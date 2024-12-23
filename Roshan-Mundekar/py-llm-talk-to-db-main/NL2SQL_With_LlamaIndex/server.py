from flask import Flask, request, jsonify,render_template
import openai
import pandas as pd
from sqlalchemy import create_engine, text
from llama_index.core import VectorStoreIndex
from llama_index.llms.openai import OpenAI
from llama_index.core import Settings
from llama_index.core.indices.struct_store.sql_query import SQLTableRetrieverQueryEngine
from llama_index.core.objects import ObjectIndex, SQLTableNodeMapping, SQLTableSchema

# Set up Flask
app = Flask(__name__)

# # Set your OpenAI API key
# openai.api_key = "your-openai-api-key"  # Replace with your actual OpenAI API key

# Database connection details
db_user = "root"
db_password = "root"
db_host = "localhost"
db_name = "classicmodels"

# Create SQLAlchemy engine
connection_string = f"mysql+pymysql://{db_user}:{db_password}@{db_host}/{db_name}?charset=utf8"
engine = create_engine(connection_string)

# Create SQLDatabase object
from llama_index.core import SQLDatabase
sql_database = SQLDatabase(engine)

# List all tables in the database
tables = sql_database._all_tables

# Create SQL table schema descriptions
table_schema_objs = []
for table in tables:
    table_schema_objs.append(SQLTableSchema(table_name=table))

# Initialize ObjectIndex and SQLTableNodeMapping
table_node_mapping = SQLTableNodeMapping(sql_database)
obj_index = ObjectIndex.from_objects(table_schema_objs, table_node_mapping, VectorStoreIndex)

# Define the SQL query generation function
def generate_sql_query(query_str):
    """
    Given a natural language question, generate the correct SQL query for the database.
    This uses LlamaIndex's query engine to generate the SQL query from the input question.
    """
    # Define the prompt for the model with a clear instruction to only generate SQL query
    prompt = f"""
    You are an agent designed to interact with a SQL database. 
    Given the following question, generate only the correct SQL query to retrieve the requested information.
    
    Question: {query_str}
    SQL Query (only the query, no explanations or additional text):
    """
    
    # Initialize the OpenAI model for query generation
    Settings.llm = OpenAI(model="gpt-3.5-turbo")  # Set model to use

    # Initialize SQL Table Retrieval Engine
    query_engine = SQLTableRetrieverQueryEngine(
        sql_database, obj_index.as_retriever(similarity_top_k=3), service_context=Settings
    )

    # Query the engine to generate a SQL query based on the prompt
    sql_query_response = query_engine.query(prompt)

    # Check if the response has a 'text' attribute and extract the query
    if hasattr(sql_query_response, 'text'):
        sql_query = sql_query_response.text.strip()  # Extract the SQL query text and remove extra spaces
    else:
        # If the response does not have a 'text' attribute, fall back to using str() for extraction
        sql_query = str(sql_query_response).strip()

    return sql_query

@app.route('/')
def index():
    
    return render_template('index.html')
    
@app.route('/api/query', methods=['POST'])
def query():
    data = request.json
    query_str = data.get('query')

    if not query_str:
        return jsonify({'success': False, 'message': 'No query provided.'})

    try:
        # Generate SQL query
        sql_query = generate_sql_query(query_str)

        # Print the generated SQL query for debugging
        print(f"Generated SQL Query: {sql_query}")

        # Execute SQL query
        with engine.connect() as connection:
            result = connection.execute(text(sql_query))
            rows = result.fetchall()
            columns = result.keys()

        # Return the SQL query and the result in JSON format
        return jsonify({
            'success': True,
            'sql_query': sql_query,
            'result': [dict(zip(columns, row)) for row in rows]
        })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e),
            'sql_query': sql_query  # Return the SQL query even in case of an error
        })
        
        
if __name__ == '__main__':
    app.run(debug=True)
