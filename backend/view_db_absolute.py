import sqlite3
import pandas as pd
import os

# Absolute path to the database
DB_PATH = r"d:\dev-labs\Vishakha-Karande\Evolute_Group_Email_Classification\orders.db"

def view_db():
    if not os.path.exists(DB_PATH):
        print(f"Error: {DB_PATH} not found.")
        return
        
    conn = sqlite3.connect(DB_PATH)
    query = "SELECT id, po_number, category, confidence, status, goods_name, quantity FROM 'order' ORDER BY id DESC LIMIT 10"
    df = pd.read_sql_query(query, conn)
    print("\n--- DATABASE AUDIT (LATEST 10 RECORDS) ---")
    print(df.to_string(index=False))
    conn.close()

if __name__ == "__main__":
    view_db()
