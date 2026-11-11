
@echo off
title STRAWBERRY WINDOWS Strawberry Setup

cd /d "%~dp0"

echo ========================================
echo    STRAWBERRY WINDOWS PORTABLE INSTALLER
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
    echo STRAWBERRY WINDOWS exited with an error.
    pause
)
