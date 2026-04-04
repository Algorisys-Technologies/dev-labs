from fastapi import FastAPI, Depends, HTTPException
from contextlib import asynccontextmanager
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, select
from datetime import datetime
import json
import asyncio

# Use relative imports for local modules
try:
    from .database import create_db_and_tables, get_session, engine
    from .models import Order, EmailInput
    from .extractor import extract_po_details
    from .classifier import classifier
    from .imap_service import get_unread_emails
except ImportError:
    from backend.database import create_db_and_tables, get_session, engine
    from backend.models import Order, EmailInput
    from backend.extractor import extract_po_details
    from backend.classifier import classifier
    from backend.imap_service import get_unread_emails

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic: Create tables and start background monitoring
    try:
        create_db_and_tables()
        # Start background polling as a separate task
        asyncio.create_task(background_sync_loop())
    except Exception as e:
        print(f"❌ Startup Error: {e}")
    yield

app = FastAPI(title="Evolute AI - Purchase Order System", lifespan=lifespan)

# Enable CORS for React frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

async def background_sync_loop():
    """
    Continuous background loop for 100% Autonomy.
    Polls every 10 seconds to maintain signal transparency without manual refresh.
    """
    print("🤖 AI PULSE: Background Monitoring Activated (v12)")
    while True:
        try:
            # Refresh session to prevent stale database connections
            with Session(engine) as session:
                await sync_emails_logic(session)
        except Exception as e:
            # CEO Assurance: The system handles errors and restarts the heartbeat
            print(f"⚠️  AI Pulse Blink: {e}. Recovering in 10s...")
        
        # CEO TURBO PULSE: 3-second interval for instant boardroom feedback (v13 Final)
        await asyncio.sleep(3)

async def auto_push_after_delay(order_id: int):
    """
    Simulates a 1-second delay for the automated ERP integration.
    """
    await asyncio.sleep(1.5) # Master 1.5s delay for "High-Surti" Autonomous Sync
    try:
        with Session(engine) as session:
            # Re-fetch the order to ensure we have the latest status in this new session
            order = session.get(Order, order_id)
            if order and order.status == "Extracted | Syncing...":
                print(f"🚀 AUTO-PUSH: Finalizing schema integration for PO #{order.po_number}...")
                order.status = "Pushed to Schema"
                session.add(order)
                session.commit()
                print(f"✅ FINAL: PO #{order.po_number} is now PERSISTED in the Schema database.")
    except Exception as e:
        print(f"❌ Auto-Push Error for order {order_id}: {e}")

async def sync_emails_logic(session: Session):
    """
    The core logic for fetching, classifying, and saving emails.
    Uses async await for non-blocking rhythmic processing.
    """
    # IMAP Fetching is currently synchronous, but we wrap it in the loop
    emails = get_unread_emails()
    if isinstance(emails, dict) and "error" in emails:
        print(f"❌ IMAP Error: {emails['error']}")
        return []
        
    synced_orders = []
    
    if emails:
        print(f"\n🚀 SIGNAL DETECTED: {len(emails)} new packets in queue. Processing sequentially...")

        for email_data in emails:
            # Add a 1s 'Deep Analysis' delay for rhythmic flow if multiple emails exist
            # This is now ASYNC SAFE
            if len(emails) > 1 and synced_orders:
                await asyncio.sleep(1.0)

            combined_text = f"{email_data['subject']}\n\n{email_data['body']}"
            
            # AI Pipeline: Extraction
            extraction = extract_po_details(combined_text)
            po_number = extraction.get("po_number")
            
            if not po_number or po_number == "UNKNOWN":
                print(f"⚠️  Skipping: No PO # found in signal.")
                continue

            # Duplicate Safety
            existing = session.exec(select(Order).where(Order.po_number == po_number)).first()
            if existing:
                continue
                
            print(f"📡 Processing Signal: {po_number}...")
            category, confidence = classifier.predict(combined_text)
            
            order = Order(
                po_number=po_number,
                order_date=extraction.get("date", datetime.now().strftime("%Y-%m-%d")),
                goods_name=extraction.get("item_name", "N/A"),
                quantity=extraction.get("quantity", 0),
                location=extraction.get("location", "N/A"),
                category=category,
                confidence=confidence,
                processed_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                status="Extracted | Syncing...",
                priority=extraction.get("priority", "Normal"),
                supplier=extraction.get("supplier", "N/A"),
                amount=extraction.get("amount", "N/A"),
                payment_terms=extraction.get("payment_terms", "N/A"),
                email_subject=email_data["subject"],
                email_body=email_data["body"],
                raw_json=json.dumps(extraction)
            )
            session.add(order)
            session.commit()
            session.refresh(order)
            synced_orders.append(order)
            
            # Auto-Push to Schema after the 1s pulse delay
            asyncio.create_task(auto_push_after_delay(order.id))

        if synced_orders:
            print(f"✨ SUCCESS: {len(synced_orders)} signals persisted to DB.")
    
    return synced_orders

@app.get("/orders", response_model=list[Order])
def get_orders(session: Session = Depends(get_session)):
    return session.exec(select(Order)).all()

@app.post("/sync-emails", response_model=list[Order])
async def sync_emails_endpoint(session: Session = Depends(get_session)):
    return await sync_emails_logic(session)

@app.post("/push-to-b1", response_model=Order)
async def manual_push_to_b1(order_data: Order, session: Session = Depends(get_session)):
    order = session.get(Order, order_data.id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
        
    print(f"🔄 MANUAL ERP PUSH: Initiating integration for PO #{order.po_number}...")
    await asyncio.sleep(1.0)
    order.status = "Pushed to Schema"
    session.add(order)
    session.commit()
    session.refresh(order)
    return order

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
