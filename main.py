from flask import Flask, jsonify

app = Flask(__name__)

# This is a "mock" endpoint for the conversational AI
# The Flutter app will send a POST request here
@app.route('/ask_atlas', methods=['POST'])
def ask_atlas():
    # We add a print statement so you can see it working in the Replit console
    print("LOG: The /ask_atlas endpoint was called!")
    
    # We send back a fake, pre-written JSON response
    return jsonify({
        "reply_text": "This is a mock response from the Atlas server! The brain is not connected yet, but I can hear you.",
        "reply_audio_url": "https_path_to_a_fake_mp3" 
    })

# This is the "mock" endpoint for getting proactive suggestions
# The Flutter app will send a GET request here
@app.route('/get_suggestions', methods=['GET'])
def get_suggestions():
    print("LOG: The /get_suggestions endpoint was called!")
    
    # Send a fake, pre-written suggestion
    return jsonify({
        "suggestion_id": "123",
        "title": "Policy Gap: 'John Smith'",
        "text": "It's been 28 days since your last high-quality interaction.",
        "type": "proactive_alert"
    })

# This line tells Replit how to run the app
if __name__ == '__main__':
    # host='0.0.0.0' makes it publicly available
    app.run(host='0.0.0.0', port=8080)
