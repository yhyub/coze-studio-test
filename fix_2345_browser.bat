@echo off
echo === 2345浏览器修复工具 ===
echo.

:: 1. 修复hosts文件，添加GitHub相关IP条目
echo 1. 修复hosts文件，添加GitHub相关IP条目
echo.

:: 定义GitHub相关IP条目
set "githubHosts=# GitHub访问优化（修复2345浏览器访问问题）
140.82.114.3 github.com
140.82.114.4 gist.github.com
185.199.108.153 assets-cdn.github.com
185.199.109.153 assets-cdn.github.com
185.199.110.153 assets-cdn.github.com
185.199.111.153 assets-cdn.github.com
199.232.69.194 github.global.ssl.fastly.net
140.82.114.9 codeload.github.com
140.82.114.10 api.github.com
185.199.111.133 raw.githubusercontent.com
185.199.110.133 raw.githubusercontent.com
185.199.109.133 raw.githubusercontent.com
185.199.108.133 raw.githubusercontent.com"

:: 检查hosts文件中是否已有GitHub条目
findstr /C:"# GitHub访问优化" C:\windows\System32\drivers\etc\hosts >nul
if %errorlevel% neq 0 (
    echo 添加GitHub hosts条目...
    echo %githubHosts% >> C:\windows\System32\drivers\etc\hosts
    echo 成功添加GitHub hosts条目
) else (
    echo GitHub hosts条目已存在
)

echo.

:: 2. 清除DNS缓存和网络缓存
echo 2. 清除DNS缓存和网络缓存
ipconfig /flushdns >nul
netsh winsock reset >nul
netsh int ip reset >nul
echo 成功清除DNS缓存、重置Winsock和TCP/IP
echo.

:: 3. 重置2345浏览器代理设置
echo 3. 重置系统代理设置
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /t REG_SZ /d "<local>" /f >nul
echo 成功重置系统代理设置
echo.

:: 4. 验证GitHub访问
echo 4. 验证GitHub访问
ping github.com -n 2 >nul
if %errorlevel% equ 0 (
    echo GitHub连接正常
) else (
    echo GitHub连接失败
)
echo.

:: 5. 尝试启动2345浏览器
echo 5. 尝试启动2345浏览器

:: 检查2345浏览器路径
set "browserPath="
if exist "C:\Program Files (x86)\2345Soft\2345Explorer\2345Explorer.exe" (
    set "browserPath=C:\Program Files (x86)\2345Soft\2345Explorer\2345Explorer.exe"
) else if exist "C:\Program Files\2345Soft\2345Explorer\2345Explorer.exe" (
    set "browserPath=C:\Program Files\2345Soft\2345Explorer\2345Explorer.exe"
)

if not "%browserPath%" == "" (
    echo 找到2345浏览器: %browserPath%
    
    :: 先停止所有2345浏览器进程
    taskkill /F /IM 2345Explorer.exe 2>nul
    timeout /t 2 /nobreak >nul
    
    :: 启动浏览器
    start "" "%browserPath%"
    echo 2345浏览器已启动
) else (
    echo 未找到2345浏览器可执行文件
)

echo.
echo === 2345浏览器修复完成 ===
echo.
pause