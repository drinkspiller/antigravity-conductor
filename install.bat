@echo off
setlocal EnableDelayedExpansion
:: =============================================================================
:: Antigravity Conductor Skills & Rules Installer (Windows)
:: =============================================================================

set "VERSION=0.11.0"
set "FLAGS_dry_run=0"
set "FLAGS_force=0"
set "FLAGS_uninstall=0"
set "FLAGS_update=0"

:: Parse arguments
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--dry_run" ( set "FLAGS_dry_run=1" & shift & goto :parse_args )
if /i "%~1"=="--force" ( set "FLAGS_force=1" & shift & goto :parse_args )
if /i "%~1"=="--uninstall" ( set "FLAGS_uninstall=1" & shift & goto :parse_args )
if /i "%~1"=="--update" ( set "FLAGS_update=1" & shift & goto :parse_args )
if /i "%~1"=="--help" ( goto :show_help )
if /i "%~1"=="-h" ( goto :show_help )
echo Unknown argument: %~1
exit /b 1

:show_help
echo Usage: install.bat [OPTIONS]
echo   --dry_run    Preview changes without writing files
echo   --force      Overwrite existing files without backup
echo   --update     Update to the latest version (implies --force)
echo   --uninstall  Remove all installed files
echo   --help, -h   Show this help message
exit /b 0

:args_done

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "SOURCE_TEMPLATE_DIR=%SCRIPT_DIR%\skills\conductor-setup\templates"
set "SOURCE_RULES_DIR=%SCRIPT_DIR%\rules"

set "TARGET_SKILLS_ROOT=%USERPROFILE%\.gemini\antigravity\skills"
set "TARGET_RULES_ROOT=%USERPROFILE%\.gemini\antigravity\rules"
set "TARGET_TEMPLATE_DIR=%TARGET_SKILLS_ROOT%\conductor-setup\templates"

echo.
echo   ==================================================
echo     Antigravity Conductor Installer (Windows) v%VERSION%
echo   ==================================================
echo.

if "%FLAGS_update%"=="1" (
    set "FLAGS_force=1"
    if exist "%TARGET_SKILLS_ROOT%\conductor-setup\.conductor_version" (
        set /p INSTALLED_VERSION= < "%TARGET_SKILLS_ROOT%\conductor-setup\.conductor_version"
        if "!INSTALLED_VERSION!"=="%VERSION%" (
            echo Already up to date (v%VERSION%^)
            exit /b 0
        )
        echo   Installed: v!INSTALLED_VERSION! -^> v%VERSION%
    ) else (
        echo   No existing installation found. Performing fresh install.
    )
    echo.
)

if "%FLAGS_uninstall%"=="1" goto :do_uninstall

:: Validate sources
if not exist "%SOURCE_TEMPLATE_DIR%\workflow_template.md" ( echo [ERROR] Missing %SOURCE_TEMPLATE_DIR%\workflow_template.md & exit /b 1 )
for %%S in (conductor-setup conductor-new-track conductor-implement conductor-status conductor-review conductor-revert conductor-chat) do (
    if not exist "%SCRIPT_DIR%\skills\%%S\SKILL.md" ( echo [ERROR] Missing %SCRIPT_DIR%\skills\%%S\SKILL.md & exit /b 1 )
)

if "%FLAGS_dry_run%"=="1" echo   [DRY RUN MODE - no files will be written]

:: Cleanup deprecated sub-skills
for %%O in (conductor_setup conductor_newTrack conductor_newTrack_grill conductor_newTrack_discovery conductor_implement conductor_status conductor_review conductor_revert conductor_chat conductor) do (
    if exist "%TARGET_SKILLS_ROOT%\%%O" (
        if "%FLAGS_dry_run%"=="1" (
            echo Would remove deprecated directory: %TARGET_SKILLS_ROOT%\%%O
        ) else (
            rmdir /s /q "%TARGET_SKILLS_ROOT%\%%O"
            echo Removed deprecated directory: %TARGET_SKILLS_ROOT%\%%O
        )
    )
)

:: Templates
echo.
echo --- Installing Conductor Templates ---
call :install_file "%SOURCE_TEMPLATE_DIR%\workflow_template.md" "%TARGET_TEMPLATE_DIR%\workflow_template.md"
call :install_file "%SOURCE_TEMPLATE_DIR%\adr_template.md" "%TARGET_TEMPLATE_DIR%\adr_template.md"

:: Version Stamp
if "%FLAGS_dry_run%"=="1" (
    echo Would write version file: .conductor_version
) else (
    if not exist "%TARGET_SKILLS_ROOT%\conductor-setup" mkdir "%TARGET_SKILLS_ROOT%\conductor-setup"
    echo %VERSION%> "%TARGET_SKILLS_ROOT%\conductor-setup\.conductor_version"
    echo Wrote version stamp: v%VERSION%
)

:: Sub-Skills
echo.
echo --- Installing Conductor Command Skills ---
for %%S in (conductor-setup conductor-new-track conductor-implement conductor-status conductor-review conductor-revert conductor-chat) do (
    call :install_file "%SCRIPT_DIR%\skills\%%S\SKILL.md" "%TARGET_SKILLS_ROOT%\%%S\SKILL.md"
)

:: Rules
echo.
echo --- Installing Conductor Rules ---
for %%R in (conductor_protocol.md conductor_jetski.md conductor_adr_preflight.md conductor_cdd_protocols.md) do (
    call :install_file "%SOURCE_RULES_DIR%\%%R" "%TARGET_RULES_ROOT%\%%R"
)

echo.
echo --- Summary ---
echo   Target:       antigravity
echo   Skills root:  %TARGET_SKILLS_ROOT%\conductor-*\
echo   Rules dir:    %TARGET_RULES_ROOT%
if "%FLAGS_dry_run%"=="1" ( echo   Dry run complete. ) else ( echo   Installation complete! )
call :check_for_updates
exit /b 0

:do_uninstall
echo --- Uninstalling Conductor ---
for %%S in (conductor-setup conductor-new-track conductor-implement conductor-status conductor-review conductor-revert conductor-chat) do (
    if exist "%TARGET_SKILLS_ROOT%\%%S" (
        if "%FLAGS_dry_run%"=="1" (
            echo Would remove: %TARGET_SKILLS_ROOT%\%%S
        ) else (
            rmdir /s /q "%TARGET_SKILLS_ROOT%\%%S"
            echo Removed: %TARGET_SKILLS_ROOT%\%%S
        )
    )
)
for %%R in (conductor_protocol.md conductor_jetski.md conductor_adr_preflight.md conductor_cdd_protocols.md) do (
    if exist "%TARGET_RULES_ROOT%\%%R" (
        if "%FLAGS_dry_run%"=="1" (
            echo Would remove: %TARGET_RULES_ROOT%\%%R
        ) else (
            del /q "%TARGET_RULES_ROOT%\%%R"
            echo Removed: %TARGET_RULES_ROOT%\%%R
        )
    )
)
echo Uninstall complete.
exit /b 0

:check_for_updates
echo.
if exist "%TARGET_SKILLS_ROOT%\conductor-setup\.conductor_version" (
    set /p INSTALLED_VERSION= < "%TARGET_SKILLS_ROOT%\conductor-setup\.conductor_version"
    if "!INSTALLED_VERSION!"=="%VERSION%" (
        echo   [OK] antigravity: Up to date (v!INSTALLED_VERSION!^)
    ) else (
        echo   [NEW] antigravity: Update available - v!INSTALLED_VERSION! -^> v%VERSION%
        echo   To update, run: install.bat --update
    )
) else (
    echo   No existing Conductor installations found.
    echo   Run install.bat to install.
)
exit /b 0

:install_file
set "source=%~1"
set "target=%~2"

for %%F in ("%target%") do set "target_dir=%%~dpF"
for %%F in ("%target%") do set "base_name=%%~nxF"

if not exist "%target_dir%" (
    if "%FLAGS_dry_run%"=="1" (
        echo Would create directory: %target_dir%
    ) else (
        mkdir "%target_dir%"
        echo Created directory: %target_dir%
    )
)

if exist "%target%" (
    fc "%source%" "%target%" >nul
    if not errorlevel 1 (
        echo %base_name% (already up-to-date)
        exit /b 0
    )
    if "%FLAGS_force%"=="0" (
        if "%FLAGS_dry_run%"=="1" (
            echo Would backup: %target% -^> %target%.bak
        ) else (
            copy /y "%target%" "%target%.bak" >nul
            echo Backed up: %base_name% -^> %base_name%.bak
        )
    )
)

if "%FLAGS_dry_run%"=="1" (
    echo Would install: %base_name%
) else (
    copy /y "%source%" "%target%" >nul
    echo Installed: %base_name%
)
exit /b 0
