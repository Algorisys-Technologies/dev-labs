from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.llms import GPT4All
from llama_index.core.node_parser import SimpleFileNodeParser
from langchain_text_splitters import TokenTextSplitter
from llama_index.readers.mongodb import SimpleMongoReader
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# MongoDB connection parameters
host = os.getenv("MONGO_URI", "mongodb+srv://yashurishu22:yash1999@cluster0.qkksqbm.mongodb.net/")
port = int(os.getenv("MONGO_PORT", 27017))
db_name = os.getenv("MONGO_DB", "Event-Management")
collection_name = os.getenv("MONGO_COLLECTION", "clients")
field_names = ["title", "plot", "fullplot"]

# Query filter (can be adjusted as needed)
query_dict = {}

# Load documents from MongoDB
reader = SimpleMongoReader(host, port)
documents = reader.load_data(
    db_name=db_name,
    collection_name=collection_name,
    field_names=field_names,
    query_dict=query_dict
)

# Print a document to test the loading
if documents:
    print("Loaded document:", documents[1])
else:
    print("No documents loaded.")
    
    
from flask import Flask, request, jsonify, render_template
import json
from sqlalchemy import create_engine, text, inspect
from llama_index.core import SQLDatabase, VectorStoreIndex
from llama_index.core.indices.struct_store.sql_query import SQLTableRetrieverQueryEngine
from llama_index.core.objects import ObjectIndex, SQLTableNodeMapping, SQLTableSchema
from llama_index.llms.openai import OpenAI
from llama_index.core import Settings
from sqlalchemy.engine import URL
import openai
openai.api_key = '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'
app = Flask(__name__)

# Load database configurations
def load_databases():
    with open('db.json', 'r') as file:
        return json.load(file)["databases"]

# Helper function to create database engines dynamically
def create_engine_for_db(db_config):
    if db_config["type"] == "mysql":
        connection_string = f"mysql+pymysql://{db_config['user']}:{db_config['password']}@{db_config['host']}/{db_config['db_name']}?charset=utf8"
    elif db_config["type"] == "postgresql":
        connection_string = f"postgresql://{db_config['user']}:{db_config['password']}@{db_config['host']}/{db_config['db_name']}"
    elif db_config["type"] == "Ms_sql_server":
        connection_url = (
            "Driver={ODBC Driver 17 for SQL Server};"
            f"Server={db_config['host']};"
            f"Database={db_config['db_name']};"
            f"UID={db_config['user']};"
            f"PWD={db_config['password']};"
            "Trusted_Connection=no;"
        )
        connection_string = URL.create("mssql+pyodbc", query={"odbc_connect": connection_url})
    else:
        raise ValueError(f"Unsupported database type: {db_config['type']}")
    return create_engine(connection_string)

# Extract schema information from the database
def extract_schema(engine):
    inspector = inspect(engine)
    schema_info = ""
    for table_name in inspector.get_table_names():
        schema_info += f"Table: {table_name}\n"
        columns = inspector.get_columns(table_name)
        for column in columns:
            schema_info += f"  Column: {column['name']}, Type: {column['type']}\n"
        schema_info += "\n"
    return schema_info

# Generate SQL query using OpenAI LLM
def generate_sql_query(query_str, sql_database, obj_index,schema_info):
    prompt = f"""
    You are an agent designed to interact with a SQL database. 
    
    Given the following question, generate only the correct SQL query to retrieve the requested information.
    Database Schema:
    {schema_info}

    User Query:
    {query_str}

    SQL Query (only the query, no explanations or additional text):
    """
    Settings.llm = OpenAI(model="gpt-3.5-turbo")
    query_engine = SQLTableRetrieverQueryEngine(
        sql_database, obj_index.as_retriever(similarity_top_k=3), service_context=Settings
    )
    sql_query_response = query_engine.query(prompt)
    return sql_query_response.text.strip() if hasattr(sql_query_response, 'text') else str(sql_query_response).strip()

# Final query execution and correction
# def final_query_execute(sql_query, schema_info, query_str):
    
#     print("==============")
#     prompt = f"""
#     You are a SQL expert. Validate and correct the following query:
    
#     Database Schema:
#     {schema_info}

#     User Query:
#     {query_str}

#     Generated SQL Query:
#     {sql_query}

#     Provide a syntactically correct and optimized  only query.
#     """
#     corrected_query = Settings.llm.call(prompt).strip()
#     print(corrected_query)
#     return corrected_query

def final_query_execute(sql_query, schema_info, query_str, sql_database, obj_index):
    """
    Use OpenAI Chat API to validate and correct SQL query.
    """

    print("==============")
    
    prompt = f"""
    You are an agent designed to interact with a SQL database. 
    
    Given the following question, generate only the correct SQL query to retrieve the requested information.
    You are a SQL expert. Validate and correct the following query:

    Database Schema:
    {schema_info}

    User Query:
    {query_str}

    Generated SQL Query:
    {sql_query}

    SQL Query (only the query, no explanations or additional text):
    """

    Settings.llm = OpenAI(model="gpt-3.5-turbo")
    query_engine = SQLTableRetrieverQueryEngine(
        sql_database, obj_index.as_retriever(similarity_top_k=3), service_context=Settings
    )
    
    sql_query_response = query_engine.query(prompt)
    
    # Extract SQL query only
    clean_response = sql_query_response.text.strip() if hasattr(sql_query_response, 'text') else str(sql_query_response).strip()
    
    return clean_response

@app.route('/')
def index():
    databases = load_databases()
    return render_template('main.html', databases=databases)

@app.route('/api/query', methods=['POST'])
def query():
    data = request.json
    query_str = data.get('query')
    selected_db_name = data.get('db_name')

    if not query_str or not selected_db_name:
        return jsonify({'success': False, 'message': 'Missing query or database name.'})

    databases = load_databases()
    db_config = next((db for db in databases if db["type"] == selected_db_name), None)
    if not db_config:
        return jsonify({'success': False, 'message': f'Database "{selected_db_name}" not found.'})

    engine = create_engine_for_db(db_config)
    try:
        schema_info = extract_schema(engine)
        sql_database = SQLDatabase(engine)
        table_schema_objs = [SQLTableSchema(table_name=table) for table in sql_database._all_tables]
        table_node_mapping = SQLTableNodeMapping(sql_database)
        obj_index = ObjectIndex.from_objects(table_schema_objs, table_node_mapping, VectorStoreIndex)

        sql_query = generate_sql_query(query_str, sql_database, obj_index,schema_info)
        print()
        print("sql_query")
        print(sql_query)
        print(query_str)
        print(schema_info)
        print()
        final_query = final_query_execute(sql_query, schema_info, query_str, sql_database, obj_index)
        print("final_query")
        
        print(final_query)
        
        with engine.connect() as connection:
            result = connection.execute(text(final_query))
            rows = result.fetchall()
            columns = result.keys()

        return jsonify({
            'success': True,
            'sql_query': final_query,
            'result': [dict(zip(columns, row)) for row in rows]
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e),
            'sql_query': sql_query if 'sql_query' in locals() else None
        })

if __name__ == '__main__':
    # app.run(debug=True)
    app.run('0.0.0.0')
    
