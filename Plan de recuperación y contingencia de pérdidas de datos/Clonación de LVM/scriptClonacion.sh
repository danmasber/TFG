#!/bin/sh
set -e

echo "Comieza el proceso de clonacion"
echo "Realizando la copia de las particiones con datos"
fsarchiver -j2 -v savefs root_backup /dev/mapper/volumenDatos-root
fsarchiver -j2 -v savefs boot_backup /dev/sda2

echo "Copiando el MBR "
dd if=/dev/sda of=backup_sda_MBR.dd bs=512 count=1
dd if=/dev/sdb of=backup_sdb_MBR.dd bs=512 count=1

echo "Copiando tabla de particiones"
sfdisk -d /dev/sda > backup_sda.sfdisk
sfdisk -d /dev/sdb > backup_sdb.sfdisk

echo "Hacemos backkup configuracion de LVM"
vgcfgbackup -f volumenDatosConfig volumenDatos

echo " Guardamos uuid de /dev/sda1"
for i in $(blkid /dev/sda1); do
case "$i" in  
UUID*) 
echo "$i" |sed "s/UUID/UUID_SDA1/g" > uuid_sda1 ;; 
esac
done

echo " Guardamos uuid de /dev/sdb1"
for i in $(blkid /dev/sdb1); do
case "$i" in  
UUID*) 
echo "$i" |sed "s/UUID/UUID_SDB1/g" > uuid_sdb1 ;; 
esac
done

echo " Guardamos uuid y label de swap"
for i in $(blkid /dev/mapper/volumenDatos-swap); do
case "$i" in  
UUID*) 
echo "$i" |sed "s/UUID/UUID_SWAP/g" > uuid_swap ;; 
LABEL*)
echo "$i" | sed "s/LABEL/LABE_SWAP/g" > label_swap ;;	
esac
done

echo "Terminado el proceso de clonacion correctamente"
