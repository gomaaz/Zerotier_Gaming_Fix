@echo off

:: ================================================================
:: Tee-Wrapper: SYSTEM-Context-Lauf ohne Konsole - daher wuerden
:: stdout/stderr ungeloggt verfallen. Wir piping alles durch
:: PowerShell und schreiben es in run.log (mit Run-Header/Footer).
:: Da kein User-Input passiert (set /p etc.), gibt's keine
:: Pipe-Interaktivitaetsprobleme. Marker ZGF_TEE_ACTIVE verhindert
:: Endlos-Re-Exec.
:: ================================================================
if not defined ZGF_TEE_ACTIVE (
    set "ZGF_TEE_ACTIVE=1"
    set "LOGFILE=%~dp0run.log"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Content -Path $env:LOGFILE -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] ===== %~nx0 run start =====')"
    cmd /c ""%~f0"" 2>&1 | powershell -NoProfile -ExecutionPolicy Bypass -Command "$input | ForEach-Object { Write-Host $_; Add-Content -Path $env:LOGFILE -Value $_ }"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Content -Path $env:LOGFILE -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] ===== %~nx0 run end =====')"
    exit /b 0
)

echo Fixing ZeroTier network settings for LAN gaming...

:: Ensure running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run this script as Administrator!
    pause
    exit /b
)

echo [%date% %time%] ZeroTier_Fix.bat run start

:: Detect all ZeroTier adapter indexes once. Matches both InterfaceDescription
:: (vendor-set, stable) and InterfaceAlias (user-renameable) so renamed
:: adapters and unusual setups are still picked up. PowerShell emits the
:: indexes as a single comma-joined line that we can reuse for every
:: subsequent block.
:: We route the PS output through a temp file rather than `for /f` with
:: backticks: the latter requires cmd-escape (^|) for the PS pipes, and
:: that escape gets eaten one layer too early when this script is itself
:: invoked via cmd /c inside the tee wrapper. PowerShell then sees a
:: literal '^|' and bails with "Es wurde kein Positionsparameter
:: gefunden, der das Argument '^' akzeptiert.". The temp-file form puts
:: the pipes inside the quoted -Command string where cmd never tries to
:: parse them as a pipeline.
set "ZGF_IDX_TMP=%TEMP%\zgf_zt_idx.txt"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& {(Get-NetAdapter | Where-Object { $_.InterfaceDescription -like '*ZeroTier*' -or $_.InterfaceAlias -like 'ZeroTier*' } | Select-Object -ExpandProperty ifIndex) -join ','}" > "%ZGF_IDX_TMP%" 2>nul
set ZT_IDX=
if exist "%ZGF_IDX_TMP%" set /p ZT_IDX=<"%ZGF_IDX_TMP%"
del "%ZGF_IDX_TMP%" >nul 2>&1

if "%ZT_IDX%"=="" (
    echo [WARN] No ZeroTier adapters detected. Nothing to do.
    exit /b 0
)
echo [INFO] ZT adapter indexes: %ZT_IDX%

:: Back up IPv6 prefix policies before we first modify them. Skip the
:: backup if our marker (::ffff:0:0/96 with precedence 100) is already
:: present, otherwise we would be capturing a state we ourselves had
:: already changed.
set BACKUP_FILE=%~dp0prefix_policy_backup.txt
if not exist "%BACKUP_FILE%" (
    netsh interface ipv6 show prefixpolicies | findstr /C:"::ffff:0:0/96" | findstr "100" >nul
    if errorlevel 1 (
        echo [INFO] Saving current IPv6 prefix policies to %BACKUP_FILE%...
        netsh interface ipv6 show prefixpolicies > "%BACKUP_FILE%"
    ) else (
        echo [INFO] Existing ::ffff:0:0/96 prec=100 policy detected; skipping backup.
    )
)

:: Prioritize IPv4 over IPv6 by setting ::ffff:0:0/96 prefix to precedence 100.
echo [INFO] Prioritizing IPv4 over IPv6...
netsh interface ipv6 set prefixpolicy ::ffff:0:0/96 100 4

:: Set adapter metric for all ZeroTier adapters. AutomaticMetric must be
:: disabled together with the manual metric value, otherwise Windows
:: re-derives the metric from link speed on the next reconnect (~35 for
:: a 1 Gbps virtual adapter) and our value is silently overwritten.
::
:: Family-specific values:
::   IPv4 -> 1  (highest priority so LAN games prefer ZT over Ethernet/Wi-Fi)
::   IPv6 -> 20 (deliberately deprioritized; we want other adapters' IPv6
::               to win route selection over ZT's IPv6, since most LAN
::               game-discovery and older title netcode is IPv4-only.
::               20 is low-priority but not "off")
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {$idx=@(%ZT_IDX%); Get-NetIPInterface | Where-Object { $_.InterfaceIndex -in $idx } | ForEach-Object { $m = if ($_.AddressFamily -eq 'IPv6') { 20 } else { 1 }; Set-NetIPInterface -InterfaceIndex $_.InterfaceIndex -AddressFamily $_.AddressFamily -AutomaticMetric Disabled -InterfaceMetric $m -ErrorAction SilentlyContinue } }"

:: Set all ZeroTier connection profiles to Private (firewall profile).
:: Set-NetConnectionProfile writes the live category, but Windows' NLA
:: service often re-identifies ZeroTier-style virtual adapters as Public
:: on the next identification event (no domain membership, no DC-issued
:: DNS suffix). To make Private stick, we ALSO write Category=1 directly
:: into the saved profile under HKLM\NetworkList\Profiles, matched by
:: ProfileName — that is the on-disk value NLA reads back at reconnect.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {$idx=@(%ZT_IDX%); Get-NetConnectionProfile | Where-Object { $_.InterfaceIndex -in $idx } | ForEach-Object { Set-NetConnectionProfile -Name $_.Name -NetworkCategory Private -ErrorAction SilentlyContinue } }"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {$idx=@(%ZT_IDX%); $names=@(Get-NetConnectionProfile -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceIndex -in $idx } | Select-Object -ExpandProperty Name); if ($names.Count -gt 0) { Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles' -ErrorAction SilentlyContinue | ForEach-Object { $pn=(Get-ItemProperty -Path $_.PSPath -Name ProfileName -ErrorAction SilentlyContinue).ProfileName; if ($pn -and ($names -contains $pn)) { Set-ItemProperty -Path $_.PSPath -Name Category -Value 1 -ErrorAction SilentlyContinue } } } }"

:: Add LAN-discovery routes on every ZT adapter:
::   * 255.255.255.255/32 - classic LAN broadcast discovery
::   * 224.0.0.0/4        - full IPv4 multicast range (IGMP, SSDP,
::                          mDNS @ 224.0.0.251, server-browser protocols)
for %%A in (%ZT_IDX:,= %) do (
    echo [INFO] Adding broadcast route 255.255.255.255 on ZT Interface Index %%A...
    route -p add 255.255.255.255 mask 255.255.255.255 0.0.0.0 if %%A
    echo [INFO] Adding multicast route 224.0.0.0/4 on ZT Interface Index %%A...
    route -p add 224.0.0.0 mask 240.0.0.0 0.0.0.0 if %%A
)

:: Ensure LAN-discovery firewall rule groups are enabled for the Private
:: profile. Switching the network category to Private alone is not
:: enough - the rule groups themselves may have been turned off. Tries
:: the locale-independent Group ID first, then English and German display
:: names as fallback. Idempotent.
echo [INFO] Enabling LAN-discovery firewall rule groups (Network Discovery + File and Printer Sharing)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ids=@('@FirewallAPI.dll,-32752','@FirewallAPI.dll,-28502','Network Discovery','File and Printer Sharing','Netzwerkerkennung','Datei- und Druckerfreigabe'); foreach($id in $ids){$r=Get-NetFirewallRule -Group $id -ErrorAction SilentlyContinue; if(-not $r){$r=Get-NetFirewallRule -DisplayGroup $id -ErrorAction SilentlyContinue}; if($r){$r | Where-Object {$_.Profile -match 'Private|Any|All'} | Enable-NetFirewallRule -ErrorAction SilentlyContinue}}"

:: Force delete the 0.0.0.0/0 default route on EVERY ZT adapter so
:: ZeroTier does not capture internet traffic.
echo [INFO] Removing ZeroTier as the default internet route on all ZT adapters...
for %%A in (%ZT_IDX:,= %) do (
    echo [INFO] Removing default route on ZT Interface Index %%A...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "& {Get-NetRoute -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' -and $_.InterfaceIndex -eq %%A } | ForEach-Object { Remove-NetRoute -InterfaceIndex $_.InterfaceIndex -DestinationPrefix $_.DestinationPrefix -Confirm:$false -ErrorAction SilentlyContinue } }"
    netsh interface ipv4 delete route 0.0.0.0/0 interface=%%A >nul 2>&1
)

:: Legacy cleanup (<= v2.1): the old ZeroTier_PrioritizeIPv6 task and its
:: helper script contradicted the IPv4 prefix policy set above. Dropped
:: in v2.1.1. Safe no-op on fresh installs.
schtasks /delete /tn "ZeroTier_PrioritizeIPv6" /f >nul 2>&1
if exist "C:\zerotier_fix\set_ipv6_policy.ps1" del /F /Q "C:\zerotier_fix\set_ipv6_policy.ps1" >nul 2>&1

echo [%date% %time%] ZeroTier_Fix.bat run end
echo [DONE] ZeroTier network settings updated.

:: Explicit success exit so idempotent cleanups above (schtasks /delete
:: of a legacy task that does not exist on fresh installs -> errorlevel 1,
:: route -p add of an already-present route -> errorlevel 1, etc.) do
:: not bleed errorlevel into the scheduled-task LastTaskResult.
exit /b 0
