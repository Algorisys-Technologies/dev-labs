import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
from dotenv import load_dotenv
import time

load_dotenv()

SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
EMAIL_ACCOUNT = os.getenv("IMAP_EMAIL_ACCOUNT")
APP_PASSWORD = os.getenv("IMAP_APP_PASSWORD")

def send_email(subject, body, subtype="plain"):
    msg = MIMEMultipart()
    msg['From'] = EMAIL_ACCOUNT
    msg['To'] = EMAIL_ACCOUNT
    msg['Subject'] = subject
    
    msg.attach(MIMEText(body, subtype))
    
    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(EMAIL_ACCOUNT, APP_PASSWORD)
        server.send_message(msg)
        server.quit()
        print(f"Sent: {subject}")
    except Exception as e:
        print(f"Error sending {subject}: {e}")

# COMPLEX PO 1: MANUFACTURING (Tabular-ish Plain Text)
po_mfg = """
Purchase Order: ET-MF-99012
Date: 2026-04-10
Vendor: Evolute Precision Systems

---------------------------------------------------------
| Item Code | Description              | Qty | Location  |
---------------------------------------------------------
| EV-BMS-01 | Lithium-Ion BMS Board-A1 | 500 | Factory-7 |
| EV-CAS-02 | Plastic Battery Casing   | 1000| Factory-7 |
---------------------------------------------------------

Delivery Instructions: 
Please deliver to Sector 18, MIDC, Electronics Zone, Mumbai.
Special Note: High priority for EV infrastructure project.
"""

# COMPLEX PO 2: TRADING (Dashed Table)
po_trading = """
Ref No: HT-PO-TR-667
Order Date: April 5, 2026

Attention: Sales Dept
We are pleased to place an order for the following:

Product: X-Factor Solar Inverters (10KW)
Quantity: 12 Units
Price per Unit: $850.00
-----------------------------------------
Total Amount: $10,200.00
-----------------------------------------

Shipping Address:
Distribution Hub Alpha, Greater Noida, UP - 201301
Contact person: Rajesh Kumar (9876543210)
"""

# COMPLEX PO 3: DISTRIBUTION (Natural Language mix)
po_dist = """
Order No: DIS-EV-4422
Date: 02/04/2026

Subject: Urgent Stock Replenishment for Southern Region

Hello Team,
This is an official purchase request for 2500 units of "EV-QuickCharge-05" (Fast Chargers).
The shipment should be dispatched to our Chennai Regional Warehouse (SR-04).

Billing Address: Evolute Group North, Delhi.
Shipping Address: Plot 44, Industrial Estate, Guindy, Chennai.

Regards,
Inventory Manager
"""

if __name__ == "__main__":
    if not EMAIL_ACCOUNT or not APP_PASSWORD:
        print("Missing credentials in .env")
    else:
        print("Sending Complex Demo Emails...")
        send_email("NEW ORDER: Manufacturing PO #ET-MF-99012", po_mfg)
        time.sleep(2)
        send_email("Purchase Request: HT-PO-TR-667", po_trading)
        time.sleep(2)
        send_email("Distribution Order DIS-EV-4422 - URGENT", po_dist)
        print("Done!")
