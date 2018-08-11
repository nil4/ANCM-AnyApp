@echo off
setlocal
call "%~dp0_init.cmd" WSL_PATH wsl.exe

set IIS_SITE_PATH=%~dp0python-wsl
set LAUNCHER_PATH=%WSL_PATH%
set LAUNCHER_ARGS=ASPNETCORE_PORT=18000 python/server.py

start http://localhost:50690/

"%IISExpress%" /config:"%~dp0ancmv2_extra\IISExpress.config" /trace:error

