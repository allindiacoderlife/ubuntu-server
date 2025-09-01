#!/bin/bash
# server-stop.sh - Stop Ubuntu chroot VPS
# Works on rooted Android with Termux + Busybox (Magisk)

set -e
UBUNTUPATH="/data/local/tmp/chrootubuntu"

echo "[*] Switching to root..."
su <<'EOF'
UBUNTUPATH="/data/local/tmp/chrootubuntu"

# Stop SSH if running
if busybox chroot $UBUNTUPATH /usr/bin/pgrep sshd >/dev/null 2>&1; then
    echo "[*] Stopping sshd..."
    busybox chroot $UBUNTUPATH /usr/bin/pkill sshd || true
fi

# Unmount bound filesystems
for fs in dev/pts dev/shm sdcard dev sys proc; do
    if mountpoint -q $UBUNTUPATH/$fs; then
        echo "[*] Unmounting $fs..."
        busybox umount -l $UBUNTUPATH/$fs || true
    fi
done

echo "[*] Ubuntu chroot VPS stopped."
EOF
