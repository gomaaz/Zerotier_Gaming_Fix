# 🎮 ZeroTier Gaming Fix

**Automatically fixes Windows network settings so ZeroTier works seamlessly for LAN gaming — zero coding required.**

When you use **ZeroTier for LAN gaming**, players often **can't see each other in-game** because Windows resets the relevant network settings every time a ZeroTier network reconnects. This tool restores the right settings automatically, on every reconnect, in the background.

---

## 🛑 Heads-up: this is a vibe-coding project

This repo is a **vibe-coding project** — built iteratively with AI assistance, driven by what worked on the author's own gaming setup rather than by formal engineering process. There are **no automated tests**, no CI, and no professional code review. Scripts are validated by running them on real Windows machines and watching whether LAN games actually discover each other; that's the whole QA pipeline.

What that means for you:

- It works well for the **typical home gaming scenario** it was built around (Windows 10/11, ZeroTier 1.14–1.16, handful of peers, LAN game discovery).
- Edge cases, exotic network setups, enterprise/managed Windows, or future ZeroTier versions may break in ways nobody has tried yet.
- If something doesn't work, the best path is to read [Check_Network_interfaces.bat](resources/Check_Network_interfaces.bat) output, open an issue with the diagnostic, and treat the fix as a starting point you can adapt — not a hardened product.

**See the full disclaimer at the bottom of this README before running anything.** TL;DR: it modifies your network stack with Admin rights; back up first, run at your own risk.

---

## ⚠️ Read this first: ZeroTier's free tier no longer allows the two managed routes this fix expects

ZeroTier has tightened the limits on **custom managed routes** for free accounts. As of late 2025 / early 2026:

- The **new web UI** at [my.zerotier.com](https://my.zerotier.com) shows the *Managed Routes* form fully greyed out with `Custom routes are unavailable at your current plan tier`.
- The **old web UI** lets you add a single custom route, but the LAN route already counts against the cap, so you typically see `2 / 1 routes` and the *Add* button is disabled.

This fix's *Enable broadcast/multicast on the ZeroTier side* step (further down) originally asked you to add **two** custom routes on the controller — `255.255.255.255/32` for broadcast and `224.0.0.0/4` for multicast. On a free account today, that's no longer fully possible. You have three realistic options:

1. **Add only `255.255.255.255/32`** (broadcast) as your one allowed custom route. That covers classic LAN-broadcast game discovery (AoE II, classic C&C, most older multiplayer titles, Half-Life 1 mods, …). Multicast/mDNS/SSDP-style discovery used by some newer engines will still be broken, but a lot of LAN-gaming scenarios work with broadcast alone.
2. **Self-host the controller with [ZTNET](https://ztnet.network/)** *(recommended once you outgrow option 1)*. ZTNET is a free, open-source ZeroTier controller you can run in a Docker container on a Raspberry Pi, NAS, or small VPS. It gives you **unlimited custom managed routes, unlimited devices, adjustable network-wide MTU, and a full dashboard** — using the same ZeroTier protocol and same peer-to-peer transport as `my.zerotier.com`, only the control plane moves to your own box. Every step of this README works against a ZTNET controller exactly the same way (open the network → *Advanced* → *Managed Routes* → add both routes).
3. **Pay for a ZeroTier tier** that lifts the route limit.

A note on why the controller route matters even though `ZeroTier_Fix.bat` adds local `255.255.255.255/32` routes on every Windows client: the local route tells *Windows* to send broadcast frames over the ZT adapter, but the **controller-side managed route is what tells the ZT virtual switch to actually forward those broadcasts across peers**. Without it, peers won't see each other's broadcasts no matter what each client's local routing table says.

---

## ✅ What it fixes

| Area | What the fix does |
| --- | --- |
| **Adapter metric** | Sets `InterfaceMetric = 1` on the **IPv4** stack of every ZeroTier adapter so games prefer ZT over LAN/Wi-Fi. The **IPv6** stack is set to `20` instead — deliberately deprioritized so other adapters' IPv6 wins route selection (most LAN-game discovery and older netcode is IPv4-only; we don't want ZT's IPv6 fighting native IPv6). `AutomaticMetric` is disabled on both so Windows doesn't re-derive the value from link speed at every reconnect. |
| **Firewall profile** | Sets the ZeroTier connection to **Private** *and* writes `Category=1` directly into the saved profile under `HKLM\…\NetworkList\Profiles\{guid}` — that's the on-disk value Windows' NLA service reads back at the next reconnect, so the category survives identification events that would otherwise flip ZT back to Public. Also explicitly enables the **Network Discovery** and **File and Printer Sharing** firewall rule groups. |
| **Broadcast & multicast** | Adds persistent routes `255.255.255.255/32` and `224.0.0.0/4` on every ZeroTier adapter — needed by classic LAN broadcast, mDNS, SSDP, IGMP, and game server browsers. |
| **IPv4 priority** | Adds Windows prefix policy `::ffff:0:0/96 100 4` so IPv4 outranks IPv6 *for dual-stack hostname resolution* (RFC 6724). Most LAN games don't speak IPv6. **Does not disable IPv6** and does not affect ZeroTier's own IPv6 transport — see FAQ below. |
| **DirectPlay** | Enables the legacy Windows component required by some [older games](https://gitlab.winehq.org/wine/wine/-/wikis/DirectPlay-Games). |
| **No internet hijack** | Removes the `0.0.0.0/0` default route ZeroTier might add, so it doesn't capture your normal internet traffic. |
| **WinIPBroadcast** *(optional)* | One-click install of [WinIPBroadcast](https://github.com/dechamps/WinIPBroadcast) as a Windows service — rebroadcasts IP broadcasts across all interfaces for legacy DirectPlay-era games (Age of Empires II, classic C&C, Quake-derived titles, Half-Life 1 mods). |
| **Per-network MTU** *(optional)* | Lower the network-wide MTU via the ZeroTier Central API — common for gaming setups that prefer 1400 over the ZT default of 2800. |

---

## 🧩 Requirements

- **Windows 10 or Windows 11.** The fix uses Windows-specific cmdlets and the Task Scheduler event-trigger system — it does not run on Linux, macOS, or Windows Server in unsupported configurations.
- **Administrator rights** for installation and uninstallation.
- **ZeroTier One installed** — any version from **1.14** through the current **1.16.1** has been validated. Newer 1.x versions should keep working.

### ZeroTier 1.16 notes

- The installer pre-stages multi-core packet I/O settings in `local.conf`. As of 1.16.1 the Windows multi-core port is **not yet released** (Linux/FreeBSD only — see the [ZeroTier multithreading docs](https://docs.zerotier.com/multithreading/)). The settings are **forward-compatible** and take effect automatically once the Windows port lands; today they are inert.
- 1.16 adds `encryptedHelloEnabled` for HELLO-packet encryption (set it in `local.conf` manually if desired).
- 1.16 *Network-Specific Relays* (beta) can help if your peers struggle with NAT traversal — configure on the ZeroTier Central side, no client-side change needed.

---

## 📥 Installation

### 1. Download and extract

1. Download the latest ZIP from the [Releases](https://github.com/gomaaz/Zerotier_Gaming_Fix/releases) page (`Zerotier_Gaming_Fix_vX.Y.Z_Win11.zip`).
2. Extract it anywhere.

### 2. Run the installer as Administrator

Right-click `install_zerotier_gaming_fix.bat` → **Run as Administrator**.

The installer will:

- Copy the fix scripts to `C:\zerotier_fix\` and write a `version.txt` so future re-runs know which version is already present.
- Enable the **DirectPlay** Windows feature.
- Pre-stage the multi-core `local.conf` in `%ProgramData%\ZeroTier\One\` (forward-compatible, see note above). Any existing `local.conf` is backed up first to `local.conf.bak.<timestamp>`.
- Register the **ZeroTier Auto Fix** scheduled task. It triggers on Windows network-profile events, so the fix re-applies itself every time a ZeroTier network connects or reconnects.
- Run the task once so settings are applied immediately.
- *(Optional)* Offer to install **WinIPBroadcast** as a service — only do this if older LAN games still don't discover peers after the basic fix. Downloads from upstream over TLS at install time; no binary is bundled with this repo.
- *(Optional)* Offer to call the **MTU helper** (`update_zerotier_mtu.ps1`) if you are the admin of the ZeroTier network and want to set a non-default MTU.

### 3. Verify

After install, run `C:\zerotier_fix\Check_Network_interfaces.bat` as Administrator. See the **Verifying the fix** section below for what the output should look like.

---

## 🛜 Enable broadcast/multicast on the ZeroTier side

For the fix to be effective, your ZeroTier network controller must actually forward broadcast and multicast traffic. ZeroTier doesn't enable this by default (broadcast scales poorly in large networks).

1. Open your network on [my.zerotier.com](https://my.zerotier.com).
2. Scroll to **Advanced** → **Managed Routes** → **Add Route**.
3. Add `255.255.255.255/32` via `0.0.0.0` — enables broadcast.
4. Add `224.0.0.0/4` via `0.0.0.0` — enables multicast (mDNS, SSDP, server browsers).

> ⚠️ **Free-tier note:** Steps 3 and 4 require two custom managed routes; the current ZeroTier free tier only allows **one** (and the new web UI blocks custom routes entirely). See the *Read this first* section at the top of this README — short answer: add `255.255.255.255/32` only and you're fine for most classic LAN games, or switch to a self-hosted [ZTNET](https://ztnet.network/) controller for unlimited routes.

If you self-host your own controller via [ZTNET](https://ztnet.network/), you can additionally tune the network-wide MTU from the dashboard (e.g. 1400 for gaming) and remove ZeroTier Central's device limits.

---

## 🎚️ Optional: lower the network MTU

ZeroTier's default MTU is **2800**. For latency-sensitive gaming, **1400 or lower** is often a better fit and helps avoid fragmentation by the underlying transport.

You can change it via the ZeroTier Central API:

- During install, answer **yes** when prompted about the MTU change, or
- Later, run `C:\zerotier_fix\change_MTU_only.bat` as Administrator.

You'll be asked for an API token (created at *my.zerotier.com → Account → API Access Tokens*), the 16-hex network ID, and the new MTU.

**Verify it took effect:**

```cmd
ping <zt-peer-ip> -l 1500 -f
```

If you set MTU to 1400, this should report *"Packet needs to be fragmented"* or similar — confirming that anything above 1400 is now blocked.

> ⚠️ The ZeroTier dashboard may still display the old MTU (2800) after the change — this is a known visual bug, not a failed update. The ping test above is the source of truth.

Games typically inherit the system MTU automatically, but some hard-code their own packet size and won't be influenced by this setting. Don't use a very low MTU if you also rely on the network for large file transfers.

---

## 🔁 Updating

Just run the installer again. The version detection prints what's already installed and the rest is idempotent.

---

## 🛠 Uninstallation

Right-click `uninstall_zerotier_gaming_fix.bat` (either in your extracted folder or `C:\zerotier_fix\`) → **Run as Administrator**.

The uninstaller will:

- Stop and delete the **ZeroTier Auto Fix** scheduled task (and any legacy `ZeroTier_PrioritizeIPv6` task from older installs).
- Restore the saved **IPv6 prefix policies** from the backup file.
- **Disable** the DirectPlay Windows feature.
- *(If present)* Stop and unregister the **WinIPBroadcast** service and remove `%ProgramFiles%\WinIPBroadcast\`. Only acts on the path the installer uses; separately-installed copies are left alone.
- Delete the **persistent broadcast and multicast routes** on every ZeroTier adapter (`255.255.255.255/32` and `224.0.0.0/4`).
- **Restore** the most recent installer-written `local.conf.bak.*` to `%ProgramData%\ZeroTier\One\local.conf`, or delete our `local.conf` if no backup was found.
- Delete `C:\zerotier_fix\` and everything in it.

---

## ✅ Verifying the fix

Run `Check_Network_interfaces.bat` (in `resources\` after extraction, or `C:\zerotier_fix\` after install) as Administrator. It prints eight diagnostic sections, each with the **expected output**:

| # | Section | What to look for |
| --- | --- | --- |
| 0 | DirectPlay status | `State: Enabled` |
| 1 | Adapter metrics | ZeroTier adapters: **IPv4 `InterfaceMetric=1`** (top priority), **IPv6 `InterfaceMetric=20`** (deprioritized) |
| 2 | Network profiles | ZeroTier connections show `NetworkCategory: Private` |
| 3 | IPv6 prefix policies | `::ffff:0:0/96` has precedence 100 (top of the table) |
| 4 | IPv6 routes on ZT | No `::/0` default route on ZT adapters |
| 5 | IPv4 routes on ZT | No `0.0.0.0/0` if internet routing is disabled |
| 6 | Scheduled task status | `LastTaskResult: 0` after at least one recent reconnect |
| 7 | Last lines of `run.log` | Recent `run start`/`run end` entries |
| 8 | WinIPBroadcast service | `STATE: RUNNING` if you opted into it, else "not installed" |

The peer-connection check at the top (`zerotier-cli peers`) should show **DIRECT** connections for low latency. **RELAY** means peer-to-peer punching failed — typically a router/firewall blocking UDP **9993** in one direction.

---

## 🔧 How it works under the hood

The installer registers a Task Scheduler job that subscribes to **`Microsoft-Windows-NetworkProfile/Operational` Event ID 10000** — which Windows fires every time it identifies a network. Whenever a ZeroTier network (re-)connects, the task runs `C:\zerotier_fix\ZeroTier_Fix.bat` as SYSTEM with elevated rights and re-applies everything from the **What it fixes** table above.

This is necessary because Windows resets adapter metric, network category, and route settings on every network identification event — once at install time isn't enough.

### Logging — `C:\zerotier_fix\run.log`

Every user-facing script (installer, uninstaller, `Check_Network_interfaces.bat`, `change_MTU_only.bat`) and the per-reconnect `ZeroTier_Fix.bat` self-re-execute through a PowerShell tee at the top, so the complete stdout/stderr stream of every run is mirrored both to the console (as before) **and** to `C:\zerotier_fix\run.log`. Each run is bracketed with `===== <script> run start =====` / `===== run end =====` timestamps. This is especially useful for the SYSTEM-context scheduled-task runs — those have no console at all, so without the tee any PowerShell error from inside the fix would be invisible. Before the first install the log goes to `%TEMP%\zerotier_fix_run.log` as fallback. The uninstaller's run is also captured (with a fallback to `%TEMP%` once `C:\zerotier_fix\` is deleted), so a failed uninstall is post-mortem-traceable too.

---

## ⚠️ Troubleshooting

- **First stop: `C:\zerotier_fix\run.log`.** Every script — installer, uninstaller, `Check_Network_interfaces.bat`, and every scheduled-task fire of `ZeroTier_Fix.bat` — appends its full stdout/stderr to this file with timestamped run start/end markers. If anything misbehaved, scroll back to the last `===== <script> run start =====` and read forward. PowerShell errors inside the SYSTEM-context fix only show up here.
- **Always run installer and diagnostic scripts as Administrator.** Anything that touches firewall, routing, or scheduled tasks needs elevation.
- **Can you ping the peer?** Find your ZT IP with `ipconfig`, then `ping <peer-zt-ip>`. If that fails, the fix is irrelevant — your ZT network itself isn't routing.
- **Is the connection DIRECT or RELAY?** See section 0 of `Check_Network_interfaces.bat`. RELAY means UDP port **9993** is blocked somewhere; open it on your router or check carrier-grade NAT.
- **Firewall blocking LAN traffic?** Manually verify Windows Defender / third-party firewall settings.
- **LAN discovery still broken?** Make sure broadcast/multicast routes exist on the ZeroTier Central side (see *Enable broadcast/multicast on the ZeroTier side* above) — the local fix only helps if the controller actually delivers the packets.
- **Old DirectPlay-era games specifically?** Re-run `install_zerotier_gaming_fix.bat` and accept the optional **WinIPBroadcast** prompt.
- **Last resort:** install [Npcap](https://npcap.com/). It enables raw packet capturing, which some games need to detect LAN sessions over virtual networks.
- **Want more control?** Self-host a ZeroTier controller with [ZTNET](https://ztnet.network/) — adjustable MTU, unlimited devices, full dashboard.

---

## 🎮 Gaming with Linux or macOS friends

On Linux and macOS, broadcast traffic is **not automatically routed over the ZeroTier adapter**. Each non-Windows peer needs to add a broadcast route manually.

### Linux

```sh
ip addr                    # find your ZT interface name, e.g. ztkseq3i6h
sudo route add -host 255.255.255.255 dev ztkseq3i6h
```

### macOS

```sh
ifconfig                   # find your ZT interface name
sudo route add -host 255.255.255.255 dev ztkseq3i6h
```

Replace `ztkseq3i6h` with your actual interface name.

---

## ❓ Why ZeroTier?

ZeroTier has a few real advantages over a typical VPN for LAN gaming:

- **Layer-2 networking.** Most VPN solutions operate at Layer 3; ZeroTier behaves like a virtual Ethernet, so broadcast and multicast actually work — which is exactly what game discovery needs.
- **Peer-to-peer first.** ZeroTier punches direct UDP connections between peers whenever it can, only falling back to relay servers when NAT traversal fails.
- **Reliable NAT traversal.** Notoriously fiddly for games. ZeroTier handles it well in most home-network configurations.
- **Cross-platform.** Windows, Linux, macOS, Android, iOS — everyone in the lobby can join.

---

## ❓ Does this disable IPv6 (or block ZeroTier from using IPv6)?

**No.** The only IPv6-related thing the fix does is set a Windows **prefix policy**:

```
netsh interface ipv6 set prefixpolicy ::ffff:0:0/96 100 4
```

That is RFC 6724 *destination-address selection* — it only affects how Windows picks between A and AAAA records when an application resolves a hostname that has both. Bumping `::ffff:0:0/96` to precedence 100 makes IPv4 win over native IPv6 for that selection step.

What it does **not** touch:

- **ZeroTier's underlay transport.** The UDP sockets ZT uses to reach peers and root servers over IPv6 (which is what makes peer-to-peer hole-punching dramatically more reliable on IPv6-capable networks) are completely unaffected. ZeroTier will continue to use IPv6 paths whenever both endpoints have IPv6 reachability.
- **The IPv6 stack on any adapter.** Nothing is disabled, no addresses are removed, no firewall rules are added. `Get-NetAdapterBinding -ComponentID ms_tcpip6` still shows IPv6 enabled on every adapter after install.
- **Native IPv6 destinations.** AAAA-only hostnames still resolve to IPv6 normally — the policy only re-orders the *IPv4-mapped* range relative to the default `::/0` entry.

The reason it's in there at all is application-level: a lot of LAN game-discovery and older title netcode is IPv4-only and gets confused when Windows hands them an IPv6 destination for a dual-stack hostname. The prefix policy nudges that selection back to IPv4 without ripping IPv6 out from under ZeroTier itself.

The uninstaller restores the original prefix-policy table from the backup file (`C:\zerotier_fix\prefix_policy_backup.txt`).

---

## ❓ Does the fix work without ZeroTier?

Partly. The adapter, firewall, and route fixes are useful on any Windows LAN setup that has broken multiplayer discovery — the script just looks for adapters whose description or alias contains "ZeroTier", so without those adapters most of the per-reconnect work simply doesn't run.

If you want the network-discovery and firewall improvements on a non-ZeroTier interface, you can adapt the filter in `ZeroTier_Fix.bat`. Run `Check_Network_interfaces.bat` first to see what's currently configured.

---

## 🤝 Contributing

Pull requests are welcome. If you spot a bug or have an improvement, fork the repo and open a PR. See [CHANGELOG.md](CHANGELOG.md) for the release history and what's been changed in each version.

---

## 🛑 Disclaimer

This software is provided **"as is"**, without any warranty. By running these scripts you agree that the author is **not responsible** for any damage, data loss, or instability that may result.

### ⚠️ Use at your own risk

- Modifying network settings, firewall rules, and Windows components can have **unintended side effects**.
- Enabling or disabling legacy features (DirectPlay) may affect **system compatibility**.
- Consider creating a **system restore point** before installing.

### 🚀 No liability

The author assumes no liability for:

- System crashes, malfunctions, or misconfigurations.
- Loss of network connectivity or application failures.
- Any other unintended behavior resulting from the use of these scripts.

If you are unsure, consult the official ZeroTier documentation or ask in a place with humans before running.

By running this script, you **acknowledge and accept** full responsibility for any changes made to your system.

---

### **🎮 Enjoy hassle-free LAN gaming with ZeroTier! 🚀**
