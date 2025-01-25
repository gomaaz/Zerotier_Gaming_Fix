# 🎮 ZeroTier Gaming Fix
**Automatically fixes ZeroTier network settings for seamless LAN gaming!**  

When using **ZeroTier for LAN gaming**, some users experience issues where players **cannot see each other in-game**. This happens because **Windows resets network settings(!)** upon reconnecting, affecting:  
✅ **Network adapter metrics**  
✅ **Firewall profile (public/private)**  
✅ **Broadcast traffic for game discovery**  

This tool ensures that **ZeroTier works flawlessly for LAN gaming**, even after reconnections.

---

## 🚀 Why is this needed?
Many games rely on **LAN discovery via broadcast packets**. Windows often **resets key network settings(!)** when reconnecting to ZeroTier, which prevents proper LAN discovery.  
This fix:
- Ensures **LAN broadcast works**, so game lobbies are always visible.
- Forces **ZeroTier as the top-priority network adapter**.
- Automatically **corrects Windows firewall settings** to allow LAN traffic.
- Prioritizes IPv4 over IPv6 (by default windows prioritizes ipv6). this prioritization ensures that LAN games (which often don’t support IPv6) will use IPv4 whenever possible.

### ✅ Features:
✔ **Auto-fix for ZeroTier adapter settings**  
✔ **Runs automatically in the background**  
✔ **No need to manually adjust settings**  
✔ **Works on Windows 10 & 11**  

---

## 📥 Installation

### **Step 1: Download & Extract**
1. **Download the latest ZIP** from the [Releases](https://github.com/gomaaz/Zerotier_Gaming_Fix/releases) page.  
2. Extract the ZIP file (`Zerotier_Gaming_Fix_vX.X_Win11.zip`).  

### **Step 2: Install the Fix**
1. Open the extracted folder **`Zerotier_Gaming_Fix_vX.X_Win11`**.
2. **Right-click `install_zerotier_gaming_fix.bat` → Run as Administrator**.  
3. The fix will:
   - Copy necessary files to `C:\zerotier_fix`
   - Install an automated scheduled task, triggered by a zerotier network (re-)connect
   - Apply the correct network settings for those interfaces
   - Set IPv6 prefix policies to prioritize IPv4 over IPv6 as a workaround, since IPv6 cannot be disabled via shell commands for ZeroTier adapters.
   - activate the legacycomponent of windows "Directplay", since it's needed for some [older games](https://gitlab.winehq.org/wine/wine/-/wikis/DirectPlay-Games)

---

## 🛠 Uninstallation
If you want to remove the fix:
1. **Right-click `uninstall_zerotier_gaming_fix.bat` → Run as Administrator**.
2. This will:
   - Remove the scheduled task
   - restore ipv6 prefix policies  
   - Delete `C:\zerotier_fix`
   - deactivate direct play feature from windows components

---

## 🔧 How It Works
**Runs automatically** whenever ZeroTier reconnects - for existing and all future zerotier networks.

| **Category**                | **Fix**                                       | **Installation**                                               |
| --------------------------- | --------------------------------------------- | -------------------------------------------------------------- |
| **Multicast & Broadcast**   | Enable LAN discovery for older games          | Ensure routes for `255.255.255.255/32` and `224.0.0.0/4` exist |
| **DirectPlay Fix**          | Required for older games                      | Enables Feature via `dism` command                                      |
| **Network Metric Priority** | Ensure ZeroTier has priority for game traffic | Set `Metric = 1` for ZeroTier adapters                         |
| **IPv6 Issues**             | Prioritize ipv4 Traffic if causing issues                     |  ::ffff:0:0/96 at top of the prefix table                        |
| **Windows Network Profile** | Set ZeroTier as **Private** network           | Prevents Windows from blocking LAN traffic                     |

---

## ✅ Verify its working
- You can always check your whole adapter settings with the script 
`Check_Network_interfaces.bat` in resources folder. (Run as administrator)
with this, you can check if metrics, firewall and ipv6 prefix policies are correctly set to your zerotier interfaces.
Expected outputs are written down, for every block.

---

## ⚠️ Notes & Troubleshooting
- **Run the installer as Administrator** to apply settings correctly.
- Check if ping to the devices is working `ping <zerotier-client-ip>`
- is a `DIRECT` connection to each peer working? Check with powershell (as administrator) and type `zerotier-cli.bat peers`
- If your firewall is **blocking LAN traffic**, manually check the **Windows Defender settings**.
- If LAN discovery still doesn’t work, verify that **Multicast & Broadcast are enabled in ZeroTier Central**.
- If Discovery still doesnt work you can have a look at [Winipbroadcast-1.6](https://github.com/dechamps/WinIPBroadcast/releases/tag/winipbroadcast-1.6)
- In Zerotier dashboard, set managed routes `255.255.255.255/32 via 0.0.0.0` and `224.0.0.0/4 via 0.0.0.0`)
- Consider running a own Zerotier controller with [ZTNET](https://ztnet.network/) since you can adjust MTU Sizes (1400 eg.) for gaming optimization and unlimited Devices.

---

## 🎮 Considerations for Gaming with Linux and Mac Friends  

When playing with friends on **Linux or macOS**, there are additional steps required to ensure **LAN discovery works properly over ZeroTier**.

By default, **broadcast traffic is not automatically routed over the ZeroTier adapter** on macOS and Linux. To fix this, you need to **manually add a broadcast route**.

Like so

`sudo route add -host 255.255.255.255 dev my_zerotier_interface`

Replace `my_zerotier_interface` with the actual name of your ZeroTier adapter.

For this find your interface with on Linux:

```sh on Linux (shell)
ip addr
```

on mac (with Terminal)
```sh on mac
ifconfig
```

then enter the command with the device ID printed in the output above
```sh with ztkseq3i6h as example device ID
sudo route add -host 255.255.255.255 dev ztkseq3i6h
```


---

## 🤝 Contributing
Pull requests are welcome! If you have improvements, feel free to fork the repo and submit a PR.

---

## 🛑 Disclaimer

This software is provided **"as is"** without any warranties or guarantees. By using this script, you agree that the author(s) are **not responsible** for any potential damages, data loss, or system instability that may result from its use.

### ⚠️ Use at Your Own Risk!
- Modifying network settings, firewall rules, and system components may cause **unintended side effects**.
- Enabling or disabling legacy components (e.g., DirectPlay) may affect **system performance or compatibility**.
- Always **create a backup** of your system before applying any modifications.

### 🚀 No Liability
The author(s) **assume no liability** for:
- System crashes, malfunctions, or misconfigurations.
- Loss of network connectivity or application failures.
- Any other unintended behavior resulting from the use of this script.

If you are **unsure** about using this tool, consult **official documentation** or seek **professional support**.

By running this script, you **acknowledge and accept** full responsibility for any changes made to your system.

---

### **🎮 Enjoy hassle-free LAN gaming with ZeroTier! 🚀**
