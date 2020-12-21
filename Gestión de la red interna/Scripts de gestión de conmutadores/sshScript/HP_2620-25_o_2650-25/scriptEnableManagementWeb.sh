#!/bin/sh

DIRECTORIO=$(dirname "$0")"/"
FICHERO_CONFIGURCION="${DIRECTORIO}backup_configuracion"

# La funcion comprobarEjecucion evalua si hubo un error al ejecutar el ultimo comando y muestra un mensaje de lo ocurrido.
# Si ocurrio un error provoca la salida del script		
# Tambien borrar los archivos creado apatir del template para añadir usuario y contraseña de administrador
# ENTRADA salida del comando y mensaje a mostrar 
# SALIDA ninguna
comprobarEjecucion(){
	salida=$1
	mensaje=$2
	if [ "$salida" != "0" ]; then
		if [ "$mensaje" != "" ]; then
			echo "ERROR: $mensaje"
		fi
		exit "$salida"
	fi	
} 

mostrarAyuda(){
	FICHERO_CONFIGURCION="${DIRECTORIO}backup_configuracion"
	echo "	El modo de usar el script es el siguiente"
	echo "		$0 [-h] [-?] -u usuario_manager -p contraseña_manager "
	echo "		    -H direccion_switch -P puerto_ssh_switch"
	echo "	"
	echo "  -h -?					Mostar ayuda"
	echo "	-u usuario_manager  	Indica el usuario administrador del switch"
	echo "	-p contraseña_manager 	Indica la contraseña administrador del switch"
	echo "	-H direccion_switch 	Indica la direccion del switch"
	echo "	-P puerto_ssh_switch 	Indica el puerto ssh configurado en el switch "
	echo "  "
	echo "	Los valores por defectos son "
	echo "		backupConfiguracion=${FICHERO_CONFIGURCION}"
	exit 1
}


#Comprobamos que se este instalado el comando scp
command -v scp > /dev/null  2>&1

comprobarEjecucion "$?" "Debe estar instalado scp"

#Comprobamos que se este instalado el comando expect
command -v expect > /dev/null  2>&1
comprobarEjecucion "$?" "Debe estar instalado expect"

# Parsemos los argumentos introducido
while getopts ':u:p:H:P: ?h'  c
do
  case $c in
 	u) USUARIO_MANAGER="$OPTARG" ;;
 	p) CONTRASENA_MANAGER="$OPTARG" ;;
	H) IP_SWITCH="$OPTARG" ;;
	P) PORT_SWITCH="$OPTARG" ;;
    h|?) mostrarAyuda "$0";;
  esac
done


if [ "$USUARIO_MANAGER" = "" ]; then
	mostrarAyuda "$0"
fi
if [ "$CONTRASENA_MANAGER" = "" ]; then
	mostrarAyuda "$0"
fi

if [ "$IP_SWITCH" = "" ]; then
	mostrarAyuda "$0"
fi

if [ "$PORT_SWITCH" = "" ]; then
	mostrarAyuda "$0"
fi

"${DIRECTORIO}"ExpectScripts/enableManagementWeb.expect "$USUARIO_MANAGER" "$CONTRASENA_MANAGER" "$IP_SWITCH" "$PORT_SWITCH" 
comprobarEjecucion $? "Al procesar ${DIRECTORIO}ExpectScripts/enableManagementWeb.expect" 

echo "Finalizado $(basename "$0")"

