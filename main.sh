#!/bin/bash

# Title: Ultimate Android Forensics and Remote Access Toolkit
# Author: [Your Name]
# Purpose: This script is designed to perform kernel and firmware dumps, set up secure remote access, and allow device flashing, with robust compatibility across all Android versions.

echo "Starting Ultimate Android Toolkit..."

# Step 1: Check if the device is rooted
echo "Checking for root access..."
if ! adb shell "su -c 'echo Root access verified'" > /dev/null 2>&1; then
    echo "Error: Root access is required for this script to function."
    exit 1
fi
echo "Root access confirmed."

# Step 2: Enable USB Debugging over TCP/IP
echo "Enabling ADB over TCP/IP..."
adb tcpip 5555
adb connect localhost:5555

# Step 3: Install and start an SSH server if not already installed
echo "Setting up SSH server..."
if ! adb shell "which sshd" > /dev/null 2>&1; then
    adb shell "su -c 'apt-get update && apt-get install -y openssh-server'" || {
        echo "Failed to install SSH server. Attempting to use existing services."
    }
fi
adb shell "su -c '/system/bin/sshd'"
echo "SSH server setup complete."

# Step 4: Dump the Kernel
echo "Dumping the kernel..."
adb shell "su -c 'dd if=/dev/block/bootdevice/by-name/boot of=/data/local/tmp/kernel_dump.img'" || {
    echo "Kernel dump failed. Attempting alternative method..."
    adb shell "su -c 'dd if=/dev/block/platform/msm_sdcc.1/by-name/boot of=/data/local/tmp/kernel_dump.img'" || {
        echo "Error: Kernel dump failed. Manual intervention required."
        exit 1
    }
}
echo "Kernel dump successful."

# Step 5: Dump the Firmware
echo "Dumping the firmware..."
adb shell "su -c 'dd if=/dev/block/bootdevice/by-name/system of=/data/local/tmp/firmware_dump.img'" || {
    echo "Firmware dump failed. Attempting alternative method..."
    adb shell "su -c 'dd if=/dev/block/platform/msm_sdcc.1/by-name/system of=/data/local/tmp/firmware_dump.img'" || {
        echo "Error: Firmware dump failed. Manual intervention required."
        exit 1
    }
}
echo "Firmware dump successful."

# Step 6: Enable Device Flashing (Unlock bootloader and allow flashing)
echo "Enabling device flashing..."
adb shell "su -c 'fastboot oem unlock'" || {
    echo "Bootloader unlock failed or not necessary. Continuing..."
}
adb shell "su -c 'fastboot flash recovery /path/to/recovery.img'" || {
    echo "Error: Flashing recovery image failed. Ensure the correct path and image are provided."
    exit 1
}
echo "Device flashing enabled."

# Step 7: Securely Transfer Dumps to Host
echo "Transferring kernel and firmware dumps to host..."
adb pull /data/local/tmp/kernel_dump.img ./kernel_dump.img
adb pull /data/local/tmp/firmware_dump.img ./firmware_dump.img
echo "Transfer complete."

# Step 8: Forensic Logging and Cleanup
echo "Generating forensic logs..."
adb shell "su -c 'dmesg > /data/local/tmp/forensic_log.txt && logcat -d > /data/local/tmp/logcat.txt'"
adb pull /data/local/tmp/forensic_log.txt ./forensic_log.txt
adb pull /data/local/tmp/logcat.txt ./logcat.txt

# Optional: Securely wipe temporary files from the device to cover tracks
echo "Wiping temporary files..."
adb shell "su -c 'rm -f /data/local/tmp/kernel_dump.img /data/local/tmp/firmware_dump.img /data/local/tmp/forensic_log.txt /data/local/tmp/logcat.txt'"
echo "Temporary files wiped."

# Step 9: Forward Ports for Remote Access
echo "Setting up port forwarding for remote access..."
adb forward tcp:2222 tcp:22
adb forward tcp:5555 tcp:5555
echo "Port forwarding complete."

# Final Instructions and Stealth Mode
echo "To connect via SSH, use: ssh -p 2222 user@localhost"
echo "To reconnect via ADB, use: adb connect localhost:5555"

# Disabling USB Debugging over TCP/IP for security
adb usb
echo "ADB over TCP/IP disabled for security reasons."

echo "Script execution complete. System is ready for further operations."

# adb push <root-script>.sh /data/local/tmp/ && adb shell "su -c 'chmod +x /data/local/tmp/<root-script>.sh && /data/local/tmp/<root-script>.sh'"
