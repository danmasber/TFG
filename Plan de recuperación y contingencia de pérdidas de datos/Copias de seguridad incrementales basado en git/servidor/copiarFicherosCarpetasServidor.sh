#!/bin/sh

#
# Este script copia en la carpeta configurada en configuracionRepo.cfg(CARPETA_REPOSITORIO) los ficheros y carpetas indicada 
# en ficherosYCarptasRepositorio.cfg(Un Fichero/Carpeta por linea)

configuracion=$(dirname "$0")"/"configuracionRepo.cfg
. "$configuracion"

#Este fichero contine las rutas absolutas de ficheros o carpetas que se desean copiar en el repositorio y una por linea
ficherosYCarptasRepositorio=$(dirname "$0")"/"ficherosYCarptasRepositorio.cfg
ficherosYCarptasRepositorio=$(readlink -f "$ficherosYCarptasRepositorio")

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
			 logger -is "$(basename "$0") ERROR: $mensaje"
		fi
		if [ -f  "${ficherosYCarptasRepositorio}TMP" ]; then
			rm -f  "${ficherosYCarptasRepositorio}TMP"
		fi

		if [ -f  "${ficherosYCarptasRepositorio}Patron" ]; then
			rm -f  "${ficherosYCarptasRepositorio}Patron"
		fi
		exit "$salida"
	fi
}


logger -is  "$(basename "$0") INFO: Iniciando copia de los ficheros en la carpeta $CARPETA_REPOSITORIO"

# Comprobamos que se ejecute el script como root para cambiar de usuario sin poner contraseña
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 1 "Se requieren permisos de administrador para continuar con el script"
fi

# Comprobamos que se este instalado el comando rsync
command -v rsync > /dev/null  2>&1
comprobarEjecucion $? "Debe estar instalado rsync"


# Accedemos a la carpeta $CARPETA_REPOSITORIO

logger -is  "$(basename "$0") INFO: Accedemos a la carpeta $CARPETA_REPOSITORIO"
[ -d  "$CARPETA_REPOSITORIO" ] || comprobarEjecucion 1 "No existe  la carpeta $CARPETA_REPOSITORIO"

logger -is  "$(basename "$0") INFO: Comprobamos que existe el fichero ficherosYCarptasRepositorio.cfg"
[ -f "$ficherosYCarptasRepositorio" ] || comprobarEjecucion 1 "No existe el fichero ficherosYCarptasRepositorio.cfg"

logger -is  "$(basename "$0") INFO: Copiamos los archivos indicado en $ficherosYCarptasRepositorio"

#Eliminamos la lineas comentado o comentarios en una linea
sed 's:#[^"]*$::g' "$ficherosYCarptasRepositorio" | grep "\S" > "${ficherosYCarptasRepositorio}TMP"
while IFS= read -r linea
do
	# Eliminamos los espacios en blanco
	linea=$(echo "$linea" | sed -E 's/ *$//')

	if [ "$linea" != "" ]; then
		#Preparamos la linea leida por si fuerea una carpeta hacer la copia recuersivamente de esta
		lineaRsync="$linea"

		if [ -d "$lineaRsync" ]; then
	    	lineaRsync="${lineaRsync}/"
		fi
		# Copiamos los ficheros indicado en una de las lineas del fichero ficherosYCarptasRepositorio.cfg
		logger -is  "$(basename "$0") INFO: Copiando el fichero/carpeta $linea"
		rsync -acPRAX --delete-after "$lineaRsync" "$CARPETA_REPOSITORIO"  > /dev/null  2>&1
		comprobarEjecucion $? "Copiando el fichero/carpeta $linea en $CARPETA_REPOSITORI."	
	fi
done < "${ficherosYCarptasRepositorio}TMP"

logger "$(basename "$0") INFO: Creamos el fichero que contendra el patron de los ficheros a mantener"

sed 's/ *$//g' "${ficherosYCarptasRepositorio}TMP" | sed 's/\/$//' | sed 's/\//\\\//g'  | sed 's/^/\^\./' | sed 's/ $//' > "${ficherosYCarptasRepositorio}Patron"

logger -is  "$(basename "$0") INFO: Eliminamos los archivos que no estan indicado en $ficherosYCarptasRepositorio"
cd "$CARPETA_REPOSITORIO" || comprobarEjecucion 1 "Accediendo a $CARPETA_REPOSITORIO"

for elemento in  $( find . | grep -vE "^\./\.|^\.$"   | grep -v -f "${ficherosYCarptasRepositorio}Patron" | sort -rn ); do
	elemento=$(echo "$elemento" | sed 's/^\.//')
	if ! grep "^$elemento" "${ficherosYCarptasRepositorio}TMP" > /dev/null  2>&1 ; then
		logger -is  "$(basename "$0") INFO: Borrando el fichero/carpeta $elemento por no estar en $ficherosYCarptasRepositorio"
		rm -Rf "$CARPETA_REPOSITORIO$elemento"
		comprobarEjecucion $? "Borrando el fichero/carpeta $elemento en $CARPETA_REPOSITORIO"	
	fi
done

rm  -f "${ficherosYCarptasRepositorio}TMP"
rm -f "${ficherosYCarptasRepositorio}Patron"
logger -is  "$(basename "$0") INFO: Finalizado copia de los ficheros en la carpeta $CARPETA_REPOSITORIO"
