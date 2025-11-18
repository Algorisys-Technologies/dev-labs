#!/usr/bin/env python3
"""
chirst_po_extractor_v2.py

Robust CHIRST PO extractor (single-file). Fixed path-suffix bug.

Usage:
    python chirst_po_extractor_v2.py --pdf "/path/to/CHIRST-ORDERS_....pdf" \
        --out "/path/to/out_prefix" --debug

Outputs:
  - <out_prefix>_chirst_extracted.xlsx
  - <out_prefix>_chirst_extracted.csv
  - <out_prefix>_chirst_extracted.json
  - debug folder when --debug

Dependencies:
    pip install pdfplumber pandas python-dateutil openpyxl
"""
import argparse
import json
import logging
import os
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

import pdfplumber
import pandas as pd
from dateutil import parser as dateparser

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

OUTPUT_COLUMNS = [
    "PO_No", "Customer_No", "Ordered_By", "Order_Date", "Expected_Date",
    "Bill_To", "Ship_To", "Total_Value", "Grand_Total",
    "Line_No", "Our_Ref", "Supplier_Ref", "Article_Code",
    "Vend_Article", "EAN", "Metal_Type", "Metal_Weight", "Quantity",
    "Article_Price", "Total_Value_Line", "Description", "Notes"
]


def normalize_euro_number_to_float(s: Optional[str]) -> Optional[float]:
    if not s:
        return None
    s = str(s).strip()
    s = re.sub(r'[^\d\.,\-]', '', s)
    if not s:
        return None
    if '.' in s and ',' in s:
        s = s.replace('.', '').replace(',', '.')
    else:
        s = s.replace(',', '.')
    try:
        return float(s)
    except Exception:
        return None


def numeric_normalize_str(v: Any) -> str:
    if v is None or v == "":
        return ""
    f = normalize_euro_number_to_float(str(v))
    if f is None:
        return str(v).strip()
    return f"{f:.2f}"


def read_pdf_and_tables(pdf_path: str) -> (str, List[str], List):
    pages_text: List[str] = []
    tables: List = []
    with pdfplumber.open(pdf_path) as pdf:
        for p in pdf.pages:
            text = p.extract_text() or ""
            try:
                tbs = p.extract_tables() or []
                for t in tbs:
                    tables.append(t)
                    for row in t:
                        if row and any(c for c in row if c):
                            text += "\n" + " | ".join([c if c else "" for c in row])
            except Exception:
                pass
            pages_text.append(text)
    combined = "\n\n".join(pages_text)
    return combined, pages_text, tables


def find_header_values(combined: str) -> Dict[str, str]:
    out = {k: "" for k in ["PO_No", "Customer_No", "Ordered_By", "Order_Date", "Expected_Date",
                           "Bill_To", "Ship_To", "Total_Value", "Grand_Total"]}
    long_nums = re.findall(r'\b\d{7,12}\b', combined)
    hyphen = re.findall(r'\b\d{2,4}-\d{3,8}\b', combined)
    po = ""
    if long_nums:
        for n in long_nums:
            pos = combined.find(n)
            if pos >= 0 and 'purchase order' in combined[max(0, pos - 200):pos + 200].lower():
                po = n
                break
        if not po:
            po = long_nums[0]
    elif hyphen:
        po = hyphen[0]
    out["PO_No"] = po

    m_date = re.search(r'\b(\d{2}\.\d{2}\.\d{4})\b', combined)
    if m_date:
        out["Order_Date"] = m_date.group(1)
    else:
        lm = re.search(r'(?:PO number/date|Order Date|Date|Order date)[^\n\r]{0,60}', combined, re.IGNORECASE)
        if lm:
            d = re.search(r'\d{1,2}[./-]\d{1,2}[./-]\d{2,4}', lm.group(0))
            if d:
                out["Order_Date"] = d.group(0)

    if "Inter Gold" in combined:
        out["Bill_To"] = "Inter Gold (India) Private Limited"
    else:
        m = re.search(r'Bill to[:\s]*\n?(.{2,120})', combined, re.IGNORECASE)
        if m:
            out["Bill_To"] = m.group(1).strip()

    if "Coop Cooperative" in combined or "Coop" in combined:
        out["Ship_To"] = "Coop Cooperative, Basle"
    else:
        m = re.search(r'Ship to[:\s]*\n?(.{2,120})', combined, re.IGNORECASE)
        if m:
            out["Ship_To"] = m.group(1).strip()

    m_tot = re.search(r'(?:Total Value|Net value|Net Value|Total Amount|Total)\s*[:#]?\s*([0-9\.\,]+)', combined, re.IGNORECASE)
    if m_tot:
        out["Total_Value"] = numeric_normalize_str(m_tot.group(1))
    m_grand = re.search(r'(?:Grand Total|Total Due|Balance Due)\s*[:#]?\s*([0-9\.\,]+)', combined, re.IGNORECASE)
    if m_grand:
        out["Grand_Total"] = numeric_normalize_str(m_grand.group(1))
    return out


def split_items_by_header(combined: str) -> List[Dict[str, Any]]:
    header_re = re.compile(r'(?m)^(?P<item_no>\d{5})\s+(?P<article>[\d\.\d]+)\s+(?P<desc>.+)$')
    matches = list(header_re.finditer(combined))
    blocks = []
    if not matches:
        fallback_re = re.compile(r'(?m)^(?P<item_no>\d{5})\b')
        matches = list(fallback_re.finditer(combined))
        for i, m in enumerate(matches):
            start = m.start()
            end = matches[i+1].start() if i+1 < len(matches) else len(combined)
            blk = combined[start:end]
            art_m = re.search(r'([\d]{1,2}(?:\.\d{3}){1,2})', blk)
            article = art_m.group(1) if art_m else ""
            first_line = blk.splitlines()[0] if blk.splitlines() else ""
            desc = first_line
            blocks.append({"item_no": m.group("item_no"), "article": article, "block": blk, "description": desc})
        return blocks

    for i, mm in enumerate(matches):
        start = mm.start()
        end = matches[i+1].start() if i+1 < len(matches) else len(combined)
        block = combined[start:end]
        blocks.append({
            "item_no": mm.group("item_no"),
            "article": mm.group("article"),
            "description": mm.group("desc").strip(),
            "block": block
        })
    return blocks


def parse_item_block(block: str, header_article: Optional[str] = None) -> Dict[str, Any]:
    item = {
        "item_no": "",
        "article": header_article or "",
        "description": "",
        "vend_article": "",
        "ean": "",
        "quantity": None,
        "unit_price": None,
        "net_value": None,
        "metal_weight": None,
        "metal_type": None,
        "stones": None
    }
    lines = [ln.strip() for ln in block.splitlines() if ln.strip()]
    m_head = re.match(r'^(?P<item_no>\d{5})\s+(?P<article>[\d\.\d]+)\s*(?P<desc>.*)$', lines[0]) if lines else None
    if m_head:
        item["item_no"] = m_head.group("item_no")
        if m_head.group("article"):
            item["article"] = m_head.group("article")
        if m_head.group("desc"):
            item["description"] = m_head.group("desc").strip()

    ean_m = re.search(r'\b(\d{13})\b', block)
    if ean_m:
        item["ean"] = ean_m.group(1)

    vend_m = re.search(r'\b([A-Z]{1,4}[-][\dA-Z\-]{2,30})\b', block)
    if vend_m:
        item["vend_article"] = vend_m.group(1)

    qty_m = re.search(r'(\d+)\s+(?:piece|PCE|Stk|Stk\.)', block, re.IGNORECASE)
    if qty_m:
        try:
            item["quantity"] = int(qty_m.group(1))
        except:
            item["quantity"] = None
    else:
        small_nums = re.findall(r'\b([1-9][0-9]{0,3})\b', block)
        for n in small_nums:
            ni = int(n)
            if 1 <= ni <= 1000:
                item["quantity"] = ni
                break

    for ln in lines:
        if 'USD' in ln.upper():
            nums = re.findall(r'[\d\.\,]+', ln)
            if nums:
                item["unit_price"] = normalize_euro_number_to_float(nums[0])
                if len(nums) >= 2:
                    nv = normalize_euro_number_to_float(nums[-1])
                    item["net_value"] = nv
            break

    if item["net_value"] is None:
        comma_nums = re.findall(r'\b\d{1,4}(?:\.\d{3})*,\d{2}\b', block)
        if comma_nums:
            item["net_value"] = normalize_euro_number_to_float(comma_nums[-1])

    if item["unit_price"] is None:
        usd_m = re.search(r'([\d\.\,]+)\s+USD', block, re.IGNORECASE)
        if usd_m:
            item["unit_price"] = normalize_euro_number_to_float(usd_m.group(1))
        else:
            ppu = re.search(r'Price per Unit[:\s]*([0-9\.,]+)', block, re.IGNORECASE)
            if ppu:
                item["unit_price"] = normalize_euro_number_to_float(ppu.group(1))

    mw = re.search(r'([0-9]+\.[0-9]+)\s*g\b', block, re.IGNORECASE)
    if mw:
        item["metal_weight"] = mw.group(1)

    mt = re.search(r'\b(18K|18KT|18CT|WHITE GOLD|YELLOW GOLD|YG|WG|PLATINUM|PLAT)\b', block, re.IGNORECASE)
    if mt:
        item["metal_type"] = mt.group(0)

    st = re.search(r'Number of stones[:\s]*([0-9]{1,4})', block, re.IGNORECASE)
    if st:
        item["stones"] = int(st.group(1))

    desc_lines = []
    for ln in lines:
        if re.search(r'USD|Price per Unit|Net value|Gross Price|Qty|Quantity|piece|PCE|Stk', ln, re.IGNORECASE):
            continue
        if re.search(r'^\d{13}$', ln):
            continue
        desc_lines.append(ln)
    if desc_lines:
        if desc_lines[0].startswith(item["item_no"]):
            desc_lines[0] = re.sub(r'^\d{5}\s+', '', desc_lines[0])
        item["description"] = " ".join(desc_lines[:6]).strip()

    return item


def build_outputs(pdf_path: str, combined: str, blocks: List[Dict[str, Any]], headers: Dict[str, str],
                  out_prefix: Path, debug: bool = False):
    parsed_items = []
    for b in blocks:
        parsed = parse_item_block(b["block"], header_article=b.get("article"))
        if not parsed.get("item_no"):
            parsed["item_no"] = b.get("item_no", "")
        parsed_items.append(parsed)

    result = {
        "source_file": str(Path(pdf_path).resolve()),
        "po_number": headers.get("PO_No", ""),
        "po_date": headers.get("Order_Date", ""),
        "supplier": headers.get("Bill_To", ""),
        "buyer": headers.get("Ship_To", ""),
        "items_count": len(parsed_items),
        "items": parsed_items
    }

    # Build correct filenames using stem + suffix (avoid with_suffix misuse)
    parent = out_prefix.parent if out_prefix.parent != Path('.') else Path(out_prefix.parent)
    stem = out_prefix.stem
    json_path = parent / f"{stem}_chirst_extracted.json"
    csv_path = parent / f"{stem}_chirst_extracted.csv"
    xlsx_path = parent / f"{stem}_chirst_extracted.xlsx"

    with json_path.open("w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)

    rows = []
    for idx, it in enumerate(parsed_items, start=1):
        r = {c: "" for c in OUTPUT_COLUMNS}
        r["PO_No"] = headers.get("PO_No", "")
        r["Customer_No"] = headers.get("Customer_No", "")
        r["Ordered_By"] = headers.get("Ordered_By", "")
        r["Order_Date"] = headers.get("Order_Date", "")
        r["Expected_Date"] = headers.get("Expected_Date", "")
        r["Bill_To"] = headers.get("Bill_To", "")
        r["Ship_To"] = headers.get("Ship_To", "")
        r["Total_Value"] = headers.get("Total_Value", "")
        r["Grand_Total"] = headers.get("Grand_Total", "")
        r["Line_No"] = it.get("item_no") or str(idx).zfill(4)
        r["Our_Ref"] = ""
        r["Supplier_Ref"] = ""
        r["Article_Code"] = it.get("article", "")
        r["Vend_Article"] = it.get("vend_article", "")
        r["EAN"] = it.get("ean", "")
        r["Metal_Type"] = it.get("metal_type") or ""
        r["Metal_Weight"] = it.get("metal_weight") or ""
        r["Quantity"] = it.get("quantity") or ""
        r["Article_Price"] = numeric_normalize_str(it.get("unit_price"))
        r["Total_Value_Line"] = numeric_normalize_str(it.get("net_value"))
        r["Description"] = it.get("description", "")
        r["Notes"] = "" if it.get("stones") is None else f"stones={it.get('stones')}"
        rows.append(r)

    df = pd.DataFrame(rows, columns=OUTPUT_COLUMNS)
    df.to_csv(csv_path, index=False, encoding="utf-8")
    df.to_excel(xlsx_path, index=False)

    if debug:
        dbg_dir = parent / f"{stem}_chirst_debug"
        dbg_dir.mkdir(parents=True, exist_ok=True)
        (dbg_dir / "combined_text.txt").write_text(combined, encoding="utf-8")
        dbg = {
            "headers": headers,
            "items_count_found": len(parsed_items),
            "sample_parsed_items": parsed_items[:10]
        }
        (dbg_dir / "extraction.debug.json").write_text(json.dumps(dbg, indent=2), encoding="utf-8")
        logging.info("Wrote debug files to: %s", str(dbg_dir))

    logging.info("Wrote JSON: %s", str(json_path))
    logging.info("Wrote CSV: %s", str(csv_path))
    logging.info("Wrote Excel: %s (rows: %d)", str(xlsx_path), len(df))


def extract_chirst_po_cli(pdf_path: str, out_path: Optional[str] = None, debug: bool = False) -> Path:
    pdfp = Path(pdf_path)
    if not pdfp.exists():
        raise FileNotFoundError(f"PDF not found: {pdf_path}")
    combined, pages_text, tables = read_pdf_and_tables(str(pdfp))
    headers = find_header_values(combined)
    blocks = split_items_by_header(combined)

    if not blocks and tables:
        blocks = []
        for t in tables:
            for row in t:
                row_text = " | ".join([c if c else "" for c in row])
                m = re.match(r'^\s*(\d{5})\s+([\d\.\,]+)\s*(.*)$', row_text)
                item_no = m.group(1) if m else ""
                article = m.group(2) if m else ""
                blocks.append({"item_no": item_no, "article": article, "description": "", "block": row_text})

    if out_path:
        out_prefix = Path(out_path)
        # if out_path has an extension (file), remove it to form prefix
        if out_prefix.suffix:
            out_prefix = out_prefix.with_suffix('')
    else:
        out_prefix = pdfp.with_name(pdfp.stem)

    build_outputs(str(pdfp), combined, blocks, headers, out_prefix, debug=debug)
    return out_prefix


def main():
    parser = argparse.ArgumentParser(description="CHIRST PO extractor v2")
    parser.add_argument("--pdf", required=True, help="Path to CHIRST PDF file")
    parser.add_argument("--out", required=False, help="Output file prefix or full path (optional). If omitted, uses PDF stem in same folder")
    parser.add_argument("--debug", action="store_true", help="Write debug outputs")
    args = parser.parse_args()

    try:
        outpref = extract_chirst_po_cli(args.pdf, args.out, debug=args.debug)
        print("Extraction finished. Outputs written using prefix:", outpref)
    except Exception as e:
        logging.exception("Extraction failed: %s", e)
        raise


if __name__ == "__main__":
    main()
