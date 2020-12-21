#!/bin/sh
#Debe esta configurado con vnc en el puerto 5999 
#  Añador em el archivo vmx
# RemoteDisplay.vnc.enabled = "true"
# RemoteDisplay.vnc.port = "5999"
# RemoteDisplay.vnc.password = "Password"

PUERTO_PROTOCOLO="5999"
IP_PROTOCOLO="localhost"
VMFile="/home/dit/vmware/Ubuntu/Ubuntu.vmx"

vmplayer "$VMFile" &
PID_VM="$!"

# Espera que la maquina virtual este levantada para que este iniciado el servidor del protocolo
timeout 30s  sh -c "while ! nc -z ${IP_PROTOCOLO} ${PUERTO_PROTOCOLO} ; do sleep 1; done"
nc -z ${IP_PROTOCOLO} ${PUERTO_PROTOCOLO}
if [ "$?" = "0" ]; then
	# Si tiene contaseña
	# Generar archivo con vncpasswd "/opt/servicioMaquina/passwd"
	# y añadir al comando -passwd="/opt/servicioMaquina/passwd"
	vncviewer -FullScreen "${IP_PROTOCOLO}:${PUERTO_PROTOCOLO}"
fi

# Cerramos la maquina por si se cerro unicamente el cliente
kill -9 "$PID_VM"
exit
