# 🚀 IndiaMart Lead Product Extractor

A FastAPI-based intelligent product extraction system that automatically identifies and extracts product names from IndiaMart customer inquiry messages using hybrid NLP techniques.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [How It Works](#how-it-works)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Running the Application](#running-the-application)
- [API Usage](#api-usage)
- [Code Explanation](#code-explanation)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This application processes customer inquiry messages from IndiaMart and intelligently extracts product names mentioned in those messages. It uses a combination of:
- **Regular Expression (Regex) Pattern Matching** - For structured text patterns
- **SpaCy NER (Named Entity Recognition)** - For chemical/product entity detection
- **Smart Filtering** - To remove noise and irrelevant text

---

## ✨ Features

✅ **Hybrid Extraction**: Combines regex patterns and AI-based NER for accurate product detection  
✅ **Smart Filtering**: Automatically removes greetings, pleasantries, and irrelevant phrases  
✅ **Multi-Pattern Support**: Handles various inquiry formats (8+ different patterns)  
✅ **CORS Enabled**: Ready for frontend integration  
✅ **RESTful API**: Simple POST endpoint for easy integration  
✅ **Clean Output**: Returns deduplicated, formatted product names  

---

## 🔍 How It Works

### **Step 1: Regex Pattern Matching**
The system searches for common inquiry patterns like:
- "For **Aquapetal Beads**"
- "I want to buy **Cosmetic Beads**"
- "My Requirement is for **Chemical XYZ**"
- "I am interested in **Product ABC**"
- "I viewed your product **Product Name**"

### **Step 2: SpaCy NER Extraction**
Uses the `en_ner_bc5cdr_md` model to identify chemical/product entities in the text.

### **Step 3: Filtering & Cleaning**
- Removes common words: hi, hello, thanks, regards, catalog, brochure
- Removes trailing punctuation
- Filters out empty or invalid results
- Deduplicates product names

### **Step 4: Return Results**
Returns a clean, formatted list of products joined by " & ".

---

## 📁 Project Structure

```
propeakLead/
│
├── lead.py              # Main application (RECOMMENDED)
├── lead copy.py         # Backup version
├── test.py              # Simplified test version
├── requirements.txt     # Dependencies (needs formatting)
└── README.md            # This file
```

### **File Descriptions**

| File | Purpose | Status |
|------|---------|--------|
| `lead.py` | **Main production file** with comprehensive filtering | ✅ Use This |
| `lead copy.py` | Backup copy (almost identical to lead.py) | 📦 Backup |
| `test.py` | Simplified version with basic filtering | 🧪 Testing |
| `requirements.txt` | Installation commands | ⚠️ Needs fixing |

---

## 🛠️ Installation

### **Prerequisites**
- Python 3.8 or higher
- pip (Python package manager)

### **Step-by-Step Installation**

#### **1. Clone or Navigate to Project Directory**
```bash
cd d:\ALGORIS\Propeak_server\propeakLead
```

#### **2. Create Virtual Environment (Recommended)**
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate

# On Linux/Mac:
source venv/bin/activate
```

#### **3. Install Dependencies**

Run these commands **one by one** in order:

```bash
# Install FastAPI and Uvicorn
pip install fastapi uvicorn

# Install SpaCy
pip install spacy

# Install SciSpacy (without dependencies first)
pip install scispacy==0.5.3 --no-deps

# Install SciSpacy with dependencies
pip install scispacy==0.5.3

# Download the SpaCy NER model
pip install https://s3-us-west-2.amazonaws.com/ai2-s2-scispacy/releases/v0.5.3/en_ner_bc5cdr_md-0.5.3.tar.gz
```

#### **4. Verify Installation**
```bash
python -c "import spacy; nlp = spacy.load('en_ner_bc5cdr_md'); print('✅ Installation successful!')"
```

---

## 🚀 Running the Application

### **Method 1: Using Uvicorn (Recommended)**

```bash
uvicorn lead:app --reload --host 0.0.0.0 --port 8000
```

**Flags Explained:**
- `lead:app` - Runs the `app` object from `lead.py`
- `--reload` - Auto-restarts on code changes (development mode)
- `--host 0.0.0.0` - Makes server accessible from other devices
- `--port 8000` - Runs on port 8000

### **Method 2: Direct Python Execution**

```bash
python lead.py
```

### **Expected Output**
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [12345] using StatReload
INFO:     Started server process [12346]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

### **Access the API**
- **API Endpoint**: `http://localhost:8000/extract_product`
- **Interactive Docs**: `http://localhost:8000/docs`
- **Alternative Docs**: `http://localhost:8000/redoc`

---

## 📡 API Usage

### **Endpoint**
```
POST /extract_product
```

### **Request Format**
```json
{
  "message": "Hi, I want to buy Aquapetal Beads for my cosmetic business. Quantity: 500kg",
  "date": "2024-02-06"
}
```

### **Response Format**
```json
{
  "product": "Aquapetal Beads",
  "date": "2024-02-06",
  "message": "Hi, I want to buy Aquapetal Beads for my cosmetic business. Quantity: 500kg"
}
```

### **Example Using cURL**
```bash
curl -X POST "http://localhost:8000/extract_product" \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"I am interested in Cosmetic Beads\", \"date\": \"2024-02-06\"}"
```

### **Example Using Python Requests**
```python
import requests

url = "http://localhost:8000/extract_product"
payload = {
    "message": "For Aquapetal Beads. I want to know the price.",
    "date": "2024-02-06"
}

response = requests.post(url, json=payload)
print(response.json())
```

### **Example Using JavaScript (Fetch)**
```javascript
fetch('http://localhost:8000/extract_product', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    message: "My Requirement is for Chemical XYZ",
    date: "2024-02-06"
  })
})
.then(response => response.json())
.then(data => console.log(data));
```

---

## 💻 Code Explanation

### **Main Components**

#### **1. FastAPI Application Setup**
```python
app = FastAPI(title="IndiaMart Lead Product Extractor")
```
Creates the FastAPI application instance.

#### **2. CORS Middleware**
```python
app.add_middleware(CORSMiddleware, allow_origins=["*"], ...)
```
Enables Cross-Origin Resource Sharing for frontend integration.

#### **3. SpaCy NLP Model**
```python
nlp = spacy.load("en_ner_bc5cdr_md")
```
Loads the biomedical/chemical Named Entity Recognition model.

#### **4. Product Patterns (Regex)**
```python
PRODUCT_PATTERNS = [
    r"^For\s+(?P<prod>[^\n]+)",
    r"I want to (?:buy|purchase|order|enquire about) (?P<prod>[^\n]+)",
    # ... more patterns
]
```
Regular expressions to match common inquiry formats.

#### **5. Ignore Lists**
```python
IGNORE_PHRASES = ["thanks for your enquiry", "catalog link", ...]
IGNORE_WORDS = {'hi', 'hello', 'dear', 'thanks', ...}
```
Filters out noise and irrelevant text.

#### **6. Extraction Logic**

**Step A: Regex Extraction**
```python
for pat in PRODUCT_PATTERNS:
    matches = re.findall(pat, text, re.IGNORECASE)
    # Process matches...
```

**Step B: SpaCy NER Extraction**
```python
doc = nlp(text)
for ent in doc.ents:
    if ent.label_ == "CHEMICAL":
        # Add to products...
```

**Step C: Filtering**
```python
# Remove ignored words
words = [word for word in clean.split() 
         if word.strip().lower() not in IGNORE_WORDS]
```

**Step D: Return Results**
```python
product_str = " & ".join(sorted(filtered_products))
```

---

## 🐛 Troubleshooting

### **Issue 1: Module Not Found Error**
```
ModuleNotFoundError: No module named 'spacy'
```
**Solution**: Install dependencies again
```bash
pip install fastapi uvicorn spacy scispacy
```

### **Issue 2: SpaCy Model Not Found**
```
OSError: [E050] Can't find model 'en_ner_bc5cdr_md'
```
**Solution**: Download the model
```bash
pip install https://s3-us-west-2.amazonaws.com/ai2-s2-scispacy/releases/v0.5.3/en_ner_bc5cdr_md-0.5.3.tar.gz
```

### **Issue 3: Port Already in Use**
```
ERROR: [Errno 10048] error while attempting to bind on address ('0.0.0.0', 8000)
```
**Solution**: Use a different port
```bash
uvicorn lead:app --reload --port 8001
```

### **Issue 4: CORS Errors in Browser**
**Solution**: The app already has CORS enabled with `allow_origins=["*"]`. If still facing issues, check your frontend request headers.

### **Issue 5: No Products Extracted**
**Possible Causes**:
- Message doesn't match any patterns
- All extracted products were filtered out as noise
- SpaCy model didn't detect any chemical entities

**Solution**: Check the patterns in `PRODUCT_PATTERNS` and adjust if needed.

---

## 📝 Development Notes

### **Choosing the Right File**
- **Production**: Use `lead.py` (most comprehensive filtering)
- **Testing**: Use `test.py` (simpler, faster)
- **Backup**: `lead copy.py` is nearly identical to `lead.py`

### **Customization**

#### **Add New Patterns**
Edit the `PRODUCT_PATTERNS` list in `lead.py`:
```python
PRODUCT_PATTERNS = [
    # Add your custom pattern here
    r"Looking for (?P<prod>[^\n]+)",
]
```

#### **Modify Ignore Words**
Edit `IGNORE_WORDS` or `IGNORE_PHRASES`:
```python
IGNORE_WORDS = {
    'hi', 'hello', 'your_custom_word'
}
```

#### **Change Port**
Modify the last line in `lead.py`:
```python
uvicorn.run("app:app", host="0.0.0.0", port=9000)  # Changed to 9000
```

---

## 🔐 Security Considerations

⚠️ **Current Configuration**: CORS is set to `allow_origins=["*"]` which allows all origins.

**For Production**:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],  # Specific domain
    allow_methods=["POST"],
    allow_headers=["Content-Type"],
)
```

---

## 📊 Testing Examples

### **Test Case 1: Simple Inquiry**
```json
Input: "I want to buy Aquapetal Beads"
Output: {"product": "Aquapetal Beads", ...}
```

### **Test Case 2: Multiple Products**
```json
Input: "For Cosmetic Beads and Chemical XYZ"
Output: {"product": "Chemical XYZ & Cosmetic Beads", ...}
```

### **Test Case 3: Noisy Message**
```json
Input: "Hi, thanks for your catalog. I am interested in Product ABC. Regards."
Output: {"product": "Product ABC", ...}
```

### **Test Case 4: No Product**
```json
Input: "Hi, please share your catalog and price list. Thanks."
Output: {"product": null, ...}
```

---

## 🤝 Contributing

To improve this project:
1. Test with real IndiaMart messages
2. Add new patterns for better coverage
3. Improve filtering logic
4. Add unit tests
5. Optimize performance

---

## 📞 Support

For issues or questions:
- Check the [Troubleshooting](#troubleshooting) section
- Review the [API Usage](#api-usage) examples
- Test with the interactive docs at `/docs`

---

## 📄 License

Internal project for ALGORIS/Propeak Server.

---

**Last Updated**: February 6, 2026  
**Version**: 1.0  
**Maintained by**: Development Team
