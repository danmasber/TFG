#!/bin/sh

# $(($?*2)) es porque cerramos minicom con la señal 15  que proboca salida con exit 1

DIRECTORIO=$(dirname "$0")"/"
BAUD_INICIALES=9600      
TTY_SERIAL=/dev/ttyS0

#Comprobamos que se ejecute el script como root para poder acceder a minicom
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 127 "Se requieren pesmisos de administrador para continuar con el script"
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

			rm -f "${{DIRECTORIO}}MinicomScripts"*.tmp		
			clear
			exit "$salida"
		fi
	fi	
} 

mostrarAyuda(){
	BAUD_INICIALES=9600
	TTY_SERIAL=/dev/ttyS0
	FICHERO_CONFIGURCION="${DIRECTORIO}backup_configuracion"
	echo "	El modo de usar el script es el siguiente"
	echo " 	$0 [-h] [-?] [-t tty_serie] [-b baudIncial] [-u usuario_manager] [-p contraseña_manager]"
	echo ""
	echo "  -h -? 					Mostar ayuda"
	echo "	-t tty_serie  			Indica el TTY  donde esta ubicado la conexion por puerto serie al switch"
	echo "	-b baudIncial  			Indica los baud con los cuales se ha iniciado el switch"
	echo "	-u usuario_manager  	Indica el usuario del administrador del switch"
	echo "	-p contraseña_manager 	Indica la contraseña del administrador del switch"
	echo ""
	echo "	 Si el switch no posee usuario y contraseña administrador se ignorá los argumentos "
	echo "	 usuario_manager y contraseña_manager"
	echo ""
	echo "	Los valores por defectos son "
	echo "		baudIncial=${BAUD_INICIALES}"
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
while getopts ':b:t:u:p: ?h' c
do
  case $c in
    b) BAUD_INICIALES="$OPTARG" ;;
	t) TTY_SERIAL="$OPTARG" ;;
 	u) USUARIO_MANAGER="$OPTARG" ;;
 	p) PASSWORD_MANAGER="$OPTARG" ;;
   	h|\?) mostrarAyuda "$0";;
  esac
done

#Creando los ficheros con la contraseña y usuario introducido a partir de los template
sed -e "s/USUARIO_MANAGER/$USUARIO_MANAGER/g" \
        -e "s/PASSWORD_MANAGER/$PASSWORD_MANAGER/g"  \
             "${DIRECTORIO}MinicomScripts/scriptEnableManagementWeb.template" > "${DIRECTORIO}MinicomScripts/scriptEnableManagementWeb.tmp"


minicom -d  "$TTY_SERIAL" -b "$BAUD_INICIALES" -S "${DIRECTORIO}MinicomScripts/scriptEnableManagementWeb.tmp"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptEnableManagementWeb.tmp"

rm -f "${{DIRECTORIO}}MinicomScripts"*.tmp	

echo "Finalizado $(basename $0)"




