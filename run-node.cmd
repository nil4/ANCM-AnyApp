@echo off
setlocal
call "%~dp0_init.cmd" NODE_PATH node.exe

set IIS_SITE_PATH=%~dp0node
set LAUNCHER_PATH="%NODE_PATH%"
set LAUNCHER_ARGS="%~dp0node\server.js"

start http://localhost:50690/

"%IISExpress%" /config:"%~dp0ancmv2_extra\IISExpress.config" /trace:error
