@echo off
echo Displaying network adapter metrics and firewall profiles...
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
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetIPInterface | Select-Object InterfaceAlias, InterfaceIndex, AddressFamily, InterfaceMetric | Format-Table -AutoSize}"
echo.

:: Display firewall profiles (Private/Public)
echo ==============================================================
echo [2] Network Profiles:
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-NetConnectionProfile | Select-Object InterfaceAlias, Name, NetworkCategory | Format-Table -AutoSize}"
echo.

echo [DONE] Please check the values above.
echo ==============================================================
pause
exit
