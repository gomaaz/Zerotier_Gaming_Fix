@echo off
echo [INFO] Installing ZeroTier Auto-Fix...

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run this script as Administrator!
    pause
    exit /b
)

:: Define source and target directories
set SOURCE_DIR=%~dp0resources
set TARGET_DIR=C:\zerotier_fix

:: Create the target directory if it doesn't exist
if not exist "%TARGET_DIR%" (
    mkdir "%TARGET_DIR%"
    echo [INFO] Created directory: %TARGET_DIR%
)

echo [INFO] Enabling DirectPlay (Legacy Component)...
dism /online /enable-feature /featurename:DirectPlay /all /NoRestart
echo [DONE] DirectPlay has been enabled!

:: Copy all necessary files
echo [INFO] Copying files to %TARGET_DIR%...
xcopy "%SOURCE_DIR%\*" "%TARGET_DIR%" /Y /E

:: Import and enable the scheduled task
echo [INFO] Installing scheduled task...
schtasks /create /tn "ZeroTier Auto Fix" /xml "%TARGET_DIR%\Check_ZeroTier_Connection_schedule.xml" /f

:: Start the task immediately
echo [INFO] Starting the task for the first time...
schtasks /run /tn "ZeroTier Auto Fix"

echo [DONE] Installation complete! ZeroTier Auto Fix is now running.
pause
exit
