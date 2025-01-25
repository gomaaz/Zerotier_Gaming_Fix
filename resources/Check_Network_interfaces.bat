@echo off
cls
echo.
echo.
echo  8888P                   w   w               .d88b                 w                d8b w       
echo   dP  .d88b 8d8b .d8b. w8ww w .d88b 8d8b    8P www .d88 8d8b.d8b. w 8d8b. .d88     8'  w Yb dP 
echo  dP   8.dP' 8P   8' .8  8   8 8.dP' 8P      8b  d8 8  8 8P Y8P Y8 8 8P Y8 8  8    w8ww 8  `8.  
echo d8888 `Y88P 8    `Y8P'  Y8P 8 `Y88P 8       `Y88P' `Y88 8   8   8 8 8   8 `Y88     8   8 dP Yb 
echo                                                                           wwdP
echo.
echo.  

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run this script as Administrator!
    pause
    exit /b
)


echo ==============================================================
echo [INFO] Checking ZeroTier Peer Connections...
echo ==============================================================

:: Run zerotier-cli peers and display output
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Start-Process -NoNewWindow -FilePath 'cmd.exe' -ArgumentList '/c zerotier-cli peers' -Wait}"

echo.
echo.
echo ==============================================================
echo [INFO] Explanation:
echo - "DIRECT"  = Good! Your peer is connected directly (low latency)
echo - "RELAY"   = Bad! Your peer is going through a relay (high latency)
echo - If relay, check if UDP Port 9993 is open in your router/firewall
echo ==============================================================
echo.
echo.
echo.


:: Check Direct Play Status
echo ==============================================================
echo [0] Direct Play Status
echo Expected Output State: Enabled
echo ==============================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "& {Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq 'DirectPlay' } | Format-Table FeatureName, State -AutoSize }"
echo.
echo.
echo.


:: Display network adapter metrics
echo ==============================================================
echo [1] Network Adapter Metrics:
echo Expected Output (Zerotier adapters should have lowest interfacemetric)
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
