"""
Atlas Gateway Server - Pro Multi-Agent Architecture
Coordinates the full Nemotron NIM suite on Brev A100 server
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import requests
import json
from datetime import datetime

app = Flask(__name__)
CORS(app)

# ============================================================================
# CONFIGURATION
# ============================================================================

# Brev Server Configuration (Your A100 GPU Server)
BREV_SERVER = os.environ.get('BREV_SERVER_URL', 'http://your-brev-server-ip')
ORCHESTRATOR_URL = f"{BREV_SERVER}:8001/v1/chat/completions"
SCOUT_VLM_URL = f"{BREV_SERVER}:8002/v1/chat/completions"
RIVA_ASR_URL = f"{BREV_SERVER}:50051"
RIVA_TTS_URL = f"{BREV_SERVER}:50052"

# API Keys
NVIDIA_API_KEY = os.environ.get('NVIDIA_API_KEY', 'your-nvidia-api-key')
ELEVENLABS_API_KEY = os.environ.get('ELEVENLABS_API_KEY', 'your-elevenlabs-key')
GOOGLE_CALENDAR_API_KEY = os.environ.get('GOOGLE_CALENDAR_KEY', 'mock')

# Model Configurations
ORCHESTRATOR_MODEL = "nvidia/nemotron-4-340b-instruct"
SCOUT_VLM_MODEL = "nvidia/llama-3.1-nemotron-nano-vl-8b-v1"


# ============================================================================
# AGENT 1: THE ORCHESTRATOR (Main Coordinator)
# ============================================================================

def call_orchestrator(system_prompt, user_prompt, tools=None):
    """
    Call the Nemotron Orchestrator NIM
    This is the "Brain" that coordinates all other agents
    """
    try:
        payload = {
            "model": ORCHESTRATOR_MODEL,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        }
        
        # Add tools for ReAct pattern if provided
        if tools:
            payload["tools"] = tools
        
        response = requests.post(
            ORCHESTRATOR_URL,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {NVIDIA_API_KEY}"
            },
            json=payload,
            timeout=30
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Orchestrator Error: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        print(f"Orchestrator Exception: {e}")
        return None


# ============================================================================
# AGENT 2: THE SCOUT (Multi-Modal Vision Agent)
# ============================================================================

def call_scout_vlm(image_url, query):
    """
    Call the Scout VLM NIM for image analysis
    Used for understanding social media photos
    """
    try:
        payload = {
            "model": SCOUT_VLM_MODEL,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": query},
                        {"type": "image_url", "image_url": {"url": image_url}}
                    ]
                }
            ],
            "max_tokens": 300
        }
        
        response = requests.post(
            SCOUT_VLM_URL,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {NVIDIA_API_KEY}"
            },
            json=payload,
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            return data['choices'][0]['message']['content']
        else:
            return None
            
    except Exception as e:
        print(f"Scout VLM Exception: {e}")
        return None


# ============================================================================
# AGENT 3: THE CONCIERGE (Event Planning Agent)
# ============================================================================

def concierge_agent(user_request, user_calendar, friend_calendar):
    """
    Implements the ReAct Pattern: Reason → Act → Observe
    Plans events by coordinating calendars and preferences
    """
    
    system_prompt = """You are the "Concierge Agent" for Atlas.
Your job is to plan social events by:
1. REASONING about availability and preferences
2. ACTING by checking tools (calendars, maps, preferences)
3. OBSERVING the results
4. Synthesizing a perfect plan

Use the ReAct pattern. Think step-by-step."""

    user_prompt = f"""Plan an event for this request: "{user_request}"

Available Data:
- User Calendar: {json.dumps(user_calendar)}
- Friend Calendar: {json.dumps(friend_calendar)}

Think through this step by step:
1. What times work for both people?
2. What shared interests do they have?
3. What location makes sense?

Return a JSON plan:
{{
  "reasoning": "your step-by-step thought process",
  "suggested_time": "when to meet",
  "suggested_activity": "what to do",
  "suggested_location": "where to go",
  "confidence": "high/medium/low"
}}"""

    result = call_orchestrator(system_prompt, user_prompt)
    
    if result:
        try:
            content = result['choices'][0]['message']['content']
            # Try to parse JSON from response
            if '{' in content:
                json_start = content.index('{')
                json_end = content.rindex('}') + 1
                plan = json.loads(content[json_start:json_end])
                return plan
        except:
            pass
    
    # Fallback mock
    return {
        "reasoning": "Analyzed calendars and found mutual availability",
        "suggested_time": "Saturday at 3 PM",
        "suggested_activity": "Hiking",
        "suggested_location": "Arbor Hills Park",
        "confidence": "high"
    }


# ============================================================================
# AGENT 4: THE GHOSTWRITER (Agentic RAG Agent)
# ============================================================================

def ghostwriter_agent(message_to_write, user_writing_samples):
    """
    Implements Agentic RAG: Intelligently retrieves user's writing style
    Then generates a message that sounds authentically like them
    """
    
    system_prompt = """You are the "Ghostwriter Agent" for Atlas.
Your job is to write messages that sound EXACTLY like the user.

You have access to RAG (Retrieval-Augmented Generation):
- You can analyze the user's past messages to learn their style
- You intelligently decide WHEN to retrieve examples
- You blend the content request with the authentic style

NEVER sound like an AI. Sound like the human."""

    user_prompt = f"""Write this message: "{message_to_write}"

The user's writing style (from RAG):
{json.dumps(user_writing_samples, indent=2)}

Requirements:
1. Match their tone (formal/casual)
2. Use their typical phrases/slang
3. Match their emoji usage
4. Sound 100% authentic

Return ONLY the final message text, nothing else."""

    result = call_orchestrator(system_prompt, user_prompt)
    
    if result:
        content = result['choices'][0]['message']['content']
        return content.strip().strip('"')
    
    # Fallback
    return message_to_write


# ============================================================================
# AGENT 5: THE SCOUT SOCIAL (Social Media Analysis)
# ============================================================================

def scout_social_agent(friend_name, recent_photo_url=None):
    """
    Multi-modal agent that finds genuine touchpoints
    Uses VLM to analyze social media photos
    """
    
    # If there's a photo, use the VLM
    if recent_photo_url:
        image_analysis = call_scout_vlm(
            recent_photo_url,
            f"Describe what is happening in this photo. Focus on: 1) Who is in it, 2) What they're doing, 3) Any notable objects or events. Be concise and factual."
        )
        
        if image_analysis:
            # Now use Orchestrator to turn this into a touchpoint
            system_prompt = """You are the "Scout Agent" for Atlas.
You analyze social signals to find genuine conversation starters."""

            user_prompt = f"""Friend: {friend_name}
Recent photo analysis: {image_analysis}

Generate a JSON touchpoint:
{{
  "touchpoint_type": "new_photo|life_event|shared_interest",
  "summary": "one-sentence description",
  "icebreaker": "a natural way to bring this up",
  "priority": "high/medium/low"
}}"""

            result = call_orchestrator(system_prompt, user_prompt)
            
            if result:
                try:
                    content = result['choices'][0]['message']['content']
                    if '{' in content:
                        json_start = content.index('{')
                        json_end = content.rindex('}') + 1
                        return json.loads(content[json_start:json_end])
                except:
                    pass
    
    # Fallback mock
    return {
        "touchpoint_type": "life_event",
        "summary": f"{friend_name} recently shared something interesting",
        "icebreaker": f"Hey! Saw your recent post - what's new?",
        "priority": "medium"
    }


# ============================================================================
# API ENDPOINTS
# ============================================================================

@app.route('/')
def home():
    return jsonify({
        'status': 'online',
        'service': 'Atlas Pro Gateway',
        'architecture': 'Multi-Agent Nemotron System',
        'agents': {
            'orchestrator': 'Nemotron 340B Instruct',
            'scout_vlm': 'Llama 3.1 Nemotron Nano VL',
            'riva_asr': 'Real-time Speech-to-Text',
            'riva_tts': 'AI Voice Synthesis'
        },
        'endpoints': [
            '/summarize_chat',
            '/plan_event',
            '/write_message',
            '/analyze_social',
            '/health'
        ]
    })


@app.route('/health')
def health():
    return jsonify({'status': 'ok'}), 200


@app.route('/summarize_chat', methods=['POST'])
def summarize_chat():
    """
    Enhanced chat summarization using Orchestrator NIM
    """
    try:
        data = request.json
        chat_log = data.get('chat_log', '')
        
        system_prompt = """You are the "Scribe Agent" for Atlas.
Analyze conversations and provide actionable insights."""

        user_prompt = f"""Analyze this conversation and respond with ONLY valid JSON:
{{
  "summary_text": "one sentence summary",
  "topics": ["topic1", "topic2", "topic3"],
  "suggested_reply": "a natural, contextual response"
}}

Conversation:
{chat_log}"""

        result = call_orchestrator(system_prompt, user_prompt)
        
        if result:
            try:
                content = result['choices'][0]['message']['content']
                if '{' in content:
                    json_start = content.index('{')
                    json_end = content.rindex('}') + 1
                    parsed = json.loads(content[json_start:json_end])
                    return jsonify(parsed)
            except:
                pass
        
        # Fallback
        return jsonify({
            "summary_text": "Conversation analyzed",
            "topics": ["general discussion"],
            "suggested_reply": "That's interesting! Tell me more."
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/plan_event', methods=['POST'])
def plan_event():
    """
    NEW: Concierge Agent endpoint for event planning
    """
    try:
        data = request.json
        user_request = data.get('request', '')
        user_calendar = data.get('user_calendar', [])
        friend_calendar = data.get('friend_calendar', [])
        
        plan = concierge_agent(user_request, user_calendar, friend_calendar)
        return jsonify(plan)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/write_message', methods=['POST'])
def write_message():
    """
    NEW: Ghostwriter Agent endpoint with Agentic RAG
    """
    try:
        data = request.json
        message_content = data.get('message', '')
        writing_samples = data.get('writing_samples', [])
        
        final_message = ghostwriter_agent(message_content, writing_samples)
        return jsonify({"message": final_message})
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/analyze_social', methods=['POST'])
def analyze_social():
    """
    NEW: Scout Social Agent with Multi-Modal VLM
    """
    try:
        data = request.json
        friend_name = data.get('friend_name', '')
        photo_url = data.get('photo_url', None)
        
        touchpoint = scout_social_agent(friend_name, photo_url)
        return jsonify(touchpoint)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
