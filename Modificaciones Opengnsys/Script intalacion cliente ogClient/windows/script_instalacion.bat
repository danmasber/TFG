@echo off
cls

SET /P IPSERVIDOR="Introduce IPv4 del servidor: "
ping -n 1 -4 %IPSERVIDOR% > nul 2> nul
if errorlevel 1 (
   echo La IPv4 seleccionada no es valida
   exit /b %errorlevel%
)

SET CARPETAx64="C:\Program Files (x86)\OGAgent\cfg"
SET CARPETAx32="C:\Program Files\OGAgent\cfg"



FOR /f %%i in ('DIR /B OGAgentSetup*.exe') do set INSTALADOR=%%i

echo ========= Ejecuatamos el instalador =========
echo.
echo Recuerde que si al instalar cambia la ruta por defecto no se modificara correctamente el archivo de configuracion
echo.
%INSTALADOR%

if errorlevel 1 (
  echo Se cancelo o fallo el instalador
  exit /b %errorlevel%
)


echo ========= Ejecuatamos la edicion de la cofiguracion =========
echo.
IF EXIST %CARPETAx64% (
	sed.exe -i "0,/remote=/ s,remote=.*,remote=https://%IPSERVIDOR%/opengnsys/rest/,"  "%CARPETAx64:"=%\ogagent.cfg"
) ELSE IF EXIST %CARPETAx32% (
	sed.exe -i "0,/remote=/ s,remote=.*,remote=https://%IPSERVIDOR%/opengnsys/rest/," "%CARPETAx32:"=%\ogagent.cfg"
)

if errorlevel 1 (
   echo Fallo la edicion de la cofiguracion
   exit /b %errorlevel%
)

echo ========= Iniciar el servicio de OGAgent =========
echo.

NET START OGAgent

if errorlevel 1 (
   echo Fallo la iniciar el servicio
   exit /b %errorlevel%
)
