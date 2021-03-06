@echo off

rem Detect CPU bitness

if /i [%PROCESSOR_ARCHITECTURE%] EQU [AMD64] (
    set ARCH=x64
) else (
    set ARCH=x86
)

rem Ensure IIS Express installed

set IISExpress=%ProgramFiles%\IIS Express\IISExpress.exe
if not exist "%IISExpress%" (
    echo.
    echo !!! OOPS !!! 
    echo. 
    echo Could not find IIS Express at "%IISExpress%"
    echo Please install it from: https://www.microsoft.com/en-us/download/details.aspx?id=48264
    exit 1
)

rem Ensure ANCM installed

if not exist "%ProgramFiles%\IIS Express\config\schema\aspnetcore_schema.xml" (
    echo.
    echo !!! OOPS !!! 
    echo. 
    echo Could not find the ANCM schema at "%ProgramFiles%\IIS Express\config\schema\aspnetcore_schema.xml"
    echo Please install the .NET Core 2.1 bundle from: https://www.microsoft.com/net/download/thank-you/dotnet-runtime-2.1.2-windows-hosting-bundle-installer
    exit 1
)


rem Ensure ANCM V2 and V2-extra schemas installed in IIS Express

setlocal

if not exist "%ProgramFiles%\IIS Express\config\schema\aspnetcore_schema_v2.xml" (
    set schema_missing=1
)
if not exist "%ProgramFiles%\IIS Express\config\schema\aspnetcore_schema_v2_extra.xml" (
    set schema_missing=1
)

if [%schema_missing%] neq [] (
    echo.
    echo !!! One-time setup needed !!!
    echo.
    echo IISExpress is not configured to understand the ANCM V2 Web.config schema, and 
    echo the extended schema used by this demo. Two files need to be copied to the
    echo folder "%ProgramFiles%\IIS Express\config\schema":
    echo - %~dp0aspnetcore_schema_v2.xml
    echo - %~dp0aspnetcore_schema_v2_extra.xml
    echo.
    echo Please open an elevated command prompt and run this command:
    echo.
    echo copy "%~dp0aspnetcore_schema*.xml" "%ProgramFiles%\IIS Express\config\schema"
    echo.
    exit 1
)

endlocal

rem Resolve executable to full path

if [%1%2] neq [] (
    if not exist "%~$PATH:2" (
        echo.
        echo !!! OOPS !!!
        echo.
        echo Could not find %2 in the PATH. Is it installed?
        exit 1
    )
    set "%~1=%~$PATH:2"
)

rem Set ANCM environment variables

set ANCM_PATH=%~dp0ancmv2_extra\%ARCH%\aspnetcore.dll
set ANCMV2_PATH=%~dp0ancmv2_extra\%ARCH%\aspnetcorev2.dll
set ASPNETCORE_MODULE_DEBUG=console
