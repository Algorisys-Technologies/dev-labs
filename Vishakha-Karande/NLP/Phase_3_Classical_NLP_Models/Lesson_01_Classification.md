# Phase 3 - Lesson 1: Classification Models

## The Goal
Text Classification is assigning a category to a piece of text.
- Spam vs. Ham
- Positive vs. Negative (Sentiment)
- Politics vs. Sports (News)

## The Pipeline
1.  **Input**: Raw Text.
2.  **Vectorization**: Convert to Numbers (Bag of Words or TF-IDF).
3.  **Model**: A Machine Learning algorithm that learns patterns in the numbers.
4.  **Output**: A Label (0 or 1).

## The Algorithm: Naive Bayes
Why "Naive"?
It assumes that every word is independent of every other word.
- It thinks "San" and "Francisco" are unrelated variables.
- Depending on the math, this is "naive".
- **BUT**: It works incredibly well for text.

## Why it works for Spam
- It calculates probabilities.
- `P(Space | "Free")` might be 80%.
- `P(Ham | "Meeting")` might be 99%.
- It multiplies these probabilities for the whole sentence to make a decision.

## Step-by-Step in Code
1.  `fit_transform(data)`: Learn vocabulary from training data.
2.  `model.fit(X, y)`: Train the model to associate words with labels.
3.  `transform(new_data)`: Convert new text to numbers using the *same* vocabulary.
4.  `model.predict(X_new)`: Ask the model for the answer.
