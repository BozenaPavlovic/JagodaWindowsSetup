
@echo off
title Pink Windows Strawberry Setup

cd /d "%~dp0"

echo ========================================
echo    PINK WINDOWS PORTABLE INSTALLER
echo ========================================
echo.

where powershell.exe >nul 2>&1

if errorlevel 1 (
    echo ERROR: Windows PowerShell not found.
    pause
    exit /b 1
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0START.ps1"

if errorlevel 1 (
    echo.
    echo Pink Windows exited with an error.
    pause
)
