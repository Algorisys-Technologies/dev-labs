import os
import gradio as gr
import openai
from openai import AuthenticationError, RateLimitError
from pymongo.mongo_client import MongoClient
from pymongo.server_api import ServerApi
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.vector_stores.mongodb import MongoDBAtlasVectorSearch
from llama_index.core import VectorStoreIndex
from llama_index.llms.openai import OpenAI

# Load environment variables
MONGO_URI = os.getenv("MONGO_URI")
# OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

import os
os.environ['OPENAI_API_KEY'] = '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'


# MongoDB Client Initialization
try:
    mongo_client = MongoClient(MONGO_URI, server_api=ServerApi('1'))
    mongo_client.admin.command('ping')
    print("Pinged your MongoDB deployment. Connection successful!")
except Exception as e:
    print(f"Error connecting to MongoDB: {e}")
    mongo_client = None

# MongoDB Atlas Vector Store
if mongo_client:
    store = MongoDBAtlasVectorSearch(
        mongodb_client=mongo_client,
        db_name="sample_mflix",
        collection_name="movies",
        index_name="vector_index",
        embedding_key="embedding",
    )
else:
    store = None
    print("Failed to initialize MongoDBAtlasVectorSearch due to client issues.")

# Function to validate OpenAI API Key
def is_valid_openai_api_key(api_key):
    openai.api_key = api_key
    try:
        openai.Completion.create(
            model="gpt-3.5-turbo",
            prompt="Your input text here",
            max_tokens=100
        )

        return True
    except AuthenticationError:
        return False
    except Exception as e:
        print(f"Unexpected error validating OpenAI API key: {e}")
        return False

# Create a query engine using the provided API key
def prepare_query_engine():
    OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')

    embed_model = OpenAIEmbedding(
        model="text-embedding-ada-002",
        embed_batch_size=16,
        api_key=OPENAI_API_KEY,
        max_retries=2,
    )

    if store is None:
        raise ValueError("MongoDBAtlasVectorSearch is not initialized.")
    
    index_loaded = VectorStoreIndex.from_vector_store(
        vector_store=store, embed_model=embed_model
    )

    llm = OpenAI(
        model="gpt-3.5-turbo", temperature=0, max_tokens=512, api_key=OPENAI_API_KEY
    )

    query_engine = index_loaded.as_query_engine(
        llm=llm, streaming=True, similarity_top_k=3
    )
    return query_engine

# Generate response using the query engine
def generate(query):
    OPENAI_API_KEY=os.getenv('OPENAI_API_KEY')

    if not OPENAI_API_KEY.strip() or not is_valid_openai_api_key(OPENAI_API_KEY):
        yield "The OpenAI API key is invalid or not set. Check your environment variables."
    elif store is None:
        yield "MongoDB Vector Search is not initialized. Check your database connection."
    else:
        try:
            query_engine = prepare_query_engine()
            response = ""
            streaming_response = query_engine.query(query)
            for token in streaming_response.response_gen:
                response += token
                yield response
        except RateLimitError as e:
            yield f"Rate limit exceeded: {e}"
        except Exception as e:
            yield f"An error occurred: {e}"

# Gradio Interface
with gr.Blocks() as demo:
    gr.Markdown(
        """
        # Retrieval-Augmented Generation (RAG) Demo
        **GPT-3.5 Turbo with MongoDB Atlas Vector Search**
        """
    )
    query = gr.Textbox(label="Enter your query", placeholder="Ask a question", lines=2)
    answer = gr.Textbox(label="Answer", lines=4, interactive=False)
    submit_button = gr.Button("Submit")
    submit_button.click(generate, inputs=[query], outputs=[answer])

demo.launch(debug=True)
