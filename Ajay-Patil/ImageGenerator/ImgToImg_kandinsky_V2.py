import torch
from diffusers import AutoPipelineForImage2Image
from diffusers.utils import make_image_grid, load_image
import os
from PIL import Image

# Directory where the model will be saved
save_directory = "kandinsky-2-2-decoder"

# Check if the model is already saved locally
if os.path.exists(save_directory):
    # Load the model from the local directory
    pipeline = AutoPipelineForImage2Image.from_pretrained(save_directory)
else:
    # Load the model from the internet and save it locally
    pipeline = AutoPipelineForImage2Image.from_pretrained(
        "kandinsky-community/kandinsky-2-2-decoder"
    )
    # Save the model locally
    pipeline.save_pretrained(save_directory)

# Prepare image
# url = "https://huggingface.co/datasets/huggingface/documentation-images/resolve/main/diffusers/img2img-init.png"
# init_image = load_image(url)

image_path = "./download.jpg"
init_image = Image.open(image_path)

prompt = "The image is of a beautiful diamond engagement ring. The ring is made of yellow gold and has a round brilliant cut diamond in the center. The diamond is surrounded by a halo of smaller diamonds on either side. The band of the ring is also covered in small diamonds, creating a sparkling effect. The overall design is elegant and luxurious."
negative_prompt = "blurry, out of focus, low resolution, extra diamonds, distorted ring shape, broken band, dark lighting, dull colors, deformed diamonds, cartoonish, pixelated, poorly rendered, flat, unrealistic reflections, cheap appearance, tarnished metal, unnatural shadows, dirty, scratches, overly ornate, gaudy, unbalanced design, misaligned halo, cracked diamond, chipped, rusted."
# Generate the image
image = pipeline(prompt,negative_prompt=negative_prompt,guidance_scale=3,strength=0.5, image=init_image).images[0]

# Save the generated image locally
image.save("./image/kandinskyV2.png")

# Display the original and generated images side by side
grid = make_image_grid([init_image, image], rows=1, cols=2)
grid.show()