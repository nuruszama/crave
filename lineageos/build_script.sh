#!/bin/bash

# ==============================================================================
# LineageOS Multi-Variant Build Matrix
# Variants: EROFS Vanilla, EXT4 Vanilla, EROFS GApps
# ==============================================================================

set -e # Exit immediately if a command or build step fails
clear

# Array of target variants: "FS_TYPE GAPPS_BUILD"
VARIANTS=(
    "erofs vanilla"
    "ext4 vanilla"
    "erofs gapps"
)

# Export constant variables for all runs
export SF_USER="nuruszama"
export SF_PROJECT="xiaomicreek"
export ANDROID_VER="16"
export ROM_NAME="LineageOS"
export SSH_KEY="$HOME/.ssh/id_ed25519"

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

# Extract vendor tree
curl -sfLo vendorextract.sh https://raw.githubusercontent.com/nuruszama/crave/creek/tools/vendorextract.sh
chmod +x vendorextract.sh
./vendorextract.sh

for VARIANT in "${VARIANTS[@]}"; do
    read -r FS_TYPE GAPPS_CHOICE <<< "$VARIANT"
    
    echo ""
    echo " STARTING BUILD: FS=${FS_TYPE^^} | TYPE=${GAPPS_CHOICE^^}"
    echo ""
    
    # Export flags read by your Lineage device tree / overlay config
    if [ "$FS_TYPE" == "erofs" ]; then
        export WITH_EROFS=true
    else
        export WITH_EROFS=false
    fi
    
    if [ "$GAPPS_CHOICE" == "gapps" ]; then
        export WITH_GMS=true
    else
        export WITH_GMS=false
    fi

    # Make build name unique (e.g. erofs-vanilla, ext4-vanilla, erofs-gapps)
    export LINEAGE_BUILDTYPE="${FS_TYPE}-${GAPPS_CHOICE}"

    # setup build env
    source build/envsetup.sh

    # prepare device menu
    breakfast creek userdebug

    # Clean staging dirs
    make installclean

    # start building
    mka bacon

    # Upload
    echo "uploading file..."
    ROM_DIR="out/target/product/creek/"
    ZIP_FILE=$(ls "$ROM_DIR" | grep "lineage-creek-*.zip$" | tail -n 1)
    if [ -n "${ZIP_FILE}" ]; then
        curl -sfLo upload.sh https://raw.githubusercontent.com/nuruszama/crave/creek/tools/sf-upload.sh
        chmod +x upload.sh
        ./upload.sh "${ROM_DIR}/${ZIP_FILE}"
        echo "Upload done for ${FS_TYPE}-${GAPPS_CHOICE}!"
        
        # Clean uploaded zip to preserve workspace disk space
        rm -f "${ROM_DIR}/${ZIP_FILE}"
    else
        echo "no zip found at out/ dir..."
        exit 1
    fi
done

clear
rm -rf out
echo "All variants built and uploaded successfully!"
