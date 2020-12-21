<?php
// *************************************************************************************************************************************************
include_once("../includes/ctrlacc.php");
// *************************************************************************************************************************************************

?>

<HTML>
	<HEAD>
		<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
		<LINK rel="stylesheet" type="text/css" href="../estilos.css">
		<style type="text/css">
			#volver{
				display: none;
				position: fixed;
			    bottom: 3rem;
			    right: 3rem;
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
			    background-color: #55555552;
			}

			#volver:hover {
			    background-color: #555555;
			    color: white;
			}

			#indice  a {
				color: inherit;
			}

			#indice li , #indice ul {
 				list-style: none;
			}

			.tituloNivel1{
			    color: #999999;
			    font-family: Verdana;
			    font-size: 24px;
				font-weight: 600;
			}
			.tituloNivel2{
				color: #D6A621;
			    font-family: Verdana;
			    font-size: 20px;
			}

			.tituloNivel3 {
				color:#7575DD; 
				font-family: Arial;
				font-size: 18px;
				font-weight: 400;
			}

			.tabla_datos {
				background-color: #B5DAAD;
				font-family: Courier New, Courier;
			}

			.tabla_comando{
				background-color: #EEEECC;
				font-family: Courier New, Courier;
				width: 566px;
			}

		</style>
	</HEAD>
<BODY OnContextMenu="return false">
	<script type="text/javascript">
		document.body.onscroll = function() {funcionScroll()};
		window.onload = function() {
			funcionScroll();
			crearIndiceAutomatico();
			aniadirEstilo();
		};

		function funcionScroll() {
		  if (document.body.scrollTop > 50) {
		    document.getElementById("volver").style.display = "";
		  } else {
		    document.getElementById("volver").style.display = "none";
		  }
		}

		function aniadirEstilo() {			
			titulos = Array.from(container.querySelectorAll("h1, h2, h3"));
			for (var i = titulos.length - 1; i >= 0; i--) {
				if(titulos[i].tagName== "H1"){
					titulos[i].className = "tituloNivel1";
				} else if(titulos[i].tagName== "H2"){
					titulos[i].className = "tituloNivel2";
				} else {
					titulos[i].className = "tituloNivel3";
				}
				
			}

		}

		
		function crearIndiceAutomatico(){

			container = document.querySelector("#contenido");

			table = document.getElementById("indice");
			titulos = Array.from(container.querySelectorAll("h1, h2, h3"));
			ultimaCabecera = new Array(6);	
			ultimaCabecera[0] = table;

			for (var i = 0; i < titulos.length; i++) {

				titulo = titulos[i];
				numeroDeCabecera = parseInt(titulo.tagName.slice(1));
				titulo.setAttribute("id", 'title-' + i);
				
				nodo = document.createElement("li");                 
				link = document.createElement("a");
				textoDeLink = document.createTextNode(titulo.textContent);
				link.appendChild(textoDeLink);
				link.setAttribute("href", '#title-' + i);
				nodo.appendChild(link);
				
				if(titulo.tagName== "H1"){
					nodo.className = "tituloNivel1";
				} else if(titulo.tagName== "H2"){
					nodo.className = "tituloNivel2";
				} else{
					nodo.className = "tituloNivel3";
				}
				nodo.style = " font-size: 1em;"
				if(ultimaCabecera[numeroDeCabecera] == null){
					ultimaCabecera[numeroDeCabecera] = nodo;
					nodoPadre = null;
					var cabeceraPadre = 0;
					for (var j = numeroDeCabecera - 1 ; j >= 0 && nodoPadre == null; j--) {
						if (ultimaCabecera[j] != null) {
							nodoPadre = ultimaCabecera[j];
							cabeceraPadre = j;
						}
					}
				} else{
					nodoPadre = ultimaCabecera[numeroDeCabecera].parentElement;
					ultimaCabecera[numeroDeCabecera] = nodo;
				}
				
				for (var j = numeroDeCabecera + 1 ; j < ultimaCabecera.length; j++) {
					ultimaCabecera[j] = null;
				}

				if (numeroDeCabecera != 1) {
					ultimoNodeDelMultiNivel = nodoPadre;
					if (nodoPadre.tagName == "UL") {
						ultimoNodeDelMultiNivel.appendChild(nodo);
					} else{
						for (var j = cabeceraPadre; j < numeroDeCabecera ; j++) {
							nuevoNode = document.createElement("ul");
							ultimoNodeDelMultiNivel.appendChild(nuevoNode);
							ultimoNodeDelMultiNivel = nuevoNode;
						}
						ultimoNodeDelMultiNivel.appendChild(nodo);
					}
				} else  {
					nodoPadre.appendChild(nodo);
				}
			}
		}
		

	

	</script>

	<p align=center><span align=center class=cabeceras>P&aacute;gina de gesti&oacute;n de switch</span></p>
	<h1 class=subcabeceras>&Iacute;ndice</h1>
	<ol id="indice" class=subcabeceras></ol>
	<div id="contenido">
	<h1>
    	1. Script para la gesti&oacute;n de switch basado en el uso de minicom
	</h1>
	<p>
	    Todos los scripts tienen valores por defectos para aquellos valores que no
	    son contrase&ntilde;a del administrador ni usuario del administrador y se pueden
	    modificar al inicio del script para no pasar todos los par&aacute;metros al script
	</p>
	<h2>
	    1.1. Requisitos para usar script con minicom
	</h2>
	<p>
	    Para hacer uso de los scripts se ejecutar desde &eacute;l la cuenta de
	    superusuario.<u></u>
	</p>
	<p>
	    Debe estar instalado
	</p>
	<ul>
	    <li>
	        Minicom
	    </li>
	    <li>
	        Sx
	    </li>
	    <li>
	        Rx
	    </li>
	    <li>
	        sed
	    </li>
	</ul>
	<p>
	    Debe tener conexi&oacute;n mediante puerto serie, conocer el dispositivo
	    /dev/ttySX asociada a la conexi&oacute;n y la velocidad de baud a la que se
	    encuentra configurada la conexi&oacute;n serie el switch.
	</p>
	<p>
	    Adem&aacute;s, para el uso de los scripts para los switch de Cisco se necesita
	    tener instalado:
	</p>
	<ul>
	    <li>
	        Ip
	    </li>
	    <li>
	        in.tftp o tfpd-hpa y activado
	    </li>
	</ul>
	<p>
	    Y se debe tener conexi&oacute;n mediante un cable ethernet que conecte
	    directamente el PC con la conexi&oacute;n serie con el switch.
	</p>
	<h2>
	    1.2. Switch Cisco 3750G-24TS
	</h2>
	<p>
	    Se dispone de seis scripts que usan el programa minicom junto a su funci&oacute;n
	    de script para guiar seis procesos:
	</p>
	<ul>
		<li>
			scriptBackupConfiguration.sh que permite realizar copiar de la configuraci&oacute;n actual del switch.
		</li>
		<li>
			scriptLoadConfiguration.sh que permite cargar una configuraci&oacute;n al switch
		</li>
		<li>
			scriptUpgrade.sh que permite actualizar el firmware del switch.
		</li>
		<li>
			scriptDisableDHCP.sh que deshabilitara el servicio de DHCP..
		</li>
		<li>
			scriptEnableDHCP.sh que habilitara el servicio de DHCP
		</li>
	    <li>
	    	scriptEnableManagementWeb.sh que habilitara la web de gesti&oacute;n.
	    </li>	
	</ul>
	</p>
	<p>
	    La ubicaci&oacute;n es UBICACI&oacute;N
	</p>
	<p>
	    La contrase&ntilde;a que se puede pasar a los scripts es aquella configurada para
	    habilitar los privilegios mediante la ejecuci&oacute;n del comando
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    enable
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<h3>
	    1.2.1. scriptBackupConfiguration.sh
	</h3>
	<ul>
		<li>
		    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
		</li>
		<li>
		    -f backupConfiguracion: Indica el fichero de configuraci&oacute;n donde se
		    almacenar&aacute; el backup
		</li>
		<li>
		    -t tty_serie: Indica el TTY donde est&aacute; ubicado la conexi&oacute;n por puerto
		    serie al switch
		</li>
		<li>
		    -b baudRescue: Indica los baud con los cuales se ha iniciado el switch en
		    modo rescue
		</li>
		<li>
		    -r: Indica si se inicia el proceso desde modo rescue
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
		<li>
		    -d directorioServidorTftp: Indica la ruta del directorio del servidor
		    TFTP
		</li>
		<li>
		    -P puertoSwitch: Indica el puerto ethernet del switch que se usar&aacute; para
		    conectar mediante tftp
		</li>
		<li>
		    -i intefazRedEthernet: Indica la interfaz Ethernet del PC que usaremos
		    para conector con el switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado har&aacute; uso de sed para generar los scripts necesarios a
	    partir de los archivos *.template en la carpeta MinicomScripts para poder
	    ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<p>
	    Este script creara en el ordenador donde se ejecute un IP virtual que se
	    usara junto a la IP que se creara en el switch para descargar mediante TFTP
	    la configuraci&oacute;n actual. Estas se eliminar&aacute;n tras realizar la copia.
	</p>
	<h3>
	    1.2.2. scriptLoadConfiguration.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
	    <li>
	        -f ficheroConfiguration: Indica el fichero de configuraci&oacute;n que se
	        usara
	    </li>
		<li>
		    -t tty_serie: Indica el TTY donde est&aacute; ubicado la conexi&oacute;n por puerto
		    serie al switch
		</li>
		<li>
		    -b baudRescue: Indica los baud con los cuales se ha iniciado el switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado har&aacute; uso de sed para generar los scripts necesarios a
	    partir de los archivos *.template en la carpeta MinicomScripts para poder
	    ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<p>
	    Al finalizar reiniciara el switch con la configuraci&oacute;n indicado
	</p>
	<h3>
	    1.2.3. scriptUpgrade.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
	    <li>
	        -f ficheroFirmware: Indica el fichero de firmware que se usara
	    </li>
		<li>
		    -t tty_serie: Indica el TTY donde est&aacute; ubicado la conexi&oacute;n por puerto
		    serie al switch
		</li>
		<li>
		    -b baudRescue: Indica los baud con los cuales se ha iniciado el switch
		</li>
		<li>
		    -d: Indica si se eliminar&aacute; las contrase&ntilde;as y configuraci&oacute;n en el proceso
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado har&aacute; uso de sed para generar los scripts necesarios a
	    partir de los archivos *.template en la carpeta MinicomScripts para poder
	    ejecutar el script con las m&iacute;nimas interacciones posibles.
	</p>
	<p>
	    Durante la ejecuci&oacute;n se le solicitara introducir la localizaci&oacute;n del
	    firmware actual si no estuviera declara la variable BOOT path-list visible
	    con
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    show boot
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Para ello se le mostrara la ejecuci&oacute;n del comando configuraci&oacute;n mostrando
	    la ejecuci&oacute;n del comando
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    dir flash:
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Esto hace que exista una limitaci&oacute;n de que el archivo del firmware se
	    encuentre en la ra&iacute;z de flash
	</p>
	<p>
	    Si se indica que se desea borrar las contrase&ntilde;as y configuraci&oacute;n durante el
	    proceso se le indicara que debe introducir la ubicaci&oacute;n completa de fichero
	    de configuraci&oacute;n mostrando la ejecuci&oacute;n del comando
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    dir flash:
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Y deber&aacute; indicar uno de los archivos que corresponder&aacute; al archivo de
	    configuraci&oacute;n actual.
	</p>
	<p>
	    Se har&aacute; una copia de este fichero con el nombre
	    config_last_delete_password.text por si se quisiera recuperar parte de esta
	    configuraci&oacute;n
	</p>
	<p>
	    Al finalizar y para agilizar la carga de firmware los bauds pasar&aacute;n se
	    pasar&aacute;n a configurar a 115200 y ser reiniciara con la versi&oacute;n de firmware
	    indicada.
	</p>
	<h3>
	    1.2.4. scriptDisableDHCP.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
		<li>
		    -t tty_serie: Indica el TTY donde est&aacute; ubicado la conexi&oacute;n por puerto
		    serie al switch
		</li>
		<li>
		    -b baudRescue: Indica los baud con los cuales se ha iniciado el switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado har&aacute; uso de sed para generar los scripts necesarios a
	    partir de los archivos *.template en la carpeta MinicomScripts para poder
	    ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<h3>
	    1.2.5. scriptEnableDHCP.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
		<li>
		    -t tty_serie: Indica el TTY donde est&aacute; ubicado la conexi&oacute;n por puerto
		    serie al switch
		</li>
		<li>
		    -b baudRescue: Indica los baud con los cuales se ha iniciado el switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado har&aacute; uso de sed para generar los scripts necesarios a
	    partir de los archivos *.template en la carpeta MinicomScripts para poder
	    ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<h3>
	    1.2.6. scriptEnableManagementWeb.sh
	</h3>
	<ul>
		<li>
		    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
		</li>
		<li>
		    -t tty_serie: Indica el TTY donde est&aacute; ubicado la conexi&oacute;n por puerto
		    serie al switch
		</li>
		<li>
		    -b baudRescue: Indica los baud con los cuales se ha iniciado el switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado har&aacute; uso de sed para generar los scripts necesarios a
	    partir de los archivos *.template en la carpeta MinicomScripts para poder
	    ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<h2>
	    1.3. Switch HP 2620-25 o 2650-25
	</h2>
	<p>
	    Se dispone de seis scripts que usan el programa minicom junto a su funci&oacute;n
	    de script para guiar seis procesos:
	</p>
	<ul>
		<li>
		   scriptBackupConfiguration.sh que permite realizar copiar de la configuraci&oacute;n actual del switch.
		</li>
		<li>
		    scriptLoadConfiguration.sh que permite cargar una configuraci&oacute;n al switch
		</li>
		<li>
		    scriptUpgrade.sh que permite actualizar el firmware del switch.
		</li>
		<li>
		    scriptDisableDHCP.sh que deshabilitara el servicio de DHCP.
		</li>
		<li>
		    scriptEnableDHCP.sh que habilitara el servicio de DHCP.
		</li>
		<li>
		    scriptEnableManagementWeb.sh que habilitara la web de gesti&oacute;n.
		</li>
	</ul>
	<p>
	    La ubicaci&oacute;n es UBICACION
	</p>
	<h3>
	    1.3.1. scriptBackupConfiguration.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
		<li>
		    -f backupConfiguracion: Indica el fichero de configuraci&oacute;n donde se
		    almacenar&aacute; el backup
		</li>
		<li>
		    -t tty_serie: Indica el TTY donde est&aacute; ubicado la conexi&oacute;n por puerto
		    serie al switch
		</li>
		<li>
		    -b baudIncial: Indica los baud con los cuales se ha iniciado el switch
		</li>
		<li>
		    -u usuario_manager: Indica el usuario del administrador del switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado har&aacute; uso de sed para generar los scripts necesarios a
	    partir de los archivos *.template en la carpeta MinicomScripts para poder
	    ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<h3>
	    1.3.2. scriptLoadConfiguration.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
	    <li>
	        -f ficheroConfiguracion Indica el fichero de configuraci&oacute;n que se
	        cargara
	    </li>
		<li>
		    -t tty_serie: Indica el TTY donde est&aacute; ubicado la conexi&oacute;n por puerto
		    serie al switch
		</li>
		<li>
		    -b baudIncial: Indica los baud con los cuales se ha iniciado el switch
		</li>
		<li>
		    -u usuario_manager: Indica el usuario del administrador del switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager :Indica la contrase&ntilde;a del administrador del switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado har&aacute; uso de sed para generar los scripts necesarios a
	    partir de los archivos *.template en la carpeta MinicomScripts para poder
	    ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<h3>
	    1.3.3. scriptUpgrade.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
		<li>
		    -t ficheroFirmware: Indica el fichero de firmware que se usara
		</li>
		<li>
		    -t tty_serie: Indica el TTY donde est&aacute; ubicado la conexi&oacute;n por puerto
		    serie al switch
		</li>
		<li>
		    -b baudIncial: Indica los baud con los cuales se ha iniciado el switch
		</li>
		<li>
		    -r: Indica que se inicia desde modo Rescue por lo cual no ser&iacute;a necesario
		    ni usuario_manager ni contrasena_manager
		</li>
		<li>
		    -u usuario_manager: Indica el usuario del administrador del switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado har&aacute; uso de sed para generar los scripts necesarios a
	    partir de los archivos *.template en la carpeta MinicomScripts para poder
	    ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<p>
	    Si le pasa como par&aacute;metro -r, indica que el switch ya se encuentra en modo
	    Rescue por lo cual no ser&iacute;a necesario ni el usuario ni la contrase&ntilde;a del
	    administrador.
	    <br/>
	</p>
	<p>
	    Al finalizar y para agilizar la carga de firmware los bauds pasar&aacute;n se
	    pasar&aacute;n a configurar a 115200 y ser reiniciara con la versi&oacute;n de firmware
	    indicada.
	</p>
	<h3>
	    1.3.4. scriptDisableDHCP.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
		<li>
		    -t tty_serie: Indica el TTY donde est&aacute; ubicado la conexi&oacute;n por puerto
		    serie al switch
		</li>
		<li>
		    -b baudIncial: Indica los baud con los cuales se ha iniciado el switch
		</li>
		<li>
		    -u usuario_manager: Indica el usuario del administrador del switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager :Indica la contrase&ntilde;a del administrador del switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado har&aacute; uso de sed para generar los scripts necesarios a
	    partir de los archivos *.template en la carpeta MinicomScripts para poder
	    ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<h3>
	    1.3.5. scriptEnableDHCP.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
		<li>
		    -t tty_serie: Indica el TTY donde est&aacute; ubicado la conexi&oacute;n por puerto
		    serie al switch
		</li>
		<li>
		    -b baudIncial: Indica los baud con los cuales se ha iniciado el switch
		</li>
		<li>
		    -u usuario_manager: Indica el usuario del administrador del switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado har&aacute; uso de sed para generar los scripts necesarios a
	    partir de los archivos *.template en la carpeta MinicomScripts para poder
	    ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<h3>
	    1.3.6. scriptEnableManagementWeb.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
		<li>
		    -t tty_serie: Indica el TTY donde est&aacute; ubicado la conexi&oacute;n por puerto
		    serie al switch
		</li>
		<li>
		    -b baudIncial: Indica los baud con los cuales se ha iniciado el switch
		</li>
		<li>
		    -u usuario_manager: Indica el usuario del administrador del switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado har&aacute; uso de sed para generar los scripts necesarios a
	    partir de los archivos *.template en la carpeta MinicomScripts para poder
	    ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<h1>
	    2. Script para la gesti&oacute;n de switch basado en el uso de ssh
	</h1>
	<p>
	    Todos los scripts tienen valores por defectos para aquellos valores que no
	    son contrase&ntilde;a de administrador, usuario del administrador, direcci&oacute;n IP ni
	    puerto SSH y se pueden modificar al inicio del script para no pasar todos
	    los par&aacute;metros al script
	</p>
	<h2>
	    2.1. Requisitos para usar script con ssh
	</h2>
	<p>
	    Debe est&aacute; instalado
	</p>
	<ul>
	    <li>
	        Expect
	    </li>
	    <li>
	        Ssh
	    </li>
	</ul>
	<p>
	    Se debe tener configurado un usuario con privilegio de administrador y
	    activado tanto ssh como la transferencia mediante este(scp)
	</p>
	<h2>
	    1.1. Switch Cisco 3750G-24TS o Switch HP 2620-25 o 2650-25
	</h2>
	<p>
	    Se dispone de seis scripts que usan el programa Expect y Ssh para guiar
	    seis procesos:
	</p>
	<ul>
		<li>
		    scriptBackupConfiguration.sh que permite realizar copiar de la configuraci&oacute;n actual del switch.
		</li>
		<li>
		    scriptLoadConfiguration.sh que permite cargar una configuraci&oacute;n al switch
		</li>
		<li>
		    scriptUpgrade.sh que permite actualizar el firmware del switch.
		</li>
		<li>
		    scriptDisableDHCP.sh que deshabilitara el servicio de DHCP.
		</li>
		<li>
		    scriptEnableDHCP.sh que habilitara el servicio de DHCP.
		</li>
		<li>
		    scriptEnableManagementWeb.sh que habilitara la web de gesti&oacute;n.
		</li>
	</ul>
	<p>
	    La ubicaci&oacute;n es UBICACI&oacute;N PARA CISCO o UBICACI&oacute;N PARA HP
	</p>
	<h3>
	    1.1.1. scriptBackupConfiguration.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
		<li>
		    -f backupConfiguracion: Indica el fichero de configuraci&oacute;n donde se
		    almacenar&aacute; el Backus
		</li>
		<li>
		    -u usuario_manage: Indica el usuario del administrador del switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
		<li>
		    -H direccion_switch: Indica la direcci&oacute;n del switch
		</li>
		<li>
		    -P puerto_ssh_switch: Indica el puerto ssh configurado en el switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado el comando expect y los scripts en la carpeta
	    ExpectScripts para poder ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<h3>
	    1.1.2. scriptLoadConfiguration.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
		<li>
		    -f ficheroConfiguracion: Indica el fichero de configuraci&oacute;n donde se
		    almacenar&aacute; el backup
		</li>
		<li>
		    -u usuario_manager: Indica el fichero de configuraci&oacute;n que se cargara
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
		<li>
		    -H direccion_switch: Indica la direcci&oacute;n del switch
		</li>
		<li>
		    -P puerto_ssh_switch: Indica el puerto ssh configurado en el switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado el comando expect y los scripts en la carpeta
	    ExpectScripts para poder ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<p>
	    Al finalizar en running-config y running-config estar&aacute; copiado el fichero
	    de configuraci&oacute;n
	</p>
	<h3>
	    1.1.3. scriptUpgrade.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
		<li>
		    -u usuario_manager: Indica el usuario del administrador del switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
		<li>
		    -H direccion_switch: Indica la direcci&oacute;n del switch
		</li>
		<li>
		    -P puerto_ssh_switch: Indica el puerto ssh configurado en el switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado el comando expect y los scripts en la carpeta
	    ExpectScripts para poder ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<h3>
	    1.1.4. scriptDisableDHCP.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
		<li>
		    -u usuario_manager: Indica el usuario del administrador del switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
		<li>
		    -H direccion_switch: Indica la direcci&oacute;n del switch
		</li>
		<li>
		    -P puerto_ssh_switch: Indica el puerto ssh configurado en el switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado el comando expect y los scripts en la carpeta
	    ExpectScripts para poder ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<h3>
	    1.1.5. scriptEnableDHCP.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
		<li>
		    -u usuario_manager: Indica el usuario del administrador del switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
		<li>
		    -H direccion_switch: Indica la direcci&oacute;n del switch
		</li>
		<li>
		    -P puerto_ssh_switch: Indica el puerto ssh configurado en el switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado el comando expect y los scripts en la carpeta
	    ExpectScripts para poder ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<h3>
	    1.1.6. scriptEnableManagementWeb.sh
	</h3>
	<p>
	    Al ejecutar el script se le podr&aacute; pasar como par&aacute;metros:
	</p>
	<ul>
		<li>
		    -u usuario_manager: Indica el usuario del administrador del switch
		</li>
		<li>
		    -p contrase&ntilde;a_manager: Indica la contrase&ntilde;a del administrador del switch
		</li>
		<li>
		    -H direccion_switch: Indica la direcci&oacute;n del switch
		</li>
		<li>
		    -P puerto_ssh_switch: Indica el puerto ssh configurado en el switch
		</li>
	</ul>
	<p>
	    Una vez ejecutado el comando expect y los scripts en la carpeta
	    ExpectScripts para poder ejecutar el script sin ninguna interacci&oacute;n m&aacute;s.
	</p>
	<h1>
	    2. Activar servicio ssh
	</h1>
	<h2>
	    2.1. Switch Cisco 3750G-24TS
	</h2>
	<p>
	    El firmware por defecto no incluye la posibilidad de activar ssh.
	</p>
	<p>
	    Es necesario como m&iacute;nimo 12.2(58)SE1 (
	    <a
	        href="https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst3750x_3560x/software/release/15-2_4_e/releasenotes/rn-1524e-3750x3560x.html"
	    >
	        link
	    </a>
	    )
	</p>
	<p>
	    Para activar ssh es necesario configurar un IP que sea accesible que nos
	    permita hacer funciones de gesti&oacute;n (no tiene porque que estar fuera del
	    enrutamiento IP ) para ello se puede seguir el siguiente ejemplo
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    enable
	                </p>
	                <p>
	                    configure
	                </p>
	                <p>
	                    interface vlan 1
	                </p>
	                <p>
	                    ip address 192.168.0.2 255.255.255.0
	                </p>
	                <p>
	                    exit
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Luego es necesario configurar un nombre y un nombre de dominio para ello se
	    puede seguir el siguiente ejemplo
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    enable
	                </p>
	                <p>
	                    configure
	                </p>
	                <p>
	                    h
	                <p>
	                    ip doma
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Posteriormente generaremos las claves RSA necesaria para la conexi&oacute;n ssh y
	    para ello hay que ejecutar el siguiente comando y cuando se solicite el
	    n&uacute;mero de bits de la clave hay que especificar como m&iacute;nimo 1024
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    enable
	                </p>
	                <p>
	                    configure
	                </p>
	                <p>
	                    crypto key generate rsa
	                </p>
	                <p>
	                    #Al preguntar How many bits in the modulus [512]:
	                </p>
	                <p>
	                    1024
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Para continuar activaremos el servicio ssh y la transferencia de archivos
	    mediante ssh
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    enable
	                </p>
	                <p>
	                    configure
	                </p>
	                <p>
	                    ip ssh version 2
	                </p>
	                <p>
	                    ip scp server enable
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    El &uacute;ltimo paso que seguir ser&aacute; crear una l&iacute;nea virtual para permitir la
	    conexi&oacute;n ssh. Los comandos que seguir son
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    enable
	                </p>
	                <p>
	                    configure
	                </p>
	                <p>
	                    line vty X Y
	                </p>
	                <p>
	                    transport input ssh
	                </p>
	                <p>
	                    login local
	                </p>
	                <p>
	                    exit
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Siendo X un n&uacute;mero de 0 &mdash; 4 que indica que l&iacute;nea se usara para la conexi&oacute;n
	    ssh y un n&uacute;mero de 0 - 15 que indica el n&uacute;mero de conexiones simultanea
	    siendo 1 si indicamos 0 y 16 si indicamos 15.
	</p>
	<h2>
	    2.2. Switch HP 2620-24 o 2650-24
	</h2>
	<p>
	    Debido a la implementaci&oacute;n de ssh que disponemos solo disponemos del
	    cifrado 3des-cbc compatible entre las dos modelos de switch.
	</p>
	<p>
	    Para activar ssh es necesario configurar un IP que sea accesible que nos
	    permita hacer funciones de gesti&oacute;n (no tiene porque que estar fuera del
	    enrutamiento IP) para ello se puede seguir el siguiente ejemplo
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    enable
	                </p>
	                <p>
	                    configure
	                </p>
	                <p>
	                    vlan 1
	                </p>
	                <p>
	                    ip address 192.168.0.2 255.255.255.0
	                </p>
	                <p>
	                    exit
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Para continuar activaremos el servicio ssh y la transferencia de archivos
	    mediante ssh
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    enable
	                </p>
	                <p>
	                    configure
	                </p>
	                <p>
	                    ip ssh
	                </p>
	                <p>
	                    ip ssh filetransfer
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Al habilitar la transferencia de ficheros mediante ssh se deshabilita el
	    demonio de tftp y el cliente, para habilitarlo de nuevo se puede ejecutar
	    lo siguiente comandos, pero esto deshabilitar&aacute; la transferencia de ficheros
	    mediante ssh
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    enable
	                </p>
	                <p>
	                    configure
	                </p>
	                <p>
	                    tftp client
	                </p>
	                <p>
	                    tftp server
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<h1>
	    3. Creaci&oacute;n de usuario administrador
	</h1>
	<h2>
	    3.1. Switch Cisco 3750G-24TS
	</h2>
	<p>
	    Para crear un usuario con privilegio de administrador se deben ejecutar los
	    siguientes comandos
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    enable
	                </p>
	                <p>
	                    configure
	                </p>
	                <p>
	                    username USERNAME privilege 15 secret PASSWORD 
	                </p>
	                <p>
	                    enable secret PASSWORD
	                </p>
	                <p>
	                    exit
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Para &uacute;nicamente poner contrase&ntilde;a para habilitar los privilegios mediante el
	    comando
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    enable
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Hay que ejecutar los siguientes comandos
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    enable
	                </p>
	                <p>
	                    configure t
	                </p>
	                <p>
	                    enable secret PASSWORD
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<h2>
	    3.2. Switch HP 25</a> o 2650-25
	</h2>
	<p>
	    Para crear un usuario con privilegio de administrador se deben ejecutar los
	    siguientes comandos
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    enable
	                </p>
	                <p>
	                    configure
	                </p>
	                <p>
	                    password manager us	                <p>
	                    #Al preguntar New password for manager:
	                </p>
	                <p>
	                    PASSWORD
	                </p>
	                <p>
	                    #Al preguntar Re-enter the new password for manager:
	                </p>
	                <p>
	                    PASSWORD
	                </p>
	                <p>
	                    exit
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<h1>
	    4. Borrado de configuraci&oacute;n total
	</h1>
	<h2>
	    4.1. Switch Cisco 3750G-24TS
	</h2>
	<p>
	    Partimos con el switch desconectado de la corriente.
	</p>
	<ol>
		<li>
		    Pulsamos el bot&oacute;n mode y conectamos el cable de corriente.
		</li>
		<li>
		    Mantener unos 15 segundo hasta que el led de SYST parpadee en naranja y
		    luego vuelva a verde y se mantenga en sin parpadear
		</li>
		<li>
		    Esperamos a que inicie el switch y muestre una consola como esta
		</li>
	</ol>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    Boot Sector Filesystem (bs) installed, fsid: 2
	                </p>
	                <p>
	                    Base ethernet MAC Address: 30:37:a6:01:f4:80
	                </p>
	                <p>
	                    Xmodem file system is available.
	                </p>
	                <p>
	                    The password-recovery mechanism is enabled.
	                </p>
	                <p>
	                    The system has been interrupted prior to initializing the
	                </p>
	                <p>
	                    flash filesystem. The following commands will initialize
	                </p>
	                <p>
	                    the flash filesystem, and finish loading the operating
	                </p>
	                <p>
	                    system software:
	                </p>
	                <p>
	                    flash_init
	                </p>
	                <p>
	                    boot
	                </p>
	                <p>
	                    switch:
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<ol start="4">
		<li>
		    Introducimos el comando flash_init
		</li>
		<li>
		    Ejecutaremos el comando set que nos mostrara las variables configurada
		    para el arranque de switch
		</li>
	</ol>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    BAUD=115200
	                </p>
	                <p>
	                    BOOT=flash:/c3750_15.bin
	                </p>
	                <p>
	                    BOOTHLPR=flash:/c3750_15.bin
	                </p>
	                <p>
	                    BOOT_MANUAL=
	                </p>
	                <p>
	                    DEFAULT_ROUTER=
	                </p>
	                <p>
	                    HELPER=
	                </p>
	                <p>
	                    IP_ADDR=
	                </p>
	                <p>
	                    MANUAL_BOOT=no
	                </p>
	                <p>
	                    PRIV_CONFIG=flash:/private-config.text
	                </p>
	                <p>
	                    SDM_TEMPLATE_ID=0
	                </p>
	                <p>
	                    SWITCH_NUMBER=1
	                </p>
	                <p>
	                    SWITCH_PRIORITY=1
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    De aqu&iacute; podemos ver que en el archivo flash:/private-config.text estar&iacute;a la
	    configuraci&oacute;n privada
	</p>
	<ol start="6">
		<li>
		    6. Ahora borraremos o renombraremos los siguientes ficheros terminado en
		    flash:*text y el archivo flash:config.text con el comando delete over que fichero es necesario borrar o renombrar podemos ejecutar
		</li>
	</ol>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    dir flash:
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Para cada archivo nos pedir&aacute; una confirmaci&oacute;n
	</p>
	<p>
	    Tambi&eacute;n habr&aacute; que borrar las variables que apuntaba a un archivo
	</p>
	<p>
	    Un ejemplo ser&iacute;a
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    set PRIV_CONFIG
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<ol start="6">
		<li>
		    7. ara finalizar ejecutamos el comando boot.
		</li>
	</ol>
	<p>
	    Si est&aacute; declarada anteriormente BOOTHLPR ni BOOT reiniciaremos el switch
	    sin configuraci&oacute;n.
	</p>
	<p>
	    Si no estaba declarada la variable BOOTHLPR y BOOT coger&aacute; la imagen por
	    defecto y si no hubiere deberemos setear nosotros la ruta hasta la imagen
	    de firmware
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    set BOOTHLPR flash:/c3750_15.bin
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Nota los bauds para la conexi&oacute;n depende de si se configuraron anteriormente
	    en el switch por defecto son 9600 pero una vez configurado esto tambi&eacute;n
	    afecta al modo de recuperaci&oacute;n
	</p>
	<h2>
	    4.2. Switch HP 2620-25 o 2650-25
	</h2>
	<p>
	Tambi&eacute;n puede usar el bot&oacute;n Reset junto con el bot&oacute;n Clear(Reset+Clear) para
	    restaurar la configuraci&oacute;n predeterminada de f&aacute;brica para el conmutador.
	    Para hacer esto:
	</p>
	<ol>
		<li>
			Mantenga presionado el bot&oacute;n Reset.    
		</li>
		<li>
		    Mientras mantiene presionado el bot&oacute;n Reset, presione y
		mantenga presionado el bot&oacute;n Clear    
		</li>
		<li>
		    Suelte el bot&oacute;n Reset.
		</li>
		<li>
			Cuando el LED de TEST a la derecha del Clear comienza a parpadear, suelte el bot&oacute:n Clear.
		</li>
	</ol>
	<p>
	    El conmutador tarda aproximadamente 20-25 segundos en reiniciarse. Este
	    proceso restaura la configuraci&oacute;n del interruptor a la configuraci&oacute;n
	    predeterminada de f&aacute;brica.
	</p>
	<p>
	    Si esta deshabilitado la configuraci&oacute;n front-panel-security factory-reset
	    no se podr&aacute; usar la combinaci&oacute;n de botones para hacer el borrado completo
	    de switch.
	</p>
	<p>
	    Aun as&iacute;, hay una posibilidad de recuperar la contrase&ntilde;a si la versi&oacute;n de
	    ROM del switch permite que al arrancar el switch y estando conectado por el
	    puerto serie a 9600 baud nos sale el siguiente men&uacute;
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    Boot Profiles:
	                </p>
	                <p>
	                    0. Monitor ROM Console
	                </p>
	                <p>
	                    1. Primary Software Image
	                </p>
	                <p>
	                    2. Secondary Software Image
	                </p>
	                <p>
	                    Select profile (primary): 0
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Entonces accedemos a Monitor ROM Console y ejecuatamos
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_comando" valign="top">
	                <p>
	                    cat cfa0/mgrinfo.txt
	                </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Y mostrara como resultado una de estas opciones:
	</p>
	<p>
	    Si tenemos contrase&ntilde;a tanto para operator como para manager.
	</p>
	<p>
	    El nombre de usuario manager seria -MANAGER- y la contrase&ntilde;a _PASSMANAGER_
	</p>
	<p>
	    El nombre de usuario operator seria -OPERATOR- y la contrase&ntilde;a
	    _PASSOPERATOR_
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_datos" valign="top">
	                <p>
	                FLG&mdash;PASSMANAGER&mdash;FLG&mdash;PASSOPERATOR&mdash;&#9640&#9640&#9640&#9640-MANAGER--OPERATOR-&mdash;PASSMANAGER&mdash;&mdash;PASSMANAGER&mdash;-MANAGER&mdash;OPERATOR-&#9640
	            </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<ul>
	    <li>
	        Si tenemos contrase&ntilde;a solo para operator.
	    </li>
	</ul>
	<p>
	    El nombre de usuario operator seria -OPERATOR- y la contrase&ntilde;a
	    _PASSOPERATOR_
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_datos" valign="top">
	                <p>
	                FLG&mdash;PASSOPERATOR&mdash;&#9640&#9640&#9640&#9640-OPERATOR-&mdash;PASSOPERATOR&mdash;--OPERATOR-&#9640
	            </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<ul>
	    <li>
	        Si tenemos contrase&ntilde;a solo para manager.
	    </li>
	</ul>
	<p>
	    El nombre de usuario manager seria -MANAGER- y la contrase&ntilde;a _PASSMANAGER_
	</p>
	<table border="1" cellspacing="0" cellpadding="0">
	    <tbody>
	        <tr>
	            <td class="tabla_datos" valign="top">
	                <p>
	                FLG&mdash;PASSMANAGER&mdash; &#9640&#9640&#9640&#9640-MANAGER-&mdash;PASSMANAGER&mdash;-MANAGER-&#9640
	            </p>
	            </td>
	        </tr>
	    </tbody>
	</table>
	<p>
	    Para m&aacute;s informaci&oacute;n
	    <a 
	    	target="_blank"
	        href="https://techhub.hpe.com/eginfolib/networking/docs/switches/WB/15-18/5998-8152_wb_2920_asg/content/ch02s05.html"
	    >
	        link
	    </a>
	</p>

	</div>
	<a id="volver" href="#">Volver</a>
</BODY>
</HTML>