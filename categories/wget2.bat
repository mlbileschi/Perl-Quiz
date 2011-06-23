:: A windows alias for wget. 

@echo off
:: %* is used to pass the remainder of the CL args to wget.exe
C:\PROGRA~2\GnuWin32\bin\wget.exe --quiet %* 2> NUL