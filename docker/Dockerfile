# Puppy Stardew Server - Public Version
# 小狗星谷服务器 - 公开版本
#
# This Docker image does NOT include the game files.
# Users must provide their own Steam credentials to download Stardew Valley.
# 此镜像不包含游戏本体文件。
# 用户需要提供自己的 Steam 账号来下载星露谷物语。

FROM ubuntu:22.04

# Prevent interactive prompts during installation
# 避免安装过程中的交互提示
ENV DEBIAN_FRONTEND=noninteractive

LABEL maintainer="truemanlive" \
      description="Stardew Valley dedicated server with auto-pause and instant sleep" \
      version="1.0.66"

# Enable 32-bit architecture for SteamCMD
# 启用32位架构支持以安装SteamCMD
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    unzip \
    ca-certificates \
    lib32gcc-s1 \
    libsdl2-2.0-0 \
    libcurl3-gnutls:i386 \
    tmux \
    net-tools \
    procps \
    libgl1-mesa-dri libgl1-mesa-glx mesa-utils libegl1-mesa \
    xserver-xorg-core xserver-xorg-video-modesetting x11-xserver-utils x11-apps \
    xvfb \
    x11vnc \
    openbox \
    expect \
    xdotool \
    dotnet-runtime-6.0 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
# 创建非 root 用户以提高安全性
RUN useradd -m -s /bin/bash steam && \
    mkdir -p /home/steam/steamcmd /home/steam/stardewvalley /home/steam/.config/StardewValley && \
    chown -R steam:steam /home/steam && \
    usermod -aG video steam || true

# Xorg modesetting config for using Intel/AMD integrated GPUs (glamor + DRI3)
# 为 Xorg 创建配置文件以启用 modesetting/glamor
RUN mkdir -p /etc/X11/xorg.conf.d && \
    cat > /etc/X11/xorg.conf.d/20-modesetting.conf <<'EOF'
Section "Device"
  Identifier "IntelGPU0"
  Driver "modesetting"
  Option "AccelMethod" "glamor"
  Option "DRI" "3"
EndSection
EOF

# Set working directory and switch to steam user
WORKDIR /home/steam
USER steam

# Download and extract SteamCMD
# 下载并解压 SteamCMD
RUN wget -qO- 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | \
    tar zxvf - -C /home/steam/steamcmd

# Download and install SMAPI (Stardew Modding API)
# 下载并安装 SMAPI（星露谷模组API）
RUN wget -qO smapi.zip 'https://github.com/Pathoschild/SMAPI/releases/download/4.3.2/SMAPI-4.3.2-installer.zip' && \
    unzip -q smapi.zip -d smapi && \
    rm smapi.zip

# Copy pre-configured mods to a temporary location
# 将预配置的模组复制到临时位置
USER root
COPY mods/ /home/steam/preinstalled-mods/
RUN chown -R steam:steam /home/steam/preinstalled-mods && \
    chmod -R 755 /home/steam/preinstalled-mods
USER steam

# Copy scripts
# 复制脚本
RUN mkdir -p /home/steam/scripts
COPY --chown=steam:steam scripts/entrypoint.sh /home/steam/entrypoint.sh
COPY --chown=steam:steam scripts/log-manager.sh /home/steam/scripts/log-manager.sh
COPY --chown=steam:steam scripts/log-monitor.sh /home/steam/scripts/log-monitor.sh
COPY --chown=steam:steam scripts/view-logs.sh /home/steam/scripts/view-logs.sh
COPY --chown=steam:steam scripts/event-handler.sh /home/steam/scripts/event-handler.sh
COPY --chown=steam:steam scripts/auto-backup.sh /home/steam/scripts/auto-backup.sh
COPY --chown=steam:steam scripts/vnc-monitor.sh /home/steam/scripts/vnc-monitor.sh
COPY --chown=steam:steam scripts/set-resolution.sh /home/steam/scripts/set-resolution.sh
RUN chmod +x /home/steam/entrypoint.sh /home/steam/scripts/*.sh

# Copy optimized game config template for VNC display
# 复制VNC显示优化的游戏配置模板
COPY --chown=steam:steam config/startup_preferences /home/steam/startup_preferences.template
# Copy Xorg monitor config to set a default resolution
# 复制 Xorg 显示器配置以设置默认分辨率
COPY --chown=steam:steam config/10-monitor.conf /etc/X11/xorg.conf.d/10-monitor.conf

# Run as root to allow permission fixes on startup
# 以 root 身份运行以允许启动时修复权限
USER root

# Expose game port (UDP) and VNC port (TCP)
# 暴露游戏端口（UDP）和 VNC 端口（TCP）
EXPOSE 24642/udp 5900/tcp

# Health check to ensure server is running
# 健康检查确保服务器正在运行
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD pgrep -f "StardewModdingAPI" > /dev/null || exit 1

# Set entrypoint
# 设置启动脚本
ENTRYPOINT ["/home/steam/entrypoint.sh"]
