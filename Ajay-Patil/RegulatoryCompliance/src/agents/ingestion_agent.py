import os
from langchain_groq import ChatGroq
from langchain.output_parsers import StructuredOutputParser, ResponseSchema
from src.prompts.ingestion_prompt import INGESTION_PROMPT
from logger.custom_logger import CustomLogger
from exception.custom_exception import CustomException
from langchain_core.messages import HumanMessage
from dotenv import load_dotenv
load_dotenv()
logger = CustomLogger().get_logger(__name__)

class IngestionAgent:
    def __init__(self, llm_config):
        try:
            api_key = os.getenv("GROQ_API_KEY")
            self.llm = ChatGroq(
                model_name=llm_config["groq"]["model_name"],
                temperature=llm_config["groq"]["temperature"],
                max_tokens=llm_config["groq"]["max_output_tokens"],
                api_key=api_key,
            )
            
            response_schemas = [
                ResponseSchema(name="molecule", description="Name of the molecule"),
                ResponseSchema(name="region", description="Region e.g., India"),
                ResponseSchema(
                    name="context",
                    description="Contains cleaned process_description, specification, stability_report"
                ),
            ]
            self.output_parser = StructuredOutputParser.from_response_schemas(response_schemas)

            logger.info("IngestionAgent initialized successfully")

        except Exception as e:
            logger.error("Failed to initialize IngestionAgent")
            raise CustomException("Failed to initialize IngestionAgent", e)

    def run(self, molecule, region, process_description, specification, stability_report):
        try:
            logger.info(f"Running ingestion for molecule={molecule}, region={region}")
            
            # Format the prompt with variables
            prompt_text = INGESTION_PROMPT.format(
                molecule=molecule,
                region=region,
                process_description=process_description,
                specification=specification,
                stability_report=stability_report,
            )
            
            # Create a proper chat message
            message = HumanMessage(content=prompt_text)
            
            # Use invoke() instead of __call__ as suggested by the deprecation warning
            response = self.llm.invoke([message])
            
            parsed_output = self.output_parser.parse(response.content)

            logger.info("Ingestion successful")
            return parsed_output

        except Exception as e:
            logger.error("Ingestion failed")
            raise CustomException("Error in ingestion pipeline", e)
