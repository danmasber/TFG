<?php
// ********************************************************************
// Aplicación WEB: ogAdmWebCon 
// Autor: José Manuel Alonso (E.T.S.I.I.) Universidad de Sevilla 
// Fecha Creación: Agosto-2010 
// Fecha Última modificación: Agosto-2010 
// Nombre del fichero: controlacceso.php 
// Descripción :Este fichero implementa el control de acceso de los operadores de aula
// *********************************************************************
include_once("../includes/ctrlacc.php");
include_once("../clases/AdoPhp.php");
include_once("../includes/constantes.php");
include_once("../includes/CreaComando.php");
  
$usu=""; 
$pss=""; 
  
if (isset($_POST["usu"])) $usu=$_POST["usu"];  
if (isset($_POST["pss"])) $pss=$_POST["pss"];  

$cmd=CreaComando($cadenaconexion);
if (!$cmd)
	Header('Location:acceso_operador.php?herror=2'); // Error de conexióncon servidor B.D.

global $ITEM_PUBLICO; 
global $ITEM_PRIVADO;
global $ITEM_OPERADOR;

// COntrol de acceso del usuario
$rs=new Recordset;  
  
$cmd->texto="SELECT usuarios.idusuario,usuarios.idtipousuario
		FROM usuarios
		INNER JOIN administradores_centros ON administradores_centros.idusuario=usuarios.idusuario
		 WHERE usuarios.usuario='".$usu."' AND usuarios.pasguor=SHA2('".$pss."',224)"; 
$rs->Comando=&$cmd; 

if (!$rs->Abrir()){
	Header('Location:acceso_operador.php?herror=2'); // Error de conexióncon servidor B.D. 
	exit;
}
if ($rs->EOF){
	Header('Location:acceso_operador.php?herror=1'); // Error de acceso, no existe usuario
	exit;
}
// Acceso al menu de adminitración del aula
//$wurl="menucliente.php?iph=".$iph."&tip=".$ITEMS_PRIVADOS;
$idtipousuario=$rs->campos["idtipousuario"]; 

global $SUPERADMINISTRADOR; 
global $ADMINISTRADOR; 
global $OPERADOR; //Este tipo de usuario accederá aun menú distinto donde se mostrará los item_operador

$wurl="menucliente.php?tip=".$ITEM_PUBLICO;
if($idtipousuario==$SUPERADMINISTRADOR || $idtipousuario==$ADMINISTRADOR ){
	$wurl="menucliente.php?tip=".$ITEM_PRIVADO;
	$_SESSION["swoptipo"]=$ITEM_PRIVADOS;
}

if($idtipousuario==$OPERADOR){
	$wurl="menucliente.php?tip=".$ITEM_OPERADOR;
	$_SESSION["swoptipo"]=$ITEM_OPERADOR;
}

$_SESSION["swop"]=$usu; 
Header('Location:'.$wurl); 
exit;
