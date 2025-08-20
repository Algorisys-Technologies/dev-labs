import os
import re
from typing import Dict, List

from dotenv import load_dotenv
from logger.custom_logger import CustomLogger
from exception.custom_exception import CustomException

# LangChain
from langchain_groq import ChatGroq
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS, Chroma
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate

load_dotenv()
logger = CustomLogger().get_logger(__name__)


class WritingAgent:
    """
    Generates CTD section content grounded on a persisted vectorstore using a
    stable RetrievalQA chain (no fragile agent tool-calls).
    Returns structured content and citations (from retrieved source docs).
    """

    def __init__(self, llm_config: Dict):
        try:
            self.llm = self._initialize_llm(llm_config)
            self.embeddings = self._initialize_embeddings()
            logger.info("Writing Agent initialized with Groq DeepSeek and HF embeddings (RetrievalQA mode)")
        except Exception as e:
            logger.error(f"Failed to initialize Writing Agent: {e}")
            raise CustomException(f"Writing Agent initialization failed: {e}", e)
    def _get_regulatory_standards(self, region: str) -> str:
        standards = {
            "India": "CDSCO guidelines, Indian Pharmacopoeia (IP), WHO TRS, ICH Q series, Schedule M",
            "USA": "FDA guidelines, USP, ICH Q series, 21 CFR Part 211, cGMP",
            "EU": "EMA guidelines, Ph. Eur., ICH Q series, EU GMP Guide, Annexes",
            "UK": "MHRA guidelines, Ph. Eur., ICH Q series, Orange Guide",
            "Japan": "PMDA guidelines, JP, ICH Q series, GMP Ministerial Ordinance",
            "China": "NMPA guidelines, ChP, ICH Q series, GMP regulations",
            "Brazil": "ANVISA guidelines, Brazilian Pharmacopoeia, ICH Q series, RDC regulations",
        }
        return standards.get(region, "ICH Q series, WHO guidelines, regional pharmacopoeia")
    # -------------------
    # Init helpers
    # -------------------
    def _initialize_llm(self, llm_config: Dict):
        try:
            return ChatGroq(
                model_name=llm_config.get("model", "deepseek-r1-distill-llama-70b"),
                temperature=llm_config.get("temperature", 0.2),
                groq_api_key=os.getenv("GROQ_API_KEY"),
                max_tokens=llm_config.get("max_tokens", 4096),
            )
        except Exception as e:
            logger.error(f"Groq LLM initialization failed: {e}")
            raise CustomException(f"Groq LLM initialization failed: {e}", e)

    def _initialize_embeddings(self):
        try:
            return HuggingFaceEmbeddings(
                model_name="sentence-transformers/all-MiniLM-L6-v2",
                model_kwargs={"device": "cpu"},
                encode_kwargs={"normalize_embeddings": True},
            )
        except Exception as e:
            logger.error(f"HF embeddings initialization failed: {e}")
            raise CustomException(f"HF embeddings initialization failed: {e}", e)

    # -------------------
    # Vectorstore
    # -------------------
    def _load_vectorstore(self, vectorstore_path: str):
        if not os.path.exists(vectorstore_path):
            raise FileNotFoundError(f"Vectorstore not found at {vectorstore_path}")

        faiss_files = {
            os.path.join(vectorstore_path, "index.faiss"),
            os.path.join(vectorstore_path, "index.pkl"),
        }
        is_faiss = all(os.path.exists(p) for p in faiss_files)
        chroma_marker = os.path.join(vectorstore_path, "chroma-collections.parquet")
        is_chroma = os.path.exists(chroma_marker)

        if is_faiss:
            return FAISS.load_local(
                vectorstore_path,
                self.embeddings,
                allow_dangerous_deserialization=True,
            )
        if is_chroma:
            return Chroma(persist_directory=vectorstore_path, embedding_function=self.embeddings)

        # Fallback attempts
        try:
            return FAISS.load_local(
                vectorstore_path,
                self.embeddings,
                allow_dangerous_deserialization=True,
            )
        except Exception as e1:
            try:
                return Chroma(persist_directory=vectorstore_path, embedding_function=self.embeddings)
            except Exception as e2:
                raise Exception(f"Cannot load vectorstore. FAISS error: {e1}; Chroma error: {e2}")

    # -------------------
    # Public API
    # -------------------
    def generate_section_content(
        self,
        molecule: str,
        region: str,
        context: Dict,
        vectorstore_path: str,
        section_name: str,
    ) -> Dict:
        """Generate content for a CTD section using a RetrievalQA chain with citations."""
        try:
            vectorstore = self._load_vectorstore(vectorstore_path)
            retriever = vectorstore.as_retriever(search_kwargs={"k": 6})

            # Compose one strong question string; RetrievalQA expects input key 'query'
            question = self._compose_question(molecule, region, section_name, context)

            # Prompt for the combine_docs phase (stuff chain)
            prompt = self._make_prompt()

            qa = RetrievalQA.from_chain_type(
                llm=self.llm,
                chain_type="stuff",
                retriever=retriever,
                return_source_documents=True,
                chain_type_kwargs={
                    "prompt": prompt,
                },
            )

            result = qa.invoke({"query": question})
            answer = result.get("result", "")
            source_docs = result.get("source_documents", []) or []

            citations = self._citations_from_sources(source_docs)
            # Fallback: also parse inline [1], [2] if present
            if not citations:
                citations = self._extract_detailed_citations(answer)

            return {
                "status": "success",
                "section_name": section_name,
                "generated_content": answer,
                "molecule": molecule,
                "region": region,
                "citations": citations,
                "word_count": len(answer.split()),
                "citation_count": len(citations),
            }

        except Exception as e:
            logger.error(f"Failed to generate content for section {section_name}: {e}")
            return {
                "status": "error",
                "section_name": section_name,
                "error": str(e),
                "generated_content": f"Error generating content: {str(e)}",
                "citations": [],
            }

    # -------------------
    # Prompting
    # -------------------
    def _compose_question(self, molecule: str, region: str, section_name: str, context: Dict) -> str:
        return (
            f"Generate comprehensive, compliant content for CTD section '{section_name}' "
            f"for molecule '{molecule}' in region '{region}'.\n\n"
            f"CONTEXT:\n"
            f"- Process Description: {context.get('process_description','')}\n"
            f"- Specification: {context.get('specification','')}\n"
            f"- Stability Report: {context.get('stability_report','')}\n\n"
            f"Regulatory standards to follow: {self._get_regulatory_standards(region)}\n\n"
            "Requirements:\n"
            "1) Ground the answer in retrieved regulatory documents from the region.\n"
            "2) Include citations like [1], [2] with document/section/version where possible.\n"
            "3) Use professional regulatory tone; add bullet points/tables where relevant.\n"
        )

    def _make_prompt(self) -> PromptTemplate:
        template = (
            "You are a senior regulatory affairs expert. Use the following retrieved documents to "
            "produce accurate, compliant text for a CTD section.\n\n"
            "{context}\n\n"
            "CRITICAL:\n"
            "- Stay aligned with the region's regulatory standards in the question.\n"
            "- Integrate key specifics from the question's context.\n"
            "- Cite sources inline as [1], [2], ... and list references at the end.\n\n"
            "QUESTION:\n{question}\n\n"
            "--- Retrieved Documents ---\n{context}"
        )
        # For stuff chain, the variables are typically {context} and {question}
        return PromptTemplate(template=template, input_variables=["context", "question"])

    # -------------------
    # Citations utilities
    # -------------------
    def _citations_from_sources(self, source_docs) -> List[Dict]:
        citations: List[Dict] = []
        for i, doc in enumerate(source_docs, start=1):
            meta = getattr(doc, "metadata", {})
            if meta is None:
                meta = {}
            title = meta.get("title") or meta.get("source") or meta.get("file") or meta.get("path") or "Document"
            url = meta.get("url")
            section = meta.get("section") or meta.get("header")
            version = meta.get("version") or meta.get("date")
            ref_parts = [str(title)]
            if section:
                ref_parts.append(f"Section: {section}")
            if version:
                ref_parts.append(f"Version/Date: {version}")
            if url:
                ref_parts.append(f"URL: {url}")
            citations.append({
                "number": i,
                "reference": " | ".join(ref_parts),
                "document_type": self._identify_document_type(title or ""),
                "context": meta.get("summary") or meta.get("snippet") or "Retrieved source",
            })
        return citations

    def _extract_detailed_citations(self, content: str) -> List[Dict]:
        citations: List[Dict] = []
        if not content:
            return citations
        # [1] ... [2] ... pattern across newlines
        citation_pattern = r"\[(\d+)\](.*?)(?=\[\d+\]|$)"
        matches = re.finditer(citation_pattern, content, re.DOTALL)
        for match in matches:
            citation_num = match.group(1)
            citation_text = match.group(2).strip()
            citations.append({
                "number": int(citation_num),
                "reference": citation_text,
                "document_type": self._identify_document_type(citation_text),
                "context": self._extract_citation_context(citation_text),
            })
        return citations

    def _identify_document_type(self, text: str) -> str:
        tl = text.lower()
        if 'ich q' in tl or 'ich guideline' in tl:
            return "ICH Guideline"
        if 'who' in tl or 'world health organization' in tl:
            return "WHO Technical Report"
        if 'usp' in tl or 'united states pharmacopeia' in tl:
            return "USP Monograph"
        if 'ph. eur' in tl or 'european pharmacopoeia' in tl:
            return "European Pharmacopoeia"
        if ' ip ' in f" {tl} ":
            return "Indian Pharmacopoeia"
        if 'cdsco' in tl:
            return "CDSCO Guideline"
        if 'fda' in tl:
            return "FDA Guideline"
        if 'ema' in tl:
            return "EMA Guideline"
        if 'gmp' in tl:
            return "GMP Guideline"
        return "Regulatory Document"

    def _extract_citation_context(self, text: str) -> str:
        tl = text.lower()
        if any(x in tl for x in ['specification', 'assay', 'impurity']):
            return "Quality Control"
        if any(x in tl for x in ['manufacturing', 'process', 'validation']):
            return "Manufacturing Process"
        if any(x in tl for x in ['stability', 'storage', 'shelf life']):
            return "Stability"
        if any(x in tl for x in ['container', 'closure', 'packaging']):
            return "Packaging"
        if any(x in tl for x in ['safety', 'toxicology', 'adventitious']):
            return "Safety"
        return "General Regulatory"


if __name__ == "__main__":
    cfg = {
        "model": "deepseek-r1-distill-llama-70b",
        "temperature": 0.2,
        "max_tokens": 2048,
    }
    agent = WritingAgent(cfg)
    dummy_context = {
        "process_description": "Example process...",
        "specification": "Example spec...",
        "stability_report": "Example stability...",
    }
    try:
        out = agent.generate_section_content(
            molecule="Paracetamol",
            region="India",
            context=dummy_context,
            vectorstore_path="./vectorstore/paracetamol_india_docs",
            section_name="2.3.S.4 Control of Drug Substance",
        )
        print(out.get("status"), len(out.get("generated_content", "")))
    except Exception as e:
        print("Test run error:", e)
