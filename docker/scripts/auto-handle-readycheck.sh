#!/bin/bash
# Auto-Handle Blocking Menus - Background Script
# 自动处理阻塞性菜单（地震等特殊事件、技能升级等）

SMAPI_LOG="/home/steam/.config/StardewValley/ErrorLogs/SMAPI-latest.txt"
CHECK_INTERVAL=2  # 每 2 秒检查一次

log() {
    echo -e "\033[0;35m[Auto-Handle-Menus]\033[0m $1"
}

log "启动菜单自动处理服务..."
log "监控以下菜单类型："
log "  - ReadyCheckDialog（特殊事件确认，如地震）"
log "  - LevelUpMenu（技能升级选择）"
log "  - QuestContainerMenu（任务完成）"
log "  - ShippingMenu（出货菜单）"

# 设置 DISPLAY 环境变量
export DISPLAY=:99

# 上次处理的时间戳，避免重复处理
LAST_HANDLE_TIME=0

while true; do
    if [ -f "$SMAPI_LOG" ]; then
        CURRENT_TIME=$(date +%s)

        # 获取最近的日志内容
        RECENT_LOG=$(tail -100 "$SMAPI_LOG" 2>/dev/null)

        # 检测是否需要处理（距离上次处理超过5秒）
        if [ $((CURRENT_TIME - LAST_HANDLE_TIME)) -lt 5 ]; then
            sleep $CHECK_INTERVAL
            continue
        fi

        MENU_DETECTED=false
        MENU_TYPE=""
        KEY_TO_PRESS=""

        # 1. ReadyCheckDialog - 特殊事件确认（地震、解锁新区域等）
        if echo "$RECENT_LOG" | grep -q "ReadyCheckDialog"; then
            MENU_DETECTED=true
            MENU_TYPE="ReadyCheckDialog（特殊事件确认）"
            KEY_TO_PRESS="Return"  # Enter键

        # 2. LevelUpMenu - 技能升级选择
        elif echo "$RECENT_LOG" | grep -q "菜单变化.*LevelUpMenu\|Menu changed.*LevelUpMenu"; then
            MENU_DETECTED=true
            MENU_TYPE="LevelUpMenu（技能升级）"
            KEY_TO_PRESS="Escape"  # ESC键跳过选择（使用默认技能）

        # 3. QuestContainerMenu - 任务完成通知
        elif echo "$RECENT_LOG" | grep -q "菜单变化.*QuestContainerMenu\|Menu changed.*QuestContainerMenu"; then
            MENU_DETECTED=true
            MENU_TYPE="QuestContainerMenu（任务通知）"
            KEY_TO_PRESS="Escape"  # ESC键关闭

        # 4. ShippingMenu - 出货菜单（每日收益）
        elif echo "$RECENT_LOG" | grep -q "菜单变化.*ShippingMenu\|Menu changed.*ShippingMenu"; then
            MENU_DETECTED=true
            MENU_TYPE="ShippingMenu（出货菜单）"
            KEY_TO_PRESS="Escape"  # ESC键快速跳过

        # 5. ItemGrabMenu - 物品拾取菜单（如果卡住）
        elif echo "$RECENT_LOG" | grep -q "菜单变化.*ItemGrabMenu.*stuck\|Menu changed.*ItemGrabMenu.*stuck"; then
            MENU_DETECTED=true
            MENU_TYPE="ItemGrabMenu（物品菜单卡住）"
            KEY_TO_PRESS="Escape"  # ESC键关闭
        fi

        # 如果检测到需要处理的菜单
        if [ "$MENU_DETECTED" = true ]; then
            log "⚠️ 检测到阻塞菜单: $MENU_TYPE"

            # 等待菜单完全显示
            sleep 1

            # 使用 xdotool 模拟按键
            if command -v xdotool >/dev/null 2>&1; then
                log "模拟按 $KEY_TO_PRESS 键处理菜单..."

                # 连续按 3 次确保生效
                for i in 1 2 3; do
                    xdotool key "$KEY_TO_PRESS"
                    sleep 0.3
                done

                log "✅ 已发送按键，菜单应已处理"

                # 记录处理时间
                LAST_HANDLE_TIME=$(date +%s)

                # 等待一段时间再检查，避免重复处理
                sleep 5
            else
                log "❌ xdotool 未安装，无法自动处理"
            fi
        fi
    fi

    sleep $CHECK_INTERVAL
done
