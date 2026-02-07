# Phase 6 - Lesson 3: Encoder-Decoder Architecture

## The Generative Shift
Transformers essentially process text in two different modes.

### 1. The Encoder (e.g., BERT, RoBERTa)
- **Goal**: "Understand" the input.
- **Mechanism**: Bidirectional. It looks at the whole sentence at once (Left-to-Right AND Right-to-Left).
- **Use Cases**:
    - Classification (Sentiment Analysis).
    - Named Entity Recognition (Finding names/dates).
    - Question Answering (Finding the answer span in text).
- **Analogy**: A reader highlighting important parts of a book.

### 2. The Decoder (e.g., GPT-3, Llama)
- **Goal**: "Generate" the next word.
- **Mechanism**: Unidirectional (Causal). It can only see words to its *left*. It cannot cheat by looking at the future.
- **Use Cases**:
    - Text Generation (Writing stories).
    - Chatbots.
    - Code Completion.
- **Analogy**: A writer typing one word at a time.

### 3. Encoder-Decoder (e.g., T5, BART)
- **Goal**: Transform Text A to Text B.
- **Mechanism**: The Encoder reads the input (French), passes the "memory" to the Decoder, which generates the output (English).
- **Use Cases**:
    - Machine Translation.
    - Summarization.

## Summary Table
| Architecture | Example | Best For |
| :--- | :--- | :--- |
| **Encoder-Only** | BERT | Understanding, Search, Classification |
| **Decoder-Only** | GPT | Generation, Chat, Creativity |
| **Encoder-Decoder** | T5 | Translation, Summarization |
