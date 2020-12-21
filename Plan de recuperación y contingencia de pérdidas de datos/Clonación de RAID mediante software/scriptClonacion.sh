#!/bin/sh
set -e

echo "Comieza el proceso de clonacion"
echo "Paramos los RAIDs y los recreamos correctamente"
mdadm -S --scan
mdadm -A --run --update=resync /dev/md0 /dev/sda1 /dev/sdb1
mdadm -A --run --update=resync /dev/md1 /dev/sda5 /dev/sdb5

echo "Realizando la copia del RAID 1 con datos"
fsarchiver -j2 -v savefs md0 /dev/md0

echo "Copiando el MBR"
dd if=/dev/sda of=backup_sda_MBR.dd bs=512 count=1
dd if=/dev/sdb of=backup_sdb_MBR.dd bs=512 count=1

echo "Copiando tabla de particiones"
sfdisk -d /dev/sda > backup_sda.sfdisk
sfdisk -d /dev/sdb > backup_sdb.sfdisk

echo "Copiando supeblock RAIDs"

echo "Buscando ubicacion de superblock"
j=0
for i in $(mdadm -E /dev/sda1 | grep "Super Offset"); do 
 j=$((j+1)) 
 if [ "$j" = "4" ]; then 
  echo "OFFSET_MD0=$i" > offset_superblock_md0 
 fi
done

j=0
for i in $(mdadm -E /dev/sda5 | grep "Super Offset"); do 
 j=$((j+1))
 if [ "$j" = "4" ]; then 
  echo "OFFSET_MD1=$i" > offset_superblock_md1
 fi
done

echo "Buscando tamanio de los	 sectores"
echo "SECTOR_SIZE_SDA=$(cat /sys/block/sda/queue/hw_sector_size)" > sector_size_sda
echo "SECTOR_SIZE_SDB=$(cat /sys/block/sda/queue/hw_sector_size)" > sector_size_sdb



. sector_size_sda
. sector_size_sdb

echo "Clonando superblock del raid md0"
. offset_superblock_md0
dd if=/dev/sda1 of=sda1_superblock.dd count=1 bs="$SECTOR_SIZE_SDA" skip="$OFFSET_MD0"
dd if=/dev/sdb1 of=sdb1_superblock.dd count=1 bs="$SECTOR_SIZE_SDB" skip="$OFFSET_MD0"

echo "Clonando superblock del raid md1"
. offset_superblock_md1
dd if=/dev/sda5 of=sda5_superblock.dd count=1 bs="$SECTOR_SIZE_SDA" skip="$OFFSET_MD1"
dd if=/dev/sdb5 of=sdb5_superblock.dd count=1 bs="$SECTOR_SIZE_SDB" skip="$OFFSET_MD1"

echo "Guardando uuid y label de swap"
for i in $(blkid /dev/md1); do
 case "$i" in  
 UUID*) 
  echo "$i" |sed "s/UUID/UUID_MD1/g" > uuid_md1 ;; 
 LABEL*)
  echo "$i" | sed "s/LABEL/LABEL_MD1/g" > label_md1 ;;
 esac
done
echo "Terminado el proceso de clonacion correctamente"