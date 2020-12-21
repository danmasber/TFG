#!/bin/sh

DIRECTORIO=$(dirname "$0")"/"
BORRAR_PASSWORD="FALSE"
BAUD_RESCUE=115200
TTY_SERIAL=/dev/ttyS0

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
	echo "	-t tty_serie  			Indica el TTY  donde esta ubicado la conexion por puerto serie al switch"
	echo "	-b baudRescue  			Indica los baud con los cuales se ha iniciado el switch"
	echo "	-p contraseña_manager 	Indica la contraseña del administrador del switch"
	echo ""
	echo "	Los valores por defectos son "
	echo "		baudRescue=${BAUD_RESCUE}"
	echo "		tty_serie=${TTY_SERIAL}"
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
	t) TTY_SERIAL="$OPTARG" ;;
 	p) PASSWORD_MANAGER="$OPTARG" ;;
   	h|\?) mostrarAyuda "$0";;
  esac
done

if [ "$PASSWORD_MANAGER" = "" ]; then
	mostrarAyuda "$0"
fi

#	Creando el fichero las variables que existen en los template introducido a partir de los template
sed -e "s/PASSWORD_MANAGER/$PASSWORD_MANAGER/g"  \
             "${DIRECTORIO}MinicomScripts/scriptEnable.template" > "${DIRECTORIO}MinicomScripts/scriptEnable.tmp"

minicom -d  "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptEnable.tmp"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptEnable.tmp" 

rm -f "${DIRECTORIO}MinicomScripts/scriptEnable.tmp"

minicom -d "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptEnableManagementWeb" 
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptEnableManagementWeb" 

echo "Finalizado $(dirname $0)"

