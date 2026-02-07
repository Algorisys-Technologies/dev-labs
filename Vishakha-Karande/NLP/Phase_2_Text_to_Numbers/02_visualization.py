# Phase 2 - Lesson 3: Visualizing Text Vectors

import matplotlib.pyplot as plt
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.decomposition import PCA

# ==========================================
# 1. DATA
# ==========================================
# We have sentences about 3 topics: Food, Sports, Tech.
corpus = [
    # Food
    "I ate a delicious pizza",
    "The burger was tasty",
    "I love pasta and cheese",
    # Sports
    "The player scored a goal",
    "Football is a great sport",
    "The team won the match",
    # Tech
    "The computer memory is full",
    "Artificial Intelligence is future",
    "I code in Python"
]

labels = ["Food", "Food", "Food", "Sports", "Sports", "Sports", "Tech", "Tech", "Tech"]

# ==========================================
# 2. VECTORIZATION (TF-IDF)
# ==========================================
vectorizer = TfidfVectorizer()
X = vectorizer.fit_transform(corpus)
# X is a matrix of size (9 sentences, N words). E.g., (9, 25).
# We cannot visualize 25 dimensions. We can only see 2D or 3D.

# ==========================================
# 3. DIMENSIONALITY REDUCTION (PCA)
# ==========================================
# PCA (Principal Component Analysis) squashes High-Dimensions -> 2 Dimensions.
# It tries to keep "similar" points close together.

pca = PCA(n_components=2)
reduced_X = pca.fit_transform(X.toarray())

# reduced_X is now (9, 2). x and y coordinates.

# ==========================================
# 4. PLOTTING
# ==========================================
print("--- Plotting Vectors (Check the Popup Window) ---")

plt.figure(figsize=(8, 6))

# Zip together: x-coord, y-coord, and label
for i, label in enumerate(labels):
    x = reduced_X[i, 0]
    y = reduced_X[i, 1]
    
    # Color code
    if label == "Food": color = 'red'
    elif label == "Sports": color = 'blue'
    else: color = 'green'
    
    plt.scatter(x, y, c=color)
    plt.text(x+0.01, y, corpus[i], fontsize=9) # Print sentence near dot

plt.title("Text Clusters (PCA Visualization)")
plt.xlabel("Dimension 1")
plt.ylabel("Dimension 2")
plt.grid()
plt.show()

# EXPECTATION:
# You should see 3 distinct clusters. Red dots together, Blue together, Green together.
# This proves that our Vectors captured the meaningless of the sentences!
