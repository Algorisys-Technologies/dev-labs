# Phase 7 - Lesson 1: Prompt Engineering (The New Coding)

# ==========================================
# 1. WHAT IS A PROMPT?
# ==========================================
# A prompt is the input string we feed to the LLM.
# The quality of the output depends 80% on the quality of the prompt.

# ==========================================
# 2. TECHNIQUE: ZERO-SHOT
# ==========================================
# Asking without help.
zero_shot_prompt = """
Classify the sentiment of this text: "The food was okay, but the service was slow."
Sentiment:
"""
print("--- Zero Shot ---")
print(zero_shot_prompt)

# ==========================================
# 3. TECHNIQUE: FEW-SHOT (Pattern Matching)
# ==========================================
# Giving examples to guide the model.
few_shot_prompt = """
Classify the sentiment of the text.

Text: "I won the lottery!"
Sentiment: Positive

Text: "I lost my keys."
Sentiment: Negative

Text: "The food was okay, but the service was slow."
Sentiment: 
"""
print("\n--- Few Shot ---")
print(few_shot_prompt)

# ==========================================
# 4. TECHNIQUE: CHAIN OF THOUGHT (CoT)
# ==========================================
# Asking the model to "think" before answering. Drastically improves math/logic.

cot_prompt = """
Question: If I have 5 apples, eat 2, and buy 4 more, how many do I have?

Answer: Let's think step by step.
1. Start with 5 apples.
2. Eat 2 apples. 5 - 2 = 3.
3. Buy 4 apples. 3 + 4 = 7.
The answer is 7.

Question: If I have 10 cars, sell 2, and buy 1, how many cars do I have?
Answer: Let's think step by step.
"""
print("\n--- Chain of Thought ---")
print(cot_prompt)

# ==========================================
# 5. TEMPLATES (Python F-Strings)
# ==========================================
# In apps, we don't hardcode prompts. We use templates.

user_input = "The battery life is terrible."
template = f"""
You are a helpful customer support AI. 
The user is complaining about: "{user_input}"
Write a polite apology email in 2 sentences.
"""

print("\n--- Dynamic Template ---")
print(template)
