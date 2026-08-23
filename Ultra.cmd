@echo off
setlocal EnableExtensions EnableDelayedExpansion
title SoftTweak - FiveM Ultra Low Latency
color 0A

:: ============================================================
:: SoftTweak - FiveM Edition
:: Safe-first gaming / latency / smoothness toolkit
:: Run as Administrator.
:: Creates registry backups before applying changes.
:: ============================================================

set "APP=SoftTweak"
set "BACKUP=%~dp0SoftTweak_Backup"
set "LOG=%BACKUP%\SoftTweak.log"
set "FIVEM=%LocalAppData%\FiveM\FiveM.exe"

:: ---------- Admin check ----------
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo.
    echo [!] Please run this BAT as Administrator.
    echo     Right-click ^> Run as administrator
    pause
    exit /b 1
)

if not exist "%BACKUP%" md "%BACKUP%" >nul 2>&1
if not exist "%LOG%" echo SoftTweak log - %date% %time%>"%LOG%"

:: ---------- Detect OS ----------
for /f "tokens=2 delims==" %%A in ('wmic os get Caption /value 2^>nul') do set "OSNAME=%%A"
if not defined OSNAME set "OSNAME=Windows"

:: ---------- Detect GPU ----------
set "GPU=N/A"
for /f "tokens=2 delims==" %%A in ('wmic path win32_VideoController get Name /value 2^>nul') do (
    if not defined GPUDET set "GPUDET=%%A"
)
if defined GPUDET set "GPU=!GPUDET!"

set "GPUVENDOR=OTHER"
echo !GPU! | find /I "NVIDIA" >nul && set "GPUVENDOR=NVIDIA"
echo !GPU! | find /I "AMD" >nul && set "GPUVENDOR=AMD"
echo !GPU! | find /I "Radeon" >nul && set "GPUVENDOR=AMD"

:: ---------- Backup ----------
:BACKUP
set "STAMP=%date:~-4,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "STAMP=%STAMP: =0%"
set "BK=%BACKUP%\%STAMP%"
if not exist "%BK%" md "%BK%" >nul 2>&1

reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" "%BK%\GameDVR.reg" /y >nul 2>&1
reg export "HKCU\System\GameConfigStore" "%BK%\GameConfigStore.reg" /y >nul 2>&1
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "%BK%\VisualEffects.reg" /y >nul 2>&1
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "%BK%\Personalize.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "%BK%\GraphicsDrivers.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Control\Power" "%BK%\Power.reg" /y >nul 2>&1
powercfg /getactivescheme > "%BK%\PowerPlan.txt" 2>nul
netsh int tcp show global > "%BK%\TCP_Global.txt" 2>nul
netsh interface ipv4 show subinterfaces > "%BK%\IPv4_Interfaces.txt" 2>nul
echo Backup: %BK%>>"%LOG%"

:: ---------- Helpers ----------
:MAIN
cls
echo.
echo ============================================================
echo              SOFTTWEAK - FIVEM EDITION
echo ============================================================
echo.
echo  GPU     : %GPU%
echo  Vendor  : %GPUVENDOR%
echo  OS      : %OSNAME%
echo.
echo  [1] LOW LATENCY
echo  [2] PERFORMANCE / FPS
echo  [3] SAFE FULL BOOST
echo  [4] FULL SYSTEM
echo.
echo  [5] NETWORK OPTIMIZATION
echo  [6] WINDOWS SMOOTHNESS
echo  [7] CLEAN + REPAIR
echo  [8] FIVEM PROCESS OPTIMIZATION
echo.
echo  [9] CREATE BACKUP
echo  [R] RESTORE SAFE DEFAULTS
echo  [0] EXIT
echo.
set /p "CHOICE=Select: "

if /I "%CHOICE%"=="1" goto LOWLAT
if /I "%CHOICE%"=="2" goto FPS
if /I "%CHOICE%"=="3" goto SAFE
if /I "%CHOICE%"=="4" goto FULL
if /I "%CHOICE%"=="5" goto NETWORK
if /I "%CHOICE%"=="6" goto SMOOTH
if /I "%CHOICE%"=="7" goto CLEAN
if /I "%CHOICE%"=="8" goto FIVEM
if /I "%CHOICE%"=="9" goto BACKUP
if /I "%CHOICE%"=="R" goto RESTORE
if "%CHOICE%"=="0" exit /b 0
goto MAIN

:HEADER
cls
echo.
echo ============================================================
echo %~1
echo ============================================================
echo.
goto :eof

:: ============================================================
:: LOW LATENCY
:: ============================================================
:LOWLAT
call :HEADER "LOW LATENCY PRESET"
echo [1/18] Game Mode...
reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul

echo [2/18] Disable Game DVR capture...
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul

echo [3/18] Disable background Game DVR recording...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AudioCaptureEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v HistoricalCaptureEnabled /t REG_DWORD /d 0 /f >nul

echo [4/18] Reduce power throttling...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f >nul

echo [5/18] Multimedia gaming scheduling...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 10 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f >nul

echo [6/18] Gaming task profile...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v Priority /t REG_DWORD /d 6 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v Scheduling Category /t REG_SZ /d High /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d High /f >nul

echo [7/18] Disable fullscreen optimization for FiveM if installed...
if exist "%FIVEM%" reg add "HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%FIVEM%" /t REG_SZ /d "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" /f >nul

echo [8/18] Power plan...
powercfg /setactive SCHEME_MIN >nul 2>&1

echo [9/18] USB selective suspend off for active power plan...
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_USB USBSELECTIVE 0 >nul 2>&1
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_USB USBSELECTIVE 0 >nul 2>&1

echo [10/18] PCIe link state power saving off...
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_PCIEXPRESS ASPM 0 >nul 2>&1
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_PCIEXPRESS ASPM 0 >nul 2>&1

echo [11/18] Processor idle settings...
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 0 >nul 2>&1

echo [12/18] Refresh power plan...
powercfg /S SCHEME_CURRENT >nul 2>&1

echo [13/18] Flush DNS...
ipconfig /flushdns >nul 2>&1

echo [14/18] Reset Winsock catalog...
netsh winsock reset >nul 2>&1

echo [15/18] TCP autotuning normal...
netsh int tcp set global autotuninglevel=normal >nul 2>&1

echo [16/18] ECN default...
netsh int tcp set global ecncapability=default >nul 2>&1

echo [17/18] RSS enabled...
netsh int tcp set global rss=enabled >nul 2>&1

echo [18/18] Disable mouse acceleration...
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 0 /f >nul
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 0 /f >nul
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 0 /f >nul

echo.
echo DONE. Restart Windows before benchmarking FiveM.
pause
goto MAIN

:: ============================================================
:: FPS / PERFORMANCE
:: ============================================================
:FPS
call :HEADER "PERFORMANCE / FPS PRESET"
echo [1/20] Performance power plan...
powercfg /setactive SCHEME_MIN >nul 2>&1

echo [2/20] Disable power throttling...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f >nul

echo [3/20] Game Mode...
reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul

echo [4/20] Game DVR off...
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul

echo [5/20] System responsiveness...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 10 /f >nul

echo [6/20] Network throttling...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f >nul

echo [7/20] Games GPU priority...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul

echo [8/20] Games priority...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v Priority /t REG_DWORD /d 6 /f >nul

echo [9/20] Games scheduling...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d High /f >nul

echo [10/20] Games SFIO...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d High /f >nul

echo [11/20] Visual effects: performance...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul

echo [12/20] Disable transparency...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul

echo [13/20] Menu animation off...
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul

echo [14/20] Minimize/maximize animation off...
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul

echo [15/20] DNS cache flush...
ipconfig /flushdns >nul 2>&1

echo [16/20] TCP RSS...
netsh int tcp set global rss=enabled >nul 2>&1

echo [17/20] TCP autotuning...
netsh int tcp set global autotuninglevel=normal >nul 2>&1

echo [18/20] Clean user temp...
del /f /s /q "%TEMP%\*" >nul 2>&1

echo [19/20] Clean Windows temp...
del /f /s /q "%WINDIR%\Temp\*" >nul 2>&1

echo [20/20] Refresh explorer...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe

echo.
echo DONE. FPS gains depend on CPU/GPU load; this preset targets consistency too.
pause
goto MAIN

:: ============================================================
:: SAFE FULL BOOST
:: ============================================================
:SAFE
call :HEADER "SAFE FULL BOOST"
call :LOWLAT_RUN
call :FPS_RUN
call :NETWORK_RUN
call :SMOOTH_RUN
call :FIVEM_RUN
echo.
echo ============================================================
echo SAFE FULL BOOST COMPLETE
echo ============================================================
echo Restart Windows for the cleanest result.
pause
goto MAIN

:: Internal runners
:LOWLAT_RUN
powercfg /setactive SCHEME_MIN >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 10 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v Priority /t REG_DWORD /d 6 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d High /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d High /f >nul
exit /b

:FPS_RUN
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul
exit /b

:NETWORK_RUN
ipconfig /flushdns >nul 2>&1
netsh winsock reset >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global ecncapability=default >nul 2>&1
exit /b

:SMOOTH_RUN
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul
exit /b

:FIVEM_RUN
if exist "%FIVEM%" (
    reg add "HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%FIVEM%" /t REG_SZ /d "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" /f >nul
)
exit /b

:: ============================================================
:: FULL SYSTEM
:: ============================================================
:FULL
call :HEADER "FULL SYSTEM - SAFE MODE"
echo This mode applies all Safe Full Boost changes plus repair/cleanup.
echo.
choice /C YN /N /M "Continue? [Y/N]: "
if errorlevel 2 goto MAIN
call :SAFE_RUN
call :CLEAN_RUN
call :REPAIR_RUN
echo.
echo FULL SYSTEM COMPLETE.
echo A Windows restart is recommended.
pause
goto MAIN

:SAFE_RUN
call :LOWLAT_RUN
call :FPS_RUN
call :NETWORK_RUN
call :SMOOTH_RUN
call :FIVEM_RUN
exit /b

:: ============================================================
:: NETWORK
:: ============================================================
:NETWORK
call :HEADER "NETWORK OPTIMIZATION"
echo [1] Flush DNS
ipconfig /flushdns
echo.
echo [2] Winsock reset
netsh winsock reset
echo.
echo [3] TCP RSS
netsh int tcp set global rss=enabled
echo.
echo [4] TCP autotuning = normal
netsh int tcp set global autotuninglevel=normal
echo.
echo [5] ECN = default
netsh int tcp set global ecncapability=default
echo.
echo [6] TCP timestamps = default
netsh int tcp set global timestamps=default
echo.
echo [7] Show current TCP settings
netsh int tcp show global
echo.
echo [8] Show interfaces
netsh interface ipv4 show interfaces
echo.
echo Network optimization complete.
echo Note: BAT cannot lower ISP/server ping. It can only avoid local misconfiguration.
pause
goto MAIN

:: ============================================================
:: SMOOTHNESS
:: ============================================================
:SMOOTH
call :HEADER "WINDOWS SMOOTHNESS"
echo [1] Visual effects performance
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul

echo [2] Transparency off
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul

echo [3] Menu delay = 0
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul

echo [4] Window animation off
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul

echo [5] Taskbar animations off
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul

echo [6] Mouse acceleration off
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 0 /f >nul
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 0 /f >nul
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 0 /f >nul

echo.
echo Smoothness tweaks applied.
echo You may need to sign out/restart for all UI changes.
pause
goto MAIN

:: ============================================================
:: CLEAN + REPAIR
:: ============================================================
:CLEAN
call :HEADER "CLEAN + REPAIR"
call :CLEAN_RUN
call :REPAIR_RUN
echo.
echo Done.
pause
goto MAIN

:CLEAN_RUN
echo [1/8] User TEMP...
del /f /s /q "%TEMP%\*" >nul 2>&1

echo [2/8] Windows TEMP...
del /f /s /q "%WINDIR%\Temp\*" >nul 2>&1

echo [3/8] Windows Error Reporting cache...
del /f /s /q "%ProgramData%\Microsoft\Windows\WER\ReportArchive\*" >nul 2>&1

echo [4/8] DNS cache...
ipconfig /flushdns >nul 2>&1

echo [5/8] DirectX shader cache cleanup (user)...
del /f /s /q "%LocalAppData%\D3DSCache\*" >nul 2>&1

echo [6/8] NVIDIA DX cache cleanup if present...
if exist "%LocalAppData%\NVIDIA\DXCache" del /f /s /q "%LocalAppData%\NVIDIA\DXCache\*" >nul 2>&1

echo [7/8] AMD DX cache cleanup if present...
if exist "%LocalAppData%\AMD\DxCache" del /f /s /q "%LocalAppData%\AMD\DxCache\*" >nul 2>&1

echo [8/8] Empty recycle bin...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
exit /b

:REPAIR_RUN
echo [Repair 1/3] DISM health check...
DISM /Online /Cleanup-Image /CheckHealth

echo [Repair 2/3] DISM component scan...
DISM /Online /Cleanup-Image /ScanHealth

echo [Repair 3/3] System file check...
sfc /scannow
exit /b

:: ============================================================
:: FIVEM
:: ============================================================
:FIVEM
call :HEADER "FIVEM PROCESS OPTIMIZATION"
echo.
if not exist "%FIVEM%" (
    echo [!] FiveM.exe was not found at:
    echo     %FIVEM%
    echo.
    echo You can still use the other tweaks.
    pause
    goto MAIN
)

echo [1] Set FiveM compatibility flag...
reg add "HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%FIVEM%" /t REG_SZ /d "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" /f >nul

echo [2] Start FiveM with HIGH priority?
choice /C YN /N /M "Launch FiveM with HIGH priority now? [Y/N]: "
if errorlevel 2 goto MAIN

echo Starting FiveM...
start "" /HIGH "%FIVEM%"
echo.
echo FiveM started with HIGH priority.
echo NOTE: HIGH is intentional; REALTIME is not used because it can starve Windows.
pause
goto MAIN

:: ============================================================
:: RESTORE
:: ============================================================
:RESTORE
call :HEADER "RESTORE SAFE DEFAULTS"
echo This restores common Windows defaults for values changed by SoftTweak.
echo It does not restore third-party GPU driver control-panel settings.
echo.
choice /C YN /N /M "Continue? [Y/N]: "
if errorlevel 2 goto MAIN

echo Restoring Game DVR defaults...
reg delete "HKCU\System\GameConfigStore" /v GameDVR_Enabled /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AudioCaptureEnabled /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v HistoricalCaptureEnabled /f >nul 2>&1

echo Restoring Power Throttling policy...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /f >nul 2>&1

echo Restoring Multimedia values...
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /f >nul 2>&1

echo Restoring Games task values...
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v Priority /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /f >nul 2>&1

echo Restoring visual settings...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /f >nul 2>&1
reg delete "HKCU\Control Panel\Desktop" /v MenuShowDelay /f >nul 2>&1
reg delete "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /f >nul 2>&1

echo Restoring mouse acceleration defaults...
reg delete "HKCU\Control Panel\Mouse" /v MouseSpeed /f >nul 2>&1
reg delete "HKCU\Control Panel\Mouse" /v MouseThreshold1 /f >nul 2>&1
reg delete "HKCU\Control Panel\Mouse" /v MouseThreshold2 /f >nul 2>&1

echo Restoring TCP autotuning...
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global ecncapability=default >nul 2>&1
netsh int tcp set global timestamps=default >nul 2>&1
netsh int tcp set global rss=default >nul 2>&1

echo Restoring power plan to Balanced...
powercfg /setactive SCHEME_BALANCED >nul 2>&1

echo.
echo Restore completed.
echo For an exact registry restore, import the backup .reg files located in:
echo %BACKUP%
pause
goto MAIN

:: ============================================================
:: END
:: ============================================================