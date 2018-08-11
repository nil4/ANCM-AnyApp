@echo off
setlocal
call "%~dp0_init.cmd" PYTHON_PATH python.exe

set IIS_SITE_PATH=%~dp0python
set LAUNCHER_PATH=%PYTHON_PATH%
set LAUNCHER_ARGS="%~dp0python\server.py"

start http://localhost:50690/

"%IISExpress%" /config:"%~dp0ancmv2_extra\IISExpress.config" /trace:error

