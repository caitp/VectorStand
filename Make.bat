@echo off
setlocal
set "openscad_defines="

:parse_args
if "%~1"=="" goto run_openscad
if "%~1"=="--help" goto print_help
set "argument=%~1"
if "%argument:~0,1%"=="-" goto unrecognized_parameter
for /f "tokens=1,* delims==" %%A in ("%argument%") do if not "%%B"=="" set "openscad_defines=%openscad_defines% -D %%A=%%B"
shift
goto parse_args

:unrecognized_parameter
echo Error: unrecognized parameter "%~1"
exit /b 1

:print_help
set "help_file=%~dp0docs\help.txt"
if exist "%help_file%" (
    type %help_file%
)
exit /b 0

:run_openscad
call openscad "%~dp0gear_stand.scad" -o gear_stand.stl %openscad_defines%
exit /b %errorlevel%
