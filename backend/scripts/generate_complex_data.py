import pandas as pd
import random
import os

# --- DEFINE CATEGORIES AND DATA ---
CATEGORIES = ["Manufacturing", "Trading", "Distribution"]

# BOARDROOM V13: Hardened Items based on real-world Zenith failure
ITEMS = {
    "Manufacturing": [
        "Forged Steel Crankshaft Assembly", "Machine Bolts - Grade 8", "Iron Support Plates", 
        "Hydraulic Cylinder Mount", "Aluminum Housing Block", "Cylindrical Bearing Kit", 
        "Industrial Gear Shaft", "Pneumatic Valve Assembly", "Steel Rods (Part ID: SR-8821)",
        "Iron Plates (Part ID: IP-5521)", "Machine Bolts (Part ID: MB-7741)"
    ],
    "Trading": [
        "POS Payment Terminal", "Smart Banking Kiosk", "Aadhaar Enabled Biometric Device",
        "Mobile POS (mPOS) Device", "iPhone 15 Pro Max", "Samsung Galaxy S24 Ultra", 
        "ThinkPad L14 Laptop", "Fingerprint Scanner Module", "Handheld POS Terminal"
    ],
    "Distribution": [
        "FMCG Drinking Water Bulk Packets", "Packaged Drinking Water", "Snack Packs (Bulk)", 
        "Dairy Milk Packs", "Logistics Service Agreement", "Warehouse Inventory Shift",
        "Bulk Shipping Container Hub", "Dispatch Logistics Route Plan", "Regional Hub Supply"
    ]
}

# BOARDROOM V13: Hardened Locations + Company Names
COMPANIES = {
    "Manufacturing": ["Evolute Manufacturing Unit", "Plant 1, Pune", "Chakan MIDC Factory"],
    "Trading": ["Zenith Trading Co.", "Global Retail Hub", "Electronics Trading Point", "Trading Partners Ltd."],
    "Distribution": ["Southern Region Warehouse", "Chennai Distribution Point", "Logistics Delta Hub"]
}

LOCATIONS = {
    "Manufacturing": ["Unit 4, Chakan MIDC, Plant 1", "Sector 18, Pune", "Manufacturing Hub, Mumbai"],
    "Trading": ["Warehouse, Mumbai", "Retail Center Alpha, Mumbai", "Electronics Mall Hub, Delhi"],
    "Distribution": ["Chennai Regional Warehouse (SR-04)", "Logistics Hub Delta, Hyderabad", "Fulfillment Center Omega, Chennai"]
}

TEMPLATES = [
    # 1. MANUFACTURING: Production focus
    """Subject: Production Materials for {loc}
Order No: {po}
Please process for {loc}:
- {item} (Part Number: {id}) - Qty: {qty}
Regards, Factory Coordinator""",

    # 2. TRADING: Finished Goods & Trading Co (V13 Fix)
    """Subject: Urgent Order from {comp}
Order Ref: {po}
We would like to place an order for the following ready stock from Evolute.
Items:
* Product Name: {item} | Quantity: {qty} units
Delivery Address: {loc}
Best, Procurement Manager {comp}""",

    # 3. DISTRIBUTION: Bulk Shipments & Move logic
    """Order No: {po}
Subject: Regional Stock Replenishment for {loc}
This is a purchase request for {qty} units of "{item}".
Shipping Address: {loc}
Dispatch within 48 hours for bulk distribution.
Regards, Inventory Manager""",

    # 4. NESTED (Zenith Style - V13 Fix)
    """Greetings from {comp}.
Order Details: {po}
*Product Details*
- *Product Name:* {item}
- *Quantity:* {qty} units
- *Product Name:* {item2}
- *Quantity:* {qty2} units
Delivery: {loc}
Payment Terms: 30 Days Credit.
Regards, Rahul Mehta, {comp}"""
]

def generate_sample():
    cat = random.choice(CATEGORIES)
    template = random.choice(TEMPLATES)
    
    # Context-aware weights
    if cat == "Manufacturing":
        items_list = ITEMS["Manufacturing"]
        loc = random.choice(LOCATIONS["Manufacturing"])
        comp = random.choice(COMPANIES["Manufacturing"])
    elif cat == "Trading":
        items_list = ITEMS["Trading"]
        loc = random.choice(LOCATIONS["Trading"])
        comp = random.choice(COMPANIES["Trading"])
        # Ensure 'Trading' is more likely to use the 'Trading Template' (v13 fix)
        if random.random() > 0.3:
            template = TEMPLATES[1] if random.random() > 0.5 else TEMPLATES[3]
    else:
        items_list = ITEMS["Distribution"]
        loc = random.choice(LOCATIONS["Distribution"])
        comp = random.choice(COMPANIES["Distribution"])
        if random.random() > 0.3:
            template = TEMPLATES[2]

    po_num = f"{'EVO-PO-' if cat == 'Trading' else 'PUR-'}{random.randint(1000, 9999)}"
    item = random.choice(items_list)
    item2 = random.choice(items_list)
    qty = random.randint(10, 5000)
    qty2 = random.randint(10, 2000)
    
    body = template.format(
        po=po_num, item=item, item2=item2, qty=qty, qty2=qty2, 
        loc=loc, comp=comp, id=f"ID-{random.randint(500, 900)}"
    )
    
    return {"text": body, "label": cat}

# --- GENERATE 10,000 SAMPLES ---
print("🚀 CEO SIGNAL GENERATION: Generating 10,000 High-Diversity Samples (v13)...")
data = [generate_sample() for _ in range(10000)]
df = pd.DataFrame(data)

# --- SAVE DATA ---
data_dir = "backend/data"
os.makedirs(data_dir, exist_ok=True)
csv_path = os.path.join(data_dir, "complex_emails.csv")
df.to_csv(csv_path, index=False)

print(f"✅ Success: 10,000 Signals saved to {csv_path}")
print(df["label"].value_counts())
