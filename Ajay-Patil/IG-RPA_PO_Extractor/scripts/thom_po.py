#!/usr/bin/env python3
"""
extract_thom_po_structured.py

THOM-style PO extractor (single-PDF input) - FIXED VERSION

Function signature:
    extract_thom_po(pdf_path: str, output_excel_path: str = None, debug: bool = False)

CLI:
    python extract_thom_po_structured.py --pdf INPUT.pdf [--out OUTPUT.xlsx] [--debug]

Output columns (Option A):
    PO_No, Buyer, Vendor, PO_Date, PO_Header_ExFactoryDate,
    Subtotal, GST, Total_Units, Total_USD,
    Line_No, Style_Code, SKU, Description, Line_ExFactoryDate,
    Quantity, Weight, Unit_Price, Discount, Amount
"""
import os
import re
import json
import argparse
import logging
import math
from pathlib import Path
from typing import List, Dict, Any, Tuple

import pdfplumber
import pandas as pd
from dateutil import parser as dateparser

# ---------- Logging ----------
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

# ---------- Output schema (Option A) ----------
OUTPUT_COLUMNS = [
    "PO_No", "Buyer", "Vendor", "PO_Date", "PO_Header_ExFactoryDate",
    "Subtotal", "GST", "Total_Units", "Total_USD",
    "Line_No", "Style_Code", "SKU", "Description", "Line_ExFactoryDate",
    "Quantity", "Weight", "Unit_Price", "Discount", "Amount"
]


# ---------- Helpers ----------
def numeric_normalize(v: Any) -> str:
    if v is None:
        return ''
    s = str(v).strip().replace(',', '.').replace(' ', '').replace('£', '').replace('$', '')
    m = re.search(r'[-+]?\d*\.?\d+', s)
    return m.group(0) if m else ''


def to_float_safe(v: Any) -> float:
    """Return float or nan."""
    if v is None:
        return float('nan')
    s = str(v).strip().replace(',', '.').replace(' ', '')
    if s == '':
        return float('nan')
    try:
        return float(re.search(r'[-+]?\d*\.?\d+', s).group(0))
    except Exception:
        return float('nan')


def normalize_date_iso(date_str: str) -> str:
    if not date_str:
        return ''
    try:
        dt = dateparser.parse(date_str, dayfirst=True, fuzzy=True)
        return dt.strftime("%Y-%m-%d")
    except Exception:
        m = re.search(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', date_str)
        if m:
            try:
                return pd.to_datetime(m.group(1), dayfirst=True).strftime("%Y-%m-%d")
            except Exception:
                return ''
        return ''


def read_pdf_text(pdf_path: str) -> Tuple[str, List[str], List]:
    """Return combined_text, per_page_texts, pdfplumber_tables."""
    pages = []
    tables = []
    try:
        with pdfplumber.open(pdf_path) as pdf:
            for p in pdf.pages:
                page_text = p.extract_text() or ''
                pages.append(page_text)
    except Exception as e:
        raise RuntimeError(f"Failed to open/read PDF: {e}")
    combined = "\n\n".join(pages)
    return combined, pages, tables


# ---------- Header parsing ----------
def parse_headers(combined_text: str) -> Dict[str, str]:
    """Extract header fields for THOM-style PO."""
    out = {k: "" for k in ["PO_No", "Buyer", "Vendor", "PO_Date", "PO_Header_ExFactoryDate", "Subtotal", "GST", "Total_Units", "Total_USD"]}

    # PO No extraction
    po_patterns = [
        r'Order\s+ref\s*[:\-]?\s*(\S+)',
        r'Orders?\s*n°?\s*(\S+)',
        r'Ordine\s*n°\s*(\S+)',
        r'Purchase\s+Order\s*(?:No|#|number)?\s*[:\-]?\s*(\S+)'
    ]
    
    for pattern in po_patterns:
        m = re.search(pattern, combined_text, re.IGNORECASE)
        if m:
            out["PO_No"] = m.group(1).strip()
            break

    # Buyer extraction
    if 'HORIZON DISTRIBUTION' in combined_text:
        out["Buyer"] = "HORIZON DISTRIBUTION"
    elif 'THOM FRANCE' in combined_text or 'THOM SAS' in combined_text:
        out["Buyer"] = "THOM FRANCE"
    elif 'Stroili Oro' in combined_text:
        out["Buyer"] = "Stroili Oro S.p.A."

    # Vendor extraction
    if 'INTER GOLD' in combined_text:
        out["Vendor"] = "INTER GOLD (INDIA) PRIVATE LIMITED"

    # PO Date extraction
    date_patterns = [
        r'Date of order\s*[:\-]?\s*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})',
        r'Data\s*[:\-]?\s*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})',
        r'Date\s*[:\-]?\s*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})'
    ]
    
    for pattern in date_patterns:
        m = re.search(pattern, combined_text, re.IGNORECASE)
        if m:
            out["PO_Date"] = normalize_date_iso(m.group(1))
            break

    # Total amounts
    total_match = re.search(r'Order total excl tax[^\d]*([0-9\., ]+)', combined_text, re.IGNORECASE)
    if total_match:
        out["Subtotal"] = numeric_normalize(total_match.group(1))
        out["Total_USD"] = numeric_normalize(total_match.group(1))

    return out


# ---------- Item parsing for different PDF types ----------
def parse_horizon_items(combined_text: str) -> List[Dict[str, Any]]:
    """Parse items from HORIZON DISTRIBUTION format (310411.pdf)"""
    items = []
    
    # Find the item table section
    lines = combined_text.split('\n')
    in_items_section = False
    
    for i, line in enumerate(lines):
        # Look for the start of the items table
        if 'Provider ref' in line and 'Product reference' in line:
            in_items_section = True
            continue
            
        if in_items_section:
            # Check if we've reached the end of items
            if 'Currency USD' in line or 'Order total' in line or 'Page' in line:
                break
                
            # Parse item lines - they start with patterns like BR-, ER-, NK-, RG-, L-ER-, etc.
            if re.match(r'^(BR-|ER-|NK-|RG-|L-ER-|L-RG-|PN-)', line.strip()):
                parts = re.split(r'\s{2,}', line.strip())  # Split by multiple spaces
                if len(parts) >= 6:
                    item = {
                        "Style_Code": parts[0].strip(),
                        "SKU": parts[1].strip() if len(parts) > 1 else "",
                        "Description": parts[2].strip() if len(parts) > 2 else "",
                        "Line_ExFactoryDate": "",
                        "Quantity": numeric_normalize(parts[4]) if len(parts) > 4 else "",
                        "Weight": numeric_normalize(parts[3]) if len(parts) > 3 else "",
                        "Unit_Price": numeric_normalize(parts[5]) if len(parts) > 5 else "",
                        "Discount": "",
                        "Amount": numeric_normalize(parts[6]) if len(parts) > 6 else ""
                    }
                    # If amount is missing but we have quantity and price, calculate it
                    if not item["Amount"] and item["Quantity"] and item["Unit_Price"]:
                        qty = to_float_safe(item["Quantity"])
                        price = to_float_safe(item["Unit_Price"])
                        if not math.isnan(qty) and not math.isnan(price):
                            item["Amount"] = f"{qty * price:.2f}"
                    
                    items.append(item)
    
    return items


def parse_thom_france_items(combined_text: str) -> List[Dict[str, Any]]:
    """Parse items from THOM FRANCE format (commandes_4200099157.pdf)"""
    items = []
    
    lines = combined_text.split('\n')
    
    for line in lines:
        # Look for lines with product references and prices
        if 'L-RG' in line and 'USD' in line:
            # Extract components from the line
            parts = line.split()
            if len(parts) >= 10:
                item = {
                    "Style_Code": parts[1] if len(parts) > 1 else "",
                    "SKU": parts[3] if len(parts) > 3 else "",
                    "Description": ' '.join(parts[4:7]) if len(parts) > 7 else ' '.join(parts[4:]),
                    "Line_ExFactoryDate": "",
                    "Quantity": "1",  # Default to 1 for single item POs
                    "Weight": numeric_normalize(parts[9]) if len(parts) > 9 else "",
                    "Unit_Price": numeric_normalize(parts[7]),
                    "Discount": "",
                    "Amount": numeric_normalize(parts[7])
                }
                items.append(item)
                break
    
    return items


def parse_stroili_oro_items(combined_text: str) -> List[Dict[str, Any]]:
    """Parse items from Stroili Oro format (PO25-0001-058565.pdf)"""
    items = []
    
    lines = combined_text.split('\n')
    in_items_section = False
    
    for i, line in enumerate(lines):
        # Look for the start of items table
        if 'Referenza Articolo' in line and 'Descrizione' in line:
            in_items_section = True
            continue
            
        if in_items_section:
            # Check for end of items section
            if 'Totale Pezzi' in line or 'Condizioni di fornitura' in line:
                break
                
            # Look for product lines (start with 9KT- or similar patterns)
            if re.match(r'^(9KT-|RG-|ER-|NK-)', line.strip()):
                # Split by multiple spaces to get columns
                parts = re.split(r'\s{2,}', line.strip())
                if len(parts) >= 7:
                    item = {
                        "Style_Code": parts[0].strip(),
                        "SKU": "",
                        "Description": parts[1].strip() if len(parts) > 1 else "",
                        "Line_ExFactoryDate": normalize_date_iso(parts[9]) if len(parts) > 9 else "",
                        "Quantity": numeric_normalize(parts[2]) if len(parts) > 2 else "",
                        "Weight": numeric_normalize(parts[3]) if len(parts) > 3 else "",
                        "Unit_Price": numeric_normalize(parts[6]) if len(parts) > 6 else "",
                        "Discount": numeric_normalize(parts[4]) if len(parts) > 4 else "",
                        "Amount": ""
                    }
                    
                    # Try to find amount in next line if available
                    if i + 1 < len(lines):
                        next_line = lines[i + 1].strip()
                        if next_line and re.search(r'\d+\.\d{2}', next_line):
                            amount_match = re.search(r'(\d+\.\d{2})', next_line)
                            if amount_match:
                                item["Amount"] = amount_match.group(1)
                    
                    items.append(item)
    
    return items


def parse_items_adaptive(combined_text: str) -> List[Dict[str, Any]]:
    """Adaptive item parser that detects PDF type and uses appropriate parser"""
    
    # Detect PDF type and use appropriate parser
    if 'HORIZON DISTRIBUTION' in combined_text and 'ORDER FORM' in combined_text:
        logging.info("Detected HORIZON DISTRIBUTION format")
        return parse_horizon_items(combined_text)
    elif 'Stroili Oro' in combined_text and 'ORDINE DI ACQUISTO' in combined_text:
        logging.info("Detected Stroili Oro format")
        return parse_stroili_oro_items(combined_text)
    elif 'THOM FRANCE' in combined_text or 'Orders n°' in combined_text:
        logging.info("Detected THOM FRANCE format")
        return parse_thom_france_items(combined_text)
    else:
        logging.info("Using generic text parser as fallback")
        return parse_items_generic(combined_text)


def parse_items_generic(combined_text: str) -> List[Dict[str, Any]]:
    """Generic text-based item parser as fallback"""
    items = []
    
    lines = combined_text.split('\n')
    
    for line in lines:
        line = line.strip()
        # Look for lines that have product codes and numbers
        if (re.match(r'^[A-Z]{2,3}-[A-Z0-9]', line) or 
            re.match(r'^\d+[A-Z]-[A-Z]{2}-', line)) and re.search(r'\d+\.\d{2}', line):
            
            # Try to extract components
            parts = re.split(r'\s{2,}', line)
            if len(parts) >= 3:
                # Find quantity - look for integers
                qty = "1"
                for part in parts:
                    if part.isdigit() and 1 <= int(part) <= 1000:
                        qty = part
                        break
                
                # Find price - look for decimal numbers
                price = ""
                for part in parts:
                    if re.match(r'^\d+\.\d{2}$', part):
                        price = part
                        break
                
                if price:
                    item = {
                        "Style_Code": parts[0],
                        "SKU": parts[1] if len(parts) > 1 else "",
                        "Description": ' '.join(parts[2:-3]) if len(parts) > 5 else ' '.join(parts[2:]),
                        "Line_ExFactoryDate": "",
                        "Quantity": qty,
                        "Weight": "",
                        "Unit_Price": price,
                        "Discount": "",
                        "Amount": price if qty == "1" else ""
                    }
                    items.append(item)
    
    return items


def compute_amount_from_row(it: Dict[str, Any]) -> str:
    """Calculate amount from quantity and unit price"""
    q = to_float_safe(it.get("Quantity", ""))
    u = to_float_safe(it.get("Unit_Price", ""))
    
    if not math.isnan(q) and not math.isnan(u):
        amount = q * u
        return f"{amount:.2f}"
    
    # Return existing amount if calculation not possible
    return it.get("Amount", "")


# ---------- Main extraction function ----------
def extract_thom_po(pdf_path: str, output_excel_path: str = None, debug: bool = False) -> str:
    """
    Extract THOM PO from single PDF and write Excel.
    Returns output Excel path.
    """
    pdf_path = str(pdf_path)
    pdf_name = Path(pdf_path).stem
    if not output_excel_path:
        output_excel_path = fr"D:\RPA\Purchase_Orders_Extracted_{pdf_name}.xlsx"

    logging.info("Reading PDF text...")
    combined_text, pages_text, tables = read_pdf_text(pdf_path)

    if debug:
        dbg_dir = Path(output_excel_path).with_suffix("")
        dbg_dir = Path(dbg_dir.parent) / f"{pdf_name}_debug"
        dbg_dir.mkdir(parents=True, exist_ok=True)
        (dbg_dir / "combined_text.txt").write_text(combined_text, encoding="utf-8")
        logging.info("Wrote debug combined_text.txt")

    logging.info("Parsing headers...")
    headers = parse_headers(combined_text)
    logging.info(f"Parsed headers: PO_No={headers.get('PO_No')}")

    logging.info("Parsing items using adaptive parser...")
    items = parse_items_adaptive(combined_text)
    logging.info(f"Found {len(items)} items")

    if debug:
        dbg_items = {"items": items, "headers": headers}
        dbg_items_path = Path(output_excel_path).with_suffix(".debug.json")
        with open(dbg_items_path, "w", encoding="utf-8") as f:
            json.dump(dbg_items, f, indent=2, default=str)
        logging.info("Wrote debug JSON: %s", dbg_items_path)

    # Create output rows
    rows = []
    for idx, item in enumerate(items, 1):
        amt = compute_amount_from_row(item)
        row = {c: "" for c in OUTPUT_COLUMNS}
        row["PO_No"] = headers.get("PO_No", "")
        row["Buyer"] = headers.get("Buyer", "")
        row["Vendor"] = headers.get("Vendor", "")
        row["PO_Date"] = headers.get("PO_Date", "")
        row["PO_Header_ExFactoryDate"] = headers.get("PO_Header_ExFactoryDate", "")
        row["Subtotal"] = headers.get("Subtotal", "")
        row["GST"] = headers.get("GST", "")
        row["Total_Units"] = headers.get("Total_Units", "")
        row["Total_USD"] = headers.get("Total_USD", "")
        row["Line_No"] = f"{idx:04d}"
        row["Style_Code"] = item.get("Style_Code", "")
        row["SKU"] = item.get("SKU", "")
        row["Description"] = item.get("Description", "")
        row["Line_ExFactoryDate"] = item.get("Line_ExFactoryDate", "")
        row["Quantity"] = item.get("Quantity", "")
        row["Weight"] = item.get("Weight", "")
        row["Unit_Price"] = item.get("Unit_Price", "")
        row["Discount"] = item.get("Discount", "")
        row["Amount"] = amt
        rows.append(row)

    # If no items found, create header-only row
    if not rows:
        row = {c: "" for c in OUTPUT_COLUMNS}
        row["PO_No"] = headers.get("PO_No", "")
        row["Buyer"] = headers.get("Buyer", "")
        row["Vendor"] = headers.get("Vendor", "")
        row["PO_Date"] = headers.get("PO_Date", "")
        rows.append(row)

    df = pd.DataFrame(rows, columns=OUTPUT_COLUMNS)

    # ensure output dir exists
    out_dir = os.path.dirname(output_excel_path)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    df.to_excel(output_excel_path, index=False)
    logging.info("Wrote Excel: %s (rows: %d)", output_excel_path, len(df))

    return output_excel_path


# ---------- CLI ----------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract THOM PO from a PDF (single-file).")
    parser.add_argument("--pdf", required=True, help="Path to the PDF file.")
    parser.add_argument("--out", required=False, help="Optional output Excel path.")
    parser.add_argument("--debug", action="store_true", help="Write debug files (combined text + candidates).")
    args = parser.parse_args()
    try:
        out = extract_thom_po(args.pdf, args.out, debug=args.debug)
        print("Extraction complete:", out)
    except Exception:
        logging.exception("Extraction failed.")
        raise