# Phase 1 - Lesson 1: Introduction to NLP & The Need for Preprocessing

# ==========================================
# 1. WHAT IS NLP?
# ==========================================
# NLP (Natural Language Processing) is the field of AI that gives machines 
# the ability to read, understand, and derive meaning from human languages.

# Use Cases:
# - Translation (Google Translate)
# - Chatbots (Customer Service, ChatGPT)
# - Sentiment Analysis (Is this review positive or negative?)

# ==========================================
# 2. THE PROBLEM: COMPUTERS DON'T SPEAK ENGLISH
# ==========================================
# Computers are mathematical machines. They only understand numbers (0s and 1s).
# If you feed the word "Apple" to a math model, it errors out.
# We need to convert TEXT -> NUMBERS.

text = "Hello, NLP World! innovative"

# How a computer sees this string (Bytes/ASCII values):
# Each character corresponds to a number.
print(f"Original Text: {text}")
print(f"Computer representation (Bytes): {text.encode('utf-8')}")

# ==========================================
# 3. WHY preprocessing? (Intuition)
# ==========================================
# Raw text is "dirty" and inconsistent. 
# We need to standardize it so the model can learn patterns efficiently.

# Example A: Case Sensitivity
# To a computer, "Apple" and "apple" are completely different numbers.
word1 = "Apple"
word2 = "apple"
print(f"\n--- Case Sensitivity ---")
print(f"Is '{word1}' equal to '{word2}'? -> {word1 == word2}") 
# This is BAD. We want the model to know they are the same concept.
# FIX: Lowercasing
print(f"After lowercasing: {word1.lower() == word2.lower()}")

# Example B: Punctuation & Noise
# "World!" is different from "World". The exclamation mark makes it a unique token.
print(f"\n--- Punctuation Noise ---")
raw_token = "World!"
clean_token = "World"
print(f"Is '{raw_token}' equal to '{clean_token}'? -> {raw_token == clean_token}")
# FIX: We need to remove punctuation using cleaning techniques (Regex) - coming in Lesson 2.

# Example C: Variations of words (Morphology)
# "run", "running", "ran"
# These all mean the same action, but look different.
# FIX: Stemming/Lemmatization (Lesson 3).

# ==========================================
# 4. A SNEAK PEEK AT TOKENIZATION
# ==========================================
# We cannot process the whole sentence at once. We break it into chunks called "Tokens".
tokens = text.split() 
print(f"\nSimple Split Tokens: {tokens}")
# Notice "World!" has the punctuation attached. This is why simple .split() isn't enough.
