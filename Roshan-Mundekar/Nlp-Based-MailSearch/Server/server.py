from sqlalchemy import create_engine, text, inspect
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import SQLAlchemyError
import email
from email import policy

class EmailSearch:
    def __init__(self, connection_string, COHERE_API_KEY, thr):
        self.connection_string = connection_string
        self.COHERE_API_KEY = COHERE_API_KEY
        self.thr = thr
        self.engine = None
        self.Session = None
    
    def get_engine(self):
        """
        Initializes the SQLAlchemy engine and session.
        """
        try:
            self.engine = create_engine(self.connection_string)
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

    def drop_table(self, table_name):
        """
        Drops a table using the CASCADE option to remove dependent objects.
        """
        drop_table_query = f"DROP TABLE IF EXISTS {table_name} CASCADE;"
        session = self.Session()
        try:
            session.execute(text(drop_table_query))
            session.commit()
            print(f"Table '{table_name}' dropped successfully.")
        except SQLAlchemyError as e:
            session.rollback()
            print(f"Error occurred while dropping the table '{table_name}': {e}")
        finally:
            session.close()

    def create_table(self, table_name, create_table_query):
        """
        Creates a table based on the provided SQL create table query.
        """
        session = self.Session()
        try:
            session.execute(text(create_table_query))
            session.commit()
            print(f"Table '{table_name}' created successfully.")
        except SQLAlchemyError as e:
            session.rollback()
            print(f"Error occurred while creating the table '{table_name}': {e}")
        finally:
            session.close()

    def define_database(self):
        """
        Defines the database schema by dropping existing tables and creating new ones.
        """
        with self.engine.connect() as connection:
            # Use SQLAlchemy's inspector to check if the table exists
            inspector = inspect(self.engine)
            
            # Drop and recreate 'enron_emaildataset' table
            if 'enron_emaildataset' in inspector.get_table_names():
                self.drop_table('enron_emaildataset')
                
            create_enron_emaildataset = """
                CREATE TABLE enron_emaildataset ( 
                    id SERIAL PRIMARY KEY,                 -- Unique identifier for each row
                    "from" VARCHAR(100),
                    "to" TEXT,
                    date TIMESTAMP,
                    subject TEXT,
                    body_text TEXT,
                    status VARCHAR(50) DEFAULT 'unseen',
                    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    emailid INTEGER,                       -- Allow duplicates in emailid
                    attachments JSONB,
                    UNIQUE(subject, date, "to", "from", body_text)   -- Composite unique constraint on content
                );
            """
            self.create_table('enron_emaildataset', create_enron_emaildataset)
            
            # Drop and recreate 'subject_embedding_data' table
            if 'subject_embedding_data' in inspector.get_table_names():
                self.drop_table('subject_embedding_data')

            create_subject_embedding = """
            CREATE TABLE subject_embedding_data (
                id INTEGER REFERENCES enron_emaildataset(id) ON DELETE CASCADE,
                subject_embeddings_bin BYTEA
            );
            """
            self.create_table('subject_embedding_data', create_subject_embedding)
            
            # Drop and recreate 'body_embedding_data' table
            if 'body_embedding_data' in inspector.get_table_names():
                self.drop_table('body_embedding_data')

            create_body_embedding = """
            CREATE TABLE body_embedding_data (
                id INTEGER REFERENCES enron_emaildataset(id) ON DELETE CASCADE,
                body_embeddings_bin BYTEA
            );
            """
            self.create_table('body_embedding_data', create_body_embedding)
            
            # Drop and recreate 'Account' table
            if 'account' in inspector.get_table_names():
                self.drop_table('account')
            
            create_account_table = """
            CREATE TABLE account (
                id SERIAL PRIMARY KEY,           -- Auto-increment primary key
                email VARCHAR(255) UNIQUE        -- Unique email column
            );
            """
            self.create_table('account', create_account_table)

if __name__ == '__main__':
    connection_string = "postgresql+psycopg2://postgres:root@localhost:5432/emaiapplication1"
    COHERE_API_KEY = '--------------------------------------'  # Replace with your actual Cohere API key
    emailsearch = EmailSearch(connection_string=connection_string, COHERE_API_KEY=COHERE_API_KEY, thr=0.65)
    
    # Initialize the engine and define the database
    emailsearch.get_engine()
    emailsearch.define_database()
