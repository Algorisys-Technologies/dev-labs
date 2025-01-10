from flask import Flask, request, jsonify, render_template
import json
from sqlalchemy import create_engine, text
from llama_index.core import SQLDatabase, VectorStoreIndex
from llama_index.core.indices.struct_store.sql_query import SQLTableRetrieverQueryEngine
from llama_index.core.objects import ObjectIndex, SQLTableNodeMapping, SQLTableSchema
from llama_index.llms.openai import OpenAI
from llama_index.core import Settings
import pyodbc

# Define connection parameters
db_config = {
    "name": "SQLServer_DB",
    "type": "sql_server",
    "host": "DESKTOP-SFJI2T5\\SQLEXPRESS",  # Adjust the host as per your configuration
    "user": "sa",
    "password": "admin@123",
    "database": "Chinook"
}

# Create the ODBC connection string with port
def connect_sql_server(db_details):
    try:
        conn = pyodbc.connect(
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={db_details['host']};" 
            f"DATABASE={db_details['database']};" 
            f"UID={db_details['user']};"
            f"PWD={db_details['password']};"
        )
        return conn
    except Exception as e:
        return str(e)

# Function to execute query and fetch data
def execute_query(conn, query):
    try:
        cursor = conn.cursor()
        cursor.execute(query)
        result = cursor.fetchall()  # Fetch all rows from the result
        return result   
    except Exception as e:
        return str(e)


# Define the SQL query generation function
def generate_sql_query(query_str, sql_database, obj_index):
    prompt = f"""
    You are an agent designed to interact with a SQL database. 
    
    Given the following question, generate only the correct SQL query to retrieve the requested information.
    
    Question: {query_str}
    SQL Query (only the query, no explanations or additional text):
    """
    Settings.llm = OpenAI(model="gpt-3.5-turbo")
    query_engine = SQLTableRetrieverQueryEngine(
        sql_database, obj_index.as_retriever(similarity_top_k=3), service_context=Settings
    )
    sql_query_response = query_engine.query(prompt)
    return sql_query_response.text.strip() if hasattr(sql_query_response, 'text') else str(sql_query_response).strip()



# Function to create SQLAlchemy engine
def create_engine_for_db(db_config):
    connection_string = (
        f"mssql+pyodbc://{db_config['user']}:{db_config['password']}@{db_config['host']}/{db_config['database']}?driver=ODBC+Driver+17+for+SQL+Server"
    )
    return create_engine(connection_string)

# Flask app or script logic
connection = connect_sql_server(db_config)
if isinstance(connection, pyodbc.Connection):
    print("Connection successful!")
    
    # SQL Query to fetch data from the Album table
    query = "SELECT TOP 10 * FROM Album"
    
    # Execute query and fetch results
    data = execute_query(connection, query)
    
    if isinstance(data, list):  # Check if data is a list of rows
        for row in data:
            print(row)  # Print each row
    else:
        print(f"Query failed: {data}")
    
    # Close the connection after use
    connection.close()
else:
    print(f"Connection failed: {connection}")

# Create SQLAlchemy engine
engine = create_engine_for_db(db_config)

# Using LlamaIndex to generate SQL queries and execute them
sql_database = SQLDatabase(engine)
table_schema_objs = [SQLTableSchema(table_name=table) for table in sql_database._all_tables]
table_node_mapping = SQLTableNodeMapping(sql_database)
obj_index = ObjectIndex.from_objects(table_schema_objs, table_node_mapping, VectorStoreIndex)

# Example query for LlamaIndex to process
query_str = "SELECT * FROM Album WHERE ArtistId = 1"

# Generate SQL query with LlamaIndex
sql_query = generate_sql_query(query_str, sql_database, obj_index)

print("Generated SQL Query:", sql_query)

