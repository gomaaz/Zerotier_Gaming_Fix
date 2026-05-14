@echo off
echo Fixing ZeroTier network settings for LAN gaming...

:: Ensure running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run this script as Administrator!
    pause
    exit /b
)

:: Run log - appended on every fire of the scheduled task so failures are
:: traceable after the fact. SYSTEM-context runs have no console.
set LOGFILE=%~dp0run.log
echo. >> "%LOGFILE%"
echo [%date% %time%] ZeroTier_Fix.bat run start >> "%LOGFILE%"

:: Detect all ZeroTier adapter indexes once. Matches both InterfaceDescription
:: (vendor-set, stable) and InterfaceAlias (user-renameable) so renamed
:: adapters and unusual setups are still picked up. PowerShell emits the
:: indexes as a single comma-joined line that we can reuse for every
:: subsequent block.
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "& {(Get-NetAdapter ^| Where-Object { $_.InterfaceDescription -like '*ZeroTier*' -or $_.InterfaceAlias -like 'ZeroTier*' } ^| Select-Object -ExpandProperty ifIndex) -join ','}"`) do set ZT_IDX=%%I

if "%ZT_IDX%"=="" (
    echo [WARN] No ZeroTier adapters detected. Nothing to do.
    echo [%date% %time%] ZeroTier_Fix.bat: no ZT adapters found, exiting >> "%LOGFILE%"
    exit /b
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

:: Set metric to 1 for all ZeroTier adapters.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {$idx=@(%ZT_IDX%); Get-NetIPInterface | Where-Object { $_.InterfaceIndex -in $idx } | ForEach-Object { Set-NetIPInterface -InterfaceIndex $_.InterfaceIndex -InterfaceMetric 1 -ErrorAction SilentlyContinue } }"

:: Set all ZeroTier connection profiles to Private (firewall profile).
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {$idx=@(%ZT_IDX%); Get-NetConnectionProfile | Where-Object { $_.InterfaceIndex -in $idx } | ForEach-Object { Set-NetConnectionProfile -Name $_.Name -NetworkCategory Private -ErrorAction SilentlyContinue } }"

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

echo [%date% %time%] ZeroTier_Fix.bat run end >> "%LOGFILE%"
echo [DONE] ZeroTier network settings updated.
exit
