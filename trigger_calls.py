import os
import json
import requests
from datetime import datetime
from pathlib import Path
from dotenv import load_dotenv

# Use absolute path for resources
BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

# We need the token and gateway ID from your VideoSDK Dashboard
VIDEOSDK_AUTH_TOKEN = os.getenv("VIDEOSDK_AUTH_TOKEN")
GATEWAY_ID = os.getenv("VIDEOSDK_OUTBOUND_GATEWAY_ID")
LOG_FILE = BASE_DIR / "call_log.json"
DB_FILE = BASE_DIR / "insurance_data.txt"

def load_call_log():
    if LOG_FILE.exists():
        with open(LOG_FILE, "r") as f:
            return json.load(f)
    return {}

def save_call_log(log_data):
    with open(LOG_FILE, "w") as f:
        json.dump(log_data, f, indent=4)

def parse_txt_db():
    users = []
    current_user = {}
    
    if not DB_FILE.exists():
        print(f"ERROR: Database file not found at {DB_FILE}")
        return []

    with open(DB_FILE, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                if current_user:
                    users.append(current_user)
                    current_user = {}
                continue
            
            # Robust split: only on the FIRST colon to allow addresses with colons
            if ":" in line:
                parts = line.split(":", 1)
                if len(parts) == 2:
                    current_user[parts[0].strip()] = parts[1].strip()
                
    if current_user:
        users.append(current_user)
        
    return users

def run_daily_check():
    today_str = datetime.now().strftime("%Y-%m-%d")
    print(f"--- Production Daily Check: {today_str} ---")
    
    call_log = load_call_log()
    users = parse_txt_db()
    
    calls_made_this_run = 0

    for user_data in users:
        policy_id = user_data.get("Policy ID", "UNKNOWN")
        phone = user_data.get("Phone")
        
        # 1. Maturity Check
        if user_data.get("Maturity Date") != today_str:
            continue
            
        # 2. State Tracking Check (Prevent Duplicate Calls)
        if policy_id in call_log and call_log[policy_id] == today_str:
            print(f"Skipping {user_data.get('Customer')} ({policy_id}) - Already called today.")
            continue
            
        print(f"Match found! Triggering outbound call to {user_data.get('Customer')} at {phone}...")
        
        # Using the official VideoSDK Outbound API
        url = "https://api.videosdk.live/v2/sip/call"
        headers = {
            "Authorization": VIDEOSDK_AUTH_TOKEN,
            "Content-Type": "application/json"
        }
        payload = {
            "gatewayId": GATEWAY_ID,
            "sipCallTo": phone
        }
        
        try:
            response = requests.post(url, json=payload, headers=headers, timeout=10)
            if response.status_code in [200, 201]:
                print(f"Success! Agent is now dialing {policy_id}.")
                # Mark as called in the state tracker
                call_log[policy_id] = today_str
                calls_made_this_run += 1
            else:
                print(f"Failed to initiate call for {policy_id}. Status: {response.status_code}")
        except Exception as e:
            print(f"Error making request: {e}")

    if calls_made_this_run > 0:
        save_call_log(call_log)
    else:
        print("No new calls were required today.")

if __name__ == "__main__":
    run_daily_check()
