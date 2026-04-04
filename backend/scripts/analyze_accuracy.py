import pandas as pd
import numpy as np
import os
import pickle
import sys

# Ensure backend can be imported
sys.path.append(os.getcwd())

from backend.extractor import extract_po_details
from backend.classifier import classifier

def analyze_ml_accuracy():
    print("--- PHASE 1: ML CLASSIFICATION AUDIT ---")
    data_path = os.path.abspath("backend/data/complex_emails.csv")
    if not os.path.exists(data_path):
        print(f"Error: No training data found at {data_path} for audit.")
        return

    df = pd.read_csv(data_path).sample(1000, random_state=42) # Audit 1000 random samples
    
    y_true = df['category']
    y_pred = []
    confidences = []

    for text in df['text']:
        cat, conf = classifier.predict(text)
        y_pred.append(cat)
        confidences.append(conf)

    from sklearn.metrics import classification_report
    print(classification_report(y_true, y_pred))
    print(f"Average Confidence Score: {np.mean(confidences):.4f}")
    
    # Feature Importance (Top Words)
    vectorizer = classifier.vectorizer
    model = classifier.model
    feature_names = vectorizer.get_feature_names_out()
    
    print("\n--- TOP DETERMINISTIC SIGNALS (SIGNAL DENSITY) ---")
    for i, category in enumerate(model.classes_):
        top_indices = np.argsort(model.coef_[i])[-10:]
        top_words = [feature_names[idx] for idx in top_indices]
        print(f"[{category}]: {', '.join(top_words)}")

def analyze_extraction_robustness():
    print("\n--- PHASE 2: SEMANTIC EXTRACTION AUDIT ---")
    test_cases = [
        # Case 1: Axis Auto Style (Complex)
        """URGENT: PO Release for April Production Batch | Ref: APR-PROD-77
Dear Vendor,
Following our discussion with the production and maintenance teams, we are releasing the below purchase order for immediate processing.

PO Number: PO-APR-2026-7781
Release Date: 03-Apr-2026
Priority: High

Plant Location: Unit 4, Chakan MIDC, Pune

1) Item: Forged Crankshaft Assembly  
   Qty: 120 Units  
2) Item: High-Pressure Fuel Pump  
   Qty: 75 Units  
3) Item: Engine Mount Bracket  
   Qty: 200 Units
""",
        
        # Case 2: Minimalist Raw
        "PO: REF-88 | Loc: Mumbai | Goods: Solar Inverter | Qty: 10",
        
        # Case 3: Block Style
        """Purchase Order No: PUR-552
        Address: Sector 18, Mumbai
        
        Forged Steel Block -- Qty 500
        Aluminum Housing -- Qty 200"""
    ]

    for i, text in enumerate(test_cases):
        data = extract_po_details(text)
        print(f"\n[Test Case {i+1}]:")
        print(f"  PO ID: {data['po_number']}")
        print(f"  Item(s): {data['item_name']} (Total Qty: {data['quantity']})")
        print(f"  Location: {data['location']}")
        print(f"  Accuracy Check: {'PASS' if data['po_number'] != 'UNKNOWN' and data['quantity'] > 0 else 'FAIL'}")

if __name__ == "__main__":
    analyze_ml_accuracy()
    analyze_extraction_robustness()
