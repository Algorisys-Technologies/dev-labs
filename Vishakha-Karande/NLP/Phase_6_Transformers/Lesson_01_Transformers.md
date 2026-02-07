# Phase 6 - Lesson 1: Transformers (The Revolution)

## Pre-2017 Era
RNNs and LSTMs were King.
But they were slow (sequential processing) and struggled with really long context.

## 2017: "Attention Is All You Need"
Google published the Transformer paper. It changed everything.

## Key Innovation: Self-Attention
Instead of processing words 1-by-1, the Transformer looks at the **entire sentence at once**.
For every word, it calculates: *"How much does this word relate to every other word?"*

### Query, Key, Value (Q, K, V) Analogy
Think of a Filing Cabinet (Database).
- **Query**: The sticky note you are holding ("What is the address?").
- **Key**: The labels on the folders ("Tax", "Address", "Receipts").
- **Value**: The content inside the folder.
- **Attention**: You match your **Query** to the **Key** (Address) and extract the **Value**.

## Encoder vs. Decoder
1.  **Encoder (BERT)**: Reads text and understands it. Great for Classification, Q&A.
    - Example: "Classify this email."
2.  **Decoder (GPT)**: Generates text. It can't see the future words (Masked).
    - Example: "Write a poem."
3.  **Encoder-Decoder (T5, Bart)**: Reads input, generates output.
    - Example: Translation.

## Why are they "Large"?
Because they stack these attention layers 96+ times (GPT-4) and train on the whole internet.
