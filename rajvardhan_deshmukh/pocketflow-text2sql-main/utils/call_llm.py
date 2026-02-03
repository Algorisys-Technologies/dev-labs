import os
import time
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

def call_llm(prompt):
    api_key = os.environ.get("GROQ_API_KEY")
    if not api_key:
        return "Error: GROQ_API_KEY is missing in .env file"

    client = Groq(api_key=api_key)

    max_retries = 1
    for attempt in range(max_retries):
        try:
            response = client.chat.completions.create(
                model="qwen/qwen3-32b",  # fast + high quality
                messages=[
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,
            )
            return response.choices[0].message.content

        except Exception as e:
            error_msg = str(e)

            if "429" in error_msg or "rate" in error_msg.lower():
                print(f"\n[!] Rate limit hit. Waiting 20 seconds before retry {attempt+1}/{max_retries}...")
                time.sleep(20)
                continue
            else:
                return f"Error calling Groq: {error_msg}"

    return "Error: Failed to get response from Groq after multiple retries."

if __name__ == "__main__":
    print(call_llm("Tell me a one sentence joke."))
