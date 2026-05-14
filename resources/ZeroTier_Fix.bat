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

:: Define backup file path
set BACKUP_FILE=%~dp0prefix_policy_backup.txt

:: Check if backup already exists
if not exist "%BACKUP_FILE%" (
    echo [INFO] Saving current IPv6 prefix policies to %BACKUP_FILE%...
    netsh interface ipv6 show prefixpolicies > "%BACKUP_FILE%"
)



:: Prioritize IPv4 over IPv6 by setting ::ffff:0:0/96 prefix to 100
echo [INFO] Prioritizing IPv4 over IPv6...
netsh interface ipv6 set prefixpolicy ::ffff:0:0/96 100 4


:: Set metric to 1 for all ZeroTier adapters
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetIPInterface | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | ForEach-Object { Set-NetIPInterface -InterfaceIndex $_.InterfaceIndex -InterfaceMetric 1 } }"

:: Set all ZeroTier networks to Private
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetConnectionProfile | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | ForEach-Object { Set-NetConnectionProfile -Name $_.Name -NetworkCategory Private } }"

:: Detect all ZeroTier Interface Indexes and add LAN-discovery routes:
:: broadcast (255.255.255.255/32) for classic LAN discovery, and the full
:: IPv4 multicast range (224.0.0.0/4) for game-server browsers, mDNS,
:: SSDP, and similar protocols that older / lightweight game discovery
:: relies on.
for /f "tokens=1 delims=," %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetIPInterface | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | Select-Object -ExpandProperty InterfaceIndex -Unique}"') do (
    echo [INFO] Adding broadcast route 255.255.255.255 on ZT Interface Index %%A...
    route -p add 255.255.255.255 mask 255.255.255.255 0.0.0.0 if %%A
    echo [INFO] Adding multicast route 224.0.0.0/4 on ZT Interface Index %%A...
    route -p add 224.0.0.0 mask 240.0.0.0 0.0.0.0 if %%A
)

:: Ensure LAN-discovery firewall rule groups are enabled for the Private
:: profile. Switching the network category to Private (above) is not
:: enough on its own - the rule groups themselves may have been turned
:: off. Tries the locale-independent Group ID first, then English and
:: German display names as fallback. Idempotent.
echo [INFO] Enabling LAN-discovery firewall rule groups (Network Discovery + File and Printer Sharing)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ids=@('@FirewallAPI.dll,-32752','@FirewallAPI.dll,-28502','Network Discovery','File and Printer Sharing','Netzwerkerkennung','Datei- und Druckerfreigabe'); foreach($id in $ids){$r=Get-NetFirewallRule -Group $id -ErrorAction SilentlyContinue; if(-not $r){$r=Get-NetFirewallRule -DisplayGroup $id -ErrorAction SilentlyContinue}; if($r){$r | Where-Object {$_.Profile -match 'Private|Any|All'} | Enable-NetFirewallRule -ErrorAction SilentlyContinue}}"


:: Force delete the 0.0.0.0/0 default route on EVERY ZT adapter so ZeroTier
:: does not capture internet traffic. Iterates over all ZT adapters - the
:: pre-v2.1.1 version only handled the last one due to a for-loop bug.
echo [INFO] Removing ZeroTier as the default internet route on all ZT adapters...
for /f "tokens=1" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetIPInterface | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | Select-Object -ExpandProperty InterfaceIndex -Unique}"') do (
    echo [INFO] Removing default route on ZT Interface Index %%A...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "& {Get-NetRoute -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' -and $_.InterfaceIndex -eq %%A } | ForEach-Object { Remove-NetRoute -InterfaceIndex $_.InterfaceIndex -DestinationPrefix $_.DestinationPrefix -Confirm:$false -ErrorAction SilentlyContinue } }"
    netsh interface ipv4 delete route 0.0.0.0/0 interface=%%A >nul 2>&1
)

:: Legacy cleanup (<= v2.1): the old ZeroTier_PrioritizeIPv6 task and its
:: helper script contradicted the IPv4 prefix policy set above. Dropped in
:: v2.1.1. Safe no-op on fresh installs.
schtasks /delete /tn "ZeroTier_PrioritizeIPv6" /f >nul 2>&1
if exist "C:\zerotier_fix\set_ipv6_policy.ps1" del /F /Q "C:\zerotier_fix\set_ipv6_policy.ps1" >nul 2>&1

echo [%date% %time%] ZeroTier_Fix.bat run end >> "%LOGFILE%"
echo [DONE] ZeroTier network settings updated.
exit
