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
    s = str(v).strip().replace(',', '').replace('£', '').replace('$', '').replace(' ', '')
    m = re.search(r'[-+]?\d*\.?\d+', s)
    return m.group(0) if m else ''


def to_float_safe(v: Any) -> float:
    """Return float or nan. If percent string passed, return fraction (0.10 for '10%')."""
    if v is None:
        return float('nan')
    s = str(v).strip().replace(',', '').replace('£', '').replace('$', '').replace(' ', '')
    if s == '':
        return float('nan')
    if '%' in s:
        try:
            return float(s.replace('%', '').strip()) / 100.0
        except Exception:
            return float('nan')
    try:
        return float(re.search(r'[-+]?\d*\.?\d+', s).group(0))
    except Exception:
        return float('nan')


def normalize_date_iso(date_str: str) -> str:
    if not date_str:
        return ''
    try:
        dt = dateparser.parse(date_str, fuzzy=True)
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
                try:
                    tbs = p.extract_tables() or []
                    for t in tbs:
                        if t and any(any(cell for cell in row if cell) for row in t):
                            tables.append(t)
                except Exception:
                    pass
                pages.append(page_text)
    except Exception as e:
        raise RuntimeError(f"Failed to open/read PDF: {e}")
    combined = "\n\n".join(pages)
    return combined, pages, tables


# ---------- Header parsing ----------
def parse_headers(combined_text: str, pages_text: List[str], tables: List) -> Dict[str, str]:
    """Extract header fields for THOM-style PO (Option A)."""
    out = {k: "" for k in ["PO_No", "Buyer", "Vendor", "PO_Date", "PO_Header_ExFactoryDate", "Subtotal", "GST", "Total_Units", "Total_USD"]}

    # PO No - multiple patterns
    m = re.search(r'Order\s+ref\s*[:\-]?\s*([A-Z0-9\-\_]{3,})', combined_text, re.IGNORECASE)
    if m:
        out["PO_No"] = m.group(1).strip()
    else:
        m = re.search(r'Purchase\s+Order\s*(?:No|#|number)?\s*[:\-]?\s*([A-Z0-9\-\_]{3,})', combined_text, re.IGNORECASE)
        if m:
            out["PO_No"] = m.group(1).strip()
        else:
            m = re.search(r'Orders?\s*n°?\s*([A-Z0-9\-\_]{3,})', combined_text, re.IGNORECASE)
            if m:
                out["PO_No"] = m.group(1).strip()
            else:
                m = re.search(r'Ordine\s*n°\s*([A-Z0-9\-\_]{3,})', combined_text, re.IGNORECASE)
                if m:
                    out["PO_No"] = m.group(1).strip()

    # Buyer extraction
    if 'HORIZON DISTRIBUTION' in combined_text:
        out["Buyer"] = "HORIZON DISTRIBUTION"
    elif 'THOM FRANCE' in combined_text or 'THOM SAS' in combined_text:
        out["Buyer"] = "THOM FRANCE"
    elif 'Stroili Oro' in combined_text:
        out["Buyer"] = "Stroili Oro S.p.A."
    else:
        lines = combined_text.splitlines()
        for ln in lines[:12]:
            if ln.strip() and not re.search(r'purchase|order|invoice|telephone|phone|tel|fax|style|sku|address', ln, re.IGNORECASE):
                out["Buyer"] = ln.strip()
                break

    # Vendor extraction
    if 'INTER GOLD' in combined_text:
        vendor_match = re.search(r'INTER GOLD[^\n]{0,100}', combined_text)
        if vendor_match:
            out["Vendor"] = vendor_match.group(0).strip()

    # PO Date extraction
    mdate = re.search(r'Date of order\s*[:\-]?\s*([A-Za-z0-9\/\-\., ]{6,40})', combined_text, re.IGNORECASE)
    if mdate:
        out["PO_Date"] = normalize_date_iso(mdate.group(1).strip())
    else:
        mdate = re.search(r'Data\s*[:\-]?\s*([A-Za-z0-9\/\-\., ]{6,40})', combined_text, re.IGNORECASE)
        if mdate:
            out["PO_Date"] = normalize_date_iso(mdate.group(1).strip())
        else:
            md = re.search(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', combined_text)
            if md:
                out["PO_Date"] = normalize_date_iso(md.group(1))

    # Total amounts
    m = re.search(r'Order total excl tax[^\d]*([0-9\., ]+)', combined_text, re.IGNORECASE)
    if m:
        out["Subtotal"] = numeric_normalize(m.group(1))
    
    m = re.search(r'Total.*?([0-9\., ]+)\s*USD', combined_text, re.IGNORECASE)
    if m:
        out["Total_USD"] = numeric_normalize(m.group(1))

    return out


# ---------- Item parsing for different PDF types ----------
def parse_horizon_items(tables: List) -> List[Dict[str, Any]]:
    """Parse items from HORIZON DISTRIBUTION format (310411.pdf)"""
    items = []
    
    for table in tables:
        if not table or len(table) < 2:
            continue
            
        # Look for header row with expected columns
        header_found = False
        header_row_idx = -1
        
        for i, row in enumerate(table):
            if not row:
                continue
            row_text = ' '.join(str(cell) for cell in row if cell)
            if all(keyword in row_text for keyword in ['Provider ref', 'Product reference', 'Name']):
                header_row_idx = i
                header_found = True
                break
                
        if not header_found:
            continue
            
        # Parse data rows
        for row in table[header_row_idx + 1:]:
            if not row or len(row) < 9:
                continue
                
            # Check if row has meaningful data (has at least provider ref and quantity)
            provider_ref = str(row[0]).strip() if row[0] else ''
            quantity = str(row[5]).strip() if len(row) > 5 and row[5] else ''
            
            if not provider_ref or not quantity or not quantity.isdigit():
                continue
                
            item = {
                "Style_Code": provider_ref,
                "SKU": str(row[1]).strip() if len(row) > 1 and row[1] else '',
                "Description": str(row[2]).strip() if len(row) > 2 and row[2] else '',
                "Line_ExFactoryDate": "",
                "Quantity": numeric_normalize(quantity),
                "Weight": numeric_normalize(row[4]) if len(row) > 4 and row[4] else '',
                "Unit_Price": numeric_normalize(row[6]) if len(row) > 6 and row[6] else '',
                "Discount": numeric_normalize(row[7]) if len(row) > 7 and row[7] else '',
                "Amount": numeric_normalize(row[8]) if len(row) > 8 and row[8] else ''
            }
            items.append(item)
            
    return items


def parse_thom_france_items(combined_text: str, tables: List) -> List[Dict[str, Any]]:
    """Parse items from THOM FRANCE format (commandes_4200099157.pdf)"""
    items = []
    
    # Try table extraction first
    for table in tables:
        if not table or len(table) < 2:
            continue
            
        # Look for line items in tables
        for row in table:
            if not row or len(row) < 10:
                continue
                
            # Check if this looks like an item row (has ref and price)
            ref_fm = str(row[1]).strip() if len(row) > 1 and row[1] else ''
            price = str(row[7]).strip() if len(row) > 7 and row[7] else ''
            
            if ref_fm and price and any(c.isdigit() for c in price):
                item = {
                    "Style_Code": ref_fm,
                    "SKU": str(row[2]).strip() if len(row) > 2 and row[2] else '',
                    "Description": str(row[3]).strip() if len(row) > 3 and row[3] else '',
                    "Line_ExFactoryDate": "",
                    "Quantity": numeric_normalize(row[6]) if len(row) > 6 and row[6] else '1',  # Default to 1
                    "Weight": numeric_normalize(row[11]) if len(row) > 11 and row[11] else '',
                    "Unit_Price": numeric_normalize(price),
                    "Discount": "",
                    "Amount": numeric_normalize(price)  # Use price as amount for single item
                }
                items.append(item)
                break
    
    # Fallback to text extraction
    if not items:
        lines = combined_text.split('\n')
        for i, line in enumerate(lines):
            if 'L-RG' in line and 'USD' in line:
                # Extract the main item line
                parts = line.split()
                if len(parts) >= 8:
                    item = {
                        "Style_Code": parts[1] if len(parts) > 1 else '',
                        "SKU": parts[3] if len(parts) > 3 else '',
                        "Description": ' '.join(parts[4:7]) if len(parts) > 7 else '',
                        "Line_ExFactoryDate": "",
                        "Quantity": "1",
                        "Weight": numeric_normalize(parts[9]) if len(parts) > 9 else '',
                        "Unit_Price": numeric_normalize(parts[7]),
                        "Discount": "",
                        "Amount": numeric_normalize(parts[7])
                    }
                    items.append(item)
                    break
                    
    return items


def parse_stroili_oro_items(tables: List) -> List[Dict[str, Any]]:
    """Parse items from Stroili Oro format (PO25-0001-058565.pdf)"""
    items = []
    
    for table in tables:
        if not table or len(table) < 2:
            continue
            
        # Look for header row
        header_found = False
        header_row_idx = -1
        
        for i, row in enumerate(table):
            if not row:
                continue
            row_text = ' '.join(str(cell) for cell in row if cell)
            if 'Referenza Articolo' in row_text and 'Descrizione' in row_text:
                header_row_idx = i
                header_found = True
                break
                
        if not header_found:
            continue
            
        # Parse data rows - Stroili Oro has complex multi-line structure
        i = header_row_idx + 1
        while i < len(table):
            row = table[i]
            if not row or len(row) < 10:
                i += 1
                continue
                
            referenza = str(row[0]).strip() if row[0] else ''
            # Check if this is a product row (starts with product code)
            if referenza and ('9KT' in referenza or 'RG' in referanza or any(c.isalpha() for c in referenza)):
                
                # Stroili Oro items span multiple rows, so we need to gather data from subsequent rows
                descrizione = str(row[1]).strip() if len(row) > 1 and row[1] else ''
                quantity = str(row[2]).strip() if len(row) > 2 and row[2] else ''
                peso = str(row[3]).strip() if len(row) > 3 and row[3] else ''
                unit_price = str(row[6]).strip() if len(row) > 6 and row[6] else ''
                
                # Look for amount in next row if available
                amount = ""
                if i + 1 < len(table):
                    next_row = table[i + 1]
                    if next_row and len(next_row) > 6:
                        amount_candidate = str(next_row[6]).strip() if next_row[6] else ''
                        if amount_candidate and any(c.isdigit() for c in amount_candidate):
                            amount = amount_candidate
                
                item = {
                    "Style_Code": referenza,
                    "SKU": "",  # Stroili Oro doesn't have separate SKU in visible format
                    "Description": descrizione,
                    "Line_ExFactoryDate": str(row[9]).strip() if len(row) > 9 and row[9] else '',
                    "Quantity": numeric_normalize(quantity),
                    "Weight": numeric_normalize(peso),
                    "Unit_Price": numeric_normalize(unit_price),
                    "Discount": numeric_normalize(row[4]) if len(row) > 4 and row[4] else '',
                    "Amount": numeric_normalize(amount)
                }
                
                if item["Quantity"]:  # Only add if we have quantity
                    items.append(item)
                    i += 2  # Skip next row as it's part of the same item
                else:
                    i += 1
            else:
                i += 1
                
    return items


def parse_items_adaptive(combined_text: str, tables: List) -> List[Dict[str, Any]]:
    """Adaptive item parser that detects PDF type and uses appropriate parser"""
    items = []
    
    # Detect PDF type and use appropriate parser
    if 'HORIZON DISTRIBUTION' in combined_text and 'ORDER FORM' in combined_text:
        logging.info("Detected HORIZON DISTRIBUTION format")
        items = parse_horizon_items(tables)
    elif 'Stroili Oro' in combined_text and 'ORDINE DI ACQUISTO' in combined_text:
        logging.info("Detected Stroili Oro format")
        items = parse_stroili_oro_items(tables)
    elif 'THOM FRANCE' in combined_text or 'Orders n°' in combined_text:
        logging.info("Detected THOM FRANCE format")
        items = parse_thom_france_items(combined_text, tables)
    else:
        logging.info("Using generic table parser as fallback")
        # Generic table parser as fallback
        for table in tables:
            if table and len(table) > 1:
                for row in table:
                    if row and any(cell for cell in row if cell and str(cell).strip()):
                        # Simple heuristic: row with numbers in certain positions might be items
                        if len(row) >= 5 and any(numeric_normalize(row[i]) for i in [2, 3, 4] if i < len(row)):
                            item = {
                                "Style_Code": str(row[0]).strip() if row[0] else '',
                                "SKU": str(row[1]).strip() if len(row) > 1 and row[1] else '',
                                "Description": str(row[2]).strip() if len(row) > 2 and row[2] else '',
                                "Line_ExFactoryDate": "",
                                "Quantity": numeric_normalize(row[3]) if len(row) > 3 and row[3] else '',
                                "Weight": numeric_normalize(row[4]) if len(row) > 4 and row[4] else '',
                                "Unit_Price": numeric_normalize(row[5]) if len(row) > 5 and row[5] else '',
                                "Discount": numeric_normalize(row[6]) if len(row) > 6 and row[6] else '',
                                "Amount": numeric_normalize(row[7]) if len(row) > 7 and row[7] else ''
                            }
                            if item["Style_Code"] or item["Quantity"]:
                                items.append(item)
    
    return items


def compute_amount_from_row(it: Dict[str, Any]) -> str:
    q = to_float_safe(it.get("Quantity", ""))
    u = to_float_safe(it.get("Unit_Price", ""))
    disc_raw = it.get("Discount", "")
    
    if isinstance(disc_raw, str) and '%' in disc_raw:
        pct = to_float_safe(disc_raw)
        d_amt = (q * u * pct) if not (math.isnan(q) or math.isnan(u)) else 0.0
    else:
        d_amt = to_float_safe(disc_raw)
        if math.isnan(d_amt):
            d_amt = 0.0
            
    if math.isnan(q) or math.isnan(u):
        amt_token = numeric_normalize(it.get("Amount", ""))
        return amt_token if amt_token else ""
    else:
        val = q * u - d_amt
        try:
            return "{:.2f}".format(round(val + 1e-9, 2))
        except:
            return it.get("Amount", "")


# ---------- Main extraction function (required name) ----------
def extract_thom_po(pdf_path: str, output_excel_path: str = None, debug: bool = False) -> str:
    """
    Extract THOM PO from single PDF and write Excel.
    Returns output Excel path.
    """
    pdf_path = str(pdf_path)
    pdf_name = Path(pdf_path).stem
    if not output_excel_path:
        output_excel_path = fr"D:\RPA\Purchase_Orders_Extracted_{pdf_name}.xlsx"

    logging.info("Reading PDF text and tables...")
    combined_text, pages_text, tables = read_pdf_text(pdf_path)

    if debug:
        dbg_dir = Path(output_excel_path).with_suffix("")
        dbg_dir = Path(dbg_dir.parent) / f"{pdf_name}_debug"
        dbg_dir.mkdir(parents=True, exist_ok=True)
        (dbg_dir / "combined_text.txt").write_text(combined_text, encoding="utf-8")
        logging.info("Wrote debug combined_text.txt")

    logging.info("Parsing headers...")
    headers = parse_headers(combined_text, pages_text, tables)
    logging.info(f"Parsed headers: PO_No={headers.get('PO_No')}")

    logging.info("Parsing items using adaptive parser...")
    items = parse_items_adaptive(combined_text, tables)
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