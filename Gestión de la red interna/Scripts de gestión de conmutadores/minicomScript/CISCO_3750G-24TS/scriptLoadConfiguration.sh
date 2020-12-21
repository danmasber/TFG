#!/bin/sh

DIRECTORIO=$(dirname "$0")"/"
BORRAR_PASSWORD="FALSE"
BAUD_RESCUE=115200
TTY_SERIAL=/dev/ttyS0
BACKUP_CONFIGURCION="${DIRECTORIO}backup_configuracion"

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

			rm -f "${DIRECTORIO}MinicomScripts/"*.tmp
			exit "$salida"
		fi
	fi	
} 

mostrarAyuda(){
	BAUD_RESCUE=115200
	TTY_SERIAL=/dev/ttyS0
	BACKUP_CONFIGURCION="${DIRECTORIO}backup_configuracion.txt"
	echo "	El modo de usar el script es el siguiente"
	echo "		$0 [-h] [-?] -f ficheroConfiguration [-t tty_serie] [-b baudRescue] -p contraseña_manager"
	echo "	"
	echo "  -h -? 					Mostar ayuda"
	echo "	-f ficheroConfiguration	Indica el fichero de configuracion que se usara"
	echo "	-t tty_serie  			Indica el TTY  donde esta ubicado la conexion por puerto serie al switch"
	echo "	-b baudRescue  			Indica los baud con los cuales se ha iniciado el switch"
	echo "	-p contraseña_manager 	Indica la contraseña del administrador del switch"
	echo ""
	echo "	Los valores por defectos son "
	echo "		baudRescue=${BAUD_RESCUE}"
	echo "		tty_serie=${TTY_SERIAL}"
	echo "		ficheroConfiguration=${BACKUP_CONFIGURCION}"
	exit 1
}


#Comprobamos que se este instalado el comando minicom
command -v minicom > /dev/null  2>&1

comprobarEjecucion $(($?*2)) "Debe estar instalado minicom"

#Comprobamos que se este instalado el comando sx
command -v sx > /dev/null  2>&1
comprobarEjecucion $(($?*2)) "Debe estar instalado sx"

# Parsemos los argumentos introducido
while getopts ':b:f:t:d:p: ?hd' c
do
  case $c in
    b) BAUD_RESCUE="$OPTARG" ;;
    f) BACKUP_CONFIGURACION="$OPTARG" ;;
	t) TTY_SERIAL="$OPTARG" ;;
 	p) PASSWORD_MANAGER="$OPTARG" ;;
   	h|\?) mostrarAyuda "$0";;
  esac
done

if [ "${BACKUP_CONFIGURACION}" = "" ]; then
	mostrarAyuda "$0"
fi

if [ "$PASSWORD_MANAGER" = "" ]; then
	mostrarAyuda "$0"
fi

#	Creando el fichero las variables que existen en los template introducido a partir de los template
sed -e "s/PASSWORD_MANAGER/$PASSWORD_MANAGER/g"  \
             "${DIRECTORIO}MinicomScripts/scriptEnable.template" > "${DIRECTORIO}MinicomScripts/scriptEnable.tmp"

minicom -d  "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptEnable.tmp"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptEnable.tmp" 

rm -f "${DIRECTORIO}MinicomScripts/showBootSalida.tmp"

minicom -d "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptShowBoot" -C "${DIRECTORIO}MinicomScripts/showBootSalida.tmp"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptShowBoot" 

CONFIGURACION=$(grep "^Config file" "${DIRECTORIO}MinicomScripts/showBootSalida.tmp" | cut -d':' -f2-3 | tr -d ' /') 

if [ "$CONFIGURACION" = "" ]; then
	rm -f "${DIRECTORIO}MinicomScripts/showFlashSalida.tmp"
	minicom -d "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptShowFlash" -C "${DIRECTORIO}MinicomScripts/showFlashSalida.tmp"
	comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptShowFlash" 
	
	CONFIGURACION_VALIDO="FALSE"
	while [ "$CONFIGURACION_VALIDO" = "FALSE" ]; do
		echo "Introduce la localizacion del fichero de configuracion actual"
		head -n -2 "${DIRECTORIO}MinicomScripts/showFlashSalida.tmp" | tail -n +2

		read -r CONFIGURACION
		if sed -n 's/ \+/ / gp' "${DIRECTORIO}MinicomScripts/showFlashSalida.tmp" | cut -d' ' -f6 | grep "^$CONFIGURACION$" ; then
		 	CONFIGURACION_VALIDO="TRUE"
			CONFIGURACION="flash:${CONFIGURACION}"
		fi 
	done
fi


sed -e "s/CONFIGURACION/$CONFIGURACION/g"  \
             "${DIRECTORIO}MinicomScripts/scriptLoadConfiguration.template" > "${DIRECTORIO}MinicomScripts/scriptLoadConfiguration.tmp"
	

minicom -d  "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptStartModeRescue"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptStartModeRescue" 


minicom -d  "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptLoadConfiguration.tmp"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptLoadConfiguration.tmp" 

sx "${BACKUP_CONFIGURACION}" -vv < "$TTY_SERIAL" > "$TTY_SERIAL"
comprobarEjecucion $(($?*2)) "Al enviar el fichero ${BACKUP_CONFIGURACION}"
 
minicom -d  "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptInitSwitchFromRescue"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptInitSwitchFromRescue" 


rm -f "${DIRECTORIO}MinicomScripts/"*.tmp

echo "Finalizado $(dirname $0)"

