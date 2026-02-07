# Phase 8 - Lesson 1: Using Hugging Face (Building SLMs)

from transformers import pipeline

# ==========================================
# 1. HUGGING FACE (The GitHub of NLP)
# ==========================================
# Hugging Face hosts thousands of pretrained models (BERT, GPT-2, Llama, Mistral).
# The "pipeline" function is the easiest way to use them.

# ==========================================
# 2. SENTIMENT ANALYSIS
# ==========================================
print("--- 1. Sentiment Analysis ---")
classifier = pipeline("sentiment-analysis")
result = classifier("I absolutely loved this course! It was amazing.")
print(f"Result: {result}")

# ==========================================
# 3. TEXT GENERATION (Mini-LLM)
# ==========================================
print("\n--- 2. Text Generation (GPT-2) ---")
# GPT-2 is an older, smaller "SLM" (Small Language Model). 
# Good for demos, runs on CPU.
generator = pipeline("text-generation", model="gpt2")
output = generator("Artificial Intelligence is going to", max_length=30, num_return_sequences=1)

print(f"Prompt: 'Artificial Intelligence is going to...'")
print(f"Completion: {output[0]['generated_text']}")

# ==========================================
# 4. QUESTION ANSWERING
# ==========================================
print("\n--- 3. Question Answering ---")
qa_model = pipeline("question-answering")
context = "My name is Vishaka and I am learning NLP using Python."
question = "What is Vishaka learning?"

answer = qa_model(question=question, context=context)
print(f"Context: {context}")
print(f"Question: {question}")
print(f"Answer: {answer['answer']}")

# ==========================================
# NEXT STEPS
# ==========================================
# To build a custom bot, you would use libraries like 'LangChain' or 'LlamaIndex' 
# to connect these models to your own PDF data (RAG).
