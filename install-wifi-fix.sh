#!/bin/bash

# Detect the actual user behind sudo
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

# Dynamically detect the active rtw88 driver variant name
CHIP_MODULE=$(lsmod | grep -oE "rtw88_[0-9a-z]+" | head -n 1)

# Check if user provided an argument
ACTION=$1

if [ "$ACTION" == "install" ]; then
    # Block installation if no rtw88 module is found running
    if [ -z "$CHIP_MODULE" ]; then
        echo "❌ Error: No active rtw88 wireless driver detected in memory."
        exit 1
    fi

    echo "⚙️ Setting up automated Linux Wi-Fi fix for rtw88 family ($CHIP_MODULE)..."

    # 1. Block hardware-level PCIe sleep glitches
    echo -e "options rtw88_core disable_lps_deep=y\noptions rtw88_pci disable_aspm=y" | sudo tee /etc/modprobe.d/rtw88.conf

    # 2. Disable high-level NetworkManager power cycling
    sudo mkdir -p /etc/NetworkManager/conf.d
    echo -e "[connection]\nwifi.powersave = 2" | sudo tee /etc/NetworkManager/conf.d/wifi-powersave-off.conf

    # 3. Inject the shutdown driver unloader
    sudo tee /etc/systemd/system/wifi-clear-reboot.service << EOF
[Unit]
Description=Quiesce $CHIP_MODULE combo device before shutdown
Before=NetworkManager.service shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/true
ExecStop=-/usr/bin/modprobe -r btusb
ExecStop=-/usr/bin/modprobe -r $CHIP_MODULE

[Install]
WantedBy=multi-user.target
EOF

    # Enable the reboot system service
    sudo systemctl enable wifi-clear-reboot.service

    # 4. Create the hidden configuration directory for the ping script
    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/autostart"

    # 5. Create the hidden background heartbeat script
    sudo -u "$REAL_USER" tee "$REAL_HOME/.config/wifi-keepalive.sh" << 'EOF' > /dev/null
#!/bin/bash
while true; do
  TARGET_IP=$(ip route | awk '/default/ {print $3}')
  if [ ! -z "$TARGET_IP" ]; then
    ping -c 1 -W 2 "$TARGET_IP" > /dev/null 2>&1
  fi
  sleep 10
done
EOF

    sudo -u "$REAL_USER" chmod +x "$REAL_HOME/.config/wifi-keepalive.sh"

    # 6. Set up the system desktop startup launcher
    sudo -u "$REAL_USER" tee "$REAL_HOME/.config/autostart/wifi-keepalive.desktop" << EOF > /dev/null
[Desktop Entry]
Type=Application
Exec=$REAL_HOME/.config/wifi-keepalive.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Wi-Fi Keepalive
Comment=Prevents Realtek Wi-Fi drops
EOF

    # Launch it immediately under the user space context with zero root duplicates
    pkill -f wifi-keepalive.sh
    systemd-run --user --machine="${REAL_USER}@" --quiet "$REAL_HOME/.config/wifi-keepalive.sh"

    echo "✅ Full master script configuration applied for $CHIP_MODULE."

elif [ "$ACTION" == "remove" ]; then
    echo "🧹 Removing automated Wi-Fi fixes and restoring system defaults..."

    sudo systemctl disable --now wifi-clear-reboot.service 2>/dev/null
    sudo rm -f /etc/systemd/system/wifi-clear-reboot.service
    sudo systemctl daemon-reload

    pkill -f wifi-keepalive.sh

    sudo rm -f /etc/modprobe.d/rtw88.conf
    sudo rm -f /etc/NetworkManager/conf.d/wifi-powersave-off.conf
    rm -f "$REAL_HOME/.config/wifi-keepalive.sh"
    rm -f "$REAL_HOME/.config/autostart/wifi-keepalive.desktop"

    sudo systemctl restart NetworkManager
    echo "🗑️ All fixes removed successfully. System has been reverted to default state."

elif [ "$ACTION" == "check" ]; then
    echo -e "\n--- 🔍 Hardware Detection ---"
    if [ -z "$CHIP_MODULE" ]; then
        echo "❌ No rtw88 driver variant detected active."
    else
        echo "Detected active chip driver: $CHIP_MODULE"
    fi

    echo -e "\n--- 📄 Checking Configuration Files ---"
    for file in "/etc/modprobe.d/rtw88.conf" "/etc/NetworkManager/conf.d/wifi-powersave-off.conf" "$REAL_HOME/.config/wifi-keepalive.sh" "$REAL_HOME/.config/autostart/wifi-keepalive.desktop" "/etc/systemd/system/wifi-clear-reboot.service"; do
        if [ -f "$file" ]; then
            ls -la "$file"
        else
            echo "❌ Missing: $file"
        fi
    done

    echo -e "\n--- 🔄 Checking Systemd Shutdown Service ---"
    if systemctl list-unit-files | grep -q "wifi-clear-reboot.service"; then
        systemctl status wifi-clear-reboot.service | grep -E "Active:|Loaded:"
    else
        echo "❌ Systemd service is not registered."
    fi

    echo -e "\n--- 💓 Checking Background Heartbeat (Ping Process) ---"
    if ps aux | grep wifi-keepalive | grep -v grep > /dev/null; then
        ps aux | grep wifi-keepalive | grep -v grep
    else
        echo "❌ Background ping heartbeat process is NOT running."
    fi

else
    echo "❌ Error: Invalid or missing argument."
    echo "Usage:"
    echo "  ./install-wifi-fix.sh install  <- To apply the fix"
    echo "  ./install-wifi-fix.sh remove   <- To revert changes"
    echo "  ./install-wifi-fix.sh check    <- To check active status"
fi
