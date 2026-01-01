@echo off
setlocal

REM Activate venv
call myenv\Scripts\activate

REM Run server
python manage.py runserver

endlocal
