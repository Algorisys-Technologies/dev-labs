from fastapi import FastAPI
from pydantic import BaseModel
import re
import spacy
from fastapi.middleware.cors import CORSMiddleware

nlp = spacy.load("en_ner_bc5cdr_md")
app = FastAPI(title="IndiaMart Lead Product Extractor")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class MessageIn(BaseModel):
    message: str
    date: str

PRODUCT_PATTERNS = [
    r"^For\s+(?P<prod>[^\n]+)",  # Capture until first newline
    r"I want to (?:buy|purchase|order|enquire about) (?P<prod>[^\n]+)",
    r"My Requirement is for (?P<prod>[^\n]+)",
    r"I am interested in (?P<prod>[^\n]+)",
    r"I viewed your product[,:\s]*['\"]?(?P<prod>[^\n]+)",  # Capture until newline
    r"(?:Aquapetal|Cosmetic Beads)",  # Specific pattern for known product names
    r"(?:price|cost)\s+for\s+.*?\s+of\s+([^\n]+)"
]

IGNORE_PHRASES = [
    "thanks for your enquiry",
    "share more details?",
    "catalog link",
    "hi", "hello", "dear", "thanks", "thank you", 
    "regards", "best regards", "share details",
    "catalog", "brochure", "price list", "Hi list"
]

@app.post("/extract_product")
async def extract_product(payload: MessageIn):
    text = payload.message
    products = set()

    # Regex extraction with newline handling
    for pat in PRODUCT_PATTERNS:
        matches = re.findall(pat, text, re.IGNORECASE)
        for match in matches:
            clean_prod = match.split("\n")[0].strip()  # Split at first newline
            products.add(clean_prod)

    # SpaCy extraction with newline handling
    doc = nlp(text)
    for ent in doc.ents:
        if ent.label_ == "CHEMICAL":
            clean_ent = ent.text.split("\n")[0].strip()  # Split at first newline
            products.add(clean_ent)

    # Post-processing to remove quantity mentions
    filtered_products = set()
    for p in products:
        # Remove lines containing "Quantity" or "Qty"
        clean = " ".join([word for word in p.split() 
                        if not re.match(r"(quantity|qty)", word, re.IGNORECASE)])
        if clean:
            filtered_products.add(clean)

    product_str = " & ".join(sorted(filtered_products)) if filtered_products else None

    return {
        "product": product_str,
        "date": payload.date,
        "message": text
    }
    
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=8000)