@echo off
echo Fixing ZeroTier network settings...


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

echo [DONE] ZeroTier network settings fixed!
exit
