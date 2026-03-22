"""
NK Protein AI — Command Center
Flask backend connecting all 3 trained models to the chatbot UI
"""

import os
import sys
import pickle
import warnings
import pandas as pd
import numpy as np
from flask import Flask, render_template, request, jsonify

warnings.filterwarnings("ignore")

app = Flask(__name__)

print("\n" + "="*55)
print("NK PROTEIN AI — Loading models...")
print("="*55)

BASE_DIR    = os.path.dirname(__file__)
MODELS_DIR  = os.path.join(BASE_DIR, "saved_models")
DATA_DIR    = os.path.join(BASE_DIR, "data")

try:
    with open(os.path.join(MODELS_DIR, "cashflow_model.pkl"), "rb") as f:
        cf_package = pickle.load(f)
    cf_model    = cf_package["model"]
    cf_features = cf_package["features"]
    cf_le_cust  = cf_package["le_customer"]
    cf_le_city  = cf_package["le_city"]
    cf_le_prod  = cf_package["le_product"]
    df_ar       = pd.read_csv(os.path.join(DATA_DIR, "ar_aging.csv"),
                              parse_dates=["invoice_date","due_date"])
    print("  ok Cash Flow model loaded")
except Exception as e:
    cf_model = None
    print(f"  warn Cash Flow model failed: {e}")

try:
    with open(os.path.join(MODELS_DIR, "inventory_model.pkl"), "rb") as f:
        inv_package = pickle.load(f)
    inv_model    = inv_package["model"]
    inv_features = inv_package["features"]
    inv_le_sku   = inv_package["le_sku"]
    inv_le_cat   = inv_package["le_category"]
    inv_le_wh    = inv_package["le_warehouse"]
    df_inv       = pd.read_csv(os.path.join(DATA_DIR, "inventory.csv"),
                               parse_dates=["snapshot_date","last_sale_date"])
    print("  ok Inventory model loaded")
except Exception as e:
    inv_model = None
    print(f"  warn Inventory model failed: {e}")

try:
    with open(os.path.join(MODELS_DIR, "gst_summary.pkl"), "rb") as f:
        gst_summary = pickle.load(f)
    df_gst = pd.read_csv(os.path.join(DATA_DIR, "gst_data.csv"))
    print("  ok GST data loaded")
except Exception as e:
    gst_summary = None
    print(f"  warn GST data failed: {e}")

print("="*55 + "\n")

SALES_KW = [
    "sales", "forecast", "predict", "quarter", "revenue", "growth",
    "q3", "q4", "trend", "promote", "discontinue", "top product",
    "best product", "best selling", "which product", "production",
    "next quarter", "most demand", "highest demand", "popular",
    "least demand", "low demand", "phase out", "drop product",
    "top selling", "worst product"
]
CASH_KW  = ["cash","liquidity","receivable","overdue","outstanding","collection","payment","customer","aging","money trapped","cash flow","working capital","30 day","60 day","90 day","slow pay","at risk","trapped","stuck","who owes"]
INV_KW   = ["inventory","stock","dead stock","warehouse","reorder","kg","storage","material","raw material","finished","holding","blocked","liquidat","overstock","item","sku","dead","idle","shelf"]
GST_KW   = ["gst","tax","gstr","itc","input tax","mismatch","reconcil","2a","2b","liability","vendor","compliance","filing","igst","cgst","sgst","tds"]
HEALTH_KW= ["health check","health","status","overview","summary","biggest risk","how are we","dashboard","everything","all modules","good morning","hi","hello","start"]

def detect_intent(msg):
    msg = msg.lower()
    scores = {
        "sales":     sum(1 for k in SALES_KW  if k in msg),
        "cash":      sum(1 for k in CASH_KW   if k in msg),
        "inventory": sum(1 for k in INV_KW    if k in msg),
        "gst":       sum(1 for k in GST_KW    if k in msg),
        "health":    sum(1 for k in HEALTH_KW if k in msg),
    }
    best = max(scores, key=scores.get)
    return best if scores[best] > 0 else "unknown"

def handle_cash(query):
    if cf_model is None or df_ar is None:
        return "Cash Flow model not loaded. Check saved_models folder."
    data = df_ar.copy()
    try: data["customer_enc"] = cf_le_cust.transform(data["customer_name"])
    except: data["customer_enc"] = 0
    try: data["city_enc"] = cf_le_city.transform(data["city"])
    except: data["city_enc"] = 0
    try: data["product_enc"] = cf_le_prod.transform(data["product_category"])
    except: data["product_enc"] = 0
    data["invoice_date"]    = pd.to_datetime(data["invoice_date"])
    data["invoice_month"]   = data["invoice_date"].dt.month
    data["invoice_quarter"] = data["invoice_date"].dt.quarter
    data["invoice_year"]    = data["invoice_date"].dt.year
    data["is_fy_end"]       = (data["invoice_month"] == 3).astype(int)
    data["is_fy_start"]     = (data["invoice_month"] == 4).astype(int)
    data["credit_stress"]       = data["invoice_amount"] / (data["credit_limit"] + 1)
    avg_per_cust                = data.groupby("customer_enc")["invoice_amount"].transform("mean")
    data["invoice_vs_avg"]      = data["invoice_amount"] / (avg_per_cust + 1)
    data["terms_x_utilization"] = data["payment_terms_days"] * data["credit_utilization"]
    data = data.sort_values(["customer_enc","invoice_date"]).reset_index(drop=True)
    data["cust_avg_overdue"]    = data.groupby("customer_enc")["days_overdue"].transform(lambda x: x.shift(1).expanding().mean().fillna(0))
    data["cust_late_count"]     = data.groupby("customer_enc")["is_high_risk"].transform(lambda x: x.shift(1).expanding().sum().fillna(0))
    data["cust_overdue_rate"]   = data.groupby("customer_enc")["is_high_risk"].transform(lambda x: x.shift(1).expanding().mean().fillna(0))
    data["cust_recent_overdue"] = data.groupby("customer_enc")["is_high_risk"].transform(lambda x: x.shift(1).rolling(3, min_periods=1).mean().fillna(0))
    available = [f for f in cf_features if f in data.columns]
    X = data[available].fillna(0)
    data["risk_score"] = cf_model.predict_proba(X)[:, 1]
    total_ar     = data["outstanding"].sum()
    overdue_90   = data[data["days_overdue"] > 90]["outstanding"].sum()
    high_risk_ar = data[data["is_high_risk"] == 1]["outstanding"].sum()
    cust_summary = data.groupby("customer_name").agg(total_outstanding=("outstanding","sum"),avg_risk_score=("risk_score","mean"),max_days_overdue=("days_overdue","max"),city=("city","first")).sort_values("total_outstanding",ascending=False).reset_index()
    today = pd.Timestamp("2024-06-30")
    data["due_date"] = pd.to_datetime(data["due_date"])
    data["exp_pay"]  = data["due_date"] + pd.to_timedelta((data["risk_score"]*60).astype(int),unit="D")
    next_30 = data[data["exp_pay"] <= today+pd.Timedelta(days=30)]["outstanding"].sum()
    next_60 = data[data["exp_pay"] <= today+pd.Timedelta(days=60)]["outstanding"].sum()
    next_90 = data[data["exp_pay"] <= today+pd.Timedelta(days=90)]["outstanding"].sum()
    lines = ["CASH FLOW & LIQUIDITY RISK REPORT","━"*40,f"  Total Outstanding AR    : Rs{total_ar:>13,.0f}",f"  High Risk Amount        : Rs{high_risk_ar:>13,.0f}",f"  90+ Day Overdue         : Rs{overdue_90:>13,.0f}","","Expected Cash Inflows:",f"   Next 30 days : Rs{next_30:>13,.0f}",f"   Next 60 days : Rs{next_60:>13,.0f}",f"   Next 90 days : Rs{next_90:>13,.0f}","","Top At-Risk Customers:"]
    for _, row in cust_summary.head(5).iterrows():
        flag = "HIGH RISK" if row["avg_risk_score"] > 0.6 else "MEDIUM"
        lines.append(f"   {flag} {row['customer_name']} ({row['city']})")
        lines.append(f"      Rs{row['total_outstanding']:>10,.0f} outstanding | Risk: {row['avg_risk_score']:.0%} | Max overdue: {row['max_days_overdue']:.0f} days")
    if overdue_90 > 50000:
        lines += ["",f"ACTION REQUIRED: Rs{overdue_90:,.0f} stuck in 90+ day overdue.","Immediate collection calls needed on top customers."]
    return "\n".join(lines)

def handle_inventory(query):
    if inv_model is None or df_inv is None:
        return "Inventory model not loaded. Check saved_models folder."
    data = df_inv.copy()
    try: data["sku_enc"]       = inv_le_sku.transform(data["sku"])
    except: data["sku_enc"]    = 0
    try: data["category_enc"]  = inv_le_cat.transform(data["category"])
    except: data["category_enc"] = 0
    try: data["warehouse_enc"] = inv_le_wh.transform(data["warehouse"])
    except: data["warehouse_enc"] = 0
    data["days_of_stock"]    = data["current_stock_kg"] / (data["avg_daily_sales"] + 0.01)
    data["overstock_ratio"]  = data["current_stock_kg"] / (data["ideal_stock"] + 1)
    data["velocity_score"]   = data["avg_daily_sales"]  / (data["current_stock_kg"] + 1)
    data["holding_pressure"] = data["monthly_holding_cost"] / (data["total_value_inr"] + 1)
    available = [f for f in inv_features if f in data.columns]
    X = data[available].fillna(0)
    data["dead_prob"] = inv_model.predict_proba(X)[:, 1]
    latest    = data[data["snapshot_date"] == data["snapshot_date"].max()].copy()
    total_val = latest["total_value_inr"].sum()
    dead_val  = latest[latest["is_dead_stock"]==1]["total_value_inr"].sum()
    dead_pct  = dead_val / (total_val+1) * 100
    hold_loss = latest[latest["is_dead_stock"]==1]["monthly_holding_cost"].sum()
    dead_items= latest[latest["is_dead_stock"]==1].groupby("product_name").agg(qty=("current_stock_kg","sum"),value=("total_value_inr","sum"),idle=("days_no_movement","mean"),loss_mo=("monthly_holding_cost","sum")).sort_values("value",ascending=False)
    at_risk   = latest[latest["dead_prob"]>=0.60].groupby("product_name").agg(risk=("dead_prob","mean"),val=("total_value_inr","sum")).sort_values("risk",ascending=False)
    reorders  = latest[latest["needs_reorder"]==1].groupby(["product_name","warehouse"]).agg(stock=("current_stock_kg","mean"),rpt=("reorder_point","mean"),lead=("lead_time_days","mean")).sort_values("stock").head(5)
    lines = ["INVENTORY INTELLIGENCE REPORT","━"*40,f"  Total Inventory Value  : Rs{total_val:>13,.0f}",f"  Dead Stock Value       : Rs{dead_val:>13,.0f} ({dead_pct:.1f}%)",f"  Monthly Holding Loss   : Rs{hold_loss:>13,.0f}","","Current Dead Stock (Liquidate Now):"]
    for name, row in dead_items.head(4).iterrows():
        lines.append(f"   {name}")
        lines.append(f"     Rs{row['value']:>10,.0f} blocked | {row['idle']:.0f} days idle | Rs{row['loss_mo']:,.0f}/month loss")
    if len(at_risk) > 0:
        lines += ["","AI Predicts These Will Go Dead (Next 2 Months):"]
        for name, row in at_risk.head(4).iterrows():
            lines.append(f"   {name} — {row['risk']:.0%} risk | Rs{row['val']:>10,.0f} at stake")
    lines += ["","Reorder Alerts:"]
    for (pname, wh), row in reorders.iterrows():
        lines.append(f"   {pname} @ {wh}")
        lines.append(f"     Stock: {row['stock']:.0f} kg | Reorder at: {row['rpt']:.0f} kg | Lead: {row['lead']:.0f} days")
    lines += ["",f"Recommendation: Liquidating dead stock frees Rs{dead_val:,.0f} in working capital."]
    return "\n".join(lines)

def handle_gst(query):
    if gst_summary is None:
        return "GST data not loaded. Check saved_models folder."
    g = gst_summary
    lines = ["GST RECONCILIATION REPORT","━"*40,f"  Total Invoices : {g['total_invoices']:,}",f"  Reconciled     : {g['total_invoices']-g['total_mismatches']:,}",f"  Mismatches     : {g['total_mismatches']:,} ({g['mismatch_rate']}%)","","ITC Position:",f"   Books IGST   : Rs{g['total_books_igst']:>13,.0f}",f"   GSTR-2B      : Rs{g['total_2b_igst']:>13,.0f}",f"   ITC at Risk  : Rs{g['total_itc_at_risk']:>13,.0f}",f"   Recoverable  : Rs{g['itc_recoverable']:>13,.0f}","","Top Vendors with Mismatches:"]
    for v in sorted(g.get("vendor_analysis",[]),key=lambda x:x["total_itc_risk"],reverse=True)[:4]:
        lines.append(f"   {v['vendor_name']}: {v['mismatch_count']} mismatches ({v['mismatch_pct']:.0f}%) | Rs{v['total_itc_risk']:>10,.0f} at risk")
    lines += ["","Q3 Tax Projection:",f"   Projected Liability  : Rs{g['q3_projected_tax']:>13,.0f}",f"   Recoverable ITC      : Rs{g['itc_recoverable']:>13,.0f}",f"   Net Liability        : Rs{g['q3_projected_tax']-g['itc_recoverable']:>13,.0f}","",f"ACTION: Follow up with vendors to recover Rs{g['itc_recoverable']:,.0f} before Q3 filing."]
    return "\n".join(lines)

def handle_sales(query):
    msg = query.lower()

    # ── Product demand analysis ──────────────────────────────
    if any(k in msg for k in [
        "most demand", "top product", "best product",
        "highest demand", "which product", "popular product",
        "best selling", "promote", "top selling"
    ]):
        if df_ar is not None:
            # Group by product category and sum invoice amounts
            product_demand = (
                df_ar.groupby("product_category")
                .agg(
                    total_revenue  = ("invoice_amount", "sum"),
                    total_invoices = ("invoice_id",     "count"),
                    avg_order_val  = ("invoice_amount", "mean"),
                    unique_customers = ("customer_name","nunique"),
                )
                .sort_values("total_revenue", ascending=False)
                .reset_index()
            )

            total_rev = product_demand["total_revenue"].sum()

            lines = [
                "📈 PRODUCT DEMAND ANALYSIS",
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                "  Ranked by Total Revenue Generated:",
                "",
            ]

            for i, row in product_demand.iterrows():
                rank        = i + 1
                share       = row["total_revenue"] / total_rev * 100
                flag        = "🥇" if rank == 1 else "🥈" if rank == 2 else "🥉" if rank == 3 else "  "
                action      = "📈 PROMOTE" if rank <= 3 else "✅ Maintain" if rank <= 5 else "⚠️  Review"

                lines.append(f"  {flag} #{rank} {row['product_category']}")
                lines.append(
                    f"      Revenue : ₹{row['total_revenue']:>12,.0f}"
                    f"  ({share:.1f}% of total)"
                )
                lines.append(
                    f"      Orders  : {row['total_invoices']:>5,}"
                    f"  |  Avg Order: ₹{row['avg_order_val']:>8,.0f}"
                    f"  |  Customers: {row['unique_customers']}"
                )
                lines.append(f"      Action  : {action}")
                lines.append("")

            # Top recommendation
            top     = product_demand.iloc[0]
            bottom  = product_demand.iloc[-1]
            lines += [
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                f"🚀 HIGHEST DEMAND : {top['product_category']}",
                f"   ₹{top['total_revenue']:,.0f} revenue"
                f" | {top['total_invoices']:,} orders",
                f"   Recommendation: Increase production by 15%"
                f" to capture rising demand.",
                "",
                f"⚠️  LOWEST DEMAND  : {bottom['product_category']}",
                f"   ₹{bottom['total_revenue']:,.0f} revenue"
                f" | {bottom['total_invoices']:,} orders",
                f"   Recommendation: Review pricing or consider"
                f" phasing out this SKU.",
            ]
            return "\n".join(lines)

    # ── Discontinue / low margin products ────────────────────
    if any(k in msg for k in [
        "discontinue", "phase out", "drop", "stop",
        "low demand", "worst product", "least demand"
    ]):
        if df_ar is not None:
            product_demand = (
                df_ar.groupby("product_category")
                .agg(total_revenue=("invoice_amount","sum"),
                     total_invoices=("invoice_id","count"))
                .sort_values("total_revenue")
                .reset_index()
            )
            lines = [
                "🔴 PRODUCTS TO CONSIDER DISCONTINUING",
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                "  Bottom 3 products by demand:",
                "",
            ]
            for i, row in product_demand.head(3).iterrows():
                lines.append(f"  ⚠️  {row['product_category']}")
                lines.append(
                    f"      Revenue: ₹{row['total_revenue']:>10,.0f}"
                    f"  |  Orders: {row['total_invoices']:,}"
                )
                lines.append(
                    f"      Reason : Low revenue, high storage cost."
                    f" Consider phasing out."
                )
                lines.append("")
            return "\n".join(lines)

    # ── Forecast / trend question ─────────────────────────────
    sales_pkl = os.path.join(MODELS_DIR, "sales_model.pkl")
    if os.path.exists(sales_pkl):
        try:
            with open(sales_pkl, "rb") as f:
                sales_data = pickle.load(f)
            forecasts = sales_data.get("forecasts", [])
            if forecasts:
                lines = [
                    "📊 SALES FORECAST",
                    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
                ]
                for fc in forecasts[:6]:
                    emoji = "📈" if fc.get("growth_pct", 0) > 5 else \
                            "⚠️"  if fc.get("growth_pct", 0) < 0 else "✅"
                    lines.append(f"  {emoji} {fc.get('product','')}")
                    lines.append(
                        f"     Q3: ₹{fc.get('q3_forecast',0):>10,.0f}"
                        f"  Growth: {fc.get('growth_pct',0):+.1f}%"
                    )
                    lines.append(f"     {fc.get('recommendation','')}")
                return "\n".join(lines)
        except Exception:
            pass

    # ── Default trend from AR data ────────────────────────────
    if df_ar is not None:
        monthly_rev = (
            df_ar.groupby(
                pd.to_datetime(df_ar["invoice_date"]).dt.to_period("M")
            )["invoice_amount"].sum()
        )
        last_3 = monthly_rev.tail(3).mean()
        prev_3 = monthly_rev.iloc[-6:-3].mean() \
                 if len(monthly_rev) >= 6 else last_3
        growth = ((last_3 - prev_3) / (prev_3 + 1)) * 100

        return "\n".join([
            "📊 SALES TREND ANALYSIS",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            f"  Avg Monthly Revenue (last 3m) : ₹{last_3:>12,.0f}",
            f"  Avg Monthly Revenue (prev 3m) : ₹{prev_3:>12,.0f}",
            f"  Trend                         : {growth:+.1f}%",
            "",
            f"  {'📈 Revenue growing — positive momentum.' if growth > 0 else '⚠️ Revenue declining — review pricing strategy.'}",
            "",
            "  Ask: 'which product has most demand?'",
            "  Ask: 'which products to discontinue?'",
        ])

    return "Sales data loading. Ask about cash, inventory, or GST for live data."

def handle_health():
    risks = []
    if df_ar is not None:
        overdue_90 = df_ar[df_ar["days_overdue"]>90]["outstanding"].sum()
        if overdue_90>50000: risks.append(("CRITICAL",f"Cash: Rs{overdue_90:,.0f} stuck in 90+ day overdue"))
    if df_inv is not None:
        latest   = df_inv[df_inv["snapshot_date"]==df_inv["snapshot_date"].max()]
        dead_val = latest[latest["is_dead_stock"]==1]["total_value_inr"].sum()
        total_val= latest["total_value_inr"].sum()
        dead_pct = dead_val/(total_val+1)*100
        if dead_pct>15: risks.append(("HIGH",f"Inventory: {dead_pct:.0f}% (Rs{dead_val:,.0f}) is dead stock"))
        rc = latest[latest["needs_reorder"]==1]["sku"].nunique()
        if rc>3: risks.append(("MEDIUM",f"Inventory: {rc} SKUs below reorder level"))
    if gst_summary:
        itc = gst_summary["total_itc_at_risk"]
        rate= gst_summary["mismatch_rate"]
        if itc>100000: risks.append(("MEDIUM",f"GST: Rs{itc:,.0f} ITC at risk ({rate}% mismatch rate)"))
    lines = ["NK PROTEIN — EXECUTIVE HEALTH CHECK","━"*40,"  Your biggest risks today:",""]
    if risks:
        for i,(level,desc) in enumerate(risks,1):
            lines.append(f"  {i}. [{level}] {desc}")
    else:
        lines.append("  No critical risks detected today.")
    lines += ["","Ask me to drill down:","  'Show me the cash risk'","  'Which inventory is dead stock?'","  'What is my GST liability?'","  'Predict next quarter sales'"]
    return "\n".join(lines)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/chat", methods=["POST"])
def chat():
    data    = request.get_json()
    message = data.get("message","").strip()
    if not message:
        return jsonify({"response":"Please type a question.","intent":"unknown"})
    intent = detect_intent(message)
    if   intent == "cash":      response = handle_cash(message)
    elif intent == "inventory": response = handle_inventory(message)
    elif intent == "gst":       response = handle_gst(message)
    elif intent == "sales":     response = handle_sales(message)
    elif intent == "health":    response = handle_health()
    else:
        response = "\n".join(["I can help you with:","","  Health Check  — 'What is my biggest risk today?'","  Sales         — 'Predict next quarter sales'","  Cash Flow     — 'Where is my cash trapped?'","  Inventory     — 'Show dead stock analysis'","  GST           — 'Any GST mismatches?'"])
    return jsonify({"response":response,"intent":intent})

@app.route("/status")
def status():
    return jsonify({"cashflow_model":cf_model is not None,"inventory_model":inv_model is not None,"gst_data":gst_summary is not None,"status":"ready"})

if __name__ == "__main__":
    print("Starting NK Protein AI...")
    print("Open browser: http://localhost:5000\n")
    app.run(debug=True, port=5000)