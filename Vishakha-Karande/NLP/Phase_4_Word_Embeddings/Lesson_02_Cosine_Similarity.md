# Phase 4 - Lesson 2: Cosine Similarity

## The Math of Meaning
How do we know if "King" and "Queen" are similar?
We calculate the **Angle** between their vectors.

### Euclidean Distance vs. Cosine Similarity
- **Euclidean Distance**: Measures the straight-line distance.
    - Problem: If a document is just longer (more words), the vector magnitude grows, pushing it "far away" even if the topic is the same.
- **Cosine Similarity**: Measures the **direction**.
    - If two vectors point in the same direction, Angle = 0, Cosine = 1.
    - If they form a 90-degree angle, Cosine = 0 (Unrelated).
    - If they point opposite, Cosine = -1 (Opposite meaning).

$$ \text{Similarity} = \cos(\theta) = \frac{A \cdot B}{\|A\| \|B\|} $$

### Intuition
1.  **High Similarity (0.8 - 1.0)**: Synonyms or related words ("Car" & "Bus").
2.  **Low Similarity (0.0 - 0.2)**: Unrelated ("Car" & "Banana").
3.  **Negative Similarity**: Rarely happens in NLP, but implies opposite contexts in semantic space.

### In Code
We used `token.similarity(token)` in `01_word_vectors.py`.
Under the hood, spaCy performs this dot product calculation for you.
