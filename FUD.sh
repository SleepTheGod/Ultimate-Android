#!/bin/bash

# Title: Ultimate Android Forensics and Remote Access Toolkit
# Author: Taylor Christian Newsome
# Purpose: This script performs kernel and firmware dumps, enables secure remote access, and supports device flashing with maximum compatibility and security.

echo "[INFO] Starting Ultimate Android Toolkit..."

# Step 1: Check for Root Access
echo "[INFO] Checking for root access..."
if ! adb shell "su -c 'echo Root access confirmed'" > /dev/null 2>&1; then
    echo "[ERROR] Root access required. Exiting..."
    exit 1
fi

# Step 2: Enable ADB over TCP/IP and Connect
echo "[INFO] Enabling ADB over TCP/IP..."
adb tcpip 5555
adb connect localhost:5555 || {
    echo "[ERROR] Failed to establish TCP/IP connection. Exiting..."
    exit 1
}

# Step 3: Install and Start SSH Server (if necessary)
echo "[INFO] Setting up SSH server..."
if ! adb shell "su -c 'command -v sshd'" > /dev/null 2>&1; then
    adb shell "su -c 'apt-get update && apt-get install -y openssh-server'" || {
        echo "[WARN] SSH server installation failed or not necessary."
    }
fi
adb shell "su -c '/system/bin/sshd'"
echo "[INFO] SSH server started."

# Step 4: Dump Kernel
echo "[INFO] Dumping the kernel..."
if ! adb shell "su -c 'dd if=/dev/block/bootdevice/by-name/boot of=/data/local/tmp/kernel_dump.img'"; then
    adb shell "su -c 'dd if=/dev/block/platform/msm_sdcc.1/by-name/boot of=/data/local/tmp/kernel_dump.img'" || {
        echo "[ERROR] Kernel dump failed. Exiting..."
        exit 1
    }
}
echo "[INFO] Kernel dump complete."

# Step 5: Dump Firmware
echo "[INFO] Dumping the firmware..."
if ! adb shell "su -c 'dd if=/dev/block/bootdevice/by-name/system of=/data/local/tmp/firmware_dump.img'"; then
    adb shell "su -c 'dd if=/dev/block/platform/msm_sdcc.1/by-name/system of=/data/local/tmp/firmware_dump.img'" || {
        echo "[ERROR] Firmware dump failed. Exiting..."
        exit 1
    }
}
echo "[INFO] Firmware dump complete."

# Step 6: Enable Device Flashing
echo "[INFO] Enabling device flashing..."
adb shell "su -c 'fastboot oem unlock'" || echo "[WARN] Bootloader unlock failed or not necessary."
adb shell "su -c 'fastboot flash recovery /path/to/recovery.img'" || {
    echo "[ERROR] Flashing recovery image failed. Exiting..."
    exit 1
}
echo "[INFO] Device flashing enabled."

# Step 7: Securely Transfer Dumps to Host
echo "[INFO] Transferring kernel and firmware dumps to host..."
adb pull /data/local/tmp/kernel_dump.img ./kernel_dump.img || {
    echo "[ERROR] Failed to transfer kernel dump. Exiting..."
    exit 1
}
adb pull /data/local/tmp/firmware_dump.img ./firmware_dump.img || {
    echo "[ERROR] Failed to transfer firmware dump. Exiting..."
    exit 1
}
echo "[INFO] Transfer complete."

# Step 8: Forensic Logging and Cleanup
echo "[INFO] Capturing forensic logs..."
adb shell "su -c 'dmesg > /data/local/tmp/forensic_log.txt && logcat -d > /data/local/tmp/logcat.txt'"
adb pull /data/local/tmp/forensic_log.txt ./forensic_log.txt
adb pull /data/local/tmp/logcat.txt ./logcat.txt
echo "[INFO] Forensic logs captured."

# Optional: Wipe temporary files for stealth
echo "[INFO] Wiping temporary files..."
adb shell "su -c 'rm -f /data/local/tmp/kernel_dump.img /data/local/tmp/firmware_dump.img /data/local/tmp/forensic_log.txt /data/local/tmp/logcat.txt'"
echo "[INFO] Temporary files wiped."

# Step 9: Setup Port Forwarding for Remote Access
echo "[INFO] Setting up port forwarding..."
adb forward tcp:2222 tcp:22 || {
    echo "[ERROR] Failed to set up SSH port forwarding. Exiting..."
    exit 1
}
adb forward tcp:5555 tcp:5555
echo "[INFO] Port forwarding complete."

# Step 10: Disable ADB over TCP/IP for security
echo "[INFO] Disabling ADB over TCP/IP..."
adb usb
echo "[INFO] ADB over TCP/IP disabled."

# Final Notes
echo "[INFO] Script execution complete. Connect via SSH using 'ssh -p 2222 user@localhost'."
echo "[INFO] To reconnect ADB, use 'adb connect localhost:5555'."

echo "[INFO] Ultimate Android Toolkit is ready for further operations. Exiting..."

# IF THIS DOES NOT WORK TRY THIS adb push FUD.sh /data/local/tmp/ && adb shell "su -c 'chmod +x /data/local/tmp/FUD.sh && /data/local/tmp/FUD.sh'"
