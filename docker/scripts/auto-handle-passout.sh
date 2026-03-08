#!/bin/bash
# Auto-Handle Passout (2AM) - Background Script
# 自动处理凌晨2点晕倒 - 后台脚本
#
# When players stay up past 2 AM, they pass out and should automatically rest.
# Sometimes the host fails to trigger rest, causing the game to freeze.
# This script detects the passout event and simulates movement to trigger rest.
# 当玩家熬夜到凌晨2点，会晕倒并自动休息。
# 有时主机无法触发休息，导致游戏卡住。
# 此脚本检测晕倒事件并模拟移动来触发休息。

SMAPI_LOG="/home/steam/.config/StardewValley/ErrorLogs/SMAPI-latest.txt"
CHECK_INTERVAL=5  # Check every 5 seconds

log() {
    echo -e "\033[0;33m[Auto-Handle-Passout]\033[0m $1"
}

log "启动凌晨2点晕倒自动处理服务..."
log "检查间隔: ${CHECK_INTERVAL}秒"

# Set DISPLAY environment variable
export DISPLAY=:99

# Wait for game initialization
log "等待游戏初始化..."
sleep 20

# Track last handled time to avoid duplicate handling
LAST_HANDLE_TIME=0

while true; do
    if [ -f "$SMAPI_LOG" ]; then
        CURRENT_TIME=$(date +%s)

        # Must be at least 30 seconds since last handle
        if [ $((CURRENT_TIME - LAST_HANDLE_TIME)) -lt 30 ]; then
            sleep $CHECK_INTERVAL
            continue
        fi

        # Get recent log (last 50 lines to catch passout events)
        RECENT_LOG=$(tail -50 "$SMAPI_LOG" 2>/dev/null)

        # Detect passout/exhaustion patterns
        # Look for: "passed out", "exhausted", "collapsed", or time >= 2600 (2AM)
        if echo "$RECENT_LOG" | grep -qiE "passed out|exhausted|collapsed|fell asleep"; then
            log "⚠️ 检测到玩家晕倒事件（凌晨2点）"

            # Wait for event to fully trigger
            sleep 2

            if command -v xdotool >/dev/null 2>&1; then
                log "尝试触发主机休息..."

                # Step 1: Press F9 to activate game window
                log "  步骤 1: 按 F9 激活游戏窗口..."
                xdotool key F9
                sleep 1

                # Step 2: Move character to trigger rest animation
                log "  步骤 2: 移动角色触发休息动画..."
                # Move down, up, left, right to ensure character moves
                xdotool key Down
                sleep 0.3
                xdotool key Up
                sleep 0.3
                xdotool key Left
                sleep 0.3
                xdotool key Right
                sleep 0.5

                # Step 3: Press Enter to confirm any dialogs
                log "  步骤 3: 按 Enter 确认对话框..."
                xdotool key Return
                sleep 0.5
                xdotool key Return

                log "✅ 已尝试触发主机休息"

                # Record handle time
                LAST_HANDLE_TIME=$(date +%s)

                # Wait longer before next check
                sleep 30
            else
                log "❌ xdotool 未安装，无法自动处理"
            fi
        fi
    fi

    sleep $CHECK_INTERVAL
done
