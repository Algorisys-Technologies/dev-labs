# Phase 1 - Lesson 4: NLTK vs spaCy

## The Two Main Libraries

When doing NLP in Python, you will encounter two main libraries.

### 1. NLTK (Natural Language Toolkit)
- **The "Academic" Library.**
- Created in 2001. Massive, covers everything.
- **Philosophy**: "Here are 5 different ways to do stemming. Choose one."
- **Pros**: 
    - Great for learning how algorithms work.
    - Has obscure linguistic tools.
- **Cons**: 
    - Slow. 
    - String-processing heavy (input is strings, output is strings).

### 2. spaCy
- **The "Industrial" Library.**
- Created in 2015. Modern, Cython-optimized.
- **Philosophy**: "Here is the ONE best way to do lemmatization. We implemented it for you."
- **Pros**:
    - Extremely fast.
    - Object-Oriented (input is string, output is a rich `Doc` object).
    - production-ready (used by companies).
- **Cons**:
    - Less flexible if you want to tweak the core algorithm.

## When to use which?
- **Learning / Research**: Use **NLTK**.
- **Building a Product / App**: Use **spaCy**.

## This Course
We used NLTK for the basics (Lessons 1-3) because it exposes the *steps* clearly.
Moving forward, especially for **Vectorization** and **Pipelines**, we will use **Scikit-Learn** and **spaCy** because they are standard for building models.
