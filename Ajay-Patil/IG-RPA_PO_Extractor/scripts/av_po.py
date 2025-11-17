#!/usr/bin/env python3
"""
av_po_extractor.py

Extractor for AV purchase order PDFs (AVD- style). Produces a standardized Excel
with columns matching the VA extractor's OUTPUT_COLUMNS.

Usage:
    python av_po_extractor.py --pdf INPUT.pdf [--out OUTPUT.xlsx] [--debug] [--no-increment-dates]

Designed to mirror function names / I/O behavior of va_po_extractor_structured.py
"""
import os
import re
import argparse
import logging
from datetime import timedelta
from pathlib import Path
from typing import List, Dict, Tuple, Any

import pdfplumber
import pandas as pd
from dateutil import parser as dateparser

# ---------- Logging ----------
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")


# ---------- Output schema (same standard) ----------
OUTPUT_COLUMNS = [
    "PO_No", "Order_Date", "Request_Date", "Prepared_By", "Vendor",
    "Shipping_Address", "Ordering_Address", "Confirmed_To", "Pay_Term",
    "FOB", "Ship_Via", "PO_Type", "Buyer", "Short_Remarks",
    "Line_No", "Order_Qty", "Rcvd_Qty", "Item_No", "Style_No", "Model_No",
    "Metal_Type", "Metal_Color", "Remarks", "SO_No", "Total_Quantity", "Notes"
]


# ---------- Helpers ----------
def numeric_normalize(v: Any) -> str:
    if v is None:
        return ''
    s = str(v).strip()
    if s == '':
        return ''
    s = s.replace(',', '')
    m = re.search(r'[-+]?\d*\.?\d+', s)
    if not m:
        return s
    try:
        val = float(m.group(0))
    except Exception:
        return s
    if abs(val - round(val)) < 1e-9:
        return str(int(round(val)))
    else:
        s2 = ('{0:.4f}'.format(val)).rstrip('0').rstrip('.')
        return s2


def normalize_date_iso(date_str: Any) -> str:
    if not date_str or str(date_str).strip() == "":
        return ''
    try:
        dt = dateparser.parse(str(date_str), fuzzy=True)
        return dt.strftime("%Y-%m-%d")
    except Exception:
        return ''


def read_pdf_text(pdf_path: str) -> Tuple[str, List[str]]:
    """Read all pages and return combined text and per-page texts (append simple table rows if available)."""
    texts: List[str] = []
    try:
        with pdfplumber.open(pdf_path) as pdf:
            for page in pdf.pages:
                page_text = page.extract_text() or ''
                # append table row text (pipe-joined) to preserve table tokens
                try:
                    tables = page.extract_tables()
                    for t in tables:
                        for row in t:
                            if row:
                                page_text += "\n" + " | ".join([c if c else "" for c in row])
                except Exception:
                    pass
                texts.append(page_text)
    except Exception as e:
        raise RuntimeError(f"Failed to open/read PDF: {e}")
    combined = "\n\n".join(texts)
    return combined, texts


# ---------- Header parsing (tuned for AV layout) ----------
def parse_headers(combined_text: str) -> Dict[str, str]:
    """
    Extract header-level fields for AV PO (PO_No like AVD-40951, Order Date, Request Date,
    Prepared By, addresses, buyer, pay term, short remarks, total quantity, notes).
    """
    out = {k: "" for k in ["PO_No", "Order_Date", "Request_Date", "Prepared_By", "Vendor",
                           "Shipping_Address", "Ordering_Address", "Confirmed_To", "Pay_Term",
                           "FOB", "Ship_Via", "PO_Type", "Buyer", "Short_Remarks", "Total_Quantity", "Notes"]}

    # PO pattern: AVD-40951 (or AV- etc.)
    m = re.search(r'\b(AVD[-\s]*\d+|AV[-\s]*\d+)\b', combined_text, re.IGNORECASE)
    if m:
        out["PO_No"] = m.group(1).strip()

    # Order Date / Request Date / Prepared By - various formats found in AV sample.
    m = re.search(r'Order Date[:\s]*([A-Za-z0-9,\s\/\.-]{6,30})', combined_text, re.IGNORECASE)
    if m:
        out["Order_Date"] = normalize_date_iso(m.group(1).strip())
    # Some AV POs show a date near top like '03/17/2025' -> capture slash dates too
    if not out["Order_Date"]:
        m2 = re.search(r'\b(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})\b', combined_text)
        if m2:
            out["Order_Date"] = normalize_date_iso(m2.group(1))

    m = re.search(r'Request Date[:\s]*([A-Za-z0-9,\s\/\.-]{6,30})', combined_text, re.IGNORECASE)
    if m:
        out["Request_Date"] = normalize_date_iso(m.group(1).strip())

    m = re.search(r'Prepared By[:\s]*([A-Za-z0-9 .]+)', combined_text, re.IGNORECASE)
    if m:
        out["Prepared_By"] = m.group(1).strip()

    # Shipping / Ordering Address (AV sample uses "Shipping Address:Ordering Address:")
    m = re.search(r'Shipping Address[:\s]*([\s\S]*?)Ordering Address[:\s]*', combined_text, re.IGNORECASE)
    if m:
        addr = re.sub(r'\s{2,}', ' ', m.group(1)).replace('\n', ', ').strip(' ,')
        out["Shipping_Address"] = addr

    # Ordering Address (attempt to extract block after Ordering Address)
    m = re.search(r'Ordering Address[:\s]*([\s\S]*?)(?:Confirmed To|Pay Term|FOB|Ship Via|PO Type|Line No\.|$)', combined_text, re.IGNORECASE)
    if m:
        out["Ordering_Address"] = re.sub(r'\s{2,}', ' ', m.group(1)).replace('\n', ', ').strip(' ,')

    # Short remarks, buyer, confirm, pay term, etc.
    m = re.search(r'Confirmed To[:\s]*([^\n\r]+)', combined_text, re.IGNORECASE)
    if m:
        out["Confirmed_To"] = m.group(1).strip()
    m = re.search(r'Pay Term[:\s]*([^\n\r]+)', combined_text, re.IGNORECASE)
    if m:
        out["Pay_Term"] = m.group(1).strip()
    m = re.search(r'FOB[:\s]*([^\n\r]+)', combined_text, re.IGNORECASE)
    if m:
        out["FOB"] = m.group(1).strip()
    m = re.search(r'Ship Via[:\s]*([^\n\r]+)', combined_text, re.IGNORECASE)
    if m:
        out["Ship_Via"] = m.group(1).strip()
    m = re.search(r'PO Type[:\s]*([^\n\r]+)', combined_text, re.IGNORECASE)
    if m:
        out["PO_Type"] = m.group(1).strip()
    m = re.search(r'Buyer[:\s]*([^\n\r]+)', combined_text, re.IGNORECASE)
    if m:
        out["Buyer"] = m.group(1).strip()
    m = re.search(r'Short Remarks[:\s]*([^\n\r]+)', combined_text, re.IGNORECASE)
    if m:
        out["Short_Remarks"] = m.group(1).strip()

    # Total quantity
    m = re.search(r'([\d\.,]+)\s*Total Quantity', combined_text, re.IGNORECASE)
    if m:
        out["Total_Quantity"] = numeric_normalize(m.group(1))

    # NOTES block
    m = re.search(r'NOTES[:\s]*([\s\S]*?)Prepared by[:\s]*', combined_text, re.IGNORECASE)
    if m:
        out["Notes"] = re.sub(r'\s{2,}', ' ', m.group(1)).replace('\n', ' ').strip()
    else:
        m2 = re.search(r'NOTES[:\s]*([\s\S]*?)\n{2,}', combined_text, re.IGNORECASE)
        if m2:
            out["Notes"] = re.sub(r'\s{2,}', ' ', m2.group(1)).replace('\n', ' ').strip()

    return out


# ---------- Metal color helpers (split + inference) ----------
def infer_metal_color_from_text(candidate_text: str) -> str:
    if not candidate_text:
        return ''
    t = str(candidate_text).upper()
    if re.search(r'\bWG\b', t):
        return 'WG'
    if re.search(r'\bYG\b', t):
        return 'YG'
    if re.search(r'\bRG\b', t):
        return 'RG'
    if re.search(r'\bPT\b', t) or 'PLATINUM' in t:
        return 'PT'
    m = re.match(r'^\s*([WYR])\b', t)
    if m:
        ch = m.group(1)
        return {'W': 'WG', 'Y': 'YG', 'R': 'RG'}.get(ch, '')
    if 'WHITE' in t:
        return 'WG'
    if 'YELLOW' in t:
        return 'YG'
    if 'ROSE' in t or 'PINK' in t:
        return 'RG'
    return ''


def split_metal_type_color(raw: str) -> Tuple[str, str]:
    """Split a metal token (like '10KT YG' or '10K YG' or '10KT YG/10K YG') into (type, color)."""
    if not raw:
        return '', ''
    # normalize separators and collapse extra spaces
    s = re.sub(r'[\|\/,]+', ' ', raw).strip()
    parts = [p.strip() for p in s.split() if p.strip()]
    # heuristics: often last token is color (YG/WG/RG), earlier tokens form metal type
    color = ''
    metal_type = ''
    if parts:
        # try detect common color tokens in parts
        for i in range(len(parts)-1, -1, -1):
            if re.search(r'\b(YG|WG|RG|PT|WHITE|YELLOW|ROSE|PINK)\b', parts[i], re.IGNORECASE):
                color = infer_metal_color_from_text(parts[i])
                metal_type = " ".join(parts[:i]).strip()
                break
        if not color:
            # fallback: if last token is like 'YG' or '10KT', decide last token as color if short
            last = parts[-1]
            if len(last) <= 3 and re.match(r'^[A-Z]{1,3}$', last, re.IGNORECASE):
                color = infer_metal_color_from_text(last)
                metal_type = " ".join(parts[:-1]).strip()
            else:
                metal_type = " ".join(parts).strip()
    return metal_type, color


# ---------- Table extraction (strict & loose) ----------
# Strict anchored regex tuned for AV sample table layout:
STRICT_ITEM_RE = re.compile(r'''
    ^\s*(?P<ln>\d{1,3})\s+                                   # line number
    (?P<orderqty>[0-9\.,]+)\s+                               # order qty
    (?P<rcvdqty>[0-9\.,]+)\s+                                # rcvd qty
    (?P<style>\S+)\s+(?P<item>\S+)\s+(?P<model>\S+)\s+        # style, item, model (non-space tokens)
    (?P<metal>[^|\n\r]{1,60})                                 # metal type (+ maybe color/extra)
    (?:\s*\|\s*(?P<metal_color>[^\n\r|]+))?                   # optional explicit metal color column (if present)
    (?:\s+(?P<remarks>\(.+|\b[A-Z0-9].*))?                    # optional remarks (starting with '(' or other)
''', re.IGNORECASE | re.MULTILINE | re.VERBOSE)


def parse_items_strict(combined_text: str) -> List[Dict]:
    items: List[Dict] = []
    for m in STRICT_ITEM_RE.finditer(combined_text):
        raw_metal = (m.group('metal') or "").strip()
        metal_type, metal_color = split_metal_type_color(raw_metal)
        explicit_color = (m.group('metal_color') or "").strip()
        if explicit_color and not metal_color:
            metal_color = infer_metal_color_from_text(explicit_color)
        remarks = (m.group('remarks') or "").strip()
        items.append({
            "Line_No": m.group("ln") or "",
            "Order_Qty": numeric_normalize(m.group("orderqty") or ""),
            "Rcvd_Qty": numeric_normalize(m.group("rcvdqty") or ""),
            "Style_No": (m.group("style") or "").strip(),
            "Item_No": (m.group("item") or "").strip(),
            "Model_No": (m.group("model") or "").strip(),
            "Metal_Type": metal_type,
            "Metal_Color": metal_color,
            "Remarks": remarks,
            "SO_No": "",
            "match_span": (m.start(), m.end())
        })
    return items


# Loose block-based parser: split by double newlines and heuristics similar to VA loose parser
def parse_items_loose(combined_text: str) -> List[Dict]:
    items: List[Dict] = []
    blocks = re.split(r'\n{2,}', combined_text)
    for blk in blocks:
        if not blk.strip():
            continue
        # detect blocks that contain numeric qty and a style/item token
        if re.search(r'\b\d+\s+[0-9\.,]+\s+[0-9\.,]+', blk) or re.search(r'\bStyle\s*#', blk, re.IGNORECASE):
            lines = [l.strip() for l in blk.splitlines() if l.strip()]
            # attempt to find first line with numbers
            found = False
            for ln in lines:
                m = re.match(r'^\s*(\d{1,3})\s+([0-9\.,]+)\s+([0-9\.,]+)\s+(\S+)\s+(\S+)\s+(\S+)\s*(.*)', ln)
                if m:
                    found = True
                    line_no = m.group(1)
                    order_q = numeric_normalize(m.group(2))
                    rcvd_q = numeric_normalize(m.group(3))
                    style = m.group(4)
                    item = m.group(5)
                    model = m.group(6)
                    tail = m.group(7).strip()
                    # tail often contains metal type and remarks - split
                    metal_type, metal_color = split_metal_type_color(tail)
                    remarks = ""
                    if '(' in tail:
                        # everything from '(' is remarks
                        idx = tail.find('(')
                        remarks = tail[idx:].strip()
                        metal_type = tail[:idx].strip()
                        mt, mc = split_metal_type_color(metal_type)
                        metal_type = mt
                        if not metal_color:
                            metal_color = mc
                    items.append({
                        "Line_No": line_no,
                        "Order_Qty": order_q,
                        "Rcvd_Qty": rcvd_q,
                        "Style_No": style,
                        "Item_No": item,
                        "Model_No": model,
                        "Metal_Type": metal_type,
                        "Metal_Color": metal_color,
                        "Remarks": remarks,
                        "SO_No": "",
                        "match_span": None
                    })
                    break
            if not found:
                # fallback: attempt to pull tokens from block's first combined line
                first = lines[0]
                m2 = re.match(r'^\s*(\d{1,3})\s+([0-9\.,]+)\s+([0-9\.,]+)\s+(.*)', first)
                if m2:
                    line_no = m2.group(1)
                    order_q = numeric_normalize(m2.group(2))
                    rcvd_q = numeric_normalize(m2.group(3))
                    rest = m2.group(4).strip()
                    parts = re.split(r'\s{2,}|\|', rest)
                    parts = [p.strip() for p in parts if p.strip()]
                    style = parts[0] if len(parts) > 0 else ""
                    item = parts[1] if len(parts) > 1 else ""
                    model = parts[2] if len(parts) > 2 else ""
                    tail = " | ".join(parts[3:]) if len(parts) > 3 else ""
                    metal_type, metal_color = split_metal_type_color(tail)
                    remarks = "" if not tail else tail
                    items.append({
                        "Line_No": line_no,
                        "Order_Qty": order_q,
                        "Rcvd_Qty": rcvd_q,
                        "Style_No": style,
                        "Item_No": item,
                        "Model_No": model,
                        "Metal_Type": metal_type,
                        "Metal_Color": metal_color,
                        "Remarks": remarks,
                        "SO_No": "",
                        "match_span": None
                    })
    # dedupe by key
    seen = set()
    out = []
    for it in items:
        key = (it.get("Line_No"), it.get("Item_No"), it.get("Style_No"))
        if key in seen:
            continue
        seen.add(key)
        out.append(it)
    return out


# ---------- Main extraction function (mirrors VA extractor signature) ----------
def extract_av_po(pdf_path: str, output_excel_path: str = None, debug: bool = False, increment_dates: bool = True) -> str:
    pdf_path = str(pdf_path)
    pdf_name = Path(pdf_path).stem
    if not output_excel_path:
        output_excel_path = fr"D:\RPA\Purchase_Orders_Extracted_{pdf_name}.xlsx"

    logging.info("Reading PDF text...")
    combined_text, pages_text = read_pdf_text(pdf_path)

    if debug:
        dbg_dir = Path(output_excel_path).with_suffix("")
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
        logging.info("Strict parser found 0 items — trying loose parser and whitespace table fallback...")
        # try whitespace/table per-page extraction first (if table rows were appended)
        items_whitespace: List[Dict] = []
        try:
            with pdfplumber.open(pdf_path) as pdf:
                for p in pdf.pages:
                    pt = p.extract_text() or ""
                    # find header anchor
                    lines = pt.splitlines()
                    # find index for 'Line' or 'Line No.'
                    idx = -1
                    for i, ln in enumerate(lines):
                        if re.search(r'\bLine\b.*Order\s*Qty|\bLine\b\s*No', ln, re.IGNORECASE):
                            idx = i
                            break
                    if idx >= 0:
                        parsed = []
                        # pass lines after header to a simple whitespace parser
                        for ln in lines[idx+1:]:
                            # reuse a tiny heuristic: split by ' | ' if present else by 2+ spaces
                            if '|' in ln:
                                parts = [p.strip() for p in ln.split('|') if p.strip()]
                            else:
                                parts = re.split(r'\s{2,}', ln)
                                parts = [p.strip() for p in parts if p.strip()]
                            if not parts:
                                continue
                            # if line starts with integer -> likely item
                            if re.match(r'^\d', ln.strip()):
                                # try to map tokens: ln, order, rcvd, style, item, model, metal...
                                tok = re.split(r'\s+', ln.strip())
                                # push into parsed as fallback
                                # attempt minimal mapping
                                mapped = {
                                    "Line_No": tok[0] if len(tok) > 0 else "",
                                    "Order_Qty": tok[1] if len(tok) > 1 else "",
                                    "Rcvd_Qty": tok[2] if len(tok) > 2 else "",
                                    "Style_No": tok[3] if len(tok) > 3 else "",
                                    "Item_No": tok[4] if len(tok) > 4 else "",
                                    "Model_No": tok[5] if len(tok) > 5 else "",
                                    "Metal_Type": " ".join(tok[6:8]) if len(tok) > 6 else "",
                                    "Metal_Color": "",
                                    "Remarks": " ".join(tok[8:]) if len(tok) > 8 else "",
                                    "SO_No": ""
                                }
                                parsed.append(mapped)
                        items_whitespace.extend(parsed)
            if items_whitespace:
                items = items_whitespace
                logging.info(f"Whitespace heuristic found {len(items)} items.")
            else:
                items = parse_items_loose(combined_text)
                logging.info(f"Loose parser found {len(items)} items.")
        except Exception:
            # fallback to loose parser if any error
            items = parse_items_loose(combined_text)
            logging.info(f"Loose parser found {len(items)} items (fallback).")

    # infer metal color when missing
    for it in items:
        if not it.get("Metal_Color"):
            guessed = infer_metal_color_from_text((it.get("Metal_Type") or "") + " " + (it.get("Remarks") or ""))
            if not guessed:
                guessed = infer_metal_color_from_text((it.get("Style_No") or "") + " " + (it.get("Item_No") or ""))
            if guessed:
                it["Metal_Color"] = guessed
                logging.debug(f"Inferred Metal_Color={guessed} for line {it.get('Line_No')}")

    if debug:
        import json
        dbg_dir = Path(output_excel_path).with_suffix("")
        dbg_dir = Path(dbg_dir.parent) / f"{pdf_name}_debug"
        (dbg_dir / "items.json").write_text(json.dumps(items, indent=2), encoding="utf-8")
        logging.info("Wrote debug items.json")

    # assign per-row dates using Request_Date or Order_Date and optionally increment
    base_date_str = headers.get("Request_Date") or headers.get("Order_Date") or ""
    base_dt = None
    try:
        base_dt = dateparser.parse(base_date_str) if base_date_str else None
    except Exception:
        base_dt = None

    # compose final rows
    final_rows: List[Dict] = []
    for idx, it in enumerate(items):
        # try find per-line date near match_span
        found_date_iso = ""
        if it.get("match_span"):
            s, e = it["match_span"]
            ctx = combined_text[max(0, s-200):min(len(combined_text), e+400)]
            md = re.search(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}|[A-Za-z]{3,}\s+\d{1,2},\s+\d{4})', ctx)
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
        # populate header fields
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

        # copy line-specific fields
        for k in ("Line_No", "Order_Qty", "Rcvd_Qty", "Item_No", "Style_No", "Model_No", "Metal_Type", "Metal_Color", "Remarks", "SO_No"):
            if it.get(k) is not None:
                if k in ("Order_Qty", "Rcvd_Qty"):
                    row[k] = numeric_normalize(it.get(k, ""))
                else:
                    row[k] = it.get(k, "")

        row["Notes"] = headers.get("Notes", "")
        final_rows.append(row)

    # if no items found, emit a header-only row
    if not final_rows:
        row = {c: "" for c in OUTPUT_COLUMNS}
        for h in ["PO_No", "Order_Date", "Request_Date", "Prepared_By", "Shipping_Address", "Ordering_Address", "Total_Quantity", "Notes"]:
            row[h] = headers.get(h, "")
        final_rows.append(row)

    df_out = pd.DataFrame(final_rows, columns=OUTPUT_COLUMNS)

    # ensure output dir exists
    out_dir = os.path.dirname(output_excel_path)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    df_out.to_excel(output_excel_path, index=False)
    logging.info(f"Wrote Excel: {output_excel_path}  (rows: {len(df_out)})")
    return output_excel_path


# ---------- CLI ----------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract AV PO data from a PDF file (structured).")
    parser.add_argument("--pdf", required=True, help="Path to the AV PO PDF file.")
    parser.add_argument("--out", required=False, help="Optional output Excel path.")
    parser.add_argument("--debug", action="store_true", help="Write debug files (combined text + extracted items).")
    parser.add_argument("--no-increment-dates", dest="no_increment", action="store_true",
                        help="Don't increment per-row dates; use header Request/Order Date for all rows.")
    args = parser.parse_args()
    try:
        out = extract_av_po(args.pdf, args.out, debug=args.debug, increment_dates=(not args.no_increment))
        print("Extraction complete:", out)
    except Exception as exc:
        logging.exception("Extraction failed with an error.")
        raise
