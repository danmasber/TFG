#!/bin/sh 

is_ip() {
    ip=$1
    
    if expr "$ip" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
        for i in 1 2 3 4; do
            if [ "$(echo "$ip" | cut -d. -f$i)" -gt 255 ]; then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

DEFAULT_OPENGNSYS_IP_SERVER=$(ip route list|grep default| cut -d' ' -f3|awk '{$1=$1;print}')

if [ "$(whoami)" != 'root' ]; then
   echo "ERROR:Se requieren pesmisos de administrador para continuar con el script"
exit 1
fi

while : ; do
    echo "Introduce la IP del servidor de opengnsys (${DEFAULT_OPENGNSYS_IP_SERVER}): "
    read -r OPENGNSYS_IP_SERVER
    OPENGNSYS_IP_SERVER=$(echo "$OPENGNSYS_IP_SERVER"|awk '{$1=$1;print}')
    is_ip "$OPENGNSYS_IP_SERVER"
  resultado="$?"
  if [ "$resultado" != "0" ] && [ -n "$OPENGNSYS_IP_SERVER" ]; then # Comprobamos que sea un valor IPv4
     echo "ERROR: Debe tener formato de IPv4 XXX.XXX.XXX.XXX, prueba de nuevo..."
  else
  # Si esta vacio ponemos el valor por defecto
  OPENGNSYS_IP_SERVER="${OPENGNSYS_IP_SERVER:-$DEFAULT_OPENGNSYS_IP_SERVER}"
    break
    fi
done

echo "=====  Instalando cliente OGAgent  ====="
yum -y install ogagent-[1-9]*.noarch.rpm

resultado="$?"
if [ "$resultado" != "0" ]; then
    echo "ERROR:No se puedo instalar correctamente el cliente OGAgent"
    exit 1
fi

echo "=====  Configurando cliente OGAgent  ====="

sed -i "0,/remote=/ s,remote=.*,remote=https://$OPENGNSYS_IP_SERVER/opengnsys/rest/," /usr/share/OGAgent/cfg/ogagent.cfg

resultado="$?"
if [ "$resultado" != "0" ]; then
   echo "ERROR:No se puedo configurar correctamente el cliente OGAgent"
   exit 1
fi

echo "=====  Ajustando permiso servicio del cliente OGAgent  ====="

chmod +x /etc/init.d/ogagent

resultado="$?"
if [ "$resultado" != "0" ]; then
   echo "ERROR:No se puedo ajustar correctamente el servicio del cliente OGAgent"
   exit 1
fi

echo "=====  Iniciando servicio cliente OGAgent  ====="

service ogagent start

resultado="$?"
if [ "$resultado" != "0" ]; then
   echo "ERROR:No se puedo iniciar correctamente el cliente OGAgent"
   exit 1
fi
