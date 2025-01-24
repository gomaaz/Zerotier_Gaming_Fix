@echo off
cls
echo Displaying network adapter metrics, firewall profiles, and IPv6 prefix policies...
echo.

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run this script as Administrator!
    pause
    exit /b
)



:: Display network adapter metrics
echo ==============================================================
echo [1] Network Adapter Metrics:
echo Expected Output (IPv4 should have lowest interfacemetric)
echo ==============================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetIPInterface | Select-Object InterfaceAlias, InterfaceIndex, AddressFamily, InterfaceMetric | Format-Table -AutoSize}"
echo.
echo.
echo.



:: Display firewall profiles (Private/Public)
echo ==============================================================
echo [2] Network Profiles:
echo Expected output: Zerotier networks are "private"
echo ==============================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetConnectionProfile | Select-Object InterfaceAlias, Name, NetworkCategory | Format-Table -AutoSize}"
echo.
echo.
echo.



:: Display IPv6 Prefix Policies
echo ==============================================================
echo [3] IPv6 Prefix Policies:
echo Expected Output ::ffff:0:0/96 should have highest priority 
echo ==============================================================
netsh interface ipv6 show prefixpolicies
echo.
echo.
echo.



:: Display IPv6 routes for ZeroTier adapters
echo ==============================================================
echo [4] Displaying IPv6 Routes for ZeroTier adapters...
echo Expected Output: No ::/0 default route for ZeroTier
echo ==============================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetRoute -AddressFamily IPv6 | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | Sort-Object RouteMetric | Format-Table -AutoSize}"
echo.
echo.
echo.



:: Display IPv4 routes for ZeroTier adapters
echo ==============================================================
echo [5] Displaying IPv4 Routes for ZeroTier adapters...
echo Expected Output: no 0.0.0.0/0 if internet routing is disabled
echo ==============================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetRoute -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like 'ZeroTier*' } | Sort-Object RouteMetric | Format-Table -AutoSize}"

echo.
echo.
echo ==============================================================
echo [DONE] Please check the values above.
echo ==============================================================
echo.
echo.
echo.
pause
