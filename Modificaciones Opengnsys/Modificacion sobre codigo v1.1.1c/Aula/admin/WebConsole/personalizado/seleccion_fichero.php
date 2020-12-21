	<?php
	include_once("../includes/ctrlacc.php");
	include_once("../clases/AdoPhp.php");
	include_once("../includes/CreaComando.php");
	include_once("./configuracion/configuracion_fichero.php");
	include_once("./configuracion/mapeo_particiones_opengnsys.php");
	include_once("../idiomas/php/".$idioma."/seleccion_fichero_".$idioma.".php");
	$scriptCopia = null;

	if (isset($_POST['borrar'])){
		unlink($directorio_absoluto_ficheros.$fichero_script_copia);
		unlink($directorio_absoluto_ficheros.$fichero_ultima_seleccion);
		echo "<script type=\"text/javascript\">
			alert(\"$TbMsg[1]\")
		</script>";
	}

	/*
	* Creamos los ficheros que usaremos para recordar la seleccion
	* y realizar la copia de fichero posteriormente		 
	*/
	if (isset($_POST['particionNombre'])){

		if (isset($_POST['directorio']) || isset($_POST['fichero'])){
			$scriptCopia = fopen($directorio_absoluto_ficheros.$fichero_script_copia, "w");
			$ficheroListadoSeleccion = fopen($directorio_absoluto_ficheros.$fichero_ultima_seleccion, "w");
			fwrite($scriptCopia, "#!/bin/bash" . PHP_EOL );
			fwrite($scriptCopia,  PHP_EOL."function copiarEnParticion(){" . PHP_EOL);
		    fwrite($scriptCopia,  "[ -d $1" . $_POST['carpetaDestino'] . "  ] || mkdir -p $1" . $_POST['carpetaDestino'] . PHP_EOL);
			fwrite($scriptCopia,  "cd $1" . $_POST['carpetaDestino'] . PHP_EOL);
			fwrite($scriptCopia,  "salida=\"$?\" ; if [ \"\$salida\" != \"0\" ]; then ogEcho log \"Error accediento a \$1\"; exit \$salida ; fi".PHP_EOL);
			fwrite($ficheroListadoSeleccion, "Destino Copia:" . $_POST['carpetaDestino'] . PHP_EOL);
		} 


		if (isset($_POST['directorio'])) {
			foreach ($_POST['directorio'] as $directorio_seleccionado)
			{
				fwrite($ficheroListadoSeleccion, $directorio_seleccionado . PHP_EOL);
			}
		}

		if (isset($_POST['fichero'])) {
			foreach ($_POST['fichero'] as $fichero) {
				fwrite($ficheroListadoSeleccion, $fichero . PHP_EOL);
				fwrite($scriptCopia, "install -D '" . str_replace($directorio_relativo_ficheros."/" , $directorio_completo_en_ogLive , $fichero) . "' '". str_replace($directorio_relativo_ficheros."/" , "", $fichero) . "'" .PHP_EOL);
				fwrite($scriptCopia, "salida=\"$?\" ; if [ \"\$salida\" != \"0\" ]; then ogEcho log \"Fallo copiando $fichero\"; exit \$salida ; fi".PHP_EOL);
			}
			
			
		}
		if (isset($_POST['directorio']) || isset($_POST['fichero'])){
			fwrite($scriptCopia,  PHP_EOL . "}" . PHP_EOL);
			foreach ($_POST['particionNombre'] as $particionNombre) {
				fwrite($scriptCopia,  "copiarEnParticion \"" .$mapeoParticiones[$particionNombre]['particion'] . "\"" . PHP_EOL);
			}
			fwrite($ficheroListadoSeleccion, "Particiones seleccionada:" . join(",", $_POST['particionNombre']));
			fclose($scriptCopia);
			fclose($ficheroListadoSeleccion);
			echo "<script type=\"text/javascript\">
				alert(\"$TbMsg[0]\")
			</script>";
		}
	}
	

	$ficherosUltimaSeleccion = array();
	$particionesUltimaSeleccion = array();
	if(file_exists($directorio_absoluto_ficheros.$fichero_ultima_seleccion)){
		$ficheroListadoSeleccion = fopen($directorio_absoluto_ficheros.$fichero_ultima_seleccion, "r");

		while ($linea = fgets($ficheroListadoSeleccion)) {
			if(strpos(trim($linea),"Destino Copia:") === false && strpos(trim($linea),"Particiones seleccionada:") === false){
				array_push($ficherosUltimaSeleccion, trim($linea));
			} else if(strpos(trim($linea),"Destino Copia:") !== false){
				$carpetaDestino = substr($linea,strpos($linea,":") + 1);
			} else if(strpos(trim($linea),"Particiones seleccionada:") !== false){
				$particionesUltimaSeleccion = explode(",", substr($linea,strpos($linea,":") + 1));
			}
	   		
		}

		fclose($ficheroListadoSeleccion);
	}

	/**
	 * Funcion que muestra la estructura de carpetas a partir de la ruta dada.
	 */
	function obtener_estructura_directorios($ruta, $clase = array()){
	    global $ficherosUltimaSeleccion;
	   	global $TbMsg;
	    // Se comprueba que realmente sea la ruta de un directorio
	    if (is_dir($ruta)){
	        // Abre un gestor de directorios para la ruta indicada
	        $gestor = opendir($ruta);
	        echo "<ul>";
	        array_push($clase, $ruta);

			$padre = str_replace("//","/",$ruta);
			$padre = str_replace("/","_",$padre);
	        // Recorre todos los elementos del directorio
	        while (($archivo = readdir($gestor)) !== false)  {
	            
	            $ruta_completa = $ruta .'/'. $archivo;
				
				$checked_archivo = in_array($ruta_completa, $ficherosUltimaSeleccion);
				
				// Se muestran todos los archivos y carpetas excepto "." y ".."
	            if ($archivo != "." && $archivo != ".." && !fnmatch('.*',$archivo)) {
	                // Si es un directorio se recorre recursivamente
	                if (is_dir($ruta_completa)) {
	                    if (count($clase) !=1 ) {
	                    	echo "<li ondblclick=\"mostrarHijo('$padre"."_"."$archivo')\" class=\"padre_$padre hijo\" >";
	                    } else {
	                    	echo "<li ondblclick=\"mostrarHijo('$padre$archivo')\" >";
	                    }		
	                    echo "<img  width=\"20\" height=\"20\" src=\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAK9SURBVGhD7Zk7aBRRFIYXLIKCEQuxExEhYhcFCxEFUSsxCJFgAqJ2goWIdiJaiIrgI50kjRoLEdJpumApsfIBFpKg4AvxBYqF7/87zFnuzowxu8p41P3gY+bc7C7nz+7cO49amzZtfspsOShfy29N+FSul2E4LWnsiyTMTHwrec87uVSG4LmkqeVWzZwLkvfdlLMY+NPQDDbLPPlQ8t6jcn4Fdsof0moQWCc/S/+MKnwk+2QBf0Gr9MoHsuxY+t36sck/b5Vs4FeDVM0xSb+nrEr424L0S/q9bFXCfxFkjlwSzH2Sfq/KBsqCMM1dkZ+k/z2iL+QOafhgynnJGCv3ZFCZhr/K+gyWD8Iq/VLybSxkIDDHJb0zkxWCLJPU96yKzRFJr4co8kFYNakLs0JARiW9bqHIB/Gv66BVsZmS9LqIIh/kuqTeZFVcOGnlYH9llcgHeSKpox/oayV9jlsl0iALJPvPrIrNXkmvZ6wSaZCNkv0xq2IzLOl1p1UiDXJAsn/CqtjckvTabZVIg1yS7G+3Ki4s2h/kR9nBAKRB7kj2m71+rxr6o8/bVmV4EJJxWkLSEDcTpoFfDD1ftCrDg6zIthMyOiclve63KsOD7Mq2QzI6zKr0usGqDA9yNtsyP0eHdY5eWffqeJAb2XaNjAxnHPT52KoED/JGcu4yV0bGF+1rViV4EOTKKzqcldOrXUylpEE4v4/OiKTXwt3GNMhhBoLDlSu9dlmVkAbpYSAwvmi/l4VFOw2ymIHArJT0yaOMAh6CWSs6uyW9cruqgAdhHYmOL9p7rMrhQc5ZFRtftFdblcOD8LVFh58/zzpLF20PwoEUGSYi+uShUikk5AU8po7MVkmfhbvwzl3JC7gbsS2oA5LrJPrksUIpm2XVDzRb9b6c9skudyK46mJ+jip3eKKfmbf516jVvgPWjL2OHf8X/wAAAABJRU5ErkJggg==\"/>";
						echo $archivo . "  ";
	                    echo "<input onclick=\"directorio_completo('$ruta_completa',this)\" class=\"".implode(" ", $clase)."\" type=\"checkbox\" name=\"directorio[]\" value=\"$ruta_completa\"";
	                    
	                    if($checked_archivo){
	                    	echo "checked";
	                    }
	                    
	                    echo ">";
	                    echo "</li>";
	                    obtener_estructura_directorios($ruta_completa,$clase);
	                } else {
	                    if (count($clase) !=1 ) {
	                    	echo "<li class=\"padre_$padre hijo\" >";
	                    } else {
	                    	echo "<li>";
	                    }
	                    
	                   	echo "<img width=\"20\" height=\"20\" src=\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAE2SURBVGhD7ZehbsJQFIarCCgcQSEIySzJkMi9AhPYvQoOMZB7gGkQOCRye4WZualhEKjxH8JNGnLTtb3nvy3kfMmXtKnpl9xz0ibGDdGGf0TXsAHpsEPEKDEuZH++02MMo8awQ77h7+WaGsMO2cERpMfECBHoMbFCBGpMzBCBFhM7RKDEVBEipGNWMDimqhBBNYYd8gH7GT7DIwyOYYcUdQ5LwQqRY/NVwB8o7/EOS8EKKcoUWohgIcpYiOO/ENnrj4oOoA96SA/Kcy030Ac9pAs/FV1AHzYjDgtRhh4SurUeYB7oIaFbK+t/JA09pAO3Ab7CPNiMOCxEGXpIEz4pOoQ+6CF3860VurWunUEfNiMOC1HGQhwWooyFOCxEGbWQA5xU6BKqhNTF0iEt+FYjX6BxIyTJCQgBu1XLf9sJAAAAAElFTkSuQmCC\"/>";
	                    echo $archivo . "  ";
	                    echo "<input class=\"".implode(" ", $clase)."\" type=\"checkbox\" name=\"fichero[]\" value=\"$ruta_completa\" onclick=\"seleccionarPadre(this)\"";
	                    
	                    if($checked_archivo){
	                    	echo "checked";
	                    }
	                    
	                    echo ">";
	                    echo "</li>";
	                }
	            }
	        }
	        
	        // Cierra el gestor de directorios
	        closedir($gestor);
	        echo "</ul>";
	    } else {
	        echo "$TbErr[2]<br/>";
	    }
	}

	?>
	<!DOCTYPE html>
	<html>
	<head>
		<title>Ventana seleccionar ficheros a enviar</title>
		<LINK rel="stylesheet" type="text/css" href="../estilos.css">
	</head>
	<body>
		<style type="text/css">
			ul {
				list-style-type: circle;
				display: table;	
			}

			ul {
				
				display: table-cell;	
			}

			input[type="submit"],input[type="button"],button {
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

			input[type="submit"]:hover,input[type="button"]:hover,button:hover {
			    background-color: #555555;
			    color: white;
			}

			select, select option {
			   background-color: #dddddd;
			   border: 3px solid #dddddd;
			   border-radius: 20px;
			}

			.hijo{
				display: none;
			}

			input + label {
				background-color: #dddddd;
			   	border: 5px solid #dddddd;
			   	border-radius: 20px;
				display: table-cell;
				padding: : 3px;
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

			input[name="particionNombre[]"] {
				display: none;
			}

			input:checked + label {
				background-color: #555555;
			    color: white;
			}

			.Particiones{
				border-spacing: 3px;
			}

		</style>
		<script type="text/javascript">

		function directorio_completo(clase,elemento) {
			var hijos = document.getElementsByClassName(clase);
			for (var i = 0; i < hijos.length; ++i) {
				hijos[i].checked = elemento.checked; 
				hijos[i].indeterminate = false;
			}
			seleccionarPadre(elemento);
		}

		function mostrarHijo(padre) {
			var hijos = document.getElementsByClassName("padre_"+padre);
			for (var i = 0; i < hijos.length; ++i) {
				if (hijos[i].style.display == "none") {
					hijos[i].style.display = "list-item"; 
				} else{
					hijos[i].style.display = "none"; 
					ocultarHijo(padre+"_"+hijos[i].textContent.trim());
				}
				
			}
		}	

		function ocultarHijo(padre) {
			var hijos = document.getElementsByClassName("padre_"+padre);
			for (var i = 0; i < hijos.length; ++i) {
					hijos[i].style.display = "none";
					ocultarHijo(padre+"_"+hijos[i].textContent.trim());
			}
		}	

		function validaFormulario(formulario) {
			var resultado = true;
			var seleccionadoElemento = false;
			var elemento = document.getElementsByTagName("input");
			for (var i = 0; i < elemento.length; i++) {
			  	if(elemento[i].type == "checkbox") {
		  			if(elemento[i].checked){
		  				seleccionadoElemento = true;
		  			}
				} 
		  	}
		  	if(!seleccionadoElemento){
		  		var borrarSeleccion = document.createElement("input"); 
			    borrarSeleccion.value = true;
    			borrarSeleccion.name = "borrar";
    			borrarSeleccion.style.display = "none";
    			formulario.appendChild(borrarSeleccion); 
		  	}else{			 	
			 	var particioneseleccionado = false;
			  	var particiones = document.getElementsByName("particionNombre[]");
				for (var i = 0; i < particiones.length; i++) {
				  	if(particiones[i].type == "checkbox") {
			  			if(particiones[i].checked){
							particioneseleccionado = true;
						}
					} 
			  	}
				
			  	if(!particioneseleccionado){
			  		alert("<?=$TbMsg[7];?>");
			  		return false;
			  	}

			  	if(document.getElementsByName("carpetaDestino")[0].value == ""){
			  		alert("<?=$TbMsg[8];?>");
			  		return false;
			  	}
		  	}
		  return resultado;
		}

		function borrarSeleccion() {
		  var elementoResetear = document.getElementsByTagName("input");
		  for (var i = 0; i < elementoResetear.length; i++) {
		  	if(elementoResetear[i].type == "checkbox") {
	      	  elementoResetear[i].checked = false; 
	    	} 
		  }
		}
		
		function seleccionarPadre(elemento) {
			var clases = elemento.className.split(" ");
			clases.shift();
			

			while((clasePadre=clases.pop()) != null){ 
			    var elementosSeleccionable = document.getElementsByTagName("input");
				for (var i = 0; i < elementosSeleccionable.length; i++){
			  		if(elementosSeleccionable[i].name == "directorio[]" && clasePadre == elementosSeleccionable[i].value) {
			  			var hijos = document.getElementsByClassName(elementosSeleccionable[i].value);
			  			var seleccionadoTodo = true;
			  			var noSeleccionado = 0;
			  			for (var j = 0; j < hijos.length; j++) {
					  		if(hijos[j].type == "checkbox" && !hijos[j].checked ) {
				      		  seleccionadoTodo = false;
				      		  noSeleccionado++; 
				    		} 
						 }
		      			elementosSeleccionable[i].checked = elemento.checked;
		      			elementosSeleccionable[i].indeterminate = !seleccionadoTodo; 
		      			if (hijos.length == noSeleccionado) {
		      				elementosSeleccionable[i].indeterminate = false;
		      			}
		    		} 
		  		}

			}
		
	     }
		</script>
	<p align=center><span align=center class=cabeceras><?=$TbMsg[2];?></span></p>
		</br>
	<form class="formulariodatos" method="post" onsubmit="return  validaFormulario(this);" 
		action="<?php echo $_SERVER['PHP_SELF']; ?>">
		<div class="archivos" align="center" >
		<?php 
			obtener_estructura_directorios($directorio_relativo_ficheros);
		?>
		</div>
		<div class="botones" align="center">

			<div class="Particiones" align="center">
			<p align=center><span align=center class=subcabeceras><?=$TbMsg[10];?></span></p>
			</br>
			<?php 
			 foreach ($mapeoParticiones as $key => $value) {
		 		echo "
		 		<alt>
		 		<input type=\"checkbox\" name=\"particionNombre[]\" value=\"$key\" id=\"$key\"";

		 		if (in_array($key, $particionesUltimaSeleccion)) {
		 			echo "checked";
		 		}

		 		echo " ></input>
		 		<label for=\"$key\" >$key</label>
		 		</alt>";
			 }

			?>
			</div>	
		<br>
		
		<?=$TbMsg[9];?> <input type="text" name="carpetaDestino" value="<?=$carpetaDestino;?>"><br>	
		<br>
		<input type="button" onclick="borrarSeleccion()" value="<?=$TbMsg[4];?>" >
		<input type="submit" value="<?=$TbMsg[5];?>" >
		<input type="button" value="<?=$TbMsg[6];?>" onclick="window.close()">
		</div>
	</form>

	<script type="text/javascript">
		
		var elementosComprobarPadre = document.getElementsByClassName("archivos")[0].getElementsByTagName("input");
		for (var i = 0; i < elementosComprobarPadre.length; i++) {
			  seleccionarPadre(elementosComprobarPadre[i]);
		  	}
	</script>
	</body>
	</html>

