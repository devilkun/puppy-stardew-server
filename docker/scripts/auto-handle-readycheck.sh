#!/bin/bash
# Auto-Handle ReadyCheckDialog - Background Script
# 自动处理ReadyCheckDialog（地震等特殊事件的确认对话框）

SMAPI_LOG="/home/steam/.config/StardewValley/ErrorLogs/SMAPI-latest.txt"
CHECK_INTERVAL=2  # 每 2 秒检查一次

log() {
    echo -e "\033[0;35m[Auto-Handle-ReadyCheck]\033[0m $1"
}

log "启动 ReadyCheckDialog 自动处理服务..."

# 设置 DISPLAY 环境变量
export DISPLAY=:99

while true; do
    # 检查 SMAPI 日志中是否出现 ReadyCheckDialog
    if [ -f "$SMAPI_LOG" ]; then
        # 检查最近10秒内是否有 ReadyCheckDialog
        if tail -100 "$SMAPI_LOG" 2>/dev/null | grep -q "ReadyCheckDialog"; then
            log "⚠️ 检测到 ReadyCheckDialog（特殊事件确认对话框）"

            # 等待对话框完全显示
            sleep 1

            # 使用 xdotool 模拟按 Enter 键确认
            if command -v xdotool >/dev/null 2>&1; then
                log "模拟按 Enter 键自动确认..."

                # 连续按 3 次 Enter 确保确认成功
                xdotool key Return
                sleep 0.3
                xdotool key Return
                sleep 0.3
                xdotool key Return

                log "✅ 已发送确认按键"

                # 等待一段时间再检查，避免重复处理同一个对话框
                sleep 5
            else
                log "❌ xdotool 未安装，无法自动确认"
            fi
        fi
    fi

    sleep $CHECK_INTERVAL
done
