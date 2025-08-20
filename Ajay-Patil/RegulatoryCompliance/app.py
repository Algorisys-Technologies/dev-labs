import streamlit as st
import yaml
import json
import os
from datetime import datetime
from src.agents.ingestion_agent import IngestionAgent
from src.agents.search_agents import run_regulatory_search
from src.agents.writing_agent import WritingAgent
from exception.custom_exception import CustomException
from logger.custom_logger import CustomLogger
import tempfile
import io
import PyPDF2

# Initialize logger
logger = CustomLogger().get_logger(__name__)

# CTD Sections Structure
CTD_SECTIONS = {
    "MODULE 2: QUALITY OVERALL SUMMARY (QOS)": {
        "2.3.S DRUG SUBSTANCE": {
            "2.3.S.1 General Information": {},
            "2.3.S.2 Manufacture": {},
            "2.3.S.3 Characterisation": {},
            "2.3.S.4 Control of Drug Substance": {},
            "2.3.S.5 Reference Standards or Materials": {},
            "2.3.S.6 Container Closure System": {},
            "2.3.S.7 Stability": {}
        },
        "2.3.P DRUG PRODUCT": {
            "2.3.P.1 Description and Composition": {},
            "2.3.P.2 Pharmaceutical Development": {},
            "2.3.P.3 Manufacture": {},
            "2.3.P.4 Control of Excipients": {},
            "2.3.P.5 Control of Drug Product": {},
            "2.3.P.6 Reference Standards or Materials": {},
            "2.3.P.7 Container Closure System": {},
            "2.3.P.8 Stability": {}
        },
        "2.3.A APPENDICES": {
            "2.3.A.1 Facilities and Equipment": {},
            "2.3.A.2 Adventitious Agents Safety Evaluation": {},
            "2.3.A.3 Excipients": {}
        },
        "2.3.R REGIONAL INFORMATION": {}
    },
    "MODULE 3: QUALITY": {
        "3.2.S DRUG SUBSTANCE": {
            "3.2.S.1 General Information": {
                "3.2.S.1.1 Nomenclature": {},
                "3.2.S.1.2 Structure": {},
                "3.2.S.1.3 General Properties": {}
            },
            "3.2.S.2 Manufacture": {
                "3.2.S.2.1 Manufacturer(s)": {},
                "3.2.S.2.2 Description of Manufacturing Process": {},
                "3.2.S.2.3 Control of Materials": {},
                "3.2.S.2.4 Controls of Critical Steps": {},
                "3.2.S.2.5 Process Validation": {},
                "3.2.S.2.6 Manufacturing Process Development": {}
            },
            "3.2.S.3 Characterisation": {
                "3.2.S.3.1 Elucidation of Structure": {},
                "3.2.S.3.2 Impurities": {}
            },
            "3.2.S.4 Control of Drug Substance": {
                "3.2.S.4.1 Specification": {},
                "3.2.S.4.2 Analytical Procedures": {},
                "3.2.S.4.3 Validation of Analytical Procedures": {},
                "3.2.S.4.4 Batch Analyses": {},
                "3.2.S.4.5 Justification of Specification": {}
            },
            "3.2.S.5 Reference Standards or Materials": {},
            "3.2.S.6 Container Closure System": {},
            "3.2.S.7 Stability": {
                "3.2.S.7.1 Stability Summary": {},
                "3.2.S.7.2 Post-approval Stability Protocol": {},
                "3.2.S.7.3 Stability Data": {}
            }
        },
        "3.2.P DRUG PRODUCT": {
            "3.2.P.1 Description and Composition": {},
            "3.2.P.2 Pharmaceutical Development": {
                "3.2.P.2.1 Components": {
                    "3.2.P.2.1.1 Drug Substance": {},
                    "3.2.P.2.1.2 Excipients": {}
                },
                "3.2.P.2.2 Drug Product": {
                    "3.2.P.2.2.1 Formulation Development": {},
                    "3.2.P.2.2.2 Overages": {},
                    "3.2.P.2.2.3 Physicochemical Properties": {}
                },
                "3.2.P.2.3 Manufacturing Process Development": {},
                "3.2.P.2.4 Container Closure System": {},
                "3.2.P.2.5 Microbiological Attributes": {},
                "3.2.P.2.6 Compatibility": {}
            },
            "3.2.P.3 Manufacture": {
                "3.2.P.3.1 Manufacturer(s)": {},
                "3.2.P.3.2 Batch Formula": {},
                "3.2.P.3.3 Description of Manufacturing Process": {},
                "3.2.P.3.4 Controls of Critical Steps": {},
                "3.2.P.3.5 Process Validation": {}
            },
            "3.2.P.4 Control of Excipients": {
                "3.2.P.4.1 Specifications": {},
                "3.2.P.4.2 Analytical Procedures": {},
                "3.2.P.4.3 Validation of Analytical Procedures": {},
                "3.2.P.4.4 Justification of Specifications": {},
                "3.2.P.4.5 Excipients of Human or Animal Origin": {},
                "3.2.P.4.6 Novel Excipients": {}
            },
            "3.2.P.5 Control of Drug Product": {
                "3.2.P.5.1 Specification(s)": {},
                "3.2.P.5.2 Analytical Procedures": {},
                "3.2.P.5.3 Validation of Analytical Procedures": {},
                "3.2.P.5.4 Batch Analyses": {},
                "3.2.P.5.5 Characterisation of Impurities": {},
                "3.2.P.5.6 Justification of Specification(s)": {}
            },
            "3.2.P.6 Reference Standards or Materials": {},
            "3.2.P.7 Container Closure System": {},
            "3.2.P.8 Stability": {
                "3.2.P.8.1 Stability Summary": {},
                "3.2.P.8.2 Post-approval Stability Protocol": {},
                "3.2.P.8.3 Stability Data": {}
            }
        },
        "3.2.A APPENDICES": {
            "3.2.A.1 Facilities and Equipment": {},
            "3.2.A.2 Adventitious Agents Safety Evaluation": {},
            "3.2.A.3 Excipients": {}
        },
        "3.2.R REGIONAL INFORMATION": {},
        "3.3 LITERATURE REFERENCES": {}
    }
}


# ----------------------
# Helpers for session-stable state
# ----------------------

def _ensure_session_defaults():
    if 'pipeline' not in st.session_state:
        st.session_state.pipeline = {
            'config': None,
            'region': None,
            'molecule': None,
            'extracted_texts': {
                'process_description': '',
                'specification': '',
                'stability_report': ''
            },
            'extraction_last_run': None,
            'ingestion_output': None,
            'ingestion_last_run': None,
            'search_results': None,
            'vectordb_path': None,
            'search_last_run': None,
            'selected_section': None,
            'writing_results': {},
        }


def main():
    st.set_page_config(
        page_title="Regulatory Compliance Document Generator",
        page_icon="📊",
        layout="wide",
        initial_sidebar_state="expanded"
    )

    _ensure_session_defaults()

    st.title("📊 Regulatory Compliance Document Generator")
    st.markdown("Automated CTD Module 2 & 3 Generation for Pharmaceutical Submissions")
    st.markdown("---")

    # Load configuration ONCE per session unless explicitly reloaded
    if st.session_state.pipeline['config'] is None:
        try:
            with open("./config/config.yaml", "r") as f:
                config = yaml.safe_load(f)
            st.session_state.pipeline['config'] = config
        except Exception as e:
            st.error(f"Failed to load configuration: {e}")
            return

    # Sidebar
    with st.sidebar:
        st.header("🔧 Configuration")

        regions = ["India", "USA", "EU", "UK", "Japan", "China", "Brazil"]
        molecule_options = ["Paracetamol", "Ibuprofen", "Aspirin", "Metformin", "Amoxicillin", "Other"]

        region = st.selectbox("Region", regions, index=(regions.index(st.session_state.pipeline['region']) if st.session_state.pipeline['region'] in regions else 0))
        molecule_type = st.selectbox("Molecule", molecule_options, index=(molecule_options.index(st.session_state.pipeline['molecule']) if st.session_state.pipeline['molecule'] in molecule_options else 0))

        if molecule_type == "Other":
            molecule = st.text_input("Custom Molecule Name", value=(st.session_state.pipeline['molecule'] if st.session_state.pipeline['molecule'] not in molecule_options and st.session_state.pipeline['molecule'] else ""))
        else:
            molecule = molecule_type

        # Persist choices in session
        st.session_state.pipeline['region'] = region
        st.session_state.pipeline['molecule'] = molecule

        st.markdown("---")
        st.header("📄 Document Upload")

        process_file = st.file_uploader("Process Description PDF", type="pdf")
        spec_file = st.file_uploader("Specification PDF", type="pdf")
        stability_file = st.file_uploader("Stability Report PDF", type="pdf")

        colu1, colu2 = st.columns(2)
        with colu1:
            upload_btn = st.button("📝 Extract Text", disabled=not all([process_file, spec_file, stability_file]))
        with colu2:
            reset_extraction = st.button("♻️ Reset Extraction")

        if reset_extraction:
            st.session_state.pipeline['extracted_texts'] = {
                'process_description': '',
                'specification': '',
                'stability_report': ''
            }
            st.session_state.pipeline['extraction_last_run'] = None

        if upload_btn:
            with st.spinner("Extracting text from PDFs..."):
                try:
                    st.session_state.pipeline['extracted_texts'] = extract_text_from_pdfs(
                        process_file, spec_file, stability_file
                    )
                    st.session_state.pipeline['extraction_last_run'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                    st.success("Text extraction completed!")
                except Exception as e:
                    st.error(f"Extraction failed: {e}")

    # Main content - Two columns layout
    col1, col2 = st.columns([1, 2])

    with col1:
        st.header("📋 CTD Sections")

        # Persist selection across reruns
        clicked = navigate_ctd_sections(CTD_SECTIONS)
        if clicked:
            st.session_state.pipeline['selected_section'] = clicked

        sel_path = st.session_state.pipeline.get('selected_section')
        if sel_path:
            st.info(f"Selected: {sel_path}")

        ready_for_writing = (
            st.session_state.pipeline['ingestion_output'] is not None and
            st.session_state.pipeline['vectordb_path'] is not None and
            sel_path is not None
        )

        # Button should rely on persisted selection so clicks survive reruns
        if st.button("🖊️ Generate Section Content", type="primary", disabled=not ready_for_writing, key="btn_generate_section"):
            with st.spinner(f"Generating content for {sel_path}..."):
                try:
                    writing_agent = WritingAgent(st.session_state.pipeline['config']["llm"])  # expects key "llm"
                    result = writing_agent.generate_section_content(
                        molecule=st.session_state.pipeline['molecule'],
                        region=st.session_state.pipeline['region'],
                        context=st.session_state.pipeline['ingestion_output'],
                        vectorstore_path=st.session_state.pipeline['vectordb_path'],
                        section_name=sel_path
                    )
                    st.success(f"Content generated for {sel_path}!")
                except Exception as e:
                    result = {
                        "status": "error",
                        "section_name": sel_path,
                        "error": str(e),
                        "generated_content": f"Error generating content: {e}",
                        "citations": []
                    }
                    st.error(f"Content generation failed: {e}")
                finally:
                    # Persist result regardless so Writing tab can show either content or the error
                    result = result or {}
                    result['molecule'] = st.session_state.pipeline['molecule']
                    result['region'] = st.session_state.pipeline['region']
                    result['section_name'] = sel_path
                    result['generated_at'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                    st.session_state.pipeline['writing_results'][sel_path] = result

    with col2:
        st.header("🔍 Analysis Pipeline")

        tab1, tab2, tab3, tab4 = st.tabs(["📝 Extraction", "🧠 Ingestion", "🔍 Search", "📄 Writing"]) 

        with tab1:
            display_extraction_results()

        with tab2:
            colA, colB = st.columns([1,1])
            with colA:
                run_ingestion = st.button("🧠 Run Ingestion", disabled=not any(st.session_state.pipeline['extracted_texts'].values()))
            with colB:
                reset_ingestion = st.button("♻️ Reset Ingestion")

            if reset_ingestion:
                st.session_state.pipeline['ingestion_output'] = None
                st.session_state.pipeline['ingestion_last_run'] = None

            if run_ingestion:
                with st.spinner("Running ingestion agent..."):
                    try:
                        ingestion_agent = IngestionAgent(st.session_state.pipeline['config']["llm"])  # expects key "llm"
                        st.session_state.pipeline['ingestion_output'] = ingestion_agent.run(
                            molecule=st.session_state.pipeline['molecule'],
                            region=st.session_state.pipeline['region'],
                            process_description=st.session_state.pipeline['extracted_texts']["process_description"],
                            specification=st.session_state.pipeline['extracted_texts']["specification"],
                            stability_report=st.session_state.pipeline['extracted_texts']["stability_report"]
                        )
                        st.session_state.pipeline['ingestion_last_run'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                        st.success("Ingestion completed!")
                        st.json(st.session_state.pipeline['ingestion_output'])
                    except Exception as e:
                        st.error(f"Ingestion failed: {e}")

        with tab3:
            if st.session_state.pipeline['ingestion_output']:
                colA, colB = st.columns([1,1])
                with colA:
                    run_search_btn = st.button("🔍 Run Regulatory Search", type="secondary")
                with colB:
                    reset_search_btn = st.button("♻️ Reset Search")

                if reset_search_btn:
                    st.session_state.pipeline['search_results'] = None
                    st.session_state.pipeline['vectordb_path'] = None
                    st.session_state.pipeline['search_last_run'] = None

                if run_search_btn:
                    with st.spinner("Searching for regulatory documents..."):
                        try:
                            st.session_state.pipeline['search_results'] = run_regulatory_search(
                                molecule=st.session_state.pipeline['molecule'],
                                context=st.session_state.pipeline['ingestion_output'],
                                region=st.session_state.pipeline['region']
                            )
                            # persist the FAISS path separately for robustness
                            st.session_state.pipeline['vectordb_path'] = (
                                st.session_state.pipeline['search_results'].get('vectorstore') if st.session_state.pipeline['search_results'] else None
                            )
                            st.session_state.pipeline['search_last_run'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                            st.success("Regulatory search completed!")
                            display_search_results(st.session_state.pipeline['search_results'])
                        except Exception as e:
                            st.error(f"Search failed: {e}")

            # Show persisted search info even after reruns
            if st.session_state.pipeline['search_results']:
                st.info(f"Vectorstore: {st.session_state.pipeline['vectordb_path']}")
                display_search_results(st.session_state.pipeline['search_results'])

        with tab4:
            sel = st.session_state.pipeline['selected_section']
            if sel and sel in st.session_state.pipeline['writing_results']:
                display_writing_results(st.session_state.pipeline['writing_results'][sel])
            else:
                if sel:
                    st.warning("No generated content yet for the selected section. Use the button in the left panel.")
                else:
                    st.info("Select a CTD leaf section from the left to generate content.")


def navigate_ctd_sections(sections, parent_path=""):
    """Recursive function to navigate CTD sections"""
    selected = None

    for section_name, subsection in sections.items():
        full_path = f"{parent_path}/{section_name}" if parent_path else section_name

        if subsection:  # Has subsections
            with st.expander(section_name):
                selected = navigate_ctd_sections(subsection, full_path)
                if selected:
                    return selected
        else:  # Leaf section
            if st.button(section_name, key=full_path):
                return full_path

    return selected


def display_extraction_results():
    """Display extracted text results with non-empty labels (avoid Streamlit warning)."""
    et = st.session_state.pipeline['extracted_texts']
    ts = st.session_state.pipeline['extraction_last_run']
    if ts:
        st.caption(f"Last extraction: {ts}")
    for key, text in et.items():
        if text:
            with st.expander(f"{key.replace('_', ' ').title()}"):
                # Provide a non-empty label and hide it visually
                st.text_area(
                    label=f"{key} preview",
                    value=(text[:1000] + "...") if len(text) > 1000 else text,
                    height=150,
                    key=f"extracted_{key}",
                    label_visibility="collapsed",
                    disabled=True,
                )


def display_search_results(results):
    """Display search results"""
    if results:
        st.subheader("Search Results")

        col1, col2 = st.columns(2)

        with col1:
            st.metric("Status", results.get('status', 'unknown'))
            st.metric("Documents Found", len(results.get('downloaded_files', [])))

        with col2:
            st.metric("URLs Found", len(results.get('found_urls', [])))
            if st.session_state.pipeline['vectordb_path']:
                st.info(f"Vectorstore: {st.session_state.pipeline['vectordb_path']}")

        if results.get('search_queries'):
            with st.expander("Generated Search Queries"):
                for i, query in enumerate(results['search_queries'], 1):
                    st.write(f"{i}. {query}")

        if results.get('downloaded_files'):
            with st.expander("Top Documents"):
                for i, file in enumerate(results['downloaded_files'][:3], 1):
                    st.write(f"**{i}. Score: {file.get('score', 0):.2f}**")
                    st.write(f"File: `{file.get('local_path', '')}`")
                    st.write(f"Source: {file.get('url', '')}")
                    st.markdown("---")


def display_writing_results(results):
    """Display writing agent results"""
    status = results.get('status', 'success')
    if status == 'success':
        st.subheader(f"Generated Content: {results.get('section_name')}")

        st.text_area(
            "generated_content_textarea_label",
            value=results.get('generated_content', ''),
            height=400,
            key=f"generated_{results.get('section_name', 'section')}",
            label_visibility='collapsed'
        )

        if results.get('citations'):
            with st.expander("📚 Citations & References"):
                for i, citation in enumerate(results.get('citations', []), 1):
                    st.write(f"{i}. **{citation.get('reference', '')}**")
                    st.write(f"   Context: {citation.get('context', '')}")
                    st.markdown("---")

        if st.button("💾 Download Section"):
            download_content(results)

    elif status == 'error':
        st.error(f"Error: {results.get('error', 'Unknown error')}")


def download_content(results):
    """Download generated content"""
    content = f"""
CTD Section: {results.get('section_name')}
Molecule: {results.get('molecule')}
Region: {results.get('region')}
Generated on: {results.get('generated_at', '')}

{'='*50}

{results.get('generated_content', '')}

{'='*50}

REFERENCES:
"""

    for i, citation in enumerate(results.get('citations', []), 1):
        content += f"\n{i}. {citation.get('reference', '')}"

    st.download_button(
        label="Download TXT",
        data=content,
        file_name=f"ctd_section_{str(results.get('section_name', '')).replace(' ', '_').replace('.', '_')}.txt",
        mime="text/plain"
    )


def extract_text_from_pdfs(process_file, spec_file, stability_file):
    """Extract text from PDF files"""
    try:
        def extract_pdf_text(file):
            if file is None:
                return ""
            file.seek(0)
            pdf_reader = PyPDF2.PdfReader(io.BytesIO(file.read()))
            text = ""
            for page in pdf_reader.pages:
                t = page.extract_text() or ''
                text += t + "\n"
            return text.strip()

        return {
            "process_description": extract_pdf_text(process_file),
            "specification": extract_pdf_text(spec_file),
            "stability_report": extract_pdf_text(stability_file)
        }

    except Exception as e:
        raise Exception(f"PDF extraction failed: {e}")


if __name__ == "__main__":
    main()
