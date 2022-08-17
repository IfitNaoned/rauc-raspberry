#!/bin/sh

set -u
set -e

RAUC_COMPATIBLE="rauc_proxyvend_raspberrypi"

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
	sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
fi

# Mount persistent data partitions
if [ -e ${TARGET_DIR}/etc/fstab ]; then
	# For configuration data
	# WARNING: data=journal is safest, but potentially slow!
	grep -qE 'LABEL=Data' ${TARGET_DIR}/etc/fstab || \
	echo "LABEL=Data /data ext4 defaults,data=journal,noatime 0 0" >> ${TARGET_DIR}/etc/fstab

	# For bulk data (eg: firmware updates)
	grep -qE 'LABEL=Upload' ${TARGET_DIR}/etc/fstab || \
	echo "LABEL=Upload /upload ext4 defaults,noatime 0 0" >> ${TARGET_DIR}/etc/fstab
fi

# Copy custom cmdline.txt file
install -D -m 0644 ${BR2_EXTERNAL_PROXYVENDOS_PATH}/board/raspberrypi/cmdline.txt ${BINARIES_DIR}/custom/cmdline.txt

