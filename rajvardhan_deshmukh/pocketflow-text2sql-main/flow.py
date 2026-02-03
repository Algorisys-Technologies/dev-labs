from pocketflow import Flow
from nodes import GetSchema, GenerateSQL, ExecuteSQL, DebugSQL, End


def create_text_to_sql_flow():
    get_schema = GetSchema()
    gen_sql = GenerateSQL()
    exec_sql = ExecuteSQL()
    debug_sql = DebugSQL()
    end = End()

    get_schema >> gen_sql >> exec_sql

    exec_sql - "error_retry" >> debug_sql
    exec_sql - "success" >> end

    debug_sql >> exec_sql

    return Flow(start=get_schema)
