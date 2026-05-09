@echo off
REM install_nanobot.bat — Windows batch launcher for PowerShell installer
REM Right-click and select "Run as administrator"

setlocal enabledelayedexpansion

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [ERROR] This script must run as Administrator.
    echo Please right-click cmd.exe or PowerShell and select "Run as administrator",
    echo then navigate to this folder and re-run this batch file.
    echo.
    pause
    exit /b 1
)

:: Get the directory where this script is located
set SCRIPT_DIR=%~dp0

:: Check if PowerShell script exists
if not exist "%SCRIPT_DIR%install_nanobot.ps1" (
    echo [ERROR] install_nanobot.ps1 not found in %SCRIPT_DIR%
    echo Make sure both files are in the same directory.
    pause
    exit /b 1
)

:: Run the PowerShell script with proper execution policy
echo.
echo [*] Starting nanobot Windows installer...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install_nanobot.ps1"

if !errorLevel! equ 0 (
    echo.
    echo [OK] Installation completed successfully.
    echo.
) else (
    echo.
    echo [ERROR] Installation failed with exit code !errorLevel!
    echo.
)

pause
