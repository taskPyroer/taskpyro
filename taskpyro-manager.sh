#!/bin/bash

# TaskPyro 专业版Linux一键管理脚本
# 版本: 1.0
# 作者: TaskPyro Team
# 描述: 提供TaskPyro标准版/专业版Linux环境的一键安装、配置、启动、停止、升级、删除等功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
PROJECT_NAME="taskpyro"
DATA_DIR="/opt/taskpyrodata"
DEFAULT_FRONTEND_PORT=8080
DEFAULT_BACKEND_PORT=9000
DEFAULT_SERVER_NAME="localhost"
DEFAULT_WORKERS=1


# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 未安装，请先安装 $1"
        return 1
    fi
    return 0
}

# 检测操作系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        OS=openSUSE
    elif [ -f /etc/redhat-release ]; then
        OS=RedHat
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
}

# 安装Docker
install_docker() {
    log_info "开始安装 Docker..."
    
    detect_os
    
    case "$OS" in
        *"Red Hat"*|*"CentOS"*|*"Rocky"*|*"AlmaLinux"*)
            log_info "检测到 RedHat/CentOS 系统，使用阿里云镜像源安装Docker..."
            
            # 检查是否为CentOS 8，需要特殊处理
            if grep -q "CentOS Linux 8" /etc/os-release 2>/dev/null; then
                log_warning "检测到 CentOS 8 系统，正在修复yum源配置..."
                
                # 备份所有CentOS源文件
                sudo mkdir -p /etc/yum.repos.d/backup
                sudo cp /etc/yum.repos.d/CentOS-*.repo /etc/yum.repos.d/backup/ 2>/dev/null || true
                
                # 创建新的CentOS 8源配置
                sudo tee /etc/yum.repos.d/CentOS-Linux-BaseOS.repo > /dev/null << 'EOF'
[baseos]
name=CentOS Linux $releasever - BaseOS
baseurl=https://mirrors.aliyun.com/centos-vault/8.5.2111/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

                sudo tee /etc/yum.repos.d/CentOS-Linux-AppStream.repo > /dev/null << 'EOF'
[appstream]
name=CentOS Linux $releasever - AppStream
baseurl=https://mirrors.aliyun.com/centos-vault/8.5.2111/AppStream/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

                sudo tee /etc/yum.repos.d/CentOS-Linux-Extras.repo > /dev/null << 'EOF'
[extras]
name=CentOS Linux $releasever - Extras
baseurl=https://mirrors.aliyun.com/centos-vault/8.5.2111/extras/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
                
                # 清理缓存并重建
                sudo yum clean all
                sudo yum makecache
                
                log_info "CentOS 8 yum源配置已修复"
            fi
            
            # 对于CentOS 8，使用--allowerasing参数解决repos包冲突
            if grep -q "CentOS Linux 8" /etc/os-release 2>/dev/null; then
                sudo yum update -y --allowerasing
            else
                sudo yum update -y
            fi
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *"Ubuntu"*|*"Debian"*)
            log_info "检测到 Ubuntu/Debian 系统，使用阿里云镜像源安装Docker..."
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *"openEuler"*)
            log_info "检测到 openEuler 系统，使用 dnf 安装..."
            sudo dnf update -y
            sudo dnf install -y docker
            ;;
        *)
            log_warning "未识别的操作系统: $OS"
            log_info "尝试使用通用安装脚本..."
            if command -v curl &> /dev/null; then
                bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
            else
                log_error "curl 未安装，无法使用自动安装脚本"
                log_error "请手动安装 Docker: https://docs.docker.com/get-docker/"
                return 1
            fi
            ;;
    esac
    
    # 启动并启用Docker服务
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 将当前用户添加到docker组（可选）
    if [ "$USER" != "root" ]; then
        log_info "将用户 $USER 添加到 docker 组..."
        sudo usermod -aG docker $USER
        log_warning "请注销并重新登录以使docker组权限生效，或使用 'newgrp docker' 命令"
    fi
    
    log_success "Docker 安装完成"
}

# 安装Docker Compose
install_docker_compose() {
    log_info "检查 Docker Compose 安装状态..."
    
    # 检查是否已经通过docker-compose-plugin安装
    if docker compose version &> /dev/null; then
        log_success "Docker Compose (plugin) 已安装"
        # 创建docker-compose命令的别名脚本
        if [ ! -f /usr/local/bin/docker-compose ]; then
            sudo tee /usr/local/bin/docker-compose > /dev/null << 'EOF'
#!/bin/bash
docker compose "$@"
EOF
            sudo chmod +x /usr/local/bin/docker-compose
            log_info "已创建 docker-compose 命令别名"
        fi
        return 0
    fi
    
    # 如果plugin版本不可用，则安装独立版本
    log_info "安装独立版本的 Docker Compose..."
    
    # 使用固定版本以确保稳定性
    COMPOSE_VERSION="v2.24.1"
    
    log_info "安装 Docker Compose $COMPOSE_VERSION..."
    
    # 优先使用Gitee镜像源（国内推荐）
    log_info "尝试从 Gitee 镜像源下载..."
    sudo curl -L "https://gitee.com/fustack/docker-compose/releases/download/$COMPOSE_VERSION/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
    
    # 如果Gitee下载失败，回退到GitHub
    if [ $? -ne 0 ]; then
        log_warning "Gitee 下载失败，尝试从 GitHub 下载..."
        sudo curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        
        if [ $? -ne 0 ]; then
            log_error "Docker Compose 下载失败，请检查网络连接"
            return 1
        fi
    fi
    
    sudo chmod +x /usr/local/bin/docker-compose
    
    log_success "Docker Compose 安装完成"
}

# 检查并安装Docker环境
check_and_install_docker() {
    log_info "检查 Docker 环境..."
    
    local docker_missing=false
    local compose_missing=false
    
    # 检查Docker
    if ! check_command "docker"; then
        docker_missing=true
    fi
    
    # 检查Docker Compose (支持plugin和独立版本)
    if ! check_command "docker-compose" && ! docker compose version &> /dev/null; then
        compose_missing=true
    fi
    
    # 如果都已安装，检查服务状态
    if [ "$docker_missing" = false ] && [ "$compose_missing" = false ]; then
        if docker info &> /dev/null; then
            log_success "Docker 环境检查通过"
            return 0
        else
            log_warning "Docker 已安装但服务未运行，尝试启动..."
            sudo systemctl start docker
            if docker info &> /dev/null; then
                log_success "Docker 服务启动成功"
                return 0
            else
                log_error "Docker 服务启动失败"
                return 1
            fi
        fi
    fi
    
    # 询问用户是否自动安装
    echo
    log_warning "检测到以下组件未安装:"
    [ "$docker_missing" = true ] && echo "  - Docker"
    [ "$compose_missing" = true ] && echo "  - Docker Compose"
    echo
    read -p "是否自动安装缺失的组件？(y/N): " auto_install
    
    if [[ $auto_install != [yY] ]]; then
        log_error "请手动安装 Docker 和 Docker Compose 后再运行此脚本"
        log_info "安装指南: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # 安装Docker
    if [ "$docker_missing" = true ]; then
        install_docker
        if [ $? -ne 0 ]; then
            log_error "Docker 安装失败"
            exit 1
        fi
    fi
    
    # 安装Docker Compose
    if [ "$compose_missing" = true ]; then
        install_docker_compose
        if [ $? -ne 0 ]; then
            log_error "Docker Compose 安装失败"
            exit 1
        fi
    fi
    
    # 验证安装
    log_info "验证安装结果..."
    docker --version
    docker-compose --version
    
    # 测试Docker运行
    if docker info &> /dev/null; then
        log_success "Docker 环境安装并配置成功！"
    else
        log_error "Docker 安装完成但服务异常，请检查系统日志"
        exit 1
    fi
}

# 检查系统环境（重命名原函数）
check_prerequisites() {
    log_info "检查系统环境..."
    check_and_install_docker
}

# 获取用户输入
get_user_input() {
    read -p "请输入前端服务端口 (默认: $DEFAULT_FRONTEND_PORT): " FRONTEND_PORT
    FRONTEND_PORT=${FRONTEND_PORT:-$DEFAULT_FRONTEND_PORT}
    
    read -p "请输入后端服务端口 (默认: $DEFAULT_BACKEND_PORT): " BACKEND_PORT
    BACKEND_PORT=${BACKEND_PORT:-$DEFAULT_BACKEND_PORT}
    
    read -p "请输入数据存储目录 (默认: $DATA_DIR): " USER_DATA_DIR
    USER_DATA_DIR=${USER_DATA_DIR:-$DATA_DIR}
    
    # 使用默认配置，无需用户输入
    SERVER_NAME=$DEFAULT_SERVER_NAME
    WORKERS=$DEFAULT_WORKERS
}

# 创建或更新.env文件
create_env_file() {
    log_info "创建.env配置文件..."
    
    cat > .env << EOF
# 前端服务端口
FRONTEND_PORT=$FRONTEND_PORT
# 后端服务端口
BACKEND_PORT=$BACKEND_PORT
# 服务器域名或IP（默认localhost，通常不需要修改）
SERVER_NAME=$SERVER_NAME
# 后端工作进程数(不需要修改)
WORKERS=$WORKERS
# 数据存储目录
DATA_DIR=$USER_DATA_DIR
EOF
    
    log_success ".env文件创建完成"
}

# 检查Docker版本兼容性
check_docker_version() {
    local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    local major_version=$(echo $docker_version | cut -d. -f1)
    local minor_version=$(echo $docker_version | cut -d. -f2)
    
    # Docker 20.10+ 支持 init 选项
    if [ "$major_version" -gt 20 ] || ([ "$major_version" -eq 20 ] && [ "$minor_version" -ge 10 ]); then
        echo "true"
    else
        echo "false"
    fi
}

# 创建docker-compose.yml文件
create_docker_compose() {
    log_info "创建Docker Compose配置文件..."
    
    # 检查Docker版本兼容性
    local supports_init=$(check_docker_version)
    if [ "$supports_init" = "false" ]; then
        log_warning "检测到较老的Docker版本，将禁用init选项以确保兼容性"
    fi
    
    # 根据版本选择不同的镜像
    if [ "$EDITION" = "standard" ]; then
        FRONTEND_IMAGE="crpi-7ub5pdu5y0ps1uyh.cn-hangzhou.personal.cr.aliyuncs.com/taskpyro/taskpyro-frontend:1.0"
        API_IMAGE="crpi-7ub5pdu5y0ps1uyh.cn-hangzhou.personal.cr.aliyuncs.com/taskpyro/taskpyro-api:1.0"
        log_info "使用标准版镜像"
    else
        FRONTEND_IMAGE="crpi-7ub5pdu5y0ps1uyh.cn-hangzhou.personal.cr.aliyuncs.com/taskpyro/taskpyro-frontend:2.0"
        API_IMAGE="crpi-7ub5pdu5y0ps1uyh.cn-hangzhou.personal.cr.aliyuncs.com/taskpyro/taskpyro-api:2.0"
        log_info "使用专业版镜像"
    fi
    
    # 根据Docker版本生成不同的配置
    if [ "$supports_init" = "true" ]; then
        cat > docker-compose.yml << EOF
services:
  frontend:
    image: $FRONTEND_IMAGE
    ports:
      - "\${FRONTEND_PORT:-7789}:\${FRONTEND_PORT:-7789}"
    environment:
      - PORT=\${FRONTEND_PORT:-7789}
      - SERVER_NAME=\${SERVER_NAME:-localhost}
      - BACKEND_PORT=\${BACKEND_PORT:-8000}
      - API_URL=http://\${SERVER_NAME}:\${BACKEND_PORT:-8000}
      - TZ=Asia/Shanghai
    env_file:
      - .env
    depends_on:
      - api

  api:
    image: $API_IMAGE
    ports:
      - "\${BACKEND_PORT:-8000}:\${BACKEND_PORT:-8000}"
    environment:
      - PORT=\${BACKEND_PORT:-8000}
      - PYTHONPATH=/app
      - CORS_ORIGINS=http://localhost:\${FRONTEND_PORT:-7789},http://127.0.0.1:\${FRONTEND_PORT:-7789}
      - TZ=Asia/Shanghai
      - WORKERS=\${WORKERS:-1}
    volumes:
      - \${DATA_DIR}/static:/app/../static
      - \${DATA_DIR}/logs:/app/../logs
      - \${DATA_DIR}/data:/app/data
    env_file:
      - .env
    init: true
    restart: unless-stopped
EOF
    else
        cat > docker-compose.yml << EOF
services:
  frontend:
    image: $FRONTEND_IMAGE
    ports:
      - "\${FRONTEND_PORT:-7789}:\${FRONTEND_PORT:-7789}"
    environment:
      - PORT=\${FRONTEND_PORT:-7789}
      - SERVER_NAME=\${SERVER_NAME:-localhost}
      - BACKEND_PORT=\${BACKEND_PORT:-8000}
      - API_URL=http://\${SERVER_NAME}:\${BACKEND_PORT:-8000}
      - TZ=Asia/Shanghai
    env_file:
      - .env
    depends_on:
      - api

  api:
    image: $API_IMAGE
    ports:
      - "\${BACKEND_PORT:-8000}:\${BACKEND_PORT:-8000}"
    environment:
      - PORT=\${BACKEND_PORT:-8000}
      - PYTHONPATH=/app
      - CORS_ORIGINS=http://localhost:\${FRONTEND_PORT:-7789},http://127.0.0.1:\${FRONTEND_PORT:-7789}
      - TZ=Asia/Shanghai
      - WORKERS=\${WORKERS:-1}
    volumes:
      - \${DATA_DIR}/static:/app/../static
      - \${DATA_DIR}/logs:/app/../logs
      - \${DATA_DIR}/data:/app/data
    env_file:
      - .env
    restart: unless-stopped
EOF
    fi
    
    log_success "Docker Compose配置文件创建完成"
}

# 注释：数据目录创建函数已删除，目录将在Docker容器启动时自动创建
# 注释：install_from_git 函数已删除，现在只支持手动创建方式

# 手动安装
manual_install() {
    log_info "开始手动安装..."
    
    local script_dir=$(dirname "$(readlink -f "$0")")
    local target_dir="$script_dir/$PROJECT_NAME"
    
    # 清理可能存在的目标目录
    if [ -d "$target_dir" ]; then
        log_warning "目标目录 $target_dir 已存在，正在删除..."
        rm -rf "$target_dir"
    fi
    
    # 创建项目目录
    mkdir -p "$target_dir"
    cd "$target_dir"
    
    # 获取用户配置
    get_user_input
    
    # 创建配置文件
    create_env_file
    create_docker_compose
    
    log_success "手动安装配置完成，文件已创建到: $target_dir"
}

# 安装TaskPyro
install_taskpyro() {
    log_info "开始安装 TaskPyro..."
    
    # 检查系统环境并自动安装Docker（如需要）
    check_prerequisites
    
    echo
    echo "请选择 TaskPyro 版本:"
    echo "1) 标准版 (基础功能，支持在标准版基础上升级到专业版)"
    echo "2) 专业版 (完整功能，推荐)"
    read -p "请输入选择 (1-2): " version_choice
    
    case $version_choice in
        1)
            log_info "您选择了标准版"
            EDITION="standard"
            ;;
        2)
            log_info "您选择了专业版"
            EDITION="professional"
            ;;
        *)
            log_error "无效选择，默认使用专业版"
            EDITION="professional"
            ;;
    esac
    
    # 直接使用手动安装方式
    manual_install
    
    if [ "$EDITION" = "standard" ]; then
        log_success "TaskPyro 标准版安装完成！"
        echo
        log_info "标准版功能说明:"
        log_info "- 提供基础的Web管理界面"
        log_info "- 支持基本的任务调度功能"
        log_info "- 适合个人用户和小型项目"
        log_info "- 免费使用，功能相对简化"
    else
        log_success "TaskPyro 专业版Linux主控节点安装完成！"
        echo
        log_info "专业版功能说明:"
        log_info "- 提供完整的Web管理界面和API服务"
        log_info "- 支持高级任务调度和监控管理"
        log_info "- 具备完整的任务执行能力"
        log_info "- 可单机使用或管理其他工作节点"
        log_info "- 支持集群部署和高可用配置"
    fi
    echo
    log_info "安装已完成，请继续选择以下操作:"
    log_info "- 启动服务: 选择菜单中的 '启动服务' 选项"
    log_info "- 查看状态: 选择菜单中的 '查看服务状态' 选项"
    log_info "- 查看日志: 选择菜单中的 '查看服务日志' 选项"
}

# 启动服务
start_service() {
    log_info "启动 TaskPyro 服务..."
    
    if [ ! -f "docker-compose.yml" ]; then
        log_error "未找到 docker-compose.yml 文件，请先安装 TaskPyro"
        exit 1
    fi
    
    docker-compose up -d
    
    log_success "TaskPyro 服务启动成功！"
    
    # 显示服务状态
    echo
    log_info "服务状态:"
    docker-compose ps
    
    echo
    # 获取公网IP地址
    log_info "正在获取公网IP地址..."
    PUBLIC_IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || curl -s --connect-timeout 5 icanhazip.com 2>/dev/null || echo "")
    
    if [ -z "$PUBLIC_IP" ]; then
        log_warning "无法获取公网IP，使用本地IP地址"
        LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || ip route get 1 | awk '{print $7}' 2>/dev/null || echo "localhost")
        DISPLAY_IP=$LOCAL_IP
    else
        log_info "公网IP地址: $PUBLIC_IP"
        DISPLAY_IP=$PUBLIC_IP
    fi
    
    if [ -f ".env" ]; then
        source .env
        log_info "访问地址: http://${DISPLAY_IP}:${FRONTEND_PORT:-8080}"
    else
        log_info "访问地址: http://${DISPLAY_IP}:8080"
    fi
}

# 停止服务
stop_service() {
    log_info "停止 TaskPyro 服务..."
    
    if [ ! -f "docker-compose.yml" ]; then
        log_error "未找到 docker-compose.yml 文件"
        exit 1
    fi
    
    docker-compose down
    
    log_success "TaskPyro 服务已停止"
}

# 重启服务
restart_service() {
    log_info "重启 TaskPyro 服务..."
    
    stop_service
    sleep 2
    start_service
}

# 查看服务状态
show_status() {
    log_info "TaskPyro 服务状态:"
    
    if [ ! -f "docker-compose.yml" ]; then
        log_error "未找到 docker-compose.yml 文件"
        exit 1
    fi
    
    docker-compose ps
    
    echo
    log_info "服务日志 (最近20行):"
    docker-compose logs --tail=20
}

# 查看日志
show_logs() {
    log_info "查看 TaskPyro 服务日志..."
    
    if [ ! -f "docker-compose.yml" ]; then
        log_error "未找到 docker-compose.yml 文件"
        exit 1
    fi
    
    echo "请选择要查看的服务日志:"
    echo "1) 前端服务 (frontend)"
    echo "2) 后端服务 (api)"
    echo "3) 所有服务"
    read -p "请输入选择 (1-3): " choice
    
    case $choice in
        1)
            docker-compose logs -f frontend
            ;;
        2)
            docker-compose logs -f api
            ;;
        3)
            docker-compose logs -f
            ;;
        *)
            log_error "无效选择"
            ;;
    esac
}

# 修复Docker兼容性问题
# 主要解决Docker 18.x版本中"docker-init: executable file not found in $PATH"错误
# 通过移除不兼容的init选项来确保容器正常启动
fix_docker_compatibility() {
    log_info "修复Docker兼容性问题..."
    log_info "此功能主要解决Docker 18.x版本的init选项兼容性问题"
    
    if [ ! -f "docker-compose.yml" ]; then
        log_error "未找到 docker-compose.yml 文件"
        return 1
    fi
    
    # 检查是否存在init配置
    if grep -q "init: true" docker-compose.yml; then
        local supports_init=$(check_docker_version)
        if [ "$supports_init" = "false" ]; then
            log_warning "检测到Docker版本不支持init选项，正在移除..."
            
            # 备份原文件
            cp docker-compose.yml docker-compose.yml.backup
            
            # 移除init选项
            sed -i '/^[[:space:]]*init: true/d' docker-compose.yml
            
            log_success "已移除init选项，原文件已备份为docker-compose.yml.backup"
            log_info "请重新启动服务以应用修复"
        else
            log_info "当前Docker版本支持init选项，无需修复"
        fi
    else
        log_info "配置文件中未发现init选项，无需修复"
    fi
}

# 升级服务
upgrade_service() {
    log_info "升级 TaskPyro 到最新版本..."
    
    if [ ! -f "docker-compose.yml" ]; then
        log_error "未找到 docker-compose.yml 文件"
        exit 1
    fi
    
    # 检测当前版本
    log_info "检测当前版本..."
    current_version="unknown"
    if grep -q ":1\.[0-9]" docker-compose.yml; then
        current_version="1.x"
    elif grep -q ":2\.[0-9]" docker-compose.yml; then
        current_version="2.x"
    fi
    
    log_info "当前检测到的版本: $current_version"
    
    # 如果是1.x版本，提供升级选项
    if [ "$current_version" = "1.x" ]; then
        echo
        log_warning "检测到您当前使用的是 1.x 版本"
        echo
        echo "请选择升级方式："
        echo "1) 升级到最新的 1.x 版本 (保持当前版本系列)"
        echo "2) 升级到 2.x 版本 (需要手动修改配置文件)"
        echo "3) 取消升级"
        echo
        read -p "请选择 (1-3): " upgrade_choice
        
        case $upgrade_choice in
            1)
                log_info "将升级到最新的 1.x 版本"
                # 继续使用当前的1.x版本升级流程
                ;;
            2)
                log_warning "升级到 2.x 版本需要修改 docker-compose.yml 文件"
                echo
                echo "检测到以下需要升级的镜像："
                if grep -q "taskpyro-frontend:1" docker-compose.yml; then
                    echo "- frontend: 1.x -> 2.0"
                fi
                if grep -q "taskpyro-api:1" docker-compose.yml; then
                    echo "- api: 1.x -> 2.0"
                fi
                echo
                read -p "是否自动修改配置文件？(Y/n): " auto_update
                
                if [[ $auto_update == [nN] ]]; then
                    echo
                    echo "请手动按照以下步骤操作："
                    echo "1. 编辑 docker-compose.yml 文件"
                    echo "2. 将 frontend 的 image 标签改为 2.0"
                    echo "3. 将 api 的 image 标签改为 2.0"
                    echo "4. 保存文件后重新运行升级命令"
                    echo
                    echo "示例修改："
                    echo "  frontend:"
                    echo "    image: crpi-7ub5pdu5y0ps1uyh.cn-hangzhou.personal.cr.aliyuncs.com/taskpyro/taskpyro-frontend:2.0"
                    echo "  api:"
                    echo "    image: crpi-7ub5pdu5y0ps1uyh.cn-hangzhou.personal.cr.aliyuncs.com/taskpyro/taskpyro-api:2.0"
                    echo
                    read -p "是否已经完成配置文件修改？(y/N): " config_updated
                    
                    if [[ $config_updated != [yY] ]]; then
                        log_info "请先修改配置文件后再运行升级"
                        return 1
                    fi
                else
                    log_info "正在自动修改配置文件..."
                    
                    # 备份原配置文件
                    cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
                    log_info "已备份原配置文件"
                    
                    # 自动修改镜像版本
                    sed -i 's|taskpyro-frontend:1\.[0-9]*|taskpyro-frontend:2.0|g' docker-compose.yml
                    sed -i 's|taskpyro-api:1\.[0-9]*|taskpyro-api:2.0|g' docker-compose.yml
                    
                    log_success "配置文件已自动更新到 2.x 版本"
                fi
                ;;
            3)
                log_info "取消升级操作"
                return 0
                ;;
            *)
                log_error "无效选择，取消升级"
                return 1
                ;;
        esac
    fi
    
    # 备份提醒
    echo
    log_warning "升级前建议备份重要数据"
    read -p "是否继续升级？(y/N): " continue_upgrade
    
    if [[ $continue_upgrade != [yY] ]]; then
        log_info "取消升级操作"
        return 0
    fi
    
    # 拉取最新镜像
    log_info "拉取最新镜像..."
    if ! docker-compose pull; then
        log_error "镜像拉取失败，请检查网络连接或镜像源配置"
        return 1
    fi
    
    # 重启服务
    log_info "重启服务以应用更新..."
    if ! docker-compose up -d; then
        log_error "服务启动失败，请检查配置文件和系统资源"
        return 1
    fi
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 5
    
    # 检查服务状态
    if docker-compose ps | grep -q "Up"; then
        log_success "TaskPyro 升级完成！"
        log_info "您可以使用 './taskpyro-manager.sh status' 查看详细状态"
    else
        log_warning "升级完成，但部分服务可能未正常启动"
        log_info "请使用 './taskpyro-manager.sh logs' 查看详细日志"
    fi
}



# 卸载TaskPyro
uninstall_taskpyro() {
    log_warning "即将卸载 TaskPyro，此操作将删除所有容器和镜像"
    read -p "是否继续？(y/N): " confirm
    
    if [[ $confirm != [yY] ]]; then
        log_info "取消卸载操作"
        return
    fi
    
    log_info "停止并删除容器..."
    if [ -f "docker-compose.yml" ]; then
        docker-compose down
    fi
    
    # 删除镜像
    log_info "删除 TaskPyro 镜像..."
    docker images | grep taskpyro | awk '{print $3}' | xargs -r docker rmi -f
    
    # 删除项目文件（从脚本同级目录删除）
    local script_dir=$(dirname "$(readlink -f "$0")")
    local target_dir="$script_dir/$PROJECT_NAME"
    if [ -d "$target_dir" ]; then
        log_info "删除项目文件: $target_dir"
        rm -rf "$target_dir"
    fi
    
    # 删除taskpyro配置文件夹
    if [ -d "$script_dir/$PROJECT_NAME" ]; then
        log_info "删除配置文件夹: $script_dir/$PROJECT_NAME"
        rm -rf "$script_dir/$PROJECT_NAME"
    fi
    
    # 询问是否删除数据
    echo
    log_warning "是否同时删除数据目录 $DATA_DIR ？"
    log_warning "警告：此操作将永久删除所有任务数据、日志等信息！"
    read -p "删除数据目录？(y/N): " delete_data
    
    if [[ $delete_data == [yY] ]]; then
        sudo rm -rf $DATA_DIR
        log_success "数据目录已删除"
    else
        log_info "保留数据目录: $DATA_DIR"
    fi
    
    # 注释：不再需要清理配置目录，因为现在使用简化的目录结构
    
    log_success "TaskPyro 卸载完成"
}

# 显示帮助信息
show_help() {
    echo "TaskPyro Linux管理脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  install     安装 TaskPyro (支持标准版/专业版选择)"
    echo "  start       启动服务"
    echo "  stop        停止服务"
    echo "  restart     重启服务"
    echo "  status      查看服务状态"
    echo "  logs        查看服务日志"
    echo "  upgrade     升级到最新版本"
    echo "  fix         修复Docker兼容性问题"
    echo ""
    echo "  uninstall   卸载 TaskPyro"
    echo "  help        显示帮助信息"
    echo
    echo "说明:"
    echo "  此脚本用于部署TaskPyro的Linux主控节点"
    echo "  支持标准版(免费)和专业版(完整功能)选择"
    echo "  主控节点具备任务执行和管理能力"
    echo "  如果不提供参数，将显示交互式菜单"
}

# 显示交互式菜单
show_menu() {
    while true; do
        echo
        echo "=========================================="
        echo "        TaskPyro Linux管理工具"
        echo "=========================================="
        echo "1) 安装 TaskPyro (标准版/专业版)"
        echo "2) 启动服务"
        echo "3) 停止服务"
        echo "4) 重启服务"
        echo "5) 查看服务状态"
        echo "6) 查看服务日志"
        echo "7) 升级到最新版本"
        echo "8) 修复Docker兼容性问题"
        echo "9) 卸载 TaskPyro"
        echo "0) 退出"
        echo "==========================================="
        read -p "请选择操作 (0-9): " choice
        
        case $choice in
            1) install_taskpyro ;;
            2) check_taskpyro_workdir "start" && start_service ;;
            3) check_taskpyro_workdir "stop" && stop_service ;;
            4) check_taskpyro_workdir "restart" && restart_service ;;
            5) check_taskpyro_workdir "status" && show_status ;;
            6) check_taskpyro_workdir "logs" && show_logs ;;
            7) check_taskpyro_workdir "upgrade" && upgrade_service ;;
            8) check_taskpyro_workdir "fix" && fix_docker_compatibility ;;
            9) check_taskpyro_workdir "uninstall" && uninstall_taskpyro ;;
            0) 
                log_info "感谢使用 TaskPyro 管理工具！"
                exit 0
                ;;
            *) 
                log_error "无效选择，请重新输入"
                ;;
        esac
        
        echo
        read -p "按回车键继续..."
    done
}

# 检测并切换到TaskPyro工作目录
find_and_switch_to_workdir() {
    local current_dir=$(pwd)
    local script_dir=$(dirname "$(readlink -f "$0")")
    
    # 如果当前目录有docker-compose.yml，直接返回
    if [ -f "docker-compose.yml" ]; then
        return 0
    fi
    
    # 搜索可能的TaskPyro目录（优先搜索脚本同级目录）
    local possible_dirs=(
        "$script_dir/taskpyro"
        "$current_dir/taskpyro"
        "./taskpyro"
    )
    
    # 遍历可能的目录
    for dir in "${possible_dirs[@]}"; do
        if [ -f "$dir/docker-compose.yml" ]; then
            log_info "找到TaskPyro工作目录: $dir"
            cd "$dir"
            return 0
        fi
    done
    
    return 1
}

# 检查TaskPyro工作环境
check_taskpyro_workdir() {
    # 对于安装操作和交互式菜单，不需要检查工作目录
    if [ "${1:-}" = "install" ] || [ "${1:-}" = "" ]; then
        return 0
    fi
    
    # 尝试找到并切换到工作目录
    if ! find_and_switch_to_workdir; then
        log_error "未找到TaskPyro工作目录或docker-compose.yml文件"
        log_info "请确保已经安装TaskPyro，或在正确的目录中运行此脚本"
        log_info "如果尚未安装，请先运行: $0 install"
        exit 1
    fi
}

# 主函数
main() {

    
    # 检查TaskPyro工作目录（除了安装操作）
    check_taskpyro_workdir "${1:-}"
    
    # 处理命令行参数
    case "${1:-}" in
        install)
            install_taskpyro
            ;;
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            restart_service
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        upgrade)
            upgrade_service
            ;;
        fix)
            fix_docker_compatibility
            ;;
        uninstall)
            uninstall_taskpyro
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            show_menu
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"