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
	echo " 	- is_gateway: Indica si interfaz_red es la interfaz conectada a la ruta predeterminada(TRUE o FALSE)"
	echo ""
	echo "  Ejemplo de fichero de configuracion"
	echo " 	interfaz_red=\"enp4s0\""
	echo " 	interfaz_bridge=\"br0\""
	echo " 	interfaces_tap=\"tap0 tap1\""
	echo " 	is_gateway=\"FALSE\""
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

if [ "$is_gateway" = "" ] && [ "$is_gateway" != "FALSE" ] && [ "$is_gateway" != "TRUE" ]; then
	mostrarAyuda 
	exit 1 
fi

echo "INFO: Comprobamos que existe la interfaz $interfaz_red"
ip link show "$interfaz_red" > /dev/null 2>&1
comprobarEjecucion $? "No existe la interfaz $interfaz_red"

ip_interfaz_red=$(ip addr show "$interfaz_red" | grep -Po 'inet \K[\d.]+' | head -1)
mascara_interfaz_red=$(ip addr show "$interfaz_red" | grep -Po 'inet .*\/\K[\d]+'  | head -1)
ip_gateway=$(ip route list | grep "default" |  grep -Po 'via \K[\d.]+')
numero_ip=$(ip addr show "$interfaz_red" | grep -Po 'inet \K[\d.]+' | wc -l )
ips_interfaz_red=$(ip addr show "$interfaz_red" | grep -Po 'inet \K[\d.]+' | tr -s '\n' ' ')


if [ "$numero_ip" != "1" ]; then
	if [ "$numero_ip" = "0" ]; then
		echo "ERROR: No existe ninguna ip para el interfaz $interfaz_red"
		exit 1
	fi
	echo "INFO: La interfaz $interfaz_red tenia varias IP ( $ips_interfaz_red) y se usara $ip_interfaz_red"
fi

echo "INFO: Asignamos las interfaces TAP ( $interfaces_tap ) a OpenVpn"	
for interfaz_tap in $interfaces_tap; do
    openvpn --mktun --dev "$interfaz_tap"
    comprobarEjecucion $? "Asignando las interfaces TAP $interfaz_tap a OpenVpn"
done


echo "INFO: Creamos la interfaz bridge $interfaz_bridge"
brctl addbr "$interfaz_bridge"
comprobarEjecucion $? "Creando la interfaz bridge $interfaz_bridge"


echo "INFO: Asignamos la interfaz $interfaz_red al interfaz bridge $interfaz_bridge"
brctl addif "$interfaz_bridge" "$interfaz_red"
comprobarEjecucion $? "Asignando la interfaz $interfaz_red al interfaz bridge $interfaz_bridge"

echo "INFO: Asignamos las interfaces TAP ( $interfaces_tap ) a la interfaz bridge $interfaz_bridge"

for interfaz_tap in $interfaces_tap; do
    brctl addif "$interfaz_bridge" "$interfaz_tap"
    comprobarEjecucion $? "Asignando la interfaz TAP $interfaz_tap a la interfaz bridge $interfaz_bridge"
done


for interfaz_tap in $interfaces_tap; do
	echo "INFO: Ponemos en modo promiscuo la interfaz $interfaz_tap"
	ip link set "$interfaz_tap" promisc on up
    comprobarEjecucion $? "Poniendo en modo promiscuo la interfaz $interfaz_tap"
    # ifconfig $interfaz_tap 0.0.0.0 promisc up
done

echo "INFO: Borramos la ip asignadas a $interfaz_red y lo ponemos en modo promisc"
ip link set "$interfaz_red" promisc on up
comprobarEjecucion $? "Poniendo en modo promiscuo la interfaz $interfaz_red"
ip addr flush dev "$interfaz_red"
comprobarEjecucion $? "Borrando la IP asociada $interfaz_red"
# ifconfig "$interfaz_red" 0.0.0.0 promisc up


echo "INFO: Configuramos la ip $ip_interfaz_red en el interfaz $interfaz_bridge"
ip address add "${ip_interfaz_red}/${mascara_interfaz_red}" dev "$interfaz_bridge"
comprobarEjecucion $? "Configurando la ip $ip_interfaz_red en el interfaz $interfaz_bridge"

#ip_broadcast_interfaz_red=$(ip addr show "$interfaz_red" | grep -Po 'brd \K[\d.]+' | head -1)
# ifconfig $interfaz_bridge "${ip_interfaz_red}/${mascara_interfaz_red}" broadcast "$ip_broadcast_interfaz_red"

echo "INFO: Activamos la interfaz $interfaz_bridge"
ip link set "$interfaz_bridge" up
comprobarEjecucion $? "Activando la interfaz $interfaz_bridge"
# ifconfig $interfaz_bridge up

if [ "$is_gateway" != "FALSE" ]; then
	if ip route list | grep "default" | grep -q "$interfaz_red" ; then
		echo "INFO: Borramos la ruta por defecto a la interfaz $interfaz_red"
		ip route delete default via "$ip_gateway" dev  "$interfaz_red"
		comprobarEjecucion $? "Borrando la ruta por defecto a la interfaz $interfaz_red"
	fi

	if ! ip route list | grep -q "default" ; then
		echo "INFO: Configuramos la ruta por defecto a la interfaz $interfaz_bridge"
		ip route add default via "$ip_gateway" dev  "$interfaz_bridge" 
		comprobarEjecucion $? "Configurando la ruta por defecto a la interfaz $interfaz_bridge"
	fi
fi
