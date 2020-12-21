#!/bin/sh
configuracion=$(dirname "$0")"/"configuracionScriptVirsh.cfg
. "$configuracion"

# Este script permite la importacion de una maquina virtual KVM creada mediante el los scripts  importarMV*.sh
# si se parte de un archivo comprimido o donde colocar lo fichero que representan los discos duros.
# Debe ser ejecutado como root
# Este script permite hacer el uso de un archivos de configuracion o argumentos de entrada para modificar su resultado

# La funcion comprobarEjecucion evalua si hubo un error al ejecutar el ultimo comando y muestra un mensaje de lo ocurrido.
# Si ocurrio un error provoca la salida del script		
# Tambien sino se le indica borrar los archivos asociado a la exportacion fallida
# ENTRADA salida del comando , mensaje a mostrar y argunmento para NO_BORRAR para mantener los archivos asociado a la exportacion fallida
# SALIDA ninguna
 comprobarEjecucion(){
	salida=$1
	mensaje=$2
	borrarTemporales=$3
	if [ "$salida" != "0" ]; then
		if [ "$mensaje" != "" ]; then
			logger -is " $(basename $0) ERROR: $mensaje"
		fi

		#Borramos los archivos temporales
		if [ -d "/tmp/""$VM_NUEVA""/" ] && [ "$borrarTemporales" != "NO_BORRAR" ]; then
			rm -R "/tmp/""$VM_NUEVA""/"
		fi
		if [ -f "/tmp/""$VM_NUEVA"".xml" ] && [ "$borrarTemporales" != "NO_BORRAR" ]; then
			rm "/tmp/""$VM_NUEVA"".xml"
		fi

		clear
		exit "$salida"
	fi	
} 

mostrarAyuda(){
	echo "El modo de usar el script es el siguiente"
	echo " $0 [-h] [-?] [-o rutaOrigen]  [-f fichero] [-n nombreNuevo] [-d rutaDestino] [-c] [-x discosAExcluir]"
	echo ""
	echo "-h -? 			Mostar ayuda"
	echo "-o rutaOrigen  	Indica donde se encontrara los archivos necesarios para importar la maquina"
	echo "-n nombreNuevo  	Indica el nuevo nombre de la maquina a importar"
	echo "-d rutaDestino  	Indica donde se copiará los discos tras la importacion"
	echo "-f fichero  		Indica el fichero comprimido se usara como origen para la importacion(debera ser la ruta absoluta)"
	echo "-x 				Indica si se usara el un archivo comprimido para importar por defecto no se usara"
	echo ""
	echo "Si no se introduce alguno de los argumentos se intentará recuperar de $(dirname "$0")/configuracionScriptVirsh.cfg"
	exit 1
}

# Comprobamos que se este instalado el comando tar
command -v tar > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado tar"
# Comprobamos que se este instalado el comando virsh
command -v virsh > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado virsh"

# Comprobamos que se este instalado el comando sed
command -v sed > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado sed"

#Comprobamos que se ejecute el script como root para poder acceder a virsh
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 1 "Se requieren pesmisos de administrador para continuar con el menu"
fi

# Parsemos los argumentos introducido
while getopts 'xo:n:d: ?h' c
do
  case $c in
    n) VM_NUEVA="$OPTARG" ;;
    d) CARPETA_UBICACION_DISCOS_DESANTENDIDO="$OPTARG" ;;
	o) DIRECTORIO_ORIGEN_MAQUINA_DESANTENDIDO="$OPTARG" ;;
	f) ARCHIVO_COMPRIMIDO_DESANTENDIDO="$OPTARG" ;;
    x) DESCOMPRIMIR="TRUE" ;;
    h|\?) mostrarAyuda "$0";;
  esac
done

if [ "$DESCOMPRIMIR" = "" ]; then
	DESCOMPRIMIR="FALSE"
fi

logger -is " $(basename $0) INFO: Comienza la importacion de la maquina $VM_NUEVA"
# Comprobamos que se haya pasado la maquina a importar como argumento o esta configurada
if [ "$VM_NUEVA" = "" ]; then
	comprobarEjecucion 1 "No se ha seleccionado ninguna maquina nueva"
fi

# Comprobamos que no exista ya una maquina con el mismo nombre
virsh dominfo --domain "$VM_NUEVA" > /dev/null 2>&1
if [ $? = "0" ]; then
	comprobarEjecucion 1 "La maquina $VM_NUEVA ya existe"
fi

# Comprobamos que se haya pasado como argumento donde guardar los discos exportados de la maquina o este configurado
if [ "$CARPETA_UBICACION_DISCOS_DESANTENDIDO" = "" ]; then
	comprobarEjecucion 1 "La carpeta destino de los disco $CARPETA_UBICACION_DISCOS_DESANTENDIDO no existe"
fi

# Comprobamos que la carpeta destino de los discos exista
carpetaSeleccionadaDisco=$CARPETA_UBICACION_DISCOS_DESANTENDIDO"/tmp"
carpetaSeleccionadaDisco=$(dirname "$carpetaSeleccionadaDisco")"/"
if [ ! -d "$carpetaSeleccionadaDisco" ]; then
	comprobarEjecucion 1 "La carpeta destino de los disco $carpetaSeleccionadaDisco no existe"
fi

# Evaluamos si vamos a partir de un archivo comprimido o no

if [ "$DESCOMPRIMIR" = "TRUE" ]; then
	# Comprobamos que el fichero de origen comprimido existe
	if [ ! -f "$ARCHIVO_COMPRIMIDO_DESANTENDIDO" ]; then
  		comprobarEjecucion 1 "$ARCHIVO_COMPRIMIDO_DESANTENDIDO no es un archivo"
	fi
	# Descomprimiendo el archivo comprido en una carpeta temporal
	logger -is " $(basename $0) INFO: Descomprimiendo el archivo $archivoComprimido en /tmp/$VM_NUEVA/"
	mkdir -p "/tmp/""$VM_NUEVA""/" > /dev/null 2>&1
	comprobarEjecucion $? "Fallo al crear el directorio /tmp/""$VM_NUEVA""/ para descomprimir $ARCHIVO_COMPRIMIDO_DESANTENDIDO"
	true > "$ERROR_DESCOMPRIMIR"
	tar -zvxf "$ARCHIVO_COMPRIMIDO_DESANTENDIDO" -C "/tmp/""$VM_NUEVA""/" > "$ERROR_DESCOMPRIMIR" 2>&1
	salida=$?
	ERROR=$(cat "$ERROR_DESCOMPRIMIR")
	comprobarEjecucion $salida "Fallo al descomprimir $ARCHIVO_COMPRIMIDO_DESANTENDIDO debido a \n $ERROR"
	rm "$ERROR_DESCOMPRIMIR"
	directorioOrigenMaquina="/tmp/""$VM_NUEVA""/" 
else
	# Comprobamos que existe la carpeta donde se encuentra los archivos perteneciente a la maquina a importar
	if [ "$DIRECTORIO_ORIGEN_MAQUINA_DESANTENDIDO" = "" ]; then
		comprobarEjecucion 1 "La carpeta origen de la maquina $DIRECTORIO_ORIGEN_MAQUINA_DESANTENDIDO no existe"
	fi
	# Comprobamos que existe la carpeta donde se encuentra los archivos perteneciente a la maquina a importar
	directorioOrigenMaquina=$DIRECTORIO_ORIGEN_MAQUINA_DESANTENDIDO"/tmp"
	directorioOrigenMaquina=$(dirname "$directorioOrigenMaquina")"/"
	if [ ! -d "$directorioOrigenMaquina" ]; then
		comprobarEjecucion 1 "La carpeta origen de la maquina $directorioOrigenMaquina no existe"
	fi	
fi

# Comprobamos que existe el XML que define la maquina a importar
if [ ! -f "$directorioOrigenMaquina""$VM_NUEVA"".xml" ]; then
	comprobarEjecucion 1 "El fichero ""$VM_NUEVA"".xml no existe"
fi

# Copiamos el XML de la maquina para poder modificarlo
logger -is " $(basename $0) INFO: Realizando copia del XML en /tmp/$VM_NUEVA.xml"
cp -p "$directorioOrigenMaquina""$VM_NUEVA"".xml" "/tmp/""$VM_NUEVA"".xml" > /dev/null 2>&1
comprobarEjecucion $? "Fallo la copia del XML en /tmp/$VM_NUEVA.xml para su modificación"


discosMapaCopiado=""
numeroDiscosParaCopiar=0
# Leemos los discos perteneciente de la maquina y si se han exportado o no del fichero discos_Asociado_$VM_NUEVA
for disco in $(cat "$directorioOrigenMaquina""discos_Asociado_""$VM_NUEVA"); do
	discosMapaCopiado="$discosMapaCopiado $disco"
	KEY=${disco%%:*}
    VALUE=${disco#*:}
	if [ "$VALUE" = "COPY" ]; then
		numeroDiscosParaCopiar=$((numeroDiscosParaCopiar+1))
	fi
done

discosNoCopiado=""
numeroDiscosNoCopiado=0
# Realizamos la copia de los discos exportados de la maquina y modificamos el XML con la nueva ubicacion de los discos
for disco in $discosMapaCopiado; do
	KEY=${disco%%|*}
    VALUE=${disco#*|}
	if [ "$VALUE" = "COPY" ]; then
		logger -is " $(basename $0) INFO: Realizando copia del disco $KEY en $carpetaSeleccionadaDisco"
		cp -p "$directorioOrigenMaquina""$KEY" "$carpetaSeleccionadaDisco" > /dev/null 2>&1
		comprobarEjecucion $? "Fallo la copia del disco $KEY"
		sed -i "s|$KEY|$carpetaSeleccionadaDisco$KEY|g" "/tmp/""$VM_NUEVA"".xml" > /dev/null 2>&1
		comprobarEjecucion $? "Fallo la modificacion del XML para el disco $KEY"
	else
		discosNoCopiado="$discosNoCopiado -$KEY\n"
		numeroDiscosNoCopiado=$((numeroDiscosNoCopiado+1))
	fi	
done

# Creamos la maquina a apatir del XML modificado con la nueva ubicacion de los discos 
logger -is " $(basename $0) INFO: Creamos la maquina a apatir del XML modificado con la nueva ubicacion de los discos"
virsh define "/tmp/""$VM_NUEVA"".xml" > /dev/null 2>&1
salida=$?
comprobarEjecucion "$salida" "No se puedo definir la maquina $VM_NUEVA mediante el XML" 

#Borramos los archivos temporales
if [ -d "/tmp/""$VM_NUEVA""/" ]; then
	rm -R "/tmp/""$VM_NUEVA""/"
fi
if [ -f "/tmp/""$VM_NUEVA"".xml" ]; then
	rm "/tmp/""$VM_NUEVA"".xml"
fi

# Mostramos advertencia sobre los discos que pertenece a la maquina y no se han exportado
if [ "$numeroDiscosNoCopiado" != "0" ]; then
	logger -is " $(basename $0) INFO: Los siguiente discos no han sido copiado ni modificado en el XML de la maquina y deberán ser modificado a mano \n $discosNoCopiado"
fi

logger -is " $(basename $0) INFO: Finalizada la importacion de la maquina $VM_NUEVA"