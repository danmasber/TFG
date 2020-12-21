#!/bin/sh


# $(($?*2)) es porque cerramos minicom con la señal 15  que proboca salida con exit 1

DIRECTORIO=$(dirname "$0")"/"
IP_TFTP_SERVIDOR="192.255.255.2"
IP_TFTP_CLIENTE="192.255.255.3"
IP_MASCARA_TFTP="255.255.255.0"
MASCARA_SUBRED="24"

BAUD_RESCUE=115200
REINICIAR_DESDE_RESCUE="FALSE"
TTY_SERIAL=/dev/ttyS0
PUERTO_SWITCH="1"
BACKUP_CONFIGURCION="backup_configuracion"

if [ -f /var/default/tftpd-hpa ]; then 
	. "/var/default/tftpd-hpa"
	DIRECTORIO_SERVIDOR_TFTP="$TFTP_DIRECTOTY"
else
	DIRECTORIO_SERVIDOR_TFTP="/var/lib/tftpboot/"
fi

INTERFAZ_RED_TFTP=$(ls -l /sys/class/net/ | grep -vE "virtual|total"  | rev | cut -d "/" -f1 |rev| head -1)


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
			ip address delete "${IP_TFTP_SERVIDOR}/${MASCARA_SUBRED}" dev "${INTERFAZ_RED_TFTP}"		
			exit "$salida"
		fi
	fi	
} 

mostrarAyuda(){
	BAUD_RESCUE=115200
	TTY_SERIAL=/dev/ttyS0
	BACKUP_CONFIGURCION="backup_configuracion"
	PUERTO_SWITCH="1"
	INTERFAZ_RED_TFTP=$(ls -l /sys/class/net/ | grep -vE "virtual|total"  | rev | cut -d "/" -f1 |rev| head -1)
	if [ -f /var/default/tftpd-hpa ]; then 
		. "/var/default/tftpd-hpa"
		DIRECTORIO_SERVIDOR_TFTP="$TFTP_DIRECTOTY"
	else
		DIRECTORIO_SERVIDOR_TFTP="/var/lib/tftpboot/"
	fi
	echo "	El modo de usar el script es el siguiente"
	echo " 	$0 [-h] [-?] -p contraseña_manager [-f backupConfiguracion] [-t tty_serie] [-b baudRescue] [-r]  [-d directorioServidorTftp]"
	echo "		[-P puertoSwitch] [-i interfazRedEthernet]"
	echo ""
	echo "  -h -? 						Mostar ayuda"
	echo "	-f backupConfiguracion		Indica el fichero de configuracion donde se almacenara el backup"
	echo "	-t tty_serie  				Indica el TTY  donde esta ubicado la conexion por puerto serie al switch"
	echo "	-b baudRescue  				Indica los baud con los cuales se ha iniciado el switch en modo rescue"
	echo "	-r 							Indica si se se incia el proceso desde modo rescue"
	echo "	-p contraseña_manager 		Indica la contraseña del administrador del switch"
	echo "	-d directorioServidorTftp	Indica la ruta del directorio del servidor TFTP"
	echo "	-P puertoSwitch 			Indica el puerto ethernet del switch que se usará para conectar mediante tftp"
	echo "	-i interfazRedEthernet		Indica la intefaz Ethernet del PC que usaremos para conector con el switch"
	echo ""
	echo "	 Si el switch no posee usuario y contraseña administrador se ignorá el argumento contraseña_manager"
	echo ""
	echo "	Los valores por defectos son "
	echo "		baudRescue=${BAUD_RESCUE}"
	echo "		tty_serie=${TTY_SERIAL}"
	echo "		backupConfiguracion=${BACKUP_CONFIGURCION}"
	echo "		puertoSwitch=${PUERTO_SWITCH}"
	echo "		directorioServidorTftp=${DIRECTORIO_SERVIDOR_TFTP}"
	echo "		interfazRedEthernet=${INTERFAZ_RED_TFTP}"
	exit 1
}

# Parsemos los argumentos introducido
while getopts ':f:t:b:p:d:P:i: r?h' c
do
  case $c in
	f) BACKUP_CONFIGURCION="$OPTARG" ;;	
	t) TTY_SERIAL="$OPTARG" ;;
 	b) BAUD_RESCUE="$OPTARG" ;;
 	r) REINICIAR_DESDE_RESCUE="TRUE" ;;	
 	p) PASSWORD_MANAGER="$OPTARG" ;;
	d) DIRECTORIO_SERVIDOR_TFTP="$OPTARG" ;;
	P) PUERTO_SWITCH="$OPTARG" ;;
	i) INTERFAZ_RED_TFTP="$OPTARG" ;;
    h|\?) mostrarAyuda "$0";;
  esac
done

#Comprobamos que se este instalado el comando minicom
command -v minicom > /dev/null  2>&1
comprobarEjecucion $(($?*2)) "Debe estar instalado minicom"

#Comprobamos que se este instalado el comando in.tftpd
command -v in.tftpd > /dev/null  2>&1
comprobarEjecucion $(($?*2)) "Debe estar instalado in.tftpd"

#Comprobamos que se este ejecutandose el servidor tftp
systemctl status tftp > /dev/null  2>&1
comprobarEjecucion $(($?*2)) "Debe estar ejecutandose el servidor tftp"

#Comprobamos que se este ejecutandose el servidor tftp
ip link show "${INTERFAZ_RED_TFTP}" > /dev/null  2>&1
comprobarEjecucion $(($?*2)) "No existe el interfaz ${INTERFAZ_RED_TFTP}"

if [ -d "${DIRECTORIO_SERVIDOR_TFTP}" ]; then
	DIRECTORIO_SERVIDOR_TFTP_TEMPORAL=$(dirname "${DIRECTORIO_SERVIDOR_TFTP}/aux")
	systemctl status tftp | grep "$DIRECTORIO_SERVIDOR_TFTP_TEMPORAL" > /dev/null  2>&1
	comprobarEjecucion $(($?*2)) "No esta configura el servidor con la carpeta ${DIRECTORIO_SERVIDOR_TFTP}"
else 
	comprobarEjecucion 125 "No existe el directorio ${DIRECTORIO_SERVIDOR_TFTP}"
fi

if [ "$PASSWORD_MANAGER" = "" ]; then
	mostrarAyuda "$0"
fi



#	Creando el fichero las variables que existen en los template introducido a partir de los template
sed -e "s/PASSWORD_MANAGER/$PASSWORD_MANAGER/g"  \
             "${DIRECTORIO}MinicomScripts/scriptEnable.template" > "${DIRECTORIO}MinicomScripts/scriptEnable.tmp"

FECHA=$(date +%y_%m_%d)

sed -e "s/IP_TFTP_CLIENTE/$IP_TFTP_CLIENTE/g"  \
	-e "s/IP_MASCARA_TFTP/$IP_MASCARA_TFTP/g"  \
	-e "s/IP_TFTP_SERVIDOR/$IP_TFTP_SERVIDOR/g"  \
	-e "s/PUERTO_SWITCH/$PUERTO_SWITCH/g"  \
	-e "s/BACKUP_CONFIGURCION/$BACKUP_CONFIGURCION/g"  \
	-e "s/FECHA/$FECHA/g"  \
             "${DIRECTORIO}MinicomScripts/scriptBackupConfiguration.template" > "${DIRECTORIO}MinicomScripts/scriptBackupConfiguration.tmp"

BACKUP_CONFIGURCION="${BACKUP_CONFIGURCION}_${FECHA}"

if [ "$REINICIAR_DESDE_RESCUE" = "TRUE" ]; then
	minicom -d  "$TTY_SERIAL" -b "$BAUD_RESCUE" -S "${DIRECTORIO}MinicomScripts/scriptInitSwitchFromRescueStart"
	comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptInitSwitchFromRescueStart" 

	minicom -d  "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptInitSwitchFromRescueEnd"
	comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptInitSwitchFromRescueEnd" 
	
	echo "Esperamos un tiempo para que se reinicie el switch"
	sleep 60 
fi

minicom -d  "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptEnable.tmp"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptEnable.tmp"


ip address add "${IP_TFTP_SERVIDOR}/${MASCARA_SUBRED}" dev "${INTERFAZ_RED_TFTP}"
comprobarEjecucion $(($?*2)) "Al crear la ip virtual ${IP_VIRTUAL_SERVER} en ${INTERFAZ_RED_TFTP}"

minicom -d  "$TTY_SERIAL" -b "${BAUD_RESCUE}" -S "${DIRECTORIO}MinicomScripts/scriptBackupConfiguration.tmp"
comprobarEjecucion $? "Al procesar ${DIRECTORIO}MinicomScripts/scriptBackupConfiguration.tmp"

cp "${DIRECTORIO_SERVIDOR_TFTP}/${BACKUP_CONFIGURCION}.txt" "${DIRECTORIO}${BACKUP_CONFIGURCION}.txt"
comprobarEjecucion $? "Al recibir el fichero ${DIRECTORIO}${BACKUP_CONFIGURCION}.txt"
 
ip address delete "${IP_TFTP_SERVIDOR}/${MASCARA_SUBRED}" dev "${INTERFAZ_RED_TFTP}"
comprobarEjecucion $(($?*2)) "Al eliminando la ip virtual ${IP_TFTP_SERVIDOR} en ${INTERFAZ_RED_TFTP}"

rm -f "${DIRECTORIO}MinicomScripts/"*.tmp

echo "Finalizado $(dirname "$0")"
