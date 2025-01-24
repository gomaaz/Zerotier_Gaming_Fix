@echo off
echo Fixing ZeroTier network settings...

setlocal
set BACKUP_FILE=C:\zerotier_fix\prefix_policy_backup.txt

:: Ensure backup folder exists
if not exist "C:\zerotier_fix" mkdir "C:\zerotier_fix"

:: Backup current IPv6 prefix policies
echo [INFO] Saving current IPv6 prefix policies to %BACKUP_FILE%...
(
    echo # Prefix Precedence Label
    netsh interface ipv6 show prefixpolicies | findstr "::" | sort
) > "%BACKUP_FILE%"

echo [DONE] IPv6 prefix policies saved successfully.


:: Set metric to 1 for all ZeroTier adapters
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetIPInterface | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | ForEach-Object { Set-NetIPInterface -InterfaceIndex $_.InterfaceIndex -InterfaceMetric 1 } }"

:: Set all ZeroTier networks to Private
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetConnectionProfile | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | ForEach-Object { Set-NetConnectionProfile -Name $_.Name -NetworkCategory Private } }"

:: Detect all ZeroTier Interface Indexes and add broadcast route
for /f "tokens=1 delims=," %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetIPInterface | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | Select-Object -ExpandProperty InterfaceIndex}"') do (
    echo [INFO] Adding broadcast route for 255.255.255.255 via ZeroTier interface %%A...
    route -p add 255.255.255.255 mask 255.255.255.255 0.0.0.0 if %%A
)

:: Prioritize IPv4 over IPv6 by setting ::ffff:0:0/96 prefix to 100
echo [INFO] Prioritizing IPv4 over IPv6...
netsh interface ipv6 set prefixpolicy ::ffff:0:0/96 100 4

:: Verify new prefix policy settings
echo [INFO] Checking prefix policies after modification...
netsh interface ipv6 show prefixpolicies

echo [DONE] ZeroTier network settings fixed! IPv4 is now prioritized.
exit
