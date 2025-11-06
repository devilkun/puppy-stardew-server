#!/bin/bash
# Puppy Stardew Server Entrypoint Script - v1.0.47
# 小狗星谷服务器启动脚本 - v1.0.47

# DO NOT use set -e - we need manual error handling
# 不使用 set -e - 需要手动错误处理

# Color codes for pretty logging
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[Puppy-Stardew]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[Puppy-Stardew]${NC} $1"
}

log_error() {
    echo -e "${RED}[Puppy-Stardew]${NC} $1"
}

log_step() {
    echo -e "${BLUE}${1}${NC}"
}

log_steam() {
    echo -e "${CYAN}$1${NC}"
}

# Function to download game via steamcmd
# 下载游戏函数
download_game_via_steam() {
    log_info "========================================="
    log_info "  Starting Steam download process"
    log_info "  开始 Steam 下载流程"
    log_info "========================================="
    log_info ""
    log_info "If Steam Guard is required, you will see a prompt."
    log_info "如果需要 Steam Guard，您会看到提示。"
    log_info ""
    log_info "To input Steam Guard code:"
    log_info "输入 Steam Guard 验证码："
    log_info "  1. You should already have run: docker attach puppy-stardew"
    log_info "  1. 您应该已经运行了：docker attach puppy-stardew"
    log_info "  2. Enter the code when prompted below"
    log_info "  2. 在下面提示时输入验证码"
    log_info "  3. Press ENTER"
    log_info "  3. 按回车"
    log_info ""
    log_info "After successful authentication, game will download (~708MB)"
    log_info "验证成功后，游戏将开始下载（约708MB）"
    log_info "========================================="
    log_info ""

    # Run steamcmd WITHOUT pipe - this preserves stdin!
    # 运行 steamcmd 不使用管道 - 保留stdin！
    /home/steam/steamcmd/steamcmd.sh \
        +force_install_dir /home/steam/stardewvalley \
        +login "$STEAM_USERNAME" "$STEAM_PASSWORD" \
        +app_update 413150 validate \
        +quit

    DOWNLOAD_EXIT_CODE=$?

    # Check result
    if [ -f "/home/steam/stardewvalley/StardewValley" ]; then
        log_info "✅ Game downloaded successfully!"
        log_info "✅ 游戏下载完成！"
        return 0
    else
        log_error "❌ Game download failed (exit code: $DOWNLOAD_EXIT_CODE)"
        log_error "❌ 游戏下载失败（退出码：$DOWNLOAD_EXIT_CODE）"
        log_error ""
        log_error "Common causes / 常见原因："
        log_error "  1. Steam Guard code incorrect / Steam Guard 验证码错误"
        log_error "  2. Network timeout / 网络超时"
        log_error "  3. Insufficient disk space / 磁盘空间不足"
        log_error "  4. Steam API rate limit / Steam API 速率限制"
        return 1
    fi
}

# =============================================
# Main Script Starts Here
# 主脚本从这里开始
# =============================================

log_step "================================================"
log_step "  Puppy Stardew Server v1.0.47 Starting..."
log_step "  小狗星谷服务器 v1.0.47 启动中..."
log_step "================================================"

# Step 1: Validate Steam credentials
log_step "Step 1: Validating configuration..."

if [ -z "$STEAM_USERNAME" ] || [ -z "$STEAM_PASSWORD" ]; then
    log_error "STEAM_USERNAME or STEAM_PASSWORD not set!"
    log_error "STEAM_USERNAME 或 STEAM_PASSWORD 未设置！"
    log_error "Please configure .env file."
    log_error "请配置 .env 文件。"
    exit 1
fi

log_info "Steam username: $STEAM_USERNAME"

# Step 2: Fix libcurl compatibility
log_step "Step 2: Setting up system compatibility..."

if [ ! -f "/usr/lib/x86_64-linux-gnu/libcurl.so.4" ]; then
    log_info "Creating libcurl symlink for SteamCMD..."
    rm -f /usr/lib/x86_64-linux-gnu/libcurl.so.4 2>/dev/null || true
    ln -sf /usr/lib/i386-linux-gnu/libcurl.so.4 /usr/lib/x86_64-linux-gnu/libcurl.so.4
    log_info "libcurl compatibility fixed!"
fi

# Step 3: Download game if needed
if [ ! -f "/home/steam/stardewvalley/StardewValley" ]; then
    log_step "Step 3: Downloading Stardew Valley..."
    log_warn "Game files not found. Downloading from Steam..."
    log_warn "未找到游戏文件。正在从 Steam 下载..."
    log_warn "This will take 5-10 minutes depending on your connection."
    log_warn "根据网络情况，此过程需要 5-10 分钟。"
    log_warn ""

    # Clean up any existing Steam cache
    log_info "Cleaning Steam cache..."
    rm -rf /home/steam/Steam/config/* 2>/dev/null || true
    rm -rf /home/steam/Steam/logs/* 2>/dev/null || true
    rm -rf /tmp/steam* 2>/dev/null || true

    # Download game (handles Steam Guard automatically)
    if ! download_game_via_steam; then
        log_error "Failed to download game. Container will exit."
        log_error "游戏下载失败。容器将退出。"
        exit 1
    fi
else
    log_step "Step 3: Game files found, skipping download"
    log_info "✓ Stardew Valley already downloaded"
    log_info "✓ 星露谷物语已下载"
fi

# Step 4: Install SMAPI
log_step "Step 4: Installing SMAPI mod loader..."

if [ ! -f "/home/steam/stardewvalley/StardewModdingAPI" ]; then
    log_info "Installing SMAPI..."
    cd /home/steam
    echo "1" | dotnet smapi/SMAPI*/internal/linux/SMAPI.Installer.dll --install --game-path /home/steam/stardewvalley

    if [ $? -ne 0 ]; then
        log_error "Failed to install SMAPI!"
        log_error "SMAPI 安装失败！"
        exit 1
    fi

    log_info "✓ SMAPI installed successfully!"
else
    log_info "✓ SMAPI already installed"
fi

# Step 5: Install mods
log_step "Step 5: Installing mods..."

mkdir -p /home/steam/stardewvalley/Mods

if [ -d "/home/steam/preinstalled-mods" ]; then
    if [ -d "/home/steam/stardewvalley/Mods/AutoHideHost" ]; then
        log_info "✓ Mods already installed"
    else
        log_info "Installing mods..."
        cp -r /home/steam/preinstalled-mods/* /home/steam/stardewvalley/Mods/
        log_info "✓ Mods installed successfully!"
    fi

    log_info "Installed mods:"
    ls -1 /home/steam/stardewvalley/Mods/ | while read mod; do
        log_info "  ✓ $mod"
    done
fi

# Step 6: Setup virtual display
log_step "Step 6: Starting virtual display..."

rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null || true
Xvfb :99 -screen 0 1280x720x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99
sleep 3

log_info "✓ Virtual display started on :99 (1280x720)"

# Step 7: Start VNC server (optional)
if [ "$ENABLE_VNC" = "true" ]; then
    log_step "Step 7: Starting VNC server..."

    VNC_PASSWORD=${VNC_PASSWORD:-"stardew1"}

    if [ ${#VNC_PASSWORD} -gt 8 ]; then
        log_warn "VNC password > 8 chars, truncating to: ${VNC_PASSWORD:0:8}"
        VNC_PASSWORD="${VNC_PASSWORD:0:8}"
    fi

    # Wait for Xvfb to be fully ready
    sleep 2

    # Start x11vnc with plaintext password (more reliable than password file)
    log_info "Starting x11vnc on port 5900..."
    x11vnc -display :99 -forever -shared -passwd "$VNC_PASSWORD" -rfbport 5900 -noxdamage -bg 2>&1 | grep -v "^$"

    # Wait for x11vnc to start
    sleep 2

    # Verify VNC is running
    if pgrep -x "x11vnc" >/dev/null; then
        log_info "✓ VNC server started successfully on port 5900"
        log_info "  Password: $VNC_PASSWORD"
        log_info "  Connect to: your-server-ip:5900"
    else
        log_error "✗ VNC server failed to start"
        log_error "Check logs above for errors"
    fi
else
    log_step "Step 7: VNC disabled (set ENABLE_VNC=true to enable)"
fi

# Step 8: Start log monitoring (optional)
if [ "$ENABLE_LOG_MONITOR" = "true" ]; then
    log_step "Step 8: Starting log monitoring..."

    if [ -f "/home/steam/scripts/log-monitor.sh" ]; then
        /home/steam/scripts/log-monitor.sh &
        log_info "✓ Log monitoring started"
    fi
else
    log_step "Step 8: Log monitoring disabled"
fi

# Step 9: Start game server
log_step "Step 9: Starting game server..."
log_info "================================================"
log_info "  Server is starting!"
log_info "  服务器启动中！"
log_info "================================================"
log_info ""
log_info "To create/load a save:"
log_info "要创建/加载存档："
log_info "  1. Connect via VNC: localhost:5900 (password: $VNC_PASSWORD)"
log_info "  1. 通过 VNC 连接：localhost:5900（密码：$VNC_PASSWORD）"
log_info "  2. Click CO-OP → Start new co-op farm"
log_info "  2. 点击 CO-OP → 开始新的联机农场"
log_info ""
log_info "Players connect via:"
log_info "玩家连接方式："
log_info "  Game → CO-OP → Enter Invite Code"
log_info "  游戏 → CO-OP → 输入邀请码"
log_info "  (Code shown in logs below)"
log_info "  （邀请码显示在下方日志中）"
log_info "================================================"
log_info ""

cd /home/steam/stardewvalley

# Start auto-enable script in background
log_info "Starting auto-enable Always On Server script..."
/home/steam/scripts/auto-enable-server.sh &

# Start auto-handle ReadyCheckDialog script in background
log_info "Starting auto-handle ReadyCheckDialog script..."
/home/steam/scripts/auto-handle-readycheck.sh &

# Run game server (this runs in foreground)
exec ./StardewModdingAPI --server
