:: A simple DOS Batch script to start setiathome.exe 
:: and sleep for x number of seconds
:: Luis Mondesi <lemsx1@hotmail.com> 
@echo off
set SLEEP=14400
set SETI="c:\program files\seti"
cd %SETI% || exit 1
:: we loop forever here:
:start
    setiathome
    :: stupid DOS has no 'sleep'
    ping -n %SLEEP% localhost > nul
goto start
