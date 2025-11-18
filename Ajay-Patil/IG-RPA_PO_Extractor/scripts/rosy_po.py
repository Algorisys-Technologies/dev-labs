#!/usr/bin/env python3
"""
rosy_po_extractor_v3.py

Improved ROSY extractor — stronger vendor-item detection to correctly capture tokens like:
    160-YGE-16501-050

Writes only one Excel file: <out_prefix>_rosy_extracted.xlsx

Usage:
    python rosy_po_extractor_v3.py --pdf "/path/ROSY_....pdf" --out "/path/out_prefix" [--debug]
"""
import argparse, logging, re
from pathlib import Path
from typing import List, Dict, Any, Optional

import pdfplumber
import pandas as pd
from dateutil import parser as dateparser

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

OUTPUT_COLUMNS = [
    "PO_No", "Order_Date", "Requested_Delivery_Date", "Store_No", "Vendor_ID",
    "Ship_To", "Bill_To", "Payment_Terms", "Merch_Type", "Routing",
    "Line_No", "Vendor_Item", "UPC", "Buyer_Number", "Quantity", "UM",
    "Unit_Price", "Total_Amount", "Description"
]


def normalize_money(tok: str) -> str:
    if tok is None:
        return ""
    s = str(tok).strip()
    s = s.replace('$', '').replace(',', '').replace('\u00A0', '')
    m = re.search(r'[-+]?\d*\.?\d+', s)
    return m.group(0) if m else s


def normalize_date(token: str) -> str:
    if not token:
        return ""
    try:
        return dateparser.parse(token, fuzzy=True).strftime("%Y-%m-%d")
    except Exception:
        return token


def read_pdf_text_and_tables(pdf_path: str) -> (str, List[str], List):
    pages_text = []
    tables = []
    with pdfplumber.open(pdf_path) as pdf:
        for p in pdf.pages:
            txt = p.extract_text() or ""
            try:
                tbs = p.extract_tables() or []
                for t in tbs:
                    tables.append(t)
                    for row in t:
                        if row and any(c for c in row if c):
                            txt += "\n" + " | ".join([c if c else "" for c in row])
            except Exception:
                pass
            pages_text.append(txt)
    return "\n\n".join(pages_text), pages_text, tables


def extract_headers(text: str) -> Dict[str, str]:
    h = {"PO_No":"", "Order_Date":"", "Requested_Delivery_Date":"", "Store_No":"",
         "Vendor_ID":"", "Ship_To":"", "Bill_To":"", "Payment_Terms":"", "Merch_Type":"", "Routing":""}
    m = re.search(r'PO\s*Number[:\s]*([A-Z0-9\-]+)', text, re.IGNORECASE)
    if m: h["PO_No"] = m.group(1).strip()
    od = re.search(r'Order\s*Date[:\s]*([0-3]?\d[\/\.\-]\d{1,2}[\/\.\-]\d{2,4})', text, re.IGNORECASE)
    if od: h["Order_Date"] = normalize_date(od.group(1).strip())
    rdd = re.search(r'Requested\s*Delivery\s*Date[:\s]*([0-3]?\d[\/\.\-]\d{1,2}[\/\.\-]\d{2,4})', text, re.IGNORECASE)
    if rdd: h["Requested_Delivery_Date"] = normalize_date(rdd.group(1).strip())
    st = re.search(r'Store\s*#\s*([0-9A-Za-z\-]+)', text, re.IGNORECASE)
    if st: h["Store_No"] = st.group(1).strip()
    v = re.search(r'Vendor[:\s]*([0-9A-Z\-]+)', text, re.IGNORECASE)
    if v: h["Vendor_ID"] = v.group(1).strip()

    def capture(anchor):
        m = re.search(rf'{anchor}\s*[:\s]*(.+?)(?:\n\s*\n|Payment Terms:|Total Dollars:|PO Line #|$)', text, re.IGNORECASE|re.DOTALL)
        if m: return re.sub(r'\s+', ' ', m.group(1).strip())
        m2 = re.search(rf'{anchor}\s*[:\s]*(.+?)(?:\n)', text, re.IGNORECASE|re.DOTALL)
        return re.sub(r'\s+', ' ', m2.group(1).strip()) if m2 else ""
    h["Ship_To"] = capture("Ship To")
    h["Bill_To"] = capture("Bill To")
    pt = re.search(r'Payment\s*Terms[:\s]*([A-Z0-9 ]+)', text, re.IGNORECASE)
    if pt: h["Payment_Terms"] = pt.group(1).strip()
    mt = re.search(r'Merch\s*Type[:\s]*([A-Z0-9 ]+)', text, re.IGNORECASE)
    if mt: h["Merch_Type"] = mt.group(1).strip()
    ro = re.search(r'Routing[:\s]*([A-Z0-9 ]+)', text, re.IGNORECASE)
    if ro: h["Routing"] = ro.group(1).strip()
    return h


def find_items_block_lines(full_text: str) -> List[str]:
    lines = [ln for ln in full_text.splitlines()]
    header_idx = None
    for i, ln in enumerate(lines):
        if re.search(r'PO\s*Line\s*#\s*Vendor\s*Item|Vendor\s*Item\s+UPC|PO\s*Line\s*#', ln, re.IGNORECASE):
            header_idx = i
            break
    item_lines = []
    if header_idx is not None:
        for ln in lines[header_idx+1:]:
            if re.search(r'Total\s+Dollars|Total\s+Amount|Total\s+Pieces|Grand\s*Total', ln, re.IGNORECASE):
                break
            if ln.strip(): item_lines.append(ln.rstrip())
    else:
        for ln in lines:
            if re.search(r'\$\s*\d', ln) or re.search(r'\b\d{12,13}\b', ln):
                item_lines.append(ln)
    # collapse wrapped lines (if line no money but next has money, merge)
    merged = []
    i = 0
    while i < len(item_lines):
        ln = item_lines[i]
        if (not re.search(r'\$\s*\d|\b\d{12,13}\b', ln)) and i+1 < len(item_lines) and re.search(r'\$\s*\d|\b\d{12,13}\b', item_lines[i+1]):
            merged.append((ln + ' ' + item_lines[i+1]).strip())
            i += 2
        else:
            merged.append(ln)
            i += 1
    return merged


def group_item_lines(lines: List[str]) -> List[str]:
    start_re = re.compile(r'(^PO\s*Line\b)|(\b\d{1,4}-[A-Z]{2,4}-\d{2,6}-\d{2,6}\b)|(\b[0-9A-Z]{4,}\-[0-9A-Z\-\_]{2,})|(\b\d{12,13}\b)', re.IGNORECASE)
    groups = []
    cur = None
    for ln in lines:
        if start_re.search(ln):
            if cur is not None:
                groups.append(cur)
            cur = [ln]
        else:
            if cur is None:
                cur = [ln]
            else:
                cur.append(ln)
    if cur:
        groups.append(cur)
    # Merge groups that have no money token into previous group
    def has_money(s): return bool(re.search(r'\$\s*\d|\d{1,3}(?:,\d{3})*(?:\.\d{2})', s))
    merged = []
    for g in groups:
        gtext = " ".join(g)
        if merged and not has_money(gtext):
            merged[-1] = merged[-1] + " " + gtext
        else:
            merged.append(gtext)
    return merged


def detect_vendor_candidates(text: str) -> List[str]:
    """Return list of plausible vendor tokens from text (ordered by plausibility)"""
    candidates = []
    # 1) strict patterned tokens like 160-YGE-16501-050 (digits-hyphen-letters-hyphen-digits-hyphen-digits)
    strict = re.findall(r'\b\d{1,4}-[A-Z]{2,4}-\d{2,6}-\d{2,6}\b', text, re.IGNORECASE)
    candidates.extend(strict)
    # 2) hyphenated tokens with at least one alphabetic segment
    hyph = re.findall(r'\b(?=[0-9A-Z\-]{6,40})(?:[0-9A-Z]+-[0-9A-Z\-]+)\b', text, re.IGNORECASE)
    # keep only those with at least one letter
    hyph = [h for h in hyph if re.search(r'[A-Z]', h, re.IGNORECASE)]
    candidates.extend([h for h in hyph if h not in candidates])
    # 3) tokens that appear after money tokens (strip money) — handle concatenated forms like $228.53290864608160-YGE-...
    no_money = re.sub(r'\$\s*[\d\.,]+', ' ', text)
    post = re.findall(r'\b[0-9A-Z]{1,4}-[0-9A-Z\-\_]{3,40}\b', no_money, re.IGNORECASE)
    for p in post:
        if re.search(r'[A-Z]', p, re.IGNORECASE) and p not in candidates:
            candidates.append(p)
    # return unique preserving order
    seen = set()
    uniq = []
    for c in candidates:
        cc = c.strip('-')
        if cc not in seen:
            uniq.append(cc)
            seen.add(cc)
    # sort by length desc to prefer longer (more specific) tokens first
    uniq.sort(key=lambda x: -len(x))
    return uniq


def parse_group_to_fields(gtext: str) -> Dict[str, Any]:
    # First, remove obvious money tokens for vendor detection
    cleaned_for_vendor = re.sub(r'\$\s*[\d\.,]+', ' ', gtext)
    vendor_candidates = detect_vendor_candidates(cleaned_for_vendor)

    vendor_item = ""
    upc = ""
    buyer = ""
    qty = ""
    um = ""
    unit_price = ""
    total_amount = ""
    desc = ""

    # Choose best vendor candidate that appears in group text
    for cand in vendor_candidates:
        if re.search(re.escape(cand), gtext, re.IGNORECASE):
            vendor_item = cand
            break

    # UPC 12-13 digits
    m_upc = re.search(r'\b(\d{12,13})\b', gtext)
    if m_upc:
        upc = m_upc.group(1)

    # buyer: token right after vendor_item if present
    if vendor_item and vendor_item in gtext:
        tail = gtext.split(vendor_item,1)[1]
        m_buy = re.search(r'\b([0-9A-Z]{3,12})\b', tail)
        if m_buy:
            buyer = m_buy.group(1)

    # qty and UM
    m_q = re.search(r'\b(\d{1,4})\s*(EA|PC|PCS|EA\.)\b', gtext, re.IGNORECASE)
    if m_q:
        qty = m_q.group(1)
        um = m_q.group(2).upper().replace('.', '')
    else:
        m_q2 = re.search(r'(\d{1,4})\s+(?=[^\n]{0,30}\$\s*\d)', gtext)
        if m_q2:
            qty = m_q2.group(1)

    # money tokens
    monies = re.findall(r'\$\s*[\d\.,]+', gtext)
    if monies:
        unit_price = normalize_money(monies[0])
        if len(monies) > 1:
            total_amount = normalize_money(monies[-1])
    else:
        monies2 = re.findall(r'\d{1,3}(?:,\d{3})*(?:\.\d{2})', gtext)
        if monies2:
            unit_price = monies2[0]
            if len(monies2) > 1:
                total_amount = monies2[-1]

    # description: remove vendor_item and money tokens and UPC
    dd = gtext
    if vendor_item:
        dd = re.sub(re.escape(vendor_item), ' ', dd, flags=re.IGNORECASE)
    dd = re.sub(r'\$\s*[\d\.,]+', ' ', dd)
    dd = re.sub(r'\b\d{12,13}\b', ' ', dd)
    dd = re.sub(r'\b\d{1,4}\b', ' ', dd)  # remove stray small numbers
    desc = re.sub(r'\s{2,}', ' ', dd).strip()

    return {"Vendor_Item": vendor_item, "UPC": upc, "Buyer_Number": buyer,
            "Quantity": qty, "UM": um, "Unit_Price": unit_price,
            "Total_Amount": total_amount, "Description": desc}


def build_and_write(full_text: str, tables: List, out_prefix: Path, debug_flag: bool):
    headers = extract_headers(full_text)
    item_lines = find_items_block_lines(full_text)
    grouped = group_item_lines(item_lines)

    parsed_rows = []
    for i, g in enumerate(grouped, start=1):
        rec = parse_group_to_fields(g)
        rec_row = {c: "" for c in OUTPUT_COLUMNS}
        rec_row["PO_No"] = headers.get("PO_No","")
        rec_row["Order_Date"] = headers.get("Order_Date","")
        rec_row["Requested_Delivery_Date"] = headers.get("Requested_Delivery_Date","")
        rec_row["Store_No"] = headers.get("Store_No","")
        rec_row["Vendor_ID"] = headers.get("Vendor_ID","")
        rec_row["Ship_To"] = headers.get("Ship_To","")
        rec_row["Bill_To"] = headers.get("Bill_To","")
        rec_row["Payment_Terms"] = headers.get("Payment_Terms","")
        rec_row["Merch_Type"] = headers.get("Merch_Type","")
        rec_row["Routing"] = headers.get("Routing","")
        rec_row["Line_No"] = str(i).zfill(4)
        rec_row["Vendor_Item"] = rec["Vendor_Item"]
        rec_row["UPC"] = rec["UPC"]
        rec_row["Buyer_Number"] = rec["Buyer_Number"]
        rec_row["Quantity"] = rec["Quantity"]
        rec_row["UM"] = rec["UM"]
        rec_row["Unit_Price"] = rec["Unit_Price"]
        rec_row["Total_Amount"] = rec["Total_Amount"]
        rec_row["Description"] = rec["Description"]
        parsed_rows.append(rec_row)

    # if multiple rows but others look like continuations, merge into first
    if len(parsed_rows) > 1:
        primary = parsed_rows[0]
        others = parsed_rows[1:]
        all_empty_vendor = all((not r["Vendor_Item"]) for r in others)
        if all_empty_vendor:
            for r in others:
                if r["Description"]:
                    primary["Description"] = (primary["Description"] + " " + r["Description"]).strip()
                if not primary["Unit_Price"] and r["Unit_Price"]:
                    primary["Unit_Price"] = r["Unit_Price"]
                if not primary["Total_Amount"] and r["Total_Amount"]:
                    primary["Total_Amount"] = r["Total_Amount"]
            parsed_rows = [primary]

    df = pd.DataFrame(parsed_rows, columns=OUTPUT_COLUMNS)
    parent = out_prefix.parent if out_prefix.parent != Path('.') else Path(out_prefix.parent)
    parent.mkdir(parents=True, exist_ok=True)
    xlsx_path = parent / f"{out_prefix.stem}_rosy_extracted.xlsx"
    df.to_excel(xlsx_path, index=False)

    if debug_flag:
        logging.info("Headers: %s", headers)
        logging.info("Item lines count: %d", len(item_lines))
        logging.info("Grouped items count: %d", len(grouped))
        logging.info("Parsed rows: %s", parsed_rows)

    logging.info("Wrote Excel: %s (rows: %d)", str(xlsx_path), len(df))


def extract_cli(pdf_path: str, out_path: Optional[str] = None, debug_flag: bool = False):
    pdfp = Path(pdf_path)
    if not pdfp.exists():
        raise FileNotFoundError(f"PDF not found: {pdfp}")
    full_text, pages, tables = read_pdf_text_and_tables(str(pdfp))
    if out_path:
        out_prefix = Path(out_path)
        if out_prefix.suffix:
            out_prefix = out_prefix.with_suffix('')
    else:
        out_prefix = pdfp.with_name(pdfp.stem)
    build_and_write(full_text, tables, out_prefix, debug_flag)
    return out_prefix


def main():
    parser = argparse.ArgumentParser(description="ROSY PO extractor v3 (stronger vendor detection)")
    parser.add_argument("--pdf", required=True)
    parser.add_argument("--out", required=False)
    parser.add_argument("--debug", action="store_true", help="Verbose logging only")
    args = parser.parse_args()
    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
    try:
        pref = extract_cli(args.pdf, args.out, debug_flag=args.debug)
        print("Extraction finished. Excel written using prefix:", pref)
    except Exception as e:
        logging.exception("Failed: %s", e)
        raise


if __name__ == '__main__':
    main()
