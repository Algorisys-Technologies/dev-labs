import { Link } from "@remix-run/react";

export default function Sidebar({ isOpen }: { isOpen: boolean }) {
  return (
    <div className={`${isOpen ? 'w-64' : 'w-20'} bg-white shadow-md transition-all duration-300 ease-in-out`}>
      <div className="p-3 border-b border-gray-200 flex items-center justify-center">
        {isOpen ? (
           <div className=" border-gray-200">
            <Link
                to="/dashboard"
                >
        <h1 className="text-xl font-bold text-indigo-700">Algorisys</h1>
        <p className="text-sm text-gray-500">HRMS & JD Tracker</p>
        </Link>
      </div>
        ) : (
          <h1 className="p-3 text-xl font-bold text-indigo-700">A</h1>
        )}
      </div>
      <nav className="p-4">
        <div className="mb-6">
          <h2 className={`${isOpen ? 'block' : 'hidden'} text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2`}>
            HRMS
          </h2>
          <ul className="space-y-1">
            <li>
              <Link
                to="/employees"
                className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 rounded hover:bg-gray-100"
              >
                <svg
                  className="h-5 w-5 mr-3 text-gray-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                  />
                </svg>
                {isOpen && "Employee Profiles"}
              </Link>
            </li>
            <li>
              <Link
                to="/attendance"
                className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 rounded hover:bg-gray-100"
              >
                <svg
                  className="h-5 w-5 mr-3 text-gray-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                {isOpen && "Attendance"}
              </Link>
            </li>
            <li>
              <Link
                to="/daily-status"
                className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 rounded hover:bg-gray-100"
              >
                <svg
                  className="h-5 w-5 mr-3 text-gray-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"
                  />
                </svg>
                {isOpen && "Daily Status"}
              </Link>
            </li>
            <li>
              <Link
                to="/leave-management"
                className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 rounded hover:bg-gray-100"
              >
                <svg
                  className="h-5 w-5 mr-3 text-gray-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
                  />
                </svg>
                {isOpen && "Leave Management"}
              </Link>
            </li>
          </ul>
        </div>
        <div>
          <h2 className={`${isOpen ? 'block' : 'hidden'} text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2`}>
            JD Tracker
          </h2>
          <ul className="space-y-1">
            <li>
              <Link
                to="/jd-master"
                className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 rounded hover:bg-gray-100"
              >
                <svg
                  className="h-5 w-5 mr-3 text-gray-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                </svg>
                {isOpen && "JD Master"}
              </Link>
            </li>
            <li>
              <Link
                to="/companies"
                className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 rounded hover:bg-gray-100"
              >
                <svg
                  className="h-5 w-5 mr-3 text-gray-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                  />
                </svg>
                {isOpen && "Company Master"}
              </Link>
            </li>
            <li>
              <Link
                to="/candidates"
                className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 rounded hover:bg-gray-100"
              >
                <svg
                  className="h-5 w-5 mr-3 text-gray-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
                  />
                </svg>
                {isOpen && "Candidates"}
              </Link>
            </li>
            <li>
              <Link
                to="/interviews"
                className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 rounded hover:bg-gray-100"
              >
                <svg
                  className="h-5 w-5 mr-3 text-gray-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                  />
                </svg>
                {isOpen && "Interviews"}
              </Link>
            </li>
            <li>
              <Link
                to="/incentives"
                className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 rounded hover:bg-gray-100"
              >
                <svg
                  className="h-5 w-5 mr-3 text-gray-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                {isOpen && "Incentives"}
              </Link>
            </li>
          </ul>
        </div>
      </nav>
    </div>
  );
}