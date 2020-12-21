<?php

// *************************************************************************************************************************************************
include_once("../includes/ctrlacc.php");
include_once("../includes/restfunctions.php");
include_once("../clases/AdoPhp.php");
include_once("../includes/constantes.php");
include_once("../includes/CreaComando.php");
include_once("../includes/RecopilaIpesMacs.php");
// *************************************************************************************************************************************************
include_once("./configuracion/configuracion_fichero.php");

$cadenaid="";
$cadenaip="";
$cadenamac="";
$cadenaoga="";
$cmd=CreaComando($cadenaconexion);
if($_POST['ambito'] == 'aulas'){
	RecopilaIpesMacs($cmd,$AMBITO_AULAS,$_POST['idambito']);
} 
if($_POST['ambito'] == 'gruposordenadores'){
	RecopilaIpesMacs($cmd,$AMBITO_GRUPOSORDENADORES,$_POST['idambito']);
} 

$auxIp = explode(';', $cadenaip);
$auxId = explode(',', $cadenaid);
$auxKey = explode(";", $cadenaoga);

$return="";

$encender = json_decode($_POST['encender']);
$encender_ip = array(); 
foreach($encender as $d){
	list($name, $mac, $ip) = explode('_', $d);
  	array_push($encender_ip,$ip);
}

$apagar = json_decode($_POST['apagar']);
$apagar_ip = array(); 
foreach($apagar as $d){
	list($name, $mac, $ip) = explode('_', $d);
  	array_push($apagar_ip,$ip);
}

$enviarArchivos = json_decode($_POST['enviarArchivos']);
$enviarArchivos_ip = array(); 
foreach($enviarArchivos as $d){
	list($name, $mac, $ip) = explode('_', $d);
  	array_push($enviarArchivos_ip,$ip);
}

$enviarComando = json_decode($_POST['enviarComando']);
$enviarComando_ip = array(); 
foreach($enviarComando as $d){
	list($name, $mac, $ip) = explode('_', $d);
  	array_push($enviarComando_ip,$ip);
}

$idProcedimientoEnviado = json_decode($_POST['idProcedimientoEnviar']);
$descripcionProcedimientoEnviado = $_POST['descripcionProcedimientoEnviar'];
$enviarProcedimiento = json_decode($_POST['enviarProcedimiento']);

$enviarProcedimiento_ip = array(); 
foreach($enviarProcedimiento as $d){
	list($name, $mac, $ip) = explode('_', $d);
  	array_push($enviarProcedimiento_ip,$ip);
}


$i = 0;
foreach ($auxIp as $ip) {

	if(in_array($ip, $encender_ip)){	
		$return .= "encender_".$AMBITO_ORDENADORES."_".$auxId[$i]."_".$ip.",";
	}
	
	if(in_array($ip, $apagar_ip)){	
   		$return .= "apagar_".$AMBITO_ORDENADORES."_".$auxId[$i]."_".$ip.",";
	}

	if(in_array($ip, $enviarArchivos_ip)){	
   		$return .= "enviarArchivos_".$AMBITO_ORDENADORES."_".$auxId[$i]."_".$ip."_".$comandoParaCopia.",";
	}

	if(in_array($ip, $enviarComando_ip)){	
   		$return .= "enviarComando_".$AMBITO_ORDENADORES."_".$auxId[$i]."_".$ip.",";
	}

	if(in_array($ip, $enviarProcedimiento_ip)){	
		$return .= "enviarProcedimiento_".$AMBITO_ORDENADORES."_".$auxId[$i]."_".$ip."_".str_replace("_" , "*barraBaja*", $descripcionProcedimientoEnviado)."_".$idProcedimientoEnviado.",";
	}
	$i++;
}

if (!empty($return)) {
    echo trim($return,",");
}
?>