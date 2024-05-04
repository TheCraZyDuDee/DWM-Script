@echo off
title DWM Script

:: requesting admin permissions
echo Requesting Admin Permissions...
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)

:: checking if the build number is higher than 19045 to see if it's 11 and less than 10240 for any os before 10
:winver
for /f "tokens=4-6 delims=. " %%i in ('ver') do set VERSION=%%i%%j%%k
if "%version%" GTR "10019045" (goto not_supported) else (set osver=Windows 10 - Supported)
if "%version%" LSS "10010240" goto not_supported

:start
color 1f
cd %~dp0
cls
echo.
echo    //////////////////////////////
echo   //  CraZyDuDe's DWM Script  //
echo  //////////////////////////////
echo.
echo Standalone Script to disable the Desktop Window Manager
echo.
echo Current OS: %osver%
echo Welcome %username%.
echo.
echo Press any Key to start...
echo.
pause >nul

:: check for pssuspend and if not found download it via BitsTransfer
cls
if exist "%~dp0\Tools\PSSuspend\pssuspend.exe" goto check
echo PSSuspend not found, downloading...
md Tools\PSSuspend
powershell -Command "Start-BitsTransfer "https://live.sysinternals.com/pssuspend.exe" "Tools\PSSuspend""

:: check for dwm running
:check
tasklist|find "dwm.exe" >nul
if %errorlevel% == 0 goto disable

:: resume winlogon and start explorer to enable dwm
:enable
cls
"Tools\PSSuspend\pssuspend.exe" -r winlogon.exe -nobanner >nul
start explorer
echo DWM enabled!
echo.
echo You may now close the window or press any Key to disable DWM...
pause >nul

:: freeze winlogon and then kill all nessesary tasks to disable dwm
:disable
cls
"Tools\PSSuspend\pssuspend.exe" winlogon.exe -nobanner
taskkill /F /IM "wallpaper32.exe"
taskkill /F /IM "explorer.exe"
taskkill /F /IM "dwm.exe"
taskkill /F /IM "SearchApp.exe"
taskkill /F /IM "TextInputHost.exe"
taskkill /F /IM "StartMenuExperienceHost.exe"
taskkill /F /IM "ShellExperienceHost.exe"
cls
echo.
echo DWM disabled!
echo.
echo Press any Key to enable DWM...
pause >nul
goto enable

:: prompts the user to exit since they are either below or above windows 10
:not_supported
cls
echo.
echo Your current Windows Version isn't supported!
echo Please press any Key to continue...
pause >nul
exit
