#!/bin/sh

directorio=$(dirname "$0")

$directorio/ltA/destruirBridge.sh
resultado=$?
if [ "$resultado" != "0" ]; then
	exit $resultado
fi

$directorio/ltB/destruirBridge.sh
resultado=$?
if [ "$resultado" != "0" ]; then
	exit $resultado
fi
