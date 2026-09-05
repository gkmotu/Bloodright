@echo off
setlocal
title Bloodright Debug Launcher

cd /d "%~dp0"
set "BLOODRIGHT_GODOT="
set "BLOODRIGHT_PROJECT=%CD%"

for %%G in (godot_console.exe godot_console godot.exe godot) do (
    if not defined BLOODRIGHT_GODOT (
        for /f "delims=" %%P in ('where %%G 2^>nul') do set "BLOODRIGHT_GODOT=%%P"
    )
)

if not defined BLOODRIGHT_GODOT (
    for /r "%LOCALAPPDATA%\Microsoft\WinGet\Packages" %%P in (Godot_v*-stable_win64_console.exe) do (
        if not defined BLOODRIGHT_GODOT set "BLOODRIGHT_GODOT=%%P"
    )
)

if not defined BLOODRIGHT_GODOT (
    echo Godot could not be found.
    echo Install Godot 4, then run this launcher again.
    pause
    exit /b 1
)

echo Starting Bloodright in debug mode...
"%BLOODRIGHT_GODOT%" --path "%BLOODRIGHT_PROJECT%" --debug --maximized

if errorlevel 1 (
    echo.
    echo Bloodright stopped with an error. The details are shown above.
    pause
)
