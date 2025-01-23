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
   - Install an automated scheduled task  
   - Apply the correct network settings  

---

## 🛠 Uninstallation
If you want to remove the fix:
1. **Right-click `uninstall_zerotier_gaming_fix.bat` → Run as Administrator**.
2. This will:
   - Remove the scheduled task  
   - Delete `C:\zerotier_fix`  

---

## 🔧 How It Works
1. **Checks if the ZeroTier adapter metric is correct** (`Metric = 1`).
2. **Ensures Windows firewall allows LAN traffic** by setting the ZeroTier network to **Private**.
3. **Adds a broadcast route (`255.255.255.255`)** to enable LAN discovery.
4. **Runs automatically** whenever ZeroTier reconnects.

---

## ✅ Verify its working
- You can always check your whole adapter settings with the script `Check_Network_Adapter_and_metrics.bat` in resources folder. (Run as administrator)

---

## ⚠️ Notes & Troubleshooting
- **Run the installer as Administrator** to apply settings correctly.
- Check if ping to the devices is working `ping <zerotier-client-ip>`
- If your firewall is **blocking LAN traffic**, manually check the **Windows Defender settings**.
- If LAN discovery still doesn’t work, verify that **Multicast & Broadcast are enabled in ZeroTier Central**.
- Consider running a own Zerotier node with [ZTNET](https://ztnet.network/) since you can adjust MTU Sizes for gaming optimization and unlimited Devices.

---

## 🤝 Contributing
Pull requests are welcome! If you have improvements, feel free to fork the repo and submit a PR.

---

## 📜 License
MIT License. Free to use, modify, and share.

---

### **🎮 Enjoy hassle-free LAN gaming with ZeroTier! 🚀**
