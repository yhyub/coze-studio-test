#!/usr/bin/env pwsh

# Deploy Coze Studio with Docker
# Version: 1.0.0
# Author: trae-ai

# 以管理员权限运行
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "请以管理员权限运行此脚本" -ForegroundColor Red
    Start-Sleep -Seconds 3
    exit 1
}

# 检查Docker是否安装
Write-Host "[Step 1/8] 检查Docker环境..." -ForegroundColor Green
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker未安装，正在检查Docker Desktop安装程序..." -ForegroundColor Yellow
    if (Test-Path "$PSScriptRoot\..\..\Docker Desktop Installer.exe") {
        Write-Host "找到Docker Desktop安装程序，正在安装..." -ForegroundColor Cyan
        & "$PSScriptRoot\..\..\Docker Desktop Installer.exe" install --quiet
        Start-Sleep -Seconds 60
    } else {
        Write-Host "未找到Docker Desktop安装程序，请先安装Docker" -ForegroundColor Red
        exit 1
    }
}

# 检查Docker服务状态
Write-Host "[Step 2/8] 检查Docker服务状态..." -ForegroundColor Green
try {
    docker info | Out-Null
    Write-Host "Docker服务运行正常" -ForegroundColor Green
} catch {
    Write-Host "启动Docker服务..." -ForegroundColor Yellow
    Start-Service Docker
    Start-Sleep -Seconds 10
    try {
        docker info | Out-Null
        Write-Host "Docker服务已启动" -ForegroundColor Green
    } catch {
        Write-Host "Docker服务启动失败，请手动启动Docker Desktop" -ForegroundColor Red
        exit 1
    }
}

# 创建部署目录
Write-Host "[Step 3/8] 创建部署目录..." -ForegroundColor Green
$deployDir = "$PSScriptRoot\deploy"
if (-not (Test-Path $deployDir)) {
    New-Item -Path $deployDir -ItemType Directory -Force | Out-Null
}
Set-Location $deployDir

# 生成随机密码
Write-Host "[Step 4/8] 生成安全配置..." -ForegroundColor Green
function Generate-RandomPassword($length = 16) {
    $chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+[]{}|;:,.<>?'
    $password = ''
    for ($i = 0; $i -lt $length; $i++) {
        $password += $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
    }
    return $password
}

$mysqlPassword = Generate-RandomPassword
$minioPassword = Generate-RandomPassword
$pluginAesSecret = Generate-RandomPassword -length 16
$pluginAesStateSecret = Generate-RandomPassword -length 16
$pluginAesOAuthTokenSecret = Generate-RandomPassword -length 16

# 创建环境变量文件
Write-Host "[Step 5/8] 创建环境变量文件..." -ForegroundColor Green
$envContent = @"
# Server
export LISTEN_ADDR=":8888"
export LOG_LEVEL="info"
export MAX_REQUEST_BODY_SIZE=1073741824
export SERVER_HOST="http://localhost:8888"
export USE_SSL="0"
export SSL_CERT_FILE=""
export SSL_KEY_FILE=""
export WEB_LISTEN_ADDR="8888"

# MySQL
export MYSQL_ROOT_PASSWORD="$mysqlPassword"
export MYSQL_DATABASE="opencoze"
export MYSQL_USER="coze"
export MYSQL_PASSWORD="$mysqlPassword"
export MYSQL_HOST="mysql"
export MYSQL_PORT=3306
export MYSQL_DSN="${MYSQL_USER}:${MYSQL_PASSWORD}@tcp(${MYSQL_HOST}:${MYSQL_PORT})/${MYSQL_DATABASE}?charset=utf8mb4&parseTime=True"
export ATLAS_URL="mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}?charset=utf8mb4&parseTime=True"
export MYSQL_MAX_IDLE_CONNS=10
export MYSQL_MAX_OPEN_CONNS=100
export MYSQL_CONN_MAX_LIFETIME=3600
export MYSQL_CONN_MAX_IDLE_TIME=600

# Redis
export REDIS_AOF_ENABLED=no
export REDIS_IO_THREADS=4
export ALLOW_EMPTY_PASSWORD=yes
export REDIS_ADDR="redis:6379"
export REDIS_PASSWORD=""

# Storage
export FILE_UPLOAD_COMPONENT_TYPE="storage"
export STORAGE_TYPE="minio"
export STORAGE_UPLOAD_HTTP_SCHEME="http"
export STORAGE_BUCKET="opencoze"
export MINIO_ROOT_USER="minioadmin"
export MINIO_ROOT_PASSWORD="$minioPassword"
export MINIO_DEFAULT_BUCKETS="milvus"
export MINIO_AK=$MINIO_ROOT_USER
export MINIO_SK=$MINIO_ROOT_PASSWORD
export MINIO_ENDPOINT="minio:9000"
export MINIO_API_HOST="http://${MINIO_ENDPOINT}"
export MINIO_USE_SSL=false

# Elasticsearch
export ES_ADDR="http://elasticsearch:9200"
export ES_VERSION="v8"
export ES_USERNAME=""
export ES_PASSWORD=""
export ES_NUMBER_OF_SHARDS="1"
export ES_NUMBER_OF_REPLICAS="1"

# Message Queue
export COZE_MQ_TYPE="nsq"
export MQ_NAME_SERVER="nsqd:4150"

# Vector Store
export VECTOR_STORE_TYPE="milvus"
export MILVUS_ADDR="milvus:19530"
export MILVUS_USER=""
export MILVUS_PASSWORD=""
export MILVUS_TOKEN=""

# Embedding
export EMBEDDING_TYPE="ark"
export EMBEDDING_MAX_BATCH_SIZE=100

# OCR
export OCR_TYPE="ve"
export VE_OCR_AK=""
export VE_OCR_SK=""

# Parser
export PARSER_TYPE="builtin"

# Model
export MODEL_PROTOCOL_0="ark"
export MODEL_OPENCOZE_ID_0="100001"
export MODEL_NAME_0="Doubao"
export MODEL_ID_0="ep-20260201113548-5m7xq"
export MODEL_API_KEY_0="sk-"
export MODEL_BASE_URL_0="https://ark.cn-beijing.volces.com/api/v3"

# Plugin AES Secrets
export PLUGIN_AES_AUTH_SECRET='$pluginAesSecret'
export PLUGIN_AES_STATE_SECRET='$pluginAesStateSecret'
export PLUGIN_AES_OAUTH_TOKEN_SECRET='$pluginAesOAuthTokenSecret'

# Code Runner
export CODE_RUNNER_TYPE="sandbox"
export CODE_RUNNER_ALLOW_ENV=""
export CODE_RUNNER_ALLOW_READ=""
export CODE_RUNNER_ALLOW_WRITE=""
export CODE_RUNNER_ALLOW_RUN=""
export CODE_RUNNER_ALLOW_NET="cdn.jsdelivr.net"
export CODE_RUNNER_ALLOW_FFI=""
export CODE_RUNNER_NODE_MODULES_DIR=""
export CODE_RUNNER_TIMEOUT_SECONDS="60"
export CODE_RUNNER_MEMORY_LIMIT_MB="100"

# Registration
export DISABLE_USER_REGISTRATION="false"
export ALLOW_REGISTRATION_EMAIL=""

# Coze Saas API
export COZE_SAAS_PLUGIN_ENABLED="false"
export COZE_SAAS_API_BASE_URL="https://api.coze.cn"
export COZE_SAAS_API_KEY=""
"@

$envContent | Out-File -FilePath ".env" -Encoding UTF8 -Force
Write-Host "环境变量文件已创建" -ForegroundColor Green

# 创建Docker Compose配置
Write-Host "[Step 6/8] 创建Docker Compose配置..." -ForegroundColor Green
$composeContent = @"
name: coze-studio
x-env-file: &env_file
  - .env

services:
  mysql:
    image: mysql:8.4.5
    container_name: coze-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-root}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-opencoze}
      MYSQL_USER: ${MYSQL_USER:-coze}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-coze123