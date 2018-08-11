@echo off
setlocal
call "%~dp0_init.cmd" DOCKER_PATH docker.exe

"%DOCKER_PATH%" pull paddycarey/go-echo

set ASPNETCORE_PORT=18000
set IIS_SITE_PATH=%~dp0docker
set LAUNCHER_PATH="%DOCKER_PATH%"
set LAUNCHER_ARGS=run -i --rm -p%ASPNETCORE_PORT%:8000 --name "ancm-test" paddycarey/go-echo

start http://localhost:50690/

"%IISExpress%" /config:"%~dp0ancmv2_extra\IISExpress.config" /trace:error

echo.
echo Stopping container 'ancm-test'
for /f "tokens=*" %%i in ('docker ps -aqf "name=ancm-test"') do docker.exe stop %%i
