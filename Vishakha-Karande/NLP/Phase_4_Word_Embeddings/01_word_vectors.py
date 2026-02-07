# Phase 4 - Lesson 1: Word Embeddings (Word2Vec / GloVe)

import spacy
import numpy as np

# ==========================================
# 0. SETUP
# ==========================================
# We need a model that HAS vectors. 
# 'en_core_web_sm' (Small) does NOT have good vectors.
# You need 'en_core_web_md' (Medium).
# Run in terminal: python -m spacy download en_core_web_md

print("Loading model... (This might take a moment)")
try:
    nlp = spacy.load("en_core_web_md")
except OSError:
    print("Downloading 'en_core_web_md' model...")
    # Fallback to sm if md not present (but results will be bad)
    nlp = spacy.load("en_core_web_sm")
    print("WARNING: Using small model. Vectors will be meaningless. Please install en_core_web_md.")

# ==========================================
# 1. WHAT IS A VECTOR?
# ==========================================
# A vector is a list of numbers representing the word's meaning in a multi-dimensional space.
word = "king"
vector = nlp(word).vector

print(f"\n--- Vector for '{word}' ---")
print(f"Shape: {vector.shape} (Dimensions)") 
print(f"First 10 values: {vector[:10]}")

# ==========================================
# 2. SIMILARITY (Cosine Similarity)
# ==========================================
# Words with similar meanings have vectors that point in similar directions.
token1 = nlp("king")
token2 = nlp("queen")
token3 = nlp("apple")

print("\n--- Similarity Scores (0 to 1) ---")
print(f"{token1.text} <-> {token2.text}: {token1.similarity(token2):.4f}")
print(f"{token1.text} <-> {token3.text}: {token1.similarity(token3):.4f}")

# Expect "king" and "queen" to have HIGH similarity (~0.7).
# Expect "king" and "apple" to have LOW similarity (~0.1).

# ==========================================
# 3. VECTOR ARITHMETIC (King - Man + Woman = ?)
# ==========================================
# This is the magic of embeddings. We can do math on meaning.
# Target: King - Man + Woman should result in a vector close to Queen.

# Note: Spacy vectors are static, so we can't query "closest word" efficiently without extra code.
# But we can calculate the vector manually.

vec_king = nlp("king").vector
vec_man = nlp("man").vector
vec_woman = nlp("woman").vector

target_vector = vec_king - vec_man + vec_woman

# Calculate similarity of this new vector to "queen"
vec_queen = nlp("queen").vector

# Manually calc Cosine Similarity
similarity = np.dot(target_vector, vec_queen) / (np.linalg.norm(target_vector) * np.linalg.norm(vec_queen))
print(f"\n--- Vector Arithmetic ---")
print(f"(King - Man + Woman) similarity to Queen: {similarity:.4f}")
