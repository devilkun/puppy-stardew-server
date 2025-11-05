#!/bin/bash
# Auto-Enable Always On Server - Background Script
# 自动启用 Always On Server 的后台脚本
# 使用 xdotool 模拟 F9 键盘按键

SMAPI_LOG="/home/steam/.config/StardewValley/ErrorLogs/SMAPI-latest.txt"
MAX_WAIT=120  # 最多等待 120 秒
CHECK_INTERVAL=2  # 每 2 秒检查一次

log() {
    echo -e "\033[0;36m[Auto-Enable-Server]\033[0m $1"
}

log "启动 Always On Server 自动启用服务..."

# 等待游戏窗口启动
log "等待游戏初始化..."
sleep 10

log "等待存档加载完成..."

elapsed=0
while [ $elapsed -lt $MAX_WAIT ]; do
    # 检查 SMAPI 日志文件是否存在
    if [ -f "$SMAPI_LOG" ]; then
        # 检查存档是否加载成功
        if grep -q "SAVE LOADED SUCCESSFULLY\|Context: loaded save" "$SMAPI_LOG" 2>/dev/null; then
            log "✓ 检测到存档已加载"

            # 额外等待 5 秒，确保所有模组初始化完成
            log "等待模组初始化..."
            sleep 5

            # 使用 xdotool 模拟按 F9 键（重试最多3次）
            MAX_RETRIES=3
            RETRY=0
            SUCCESS=false

            while [ $RETRY -lt $MAX_RETRIES ]; do
                log "模拟按 F9 键启用 Always On Server (尝试 $((RETRY + 1))/$MAX_RETRIES)..."

                # 设置 DISPLAY 环境变量
                export DISPLAY=:99

                # 使用 xdotool 模拟按键
                if command -v xdotool >/dev/null 2>&1; then
                    # 连续按 3 次 F9 确保生效
                    xdotool key F9
                    sleep 0.5
                    xdotool key F9
                    sleep 0.5
                    xdotool key F9

                    log "✓ F9 按键已发送"
                    sleep 5

                    # 验证是否成功 - 检查多种可能的成功标志
                    if grep -qi "Auto [Mm]ode [Oo]n\|Server Mode: On\|serverMode.*true" "$SMAPI_LOG" 2>/dev/null; then
                        log "✅ Always On Server 已成功启用！"
                        log "✅ 自动暂停功能已激活（无玩家时暂停，有玩家时继续）"
                        SUCCESS=true
                        break
                    else
                        log "⚠ 未检测到成功消息，等待后重试..."
                        sleep 3
                    fi
                else
                    log "❌ xdotool 未安装"
                    break
                fi

                RETRY=$((RETRY + 1))
            done

            if [ "$SUCCESS" = true ]; then
                exit 0
            else
                log "⚠ 自动启用可能失败"
                log "   验证方法："
                log "   1. 检查游戏是否暂停（无玩家时应该暂停）"
                log "   2. 玩家连接后游戏应该自动继续"
                log "   3. 如果游戏一直运行，说明 Server Mode 未启用"
                exit 0  # 不返回错误，因为可能已经启用但日志中没有明确标识
            fi
        fi
    fi

    sleep $CHECK_INTERVAL
    elapsed=$((elapsed + CHECK_INTERVAL))
done

log "⚠ 等待超时（${MAX_WAIT}秒），存档未加载"
log "Always On Server 可能未自动启用"
exit 1
