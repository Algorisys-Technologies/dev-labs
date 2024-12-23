import numpy as np
from PIL import Image  # For handling images
from feature_extractor import FeatureExtractor  # Importing feature extraction class
from datetime import datetime  # To create unique timestamps for uploaded image filenames
from flask import Flask, request, render_template  # Flask web framework components
from pathlib import Path  # Path handling for filesystem operations

app = Flask(__name__)  # Initializing the Flask app

# Read pre-extracted image features
fe = FeatureExtractor()  # Create an instance of the feature extractor
features = []  # List to store image features (loaded from .npy files)
img_paths = []  # List to store paths of corresponding images
for feature_path in Path("./static/feature").glob("*.npy"):  # Loop through all saved features
    features.append(np.load(feature_path))  # Load feature vector from .npy file
    img_paths.append(Path("./static/img") / (feature_path.stem + ".jpg"))  # Create path for the corresponding image
features = np.array(features)  # Convert feature list to a NumPy array for vectorized operations


@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':  # If the form is submitted (via POST request)
        file = request.files['query_img']  # Get the uploaded image file from the request

        # Save the uploaded query image with a unique timestamp-based name
        img = Image.open(file.stream)  # Open the uploaded image using PIL
        uploaded_img_path = "static/uploaded/" + datetime.now().isoformat().replace(":", ".") + "_" + file.filename
        img.save(uploaded_img_path)  # Save the image in the 'static/uploaded/' directory

        # Run image similarity search
        query = fe.extract(img)  # Extract features from the uploaded query image
        dists = np.linalg.norm(features - query, axis=1)  # Calculate L2 distances between query features and dataset features
        ids = np.argsort(dists)[1:11]  # Get the indices of the top 40 closest (most similar) images based on distance
        scores = [(dists[id], img_paths[id]) for id in ids]  # Pair distances with image paths for top results

        return render_template('index.html',
                               query_path=uploaded_img_path,  # Show the uploaded image
                               scores=scores)  # Display the top 40 similar images and their scores
    else:
        return render_template('index.html')  # Render the default homepage on GET request


if __name__ == "__main__":
    app.run("0.0.0.0")  # Run the app on all available network interfaces (accessible via localhost or IP)
