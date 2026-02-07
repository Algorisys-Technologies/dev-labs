# Phase 6 - Lesson 2: Positional Encoding (Math of Order)

import numpy as np
import matplotlib.pyplot as plt

# ==========================================
# 1. THE PROBLEM
# ==========================================
# Transformers process all words at once (Parallel).
# They don't know that "Man" comes before "Bites".
# We must INJECT position info into the vectors.

# ==========================================
# 2. THE FORMULA (Sine & Cosine)
# ==========================================
# PE(pos, 2i) = sin(pos / 10000^(2i/d_model))
# PE(pos, 2i+1) = cos(pos / 10000^(2i/d_model))
# Don't panic. It just creates a unique "signature" for each position.

def get_positional_encoding(max_len, d_model):
    pos_enc = np.zeros((max_len, d_model))
    
    for pos in range(max_len):
        for i in range(0, d_model, 2):
            denominator = 10000 ** (2 * i / d_model)
            
            pos_enc[pos, i] = np.sin(pos / denominator)
            if i + 1 < d_model:
                pos_enc[pos, i + 1] = np.cos(pos / denominator)
                
    return pos_enc

# ==========================================
# 3. VISUALIZATION
# ==========================================
# Let's generate encodings for sentence with 50 words, vector size 128
max_len = 50
d_model = 128

pe = get_positional_encoding(max_len, d_model)

print("--- Plotting Positional Encodings ---")
plt.figure(figsize=(10, 6))
plt.imshow(pe, cmap='hot', aspect='auto')
plt.xlabel("Vector Dimension (0-128)")
plt.ylabel("Word Position (0-50)")
plt.colorbar(label="Added Value")
plt.title("Positional Encoding Matrix")
plt.show()

# INTUITION:
# Look at the waves. 
# Position 1 has a different wave pattern than Position 20.
# The Model adds this wave to the Word Embedding.
# Word + Wave = Position-Aware Word.
