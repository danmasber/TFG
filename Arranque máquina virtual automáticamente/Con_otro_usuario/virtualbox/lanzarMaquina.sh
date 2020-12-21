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


VMFile="/var/share/MaquinaVirtual/archivoMaquina.vbox"
VMName=$(basename $VMFile | cut -d"." -f1)
i3Cofig="/opt/servicioMaquina/i3config" 
i3 -c $i3Cofig & 

cambioPermiso "$VMFile"
su usuarioMaquinaVirtual -c "vboxmanage list vms " | grep -q "\"$VMName\""
if [ "$?" = "1" ]; then
	su usuarioMaquinaVirtual -c "vboxmanage registervm \"$VMFile\""
fi
su usuarioMaquinaVirtual -c "virtualboxvm --startvm \"$VMName\" --fullscreen"  
exit