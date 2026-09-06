#!/bin/bash
set -e

clear

# Maintainer and Host Info
export BUILD_USERNAME="nuruszama"
export BUILD_HOSTNAME="creek"

# Build Optimizations & Checks
export SKIP_ABI_CHECKS=true
export WITH_DEXPREOPT=true

# Clean up qcom-caf hardware repo without deleting it
if [ -d "hardware/qcom-caf/common" ]; then
    echo "==> Resetting hardware/qcom-caf/common..."
    git -C hardware/qcom-caf/common checkout . 2>/dev/null || true
    git -C hardware/qcom-caf/common clean -fd 2>/dev/null || true
fi

# Ensure git cleanup always runs even if the build is interrupted or fails
cleanup_updater() {
    echo "==> Restoring original Updater strings.xml..."
    if [ -d "packages/apps/Updater" ]; then
        git -C packages/apps/Updater checkout app/src/main/res/values/strings.xml 2>/dev/null || true
    fi
}
trap cleanup_updater EXIT

# Remove local manifest and device/vendor trees to allow fresh local_manifest sync
rm -rf .repo/local_manifests
rm -rf vendor/xiaomi/creek-kernel
rm -rf vendor/xiaomi/creek
rm -rf device/xiaomi/creek

# Re-initialize the source
repo init -u https://github.com/Evolution-X/manifest -b bka --git-lfs --depth=1

# Clone local manifest
git clone https://github.com/XiaomiCreek/android.git -b lineage-23.2 --depth=1 .repo/local_manifests

# Resync the repo source
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# Change the update url string in updater app
if [ -f "packages/apps/Updater/app/src/main/res/values/strings.xml" ]; then
    echo "==> Patching Updater URL..."
    sed -i 's/Evolution-X\/OTA/XiaomiCreek\/OTA/g' packages/apps/Updater/app/src/main/res/values/strings.xml
fi

# Setup build env
source build/envsetup.sh

# Extract vendor tree
./vendorextract.sh

# Prepare device menu
breakfast creek userdebug

# Clean staging dirs
make installclean

# Start building
m evolution

# Export environment variables for the upload script
export SF_USER="nuruszama"
export SF_PROJECT="xiaomicreek"
export ANDROID_VER="16"
export ROM_NAME="EvolutionX"

# Custom SSH key location (if using a different key or path)
export SSH_KEY="$HOME/.ssh/id_ed25519"

# Upload
echo "uploading file..."
ROM_DIR="out/target/product/creek/"
ZIP_FILE=$(ls "$ROM_DIR" | grep "EvolutionX-*.zip$" | tail -n 1)
if [ -n "${ZIP_FILE}" ]; then
    curl -sfLo upload.sh -z upload.sh https://raw.githubusercontent.com/nuruszama/crave/creek/tools/sf-upload.sh
    chmod +x upload.sh ; ./upload.sh "${ROM_DIR}${ZIP_FILE}"
    echo "upload done!"
else
    echo "no zip found at out/ dir..."
    exit 1
fi
