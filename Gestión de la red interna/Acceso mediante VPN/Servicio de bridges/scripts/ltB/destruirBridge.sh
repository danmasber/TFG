#!/bin/sh


configuracion="$(dirname "$0")/configuracionBridge.cfg"
. "$configuracion"

# La funcion comprobarEjecucion evalua si hubo un error al ejecutar el ultimo comando y muestra un mensaje de lo ocurrido.
# Si ocurrio un error provoca la salida del script		
# Tambien sino se le indica borrar los archivos asociado a la exportacion fallida
# ENTRADA salida del comando , mensaje a mostrar 
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

# Muesta la ayuda para usar el script 
# ENTRADA ninguna
# SALIDA ninguna
mostrarAyuda(){
	echo "	En el fichero de configuracion $configuracion debe existir definidas las siguientes variables"
	echo " 	- interfaz_red : Nombre del interfaz de red que formara parte del bridge que se va a crear"
	echo " 	- interfaz_bridge : Nombre del bridge que se va a crear"
	echo " 	- interfaces_tap: Define la lista de dispositivos TAP que se incluirá en el bridged "
	echo ""
	echo "  Ejemplo de fichero de configuracion"
	echo " 	interfaz_red=\"enp4s0\""
	echo " 	interfaz_bridge=\"br0\""
	echo " 	interfaces_tap=\"tap0 tap1\""
}

# Comprobamos que se ejecute el script como root para cambiar de usuario sin poner contraseña
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 1 "Se requieren pesmisos de administrador para continuar con el script"
fi

# Coomprobamos que este instalado bridge-utils
command -v brctl > /dev/null  2>&1
comprobarEjecucion $? "Debe estar instalado bridge-utils"

#Comprobamos el archivo de configuracion esta completo
if [ "$interfaz_red" = "" ]; then
	mostrarAyuda 
	exit 1 
fi

if [ "$interfaz_bridge" = "" ]; then
	mostrarAyuda 
	exit 1 
fi

if [ "$interfaces_tap" = "" ]; then
	mostrarAyuda 
	exit 1 
fi

echo "INFO: Comprobamos que existen las interfaces $interfaz_red y $interfaz_bridge y estan asociadas"
ip link show "$interfaz_red" > /dev/null 2>&1
comprobarEjecucion $? "No existe la interfaz $interfaz_red"

ip link show "$interfaz_bridge" > /dev/null 2>&1
comprobarEjecucion $? "No existe la interfaz $interfaz_bridge"

brctl show "$interfaz_bridge" | grep -q "${interfaz_red}$"
comprobarEjecucion $? "La interfaz $interfaz_red no esta asociada al bridge $interfaz_bridge"

echo "INFO: Paramos la interfaz bridge $interfaz_bridge"
ip link set "$interfaz_bridge" down
comprobarEjecucion $? "Parado la interfaz bridge $interfaz_bridge"
# ifconfig $interfaz_bridge down

echo "INFO: Borramos la interfaz bridge $interfaz_bridge"
brctl delbr "$interfaz_bridge"
comprobarEjecucion $? "Borrado la interfaz bridge $interfaz_bridge"

echo "INFO: Desasignamos las interfaces TAP ( $interfaces_tap ) de OpenVpn"
for interfaz_tap in $interfaces_tap; do
    openvpn --rmtun --dev "$interfaz_tap"
    comprobarEjecucion $? "Desasignando la interfaz TAP  $interfaz_tap de OpenVpn"
done

echo "INFO: Reiniciamos la interfaz $interfaz_red"
ip link set "$interfaz_red"  promisc off 
comprobarEjecucion $? "Desactivando el modo promiscuo de $interfaz_red"

ifdown "$interfaz_red"
comprobarEjecucion $? "Desactivando la interfaz $interfaz_red"

ifup "$interfaz_red"
comprobarEjecucion $? "Desactivando el modo promiscuo de $interfaz_red"
comprobarEjecucion $? "Activando la interfaz $interfaz_red"
