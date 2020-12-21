#!/bin/sh
configuracion=$(dirname "$0")"/"configuracionScriptVirsh.cfg
. "$configuracion"

# Este script permite la exportacion de una maquina virtual KVM. Durante la ejecucion se solicitara 
# si se desea comprimir el rusultado o incluir lo fichero que representan los discos duros.
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
			echo -e "\e[31mERROR:$mensaje\e[0m"
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
  comprobarEjecucion 1 "Se requieren pesmisos de administrador para continuar con el script"
fi

#Comprobamos que se haya pasado la maquina a exportar como argumento o la solicitamos
if [ "$1" = "" ]; then
	echo "Introduce la maquina original "
	read -r VM_ORIGINAL 
else 
	VM_ORIGINAL=$1
fi	

#Comprobamos que se haya introducido o pasado como argumento una maquina 
if [ "$VM_ORIGINAL" = "" ]; then
	comprobarEjecucion 1 "No se ha introducido ninguna maquina"
fi	

#Comprobamos que la maquina a exportar exista
echo "Comprobando si existe la maquina $VM_ORIGINAL"
virsh dominfo --domain "$VM_ORIGINAL" > /dev/null 2>&1
salida=$?
comprobarEjecucion "$salida" "La maquina original $VM_ORIGINAL no existe"

# Solicitamos un nuevo nombre para la maquina despues de exportarla y comprobamos si se ha introucido alguno
echo "Introduce nombre para la maquina nueva " 
read -r VM_NUEVA 

if [ "$VM_NUEVA" = "" ]; then
	comprobarEjecucion 1 "No se ha introduciodo un nuevo nombre para la maquina"
fi

# Solicitamos la carpeta donde exportar la maquina y comprobamos si se ha introucido alguna
echo "La ruta de la carpeta donde realizar la copia " 
read -r carpetaSeleccionada

if [ "$carpetaSeleccionada" = "" ]; then
	comprobarEjecucion 1 "La carpeta $carpetaSeleccionada no existe"
fi

# Comprobamos que la carpeta destino de la exportacion exista
carpetaSeleccionada=$carpetaSeleccionada"/tmp"
carpetaSeleccionada=$(dirname "$carpetaSeleccionada")"/"
if [ ! -d "$carpetaSeleccionada" ]; then
	comprobarEjecucion 1 "La carpeta $carpetaSeleccionada no existe"
fi

# Solicitamos si desea comprimir tras la exportacion 
while [ true ]; do
	echo "¿Deseas comprimir tras realizar la exportación?(Y/N) " 
	read -r eleccion
	case $eleccion in
		"Y"|"y" )
			comprimir="TRUE"
			break
		;;
		"N"|"n" )
			comprimir="FALSE"
			break
		;;
	esac
	echo "Debes seleccionar Y, y, N o n"
	sleep 2
done


#Comprobamos que la maquina a exportar se encuentra corriendo
if [ $(virsh list --state-running  | sed "12d" | grep " $VM_ORIGINAL " | wc -l) = 1 ]; then
	estadoAnteriorActivo="TRUE"
fi

# Creamos la carpeta donde realizaremos la exportacion
mkdir -p "$carpetaSeleccionada""$VM_NUEVA"
comprobarEjecucion $? "Fallo al crear la carpeta para realizar la copia $carpetaSeleccionada$VM_NUEVA"
carpetaExportacionMaquina=$carpetaSeleccionada$VM_NUEVA"/" 


if [ $estadoAnteriorActivo = "TRUE" ]; then
	# Apagamos la maqiona original antes de copiar no seria necesario pero es recomendable
	echo "Apagamos la maqiona original antes de copiar"
	virsh shutdown "$VM_ORIGINAL" > /dev/null 2>&1
	comprobarEjecucion $? "Fallo el apagado de la maquina $VM_ORIGINAL"
fi

# Extraemos el XML de la maquina para modificarla y guardarla
echo "Extraemos el XML de la maquina para modificarla y guardarla"
virsh dumpxml "$VM_ORIGINAL" > "$dirExportacionMaquina""$VM_NUEVA"".xml" 2> /dev/null 
comprobarEjecucion $? "Fallo el volcado a XML de la maquina $VM_ORIGINAL"


# Consultamos los discos actuales que se estan asociados
discos=$(virsh domblklist "$VM_ORIGINAL" | sed -e '1,2d' | cut -d'/' -f2- | xargs -I "%" echo /%)

# Si no esta configurada la seleccion de disco preguntamos si se quiere selecionar
if [ "$SELECCIONAR_DISCOS" = "" ]; then
	while [ true ]; do
	echo "¿Deseas selecionar que deseas expoertar?(Y/N) Por defecto se exportaran todos" 
	read -r eleccion
	case $eleccion in
		"Y"|"y" )
			SELECCIONAR_DISCOS="TRUE"
			break
		;;
		"N"|"n" )
			SELECCIONAR_DISCOS="FALSE"
			break
		;;
	esac
	echo "Debes seleccionar Y, y, N o n"
	sleep 2
done
fi

# Si se desea seleccionar los discos a exportar se pregunta cuales de ellos NO se quiere exportar
if [ "$SELECCIONAR_DISCOS" = "TRUE" ]; then
	echo "Introduce las maquinas que no quieres copiar separada por espacio \n $discos" 
	read -r discosAExcluir
fi

true > "$carpetaExportacionMaquina""discos_Asociado_""$VM_NUEVA"

for disco in $discos; do
	if [ "$SELECCIONAR_DISCOS" = "TRUE" ]; then
		arrayContineElemento "$discosAExcluir" "$disco"
		existeElemento=$?
		if [ "$existeElemento" = "1" ]; then
			# Guardamos los discos que se estan copiando para usarlo al importar
			echo "$nombreDisco|NO_COPY">> "$carpetaExportacionMaquina""discos_Asociado_""$VM_NUEVA"
			sed -i "s|$disco|$nombreDisco|g" "$carpetaExportacionMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
			comprobarEjecucion $? "Fallo modificando XML para el disco $disco"
			continue
		fi
	fi

	echo "Exportando disco $disco"
	# Guardamos los discos que se estan copiando para usarlo al importar
	echo "$nombreDisco|COPY" >> "$carpetaExportacionMaquina""discos_Asociado_""$VM_NUEVA" 
	# Copiamos los discos a la carpeta elegida para la exportacion
	cp -p "$disco" "$carpetaExportacionMaquina""$nombreDisco" > /dev/null 2>&1
	comprobarEjecucion $? "Fallo copiadando el $disco"
	# Modificamos el XML de maquina exportada para borrar la ruta antigua de los discos
	sed -i "s|$disco|$nombreDisco|g" "$carpetaExportacionMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
	comprobarEjecucion $? "Fallo modificando XML para el disco $disco"

done

echo "Eliminando el uuid y macs para que al generar de nuevo la maquina se auto genere "
# Eliminamos el uuid y macs para que al generar de nuevo la maquina se auto genere 
sed -i '/uuid/d' "$carpetaExportacionMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
comprobarEjecucion $? "Fallo eliminando el uuid de la maquina en el XML"

sed -i '/mac address/d' "$carpetaExportacionMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
comprobarEjecucion $? "Fallo eliminando las dirrecciones MAC de la maquina en el XML"

echo "Cambiando el nombre de la maquina por $VM_NUEVA"
# Cambiamos el nombre de la maquina
sed -i "s/name>$VM_ORIGINAL/name>$VM_NUEVA/" "$carpetaExportacionMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
comprobarEjecucion $? "Fallo sustituyendo el nombre de la maquina $VM_ORIGINAL por $VM_NUEVA XML"

# Quedaria ver si se desea usar virt-sysprep -a discos pra tratar las maquinas antes de comprimirla

# Comprimimos si esta habilitada esta opcion con el nombre del dia de la exportacion y el nuevo nombre de la maquina   
if [ "$COMPRIMIR" = "TRUE"  ]; then
	fechaActual=$(date +%m-%d-%Y)
	nombreTar=$fechaActual$VM_NUEVA".tar.gz"
	true > "$ERROR_COMPRIMIR"
	echo "Comprimiendo la exportacion en $carpetaSeleccionada$nombreTar"
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