
// import { useState, useEffect } from "react";
// import { Form, json, useActionData } from "@remix-run/react";

// // Remix action to handle the form submission and interact with the Python backend
// export let action = async ({ request }) => {
//   const formData = new URLSearchParams(await request.text());
//   const searchQuery = formData.get("search");

//   // Send the query to the Python backend (your Flask app)
//   const response = await fetch("http://localhost:5000/search", {
//     method: "POST",
//     headers: {
//       "Content-Type": "application/json",
//     },
//     body: JSON.stringify({ search: searchQuery }),
//   });

//   const data = await response.json();
  
//   // Return the results back to the frontend to display
//   return json(data);
// };

// // React component to handle the search form and results display
// export default function SearchPage() {
//   const [searchResults, setSearchResults] = useState([]);
//   const [selectedEmail, setSelectedEmail] = useState(null);
//   const actionData = useActionData();

//   useEffect(() => {
//     if (actionData?.length > 0) {
//       setSearchResults(actionData);
//     }
//   }, [actionData]);

//   const handleShowBodyText = (email) => {
//     setSelectedEmail(email);
//   };

//   return (
//     <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50">
//       {/* Form container */}
//       <Form method="post" className="p-8 bg-white border rounded-lg shadow-lg w-full max-w-md sm:max-w-lg md:max-w-xl lg:max-w-2xl">
//         <h2 className="text-2xl font-semibold text-gray-800 mb-6 text-center">Email NLP Search Engine</h2>
  
//         <label htmlFor="search" className="block text-lg font-medium text-gray-700">
//           Search Query
//         </label>
//         <input
//           type="text"
//           name="search"
//           id="search"
//           className="w-full p-4 mt-2 text-lg border border-gray-300 rounded-md focus:border-blue-500 focus:outline-none"
//           placeholder="Enter search term"
//           required
//         />
  
//         <button
//           type="submit"
//           className="mt-6 w-full p-4 text-lg text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none"
//         >
//           Submit
//         </button>
//       </Form>
  
//       {/* Table container */}
//       {searchResults.length > 0 && (
//         <div className="w-full mt-10 overflow-x-auto">
//           <table className="min-w-full bg-white border border-gray-200 rounded-lg shadow-lg">
//             <thead>
//               <tr className="text-left bg-gray-100 border-b">
//                 <th className="p-4 text-sm font-medium text-gray-700">From</th>
//                 <th className="p-4 text-sm font-medium text-gray-700">To</th>
//                 <th className="p-4 text-sm font-medium text-gray-700">Subject</th>
//                 <th className="p-4 text-sm font-medium text-gray-700">Date</th>
//                 <th className="p-4 text-sm font-medium text-gray-700">Actions</th>
//               </tr>
//             </thead>
//             <tbody>
//               {searchResults.map((email, index) => (
//                 <tr key={index} className="border-t hover:bg-gray-50">
//                   <td className="p-4 text-sm text-gray-700">{email.from}</td>
//                   <td className="p-4 text-sm text-gray-700">{email.to}</td>
//                   <td className="p-4 text-sm text-gray-700">{email.subject}</td>
//                   <td className="p-4 text-sm text-gray-700">{email.date}</td>
//                   <td className="p-4">
//                     <button
//                       className="px-4 py-2 text-sm text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none"
//                       onClick={() => handleShowBodyText(email)}
//                     >
//                       Show Body
//                     </button>
//                   </td>
//                 </tr>
//               ))}
//             </tbody>
//           </table>
//         </div>
//       )}
  
//       {/* Modal or Collapsible Body */}
//       {selectedEmail && (
//         <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 z-50">
//           <div className="bg-white p-6 rounded-lg w-3/4 max-w-2xl border-2 border-indigo-600">
//             <h3 className="text-xl font-semibold mb-4 text-center">Email Body</h3>
  
//             <table className="min-w-full table-auto border-separate border-spacing-2">
//               <tbody>
//                 <tr>
//                   <td className="p-3 font-semibold border border-gray-300">From:</td>
//                   <td className="p-3 border border-gray-300">{selectedEmail.from}</td>
//                 </tr>
//                 <tr>
//                   <td className="p-3 font-semibold border border-gray-300">To:</td>
//                   <td className="p-3 border border-gray-300">{selectedEmail.to}</td>
//                 </tr>
//                 <tr>
//                   <td className="p-3 font-semibold border border-gray-300">Subject:</td>
//                   <td className="p-3 border border-gray-300">{selectedEmail.subject}</td>
//                 </tr>
//                 <tr>
//                   <td className="p-3 font-semibold border border-gray-300">Date:</td>
//                   <td className="p-3 border border-gray-300">{selectedEmail.date}</td>
//                 </tr>
//                 <tr>
//                   <td className="p-3 font-semibold border border-gray-300">Body:</td>
//                   <td className="p-3 border border-gray-300">{selectedEmail.body_text}</td>
//                 </tr>
//               </tbody>
//             </table>
  
//             <button
//               onClick={() => setSelectedEmail(null)}
//               className="mt-4 px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
//             >
//               Close
//             </button>
//           </div>
//         </div>
//       )}
//     </div>
//   );
  
// }


import { useState, useEffect } from "react";
import { Form, json, useActionData } from "@remix-run/react";

// Remix action to handle the form submission and interact with the Python backend
export let action = async ({ request }) => {
  const formData = new URLSearchParams(await request.text());
  const searchQuery = formData.get("search");

  // Send the query to the Python backend (your Flask app)
  const response = await fetch("http://localhost:5000/search", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ search: searchQuery }),
  });

  const data = await response.json();
  
  // Return the results back to the frontend to display
  return json(data);
};

// React component to handle the search form and results display
export default function SearchPage() {
  const [searchResults, setSearchResults] = useState([]);
  const [selectedEmail, setSelectedEmail] = useState(null);
  const [currentPage, setCurrentPage] = useState(1); // Keep track of the current page
  const resultsPerPage = 5; // Number of results per page
  const actionData = useActionData();

  useEffect(() => {
    if (actionData?.length > 0) {
      setSearchResults(actionData);
    }
  }, [actionData]);

  const handleShowBodyText = (email) => {
    setSelectedEmail(email);
  };

  // Calculate the index of the first and last items for the current page
  const indexOfLastResult = currentPage * resultsPerPage;
  const indexOfFirstResult = indexOfLastResult - resultsPerPage;
  const currentResults = searchResults.slice(indexOfFirstResult, indexOfLastResult);

  // Pagination buttons logic
  const handleNextPage = () => {
    if (currentPage < Math.ceil(searchResults.length / resultsPerPage)) {
      setCurrentPage(currentPage + 1);
    }
  };

  const handlePrevPage = () => {
    if (currentPage > 1) {
      setCurrentPage(currentPage - 1);
    }
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50">
      {/* Form container */}
      <Form method="post" className="p-8 bg-white border rounded-lg shadow-lg w-full max-w-md sm:max-w-lg md:max-w-xl lg:max-w-2xl">
        <h2 className="text-2xl font-semibold text-gray-800 mb-6 text-center">Email NLP Search Engine</h2>

        <label htmlFor="search" className="block text-lg font-medium text-gray-700">
          Search Query
        </label>
        <input
          type="text"
          name="search"
          id="search"
          className="w-full p-4 mt-2 text-lg border border-gray-300 rounded-md focus:border-blue-500 focus:outline-none"
          placeholder="Enter search term"
          required
        />

        <button
          type="submit"
          className="mt-6 w-full p-4 text-lg text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none"
        >
          Submit
        </button>
      </Form>

      {/* Table container */}
      {currentResults.length > 0 && (
        <div className="w-full mt-10 overflow-x-auto">
          <table className="min-w-full bg-white border border-gray-200 rounded-lg shadow-lg">
            <thead>
              <tr className="text-left bg-gray-100 border-b">
                <th className="p-4 text-sm font-medium text-gray-700">From</th>
                <th className="p-4 text-sm font-medium text-gray-700">To</th>
                <th className="p-4 text-sm font-medium text-gray-700">Subject</th>
                <th className="p-4 text-sm font-medium text-gray-700">Date</th>
                <th className="p-4 text-sm font-medium text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody>
              {currentResults.map((email, index) => (
                <tr key={index} className="border-t hover:bg-gray-50">
                  <td className="p-4 text-sm text-gray-700">{email.from}</td>
                  <td className="p-4 text-sm text-gray-700">{email.to}</td>
                  <td className="p-4 text-sm text-gray-700">{email.subject}</td>
                  <td className="p-4 text-sm text-gray-700">{email.date}</td>
                  <td className="p-4">
                    <button
                      className="px-4 py-2 text-sm text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none"
                      onClick={() => handleShowBodyText(email)}
                    >
                      Show Body
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* Pagination controls */}
          <div className="mt-6 mx-auto flex justify-center items-center space-x-4">
  {/* Previous Button */}
  <button
    className="px-6 py-3 text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none disabled:opacity-50"
    onClick={handlePrevPage}
    disabled={currentPage === 1}
  >
    Previous
  </button>

  {/* Page Number Display */}
  <div className="text-lg text-gray-700 font-medium">
    Page <span className="font-bold text-blue-600">{currentPage}</span> of{" "}
    <span className="font-bold text-blue-600">{Math.ceil(searchResults.length / resultsPerPage)}</span>
  </div>

  {/* Next Button */}
  <button
    className="px-6 py-3 text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none disabled:opacity-50"
    onClick={handleNextPage}
    disabled={currentPage === Math.ceil(searchResults.length / resultsPerPage)}
  >
    Next
  </button>
</div>

        </div>
      )}

      {/* Modal or Collapsible Body */}
      {selectedEmail && (
  <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 z-50">
    <div className="bg-white p-6 rounded-lg w-3/4 max-w-2xl max-h-[80vh] overflow-y-auto relative">
      
      {/* Close Button in Top Left */}
      <button
        onClick={() => setSelectedEmail(null)}
        className="absolute top-4 right-4 p-2 text-gray-600 bg-transparent rounded-full hover:bg-gray-200 focus:outline-none"
      >
        {/* Close Icon (X) */}
        <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>

      <h3 className="text-xl font-semibold mb-4 text-center">Email Body</h3>

      <table className="min-w-full table-auto border-separate border-spacing-2">
        <tbody>
          <tr>
            <td className="p-3 font-semibold border border-gray-300">From:</td>
            <td className="p-3 border border-gray-300 overflow-hidden text-ellipsis whitespace-nowrap">{selectedEmail.from}</td>
          </tr>
          <tr>
            <td className="p-3 font-semibold border border-gray-300">To:</td>
            <td className="p-3 border border-gray-300 overflow-hidden text-ellipsis whitespace-nowrap">{selectedEmail.to}</td>
          </tr>
          <tr>
            <td className="p-3 font-semibold border border-gray-300">Subject:</td>
            <td className="p-3 border border-gray-300 overflow-hidden text-ellipsis whitespace-nowrap">{selectedEmail.subject}</td>
          </tr>
          <tr>
            <td className="p-3 font-semibold border border-gray-300">Date:</td>
            <td className="p-3 border border-gray-300 overflow-hidden text-ellipsis whitespace-nowrap">{selectedEmail.date}</td>
          </tr>
          <tr>
            <td className="p-3 font-semibold border border-gray-300">Body:</td>
            <td className="p-3 border border-gray-300 overflow-auto max-h-40">{selectedEmail.body_text}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
)}



    </div>
  );
}
