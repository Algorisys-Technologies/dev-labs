from flask import Flask, render_template, request, jsonify
from langchain.chat_models import ChatOpenAI
from langchain.prompts import PromptTemplate
from langchain.chains import LLMChain
import pyodbc
import environ

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

# Set up the LLM chain
llm_chain = LLMChain(llm=openai_model, prompt=sql_prompt_template)

# Database connection
server = 'DESKTOP-SFJI2T5\SQLEXPRESS'
database = 'llmtalktodb'
username = 'sa'
password = 'sqlpass'

connection_string = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}'
cnxn = pyodbc.connect(connection_string)
cursor = cnxn.cursor()

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/query', methods=['POST'])
def query_db():
    user_query = request.json.get('query', '')
    print(user_query)
    try:
        # Generate SQL query using LLM chain
        sql_query = llm_chain.run(user_query)
        print(sql_query)
        # Execute the query
        cursor.execute(sql_query)
        results = cursor.fetchall()

        # Convert results to a readable format
        formatted_results = [list(row) for row in results]
        
        return jsonify({
            'sql_query': sql_query,
            'results': formatted_results
        })
    except Exception as e:
        return jsonify({
            'error': str(e)
        }), 400

if __name__ == '__main__':
    app.run(debug=True)
