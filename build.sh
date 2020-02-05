#! /bin/bash


set -eo pipefail

VERSION="$1"

if [ -z "$VERSION" ]; then
  VERSION="18.06.6"
fi

echo "***** BUILDING IMAGE FOR $VERSION *****"

# should we sudo?
SUDO="sudo"
if [ "$(whoami)" == "root" ]; then
  SUDO=""
fi


# from https://openwrt.org/docs/guide-user/additional-software/imagebuilder
DEPS="build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python curl"



PACKAGES="$(cat PACKAGES | sed -e 's/#.*$//' | xargs)"


BUILDER_NAME="openwrt-imagebuilder-${VERSION}-x86-64.Linux-x86_64"

BUILDER_ARCHIVE="https://downloads.openwrt.org/releases/${VERSION}/targets/x86/64/${BUILDER_NAME}.tar.xz"


echo "***** INSTALLING DEPS *****"
${SUDO} apt-get update
${SUDO} apt-get -qq -y install ${DEPS}

echo "***** GETTING IMAGEBUILDER DEPS *****"
echo "URL: ${BUILDER_ARCHIVE}"

curl -Lqs "${BUILDER_ARCHIVE}" | unxz | tar -xf -

echo "***** BUILDING *****"
cd "${BUILDER_NAME}"
make image PACKAGES="${PACKAGES}"

echo "***** OUTPUT *****"
ls -lh bin/targets/x86/64
cp bin/targets/x86/64/openwrt-${VERSION}-x86-64-combined-ext4.img.gz ../openwrt-${VERSION}-x86-64-combined-ext4.img.gz
