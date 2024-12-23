// app/routes/emails/$id.tsx

import { useLoaderData, Link } from "@remix-run/react";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export const loader = async ({ params }) => {
  console.log("Params: ", params);
  const emailId = parseInt(params.id); // Extract ID from params
  if (isNaN(emailId)) {
    throw new Response("Invalid email ID", { status: 400 });
  }

  const email = await prisma.email.findUnique({
    where: { id: emailId }, // Find email by ID
  });

  if (!email) {
    throw new Response("Email not found", { status: 404 }); // Handle not found
  }

  return email; // Return the found email
};

export default function EmailDetail() {
  const email = useLoaderData();

  return (
    <div className="p-4">
      <Link to="/" className="mb-4 inline-block text-blue-600 hover:underline">
        ➡️ Back to Home
      </Link>
      <h1 className="font-bold text-2xl">{email.subject || "No Subject"}</h1>
      <p>
        <strong>From:</strong> {email.from}
      </p>
      <p>
        <strong>To:</strong> {email.to}
      </p>
      <p>
        <strong>Date:</strong> {new Date(email.date).toLocaleString()}
      </p>

      <div className="mt-4">
        <h2 className="font-bold">Body:</h2>
        <p>{email.bodyText}</p>
      </div>

      {/* Display attachments if they exist */}
      {email.attachments && email.attachments.length > 0 && (
        <div className="mt-4">
          <h2 className="font-bold">Attachments:</h2>
          <ul className="list-disc pl-5">
            {email.attachments.map((attachment) => (
              <li key={attachment.filename}>
                <a
                  href={`/attachments/${attachment.filename}`}
                  className="text-blue-600 hover:underline"
                  download
                >
                  {attachment.filename}
                </a>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
