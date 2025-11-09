# Atlas AI MCP Server Startup Script (with Google Gemini)
# This script starts the Model Context Protocol (MCP) Flask server

Write-Host ""
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "    🤖 Atlas AI - MCP Server with Gemini" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "❌ Error: .env file not found!" -ForegroundColor Red
    Write-Host "Please create a .env file with your Gemini API key" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Get FREE API key: https://aistudio.google.com/app/apikey" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host "✨ Features:" -ForegroundColor Yellow
Write-Host "   • AI Conversation Analysis (Sentiment, Context)" -ForegroundColor White
Write-Host "   • Smart Meeting Detection" -ForegroundColor White
Write-Host "   • Action Items Extraction" -ForegroundColor White
Write-Host "   • Conversation Summaries" -ForegroundColor White
Write-Host "   • Personalized Voice Responses" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Server URL: http://localhost:5001" -ForegroundColor Cyan
Write-Host "🤖 AI Model: Google Gemini 1.5 Flash (FREE!)" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Setup Instructions:" -ForegroundColor Yellow
Write-Host "   1. Get FREE API key: https://aistudio.google.com/app/apikey" -ForegroundColor White
Write-Host "   2. Add to .env: GEMINI_API_KEY=AIza..." -ForegroundColor White
Write-Host "   3. Run this script" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Starting server..." -ForegroundColor Green
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Start the Flask server
python mcp_flask_server.py
