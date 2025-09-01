#!/bin/bash
# setup.sh - Automated Ubuntu chroot installer (server-ready with SSH)
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

UBUNTU_VERSION="22.04"
UBUNTU_PATH="/data/local/tmp/chrootubuntu"
UBUNTU_TARBALL="ubuntu.tar.gz"
UBUNTU_URL="https://cdimage.ubuntu.com/ubuntu-base/releases/${UBUNTU_VERSION}/release/ubuntu-base-${UBUNTU_VERSION}-base-arm64.tar.gz"

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

# --- Networking + Hostname Fix ---
echo "nameserver 8.8.8.8" > ${UBUNTU_PATH}/etc/resolv.conf
echo "localhost" > ${UBUNTU_PATH}/etc/hostname
echo "127.0.0.1 localhost" > ${UBUNTU_PATH}/etc/hosts

# --- Auto-install SSH + Essentials on First Boot ---
cat > ${UBUNTU_PATH}/root/firstboot.sh <<'EOS'
#!/bin/bash
set -e
apt update
DEBIAN_FRONTEND=noninteractive apt install -y sudo systemd wget curl iproute2 net-tools \
    openssh-server nano vim git
# Set root password (default: root)
echo "root:root" | chpasswd
systemctl enable ssh
EOS
chmod +x ${UBUNTU_PATH}/root/firstboot.sh

# --- Start Script ---
cd /data/local/tmp
cat > start.sh <<'EOS'
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

# Copy DNS each boot
cp /etc/resolv.conf $UBUNTUPATH/etc/resolv.conf

# First boot setup (only runs once)
if [ ! -f "$UBUNTUPATH/root/.vps_ready" ]; then
    echo "[*] Running firstboot setup..."
    busybox chroot $UBUNTUPATH /bin/bash /root/firstboot.sh
    touch $UBUNTUPATH/root/.vps_ready
fi

# Start chroot
echo "[*] Starting Ubuntu chroot (VPS mode)..."
busybox chroot $UBUNTUPATH /bin/bash
EOS

chmod +x start.sh

echo "[*] Setup complete!"
echo ">>> To start Ubuntu server, run:"
echo "    su -c /data/local/tmp/start.sh"
echo ">>> Default SSH login: root / root"
EOF
