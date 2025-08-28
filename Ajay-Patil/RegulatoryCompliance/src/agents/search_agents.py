# search_agent.py
import os
from typing import Dict, List, Optional, Tuple
from dotenv import load_dotenv

from langchain_groq import ChatGroq
from langchain_core.output_parsers import StrOutputParser
from langchain_community.tools.tavily_search import TavilySearchResults
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import FAISS
from langchain_core.embeddings import Embeddings
from langchain_community.embeddings import HuggingFaceEmbeddings

from exception.custom_exception import CustomException
from logger.custom_logger import CustomLogger

# Utils & Prompts (modularized)
from utils.search_utils import (
    initialize_environment, is_relevant_url, download_content, load_document,
    VECTORSTORE_DIR, MAX_DOWNLOADS
)
from src.prompts.search_prompt import regulatory_query_prompt

load_dotenv()
logger = CustomLogger().get_logger(__name__)


class SearchAgent:
    """
    Encapsulates the previous procedural flow into a class without changing functionality.
    """

    def __init__(self):
        self.logger = logger

    # ----- Components that were previously free functions -----

    def get_search_tool(self) -> TavilySearchResults:
        """Initialize Tavily search tool with proper configuration."""
        try:
            tavily_api_key = os.getenv("TAVILY_API_KEY")
            if not tavily_api_key:
                error_msg = "TAVILY_API_KEY not set in environment variables"
                self.logger.error(error_msg)
                raise CustomException(error_msg)

            self.logger.info("Initialized Tavily search tool")
            return TavilySearchResults(max_results=7, include_raw_content=True)
        except Exception as e:
            error_msg = f"Failed to initialize search tool: {str(e)}"
            self.logger.error(error_msg)
            raise CustomException(error_msg, e)

    def get_embeddings(self) -> Embeddings:
        """Initialize embeddings model."""
        try:
            self.logger.info("Initializing HuggingFace embeddings")
            return HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
        except Exception as e:
            error_msg = f"Failed to initialize embeddings: {str(e)}"
            self.logger.error(error_msg)
            raise CustomException(error_msg, e)

    def score_document_relevance(self, doc: Dict, molecule: str, region: str) -> int:
        """Score documents based on regulatory relevance with molecule-specific scoring."""
        try:
            title = (doc.get('title') or '').lower()
            url = (doc.get('url') or '').lower()
            content = (doc.get('content') or '').lower()
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

            ich_terms = {'q1a': 5, 'q3a': 5, 'q6a': 5, 'q7': 5, 'e6': 4}
            for term, weight in ich_terms.items():
                if term in content:
                    score += weight

            if molecule_lower in title:
                score += 3
            if molecule_lower in content[:2000]:
                score += 2

            self.logger.debug(f"Document scored: {url} -> {score}")
            return score
        except Exception as e:
            self.logger.error(f"Document scoring failed: {str(e)}")
            return 0

    def generate_search_queries(self, molecule: str, context: Dict, region: str) -> List[str]:
        """Generate focused regulatory search queries using LLM with enhanced prompt."""
        try:
            self.logger.info(f"Generating search queries for {molecule} in {region}")
            llm = ChatGroq(
                model="deepseek-r1-distill-llama-70b",
                temperature=0.3,
                api_key=os.getenv("GROQ_API_KEY")
            )

            prompt = regulatory_query_prompt()
            chain = prompt | llm | StrOutputParser()
            response = chain.invoke({
                "molecule": molecule,
                "context": "\n".join(f"{k}: {v}" for k, v in (context or {}).items()),
                "region": region
            })

            queries: List[str] = []
            for q in (response or "").split('\n'):
                q = (q or "").strip()
                if not q:
                    continue
                if 'filetype:' not in q.lower() and not q.lower().endswith('.pdf'):
                    q += " filetype:pdf"
                if region.lower() == 'india' and 'site:cdsco.gov.in' not in q.lower():
                    if 'site:' not in q.lower():
                        q = f"site:cdsco.gov.in {q}"
                queries.append(q)

            self.logger.info(f"Generated {len(queries)} search queries")
            return queries[:12]
        except Exception as e:
            error_msg = f"Failed to generate search queries: {str(e)}"
            self.logger.error(error_msg)
            raise CustomException(error_msg, e)

    def ensure_regulatory_coverage(self, docs: List, molecule: str, region: str) -> List:
        """Ensure key regulatory documents are included in the results."""
        try:
            self.logger.info("Checking regulatory document coverage")
            required_docs = []

            has_monograph = any(
                'monograph' in (getattr(doc, "metadata", {}).get('title', '') or '').lower() or
                'monograph' in (getattr(doc, "page_content", '') or '').lower()
                for doc in docs
            )

            if not has_monograph:
                self.logger.info("No monograph found - attempting to fetch one")
                search_tool = self.get_search_tool()
                query = (f"{molecule} monograph site:ipc.gov.in filetype:pdf"
                         if region.lower() == 'india'
                         else f"{molecule} monograph site:usp.org filetype:pdf")
                try:
                    results = search_tool.invoke({"query": query})
                    if results:
                        for result in results[:2]:
                            if isinstance(result, dict) and is_relevant_url(result.get('url', ''), region):
                                filepath, _ = download_content(result['url'])
                                if filepath:
                                    new_docs = load_document(filepath)
                                    if new_docs:
                                        required_docs.extend(new_docs)
                                        self.logger.info(f"Added monograph from {result['url']}")
                                        break
                except Exception as e:
                    self.logger.warning(f"Failed to fetch monograph: {e}")

            has_ich = any(
                'ich' in (getattr(doc, "metadata", {}).get('title', '') or '').lower() or
                'ich' in (getattr(doc, "page_content", '') or '').lower()
                for doc in docs
            )

            if not has_ich:
                self.logger.info("No ICH guidelines found - attempting to fetch")
                search_tool = self.get_search_tool()
                query = f"ICH guidelines {molecule} filetype:pdf"
                try:
                    results = search_tool.invoke({"query": query})
                    if results:
                        for result in results[:2]:
                            if isinstance(result, dict) and is_relevant_url(result.get('url', ''), region):
                                filepath, _ = download_content(result['url'])
                                if filepath:
                                    new_docs = load_document(filepath)
                                    if new_docs:
                                        required_docs.extend(new_docs)
                                        self.logger.info(f"Added ICH guidelines from {result['url']}")
                                        break
                except Exception as e:
                    self.logger.warning(f"Failed to fetch ICH guidelines: {e}")

            return docs + required_docs
        except Exception as e:
            self.logger.error(f"Regulatory coverage check failed: {str(e)}")
            return docs

    def create_vectorstore_from_documents(self, all_docs: List, molecule: str, region: str) -> Optional[str]:
        """Create vectorstore from downloaded documents with robust error handling."""
        try:
            if not all_docs:
                self.logger.error("No documents provided for vectorstore creation")
                return None

            self.logger.info(f"Creating vectorstore from {len(all_docs)} documents")

            embeddings = self.get_embeddings()

            text_splitter = RecursiveCharacterTextSplitter(
                chunk_size=1000, chunk_overlap=200, length_function=len, is_separator_regex=False
            )

            splits = text_splitter.split_documents(all_docs)
            self.logger.info(f"Split documents into {len(splits)} chunks")

            if not splits:
                self.logger.error("No document chunks created after splitting")
                return None

            vectorstore_name = f"{molecule.lower()}_{region.lower()}_docs".replace(' ', '_')
            vectorstore_path = os.path.join(VECTORSTORE_DIR, vectorstore_name)

            self.logger.info(f"Creating FAISS vectorstore at {vectorstore_path}")
            vectorstore = FAISS.from_documents(splits, embeddings)
            vectorstore.save_local(vectorstore_path)
            self.logger.info(f"Vectorstore successfully saved to {vectorstore_path}")

            return vectorstore_path

        except Exception as e:
            error_msg = f"Failed to create vectorstore: {str(e)}"
            self.logger.error(error_msg)
            raise CustomException(error_msg, e)

    # ----- Orchestrator (was run_regulatory_search) -----

    def run(self, molecule: str, context: Dict, region: str) -> Dict:
        """Main search and document processing workflow (functionality unchanged)."""
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

        try:
            # 1) Queries
            queries = self.generate_search_queries(molecule, context, region)
            response['search_queries'] = queries
            if not queries:
                response['message'] = "No search queries generated"
                self.logger.error(response['message'])
                return response

            # 2) Search & score
            search_tool = self.get_search_tool()
            scored_results: List[Dict] = []
            for query in queries:
                try:
                    self.logger.debug(f"Executing search: {query}")
                    results = search_tool.invoke({"query": query})
                    if isinstance(results, list):
                        iterable = results
                    elif isinstance(results, dict) and 'results' in results:
                        iterable = results['results']
                    else:
                        iterable = []

                    for result in iterable:
                        if isinstance(result, dict) and is_relevant_url(result.get('url', ''), region):
                            result['score'] = self.score_document_relevance(result, molecule, region)
                            scored_results.append(result)
                except Exception as e:
                    self.logger.error(f"Search failed for '{query}': {e}")
                    continue

            # Dedup & top-N
            unique_results: Dict[str, Dict] = {}
            for r in sorted(scored_results, key=lambda x: x.get('score', 0), reverse=True):
                url = r.get('url')
                if url and url not in unique_results:
                    unique_results[url] = r

            urls = list(unique_results.keys())[:MAX_DOWNLOADS * 2]
            response['found_urls'] = urls
            self.logger.info(f"Found {len(urls)} relevant URLs")

            # 3) Download
            downloaded_files: List[Dict] = []
            for url in urls[:MAX_DOWNLOADS]:
                try:
                    self.logger.debug(f"Downloading URL: {url}")
                    filepath, content_type = download_content(url)
                    if filepath:
                        downloaded_files.append({
                            'url': url,
                            'local_path': filepath,
                            'content_type': content_type,
                            'score': unique_results[url].get('score', 0)
                        })
                except Exception as e:
                    self.logger.error(f"Failed to download {url}: {e}")
                    continue

            if not downloaded_files:
                response['message'] = "No documents downloaded"
                self.logger.error(response['message'])
                return response

            # 4) Load
            all_docs = []
            for f in downloaded_files:
                try:
                    self.logger.debug(f"Loading document: {f['local_path']}")
                    docs = load_document(f['local_path'], f['content_type'])
                    if docs:
                        all_docs.extend(docs)
                        self.logger.info(f"Loaded {len(docs)} pages from {f['local_path']}")
                except Exception as e:
                    self.logger.error(f"Failed to load {f['local_path']}: {e}")
                    continue

            if not all_docs:
                response['message'] = "No documents loaded successfully"
                self.logger.error(response['message'])
                return response

            # 5) Ensure coverage
            all_docs = self.ensure_regulatory_coverage(all_docs, molecule, region)

            # 6) Vectorstore
            vectorstore_path = self.create_vectorstore_from_documents(all_docs, molecule, region)
            if not vectorstore_path:
                response['message'] = "Vectorstore creation failed"
                self.logger.error(response['message'])
                return response

            downloaded_files.sort(key=lambda x: x['score'], reverse=True)

            response.update({
                'downloaded_files': downloaded_files[:MAX_DOWNLOADS],
                'vectorstore': vectorstore_path,
                'status': 'success',
                'message': f"Processed {len(downloaded_files)} documents. Vectorstore created at {vectorstore_path}."
            })
            self.logger.info(f"Search completed successfully: {response['message']}")
            return response

        except Exception as e:
            error_msg = f"Regulatory search failed: {str(e)}"
            self.logger.error(error_msg)
            response['message'] = error_msg
            return response


# Optional: keep a compatible CLI/entrypoint similar to the original
if __name__ == "__main__":
    try:
        agent = SearchAgent()
        context = {
            "process_description": "The synthesis of Paracetamol involves a three-step process: 1) Acetylation, 2) Nitro reduction, and 3) Recrystallization.",
            "specification": ("The specifications for Paracetamol (IP 2022) include: - Assay: 99.0 – 101.0 % (HPLC "
                              "with external standard). - Impurity A: ≤ 0.10 % (HPLC). - Loss on Drying: ≤ 0.5 % "
                              "(USP <731>). - Residue on Ignition: ≤ 0.1 % (USP <281>)."),
            "stability_report": ("The stability study follows ICH Q1A (R2) guidelines. Accelerated conditions "
                                 "(40 °C/75 % RH) for 6 months show: - Assay decrease: −0.8 % (within specification). "
                                 "- Impurity A increase: +0.03 % (0.08 % at 6 months). Physical appearance remains "
                                 "unchanged. Long-term conditions (30 °C/65 % RH) for 12 months show all parameters "
                                 "remain within specification. Paracetamol API is stable in LDPE/aluminium laminate "
                                 "packs with a proposed re-test period of 36 months when stored at ≤ 30 °C."),
            "regulatory_requirements": ("Must comply with: - IP 2022 monograph for Paracetamol - ICH Q3A for impurities "
                                        "- WHO guidelines for API manufacturing - CDSCO guidance on stability testing")
        }

        results = agent.run(molecule="Paracetamol", context=context, region="India")

        logger.info("\n=== REGULATORY SEARCH RESULTS ===")
        logger.info(f"Status: {results['status']}")
        logger.info(f"Molecule: {results['molecule']}")
        logger.info(f"Region: {results['region']}")

        if results.get('search_queries'):
            logger.info("\nGenerated Search Queries:")
            for i, query in enumerate(results['search_queries'], 1):
                logger.info(f"{i}. {query}")

        if results.get('downloaded_files'):
            logger.info("\nTop Downloaded Documents (sorted by relevance):")
            for i, file in enumerate(results['downloaded_files'], 1):
                logger.info(f"{i}. Score: {file['score']} - {file['local_path']}")
                logger.info(f"   Source: {file['url']}")

        if results.get('found_urls'):
            logger.info("\nAll Relevant URLs Found:")
            for i, url in enumerate(results['found_urls'], 1):
                logger.info(f"{i}. {url}")

        if results.get('vectorstore'):
            logger.info(f"\nVectorstore created at: {results['vectorstore']}")

        logger.info(f"\nMessage: {results['message']}")

    except Exception as e:
        logger.error(f"Fatal error in main execution: {str(e)}")
        raise CustomException(f"Main execution failed: {str(e)}", e)
