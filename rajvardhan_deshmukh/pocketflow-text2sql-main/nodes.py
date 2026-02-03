# nodes.py
import time
import re
import yaml
import mysql.connector
from pocketflow import Node
from utils.call_llm import call_llm


# ---------------- HELPER ----------------
def extract_yaml(llm_response: str):
    """
    Extract the first ```yaml ... ``` block from the LLM response.
    Returns the inner YAML text or None.
    """
    match = re.search(r"```yaml\s*([\s\S]*?)```", llm_response)
    if not match:
        return None
    return match.group(1).strip()


# ================= GET SCHEMA =================
class GetSchema(Node):

    def prep(self, shared):
        return shared["db_config"]

    def exec(self, db_config):
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = %s
            """,
            (db_config["database"],)
        )

        tables = cursor.fetchall()
        schema_lines = []

        for (table_name,) in tables:
            schema_lines.append(f"Table: {table_name}")

            cursor.execute(
                """
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_schema = %s AND table_name = %s
                """,
                (db_config["database"], table_name)
            )

            for col, dtype in cursor.fetchall():
                schema_lines.append(f"  - {col} ({dtype})")

            schema_lines.append("")

        conn.close()
        return "\n".join(schema_lines).strip()

    def post(self, shared, prep_res, exec_res):
        shared["schema"] = exec_res
        print("\n===== DB SCHEMA =====\n")
        print(exec_res)
        print("\n=====================\n")


# ================= GENERATE SQL =================
class GenerateSQL(Node):

    def prep(self, shared):
        # return a tuple (natural_query, schema)
        return shared["natural_query"], shared["schema"]

    def exec(self, prep_res):
        natural_query, schema = prep_res

        prompt = f"""
Given the following MySQL database schema:

{schema}

Question: "{natural_query}"

Respond ONLY with YAML:
```yaml
sql: |
  SELECT ...
```"""

        llm_response = call_llm(prompt)
        yaml_str = extract_yaml(llm_response)

        if not yaml_str:
            raise ValueError("LLM did not return valid YAML")

        parsed = yaml.safe_load(yaml_str)
        return parsed["sql"].strip().rstrip(";")

    def post(self, shared, prep_res, exec_res):
        shared["generated_sql"] = exec_res
        shared["debug_attempts"] = 0

        print("\n===== GENERATED SQL =====\n")
        print(exec_res)
        print("\n========================\n")


# ================= EXECUTE SQL =================
class ExecuteSQL(Node):

    def prep(self, shared):
        # return db_config and the SQL string
        return shared["db_config"], shared["generated_sql"]

    def exec(self, prep_res):
        """
        Exec should not touch 'shared'. It returns a tuple:
        (success: bool, payload: rows or error message, columns or None)
        """
        db_config, sql_query = prep_res

        if not sql_query or not isinstance(sql_query, str):
            return False, "No SQL to execute", None

        # Allow only SELECTs (safety)
        if not sql_query.strip().upper().startswith("SELECT"):
            return False, "Only SELECT queries are allowed", None

        try:
            start = time.time()
            conn = mysql.connector.connect(**db_config)
            cursor = conn.cursor()
            cursor.execute(sql_query)

            # read description once
            desc = cursor.description
            columns = [d[0] for d in desc] if desc else []

            rows = cursor.fetchall()
            conn.close()

            print(f"Executed in {time.time() - start:.3f}s")
            return True, rows, columns

        except Exception as e:
            return False, str(e), None

    def post(self, shared, prep_res, exec_res):
        success, result, columns = exec_res

        if success:
            # Persist both columns and rows to shared
            shared["result_columns"] = columns
            # keep rows as list of tuples (normal DB shape)
            shared["final_result"] = result
            shared["final_error"] = None

            # Print a human readable result in the server logs
            print("\n===== SQL RESULT =====")
            print("Columns:", columns)
            for row in (result or []):
                print(row)
            print("=====================\n")

            # return "success" to follow the success path in the flow
            return "success"

        # ERROR PATH: store execution error and decide next action
        shared["execution_error"] = result
        shared["debug_attempts"] = shared.get("debug_attempts", 0) + 1

        if shared["debug_attempts"] >= shared.get("max_debug_attempts", 3):
            # give up and surface final_error, then terminate gracefully
            shared["final_error"] = result
            return "success"  # go to End node

        # signal the flow to go to the debug node
        return "error_retry"


# ================= DEBUG SQL =================
class DebugSQL(Node):

    def prep(self, shared):
        return (
            shared.get("natural_query"),
            shared.get("schema"),
            shared.get("generated_sql"),
            shared.get("execution_error")
        )

    def exec(self, prep_res):
        natural_query, schema, failed_sql, error = prep_res

        prompt = f"""
Broken SQL:
{failed_sql}

Error:
{error}

Schema:
{schema}

Fix it. Respond ONLY with YAML:
```yaml
sql: |
  SELECT ...
```"""

        llm_response = call_llm(prompt)
        yaml_str = extract_yaml(llm_response)

        if not yaml_str:
            raise ValueError("LLM did not return YAML")

        parsed = yaml.safe_load(yaml_str)
        return parsed["sql"].strip().rstrip(";")

    def post(self, shared, prep_res, exec_res):
        # Update the SQL and clear previous execution error so the next ExecuteSQL run will attempt again
        shared["generated_sql"] = exec_res
        shared.pop("execution_error", None)

        print("\n===== FIXED SQL =====\n")
        print(exec_res)
        print("\n====================\n")
# ================= END NODE =================
class End(Node):
    def prep(self, shared):
        return None

    def exec(self, prep_res):
        return None

    def post(self, shared, prep_res, exec_res):
        return None

