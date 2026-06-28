@echo off
setlocal EnableExtensions

set "ACTIVE_FILE=%~1"
if "%ACTIVE_FILE%"=="" (
    >&2 echo VS Code thesis render: open a .tex file inside thesis/ and press F5.
    exit /b 1
)

where wsl.exe >nul 2>nul
if errorlevel 1 (
    >&2 echo VS Code thesis render: wsl.exe was not found. Install WSL or open this repository in a WSL VS Code window.
    exit /b 1
)

set "SCRIPT_WIN=%~dp0render-active-tex.sh"
set "DISTRO="
set "UNC_PATH=%SCRIPT_WIN%"
if "%UNC_PATH:~0,2%"=="\\" set "UNC_PATH=%UNC_PATH:~2%"
set "SCRIPT_REST="
for /f "tokens=1,2,* delims=\" %%A in ("%UNC_PATH%") do (
    if /I "%%A"=="wsl.localhost" (
        set "DISTRO=%%B"
        set "SCRIPT_REST=%%C"
    )
    if /I "%%A"=="wsl$" (
        set "DISTRO=%%B"
        set "SCRIPT_REST=%%C"
    )
)

if defined THESIS_VSCODE_DEBUG (
    echo SCRIPT_WIN=[%SCRIPT_WIN%]
    echo UNC_PATH=[%UNC_PATH%]
    echo DISTRO=[%DISTRO%]
)

if defined SCRIPT_REST set "SCRIPT_WSL=/%SCRIPT_REST:\=/%"

set "ACTIVE_UNC_PATH=%ACTIVE_FILE%"
if "%ACTIVE_UNC_PATH:~0,2%"=="\\" set "ACTIVE_UNC_PATH=%ACTIVE_UNC_PATH:~2%"
set "ACTIVE_FILE_REST="
for /f "tokens=1,2,* delims=\" %%A in ("%ACTIVE_UNC_PATH%") do (
    if /I "%%A"=="wsl.localhost" set "ACTIVE_FILE_REST=%%C"
    if /I "%%A"=="wsl$" set "ACTIVE_FILE_REST=%%C"
)

if defined ACTIVE_FILE_REST set "ACTIVE_FILE_WSL=/%ACTIVE_FILE_REST:\=/%"

if not defined SCRIPT_WSL if defined DISTRO (
    for /f "usebackq delims=" %%I in (`wsl.exe -d %DISTRO% wslpath -u "%SCRIPT_WIN%"`) do set "SCRIPT_WSL=%%I"
)
if not defined ACTIVE_FILE_WSL if defined DISTRO (
    for /f "usebackq delims=" %%I in (`wsl.exe -d %DISTRO% wslpath -u "%ACTIVE_FILE%"`) do set "ACTIVE_FILE_WSL=%%I"
)

if not defined SCRIPT_WSL (
    for /f "usebackq delims=" %%I in (`wsl.exe wslpath -u "%SCRIPT_WIN%"`) do set "SCRIPT_WSL=%%I"
)
if not defined ACTIVE_FILE_WSL (
    for /f "usebackq delims=" %%I in (`wsl.exe wslpath -u "%ACTIVE_FILE%"`) do set "ACTIVE_FILE_WSL=%%I"
)

if not defined SCRIPT_WSL (
    >&2 echo VS Code thesis render: failed to convert helper path to a WSL path.
    exit /b 1
)

if not defined ACTIVE_FILE_WSL (
    >&2 echo VS Code thesis render: failed to convert active file path to a WSL path.
    exit /b 1
)

if defined DISTRO (
    if defined THESIS_VSCODE_NO_BROWSER (
        wsl.exe -d %DISTRO% env THESIS_VSCODE_NO_BROWSER="%THESIS_VSCODE_NO_BROWSER%" bash "%SCRIPT_WSL%" "%ACTIVE_FILE_WSL%"
    ) else (
        wsl.exe -d %DISTRO% bash "%SCRIPT_WSL%" "%ACTIVE_FILE_WSL%"
    )
) else (
    if defined THESIS_VSCODE_NO_BROWSER (
        wsl.exe env THESIS_VSCODE_NO_BROWSER="%THESIS_VSCODE_NO_BROWSER%" bash "%SCRIPT_WSL%" "%ACTIVE_FILE_WSL%"
    ) else (
        wsl.exe bash "%SCRIPT_WSL%" "%ACTIVE_FILE_WSL%"
    )
)

exit /b %ERRORLEVEL%
