# writing_agent.py
import os
from typing import Dict, List
from dotenv import load_dotenv

from logger.custom_logger import CustomLogger
from exception.custom_exception import CustomException

# LangChain
from langchain_groq import ChatGroq
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain.chains import RetrievalQA

# Modular imports
from utils.writing_utils import (
    load_vectorstore,
    citations_from_sources,
    extract_detailed_citations,
)
from src.prompts.writing_prompt import compose_writing_question, make_writing_prompt

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
            vectorstore = load_vectorstore(vectorstore_path, self.embeddings)
            retriever = vectorstore.as_retriever(search_kwargs={"k": 6})

            # Compose one strong question string; RetrievalQA expects input key 'query'
            question = compose_writing_question(molecule, region, section_name, context)

            # Prompt for the combine_docs phase (stuff chain)
            prompt = make_writing_prompt()

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

            citations = citations_from_sources(source_docs)
            # Fallback: also parse inline [1], [2] if present
            if not citations:
                citations = extract_detailed_citations(answer)

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
