@echo off

:: ================================================================
:: Tee-Wrapper: alle stdout/stderr in run.log und auf Konsole.
:: Marker ZGF_TEE_ACTIVE verhindert Endlos-Re-Exec.
:: ================================================================
if not defined ZGF_TEE_ACTIVE (
    set "ZGF_TEE_ACTIVE=1"
    set "LOGFILE=C:\zerotier_fix\run.log"
    if not exist "C:\zerotier_fix" set "LOGFILE=%TEMP%\zerotier_fix_run.log"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Content -Path $env:LOGFILE -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] ===== %~nx0 run start =====')"
    cmd /c ""%~f0"" 2>&1 | powershell -NoProfile -ExecutionPolicy Bypass -Command "$input | ForEach-Object { Write-Host $_; Add-Content -Path $env:LOGFILE -Value $_ }"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Content -Path $env:LOGFILE -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] ===== %~nx0 run end =====')"
    exit /b
)

cls
set TARGET_DIR=C:\zerotier_fix
echo.
echo.
echo ==============================================================
echo Changing MTU Size of Controller
echo ==============================================================
echo.
echo If you are the network admin of the ZeroTier controller (my.zerotier.com),
echo you can change the MTU size to a self defined value, e.g. 1400. A lower MTU might be
echo better for gaming compared to the default ZeroTier MTU of 2800.
echo.
echo Requires: you OWN the network on my.zerotier.com and have an API
echo token (Account -^> API Access Tokens). The MTU endpoint is reachable
echo on every plan tier including free, but only network owners can call it.
echo If a 403 comes back, your token is for a different account than the
echo network owner.
echo.
echo If you self-host with ZTNET ^(https://ztnet.network/^), set the
echo network-wide MTU directly in the ZTNET dashboard instead - no API
echo token needed, and unlimited custom routes too (the free tier of
echo my.zerotier.com only allows one custom managed route as of late 2025).
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
echo Your choice:
set /p wantmtu=

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

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update_zerotier_mtu.ps1"

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
