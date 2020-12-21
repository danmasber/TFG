#!/bin/sh
export NCURSES_NO_UTF8_ACS=1 # Evitar que aparezcan caracteres en lugar de lineas
configuracion=$(dirname "$0")"/"configuracionScriptVirsh.cfg
. "$configuracion"

# Este script permite la exportacion de una maquina virtual KVM. Durante la ejecucion se solicitara 
# si se desea comprimir el rusultado o incluir lo fichero que representan los discos duros.
# Este script hace uso de menu para solicitar la ubicacion donde almacenar el resultado, si se desea comprimir o los discos a incluir en la copia
# Debe ser ejecutado como root
# Este script tiene que recibir como parametro la maquina a exportar 

VM_ORIGINAL=$1
dialogAlias='dialog --cancel-label Atras --stdout --clear --backtitle'
dialogAliasNoClear='dialog  --cancel-label Atras --stdout --backtitle'
tituloMenu=$(echo "Realizando exportacion de la maquina ""$VM_ORIGINAL")

estadoAnteriorActivo="FALSE"

trap "clear" 1 2 15

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
		
		if [ -f "$ERROR_COMPRIMIR" ]; then
			rm "$ERROR_COMPRIMIR"
		fi

		if [ -d "$carpetaBackupMaquina" ] && [ "$borrarTemporales" != "NO_BORRAR" ]; then
			rm -R "$carpetaBackupMaquina"
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

# Comprobamos que se este instalado el comando dialog
command -v dialog > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado dialog"

# Comprobamos que se ejecute el script como root para poder acceder a virsh
if [ "$(whoami)" != 'root' ]; then
	comprobarEjecucion 1 "Se requieren pesmisos de administrador para continuar con el menu"
fi

# Comprobamos que se haya pasado la maquina a exportar como argumento
if [ "$1" = "" ]; then
	comprobarEjecucion 1 "Se requieren introducir como paramtro una maquina \n $0 nombreMaquina"
fi	

#Comprobamos que la maquina a exportar exista
$dialogAlias "$tituloMenu" --msgbox "Comprobando que la maquina $VM_ORIGINAL a exportar existe" 10 50
virsh dominfo --domain "$VM_ORIGINAL" > /dev/null 2>&1
salida=$?
comprobarEjecucion "$salida" "La maquina original $VM_ORIGINAL no existe"

# Solicitamos un nuevo nombre para la maquina despues de exportarla y comprobamos si se ha introucido alguno
VM_NUEVA=$($dialogAlias "$tituloMenu" --inputbox "Seleccion un nombre para la maquina exportada:" 8 50 "$VM_ORIGINAL")
if [ "$VM_NUEVA" = "" ]; then
  comprobarEjecucion 1 "No se ha introucido un nombre nuevo para $VM_ORIGINAL" 
fi

if [ ! -d "$DIRECTORIO_POR_DEFECTO_DESTINO" ]; then
	DIRECTORIO_POR_DEFECTO_DESTINO="$PWD"
fi

# Solicitamos la carpeta donde exportar la maquina y comprobamos si se ha introucido alguna
carpetaSeleccionada=$($dialogAlias "$tituloMenu" --title "Seleccione la carpeta donde guardar la maquina exportada" --dselect "$DIRECTORIO_POR_DEFECTO_DESTINO" 8 50)
salida=$? 
comprobarEjecucion "$salida" "No se seleciono ninguna carpeta" 
if [ "$carpetaSeleccionada" = "" ]; then
	comprobarEjecucion 1  "La carpeta $carpetaSeleccionada no existe"
fi

# Comprobamos que la carpeta destino de la exportacion exista
carpetaSeleccionada=$carpetaSeleccionada"/tmp"
carpetaSeleccionada=$(dirname "$carpetaSeleccionada")"/"
if [ ! -d "$carpetaSeleccionada" ]; then
	comprobarEjecucion 1 "La carpeta $carpetaSeleccionada no existe"
fi

# Solicitamos si desea comprimir tras la exportacion 
$dialogAlias "$tituloMenu"  --yesno "¿Deseas comprimir?" 8 50

salida=$?  	
  case $salida in
  	0)
  	COMPRIMIR="TRUE"
  	;;
    1)
	COMPRIMIR="FALSE"
	;;
	255) 
      clear
      exit $salida
    ;;
esac

#Comprobamos que la maquina a exportar se encuentra corriendo
if [ $(virsh list --state-running  | sed "12d" | grep -c " $VM_ORIGINAL ") = 1 ]; then
	estadoAnteriorActivo="TRUE"
fi
 
 # Creamos la carpeta donde realizaremos la exportacion
mkdir -p "$carpetaSeleccionada""$VM_NUEVA"
comprobarEjecucion $? "Fallo al crear la carpeta para realizar la copia $carpetaSeleccionada$VM_NUEVA"
carpetaBackupMaquina=$carpetaSeleccionada$VM_NUEVA"/" 


# Calculamos los porcentaje de cada paso de la exportacion
porcentaje=0
if [ $estadoAnteriorActivo = "TRUE" ]; then
	pasoPorcentaje=$((100/8))
else
	pasoPorcentaje=$((100/6))
fi

if [ $estadoAnteriorActivo = "TRUE" ]; then
	$dialogAliasNoClear "$tituloMenu" --title "Realizando exportacion" --gauge "Apagango la maquina $VM_ORIGINAL" 10 80 $porcentaje &
	# Apagamos la maquina original antes de copiar no seria necesario pero es recomendable
	virsh shutdown "$VM_ORIGINAL" > /dev/null 2>&1
	comprobarEjecucion $? "Fallo el apagado de la maquina $VM_ORIGINAL"
	porcentaje=$((porcentaje + pasoPorcentaje))
	sleep 1
fi

$dialogAliasNoClear "$tituloMenu" --title "Realizando exportacion" --gauge "Extraemos el XML de la maquina para modificarla y guardarla" 10 80 $porcentaje &
# Extraemos el XML de la maquina para modificarla y guardarla
virsh dumpxml "$VM_ORIGINAL" > "$carpetaBackupMaquina""$VM_NUEVA"".xml" 2> /dev/null 
comprobarEjecucion $? "Fallo el volcado a XML de la maquina $VM_ORIGINAL"
porcentaje=$((porcentaje + pasoPorcentaje))
sleep 1

# Consultamos los discos actuales que se estan asociados
discos=$(virsh domblklist "$VM_ORIGINAL" | sed -e '1,2d' | cut -d'/' -f2- | xargs -I "%" echo /%)
listadoDiscosActuales=""
numeroDiscosActuales=0

# Solicitamos si desea comprimir tras la exportacion 
$dialogAlias "$tituloMenu"  --yesno "¿Deseas seleccionar los discos a exportar? Por defecto se exportaran todos" 8 50

salida=$?  	
  case $salida in
  	255) 
      clear
      exit $salida
    ;;
  	0)
  	SELECCIONAR_DISCOS="TRUE"
  	;;
    1)
	SELECCIONAR_DISCOS="FALSE"
	;;
	
esac

# Si se desea seleccionar los discos a exportar se pregunta cuales de ellos se quiere exportar
if [ "$SELECCIONAR_DISCOS" = "TRUE" ]; then
	for i in $discos; do
	    listadoDiscosActuales="$listadoDiscosActuales $i $i ON "
	    numeroDiscosActuales=$((numeroDiscosActuales+1))
	done
	if [ $numeroDiscosActuales -gt 1 ]; then 
	discosSelecionados=$($dialogAlias "$tituloMenu" --no-tags --cancel-label "Atras"  --checklist "Selecciones los discos a copiar" 8 50 0 $listadoDiscosActuales)
	comprobarEjecucion $? "Se ha cancelado la seleccion de disco"
	else
		$dialogAlias "$tituloMenu"  --yesno "¿Deseas copiar el disco $discos ?" 8 50
		salida=$?  	
  		case $salida in
  			0)
  			discosSelecionados=$listadoDiscosActuales
  			break
  			;;
  			255) 
		      clear
		      exit $salida
		    ;;
		esac
		
	fi
else
	for i in $discos; do
	    discosSelecionados="$discosSelecionados $i"
	done
fi

numeroDiscos=0
for i in $discosSelecionados; do
	 numeroDiscos=$((numeroDiscos+1))
done

if [ "$numeroDiscos" = "0" ]; then
	pasoDiscoPorcentaje=$pasoPorcentaje
else
	pasoDiscoPorcentaje=$((pasoPorcentaje/numeroDiscos))
fi

true > "$carpetaBackupMaquina""discos_Asociado_""$VM_NUEVA"
for disco in $discos; do
	nombreDisco=$(basename "$disco")
	if [ "$SELECCIONAR_DISCOS" = "TRUE" ]; then
		arrayContineElemento "$discosSelecionados" "$disco"
		existeElemento=$?
		if [ "$existeElemento" = "0" ]; then
			echo "$nombreDisco|NO_COPY">> "$carpetaBackupMaquina""discos_Asociado_""$VM_NUEVA"
			sed -i "s|$disco|$nombreDisco|g" "$carpetaBackupMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
			comprobarEjecucion $? "Fallo modificando XML para el disco $disco"
			continue
		fi
	fi
	# Guardamos los discos que se estan copiando para usarlo al importar
	$dialogAliasNoClear "$tituloMenu" --title "Realizando exportacion" --gauge "Copiando disco $nombreDisco a $carpetaBackupMaquina " 10 80 $porcentaje &
	echo "$nombreDisco|COPY" >> "$carpetaBackupMaquina""discos_Asociado_""$VM_NUEVA"
	# Copiamos los discos a la carpeta elegida para la exportacion
	cp -p "$disco" "$carpetaBackupMaquina""$nombreDisco" > /dev/null 2>&1
	comprobarEjecucion $? "Fallo copiadando el $disco"
	# Modificamos el XML de maquina exportada para borrar la ruta antigua de los discos
	sed -i "s|$disco|$nombreDisco|g" "$carpetaBackupMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
	comprobarEjecucion $? "Fallo modificando XML para el disco $disco"

	porcentaje=$((porcentaje + pasoDiscoPorcentaje))
done
sleep 1


# Quedaria ver si se desea usar virt-sysprep -a discos pra tratar las maquinas antes de comprimirla

$dialogAliasNoClear "$tituloMenu" --title "Realizando exportacion" --gauge "Elimindo UUID de la maquina original" 10 80 $porcentaje &
# Eliminamos el uuid y macs para que al generar de nuevo la maquina se auto genere 
sed -i '/uuid/d' "$carpetaBackupMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
comprobarEjecucion $? "Fallo eliminando el uuid de la maquina en el XML"
porcentaje=$((porcentaje + pasoPorcentaje))
sleep 1

$dialogAliasNoClear "$tituloMenu" --title "Realizando exportacion" --gauge "Elimindo direcciones MAC de la maquina original" 10 80 $porcentaje &
sed -i '/mac address/d' "$carpetaBackupMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
comprobarEjecucion $? "Fallo eliminando las dirrecciones MAC de la maquina en el XML"
porcentaje=$((porcentaje + pasoPorcentaje))
sleep 1

# Cambiamos el nombre de la maquina
$dialogAliasNoClear "$tituloMenu" --title "Realizando exportacion" --gauge "Cambiando nombre de $VM_ORIGINAL a $VM_NUEVA" 10 80 $porcentaje &
sed -i "s/name>$VM_ORIGINAL/name>$VM_NUEVA/" "$carpetaBackupMaquina""$VM_NUEVA"".xml" > /dev/null 2>&1
comprobarEjecucion $? "Fallo sustituyendo el nombre de la maquina $VM_ORIGINAL por $VM_NUEVA XML"
porcentaje=$((porcentaje + pasoPorcentaje))
sleep 1

# Quedaria ver si se desea usar virt-sysprep -a discos pra tratar las maquinas antes de comprimirla

# Comprimimos si esta habilitada esta opcion con el nombre del dia de la exportacion y el nuevo nombre de la maquina 
if [ "$COMPRIMIR" = "TRUE"  ]; then
	fechaActual=$(date +%m-%d-%Y)
	nombreTar=$fechaActual$VM_NUEVA".tar.gz"
	$dialogAliasNoClear "$tituloMenu" --title "Realizando exportacion" --gauge "Comprimiendo en los archivos en $nombreTar \n Se eliminaran la carpeta $carpetaBackupMaquina" 10 80 $porcentaje &
	true > "$ERROR_COMPRIMIR"
	tar --remove-files -C "$carpetaBackupMaquina" -czvf  "$carpetaSeleccionada""$nombreTar" ./ > "$ERROR_COMPRIMIR" 2>&1
	salida=$?
	ERROR=$(cat "$ERROR_COMPRIMIR")
	comprobarEjecucion $? "Fallo al comprimir $nombreTar debido a \n $ERROR"
	rm "$ERROR_COMPRIMIR"
	sleep 1
fi

porcentaje=$((porcentaje + pasoPorcentaje))

# Reactivamos la maquina original si anteriormente estuviera activa
if [ $estadoAnteriorActivo = "TRUE" ]; then
	$dialogAliasNoClear "$tituloMenu" --title "Realizando exportacion" --gauge "Reactivando la maquinasquina $VM_ORIGINAL" 10 80 $porcentaje &	
	#Rearrancamos la original maquina
	virsh start "$VM_ORIGINAL" > /dev/null 2>&1
	comprobarEjecucion $? "Fallo al rearrancar la maquina $VM_ORIGINAL" "NO_BORRAR"
	sleep 1
fi

porcentaje=100
$dialogAliasNoClear "$tituloMenu" --title "Realizando exportacion" --gauge "Se ha completado la copia con éxito" 10 80 $porcentaje &
sleep 3	
