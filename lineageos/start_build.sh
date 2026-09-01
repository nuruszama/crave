#!/bin/bash

clear

# Reset all local modifications and delete untracked/generated files
repo forall -c "git reset --hard HEAD"
repo forall -c "git clean -fd"

# Maintainer and Host Info
export BUILD_USERNAME="nuruszama"
export BUILD_HOSTNAME="creek"

# Custom Build Tag
export LINEAGE_BUILDTYPE="TFAS"

# Build Optimizations & Checks
export SKIP_ABI_CHECKS=true
export WITH_DEXPREOPT=true

# remove device tree
rm -rf .repo/local_manifests
rm -rf vendor/xiaomi/creek
rm -rf device/xiaomi/creek

# re-initialize the lineage source
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs --depth=1

#clone local manifest
git clone https://github.com/XiaomiCreek/android.git -b lineage-23.2 --depth=1 .repo/local_manifests

# resync the repo source
repo sync -j16 --force-sync

# extract vendor tree
curl -sfLo vendorextract.sh -z vendorextract.sh https://raw.githubusercontent.com/nuruszama/crave/creek/tools/vendorextract.sh
chmod +x vendorextract.sh
./vendorextract.sh

# dynamically inject features.mk into device tree
cat << 'EOF' > device/xiaomi/creek/features.mk
# Inherit gapps configurations
\$(call inherit-product, vendor/gapps/arm64/arm64-vendor.mk)

EOF

# setup build env
source build/envsetup.sh

# remove intermediates files with seapp
find out/soong/.intermediates -type d -name "*seapp*" -exec rm -rf {} +

# change modified date to make soong start again
touch device/xiaomi/creek/BoardConfig.mk

# prepare device menu
breakfast creek userdebug

# Clean staging dirs
make installclean

# start building
mka bacon

# Upload
echo "upload to gofile..."
ROM_DIR="out/target/product/creek/"
ZIP_FILE=$(ls "$ROM_DIR" | grep "lineage-.*-creek.zip$" | tail -n 1)
if [ -n "${ZIP_FILE}" ]; then
    curl -sfLo upload.sh -z upload.sh https://raw.githubusercontent.com/nuruszama/crave/creek/tools/GoFile-upload.sh
    chmod +x upload.sh ; ./upload.sh "${ROM_DIR}${ZIP_FILE}"
    echo "upload done!"
else
    echo "no zip found at out/ dir..."
    exit 1
fi
