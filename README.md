Here’s a clean **README** for your Ubuntu chroot VPS-style installer on Termux:

---

# Ubuntu Chroot Server on Rooted Termux

A minimal VPS-style **Ubuntu server (24.04 LTS)** setup for **rooted Android devices** using Termux and Busybox.
It runs entirely in a **chroot environment**, providing a simple server with SSH access and a non-root `ubuntu` user.

---

## 📌 Features

* Automated download & extraction of **Ubuntu 24.04 LTS** rootfs (ARM64/ARMHF).
* Creates a **VPS-style user**: `ubuntu` / `ubuntu` with sudo privileges.
* **OpenSSH server** enabled on **port 2222** inside chroot.
* Simple **start/stop scripts** for easy VPS management.
* Server-only, no GUI (headless, lightweight).
* Ready for Termux X11 later if you want GUI extensions.

---

## 🛠 Prerequisites

1. **Rooted Android device**.
2. **Magisk + Busybox** installed.
3. **Termux** installed from F-Droid or Google Play.
4. Packages in Termux:

```bash
pkg update
pkg install -y root-repo tsu curl wget nano vim git net-tools openssh busybox
```

---

## ⚡ Installation

1. **Download the installer script**:

```bash
curl -O https://example.com/setup.sh
chmod +x setup.sh
```

2. **Run the installer**:

```bash
./setup.sh
```

3. The script will:

* Detect architecture (ARM64/ARMHF).
* Download Ubuntu rootfs to `/data/local/tmp/ubuntu.tar.gz`.
* Extract rootfs into `/data/local/tmp/chrootubuntu`.
* Create start (`/data/local/start-ubuntu.sh`) and stop (`/data/local/stop-ubuntu.sh`) scripts.
* Set up `ubuntu` user with password `ubuntu` and NOPASSWD sudo.
* Enable SSH inside the chroot.

---

## 🚀 Usage

### Start Ubuntu server

```bash
su -c /data/local/start-ubuntu.sh
```

* Logs in as **`ubuntu` user** by default.
* To login as **root**, run:

```bash
su -c "/data/local/start-ubuntu.sh root"
```

### Stop / Clean mounts

```bash
su -c /data/local/stop-ubuntu.sh
```

---

## 🔑 SSH Access (Optional)

* SSH server runs **port 2222** inside chroot.
* From Termux or other device:

```bash
ssh ubuntu@localhost -p 2222
```

* Default password: `ubuntu`

---

## 📝 Notes

* First start will run **apt update/upgrade** and configure the system; it may take a few minutes.
* To exit Ubuntu shell, type:

```bash
exit
```

* **Stop the chroot** to avoid device issues.
* You can modify the `/data/local/start-ubuntu.sh` script to customize mounts, network, or login behavior.

---

## 🛡 Security

* Default SSH password is `ubuntu` — change it inside the chroot:

```bash
passwd ubuntu
```

* NOPASSWD sudo is enabled for convenience; remove from `/etc/sudoers.d/99-ubuntu` for stricter security.

---

## 📂 Paths

| File                           | Description                   |
| ------------------------------ | ----------------------------- |
| `/data/local/tmp/chrootubuntu` | Ubuntu rootfs directory       |
| `/data/local/start-ubuntu.sh`  | Script to start Ubuntu server |
| `/data/local/stop-ubuntu.sh`   | Script to stop/unmount chroot |

---

This README provides all instructions to **install, start, stop, and access your Ubuntu chroot VPS** on Termux.

---

If you want, I can also make a **more “GitHub-ready” README with badges, a diagram, and step-by-step screenshots** for easier sharing.

Do you want me to do that?
