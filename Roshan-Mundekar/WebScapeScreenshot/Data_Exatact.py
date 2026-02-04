from PIL import Image
import pytesseract
import cv2
import os
import openai

from dotenv import load_dotenv  # Import dotenv to load environment variables


# Load environment variables from a .env file
load_dotenv()

openai.api_key = os.getenv("OPENAI_API_KEY")

def image_extract_data(image_path):
    if not os.path.exists(image_path):
        raise FileNotFoundError(f"Image file '{image_path}' not found.")
    
    # Extract the base filename without extension
    base_filename = os.path.splitext(os.path.basename(image_path))[0]

    # Load the image and convert it to grayscale
    image = cv2.imread(image_path)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Apply preprocessing (threshold or blur)
    preprocess_type = "thresh"  # Change to "blur" if you want median blur instead
    if preprocess_type == "thresh":
        gray = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)[1]
    elif preprocess_type == "blur":
        gray = cv2.medianBlur(gray, 3)

    # Save the preprocessed image as a temporary file for OCR
    temp_filename = f"{base_filename}_temp.png"
    cv2.imwrite(temp_filename, gray)

    # Perform OCR using Tesseract
    pytesseract.pytesseract.tesseract_cmd = r'C:/Program Files (x86)/Tesseract-OCR/tesseract.exe'
    raw_text = pytesseract.image_to_string(Image.open(temp_filename))
    os.remove(temp_filename)  # Clean up temporary file

    # Use OpenAI GPT to clean and format the text
    prompt = f"""
    The following text is unformatted and messy. Please clean it up and organize it into a proper, structured format with clear sections like "About Us", "Products", "Services", etc.

    Text:
    {raw_text}

    Cleaned and formatted text:
    """
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": prompt}
        ],
        max_tokens=1500,
        temperature=0.5
    )
    formatted_text = response['choices'][0]['message']['content'].strip()

    # Save the formatted text to a file
    output_dir = "static/text_files"
    os.makedirs(output_dir, exist_ok=True)  # Ensure the directory exists
    text_filename = os.path.join(output_dir, f"{base_filename}.txt")
    with open(text_filename, 'w', encoding='utf-8') as txt_file:
        txt_file.write(formatted_text)

    # Return the relative path for the text file
    return f"/{text_filename}"