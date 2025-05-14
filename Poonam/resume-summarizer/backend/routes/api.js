import express from 'express';
import multer from 'multer';
import axios from 'axios';
import fs from 'fs';
import dotenv from 'dotenv';
import path from 'path';
import { extractTextFromPDF } from './utils/pdfExtractor.js';

dotenv.config();

const router = express.Router();
const upload = multer();

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`;

// POST /api/upload
router.post('/upload', upload.single('resume'), async (req, res) => {
  const filePath = './tempfile.pdf';

  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    fs.writeFileSync(filePath, req.file.buffer);

    const resumeText = await extractTextFromPDF(filePath);
    const prompt = `Summarize this resume:\n${resumeText}`;

    const response = await axios.post(GEMINI_URL, {
      contents: [
        {
          parts: [{ text: prompt }]
        }
      ]
    });

    const summary = response.data?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!summary) {
      throw new Error('Gemini API did not return a summary.');
    }

    res.json({ summary });
  } catch (error) {
    console.error('Error:', error.message);
    res.status(500).json({ error: 'Failed to summarize resume' });
  } finally {
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  }
});

export default router;
