import random
import numpy as np
import os
import openai
from flask import request, Flask, render_template,abort
from PIL import Image
from feature_extractor import FeatureExtractor  # Importing feature extraction class
from datetime import datetime 
from dotenv import load_dotenv
from io import BytesIO
import base64
import json
from prodia_client import Prodia, image_to_base64, validate_params  # Import from prodia_client.py
from pathlib import Path  # Path handling for filesystem operation
from werkzeug.utils import secure_filename
from pypdf import PdfReader 
from resumeparser import ats_extractor
from rsu import extract_text_from_pdf,get_openai_answer


# Load environment variables from a .env file
load_dotenv()

# Initialize Flask app
app = Flask(__name__)


UPLOAD_FOLDER = 'static/uploads'  # Change this to your desired upload directory






# Ensure the upload directory exists
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# Initialize Prodia API client with the API key
prodia_client = Prodia(api_key=os.getenv('PRODIA_API_KEY'))
model_names = prodia_client.list_models()

# Read pre-extracted image features
fe = FeatureExtractor()  # Create an instance of the feature extractor
features = []  # List to store image features (loaded from .npy files)
img_paths = []  # List to store paths of corresponding images
for feature_path in Path("./static/feature").glob("*.npy"):  # Loop through all saved features
    features.append(np.load(feature_path))  # Load feature vector from .npy file
    img_paths.append(Path("./static/img") / (feature_path.stem + ".jpg"))  # Create path for the corresponding image
features = np.array(features)  # Convert feature list to a NumPy array for vectorized operations

# Convert image to base64 string
def image_to_base64_str(image):
    buffer = BytesIO()
    image.save(buffer, format='PNG')
    buffer.seek(0)
    return base64.b64encode(buffer.read()).decode('utf-8')

# Generate image from text prompt using Prodia API
def txt2img(prompt, negative_prompt, model, steps, sampler, cfg_scale, width, height, seed):
    params = {
        "prompt": prompt,
        "negative_prompt": negative_prompt,
        "model": model,
        "steps": steps,
        "sampler": sampler,
        "cfg_scale": cfg_scale,
        "width": width,
        "height": height,
        "seed": seed
    }
    
    validate_params(params)
    
    print("Sending request with parameters:", json.dumps(params, indent=4))
    result = prodia_client.generate(params)
    job = prodia_client.wait(result)
    
    return job["imageUrl"]

# Generate image from another image using Prodia API
def img2img(input_image, denoising, prompt, negative_prompt, model, steps, sampler, cfg_scale, width, height, seed):
    params = {
        "imageData": image_to_base64(input_image),
        "denoising_strength": denoising,
        "prompt": prompt,
        "negative_prompt": negative_prompt,
        "model": model,
        "steps": steps,
        "sampler": sampler,
        "cfg_scale": cfg_scale,
        "width": width,
        "height": height,
        "seed": seed
    }
    
    validate_params(params)
    
    print("Sending request with parameters:", json.dumps(params, indent=4))
    result = prodia_client.transform(params)
    job = prodia_client.wait(result)
    
    return job["imageUrl"]

# Process image (convert to PNG and compress if necessary)
def process_image(input_image):
    img = Image.open(input_image)

    # Convert the image to PNG format
    img = img.convert("RGBA")

    # Compress the image to reduce file size
    output_io = BytesIO()
    img.save(output_io, format='PNG', optimize=True, quality=85)

    # Ensure the compressed image is under 4 MB
    if output_io.tell() > 4 * 1024 * 1024:
        raise ValueError("Compressed image is still larger than 4 MB")

    output_io.seek(0)
    return output_io


# DEFAULT_FEATURES = ['Dashboard', 'Image Search', 'Image Generate', 'Resume Search', 'Resume summary']
# Function to read features from feature.txt, with a fallback to default features
# def get_features():
#     if not os.path.exists('feature.txt'):
#         # If feature.txt doesn't exist, return default features
#         return DEFAULT_FEATURES
    
#     with open('feature.txt', 'r') as file:
#         features = [line.strip() for line in file.readlines() if line.strip()]
    
#     # If feature.txt is empty, return default features
#     if not features:
#         return DEFAULT_FEATURES

#     return features

def get_features():
    if not os.path.exists('feature.txt'):
        # If feature.txt doesn't exist, return an empty list
        return []
    
    with open('feature.txt', 'r') as file:
        features = [line.strip() for line in file.readlines() if line.strip()]
    
    # If feature.txt is empty, return an empty list
    if not features:
        return []

    return features

@app.route('/')
def index():
    features = get_features()
    
    # If no features are available, set a message
    if not features:
        message = "No features are available to be used"
    else:
        message = None

    return render_template('index.html', features=features, message=message)


# @app.route('/')
# def index():
#     features = get_features()
#     print(features)
#     return render_template('index.html',features=features)


@app.route('/generate', methods=['POST','GET'])
def generate_images():
    features = get_features()
    if not features:
        message = "No features are available to be used"
    else:
        message = None
    
    
    
    if request.method == 'POST':
        try:
            # Extract form data
            model = request.form['model']
            prompt = request.form['prompt']
            negative_prompt = request.form.get('negative-prompt', '')
            steps = request.form.get('steps', 30)
            sampling_method = request.form.get('sampling-method', 'default_sampler')
            cfg_scale = request.form.get('cfg-scale', 7.0)
            width = request.form.get('width', 512)
            height = request.form.get('height', 512)
            seed = request.form.get('seed', None)
            number_of_images = request.form['number-of-images']
            
            # Check if an image is uploaded
            input_image = request.files.get('input-image', None)

            generated_images = []
            image_urls = []

            if input_image and input_image.filename != '':
                # Handle img2img if image is uploaded
                input_image = Image.open(input_image.stream).convert("RGBA")

                for i in range(int(number_of_images)):
                    current_seed = int(seed) + i * 5 if seed else random.randint(0, 10000)

                    result = img2img(
                        input_image=input_image,
                        denoising=float(request.form.get('denoising-strength', 0.5)),
                        prompt=prompt,
                        negative_prompt=negative_prompt,
                        model=model,
                        steps=int(steps) + i * 2,
                        sampler=sampling_method,
                        cfg_scale=float(cfg_scale),
                        height=int(height),
                        width=int(width),
                        seed=current_seed
                    )

                    generated_images.append(result)

                input_image = request.files.get('input-image', None)
                number_of_images = int(number_of_images)
                if number_of_images > 5:
                    number_of_images = 5
                response = openai.Image.create_variation(
                    model="dall-e-2",
                    image=process_image(input_image.stream),
                    n=int(number_of_images),
                    size="1024x1024"
                )
                image_urls = [image['url'] for image in response['data']]
                
            
            else:
                # Handle txt2img if no image is uploaded
                for i in range(int(number_of_images)):
                    current_seed = int(seed) + i * 5 if seed else random.randint(0, 10000)

                    result = txt2img(
                        prompt=prompt,
                        negative_prompt=negative_prompt,
                        model=model,
                        steps=int(steps) + i * 2,
                        sampler=sampling_method,
                        cfg_scale=float(cfg_scale),
                        height=int(height),
                        width=int(width),
                        seed=current_seed
                    )
                    generated_images.append(result)

                number_of_images = int(number_of_images)
                if number_of_images > 5:
                    number_of_images = 5
                # Generate images using OpenAI's DALL-E API
                response = openai.Image.create(
                    model="dall-e-2",
                    prompt=prompt,
                    size="1024x1024",
                    n=int(number_of_images)
                )
                image_urls = [image['url'] for image in response['data']]

            return render_template('result.html', generated_images=generated_images, image_urls=image_urls,features=features,message=message)

        except ValueError as ve:
            return f"Invalid input: {str(ve)}", 400
        except Exception as e:
            return f"An error occurred: {str(e)}", 500
    else:
        return render_template('generate.html',sampling_method=prodia_client.list_samplers(), model_names=model_names,features=features,message=message)
    
@app.route('/search', methods=['GET', 'POST'])
def search_image():
    features2 = get_features()
    if not features2:
        message = "No features are available to be used"
    else:
        message = None
        
    if request.method == 'POST':  # If the form is submitted (via POST request)
        file = request.files['query_img']  # Get the uploaded image file from the request
        img = Image.open(file.stream)  # Open the uploaded image using PIL

        # Run image similarity search
        query = fe.extract(img)  # Extract features from the uploaded query image
        dists = np.linalg.norm(features - query, axis=1)  # Calculate L2 distances between query features and dataset features
        ids = np.argsort(dists)[1:6]  # Get the indices of the top 40 closest (most similar) images based on distance
        scores = [(dists[id], img_paths[id]) for id in ids]  # Pair distances with image paths for top results

        return render_template('search.html', query_path=image_to_base64_str(img), scores=scores,features=features2)  # Pass base64 image string
    else:
        return render_template('search.html', query_path=None, scores=None,features=features2,message=message)  # Render the default homepage on GET request

# =========================================================================================
                                    # !Roshan
# =========================================================================================

def _read_file_from_path(path):
    reader = PdfReader(path) 
    data = ""

    for page_no in range(len(reader.pages)):
        page = reader.pages[page_no] 
        data += page.extract_text()

    return data 


@app.route('/resume', methods=['GET', 'POST'])
def resume():
    features = get_features()
    if not features:
        message2 = "No features are available to be used"
    else:
        message2 = None
     
    if request.method == 'POST':
        if 'query_pdf' not in request.files:
            return render_template('Resume.html', error="No file part")
        
        new_file = request.files['query_pdf']  # Get the uploaded file
        print(new_file)
        
        # Check if a file was selected
        if new_file.filename == '':
            return render_template('Resume.html', error="No selected file")

        # Ensure the file is a PDF
        if new_file and new_file.filename.endswith('.pdf'):
            # Construct the path to save the uploaded PDF
            pdf_path = os.path.join(UPLOAD_FOLDER, new_file.filename)
            new_file.save(pdf_path)  # Save the file
            print(pdf_path)
            # Read the PDF file from the path
            data = _read_file_from_path(pdf_path)
            
            extracted_data = ats_extractor(data)
            data=json.loads(extracted_data)
            print(data)
            
            return render_template('Resume.html', message="File uploaded successfully!", data=data,features=features)
        else:
            return render_template('Resume.html', error="Please upload a valid PDF file",features=features)

    return render_template('Resume.html',features=features,message2=message2)  # For GET request




@app.route('/Research')
def Research():
    features = get_features()
    if not features:
        message = "No features are available to be used"
    else:
        message = None
     
    return render_template('Research.html',features=features,message=message)


@app.route('/askbot', methods=['POST'])
def askbot():
    features = get_features()
    if request.method == 'POST':
        # Get the uploaded file
        uploaded_file = request.files.get('resume')
        search_phrase = request.form.get('question')

        if uploaded_file and uploaded_file.filename.endswith('.pdf'):
            filename = secure_filename(uploaded_file.filename)
            # file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file_path = os.path.join(UPLOAD_FOLDER, uploaded_file.filename)

            # Save the uploaded file
            uploaded_file.save(file_path)

            # Extract text from the saved PDF
            extracted_text = extract_text_from_pdf(file_path)

            if extracted_text:
                # Generate an answer using extracted text and the search phrase
                answer = get_openai_answer(extracted_text, search_phrase)
                print(search_phrase)
                print(answer)
                return render_template('Research.html', question=search_phrase, answer=answer,features=features)
                
                
            else:
                return "Could not extract text from the PDF.", 400
        else:
            return "Invalid file type. Please upload a PDF.", 400
        
    return render_template('Research.html',features=features)



if __name__ == '__main__':
    app.run(debug=True)
    # app.run("0.0.0.0")
