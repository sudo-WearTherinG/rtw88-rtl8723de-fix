#!/bin/bash

# Check if user provided an argument
ACTION=$1

if [ "$ACTION" == "install" ]; then
    echo "⚙️ Setting up automated Omarchy Wi-Fi fix for HP 15-da..."

    # 1. Block hardware-level PCIe sleep glitches
    echo -e "options rtw88_core disable_lps_deep=y\noptions rtw88_pci disable_aspm=y" | sudo tee /etc/modprobe.d/rtw88.conf

    # 2. Disable high-level NetworkManager power cycling
    sudo mkdir -p /etc/NetworkManager/conf.d
    echo -e "[connection]\nwifi.powersave = 2" | sudo tee /etc/NetworkManager/conf.d/wifi-powersave-off.conf

    # 3. Inject the shutdown driver unloader (Fixes the warm reboot bug)
    sudo tee /etc/systemd/system/wifi-clear-reboot.service << 'EOF'
[Unit]
Description=Quiesce RTL8723DE combo device before shutdown
Before=NetworkManager.service shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/true
ExecStop=-/usr/bin/modprobe -r btusb
ExecStop=-/usr/bin/modprobe -r rtw88_8723de

[Install]
WantedBy=multi-user.target
EOF

    # Enable the reboot system service
    sudo systemctl enable wifi-clear-reboot.service

    # 4. Create the hidden configuration directory for the ping script
    mkdir -p ~/.config/autostart

    # 5. Create the hidden background heartbeat script (Fixes the 1Mbps video drop)
    cat << 'EOF' > ~/.config/wifi-keepalive.sh
#!/bin/bash
while true; do
  TARGET_IP=$(ip route | awk '/default/ {print $3}')
  if [ ! -z "$TARGET_IP" ]; then
    ping -c 1 -W 2 "$TARGET_IP" > /dev/null 2>&1
  fi
  sleep 10
done
EOF

    chmod +x ~/.config/wifi-keepalive.sh

    # 6. Set up the system desktop startup launcher
    cat << EOF > ~/.config/autostart/wifi-keepalive.desktop
[Desktop Entry]
Type=Application
Exec=$HOME/.config/wifi-keepalive.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Wi-Fi Keepalive
Comment=Prevents Realtek Wi-Fi drops
EOF

    # Launch it immediately
    pkill -f wifi-keepalive.sh
    ~/.config/wifi-keepalive.sh &

    echo "✅ Full master script configuration applied."

elif [ "$ACTION" == "remove" ]; then
    echo "🧹 Removing automated Wi-Fi fixes and restoring system defaults..."

    # 1. Stop and completely disable the shutdown service
    sudo systemctl disable --now wifi-clear-reboot.service 2>/dev/null
    sudo rm -f /etc/systemd/system/wifi-clear-reboot.service
    sudo systemctl daemon-reload

    # 2. Kill the running background heartbeat loop
    pkill -f wifi-keepalive.sh

    # 3. Delete all created configuration and script files
    sudo rm -f /etc/modprobe.d/rtw88.conf
    sudo rm -f /etc/NetworkManager/conf.d/wifi-powersave-off.conf
    rm -f ~/.config/wifi-keepalive.sh
    rm -f ~/.config/autostart/wifi-keepalive.desktop

    # 4. Restart NetworkManager to load default settings
    sudo systemctl restart NetworkManager

    echo "🗑️ All fixes removed successfully. System has been reverted to default state."

elif [ "$ACTION" == "check" ]; then
    echo -e "\n--- 📄 Checking Configuration Files ---"
    for file in "/etc/modprobe.d/rtw88.conf" "/etc/NetworkManager/conf.d/wifi-powersave-off.conf" "$HOME/.config/wifi-keepalive.sh" "$HOME/.config/autostart/wifi-keepalive.desktop" "/etc/systemd/system/wifi-clear-reboot.service"; do
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
