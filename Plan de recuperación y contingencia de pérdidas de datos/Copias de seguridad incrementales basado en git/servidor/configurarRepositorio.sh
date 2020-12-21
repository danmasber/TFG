#!/bin/sh

#
# Este script crea y configura un repositorio y lo ubica en una carpeta propietaria de un determinado usuario del sistema, 
# ádemas nombremos el repositorio para poder hacer mas facilmente desde el cliente
# Para finalizar creamos los fichero configuracionRepo.cfg y repo.conf donde almacenamos informacion del repositorio clonado
# y configuracion para el script realizarCommitRepositorio.sh
#

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
			 echo "ERROR: $mensaje"
		fi
		exit "$salida"
	fi	
} 

#Comprobamos que se ejecute el script como root para poder acceder a virsh
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 1 "Se requieren permisos de administrador para continuar con el script"
fi

# Comprobamos que se este instalado el comando git
command -v git > /dev/null  2>&1
comprobarEjecucion $? "Debe estar instalado git"

# Comprobamos que se este instalado el comando git-store-meta.pl 
command -v git-store-meta.pl > /dev/null  2>&1
comprobarEjecucion $? "Debe estar instalado git-store-meta.pl"


echo "Nombre Repositorio GIT: "
read -r NOMBRE_REPOSITORIO

if [ -z "$NOMBRE_REPOSITORIO" ]; then
     comprobarEjecucion 1 "Debe introducirse un nombre de repositorio"
fi

echo "Ubicacion de la carpeta para el repositorio de GIT: "
read -r CARPETA_REPOSITORIO

if [ -z "$CARPETA_REPOSITORIO" ]; then
     comprobarEjecucion 1 "Debe introducirse un carpeta para el repositorio"
fi

echo "Introducir usuario propietario carpeta el repositorio de GIT: " 
read -r USUARIO_REPOSITORIO

if [ -z "$USUARIO_REPOSITORIO" ]; then
     comprobarEjecucion 1 "Debe introducirse un usuario propietario para el repositorio"
fi

# Comprobamos si existe el usuario $USUARIO_REPOSITORIO
echo "Comprobamos si existe el usuario $USUARIO_REPOSITORIO"
id "$USUARIO_REPOSITORIO"> /dev/null  2>&1
comprobarEjecucion $? "El usuario $USUARIO_REPOSITORIO no existe"

# Creamos la carpeta $CARPETA_REPOSITORIO para ubicar el repositorio
echo "Creamos la carpeta $CARPETA_REPOSITORIO para ubicar el repositorio"
[ -d "$CARPETA_REPOSITORIO" ] || mkdir -p "$CARPETA_REPOSITORIO"
comprobarEjecucion $? "Creando la carpeta $CARPETA_REPOSITORIO"

CARPETA_REPOSITORIO="${CARPETA_REPOSITORIO}/"

# Accedemos a la carpeta $CARPETA_REPOSITORIO
echo "Accedemos a la carpeta $CARPETA_REPOSITORIO"
cd "$CARPETA_REPOSITORIO" || comprobarEjecucion 1 "Accediendo a la carpeta $CARPETA_REPOSITORIO"

# Inicializamos el repositorio
echo "Inicializamos el repositorio"
git init 
comprobarEjecucion $? "Error al inicializando el repositorio de GIT"

# Configuramos para que el git pueda guardar y aplicar lo metadatos
echo "INFO: Configuramos para que git pueda guardar y aplicar los metadatos de los ficheros"
git-store-meta.pl -i -f mtime,atime,mode,user,group,uid,gid,acl
comprobarEjecucion $? "Configuramos para que el git pueda guardar y aplicar lo metadatos"
git-store-meta.pl -s -f mtime,atime,mode,user,group,uid,gid,acl
comprobarEjecucion $? "Configuramos para que el git pueda guardar y aplicar lo metadatos"

# Realizamos el primer commit
echo "Realizamos el primer commit"
git commit --allow-empty -m "Primer commit del repositorio de GIT en $CARPETA_REPOSITORIO"
comprobarEjecucion $? "Haciendo el primer commit"

# Nombramos el reposito con $NOMBRE_REPOSITORIO para acceder mas facilmente desde el cliente
echo "Nombramos el reposito con $NOMBRE_REPOSITORIO"
git remote add "$NOMBRE_REPOSITORIO" localhost:"$CARPETA_REPOSITORIO"
comprobarEjecucion $? "Agregando el nuevo repositorio $NOMBRE_REPOSITORIO para poder acceder desde el cliente"

cd - > /dev/null  2>&1 || comprobarEjecucion $? "Volviendo a la carpeta de ejecucion del script"

# Guardamos la informacion de configuracion y cremos el archivo de configuracionn para realizarCommitRepositorio.sh
echo  "Escribiendo archivo con la configuracion repo.conf y configuracionRepo.cfg en $CARPETA_REPOSITORIO"
{
	echo "Usuario propietario: $USUARIO_REPOSITORIO"
	echo "Carpeta repositorio: $CARPETA_REPOSITORIO"		
	echo "Nombre repositorio: $NOMBRE_REPOSITORIO"
} > "$(dirname "$0")/repo.conf"

{
	echo "USUARIO_REPOSITORIO=\"$USUARIO_REPOSITORIO\"" 
	echo "CARPETA_REPOSITORIO=\"$CARPETA_REPOSITORIO\"" 		
	echo "NOMBRE_REPOSITORIO=\"$NOMBRE_REPOSITORIO\""	
} > "$(dirname "$0")/configuracionRepo.cfg"


# Cambiado el propiertario a USUARIO_REPOSITORIO
echo "Cambiado el propiertario a $USUARIO_REPOSITORIO"
chown -R "$USUARIO_REPOSITORIO"  "$CARPETA_REPOSITORIO"
comprobarEjecucion $? "Cambiado el propiertario a $USUARIO_REPOSITORIO"


echo "Finalizado configuracion de repositorio"

