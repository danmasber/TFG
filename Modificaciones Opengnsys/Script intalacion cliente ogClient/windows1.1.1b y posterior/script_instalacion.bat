@echo off
cls

SET /P IPSERVIDOR="Introduce IPv4 del servidor: "
ping -n 1 -4 %IPSERVIDOR% > nul 2> nul
if errorlevel 1 (
   echo La IPv4 seleccionada no es valida
   exit /b %errorlevel%
)


FOR /f %%i in ('DIR /B OGAgentSetup*.exe') do set INSTALADOR=%%i

echo ========= Ejecuatamos el instalador =========
%INSTALADOR% /S /server %IPSERVIDOR%

if errorlevel 1 (
  echo Se cancelo o fallo el instalador
  exit /b %errorlevel%
)
