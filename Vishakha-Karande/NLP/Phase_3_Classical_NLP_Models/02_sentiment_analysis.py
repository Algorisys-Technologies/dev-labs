# Phase 3 - Lesson 2: Sentiment Analysis (Simple)

from sklearn.feature_extraction.text import CountVectorizer
from sklearn.linear_model import LogisticRegression

# ==========================================
# 1. TRAINING DATA
# ==========================================
# 1 = Positive, 0 = Negative
train_data = [
    ("I love this movie", 1),
    ("This is the best food ever", 1),
    ("Fantastic experience", 1),
    ("I hate this", 0),
    ("Disgusting food", 0),
    ("Terrible service", 0),
    ("Not good at all", 0),
    ("Really great and fun", 1)
]

# Split X and y
X_train_text = [row[0] for row in train_data]
y_train = [row[1] for row in train_data]

# ==========================================
# 2. PIPELINE
# ==========================================
# 1. Convert Text -> Numbers (BoW)
# 2. Train Model (Logistic Regression)

vectorizer = CountVectorizer()
X_train = vectorizer.fit_transform(X_train_text)

model = LogisticRegression()
model.fit(X_train, y_train)

print("--- Sentiment Analysis Model Trained ---")

# ==========================================
# 3. TEST
# ==========================================
test_sentences = [
    "I love Python",
    "This is terrible",
    "The movie was not good", # Tricky! "not" logic is hard for BoW.
    "The movie was not bad"  # Very Tricky!
]

X_test = vectorizer.transform(test_sentences)
predictions = model.predict(X_test)

for text, pred in zip(test_sentences, predictions):
    sentiment = "POSITIVE" if pred == 1 else "NEGATIVE"
    print(f"Text: '{text}' -> {sentiment}")

# Note on "Not Good":
# Bag of Words sees "not" and "good". 
# If "good" is very positive in training, "not good" might still be predicted Positive.
# This shows the limitation of Phase 3 models. (Phase 5/LSTM fixes this).
