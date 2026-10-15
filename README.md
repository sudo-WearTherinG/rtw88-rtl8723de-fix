# rtw88-rtl8723de-fix
"Keeping the Realtek RTL8723DE chip awake and alive on Linux. No more sleep glitches. No more streaming lag."

# Universal Realtek rtw88 Wi-Fi Fix for Linux

An automated interactive script designed to fix intermittent Wi-Fi speed drops, video streaming cache freezes, and warm reboot initialization failures for Realtek **rtw88** family cards (`RTL8723DE`, `RTL8821CE`, `RTL8822CE`, `RTL8822BE`).

## 🛠️ The Problems It Resolves

1. **The 1.0 MBit/s RX Drop (Streaming Lag):** Prevents the driver from aggressively downshifting your download bandwidth to 1 Mbps when streaming players temporarily pause to fill video caches.
2. **The Latency/Packet Loss Avalanche:** Bypasses deep driver sleep cycles, dropping severe packet loss from 15% back to 0%.
3. **The Warm Reboot Bug:** Prevents hardware state lockups on restarts caused by motherboard trickle voltage.

---

## 🚀 How It Works (Code Breakdown)

### ⚙️ Option: `install`
* **Driver Flags:** Appends module configs to `/etc/modprobe.d/rtw88.conf` to permanently disable deep low-power states (`disable_lps_deep=y`) and active state power management (`disable_aspm=y`).
* **Power Management Override:** Disables high-level software network throttling via NetworkManager rules.
* **Dynamic Shutdown Service Hook:** Probes and detects your specific driver module dynamically (e.g., `rtw88_8723de`), then builds an automated systemd shutdown hook to forcefully unload the driver components (`modprobe -r`) the exact millisecond a restart is triggered. This forces a clean hardware reset.
* **Clean User-Space Heartbeat:** Deploys a quiet 10-second gateway router ping loop script to `~/.config/wifi-keepalive.sh`. It triggers via a clean systemd-run container inside user space, meaning **zero root process duplicate lines or shell wrappers.**

### 🧹 Option: `remove`
* Completely unloads and purges the systemd shutdown service, finishes running background processes, and wipes all custom configurations, restoring factory system defaults.

### 📋 Option: `check`
* Provides a quick terminal diagnostic layout showing verified file locations, systemd service tracking status, and live active background process logs.

---

## 📥 Installation & Usage

### 1. Apply the Fixes
```bash
chmod +x install-wifi-fix.sh
./install-wifi-fix.sh install
```

⚠️ **CRITICAL STEP AFTER FIRST INSTALLATION:**
Once the script finishes, **do not click Restart/Reboot**. You must perform a complete, hard **Shut Down** of your laptop to cut system power entirely. This resets the glitched physical register state inside your PCIe lane. Once fully powered off, boot up normally. From then on, all future standard restarts will initialize seamlessly!

### 2. Verify Operational Status
```bash
./install-wifi-fix.sh check
```

### 3. Uninstall / Revert to Defaults
```bash
./install-wifi-fix.sh remove
```

## 📋 System Requirements & Supported Chips
* **Supported Variants:** Automatically detects and applies fixes for `rtw88_8723de`, `rtw88_8821ce`, `rtw88_8822ce`, and `rtw88_8822be`.
* **OS:** Optimized for Arch-based distributions (like Omarchy) and Debian/Ubuntu ecosystems running modern Linux kernels. Requires standard network hooks (`NetworkManager`, `iproute2`, and `ping`).
