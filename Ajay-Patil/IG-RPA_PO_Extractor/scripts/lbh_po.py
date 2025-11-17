#!/usr/bin/env python3
"""
lbh_po_extractor_fixed3.py

More robust LBH PO extractor — stronger header discovery across entire PDF and
robust row grouping for table rows. Writes Excel with one row per line item and
repeats header fields.

Usage:
    python lbh_po_extractor_fixed3.py --pdf INPUT.pdf [--out OUTPUT.xlsx] [--debug]
"""
import os
import re
import argparse
import logging
import json
from pathlib import Path
from typing import List, Dict, Any, Tuple

import pdfplumber
import pandas as pd
from dateutil import parser as dateparser

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

OUTPUT_COLUMNS = [
    "PO_No", "Vendor_No", "Vendor", "Issue_Date", "Ship_Date", "Buyer",
    "Bill_To", "Ship_To", "Total_Amount", "Special_Instructions",
    "Line_No", "Vendor_Item_Number", "LBH_Item_Number", "Quantity",
    "Unit_Price", "Ext_Amt", "Description", "Metal_Weight", "Average_Finished_Weight"
]


# ---------- small helpers ----------
def numeric_normalize(v: Any) -> str:
    if v is None:
        return ""
    s = str(v).strip().replace(',', '').replace('$', '')
    m = re.search(r'[-+]?\d*\.?\d+', s)
    return m.group(0) if m else s


def normalize_date_token(token: str) -> str:
    if not token:
        return ""
    token = token.strip()
    # try to parse simple mm/dd/yy tokens first
    m = re.search(r'(\d{1,2}\/\d{1,2}\/\d{2,4})', token)
    if m:
        try:
            return pd.to_datetime(m.group(1)).strftime("%Y-%m-%d")
        except Exception:
            pass
    # fuzzy parse fallback
    try:
        dt = dateparser.parse(token, fuzzy=True)
        return dt.strftime("%Y-%m-%d")
    except Exception:
        return ""


def read_pdf_pages_and_tables(pdf_path: str) -> Tuple[List[str], List]:
    pages_text = []
    all_tables = []
    with pdfplumber.open(pdf_path) as pdf:
        for p in pdf.pages:
            text = p.extract_text() or ""
            # collect tables detected by pdfplumber (list of rows)
            try:
                tables = p.extract_tables() or []
                for t in tables:
                    all_tables.append(t)
                    # append pipe-joined table rows to page text to preserve them for grouping
                    for row in t:
                        if row and any([c for c in row if c]):
                            text += "\n" + " | ".join([c if c else "" for c in row])
            except Exception:
                pass
            pages_text.append(text)
    return pages_text, all_tables


# ---------- robust header extraction ----------
def find_label_value(combined: str, label_patterns: List[str], look_next_lines: int = 2) -> str:
    """
    Search combined text for any of label_patterns (case-insensitive).
    If label present on same line with colon, return the value after colon.
    Else, return first non-empty token from next N lines.
    """
    lines = combined.splitlines()
    for i, ln in enumerate(lines):
        for lab in label_patterns:
            if re.search(lab, ln, re.IGNORECASE):
                # if there's a colon or '#' on same line, prefer text after it
                if ':' in ln or '#' in ln:
                    # try to capture after colon or after label token
                    m = re.search(rf'{lab}.*?[:#\-]\s*(.+)', ln, re.IGNORECASE)
                    if m:
                        return m.group(1).strip()
                    # last-resort: take words after label token
                    m2 = re.split(lab, ln, flags=re.IGNORECASE)
                    if len(m2) > 1 and m2[1].strip():
                        return m2[1].strip()
                # else look on next lines
                for j in range(1, look_next_lines + 1):
                    if i + j < len(lines):
                        nxt = lines[i + j].strip()
                        if nxt:
                            return nxt
    return ""


def extract_header_blocks(combined: str, pages_text: List[str], tables: List) -> Dict[str, str]:
    """
    Aggressive header extraction. Uses label search across entire combined text,
    plus table fallback.
    """
    out = {k: "" for k in ["PO_No", "Vendor_No", "Vendor", "Issue_Date", "Ship_Date", "Buyer", "Bill_To", "Ship_To", "Total_Amount", "Special_Instructions"]}

    # 1) PO - many variants. Find explicit 'PO' anchor first
    po_val = find_label_value(combined, [r'\bPO\b', r'\bP\.?O\.?\b', r'Purchase Order'], look_next_lines=1)
    if po_val:
        # extract a long numeric token from returned text
        m = re.search(r'\b(\d{6,10})\b', po_val)
        if m:
            out["PO_No"] = m.group(1)
        else:
            # maybe the returned text contains the number later; fallback to search for 6-10 digit in combined near 'PO' occurrences
            matches = re.findall(r'\b(\d{6,10})\b', combined)
            if matches:
                out["PO_No"] = matches[0]
    else:
        # 2) fallback: find any 6-10 digit token near top third of document
        cand = re.findall(r'\b(\d{6,10})\b', combined)
        if cand:
            out["PO_No"] = cand[0]

    # 3) Vendor No
    vno = find_label_value(combined, [r'VENDOR\s*NO', r'Vendor Number', r'VENDOR #'], look_next_lines=1)
    if vno:
        m = re.search(r'\b([0-9A-Za-z\-]{4,})\b', vno)
        if m:
            out["Vendor_No"] = m.group(1)
    else:
        # fallback: any 6-8 digit candidate that is not PO
        nums = re.findall(r'\b(\d{6,8})\b', combined)
        for n in nums:
            if n != out["PO_No"]:
                out["Vendor_No"] = n
                break

    # 4) Vendor block: locate vendor anchor and take next few non-empty lines
    vendor_block = ""
    lines = combined.splitlines()
    for i, ln in enumerate(lines):
        if re.search(r'VENDOR\s*NO|VENDOR[:\s]|Supplier[:\s]', ln, re.IGNORECASE):
            # gather next up to 6 lines that look like address/name
            blk = []
            for j in range(i + 1, min(len(lines), i + 10)):
                l2 = lines[j].strip()
                if not l2:
                    break
                # stop if we hit 'Bill to' / 'Ship to' or other header tokens
                if re.search(r'BILL TO|SHIP TO|ISSUE DATE|PO #|PURCHASE ORDER', l2, re.IGNORECASE):
                    break
                blk.append(l2)
            vendor_block = ", ".join(blk)
            break
    out["Vendor"] = vendor_block

    # 5) Issue / Ship dates - prefer labeled tokens
    issue_raw = find_label_value(combined, [r'ISSUE\s*DATE'], look_next_lines=2)
    ship_raw = find_label_value(combined, [r'SHIP\s*DATE'], look_next_lines=2)
    # If the 'ISSUE DATE' label found a line containing two dates (issue & ship), extract both.
    if issue_raw:
        dates = re.findall(r'(\d{1,2}\/\d{1,2}\/\d{2,4})', issue_raw)
        if dates:
            out["Issue_Date"] = normalize_date_token(dates[0])
            if len(dates) > 1:
                out["Ship_Date"] = normalize_date_token(dates[1])
        else:
            out["Issue_Date"] = normalize_date_token(issue_raw)
    if ship_raw and not out["Ship_Date"]:
        out["Ship_Date"] = normalize_date_token(ship_raw)

    # fallback: if still empty, search whole doc for first two mm/dd tokens in top area
    if not out["Issue_Date"] or not out["Ship_Date"]:
        top_tokens = re.findall(r'(\d{1,2}\/\d{1,2}\/\d{2,4})', combined[:4000])
        if top_tokens:
            if not out["Issue_Date"]:
                out["Issue_Date"] = normalize_date_token(top_tokens[0])
            if not out["Ship_Date"] and len(top_tokens) > 1:
                out["Ship_Date"] = normalize_date_token(top_tokens[1])

    # 6) Buyer
    buyer = find_label_value(combined, [r'\bBuyer\b', r'\bPurchaser\b'], look_next_lines=1)
    out["Buyer"] = buyer

    # 7) Bill_To / Ship_To blocks
    def find_block(anchor_patterns):
        lines = combined.splitlines()
        for i, ln in enumerate(lines):
            for pat in anchor_patterns:
                if re.search(pat, ln, re.IGNORECASE):
                    blk = []
                    for j in range(i + 1, min(len(lines), i + 12)):
                        nxt = lines[j].strip()
                        if not nxt:
                            break
                        if re.search(r'VENDOR FAX|BILL TO|SHIP TO|ISSUE DATE|PO #|PURCHASE ORDER|LINE\s+VENDOR', nxt, re.IGNORECASE):
                            break
                        blk.append(nxt)
                    if blk:
                        return ", ".join(blk)
        return ""
    out["Bill_To"] = find_block([r'Bill\s*to', r'Bill To'])
    out["Ship_To"] = find_block([r'Ship\s*to', r'Ship To'])

    # 8) Total amount and special instructions
    total_raw = find_label_value(combined, [r'Purchase Order Total', r'Purchase Order\s*Total', r'Total Amount', r'PO Total'], look_next_lines=1)
    if total_raw:
        m = re.search(r'([0-9\.,]+)', total_raw)
        if m:
            out["Total_Amount"] = numeric_normalize(m.group(1))
    # special instructions block - capture block after 'SPECIAL INSTRUCTIONS/NOTES' anchor
    if 'SPECIAL INSTRUCTIONS' in combined.upper():
        m = re.search(r'SPECIAL INSTRUCTIONS\/NOTES\s*([\s\S]{0,400}?)\n\n', combined, re.IGNORECASE)
        if m:
            out["Special_Instructions"] = re.sub(r'\s{2,}', ' ', m.group(1)).replace('\n', ' ').strip()
        else:
            # fallback capture shorter block
            v = find_label_value(combined, [r'SPECIAL INSTRUCTIONS/NOTES', r'SPECIAL INSTRUCTIONS', r'NOTES'], look_next_lines=4)
            out["Special_Instructions"] = v

    # 9) table fallback: check pdfplumber tables for header-like key-value if still missing
    if (not out["PO_No"] or not out["Vendor_No"] or not out["Issue_Date"]) and tables:
        # flatten all table text and search
        for tbl in tables:
            for row in tbl:
                row_text = " ".join([c for c in (row or []) if c])
                if not out["PO_No"]:
                    m = re.search(r'\bPO\s*#\s*([0-9A-Za-z\-]{6,10})', row_text, re.IGNORECASE)
                    if m:
                        out["PO_No"] = m.group(1)
                if not out["Vendor_No"]:
                    m = re.search(r'VENDOR\s*NO[:\s]*([0-9A-Za-z\-]{4,10})', row_text, re.IGNORECASE)
                    if m:
                        out["Vendor_No"] = m.group(1)
                if not out["Issue_Date"]:
                    m = re.search(r'ISSUE\s*DATE[:\s]*([0-9\/\-\., ]{6,30})', row_text, re.IGNORECASE)
                    if m:
                        out["Issue_Date"] = normalize_date_token(m.group(1))
    return out


# ---------- table row grouping/parsing (same approach as fixed2) ----------
def find_table_start_index(lines: List[str]) -> int:
    for i, ln in enumerate(lines):
        if re.search(r'\bLINE\b', ln, re.IGNORECASE) and re.search(r'VENDOR\s+ITEM\s+NUMBER', ln, re.IGNORECASE):
            ctx = " ".join(lines[i:i+3]).upper()
            if "DESCRIPTION" in ctx and "LBH ITEM" in ctx:
                return i
    return -1


def group_table_lines_by_pipe(lines: List[str]) -> List[List[str]]:
    groups = []
    current = None
    for ln in lines:
        if re.match(r'^\s*\d{1,4}\s*\|', ln):
            if current:
                groups.append(current)
            current = [ln]
        else:
            if current is not None:
                current.append(ln)
    if current:
        groups.append(current)
    return groups


def parse_group(group: List[str]) -> Dict[str, str]:
    first = group[0]
    parts = [p.strip() for p in first.split('|')]
    line_no = parts[0] if len(parts) > 0 else ""
    vendor_item = parts[1] if len(parts) > 1 else ""
    qty = parts[2] if len(parts) > 2 else ""
    desc_parts = []
    if len(parts) > 3:
        desc_parts.append(parts[3])
    for extra in group[1:]:
        if '|' in extra:
            ex_parts = [p.strip() for p in extra.split('|') if p.strip()]
            # if last two are numeric -> unit/ext; else treat as desc
            if len(ex_parts) >= 2 and re.search(r'\d', ex_parts[-1]):
                if len(ex_parts) > 2:
                    desc_parts.append(" ".join(ex_parts[:-2]))
            else:
                desc_parts.append(" ".join(ex_parts))
        else:
            desc_parts.append(extra.strip())
    desc = " ".join([d for d in desc_parts if d]).strip()
    # LBH item number inside desc (5-8 digits)
    lbh = ""
    m = re.search(r'\b(\d{5,8})\b', desc)
    if m:
        lbh = m.group(1)
        desc = re.sub(r'\b' + re.escape(lbh) + r'\b', '', desc).strip(' ,;:')
    unit = ""
    ext = ""
    for ln in reversed(group):
        nums = re.findall(r'([0-9]+\.[0-9]{2}|[0-9]+(?:\.[0-9]+)?)', ln)
        if len(nums) >= 2:
            unit = numeric_normalize(nums[-2])
            ext = numeric_normalize(nums[-1])
            break
    # detect weights
    mw = ""
    afw = ""
    for ln in group:
        m1 = re.search(r'Metal Weight[:\s]*([0-9\.,]+)g', ln, re.IGNORECASE)
        if m1:
            mw = numeric_normalize(m1.group(1))
        m2 = re.search(r'Average Finished Weight[:\s]*([0-9\.,]+)g', ln, re.IGNORECASE)
        if m2:
            afw = numeric_normalize(m2.group(1))
    return {
        "Line_No": line_no, "Vendor_Item_Number": vendor_item, "Quantity": numeric_normalize(qty),
        "Description": re.sub(r'\s{2,}', ' ', desc), "Unit_Price": unit, "Ext_Amt": ext,
        "LBH_Item_Number": lbh, "Metal_Weight": mw, "Average_Finished_Weight": afw
    }


# ---------- main extraction ----------
def extract_lbh_po(pdf_path: str, output_excel_path: str = None, debug: bool = False) -> str:
    pdf_path = str(pdf_path)
    pdf_name = Path(pdf_path).stem
    if not output_excel_path:
        output_excel_path = fr"D:\RPA\Purchase_Orders_Extracted_{pdf_name}.xlsx"

    pages_text, tables = read_pdf_pages_and_tables(pdf_path)
    combined = "\n\n".join(pages_text)
    lines = combined.splitlines()

    headers = extract_header_blocks(combined, pages_text, tables)

    # find table start
    start_idx = find_table_start_index(lines)
    if start_idx >= 0:
        # collect lines after header until footer
        table_lines = []
        for ln in lines[start_idx + 1:]:
            if re.search(r'Purchase Order Total|TOTAL AMOUNT|SPECIAL INSTRUCTIONS|This purchase order', ln, re.IGNORECASE):
                break
            table_lines.append(ln)
    else:
        # fallback to collecting lines containing '|' or lines starting with digit+space
        table_lines = [ln for ln in lines if '|' in ln or re.match(r'^\s*\d{1,4}\b', ln)]

    groups = group_table_lines_by_pipe(table_lines)
    parsed = [parse_group(g) for g in groups]

    # if no groups found but there are pdfplumber tables, attempt to parse rows from first table
    if not parsed and tables:
        for tbl in tables:
            # try to find header-like row and then parse following rows
            joined = [" | ".join([c if c else "" for c in r]) for r in tbl]
            # try to find row indices after header containing 'LINE' 'VENDOR ITEM NUMBER'
            header_idx = -1
            for i, row_text in enumerate(joined):
                if re.search(r'\bLINE\b', row_text, re.IGNORECASE) and re.search(r'VENDOR', row_text, re.IGNORECASE):
                    header_idx = i
                    break
            if header_idx >= 0:
                for r in joined[header_idx + 1:]:
                    # split by pipe
                    parts = [p.strip() for p in r.split('|') if p.strip()]
                    if not parts:
                        continue
                    # minimal mapping
                    parsed.append({
                        "Line_No": parts[0] if len(parts) > 0 else "",
                        "Vendor_Item_Number": parts[1] if len(parts) > 1 else "",
                        "Quantity": numeric_normalize(parts[2]) if len(parts) > 2 else "",
                        "Description": " ".join(parts[3:-2]) if len(parts) > 5 else (parts[3] if len(parts) > 3 else ""),
                        "Unit_Price": numeric_normalize(parts[-2]) if len(parts) > 1 else "",
                        "Ext_Amt": numeric_normalize(parts[-1]) if len(parts) > 0 else "",
                        "LBH_Item_Number": ""
                    })
                if parsed:
                    break

    final_rows = []
    for it in parsed:
        row = {c: "" for c in OUTPUT_COLUMNS}
        row["PO_No"] = headers.get("PO_No", "")
        row["Vendor_No"] = headers.get("Vendor_No", "")
        row["Vendor"] = headers.get("Vendor", "")
        row["Issue_Date"] = headers.get("Issue_Date", "")
        row["Ship_Date"] = headers.get("Ship_Date", "")
        row["Buyer"] = headers.get("Buyer", "")
        row["Bill_To"] = headers.get("Bill_To", "")
        row["Ship_To"] = headers.get("Ship_To", "")
        row["Total_Amount"] = headers.get("Total_Amount", "")
        row["Special_Instructions"] = headers.get("Special_Instructions", "")
        row["Line_No"] = it.get("Line_No", "")
        row["Vendor_Item_Number"] = it.get("Vendor_Item_Number", "")
        row["LBH_Item_Number"] = it.get("LBH_Item_Number", "")
        row["Quantity"] = it.get("Quantity", "")
        row["Unit_Price"] = it.get("Unit_Price", "")
        row["Ext_Amt"] = it.get("Ext_Amt", "")
        row["Description"] = it.get("Description", "")
        row["Metal_Weight"] = it.get("Metal_Weight", "")
        row["Average_Finished_Weight"] = it.get("Average_Finished_Weight", "")
        final_rows.append(row)

    if not final_rows:
        # emit at least a header-only row
        final_rows.append({
            **{c: "" for c in OUTPUT_COLUMNS},
            "PO_No": headers.get("PO_No", ""), "Vendor_No": headers.get("Vendor_No", ""),
            "Vendor": headers.get("Vendor", ""), "Issue_Date": headers.get("Issue_Date", ""),
            "Ship_Date": headers.get("Ship_Date", "")
        })

    df = pd.DataFrame(final_rows, columns=OUTPUT_COLUMNS)
    out_dir = os.path.dirname(output_excel_path)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)
    df.to_excel(output_excel_path, index=False)

    if debug:
        dbg = {
            "headers": headers,
            "groups_count": len(groups),
            "parsed_sample": parsed[:6],
            "table_lines_preview": table_lines[:12]
        }
        debug_path = str(Path(output_excel_path).with_suffix(".debug.json"))
        with open(debug_path, "w", encoding="utf-8") as f:
            json.dump(dbg, f, indent=2)
        logging.info("Wrote debug JSON: %s", debug_path)

    logging.info("Wrote Excel: %s (rows: %d)", output_excel_path, len(df))
    return output_excel_path


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="LBH PO extractor (fixed3).")
    parser.add_argument("--pdf", required=True, help="Input LBH PDF file.")
    parser.add_argument("--out", required=False, help="Output Excel path.")
    parser.add_argument("--debug", action="store_true", help="Write debug JSON.")
    args = parser.parse_args()
    try:
        out = extract_lbh_po(args.pdf, args.out, debug=args.debug)
        print("Extraction complete:", out)
    except Exception:
        logging.exception("Extraction failed.")
        raise
