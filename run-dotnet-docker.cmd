@echo off
setlocal
call "%~dp0ancmv2_extra\init.cmd" DOCKER_PATH docker.exe

"%DOCKER_PATH%" build "%~dp0dotnet" -t "ancm-test-dotnet"

set ASPNETCORE_PORT=18000
set IIS_SITE_PATH=%~dp0docker
set LAUNCHER_PATH="%DOCKER_PATH%"
set LAUNCHER_ARGS=run --rm -p%ASPNETCORE_PORT%:80 --name "ancm-test-dotnet" ancm-test-dotnet

start http://localhost:50690/

"%IISExpress%" /config:"%~dp0IISExpress.config" /trace:error

echo.
echo Stopping container 'ancm-test-dotnet'
for /f "tokens=*" %%i in ('docker ps -aqf "name=ancm-test-dotnet"') do docker.exe stop %%i
