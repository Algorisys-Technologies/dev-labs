# Phase 5 - Lesson 1: Sequence Models (RNNs, LSTMs)

## The Limitation of Classical Models
Naive Bayes and Bag of Words treat a sentence as a **Pile of tokens**.
- They don't know "not good" is different from "good".
- They don't know word order.

## Recurrent Neural Networks (RNNs)
Idea: Process text **sequentially** (Time Step $t$).
1.  Read Word 1 ("The"). Update Memory.
2.  Read Word 2 ("Movie"). Update Memory (combining "The" + "Movie").
3.  Read Word 3 ("Sucked"). Update Memory.

At the end, the **Final Memory (Hidden State)** represents the whole sentence.

### The Problem: Short-Term Memory
RNNs are bad at long sentences.
*"The clouds in the sky [.... 50 words ....] are blue."*
By the time it gets to "are", it forgot "clouds" was plural. This is due to the **Vanishing Gradient** problem.

## LSTMs (Long Short-Term Memory)
Invented to fix RNNs.
They add a separate **Cell State** (Long-term memory).
They use **Gates** to control information flow:
1.  **Forget Gate**: "The context changed, forget the old subject."
2.  **Input Gate**: "This new word is important, save it."
3.  **Output Gate**: "Based on memory, predict the next word."

## GRUs (Gated Recurrent Units)
A simplified, faster version of LSTM. Used often today.

## Applications
- Machine Translation (Seq2Seq).
- Next Word Prediction (Smart Compose).
- Speech Recognition.
