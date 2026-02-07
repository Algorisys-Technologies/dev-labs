# Phase 2 - Lesson 1: Bag of Words (BoW)

from sklearn.feature_extraction.text import CountVectorizer

# ==========================================
# 1. THE CONCEPT
# ==========================================
# We need to convert Text -> Numbers.
# Bag of Words is the simplest method.
# It counts how many times each word appears.
# It ignores ORDER (grammar). It just cares about "bag" of words.

corpus = [
    "I love AI.",           # Document 1
    "I love NLP.",          # Document 2
    "AI is the future."     # Document 3
]

# ==========================================
# 2. IMPLEMENTATION (Scikit-Learn)
# ==========================================
# We use CountVectorizer. It does:
# 1. Tokenization
# 2. Vocabulary Building
# 3. Encoding

vectorizer = CountVectorizer()

# Fit (Learn Vocabulary) and Transform (Convert to Numbers)
X = vectorizer.fit_transform(corpus)

# ==========================================
# 3. INSPECTING THE RESULT
# ==========================================
print("--- Vocabulary (Word -> Index) ---")
print(vectorizer.vocabulary_)
# Output might look like: {'love': 3, 'ai': 0, ...}
# It maps each word to a column index in the matrix.

print("\n--- The Feature Names (Sorted) ---")
print(vectorizer.get_feature_names_out())
# ['ai', 'future', 'is', 'love', 'nlp', 'the']

print("\n--- The Vector Matrix ---")
# The output is a Sparse Matrix (stores only non-zeros to save memory).
# We convert to Array to see it clearly (don't do this for huge data!).
print(X.toarray())

# Interpretation:
# Row 1 ("I love AI"): [1, 0, 0, 1, 0, 0]  -> AI=1, Future=0, Is=0, Love=1...
# (Note: "I" is removed as a stopword by default or because it's too short?)
# Actually CountVectorizer default token pattern removes single characters like "I".
