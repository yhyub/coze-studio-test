@echo off
setlocal enabledelayedexpansion

echo ============================================
echo Docker WSL 配置工具 - 2026年安全可靠版本
echo ============================================
echo.

:: 检查WSL是否安装
wsl --list >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误：未安装WSL或WSL版本过低
    echo 请先安装WSL 2：wsl --install
    pause
    exit /b 1
)

:: 检查Ubuntu发行版
wsl --list | findstr /i ubuntu >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误：未找到Ubuntu发行版
    echo 请安装Ubuntu：wsl --install -d Ubuntu
    pause
    exit /b 1
)

echo 1. 停止并重启WSL服务以修复网络问题...
wsl --shutdown
echo 正在重启WSL服务...
timeout /t 3 /nobreak >nul

:: 配置DNS和Docker镜像源
echo 2. 配置WSL Ubuntu的DNS和Docker镜像源...
wsl -d Ubuntu -e bash -c "echo 'nameserver 114.114.114.114' | sudo tee /etc/resolv.conf > /dev/null"
wsl -d Ubuntu -e bash -c "sudo mkdir -p /etc/docker > /dev/null"
wsl -d Ubuntu -e bash -c "echo '{\"registry-mirrors\": [\"https://mirror.aliyuncs.com\", \"https://hub-mirror.c.163.com\", \"https://mirrors.ustc.edu.cn/dockerhub/\"]}' | sudo tee /etc/docker/daemon.json > /dev/null"

:: 重启Docker服务
echo 3. 重启Docker服务...
wsl -d Ubuntu -e bash -c "sudo systemctl restart docker > /dev/null 2>&1 || true"

:: 测试网络连接
echo 4. 测试网络连接...
wsl -d Ubuntu -e bash -c "ping -c 2 www.baidu.com > /dev/null"
if %errorlevel% equ 0 (
    echo 网络连接正常
) else (
    echo 警告：网络连接可能存在问题，但将继续配置
)

:: 测试Docker运行
echo 5. 测试Docker运行状态...
wsl -d Ubuntu -e bash -c "sudo docker info > /dev/null 2>&1"
if %errorlevel% equ 0 (
    echo Docker服务运行正常
) else (
    echo 错误：Docker服务未正常运行
    echo 请检查WSL中的Docker安装：sudo apt update && sudo apt install -y docker.io
    pause
    exit /b 1
)

echo.
echo ============================================
echo 配置完成！
echo ============================================
echo 您可以使用以下命令在WSL中使用Docker：
echo wsl -d Ubuntu -e bash -c "sudo docker [命令]"
echo.
echo 例如：
echo wsl -d Ubuntu -e bash -c "sudo docker run hello-world"
echo wsl -d Ubuntu -e bash -c "sudo docker pull ubuntu"
echo.
echo 已配置的安全可靠镜像源：
echo - https://mirror.aliyuncs.com (阿里云官方)
echo - https://hub-mirror.c.163.com (网易官方)
echo - https://mirrors.ustc.edu.cn/dockerhub/ (中国科技大学)
echo ============================================

pause
