@echo off
REM Build Rust library and run Flutter on Windows
setlocal enabledelayedexpansion

echo === Building Rust library ===
call rust\build_windows.bat
if %errorlevel% neq 0 exit /b %errorlevel%

set PATH=%CD%\rust\target\release;%PATH%

echo === Building and running Flutter Windows app ===
flutter run -d windows %*
