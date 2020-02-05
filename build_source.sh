#! /bin/bash

set -x
set -eo pipefail

# should we sudo?
SUDO="sudo"
if [ "$(whoami)" == "root" ]; then
  SUDO=""
fi


DEPS="build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python curl"

ROOT_DIR=$(pwd)

VERSION="$1"

if [ -z "$VERSION" ]; then
  VERSION="19.07.0"
fi



echo "***** BUILDING IMAGEBUILDER FOR $VERSION *****"

echo "***** INSTALLING DEPS *****"
${SUDO} apt-get update
${SUDO} apt-get -qq -y install ${DEPS}

echo "***** DOWNLOADING SOURCE FOR $VERSION *****"
wget -qO- "https://github.com/openwrt/openwrt/archive/v${VERSION}.tar.gz" | tar -xzf -
cd "openwrt-${VERSION}"

# initialize the config
mv "${ROOT_DIR}/.config-init" .config

echo "***** MAKING DEFAULT CONFIG *****"
# fill in the defaults
make defconfig

echo "***** UPDATING CONFIG *****"
cat "${ROOT_DIR}/.config-apu2"
scripts/kconfig.pl '+' ".config" "${ROOT_DIR}/.config-apu2" > .config-apu2-add
scripts/kconfig.pl '-' ".config-apu2-add" "${ROOT_DIR}/.config-apu2-sub" > .config-apu2
mv .config-apu2 .config


# update the kernel config
cat "${ROOT_DIR}/config-kernel-apu2" >> target/linux/x86/config-4.14

echo "***** LAST 10 KERNELCONFIG *****"
tail -n 10 target/linux/x86/config-4.14

echo "***** MAKING IMAGEBUILDER *****"
make

echo "***** DONE *****"
ls -lh build_dir/target-x86_64_musl
cd build_dir/target-x86_64_musl

tar -cJf "${ROOT_DIR}/openwrt-imagebuilder-${VERSION}-x86-64.Linux-x86_64-apu2.tar.xz" openwrt-imagebuilder-x86-64.Linux-x86_64
ls -lh "${ROOT_DIR}"
