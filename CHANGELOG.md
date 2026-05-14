# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and from `v2.1.1` onwards this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Tags from `v1.0` through `v2.1` predate the SemVer adoption and use a `vMAJOR.MINOR` scheme; `v2.1` is treated as the semantic equivalent of `v2.1.0`.

## [Unreleased]

### Added
- **`Check_Network_interfaces.bat` now ends with a compact pass/fail summary table.** A new helper script `resources/Check_Network_Summary.ps1` evaluates each of the diagnostic blocks (DirectPlay, ZT adapter metric, network category, IPv6 prefix policy, default-route cleanup on IPv4/IPv6, persistent broadcast route, scheduled-task `LastTaskResult`, optional WinIPBroadcast service) and prints a single `# | Section | Status | Details` table with overall `OK=/WARN=/FAIL=` counts. The user no longer has to scroll back through eight raw sections to know whether the fix is delivering — the verdict is on the screen right before the `pause`. Raw per-block output is unchanged.

### Fixed
- **`Check_Network_interfaces.bat` window closed immediately on exit on some setups.** After a `powershell.exe -File ...` call the Windows console-input buffer can hold a stray key event, which makes the subsequent `pause` return instantly and the window auto-close before the user has a chance to read the summary. The script now uses a hardened end-of-run wait (double `pause >nul`: the first absorbs any buffer leftover from PowerShell, the second blocks on a real keypress) together with an explicit "Druecken Sie eine beliebige Taste"-banner.

---

## [v2.4.2] – 2026-05-14

Documentation overhaul — no functional change to scripts. Also clarifies what "prioritizes IPv4 over IPv6" actually means (and does not mean), in response to issue [#2](https://github.com/gomaaz/Zerotier_Gaming_Fix/issues/2).

### Added
- **New FAQ entry "Does this disable IPv6 (or block ZeroTier from using IPv6)?"** in the README. Walks through what the `::ffff:0:0/96 100 4` prefix policy actually does (RFC 6724 host-side destination-address selection between A and AAAA records for dual-stack hostnames) versus what stays untouched (ZeroTier's UDP underlay over IPv6, the IPv6 stack itself, AAAA-only destinations). Direct response to [#2](https://github.com/gomaaz/Zerotier_Gaming_Fix/issues/2).

### Changed
- **README restructured end-to-end** to match the actual v2.4.x install behavior. New section flow: *What it fixes → Requirements → Installation → ZeroTier-side setup → Optional MTU → Updating → Uninstalling → Verifying → How it works → Troubleshooting → Linux/macOS peers → Q&A → Disclaimer.*
- **"What it fixes"** is now a two-column reference table (adapter metric, firewall profile, broadcast/multicast routes, IPv4 priority, DirectPlay, default-route cleanup, optional WinIPBroadcast, optional MTU). Replaces two duplicated feature lists from earlier versions.
- **IPv4-priority row in the *What it fixes* table** now names the mechanism (Windows prefix policy / RFC 6724) and explicitly states the fix does **not** disable IPv6 and does not affect ZeroTier's IPv6 underlay.
- **Installation section** now accurately lists every step the installer performs in v2.4.x: `version.txt`, `local.conf` backup, the WinIPBroadcast prompt, the MTU prompt, the scheduled task being run once at the end.
- **Uninstall section** now accurately lists every cleanup step: persistent-route deletion on every ZT adapter, `local.conf` restore from the most recent backup (or deletion), WinIPBroadcast service removal, scheduled-task removal, IPv6 prefix-policy restoration, DirectPlay disable.
- **"How it works" section** documents the Task Scheduler trigger (Network-Profile Event ID 10000), the SYSTEM-context execution, and the `run.log` per-reconnect trail.
- **"Verifying the fix" section** lists all eight diagnostic blocks of `Check_Network_interfaces.bat` (`[0]` DirectPlay … `[8]` WinIPBroadcast service status) with the expected output per block.
- **Optional MTU change** is now its own section with a verification ping example, rather than a single long paragraph buried inside Installation.
- **Multi-core / ZeroTier 1.16 note** is in its own subsection under Requirements, clearly stating that the staged setting is forward-compatible but inert on Windows today.
- Installer bumped to `ZGF_VERSION=2.4.2` so the installed `version.txt` matches the tag for users who download this release. (The constant was left at `2.4.0` through v2.4.1 by mistake.)

### Fixed
- Numerous README typos, broken bold markers, inconsistent capitalization (`windows`/`Windows`, `ipv4`/`IPv4`, `Directplay`/`DirectPlay`), stray trailing whitespace, and mixed bullet styles.

## [v2.4.1] – 2026-05-14

Documentation polish — no behavior changes, no script changes.

### Changed
- README features list rewritten to reflect what v2.4.0 actually does (multicast route, firewall rule groups, IPv4 prefix priority, optional WinIPBroadcast).
- New **Tested with** section names Windows 10/11 as the supported targets and ZeroTier 1.16.1 as the reference version. Mentions that the staged multi-core `local.conf` is forward-compatible but currently inert on Windows (Linux/FreeBSD-only upstream), plus 1.16 specifics: `encryptedHelloEnabled` flag and Network-Specific Relays.
- Troubleshooting section: WinIPBroadcast hint now points at the installer's optional step instead of a manual download.

### Fixed
- Several README typos and stray markdown artifacts (`doesnt` → `doesn't`, stray `(!)` punctuation, broken bold formatting around "prioritize IPv4").

## [v2.4.0] – 2026-05-14

Optional WinIPBroadcast integration — fills the LAN-discovery gap for legacy DirectPlay-based games (Age of Empires II, classic Command and Conquer, Quake-derived titles, Half-Life 1 mods, …) that Windows' own broadcast handling does not forward properly over virtual adapters. Re-running the installer is enough to opt in; v2.3.0 setups are unaffected if the prompt is declined.

### Added
- **Optional WinIPBroadcast 1.6 service install** in the installer (`install_zerotier_gaming_fix.bat`). Prompts the user, downloads the binary from the upstream GitHub release over TLS 1.2 to `%ProgramFiles%\WinIPBroadcast\`, and registers it as a Windows service via the upstream-supplied `WinIPBroadcast.exe install` subcommand. The download is fail-soft: a network error prints a manual-install hint and continues the rest of the install. Upstream license is GPL-3.0; the binary is downloaded at install time, not bundled with this repo.
- **Uninstaller now also removes the WinIPBroadcast service** via `WinIPBroadcast.exe remove` and deletes `%ProgramFiles%\WinIPBroadcast\`. Only acts on the standard install path so a separately-installed copy elsewhere is left untouched.
- **`Check_Network_interfaces.bat` shows the WinIPBroadcast service status** as a new section `[8]`.

## [v2.3.0] – 2026-05-14

Robustness, security, and operator-visibility improvements. No user-facing flow changes — re-running the installer drops the new scripts in place.

### Added
- **Installer reports its version and writes `C:\zerotier_fix\version.txt`.** Detects a prior installation and prints its version (or "pre-v2.3.0" if no version file exists), so re-running the installer as an updater is transparent.
- **`Check_Network_interfaces.bat` now also shows the scheduled-task status** (`LastRunTime`, `LastTaskResult`, `NextRunTime`) and tails the last six lines of `C:\zerotier_fix\run.log`, so problems with the per-reconnect fix can be diagnosed without leaving the diagnostic script.
- **Uninstaller cleans up state the previous versions left behind:** persistent broadcast (`255.255.255.255/32`) and multicast (`224.0.0.0/4`) routes on every ZT adapter are removed, and `%ProgramData%\ZeroTier\One\local.conf` is either restored from the most recent installer-written `local.conf.bak.*` or deleted if there was no backup.

### Changed
- **`ZeroTier_Fix.bat` detects ZeroTier adapters once and reuses the index list across all blocks.** Adapter detection now matches `InterfaceDescription` (vendor-set, stable) as well as the previously-used `InterfaceAlias` (user-renameable), so renamed adapters are no longer ignored. The script exits cleanly with a warning if no ZT adapters are present.
- **IPv6 prefix-policy backup no longer captures an already-modified state.** Skip the backup if the marker policy (`::ffff:0:0/96` with precedence 100) is already present, since that means the fix has run before.
- **`update_zerotier_mtu.ps1` rewritten:** input validation for network ID (16-hex) and MTU range (68..9000), `TimeoutSec`, structured error output with HTTP status codes.

### Security
- **`update_zerotier_mtu.ps1` reads the API token as a `SecureString`** and clears it from memory after the API call instead of holding it in plain text.
- **Auth header now uses ZeroTier's documented `Authorization: token <token>` scheme** instead of the previous lowercase `bearer` variant.
- **MTU update sends a PATCH-style `{config:{mtu:N}}` body** instead of round-tripping the entire network config object. Eliminates the risk of accidentally overwriting read-only fields and the race window where a concurrent change could be clobbered.

### Fixed
- **`Check_Network_interfaces.bat` now uses the absolute path to `zerotier-cli`** (`%ProgramFiles%\ZeroTier\One\zerotier-cli.bat`) with a `where`-based fallback. The previous bare `zerotier-cli` invocation failed under SYSTEM context or when `PATH` had not been refreshed after a ZeroTier upgrade.

## [v2.2.0] – 2026-05-14

Discovery boost, honesty about Windows multi-core support, hardened installer, and per-reconnect logging.

### Added
- **Multicast route `224.0.0.0/4` is now added on every ZeroTier adapter** alongside the existing broadcast route. Covers IGMP, SSDP, mDNS (`224.0.0.251`), and the multicast-based server-browser protocols used by Source-Engine titles, Minecraft LAN, Quake-derived games, and many lightweight indie titles.
- **Firewall rule groups `Network Discovery` and `File and Printer Sharing` are now explicitly enabled** for the Private profile on every reconnect. Switching the network category to Private alone left those rule groups dormant in many installs. Tries the locale-independent Firewall API Group IDs first, then English and German display names as fallback.
- **Per-reconnect run log at `C:\zerotier_fix\run.log`.** Every fire of the scheduled task appends a `run start` / `run end` line with a timestamp, so failures in the SYSTEM-context task are traceable after the fact (previously the task ran completely silent).
- **`local.conf` is backed up before being overwritten.** Installer now copies any existing `%ProgramData%\ZeroTier\One\local.conf` to `local.conf.bak.<yyyyMMdd-HHmmss>` before writing its own version, so user-defined settings (port, bind, custom roots, …) are recoverable.

### Changed
- **Multi-core config is now staged honestly.** As of ZeroTier 1.16.1, multi-core packet I/O is implemented only for Linux and FreeBSD — the Windows port is still pending upstream. The installer no longer claims that the setting activates anything on Windows; the section is renamed to "Pre-staging" and explains that the config is forward-compatible (effective once ZeroTier ships Windows multi-core support).
- **Installer no longer restarts the ZeroTier service** after writing `local.conf`. The restart caused a brief disconnect for no observable benefit on Windows, where the multi-core settings are inert anyway. A note is printed instead, showing the manual one-liner for users on a future ZT release that supports Windows MT.
- The first line printed by `ZeroTier_Fix.bat` no longer claims "IPv6 prioritization" — it never did that.

### Fixed
- **DirectPlay state detection.** The installer previously checked only against `State = Disabled`; the legitimate state `DisabledWithPayloadRemoved` (produced by a prior `dism /remove-feature`) was silently treated as enabled, so the feature was never re-installed. The check is now `-ne 'Enabled'`.

## [v2.1.1] – 2026-05-14

First SemVer release after the switch from the `vMAJOR.MINOR` scheme. Bugfix-only — no new functionality, no install/uninstall flow changes.

### Fixed
- **Default route is now removed on every ZeroTier adapter, not just the last one.** Previously a `for /f` loop in `ZeroTier_Fix.bat` overwrote `ZT_IF` on every iteration, so the `0.0.0.0/0` route deletion only ran against whichever adapter happened to come last. Users with multiple concurrent ZT networks would see ZT capture internet traffic on every adapter except one.

### Removed
- **Removed the `ZeroTier_PrioritizeIPv6` scheduled task and its helper script.** The task ran `netsh interface ipv6 set interface <idx> ignoredefaultroutes=disabled` on every logon, which directly contradicted the IPv4-prefix-priority set elsewhere in the same fix. Behavior was self-cancelling; the task is now dropped and existing installs are cleaned up automatically on the next reconnect (`schtasks /delete` + helper script deletion run as a no-op safe legacy cleanup).

## [v2.1] – 2025-02-10

### Added
- Automatic ZeroTier multithreading configuration: installer now writes `%ProgramData%\ZeroTier\One\local.conf` with `multicoreEnabled`, `concurrency` (= logical CPU core count) and `cpuPinningEnabled`, then restarts the `ZeroTierOneService`. _(Note: as of ZeroTier 1.16.1 the multi-core packet I/O is Linux/FreeBSD-only — the Windows port is still pending upstream. The setting is forward-compatible.)_
- Installer also copies the uninstaller into `C:\zerotier_fix` so the install location is fully self-contained.
- First external contribution merged (PR #1 by Tokisaki-Galaxy).

### Changed
- README documentation refined.

## [v2.0] – 2025-02-02

### Added
- New `resources/change_MTU.bat` standalone wrapper for running the MTU update without re-installing the fix.

### Changed
- `change_MTU.bat` renamed to `change_MTU_only.bat` to clarify intent.
- README expanded with MTU-tuning guidance and gaming considerations for Linux/macOS peers.

## [v1.9] – 2025-02-01

### Added
- New `resources/update_zerotier_mtu.ps1` — interactive PowerShell helper that calls the ZeroTier Central REST API (`https://api.zerotier.com/api/v1/network/{id}`) to set a per-network MTU (useful for lowering ZeroTier's default 2800 to a gaming-friendlier value like 1400).
- Installer now offers an optional MTU-change step at the end of the install flow.

### Changed
- Iterative improvements to installer, uninstaller, `ZeroTier_Fix.bat`, and `Check_Network_interfaces.bat`.

## [v1.8] – 2025-01-25

### Changed
- `Check_Network_interfaces.bat` diagnostic output refined for clearer expected-output hints per check block.
- README polish.

## [v1.7] – 2025-01-25

### Changed
- Substantial overhaul of the installer, uninstaller, `ZeroTier_Fix.bat`, and `Check_Network_interfaces.bat`. Behavior consolidated; output and error handling improved.

## [v1.6] – 2025-01-24

### Changed
- README rewritten and expanded.

## [v1.5] – 2025-01-24

### Changed
- Repository restructured: `resources/` directory introduced as the canonical location for the fix script, schedule XML, and helpers; uninstaller updated to match the new layout.

## [1.4] – 2025-01-23

> ⚠️ Tag created without the `v` prefix. Kept as-is for history; subsequent tags use `vX.Y.Z`.

### Changed
- Reworked `ZeroTier_Fix.bat` and updated README extensively.

## [v1.3] – 2025-01-23

### Changed
- Installer reset and reuploaded (previous version was removed and replaced).

## [v1.2] – 2025-01-22

### Changed
- Further refinement of `Check_ZeroTier_Connection_schedule.xml` (Task Scheduler event subscription).

## [v1.1] – 2025-01-22

### Changed
- Initial pass on the scheduled-task XML for the network-reconnect trigger.

## [v1.0] – 2025-01-22

### Added
- Initial public release: installer/uninstaller and the `resources/` payload (`ZeroTier_Fix.bat`, `Check_Network_interfaces.bat`, `Check_ZeroTier_Connection_schedule.xml`).
- Per-reconnect fix triggered by `Microsoft-Windows-NetworkProfile/Operational` EventID 10000:
  - Sets `InterfaceMetric = 1` on every `ZeroTier*` adapter.
  - Sets `NetworkCategory = Private` (firewall profile) on every ZT adapter.
  - Adds persistent host route for `255.255.255.255` to enable LAN broadcast discovery.
  - Prioritizes IPv4 over IPv6 via prefix policy `::ffff:0:0/96`.
  - Removes the `0.0.0.0/0` default route on ZT adapters so ZT doesn't capture internet traffic.

[Unreleased]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v2.4.2...HEAD
[v2.4.2]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v2.4.1...v2.4.2
[v2.4.1]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v2.4.0...v2.4.1
[v2.4.0]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v2.3.0...v2.4.0
[v2.3.0]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v2.2.0...v2.3.0
[v2.2.0]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v2.1.1...v2.2.0
[v2.1.1]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v2.1...v2.1.1
[v2.1]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v2.0...v2.1
[v2.0]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v1.9...v2.0
[v1.9]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v1.8...v1.9
[v1.8]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v1.7...v1.8
[v1.7]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v1.6...v1.7
[v1.6]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v1.5...v1.6
[v1.5]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/1.4...v1.5
[1.4]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v1.3...1.4
[v1.3]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v1.2...v1.3
[v1.2]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v1.1...v1.2
[v1.1]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v1.0...v1.1
[v1.0]: https://github.com/gomaaz/Zerotier_Gaming_Fix/releases/tag/v1.0
