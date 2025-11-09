"""
Test script to verify NVIDIA Brev server connection
Tests the Nemotron model on your Brev A100 GPU server
"""

import requests
import json
import sys

# Your Brev server configuration
BREV_SERVER = "http://216.81.248.79"
ORCHESTRATOR_URL = f"{BREV_SERVER}:8001/v1/chat/completions"
NVIDIA_API_KEY = "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"
MODEL = "nvidia/nemotron-4-340b-instruct"

print("=" * 60)
print("NVIDIA BREV SERVER CONNECTION TEST")
print("=" * 60)
print(f"Server: {BREV_SERVER}")
print(f"Endpoint: {ORCHESTRATOR_URL}")
print(f"Model: {MODEL}")
print("=" * 60)
print()

# Test 1: Simple health check
print("[TEST 1] Testing server reachability...")
try:
    response = requests.get(f"{BREV_SERVER}:8001", timeout=5)
    print(f"✓ Server is reachable (Status: {response.status_code})")
except requests.exceptions.RequestException as e:
    print(f"✗ Server unreachable: {e}")
    print("\n[ERROR] Cannot reach Brev server. Check:")
    print("  1. Is the Brev server running?")
    print("  2. Is the IP address correct?")
    print("  3. Is port 8001 open?")
    sys.exit(1)

print()

# Test 2: Test the AI completions endpoint
print("[TEST 2] Testing Nemotron AI completion...")
try:
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {NVIDIA_API_KEY}"
    }
    
    payload = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": "You are a helpful AI assistant."},
            {"role": "user", "content": "Say 'Hello! Brev server is working!' in one sentence."}
        ],
        "temperature": 0.7,
        "max_tokens": 50
    }
    
    print(f"  Sending request to: {ORCHESTRATOR_URL}")
    print(f"  Payload: {json.dumps(payload, indent=2)[:200]}...")
    
    response = requests.post(
        ORCHESTRATOR_URL,
        headers=headers,
        json=payload,
        timeout=30
    )
    
    print(f"  Response Status: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        content = result['choices'][0]['message']['content']
        print(f"✓ AI Response: {content}")
        print()
        print("[SUCCESS] Brev server is working correctly!")
        print("Your Nemotron model is ready to use!")
    else:
        print(f"✗ Error {response.status_code}")
        print(f"  Response: {response.text}")
        print()
        print("[ERROR] Server responded but with an error.")
        print("Check your API key and model configuration.")
        
except requests.exceptions.Timeout:
    print("✗ Request timed out (30s)")
    print()
    print("[ERROR] Server is reachable but too slow to respond.")
    print("The model might be loading. Wait 1-2 minutes and try again.")
    
except Exception as e:
    print(f"✗ Exception: {e}")
    import traceback
    traceback.print_exc()
    print()
    print("[ERROR] Unexpected error occurred.")

print()
print("=" * 60)
