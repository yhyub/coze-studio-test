@echo off
chcp 65001 > nul
echo ============================================
echo Coze Studio Launch Script
echo ============================================
echo Running PowerShell script as Administrator...
echo ============================================

:: Run PowerShell script as Administrator
pwsh -Command "Start-Process pwsh -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0coze_studio_full_fix.ps1\"' -Verb RunAs"

:: Wait for user input
echo.
echo Script started. Please check the new admin window for results.
echo.
echo ============================================
echo Tips:
echo 1. First launch may take 3-5 minutes
echo 2. Ensure Docker Desktop is fully started
echo 3. Access Coze Studio at http://localhost:8888
echo ============================================
pause