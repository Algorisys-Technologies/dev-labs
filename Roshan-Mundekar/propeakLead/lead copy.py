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
    r"^For\s+(?P<prod>[^\n]+)",
    r"I want to (?:buy|purchase|order|enquire about) (?P<prod>[^\n]+)",
    r"My Requirement is for (?P<prod>[^\n]+)",
    r"I am interested in (?P<prod>[^\n]+)",
    r"I viewed your product[,:\s]*['\"]?(?P<prod>[^\n]+)",
    r"(?:Aquapetal|Cosmetic Beads)",
    r"(?:price|cost)\s+for\s+.*?\s+of\s+([^\n]+)"
]

IGNORE_PHRASES = [
    "thanks for your enquiry", "share more details?", "catalog link",
    "hi", "hello", "dear", "thanks", "thank you", "regards",
    "best regards", "share details", "catalog", "brochure",
    "price list", "Hi list", "Hi", "HI"
]

IGNORE_WORDS = {
    'hi', 'hello', 'dear', 'thanks', 'thank', 'regards',
    'best', 'share', 'details', 'catalog', 'brochure', 'price', 'list'
}

@app.post("/extract_product")
async def extract_product(payload: MessageIn):
    text = payload.message
    products = set()
    

    # Regex extraction
    for pat in PRODUCT_PATTERNS:
        matches = re.findall(pat, text, re.IGNORECASE)
        for match in matches:
            if isinstance(match, tuple):
                match = match[0]
            clean_prod = re.sub(r'[^\w\s]+$', '', match.split("\n")[0].strip())
            products.add(clean_prod)

    # SpaCy extraction
    doc = nlp(text)
    for ent in doc.ents:
        if ent.label_ == "CHEMICAL":
            clean_ent = re.sub(r'[^\w\s]+$', '', ent.text.split("\n")[0].strip())
            products.add(clean_ent)

    # Enhanced filtering
    filtered_products = set()
    for p in products:
        # Remove trailing punctuation and ignored words
        clean = re.sub(r'[^\w\s]+$', '', p.strip())
        words = [word for word in clean.split() 
                if word.strip().lower() not in IGNORE_WORDS]
        clean = ' '.join(words)
        
        # Check against ignore phrases and validate length
        if (clean.lower() not in [p.lower() for p in IGNORE_PHRASES] and
            len(clean) > 0 and
            not re.match(r'^\W*$', clean)):
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