# Test v13 Deep-Label Item Extraction
import sys
import os

sys.path.append(os.getcwd())

from backend.extractor import extract_po_details

EMAIL_TEXT = """Dear Team,
Greetings from Zenith Trading Co.
We would like to place an order for:

   - *Product Name:* POS Payment Terminal
   - *Quantity:* 250 units
   - *Product Name:* Smart Banking Kiosk
   - *Quantity:* 50 units

Delivery Location: Zenith Trading Co. Warehouse, Mumbai
"""

res = extract_po_details(EMAIL_TEXT)
print("="*60)
print("🚀 V13 DEEP-LABEL AUDIT (ZENITH FIX)")
print("="*60)
print(f"PO ID:      {res['po_number']}")
print(f"ITEM 1:     {res['all_items'][0]['name']} (Qty: {res['all_items'][0]['qty']})")
print(f"ITEM 2:     {res['all_items'][1]['name']} (Qty: {res['all_items'][1]['qty']})")
print(f"LOCATION:   {res['location']}")
print("="*60)

if "Product Name" not in res['all_items'][0]['name'] and res['all_items'][0]['qty'] == 250:
    print("✅ SUCCESS: Deep-Label Scraper stripped 'Product Name:' perfectly.")
else:
    print("❌ FAILURE: Item name still contains labels.")
