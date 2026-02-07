import Imap from "imap";
import fs from "fs";
import { simpleParser } from "mailparser";
import { PrismaClient } from "@prisma/client";
import dotenv from "dotenv";
import axios from "axios";

// Load environment variables
dotenv.config();

// Initialize Prisma client for local database
const prisma = new PrismaClient();

class MailAttachmentFetcher {
  constructor(emailConfig, localFolderPath, flaskUrl) {
    this.emailConfig = emailConfig;
    this.localFolderPath = localFolderPath;
    this.flaskUrl = flaskUrl || "http://localhost:5000";

    // Create folder if it doesn't exist
    if (!fs.existsSync(localFolderPath)) {
      fs.mkdirSync(localFolderPath, { recursive: true });
    }

    // Initialize IMAP and bind methods
    this.imap = new Imap(emailConfig);
    this.imap.once("ready", this.onImapReady.bind(this));
    this.imap.once("error", this.onImapError.bind(this));
    this.imap.once("end", this.onImapEnd.bind(this));
  }

  // Store email account in local database if not already present
  async storeAccount() {
    try {
      const existingAccount = await prisma.account.findUnique({
        where: { email: this.emailConfig.user },
      });

      if (!existingAccount) {
        await prisma.account.create({ data: { email: this.emailConfig.user } });
        console.log(`Stored account: ${this.emailConfig.user}`);
      } else {
        console.log(`Account already exists: ${this.emailConfig.user}`);
      }
    } catch (error) {
      console.error("Error storing account:", error);
    }
  }

  onImapReady() {
    console.log("IMAP connection established.");
    this.storeAccount().then(() => {
      this.imap.openBox("INBOX", true, this.onOpenBox.bind(this));
    });
  }

  onImapError(err) {
    console.error("IMAP error:", err);
  }

  onImapEnd() {
    console.log("IMAP connection ended.");
  }

  onOpenBox(err) {
    if (err) {
      console.error("Error opening INBOX:", err);
      return;
    }
    console.log("INBOX opened successfully.");

    // Search for all emails in the INBOX
    this.imap.search(["ALL"], this.onSearchResults.bind(this));
  }

  async onSearchResults(searchErr, results) {
    if (searchErr) {
      console.error("Error searching for emails:", searchErr);
      return;
    }

    console.log(`Fetched ${results.length} emails.`);

    // Retrieve account ID from the database
    const existingAccount = await prisma.account.findUnique({
      where: { email: this.emailConfig.user },
    });

    const accountId = existingAccount ? existingAccount.id : null; 

    for (const seqno of results) {
      const fetch = this.imap.fetch(seqno, {
        bodies: "",
        struct: true,
        flags: true,
      });

      fetch.on("message", (msg) => {
        let isSeen = false;

        msg.on("attributes", (attrs) => {
          if (attrs.flags.includes("\\Seen")) {
            isSeen = true;
          }
        });

        msg.on("body", (stream) => {
          simpleParser(stream, async (err, parsed) => {
            if (err) {
              console.error("Error parsing email:", err);
              return;
            }

            try {
              // Create email data for local database
              const emailData = {
                from: parsed.from.text || "Unknown",
                to: parsed.to.text || "Unknown",
                subject: parsed.subject || "No Subject",
                date: parsed.date || new Date(),
                bodyText: parsed.text || "",
                status: isSeen ? "seen" : "unseen",
                emailid: accountId || undefined, // Only assign if accountId is present
                attachments: parsed.attachments
                  ? parsed.attachments.map((att) => ({
                      filename: att.filename || `attachment_${seqno}`,
                      contentType: att.contentType,
                      size: att.size,
                    }))
                  : [],
              };

              // Save email data to the local database
              // await prisma.email.create({ data: emailData });
              // console.log(`Saved email ${seqno} to local database.`);

              // Send email data to the Flask server
              await axios.post(`${this.flaskUrl}/save_email`, emailData);
              console.log(`Email ${seqno} data sent to Flask server.`);
            } catch (error) {
              console.error(`Error handling email ${seqno}:`, error);
            }

            // Save attachments
            if (parsed.attachments && parsed.attachments.length > 0) {
              parsed.attachments.forEach((attachment, index) => {
                if (this.isSupportedAttachment(attachment)) {
                  const filename =
                    attachment.filename ||
                    `attachment_${seqno}_${index + 1}.${attachment.contentType.split("/")[1]}`;
                  const filePath = `${this.localFolderPath}/${filename}`;

                  fs.writeFileSync(filePath, attachment.content);
                  console.log(`Saved attachment: ${filePath}`);
                } else {
                  console.log(`Skipped unsupported attachment: ${attachment.filename || "No filename"}`);
                }
              });
            }
          });
        });
      });
    }

    // End the IMAP connection after processing
    this.imap.end();
  }

  isSupportedAttachment(attachment) {
    const supportedExtensions = ["pdf", "xlsx", "jpg", "zip", "rar", "docx"];
    if (attachment.filename) {
      const extension = attachment.filename.toLowerCase().split(".").pop();
      return supportedExtensions.includes(extension);
    }
    return false;
  }

  start() {
    this.imap.connect();
  }
}

// Parse email accounts and Flask URL from environment variables
const emailAccounts = JSON.parse(process.env.EMAIL_ACCOUNTS);
const flaskUrl = process.env.FLASK_URL || "http://localhost:5000/";
const localFolderPath = "./attachments";

// Initialize and start MailAttachmentFetcher for each account
emailAccounts.forEach((account) => {
  const emailConfig = {
    user: account.user,
    password: account.password,
    host: account.host,
    port: 993,
    tls: true,
    tlsOptions: { rejectUnauthorized: false },
  };

  const mailFetcher = new MailAttachmentFetcher(emailConfig, localFolderPath, flaskUrl);
  mailFetcher.start();
});
