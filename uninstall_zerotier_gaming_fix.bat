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
schtasks /delete /tn "ZeroTier Auto Fix" /f >nul 2>&1

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


echo [DONE] ZeroTier Auto Fix has been uninstalled successfully.
pause
exit
