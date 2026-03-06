# google_idx-keepalive
谷歌idx机器保活

====**我不会编程,脚本都是ai写的,我提要求,经过了多次改进,目前运行良好.只是想在这分享一下我的方法**====

我在mac电脑上想保活google idx的vm,先按照网上说的下载浏览器插件autofresh,可以是可以,但是要一直开着浏览器,我看了一下占用了2G多内存. 
后来我想长时间这样也会被google发现,并且我也不需要24小时开机,就开始实验设置了电脑晚上12点自动休眠,早晨7点唤醒.
再后来,我发现通过cloudflare的tunnel可以两台机器连接到一个tunnel,于是我设置了上午一台下午一台,2pm换班,这样我一台机器才用七八个小时,非常正常. 
我想天天早晨7点0分0秒开机,如果每天如此,如果是用ai来检测点,迟早也会发现.加上一个随机sleep解决了.
再后来,我突然想到我其实根本不用一直开着浏览器啊,并且连插件也不用了,只需要过一段时间打开一下就可以了,这样不占用内存.
并且我自己用chrome浏览器,这个firefox就是专门为了干这件事才装的. 如果我正在用电脑执行了,我就不管它,如果没用电脑,它自己打开然后关闭.

解释一下脚本,第一次开机(冷启动)需要时间长点,并且多台机器不能一起开,必须要在前台足够的时间. 有时候台湾的机器还资源不够时间可能更长.如果已经开机了,重新再打开1分钟已经足够了. (你可以根据自己使用的体验调整). 


脚本内容如下:

在open后面增加一个 -g参数, 这样启动的时候不会争夺焦点.
#电脑每天晚上自动休眠,早晨自动唤醒,时间根据自己需要设置.



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
        TARGET="https://idx.google.com/u/1/tw2-58654741"
    else
        TARGET="https://idx.google.com/tw-72229284"
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
    open -g -a "firefox" "https://idx.google.com/u/1/idx-eu-67360637"
sleep $((60 + RANDOM % 120))
    # 彻底关闭进程
    pkill -15 "firefox"
    echo "$(date +%T) | 本轮结束。"
done
