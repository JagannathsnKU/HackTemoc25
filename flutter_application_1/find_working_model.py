"""
Test different NVIDIA models to find which one works
"""

import requests
import json

NVIDIA_API_KEY = "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"

# Try different model names and endpoints
models_to_test = [
    ("meta/llama-3.1-8b-instruct", "https://integrate.api.nvidia.com/v1/chat/completions"),
    ("meta/llama-3.1-70b-instruct", "https://integrate.api.nvidia.com/v1/chat/completions"),
    ("nvidia/llama-3.1-nemotron-70b-instruct", "https://integrate.api.nvidia.com/v1/chat/completions"),
    ("meta/llama3-70b-instruct", "https://integrate.api.nvidia.com/v1/chat/completions"),
]

print("="*60)
print("TESTING AVAILABLE NVIDIA MODELS")
print("="*60)

for model_name, endpoint in models_to_test:
    print(f"\n[TEST] {model_name}")
    print(f"  URL: {endpoint}")
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {NVIDIA_API_KEY}"
    }
    
    payload = {
        "model": model_name,
        "messages": [
            {"role": "user", "content": "Say 'Hello from Atlas!' in one sentence."}
        ],
        "temperature": 0.5,
        "max_tokens": 50
    }
    
    try:
        response = requests.post(endpoint, headers=headers, json=payload, timeout=15)
        
        if response.status_code == 200:
            result = response.json()
            content = result['choices'][0]['message']['content']
            print(f"  ✅ SUCCESS!")
            print(f"  Response: {content[:100]}...")
            print(f"\n  >>> USE THIS MODEL: {model_name}")
            break
        else:
            print(f"  ❌ Error {response.status_code}: {response.text[:100]}")
            
    except Exception as e:
        print(f"  ❌ Exception: {str(e)[:100]}")

print("\n" + "="*60)
