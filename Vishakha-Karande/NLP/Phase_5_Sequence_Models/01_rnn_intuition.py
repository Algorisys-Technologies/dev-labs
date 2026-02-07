# Phase 5 - Lesson 1: Recurrent Neural Networks (RNN/LSTM)

import numpy as np
# (We use pseudo-code/numpy for intuition because training a real RNN 
# requires PyTorch/TensorFlow, which is heavy for a single file demo).

# ==========================================
# 1. WHY SEQUENCE MATTERS
# ==========================================
# Standard Neural Networks (and Naive Bayes) look at inputs all at once.
# Text is different. Order changes meaning.
# "Dog bites Man" vs "Man bites Dog".

# ==========================================
# 2. RNN INTUITION (The "Memory" State)
# ==========================================
# An RNN processes words one by one.
# It maintains a "Hidden State" (Memory) that updates after every word.

words = ["The", "food", "was", "good"]

# Initialize Memory (Hidden State)
memory = "Neutral" 

print(f"Start Memory: {memory}")

for word in words:
    # Logic: Update memory based on current word + old memory
    if word == "The":
        memory = "Expecting Noun"
    elif word == "food":
        memory = "Subject is Food"
    elif word == "was":
        memory = "Waiting for Adjective"
    elif word == "good":
        # Combine "Subject is Food" + "Good" -> Positive Sentiment
        memory = "Positive Sentiment"
    
    print(f"Word: '{word}' -> New Memory: {memory}")

# Result: The final memory contains the "gist" of the whole sentence.

# ==========================================
# 3. THE VANISHING GRADIENT PROBLEM
# ==========================================
# If the sentence is huge: "The food [100 words...] was bad."
# Basic RNNs repeat the multiplication so many times that the signal "vanishes".
# It forgets the start of the sentence by the time it reaches the end.

# ==========================================
# 4. LSTM (Long Short-Term Memory)
# ==========================================
# LSTMs fix this by having a "Conveyor Belt" (Cell State) that lets information 
# flow through unchanged if needed.
# It has "Gates":
# - Forget Gate: What to throw away?
# - Input Gate: What to store?
# - Output Gate: What to tell the next step?

print("\n--- LSTM Concept ---")
print("Instead of just overwriting memory, an LSTM chooses what to keep.")
print("It can 'carry' the context of 'The food' across 100 words to link it with 'was bad'.")
