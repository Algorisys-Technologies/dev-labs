import json
from flask import Flask, request, jsonify, render_template
import pyodbc  # For SQL Server connection
import psycopg2  # For PostgreSQL connection
import pymysql  # For MySQL connection
from langchain.chat_models import ChatOpenAI
from langchain.prompts import PromptTemplate
from langchain.chains import LLMChain
import environ
from pymongo import MongoClient

# Initialize environment variables
env = environ.Env()
environ.Env.read_env()

API_KEY = env('OPENAI_API_KEY')

# Initialize OpenAI chat model directly using OpenAI's API
openai_model = ChatOpenAI(model="gpt-3.5-turbo", openai_api_key=API_KEY)

# Set up the SQL prompt template
sql_prompt_template = PromptTemplate(
    input_variables=["query"],
    template="Generate a SQL query for the following question: {query}"
)

# Set up the MongoDB query prompt template
mongodb_prompt_template = PromptTemplate(
    input_variables=["query"],
    template="Generate a MongoDB query for the following question: {query}"
)

# Set up the LLM chain to generate MongoDB queries
llm_chain_MongoDB = LLMChain(llm=openai_model, prompt=mongodb_prompt_template)



# Set up the LLM chain to generate SQL queries
llm_chain = LLMChain(llm=openai_model, prompt=sql_prompt_template)

app = Flask(__name__)

# Load database configuration from a JSON file
def load_databases():
    with open('db.json', 'r') as file:
        data = json.load(file)
    return data["databases"]

# Connect to database functions
def connect_sql_server(db_details):
    try:
        conn = pyodbc.connect(
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={db_details['host']};"
            f"DATABASE={db_details['database']};"
            f"UID={db_details['user']};"
            f"PWD={db_details['password']}"
        )
        return conn
    except Exception as e:
        return str(e)

def connect_mysql(db_details):
    try:
        conn = pymysql.connect(
            host=db_details['host'],
            user=db_details['user'],
            password=db_details['password'],
            database=db_details['database']
        )
        return conn
    except Exception as e:
        return str(e)

def connect_postgresql(db_details):
    try:
        conn = psycopg2.connect(
            host=db_details['host'],
            user=db_details['user'],
            password=db_details['password'],
            database=db_details['database']
        )
        return conn
    except Exception as e:
        return str(e)



# MongoDB connection function
def connect_mongodb(db_details):
    try:
        client = MongoClient(
            host=db_details['host'],
            port=db_details.get('port', 27017)  # Default MongoDB port
        )
        return client[db_details['database']]
    except Exception as e:
        return str(e)
    
    
@app.route('/')
def index():
    # Fetch databases and send to frontend
    databases = load_databases()
    return render_template('index.html', databases=databases)


# @app.route('/query', methods=['POST'])
# def query_db():
#     data = request.json
#     db_name = data.get("database")
#     user_query = data.get("query")

#     print("db_name")
#     print(db_name)
#     print("user_query")
#     print(user_query)
#     # Load database configurations from JSON
#     databases = load_databases()

#     # Find the database configuration
#     db_details = next((db for db in databases if db["name"] == db_name), None)

#     if not db_details:
#         return jsonify({"status": "error", "message": "Database not found."})

#     # Generate SQL query using LLM chain
#     try:
#         sql_query = llm_chain.run(user_query)
#         print(f"Generated SQL Query: {sql_query}")

#         # Connect to the appropriate database
#         conn = None
#         if db_details['type'] == 'mysql':
#             conn = connect_mysql(db_details)
#         elif db_details['type'] == 'sql_server':
#             conn = connect_sql_server(db_details)
#         elif db_details['type'] == 'postgresql':
#             conn = connect_postgresql(db_details)

#         if isinstance(conn, str):  # Error in connection (conn is an error message string)
#             return jsonify({"status": "error", "message": conn})

#         # Execute the query on the database
#         cursor = conn.cursor()
#         cursor.execute(sql_query)
#         result = cursor.fetchall()

#         # Convert results to a readable format (list of lists)
#         formatted_results = [list(row) for row in result]

#         return jsonify({
#             'sql_query': sql_query,
#             'results': formatted_results
#         })
    
#     except Exception as e:
#         return jsonify({
#             'status': 'error',
#             'message': str(e)
#         }), 400

#     finally:
#         # Close connection if it was successful
#         if conn and isinstance(conn, (pyodbc.Connection, psycopg2.extensions.connection, pymysql.connections.Connection)):
#             conn.close()



@app.route('/query', methods=['POST'])
def query_db():
    data = request.json
    db_name = data.get("database")
    user_query = data.get("query")
    print("=======================================================")
    print("db_name")
    print(db_name)
    print("user_query")
    print(user_query)
    print("=======================================================")
    # Load database configurations from JSON
    databases = load_databases()

    # Find the database configuration
    db_details = next((db for db in databases if db["name"] == db_name), None)

    if not db_details:
        return jsonify({"status": "error", "message": "Database not found."})

    conn = None  # Initialize conn to avoid UnboundLocalError

    try:
        if db_details['type'] == 'mongodb':
            # Generate the MongoDB query using LLM Chain
            mongo_query = llm_chain_MongoDB.invoke(user_query)
            # mongo_query = llm_chain_MongoDB.run(user_query)
            
            print(f"Generated MongoDB Query: {mongo_query}")

            # Connect to MongoDB
            db = connect_mongodb(db_details)
            print(db)
            if isinstance(db, str):  # Error in connection
                return jsonify({"status": "error", "message": db})

            # Execute MongoDB Query
            collection_name = "TodoAppFARM"  # Replace with actual collection name
            collection = db[collection_name]
            mongo_query_obj = json.loads(mongo_query)  # Parse string query into JSON object
            results = list(collection.find(mongo_query_obj))
            print("results")
            print(results)

            return jsonify({
                'query': mongo_query,
                'results': results
            })

        else:
            sql_query = llm_chain.run(user_query)
            print(f"Generated SQL Query: {sql_query}")

            # Connect to relational database
            if db_details['type'] == 'mysql':
                conn = connect_mysql(db_details)
            elif db_details['type'] == 'sql_server':
                conn = connect_sql_server(db_details)
            elif db_details['type'] == 'postgresql':
                conn = connect_postgresql(db_details)

            if isinstance(conn, str):  # Error in connection
                return jsonify({"status": "error", "message": conn})

            # Execute the query on the database
            cursor = conn.cursor()
            cursor.execute(sql_query)
            result = cursor.fetchall()

            # Convert results to a readable format
            formatted_results = [list(row) for row in result]

            return jsonify({
                'sql_query': sql_query,
                'results': formatted_results
            })

    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 400

    finally:
        # Safely close connection if initialized
        if conn and isinstance(conn, (pyodbc.Connection, psycopg2.extensions.connection, pymysql.connections.Connection)):
            conn.close()

if __name__ == '__main__':
    app.run(debug=True)
