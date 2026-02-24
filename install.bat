@echo off
setlocal EnableDelayedExpansion
:: =============================================================================
:: Antigravity Conductor Skills & Workflows Installer (Windows)
:: =============================================================================

set "VERSION=0.2.0"
set "FLAGS_dry_run=0"
set "FLAGS_force=0"
set "FLAGS_uninstall=0"

:: Parse arguments
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--dry_run" ( set "FLAGS_dry_run=1" & shift & goto :parse_args )
if /i "%~1"=="--force" ( set "FLAGS_force=1" & shift & goto :parse_args )
if /i "%~1"=="--uninstall" ( set "FLAGS_uninstall=1" & shift & goto :parse_args )
if /i "%~1"=="--help" ( goto :show_help )
if /i "%~1"=="-h" ( goto :show_help )
echo Unknown argument: %~1
exit /b 1

:show_help
echo Usage: install.bat [OPTIONS]
echo   --dry_run    Preview changes without writing files
echo   --force      Overwrite existing files without backup
echo   --uninstall  Remove all installed files
echo   --help, -h   Show this help message
exit /b 0

:args_done

set "SCRIPT_DIR=%~dp0"
:: Remove trailing backslash
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "SOURCE_SKILL_DIR=%SCRIPT_DIR%\skills\conductor"
set "SOURCE_WORKFLOW_DIR=%SCRIPT_DIR%\workflows"

set "TARGET_SKILL_DIR=%USERPROFILE%\.gemini\antigravity\skills\conductor"
set "TARGET_WORKFLOW_DIR=%USERPROFILE%\.gemini\antigravity\global_workflows"

set "ALL_TARGET_FILES[0]=%TARGET_SKILL_DIR%\SKILL.md"
set "ALL_TARGET_FILES[1]=%TARGET_WORKFLOW_DIR%\conductor_implement.md"
set "ALL_TARGET_FILES[2]=%TARGET_WORKFLOW_DIR%\conductor_newTrack.md"
set "ALL_TARGET_FILES[3]=%TARGET_WORKFLOW_DIR%\conductor_revert.md"
set "ALL_TARGET_FILES[4]=%TARGET_WORKFLOW_DIR%\conductor_review.md"
set "ALL_TARGET_FILES[5]=%TARGET_WORKFLOW_DIR%\conductor_setup.md"
set "ALL_TARGET_FILES[6]=%TARGET_WORKFLOW_DIR%\conductor_status.md"

echo.
echo   ==================================================
echo     Antigravity Conductor Installer (Windows) v%VERSION%
echo   ==================================================
echo.

if "%FLAGS_uninstall%"=="1" goto :do_uninstall

:: Validate sources
if not exist "%SOURCE_SKILL_DIR%\SKILL.md" ( echo [ERROR] Missing %SOURCE_SKILL_DIR%\SKILL.md & exit /b 1 )
for %%W in (implement newTrack revert review setup status) do (
    if not exist "%SOURCE_WORKFLOW_DIR%\conductor_%%W.md" ( echo [ERROR] Missing %SOURCE_WORKFLOW_DIR%\conductor_%%W.md & exit /b 1 )
)

if "%FLAGS_dry_run%"=="1" echo   [DRY RUN MODE - no files will be written]

:: Skill
echo.
echo --- Installing Conductor Skill ---
call :install_file "%SOURCE_SKILL_DIR%\SKILL.md" "%TARGET_SKILL_DIR%\SKILL.md"

:: Workflows
echo.
echo --- Installing Conductor Workflows ---
for %%W in (implement newTrack revert review setup status) do (
    call :install_file "%SOURCE_WORKFLOW_DIR%\conductor_%%W.md" "%TARGET_WORKFLOW_DIR%\conductor_%%W.md"
)

echo.
echo --- Summary ---
echo   Target:       antigravity
echo   Skill dir:    %TARGET_SKILL_DIR%
echo   Workflow dir: %TARGET_WORKFLOW_DIR%
if "%FLAGS_dry_run%"=="1" ( echo   Dry run complete. ) else ( echo   Installation complete! )
exit /b 0

:do_uninstall
echo --- Uninstalling Conductor ---
set "removed=0"
for /L %%i in (0,1,6) do (
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
if exist "%TARGET_SKILL_DIR%" (
    dir /b /a "%TARGET_SKILL_DIR%" | findstr "^" >nul || (
        if "%FLAGS_dry_run%"=="1" (
            echo Would remove empty directory: %TARGET_SKILL_DIR%
        ) else (
            rmdir "%TARGET_SKILL_DIR%"
            echo Cleaned up empty directory.
        )
    )
)
echo Uninstalled %removed% file(s).
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
