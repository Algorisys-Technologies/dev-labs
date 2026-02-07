import os
import yaml  # Ensure you import the yaml module to read your config file
from langchain.prompts import PromptTemplate
from langchain.chat_models import ChatOpenAI  # Use ChatOpenAI for chat models
from langchain.chains import LLMChain
import openai
# Load the OpenAI API key from a YAML configuration file
api_key = None
CONFIG_PATH = "config.yaml"

# Load the API key from the config.yaml file
def load_config(config_path):
    with open(config_path, 'r') as file:
        config = yaml.safe_load(file)
    return config['openai']['api_key']

# Set the OpenAI API key as an environment variable
# os.environ['OPENAI_API_KEY'] = api_key

# Load the API key
api_key = load_config(CONFIG_PATH)
openai.api_key = api_key  # Set the API key for OpenAI


# Email summarizer function
def email_summarizer(email, subject):
    # Initialize the ChatOpenAI model with the desired model and parameters
    llm = ChatOpenAI(
        model_name='gpt-3.5-turbo',
        temperature=1,
        max_tokens=256,
        openai_api_key=api_key  # Pass the API key directly here
    )

    # Define the prompt templates for different analyses
    templates = {
        'sender': "Determine the sender from the following subject: {subject}\n\n and email:\n\n{email}\n\nSender:",
        'role': "Determine the role of the sender from the following subject: {subject}\n\n and email:\n\n{email}\n\nRole:",
        'tone': "Provide the overall tone from the following subject: {subject}\n\n and email:\n\n{email}\n\nTone:",
        'summary': "Write a brief summary from the following subject: {subject}\n\n and email:\n\n{email}\n\nSummary:",
        'spam': "Determine if the following email is spam. I am a developer dealing with new clients, business connections and financial transactions. A lot of links are shared. Is this email spam or not:\n\nSubject: {subject}\n\nEmail:\n{email}\n\nIs Spam?:",
    }

    outputs = {}

    # Loop through each template and run it to get the corresponding output
    for key, template in templates.items():
        # Create a PromptTemplate with the necessary input variables
        prompt = PromptTemplate(input_variables=["email", "subject"], template=template)
        
        # Create an LLMChain for the current template
        chain = LLMChain(llm=llm, prompt=prompt)
        
        # Run the chain and store the output
        try:
            output = chain.run(email=email, subject=subject)
            outputs[key] = output
        except Exception as e:
            # If an error occurs, log it and set the output to None
            print(f"Error processing {key}: {str(e)}")
            outputs[key] = None

    return outputs


# # Example usage:
# if __name__ == "__main__":
#     email_content = "Hello, I hope you are doing well. Please find attached the documents we discussed."
#     email_subject = "Documents for Review"
    
#     summary_result = email_summarizer(email_content, email_subject)
#     print(summary_result)
