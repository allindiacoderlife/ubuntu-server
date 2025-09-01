#!/bin/bash
# setup.sh - Automated Ubuntu chroot installer (server-only, no GUI)
# Works on rooted Android with Termux + Busybox (Magisk)

set -e

UBUNTU_VERSION="24.04.3"
UBUNTU_PATH="/data/local/tmp/chrootubuntu"
UBUNTU_TARBALL="ubuntu.tar.gz"
UBUNTU_URL="https://cdimage.ubuntu.com/ubuntu-base/releases/${UBUNTU_VERSION}/release/ubuntu-base-${UBUNTU_VERSION}-base-arm64.tar.gz"

echo "[*] Updating Termux packages..."
pkg update -y
pkg install -y root-repo tsu curl wget nano vim git net-tools pulseaudio

echo "[*] Switching to root..."
su <<'EOF'
set -e

echo "[*] Creating chroot directory..."
mkdir -p ${UBUNTU_PATH}
cd ${UBUNTU_PATH}

if [ ! -f "/data/local/tmp/${UBUNTU_TARBALL}" ]; then
    echo "[*] Downloading Ubuntu ${UBUNTU_VERSION} rootfs..."
    curl -L ${UBUNTU_URL} --output /data/local/tmp/${UBUNTU_TARBALL}
fi

echo "[*] Extracting Ubuntu rootfs..."
tar xpvf /data/local/tmp/${UBUNTU_TARBALL} --numeric-owner

mkdir -p sdcard dev/shm

cd /data/local/tmp
cat > start.sh <<'EOS'
#!/bin/sh
UBUNTUPATH="/data/local/tmp/chrootubuntu"

# Fix setuid issue
busybox mount -o remount,dev,suid /data

# Bind mounts
busybox mount --bind /dev $UBUNTUPATH/dev
busybox mount --bind /sys $UBUNTUPATH/sys
busybox mount --bind /proc $UBUNTUPATH/proc
busybox mount -t devpts devpts $UBUNTUPATH/dev/pts
busybox mount -t tmpfs -o size=256M tmpfs $UBUNTUPATH/dev/shm
busybox mount --bind /sdcard $UBUNTUPATH/sdcard

# Chroot into Ubuntu
busybox chroot $UBUNTUPATH /bin/su - root
EOS

chmod +x start.sh

echo "[*] Setup complete!"
echo ">>> To start Ubuntu server, run:"
echo "    su -c /data/local/tmp/start.sh"
EOF
