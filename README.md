# rtw88-rtl8723de-fix
"Keeping the Realtek RTL8723DE chip awake and alive on Linux. No more sleep glitches. No more streaming lag."

# Realtek RTL8723DE Wi-Fi Fix for Linux (HP 15-da Series)

An automated interactive shell script designed to permanently fix intermittent Wi-Fi speed drops, video streaming cache freezes, and warm reboot initialization failures for the **Realtek RTL8723DE** combo card on modern Linux distributions.

## 🛠️ The Problems It Resolves

1. **The 1.0 MBit/s RX Drop (Streaming Lag):** Resolves the bug where the `rtw88_8723de` driver aggressively drops the receiving bitrate down to 1 Mbps when the network buffer goes quiet during online video streaming.
2. **The Latency/Packet Loss Avalanche:** Bypasses deep driver sleep cycles, reducing severe packet loss (from 15% back down to 0%).
3. **The Warm Reboot Bug:** Prevents the network card from freezing into an uninitialized power state during system warm restarts, ensuring available networks show up instantly.

---

## 🔍 Code Breakdown: What Each Section Does

The interactive script executes distinct system modifications depending on the argument passed:

### ⚙️ When Running `install`:

#### 1. Hardware-Level Sleep Disabling
```bash
echo -e "options rtw88_core disable_lps_deep=y\noptions rtw88_pci disable_aspm=y" | sudo tee /etc/modprobe.d/rtw88.conf
```
* **What it does:** Creates a dedicated driver module configuration file.
* **Why it matters:** It forces the `rtw88` core engine to completely disable deep Low Power States (`disable_lps_deep=y`) and blocks Active State Power Management (`disable_aspm=y`) on the PCIe bus. This prevents the card from falling into unrecoverable sleep modes.

#### 2. NetworkManager Power Management Override
```bash
echo -e "[connection]\nwifi.powersave = 2" | sudo tee /etc/NetworkManager/conf.d/wifi-powersave-off.conf
```
* **What it does:** Deploys a global connectivity instruction file to the high-level network daemon.
* **Why it matters:** A values option of `2` completely disables high-level software power management. This guarantees the desktop environment will never attempt to throttle or sleep the wireless radio link.

#### 3. Systemd Shutdown Driver Unloader Hook
```bash
sudo tee /etc/systemd/system/wifi-clear-reboot.service << 'EOF'
...
ExecStop=-/usr/bin/modprobe -r btusb
ExecStop=-/usr/bin/modprobe -r rtw88_8723de
```
* **What it does:** Creates and enables a customized `oneshot` system configuration service.
* **Why it matters:** Because the HP 15-da motherboard maintains a tiny trickle voltage during warm restarts, the wireless chip easily locks up on system reboots. This service catches the system termination target and forcefully unloads the Wi-Fi and Bluetooth drivers (`modprobe -r`), forcing the hardware state machine to detach cleanly so it initializes perfectly on the next boot cycle.

#### 4. Automated Hidden Keepalive Heartbeat
```bash
while true; do
  TARGET_IP=$(ip route | awk '/default/ {print $3}')
  [ ! -z "$TARGET_IP" ] && ping -c 1 -W 2 "$TARGET_IP" > /dev/null 2>&1
  sleep 10
done
```
* **What it does:** Compiles a background loop script located at `~/.config/wifi-keepalive.sh` and attaches a standard desktop autostart configuration desktop entry.
* **Why it matters:** It programmatically traces your gateway gateway IP and fires a tiny, invisible 64-byte network ping every 10 seconds. This artificial connection activity tricks the chip into remaining in top-speed processing cycles, preventing your receiving bitrate from downshifting to 1.0 MBit/s when video streaming players pause to fill caches.

---

### 🧹 When Running `remove`:
* **Reverts to System Defaults:** Stops and completely purges the `wifi-clear-reboot.service`.
* **Kills Processes:** Terminates the active hidden ping process loops.
* **Wipes Files:** Cleanly deletes the `rtw88.conf`, `wifi-powersave-off.conf`, and `wifi-keepalive.sh` configurations, restoring your Linux network distribution back to its clean stock environment state.

---

### 📋 When Running `check`:
* **Diagnostic Audit:** Iterates through your directories to verify file existence, file security permissions, active process statuses, and systemd enablement, giving you immediate feedback on whether your setup is healthy.

---

## 📥 Installation & Usage

Clone the repository or download the script file, then navigate to the directory in your terminal and follow the options below:

### 1. Apply the Fixes
To write the configuration files, create the background heartbeat loop, and enable the reboot service:
```bash
chmod +x install-wifi-fix.sh
./install-wifi-fix.sh install
```

⚠️ **CRITICAL STEP AFTER FIRST INSTALLATION:**
Once the installer finishes execution, **do not click standard Restart/Reboot**. You must perform a complete, hard **Shut Down** of your laptop to entirely cut system electrical power. This is required to force the glitched physical register state inside your PCIe lane to reset. Once the machine has fully powered off, turn it back on normally. From this point forward, all future standard warm reboots will initialize seamlessly!

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
