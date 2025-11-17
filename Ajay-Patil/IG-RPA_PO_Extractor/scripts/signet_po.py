#!/usr/bin/env python3
"""
extract_po.py - Updated suffix handling and description-preservation.

Behavior highlights:
 - Description text is never modified; it's used only for suffix detection.
 - Allowed suffixes are defined in ALLOWED_SUFFIXES at the top.
 - Special rule: WG or YG -> suffix 'W' or 'Y' respectively.
"""

import pdfplumber
import re
import pandas as pd
import argparse
import os

# ---------- Config / regexes ----------
# Edit this list to add permitted suffixes.
# Note: include single-letter suffixes (e.g., 'W','Y') and multi-letter (e.g., 'PT').
# The special WG/YG rule is handled separately below.
ALLOWED_SUFFIXES = ["YG", "WG", "PT", "Y", "W", "G", "P"]  # example; edit as needed

# Normalized sets for matching
ALLOWED_SUFFIXES_UPPER = [s.upper() for s in ALLOWED_SUFFIXES]
# Keep a longest-first list for greedy multi-letter matching where appropriate
ALLOWED_SUFFIXES_SORTED = sorted(list(dict.fromkeys(ALLOWED_SUFFIXES_UPPER)), key=lambda x: -len(x))

# Patterns
VENDOR_TOKEN_RE = re.compile(r"^[A-Z]{1,4}-\d{4,6}[A-Z]{0,2}$")
# Support vendor tokens like IGR-40029-025 (1-3 letter prefix)
OLD_FORMAT_RE = re.compile(r"^[A-Z]{1,3}-\d{5}-\d{3}")
NUM_LET_RE = re.compile(r"\b(\d{1,2}\s*[A-Za-z]{1,3})\b")       # e.g., '18W' or '18 W' anywhere
STANDALONE_SUFFIX_RE = re.compile(r"\b([A-Za-z]{1,3})\b")        # candidate words to match against allowed suffixes
LEADING_SUFFIX_FROM_DESC_RE = re.compile(r"^\s*(\d{1,2}\s*[A-Z]{1,2})\b", re.I)
SIZE_RE = re.compile(r"\bSIZE\s*([A-Z0-9]{1,3})\b", re.I)
BLACKLIST_KEYWORDS = [
    "registered", "registered in", "registered number", "registered no",
    "registered office", "registered in england", "registered company",
    "ltd", "company number", "registered no."
]
NUMERIC_MONEY_RE = re.compile(r"([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]+)?|[0-9]+(?:\.[0-9]+)?)")

# ---------- Helpers ----------
def format_date(date_str):
    if not date_str:
        return date_str
    match = re.match(r"(\d{2}/\d{2}/)(\d{4})", date_str)
    if match:
        return f"{match.group(1)}{match.group(2)[-2:]}"
    return date_str

def is_footer_line(text):
    if not text:
        return False
    low = text.lower()
    return any(k in low for k in BLACKLIST_KEYWORDS)

def normalize_money_str(s):
    if not s:
        return s
    return s.replace(",", "").strip()

def find_total_cost_in_text(line):
    if not line:
        return None
    m = re.search(r"total cost[:\s]*([A-Za-z]{0,3})?\s*([0-9,]+(?:\.[0-9]+)?)", line, re.I)
    if m:
        return normalize_money_str(m.group(2))
    m2 = re.search(r"total cost.*?(" + NUMERIC_MONEY_RE.pattern + ")", line, re.I)
    if m2:
        return normalize_money_str(m2.group(1))
    return None

def extract_size_from_cells(cells_or_text):
    if isinstance(cells_or_text, (list, tuple)):
        for c in cells_or_text:
            if not c:
                continue
            m = SIZE_RE.search(c)
            if m:
                return m.group(1).upper()
    else:
        m = SIZE_RE.search(cells_or_text or "")
        if m:
            return m.group(1).upper()
    return ""

def find_sku_in_cells(cells):
    for c in cells:
        if c and re.match(r"^\d{9,}", c):
            return c.strip()
    return None

# ---------- Suffix detection (NEW rules) ----------
def decide_suffix_from_letters(letters):
    """
    Given a letters string (e.g., 'WG', 'YG', 'PT', 'W'), decide the effective suffix
    following rules:
      - If letters endswith 'YG' or 'WG' (case-insensitive) => return 'Y' or 'W' respectively.
      - Else if letters (upper) exactly matches an allowed suffix in ALLOWED_SUFFIXES_UPPER => return that.
      - Else, if first letter is allowed single-letter suffix, return first letter.
      - Otherwise return empty string (no suffix).
    IMPORTANT: This function does not change description text; it only returns a suffix string.
    """
    if not letters:
        return ""
    L = letters.upper()
    # special WG/YG rule: map 'WG' -> 'W', 'YG' -> 'Y'
    if L.endswith("WG"):
        return "W"
    if L.endswith("YG"):
        return "Y"
    # if exact match to an allowed suffix (e.g., 'PT' or 'G' or 'W')
    if L in ALLOWED_SUFFIXES_UPPER:
        return L
    # fallback: if first letter is in allowed single-letter set, return it
    if len(L) >= 1 and L[0] in ALLOWED_SUFFIXES_UPPER:
        return L[0]
    return ""

def parse_vendor_token(token, desc_original=""):
    """
    Parse vendor token and (possibly) find suffix from token or description.
    Returned: (vendor_style, suffix, description_out)
    - **Important**: description_out is the original description (unchanged).
    - If suffix is found in token we remove the matched token suffix portion from the token
      to produce vendor_style. If suffix is found from the description we keep the token intact
      (vendor_style is still token) and do NOT modify description text.
    """
    desc = desc_original or ""
    vendor_style = token or ""
    suffix = ""

    if token:
        tok = token.strip()
        up_tok = tok.upper()

        # 1) Try to get suffix directly from token (greedy longest-first)
        for s in ALLOWED_SUFFIXES_SORTED:
            if up_tok.endswith(s):
                # special mapping for WG/YG: if token ends with WG or YG we map to W/Y
                if s in ("WG", "YG"):
                    suffix = "W" if s == "WG" else "Y"
                else:
                    # s is allowed (could be 'PT' or 'W' etc.)
                    suffix = s
                # vendor_style: remove the entire matched trailing letters (length of s)
                vendor_style = tok[:-len(s)].rstrip() if len(s) < len(tok) else tok
                return vendor_style, suffix, desc  # desc left unchanged

        # 2) Token did not contain allowed suffix — look into description to find candidate
        #    but DO NOT modify description: only detect suffix
        # 2a) Numeric+letters anywhere: e.g., 'FOREVR 18W 0.28CT...'
        if desc:
            for m in NUM_LET_RE.finditer(desc):
                raw = m.group(1)  # '18W' or '18 W' etc.
                letters = re.sub(r"^\d+\s*", "", raw).upper()
                cand = decide_suffix_from_letters(letters)
                if cand:
                    # vendor_style remains original token (no removal) OR if token endswith the numeric+letters? usually not
                    return vendor_style, cand, desc

            # 2b) standalone suffix words anywhere, prefer allowed matches (longest-first by ALLOWED_SUFFIXES_SORTED)
            words = re.findall(r"\b[A-Za-z]{1,3}\b", desc)
            for s in ALLOWED_SUFFIXES_SORTED:
                for w in words:
                    if w.upper() == s:
                        # special WG/YG -> map to W/Y
                        if s in ("WG", "YG"):
                            cand = "W" if s == "WG" else "Y"
                        else:
                            cand = s
                        return vendor_style, cand, desc

    # 3) nothing found: vendor_style remains token (unchanged), suffix empty, desc unchanged
    return vendor_style, "", desc

# ---------- flush helper ----------
def flush_current_po(data, current_po, current_line_items):
    if current_po and current_line_items:
        for item in current_line_items:
            new_item = item.copy()
            new_item.update(current_po)
            data.append(new_item)

# ---------- Main extraction ----------
def extract_po_data(pdf_path, output_excel_path=None):
    pdf_name = os.path.splitext(os.path.basename(pdf_path))[0]
    if not output_excel_path:
        output_excel_path = fr"D:\RPA\Purchase_Orders_Extracted_{pdf_name}.xlsx"

    data = []
    current_po = {}
    current_line_items = []

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text() or ""
            lines = [ln.strip() for ln in text.split('\n') if ln.strip()]

            # --- Parse PO header fields from lines ---
            for line in lines:
                low = line.lower()
                if "po no:" in low:
                    if current_po and current_line_items:
                        flush_current_po(data, current_po, current_line_items)
                        current_line_items = []
                    po_no_m = re.search(r"PO No:\s*(\w+)", line, re.I)
                    status_m = re.search(r"Status:\s*([\w]+)", line, re.I)
                    current_po = {
                        "PO No": po_no_m.group(1) if po_no_m else "",
                        "Status": status_m.group(1) if status_m else "",
                    }
                elif "supplier:" in low:
                    m = re.search(r"Supplier:\s*([A-Za-z0-9\-/ ]+)", line, re.I)
                    if m:
                        current_po["Supplier"] = m.group(1).strip()
                elif "order date:" in low:
                    m = re.search(r"Order Date:\s*([\d/]+)", line, re.I)
                    if m:
                        current_po["Order Date"] = format_date(m.group(1))
                elif "ship date:" in low:
                    m = re.search(r"Ship Date:\s*([\d/]+)", line, re.I)
                    if m:
                        current_po["Ship Date"] = format_date(m.group(1))
                elif "delivery date:" in low:
                    m = re.search(r"Delivery Date:\s*([\d/]+)", line, re.I)
                    if m:
                        current_po["Delivery Date"] = format_date(m.group(1))
                elif "total units:" in low:
                    m = re.search(r"Total Units:\s*(\d+)", line, re.I)
                    if m:
                        current_po["Total Units"] = m.group(1)
                    m_cost_inline = re.search(r"Total Cost:\s*([A-Za-z]{0,3})?\s*([0-9,]+(?:\.[0-9]+)?)", line, re.I)
                    if m_cost_inline:
                        current_po["Total Cost"] = normalize_money_str(m_cost_inline.group(2))
                elif "total cost:" in low:
                    m = re.search(r"Total Cost:\s*([A-Za-z]{0,3})?\s*([0-9,]+(?:\.[0-9]+)?)", line, re.I)
                    if m:
                        current_po["Total Cost"] = normalize_money_str(m.group(2))
                elif "total cost" in low:
                    found = find_total_cost_in_text(line)
                    if found and (("Total Cost" not in current_po) or not current_po.get("Total Cost")):
                        current_po["Total Cost"] = found
                elif "comments:" in low:
                    current_po["Comments"] = line.split("Comments:", 1)[-1].strip()

            # --- Try pdfplumber tables first ---
            used_table = False
            try:
                tables = page.extract_tables() or []
            except Exception:
                tables = []

            for tbl in tables:
                if not tbl or len(tbl) < 2:
                    continue
                last_style = last_suffix = last_desc = ""
                table_has_sku = False
                for row in tbl:
                    cells = [(c.strip() if c else "") for c in row]
                    row_text = " ".join([c for c in cells if c])
                    if not row_text:
                        continue

                    # vendor token detection (first two cells)
                    vendor_token = ""
                    for c in cells[:2]:
                        if c and (OLD_FORMAT_RE.search(c) or VENDOR_TOKEN_RE.search(c)):
                            vendor_token = c.strip()
                            break

                    if vendor_token:
                        tok = vendor_token.split()[0]
                        # desc_candidate is the original description text (unchanged)
                        desc_candidate = cells[1] if len(cells) > 1 else row_text[len(tok):].strip()
                        # parse_vendor_token will NOT modify desc_candidate
                        last_style, last_suffix, last_desc = parse_vendor_token(tok, desc_candidate)
                        # last_desc is the original description (unchanged)
                        continue

                    # SKU detection & append
                    sku_found = find_sku_in_cells(cells)
                    if sku_found:
                        if is_footer_line(row_text):
                            continue
                        non_empty = [c for c in cells if c]
                        qty = non_empty[-2] if len(non_empty) >= 2 else ""
                        unit_cost = non_empty[-1] if len(non_empty) >= 1 else ""
                        size = extract_size_from_cells(cells) or extract_size_from_cells(row_text)
                        current_line_items.append({
                            "Vendor Style": last_style,
                            "Vendor Suffix": last_suffix,
                            "Description": last_desc,
                            "SKU": sku_found,
                            "Size": size,
                            "Quantity": qty,
                            "Unit Cost": unit_cost,
                        })
                        table_has_sku = True

                if table_has_sku:
                    used_table = True
                    break

            # --- Try Camelot if pdfplumber tables not useful ---
            if not used_table:
                try:
                    import camelot
                    camelot_tables = camelot.read_pdf(pdf_path, pages=str(page.page_number), flavor='stream', strip_text='\n')
                except Exception:
                    camelot_tables = []

                for ct in camelot_tables:
                    try:
                        df = ct.df
                    except Exception:
                        continue

                    last_style = last_suffix = last_desc = ""
                    table_has_sku = False
                    for idx in range(len(df)):
                        row = list(df.iloc[idx].fillna("").astype(str))
                        row = [r.strip() for r in row]
                        row_text = " ".join([c for c in row if c])
                        if not row_text:
                            continue

                        vendor_token = ""
                        for c in row[:2]:
                            if c and (OLD_FORMAT_RE.search(c) or VENDOR_TOKEN_RE.search(c)):
                                vendor_token = c.strip()
                                break

                        if vendor_token:
                            tok = vendor_token.split()[0]
                            desc_candidate = row[1] if len(row) > 1 and row[1].strip() else row_text[len(tok):].strip()
                            last_style, last_suffix, last_desc = parse_vendor_token(tok, desc_candidate)
                            continue

                        sku_found = find_sku_in_cells(row)
                        if sku_found:
                            if is_footer_line(row_text):
                                continue
                            non_empty = [c for c in row if c]
                            qty = non_empty[-2] if len(non_empty) >= 2 else ""
                            unit_cost = non_empty[-1] if len(non_empty) >= 1 else ""
                            size = extract_size_from_cells(row) or extract_size_from_cells(row_text)
                            current_line_items.append({
                                "Vendor Style": last_style,
                                "Vendor Suffix": last_suffix,
                                "Description": last_desc,
                                "SKU": sku_found,
                                "Size": size,
                                "Quantity": qty,
                                "Unit Cost": unit_cost,
                            })
                            table_has_sku = True

                    if table_has_sku:
                        used_table = True
                        break

            # --- Fallback: line-by-line parsing (improved) ---
            if not used_table:
                vendor_style = suffix = description = ""
                for line in lines:
                    tokens = line.split()
                    if not tokens:
                        continue
                    first_token = tokens[0]

                    if OLD_FORMAT_RE.match(first_token) or VENDOR_TOKEN_RE.match(first_token):
                        vendor_token = first_token
                        desc = " ".join(tokens[1:]).strip()
                        vendor_style, suffix, description = parse_vendor_token(vendor_token, desc)
                        continue

                    # SKU-like detection
                    m_sku = re.search(r"(\d{9,})", line)
                    if m_sku:
                        if is_footer_line(line):
                            continue
                        sku = m_sku.group(1)
                        parts = re.split(r"\s+", line)
                        qty = parts[-2] if len(parts) > 1 else ""
                        unit_cost = parts[-1] if len(parts) > 1 else ""
                        size = extract_size_from_cells(line)
                        current_line_items.append({
                            "Vendor Style": vendor_style,
                            "Vendor Suffix": suffix,
                            "Description": description,
                            "SKU": sku,
                            "Size": size,
                            "Quantity": qty,
                            "Unit Cost": unit_cost,
                        })
                        continue

        # end pages loop

        # final flush
        flush_current_po(data, current_po, current_line_items)

    # build DataFrame and ensure columns
    df = pd.DataFrame(data)
    expected_columns = [
        "PO No", "Supplier", "Order Date", "Ship Date", "Delivery Date",
        "Total Units", "Total Cost", "Status", "Comments",
        "Vendor Style", "Vendor Suffix", "Description", "SKU", "Size",
        "Quantity", "Unit Cost"
    ]
    for col in expected_columns:
        if col not in df.columns:
            df[col] = ""
    df = df[expected_columns]
    if "Total Cost" in df.columns:
        df["Total Cost"] = df["Total Cost"].astype(str).apply(lambda x: x.replace(",", "") if x and x != "nan" else "")
    df.to_excel(output_excel_path, index=False)
    print(f"Successfully exported {len(df)} records to {output_excel_path}")

# ---------- CLI ----------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract PO data from a PDF file.")
    parser.add_argument("--pdf", required=True, help="Path to the PDF file.")
    parser.add_argument("--out", required=False, help="Optional output Excel path.")
    args = parser.parse_args()
    extract_po_data(args.pdf, args.out)
