# Phase 4 - Lesson 1: Word Embeddings & Semantics

## The Problem with One-Hot / Bag of Words
In Phase 2, we represented words as counts.
- "King" and "Queen" were just two different columns.
- The computer had **no idea** they were related.
- "Cat" and "Dog" were as different as "Cat" and "Refrigerator".

## The Solution: Dense Vectors (Embeddings)
Instead of a mostly-empty array (Sparse), we use a smaller, dense array of numbers (e.g., 300 numbers).
These numbers are **learned** by a neural network by reading billions of sentences.

### How it works (Intuition)
Imagine a graph.
- **Dimension 1**: "Royalty" (King is high, Peasant is low).
- **Dimension 2**: "Gender" (King is male, Queen is female).
- **Dimension 3**: "Edibility" (Apple is high, King is low).

In fit 300-dimensional space, words that share context (like "Coffee" and "Tea") end up **close together**.

## Key Concepts
1.  **Word2Vec**: Google's algorithm (2013) that revolutionized NLP. It used a simple neural net to predict surrounding words.
2.  **GloVe (Global Vectors)**: Stanford's algorithm based on global counts.
3.  **Cosine Similarity**: The metric used to measure distance.
    - 1.0 = Same direction (Synonyms)
    - 0.0 = 90 degrees (Unrelated)
    - -1.0 = Opposite direction (Antonyms)

## Vector Arithmetic
The most famous example:
$$ \text{King} - \text{Man} + \text{Woman} \approx \text{Queen} $$
This proves the model learned the **concept** of gender and royalty!
