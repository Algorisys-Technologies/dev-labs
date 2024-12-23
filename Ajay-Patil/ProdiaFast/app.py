import gradio as gr
import requests
import time
import json
import base64
import re
from flask import request, jsonify, Flask, render_template
from PIL import Image
from io import BytesIO

app = Flask(__name__)

class Prodia:
    def __init__(self, api_key, base=None):
        self.base = base or "https://api.prodia.com/v1"
        self.headers = {
            "X-Prodia-Key": api_key
        }

    def generate(self, params):
        response = self._post(f"{self.base}/sd/generate", params)
        return response.json()

    def transform(self, params):
        response = self._post(f"{self.base}/sd/transform", params)
        return response.json()

    def get_job(self, job_id):
        response = self._get(f"{self.base}/job/{job_id}")
        return response.json()

    def wait(self, job):
        job_result = job
        while job_result['status'] not in ['succeeded', 'failed']:
            time.sleep(0.25)
            job_result = self.get_job(job['job'])
        return job_result

    def list_models(self):
        response = self._get(f"{self.base}/sd/models")
        return response.json()

    def list_samplers(self):
        response = self._get(f"{self.base}/sd/samplers")
        return response.json()

    def _post(self, url, params):
        headers = {
            **self.headers,
            "Content-Type": "application/json"
        }
        response = requests.post(url, headers=headers, data=json.dumps(params))

        if response.status_code != 200:
            print("Error Details:", response.text)
            raise Exception(f"Bad Prodia Response: {response.status_code}")

        return response

    def _get(self, url):
        response = requests.get(url, headers=self.headers)

        if response.status_code != 200:
            raise Exception(f"Bad Prodia Response: {response.status_code}")

        return response


def image_to_base64(image):
    buffered = BytesIO()
    image.save(buffered, format="PNG")
    img_str = base64.b64encode(buffered.getvalue())
    return img_str.decode('utf-8')


def remove_id_and_ext(text):
    text = re.sub(r'\[.*\]$', '', text)
    extension = text[-12:].strip()
    if extension == "safetensors":
        text = text[:-13]
    elif extension == "ckpt":
        text = text[:-4]
    return text


def validate_params(params):
    for key, value in params.items():
        if value is None or value == '':
            raise ValueError(f"Parameter '{key}' is missing or invalid.")


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


prodia_client = Prodia(api_key='f89b5344-fb14-4e74-9809-032b4de5deaf')

@app.route('/')
def index():
    return render_template('index.html',sampling_method = prodia_client.list_samplers())

@app.route('/text_to_image', methods=['POST'])
def generate_txt2img():
    try:
        prompt = request.form['prompt']
        negative_prompt = request.form.get('negative-prompt', '')
        steps = request.form.get('steps', 50)  # Default steps if not provided
        sampling_method = request.form.get('sampling-method', 'default_sampler')  # Replace with a valid default sampler
        cfg_scale = request.form.get('cfg-scale', 7.0)  # Default CFG scale if not provided
        width = request.form.get('width', 512)  # Default width
        height = request.form.get('height', 512)  # Default height
        seed = request.form.get('seed', None)  # Optional seed

        result = txt2img(
            prompt=prompt,
            negative_prompt=negative_prompt,
            model='absolutereality_v181.safetensors [3d9d4d2b]',
            steps=int(steps),
            sampler=sampling_method,
            cfg_scale=float(cfg_scale),
            height=int(height),
            width=int(width),
            seed=int(seed) if seed else None
        )

        return f'<img src="{result}">'

    except ValueError as ve:
        return f"Invalid input: {str(ve)}", 400
    except Exception as e:
        return f"An error occurred: {str(e)}", 500


@app.route('/image_to_image', methods=['POST'])
def generate_img2img():
    try:
        prompt = request.form['prompt']
        negative_prompt = request.form.get('negative-prompt', '')
        steps = request.form.get('steps', 50)  # Default steps if not provided
        sampling_method = request.form.get('sampling-method', 'default_sampler')  # Replace with a valid default sampler
        cfg_scale = request.form.get('cfg-scale', 7.0)  # Default CFG scale if not provided
        denoising_strength = request.form.get('denoising-strength', 0.5)  # Default denoising strength
        width = request.form.get('width', 512)  # Default width
        height = request.form.get('height', 512)  # Default height
        seed = request.form.get('seed', None)  # Optional seed

        # Handle the uploaded image
        input_image = request.files['input-image']
        if input_image.filename == '':
            raise ValueError("No image selected for uploading")

        # Open the image using PIL
        input_image_pil = Image.open(input_image.stream).convert("RGBA")

        # Call the img2img function
        result = img2img(
            input_image=input_image_pil,  # Pass the PIL image instead of BytesIO
            denoising=float(denoising_strength),  # Use the denoising strength
            prompt=prompt,
            negative_prompt=negative_prompt,
            model='absolutereality_v181.safetensors [3d9d4d2b]',
            steps=int(steps),
            sampler=sampling_method,
            cfg_scale=float(cfg_scale),
            height=int(height),
            width=int(width),
            seed=int(seed) if seed else None
        )

        return f'<img src="{result}">'

    except ValueError as ve:
        return f"Invalid input: {str(ve)}", 400
    except Exception as e:
        return f"An error occurred: {str(e)}", 500

if __name__ == '__main__':
    app.run(debug=True)
