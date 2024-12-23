import os
import torch
from diffusers import AutoPipelineForImage2Image
from diffusers.utils import make_image_grid, load_image
from PIL import Image

# Define model ID and local model directory
model_id = "runwayml/stable-diffusion-v1-5"
local_model_dir = "./models/stable-diffusion-v1-5"

# Check if the model exists locally
if not os.path.exists(local_model_dir):
    print("Downloading and saving the model...")
    pipeline = AutoPipelineForImage2Image.from_pretrained(
        model_id, use_safetensors=True
    )
    # Save the model locally
    pipeline.save_pretrained(local_model_dir)
else:
    print("Loading the model from local storage...")
    pipeline = AutoPipelineForImage2Image.from_pretrained(local_model_dir)

# Enable CPU offloading
pipeline.to('cpu')

# Prepare the initial image
image_path = "download.jpg"  # Replace with your actual image path
init_image = Image.open(image_path).convert("RGB")

# Define the prompt
prompt = "The image is of a beautiful diamond engagement ring. The ring is made of yellow gold and has a round brilliant cut diamond in the center. The diamond is surrounded by a halo of smaller diamonds on either side. The band of the ring is also covered in small diamonds, creating a sparkling effect. The overall design is elegant and luxurious."

# Pass prompt and image to pipeline
image = pipeline(prompt, image=init_image, guidance_scale=8.0).images[0]

# Create a directory for saving generated images
output_dir = "image"
os.makedirs(output_dir, exist_ok=True)

# Save the generated image
output_path = os.path.join(output_dir, "SD_GenImg.png")
image.save(output_path)
print(f"Generated image saved at: {output_path}")

# Display the images
make_image_grid([init_image, image], rows=1, cols=2).show()
