#!/usr/bin/env bash

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found." >&2
    exit 1
fi

# Export variables from .env
set -a
source .env
set +a

# Clean TG_TOKEN
BOT_TOKEN="${TG_TOKEN#bot}"

if [ -f "$1" ]; then
    caption="${ROM_NAME}-${BUILD_CONFIG}-${DEVICE}.json"
    doc="$1"
else
    echo "Usage: $0 [file dir]" >&2
    exit 1
fi

echo "Sending build update to ${TG_PERSONAL}..."

# Send photo with caption or fall back to text message
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
  -d "chat_id=${TG_PERSONAL}" \
  -d "document=$1" \
  -d "caption=${CAPTION}" \
  -d "parse_mode=HTML" \
  -d "disable_web_page_preview=true"

echo -e "\n[+] Release data shared to Telegram inbox."
