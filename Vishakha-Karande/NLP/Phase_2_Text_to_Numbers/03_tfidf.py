# Phase 2 - Lesson 2: TF-IDF (Term Frequency - Inverse Document Frequency)

from sklearn.feature_extraction.text import TfidfVectorizer
import pandas as pd

# ==========================================
# 1. THE PROBLEM WITH BoW
# ==========================================
# In Bag of Words, common words like "is", "good" might appear huge number of times.
# Rare, important words like "Defenestration" appear once.
# If we just count, the common words dominate.
# We want to DOWN-WEIGHT common words and UP-WEIGHT rare words.

corpus = [
    "The car is fast.",
    "The car is red.",
    "The car is expensive and fast."
]

# ==========================================
# 2. IMPLEMENTATION
# ==========================================
# TF: Term Frequency (How often word appears in THIS document)
# IDF: Inverse Document Frequency (log(Total Docs / Docs with this word))
# TF-IDF = TF * IDF

vectorizer = TfidfVectorizer()
X = vectorizer.fit_transform(corpus)

# ==========================================
# 3. VISUALIZATION
# ==========================================
print("--- TF-IDF Matrix ---")
df = pd.DataFrame(X.toarray(), columns=vectorizer.get_feature_names_out())
print(df)

# Observe "The", "car", "is". 
# They appear in ALL documents. Their IDF is Low (near 0).
# So their TF-IDF score is Low.
# "Red" appears in ONLY ONE document. Its IDF is High.
# So "Red" gets a high score. It is a "signature" word for Document 2.
