from tensorflow.keras.preprocessing import image
from tensorflow.keras.applications.vgg16 import VGG16, preprocess_input
from tensorflow.keras.models import Model
import numpy as np

class FeatureExtractor:
    def __init__(self):
        # Load the pre-trained VGG16 model with weights trained on the ImageNet dataset.
        # The 'imagenet' weights allow the model to perform feature extraction based on a wide range of common objects.
        base_model = VGG16(weights="imagenet")
        
        # Define a new model that uses the same input as VGG16 but outputs the features from the 'fc1' layer (the first fully connected layer).
        # This is useful for feature extraction, as this layer contains abstract features useful for comparison and classification tasks.
        self.model = Model(inputs=base_model.input, outputs=base_model.get_layer('fc1').output)
    
    def extract(self, img):
        # Resize the image to 224x224 pixels, which is the required input size for the VGG16 model.
        # Convert the image to RGB, ensuring it has 3 color channels.
        img = img.resize((224, 224)).convert('RGB')
        
        # Convert the image to a NumPy array (which is required for further processing in the model).
        x = image.img_to_array(img)
        
        # Add an additional dimension to the array (since the model expects batches of images, even if it's a single image).
        x = np.expand_dims(x, axis=0)
        
        # Preprocess the input image array by normalizing it according to the ImageNet dataset's mean and standard deviation.
        # This step ensures the input is in the same format that the VGG16 model was originally trained on.
        x = preprocess_input(x)
        
        # Pass the image through the model and obtain the features from the 'fc1' layer. The output is a vector of feature values.
        feature = self.model.predict(x)[0]
        
        # Normalize the feature vector using the L2 norm to get a unit vector (length 1).
        # This is helpful for similarity comparisons, where the direction of the vector matters more than its magnitude.
        return feature / np.linalg.norm(feature)
