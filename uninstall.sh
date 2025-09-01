#!/bin/bash
# uninstall.sh - Remove Ubuntu chroot environment
# Works on rooted Android with Termux + Busybox (Magisk)

set -e

UBUNTU_PATH="/data/local/tmp/chrootubuntu"
START_SCRIPT="/data/local/tmp/start.sh"
UBUNTU_TARBALL="/data/local/tmp/ubuntu.tar.gz"

echo "[*] Switching to root to unmount and delete Ubuntu..."
su <<EOF
set -e

# Stop SSH if running
if busybox chroot $UBUNTU_PATH /usr/bin/pgrep sshd >/dev/null 2>&1; then
    echo "[*] Stopping sshd inside chroot..."
    busybox chroot $UBUNTU_PATH /usr/bin/pkill sshd || true
fi

# Unmount bound filesystems
for fs in dev/pts dev/shm dev sys proc sdcard; do
    if mountpoint -q $UBUNTU_PATH/\$fs; then
        echo "[*] Unmounting \$fs..."
        busybox umount -l $UBUNTU_PATH/\$fs || true
    fi
done

# Remove Ubuntu rootfs
if [ -d "$UBUNTU_PATH" ]; then
    echo "[*] Deleting Ubuntu chroot directory..."
    rm -rf "$UBUNTU_PATH"
fi

# Remove start script and tarball
rm -f "$START_SCRIPT"
rm -f "$UBUNTU_TARBALL"

echo "[*] Ubuntu chroot uninstalled successfully."
EOF
