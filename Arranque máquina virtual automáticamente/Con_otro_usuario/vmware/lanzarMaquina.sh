#!/bin/sh

# Cambia los permisos para que la maquina sea acesible para usuarioMaquinaVirtual
# Como parametro recibe el fichero de definicion de la maquina virtual
cambioPermiso(){
	CARPETA=$(dirname "$1")
	chmod -R o+wr "$CARPETA"
	 while [ "$CARPETA" != "/" ]
	   do
	   	   chmod o+x "$CARPETA"
	       CARPETA=$(dirname "$CARPETA")
	   done
} 

VMFile="/var/share/MaquinaVirtual/archivoMaquina.vmx"
i3Cofig="/opt/servicioMaquina/i3config" 
i3 -c $i3Cofig & 
cambioPermiso "$VMFile"
su usuarioMaquinaVirtual -c "vmplayer -X \"$VMFile\""  
exit
