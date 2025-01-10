import openai
from pymongo import MongoClient
import json
import logging
from dotenv import load_dotenv
import os
import re
import streamlit as st
import pandas as pd
from prettytable import PrettyTable

# Load environment variables
load_dotenv()
openai.api_key = os.getenv("OPENAI_API_KEY")

# Connect to the MongoDB server
client = MongoClient("mongodb://localhost:27017/")

# Access a database (create one if it doesn't exist)
db = client["testdb"]

# Configure logging
logging.basicConfig(filename="query_errors.log", level=logging.ERROR)

def scrape_database_info():
    """
    Scrape metadata about the database, including number of records, fields, and their data types.
    Save the metadata in a text file for reference.
    """
    database_info = {}

    collections = db.list_collection_names()

    for coll_name in collections:
        collection = db[coll_name]

        record_count = collection.count_documents({})
        sample_doc = collection.find_one()

        fields = {}
        examples = []
        if sample_doc:
            for key, value in sample_doc.items():
                fields[key] = type(value).__name__
            examples.append(sample_doc)

        database_info[coll_name] = {
            "record_count": record_count,
            "fields": fields,
            "examples": examples[:5]
        }

    with open("database_info.txt", "w") as file:
        json.dump(database_info, file, indent=4, default=str)

    print("Database information scraped and saved to database_info.txt.")

def load_database_info():
    """Load the database information from the saved text file."""
    try:
        with open("database_info.txt", "r") as file:
            return json.load(file)
    except FileNotFoundError:
        print("Database info file not found. Please run the scraper first.")
        return {}

def identify_collection_with_openai(user_query, db_info):
    """
    Use OpenAI GPT-3.5 to identify the relevant collection.
    """
    metadata_summary = {name: {"fields": meta["fields"]} for name, meta in db_info.items()}

    prompt = f"""
    Based on the database metadata provided below and the user query, identify the most relevant collection name.

    Metadata:
    {json.dumps(metadata_summary, indent=4)}

    User Query: "{user_query}"

    Respond with only the collection name.
    """

    try:
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "system", "content": "You are a MongoDB collection identifier."},
                      {"role": "user", "content": prompt}],
            max_tokens=50,
            temperature=0.0
        )

        collection_name = response['choices'][0]['message']['content'].strip()
        print(f"OpenAI Response for Collection: {collection_name}")

        if collection_name in db_info:
            return collection_name
        else:
            raise ValueError(f"OpenAI identified invalid collection: {collection_name}")
    except Exception as e:
        logging.error(f"Failed to identify collection using OpenAI: {e}")
        raise ValueError("Unable to identify the relevant collection. Please refine your query.")

def preprocess_query(user_query):
    """Simplify and clarify user queries for better AI understanding."""
    replacements = {
        "who are": "",
        "that are": "",
        "between": "from",
        "and": "to"
    }
    for key, value in replacements.items():
        user_query = user_query.replace(key, value)
    return user_query.strip()

def validate_query(query, db_info, collection_name):
    """Validate the generated query against the database schema, including field types."""
    collection_info = db_info[collection_name]

    for key, value in query.items():
        if key not in collection_info["fields"]:
            raise ValueError(f"Invalid field: {key}")
    return True

def generate_mongo_query(query_str, db_info, collection_name):
    """Generate a MongoDB query using OpenAI API based on user input and database info."""
    prompt = f"""
    You are an expert MongoDB query generator. 
    Generate a MongoDB query in JSON format that is directly usable with pymongo.
    Ensure the response contains only the JSON object and nothing else.

    Here is the database metadata for your reference:
    {json.dumps(db_info[collection_name], indent=4)}

    Question: {query_str}
    JSON Query:
    """

    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "system", "content": "You are an expert MongoDB query generator."},
                  {"role": "user", "content": prompt}],
        max_tokens=150,
        temperature=0.0
    )

    query_text = response['choices'][0]['message']['content'].strip()
    print("OpenAI Response:", query_text)

    try:
        query_dict = json.loads(query_text)
        return query_dict
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON response from OpenAI: {e}")

def display_results_in_table(results):
    """Display query results in a tabular format."""
    if not results:
        return "No results found."

    # Convert results to DataFrame for better table presentation
    df = pd.DataFrame(results)
    return df

# Streamlit app
st.title("MongoDB Query Assistant")

st.sidebar.header("Actions")
if st.sidebar.button("Scrape Database Info"):
    try:
        scrape_database_info()
        st.sidebar.success("Database information scraped and saved.")
    except Exception as e:
        st.sidebar.error(f"Error: {e}")

# Load database info
try:
    db_info = load_database_info()
except Exception as e:
    st.error(f"Error loading database info: {e}")
    db_info = {}

# Input query
user_query = st.text_area("Enter your query:")

if st.button("Submit Query"):
    if not db_info:
        st.error("Database information is not available. Please scrape the database info first.")
    elif not user_query.strip():
        st.error("Please enter a query.")
    else:
        try:
            preprocessed_query = preprocess_query(user_query)

            # Identify collection
            collection_name = identify_collection_with_openai(preprocessed_query, db_info)
            st.write(f"Collection identified: {collection_name}")

            # Generate Mongo query
            mongo_query = generate_mongo_query(preprocessed_query, db_info, collection_name)
            validate_query(mongo_query, db_info, collection_name)

            # Execute query
            collection = db[collection_name]
            result = list(collection.find(mongo_query))

            # Display results as a table
            result_table = display_results_in_table(result)
            if isinstance(result_table, pd.DataFrame):
                st.dataframe(result_table)  # Display the DataFrame as a table in Streamlit
            else:
                st.text(result_table)
        except ValueError as val_error:
            st.error(f"Validation Error: {val_error}")
        except Exception as gen_error:
            logging.error(f"Failed to process query: {preprocessed_query}. Error: {gen_error}")
            st.error("Failed to process query. Please refine your input.")
