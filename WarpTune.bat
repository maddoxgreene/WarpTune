echo off
@echo off
cls
setlocal EnableDelayedExpansion
color 0D
title WarpTune
mode con cols=90 lines=35

cd /d "%~dp0"

:: ===== Admin Check =====
>nul 2>&1 net session
if %errorlevel% neq 0 (
    cls
    echo ================================================
    echo   ERROR: Run this script as Administrator
    echo ================================================
    pause
    exit /b
)

:MENU
cls
echo ==================================================
echo                     WarpTune
echo ==================================================
echo      High-performance network optimization tool
echo --------------------------------------------------
echo.
echo   [1]  Apply TCP Optimizations
echo   [2]  Apply NetSH Optimizations
echo   [3]  Apply QoS Optimizations
echo   [4]  Optimize DNS (Cloudflare)
echo   [5]  Optimize Network Adapter
echo   [6]  Debloat Network Adapter
echo   [7]  Enable Smart Packets
echo   [8]  Restart Network Adapter
echo   [9]  Backup Registry
echo   [10] Enable Windows Firewall
echo.
echo --------------------------------------------------
set /p choice=Choose an option (1-10): 

if "%choice%"=="1" goto TCP
if "%choice%"=="2" goto NETSH
if "%choice%"=="3" goto QOS
if "%choice%"=="4" goto DNS
if "%choice%"=="5" goto OPTADAPTER
if "%choice%"=="6" goto DEBLOAT
if "%choice%"=="7" goto SMART
if "%choice%"=="8" goto RESTART
if "%choice%"=="9" goto BACKUP
if "%choice%"=="10" goto FIREWALL
goto MENU


:TCP
cls
echo ================= TCP OPTIMIZATION =================
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TCPAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TCPDelAckTicks /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxUserPort /t REG_DWORD /d 65534 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DefaultTTL /t REG_DWORD /d 64 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableRSS /t REG_DWORD /d 1 /f >nul 2>&1
echo.
echo TCP optimizations applied.
pause
goto MENU


:NETSH
cls
echo ================= NETSH OPTIMIZATION =================
netsh int tcp set global autotuninglevel=disabled >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global timestamps=disabled >nul 2>&1
netsh int tcp set global initialRto=2000 >nul 2>&1
netsh int isatap set state disabled >nul 2>&1
echo.
echo NetSH optimizations applied.
pause
goto MENU


:QOS
cls
echo ================= QoS OPTIMIZATION =================
reg add "HKLM\Software\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f >nul 2>&1
sc config Psched start= auto >nul 2>&1
sc start Psched >nul 2>&1
netsh advfirewall set allprofiles state off >nul 2>&1
echo.
echo QoS optimizations applied.
pause
goto MENU


:DNS
cls
echo ================= DNS OPTIMIZATION =================
for /f "tokens=1*" %%A in ('netsh interface show interface ^| findstr "Connected"') do (
    netsh interface ip set dns name="%%B" static 1.1.1.1 >nul 2>&1
    netsh interface ip add dns name="%%B" 1.0.0.1 index=2 >nul 2>&1
)
echo.
echo DNS set to Cloudflare.
pause
goto MENU


:OPTADAPTER
cls
echo ============ NETWORK ADAPTER OPTIMIZATION ============
echo Optimizing active adapters...

set "PS1=%TEMP%\warptune_optadapter.ps1"
del /f /q "%PS1%" >nul 2>&1

>>"%PS1%" echo $ErrorActionPreference = 'SilentlyContinue'
>>"%PS1%" echo $adapters = Get-NetAdapter ^| Where-Object { $_.Status -eq 'Up' -and $_.HardwareInterface -eq $true }
>>"%PS1%" echo foreach($a in $adapters^) {
>>"%PS1%" echo ^    try { Set-NetAdapterPowerManagement -Name $a.Name -AllowComputerToTurnOffDevice Disabled ^| Out-Null } catch {}
>>"%PS1%" echo ^    $props = Get-NetAdapterAdvancedProperty -Name $a.Name
>>"%PS1%" echo ^    function SetAdv($n,$v^) {
>>"%PS1%" echo ^        $p = $props ^| Where-Object { $_.DisplayName -eq $n } ^| Select-Object -First 1
>>"%PS1%" echo ^        if($p^) { try { Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName $p.DisplayName -DisplayValue $v -NoRestart ^| Out-Null } catch {} }
>>"%PS1%" echo ^    }
>>"%PS1%" echo ^    SetAdv 'Energy Efficient Ethernet' 'Disabled'
>>"%PS1%" echo ^    SetAdv 'Green Ethernet' 'Disabled'
>>"%PS1%" echo ^    SetAdv 'Power Saving Mode' 'Disabled'
>>"%PS1%" echo ^    SetAdv 'Interrupt Moderation' 'Disabled'
>>"%PS1%" echo ^    SetAdv 'Interrupt Moderation Rate' 'Off'
>>"%PS1%" echo ^    SetAdv 'Receive Side Scaling' 'Enabled'
>>"%PS1%" echo ^    SetAdv 'Large Send Offload v2 (IPv4)' 'Disabled'
>>"%PS1%" echo ^    SetAdv 'Large Send Offload v2 (IPv6)' 'Disabled'
>>"%PS1%" echo }

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" >nul 2>&1
del /f /q "%PS1%" >nul 2>&1

echo.
echo Network adapter optimized.
pause
goto MENU


:DEBLOAT
cls
echo ============ NETWORK DEBLOAT ============
netsh interface teredo set state disabled >nul 2>&1
netsh interface isatap set state disabled >nul 2>&1
netsh interface ipv6 6to4 set state disabled >nul 2>&1
echo.
echo Network debloat complete.
pause
goto MENU


:SMART
cls
echo ============ SMART PACKETS ============
sc config BITS start= auto >nul 2>&1
sc start BITS >nul 2>&1
echo.
echo Smart Packets enabled.
pause
goto MENU


:RESTART
cls
echo ============ RESTARTING NETWORK ============
powershell -NoProfile -Command "Get-NetAdapter | Restart-NetAdapter -Confirm:$false" >nul 2>&1
echo.
echo Network restarted.
pause
goto MENU


:BACKUP
cls
echo ============ REGISTRY BACKUP ============
set "BACKUP=%USERPROFILE%\Downloads\WarpTune_Backup.reg"
reg export HKLM "%BACKUP%" /y >nul 2>&1
echo.
echo Backup saved to:
echo %BACKUP%
pause
goto MENU


:FIREWALL
cls
echo ============ FIREWALL ENABLE ============
sc config bfe start= auto >nul 2>&1
sc start bfe >nul 2>&1
sc config mpssvc start= auto >nul 2>&1
sc start mpssvc >nul 2>&1
netsh advfirewall set allprofiles state on >nul 2>&1
echo.
echo Windows Firewall enabled.
pause
goto MENU
