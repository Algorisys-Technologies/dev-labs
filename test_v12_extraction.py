# Test v12.1 Extraction
import sys
import os

sys.path.append(os.getcwd())

from backend.extractor import extract_po_details

EMAIL_TEXT = """Hello,

As per current demand spike, we need immediate stock replenishment.

Order Ref: DIST-APR-9901

Items Required:
- Packaged Drinking Water – 9000 units
- Snack Packs – 7500 units
- Dairy Milk Packs – 5000 units

Dispatch Plan:
- Mumbai Warehouse – 50%
- Pune Hub – 30%
- Nashik Distribution Point – 20%

Timeline: within 48 hours

Notes:
- ensure batch tracking
- expiry dates must be clearly visible
- damaged goods to be replaced

Payment: 50% advance

Confirm dispatch ASAP.

Thanks,
Logistics Team"""

res = extract_po_details(EMAIL_TEXT)
print("="*60)
print("🚀 V12.1 EXTRACTION AUDIT")
print("="*60)
print(f"PO ID:      {res['po_number']}")
print(f"ITEMS:      {res['item_name']}")
print(f"QUANTITY:   {res['quantity']}")
print(f"LOCATION:   {res['location']}")
print(f"SUPPLIER:   {res['supplier']}")
print(f"AMOUNT:     {res['amount']}")
print("="*60)

if res['po_number'] == "DIST-APR-9901":
    print("✅ SUCCESS: Pattern 'Order Ref: DIST-' captured perfectly.")
else:
    print("❌ FAILURE: PO ID not Found.")
