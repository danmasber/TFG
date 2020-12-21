
var comando = "";
var cerradaVentana = false;
var arraySistemasOpertivosSeleccionado = new Array();

function crearVentanaComando(xhttp, parametros_POST){
	cerradaVentana = true;

	var entrada_comando = window.open("", TbMsg[13], "width=750,height=400"); 
	entrada_comando.document.head.title = TbMsg[13];

	var div = document.createElement("div");
	div.setAttribute("align", "center");

	var titulo = document.createElement("h1");
	titulo.innerHTML = TbMsg[14];

	var textNoUso = document.createElement("p");
	textNoUso.innerHTML= TbMsg[15];
	
	var areaTextoComando = document.createElement("textarea");
	areaTextoComando.name = "Comando";
	areaTextoComando.value = comando;
	areaTextoComando.maxLength = "5000";
	areaTextoComando.cols = "100";
	areaTextoComando.rows = "10";

	var botonEnviarComando = document.createElement("button");
	botonEnviarComando.value = "enviar";
	botonEnviarComando.innerHTML = TbMsg[16];
	
	botonEnviarComando.onclick = function(){	
		comando = areaTextoComando.value;
		var ocurrencia = comando.indexOf("#!");
		var sistemasOperativos = entrada_comando.document.getElementsByName("sistemaOperativo");
		arraySistemasOpertivosSeleccionado.length = 0;
		for (var i = 0; i < sistemasOperativos.length; i++) {
			if(sistemasOperativos[i].checked){
				arraySistemasOpertivosSeleccionado.push(sistemasOperativos[i].value);
			}
		}
		if(ocurrencia == -1 && arraySistemasOpertivosSeleccionado.length != 0){
		  cerradaVentana = false;
		  entrada_comando.close();
		} else if(arraySistemasOpertivosSeleccionado.length == 0) {
			entrada_comando.alert(TbMsg[25]);
		} else {
			entrada_comando.alert(TbMsg[17]);
      cerradaVentana = false;
		  entrada_comando.close();
		}
		
	};

	botonEnviarComando.onmouseover = function() 
	{
	    this.style.backgroundColor = "#555555";
    	this.style.color = "white";
	}

	botonEnviarComando.onmouseout = function() 
	{
	    this.style.backgroundColor = "";
    	this.style.color = "black";
	}

	botonEnviarComando.style.marginTop = "10px";
	botonEnviarComando.style.borderRadius = " 10px";
    botonEnviarComando.style.color = " black";
    botonEnviarComando.style.border = " 2px solid #555555";
    botonEnviarComando.style.border = " none";
    botonEnviarComando.style.padding = " 4px 8px";
    botonEnviarComando.style.textAlign = " center";
    botonEnviarComando.style.textDecoration = " none";
    botonEnviarComando.style.display = " inline-block";
    botonEnviarComando.style.margin = " 4px 2px";
    botonEnviarComando.style.transitionDuration = " 0.4s";
    botonEnviarComando.style.cursor = " pointer";

    var parrafoBotonEnviarComando = document.createElement("p");
    parrafoBotonEnviarComando.appendChild(botonEnviarComando);
    
    var tituloSistemaOperativo = document.createElement("h3");
	tituloSistemaOperativo.innerHTML = TbMsg[26];

    div.appendChild(titulo);
	div.appendChild(areaTextoComando); 
	div.appendChild(parrafoBotonEnviarComando); 
	div.appendChild(textNoUso); 
	div.appendChild(tituloSistemaOperativo);

	for (var key in mapeoParticiones){
	    var sistemasOperativoCheckbox = document.createElement("input");
	    sistemasOperativoCheckbox.type = "checkbox";
	    sistemasOperativoCheckbox.name = "sistemaOperativo"; 
		sistemasOperativoCheckbox.value =  key;
		sistemasOperativoCheckbox.id = key;
		sistemasOperativoCheckbox.style.display = "none";

		var sistemasOperativoLabel = document.createElement("label");
		sistemasOperativoLabel.htmlFor = key;
		sistemasOperativoLabel.innerHTML = key;
		sistemasOperativoLabel.style.background = "#DDDDDD";
		sistemasOperativoLabel.style.marginTop = "10px";
		sistemasOperativoLabel.style.borderRadius = " 10px";
	    sistemasOperativoLabel.style.padding = " 4px 8px";
	    sistemasOperativoLabel.style.textAlign = " center";
	    sistemasOperativoLabel.style.margin = " 4px 2px";
	    sistemasOperativoLabel.style.transitionDuration = " 0.4s";

	    if (arraySistemasOpertivosSeleccionado.includes(key)) {
			sistemasOperativoCheckbox.checked = true;
			sistemasOperativoLabel.style.backgroundColor = "#555555";
    		sistemasOperativoLabel.style.color = "white";
		}

	    sistemasOperativoCheckbox.onclick = function(){
	    	if (this.checked) {
	    		this.nextElementSibling.style.backgroundColor = "#555555";
    			this.nextElementSibling.style.color = "white";
	    	} else {
	    		this.nextElementSibling.style.backgroundColor = "#DDDDDD";
    			this.nextElementSibling.style.color = "";
	    	}
	    
		}

		div.appendChild(sistemasOperativoCheckbox); 
		div.appendChild(sistemasOperativoLabel); 
	}	

	entrada_comando.document.body.appendChild(div);
	
	var timer = setInterval(function (){
        if (entrada_comando.closed)
        {
            clearInterval(timer);
            if(!cerradaVentana){
              xhttp.send(parametros_POST);
            }
           
        }
    }, 500);

}

function isEmpty(str) {
    return (!str || 0 === str.trim(str).length);
}

function resultado_comando(result){
	alert("- " + result.split("_")[0] + "\n"+ CTbMsg_comando[result.split("_")[1]] + "\n");	
}

function resultado_procedimiento(result){
	alert("- " + result.split("_")[0] + "\n"+ result.split("_")[1] + "\n");	
}

function pulsadoAccion(nombre,actual) {
	var checkbox_acciones = [];
	checkbox_acciones.push(document.getElementById(nombre+'_encendido'));
	checkbox_acciones.push(document.getElementById(nombre+'_apagado'));
	checkbox_acciones.push(document.getElementById(nombre+'_enviarArchivos'));
	checkbox_acciones.push(document.getElementById(nombre+'_enviarComando'));
	checkbox_acciones.push(document.getElementById(nombre+'_enviarProcedimiento'));
	checkbox_filtrado = checkbox_acciones.filter(function (item) {
			  return item !== actual;
			}); 
	if (actual.checked) {
		checkbox_filtrado.forEach(function(checkbox) {
			  checkbox.checked = false;
			});
	} 
}

function seleccionarAccionTodos(nombre){
	var selectElement =  document.getElementsByName("accion_"+nombre)[0];
	var accionSelecionada= selectElement.options[selectElement.selectedIndex].value;
	
	var formulario = document.forms[nombre];
	var botonesAccionSelecionada = formulario[accionSelecionada];
	if(botonesAccionSelecionada.length!=null){
		for (var i = 0; i < botonesAccionSelecionada.length; i++) {
			botonesAccionSelecionada[i].click();
			botonesAccionSelecionada[i].checked = true;
		}
	} else{
		botonesAccionSelecionada.click();
		botonesAccionSelecionada.checked = true;
	}	

}

function ocultarOpciones(nombre){
	var opciones =  document.forms[nombre].getElementsByClassName("opciones");
	for (var i = 0; i < opciones.length; i++) {
			if(opciones[i].style.display != "none"){
				opciones[i].style.display = "none";
			} else{
				opciones[i].style.display = "";
			}
	}
	
}

function comando_request(cadena) {
	 var cadenaArray = cadena.split("_");
	 var peticion = null;
	 var url = "";
	 switch(cadenaArray[0]) {
 	 case "encender":
	   url = "../comandos/gestores/gestor_Comandos.php";
	   peticion = {
		'idcomando':1,
		'descricomando':"Arrancar",
		'ambito':cadenaArray[1],
		'idambito':cadenaArray[2], //Es el id del PC en el ambito Aula
		'funcion':"Arrancar",
	    'atributos':"mar=1@",
		'gestor':"../comandos/gestores/gestor_Comandos.php",
    	'filtro':"",
    	'sw_ejya':"on",
		'sw_seguimiento':1,
    	'nombreprocedimiento':"",
    	'idprocedimiento':0,
    	'ordprocedimiento':"",
    	'nombretarea':"",
    	'idtarea':0,
    	'ordtarea':"",
		}; 
    break;
  	case "apagar":
  	  url = "../comandos/gestores/gestor_Comandos.php";
      peticion = {
		'idcomando':2,
		'descricomando':"Apagar",
		'ambito':cadenaArray[1],
		'idambito':cadenaArray[2], //Es el id del PC en el ambito Aula
		'funcion':"Apagar",
	    'atributos':"",
		'gestor':"../comandos/gestores/gestor_Comandos.php",
    	'filtro':"",
    	'sw_ejya':"on",
		'sw_seguimiento':1,
    	'nombreprocedimiento':"",
    	'idprocedimiento':0,
    	'ordprocedimiento':"",
    	'nombretarea':"",
    	'idtarea':0,
    	'ordtarea':"",
    	};
    break;
    case "enviarArchivos":
      	url = "../comandos/gestores/gestor_Comandos.php";
	  	var RC='@';
	  	var comandoEscapado="scp="+escape(encodeURIComponent(cadenaArray[4])+"\n"+"\n")+RC;
  		peticion = { 
			'idcomando':8,
			'descricomando':"Ejecutar Script",
			'ambito':cadenaArray[1],
			'idambito':cadenaArray[2], //Es el id del PC en el ambito Aula
			'funcion':"EjecutarScript",
			'atributos':comandoEscapado,
			'gestor':"../comandos/gestores/gestor_Comandos.php",
			'filtro':"",
			'sw_ejya':"on",
			'sw_seguimiento':1,
			'nombreprocedimiento':"",
			'idprocedimiento':0,
			'ordprocedimiento':"",
			'nombretarea':"",
			'idtarea':0,
			'ordtarea':"",
			'modoejecucion' : false,
		};	
    break;
 	case "enviarComando":
 	  enviarComandoRequest(cadenaArray);
 	break;
 	case "enviarProcedimiento":
      url = "../gestores/gestor_ejecutaracciones.php"; 
      peticion = {
      	'opcion': 2,
		'ambito':cadenaArray[1],
		'idambito':cadenaArray[2], //Es el id del PC en el ambito Aula
		'idprocedimiento': cadenaArray[5],
		'descriprocedimiento': cadenaArray[4].replace("*barraBaja*", "_"),
    	};
    break;
  default:
   break;
}
   if(peticion != null){
   	var xhttp = new XMLHttpRequest();
		xhttp.onreadystatechange = function(data) {
			if (this.readyState == 4 && this.status == 200) {
				result = data.target.responseText;
				var match = result.match(/resultado_comando\((\d+)\)/);
				//Solo informamos si ocurre algun error
				if(match != null && match[1] != 2){
						resultado_comando(cadenaArray[3]+ "_" + match[1]);
				}
				var match = result.match(/resultado_gestion_procedimiento\(\d+,\'(.*?)\'\)/);
				if(match != null){
					resultado_procedimiento(cadenaArray[3]+ "_" + match[1]);
				} else if (this.readyState == 4 && this.status != 200){
					alert("- " + cadenaArray[3] + "\n" +TbMsg[27]);
				}		
				
		    }
		};
		var parametros ="";
		for (var clave in peticion) {
  			parametros += clave + "=" + peticion[clave] + "&";
		}
		parametros = parametros.slice(0,-1);
		xhttp.open("POST", url , true);
		xhttp.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
		xhttp.send(parametros);
		//Necesario para que no se lie el servidor y crea que la peticion es para otro ordenador
		sleep(1000);
   }
}

function enviarComandoRequest(cadenaArray) {
	var peticion = null;
	  url = "../comandos/gestores/gestor_Comandos.php";
	  var RC='@';
	  if (comando != "") {
	  	for (var i = 0; i < arraySistemasOpertivosSeleccionado.length; i++) {
	  		var comentario = mapeoParticiones[arraySistemasOpertivosSeleccionado[i]]['comentario'] 
	  			+ "Comando para ejecutar en " + arraySistemasOpertivosSeleccionado[i];
	  		var comandoConComprobacion =  mapeoParticiones[arraySistemasOpertivosSeleccionado[i]]['comprobacion'].replace(/\*comando\*/g, comando);
	  		var comandoConComprobacionYComentario = "";
	  		if (mapeoParticiones[arraySistemasOpertivosSeleccionado[i]]['lugarComentario'] == "principio") {
	  			comandoConComprobacionYComentario = comentario + "\n" + comandoConComprobacion;
	  		}
	  		if (mapeoParticiones[arraySistemasOpertivosSeleccionado[i]]['lugarComentario'] == "fin") {
	  			comandoConComprobacionYComentario = comandoConComprobacion + "\n" + comentario;
	  		}
	  		var comandoEscapado="scp="+escape(encodeURIComponent(comandoConComprobacionYComentario)+"\n"+"\n")+RC;
		  	var peticionComando = { 
	 			'idcomando':8,
				'descricomando':"Ejecutar Script",
				'ambito':cadenaArray[1],
				'idambito':cadenaArray[2], //Es el id del PC en el ambito Aula
				'funcion':"EjecutarScript",
				'atributos':comandoEscapado,
				'gestor':"../comandos/gestores/gestor_Comandos.php",
				'filtro':"",
				'sw_ejya':"on",
				'sw_seguimiento':1,
				'nombreprocedimiento':"",
				'idprocedimiento':0,
				'ordprocedimiento':"",
				'nombretarea':"",
				'idtarea':0,
				'ordtarea':"",
				'modoejecucion' : false,
			};	
			var xhttp = new XMLHttpRequest();
			xhttp.onreadystatechange = function(data) {
				if (this.readyState == 4 && this.status == 200) {
					result = data.target.responseText;
					var match = result.match(/resultado_comando\((\d+)\)/);
					//Solo informamos si ocurre algun error
					if(match != null && match[1] != 2){
						resultado_comando(cadenaArray[3]+ "_" + match[1]);
					}
					var match = result.match(/resultado_gestion_procedimiento\(\d+,\'(.*?)\'\)/);
					if(match != null){
						resultado_procedimiento(cadenaArray[3]+ "_" + match[1]);
					}

					
			    } else if (this.readyState == 4 && this.status != 200){
					alert("- " + cadenaArray[3] + "\n" +TbMsg[27]);
				}
			};
			var parametros ="";
			for (var clave in peticionComando) {
	  			parametros += clave + "=" + peticionComando[clave] + "&";
			}
			parametros = parametros.slice(0,-1);
			xhttp.open("POST", url , true);
			xhttp.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
			xhttp.send(parametros);
			//Necesario para que no se lie el servidor y crea que la peticion es para otro ordenador
			sleep(1000);
	  	}
	  	
	  } else {
	  	alert(TbMsg[18]);
	  }
   
}

function sleep(delay) {
        var start = new Date().getTime();
        while (new Date().getTime() < start + delay);
      }
	
function comprobacionSeleccion(formulario, accion){
	var accionArray=[];
	var elementosAccion = formulario[accion];
	if(elementosAccion.length!=null){
		for (var i = 0; i < elementosAccion.length; i++) {
			if (elementosAccion[i].checked) {
			accionArray.push(elementosAccion[i].value);
			}
		}
	} else{
		if (elementosAccion.checked) {
			accionArray.push(elementosAccion.value);
		}
	}

	return accionArray;
}

function añadirAccionConfirm(textoInicial, accionArray){
	var texto = "";
	if (Array.isArray(accionArray) && accionArray.length != 0) {
		texto += textoInicial + "\n";
		 for (var i = 0; i < accionArray.length; i++) {
			texto += "- " + accionArray[i].split("_")[0] + "\n";	
		}
	}
	return texto;
}

function enviarDatos(ambito, idambito, formulario){
	var textoConfirm = "";

	var textoConfirmApagar = TbMsg[19];
	var apagarArray = comprobacionSeleccion(formulario, "apagar");
	
	var textoConfirmEncender = TbMsg[20];
	var encederArray=comprobacionSeleccion(formulario, "encender");
	
	var textoConfirmEnviarArchivos = TbMsg[21];
	var enviarArchivosArray=comprobacionSeleccion(formulario, "enviarArchivos");
	
	var textoConfirmEnviarComando = TbMsg[22];
	var enviarComandoArray=comprobacionSeleccion(formulario, "enviarComando");
	
	var textoConfirmEnviarProcedimiento = TbMsg[23];
	var enviarProcedimientoArray=comprobacionSeleccion(formulario, "enviarProcedimiento");

	textoConfirm += añadirAccionConfirm(textoConfirmEncender, encederArray);
	textoConfirm += añadirAccionConfirm(textoConfirmApagar, apagarArray);
	textoConfirm += añadirAccionConfirm(textoConfirmEnviarArchivos, enviarArchivosArray);
	textoConfirm += añadirAccionConfirm(textoConfirmEnviarComando,enviarComandoArray);
	textoConfirm += añadirAccionConfirm(textoConfirmEnviarProcedimiento,enviarProcedimientoArray);
	
	var procedimientoSeleccionado = formulario["procedimiento"].options[formulario["procedimiento"].selectedIndex].value;
	var procedimientoDescripcionSeleccionado = formulario["procedimiento"].options[formulario["procedimiento"].selectedIndex].innerHTML;
	if(procedimientoSeleccionado == "" && Array.isArray(enviarProcedimientoArray) && enviarProcedimientoArray.length != 0){
		alert(TbMsg[24]);
		return false;
	} else if(Array.isArray(enviarProcedimientoArray) && enviarProcedimientoArray.length == 0){
		procedimientoSeleccionado = "";
		procedimientoDescripcionSeleccionado="";
	}

	var aceptadoEnvio = false;
	if(textoConfirm != ""){
		aceptadoEnvio = window.confirm(textoConfirm);
	}
	
	if(aceptadoEnvio){
		var xhttp = new XMLHttpRequest();

		xhttp.onreadystatechange = function(data) {
			if (this.readyState == 4 && this.status == 200) {
				resultado = data.target.responseText;
				if(!isEmpty(resultado)){
					resultadoArray = resultado.trim(resultado).split(",");
					for (var i = 0; i < resultadoArray.length; i++) {
						comando_request(resultadoArray[i]);
					}
				}
		    }
		};

		var parametros_POST="encender="+JSON.stringify(encederArray)
				+"&apagar="+JSON.stringify(apagarArray)
				+"&enviarArchivos="+JSON.stringify(enviarArchivosArray)
				+"&enviarComando="+JSON.stringify(enviarComandoArray)
				+"&enviarProcedimiento="+JSON.stringify(enviarProcedimientoArray)
				+"&idambito="+idambito
				+"&ambito="+ambito;
		if(procedimientoSeleccionado != ""){
			parametros_POST += "&idProcedimientoEnviar="+procedimientoSeleccionado;
			parametros_POST += "&descripcionProcedimientoEnviar="+procedimientoDescripcionSeleccionado;
		}		

		xhttp.open("POST", "../personalizado/capturador_opciones_modificacion_aula.php", true);
		xhttp.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
		
		if(Array.isArray(enviarComandoArray) && enviarComandoArray.length != 0){
			crearVentanaComando(xhttp,parametros_POST);	
		} else {
			xhttp.send(parametros_POST);
		}
		
		formulario.reset()
	}

}

