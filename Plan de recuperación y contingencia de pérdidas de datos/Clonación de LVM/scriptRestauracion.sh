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

echo "Restaurando el volumen fisico /dev/sda1"
. uuid_sda1
pvcreate -u "$UUID_SDA1" --restorefile volumenDatosConfig /dev/sda1

echo "Restaurando el volumen fisico /dev/sda1"
. uuid_sdb1
pvcreate -u "$UUID_SDB1" --restorefile volumenDatosConfig /dev/sdb1

echo "Restaurando el grupo de volumenes volumenDatos"
vgcfgrestore -f volumenDatosConfig volumenDatos

echo "Activamos los volumenes logicos"
vgchange -a y

echo "Restaurando partición swap"
. uuid_swap
. label_swap
mkswap -U "$UUID_SWAP" -L "${LABEL_SWAP:-"swap"}" /dev/mapper/volumenDatos-swap

echo "Restaurando las particiones con datos"
fsarchiver -j2 -v restfs root_backup.fsa id=0,dest=/dev/mapper/volumenDatos-root
fsarchiver -j2 -v restfs boot_backup.fsa id=0,dest=/dev/sda2

echo "Reinstando el GRUB" 
mkdir datos
mount /dev/mapper/centos-root datos/
mount /dev/sda1 datos/boot/
mount --bind /dev/ datos/dev
mount --bind /proc/ datos/proc
chroot datos /bin/bash << "EOT"
/sbin/vgchange -y a
/sbin/grub2-install /dev/sda
/sbin/grub2-install /dev/sdb
EOT

echo "Terminado el proceso de clonacion correctamente"
