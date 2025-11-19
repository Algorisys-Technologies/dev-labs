#!/usr/bin/env python3
"""
bpo_po_extractor_strict_single.py

Stricter BPO extractor that returns a single high-confidence item row (if present).
Follows the exact function signature and CLI style used in other extractors.

Usage:
    python bpo_po_extractor_strict_single.py --pdf INPUT.pdf [--out OUTPUT.xlsx] [--debug]
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

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

OUTPUT_COLUMNS = [
    "PO_No", "Buyer", "Vendor", "PO_Header_ExFactoryDate",
    "Subtotal", "GST", "Total_Units", "Total_USD",
    "Line_No", "Style_Code", "SKU", "Description", "Line_ExFactoryDate",
    "Quantity", "Weight", "Unit_Price", "Discount", "Amount"
]


# ---------- helpers ----------
def numeric_normalize(v: Any) -> str:
    if v is None:
        return ''
    s = str(v).strip().replace(',', '').replace('£', '').replace('$', '')
    m = re.search(r'[-+]?\d*\.?\d+', s)
    return m.group(0) if m else ''


def to_float_safe(v: Any) -> float:
    if v is None:
        return float('nan')
    s = str(v).strip().replace(',', '').replace('£','').replace('$','')
    if s == '':
        return float('nan')
    if '%' in s:
        try:
            return float(s.replace('%','').strip()) / 100.0
        except:
            return float('nan')
    try:
        return float(re.search(r'[-+]?\d*\.?\d+', s).group(0))
    except:
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
            except:
                pass
    return ''


def read_pdf_text(pdf_path: str) -> Tuple[str, List[str], List]:
    pages = []
    tables = []
    with pdfplumber.open(pdf_path) as pdf:
        for p in pdf.pages:
            page_text = p.extract_text() or ''
            try:
                for t in (p.extract_tables() or []):
                    tables.append(t)
                    for row in t:
                        if row and any(c for c in row if c):
                            page_text += "\n" + " | ".join([c if c else "" for c in row])
            except Exception:
                pass
            pages.append(page_text)
    combined = "\n\n".join(pages)
    return combined, pages, tables


# ---------- header parsing ----------
def parse_headers(combined_text: str, pages_text: List[str], tables: List) -> Dict[str, str]:
    out = {k: "" for k in ["PO_No", "Buyer", "Vendor", "PO_Header_ExFactoryDate", "Subtotal", "GST", "Total_Units", "Total_USD"]}

    # PO No
    m = re.search(r'Purchase\s+Order\s*(?:No|#|number)?\s*[:\-]?\s*([A-Z0-9\-\_]{3,})', combined_text, re.IGNORECASE)
    if m:
        out["PO_No"] = m.group(1).strip()
    else:
        m2 = re.search(r'\b(BPO[0-9\-]{3,})\b', combined_text, re.IGNORECASE)
        if m2:
            out["PO_No"] = m2.group(1)
        else:
            m3 = re.search(r'\b\d{2,4}-\d{3,8}\b', combined_text)
            if m3:
                out["PO_No"] = m3.group(0)

    # Buyer (naive first non-label line)
    lines = combined_text.splitlines()
    for ln in lines[:12]:
        if ln.strip() and not re.search(r'purchase|order|invoice|phone|tel|fax|style|sku|address', ln, re.IGNORECASE):
            out["Buyer"] = ln.strip()
            break

    # Vendor block
    pre_po = combined_text.split("Purchase Order")[0] if "Purchase Order" in combined_text else combined_text[:1000]
    vlines = [l.strip() for l in pre_po.splitlines() if l.strip()]
    if vlines:
        out["Vendor"] = ", ".join(vlines[-4:])

    # Ex factory
    m = re.search(r'Ex\.?\s*Factory\s*date\s*[:\-]?\s*([A-Za-z0-9\/\-\., ]{4,40})', combined_text, re.IGNORECASE)
    if m:
        out["PO_Header_ExFactoryDate"] = normalize_date_iso(m.group(1).strip())

    # Totals
    m = re.search(r'SUBTOTAL\s+([0-9\.,]+)', combined_text, re.IGNORECASE)
    if m:
        out["Subtotal"] = numeric_normalize(m.group(1))
    m = re.search(r'GST\s+([0-9\.,]+)', combined_text, re.IGNORECASE)
    if m:
        out["GST"] = numeric_normalize(m.group(1))
    m = re.search(r'TOTAL\s+UNITS\s+([0-9\.,]+)', combined_text, re.IGNORECASE)
    if m:
        out["Total_Units"] = numeric_normalize(m.group(1))
    m = re.search(r'USD\s*TOTAL\s*\$?\s*([0-9\.,]+)', combined_text, re.IGNORECASE)
    if m:
        out["Total_USD"] = numeric_normalize(m.group(1))
    else:
        m2 = re.search(r'\bTOTAL\b[^\d\n]*([0-9\.,]+)', combined_text, re.IGNORECASE)
        if m2:
            out["Total_USD"] = numeric_normalize(m2.group(1))

    return out


# ---------- strict and loose parsing ----------
STRICT_LINE_RE = re.compile(
    r'^\s*(?P<style>[A-Z0-9\-\./]{3,})\s{2,}(?P<sku>[A-Z0-9\.\-\/]{3,})\s{2,}(?P<desc>.+?)\s{2,}(?P<exdate>\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})?\s{2,}(?P<qty>[0-9]+(?:\.[0-9]+)?)\s{2,}(?P<weight>[0-9]+\.[0-9]+)?\s{2,}(?P<unit>[0-9]+\.[0-9]{2})\s{2,}(?P<discount>[0-9]+\%?|[0-9]+\.[0-9]{2})\s{2,}(?P<amount>[0-9]+\.[0-9]{2})\s*$',
    re.IGNORECASE | re.MULTILINE
)


def parse_items_strict(combined_text: str) -> List[Dict[str, Any]]:
    items = []
    for m in STRICT_LINE_RE.finditer(combined_text):
        it = {
            "Style_Code": (m.group('style') or '').strip(),
            "SKU": (m.group('sku') or '').strip(),
            "Description": (m.group('desc') or '').strip(),
            "Line_ExFactoryDate": normalize_date_iso(m.group('exdate') or ''),
            "Quantity": numeric_normalize(m.group('qty') or ''),
            "Weight": numeric_normalize(m.group('weight') or ''),
            "Unit_Price": numeric_normalize(m.group('unit') or ''),
            "Discount": (m.group('discount') or '').strip(),
            "Amount": numeric_normalize(m.group('amount') or ''),
            "match_span": (m.start(), m.end())
        }
        items.append(it)
    return items


def parse_items_loose(combined_text: str) -> List[Dict[str, Any]]:
    items = []
    # split into candidate blocks using double newlines and lines with price patterns
    blocks = re.split(r'\n{1,3}', combined_text)
    for blk in blocks:
        if not blk.strip():
            continue
        # only consider block that contains a price-like token AND at least one numeric token that could be qty
        if not (re.search(r'[0-9]+\.[0-9]{2}', blk) and re.search(r'\b[0-9]{1,4}\b', blk)):
            continue
        txt = " ".join([ln.strip() for ln in blk.splitlines() if ln.strip()])
        nums = re.findall(r'([0-9]+\.[0-9]{2}|[0-9]+(?:\.[0-9]+)?)', txt)
        unit = numeric_normalize(nums[-3]) if len(nums) >= 3 else (numeric_normalize(nums[-2]) if len(nums) == 2 else '')
        discount = nums[-2] if len(nums) >= 2 else ''
        amount = numeric_normalize(nums[-1]) if nums else ''
        qty = ''
        for n in re.findall(r'\b([0-9]+(?:\.[0-9]+)?)\b', txt):
            try:
                if float(n) <= 9999:
                    qty = numeric_normalize(n)
                    break
            except:
                continue
        exdate_m = re.search(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', txt)
        exdate = normalize_date_iso(exdate_m.group(1)) if exdate_m else ''
        tokens = re.split(r'\s+', txt)
        style = tokens[0] if tokens else ''
        sku = tokens[1] if len(tokens) > 1 else ''
        # produce description by removing trailing numeric tokens
        if nums:
            # remove the last 3 numeric tokens if present
            tail = r'\s*' + r'\s*'.join([re.escape(n) for n in nums[-3:]]) + r'\s*$' if len(nums) >= 3 else r'\s*$'
            desc = re.sub(tail, '', txt).strip(' ,|')
        else:
            desc = txt
        items.append({
            "Style_Code": style.strip(),
            "SKU": sku.strip(),
            "Description": desc.strip(),
            "Line_ExFactoryDate": exdate,
            "Quantity": qty,
            "Weight": '',
            "Unit_Price": unit,
            "Discount": discount,
            "Amount": amount,
            "match_span": None
        })
    # dedupe simple
    seen = set()
    out = []
    for it in items:
        key = (it.get('Style_Code'), it.get('SKU'), it.get('Quantity'), it.get('Unit_Price'))
        if key in seen:
            continue
        seen.add(key)
        out.append(it)
    return out


# ---------- scoring / filtering ----------
def score_item(it: Dict[str, Any]) -> int:
    """Give points for presence of key tokens. Higher = more confident."""
    score = 0
    if it.get("Quantity"):
        score += 2
    if it.get("Unit_Price"):
        score += 3
    if it.get("Amount"):
        score += 3
    if it.get("Line_ExFactoryDate"):
        score += 1
    if it.get("SKU") and len(it.get("SKU")) >= 3:
        score += 1
    # penalize if description is identical to header noise
    desc = (it.get("Description") or "").lower()
    if len(desc) < 5:
        score -= 1
    return score


def select_best_items(candidates: List[Dict[str, Any]], required_one: bool = True) -> List[Dict[str, Any]]:
    """Filter low-confidence items, dedupe, and pick the single best item (or list if desired)."""
    # compute score for each
    for it in candidates:
        it['_score'] = score_item(it)
        # confidence flag
        it['_has_price_qty'] = bool(it.get("Unit_Price")) and bool(it.get("Quantity"))
    # filter by minimum score threshold (>=3) or must have price+qty
    filtered = [it for it in candidates if (it['_score'] >= 3 or it['_has_price_qty'])]
    # dedupe by tuple
    seen = {}
    unique = []
    for it in filtered:
        key = (it.get("Style_Code",""), it.get("SKU",""), it.get("Quantity",""), it.get("Unit_Price",""))
        if key in seen:
            # keep the one with higher score
            if it['_score'] > seen[key]['_score']:
                seen[key] = it
        else:
            seen[key] = it
    unique = list(seen.values())
    # if none remain and input candidates exist, relax threshold and take top by score
    if not unique and candidates:
        candidates_sorted = sorted(candidates, key=lambda x: x.get('_score', 0), reverse=True)
        # take first
        unique = [candidates_sorted[0]]
    # if we still have multiple, sort by score desc then prefer presence of amount then earliest match_span
    if len(unique) > 1:
        def sort_key(it):
            has_amount = 1 if it.get("Amount") else 0
            span_start = it.get("match_span")[0] if it.get("match_span") else 1e9
            return (-it.get('_score', 0), -has_amount, span_start)
        unique = sorted(unique, key=sort_key)
    # final selection: if required_one True, return only first; else return all unique
    if required_one:
        return [unique[0]] if unique else []
    else:
        return unique


# ---------- main extraction ----------
def extract_bpo_data(pdf_path: str, output_excel_path: str = None, debug: bool = False) -> str:
    pdf_path = str(pdf_path)
    pdf_name = Path(pdf_path).stem
    if not output_excel_path:
        output_excel_path = fr"D:\RPA\Purchase_Orders_Extracted_{pdf_name}.xlsx"

    logging.info("Reading PDF text...")
    combined_text, pages_text, tables = read_pdf_text(pdf_path)

    if debug:
        dbg_dir = Path(output_excel_path).with_suffix("")
        dbg_dir = Path(dbg_dir.parent) / f"{pdf_name}_debug"
        dbg_dir.mkdir(parents=True, exist_ok=True)
        (dbg_dir / "combined_text.txt").write_text(combined_text, encoding="utf-8")
        logging.info("Wrote debug combined_text.txt")

    logging.info("Parsing headers...")
    headers = parse_headers(combined_text, pages_text, tables)
    logging.info(f"Headers parsed: PO_No={headers.get('PO_No')}")

    # strict parse first
    logging.info("Trying strict item parse...")
    candidates = parse_items_strict(combined_text)
    logging.info(f"Strict parser candidates: {len(candidates)}")
    if not candidates:
        logging.info("Strict parser found 0 items — trying loose parser...")
        candidates = parse_items_loose(combined_text)
        logging.info(f"Loose parser candidates: {len(candidates)}")

    # score + select best single (or none)
    for it in candidates:
        # ensure fields normalized
        for k in ["Quantity","Unit_Price","Amount","Discount","Line_ExFactoryDate"]:
            if k in it:
                it[k] = it[k] if it[k] is not None else ''
    selected = select_best_items(candidates, required_one=True)

    if debug:
        dbg_items_path = Path(output_excel_path).with_suffix(".candidates.json")
        with open(dbg_items_path, "w", encoding="utf-8") as f:
            json.dump({"candidates": candidates, "selected": selected}, f, indent=2)
        logging.info("Wrote debug candidates JSON: %s", dbg_items_path)

    final_rows = []
    if selected:
        chosen = selected[0]
        # compute final amount reliably
        q = to_float_safe(chosen.get("Quantity", ""))
        u = to_float_safe(chosen.get("Unit_Price", ""))
        d_raw = chosen.get("Discount", "")
        # compute discount amount
        if isinstance(d_raw, str) and '%' in d_raw:
            pct = to_float_safe(d_raw)
            d_amt = (q * u * pct) if not (math.isnan(q) or math.isnan(u)) else 0.0
        else:
            d_amt = to_float_safe(d_raw)
            if math.isnan(d_amt):
                d_amt = 0.0
        amt = ""
        if not (math.isnan(q) or math.isnan(u)):
            amt_val = q * u - (d_amt or 0.0)
            try:
                amt = "{:.2f}".format(round(amt_val + 1e-9, 2))
            except:
                amt = numeric_normalize(chosen.get("Amount", ""))
        else:
            amt = numeric_normalize(chosen.get("Amount", ""))
        row = {
            "PO_No": headers.get("PO_No", ""),
            "Buyer": headers.get("Buyer", ""),
            "Vendor": headers.get("Vendor", ""),
            "PO_Header_ExFactoryDate": headers.get("PO_Header_ExFactoryDate", ""),
            "Subtotal": headers.get("Subtotal", ""),
            "GST": headers.get("GST", ""),
            "Total_Units": headers.get("Total_Units", ""),
            "Total_USD": headers.get("Total_USD", ""),
            "Line_No": "0001",
            "Style_Code": chosen.get("Style_Code", ""),
            "SKU": chosen.get("SKU", ""),
            "Description": chosen.get("Description", ""),
            "Line_ExFactoryDate": chosen.get("Line_ExFactoryDate", ""),
            "Quantity": chosen.get("Quantity", ""),
            "Weight": chosen.get("Weight", ""),
            "Unit_Price": chosen.get("Unit_Price", ""),
            "Discount": chosen.get("Discount", ""),
            "Amount": amt
        }
        final_rows.append(row)
    else:
        # no selected rows, emit header-only single row
        row = {c: "" for c in OUTPUT_COLUMNS}
        row["PO_No"] = headers.get("PO_No", "")
        row["Buyer"] = headers.get("Buyer", "")
        row["Vendor"] = headers.get("Vendor", "")
        row["PO_Header_ExFactoryDate"] = headers.get("PO_Header_ExFactoryDate", "")
        final_rows.append(row)

    df = pd.DataFrame(final_rows, columns=OUTPUT_COLUMNS)

    # write excel
    out_dir = os.path.dirname(output_excel_path)
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)
    df.to_excel(output_excel_path, index=False)
    logging.info("Wrote Excel: %s (rows: %d)", output_excel_path, len(df))

    return output_excel_path


# ---------- CLI ----------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract single BPO item from PDF (strict single-record).")
    parser.add_argument("--pdf", required=True, help="Path to the PDF file.")
    parser.add_argument("--out", required=False, help="Optional output Excel path.")
    parser.add_argument("--debug", action="store_true", help="Write debug files (combined text + candidates JSON).")
    args = parser.parse_args()
    try:
        out = extract_bpo_data(args.pdf, args.out, debug=args.debug)
        print("Extraction complete:", out)
    except Exception:
        logging.exception("Extraction failed.")
        raise
