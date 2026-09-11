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
    doc="$1"
    # Check if build variables are set and non-empty
    if [ -n "${ROM_NAME}" ] && [ -n "${BUILD_CONFIG}" ] && [ -n "${DEVICE}" ]; then
        caption="${ROM_NAME}-${BUILD_CONFIG}-${DEVICE}.json"
    else
        echo "Warning: Build variables missing. Falling back to input filename." >&2
        caption="$(basename "$doc")"
    fi
else
    echo "Usage: $0 [file dir]" >&2
    exit 1
fi

echo "Sending build update to ${TG_PERSONAL}..."

# Send document with corrected variable and form-data upload
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
  -F "chat_id=${TG_PERSONAL}" \
  -F "document=@${doc}" \
  -F "caption=${caption}" \
  -F "disable_web_page_preview=true"

echo -e "\n[+] Release data shared to Telegram inbox."
