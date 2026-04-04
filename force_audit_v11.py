import imaplib
import email
from email.header import decode_header
import os
from dotenv import load_dotenv
from sqlmodel import Session, create_engine, select
import sys

# Add the current directory to the system path to allow imports
sys.path.append(os.getcwd())

from backend.models import Order
from backend.extractor import extract_po_details

load_dotenv()

IMAP_SERVER = os.getenv("IMAP_SERVER", "imap.gmail.com")
EMAIL_ACCOUNT = os.getenv("IMAP_EMAIL_ACCOUNT", "")
APP_PASSWORD = os.getenv("IMAP_APP_PASSWORD", "")
DATABASE_URL = "sqlite:///./backend/orders.db"
engine = create_engine(DATABASE_URL)

def force_audit():
    print("="*60)
    print("🚀 MASTER SIGNAL AUDIT (v11.1)")
    print("="*60)

    # 1. Check Database
    try:
        with Session(engine) as session:
            count = session.exec(select(Order)).all()
            print(f"📊 DATABASE COUNT: {len(count)} records found.")
            if count:
                for o in count[-2:]:
                    print(f"   [DB RECORD]: ID={o.id} | PO={o.po_number} | CAT={o.category} | LOC={o.location}")
    except Exception as e:
        print(f"❌ DB ERROR: {e}")

    # 2. Check Inbox
    try:
        mail = imaplib.IMAP4_SSL(IMAP_SERVER)
        mail.login(EMAIL_ACCOUNT, APP_PASSWORD)
        mail.select("inbox")
        
        status, messages = mail.search(None, 'ALL')
        mail_ids = messages[0].split()
        if not mail_ids:
            print("📭 INBOX EMPTY: No signals found in history.")
            return

        last_id = mail_ids[-1]
        res, data = mail.fetch(last_id, '(RFC822)')
        msg = email.message_from_bytes(data[0][1])
        
        subject, encoding = decode_header(msg["Subject"])[0]
        if isinstance(subject, bytes):
            subject = subject.decode(encoding if encoding else 'utf-8', errors='replace')
        
        body = ""
        if msg.is_multipart():
            for part in msg.walk():
                if part.get_content_type() == "text/plain":
                    body = part.get_payload(decode=True).decode(errors='replace')
                    break
        else:
            body = msg.get_payload(decode=True).decode(errors='replace')
        
        print(f"\n📡 LATEST SIGNAL IN INBOX:")
        print(f"   [SUBJECT]: {subject}")
        print(f"   [BODY (First 200 chars)]:\n{body[:200]}...")
        
        # 3. Test Extraction on this Signal
        print(f"\n🛠️  AI EXTRACTION TEST ON LATEST SIGNAL:")
        extraction = extract_po_details(f"{subject}\n\n{body}")
        print(f"   [RESULT]: PO Number = {extraction['po_number']}")
        print(f"   [RESULT]: Items = {extraction['item_name']} (Qty: {extraction['quantity']})")
        print(f"   [RESULT]: Location = {extraction['location']}")
        
        if extraction['po_number'] == "UNKNOWN":
            print("\n❌ CRITICAL: The AI still cannot see the PO Number in this email.")
            print("   Please send an email with 'PO Number: DIS-EV-4422' to test.")
        else:
            print("\n✅ SUCCESS: Extraction is working. If the UI is empty, please REFRESH your browser.")
            
        mail.logout()
    except Exception as e:
        print(f"❌ IMAP ERROR: {e}")

if __name__ == "__main__":
    force_audit()
