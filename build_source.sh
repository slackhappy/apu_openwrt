#! /bin/bash

set -x
set -eo pipefail

# should we sudo?
SUDO="sudo"
if [ "$(whoami)" == "root" ]; then
  SUDO=""
  export FORCE_UNSAFE_CONFIGURE=1
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

echo "***** DOWNLOAD docker package from https://gitlab.com/mcbridematt/openwrt-container-feed"
wget -qO- "https://gitlab.com/mcbridematt/openwrt-container-feed/-/archive/master/openwrt-container-feed-master.tar.gz" | tar -C "package" -xzf - --strip-components 1

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
make || make V=s

# copy any packages that would be ignored by non-standalone
# currently just docker
echo "***** COPYING PACKAGES TO IMAGEBUILDER *****"
cp staging_dir/packages/x86/docker-binary-x86_64*.ipk build_dir/target-x86_64_musl/openwrt-imagebuilder-x86-64.Linux-x86_64/packages/

echo "***** GENERATING IMAGEBUILDER ARCHIVE *****"
ls -lh build_dir/target-x86_64_musl
cd build_dir/target-x86_64_musl

tar -cJf "${ROOT_DIR}/openwrt-imagebuilder-${VERSION}-x86-64.Linux-x86_64-apu2.tar.xz" openwrt-imagebuilder-x86-64.Linux-x86_64
ls -lh "${ROOT_DIR}"

echo "***** GENERATING IMAGE *****"

PACKAGES="$(cat "${ROOT_DIR}/PACKAGES" | sed -e 's/#.*$//' | xargs)"
cd build_dir/target-x86_64_musl/openwrt-imagebuilder-x86-64.Linux-x86_64
make image PACKAGES="${PACKAGES}"

echo "***** OUTPUT *****"
ls -lh bin/targets/x86/64
cp bin/targets/x86/64/openwrt-${VERSION}-x86-64-combined-ext4.img.gz ${ROOT_DIR}/openwrt-${VERSION}-x86-64-combined-ext4.img.gz

