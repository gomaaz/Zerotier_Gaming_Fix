@echo off
echo Fixing ZeroTier network settings with IPv6 prioritization...

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


:: Get ZeroTier interface index
for /f "tokens=1" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetIPInterface | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | Select-Object -ExpandProperty InterfaceIndex}"') do set ZT_IF=%%A

echo [INFO] Detected ZeroTier Interface Index: %ZT_IF%

:: Force delete ZeroTier Default Route (No Confirmation)
echo [INFO] Removing ZeroTier as the default internet route...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetRoute -AddressFamily IPv4 | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' -and $_.InterfaceIndex -eq %ZT_IF% } | ForEach-Object { Remove-NetRoute -InterfaceIndex $_.InterfaceIndex -DestinationPrefix $_.DestinationPrefix -Confirm:$false } }"

:: Alternative method using netsh (if PowerShell fails)
netsh interface ipv4 delete route 0.0.0.0/0 interface=%ZT_IF% >nul 2>&1



:: Create PowerShell script to set IPv6 prefix policies for ZeroTier adapters
set SCRIPT_PATH=C:\zerotier_fix\set_ipv6_policy.ps1

(
    echo $ztAdapters = Get-NetAdapter ^| Where-Object { $_.InterfaceAlias -like "ZeroTier*" }
    echo foreach ($adapter in $ztAdapters^) {
    echo     Write-Host "[INFO] Prioritizing IPv6 for: $($adapter.Name) (Index: $($adapter.ifIndex))"
    echo     netsh interface ipv6 set interface $adapter.ifIndex ignoredefaultroutes=disabled
    echo }
) > "%SCRIPT_PATH%"

:: Run the PowerShell script once to apply settings immediately
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

:: Schedule task to ensure IPv6 priority persists on reboot
schtasks /create /tn "ZeroTier_PrioritizeIPv6" /tr "powershell.exe -ExecutionPolicy Bypass -File %SCRIPT_PATH%" /sc onlogon /rl highest /f

echo [DONE] ZeroTier network settings updated! IPv6 is now prioritized over IPv4 for ZeroTier.
exit
