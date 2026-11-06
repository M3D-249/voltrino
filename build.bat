
@echo off
setlocal EnableDelayedExpansion

:: ==========================================
:: Project configuration
:: ==========================================

set MCU=atmega328p

set PORT=COM3
set BAUD=115200

:: ==========================================
:: Toolchain
:: ==========================================

set CC=avr-gcc
set OBJCOPY=avr-objcopy
set OBJDUMP=avr-objdump
set SIZE=avr-size
set AVRDUDE=avrdude

:: ==========================================
:: Project files
:: ==========================================

set BUILD=build
set TARGET=%BUILD%\firmware

set ELF=%TARGET%.elf
set HEX=%TARGET%.hex
set LIST=%TARGET%.lst

:: ==========================================
:: Compiler options
:: ==========================================

set CFLAGS=-mmcu=%MCU% -std=gnu11 -Os -Wall -Wextra -ffunction-sections -fdata-sections -Iinclude

set LDFLAGS=-mmcu=%MCU% -Wl,--gc-sections

:: ==========================================
:: Source files
:: ==========================================

set SRC=src\main.c src\gpio.c

:: ==========================================
:: Main menu
:: ==========================================

:MENU
cls

echo ==========================================
echo       AVR ATmega328P BUILD SYSTEM
echo ==========================================
echo.
echo MCU:  %MCU%
echo PORT: %PORT%
echo BAUD: %BAUD%
echo.
echo ------------------------------------------
echo Select an operation:
echo ------------------------------------------
echo.
echo 1. Build firmware
echo 2. Upload firmware
echo 3. Inspect firmware
echo 4. Clean build files
echo 0. Exit
echo.

set /p CHOICE=Select operation:

if "%CHOICE%"=="1" goto BUILD_FIRMWARE
if "%CHOICE%"=="2" goto UPLOAD_FIRMWARE
if "%CHOICE%"=="3" goto INSPECT_FIRMWARE
if "%CHOICE%"=="4" goto CLEAN
if "%CHOICE%"=="0" exit /b 0

echo Invalid selection.
pause
goto MENU

:: ==========================================
:: Build firmware
:: ==========================================

:BUILD_FIRMWARE

echo.
echo ==========================================
echo Building firmware
echo ==========================================

if not exist "%BUILD%" mkdir "%BUILD%"

set OBJECTS=

for %%F in (%SRC%) do (

    echo.
    echo Compiling %%F...

    set OBJECT=%BUILD%\%%~nF.o

    %CC% %CFLAGS% -c "%%F" -o "!OBJECT!"

    if errorlevel 1 goto BUILD_ERROR

    set OBJECTS=!OBJECTS! "!OBJECT!"
)

echo.
echo Linking firmware...

%CC% %LDFLAGS% !OBJECTS! -o "%ELF%"

if errorlevel 1 goto BUILD_ERROR

echo.
echo Generating HEX file...

%OBJCOPY% -O ihex -R .eeprom "%ELF%" "%HEX%"

if errorlevel 1 goto BUILD_ERROR

echo.
echo ==========================================
echo BUILD SUCCESSFUL
echo ==========================================
echo Output: %HEX%

pause
goto MENU

:BUILD_ERROR
echo.
echo BUILD FAILED!
pause
goto MENU

:: ==========================================
:: Upload firmware
:: ==========================================

:UPLOAD_FIRMWARE

echo.
echo ==========================================
echo Uploading firmware
echo ==========================================

if not exist "%HEX%" (
    echo Firmware not found. Building first...
    goto BUILD_FOR_UPLOAD
)

goto FLASH

:BUILD_FOR_UPLOAD

call :BUILD_ROUTINE

if errorlevel 1 goto MENU

:FLASH

echo.
set /p INPUT=Serial port [%PORT%]:

if not "!INPUT!"=="" set PORT=!INPUT!

echo.
echo Uploading to %MCU% on %PORT%...

%AVRDUDE% -v -p %MCU% -c arduino -P %PORT% -b %BAUD% -D -U flash:w:%HEX%:i

if errorlevel 1 (
    echo.
    echo UPLOAD FAILED!
) else (
    echo.
    echo UPLOAD SUCCESSFUL!
)

pause
goto MENU

:: ==========================================
:: Internal build routine
:: ==========================================

:BUILD_ROUTINE

if not exist "%BUILD%" mkdir "%BUILD%"

set OBJECTS=

for %%F in (%SRC%) do (

    echo Compiling %%F...

    set OBJECT=%BUILD%\%%~nF.o

    %CC% %CFLAGS% -c "%%F" -o "!OBJECT!"

    if errorlevel 1 exit /b 1

    set OBJECTS=!OBJECTS! "!OBJECT!"
)

%CC% %LDFLAGS% !OBJECTS! -o "%ELF%"

if errorlevel 1 exit /b 1

%OBJCOPY% -O ihex -R .eeprom "%ELF%" "%HEX%"

if errorlevel 1 exit /b 1

exit /b 0

:: ==========================================
:: Inspect firmware
:: ==========================================

:INSPECT_FIRMWARE

if not exist "%ELF%" (
    echo.
    echo No built firmware found!
    echo Build firmware first.
    pause
    goto MENU
)

echo.
echo ==========================================
echo Firmware inspection
echo ==========================================

echo.
echo 1. Memory usage
echo ------------------------------------------

%SIZE% --format=avr --mcu=%MCU% "%ELF%"

echo.
echo 2. Generate assembly listing
echo ------------------------------------------

%OBJDUMP% -d -S "%ELF%" > "%LIST%"

echo Generated: %LIST%

echo.
echo 3. Build files
echo ------------------------------------------

dir "%BUILD%"

pause
goto MENU

:: ==========================================
:: Clean
:: ==========================================

:CLEAN

echo.
echo Cleaning build directory...

if exist "%BUILD%" rmdir /s /q "%BUILD%"

echo Clean completed.

pause
goto MENU
