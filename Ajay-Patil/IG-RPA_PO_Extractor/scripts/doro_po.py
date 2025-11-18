#!/usr/bin/env python3
"""
doro_po_extractor_v2.py

Strict & robust Dorotheum order extractor — improved supplier item extraction
(now handles forms like "P 22388A 000", "P.22388A.000", "P-22388A-000", "P22388A000").

Usage:
    python doro_po_extractor_v2.py --pdf "path/to/doro oRDER.pdf" --out "path/to/out_prefix"

Output:
  - <out_prefix>_doro_extracted.xlsx  (or <pdf_stem>_doro_extracted.xlsx if --out omitted)

Dependencies:
    pip install pdfplumber pandas python-dateutil openpyxl
"""
import argparse
import logging
import re
from pathlib import Path
from typing import Dict, List, Optional, Any

import pdfplumber
import pandas as pd

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

OUTPUT_COLUMNS = [
    "PO_No", "Order_Date", "Supplier_Number", "Name", "Department", "Branch",
    "Precious_Metal", "Precious_Metal_Price", "Price_Fixing", "Currency",
    "Line_No", "Supplier_Item_No", "Doro_Item_No", "Unit", "Quantity", "Weight_g",
    "Unit_Price", "Total_Price_per_pc", "Total_Line_Value", "Description", "Notes"
]


def read_pdf_text(pdf_path: str) -> str:
    pages = []
    with pdfplumber.open(pdf_path) as pdf:
        for p in pdf.pages:
            txt = p.extract_text() or ""
            # append table rows if pdfplumber finds them (fallback)
            try:
                for t in p.extract_tables() or []:
                    for row in t:
                        if row and any(c for c in row if c):
                            txt += "\n" + " | ".join([c if c else "" for c in row])
            except Exception:
                pass
            pages.append(txt)
    return "\n\n".join(pages)


def find_purchase_block(full_text: str) -> Optional[str]:
    """
    Return substring from first 'Purchase order number' occurrence
    to the next 'Grand Total' (inclusive start, exclusive end).
    """
    start = re.search(r'Purchase\s*order\s*number', full_text, re.IGNORECASE)
    if not start:
        # fallback: find 'Purchase order' or 'Order number' or 'Order No'
        start = re.search(r'(?:Purchase\s*order|Order\s*No(?:\.|:)?|Order\s*number)', full_text, re.IGNORECASE)
    if not start:
        return None
    # search for 'Grand Total' after start
    post = full_text[start.start():]
    end = re.search(r'Grand\s*Total', post, re.IGNORECASE)
    if end:
        return post[:end.start()]
    return post


def first_group(patterns: List[str], txt: str, flags=0) -> Optional[re.Match]:
    """Return first matching re.Match from a list of patterns, else None."""
    for p in patterns:
        m = re.search(p, txt, flags)
        if m:
            return m
    return None


def normalize_supplier_item(raw: str) -> str:
    """
    Normalize supplier-item token: replace spaces, dots and multiple separators with single dash.
    Examples:
      "P 22388A 000" -> "P-22388A-000"
      "P.22388A.000" -> "P-22388A-000"
      "P-22388A-000" -> "P-22388A-000"
      "P22388A000" -> "P22388A000" (if no separators)
    """
    if not raw:
        return ""
    s = raw.strip()
    # remove weird unicode hyphen variants
    s = re.sub(r'[\u2011\u2012\u2013\u2014]', '-', s)
    # replace dots and underscores with spaces to normalize
    s = s.replace('.', ' ').replace('_', ' ')
    # collapse multiple spaces
    s = re.sub(r'\s+', ' ', s).strip()
    # If there are spaces between alpha and digits, join them with dashes
    # We'll replace sequences of space or hyphen with single dash
    s = re.sub(r'[\s\-]+', '-', s)
    # remove any leading/trailing dashes
    s = s.strip('-')
    return s


def extract_headers(block: str) -> Dict[str, str]:
    hdr = {
        "PO_No": "",
        "Order_Date": "",
        "Supplier_Number": "",
        "Name": "",
        "Department": "",
        "Branch": "",
        "Precious_Metal": "",
        "Precious_Metal_Price": "",
        "Price_Fixing": "",
        "Currency": ""
    }

    # PO number (many variants)
    po_patterns = [
        r'Purchase\s*order\s*number[:\s]*([A-Z0-9\-\u2011\u2012\u2013\u2014]+)',
        r'Purchase\s*order[:\s]*([A-Z0-9\-\u2011]+)',
        r'Order\s*No(?:\.|:)?\s*([A-Z0-9\-]+)'
    ]
    po_m = first_group(po_patterns, block, re.IGNORECASE)
    if po_m:
        hdr["PO_No"] = po_m.group(1).strip()

    # Supplier number
    sup_patterns = [r'supplier\s*number[:\.\s]*([0-9]{2,10})', r'supplier[:\s]*#?([0-9]{2,10})']
    s_m = first_group(sup_patterns, block, re.IGNORECASE)
    if s_m:
        hdr["Supplier_Number"] = s_m.group(1).strip()

    # Name
    nm = re.search(r'Name\s*\.{2,}\s*[:\s]*([^\n\r]+)', block)
    if nm:
        hdr["Name"] = nm.group(1).strip()
    else:
        nm2 = re.search(r'Name\s*[^\S\r\n]{0,}\.{2,}\s*[:\s]*([^\n\r]+)', block)
        if nm2:
            hdr["Name"] = nm2.group(1).strip()

    # Order Date (dd.mm.yyyy or similar)
    date_m = first_group([r'\bDate\s*[:\.\s]*([0-3]?\d[./-]\d{1,2}[./-]\d{2,4})',
                          r'\b(\d{2}\.\d{2}\.\d{4})\b'], block, re.IGNORECASE)
    if date_m:
        hdr["Order_Date"] = date_m.group(1).strip()

    # Department / Branch
    dep = re.search(r'Department\s*\.{2,}\s*[:\s]*([^\n\r]+)', block, re.IGNORECASE)
    if dep:
        hdr["Department"] = dep.group(1).strip()
    br = re.search(r'Branch\s*\.{2,}\s*[:\s]*([0-9A-Za-z\-]+)', block, re.IGNORECASE)
    if br:
        hdr["Branch"] = br.group(1).strip()

    # precious metal and price
    pm = re.search(r'precious\s*metal\s*\.{2,}\s*[:\s]*([^\n\r]+)', block, re.IGNORECASE)
    if pm:
        hdr["Precious_Metal"] = pm.group(1).strip()
    pmp = re.search(r'precious\s*metal\s+price\s*[:\s]*([0-9\.\,]+)', block, re.IGNORECASE)
    if pmp:
        hdr["Precious_Metal_Price"] = pmp.group(1).strip()

    # price fixing and currency
    pf = re.search(r'price\s*fixing\s*[:\s]*([A-Za-z]+)', block, re.IGNORECASE)
    if pf:
        hdr["Price_Fixing"] = pf.group(1).strip()
    cur = first_group([r'Currency\s*[:\s]*([A-Z]{3})', r'\b(USD|EUR|€)\b'], block, re.IGNORECASE)
    if cur:
        hdr["Currency"] = cur.group(1).strip()

    return hdr


def parse_order_row(block: str) -> Dict[str, Any]:
    """
    Parse the single order row inside the important block.
    Improved supplier-item extraction to handle spaced forms.
    """
    row = {
        "Supplier_Item_No": "",
        "Doro_Item_No": "",
        "Unit": "",
        "Quantity": "",
        "Weight_g": "",
        "Unit_Price": "",
        "Total_Price_per_pc": "",
        "Total_Line_Value": "",
        "Description": ""
    }

    # Primary attempt: explicit 'suppl. item nr.' followed by token
    sup_m = first_group([
        r'suppl(?:\.|ier)?\s*item\s*(?:nr|no|number)\.?\s*[:\s]*([A-Z0-9\-\.\s\u2011\u2012\u2013\u2014]{2,40})(?=\s+Doro|\s+Doro\.|\s+unit|\s+unit\s|$)',
        r'supplier\s*item\s*(?:nr|no)\.?\s*[:\s]*([A-Z0-9\-\.\s\u2011\u2012\u2013\u2014]{2,40})(?=\s+Doro|\s+unit|\s+unit\s|$)'
    ], block, re.IGNORECASE)

    supplier_raw = ""
    if sup_m:
        supplier_raw = sup_m.group(1).strip()
    else:
        # fallback: capture tokens after 'suppl. item' till next anchor (Doro / unit / numeric tokens)
        m2 = re.search(r'suppl(?:\.|ier)?\s*item[^\n\r]{0,60}', block, re.IGNORECASE)
        if m2:
            tail = m2.group(0)
            # try to extract following token sequence from the same line
            line = tail
            # try reading the rest of the line from original block
            for ln in block.splitlines():
                if tail.strip() in ln:
                    line = ln
                    break
            # remove leading "suppl...item..." and capture remainder before 'Doro' or 'unit'
            line_after = re.sub(r'(?i)^.*?suppl(?:\.|ier)?\s*item\s*(?:nr|no|number)?\.?\s*[:\s]*', '', line)
            # stop at "Doro" or "Doro." if present
            line_after = re.split(r'\bDoro\b|\bDoro\.\b|\bunit\b|\bunit\s', line_after, flags=re.IGNORECASE)[0]
            supplier_raw = line_after.strip()

    # Normalize supplier token (turn spaces/dots into single dash)
    if supplier_raw:
        supplier_norm = normalize_supplier_item(supplier_raw)
        row["Supplier_Item_No"] = supplier_norm

    # Doro item extraction
    doro_m = first_group([
        r'Doro\.\s*item\s*(?:nr|no)\.?\s*[:\s]*([0-9\-]+)',
        r'Doro\.\s*item\s*[:\s]*([0-9\-]+)',
        r'\bDoro\.\s*([0-9\-]+)'
    ], block, re.IGNORECASE)
    if doro_m:
        row["Doro_Item_No"] = doro_m.group(1).strip()
    else:
        # fallback: any standalone 5-9 digit sequence likely Doro item
        df = re.search(r'\b(\d{5,9})\b', block)
        if df:
            row["Doro_Item_No"] = df.group(1).strip()

    # Find numeric-heavy line (has multiple numeric tokens and money tokens)
    numeric_line = None
    for ln in block.splitlines():
        ln = ln.strip()
        if len(re.findall(r'[\d\.,]+', ln)) >= 4 and re.search(r'\d+[.,]\d{2}', ln):
            numeric_line = ln
            break

    if numeric_line:
        money_tokens = re.findall(r'\d{1,3}(?:\.\d{3})*,\d{2}|\d+[.,]\d{2}', numeric_line)
        if money_tokens:
            row["Total_Line_Value"] = money_tokens[-1]
            if len(money_tokens) >= 2:
                row["Total_Price_per_pc"] = money_tokens[-2]
            if len(money_tokens) >= 3:
                row["Unit_Price"] = money_tokens[-3]
        # quantity detection
        qty_m = first_group([r'(\d{1,4}[,\.]\d+)', r'\b(\d{1,4})\b'], numeric_line)
        if qty_m:
            row["Quantity"] = qty_m.group(1).strip()
        # weight detection
        w_m = re.search(r'([\d\.,]+)\s*(?:gr|g)\b', numeric_line, re.IGNORECASE)
        if w_m:
            row["Weight_g"] = w_m.group(1).strip()

    # Description: line after numeric_line or the first alphabetic descriptive line
    if numeric_line:
        lines = [l.strip() for l in block.splitlines() if l.strip()]
        try:
            idx = lines.index(numeric_line)
            if idx + 1 < len(lines):
                row["Description"] = lines[idx + 1].strip()
        except ValueError:
            pass
    if not row["Description"]:
        for l in block.splitlines():
            if re.search(r'[A-Za-z]{3,}', l) and not re.search(r'Purchase order|Grand Total|precious metal|Currency|Please note', l, re.IGNORECASE):
                row["Description"] = l.strip()
                break

    # strip and cleanup
    for k in row:
        if isinstance(row[k], str):
            row[k] = row[k].strip().rstrip(',;')

    return row


def write_xlsx(out_prefix: Path, headers: Dict[str, str], parsed_row: Dict[str, Any]):
    stem = out_prefix.stem
    out_xlsx = fr"D:\RPA\Purchase_Orders_Extracted_{stem}.xlsx"

    rec = {
        "PO_No": headers.get("PO_No", ""),
        "Order_Date": headers.get("Order_Date", ""),
        "Supplier_Number": headers.get("Supplier_Number", ""),
        "Name": headers.get("Name", ""),
        "Department": headers.get("Department", ""),
        "Branch": headers.get("Branch", ""),
        "Precious_Metal": headers.get("Precious_Metal", ""),
        "Precious_Metal_Price": headers.get("Precious_Metal_Price", ""),
        "Price_Fixing": headers.get("Price_Fixing", ""),
        "Currency": headers.get("Currency", ""),
        "Line_No": "0001",
        "Supplier_Item_No": parsed_row.get("Supplier_Item_No", ""),
        "Doro_Item_No": parsed_row.get("Doro_Item_No", ""),
        "Unit": parsed_row.get("Unit", ""),
        "Quantity": parsed_row.get("Quantity", ""),
        "Weight_g": parsed_row.get("Weight_g", ""),
        "Unit_Price": parsed_row.get("Unit_Price", ""),
        "Total_Price_per_pc": parsed_row.get("Total_Price_per_pc", ""),
        "Total_Line_Value": parsed_row.get("Total_Line_Value", ""),
        "Description": parsed_row.get("Description", ""),
        "Notes": ""
    }
    df = pd.DataFrame([rec], columns=OUTPUT_COLUMNS)
    df.to_excel(out_xlsx, index=False)
    logging.info("Wrote Excel: %s (rows: %d)", str(out_xlsx), len(df))


def extract_cli(pdf_path: str, out_path: Optional[str] = None):
    pdfp = Path(pdf_path)
    if not pdfp.exists():
        raise FileNotFoundError(f"PDF not found: {pdf_path}")
    full_text = read_pdf_text(str(pdfp))
    block = find_purchase_block(full_text)
    if not block:
        raise RuntimeError("Couldn't find purchase-order block between 'Purchase order number' and 'Grand Total'.")
    headers = extract_headers(block)
    parsed_row = parse_order_row(block)
    # if out path provided, strip extension to create prefix
    if out_path:
        out_prefix = Path(out_path)
        if out_prefix.suffix:
            out_prefix = out_prefix.with_suffix('')
    else:
        out_prefix = pdfp.with_name(pdfp.stem)
    write_xlsx(out_prefix, headers, parsed_row)
    return out_prefix


def main():
    parser = argparse.ArgumentParser(description="Dorotheum order extractor v2 (strict, improved supplier item)")
    parser.add_argument("--pdf", required=True, help="Path to PDF file")
    parser.add_argument("--out", required=False, help="Output prefix (optional)")
    args = parser.parse_args()

    try:
        pref = extract_cli(args.pdf, args.out)
        print("Extraction finished. Excel written using prefix:", pref)
    except Exception as e:
        logging.exception("Extraction failed: %s", e)
        raise


if __name__ == "__main__":
    main()
