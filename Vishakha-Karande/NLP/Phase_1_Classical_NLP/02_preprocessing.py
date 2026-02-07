# Phase 1 - Lesson 2: Text Preprocessing (Cleaning & Tokenization)

import re # "re" stands for Regular Expressions (a tool to find patterns in text)

# ==========================================
# 1. THE DIRTY INPUT
# ==========================================
# Real-world data is messy. It has punctuation, numbers, and weird symbols.
raw_text = "Good Morning! It's 7:00 AM. Time to learn NLP... #AI #MachineLearning"

print(f"Original Text: \n{raw_text}\n")


# ==========================================
# 2. LOWERCASING
# ==========================================
# WHY: "NLP" and "nlp" should be the same token.
# If we don't lowercase, the model learns two separate patterns for the same word.
text_lower = raw_text.lower()
print(f"Step 1 - Lowercasing: \n{text_lower}\n")


# ==========================================
# 3. NOISE REMOVAL (Regex)
# ==========================================
# WHY: Punctuation (.,!,#) and numbers (7:00) often don't carry *semantic* meaning 
# for simple tasks (like sentiment analysis). We want to remove them.

# We use "Regular Expressions" (Regex) to define what we want to KEEP.
# Pattern: "[^a-zA-Z]" 
# ^ means "NOT". 
# a-z means lowercase letters. 
# A-Z means uppercase letters.
# So this pattern means: "Replace anything that is NOT a letter with a space."

text_clean = re.sub(r"[^a-zA-Z]", " ", text_lower)
print(f"Step 2 - Cleaning Punctuation/Numbers (Regex): \n{text_clean}\n")
# Notice: "7:00" became "     " and "#AI" became " ai".


# ==========================================
# 4. TOKENIZATION
# ==========================================
# WHY: Computers process words (or sub-words), not whole sentences.
# We need to break the text into individual units called "tokens".

# Method A: Simple Split (by space)
# This is the most basic form of tokenization.
tokens = text_clean.split()
print(f"Step 3 - Tokenization (Result): \n{tokens}\n")

# Observe the result:
# ['good', 'morning', 'it', 's', 'am', 'time', 'to', 'learn', 'nlp', 'ai', 'machinelearning']

# Note: "It's" became "it" and "s". This is a side effect of removing the apostrophe using our simple regex.
# In advanced NLP (Lesson 4), we use tools like NLTK/spaCy to handle "It's" -> "It", "is" properly.
