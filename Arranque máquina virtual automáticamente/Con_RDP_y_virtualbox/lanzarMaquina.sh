#!/bin/sh

#Debe esta configurado con vnc en el puerto 5999 
#	Añadir em el archivo vbox en el elemento <Hardware>
#  Añador em el archivo vbox
#   <RemoteDisplay enabled="true" authTimeout="2000" allowMultiConnection="true">
#        <VRDEProperties>
#           <Property name="TCP/Ports" value="5999"/>
#         </VRDEProperties>
#     </RemoteDisplay>
#O realizar la configuracion desde la GUI

PUERTO_PROTOCOLO="5999"
IP_PROTOCOLO="localhost"
VMFile="/var/maquinaVirtual/Ubuntu/Ubuntu.vbox"
VMName=$(basename $VMFile | cut -d"." -f1)

vboxmanage list vms | grep -q "\"$VMName\""
if [ "$?" = "1" ]; then
	vboxmanage registervm "$VMFile"
fi
virtualboxvm --startvm "$VMName" &
PID_VM="$!"


# Espera que la maquina virtual este levantada para que este iniciado el servidor del protocolo
timeout 30s  sh -c "while ! nc -z ${IP_PROTOCOLO} ${PUERTO_PROTOCOLO} ; do sleep 1; done"
nc -z ${IP_PROTOCOLO} ${PUERTO_PROTOCOLO}

if [ "$?" = "0" ]; then
	xfreerdp  /v:"${IP_PROTOCOLO}:${PUERTO_PROTOCOLO}" /f
fi

# Cerramos la maquina por si se cerro unicamente el cliente
kill -9 "$PID_VM"
exit



