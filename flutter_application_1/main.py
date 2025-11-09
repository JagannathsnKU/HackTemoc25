"""
Atlas Gateway Server
Connects Flutter app to NVIDIA Nemotron for chat summarization
and ElevenLabs for voice synthesis
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import requests

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter web app

# API Keys (set these as environment variables in Render)
NVIDIA_API_KEY = os.environ.get('NVIDIA_API_KEY', 'your-nvidia-api-key-here')
ELEVENLABS_API_KEY = os.environ.get('ELEVENLABS_API_KEY', 'your-elevenlabs-api-key-here')

# NVIDIA API Configuration
NVIDIA_API_URL = "https://integrate.api.nvidia.com/v1/chat/completions"
NVIDIA_MODEL = "nvidia/nemotron-4-340b-instruct"  # Or your preferred model

# ElevenLabs API Configuration
ELEVENLABS_API_URL = "https://api.elevenlabs.io/v1/text-to-speech"
ELEVENLABS_VOICE_ID = "21m00Tcm4TlvDq8ikWAM"  # Rachel voice (or choose your own)


@app.route('/')
def home():
    return jsonify({
        'status': 'online',
        'service': 'Atlas Gateway',
        'endpoints': ['/summarize_chat', '/health']
    })


@app.route('/health')
def health():
    return jsonify({'status': 'ok'}), 200


@app.route('/summarize_chat', methods=['POST'])
def summarize_chat():
    """
    Main endpoint: Receives chat log, uses NVIDIA Nemotron for analysis,
    and optionally generates audio with ElevenLabs
    """
    try:
        data = request.json
        chat_log = data.get('chat_log', '')
        
        if not chat_log:
            return jsonify({'error': 'No chat_log provided'}), 400
        
        # Step 1: Call NVIDIA Nemotron for intelligent analysis
        summary_data = call_nvidia_nemotron(chat_log)
        
        # Step 2: Optionally generate audio with ElevenLabs
        # Uncomment when you have ElevenLabs API key
        # audio_url = generate_audio_summary(summary_data['summary_text'])
        # summary_data['summary_audio_url'] = audio_url
        
        return jsonify(summary_data), 200
        
    except Exception as e:
        print(f"Error in summarize_chat: {e}")
        return jsonify({
            'error': str(e),
            'summary_text': 'Error processing request',
            'topics': [],
            'suggested_reply': 'Could not generate suggestion'
        }), 500


def call_nvidia_nemotron(chat_log):
    """
    Calls NVIDIA Nemotron API with the "Scribe Agent" prompt
    """
    
    # The "Scribe Agent" prompt - multi-step reasoning
    system_prompt = """You are the 'Scribe Agent' for Atlas, a social context engine. 
Your job is to analyze chat conversations and provide intelligent insights.

For the given chat log, provide:
1. A 1-sentence summary of the conversation
2. Key topics being discussed (list of 3-5 topics)
3. A suggested reply to keep the conversation going

Be concise, friendly, and contextual. Focus on what the other person seems interested in."""

    user_prompt = f"""Analyze this conversation:

{chat_log}

Provide your analysis in this exact JSON format:
{{
  "summary": "one sentence summary",
  "topics": ["topic1", "topic2", "topic3"],
  "suggested_reply": "a natural, friendly reply suggestion"
}}"""

    try:
        headers = {
            "Authorization": f"Bearer {NVIDIA_API_KEY}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": NVIDIA_MODEL,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": 0.7,
            "max_tokens": 500
        }
        
        response = requests.post(NVIDIA_API_URL, json=payload, headers=headers, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            content = result['choices'][0]['message']['content']
            
            # Parse the JSON response from the model
            import json
            parsed = json.loads(content)
            
            return {
                'summary_text': parsed.get('summary', 'Summary not available'),
                'topics': parsed.get('topics', []),
                'suggested_reply': parsed.get('suggested_reply', 'No suggestion available')
            }
        else:
            print(f"NVIDIA API Error: {response.status_code} - {response.text}")
            # Return mock data if API fails
            return get_mock_summary(chat_log)
            
    except Exception as e:
        print(f"Error calling NVIDIA API: {e}")
        return get_mock_summary(chat_log)


def generate_audio_summary(text):
    """
    Generates audio using ElevenLabs API
    Returns URL to the audio file
    """
    try:
        headers = {
            "xi-api-key": ELEVENLABS_API_KEY,
            "Content-Type": "application/json"
        }
        
        payload = {
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": {
                "stability": 0.5,
                "similarity_boost": 0.75
            }
        }
        
        url = f"{ELEVENLABS_API_URL}/{ELEVENLABS_VOICE_ID}"
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        
        if response.status_code == 200:
            # Save audio file or upload to storage
            # For now, return a placeholder
            return "https://example.com/audio.mp3"
        else:
            print(f"ElevenLabs API Error: {response.status_code}")
            return None
            
    except Exception as e:
        print(f"Error calling ElevenLabs API: {e}")
        return None


def get_mock_summary(chat_log):
    """
    Fallback mock summary when APIs are unavailable
    """
    # Simple keyword detection
    if "puppy" in chat_log.lower() or "dog" in chat_log.lower():
        return {
            'summary_text': 'The conversation is about a new puppy and planning to meet up.',
            'topics': ['new puppy', 'dog park', 'meetup plans'],
            'suggested_reply': 'That sounds great! When works best for you?'
        }
    elif "japan" in chat_log.lower() or "travel" in chat_log.lower():
        return {
            'summary_text': 'Discussion about Japan travel and asking for recommendations.',
            'topics': ['Japan', 'travel', 'recommendations'],
            'suggested_reply': 'Kyoto is amazing in spring! The temples and cherry blossoms are incredible.'
        }
    else:
        return {
            'summary_text': 'General conversation with friendly discussion.',
            'topics': ['conversation', 'chat'],
            'suggested_reply': 'That sounds interesting! Tell me more about that.'
        }


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
