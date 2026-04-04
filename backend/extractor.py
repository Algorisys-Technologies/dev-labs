import re
import json

def denoise_text(text):
    """
    Standardizes whitespace and removes markdown noise without breaking IDs.
    """
    # Remove markdown bolding (asterisks) but keep content
    text = re.sub(r'\*+', '', text)
    return text

def extract_po_details(raw_text):
    data = {
        "po_number": "UNKNOWN",
        "date": None,
        "item_name": "N/A",
        "quantity": 0,
        "location": "N/A",
        "supplier": "N/A",
        "amount": "N/A",
        "payment_terms": "N/A",
        "priority": "Normal",
        "all_items": []
    }
    
    clean_text = denoise_text(raw_text)
    lines = [line.strip() for line in clean_text.split('\n') if line.strip()]
    normalized_body = "\n".join(lines)

    # 1. UNIVERSAL PO PATTERN (v13)
    po_patterns = [
        r"(?:Order\s*Ref|Ref|Order\s*No|Order\s*No\.|No|P\.O\.\s*No)\s*[:#-]?\s*\b([A-Z0-9-]{4,})\b",
        r"(?:Purchase Order No|PO Number|PO\s*No|PO\s*#)\s*[:#-]?\s*\b([A-Z0-9-]{4,})\b",
        r"\b(DIST-[A-Z0-9-]+)\b",
        r"\b(DIS-EV-[A-Z0-9-]+)\b",
        r"\b(PO-[A-Z0-9-]{4,})\b"
    ]
    for pattern in po_patterns:
        match = re.search(pattern, normalized_body, re.IGNORECASE)
        if match:
            found = match.group(1).strip()
            if re.match(r"^\d{1,2}/\d{1,2}/\d{2,4}$", found) or found.lower() in ["dear", "date", "pune", "confirmed"]:
                continue
            data["po_number"] = found
            break

    # 2. ERP SIGNAL MAPPING
    supplier_match = re.search(r"(?:Supplier|Vendor|Bill to|Billing Address|From|Zenith Trading)\s*[:#-]?\s*([^\n,]{3,100})", normalized_body, re.IGNORECASE)
    if supplier_match:
        data["supplier"] = supplier_match.group(1).strip()
    elif "Zenith Trading" in raw_text:
        data["supplier"] = "Zenith Trading Co."
        
    amount_match = re.search(r"(?:Amount|Total|Total Amount|Value|Base Amount|Payment)\s*[:#-]?\s*([₹\$\w\d\s.,/]{3,30})", normalized_body, re.IGNORECASE)
    if amount_match:
        data["amount"] = amount_match.group(1).strip().replace('\n', ' ')

    terms_match = re.search(r"(?:Payment Terms|Payment|Terms)\s*[:#-]?\s*([^\n]{3,60})", normalized_body, re.IGNORECASE)
    if terms_match:
        data["payment_terms"] = terms_match.group(1).strip()

    # 3. DATE
    date_match = re.search(r"(?:Date|Order Date)\s*[:#-]?\s*([\d\w\s/-]{6,20})", normalized_body, re.IGNORECASE)
    if date_match:
        data["date"] = date_match.group(1).strip().split('\n')[0]

    # 4. LOCATION (Anchor-Search)
    loc_header_match = re.search(r"(?:Shipping Address|Ship to|Delivery Address|Address|Warehouse|Hub|Distribution Point|Location)\s*[:#-]?\s*(.*)", normalized_body, re.IGNORECASE)
    if loc_header_match:
        loc = loc_header_match.group(1).strip()
        loc = re.split(r'---|\n|Regards|Line Items|Item|Product|Description|📦|📅', loc)[0].strip()
        data["location"] = loc.replace('\n', ', ').strip()
    
    if data["location"] == "N/A" or data["location"] == "":
        city_match = re.search(r"(.*? (?:Pune|Mumbai|MIDC|Industrial|Warehouse|Nagpur|Chennai|Guindy|Nashik).*?)(?:\n|$)", normalized_body, re.IGNORECASE)
        if city_match:
            data["location"] = city_match.group(1).strip()

    # 5. DEEP-LABEL PROPERTY BUFFER (v13)
    raw_items = []
    current_item = {}
    
    # Common labels to strip from data values
    LABEL_LABELS = r"Product Name|Product ID|Part ID|Quantity|Item Name|Item|Description|Name"

    for line in lines:
        # Skip metadata lines
        if re.search(r"Subject|Dear|Regarding|Order Date:|Ref:|P.O. No|PO Number:|^Best regards", line, re.IGNORECASE):
            continue

        # v13 SPECIALIST: Handle "Label: Value" within bullet points
        # If line is "*Product Name:* POS Terminal", capture "POS Terminal"
        label_prop_match = re.search(fr"^\s*-\s*({LABEL_LABELS})\s*[:–#-]?\s*(.*)", line, re.IGNORECASE)
        if label_prop_match:
            label_type = label_prop_match.group(1).lower()
            val = label_prop_match.group(2).strip()
            
            # If it's a "Name" label, start a new item or set name
            if any(x in label_type for x in ["product name", "item name", "description", "name"]):
                if "name" in current_item:
                    raw_items.append(current_item)
                current_item = {"name": val}
            # If it's a "Quantity" label, set qty
            elif "quantity" in label_type or "qty" in label_type:
                qty_match = re.search(r"(\d+)", val)
                if qty_match:
                    current_item["qty"] = int(qty_match.group(1))
            continue

        # Pattern A: Number BEFORE units (e.g. 9000 units of Packaged Water)
        pre_qty_match = re.search(r"(\d+)\s*(?:units|qty|pkts|pcs|items|mounts|packs)\s*(?:of)?\s*(.*?)(?:\s*[–\-\|]|\(|\n|$)", line, re.IGNORECASE)
        # Pattern B: Number AFTER units (e.g. Snack Packs – 7500 units)
        post_qty_match = re.search(r"(.*?)\s*[–\-\|]?\s*(\d+)\s*(?:units|qty|pkts|pcs|items|mounts|packs)", line, re.IGNORECASE)
        
        # Pattern C: Fallback Scraper for loose lines
        qty_solo = re.search(r"(?:Quantity|Qty|Units|Amount)\s*[:–#-]?\s*(\d+)", line, re.IGNORECASE)
        name_solo = re.search(fr"(?:Goods Name|Item|Product|Description|^-\s*)(.*)", line, re.IGNORECASE)

        if pre_qty_match:
            qty = int(pre_qty_match.group(1))
            name = pre_qty_match.group(2).strip().strip('"').strip('- ')
            # Strip labels if they were accidentally captured
            name = re.sub(fr"({LABEL_LABELS})\s*[:–#-]?\s*", "", name, flags=re.IGNORECASE).strip()
            if len(name) > 2:
                raw_items.append({"name": name, "qty": qty})
                continue
        
        if post_qty_match:
            name = post_qty_match.group(1).replace('-', '').strip()
            name = re.sub(fr"({LABEL_LABELS})\s*[:–#-]?\s*", "", name, flags=re.IGNORECASE).strip()
            qty = int(post_qty_match.group(2))
            if len(name) > 2 and not name.isdigit():
                raw_items.append({"name": name, "qty": qty})
                continue

        if name_solo:
            val = name_solo.group(1).strip()
            # Deep Label Strip: Remove "Product Name:", "Quantity:", etc.
            val = re.sub(fr"({LABEL_LABELS})\s*[:–#-]?\s*", "", val, flags=re.IGNORECASE).strip()
            val = re.split(r'Qty|Quantity|Units|ID|Part|Code|–|--|:|\(|\"|–', val, re.IGNORECASE)[0].strip()
            
            if len(val) > 2:
                if "name" in current_item and current_item["name"] != val:
                    raw_items.append(current_item)
                    current_item = {}
                current_item["name"] = val
        
        if qty_solo and "name" in current_item:
            current_item["qty"] = int(qty_solo.group(1))

    if "name" in current_item:
        raw_items.append(current_item)

    # 6. PRODUCT SCHEMA SYNTHESIS
    if raw_items:
        unique_items = []
        seen_names = set()
        for itm in raw_items:
            name_clean = itm["name"].strip()
            # Final Safety: Skip label-only captures
            if name_clean and len(name_clean) > 2 and name_clean not in seen_names and name_clean.lower() not in ["quantity", "product id", "part id"]:
                unique_items.append({"name": name_clean, "qty": itm.get("qty", 0)})
                seen_names.add(name_clean)
        
        if unique_items:
            data["all_items"] = unique_items
            if len(unique_items) > 1:
                data["item_name"] = f"{unique_items[0]['name']} (+{len(unique_items)-1} more)"
                data["quantity"] = sum(i["qty"] for i in unique_items)
            else:
                data["item_name"] = unique_items[0]["name"]
                data["quantity"] = unique_items[0]["qty"]
            
    return data
