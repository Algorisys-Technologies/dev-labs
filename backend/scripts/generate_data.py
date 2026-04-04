import pandas as pd
import random
import os

# Define templates for each category
categories = ["Manufacturing", "Trading", "Distribution"]

po_prefixes = ["PO-2026-", "ORD-", "PUR-", "EVO-"]
goods = [
    "Brake Pad Assembly", "Engine Control Unit", "Hydraulic Pump", 
    "Transmission Gear", "Conveyor Belt", "Steel Coil", "Copper Wire",
    "Industrial Sensor", "LED Driver", "Power Supply Unit",
    "Plastic Pellets", "Aluminum Sheet", "Bearing Kit", "Sealing O-Ring"
]

locations = {
    "Manufacturing": [
        "A10 Manufacturing Plant, Pune", "Chakan Industrial Area, Phase II",
        "Oragadam Factory, Chennai", "Hosur Production Unit", "Sanand Assembly Plant",
        "Bawal Manufacturing Hub", "Pantnagar Factory Complex"
    ],
    "Trading": [
        "Global Trade Center, Mumbai", "Export-Import Hub, Mundra",
        "City Wholesalers Market, Delhi", "Vashi APMC Market", "Metro Trading Point",
        "Regional Stockist Warehouse, Bangalore", "Harbour View Trade Zone"
    ],
    "Distribution": [
        "Regional Distribution Center, Nagpur", "E-commerce Logistics Hub, Bhiwandi",
        "Central Warehouse, Hyderabad", "Last-Mile Delivery Depot, Kolkata",
        "State Logistics Park, Indore", "Logistics Terminal, Kochi", "Hub & Spoke Center, Lucknow"
    ]
}

def generate_email(category):
    po_no = f"{random.choice(po_prefixes)}{random.randint(10000, 99999)}"
    date = f"{random.randint(1, 28):02d}-{random.choice(['Apr', 'May', 'Jun'])}-2026"
    item = random.choice(goods)
    qty = random.randint(50, 5000)
    location = random.choice(locations[category])
    
    # Variations in wording
    openers = [
        "Dear Sir/Madam,", "Greetings,", "Hello Team,", "Hi,", "To the Sales Department,"
    ]
    intros = [
        "We would like to place an order for the following items.",
        "Please find our purchase order details below.",
        "Attached is our formal requirement for the current month.",
        "We are pleased to issue this purchase order as per our recent discussion.",
        "Kindly process the following order at the earliest."
    ]
    
    body = f"""{random.choice(openers)}
{random.choice(intros)}

Purchase Order No: {po_no}
Order Date: {date}

Goods Name: {item}
Quantity: {qty} units

Delivery Location: {location}

Regards,
Procurement Team
"""
    subject = f"Purchase Order: {po_no} - {item}"
    
    return f"{subject}\n\n{body}"

def main():
    data = []
    for category in categories:
        for _ in range(40): # 40 samples per category = 120 total
            email_content = generate_email(category)
            data.append({"text": email_content, "category": category})
    
    df = pd.DataFrame(data)
    # Shuffle the data
    df = df.sample(frac=1).reset_index(drop=True)
    
    output_path = "backend/data/emails.csv"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    df.to_csv(output_path, index=False)
    print(f"Generated {len(df)} samples and saved to {output_path}")

if __name__ == "__main__":
    main()
