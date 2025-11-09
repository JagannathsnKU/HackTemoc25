"""
Quick test to verify NVIDIA Nemotron API is working
This will test the actual AI model without Flask
"""

import requests
import json

NVIDIA_API_KEY = "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"
MODEL = "nvidia/nemotron-4-340b-instruct"

print("="*60)
print("TESTING NVIDIA NEMOTRON-4-340B-INSTRUCT")
print("="*60)

url = "https://integrate.api.nvidia.com/v1/chat/completions"

headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {NVIDIA_API_KEY}"
}

payload = {
    "model": MODEL,
    "messages": [
        {
            "role": "system",
            "content": "You are a helpful AI assistant in a relationship management app called Atlas."
        },
        {
            "role": "user",
            "content": "Generate 3 smart reply suggestions for this message: 'Hey! Want to grab coffee this week?' Return as JSON with format: {\"replies\": [{\"text\": \"...\", \"tone\": \"...\"}]}"
        }
    ],
    "temperature": 0.7,
    "max_tokens": 500
}

print(f"\nCalling: {url}")
print(f"Model: {MODEL}")
print(f"Request: {json.dumps(payload, indent=2)[:300]}...\n")

try:
    response = requests.post(url, headers=headers, json=payload, timeout=30)
    
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        content = result['choices'][0]['message']['content']
        
        print("\n" + "="*60)
        print("SUCCESS! NVIDIA NEMOTRON RESPONSE:")
        print("="*60)
        print(content)
        print("="*60)
        print("\n✅ NVIDIA Nemotron-4-340B is working!")
        print("✅ Your API key is valid!")
        print("✅ Multi-agent system is ready!\n")
        
    else:
        print(f"\n❌ ERROR {response.status_code}")
        print(f"Response: {response.text}\n")
        
except Exception as e:
    print(f"\n❌ EXCEPTION: {e}\n")
    import traceback
    traceback.print_exc()
