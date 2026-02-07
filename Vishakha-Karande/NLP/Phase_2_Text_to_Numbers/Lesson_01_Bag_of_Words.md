# Phase 2 - Lesson 1: Bag of Words (BoW)

## The Problem
We have clean tokens. Now we need numbers.

## The Solution: One-Hot Encoding?
Imagine we have a vocabulary of 3 words: `["Apple", "Banana", "Cat"]`.
- Apple = `[1, 0, 0]`
- Banana = `[0, 1, 0]`
- Cat = `[0, 0, 1]`

This works for single words. But for sentences?

## The Bag of Words (BoW) Model
We represent a sentence as a **Frequency Count** of its words.

### Example
Corpus (All known words): `["AI", "Learning", "Love"]`

Sentence 1: "I Love AI"
- AI: 1
- Learning: 0
- Love: 1
- **Vector**: `[1, 0, 1]`

Sentence 2: "AI Learning AI"
- AI: 2
- Learning: 1
- Love: 0
- **Vector**: `[2, 1, 0]`

## Why "Bag"?
Because we lose the **structure**.
"The dog bit the man" and "The man bit the dog" have the **exact same BoW vector**.
This is a major limitation! (We will fix this in Phase 4 & 5).

## The Code
We use `sklearn.feature_extraction.text.CountVectorizer`.
It automatically:
1.  Lowercases.
2.  Tokenizes.
3.  Builds the Vocabulary.
4.  Counts frequencies.
