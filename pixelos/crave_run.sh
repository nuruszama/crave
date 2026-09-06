#!/bin/bash

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️ .env file not found!"
else
    # Load your local secrets
    set -o allexport
    source .env
    set +o allexport
fi

# Define some requirements
export BUILD_USERNAME="${BUILD_USERNAME}"
export BUILD_HOSTNAME="${BUILD_HOSTNAME}"
export SKIP_ABI_CHECKS=true
export LINEAGE_UPDATER_URI="${OTA_URL}"

# remove device tree
rm -rf .repo/local_manifests
rm -rf device/xiaomi/creek
rm -rf vendor/xiaomi/creek

# re-initialize the lineage source
repo init -u https://github.com/PixelOS-AOSP/android_manifest.git -b sixteen-qpr2 --git-lfs --depth=1

#clone local manifest
git clone https://github.com/XiaomiCreek/android.git -b lineage-23.2 --depth=1 .repo/local_manifests

# resync the repo source
/opt/crave/resync.sh

# setup build env
source build/envsetup.sh

# prepare device menu
breakfast creek userdebug

# Clean intermediate cached system properties and staging dirs
make installclean

# start building
m pixelos

# Upload
echo "uploading file..."
ROM_DIR="out/target/product/creek/"
ZIP_FILE=$(ls "$ROM_DIR" | grep "PixelOS-creek-*.zip$" | tail -n 1)
if [ -n "${ZIP_FILE}" ]; then
    curl -sfLo upload.sh -z upload.sh https://raw.githubusercontent.com/nuruszama/crave/creek/tools/sf-upload.sh
    chmod +x upload.sh ; ./upload.sh "${ROM_DIR}${ZIP_FILE}"
    echo "upload done!"
else
    echo "no zip found at out/ dir..."
    exit 1
fi
