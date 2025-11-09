import requests
import json

url = "http://localhost:5000/agent/smart_reply"
data = {
    "contact_name": "James",
    "last_message": "Hit me up when you can!",
    "conversation_history": "James: Hey man! Long time\nJames: Remember that Web3 project?",
    "user_name": "Heet"
}

print("🔵 Sending request to:", url)
print("📤 Data:", json.dumps(data, indent=2))

try:
    response = requests.post(url, json=data, headers={"Content-Type": "application/json"})
    print(f"\n✅ Status: {response.status_code}")
    print(f"📥 Response: {response.text}")
except Exception as e:
    print(f"❌ Error: {e}")
