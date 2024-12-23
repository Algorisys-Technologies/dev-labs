// backend/saveToFile.ts (example file path)
import { json } from "@remix-run/node";
import { writeFile } from "fs/promises";
import * as XLSX from "xlsx";
import { v4 as uuidv4 } from 'uuid';
import path from 'path';

export const action = async ({ request }: { request: Request }) => {
  try {
    const { sheetsData } = await request.json();

    if (!Array.isArray(sheetsData) || sheetsData.length === 0) {
      return json({ success: false, error: "Invalid data format or empty data." }, { status: 400 });
    }

    // Create a new workbook
    const workbook = XLSX.utils.book_new();

    // Add each sheet to the workbook
    sheetsData.forEach(sheet => {
      const { sheetName, data } = sheet;
      const worksheet = XLSX.utils.aoa_to_sheet(data);
      XLSX.utils.book_append_sheet(workbook, worksheet, sheetName);
    });

    // Generate a unique filename
    const filename = `spreadsheet_${uuidv4()}.xlsx`;
    const filePath = path.join(process.cwd(), 'public', filename); // Adjust path if necessary
    const buffer = XLSX.write(workbook, { bookType: "xlsx", type: "buffer" });

    // Save the file in the 'public' directory
    await writeFile(filePath, buffer);

    return json({ success: true, filename });
  } catch (error) {
    console.error("Error writing file:", error);
    return json({ success: false, error: "Failed to save file." }, { status: 500 });
  }
};
