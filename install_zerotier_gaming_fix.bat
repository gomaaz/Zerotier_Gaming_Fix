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


echo [INFO] Installing ZeroTier Auto-Fix...

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
REM Call PowerShell to check if DirectPlay is enabled
powershell -Command "$state = Get-WindowsOptionalFeature -Online -FeatureName DirectPlay | Select-Object -ExpandProperty State; if ($state -eq 'Disabled') { exit 1 } else { exit 0 }"

REM Check the result of PowerShell command
if %errorlevel% neq 0 (
    echo [INFO] DirectPlay is not enabled. Scheduling installation...
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


echo.
echo.
echo.
echo ==============================================================
echo [INFO] Enabling ZeroTier Multithreading...
echo ==============================================================
echo.
echo.

:: Get number of logical cores via PowerShell
for /f %%A in ('powershell -Command "(Get-CimInstance Win32_Processor).NumberOfLogicalProcessors"') do set CORES=%%A

:: Create ZeroTier config directory if missing
if not exist "%ProgramData%\ZeroTier\One" (
    mkdir "%ProgramData%\ZeroTier\One"
)

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

:: Restart ZeroTier service to apply changes
echo stop Zerotier Service
net stop ZeroTierOneService >nul 2>&1
echo start Zerotier Service
net start ZeroTierOneService >nul 2>&1
timeout /t 3 /nobreak >nul
echo.
:: Verify multithreading status
echo ==============================================================
echo [INFO] Verifying ZeroTier multithreading settings...
echo ==============================================================
powershell -Command "& {zerotier-cli info -j | ConvertFrom-Json | Select-Object @{Name='multicoreEnabled';Expression={$_.config.settings.multicoreEnabled}}, @{Name='concurrency';Expression={$_.config.settings.concurrency}}, @{Name='cpuPinningEnabled';Expression={$_.config.settings.cpuPinningEnabled}} | Format-List}"
echo If "config" shows "multicoreEnabled: true", multithreading is active!
echo Concurrency is the value taken with your max cores 
echo if needed you can adjust concurrency in C:\ProgramData\ZeroTier\One\local.conf
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
