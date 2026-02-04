import openai

# Set your OpenAI API key
openai.api_key = "your_openai_api_key"

# Your unformatted text
raw_text = """
YOUR UNFORMATTED TEXT GOES HERE
"""

# Prompt to instruct GPT to clean and format the text
prompt = f"""
The following text is unformatted and messy. Please clean it up and organize it into a proper, structured format with clear sections like "About Us", "Products", "Services", etc.

Text:
{raw_text}

Cleaned and formatted text:
"""

# Request OpenAI to process the text
response = openai.Completion.create(
    engine="gpt-4",  # or "text-davinci-003" if you're using GPT-3
    prompt=prompt,
    max_tokens=1500,
    temperature=0.5
)

# Get the formatted text
formatted_text = response.choices[0].text.strip()

# Output the formatted text
print(formatted_text)
