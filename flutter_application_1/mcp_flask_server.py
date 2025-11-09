"""
MCP Flask Server for Atlas AI Voice Agent
Provides AI-powered conversation analysis, smart scheduling, and voice response generation
using Google Gemini AI
"""

import os
from flask import Flask, request, jsonify
from flask_cors import CORS
import google.generativeai as genai
from datetime import datetime, timedelta
import json
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Initialize Gemini client
gemini_api_key = os.getenv("GEMINI_API_KEY", "")
if gemini_api_key:
    genai.configure(api_key=gemini_api_key)
    model = genai.GenerativeModel('gemini-1.5-flash')
else:
    model = None

# In-memory storage
conversation_memory = {}
pending_actions = []
meeting_history = []

@app.route('/')
def home():
    """Health check endpoint"""
    return jsonify({
        "status": "running",
        "service": "Atlas AI MCP Server",
        "version": "1.0.0",
        "gemini_available": model is not None
    })

@app.route('/analyze_conversation', methods=['POST'])
def analyze_conversation():
    """
    Analyze a conversation using Gemini AI
    Returns: sentiment, meeting_needs, action_items, context_summary
    """
    if not model:
        return jsonify({"error": "Gemini API key not configured"}), 400
    
    data = request.json
    contact_name = data.get('contact_name', 'Unknown')
    messages = data.get('messages', [])
    
    # Format messages for Gemini
    conversation_text = "\n".join([
        f"{'User' if msg.get('isUser') else contact_name}: {msg.get('text', '')}"
        for msg in messages
    ])
    
    try:
        prompt = f"""Analyze this conversation and provide:
1. Sentiment (positive/neutral/negative)
2. Meeting needs (does the user need to schedule a meeting? yes/no)
3. Action items (what needs to be done?)
4. Context summary (2-3 sentences)

Conversation with {contact_name}:
{conversation_text}

Respond in JSON format with keys: sentiment, meeting_needs, action_items (array), context_summary"""

        response = model.generate_content(prompt)
        result_text = response.text
        
        # Try to extract JSON from the response
        try:
            # Gemini might wrap JSON in markdown code blocks
            if "```json" in result_text:
                result_text = result_text.split("```json")[1].split("```")[0].strip()
            elif "```" in result_text:
                result_text = result_text.split("```")[1].split("```")[0].strip()
            
            result = json.loads(result_text)
        except:
            # Fallback if JSON parsing fails
            result = {
                "sentiment": "neutral",
                "meeting_needs": "Unable to determine",
                "action_items": [],
                "context_summary": result_text[:200]
            }
        
        return jsonify(result)
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/smart_schedule', methods=['POST'])
def smart_schedule():
    """
    Suggest optimal meeting times based on meeting type and context
    """
    data = request.json
    meeting_type = data.get('meeting_type', 'appointment')
    contact_name = data.get('contact_name', 'Unknown')
    context = data.get('context', '')
    
    # Smart time suggestions based on meeting type
    suggestions = {
        'coffee': ['10:00 AM', '2:00 PM', '3:00 PM'],
        'lunch': ['12:00 PM', '12:30 PM', '1:00 PM'],
        'dinner': ['6:00 PM', '7:00 PM', '7:30 PM'],
        'call': ['9:00 AM', '2:00 PM', '4:00 PM'],
        'video': ['10:00 AM', '2:00 PM', '3:00 PM'],
        'appointment': ['9:00 AM', '2:00 PM', '3:00 PM'],
        'sync': ['9:00 AM', '10:00 AM', '2:00 PM'],
        'review': ['10:00 AM', '2:00 PM', '4:00 PM']
    }
    
    suggested_times = suggestions.get(meeting_type.lower(), suggestions['appointment'])
    
    # Generate dates for next 3 days (excluding weekends for business meetings)
    dates = []
    current_date = datetime.now()
    days_added = 0
    while days_added < 3:
        next_date = current_date + timedelta(days=days_added + 1)
        if next_date.weekday() < 5:  # Monday-Friday
            dates.append(next_date.strftime('%A, %B %d'))
        days_added += 1
    
    return jsonify({
        "contact_name": contact_name,
        "meeting_type": meeting_type,
        "suggested_times": suggested_times,
        "suggested_dates": dates,
        "recommendation": f"Best time for {meeting_type} with {contact_name}: {suggested_times[0]} tomorrow"
    })

@app.route('/generate_voice_response', methods=['POST'])
def generate_voice_response():
    """
    Generate personalized voice response script for ElevenLabs
    """
    data = request.json
    user_name = data.get('user_name', 'Heet')
    contact_name = data.get('contact_name', 'Unknown')
    meeting_type = data.get('meeting_type', 'appointment')
    time = data.get('time', 'soon')
    location = data.get('location', '')
    
    # Generate personalized script
    if location:
        script = f"Hi {user_name}! I heard you want to book a {meeting_type} with {contact_name}. I've scheduled it for {time} at {location}."
    else:
        script = f"Hi {user_name}! I heard you want to book a {meeting_type} with {contact_name}. I've scheduled it for {time}."
    
    return jsonify({
        "script": script,
        "user_name": user_name,
        "contact_name": contact_name,
        "meeting_type": meeting_type
    })

@app.route('/extract_action_items', methods=['POST'])
def extract_action_items():
    """
    Extract action items from conversation using Gemini AI
    """
    if not model:
        return jsonify({"error": "Gemini API key not configured"}), 400
    
    data = request.json
    messages = data.get('messages', [])
    contact_name = data.get('contact_name', 'Unknown')
    
    # Format messages for Gemini
    conversation_text = "\n".join([
        f"{'User' if msg.get('isUser') else contact_name}: {msg.get('text', '')}"
        for msg in messages
    ])
    
    try:
        prompt = f"""Extract action items from this conversation. For each action item, provide:
- task: what needs to be done
- priority: high/medium/low
- deadline: if mentioned, otherwise "Not specified"
- assigned_to: user or contact name

Conversation:
{conversation_text}

Respond in JSON format with key "action_items" containing an array of tasks."""

        response = model.generate_content(prompt)
        result_text = response.text
        
        try:
            if "```json" in result_text:
                result_text = result_text.split("```json")[1].split("```")[0].strip()
            elif "```" in result_text:
                result_text = result_text.split("```")[1].split("```")[0].strip()
            
            result = json.loads(result_text)
        except:
            result = {"action_items": []}
        
        return jsonify(result)
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/conversation_summary', methods=['POST'])
def conversation_summary():
    """
    Generate a concise summary of the conversation
    """
    if not model:
        return jsonify({"error": "Gemini API key not configured"}), 400
    
    data = request.json
    messages = data.get('messages', [])
    contact_name = data.get('contact_name', 'Unknown')
    
    # Format messages for Gemini
    conversation_text = "\n".join([
        f"{'User' if msg.get('isUser') else contact_name}: {msg.get('text', '')}"
        for msg in messages
    ])
    
    try:
        prompt = f"""Summarize this conversation in 2-3 sentences. Focus on key topics and any decisions made.

Conversation with {contact_name}:
{conversation_text}"""

        response = model.generate_content(prompt)
        summary = response.text.strip()
        
        return jsonify({
            "contact_name": contact_name,
            "summary": summary,
            "message_count": len(messages)
        })
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    print("🤖 Atlas AI MCP Flask Server starting...")
    print(f"📡 Google Gemini AI: {'✅ Connected' if model else '❌ API key not found'}")
    print("🌐 Server running on http://localhost:5001")
    print("\nAvailable endpoints:")
    print("  GET  / - Health check")
    print("  POST /analyze_conversation - Analyze conversation with Gemini")
    print("  POST /smart_schedule - Get smart scheduling suggestions")
    print("  POST /generate_voice_response - Generate personalized voice scripts")
    print("  POST /extract_action_items - Extract action items from chat")
    print("  POST /conversation_summary - Get conversation summary")
    
    app.run(host='0.0.0.0', port=5001, debug=True)
