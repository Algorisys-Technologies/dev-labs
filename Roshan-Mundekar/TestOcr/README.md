# 🪪 Indian ID Card OCR Refinement with OpenAI & PaddleOCR

This project processes Indian ID card images using OCR, cleans noisy background, extracts readable text, and refines it using OpenAI GPT to produce accurate, well-structured information.

---

## 📦 Features

- ✅ Background removal using `rembg`
- ✅ OCR using PaddleOCR (PP-OCRv4 + SVTR_LCNet)
- ✅ Text refinement using OpenAI GPT (grammar correction + structure)
- ✅ Filters out junk, misread characters, and unwanted tokens (e.g., "PIC", "3PIC", "H382")
- ✅ Preserves original names, card numbers, and identity information
- ✅ Saves refined results and visual output with bounding boxes

---

## 🚀 How It Works

1. **Input**: You provide an image of an Indian Voter ID card (`.jpg`/`.png`).
2. **Step 1 - Background Removal**: `rembg` removes noisy image background.
3. **Step 2 - OCR Extraction**: `PaddleOCR` extracts raw text and bounding boxes from image.
4. **Step 3 - Text Refinement**: `OpenAI GPT` cleans the text:
   - Fixes spacing, grammar
   - Removes junk (e.g., `33385afH`, `PIC`)
   - Preserves name, EPIC number, Card No, and Mother's Name
   - Outputs readable, accurate text

---

## 🧪 Sample Input vs Final Result

**OCR Raw Output**:
```text
ELECTION COMMISSION OF INDIA
OFFICE OF THE ELECTORAL REGISTRATION OFFICER
STATE ASSEMBLY/ PARLIAMENTARY CONSTITUENCY
UGU1996124
EPIC NO: H383
Name: TULSITETYAL
Mother's Name: SHUBHLATA
