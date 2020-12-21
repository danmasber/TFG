#!/bin/sh

#
# Este script realiza commit con mensaje la fecha de hoy  y con todo lo que contiene la carperta
# que contiene el repositorio configurado en configuracionRepo.cfg(CARPETA_REPOSITORIO) y cuyo usuario propietario tambien 
# esta configurado en  configuracionRepo.cfg(USUARIO_REPOSITORIO)
#

configuracion=$(dirname "$0")"/"configuracionRepo.cfg
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
			 logger -is "$(basename "$0") ERROR: $mensaje"
		fi
		exit "$salida"
	fi	
} 

mostrarAyuda(){
    echo "    El modo de usar el script es el siguiente"
    echo "        $0 [-h] [-?]  [-m mensajeCommit]"
    echo ""
    echo "    	-h -? 	Mostar ayuda"
    echo "		-m 	mensajeCommit Indica el mensaje que se incluirá en el commit "
    echo ""
    exit 1
}

while getopts ':m: i?h' c
do
  case $c in
	m) MENSAJE="$OPTARG"
    h|\?) mostrarAyuda;;
  esac
done


logger -is  "$(basename "$0") INFO: Iniciando commit de repositorio con fecha $FECHA"

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


# Añadimos todos los archivos que hay en la carpeta por si existira nuevos para realizar el commit
logger -is  "$(basename "$0") INFO: Añadimos todos los archivos que hay en la carpeta por si existira nuevos para realizar el commit"
git add -A > /dev/null 2>&1
comprobarEjecucion $? "Configurando el commit $FECHA"

#Verificamos que existan cambios para no realizar un commit si nada que provocaria error
logger -is  "$(basename "$0") INFO: Comprobando si hay cambios que commitear"
git diff --cached --exit-code > /dev/null 2>&1 
resultado_contenido_commit="$?"
if [ "$resultado_contenido_commit" != "1" ]; then
	if [ "$resultado_contenido_commit" != "0" ]; then
		comprobarEjecucion "$resultado_contenido_commit" "Comprobando si hay cambios que commitear"
	fi
	logger -is  "$(basename "$0") INFO: No hay ningun cambio que commit"
	logger -is  "$(basename "$0") INFO: Finalizado commit de repositorio con fecha $FECHA"
	exit 0
fi

FECHA=$(date '+%Y/%m/%d %T')

# Realizamos el commit
logger -is  "$(basename "$0") INFO: Realizamos el commit con fecha $FECHA"
if [ "$MENSAJE" == "" ]; then
	git commit -a -m "Backup $FECHA - $MENSAJE"  > /dev/null 2>&1
else
	git commit -a -m "Backup $FECHA"  > /dev/null 2>&1	
fi
comprobarEjecucion $? "Realizando el commit con fecha $FECHA"

logger -is  "$(basename "$0") INFO: Finalizado commit de repositorio con fecha $FECHA"