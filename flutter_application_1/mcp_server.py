"""
Atlas AI Voice Agent - MCP Server
Integrates Model Context Protocol with ElevenLabs for enhanced AI features
"""

import asyncio
from mcp.server import Server, NotificationOptions
from mcp.server.models import InitializationOptions
import mcp.server.stdio
import mcp.types as types
from anthropic import Anthropic
import os
from datetime import datetime, timedelta
import json

# Initialize Anthropic client
anthropic_client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

# Create MCP server
server = Server("atlas-voice-agent")

# Store conversation context (in-memory for demo, use database in production)
conversation_memory = {}
pending_actions = []
meeting_history = []

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    """List available AI tools"""
    return [
        types.Tool(
            name="analyze_conversation",
            description="Analyze chat conversation for action items, sentiment, and meeting opportunities",
            inputSchema={
                "type": "object",
                "properties": {
                    "contact_name": {
                        "type": "string",
                        "description": "Name of the contact"
                    },
                    "chat_log": {
                        "type": "string",
                        "description": "Full conversation history"
                    },
                    "voice_command": {
                        "type": "string",
                        "description": "Current voice command"
                    }
                },
                "required": ["contact_name", "chat_log", "voice_command"]
            }
        ),
        types.Tool(
            name="smart_schedule",
            description="Find optimal meeting time based on context and preferences",
            inputSchema={
                "type": "object",
                "properties": {
                    "contact_name": {
                        "type": "string",
                        "description": "Name of the contact"
                    },
                    "meeting_type": {
                        "type": "string",
                        "description": "Type of meeting (coffee, lunch, call, etc.)"
                    },
                    "user_preferences": {
                        "type": "object",
                        "description": "User's scheduling preferences"
                    }
                },
                "required": ["contact_name", "meeting_type"]
            }
        ),
        types.Tool(
            name="generate_voice_response",
            description="Generate natural, context-aware voice response for ElevenLabs",
            inputSchema={
                "type": "object",
                "properties": {
                    "user_name": {
                        "type": "string",
                        "description": "User's name (e.g., Heet)"
                    },
                    "contact_name": {
                        "type": "string",
                        "description": "Contact's name"
                    },
                    "action": {
                        "type": "string",
                        "description": "What action was taken"
                    },
                    "details": {
                        "type": "object",
                        "description": "Meeting or action details"
                    }
                },
                "required": ["user_name", "contact_name", "action"]
            }
        ),
        types.Tool(
            name="extract_action_items",
            description="Extract pending action items from conversation",
            inputSchema={
                "type": "object",
                "properties": {
                    "chat_log": {
                        "type": "string",
                        "description": "Conversation to analyze"
                    }
                },
                "required": ["chat_log"]
            }
        ),
        types.Tool(
            name="conversation_summary",
            description="Generate a concise summary of the conversation",
            inputSchema={
                "type": "object",
                "properties": {
                    "contact_name": {
                        "type": "string",
                        "description": "Name of the contact"
                    },
                    "chat_log": {
                        "type": "string",
                        "description": "Full conversation history"
                    }
                },
                "required": ["contact_name", "chat_log"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(
    name: str, arguments: dict | None
) -> list[types.TextContent | types.ImageContent | types.EmbeddedResource]:
    """Handle tool execution"""
    
    if name == "analyze_conversation":
        result = await analyze_conversation(
            arguments.get("contact_name"),
            arguments.get("chat_log"),
            arguments.get("voice_command")
        )
        return [types.TextContent(type="text", text=json.dumps(result, indent=2))]
    
    elif name == "smart_schedule":
        result = await smart_schedule(
            arguments.get("contact_name"),
            arguments.get("meeting_type"),
            arguments.get("user_preferences", {})
        )
        return [types.TextContent(type="text", text=json.dumps(result, indent=2))]
    
    elif name == "generate_voice_response":
        result = await generate_voice_response(
            arguments.get("user_name"),
            arguments.get("contact_name"),
            arguments.get("action"),
            arguments.get("details", {})
        )
        return [types.TextContent(type="text", text=result)]
    
    elif name == "extract_action_items":
        result = await extract_action_items(arguments.get("chat_log"))
        return [types.TextContent(type="text", text=json.dumps(result, indent=2))]
    
    elif name == "conversation_summary":
        result = await conversation_summary(
            arguments.get("contact_name"),
            arguments.get("chat_log")
        )
        return [types.TextContent(type="text", text=result)]
    
    else:
        raise ValueError(f"Unknown tool: {name}")

async def analyze_conversation(contact_name: str, chat_log: str, voice_command: str) -> dict:
    """Analyze conversation using Claude AI"""
    
    prompt = f"""Analyze this conversation and voice command:

Contact: {contact_name}
Voice Command: {voice_command}
Chat History:
{chat_log}

Provide:
1. Sentiment (positive/neutral/negative)
2. Should a meeting be booked? (yes/no)
3. If yes, suggest meeting type and time
4. Any action items mentioned
5. Context summary

Respond in JSON format."""

    try:
        message = anthropic_client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            messages=[{
                "role": "user",
                "content": prompt
            }]
        )
        
        response_text = message.content[0].text
        
        # Try to parse as JSON, fallback to structured response
        try:
            result = json.loads(response_text)
        except:
            result = {
                "sentiment": "positive",
                "needs_booking": "yes" in response_text.lower(),
                "suggested_meeting": {
                    "type": "Meeting",
                    "time": "Tomorrow at 2pm"
                },
                "action_items": [],
                "context": response_text
            }
        
        return result
        
    except Exception as e:
        return {
            "error": str(e),
            "sentiment": "neutral",
            "needs_booking": False
        }

async def smart_schedule(contact_name: str, meeting_type: str, preferences: dict) -> dict:
    """Find optimal meeting time"""
    
    # Simple smart scheduling (can be enhanced with calendar integration)
    now = datetime.now()
    suggestions = []
    
    # Generate 3 smart suggestions
    for i in range(1, 4):
        suggested_time = now + timedelta(days=i)
        
        # Smart time selection based on meeting type
        if meeting_type.lower() == "coffee":
            hour = 10  # Morning coffee
        elif meeting_type.lower() == "lunch":
            hour = 12  # Lunch time
        elif meeting_type.lower() == "dinner":
            hour = 18  # Evening dinner
        else:
            hour = 14  # Default afternoon
        
        suggested_time = suggested_time.replace(hour=hour, minute=0, second=0)
        
        suggestions.append({
            "time": suggested_time.strftime("%A at %I:%M %p"),
            "timestamp": suggested_time.isoformat(),
            "confidence": 0.9 - (i * 0.1),
            "reason": f"Optimal for {meeting_type}"
        })
    
    return {
        "contact": contact_name,
        "meeting_type": meeting_type,
        "suggested_times": suggestions,
        "best_option": suggestions[0]
    }

async def generate_voice_response(
    user_name: str,
    contact_name: str,
    action: str,
    details: dict
) -> str:
    """Generate natural voice response for ElevenLabs"""
    
    meeting_type = details.get("meeting_type", "meeting")
    meeting_time = details.get("suggested_time", "tomorrow")
    
    # Generate contextual response
    if action == "book_meeting":
        response = (
            f"Hi {user_name}! I've scheduled a {meeting_type} with {contact_name} "
            f"for {meeting_time}. I'll send the calendar invite now. "
            f"Is there anything else you'd like me to do?"
        )
    elif action == "analyze":
        response = (
            f"Hi {user_name}! I've analyzed your conversation with {contact_name}. "
            f"The sentiment is {details.get('sentiment', 'positive')}, and I found "
            f"{len(details.get('action_items', []))} action items. Would you like to hear them?"
        )
    elif action == "summarize":
        response = (
            f"Hi {user_name}! Here's a quick summary of your chat with {contact_name}: "
            f"{details.get('summary', 'The conversation covered various topics.')}"
        )
    else:
        response = (
            f"Hi {user_name}! I've completed the requested action for {contact_name}. "
            f"Let me know if you need anything else!"
        )
    
    return response

async def extract_action_items(chat_log: str) -> dict:
    """Extract action items from conversation"""
    
    prompt = f"""Extract all action items, tasks, and follow-ups from this conversation:

{chat_log}

List each action item with:
- What needs to be done
- Who should do it
- Priority (high/medium/low)
- Any mentioned deadline

Respond in JSON format."""

    try:
        message = anthropic_client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            messages=[{
                "role": "user",
                "content": prompt
            }]
        )
        
        response_text = message.content[0].text
        
        try:
            result = json.loads(response_text)
        except:
            result = {
                "action_items": [],
                "raw_response": response_text
            }
        
        return result
        
    except Exception as e:
        return {
            "error": str(e),
            "action_items": []
        }

async def conversation_summary(contact_name: str, chat_log: str) -> str:
    """Generate conversation summary"""
    
    prompt = f"""Summarize this conversation with {contact_name} in 2-3 sentences:

{chat_log}

Focus on:
- Main topics discussed
- Key decisions or agreements
- Next steps

Keep it concise and professional."""

    try:
        message = anthropic_client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=512,
            messages=[{
                "role": "user",
                "content": prompt
            }]
        )
        
        return message.content[0].text
        
    except Exception as e:
        return f"Error generating summary: {str(e)}"

async def main():
    """Run the MCP server"""
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="atlas-voice-agent",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )

if __name__ == "__main__":
    print("🤖 Atlas AI Voice Agent MCP Server starting...")
    print("📡 Waiting for connections...")
    asyncio.run(main())
