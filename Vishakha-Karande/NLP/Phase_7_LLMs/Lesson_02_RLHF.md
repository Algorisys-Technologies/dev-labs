# Phase 7 - Lesson 2: RLHF (Reinforcement Learning from Human Feedback)

## Why Pretraining isn't enough?
A pretrained LLM (like GPT-3 Base) is just a "Text Completer".
- **Input**: "The capital of France is"
- **Output**: "Paris, and the capital of Germany is Berlin..." (It just keeps going).
- **Input**: "How do I make a bomb?"
- **Output**: "Here is the recipe..." (It has no safety filter).

We need to **Align** the model to be helpful and safe.

## The RLHF Pipeline
This is how we turn a "Wild" model into "ChatGPT".

### Step 1: Supervised Fine-Tuning (SFT)
- Humans write good answers.
- The model learns to mimic this style.
- Result: It answers questions, but still makes stuff up.

### Step 2: Reward Modeling
- The model generates **two** answers for the same prompt.
- Answer A: "The capital is Paris."
- Answer B: "Paris is a city in France."
- A Human Labeler ranks them: "A is better than B".
- We train a **Reward Model** (a separate AI) to predict what humans like.

### Step 3: PPO (Proximal Policy Optimization)
- We let the LLM generate answers.
- The Reward Model scores them (e.g., +10 points).
- The LLM updates its weights to get more points (Reinforcement Learning).
- **Analogy**: Training a dog with treats. If it sits (Good Answer), it gets a treat (Reward).

## The Result
A model that:
1.  Follows instructions.
2.  Refuses harmful requests ("I can't help with that").
3.  Writes in a helpful tone.
