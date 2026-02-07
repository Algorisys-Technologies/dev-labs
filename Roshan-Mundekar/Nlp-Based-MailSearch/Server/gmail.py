# email_search.py
import os
import pickle
import pandas as pd
import numpy as np
import email
from email import policy
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy import inspect
from transformers import BertTokenizer, BertModel
from sklearn.metrics.pairwise import cosine_similarity
import nltk
from nltk.corpus import stopwords
from nltk.stem import WordNetLemmatizer
from nltk.tokenize import word_tokenize
from langchain_community.llms import Cohere
import torch
from datetime import datetime
from sklearn.decomposition import PCA
from nlp_date_parser import nlp_date_parser
# Download necessary NLTK data
nltk.download('punkt')
nltk.download('stopwords')
nltk.download('wordnet')


class EmailSearch:
    def __init__(self, connection_string, COHERE_API_KEY, thr=0.65, D='auto'):
        self.connection_string = connection_string
        self.thr = thr
        self.D = thr - 1 if D == 'auto' else D
        self.tokenizer = BertTokenizer.from_pretrained('bert-base-uncased', cache_dir='./')
        self.model = BertModel.from_pretrained('bert-base-uncased', cache_dir='./')
        os.environ["COHERE_API_KEY"] = COHERE_API_KEY
        self.llm = Cohere(temperature=0)  # Initialize Cohere LLM
        self.stop_words = set(stopwords.words('english'))
        self.lemmatizer = WordNetLemmatizer()
        self.query_template = """
        SELECT id 
        FROM enron_emaildataset
        WHERE (:from_email IS NULL OR "from" ILIKE '%' || :from_email || '%')
          AND (:to_email IS NULL OR "to" ILIKE '%' || :to_email || '%')
          AND (:start_date IS NULL OR date >= :start_date)
          AND (:end_date IS NULL OR date <= :end_date)
        """
    
        self.cache = None
        self.date_parser = nlp_date_parser()  # Ensure this is properly defined

        # Initialize SQLAlchemy engine and session
        self.engine = None
        self.Session = None
        self.get_engine()

    def get_engine(self):
        """
        Initializes the SQLAlchemy engine and session.
        """
        try:
            self.engine = create_engine('postgresql+psycopg2://postgres:root@localhost/emaiapplication1')
            self.Session = sessionmaker(bind=self.engine)

            # Test the connection
            with self.engine.connect() as conn:
                conn.execute(text("SELECT 1"))
                print("PostgreSQL connection successful!")

        except Exception as e:
            print(f"PostgreSQL connection failed: {e}")
            raise e

    def parse_email_message(self, message):
        """
        Parses an email message and extracts relevant fields.
        """
        msg = email.message_from_string(message, policy=policy.default)
        email_data = {
            'from': msg.get('X-From'),
            'to': msg.get('X-To'),
            'date': msg.get('Date'),
            'subject': msg.get('Subject'),
            'bodyText': msg.get_payload(decode=True).decode('utf-8', errors='ignore') if msg.is_multipart() else msg.get_payload()
        }
        return email_data


    def get_bert_embeddings(self, tokens_list):
        """
        Generates BERT embeddings for a list of tokenized inputs.
        """
        tokens_tensor = torch.tensor(tokens_list)
        with torch.no_grad():
            outputs = self.model(tokens_tensor)
            embeddings = outputs.last_hidden_state
        return embeddings

    def process_text(self, text):
        """
        Processes text by tokenizing, removing stopwords, and lemmatizing.
        """
        # Tokenization
        tokens = word_tokenize(text)

        # Stopword removal
        tokens = [word for word in tokens if word.lower() not in self.stop_words]

        # Lemmatization
        tokens = [self.lemmatizer.lemmatize(word) for word in tokens]

        return tokens

    def get_query_embeddings(self, query):
        """
        Generates BERT embeddings for the query.
        """
        query = query.lower()
        query_tokens = self.tokenizer.encode(query, add_special_tokens=True, max_length=512, truncation=True)
        query_embedding = self.get_bert_embeddings([query_tokens])[0]
        return query_embedding

    def convert_natural_language_to_mail_search(self, query):
        """
        Converts a natural language query into structured mail search parameters using Cohere LLM.
        """
        prompt = f"""
        Convert the following natural language query to a mail search query format.

        Query: "{query}"

        Format:
        From : <Sender's name>
        To : <Recipient's name>
        Date : <Date or date range>
        Subject : <Subject of the email>

        If any information is not present in the query, return None for that field.

        Example:
        Query: "Find emails from John to Jane and Bill W. last week about the project update"
        Output:
        From : John
        To : [Jane, Bill W.]
        Date : last week
        Subject : project update

        Example:
        Query: "Show me the emails sent by Alice regarding the budget report"
        Output:
        From : Alice
        To : None
        Date : None
        Subject : budget report

        Example:
        Query: "mail received in may 2001"
        Output:
        From : None
        To : None
        Date : may 2001
        Subject : None

        Example:
        Query: "Show me the emails sent by Alice on 5 May 2002 regarding the budget report"
        Output:
        From : Alice
        To : None
        Date : 5 May 2002
        Subject : budget report

        Query: "{query}"
        Output:
        """

        # Use the language model to generate the output
        output = self.llm(prompt)
        print("========================= prompt ==================================")
        print(output)

        # Parse the output into the required format
        lines = output.strip().split('\n')
        result = {}
        for line in lines:
            if ': ' in line:
                key, value = line.split(': ', 1)
                result[key.strip()] = value.strip() if value.strip() else None

        return result

  
    
    def Get_score(self, token_wise_score,thr=0.65, D='auto'):
        # Ensure token_wise_score is a numpy array
        token_wise_score = np.asarray(token_wise_score)
        
        # Check if the array is 1D or scalar and reshape if necessary
        if token_wise_score.ndim == 0:
            token_wise_score = np.array([token_wise_score])
        
        # Apply the desired transformation to the scores
        token_wise_score[token_wise_score == 0] = -D
        
        # Example scoring logic; adjust as needed
        # Here you might want to return a score based on some logic involving `thr`
        return np.mean(token_wise_score)
    
    

    def final_score(self, token_wise_score):
        """
        Computes the final aggregated score.
        """
        self.cache[self.cache == 0] = 1
        score = token_wise_score / self.cache
        return np.sum(score)

#########################################################################################################   
    
    def create_database(self, json_data):
        """
        Creates the database by defining the schema, inserting data, and generating embeddings from JSON data.
        """
        # self.define_database()
        # Assuming json_data is a list of email JSON objects
        df = pd.json_normalize(json_data)
        print("===============================")
        print(df)
        print("===============================")
        
        # Prepare the result DataFrame
        result_df = df.copy()
        result_df['date'] = pd.to_datetime(result_df['date']).dt.tz_localize(None)  # Ensure date format consistency
        
        # Remove unnecessary columns if they exist
        if 'attachments' in result_df.columns:
            result_df = result_df.drop(columns=['attachments'])
        
        # Rename column for consistency with the table schema
        result_df.rename(columns={"bodyText": "body_text"}, inplace=True)
        
        # Ensure data is inserted into the table before retrieving the `id`s
        try:
            # Insert the main DataFrame into the enron_emaildataset table
            result_df.to_sql('enron_emaildataset', con=self.engine, if_exists='append', index=False)
            print("enron_emaildataset inserted successfully.")
        except Exception as e:
            print(f"An error occurred while inserting into enron_emaildataset: {e}")
            return self
        
        # Now retrieve ids from enron_emaildataset in the order they were inserted
        try:
            # Match rows based on unique identifiers like subject, date, from, and to
            query = """
            SELECT id, subject, date, "from", "to", body_text
            FROM enron_emaildataset
            ORDER BY id;
            """
            ids = pd.read_sql(query, con=self.engine)
            
            # Print the retrieved IDs for debugging
            print("======================")
            print(ids)
            print("======================")
            
            # Merge result_df with the retrieved ids based on common columns
            result_df = result_df.merge(ids, on=['subject', 'date', 'from', 'to', 'body_text'], how='left')
            
            # Check for rows that couldn't be matched
            unmatched_rows = result_df[result_df['id'].isnull()]
            if not unmatched_rows.empty:
                print(f"Unmatched rows: {unmatched_rows}")
            
            print(f"Matched {len(result_df) - len(unmatched_rows)} rows successfully.")
            print(f"Total rows in result_df: {len(result_df)}")
            
        except Exception as e:
            print(f"An error occurred while retrieving email IDs: {e}")
            return self
        
        
        # Tokenization and embedding
        result_df['subject_tokens'] = result_df['subject'].apply(
            lambda x: self.tokenizer.encode(x, add_special_tokens=True, max_length=512, truncation=True)
        )
        result_df['body_tokens'] = result_df['body_text'].apply(
            lambda x: self.tokenizer.encode(x, add_special_tokens=True, max_length=512, truncation=True)
        )
        
        # Get embeddings
        result_df['subject_embeddings'] = result_df['subject_tokens'].apply(lambda x: self.get_bert_embeddings([x])[0])
        result_df['body_embeddings'] = result_df['body_tokens'].apply(lambda x: self.get_bert_embeddings([x])[0])
        
        # Convert embeddings to binary format for database storage
        result_df['subject_embeddings_bin'] = result_df['subject_embeddings'].apply(lambda x: pickle.dumps(x.tolist()))
        result_df['body_embeddings_bin'] = result_df['body_embeddings'].apply(lambda x: pickle.dumps(x.tolist()))
        
        # Prepare DataFrames for subject and body embeddings
        subject_df = result_df[['id', 'subject_embeddings_bin']].copy()
        body_df = result_df[['id', 'body_embeddings_bin']].copy()
        
        # Insert subject embeddings (for all rows)
        try:
            subject_df.to_sql('subject_embedding_data', con=self.engine, if_exists='append', index=False)
            print(f"Inserted {len(subject_df)} subject embeddings successfully.")
        except Exception as e:
            print(f"An error occurred while inserting subject embeddings: {e}")
            
        # Insert body embeddings (for all rows)
        try:
            body_df.to_sql('body_embedding_data', con=self.engine, if_exists='append', index=False)
            print(f"Inserted {len(body_df)} body embeddings successfully.")
        except Exception as e:
            print(f"An error occurred while inserting body embeddings: {e}")
        
        return self



#########################################################################################################   


    

   

    def search(self, query):
        mail_search_query = self.convert_natural_language_to_mail_search(query)
        
        

        for key in ['From', 'To', 'Date', 'Subject']:
            if key not in mail_search_query.keys():
                mail_search_query[key] = None

        date = {'start_date': None, 'end_date': None}
        if mail_search_query['Date']:
            date = self.date_parser(mail_search_query['Date'])
            # print("=================================")
            # print(date)
            # print("=================================")
            if date is None:
                date = {'start_date': None, 'end_date': None}

        params = {
            'from_email': mail_search_query['From'],
            'to_email': mail_search_query['To'],
            'start_date': date['start_date'],
            'end_date': date['end_date']
        }

        # Adjust params to None where needed
        for key in params:
            if params[key] == 'None' or params[key] is None:
                params[key] = None

        query_template = """
            SELECT id 
            FROM enron_emaildataset
            WHERE (:from_email IS NULL OR "from" ILIKE '%' || :from_email || '%')
              AND (:to_email IS NULL OR "to" ILIKE '%' || :to_email || '%')
              AND (:start_date IS NULL OR date >= :start_date)
              AND (:end_date IS NULL OR date <= :end_date)
        """


        with self.engine.connect() as conn:
            result = conn.execute(text(query_template), params)
            emails_info = result.fetchall()

        
        emails_info = tuple(id[0] for id in emails_info)
        # print(emails_info)
        if not emails_info:
            return tuple()  # No matching emails
        
        # Fetch embeddings
        if len(emails_info) == 1:
            # Use a single email ID without tuple for the query
            body_query = f"SELECT id , body_embeddings_bin FROM body_embedding_data WHERE id  = {emails_info[0]}"
            subject_query = f"SELECT id, subject_embeddings_bin FROM subject_embedding_data WHERE id = {emails_info[0]}"
        else:
            # Use the tuple for multiple email IDs
            body_query = f"SELECT id , body_embeddings_bin FROM body_embedding_data WHERE id  IN {emails_info}"
            subject_query = f"SELECT id , subject_embeddings_bin FROM subject_embedding_data WHERE id  IN {emails_info}"
        
        query_dfb = pd.read_sql(body_query, self.engine)
        query_dfs = pd.read_sql(subject_query, self.engine)
        
        # Merge the embeddings
        query_df = pd.merge(query_dfs, query_dfb, on='id')

        # Deserialize embeddings
        query_df['subject_embeddings_bin'] = query_df['subject_embeddings_bin'].apply(lambda x: pickle.loads(x))
        query_df['body_embeddings_bin'] = query_df['body_embeddings_bin'].apply(lambda x: pickle.loads(x))
           
        # print("========================================================================")

        # Process the subject query
        Subject_query = mail_search_query['Subject']
        processed_tokens = self.process_text(Subject_query)
        processed_query = ' '.join(processed_tokens)
        query_embedding = self.get_query_embeddings(processed_query)

        # Compute cosine similarity for subjects
        query_df['subject_similarity'] = query_df['subject_embeddings_bin'].apply(
            lambda x: np.dot(np.array(x), query_embedding.T) / (np.linalg.norm(np.array(x)) * np.linalg.norm(query_embedding))
        )

        # Compute cosine similarity for bodies
        query_df['body_similarity'] = query_df['body_embeddings_bin'].apply(
            lambda x: np.dot(np.array(x), query_embedding.T) / (np.linalg.norm(np.array(x)) * np.linalg.norm(query_embedding))
        )

        # Initialize cache
        self.cache = np.zeros(len(query_embedding))

        # Compute scores
        query_df['subject_similarity_score'] = query_df['subject_similarity'].apply(
            lambda x: self.Get_score(np.array([x]), self.thr, self.D)
        )
        
        print("Subject Similarity Scores:")
        print(query_df[['id', 'subject_similarity_score']])


        query_df['body_similarity_score'] = query_df['body_similarity'].apply(
            lambda x: self.Get_score(np.array([x]), self.thr, self.D)
        )
        
        print("Body Similarity Scores:")
        print(query_df[['id', 'body_similarity_score']])

        # Aggregate scores
        query_df['score'] = query_df['subject_similarity_score'] + query_df['body_similarity_score']
        
        # Print the aggregated scores
        print("Aggregated Scores:")
        print(query_df[['id', 'score']])



        query_df = query_df.sort_values(by='score', ascending=False)

        return tuple(query_df['id'].to_list())


       

    def get_mail(self, email_id):
        """
        Retrieves a single email by its ID.
        """
        query = f"""
        SELECT id, "from", "to", date, subject, body_text 
        FROM enron_emaildataset 
        WHERE id IN ({email_id})
        """
        df = pd.read_sql(query, self.engine)
        return df

    
    def get_mails(self, email_ids):
        """
        Retrieves multiple emails by their IDs from the enron_emaildataset.
        """
        if isinstance(email_ids, int):
            return self.get_mail(email_ids)
        else:
            # Ensure email_ids is a tuple for the SQL query
            if isinstance(email_ids, tuple):
                email_ids_str = ", ".join(map(str, email_ids))
            else:
                email_ids_str = str(email_ids)

            # Updated query with the correct column names based on your table schema
            query = f"""
            SELECT id, "from", "to", date, subject, body_text 
            FROM enron_emaildataset 
            WHERE id IN ({email_ids_str})
            """
            # Reading the data into a pandas dataframe
            df = pd.read_sql(query, self.engine)
            
            # Set emailid as index and reorder by the provided email_ids
            df = df.set_index('id')
            df = df.reindex(email_ids).reset_index()
            return df

