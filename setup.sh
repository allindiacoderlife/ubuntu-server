#!/bin/bash
# setup.sh - Automated Ubuntu chroot installer (server-only, VPS-style)
# Rooted Termux + Busybox required

set -e

UBUNTU_VERSION="24.04.3"
UBUNTU_PATH="/data/local/tmp/chrootubuntu"
UBUNTU_TARBALL="/data/local/tmp/ubuntu.tar.gz"
UBUNTU_URL="https://cdimage.ubuntu.com/ubuntu-base/releases/${UBUNTU_VERSION}/release/ubuntu-base-${UBUNTU_VERSION}-base-arm64.tar.gz"
START_SCRIPT="/data/local/start-ubuntu.sh"
STOP_SCRIPT="/data/local/stop-ubuntu.sh"

echo "[*] Installing Termux dependencies..."
pkg update -y
pkg install -y root-repo tsu curl wget nano vim git net-tools openssh busybox

echo "[*] Creating chroot directory..."
su -c "mkdir -p $UBUNTU_PATH $UBUNTU_PATH/dev/pts $UBUNTU_PATH/dev/shm $UBUNTU_PATH/proc $UBUNTU_PATH/sys $UBUNTU_PATH/sdcard"

if [ ! -f "$UBUNTU_TARBALL" ]; then
    echo "[*] Downloading Ubuntu rootfs..."
    curl -L "$UBUNTU_URL" -o "$UBUNTU_TARBALL"
fi

echo "[*] Extracting rootfs..."
su -c "cd $UBUNTU_PATH && tar xpf $UBUNTU_TARBALL --numeric-owner"

# --- Create start script ---
echo "[*] Creating start script..."
su -c "cat > '$START_SCRIPT' <<'EOF'
#!/system/bin/sh
UBUNTU_PATH=\"$UBUNTU_PATH\"

# Mount system files
mountpoint -q \$UBUNTU_PATH/proc || busybox mount -t proc proc \$UBUNTU_PATH/proc
mountpoint -q \$UBUNTU_PATH/sys  || busybox mount -t sysfs sysfs \$UBUNTU_PATH/sys
mountpoint -q \$UBUNTU_PATH/dev  || busybox mount --bind /dev \$UBUNTU_PATH/dev
mountpoint -q \$UBUNTU_PATH/dev/pts || busybox mount -t devpts devpts \$UBUNTU_PATH/dev/pts
mountpoint -q \$UBUNTU_PATH/dev/shm || busybox mount -t tmpfs -o size=256M tmpfs \$UBUNTU_PATH/dev/shm
mountpoint -q \$UBUNTU_PATH/sdcard || busybox mount --bind /sdcard \$UBUNTU_PATH/sdcard

# Setup DNS
echo 'nameserver 8.8.8.8' > \$UBUNTU_PATH/etc/resolv.conf
echo '127.0.0.1 localhost' > \$UBUNTU_PATH/etc/hosts

# First-time setup
FIRSTBOOT_FLAG=\$UBUNTU_PATH/.firstboot_done
if [ ! -f \"\$FIRSTBOOT_FLAG\" ]; then
    echo '[*] First boot: configuring Ubuntu server...'
    busybox chroot \$UBUNTU_PATH /bin/bash -lc \"
        set -e
        export DEBIAN_FRONTEND=noninteractive
        apt update
        apt -y upgrade
        apt -y install sudo bash coreutils ca-certificates curl wget vim nano git net-tools iproute2 openssh-server locales tzdata

        # locale/timezone
        locale-gen en_US.UTF-8 || true
        ln -sf /usr/share/zoneinfo/UTC /etc/localtime

        # create ubuntu user with password ubuntu
        id -u ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash ubuntu
        echo 'ubuntu:ubuntu' | chpasswd
        mkdir -p /etc/sudoers.d
        echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/99-ubuntu
        chmod 0440 /etc/sudoers.d/99-ubuntu

        # Enable SSH
        mkdir -p /run/sshd
        sed -i 's|[#]*PasswordAuthentication .*|PasswordAuthentication yes|' /etc/ssh/sshd_config
    \"
    touch \"\$FIRSTBOOT_FLAG\"
fi

# Entry mode
MODE=\"\$1\"
if [ \"\$MODE\" = 'root' ]; then
    exec busybox chroot \$UBUNTU_PATH /bin/bash -l
else
    # start SSH in background
    busybox chroot \$UBUNTU_PATH /usr/sbin/sshd -D -p 2222 &
    exec busybox chroot \$UBUNTU_PATH /bin/su - ubuntu
fi
EOF"

su -c "chmod +x $START_SCRIPT"

# --- Stop script ---
echo "[*] Creating stop script..."
su -c "cat > '$STOP_SCRIPT' <<'EOF'
#!/system/bin/sh
UBUNTU_PATH=\"$UBUNTU_PATH\"
busybox fuser -km \$UBUNTU_PATH/dev/pts 2>/dev/null
busybox umount \$UBUNTU_PATH/dev/pts 2>/dev/null
busybox umount \$UBUNTU_PATH/dev/shm 2>/dev/null
busybox umount \$UBUNTU_PATH/dev 2>/dev/null
busybox umount \$UBUNTU_PATH/sys 2>/dev/null
busybox umount \$UBUNTU_PATH/proc 2>/dev/null
busybox umount \$UBUNTU_PATH/sdcard 2>/dev/null
echo '[*] Chroot mounts stopped.'
EOF"

su -c "chmod +x $STOP_SCRIPT"

echo
echo "✅ Ubuntu server installed!"
echo "➤ Start VPS-style Ubuntu:  su -c $START_SCRIPT"
echo "➤ Start as root:           su -c \"$START_SCRIPT root\""
echo "➤ Stop/unmount:            su -c $STOP_SCRIPT"
echo
echo "SSH is enabled on port 2222 inside chroot."
echo "Login user: ubuntu   Password: ubuntu"
