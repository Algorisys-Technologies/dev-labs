from langchain.chat_models import ChatOpenAI  # Use the correct class for chat models
from langchain.prompts import PromptTemplate
from langchain.chains import LLMChain
import pyodbc
import environ

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

# Connect to the database
server = 'DESKTOP-SFJI2T5\SQLEXPRESS'
database = 'llmtalktodb'
username = 'sa'
password = 'sqlpass'

connection_string = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}'

# Create a connection object
cnxn = pyodbc.connect(connection_string)

# Create a cursor object
cursor = cnxn.cursor()

def execute_query(query):
    try:
        # Execute the query
        cursor.execute(query)

        # Fetch the results
        results = cursor.fetchall()

        # Print the results
        for row in results:
            print(row)

    except Exception as e:
        print(f'Error: {e}')

def main():
    while True:
        # Get the user's input
        input_text = input('Enter a question: ')

        # Generate the SQL query using the LLM chain
        sql_query = llm_chain.run(input_text)

        # Print the SQL query
        print(f'SQL Query: {sql_query}')

        # Optionally execute the query (commented out for safety)
        execute_query(sql_query)

if __name__ == '__main__':
    main()


