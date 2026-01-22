# Visual C++ Redistributables 2026 更新脚本
# 下载并安装最新的Visual C++ redistributables包

Write-Host "正在下载并安装2026年最新的Visual C++ Redistributables..."

# 创建临时目录
$tempDir = "$env:TEMP\VC_Redist_2026"
if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# 下载链接 (假设的2026年版本链接，实际使用时需要替换为真实链接)
$downloadLinks = @(
    @{
        URL = "https://aka.ms/vs/17/release/vc_redist.x86.exe"
        FileName = "vc_redist.x86.exe"
        Arguments = "/install /quiet /norestart"
    },
    @{
        URL = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
        FileName = "vc_redist.x64.exe"
        Arguments = "/install /quiet /norestart"
    }
)

# 下载并安装每个包
foreach ($link in $downloadLinks) {
    $filePath = "$tempDir\$($link.FileName)"
    Write-Host "正在下载: $($link.FileName)"
    
    try {
        Invoke-WebRequest -Uri $link.URL -OutFile $filePath -UseBasicParsing
        Write-Host "下载完成，正在安装..."
        
        # 安装
        $process = Start-Process -FilePath $filePath -ArgumentList $link.Arguments -Wait -PassThru
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Host "安装成功!"
        } else {
            Write-Host "安装失败，退出代码: $($process.ExitCode)"
        }
    } catch {
        Write-Host "下载失败: $($_.Exception.Message)"
    }
}

Write-Host "Visual C++ Redistributables 更新完成!"
Write-Host "注意: 如果安装过程中要求重启，请在方便时重启系统。"
