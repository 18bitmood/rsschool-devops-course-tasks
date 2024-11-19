#!/bin/bash
set -e

# Update system and install required packages
apt-get update -y
apt-get install -y curl linux-modules-extra-$(uname -r)

# Disable any existing swap
swapoff -a

# Configure zRAM
swapoff /dev/zram0 2>/dev/null || true
rmmod zram 2>/dev/null || true
modprobe zram

# Remove existing swapfile
rm -f /swapfile

# Create persistent module loading configuration
echo "zram" > /etc/modules-load.d/zram.conf
echo "options zram num_devices=1" > /etc/modprobe.d/zram.conf

# Calculate zRAM size (100% of total RAM, minimum 40 KiB)
TOTALMEM=$(grep MemTotal /proc/meminfo | tr -dc '0-9')
ZRAM_SIZE=$TOTALMEM

# Configure compression algorithm to zstd
echo "zstd" | sudo tee /sys/block/zram0/comp_algorithm
# Create udev rule for zRAM device
cat << 'UDEVRULE' > /etc/udev/rules.d/99-zram.rules
KERNEL=="zram0", ATTR{disksize}="$ZRAM_SIZE"K" RUN="/usr/bin/mkswap -L zram0 /dev/zram0", TAG+="systemd"
UDEVRULE

# Create and configure regular swap partition (1GB)
dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 600 /swapfile
mkswap /swapfile
swapon -p -2 /swapfile
# Add swap entries to fstab
grep -q "^/dev/zram0" /etc/fstab || echo "/dev/zram0 none swap defaults,pri=100 0 0" >> /etc/fstab
grep -q "^/swapfile" /etc/fstab || echo "/swapfile none swap sw,pri=-2 0 0" >> /etc/fstab

# Reload systemd and udev
systemctl daemon-reload
udevadm control --reload

# Configure swap parameters
cat << 'SYSCTL' > /etc/sysctl.d/99-zram.conf
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.page-cluster = 0
SYSCTL

# Apply sysctl settings
sysctl -p /etc/sysctl.d/99-zram.conf

# Initialize zRAM device
echo "${ZRAM_SIZE}K" | sudo tee /sys/block/zram0/disksize
mkswap -L zram0 /dev/zram0
swapon -p 100 /dev/zram0
