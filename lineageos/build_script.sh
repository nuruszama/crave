#!/bin/bash

clear

# Maintainer and Host Info
export BUILD_USERNAME="nuruszama"
export BUILD_HOSTNAME="creek"

# Custom Build Tag
export RELEASE_TYPE="RELEASE"

# Build Optimizations & Checks
export SKIP_ABI_CHECKS=true
export WITH_DEXPREOPT=true

# remove device tree
rm -rf .repo/local_manifests
rm -rf vendor/xiaomi/creek
rm -rf device/xiaomi/creek

# re-initialize the lineage source
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs --depth=1

# clone local manifest
git clone https://github.com/XiaomiCreek/android.git -b lineage-23.2 --depth=1 .repo/local_manifests

# resync the repo source
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# extract vendor tree
curl -sfLo vendorextract.sh -z vendorextract.sh https://raw.githubusercontent.com/nuruszama/crave/creek/tools/vendorextract.sh
chmod +x vendorextract.sh
./vendorextract.sh

# setup build env
source build/envsetup.sh

# prepare device menu
breakfast creek userdebug

# Clean staging dirs
make installclean

# start building
mka bacon

# Export environment variables for the upload script
export SF_USER="nuruszama"
export SF_PROJECT="xiaomicreek"
export ANDROID_VER="16"
export ROM_NAME="LineageOS"

# Custom SSH key location (if using a different key or path)
export SSH_KEY="$HOME/.ssh/id_ed25519"

# Upload
echo "uploading file..."
ROM_DIR="out/target/product/creek/"
ZIP_FILE=$(ls "$ROM_DIR" | grep "lineage-creek-*.zip$" | tail -n 1)
if [ -n "${ZIP_FILE}" ]; then
    curl -sfLo upload.sh -z upload.sh https://raw.githubusercontent.com/nuruszama/crave/creek/tools/sf-upload.sh
    chmod +x upload.sh ; ./upload.sh "${ROM_DIR}${ZIP_FILE}"
    echo "upload done!"
else
    echo "no zip found at out/ dir..."
    exit 1
fi
