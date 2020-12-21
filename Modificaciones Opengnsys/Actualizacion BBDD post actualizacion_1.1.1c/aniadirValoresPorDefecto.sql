ALTER TABLE imagenes
	MODIFY nombreca varchar(50) NOT NULL DEFAULT '';

 ALTER TABLE ordenadores_particiones
	MODIFY  idordenador int(11) NOT NULL DEFAULT '0',
	MODIFY  numdisk smallint NOT NULL DEFAULT '0',
	MODIFY  numpar smallint NOT NULL DEFAULT '0',
	MODIFY  codpar int(8) NOT NULL DEFAULT '0',
	MODIFY  tamano int(11) NOT NULL DEFAULT '0',
	MODIFY  idsistemafichero smallint(11) NOT NULL DEFAULT '0',
	MODIFY  idnombreso smallint(11) NOT NULL DEFAULT '0',
	MODIFY  idimagen int(11) NOT NULL DEFAULT '0',
	MODIFY  idperfilsoft int(11) NOT NULL DEFAULT '0';

ALTER TABLE acciones
	MODIFY tipoaccion smallint(6) NOT NULL DEFAULT '0',
	MODIFY idtipoaccion int(11) NOT NULL DEFAULT '0', 
	MODIFY descriaccion varchar(250) NOT NULL DEFAULT '',
	MODIFY idordenador int(11) NOT NULL DEFAULT '0',
	MODIFY ip varchar(50) NOT NULL DEFAULT '',
	MODIFY sesion int(11) NOT NULL DEFAULT '0',
	MODIFY idcomando int(11) NOT NULL DEFAULT '0';	

ALTER TABLE parametros 
	MODIFY nemonico char(3) NOT NULL DEFAULT '',
	MODIFY nomidentificador varchar(64) NOT NULL DEFAULT '',
	MODIFY nomtabla varchar(64) NOT NULL DEFAULT '';

 ALTER TABLE tipohardwares
	MODIFY nemonico char(3) NOT NULL DEFAULT '';	

ALTER TABLE perfilessoft
  MODIFY  idcentro int(11) NOT NULL DEFAULT '0';	

ALTER TABLE programaciones
  MODIFY sesion int(11) NOT NULL DEFAULT '0'; 

ALTER TABLE aulas
	MODIFY  modomul tinyint(4) NOT NULL DEFAULT '0',
	MODIFY ipmul varchar(16) NOT NULL DEFAULT '';
	MODIFY pormul int(11) NOT NULL DEFAULT '0';

ALTER TABLE asistentes
	MODIFY  pagina varchar(256) NOT NULL DEFAULT '',
	MODIFY  gestor varchar(256) NOT NULL DEFAULT '',
	MODIFY  funcion varchar(64) NOT NULL DEFAULT '',
	MODIFY  activo tinyint(1) NOT NULL DEFAULT '0';

ALTER TABLE comandos
	MODIFY pagina varchar(256) NOT NULL DEFAULT '',
	MODIFY gestor varchar(256) NOT NULL DEFAULT '',
	MODIFY funcion varchar(64) NOT NULL DEFAULT '',
	MODIFY activo tinyint(1) NOT NULL DEFAULT '0';

ALTER TABLE entornos
	MODIFY  ipserveradm varchar(50) NOT NULL DEFAULT '',
	MODIFY  portserveradm int(20) NOT NULL DEFAULT 2008,
	MODIFY  protoclonacion varchar(50) NOT NULL DEFAULT '';

ALTER TABLE nombresos 
	MODIFY nombreso varchar(250) NOT NULL DEFAULT '';

ALTER TABLE  perfileshard
	MODIFY idcentro int(11) NOT NULL DEFAULT '0';

ALTER TABLE  plataforma
	MODIFY plataforma varchar(250) NOT NULL DEFAULT '';

ALTER TABLE procedimientos_acciones 
	MODIFY procedimientoid int(11) NOT NULL DEFAULT '0';

ALTER TABLE repositorios
	MODIFY nombrerepositorio varchar(250) NOT NULL DEFAULT '';

ALTER TABLE sistemasficheros
	MODIFY codpar int(8) NOT NULL DEFAULT '0'; 

ALTER TABLE tiposos 
	MODIFY tiposo varchar(250) NOT NULL DEFAULT '',
	MODIFY idplataforma int(11) NOT NULL DEFAULT '0';

ALTER TABLE tipospar 
	MODIFY codpar int(8) NOT NULL DEFAULT 0,
	MODIFY tipopar varchar(250) NOT NULL DEFAULT '',
	MODIFY clonable tinyint(4) NOT NULL DEFAULT '0';  