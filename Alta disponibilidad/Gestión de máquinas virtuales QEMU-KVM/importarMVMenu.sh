#!/bin/sh
export NCURSES_NO_UTF8_ACS=1 # Evitar que aparezcan caracteres en lugar de lineas
configuracion=$(dirname "$0")"/"configuracionScriptVirsh.cfg
. "$configuracion"

# Este script permite la importacion de una maquina virtual KVM creada mediante el los scripts  importarMV*.sh
# si se parte de un archivo comprimido o donde colocar lo fichero que representan los discos duros.
# Este script hace uso de menu para solicitar la ubicacion donde almacenar la maquina , si se parte de un archivo comprimido o donde se encuentra la maquina a importar.
# Debe ser ejecutado como root

VM_NUEVA=$1

dialogAlias='dialog --cancel-label Atras  --stdout --clear --backtitle '
dialogAliasNoClear='dialog --cancel-label Atras --stdout --backtitle '
tituloMenu=$(echo "Realizando importacion de la maquina ""$VM_NUEVA")

trap "rm $ERROR_DESCOMPRIMIR;clear; exit" 1 2 15

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
			$dialogAlias "$tituloMenu" --title "ERROR" --msgbox "$mensaje" 10 50
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

# Comprobamos que se este instalado el comando dialog
command -v dialog > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado dialog"


# Comprobamos que se ejecute el script como root para poder acceder a virsh
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 1 "Se requieren pesmisos de administrador para continuar con el menu"
fi

# Comprobamos que se haya pasado la maquina a importar como argumento
if [ "$1" = "" ]; then
	comprobarEjecucion 1 "Se requieren introducir como parametro una maquina \n $0 nombreMaquina"
fi	

# Comprobamos que no exista ya una maquina con el mismo nombre
virsh dominfo --domain "$VM_NUEVA" > /dev/null 2>&1
if [ $? = "0" ]; then
	comprobarEjecucion 1 "La maquina $VM_NUEVA ya existe"
fi

if [ ! -d "$DIRECTORIO_POR_DEFECTO_DESTINO_DISCO" ]; then
	DIRECTORIO_POR_DEFECTO_DESTINO_DISCO="$PWD"
fi


# Solicitamos donde deseamos guardar los discos exportados de la maquina
carpetaSeleccionadaDisco=$($dialogAlias "$tituloMenu" --title "Seleccione la carpeta donde se almacenarán los discos de la maquina a importar" --dselect "$DIRECTORIO_POR_DEFECTO_DESTINO_DISCO" 10 50)
comprobarEjecucion $?

# Comprobamos que la carpeta destino de los discos exista
carpetaSeleccionadaDisco=$carpetaSeleccionadaDisco"/tmp"
carpetaSeleccionadaDisco=$(dirname "$carpetaSeleccionadaDisco")"/"
if [ ! -d "$carpetaSeleccionadaDisco" ]; then
	comprobarEjecucion 1 "La carpeta destino de los disco $carpetaSeleccionadaDisco no existe"
fi

# Solicitamos si deseamos partir de un archivo comprimido
$dialogAlias "$tituloMenu" --yesno "¿Deseas usar un archivo comprimido?" 8 50
salida=$?  	
case $salida in
	0)
		DESCOMPRIMIR="TRUE"
		break
	;;
	1)
		DESCOMPRIMIR="FALSE"
		break
	;;
	255) 
	  clear
	  exit $salida
	;;
esac

porcentaje=0
pasoPorcentaje=$((100/4))

if [ ! -d "$DIRECTORIO_POR_DEFECTO_ORIGEN" ]; then
	DIRECTORIO_POR_DEFECTO_ORIGEN="$PWD"
fi


# Evaluamos si vamos a partir de un archivo comprimido o no
if [ "$DESCOMPRIMIR" = "TRUE" ]; then
	# Solicitamos que se indique el archivo origen para importacion de la maquina
	archivoComprimido=$($dialogAlias "$tituloMenu" --title "Seleccione el fichero tar.gz donde se encuentra la copia de $VM_NUEVA " --fselect "$DIRECTORIO_POR_DEFECTO_ORIGEN" 8 50)
  	comprobarEjecucion $?
  	# Comprobamos que el fichero de origen comprimido existe
  	if [ ! -f "$archivoComprimido" ]; then
  		comprobarEjecucion 1 "$archivoComprimido no es un archivo"
	fi
	
	$dialogAliasNoClear "$tituloMenu" --title "Realizando importarcion" --gauge "Descomprimiendo el archivo $archivoComprimido" 10 80 $porcentaje &

	# Descomprimiendo el archivo comprido en una carpeta temporal
	mkdir -p "/tmp/""$VM_NUEVA""/" > /dev/null 2>"$1"
	comprobarEjecucion $? "Fallo al crear el directorio /tmp/""$VM_NUEVA""/ para descomprimir $archivoComprimido"
	true > "$ERROR_DESCOMPRIMIR"
	tar -zvxf "$archivoComprimido" -C "/tmp/""$VM_NUEVA""/" > "$ERROR_DESCOMPRIMIR" 2>&1
	salida=$?
	ERROR=$(cat "$ERROR_DESCOMPRIMIR")
	comprobarEjecucion $salida "Fallo al descomprimir $archivoComprimido debido a \n $ERROR"
	rm "$ERROR_DESCOMPRIMIR"
	directorioOrigenMaquina="/tmp/""$VM_NUEVA""/" 
else
	# Solicitamos donde se encuentra los archivos perteneciente a la maquina a importar
	directorioOrigenMaquina=$($dialogAlias "$tituloMenu" --title "Seleccione la carpeta donde se encuentra los ficheros de backup de $VM_NUEVA" --dselect "$DIRECTORIO_POR_DEFECTO_ORIGEN" 8 50)
	comprobarEjecucion $? "Se ha cancelado la seleccion de carpeta donde se encuentra los ficheros de backup de $VM_NUEVA"
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

porcentaje=$((porcentaje + pasoPorcentaje))
sleep 1

# Comprobamos que existe el XML que define la maquina a importar
if [ ! -f "$directorioOrigenMaquina""$VM_NUEVA"".xml" ]; then
	comprobarEjecucion 1 "El fichero ""$VM_NUEVA"".xml no existe"
fi

$dialogAliasNoClear "$tituloMenu" --title "Realizando importarcion" --gauge "Realizando copia del XML en /tmp/$VM_NUEVA.xml" 10 80 $porcentaje &

# Copiamos el XML de la maquina para poder modificarlo
cp -p "$directorioOrigenMaquina""$VM_NUEVA"".xml" "/tmp/""$VM_NUEVA"".xml" > /dev/null 2>&1
comprobarEjecucion $? "Fallo la copia del XML en /tmp/$VM_NUEVA.xml para su modificación"
porcentaje=$((porcentaje + pasoPorcentaje))
sleep 1

discosMapaCopiado=""
numeroDiscosParaCopiar=0
# Leemos los discos perteneciente de la maquina y si se han exportado o no del fichero discos_Asociado_$VM_NUEVA
for disco in $(cat "$directorioOrigenMaquina""discos_Asociado_""$VM_NUEVA"); do
	discosMapaCopiado="$discosMapaCopiado $disco"
	KEY=${disco%%|*}
    VALUE=${disco#*|}
	if [ "$VALUE" = "COPY" ]; then
		numeroDiscosParaCopiar=$((numeroDiscosParaCopiar+1))
	fi
done

if [ "$numeroDiscosParaCopiar" != "0" ]; then
	pasoDiscoPorcentaje=$((pasoPorcentaje/numeroDiscosParaCopiar))
else
	porcentaje=$((porcentaje + pasoDiscoPorcentaje))
fi

discosNoCopiado=""
numeroDiscosNoCopiado=0
# Realizamos la copia de los discos exportados de la maquina y modificamos el XML con la nueva ubicacion de los discos
for disco in $discosMapaCopiado; do
	KEY=${disco%%|*}
    VALUE=${disco#*|}
	if [ "$VALUE" = "COPY" ]; then
		$dialogAliasNoClear "$tituloMenu" --title "Realizando importarcion" --gauge "Realizando copia del disco $KEY en $carpetaSeleccionadaDisco" 10 80 $porcentaje &
		cp -p "$directorioOrigenMaquina""$KEY" "$carpetaSeleccionadaDisco" > /dev/null 2>&1
		comprobarEjecucion $? "Fallo la copia del disco $KEY"
		sed -i "s|$KEY|$carpetaSeleccionadaDisco$KEY|g" "/tmp/""$VM_NUEVA"".xml" > /dev/null 2>&1
		comprobarEjecucion $? "Fallo la modificacion del XML para el disco $KEY"
		porcentaje=$((porcentaje + pasoDiscoPorcentaje))
	else
		discosNoCopiado="$discosNoCopiado -$KEY\n"
		numeroDiscosNoCopiado=$((numeroDiscosNoCopiado+1))
	fi	
done
# Creamos la maquina a apatir del XML modificado con la nueva ubicacion de los discos 
$dialogAliasNoClear "$tituloMenu" --title "Realizando importarcion" --gauge "Definiendo la nueva maquina $VM_NUEVA" 10 80 $porcentaje &	
virsh define "/tmp/""$VM_NUEVA"".xml" > /dev/null 2>&1
comprobarEjecucion $? "No se puedo definir la maquina $VM_NUEVA mediante el XML"

porcentaje=100
$dialogAliasNoClear "$tituloMenu" --title "Realizando importarcion" --gauge "Se ha completado la importacion con éxito" 10 80 $porcentaje &
sleep 3	

#Borramos los archivos temporales
if [ -d "/tmp/""$VM_NUEVA""/" ]; then
	rm -R "/tmp/""$VM_NUEVA""/"
fi
if [ -f "/tmp/""$VM_NUEVA"".xml" ]; then
	rm "/tmp/""$VM_NUEVA"".xml"
fi

# Mostramos advertencia sobre los discos que pertenece a la maquina y no se han exportado
if [ "$numeroDiscosNoCopiado" != "0" ]; then
	$dialogAlias "$tituloMenu" --title "ADVERTENCIA"\
		 --msgbox "Los siguiente discos no han sido copiado ni modificado en el XML de la maquina y deberán ser modificado a mano \n $discosNoCopiado" 8 50
fi
