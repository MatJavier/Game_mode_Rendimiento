@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Gaming Mode Manager (Batch-Only Stable - FIXED)

:: =================================================
:: REQUIRE ADMIN
:: =================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo [ERROR] Ejecuta este .BAT como ADMINISTRADOR.
  pause
  exit /b 1
)

:: =================================================
:: REGISTRY PATHS
:: =================================================
set "BK=HKCU\Software\GamingModeManager"
set "MM=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
set "GCS=HKCU\System\GameConfigStore"
set "GDVR=HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
set "GBAR=HKCU\Software\Microsoft\GameBar"

:: =================================================
:: LOG (batch-only timestamp - filename only)
:: =================================================
set "stamp=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "stamp=%stamp: =0%"
set "log=%~dp0GamingMode_%stamp%.log"

call :log "=== START ==="

:: =================================================
:: MENU
:: =================================================
:MENU
cls
echo ==========================================
echo        GAMING MODE MANAGER (BATCH)
echo ==========================================
echo 1) Activar Modo Gaming
echo 2) Desactivar / Restaurar
echo 3) Ver Estado
echo 0) Salir
echo ------------------------------------------
set /p opt=Selecciona una opcion: 

if "%opt%"=="1" goto ENABLE
if "%opt%"=="2" goto DISABLE
if "%opt%"=="3" goto STATUS
if "%opt%"=="0" goto END
goto MENU


:: =================================================
:: ENABLE GAMING MODE
:: =================================================
:ENABLE
call :ensure_backup
call :get_flag

if "!ENABLED!"=="1" (
  echo [INFO] El modo gaming ya esta ACTIVADO.
  pause
  goto MENU
)

echo [OK] Activando modo gaming...
call :log "Enable requested"

:: ---- Power plan: High Performance
powercfg -setactive SCHEME_MIN >nul 2>&1
call :log "Power plan set to SCHEME_MIN"

:: ---- Multimedia priority
reg add "%MM%" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f >nul 2>&1
reg add "%MM%" /v SystemResponsiveness   /t REG_DWORD /d 0 /f >nul 2>&1
call :log "Multimedia SystemProfile set"

:: ---- Disable Game DVR capture
reg add "%GDVR%" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%GCS%"  /v GameDVR_Enabled   /t REG_DWORD /d 0 /f >nul 2>&1
call :log "Game DVR disabled"

:: ---- Ensure Game Mode enabled
reg add "%GBAR%" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "%GBAR%" /v AllowAutoGameMode   /t REG_DWORD /d 1 /f >nul 2>&1
call :log "Game Mode enabled"

:: ---- Stable TCP baseline
netsh int tcp set global autotuninglevel=normal >nul 2>&1
call :log "TCP autotuning set to normal"

:: ---- Flag enabled
reg add "%BK%" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
call :log "Gaming mode ENABLED"

echo.
echo  Modo gaming ACTIVADO.
pause
goto MENU


:: =================================================
:: DISABLE / RESTORE
:: =================================================
:DISABLE
call :get_flag

if not "!ENABLED!"=="1" (
  echo [INFO] El modo gaming NO esta activo.
  pause
  goto MENU
)

echo [OK] Restaurando configuracion original...
call :log "Disable requested"

:: ---- Restore DWORDs
call :restore_dword "%MM%"  NetworkThrottlingIndex "%BK%" BK_NetworkThrottlingIndex
call :restore_dword "%MM%"  SystemResponsiveness   "%BK%" BK_SystemResponsiveness
call :restore_dword "%GDVR%" AppCaptureEnabled     "%BK%" BK_AppCaptureEnabled
call :restore_dword "%GCS%"  GameDVR_Enabled       "%BK%" BK_GameDVR_Enabled
call :restore_dword "%GBAR%" AutoGameModeEnabled   "%BK%" BK_AutoGameModeEnabled
call :restore_dword "%GBAR%" AllowAutoGameMode     "%BK%" BK_AllowAutoGameMode

:: ---- Restore power plan (GUID stored)
set "PS="
for /f "tokens=3" %%g in ('reg query "%BK%" /v BK_PowerScheme 2^>nul ^| findstr /i "BK_PowerScheme"') do set "PS=%%g"
if defined PS (
  powercfg -setactive !PS! >nul 2>&1
  call :log "Power plan restored: !PS!"
) else (
  powercfg -setactive SCHEME_BALANCED >nul 2>&1
  call :log "Power plan fallback: BALANCED"
)

:: ---- Restore TCP autotuning
set "AT="
for /f "tokens=3" %%a in ('reg query "%BK%" /v BK_AutoTuning 2^>nul ^| findstr /i "BK_AutoTuning"') do set "AT=%%a"
if defined AT (
  netsh int tcp set global autotuninglevel=!AT! >nul 2>&1
  call :log "TCP autotuning restored: !AT!"
) else (
  netsh int tcp set global autotuninglevel=normal >nul 2>&1
  call :log "TCP autotuning fallback normal"
)

:: ---- Clear flag
reg add "%BK%" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
call :log "Gaming mode DISABLED"

echo.
echo  Sistema restaurado.
pause
goto MENU


:: =================================================
:: STATUS
:: =================================================
:STATUS
cls
call :get_flag
echo ==========================================
if "!ENABLED!"=="1" (
  echo  ESTADO: MODO GAMING ACTIVADO
) else (
  echo  ESTADO: MODO NORMAL
)
echo ==========================================
echo.
call :showval "%MM%"  NetworkThrottlingIndex
call :showval "%MM%"  SystemResponsiveness
call :showval "%GDVR%" AppCaptureEnabled
call :showval "%GCS%"  GameDVR_Enabled
call :showval "%GBAR%" AutoGameModeEnabled
call :showval "%GBAR%" AllowAutoGameMode
echo.
pause
goto MENU


:: =================================================
:: BACKUP (ONLY ONCE) - FIXED
:: =================================================
:ensure_backup
reg query "%BK%" /v BackedUp >nul 2>&1
if %errorlevel%==0 goto :eof

call :log "Creating backup"

:: ---- Power plan GUID (pattern extraction, language-agnostic)
set "ACTSCHEME="
for /f "tokens=1 delims= " %%g in ('powercfg /getactivescheme 2^>nul ^| findstr /r /i "[0-9a-f][0-9a-f]*-[0-9a-f][0-9a-f]*-[0-9a-f][0-9a-f]*-[0-9a-f][0-9a-f]*-[0-9a-f][0-9a-f]*"') do (
  if not defined ACTSCHEME set "ACTSCHEME=%%g"
)
if not defined ACTSCHEME set "ACTSCHEME=SCHEME_BALANCED"
reg add "%BK%" /v BK_PowerScheme /t REG_SZ /d "%ACTSCHEME%" /f >nul 2>&1
call :log "Backed up power scheme: %ACTSCHEME%"

:: ---- TCP autotuning (extract value among known set; language-agnostic)
set "AUTOT="
for /f "tokens=* delims=" %%l in ('netsh int tcp show global 2^>nul') do (
  for %%v in (normal disabled restricted highlyrestricted experimental) do (
    echo %%l | findstr /i /r " %%v$" >nul && if not defined AUTOT set "AUTOT=%%v"
  )
)
if not defined AUTOT set "AUTOT=normal"
reg add "%BK%" /v BK_AutoTuning /t REG_SZ /d "%AUTOT%" /f >nul 2>&1
call :log "Backed up autotuning: %AUTOT%"

:: ---- DWORD backups
call :backup_dword "%MM%"  NetworkThrottlingIndex "%BK%" BK_NetworkThrottlingIndex 10
call :backup_dword "%MM%"  SystemResponsiveness   "%BK%" BK_SystemResponsiveness   20
call :backup_dword "%GDVR%" AppCaptureEnabled     "%BK%" BK_AppCaptureEnabled      1
call :backup_dword "%GCS%"  GameDVR_Enabled       "%BK%" BK_GameDVR_Enabled        1
call :backup_dword "%GBAR%" AutoGameModeEnabled   "%BK%" BK_AutoGameModeEnabled    1
call :backup_dword "%GBAR%" AllowAutoGameMode     "%BK%" BK_AllowAutoGameMode      1

reg add "%BK%" /v BackedUp /t REG_DWORD /d 1 /f >nul 2>&1
call :log "Backup complete"
goto :eof


:: =================================================
:: HELPERS
:: =================================================
:backup_dword
set "SRC=%~1"
set "VAL=%~2"
set "DSTK=%~3"
set "DSTV=%~4"
set "DEF=%~5"

set "CUR="
for /f "tokens=3" %%a in ('reg query "%SRC%" /v "%VAL%" 2^>nul ^| findstr /i "%VAL%"') do set "CUR=%%a"
if not defined CUR (
  reg add "%DSTK%" /v "%DSTV%" /t REG_DWORD /d %DEF% /f >nul 2>&1
) else (
  reg add "%DSTK%" /v "%DSTV%" /t REG_DWORD /d %CUR% /f >nul 2>&1
)
goto :eof

:restore_dword
set "DST=%~1"
set "VAL=%~2"
set "SRC=%~3"
set "SRCV=%~4"

set "BKVAL="
for /f "tokens=3" %%a in ('reg query "%SRC%" /v "%SRCV%" 2^>nul ^| findstr /i "%SRCV%"') do set "BKVAL=%%a"
if defined BKVAL reg add "%DST%" /v "%VAL%" /t REG_DWORD /d %BKVAL% /f >nul 2>&1
goto :eof

:showval
set "K=%~1"
set "V=%~2"
set "O=(no existe)"
for /f "tokens=3" %%a in ('reg query "%K%" /v "%V%" 2^>nul ^| findstr /i "%V%"') do set "O=%%a"
echo - %V% = %O%
goto :eof

:get_flag
set "ENABLED=0"
for /f "tokens=3" %%a in ('reg query "%BK%" /v Enabled 2^>nul ^| findstr /i "Enabled"') do (
  if /i "%%a"=="0x1" set "ENABLED=1"
)
goto :eof

:log
>> "%log%" echo [%date% %time%] %~1
goto :eof

:END
call :log "=== END ==="
endlocal
exit /b 0
