# Phase 8 - Lesson 2: Fine-Tuning Skeleton (PEFT/LoRA)

# ==========================================
# CONTEXT
# ==========================================
# This code is a SKELETON. It shows how we write code to fine-tune 
# a model like Llama-2 or Mistral using Hugging Face PEFT.
# You need a GPU (NVIDIA) to run this for real.

# Libraries you would typically install:
# pip install transformers peft bitsandbytes training

print("--- Conceptual Fine-Tuning Script ---")

# 1. Import Libraries
# from transformers import AutoModelForCausalLM, AutoTokenizer, TrainingArguments
# from peft import LoraConfig, get_peft_model

# 2. Load Base Model (e.g., Mistral 7B)
model_name = "mistralai/Mistral-7B-v0.1"
print(f"Loading Base Model: {model_name}...")
# model = AutoModelForCausalLM.from_pretrained(model_name, load_in_4bit=True)
# tokenizer = AutoTokenizer.from_pretrained(model_name)

# 3. Define LoRA Config (Low Rank Adaptation)
# Instead of training 7 Billion params, we train 0.1% (Adapters).
print("Configuring LoRA adapters...")
# peft_config = LoraConfig(
#     r=16,       # Rank (Size of adapter)
#     lora_alpha=32,
#     target_modules=["q_proj", "v_proj"], # Apply to Attention layers
#     task_type="CAUSAL_LM"
# )

# 4. Attach Adapter to Model
# model = get_peft_model(model, peft_config)
# model.print_trainable_parameters()
# Output: "Trainable params: 4,000,000 || All params: 7,000,000,000 || 0.06%"

# 5. Dataset (JSON format)
# data = [{"instruction": "Summarize", "input": "...", "output": "..."}]

# 6. Training
print("Starting Training Loop (Trainer)...")
# trainer = Trainer(
#     model=model,
#     train_dataset=data,
#     args=TrainingArguments(max_steps=100)
# )
# trainer.train()

print("Training Complete. Model saved to ./my_finetuned_model")
