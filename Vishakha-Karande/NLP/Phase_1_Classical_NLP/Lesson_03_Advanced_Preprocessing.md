# Phase 1 - Lesson 3: Advanced Preprocessing

## Recap
In Lesson 2, we cleaned text using `lower()` and `regex`. But we still had issues like:
- "running" vs "run" (Morphology)
- "is", "the" (Useless common words)

Now, we introduce **NLTK (Natural Language Toolkit)** to solve these.

## 1. Stopwords
**Concept:** Words that are extremely common in a language but carry little specific meaning.
**Examples:** "the", "is", "in", "for", "where", "when", "to".

**Why remove them?**
- They take up space.
- In **Sentiment Analysis** ("I love this movie"), only "love" matters. "I", "this" are filler.
- In **Search Engines**, if you search for "The Matrix", you want results for "Matrix", not every page with "The".

## 2. Text Normalization: Stemming vs. Lemmatization
We want to treat "run", "runs", "running", and "ran" as the **same word**.
This reduces our vocabulary size and helps the model generalize.

### Option A: Stemming (The "Butcher")
- **How it works**: Just chops off the end of the word based on rules.
- **Example**: 
    - "fishing" -> "fish"
    - "fished" -> "fish"
    - "argument" -> "argu" (**Wait, that's not a word!**)
- **Pros**: Very fast. Simple.
- **Cons**: Often produces non-words.
- **Library**: `PorterStemmer` in NLTK.

### Option B: Lemmatization (The "Professor")
- **How it works**: Uses a dictionary (WordNet) to find the actual root form (Lemma).
- **Example**:
    - "better" -> "good" (Stemmer would fail here).
    - "rocks" -> "rock".
    - "corpora" -> "corpus".
- **Pros**: Accurate. Always meaningful words.
- **Cons**: Slower. Needs Part-of-Speech (POS) tags to work perfectly (e.g., knowing "better" is an adjective).
- **Library**: `WordNetLemmatizer` in NLTK.

## Setup Instructions (Important!)
You will likely see a `LookupError` when you run the code. This is normal!
NLTK is lightweight and doesn't come with all dictionaries pre-installed.
You need to run these commands once in your Python console:

```python
import nltk
nltk.download('stopwords')
nltk.download('wordnet')
nltk.download('omw-1.4')
```

## When to use which?
- **Stemming**: Used in search engines where speed is key and perfect grammar doesn't matter.
- **Lemmatization**: Used in chatbots or text generation where the output must be a valid word.
