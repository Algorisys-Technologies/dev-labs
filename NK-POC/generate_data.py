"""
NK Protein AI - Dummy Data Generator
Generates realistic CSV data for all 4 modules
Run this ONCE to create your data files
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os
import random

os.makedirs("data", exist_ok=True)
np.random.seed(42)
random.seed(42)

# ─────────────────────────────────────────────
# MODULE 1: SALES HISTORY  (800 rows)
# Daily sales per product from Jan 2022 to Jun 2024
# ─────────────────────────────────────────────
print("Generating sales_history.csv ...")

products = {
    "High-Protein Whey":    {"base": 520, "trend": 1.15, "seasonality": "high"},
    "Casein Blend":         {"base": 310, "trend": 0.94, "seasonality": "medium"},
    "Soy Protein Isolate":  {"base": 180, "trend": 0.88, "seasonality": "low"},
    "Plant Protein Mix":    {"base": 420, "trend": 1.22, "seasonality": "high"},
    "Whey Concentrate 80%": {"base": 390, "trend": 1.08, "seasonality": "medium"},
    "BCAA Supplement":      {"base": 260, "trend": 1.05, "seasonality": "medium"},
    "Egg White Protein":    {"base": 150, "trend": 0.92, "seasonality": "low"},
    "Collagen Peptides":    {"base": 200, "trend": 1.30, "seasonality": "high"},
}

regions = ["Mumbai", "Delhi", "Bangalore", "Chennai", "Hyderabad", "Pune", "Ahmedabad"]
channels = ["Retail", "Online", "Wholesale", "Export"]

sales_rows = []
start_date = datetime(2022, 1, 1)
end_date   = datetime(2024, 6, 30)

for product, props in products.items():
    current_date = start_date
    month_num = 0
    while current_date <= end_date:
        month_num += 1
        # Trend growth
        trend_factor = props["trend"] ** (month_num / 12)

        # Seasonality: Q1 slow, Q2 medium, Q3 peak, Q4 high
        month = current_date.month
        if props["seasonality"] == "high":
            season = {1:0.75, 2:0.80, 3:0.90, 4:1.00, 5:1.05, 6:1.10,
                      7:1.20, 8:1.25, 9:1.15, 10:1.10, 11:1.05, 12:0.95}[month]
        elif props["seasonality"] == "medium":
            season = {1:0.85, 2:0.88, 3:0.92, 4:0.97, 5:1.02, 6:1.05,
                      7:1.10, 8:1.08, 9:1.05, 10:1.00, 11:0.98, 12:0.90}[month]
        else:
            season = 1.0

        for region in regions:
            region_factor = {"Mumbai":1.20, "Delhi":1.15, "Bangalore":1.18,
                             "Chennai":0.95, "Hyderabad":1.00, "Pune":1.05, "Ahmedabad":0.90}[region]
            for channel in channels:
                channel_factor = {"Retail":1.0, "Online":1.25, "Wholesale":0.85, "Export":0.70}[channel]

                base_sales = props["base"] * trend_factor * season * region_factor * channel_factor
                noise      = np.random.normal(1.0, 0.08)
                units_sold = max(10, int(base_sales * noise))
                unit_price = round(np.random.uniform(380, 520), 2)
                revenue    = round(units_sold * unit_price, 2)
                cost       = round(revenue * np.random.uniform(0.55, 0.70), 2)
                margin_pct = round((revenue - cost) / revenue * 100, 2)

                sales_rows.append({
                    "date":            current_date.strftime("%Y-%m-%d"),
                    "product":         product,
                    "region":          region,
                    "channel":         channel,
                    "units_sold":      units_sold,
                    "unit_price":      unit_price,
                    "revenue":         revenue,
                    "cogs":            cost,
                    "gross_margin":    margin_pct,
                    "returns":         int(units_sold * np.random.uniform(0.00, 0.03)),
                    "discount_pct":    round(np.random.uniform(0, 12), 2),
                    "sales_rep":       f"REP-{np.random.randint(101,130)}",
                })
        current_date += timedelta(days=32)
        current_date = current_date.replace(day=1)

df_sales = pd.DataFrame(sales_rows)
df_sales.to_csv("data/sales_history.csv", index=False)
print(f"  ✓ sales_history.csv  → {len(df_sales)} rows")


# ─────────────────────────────────────────────
# MODULE 2: ACCOUNTS RECEIVABLE AGING  (600 rows)
# ─────────────────────────────────────────────
print("Generating ar_aging.csv ...")

customers = [
    ("Protein World Ltd",       "Mumbai",    "High Risk",   180000, 0.60),
    ("FitLife Distributors",    "Delhi",     "Medium Risk", 120000, 0.35),
    ("NutriMax Wholesale",      "Bangalore", "Low Risk",     90000, 0.15),
    ("HealthHub Retail",        "Chennai",   "High Risk",   210000, 0.55),
    ("GymPro Supplements",      "Pune",      "Medium Risk",  75000, 0.30),
    ("Apex Nutrition",          "Hyderabad", "Low Risk",     55000, 0.10),
    ("SportsFuel India",        "Mumbai",    "High Risk",   160000, 0.65),
    ("PowerFit Stores",         "Delhi",     "Medium Risk",  95000, 0.25),
    ("VitaWell Distributors",   "Ahmedabad", "Low Risk",     40000, 0.08),
    ("ActiveLife Co",           "Bangalore", "Medium Risk",  85000, 0.40),
    ("MuscleZone Retail",       "Chennai",   "High Risk",   130000, 0.70),
    ("ProHealth Wholesale",     "Pune",      "Low Risk",     60000, 0.12),
    ("FuelUp Nutrition",        "Mumbai",    "Medium Risk", 110000, 0.45),
    ("BodyBuild Distributors",  "Delhi",     "High Risk",   195000, 0.58),
    ("NutriGo Stores",          "Hyderabad", "Low Risk",     35000, 0.05),
]

ar_rows = []
invoice_id = 10001
for customer, city, risk, credit_limit, overdue_prob in customers:
    num_invoices = random.randint(30, 55)
    for _ in range(num_invoices):
        invoice_date = start_date + timedelta(days=random.randint(0, 800))
        due_date     = invoice_date + timedelta(days=30)
        amount       = round(random.uniform(5000, credit_limit * 0.4), 2)
        days_overdue = (datetime(2024, 6, 30) - due_date).days

        if random.random() < overdue_prob:
            status   = random.choice(["Overdue", "Partially Paid"])
            paid_amt = round(amount * random.uniform(0.0, 0.6), 2) if status == "Partially Paid" else 0
        else:
            status   = "Paid" if days_overdue > 0 else "Current"
            paid_amt = amount if status == "Paid" else 0

        outstanding = round(amount - paid_amt, 2)
        aging_bucket = (
            "0-30 days"  if 0 <= days_overdue <= 30 else
            "31-60 days" if 31 <= days_overdue <= 60 else
            "61-90 days" if 61 <= days_overdue <= 90 else
            "90+ days"   if days_overdue > 90 else "Not Due"
        )

        ar_rows.append({
            "invoice_id":     f"INV-{invoice_id}",
            "customer_name":  customer,
            "city":           city,
            "risk_category":  risk,
            "invoice_date":   invoice_date.strftime("%Y-%m-%d"),
            "due_date":       due_date.strftime("%Y-%m-%d"),
            "invoice_amount": amount,
            "paid_amount":    paid_amt,
            "outstanding":    outstanding,
            "days_overdue":   max(0, days_overdue),
            "aging_bucket":   aging_bucket,
            "status":         status,
            "credit_limit":   credit_limit,
            "payment_terms":  "Net 30",
        })
        invoice_id += 1

df_ar = pd.DataFrame(ar_rows)
df_ar.to_csv("data/ar_aging.csv", index=False)
print(f"  ✓ ar_aging.csv       → {len(df_ar)} rows")


# ─────────────────────────────────────────────
# MODULE 3: INVENTORY  (500 rows)
# ─────────────────────────────────────────────
print("Generating inventory.csv ...")

raw_materials = [
    ("Whey Protein Concentrate", "WPC",  "Raw Material", 850, 200, 500),
    ("Casein Protein Powder",    "CAS",  "Raw Material", 920, 150, 300),
    ("Soy Protein Isolate",      "SPI",  "Raw Material", 780, 80,  200),
    ("BCAA Powder",              "BCA",  "Raw Material", 1100,60,  150),
    ("Collagen Hydrolysate",     "COL",  "Raw Material", 650, 40,  100),
    ("Egg Albumin",              "EGA",  "Raw Material", 720, 50,  120),
    ("Pea Protein",              "PEA",  "Raw Material", 680, 90,  180),
    ("Maltodextrin",             "MAL",  "Raw Material", 120, 500, 800),
    ("Natural Flavors",          "NFL",  "Ingredient",   2200,20,  50),
    ("Sucralose",                "SUC",  "Ingredient",   3400,10,  25),
]

finished_goods = [
    ("High-Protein Whey 1kg",   "FG001","Finished Good", 1800, 300, 600),
    ("Casein Blend 1kg",        "FG002","Finished Good", 1600, 120, 250),
    ("Soy Isolate 500g",        "FG003","Finished Good", 950,  80,  150),
    ("Plant Protein Mix 1kg",   "FG004","Finished Good", 1750, 250, 500),
    ("Whey Concentrate 2kg",    "FG005","Finished Good", 3200, 180, 350),
    ("BCAA 300g",               "FG006","Finished Good", 1200, 200, 400),
    ("Collagen Peptides 250g",  "FG007","Finished Good", 1450, 100, 200),
    ("Egg White Protein 1kg",   "FG008","Finished Good", 1900, 60,  120),
]

warehouses = ["Mumbai WH", "Delhi WH", "Bangalore WH", "Pune WH"]

inv_rows = []
item_id = 5001

all_items = raw_materials + finished_goods

for item_name, sku, category, unit_cost, reorder_level, ideal_stock in all_items:
    for warehouse in warehouses:
        num_records = random.randint(10, 18)
        for i in range(num_records):
            record_date  = start_date + timedelta(days=random.randint(0, 910))
            current_qty  = random.randint(0, int(ideal_stock * 1.5))
            last_sale_dt = record_date - timedelta(days=random.randint(0, 150))
            days_no_move = (datetime(2024, 6, 30) - last_sale_dt).days

            # Dead stock: items with 0 movement in 90+ days
            is_dead_stock = days_no_move >= 90

            # Reorder flag
            needs_reorder = current_qty <= reorder_level

            holding_cost  = round(current_qty * unit_cost * 0.02, 2)  # 2% monthly
            total_value   = round(current_qty * unit_cost, 2)

            inv_rows.append({
                "item_id":          f"ITEM-{item_id}",
                "sku":              sku,
                "item_name":        item_name,
                "category":         category,
                "warehouse":        warehouse,
                "record_date":      record_date.strftime("%Y-%m-%d"),
                "current_qty_kg":   current_qty,
                "reorder_level_kg": reorder_level,
                "ideal_stock_kg":   ideal_stock,
                "unit_cost_inr":    unit_cost,
                "total_value_inr":  total_value,
                "last_sale_date":   last_sale_dt.strftime("%Y-%m-%d"),
                "days_no_movement": days_no_move,
                "is_dead_stock":    is_dead_stock,
                "needs_reorder":    needs_reorder,
                "monthly_holding_cost": holding_cost,
                "supplier":         f"Supplier-{random.randint(1,8)}",
                "lead_time_days":   random.randint(7, 21),
            })
            item_id += 1

df_inv = pd.DataFrame(inv_rows)
df_inv.to_csv("data/inventory.csv", index=False)
print(f"  ✓ inventory.csv      → {len(df_inv)} rows")


# ─────────────────────────────────────────────
# MODULE 4: GST RECONCILIATION  (500 rows)
# ─────────────────────────────────────────────
print("Generating gst_data.csv ...")

vendors = [
    ("Vendor A - Raw Protein Co",  "27AABCU9603R1ZX", "Regular"),
    ("Vendor B - PackagingPlus",   "07BBBCS9999R1ZY", "Regular"),
    ("Vendor C - FlavorTech",      "29CCCCT1234R1ZW", "Regular"),
    ("Vendor D - LogisticsFast",   "27DDDDU5678R1ZV", "Regular"),
    ("Vendor E - LabChemicals",    "19EEEEV9012R1ZU", "Composition"),
    ("Vendor F - PrintingHub",     "36FFFFW3456R1ZT", "Regular"),
    ("Vendor G - ColdStorage",     "09GGGGY7890R1ZS", "Regular"),
    ("Vendor H - ContainerWorld",  "24HHHHZ2345R1ZR", "Regular"),
]

gst_rows = []
doc_id = 20001

for month_offset in range(30):  # 30 months of data
    doc_date = (datetime(2022, 1, 1) + timedelta(days=month_offset * 30))
    for vendor_name, gstin, vtype in vendors:
        num_invoices = random.randint(5, 12)
        for _ in range(num_invoices):
            taxable_value = round(random.uniform(10000, 200000), 2)
            gst_rate      = random.choice([5, 12, 18, 28])
            books_igst    = round(taxable_value * gst_rate / 100, 2)

            # Introduce mismatches for some records
            mismatch_type = "None"
            gstr2b_igst   = books_igst
            if random.random() < 0.20:   # 20% mismatch rate
                delta = round(random.uniform(-5000, 5000), 2)
                gstr2b_igst  = round(books_igst + delta, 2)
                if delta > 0:
                    mismatch_type = "Excess in 2B"
                else:
                    mismatch_type = "Short in 2B"

            difference   = round(gstr2b_igst - books_igst, 2)
            itc_eligible = gstr2b_igst if mismatch_type == "None" else min(books_igst, gstr2b_igst)
            itc_at_risk  = abs(difference)

            gst_rows.append({
                "doc_id":            f"GST-{doc_id}",
                "month":             doc_date.strftime("%Y-%m"),
                "vendor_name":       vendor_name,
                "vendor_gstin":      gstin,
                "vendor_type":       vtype,
                "invoice_date":      doc_date.strftime("%Y-%m-%d"),
                "taxable_value":     taxable_value,
                "gst_rate_pct":      gst_rate,
                "books_igst":        books_igst,
                "gstr2b_igst":       gstr2b_igst,
                "difference":        difference,
                "mismatch_type":     mismatch_type,
                "itc_eligible":      round(itc_eligible, 2),
                "itc_at_risk":       round(itc_at_risk, 2),
                "status":            "Reconciled" if mismatch_type == "None" else "Mismatch",
                "filing_period":     doc_date.strftime("%b-%Y"),
            })
            doc_id += 1

df_gst = pd.DataFrame(gst_rows)
df_gst.to_csv("data/gst_data.csv", index=False)
print(f"  ✓ gst_data.csv       → {len(df_gst)} rows")

print("\n✅ All data files created successfully in /data folder!")
print(f"   Sales History : {len(df_sales):,} rows")
print(f"   AR Aging      : {len(df_ar):,} rows")
print(f"   Inventory     : {len(df_inv):,} rows")
print(f"   GST Data      : {len(df_gst):,} rows")