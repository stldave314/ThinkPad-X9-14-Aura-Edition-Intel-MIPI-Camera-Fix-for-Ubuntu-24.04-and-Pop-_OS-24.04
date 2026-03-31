#!/bin/bash

# ThinkPad X9 14 Aura Edition (Intel Lunar Lake) Webcam Configuration Script
# This script applies persistent fixes for the IPU7 MIPI webcam.

set -e

echo "Starting ThinkPad X9 Webcam Configuration..."

# 1. Update v4l2-relayd configuration
echo "Updating v4l2-relayd configuration..."
sudo sed -i 's/CARD_LABEL="Virtual Camera"/CARD_LABEL="Intel MIPI Camera"/' /etc/default/v4l2-relayd
sudo sed -i 's/FORMAT=YUY2/FORMAT=NV12/' /etc/default/v4l2-relayd
sudo sed -i 's/WIDTH=1280/WIDTH=1920/' /etc/default/v4l2-relayd
sudo sed -i 's/HEIGHT=720/HEIGHT=1080/' /etc/default/v4l2-relayd

# 2. Set permanent hardware permissions (udev)
echo "Setting permanent hardware permissions..."
echo 'KERNEL=="ipu7-psys*", GROUP="video", MODE="0660"' | sudo tee /etc/udev/rules.d/72-intel-ipu7-permissions.rules > /dev/null

# 3. Ensure calibration directory on boot (tmpfiles.d)
echo "Configuring persistent calibration directory..."
echo 'd /run/camera 0775 root video - -' | sudo tee /etc/tmpfiles.d/intel-camera.conf > /dev/null

# 4. Increase Loopback Buffers (modprobe)
echo "Configuring v4l2loopback buffers..."
echo 'options v4l2loopback devices=1 exclusive_caps=1 card_label="Intel MIPI Camera" max_buffers=32' | sudo tee /etc/modprobe.d/v4l2loopback.conf > /dev/null

# Apply changes that can be applied immediately
echo "Applying system changes..."
sudo systemd-tmpfiles --create /etc/tmpfiles.d/intel-camera.conf
sudo udevadm control --reload-rules && sudo udevadm trigger

echo "--------------------------------------------------------"
echo "Configuration complete!"
echo "Please REBOOT your laptop to ensure all changes take effect."
echo "--------------------------------------------------------"
