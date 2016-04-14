/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Perez
Date: 2016/04/11
Description:



Database: CCenterRia
Required version: 119.01

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 118 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 118 sin fix
set @versionfix = 2
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and @actualVersionFix = @versionfix-1
	begin
		begin tran
		begin try

		set @process = 'Update Labels from menus'
		set @sql='update ccMenus set menu_descrip = ''Cuentas de salida|From Email Addresses'', release = ''dbc8236e42a707b69957a1961fb04ab814ab0f803509bd8ee1cb1ce4ce53b90921ca2afa2fdd6d4b379b739e34b9d570'' where menu_id = 81
update ccMenus set menu_descrip = ''Asociación de cuentas de salida|From Email Addresses Association'', release = ''560ed80e1b20ea34c6507d730c5bf457f1fed7bc7dd97e37ebfd050781c6ec5086d0b6eec2aa79bf1194ad3818fa19d8ebb4c5def239352b188702be9f9ae82c08edd5ac6e4bafaea20ebaa5125dbf1b'' where menu_id = 82
update ccMenus set menu_descrip = ''Firmas de correo|Email Signatures'', release = ''4ac1b8688d4d698a233e8ed87fdb403731fc1fa748d926ce076376f74dc782023846549ea7f469eb9eb2816c3ca594e9'' where menu_id = 84

update ccMenus set menu_descrip = ''Correo|Email'', release = ''7484a0302660b91b91039cc3893f7f41'' where menu_id = 10000
update ccMenus set menu_descrip = ''Correo por ACD|Email by ACD'', release = ''9c6c602297410825b497961460515577b97c3ffaf4fb11ede685651e9e766ed6'' where menu_id = 10010
update ccMenus set menu_descrip = ''Correo por agente|Email by Agent'', release = ''47e34a74d238060569df56743ee7a37b70af8b3463c50698d6d105f76caf167a50fc15bfa36658b439e5649bab19a15d'' where menu_id = 10020
update ccMenus set menu_descrip = ''Detalle de correo|Email Detail'', release = ''02e33a8aa5030f2d6c2a78bb678ce5f294142ffa65b64d6708ef84f005c9cf38'' where menu_id = 10030
update ccMenus set menu_descrip = ''Correo general|Email General'', release = ''f9309f761b4c90b0bf2c6104c668719f72153ec21ed97a023be950c7197458a2'' where menu_id = 10040

update ccMenus set menu_descrip = ''Guion de agentes|Scripting'', release = ''4ffed6b59a7b91b78b12c98b4d855663865935dd4a7cd7f0ef276d059d5d1919'' where menu_id = 72
update ccMenus set menu_descrip = ''Direcciones CC y CCO|CC & BCC Email Addresses'', release = ''09cbbffafe26e97542fa49002c1ec5e68ba515f9cbd9bbc03c547910ac6d73ec802e03cbfc7bceaa52cbfdbbf0396e04'' where menu_id = 85
update ccMenus set menu_descrip = ''Plantillas de multimedios|Multichannel Templates'', release = ''fec74cbaf0b2d7132ee780dabe49895080099c393ebceefb3f21a3efb74960106857e5d4c2ffacf5aced54935e6ee3c55dfbfe9bce82bde21378d3a3b081a702'' where menu_id = 79
update ccMenus set menu_descrip = ''Mensajes automáticos|Automatic Messages'', release = ''6d88ac1ff1c050478fb6151462e81ed619809b45d00e0111d5b6871bd2b894b3de8adfd202942ad8e6026e12c0488685'' where menu_id = 19'
		EXEC(@sql)

	set @process = 'Alter [dbo].[configuraIdiomaCatalogosEspañol]-----'
	set @sql='ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEspañol]
AS
Print ''Iniciando proceso de configuracion en Español''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Semana'' collate SQL_Latin1_General_CP1_CI_AS), 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Nocturno'' collate SQL_Latin1_General_CP1_CI_AS), 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady]
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''No Clasificado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Break'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Tocador'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Con Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Aclaracion'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Junta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Comida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Sistemas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))

DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
TRUNCATE TABLE [dbo].[ccStatusLLamada]
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, convert(text, N''Inicial'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, convert(text, N''Fuera de Horario'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, convert(text, N''Fuera de Servicio'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, convert(text, N''Sin Agentes Firmados'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, convert(text, N''En espera'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, convert(text, N''Colgada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, convert(text, N''Desborde por Tiempo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, convert(text, N''Desborde por Cantidad'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, convert(text, N''Con Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, convert(text, N''Asignada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, convert(text, N''Asignada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, convert(text, N''Atendida Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, convert(text, N''Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, convert(text, N''Cancelada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, convert(text, N''Asignada y No Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, convert(text, N''Asignada y Toma Linea'' collate SQL_Latin1_General_CP1_CI_AS))
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [dbo].[ccTipoDias]
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo resultados de marcacion''
TRUNCATE TABLE [dbo].[ccTipoResultadoDial]
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, convert(text, N''Contestan'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, convert(text, N''Ocupado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, convert(text, N''No Contesta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, convert(text, N''Fax/Modem'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, convert(text, N''NoDialTone'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, convert(text, N''NoService'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, convert(text, N''Buzon/Maquina'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, convert(text, N''Congestion'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de estado de los agentes''
Delete [dbo].[ccTipoStatusAgente]
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, convert(text, N''LogOut'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, convert(text, N''Desconocido'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, convert(text, N''No Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, convert(text, N''Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, convert(text, N''Dialogo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, convert(text, N''Transferencia'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, convert(text, N''Notas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, convert(text, N''Otra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, convert(text, N''Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, convert(text, N''Ringing'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, convert(text, N''Problema'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, convert(text, N''Espera llamada manual'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, convert(text, N''Agente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, convert(text, N''AVRS Calidad'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
SET IDENTITY_INSERT [ccDias] ON
INSERT [ccDias] ([dia_id], [Name]) VALUES (1, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (2, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (3, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (4, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (5, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (6, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (7, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccDias] OFF

Print ''Estableciendo los tipos de llamada''
truncate table cstoTarifa
delete cstoTipoLlamada
declare @country_id tinyint
select @country_id = valor from ccsettings where setting_id = 104

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,1,''Local'',8,''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,2,''LD nacional'',12,''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,3,''Cel'',13,''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,4,''Cel LD'',13,''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,5,''01800'',12,''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,6,''LD usa'',13,''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,7,''LD inter'',0,''00%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, convert(text, N''Carga Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, convert(text, N''Lista Negra en Carga de Registros'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, convert(text, N''Eliminado por Aplicar Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, convert(text, N''Eliminado de Lista Negra por Remplazo '' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, convert(text, N''Borrado de Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, convert(text, N''Solicita información general'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, convert(text, N''Se cortó la llamada'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, convert(text, N''Número equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, convert(text, N''Gestión Efectiva'' collate SQL_Latin1_General_CP1_CI_AS), 0, 0, 1)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, convert(text, N''Se deja recado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 2)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, convert(text, N''Numero Equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [dbo].[cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telmex'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Maxcom'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Avantel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''AT&T'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telnor'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Axtel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telular'')

Print ''Mensajes default chat''
DELETE [dbo].[ccRIAChatInboundMsgs]
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default5'', ''!Bienvenido!'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default3'', ''El servicio no se encuentra disponible'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default2'', ''Nuestro horario de atención ha terminado'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default1'', ''Por favor espere mientras uno de nuestros agentes se encuentra disponible'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default7'', ''No hay agentes disponibles'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default10'', ''No podemos tomar su solicitud'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default12'', ''La sesión de chat ha estado inactiva mucho tiempo'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default13'', ''La sesión de chat ha concluido'')'
		EXEC(@sql)

		set @process = 'Alter [dbo].[configuraIdiomaCatalogosEnglish]-----'
		set @sql='ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEnglish]
AS
Print ''Iniciando proceso de configuracion en Ingles''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Week'', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Night shift'', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Saturday'', 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Sunday'', 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady]
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Not Clasified'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Break'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Bathroom'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''With client'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Supervisor'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Clarification'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Meeting'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Lunch'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Systems'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Other'')

--EXEC sp_generate_inserts ''ccRIANotReadyGraph''
DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
TRUNCATE TABLE [dbo].[ccStatusLLamada]
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, ''Initial'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Out of Schedule'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Out of Service'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''No Agents Logged in'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''On Hold'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandoned'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Time overflow'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Queue size overflow'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''With Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, ''Assigned Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, ''Assigned'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, ''Attended Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, ''Answered'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, ''Canceled Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, ''Assigned and Not Answered'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, ''Assigned and took line'')
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [dbo].[ccTipoDias]
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (1, ''Monday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (2, ''Tuesday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (3, ''Wednesday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (4, ''Thursday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (5, ''Friday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (6, ''Saturday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (7, ''Sunday'')

Print ''Estableciendo resultados de marcacion''
TRUNCATE TABLE [dbo].[ccTipoResultadoDial]
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Answer'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Busy'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Not Answer'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax/Modem'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Other'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, ''NoService'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, ''VoiceMail/Machine'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, ''Circuit busy'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, ''Cancelled'')

Print ''Estableciendo los tipos de estado de los agentes''
DELETE [dbo].[ccTipoStatusAgente]
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, ''LogOut'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, ''Unknown'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, ''Not Ready'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, ''Ready'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, ''Talking'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, ''Transfer'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, ''Wrapup'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, ''Other'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, ''Client'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, ''Ringing'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, ''Problem'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, ''Wait for manual call'')

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, ''Agent'')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, ''Supervisor'')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, ''AVRS Access'')

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
SET IDENTITY_INSERT [dbo].[ccDias] ON
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (1, ''Sunday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (2, ''Monday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (3, ''Tuesday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (4, ''Wednesday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (5, ''Thursday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (6, ''Friday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (7, ''Saturday'')
SET IDENTITY_INSERT [dbo].[ccDias] OFF

truncate table cstoTarifa

Print ''Estableciendo los tipos de llamada''
delete cstoTipoLlamada
declare @country_id tinyint
select @country_id = valor from ccsettings where setting_id = 104
insert into cstoTipoLlamada(country_id,tipoLlamada_id,descrip,longitud,prefijo) values (@country_id,1,''Standard call'', 8, ''%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] ON
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Added to black list'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Blocked on loading'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Removed from campaign'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Replaced from black list'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Deleted from black list'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Added by Disposition'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, ''Load black list'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, ''Load customer black list'')
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, ''Wrong area'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, ''Disconnected call'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, ''Wrong number'', 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, ''Effective call'', 0, 0, 1)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, ''Leave a message'', 0, 1, 2)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, ''Wrong number'', 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [dbo].[cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Carrier 1'')

Print ''Tipo Msg ChatLog'' -- No se hace delete ni truncate ya que se perderia la integridad si ya hay registros, los id ya deberian estar creados por lo cual se genera el update
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes an individual message to agent'' where TipoMsgChat=1
Update ccRIAChat_TipoMsg set MsgDetalle=''Agent writes a message to Administrator'' where TipoMsgChat=2
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes a global message'' where TipoMsgChat=3

Print ''Mensajes defualt''
DELETE [dbo].[ccMsgFiles]
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default5'', ''Welcome message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default4'', ''Transfer message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default3'', ''Out of service message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default2'', ''After hours message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default1'', ''In queue message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default7'', ''No agents signed in message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default9'', ''VoiceMail message'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default10'', ''Overflow message'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default11'', ''DNC list'')

Print ''Mensajes default chat''
DELETE [dbo].[ccRIAChatInboundMsgs]
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default5'', ''Welcome!'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default3'', ''Service currently unavailable'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default2'', ''Our schedule service has finished'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default1'', ''Please hold while one of our agents is available'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default7'', ''There are not available agents'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default10'', ''Your request can not be processed'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default12'', ''Chat session has been inactive for too long'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default13'', ''Chat session has finished'')'
		EXEC(@sql)

		set @process = 'DROP TABLE [dbo].[ccTwitterNode]-----'
		set @sql='if exists(select * from sys.tables where name=''ccTwitterNode'')  DROP TABLE [dbo].[ccTwitterNode]'
		EXEC(@sql)

		set @process = 'DROP PROCEDURE ccsp_CreateNodeMultimedia'
		set @sql='if exists (select * from sys.procedures where name=''ccsp_CreateNodeMultimedia'') DROP PROCEDURE ccsp_CreateNodeMultimedia'
		EXEC(@sql)


		set @process = 'CREATE TABLE -------- mcaTipoLlamada'
		set @sql='if not exists (select * from sys.tables where name = N''mcaTipoLlamada'') begin
CREATE TABLE [dbo].[mcaTipoLlamada](
[tipoLlamada_id] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
[descrip] [varchar](30) NOT NULL,
CONSTRAINT [PK_mcaTipoLlamada] PRIMARY KEY CLUSTERED
(
[tipoLlamada_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]
				 end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -------- mcaProtocolos'
		set @sql='if not exists (select * from sys.tables where name = N''mcaProtocolos'') begin
	CREATE TABLE [dbo].[mcaProtocolos](
	[protocolo_id] [smallint] IDENTITY(1,1) NOT NULL,
	[descrip] [varchar](30) NOT NULL,
	[nota] [varchar] (max)
	CONSTRAINT [PK_mcaProtocolos] PRIMARY KEY CLUSTERED
	(
	[protocolo_id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	) ON [PRIMARY]
 end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -------- mcaProveedores'
		set @sql='if not exists (select * from sys.tables where name = N''mcaProveedores'') begin
	CREATE TABLE [dbo].[mcaProveedores](
	[provedor_id] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[descrip] [varchar](30) NOT NULL,

	CONSTRAINT [PK_mcaProveedores] PRIMARY KEY CLUSTERED
	(
	[provedor_id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON,  FILLFACTOR = 100) ON [PRIMARY]
	) ON [PRIMARY]
 end'
		EXEC(@sql)

		set @process = 'CREATE TABLE --------mcaPlanMarcacion'
		set @sql='if not exists (select * from sys.tables where name = N''mcaPlanMarcacion'') begin
	CREATE TABLE [dbo].[mcaPlanMarcacion](
	[country_id] [smallint] NOT NULL,
	[provedor_id] [smallint] NOT NULL,
	[protocolo_id] [smallint] NOT NULL,
	[tipoLlamada_id] [smallint] NOT NULL,
	[prefijo] [varchar](15) NOT NULL,
	[longitud] [varchar](15) NULL
	CONSTRAINT [PK_mcaPlanMarcacion] PRIMARY KEY CLUSTERED
	(
		[country_id], [provedor_id], [protocolo_id], [tipoLlamada_id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	) ON [PRIMARY]
  end'
		EXEC(@sql)


			set @process = 'CREATE TABLE [dbo].[ccTwitterNode]-----------'
		set @sql='if not exists (select * from sys.tables where name = N''ccTwitterNode'')	begin
	CREATE TABLE [dbo].[ccTwitterNode](
	[conversationTwitterId] [bigint] NOT NULL,
	[node] [xml] NOT NULL,
	[dateIn] [datetime] NOT NULL,
	[dateOut] [datetime] NULL,
	[status] [int] NOT NULL DEFAULT ((0))
	)
end'
		EXEC(@sql)

		set @process = 'ALTER TABLE--------ccRIACat_Areas'
		set @sql='if not exists (select * from sys.columns where name = N''maxTweets'' and Object_ID = Object_ID(N''ccRIACat_Areas'')) ALTER TABLE ccRIACat_Areas ADD maxTweets tinyint null'
		EXEC(@sql)


		set @process = 'ALTER TABLE--------ccoCallsOutSource'
		set @sql='if not exists (select * from sys.columns where name in (N''Region'',''Localidad'') and Object_ID = Object_ID(N''ccoCallsOutSource''))
ALTER TABLE ccoCallsOutSource add Region varchar(20) null,Localidad varchar(20) null'
		EXEC(@sql)



		set @process = 'ALTER TABLE ccTwitterNode -----------------'
		set @sql='ALTER TABLE ccTwitterNode ADD PRIMARY KEY (conversationTwitterId)
ALTER TABLE ccTwitterNode ADD FOREIGN KEY (conversationTwitterId) REFERENCES conversationTwitter(conversationTwitterId)'
		EXEC(@sql)

		set @process = 'CREATE NONCLUSTERED INDEX [IX_ccoCallsOutSource_19]-------'
		set @sql=' if not exists (select * from sys.indexes where name = N''IX_ccoCallsOutSource_19'' and object_id = OBJECT_ID(N''ccoCallsOutSource''))
	begin
		CREATE NONCLUSTERED INDEX [IX_ccoCallsOutSource_19] ON [dbo].[ccoCallsOutSource]
(
	[cal_fechaDial] ASC,
	[cal_status] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

end
'
		EXEC(@sql)


		set @process = 'INSERT -------- ccMenus'
		set @sql ='if not exists(select * from ccmenus where type=3 and menu_id in(4220, 4230, 4240)) begin
	insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, [type], HelpSWF, release ) values (4220, ''Reporte de teléfonos por estado de la república|Telephone report ordered by republic states'', 4000, ''B'', 4, 3, '''', ''60b188045ce43b6a1d77f7a81f67767fc90fbef71d57e4498d362c5c67a3c097d076f2f127f0f7af01beda4ac36008993c52871865dfbcc8d37183f0a429089f59ae97a60b9d269449063e6d38f93222a414d69d2a3fb7b721155619d8e6b4e2'')
	insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, [type], HelpSWF, release ) values (4230, ''Reporte de números telefónicos por registro/lista|Telephone Numbers by RecordList Report'',  4000, ''B'', 4, 3, '''',''94876e9b8b232270fece46d9fc0233a7f810ac1c5ac6c2a03d59c4404e28a0c40eaade12674a111dbfba34cfd4a3efd7c09b538de3ae9891c2ed4b98f2e08acd083c26b7666470d365e856c76e59c751b381635cf60a71915886932047e9227c'')
	insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, [type], HelpSWF, release ) values (4240, ''Reporte de resultados de marcación|Dialing Result Report'', 4000, ''B'', 4, 3, '''', ''9cf7679f1b10838b63e4eae2368159813ae5d3eecaf4bccecfb21a247080897dc3e3d80988c85c0931f5a2fe77da619d446f04bcc6ff01e8247b5531a00ded6b'')
end'
		EXEC(@sql)

		set @process = 'INSERT -------- ccRIACat_AdminPermissions'
		set @sql =' if not exists ( select per_id from ccRIACat_AdminPermissions where per_id = 9 )
		insert into ccRIACat_AdminPermissions (per_desc,bstatus,release)	values (''Ver reportes por grupo|Access reports by workgroup'',''1'',''4fa74acb1f6a68e4c30f0b01ff93a04445c80efab455828ae88f15b70332f27f3280b2a147b0891eee145e736b46afcec1e9a93d16f405f9e7076fbc55dd05db'')'
		EXEC(@sql)


		set @process = 'INSERT -------- mcaTipoLlamada'
		set @sql='if not exists(select * from mcaTipoLlamada where tipoLlamada_id in(1, 2, 3, 4)) begin
	insert into mcaTipoLlamada (descrip) values (''Local'')
	insert into mcaTipoLlamada (descrip) values (''LD Nacional'')
	insert into mcaTipoLlamada (descrip) values (''Cel'')
	insert into mcaTipoLlamada (descrip) values (''Cel LD'')
 end'
		EXEC(@sql)

		set @process = 'INSERT -------- mcaProveedores'
		set @sql='if not exists(select * from mcaProveedores where provedor_id in(1, 2, 3)) begin
	INSERT INTO [dbo].[mcaProveedores] ([descrip]) VALUES (N''Maxcom'')
	INSERT INTO [dbo].[mcaProveedores] ([descrip]) VALUES (N''Marcatel'')
	INSERT INTO [dbo].[mcaProveedores] ([descrip]) VALUES (N''Telmex'')
 end'
		EXEC(@sql)

		set @process = 'INSERT -------- mcaProtocolos'
		set @sql='if not exists(select * from mcaProtocolos where protocolo_id in(1, 2, 3, 4, 5)) begin
	INSERT INTO [dbo].[mcaProtocolos] ([descrip]) VALUES (N''ISDN sin ANI Rotatorio'')
	INSERT INTO [dbo].[mcaProtocolos] ([descrip], [nota]) VALUES (N''ISDN con Ani Rotatorio'', ''En las ciudades con LADA donde Maxcom tiene numeración los números celulares van como locales, para las ciudades Monterrey, GDl y DF solo se toman 2 dígitos de la lada'')
	INSERT INTO [dbo].[mcaProtocolos] ([descrip]) VALUES (N''SIP sin Ani Rotatorio'')
	INSERT INTO [dbo].[mcaProtocolos] ([descrip], [nota]) VALUES (N''SIP con Ani Rotatorio'', ''En las ciudades con LADA donde Maxcom tiene numeración los números celulares van como locales, para las ciudades Monterrey, GDl y DF solo se toman 2 dígitos de la lada'')
	INSERT INTO [dbo].[mcaProtocolos] ([descrip]) VALUES (N''R2'')
 end'
		EXEC(@sql)

		set @process = 'insert into ccFinderServices------------'
		set @sql='if not exists(select * from ccFinderServices where ref=''R04'') begin
	insert into ccFinderServices(name,ref) values(''Twitter'',''R04'')
end'
		EXEC(@sql)

		set @process = 'INSERT -------- mcaPlanMarcacion'
		set @sql='if not exists(select * from mcaPlanMarcacion where protocolo_id in(1, 2, 3, 4, 5) and tipoLlamada_id in (1, 2, 3, 4, 5)) begin
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 1, 1, ''%'', ''7'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 2, 1, ''%'', ''10'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 3, 1, ''%'', ''10'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 4, 1, ''%'', ''10'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 5, 1, ''%'', ''7'')

	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 1, 2, ''01%'', ''12'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 2, 2, ''%'', ''10'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 3, 2, ''01%'', ''12'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 4, 2, ''%'', ''10'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 5, 2, ''01%'', ''12'')

	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 1, 3, ''044%'', ''13'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 2, 3, ''044%'', ''13'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 3, 3, ''044%'', ''13'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 4, 3, ''044%'', ''13'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 5, 3, ''044%'', ''13'')

	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 1, 4, ''045%'', ''13'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 2, 4, ''045%'', ''13'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 3, 4, ''045%'', ''13'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 4, 4, ''045%'', ''13'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 1, 5, 4, ''045%'', ''13'')

	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 2, 3, 1, ''%'', ''10'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 2, 3, 2, ''01%'', ''12'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 2, 3, 3, ''044%'', ''13'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 2, 3, 4, ''045%'', ''13'')

	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 3, 5, 1, ''%'', ''7'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 3, 5, 2, ''01%'', ''12'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 3, 5, 3, ''044%'', ''13'')
	insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
	values (1, 3, 5, 4, ''045%'', ''13'')
 end'
		EXEC(@sql)

		set @process = 'ALTER TABLE--------xxClienteCarga'
		set @sql='if not exists (select * from sys.columns where name = N''proveedor'' and Object_ID = Object_ID(N''xxClienteCarga'')) alter table xxClienteCarga add proveedor int null
				  if not exists (select * from sys.columns where name = N''protocolo'' and Object_ID = Object_ID(N''xxClienteCarga'')) alter table xxClienteCarga add protocolo int null'
		EXEC(@sql)



		set @process = 'Alter SP -- ccsp_NetworkSocialAdminAccount'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_NetworkSocialAdminAccount]
@action int,
@meanContactTypeId smallint = 2,
@contactMeanId int=0,
@name	varchar(30)=null,
@conexionInfo	varchar(255)=null,
@inboundId	int=0,
@connUser	varchar(60)=null,
@ConnPass	varchar(30)=null,
@numMessages	tinyint=null,
@timeAlertMessage	tinyint=null,
@isActive bit =null,
@UserId int =null,
@idArea smallint =null,
@maxMails tinyint =3,
@answerTimeOut tinyint=null,
@revisionTime varchar(10)=null,
@daysTwitterRecord varchar(10)=null,
@closeConversationTime varchar(10)=null
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

declare @isActiveMail bit
set @isActiveMail=0

if @action = 1 begin--insert account twitter account
	DECLARE @tableConexionInfo TABLE(  id int, value varchar(255))
	if exists(select * from ContactMeanIn where conexionInfo = @conexionInfo and meanContactTypeId=@meanContactTypeId and inboundId<>@inboundId) begin
		select 0, ''Error: acount already exists''
		return -1
	end
	if not exists(select * from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId) begin
	if @name is null set @name=''''
		--if @conexionInfo is null set @conexionInfo=''''
		if @connUser is null set @connUser=''''
		if @connPass is null set @connPass=''''
		if @numMessages is null set @numMessages=3
		if @timeAlertMessage is null set @timeAlertMessage=5
		if @isActive is null set @isActive=0
		if @answerTimeOut is null set @answerTimeOut=0
		if @closeConversationTime is null set @closeConversationTime=3

		--Twitter deja los token
		--conexion Info usuarioID|token|tokenSecret|time|daysTwitterRecord
		if @meanContactTypeId= 2 begin

			if @conexionInfo is null begin
				set @conexionInfo=''usuarioID|token|tokenSecret''
				set @revisionTime=isnull(@revisionTime,''1'')
				set @daysTwitterRecord=isnull(@daysTwitterRecord,''0'')
			end
			else begin
			select @conexionInfo
				insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
				set @conexionInfo=null

				SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

				SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
				SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
				SELECT @closeConversationTime=  isnull(@closeConversationTime,isnull(max(value),''3'')) FROM @tableConexionInfo where id=6
			end
			set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
		end


		insert into ContactMeanIn (meanContactTypeId,name,conexionInfo,inboundId,connUser,ConnPass,numMessages,timeAlertMessage,isActive,answerTimeOut,closeConversationTime)
				values (@meanContactTypeId,@name,@conexionInfo,@inboundId,@connUser,@connPass,@numMessages,@timeAlertMessage,@isActive,@answerTimeOut,@closeConversationTime)
		select 1,''insert''
	end
	else begin
		select @conexionInfo = isnull(@conexionInfo,conexionInfo),@connUser= isnull(@connUser,connUser),@connPass= isnull(@connPass,ConnPass),
				@numMessages= isnull(@numMessages,numMessages),@timeAlertMessage= isnull(@timeAlertMessage,timeAlertMessage),@isActive= isnull(@isActive,isActive),
				@answerTimeOut= isnull(@answerTimeOut,answerTimeOut),@name=isnull(@name,name),@closeConversationTime=isnull(@closeConversationTime,closeConversationTime)
				from ContactMeanIn where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId

		--Twitter deja los token
		if @meanContactTypeId= 2 begin
			--usuarioID|token|tokenSecret|time|daysTwitterRecord|closeConversation
			insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
			set @conexionInfo=null

			SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

			SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
			SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5

			set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
		end



		update ContactMeanIn set name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,
			numMessages=@numMessages,timeAlertMessage=@timeAlertMessage,isActive=@isActive,answerTimeOut=@answerTimeOut,
			closeConversationTime=@closeConversationTime
			where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
		select 1,''update''
	end
end
else if @action = 2 begin
	if @inboundId=0
		select inboundId,conexionInfo,connUser,ConnPass,isActive,name from contactMeanIn where meanContactTypeId=@meanContactTypeId and isActive=1
	else
		select inboundId,conexionInfo,connUser,ConnPass,isActive,name from contactMeanIn where meanContactTypeId=@meanContactTypeId and isActive=1 and inboundId=@inboundId
end
else if @action = 3 begin
	select A.name,A.connUser,A.numMessages,A.timeAlertMessage,A.answerTimeOut ,B.tNotas,B.descripcion,C.graphic_id,D.frame
	from ContactMeanIn A
	inner join ccinbound B on A.inboundId=B.Inbound_id
	inner join ccRIAinboundGraph C on C.Inbound_id=B.Inbound_id
	inner join ccRIAGraphics D on D.graphic_id=C.graphic_id
	where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action=4 begin
	--Estos es para Twitter
	--usuarioID|token|tokenSecret|time|daysTwitterRecord
	select isnull(max(conexionInfo),''usuarioID|token|tokenSecret|1|0'') from contactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
END'
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_RIAConfEspec'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec]
@User_id int
AS
set nocount on
/****
Conexion Info Email In
	protocol|server|ssl|port|cleanMail|revisionTime
Conexion Info Email Out
	serverOut|portOut|tls|sslOut
Conexion Info Twitter
	usuarioID|token|tokenSecret|time|daysTwitterRecord
***/
select  A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd,
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat mode, A.inactiveChatTime, A.maxChats, isnull(A.chatDomain,'''') chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
isnull(A.startStopRecording,0) startStopRecording
,isnull(B.name,'''') as nameMail,isnull(B.conexionInfo,'''') as conexionInfo,isnull(B.connUser,'''') as connUser,
isnull(B.ConnPass,'''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage,
isnull(B.IsActive,0) as Active, isnull(B.answerTimeOut,0) as answerTimeOut,A.callBackSurveyAgent,A.callBackSurveyClient,
case when C.CallsBySurvey is null or C.CallsBySurvey = 0 then 0 else 1 end isRelationSurvey,
isnull(nameTwitter,'''') nameTwitter,isnull(userTwitter,'''') userTwitter,isnull(numMessagesTwitter,3) numMessagesTwitter,
isnull(timeAlertMessageTwitter,10) timeAlertMessageTwitter,isnull(ActiveTwitter,0) ActiveTwitter,isnull(answerTimeOutTwitter,10) answerTimeOutTwitter,
--usuarioID|token|tokenSecret|time|daysTwitterRecord
isnull(conexionInfoTwitter,''usuarioID|token|tokenSecret|1|0'') conexionInfoTwitter
,isnull(closeConversationTimeTwitter,3) closeConversationTimeTwitter,isnull(closeConversationTime,3) closeConversationTimeEmail
from ccInbound A
left join ContactMeanIn B on A.inbound_id=B.inboundId and B.meanContactTypeId=1
left join ccCamps C on C.cam_id=A.cam_id
left join (
select D.inboundId,
D.name as nameTwitter,D.connUser as userTwitter,D.numMessages as numMessagesTwitter,
D.timeAlertMessage as timeAlertMessageTwitter,
D.IsActive as ActiveTwitter, D.answerTimeOut as answerTimeOutTwitter,D.conexionInfo as conexionInfoTwitter,
closeConversationTime as  closeConversationTimeTwitter
from ContactMeanIn D
where D.meanContactTypeId=2) D on A.Inbound_id=D.inboundId
where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 4))
return(0)
set nocount off'
		EXEC(@sql)


		set @process = 'Alter SP -- ccsp_TwitterInitialStatistics'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_TwitterInitialStatistics]
@inboundId int=0,
@Option AS SMALLINT=0,
@User_id AS SMALLINT=0
AS
BEGIN

	SET NOCOUNT ON;

	if(@Option=0)
	begin
		select
		count(*) received,
		count(case when messageStatusId = 1 then 1 else null end) pending,
		count(case when messageStatusId in (2,3) then 1 else null end) assigned,
		count(case when messageStatusId = 4 then 1 else null end) unassigned,
		count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
		count(case when messageStatusId = 7 then 1 else null end) rejected,
		count(case when messageStatusId = 8 then 1 else null end) programFwd,
		count(case when messageStatusId = 9 then 1 else null end) forwarding,
		count(case when messageStatusId in (10,11) then 1 else null end) closed,
		count(case when messageStatusId = 3 then 1 else null end) active ,
		isnull(AVG(msg.twait + msg.tretention + msg.tresponse),0) avgtAtention,
		isnull(AVG(msg.twait),0) avgtWait,
		isnull(MAX(msg.twait),0) maxtWait
		from messageOutTwitter msg(nolock) join conversationTwitter con (nolock) on con.conversationTwitterId=msg.conversationTwitterId
		where inboundId=@inboundId --and [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121)
		and ( messageStatusId in (1,4) or [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121) )
	end
	if @Option = 1
	BEGIN
		select
		count(*) received,
		count(case when messageStatusId = 1 then 1 else null end) pending,
		count(case when messageStatusId in (2,3) then 1 else null end) assigned,
		count(case when messageStatusId = 4 then 1 else null end) unassigned,
		count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
		count(case when messageStatusId = 7 then 1 else null end) rejected,
		count(case when messageStatusId = 8 then 1 else null end) programFwd,
		count(case when messageStatusId = 9 then 1 else null end) forwarding,
		count(case when messageStatusId in (10,11) then 1 else null end) closed,
		count(case when messageStatusId = 3 then 1 else null end) active ,
		isnull(AVG(msg.twait + msg.tretention + msg.tresponse),0) avgtAtention,
		isnull(AVG(msg.twait),0) avgtWait,
		isnull(MAX(msg.twait),0) maxtWait,
		InboundId inboundId
		from messageOutTwitter msg (nolock) join conversationTwitter con (nolock) on con.conversationTwitterId=msg.conversationTwitterId
		where inboundId in (select inbound_id from ccInbound where inbound_id in (SELECT cam_id FROM ccSupervisorCam WHERE user_id = @User_id AND tipo = 0) and chat = 4)
		and ( messageStatusId in (1,4) or [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121) )
		GROUP BY InboundId
	END
END'
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_TwitterSave'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_TwitterSave]
 @action int,
 @conversationId int=0,
 @messageOutTwitterId bigint=null,
 @userId int=0,
 @isLogout bit=0,
 @messageId int =null,
 @messageStatusId int=null,
 @inboundId smallint=null,
 @twitId varchar(255)=null,
 @dispositionId smallint=0,
 @subDispositionId smallint=0,
 @timeAtt int = 0,
 @tWrapUp int =0,
 @tRetention int = 0
AS
BEGIN

declare @meanContactTypeId smallint
declare @isEndConversation bit

set @meanContactTypeId = 2 --Twitter


 if @action = 1 BEGIN  -- desasignar
	if @messageOutTwitterId = 0 begin
		insert into [messageUnAssingedTwit](messageOutTwitterId,userId,[time],isLogout)
		select messageOutTwitterId,userId,datediff(ss,tQueue,getdate()) as [time],1 from [messageOutTwitter]  where userId=@userId and messageStatusId in (2,3)

		update [messageOutTwitter] set twitId='''',tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0 where userId=@userId and messageStatusId in (2,3)
	end
	else begin
		insert into [messageUnAssingedTwit](messageOutTwitterId,userId,[time],isLogout)
		select messageOutTwitterId,userId,datediff(ss,tQueue,getdate()) as [time],0 as isLogout from [messageOutTwitter] where userId=@userId and messageOutTwitterId=@messageOutTwitterId and messageStatusId in (2,3)

		update [messageOutTwitter] set twitId='''',tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0 where userId=@userId and messageOutTwitterId=@messageOutTwitterId and messageStatusId in (2,3)
	end
END
else if @action = 2 begin --Coloca el valor del TwitId
	update [messageOutTwitter] set twitId=@twitId where messageOutTwitterId=@messageOutTwitterId
end
else if @action = 5 BEGIN --Twitter por contestar
	--Status DOWNLOAD,Assigned,READ,UnaSSIGNED
	select A.conversationTwitterId,B.userId,A.screenNameClient,A.screenNameInbound,B.messageStatusId,max(B.messageOutTwitterId) as messageId
		from conversationTwitter A
		inner join [messageoutTwitter] B on A.conversationTwitterId = B.conversationTwitterId
		where A.inboundId = @inboundId and B.messageStatusId in(1,2,3,4) and meanContactTypeId = @meanContactTypeId
		GROUP BY A.conversationTwitterId,A.inboundId,A.screenNameClient,A.screenNameInbound,B.messageStatusId,B.userId
END
else if @action = 6 BEGIN --update Time Attention, Retencion
	select @messageId=max(messageOutTwitterId) from messageOutTwitter with(nolock) where conversationTwitterId=@conversationId
	update messageOutTwitter set tResponse=@timeAtt,tRetention=@tRetention,isSender=1,messageStatusId=@messageStatusId where messageOutTwitterId=@messageId
END
else if @action = 7 BEGIN --Cambia el status del mensaje
	select @messageId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId

	--Status Read
	if @messageStatusId=3  update [messageOutTwitter] set tWait=DATEDIFF(ss,tQueue, getdate()) where messageOutTwitterId=@messageId
	--Status Send
	if @messageStatusId=6  begin
		select @isEndConversation=isFinished from conversationTwitter where conversationTwitterId=@conversationId

		if @isEndConversation = 1 set @messageStatusId=11--Close conversation by Agent
		update [messageOutTwitter] set tSend=getdate() where messageOutTwitterId=@messageId

	end
	update [messageOutTwitter] set messageStatusId=@messageStatusId where messageOutTwitterId=@messageId
END
else if @action = 10 begin --Carga las conversaciones pendientes
	if @conversationId = 0 begin
		select A.conversationTwitterId,max(B.messageOutTwitterId) as messageId,B.userId,A.inboundId,max(C.twitId) as twitId
			from conversationTwitter A
			inner join messageOutTwitter B on A.conversationTwitterId = B.conversationTwitterId
			inner join messageInTwitter C on C.conversationTwitterId=B.conversationTwitterId
			where A.meanContactTypeId = @meanContactTypeId
			and B.messageStatusId in(5,7,8,9) and isSender=1 and A.inboundId=@inboundId
			GROUP BY A.conversationTwitterId,A.inboundId,B.userId
	end
	else begin
	select A.conversationTwitterId,max(B.messageOutTwitterId) as messageId,B.userId,A.inboundId,max(C.twitId) as twitId
			from conversationTwitter A
			inner join messageOutTwitter B on A.conversationTwitterId = B.conversationTwitterId
			inner join messageInTwitter C on C.conversationTwitterId=B.conversationTwitterId
			where A.meanContactTypeId = @meanContactTypeId
			and A.conversationTwitterId = @conversationId
			GROUP BY A.conversationTwitterId,A.inboundId,B.userId
	end
end
else if @action = 11 BEGIN --Califica el mensaje y pone el tiempo Notas
	if @subDispositionId <> 0 begin
		select @isEndConversation=isnull(EndConversation,0) from ccTipoCalifSub where califSub_id=@subDispositionId
	end
	else begin
		select @isEndConversation=isnull(EndConversation,0) from cctipoCalif where calif_id=@dispositionId
	end
	if not exists(select * from relationMessageDispositionTwit where messageOutTwitterId=@messageId) begin
		insert into relationMessageDispositionTwit(messageOutTwitterId,dispositionId,subDispositionId) values(@messageId,@dispositionId,@subDispositionId)
	end
	else begin
		update relationMessageDispositionTwit set dispositionId=@dispositionId,subDispositionId=@subDispositionId where messageOutTwitterId=@messageId
	end
	update [messageOutTwitter] set tWrapUp=@tWrapUp where messageOutTwitterId=@messageId
	if @isEndConversation = 1 begin
		select @conversationId=conversationTwitterId from [messageOutTwitter]where messageOutTwitterId=@messageId
		update conversationTwitter set isFinished=@isEndConversation where conversationTwitterId=@conversationId
	end
END
else if @action = 12 BEGIN  --Tiempo de cola
	select @messageId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId
	update [messageOutTwitter] set tQueue=getdate(),userId=@userId where messageOutTwitterId=@messageId
END
else if @action = 13 BEGIN  --Limpia las conversaciones quedaron abiertas por cerrar la aplicacion
	update [messageoutTwitter] set @messageStatusId=1,twitId='''',tQueue=null,userId=0,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0  where messageStatusId in(2,3)
END

END'
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_RIA_ABCAreas'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas]
@option smallint,
@IDArea smallint,
@Descripcion varchar(40),
@maxMails smallint = 3,
@maxChats smallint = 3,
@maxTweets smallint = 3
AS

set nocount on

if @option=1 --Selected Area
begin
 Select a.IDArea, AreaName, isnull(a.maxChats,0) as maxChats, isnull(maxMails,3) maxMails,
 isnull(users,0) users, isnull(admins,0) admins,
 isnull(camps,0) camps, isnull(acds,0) acds  ,isnull(a.maxTweets,3) as maxTweets
 from ccRIACat_Areas a (nolock)
 left join (select IDArea , MAX(isnull(maxChats,0)) as maxChats from ccInbound GROUP BY IDArea) b on a.IDArea = b.IDArea
 left join (select IDArea,count(case when TipoUser_id = 1 then 1 else null end) users, count(case when TipoUser_id > 1 then 1 else null end) admins from ccusers (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) userswg on userswg.IDArea=a.IDArea
 left join (select IDArea,count(*) acds from ccinbound (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) acdswg on acdswg.IDArea=a.IDArea
 left join (select IDArea,count(*) camps from cccamps (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) campswg on campswg.IDArea=a.IDArea
 where StatusArea=1 and isnull(a.IDArea,0)=case isnull(@IDArea,0)
 when 0 then isnull(a.IDArea,0) else @IDArea end
 order by AreaName

 return(0)
end

if @option=2 --Insert Area
begin
 if exists(select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
 begin
  select -1--, Nombre en Uso
  return(0)
 end

 Insert into ccRIACat_Areas (AreaName,maxMails,maxChats,maxTweets) values (@Descripcion,@maxMails,@maxChats,@maxTweets)

 select 1, scope_identity()--, Area Insertada
 return(0)
end

if @option=3 --Update Area
begin
 if not exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
  Update ccRIACat_Areas set AreaName=@Descripcion,maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets where IDArea=@IDArea
 else
  Update ccRIACat_Areas set maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets where IDArea=@IDArea

 if (select max(maxChats) as maxChats from ccinbound where IDArea=@IDArea) <> @maxChats
  Update ccinbound set maxChats=@maxChats where IDArea=@IDArea

 return(0)
end

if @option=4 --Delete Area
begin
 if (exists(select IDArea from ccUsers where IDArea=@IDArea) or exists(select IDArea from ccCamps where IDArea = @IDArea)
  or exists(select IDArea from ccInbound where IDArea=@IDArea)) and (select valor from ccSettings where setting_id=95)<>1
 begin
  select -1
  return(0)
 end

 declare @DWorkGroups as varchar(500)

 insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
 select user_id,cam_id,prioridad,skill,rel_id,IDWG
 from ccCampsAgente
 where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

 insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
 select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
 from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

 Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)
 Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

 insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
 select user_id,cam_id,tipo,IDWG,monitored
 from ccSupervisorCam
 where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

 Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

 delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
 delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
 delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
 where cam_id in (select cam_id from ccCamps where IDArea=@IDArea))

 Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)
 Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)

 Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
 Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
 Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)

 select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea=@IDArea
 Delete from ccRIAAreaWorkGroup where IDArea=@IDArea

 if (select valor from ccSettings where setting_id=95)=1
 begin
  Update ccInbound set IDArea=NULL, status=0 where IDArea=@IDArea
  Update ccCamps set IDArea=NULL where IDArea=@IDArea
  Update ccUsers set IDArea=NULL where IDArea=@IDArea
 end

 Update ccRIACat_Areas set StatusArea=0 where IDArea=@IDArea

 select @DWorkGroups

 return(0)
end'
		EXEC(@sql)

		set @process = 'CREATE Function -- [VerificaRegionLocalidad]'
		set @sql='CREATE FUNCTION [dbo].[VerificaRegionLocalidad](@tel varchar(32))
RETURNS @retVRL TABLE
(
    tel varchar(32) PRIMARY KEY NOT NULL,
    region varchar(32) NULL,
    localidad varchar(32) NULL
)
 BEGIN
 declare @ld varchar(7)
 declare @lon tinyint
 declare @result tinyint
 declare @mod varchar(10)
 declare @Cadena varchar(32)
 declare @region varchar(20)
 declare @localidad varchar(20)
 declare @cldLocal varchar(7)
 declare @pais tinyint

 select @cldLocal = valor from ccsettings with(nolock) where setting_id = 17
 select @pais = valor from ccSettings with(nolock) where setting_id = 104

 select @tel = dbo.limpia(@tel)

 if @pais = 1 begin --Empieza Mexico
  select @lon = len(@tel)
  if @lon between 7 and 8 begin
   set @tel = @cldLocal + @tel
  end
  select @tel = right(@tel, 10)
  select @lon = len(@tel)

  if @lon = 10 begin

   if(exists(select top 1 cld from series nolock where cld=left(@tel,2)))begin
    select @ld = left(@tel,2)
    select @region = estado, @localidad = municipio from series nolock where cld=left(@tel,2)
    end
   else if(exists(select top 1 cld from series nolock where cld=left(@tel,3)))  begin
    select @ld = left(@tel,3)
    select @region = estado, @localidad = municipio from series nolock where cld=left(@tel,3)
    end
   else  begin
   if (@region is null) begin
 select @region = estado from series nolock where cld=@cldLocal
 end
   INSERT @retVRL
        SELECT @tel, @region, @localidad
 RETURN
   end
  end
end --Termina Mexico

  INSERT @retVRL
        SELECT @tel, @region, @localidad
  RETURN

end'
		EXEC(@sql)


		set @process = 'CREATE SP -- ccsp_CreateNodeMultimedia'
		set @sql='CREATE PROCEDURE [dbo].[ccsp_CreateNodeMultimedia]
@conversationId bigint,
@xml xml OUTPUT,
@supervisor varchar(255)='''',
@template varchar (255)='''',
@ScoreTemplate int=0,
@type int =1--1 EMAIL , 2 Twitter
AS
BEGIN

--SET @conversationId=16
declare @existAttached bit,@numInteracion smallint
if @type=0 begin--CHAT

	   select @xml = convert(xml,''<R01 C01="''+convert(varchar(max),chatId) +
	   ''" C02="''+convert(varchar(max),isnull(ccinbound.descripcion,'''')) +
	   ''" C03="''+convert(varchar(max),domain) +
	   ''" C04="''+convert(varchar(max), Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno ) +
       ''" C05="''+convert(varchar(max),tchatting) +
	   ''" C06="''+convert(varchar(max),isnull(cctipocalif.[Description],''N/A'')) +
	   ''" C07="''+convert(varchar(max),isnull(cctipocalifsub.califSubdesc,''N/A'')) +
	   ''" C08="''+convert(varchar(max),clientname) +
	   ''" C09="''+rtrim(ltrim(convert(varchar(23), chatDate, 126))) +
	   ''" C10="''+convert(varchar(max),isnull(@supervisor,'''') ) +
	   ''" C11="''+convert(varchar(max),isnull(@template,'''') )  +
	   ''" C12="''+convert(varchar(max),isnull(@ScoreTemplate,0)) +
	   ''" C13="''+convert(varchar(max),isnull(ccusers.[Login],'''')) + ''"/>'')
       from ccRIAChats
       left outer join ccinbound on ccinbound.inbound_id = ccRIAChats.inboundid
       left outer join ccusers on ccusers.user_id = ccRIAChats.userid
       left outer join cctipocalif on cctipocalif.calif_id = ccRIAChats.disposition
       left outer join cctipocalifsub on cctipocalifsub.califsub_id = ccRIAChats.subdisposition and ccRIAChats.subdisposition <> 0
       where chatId = @conversationId and chatStatus = 4 and requestDate is not null and chatDate is not null

end
else if @type=1 begin--EMAIL
	SELECT @existAttached = case when count(*)>0 then 1 else 0 end
	from attached where messageId in (select messageId from message where conversationId=@conversationId)
	select @numInteracion = count(*) from message where conversationId=@conversationId


	select @xml = convert(xml,''<R03 C01="''+ convert(varchar(max),a.conversationId) +
	''" C02="''+rtrim(ltrim(convert(varchar(23), min(b.date), 126))) +
	''" C03="''+convert(varchar(max),max(c.descripcion)) +
	''" C04="''+ convert(varchar,max(isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno,''''))) +
	''" C05="''+convert(varchar,max(isnull(cctipocalif.[Description],''N/A''))) +
	''" C06="''+ convert(varchar,max(replace(replace(a.mailClient,''<'','' ''),''>'','' ''))) +
	''" C07="''+convert(varchar(max),sum(b.tRetention+b.tResponse+b.tWrapup)) +''" C08="''+ max(a.info) +
	''" C09="''+convert(varchar(max),max(b.messageStatusid) ) +''" C10="''+  convert(varchar(max), isnull(@numInteracion,0)) +
	''" C11="''+convert(varchar(max),@existAttached) +''" C12="''+ convert(varchar(max),isnull(@supervisor,'''') ) +
	''" C13="''+convert(varchar(max),isnull(@template,'''') )  +''" C14="''+convert(varchar(max),isnull(@ScoreTemplate,0)) +
	''" C15="''+ convert(varchar,max(isnull(cctipocalifsub.califSubdesc,''N/A''))) +
	''" C16="''+convert(varchar(max),isnull(max(d.[Login]),'''')) + ''"/>'')
	from conversation a
	inner join message b on a.conversationid=b.conversationid
	left outer join ccinbound c on c.inbound_id = a.inboundid
	left outer join ccusers d on d.user_id = b.userid
	left outer join relationmessageDisposition e on e.messageId=b.messageId
	left outer join cctipocalif on cctipocalif.calif_id = e.dispositionId
	left outer join cctipocalifsub on cctipocalifsub.califsub_id = e.subdispositionId and e.subdispositionId <> 0
	where a.conversationId=@conversationId
	group by a.conversationId,a.inboundid
end
else if @type=2 begin--Twitter
	select @numInteracion = sum(ninteration) from messageOutTwitter where conversationTwitterId=@conversationId

	select @xml = convert(xml,''<R04  C01="''+convert(varchar(max),a.conversationTwitterId) +
	''" C02="''+rtrim(ltrim(convert(varchar(23), min(b.date), 126))) +
	''" C03="''+convert(varchar(max),max(c.descripcion)) +
	''" C04="''+ convert(varchar,max(isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno,''''))) +
	''" C05="''+convert(varchar,max(isnull(cctipocalif.[Description],''N/A''))) +
	''" C06="''+ max(a.screenNameClient) +
	''" C07="''+convert(varchar(max),sum(b.tRetention+b.tResponse+b.tWrapup)) +
	''" C08="''+ max(a.screenNameInbound) +
	''" C09="''+convert(varchar(max),max(b.messageStatusid) ) +
	''" C10="''+  convert(varchar(max), isnull(@numInteracion,0)) +
	''" C11="''+ convert(varchar(max),isnull(@supervisor,'''') ) +
	''" C12="''+convert(varchar(max),isnull(@template,''''))  +
	''" C13="''+convert(varchar(max),isnull(@ScoreTemplate,0)) +
	''" C14="''+ convert(varchar,max(isnull(cctipocalifsub.califSubdesc,''N/A''))) +
	''" C15="''+convert(varchar(max),isnull(max(d.[Login]),'''')) + ''"/>'')
	from conversationTwitter a
	inner join messageOutTwitter b on a.conversationTwitterId=b.conversationTwitterId
	left outer join ccinbound c on c.inbound_id = a.inboundid
	left outer join ccusers d on d.user_id = b.userid
	left outer join relationmessageDisposition e on e.messageId=b.messageOutTwitterId
	left outer join cctipocalif on cctipocalif.calif_id = e.dispositionId
	left outer join cctipocalifsub on cctipocalifsub.califsub_id = e.subdispositionId and e.subdispositionId <> 0
	where a.conversationTwitterId=@conversationId
	group by a.conversationTwitterId,a.inboundid
end

--print convert(nvarchar(1000),@xml)
--select @xml
END'
		EXEC(@sql)

	set @process = 'Alter SP -- ccsp_MailAdminAccount'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_MailAdminAccount]
@action int,
@meanContactTypeId smallint = 1,
@contactMeanId int=0,
@name	varchar(30)=null,
@conexionInfo	varchar(255)=null,
@inboundId	int=0,
@connUser	varchar(60)=null,
@ConnPass	varchar(30)=null,
@numMessages	tinyint=null,
@timeAlertMessage	tinyint=null,
@isActive bit =null,
@UserId int =null,
@idArea smallint =null,
@maxMails tinyint =3,
@answerTimeOut tinyint=null,
@revisionTime varchar(10)=null,
@daysTwitterRecord varchar(10)=null,
@closeConversationTime varchar(10)=null
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

SET NOCOUNT ON;
/****
Conexion Info Email In
	protocol|server|ssl|port|cleanMail|revisionTime
Conexion Info Email Out
	serverOut|portOut|tls|sslOut
Conexion Info Twitter
	usuarioID|token|tokenSecret|time|daysTwitterRecord
***/


declare @isActiveMail bit
set @isActiveMail=0

if @action = 1 begin --checha si esta activo el servicio
	select @isActiveMail = valor from ccSettings where setting_id=152
	if @isActiveMail = 1 begin
		select @isActiveMail=(case when isActive = 1 and @isActiveMail = 1 then 1 else 0 end) from meanContactType where meanContactTypeId = 1
	end
	select @isActiveMail as isActiveMail
	return (0)
end
else if @action = 2 begin -- carga la relacion de especialidades y cuentas de email de entrada
	select A.inboundId,A.conexionInfo,A.connUser,A.connPass, A.isActive
		from ContactMeanIn A
			inner join ccInbound B on A.inboundId=B.Inbound_Id
		where meanContactTypeId = @meanContactTypeId and B.Status=1 and A.isActive=1
end
else if @action = 3 begin	--
	select name,conexionInfo,connUser,ConnPass,numMessages,timeAlertMessage,answerTimeOut from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 4 begin--insert or update relation mail whit ACD by in
	---Es necesario cambiar [ccsp_NetworkSocialAdminAccount] por que tambien se ocupa aqui
	DECLARE @tableConexionInfo TABLE(  id int, value varchar(255))
	if @connUser='''' 	set @connUser=''nuxiba@nuxiba.com''
	if not exists(select * from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId) begin
		if not exists(select * from ContactMeanIn where connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin
		if @name is null set @name=''''
		if @conexionInfo is null and @meanContactTypeId=1  set @conexionInfo=''''
		if @connUser is null set @connUser=''''
		if @connPass is null set @connPass=''''
		if @numMessages is null set @numMessages=3
		if @timeAlertMessage is null set @timeAlertMessage=5
		if @isActive is null set @isActive=0
		if @answerTimeOut is null set @answerTimeOut=0
		if @closeConversationTime is null set @closeConversationTime=3

		--Twitter deja los token
		--conexion Info usuarioID|token|tokenSecret|time|daysTwitterRecord
		if @meanContactTypeId= 2 begin

			if @conexionInfo is null begin
				set @conexionInfo=''usuarioID|token|tokenSecret''
				set @revisionTime=isnull(@revisionTime,''1'')
				set @daysTwitterRecord=isnull(@daysTwitterRecord,''0'')
			end
			else begin
			select @conexionInfo
				insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
				set @conexionInfo=null

				SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

				SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
				SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
			end
			set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
		end



		insert into ContactMeanIn (meanContactTypeId,name,conexionInfo,inboundId,connUser,ConnPass,numMessages,timeAlertMessage,isActive,answerTimeOut,closeConversationTime)
				values (@meanContactTypeId,@name,@conexionInfo,@inboundId,@connUser,@connPass,@numMessages,@timeAlertMessage,@isActive,@answerTimeOut,@closeConversationTime)
		select 1,''insert''
	end
		else select -1,''insert''
	end
	else begin
		if not exists(select * from ContactMeanIn where inboundId<>@inboundId and connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin

			select @name=isnull(@name,name), @conexionInfo = isnull(@conexionInfo,conexionInfo),@connUser= isnull(@connUser,connUser),@connPass= isnull(@connPass,ConnPass),
				@numMessages= isnull(@numMessages,numMessages),@timeAlertMessage= isnull(@timeAlertMessage,timeAlertMessage),@isActive= isnull(@isActive,isActive),
				@answerTimeOut= isnull(@answerTimeOut,answerTimeOut),@closeConversationTime=isnull(@closeConversationTime,closeConversationTime)
			from ContactMeanIn where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId


			--Twitter deja los token
			if @meanContactTypeId= 2 begin
				--usuarioID|token|tokenSecret|time|daysTwitterRecord
				insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
				set @conexionInfo=null

				SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

				SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
				SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
				set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
			end


			update ContactMeanIn set name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,
				numMessages=@numMessages,timeAlertMessage=@timeAlertMessage,isActive=@isActive,answerTimeOut=@answerTimeOut,
				closeConversationTime=@closeConversationTime
				where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
			select 1,''update''
		end
		else select -1,''update''
	end
	return (0)
end

else if @action = 5 begin--parameters check conection Mail In
	select conexionInfo,connUser,connPass from ContactMeanIn with(nolock) where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 6 begin--parameters check conection Mail Out
	select conexionInfo,connUser,connPass
		from ContactMeanOut with(nolock) where contactMeanOutId  = @contactMeanId
end
else if @action = 7 begin--list mail out by ACD
	select A.contactMeanOutId,A.name, A.conexionInfo,A.connUser,A.connPass,A.isActive
		from ContactMeanOut A with(nolock)

end
else if @action = 8 begin--insert account mail out
	if not exists(select * from ContactMeanOut where connUser=@connUser) begin
		insert into ContactMeanOut (meanContactTypeId,name,conexionInfo,connUser,ConnPass,isActive)
			values (@meanContactTypeId,@name,@conexionInfo,@connUser,@connPass,@isActive)
		select 1
		return(0)
	end
	else select -1
end
else if @action = 9 begin--update account mail out
	if not exists(select * from ContactMeanOut where contactMeanOutId <> @contactMeanId  and connUser=@connUser) begin

		select  @meanContactTypeId=isnull(@meanContactTypeId,meanContactTypeId),@name=isnull(@name,name),
			@conexionInfo=isnull(@conexionInfo,conexionInfo),@connUser=isnull(@connUser,connUser),
			@connPass=isnull(@connPass,ConnPass),@isActive=isnull(@isActive,isActive)
			from ContactMeanOut where contactMeanOutId = @contactMeanId

		update ContactMeanOut set meanContactTypeId=@meanContactTypeId,name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,isActive=@isActive
		 where contactMeanOutId = @contactMeanId
		 select 1,''update ''
	end
	else select -1
end
else if @action = 10 begin	--insert relation mail out and ACD
	if not exists(select * from relationContactMeanOutInbound where contactMeanOutId=@contactMeanId) begin
		insert into relationContactMeanOutInbound(contactMeanOutId,inboundId) values (@contactMeanId,@inboundId)
	end
end
else if @action = 11 begin --delete relation mail out and ACD
	delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId and inboundId=@inboundId
end
else if @action = 12 begin --delete mail out
	delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId
	delete ContactMeanOut where contactMeanOutId=@contactMeanId
end
else if @action = 13 begin --delete mail out
	if not exists(select * from ContactMeanOut where contactMeanOutId=@contactMeanId) begin
		update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
		select 1
	end
	else select -1
end
else if @action = 14 begin
	select * from relationContactMeanOutInbound
end
else if @action = 15 begin
	select * from relationContactMeanOutInbound where inboundId=@inboundId
end
--else if @action = 16 begin
--	update ccRIACat_Areas set maxMails = @maxMails where IDArea=@idArea
--end
else if @action = 17 begin	--
	select A.conexionInfo,A.connUser,A.connPass,A.isActive from ContactMeanIn A where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
End
else if @action = 18 begin	--Carga cuentas de salida
	select A.contactMeanOutId,A.conexionInfo,A.connUser,A.connPass,isActive from contactMeanOut A where isActive=1
end
else if @action = 19 begin	 --relation MailOut and ACD
	select contactMeanOutId,inboundId from relationContactMeanOutInbound where inboundId = @inboundId or @inboundId = 0 order by inboundId
end
else if @action = 20 begin --relation MailOut and ACD
	select B.inboundId,A.conexionInfo,A.connUser,A.connPass
	from ContactMeanOut A
	inner join relationContactMeanOutInbound B on B.contactMeanOutId=A.contactMeanOutId
	where B.inboundId = @inboundId or @inboundId = 0
end
else if @action = 21 begin --relation MailOut and ACD
	update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
end
else if @action = 22 begin --Update type
	if @meanContactTypeId = 2 --Twitter
		set @conexionInfo=''usuarioID|token|tokenSecret|1|0''
	else
		set @conexionInfo=''''
	update ContactMeanIn set name = '''', conexionInfo = @conexionInfo, connUser = '''', isActive = 0 where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
	select 1,''unAssigned''
end
END'
	EXEC(@sql)

	set @process = 'Alter SP -- ccsp_MailInitialStatistics'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_MailInitialStatistics]
@inboundId int=0,
@Option AS SMALLINT=0,
@User_id AS SMALLINT=0
AS
BEGIN

SET NOCOUNT ON;

if(@Option=0)
begin
	select
	count(*) received,
	count(case when messageStatusId = 1 then 1 else null end) pending,
	count(case when messageStatusId in (2,3) then 1 else null end) assigned,
	count(case when messageStatusId = 4 then 1 else null end) unassigned,
	count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
	count(case when messageStatusId = 7 then 1 else null end) rejected,
	count(case when messageStatusId = 8 then 1 else null end) programFwd,
	count(case when messageStatusId = 9 then 1 else null end) forwarding,
	count(case when messageStatusId in (10,11) then 1 else null end) closed,
	count(case when messageStatusId = 3 then 1 else null end) active,
	isnull(AVG(B.twait + B.tretention + B.tresponse),0) avgtAtention,
	isnull(AVG(B.twait),0) avgtWait,
	isnull(MAX(B.twait),0) maxtWait
	from conversation A
	inner join message B on A.conversationId=b.conversationId
	where inboundId= @inboundId
	and ( messageStatusId in (1,4) or [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121) )
end
if @Option = 1
BEGIN

	select
	count(*) received,
	count(case when messageStatusId = 1 then 1 else null end) pending,
	count(case when messageStatusId in (2,3) then 1 else null end) assigned,
	count(case when messageStatusId = 4 then 1 else null end) unassigned,
	count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
	count(case when messageStatusId = 7 then 1 else null end) rejected,
	count(case when messageStatusId = 8 then 1 else null end) programFwd,
	count(case when messageStatusId = 9 then 1 else null end) forwarding,
	count(case when messageStatusId in (10,11) then 1 else null end) closed,
	count(case when messageStatusId = 3 then 1 else null end) active ,
	isnull(AVG(msg.twait + msg.tretention + msg.tresponse),0) avgtAtention,
	isnull(AVG(msg.twait),0) avgtWait,
	isnull(MAX(msg.twait),0) maxtWait,
	InboundId inboundId
	from message msg (nolock) join conversation con (nolock) on con.conversationId=msg.conversationId
	where inboundId in (select inbound_id from ccInbound where inbound_id in (SELECT cam_id FROM ccSupervisorCam WHERE user_id = @User_id AND tipo = 0) and chat = 3)
	and ( messageStatusId in (1,4) or [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121) )
	GROUP BY InboundId
	END
END'
	EXEC(@sql)

		set @process = 'Alter SP -- ccsp_MailSave'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_MailSave]
@action int,
@uid varchar(max)=null,
@date datetime=null,
@conversationId int=0,
@inboundId smallint=null,
@userId smallint=0,
@messageStatusId int=null,
@isInbox bit=1,
@messageId int =null,
@timeAtt int = 0,
@pathFile varchar(255)= null,
@mailClient varchar(60)= null,
@mailACD varchar(60)= null,
@isSender bit=0,
@isUser bit = 0,
@info varchar(255)=null,
@dispositionId smallint=0,
@subDispositionId smallint=0,
@tWrapUp int =0,
@tRetention int = 0,

---Finder
@supervisor varchar(100)='''' ,@template varchar (100)='''',@ScoreTemplate int =0
AS
BEGIN


declare @isEndConversation bit
declare @meanContactTypeId smallint
declare @xmlnode xml
declare @existAttached bit, @numInteracion smallint
declare @ids varchar(max)

set @meanContactTypeId = 1
SET NOCOUNT ON;

if @action = 1 begin --find uid ConversationMail
  select count(*) from messageMail where [uid]=@uid
  return (0)
end
else if @action = 2 BEGIN --new Conversation
if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin
	insert into [conversation](inboundId,info,isInbox,isFinished,mailClient,mailInbound,meanContactTypeId) values (@inboundId,@info,@isInbox,0,@mailClient,@mailACD,@meanContactTypeId)
	select @conversationId=SCOPE_IDENTITY()
	insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,0,@date,@messageStatusId)
	select @messageId=SCOPE_IDENTITY()
	insert into [messageMail](messageId,[uid]) values (@messageId,@uid)
	select @conversationId as conversationId,@messageId as messageId,0 as lastUserId
	return (0)
end
else begin
	select 0 as conversationId,0 as messageId,0 as lastUserId
	return (0)
end
END
else if @action = 3 BEGIN --new Messages
	if @date is null set @date=getdate()
	if @mailACD is null	select @mailACD=mailInbound from conversation where conversationId=@conversationId
	if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin
		--update [conversation] set info=@info where conversationId=@conversationId
		insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,@userId,@date,@messageStatusId)
		select @messageId=SCOPE_IDENTITY()
	end
else begin
	select 0 as conversationId,0 as messageId,0 as lastUserId
	return (0)
end

	if @uid is null --for outbound messages
		select @uid = dbo.md5(cast(@conversationId as varchar(10)) + ''_'' + cast(@messageId as varchar(10)))

	insert into [messageMail](messageId,[uid]) values (@messageId,@uid)

	--Finder
	select @existAttached =case when count(*)>0 then 1 else 0 end  from attached where messageId in (select messageId from message where conversationId=@conversationId)
	select @numInteracion = count(*) from message where conversationId=@conversationId
    --Actualiza un nodo del finder
	exec ccsp_CreateNodeMultimedia @type=1, @conversationId=@conversationId, @xml = @xmlnode OUTPUT
	if not exists(select * from ccEmailNode where emailId=@conversationId) begin
		insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
	end
	else begin
		update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
	end
	select @conversationId as conversationId,@messageId as messageId,0 as lastUserId

END
else if @action = 4 BEGIN --new attachment
	insert into [attached](messageId,pathFile,isUser) values(@messageId,@pathFile,@isUser)
	select SCOPE_IDENTITY() as attachedId
END
else if @action = 5 BEGIN --Correos por contestar Status DOWNLOAD,Assigned,READ,UnaSSIGNED
	select A.conversationId,B.userId,A.mailClient,A.mailInbound,A.info,B.messageStatusId,max(B.messageId) as messageId
	from conversation A inner join message B on A.conversationId = B.conversationId
	where A.inboundId = @inboundId and B.messageStatusId in(1,2,3,4) and meanContactTypeId = @meanContactTypeId
	GROUP BY A.conversationId,A.inboundId,A.info,A.mailClient,A.mailInbound,B.messageStatusId,B.userId
END
else if @action = 6 BEGIN --update Time Attention, Retencion
	select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
	update [message] set tResponse=@timeAtt,tRetention=@tRetention,isSender=@isSender,messageStatusId=@messageStatusId,userId=@userId where messageId=@messageId
END
else if @action = 7 BEGIN --Cambia el status del mensaje
	select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
	--Status Read
	if @messageStatusId=3  update [message] set tWait=DATEDIFF(ss,isnull(tQueue,getdate()), getdate()) where messageId=@messageId

	--Status Send
	if @messageStatusId=6  begin
		select @isEndConversation=isFinished from conversation where conversationId=@conversationId
		if @isEndConversation = 1 set @messageStatusId=11--Close conversation by Agent
		update [message] set tSend=getdate() where messageId=@messageId
	end
	update [message] set messageStatusId=@messageStatusId where messageId=@messageId

	--Answered,Send,CLose Conversation system or agent
	if @messageStatusId in (5,6,10,11)  begin
		exec ccsp_CreateNodeMultimedia @type=1, @conversationId=@conversationId, @xml = @xmlnode OUTPUT
		if not exists(select * from ccEmailNode where emailId=@conversationId) begin
			insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
		end
		else begin
			update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
		end
	end

END
else if @action = 8 BEGIN --info del ultimo correo
	select messageId,GP.inboundId,C.connUser mailInbound,mailClient,mediaType,messageStatusId,info,I.descripcion,IG.graphic_id,I.tNotas,isnull(C.answerTimeOut,10) tTimeOut,C.timeAlertMessage tAlert
	from (
		select max(B.messageId) messageId,A.inboundId,A.mailClient, case A.meanContactTypeId when 1 then 3 else -1 end mediaType, B.messageStatusId, max(A.info) info
		from conversation A inner join message B  on A.conversationId = B.conversationId  where A.conversationId=@conversationId  GROUP BY A.inboundId,A.mailClient, A.meanContactTypeId, B.messageStatusId, B.userId) GP
	inner join contactMeanIn C on C.inboundId=GP.inboundId
	inner join ccInbound I on I.Inbound_id=GP.inboundId
	inner join ccRIAInboundGraph IG on IG.Inbound_id=GP.inboundId
END
else if @action = 9 BEGIN --carga adjuntos del ultimo mensaje
	if isnull(@conversationId,0) = 0
		select pathFile,isUser from attached where messageId=@messageId and isUser=@isUser
	else
	select pathFile,isUser from attached A
	inner join message B on A.messageId=B.messageId and B.conversationId=@conversationId
	where B.conversationId=@conversationId
END
else if @action = 10 BEGIN --Correos por enviar
	select A.conversationId,max(B.messageId) as messageId,B.userId,A.inboundId,A.mailInbound
	from conversation A
	inner join message B on A.conversationId = B.conversationId
	where B.messageStatusId in(5,7,8,9) and A.meanContactTypeId = 1
	GROUP BY A.conversationId,A.inboundId,A.info,A.mailClient,A.mailInbound,B.messageStatusId,B.userId
END

else if @action = 11 BEGIN --Califica el mensaje y pone el tiempo Notas
	if @subDispositionId <> 0 begin
		select @isEndConversation=isnull(EndConversation,0) from ccTipoCalifSub where califSub_id=@subDispositionId
	end
	else begin
		select @isEndConversation=isnull(EndConversation,0) from cctipoCalif where calif_id=@dispositionId
	end
	if not exists(select * from relationMessageDisposition where messageId=@messageId) begin
		insert into relationMessageDisposition(messageId,dispositionId,subDispositionId) values(@messageId,@dispositionId,@subDispositionId)
	end
	else begin
		update relationMessageDisposition set dispositionId=@dispositionId,subDispositionId=@subDispositionId where messageId=@messageId
	end
		update message set tWrapUp=@tWrapUp where messageId=@messageId
		if @isEndConversation = 1 begin
		select @conversationId=conversationId from [message] where messageId=@messageId
		update conversation set isFinished=@isEndConversation where conversationId=@conversationId
	end
END
else if @action = 12 begin --Tiempo de cola
	select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
	update [message] set tQueue=getdate(),userId=@userId where messageId=@messageId
end
else if @action = 13 BEGIN  -- desasignar
	if @messageId = 0 begin
		insert into [messageUnAssigned](messageId,userId,[time],isLogout)
		select messageId,userId,datediff(ss,tQueue,getdate()) as [time],1 as isLogout from [message] where userId=@userId and messageStatusId in (2,3)
		update [message] set tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0 where userId=@userId and messageStatusId in (2,3)
	end
	else begin
		insert into [messageUnAssigned](messageId,userId,[time],isLogout)
		select messageId,userId,datediff(ss,tQueue,getdate()) as [time],0 as isLogout from [message] where userId=@userId and messageId=@messageId and messageStatusId in (2,3)
		update [message] set tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0 where userId=@userId and messageId=@messageId and messageStatusId in (2,3)
	end
end
else if @action = 14 begin
 update [message] set @messageStatusId=1,tQueue=null,userId=0,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0  where messageStatusId in(2,3)
end
else if @action = 15 begin
	SELECT @existAttached = case when count(*)>0 then 1 else 0 end
	from attached where messageId in (select messageId from message where conversationId=@conversationId)

	select max(messageid) as messageid,max(A.inboundid) as inboundid,max(a.conversationid) as conversationid,
		max(mailClient) as mailClient, min([date]) as [date], @existAttached isAttached, max(C.descripcion) as descripcion,
		max(B.tSend) as tSend, max(D.Nombres+'' ''+D.ApellidoPaterno+'' ''+D.ApellidoMaterno) as nameAgent,
		max(E.timeAlertMessage) timeAlertMessage ,max( E.answerTimeOut) answerTimeOut, max(C.tNotas) as tNotas,
		max(E.connUser) as MailInbound, isnull(max(E.name), '''') as name
	from conversation A
	inner join message B  on A.conversationId = B.conversationId
	inner join ccinbound C on A.inboundid= C.inbound_id
	left join ccUsers D on B.userId = D.User_id
	inner join contactMeanIn E on E.inboundId=C.Inbound_id   and E.meanContactTypeId=@meanContactTypeId
	where A.conversationId=@conversationId

end
else if @action = 16 begin
	select A.inboundid,B.messageid,a.conversationid,c.pathFile
	from conversation A
	inner join message B  on A.conversationId = B.conversationId
	inner join attached C on B.messageid= C.messageid
	where A.conversationId=@conversationId
end
else if @action = 17 begin --Asignar una evluacion
	exec ccsp_CreateNodeMultimedia @type=1, @conversationId=@conversationId, @xml = @xmlnode OUTPUT,@supervisor=@supervisor,@template=@template,@ScoreTemplate=@ScoreTemplate
	if not exists(select * from ccEmailNode where emailId=@conversationId) begin
		insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
	end
	else begin
		update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
	end
end
else if @action = 18 begin --cerrar conversacion por tiempo
	if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date)
	if @conversationId = 0
		select 0
	else begin
		declare @closeConversation tinyint
		declare @tRsponse datetime
		select @tRsponse = isnull(max(tSend), getdate()) from message where messageId = @conversationId
		select @closeConversation = closeConversationTime from contactMeanIn
		 if datediff(dd,getdate(),@tRsponse ) > @closeConversation
			select 0
		else
			select @conversationId
		end
	return 0
end
else if @action = 19 begin
	select isnull(max(C.Uid),0) [maxUid] from conversation A
	inner join message B on A.conversationId=B.conversationId
	inner join messageMail C on C.messageId=B.MessageId
	where inboundId=@inboundId
end
else if @action = 20 begin
	if @messageId is null begin
		select @ids=COALESCE(@ids + '','', '''') + cast(messageId as varchar(max))  from message where conversationId=@conversationId
		select @inboundId=inboundId from conversation where conversationId=@conversationId
		select @ids as ids,@inboundId as inboundId
	end
	else begin
		select case when count(*)>0 then 1 else 0 end  from attached where messageId=@messageId
	end
end
END'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAInsertChat]------------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAInsertChat]
@action int,
@inboundId smallint = 0,
@domain varchar(50) = '''',
@session varchar(50) = '''',
@tTimeout smallint = 0,
@chatId int = 0,
@status tinyInt = 0,
@userId smallint = 0,
@finished tinyInt = 0,
@chattingTime int = 0,
@startTime datetime = null,
@clientName varchar(50) = '''',
@firstMessage int = 0,
@firstMessageTime datetime = null,
@crmNode xml = null,
@supervisor varchar(100) =null,
@template varchar (100)= null,
@ScoreTemplate int = null
AS

declare @xml xml
declare @sql nvarchar(2000)

if @action = 1 begin -- Inserta nuevo chat request /*comentario: se recomienda hacer la busqueda del userid del CRM en esta action*/
       insert into ccRIAChats (domain,session,chatStatus,requestDate,inboundId,clientName)
       values(@domain,@session,@status,getDate(),0,@clientName)
       set @chatId = scope_identity()
       select @chatId
end

else if @action = 2 begin -- Save Initial Info
update ccRIAChats set inboundId = @inboundId, chatStatus = @status, userId = @userId, tTimeout = @tTimeout where chatId = @chatId
end

else if @action = 3 begin -- Update Status
update ccRIAChats set chatStatus = @status where chatId = @chatId
end

else if @action = 4 begin -- Save Final Status
if @firstMessage = 0
       begin
             update ccRIAChats set finishedBy = @finished where chatId = @chatId
       end
else
       begin
             update ccRIAChats set finishedBy = @finished, firstMessageTime  = @firstMessageTime where chatId = @chatId
       end
end

else if @action in (5,6) begin -- Save Chatting Time /*comentario: la insercion del nodo (registro final para el finder) se recomiendo en esta action, no olvidar validar status = 4, finishedby != null y validar los tiempos para garantizar el dato final */
       if @action = 5 begin
             update ccRIAChats set tChatting = @chattingTime, chatDate = @startTime where chatId = @chatId
       end
	   set @crmNode = null

	   exec ccsp_CreateNodeMultimedia @conversationId=@chatId, @type=0,@xml=@xml OUTPUT,@supervisor=@supervisor,@template =@template,@ScoreTemplate=@ScoreTemplate

       if @xml is not null
       begin
             select @crmNode = node from ccCRMNodes where chatId = @chatId
             if @crmNode is not null
             begin
                    set @sql = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R01)[1]'''') ''
                    execute sp_executesql @sql,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
             end

             if not exists(select * from ccChatsNode where chatId=@chatId) begin ---insert finder
                insert into ccChatsNode (chatId,node, dateIn,[status]) values (@chatId,@xml, getdate(),0)
             end
             else begin ---update finder
				update ccChatsNode set [status] = 2, node =@xml  where chatId = @chatId
                --select @chatId
             end
       end
end'
		EXEC(@sql)

	set @process = 'Alter SP -- ccsp_Multimedia'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_Multimedia]
@action int,@inboundId tinyint=0,@userId int =0,@meanContactTypeId tinyint = 1
AS
BEGIN

SET NOCOUNT ON;

if @action = 1 begin --Cuentas acd por tipo

	if @inboundId=0 begin
		select distinct A.inbound_id,A.chat as mode,cast(A.status as bit) [status],cast(isnull(b.isActive,0) as bit) isActive,cast(isnull(B.numMessages,3) as int) numMessages,
			case A.chat when 0 then ''call'' when 1 then ''chat'' when 2 then ''call and chat'' when 3 then ''mail'' when 4 then ''twitter'' else ''multimedia'' end  as typeMedia
			,A.IDArea
			from ccInbound A
			left join ContactMeanIn B on B.inboundId =  A.inbound_id and A.chat = case when @meanContactTypeId =1 then 3 when  @meanContactTypeId =2 then 4 else -1 end
			where isnull(A.IDArea,0)> 0 and B.meanContactTypeId=@meanContactTypeId
	end
	else begin
		select A.inbound_id,A.chat as mode,cast(A.status as bit) [status],cast(isnull(b.isActive,0) as bit) isActive,cast(isnull(B.numMessages,3) as int) numMessages,
			case A.chat when 0 then ''call'' when 1 then ''chat'' when 2 then ''call and chat'' when 3 then ''mail'' when 4 then ''twitter'' else ''multimedia'' end  as typeMedia,
			A.IDArea
			from ccInbound A
			left join ContactMeanIn B on B.inboundId =  A.inbound_id and A.chat = case when @meanContactTypeId =1 then 3 when  @meanContactTypeId =2 then 4 else -1 end
			where A.inbound_id = @inboundId and B.meanContactTypeId=@meanContactTypeId

	end
end
else if @action = 2 begin --Relacion entre agenetes y acd
	if @inboundId=0 and @userId = 0 begin --- Carga todas las relaciones
		select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
		from ccRIAWorkGroupUsers A
		inner join ccusers B on A.User_id=B.User_id
		inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
		inner join ccInbound D on C.idCampEsp = D.inbound_id
		left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
		where B.TipoUser_id=1 and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
		order by  C.idCampEsp
	end
	else if @inboundId>0 and @userId = 0 begin
		select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
		from ccRIAWorkGroupUsers A
		inner join ccusers B on A.User_id=B.User_id
		inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
		inner join ccInbound D on C.idCampEsp = D.inbound_id
		left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
		where B.TipoUser_id=1 and D.Inbound_id=@inboundId and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
		order by  C.idCampEsp
	end
	else if @inboundId=0 and @userId > 0 begin
		select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
		from ccRIAWorkGroupUsers A
		inner join ccusers B on A.User_id=B.User_id
		inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
		inner join ccInbound D on C.idCampEsp = D.inbound_id
		left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
		where B.TipoUser_id=1 and B.User_id=@userId and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
		order by  C.idCampEsp
	end
end
else if @action =3 begin -- Cargar relacion de agentes
	if	@userId is null or @userId=0 begin
		select user_id,Login,isnull(maxmails,3) maxMails from ccusers us (nolock)
			left join ccriacat_areas area (nolock) on area.idarea=us.idarea where TipoUser_id=1
	end
	else begin
	select user_id,Login,isnull(maxmails,3) maxMails from ccusers us (nolock)
			left join ccriacat_areas area (nolock) on area.idarea=us.idarea
			where TipoUser_id=1 and  us.User_id=@userId
	end
end
END'
	EXEC(@sql)

	set @process = 'Alter SP -- ccsp_BaseXmngr'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option tinyint = 0,
@idF bigint = 0,
@idL bigint = 0,
@name varchar(25) = NULL,
@top varchar(max) = NULL
AS
declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max)
declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
declare @status tinyint
set @sql = ''''
--nota: las acciones 3 y 4 hacerlas para casos dinamicos, (i.e.) si se va controlor por tamaño y asignar un xml nuevo, conusltar Daniel de CW :)

if @action in (1,6) begin --obtiene los nodos a insertar en BX
	if @action = 1 set @status =0
	else if @action = 6 set @status = 2

	if @option = 1 begin
		set @tableName=''ccChatsNode''
		set @columnId=''chatId''
	end
	else if @option = 3 begin
		set @tableName=''ccEmailNode''
		set @columnId=''emailId''
	end
	else if @option = 4 begin
		set @tableName=''ccTwitterNode''
		set @columnId=''conversationTwitterId''
	end
	if @option in (1,3,4) begin
		set @sql = ''select top '' + @top + '' ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ''
		+ @tableName + '' with(rowlock) where status = ''+ cast(@status as nvarchar(max))
		print(@sql)
		exec(@sql)
	end
end
else if @action in (2,7) begin--actualiza los nodos insertados en BX
	if @action = 2 set @status =0
	else if @action = 7 set @status = 2
	if @option = 1
		update ccChatsNode with(rowlock) set [status] = @status+1, dateOut = getDate() where chatId between @idF and @idL and [status] =@status
	else if @option = 3
		update ccEmailNode with(rowlock) set [status] = @status+1, dateOut = getDate() where emailId between @idF and @idL and [status] = @status
	else if @option = 4
		update ccTwitterNode with(rowlock) set [status] = @status+1, dateOut = getDate() where conversationTwitterId between @idF and @idL and [status] =@status

end
else if @action = 3 --trae el nombre de la base de datos en BX
begin
	select Xname from ccBaseXDB where serviceId = @option and isFull = 0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
	insert into ccBaseXDB (serviceId, dateStart, Xname) values (@option, getDate(), @name)
end
else if @action = 5 begin --obtener servicios disponibles
	select @chat= 0,@rec= 2,@email= 0,@twitter=0
	select @chat = case when valor > 1 then 1 else 0 end from ccSettings where setting_id = 145
	select @email = case when valor = 1 then 3 else 0 end from ccSettings where setting_id = 155
	select @twitter = case when valor = 1 then 4 else 0 end from ccSettings where setting_id = 173
	select id, ref 	from ccFinderServices where id in (@chat, @rec, @email,@twitter)

end'
	EXEC(@sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_TwitterSave]----------------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_TwitterSave]
 @action int,
 @conversationId int=0,
 @messageOutTwitterId bigint=null,
 @userId int=0,
 @isLogout bit=0,
 @messageId int =null,
 @messageStatusId int=null,
 @inboundId smallint=null,
 @twitId varchar(255)=null,
 @dispositionId smallint=0,
 @subDispositionId smallint=0,
 @timeAtt int = 0,
 @tWrapUp int =0,
 @tRetention int = 0,

 ---Finder
@supervisor varchar(100)='''' ,@template varchar (100)='''',@ScoreTemplate int =0
AS
BEGIN

declare @meanContactTypeId smallint
declare @isEndConversation bit
declare @xmlnode xml

set @meanContactTypeId = 2 --Twitter


 if @action = 1 BEGIN  -- desasignar
	if @messageOutTwitterId = 0 begin
		insert into [messageUnAssingedTwit](messageOutTwitterId,userId,[time],isLogout)
		select messageOutTwitterId,userId,datediff(ss,tQueue,getdate()) as [time],1 from [messageOutTwitter]  where userId=@userId and messageStatusId in (2,3)

		update [messageOutTwitter] set twitId='''',tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0 where userId=@userId and messageStatusId in (2,3)
	end
	else begin
		insert into [messageUnAssingedTwit](messageOutTwitterId,userId,[time],isLogout)
		select messageOutTwitterId,userId,datediff(ss,tQueue,getdate()) as [time],0 as isLogout from [messageOutTwitter] where userId=@userId and messageOutTwitterId=@messageOutTwitterId and messageStatusId in (2,3)

		update [messageOutTwitter] set twitId='''',tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0 where userId=@userId and messageOutTwitterId=@messageOutTwitterId and messageStatusId in (2,3)
	end
END
else if @action = 2 begin --Coloca el valor del TwitId
	update [messageOutTwitter] set twitId=@twitId where messageOutTwitterId=@messageOutTwitterId
end
else if @action = 5 BEGIN --Twitter por contestar
	--Status DOWNLOAD,Assigned,READ,UnaSSIGNED
	select A.conversationTwitterId,B.userId,A.screenNameClient,A.screenNameInbound,B.messageStatusId,max(B.messageOutTwitterId) as messageId
		from conversationTwitter A
		inner join [messageoutTwitter] B on A.conversationTwitterId = B.conversationTwitterId
		where A.inboundId = @inboundId and B.messageStatusId in(1,2,3,4) and meanContactTypeId = @meanContactTypeId
		GROUP BY A.conversationTwitterId,A.inboundId,A.screenNameClient,A.screenNameInbound,B.messageStatusId,B.userId
END
else if @action = 6 BEGIN --update Time Attention, Retencion
	select @messageId=max(messageOutTwitterId) from messageOutTwitter with(nolock) where conversationTwitterId=@conversationId
	update messageOutTwitter set tResponse=@timeAtt,tRetention=@tRetention,isSender=1,messageStatusId=@messageStatusId where messageOutTwitterId=@messageId
END
else if @action = 7 BEGIN --Cambia el status del mensaje
	select @messageId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId

	--Status Read
	if @messageStatusId=3  update [messageOutTwitter] set tWait=DATEDIFF(ss,tQueue, getdate()) where messageOutTwitterId=@messageId
	--Status Send
	if @messageStatusId=6  begin
		select @isEndConversation=isFinished from conversationTwitter where conversationTwitterId=@conversationId

		if @isEndConversation = 1 set @messageStatusId=11--Close conversation by Agent
		update [messageOutTwitter] set tSend=getdate() where messageOutTwitterId=@messageId

	end
	update [messageOutTwitter] set messageStatusId=@messageStatusId where messageOutTwitterId=@messageId

	--Answered,Send,CLose Conversation system or agent
	if @messageStatusId in (5,6,10,11)  begin
		exec ccsp_CreateNodeMultimedia @type=2, @conversationId=@conversationId, @xml = @xmlnode OUTPUT
		if not exists(select * from [ccTwitterNode] where [conversationTwitterId]=@conversationId) begin
			insert into [ccTwitterNode]([conversationTwitterId],[node],dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
		end
		else begin
			update [ccTwitterNode] set node=@xmlnode,status=2 where [conversationTwitterId]=@conversationId
		end
	end

END
else if @action = 10 begin --Carga las conversaciones pendientes
	if @conversationId = 0 begin
		select A.conversationTwitterId,max(B.messageOutTwitterId) as messageId,B.userId,A.inboundId,max(C.twitId) as twitId
			from conversationTwitter A
			inner join messageOutTwitter B on A.conversationTwitterId = B.conversationTwitterId
			inner join messageInTwitter C on C.conversationTwitterId=B.conversationTwitterId
			where A.meanContactTypeId = @meanContactTypeId
			and B.messageStatusId in(5,7,8,9) and isSender=1 and A.inboundId=@inboundId
			GROUP BY A.conversationTwitterId,A.inboundId,B.userId
	end
	else begin
	select A.conversationTwitterId,max(B.messageOutTwitterId) as messageId,B.userId,A.inboundId,max(C.twitId) as twitId
			from conversationTwitter A
			inner join messageOutTwitter B on A.conversationTwitterId = B.conversationTwitterId
			inner join messageInTwitter C on C.conversationTwitterId=B.conversationTwitterId
			where A.meanContactTypeId = @meanContactTypeId
			and A.conversationTwitterId = @conversationId
			GROUP BY A.conversationTwitterId,A.inboundId,B.userId
	end
end
else if @action = 11 BEGIN --Califica el mensaje y pone el tiempo Notas
	if @subDispositionId <> 0 begin
		select @isEndConversation=isnull(EndConversation,0) from ccTipoCalifSub where califSub_id=@subDispositionId
	end
	else begin
		select @isEndConversation=isnull(EndConversation,0) from cctipoCalif where calif_id=@dispositionId
	end
	if not exists(select * from relationMessageDispositionTwit where messageOutTwitterId=@messageId) begin
		insert into relationMessageDispositionTwit(messageOutTwitterId,dispositionId,subDispositionId) values(@messageId,@dispositionId,@subDispositionId)
	end
	else begin
		update relationMessageDispositionTwit set dispositionId=@dispositionId,subDispositionId=@subDispositionId where messageOutTwitterId=@messageId
	end
	update [messageOutTwitter] set tWrapUp=@tWrapUp where messageOutTwitterId=@messageId
	if @isEndConversation = 1 begin
		select @conversationId=conversationTwitterId from [messageOutTwitter]where messageOutTwitterId=@messageId
		update conversationTwitter set isFinished=@isEndConversation where conversationTwitterId=@conversationId
	end
END
else if @action = 12 BEGIN  --Tiempo de cola
	select @messageId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId
	update [messageOutTwitter] set tQueue=getdate(),userId=@userId where messageOutTwitterId=@messageId
END
else if @action = 13 BEGIN  --Limpia las conversaciones quedaron abiertas por cerrar la aplicacion
	update [messageoutTwitter] set @messageStatusId=1,twitId='''',tQueue=null,userId=0,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0  where messageStatusId in(2,3)
END
else if @action = 14 begin --Asignar una evluacion
	exec ccsp_CreateNodeMultimedia @type=2, @conversationId=@conversationId, @xml = @xmlnode OUTPUT,@supervisor=@supervisor,@template=@template,@ScoreTemplate=@ScoreTemplate
	if not exists(select * from ccEmailNode where emailId=@conversationId) begin
		insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
	end
	else begin
		update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
	end
end

END'
		EXEC(@sql)


		set @process = 'ALTER PROCEDURE [dbo].[ccspADMaddConversationTweet]--------'
		set @sql='ALTER PROCEDURE [dbo].[ccspADMaddConversationTweet]
@action int,
@inboundId int = null,
@clientId varchar(255)= null,
@isFinished bit = 0,
@screenNameClient varchar(100) = null,
@screenNameInbound varchar(100) = null,
@meanContactTypeId smallint = null,
@twitId varchar(255) = null,
@conversationId bigint = null,
@date datetime=null,
@replayId varchar(255)=null,
@tipoTwitId tinyint=1,
@messageId bigint = null,
@dispositionId smallint=0,
@subDispositionId smallint=0,
@tWrapUp int =0

as
set nocount on

declare @ninteration int ,@messageOutTwitterId bigint
declare @userId int
declare @isEndConversation bit


if @action = 1 begin --Revisa que exista la conversacion
	select @conversationId =  isnull(max(conversationTwitterId),0) from conversationTwitter where isFinished = 0 and meanContactTypeId = 2 and ClientId = @clientId and inboundId=@inboundId
	if @conversationId = 0
		select 0,''New Conversation''
	else begin
		declare @closeConversation tinyint
		declare @tRsponse datetime
		select @tRsponse = isnull(max(tSend),getdate()) from messageOutTwitter where conversationTwitterId = @conversationId
		select @closeConversation = closeConversationTime from contactMeanIn
		 if datediff(dd,getdate(),@tRsponse ) > @closeConversation
			select 0,''New Conversation Close System''
		else
			select @conversationId
	end
    return 0
end
else if @action = 2 begin --Nueva conversacion y mensaje entrada y salida
    --agregar tabla de messagetwit fecha de descarga
	if @replayId is null or @replayId=''''
		set @replayId= ''0''
    insert into conversationTwitter (inboundId,ClientId,isFinished,screenNameClient,screenNameInbound,meanContactTypeId,replayId)
    values(@inboundId,@clientId,@isFinished,@screenNameClient,@screenNameInbound,@meanContactTypeId,@replayId)
    set  @conversationId  = SCOPE_IDENTITY()
	insert into messageInTwitter(conversationTwitterId,tipoTwitId,twitId,[date]) values(@conversationId,@tipoTwitId,@twitId,@date)
	set @messageId=SCOPE_IDENTITY()
	insert into messageOutTwitter(conversationTwitterId,messageStatusId,tipoTwitId,userId,[date],ninteration,messageInTwitterIdIni,messageInTwitterIdEnd)
	values(@conversationId,1,@tipoTwitId,0,@date,1,@messageId,@messageId)
    select 0 as userId,@conversationId as conversationId, @messageId as messageId
    return 0
end
else if @action = 3 begin --Nuevo mensaje Entrada
	---Revisa que no se contesto el twitt
	select @messageOutTwitterId=max(A.messageOutTwitterId),@ninteration= count(B.messageInTwitterId)
	from messageOutTwitter A inner join messageInTwitter B on A.conversationTwitterId=B.conversationTwitterId
	where A.conversationTwitterId=@conversationId and A.messageStatusId not in (5,6,7,8,9,10,11)

	insert into messageInTwitter(conversationTwitterId,tipoTwitId,twitId,[date]) values(@conversationId,@tipoTwitId,@twitId,@date)
	set @messageId=SCOPE_IDENTITY()

	if  @messageOutTwitterId is null begin
		insert into messageOutTwitter(conversationTwitterId,messageStatusId,tipoTwitId,userId,[date],ninteration,messageInTwitterIdIni,messageInTwitterIdEnd)
		values(@conversationId,1,@tipoTwitId,0,@date,1,@messageId,@messageId)
		set @messageOutTwitterId=SCOPE_IDENTITY()
	end
	else begin
		update messageOutTwitter set messageInTwitterIdEnd=@messageId,[date]=@date,ninteration=@ninteration
		where messageOutTwitterId=@messageOutTwitterId
	end
	select @userId = userId  from messageOutTwitter with(nolock) where messageOutTwitterId=@messageOutTwitterId
	select @userId as userId,@conversationId as conversationId, @messageId as messageId
	return 0
end
else if @action = 4 begin --Obtiene el maximo messageOutTwitterId por conversacion
    select @messageOutTwitterId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId
	select @replayId=replayId from conversationTwitter where conversationTwitterId=@conversationId
	select @messageOutTwitterId as messageOutTwitterId,@replayId as replayId
	return 0
end
else if @action = 5 begin --Ultimo mensaje en por ACD
    select isnull(max(twitId),0),max(date) from messageInTwitter as A
	inner join conversationTwitter as B on A.conversationTwitterId=B.conversationTwitterId
	where B.inboundId=@inboundId
	return 0
end
else if @action = 6 begin --Obtiene conversación dependiendo del replayId
	select @conversationId=conversationTwitterId  from messageOutTwitter where twitId=@replayId
	if @conversationId is not null begin
		select @replayId=replayId from conversationTwitter where conversationTwitterId=@conversationId
	end
	else begin
		select 0 as conversationId,''0'' as replayId
	end
	select @conversationId as conversationId,@replayId as replayId
	return 0
end

set nocount off'
		EXEC(@sql)


		set @process = 'ALTER PROCEDURE [dbo].[ccspFinderChat]--------'
		set @sql='ALTER PROCEDURE [dbo].[ccspFinderChat]
@action int,@ids nvarchar(max)=null

AS
BEGIN

SET NOCOUNT ON

declare @sql nvarchar(max)
if @action = 1 begin
	set @sql=''select chatId,clientName,userId as agentId from ccRIAChats where chatId in(''+@ids+'')''
	exec (@sql)
end
--action 2 es para grabadora
else if @action = 3 begin
	set @sql=''select conv.conversationId,max(msg.messageId) as messageId,conv.mailClient,conv.mailInbound
from conversation conv
inner join message msg on msg.conversationId=conv.conversationId
where conv.conversationId in(''+@ids+'')
group by conv.conversationId,conv.mailClient,conv.mailInbound''
	exec (@sql)
end
else if @action = 4 begin
	set @sql=''select conv.conversationTwitterId,max(msg.messageOutTwitterId) as messageId,
conv.screenNameClient,conv.screenNameInbound
from conversationTwitter conv
inner join messageOutTwitter msg on msg.conversationTwitterId=conv.conversationTwitterId
where conv.conversationTwitterId in(''+@ids+'')
group by conv.conversationTwitterId,conv.screenNameClient,conv.screenNameInbound''
	exec (@sql)
end
--print (@sql)


END	'
		EXEC(@sql)


		set @process = 'ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay]--------'
		set @sql='ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay]
@type smallint = null,
@inbound_id smallint = null,
@calif_id smallint = null,
@cam_id smallint = null
AS
set nocount on
create table #CalifTemp (id int identity,
tipo integer,
Cam_id varchar(50),
Calificacion varchar(50),
subCalificacion varchar(50) null,
calif_id smallint null,
Total int )

declare @typeACD smallint --= 0
declare @today datetime
--declare
set @today = convert(datetime, convert (varchar(11), getdate(), 101))
--set @today =convert(datetime, convert (varchar(11), ''2015-10-01 17:50:20.470'', 101))
select @typeACD =chat from ccInbound  where Inbound_id = @inbound_id

-- Seleccion de idioma --
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end
from ccsettings where setting_id = 27 -- 0 esp

select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
from ccsettings where setting_id = 27 -- 0 esp

if @type=0
insert into #CalifTemp
select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13
		then case when description is not null
					then description
					else @nIdioma-- substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1)
					end
else case when sll.descripcion is not null then ''cw:'' + sll.descripcion
	else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1)
	end end as Calificacion
,0 as subCalificaion,
co.calif_id,count(*) cantidad
from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
left join ccCamps ci on ci.cam_id = co.cam_id
where co.cal_inicio > @today
group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id

if @type=0
select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1)
then calificacion
else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma))
end as Calificacion,case when count(subCalificacion)>0 then 1 else 0 end subCalificacion, calif_id,sum(Total) as Total-- , iTotal4Campaign -- para ver total por campaña
from #CalifTemp
group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1)
then calificacion
else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma))
end, Cam_id, iTotal4Campaign,calif_id

if @typeACD=1 and @type = 1
insert into #CalifTemp

select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description
else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1)
end as Calificacion
,count(isnull(ctcs.califSubDesc,'''')) as subCalificacion,ci.calif_id
,count(*) as total

from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id
left join ccInbound cci on cci.inbound_id = ci.inbound_id
left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
where ci.cal_inicio > @today
and statuscall_id = 13
group by description, cci.inbound_id,ci.calif_id

-- Se corrigio suma de totales --
Alter table #CalifTemp add iTotal4Campaign int null

if (select valor from ccSettings where setting_id = 78) = 0
update #CalifTemp set iTotal4Campaign = 0

else
update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign
from (select cam_id, sum(A.Total) iTotal4Campaign
from #CalifTemp A group by cam_id) t join #CalifTemp c
on t.cam_id = c.cam_id

if @typeACD=1 and @type = 1
select tipo, cam_id, calificacion,subCalificacion,calif_id ,sum( total ) as totales from (
	select 1 as tipo, inboundId as Cam_id, case when description is not null then description
	 else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1)
	 end as Calificacion
	 , 0 as subCalificacion,0 as calif_id,
	 count(disposition) as Total,0 count,0 iTotal4Campaign
	from ccriachats a left join ccTipoCalif b
	on a.disposition=b.calif_id
	where a.chatDate > @today
	group by inboundId, Description

	union all

	select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1)
	then calificacion
	else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma))
	end as Calificacion
	,case when count(subCalificacion)>0 then 1 else 0 end subCalificacion,
	isnull(calif_id,'''') as calif_id
	 ,sum(Total) as Total, count(*) count , iTotal4Campaign -- para ver total por campaña
	from #CalifTemp
	group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1)
	then calificacion
	else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma))
	end,calif_id,Cam_id, iTotal4Campaign
)  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id order by tipo,cam_id,calif_id

if @typeACD = 3 and @type = 1 begin ---calif mail
	insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
		select 2 as tipo,conmean.inboundId as camid, ''''as calificacion--, tipcal.Description as calificacion,
		,
		case when relmesdis.subDispositionId > 0 then 1 else 0 end as subcalificacion,
		relmesdis.dispositionId as calif_id, COUNT(relmesdis.dispositionId) as total
		 from contactMeanIn conmean
		inner join conversation conver on conmean.inboundId = conver.inboundId
		inner join message mess on mess.conversationId = conver.conversationId
		inner join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
	--left join ccTipoCalif tipcal on tipcal.calif_id = relmesdis.messageId
	where conmean.meanContactTypeId = 1 and mess.date > @today
	group by conmean.inboundId,relmesdis.subDispositionId,relmesdis.dispositionId,conmean.inboundId

	select camtemp.tipo,camtemp.cam_id,tipcal.Description,camtemp.subcalificacion,camtemp.calif_id,camtemp.total from #CalifTemp camtemp
	inner join
	ccTipoCalif tipcal on camtemp.calif_id =  tipcal.calif_id
	return
end




if @typeACD = 4 and @type= 1 begin --calif twetter

	insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
		select 3 as tipo,conmean.inboundId as camid, ''''as calificacion--, tipcal.Description as calificacion,
		,
		case when relmesdis.subDispositionId > 0 then 1 else 0 end as subcalificacion,
		relmesdis.dispositionId as calif_id, COUNT(relmesdis.dispositionId) as total
		 from contactMeanIn conmean
		inner join conversationTwitter conver on conmean.inboundId = conver.inboundId
		inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
		inner join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
	--left join ccTipoCalif tipcal on tipcal.calif_id = relmesdis.messageId
	where conmean.meanContactTypeId = 2 and mess.date > @today
	group by conmean.inboundId,relmesdis.subDispositionId,relmesdis.dispositionId,conmean.inboundId

	select camtemp.tipo,camtemp.cam_id,tipcal.Description,camtemp.subcalificacion,camtemp.calif_id,camtemp.total from #CalifTemp camtemp
	inner join
	ccTipoCalif tipcal on camtemp.calif_id =  tipcal.calif_id

	--select 3 as tipo, tipcal.Description, case when remedi.subdispositionId = 0 then 0 else 1 end  as subdisposition, tipcal.calif_id
	--from ccTipoCalif tipcal
	--inner join relationMessageDispositionTwit remedi on tipcal.calif_id = remedi.dispositionId
end

--SUBCALIFICACIONES

if @type = 3 begin -----entrada acd''s subcalif
	select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description
	else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1)
	end as Calificacion,
	isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion
	, count(*) as totales
	from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id
	left join ccInbound cci on cci.inbound_id = ci.inbound_id
	left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
	where ci.cal_inicio > @today
	and ci.inbound_id = @inbound_id
	and statuscall_id = 13
	and ci.calif_id = @calif_id
	group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id
end

if @type = 4 begin --salida campañas
		select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13
			then case when description is not null
						then description
						else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1)
						end
	else case when sll.descripcion is not null
	then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1)
	end end as Calificacion,isnull(cso.califSubDesc,@nIdiomaSub) ,count(*) cantidad
	from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
	left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
	left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
	left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
	left join ccCamps ci on ci.cam_id = co.cam_id
	where co.cal_inicio > @today
	and co.cam_id = @inbound_id
	and co.calif_id = @calif_id
	group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
end

if  @typeACD = 3 and @type = 2 begin ----- eMail subcalif
	select 4 as tipo,cci.inbound_id as cam_id, case when description is not null then description
	else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1)
	end as Calificacion,
	isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion
	, count(*) as totales
	from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id
	left join ccInbound cci on cci.inbound_id = ci.inbound_id
	left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
	left join relationMessageDisposition relmedis on relmedis.subDispositionId = ctcs.califsub_id
	where ci.cal_inicio > @today
	and ci.inbound_id = @inbound_id
	and cci.chat = 3
	and ci.calif_id = @calif_id
	group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id
end


if  @typeACD = 4 and @type = 2  begin ----- twetter subcalif
insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
		select 3 as tipo,conmean.inboundId as camid, ''''as calificacion--, tipcal.Description as calificacion,
		,
		 relmesdis.subDispositionId as subcalificacion,
		relmesdis.dispositionId as calif_id, COUNT(relmesdis.dispositionId) as total
		 from contactMeanIn conmean
		inner join conversationTwitter conver on conmean.inboundId = conver.inboundId
		inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
		inner join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
	--left join ccTipoCalif tipcal on tipcal.calif_id = relmesdis.messageId

	where conmean.meanContactTypeId = 2 and mess.date > @today
	group by conmean.inboundId,relmesdis.subDispositionId,relmesdis.dispositionId,conmean.inboundId


select camtemp.tipo,camtemp.cam_id,subcali.califSubDesc,camtemp.subcalificacion,camtemp.calif_id,camtemp.total
 from #CalifTemp camtemp
	inner join ccTipoCalifSub subcali on camtemp.subCalificacion = subcali.califSub_id
	where camtemp.cam_id = @inbound_id

end

drop table #CalifTemp
set nocount off'
		EXEC(@sql)


		set @process = 'ALTER Procedure [dbo].[xx_Inserta]--------'
		set @sql='alter procedure [dbo].[xx_Inserta]
@cal_key varchar(20),
@cal_telefono varchar(19),
@cal_telefono2 varchar(19),
@cal_telefono3 varchar(19),
@cal_telefono4 varchar(19),
@cal_telefono5 varchar(19),
@dato1 varchar(255),
@dato2 varchar(255),
@dato3 varchar(255),
@dato4 varchar(255),
@dato5 varchar(255),
@cam_id integer,
@FCallBack smalldatetime = '''',
@cal_status tinyint=0,
@User_id integer=0,
@region varchar(10),
@localidad varchar(10)
as
declare @calloutid int
if (@cal_status=0) set @FCallBack=getdate()
Insert into ccoCallsOutSource ( cal_key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, dato1, dato2, dato3, dato4, dato5, cam_id, cal_fechaDial, cal_status, user_id,Region,Localidad)
values ( @cal_key, @cal_telefono, @cal_telefono2, @cal_telefono3, @cal_telefono4, @cal_telefono5, @dato1, @dato2, @dato3, @dato4, @dato5, @cam_id, @FCallBack, @cal_status, @User_id,@region,@localidad)
select @calloutid=scope_identity()
Insert into xxClienteHistorial ( callout_id , fechaAct ) values ( @calloutid, getdate() )
select @calloutid'
		EXEC(@sql)

		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ''', version to release: ''' + cast(@version as varchar(5))
	end

set nocount off