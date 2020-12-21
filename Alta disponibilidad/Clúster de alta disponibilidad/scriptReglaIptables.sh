#!/bin/sh

#
#	Este script crea reglas de iptables que hará se rediriga el trafico de los puertos especificado hacia el nodo donde se encuentra
# 	alojado el recurso del cluster KVM HA actualmente para poder hacer al recurso a través de la IP de cualquier nodo al recurso que se desea 
#	Esta pensado para hacer uso del recurso  ocf:heartbeat:anything en un cluster KVM HA para llamar a este script
#


SEGUNDOS_ESPERA="10"

# La funcion logearErrorYSalir evalua si hubo un error al ejecutar el ultimo comando, muestra un mensaje de lo ocurrido y borra las reglas creada si
# se le indica.
# ENTRADA salida del comando y mensaje a mostrar  y si se deben borrar las reglas
# SALIDA ninguna
logearErrorYSalir(){
	salida=$1
	mensaje=$2
	borrar=$3
	if [ "$salida" != "0" ]; then
		if [ "$mensaje" != "" ]; then
			logger -is " $(basename $0) ERROR: $mensaje"
		fi
		#Eliminamos la reglas si se crearon antes
		if [ "$borrar" = "TRUE"  ]; then
			eliminarTodasLasReglas "$salida" 
		fi
		exit $salida
	fi	
} 

# Elimina todas las reglas que se pudiero crear para ID_RECURSO para redirigir PUERTOS_INTRODUCIDO hacia el nodoActual
eliminarTodasLasReglas(){
	logger -is " $(basename $0) INFO: Borrando las reglas para el recurso ${ID_RECURSO} y nodo ${nodoActual} y puertos ${PUERTOS_INTRODUCIDO}"
	for PUERTOS in $(echo "$PUERTOS_INTRODUCIDO" | tr -s ',' ' ' ); do
		crearEliminaReglas "$PUERTOS" "ELIMINAR"
	done
	exit $1 # Devolvemos la señal recibida
}

# Crean o eliminan un regla de enrutamiento hacia el nodo nodoActual para el puerto pasado como primer parametro
# ENTRADA puerto para el cual crear las reglas de enrutamiento y si se desea CREAR o ELIMINAR
# SALIDA ninguna
crearEliminaReglas(){
	accion="$2"
	puertos="$1"
	num_puertos=$(echo "$puertos" | cut -d'/' -f1 )
	protocolo=$(echo "$puertos" | cut -d'/' -f2 )
	num_puertos_rango_auxiliar=$(echo "$puertos" | cut -d'/' -f1 | tr -s ':' '-' )

	if [ "$accion" = "CREAR" ]; then
		#Comprobamos antes de crear para no duplicar reglas de PREROUTING
		if ! iptables-save |  grep " PREROUTING -p $protocolo.*--dport $num_puertos -j DNAT --to-destination.*\:$num_puertos_rango_auxiliar" > /dev/null ; then
			if [ "$(eval iptables -t nat -A  PREROUTING -p "$protocolo" --dport "$num_puertos" -j DNAT --to-destination "$IPNodoActual":"$num_puertos_rango_auxiliar"; echo $?)" != "0" ]; then
				logearErrorYSalir 127 "Error al crear regla de PREROUTING para $puertos" "TRUE"
			fi
		fi	

		#Comprobamos antes de crear  para no duplicar reglas de OUTPUT
		if ! iptables-save |  grep " OUTPUT -p $protocolo.*--dport $num_puertos -j DNAT --to-destination.*\:$num_puertos_rango_auxiliar" > /dev/null ; then
			if [ "$(eval iptables -t nat -A  OUTPUT -p "$protocolo" --dport "$num_puertos" -j DNAT --to-destination "$IPNodoActual":"$num_puertos_rango_auxiliar"; echo $?)" != "0" ]; then
				logearErrorYSalir 127 "Error al crear regla de OUTPUT para $puertos" "TRUE"
			fi
		fi	

		#Comprobamos antes de crear para no duplicar reglas de POSTROUTING 
		if [ "$(eval iptables -t nat -C POSTROUTING -p "$protocolo"	 --dport "$num_puertos" -j MASQUERADE; echo $?)" != "0" ]; then
			if [ "$(eval iptables -t nat -A  POSTROUTING -p "$protocolo" --dport "$num_puertos" -j MASQUERADE; echo $?)" != "0" ]; then
				logearErrorYSalir 127 "Error al crear regla de POSTROUTING para $puertos" "TRUE"
			fi
		fi	
	fi

	if [ "$accion" = "ELIMINAR" ]; then
		#Comprobamos si existe la regla de PREROUTING para eliminarla
		if iptables-save |  grep " PREROUTING -p $protocolo.*--dport $num_puertos -j DNAT --to-destination.*\:$num_puertos_rango_auxiliar" > /dev/null ; then
			if [ "$(eval iptables -t nat -D  PREROUTING -p "$protocolo" --dport "$num_puertos" -j DNAT --to-destination "$IPNodoActual":"$num_puertos_rango_auxiliar"; echo $?)" != "0" ]; then
				logger -is " $(basename $0) INFO: No se pudo borrar la regla de PREROUTING para $puertos" 
			fi
		fi	

		#Comprobamos si existe la regla de OUTPUT para eliminarla
		if iptables-save |  grep " OUTPUT -p $protocolo.*--dport $num_puertos -j DNAT --to-destination.*\:$num_puertos_rango_auxiliar" > /dev/null ; then
			if [ "$(eval iptables -t nat -D  OUTPUT -p "$protocolo" --dport "$num_puertos" -j DNAT --to-destination "$IPNodoActual":"$num_puertos_rango_auxiliar"; echo $?)" != "0" ]; then
				logger -is " $(basename $0) INFO: No se pudo borrar la regla de OUTPUT para $puertos" 
			fi
		fi	

		#Comprobamos si existe la regla de POSTROUTING para eliminarla
		if [ "$(eval iptables -t nat -C POSTROUTING -p "$protocolo"	 --dport "$num_puertos" -j MASQUERADE; echo $?)" = "0" ]; then
			if [ "$(eval iptables -t nat -D  POSTROUTING -p "$protocolo"	 --dport "$num_puertos" -j MASQUERADE; echo $?)" != "0" ]; then
				logger -is " $(basename $0) INFO: No se pudo borrar la regla de POSTROUTING para $puertos" 
			fi
		fi	
	fi
} 

# Muesta la ayuda para usar el script 
# ENTRADA ninguna
# SALIDA ninguna
mostrarAyuda(){
	SEGUNDOS_ESPERA="10"
	echo "	El modo de usar el script es el siguiente"
	echo " 	[-?] [-h] [-d] [-w segundosEspera] -r idRecurso -p puertos"
	echo ""
	echo " 	-? -h 				Mostrar ayuda"
	echo "	-d 					Indica que se borran las reglas creada de iptables con los parametos idRecuso y puertos y se finalizará"
	echo "	-w segundosEspera	Indica los segundos de espera para comprobamos que el recurso siga activo en el mismo nodo desde que se incio el script"
	echo "	-r idRecurso  		Indica el recurso que se buscara para redireccionar los puertos parado como párametros"
	echo "	-p puertos  		Indica los puertos a redireccionar hacia el nodo donde se encuentra el recurso idRecurso"
	echo "							Ej: 20/udp 80/tcp 1900:1910/tcp 20/udp,21/tcp"
	echo ""
	echo "	Los valores por defectos son "
	echo "		segundosEspera=${SEGUNDOS_ESPERA}"
}

# Indicamos que si se recibe la señal para terminar o matar el script antes de salir se quiere borrar las posibles reglas que se haya generado
trap eliminarTodasLasReglas TERM KILL

# Comprobamos que se ejecute el script como root para poder acceder a virsh
if [ "$(whoami)" != 'root' ]; then
  logearErrorYSalir 127 "Se requieren pesmisos de administrador para continuar con el menu"
fi

# Comprobamos que se este instalado el comando pcs
command -v pcs > /dev/null  2>&1
logearErrorYSalir "$?" "Debe estar instalado pcs"

# Comprobamos que se este instalado el comando xmllint
command -v xmllint > /dev/null  2>&1
logearErrorYSalir "$?" "Debe estar instalado xmllint"

# Leemos los argumentos pasado al script
while getopts ":t:r:p:w: d?h" opt
do
    case $opt in
        \?|h ) mostrarAyuda ; exit 0;; # crear que funcion de ayuda
        r ) ID_RECURSO=$OPTARG ;;     
		p ) PUERTOS_INTRODUCIDO=$OPTARG ;;
		d ) BORRADO_MANUAL="TRUE";;
		w ) SEGUNDOS_ESPERA=$OPTARG ;;
    esac
done

if [ "$ID_RECURSO" = "" ]; then
	mostrarAyuda
	logearErrorYSalir 1  "No se introdujo el parametro -r " "FALSE"
fi

if [ "$PUERTOS_INTRODUCIDO" = "" ]; then
	mostrarAyuda
	logearErrorYSalir 1  "No se introdujo el parametro -p " "FALSE"
fi

# Comprobamos si existe algun puerto incorrecto, es decir, no se introdujo como portocolo udp o tcp
logger -is " $(basename $0) INFO: Comprobamos si alguno de los puerto introducido es incorrecto"

PUERTOS_INCORRECTO=""
for PUERTO in $(echo "$PUERTOS_INTRODUCIDO" | tr -s ',' ' ' ); do
	protocolo=$(echo "$PUERTO" | cut -d'/' -f2 )
	if [ "$protocolo" != "udp" ] && [ "$protocolo" != "tcp" ]; then
		if [ "$PUERTOS_INCORRECTO" = "" ]; then
			PUERTOS_INCORRECTO="$PUERTO"
		else
			PUERTOS_INCORRECTO="$PUERTOS_INCORRECTO, $PUERTO"
		fi
	fi
done

if [ "$PUERTOS_INCORRECTO" != "" ]; then
	logearErrorYSalir 127  "Formato de los puertos es incorrecto: $PUERTOS_INCORRECTO " "FALSE"
fi

# Comprobando en que nodo se ejecuta el recurso ID_RECURSO
logger -is " $(basename $0) INFO: Comprobamos en que nodo se esta ejecutando ${ID_RECURSO}"
nodoActual=$(pcs status xml | xmllint --xpath "string(//resource[@id=\"${ID_RECURSO}\"]/node/@name)" -)
if [ "$nodoActual" = "" ]; then
	logearErrorYSalir 127 "No se ha podido determinar donde se encuentra el recurso $ID_RECURSO"
fi

# Calculamos la ip del nodo dondde se encuntra el recurso ID_RECURSO
logger -is " $(basename $0) INFO: Calculamos la ip del nodo ${nodoActual} donde se encuntra el recurso ${ID_RECURSO}"
IPNodoActual=$(grep "$nodoActual" /etc/hosts | cut -d' ' -f1)
if [ "$IPNodoActual" = "" ]; then
	logearErrorYSalir "$?" "No se ha podido determinar donde la IP del nodo $nodoActual a partir del fichero /etc/hosts"
fi

# Si se se selecciono el borrado de las reglas como argumento del script
if [ "$BORRADO_MANUAL" = "TRUE" ]; then
	eliminarTodasLasReglas "0"
fi

# Creamos las reglas iptables para el recurso ID_RECURSO para redireccionar los puerto PUERTOS_INTRODUCIDO al nodo nodoActual
logger -is " $(basename $0) INFO: Creando las reglas para el recurso ${ID_RECURSO} y nodo ${nodoActual} y puertos ${PUERTOS_INTRODUCIDO}"
for PUERTOS in $(echo "$PUERTOS_INTRODUCIDO" | tr -s ',' ' ' ); do
	crearEliminaReglas "$PUERTOS" "CREAR"
done

logger -is " $(basename $0) INFO: Empieza la espera hasta que ${ID_RECURSO} falle"
# Espera infinita
while  true ; do
	# Esperamos 10 segundo y comprobamos que el recurso siga activo
	sleep "${SEGUNDOS_ESPERA}s" &
	wait $!
	if [ "$(pcs status xml | xmllint --xpath "string(//resource[@id=\"${ID_RECURSO}\"]/node/@name)" -)" != "$nodoActual" ]; then
		eliminarTodasLasReglas "1"
	fi
done