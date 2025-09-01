#!/bin/bash
# server-start.sh - Start Ubuntu chroot VPS
# Works on rooted Android with Termux + Busybox (Magisk)

set -e
UBUNTUPATH="/data/local/tmp/chrootubuntu"

echo "[*] Switching to root..."
su <<'EOF'
UBUNTUPATH="/data/local/tmp/chrootubuntu"

# Fix setuid issue
busybox mount -o remount,dev,suid /data

# Bind mounts
for fs in dev sys proc; do
    if ! mountpoint -q $UBUNTUPATH/$fs; then
        echo "[*] Mounting /$fs..."
        busybox mount --bind /$fs $UBUNTUPATH/$fs
    fi
done

if ! mountpoint -q $UBUNTUPATH/dev/pts; then
    busybox mount -t devpts devpts $UBUNTUPATH/dev/pts
fi
if ! mountpoint -q $UBUNTUPATH/dev/shm; then
    busybox mount -t tmpfs -o size=256M tmpfs $UBUNTUPATH/dev/shm
fi
if ! mountpoint -q $UBUNTUPATH/sdcard; then
    busybox mount --bind /sdcard $UBUNTUPATH/sdcard
fi

# Copy DNS
cp /etc/resolv.conf $UBUNTUPATH/etc/resolv.conf

# First boot setup
if [ ! -f "$UBUNTUPATH/root/.vps_ready" ]; then
    echo "[*] Running firstboot setup..."
    busybox chroot $UBUNTUPATH /bin/bash /root/firstboot.sh
    touch $UBUNTUPATH/root/.vps_ready
fi

# Start SSH server
mkdir -p $UBUNTUPATH/var/run/sshd
busybox chroot $UBUNTUPATH /usr/sbin/sshd

echo "[*] Ubuntu chroot VPS started!"
echo ">>> SSH login: ssh root@<phone-ip> (password: root)"
EOF
