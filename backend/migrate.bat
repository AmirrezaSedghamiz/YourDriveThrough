@echo off
setlocal

REM Activate venv
call myenv\Scripts\activate

REM Migrate database
python manage.py makemigrations
python manage.py migrate

endlocal