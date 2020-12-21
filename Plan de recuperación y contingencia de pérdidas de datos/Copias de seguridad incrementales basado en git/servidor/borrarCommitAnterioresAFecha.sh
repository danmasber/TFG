#!/bin/sh

# Este script recibe como parametro una cadena que indica cuanto se debe retroceder para tomar el primer commit 
# anterior a dicha fecha y borrar el historio anterior a dicho commit
# El formato es 'X Y ago' siendo Y month , year, day , hour , minute , second y X el numero de divisiones de tiempo que se quiere
# retoceder
# ADVERTENCIA Este script no puede hacerse si tienen rama fusionadas

configuracion=$(dirname "$0")"/"configuracionRepo.cfg
. "$configuracion"

# La funcion comprobarEjecucion evalua si hubo un error al ejecutar el ultimo comando y muestra un mensaje de lo ocurrido.
# Si ocurrio un error provoca la salida del script		
# Tambien sino se le indica borrar los archivos asociado a la exportacion fallida
# ENTRADA salida del comando , mensaje a mostrar y si debe borrar la rama temporal
# SALIDA ninguna 
comprobarEjecucion(){
	salida=$1  
	mensaje=$2
	borrarRama=$3
	if [ "$salida" != "0" ]; then
		if [ "$borrarRama" = "TRUE" ]; then
			git branch -D rama_temporal
		fi
    	if [ "$mensaje" != "" ]; then
			 logger -is "$(basename "$0") ERROR: $mensaje"
		fi
		exit "$salida"
	fi	
} 

TIEMPO_A_RETROCEDER=$1

if [ "$TIEMPO_A_RETROCEDER" == "" ]; then
	comprobarEjecucion 1 "Se requieren un tiempo determinado a retroceder en para acortar realizar el borrado de commit"
fi

FECHA=$(date "+%Y/%m/%d %T" -d "-$TIEMPO_A_RETROCEDER")
FECHA_PARA_COMMIT=$(date -d "$TIEMPO_A_RETROCEDER")

logger -is  "$(basename "$0") INFO: Iniciando borrado del historico del repositorio anterior a la fecha $FECHA"


# Comprobamos que se ejecute el script como root para cambiar de usuario sin poner contraseña
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 1 "Se requieren permisos de administrador para continuar con el script"
fi

# Coomprobamos que este instalado git
command -v git > /dev/null  2>&1
comprobarEjecucion $? "Debe estar instalado git"

# Comprobamos que se este instalado el comando git-store-meta.pl 
command -v git-store-meta.pl > /dev/null  2>&1
comprobarEjecucion $? "Debe estar instalado git-store-meta.pl"

# Accedemos a la carpeta $CARPETA_REPOSITORIO
logger -is  "$(basename "$0") INFO: Accedemos a la carpeta $CARPETA_REPOSITORIO"
cd "$CARPETA_REPOSITORIO"  || comprobarEjecucion 1 "Accediendo a la carpeta $CARPETA_REPOSITORIO"

# Buscamos el primer commit anterior a una fecha en la rama master
logger -is  "$(basename "$0") INFO: Buscamos el primer commit anterior a la fecha($TIEMPO_A_RETROCEDER) indica en la rama master"
HEAD_ANTERIOR=$(git rev-list -1 --before="$TIEMPO_A_RETROCEDER" --date=relative master)
comprobarEjecucion $? "Buscando HEAD anterior a la fecha $FECHA"

[ "$HEAD_ANTERIOR" != "" ] || comprobarEjecucion 1 "No se encontro una revision anterior a la fecha $FECHA"

# Creamos la rama temporal para hacer el borrado del historico anterio desde $HEAD_ANTERIOR
logger -is  "$(basename "$0") INFO: Creamos la rama temporal para hacer el borrado del historico anterio desde $HEAD_ANTERIOR"
git checkout --orphan rama_temporal "$HEAD_ANTERIOR"
comprobarEjecucion $? "Creando la rama temporal desde el HEAD $HEAD_ANTERIOR" 

# Hacemos un commit indicado un mensaje para localizar bien cuando se realizo el borrado del historicos
# Además es necesario hacer un commit en la rama temporal en el proceso
# Seleccionamos la fecha con la que se hara el commit para que tenga la misma que la que se desea como limite
logger -is  "$(basename "$0") INFO: Haciendo commit en la rama temporal creada desde $HEAD_ANTERIOR"
GIT_COMMITTER_DATE="$FECHA_PARA_COMMIT" git commit --date "$FECHA_PARA_COMMIT" -m "Truncado del historial antes de la $FECHA" 
comprobarEjecucion $? "Haciendo commit en la rama temporal" "TRUE"

# Cambiamos el inicio de la rama master por la agrupacion de todos los commit desde el inicio hasta $HEAD_ANTERIOR
logger -is  "$(basename "$0") INFO: Cambiamos el inicio de la rama master por la agrupacion de todos los commit desde el inicio hasta $HEAD_ANTERIOR"
git rebase --committer-date-is-author-date --onto rama_temporal "$HEAD_ANTERIOR" master
comprobarEjecucion $? "Agrupando todos los commit desde el inicio del repositorio hasta el commit con HEAD $HEAD_ANTERIOR" "TRUE"

# Borramos la rama temporal 
logger -is  "$(basename "$0") INFO:  Borramos la rama temporal rama_temporal"
git branch -D rama_temporal
comprobarEjecucion $? "Borrando la rama temporal"

# Los siguientes 2 comandos son opcionales: mantienen su repositorio de git en buena forma.
# Borramos todos los archivos sin referencia
logger -is  "$(basename "$0") INFO: Borramos todos los archivos sin referencia"
git prune --progress 
comprobarEjecucion $? "Error borrando todos los archivos sin referencia"

# Recolectamos basura del repositorio ; puede tomar mucho tiempo en repositorios grandes
logger -is  "$(basename "$0") INFO: Recolectamos basura del repositorio"
git gc --aggressive 
comprobarEjecucion $? "Error  recolectando basura agresivamente"

logger -is  "$(basename "$0") INFO: Finalizado borrado del historico del repositorio a la fecha $FECHA"