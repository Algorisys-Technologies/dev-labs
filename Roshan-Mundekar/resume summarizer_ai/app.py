from flask import Flask,render_template,request,session, url_for, redirect ,flash,jsonify
import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)
import pymysql
import logging
from datetime import datetime
from werkzeug.utils import secure_filename
import random
import os, sys
import json

from pypdf import PdfReader 
import json
from resumeparser import ats_extractor
from emailsumery import email_summarizer
from rsu import extract_text_from_pdf,get_openai_answer
sys.path.insert(0, os.path.abspath(os.getcwd()))


app = Flask(__name__)

UPLOAD_FOLDER = 'static/uploads'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER


def dbConnection():
    connection = pymysql.connect(host="localhost", user="root", password="root", database="algoai")
    return connection

def dbClose():
    try:
        dbConnection().close()
    except:
        print("Something went wrong in Close DB Connection")
        
                  
con = dbConnection()
cursor = con.cursor()


@app.route('/')
def index():
    return render_template('main.html') 

@app.route('/index')
def home():
    con = dbConnection()
    cursor = con.cursor()
    cursor.execute('SELECT * FROM addresume')  # Adjust your SQL query as needed
    data = cursor.fetchall()
    cursor.close()
    con.close()

    # Pass the raw data directly to the template
    return render_template('index.html', data=data)


@app.route('/create')
def about():
    return render_template('create.html')

@app.route('/addresume', methods=['POST'])

def addresume():
    print("----------------------------------------")
    if 'files[]' not in request.files:
        return jsonify({"error": "No files found in request"}), 400

    files = request.files.getlist('files[]')
    conn = dbConnection()
    cursor = conn.cursor()
    
    current_date = datetime.now().date()

    try:
        for file in files:
            if file and file.filename.lower().endswith('.pdf'):
                # Secure the filename and replace spaces and dashes with underscores
                filename = secure_filename(file.filename.lower().replace(" ", "_").replace("-", "_"))
                random_number = random.randint(1000, 9999)
                new_filename = f"{os.path.splitext(filename)[0]}_{random_number}.pdf"
                new_filename1 = f"{os.path.splitext(filename)[0]}_{random_number}"
                # Save file to the upload folder
                filepath = os.path.join(app.config['UPLOAD_FOLDER'], new_filename)
                file.save(filepath)

                # Insert file metadata into PostgreSQL
                sql = "INSERT INTO addresume (RESUME_ID, DATE, FILE_PATH) VALUES (%s, %s, %s)"
                cursor.execute(sql, (new_filename1, current_date, filepath))
                conn.commit()

        cursor.close()
        conn.close()
        return jsonify({"message": "Files uploaded successfully"}), 200
    except Exception as e:
        logging.error(f"Error uploading file: {e}")
        conn.rollback()
        cursor.close()
        conn.close()
        return jsonify({"error": "Error uploading file"}), 500

# =============================================================================    
                                    #resume Paraser OpenAi Chatbot
# =============================================================================

# @app.route('/askbot/<int:id>', methods=['GET', 'POST'])
# def askbot(id):
#     try:
#         # Query to get the PDF file path from the database
#         sql_get_pdf = 'SELECT FILE_PATH FROM addresume WHERE ID = %s;'
#         cursor.execute(sql_get_pdf, (id,))
#         result = cursor.fetchone()
        
#         if result:
#             pdf_path = result[0]  # Get the PDF file path from the result
            
#             # Read the PDF file from the path
#             data = _read_file_from_path(pdf_path)
            
#             # Extract the data using ATS extractor (ensure this returns a dictionary)
#             extracted_data = ats_extractor(data)  # Expecting a dict
#             json_string = extracted_data  
           
#             # Convert JSON string to a dictionary
#             json_data = json.loads(json_string)
            
#             # Print the result and its type
#             print(json_data)
#             print(type(json_data))  # This should output: <class 'dict'>
            
            
#             if request.method == 'POST':
#                 search_phrase = request.form.get('question')  # Get the user's question from the form
                
                
#                 search_words = search_phrase.split()  # Split the phrase into words
#                 results = search_in_json(json_data, search_words)

#                 # print(results)
                
                
#                 return render_template('askbot.html', extracted_data=extracted_data, question=search_phrase, answer=results)
           
#             # Render the initial form when the method is GET
#             return render_template('askbot.html', extracted_data=extracted_data)
        
#         else:
#             # If no file path is found for the given ID, handle gracefully
#             return render_template('askbot.html', error="No PDF file found for this record.")
    
#     except Exception as e:
#         # Handle any unexpected errors
#         return render_template('askbot.html', error=f"An error occurred: {str(e)}")

# # Function to search for words in JSON and return related values
# def search_in_json(data, search_words):
#     matches = []

#     if isinstance(data, dict):
#         for key, value in data.items():
#             if any(word.lower() in key.lower() for word in search_words):
#                 if isinstance(value, list):
#                     matches.extend(value)  # Add values from the list directly
#                 else:
#                     matches.append(value)  # Add the value directly if not a list
#             # Recursive search in value
#             matches.extend(search_in_json(value, search_words))
    
#     elif isinstance(data, list):
#         for item in data:
#             matches.extend(search_in_json(item, search_words))
    
#     elif isinstance(data, str):
#         if any(word.lower() in data.lower() for word in search_words):
#             matches.append(data)

#     return matches
# =============================================================================
                                #update code
# =============================================================================

@app.route('/askbot/<int:id>', methods=['GET', 'POST'])
def askbot(id):
    try:
        # Query to get the PDF file path from the database
        sql_get_pdf = 'SELECT FILE_PATH FROM addresume WHERE ID = %s;'
        cursor.execute(sql_get_pdf, (id,))
        result = cursor.fetchone()
        
        if result:
            pdf_path = result[0]  # Get the PDF file path from the result
            extracted_text = extract_text_from_pdf(pdf_path)
            if request.method == 'POST':
                search_phrase = request.form.get('question')
                
                if extracted_text:
                    answer = get_openai_answer(extracted_text, search_phrase)
                    # Print the answer
                    print("Question:", search_phrase)
                    print("Answer:", answer)
                    return render_template('askbot.html', question=search_phrase, answer=answer)

                else:
                    print("Could not extract text from the PDF.")
         
           
            # Render the initial form when the method is GET
            return render_template('askbot.html')
        
        else:
            # If no file path is found for the given ID, handle gracefully
            return render_template('askbot.html', error="No PDF file found for this record.")
    
    except Exception as e:
        # Handle any unexpected errors
        return render_template('askbot.html', error=f"An error occurred: {str(e)}")




# =============================================================================
@app.route('/delete/<int:id>', methods=['DELETE'])
def delete_record(id):
    # Fetch the file path of the PDF from the database
    sql_get_pdf = 'SELECT FILE_PATH FROM addresume WHERE ID = %s;'
    cursor.execute(sql_get_pdf, (id,))
    result = cursor.fetchone()

    if result:
        pdf_path = result[0]  # Assuming the file path is stored in the first column

        # Check if the file exists and remove it
        if os.path.exists(pdf_path):
            try:
                os.remove(pdf_path)  # Delete the PDF file from the filesystem
                print(f"File {pdf_path} has been removed successfully.")
            except Exception as e:
                return jsonify({"message": f"Error deleting file: {e}"}), 500
        else:
            print(f"File {pdf_path} does not exist.")

        # Delete the record from the database
        sql_delete_record = 'DELETE FROM addresume WHERE ID = %s;'
        cursor.execute(sql_delete_record, (id,))
        con.commit()

        return jsonify({"message": "Record and associated file deleted successfully!"}), 200
    else:
        return jsonify({"message": "Record not found."}), 404
# =============================================================================    
                                    #resume Paraser OpenAi
# =============================================================================

def _read_file_from_path(path):
    reader = PdfReader(path) 
    data = ""

    for page_no in range(len(reader.pages)):
        page = reader.pages[page_no] 
        data += page.extract_text()

    return data 

    
@app.route('/view/<int:id>')
def view_record(id):
    try:
        # Query to get the PDF file path from the database
        sql_get_pdf = 'SELECT FILE_PATH FROM addresume WHERE ID = %s;'
        cursor.execute(sql_get_pdf, (id,))
        result = cursor.fetchone()
        
        if result:
            pdf_path = result[0]  # Get the PDF file path from the result
            
            # Read the PDF file from the path
            data = _read_file_from_path(pdf_path)
            
            # Extract the data using ATS extractor (assuming this is a custom function)
            extracted_data = ats_extractor(data)
            data=json.loads(extracted_data)
            print(data)
            # Render the template with extracted data
            return render_template('view_record.html', data=data)
        else:
            # If no file path is found for the given ID, handle gracefully
            return render_template('view_record.html', error="No PDF file found for this record.")
    except Exception as e:
        # Handle any unexpected errors
        return render_template('view_record.html', error=f"An error occurred: {str(e)}")

 # =============================================================================  
   

@app.route('/email')
def email():
    return render_template('email.html')

@app.route('/check', methods=['POST'])
def check():
    email_subject = request.form.get('subject')
    email_content = request.form.get('emaildata') 
    
    # Ensure that both subject and email body are not empty
    if not email_subject or not email_content:
        return jsonify({'summary': 'Subject and email body are required.'}), 400

    print(email_subject)
    print(email_content)
    
    # Assuming email_summarizer is a function you defined elsewhere to summarize the email
    summary_result = email_summarizer(email_content, email_subject)
    print(summary_result)
    return jsonify({'summary': summary_result})



if __name__ == "__main__":
    app.run(debug=True)
    # app.run("0.0.0.0")