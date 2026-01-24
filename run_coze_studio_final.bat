@echo off
chcp 65001 > nul
echo ============================================
echo 最终 Coze Studio 启动解决方案
echo ============================================
echo 正在以管理员身份运行 PowerShell 脚本...
echo ============================================

:: 以管理员身份运行 PowerShell 脚本
pwsh -Command "Start-Process pwsh -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0final_coze_studio_solution.ps1\"' -Verb RunAs"

echo.
echo 脚本已启动，请在新打开的管理员窗口中查看执行结果
echo.
echo ============================================
echo 📋 执行步骤:
echo 1. 运行磁盘维护工具
echo 2. 修复 Docker 服务
echo 3. 配置 WSL
echo 4. 启动 Coze Studio 服务
echo 5. 验证访问 http://localhost:8888
echo ============================================
echo 💡 提示:
echo - 首次启动可能需要 3-5 分钟时间
echo - 请确保 Docker Desktop 已完全启动
echo - 服务启动后访问 http://localhost:8888
echo ============================================
pause