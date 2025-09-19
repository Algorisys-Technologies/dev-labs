import { Link } from "@remix-run/react";

export default function Index() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex flex-col items-center justify-center p-4">
      <div className="max-w-4xl w-full bg-white rounded-xl shadow-lg p-8 text-center">
        <h1 className="text-4xl font-bold text-indigo-700 mb-6">
          Welcome to Algorisys HRMS & JD Tracker
        </h1>
        <p className="text-lg text-gray-600 mb-8">
          Streamline your human resource management and job description tracking
          with our comprehensive solution.
        </p>
        <div className="flex justify-center gap-6">
          <Link
            to="/login"
            className="px-6 py-3 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition-colors"
          >
            Login
          </Link>
          <Link
            to="/dashboard"
            className="px-6 py-3 border border-indigo-600 text-indigo-600 font-medium rounded-lg hover:bg-indigo-50 transition-colors"
          >
            Demo Dashboard
          </Link>
        </div>
      </div>
    </div>
  );
}