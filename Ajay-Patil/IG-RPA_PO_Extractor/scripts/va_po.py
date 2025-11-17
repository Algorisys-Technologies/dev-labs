#!/usr/bin/env python3
"""
va_po_extractor_structured.py

VA PO extractor following the referenced structure (CLI, logging, strict + loose parsing).
Outputs an Excel with consistent columns suitable for downstream use.

Usage:
    python va_po_extractor_structured.py --pdf INPUT.pdf [--out OUTPUT.xlsx] [--debug] [--no-increment-dates]
"""
import os
import re
import argparse
import logging
from datetime import timedelta
from pathlib import Path
from typing import List, Dict, Tuple

import pdfplumber
import pandas as pd
from dateutil import parser as dateparser

# ---------- Logging ----------
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")


# ---------- Output schema (standard) ----------
OUTPUT_COLUMNS = [
    "PO_No", "Order_Date", "Request_Date", "Prepared_By", "Vendor",
    "Shipping_Address", "Ordering_Address", "Confirmed_To", "Pay_Term",
    "FOB", "Ship_Via", "PO_Type", "Buyer", "Short_Remarks",
    "Line_No", "Order_Qty", "Rcvd_Qty", "Item_No", "Style_No", "Model_No",
    "Metal_Type", "Metal_Color", "Remarks", "SO_No", "Total_Quantity", "Notes"
]


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


def normalize_date_iso(date_str: str) -> str:
    """Return ISO date YYYY-MM-DD or empty string."""
    if not date_str:
        return ''
    try:
        dt = dateparser.parse(date_str, fuzzy=True)
        return dt.strftime("%Y-%m-%d")
    except Exception:
        return ''


def read_pdf_text(pdf_path: str) -> Tuple[str, List[str]]:
    """
    Return combined text for all pages and list of each page's text.
    Also append simple pipe-joined table rows discovered by pdfplumber to preserve layout tokens.
    """
    texts = []
    try:
        with pdfplumber.open(pdf_path) as pdf:
            for page in pdf.pages:
                page_text = page.extract_text() or ''
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
    combined = "\n\n".join(texts)
    return combined, texts


# ---------- Header parsing ----------
def parse_headers(combined_text: str) -> Dict[str, str]:
    """Extract likely header fields from the combined PDF text."""
    out = {k: "" for k in ["PO_No", "Order_Date", "Request_Date", "Prepared_By", "Vendor",
                           "Shipping_Address", "Ordering_Address", "Confirmed_To", "Pay_Term",
                           "FOB", "Ship_Via", "PO_Type", "Buyer", "Short_Remarks", "Total_Quantity", "Notes"]}
    # PO No (VA-10337 or VA 10337)
    m = re.search(r'\b(VA[-\s]*\d{1,})\b', combined_text, re.IGNORECASE)
    if m:
        out["PO_No"] = m.group(1).strip()

    # Order Date / Request Date / Prepared By
    m = re.search(r'Order Date[:\s]*([A-Za-z0-9,\s\/\.-]{6,30})', combined_text, re.IGNORECASE)
    if m:
        out["Order_Date"] = normalize_date_iso(m.group(1).strip())
    m = re.search(r'Request Date[:\s]*([A-Za-z0-9,\s\/\.-]{6,30})', combined_text, re.IGNORECASE)
    if m:
        out["Request_Date"] = normalize_date_iso(m.group(1).strip())
    m = re.search(r'Prepared By[:\s]*([A-Za-z .]+)', combined_text, re.IGNORECASE)
    if m:
        out["Prepared_By"] = m.group(1).strip()

    # Shipping / Ordering Address: capture small blocks if labeled
    m = re.search(r'Shipping Address[:\s]*([\s\S]*?)Ordering Address[:\s]*', combined_text, re.IGNORECASE)
    if m:
        addr = re.sub(r'\s{2,}', ' ', m.group(1)).replace('\n', ', ').strip(' ,')
        out["Shipping_Address"] = addr
    else:
        m2 = re.search(r'Shipping Address[:\s]*([\s\S]*?)\n\n', combined_text, re.IGNORECASE)
        if m2:
            out["Shipping_Address"] = re.sub(r'\s{2,}', ' ', m2.group(1)).replace('\n', ', ').strip(' ,')

    m = re.search(r'Ordering Address[:\s]*([\s\S]*?)(?:Confirmed To|Pay Term|FOB|Ship Via|PO Type|Line No\.|$)', combined_text, re.IGNORECASE)
    if m:
        out["Ordering_Address"] = re.sub(r'\s{2,}', ' ', m.group(1)).replace('\n', ', ').strip(' ,')

    # Short Remarks (if present near top)
    m = re.search(r'Short Remarks[:\s]*([^\n]{1,200})', combined_text, re.IGNORECASE)
    if m:
        out["Short_Remarks"] = m.group(1).strip()

    # Total Quantity
    m = re.search(r'([\d\.,]+)\s*Total Quantity', combined_text, re.IGNORECASE)
    if m:
        out["Total_Quantity"] = numeric_normalize(m.group(1))

    # NOTES block
    m = re.search(r'NOTES[:\s]*([\s\S]*?)Prepared by[:\s]*', combined_text, re.IGNORECASE)
    if m:
        out["Notes"] = re.sub(r'\s{2,}', ' ', m.group(1)).replace('\n', ' ').strip()
    else:
        # sometimes Prepared by appears as 'Prepared by:' (case)
        m2 = re.search(r'NOTES[:\s]*([\s\S]*?)\n{2,}', combined_text, re.IGNORECASE)
        if m2:
            out["Notes"] = re.sub(r'\s{2,}', ' ', m2.group(1)).replace('\n', ' ').strip()

    # Other headers like Confirmed To, Pay Term, FOB, Ship Via, PO Type, Buyer — attempt loose capture
    for key, label in [("Confirmed_To", "Confirmed To"), ("Pay_Term", "Pay Term"), ("FOB", "FOB"),
                       ("Ship_Via", "Ship Via"), ("PO_Type", "PO Type"), ("Buyer", "Buyer"), ("Vendor", "Vendor")]:
        m = re.search(rf'{label}\s*[:\s]*([^\n\r]+)', combined_text, re.IGNORECASE)
        if m:
            out[key] = m.group(1).strip()

    return out


# ---------- Table extraction heuristics ----------
# We'll implement: (1) strict anchored table parse using header anchor "Line No." (2) loose block-based parsing

def find_table_start_lines(page_text: str) -> int:
    """Return index of line where table header (Line No.) appears, else -1."""
    lines = page_text.splitlines()
    for i, ln in enumerate(lines):
        if re.search(r'\bLine\b\s*No\.?', ln, re.IGNORECASE):
            return i
    return -1


def parse_table_by_whitespace(lines: List[str]) -> List[Dict]:
    """
    Heuristic: take lines after header and split by runs of 2+ spaces (or ' | ' if tables were preserved).
    Return list of dicts with keys matching line-level fields.
    """
    rows = []
    for ln in lines:
        if not ln.strip():
            continue
        # Try split by pipe if preserved
        if '|' in ln:
            parts = [p.strip() for p in ln.split('|') if p.strip() != ""]
        else:
            parts = re.split(r'\s{2,}', ln)
            parts = [p.strip() for p in parts if p.strip() != ""]
        # Minimal heuristic mapping (based on sample PDF columns):
        # Expect columns like: [LineNo] [OrderQty] [RcvdQty] [Item#] [Style#] [Model#] [Metal Type] [Metal Color] [Remarks] [SO #]
        # We'll attempt to find numeric columns first
        mapped = {
            "Line_No": "", "Order_Qty": "", "Rcvd_Qty": "", "Item_No": "", "Style_No": "", "Model_No": "",
            "Metal_Type": "", "Metal_Color": "", "Remarks": "", "SO_No": ""
        }
        # If the line begins with an integer, treat that as Line_No and proceed
        m = re.match(r'^\s*(\d{1,3})\b', ln)
        if m:
            mapped["Line_No"] = m.group(1)
            # attempt to find first three numeric tokens after line no
            tokens = ln[m.end():].strip()
            # split tokens by 2+ spaces to preserve columns
            cols = re.split(r'\s{2,}', tokens)
            cols = [c.strip() for c in cols if c.strip()]
            # assign heuristically
            if len(cols) >= 1:
                # first column often: OrderQty  RcvdQty  Item#
                first_parts = re.split(r'\s+', cols[0])
                # try get order and rcvd and item
                if len(first_parts) >= 3 and re.search(r'\d', first_parts[0]):
                    mapped["Order_Qty"] = numeric_normalize(first_parts[0])
                    mapped["Rcvd_Qty"] = numeric_normalize(first_parts[1])
                    mapped["Item_No"] = first_parts[2]
                    # the rest of cols map sequentially
                    if len(cols) >= 2:
                        mapped["Style_No"] = cols[1]
                    if len(cols) >= 3:
                        mapped["Model_No"] = cols[2]
                    if len(cols) >= 4:
                        # metal type/color/remarks may be in one or more cols
                        tail = " | ".join(cols[3:])
                        # attempt metal and color split by two-letter words (heuristic)
                        mt = tail.split('  ')[0].strip()
                        mapped["Metal_Type"] = mt
                        mapped["Remarks"] = tail
                else:
                    # fallback mapping by sequential columns
                    if len(cols) >= 1:
                        mapped["Item_No"] = cols[0]
                    if len(cols) >= 2:
                        mapped["Style_No"] = cols[1]
                    if len(cols) >= 3:
                        mapped["Model_No"] = cols[2]
                    if len(cols) >= 4:
                        mapped["Remarks"] = cols[3]
        else:
            # Not starting with line number -> may be continuation of remarks / multi-line cell.
            # We append this line to last row's Remarks (handled by caller).
            mapped = None

        if mapped:
            rows.append(mapped)
    return rows


STRICT_LINE_RE = re.compile(
    r'^\s*(?P<ln>\d{1,3})\s+(?P<orderqty>[0-9,.]+)\s+(?P<rcvdqty>[0-9,.]+)\s+(?P<item>#?\d+)\s*'
    r'(?P<style>[A-Z0-9\-]{3,})?\s*(?P<model>[A-Z0-9\-\_]{3,})?\s*(?P<metal>[^\\\n]{2,})?',
    re.IGNORECASE | re.MULTILINE
)


def parse_items_strict(combined_text: str) -> List[Dict]:
    """Strict anchored parser using line-level regex. Returns list of item dicts with match_span."""
    items = []
    for m in STRICT_LINE_RE.finditer(combined_text):
        itm = {
            "Line_No": m.group("ln") or "",
            "Order_Qty": numeric_normalize(m.group("orderqty") or ""),
            "Rcvd_Qty": numeric_normalize(m.group("rcvdqty") or ""),
            "Item_No": (m.group("item") or "").strip(),
            "Style_No": (m.group("style") or "").strip(),
            "Model_No": (m.group("model") or "").strip(),
            "Metal_Type": (m.group("metal") or "").strip(),
            "Remarks": "",
            "SO_No": "",
            "match_span": (m.start(), m.end())
        }
        items.append(itm)
    return items


VENDOR_STYLE_RE = re.compile(r'\b([A-Z0-9]{4,}\-?[A-Z0-9]{0,})\b', re.IGNORECASE)


def parse_items_loose(combined_text: str) -> List[Dict]:
    """
    Loose block-based parser: split text into blocks separated by blank lines and search for item-like blocks.
    """
    items = []
    blocks = re.split(r'\n{2,}', combined_text)
    for blk in blocks:
        if not blk.strip():
            continue
        # Look for a starting numeric line indicating a line item
        if re.search(r'^\s*\d{1,3}\s+', blk, re.MULTILINE):
            # split lines and try to extract
            lines = [l.strip() for l in blk.splitlines() if l.strip()]
            if not lines:
                continue
            first = lines[0]
            m = re.match(r'^\s*(\d{1,3})\s+([0-9\.,]+)\s+([0-9\.,]+)\s+(\S+)', first)
            if m:
                ln = m.group(1)
                order_qty = numeric_normalize(m.group(2))
                rcvd_qty = numeric_normalize(m.group(3))
                item_no = m.group(4)
                style = ""
                model = ""
                metal = ""
                remarks = ""
                so_no = ""
                # inspect remaining lines for style/model/metal
                rest = " | ".join(lines[1:])
                # attempt simple splits
                parts = re.split(r'\s{2,}|\|', rest)
                parts = [p.strip() for p in parts if p.strip()]
                if parts:
                    style = parts[0] if len(parts) >= 1 else ""
                    model = parts[1] if len(parts) >= 2 else ""
                    # last parts may contain metal/color/remarks
                    if len(parts) >= 3:
                        metal = parts[2]
                        if len(parts) > 3:
                            remarks = " | ".join(parts[3:])
                items.append({
                    "Line_No": ln,
                    "Order_Qty": order_qty,
                    "Rcvd_Qty": rcvd_qty,
                    "Item_No": item_no,
                    "Style_No": style,
                    "Model_No": model,
                    "Metal_Type": metal,
                    "Metal_Color": "",
                    "Remarks": remarks,
                    "SO_No": so_no,
                    "match_span": None
                })
    # dedupe by (Line_No, Item_No)
    seen = set()
    out = []
    for it in items:
        k = (it.get("Line_No"), it.get("Item_No"))
        if k in seen:
            continue
        seen.add(k)
        out.append(it)
    return out


# ---------- Main extraction ----------
def extract_va_po(pdf_path: str, output_excel_path: str = None, debug: bool = False, increment_dates: bool = True) -> str:
    pdf_path = str(pdf_path)
    pdf_name = Path(pdf_path).stem
    if not output_excel_path:
         output_excel_path = fr"D:\RPA\Purchase_Orders_Extracted_{pdf_name}.xlsx"
         
    logging.info("Reading PDF text...")
    combined_text, pages_text = read_pdf_text(pdf_path)

    if debug:
        dbg_dir = Path(output_excel_path).with_suffix("")  # folder next to output
        dbg_dir = Path(dbg_dir.parent) / f"{pdf_name}_debug"
        dbg_dir.mkdir(parents=True, exist_ok=True)
        (dbg_dir / "combined_text.txt").write_text(combined_text, encoding="utf-8")
        logging.info("Wrote debug combined_text.txt")

    logging.info("Parsing headers...")
    headers = parse_headers(combined_text)
    logging.info(f"Headers parsed: PO_No={headers.get('PO_No')}, Order_Date={headers.get('Order_Date')}, Request_Date={headers.get('Request_Date')}")

    logging.info("Trying strict item parse...")
    items = parse_items_strict(combined_text)
    if items:
        logging.info(f"Strict parser found {len(items)} items.")
    else:
        logging.info("Strict parser found 0 items — trying loose parser...")
        items = parse_items_loose(combined_text)
        logging.info(f"Loose parser found {len(items)} items.")

    if debug:
        import json
        dbg_dir = dbg_dir if 'dbg_dir' in locals() else Path.cwd() / f"{pdf_name}_debug"
        (dbg_dir / "items.json").write_text(json.dumps(items, indent=2), encoding="utf-8")
        logging.info("Wrote debug items.json")

    # Assign per-row dates using Request_Date if present, else use Order_Date; optionally increment per-line
    base_date_str = headers.get("Request_Date") or headers.get("Order_Date") or ""
    base_dt = None
    try:
        base_dt = dateparser.parse(base_date_str) if base_date_str else None
    except Exception:
        base_dt = None

    final_rows = []
    for idx, it in enumerate(items):
        # find local date near match span if available
        found_date_iso = ""
        if it.get("match_span") and it["match_span"]:
            s, e = it["match_span"]
            window = combined_text[max(0, s - 200):min(len(combined_text), e + 400)]
            md = re.search(r'([A-Za-z]{3,}\s+\d{1,2},\s+\d{4})', window)
            if md:
                found_date_iso = normalize_date_iso(md.group(1))

        if found_date_iso:
            order_iso = ship_iso = found_date_iso
        elif base_dt:
            if increment_dates:
                d = base_dt + timedelta(days=idx)
            else:
                d = base_dt
            order_iso = ship_iso = d.strftime("%Y-%m-%d")
        else:
            order_iso = ship_iso = ""

        row = {c: "" for c in OUTPUT_COLUMNS}
        # header fields
        row["PO_No"] = headers.get("PO_No", "")
        row["Order_Date"] = headers.get("Order_Date", "")
        row["Request_Date"] = headers.get("Request_Date", "")
        row["Prepared_By"] = headers.get("Prepared_By", "")
        row["Vendor"] = headers.get("Vendor", "")
        row["Shipping_Address"] = headers.get("Shipping_Address", "")
        row["Ordering_Address"] = headers.get("Ordering_Address", "")
        row["Confirmed_To"] = headers.get("Confirmed_To", "")
        row["Pay_Term"] = headers.get("Pay_Term", "")
        row["FOB"] = headers.get("FOB", "")
        row["Ship_Via"] = headers.get("Ship_Via", "")
        row["PO_Type"] = headers.get("PO_Type", "")
        row["Buyer"] = headers.get("Buyer", "")
        row["Short_Remarks"] = headers.get("Short_Remarks", "")
        row["Total_Quantity"] = headers.get("Total_Quantity", "")

        # line item fields
        for k in ("Line_No", "Order_Qty", "Rcvd_Qty", "Item_No", "Style_No", "Model_No", "Metal_Type", "Metal_Color", "Remarks", "SO_No"):
            if it.get(k) is not None:
                row[k] = it.get(k, "")

        row["Notes"] = headers.get("Notes", "")

        final_rows.append(row)

    # If no line items found, emit a single row with header-only
    if not final_rows:
        row = {c: "" for c in OUTPUT_COLUMNS}
        for h in ["PO_No", "Order_Date", "Request_Date", "Prepared_By", "Shipping_Address", "Ordering_Address", "Total_Quantity", "Notes"]:
            row[h] = headers.get(h, "")
        final_rows.append(row)

    df = pd.DataFrame(final_rows, columns=OUTPUT_COLUMNS)

    # ensure directory exists
    out_dir = os.path.dirname(output_excel_path)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    df.to_excel(output_excel_path, index=False)
    logging.info(f"Wrote Excel: {output_excel_path}  (rows: {len(df)})")
    return output_excel_path


# ---------- CLI ----------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract VA PO data from a PDF file (structured).")
    parser.add_argument("--pdf", required=True, help="Path to the PDF file.")
    parser.add_argument("--out", required=False, help="Optional output Excel path.")
    parser.add_argument("--debug", action="store_true", help="Write debug files (combined text + extracted items).")
    parser.add_argument("--no-increment-dates", dest="no_increment", action="store_true",
                        help="Don't increment per-row dates; use header Request/Order Date for all rows.")
    args = parser.parse_args()
    try:
        out = extract_va_po(args.pdf, args.out, debug=args.debug, increment_dates=(not args.no_increment))
        print("Extraction complete:", out)
    except Exception as exc:
        logging.exception("Extraction failed with an error.")
        raise
