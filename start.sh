#!/bin/sh
UBUNTUPATH="/data/local/tmp/chrootubuntu"

# Fix setuid issue
busybox mount -o remount,dev,suid /data

# Bind mounts
for fs in dev sys proc; do
    busybox mount --bind /$fs $UBUNTUPATH/$fs
done
busybox mount -t devpts devpts $UBUNTUPATH/dev/pts
busybox mount -t tmpfs -o size=256M tmpfs $UBUNTUPATH/dev/shm
busybox mount --bind /sdcard $UBUNTUPATH/sdcard

# Networking fix
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

# Start shell
echo "[*] Starting Ubuntu chroot (VPS mode)..."
busybox chroot $UBUNTUPATH /bin/bash
