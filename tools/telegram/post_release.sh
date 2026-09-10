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

# Determine message text (from file if it exists, otherwise from argument $1)
if [ -f "changelog.txt" ]; then
    CHANGELOG=$(cat changelog.txt)
elif [ -n "$1" ]; then
    CHANGELOG="$1"
else
    echo "Usage: $0 <caption> [rom_url] [recovery_url]" >&2
    exit 1
fi

# Optional URLs passed as arguments $2 and $3, or set from environment
ROM_URL="${2:-$ROM_DOWNLOAD_URL}"
REC_URL="${3:-$REC_DOWNLOAD_URL}"
SCREENSHOTS="${SCREENSHOTS:-https://t.me/creekglobal}"
DISCUSSION="${DISCUSSION:-https://t.me/creekglobal}"

HEADER="#${ROM_NAME} #${RELEASE_TYPE} #${DEVICE_CODENAME} #A${ANDROID_VERSION}

<b>${ROM_NAME}-${ROM_VERSION} for ${DEVICE_CODENAME}</b>"
TAGS="• <b>Android version:</b> ${ANDROID_VERSION}
• <b>Build type:</b> ${BUILD_TYPE}
• <b>Build date:</b> ${BUILD_DATE}"

FLASHING_STEPS="• flash the rom with any recovery
(keep recovery reflashing unticked if ofox)
• reboot to the ${ROM_NAME} recovery
• do a format
• reboot to system"

CREDITS="@Sarojtaj77 @therealmharc @nuruszama
@Yozemitas @Lufrz @vivekachooz @Liieko"

FOOTER="<a href=\"${ROM_URL}\">Download</a> | <a href=\"${DISCUSSION}\">Discussion</a> | <a href=\"${REC_URL}\">Recovery</a> | <a href=\"${SCREENSHOTS}\">Screenshots</a>"

# Caption Template Assembly (HTML)
CAPTION="${HEADER}
<blockquote>${TAGS}</blockquote>
<b>Changelog</b>
<blockquote>${CHANGELOG}</blockquote>
<b>Flashing Steps (first time)</b>
<blockquote>${FLASHING_STEPS}</blockquote>
<b>Additional Credits</b>
<blockquote>${CREDITS}</blockquote>

${FOOTER}"

echo "Sending build update with buttons to ${TG_CHANNEL}..."

# Send photo with caption or fall back to text message
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendPhoto" \
  -d "chat_id=${CHAT_ID}" \
  -d "photo=${BANNER}" \
  -d "caption=${CAPTION}" \
  -d "parse_mode=HTML" \
  -d "disable_web_page_preview=true"

echo -e "\n[+] Release posted successfully to Telegram."
