import pickle
import os
import numpy as np

class EmailClassifier:
    def __init__(self, model_path="backend/ml_models/classifier.pkl", vectorizer_path="backend/ml_models/vectorizer.pkl"):
        self.model = None
        self.vectorizer = None
        
        if os.path.exists(model_path) and os.path.exists(vectorizer_path):
            with open(model_path, "rb") as f:
                self.model = pickle.load(f)
            with open(vectorizer_path, "rb") as f:
                self.vectorizer = pickle.load(f)
        else:
            print(f"Warning: Model paths not found: {model_path}, {vectorizer_path}")

    def predict(self, text):
        """
        Returns (category, confidence_score)
        """
        if not self.model or not self.vectorizer:
            return "Unknown", 0.0
        
        clean_text = text.lower().strip()
        vec = self.vectorizer.transform([clean_text])
        
        # Get category prediction
        prediction = self.model.predict(vec)[0]
        
        # Get confidence (probability)
        probs = self.model.predict_proba(vec)[0]
        max_prob = np.max(probs)
        
        return prediction, round(float(max_prob), 4)

# Singleton instance
classifier = EmailClassifier()
