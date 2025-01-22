@echo off
echo [INFO] Uninstalling ZeroTier Auto-Fix...

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run this script as Administrator!
    pause
    exit /b
)

:: Stop and delete the scheduled task
echo [INFO] Removing scheduled task...
schtasks /delete /tn "ZeroTier Auto Fix" /f

:: Wait a moment before deleting files
timeout /t 3 /nobreak >nul

:: Remove the installation directory
set TARGET_DIR=C:\zerotier_fix
if exist "%TARGET_DIR%" (
    echo [INFO] Deleting %TARGET_DIR%...
    rmdir /s /q "%TARGET_DIR%"
)

echo [DONE] ZeroTier Auto Fix has been uninstalled.
pause
exit
