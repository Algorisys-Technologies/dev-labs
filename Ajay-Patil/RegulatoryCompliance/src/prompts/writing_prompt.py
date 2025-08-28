# writing_prompt.py
from typing import Dict
from langchain.prompts import PromptTemplate
from utils.writing_utils import get_regulatory_standards

def compose_writing_question(
    molecule: str, region: str, section_name: str, context: Dict
) -> str:
    """
    Matches original _compose_question behavior, but now modular.
    """
    return (
        f"Generate comprehensive, compliant content for CTD section '{section_name}' "
        f"for molecule '{molecule}' in region '{region}'.\n\n"
        f"CONTEXT:\n"
        f"- Process Description: {context.get('process_description','')}\n"
        f"- Specification: {context.get('specification','')}\n"
        f"- Stability Report: {context.get('stability_report','')}\n\n"
        f"Regulatory standards to follow: {get_regulatory_standards(region)}\n\n"
        "Requirements:\n"
        "1) Ground the answer in retrieved regulatory documents from the region.\n"
        "2) Include citations like [1], [2] with document/section/version where possible.\n"
        "3) Use professional regulatory tone; add bullet points/tables where relevant.\n"
    )


def make_writing_prompt() -> PromptTemplate:
    """
    Matches original _make_prompt behavior, but now modular.
    For a RetrievalQA 'stuff' chain, variables are typically {context} and {question}.
    """
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
    return PromptTemplate(template=template, input_variables=["context", "question"])
