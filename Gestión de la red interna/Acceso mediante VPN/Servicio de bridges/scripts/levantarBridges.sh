#!/bin/sh

directorio=$(dirname "$0")
$directorio/ltA/levantarBridge.sh
resultado=$?
if [ "$resultado" != "0" ]; then
	exit $resultado
fi

$directorio/lBA/levantarBridge.sh
resultado=$?
if [ "$resultado" != "0" ]; then
	exit $resultado
fi
