<#
.SYNOPSIS
    磁盘维护运行程序 - 定期执行磁盘清理、重复文件检查、文件夹命名规范维护和临时文件清理

.DESCRIPTION
    该脚本用于自动化执行磁盘维护任务，包括：
    1. 运行Windows磁盘清理工具
    2. 检查并删除重复文件
    3. 维护文件夹命名规范
    4. 清理临时文件和缓存
    5. 生成维护报告

.PARAMETER DriveLetter
    指定要维护的驱动器盘符，默认为C:

.PARAMETER LogPath
    指定日志文件路径，默认为C:\DiskMaintenanceLog.txt

.EXAMPLE
    .\DiskMaintenance.ps1
    执行C盘的完整维护任务

.EXAMPLE
    .\DiskMaintenance.ps1 -DriveLetter D:
    执行D盘的完整维护任务

.NOTES
    Author: AI Assistant
    Date: 2026-01-17
    Version: 1.0
    建议每月运行一次该脚本，可通过Windows任务计划程序设置自动执行
#>

param(
    [Parameter(Mandatory=$false, HelpMessage="指定要维护的驱动器盘符")]
    [string]$DriveLetter = "C:",

    [Parameter(Mandatory=$false, HelpMessage="指定日志文件路径")]
    [string]$LogPath = "C:\DiskMaintenanceLog.txt"
)

# 确保驱动器盘符格式正确
if (-not $DriveLetter.EndsWith("\")) {
    $DriveLetter += "\"}

# 函数：写入日志
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] [$Level] $Message" | Out-File -FilePath $LogPath -Append -Encoding UTF8
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(switch($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "INFO" { "White" }
        "SUCCESS" { "Green" }
        default { "White" }
    })
}

# 开始维护
Write-Log "开始磁盘维护任务 - 驱动器: $DriveLetter" "INFO"
Write-Log "=" * 60 "INFO"

# 1. 运行Windows磁盘清理工具
Write-Log "1. 运行Windows磁盘清理工具" "INFO"
try {
    # 启动磁盘清理工具，自动清理所有可清理项
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -NoNewWindow
    Write-Log "磁盘清理工具运行完成" "SUCCESS"
} catch {
    Write-Log "运行磁盘清理工具时出错: $($_.Exception.Message)" "ERROR"
}

# 2. 检查并删除重复文件
Write-Log "2. 检查并删除重复文件" "INFO"

# 定义需要排除的系统文件夹
$excludeFolders = @(
    "$DriveLetterWindows",
    "$DriveLetterProgram Files",
    "$DriveLetterProgram Files (x86)",
    "$DriveLetterProgramData",
    "$DriveLetterUsers\*\AppData",
    "$DriveLetterRecovery"
)

# 定义要扫描的文件夹
$scanFolder = $DriveLetter

# 创建哈希表存储文件哈希和路径
$fileHashes = @{}
$duplicateCount = 0

# 获取所有文件，排除系统文件夹
try {
    $files = Get-ChildItem -Path $scanFolder -Recurse -File -ErrorAction SilentlyContinue | 
        Where-Object { 
            $excludeFolders -notcontains $_.Directory.FullName -and 
            -not ($excludeFolders | Where-Object { $_.EndsWith("*") -and $_.Directory.FullName -like $_.Replace("*", "*") })
        }
    
    # 遍历所有文件，计算哈希值并找出重复文件
    foreach ($file in $files) {
        try {
            # 计算文件哈希值
            $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256 -ErrorAction Stop
            
            # 检查哈希值是否已存在
            if ($fileHashes.ContainsKey($hash.Hash)) {
                # 找到重复文件，记录并删除
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                $duplicateCount++
            } else {
                # 将哈希值和文件路径添加到哈希表
                $fileHashes[$hash.Hash] = $file.FullName
            }
        } catch {
            Write-Log "处理文件 $($file.FullName) 时出错: $($_.Exception.Message)" "ERROR"
        }
    }
    
    Write-Log "已删除 $duplicateCount 个重复文件" "SUCCESS"
} catch {
    Write-Log "检查重复文件时出错: $($_.Exception.Message)" "ERROR"
}

# 3. 维护文件夹命名规范
Write-Log "3. 维护文件夹命名规范" "INFO"

# 定义文件夹命名规则
$renameRules = @{
    "temp" = "临时文件";
    "tmp" = "临时文件2";
    "downloads" = "下载";
    "documents" = "文档";
    "pictures" = "图片";
    "music" = "音乐";
    "videos" = "视频";
    "projects" = "项目";
    "cache" = "缓存";
    "logs" = "日志"
}

# 获取驱动器根目录所有文件夹
try {
    $rootFolders = Get-ChildItem -Path $DriveLetter -Directory
    
    # 定义系统文件夹（不需要重命名）
    $systemFolders = @(
        "Windows",
        "Program Files",
        "Program Files (x86)",
        "Users",
        "ProgramData",
        "Recovery"
    )
    
    $renamedCount = 0
    
    # 遍历所有文件夹，进行重命名
    foreach ($folder in $rootFolders) {
        # 跳过系统文件夹
        if ($systemFolders -contains $folder.Name) {
            continue
        }
        
        # 检查是否有重命名规则
        if ($renameRules.ContainsKey($folder.Name.ToLower())) {
            $newName = $renameRules[$folder.Name.ToLower()]
            $newPath = Join-Path -Path $DriveLetter -ChildPath $newName
            
            # 检查新名称是否已存在
            if (-not (Test-Path -Path $newPath)) {
                try {
                    # 执行重命名
                    Rename-Item -Path $folder.FullName -NewName $newName -Force -ErrorAction Stop
                    $renamedCount++
                } catch {
                    Write-Log "重命名文件夹 $($folder.Name) 时出错: $($_.Exception.Message)" "ERROR"
                }
            }
        }
    }
    
    Write-Log "已规范化 $renamedCount 个文件夹名称" "SUCCESS"
} catch {
    Write-Log "维护文件夹命名规范时出错: $($_.Exception.Message)" "ERROR"
}

# 4. 清理临时文件和缓存
Write-Log "4. 清理临时文件和缓存" "INFO"
try {
    # 清理临时文件
    Write-Log "   清理Windows临时文件夹" "INFO"
    Remove-Item -Path "$DriveLetterWindows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Log "   清理用户临时文件夹" "INFO"
    Remove-Item -Path "$DriveLetterUsers\*\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Log "   清理根目录临时文件" "INFO"
    Remove-Item -Path "$DriveLetter*.tmp" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$DriveLetter*.temp" -Force -ErrorAction SilentlyContinue
    
    # 清理缓存文件
    Write-Log "   清理浏览器缓存" "INFO"
    Remove-Item -Path "$DriveLetterUsers\*\AppData\Local\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$DriveLetterUsers\*\AppData\Local\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$DriveLetterUsers\*\AppData\Local\Mozilla\Firefox\Profiles\*\cache2\entries\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    # 清理日志文件
    Write-Log "   清理系统日志" "INFO"
    Remove-Item -Path "$DriveLetterWindows\Logs\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    # 清理回收站
    Write-Log "   清理回收站" "INFO"
    Remove-Item -Path "$DriveLetter`$Recycle.Bin\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Log "临时文件和缓存清理完成" "SUCCESS"
} catch {
    Write-Log "清理临时文件和缓存时出错: $($_.Exception.Message)" "ERROR"
}

# 5. 生成维护报告
Write-Log "5. 生成维护报告" "INFO"

# 获取磁盘使用情况
try {
    $diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$($DriveLetter.TrimEnd('\'))'"
    $totalSize = [math]::Round($diskInfo.Size / 1GB, 2)
    $freeSpace = [math]::Round($diskInfo.FreeSpace / 1GB, 2)
    $usedSpace = $totalSize - $freeSpace
    
    # 创建报告文件
    $reportFile = "$DriveLetterDiskMaintenanceReport_$(Get-Date -Format 'yyyyMMdd').txt"
    
    "磁盘维护报告 - $(Get-Date)" | Out-File -FilePath $reportFile -Append
    "=" * 50 | Out-File -FilePath $reportFile -Append
    "驱动器: $DriveLetter" | Out-File -FilePath $reportFile -Append
    "" | Out-File -FilePath $reportFile -Append
    
    "1. 磁盘使用情况：" | Out-File -FilePath $reportFile -Append
    "   总容量: $totalSize GB" | Out-File -FilePath $reportFile -Append
    "   已用空间: $usedSpace GB" | Out-File -FilePath $reportFile -Append
    "   可用空间: $freeSpace GB" | Out-File -FilePath $reportFile -Append
    "" | Out-File -FilePath $reportFile -Append
    
    "2. 重复文件删除情况：" | Out-File -FilePath $reportFile -Append
    "   已删除重复文件数量: $duplicateCount" | Out-File -FilePath $reportFile -Append
    "" | Out-File -FilePath $reportFile -Append
    
    "3. 文件夹命名规范维护情况：" | Out-File -FilePath $reportFile -Append
    "   已规范化文件夹数量: $renamedCount" | Out-File -FilePath $reportFile -Append
    "" | Out-File -FilePath $reportFile -Append
    
    "4. 临时文件和缓存清理：" | Out-File -FilePath $reportFile -Append
    "   已清理Windows临时文件夹" | Out-File -FilePath $reportFile -Append
    "   已清理用户临时文件夹" | Out-File -FilePath $reportFile -Append
    "   已清理浏览器缓存" | Out-File -FilePath $reportFile -Append
    "   已清理系统日志" | Out-File -FilePath $reportFile -Append
    "   已清理回收站" | Out-File -FilePath $reportFile -Append
    "" | Out-File -FilePath $reportFile -Append
    
    "5. 后续维护建议：" | Out-File -FilePath $reportFile -Append
    "   - 定期运行磁盘维护程序，建议每月一次" | Out-File -FilePath $reportFile -Append
    "   - 定期检查重复文件，避免文件冗余" | Out-File -FilePath $reportFile -Append
    "   - 保持文件夹命名规范，便于文件管理" | Out-File -FilePath $reportFile -Append
    "   - 及时清理临时文件和缓存，释放磁盘空间" | Out-File -FilePath $reportFile -Append
    "   - 定期备份重要文件，防止数据丢失" | Out-File -FilePath $reportFile -Append
    "" | Out-File -FilePath $reportFile -Append
    
    "=" * 50 | Out-File -FilePath $reportFile -Append
    "报告生成完成，详细内容请查看：$reportFile" | Out-File -FilePath $reportFile -Append
    
    Write-Log "维护报告生成完成: $reportFile" "SUCCESS"
} catch {
    Write-Log "生成维护报告时出错: $($_.Exception.Message)" "ERROR"
}

# 维护完成
Write-Log "=" * 60 "INFO"
Write-Log "磁盘维护任务完成 - 驱动器: $DriveLetter" "SUCCESS"
Write-Log "维护日志文件: $LogPath" "INFO"
Write-Log "建议：将此脚本添加到Windows任务计划程序，设置为每月自动执行" "INFO"