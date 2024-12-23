// import React, { useEffect, useState, useCallback, useRef } from "react";
// import jspreadsheet from "jspreadsheet-ce";
// import "jspreadsheet-ce/dist/jspreadsheet.css";
// import * as XLSX from "xlsx";
// import { FaDownload, FaFileUpload, FaPlus, FaTrash } from "react-icons/fa";

// export default function Index() {
//   const [spreadInstances, setSpreadInstances] = useState<any[]>([]);
//   const [currentIndex, setCurrentIndex] = useState<number>(0);
//   const containerRefs = useRef<(HTMLDivElement | null)[]>([]);
//   const [totalAmount, setTotalAmount] = useState(0);
//   const [averageAmount, setAverageAmount] = useState(0);

//   const options = {
//     data: [], // Initial data
//     columns: [
//         // { type: 'image', width: 120 },
//     ],
//     minDimensions: [10, 10], // Minimum dimensions of the spreadsheet
// };

//   useEffect(() => {
//     const savedData = localStorage.getItem("spreadsheets");
//     if (savedData) {
//       try {
//         const parsedData = JSON.parse(savedData);
//         if (parsedData.length > 0) {
//           const instances = parsedData.map((spreadsheet: any) => {
//             const container = document.createElement("div");
//             const instance = jspreadsheet(container, options);
//             const cleanData = spreadsheet.data.map((row: any[]) =>
//               row.map((cell: any) =>
//                 typeof cell === "number" ? cell : String(cell)
//               )
//             );
//             instance.setData(cleanData);
//             return { container, instance };
//           });
//           setSpreadInstances(instances);
//           setCurrentIndex(0);
//         }
//       } catch (error) {
//         console.error("Error loading spreadsheets from localStorage:", error);
//       }
//     }
//   }, []);

//   useEffect(() => {
//     spreadInstances.forEach((spread, index) => {
//       const container = containerRefs.current[index];
//       if (container && !container.hasChildNodes()) {
//         container.appendChild(spread.container);
//       }
//     });

//     const saveData = spreadInstances.map((spread) => ({
//       data: spread.instance
//         .getData()
//         .map((row: any[]) =>
//           row.map((cell: any) =>
//             typeof cell === "string" ? cell : parseFloat(cell)
//           )
//         ),
//     }));
//     localStorage.setItem("spreadsheets", JSON.stringify(saveData));
//   }, [spreadInstances]);

//   const addSpreadsheet = useCallback(() => {
//     const container = document.createElement("div");
//     const instance = jspreadsheet(container, options);
//     setSpreadInstances((prevInstances) => {
//       const updatedInstances = [...prevInstances, { container, instance }];
//       localStorage.setItem(
//         "spreadsheets",
//         JSON.stringify(
//           updatedInstances.map((spread) => ({
//             data: spread.instance
//               .getData()
//               .map((row: any[]) =>
//                 row.map((cell: any) =>
//                   typeof cell === "string" ? cell : parseFloat(cell)
//                 )
//               ),
//           }))
//         )
//       );
//       return updatedInstances;
//     });
//     setCurrentIndex(spreadInstances.length);
//   }, [spreadInstances]);

//   const selectSpreadsheet = useCallback((index: number) => {
//     setCurrentIndex(index);
//   }, []);

//   const getCurrentInstance = useCallback(() => {
//     return spreadInstances[currentIndex]?.instance;
//   }, [spreadInstances, currentIndex]);

//   const addRow = useCallback(() => {
//     const instance = getCurrentInstance();
//     if (instance) {
//       instance.insertRow();
//     }
//   }, [getCurrentInstance]);

//   const addColumn = useCallback(() => {
//     const instance = getCurrentInstance();
//     if (instance) {
//       instance.insertColumn(1);
//     }
//   }, [getCurrentInstance]);

//   const deleteRow = useCallback(() => {
//     const instance = getCurrentInstance();
//     if (instance) {
//       const rowIndex = prompt(
//         "Enter the row index to delete (starting from 0):"
//       );
//       if (rowIndex !== null && !isNaN(Number(rowIndex))) {
//         instance.deleteRow(Number(rowIndex));
//       } else {
//         alert("Invalid row index.");
//       }
//     }
//   }, [getCurrentInstance]);

//   const calculateTotalAmount = () => {
//     const instance = getCurrentInstance();
//     if (instance) {
//       const data = instance.getData();
//       let total = 0;
//       let count = 0;

//       data.forEach((row: any[]) => {
//         row.forEach((cell) => {
//           const value = parseFloat(cell);
//           if (!isNaN(value)) {
//             total += value;
//             count++;
//           }
//         });
//       });

//       const average = count > 0 ? (total / count).toFixed(2) : 0;

//       setTotalAmount(total);
//       setAverageAmount(average);
//       alert(`Your Total is ${total} and Average is ${average}`);
//     }
//   };

//   const downloadExcel = () => {
//     const instance = getCurrentInstance();
//     if (instance) {
//       const data = instance.getData();
//       const processedData = data.map((row) =>
//         row.map((cell) => {
//           if (!isNaN(cell) && cell !== null && cell !== "") {
//             return Number(cell);
//           }
//           return cell;
//         })
//       );

//       const ws = XLSX.utils.aoa_to_sheet(processedData);

//       Object.keys(ws).forEach((key) => {
//         if (ws[key].t === "s" && !isNaN(ws[key].v)) {
//           ws[key].t = "n"; // Set type to number
//         }
//       });

//       const wb = XLSX.utils.book_new();
//       XLSX.utils.book_append_sheet(wb, ws, "Sheet1");

//       XLSX.writeFile(wb, "spreadsheet.xlsx");
//     }
//   };

//   const saveToFile = async () => {
//     const sheetsData = spreadInstances.map((spread) => ({
//       sheetName: `Sheet${spreadInstances.indexOf(spread) + 1}`,
//       data: spread.instance
//         .getData()
//         .map((row: any[]) =>
//           row.map((cell: any) =>
//             typeof cell === "string" ? cell : parseFloat(cell)
//           )
//         ),
//     }));

//     try {
//       const response = await fetch("/saveToFile", {
//         method: "POST",
//         headers: {
//           "Content-Type": "application/json",
//         },
//         body: JSON.stringify({ sheetsData }),
//       });

//       const result = await response.json();

//       if (result.success) {
//         window.location.href = `/public/${result.filename}`;
//       } else {
//         alert(`Failed to save file: ${result.error}`);
//       }
//     } catch (error) {
//       console.error("Error saving file:", error);
//       alert("An error occurred while saving the file.");
//     }
//   };

//   const deleteSpreadsheet = useCallback(
//     (index: number) => {
//       if (window.confirm("Are you sure you want to delete this spreadsheet?")) {
//         setSpreadInstances((prevInstances) => {
//           const updatedInstances = prevInstances.filter((_, i) => i !== index);
//           localStorage.setItem(
//             "spreadsheets",
//             JSON.stringify(
//               updatedInstances.map((spread) => ({
//                 data: spread.instance.getData(),
//               }))
//             )
//           );
//           return updatedInstances;
//         });
//         if (currentIndex >= spreadInstances.length - 1) {
//           setCurrentIndex(Math.max(0, currentIndex - 1));
//         }
//       }
//     },
//     [currentIndex, spreadInstances]
//   );

//   const handleFileUpload = useCallback(
//     (event: React.ChangeEvent<HTMLInputElement>) => {
//       const file = event.target.files?.[0];
//       if (file) {
//         const reader = new FileReader();
//         reader.onload = (e) => {
//           const data = new Uint8Array(e.target?.result as ArrayBuffer);
//           const workbook = XLSX.read(data, { type: "array" });
//           const sheetName = workbook.SheetNames[0];
//           const sheet = workbook.Sheets[sheetName];
//           const jsonData = XLSX.utils.sheet_to_json(sheet, { header: 1 });

//           const container = document.createElement("div");
//           const instance = jspreadsheet(container, {
//             ...options,
//             data: jsonData,
//           });

//           setSpreadInstances((prevInstances) => {
//             const updatedInstances = [
//               ...prevInstances,
//               { container, instance },
//             ];
//             localStorage.setItem(
//               "spreadsheets",
//               JSON.stringify(
//                 updatedInstances.map((spread) => ({
//                   data: spread.instance.getData(),
//                 }))
//               )
//             );
//             return updatedInstances;
//           });
//           setCurrentIndex(spreadInstances.length);
//         };
//         reader.readAsArrayBuffer(file);
//       }
//     },
//     [spreadInstances]
//   );

//   return (
//     <div className="container mx-auto p-6 bg-gray-50 min-h-screen">
//       <div className="mb-6 flex flex-wrap gap-2">
//       <button
//           onClick={addSpreadsheet}
//           className="bg-gradient-to-r from-blue-500 to-indigo-500 text-white px-6 py-3 rounded-lg shadow-lg hover:from-blue-600 hover:to-indigo-600 transition duration-300 flex items-center"
//         >
//           <FaPlus className="mr-2" />
//           Add Spreadsheet
//         </button>
//         <button
//           onClick={addRow}
//           className="bg-green-500 text-white px-4 py-2 rounded-lg shadow-md hover:bg-green-600 transition duration-300"
//         >
//           Add Row
//         </button>
//         <button
//           onClick={addColumn}
//           className="bg-yellow-500 text-white px-4 py-2 rounded-lg shadow-md hover:bg-yellow-600 transition duration-300"
//         >
//           Add Column
//         </button>
//         <button
//           onClick={deleteRow}
//           className="bg-red-500 text-white px-4 py-2 rounded-lg shadow-md hover:bg-red-600 transition duration-300"
//         >
//           Delete Row
//         </button>
//         <button
//           onClick={downloadExcel}
//           className="bg-gradient-to-r from-indigo-500 to-blue-500 text-white px-6 py-3 rounded-lg shadow-lg hover:from-indigo-600 hover:to-blue-600 transition duration-300 flex items-center"
//         >
//           <FaDownload className="mr-2" />
//           Download Excel
//         </button>
//         <button
//           onClick={saveToFile}
//           className="bg-orange-500 text-white px-4 py-2 rounded-lg shadow-md hover:bg-orange-600 transition duration-300"
//         >
//           Save File
//         </button>
//         <label className="bg-gradient-to-r from-gray-700 to-gray-900 text-white px-6 py-3 rounded-lg shadow-lg hover:from-gray-800 hover:to-gray-900 transition duration-300 cursor-pointer flex items-center">
//           <FaFileUpload className="mr-2" />
//           Upload Excel
//           <input
//             type="file"
//             accept=".xlsx"
//             onChange={handleFileUpload}
//             className="hidden"
//           />
//         </label>
//         <select
//           value={currentIndex}
//           onChange={(e) => selectSpreadsheet(Number(e.target.value))}
//           className="text-sm border border-gray-300 rounded-md p-2 bg-white"
//         >
//           {spreadInstances.map((_, index) => (
//             <option key={index} value={index}>
//               sheet {index + 1}
//             </option>
//           ))}
//         </select>
//       </div>
//       <div className="flex flex-wrap gap-4 mb-6">
//         {spreadInstances.map((_, index) => (
//           <div
//             key={index}
//             className={`p-4 border rounded-lg shadow-md ${
//               currentIndex === index ? "bg-blue-100" : "bg-white"
//             } ${
//               currentIndex === index ? "block" : "hidden"
//             }`}
//           >
//             <button
//               onClick={() => selectSpreadsheet(index)}
//               className="text-blue-600 hover:underline mb-2 block"
//             >
//               Spreadsheet {index + 1}
//             </button>
//             <button
//               onClick={() => deleteSpreadsheet(index)}
//               className="text-red-600 hover:underline"
//             >
//               <FaTrash />
//             </button>
//             <div
//               ref={(el) => (containerRefs.current[index] = el)}
//               className="mt-4"
//             />
//           </div>
//         ))}
//       </div>
//     </div>
//   );
// }


import React, { useEffect, useState, useCallback, useRef } from "react";
import jspreadsheet from "jspreadsheet-ce";
import "jspreadsheet-ce/dist/jspreadsheet.css";
import * as XLSX from "xlsx";
import { FaDownload, FaFileUpload, FaPlus, FaTrash } from "react-icons/fa";

export default function Index() {
    const [spreadInstances, setSpreadInstances] = useState<any[]>([]);
    const [currentIndex, setCurrentIndex] = useState<number>(0);
    const containerRefs = useRef<(HTMLDivElement | null)[]>([]);
    const [formula, setFormula] = useState<string>("");

    const options = {
        data: [],
        minDimensions: [10, 10],
    };

    useEffect(() => {
        // Load existing spreadsheets
        const savedData = localStorage.getItem("spreadsheets");
        if (savedData) {
            try {
                const parsedData = JSON.parse(savedData);
                if (parsedData.length > 0) {
                    const instances = parsedData.map((spreadsheet: any) => {
                        const container = document.createElement("div");
                        const instance = jspreadsheet(container, options);
                        const cleanData = spreadsheet.data.map((row: any[]) =>
                            row.map((cell: any) => (typeof cell === "number" ? cell : String(cell)))
                        );
                        instance.setData(cleanData);
                        return { container, instance };
                    });
                    setSpreadInstances(instances);
                    setCurrentIndex(0);
                }
            } catch (error) {
                console.error("Error loading spreadsheets from localStorage:", error);
            }
        }
    }, []);

    useEffect(() => {
        // Append containers to the DOM and save data
        spreadInstances.forEach((spread, index) => {
            const container = containerRefs.current[index];
            if (container && !container.hasChildNodes()) {
                container.appendChild(spread.container);
            }
        });

        const saveData = spreadInstances.map((spread) => ({
            data: spread.instance.getData().map((row: any[]) =>
                row.map((cell: any) => (typeof cell === "string" ? cell : parseFloat(cell)))
            ),
        }));
        localStorage.setItem("spreadsheets", JSON.stringify(saveData));
    }, [spreadInstances]);

    const addSpreadsheet = useCallback(() => {
        const container = document.createElement("div");
        const instance = jspreadsheet(container, options);
        setSpreadInstances((prevInstances) => {
            const updatedInstances = [...prevInstances, { container, instance }];
            localStorage.setItem(
                "spreadsheets",
                JSON.stringify(
                    updatedInstances.map((spread) => ({
                        data: spread.instance.getData().map((row: any[]) =>
                            row.map((cell: any) => (typeof cell === "string" ? cell : parseFloat(cell)))
                        ),
                    }))
                )
            );
            return updatedInstances;
        });
        setCurrentIndex(spreadInstances.length);
    }, [spreadInstances]);

    const selectSpreadsheet = useCallback((index: number) => {
        setCurrentIndex(index);
    }, []);

    const getCurrentInstance = useCallback(() => {
        return spreadInstances[currentIndex]?.instance;
    }, [spreadInstances, currentIndex]);

    const addRow = useCallback(() => {
        const instance = getCurrentInstance();
        if (instance) {
            instance.insertRow();
        }
    }, [getCurrentInstance]);

    const addColumn = useCallback(() => {
        const instance = getCurrentInstance();
        if (instance) {
            instance.insertColumn(1);
        }
    }, [getCurrentInstance]);

    const deleteRow = useCallback(() => {
        const instance = getCurrentInstance();
        if (instance) {
            const rowIndex = prompt(
                "Enter the row index to delete (starting from 0):"
            );
            if (rowIndex !== null && !isNaN(Number(rowIndex))) {
                instance.deleteRow(Number(rowIndex));
            } else {
                alert("Invalid row index.");
            }
        }
    }, [getCurrentInstance]);

    const calculateFormula = () => {
        const instance = getCurrentInstance();
        if (instance) {
            const data = instance.getData();
            const parsedFormula = parseFormula(formula, spreadInstances);
            const result = executeFormula(parsedFormula);
            // Update the current sheet with the result
            instance.setData([['Result', result]], 0);
        } else {
            alert('Current sheet is not available.');
        }
    };

    const parseFormula = (formula: string, instances: any[]) => {
        // Basic example of parsing, adjust as needed for complex formulas
        return formula;
    };

    const executeFormula = (parsedFormula: string) => {
        // Basic example of executing, adjust as needed for complex formulas
        try {
            return eval(parsedFormula); // For demo purposes, use with caution
        } catch (error) {
            console.error('Error executing formula:', error);
            return 'Error';
        }
    };

    const downloadExcel = () => {
        const instance = getCurrentInstance();
        if (instance) {
            const data = instance.getData();
            const processedData = data.map((row) =>
                row.map((cell) => (isNaN(cell) ? cell : Number(cell)))
            );

            const ws = XLSX.utils.aoa_to_sheet(processedData);

            Object.keys(ws).forEach((key) => {
                if (ws[key].t === "s" && !isNaN(ws[key].v)) {
                    ws[key].t = "n"; // Set type to number
                }
            });

            const wb = XLSX.utils.book_new();
            XLSX.utils.book_append_sheet(wb, ws, "Sheet1");

            XLSX.writeFile(wb, "spreadsheet.xlsx");
        }
    };

    const saveToFile = async () => {
        const sheetsData = spreadInstances.map((spread) => ({
            sheetName: `Sheet${spreadInstances.indexOf(spread) + 1}`,
            data: spread.instance.getData().map((row: any[]) =>
                row.map((cell: any) => (typeof cell === "string" ? cell : parseFloat(cell)))
            ),
        }));

        try {
            const response = await fetch("/saveToFile", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({ sheetsData }),
            });

            const result = await response.json();

            if (result.success) {
                window.location.href = `/public/${result.filename}`;
            } else {
                alert(`Failed to save file: ${result.error}`);
            }
        } catch (error) {
            console.error("Error saving file:", error);
            alert("An error occurred while saving the file.");
        }
    };

    const deleteSpreadsheet = useCallback(
        (index: number) => {
            if (window.confirm("Are you sure you want to delete this spreadsheet?")) {
                setSpreadInstances((prevInstances) => {
                    const updatedInstances = prevInstances.filter((_, i) => i !== index);
                    localStorage.setItem(
                        "spreadsheets",
                        JSON.stringify(
                            updatedInstances.map((spread) => ({
                                data: spread.instance.getData(),
                            }))
                        )
                    );
                    return updatedInstances;
                });
                if (currentIndex >= spreadInstances.length - 1) {
                    setCurrentIndex(Math.max(0, currentIndex - 1));
                }
            }
        },
        [currentIndex, spreadInstances]
    );

    const handleFileUpload = useCallback(
        (event: React.ChangeEvent<HTMLInputElement>) => {
            const file = event.target.files?.[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = (e) => {
                    const data = new Uint8Array(e.target?.result as ArrayBuffer);
                    const workbook = XLSX.read(data, { type: "array" });
                    const sheetName = workbook.SheetNames[0];
                    const sheet = workbook.Sheets[sheetName];
                    const jsonData = XLSX.utils.sheet_to_json(sheet, { header: 1 });

                    const container = document.createElement("div");
                    const instance = jspreadsheet(container, {
                        ...options,
                        data: jsonData,
                    });

                    setSpreadInstances((prevInstances) => {
                        const updatedInstances = [
                            ...prevInstances,
                            { container, instance },
                        ];
                        localStorage.setItem(
                            "spreadsheets",
                            JSON.stringify(
                                updatedInstances.map((spread) => ({
                                    data: spread.instance.getData(),
                                }))
                            )
                        );
                        return updatedInstances;
                    });
                    setCurrentIndex(spreadInstances.length);
                };
                reader.readAsArrayBuffer(file);
            }
        },
        [spreadInstances]
    );

    return (
        <div className="container mx-auto p-6 bg-gray-50 min-h-screen">
            <div className="mb-6 flex flex-wrap gap-2">
                <input
                    type="text"
                    value={formula}
                    onChange={(e) => setFormula(e.target.value)}
                    placeholder="Enter formula"
                    className="p-2 border rounded-lg"
                />
                <button
                    onClick={calculateFormula}
                    className="bg-blue-500 text-white px-4 py-2 rounded-lg shadow-md hover:bg-blue-600 transition duration-300"
                >
                    Calculate Formula
                </button>
                <button
                    onClick={addSpreadsheet}
                    className="bg-green-500 text-white px-4 py-2 rounded-lg shadow-md hover:bg-green-600 transition duration-300"
                >
                    Add Spreadsheet
                </button>
                <button
                    onClick={downloadExcel}
                    className="bg-yellow-500 text-white px-4 py-2 rounded-lg shadow-md hover:bg-yellow-600 transition duration-300"
                >
                    <FaDownload />
                </button>
                <input
                    type="file"
                    accept=".xlsx"
                    onChange={handleFileUpload}
                    className="hidden"
                />
                <button
                    onClick={() => document.querySelector('input[type="file"]')?.click()}
                    className="bg-purple-500 text-white px-4 py-2 rounded-lg shadow-md hover:bg-purple-600 transition duration-300"
                >
                    <FaFileUpload />
                </button>
            </div>
            <div className="mb-6 flex flex-wrap gap-4">
                {spreadInstances.map((_, index) => (
                    <div
                        key={index}
                        className={`p-4 border rounded-lg shadow-md ${
                            currentIndex === index ? "bg-blue-100" : "bg-white"
                        } ${
                            currentIndex === index ? "block" : "hidden"
                        }`}
                    >
                        <button
                            onClick={() => selectSpreadsheet(index)}
                            className="text-blue-600 hover:underline mb-2 block"
                        >
                            Spreadsheet {index + 1}
                        </button>
                        <button
                            onClick={() => deleteSpreadsheet(index)}
                            className="text-red-600 hover:underline"
                        >
                            <FaTrash />
                        </button>
                        <div
                            ref={(el) => (containerRefs.current[index] = el)}
                            className="mt-4"
                        />
                    </div>
                ))}
            </div>
        </div>
    );
}
