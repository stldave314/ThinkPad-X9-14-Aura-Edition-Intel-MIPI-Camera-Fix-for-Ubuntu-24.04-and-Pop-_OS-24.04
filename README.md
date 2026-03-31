# ThinkPad X9 14 Aura Edition (Intel MIPI Lunar Lake) Webcam Fix for Ubuntu/Pop!_OS 24.04

This document outlines the steps to resolve webcam issues on the ThinkPad X9 14 Aura Edition running Pop!_OS 24.04 (or Ubuntu 24.04+). The device uses the Intel MIPI IPU7 system, which requires a userspace relay to bridge proprietary hardware to standard V4L2 applications.

## Quick Fix
An automation script is provided in this directory to apply all changes at once:

```bash
bash configure_thinkpad_webcam.sh
```

## Technical Issues Resolved

1.  **Configuration Mismatch**: The default `v4l2-relayd` configuration looked for a device labeled "Virtual Camera," while the kernel module created one labeled "Intel MIPI Camera."
2.  **Hardware Permissions**: The IPU7 processor node (`/dev/ipu7-psys0`) was restricted to root, blocking standard applications from accessing the ISP (Image Signal Processor).
3.  **Missing Calibration Path**: The Intel Camera HAL requires a writable directory at `/run/camera/` to store derived calibration data (`.aiqd` files). This directory is missing by default and is cleared on every reboot.
4.  **Buffer Allocation**: The default loopback buffer count was insufficient for the high-resolution NV12 streams produced by the Lunar Lake sensor.

## Persistent Fixes Applied

### 1. Update v4l2-relayd Configuration
Update `/etc/default/v4l2-relayd` to match the hardware sensor's native format and the virtual device's label.

```bash
# Set correct Card Label
sudo sed -i 's/CARD_LABEL="Virtual Camera"/CARD_LABEL="Intel MIPI Camera"/' /etc/default/v4l2-relayd

# Set native sensor format and resolution
sudo sed -i 's/FORMAT=YUY2/FORMAT=NV12/' /etc/default/v4l2-relayd
sudo sed -i 's/WIDTH=1280/WIDTH=1920/' /etc/default/v4l2-relayd
sudo sed -i 's/HEIGHT=720/HEIGHT=1080/' /etc/default/v4l2-relayd
```

### 2. Set Permanent Hardware Permissions
Create a udev rule to allow the `video` group to access the IPU hardware.

**File**: `/etc/udev/rules.d/72-intel-ipu7-permissions.rules`
```udev
KERNEL=="ipu7-psys*", GROUP="video", MODE="0660"
```

### 3. Ensure Calibration Directory on Boot
Use systemd-tmpfiles to recreate the necessary `/run/camera` directory after every reboot.

**File**: `/etc/tmpfiles.d/intel-camera.conf`
```conf
d /run/camera 0775 root video - -
```

### 4. Increase Loopback Buffers
Configure the `v4l2loopback` module with enough buffers for high-resolution video.

**File**: `/etc/modprobe.d/v4l2loopback.conf`
```conf
options v4l2loopback devices=1 exclusive_caps=1 card_label="Intel MIPI Camera" max_buffers=32
```

## How to Apply
If you need to re-apply these fixes on a fresh install:

1.  Ensure `v4l2-relayd` and `v4l2loopback-dkms` are installed.
2.  Run the provided script: `bash configure_thinkpad_webcam.sh`
3.  Alternatively, apply the configuration changes above manually.
4.  Reboot the system.
5.  The `v4l2-relayd@default.service` should now start automatically and provide video to the Camera app.
