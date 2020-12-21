#!/usr/bin/awk -f

function modoFicheroSalida(){ return "ficheroConfiguracion";} #puede ser comando o ficheroConfiguracion
function nombreFicheroSalida(){ return "salida";}
function nombreFicheroSalidaRangos(){ return "rangoDinamicoConfigurado";} 

function escribirFinComando(){
    if (modoFicheroSalida() == "comando") {
      print "exit" > nombreFicheroSalida()
    } else if (modoFicheroSalida() == "ficheroConfiguracion"){
      print "!" > nombreFicheroSalida()
    }
}

function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s)  { return rtrim(ltrim(s)); }

function buscarPropiedades(arrayPropiedad, ambitoInicial){ 
  #Solo es util para los array unidimensional
  while (arrayPropiedad[ambitoInicial] == null && ambitoInicial != "global") {
    ambitoInicial = ambitoPadre[ambitoInicial]
  }

  return arrayPropiedad[ambitoInicial]; 
}

function buscarTipoNetBios(ambitoInicial){ 
  while (tipoNetBios[ambitoInicial] == null && ambitoInicial != "global") {
    ambitoInicial = ambitoPadre[ambitoInicial]
  }

  #1 = B-node, 2 = P-node, 4 =M-node, 8 = H-node
  
  if(ipoNetBios[ambitoInicial] == null){
    return "h-node"
  } else if(ipoNetBios[ambitoInicial] == "1"){
    return "b-node"
  } else if(ipoNetBios[ambitoInicial] == "2"){
    return "p-node"
  } else if(ipoNetBios[ambitoInicial] == "4"){
    return "m-node"
  } else if(ipoNetBios[ambitoInicial] == "8"){
    return "h-node"
  } 
}

function buscarPropiedadesMultiple(arrayPropiedad, ambitoInicial){ 
  encontradoArrayPropiedad = "false"
  ultimaIteracion = "false"
  while (encontradoArrayPropiedad == "false" && ultimaIteracion == "false") {

    if( ambitoInicial == "global"){
      ultimaIteracion = "true"
    }

    for(arrayPropiedadIJ in arrayPropiedad){
      split(arrayPropiedadIJ,indices,SUBSEP);
      arrayPropiedadI=indices[1];
      arrayPropiedadJ=indices[2];

      if(arrayPropiedadI == ambitoInicial){ 
             
        encontradoArrayPropiedad = "true"
        break
      }
    }

    if (encontradoArrayPropiedad == "false") {
      ambitoInicial = ambitoPadre[ambitoInicial]
    } else{
      break
    }  
  }
        
  cadenaArrayPropiedad = ""
  if(encontradoArrayPropiedad == "true"){
    for(arrayPropiedadIJ in arrayPropiedad){
      split(arrayPropiedadIJ,indices,SUBSEP);
      arrayPropiedadI=indices[1];
      arrayPropiedadJ=indices[2];

      if(arrayPropiedadI == ambitoInicial){ 
        cadenaArrayPropiedad = cadenaArrayPropiedad " " arrayPropiedad[arrayPropiedadI,arrayPropiedadJ];
      }
    }
  }

  return cadenaArrayPropiedad
}

function convertirMac(mac, esEthernet){ 
  if(esEthernet == "true"){
    nuevoFormatoMac = "01"
    interacionFormateoMac = 2
  } else{
    nuevoFormatoMac = ""
    interacionFormateoMac = 1
  }
  
  split(mac, macDividida, ":")
  for( partMac in macDividida){
    if (interacionFormateoMac != 1 && interacionFormateoMac % 2 == 1) {
     nuevoFormatoMac = nuevoFormatoMac  "."
    }
    nuevoFormatoMac = nuevoFormatoMac  tolower(macDividida[partMac])
    
    interacionFormateoMac++
  }

  return nuevoFormatoMac
}

function convertirLease(segundo){
  dias=(segundo/60/60/24)
  dias=dias - dias%1
  horas=(segundo/60/60)%24
  horas=horas - horas%1
  minutos=(segundo/60)%60
  minutos=minutos - minutos%1
  return dias " " horas " " minutos
}

BEGIN {
   if (ARGC < 2) {
     print "Se debe introducir la configuracion dhcp de donde se obtendran los datos para generar la configuracion"
     exit 1
  }

  if (ARGC > 3) {
     print "Solo se admite un archivo de configuracion como argumento"
     exit 1
  }

  print "Se empieza el procesamiento del archivo " ARGV[1]
  print "Se genera como salida el archvio " nombreFicheroSalida()
  if (modoFicheroSalida() == "comando") {
      print "Esto se usara para ejecutarse mediante consola en el switch"
    } else if (modoFicheroSalida() == "ficheroConfiguracion"){
      print "Esto se usara para completar al archivo de configuracion actual del switch"
    }
  print "Se genera el archivo " nombreFicheroSalidaRangos() " con los rangos dinamico confiurado para cada subred"
 
  print "Si desea cambiar esto recuerda moficar las funciones nombreFicheroSalida() , modoFicheroSalida() y nombreFicheroSalidaRangos() "

  FS="\n"
}

{

  if(ambitoActual == null ){
    ambitoActual = "global"
  }

  if (index(ltrim($1), "#") != 1 && length(trim($1)) > 0) {
    #Elimino lineas  comentadas y en blanco
    registro = ltrim($1)
    #Elimino si hay comentario a mitad de linea
    split(registro, lineaSeparacionComentario, "#")
    registro = lineaSeparacionComentario[1]

    #cambio mutiple espacio por uno solo
    gsub(/ +/, " ",registro)
    
    if(registro ~ /^shared-network/) {
      split(registro, linea, " ")
    
      redCompartidaActual = linea[2]
      ambitoPadre["shared-network"linea[2]] = "global"
      ambitoActual = "shared-network"linea[2] 
    }

    if(registro ~ /^default-lease-time/) {
      gsub(";","",registro) 
      split(registro, linea," ")
      
      tiempoContradoPorDefecto[ambitoActual] = linea[2]      
    }

    if(registro ~ /^max-lease-time/) {
      gsub(";","",registro) 
      split(registro, linea, " ")
            
      tiempoContradoMaximo[ambitoActual] = linea[2]     
    }

    if(registro ~ /^min-lease-time/) {
      gsub(";","",registro) 
      split(registro, linea, " ")
     
      tiempoContradoMinimo[ambitoActual] = linea[2]    
    }

    if(registro ~ /^server-name/) {
      gsub(";","",registro) 
      split(registro, linea, " ")
    
      nombreServidor[ambitoActual] = linea[2]      
    }

    if(registro ~ /^get-lease-hostnames/) {
      gsub(";","",registro) 
      split(registro, linea, " ")

      resolverIPCliente_Nombre[ambitoActual] = linea[2]
    }

    if(registro ~ /^use-host-decl-names/) {
      gsub(";","",registro) 
      split(registro, linea, " ")

      hostNameEsNombreCliente[ambitoActual] = linea[2]      
    }

    if(registro ~ /^authoritative/) {
      
      esServicorAutorizadoEnRed[ambitoActual] = true   
    }

    if(registro ~ /^option domain-name /) {
      gsub(";|\"","",registro)
      split(registro, linea, " ")
      
      nombreDomino[ambitoActual] = linea[3]
    }

    if(registro ~ /^option domain-name-servers /) {
      gsub(";","",registro)
      gsub(","," ",registro)
      split(registro, linea, " ")
      indice = 0

      for (indiceDns in linea) {
        if(indiceDns > 2){
          dns[ambitoActual,++indice] = linea[indiceDns]
        }
      }
    }

    if(registro ~ /^range/) {
      gsub(";","",registro)
      split(registro, linea, " ")

      rangoIncio[ambitoActual] = linea[2]
      rangoFin[ambitoActual] = linea[3]
    }

    if(registro ~ /^next-server/) {
      gsub(";","",registro)
      split(registro, linea, " ")

      servidorTFTP[ambitoActual] = linea[2]
    }

    if(registro ~ /^hardware ethernet/) {
      gsub(";","",registro)
      split(registro, linea, " ")

      mac[ambitoActual] = linea[3]
    }

    if(registro ~ /^fixed-address/) {
      gsub(";","",registro)
      split(registro, linea, " ")

      ipEstatica[ambitoActual] = linea[2]
    }

    if(registro ~ /^option host-name/) {
      gsub(";|\"","",registro)
      split(registro, linea, " ")
      
      hostname[ambitoActual] = linea[3]
    }

    if(registro ~ /^option dhcp-client-identifier/) {
      gsub(";|\"","",registro)
      split(registro, linea, " ")
      
      identificadoCliente[ambitoActual] = linea[3]
    }

    if(registro ~ /^option netbios-node-type/) {
      gsub(";|\"","",registro)
      split(registro, linea, " ")
      
      tipoNetBios[ambitoActual] = linea[3]
    }

    if(registro ~ /^filename/) {
      gsub(";|\"","",registro)
      split(registro, linea, " ")
      
      bootfile[ambitoActual] = linea[2]
    }
    
    
    if(registro ~ /^option netbios-name-servers/) {
      gsub(";","",registro)
      gsub(","," ",registro)
      split(registro, linea, " ")
      indice = 0

      for (indicePropiedad in linea) {
        if(indicePropiedad > 2){
          servidorNetBios[ambitoActual,++indice] = linea[indicePropiedad]
        }
      }
    }

    if(registro ~ /^option routers/) {
      gsub(";","",registro)
      gsub(","," ",registro)
      split(registro, linea, " ")
      indice = 0

      for (indicePropiedad in linea) {
        if(indicePropiedad > 2){
          routers[ambitoActual,++indice] = linea[indicePropiedad]
        }
      }
    }

    if(registro ~ /^subnet/) {
      split(registro, lineaSubred, " ")
     
      nombreSubred = "subnet_"lineaSubred[2]
      subred[nombreSubred] = lineaSubred[2]
      mascaraSubred[nombreSubred] = lineaSubred[4]
      ambitoPadre[nombreSubred] = ambitoActual
      ambitoActual = nombreSubred
    }
    
    if(registro ~ /^host/) {
      split(registro, linea, " ")

      hostAux = linea[2]
      if(hostAux == null || hostAux == "{"){
        hostAux = "hostDesconociodo"++hostDesconociodo
      }
      
      host[hostAux] = "host_"hostAux
      ambitoPadre[host[hostAux]] = ambitoActual
      ambitoActual = host[hostAux]
    }

    if(registro ~ /^group/) {
      split(registro, linea, " ")

      groupAux = linea[2]
      if(groupAux == null || groupAux == "{"){
        groupAux = "Desconociodo_"++groupDesconociodo
      }
      
      group[groupAux] = "group_"groupAux
      ambitoPadre[group[groupAux]] = ambitoActual
      ambitoActual = group[groupAux]
    }

    if(registro ~ /}/) {
      ambitoActual = ambitoPadre[ambitoActual]    
      if(ambitoActual == null ){
        ambitoActual = "global"
      }     
    }
  }  
}


END {  
 
  modoSalida = modoFicheroSalida()
  ficheroSalida = nombreFicheroSalida()
  ficheroSalidaRangos = nombreFicheroSalidaRangos()
  for(indiceHost in host) {
    hostActual = host[indiceHost]
    nombrePool = hostActual
    gsub("host_","",nombrePool)
    print "ip dhcp pool " nombrePool > ficheroSalida

    if (buscarPropiedades(ipEstatica, hostActual) != null && buscarPropiedades(mascaraSubred, hostActual) != null) {
      print " host " buscarPropiedades(ipEstatica, hostActual) " " buscarPropiedades(mascaraSubred, hostActual) > ficheroSalida
    }

    if ((cadenaComprobacion = convertirMac(mac[hostActual], "true")) != null) {
      print " hardware-address " cadenaComprobacion " ethernet" > ficheroSalida
    }

    if ((cadenaComprobacion = convertirMac(mac[hostActual], "true")) != null) { 
      print " client-identifier " cadenaComprobacion > ficheroSalida
    }

    if ((cadenaComprobacion = hostname[hostActual]) != null) {
      print " client-name " cadenaComprobacion > ficheroSalida
    }

    if ((cadenaComprobacion = buscarPropiedadesMultiple(routers, hostActual)) != null) {
      print " default-router " cadenaComprobacion > ficheroSalida
    }

    if ((cadenaComprobacion = buscarPropiedades(servidorTFTP, hostActual)) != null) {
      print " next-server " cadenaComprobacion > ficheroSalida
    }
    
    if ((cadenaComprobacion = buscarPropiedades(nombreDomino, hostActual)) != null) {
      print " domain-name " cadenaComprobacion > ficheroSalida
    }
    
    if ((cadenaComprobacion = buscarPropiedadesMultiple(dns, hostActual)) != null) {
      print " dns-server " cadenaComprobacion > ficheroSalida
    }
    
    if ((cadenaComprobacion = buscarPropiedadesMultiple(servidorNetBios, hostActual)) != null) {
      print " netbios-name-server " cadenaComprobacion > ficheroSalida
    }
    
    if ((cadenaComprobacion = buscarTipoNetBios(hostActual)) != null) {
      print " netbios-node-type " cadenaComprobacion > ficheroSalida
    }

    if ((cadenaComprobacion = buscarPropiedades(tiempoContradoPorDefecto, hostActual)) != null) {
      print " lease " convertirLease(cadenaComprobacion) > ficheroSalida
    }
    
    if ((cadenaComprobacion = buscarPropiedades(bootfile, hostActual)) != null) {
      print " bootfile " cadenaComprobacion > ficheroSalida
    }
    
    escribirFinComando()
  }

  for(indiceSubred in subred) {
    subredActual = subred[indiceSubred]
    cadenaComprobacion = null
    print "ip dhcp pool " indiceSubred > ficheroSalida
    
    if ((cadenaComprobacion = buscarPropiedades(mascaraSubred, indiceSubred)) != null) {
       print " network " subredActual " " cadenaComprobacion > ficheroSalida
    }
     
    if ((cadenaComprobacion = buscarPropiedades(nombreDomino, indiceSubred)) != null) {
       print " domain-name " cadenaComprobacion > ficheroSalida
    }
    
    if ((cadenaComprobacion = buscarPropiedadesMultiple(routers, indiceSubred)) != null) {
      print " default-router " cadenaComprobacion > ficheroSalida
    }
    
    if ((cadenaComprobacion = buscarPropiedades(servidorTFTP, indiceSubred)) != null) {
      print " next-server " cadenaComprobacion > ficheroSalida
    }
    
    if ((cadenaComprobacion = buscarPropiedadesMultiple(dns, indiceSubred)) != null) {
       print " dns-server " cadenaComprobacion > ficheroSalida
    }
   
    if ((cadenaComprobacion = buscarPropiedadesMultiple(servidorNetBios, indiceSubred)) != null) {
      print " netbios-name-server " cadenaComprobacion > ficheroSalida
    }
    
    if ((cadenaComprobacion = buscarTipoNetBios(indiceSubred)) != null) {
      print " netbios-node-type " cadenaComprobacion > ficheroSalida
    }

    print " class "indiceSubred"_class" > ficheroSalida

    cadenaComprobacionInicio = buscarPropiedades(rangoIncio, indiceSubred)
    cadenaComprobacionFin = buscarPropiedades(rangoFin, indiceSubred)
    if ( cadenaComprobacionInicio != null && cadenaComprobacionFin != null) {
       print " address range " cadenaComprobacionInicio " " cadenaComprobacionFin > ficheroSalida
    }

    if ((cadenaComprobacion = buscarPropiedades(tiempoContradoPorDefecto, indiceSubred)) != null) {
      print " lease " convertirLease(cadenaComprobacion)  > ficheroSalida
    }
    
    if ((cadenaComprobacion = buscarPropiedadesMultiple(bootfile, indiceSubred)) != null) {
     print " bootfile " cadenaComprobacion > ficheroSalida
    }
    
    escribirFinComando()
  }

  # Excluimos las ip default server para que no se asigne por el DHCP 
  for(indiceSubred in subred) {
    subredActual = subred[indiceSubred]
    cadenaComprobacion = null
    if ((cadenaComprobacion = buscarPropiedadesMultiple(routers, indiceSubred)) != null) {
      print "ip dhcp excluded-address " cadenaComprobacion > ficheroSalida
    }
  
  }

  for(indiceSubred in subred) {
    cadenaComprobacionInicio = buscarPropiedades(rangoIncio, indiceSubred)
    cadenaComprobacionFin = buscarPropiedades(rangoFin, indiceSubred)
    cadenaComprobacionMascaraSubred = buscarPropiedades(mascaraSubred, indiceSubred)
    if ( cadenaComprobacionInicio != null && cadenaComprobacionFin != null && cadenaComprobacionMascaraSubred != null) {
       print "Rango asignado a la subred " subred[indiceSubred] " "cadenaComprobacionMascaraSubred "  -> " cadenaComprobacionInicio "-" cadenaComprobacionFin > ficheroSalidaRangos
    }
  }
  close(ficheroSalida)
  close(ficheroSalidaRangos)
S}
