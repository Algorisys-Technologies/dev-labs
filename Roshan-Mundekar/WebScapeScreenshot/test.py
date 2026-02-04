from PIL import Image
import pytesseract
import cv2
import os
import openai



openai.api_key = "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"
# Define the image path
imagepath = "index.png"
base_filename = os.path.splitext(os.path.basename(imagepath))[0]

# Load the image and convert it to grayscale
image = cv2.imread(imagepath)
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# Define the preprocessing type, you can change this as needed
preprocess_type = "thresh"  # Change to "blur" if you want median blur instead

# Check to see if we should apply thresholding to preprocess the image
if preprocess_type == "thresh":
    gray = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)[1]
# Check if median blurring should be done to remove noise
elif preprocess_type == "blur":
    gray = cv2.medianBlur(gray, 3)

# Write the grayscale image to disk as a temporary file so we can apply OCR to it
filename = "{}.png".format(os.getpid())
cv2.imwrite(filename, gray)

# Load the image as a PIL/Pillow image, apply OCR, and then delete the temporary file
x = Image.open(filename)
pytesseract.pytesseract.tesseract_cmd = r'C:/Program Files (x86)/Tesseract-OCR/tesseract.exe'
raw_text = pytesseract.image_to_string(x)
os.remove(filename)

# Output the OCR result
print("OCR Result:")
print(raw_text)
# Prompt to instruct GPT to clean and format the text
# Prompt to instruct GPT to clean and format the text
prompt = f"""
The following text is unformatted and messy. Please clean it up and organize it into a proper, structured format with clear sections like "About Us", "Products", "Services", etc.

Text:
{raw_text}

Cleaned and formatted text:
"""

# Request OpenAI to process the text using chat-based model (GPT-4)
response = openai.ChatCompletion.create(
    model="gpt-4",  # Specify the chat model
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": prompt}
    ],
    max_tokens=1500,
    temperature=0.5
)

# Get the formatted text
formatted_text = response['choices'][0]['message']['content'].strip()

# Output the formatted text
print(formatted_text)
# Create the directory path for saving the text file (without hostname)
output_dir = "static/text_files"
os.makedirs(output_dir, exist_ok=True)

# Use the base_filename from the image to create the text filename
text_filename = os.path.join(output_dir, f"{base_filename}.txt")

# Save the extracted text to a .txt file with UTF-8 encoding
with open(text_filename, 'w', encoding='utf-8') as txt_file:
    txt_file.write(formatted_text)

print(f"Text saved to {formatted_text}")
