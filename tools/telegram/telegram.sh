#!/bin/bash

# This script will run telegram message functions.
#
#  [ USAGE ]
# 
# 1. send_tg "your message"
# 2. edit_tg "your message"
# 3. reply_tg "your message"
#
# on the first send_tg, the script will capture the message id for the next usage.

# Send telegram message
send_tg() {
    # Append new log entry
    BUILD_HISTORY="🌏 _$(date +"%d %b %Y %I:%M %p GST")_
${1}"
    
    local response
    response=$(curl -sS \
        -X POST \
        "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${TG_CHAT}" \
        --data-urlencode "parse_mode=Markdown" \
        --data-urlencode "disable_web_page_preview=true" \
        --data-urlencode "text=${BUILD_HISTORY}")

    MSG_ID=$(echo "$response" | grep -o '"message_id":[0-9]*' | cut -d: -f2)

    export MSG_ID
    export BUILD_HISTORY
}

# Edit existing telegram message
edit_tg() {

    [ -z "$MSG_ID" ] && {send_tg "${1}" | return}

    # Append new log entry
    BUILD_HISTORY="${BUILD_HISTORY}

🌏 _$(date +"%d %b %Y %I:%M %p GST")_
${1}"

    curl -sS \
        -X POST \
        "https://api.telegram.org/bot${TG_TOKEN}/editMessageText" \
        --data-urlencode "chat_id=${TG_CHAT}" \
        --data-urlencode "message_id=${ID}" \
        --data-urlencode "parse_mode=Markdown" \
        --data-urlencode "disable_web_page_preview=true" \
        --data-urlencode "text=${BUILD_HISTORY}" \
        >/dev/null

    export BUILD_HISTORY
}

# reply to initial telegram message
reply_tg() {
    local TEXT="🌏 _$(date +"%d %b %Y %I:%M %p GST")_
${1}"

    curl -sS \
        -X POST \
        "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${TG_CHAT}" \
        --data-urlencode "parse_mode=Markdown" \
        --data-urlencode "disable_web_page_preview=true" \
        --data-urlencode "reply_parameters={\"message_id\":${MSG_ID}}" \
        --data-urlencode "text=${TEXT}" \
        >/dev/null
}

# Send a file document to telegram
send_tg_doc() {
    local file_path="${1}"
    local caption="${2}"

    curl -sS \
        -X POST \
        "https://api.telegram.org/bot${TG_TOKEN}/sendDocument" \
        -F "chat_id=${TG_CHAT}" \
        -F "document=@${file_path}" \
        -F "parse_mode=Markdown" \
        -F "reply_parameters={\"message_id\":${MSG_ID}}" \
        -F "caption=${caption}" \
        >/dev/null
}