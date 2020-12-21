	<?php
	function añadirOpcionGestionAvanzada($TbMsg){
		echo '<TD onclick="'.añadirDespliegueOpciones('gestion_avanzada').'" onmouseout=desresaltar(this) onmouseover=resaltar(this) align=middle style="white-space: nowrap;">
				<A style="text-decoration: none"><SPAN class=menupral >'.$TbMsg[17].'</SPAN></A>
			<span>
			</TD>
			<TD width=4 align=middle><IMG src="./images/iconos/separitem.gif"></TD>
			<TD class="gestion_avanzada_desplazamiento desplazamiento_izquierda"  onclick="'.añadirDesplazamientoIzquierda('gestion_avanzada').'" onmouseout=desresaltar(this) onmouseover=resaltar(this) align=middle style="display:none;  white-space: nowrap;">
				⇦</span>
			</TD>
			<TD class="gestion_avanzada" onmouseout=desresaltar(this) onmouseover=resaltar(this) align=middle style="display:none;  white-space: nowrap;">
				<a style="text-decoration: none" href="http://'.$_SERVER['HTTP_HOST'].':8080/guacamole" target="_blank"><span>'.$TbMsg[18].'</a></span>
			</TD>
			<TD class="gestion_avanzada" onmouseout=desresaltar(this) onmouseover=resaltar(this) align=middle style="display:none;  white-space: nowrap;">
				<a style="text-decoration: none" href="./personalizado/sincronizacion_guacamole.php" target="frame_contenidos"><span>'.$TbMsg[19].'</a></span>
			</TD>
			<TD class="gestion_avanzada" onmouseout=desresaltar(this) onmouseover=resaltar(this) align=middle style="display:none;  white-space: nowrap;">
				<a style="text-decoration: none" href="./personalizado/gestor_fichero.php" target="_blank"><span>'.$TbMsg[20].'</a></span>
			</TD>
			<TD class="gestion_avanzada" onmouseout=desresaltar(this) onmouseover=resaltar(this) align=middle style="display:none;  white-space: nowrap;">
				<a style="text-decoration: none" href="./personalizado/pagina_gestion_switch.php" target="frame_contenidos"><span>'.$TbMsg[22].'</a></span>
			</TD>
			<TD class="gestion_avanzada_desplazamiento desplazamiento_derecha" onclick="'.añadirDesplazamientoDerecha('gestion_avanzada').'" onmouseout=desresaltar(this) onmouseover=resaltar(this) align=middle style="display:none;  white-space: nowrap;">
				⇨</span>	
			<script language="javascript">
				var opcion_mostrar = 0;
			</script>
			';
	}

	function añadirDespliegueOpciones($clase_deplegable){

		return "var desplegable = document.getElementsByClassName('$clase_deplegable');				
				if(desplegable.length!=null){
				
					if(desplegable[opcion_mostrar].style.display == 'table-cell'){
			          desplegable[opcion_mostrar].style.display = 'none';
			       	}else{
			          desplegable[opcion_mostrar].style.display = 'table-cell';
			   		}
			   		if(desplegable.length > 1){
			   		var desplegable_desplazamiento = document.getElementsByClassName('$clase_deplegable'+'_desplazamiento');
					for (var x = 0; x < desplegable_desplazamiento.length; x++) {
							if(desplegable_desplazamiento[x].style.display == 'table-cell'){
					          desplegable_desplazamiento[x].style.display = 'none';
					       	}else if(x != 0){
					          desplegable_desplazamiento[x].style.display =  desplegable[opcion_mostrar].style.display;
					       	}
					    }
					}
					opcion_mostrar = 0;
				} else{
					if(desplegable.style.display == 'table-cell'){
					desplegable.style.display = 'none';
			       	}else{
			          desplegable.style.display = 'table-cell';
			       	}

				}

			";
	}

	function añadirDesplazamientoIzquierda($clase_deplegable){

		return "var desplegable = document.getElementsByClassName('$clase_deplegable');
				if(desplegable.length!=null){
					if(opcion_mostrar-1 >= 0){
						opcion_mostrar = opcion_mostrar-1;
		          		desplegable[opcion_mostrar].style.display = 'table-cell';
		          		desplegable[opcion_mostrar+1].style.display = 'none';
		          		document.getElementsByClassName('desplazamiento_derecha')[0].style.display = 'table-cell';
					} 
					if(opcion_mostrar <= 0){
						this.style.display = 'none';
					}
				} 
			";
	}

	function añadirDesplazamientoDerecha($clase_deplegable){

		return "var desplegable = document.getElementsByClassName('$clase_deplegable');
				if(desplegable.length!=null){
					if(opcion_mostrar+1 != desplegable.length){
						opcion_mostrar = opcion_mostrar+1;
		          		desplegable[opcion_mostrar].style.display = 'table-cell';
		          		desplegable[opcion_mostrar-1].style.display = 'none';
		          		document.getElementsByClassName('desplazamiento_izquierda')[0].style.display = 'table-cell';
		          		if(opcion_mostrar+1 >= desplegable.length) {
							this.style.display = 'none';
						}
					} 
				} 
			";
	}
	?>