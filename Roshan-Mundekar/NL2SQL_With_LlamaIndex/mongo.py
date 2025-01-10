from os import environ
from pymongo import MongoClient
from llama_index.core import VectorStoreIndex, StorageContext, Document
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai import OpenAI
from llama_index.core.vector_stores import SimpleVectorStore

# Load environment variables
OPENAI_API_KEY = environ.get("OPENAI_API_KEY")
MONGO_URI = environ.get("MONGO_URI")

if not OPENAI_API_KEY or not MONGO_URI:
    raise ValueError("Environment variables OPENAI_API_KEY and MONGO_URI must be set.")

# Initialize OpenAI embedding and LLM
embed_model = OpenAIEmbedding(model="text-embedding-ada-002", api_key=OPENAI_API_KEY)

# Passing prompt via OpenAI
custom_prompt = """
You are an expert database assistant. Answer questions specifically about the MongoDB database, collections, and their contents.
Ensure your responses are clear and concise, referencing the relevant collections.
"""
llm = OpenAI(api_key=OPENAI_API_KEY, prompt_template=custom_prompt)

# Connect to MongoDB
def get_mongo_client(uri):
    """Establish connection to MongoDB."""
    try:
        client = MongoClient(uri)
        print("Connected to MongoDB successfully")
        return client
    except Exception as e:
        raise ConnectionError(f"Failed to connect to MongoDB: {e}")

mongo_client = get_mongo_client(MONGO_URI)

# Function to fetch all collections and documents as indexed data
def fetch_documents_from_db(db_name):
    """Fetch documents from all collections in a database."""
    db = mongo_client[db_name]
    documents = []

    for collection_name in db.list_collection_names():
        collection = db[collection_name]
        for doc in collection.find():
            text_content = f"Collection: {collection_name} " + " ".join([f"{key}: {value}" for key, value in doc.items() if key != "_id"])
            documents.append(Document(text=text_content))
    
    return documents

# Fetch documents from the specified database
DB_NAME = "testdb"
documents = fetch_documents_from_db(DB_NAME)

# Initialize vector store and create index
vector_store = SimpleVectorStore(embed_model=embed_model)
storage_context = StorageContext.from_defaults(vector_store=vector_store)
index = VectorStoreIndex.from_documents(documents, storage_context=storage_context)

# Query engine
query_engine = index.as_query_engine(similarity_top_k=3)
print(query_engine)
# User query
query = "give me top 3 records in grades collection?"

try:
    response = query_engine.query(query)
    print("Query Response:")
    print(response.response)
except Exception as e:
    print(f"Error during query execution: {e}")
