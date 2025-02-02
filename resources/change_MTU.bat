@echo off
cls
set TARGET_DIR=C:\zerotier_fix
echo.
echo.
echo ==============================================================
echo Changing MTU Size of Controller
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