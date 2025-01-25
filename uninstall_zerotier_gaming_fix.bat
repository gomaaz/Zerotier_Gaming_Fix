@echo off
echo.
echo.
echo  8888P                   w   w               .d88b                 w                d8b w       
echo   dP  .d88b 8d8b .d8b. w8ww w .d88b 8d8b    8P www .d88 8d8b.d8b. w 8d8b. .d88     8'  w Yb dP 
echo  dP   8.dP' 8P   8' .8  8   8 8.dP' 8P      8b  d8 8  8 8P Y8P Y8 8 8P Y8 8  8    w8ww 8  `8.  
echo d8888 `Y88P 8    `Y8P'  Y8P 8 `Y88P 8       `Y88P' `Y88 8   8   8 8 8   8 `Y88     8   8 dP Yb 
echo                                                                           wwdP
echo.
echo.  

echo [INFO] Uninstalling ZeroTier Auto-Fix...

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run this script as Administrator!
    pause
    exit /b
)

echo.
echo.
echo ==============================================================
echo [INFO] Restore IPv6 prefix policies ...
echo ==============================================================
echo.
echo.
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

echo.
echo.
echo ==============================================================
echo [INFO] Deactivate DirectPlay...
echo ==============================================================
echo.
echo.


:: Remove DirectPlay
echo ==============================================================
echo [INFO] Disabling DirectPlay (Legacy Component)...
dism /online /disable-feature /featurename:DirectPlay /NoRestart
echo [DONE] DirectPlay has been disabled!

echo.
echo.
echo ==============================================================
echo [INFO] Stop and delete scheduled tasks...
echo ==============================================================
echo.
echo.

schtasks /delete /tn "ZeroTier Auto Fix" /f >nul 2>&1
schtasks /delete /tn "ZeroTier_PrioritizeIPv6" /f >nul 2>&1

:: Small delay to ensure the task is removed
timeout /t 2 /nobreak >nul

:: Remove read-only and hidden attributes
echo [INFO] Removing read-only attributes...
attrib -r -s -h C:\zerotier_fix\* /S /D >nul 2>&1

echo.
echo.
echo ==============================================================
echo [INFO] Deleting all files inside C:\zerotier_fix...
echo ==============================================================
echo.

del /F /Q "C:\zerotier_fix\*.*" >nul 2>&1

:: Wait a moment before deleting the folder
timeout /t 1 /nobreak >nul

rd /s /q C:\zerotier_fix >nul 2>&1

:: Wait before verification
timeout /t 2 /nobreak >nul

echo.
echo ==============================================================
echo [INFO] Verify deletion of files and folders...
echo ==============================================================
echo.
echo.
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
) else (
    echo [INFO] Folder deleted successfully: C:\zerotier_fix
)
echo.
echo.
echo [DONE] ZeroTier Auto Fix has been uninstalled successfully. IPv6 prefix policies have been restored.
echo.
echo.
echo Gaming is not wasting time, it's reliving those carefree days when the world was as simple as a game and joy came from just being.
echo.
echo.
pause
exit
