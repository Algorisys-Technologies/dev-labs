# utilities/llm.py
# LLM interaction functions

import os
from datetime import datetime
from groq import Groq

# Lazy-loaded client (avoids import-time errors if API key not set)
_client = None

def _get_client():
    """
    Get or create the Groq client with API key validation.
    Raises EnvironmentError early if the API key is not configured.
    """
    global _client
    if _client is None:
        api_key = os.getenv("GROQ_API_KEY")
        
        # ===== VALIDATION FIX =====
        if not api_key:
            raise EnvironmentError(
                "\n" + "="*60 + "\n"
                "❌ GROQ_API_KEY environment variable is not set!\n"
                "="*60 + "\n\n"
                "To fix this:\n"
                "1. Get your API key from: https://console.groq.com/keys\n"
                "2. Create a .env file in the project root with:\n"
                "   GROQ_API_KEY=your_api_key_here\n"
                "3. Or set it in your terminal:\n"
                "   Windows: set GROQ_API_KEY=your_api_key_here\n"
                "   Linux/Mac: export GROQ_API_KEY=your_api_key_here\n"
                + "="*60
            )
        
        _client = Groq(api_key=api_key)
    return _client


# LLM output logging file
LLM_LOG_FILE = "llm_outputs.txt"



def log_llm_output(function_name: str, prompt: str, user_input: str, output: str):
    """
    Logs LLM outputs to a text file for debugging.
    Appends timestamp, function name, inputs, and outputs.
    """
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    separator = "="*80
    
    with open(LLM_LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"\n{separator}\n")
        f.write(f"TIMESTAMP: {timestamp}\n")
        f.write(f"FUNCTION: {function_name}\n")
        f.write(f"{separator}\n\n")
        
        f.write(f"SYSTEM PROMPT (first 200 chars):\n")
        f.write(f"{prompt[:200]}...\n\n")
        
        f.write(f"USER INPUT:\n")
        f.write(f"{user_input}\n\n")
        
        f.write(f"LLM OUTPUT:\n")
        f.write(f"{output}\n")
        f.write(f"\n{separator}\n\n")


def call_llm(prompt: str, user_input: str) -> str:
    """
    Calls Groq LLM with a system prompt + user input.
    Returns raw text output.
    """
    response = _get_client().chat.completions.create(
        model="llama-3.1-8b-instant",
        messages=[
            {"role": "system", "content": prompt},
            {"role": "user", "content": user_input},
        ],
        temperature=0.2,
    )

    output = response.choices[0].message.content
    log_llm_output("call_llm", prompt, user_input, output)
    return output


def call_llm_json(prompt: str, user_input: str) -> str:
    """
    Calls Groq LLM with JSON mode enforced and temperature=0 for deterministic output.
    Use this for structured data generation.
    """
    response = _get_client().chat.completions.create(
        model="llama-3.1-8b-instant",
        messages=[
            {"role": "system", "content": prompt},
            {"role": "user", "content": user_input},
        ],
        temperature=0,
        response_format={"type": "json_object"},
    )

    output = response.choices[0].message.content
    log_llm_output("call_llm_json", prompt, user_input, output)
    return output


def call_llm_text(prompt: str, user_input: str) -> str:
    """
    Calls Groq LLM without JSON mode for free-form text output.
    """
    response = _get_client().chat.completions.create(
        model="llama-3.1-8b-instant",  # Back to 8b due to 70b rate limit

        messages=[
            {"role": "system", "content": prompt},
            {"role": "user", "content": user_input},
        ],
        temperature=0.3,
    )


    output = response.choices[0].message.content
    log_llm_output("call_llm_text", prompt, user_input, output)
    return output
