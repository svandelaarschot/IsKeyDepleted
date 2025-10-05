@echo off
echo Starting file watcher for IsKeyDepleted...
echo Press Ctrl+C to stop
echo.

:watch_loop
REM Check every 1 second for changes
timeout /t 1 /nobreak > nul

REM Sync all files to WoW folder
xcopy "D:\Development\IsKeyDepleted\*" "D:\WoW\Interface\AddOns\IsKeyDepleted\" /E /Y /I /Q

goto watch_loop
