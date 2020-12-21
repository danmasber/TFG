#!/bin/sh
#
# Para poder clonar es necesario configurada la conexion ssh mediante clave publica para el usuario root para el usuario USUARIO_REPOSITORIO 
#
# Este script realiza la actualizacion del repositorio configurado en configuracionRepoCliente.cfg(NOMBRE_REPOSITORIO) 
# ubicado en la carpeta configuradado en configuracionRepoCliente.cfg(CARPETA_REPOSITORIO_LOCAL) propietadad el usuario 
# configuradado en configuracionRepoCliente.cfg(USUARIO_REPOSITORIO_LOCAL)

configuracion=$(dirname "$0")"/"configuracionRepoCliente.cfg
. "$configuracion"

MODO_ITERATIVO="FALSE"

# La funcion comprobarEjecucion evalua si hubo un error al ejecutar el ultimo comando y muestra un mensaje de lo ocurrido.
# Si ocurrio un error provoca la salida del script		
# Tambien sino se le indica borrar los archivos asociado a la exportacion fallida
# ENTRADA salida del comando , mensaje a mostrar 
# SALIDA ninguna 
comprobarEjecucion(){
	salida=$1  
	mensaje=$2
	if [ "$salida" != "0" ]; then
		if [ -f "$EJECUTABLE_SSH" ]; then
			 rm "$EJECUTABLE_SSH"
		fi
    	if [ "$mensaje" != "" ]; then
			 logger -is " $(basename "$0") ERROR: $mensaje"
		fi
		exit "$salida"
	fi	
} 

logger -is " $(basename "$0") INFO: Inicializando actualizacion de repositorio"

# Comprobamos que se ejecute el script como root para cambiar de usuario sin poner contraseña
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 1 "Se requieren permisos de administrador para continuar con el script"
fi

# Comprobamos que se este instalado el comando ssh
command -v ssh > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado ssh"

# Comprobamos que se este instalado el comando git
command -v git > /dev/null  2>&1
comprobarEjecucion $? "Debe estar instalado git"

vesionActualGIT="$(git --version | cut -d" " -f3)"
vesionRequeridaGIT="0.99.4"

# Comprobamos que se este instalado el comando git-store-meta.pl 
command -v git-store-meta.pl > /dev/null  2>&1
comprobarEjecucion $? "Debe estar instalado git-store-meta.pl"

if [ "$(printf '%s\n' "$vesionRequeridaGIT" "$vesionActualGIT" | sort -V | head -n1)" != "$vesionRequeridaGIT" ]; then 
	comprobarEjecucion 1 "La version de git deber mayor o igual a 0.99.4"
fi


mostrarAyuda(){
    echo "    El modo de usar el script es el siguiente"
    echo "        $0 [-h] [-?] [-i] [-k clave_ssh] [-p puerto_ssh]  [-m mensajeCommit]"
    echo ""
    echo "    	-h -? 	Mostar ayuda"
    echo "		-i 	Indica que se ejecutara el script en modo iteractivo si fuera necesario"
    echo "		-k 	clave_shh	Indica el fichero que contiene la clave pública que se usará"
    echo "		-p 	puerto_ssh	Indica el puerto ssh que se usará"  
    echo "		-m 	mensajeCommit Indica el mensaje que se incluirá en el commit "
    echo ""
    echo " Si no se introduce ninguna clave o puerto se hará uso de lo congurado en  $configuracion"
    exit 1
}

while getopts ':k:m:p: i?h' c
do
  case $c in
    i) MODO_ITERATIVO="TRUE" ;;
 	k) CLAVE_SSH="$OPTARG" ;;
	p) PUERTO_SSH="$OPTARG" ;;
	m) MENSAJE="$OPTARG"
    h|\?) mostrarAyuda;;
  esac
done

logger -is  "$(basename "$0") INFO: Accedemos a la carpeta $CARPETA_REPOSITORIO_LOCAL"
[ -d  "$CARPETA_REPOSITORIO_LOCAL" ] || comprobarEjecucion 1 "No existe  la carpeta $CARPETA_REPOSITORIO_LOCAL"

if [ "$PUERTO_SSH" = "" ]; then
	echo "ERROR: No se especifico puerto_remoto ni se encuentra la variable PUERTO_SSH en $configuracion"
	mostrarAyuda
fi

logger -is " $(basename "$0") INFO: Comprobamos si la clave $CLAVE_SSH tiene passphrase"

if [ "$MODO_ITERATIVO" = "TRUE" ]; then
	MODO_BATCH="no"
else 
	MODO_BATCH="yes"
fi

EJECUTABLE_SSH="$CARPETA_REPOSITORIO_LOCAL/ejecutableSshGit"
if [ "$CLAVE_SSH" != "" ]; then
	if [ ! -f "$CLAVE_SSH" ]; then
	comprobarEjecucion 1 "No existe la clave publica $CLAVE_SSH"
	fi

	CLAVE_TIENE_PASSPHRASE=$(ssh-keygen -y -P "" -f "$CLAVE_SSH" > /dev/null 2>&1 && echo "FALSE" || echo "TRUE")
	if [ "$CLAVE_TIENE_PASSPHRASE" = "TRUE" ] && [ "$MODO_ITERATIVO" = "FALSE" ]; then
		if ! ssh-add -l | grep "$CLAVE_SSH" > /dev/null 2>&1 ; then
			comprobarEjecucion 1 "No se puede ejecutar en modo no iterarivo a al tener passphrase la clave $CLAVE_SSH y esta no estar añadido al ssh-agent"
		fi
	fi
	{
		echo '#!/bin/sh'
		echo "ssh -i $CLAVE_SSH  -oPort=$PUERTO_SSH -obatchmode=$MODO_BATCH "' $*'	
	}  > "$EJECUTABLE_SSH"
else
	{
		echo '#!/bin/sh'
		echo "ssh -obatchmode=$MODO_BATCH  -oPort=$PUERTO_SSH "' $*'	
	}  > "$EJECUTABLE_SSH"
fi


chmod +x "$EJECUTABLE_SSH"


# Accedemos a la carpeta $CARPETA_REPOSITORIO_LOCAL
logger -is  "$(basename "$0") INFO: Accedemos a la carpeta $CARPETA_REPOSITORIO_LOCAL"
cd "$CARPETA_REPOSITORIO_LOCAL"  || comprobarEjecucion 1 "Accediendo a la carpeta $CARPETA_REPOSITORIO_LOCAL"

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


# Realizamos la subimos los cambios del repositorio $NOMBRE_REPOSITORIO
logger -is " $(basename "$0") INFO: Realizamos la actualizacion del repositorio $NOMBRE_REPOSITORIO"
GIT_SSH="$EJECUTABLE_SSH" git -C "$CARPETA_REPOSITORIO_LOCAL" push "$NOMBRE_REPOSITORIO" master
comprobarEjecucion $? "Al hacer git push del repositorio $NOMBRE_REPOSITORIO"

rm "$EJECUTABLE_SSH"

logger -is  "$(basename "$0") INFO: Finalizado commit de repositorio con fecha $FECHA"