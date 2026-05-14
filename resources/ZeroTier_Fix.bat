@echo off
echo Fixing ZeroTier network settings for LAN gaming...

:: Ensure running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run this script as Administrator!
    pause
    exit /b
)

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

:: Detect all ZeroTier Interface Indexes and add broadcast route
for /f "tokens=1 delims=," %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetIPInterface | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | Select-Object -ExpandProperty InterfaceIndex}"') do (
    echo [INFO] Adding broadcast route for 255.255.255.255 via ZeroTier interface %%A...
    route -p add 255.255.255.255 mask 255.255.255.255 0.0.0.0 if %%A
)


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

echo [DONE] ZeroTier network settings updated.
exit
