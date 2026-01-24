@echo off
echo Coze Studio Auto Fix Launcher
echo ===============================
echo Running fix script as administrator...
echo Please wait, this process may take several minutes...

:: Run PowerShell script as administrator
powershell -Command "Start-Process 'powershell' -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0coze_studio_auto_fix.ps1\"' -Verb RunAs -Wait"

echo ===============================
echo Fix script execution completed!
echo Please check the script output
echo ===============================
pause