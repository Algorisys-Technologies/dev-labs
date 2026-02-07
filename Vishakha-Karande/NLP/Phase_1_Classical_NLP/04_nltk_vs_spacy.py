# Phase 1 - Lesson 4: NLTK vs spaCy (The Two Giants)

import nltk
import spacy
import time

# ==========================================
# 1. SETUP
# ==========================================
# Make sure you have spaCy installed: pip install spacy
# Make sure you have the English model: python -m spacy download en_core_web_sm

# We will compare the two libraries on a large text.
long_text = """
Natural Language Processing (NLP) is a subfield of linguistics, computer science, and artificial intelligence 
concerned with the interactions between computers and human language, in particular how to program computers 
to process and analyze large amounts of natural language data. The goal is a computer capable of "understanding" 
the contents of documents, including the contextual nuances of the language within them. The technology can then 
accurately extract information and insights contained in the documents as well as categorize and organize the documents themselves.
""" * 100 # Repeat to make it "large"

print("--- Comparing NLTK and spaCy Speed ---")

# ==========================================
# 2. NLTK (The Tool Builder)
# ==========================================
# NLTK is academic, granular, and great for learning.
# But it treats steps (tokenization, tagging) as separate function calls.

start_time = time.time()
nltk_tokens = nltk.word_tokenize(long_text)
nltk_time = time.time() - start_time
print(f"NLTK Tokenization Time: {nltk_time:.4f} seconds")
print(f"NLTK Token Count: {len(nltk_tokens)}")


# ==========================================
# 3. SPACY (The Industrial Engine)
# ==========================================
# spaCy is built for production. It does everything (tokenization, POS tagging, dependency parsing) 
# in ONE go when you call nlp(text). It is optimized for speed.

try:
    nlp = spacy.load("en_core_web_sm") # Load the small English model
    
    start_time = time.time()
    doc = nlp(long_text) # This runs the entire pipeline!
    spacy_time = time.time() - start_time
    
    print(f"spaCy Processing Time : {spacy_time:.4f} seconds")
    print(f"spaCy Token Count: {len(doc)}")
    
    # Bonus: spaCy gives us Attributes for free
    print("\n--- spaCy Features ---")
    sample_token = doc[0]
    print(f"Word: {sample_token.text}")
    print(f"Lemma: {sample_token.lemma_} (Auto-lemmatized!)")
    print(f"POS: {sample_token.pos_} (Part of Speech)")
    print(f"Is Stopword?: {sample_token.is_stop}")

except OSError:
    print("\n[ERROR] spaCy model not found.")
    print("Please run: python -m spacy download en_core_web_sm")

# ==========================================
# SUMMARY
# ==========================================
# NLTK: Great for teaching, experimenting with specific algorithms (Stemmers).
# spaCy: Great for building apps; fast, integrated, opinionated (only one way to do things).
