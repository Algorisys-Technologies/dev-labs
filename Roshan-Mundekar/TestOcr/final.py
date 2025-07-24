
# import os
# import cv2
# import numpy as np
# from PIL import Image
# from rembg import remove
# from paddleocr import PaddleOCR

# # Initialize PaddleOCR
# ocr = PaddleOCR(
#     use_angle_cls=False,
#     show_log=False,
#     ocr_version="PP-OCRv4",
#     use_gpu=False  # Set True if GPU available
# )

# def remove_background(input_path, output_path):
#     """Remove image background and save result"""
#     with Image.open(input_path) as img:
#         bg_removed = remove(img)
#         bg_removed.save(output_path)
#     return output_path

# def process_image(image_path):
#     """Process single image through background removal and OCR"""
#     # Setup paths
#     base_name = os.path.splitext(os.path.basename(image_path))[0]
#     output_dir = "output_final"
#     os.makedirs(output_dir, exist_ok=True)
    
#     # Process background removal
#     no_bg_path = os.path.join(output_dir, f"{base_name}_nobg.png")
#     print(f"Removing background for {image_path}...")
#     remove_background(image_path, no_bg_path)
    
#     # Read processed image
#     image = cv2.imread(no_bg_path)
#     if image is None:
#         raise FileNotFoundError(f"Processed image not found: {no_bg_path}")
    
#     # Perform OCR
#     print("Running OCR...")
#     result = ocr.ocr(image, cls=False)
    
#     # Extract text results
#     all_text = []
#     for line in result:
#         for word_info in line:
#             text = word_info[1][0]
#             confidence = word_info[1][1]
#             all_text.append(text)
#             print(f"Text: {text}, Confidence: {confidence:.4f}")
    
#     # Save text results
#     text_output = os.path.join(output_dir, f"results_{base_name}.txt")
#     with open(text_output, "w", encoding="utf-8") as f:
#         f.write("\n".join(all_text))
    
#     # Visualize results
#     for line in result:
#         for word_info in line:
#             box = np.array(word_info[0], dtype=np.int32)
#             text = word_info[1][0]
#             cv2.polylines(image, [box.reshape(-1,1,2)], True, (0,255,0), 2)
#             cv2.putText(image, text, (box[0][0], box[0][1]-10), 
#                         cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0,0,255), 2)
    
#     # Save visualization
#     vis_output = os.path.join(output_dir, f"vis_{base_name}.jpg")
#     cv2.imwrite(vis_output, image)
#     print(f"Results saved to:\n- Text: {text_output}\n- Visualization: {vis_output}")
#     return text_output, vis_output

# # Process sample image
# if __name__ == "__main__":
#     input_image = "./samples/1.jpg"  # Change to your image path
#     process_image(input_image)


#######################################################################################################

# import os
# import cv2
# import numpy as np
# from PIL import Image
# from rembg import remove
# from paddleocr import PaddleOCR

# # Initialize PaddleOCR
# ocr = PaddleOCR(
#     use_angle_cls=True,
#     lang="en",
#     use_gpu=True,
#     ocr_version="PP-OCRv4",
#     rec_algorithm="SVTR_LCNet",   # ✅ Correct name
#     rec_model_type="server",      # ✅ High-accuracy model
#     det_db_box_thresh=0.5,
#     show_log=False
# )

# def remove_background(input_path, output_path):
#     """Remove image background and save result"""
#     with Image.open(input_path) as img:
#         bg_removed = remove(img)
#         bg_removed.save(output_path)
#     return output_path


# def process_image(image_path):
#     """Process single image through background removal and OCR"""
#     # Setup paths
#     base_name = os.path.splitext(os.path.basename(image_path))[0]
#     output_dir = "output_final"
#     os.makedirs(output_dir, exist_ok=True)
    
#     # Process background removal
#     no_bg_path = os.path.join(output_dir, f"{base_name}_nobg.png")
#     print(f"Removing background for {image_path}...")
#     remove_background(image_path, no_bg_path)
    
#     # Read processed image
#     image = cv2.imread(no_bg_path)
#     if image is None:
#         raise FileNotFoundError(f"Processed image not found: {no_bg_path}")
    
#     # Perform OCR
#     print("Running OCR...")
#     result = ocr.ocr(image, cls=False)
    
#     # Extract text results
#     all_text = []
#     for line in result:
#         for word_info in line:
#             text = word_info[1][0]
#             confidence = word_info[1][1]
#             all_text.append(text)
#             print(f"Text: {text}, Confidence: {confidence:.4f}")
    
#     # Save text results
#     text_output = os.path.join(output_dir, f"results_{base_name}.txt")
#     with open(text_output, "w", encoding="utf-8") as f:
#         f.write("\n".join(all_text))
    
#     # Visualize results
#     for line in result:
#         for word_info in line:
#             box = np.array(word_info[0], dtype=np.int32)
#             text = word_info[1][0]
#             cv2.polylines(image, [box.reshape(-1,1,2)], True, (0,255,0), 2)
#             cv2.putText(image, text, (box[0][0], box[0][1]-10), 
#                         cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0,0,255), 2)
    
#     # Save visualization
#     vis_output = os.path.join(output_dir, f"vis_{base_name}.jpg")
#     cv2.imwrite(vis_output, image)
#     print(f"Results saved to:\n- Text: {text_output}\n- Visualization: {vis_output}")
#     return text_output, vis_output

# # Process sample image
# if __name__ == "__main__":
#     input_image = "./samples/3.jpg"  # Change to your image path
#     process_image(input_image)



import os
import cv2
import numpy as np
from PIL import Image
from rembg import remove
from paddleocr import PaddleOCR
import openai
from dotenv import load_dotenv
load_dotenv()
# Initialize PaddleOCR
ocr = PaddleOCR(
    use_angle_cls=True,
    lang="en",
    use_gpu=True,
    ocr_version="PP-OCRv4",
    rec_algorithm="SVTR_LCNet",
    rec_model_type="server",
    det_db_box_thresh=0.5,
    show_log=False
)

# Set your OpenAI API key
openai.api_key = os.getenv("OPENAI_API_KEY")  # Set in environment variables

def remove_background(input_path, output_path):
    """Remove image background and save result"""
    with Image.open(input_path) as img:
        bg_removed = remove(img)
        bg_removed.save(output_path)
    return output_path

def refine_with_gpt(text, prompt=None):
    """Refine OCR results using OpenAI GPT"""
    try:
        if not prompt:
            prompt = f"""Correct and improve the following OCR output:
            1. Fix spelling/grammar errors
            2. Structure unstructured text
            3. Maintain original information
            4. Output clean text only
            5. Remove junk, random alphanumeric strings (like "33385afH", "PIC", "3PIC", repeated "EPIC"), and meaningless words.
            6. **Do NOT change names, codes, or ID numbers** (e.g., "TULSITETYAL", "UGU1996123", etc.) even if they look unusual.
            7. Preserve all valid information from the OCR exactly as-is unless clearly broken.
            
            OCR Output:\n{text}"""
        
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a text refinement assistant."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.1,
            max_tokens=2000
        )
        return response.choices[0].message['content'].strip()
    
    except Exception as e:
        print(f"OpenAI Error: {e}")
        return text  # Return original text on failure

def process_image(image_path, use_openai=True):
    """Process image through background removal, OCR, and optional GPT refinement"""
    # Setup paths
    base_name = os.path.splitext(os.path.basename(image_path))[0]
    output_dir = "output_final"
    os.makedirs(output_dir, exist_ok=True)
    
    # Process background removal
    no_bg_path = os.path.join(output_dir, f"{base_name}_nobg.png")
    print(f"Removing background for {image_path}...")
    remove_background(image_path, no_bg_path)
    
    # Read processed image
    image = cv2.imread(no_bg_path)
    if image is None:
        raise FileNotFoundError(f"Processed image not found: {no_bg_path}")
    
    # Perform OCR
    print("Running OCR...")
    result = ocr.ocr(image, cls=False)
    
    # Extract text results
    all_text = []
    for line in result:
        for word_info in line:
            text = word_info[1][0]
            confidence = word_info[1][1]
            all_text.append(text)
            print(f"Text: {text}, Confidence: {confidence:.4f}")
    
    # Save raw OCR results
    raw_text = "\n".join(all_text)
    text_output = os.path.join(output_dir, f"results_{base_name}.txt")
    with open(text_output, "w", encoding="utf-8") as f:
        f.write(raw_text)
    
    # Refine with OpenAI GPT
    refined_text = raw_text
    if use_openai and openai.api_key:
        print("Refining text with OpenAI...")
        refined_text = refine_with_gpt(raw_text)
        
        # Save refined text
        refined_output = os.path.join(output_dir, f"refined_{base_name}.txt")
        with open(refined_output, "w", encoding="utf-8") as f:
            f.write(refined_text)
        print(f"Refined results saved to: {refined_output}")
    
    # Visualization (using original OCR results)
    for line in result:
        for word_info in line:
            box = np.array(word_info[0], dtype=np.int32)
            text = word_info[1][0]
            cv2.polylines(image, [box.reshape(-1,1,2)], True, (0,255,0), 2)
            cv2.putText(image, text, (box[0][0], box[0][1]-10), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0,0,255), 2)
    
    # Save visualization
    vis_output = os.path.join(output_dir, f"vis_{base_name}.jpg")
    cv2.imwrite(vis_output, image)
    print(f"Visualization saved to: {vis_output}")
    
    return refined_text if use_openai else raw_text

if __name__ == "__main__":


    input_image = "./samples/4.jpg"
    result = process_image(input_image, use_openai=True)
    
    print("\nFinal Result:")
    print(result)




