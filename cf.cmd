@echo off
rem Wrapper for cf (Choose Folder) in Command Prompt
for /f "delims=" %%i in ('python "%USERPROFILE%\.local\bin\cf\cf.py"') do (
    if exist "%%i" cd /d "%%i"
)
