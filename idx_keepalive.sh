#!/bin/bash

# 1. 启动自锁：防止 crontab 或重复手动启动导致多个进程
[[ $(pgrep -f $(basename "$0") | wc -l) -gt 1 ]] && exit 0

LAST_HOUR=""

while true; do
    # --- 核心：反 AI 检测逻辑 ---
    PRE_SLEEP_TIME=$(date +%s)
    NEXT_SLEEP=$((1800 + RANDOM % 1200))
    echo "$(date +%T) | 计划随机休眠: ${NEXT_SLEEP}s"
    sleep $NEXT_SLEEP
    
    POST_SLEEP_TIME=$(date +%s)
    ELAPSED=$((POST_SLEEP_TIME - PRE_SLEEP_TIME))

    # 如果实际流逝时间比计划长很多（说明中间电脑休眠了）
    # 或者是早晨第一次唤醒，强制再增加一个随机延迟（0-15分钟）
    if [ $ELAPSED -gt $((NEXT_SLEEP + 30)) ]; then
        WAKE_DELAY=$((RANDOM % 900))
        echo "$(date +%T) | 检测到系统唤醒，为模拟真人，额外随机静默 ${WAKE_DELAY}s..."
        sleep $WAKE_DELAY
    fi

    # --- 业务逻辑 ---
    HOUR=$(date +%H)
    # 2PM 切换逻辑
    if [ "$HOUR" -ge 14 ]; then
        TARGET="https://idx.google.com/u/1/tw2"
    else
        TARGET="https://idx.google.com/tw1"
    fi

    # 判定冷启动 (180s) 还是 循环保活 (60s)
    [[ "$HOUR" != "$LAST_HOUR" ]] && WAIT=$((180 + RANDOM % 121)) || WAIT=$((60 + RANDOM % 121))
    LAST_HOUR=$HOUR

    # 执行操作
    open -a "nekoray_amd64"
    sleep 5
    
    echo "$(date +%T) | 访问主机器: $TARGET (${WAIT}s)"
    open -g -a "firefox" "$TARGET"
    sleep $WAIT

    echo "$(date +%T) | 访问辅助机器 (60-180s随机)"
    open -g -a "firefox" "https://idx.google.com/u/1/idx-eu"
sleep $((60 + RANDOM % 120))
    # 彻底关闭进程
    pkill -15 "firefox"
    echo "$(date +%T) | 本轮结束。"
done
