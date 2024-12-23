from PIL import Image  # Used to open and manipulate image files
from pathlib import Path  # Provides object-oriented path handling
import numpy as np  # Used for handling arrays and saving features as .npy files

from feature_extractor import FeatureExtractor  # Importing the feature extraction class

if __name__ == "__main__":
    # Create an instance of the FeatureExtractor class
    fe = FeatureExtractor()

    # Loop through all JPEG files in the specified directory ('./static/img')
    for img_path in sorted(Path('./static/img').glob("*.jpg")):
        print(img_path)  # Print the image path to see which image is being processed
        
        # Open the image using PIL's Image module and pass it to the extract method of the FeatureExtractor
        feature = fe.extract(img=Image.open(img_path))
        
        # Print the type of the extracted feature (should be a NumPy array) and its shape
        print(type(feature), feature.shape)
        
        # Set the path for saving the extracted feature, using the image's stem (filename without extension)
        # The features are saved in the './static/feature' directory, with the same name as the image but with .npy extension
        feature_path = Path("./static/feature") / (img_path.stem + ".npy")
        
        # Print the path where the feature will be saved and the feature vector itself (optional, for debugging)
        print(feature_path)
        print(feature)

        # Save the extracted feature vector as a .npy file (NumPy binary format) to the specified path
        np.save(feature_path, feature)
