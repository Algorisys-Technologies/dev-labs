#!/usr/bin/env python3
"""
universal_po_extractor_file.py

Universal PO extractor that accepts many file types via --file (PDF / RTF / DOCX / TXT / HTML).
Updated parse_walmart function included to handle the Wal-Mart RTF structure you uploaded.

Function:
    extract_po_data(file_path: str, output_excel_path: str = None, debug: bool = False) -> str

Usage:
    python universal_po_extractor_file.py --file INPUT_FILE [--out OUTPUT.xlsx] [--debug]
"""
import os
import re
import json
import argparse
import logging
import math
from pathlib import Path
from typing import Tuple, List, Dict, Any

import pandas as pd
from dateutil import parser as dateparser

# optional imports
try:
    import pdfplumber
except Exception:
    pdfplumber = None

try:
    import docx
except Exception:
    docx = None

try:
    from bs4 import BeautifulSoup
except Exception:
    BeautifulSoup = None

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

# Standard output columns (Option A)
OUTPUT_COLUMNS = [
    "PO_No", "Buyer", "Vendor", "PO_Date", "PO_Header_ExFactoryDate",
    "Subtotal", "GST", "Total_Units", "Total_USD",
    "Line_No", "Style_Code", "SKU", "Description", "Line_ExFactoryDate",
    "Quantity", "Weight", "Unit_Price", "Discount", "Amount"
]


# ---------------- File reading helpers ----------------
def read_pdf_text(path: str) -> Tuple[str, List[str]]:
    if pdfplumber is None:
        raise RuntimeError("pdfplumber required to read PDF files. Install with `pip install pdfplumber`.")
    pages = []
    with pdfplumber.open(path) as pdf:
        for p in pdf.pages:
            txt = p.extract_text() or ""
            # append any table rows as pipe-joined lines (helps preserve columns)
            try:
                for t in (p.extract_tables() or []):
                    for r in t:
                        if r and any(c for c in r if c):
                            txt += "\n" + " | ".join([c if c else "" for c in r])
            except Exception:
                pass
            pages.append(txt)
    combined = "\n\n".join(pages)
    return combined, pages


def strip_rtf_controls(raw: str) -> str:
    # Basic RTF -> plain text cleanup (works for most RTFs exported by PO systems)
    t = re.sub(r'[{}]', '', raw)
    t = re.sub(r'\\[a-zA-Z]+\-?\d*', '', t)           # remove control words like \par, \fs24
    t = re.sub(r"\\'[0-9a-fA-F]{2}", '', t)           # remove escaped hex sequences
    t = re.sub(r'\s{2,}', ' ', t)
    t = re.sub(r'\r\n|\r', '\n', t)
    t = re.sub(r'\n{3,}', '\n\n', t)
    return t.strip()


def read_docx_text(path: str) -> Tuple[str, List[str]]:
    if docx is None:
        raise RuntimeError("python-docx required to read DOCX files. Install with `pip install python-docx`.")
    d = docx.Document(path)
    paras = [p.text for p in d.paragraphs if p.text and p.text.strip()]
    combined = "\n\n".join(paras)
    blocks = [b.strip() for b in combined.split('\n\n') if b.strip()]
    return combined, blocks


def read_html_text(path: str) -> Tuple[str, List[str]]:
    raw = Path(path).read_text(encoding='utf-8', errors='ignore')
    if BeautifulSoup:
        soup = BeautifulSoup(raw, "html.parser")
        text = soup.get_text("\n")
    else:
        # crude fallback: strip tags
        text = re.sub(r'<[^>]+>', '', raw)
    blocks = [b.strip() for b in re.split(r'\n{2,}', text) if b.strip()]
    return text, blocks


def read_any_file(path: str) -> Tuple[str, List[str]]:
    """
    Read any input file and return (combined_text, blocks_list).
    Supports: .pdf, .rtf, .docx, .txt, .html/.htm. Fallback to plain text read.
    """
    p = Path(path)
    ext = p.suffix.lower()
    if ext == '.pdf':
        return read_pdf_text(path)
    elif ext == '.rtf':
        raw = p.read_text(encoding='utf-8', errors='ignore')
        clean = strip_rtf_controls(raw)
        return clean, [b.strip() for b in re.split(r'\n{2,}', clean) if b.strip()]
    elif ext in ('.docx', '.doc'):
        try:
            return read_docx_text(path)
        except Exception:
            raw = p.read_text(encoding='utf-8', errors='ignore')
            return raw, [b.strip() for b in re.split(r'\n{2,}', raw) if b.strip()]
    elif ext in ('.html', '.htm'):
        return read_html_text(path)
    else:
        # txt or unknown: read as text
        raw = p.read_text(encoding='utf-8', errors='ignore')
        return raw, [b.strip() for b in re.split(r'\n{2,}', raw) if b.strip()]


# ---------------- Generic helpers ----------------
def normalize_numeric_token(s: str, locale_comma_decimal: bool) -> str:
    if s is None:
        return ''
    s = str(s).strip()
    if s == '':
        return ''
    s = s.replace('USD', '').replace('$', '').replace('€', '').strip()
    if locale_comma_decimal:
        # remove thousand dots/spaces then replace comma with dot
        s = s.replace(' ', '').replace('.', '').replace(',', '.')
    else:
        s = s.replace(',', '')
    m = re.search(r'[-+]?\d*\.?\d+', s)
    return m.group(0) if m else ''


def to_float_locale(s: str, locale_comma_decimal: bool) -> float:
    try:
        tok = normalize_numeric_token(s, locale_comma_decimal)
        return float(tok)
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
                return pd.to_datetime(m.group(1)).strftime("%Y-%m-%d")
            except:
                pass
    return ''


def compute_amount_from_parts(qs: str, us: str, ds: str, locale_comma_decimal: bool) -> str:
    q = to_float_locale(qs, locale_comma_decimal)
    u = to_float_locale(us, locale_comma_decimal)
    if isinstance(ds, str) and '%' in ds:
        try:
            pct = float(ds.replace('%', '').strip()) / 100.0
            d_amt = q * u * pct
        except:
            d_amt = 0.0
    else:
        d_amt = to_float_locale(ds, locale_comma_decimal)
        if math.isnan(d_amt):
            d_amt = 0.0
    if math.isnan(q) or math.isnan(u):
        return ''
    val = q * u - d_amt
    try:
        return "{:.2f}".format(round(val + 1e-9, 2))
    except:
        return ''


# ---------------- Document type detection ----------------
def detect_doc_type(combined_text: str) -> str:
    t = combined_text.lower()
    if 'thom' in t or 'order ref' in t or re.search(r'\bthom', t):
        return 'THOM'
    if 'commande' in t or 'commandes' in t or 'orders n' in t:
        return 'COMMANDES'
    if 'ordine di acquisto' in t or 'ordine' in t or 'stroili' in t:
        return 'PO25'
    if 'purchase order' in t and 'vendor stock' in t or 'product' in t and 'vendor stock' in t:
        return 'WALMART'
    # fallback: if single-line summary use COMMANDES
    if re.search(r'qty ordered|price per unit|total order amount', t):
        return 'COMMANDES'
    return 'UNKNOWN'


# ---------------- Parsers per doc type (conservative heuristics) ----------------
def parse_thom(combined_text: str, blocks: List[str]) -> Tuple[Dict[str, str], List[Dict[str, str]]]:
    locale_comma = True
    headers = {k: '' for k in ["PO_No","Buyer","Vendor","PO_Date","PO_Header_ExFactoryDate","Subtotal","GST","Total_Units","Total_USD"]}
    m = re.search(r'Order ref\s*[:\s]*([A-Z0-9\-]+)', combined_text, re.IGNORECASE)
    if m:
        headers["PO_No"] = m.group(1).strip()
    # date
    m = re.search(r'Date of order\s*[:\s]*([0-9\/\.,\-\s]+)', combined_text, re.IGNORECASE)
    if m:
        headers["PO_Date"] = normalize_date_iso(m.group(1))
    # buyer vendor
    lines = combined_text.splitlines()
    for ln in lines[:12]:
        if ln.strip() and not re.search(r'order form|date of order|order ref|provider|provider code', ln, re.IGNORECASE):
            headers["Buyer"] = ln.strip()
            break
    # items: seek lines starting with style-like token and trailing numeric tokens
    items = []
    for ln in combined_text.splitlines():
        ln = ln.strip()
        if not ln:
            continue
        if re.match(r'^[A-Z0-9]{2,}[-/][A-Z0-9\-/]{1,}', ln) or re.match(r'^[A-Z]{1,3}-\d', ln):
            nums = re.findall(r'[\d\s\.\,]*\d+[,\.]\d{1,2}|\b\d+\b', ln)
            unit = nums[-2] if len(nums) >= 2 else ''
            total = nums[-1] if nums else ''
            qty = ''
            m_seq = re.search(r'([0-9]+(?:[.,][0-9]+)?)\s+([0-9\.,\s]*\d+[,\.]\d{1,2})\s+([0-9\.,\s]*\d+[,\.]\d{1,2})\s*$', ln)
            if m_seq:
                qty = m_seq.group(1); unit = m_seq.group(2); total = m_seq.group(3)
            tokens = re.split(r'\s{2,}|\s\|\s', ln)
            style = tokens[0] if tokens else ''
            sku = tokens[1] if len(tokens) > 1 else ''
            desc = " ".join(tokens[2:]) if len(tokens) > 2 else ln
            items.append({
                "Style_Code": style, "SKU": sku, "Description": desc,
                "Line_ExFactoryDate": "", "Quantity": normalize_numeric_token(qty:=qty, True) if isinstance(qty, str) else "",
                "Weight":"", "Unit_Price": normalize_numeric_token(unit, True), "Discount":"", "Amount": normalize_numeric_token(total, True)
            })
    return headers, items


def parse_commandes(combined_text: str, blocks: List[str]) -> Tuple[Dict[str,str], List[Dict[str,str]]]:
    headers = {k: '' for k in ["PO_No","Buyer","Vendor","PO_Date","PO_Header_ExFactoryDate","Subtotal","GST","Total_Units","Total_USD"]}
    m = re.search(r'Orders n[°º]?\s*[:\s]*([0-9A-Za-z\-]+)', combined_text, re.IGNORECASE)
    if m:
        headers["PO_No"] = m.group(1).strip()
    mprice = re.search(r'Total order amount excluding vat\s*[:\s]*([0-9\.,]+)', combined_text, re.IGNORECASE)
    if mprice:
        headers["Total_USD"] = normalize_numeric_token(mprice.group(1), False)
    items = []
    mline = re.search(r'([A-Z0-9\-]{4,})\s+.*?Qty ordered\s*[:\s]*([0-9]+).*?Price per unit\s*[:\s]*([0-9\.,]+)', combined_text, re.IGNORECASE | re.DOTALL)
    if mline:
        style = mline.group(1)
        qty = mline.group(2); unit = mline.group(3)
        items.append({"Style_Code": style, "SKU":"", "Description":"", "Line_ExFactoryDate":"","Quantity":normalize_numeric_token(qty, False), "Weight":"", "Unit_Price":normalize_numeric_token(unit, False), "Discount":"", "Amount": normalize_numeric_token(headers["Total_USD"], False)})
    return headers, items


def parse_po25(combined_text: str, blocks: List[str]) -> Tuple[Dict[str,str], List[Dict[str,str]]]:
    headers = {k: '' for k in ["PO_No","Buyer","Vendor","PO_Date","PO_Header_ExFactoryDate","Subtotal","GST","Total_Units","Total_USD"]}
    m = re.search(r'Ordine n[°º]?\s*[:\s]*([A-Z0-9\-]+)', combined_text, re.IGNORECASE)
    if m:
        headers["PO_No"] = m.group(1).strip()
    items = []
    for ln in combined_text.splitlines():
        ln = ln.strip()
        if not ln:
            continue
        if re.match(r'^[A-Z0-9\-\/]{4,}', ln) and re.search(r'\d', ln):
            nums = re.findall(r'([0-9]+(?:[.,][0-9]+)?)', ln)
            qty = nums[0] if nums else ''
            unit = nums[-2] if len(nums) >= 2 else ''
            total = nums[-1] if nums else ''
            parts = re.split(r'\s{2,}|\s\|\s', ln)
            style = parts[0] if parts else ''
            sku = parts[1] if len(parts) > 1 else ''
            desc = " ".join(parts[2:]) if len(parts) > 2 else ln
            items.append({"Style_Code": style, "SKU": sku, "Description": desc, "Line_ExFactoryDate":"", "Quantity": normalize_numeric_token(qty, False), "Weight":"", "Unit_Price": normalize_numeric_token(unit, False), "Discount":"", "Amount": normalize_numeric_token(total, False)})
    return headers, items


# ----------------- Updated WALMART parser & helper -----------------
def _find_vendor_codes(text: str):
    """
    Return unique vendor-code matches with approximate positions.
    Vendor codes in your file look like: L-RG-58169-100 or L-PN-49537-033, 10K-...
    """
    # vendor pattern tuned for your file
    pat = re.compile(r'\b(?:[A-Z]{1,3}-[A-Z0-9\-]{4,}|10K[-A-Z0-9\-]{2,})\b')
    return [m for m in pat.finditer(text)]


def parse_walmart(combined_text: str, blocks: List[str]) -> Tuple[Dict[str,str], List[Dict[str,str]]]:
    """
    Robust WALMART parser: find vendor stock tokens then collect surrounding context
    for Item Id, Quoted each Cost, Qty (EA), and description.
    """
    headers = {k: '' for k in ["PO_No","Buyer","Vendor","PO_Date","PO_Header_ExFactoryDate","Subtotal","GST","Total_Units","Total_USD"]}
    # PO number
    m = re.search(r'Purchase Order[:\s]*([0-9\-]+)', combined_text, re.IGNORECASE)
    if m:
        headers["PO_No"] = m.group(1).strip()
    # Print/Create date
    md = re.search(r'(?:Print Date|Create Date)[:\s]*([0-9\/\:\-\s]+)', combined_text, re.IGNORECASE)
    if md:
        headers["PO_Date"] = normalize_date_iso(md.group(1))

    text = combined_text

    # regex helpers
    itemid_re = re.compile(r'Item Id[:\s]*([0-9A-Za-z\-]+)', re.IGNORECASE)
    quoted_cost_re = re.compile(r'(?:Quoted each Cost|NET FIRST COST|FIRST COST)[:\s]*([0-9\.,]+)', re.IGNORECASE)
    qty_ea_re = re.compile(r'\b([0-9]+(?:\.[0-9]+)?)\s+EA\b', re.IGNORECASE)

    vendor_matches = _find_vendor_codes(text)

    items = []
    seen_keys = set()

    # For each vendor occurrence, inspect a window around it for item id, qty and price
    win_chars_left = 300
    win_chars_right = 600
    for vm in vendor_matches:
        code = vm.group(0)
        # window of text around the match
        s = max(0, vm.start() - win_chars_left)
        e = min(len(text), vm.end() + win_chars_right)
        ctx = text[s:e]

        # find Item Id in the window
        itm = itemid_re.search(ctx)
        item_id = itm.group(1).strip() if itm else ''

        # find quoted cost in the window (unit price)
        qc = quoted_cost_re.search(ctx)
        unit_price = qc.group(1).strip() if qc else ''

        # find a quantity in the window like '1.0000   EA'
        q = qty_ea_re.search(ctx)
        qty = q.group(1) if q else ''

        # build a reasonable description: take vendor line plus next non-empty lines
        desc = ""
        ctx_lines = ctx.splitlines()
        # locate the vendor code's line index within ctx_lines
        vline_idx = None
        for idx, ln in enumerate(ctx_lines):
            if code in ln:
                vline_idx = idx
                break
        if vline_idx is not None:
            parts = []
            first_line = ctx_lines[vline_idx].replace(code, "").strip()
            if first_line:
                parts.append(first_line)
            for j in range(vline_idx + 1, min(vline_idx + 4, len(ctx_lines))):
                candidate = ctx_lines[j].strip()
                if candidate and not re.fullmatch(r'[-_\s]+', candidate):
                    parts.append(candidate)
            desc = " | ".join(parts).strip()

        # dedupe key: vendor_code + item_id + qty
        key = (code, item_id or None, qty or None)
        if key in seen_keys:
            continue
        seen_keys.add(key)

        items.append({
            "Style_Code": code,
            "SKU": item_id,
            "Description": desc,
            "Line_ExFactoryDate": "",
            "Quantity": qty or "1",
            "Weight": "",
            "Unit_Price": unit_price,
            "Discount": "",
            "Amount": ""  # will compute later
        })

    # fallback: if no vendor matches found, also attempt parsing table rows by scanning for lines
    if not items:
        lines = combined_text.splitlines()
        for i, ln in enumerate(lines):
            if re.search(r'VNDR STK NBR|ITEM NBR|UPC DESCRIPTION', ln, re.IGNORECASE):
                for j in range(i+1, min(i+200, len(lines))):
                    row = lines[j].strip()
                    if not row:
                        continue
                    vm2 = _find_vendor_codes(row)
                    if vm2:
                        code = vm2[0].group(0)
                        look_window = "\n".join(lines[j:j+20])
                        itm = itemid_re.search(look_window)
                        item_id = itm.group(1).strip() if itm else ''
                        qc = quoted_cost_re.search(look_window)
                        unit_price = qc.group(1).strip() if qc else ''
                        q = qty_ea_re.search(look_window)
                        qty = q.group(1) if q else "1"
                        items.append({
                            "Style_Code": code,
                            "SKU": item_id,
                            "Description": row,
                            "Line_ExFactoryDate": "",
                            "Quantity": qty,
                            "Weight": "",
                            "Unit_Price": unit_price,
                            "Discount": "",
                            "Amount": ""
                        })
                    if re.match(r'_+', row) or re.search(r'Purchase Order', row, re.IGNORECASE):
                        continue

    # compute Amount where Unit_Price and Quantity present (no locale-comma handling needed in this Walmart file)
    for it in items:
        try:
            q = float(it["Quantity"]) if it["Quantity"] else 1.0
            u = float(it["Unit_Price"].replace(',', '')) if it["Unit_Price"] else float('nan')
            if not pd.isna(u):
                it["Amount"] = "{:.2f}".format(q * u)
        except Exception:
            it["Amount"] = it.get("Amount", "")

    return headers, items


# ---------------- Main extraction wrapper (public function) ----------------
def extract_po_data(file_path: str, output_excel_path: str = None, debug: bool = False) -> str:
    """
    Public function: accepts any file via path, extracts PO & writes Excel.
    Returns path to output Excel.
    """
    file_path = str(file_path)
    fp = Path(file_path)
    stem = fp.stem
    if not output_excel_path:
        output_excel_path = fr"D:\RPA\Purchase_Orders_Extracted_{stem}.xlsx"

    logging.info("Reading input file: %s", file_path)
    combined_text, blocks = read_any_file(file_path)

    if debug:
        dbg_dir = Path(output_excel_path).with_suffix("")
        dbg_dir = Path(dbg_dir.parent) / f"{stem}_debug"
        dbg_dir.mkdir(parents=True, exist_ok=True)
        (dbg_dir / "combined_text.txt").write_text(combined_text, encoding='utf-8')
        logging.info("Wrote combined_text debug.")

    doc_type = detect_doc_type(combined_text)
    logging.info("Detected document type: %s", doc_type)

    # call parser per type
    if doc_type == 'THOM':
        headers, items = parse_thom(combined_text, blocks)
    elif doc_type == 'COMMANDES':
        headers, items = parse_commandes(combined_text, blocks)
    elif doc_type == 'PO25':
        headers, items = parse_po25(combined_text, blocks)
    elif doc_type == 'WALMART':
        headers, items = parse_walmart(combined_text, blocks)
    else:
        # attempt all heuristics and pick the one giving the most item rows
        candidates = []
        for fn in (parse_walmart, parse_thom, parse_po25, parse_commandes):
            try:
                h, its = fn(combined_text, blocks)
                candidates.append((fn.__name__, h, its))
            except Exception:
                continue
        if candidates:
            candidates_sorted = sorted(candidates, key=lambda x: len(x[2]), reverse=True)
            _, headers, items = candidates_sorted[0]
        else:
            headers = {k: '' for k in ["PO_No","Buyer","Vendor","PO_Date","PO_Header_ExFactoryDate","Subtotal","GST","Total_Units","Total_USD"]}
            items = []

    # choose locale: detect comma-decimal presence
    locale_comma_decimal = bool(re.search(r'\d[\s\d\.]*,\d{1,2}', combined_text))

    final_rows = []
    if not items:
        # produce header-only single row
        row = {c: "" for c in OUTPUT_COLUMNS}
        for k in ("PO_No","Buyer","Vendor","PO_Date","PO_Header_ExFactoryDate","Subtotal","GST","Total_Units","Total_USD"):
            row[k] = headers.get(k, "")
        final_rows.append(row)
    else:
        # if single-item doc expected (COMMANDES) but many candidates found, pick best single
        if doc_type == 'COMMANDES' and len(items) > 1:
            items = sorted(items, key=lambda it: (bool(it.get("Unit_Price")) and bool(it.get("Quantity")), float(it.get("Amount") or 0.0) ), reverse=True)[:1]
        for i, it in enumerate(items, start=1):
            # compute reliable amount
            amt = it.get("Amount", "")
            comp_amt = compute_amount_from_parts(it.get("Quantity",""), it.get("Unit_Price",""), it.get("Discount",""), locale_comma_decimal)
            if comp_amt:
                amt = comp_amt
            row = {
                "PO_No": headers.get("PO_No",""),
                "Buyer": headers.get("Buyer",""),
                "Vendor": headers.get("Vendor",""),
                "PO_Date": headers.get("PO_Date",""),
                "PO_Header_ExFactoryDate": headers.get("PO_Header_ExFactoryDate",""),
                "Subtotal": headers.get("Subtotal",""),
                "GST": headers.get("GST",""),
                "Total_Units": headers.get("Total_Units",""),
                "Total_USD": headers.get("Total_USD",""),
                "Line_No": str(i).zfill(4),
                "Style_Code": it.get("Style_Code",""),
                "SKU": it.get("SKU",""),
                "Description": it.get("Description",""),
                "Line_ExFactoryDate": it.get("Line_ExFactoryDate",""),
                "Quantity": it.get("Quantity",""),
                "Weight": it.get("Weight",""),
                "Unit_Price": it.get("Unit_Price",""),
                "Discount": it.get("Discount",""),
                "Amount": amt
            }
            final_rows.append(row)

    df = pd.DataFrame(final_rows, columns=OUTPUT_COLUMNS)

    # write excel
    out_dir = os.path.dirname(output_excel_path)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)
    df.to_excel(output_excel_path, index=False)
    logging.info("Wrote Excel: %s (rows: %d)", output_excel_path, len(df))

    # debug json
    if debug:
        dbg = {"file": file_path, "doc_type": doc_type, "headers": headers, "items_count": len(items), "items_sample": items[:10]}
        dbg_path = Path(output_excel_path).with_suffix('.debug.json')
        with open(dbg_path, "w", encoding='utf-8') as f:
            json.dump(dbg, f, indent=2, ensure_ascii=False)
        logging.info("Wrote debug JSON: %s", dbg_path)

    return output_excel_path


# ---------------- CLI ----------------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Universal PO extractor that accepts --file (pdf/rtf/docx/txt/html).")
    parser.add_argument("--file", required=True, help="Path to input file (pdf/rtf/docx/txt/html)")
    parser.add_argument("--out", required=False, help="Output Excel path (optional).")
    parser.add_argument("--debug", action="store_true", help="Write debug files.")
    args = parser.parse_args()

    try:
        outp = extract_po_data(args.file, args.out, debug=args.debug)
        print("Extraction complete:", outp)
    except Exception:
        logging.exception("Extraction failed.")
        raise
