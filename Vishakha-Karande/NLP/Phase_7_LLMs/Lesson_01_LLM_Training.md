# Phase 7 - Lesson 1: How LLMs are Trained

## The 3-Stage Training Pipeline of ChatGPT

### Stage 1: Pretraining (The "Reading" Phase)
**Goal**: Learn the statistical structure of language.
**Data**: The entire internet (Common Crawl, Books, Wikipedia).
**Task**: "Next Token Prediction".
- Input: "The cat sat on the..."
- Target: "mat".
**Result**: A "Base Model" (like GPT-3 Base). It can complete sentences but is wild/unpredictable. It doesn't follow instructions well.

### Stage 2: Supervised Fine-Tuning (SFT) (The "Instruction" Phase)
**Goal**: Teach the model to be an assistant.
**Data**: Human-written Q&A pairs.
- User: "Summarize this."
- Assistant: "Here is the summary..."
**Result**: An "Instruct Model". It follows orders but might be toxic or hallucinate.

### Stage 3: RLHF (Reinforcement Learning from Human Feedback)
**Goal**: Align with human values (Helpful, Honest, Harmless).
**Process**:
1.  Model generates 2 answers.
2.  Human ranks them: "A is better than B".
3.  A Reward Model learns this preference.
4.  PPO (Reinforcement Learning) optimizes the LLM to get high rewards.
**Result**: ChatGPT / Claude (Polite, safe, helpful).

## Prompt Engineering Concepts
- **Zero-Shot**: Asking without examples. "Translate this."
- **Few-Shot**: Giving examples. "Translate these: Hello->Hola, Cat->Gato. Now: Dog->?"
- **Chain of Thought (CoT)**: Asking the model to "Think step by step". This drastically improves math/logic performance.
