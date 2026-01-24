@echo off
echo Coze Studio 自动化修复启动器
echo ===============================
echo 正在以管理员身份运行修复脚本...
echo 请稍候，这个过程可能需要几分钟时间...

:: 以管理员身份运行PowerShell脚本
powershell -Command "Start-Process 'powershell' -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0coze_studio_auto_fix.ps1\"' -Verb RunAs -Wait"

echo ===============================
echo 修复脚本执行完成！
echo 请查看脚本输出结果
echo ===============================
pause