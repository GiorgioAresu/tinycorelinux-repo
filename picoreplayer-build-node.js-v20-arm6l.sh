#!/bin/sh
TMP_PATH=/tmp/node.js-v20
TMP_PATH_WORKDIR=${TMP_PATH}/workdir
TMP_PATH_EXTENSION=${TMP_PATH}/extension
RW_PATH=/mnt/mmcblk0p2/tce
VERSION=v20.18.1
ARCH=armv6l

echo "Installing required packages"
tce-load -wil squashfs-tools curl

echo "Creating extension structure in tmp"
mkdir -p ${TMP_PATH_WORKDIR}/build
mkdir -p ${TMP_PATH_EXTENSION}/usr/local/bin
mkdir -p ${TMP_PATH_EXTENSION}/usr/local/lib
mkdir -p ${TMP_PATH_EXTENSION}/usr/local/tce.installed

FILENAME=node-${VERSION}-linux-${ARCH}
DOWNLOAD_URL=https://unofficial-builds.nodejs.org/download/release/${VERSION}/${FILENAME}.tar.xz

FILE_PATH="${TMP_PATH_WORKDIR}/${FILENAME}.tar.xz"
if [ -f "$FILE_PATH" ]; then
    echo "Release file already exists, skipping download"
else
    echo "Downloading release"
    curl -L -o "$FILE_PATH" "$DOWNLOAD_URL"
fi

echo "Extracting"
tar Jxf "$FILE_PATH" -C "${TMP_PATH_EXTENSION}/usr/local" --strip-components=1 ${FILENAME}/bin
tar Jxf "$FILE_PATH" -C "${TMP_PATH_EXTENSION}/usr/local" --strip-components=1 ${FILENAME}/lib
tar Jxf "$FILE_PATH" -C "${TMP_PATH_EXTENSION}/usr/local" --strip-components=1 ${FILENAME}/share

echo "Packaging extension"
mksquashfs ${TMP_PATH_EXTENSION} ${TMP_PATH_WORKDIR}/build/node.js-v20.tcz
echo -e "gcc_libs.tcz" > ${TMP_PATH_WORKDIR}/build/node.js-v20.tcz.dep
(cd ${TMP_PATH_WORKDIR}/build; md5sum node.js-v20.tcz > node.js-v20.tcz.md5.txt)

echo -n "Installing"
cp ${TMP_PATH_WORKDIR}/build/* ${RW_PATH}/optional/
if ! grep -q "^node.js-v20.tcz$" ${RW_PATH}/onboot.lst; then
    echo "node.js-v20.tcz" >> ${RW_PATH}/onboot.lst
fi

rm -r ${TMP_PATH}
echo "Finished! Please reboot"
