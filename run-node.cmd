@echo off
setlocal
call "%~dp0ancmv2_extra\init.cmd" NODE_PATH node.exe

set IIS_SITE_PATH=%~dp0node
set LAUNCHER_PATH="%NODE_PATH%"
set LAUNCHER_ARGS="%~dp0node\server.js"

start http://localhost:50690/

"%IISExpress%" /config:"%~dp0IISExpress.config" /trace:error
