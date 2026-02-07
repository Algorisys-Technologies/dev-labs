# Phase 1 - Lesson 3: Advanced Preprocessing: Stopwords, Stemming, and Lemmatization

import nltk
from nltk.corpus import stopwords
from nltk.stem import PorterStemmer, WordNetLemmatizer

# ==========================================
# 0. SETUP: DOWNLOAD NLTK DATA
# ==========================================
# NLTK needs us to download the specific resources we want to use.
# If you get a "LookupError", uncomment these lines and run them once:
# nltk.download('stopwords')
# nltk.download('wordnet')
# nltk.download('omw-1.4')

# ==========================================
# 1. STOPWORD REMOVAL
# ==========================================
# Concept: Remove common words like "the", "is", "at" that don't add unique meaning.
# Why: They are just noise for many tasks (e.g., topic classification).

print("--- 1. Stopword Removal ---")
text = "This is a sample sentence, showing off the stop words filtration."
words = text.split()

# Get the list of English stopwords
stop_words = set(stopwords.words('english'))
print(f"Sample Stopwords: {list(stop_words)[:10]}...")

# Filter the list
filtered_words = [w for w in words if w.lower() not in stop_words]

print(f"Original: {words}")
print(f"Filtered: {filtered_words}")
# Notice "is", "a", "the" are gone.


# ==========================================
# 2. STEMMING (The "Chopper")
# ==========================================
# Concept: Chop off the ends of words to get to the root.
# Examples: "running" -> "run", "cats" -> "cat", "better" -> "better" (sometimes it fails)
# Pros: Fast. Cons: Can produce non-words ("univers" instead of "universe").

print("\n--- 2. Stemming (Porter Stemmer) ---")
stemmer = PorterStemmer()

words_to_stem = ["running", "jumps", "easily", "fairly"]
stemmed_words = [stemmer.stem(w) for w in words_to_stem]

print(f"Original: {words_to_stem}")
print(f"Stemmed : {stemmed_words}")
# "easily" -> "easili" (not a real word, but maps to the same root for the model)


# ==========================================
# 3. LEMMATIZATION (The "Linguist")
# ==========================================
# Concept: Reduce words to their base form (Lemma) using a dictionary.
# Examples: "running" -> "run", "better" -> "good".
# Pros: Produces real words. Cons: Slower than stemming.

print("\n--- 3. Lemmatization (WordNet) ---")
lemmatizer = WordNetLemmatizer()

words_to_lemmatize = ["running", "jumps", "easily", "better"]
lemmatized_words = [lemmatizer.lemmatize(w, pos='v') for w in words_to_lemmatize]

# Note: pos='v' tells the lemmatizer to treat the word as a VERB. 
# Without it, "better" might not change.

print(f"Original  : {words_to_lemmatize}")
print(f"Lemmatized: {lemmatized_words}")
# "better" -> "good" (Stemming can't do this!)

# ==========================================
# SUMMARY
# ==========================================
# - Stopwords: Remove common filler.
# - Stemming: Crude chop (fast, aggressive).
# - Lemmatization: Dictionary lookup (accurate, slower).
