@echo off
setlocal

if /i [%PROCESSOR_ARCHITECTURE%] EQU [AMD64] (set ARCH=x64) else (set ARCH=x86)

echo Running in %~dp0 with architecture %arch%
                                
set ASPNETCORE_ENVIRONMENT=Development
set ASPNETCORE_MODULE_DEBUG=console
set IIS_SITE_PATH=%~dp0
set ANCM_PATH=%~dp0ancmv2\%ARCH%\aspnetcore.dll
set ANCMV2_PATH=%~dp0ancmv2\%ARCH%\aspnetcorev2.dll
set LAUNCHER_PATH=dotnet.exe
set LAUNCHER_ARGS=%~dp0bin\debug\netcoreapp2.1\TestANCM.dll

start http://localhost:50690/

"%ProgramFiles%\IIS Express\iisexpress.exe" /config:"%~dp0ancmv2\IISExpress.config" /trace:error
