@echo off
setlocal
title Bloodright Debug Launcher

cd /d "%~dp0"
set "BLOODRIGHT_GODOT="
set "BLOODRIGHT_PROJECT=%CD%"
set "BLOODRIGHT_UPDATED=0"
set "BLOODRIGHT_SYNCED=0"

if exist ".git" (
    echo Checking the verified Bloodright master build...
    git fetch --quiet origin main >nul 2>&1
    if errorlevel 1 (
        echo.
        echo Bloodright could not reach GitHub to verify master.
        echo The game will not start until the verified build can be checked.
        echo Check your connection, then run this launcher again.
        pause
        exit /b 1
    )
    for /f %%H in ('git rev-parse HEAD') do set "BLOODRIGHT_LOCAL=%%H"
    for /f %%H in ('git rev-parse origin/main') do set "BLOODRIGHT_REMOTE=%%H"
    if not "%BLOODRIGHT_LOCAL%"=="%BLOODRIGHT_REMOTE%" set "BLOODRIGHT_UPDATED=1"

    rem Preserve a recoverable snapshot before master becomes the active workspace.
    git diff --quiet
    if errorlevel 1 git stash push --include-untracked --quiet -m "Bloodright automatic pre-master sync"

    git reset --hard --quiet origin/main >nul 2>&1
    if errorlevel 1 (
        echo.
        echo Bloodright could not install the verified master build.
        pause
        exit /b 1
    )
    set "BLOODRIGHT_SYNCED=1"
)

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
