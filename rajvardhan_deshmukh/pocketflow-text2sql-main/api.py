from fastapi import FastAPI, Form
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi import Request
from flow import create_text_to_sql_flow
from pydantic import BaseModel
from dotenv import load_dotenv
import os

load_dotenv()



class QueryRequest(BaseModel):
    query: str


# -------------------------------------------------
# FastAPI App
# -------------------------------------------------

app = FastAPI(
    title="PocketFlow Text-to-SQL",
    docs_url="/docs",      # still available, but optional
    redoc_url=None
)
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")


# -------------------------------------------------
# CORS (safe even if frontend grows later)
# -------------------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# -------------------------------------------------
# HOME PAGE (UI)
# -------------------------------------------------

@app.get("/", response_class=HTMLResponse)
def home():
    return """
    <html>
        <head>
            <title>PocketFlow Text-to-SQL</title>
            <link rel="stylesheet" href="/static/style.css">
        </head>
        <body>
            <h2>PocketFlow Text-to-SQL</h2>

            <textarea id="query" placeholder="Enter your natural language query..."></textarea><br>
            <button onclick="runQuery()">Run</button>
            <div id="loader" class="loader hidden"></div>


            <h3>Generated SQL</h3>
            <pre id="sql"></pre>

            <h3>Result</h3>
            <div id="result"></div>

            <script src="/static/app.js"></script>
        </body>
    </html>
    """



# -------------------------------------------------
# QUERY HANDLER
# -------------------------------------------------

@app.post("/query")
def run_query(req: QueryRequest):
    shared = {
        "db_type": "mysql",
        "db_config": {
            "host": os.getenv("DB_HOST", "localhost"),
            "user": os.getenv("DB_USER", "root"),
            "password": os.getenv("DB_PASSWORD", ""),
            "database": os.getenv("DB_NAME", "classicmodels"),
            "auth_plugin": "mysql_native_password",
        },
        "natural_query": req.query,
        "debug_attempts": 0,
        "max_debug_attempts": 3,
        "generated_sql": None,
        "result_columns": None,
        "final_result": None,
        "final_error": None,
    }

    # Run Pocket Flow
    flow = create_text_to_sql_flow()
    flow.run(shared)

    # Normalize DB output
    columns = shared.get("result_columns")
    rows = shared.get("final_result")

    formatted_rows = []
    if columns and rows:
        for row in rows:
            formatted_rows.append(dict(zip(columns, row)))

    return {
        "generated_sql": shared.get("generated_sql"),
        "final_result": {
            "columns": columns,
            "rows": formatted_rows
        },
        "final_error": shared.get("final_error"),
    }
