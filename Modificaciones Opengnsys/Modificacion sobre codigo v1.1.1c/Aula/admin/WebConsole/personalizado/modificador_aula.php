<?php
include_once("../includes/ctrlacc.php");
include_once("../personalizado/configuracion/mapeo_particiones_opengnsys.php");

function añadirDependencias(){
	global $mapeoParticiones;

	echo '<LINK rel="stylesheet" type="text/css" href="../personalizado/modificacionAula.css">' ;
	echo '<SCRIPT language="javascript" src="../idiomas/javascripts/'.$_SESSION["widioma"].'/comandos/comunescomandos_'.$_SESSION["widioma"].'.js"></SCRIPT>';
	//Para permitir tener mensajes de comandos
	echo "<script>
		var CTbMsg_comando = new Array();
		CTbMsg_comando=CTbMsg;
		var mapeoParticiones = new Array();\n";
	foreach ($mapeoParticiones as $key => $value) {
		//Solo mostramos particiones con sistemas operativos en el mapeo
		if($value['esSistemaOperativo']){
			echo "mapeoParticiones['$key'] = {};\n";
			echo "mapeoParticiones['$key']['comprobacion'] = '".$value['comandoComprobacion']."';\n";
			echo "mapeoParticiones['$key']['comentario'] = '".$value['comandoComentario']."';\n";
			echo "mapeoParticiones['$key']['lugarComentario'] = '".$value['lugarComentario']."';\n";
		}
 		
	}	
	echo "</script>";
	echo '<SCRIPT language="javascript" src="../personalizado/modificacionAula.js"></SCRIPT>';

}

function añadirInicioModificacion($nombreaula){

	echo '<form name="'.$nombreaula.'" action="" onSubmit="enviarDatos(\''.$_GET["litambito"].'\',\''.$_GET["idambito"].'\',this);return false;">';
}

function añadirOpcionesModificacion($Mnombreordenador,$Mmac,$Mip,$TbMsg){

	echo "<div class=\"opciones\">
				<div>
				<p>$TbMsg[53]</p>
			    <a class=\"check_encendido\">
					<input class=\"check_encendido\"  id=\"".$Mnombreordenador."_encendido\" type=\"checkbox\" name=\"encender\"  onclick=\"pulsadoAccion('$Mnombreordenador',this);\" value=\"".$Mnombreordenador."_".$Mmac."_".$Mip."\">
					<label>
					</label>
				</a>
				</div>
				<div>
				<p>$TbMsg[54]</p>
				<a class=\"check_apagado\">
					<input class=\"check_apagado\" id=\"".$Mnombreordenador."_apagado\" type=\"checkbox\" name=\"apagar\"  onclick=\"pulsadoAccion('$Mnombreordenador',this);\" 
					value=\"".$Mnombreordenador."_".$Mmac."_".$Mip."\">
					<label >
					</label>
				</a>
				</div>
				<div>
				<p>$TbMsg[55]</p>
				<a class=\"check_enviarArchivos\">
					<input class=\"check_enviarArchivos\" id=\"".$Mnombreordenador."_enviarArchivos\" type=\"checkbox\" name=\"enviarArchivos\"  onclick=\"pulsadoAccion('$Mnombreordenador',this);\" value=\"".$Mnombreordenador."_".$Mmac."_".$Mip."\">
					<label >
					</label>
				</a>
				</div>
				<div>
				<p>$TbMsg[56]</p>
				<a class=\"check_enviarComando\">
					<input class=\"check_enviarComando\" id=\"".$Mnombreordenador."_enviarComando\" type=\"checkbox\" name=\"enviarComando\"  onclick=\"pulsadoAccion('$Mnombreordenador',this);\" value=\"".$Mnombreordenador."_".$Mmac."_".$Mip."\">
					<label >
					</label>
				</a>
				</div>
				<div>
				<p>$TbMsg[57]</p>
				<a class=\"check_enviarProcedimiento\">
					<input class=\"check_enviarProcedimiento\" id=\"".$Mnombreordenador."_enviarProcedimiento\" type=\"checkbox\" name=\"enviarProcedimiento\"  onclick=\"pulsadoAccion('$Mnombreordenador',this);\" value=\"".$Mnombreordenador."_".$Mmac."_".$Mip."\">
					<label >
					</label>
				</a>
				</div>
			</div>";


}
function añadirFinModificacion($nombreaula,$TbMsg){
	global $cadenaconexion;
	$cmd=CreaComando($cadenaconexion);
	$cmd->texto="SELECT descripcion,idprocedimiento FROM procedimientos";	
	$procedimientos = array();
	
	$rs=new Recordset; 
	$rs->Comando=&$cmd; 
	if (!$rs->Abrir()){
			echo "<script  type=\"text/javascript\">
				alert('".$rs->DescripUltimoError().$TbErr[0].str_replace(array("'", "\n" ,"\t"), "",$cmd->texto)." ')
				</script>";
			return; 
		} 
	while (!$rs->EOF){
		$descripcionProcedimiento = $rs->campos["descripcion"];
		$idProcedimiento = $rs->campos["idprocedimiento"];
		$procedimientos[$idProcedimiento] = $descripcionProcedimiento;
		$rs->Siguiente();
	}

	echo "<p style=\"text-align:center;\" >
				<select  name=\"accion_$nombreaula\">
				  <option value=\"\">$TbMsg[58]</option>
 				  <option value=\"encender\">$TbMsg[53]</option>
  				  <option value=\"apagar\">$TbMsg[54]</option>
  				   <option value=\"enviarArchivos\">$TbMsg[55]</option>
  				  <option value=\"enviarComando\">$TbMsg[56]</option>
  				   <option value=\"enviarProcedimiento\">$TbMsg[57]</option>
				</select>
				<button type=\"button\" onclick=\"seleccionarAccionTodos('$nombreaula');\">$TbMsg[59]</button>
			<br>
			<label for=\"procedimiento\">$TbMsg[62]</label>
			<select name=\"procedimiento\">
			<option value=\"\" >$TbMsg[63]</option>";	

	foreach ($procedimientos as $idprocedimiento => $descripcion) {
		echo "<option value=\"$idprocedimiento\">$descripcion</option>";
	}
	echo "</select>
	    </p>
		<p style=\"text-align:center;\">
			<button type=\"button\" value=\"\" onclick=\"window.open('../personalizado/seleccion_fichero.php','Ventana seleccionar ficheros a enviar','toolbar=no, location=no, directories=no, status=no, menubar=no, scrollbars=yes, resizable=no, copyhistory=no, width=660, height=500', false)\">$TbMsg[60]
			</button>
		</p>
		<p style=\"text-align:center;\" >
				<input type=\"submit\" value=$TbMsg[51]>
				<input type=\"reset\" value=$TbMsg[52]>
				<button type=\"button\" onclick=\"ocultarOpciones('$nombreaula');\">$TbMsg[61]</button>
		</p>";
	
	echo '</form>';

}	

?>