@echo off
:: 设置UTF-8编码以正确显示中文
chcp 65001 >nul 2>&1
:: 设置控制台字体以支持Unicode字符
for /f "tokens=2 delims=:" %%a in ('chcp') do set current_cp=%%a
if not "%current_cp%"==" 65001" (
    echo 正在设置控制台编码...
    chcp 65001 >nul 2>&1
)
echo ========================================
echo   TaskPyro节点微服务一键安装启动脚本
echo ========================================
echo.

:: 检查Python是否安装
echo [1/6] 检查Python环境...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误: 未找到Python，请先安装Python 3.9+
    echo 下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo ✅ Python版本: %PYTHON_VERSION%
echo.

:: 检查pip是否可用
echo [2/6] 检查pip工具...
pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误: pip不可用，请检查Python安装
    pause
    exit /b 1
)
echo ✅ pip工具正常
echo.

:: 创建虚拟环境
echo [3/6] 创建虚拟环境...
if not exist "venv" (
    echo 正在创建虚拟环境...
    python -m venv venv
    if %errorlevel% neq 0 (
        echo ❌ 虚拟环境创建失败
        pause
        exit /b 1
    )
    echo ✅ 虚拟环境创建完成
) else (
    echo ✅ 虚拟环境已存在
)
echo.

:: 激活虚拟环境
echo [4/6] 激活虚拟环境...
call venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ❌ 虚拟环境激活失败
    pause
    exit /b 1
)
echo ✅ 虚拟环境已激活
echo.

:: 升级pip
echo [5/6] 升级pip工具...
python -m pip install --upgrade pip >nul 2>&1
echo ✅ pip工具已升级
echo.

:: 安装依赖包
echo [6/6] 安装项目依赖...
echo 正在安装依赖包，请稍候...
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/
if %errorlevel% neq 0 (
    echo ❌ 依赖安装失败，尝试使用默认源...
    pip install -r requirements.txt
    if %errorlevel% neq 0 (
        echo ❌ 依赖安装失败，请检查网络连接或手动安装
        pause
        exit /b 1
    )
)
echo ✅ 依赖安装完成
echo.

:: 读取.env配置文件中的端口号
echo [启动] 读取配置信息...
set SERVER_PORT=8002
if exist ".env" (
    for /f "usebackq tokens=1,2 delims==" %%i in (".env") do (
        if "%%i"=="SERVER_PORT" set SERVER_PORT=%%j
    )
)
echo ✅ 服务端口: %SERVER_PORT%

:: 获取本机IP地址
echo [启动] 获取网络信息...
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4"') do (
    for /f "tokens=1" %%j in ("%%i") do set LOCAL_IP=%%j
)
if "%LOCAL_IP%"=="" (
    for /f "tokens=1-2 delims=:" %%i in ('ipconfig ^| findstr /C:"IPv4 地址"') do (
        for /f "tokens=1" %%k in ("%%j") do set LOCAL_IP=%%k
    )
)
if "%LOCAL_IP%"=="" set LOCAL_IP=127.0.0.1

echo [启动] 启动TaskPyro节点微服务...
echo ========================================
echo   服务启动信息
echo ========================================
echo 🚀 本地访问: http://localhost:%SERVER_PORT%
echo 🌐 网络访问: http://%LOCAL_IP%:%SERVER_PORT%
echo 📖 官网文档: https://docs.taskpyro.cn/professional/
echo 💻 主机IP地址: %LOCAL_IP%
echo ⏹️  停止服务: 按 Ctrl+C
echo ========================================
echo.
echo 正在启动服务，请稍候...
echo.

:: 启动TaskPyro节点微服务应用
python secondary_main.py

:: 如果服务异常退出
echo.
echo ⚠️  服务已停止
pause