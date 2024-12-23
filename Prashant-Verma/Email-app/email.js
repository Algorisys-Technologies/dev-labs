import Imap from "imap";
import fs from "fs";
import { simpleParser } from "mailparser";
import { PrismaClient } from "@prisma/client";
import dotenv from "dotenv";

dotenv.config();

const prisma = new PrismaClient(); // Initialize Prisma client

class MailAttachmentFetcher {
  constructor(emailConfig, localFolderPath) {
    this.emailConfig = emailConfig;
    this.localFolderPath = localFolderPath;

    // Check if the folder exists, if not, create it
    if (!fs.existsSync(localFolderPath)) {
      fs.mkdirSync(localFolderPath, { recursive: true });
    }

    // Instantiate IMAP and bind methods
    this.imap = new Imap(emailConfig);
    this.imap.once("ready", this.onImapReady.bind(this));
    this.imap.once("error", this.onImapError.bind(this));
    this.imap.once("end", this.onImapEnd.bind(this));
  }

  async storeAccount() {
    try {
      const existingAccount = await prisma.account.findUnique({
        where: { email: this.emailConfig.user },
      });

      if (!existingAccount) {
        // Create new account entry if it doesn't exist
        await prisma.account.create({
          data: {
            email: this.emailConfig.user,
          },
        });
        console.log(`Stored account: ${this.emailConfig.user}`);
      } else {
        console.log(`Account already exists: ${this.emailConfig.user}`);
      }
    } catch (error) {
      console.error("Error storing account:", error);
    }
  }

  onImapReady() {
    console.log("Connection established.");
    this.storeAccount().then(() => {
      this.imap.openBox("INBOX", true, this.onOpenBox.bind(this)); // Open the INBOX in read-only mode
    });
  }

  onImapError(err) {
    console.error("IMAP error:", err);
    throw err;
  }

  onImapEnd() {
    console.log("Connection ended.");
  }

  onOpenBox(err) {
    if (err) {
      console.error("Error opening INBOX:", err);
      throw err;
    }
    console.log("INBOX opened successfully.");

    // Search for all emails in the INBOX
    this.imap.search(["ALL"], this.onSearchResults.bind(this));
  }

  async onSearchResults(searchErr, results) {
    if (searchErr) {
      console.error("Error searching for emails:", searchErr);
      throw searchErr;
    }

    console.log(`Fetched ${results.length} emails.`);

    // Loop through search results and fetch email content along with flags
    for (const seqno of results) {
      const fetch = this.imap.fetch([seqno], {
        bodies: "",
        struct: true,
        flags: true, // Fetch flags to determine if email is seen
      });

      fetch.on("message", (msg, seqno) => {
        let isSeen = false; // Default to 'unseen'

        msg.on("attributes", (attrs) => {
          if (attrs.flags.includes("\\Seen")) {
            isSeen = true; // Mark as 'seen' if the flag is present
          }
        });

        msg.on("body", (stream) => {
          simpleParser(stream, async (err, parsed) => {
            if (err) {
              console.error("Error parsing email:", err);
              return; // Return early on error
            }

            // Check for existing email in the database
            try {
              const emailExists = await prisma.email.findUnique({
                where: {
                  subject_date_to_from_bodyText: {
                    subject: parsed.subject || "No Subject",
                    date: parsed.date || new Date(),
                    to: parsed.to.text || "Unknown",
                    from: parsed.from.text || "Unknown",
                    bodyText: parsed.text || "",
                  },
                },
              });

              // Save the email data if it doesn't exist
              if (!emailExists) {
                const emailData = {
                  from: parsed.from.text || "Unknown",
                  to: parsed.to.text || "Unknown",
                  subject: parsed.subject || "No Subject",
                  date: parsed.date || new Date(),
                  bodyText: parsed.text || "",
                  status: isSeen ? "seen" : "unseen", // Set the email status
                  attachments: parsed.attachments
                    ? parsed.attachments.map((att) => ({
                        filename: att.filename || `attachment_${seqno}`,
                        contentType: att.contentType,
                        size: att.size,
                      }))
                    : [], // Store attachment details
                };

                await prisma.email.create({ data: emailData });
                console.log(
                  `Saved email ${seqno} to the database with status ${emailData.status}.`
                );
              } else {
                console.log(
                  `Email ${seqno} already exists in the database. Skipping.`
                );
              }
            } catch (error) {
              console.error(`Error checking or saving email ${seqno}:`, error); // Log the full error object
            }

            // Check if email has attachments
            if (parsed.attachments && parsed.attachments.length > 0) {
              console.log(`Saving attachments from Email ${seqno}`);

              parsed.attachments.forEach((attachment, index) => {
                if (this.isSupportedAttachment(attachment)) {
                  // Use the attachment's filename if available, otherwise create a default one
                  const filename =
                    attachment.filename ||
                    `attachment_${seqno}_${index + 1}.${
                      attachment.contentType.split("/")[1]
                    }`;
                  const fullDirPath = this.localFolderPath; // This can be modified based on your folder structure needs

                  // Create the directory if it doesn't exist
                  if (!fs.existsSync(fullDirPath)) {
                    fs.mkdirSync(fullDirPath, { recursive: true }); // Create the base directory
                  }

                  // Save the attachment
                  const filePath = `${fullDirPath}/${filename}`;
                  fs.writeFileSync(filePath, attachment.content);
                  console.log(`Saved attachment: ${filePath}`);
                } else {
                  console.log(
                    `Skipped unsupported attachment: ${
                      attachment.filename || "No filename"
                    }`
                  );
                }
              });
            } else {
              console.log(`No attachments found in Email ${seqno}.`);
            }
          });
        });
      });
    }

    this.imap.end(); // End the IMAP connection after processing
  }

  isSupportedAttachment(attachment) {
    const supportedExtensions = ["pdf", "xlsx", "jpg", "zip", "rar", "docx"];
    if (attachment.filename) {
      const extension = attachment.filename.toLowerCase().split(".").pop();
      return supportedExtensions.includes(extension);
    }
    return false;
  }

  // Method to initiate the IMAP connection
  start() {
    this.imap.connect();
  }
}

// Parse the email accounts from the environment variable
const emailAccounts = JSON.parse(process.env.EMAIL_ACCOUNTS);

// Local folder to save attachments
const localFolderPath = "./attachments";

// Initialize and start the MailAttachmentFetcher for each account
emailAccounts.forEach((account) => {
  const emailConfig = {
    user: account.user,
    password: account.password,
    host: account.host,
    port: 993,
    tls: true,
    tlsOptions: { rejectUnauthorized: false }, // Allow self-signed certificates
  };

  const mailFetcher = new MailAttachmentFetcher(emailConfig, localFolderPath);
  mailFetcher.start();
});
