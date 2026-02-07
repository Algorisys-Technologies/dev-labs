# Phase 8 - Lesson 2: Building Real World Apps

## Small Language Models (SLMs)
Not everyone needs a 1 Trillion parameter model (GPT-4).
For tasks like "Summarize my emails" or "Extract invoice data", a small model (Mistral 7B, Llama 3 8B) is better.
- **Cheaper**: Runs on a single GPU or even CPU.
- **Privacy**: Data never leaves your server.
- **Fast**: low latency.

## Fine-Tuning vs. RAG

### 1. RAG (Retrieval Augmented Generation)
**The "Open Book" Exam.**
Instead of retraining the model, you give it the answer in the prompt.
- User: "What is my leave balance?"
- System: (Searches Database) -> Finds "12 days".
- System Prompts LLM: "Context: Leave balance is 12 days. Question: What is my leave balance?"
- LLM: "You have 12 days left."

**Use RAG when:** You need up-to-date facts or proprietary data.

### 2. Fine-Tuning
**The "Medical School" Approach.**
You change the model's weights to teach it a specific *style* or *language*.
- Example: Teaching a model to speak Medical English instead of Regular English.
- **PEFT / LoRA**: Techniques to fine-tune only 1% of the parameters, making it possible on consumer hardware.

## Final Project Idea
Build a **PDF Chatbot**:
1.  Python script reads a PDF.
2.  Splits text into chunks.
3.  Creates Embeddings (Phase 4).
4.  Stores in a Vector DB (FAISS/Chroma).
5.  On Question -> Finds relevant chunks -> Sends to LLM -> Getting Answer.
