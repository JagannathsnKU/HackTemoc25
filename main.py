import os
from flask import Flask, jsonify, request
from openai import OpenAI  # Use the OpenAI library, just as the PDF shows

app = Flask(__name__)

# --- 1. SET UP YOUR "BRAIN" (NEMOTRON API) ---
# Get your secrets from Render's "Environment" tab
NVIDIA_API_KEY = os.environ.get('NVIDIA_API_KEY')
NVIDIA_BASE_URL = os.environ.get('NVIDIA_BASE_URL') # This is "https://integrate.api.nvidia.com/v1"

# This creates the "client" for the Nemotron brain
# This is the code from Page 4 of your PDF [cite: 61-65]
client = OpenAI(
  base_url = NVIDIA_BASE_URL,
  api_key = NVIDIA_API_KEY
)

# --- 2. THE "CONVERSATIONAL ORCHESTRATOR" AGENT ---
# This is your main chat endpoint.
@app.route('/ask_atlas', methods=['POST'])
def ask_atlas():
    # Get the user's prompt from your Flutter app
    user_prompt = request.json.get('prompt')

    try:
        # 1. This is the "Multi-step workflow" (Source 11)
        # We send the prompt to the Nemotron "Brain"
        print(f"Calling Nemotron brain with prompt: {user_prompt}")

        completion = client.chat.completions.create(
          model="nvidia/nvidia-nemotron-nano-9b-v2", # Model from PDF [cite: 68]
          messages=[
              {"role": "system", "content": "You are Atlas, an autonomous 'Chief of Staff' for relationships. Your job is to plan and execute tasks based on the user's 'Social Policy'. First, you must reason and plan. Then, you must call tools. Finally, you must respond to the user."},
              {"role": "user", "content": user_prompt}
          ]
          # We will add "tools" here soon
        )
        
        # 2. Get the AI's response
        ai_reply = completion.choices[0].message.content
        
        # 3. Send the real AI's answer back to the Flutter app
        return jsonify({"reply_text": ai_reply})

    except Exception as e:
        print(f"Error calling NVIDIA API: {e}")
        return jsonify({"reply_text": "Sorry, my 'brain' (NVIDIA API) is not connected."}), 500

# --- 3. THE "GATEWAY" TOOLS (MOCKED) ---
# These are the "tools" your Nemotron agent will learn to call.
# For the hackathon, we will just mock their responses.

@app.route('/tools/get_google_calendar_events', methods=['POST'])
def tool_get_calendar():
    # In a real app, this would use Auth0 + Google API
    print("LOG: 'Scout' agent called the Google Calendar tool.")
    return jsonify({
        "events": [
            {"name": "Dinner with John", "date": "60 days ago"},
            {"name": "John's Birthday", "date": "in 14 days"}
        ]
    })

@app.route('/tools/get_social_photos', methods=['POST'])
def tool_get_photos():
    print("LOG: 'Scout' agent called the Google Photos tool.")
    return jsonify({
        "photos": [
            {"url": "fake_photo_url_1.jpg", "caption": "Hiking at Arbor Hills"},
            {"url": "fake_photo_url_2.jpg", "caption": "Cowboys Game"}
        ]
    })

# This is the "main" part that runs the server
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
