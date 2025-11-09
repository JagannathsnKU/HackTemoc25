@echo off
chcp 65001 >nul
cls
echo ============================================================
echo  ATLAS AI BACKEND - Nemotron on Brev Server
echo ============================================================
echo.
echo Starting server... Please wait and KEEP THIS WINDOW OPEN!
echo.
python main_auto.py
echo.
echo ============================================================
echo Server stopped! Press any key to close this window.
echo ============================================================
pause >nul
