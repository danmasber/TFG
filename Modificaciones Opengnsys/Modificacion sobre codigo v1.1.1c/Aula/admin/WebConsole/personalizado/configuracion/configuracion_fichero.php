<?php
$directorio_relativo_ficheros = "ficheros/";
$directorio_completo_en_ogLive = "/opt/opengnsys/images/groups/";
$directorio_absoluto_ficheros = "/opt/opengnsys/www/personalizado/ficheros/";
$fichero_script_copia = "copiaRemotaScript";
$fichero_ultima_seleccion = "copiaRemotaListado";
$comandoParaCopia = "#Ejecutar Copia\ncp $directorio_completo_en_ogLive$fichero_script_copia /tmp/\nchmod 700 /tmp/$fichero_script_copia\n/tmp/$fichero_script_copia";
/*
Se recomienda un enlace simbolico para mayor seguridad

sudo ln -fs /opt/opengnsys/images/groups/ ./ficheros/
chown www-data ficheros 
o permitir a poder subir y modificar la carpeta al usuario de apache
Y crear dentro del directorio ./ficheros/ un fichero .htaccess con el contenido:
	Options -Indexes
De esta menera no seran acesible los fichero desde el exterior
*/
?>


