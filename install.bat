@echo off
setlocal EnableDelayedExpansion
:: =============================================================================
:: Antigravity Conductor Skills & Rules Installer (Windows)
:: =============================================================================

set "VERSION=0.3.0"
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
:: Remove trailing backslash
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "SOURCE_TEMPLATE_DIR=%SCRIPT_DIR%\skills\conductor_setup\templates"
set "SOURCE_RULES_DIR=%SCRIPT_DIR%\rules"

set "TARGET_SKILLS_ROOT=%USERPROFILE%\.gemini\antigravity\skills"
set "TARGET_TEMPLATE_DIR=%TARGET_SKILLS_ROOT%\conductor_setup\templates"
set "TARGET_RULES_ROOT=%USERPROFILE%\.gemini\antigravity\rules"

set "ALL_TARGET_FILES[0]=%TARGET_TEMPLATE_DIR%\workflow_template.md"
set "ALL_TARGET_FILES[1]=%TARGET_TEMPLATE_DIR%\adr_template.md"
set "ALL_TARGET_FILES[2]=%TARGET_SKILLS_ROOT%\conductor_setup\.conductor_version"
set "ALL_TARGET_FILES[3]=%TARGET_SKILLS_ROOT%\conductor_setup\SKILL.md"
set "ALL_TARGET_FILES[4]=%TARGET_SKILLS_ROOT%\conductor_newTrack\SKILL.md"
set "ALL_TARGET_FILES[5]=%TARGET_SKILLS_ROOT%\conductor_newTrack_grill\SKILL.md"
set "ALL_TARGET_FILES[6]=%TARGET_SKILLS_ROOT%\conductor_newTrack_discovery\SKILL.md"
set "ALL_TARGET_FILES[7]=%TARGET_SKILLS_ROOT%\conductor_implement\SKILL.md"
set "ALL_TARGET_FILES[8]=%TARGET_SKILLS_ROOT%\conductor_status\SKILL.md"
set "ALL_TARGET_FILES[9]=%TARGET_SKILLS_ROOT%\conductor_review\SKILL.md"
set "ALL_TARGET_FILES[10]=%TARGET_SKILLS_ROOT%\conductor_revert\SKILL.md"
set "ALL_TARGET_FILES[11]=%TARGET_SKILLS_ROOT%\conductor_chat\SKILL.md"

echo.
echo   ==================================================
echo     Antigravity Conductor Installer (Windows) v%VERSION%
echo   ==================================================
echo.

if "%FLAGS_update%"=="1" (
    set "FLAGS_force=1"
    if exist "%TARGET_SKILLS_ROOT%\conductor_setup\.conductor_version" (
        set /p INSTALLED_VERSION= < "%TARGET_SKILLS_ROOT%\conductor_setup\.conductor_version"
        if "!INSTALLED_VERSION!"=="%VERSION%" (
            echo Already up to date (v%VERSION%^)
            exit /b 0
        )
        echo   Installed: v!INSTALLED_VERSION! -^> v%VERSION%
    ) else if exist "%TARGET_SKILLS_ROOT%\conductor_setup\SKILL.md" (
        echo   Installed: pre-v0.2.1 (legacy) -^> v%VERSION%
    ) else if exist "%TARGET_SKILLS_ROOT%\conductor\SKILL.md" (
        echo   Installed: pre-v0.3.0 (hub skill) -^> v%VERSION%
        echo   The hub skill will be migrated automatically.
    ) else (
        echo   No existing installation found. Performing fresh install.
    )
    echo.
)

if "%FLAGS_uninstall%"=="1" goto :do_uninstall

:: Validate sources
if not exist "%SOURCE_TEMPLATE_DIR%\workflow_template.md" ( echo [ERROR] Missing %SOURCE_TEMPLATE_DIR%\workflow_template.md & exit /b 1 )
for %%S in (conductor_setup conductor_newTrack conductor_newTrack_grill conductor_newTrack_discovery conductor_implement conductor_status conductor_review conductor_revert conductor_chat) do (
    if not exist "%SCRIPT_DIR%\skills\%%S\SKILL.md" ( echo [ERROR] Missing %SCRIPT_DIR%\skills\%%S\SKILL.md & exit /b 1 )
)

if "%FLAGS_dry_run%"=="1" echo   [DRY RUN MODE - no files will be written]

:: Migrate hub skill (pre-v0.3.0)
if exist "%TARGET_SKILLS_ROOT%\conductor\SKILL.md" (
    echo.
    echo --- Hub Skill Migration (v0.3.0) ---
    if exist "%TARGET_SKILLS_ROOT%\conductor\.conductor_version" (
        if not exist "%TARGET_SKILLS_ROOT%\conductor_setup" mkdir "%TARGET_SKILLS_ROOT%\conductor_setup"
        if "%FLAGS_dry_run%"=="1" (
            echo Would migrate version stamp from conductor\ to conductor_setup\
        ) else (
            move /y "%TARGET_SKILLS_ROOT%\conductor\.conductor_version" "%TARGET_SKILLS_ROOT%\conductor_setup\.conductor_version" >nul
            echo Migrated version stamp to conductor_setup\.conductor_version
        )
    )
    if "%FLAGS_dry_run%"=="1" (
        echo Would remove hub skill directory: %TARGET_SKILLS_ROOT%\conductor\
    ) else (
        rmdir /s /q "%TARGET_SKILLS_ROOT%\conductor"
        echo Removed legacy hub skill directory.
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
    if not exist "%TARGET_SKILLS_ROOT%\conductor_setup" mkdir "%TARGET_SKILLS_ROOT%\conductor_setup"
    echo %VERSION%> "%TARGET_SKILLS_ROOT%\conductor_setup\.conductor_version"
    echo Wrote version stamp: v%VERSION%
)

:: Sub-Skills
echo.
echo --- Installing Conductor Command Skills ---
for %%S in (conductor_setup conductor_newTrack conductor_newTrack_grill conductor_newTrack_discovery conductor_implement conductor_status conductor_review conductor_revert conductor_chat) do (
    call :install_file "%SCRIPT_DIR%\skills\%%S\SKILL.md" "%TARGET_SKILLS_ROOT%\%%S\SKILL.md"
)

:: Rules
echo.
echo --- Installing Conductor Rules ---
for %%R in (conductor_protocol.md conductor_antigravity.md) do (
    call :install_file "%SOURCE_RULES_DIR%\%%R" "%TARGET_RULES_ROOT%\%%R"
)
:: Reference files
for %%R in (conductor_adr_preflight.md conductor_cdd_protocols.md) do (
    call :install_file "%SOURCE_RULES_DIR%\%%R" "%TARGET_RULES_ROOT%\%%R"
)

echo.
echo --- Summary ---
echo   Target:       antigravity
echo   Skills:       %TARGET_SKILLS_ROOT%\conductor_*\
echo   Rules:        %TARGET_RULES_ROOT%\
if "%FLAGS_dry_run%"=="1" ( echo   Dry run complete. ) else ( echo   Installation complete! )
call :check_for_updates
exit /b 0

:do_uninstall
echo --- Uninstalling Conductor ---
set "removed=0"
for /L %%i in (0,1,11) do (
    if exist "!ALL_TARGET_FILES[%%i]!" (
        if "%FLAGS_dry_run%"=="1" (
            echo Would remove: !ALL_TARGET_FILES[%%i]!
        ) else (
            del /q "!ALL_TARGET_FILES[%%i]!"
            echo Removed: !ALL_TARGET_FILES[%%i]!
        )
        set /a "removed+=1"
    )
)
if exist "%TARGET_TEMPLATE_DIR%" (
    dir /b /a "%TARGET_TEMPLATE_DIR%" | findstr "^" >nul || (
        if "%FLAGS_dry_run%"=="1" (
            echo Would remove empty directory: %TARGET_TEMPLATE_DIR%
        ) else (
            rmdir "%TARGET_TEMPLATE_DIR%"
            echo Cleaned up empty templates directory.
        )
    )
)
echo Uninstalled %removed% file(s).
exit /b 0

:check_for_updates
echo.
if exist "%TARGET_SKILLS_ROOT%\conductor_setup\.conductor_version" (
    set /p INSTALLED_VERSION= < "%TARGET_SKILLS_ROOT%\conductor_setup\.conductor_version"
    if "!INSTALLED_VERSION!"=="%VERSION%" (
        echo   [OK] antigravity: Up to date (v!INSTALLED_VERSION!^)
    ) else (
        echo   [NEW] antigravity: Update available - v!INSTALLED_VERSION! -^> v%VERSION%
        echo   To update, run: install.bat --update
    )
) else if exist "%TARGET_SKILLS_ROOT%\conductor_setup\SKILL.md" (
    echo   [NEW] antigravity: Legacy install detected (pre-v0.2.1) - update to v%VERSION%
    echo   To update, run: install.bat --update
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
