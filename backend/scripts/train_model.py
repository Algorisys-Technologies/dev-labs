import pandas as pd
import numpy as np
import os
import pickle
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, confusion_matrix, classification_report
import matplotlib.pyplot as plt
import seaborn as sns

def preprocess_text(text):
    if not isinstance(text, str):
        return ""
    # Lowercase and strip
    return text.lower().strip()

def main():
    data_path = "backend/data/complex_emails.csv"
    if not os.path.exists(data_path):
        print(f"Error: {data_path} not found.")
        return

    df = pd.read_csv(data_path)
    print(f"Loaded {len(df)} High-Complexity samples.")

    # Preprocessing
    df['clean_text'] = df['text'].apply(preprocess_text)

    # Train/Test Split
    X_train, X_test, y_train, y_test = train_test_split(
        df['clean_text'], df['label'], test_size=0.15, random_state=42, stratify=df['label']
    )

    # TF-IDF Vectorization with N-Grams for better pattern matching
    vectorizer = TfidfVectorizer(
        stop_words='english', 
        max_features=10000, 
        ngram_range=(1, 3) # Include bigrams and trigrams for specific phrases
    )
    X_train_vec = vectorizer.fit_transform(X_train)
    X_test_vec = vectorizer.transform(X_test)

    # Train Logistic Regression with balanced weights
    model = LogisticRegression(random_state=42, max_iter=2000, class_weight='balanced')
    model.fit(X_train_vec, y_train)

    # Evaluate
    y_pred = model.predict(X_test_vec)
    acc = accuracy_score(y_test, y_pred)
    print(f"Accuracy: {acc:.4f}")
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred))

    # Confusion Matrix
    cm = confusion_matrix(y_test, y_pred)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                xticklabels=model.classes_, yticklabels=model.classes_)
    plt.xlabel('Predicted')
    plt.ylabel('Actual')
    plt.title('Confusion Matrix')
    
    os.makedirs("backend/ml_models", exist_ok=True)
    plt.savefig("backend/ml_models/confusion_matrix.png")
    print("Confusion matrix saved to backend/ml_models/confusion_matrix.png")

    # Save models
    with open("backend/ml_models/classifier.pkl", "wb") as f:
        pickle.dump(model, f)
    with open("backend/ml_models/vectorizer.pkl", "wb") as f:
        pickle.dump(vectorizer, f)

    print("Model and Vectorizer saved to backend/ml_models/")

if __name__ == "__main__":
    main()
