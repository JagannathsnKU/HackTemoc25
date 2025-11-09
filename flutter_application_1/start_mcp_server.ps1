# Start MCP Flask Server for Atlas AI Voice Agent

Write-Host "🤖 Starting Atlas AI MCP Flask Server..." -ForegroundColor Cyan
Write-Host ""

# Check if .env file exists
if (Test-Path ".env") {
    Write-Host "✅ Found .env file" -ForegroundColor Green
} else {
    Write-Host "⚠️  Warning: .env file not found" -ForegroundColor Yellow
    Write-Host "   Create .env file and add your ANTHROPIC_API_KEY" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📡 MCP Server will run on: http://localhost:5001" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available AI Features:" -ForegroundColor Green
Write-Host "  ✨ Conversation Analysis (Claude AI)" -ForegroundColor White
Write-Host "  📅 Smart Scheduling Suggestions" -ForegroundColor White
Write-Host "  🎙️  Personalized Voice Responses" -ForegroundColor White
Write-Host "  ✅ Action Item Extraction" -ForegroundColor White
Write-Host "  📝 Conversation Summaries" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Start the Flask server
python mcp_flask_server.py
