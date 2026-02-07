# Phase 6 - Lesson 2: Query, Key, Value (QKV)

## The Core of Attention
The "Self-Attention" mechanism is arguably the most important concept in modern AI.
It uses three vectors for *every* word: **Query (Q)**, **Key (K)**, and **Value (V)**.

### The Search Engine Analogy
Imagine you are looking for a video on YouTube.
1.  **Query (Q)**: What you type in the search bar. ("Funny cat video")
2.  **Key (K)**: The video titles/tags in the database. ("Cat jumps", "News", "Cooking")
3.  **Value (V)**: The actual video content.

### The Process
1.  **Match Q to K**: The model calculates a "match score" (Dot Product) between your Query and every Key.
    - "Funny cat" matches "Cat jumps" (High Score).
    - "Funny cat" matches "Cooking" (Low Score).
2.  **Softmax**: Convert scores to probabilities (weights). (e.g., 90% Cat, 1% Cooking).
3.  **Weighted Sum of V**: The model retrieves 90% of the "Cat Video" content and 1% of the "Cooking Video" content.
4.  **Result**: A new representation of the word that is a mixture of all relevant information found.

### Why 3 Vectors?
It gives the model flexibility.
- The word "Bank" might have a **Key** that says "I am a place for money".
- But if the context (Query) is "River", it won't match.
- By separating Q, K, and V, the model learns complex relationships.
