
function selectAll(nombreTabla,checkbox) {
	var filas = document.getElementById(nombreTabla).rows;
	if(filas.length!=null){
		for (var i = 1; i < filas.length; i++) {
			filas[i].getElementsByTagName("input")[0].checked = checkbox.checked;
		}
	} else{
		filas.getElementsByTagName("input")[0].checked = checked;
	}
}

var valueSelectAllTables = false;
function selectAllTables(checkbox) {
	valueSelectAllTables = !valueSelectAllTables;
	var checkboxs = document.getElementsByTagName('input');
	for (var i = 0; i < checkboxs.length; i++) {
	  if (checkboxs[i].type == "checkbox") {
	    checkboxs[i].checked = valueSelectAllTables;
	    }
	}
}

function comprobacionSeleccion(tabla){
	var accionArray=[];
	filas = document.getElementById(tabla).rows;
	if(filas.length > 1){
		for (var i = 1; i < filas.length; i++) {
			if(filas[i].getElementsByTagName("input")[0].checked){
				accionArray.push(filas[i]);
			}
		}
	} 
	return accionArray;
}

function añadirAccionConfirm(textoInicial, accionArray){
	var texto = "";
	if (Array.isArray(accionArray) && accionArray.length != 0) {
		texto += textoInicial + "\n";
		 for (var i = 0; i < accionArray.length; i++) {
			texto += "- " + accionArray[i].cells[1].textContent + "\n";	
		}
	}
	return texto;
}

function validateForm() {
	var textoConfirm = "";

	var text_actualizar = "Los equipos a actualizar son";
	var actualizarArray = comprobacionSeleccion('tabla_actualizar');

	var text_crear = "Los equipos a crear son";
	var crearArray = comprobacionSeleccion('tabla_crear');

	var text_eliminar = "Los equipos a eliminar son";
	var eliminarArray = comprobacionSeleccion('tabla_eliminar');

	var text_eliminar_crear = "Los equipos a actualizar parametros son";
	var eliminarCrearArray = comprobacionSeleccion('tabla_eliminar_crear');

	textoConfirm += añadirAccionConfirm(text_actualizar, actualizarArray);
	textoConfirm += añadirAccionConfirm(text_crear, crearArray);
	textoConfirm += añadirAccionConfirm(text_eliminar, eliminarArray);
	textoConfirm += añadirAccionConfirm(text_eliminar_crear, eliminarCrearArray);

	var send = false;
	if(textoConfirm != ""){
		send = window.confirm(textoConfirm);
	}
	
	return send;
}