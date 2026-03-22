# NK Protein AI Command Center — Setup Guide

## Step-by-Step to Run

### 1. Install dependencies
```bash
pip install -r requirements.txt
```

### 2. Generate dummy data (run ONCE)
```bash
python generate_data.py
```
This creates 4 CSV files in the /data folder:
- data/sales_history.csv    (~2,200 rows)
- data/ar_aging.csv         (~600 rows)
- data/inventory.csv        (~500 rows)
- data/gst_data.csv         (~2,000 rows)

### 3. Start the Flask server
```bash
python app.py
```

### 4. Open the chatbot UI
Open your browser and go to: http://localhost:5000

---

## Demo Questions (CMD Happy Path)

**Health Check:**
- "What is my biggest risk today?"

**Sales Forecast:**
- "Predict next quarter sales forecast"
- "Which products should we discontinue?"
- "Which products should we promote?"

**Cash Flow:**
- "Where is my cash trapped?"
- "Show me overdue receivables"
- "Cash flow next 30 days"

**Inventory:**
- "Show dead stock analysis"
- "What inventory needs reorder?"
- "How much capital is blocked in inventory?"

**GST:**
- "Are there any GST mismatches?"
- "What is my tax liability for Q3?"
- "Show GSTR-2B reconciliation"

---

## Models Used
- **Prophet** (Meta): Time-series sales forecasting
- **XGBoost**: Feature-based revenue prediction (with regularization to prevent overfitting)
- **Random Forest**: AR payment risk classification
- Validation: TimeSeriesSplit (5-fold cross-validation) — prevents data leakage