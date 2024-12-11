# import vanna
# from vanna.remote import VannaDefault

# # Set your API key directly as a string
# api_key = '6baf015e5504404dbabdc744e58674a0'

# # Initialize Vanna with the specified model and API key
# vn = VannaDefault(model='chinook', api_key=api_key)

# # Connect to the SQLite database
# vn.connect_to_sqlite('https://vanna.ai/Chinook.sqlite')

# # Query the top 10 albums by sales
# response = vn.ask("What are the top 10 albums by sales?")
# print(response)
##########################################################################################################
##########################################################################################################
# 
# pip install --upgrade vanna[mysql]

# pip install PyMySQL


from vanna.remote import VannaDefault
from vanna.flask import VannaFlaskApp

# Initialize Vanna
vn = VannaDefault(model='test223', api_key='6baf015e5504404dbabdc744e58674a0')

# Connect to MySQL with utf8 fallback
try:
    vn.connect_to_mysql(
        host='localhost',
        dbname='movies',
        user='root',
        password='root',
        port=3306,
        charset='utf8'
    )
    print("Connected to MySQL successfully!")
except Exception as e:
    print(f"Connection failed: {e}")

# Start Flask App
VannaFlaskApp(vn).run()



##########################################################################################################
##########################################################################################################
# from vanna.remote import VannaDefault
# from vanna.flask import VannaFlaskApp
# # pip install vanna[postgres]
# # Initialize Vanna
# api_key = '6baf015e5504404dbabdc744e58674a0'
# vn = VannaDefault(model='test223', api_key=api_key)

# # PostgreSQL database connection configuration
# postgres_config = {
#     "host": "localhost",       # Replace with your PostgreSQL host, e.g., "localhost"
#     "dbname": "ENRON_Emails",  # Replace with your database name
#     "user": "postgres",           # Replace with your PostgreSQL username
#     "password": "admin",       # Replace with your PostgreSQL password
#     "port": 5432               # Replace with your PostgreSQL port (default is 5432)
# }

# # Connect to PostgreSQL database
# try:
#     vn.connect_to_postgres(
#         host=postgres_config["host"],
#         dbname=postgres_config["dbname"],
#         user=postgres_config["user"],
#         password=postgres_config["password"],
#         port=postgres_config["port"]
#     )
#     print("Connected to PostgreSQL successfully!")
# except Exception as e:
#     print(f"Failed to connect to PostgreSQL: {e}")

# # Start Flask App
# try:
#     print("Starting Flask app...")
#     VannaFlaskApp(vn).run()
# except Exception as e:
#     print(f"Failed to start Flask app: {e}")


##########################################################################################################
##########################################################################################################
# Import necessary libraries
# import pyodbc  # Ensure this is installed: pip install pyodbc
# from vanna.flask import VannaFlaskApp
# from vanna.remote import VannaDefault

# # Initialize Vanna
# api_key = '6baf015e5504404dbabdc744e58674a0'
# vn = VannaDefault(model='test223', api_key=api_key)

# # Connection string for MSSQL
# odbc_conn_str = (
#     "DRIVER={ODBC Driver 17 for SQL Server};"
#     "SERVER=DESKTOP-SFJI2T5\\SQLEXPRESS;"  # Replace with your SQL Server hostname or IP address
#     "DATABASE=llmtalktodb;"               # Replace with your database name
#     "UID=sa;"                             # Replace with your username
#     "PWD=sqlpass;"                        # Replace with your password
# )

# # Connect to MSSQL
# try:
#     print("Connecting to MSSQL...")
#     vn.connect_to_mssql(odbc_conn_str=odbc_conn_str)
#     print("Connected to MSSQL successfully!")
# except Exception as e:
#     print(f"Failed to connect to MSSQL: {e}")
#     exit(1)  # Exit the program if the connection fails

# # Start Flask App
# try:
#     print("Starting Flask app...")
#     # Ensure host and port are properly set for accessibility
#     VannaFlaskApp(vn).run(host="0.0.0.0", port=8080)
# except Exception as e:
#     print(f"Failed to start Flask app: {e}")



##########################################################################################################
##########################################################################################################
