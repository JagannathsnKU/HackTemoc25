# Atlas Backend Startup Script
# Replace YOUR_NVIDIA_API_KEY_HERE with your actual key from build.nvidia.com

$env:NVIDIA_API_KEY = "YOUR_NVIDIA_API_KEY_HERE"
$env:FLASK_APP = "main.py"

Write-Host "🚀 Starting Atlas Backend Server..." -ForegroundColor Green
Write-Host "📡 Server will run on http://localhost:5000" -ForegroundColor Cyan
Write-Host "⚠️  Make sure to replace YOUR_NVIDIA_API_KEY_HERE with your real key!" -ForegroundColor Yellow
Write-Host ""

C:/Users/HEET/Downloads/HackTemoc25/flutter_application_1/.venv/Scripts/python.exe -m flask run --host=0.0.0.0 --port=5000
