#!/bin/sh
configuracion=$(dirname "$0")"/"configuracionScriptVirsh.cfg
. "$configuracion"


# Este script permite la importacion de una maquina virtual KVM creada mediante el los scripts  importarMV*.sh
# si se parte de un archivo comprimido o donde colocar lo fichero que representan los discos duros.
# Debe ser ejecutado como root


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
			echo -e "\e[31mERROR:$mensaje\e[0m"
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

# Comprobamos que se este instalado el comando virsh
command -v virsh > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado virsh"

# Comprobamos que se este instalado el comando sed
command -v sed > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado sed"

# Comprobamos que se este instalado el comando tar
command -v tar > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado tar"			

#Comprobamos que se ejecute el script como root para poder acceder a virsh
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 1 "Se requieren pesmisos de administrador para continuar con el menu"
fi

# Solicitamos el nombre de la maquina a importar
echo "Introduce la maquina nueva " 
read -r VM_NUEVA 
if [ "$VM_NUEVA" = "" ]; then
	comprobarEjecucion 1 "No se ha seleccionado ninguna maquina nueva"
fi

# Comprobamos que no exista ya una maquina con el mismo nombre
virsh dominfo --domain "$VM_NUEVA" > /dev/null 2>&1
if [ $? = "0" ]; then
	comprobarEjecucion 1 "La maquina $VM_NUEVA ya existe"
fi

# Solicitamos donde deseamos guardar los discos exportados de la maquina y comprobamos que se haya introducido una carpeta
echo "Seleccione la carpeta colocar los discos de la maquina a importar " 
read -r carpetaSeleccionadaDisco
if [ "$carpetaSeleccionadaDisco" = "" ]; then
	comprobarEjecucion 1 "La carpeta destino de los disco $carpetaSeleccionadaDisco no existe"
fi

# Comprobamos que la carpeta destino de los discos exista
carpetaSeleccionadaDisco=$carpetaSeleccionadaDisco"/tmp"
carpetaSeleccionadaDisco=$(dirname "$carpetaSeleccionadaDisco")"/"
if [ ! -d "$carpetaSeleccionadaDisco" ]; then
	comprobarEjecucion 1 "La carpeta destino de los disco $carpetaSeleccionadaDisco no existe"
fi

# Solicitamos si deseamos partir de un archivo comprimido
while [ true ]; do
	echo "¿Deseas usar un archivo comprimido?(Y/N) " 
	read -r eleccion
	case $eleccion in
		"Y"|"y" )
			DESCOMPRIMIR="TRUE"
			break
		;;
		"N"|"n" )
			DESCOMPRIMIR="FALSE"
			break
		;;
	esac
	echo "Debes seleccionar Y, y, N o n"
	sleep 2
done

# Evaluamos si vamos a partir de un archivo comprimido o no

if [ "$DESCOMPRIMIR" = "TRUE" ]; then

	# Solicitamos que se indique el archivo origen para importacion de la maquina
	echo "Seleccione el fichero comprimido de la maquina a importar " 
	read -r archivoComprimido
	# Comprobamos que el fichero de origen comprimido existe
	if [ ! -f "$archivoComprimido" ]; then
  		comprobarEjecucion 1 "$archivoComprimido no es un archivo"
	fi
	# Descomprimiendo el archivo comprido en una carpeta temporal
	echo "Descomprimiendo el archivo $archivoComprimido en /tmp/$VM_NUEVA/"
	mkdir -p "/tmp/""$VM_NUEVA""/" > /dev/null 2>&1
	comprobarEjecucion $? "Fallo al crear el directorio /tmp/""$VM_NUEVA""/ para descomprimir $archivoComprimido"
	true > "$ERROR_DESCOMPRIMIR"
	tar -zvxf "$archivoComprimido" -C "/tmp/""$VM_NUEVA""/" > "$ERROR_DESCOMPRIMIR" 2>&1
	salida=$?
	ERROR=$(cat "$ERROR_DESCOMPRIMIR")
	comprobarEjecucion $salida "Fallo al descomprimir $archivoComprimido debido a \n $ERROR"
	rm "$ERROR_DESCOMPRIMIR"
	directorioOrigenMaquina="/tmp/"$VM_NUEVA"/" 
else
	# Solicitamos donde se encuentra los archivos perteneciente a la maquina a importar
	echo "Seleccione la carpeta donde se encuentra los discos de la maquina a importar " 
	read -r directorioOrigenMaquina
	if [ "$directorioOrigenMaquina" = "" ]; then
		comprobarEjecucion 1 "La carpeta origen de la maquina $directorioOrigenMaquina no existe"
	fi

	# Comprobamos que existe la carpeta donde se encuentra los archivos perteneciente a la maquina a importar
	directorioOrigenMaquina=$directorioOrigenMaquina"/tmp"
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
echo "Realizando copia del XML en /tmp/$VM_NUEVA.xml"
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
		echo "Realizando copia del disco $KEY en $carpetaSeleccionadaDisco" 
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
echo "Creamos la maquina a apatir del XML modificado con la nueva ubicacion de los discos"

virsh define "/tmp/""$VM_NUEVA"".xml" > /dev/null 2>&1
comprobarEjecucion $? "No se puedo definir la maquina $VM_NUEVA mediante el XML" 

#Borramos los archivos temporales
if [ -d "/tmp/""$VM_NUEVA""/" ]; then
	rm -R "/tmp/""$VM_NUEVA""/"
fi
if [ -f "/tmp/""$VM_NUEVA"".xml" ]; then
	rm "/tmp/""$VM_NUEVA"".xml"
fi

# Mostramos advertencia sobre los discos que pertenece a la maquina y no se han exportado
if [ "$numeroDiscosNoCopiado" != "0" ]; then
	echo "Los siguiente discos no han sido copiado ni modificado en el XML de la maquina y deberán ser modificado a mano \n $discosNoCopiado"
fi
