@echo off
echo [INFO] Uninstalling ZeroTier Auto-Fix...

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run this script as Administrator!
    pause
    exit /b
)

:: Restore IPv6 Prefix Policies if backup exists
set BACKUP_FILE=C:\zerotier_fix\prefix_policy_backup.txt

if exist "%BACKUP_FILE%" (
    echo [INFO] Restoring saved IPv6 prefix policies...
    
    :: Read and restore prefix policy, skipping the first header line
    for /f "skip=1 tokens=1,2,3 delims= " %%A in (%BACKUP_FILE%) do (
        echo Restoring: netsh interface ipv6 set prefixpolicy %%C %%A %%B
        netsh interface ipv6 set prefixpolicy %%C %%A %%B
    )

    echo [INFO] Prefix policies restored successfully.
) else (
    echo [WARNING] No backup file found. Skipping prefix policy restore.
)

:: Remove DirectPlay
echo ==============================================================
echo [INFO] Disabling DirectPlay (Legacy Component)...
dism /online /disable-feature /featurename:DirectPlay /NoRestart
echo [DONE] DirectPlay has been disabled!

:: Stop and delete the scheduled task
echo [INFO] Removing scheduled task...
schtasks /delete /tn "ZeroTier Auto Fix" /f >nul 2>&1
schtasks /delete /tn "ZeroTier_PrioritizeIPv6" /f >nul 2>&1

:: Small delay to ensure the task is removed
timeout /t 2 /nobreak >nul

:: Remove read-only and hidden attributes
echo [INFO] Removing read-only attributes...
attrib -r -s -h C:\zerotier_fix\* /S /D >nul 2>&1

:: Force delete all files inside the folder
echo [INFO] Deleting all files inside C:\zerotier_fix...
del /F /Q "C:\zerotier_fix\*.*" >nul 2>&1

:: Wait a moment before deleting the folder
timeout /t 1 /nobreak >nul

:: Try deleting the folder
echo [INFO] Removing C:\zerotier_fix...
rd /s /q C:\zerotier_fix >nul 2>&1

:: Wait before verification
timeout /t 2 /nobreak >nul

:: Verify if the folder is deleted
if exist "C:\zerotier_fix" (
    echo [ERROR] The folder C:\zerotier_fix could not be deleted.
    echo Possible reasons:
    echo - A program is still using it.
    echo - Windows is preventing its removal.
    echo - Insufficient permissions.
    echo.
    echo [SOLUTION] Try restarting your PC and running this uninstaller again.
    pause
    exit /b
)

echo [DONE] ZeroTier Auto Fix has been uninstalled successfully. IPv6 prefix policies have been restored.
pause
exit
