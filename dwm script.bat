@echo off
title DWM Script

echo Requesting Admin Permissions...
net session >nul 2>&1 && goto :winver
MSHTA "javascript: var shell = new ActiveXObject('shell.application'); shell.ShellExecute('%~nx0', '', '', 'runas', 1);close();"
exit /b

:winver
cls
for /f "tokens=4-6 delims=. " %%i in ('ver') do set VERSION1=%%i.%%j.%%k
if "%version1%" == "10.0.22000" goto start
if "%version1%" == "10.0.22621" goto start
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION2=%%i.%%j
if "%version2%" == "10.0" goto start
goto not_supported

:start
cls
color 1f
echo.
echo    /////////////////////////////////
echo   //  crustySenpai's DWM Script  //
echo  /////////////////////////////////
echo.
echo Standalone Script to disable the Desktop Window Manager
if "%version1%" == "10.0.22000" echo Current Windows Version: 11 (Supported)
if "%version1%" == "10.0.22621" echo Current Windows Version: 11 (Supported)
if "%version2%" == "10.0" echo Current Windows Version: 10 (Supported)
echo.
echo Welcome %username%!
echo.
echo Press any Key to start...
echo.
pause >nul
goto check

:check
echo.
echo Check for PSSuspend...
if exist "%~dp0\Tools\PSSuspend\pssuspend.exe" goto dwm_check
cls
echo.
echo Disabling DWM requires the Tool PSSuspend, do you want do download it now?
echo.
echo 0 = No / 1 = Yes
echo.
goto dwm_check_choice

:dwm_check_choice
set /p c=Select your Option: 
if "%c%"=="test" goto test_menu
if "%c%"=="0" cls & exit
if "%c%"=="1" goto dwm_download
if "%c%" GTR "1" dwm_check_choice

:dwm_download
cls
echo.
echo Downloading PSSuspend...
cd %~dp0
mkdir Tools\PSSuspend
powershell -Command "Start-BitsTransfer "https://live.sysinternals.com/pssuspend.exe" "Tools\PSSuspend""
cd C:\Windows\System32
cls
echo.
echo PSSuspend downloaded successfully!
goto check_dwm

:check_dwm
cls
echo.
echo Checking if dwm is running
tasklist|find "dwm.exe" >nul
if %errorlevel% == 0 goto disable
goto enable

:enable
cls
echo.
echo Enable DWM...
"%~dp0\Tools\PSSuspend\pssuspend.exe" -r winlogon.exe -nobanner >nul
start explorer.exe
start "" /D "C:\Program Files (x86)\Steam\steamapps\common\wallpaper_engine" "wallpaper32.exe"
echo Done!
echo.
echo You may now close the window or press any Key to disable DWM...
pause >nul
goto disable

:disable
cls
echo.
echo Disable DWM...
"%~dp0\Tools\PSSuspend\pssuspend.exe" winlogon.exe -nobanner
taskkill /F /IM "wallpaper32.exe"
taskkill /F /IM "explorer.exe"
taskkill /F /IM "dwm.exe"
taskkill /F /IM "SearchApp.exe"
taskkill /F /IM "TextInputHost.exe"
taskkill /F /IM "StartMenuExperienceHost.exe"
taskkill /F /IM "ShellExperienceHost.exe"
echo.
echo Done!
echo.
echo Press any Key to enable DWM...
pause >nul
goto enable

:not_supported
cls
echo.
echo Your current Windows Version isn't supported!
echo Please press any Key to continue...
pause >nul
goto exit