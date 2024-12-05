
# SQL Query Generator with OpenAI and Flask

This Flask application allows users to input natural language queries, which are then converted into SQL queries using OpenAI's GPT-based LLM. The generated SQL queries are executed on a Microsoft SQL Server database, and the results are displayed in a web interface.

## Features

- Convert natural language questions into SQL queries using GPT-3.5-turbo.
- Execute SQL queries on a connected Microsoft SQL Server database.
- Display query results in a user-friendly, responsive format.

## Prerequisites

- Python 3.9 or higher
- Microsoft SQL Server
- [ODBC Driver 17 for SQL Server](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server)

- Required Python libraries (listed in requirements.txt)

## Installation Guide



### Step 1: Clone the Repository
```bash
git clone https://github.com/Algorisys-Technologies/dev-labs/tree/main/Roshan-Mundekar/py-llm-talk-to-db-main/LLMDB
cd py-llm-talk-to-db-main/LLMDB



### Step 2: Install Dependencies
```bash
pip install -r requirements.txt


### Step 3: Set Up Environment Variables

#OPENAI_API_KEY=your_openai_api_key


### Step 4: Configure the Database Connection
server = 'your_sql_server_address'
database = 'your_database_name'
username = 'your_database_username'
password = 'your_database_password'

## Running the Application

### Step 1: Start the Flask Application
```bash
python app.py

Step 2: Open in Browser
Navigate to http://127.0.0.1:5000 in your web browser.

## Results

![Alt text](https://github.com/Algorisys-Technologies/dev-labs/blob/main/Roshan-Mundekar/py-llm-talk-to-db-main/LLMDB/demo.JPG)