import requests
import json
import time

# Replace with your VM's External IP
IP_ADDRESS = "34.50.146.233" 
URL = f"http://{IP_ADDRESS}/generate_sql"

payload = {
    "user_api_key": "test-key-123",
    "user_query": "Find the total sales amount per customer for the last 6 months.",
    "table_schema": {
        "customers": ["customer_id", "first_name", "last_name", "email"],
        "orders": ["order_id", "customer_id", "order_date", "total_amount"],
        "order_items": ["order_item_id", "order_id", "product_id", "quantity", "unit_price"],
        "products": ["product_id", "product_name", "category", "price"],
        "payments": ["payment_id", "order_id", "payment_date", "amount"]
    }
}

print(f"Sending POST request to {URL}...")
try:
    start_time = time.time()
    response = requests.post(URL, json=payload, timeout=30)
    latency = time.time() - start_time
    
    print(f"Status Code: {response.status_code}")
    print(f"Time: {latency:.2f}s")
    
    if response.status_code == 200:
        print("Response JSON:")
        print(json.dumps(response.json(), indent=2))
    else:
        print("Error Response:")
        print(response.text)
        
except Exception as e:
    print(f"Request failed: {e}")
