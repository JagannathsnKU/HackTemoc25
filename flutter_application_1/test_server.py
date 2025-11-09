from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/test', methods=['GET'])
def test():
    return jsonify({"status": "ok", "message": "Server is running!"})

if __name__ == '__main__':
    print("Starting test server on port 5000...")
    app.run(host='0.0.0.0', port=5000, debug=False, use_reloader=False)
    print("Server stopped")
