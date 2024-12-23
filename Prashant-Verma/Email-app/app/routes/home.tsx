import { Outlet, useLoaderData, Link } from "@remix-run/react";
import { PrismaClient } from "@prisma/client";
import { useState, useEffect } from "react";

const prisma = new PrismaClient();
const EMAILS_PER_PAGE = 5;

export const loader = async () => {
  const accounts = await prisma.account.findMany();
  const emails = await prisma.email.findMany();
  return { accounts, emails };
};

const Home = () => {
  const { accounts, emails } = useLoaderData();
  const [selectedAccount, setSelectedAccount] = useState(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [filteredEmails, setFilteredEmails] = useState(emails);

  // Filter emails based on the selected account and search query
  useEffect(() => {
    let filtered = emails;

    if (selectedAccount) {
      filtered = filtered.filter((email) => email.to === selectedAccount.email);
    }

    if (searchQuery) {
      const lowercasedQuery = searchQuery.toLowerCase();
      filtered = filtered.filter(
        (email) =>
          email.from.toLowerCase().includes(lowercasedQuery) ||
          email.subject?.toLowerCase().includes(lowercasedQuery)
      );
    }

    setFilteredEmails(filtered);
  }, [selectedAccount, searchQuery, emails]);

  // Calculate pagination details
  const totalPages = Math.ceil(filteredEmails.length / EMAILS_PER_PAGE);
  const paginatedEmails = filteredEmails.slice(
    (currentPage - 1) * EMAILS_PER_PAGE,
    currentPage * EMAILS_PER_PAGE
  );

  const handleSearchChange = (e) => {
    setSearchQuery(e.target.value);
  };

  return (
    <div className="min-h-screen flex flex-col">
      <div className="flex flex-1">
        <aside className="w-1/4 bg-gray-200 p-4">
          <div className="space-y-4">
            <h2 className="font-bold text-xl">📨 Your Email Accounts</h2>
            {accounts.map((account) => (
              <button
                key={account.id}
                className={`w-full text-left p-2 border rounded-md hover:bg-black-100 focus:outline-none ${
                  selectedAccount?.id === account.id
                    ? "bg-black text-white"
                    : "bg-white"
                }`}
                onClick={() => setSelectedAccount(account)}
              >
                {account.email}
              </button>
            ))}
            <button className="w-full text-left p-2 bg-white border border-gray-300 rounded-md hover:bg-gray-100 focus:outline-none">
              ➕ Add Account
            </button>
          </div>
        </aside>

        <main className="flex-1 p-4 bg-white">
          <div className="flex justify-between mb-4">
            <input
              type="text"
              placeholder="🔍 Search emails..."
              className="w-full p-2 border border-gray-300 rounded-md"
              value={searchQuery}
              onChange={handleSearchChange}
            />
          </div>

          {/* Only show the email header and list if an account is selected */}
          {selectedAccount ? (
            <div className="bg-gray-100 p-4 rounded-md mb-4">
              <div className="flex justify-between font-bold p-2 bg-gray-300 rounded-md">
                <div className="w-1/3">Sender</div>
                <div className="w-1/2">Subject</div>
                <div className="w-1/6 text-right">Date</div>
              </div>

              <div className="divide-y divide-gray-300">
                {paginatedEmails.length > 0 ? (
                  paginatedEmails.map((email) => (
                    <Link
                      key={email.id}
                      to={`/emails/${email.id}`} // Link to the email details route
                      className="block"
                    >
                      <div className="flex justify-between items-center p-2 hover:bg-green-200 cursor-pointer">
                        <div className="w-1/3">{email.from}</div>
                        <div className="w-1/2">
                          {email.subject || "No Subject"}
                        </div>
                        <div className="w-1/6 text-right">
                          {new Date(email.date).toLocaleDateString()}
                        </div>
                      </div>
                    </Link>
                  ))
                ) : (
                  <div className="p-4 text-gray-600 text-center">
                    No emails found for this account.
                  </div>
                )}
              </div>

              {/* Pagination Controls */}
              {totalPages > 1 && (
                <div className="mt-4 text-center">
                  <button
                    className="mr-2"
                    disabled={currentPage === 1}
                    onClick={() =>
                      setCurrentPage((prev) => Math.max(prev - 1, 1))
                    }
                  >
                    ◀️
                  </button>
                  <span>
                    {currentPage} of {totalPages}
                  </span>
                  <button
                    className="ml-2"
                    disabled={currentPage === totalPages}
                    onClick={() =>
                      setCurrentPage((prev) => Math.min(prev + 1, totalPages))
                    }
                  >
                    ▶️
                  </button>
                </div>
              )}
            </div>
          ) : (
            <div className="p-4 text-gray-600 text-center">
              Please select an account to view emails.
            </div>
          )}

          {/* Nested routes will be rendered here */}
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export default Home;
