<?php
$mapeoParticiones = array
  (
	"Windows" =>   array(
					"particion" => "/mnt/sda1",
					"comandoComprobacion"  => 'ver | findstr /C:\"Versi\"| findstr /C:\"n 10.\" > nul 2> nul & if NOT errorlevel  1 ( *comando* )' ,
					"comandoComentario" => "rem ",
					"lugarComentario" => "fin",
					"esSistemaOperativo" => true,
					),
	"Linux CentOS" =>  	array(
						 "particion" => "/mnt/sda2",
						 "comandoComprobacion"  => 'if lsb_release -d | grep -q \"CentOS Linux release 7\"; then \n*comando*\nfi' ,
						 "comandoComentario" => "# ",
						 "lugarComentario" => "principio",
						 "esSistemaOperativo" => true,
						),
	"Linux Ubuntu/Debian" =>   array(
							  	"particion" => "/mnt/sda6",
						  		"comandoComprobacion"  => 'if lsb_release -d | grep -q \"Ubuntu 16\"; then \n*comando*\nfi' ,
						  		"comandoComentario" => "# ",
						  		"lugarComentario" => "principio",
								"esSistemaOperativo" => true,
						 	   ),
	"Linux programas" =>   array(
						  	"particion" => "/mnt/sda7",
						  	"comandoComprobacion"  => "" ,
						  	"comandoComentario" => "",
						  	"lugarComentario" => "",
							"esSistemaOperativo" => false,
						   ),
	"Windows Programas" =>   array(
						  	  "particion" => "/mnt/sda8",
						  	  "comandoComprobacion"  => "" ,
						  	  "comandoComentario" => "",
						  	  "lugarComentario" => "",
							  "esSistemaOperativo" => false,
						  	 ),
	"Linux Moviles" =>   array(
						  "particion" => "/mnt/sda9",
						  "comandoComprobacion"  => 'if lsb_release -d | grep -q \"Debian GNU/Linux Kali Linux 1.0\"; then \n*comando*\nfi' ,
						  "comandoComentario" => "# ",
						  "lugarComentario" => "principio",
						  "esSistemaOperativo" => true,
						 ),
	"Linux Kali" =>   array(
					   "particion" => "/mnt/sda10",
					   "comandoComprobacion"  => 'if lsb_release -d | grep -q\"Debian GNU/Linux Kali Linux 1.0\"; then \n*comando*\nfi' ,
					   "comandoComentario" => "# ",
					   "lugarComentario" => "principio",
					   "esSistemaOperativo" => true,
					  ),
  );
?>

