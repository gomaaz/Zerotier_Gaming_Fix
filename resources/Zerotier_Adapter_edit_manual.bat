@echo off
echo Running ZeroTier Network Setup...
echo.

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run this script as Administrator!
    pause
    exit /b
)

:: Set metric to 1 for all ZeroTier adapters
echo [INFO] Setting metric to 1 for all ZeroTier adapters...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetIPInterface | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | ForEach-Object { Set-NetIPInterface -InterfaceIndex $_.InterfaceIndex -InterfaceMetric 1 } }"

:: Set all ZeroTier networks to Private
echo [INFO] Setting all ZeroTier networks to Private...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetConnectionProfile | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | ForEach-Object { Set-NetConnectionProfile -Name $_.Name -NetworkCategory Private } }"

:: Detect all ZeroTier Interface Indexes and add broadcast route
echo [INFO] Detecting ZeroTier interface indexes...
for /f "tokens=1 delims=," %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetIPInterface | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | Select-Object -ExpandProperty InterfaceIndex}"') do (
    echo [INFO] Adding broadcast route for 255.255.255.255 via ZeroTier interface %%A...
    route -p add 255.255.255.255 mask 255.255.255.255 0.0.0.0 if %%A
)

:: Display settings for verification
echo.
echo ==============================================================
echo [VERIFICATION] Current settings for ZeroTier networks:
echo ==============================================================

echo [1] Network Adapter Metrics:
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetIPInterface | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | Select-Object InterfaceAlias, InterfaceIndex, AddressFamily, InterfaceMetric | Format-Table -AutoSize}"
echo.

echo [2] Network Profile of ZeroTier Connections:
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetConnectionProfile | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | Select-Object InterfaceAlias, Name, NetworkCategory | Format-Table -AutoSize}"
echo.

echo [3] Current Routing Table (Checking 255.255.255.255 Routes):
route print | findstr "255.255.255.255"
echo.

echo [DONE] Please verify the values above.
echo - The metric should be '1'.
echo - The network should be 'Private'.
echo - The broadcast route for 255.255.255.255 should be present for all ZeroTier interfaces.
echo ==============================================================
pause
exit
