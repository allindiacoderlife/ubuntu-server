#!/data/data/com.termux/files/usr/bin/bash
# uninstall-ubuntu.sh - Remove Ubuntu chroot server

set -e

CHROOT_DIR="/data/local/tmp/chrootubuntu"
START_SCRIPT="/data/local/start-ubuntu.sh"
STOP_SCRIPT="/data/local/stop-ubuntu.sh"
TARBALL="/data/local/tmp/ubuntu.tar.gz"

echo "[*] Stopping any running Ubuntu chroot..."
if [ -x "$STOP_SCRIPT" ]; then
    su -c "$STOP_SCRIPT"
fi

echo "[*] Removing chroot directory..."
su -c "rm -rf $CHROOT_DIR"

echo "[*] Removing start/stop scripts..."
su -c "rm -f $START_SCRIPT $STOP_SCRIPT"

echo "[*] Removing downloaded rootfs tarball..."
su -c "rm -f $TARBALL"

echo "[*] Uninstall complete!"
echo "✅ Ubuntu chroot server removed."
