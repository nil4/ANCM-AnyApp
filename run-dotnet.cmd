@echo off
setlocal
call "%~dp0_init.cmd" DOTNET_PATH dotnet.exe

"%DOTNET_PATH%" build "%~dp0dotnet"

set ASPNETCORE_ENVIRONMENT=Development
set IIS_SITE_PATH=%~dp0dotnet
set LAUNCHER_PATH="%DOTNET_PATH%"
set LAUNCHER_ARGS="%~dp0dotnet\bin\Debug\netcoreapp2.1\TestANCM.dll"

start http://localhost:50690/

"%IISExpress%" /config:"%~dp0ancmv2_extra\IISExpress.config" /trace:error
