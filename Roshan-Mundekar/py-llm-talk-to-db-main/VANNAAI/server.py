from flask import Flask, render_template, request, jsonify
from vanna.remote import VannaDefault
from vanna.flask import VannaFlaskApp
import json
import pandas as pd
app = Flask(__name__)

# Vanna API Key and Model Setup
api_key = '6baf015e5504404dbabdc744e58674a0'
vn = VannaDefault(model='test223', api_key=api_key)

# Read DB Configurations from db.json
with open('db.json', 'r') as f:
    db_config = json.load(f)

# Initialize a dictionary to store connections
db_connections = {}

# Updated helper function to connect to the database
def connect_to_db(db_name):
    config = db_config[db_name]
    
    try:
        if config['type'] == 'mysql':
            connection = vn.connect_to_mysql(
                host=config['host'],
                dbname=config['dbname'],
                user=config['user'],
                password=config['password'],
                port=config["port"],
                charset='utf8'
            )
        
        elif config['type'] == 'postgres':
            connection = vn.connect_to_postgres(
                host=config["host"],
                dbname=config["dbname"],
                user=config["user"],
                password=config["password"],
                port=config["port"]
            )
        
        elif config['type'] == 'mssql':
            odbc_conn_str = (
                f"DRIVER={{ODBC Driver 17 for SQL Server}};"
                f"SERVER={config['host']};"
                f"DATABASE={config['dbname']};"
                f"UID={config['user']};"
                f"PWD={config['password']};"
            )
            connection = vn.connect_to_mssql(odbc_conn_str=odbc_conn_str)
        
        else:
            return "Unsupported Database Type"
        
        # Store the connection in db_connections
        db_connections[db_name] = connection
        return connection
    except Exception as e:
        return f"Failed to connect to {config['type']}: {e}"

@app.route('/')
def index():
    # Render the UI with the list of available databases from db.json
    return render_template('index.html', db_config=db_config)

@app.route('/select_database', methods=['POST'])
def select_database():
    db_name = request.json.get('db_name')
    print(db_name)
    connection = connect_to_db(db_name)
    
    if isinstance(connection, str):
        return jsonify({"error": connection}), 400
    
    db_connections[db_name] = connection
    return jsonify({"message": f"Connected to {db_name} successfully!"})

@app.route('/query_db', methods=['POST'])
def query_db():
    db_name = request.json.get('db_name')
    query = request.json.get('query')
    print(query)
    # Ensure the database is connected
    if db_name not in db_connections or not db_connections[db_name]:
        connection = connect_to_db(db_name)
        if isinstance(connection, str):
            return jsonify({"error": connection}), 400

    try:
        # Generate SQL query using Vanna
        sql = vn.generate_sql(question=query)
        result = vn.run_sql(sql=sql)
        print("result")
        # print(result)
        # Convert DataFrame to JSON-serializable format (list of dictionaries)
        if isinstance(result, pd.DataFrame):  # Check if result is a DataFrame
            result = result.to_dict(orient="records")
            
        return jsonify({"result": result})
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
if __name__ == '__main__':
    app.run(debug=True)
