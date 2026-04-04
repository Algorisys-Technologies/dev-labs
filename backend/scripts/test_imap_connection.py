import imaplib
import os
from dotenv import load_dotenv

# Load credentials from .env
load_dotenv()

IMAP_SERVER = os.getenv("IMAP_SERVER", "imap.gmail.com")
EMAIL_ACCOUNT = os.getenv("IMAP_EMAIL_ACCOUNT", "")
APP_PASSWORD = os.getenv("IMAP_APP_PASSWORD", "")

def test_connection():
    print("\n" + "="*40)
    print("📧 IMAP CONNECTION TESTER")
    print("="*40)
    
    if not EMAIL_ACCOUNT or not APP_PASSWORD:
        print("❌ ERROR: Missing credentials in .env file.")
        print("Please ensure you have created a '.env' file with:")
        print("IMAP_EMAIL_ACCOUNT=your-email@gmail.com")
        print("IMAP_APP_PASSWORD=xxxx-xxxx-xxxx-xxxx")
        return

    print(f"🔗 Attempting to connect to: {IMAP_SERVER}")
    print(f"👤 Using Account: {EMAIL_ACCOUNT}")
    
    try:
        # 1. Connect
        mail = imaplib.IMAP4_SSL(IMAP_SERVER)
        print("✅ Server Connection Successful.")
        
        # 2. Login
        print("🔑 Attempting Login...")
        mail.login(EMAIL_ACCOUNT, APP_PASSWORD)
        print("✅ LOGIN SUCCESSFUL!")
        
        # 3. List Inboxes
        status, folders = mail.list()
        if status == "OK":
            print(f"📬 Successfully accessed inbox. Found {len(folders)} folders.")
            
        mail.logout()
        print("\n" + "═"*40)
        print("✨ Connection test PASSED!")
        print("═"*40)
        
    except imaplib.IMAP4.error as e:
        print(f"\n❌ LOGIN FAILED: {e}")
        print("\nPossible issues:")
        print("1. Incorrect Password (use a 16-digit App Password for Gmail).")
        print("2. IMAP is not enabled in your Email Settings.")
        print("3. Less Secure Apps access is blocked.")
    except Exception as e:
        print(f"\n❌ UNEXPECTED ERROR: {e}")

if __name__ == "__main__":
    test_connection()
