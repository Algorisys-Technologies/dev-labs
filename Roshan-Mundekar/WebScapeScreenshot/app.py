from flask import request, Flask, render_template,abort,flash,redirect,jsonify
import os
import urllib.parse
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
from webdriver_manager.chrome import ChromeDriverManager
import openai
from dotenv import load_dotenv
from PIL import Image
import pytesseract
import cv2


app = Flask(__name__)
app.secret_key = 'your_secret_key'

# Path to the directories
HOSTNAME_FOLDER = "static/hostname"
IMAGES_FOLDER = "images"

load_dotenv()
openai.api_key = os.getenv("OPENAI_API_KEY")


# OCR and text formatting function
def image_extract_data(image_path):
    print(f"Provided image path: {image_path}")
    
    # Resolve the full path to the image file
    root_path = os.path.dirname(os.path.abspath(__file__))  # Get the script's directory
    full_image_path = os.path.join(root_path, image_path.lstrip('/'))  # Remove leading `/` and join

    if not os.path.exists(full_image_path):
        raise FileNotFoundError(f"Image file '{full_image_path}' not found.")
    
    # Extract the base filename without extension
    base_filename = os.path.splitext(os.path.basename(full_image_path))[0]
    print(f"Base filename: {base_filename}")
    
    # Load the image and convert it to grayscale
    image = cv2.imread(full_image_path)
    if image is None:
        raise ValueError(f"Unable to load image from path: {full_image_path}")
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Apply preprocessing (threshold or blur)
    preprocess_type = "thresh"  # Change to "blur" if needed
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
    root_path1="static/text_files"
    
    os.makedirs(root_path1, exist_ok=True)
    text_filename = os.path.join(root_path1, f"{base_filename}.txt")
    with open(text_filename, 'w', encoding='utf-8') as txt_file:
        txt_file.write(formatted_text)

    download_url = f"/{text_filename.replace(os.path.sep, '/')}"
    return download_url




def get_folders_in_directory(directory):
    """Get folder names in the given directory."""
    try:
        return [folder for folder in os.listdir(directory) if os.path.isdir(os.path.join(directory, folder))]
    except FileNotFoundError:
        return []
    
def get_images_in_folder(folder_name):
    folder_path = os.path.join('static', 'hostname', folder_name)  # Path to the folder
    if os.path.exists(folder_path):
        return [f for f in os.listdir(folder_path) if f.endswith(('.png', '.jpg', '.jpeg', '.gif'))]
    return []
    
# Function to capture a full-page screenshot
def capture_screenshot(url):
    # Parse the URL to get hostname and path
    parsed_url = urllib.parse.urlparse(url)
    print(parsed_url)
    hostname = parsed_url.hostname
    page_name = parsed_url.path.strip("/").replace("/", "-") if parsed_url.path.strip("/") else "index"
    # Create directory structure based on hostname
    screenshot_dir = os.path.join("static/hostname", hostname)
    os.makedirs(screenshot_dir, exist_ok=True)
    # screent="pic"
    # Define the screenshot path
    screenshot_path = os.path.join(screenshot_dir, f"{page_name}.png")

    # Set up Chrome options
    options = Options()
    options.add_argument("--headless")  # Run in headless mode
    options.add_argument("--window-size=1920,1080")  # Set initial window size

    # Set up ChromeDriver using WebDriver Manager
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)

    try:
        # Open the webpage
        driver.get(url)

        # Wait for the cookie dialog and click "Allow All Cookies" if it appears
        try:
            allow_button = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Allow All Cookies')]"))
            )
            allow_button.click()
            print("Clicked 'Allow All Cookies'")
        except Exception as e:
            print("No 'Allow All Cookies' button found or timed out:", e)

        # Wait briefly after clicking the cookie dialog button
        time.sleep(2)

        # Slowly scroll down the page to load all dynamic content
        scroll_pause_time = 1  # Pause between scrolls
        scroll_increment = 300  # Pixels to scroll at each step

        last_height = driver.execute_script("return document.body.scrollHeight")
        current_scroll_position = 0

        while current_scroll_position < last_height:
            # Scroll down by the increment
            driver.execute_script(f"window.scrollTo(0, {current_scroll_position});")
            time.sleep(scroll_pause_time)  # Wait to allow content to load
            current_scroll_position += scroll_increment

            # Update last_height to the new scroll height
            new_height = driver.execute_script("return document.body.scrollHeight")
            if new_height > last_height:
                last_height = new_height

        # After scrolling, take the full-page screenshot
        full_height = driver.execute_script("return document.body.scrollHeight")
        driver.set_window_size(1920, full_height)  # Adjust width as needed

        # Save the screenshot
        driver.save_screenshot(screenshot_path)
         # Resize/crop the image to 1024x1024 using Pillow
        # img = Image.open(screenshot_path)
        # img_resized = img.resize((1024, 1024), Image.ANTIALIAS)  # Resize image
        # img_resized.save(screenshot_path, quality=95)  # Save resized image
        # print(f"Screenshot resized to 1024x1024 and saved at: {screenshot_path}")
        # return screenshot_path
        print(f"Full-page screenshot with dynamic content saved at: {screenshot_path}")
        return screenshot_path

    finally:
        # Close the driver
        driver.quit()


def get_images_in_hostname_directory(hostname_folder):
   
    images_in_folders = {}
    if not os.path.exists(hostname_folder):
        print(f"Error: Directory '{hostname_folder}' does not exist.")
        return images_in_folders

    for folder_name in os.listdir(hostname_folder):
        folder_path = os.path.join(hostname_folder, folder_name)
        if os.path.isdir(folder_path):
            # Collect all image files in the current folder
            images = [
                file_name for file_name in os.listdir(folder_path)
                if file_name.lower().endswith(('.png', '.jpg', '.jpeg', '.gif', '.bmp', '.tiff'))
            ]
            images_in_folders[folder_name] = images

    return images_in_folders


@app.route('/')
def index():
    hostname_folders = get_folders_in_directory(HOSTNAME_FOLDER)
    print(hostname_folders)
    images_folders = get_images_in_hostname_directory(HOSTNAME_FOLDER)
    print("Images in folders:", images_folders)  # Debugging output
    return render_template('treeview.html', hostname_folders=hostname_folders,images_folders=images_folders)

@app.route('/show')
def show():
    return render_template('gallery.html')
    
@app.route('/submit-url', methods=['POST'])
def submit_url():
    url = request.form.get("url")
    if not url:
        return jsonify({"error": "No URL provided"}), 400

    try:
        # Simulate screenshot capture
        screenshot_path = capture_screenshot(url)
        return jsonify({
            "message": "URL processed successfully",
            "screenshot": screenshot_path
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/show/<folder_name>')
def show_folder_images(folder_name):
    print(f"Folder Name: {folder_name}")
    image_files = get_images_in_folder(folder_name)  # Function to get image files
    print("Images in folder:", image_files)  # Debugging output
    return render_template('gallery.html', folder_name=folder_name, image_files=image_files)


@app.route('/apply_ocr', methods=['POST'])
def apply_ocr():
    data = request.get_json()
    image_path = data.get('image')

    if not image_path:
        return jsonify({"error": "Image path not provided"}), 400

    try:
        # Perform OCR and get the download URL
        print(image_path)
        download_url = image_extract_data(image_path)
        print(download_url)
        return jsonify({"message": "OCR complete", "download_url": download_url})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
if __name__ == '__main__':
    # app.run(debug=True)
    app.run("0.0.0.0")
    
    