# Phase 5 - Lesson 2: Next Word Prediction (N-Gram / Markov Chain)

import random

# ==========================================
# 1. THE DATA
# ==========================================
text = """
The cat sat on the mat.
The cat sat on the hat.
The dog sat on the log.
The dog ran to the park.
The cat ran to the mat.
"""

# ==========================================
# 2. TRAINING (Building the Table)
# ==========================================
# We want to learn: Given a word, what comes next?
# "The" -> ["cat", "dog", "cat", "dog", "cat"]
# "cat" -> ["sat", "sat", "ran"]

chain = {}
words = text.split()

for i in range(len(words) - 1):
    current_word = words[i]
    next_word = words[i+1]
    
    if current_word not in chain:
        chain[current_word] = []
    
    chain[current_word].append(next_word)

print("--- The Brain (Markov Chain) ---")
print(f"'The' leads to: {chain.get('The')}")
print(f"'sat' leads to: {chain.get('sat')}")

# ==========================================
# 3. GENERATION
# ==========================================
print("\n--- Generating New Text ---")

start_word = "The"
generated_sentence = [start_word]

current_word = start_word
for i in range(10): # Generate 10 words
    possible_next_words = chain.get(current_word)
    
    if not possible_next_words:
        break # Dead end
        
    # Pick one randomly based on probability
    next_word = random.choice(possible_next_words)
    generated_sentence.append(next_word)
    current_word = next_word

print(" ".join(generated_sentence))

# This is the "Grandfather" of LLMs. 
# ChatGPT does this, but looks back at 4000+ words, not just 1.
