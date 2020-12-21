<?php
// *************************************************************************************************************************************************
include_once("../includes/ctrlacc.php");
include_once("../includes/restfunctions.php");
include_once("../clases/AdoPhp.php");
include_once("../includes/constantes.php");
include_once("../includes/CreaComando.php");
include_once("../includes/RecopilaIpesMacs.php");
// *************************************************************************************************************************************************
include_once("./configuracion/configuracion_sincronizacion_guacamole.php");

include_once("../idiomas/php/$idioma/sincronizacion_guacamole_$idioma.php");

function calcularIdAdministrador($cmd_guacamole){
	global $nombreAdministrador;
	$cmd_guacamole->texto="SELECT entity_id FROM guacamole_entity WHERE guacamole_entity.name='".$nombreAdministrador."'";

	$rs_guacamole=new Recordset; 
	$rs_guacamole->Comando=&$cmd_guacamole; 
		
	if (!$rs_guacamole->Abrir()){
		echo "<script  type=\"text/javascript\">
			alert('".$rs_guacamole->DescripUltimoError()."La consulta fue ".str_replace(array("'", "\n" ,"\t"), "",$cmd_guacamole->texto)	." ')
			</script>";
		return; 
	} 

	$rs_guacamole->Primero(); 
	while (!$rs_guacamole->EOF){
		$entity_id=$rs_guacamole->campos["entity_id"];
		$rs_guacamole->Siguiente();
	}
	if (!isset($entity_id)) {
		echo "<script  type=\"text/javascript\">
			alert('Esta mal configurado el nombre de admistrador $nombreAdministrador')
			</script>";
	}
	return $entity_id;
}

function calcularIdConexion($cmd_guacamole){
	$cmd_guacamole->texto="SELECT MAX(connection_id+1) AS idConexion FROM guacamole_connection";
	$rs_guacamole=new Recordset; 
	$rs_guacamole->Comando=&$cmd_guacamole; 
		
	if (!$rs_guacamole->Abrir()){
		echo "<script  type=\"text/javascript\">
			alert('".$rs_guacamole->DescripUltimoError()."La consulta fue ".str_replace(array("'", "\n" ,"\t"), "",$cmd_guacamole->texto)	." ')
			</script>";
		return; 
	} 

	$rs_guacamole->Primero(); 
	while (!$rs_guacamole->EOF){
		$idConexion=$rs_guacamole->campos["idConexion"];
		$rs_guacamole->Siguiente();
	}
	return $idConexion == null ? 1 : $idConexion;
}

function calcularIdGrupo($cmd_guacamole){
	$cmd_guacamole->texto="SELECT MAX(connection_group_id+1) AS idGrupo FROM guacamole_connection_group";
	$rs_guacamole=new Recordset; 
	$rs_guacamole->Comando=&$cmd_guacamole; 
		
	if (!$rs_guacamole->Abrir()){
		echo "<script  type=\"text/javascript\">
			alert('".$rs_guacamole->DescripUltimoError()."La consulta fue ".str_replace(array("'", "\n" ,"\t"), "",$cmd_guacamole->texto)	." ')
			</script>";
		return; 
	} 

	$rs_guacamole->Primero(); 
	
	while (!$rs_guacamole->EOF){
		$idGrupo=$rs_guacamole->campos["idGrupo"];
		$rs_guacamole->Siguiente();
	}
	return $idGrupo == null ? 1 : $idGrupo;
}

function eliminarPC($PC,$cmd_guacamole){
	$cmd_guacamole->CreaParametro("@nombre",0,1);
	$cmd_guacamole->ParamSetValor("@nombre",$PC);

	$cmd_guacamole->texto="DELETE FROM guacamole_connection_group_permission
			WHERE guacamole_connection_group_permission.connection_group_id IN(
			SELECT parent_id
				FROM guacamole_connection
				WHERE connection_name LIKE '%@nombre%')";
	$resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}					
	$cmd_guacamole->texto="DELETE FROM guacamole_connection_group_permission 
			WHERE guacamole_connection_group_permission.connection_group_id IN(
			SELECT parent_id
				FROM guacamole_connection
				WHERE connection_name LIKE '%@nombre%')";
	$resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}
	$cmd_guacamole->texto="DELETE FROM guacamole_connection_group
			WHERE guacamole_connection_group.connection_group_id IN(
			SELECT parent_id
				FROM guacamole_connection
				WHERE connection_name LIKE '%@nombre%')";
	$resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}
	//Borro las conexiones
	$cmd_guacamole->texto="DELETE FROM guacamole_connection_permission
			WHERE guacamole_connection_permission.connection_id IN(
			SELECT connection_id
				FROM guacamole_connection
				WHERE connection_name LIKE '%@nombre%')";
	$resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}
	$cmd_guacamole->texto="DELETE FROM guacamole_connection_parameter
			WHERE guacamole_connection_parameter.connection_id IN(
			SELECT connection_id
				FROM guacamole_connection
				WHERE connection_name LIKE '%@nombre%')";
	$resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}
	$cmd_guacamole->texto="DELETE FROM guacamole_connection
			WHERE connection_name LIKE'%@nombre%'";
	$resul=$cmd_guacamole->Ejecutar();
	
	return $resul;
}

function actualizarPC($PC,$cmd_guacamole){
	$cmd_guacamole->CreaParametro("@ip",0,1);
	$cmd_guacamole->CreaParametro("@nombre",0,1);
	$cmd_guacamole->ParamSetValor("@ip",$PC['ip']);
	$cmd_guacamole->ParamSetValor("@nombre",$PC['nombre']);

	$cmd_guacamole->texto="UPDATE guacamole_connection_parameter 
		SET  guacamole_connection_parameter.parameter_value = '@ip'
		WHERE guacamole_connection_parameter.connection_id IN (
			SELECT connection_id
			FROM guacamole_connection
			WHERE connection_name LIKE '%@nombre%')
			AND guacamole_connection_parameter.parameter_name = 'hostname' ";
	$resul=$cmd_guacamole->Ejecutar();

	return  $resul;			
}

function crearPC($PC,$cmd_guacamole){
	global $subfijo_vnc;      
	global $subfijo_ssh;      
	global $subfijo_rdp;  
	##################  CONFIGURACION   VNC  ############# 
	global $vnc_pass;      
	global $vnc_port;      

	##################  CONFIGURACION   SSH  ############# 
	global $ssh_config;
	global $ssh_user;  
	global $ssh_pass;     
	global $ssh_port;  
	global $ssh_private;
	global $ssh_passphrase;
	##################  CONFIGURACION   RDP  ############# 
	global $rdp_user;   
	global $rdp_pass;     
	global $rdp_port;    
	global $rdp_ignore_cert;  


	$idGrupo = calcularIdGrupo($cmd_guacamole);
	$idAdministrador = calcularIdAdministrador($cmd_guacamole);
	$cmd_guacamole->CreaParametro("@nombre",0,1);
	$cmd_guacamole->CreaParametro("@nombre_vnc",0,1);
	$cmd_guacamole->CreaParametro("@nombre_ssh",0,1);
	$cmd_guacamole->CreaParametro("@nombre_rdp",0,1);
	$cmd_guacamole->CreaParametro("@idGrupo",0,1);
	$cmd_guacamole->CreaParametro("@idConexion",0,1);
	$cmd_guacamole->CreaParametro("@idAdministrador",0,1);
	$cmd_guacamole->CreaParametro("@ip",0,1);
	$cmd_guacamole->ParamSetValor("@nombre",$PC['nombre']);
	$cmd_guacamole->ParamSetValor("@idGrupo",$idGrupo);
	$cmd_guacamole->ParamSetValor("@idAdministrador",$idAdministrador);
	$cmd_guacamole->ParamSetValor("@ip",$PC['ip']);
	$cmd_guacamole->ParamSetValor("@nombre_vnc",$PC['nombre'].$subfijo_vnc);
	$cmd_guacamole->ParamSetValor("@nombre_ssh",$PC['nombre'].$subfijo_ssh);
	$cmd_guacamole->ParamSetValor("@nombre_rdp",$PC['nombre'].$subfijo_rdp);
	$cmd_guacamole->texto="INSERT INTO guacamole_connection_group 
							(connection_group_id, parent_id, connection_group_name, `type`, max_connections, max_connections_per_user, enable_session_affinity) 
							VALUES (@idGrupo,NULL,'@nombre','ORGANIZATIONAL',NULL,NULL,0)";
	$resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}	
	$cmd_guacamole->texto="INSERT INTO guacamole_db.guacamole_connection_group_permission
						(entity_id, connection_group_id, permission)
						VALUES(@idAdministrador, @idGrupo, 'READ'),
							  (@idAdministrador, @idGrupo, 'UPDATE'),
							  (@idAdministrador, @idGrupo, 'DELETE'),
							  (@idAdministrador, @idGrupo, 'ADMINISTER')";
	$resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}		

	$idConexion = calcularIdConexion($cmd_guacamole);
	$cmd_guacamole->ParamSetValor("@idConexion",$idConexion);
	$cmd_guacamole->texto="INSERT INTO guacamole_connection (connection_id,connection_name,parent_id,protocol) 
							VALUES (@idConexion,'@nombre_vnc',@idGrupo,'vnc')";
	 $resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}	 

	$cmd_guacamole->texto="INSERT INTO guacamole_connection_parameter (connection_id,parameter_name,parameter_value) 
							VALUES 
							(@idConexion,'hostname','@ip'),
							(@idConexion,'password','".$vnc_pass."'),
							(@idConexion,'port','".$vnc_port."')";
	 $resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}	 

	$cmd_guacamole->texto="INSERT INTO guacamole_connection_permission (entity_id,connection_id,permission) 
		VALUES 
		(@idAdministrador, @idConexion ,'READ'),
		(@idAdministrador, @idConexion ,'UPDATE'),
		(@idAdministrador, @idConexion ,'DELETE'),
		(@idAdministrador, @idConexion ,'ADMINISTER')";
	 $resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}

	$idConexion = calcularIdConexion($cmd_guacamole);
	$cmd_guacamole->ParamSetValor("@idConexion",$idConexion);
	$cmd_guacamole->texto="INSERT INTO guacamole_connection (connection_id,connection_name,parent_id,protocol) 
							VALUES (@idConexion,'@nombre_ssh',@idGrupo,'ssh')";
	 $resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}	 

	$cmd_guacamole->texto="INSERT INTO guacamole_connection_parameter (connection_id,parameter_name,parameter_value) 
							VALUES 
							(@idConexion,'hostname','@ip'),
							(@idConexion,'port','".$ssh_port."'),
							(@idConexion,'username','".$ssh_user."')";
	
	if ($ssh_config == 'pass') {
		$cmd_guacamole->texto .= ",(@idConexion,'password','".$ssh_pass."')";
	}
	
	if ($ssh_config == 'privateKey' || $ssh_config == 'privateKey&passphrase') {
		$cmd_guacamole->texto .= ",(@idConexion,'private-key','".$ssh_private."')";
	}

	if ($ssh_config == 'privateKey&passphrase') {
		$cmd_guacamole->texto .= ",(@idConexion,'passphrase','".$ssh_passphrase."')";
	}					

	 $resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}	 

	$cmd_guacamole->texto="INSERT INTO guacamole_connection_permission (entity_id,connection_id,permission) 
		VALUES 
		(@idAdministrador, @idConexion ,'READ'),
		(@idAdministrador, @idConexion ,'UPDATE'),
		(@idAdministrador, @idConexion ,'DELETE'),
		(@idAdministrador, @idConexion ,'ADMINISTER')";
	 $resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}	 

	$idConexion = calcularIdConexion($cmd_guacamole);
	$cmd_guacamole->ParamSetValor("@idConexion",$idConexion);
	$cmd_guacamole->texto="INSERT INTO guacamole_connection (connection_id,connection_name,parent_id,protocol) 
							VALUES (@idConexion,'@nombre_rdp',@idGrupo,'rdp')";
	 $resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}	 

	$cmd_guacamole->texto="INSERT INTO guacamole_connection_parameter (connection_id,parameter_name,parameter_value) 
							VALUES 
							(@idConexion,'hostname','@ip'),
							(@idConexion,'port','".$rdp_port."'),
							(@idConexion,'password','".$rdp_pass."'),
							(@idConexion,'username','".$rdp_user."'),
            				(@idConexion,'ignore-cert','".$rdp_ignore_cert."')";

	$resul=$cmd_guacamole->Ejecutar();
	if(!$resul){
		return false;
	}	 

	$cmd_guacamole->texto="INSERT INTO guacamole_connection_permission (entity_id,connection_id,permission) 
		VALUES 
		(@idAdministrador, @idConexion ,'READ'),
		(@idAdministrador, @idConexion ,'UPDATE'),
		(@idAdministrador, @idConexion ,'DELETE'),
		(@idAdministrador, @idConexion ,'ADMINISTER')";
	 $resul=$cmd_guacamole->Ejecutar();
	return $resul;
}


$cmd=CreaComando($cadenaconexion);
$cmd->texto="SELECT ip,nombreordenador,idcentro FROM ordenadores 
				INNER JOIN  aulas ON 
					(aulas.idaula = ordenadores.idaula) 
				ORDER BY nombreordenador";
$rs=new Recordset; 
$rs->Comando=&$cmd; 
	if (!$rs->Abrir()){
	echo "<script  type=\"text/javascript\">
			alert('".$rs->DescripUltimoError()."La consulta fue ".str_replace(array("'", "\n" ,"\t"), "",$cmd->texto)	." ')
			</script>";
	return; 
	} 

	$rs->Primero(); 

	$k = 0;
	$Ordenadores_opengnsys = array();
	while (!$rs->EOF){
		$ip=$rs->campos["ip"];
		$nombre=$rs->campos["nombreordenador"];
		$idcentroOrdenador=$rs->campos["idcentro"];
		$Ordenadores_opengnsys[$k]['nombre'] = $nombre;
		$Ordenadores_opengnsys[$k]['ip'] = $ip;
		$Ordenadores_opengnsys[$k]['idcentro'] = $idcentroOrdenador;
		$rs->Siguiente();
		$k++;
	}
	$rs->Cerrar();

$cmd_guacamole=CreaComando($cadenaconexion_guacamole);

$noError = true; 
$accionesSincronizacion = false; 
foreach ($_POST as $PC => $accion) {
	if ($noError) {
		switch ($accion) {
		case 'actualizar':
			foreach ($Ordenadores_opengnsys as $PC_opengnsys) {
				$pos = strpos($PC, $PC_opengnsys['nombre']);
				if ($pos !== false) {
					$noError = actualizarPC($PC_opengnsys,$cmd_guacamole);
				} 
			}
			$accionesSincronizacion = true;
			break;
		case 'crear':
			foreach ($Ordenadores_opengnsys as $PC_opengnsys) {
				$pos = strpos($PC, $PC_opengnsys['nombre']);
				if ($pos !== false) {
					$noError =  crearPC($PC_opengnsys,$cmd_guacamole);
				} 
			}
			$accionesSincronizacion = true;
			break;
		case 'eliminar':
			$noError =  eliminarPC($PC,$cmd_guacamole);
			$accionesSincronizacion = true;
			break;
		case 'eliminar_crear':
			$noError =  eliminarPC($PC,$cmd_guacamole);
			if ($noError) {
				foreach ($Ordenadores_opengnsys as $PC_opengnsys) {
					$pos = strpos($PC, $PC_opengnsys['nombre']);
					if ($pos !== false) {
						$noError =  crearPC($PC_opengnsys,$cmd_guacamole);
					} 
				}
			}
			$accionesSincronizacion = true;
			break;			
		default:
			break;
		}
	}	
}

if(isset($_POST) && $accionesSincronizacion){
		echo "<script  type=\"text/javascript\">
			alert('".$cmd_guacamole->DescripUltimoError()."')
			</script>";
	}

$cmd_guacamole->texto="SELECT DISTINCT  gc.connection_name AS nombre ,gcp.parameter_value AS ip
	FROM guacamole_connection gc 
		INNER JOIN guacamole_connection_parameter gcp on(
			gc.connection_id=gcp.connection_id
		)WHERE gcp.parameter_name='hostname' ";

$rs_guacamole=new Recordset; 
$rs_guacamole->Comando=&$cmd_guacamole; 
	
if (!$rs_guacamole->Abrir()){
	echo "<script  type=\"text/javascript\">
			alert('".$rs_guacamole->DescripUltimoError()."La consulta fue ".str_replace(array("'", "\n" ,"\t"), "",$cmd_guacamole->texto)	." ')
			</script>";
	return; 
} 

$rs_guacamole->Primero(); 
$k = 0;
$Ordenadores_guacamole= array();

while (!$rs_guacamole->EOF){
	$ip=$rs_guacamole->campos["ip"];
	$nombre=$rs_guacamole->campos["nombre"];
	$Ordenadores_guacamole[$k]['nombre'] = $nombre;
	$Ordenadores_guacamole[$k]['ip'] = $ip;
	$k++;
	$rs_guacamole->Siguiente();
}

$rs_guacamole->Cerrar();	

$PC_actualizar=array();
$PC_no_actualizar=array();
$PC_crear=array();
$PC_eliminar=array();

foreach ($Ordenadores_guacamole as $PC_guacamole) {
	$PC_existe_opengnsys = false; 
	foreach ($Ordenadores_opengnsys as $PC_opengnsys) {
		$pos = strpos($PC_guacamole['nombre'], $PC_opengnsys['nombre']."_");
		if ($pos !== false) {
			if($PC_opengnsys['idcentro'] === $idcentro){
				if ($PC_guacamole['ip'] != $PC_opengnsys['ip']) {
				$PC_actualizar[$PC_opengnsys['nombre']]['ip_antigua'] = $PC_guacamole['ip'];
				$PC_actualizar[$PC_opengnsys['nombre']]['ip_nueva'] = $PC_opengnsys['ip'];
				} else{
					$PC_no_actualizar[$PC_opengnsys['nombre']] = $PC_opengnsys['ip'];	
				}
			}
			$PC_existe_opengnsys = true; 
		} 
	}
	if (!$PC_existe_opengnsys) {
		$PC_eliminar[$PC_guacamole['nombre']] = $PC_guacamole['ip'];
	}
}

foreach ($Ordenadores_opengnsys as $PC_opengnsys) {
	$PC_existe_guacamole = false; 
	foreach ($PC_actualizar as $nombre => $ips) {
		if(strcmp($PC_opengnsys['nombre'], $nombre) === 0){
			$PC_existe_guacamole = true; 
		}
	}
	foreach ($PC_no_actualizar as $nombre => $ips) {
		if(strcmp($PC_opengnsys['nombre'], $nombre) === 0 ){
			$PC_existe_guacamole = true; 
		}
	}

	if (!$PC_existe_guacamole && $PC_opengnsys['idcentro'] === $idcentro ) {
		$PC_crear[$PC_opengnsys['nombre']] = $PC_opengnsys['ip'];
	}
}
?>

<HTML>
	<HEAD>
		<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
		<LINK rel="stylesheet" type="text/css" href="../estilos.css">
		<style>
			input[type="submit"], input[type="button"] {
				border-radius: 10px;
			    color: black;
			    border: 2px solid #555555;
			    border: none;
			    padding: 4px 8px;
			    text-align: center;
			    text-decoration: none;
			    display: inline-block;
			    margin: 4px 2px;
			    -webkit-transition-duration: 0.4s; 
			    transition-duration: 0.4s;
			    cursor: pointer;
			}

			input[type="submit"]:hover, input[type="button"]:hover {
			    background-color: #555555;
			    color: white;
			}
			@media screen and (min-width: 700px){
			.row {
			  display: flex;
			  flex-direction: row;
			  flex-wrap: wrap;
			  width: 100%;
			}
			
 			.column {
			  display: flex;
			  flex-direction: column;
			  flex-basis: 100%;
			  flex: 1;
			}	
		}
		</style>
	</HEAD>
<BODY OnContextMenu="return false">
	<script type="text/javascript"  src="./sincronizacion_guacamole.js"></script>

<p align=center><span align=center class=cabeceras><?php echo $TbMsg[0] ?></span></p>
<form  action="" method="POST" onsubmit="return validateForm();">
<div class="row" align=center>
<div class="column opengnsys" align="center">
<p align=center><span align=center class=cabeceras>Opengnsys</span></p>
	</br>

<p align=center><span align=center class=subcabeceras><?php echo $TbMsg[1] ?></span></p>
	</br>
<table id="tabla_actualizar" align=center border=0 cellPadding=3 cellSpacing=1 class=tabla_datos>
		<tr>
			<th align=center><input type="checkbox" onclick="selectAll('tabla_actualizar',this)"></th>
			<th align=center>Nombre</th>
			<th align=center>IP antigua</th>
			<th align=center>IP nueva</th>
		</tr>
<?php
foreach ($PC_actualizar as $nombre => $ips) {
	echo "<tr>
			<td align=center><input type=\"checkbox\" class=\"seleccion\" name=\"".$nombre."\" value=\"actualizar\"></td>
			<td align=center>".$nombre."</td>
			<td align=center>".$ips['ip_antigua']."</td>
			<td align=center>".$ips['ip_nueva']."</td>
		</tr>";
}	
?>
</table>

<p align=center><span align=center class=subcabeceras><?php echo $TbMsg[2] ?></span></p>
	</br>
<table id="tabla_crear" align=center border=0 cellPadding=3 cellSpacing=1 class=tabla_datos>
		<tr>
			<th align=center><input type="checkbox" onclick="selectAll('tabla_crear',this)" ></th>
			<th align=center>Nombre</th>
			<th align=center>IP</th>
		</tr>
<?php
foreach ($PC_crear as $nombre => $ip) {
	echo "<tr>
			<td align=center><input type=\"checkbox\"   class=\"seleccion\" name=\"".$nombre."\" value=\"crear\" ></td>
			<td align=center>".$nombre."</td>
			<td align=center>".$ip."</td>
		</tr>";
}	
?>
</table>
</div>
<div class="column guacamole" align="center">
<p align=center><span align=center class=cabeceras>Guacamole</span></p>
	</br>
<p align=center><span align=center class=subcabeceras><?php echo $TbMsg[3] ?></span></p>
	</br>
<table id="tabla_eliminar" align=center border=0 cellPadding=3 cellSpacing=1 class=tabla_datos>
		<tr>
			<th align=center><input type="checkbox" onclick="selectAll('tabla_eliminar',this)"></th>
			<th align=center>Nombre</th>
			<th align=center>IP</th>
		</tr>
<?php
foreach ($PC_eliminar as $nombre => $ip) {
	echo "<tr>
			<td align=center><input type=\"checkbox\"  class=\"seleccion\" name=\"".$nombre."\"  value=\"eliminar\"></td>
			<td align=center>".$nombre."</td>
			<td align=center>".$ip."</td>
		</tr>";
}	
?>
</table>
<p align=center><span align=center class=subcabeceras><?php echo $TbMsg[4] ?></span></p>
    </br>
<table id="tabla_eliminar_crear" align=center border=0 cellPadding=3 cellSpacing=1 class=tabla_datos>
        <tr>
            <th align=center><input type="checkbox" onclick="selectAll('tabla_eliminar_crear',this)"></th>
            <th align=center>Nombre</th>
            <th align=center>IP</th>
        </tr>
<?php
foreach ($PC_no_actualizar as $nombre => $ip) {
    echo "<tr>
            <td align=center><input type=\"checkbox\"  class=\"seleccion\" name=\"".$nombre."\"  value=\"eliminar_crear\"></td>
            <td align=center>".$nombre."</td>
            <td align=center>".$ip."</td>
        </tr>";
}    
?>
</table>

</div>
</div>
<p style="text-align:center;" >
	<input type="submit" value="<?php echo $TbMsg[5] ?>" >
	<br>
	<input type="button" value="<?php echo $TbMsg[6] ?>" onclick="selectAllTables(this)">
</p>
</form>
</BODY>
</HTML>