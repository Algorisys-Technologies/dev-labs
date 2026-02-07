import io
from PIL import Image, ImageEnhance
import fitz  # PyMuPDF

# Function to enhance the image
def enhance_image(image):
    # Convert image to grayscale for better OCR results
    image = image.convert('L')

    # Enhance contrast
    enhancer = ImageEnhance.Contrast(image)
    image = enhancer.enhance(2.0)  # Increase contrast

    # Enhance sharpness
    enhancer = ImageEnhance.Sharpness(image)
    image = enhancer.enhance(2.0)  # Increase sharpness

    # Resize image to make text more legible for OCR
    image = image.resize((int(image.width * 1.5), int(image.height * 1.5)), Image.ANTIALIAS)

    return image


# Path to your source directory
enhanced_pdf_path = r'D:\ALGORIS\FINALCODEDEMO\resume summarizer_ai\Latest_code\MainCode\resumes\JewelleryBiodata\Enhanced_Biodata4.pdf'

doc = fitz.open()  # Create a new PDF



original_pdf_path = r'D:\ALGORIS\FINALCODEDEMO\resume summarizer_ai\Latest_code\MainCode\resumes\JewelleryBiodata\Biodata4.pdf'

original_doc = fitz.open(original_pdf_path)

# Process each page of the original PDF
for page_num in range(len(original_doc)):  # Use the range of the original document's pages
    page = doc.new_page(width=612, height=792)  # Standard A4 size page

    # Get the image of the original page
    pix = original_doc.load_page(page_num).get_pixmap()
    img = Image.open(io.BytesIO(pix.tobytes("png")))

    # Enhance the image
    enhanced_img = enhance_image(img)

    # Save enhanced image to a new PDF page
    img_byte_arr = io.BytesIO()
    enhanced_img.save(img_byte_arr, format='PNG')
    page.insert_image(fitz.Rect(0, 0, page.rect.width, page.rect.height), stream=img_byte_arr.getvalue())

# Save the enhanced PDF
doc.save(enhanced_pdf_path)
doc.close()
original_doc.close()

enhanced_pdf_path  # Return path to enhanced PDF
