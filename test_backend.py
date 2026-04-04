import requests
import json
import time
import subprocess
import os

def test_flow():
    # 1. Start backend process
    print("Starting backend...")
    backend_process = subprocess.Popen(
        [".venv/Scripts/python", "-m", "uvicorn", "backend.main:app", "--port", "8000"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Wait for backend to start
    time.sleep(5)
    
    try:
        # 2. Test /process-email
        print("Testing /process-email...")
        payload = {
            "subject": "New Order Test",
            "body": """Dear Sir,
            Please process PO-TEST-999.
            Item: Brake Pad Assembly
            Quantity: 150
            Location: A10 Manufacturing Plant, Pune
            """
        }
        
        response = requests.post("http://localhost:8000/process-email", json=payload)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            print("Successfully processed email!")
            
        # 3. Test /orders
        print("Testing /orders...")
        response = requests.get("http://localhost:8000/orders")
        print(f"Status Code: {response.status_code}")
        print(f"Orders count: {len(response.json())}")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        print("Stopping backend...")
        backend_process.terminate()

if __name__ == "__main__":
    test_flow()
