#! /bin/bash

set -eo pipefail

# should we sudo?
SUDO="sudo"
if [ "$(whoami)" == "root" ]; then
  SUDO=""
fi


DEPS="build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python curl"

ROOT_DIR=$(pwd)

VERSION=19.07.0

echo "***** BUILDING IMAGEBUILDER FOR $VERSION *****"

echo "***** INSTALLING DEPS *****"
${SUDO} apt-get update
${SUDO} apt-get -qq -y install ${DEPS}

wget -qO- "https://github.com/openwrt/openwrt/archive/v${VERSION}.tar.gz"
cd "openwrt-${VERSION}"

# initialize the config
mv .config-init .config

# fill in the defaults
make defconfig

# override some values
cat .config-apu2 >> .config

tail -n 10 .config

# update the kernel config
cat config-kernel-apu2 >> target/linux/x86/config-4.14

tail -n 10 target/linux/x86/config-4.14

make

cd build_dir/target-x86_64_musl/openwrt-imagebuilder-x86-64.Linux-x86_64

tar -cJf "${ROOT_DIR}/openwrt-imagebuilder-${VERSION}x86-64.Linux-x86_64-apu2.tar.xz" .
