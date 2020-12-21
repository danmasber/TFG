#!/bin/sh

# $(($?*2)) es porque cerramos minicom con la señal 15  que proboca salida con exit 1

DIRECTORIO=$(dirname "$0")"/"
BORRAR_PASSWORD="FALSE"
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

			rm -f "${DIRECTORIO}MinicomScripts"*.tmp		
			clear
			exit "$salida"
		fi
	fi	
} 

mostrarAyuda(){
	BAUD_INICIALES=9600
	TTY_SERIAL=/dev/ttyS0
	echo "	El modo de usar el script es el siguiente"
	echo "		$0 [-?] [-h] -f ficheroFirmware [-t tty_serie] [-b baudIncial] [-d] [-r] -u usuario_manager -p contrasena_manager"
	echo "	"
	echo "  -h -? 					Mostar ayuda"
	echo "	-t ficheroFirmware		Indica el fichero de firmware  que se usara"
	echo "	-t tty_serie  			Indica el TTY  donde esta ubicado la conexion por puerto serie al switch"
	echo "	-b baudIncial  			Indica los baud con los cuales se ha iniciado el switch"
	echo "	-r   					Indica que se inicia desde modo Rescue por lo cual no seria necesario ni usuario_manager ni contrasena_manager"
	echo "	-u usuario_manager  	Indica el usuario del administrador del switch"
	echo "	-p contrasena_manager 	Indica la contraseña del administrador del switch"
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
while getopts ':b:f:t:u:p: ?hr' c
do
  case $c in
	b) BAUD_INICIALES="$OPTARG" ;;
    f) FIRMWARE="$OPTARG" ;;
	r) MODO_RESCUE="TRUE" ;;
	t) TTY_SERIAL="$OPTARG" ;;
 	u) USUARIO_MANAGER="$OPTARG" ;;
 	p) PASSWORD_MANAGER="$OPTARG" ;;
    h|\?) mostrarAyuda "$0";;
  esac
done

if [ "$FIRMWARE" = "" ]; then
	mostrarAyuda "$0"
fi
if [ "$MODO_RESCUE" = "TRUE" ]; then
	if [ "$USUARIO_MANAGER" = "" ]; then
		mostrarAyuda "$0"
	fi
	if [ "$PASSWORD_MANAGER" = "" ]; then
		mostrarAyuda "$0"
	fi
fi
#	Creando el fichero con la contraseña y usuario introducido a partir de los template
sed -e "s/USUARIO_MANAGER/$USUARIO_MANAGER/g" \
        -e "s/PASSWORD_MANAGER/$PASSWORD_MANAGER/g"  \
             "${DIRECTORIO}MinicomScripts/scriptReset.template" > "${DIRECTORIO}MinicomScripts/scriptReset.tmp"

if [ "$MODO_RESCUE" != "TRUE" ]; then
	minicom -d  "$TTY_SERIAL" -b "$BAUD_INICIALES" -S "${DIRECTORIO}MinicomScripts/scriptReset.tmp"
	comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptReset.tmp" 
fi

minicom -d  "$TTY_SERIAL" -b "$BAUD_INICIALES" -S "${DIRECTORIO}MinicomScripts/scriptChangeBaud115200"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptChangeBaud115200"

minicom -d  "$TTY_SERIAL" -b 115200 -S "${DIRECTORIO}MinicomScripts/scriptStartUploadFirmware"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptStartUploadFirmware"


sx "${FIRMWARE}" -vv > "$TTY_SERIAL" < "$TTY_SERIAL"
comprobarEjecucion $(($?*2)) "Al enviar el fichero ${FIRMWARE}"
 
minicom -d  "$TTY_SERIAL" -b 115200 -S "${DIRECTORIO}MinicomScripts/scriptEndUploadFirmware"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptEndUploadFirmware"

rm -f "${{DIRECTORIO}}MinicomScripts"*.tmp	

echo "Finalizado $(basename $0)"

