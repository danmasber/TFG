#!/bin/sh

# 
# El primer argumento sera el archivo  de configuracion sino se buscara uno en la ruta de donde se encuentre el script 
#
# Este script requiere que en $SERVER_REMOTA_BACKUP debe contener la publica para conectarse mediante ssh sin tener que anadir el 
#

configuracion=$(dirname "$0")"/"backupConfigRemoto.cfg
if [ "$1" != "" ]; then
	if [ -f "$1" ]; then
		configuracion=$1
	fi
fi

if [ ! -f "$configuracion" ]; then
	 comprobarEjecucion $? "Se requieren un archivo de configuracion"
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
		if [ -e  "/tmp/carpetasBackup" ]; then
			rm /tmp/carpetasBackup
		fi

		borrarFicheroTemporal

    	if [ "$mensaje" != "" ]; then
			 logger -is " $(basename "$0") ERROR: $mensaje"
		fi
		exit $salida
	fi	
} 

# La funcion borrarFicheroTemporal borramos los ficheros temporales que pudiera existir
# ENTRADA ninguna 
# SALIDA ninguna 

borrarFicheroTemporal(){
	if [ -e  "/tmp/checksumCalculadoServidor" ]; then
		rm /tmp/checksumCalculadoServidor
	fi

	if [ -e  "/tmp/checksumGuardadoServidor" ]; then
		rm /tmp/checksumGuardadoServidor
	fi

	if [ -e  "/tmp/checksumCalculadoLocal" ]; then
		rm /tmp/checksumCalculadoLocal
	fi
}

# La funcion comprobarChecksumServidor comprueba que el checksum y el contenido en el servidor estuviera
# corresponde y no se ha modificado en su valor o el contenido de la carpeta.
# Si ha sido modificado paramos la ejecucion del script y comprobamos si existiera en local para lanzar un log
# indicado que la local es correcta
# ENTRADA ninguna 
# SALIDA ninguna 

comprobarChecksumServidor(){
	while IFS= read -r linea
	do 	
		if [ "$linea" != "" ]; then
			#Preparamos la linea leida por si fuerea una carpeta hacer la copia recuersivamente de esta
			carpetaBackup=$(basename "$linea")
			archivoChecksum="$CARPETA_BACKUP_SERVIDOR$CARPETA_CHECKSUM_SERVIDOR$carpetaBackup"
			#Comprobamos que los archivos en la carpeta de backup no han sido modificado después de haber realizado el backup


			logger -is " $(basename "$0")  INFO: Comprobamos el checksum para $carpetaBackup"
			if [ "$PUBLIC_KEY" != ""  ]; then
				"$SSH_BIN" -obatchmode=yes -oPort="$SSH_PORT" -i "$PUBLIC_KEY"  "$USUARIO_BACKUP_SERVIDOR""@""$SERVER_REMOTA_BACKUP" "cd $CARPETA_BACKUP_SERVIDOR ; tar -cf - $carpetaBackup/ | md5sum" > /tmp/checksumCalculadoServidor
				"$SSH_BIN" -obatchmode=yes -oPort="$SSH_PORT" -i "$PUBLIC_KEY"  "$USUARIO_BACKUP_SERVIDOR""@""$SERVER_REMOTA_BACKUP" "cat $archivoChecksum" > /tmp/checksumGuardadoServidor
			else
				"$SSH_BIN" -oPort="$SSH_PORT"   "$USUARIO_BACKUP_SERVIDOR""@""$SERVER_REMOTA_BACKUP" "cd $CARPETA_BACKUP_SERVIDOR ; tar -cf - $carpetaBackup/ | md5sum" > /tmp/checksumCalculadoServidor
				"$SSH_BIN" -oPort="$SSH_PORT"   "$USUARIO_BACKUP_SERVIDOR""@""$SERVER_REMOTA_BACKUP" "cat $archivoChecksum" > /tmp/checksumGuardadoServidor
			fi
			#Si la al comaprar no es igual paramos porque el servidor ha sido modificado
			diff /tmp/checksumCalculadoServidor /tmp/checksumGuardadoServidor > /dev/null  2>&1
			resultadoComparacion=$?
			if [ "$resultadoComparacion" != "0" ]; then
				comprobarChecksumLocal "$carpetaBackup"
				comprobarEjecucion $resultadoComparacion "El checksum no coincide el guardado en el servidor y el calculado para $carpetaBackup por lo que no continuamos la copia"		
			fi	
		
		fi
	done < /tmp/carpetasBackup
}

# La funcion comprobarChecksumLocal comprueba que el checksum y el contenido en el local de una carpeta.
# Se usa para informar de una carpeta que en el servidor ha sido modificada y
# Si ha sido modificado paramos la ejecucion del script y comprobamos si existiera en local para lanzar un log
# indicado que la local es correcta para copiar en el servidor
# ENTRADA La carpeta a comprobar el checksum en local 
# SALIDA ninguna 

comprobarChecksumLocal(){
	carpetaBackup="$1"
	archivoChecksum="$CARPETA_BACKUP$CARPETA_CHECKSUM$carpetaBackup"
	carpetaBackupRutaAbsoluta="$CARPETA_BACKUP$carpetaBackup"

	cd "$CARPETA_BACKUP" 
	if [ -f "$archivoChecksum" ] && [ -d "$carpetaBackupRutaAbsoluta" ]; then
		#Comprobamos que los archivos en la carpeta de backup no han sido modificado después de haber realizado el backup
		logger -is " $(basename "$0")  INFO: Comprobamos el checksum para $carpetaBackup en local para ver si es valida para copiarla de nuevo en el servidor"
		tar -cf - "$carpetaBackup" | md5sum > /tmp/checksumCalculadoLocal
		diff /tmp/checksumCalculadoLocal "$archivoChecksum" > /dev/null  2>&1
		resultado=$?
		if [ "$resultado" = "0" ]; then
			logger -is " $(basename "$0")  INFO: Se puede hacer uso de la carpeta local $carpetaBackup para copiar en el servidor ya que el checksum coincide"
		fi
	fi
	
}


# La funcion recalcularChecksumTrasCopiar recalcula lo checksum de todos las carpetar trar copiar 
# ENTRADA ninguna
# SALIDA ninguna 

recalcularChecksumTrasCopiar(){
	cd "$CARPETA_BACKUP"
	while IFS= read -r linea
	do 	
		if [ "$linea" != "" ]; then
			#Preparamos la linea leida por si fuerea una carpeta hacer la copia recuersivamente de esta
			carpetaBackup=$(basename "$linea")
			#Calculamos y guardamos el checksum de la carpeta copiada sino existe
			logger -is " $(basename "$0")  INFO: Calculamos el checksum para $carpetaBackup"
			tar -cf - "$carpetaBackup" | md5sum > "$CARPETA_BACKUP$CARPETA_CHECKSUM$carpetaBackup"
			comprobarEjecucion $? "Fallo al calcular el checksum de $carpetaBackup"
			
			logger -is " $(basename "$0")  INFO: Cambiando el propietario del checksum $CARPETA_BACKUP$CARPETA_CHECKSUM$carpetaBackup"
			chown -R "$USUARIO_BACKUP" "$CARPETA_BACKUP$CARPETA_CHECKSUM$carpetaBackup"
			comprobarEjecucion $? "Fallo al cambiar el propietario del checksum $CARPETA_BACKUP$CARPETA_CHECKSUM$carpetaBackup"

			logger -is " $(basename "$0")  INFO: Hacemos inmutables el checksum $CARPETA_BACKUP$CARPETA_CHECKSUM$carpetaBackup"
			chattr -R +i  "$CARPETA_BACKUP$CARPETA_CHECKSUM$carpetaBackup" > /dev/null  2>&1
			comprobarEjecucion $? "Fallo al hacer inmutables el checksum $CARPETA_BACKUP$CARPETA_CHECKSUM$carpetaBackup"
		fi
	done < /tmp/carpetasBackup
}

#Comprobamos que se ejecute el script como root 
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 1 "Se requieren pesmisos de administrador para continuar con el script"
fi

# Comprobamos que se este instalado el comando rsync
command -v rsync > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado rsync"

# Comprobamos que se este instalado el comando ssh
command -v ssh > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado ssh"

# Comprobamos que se este instalado el comando md5sum
command -v md5sum > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado md5sum"

# Comprobamos que se este instalado el comando tar
command -v tar > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado tar"

# Comprobamos que se existe el usuario USUARIO_BACKUP
id "$USUARIO_BACKUP" > /dev/null  2>&1

comprobarEjecucion $? "El usuario $USUARIO_BACKUP no existe"

logger -is " $(basename "$0")  INFO: Iniciando la copia remota incremental"

su "$USUARIO_BACKUP" -c "[ -d $CARPETA_BACKUP ] || mkdir $CARPETA_BACKUP" 
comprobarEjecucion $? "Fallo al crear la carpera $CARPETA_BACKUP"

#Creando la carpeta para guardar el checksum de la carpeta copiada sino existe
su "$USUARIO_BACKUP" -c "[ -d $CARPETA_BACKUP$CARPETA_CHECKSUM ] || mkdir $CARPETA_BACKUP$CARPETA_CHECKSUM" 
comprobarEjecucion $? "Fallo al crear la carpera $CARPETA_BACKUP$CARPETA_CHECKSUM"

#Compriobamos que carpetas en remoto seran las que se copiaran
logger -is " $(basename "$0")  INFO: Comprobamos las carpeta a copiar remotamente"
if [ "$PUBLIC_KEY" != ""  ]; then
	"$SSH_BIN" -obatchmode=yes -oPort="$SSH_PORT" -i "$PUBLIC_KEY" "$USUARIO_BACKUP_SERVIDOR""@""$SERVER_REMOTA_BACKUP" "cd $CARPETA_BACKUP_SERVIDOR ; ls -d * | grep ^$PREFIJO_BACKUP" > /tmp/carpetasBackup
else
	"$SSH_BIN" -oPort="$SSH_PORT" "$USUARIO_BACKUP_SERVIDOR""@""$SERVER_REMOTA_BACKUP" "cd $CARPETA_BACKUP_SERVIDOR ; ls -d * | grep ^$PREFIJO_BACKUP" > /tmp/carpetasBackup
fi

logger -is " $(basename "$0")  INFO: Comprobamos los checksum de las carpetas remotas"
comprobarChecksumServidor

logger -is " $(basename "$0")  INFO: Realizando la copia mediante rsync, se hace uso de la opcion partil(-P) para poder renaudar si es necesario"
if [ "$PUBLIC_KEY" != ""  ]; then
	rsync -e "$SSH_BIN -obatchmode=yes -oPort=$SSH_PORT -i $PUBLIC_KEY" -aczPAX --delete-after  "$USUARIO_BACKUP_SERVIDOR""@""$SERVER_REMOTA_BACKUP"":""$CARPETA_BACKUP_SERVIDOR$PREFIJO_BACKUP*" "$CARPETA_BACKUP" > /dev/null  2>&1
	comprobarEjecucion $? "Fallo al hacer la copia mediante rsync se puede volve a ejecutar el comando : rsync -e \"$SSH_BIN -obatchmode=yes -oPort=$SSH_PORT -i $PUBLIC_KEY\" -aczPAX  --delete-after $USUARIO_BACKUP_SERVIDOR@$SERVER_REMOTA_BACKUP:$CARPETA_BACKUP_SERVIDOR$PREFIJO_BACKUP* $CARPETA_BACKUP" 

else
	rsync -e "$SSH_BIN -oPort=$SSH_PORT" -aczPAX --delete-after  "$USUARIO_BACKUP_SERVIDOR""@""$SERVER_REMOTA_BACKUP"":""$CARPETA_BACKUP_SERVIDOR$PREFIJO_BACKUP*" "$CARPETA_BACKUP" > /dev/null  2>&1
	comprobarEjecucion $? "Fallo al hacer la copia mediante rsync se puede volve a ejecutar el comando : rsync -e \"$SSH_BIN -oPort=$SSH_PORT\" -aczPAX  --delete-after $USUARIO_BACKUP_SERVIDOR@$SERVER_REMOTA_BACKUP:$CARPETA_BACKUP_SERVIDOR$PREFIJO_BACKUP* $CARPETA_BACKUP" 
fi

logger -is " $(basename "$0")  INFO: Hacemos a los ficheros de $CARPETA_BACKUP inmutables"

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

logger -is " $(basename "$0")  INFO: Calculamos los checksum de las carpeta locales"
recalcularChecksumTrasCopiar

borrarFicheroTemporal

logger -is " $(basename "$0")  INFO: Fin de la copia remota incremental"