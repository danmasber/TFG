#!/bin/sh
configuracion=$(dirname "$0")"/"configuracionScriptVirsh.cfg
. $configuracion

# Este script permite la administracion de maquina virtuales mediante el comando virsh a traves menu de forma mas sencilla 
# Entre la opciones que se propociona estan: ver el esatado de las maquinas del sistama, importart o exportar maquinas, cambiar el estado de maquina
# editar configuraciones de la maquina, eliminar maquinas o habilitar el autoincio de una maquina.  
					 

export NCURSES_NO_UTF8_ACS=1 # Evitar que aparezcan caracteres en lugar de lineas al usar dialog

# Creamos un fichero vacio para almacenar salida de comondos para mostrarla posteriormente
true > "$OUTPUT"

# Configuramos para ante un salida brusca se borre el fichero que almacena la salida y limpie la terminal
			
trap 'rm "$OUTPUT"; rm /tmp/maquinaActuales; clear; exit' 1 2 15

#Variable con las opciones comunes al lanza 
dialogAlias='dialog --stdout --clear'

# La funcion comprobarEjecucion evalua si hubo un error al ejecutar el ultimo comando y muestra un mensaje de lo ocurrido
# Si ocurrio un error provoca la salida del script			 
# ENTRADA salida del comando y mensaje a mostrar
# SALIDA ninguna
 comprobarEjecucion(){
  salida=$1  
  mensaje=$2
  if [ "$salida" != "0" ]; then
    if [ "$mensaje" != "" ]; then
      $dialogAlias  --title "ERROR" --msgbox "$mensaje" 10 50
    fi
    exit "$salida"
  fi  
} 
# La funcion seleccionarMaquina muestra una pantalla para seleccionar una maquina sobre la cual realizar acciones
# si solo existe una se preguntrara si se desea continuar con esta maquina
# ENTRADA ninguna
# SALIDA el nombre de la maquina seleccionada(salida  estandar) y si se a seleccionado o no una maquina(valor devuelto)

 seleccionarMaquina(){
  listadoMaquinasActuales=""
  numeroMaquinas=0
  virsh list --all --name > /tmp/maquinaActuales
  while IFS= read -r linea
  do  
    if [ "$linea" != "" ]; then
      listadoMaquinasActuales="$listadoMaquinasActuales \"$linea\" \"$linea\""
      numeroMaquinas=$((numeroMaquinas+1))
      ultimaMaquina="$linea"
    fi
  done < /tmp/maquinaActuales

  if [ "$numeroMaquinas" -gt 1 ]; then 
    comando="$dialogAlias --no-items --cancel-label \"Atras\" --backtitle \"Seleccione las maquinas\" --radiolist \"Maqinas actuales\" 8 50 0 $listadoMaquinasActuales"
    elecion=$(eval $comando)  
    salida=$? 
    echo "$elecion"
  else
    if [ "$numeroMaquinas" -eq 1 ]; then 
    $dialogAlias --yesno "¿Continua con la maquina $ultimaMaquina?" 8 50  
    salida=$?
    echo "$ultimaMaquina"
    else
       $dialogAlias --title "ERROR" --msgbox "No existe ninguna maquina" 10 50
       salida=1
    fi
  fi
  return "$salida"
}

# La funcion cambiarEstado muestra un menú que con las opciones para cambiar el estado una maquina concreta
# segun el estado de la maquina se mostra la opcion Activar maquina o Desctivar maquina
# ENTRADA el nombre de la maquina a cambiar de estado
# SALIDA ninguna

 cambiarEstado(){
  maquinasSeleccionada=$1
  virsh list --inactive --name | grep -E "^$maquinasSeleccionada$" > /dev/null 2>&1
  if [ "$?" = "0" ]; then
    opcionActiva_Desactivar="Activar maquina"
    desccripcionActiva_Desactivar="Activa un maquina inactiva."
   # Mostramos el menu para cambiar el estado de la maquina unicamente para activarla  y capturamos la opcion elegida y si se selecciono o se decidio salir
    seleccion=$($dialogAlias --cancel-label "Salir" --backtitle "Menú gestion de la maquina $maquinasSeleccionada" --menu "Seleccione una accion" 8 50 0 \
      "Activar maquina" "Activa un maquina inactiva.")
    salida=$? 
  else
    virsh list --state-paused --name | grep -E "^$maquinasSeleccionada$"  > /dev/null 2>&1
    if [ "$?" = "0" ]; then
      opcionIniciar_Pausar="Iniciar maquina"
      desccripcionIniciar_Pausar="Reanudar un maquina previamente suspendido."
    else
      opcionIniciar_Pausar="Pausar maquina"
      desccripcionIniciar_Pausar="Suspende la ejecución de un maquina."
    fi

    # Mostramos el menu para cambiar el estado de la maquina y capturamos la opcion elegida y si se selecciono o se decidio salir
    seleccion=$($dialogAlias --cancel-label "Salir" --backtitle "Menú gestion de la maquina $maquinasSeleccionada" --menu "Seleccione una accion" 8 50 0 \
        "Detener maquina" "Detener maquina, pero deja sus recursos intactos." \
        "$opcionIniciar_Pausar"  "$desccripcionIniciar_Pausar" \
        "Apagar maquina"   "Apagar un maquina de manera adecuada" \
        "Reiniciar maquina"   "Reiniciar maquina")
    salida=$? 
  fi

   
  case "$salida" in
    1|255) 
      return 0
    ;;
  esac
  case "$seleccion" in
     "Activar maquina")
        virsh start "$maquinasSeleccionada" > "$OUTPUT" 2>&1
        $dialogAlias  --msgbox "$(cat $OUTPUT)" 8 50
      ;;
     "Iniciar maquina")
        virsh resume "$maquinasSeleccionada" > "$OUTPUT" 2>&1
        $dialogAlias  --msgbox "$(cat $OUTPUT)" 8 50
      ;;
     "Pausar maquina")
        virsh suspend "$maquinasSeleccionada" > "$OUTPUT" 2>&1
        $dialogAlias  --msgbox "$(cat $OUTPUT)" 8 50
      ;;
      "Reiniciar maquina")
        virsh reboot "$maquinasSeleccionada" > "$OUTPUT" 2>&1
        $dialogAlias  --msgbox "$(cat $OUTPUT)" 8 50
      ;;
      "Apagar maquina")
        virsh shutdown "$maquinasSeleccionada" > "$OUTPUT" 2>&1
        $dialogAlias  --msgbox "$(cat $OUTPUT)" 8 50
      ;;
      "Detener maquina")
        virsh destroy "$maquinasSeleccionada" > "$OUTPUT" 2>&1
        $dialogAlias  --msgbox "$(cat $OUTPUT)" 8 50
      ;;
  esac  
}

# La funcion editarMaquina muestra un menú que con las opciones para editar una maquina concreta ya sea su nombre o el XML asociado a esta
# ENTRADA el nombre de la maquina la cual se va a editar 
# SALIDA ninguna
 editarMaquina(){
  maquinasSeleccionada=$1

  # Mostramos el menu para eliminar el estado de la maquina y capturamos la opcion elegida y si se selecciono o se decidio salir
  seleccion=$($dialogAlias --cancel-label "Salir" --backtitle "Menú gestion de la maquina $maquinasSeleccionada" --menu "Seleccione una accion" 8 50 0 \
      "Editar XML maquina"   "Editar XML maquina"  \
      "Renombrar nombre maquina" "Renombrar nombre maquina")
  salida=$? 
   
  case "$salida" in
    1|255) 
      return 0
    ;;
  esac
  case "$seleccion" in
    "Editar XML maquina")
        clear
        EDITOR=$EDITOR_POR_DEFECTO virsh edit "$maquinasSeleccionada" 
      ;;
    "Renombrar nombre maquina")
        VM_NUEVA=$($dialogAlias  --title "nombre" --inputbox "Seleccion un nombre:" 8 50 "$maquinasSeleccionada")
        if [ "$VM_NUEVA" != "" ]; then
          virsh domrename "$maquinasSeleccionada" "$VM_NUEVA" > "$OUTPUT" 2>&1
          $dialogAlias  --msgbox "$(cat $OUTPUT)" 8 50
        else
          $dialogAlias  --msgbox "No se ha introucido un nombre nuevo para $maquinasSeleccionada" 8 50
        fi 
      ;;
  esac  
}

# La funcion eliminarMaquina muestra un menú que con las opciones para eliminar una maquina concreta 
# ENTRADA el nombre de la maquina la cual se va a eliminar
# SALIDA ninguna
 eliminarMaquina(){
  maquinasSeleccionada=$1
  seleccion=$($dialogAlias --cancel-label "Salir" --backtitle "Menú gestion de la maquina $maquinasSeleccionada" --menu "Seleccione una accion" 8 50 0 \
     "Eliminar maquina" "Eliminar maquina(Sin borrar almacenamiento)" \
     "Eliminar completamente maquina" "Eliminar maquina junto el almacenamiento")
  salida=$? 
   
  case "$salida" in
    1|255) 
      return 0
    ;;
  esac
  case "$seleccion" in
   "Eliminar maquina")
      virsh destroy "$maquinasSeleccionada" ; virsh undefine "$maquinasSeleccionada" > "$OUTPUT" 2>&1
      $dialogAlias  --msgbox "$(cat $OUTPUT)" 8 50
    ;;
    "Eliminar completamente maquina")
      virsh destroy "$maquinasSeleccionada" ; virsh undefine "$maquinasSeleccionada" --remove-all-storage --nvram > "$OUTPUT" 2>&1
      $dialogAlias  --msgbox "$(cat $OUTPUT)" 8 50
    ;;
  esac  
}

# La funcion reactivarMaquina enciende si una maquina estaba apagada o la reanudacion si estaba suspendida
# ENTRADA el nombre de la maquina la cual se va a reactivar
# SALIDA la salida del comando ejecutado ya se la activacion o la reanudacion
reactivarMaquina(){
  maquinasSeleccionada=$1

  virsh list --inactive --name | grep -E "^$maquinasSeleccionada$"  > /dev/null 2>&1
  if [ "$?" = "0" ]; then
    $dialogAlias  --msgbox "Activamos la maquina $maquinasSeleccionada al encontrarse apagada" 8 50
    virsh start "$maquinasSeleccionada" > "$OUTPUT" 2>&1
    salida="$?"
    $dialogAlias  --msgbox "$(cat $OUTPUT)" 8 50
    return $salida
  fi

  virsh list --state-paused --name | grep -E "^$maquinasSeleccionada$"  > /dev/null 2>&1
  if [ "$?" = "0" ]; then
    $dialogAlias  --msgbox "Renaudamos la maquina $maquinasSeleccionada al encontrarse suspendida" 8 50
    virsh resume "$maquinasSeleccionada" > "$OUTPUT" 2>&1
    salida="$?"
    $dialogAlias  --msgbox "$(cat $OUTPUT)" 8 50
    return $salida
  fi
}

# La funcion gestionarMaquina muestra un menú que con las opciones para moodificar una maquina concreta 
# entre estas opciones se encuentra los submenu de "Cambiar estado"  "Editar maquina" y "Eliminar maquina"  que lanzaran otro menu mas con opciones mas especificas
# segun este des/activado el autoinicio se mostrará la opcion correspondiente para activarlo o desctivarlo
# ENTRADA ninguna
# SALIDA ninguna
 gestionarMaquina(){
  #Llamamos a la funcion seleccionarMaquina que nos permitira elegir con que maquina vamos a trabajar
  maquinasSeleccionada=$(seleccionarMaquina) 
  salida=$? 
  # Volveremos al menu principal si no selecionamos una maquina
  case "$salida" in
    1|255) 
      return 0
    ;;
  esac

  # Comprobamos que la maquinaSelecciona no es una cadena vacía para contiunar
  if [ "$maquinasSeleccionada" != "" ]; then
    # Evaluamos si esta activa o no la opcion de autoinicio de la maquina seleccionada para mostrar la opcion opuesta a su estado actual
    virsh list --no-autostart --name | grep -E "^$maquinasSeleccionada$"  > /dev/null 2>&1
    salida=$? 
    if [ "$salida" = "0" ]; then
      opcionAutoinicio="Activar autoinicio maquina" 
      descripcionAutoinicio="Configura un maquina para ser iniciado automáticamente en el inicio."
    else
      opcionAutoinicio="Desctivar autoinicio maquina"
      descripcionAutoinicio="Deshabilita un maquina para ser iniciado automáticamente en el inicio."
    fi

    # Mostramos el menu de modificacion de maquina y capturamos la opcion elegida y si se selecciono o se decidio salir
    seleccion=$($dialogAlias --cancel-label "Salir" --backtitle "Menú gestion de la maquina $maquinasSeleccionada" --menu "Seleccione una accion" 8 50 0 \
      "Cambiar estado" "Menu para modificar estado de la maquina." \
      "Editar maquina" "Menu para editar la maquina." \
      "Eliminar maquina" "Menu para maquina la maquina." \
      "Acceder por consola maquina" "Acceder por consola a un maquina" \
      "Acceder por virt-viewer maquina" "Acceder por virt-viewer a un maquina" \
      "$opcionAutoinicio" "$descripcionAutoinicio")
    salida=$? 
   
    case "$salida" in
      1|255) 
        return 0
      ;;
    esac   
    
    case "$seleccion" in
      "Cambiar estado")
      cambiarEstado "$maquinasSeleccionada"
      ;;
      "Editar maquina")
      editarMaquina "$maquinasSeleccionada"
      ;;
      "Eliminar maquina")
      eliminarMaquina "$maquinasSeleccionada"
      ;;
      "Acceder por consola maquina")
        reactivarMaquina "$maquinasSeleccionada"
        clear
        virsh console "$maquinasSeleccionada" 
      ;;
      "Acceder por virt-viewer maquina")
        # Comprobamos que se este instalado el comando virt-viewer
        command -v  virt-viewer > /dev/null  2>&1
        if [ "$?" = "0" ]; then
          reactivarMaquina "$maquinasSeleccionada"
          salida="$?"
          if [ "$salida" = "0" ]; then
            virt-viewer "$maquinasSeleccionada"
          fi
        else
          $dialogAlias  --msgbox "No esta instalado virt-viewer" 8 50
        fi  
      ;;
      "Activar autoinicio maquina")
        virsh autostart "$maquinasSeleccionada" > "$OUTPUT" 2>&1
        $dialogAlias  --msgbox "$(cat $OUTPUT)" 8 50
      ;;
      "Desctivar autoinicio maquina")
        virsh autostart --disable "$maquinasSeleccionada" > "$OUTPUT" 2>&1
        $dialogAlias  --msgbox "$(cat $OUTPUT)" 8 50
      ;;
    esac
  else
    $dialogAlias  --msgbox "No se ha seleccionado ninguna maquina" 8 50
  fi
}

# Esta funcion muestra un menú que permite seleccionar entre los diferentes estado para listar las maquinas que cumplan dichos estados
# ENTRADA ninguna
# SALIDA opciones seleccionadas con el formato necesario para introduciorlo en el metodo virsh list SALIDA(salida estandar) y si se a seleccionado o no una maquina(valor devuelto)
# Si se desea anadir una opcion mas para mostrar antes del parametro que se usara en el comando virsh list colocar /
seleccionarEstadosMaquinas(){
  # Mostramos el menu de modificacion de maquina y capturamos la opcion elegida y si se selecciono o se decidio salir
  mensajeMenusSeleccionarEstadosMaquinas="Estados selecionables \n \n    Por defecto se mostrará solo lo maquinas activos"
  elecion=$($dialogAlias --cancel-label "Atras" --no-tags --backtitle "Seleccione los posibles estados de las maquinas" --checklist "$mensajeMenusSeleccionarEstadosMaquinas" 8 50 0 \
      "/--all"            "Listar todas las maquinas" OFF \
      "/--inactive"       "Listar  maquinas inactivas" OFF \
      "/--state-running"  "Listar maquinas en estado de ejecución" OFF \
      "/--state-paused"   "Listar maquinas en estado pausado" OFF \
      "/--state-shutoff"  "Lista maquinas en estado apagado" OFF \
      "/--state-other"    "Listar maquinas en otros estados" OFF \
      "/--autostart"      "Lista maquinas con autoinicio activado" OFF \
      "/--no-autostart"   "Lista maquinas con  autoinicio desactivado" OFF)

  # Filtramos de la seleccion para eliminar /   
  echo "$elecion" | sed -e 's/\///g'

  return "$salida"
}
 
# Esta funcion muestra un menú que permite seleccionar entre el uso de script para lanzar otro menu para exportacion o importacion 
# de maquinas
# ENTRADA ninguna
# SALIDA ninguna
modificarExportarImportar(){
  # Mostramos el menu de importacion/exportacion de maquina y capturamos la opcion elegida y si se selecciono o se decidio salir
  seleccion=$($dialogAlias --cancel-label "Atras" --backtitle "Menú gestion exportacion e importacion de maquinas" --menu "Seleccione una accion" 8 50 0 \
      "Exportar maquina" "Exportar una maquina concreta." \
      "Importar maquina" "Importar una maquina concreta." )

  salida=$? 
  case "$salida" in
    1|255) 
      return "$salida"
    ;;
  esac
  
  case "$seleccion" in
    "Exportar maquina")
      # Llamamos a la funcion seleccionarMaquina para elegir la maquina que será exportada
      maquinasSeleccionada=$(seleccionarMaquina) 
      salida=$?
      # Comprobamos que hemos seleccionado una maquina y que esta no es una cadena vacía
      case "$salida" in
        1|255) 
          return "$salida"
        ;;
      esac

      if [ "$maquinasSeleccionada" != "" ]; then
        # Llamamos a un otro proceso que será el encagado de guiar y exportar la maquina seleccionada
        ./exportarMVMenu.sh "$maquinasSeleccionada" > /dev/null 2>&1
      else
        $dialogAlias  --msgbox "No se ha seleccionado ninguna maquina" 8 50
      fi
    ;;
    "Importar maquina")
    # Solicitamos el nombre de la maquina a importar
    VM_NUEVA=$($dialogAlias  --title "nombre" --inputbox "Introduzca el nombre de la maquina a importar:" 8 50 )
    
    # Comprobamos que hemos introducido un nombre y que esta no es una cadena vacía
    salida=$?
      case "$salida" in
        1|255) 
          return "$salida"
        ;;
      esac
    if [ "$VM_NUEVA" != "" ]; then
    # Llamamos a un otro proceso que será el encagado de guiar y importar la maquina seleccionada
     ./importarMVMenu.sh "$VM_NUEVA"
    else
      $dialogAlias  --msgbox "No se ha introucido un nombre nuevo para la maquina a importar" 8 50
    fi 
    ;;
  esac
}

# Comprobamos que se este instalado el comando virsh
command -v virsh > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado virsh"

# Comprobamos que se este instalado el comando sed
command -v sed > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado sed"

# Comprobamos que se este instalado el comando dialog
command -v dialog > /dev/null  2>&1

comprobarEjecucion $? "Debe estar instalado dialog"							 
		   

#Comprobamos que se ejecute el script como root para poder acceder a virsh
if [ "$(whoami)" != 'root' ]; then
  comprobarEjecucion 1 "Se requieren persmisos de administrador para continuar con el script"
fi

# main() muestra un menu pricipl con tres opciones "Listar maquinas"  "Gestionar maquina concreta" y "Exportar/Importar" 
# hasta que se pulse salir o pulse esc

while true; do
  # Mostramos el menu principal y capturamos la opcion elegida y si se selecciono o se decidio salir
  opcion=$($dialogAlias --cancel-label "Salir" --backtitle "Menú gestion de maquinas virtuales KVM" --menu "Que desea hacer"  8 50 0 \
    "Listar maquinas" "Mostrar las diferentes maquinas disponibles segun el estado." \
    "Gestionar maquina concreta" "Se desea realizar una accion concreta sobre una maquina" \
    "Exportar/Importar" "Se desea expotar o importar maquina")
  salida=$?   
  comprobarEjecucion $salida
  
  case "$opcion" in
    "Listar maquinas")
      # Llamamos a la funcion seleccionarEstadosMaquinas que nos mostrará los posibles estados a seleccionar para mostrar las maquinas que lo cumple
      estados=$(seleccionarEstadosMaquinas)
      salida=$? 
      #  Volvermos a mostrar el menu principal si pulsamos volver hacia atras o pulsamos ESC
      if [ "$salida" != "0"]; then
        continue
      fi
      # Listamos las maquina que cumple los estado seleccionados y lo formatemos para que tenga apariencia de tabla para mostrarlo a continuacion
      tablaConMaquinas=$(virsh list $estados | sed '2d'| sed 's/\[:blank:]*/\t\t/g')
      $dialogAlias  --msgbox "$tablaConMaquinas" 8 50
    ;;
   "Gestionar maquina concreta")
     gestionarMaquina
    ;;
   "Exportar/Importar")
     modificarExportarImportar
    ;;  
 esac
done

