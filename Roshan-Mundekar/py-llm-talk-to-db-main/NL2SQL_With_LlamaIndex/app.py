from flask import Flask, request, jsonify, render_template
import json
from sqlalchemy import create_engine, text
from llama_index.core import SQLDatabase, VectorStoreIndex
from llama_index.core.indices.struct_store.sql_query import SQLTableRetrieverQueryEngine
from llama_index.core.objects import ObjectIndex, SQLTableNodeMapping, SQLTableSchema
from llama_index.llms.openai import OpenAI
from llama_index.core import Settings

app = Flask(__name__)

# Load database configurations
def load_databases():
    with open('db.json', 'r') as file:
        return json.load(file)["databases"]

# Helper function to create database engines dynamically
def create_engine_for_db(db_config):
    connection_string = None
    if db_config["type"] == "mysql":
        connection_string = f"mysql+pymysql://{db_config['user']}:{db_config['password']}@{db_config['host']}/{db_config['db_name']}?charset=utf8"

    elif db_config["type"] == "postgresql":
        connection_string = f"postgresql://{db_config['user']}:{db_config['password']}@{db_config['host']}/{db_config['db_name']}"
    
    
    return create_engine(connection_string)

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

@app.route('/')
def index():
    databases = load_databases()
    return render_template('main.html', databases=databases)

@app.route('/api/query', methods=['POST'])
def query():
    data = request.json
    query_str = data.get('query')
    selected_db_name = data.get('db_name')
    
    print(query_str)
    print("-----------------------")
    print(selected_db_name)

    if not query_str or not selected_db_name:
        return jsonify({'success': False, 'message': 'Missing query or database name.'})

    databases = load_databases()
    db_config = next((db for db in databases if db["type"] == selected_db_name), None)
    if not db_config:
        return jsonify({'success': False, 'message': f'Database "{selected_db_name}" not found.'})

    try:
        engine = create_engine_for_db(db_config)
        sql_database = SQLDatabase(engine)
        table_schema_objs = [SQLTableSchema(table_name=table) for table in sql_database._all_tables]
        table_node_mapping = SQLTableNodeMapping(sql_database)
        obj_index = ObjectIndex.from_objects(table_schema_objs, table_node_mapping, VectorStoreIndex)

        sql_query = generate_sql_query(query_str, sql_database, obj_index)
        
        print(sql_query)
        with engine.connect() as connection:
            result = connection.execute(text(sql_query))
            rows = result.fetchall()
            columns = result.keys()

        return jsonify({
            'success': True,
            'sql_query': sql_query,
            'result': [dict(zip(columns, row)) for row in rows]
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e),
            'sql_query': sql_query if 'sql_query' in locals() else None
        })

if __name__ == '__main__':
    app.run(debug=True)
