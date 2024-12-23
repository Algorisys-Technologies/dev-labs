import type { MetaFunction } from "@remix-run/node";
import '../tailwind.css'
import { Link } from "@remix-run/react";
import Navbar from '../components/Navbar'

export const meta: MetaFunction = () => {
  return [
    { title: "SpreadSheet App" },
    { name: "description", content: "Welcome to Remix!" },
  ];
};

export default function Index() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gray-100 p-4">
      <h1 className="text-4xl font-bold text-gray-800 mb-4">
        Welcome to Remix
      </h1>
      <p className="text-lg text-gray-600 mb-6">
        This is a simple application to manage spreadsheets.
      </p>
      <Link 
        to={'/spreadsheet'} 
        className="px-6 py-3 bg-blue-500 text-white rounded-lg shadow-md hover:bg-blue-600 transition"
      >
        Go to Spreadsheet App
      </Link>
      {/* <Navbar/> */}
    </div>
  );
}
