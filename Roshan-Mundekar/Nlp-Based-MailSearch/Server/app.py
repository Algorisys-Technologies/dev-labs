from flask import Flask, render_template, request,jsonify
from gmail import EmailSearch

app = Flask(__name__)

# =======================================================================================================


# Initialize EmailSearch instance outside the request scope Cohere's language models can 
#help identify and rank relevant emails based on the query, even when the exact keywords
# are not present in the email content. This could involve tasks like extracting the intent 
#or meaning of the email text and matching it with the search query.


def init_emailsearch():
    connection_string = "postgresql+psycopg2://postgres:root@localhost:5432/emaiapplication1"
    COHERE_API_KEY = '--------------------------------------'  # Replace with your actual Cohere API key
    emailsearch = EmailSearch(connection_string=connection_string, COHERE_API_KEY=COHERE_API_KEY, thr=0.65)
    emailsearch.get_engine()
    # emailsearch.Create_database(csv_file_path='./small_enron.csv')
    return emailsearch

emailsearch = init_emailsearch()

# =======================================================================================================


@app.route('/search', methods=['POST'])
def search():
    data = request.get_json()
    query = data.get('search')
    print("============================")
    print("enter query here")
    print(query)
    print("============================")
    
    if query:
        result_ids = emailsearch.search(query)
        print(result_ids)
        
        if result_ids and len(result_ids):
            result_df = emailsearch.get_mails(result_ids)
            result_df = result_df.drop(columns=['id'])
            # Convert the DataFrame to a dictionary for JSON response
            result_data = result_df.to_dict(orient='records')
            # print(result_data)
            
            # Return the results as JSON
            return jsonify(result_data)
        else:
            return jsonify({"message": "No results found"}), 404
    else:
        return jsonify({"message": "No search query provided"}), 400

    
# =======================================================================================================
                            #upload data
# =======================================================================================================


@app.route('/save_email', methods=['POST'])
def save_email():
    # Your existing code for processing the email
    try:
        # Call Create_database or whatever logic you have
        json_data = request.json
        # print(data)
        emailsearch.create_database(json_data)
        print("heloo done ")
        return jsonify({'status': 'success'}), 200  # Return a success response
    except Exception as e:
        return jsonify({'error': str(e)}), 500  # Return an error response
    
    
    
if __name__ == '__main__':
    # app.run(debug=True)
    app.run("0.0.0.0")
