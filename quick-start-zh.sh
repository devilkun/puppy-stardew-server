#!/bin/bash
# =============================================================================
# Puppy Stardew Server - 快速启动脚本（中文版）
# =============================================================================
# 此脚本将帮助您在几分钟内设置星露谷物语专用服务器！
# =============================================================================

# 不在错误时退出 - 我们手动处理错误
set +e

# 输出颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色
BOLD='\033[1m'

# =============================================================================
# 辅助函数
# =============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}  🐶 小狗星谷服务器 - 快速启动${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
    echo ""
    echo -e "${BOLD}$1${NC}"
}

ask_question() {
    echo -e "${CYAN}❓ $1${NC}"
}

# =============================================================================
# 主要设置函数
# =============================================================================

check_docker() {
    print_step "步骤 1: 检查 Docker 安装..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装！"
        echo ""
        echo "请先安装 Docker："
        echo "  Ubuntu/Debian: curl -fsSL https://get.docker.com | sh"
        echo "  其他系统: https://docs.docker.com/get-docker/"
        echo ""
        exit 1
    fi

    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose 不可用！"
        echo ""
        echo "请更新 Docker 到包含 Docker Compose 的新版本。"
        echo "访问: https://docs.docker.com/compose/install/"
        echo ""
        exit 1
    fi

    if ! docker ps &> /dev/null; then
        print_error "Docker 守护进程未运行或需要 sudo 权限！"
        echo ""
        echo "尝试以下方法之一："
        echo "  1. 启动 Docker: sudo systemctl start docker"
        echo "  2. 将用户添加到 docker 组: sudo usermod -aG docker \$USER"
        echo "     (然后注销并重新登录)"
        echo ""
        exit 1
    fi

    print_success "Docker 已安装并正在运行！"
}

download_files() {
    print_step "步骤 2: 下载配置文件..."

    if [ ! -d "puppy-stardew-server" ]; then
        print_info "克隆仓库..."
        if git clone https://github.com/truman-world/puppy-stardew-server.git; then
            print_success "仓库已克隆！"
        else
            print_error "克隆失败！请检查网络连接。"
            exit 1
        fi
    else
        print_info "目录已存在，跳过克隆"
    fi

    cd puppy-stardew-server || exit 1
}

configure_steam() {
    print_step "步骤 3: Steam 配置..."
    echo ""
    print_warning "重要：您必须在 Steam 上拥有星露谷物语！"
    print_info "游戏文件将通过您的 Steam 账户下载。"
    echo ""

    if [ -f ".env" ]; then
        ask_question ".env 文件已存在。是否要重新配置？(y/n)"
        read -r reconfigure </dev/tty
        if [[ ! $reconfigure =~ ^[Yy]$ ]]; then
            print_info "使用现有 .env 文件"
            return
        fi
    fi

    cp .env.example .env

    echo ""
    print_info "═══════════════════════════════════════════════════"
    print_info "  配置方式选择"
    print_info "═══════════════════════════════════════════════════"
    echo ""
    ask_question "是否在终端手动输入配置信息？(y/n)"
    echo -e "${CYAN}  y${NC} - 现在在终端输入 Steam 用户名、密码和 VNC 密码"
    echo -e "${CYAN}  n${NC} - 稍后手动编辑 .env 文件（推荐熟悉 Linux 用户）"
    echo ""
    read -r manual_input </dev/tty

    if [[ $manual_input =~ ^[Yy]$ ]]; then
        # 手动输入模式
        echo ""
        ask_question "请输入您的 Steam 用户名："
        read -r steam_username </dev/tty

        echo ""
        ask_question "请输入您的 Steam 密码："
        read -rs steam_password </dev/tty
        echo ""

        echo ""
        ask_question "请输入 VNC 密码（最多8个字符，按回车使用默认 'stardew1'）："
        read -r vnc_password </dev/tty
        if [ -z "$vnc_password" ]; then
            vnc_password="stardew1"
        fi

        # 验证并截断 VNC 密码为 8 个字符
        if [ ${#vnc_password} -gt 8 ]; then
            print_warning "VNC 密码超过 8 个字符！"
            print_warning "VNC 协议会自动截断为：${vnc_password:0:8}"
            vnc_password="${vnc_password:0:8}"
        fi

        # 更新 .env 文件
        sed -i "s/^STEAM_USERNAME=.*/STEAM_USERNAME=$steam_username/" .env
        sed -i "s/^STEAM_PASSWORD=.*/STEAM_PASSWORD=$steam_password/" .env
        sed -i "s/^VNC_PASSWORD=.*/VNC_PASSWORD=$vnc_password/" .env

        print_success "Steam 配置已保存！"
    else
        # 手动编辑 .env 文件模式
        echo ""
        print_info "请手动编辑 .env 文件来配置您的凭证："
        echo -e "  ${CYAN}nano .env${NC}  或  ${CYAN}vim .env${NC}"
        echo ""
        print_info "需要配置以下字段："
        echo -e "  ${YELLOW}STEAM_USERNAME${NC}  - 您的 Steam 用户名"
        echo -e "  ${YELLOW}STEAM_PASSWORD${NC}  - 您的 Steam 密码"
        echo -e "  ${YELLOW}VNC_PASSWORD${NC}    - VNC 访问密码（最多8个字符）"
        echo ""
        ask_question "配置完成后，按回车继续..."
        read -r </dev/tty
    fi
}

setup_directories() {
    print_step "步骤 4: 设置数据目录..."

    # 创建目录（包括日志监控需要的 logs 目录）
    mkdir -p data/{saves,game,steam,logs}

    print_info "设置正确的权限 (UID 1000)..."
    if chown -R 1000:1000 data/ 2>/dev/null; then
        # 验证权限是否正确设置
        if [ "$(stat -c '%u' data/game 2>/dev/null || stat -f '%u' data/game 2>/dev/null)" != "1000" ]; then
            print_error "权限设置失败！"
            print_error "这将导致下载游戏文件时出现'磁盘写入失败'错误。"
            echo ""
            echo "请手动运行: sudo chown -R 1000:1000 data/"
            echo ""
            exit 1
        fi
        print_success "目录已创建并设置权限！"
    else
        print_warning "无法设置权限，尝试使用 sudo..."
        if sudo chown -R 1000:1000 data/; then
            print_success "目录已创建并设置权限！"
        else
            print_error "设置权限失败！"
            print_error "这将导致下载游戏文件时出现'磁盘写入失败'错误。"
            echo ""
            echo "请手动运行: sudo chown -R 1000:1000 data/"
            echo ""
            exit 1
        fi
    fi
}

start_server() {
    print_step "步骤 5: 启动服务器..."
    echo ""

    print_info "拉取 Docker 镜像（可能需要几分钟）..."
    echo ""
    # 显示拉取进度
    if docker compose pull; then
        print_success "镜像拉取完成！"
    else
        print_warning "拉取镜像时出现错误，尝试启动..."
    fi

    echo ""
    print_info "启动服务器..."
    if docker compose up -d; then
        print_success "服务器已启动！"
    else
        print_error "启动失败！"
        echo ""
        echo "查看日志以了解详情:"
        echo -e "  ${CYAN}docker compose logs${NC}"
        exit 1
    fi

    print_info "等待服务器初始化（5秒）..."
    sleep 5

    if docker ps | grep -q puppy-stardew; then
        print_success "服务器正在运行！"
    else
        print_error "容器启动失败！"
        echo ""
        echo "查看日志:"
        echo -e "  ${CYAN}docker logs puppy-stardew${NC}"
        exit 1
    fi
}

get_server_ip() {
    # 尝试获取公网 IP
    if command -v curl &> /dev/null; then
        public_ip=$(curl -s ifconfig.me 2>/dev/null || curl -s ip.sb 2>/dev/null || echo "")
        if [ -n "$public_ip" ]; then
            echo "$public_ip"
            return
        fi
    fi

    # 回退到本地 IP
    if command -v hostname &> /dev/null; then
        hostname -I 2>/dev/null | awk '{print $1}' || echo "your-server-ip"
    else
        echo "your-server-ip"
    fi
}

print_next_steps() {
    echo ""
    echo -e "${GREEN}${BOLD}🎉 设置完成！接下来该做什么：${NC}"
    echo ""

    echo -e "${BOLD}1. 监控下载进度：${NC}"
    echo "   docker logs -f puppy-stardew"
    echo ""
    echo -e "${YELLOW}   首次启动将下载约 1.5GB 游戏文件。${NC}"
    echo -e "${YELLOW}   根据您的网络速度，通常需要 5-15 分钟。${NC}"
    echo ""

    echo -e "${BOLD}2. 如果启用了 Steam 令牌：${NC}"
    echo "   - 检查日志中是否有要求输入令牌代码的消息："
    echo -e "     ${CYAN}docker logs puppy-stardew | grep -i \"steam guard\"${NC}"
    echo "   - 如果看到 \"Steam Guard code:\" 提示，附加到容器："
    echo -e "     ${CYAN}docker attach puppy-stardew${NC}"
    echo "   - 输入从邮件/手机应用获取的 Steam 令牌代码并按回车"
    echo -e "   - ${YELLOW}重要：${NC}输入后等待3-5秒，确认开始下载游戏"
    echo -e "   - 然后按 ${YELLOW}Ctrl+P Ctrl+Q${NC} 分离（${RED}不要按 Ctrl+C！${NC}）"
    echo ""

    echo -e "${BOLD}3. 通过 VNC 初始设置（仅首次）：${NC}"
    echo "   - 下载 VNC 客户端（RealVNC、TightVNC 等）"
    echo -e "   - 连接到: ${CYAN}$(get_server_ip):5900${NC}"
    echo -e "   - 密码: ${CYAN}$(grep VNC_PASSWORD .env 2>/dev/null | cut -d'=' -f2 || echo 'stardew123')${NC}"
    echo "   - 在游戏中创建或加载存档文件"
    echo "   - 存档将在未来重启时自动加载！"
    echo ""

    echo -e "${BOLD}4. 玩家可以连接：${NC}"
    echo "   - 打开星露谷物语"
    echo "   - 点击"合作" → "加入局域网游戏""
    echo "   - 服务器会自动显示，或手动输入服务器 IP"
    echo -e "   ${YELLOW}⚠️  注意：只需输入 IP，端口 24642 是默认的无需指定${NC}"
    echo ""

    echo -e "${BOLD}常用命令：${NC}"
    echo -e "   查看日志:        ${CYAN}docker logs -f puppy-stardew${NC}"
    echo -e "   重启服务器:      ${CYAN}docker compose down && docker compose up -d${NC}"
    echo -e "   停止服务器:      ${CYAN}docker compose down${NC}"
    echo -e "   检查健康:        ${CYAN}./health-check.sh${NC}"
    echo -e "   备份存档:        ${CYAN}./backup.sh${NC}"
    echo ""
    echo -e "${YELLOW}   ⚠️  注意: 修改 .env 后必须重启才能生效！${NC}"
    echo ""

    echo -e "${GREEN}${BOLD}🌟 享受您的即时睡眠星露谷服务器！${NC}"
    echo ""

    # 询问是否查看日志
    ask_question "现在要查看日志吗？(y/n)"
    read -r watch_logs </dev/tty
    if [[ $watch_logs =~ ^[Yy]$ ]]; then
        echo ""
        print_info "显示日志...（按 Ctrl+C 退出）"
        echo ""
        docker logs -f puppy-stardew
    fi
}

# =============================================================================
# 主流程
# =============================================================================

main() {
    print_header
    check_docker
    download_files
    configure_steam
    setup_directories
    start_server
    print_next_steps
}

# 运行主函数
main
