# Phase 2 - Lesson 2: TF-IDF

## Why Bag of Words Fails
If we are analyzing news articles.
- Word "The": Appears 10,000 times.
- Word "Terrorism": Appears 5 times.

In a simple counts model (BoW), "The" is considered the most important feature. 
But "Terrorism" is the word that actually tells us the topic!

## TF-IDF Formula
We want a score that rewards **Frequency** but penalizes **Commonality**.

**TF (Term Frequency)**: How often does the word appear in *this* document?
- Higher count = Higher importance.

**IDF (Inverse Document Frequency)**: How rare is the word across *all* documents?
- If a word appears in every document (like "the"), IDF is low (near 0).
- If a word appears in only one document, IDF is high.

**Score = TF * IDF**

## Intuition
- **High Score**: A word is frequent in *this* doc, but rare *elsewhere*. (e.g., "Galaxy" in an astronomy paper). **This is a Keyword.**
- **Low Score**: A word is frequent everywhere. (e.g., "is", "are"). **This is Noise.**

## Usage
TF-IDF is the gold standard for Classical NLP. It is used for:
- Search Engines (Matching query to documents).
- Keyword Extraction.
- Document Similarity.
