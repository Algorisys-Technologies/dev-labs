#!/usr/bin/env python3
"""
fh_po_extractor_v2.py

Updated FH/PH PO extractor with improved PO detection and stronger row grouping.
Run:
    python fh_po_extractor_v2.py --pdf "FH PO COPY - PurchaseOrder-500-48675.pdf" --out fh_out.xlsx --debug
"""
import os, re, json, argparse, logging
from pathlib import Path
from typing import List, Dict, Any
import pdfplumber, pandas as pd
from dateutil import parser as dateparser

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

OUTPUT_COLUMNS = [
    "PO_No", "Customer_No", "Ordered_By", "Order_Date", "Expected_Date",
    "Bill_To", "Ship_To", "Total_Value", "Grand_Total",
    "Line_No", "Our_Ref", "Supplier_Ref", "Article_Code",
    "Metal_Type", "Metal_Weight", "Quantity", "Article_Price", "Total_Value_Line",
    "Description", "Notes"
]

def numeric_normalize(v: Any) -> str:
    if v is None:
        return ""
    s = str(v).strip().replace(',', '').replace('£','').replace('$','')
    m = re.search(r'[-+]?\d*\.?\d+', s)
    return m.group(0) if m else s

def normalize_date(token: str) -> str:
    if not token: return ""
    token = str(token).strip()
    m = re.search(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', token)
    if m:
        try:
            return pd.to_datetime(m.group(1), dayfirst=True).strftime("%Y-%m-%d")
        except Exception:
            pass
    try:
        dt = dateparser.parse(token, fuzzy=True)
        return dt.strftime("%Y-%m-%d")
    except Exception:
        return ""

def read_pdf_pages(pdf_path: str):
    pages_text, tables = [], []
    with pdfplumber.open(pdf_path) as pdf:
        for p in pdf.pages:
            txt = p.extract_text() or ""
            try:
                tbs = p.extract_tables() or []
                for t in tbs:
                    tables.append(t)
                    for row in t:
                        if row and any([c for c in row if c]):
                            txt += "\n" + " | ".join([c if c else "" for c in row])
            except Exception:
                pass
            pages_text.append(txt)
    combined = "\n\n".join(pages_text)
    return combined, pages_text, tables

def find_label_value(combined: str, label_patterns: List[str], look_next: int = 2) -> str:
    lines = combined.splitlines()
    for i, ln in enumerate(lines):
        for pat in label_patterns:
            if re.search(pat, ln, re.IGNORECASE):
                if ':' in ln or '#' in ln or '-' in ln:
                    m = re.search(rf'{pat}.*?[:#\-]\s*(.+)', ln, re.IGNORECASE)
                    if m:
                        return m.group(1).strip()
                    parts = re.split(pat, ln, flags=re.IGNORECASE)
                    if len(parts) > 1 and parts[1].strip():
                        return parts[1].strip()
                for j in range(1, look_next+1):
                    if i+j < len(lines):
                        nxt = lines[i+j].strip()
                        if nxt:
                            return nxt
    return ""

def parse_headers(combined: str, pages_text: List[str], tables: List) -> Dict[str, str]:
    out = {k: "" for k in ["PO_No","Customer_No","Ordered_By","Order_Date","Expected_Date","Bill_To","Ship_To","Total_Value","Grand_Total"]}
    # find hyphenated PO like 500-48675 (prefer)
    hyphen_candidates = re.findall(r'\b\d{2,4}-\d{3,8}\b', combined)
    # prefer candidate that matches typical PO format (3-4 digits hyphen 3-5+ digits) and that appears near 'Purchase Order'
    po_candidate = ""
    if hyphen_candidates:
        # check vicinity of "Purchase Order" for a hyphen candidate
        for c in hyphen_candidates:
            pos = combined.find(c)
            if pos >= 0:
                # look 200 chars around the candidate for the "Purchase Order" anchor
                window = combined[max(0,pos-200):pos+200].lower()
                if "purchase order" in window or "purchase order no" in window or "purchase order #" in window:
                    po_candidate = c
                    break
        if not po_candidate:
            po_candidate = hyphen_candidates[0]
    # fallback: any 5-9 digit standalone
    if not po_candidate:
        nums = re.findall(r'\b\d{5,9}\b', combined)
        if nums:
            po_candidate = nums[0]
    out["PO_No"] = po_candidate

    # other header fields using label search
    cust = find_label_value(combined, [r'Customer No', r'Customer Number', r'Account No', r'Customer:'])
    if cust:
        m = re.search(r'([A-Z0-9\-\_]+)', cust)
        out["Customer_No"] = m.group(1) if m else cust
    ordered = find_label_value(combined, [r'Ordered By', r'Order By', r'Ordered'], look_next=1)
    if ordered:
        out["Ordered_By"] = re.split(r'\bDate\b[:\s]', ordered, flags=re.IGNORECASE)[0].strip()
    date_raw = find_label_value(combined, [r'\bDate\b', r'Date[:\s]'], look_next=1)
    if date_raw:
        out["Order_Date"] = normalize_date(date_raw)
    expected_raw = find_label_value(combined, [r'Expected', r'Expected Date', r'Expected Delivery'], look_next=1)
    if expected_raw:
        out["Expected_Date"] = normalize_date(expected_raw)

    def find_block(anchor_list):
        lines = combined.splitlines()
        for i, ln in enumerate(lines):
            for a in anchor_list:
                if re.search(a, ln, re.IGNORECASE):
                    blk = []
                    for j in range(i+1, min(i+10, len(lines))):
                        nxt = lines[j].strip()
                        if not nxt: break
                        if re.search(r'^(Our Ref|Supplier|Metal Type|Description|Quantity|Total|Purchase Order)', nxt, re.IGNORECASE):
                            break
                        blk.append(nxt)
                    return ", ".join(blk)
        return ""
    out["Bill_To"] = find_block([r'Bill to', r'Bill To', r'Bill:'])
    out["Ship_To"] = find_block([r'Ship to', r'Ship To', r'Ship:'])

    total_raw = find_label_value(combined, [r'Total Value', r'Net Total', r'Grand Total', r'Total Amount'], look_next=1)
    if total_raw:
        m = re.search(r'([0-9\.,]+)', total_raw)
        if m:
            out["Total_Value"] = numeric_normalize(m.group(1))
    grand_raw = find_label_value(combined, [r'Grand Total', r'Total Due', r'Balance Due'], look_next=1)
    if grand_raw:
        m = re.search(r'([0-9\.,]+)', grand_raw)
        if m:
            out["Grand_Total"] = numeric_normalize(m.group(1))

    # table fallback using pdfplumber tables if missing
    if tables and not out["PO_No"]:
        flat = "\n".join([" | ".join([c if c else "" for row in t for c in row]) for t in tables])
        m = re.search(r'\bPO\s*#\s*([0-9A-Z\-\_]{4,})', flat, re.IGNORECASE)
        if m:
            out["PO_No"] = m.group(1)
    return out

def find_table_start(lines: List[str]) -> int:
    header_tokens = ['Our Ref', "Supplier's Ref", 'Article', 'Metal Type', 'Description', 'Metal Weight', 'Quantity', 'Qty', 'Article Price', 'Total Value', 'Total']
    for i, ln in enumerate(lines):
        hits = sum(1 for t in header_tokens if re.search(re.escape(t), ln, re.IGNORECASE))
        if hits >= 2:
            return i
    for i, ln in enumerate(lines):
        if re.search(r'\bArticle\b', ln, re.IGNORECASE) and re.search(r'\bQty\b|\bQuantity\b', ln, re.IGNORECASE):
            return i
    return -1

def group_table_lines(table_lines: List[str]) -> List[List[str]]:
    groups = []
    if any('|' in ln for ln in table_lines):
        cur = None
        for ln in table_lines:
            if re.match(r'^\s*\d+\s*\|', ln):
                if cur: groups.append(cur)
                cur = [ln]
                continue
            if cur is not None:
                cur.append(ln)
        if cur: groups.append(cur)
        return groups
    else:
        cur = None
        for ln in table_lines:
            if re.match(r'^\s*\d+\b', ln) or re.search(r'\bOur Ref\b|\bArticle\b|\b\d{2,4}-\d{3,8}\b', ln, re.IGNORECASE):
                if cur: groups.append(cur)
                cur = [ln]
            else:
                if cur is not None: cur.append(ln)
        if cur: groups.append(cur)
        return groups

def parse_group_to_row(group: List[str]) -> Dict[str,str]:
    joined = " ".join([g.strip() for g in group if g and g.strip()])
    txt = re.sub(r'\s{2,}', ' ', joined).strip()
    nums = re.findall(r'([0-9]+\.[0-9]{2}|[0-9]+(?:\.[0-9]+)?)', txt)
    unit_price = numeric_normalize(nums[-2]) if len(nums) >= 2 else ""
    ext_amt = numeric_normalize(nums[-1]) if len(nums) >= 1 else ""
    qty = ""
    m_qty = re.search(r'\bQty[:\s]*([0-9]+(?:\.[0-9]+)?)\b', txt, re.IGNORECASE)
    if m_qty:
        qty = numeric_normalize(m_qty.group(1))
    else:
        for n in re.findall(r'\b([0-9]+(?:\.[0-9]+)?)\b', txt):
            try:
                if float(n) <= 1000:
                    qty = numeric_normalize(n)
                    break
            except:
                continue
    our_ref = ""
    supplier_ref = ""
    article_code = ""
    tokens = re.split(r'\s+', txt)
    if tokens:
        t0 = re.sub(r'[^A-Za-z0-9\-\/]', '', tokens[0])
        if re.match(r'^[A-Z0-9\-\/]{2,}$', t0, re.IGNORECASE):
            our_ref = t0
    if len(tokens) >= 2:
        t1 = re.sub(r'[^A-Za-z0-9\-\/]', '', tokens[1])
        if re.match(r'^[A-Z0-9\-\/]{2,}$', t1, re.IGNORECASE):
            supplier_ref = t1
    m_art = re.search(r'\b(\d{2,4}-\d{3,8}\b|\d{5,9}\b|[A-Z0-9]{3,}\-?[A-Z0-9]{0,})', txt)
    if m_art:
        article_code = m_art.group(1)
    metal = ""
    m_metal = re.search(r'\b(18CT|18ct|WHITE GOLD|YELLOW GOLD|YG|WG|PLATINUM|PLAT)\b', txt, re.IGNORECASE)
    if m_metal:
        metal = m_metal.group(0).upper()
    metal_weight = ""
    m_w = re.search(r'([0-9]+\.[0-9]+)\s*g\b', txt, re.IGNORECASE)
    if m_w:
        metal_weight = numeric_normalize(m_w.group(1))
    desc = txt
    if unit_price and ext_amt:
        desc = re.sub(re.escape(unit_price) + r'\s*' + re.escape(ext_amt) + r'\s*$', '', desc)
    if article_code:
        desc = re.sub(re.escape(article_code), '', desc, count=1)
    if our_ref:
        desc = re.sub(r'^\s*' + re.escape(our_ref), '', desc, count=1)
    desc = re.sub(r'\bQty[:\s]*[0-9]+(?:\.[0-9]+)?\b', '', desc, flags=re.IGNORECASE).strip(' ,|')
    return {"Our_Ref": our_ref, "Supplier_Ref": supplier_ref, "Article_Code": article_code,
            "Quantity": qty, "Article_Price": unit_price, "Total_Value_Line": ext_amt,
            "Description": re.sub(r'\s{2,}', ' ', desc).strip(), "Metal_Type": metal, "Metal_Weight": metal_weight}

def extract_fh_po(pdf_path: str, output_excel_path: str = None, debug: bool = False) -> str:
    pdf_path = str(pdf_path)
    pdf_name = Path(pdf_path).stem
    if not output_excel_path:
        output_excel_path = fr"D:\RPA\Purchase_Orders_Extracted_{pdf_name}.xlsx"
    combined, pages_text, tables = read_pdf_pages(pdf_path)
    if debug:
        dbg_dir = Path(output_excel_path).with_suffix("")
        dbg_dir = Path(dbg_dir.parent) / f"{pdf_name}_debug"
        dbg_dir.mkdir(parents=True, exist_ok=True)
        (dbg_dir / "combined_text.txt").write_text(combined, encoding="utf-8")
    headers = parse_headers(combined, pages_text, tables)
    lines = combined.splitlines()
    header_idx = find_table_start(lines)
    table_lines = []
    if header_idx >= 0:
        for ln in lines[header_idx+1:]:
            if re.search(r'Grand Total|Total Value|VAT|Carriage|Total Amount|Purchase Order Total', ln, re.IGNORECASE):
                break
            table_lines.append(ln)
    if len(table_lines) < 1:
        # fallback: take lines from first page that contain numeric prices/Article keywords
        page_chunks = combined.split("\n\n")
        for ptxt in page_chunks[:2]:
            for ln in ptxt.splitlines():
                if re.search(r'\d+\.\d{2}', ln) or re.search(r'\bArticle\b|\bQty\b|\bQuantity\b', ln, re.IGNORECASE):
                    table_lines.append(ln)
    # strip blanks
    table_lines = [ln for ln in table_lines if ln.strip()]
    # fallback to pdfplumber tables if still empty
    if not table_lines and tables:
        for t in tables:
            for row in t:
                if row and any(c for c in row if c):
                    table_lines.append(" | ".join([c if c else "" for c in row]))
    groups = group_table_lines(table_lines)
    parsed_rows = [parse_group_to_row(g) for g in groups] if groups else []
    if not parsed_rows and table_lines:
        parsed_rows = [parse_group_to_row([ln]) for ln in table_lines]
    final_rows = []
    for idx, pr in enumerate(parsed_rows, start=1):
        row = {c: "" for c in OUTPUT_COLUMNS}
        row["PO_No"] = headers.get("PO_No","")
        row["Customer_No"] = headers.get("Customer_No","")
        row["Ordered_By"] = headers.get("Ordered_By","")
        row["Order_Date"] = headers.get("Order_Date","")
        row["Expected_Date"] = headers.get("Expected_Date","")
        row["Bill_To"] = headers.get("Bill_To","")
        row["Ship_To"] = headers.get("Ship_To","")
        row["Total_Value"] = headers.get("Total_Value","")
        row["Grand_Total"] = headers.get("Grand_Total","")
        row["Line_No"] = str(idx).zfill(4)
        row["Our_Ref"] = pr.get("Our_Ref","")
        row["Supplier_Ref"] = pr.get("Supplier_Ref","")
        row["Article_Code"] = pr.get("Article_Code","")
        row["Metal_Type"] = pr.get("Metal_Type","")
        row["Metal_Weight"] = pr.get("Metal_Weight","")
        row["Quantity"] = pr.get("Quantity","")
        row["Article_Price"] = pr.get("Article_Price","")
        row["Total_Value_Line"] = pr.get("Total_Value_Line","")
        row["Description"] = pr.get("Description","")
        final_rows.append(row)
    final_rows.pop()  # remove last row which is often garbage
    if not final_rows:
        row = {c: "" for c in OUTPUT_COLUMNS}
        row["PO_No"] = headers.get("PO_No","")
        final_rows.append(row)
    df = pd.DataFrame(final_rows, columns=OUTPUT_COLUMNS)
    out_dir = os.path.dirname(output_excel_path)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)
    df.to_excel(output_excel_path, index=False)
    if debug:
        dbg = {"headers": headers, "table_start_idx": header_idx, "table_lines_sample": table_lines[:30],
               "groups_count": len(groups) if groups else 0, "parsed_rows_sample": parsed_rows[:10]}
        dbg_path = str(Path(output_excel_path).with_suffix(".debug.json"))
        with open(dbg_path, "w", encoding="utf-8") as f:
            json.dump(dbg, f, indent=2)
    logging.info("Wrote Excel: %s (rows: %d)", output_excel_path, len(df))
    return output_excel_path

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="FH/PH PO extractor v2")
    parser.add_argument("--pdf", required=True)
    parser.add_argument("--out", required=False)
    parser.add_argument("--debug", action="store_true")
    args = parser.parse_args()
    try:
        out = extract_fh_po(args.pdf, args.out, debug=args.debug)
        print("Extraction complete:", out)
    except Exception:
        logging.exception("Extraction failed.")
        raise
