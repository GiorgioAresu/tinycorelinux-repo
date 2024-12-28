#!/bin/sh
TMP_PATH=/tmp/plexamp
TMP_PATH_WORKDIR=${TMP_PATH}/workdir
TMP_PATH_EXTENSION=${TMP_PATH}/extension
RW_PATH=/mnt/mmcblk0p2/tce
DATA_PATH="~/.local/Plexamp"

echo "Installing required packages"
tce-load -wi squashfs-tools bash curl node.js-v20

echo "Creating extension structure in tmp"
mkdir -p ${TMP_PATH_WORKDIR}/build
mkdir -p ${TMP_PATH_EXTENSION}/usr/local/bin
mkdir -p ${TMP_PATH_EXTENSION}/usr/local/lib
mkdir -p ${TMP_PATH_EXTENSION}/usr/local/tce.installed

echo "Getting Plexamp release info:"
VERSION=$(curl -s "https://plexamp.plex.tv/headless/version.json" | sed -E 's/.*"latestVersion": ?"?([^,"]*)"?.*/\1/' )
echo " - Version: $VERSION"
DOWNLOAD_URL=$(curl -s "https://plexamp.plex.tv/headless/version.json" | sed -E 's/.*"updateUrl": ?"?([^,"]*)"?.*/\1/' )
echo " - URL: $DOWNLOAD_URL"

if [ -z "$DOWNLOAD_URL" ]; then
    echo "No assets found in the latest release"
    exit 1
fi

FILE_PATH="${TMP_PATH_WORKDIR}/plexamp-${VERSION}.tar.bz2"
if [ -f "$FILE_PATH" ]; then
    echo "Release file already exists, skipping download"
else
    echo "Downloading release"
    curl -L -o "$FILE_PATH" "$DOWNLOAD_URL"
fi

echo "Extracting"
tar jxf "$FILE_PATH" -C "${TMP_PATH_EXTENSION}/usr/local/lib"

echo "Preparing extension"
echo -e '#!/bin/sh\nnode /usr/local/lib/plexamp/js/index.js' > ${TMP_PATH_EXTENSION}/usr/local/bin/plexamp
chmod +x ${TMP_PATH_EXTENSION}/usr/local/bin/plexamp
echo -e '#!/bin/sh\nnode /usr/local/lib/plexamp/js/index-browser.js' > ${TMP_PATH_EXTENSION}/usr/local/bin/plexamp-browser
chmod +x ${TMP_PATH_EXTENSION}/usr/local/bin/plexamp-browser
cat <<EOF > ${TMP_PATH_EXTENSION}/usr/local/tce.installed/plexamp
#!/bin/sh
# Check if the folder is already in /opt/.filetool.lst
if ! grep -q "^${DATA_PATH}$" /opt/.filetool.lst; then
    echo "Adding ${DATA_PATH} to /opt/.filetool.lst"
    echo "${DATA_PATH}" >> /opt/.filetool.lst
fi
filetool.sh -b

/usr/local/bin/plexamp
EOF

chmod +x ${TMP_PATH_EXTENSION}/usr/local/tce.installed/plexamp

echo "Running setup. Please follow instructions"
node ${TMP_PATH_EXTENSION}/usr/local/lib/plexamp/js/index-browser.js
echo "Setup done, resuming script"

echo "Packaging extension"
mksquashfs ${TMP_PATH_EXTENSION} ${TMP_PATH_WORKDIR}/build/plexamp.tcz
echo -e "bash.tcz\nnode.js.tcz" > ${TMP_PATH_WORKDIR}/build/plexamp.tcz.dep
(cd ${TMP_PATH_WORKDIR}/build; md5sum plexamp.tcz > plexamp.tcz.md5.txt)

echo -n "Installing"
cp ${TMP_PATH_WORKDIR}/build/* ${RW_PATH}/optional/
echo plexamp.tcz >> ${RW_PATH}/onboot.lst

rm -r ${TMP_PATH}
echo "Finished! Please reboot"
