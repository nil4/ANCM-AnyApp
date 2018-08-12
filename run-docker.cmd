@echo off
setlocal
call "%~dp0_init.cmd" DOCKER_PATH docker.exe

"%DOCKER_PATH%" run -i --rm -d --name "ancm-test" -p18000:8000 paddycarey/go-echo
if %ERRORLEVEL% NEQ 0 (
   exit /b 1
)

set IIS_SITE_PATH=%~dp0docker
set LAUNCHER_PATH="%DOCKER_PATH%"
set LAUNCHER_ARGS=attach --no-stdin "ancm-test"

start http://localhost:50690/

"%IISExpress%" /config:"%~dp0ancmv2_extra\IISExpress.config" /trace:error

echo.
echo Stopping container 'ancm-test'
for /f "tokens=*" %%i in ('docker ps -aqf "name=ancm-test"') do docker.exe rm -f %%i
