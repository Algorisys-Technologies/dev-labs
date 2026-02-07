# Phase 2 - Lesson 2: Sparse Vectors & Visualization

## What are Sparse Vectors?
In "Bag of Words", we created vectors like `[1, 0, 0, 1, ... 0]`.
- Most values are **0**.
- If you have 10,000 words in your vocabulary, and a sentence has 5 words, you have 9,995 zeros.
- This is called a **Sparse Vector**.

## Why Visualize?
We cannot "see" 10,000 dimensions.
We can only see 2D or 3D.
To understand if our model is learning, we use **Dimensionality Reduction** techniques like **PCA (Principal Component Analysis)** or **t-SNE**.
These squash the 10,000 dimensions down to X and Y coordinates so we can plot them.

## The Code (`02_visualization.py`)
We used PCA to plot sentences about "Food", "Sports", and "Tech".
- **Result**: You should see 3 separate groups of dots.
- This visually proves that the "numbers" we created actually capture the *meaning* (Topic) of the sentences.
