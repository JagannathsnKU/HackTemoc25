# Atlas Auto-Agent System - Quick Start
# Run this script after deploying Brev NIMs

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "  ATLAS AUTO-AGENT SYSTEM" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Get user inputs
$brevIP = Read-Host "Enter your Brev Server IP (from: curl ifconfig.me)"
$elevenLabsKey = Read-Host "Enter your ElevenLabs API Key (or press Enter to skip)"

Write-Host ""
Write-Host "Configuration complete!" -ForegroundColor Green
Write-Host ""

# Set environment variables
$env:BREV_SERVER_URL = "http://$brevIP"
$env:NVIDIA_API_KEY = "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"
if ($elevenLabsKey) {
    $env:ELEVENLABS_API_KEY = $elevenLabsKey
} else {
    $env:ELEVENLABS_API_KEY = "your-elevenlabs-key-here"
}
$env:FLASK_APP = "main_auto.py"

Write-Host "Environment Variables Set:" -ForegroundColor Yellow
Write-Host "   Brev Server: http://$brevIP" -ForegroundColor White
Write-Host "   NVIDIA API: Connected" -ForegroundColor White
Write-Host "   ElevenLabs: $(if ($elevenLabsKey) { 'Connected' } else { 'Skipped' })" -ForegroundColor White
Write-Host ""

Write-Host "Starting Atlas Auto-Agent System..." -ForegroundColor Green
Write-Host ""

# Start the server
python -m flask run --host=0.0.0.0 --port=5000
