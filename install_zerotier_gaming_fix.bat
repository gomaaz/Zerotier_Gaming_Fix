@echo off
cls

:: Version of this installer. Keep in sync with CHANGELOG.md and the git tag.
set ZGF_VERSION=2.4.2

echo.
echo.
echo  8888P                   w   w               .d88b                 w                d8b w
echo   dP  .d88b 8d8b .d8b. w8ww w .d88b 8d8b    8P www .d88 8d8b.d8b. w 8d8b. .d88     8'  w Yb dP
echo  dP   8.dP' 8P   8' .8  8   8 8.dP' 8P      8b  d8 8  8 8P Y8P Y8 8 8P Y8 8  8    w8ww 8  `8.
echo d8888 `Y88P 8    `Y8P'  Y8P 8 `Y88P 8       `Y88P' `Y88 8   8   8 8 8   8 `Y88     8   8 dP Yb
echo                                                                           wwdP
echo                                                       v%ZGF_VERSION%
echo.
echo.


echo [INFO] Installing ZeroTier Auto-Fix v%ZGF_VERSION%...
:: Detect a prior installation and report its version, so re-running the
:: installer as an updater is transparent.
if exist "C:\zerotier_fix\version.txt" (
    for /f "delims=" %%V in (C:\zerotier_fix\version.txt) do set PREV_VERSION=%%V
    echo [INFO] Previous installation detected: v%PREV_VERSION%
) else if exist "C:\zerotier_fix\ZeroTier_Fix.bat" (
    echo [INFO] Previous installation detected ^(version unknown, pre-v2.3.0^)
)

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run this script as Administrator!
    pause
    exit /b
)

echo.
echo. 
:: Define source and target directories
set SOURCE_DIR=%~dp0resources
set TARGET_DIR=C:\zerotier_fix

echo ==============================================================
echo [INFO] Create Directory on C:
echo ==============================================================
echo.
:: Create the target directory if it doesn't exist
if not exist "%TARGET_DIR%" (
    mkdir "%TARGET_DIR%"
    echo [INFO] Created directory: %TARGET_DIR%
) else (
    echo [INFO] Directory exists already: %TARGET_DIR%
)
echo.
echo.
echo ==============================================================
echo [INFO] Enabling DirectPlay (Legacy Component)...
echo ==============================================================
echo.
echo.
REM Call PowerShell to check if DirectPlay is in any non-Enabled state.
REM Covers 'Disabled' and 'DisabledWithPayloadRemoved' (the latter occurred
REM after a prior dism /remove-feature and was missed by older versions).
powershell -Command "$state = Get-WindowsOptionalFeature -Online -FeatureName DirectPlay | Select-Object -ExpandProperty State; if ($state -ne 'Enabled') { exit 1 } else { exit 0 }"

REM Check the result of PowerShell command
if %errorlevel% neq 0 (
    echo [INFO] DirectPlay is not enabled. Enabling now...
    powershell -Command "Enable-WindowsOptionalFeature -Online -FeatureName DirectPlay -All"
    echo.
    echo [DONE] DirectPlay has been enabled!
) else (
    echo [INFO] DirectPlay is already enabled.
)

echo.
echo.
echo ==============================================================
echo [INFO] Copying Files to %TARGET_DIR% ...
echo ==============================================================
echo.
echo.
xcopy "%SOURCE_DIR%\*" "%TARGET_DIR%" /Y /E
xcopy "%SOURCE_DIR%\..\uninstall_zerotier_gaming_fix.bat" "%TARGET_DIR%" /Y

:: Write the installed version so future re-runs / diagnostics know what's there.
echo %ZGF_VERSION%> "%TARGET_DIR%\version.txt"


echo.
echo.
echo.
echo ==============================================================
echo [INFO] Pre-staging ZeroTier multi-core config (local.conf)...
echo ==============================================================
echo.
echo NOTE: As of ZeroTier 1.16.1, multi-core packet I/O is implemented
echo       only for Linux and FreeBSD. The Windows port is still pending
echo       upstream (see https://docs.zerotier.com/multithreading/).
echo       The local.conf written below is forward-compatible: once
echo       ZeroTier ships Windows multi-core support, the settings take
echo       effect automatically on the next service start.
echo.

:: Get number of logical cores via PowerShell
for /f %%A in ('powershell -Command "(Get-CimInstance Win32_Processor).NumberOfLogicalProcessors"') do set CORES=%%A

:: Create ZeroTier config directory if missing
if not exist "%ProgramData%\ZeroTier\One" (
    mkdir "%ProgramData%\ZeroTier\One"
)

:: Back up existing local.conf with a timestamped name before overwriting,
:: so user-defined settings (port, bind, custom roots, ...) can be restored.
powershell -NoProfile -Command "$conf = Join-Path $env:ProgramData 'ZeroTier\One\local.conf'; if (Test-Path $conf) { $ts = Get-Date -Format 'yyyyMMdd-HHmmss'; Copy-Item $conf ($conf + '.bak.' + $ts) -Force; Write-Host ('[INFO] Existing local.conf backed up to local.conf.bak.' + $ts) } else { Write-Host '[INFO] No existing local.conf to back up.' }"

:: Generate local.conf with dynamic core count
(
    echo {
    echo    "settings":
    echo    {
    echo        "multicoreEnabled": true,
    echo        "concurrency": %CORES%,
    echo        "cpuPinningEnabled": true
    echo    }
    echo }
) > "%ProgramData%\ZeroTier\One\local.conf"

echo [INFO] Wrote %ProgramData%\ZeroTier\One\local.conf (concurrency=%CORES%).
echo.
echo To activate the settings on a future Windows multi-core release, run:
echo     net stop ZeroTierOneService ^&^& net start ZeroTierOneService
echo.
echo (Skipped automatically here - restarting the service today would only
echo  cause a brief disconnect with no effective change on Windows.)
echo.
echo.
echo.
echo ==============================================================
echo [INFO] Installing scheduled task...
echo ==============================================================
echo.
echo.
schtasks /create /tn "ZeroTier Auto Fix" /xml "%TARGET_DIR%\Check_ZeroTier_Connection_schedule.xml" /f
echo.
echo.
echo ==============================================================
echo [INFO] Starting the task for the first time...
echo ==============================================================
echo.
echo.
schtasks /run /tn "ZeroTier Auto Fix"
echo.
echo.
echo ==============================================================
echo [INFO] Installation complete! ZeroTier Auto Fix is now running.
echo ==============================================================
echo.
echo You can check if network settings are met in 
echo C:/zerotier_fix/resources/Check_Network_interfaces.bat
echo right click -> execute with admin rights.
echo.
echo.
echo.
echo ==============================================================
echo [Optional] WinIPBroadcast - extended LAN discovery for older games
echo ==============================================================
echo.
echo Some older games (DirectPlay-based: Age of Empires II, classic
echo Command and Conquer, Quake 3 derivatives, Half-Life 1 mods, ...)
echo rely on LAN discovery that Windows' own broadcast handling does
echo not fully forward over virtual adapters like ZeroTier. WinIPBroadcast
echo is a small open-source helper that rebroadcasts IP broadcasts
echo across all interfaces and is the recommended fallback per the
echo README.
echo.
echo   Source : https://github.com/dechamps/WinIPBroadcast
echo   License: GPL-3.0
echo   Size   : about 1 MB, idle CPU usage is zero
echo.
echo Requires an internet connection for the one-time download.
echo Skip this if your games already work without it, or if you prefer
echo not to install third-party services.
echo.
set /p wantwib=Install WinIPBroadcast as a service? (y/n):

if /i "%wantwib%"=="y"   goto INSTALLWIB
if /i "%wantwib%"=="yes" goto INSTALLWIB
echo You answered no. Skipping WinIPBroadcast.
goto SKIPWIB

:INSTALLWIB
set WIB_VERSION=1.6
set WIB_URL=https://github.com/dechamps/WinIPBroadcast/releases/download/winipbroadcast-%WIB_VERSION%/WinIPBroadcast.exe
set WIB_DIR=%ProgramFiles%\WinIPBroadcast
set WIB_EXE=%WIB_DIR%\WinIPBroadcast.exe

if not exist "%WIB_DIR%" mkdir "%WIB_DIR%"

echo [INFO] Downloading WinIPBroadcast %WIB_VERSION% from GitHub...
powershell -NoProfile -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%WIB_URL%' -OutFile '%WIB_EXE%' -UseBasicParsing -TimeoutSec 30; if ((Get-Item '%WIB_EXE%').Length -lt 1024) { throw 'Downloaded file is suspiciously small.' }; Write-Host '[INFO] Downloaded WinIPBroadcast.exe' ((Get-Item '%WIB_EXE%').Length) 'bytes.' } catch { Write-Host '[ERROR] Download failed:' $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo [WARN] Could not download WinIPBroadcast. Skipping service install.
    echo        You can install it manually later: download from the URL above,
    echo        place it in %WIB_DIR%, then run "WinIPBroadcast.exe install".
    goto SKIPWIB
)

echo [INFO] Installing WinIPBroadcast service...
"%WIB_EXE%" install
if errorlevel 1 (
    echo [WARN] WinIPBroadcast service install reported a non-zero exit code.
    echo        It may already be installed - check with: sc query WinIPBroadcast
) else (
    echo [DONE] WinIPBroadcast service installed and started.
)

:SKIPWIB
echo.
echo.
echo ==============================================================
echo [Optional] Optional Part - Changing MTU Size of Controller
echo ==============================================================
echo.
echo If you are the network admin of the ZeroTier controller (my.zerotier.com),
echo you can change the MTU size to a self defined value,f.e. 1400. A lower MTU might be
echo better for gaming compared to the default ZeroTier MTU of 2800.
echo.
echo Please note: These changes will be applied on-the-fly to all adapters
echo within the ZeroTier network. This MTU setting is a maximum allowed
echo packet size before fragmentation occurs. Many games will adapt their
echo packet size based on the MTU of the operating system or network adapter,
echo although some games choose their own packet sizes independently.
echo.
echo Decide carefully before making any changes, as it may affect
echo network performance and connectivity.
echo.
echo.
echo.
echo Would you like to change MTU Size now? You need to be network admin (y/n)
set /p wantmtu=Your choice:

:: Check if user typed "y" or "yes"
if /i "%wantmtu%"=="y"   goto CHANGEMTU
if /i "%wantmtu%"=="yes" goto CHANGEMTU


:: If not "y" or "yes", go directly to totheend
echo You answered no. The critical part will be skipped.
goto TOTHEEND

:CHANGEMTU
echo.
echo.
echo ==============================================================
echo Starting MTU Change Program
echo ==============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%TARGET_DIR%\update_zerotier_mtu.ps1"

echo.
echo.
echo.
echo.
:TOTHEEND
echo.
echo.
echo.
echo dP                                                                           oo                   
echo 88                                                                                                
echo 88d888b. .d8888b. 88d888b. 88d888b. dP    dP    .d8888b. .d8888b. 88d8b.d8b. dP 88d888b. .d8888b. 
echo 88'  `88 88'  `88 88'  `88 88'  `88 88    88    88'  `88 88'  `88 88'`88'`88 88 88'  `88 88'  `88 
echo 88    88 88.  .88 88.  .88 88.  .88 88.  .88    88.  .88 88.  .88 88  88  88 88 88    88 88.  .88 
echo dP    dP `88888P8 88Y888P' 88Y888P' `8888P88    `8888P88 `88888P8 dP  dP  dP dP dP    dP `8888P88 
echo                   88       88            .88         .88                                      .88 
echo                   dP       dP        d8888P      d8888P                                   d8888P
echo.
echo.
echo.
echo Gaming is not wasting time, it's reliving those carefree days when the world was as simple as a game and joy came from just being.
echo.
echo.
echo.
pause
exit
