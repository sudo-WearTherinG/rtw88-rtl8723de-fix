
Part 3: Deploy at Boot Using Task Scheduler

To make it automatically turn on whenever your computer boots up without needing any user intervention:
1. Press Win + R, type taskschd.msc, and press Enter.
2. Click Create Task on the right side menu.
3. Under the General tab:
	• Name it: Universal Wi-Fi Keepalive.
	• Select Run whether user is logged on or not.
	• Check Run with highest privileges.
4. Under the Triggers tab:
	• Click New... -> Set Begin the task to At startup.
5. Under the Actions tab:
	• Click New... -> Set Action to Start a program.
	• In Program/script, type: wscript.exe
	• In Add arguments, browse or paste the exact path to your wrapper file: "C:\ProgramData\launch.vbs"
6. Under the Conditions tab:
	• Uncheck "Start the task only if the computer is on AC power" so it works on battery.
7. Click OK, enter your Windows user password when prompted, and it is fully active.


Part 4: Complete the System ASPM Disable

To fully replace your Linux kernel rules (disable_aspm=y) natively inside the Windows registry platform:
1. Open Device Manager, right-click your Realtek adapter -> Properties -> Power Management tab.
2. Uncheck "Allow the computer to turn off this device to save power".
3. Open Control Panel -> Power Options -> Change plan settings -> Change advanced power settings.
4. Expand PCI Express -> Link State Power Management, and switch both On Battery and Plugged in states to Off.
