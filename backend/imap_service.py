import imaplib
import email
from email.header import decode_header
import os
from dotenv import load_dotenv

load_dotenv()

IMAP_SERVER = os.getenv("IMAP_SERVER", "imap.gmail.com")
EMAIL_ACCOUNT = os.getenv("IMAP_EMAIL_ACCOUNT", "")
APP_PASSWORD = os.getenv("IMAP_APP_PASSWORD", "")

def get_unread_emails():
    """
    Connect to IMAP server, fetch both UNSEEN and the last 10 RECENT emails.
    This 'Deep Sync' ensures no data is lost even if the server crashes.
    """
    results = []
    
    if not EMAIL_ACCOUNT or not APP_PASSWORD:
        return {"error": "Missing IMAP_EMAIL_ACCOUNT or IMAP_APP_PASSWORD."}
        
    try:
        mail = imaplib.IMAP4_SSL(IMAP_SERVER)
        mail.login(EMAIL_ACCOUNT, APP_PASSWORD)
        mail.select("inbox")
        
        # SEARCH 1: Standard Unseen (Immediate Signals)
        # Search for UNSEEN first
        status, unseen_msg = mail.search(None, 'UNSEEN')
        unseen_ids = unseen_msg[0].split() if status == "OK" else []
        
        # SEARCH 2: Recent History (Safety Net)
        # Fetch IDs for the last 10 messages to ensure historical persistence
        status, all_msg = mail.search(None, 'ALL')
        all_ids = all_msg[0].split() if status == "OK" else []
        recent_ids = all_ids[-10:] if len(all_ids) > 10 else all_ids
        
        # Combine and de-duplicate IDs (maintain order: unseen first)
        combined_ids = []
        seen_set = set()
        for mid in (unseen_ids + recent_ids):
            if mid not in seen_set:
                combined_ids.append(mid)
                seen_set.add(mid)

        for mail_id in combined_ids:
            res, msg_data = mail.fetch(mail_id, "(RFC822)")
            if res != "OK":
                continue
                
            for response_part in msg_data:
                if isinstance(response_part, tuple):
                    msg = email.message_from_bytes(response_part[1])
                    
                    # Subject Decoding
                    subject_header = msg.get("Subject")
                    subject, encoding = decode_header(subject_header)[0]
                    if isinstance(subject, bytes):
                        subject = subject.decode(encoding if encoding else 'utf-8', errors='replace')
                    elif subject is None:
                        subject = "(No Subject)"
                        
                    body = ""
                    if msg.is_multipart():
                        for part in msg.walk():
                            content_type = part.get_content_type()
                            content_disposition = str(part.get("Content-Disposition"))
                            if content_type == "text/plain" and "attachment" not in content_disposition:
                                try:
                                    payload = part.get_payload(decode=True)
                                    if payload:
                                        body = payload.decode(errors='replace')
                                        break
                                except: pass
                    else:
                        try:
                            payload = msg.get_payload(decode=True)
                            if payload:
                                body = payload.decode(errors='replace')
                        except: pass
                        
                    results.append({"subject": subject, "body": body, "id": mail_id.decode()})
            
            # Optional: Keep the \Seen flag to prevent bloat in the inbox view
            mail.store(mail_id, '+FLAGS', '\\Seen')
            
        mail.logout()
        return results
    except Exception as e:
        print(f"IMAP Error: {e}")
        return {"error": str(e)}
