#!/bin/sh

# Este script se encarga de hacer que todos la fichero sean inmutables en la carpeta $CARPETA_BACKUP y ademas crea los 
# necesario para poder comprobar si se realizaron modificaciones


configuracion=$(dirname "$0")"/"backupConfig.cfg
if [ "$1" != "" ]; then
	if [ -f "$1" ]; then
		configuracion=$1
	fi
fi

if [ ! -f "$configuracion" ]; then
	 comprobarEjecucion 1 "Se requieren un archivo de configuracion"
fi

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
			 logger -is " $(basename "$0") ERROR: $mensaje"
		fi

		exit $salida
	fi	
} 

#Comprobamos que se ejecute el script como root 
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 1 "Se requieren pesmisos de administrador para continuar con el script"
fi

# Comprobamos que se este instalado el comando md5sum
command -v md5sum > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado md5sum"

# Comprobamos que se este instalado el comando tar
command -v tar > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado tar"

# Comprobamos que se este instalado el comando chattr
command -v chattr > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado chattr"


# Comprobamos que se existe el usuario USUARIO_BACKUP
id "$USUARIO_BACKUP"> /dev/null  2>&1

comprobarEjecucion $? "El usuario $USUARIO_BACKUP no existe"

logger -is " $(basename "$0")  INFO: Iniciando el calculo de checksum y la convesion a inmutables los ficheros de backup"

if [ -d "$CARPETA_BACKUP" ]; then
	comprobarEjecucion 1 "No existe la carpeta $CARPETA_BACKUP"
fi

#Nos movemos a la carpeta creada
cd "$CARPETA_BACKUP"


for carpetaBackup in  $(ls -d "$CARPETA_BACKUP"*/ | grep "$PREFIJO_BACKUP"); do
	logger -is " $(basename "$0")  INFO: Cambiando el propietario de la carpeta $carpetaBackup"
	chown -R "$USUARIO_BACKUP" "$carpetaBackup"
	comprobarEjecucion $? "Fallo al cambiar el propietario de la carpeta $carpetaBackup"
done

for carpetaBackup in  $(ls -d "$CARPETA_BACKUP"*/ | grep "$PREFIJO_BACKUP"); do
	logger -is " $(basename "$0")  INFO: Hacemos a los ficheros de $carpetaBackup inmutables"
	chattr -R +i  "$carpetaBackup" > /dev/null  2>&1
	comprobarEjecucion $? "Fallo al hacer inmutables a la carpteta $carpetaBackup"	
done

logger -is " $(basename "$0")  INFO: Calculamos el checksum de las carpeta con el prefijo $PREFIJO_BACKUP y comprobamos si se modificó anteriormente"
for carpetaBackup in  $(ls -d "$CARPETA_BACKUP"*/ | grep "$PREFIJO_BACKUP"); do
	nombreCarpetaBackup=$(basename "$carpetaBackup")
	tar -cf - "$carpetaBackup" | md5sum > "$CARPETA_BACKUP$CARPETA_CHECKSUM$nombreCarpetaBackupTMP"
	if [ -f "$CARPETA_BACKUP$CARPETA_CHECKSUM$nombreCarpetaBackup" ]; then
		diff "$CARPETA_BACKUP$CARPETA_CHECKSUM$nombreCarpetaBackup" "$CARPETA_BACKUP$CARPETA_CHECKSUM$nombreCarpetaBackupTMP" > /dev/null  2>&1
		resultado=$?
		if [ "$resultado" != "0" ]; then
			logger -is " $(basename "$0")  WARN: Se ha modificado la carpeta $nombreCarpetaBackup"
		fi
		rm "$CARPETA_BACKUP$CARPETA_CHECKSUM$nombreCarpetaBackupTMP"
	else 
		mv "$CARPETA_BACKUP$CARPETA_CHECKSUM$nombreCarpetaBackupTMP" "$CARPETA_BACKUP$z$nombreCarpetaBackup"
	fi
done

logger -is " $(basename "$0")  INFO: Cambiando el propietario de la carpeta  que contiene los checksum $CARPETA_BACKUP$CARPETA_CHECKSUM"
chown -R "$USUARIO_BACKUP" "$CARPETA_BACKUP$CARPETA_CHECKSUM"
comprobarEjecucion $? "Fallo al cambiar el propietario a la carpeta que contiene los checksum $CARPETA_BACKUP$CARPETA_CHECKSUM"

logger -is " $(basename "$0")  INFO: Hacemos inmutables a los checksum calculados"
chattr -R +i  "$CARPETA_BACKUP$CARPETA_CHECKSUM" > /dev/null  2>&1
comprobarEjecucion $? "Fallo al hacer inmutables a los checksum calculados"




logger -is " $(basename "$0")  INFO: Fin del calculo de checksum y la convesion a inmutables los ficheros de backup"