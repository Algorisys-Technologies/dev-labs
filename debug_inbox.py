import imaplib
import email
from email.header import decode_header
import os
from dotenv import load_dotenv

load_dotenv()

IMAP_SERVER = os.getenv("IMAP_SERVER", "imap.gmail.com")
EMAIL_ACCOUNT = os.getenv("IMAP_EMAIL_ACCOUNT", "")
APP_PASSWORD = os.getenv("IMAP_APP_PASSWORD", "")

def debug_inbox():
    try:
        mail = imaplib.IMAP4_SSL(IMAP_SERVER)
        mail.login(EMAIL_ACCOUNT, APP_PASSWORD)
        mail.select("inbox")
        
        status, messages = mail.search(None, 'ALL')
        mail_ids = messages[0].split()
        last_3 = mail_ids[-3:] if len(mail_ids) > 3 else mail_ids
        
        print(f"--- DEBUGGING INBOX (Total: {len(mail_ids)}) ---")
        for mid in reversed(last_3):
            status, data = mail.fetch(mid, '(RFC822)')
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
            
            print(f"\n[SUBJECT]: {subject}")
            print(f"[BODY PREVIEW]:\n{body[:400]}...")
            print("-" * 40)
        
        mail.logout()
    except Exception as e:
        print(f"IMAP Error: {e}")

if __name__ == "__main__":
    debug_inbox()
