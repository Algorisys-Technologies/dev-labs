# Phase 3 - Lesson 1: NLP Classification (Spam Filter)

from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

# ==========================================
# 1. THE DATASET
# ==========================================
# (Text, Label) -> 1 = Spam, 0 = Ham (Good)
data = [
    ("Free money!!! Win cash now", 1),
    ("Hi, how are you doing today?", 0),
    ("Cheap Rolex watches for sale", 1),
    ("Meeting at 3 PM, don't be late", 0),
    ("Congratulations, you won a lottery!", 1),
    ("Can we catch up later?", 0)
]

# Separate Texts and Labels
texts = [row[0] for row in data]
labels = [row[1] for row in data]

# ==========================================
# 2. PREPROCESSING (Vectorization)
# ==========================================
# Computers need numbers. We use Bag of Words.
vectorizer = CountVectorizer()
X = vectorizer.fit_transform(texts)
y = labels

# Start Training
print("--- Training Naive Bayes Model ---")

# ==========================================
# 3. THE MODEL (Naive Bayes)
# ==========================================
# Naive Bayes is the classic algorithm for Text Classification.
# It uses probability: P(Spam | Word="Free")
model = MultinomialNB()
model.fit(X, y)

# ==========================================
# 4. PREDICTION
# ==========================================
new_emails = [
    "Win free cash prizes!",
    "Hey, are we still meeting for lunch?"
]

# CRITICAL: We must transform new data using the SAME vectorizer (vocabulary)
# Do NOT call fit_transform() here, only transform().
X_new = vectorizer.transform(new_emails)

predictions = model.predict(X_new)

for text, pred in zip(new_emails, predictions):
    label = "SPAM" if pred == 1 else "HAM"
    print(f"Text: '{text}' -> Prediction: {label}")
