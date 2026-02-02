import sys
import os
from dotenv import load_dotenv
from flow import create_text_to_sql_flow

load_dotenv()


def run_text_to_sql(query, max_debug_retries=3):
    shared = {
        "natural_query": query,
        "debug_attempts": 0,
        "max_debug_attempts": max_debug_retries,
        "final_result": None,
        "final_error": None,
        "db_config": {
            "host": os.getenv("DB_HOST", "localhost"),
            "user": os.getenv("DB_USER", "root"),
            "password": os.getenv("DB_PASSWORD", ""),
            "database": os.getenv("DB_NAME", "classicmodels"),
            "auth_plugin": "mysql_native_password"
        }
    }

    flow = create_text_to_sql_flow()
    flow.run(shared)
    
    print(shared.get("generated_sql"))
    print(shared.get("final_result"))

    return {
        "generated_sql": shared.get("generated_sql"),
        "final_result": shared.get("final_result"),
        "final_error": shared.get("final_error"),
    }


if __name__ == "__main__":
    q = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "show all customers"
    print(run_text_to_sql(q))
