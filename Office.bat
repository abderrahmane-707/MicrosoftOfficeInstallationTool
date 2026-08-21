@echo off
setlocal enabledelayedexpansion
mode con: cols=100 lines=30 >nul 2>&1

:: Go to script's directory
cd /d "%~dp0"

:: Check for ODT setup.exe
if not exist "setup.exe" (
    echo [ERROR] setup.exe is missing
    echo Please download the Office Deployment Tool and place setup.exe in the script directory
    pause & exit /b 1
)

:: Check for administrator privileges
fltmc >nul 2>&1
if errorlevel 1 (
    echo This script must be run with Administrator privileges
    pause & exit /b 1
)

:: Initialize
call :INIT
call :INIT_PROGRAMS
call :DESELECT_ALL

:: Main interface
:OFFICE_MENU
cls
echo.
echo                                                 \\!//
echo                                                 (o o)
echo              -------------------------------oOOo-(_)-oOOo-------------------------------
echo                                   Microsoft Office Installation Tool
echo              ---------------------------------------------------------------------------
echo.

:: Set Office version message
if "%OPTV%"=="365" set "VERSION_MSG=Office 365"
if "%OPTV%"=="2024" set "VERSION_MSG=Office 2024 (LTSC)"
if "%OPTV%"=="2021" set "VERSION_MSG=Office 2021"
if "%OPTV%"=="2019" set "VERSION_MSG=Office 2019"
if "%OPTV%"=="2016" set "VERSION_MSG=Office 2016"

:: Set installation mode message
if "%OPTM%"=="%ON%" set "MOD_MSG=Online Installation"
if "%OPTM%,%OFILES%"=="%OFF%,%OFF%" set "MOD_MSG=Download Offline Files"
if "%OPTM%,%OFILES%"=="%OFF%,%ON%" set "MOD_MSG=Offline Installation"

:: Set language message
if "%OPTL%"=="ar-sa" set "LANG_MSG=ar-sa"
if "%OPTL%"=="en-us" set "LANG_MSG=en-us"
if "%OPTL%"=="fr-fr" set "LANG_MSG=fr-fr"

call :RENDER_COLUMNS

echo.
echo    [V] Version:      %VERSION_MSG%
echo    [L] Language:     %LANG_MSG%
echo    [M] Mode:         %MOD_MSG%
echo.
echo              ---------------------------------------------------------------------------
echo.
echo                   [A] Select All          [D] Deselect All             [0] Exit
echo.

echo Tip: you can select multiple items, e.g. 1,3,5 or 1-5 or 1-3,7,10-12
set "choice=" & set /p "choice=--> Select an option(s) and press [S] to Start: "

if "%choice%"=="" goto OFFICE_MENU
if "%choice%"=="0" exit /b
if /i "%choice%"=="V" (call :TOGGLE_VERSION & goto OFFICE_MENU)
if /i "%choice%"=="L" (call :TOGGLE_LANGUAGE & goto OFFICE_MENU)
if /i "%choice%"=="M" (call :TOGGLE_MODE & goto OFFICE_MENU)
if /i "%choice%"=="A" (call :SELECT_ALL & goto OFFICE_MENU)
if /i "%choice%"=="D" (call :DESELECT_ALL & goto OFFICE_MENU)
if /i "%choice%"=="S" goto CONTINUE

call :MULTI_INPUT
goto OFFICE_MENU

:CONTINUE
cls
:: Collect every selected program into a single list, then check the selection in one go
set "toInstall="
for /L %%i in (1,1,%MAX_PROGS%) do (
    if "!OPT%%i!"=="%ON%" (
        for %%V in (ITEM%%i) do set "toInstall=!toInstall!;!%%V!"
    )
)

if not defined toInstall (
    echo No programs were selected
    pause & goto OFFICE_MENU
)

echo Installing the following programs:
for %%P in (!toInstall!) do echo     - %%P

echo.
echo    Installation Architecture: %ARCH_MSG%
echo    Installation Version: %OPTV%
echo    Language: %LANG_MSG%
echo    Installation Mode: %MOD_MSG%

echo. & call :CHOICE "Do you want to start?"
if errorlevel 2 (echo The operation was cancelled & pause & goto OFFICE_MENU)

if "%OPTM%"=="%ON%" goto ONLINE_INSTALL
if "%OPTM%,%OFILES%"=="%OFF%,%OFF%" goto DOWNLOAD_FILES
if "%OPTM%,%OFILES%"=="%OFF%,%ON%" goto OFFLINE_INSTALL
exit /b

:DOWNLOAD_FILES
echo. & echo Downloading Microsoft Office files 
call :CONFIG
"setup.exe" /download "%CONFIG_FILE%"
if errorlevel 1 (
    echo. & echo [ERROR] Download failed
    call :DEL_CONFIG
    pause & goto OFFICE_MENU
)
goto END

:OFFLINE_INSTALL
echo. & echo Installing Microsoft Office (using previously downloaded files)
call :CONFIG
"setup.exe" /configure "%CONFIG_FILE%"
if errorlevel 1 (
    echo. & echo [ERROR] Installation failed
    call :DEL_CONFIG
    pause & goto OFFICE_MENU
)

call :CHOICE "Deleting Microsoft Office Installation Files?"
if %errorlevel% equ 1 (
    rd /s /q "Office"
    if exist "Office" (
        echo [ERROR] Could not delete: %~dp0Office
    )
)
goto END

:ONLINE_INSTALL
echo. & echo Downloading and Installing Microsoft Office
call :CONFIG
"setup.exe" /configure "%CONFIG_FILE%"
if errorlevel 1 (
    echo. & echo [ERROR] Installation failed
    call :DEL_CONFIG
    pause & goto OFFICE_MENU
)
goto END

:END
call :DEL_CONFIG
echo. & echo Disabling Microsoft Office Telemetry
reg add "HKLM\SOFTWARE\Microsoft\Office\Common\ClientTelemetry" /v "DisableTelemetry" /t REG_DWORD /d "00000001" /f >nul

call :CHOICE "Do you want to activate Microsoft Office using (MAS)?"
if %errorlevel% equ 1 (
    echo. & echo The script will open in a new window. Follow the on-screen instructions
    powershell -NoP -EP Bypass -c "irm https://get.activated.win | iex"
)

echo. & echo The operation is done.
pause & call :DESELECT_ALL & goto OFFICE_MENU

:INIT
:: Set configuration file path
set "CONFIG_FILE=%TEMP%\OfficeConfig.xml"

:: Delete the old configuration file if exists
call :DEL_CONFIG

:: Define basic variables
set "ON=(YES)"
set "OFF=(NO)"

:: Determine processor architecture automatically
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "CPU=64"
    set "ARCH_MSG=64-bit"
) else if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "CPU=64"
    set "ARCH_MSG=64-bit (ARM64)"
) else (
    set "CPU=32"
    set "ARCH_MSG=32-bit"
)

:: Additional check for 64-bit OS running 32-bit cmd
if "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
    set "CPU=64"
    set "ARCH_MSG=64-bit (Auto-detected from 64-bit OS)"
)

:: Check for offline files and set default mode dynamically
if exist "Office\Data\*.cab" (
    set "OFILES=%ON%"
    set "OPTM=%OFF%"
) else (
    set "OFILES=%OFF%"
    set "OPTM=%ON%"
)

:: Set default Office version
set "OPTV=2021"

:: Language: ar-sa, en-us, fr-fr
set "OPTL=en-us"

goto :eof

:INIT_PROGRAMS
set "MAX_PROGS=12"

set "ITEM1=Word"
set "ITEM2=Excel"
set "ITEM3=PowerPoint"
set "ITEM4=Outlook"
set "ITEM5=OneNote"
set "ITEM6=Publisher"
set "ITEM7=Access"
set "ITEM8=Visio"
set "ITEM9=Project"
set "ITEM10=Proofing Tools"
set "ITEM11=Teams"
set "ITEM12=OneDrive"
goto :eof

:: Renders items in three columns, marking selected ones with *
:RENDER_COLUMNS
set /a "ROWS=(MAX_PROGS+2)/3"
for /L %%r in (1,1,%ROWS%) do (
    set "line="
    for %%x in (1 2 3) do (
        set /a "idx=%%r+ROWS*(%%x-1)"
        set "cell=                         "
        if !idx! leq !MAX_PROGS! (
            for %%V in (ITEM!idx!) do for %%W in (OPT!idx!) do (
                set "cell=  [!idx!] !%%V!"
                if "!%%W!"=="!ON!" set "cell=* [!idx!] !%%V!"
            )
        )
        set "cell=!cell!                          "
        set "cell=!cell:~0,25!"
        set "line=!line!!cell!"
    )
    echo                  !line!
)
goto :eof

:MULTI_INPUT
set "invalid="
set "tokens=!choice:,= !"

for %%G in (%tokens%) do (
    set "tok=%%G"
    set "matched=0"
    set "noHyphen=!tok:-=!"

    if not "!tok!"=="!noHyphen!" (
        set "rangeStart=" & set "rangeEnd="
        for /f "tokens=1,2 delims=-" %%X in ("!tok!") do (
            set "rangeStart=%%X"
            set "rangeEnd=%%Y"
        )
        set "isNum1=1" & for /f "delims=0123456789" %%C in ("!rangeStart!") do set "isNum1=0"
        set "isNum2=1" & for /f "delims=0123456789" %%C in ("!rangeEnd!") do set "isNum2=0"

        if defined rangeStart if defined rangeEnd if "!isNum1!!isNum2!"=="11" (
            if !rangeStart! geq 1 if !rangeEnd! leq !MAX_PROGS! if !rangeStart! leq !rangeEnd! (
                for /L %%N in (!rangeStart!,1,!rangeEnd!) do (
                    for %%V in (OPT%%N) do (
                        if "!%%V!"=="%ON%" (set "%%V=%OFF%") else (set "%%V=%ON%")
                    )
                )
                set "matched=1"
            )
        )
    ) else (
        set "isNum=1" & for /f "delims=0123456789" %%C in ("!tok!") do set "isNum=0"
        if "!isNum!"=="1" if defined tok (
            if !tok! geq 1 if !tok! leq !MAX_PROGS! (
                for %%V in (OPT!tok!) do (
                    if "!%%V!"=="%ON%" (set "%%V=%OFF%") else (set "%%V=%ON%")
                )
                set "matched=1"
            )
        )
    )

    if "!matched!"=="0" set "invalid=!invalid! !tok!"
)

if defined invalid (
    echo. & echo Invalid or out-of-range input:!invalid!
    pause
)
goto :eof

:TOGGLE_MODE
if "!OPTM!"=="%ON%" (set "OPTM=%OFF%") else (set "OPTM=%ON%")
goto :eof

:SELECT_ALL
for /L %%i in (1,1,%MAX_PROGS%) do set "OPT%%i=%ON%"
goto :eof

:DESELECT_ALL
for /L %%i in (1,1,%MAX_PROGS%) do set "OPT%%i=%OFF%"
goto :eof

:TOGGLE_VERSION
if "%OPTV%"=="365" (set "OPTV=2024") else if "%OPTV%"=="2024" (set "OPTV=2021") else if "%OPTV%"=="2021" (set "OPTV=2019") else if "%OPTV%"=="2019" (set "OPTV=2016") else (set "OPTV=365")
goto :eof

:TOGGLE_LANGUAGE
if "%OPTL%"=="ar-sa" (set "OPTL=en-us") else if "%OPTL%"=="en-us" (set "OPTL=fr-fr") else (set "OPTL=ar-sa")
goto :eof

:CONFIG
echo. & echo Creating Configuration File for Microsoft Office %OPTV%
call :DEL_CONFIG

echo ^<?xml version="1.0" encoding="utf-8"?^> > "%CONFIG_FILE%"
echo ^<Configuration^> >> "%CONFIG_FILE%"

if "%OPTV%"=="365" (
    echo    ^<Add OfficeClientEdition="%CPU%" Channel="Current" MigrateArch="TRUE"^> >> "%CONFIG_FILE%"
) else if "%OPTV%"=="2024" (
    echo    ^<Add OfficeClientEdition="%CPU%" Channel="PerpetualVL2024" MigrateArch="TRUE"^> >> "%CONFIG_FILE%"
) else if "%OPTV%"=="2019" (
    echo    ^<Add OfficeClientEdition="%CPU%" Channel="PerpetualVL2019" MigrateArch="TRUE"^> >> "%CONFIG_FILE%"
) else if "%OPTV%"=="2016" (
    echo    ^<Add OfficeClientEdition="%CPU%" Channel="PerpetualVL2016" MigrateArch="TRUE"^> >> "%CONFIG_FILE%"
) else if "%OPTV%"=="2021" (
    echo    ^<Add OfficeClientEdition="%CPU%" Channel="PerpetualVL2021" MigrateArch="TRUE"^> >> "%CONFIG_FILE%"
)

set "NEEDMAIN=%OFF%"
if "%OPT1%"=="%ON%" set "NEEDMAIN=%ON%"
if "%OPT2%"=="%ON%" set "NEEDMAIN=%ON%"
if "%OPT3%"=="%ON%" set "NEEDMAIN=%ON%"
if "%OPT4%"=="%ON%" set "NEEDMAIN=%ON%"
if "%OPT5%"=="%ON%" set "NEEDMAIN=%ON%"
if "%OPT6%"=="%ON%" set "NEEDMAIN=%ON%"
if "%OPT7%"=="%ON%" set "NEEDMAIN=%ON%"
if "%OPT11%"=="%ON%" set "NEEDMAIN=%ON%"
if "%OPT12%"=="%ON%" set "NEEDMAIN=%ON%"

if "%NEEDMAIN%"=="%ON%" (
    if "%OPTV%"=="365" (
        echo      ^<Product ID="O365ProPlusRetail"^> >> "%CONFIG_FILE%"
    ) else if "%OPTV%"=="2024" (
        echo      ^<Product ID="ProPlus2024Volume"^> >> "%CONFIG_FILE%"
    ) else if "%OPTV%"=="2019" (
        echo      ^<Product ID="ProPlus2019Volume"^> >> "%CONFIG_FILE%"
    ) else if "%OPTV%"=="2016" (
        echo      ^<Product ID="ProPlus2016Volume"^> >> "%CONFIG_FILE%"
    ) else if "%OPTV%"=="2021" (
        echo      ^<Product ID="ProPlus2021Volume"^> >> "%CONFIG_FILE%"
    )

    if "%OPTL%"=="ar-sa" (
        echo        ^<Language ID="ar-sa" /^> >> "%CONFIG_FILE%"
    ) else if "%OPTL%"=="en-us" (
        echo        ^<Language ID="en-us" /^> >> "%CONFIG_FILE%"
    ) else if "%OPTL%"=="fr-fr" (
        echo        ^<Language ID="fr-fr" /^> >> "%CONFIG_FILE%"
    )

    echo        ^<ExcludeApp ID="Lync" /^> >> "%CONFIG_FILE%"
    echo        ^<ExcludeApp ID="Groove" /^> >> "%CONFIG_FILE%"
    echo        ^<ExcludeApp ID="Bing" /^> >> "%CONFIG_FILE%"

    if "%OPT1%"=="%OFF%" echo        ^<ExcludeApp ID="Word" /^> >> "%CONFIG_FILE%"
    if "%OPT2%"=="%OFF%" echo        ^<ExcludeApp ID="Excel" /^> >> "%CONFIG_FILE%"
    if "%OPT3%"=="%OFF%" echo        ^<ExcludeApp ID="PowerPoint" /^> >> "%CONFIG_FILE%"
    if "%OPT4%"=="%OFF%" echo        ^<ExcludeApp ID="Outlook" /^> >> "%CONFIG_FILE%"
    if "%OPT5%"=="%OFF%" echo        ^<ExcludeApp ID="OneNote" /^> >> "%CONFIG_FILE%"
    if "%OPT6%"=="%OFF%" echo        ^<ExcludeApp ID="Publisher" /^> >> "%CONFIG_FILE%"
    if "%OPT7%"=="%OFF%" echo        ^<ExcludeApp ID="Access" /^> >> "%CONFIG_FILE%"
    if "%OPT11%"=="%OFF%" echo        ^<ExcludeApp ID="Teams" /^> >> "%CONFIG_FILE%"
    if "%OPT12%"=="%OFF%" echo        ^<ExcludeApp ID="OneDrive" /^> >> "%CONFIG_FILE%"

    echo      ^</Product^> >> "%CONFIG_FILE%"
)

if "%OPT8%"=="%ON%" (
    if "%OPTV%"=="365" (
        echo      ^<Product ID="VisioProRetail"^> >> "%CONFIG_FILE%"
    ) else if "%OPTV%"=="2024" (
        echo      ^<Product ID="VisioPro2024Volume"^> >> "%CONFIG_FILE%"
    ) else if "%OPTV%"=="2019" (
        echo      ^<Product ID="VisioPro2019Volume"^> >> "%CONFIG_FILE%"
    ) else if "%OPTV%"=="2016" (
        echo      ^<Product ID="VisioPro2016Volume"^> >> "%CONFIG_FILE%"
    ) else if "%OPTV%"=="2021" (
        echo      ^<Product ID="VisioPro2021Volume"^> >> "%CONFIG_FILE%"
    )
    if "%OPTL%"=="ar-sa" (
        echo        ^<Language ID="ar-sa" /^> >> "%CONFIG_FILE%"
    ) else if "%OPTL%"=="en-us" (
        echo        ^<Language ID="en-us" /^> >> "%CONFIG_FILE%"
    ) else if "%OPTL%"=="fr-fr" (
        echo        ^<Language ID="fr-fr" /^> >> "%CONFIG_FILE%"
    )
    echo        ^<ExcludeApp ID="Bing" /^> >> "%CONFIG_FILE%"
    echo      ^</Product^> >> "%CONFIG_FILE%"
)

if "%OPT9%"=="%ON%" (
    if "%OPTV%"=="365" (
        echo      ^<Product ID="ProjectProRetail"^> >> "%CONFIG_FILE%"
    ) else if "%OPTV%"=="2024" (
        echo      ^<Product ID="ProjectPro2024Volume"^> >> "%CONFIG_FILE%"
    ) else if "%OPTV%"=="2019" (
        echo      ^<Product ID="ProjectPro2019Volume"^> >> "%CONFIG_FILE%"
    ) else if "%OPTV%"=="2016" (
        echo      ^<Product ID="ProjectPro2016Volume"^> >> "%CONFIG_FILE%"
    ) else if "%OPTV%"=="2021" (
        echo      ^<Product ID="ProjectPro2021Volume"^> >> "%CONFIG_FILE%"
    )
    if "%OPTL%"=="ar-sa" (
        echo        ^<Language ID="ar-sa" /^> >> "%CONFIG_FILE%"
    ) else if "%OPTL%"=="en-us" (
        echo        ^<Language ID="en-us" /^> >> "%CONFIG_FILE%"
    ) else if "%OPTL%"=="fr-fr" (
        echo        ^<Language ID="fr-fr" /^> >> "%CONFIG_FILE%"
    )
    echo        ^<ExcludeApp ID="Bing" /^> >> "%CONFIG_FILE%"
    echo      ^</Product^> >> "%CONFIG_FILE%"
)

if "%OPT10%"=="%ON%" (
    echo      ^<Product ID="ProofingTools"^> >> "%CONFIG_FILE%"
    if "%OPTL%"=="ar-sa" (
        echo        ^<Language ID="ar-sa" /^> >> "%CONFIG_FILE%"
    ) else if "%OPTL%"=="en-us" (
        echo        ^<Language ID="en-us" /^> >> "%CONFIG_FILE%"
    ) else if "%OPTL%"=="fr-fr" (
        echo        ^<Language ID="fr-fr" /^> >> "%CONFIG_FILE%"
    )
    echo        ^<ExcludeApp ID="Bing" /^> >> "%CONFIG_FILE%"
    echo      ^</Product^> >> "%CONFIG_FILE%"
)

echo    ^</Add^> >> "%CONFIG_FILE%"
echo    ^<Updates Enabled="FALSE" /^> >> "%CONFIG_FILE%"
echo    ^<Display Level="Full" AcceptEULA="TRUE" /^> >> "%CONFIG_FILE%"
echo    ^<Property Name="ForceAppShutdown" Value="TRUE" /^> >> "%CONFIG_FILE%"
echo    ^<AppSettings^> >> "%CONFIG_FILE%"
echo        ^<User Key="software\microsoft\office\16.0\common" Name="ui theme" Value="5" Type="REG_DWORD" App="office16" Id="L_OfficeTheme" /^> >> "%CONFIG_FILE%"
echo        ^<User Key="software\microsoft\office\16.0\common" Name="default ui theme" Value="5" Type="REG_DWORD" App="office16" Id="L_OfficeDefaultTheme" /^> >> "%CONFIG_FILE%"
echo    ^</AppSettings^> >> "%CONFIG_FILE%"
echo ^</Configuration^> >> "%CONFIG_FILE%"

if not exist "%CONFIG_FILE%" (
    echo [ERROR] Failed to create configuration file!
	pause & goto OFFICE_MENU
)
goto :eof

:DEL_CONFIG
if exist "%CONFIG_FILE%" del /f /q "%CONFIG_FILE%" >nul 2>&1
goto :eof

:CHOICE
choice /C YN /N /M "%~1 [Y/n]: "
goto :eof
