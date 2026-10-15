# rtw88-rtl8723de-fix
> "Keeping the Realtek RTL8723DE chip awake and alive on Linux. No more sleep glitches. No more streaming lag."

# Universal Realtek rtw88 Wi-Fi Fix for Linux

An automated interactive shell script designed to permanently fix intermittent Wi-Fi speed drops, video streaming cache freezes, and warm reboot initialization failures for Realtek **rtw88** family combo cards (`RTL8723DE`, `RTL8821CE`, `RTL8822CE`, `RTL8822BE`).

---

## 🛠️ The Creator's Diagnostic Journey & Root Causes

When developing this fix, navigating the underlying kernel module behaviors exposed why these Realtek cards perform so terribly under default Linux environments. The root causes of the bugs boil down to two core engineering flaws:

### 1. The Idle-Silence Trap & The 1 Mbps RX Crash
Modern streaming players (like YouTube, Netflix, or standard HTML5 players) use a behavior called **buffer capping**. The player aggressively downloads 1 to 2 minutes of video data into RAM and then completely pauses network downloads until you catch up. 

During this quiet window, the network line falls completely silent. The default `rtw88` driver architecture misinterprets this silence as system idleness. To save power, the driver forces the card into a low-power mode and downshifts the receiving speed limit to **exactly 1.0 MBit/s** (the minimum fallback rate of legacy 802.11b). When the video player tries to wake the card back up to download the next chunk, the card responds too slowly, packets get backed up in the internal transmission queue, and the video stalls indefinitely. 
`"I noticed that disconnecting and reconnecting the Wi-Fi fixes the lag right away, but it's only a temporary band-aid. The issue keeps coming back, forcing you to manually reconnect over and over again."`

### 2. The PCIe Warm Reboot Power Freeze
On laptops like the **HP 15-da series**, the motherboard maintains a small **trickle voltage** to the PCIe slot during a standard software restart. If the card falls into a deep sleep state right before shutdown, this standby power prevents the physical hardware registers from discharging. 

When your laptop reboots, the card gets stuck in a glitched, uninitialized hardware state from the previous session. The driver tries to probe it, fails, and leaves your wireless scanning completely broken until you perform a full cold shutdown to drop the power rail to 0V.

---

## 🚀 How It Works (Code Breakdown)

### ⚙️ Option: `install`
The installation suite systematically dismantles these hardware issues using a layered defense:

#### 1. Hardware Overrides (`disable_lps_deep=y` and `disable_aspm=y`)
The script writes explicit configuration instructions straight to your kernel module parameters at `/etc/modprobe.d/rtw88.conf`:
*   **`disable_lps_deep=y`**: This parameter explicitly locks the firmware out of its deep Low Power States. It tells the hardware: *Never sleep the chip core.*
*   **`disable_aspm=y`**: This turns off Active State Power Management on the PCIe bus layer. It stops the motherboard from cutting power to the link lanes dynamically.
*   **Why the 'Y' Matters:** Passing `y` (Yes) forcefully changes the kernel's default parameters. When active, you can query your system at `/sys/module/rtw88_core/parameters/disable_lps_deep` and it will read a definitive **`Y`**. This is your physical proof that the hardware-level sleep loops have been securely disabled.

#### 2. NetworkManager Power Management Override
```bash
echo -e "[connection]\nwifi.powersave = 2" | sudo tee /etc/NetworkManager/conf.d/wifi-powersave-off.conf
```
*   **Why it's required:** High-level network managers will try to force power saving on the card even if the driver parameter is active. Setting this value to `2` completely turns off software-level power saving, preventing the desktop environment from throttling the radio link.

#### 3. Dynamic Shutdown Service Hook (`wifi-clear-reboot.service`)
```bash
ExecStop=-/usr/bin/modprobe -r btusb
ExecStop=-/usr/bin/modprobe -r $CHIP_MODULE
```
*   **Why it's required:** The script automatically probes your running memory using `lsmod` to find your precise driver variant (e.g., `rtw88_8723de`). It maps that name into a custom systemd service that triggers the split-second you click restart. By forcefully unloading (`modprobe -r`) the Wi-Fi and Bluetooth drivers right before the machine reboots, it breaks the hardware loop early, ensuring the card initializes completely fresh on the next warm boot.

#### 4. Clean User-Space Heartbeat (`wifi-keepalive.sh`)
```bash
systemd-run --user --machine="${REAL_USER}@" --quiet "$REAL_HOME/.config/wifi-keepalive.sh"
```
*   **Why it's required:** The script drops a tiny loop file into `~/.config/wifi-keepalive.sh` that automatically pings your local gateway router every 10 seconds. This persistent pulse guarantees your network connection **never stays quiet long enough to trigger the idle state**. Your bitrates remain maxed out, and video streaming stays perfectly smooth. 
*   **The Professional Launch:** By utilizing `systemd-run --user`, the script detaches the loop cleanly into the user system daemon. This avoids messy terminal wrapper processes, keeping your `ps aux` tracking logs down to **exactly one clean process line** running natively under your user profile.

---

### 🧹 Option: `remove`
*   Gracefully stops and completely deletes the custom systemd reboot hook.
*   Terminates any running keepalive ping loops in the user space daemon.
*   Deletes all customized files (`rtw88.conf`, `wifi-powersave-off.conf`, and hidden configuration folders), instantly returning your Linux operating system back to its factory default state.

---

### 📋 Option: `check`
*   Provides an instant terminal diagnostic report showing verified file sizes, directory permissions, systemd unit health, and active background process IDs so you can confirm the fix is working perfectly.

---

## 📥 Installation & Usage

### 1. Apply the Fixes
```bash
chmod +x install-wifi-fix.sh
./install-wifi-fix.sh install
```

⚠️ **CRITICAL STEP AFTER FIRST INSTALLATION:**
Once the installer prints its completion message, **do not click standard Restart/Reboot**. Because the card was already caught in a low-power loop during your current uptime session, you must perform a complete, hard **Shut Down** of your laptop. Let the power rails drop completely to clear the glitched PCIe register state. Once the laptop turns off fully, boot up normally. From this point forward, all future standard warm restarts will initialize automatically!

### 2. Verify Operational Status
```bash
./install-wifi-fix.sh check
```

### 3. Uninstall / Revert to Defaults
```bash
./install-wifi-fix.sh remove
```

---

## 📋 System Requirements & Supported Chips
*   **Universal Driver Detection:** The script automatically probes your system to detect and fix your specific variant. It fully supports all Realtek `rtw88` device models:
    *   **RTL8723DE** (`rtw88_8723de`)
    *   **RTL8821CE** (`rtw88_8821ce`)
    *   **RTL8822CE** (`rtw88_8822ce`)
    *   **RTL8822BE** (`rtw88_8822be`)
*   **OS Compatibility:** Verified and optimized for Arch-based distributions (such as Omarchy) and Debian/Ubuntu-based environments running modern Linux kernels. Requires standard networking tools (`NetworkManager`, `iproute2`, and `ping`).
