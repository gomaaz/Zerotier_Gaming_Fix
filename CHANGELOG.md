# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and from `v2.1.1` onwards this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Tags from `v1.0` through `v2.1` predate the SemVer adoption and use a `vMAJOR.MINOR` scheme; `v2.1` is treated as the semantic equivalent of `v2.1.0`.

## [Unreleased]

_Planned and in-progress changes will be listed here._

---

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

[Unreleased]: https://github.com/gomaaz/Zerotier_Gaming_Fix/compare/v2.1.1...HEAD
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
