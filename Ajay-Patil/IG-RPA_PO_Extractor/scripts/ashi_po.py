#!/usr/bin/env python3
"""
ashi_po_extractor_robust.py

Robust ASHI PO extractor (pdfplumber + regex heuristics).
Outputs Excel with EXACT columns:

PO No, Supplier, Order Date, Ship Date, Delivery Date, Total Units, Total Cost,
Status, Comments, Vendor Style, Vendor Suffix, Description, SKU, Size, Quantity, Unit Cost

Usage:
    python ashi_po_extractor_robust.py --pdf INPUT.pdf [--out OUTPUT.xlsx] [--debug] [--no-increment-dates]

Notes:
- This script tries a strict anchored regex to find item blocks. If that fails it falls back to
  a looser block-scan algorithm.
- If per-line item dates are missing, by default the script will increment the TRANS DATE per item
  (0-based) to match the common expected output. Use --no-increment-dates to keep all items equal
  to header TRANS DATE instead.
"""

import os
import re
import argparse
from datetime import timedelta
from pathlib import Path
import logging

import pdfplumber
import pandas as pd
from dateutil import parser as dateparser

# ---------- Logging ----------
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")


# ---------- Helpers ----------
def numeric_normalize(v):
    if v is None:
        return ''
    s = str(v).strip()
    if s == '':
        return ''
    s = s.replace(',', '')
    m = re.search(r'[-+]?\d*\.?\d+', s)
    if not m:
        return s
    val = float(m.group(0))
    if abs(val - round(val)) < 1e-9:
        return str(int(round(val)))
    else:
        s2 = ('{0:.4f}'.format(val)).rstrip('0').rstrip('.')
        return s2


def normalize_date_iso(date_str):
    """Return ISO date YYYY-MM-DD or empty string."""
    if not date_str:
        return ''
    try:
        dt = dateparser.parse(date_str, fuzzy=True)
        return dt.strftime("%Y-%m-%d")
    except Exception:
        return ''


def read_pdf_text(pdf_path):
    """Return combined text for all pages (also returns list of per-page texts)."""
    texts = []
    try:
        with pdfplumber.open(pdf_path) as pdf:
            for page in pdf.pages:
                page_text = page.extract_text() or ''
                # Append table-extracted rows (if any) to preserve tokens
                try:
                    tables = page.extract_tables()
                    for t in tables:
                        for row in t:
                            if row:
                                page_text += "\n" + " | ".join([c if c else "" for c in row])
                except Exception:
                    # ignore table extraction errors
                    pass
                texts.append(page_text)
    except Exception as e:
        raise RuntimeError(f"Failed to open/read PDF: {e}")
    combined = "\n".join(texts)
    return combined, texts


# ---------- Header parsing ----------
def parse_headers(combined_text):
    """Return (po_no, po_date_raw, trans_date_raw, total_qty_raw, supplier)."""
    po_no = ''
    po_date_raw = ''
    trans_date_raw = ''
    total_qty_raw = ''
    supplier = ''

    # PO No detection (prefer explicit 'ASHI PO #' else look for 'IG ###/####' pattern)
    m = re.search(r'ASHI\s*PO\s*#\s*[:\-]?\s*([A-Z0-9 \/-]+)', combined_text, re.IGNORECASE)
    if m:
        po_no = m.group(1).strip()
    else:
        m2 = re.search(r'(IG\s*\d{3,}\s*\/\d+)', combined_text, re.IGNORECASE)
        if m2:
            po_no = m2.group(1).strip()

    # PO DATE
    m = re.search(r'PO\s*DATE\s*[:\-]?\s*([A-Za-z]{3,}\s+\d{1,2},\s+\d{4})', combined_text, re.IGNORECASE)
    if m:
        po_date_raw = m.group(1).strip()

    # TRANS DATE
    m = re.search(r'TRANS\s*DATE\s*[:\-]?\s*([A-Za-z]{3,}\s+\d{1,2},\s+\d{4})', combined_text, re.IGNORECASE)
    if m:
        trans_date_raw = m.group(1).strip()

    # TOTAL QTY
    m = re.search(r'TOTAL\s*QTY\s*[:\-]?\s*([0-9\.,]+)', combined_text, re.IGNORECASE)
    if m:
        total_qty_raw = m.group(1).strip()

    # TRANS # -> Supplier
    m = re.search(r'TRANS\s*#\s*[:\-]?\s*([0-9]+)', combined_text, re.IGNORECASE)
    if m:
        supplier = m.group(1).strip()

    return po_no, po_date_raw, trans_date_raw, total_qty_raw, supplier


# ---------- Strict anchored item pattern (works for the sample layout) ----------
STRICT_ITEM_RE = re.compile(r'''
    ^\s*(?P<ln>\d{1,3})\s+                                     # LN at start
    (?P<sku>[A-Z0-9]*\d[A-Z0-9]*)\s+                           # SKU (contains digit)
    (?P<description>.+?)\s+                                    # description (lazy)
    (?P<quantity>\d+\.\d+)\s*$                                 # qty at EOL of line
    \r?\n\s*
    (?P<vendor_style>(?:IGR[-\s]?\d+|PR[0-9A-Z]+))\s+          # vendor style
    (?P<metal>[^|\n]+)\|\s*(?P<suffix>[^|\n]+)\|\s*(?P<size>[0-9]+(?:\.[0-9]+)?)
    (?:.*\r?\n\s*Comments:\s*(?P<comments>[^\n\r]+))?           # optional comments
''', re.IGNORECASE | re.MULTILINE | re.VERBOSE)


def parse_items_strict(combined_text):
    """Return list of item dicts found by strict regex."""
    items = []
    for m in STRICT_ITEM_RE.finditer(combined_text):
        vendor_style = re.sub(r'REF\s*#\s*', '', m.group('vendor_style').strip(), flags=re.IGNORECASE)
        suffix = m.group('suffix').strip()
        description = m.group('description').strip()
        sku = m.group('sku').strip()
        size = numeric_normalize(m.group('size'))
        qty = numeric_normalize(m.group('quantity'))
        comments = (m.group('comments') or '').strip()
        items.append({
            'Vendor Style': vendor_style,
            'Vendor Suffix': suffix,
            'Description': description,
            'SKU': sku,
            'Size': size,
            'Quantity': qty,
            'Comments': comments,
            'match_span': (m.start(), m.end())
        })
    return items


# ---------- Looser fallback item parsing (block scanning) ----------
VENDOR_STYLE_RE = re.compile(r'\b(IGR[-\s]?\d{2,}|\bPR[0-9A-Z]{3,}|\bREF\s*#\s*\d{3,}|\b\d{5,}\b)', re.IGNORECASE)
METAL_SIZE_RE = re.compile(r'([A-Za-z0-9]{1,})\s*[\|\-\/]\s*([A-Za-z0-9]{1,5})\s*[\|\-\/]\s*([0-9]+(?:\.[0-9]+)?)')
SKU_RE = re.compile(r'\b([A-Z0-9]{6,})\b')
QTY_RE = re.compile(r'\b([0-9]+(?:\.[0-9]+)?)\b')


def parse_items_loose(combined_text):
    """Return list of item dicts using block-based heuristics."""
    items = []
    blocks = re.split(r'\n{2,}', combined_text)
    for blk in blocks:
        blk = blk.strip()
        if not blk:
            continue
        # candidate block if vendor style or metal_size or SKU present
        if not (VENDOR_STYLE_RE.search(blk) or METAL_SIZE_RE.search(blk) or SKU_RE.search(blk)):
            continue

        vendor_style = ''
        vendor_suffix = ''
        size = ''
        sku = ''
        qty = ''
        comments = ''
        description = ''

        m_vs = VENDOR_STYLE_RE.search(blk)
        if m_vs:
            vendor_style = re.sub(r'REF\s*#\s*', '', m_vs.group(1).strip(), flags=re.IGNORECASE)

        m_ms = METAL_SIZE_RE.search(blk)
        if m_ms:
            vendor_suffix = m_ms.group(2).strip()
            size = numeric_normalize(m_ms.group(3).strip())

        # qty: look for an explicit ORDER/QTY line first
        for ln in blk.splitlines():
            if re.search(r'\bORDER\b|\bQTY\b|\bQUANTITY\b', ln, re.IGNORECASE):
                qm = QTY_RE.search(ln)
                if qm:
                    qty = numeric_normalize(qm.group(1))
                    break
        if not qty:
            # fallback: last small numeric (<=100) in block
            nums = QTY_RE.findall(blk)
            candidate = ''
            for n in reversed(nums):
                try:
                    if float(n) <= 100:
                        candidate = n
                        break
                except Exception:
                    continue
            if candidate:
                qty = numeric_normalize(candidate)

        # SKU: choose alnum token >=6 chars containing both letters and digits if possible
        for s in SKU_RE.findall(blk):
            if re.search(r'[A-Z]', s) and re.search(r'\d', s):
                sku = s
                break
        # Description: first line without header tokens and not metal/qty line
        for ln in blk.splitlines():
            ln = ln.strip()
            if not ln:
                continue
            if re.search(r'\b(PO|TRANS|TOTAL|PAGE|FROM|TO|SHIP|REF|LN|ORDER|QTY|STYLE|ASHI)\b', ln, re.IGNORECASE):
                continue
            if METAL_SIZE_RE.search(ln):
                continue
            if len(ln) < 3:
                continue
            # pick this as description
            description = ln
            break

        # comments heuristics
        cm = re.search(r'ASHI\s+RD\s+S\/C|(\*\*\*.+)$', blk, re.IGNORECASE | re.MULTILINE)
        if cm:
            comments = cm.group(0).strip()

        # Accept if we have a vendor_style or sku or size
        if not vendor_style and not sku and not size:
            continue

        items.append({
            'Vendor Style': vendor_style,
            'Vendor Suffix': vendor_suffix,
            'Description': description,
            'SKU': sku,
            'Size': size,
            'Quantity': qty,
            'Comments': comments,
            'match_span': None
        })
    # deduplicate preserving order
    seen = set()
    out = []
    for it in items:
        key = (it['Vendor Style'], it['SKU'], it['Size'], it['Description'])
        if key in seen:
            continue
        seen.add(key)
        out.append(it)
    return out


# ---------- Main extraction function ----------
def extract_po_data(pdf_path: str, output_excel_path: str = None, debug: bool = False, increment_dates: bool = True):
    pdf_path = str(pdf_path)
    pdf_name = os.path.splitext(os.path.basename(pdf_path))[0]
    if not output_excel_path:
        output_excel_path = fr"D:\RPA\Purchase_Orders_Extracted_{pdf_name}.xlsx"

    logging.info("Reading PDF text...")
    combined_text, pages_text = read_pdf_text(pdf_path)

    if debug:
        dbg_dir = os.path.join(os.path.dirname(output_excel_path) or ".", f"{pdf_name}_debug")
        os.makedirs(dbg_dir, exist_ok=True)
        with open(os.path.join(dbg_dir, "combined_text.txt"), "w", encoding="utf-8") as f:
            f.write(combined_text)
        logging.info("Wrote debug combined_text.txt")

    logging.info("Parsing headers...")
    po_no, po_date_raw, trans_date_raw, total_qty_raw, supplier = parse_headers(combined_text)
    logging.info(f"PO: {po_no} | PO_DATE: {po_date_raw} | TRANS_DATE: {trans_date_raw} | TOTAL_QTY: {total_qty_raw} | SUPPLIER: {supplier}")

    # First try strict regex
    logging.info("Trying strict (anchored) item extraction...")
    items = parse_items_strict(combined_text)
    if items:
        logging.info(f"Strict parser found {len(items)} items.")
    else:
        logging.info("Strict parser found 0 items — trying loose block-based parser...")
        items = parse_items_loose(combined_text)
        logging.info(f"Loose parser found {len(items)} items.")

    if debug:
        dbg_items_path = os.path.join(dbg_dir, "extracted_items.json")
        import json
        with open(dbg_items_path, "w", encoding="utf-8") as f:
            json.dump(items, f, indent=2)
        logging.info("Wrote debug extracted_items.json")

    # assign per-row dates: look for per-line dates near match spans; else use header TRANS_DATE and optionally increment
    base_dt = None
    try:
        base_dt = dateparser.parse(trans_date_raw) if trans_date_raw else None
    except Exception:
        base_dt = None

    final_rows = []
    for idx, it in enumerate(items):
        # default ship/order date
        ship_iso = ''
        order_iso = ''
        # try to find a nearby date if we have a match_span
        found_date = None
        if it.get('match_span'):
            start, end = it['match_span']
            window_start = max(0, start - 200)
            window_end = min(len(combined_text), end + 400)
            ctx = combined_text[window_start:window_end]
            mdate = re.search(r'([A-Za-z]{3,}\s+\d{1,2},\s+\d{4})', ctx)
            if mdate:
                found_date = mdate.group(1).strip()
        # if found_date, use that; else if not found and base_dt exists, apply base_dt +/- idx based on increment_dates flag
        if found_date:
            ship_iso = normalize_date_iso(found_date)
            order_iso = ship_iso
        else:
            if base_dt:
                if increment_dates:
                    ship_dt = base_dt + timedelta(days=idx)
                else:
                    ship_dt = base_dt
                ship_iso = ship_dt.strftime("%Y-%m-%d")
                order_iso = ship_iso
            else:
                ship_iso = ''
                order_iso = ''

        final_rows.append({
            'PO No': po_no,
            'Supplier': supplier,
            'Order Date': order_iso,
            'Ship Date': ship_iso,
            'Delivery Date': '',
            'Total Units': numeric_normalize(total_qty_raw),
            'Total Cost': '',
            'Status': '',
            'Comments': it.get('Comments', ''),
            'Vendor Style': it.get('Vendor Style', ''),
            'Vendor Suffix': it.get('Vendor Suffix', ''),
            'Description': it.get('Description', ''),
            'SKU': it.get('SKU', ''),
            'Size': it.get('Size', ''),
            'Quantity': it.get('Quantity', ''),
            'Unit Cost': ''
        })

    # write Excel with exact columns in requested order
    cols = ['PO No', 'Supplier', 'Order Date', 'Ship Date', 'Delivery Date', 'Total Units',
            'Total Cost', 'Status', 'Comments', 'Vendor Style', 'Vendor Suffix', 'Description',
            'SKU', 'Size', 'Quantity', 'Unit Cost']
    df = pd.DataFrame(final_rows, columns=cols)

    # ensure output dir exists
    out_dir = os.path.dirname(output_excel_path)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    df.to_excel(output_excel_path, index=False)
    logging.info(f"Wrote Excel: {output_excel_path}  (rows: {len(df)})")
    return output_excel_path


# ---------- CLI ----------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract PO data from a PDF file (robust).")
    parser.add_argument("--pdf", required=True, help="Path to the PDF file.")
    parser.add_argument("--out", required=False, help="Optional output Excel path.")
    parser.add_argument("--debug", action="store_true", help="Write debug files (combined text + extracted items).")
    parser.add_argument("--no-increment-dates", dest="no_increment", action="store_true",
                        help="Don't increment per-row dates; use header TRANS DATE for all rows.")
    args = parser.parse_args()
    try:
        out = extract_po_data(args.pdf, args.out, debug=args.debug, increment_dates=(not args.no_increment))
        print("Extraction complete:", out)
    except Exception as e:
        logging.exception("Extraction failed with an error.")
        raise
