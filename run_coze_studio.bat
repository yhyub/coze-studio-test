@echo off
chcp 65001 > nul
echo ============================================
echo Coze Studio 启动脚本
echo ============================================
echo 正在以管理员身份运行PowerShell脚本...
echo ============================================

:: 以管理员身份运行PowerShell脚本
pwsh -Command "Start-Process pwsh -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0coze_studio_full_fix.ps1\"' -Verb RunAs"

:: 等待用户按任意键退出
echo.
echo 脚本已启动，请在新打开的管理员窗口中查看执行结果
echo.
echo ============================================
echo 提示：
echo 1. 首次启动可能需要3-5分钟时间
echo 2. 请确保Docker Desktop已完全启动
echo 3. 服务启动后访问 http://localhost:8888
echo ============================================
pause