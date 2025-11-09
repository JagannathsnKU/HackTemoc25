"""
Atlas Auto-Agent System with ElevenLabs Voice Integration
Fully automated multi-agent system that works seamlessly in the background
"""

from flask import Flask, request, jsonify, make_response
from flask_cors import CORS
import os
import requests
import json
from datetime import datetime, timedelta

app = Flask(__name__)

# Simple CORS - allow everything
CORS(app)

# Universal OPTIONS handler
@app.route('/', defaults={'path': ''}, methods=['OPTIONS'])
@app.route('/<path:path>', methods=['OPTIONS'])
def handle_options(path):
    response = make_response('', 200)
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    response.headers['Access-Control-Max-Age'] = '3600'
    return response

# Add CORS headers to all responses
@app.after_request
def after_request(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    return response

# ============================================================================
# CONFIGURATION
# ============================================================================

# Brev Server (Your A100 GPU) - Update after deployment
# Set to 'http://localhost' to use NVIDIA API directly (no Brev server needed)
# Set to your Brev IP (e.g., 'http://216.81.248.79') when server is running
BREV_SERVER = os.environ.get('BREV_SERVER_URL', 'http://localhost')
ORCHESTRATOR_URL = f"{BREV_SERVER}:8001/v1/chat/completions"
SCOUT_VLM_URL = f"{BREV_SERVER}:8002/v1/chat/completions"

# API Keys
NVIDIA_API_KEY = os.environ.get('NVIDIA_API_KEY', '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')
ELEVENLABS_API_KEY = os.environ.get('ELEVENLABS_API_KEY', 'sk_03167a5025adcc45a25a234c6131ca7229915188c752e062')

# ElevenLabs Configuration
ELEVENLABS_API_URL = "https://api.elevenlabs.io/v1/text-to-speech"
ELEVENLABS_VOICE_ID = "21m00Tcm4TlvDq8ikWAM"  # Rachel voice - natural and professional

# Model Configuration
# Primary: Nemotron-4-340B on Brev (when available)
# Fallback: Llama-3.1-8B-Instruct via NVIDIA API (always available)
ORCHESTRATOR_MODEL = "nvidia/nemotron-4-340b-instruct"  # For Brev server
FALLBACK_MODEL = "meta/llama-3.1-8b-instruct"  # For NVIDIA API direct


# ============================================================================
# CORE AI ENGINE
# ============================================================================

def call_ai(system_prompt, user_prompt, use_brev=True):
    """
    Unified AI calling function
    Use Brev server if available, fallback to direct API
    """
    try:
        # Choose endpoint - PREFER Brev server
        if use_brev and BREV_SERVER != 'http://localhost':
            url = ORCHESTRATOR_URL
            model = ORCHESTRATOR_MODEL
            print(f"[AI] Using Brev server: {url}")
            print(f"[AI] Model: {model}")
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {NVIDIA_API_KEY}"
            }
        else:
            # Fallback to direct NVIDIA API
            url = "https://integrate.api.nvidia.com/v1/chat/completions"
            model = FALLBACK_MODEL  # Use working model
            print(f"[AI] Using NVIDIA API: {url}")
            print(f"[AI] Model: {model}")
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {NVIDIA_API_KEY}"
            }
        
        payload = {
            "model": model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        }
        
        print(f"[AI] Calling AI with model: {ORCHESTRATOR_MODEL}")
        print(f"[AI] Payload preview: {str(payload)[:200]}...")
        
        response = requests.post(
            url,
            headers=headers,
            json=payload,
            timeout=30
        )
        
        print(f"[AI] Response status: {response.status_code}")
        
        if response.status_code == 200:
            print(f"[AI] SUCCESS: AI response received")
            result = response.json()
            print(f"[AI] Response preview: {str(result)[:200]}...")
            return result
        else:
            print(f"[AI] ERROR: {response.status_code}")
            print(f"[AI] Response: {response.text[:500]}")
            return None
            
    except Exception as e:
        print(f"[AI] EXCEPTION: {e}")
        import traceback
        traceback.print_exc()
        return None


# ============================================================================
# AUTO-AGENT: CONVERSATION ANALYZER
# ============================================================================

@app.route('/auto_analyze_conversation', methods=['POST', 'OPTIONS'])
def auto_analyze_conversation():
    """
    AUTOMATIC: Called when user opens a conversation
    Analyzes full chat history and provides:
    1. Summary
    2. Topics
    3. Suggested reply
    4. Action opportunities (booking, follow-up, etc.)
    """
    # Handle OPTIONS preflight
    if request.method == 'OPTIONS':
        return jsonify({'status': 'ok'}), 200
    
    try:
        data = request.json
        chat_log = data.get('chat_log', '')
        contact_name = data.get('contact_name', '')
        
        system_prompt = f"""You are Atlas's Auto-Analyzer for {contact_name}.
Analyze this conversation AUTOMATICALLY and provide actionable insights.

Return ONLY valid JSON:
{{
  "summary_text": "one sentence summary",
  "topics": ["topic1", "topic2", "topic3"],
  "suggested_reply": "natural response",
  "action_needed": "booking|follow_up|none",
  "action_details": {{
    "type": "meeting|lunch|call",
    "suggested_time": "when to schedule",
    "reason": "why this makes sense"
  }}
}}"""

        user_prompt = f"Conversation with {contact_name}:\n{chat_log}"
        
        result = call_ai(system_prompt, user_prompt)
        
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
            "suggested_reply": "Thanks for sharing!",
            "action_needed": "none",
            "action_details": {}
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ============================================================================
# AUTO-AGENT: SMART BOOKING SYSTEM
# ============================================================================

@app.route('/auto_book_meeting', methods=['POST'])
def auto_book_meeting():
    """
    AUTOMATIC: Triggered when AI detects booking opportunity
    1. Checks calendars (mock for now, add Google Calendar API)
    2. Finds best time
    3. Generates voice message via ElevenLabs
    4. Returns booking confirmation
    """
    try:
        data = request.json
        contact_name = data.get('contact_name', '')
        meeting_type = data.get('meeting_type', 'meeting')
        chat_context = data.get('chat_context', '')
        
        # Step 1: AI determines best time
        system_prompt = """You are Atlas's Booking Agent.
Analyze the conversation and calendar availability to suggest the BEST meeting time.

Return ONLY valid JSON:
{
  "suggested_time": "Day, Time (e.g., Tomorrow at 3 PM)",
  "meeting_type": "lunch|coffee|meeting|call",
  "location": "where to meet or 'video call'",
  "message_to_send": "natural message to propose this",
  "confidence": "high|medium|low"
}"""

        user_prompt = f"""Contact: {contact_name}
Meeting Type: {meeting_type}
Recent conversation: {chat_context}

User's Calendar (mock):
- Today: 2 PM - 5 PM (busy)
- Tomorrow: Free after 12 PM
- This Weekend: Saturday morning free

Friend's typical availability: Weekday afternoons, weekends"""

        result = call_ai(system_prompt, user_prompt)
        
        booking_data = None
        if result:
            try:
                content = result['choices'][0]['message']['content']
                if '{' in content:
                    json_start = content.index('{')
                    json_end = content.rindex('}') + 1
                    booking_data = json.loads(content[json_start:json_end])
            except:
                pass
        
        if not booking_data:
            # Fallback
            booking_data = {
                "suggested_time": "Tomorrow at 3 PM",
                "meeting_type": meeting_type,
                "location": "Downtown café",
                "message_to_send": f"Hey! Want to grab {meeting_type} tomorrow around 3?",
                "confidence": "medium"
            }
        
        # Step 2: Generate ElevenLabs voice message
        voice_script = f"""Hi {contact_name}, this is Atlas, your AI assistant speaking. 
I noticed you and the user have been talking about meeting up. 
I've checked both calendars and found that {booking_data['suggested_time']} works perfectly. 
Would you like me to schedule {booking_data['meeting_type']} at {booking_data['location']}? 
Let me know and I'll send the calendar invite!"""
        
        audio_url = generate_voice_message(voice_script)
        
        booking_data['voice_message_url'] = audio_url
        booking_data['voice_script'] = voice_script
        
        return jsonify(booking_data)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ============================================================================
# ELEVENLABS VOICE GENERATION
# ============================================================================

def generate_voice_message(text):
    """
    Generate natural voice message using ElevenLabs
    Returns URL to audio file
    """
    try:
        if ELEVENLABS_API_KEY == 'your-elevenlabs-key-here':
            print("ElevenLabs: No API key, returning mock URL")
            return "https://mock-audio-url.com/atlas-voice.mp3"
        
        url = f"{ELEVENLABS_API_URL}/{ELEVENLABS_VOICE_ID}"
        
        payload = {
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": {
                "stability": 0.5,
                "similarity_boost": 0.75
            }
        }
        
        headers = {
            "Accept": "audio/mpeg",
            "Content-Type": "application/json",
            "xi-api-key": ELEVENLABS_API_KEY
        }
        
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        
        if response.status_code == 200:
            # Save audio file
            audio_filename = f"atlas_voice_{datetime.now().strftime('%Y%m%d_%H%M%S')}.mp3"
            audio_path = f"/tmp/{audio_filename}"
            
            with open(audio_path, 'wb') as f:
                f.write(response.content)
            
            # Return URL (in production, upload to S3/Cloud Storage)
            return f"http://localhost:5000/audio/{audio_filename}"
        else:
            print(f"ElevenLabs Error: {response.status_code}")
            return None
            
    except Exception as e:
        print(f"ElevenLabs Exception: {e}")
        return None


@app.route('/audio/<filename>')
def serve_audio(filename):
    """Serve generated audio files"""
    from flask import send_file
    return send_file(f"/tmp/{filename}", mimetype='audio/mpeg')


# ============================================================================
# AUTO-AGENT: CONTEXTUAL ACTIONS
# ============================================================================

@app.route('/detect_actions', methods=['POST'])
def detect_actions():
    """
    AUTOMATIC: Detects what actions the user can take
    - Book meeting
    - Send follow-up
    - Share content
    - Plan event
    """
    try:
        data = request.json
        chat_log = data.get('chat_log', '')
        contact_name = data.get('contact_name', '')
        
        system_prompt = """You are Atlas's Action Detector.
Analyze the conversation and detect what actions make sense.

Return ONLY valid JSON array:
[
  {
    "action_type": "book_meeting|send_followup|share_content|plan_event",
    "title": "Short action title",
    "description": "Why this action makes sense",
    "priority": "high|medium|low",
    "icon": "calendar|message|share|event"
  }
]"""

        user_prompt = f"Conversation with {contact_name}:\n{chat_log}"
        
        result = call_ai(system_prompt, user_prompt)
        
        if result:
            try:
                content = result['choices'][0]['message']['content']
                if '[' in content:
                    json_start = content.index('[')
                    json_end = content.rindex(']') + 1
                    actions = json.loads(content[json_start:json_end])
                    return jsonify({"actions": actions})
            except:
                pass
        
        # Fallback
        return jsonify({
            "actions": [
                {
                    "action_type": "send_followup",
                    "title": "Send Follow-up",
                    "description": "Continue the conversation",
                    "priority": "medium",
                    "icon": "message"
                }
            ]
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ============================================================================
# ORIGINAL ENDPOINT (KEEP FOR COMPATIBILITY)
# ============================================================================

@app.route('/summarize_chat', methods=['POST'])
def summarize_chat():
    """Original chat summarization - now calls auto_analyze"""
    try:
        data = request.json
        chat_log = data.get('chat_log', '')
        
        # Forward to auto analyzer
        result = auto_analyze_conversation()
        return result
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ============================================================================
# HEALTH & INFO
# ============================================================================

@app.route('/')
def home():
    return jsonify({
        'status': 'online',
        'service': 'Atlas Auto-Agent System',
        'features': [
            'Auto-analyze conversations on open',
            'Smart meeting booking with calendar check',
            'ElevenLabs voice message generation',
            'Contextual action detection',
            'Fully automated AI workflows'
        ],
        'endpoints': [
            '/auto_analyze_conversation',
            '/auto_book_meeting',
            '/detect_actions',
            '/summarize_chat'
        ],
        'brev_status': 'connected' if BREV_SERVER != 'http://localhost' else 'local_mode',
        'elevenlabs_status': 'active' if ELEVENLABS_API_KEY != 'your-elevenlabs-key-here' else 'need_api_key'
    })


@app.route('/health')
def health():
    return jsonify({'status': 'ok'}), 200


@app.route('/predict_followup', methods=['POST'])
def predict_followup():
    """
    AI-powered follow-up prediction
    Analyzes conversation context to determine if/when to follow up
    """
    try:
        data = request.json
        contact_name = data.get('contact_name')
        chat_log = data.get('chat_log', '')
        last_message = data.get('last_message', '')
        hours_since_message = data.get('hours_since_message', 0)
        
        # AI Analysis Prompt
        system_prompt = """You are Atlas, an AI relationship intelligence assistant.
Analyze conversations to determine if the user should follow up with their contact.
Consider:
- Time since last message
- Conversation context and tone
- Relationship importance signals
- Open loops or pending items
- Social norms and politeness

Return JSON with:
{
  "should_follow_up": boolean,
  "urgency": "low" | "medium" | "high" | "critical",
  "suggested_message": "Brief, contextual follow-up message",
  "reasoning": "Why this follow-up is recommended",
  "best_time": "morning" | "afternoon" | "evening" | "now",
  "wait_hours": number (hours to wait before following up)
}"""

        user_prompt = f"""Analyze this conversation with {contact_name}:

LAST MESSAGE (sent {hours_since_message} hours ago):
"{last_message}"

FULL CONVERSATION HISTORY:
{chat_log}

Should the user follow up? Generate a natural, contextual follow-up message if yes."""

        # Call AI
        ai_response = call_ai(system_prompt, user_prompt, use_brev=True)
        
        try:
            # Parse AI response as JSON
            result = json.loads(ai_response['choices'][0]['message']['content'])
        except (json.JSONDecodeError, KeyError, TypeError):
            # Fallback if AI doesn't return valid JSON
            result = {
                'should_follow_up': hours_since_message > 24,
                'urgency': 'medium' if hours_since_message > 48 else 'low',
                'suggested_message': f'Hey {contact_name}! Just wanted to check in. How are things going?',
                'reasoning': f'It\'s been {hours_since_message} hours since your last message.',
                'best_time': 'afternoon',
                'wait_hours': max(0, 24 - hours_since_message)
            }
        
        return jsonify({
            'success': True,
            'contact_name': contact_name,
            'hours_since_message': hours_since_message,
            **result
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'should_follow_up': False
        }), 500


@app.route('/voice_book_meeting', methods=['POST', 'OPTIONS'])
def voice_book_meeting():
    """
    Voice-activated meeting booking with ElevenLabs + Google Calendar Integration
    Processes spoken commands to book meetings using Brev GPU multi-agent AI
    NOW: Checks user's calendar and suggests only available time slots!
    """
    # Handle OPTIONS preflight request
    if request.method == 'OPTIONS':
        response = jsonify({'status': 'ok'})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type')
        return response, 200
    
    try:
        data = request.json
        voice_command = data.get('voice_command', '')
        contact_name = data.get('contact_name')
        chat_log = data.get('chat_log', '')
        free_calendar_slots = data.get('free_calendar_slots', '')  # ✨ NEW!
        has_calendar_data = data.get('has_calendar_data', False)  # ✨ NEW!
        
        print(f"🎤 Voice Command Received: '{voice_command}' for {contact_name}")
        if has_calendar_data:
            print(f"📅 Calendar slots available: {free_calendar_slots}")
        
        # AI processes voice command with calendar awareness
        calendar_context = ""
        voice_script_hint = "I suggest"
        if has_calendar_data and free_calendar_slots:
            calendar_context = f"\n\n📅 USER'S AVAILABLE TIME SLOTS (from Google Calendar):\n{free_calendar_slots}\n\n✅ IMPORTANT: Only suggest times from the available slots above!"
            voice_script_hint = "Based on your calendar, you're free"
        
        system_prompt = f"""You are Atlas, an AI meeting booking assistant with Google Calendar integration.

{calendar_context}

Parse the voice command and return ONLY valid JSON (no markdown, no explanation):
{{
  "meeting_type": "coffee|lunch|call|meeting|dinner",
  "preferred_time": "description of when",
  "duration_minutes": 60,
  "location": "location or null",
  "notes": "additional context",
  "suggested_times": ["Tomorrow at 2pm", "Next week", "Friday afternoon"],
  "voice_script": "Hi! I heard you want to book a [type]. {voice_script_hint} [time]. Sound good?"
}}"""

        user_prompt = f"""Voice Command: "{voice_command}"
Contact: {contact_name}
Chat History: {chat_log[:500] if chat_log else 'No history'}

Return JSON only."""

        print(f"[BREV] Calling Brev AI at {BREV_SERVER}...")
        
        # Get AI analysis using Brev GPU
        ai_result = call_ai(system_prompt, user_prompt, use_brev=True)
        
        if not ai_result or 'choices' not in ai_result:
            print(f"❌ AI returned no result: {ai_result}")
            # Fallback response
            meeting_data = {
                "meeting_type": "meeting",
                "preferred_time": "soon",
                "duration_minutes": 60,
                "location": None,
                "notes": voice_command,
                "suggested_times": ["Tomorrow at 2pm", "Next week"],
                "voice_script": f"Hi! I heard: {voice_command}. Let me help you book that meeting with {contact_name}."
            }
        else:
            ai_response = ai_result['choices'][0]['message']['content']
            print(f"[BREV] AI Response: {ai_response[:200]}...")
            
            # Try to parse JSON from AI response
            try:
                # Remove markdown code blocks if present
                if '```' in ai_response:
                    ai_response = ai_response.split('```json')[1].split('```')[0] if '```json' in ai_response else ai_response.split('```')[1].split('```')[0]
                
                meeting_data = json.loads(ai_response.strip())
                print(f"✅ Parsed meeting data: {meeting_data.get('meeting_type')} at {meeting_data.get('preferred_time')}")
            except json.JSONDecodeError as e:
                print(f"❌ JSON parse error: {e}")
                print(f"Raw response: {ai_response}")
                # Fallback with parsed info
                meeting_data = {
                    "meeting_type": "meeting",
                    "preferred_time": "soon",
                    "duration_minutes": 60,
                    "location": None,
                    "notes": voice_command,
                    "suggested_times": ["Tomorrow at 2pm"],
                    "voice_script": f"Hi {contact_name}! I heard your request: {voice_command}. Let me help you schedule that."
                }
        
        # Generate voice confirmation with ElevenLabs
        voice_script = meeting_data.get('voice_script', 
            f"Hi! I've analyzed your request to {voice_command}. I suggest booking a {meeting_data.get('meeting_type', 'meeting')} with {contact_name}.")
        
        print(f"🔊 Generating ElevenLabs voice...")
        voice_url = generate_voice_message(voice_script)
        print(f"✅ Voice URL: {voice_url}")
        
        return jsonify({
            'success': True,
            'meeting_data': meeting_data,
            'voice_message_url': voice_url,
            'voice_script': voice_script,
            'ai_analysis': meeting_data
        })
        
    except Exception as e:
        print(f"❌ Voice booking error: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/book_google_calendar', methods=['POST', 'OPTIONS'])
def book_google_calendar():
    """
    Book meeting to Google Calendar
    """
    # Handle OPTIONS preflight
    if request.method == 'OPTIONS':
        return jsonify({'status': 'ok'}), 200
    
    try:
        data = request.json
        contact_name = data.get('contact_name')
        contact_email = data.get('contact_email')
        start_time = datetime.fromisoformat(data.get('start_time'))
        end_time = datetime.fromisoformat(data.get('end_time'))
        description = data.get('description', '')
        
        # This would integrate with Google Calendar API
        # For now, return success with mock data
        
        # Generate voice confirmation
        voice_script = f"Perfect! I've booked your meeting with {contact_name} on {start_time.strftime('%A, %B %d at %I:%M %p')}. A calendar invite has been sent to {contact_email}."
        
        voice_url = generate_voice_message(voice_script)
        
        return jsonify({
            'success': True,
            'event_id': 'mock_event_123',
            'calendar_link': f'https://calendar.google.com/event?eid=mock_123',
            'voice_message_url': voice_url,
            'voice_script': voice_script,
            'meeting_details': {
                'contact': contact_name,
                'start': start_time.isoformat(),
                'end': end_time.isoformat(),
                'description': description
            }
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# ============================================================================
# NEW AI AGENT: SMART REPLY GENERATOR
# ============================================================================

@app.route('/agent/smart_reply', methods=['POST', 'OPTIONS'])
def agent_smart_reply():
    """
    Generates 3 personalized reply suggestions based on:
    - Conversation context
    - User's texting style
    - Urgency and tone
    """
    if request.method == 'OPTIONS':
        return jsonify({'status': 'ok'}), 200
    
    try:
        data = request.json
        last_message = data.get('last_message', '')
        contact_name = data.get('contact_name', '')
        conversation_history = data.get('conversation_history', '')
        user_name = data.get('user_name', 'User')
        
        system_prompt = f"""You are a Smart Reply Generator for {user_name}.
Generate 3 personalized reply suggestions to {contact_name}'s message.

Rules:
1. Match the user's texting style (casual, emojis if they use them)
2. Be contextually appropriate
3. Vary the tone: one enthusiastic, one neutral, one brief
4. Keep replies natural and authentic

Return ONLY valid JSON:
{{
  "replies": [
    {{"text": "reply 1", "tone": "enthusiastic", "emoji": "😊"}},
    {{"text": "reply 2", "tone": "neutral", "emoji": "👍"}},
    {{"text": "reply 3", "tone": "brief", "emoji": ""}}
  ]
}}"""

        user_prompt = f"""Context: Recent conversation with {contact_name}
{conversation_history}

Latest message from {contact_name}: "{last_message}"

Generate 3 smart reply suggestions."""
        
        result = call_ai(system_prompt, user_prompt)
        
        if result:
            try:
                # Extract content from AI response
                content = result['choices'][0]['message']['content']
                
                # Find JSON in the response
                if '{' in content:
                    json_start = content.index('{')
                    json_end = content.rindex('}') + 1
                    json_str = content[json_start:json_end]
                    parsed = json.loads(json_str)
                    
                    return jsonify({
                        'success': True,
                        'replies': parsed.get('replies', [])
                    })
                else:
                    raise ValueError("No JSON found in response")
                    
            except (json.JSONDecodeError, ValueError, KeyError) as e:
                print(f"Smart reply parse error: {e}")
                # Fallback replies
                return jsonify({
                    'success': True,
                    'replies': [
                        {"text": "Sounds good!", "tone": "positive", "emoji": "👍"},
                        {"text": "Let me check and get back to you", "tone": "neutral", "emoji": ""},
                        {"text": "Sure!", "tone": "brief", "emoji": ""}
                    ]
                })
        else:
            return jsonify({
                'success': False,
                'error': 'AI unavailable'
            }), 500
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# ============================================================================
# NEW AI AGENT: SENTIMENT TRACKER
# ============================================================================

@app.route('/agent/sentiment_analysis', methods=['POST', 'OPTIONS'])
def agent_sentiment_analysis():
    """
    Analyzes sentiment of messages over time
    Returns sentiment score and trend
    """
    if request.method == 'OPTIONS':
        return jsonify({'status': 'ok'}), 200
    
    try:
        data = request.json
        messages = data.get('messages', [])  # List of {text, timestamp, sender}
        contact_name = data.get('contact_name', '')
        
        system_prompt = """You are a Sentiment Analysis Agent.
Analyze the emotional tone of these messages over time.

For each message, classify sentiment as:
- positive (happy, excited, friendly)
- neutral (informational, casual)
- negative (sad, angry, frustrated)

Also provide an overall trend and relationship health indicator.

Return ONLY valid JSON:
{
  "messages": [
    {"index": 0, "sentiment": "positive", "score": 0.8, "reason": "enthusiastic greeting"},
    {"index": 1, "sentiment": "neutral", "score": 0.5, "reason": "factual response"}
  ],
  "overall_sentiment": "positive",
  "trend": "improving|stable|declining",
  "health_score": 85,
  "insights": "Relationship seems healthy. Recent messages are warm and engaged."
}"""

        # Format messages for analysis
        formatted_messages = "\n".join([
            f"{i}. [{msg.get('sender', 'Unknown')}] {msg.get('text', '')}" 
            for i, msg in enumerate(messages[:20])  # Analyze last 20 messages
        ])
        
        user_prompt = f"""Analyze sentiment in conversation with {contact_name}:

{formatted_messages}

Provide sentiment analysis for each message and overall trend."""
        
        result = call_ai(system_prompt, user_prompt)
        
        if result:
            try:
                parsed = json.loads(result)
                return jsonify({
                    'success': True,
                    'data': parsed
                })
            except json.JSONDecodeError:
                # Fallback analysis
                return jsonify({
                    'success': True,
                    'data': {
                        'overall_sentiment': 'neutral',
                        'trend': 'stable',
                        'health_score': 70,
                        'insights': 'Conversation seems balanced and healthy.'
                    }
                })
        else:
            return jsonify({
                'success': False,
                'error': 'AI unavailable'
            }), 500
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# ============================================================================
# NEW AI AGENT: RELATIONSHIP HEALTH SCORE
# ============================================================================

@app.route('/agent/relationship_health', methods=['POST', 'OPTIONS'])
def agent_relationship_health():
    """
    Calculates comprehensive relationship health score (0-100)
    Based on: frequency, sentiment, response time, topic diversity, conversation timing analysis
    """
    if request.method == 'OPTIONS':
        return jsonify({'status': 'ok'}), 200
    
    try:
        data = request.json
        contact_name = data.get('contact_name', '')
        message_count = data.get('message_count', 0)
        days_since_last = data.get('days_since_last_message', 0)
        avg_response_time_hours = data.get('avg_response_time_hours', 24)
        conversation_history = data.get('conversation_history', '')
        messages = data.get('messages', [])  # NEW: Array of message objects with timestamps
        
        # Calculate actual response times from message logs
        response_times = []
        last_other_time = None
        
        for msg in messages:
            if 'timestamp' in msg and 'isUser' in msg:
                timestamp = msg['timestamp']
                is_user = msg['isUser']
                
                if not is_user:  # Their message
                    last_other_time = timestamp
                elif is_user and last_other_time:  # Your response
                    # Calculate time between their message and your response
                    try:
                        from datetime import datetime
                        their_time = datetime.fromisoformat(last_other_time.replace('Z', '+00:00'))
                        your_time = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                        diff_hours = (your_time - their_time).total_seconds() / 3600
                        if diff_hours > 0 and diff_hours < 168:  # Within a week
                            response_times.append(diff_hours)
                    except:
                        pass
                    last_other_time = None
        
        # Calculate average response time from actual data
        actual_avg_response = sum(response_times) / len(response_times) if response_times else avg_response_time_hours
        
        # Calculate response consistency (how much it varies)
        response_variance = 0
        if len(response_times) > 1:
            avg = sum(response_times) / len(response_times)
            response_variance = sum((x - avg) ** 2 for x in response_times) / len(response_times)
            response_variance = (response_variance ** 0.5) / avg if avg > 0 else 0  # Coefficient of variation
        
        system_prompt = f"""You are an AI Relationship Health Analyzer using NVIDIA Nemotron intelligence.
Calculate a health score (0-100) for the relationship with {contact_name}.

IMPORTANT CONTEXT ANALYSIS:
- Total messages: {message_count}
- Days since last contact: {days_since_last}
- Actual average response time: {actual_avg_response:.1f} hours
- Response consistency: {"Very consistent" if response_variance < 0.5 else "Variable" if response_variance < 1 else "Very inconsistent"}
- Number of tracked responses: {len(response_times)}

SCORING CRITERIA:
1. **Frequency Score (0-100)**: Message count and interaction density
   - 50+ messages/week = 90-100
   - 20-49 messages/week = 70-89
   - 10-19 messages/week = 50-69
   - 5-9 messages/week = 30-49
   - <5 messages/week = 10-29

2. **Recency Score (0-100)**: Time since last message
   - 0-1 days = 90-100
   - 2-3 days = 70-89
   - 4-7 days = 50-69
   - 8-14 days = 30-49
   - 15-30 days = 10-29
   - 30+ days = 0-9

3. **Engagement Score (0-100)**: Response time quality
   - <2 hours = 90-100 (highly engaged)
   - 2-6 hours = 70-89 (good engagement)
   - 6-24 hours = 50-69 (moderate)
   - 24-48 hours = 30-49 (slow)
   - 48+ hours = 10-29 (very slow)
   - If response times are inconsistent (high variance), reduce score by 10-20 points

4. **Warmth Score (0-100)**: Emotional tone and conversation depth
   - Analyze message content for warmth, empathy, humor
   - Look for personal questions, follow-ups, emojis
   - Detect genuine interest vs transactional communication

5. **Diversity Score (0-100)**: Topic variety
   - Multiple topics discussed = 80-100
   - Few topics but deep = 60-79
   - Repetitive topics = 40-59
   - Only logistics/brief = 20-39

INTELLIGENCE FACTORS:
- If response time is >24 hours on average, flag as "needs attention"
- If days since last message >7, recommend reaching out
- If message count is low but recent, still growing relationship
- If response times are getting slower over time, relationship weakening

Return ONLY valid JSON:
{{
  "overall_score": 85,
  "breakdown": {{
    "frequency_score": 80,
    "recency_score": 70,
    "engagement_score": 90,
    "diversity_score": 85,
    "warmth_score": 88
  }},
  "status": "excellent|good|fair|needs_attention",
  "insights": [
    "Your response time is {actual_avg_response:.1f} hours - [analysis here]",
    "[Contextual insight based on conversation patterns]",
    "[Specific observation about relationship dynamic]"
  ],
  "suggestions": [
    "[Actionable suggestion based on the data]",
    "[Time-sensitive recommendation if needed]"
  ],
  "relationship_trend": "improving|stable|declining",
  "priority_level": "high|medium|low"
}}"""

        user_prompt = f"""Analyze relationship health with {contact_name}:

MESSAGE TIMING ANALYSIS:
- Total messages exchanged: {message_count}
- Days since last contact: {days_since_last}
- Your actual average response time: {actual_avg_response:.1f} hours
- Response time consistency: {response_variance:.2f} (0=perfect, >1=very inconsistent)
- Tracked response samples: {len(response_times)}

RECENT CONVERSATION SAMPLE:
{conversation_history[:1500]}

DETAILED INSTRUCTIONS:
1. Use the ACTUAL response time data ({actual_avg_response:.1f} hours) not the generic average
2. If response times are >24 hours, decrease engagement score significantly
3. If days_since_last >7, decrease recency score and flag as needs attention
4. Analyze conversation depth and emotional warmth from the text
5. Provide specific, actionable insights based on this person's communication pattern

Calculate comprehensive health score with context-aware intelligence."""
        
        result = call_ai(system_prompt, user_prompt)
        
        if result:
            try:
                parsed = json.loads(result)
                
                # Log the analysis for future improvement
                print(f"\n🧠 Health Score Analysis for {contact_name}:")
                print(f"   Score: {parsed.get('overall_score', 'N/A')}/100")
                print(f"   Status: {parsed.get('status', 'N/A')}")
                print(f"   Trend: {parsed.get('relationship_trend', 'N/A')}")
                print(f"   Avg Response: {actual_avg_response:.1f}h")
                
                return jsonify({
                    'success': True,
                    'data': parsed
                })
            except json.JSONDecodeError:
                # Fallback calculation with intelligence
                base_score = 100
                
                # Recency penalty (aggressive)
                if days_since_last > 30:
                    base_score -= 50
                elif days_since_last > 14:
                    base_score -= 35
                elif days_since_last > 7:
                    base_score -= 20
                elif days_since_last > 3:
                    base_score -= 10
                
                # Response time penalty (context-aware)
                if actual_avg_response > 48:
                    base_score -= 30
                elif actual_avg_response > 24:
                    base_score -= 20
                elif actual_avg_response > 12:
                    base_score -= 10
                
                # Frequency bonus
                if message_count > 100:
                    base_score += 10
                elif message_count < 20:
                    base_score -= 10
                
                base_score = max(min(base_score, 100), 20)  # Clamp 20-100
                
                status = 'excellent' if base_score >= 80 else 'good' if base_score >= 60 else 'fair' if base_score >= 40 else 'needs_attention'
                
                return jsonify({
                    'success': True,
                    'data': {
                        'overall_score': base_score,
                        'status': status,
                        'insights': [
                            f'Average response time: {actual_avg_response:.1f} hours',
                            f'Last contact: {days_since_last} days ago',
                            f'Total messages: {message_count}'
                        ],
                        'suggestions': [
                            'Reach out soon!' if days_since_last > 7 else 'Keep up the conversation!',
                            'Try to respond faster' if actual_avg_response > 24 else 'Good response time!'
                        ],
                        'relationship_trend': 'stable',
                        'priority_level': 'high' if days_since_last > 7 or actual_avg_response > 24 else 'medium'
                    }
                })
        else:
            return jsonify({
                'success': False,
                'error': 'AI unavailable'
            }), 500
            
    except Exception as e:
        print(f"❌ Health score error: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# ============================================================================
# NEW AI AGENT: CONTEXT RECALL
# ============================================================================

@app.route('/agent/context_recall', methods=['POST', 'OPTIONS'])
def agent_context_recall():
    """
    Surfaces relevant context from past conversations
    Shows reminders about important topics/events
    """
    if request.method == 'OPTIONS':
        return jsonify({'status': 'ok'}), 200
    
    try:
        data = request.json
        contact_name = data.get('contact_name', '')
        conversation_history = data.get('conversation_history', '')
        
        system_prompt = f"""You are a Context Recall Agent.
Analyze the conversation history with {contact_name} and surface:
1. Important topics they mentioned recently
2. Upcoming events/dates
3. Things they're working on/worried about
4. Good follow-up questions

Return ONLY valid JSON:
{{
  "reminders": [
    {{"type": "event", "text": "She mentioned job interview last week", "priority": "high"}},
    {{"type": "topic", "text": "Planning vacation to Japan", "priority": "medium"}},
    {{"type": "concern", "text": "Stressed about work deadline", "priority": "high"}}
  ],
  "suggested_questions": [
    "How did your job interview go?",
    "Any updates on the Japan trip?",
    "Hope work is less stressful now!"
  ],
  "key_facts": [
    "Lactose intolerant - avoid suggesting dairy restaurants",
    "Loves hiking - suggest outdoor activities",
    "Has a dog named Max"
  ]
}}"""

        user_prompt = f"""Recall important context from conversation with {contact_name}:

{conversation_history}

Surface relevant reminders and suggestions."""
        
        result = call_ai(system_prompt, user_prompt)
        
        if result:
            try:
                parsed = json.loads(result)
                return jsonify({
                    'success': True,
                    'data': parsed
                })
            except json.JSONDecodeError:
                return jsonify({
                    'success': True,
                    'data': {
                        'reminders': [],
                        'suggested_questions': ['How have you been?'],
                        'key_facts': []
                    }
                })
        else:
            return jsonify({
                'success': False,
                'error': 'AI unavailable'
            }), 500
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# ============================================================================
# NEW AI AGENT: SMART NOTIFICATION MANAGER
# ============================================================================

@app.route('/agent/smart_notifications', methods=['POST', 'OPTIONS'])
def agent_smart_notifications():
    """
    Intelligent notification timing based on texting patterns using Nvidia Nemotron
    
    Logic:
    - Frequent contacts (text often): Notify if no reply within hours/1 day
    - Occasional contacts: Notify after 3-5 days
    - Rare contacts: Notify after 1-2 weeks
    
    Uses NVIDIA Nemotron GPU to understand relationship patterns
    """
    if request.method == 'OPTIONS':
        return jsonify({'status': 'ok'}), 200
    
    try:
        data = request.json
        contact_name = data.get('contact_name', '')
        message_count = data.get('message_count', 0)
        days_since_last_message = data.get('days_since_last_message', 0)
        avg_messages_per_week = data.get('avg_messages_per_week', 0)
        last_message_from = data.get('last_message_from', 'them')  # 'me' or 'them'
        conversation_history = data.get('conversation_history', '')
        
        system_prompt = f"""You are Atlas's Smart Notification Manager powered by NVIDIA Nemotron.

Your job is to intelligently decide when to send notifications based on texting patterns.

Analyze these patterns:
- Contact: {contact_name}
- Total messages: {message_count}
- Days since last message: {days_since_last_message}
- Average messages per week: {avg_messages_per_week}
- Last message from: {last_message_from}

RULES:
1. FREQUENT CONTACTS (>10 msgs/week):
   - If I sent last message & no reply for 1 day → Notify HIGH priority
   - If they sent last message & I haven't replied for 6 hours → Notify URGENT
   
2. OCCASIONAL CONTACTS (3-10 msgs/week):
   - If I sent last message & no reply for 3 days → Notify MEDIUM priority
   - If they sent last message & I haven't replied for 1 day → Notify HIGH
   
3. RARE CONTACTS (<3 msgs/week):
   - If I sent last message & no reply for 7 days → Notify LOW priority
   - If they sent last message & I haven't replied for 3 days → Notify MEDIUM

4. INACTIVE CONTACTS (>14 days no contact):
   - Suggest gentle check-in → Notify LOW priority after 2 weeks

Return ONLY valid JSON:
{{
  "should_notify": true/false,
  "priority": "urgent|high|medium|low",
  "notification_timing": "now|in_6_hours|in_1_day|in_3_days|in_1_week",
  "relationship_type": "frequent|occasional|rare|inactive",
  "notification_message": "Brief reason for notification",
  "suggested_action": "What user should do",
  "reasoning": "Why this timing makes sense based on texting pattern",
  "wait_hours": 0-168 (hours to wait before notifying)
}}"""

        user_prompt = f"""Analyze notification timing for {contact_name}:

Texting Pattern Analysis:
- We exchange {avg_messages_per_week} messages per week on average
- Last message was {days_since_last_message} days ago
- Total message history: {message_count} messages
- Last message sent by: {last_message_from}

Recent conversation context:
{conversation_history[:500]}

Should I notify the user about this conversation? When and why?"""
        
        # Use NVIDIA Nemotron for intelligent analysis
        result = call_ai(system_prompt, user_prompt, use_brev=True)
        
        if result:
            try:
                content = result['choices'][0]['message']['content']
                
                # Extract JSON from response
                if '{' in content:
                    json_start = content.index('{')
                    json_end = content.rindex('}') + 1
                    parsed = json.loads(content[json_start:json_end])
                    
                    return jsonify({
                        'success': True,
                        'data': parsed
                    })
            except json.JSONDecodeError:
                pass
        
        # Fallback: Rule-based notification logic
        relationship_type = 'frequent' if avg_messages_per_week > 10 else \
                           'occasional' if avg_messages_per_week > 3 else \
                           'rare' if avg_messages_per_week > 0 else 'inactive'
        
        should_notify = False
        priority = 'low'
        timing = 'in_1_week'
        wait_hours = 168
        notification_message = ''
        suggested_action = ''
        
        # Apply rules
        if relationship_type == 'frequent':
            if last_message_from == 'me' and days_since_last_message >= 1:
                should_notify = True
                priority = 'high'
                timing = 'now'
                wait_hours = 0
                notification_message = f"{contact_name} hasn't replied in {days_since_last_message} days (unusual for you two)"
                suggested_action = "Send a gentle follow-up"
            elif last_message_from == 'them' and days_since_last_message >= 0.25:  # 6 hours
                should_notify = True
                priority = 'urgent'
                timing = 'now'
                wait_hours = 0
                notification_message = f"You haven't replied to {contact_name} yet (you usually reply quickly)"
                suggested_action = "Reply to their message"
        
        elif relationship_type == 'occasional':
            if last_message_from == 'me' and days_since_last_message >= 3:
                should_notify = True
                priority = 'medium'
                timing = 'now'
                wait_hours = 0
                notification_message = f"No reply from {contact_name} in 3 days"
                suggested_action = "Maybe check in?"
            elif last_message_from == 'them' and days_since_last_message >= 1:
                should_notify = True
                priority = 'high'
                timing = 'now'
                wait_hours = 0
                notification_message = f"{contact_name} sent a message yesterday"
                suggested_action = "Reply when you have time"
        
        elif relationship_type == 'rare':
            if last_message_from == 'me' and days_since_last_message >= 7:
                should_notify = True
                priority = 'low'
                timing = 'now'
                wait_hours = 0
                notification_message = f"Been a week since you messaged {contact_name}"
                suggested_action = "No rush, but maybe follow up?"
            elif last_message_from == 'them' and days_since_last_message >= 3:
                should_notify = True
                priority = 'medium'
                timing = 'now'
                wait_hours = 0
                notification_message = f"{contact_name} messaged 3 days ago"
                suggested_action = "They might be waiting for your reply"
        
        else:  # inactive
            if days_since_last_message >= 14:
                should_notify = True
                priority = 'low'
                timing = 'in_1_week'
                wait_hours = 168
                notification_message = f"Haven't talked to {contact_name} in 2 weeks"
                suggested_action = "Maybe send a friendly check-in?"
        
        return jsonify({
            'success': True,
            'data': {
                'should_notify': should_notify,
                'priority': priority,
                'notification_timing': timing,
                'relationship_type': relationship_type,
                'notification_message': notification_message,
                'suggested_action': suggested_action,
                'reasoning': f"Based on {relationship_type} texting pattern ({avg_messages_per_week} msgs/week)",
                'wait_hours': wait_hours
            }
        })
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# ============================================================================
# 6. KEY DATES AI AGENT 🎂 (NVIDIA Nemotron)
# Analyzes conversation history to extract birthdays, anniversaries, and
# other important dates mentioned in messages
# ============================================================================

@app.route('/agent/key_dates', methods=['POST', 'OPTIONS'])
def key_dates_agent():
    """
    AGENT 4: Key Dates Intelligence
    Extracts and tracks important dates from conversation history
    Analyzes last 20 messages to find birthdays, anniversaries, special events
    """
    if request.method == 'OPTIONS':
        return handle_options('agent/key_dates')
    
    try:
        data = request.get_json()
        contact_name = data.get('contact_name', 'Contact')
        recent_messages = data.get('recent_messages', [])  # List of {text, timestamp, isUser}
        
        print(f"[KEY DATES AGENT] Analyzing {len(recent_messages)} messages for {contact_name}")
        
        # Analyze with AI to find key dates
        system_prompt = """You are a Key Dates Intelligence Agent powered by NVIDIA AI.

Your task: Extract important dates from conversations with extreme accuracy.

CRITICAL RULES:
1. NEVER return "null" - always provide specific values
2. Extract EXACT dates when mentioned (e.g., "March 15th" -> "March 15, 2026")
3. Calculate relative dates precisely (e.g., "next Friday" -> calculate actual date)
4. If year not mentioned, assume upcoming occurrence in 2025/2026
5. Always provide person name (contact's name if about them, or "Contact's [relation]")

Date Types to Find:
- birthday: Personal birthdays
- anniversary: Relationship/work anniversaries  
- graduation: School graduations
- wedding: Wedding events
- trip: Vacations/travel plans
- meeting: Scheduled meetings
- event: Other special events

For EACH date, return this EXACT structure:
{
    "type": "birthday",
    "person": "Sarah" OR "Sarah's brother" (NEVER null),
    "date": "March 15, 2026" (NEVER null - calculate if needed),
    "date_relative": "in 4 months" OR "2 weeks ago" (NEVER null),
    "context": "Exact quote from conversation" (NEVER null),
    "significance": "high" OR "medium" OR "low"
}

Examples:
- "Happy birthday!" -> type: birthday, person: [contact_name], date: [today's date]
- "My birthday is March 15" -> type: birthday, person: [contact_name], date: "March 15, 2026"
- "Brother graduates in June" -> type: graduation, person: "[contact_name]'s brother", date: "June 15, 2025"

Return VALID JSON ONLY:
{
    "dates_found": [...],
    "summary": "Found X dates: [list them]"
}

If NO dates: return empty array with summary "No specific dates mentioned in recent conversation"."""

        # Format messages for analysis
        message_text = "\n".join([
            f"{'User' if msg.get('isUser') else contact_name}: {msg.get('text')}"
            for msg in recent_messages[-20:]  # Analyze last 20 messages
        ])
        
        user_prompt = f"""Contact: {contact_name}
Today's date: November 9, 2025

Recent conversation:
{message_text}

Extract ALL dates with specific values (NO nulls). If you see "my birthday" and it's said recently, extract it as their birthday."""

        result = call_ai(system_prompt, user_prompt, use_brev=False)
        
        if result and 'choices' in result:
            ai_response = result['choices'][0]['message']['content']
            print(f"[KEY DATES AGENT] AI Response: {ai_response[:200]}...")
            
            # Try to parse JSON from response
            try:
                import re
                # Extract JSON from markdown code blocks if present
                json_match = re.search(r'```(?:json)?\s*(\{.*\})\s*```', ai_response, re.DOTALL)
                if json_match:
                    json_str = json_match.group(1)
                else:
                    json_match = re.search(r'\{.*\}', ai_response, re.DOTALL)
                    json_str = json_match.group() if json_match else None
                
                if json_str:
                    dates_data = json.loads(json_str)
                    
                    # Validate and clean data - replace any nulls
                    for date_entry in dates_data.get('dates_found', []):
                        if not date_entry.get('person') or date_entry['person'] == 'null':
                            date_entry['person'] = contact_name
                        if not date_entry.get('date') or date_entry['date'] == 'null':
                            date_entry['date'] = 'Date TBD'
                        if not date_entry.get('date_relative') or date_entry['date_relative'] == 'null':
                            date_entry['date_relative'] = 'Coming up'
                        if not date_entry.get('context') or date_entry['context'] == 'null':
                            date_entry['context'] = 'Mentioned in conversation'
                        
                        # Add icon based on type
                        date_type = date_entry.get('type', '')
                        if 'birthday' in date_type.lower():
                            date_entry['icon'] = '🎂'
                        elif 'anniversary' in date_type.lower():
                            date_entry['icon'] = '💕'
                        elif 'graduation' in date_type.lower():
                            date_entry['icon'] = '🎓'
                        elif 'wedding' in date_type.lower():
                            date_entry['icon'] = '💒'
                        elif 'trip' in date_type.lower() or 'vacation' in date_type.lower():
                            date_entry['icon'] = '✈️'
                        elif 'meeting' in date_type.lower():
                            date_entry['icon'] = '☕'
                        else:
                            date_entry['icon'] = '📅'
                    
                    print(f"[KEY DATES AGENT] Found {len(dates_data.get('dates_found', []))} dates")
                    return jsonify({
                        'success': True,
                        'data': dates_data
                    })
                else:
                    raise ValueError("No JSON found in response")
            except Exception as e:
                print(f"[KEY DATES AGENT] Parse error: {e}")
                dates_data = {
                    "dates_found": [],
                    "summary": "No specific dates detected in conversation"
                }
        
        return jsonify({
            'success': True,
            'data': {
                'dates_found': [],
                'summary': 'No dates detected in recent messages'
            }
        })
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# ========================================
# NEW AI AGENTS - EXPANDED FUNCTIONALITY
# ========================================

@app.route('/agent/conversation_insights', methods=['POST', 'OPTIONS'])
def conversation_insights_agent():
    """
    AGENT 8: Conversation Insights & Patterns
    Deep analysis of conversation dynamics, topics, and relationship evolution
    """
    if request.method == 'OPTIONS':
        return jsonify({'status': 'ok'}), 200
    
    try:
        data = request.get_json()
        contact_name = data.get('contact_name', 'Contact')
        recent_messages = data.get('recent_messages', [])
        
        print(f"[INSIGHTS AGENT] Analyzing conversation patterns for {contact_name}")
        
        system_prompt = """You are a Conversation Insights Agent powered by NVIDIA AI.

Analyze conversation patterns and provide actionable intelligence:

1. TOPIC ANALYSIS:
   - Main topics discussed (work, hobbies, family, goals, etc.)
   - Topic shifts over time
   - Shared interests discovered

2. COMMUNICATION STYLE:
   - Formality level (casual/professional)
   - Emoji usage patterns
   - Response length preferences
   - Humor style compatibility

3. RELATIONSHIP EVOLUTION:
   - How the relationship has changed
   - Moments of deepening connection
   - Areas of growing distance

4. CONVERSATION QUALITY:
   - Depth of conversations (surface vs meaningful)
   - Question-asking patterns
   - Mutual engagement level

5. ACTIONABLE RECOMMENDATIONS:
   - Topics to explore more
   - Communication adjustments
   - Ways to deepen connection

Return JSON:
{
    "topics": {
        "primary": ["work", "travel", "food"],
        "emerging": ["photography", "fitness"],
        "declining": ["gaming"]
    },
    "communication_style": {
        "formality": "casual",
        "emoji_usage": "high",
        "avg_message_length": "medium",
        "humor_compatibility": "high"
    },
    "relationship_trajectory": {
        "trend": "improving",
        "strength": 8.2,
        "key_moments": ["Shared personal story on Oct 15", "Made plans together"],
        "areas_of_concern": []
    },
    "conversation_quality": {
        "depth_score": 7.5,
        "engagement_score": 8.0,
        "reciprocity_score": 7.8
    },
    "recommendations": [
        "Ask about their photography hobby - they mentioned it 3 times",
        "Share more personal stories - they open up when you do",
        "Suggest a video call - text conversations are plateauing"
    ],
    "summary": "Your relationship is strengthening with shared interests in travel and photography. Consider moving to deeper conversations."
}"""

        # Format messages
        message_text = "\n".join([
            f"{'User' if msg.get('isUser') else contact_name}: {msg.get('text')} (at {msg.get('timestamp', 'unknown')})"
            for msg in recent_messages[-50:]  # Analyze more for patterns
        ])
        
        user_prompt = f"""Contact: {contact_name}
Analyze these {len(recent_messages)} messages for patterns and insights:

{message_text}

Provide deep insights and actionable recommendations."""

        result = call_ai(system_prompt, user_prompt, use_brev=False)
        
        if result and 'choices' in result:
            ai_response = result['choices'][0]['message']['content']
            print(f"[INSIGHTS AGENT] Generated insights")
            
            try:
                import re
                json_match = re.search(r'```(?:json)?\s*(\{.*\})\s*```', ai_response, re.DOTALL)
                if json_match:
                    insights_data = json.loads(json_match.group(1))
                else:
                    json_match = re.search(r'\{.*\}', ai_response, re.DOTALL)
                    if json_match:
                        insights_data = json.loads(json_match.group())
                    else:
                        raise ValueError("No JSON found")
                
                return jsonify({
                    'success': True,
                    'data': insights_data
                })
            except Exception as e:
                print(f"[INSIGHTS AGENT] Parse error: {e}")
                return jsonify({
                    'success': True,
                    'data': {
                        'summary': 'Could not generate detailed insights',
                        'recommendations': ['Continue regular communication']
                    }
                })
        
        return jsonify({'success': False, 'error': 'AI response error'}), 500
        
    except Exception as e:
        print(f"[INSIGHTS AGENT] Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/agent/conversation_starter', methods=['POST', 'OPTIONS'])
def conversation_starter_agent():
    """
    AGENT 9: Intelligent Conversation Starters
    Generates personalized ice-breakers and conversation topics based on history
    """
    if request.method == 'OPTIONS':
        return jsonify({'status': 'ok'}), 200
    
    try:
        data = request.get_json()
        contact_name = data.get('contact_name', 'Contact')
        recent_messages = data.get('recent_messages', [])
        days_since_last = data.get('days_since_last_message', 0)
        
        print(f"[STARTER AGENT] Generating conversation starters for {contact_name}")
        
        system_prompt = """You are a Conversation Starter Agent powered by NVIDIA AI.

Generate 5 creative, personalized conversation starters based on conversation history.

RULES:
1. Reference specific past conversations or shared interests
2. Match the tone/formality of the relationship
3. Avoid generic "how are you" - be creative!
4. Consider time since last contact (apologetic if long gap)
5. Include follow-up questions to topics they mentioned

For EACH starter, provide:
- The message text
- The reasoning (why this will work)
- Expected response type
- Risk level (safe/medium/bold)

Categories:
- Callback: Reference something they mentioned
- Shared Interest: About mutual hobbies/topics
- Current Event: Something relevant to them
- Personal: About their life/goals
- Fun: Lighthearted/humorous

Return JSON:
{
    "starters": [
        {
            "message": "Hey! Did you end up trying that new coffee place you mentioned?",
            "reasoning": "They mentioned wanting to try it 2 weeks ago - shows you remember",
            "category": "callback",
            "risk_level": "safe",
            "expected_response": "positive_engagement"
        }
    ],
    "context_note": "It's been 5 days - gentle re-engagement recommended",
    "best_timing": "afternoon - they're usually more responsive then"
}"""

        message_text = "\n".join([
            f"{'User' if msg.get('isUser') else contact_name}: {msg.get('text')}"
            for msg in recent_messages[-30:]
        ])
        
        user_prompt = f"""Contact: {contact_name}
Days since last message: {days_since_last}

Recent conversation history:
{message_text}

Generate 5 personalized conversation starters that will re-engage this relationship."""

        result = call_ai(system_prompt, user_prompt, use_brev=False)
        
        if result and 'choices' in result:
            ai_response = result['choices'][0]['message']['content']
            
            try:
                import re
                json_match = re.search(r'```(?:json)?\s*(\{.*\})\s*```', ai_response, re.DOTALL)
                if json_match:
                    starters_data = json.loads(json_match.group(1))
                else:
                    json_match = re.search(r'\{.*\}', ai_response, re.DOTALL)
                    if json_match:
                        starters_data = json.loads(json_match.group())
                    else:
                        raise ValueError("No JSON")
                
                return jsonify({
                    'success': True,
                    'data': starters_data
                })
            except Exception as e:
                print(f"[STARTER AGENT] Parse error: {e}")
                # Fallback generic starters
                return jsonify({
                    'success': True,
                    'data': {
                        'starters': [
                            {
                                'message': f"Hey {contact_name}! Hope you've been well!",
                                'reasoning': 'Generic but friendly re-engagement',
                                'category': 'personal',
                                'risk_level': 'safe'
                            }
                        ]
                    }
                })
        
        return jsonify({'success': False, 'error': 'AI error'}), 500
        
    except Exception as e:
        print(f"[STARTER AGENT] Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/agent/relationship_forecast', methods=['POST', 'OPTIONS'])
def relationship_forecast_agent():
    """
    AGENT 10: Relationship Trajectory Forecasting
    Predicts future relationship health and provides proactive interventions
    """
    if request.method == 'OPTIONS':
        return jsonify({'status': 'ok'}), 200
    
    try:
        data = request.get_json()
        contact_name = data.get('contact_name', 'Contact')
        historical_health_scores = data.get('health_history', [])  # List of {date, score}
        recent_messages = data.get('recent_messages', [])
        
        print(f"[FORECAST AGENT] Predicting relationship trajectory for {contact_name}")
        
        system_prompt = """You are a Relationship Forecasting Agent powered by NVIDIA AI.

Analyze historical data and current patterns to predict relationship trajectory.

Analyze:
1. Health score trends (improving/declining/stable)
2. Communication frequency patterns
3. Engagement quality over time
4. Warning signs or positive indicators

Provide:
1. 30-day forecast (predicted health score)
2. 90-day forecast
3. Risk factors that could cause decline
4. Protective factors maintaining health
5. Proactive interventions to prevent decline
6. Milestone predictions (when relationship might reach key points)

Return JSON:
{
    "current_health": 75,
    "forecast_30_days": {
        "predicted_score": 72,
        "confidence": "high",
        "trajectory": "slight_decline",
        "reasoning": "Message frequency decreasing, needs intervention"
    },
    "forecast_90_days": {
        "predicted_score": 65,
        "confidence": "medium",
        "trajectory": "moderate_decline"
    },
    "risk_factors": [
        {
            "factor": "Decreasing message frequency",
            "severity": "medium",
            "impact": -5,
            "mitigation": "Schedule regular check-ins"
        }
    ],
    "protective_factors": [
        {
            "factor": "Strong shared interests",
            "strength": "high",
            "leverage": "Suggest activities around shared hobbies"
        }
    ],
    "interventions": [
        {
            "action": "Plan a video call this week",
            "priority": "high",
            "expected_impact": "+8 points",
            "timing": "within 3 days"
        },
        {
            "action": "Send a thoughtful message about their work project",
            "priority": "medium",
            "expected_impact": "+3 points",
            "timing": "today"
        }
    ],
    "milestones": [
        {
            "event": "Risk of relationship becoming distant",
            "predicted_date": "December 15, 2025",
            "prevention_deadline": "November 20, 2025"
        }
    ],
    "summary": "Relationship is stable but showing early decline signs. Proactive engagement in next 2 weeks critical to maintain health."
}"""

        # Format health history
        health_text = "\n".join([
            f"Date: {h.get('date')}, Score: {h.get('score')}"
            for h in historical_health_scores[-10:]  # Last 10 data points
        ])
        
        message_text = "\n".join([
            f"{'User' if msg.get('isUser') else contact_name}: {msg.get('text')}"
            for msg in recent_messages[-20:]
        ])
        
        user_prompt = f"""Contact: {contact_name}

Health Score History:
{health_text if health_text else "Limited history available"}

Recent Messages:
{message_text}

Predict the relationship trajectory and provide proactive interventions."""

        result = call_ai(system_prompt, user_prompt, use_brev=False)
        
        if result and 'choices' in result:
            ai_response = result['choices'][0]['message']['content']
            
            try:
                import re
                json_match = re.search(r'```(?:json)?\s*(\{.*\})\s*```', ai_response, re.DOTALL)
                if json_match:
                    forecast_data = json.loads(json_match.group(1))
                else:
                    json_match = re.search(r'\{.*\}', ai_response, re.DOTALL)
                    if json_match:
                        forecast_data = json.loads(json_match.group())
                    else:
                        raise ValueError("No JSON")
                
                return jsonify({
                    'success': True,
                    'data': forecast_data
                })
            except Exception as e:
                print(f"[FORECAST AGENT] Parse error: {e}")
                return jsonify({
                    'success': True,
                    'data': {
                        'summary': 'Insufficient data for detailed forecast',
                        'interventions': [
                            {
                                'action': 'Maintain regular communication',
                                'priority': 'medium'
                            }
                        ]
                    }
                })
        
        return jsonify({'success': False, 'error': 'AI error'}), 500
        
    except Exception as e:
        print(f"[FORECAST AGENT] Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


if __name__ == '__main__':
    try:
        port = int(os.environ.get('PORT', 5000))
        print("\n" + "="*70)
        print(" ██████╗ ████████╗██╗      █████╗ ███████╗")
        print("██╔═══██╗╚══██╔══╝██║     ██╔══██╗██╔════╝")
        print("███████║   ██║   ██║     ███████║███████╗")
        print("██╔═══██╗  ██║   ██║     ██╔══██║╚════██║")
        print("██║   ██║  ██║   ███████╗██║  ██║███████║")
        print("╚═╝   ╚═╝  ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝")
        print("="*70)
        print("NVIDIA NEMOTRON MULTI-AGENT INTELLIGENCE SYSTEM")
        print("="*70)
        print(f"Port: {port}")
        print(f"NVIDIA API: {'✓ Connected' if NVIDIA_API_KEY != 'your-nvidia-api-key' else '✗ Need Key'}")
        print(f"ElevenLabs Voice: {'✓ Ready' if ELEVENLABS_API_KEY != 'your-elevenlabs-key-here' else '○ Optional'}")
        
        if BREV_SERVER == 'http://localhost':
            print(f"\nMode: NVIDIA API Direct")
            print(f"  → Endpoint: https://integrate.api.nvidia.com")
            print(f"  → Model: {FALLBACK_MODEL}")
        else:
            print(f"\nMode: Brev A100 GPU Server")
            print(f"  → Endpoint: {ORCHESTRATOR_URL}")
            print(f"  → Model: {ORCHESTRATOR_MODEL}")
        
        print("\n" + "="*70)
        print("MULTI-AGENT ARCHITECTURE (10 Specialized AI Agents)")
        print("="*70)
        print("  🤖 AGENT 1: Smart Reply Generator")
        print("     └─ Endpoint: /agent/smart_reply")
        print("     └─ Purpose: Context-aware message suggestions")
        print()
        print("  💚 AGENT 2: Relationship Health Analyzer")
        print("     └─ Endpoint: /agent/relationship_health")
        print("     └─ Purpose: Multi-factor health scoring (0-100)")
        print()
        print("  🔔 AGENT 3: Smart Notification Manager")
        print("     └─ Endpoint: /agent/smart_notifications")
        print("     └─ Purpose: Intelligent timing recommendations")
        print()
        print("  📅 AGENT 4: Key Dates Intelligence")
        print("     └─ Endpoint: /agent/key_dates")
        print("     └─ Purpose: Extract birthdays, events, anniversaries")
        print()
        print("  💭 AGENT 5: Sentiment Tracker")
        print("     └─ Endpoint: /agent/sentiment_analysis")
        print("     └─ Purpose: Emotional trend analysis")
        print()
        print("  📞 AGENT 6: Meeting Booking Agent")
        print("     └─ Endpoint: /auto_book_meeting")
        print("     └─ Purpose: AI-powered scheduling")
        print()
        print("  🎤 AGENT 7: Voice Synthesis (ElevenLabs)")
        print("     └─ Integration: Works with Booking Agent")
        print("     └─ Purpose: Natural voice confirmations")
        print()
        print("  🔍 AGENT 8: Conversation Insights")
        print("     └─ Endpoint: /agent/conversation_insights")
        print("     └─ Purpose: Deep pattern analysis & topic tracking")
        print()
        print("  💬 AGENT 9: Conversation Starter")
        print("     └─ Endpoint: /agent/conversation_starter")
        print("     └─ Purpose: Personalized ice-breakers & re-engagement")
        print()
        print("  📈 AGENT 10: Relationship Forecast")
        print("     └─ Endpoint: /agent/relationship_forecast")
        print("     └─ Purpose: Predictive analytics & proactive interventions")
        print()
        print("="*70)
        print("All agents powered by NVIDIA Nemotron/Llama models")
        print("Ready to demonstrate multi-agent intelligence!")
        print("="*70)
        print("\nStarting Flask server...")
        print("KEEP THIS WINDOW OPEN - Press CTRL+C to stop\n")
        
        app.run(host='0.0.0.0', port=port, debug=False, use_reloader=False, threaded=True)
        
    except KeyboardInterrupt:
        print("\n\n" + "="*70)
        print("Server stopped by user. All agents offline.")
        print("="*70)
    except Exception as e:
        print(f"\n\n{'='*70}")
        print("FATAL ERROR")
        print("="*70)
        print(f"{e}")
        import traceback
        traceback.print_exc()
        print("\n" + "="*70)
        print("Press Enter to exit...")
        input()

        input("Press Enter to exit...")
