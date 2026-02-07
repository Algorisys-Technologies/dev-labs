# import requests
# api_key = 'K83633580688957'
# image_path = 'test.jpg'
# with open(image_path, 'rb') as f:
#     response = requests.post(
#         'https://api.ocr.space/parse/image',
#         files={'filename': f},
#         data={'apikey': api_key, 'isTable': 'true'}
#     )
# print(response.json())

import requests
import cv2
# import pytesseract
from pdf2image import convert_from_path
import os
import numpy as np

# API key for OCR.space (replace 'your_api_key' with your actual API key)
api_key = 'K83633580688957'

def enhance_image(image):
    """Enhance the image for better OCR performance."""
    # Convert to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Apply Gaussian blur to remove noise
    blur = cv2.GaussianBlur(gray, (5, 5), 0)

    # Apply adaptive thresholding
    _, thresh = cv2.threshold(blur, 150, 255, cv2.THRESH_BINARY)

    return thresh

def convert_pdf_to_images(pdf_path):
    """Convert PDF pages to images."""
    return convert_from_path(pdf_path)

def ocr_space_api(image_path):
    """Send the image to OCR.space API for OCR processing."""
    with open(image_path, 'rb') as f:
        response = requests.post(
            'https://api.ocr.space/parse/image',
            files={'filename': f},
            data={'apikey': api_key, 'isTable': 'true'}
        )
    return response.json()

def save_image(image, path):
    """Save the image temporarily for sending to the OCR API."""
    cv2.imwrite(path, image)

def process_pdf_to_ocr(pdf_path):
    # Step 1: Convert PDF to images
    images = convert_pdf_to_images(pdf_path)
    
    ocr_results = []
    
    # Step 2: Loop through the pages and process each image
    for idx, image in enumerate(images):
        # Convert PIL image to OpenCV format
        open_cv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)

        # Step 3: Enhance the image
        enhanced_image = enhance_image(open_cv_image)

        # Step 4: Save the enhanced image temporarily
        temp_image_path = f"temp_page_{idx}.png"
        save_image(enhanced_image, temp_image_path)

        # Step 5: Pass the enhanced image to OCR.space API
        ocr_result = ocr_space_api(temp_image_path)

        # Append the result for further processing or saving
        ocr_results.append(ocr_result)

        # Optionally delete the temp file after processing
        os.remove(temp_image_path)
    
    return ocr_results

# Provide the path to your PDF file
pdf_path = 'amit.pdf'

# Process the PDF and extract OCR results
ocr_data = process_pdf_to_ocr(pdf_path)

# Output the OCR results
for page_idx, result in enumerate(ocr_data):
    print(f"OCR Results for Page {page_idx + 1}:")
    print(result)
