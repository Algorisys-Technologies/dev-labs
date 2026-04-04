import pandas as pd
import pickle
import os
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report

def check_v13():
    model_path = "backend/ml_models/classifier.pkl"
    vec_path = "backend/ml_models/vectorizer.pkl"
    data_path = "backend/data/complex_emails.csv"
    
    if not os.path.exists(model_path):
        print("❌ Model not found.")
        return
        
    with open(model_path, 'rb') as f:
        model = pickle.load(f)
    with open(vec_path, 'rb') as f:
        vectorizer = pickle.load(f)
        
    df = pd.read_csv(data_path)
    X = vectorizer.transform(df['text'].apply(lambda x: str(x).lower()))
    y = df['label']
    
    y_pred = model.predict(X)
    acc = accuracy_score(y, y_pred)
    
    print("="*60)
    print(f"🚀 NEURAL AUDIT (v13): {acc*100:.2f}% Accuracy Verified.")
    print("="*60)
    print(classification_report(y, y_pred))
    
    if acc > 0.98:
        print("✅ BOARDROOM READY: 98%+ Accuracy achieved for v13.")
    else:
        print("⚠️  WEAK SIGNAL: Accuracy below 98%. Neural hardening recommended.")

if __name__ == "__main__":
    check_v13()
