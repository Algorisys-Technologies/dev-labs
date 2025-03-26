const _ = require("lodash");

// Get all categories
// exports.getAllCategories = (req, res) => {
//   const respData = {
//     status: "success",
//     data: [
//       { id: 1, name: "Work" },
//       { id: 2, name: "Personal" },
//       { id: 3, name: "Shopping" },
//       { id: 4, name: "Health" },
//     ],
//   };

//   res.send({
//     status: respData.status,
//     data: respData.data,
//     totalRecords: respData.data.length,
//   });
// };

// // Get all statuses
// exports.getAllStatuses = (req, res) => {
//   const respData = {
//     status: "success",
//     data: ["Pending", "In Progress", "Completed", "On Hold"],
//   };

//   res.send({
//     status: respData.status,
//     statuses: respData.data,
//     totalRecords: respData.data.length,
//   });
// };


exports.getAllArea = (req, res) => {
  res.json({ message: "List of all areas" });
};

exports.getAllItems = (req, res) => {
  res.json({ message: "List of all items" });
};