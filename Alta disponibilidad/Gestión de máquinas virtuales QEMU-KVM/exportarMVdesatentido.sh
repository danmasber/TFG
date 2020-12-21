#!/bin/sh
configuracion=$(dirname "$0")"/"configuracionScriptVirsh.cfg
. "$configuracion"

# Este script permite la exportacion de una maquina virtual KVM. Durante la ejecucion se solicitara 
# si se desea comprimir el rusultado o incluir lo fichero que representan los discos duros.
# Este script permite hacer el uso de un archivos de configuracion o argumentos de entrada para modificar su resultado
# Debe ser ejecutado como root

estadoAnteriorActivo="FALSE"

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
		
		if [ -f "$ERROR_COMPRIMIR" ]; then
			rm "$ERROR_COMPRIMIR"
		fi

		if [ -d "$carpetaExportacionMaquina" ] && [ "$borrarTemporales" != "NO_BORRAR" ]; then
			rm -R "$carpetaExportacionMaquina"
		fi	

		if [ -f "$nombreTar" ] && [ "$borrarTemporales" != "NO_BORRAR" ]; then
			rm -R "$nombreTar"
		fi
		exit "$salida"
	fi	
} 

# La funcion arrayContineElemento busca en la cadena elementos se encuentra contenido el elemento
# ENTRADA Cadena de elementos separado por espacio y elemento a buscas
# SALIDA devuelve 1 si elementos contiene a elemento o 0 en caso contrario
 arrayContineElemento() {
	elementos=$1
    elemento=$2
    for i in $elementos ; do
        if [ "$i" = "$elemento" ] ; then
            return 1
        fi
    done
    return 0
}

mostrarAyuda(){
	echo "El modo de usar el script es el siguiente"
	echo " $0 [-h] [-?] [-o nombreOriginal] [-n nombreNuevo] [-d rutaDestino] [-c] [-x discosAExcluir]"
	echo ""
	echo "-h -? 			 	Mostar ayuda"
	echo "-o nombreOriginal 	Indica el nombre de la maquina a exportar"
	echo "-n nombreNuevo  		Indica el nuevo nombre de la maquina tras exportarla"
	echo "-d rutaDestino  		Indica donde se realizar la exportacion y debe ser una ruta absoluta"
	echo "-c 					Indica que se desea comprimir tras exportar por defecto no se comprimira"
	echo "-x dicosAExcluir 		Indica los discos que no se quieren incluir al exportar"
	echo " Introducir el parametro que aprace en el XML en las etiquetas de los discos <source "/"file='*'/> separado por espacio y entrecomillado"
	echo ""
	echo "Si no se introduce alguno de los argumentos se intentará recuperar de $(dirname "$0")/configuracionScriptVirsh.cfg"
	exit 1
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


#Comprobamos que se ejecute el script como root para poder acceder a virsh
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 1 "Se requieren pesmisos de administrador para continuar con el script"
fi

# Parsemos los argumentos introducido
while getopts 'cxo:n:d: ?h' c
do
  case $c in
    o) VM_ORIGINAL="$OPTARG" ;;
    n) VM_NUEVA="$OPTARG" ;;
    d) CARPETA_SELECCIONADA_DESANTENDIDO="$OPTARG" ;;
    c) COMPRIMIR="TRUE" ;;
	x) DISCOS_A_EXCLUIR="$OPTARG"
    h|\?) mostrarAyuda $0;;
  esac
done

if [ "$COMPRIMIR" = "" ]; then
	COMPRIMIR="FALSE"
fi



#Comprobamos que se haya pasado la maquina a exportar como primer argumento o este configurada
if [ "$VM_ORIGINAL" = "" ]; then
		comprobarEjecucion 1 "Se configurar en configuracionScriptVirsh una maquina con la variable VM_ORIGINAL"
	fi

logger -is " $(basename $0) INFO: Comienza la exportacion de la maquina $VM_ORIGINAL a $VM_NUEVA"

#Comprobamos que la maquina a exportar exista
logger -is " $(basename $0) INFO: Comprobando si existe la maquina $VM_ORIGINAL"
virsh dominfo --domain "$VM_ORIGINAL" > /dev/null 2>&1
salida=$?
comprobarEjecucion "$salida" "La maquina original $VM_ORIGINAL no existe"

# Comprobamo si se le paso como segundo argumento un nuevo nombre o se este configurado
if [ "$VM_NUEVA" = "" ]; then
		comprobarEjecucion 1 "No se ha introduciodo un nuevo nombre para la maquina"
fi

# Comprobamo si se le paso como tercer argumento un el lugar donde exportar la maquina o se este configurado
if [ "$CARPETA_SELECCIONADA_DESANTENDIDO" = "" ]; then
		comprobarEjecucion 1 "La carpeta $CARPETA_SELECCIONADA_DESANTENDIDO no existe"
fi

#Comprobamos que la carpeta destino de la exportacion exista
carpetaSeleccionada=$CARPETA_SELECCIONADA_DESANTENDIDO"/tmp"
carpetaSeleccionada=$(dirname "$carpetaSeleccionada")"/"
if [ ! -d "$carpetaSeleccionada" ]; then
	comprobarEjecucion 1 "La carpeta $carpetaSeleccionada no existe"
fi

# Comprobamos que la maquina a exportar se encuentra corriendo
if [ $(virsh list --state-running  | sed "12d" | grep " $VM_ORIGINAL " | wc -l) = 1 ]; then
	estadoAnteriorActivo="TRUE"
fi

# Creamos la carpeta donde realizaremos la exportacion
mkdir -p "$carpetaSeleccionada""$VM_NUEVA"
comprobarEjecucion $? "Fallo al crear la carpeta para realizar la copia $carpetaSeleccionada$VM_NUEVA"
carpetaExportacionMaquina=$carpetaSeleccionada$VM_NUEVA"/" 


if [ $estadoAnteriorActivo = "TRUE" ]; then
	# Apagamos la maqiona original antes de copiar no seria necesario pero es recomendable
	logger -is " $(basename $0) INFO: Apagamos la maqiona original antes de copiar"
	virsh shutdown "$VM_ORIGINAL" > /dev/null 2>&1
	comprobarEjecucion $? "Fallo el apagado de la maquina $VM_ORIGINAL"
fi

# Extraemos el XML de la maquina para modificarla y guardarla
logger -is " $(basename $0) INFO: Extraemos el XML de la maquina para modificarla y guardarla"
virsh dumpxml "$VM_ORIGINAL" > "$dirExportacionMaquina""$VM_NUEVA"".xml" 2> /dev/null
comprobarEjecucion $? "Fallo el volcado a XML de la maquina $VM_ORIGINAL"


# Consultamos los discos actuales que se estan asociados
discos=$(virsh domblklist "$VM_ORIGINAL" | sed -e '1,2d' | cut -d'/' -f2- | xargs -I "%" echo /%)

true > "$carpetaExportacionMaquina""discos_Asociado_""$VM_NUEVA"

for disco in $discos; do
	arrayContineElemento "$DISCOS_A_EXCLUIR" "$disco"
	existeElemento=$?
	if [ "$existeElemento" = "1" ]; then
		# Guardamos los discos que se estan copiando para usarlo al importar
		echo "$nombreDisco|NO_COPY">> "$carpetaExportacionMaquina""discos_Asociado_""$VM_NUEVA"
		sed -i "s|$disco|$nombreDisco|g" "$carpetaExportacionMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
		comprobarEjecucion $? "Fallo modificando XML para el disco $disco"
		continue
	fi
	logger -is " $(basename $0) INFO: Exportando disco $disco"
	# Guardamos los discos que se estan copiando para usarlo al importar
	echo "$nombreDisco|COPY" >> "$carpetaExportacionMaquina""discos_Asociado_""$VM_NUEVA"
	# Copiamos los discos a la carpeta elegida para la exportacion
	cp -p "$disco" "$carpetaExportacionMaquina""$nombreDisco" > /dev/null 2>&1
	comprobarEjecucion $? "Fallo copiadando el $disco"
	# Modificamos el XML de maquina exportada para borrar la ruta antigua de los discos
	sed -i "s|$disco|$nombreDisco|g" "$carpetaExportacionMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
	comprobarEjecucion $? "Fallo modificando XML para el disco $disco"

done

logger -is " $(basename $0) INFO: Eliminando el uuid y macs para que al generar de nuevo la maquina se auto genere "
# Eliminamos el uuid y macs para que al generar de nuevo la maquina se auto genere 
sed -i '/uuid/d' "$carpetaExportacionMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
comprobarEjecucion $? "Fallo eliminando el uuid de la maquina en el XML"

sed -i '/mac address/d' "$carpetaExportacionMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
comprobarEjecucion $? "Fallo eliminando las dirrecciones MAC de la maquina en el XML"

logger -is " $(basename $0) INFO: Cambiando el nombre de la maquina por $VM_NUEVA"
# Cambiamos el nombre de la maquina
sed -i "s/name>$VM_ORIGINAL/name>$VM_NUEVA/" "$carpetaExportacionMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
comprobarEjecucion $? "Fallo sustituyendo el nombre de la maquina $VM_ORIGINAL por $VM_NUEVA XML"

# Quedaria ver si se desea usar virt-sysprep -a discos pra tratar las maquinas antes de comprimirla

# Comprimimos si esta habilitada esta opcion con el nombre del dia de la exportacion y el nuevo nombre de la maquina 
if [ "$COMPRIMIR" = "TRUE"  ]; then
	fechaActual=$(date +%m-%d-%Y)
	nombreTar=$fechaActual$VM_NUEVA".tar.gz"
	true > "$ERROR_COMPRIMIR"
	logger -is " $(basename $0) INFO: Comprimiendo la exportacion en $carpetaSeleccionada$nombreTar"
	tar --remove-files -C "$carpetaExportacionMaquina" -czvf  "$carpetaSeleccionada""$nombreTar" ./ > "$ERROR_COMPRIMIR" 2>&1
	salida=$?
	ERROR=$(cat "$ERROR_COMPRIMIR")
	comprobarEjecucion $? "Fallo al comprimir $nombreTar debido a \n $ERROR"
	rm "$ERROR_COMPRIMIR"
fi

# Reactivamos la maquina original si anteriormente estuviera activa
if [ $estadoAnteriorActivo = "TRUE" ]; then
	#Rearrancamos la original maquina
	virsh start "$VM_ORIGINAL" > /dev/null 2>&1
	comprobarEjecucion $? "Fallo al rearrancar la maquina $VM_ORIGINAL" "NO_BORRAR"
fi

logger -is " $(basename $0) INFO: Finalizada la exportacion de la maquina $VM_ORIGINAL a $VM_NUEVA"