#!/bin/sh

#
# Este script clona un repositorio y lo ubica en una carpeta propietaria de un determinado usuario del sistema
# Para poder clonar es necesarioconfigurada la conexion ssh mediante clave publica para el usuario root para el usuario USUARIO_REPOSITORIO 
# en el servidor DIRECCION_REPOSITORIO y usuario USUARIO_REPOSITORIO_SERVIDOR
# Para finalizar creamos los fichero configuracionRepoCliente.cfg y repo_cliente.conf donde almacenamos informacion del repositorio clonado
# y configuracion para el script actualizarCliente.sh
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

# Comprobamos que se este instalado el comando ssh
command -v ssh > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado ssh"

echo "IP o Hostnames de servidor del repositorio a clonar: "
read -r DIRECCION_REPOSITORIO

if [ -z "$DIRECCION_REPOSITORIO" ]; then
     comprobarEjecucion 1 "Debe introducirse una IP o un Hostnames de servidor del para el repositorio"
fi

echo "Nombre Repositorio GIT: "
read -r NOMBRE_REPOSITORIO

if [ -z "$NOMBRE_REPOSITORIO" ]; then
     comprobarEjecucion 1 "Debe introducirse un nombre de repositorio"
fi

echo "Ubicacion de la carpeta local para el repositorio de GIT: "
read -r CARPETA_REPOSITORIO_LOCAL

if [ -z "$CARPETA_REPOSITORIO_LOCAL" ]; then
     comprobarEjecucion 1 "Debe introducirse un carpeta para el repositorio"
fi

echo "Introducir usuario propietario carpeta local del repositorio de GIT: " 
read -r USUARIO_REPOSITORIO_LOCAL

if [ -z "$USUARIO_REPOSITORIO_LOCAL" ]; then
     comprobarEjecucion 1 "Debe introducirse un usuario propietario carpeta local del repositorio"
fi

id "$USUARIO_REPOSITORIO_LOCAL"> /dev/null  2>&1

comprobarEjecucion $? "El usuario $USUARIO_REPOSITORIO_LOCAL no existe"

echo "Introducir usuario propietario repositorio de GIT: " 
read -r USUARIO_REPOSITORIO_SERVIDOR

if [ -z "$USUARIO_REPOSITORIO_SERVIDOR" ]; then
     comprobarEjecucion 1 "Debe introducirse el usuario propietario del repositorio"
fi

echo "Ubicacion de la carpeta en el servidor para el repositorio de GIT: "
read -r CARPETA_REPOSITORIO_SERVIDOR

if [ -z "$CARPETA_REPOSITORIO_SERVIDOR" ]; then
     comprobarEjecucion 1 "Debe introdir la ubicacion de la caperpeta del respositorio GIT en el servidor"
fi

echo "Introducir puerto para ssh"
read -r PUERTO_SSH

if [ -z "$PUERTO_SSH" ]; then
     comprobarEjecucion 1 "Debe introdir el puerto ssh para acceder al respositorio GIT en el servidor"
fi


CARPETA_ACTUAL=$(pwd)

# Creamos la carpeta $CARPETA_REPOSITORIO_LOCAL para ubicar el clonado del repositorio
[ -d "$CARPETA_REPOSITORIO_LOCAL" ] || mkdir -p "$CARPETA_REPOSITORIO_LOCAL"

comprobarEjecucion $? "No se pudo crear la carpeta $CARPETA_REPOSITORIO_LOCAL"

cd "$CARPETA_REPOSITORIO_LOCAL" || comprobarEjecucion 1 "No se pudo mover a la carpeta $CARPETA_REPOSITORIO_LOCAL"


SELECIONADA_UTILIZAR_CLAVE="FALSE"
while [ "$SELECIONADA_UTILIZAR_CLAVE" != "TRUE" ]; do
    echo "Desea usar clave publica para la configuracion del repositorio(S/N)?"
    read -r USAR_CLAVE
    case "$USAR_CLAVE" in
        S|s )
            UTILIZAR_CLAVE="TRUE"
            SELECIONADA_UTILIZAR_CLAVE="TRUE"
            ;;
        N|n )
            UTILIZAR_CLAVE="FALSE"
            SELECIONADA_UTILIZAR_CLAVE="TRUE"
            ;;
         *)
            ;;   
    esac
done

if [ "$UTILIZAR_CLAVE" = "TRUE" ]; then
    CLAVES_ENCONTRADAS="$(find "$HOME"/.ssh/*pub  -maxdepth 1 -name '*.pub' | rev | cut -d'/' -f1 | rev | sed 's/.pub//g')" 
    NUM_CLAVES_ENCONTRADAS="$(find "$HOME"/.ssh/*pub  -maxdepth 1 -name '*.pub' | wc -l)" 
    if [ "$NUM_CLAVES_ENCONTRADAS" != "1" ]; then
        SELECIONADA_CLAVE="FALSE"
        while [ "$SELECIONADA_CLAVE" != "TRUE" ]; do
            echo "Selecciona una de las siguiente publica claves para conectar con ${USUARIO_REPOSITORIO_SERVIDOR}@${DIRECCION_REPOSITORIO} : "
            for clave in $CLAVES_ENCONTRADAS; do
                echo "    $clave"
            done
            read -r CLAVE_SELECIONADA
            if find ~/.ssh/*pub  -maxdepth 1 -name '*.pub' | rev | cut -d'/' -f1 | rev | sed 's/.pub//g' | grep -q "^${CLAVE_SELECIONADA}$" ; then
                SELECIONADA_CLAVE="TRUE"
            else 
                echo "No se introdujo ninguna de la claves indicada"
            fi
            echo 
        done
        CLAVE_PUBLICA="$CLAVE_SELECIONADA"
    else
        CLAVE_PUBLICA="$CLAVES_ENCONTRADAS"
    fi
    CLAVE_PUBLICA_RUTA_ABSOLUTA="$HOME/.ssh/${CLAVE_PUBLICA}"

    EJECUTABLE_SSH_CLAVE="${CARPETA_ACTUAL}/comandoSsh"
    {
        echo '#!/bin/sh'
        echo "ssh -i $CLAVE_PUBLICA_RUTA_ABSOLUTA  -obatchmode=no -oPort=$PUERTO_SSH -oPasswordAuthentication=no "' $*' 
    }  > "$EJECUTABLE_SSH_CLAVE"

    chmod +x "$EJECUTABLE_SSH_CLAVE"

    # Clonamos el repositorio remoto
    echo "INFO: Clonamos el repositorio $NOMBRE_REPOSITORIO de $DIRECCION_REPOSITORIO $CARPETA_REPOSITORIO_SERVIDOR "
    GIT_SSH="$EJECUTABLE_SSH_CLAVE" git clone "$USUARIO_REPOSITORIO_SERVIDOR"@"$DIRECCION_REPOSITORIO":"$CARPETA_REPOSITORIO_SERVIDOR" -o "$NOMBRE_REPOSITORIO" .
    resultadoClone=$?

    rm "$EJECUTABLE_SSH_CLAVE"
    comprobarEjecucion $resultadoClone "Clonando el repositro $NOMBRE_REPOSITORIO en $DIRECCION_REPOSITORIO de GIT, ten en cuenta que es necesario tener configura conexion mediante ssh por clave publica sin passphrase"
    
    # Configuramos para que el git pueda guardar y aplicar lo metadatos
    echo "INFO: Configuramos para que git pueda guardar y aplicar los metadatos de los ficheros"
    git-store-meta.pl -i -f mtime,atime,mode,user,group,uid,gid,acl
    comprobarEjecucion $? "Configuramos para que el git pueda guardar y aplicar lo metadatos"
else
    echo "WARN: Tener en cuenta que no se podrar usar el script de actualizarCliente o realizarCommitRepositorioCliente sin usar clave publica en la conexion ssh"
    echo "WARN: Se recomienda el uso del script configurarSshConexionConClavePublica.sh"
    
    EJECUTABLE_SSH_CLAVE="${CARPETA_ACTUAL}/comandoSsh"
    {
        echo '#!/bin/sh'
        echo "ssh -i $CLAVE_PUBLICA_RUTA_ABSOLUTA  -obatchmode=no -oPort=$PUERTO_SSH -oPasswordAuthentication=no "' $*' 
    }  > "$EJECUTABLE_SSH_CLAVE"

    chmod +x "$EJECUTABLE_SSH_CLAVE"


    # Clonamos el repositorio remoto
    echo "INFO: Clonamos el repositorio $NOMBRE_REPOSITORIO de $DIRECCION_REPOSITORIO $CARPETA_REPOSITORIO_SERVIDOR "
    GIT_SSH="$EJECUTABLE_SSH_CLAVE" git clone "$USUARIO_REPOSITORIO_SERVIDOR"@"$DIRECCION_REPOSITORIO":"$CARPETA_REPOSITORIO_SERVIDOR" -o "$NOMBRE_REPOSITORIO" .
    resultadoClone=$?
    rm "$EJECUTABLE_SSH_CLAVE"
    comprobarEjecucion $resultadoClone "Clonando el repositro $NOMBRE_REPOSITORIO en $DIRECCION_REPOSITORIO de GIT, ten en cuenta que es necesario tener configura conexion mediante ssh por clave publica sin passphrase"


    # Configuramos para que el git pueda guardar y aplicar lo metadatos
    echo "INFO: Configuramos para que git pueda guardar y aplicar los metadatos de los ficheros"
    git-store-meta.pl -i -f mtime,atime,mode,user,group,uid,gid,acl
    comprobarEjecucion $? "Configuramos para que el git pueda guardar y aplicar lo metadatos"
fi
cd - > /dev/null  2>&1 || comprobarEjecucion $? "Volviendo a la carpeta de ejecucion del script"

# Guardamos la informacion de configuracion y cremos el archivo de configuracionn para actualizarCliente.sh
echo "INFO: Escribiendo archivo con la configuracion repo_cliente.conf y en configuracionRepoCliente.cfg en $CARPETA_REPOSITORIO_LOCAL"

{
    echo "Usuario propietario: $USUARIO_REPOSITORIO_LOCAL"
    echo "Carpeta repositorio: $CARPETA_REPOSITORIO_LOCAL"      
    echo "Nombre repositorio: $NOMBRE_REPOSITORIO" 
    echo "Usuario remoto propietario: $USUARIO_REPOSITORIO_SERVIDOR"
    echo "Carpeta remota repositorio: $CARPETA_REPOSITORIO_SERVIDOR"
    echo "Ubicacion remota: $DIRECCION_REPOSITORIO"
    echo "Puerto ssh usado para acceder mediante ssh con git : $PUERTO_SSH"
    if [ "$UTILIZAR_CLAVE" = "TRUE" ]; then
        echo "Clave publica usada para acceder mediante ssh con git : $CLAVE_PUBLICA_RUTA_ABSOLUTA"
    fi  

} >  "$(dirname "$0")/repo_cliente.conf"    

{   
    if [ "$UTILIZAR_CLAVE" != "TRUE" ]; then
        echo "# Si se desea usar una clave primaria distinta de ~/.ssh/id_rsa hay que declarar la variable  CLAVE_SSH "
        echo "#  CLAVE_SSH=\"~/.ssh/id_rsa\""
    fi
    echo "USUARIO_REPOSITORIO_LOCAL=\"$USUARIO_REPOSITORIO_LOCAL\""
    echo "CARPETA_REPOSITORIO_LOCAL=\"$CARPETA_REPOSITORIO_LOCAL\""     
    echo "NOMBRE_REPOSITORIO=\"$NOMBRE_REPOSITORIO\""
    echo "DIRECCION_REPOSITORIO=\"$DIRECCION_REPOSITORIO\""
    echo "PUERTO_SSH=\"$CLAVE_PUBLICA_RUTA_ABSOLUTA\""
    if [ "$UTILIZAR_CLAVE" = "TRUE" ]; then
        echo "CLAVE_SSH=\"$CLAVE_PUBLICA_RUTA_ABSOLUTA\""
    fi
}  > "$(dirname "$0")/configuracionRepoCliente.cfg"

# Cambiado el propiertario a USUARIO_REPOSITORIO
echo "INFO: Cambiado el propiertario a $USUARIO_REPOSITORIO"
chown -R "$USUARIO_REPOSITORIO_LOCAL"  "$CARPETA_REPOSITORIO_LOCAL"
comprobarEjecucion $? "Cambiado el propiertario a $CARPETA_REPOSITORIO_LOCAL"

echo "Finalizado configuracion de repositorio"

