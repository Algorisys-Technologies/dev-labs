import openai
import yaml

# Load the API key from the config.yaml file
def load_config(config_path):
    with open(config_path, 'r') as file:
        config = yaml.safe_load(file)
    return config['openai']['api_key']

# Path to your config file
CONFIG_PATH = "config.yaml"

# Load the API key
api_key = load_config(CONFIG_PATH)
openai.api_key = api_key  # Set the API key for OpenAI

def ats_extractor(resume_data):
    # Print the incoming resume data for debugging
    # print(resume_data)

    # Define the prompt for the OpenAI model
    prompt = '''
    Summarize the content of the uploaded PDF file by extracting the following information into a structured table format. 
    If any field is missing or not applicable in the document, please indicate it as "N/A."

    1. products delivered country. 
    2. category of the stammed product type.
    

    Provide the summarized information in JSON format.
    '''
    # Prepare the messages to be sent to the OpenAI API
    messages = [
        {"role": "system", "content": prompt},
        {"role": "user", "content": resume_data}
    ]

    # Call OpenAI's chat completion API
    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=messages,
        temperature=0.0,
        max_tokens=1500
    )
    

    # Extract the content from the API response
    data = response.choices[0].message.content
    print(data)
    return data

# Example usage
# if __name__ == "__main__":
#     resume_example = """
#     John Doe
#     Email: john.doe@example.com
#     GitHub: https://github.com/johndoe
#     LinkedIn: https://linkedin.com/in/johndoe
#     Employment:
#     - Company: ABC Corp
#       Role: Software Engineer
#       Duration: 2019 - Present
#     - Company: XYZ Inc
#       Role: Intern
#       Duration: 2018
#     Technical Skills: Python, JavaScript, SQL
#     Soft Skills: Communication, Teamwork
#     """

#     extracted_info = ats_extractor(resume_example)
#     print(extracted_info)
