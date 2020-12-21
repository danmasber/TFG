#!/bin/sh
#
# Este script realiza la configuracion para poder realizar la actualizacion del repositorio configurado en configuracionRepoCliente.cfg(NOMBRE_REPOSITORIO) 
# ubicado en la carpeta configuradado en configuracionRepoCliente.cfg(CARPETA_REPOSITORIO_LOCAL) propietadad el usuario 
# configuradado en configuracionRepoCliente.cfg(USUARIO_REPOSITORIO_LOCAL) mediante conexion ssh usando unicamente la clave publica

configuracion=$(dirname "$0")"/"configuracionRepoCliente.cfg
if [ -f "$configuracion" ]; then
	. "$configuracion"
fi

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

echo "Iniciando configuracion conexion ssh mediante clave publica para actualizacion de repositorio"

# Comprobamos que se ejecute el script como root para cambiar de usuario sin poner contraseña
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 1 "Se requieren permisos de administrador para continuar con el script"
fi

# Comprobamos que se este instalado el comando ssh
command -v ssh > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado ssh"

# Comprobamos que se este instalado el comando ssh-keygen
command -v ssh-keygen > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado ssh-keygen"

# Comprobamos que se este instalado el comando ssh-copy-id
command -v ssh-copy-id > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado ssh-copy-id"

# Mustra la ayuda para el uso del script
mostrarAyuda(){
    echo "    El modo de usar el script es el siguiente"
    echo "        $0 [-e] [-h] [-?] [-k key_propia] [-H host_remoto] [-u usuario_remoto] [-p puerto_remoto]"
    echo "    "
    echo "	-h -?			Mostar ayuda"
    echo "	-k key_propia		Indica la key que se usará para acceder a host_remoto con usuario_remoto"
    echo "	-H host_remoto		Indica el host para el que se desea configurar el acceso median clave publica"
	echo "	-u usuario_remoto	Indica el usuario del host remoto"
	echo "	-p puerto_remoto	Indica el puerto ssh del host remoto"
	echo "	-e					Indica que se modique el fichero $configuracion"
    echo ""
    echo "	Si no se especifica ni host_remoto ni usuario_remoto ni puerto_remoto se usará los que se encuentre en el fichero $configuracion"
    echo "	Si no se expecifica key_propia se buscara en ~/.ssh/ o se creará una con el nombre claveSsh sin passphrase"
    echo ""
    exit 1
}

EDITAR="FALSE"

while getopts ':k:H:u:p: e?h' c
do
  case $c in
    k) CLAVE_PUBLICA_RUTA_ABSOLUTA="$OPTARG" ;;
    H) DIRECCION_REPOSITORIO="$OPTARG" ;;
    u) USUARIO_REPOSITORIO_SERVIDOR="$OPTARG" ;;
    p) PUERTO_SSH="$OPTARG" ;;
	e) EDITAR="TRUE"
    h|?) mostrarAyuda ;;
  esac
done

if [ "$DIRECCION_REPOSITORIO" = "" ]; then
	echo "ERROR: No se especifico host_remoto ni se encuentra la variable DIRECCION_REPOSITORIO en $configuracion"
	mostrarAyuda
fi

if [ "$USUARIO_REPOSITORIO_SERVIDOR" = "" ]; then
	echo "ERROR: No se especifico usuario_remoto ni se encuentra la variable USUARIO_REPOSITORIO_SERVIDOR en $configuracion"
	mostrarAyuda
fi

if [ "$PUERTO_SSH" = "" ]; then
	echo "ERROR: No se especifico puerto_remoto ni se encuentra la variable PUERTO_SSH en $configuracion"
	mostrarAyuda
fi

echo "Comprobamos si ya esta configuradada la clave publica"

if [ "$CLAVE_PUBLICA_RUTA_ABSOLUTA" != "" ]; then
	ssh -i "$CLAVE_PUBLICA_RUTA_ABSOLUTA" -oPort=$PUERTO_SSH -oPasswordAuthentication=no "$USUARIO_REPOSITORIO_SERVIDOR"@"$DIRECCION_REPOSITORIO" -C exit > /dev/null  2>&1
	resultado=$?
else 
	ssh  -oStrictHostKeyChecking=no -oPort=$PUERTO_SSH -oPasswordAuthentication=no "$USUARIO_REPOSITORIO_SERVIDOR"@"$DIRECCION_REPOSITORIO" -C exit > /dev/null  2>&1
	resultado=$?
fi

if [ "$resultado" = "255" ]; then
	if [ "$CLAVE_PUBLICA_RUTA_ABSOLUTA" != "" ]; then
		CLAVE_TIENE_PASSPHRASE=$(ssh-keygen -y -P "" -f "$CLAVE_PUBLICA_RUTA_ABSOLUTA" > /dev/null 2>&1 && echo "FALSE" || echo "TRUE")
		if [ "$CLAVE_TIENE_PASSPHRASE" = "TRUE" ]; then
			comprobarEjecucion 1 "La clave $CLAVE_PUBLICA_RUTA_ABSOLUTA no es valida para automatizar la actualizacion \
			por tener passphrase puede introducirla manualmente en ${configuracion} en \
			la variable CLAVE_SSH y hacer ssh-copy-id a ${USUARIO_REPOSITORIO_SERVIDOR}@${DIRECCION_REPOSITORIO} con ella"
		fi

		echo "Ahora se te pedirá introducir la contraseña para  ${USUARIO_REPOSITORIO_SERVIDOR}@${DIRECCION_REPOSITORIO}"
		ssh-copy-id  -oPort=$PUERTO_SSH -i "$HOME/.ssh/${CLAVE_PUBLICA}" "$USUARIO_REPOSITORIO_SERVIDOR"@"$DIRECCION_REPOSITORIO"
	else 
		echo "$HOME/.ssh/"
		mkdir "$HOME/.ssh/" > /dev/null  2>&1
		chmod 600 "$HOME/.ssh/" > /dev/null  2>&1
		ls "$HOME"/.ssh/*pub  > /dev/null  2>&1
		resultado=$?
		if [ "$resultado" = "2" ]; then
			echo "Generado clave $HOME/.ssh/claveSsh y sin passphrase"
		 	ssh-keygen -q -b 2048 -t rsa -N "" -f "$HOME/.ssh/claveSsh" > /dev/null  2>&1
		 	comprobarEjecucion $? "Error generando clave $HOME/.ssh/claveSsh"
		elif [ "$resultado" != "0" ]; then
			comprobarEjecucion "$resultado" "Comprobando si existian claves en $HOME/.ssh/*.pub"
		fi

		CLAVES_ENCONTRADAS="$(find "$HOME"/.ssh/*pub  -maxdepth 1 -name '*.pub' | rev | cut -d'/' -f1 | rev | sed 's/.pub//g')" 
		NUM_CLAVES_ENCONTRADAS="$(find "$HOME"/.ssh/*pub  -maxdepth 1 -name '*.pub' | wc -l)" 
		if [ "$NUM_CLAVES_ENCONTRADAS" != "1" ]; then
			SELECIONADA_CLAVE="FALSE"
			while [ "$SELECIONADA_CLAVE" != "TRUE" ]; do
				echo "Selecciona una de las siguiente claves: "
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

		CLAVE_TIENE_PASSPHRASE=$(ssh-keygen -y -P "" -f "$HOME/.ssh/$CLAVE_PUBLICA" > /dev/null 2>&1 && echo "FALSE" || echo "TRUE")
		
		if [ "$CLAVE_TIENE_PASSPHRASE" = "TRUE" ]; then
			comprobarEjecucion 1 "La clave $CLAVE_PUBLICA no es valida para automatizar la actualizacion por tener passphrase puede introducirla manualmente en $configuracion en la variable CLAVE_SSH y hacer ssh-copy-id a ${USUARIO_REPOSITORIO_SERVIDOR}@${DIRECCION_REPOSITORIO} con ella tambien será necesario añadido al ssh-agent para la auto autentificacion"
		fi

		echo "Iniciamos la configuración  con la clave ${CLAVE_PUBLICA}"
		echo ""
		echo "Ahora se te pedirá introducir la contraseña para ${USUARIO_REPOSITORIO_SERVIDOR}@${DIRECCION_REPOSITORIO}"
		echo ""
		ssh-copy-id -oPort=$PUERTO_SSH -i "$HOME/.ssh/${CLAVE_PUBLICA}" "$USUARIO_REPOSITORIO_SERVIDOR"@"$DIRECCION_REPOSITORIO"
		CLAVE_PUBLICA_RUTA_ABSOLUTA="$HOME/.ssh/${CLAVE_PUBLICA}"
	fi
	
	echo "Comprobamos que hemos copiado la clave publica correctamente $DIRECCION_REPOSITORIO para el usuario $USUARIO_REPOSITORIO_SERVIDOR"
	ssh -oPasswordAuthentication=no -i "$CLAVE_PUBLICA_RUTA_ABSOLUTA"  "$USUARIO_REPOSITORIO_SERVIDOR"@"$DIRECCION_REPOSITORIO" -C exit
	comprobarEjecucion $? "Accediendo mediante ssh $DIRECCION_REPOSITORIO con el usuario $USUARIO_REPOSITORIO_SERVIDOR tras copiar la clave publica"

	if [ "$EDITAR" = "TRUE" ]; then
		if [ -f "$configuracion" ]; then
			echo "Escribimos la clave publica y puerto en  $configuracion"
			# Eliminamos de configuracionRepoCliente.cfg otra varible CLAVE_SSH o informacion de clave usada si existirá ya
			sed -e '/^CLAVE_SSH/d' "$configuracion" > "${configuracion}TMP"
			sed -e '/^PUERTO_SSH/d' "$configuracion" > "${configuracion}TMP"
			mv "${configuracion}TMP" "$configuracion"
			echo "CLAVE_SSH=\"$CLAVE_PUBLICA_RUTA_ABSOLUTA\""  >> "$configuracion"
			echo "PUERTO_SSH=\"$PUERTO_SSH\""  >> "$configuracion"
		fi	
		if [ -f "$(dirname "$0")/repo_cliente.conf" ]; then
			echo "Escribimos la clave publica y puerto en  $(dirname "$0")/repo_cliente.conf"		
			sed -e '/^Clave publica usada/d' "$(dirname "$0")/repo_cliente.conf" > "$(dirname "$0")/repo_cliente.confTMP"
			mv "$(dirname "$0")/repo_cliente.confTMP" "$(dirname "$0")/repo_cliente.conf"
			echo "Clave publica usada para acceder mediante ssh con git : $CLAVE_PUBLICA_RUTA_ABSOLUTA"  >> "$(dirname "$0")/repo_cliente.conf"   
			echo "Puerto shh usado para acceder mediante ssh con git : $PUERTO_SSH"  >> "$(dirname "$0")/repo_cliente.conf"   
		fi
	fi
elif [ "$resultado" != "0" ]; then
	comprobarEjecucion "$resultado" "Accediendo mediante ssh $DIRECCION_REPOSITORIO con el usuario %USUARIO_REPOSITORIO_SERVIDOR"
else 
	echo "Ya estaba configurado conexion ssh mediante clave publica"
	CLAVE_PUBLICA_RUTA_ABSOLUTA="${CLAVE_PUBLICA_RUTA_ABSOLUTA:=~/.ssh/id_rsa}"
	if [ "$EDITAR" = "TRUE" ]; then
		if [ -f "$configuracion" ]; then
			echo "Escribimos la clave publica y puerto en  $configuracion"
			# Eliminamos de configuracionRepoCliente.cfg otra varible CLAVE_SSH o informacion de clave usada si existirá ya
			sed -e '/^CLAVE_SSH/d' "$configuracion" > "${configuracion}TMP"
			sed -e '/^PUERTO_SSH/d' "$configuracion" > "${configuracion}TMP"
			mv "${configuracion}TMP" "$configuracion"
			echo "CLAVE_SSH=\"$CLAVE_PUBLICA_RUTA_ABSOLUTA\""  >> "$configuracion"
			echo "PUERTO_SSH=\"$PUERTO_SSH\""  >> "$configuracion"
		fi	
		if [ -f "$(dirname "$0")/repo_cliente.conf" ]; then		
			echo "Escribimos la clave publica y puerto en  $(dirname "$0")/repo_cliente.conf"
			sed -e '/^Clave publica usada/d' "$(dirname "$0")/repo_cliente.conf" > "$(dirname "$0")/repo_cliente.confTMP"
			mv "$(dirname "$0")/repo_cliente.confTMP" "$(dirname "$0")/repo_cliente.conf"
			echo "Clave publica usada para acceder mediante ssh con git : $CLAVE_PUBLICA_RUTA_ABSOLUTA"  >> "$(dirname "$0")/repo_cliente.conf"   
			echo "Puerto shh usado para acceder mediante ssh con git : $PUERTO_SSH"  >> "$(dirname "$0")/repo_cliente.conf"   
		fi
	fi
fi

echo "Finalizado configuracion conexion ssh mediante clave publica para actualizacion de repositorio"
