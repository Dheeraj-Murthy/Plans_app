@echo off
REM Build Rust library for Windows
setlocal

echo Building Rust crate (release) for Windows...
cargo build --release --manifest-path "%~dp0Cargo.toml"
if %errorlevel% neq 0 exit /b %errorlevel%

echo DLL: %~dp0target\release\plans_core.dll
echo Done.
