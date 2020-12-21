#!/bin/sh
set -e

echo "Comieza el proceso de restauracion"
echo "Restaurando el MBR y tabla de particiones"
echo "Restaurando MBR "
dd if=backup_sda_MBR.dd of=/dev/sda bs=512 count=1 
dd if=backup_sdb_MBR.dd of=/dev/sdb bs=512 count=1

echo "Restaurando tabla de particiones extendida"
sfdisk /dev/sda < backup_sda.sfdisk
sfdisk /dev/sdb < backup_sdb.sfdisk

. sector_size_sda
. sector_size_sdb

echo "Restaurando superblock del raid md0"
. offset_superblock_md0
dd of=/dev/sda1 if=sda1_superblock.dd count=1 bs="$SECTOR_SIZE_SDA" seek="$OFFSET_MD0"
dd of=/dev/sdb1 if=sdb1_superblock.dd count=1 bs="$SECTOR_SIZE_SDB" seek="$OFFSET_MD0"

echo "Restaurando superblock del raid md1"
. offset_superblock_md1
dd of=/dev/sda5 if=sda5_superblock.dd count=1 bs="$SECTOR_SIZE_SDA" seek="$OFFSET_MD1"
dd of=/dev/sdb5 if=sdb5_superblock.dd count=1 bs="$SECTOR_SIZE_SDB" seek="$OFFSET_MD1" 

echo "Parando raid si iniciaron automaticamente"
mdadm -S --scan

echo "Restaurando partición swap"
mdadm -A --run --update=resync /dev/md1 /dev/sda5 /dev/sdb5
. uuid_md1
. label_md1
mkswap -U "$UUID_MD1" -L "${LABEL_MD1:-"raid1Swap"}" /dev/md1

echo "Restaurando datos RAID 1 con datos"
mdadm -A --run --update=resync /dev/md0 /dev/sda1 /dev/sdb1
fsarchiver -j2 -v restfs md0.fsa id=0,dest=/dev/md0

echo "Reinstando el GRUB" 
mkdir md0_carpeta
mount /dev/md0 md0_carpeta
grub-install --boot-directory=md0_carpeta/boot/ /dev/sda
grub-install --boot-directory=md0_carpeta/boot/ /dev/sdb	

echo "Terminado el proceso de restauracion correctamente"