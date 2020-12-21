#!/bin/sh

DIRECTORIO=$(dirname "$0")"/"
BORRAR_PASSWORD="FALSE"
BAUD_RESCUE=115200
TTY_SERIAL=/dev/ttyS0
FIRMWARE="${DIRECTORIO}firware.bin"

#Comprobamos que se ejecute el script como root para poder acceder a virsh
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 127 "Se requieren pesmisos de administrador para continuar con el menu"
fi

# La funcion comprobarEjecucion evalua si hubo un error al ejecutar el ultimo comando y muestra un mensaje de lo ocurrido.
# Si ocurrio un error provoca la salida del script		
# Tambien borrar los archivos creado apatir del template para añadir usuario y contraseña de administrador
# ENTRADA salida del comando y mensaje a mostrar 
# SALIDA ninguna
comprobarEjecucion(){
	salida=$1
	mensaje=$2
	if [ "$salida" != "0" ]; then
		if [ "$salida" != "1" ]; then
			if [ "$mensaje" != "" ]; then
				echo "ERROR: $mensaje"
			fi

			rm -f "${DIRECTORIO}MinicomScripts"*.tmp		
			clear
			exit "$salida"
		fi
	fi	
} 

mostrarAyuda(){
	BAUD_RESCUE=115200
	TTY_SERIAL=/dev/ttyS0
	FIRMWARE="${DIRECTORIO}firware.bin"
	echo "	El modo de usar el script es el siguiente"
	echo "		$0 [-h] [-?] -f ficheroFirmware [-t tty_serie] [-b baudRescue] [-d] -p contraseña_manager"
	echo "	"
	echo "  -h -? 					Mostar ayuda"
	echo "	-f ficheroFirmware		Indica el fichero de firmware  que se usara"
	echo "	-t tty_serie  			Indica el TTY donde esta ubicado la conexion por puerto serie al switch"
	echo "	-b baudRescue  			Indica los baud con los cuales se ha iniciado el switch"
	echo "	-d 						Indica si se eliminará las contraseñas y configuracion en el proceso"
	echo "	-p contraseña_manager 	Indica la contraseña del administrador del switch"
	echo ""
	echo "	Los valores por defectos son "
	echo "		baudRescue=${BAUD_RESCUE}"
	echo "		tty_serie=${TTY_SERIAL}"
	echo "		ficheroFirmware=${FIRMWARE}"
	exit 1
}


#Comprobamos que se este instalado el comando minicom
command -v minicom > /dev/null  2>&1

comprobarEjecucion $(($?*2)) "Debe estar instalado minicom"

#Comprobamos que se este instalado el comando sx
command -v sx > /dev/null  2>&1
comprobarEjecucion $(($?*2)) "Debe estar instalado sx"

# Parsemos los argumentos introducido
while getopts ':b:f:t:b:p: ?hd' c
do
  case $c in
   	b) BAUD_RESCUE="$OPTARG" ;;
    f) FIRMWARE="$OPTARG" ;;
    d) BORRAR_PASSWORD="TRUE" ;;
	t) TTY_SERIAL="$OPTARG" ;;
 	p) PASSWORD_MANAGER="$OPTARG" ;;
    h|\?) mostrarAyuda "$0";;
  esac
done

if [ "${FIRMWARE}" = "" ]; then
	mostrarAyuda "$0"
fi

if [ "$PASSWORD_MANAGER" = "" ]; then
	mostrarAyuda "$0"
fi

#	Creando el fichero las variables que existen en los template introducido a partir de los template
sed -e "s/PASSWORD_MANAGER/$PASSWORD_MANAGER/g"  \
             "${DIRECTORIO}MinicomScripts/scriptEnable.template" > "${DIRECTORIO}MinicomScripts/scriptEnable.tmp"

FIRMWARE_BASENAME=$(basename "$FIRMWARE")

sed -e "s/FIRMWARE/$FIRMWARE_BASENAME/g"  
             "${DIRECTORIO}MinicomScripts/scriptEndUploadFirmware.template" > "${DIRECTORIO}MinicomScripts/scriptEndUploadFirmware.tmp"



minicom -d  "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptEnable.tmp"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptEnable.tmp" 

rm -f "${DIRECTORIO}MinicomScripts/showBootSalida.tmp"

minicom -d "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptShowBoot" -C "${DIRECTORIO}MinicomScripts/showBootSalida.tmp"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptShowBoot" 

OLD_FIRWARE=$(grep "BOOT path-list" "${DIRECTORIO}MinicomScripts/showBootSalida.tmp" | cut -d':' -f2-3 | tr -d ' /') 

if [ "$OLD_FIRWARE" = "" ]; then
	rm -f "${DIRECTORIO}MinicomScripts/showFlashSalida.tmp"
	minicom -d "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptShowFlash" -C "${DIRECTORIO}MinicomScripts/showFlashSalida.tmp"
	comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptShowFlash" 
	OLD_FIRWARE_VALIDO="FALSE"
	while [ "$OLD_FIRWARE_VALIDO" = "FALSE" ]; do
		echo "Introduce la localizacion del actual firmware"
		head -n -2 "${DIRECTORIO}MinicomScripts/showFlashSalida.tmp" | tail -n +2

		read -r OLD_FIRWARE

		if sed -n 's/ \+/ / gp' "${DIRECTORIO}MinicomScripts/showFlashSalida.tmp" | cut -d' ' -f6 | grep "^$OLD_FIRWARE$"; then
		 	OLD_FIRWARE_VALIDO="TRUE"
			OLD_FIRWARE="flash:${OLD_FIRWARE}"
		fi 
	done
fi

sed -e "s/OLD/$OLD_FIRWARE/g"   \
	-e "s/FIRMWARE/$FIRMWARE_BASENAME/g"   \
             "${DIRECTORIO}MinicomScripts/scriptStartUploadFirmware.template" > "${DIRECTORIO}MinicomScripts/scriptStartUploadFirmware.tmp"


minicom -d  "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptStartModeRescue"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptStartModeRescue" 

## No funciona el borrado del anterior
if [ "$BORRAR_PASSWORD" = "TRUE" ]; then
	CONFIGURACION=$(grep "^Config file" "${DIRECTORIO}MinicomScripts/showBootSalida.tmp" |  cut -d':' -f2-3 | tr -d ' /') 

	if [ "$CONFIGURACION" = "" ]; then
		rm -f "${DIRECTORIO}MinicomScripts/showFlashSalida.tmp"
		minicom -d "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptShowFlash" -C "${DIRECTORIO}MinicomScripts/showFlashSalida.tmp"
		comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptShowFlash" 
		
		CONFIGURACION_VALIDO="FALSE"
		while [ "$CONFIGURACION_VALIDO" = "FALSE" ]; do
			echo "Introduce la localizacion del fichero de configuracion actual"
			head -n -2 "${DIRECTORIO}MinicomScripts/showFlashSalida.tmp" | tail -n +2

			read -r CONFIGURACION
			
			if sed -n 's/ \+/ / gp' "${DIRECTORIO}MinicomScripts/showFlashSalida.tmp" | cut -d' ' -f6 | grep "^$CONFIGURACION$"; then
			 	CONFIGURACION_VALIDO="TRUE"
			fi 
		done
	fi

	sed -e "s/CONFIGURACION/$CONFIGURACION/g"  \
             "${DIRECTORIO}MinicomScripts/scriptRemovePasswordAndConfig.template" > "${DIRECTORIO}MinicomScripts/scriptRemovePasswordAndConfig.tmp"


	minicom -d  "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptRemovePasswordAndConfig.tmp"
	comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptRemovePasswordAndConfig.tmp"
fi



minicom -d  "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptStartUploadFirmware.tmp"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptStartUploadFirmware.tmp" 

sx "${FIRMWARE}" -vv < "$TTY_SERIAL" > "$TTY_SERIAL"
comprobarEjecucion $(($?*2)) "Al enviar el fichero ${FIRMWARE}"
 

minicom -d  "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptEndUploadFirmware.tmp"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptEndUploadFirmware.tmp" 

 
minicom -d  "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptInitSwitchFromRescue"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptInitSwitchFromRescue" 

rm -f "${DIRECTORIO}MinicomScripts"*.tmp

echo "Finalizado $(dirname "$0")"


