# writing_utils.py
import os
import re
from typing import Dict, List

from logger.custom_logger import CustomLogger
from exception.custom_exception import CustomException
from langchain_community.vectorstores import FAISS, Chroma

logger = CustomLogger().get_logger(__name__)

# -------------------
# Regulatory standards
# -------------------
def get_regulatory_standards(region: str) -> str:
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
# Vectorstore loading
# -------------------
def load_vectorstore(vectorstore_path: str, embeddings):
    """
    Load a FAISS or Chroma vectorstore from disk.
    Behavior matches your original _load_vectorstore (kept intact).
    """
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
            vectorstore_path, embeddings, allow_dangerous_deserialization=True
        )
    if is_chroma:
        return Chroma(persist_directory=vectorstore_path, embedding_function=embeddings)

    # Fallback attempts (unchanged)
    try:
        return FAISS.load_local(
            vectorstore_path, embeddings, allow_dangerous_deserialization=True
        )
    except Exception as e1:
        try:
            return Chroma(persist_directory=vectorstore_path, embedding_function=embeddings)
        except Exception as e2:
            raise Exception(f"Cannot load vectorstore. FAISS error: {e1}; Chroma error: {e2}")


# -------------------
# Citation utilities
# -------------------
def identify_document_type(text: str) -> str:
    tl = (text or "").lower()
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


def extract_citation_context(text: str) -> str:
    tl = (text or "").lower()
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


def citations_from_sources(source_docs) -> List[Dict]:
    citations: List[Dict] = []
    for i, doc in enumerate(source_docs or [], start=1):
        meta = getattr(doc, "metadata", {}) or {}
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
            "document_type": identify_document_type(title or ""),
            "context": meta.get("summary") or meta.get("snippet") or "Retrieved source",
        })
    return citations


def extract_detailed_citations(content: str) -> List[Dict]:
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
            "document_type": identify_document_type(citation_text),
            "context": extract_citation_context(citation_text),
        })
    return citations