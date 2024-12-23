import os
import torch
from diffusers import AutoPipelineForImage2Image
from diffusers.utils import load_image, make_image_grid
from PIL import Image

# Define the path to the local folder where the model will be stored
local_model_dir = "kandinsky-2-2-decoder"

# Check if the model is already downloaded in the local folder
if os.path.exists(local_model_dir):
    print("Loading model from local directory...")
    pipeline = AutoPipelineForImage2Image.from_pretrained(
        local_model_dir, torch_dtype=torch.float32  # Using float32 for CPU
    )
else:
    print("Downloading model from Hugging Face Hub...")
    pipeline = AutoPipelineForImage2Image.from_pretrained(
        "kandinsky-community/kandinsky-2-2-decoder", torch_dtype=torch.float32  # Using float32 for CPU
    )
    # Save the model to the local folder for future use
    pipeline.save_pretrained(local_model_dir)

# Load the initial image from a local file instead of a URL
# Replace 'path_to_your_image.png' with the actual path to your local image file
init_image = Image.open("./download.jpg")

# Define the prompt for the image transformation
prompt = "cat wizard, gandalf, lord of the rings, detailed, fantasy, cute, adorable, Pixar, Disney, 8k"

# Generate the new image based on the prompt and initial image
image = pipeline(prompt, image=init_image,strength=0.6,guidance_scale=10).images[0]

# Save the generated image with the model name in the filename
image.save("./image/kandinsky-2-2-decoder_gen_img.png")

# Optionally, create a grid of the initial and transformed images for comparison
grid_image = make_image_grid([init_image, image], rows=1, cols=2)
grid_image.show()  # This will display the image grid
