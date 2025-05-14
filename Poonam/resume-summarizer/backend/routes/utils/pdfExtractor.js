// backend/routes/utils/pdfExtractor.js
import fs from 'fs';
import path from 'path';
import { PDFExtract } from 'pdf.js-extract';

export async function extractTextFromPDF(filePath) {
  const absolutePath = path.resolve(filePath);
  if (!fs.existsSync(absolutePath)) {
    throw new Error(`File not found: ${absolutePath}`);
  }

  const buffer = fs.readFileSync(absolutePath);
  const pdfExtract = new PDFExtract();
  const options = {}; // Add options if needed

  return new Promise((resolve, reject) => {
    pdfExtract.extractBuffer(buffer, options, (err, data) => {
      if (err) return reject(err);

      let fullText = "";
      data.pages.forEach((page) => {
        const pageText = page.content
          .map(item => item.str)
          .filter(Boolean)
          .join(" ");
        fullText += pageText + "\n";
      });

      resolve(fullText);
    });
  });
}
