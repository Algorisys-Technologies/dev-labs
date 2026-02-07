# Phase 1 - Lesson 2: Text Preprocessing Steps

## Recap of Lesson 1
We learned that computers need numbers, and raw text is too noisy to convert directly. Now we will fix the noise.

## The 3-Step Cleaning Pipeline

### Step 1: Lowercasing 
**Concept**: Convert all characters to lowercase.
**Why**: To ensure "Apple" and "apple" are treated as the same word.
**Code**: `text.lower()`

### Step 2: Noise Removal (Regex)
**Concept**: Use pattern matching to remove unwanted characters.
**Tool**: We use the Python `re` library (Regular Expressions).
**The Pattern**: `[^a-zA-Z]`
- `[]` denotes a set of characters.
- `^` inside the brackets means "NOT".
- `a-z` is all lowercase letters.
- `A-Z` is all uppercase letters.
- **Translation**: "Find any character that is NOT a letter, and replace it." (Usually with a space).

**Why Space?**: If we replace with empty string `""`, then "Hello,World" becomes "HelloWorld" (merged). We want "Hello World".

### Step 3: Tokenization
**Concept**: Breaking a stream of text into meaningful units (Tokens).
**Intuition**:
- A sentence is a train.
- Tokenization uncouples the cars (words) so we can rearrange or analyze them individually.
- **Words** are the most common tokens (e.g., "hello", "world").
- **Sub-words** are chunks of words (e.g., "run", "ning") - used in LLMs (Phase 6).

### Limitations of this "Manual" Approach
In `02_preprocessing.py`, we used simple Python rules.
- **Issue**: "It's" became "it", "s". (We lost the meaning of "is").
- **Issue**: "New York" is two tokens "new", "york". (Ideally, it should be one entity).

**Next (Lesson 3)**: We will learn how to handle Stopwords ("is", "the") and Morphology ("running" -> "run").
