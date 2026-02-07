# Phase 6 - Lesson 1: The Attention Mechanism

import numpy as np
import scipy.special

# ==========================================
# 1. THE CONCEPT: "Pay Attention"
# ==========================================
# When you translate "The big red dog", you don't look at all words equally at once.
# When writing "Le" (The), you look at "The".
# When writing "grand" (big), you look at "big".
# Attention allows the model to "focus" on relevant input words for each output step.

# ==========================================
# 2. SELF-ATTENTION (The Transformer Core)
# ==========================================
# "The animal didn't cross the street because it was too tired."
# What does "it" refer to?
# Attention connects "it" strongly to "animal".
# If the sentence was "too wide", "it" connects to "street".

# ==========================================
# 3. CODING ATTENTION (Simplified Q, K, V)
# ==========================================
# Q (Query): What am I looking for? (e.g., current word "it")
# K (Key): What do I have? (e.g., all other words offer their identity)
# V (Value): What information do I pass along?

print("--- Self-Attention Demo (NumPy) ---")

def self_attention(query, keys, values):
    # 1. Score: How relevant is every Key to the Query? (Dot Product)
    scores = np.dot(query, keys.T) 
    
    # 2. Normalize: Turn scores into probabilities (Softmax)
    # Higher score = More attention.
    weights = scipy.special.softmax(scores)
    
    # 3. Weighted Sum: Combine Values based on attention weights.
    # If I pay 90% attention to "animal", I take 90% of its Value vector.
    output = np.dot(weights, values)
    
    return output, weights

# Dummy Data (3 words, 4 dimensions each)
# Word 0: "The"
# Word 1: "animal"
# Word 2: "tired"
inputs = np.array([
    [1, 0, 1, 0], # The
    [0, 1, 0, 1], # animal
    [1, 1, 0, 0]  # tired
])

# In real transformers, Q, K, V are learned projections. Here we use inputs as is.
output, weights = self_attention(inputs, inputs, inputs)

print("\nAttention Weights (Who looks at whom?):")
print(weights)
# Row 0 shows how much "The" looks at ["The", "animal", "tired"].

print("\nOutput (Context-Assemblage):")
print(output)
# These new vectors now contain CONTEXT!
