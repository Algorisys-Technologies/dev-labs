# PocketFlow Text-to-SQL 🚀

A **minimalist, production-grade Text-to-SQL system** built using **Pocket Flow**, **FastAPI**, and **MySQL**, demonstrating how complex LLM applications can be constructed using **simple graphs, explicit control flow, and zero dependency bloat**.

This project converts **natural language questions** into **valid SQL queries**, executes them against a MySQL database, and returns structured results via a clean web interface.

---

## ✨ Key Highlights

* 🧠 **LLM-powered Text → SQL generation**
* 🧩 Built on **Pocket Flow** (minimal graph-based framework)
* ⚡ **FastAPI backend** with JSON API
* 🎨 Simple **frontend UI** (served via FastAPI)
* 🗄️ Real **MySQL database integration**
* 🧪 Deterministic, debuggable, and extensible design

---

## 🧠 Why Pocket Flow?

Most LLM frameworks introduce:

* Hidden state
* Complex abstractions
* Dependency bloat
* Hard-to-debug pipelines

**Pocket Flow** proves that **all powerful LLM systems are just graphs**.

This project intentionally uses:

* ~100 lines of orchestration code
* Explicit execution order
* Clear data flow
* Zero vendor lock-in

---

## 🏗️ Architecture Overview

### High-Level Flow

```
User (Browser)
   |
   | Natural Language Query
   v
Frontend UI (HTML + JS)
   |
   | POST /query
   v
FastAPI Backend
   |
   | Shared Store (dict)
   v
Pocket Flow
   |
   | 1. Get DB Schema
   | 2. Generate SQL (LLM)
   | 3. Validate / Retry if needed
   | 4. Execute SQL
   |
   v
MySQL Database
   |
   | Raw Results
   v
Serializer (dates, decimals → JSON-safe)
   |
   v
FastAPI JSON Response
   |
   v
Frontend Table Output
```

---

## 🧩 Pocket Flow Internals (Core Concepts)

### 1️⃣ Node (Worker Unit)

Each Node follows a strict lifecycle:

```
prep() → exec() → post()
```

* **prep**: Reads required data from shared store
* **exec**: Performs isolated computation (LLM call, SQL execution)
* **post**: Writes results back + returns an action string

Built-in:

* Retry logic
* Failure fallback
* Clean isolation

---

### 2️⃣ Shared Store (Central Whiteboard)

* A simple Python `dict`
* Single source of truth
* Makes debugging trivial
* No hidden memory or side effects

Example:

```python
shared = {
  "user_query": "...",
  "schema": "...",
  "generated_sql": "...",
  "final_result": [...]
}
```

---

### 3️⃣ Flow (Graph Orchestrator)

* Controls execution order
* Uses **explicit transitions**
* Supports branching & retries
* A Flow is itself a Node (nestable)

```python
node_a >> node_b -"error" >> retry_node
```

---

## 📂 Project Structure

```
pocketflow-text2sql/
│
├── api.py               # FastAPI app + API endpoints
├── main.py              # CLI entry point (text → SQL)
├── flow.py              # Pocket Flow core (Node, Flow)
├── nodes.py             # Application-specific Nodes
├── app.py               # Streamlit UI
├── utils/
│   └── call_llm.py      # LLM API wrapper (Groq)
├── static/              # Static assets (CSS, JS)
├── templates/           # HTML templates
├── requirements.txt
├── .env.example         # Environment variables template
└── README.md
```

---

## 🚀 Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/pocketflow-text2sql.git
cd pocketflow-text2sql
```

### 2. Create virtual environment

```bash
python -m venv .venv
.venv\Scripts\activate  # Windows
# or: source .venv/bin/activate  # Linux/Mac
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Set up environment variables

```bash
cp .env.example .env
# Edit .env with your credentials:
# - GROQ_API_KEY (get from https://console.groq.com)
# - DB_HOST, DB_USER, DB_PASSWORD, DB_NAME
```

### 5. Run the API server

```bash
uvicorn api:app --reload
```

Visit http://localhost:8000 to use the web interface.

### 6. Or run via CLI

```bash
python main.py "show all customers"
```

### 7. Or use Streamlit UI

```bash
streamlit run app.py
```

---

## ⚙️ How It Works (End-to-End)

1. User enters a natural language question
2. Frontend sends request to `/query`
3. FastAPI initializes shared store
4. Pocket Flow executes nodes:

   * Extract schema
   * Generate SQL using LLM
   * Retry if SQL invalid
   * Execute SQL on MySQL
5. Results are serialized (dates → strings)
6. JSON response returned
7. Frontend renders results in a table

---

## 🧪 Example Query

```bash
python main.py "show all orders where status is shipped"
```

Or via UI:

```
Show all orders placed in 2004 that were not shipped
```

---

## 🛡️ Robustness Features

* Retry on invalid SQL
* Explicit error handling
* Safe JSON serialization
* No silent failures
* Debug-friendly logs

---

## 🧠 Design Philosophy

* **Explicit > Implicit**
* **Simple graphs > magic abstractions**
* **Control > convenience**
* **Debuggability > features**

This project demonstrates that **Compound AI Systems** can be:

* Simple
* Fast
* Maintainable
* Vendor-agnostic

---

## 🚀 Future Improvements

* Pagination for large results
* Query history
* Streaming SQL generation
* Auth + multi-user support
* Async LLM execution

---

## 🧑‍💻 Author

**Rajvardhan Deshmukh**
AI Engineer | ML Engineer | Data Scientist

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⭐ If this helped you

Star ⭐ the repo and fork it — Pocket Flow systems are meant to be extended.
