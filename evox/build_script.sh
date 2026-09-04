#!/bin/bash

clear

# Maintainer and Host Info
export BUILD_USERNAME="nuruszama"
export BUILD_HOSTNAME="creek"
export EVO_MAINTAINER="nuruszama"
export EVO_BUILDTYPE="COMMUNITY-BUILD"

# Build Optimizations & Checks
export SKIP_ABI_CHECKS=true
export WITH_DEXPREOPT=true

# remove device tree
rm -rf .repo/local_manifests
rm -rf vendor/xiaomi/creek
rm -rf device/xiaomi/creek

# re-initialize the lineage source
repo init -u https://github.com/Evolution-X/manifest -b bka --git-lfs --depth=1

# clone local manifest
git clone https://github.com/XiaomiCreek/android.git -b lineage-23.2 --depth=1 .repo/local_manifests

# resync the repo source
repo sync -j16 --force-sync

# extract vendor tree
./vendorextract.sh

# setup build env
source build/envsetup.sh

# prepare device menu
breakfast creek userdebug

# Clean staging dirs
make installclean

# start building
m evolution
