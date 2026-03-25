import asyncio
import traceback
import os
import logging
from dotenv import load_dotenv

from videosdk.agents import Agent, AgentSession, RealTimePipeline, JobContext, RoomOptions, WorkerJob, Options
from videosdk.plugins.openai import OpenAIRealtime, OpenAIRealtimeConfig

logging.basicConfig(level=logging.INFO)
# Use absolute path for .env
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(BASE_DIR, ".env"))

def load_rag_context() -> str:
    """Reads the local database from .txt for RAG using absolute path."""
    db_path = os.path.join(BASE_DIR, "insurance_data.txt")
    if not os.path.exists(db_path):
        logging.warning(f"DATABASE NOT FOUND at {db_path}!")
        return "No database found."
        
    try:
        with open(db_path, "r") as f:
            content = f.read()
            logging.info(f"Loaded database context ({len(content)} characters).")
            return content
    except Exception as e:
        logging.error(f"Error reading database: {e}")
        return "No database found."

class MyVoiceAgent(Agent):
    def __init__(self, greeting_message: str, rag_context: str):
        instructions = f"""You are a professional assistant for XYZ Insurance.

YOUR ROLE & RULES:
1. LANGUAGE: Start the conversation in HINDI. 
2. DYNAMIC SWITCHING: Always respond in the SAME language as the customer. If they speak English, you speak English. If they switch back to Hindi, you switch back to Hindi immediately.
3. MATURITY NOTIFICATION: Mention the Maturity Amount of 5,00,000 INR early in the greeting.
4. Be polite, friendly, and very concise (1 sentence answers).
5. Answer user questions ONLY by fetching facts from the DATABASE CONTEXT below.
6. If the user asks something NOT in the database, say: "Sorry, you can call the office regarding this." in their active language.
7. SAFETY: Never mention competitor insurance companies. 
8. ENDING THE CALL: If the user says "bye" or "thank you", reply with: "Thank you, goodbye!" (in English) OR "धन्यवाद, अलविदा!" (in Hindi) and then STOP. This phrase is a trigger to end the call.

DATABASE CONTEXT:
{rag_context}
"""
        super().__init__(instructions=instructions)
        self.greeting_message = greeting_message

    async def on_enter(self) -> None:
        logging.info(f"Agent {self.id} entered. Waiting for pipeline to stabilize...")
        await asyncio.sleep(1.0) # Small delay to ensure STT/TTS are ready
        try:
            logging.info(f"Sending greeting: {self.greeting_message}")
            await self.session.say(self.greeting_message)
            logging.info("Greeting sent successfully.")
        except Exception as e:
            logging.error(f"Error in greeting: {e}")

    async def on_exit(self) -> None:
        logging.info(f"Agent {self.id} is exiting the room.")

def generate_dynamic_greeting(rag_context: str) -> str:
    """Parses the first customer in the context for a personalized greeting."""
    lines = rag_context.strip().split("\n")
    data = {}
    for line in lines:
        if ":" in line:
            parts = line.split(":", 1)
            data[parts[0].strip()] = parts[1].strip()
    
    name = data.get("Customer", "Customer")
    amount = data.get("Maturity Amount", "your maturity amount")
    policy = data.get("Policy ID", "your policy")
    
    return f"नमस्ते {name}, आपकी बीमा पॉलिसी {policy} आज परिपक्व (mature) हो गई है और आपकी परिपक्वता राशि (maturity amount) {amount} है। क्या आपके पास कोई प्रश्न हैं?"

async def start_session(context: JobContext):
    db_text = load_rag_context()
    greeting = generate_dynamic_greeting(db_text)

    # We will use the pure, standard OpenAI API directly now 
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        logging.error("CRITICAL: OPENAI_API_KEY is missing from environment!")
        return
    logging.info(f"API Key found (starts with: {api_key[:10]}...)")

    # Switch to the unified Realtime Model (STT + LLM + TTS in one)
    # This is much faster and more stable than the cascading approach
    try:
        model = OpenAIRealtime(
            model="gpt-4o-realtime-preview",
            api_key=api_key,
            config=OpenAIRealtimeConfig(voice="alloy")
        )
    except Exception as e:
        logging.error(f"Failed to init OpenAIRealtime: {e}")
        # Final fallback if config/model parameters differ in this version
        model = OpenAIRealtime(model="gpt-4o-realtime-preview", api_key=api_key)

    pipeline = RealTimePipeline(model=model)
    session = AgentSession(agent=MyVoiceAgent(greeting, db_text), pipeline=pipeline)

    try:
        logging.info("Connecting to VideoSDK room...")
        await context.connect()
        logging.info("Connected. Starting agent session...")
        
        # Auto-Hangup Logic: Listen for the "Goodbye" phrase from the agent
        # Note: VideoSDK Event handlers MUST be synchronous. 
        # We use asyncio.create_task to bridge to the async shutdown.
        async def delayed_shutdown():
            await asyncio.sleep(5)
            logging.info("Closing call now.")
            await context.shutdown()

        def handle_goodbye(data):
            text = data.get("text", "").lower()
            if "goodbye" in text or "अलविदा" in text:
                logging.info(f"Goodbye detected: '{text}'. Closing call in 5 seconds...")
                asyncio.create_task(delayed_shutdown())
        
        session.on("speech_out", handle_goodbye)

        await session.start()
        logging.info("Session started. Waiting for events...")
        await asyncio.Event().wait()
    except Exception as e:
        if "CancelledError" not in str(e):
            logging.error(f"Session error: {e}")
            traceback.print_exc()
    finally:
        try:
            await session.close()
        except Exception as e:
            logging.debug(f"Session close ignore: {e}")
        await context.shutdown()

def make_context() -> JobContext:
    return JobContext(room_options=RoomOptions())

if __name__ == "__main__":
    try:
        options = Options(
            agent_id="my-telephony-agent",
            register=True,
            max_processes=10,
            host="localhost",
            port=8081,
        )
        print("Starting VideoSDK AI Agent worker...")
        job = WorkerJob(entrypoint=start_session, jobctx=make_context, options=options)
        job.start()
    except Exception as e:
        traceback.print_exc()
