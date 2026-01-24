@echo off
echo === Coze Studio 完整修复脚本 ===
echo 正在启动修复流程...

echo 1. 检查Docker状态
docker --version
if %errorlevel% neq 0 (
    echo Docker未安装，请先安装Docker Desktop
    pause
    exit /b 1
)

echo 2. 创建.env文件
if not exist "coze-studio-0.5.0\docker\.env" (
    echo 创建.env文件...
    cd coze-studio-0.5.0\docker
    echo MYSQL_ROOT_PASSWORD=root > .env
    echo MYSQL_DATABASE=opencoze >> .env
    echo MYSQL_USER=coze >> .env
    echo MYSQL_PASSWORD=coze123 >> .env
    echo MINIO_ROOT_USER=minioadmin >> .env
    echo MINIO_ROOT_PASSWORD=minioadmin123 >> .env
    echo MINIO_DEFAULT_BUCKETS=opencoze,milvus >> .env
    echo STORAGE_BUCKET=opencoze >> .env
    echo WEB_LISTEN_ADDR=8888 >> .env
    echo REDIS_AOF_ENABLED=no >> .env
    echo REDIS_PORT_NUMBER=6379 >> .env
    echo REDIS_IO_THREADS=4 >> .env
    echo ALLOW_EMPTY_PASSWORD=yes >> .env
    echo ETCD_AUTO_COMPACTION_MODE=revision >> .env
    echo ETCD_AUTO_COMPACTION_RETENTION=1000 >> .env
    echo ETCD_QUOTA_BACKEND_BYTES=4294967296 >> .env
    echo ALLOW_NONE_AUTHENTICATION=yes >> .env
    echo ETCD_ENDPOINTS=etcd:2379 >> .env
    echo MINIO_ADDRESS=minio:9000 >> .env
    echo MINIO_BUCKET_NAME=milvus >> .env
    echo MINIO_ACCESS_KEY_ID=minioadmin >> .env
    echo MINIO_SECRET_ACCESS_KEY=minioadmin123 >> .env
    echo MINIO_USE_SSL=false >> .env
    echo LOG_LEVEL=debug >> .env
    echo TEST=1 >> .env
    cd ..\..
)

echo 3. 启动Docker Desktop
echo 请确保Docker Desktop已启动...
timeout /t 5 /nobreak >nul

echo 4. 检查Docker守护进程
echo 检查Docker守护进程状态...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker守护进程未运行，请启动Docker Desktop
    pause
    exit /b 1
)

echo 5. 启动Coze Studio服务
echo 启动Coze Studio服务...
cd coze-studio-0.5.0\docker
docker-compose up -d

echo 6. 检查服务启动状态
echo 检查服务启动状态...
timeout /t 30 /nobreak >nul
docker-compose ps

echo 7. 验证服务访问
echo 验证Coze Studio服务访问...
echo 请在浏览器中访问: http://localhost:8888
echo 检查服务是否正常运行...

echo 8. 检查容器日志
echo 检查关键服务日志...
docker logs coze-server --tail 50
docker logs coze-web --tail 20

echo === 修复完成 ===
echo 服务启动状态:
docker-compose ps
echo 访问地址: http://localhost:8888
echo 如果服务未正常启动，请检查Docker Desktop状态和容器日志
pause