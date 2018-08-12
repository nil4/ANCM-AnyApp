@echo off
setlocal
call "%~dp0_init.cmd" DOCKER_PATH docker.exe

"%DOCKER_PATH%" build "%~dp0dotnet" -t "ancm-test-dotnet"
if %ERRORLEVEL% NEQ 0 (
   exit /b 1
)

"%DOCKER_PATH%" run -i --rm -d --name "ancm-test-dotnet" -p18000:80 "ancm-test-dotnet"
if %ERRORLEVEL% NEQ 0 (
   exit /b 1
)

set IIS_SITE_PATH=%~dp0docker
set LAUNCHER_PATH="%DOCKER_PATH%"
set LAUNCHER_ARGS=attach --no-stdin "ancm-test-dotnet"

start http://localhost:50690/

"%IISExpress%" /config:"%~dp0ancmv2_extra\IISExpress.config" /trace:error

echo.
echo Stopping container 'ancm-test-dotnet'
for /f "tokens=*" %%i in ('docker ps -aqf "name=ancm-test-dotnet"') do docker.exe rm -f %%i
