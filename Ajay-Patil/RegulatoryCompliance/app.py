# Enhanced version with better UI
import streamlit as st
import yaml
import json
from src.agents.ingestion_agent import IngestionAgent
from src.agents.search_agents import run_regulatory_search
from exception.custom_exception import CustomException
from logger.custom_logger import CustomLogger
import tempfile
import os

# Initialize logger
logger = CustomLogger().get_logger(__name__)

def main():
    st.set_page_config(
        page_title="Regulatory Compliance Analyzer",
        page_icon="📊",
        layout="wide"
    )
    
    st.title("📊 Regulatory Compliance Analyzer")
    st.markdown("Analyze regulatory compliance for pharmaceutical molecules across different regions")
    st.markdown("---")
    
    # Initialize session state
    if 'extracted_texts' not in st.session_state:
        st.session_state.extracted_texts = {
            "process_description": "",
            "specification": "",
            "stability_report": ""
        }
    
    if 'analysis_results' not in st.session_state:
        st.session_state.analysis_results = None
    
    # Load configuration
    try:
        with open("./config/config.yaml", "r") as f:
            config = yaml.safe_load(f)
        st.session_state.config = config
    except Exception as e:
        st.error(f"Failed to load configuration: {e}")
        return
    
    # Sidebar
    with st.sidebar:
        st.header("🔧 Configuration")
        
        regions = ["India", "USA", "EU", "UK", "Japan", "China", "Brazil"]
        molecule_options = ["Paracetamol", "Ibuprofen", "Aspirin", "Metformin", "Amoxicillin", "Other"]
        
        region = st.selectbox("Region:", regions, index=0)
        molecule_type = st.selectbox("Molecule:", molecule_options, index=0)
        
        if molecule_type == "Other":
            molecule = st.text_input("Custom Molecule Name:")
        else:
            molecule = molecule_type
        
        st.markdown("---")
        st.header("📄 Document Upload")
        
        process_file = st.file_uploader("Process Description PDF", type="pdf")
        spec_file = st.file_uploader("Specification PDF", type="pdf")
        stability_file = st.file_uploader("Stability Report PDF", type="pdf")
        
        upload_btn = st.button("📝 Extract Text", disabled=not all([process_file, spec_file, stability_file]))
    
    # Main content
    col1, col2 = st.columns([1, 1])
    
    with col1:
        st.header("📋 Extracted Content")
        
        if upload_btn:
            with st.spinner("Extracting text from PDFs..."):
                try:
                    st.session_state.extracted_texts = extract_text_from_pdfs(
                        process_file, spec_file, stability_file
                    )
                    st.success("Text extraction completed!")
                except Exception as e:
                    st.error(f"Extraction failed: {e}")
        
        # Display extracted text
        for key, text in st.session_state.extracted_texts.items():
            if text:
                with st.expander(f"{key.replace('_', ' ').title()}"):
                    st.text_area("", value=text[:1500] + "..." if len(text) > 1500 else text, 
                               height=200, key=f"{key}_display")
    
    with col2:
        st.header("🔍 Analysis Results")
        
        analysis_btn = st.button("🚀 Run Analysis", 
                               disabled=not any(st.session_state.extracted_texts.values()))
        
        if analysis_btn:
            progress_bar = st.progress(0)
            status_text = st.empty()
            
            try:
                # Step 1: Ingestion
                status_text.text("Running ingestion agent...")
                ingestion_agent = IngestionAgent(st.session_state.config["llm"])
                
                ingestion_output = ingestion_agent.run(
                    molecule=molecule,
                    region=region,
                    process_description=st.session_state.extracted_texts["process_description"],
                    specification=st.session_state.extracted_texts["specification"],
                    stability_report=st.session_state.extracted_texts["stability_report"]
                )
                progress_bar.progress(33)
                
                # Step 2: Regulatory Search
                status_text.text("Running regulatory search...")
                results = run_regulatory_search(
                    molecule=molecule,
                    context=ingestion_output,
                    region=region
                )
                progress_bar.progress(66)
                
                st.session_state.analysis_results = results
                progress_bar.progress(100)
                status_text.text("Analysis completed!")
                
                # Display results
                display_results(results)
                
            except Exception as e:
                st.error(f"Analysis failed: {e}")

def display_results(results):
    """Display analysis results in a user-friendly format"""
    
    st.subheader("📊 Results Summary")
    
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Status", results['status'].title())
    with col2:
        st.metric("Documents Processed", len(results['downloaded_files']))
    with col3:
        st.metric("URLs Found", len(results['found_urls']))
    
    # Search Queries
    if results['search_queries']:
        with st.expander("🔍 Generated Search Queries"):
            for i, query in enumerate(results['search_queries'], 1):
                st.write(f"**{i}.** {query}")
    
    # Top Documents
    if results['downloaded_files']:
        with st.expander("📄 Top Relevant Documents"):
            for i, file in enumerate(results['downloaded_files'][:5], 1):
                st.markdown(f"""
                **{i}. Document** (Score: {file['score']:.2f})
                - **File:** `{file['local_path']}`
                - **Source:** [{file['url']}]({file['url']})
                """)
                st.markdown("---")
    
    # All URLs
    if results['found_urls']:
        with st.expander("🌐 All Found URLs"):
            for i, url in enumerate(results['found_urls'][:15], 1):
                st.write(f"{i}. [{url}]({url})")
    
    if results['vectorstore']:
        st.info(f"📚 Vector database created at: `{results['vectorstore']}`")
    
    st.success(results['message'])

def extract_text_from_pdfs(process_file, spec_file, stability_file):
    """Extract text from PDF files using PyPDF2"""
    try:
        import PyPDF2
        import io
        
        def extract_text(file):
            file.seek(0)
            pdf_reader = PyPDF2.PdfReader(io.BytesIO(file.read()))
            text = ""
            for page in pdf_reader.pages:
                text += page.extract_text() + "\n"
            return text.strip()
        
        return {
            "process_description": extract_text(process_file),
            "specification": extract_text(spec_file),
            "stability_report": extract_text(stability_file)
        }
        
    except Exception as e:
        raise Exception(f"PDF extraction failed: {e}")

if __name__ == "__main__":
    main()