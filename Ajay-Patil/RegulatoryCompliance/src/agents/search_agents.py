import os
import requests
import time
import re
from typing import Dict, List, Optional, Tuple
from pathlib import Path
from urllib.parse import urlparse
from langchain_community.tools.tavily_search import TavilySearchResults
from langchain_groq import ChatGroq
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_community.document_loaders import WebBaseLoader, PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import FAISS
from langchain_core.embeddings import Embeddings
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain.agents import AgentExecutor, create_react_agent
from langchain_core.messages import SystemMessage, HumanMessage
from exception.custom_exception import CustomException
from logger.custom_logger import CustomLogger
from dotenv import load_dotenv
load_dotenv()
# Initialize logger
logger = CustomLogger().get_logger(__name__)

# Configuration
DOWNLOAD_DIR = "downloaded_docs"
VECTORSTORE_DIR = "vectorstore"
REQUEST_TIMEOUT = 30
MAX_DOWNLOADS = 15
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
}

# Enhanced Domain whitelist with regulatory focus
TRUSTED_DOMAINS = {
    'india': [
        'cdsco.gov.in', 'ipc.gov.in', 'pharmaceuticals.gov.in', 
        'who.int', 'ich.org', 'usp.org', 'edqm.eu', 'pharmacopoeia.com',
        'fda.gov', 'ema.europa.eu', 'pmda.go.jp', 'tga.gov.au',
        'pharmabiz.com', 'pharmatutor.org', 'sciencedirect.com',
        'researchgate.net', 'springer.com', 'pharmasm.com',
        'ncbi.nlm.nih.gov', 'pubmed.ncbi.nlm.nih.gov', 'frontiersin.org',
        'mdpi.com', 'acs.org', 'rsc.org'
    ],
    'default': [
        'fda.gov', 'ema.europa.eu', 'who.int', 'ich.org', 
        'usp.org', 'edqm.eu', 'pmda.go.jp', 'tga.gov.au',
        'ncbi.nlm.nih.gov', 'sciencedirect.com', 'researchgate.net',
        'springer.com', 'mdpi.com', 'frontiersin.org',
        'pubmed.ncbi.nlm.nih.gov', 'acs.org', 'rsc.org'
    ]
}

def initialize_environment():
    """Create necessary directories."""
    try:
        os.makedirs(DOWNLOAD_DIR, exist_ok=True)
        os.makedirs(VECTORSTORE_DIR, exist_ok=True)
        logger.info(f"Initialized directories: {DOWNLOAD_DIR}, {VECTORSTORE_DIR}")
    except Exception as e:
        error_msg = f"Failed to initialize environment: {str(e)}"
        logger.error(error_msg)
        raise CustomException(error_msg, e)

def get_search_tool():
    """Initialize Tavily search tool with proper configuration."""
    try:
        tavily_api_key = os.getenv("TAVILY_API_KEY")
        if not tavily_api_key:
            error_msg = "TAVILY_API_KEY not set in environment variables"
            logger.error(error_msg)
            raise CustomException(error_msg)
        
        logger.info("Initialized Tavily search tool")
        return TavilySearchResults(max_results=7, include_raw_content=True)
    except Exception as e:
        error_msg = f"Failed to initialize search tool: {str(e)}"
        logger.error(error_msg)
        raise CustomException(error_msg, e)

def get_embeddings() -> Embeddings:
    """Initialize embeddings model."""
    try:
        logger.info("Initializing HuggingFace embeddings")
        return HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
    except Exception as e:
        error_msg = f"Failed to initialize embeddings: {str(e)}"
        logger.error(error_msg)
        raise CustomException(error_msg, e)

def is_relevant_url(url: str, region: str) -> bool:
    """Check if URL is from a trusted domain with enhanced matching."""
    try:
        domain = urlparse(url).netloc.lower()
        domain = re.sub(r'^www\.', '', domain)
        trusted_domains = TRUSTED_DOMAINS.get(region.lower(), TRUSTED_DOMAINS['default'])
        result = any(domain.endswith(td) for td in trusted_domains)
        logger.debug(f"URL relevance check: {url} -> {result}")
        return result
    except Exception as e:
        error_msg = f"URL relevance check failed for {url}: {str(e)}"
        logger.error(error_msg)
        return False

def sanitize_filename(filename: str) -> str:
    """Sanitize filename to be filesystem-safe with improved handling."""
    try:
        filename = re.sub(r'[^\w\-_. ]', '_', filename)
        if len(filename) > 150:
            name, ext = os.path.splitext(filename)
            filename = name[:150-len(ext)] + ext
        return filename
    except Exception as e:
        error_msg = f"Filename sanitization failed: {str(e)}"
        logger.error(error_msg)
        raise CustomException(error_msg, e)

def download_content(url: str) -> Tuple[Optional[str], Optional[str]]:
    """Download content from URL and save locally with enhanced handling."""
    try:
        parsed = urlparse(url)
        if not all([parsed.scheme, parsed.netloc]):
            error_msg = f"Invalid URL: {url}"
            logger.error(error_msg)
            raise CustomException(error_msg)

        domain_part = parsed.netloc.replace('www.', '').split('.')[0]
        path_part = os.path.splitext(os.path.basename(parsed.path))[0][:50]
        timestamp = int(time.time())
        filename = f"{domain_part}_{path_part}_{timestamp}"
        filepath = os.path.join(DOWNLOAD_DIR, filename)
        
        existing_files = [f for f in os.listdir(DOWNLOAD_DIR) if f.startswith(f"{domain_part}_{path_part}")]
        if existing_files:
            logger.info(f"Using existing file for {url}: {existing_files[0]}")
            return os.path.join(DOWNLOAD_DIR, existing_files[0]), None
            
        logger.info(f"Downloading content from {url}")
        response = requests.get(url, headers=HEADERS, stream=True, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()
        
        content_type = response.headers.get('Content-Type', '')
        if 'application/pdf' in content_type:
            filepath += '.pdf'
        elif 'text/html' in content_type:
            filepath += '.html'
        elif 'text/plain' in content_type:
            filepath += '.txt'
        else:
            if url.lower().endswith('.pdf'):
                filepath += '.pdf'
            elif url.lower().endswith(('.html', '.htm')):
                filepath += '.html'
            else:
                filepath += '.html'
        
        temp_filepath = filepath + '.download'
        with open(temp_filepath, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
        
        if os.path.getsize(temp_filepath) > 1024:
            os.rename(temp_filepath, filepath)
            logger.info(f"Successfully downloaded {url} to {filepath}")
            return filepath, content_type
        else:
            os.remove(temp_filepath)
            error_msg = f"Downloaded file too small: {url}"
            logger.warning(error_msg)
            return None, None
            
    except requests.exceptions.RequestException as e:
        error_msg = f"Failed to download {url}: {str(e)}"
        logger.error(error_msg)
        return None, None
    except Exception as e:
        error_msg = f"Unexpected error downloading {url}: {str(e)}"
        logger.error(error_msg)
        raise CustomException(error_msg, e)

def load_document(filepath: str, content_type: str = None) -> Optional[List]:
    """Load document based on its type with enhanced error handling."""
    try:
        logger.info(f"Loading document: {filepath}")
        if filepath.lower().endswith('.pdf') or (content_type and 'pdf' in content_type.lower()):
            loader = PyPDFLoader(filepath)
            docs = loader.load()
            for doc in docs:
                doc.metadata['document_type'] = 'pdf'
            logger.info(f"Loaded {len(docs)} pages from PDF: {filepath}")
            return docs
        else:
            loader = WebBaseLoader(filepath)
            docs = loader.load()
            for doc in docs:
                doc.metadata['document_type'] = 'web'
            logger.info(f"Loaded web content from: {filepath}")
            return docs
    except Exception as e:
        error_msg = f"Failed to load {filepath}: {str(e)}"
        logger.error(error_msg)
        return None

def score_document_relevance(doc: Dict, molecule: str, region: str) -> int:
    """Score documents based on regulatory relevance with molecule-specific scoring."""
    try:
        title = doc.get('title', '').lower()
        url = doc.get('url', '').lower()
        content = (doc.get('content', '') or '').lower()
        molecule_lower = molecule.lower()
        
        score = 0
        
        domain_weights = {
            'cdsco.gov.in': 10, 'ipc.gov.in': 10, 'pharmaceuticals.gov.in': 8,
            'fda.gov': 9, 'ema.europa.eu': 9, 'ich.org': 9, 'usp.org': 8,
            'who.int': 7, 'edqm.eu': 7, 'pharmacopoeia.com': 7
        }
        
        for domain, weight in domain_weights.items():
            if domain in url:
                score += weight
                break
        
        doc_type_terms = {
            'guidance': 4, 'guideline': 4, 'standard': 4, 'monograph': 5,
            'regulation': 4, 'compliance': 3, 'specification': 4, 'requirement': 3
        }
        
        for term, weight in doc_type_terms.items():
            if term in title:
                score += weight
            if term in content[:2000]:
                score += weight - 1
        
        pharmacopoeia_terms = {
            'usp': 4, 'ip': 5 if region.lower() == 'india' else 3,
            'bp': 3, 'ep': 3, 'pharmacopoeia': 4
        }
        
        for term, weight in pharmacopoeia_terms.items():
            if term in content:
                score += weight
        
        ich_terms = {
            'q1a': 5, 'q3a': 5, 'q6a': 5, 'q7': 5, 'e6': 4
        }
        
        for term, weight in ich_terms.items():
            if term in content:
                score += weight
        
        if molecule_lower in title:
            score += 3
        if molecule_lower in content[:2000]:
            score += 2
        
        logger.debug(f"Document scored: {url} -> {score}")
        return score
    except Exception as e:
        error_msg = f"Document scoring failed: {str(e)}"
        logger.error(error_msg)
        return 0  # Return minimum score if scoring fails

def generate_search_queries(molecule: str, context: Dict, region: str) -> List[str]:
    """Generate focused regulatory search queries using LLM with enhanced prompt."""
    try:
        logger.info(f"Generating search queries for {molecule} in {region}")
        llm = ChatGroq(
            model="deepseek-r1-distill-llama-70b",
            temperature=0.3,
            api_key=os.getenv("GROQ_API_KEY")
        )
        
        regulatory_bodies = {
            'india': 'CDSCO and Indian Pharmacopoeia',
            'us': 'FDA and USP',
            'eu': 'EMA and EP',
            'uk': 'MHRA and BP'
        }.get(region.lower(), 'regulatory authorities')
        
        prompt = ChatPromptTemplate.from_messages([
            ("system", """You are a regulatory affairs expert specializing in pharmaceutical compliance. Generate precise, targeted search queries to find regulatory documents, guidelines, monographs, and standards for pharmaceutical molecules.

Key focus areas:
1. Pharmacopoeial monographs (USP, IP, EP, BP)
2. ICH guidelines (Q1A, Q3A, Q6A, Q7, E6)
3. Regulatory authority guidelines (FDA, EMA, CDSCO, WHO)
4. Stability testing requirements
5. Impurity profiling and control
6. Manufacturing and quality standards
7. Regional specific regulations

Format requirements:
- Include 'filetype:pdf' for document searches
- For India region, prioritize site:cdsco.gov.in and site:ipc.gov.in
- Use specific regulatory terminology
- Keep queries concise but comprehensive
- Return each query on a new line"""),
            ("human", "Generate comprehensive regulatory search queries for {molecule} in {region}")
        ])
        
        chain = prompt | llm | StrOutputParser()
        response = chain.invoke({
            "molecule": molecule,
            "context": "\n".join(f"{k}: {v}" for k,v in context.items()),
            "region": region,
            "regulatory_body": regulatory_bodies
        })
        
        queries = []
        for q in response.split('\n'):
            q = q.strip()
            if not q:
                continue
            if 'filetype:' not in q.lower() and not q.lower().endswith('.pdf'):
                q += " filetype:pdf"
            if region.lower() == 'india' and 'site:cdsco.gov.in' not in q.lower():
                if 'site:' not in q.lower():
                    q = f"site:cdsco.gov.in {q}"
            queries.append(q)
        
        logger.info(f"Generated {len(queries)} search queries")
        return queries[:12]
    except Exception as e:
        error_msg = f"Failed to generate search queries: {str(e)}"
        logger.error(error_msg)
        raise CustomException(error_msg, e)

def ensure_regulatory_coverage(docs: List, molecule: str, region: str) -> List:
    """Ensure key regulatory documents are included in the results."""
    try:
        logger.info("Checking regulatory document coverage")
        required_docs = []
        
        has_monograph = any(
            'monograph' in doc.metadata.get('title', '').lower() or
            'monograph' in doc.page_content.lower()
            for doc in docs
        )
        
        if not has_monograph:
            logger.info("No monograph found - attempting to fetch one")
            search_tool = get_search_tool()
            query = f"{molecule} monograph site:ipc.gov.in filetype:pdf" if region.lower() == 'india' else f"{molecule} monograph site:usp.org filetype:pdf"
            try:
                results = search_tool.invoke({"query": query})
                if results:
                    for result in results[:2]:
                        if isinstance(result, dict) and is_relevant_url(result.get('url'), region):
                            filepath, _ = download_content(result['url'])
                            if filepath:
                                new_docs = load_document(filepath)
                                if new_docs:
                                    required_docs.extend(new_docs)
                                    logger.info(f"Added monograph from {result['url']}")
                                    break
            except Exception as e:
                logger.warning(f"Failed to fetch monograph: {e}")
        
        has_ich = any(
            'ich' in doc.metadata.get('title', '').lower() or
            'ich' in doc.page_content.lower()
            for doc in docs
        )
        
        if not has_ich:
            logger.info("No ICH guidelines found - attempting to fetch")
            search_tool = get_search_tool()
            query = f"ICH guidelines {molecule} filetype:pdf"
            try:
                results = search_tool.invoke({"query": query})
                if results:
                    for result in results[:2]:
                        if isinstance(result, dict) and is_relevant_url(result.get('url'), region):
                            filepath, _ = download_content(result['url'])
                            if filepath:
                                new_docs = load_document(filepath)
                                if new_docs:
                                    required_docs.extend(new_docs)
                                    logger.info(f"Added ICH guidelines from {result['url']}")
                                    break
            except Exception as e:
                logger.warning(f"Failed to fetch ICH guidelines: {e}")
        
        return docs + required_docs
    except Exception as e:
        error_msg = f"Regulatory coverage check failed: {str(e)}"
        logger.error(error_msg)
        return docs  # Return original docs if check fails

def create_vectorstore_from_documents(all_docs: List, molecule: str, region: str) -> Optional[str]:
    """Create vectorstore from downloaded documents with robust error handling."""
    try:
        if not all_docs:
            logger.error("No documents provided for vectorstore creation")
            return None
        
        logger.info(f"Creating vectorstore from {len(all_docs)} documents")
        
        # Initialize embeddings
        embeddings = get_embeddings()
        
        # Split documents into chunks
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200,
            length_function=len,
            is_separator_regex=False
        )
        
        splits = text_splitter.split_documents(all_docs)
        logger.info(f"Split documents into {len(splits)} chunks")
        
        if not splits:
            logger.error("No document chunks created after splitting")
            return None
        
        # Create vectorstore name
        vectorstore_name = f"{molecule.lower()}_{region.lower()}_docs".replace(' ', '_')
        vectorstore_path = os.path.join(VECTORSTORE_DIR, vectorstore_name)
        
        # Create and save vectorstore
        logger.info(f"Creating FAISS vectorstore at {vectorstore_path}")
        vectorstore = FAISS.from_documents(splits, embeddings)
        
        # Save vectorstore
        vectorstore.save_local(vectorstore_path)
        logger.info(f"Vectorstore successfully saved to {vectorstore_path}")
        
        return vectorstore_path
        
    except Exception as e:
        error_msg = f"Failed to create vectorstore: {str(e)}"
        logger.error(error_msg)
        raise CustomException(error_msg, e)

def run_regulatory_search(molecule: str, context: Dict, region: str) -> Dict:
    """Enhanced main search and document processing workflow with logging."""
    try:
        logger.info(f"Starting regulatory search for {molecule} in {region}")
        initialize_environment()
        response = {
            'status': 'error',
            'molecule': molecule,
            'region': region,
            'context': context,
            'found_urls': [],
            'downloaded_files': [],
            'vectorstore': None,
            'message': 'Initialization failed',
            'search_queries': []
        }
        
        # Step 1: Generate enhanced search queries
        queries = generate_search_queries(molecule, context, region)
        response['search_queries'] = queries
        if not queries:
            response['message'] = "No search queries generated"
            logger.error(response['message'])
            return response
        
        # Step 2: Execute searches with scoring
        search_tool = get_search_tool()
        scored_results = []
        
        for query in queries:
            try:
                logger.debug(f"Executing search: {query}")
                results = search_tool.invoke({"query": query})
                if isinstance(results, list):
                    for result in results:
                        if isinstance(result, dict) and is_relevant_url(result.get('url'), region):
                            result['score'] = score_document_relevance(result, molecule, region)
                            scored_results.append(result)
                elif isinstance(results, dict) and 'results' in results:
                    for result in results['results']:
                        if isinstance(result, dict) and is_relevant_url(result.get('url'), region):
                            result['score'] = score_document_relevance(result, molecule, region)
                            scored_results.append(result)
            except Exception as e:
                logger.error(f"Search failed for '{query}': {e}")
                continue
        
        # Sort by score and remove duplicates
        unique_results = {}
        for result in sorted(scored_results, key=lambda x: x.get('score', 0), reverse=True):
            url = result.get('url')
            if url and url not in unique_results:
                unique_results[url] = result
        
        urls = list(unique_results.keys())[:MAX_DOWNLOADS*2]
        response['found_urls'] = urls
        logger.info(f"Found {len(urls)} relevant URLs")
        
        # Step 3: Download all content first
        downloaded_files = []
        for url in urls[:MAX_DOWNLOADS]:
            try:
                logger.debug(f"Downloading URL: {url}")
                filepath, content_type = download_content(url)
                if filepath:
                    downloaded_files.append({
                        'url': url,
                        'local_path': filepath,
                        'content_type': content_type,
                        'score': unique_results[url].get('score', 0)
                    })
            except Exception as e:
                logger.error(f"Failed to download {url}: {e}")
                continue
        
        if not downloaded_files:
            response['message'] = "No documents downloaded"
            logger.error(response['message'])
            return response
        
        # Step 4: Load all documents
        all_docs = []
        for file_info in downloaded_files:
            try:
                logger.debug(f"Loading document: {file_info['local_path']}")
                docs = load_document(file_info['local_path'], file_info['content_type'])
                if docs:
                    all_docs.extend(docs)
                    logger.info(f"Loaded {len(docs)} pages from {file_info['local_path']}")
            except Exception as e:
                logger.error(f"Failed to load {file_info['local_path']}: {e}")
                continue
        
        if not all_docs:
            response['message'] = "No documents loaded successfully"
            logger.error(response['message'])
            return response
        
        # Step 5: Ensure regulatory coverage
        all_docs = ensure_regulatory_coverage(all_docs, molecule, region)
        
        # Step 6: Create vectorstore from all loaded documents
        try:
            vectorstore_path = create_vectorstore_from_documents(all_docs, molecule, region)
            if not vectorstore_path:
                response['message'] = "Vectorstore creation failed"
                logger.error(response['message'])
                return response
        except Exception as e:
            error_msg = f"Vectorstore creation failed: {str(e)}"
            logger.error(error_msg)
            response['message'] = error_msg
            return response
        
        # Sort downloaded files by score
        downloaded_files.sort(key=lambda x: x['score'], reverse=True)
        
        response.update({
            'downloaded_files': downloaded_files[:MAX_DOWNLOADS],
            'vectorstore': vectorstore_path,
            'status': 'success',
            'message': f"Processed {len(downloaded_files)} documents. Vectorstore created at {vectorstore_path}."
        })
        
        logger.info(f"Search completed successfully: {response['message']}")
        return response
        
    except Exception as e:
        error_msg = f"Regulatory search failed: {str(e)}"
        logger.error(error_msg)
        response['message'] = error_msg
        return response

if __name__ == "__main__":
    try:
        # Enhanced example usage
        context = {
            "process_description": "The synthesis of Paracetamol involves a three-step process: 1) Acetylation, 2) Nitro reduction, and 3) Recrystallization.",
            "specification": "The specifications for Paracetamol (IP 2022) include: - Assay: 99.0 – 101.0 % (HPLC with external standard). - Impurity A: ≤ 0.10 % (HPLC). - Loss on Drying: ≤ 0.5 % (USP <731>). - Residue on Ignition: ≤ 0.1 % (USP <281>).",
            "stability_report": "The stability study follows ICH Q1A (R2) guidelines. Accelerated conditions (40 °C/75 % RH) for 6 months show: - Assay decrease: −0.8 % (within specification). - Impurity A increase: +0.03 % (0.08 % at 6 months). Physical appearance remains unchanged. Long-term conditions (30 °C/65 % RH) for 12 months show all parameters remain within specification. Paracetamol API is stable in LDPE/aluminium laminate packs with a proposed re-test period of 36 months when stored at ≤ 30 °C.",
            "regulatory_requirements": "Must comply with: - IP 2022 monograph for Paracetamol - ICH Q3A for impurities - WHO guidelines for API manufacturing - CDSCO guidance on stability testing"
        }
        
        results = run_regulatory_search(
            molecule="Paracetamol",
            context=context,
            region="India"
        )
        
        # Enhanced results printing
        logger.info("\n=== REGULATORY SEARCH RESULTS ===")
        logger.info(f"Status: {results['status']}")
        logger.info(f"Molecule: {results['molecule']}")
        logger.info(f"Region: {results['region']}")
        
        if results['search_queries']:
            logger.info("\nGenerated Search Queries:")
            for i, query in enumerate(results['search_queries'], 1):
                logger.info(f"{i}. {query}")
        
        if results['downloaded_files']:
            logger.info("\nTop Downloaded Documents (sorted by relevance):")
            for i, file in enumerate(results['downloaded_files'], 1):
                logger.info(f"{i}. Score: {file['score']} - {file['local_path']}")
                logger.info(f"   Source: {file['url']}")
        
        if results['found_urls']:
            logger.info("\nAll Relevant URLs Found:")
            for i, url in enumerate(results['found_urls'], 1):
                logger.info(f"{i}. {url}")
        
        if results['vectorstore']:
            logger.info(f"\nVectorstore created at: {results['vectorstore']}")
        
        logger.info(f"\nMessage: {results['message']}")
    
    except Exception as e:
        logger.error(f"Fatal error in main execution: {str(e)}")
        raise CustomException(f"Main execution failed: {str(e)}", e)