@echo off
:: Disable command echoing
setlocal enabledelayedexpansion

:: Check the path of Nmap
set nmap_path=nmap
%nmap_path% --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Nmap não encontrado. Por favor, instale-o e adicione ao PATH.
    pause
    exit /b
)

:: Create the logs directory if it doesn't exist
if not exist "%~dp0MetaData.logs" (
    mkdir "%~dp0MetaData.logs"
)

:Menu
echo.
echo ============================
echo 1. scan-net
echo 2. save-metadata
echo 3. exit
echo ============================
set /p choice="Choose an option (1-3): "

if "%choice%"=="1" (
    call :ScanNet
    goto Menu
) else if "%choice%"=="2" (
    call :SaveMetadata
    goto Menu
) else if "%choice%"=="3" (
    exit /b
) else (
    echo Invalid option. Please try again.
    goto Menu
)

:ScanNet
:: Get the machine's IP address
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr "IPv4 Address"') do (
    set ip_address=%%A
)

:: Remove spaces from the IP
set ip_address=%ip_address: =%

:: Determine the network range
for /f "tokens=1,2,3 delims=." %%A in ("%ip_address%") do (
    set subnet=%%A.%%B.%%C.0/24
)

:: Inform the identified network
echo Rede identificada: %subnet%

:: Scanning connected devices with OS detection and TCP connect scan
echo Escaneando a rede %subnet%...
%nmap_path% -sT -O %subnet% > "%~dp0MetaData.logs\scan_results.txt"

:: Filter relevant results and save to the log file
echo Dispositivos conectados: > "%~dp0MetaData.logs\devices.txt"
for /f "tokens=2 delims= " %%B in ('findstr "Nmap scan report" "%~dp0MetaData.logs\scan_results.txt"') do (
    set "ip=%%B"
    echo IP: !ip! >> "%~dp0MetaData.logs\devices.txt"
    
    :: Extract OS information
    for /f "tokens=2 delims=:" %%C in ('findstr /C:"OS details" "%~dp0MetaData.logs\scan_results.txt"') do (
        echo Brand/Model: %%C >> "%~dp0MetaData.logs\devices.txt"
    )
)

:: Display results
type "%~dp0MetaData.logs\devices.txt"

echo Relatorio salvo em "%~dp0MetaData.logs\devices.txt".
exit /b

:SaveMetadata
set /p "date=Enter the date (format YYYY-MM-DD): "
set "uniqueNumber=!date:~0,4!!date:~5,2!!date:~8,2!"  REM Create unique number based on date
set "filename=MetaData.logs\%uniqueNumber%_metadata.txt"

:: Check if devices.txt exists before saving
if exist "%~dp0MetaData.logs\devices.txt" (
    copy "%~dp0MetaData.logs\devices.txt" "!filename!" >nul
    echo Metadata saved as !filename!.
) else (
    echo No device information found. Please perform a scan first.
)

exit /b