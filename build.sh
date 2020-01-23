#! /bin/bash

set -eo pipefail

VERSION="$1"

if [ -z "$VERSION" ]; then
  VERSION="18.06.2"
fi

# from https://openwrt.org/docs/guide-user/additional-software/imagebuilder
DEPS="build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python"


EXTRA_IMAGE_NAME="apu2-ath10k-qca988x"

PACKAGES="adblock ath10k-firmware-qca988x block-mount ca-bundle collectd collectd-mod-sensors flashrom fstools hostapd kmod-ath10k kmod-crypto-hw-ccp kmod-fs-vfat kmod-gpio-button-hotplug kmod-gpio-nct5104d kmod-leds-gpio kmod-pcspkr kmod-rt2800-lib kmod-rt2800-usb kmod-rt2x00-lib kmod-rt2x00-usb kmod-sound-core kmod-sp5100_tco kmod-usb-ohci kmod-usb-storage kmod-usb-storage-uas kmod-usb2 kmod-usb3 luci luci-app-statistics rt2800-usb-firmware tcpdump sysfsutils usbutils wget"


BUILDER_NAME="openwrt-imagebuilder-${VERSION}-x86-64.Linux-x86_64"

BUILDER_ARCHIVE="https://downloads.openwrt.org/releases/${VERSION}/targets/x86/64/${BUILDER_NAME}.tar.xz"


echo "***** INSTALLING DEPS *****"
sudo apt-get install ${DEPS}

echo "***** GETTING IMAGEBUILDER DEPS *****"
echo "URL: ${BUILDER_ARCHIVE}"

curl -Lqs "${BUILDER_ARCHIVE}" | unxz | tar -xf -

echo "***** BUILDING *****"
cd "${BUILDER_NAME}"
make image PACKAGES="${PACKAGES}" EXTRA_IMAGE_NAME="${EXTRA_IMAGE_NAME}"

echo "***** OUTPUT *****"
ls bin/targets/x86/64/bin/targets/x86/64/openwrt-${VERSION}-${EXTRA_IMAGE_NAME}-x86-64-combined-ext4.img.gz
