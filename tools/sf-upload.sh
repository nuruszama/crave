#!/usr/bin/env bash

# ==============================================================================
# Universal SourceForge Uploader
# Works on Termux, Linux Desktop, macOS, and WSL
# ==============================================================================

# SourceForge Credentials & Keys (Overridden via environment variables if set)
SF_USER="${SF_USER:-nuruszama}"
SF_PROJECT="${SF_PROJECT:-xiaomicreek}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"
KNOWN_HOSTS="$HOME/.ssh/known_hosts"

# Auto-detect Termux vs Standard Linux/macOS
if [ -d "/data/data/com.termux" ]; then
    SSH_OPTS="-o UserKnownHostsFile=${KNOWN_HOSTS} -o GlobalKnownHostsFile=/dev/null -i ${SSH_KEY}"
else
    SSH_OPTS="-i ${SSH_KEY}"
fi

# Help / Usage check
if [ -z "$1" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Usage: ./upload.sh <file_path> [Android_Version] [ROM_Name]"
    echo ""
    echo "Examples:"
    echo "  ./upload.sh LineageOS-16-20260906-creek.zip"
    echo "  ./upload.sh build.zip 16 EvolutionX"
    echo ""
    echo "Environment Overrides:"
    echo "  SF_USER=myuser SF_PROJECT=myproject ANDROID_VER=16 ROM_NAME=EvolutionX ./upload.sh file.zip"
    exit 0
fi

FILE_PATH="$1"

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File '$FILE_PATH' not found!"
    exit 1
fi

FILE_NAME=$(basename "$FILE_PATH")

# 1. Android Version: Passed Arg ($2) -> Environment Var ($ANDROID_VER) -> Default (16)
ANDROID_VER="${2:-${ANDROID_VER:-16}}"

# 2. ROM Name: Passed Arg ($3) -> Environment Var ($ROM_NAME) -> Auto-detect -> Default (LineageOS)
if [ -n "$3" ]; then
    ROM_NAME="$3"
elif [ -z "$ROM_NAME" ]; then
    if [[ "$FILE_NAME" =~ [eE]volution|[eE]vo ]]; then ROM_NAME="EvolutionX";
    elif [[ "$FILE_NAME" =~ [lL]ineage|[lL]os ]]; then ROM_NAME="LineageOS";
    elif [[ "$FILE_NAME" =~ [pP]ixel ]]; then ROM_NAME="PixelOS";
    else ROM_NAME="LineageOS";
    fi
fi

# TARGET STRUCTURE: <SF_PROJECT> / <ANDROID_VER> / <ROM_NAME>
REMOTE_DIR="/home/frs/project/${SF_PROJECT}/${ANDROID_VER}/${ROM_NAME}"

echo "=================================================="
echo " Device:      $([ -d "/data/data/com.termux" ] && echo "Termux" || echo "Linux PC / Mac")"
echo " User:        ${SF_USER}"
echo " Project:     ${SF_PROJECT}"
echo " File:        ${FILE_NAME}"
echo " Destination: /${SF_PROJECT}/${ANDROID_VER}/${ROM_NAME}/"
echo "=================================================="

# Execute SFTP commands
sftp ${SSH_OPTS} ${SF_USER}@frs.sourceforge.net <<EOF
-mkdir /home/frs/project/${SF_PROJECT}
-mkdir /home/frs/project/${SF_PROJECT}/${ANDROID_VER}
-mkdir /home/frs/project/${SF_PROJECT}/${ANDROID_VER}/${ROM_NAME}
cd ${REMOTE_DIR}
put ${FILE_PATH}
exit
EOF

if [ $? -eq 0 ]; then
    echo -e "\n[SUCCESS] Upload finished successfully!"
else
    echo -e "\n[ERROR] Upload failed. Check network or SSH configuration."
    exit 1
fi
