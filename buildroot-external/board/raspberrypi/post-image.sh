#!/bin/bash

set -e

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage-${BOARD_NAME}.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
GENBOOTFS_CFG="${BOARD_DIR}/genbootfs-${BOARD_NAME}.cfg"

trap 'rm -rf "${ROOTPATH_TMP}"' EXIT
ROOTPATH_TMP="$(mktemp -d)"

rm -rf "${GENIMAGE_TMP}"

# Pass VERSION as an environment variable (eg: export from a top-level Makefile)
# If VERSION is unset, fallback to the Buildroot version
RAUC_VERSION=${VERSION:-${BR2_VERSION_FULL}}
RAUC_COMPATIBLE="rauc_proxyvend_raspberrypi"

# Generate the boot filesystem image

genimage \
	--rootpath "${ROOTPATH_TMP}"   \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENBOOTFS_CFG}"
  
# Generate a RAUC update bundle for the full system (bootfs + rootfs)
[ -e ${BINARIES_DIR}/update.raucb ] && rm -rf ${BINARIES_DIR}/update.raucb
[ -e ${BINARIES_DIR}/temp-update ] && rm -rf ${BINARIES_DIR}/temp-update
mkdir -p ${BINARIES_DIR}/temp-update

cat >> ${BINARIES_DIR}/temp-update/manifest.raucm << EOF
[update]
compatible=${RAUC_COMPATIBLE}
version=${RAUC_VERSION}
[bundle]
format=verity
[image.bootloader]
filename=boot.vfat
[image.rootfs]
filename=rootfs.ext4
EOF

ln -L ${BINARIES_DIR}/boot.vfat ${BINARIES_DIR}/temp-update/
ln -L ${BINARIES_DIR}/rootfs.ext4 ${BINARIES_DIR}/temp-update/

${HOST_DIR}/bin/rauc bundle \
	--cert ${BR2_EXTERNAL_PROXYVENDOS_PATH}/board/raspberrypi/rootfs-overlay/etc/rauc/demo.cert.pem \
	--key ${BR2_EXTERNAL_PROXYVENDOS_PATH}/board/raspberrypi/rootfs-overlay/etc/rauc/demo.key.pem \
	${BINARIES_DIR}/temp-update/ \
	${BINARIES_DIR}/update.raucb

# Generate a RAUC update bundle for just the root filesystem
[ -e ${BINARIES_DIR}/rootfs.raucb ] && rm -rf ${BINARIES_DIR}/rootfs.raucb
[ -e ${BINARIES_DIR}/temp-rootfs ] && rm -rf ${BINARIES_DIR}/temp-rootfs
mkdir -p ${BINARIES_DIR}/temp-rootfs

cat >> ${BINARIES_DIR}/temp-rootfs/manifest.raucm << EOF
[update]
compatible=${RAUC_COMPATIBLE}
version=${RAUC_VERSION}
[bundle]
format=verity
[image.rootfs]
filename=rootfs.ext4
EOF


ln -L ${BINARIES_DIR}/rootfs.ext4 ${BINARIES_DIR}/temp-rootfs/

${HOST_DIR}/bin/rauc bundle \
	--cert ${BR2_EXTERNAL_PROXYVENDOS_PATH}/board/raspberrypi/rootfs-overlay/etc/rauc/demo.cert.pem \
	--key ${BR2_EXTERNAL_PROXYVENDOS_PATH}/board/raspberrypi/rootfs-overlay/etc/rauc/demo.key.pem \
	${BINARIES_DIR}/temp-rootfs/ \
	${BINARIES_DIR}/rootfs.raucb

 # Parse update.raucb and generate initial rauc.status file
# FIXME: There is probably a MUCH better way to do this,
#        suggestions welcome!
eval $(rauc --keyring ${BR2_EXTERNAL_PROXYVENDOS_PATH}/board/raspberrypi/rootfs-overlay/etc/rauc/demo.cert.pem --output-format=shell info ${BINARIES_DIR}/update.raucb)

cat > ${BINARIES_DIR}/rauc.status << EOF
[slot.${RAUC_IMAGE_CLASS_0}.0]
bundle.compatible=${RAUC_MF_COMPATIBLE}
status=ok
sha256=${RAUC_IMAGE_DIGEST_0}
size=${RAUC_IMAGE_SIZE_0}

[slot.${RAUC_IMAGE_CLASS_1}.0]
bundle.compatible=${RAUC_MF_COMPATIBLE}
status=ok
sha256=${RAUC_IMAGE_DIGEST_1}
size=${RAUC_IMAGE_SIZE_1}

[slot.${RAUC_IMAGE_CLASS_1}.1]
bundle.compatible=${RAUC_MF_COMPATIBLE}
status=ok
sha256=${RAUC_IMAGE_DIGEST_1}
size=${RAUC_IMAGE_SIZE_1}
EOF

# Install rauc.status to genimage rootpath
install -D -m 0644 ${BINARIES_DIR}/rauc.status ${ROOTPATH_TMP}/data/rauc.status

# Generate the sdcard image

rm -rf "${GENIMAGE_TMP}"

genimage \
	--rootpath "${ROOTPATH_TMP}"   \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

exit $?