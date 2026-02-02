import streamlit as st
import pandas as pd
from main import run_text_to_sql

# ---------------- Page Config ----------------
st.set_page_config(
    page_title="PocketFlow Text-to-SQL",
    page_icon="🧠",
    layout="wide"
)

# ---------------- Professional Styling ----------------
st.markdown("""
<style>
/* Main Title Styling */
.main-title {
    font-size: 34px;
    font-weight: 700;
    color: #E5E7EB;
    margin-bottom: 4px;
}
.sub-title {
    font-size: 16px;
    color: #9CA3AF;
    margin-bottom: 28px;
}

/* Card container */
.agent-card {
    background-color: #020617;
    padding: 20px;
    border-radius: 12px;
    border: 1px solid #1E293B;
}

/* Dark theme override */
html, body, [class*="css"] {
    background-color: #020617 !important;
    color: #E5E7EB !important;
}

/* Hide Streamlit branding */
#MainMenu {visibility: hidden;}
footer {visibility: hidden;}
</style>
""", unsafe_allow_html=True)

# ---------------- Sidebar ----------------
with st.sidebar:
    st.markdown("## ⚙️ PocketFlow Controls")
    st.caption("Database: **classicmodels (MySQL)**")

    st.markdown("---")
    st.markdown("### 🧠 Example Business Questions")

    example_queries = [
        "Top 5 customers by total payments",
        "Which customer generated the highest total revenue from orders?",
        "Customers who ordered from more than 3 product lines",
        "Orders that have not been shipped yet",
        "Customers who placed orders in 2003 but not in 2004"
    ]

    for q in example_queries:
        if st.button(q, use_container_width=True):
            st.session_state.query_input = q

# ---------------- Header ----------------
st.markdown(
    '<div class="main-title">PocketFlow Text-to-SQL</div>',
    unsafe_allow_html=True
)
st.markdown(
    '<div class="sub-title">'
    'Natural Language → SQL analytics engine powered by PocketFlow & LLMs'
    '</div>',
    unsafe_allow_html=True
)

# ---------------- Query Input ----------------
if "query_input" not in st.session_state:
    st.session_state.query_input = ""

query = st.text_input(
    label="",
    value=st.session_state.query_input,
    placeholder="Ask a business question in plain English…"
)

col1, col2, col3 = st.columns([1, 2, 1])
with col2:
    run = st.button("▶ Run Query", use_container_width=True, type="primary")

# ---------------- Execution ----------------
if run:
    if not query:
        st.warning("Please enter a query to proceed.")
    else:
        with st.spinner("🧠 PocketFlow is generating SQL and querying the database..."):
            result = run_text_to_sql(query)

        left_col, right_col = st.columns([1, 2])

        # -------- Agent Reasoning --------
        with left_col:
            st.markdown("### 🧠 Agent Trace")

            with st.expander("User Intent", expanded=True):
                st.info(result.get("intent", "Interpreting user request"))

            with st.expander("Generated SQL", expanded=True):
                sql = result.get("generated_sql")
                if sql:
                    st.code(sql, language="sql")
                else:
                    st.error("SQL generation failed")

        # -------- Result Output --------
        with right_col:
            st.markdown("### 📊 Query Result")

            final_result = result.get("final_result")

            if isinstance(final_result, dict) and "rows" in final_result:
                final_result = pd.DataFrame(
               final_result["rows"],
        columns=final_result["columns"]
            )


                st.markdown('<div class="agent-card">', unsafe_allow_html=True)
                st.dataframe(final_result, use_container_width=True, hide_index=True)
                st.markdown('</div>', unsafe_allow_html=True)

                csv = final_result.to_csv(index=False).encode("utf-8")
                st.download_button(
                    "⬇ Download CSV",
                    data=csv,
                    file_name="query_results.csv",
                    mime="text/csv"
                )
            else:
                st.error(result.get("final_error", "Query execution failed"))

# ---------------- Footer ----------------
st.markdown("---")
st.markdown(
    """
    <div style='display:flex; justify-content:space-between; color:#9CA3AF; font-size:12px;'>
        <div>Status: <span style='color:#22C55E;'>● Operational</span></div>
        <div>Powered by PocketFlow · Text-to-SQL System</div>
    </div>
    """,
    unsafe_allow_html=True
)
