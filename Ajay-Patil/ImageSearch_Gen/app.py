import random
import numpy as np
import os
import openai
from flask import request, Flask, render_template
from PIL import Image
from feature_extractor import FeatureExtractor  # Importing feature extraction class
from datetime import datetime 
from dotenv import load_dotenv
from io import BytesIO
import json
from prodia_client import Prodia, image_to_base64, validate_params  # Import from prodia_client.py
from pathlib import Path  # Path handling for filesystem operations

# Load environment variables from a .env file
load_dotenv()

# Initialize Flask app
app = Flask(__name__)

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


from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/generate', methods=['POST','GET'])
def generate_images():
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

                # Generate images using OpenAI's DALL-E API
                response = openai.Image.create(
                    model="dall-e-2",
                    prompt=prompt,
                    size="1024x1024",
                    n=int(number_of_images)
                )
                image_urls = [image['url'] for image in response['data']]

            return render_template('result.html', generated_images=generated_images, image_urls=image_urls)

        except ValueError as ve:
            return f"Invalid input: {str(ve)}", 400
        except Exception as e:
            return f"An error occurred: {str(e)}", 500
    else:
        return render_template('generate.html',sampling_method=prodia_client.list_samplers(), model_names=model_names)
    
@app.route('/search', methods=['GET', 'POST'])
def search_image():
    if request.method == 'POST':  # If the form is submitted (via POST request)
        file = request.files['query_img']  # Get the uploaded image file from the request

        # Save the uploaded query image with a unique timestamp-based name
        img = Image.open(file.stream)  # Open the uploaded image using PIL
        uploaded_img_path = "static/uploaded/" + datetime.now().isoformat().replace(":", ".") + "_" + file.filename
        img.save(uploaded_img_path)  # Save the image in the 'static/uploaded/' directory

        # Run image similarity search
        query = fe.extract(img)  # Extract features from the uploaded query image
        dists = np.linalg.norm(features - query, axis=1)  # Calculate L2 distances between query features and dataset features
        ids = np.argsort(dists)[1:6]  # Get the indices of the top 40 closest (most similar) images based on distance
        scores = [(dists[id], img_paths[id]) for id in ids]  # Pair distances with image paths for top results

        return render_template('search.html',
                               query_path=uploaded_img_path,  # Show the uploaded image
                               scores=scores)  # Display the top 40 similar images and their scores
    else:
        return render_template('search.html',query_path=None,scores=None)  # Render the default homepage on GET request

if __name__ == '__main__':
    app.run(debug=True)