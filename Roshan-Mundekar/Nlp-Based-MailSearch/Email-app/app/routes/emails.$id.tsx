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

  const email = await prisma.enron_emaildataset.findUnique({
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

      <div className="overflow-x-auto">
        <table className="min-w-full border-collapse border border-gray-300">
          <thead>
            <tr>
              <th className="border border-gray-300 px-4 py-2 text-left font-bold">Field</th>
              <th className="border border-gray-300 px-4 py-2 text-left font-bold">Details</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td className="border border-gray-300 px-4 py-2 font-semibold">Subject</td>
              <td className="border border-gray-300 px-4 py-2">{email.subject || "No Subject"}</td>
            </tr>
            <tr>
              <td className="border border-gray-300 px-4 py-2 font-semibold">From</td>
              <td className="border border-gray-300 px-4 py-2">{email.from}</td>
            </tr>
            <tr>
              <td className="border border-gray-300 px-4 py-2 font-semibold">To</td>
              <td className="border border-gray-300 px-4 py-2">{email.to}</td>
            </tr>
            <tr>
              <td className="border border-gray-300 px-4 py-2 font-semibold">Date</td>
              <td className="border border-gray-300 px-4 py-2">
                {new Date(email.date).toLocaleString()}
              </td>
            </tr>
            <tr>
              <td className="border border-gray-300 px-4 py-2 font-semibold">Body</td>
              <td className="border border-gray-300 px-4 py-2">{email.body_text}</td>
            </tr>
            {email.attachments && email.attachments.length > 0 && (
              <tr>
                <td className="border border-gray-300 px-4 py-2 font-semibold">Attachments</td>
                <td className="border border-gray-300 px-4 py-2">
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
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>

  );
}
