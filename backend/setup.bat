@echo off
setlocal

REM === Check Python ===
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo Python not found. Installing Python 3.12.10...
    curl -o python-installer.exe https://www.python.org/ftp/python/3.12.10/python-3.12.10-amd64.exe
    python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
)

REM === Ensure venv exists ===
if not exist myenv (
    echo Creating virtual environment...
    python -m venv myenv
)

REM === Activate venv ===
call myenv\Scripts\activate

REM === Install requirements ===
pip install --upgrade pip
pip install -r requirements.txt

echo Setup complete.
endlocal
