<?php


$conexion_guacmole = array(
    "url" => "localhost:3306",
    "username" => "guacamole",
    "password" => "some_password",	
    "database" => "guacamole_db",
    "supplier" => "mysql",
 );

$cadenaconexion_guacamole=implode(";", $conexion_guacmole);

$nombreAdministrador = "guacadmin";
$subfijo_vnc = "_VNC";
$subfijo_ssh = "_SSH";
$subfijo_rdp = "_RDP";

##################  CONFIGURACION   VNC  ############# 
$vnc_pass = "VNCPASS";
$vnc_port = "5900";

##################  CONFIGURACION   SSH  ############# 
$ssh_config = "pass"; // pass privateKey privateKey&passphrase
$ssh_user = "username";
$ssh_pass = "password";
$ssh_port = "22";
$ssh_private = "private-key";
$ssh_passphrase = "passphrase";
##################  CONFIGURACION   RDP  ############# 
$rdp_user = "username";
$rdp_pass = "password";
$rdp_port = "3389";
$rdp_ignore_cert = "true"; // Para permitir la conexion sin valida el certificado del PC al que conectarno
?>