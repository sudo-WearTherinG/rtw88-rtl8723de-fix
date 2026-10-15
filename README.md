# rtw88-rtl8723de-fix
"Keeping the Realtek RTL8723DE chip awake and alive on Linux. No more sleep glitches. No more streaming lag."

# Realtek RTL8723DE Wi-Fi Fix for Linux (HP 15-da Series)

An automated interactive shell script designed to permanently fix intermittent Wi-Fi speed drops, video streaming cache freezes, and warm reboot initialization failures for the **Realtek RTL8723DE** combo card on modern Linux distributions.

## 🛠️ The Problems It Resolves

1. **The 1.0 MBit/s RX Drop (Streaming Lag):** Resolves the bug where the `rtw88_8723de` driver aggressively drops the receiving bitrate down to 1 Mbps when the network buffer goes quiet during online video streaming.
2. **The Latency/Packet Loss Avalanche:** Bypasses deep driver sleep cycles, reducing severe packet loss (from 15% back down to 0%).
3. **The Warm Reboot Bug:** Prevents the network card from freezing into an uninitialized power state during system warm restarts, ensuring available networks show up instantly.

## 🚀 How It Works

- **Kernel Flags:** Forces `rtw88_core` and `rtw88_pci` to disable deep low-power sleep states (`disable_lps_deep=y`) and active state power management (`disable_aspm=y`).
- **Network Pulse (Heartbeat):** Deploys a quiet, low-overhead background heartbeat script that pings the local gateway router every 10 seconds to keep the wireless data line warm.
- **Systemd Shutdown Quiesce:** Creates an automated shutdown hook to cleanly unload the `btusb` and `rtw88_8723de` kernel driver modules the exact millisecond a restart is triggered, preventing hardware state lockups.

## 📥 Installation & Usage

Clone the repository or download the script file, then navigate to the directory in your terminal and follow the options below:

### 1. Apply the Fixes
To write the configuration files, create the background heartbeat loop, and enable the reboot service:
```bash
chmod +x install-wifi-fix.sh
./install-wifi-fix.sh install
```

### 2. Verify Operational Status
To quickly check that all configuration files exist, the systemd unit is loaded, and the background ping loop is actively working:
```bash
./install-wifi-fix.sh check
```

### 3. Uninstall / Revert to Defaults
If you want to cleanly purge the rules, terminate the background loops, and restore factory kernel settings:
```bash
./install-wifi-fix.sh remove
```

## 📋 System Requirements
Optimized and verified for Arch-based distributions (like Omarchy) and Debian/Ubuntu-based environments running modern Linux kernels. Requires standard networking utilities (`NetworkManager`, `iproute2`, and `ping`).
