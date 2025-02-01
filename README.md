# 🎮 ZeroTier Gaming Fix
**Automatically fixes ZeroTier network settings for seamless LAN gaming with zero coding knowledge!**  

When using **ZeroTier for LAN gaming**, some users experience issues where players **cannot see each other in-game**. This happens because **Windows resets network settings(!)** upon reconnecting, affecting:  
✅ **Network adapter metrics**  
✅ **Firewall profile (public/private)**  
✅ **Broadcast traffic for game discovery**  
✅ **optional: Set MTU Size for the whole network (for network admins)**  

This tool ensures that **ZeroTier works flawlessly for LAN gaming**, even after reconnections.

---

## 🚀 Why is this needed?
Many games rely on **LAN discovery via broadcast packets**. Windows often **resets key network settings(!)** when reconnecting to ZeroTier, which prevents proper LAN discovery.  
This fix:
- Ensures **LAN broadcast works**, so game lobbies are always visible.
- Forces **ZeroTier as the top-priority network adapter**.
- Automatically **corrects Windows firewall settings** to allow LAN traffic.
- Prioritizes IPv4 over IPv6 (by default windows prioritizes ipv6). this prioritization ensures that LAN games (which often don’t support IPv6) will use IPv4 whenever possible.
- Optionally to lower a max allowed MTU Packet Size, since games need lower packets for a reduced latency.

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
   - (optional) Set MTU Size for the whole network, if you are network admin. For gaming, many users prefer a lower MTU such as 1400 or even below, to potentially reduce latency and avoid large packet fragmentation. This change is an on-the-fly change and doesn't need the clients to reconnect for its activation, it's active right away! NOTE: After change Zerotier will propably still show an MTU of its default value 2800, but the size has changed to your preferred value. You can check this if you ping your ZT Opponent with `ping <ZT-Opponent-IP> -l 1500 -f`. If you have set 1400 it will "unknown error" or "need to be fragmented" as this will tell you: more than 1400 is not allowed.  

---

## 🛜 Check your Zerotier Network in the Dashboard
- Click on your network
- Scroll down to advanced settings
- Managed Routes -> Add Routes
- add Destination "255.255.255.255/32" via "0.0.0.0" (Enables Broadcast Traffic)
- add Destination "224.0.0.0/4" via "0.0.0.0" (Enables Multicast Traffic)
- done.


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
| **(Optional) Change Network MTU Size** | potentially reduce latency and avoid large packet fragmentation.            | Set the Network MTU Size on ZT-network (my.zerotier.com)                     |

---

## ✅ Verify its working
- You can always check your whole adapter settings with the script 
`Check_Network_interfaces.bat` in resources folder. (Run as administrator)
with this, you can check if metrics, firewall and ipv6 prefix policies are correctly set to your zerotier interfaces.
Expected outputs are written down, for every block.

---

## ⚠️ Notes & Troubleshooting
- **Run the installer as Administrator** to apply settings correctly.
- Check if ping to the devices is working `ping <zerotier-client-ip>` -> find out your ip with cmd.exe -> "ipconfig" enter
- is a `DIRECT` connection to each peer working? Check with `Check_Network_interfaces.bat` in resources folder. (Run as administrator)
- If your firewall is **blocking LAN traffic**, manually check the **Windows Defender settings**.
- If LAN discovery still doesn’t work, verify that **Multicast & Broadcast are enabled in ZeroTier Central**.
- If Discovery still doesnt work, you can have a look at [Winipbroadcast-1.6](https://github.com/dechamps/WinIPBroadcast/releases/tag/winipbroadcast-1.6)
- If Discovery still doesnt work, you can install [Npcap](https://npcap.com/). Npcap enables raw packet capturing, allowing these games to detect LAN sessions over ZeroTier, Hamachi, or OpenVPN. 
- Consider running a own Zerotier controller with [ZTNET](https://ztnet.network/) since you can adjust MTU Sizes in the dashboard (1400 eg.) for gaming optimization and have unlimited Devices.

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

## Why Zerotier?

Zerotier is an advanced networking solution that provides several advantages over traditional VPNs for gaming:

- **Layer 2 Networking**: Unlike many VPN solutions that operate on Layer 3, Zerotier functions on OSI Layer 2, allowing full broadcast and multicast support. This ensures that players can discover each other more easily in multiplayer games.
- **Low Latency**: Zerotier is optimized for peer-to-peer communication, reducing latency compared to conventional VPN solutions.
- **Seamless NAT Traversal**: Many games struggle with NAT issues, but Zerotier efficiently handles NAT traversal, making connections more reliable.
- **Cross-Platform Support**: Works on Windows, Linux, macOS, Android, and iOS, allowing seamless gaming across different devices.

---

## Does the fix work without Zerotier?

Yes, the fix can still help improve connectivity and multiplayer visibility even if you're not using Zerotier. The main focus is on the network adapter configuration. By ensuring that the adapters are set up correctly and that the necessary network bridges are enabled, players can sometimes resolve connection issues without the need for Zerotier. However, without Zerotier, you may not benefit from the advanced Layer 2 networking capabilities and ease of multiplayer discovery that Zerotier provides. Check your LAN settings with the script provided in resources folder `Check_Network_interfaces.bat` (run as administrator)

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
