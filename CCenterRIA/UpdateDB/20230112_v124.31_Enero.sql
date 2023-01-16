/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.25

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 31
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

		-------------------------------------- K026001-Configuración de callbacks IVAN (GERARDO) --------------------------------
		
		SET @process = 'K026001-Configuración de callbacks Se agrega el nuevo status el la tabla ccStatusLLamada'
		SET @sql = 'if not exists ( select * from ccStatusLLamada where statusCall_id = 18)
					begin
						insert into ccStatusLLamada(statusCall_id, descripcion, inAbandonConfig) 
						values(18, ''Abandonada (Reminder)'', 1)---esto es por lo configurado en el setting_id 13
					end';
		EXEC(@sql);

		SET @process = 'K026001-Configuración de callbacks Se agrega insert en el apartado de Estableciendo Status de llamadas (línea 163) Español'
		SET @sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEspañol] AS
					SET NOCOUNT ON

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
					delete from [dbo].[ccStatusLLamada]

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
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (18, convert(text, N''Abandonada (Reminder)'' collate SQL_Latin1_General_CP1_CI_AS))
					update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8, 18 )

					Print ''Estableciendo los tipos de dias''
					truncate table [dbo].[ccTipoDias]
					INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))

					Print ''Estableciendo resultados de marcacion''
					delete from [dbo].[ccTipoResultadoDial]

					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, convert(text, N''Contestan'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, convert(text, N''Ocupado'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, convert(text, N''No Contesta'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, convert(text, N''Fax/Modem'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, convert(text, N''NoDialTone'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, convert(text, N''NoService'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, convert(text, N''Buzon/Maquina'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, convert(text, N''Congestion'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, convert(text, N''Cancelado'' collate SQL_Latin1_General_CP1_CI_AS))

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
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N''ChatReq'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N''Chatting'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, convert(text, N''Transferencia Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, convert(text, N''Ringing Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (30, convert(text, N''ReconnectKolob'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, convert(text, N''Ready PreviewPro'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (32, convert(text, N''Preview'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (33, convert(text, N''Asistida'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (35, convert(text, N''Inactivo'' collate SQL_Latin1_General_CP1_CI_AS))

					Print ''Estableciendo los tipos de usuario''
					Delete [dbo].[ccTipoUsers]
					INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, convert(text, N''Agente'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, convert(text, N''AVRS Calidad'' collate SQL_Latin1_General_CP1_CI_AS))

					Print ''Estableciendo los dias''
					Delete [dbo].[ccDias]
					DBCC CHECKIDENT (''[ccDias]'', RESEED, 0)
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
					delete from [dbo].cstoTarifa
					delete cstoTipoLlamada

					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''LD nacional'',''12'',''01%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Cel'',''13'',''044%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''Cel LD'',''13'',''045%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''LD USA'',''13'',''001%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''LD inter'',''0'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''LADA local 2 dígitos'',''8'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''Local lada 3 digitos'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''Local lada 4 digitos'',''6'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''Cel LADA local 2 dígitos'',''10'',''15%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''Cel LADA local 3 dígitos'',''9'',''15%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''Cel LADA local 4 dígitos'',''8'',''15%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Larga distancia'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Cel larga distancia'',''13'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Celular'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''LD Nacional'',''11'',''1%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''LD Nacional'',''10'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Celular'',''11'',''04%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Cel'',''11'',''07%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''LD inter'',''13'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''LD anterior'',''9'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Cel'',''10'',''05%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''LD actual'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''LD inter'',''13'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''LD inter'',''0'',''0011%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Cel'',''10'',''04%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Movil '',''8'',''6%|7%|8%|9%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''Celular 9 dígitos '',''9'',''9%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''LD Nacional'',''10'',''02%|03%|04%|05%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''Cel LD nacional'',''10'',''06%|07%|08%|09%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''Cel LD nacional 9 dígitos'',''11'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''LD internacional'',''19'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Movil'',''8'',''3%|4%|5%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''LD Nacional'',''8'',''7%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''LD internacional'',''8'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''Telefonía SIP'',''8'',''4%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Telefonía móvil'',''8'',''5%|6%|7%|8%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''LD internacional'',''0'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Cobro Revertido'',''10'',''800%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Tarifa Prima'',''10'',''90%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Acceso Internet'',''10'',''900%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Especial'',''0'',''08%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Fijo'',''8'',''2%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Movil'',''8'',''6%|7%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''LD internacional'',''0'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Celular'',''9'',''6%|7%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''LD internacional'',''0'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Servicios web'',''9'',''5%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''LD nacional'',''9'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Cel'',''9'',''9%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''LD inter'',''0'',''00%'')

					Print ''Estableciendo los movimientos de lista negra''
					Delete [dbo].[ccTipoMovsListaNegra]
					SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, convert(text, N''Carga Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, convert(text, N''Lista Negra en Carga de Registros'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, convert(text, N''Eliminado por Aplicar Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, convert(text, N''Eliminado de Lista Negra por Remplazo '' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, convert(text, N''Borrado de Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, convert(text, N''Agregado por calificación por campaña'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, convert(text, N''Carga Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, convert(text, N''Carga Registro Cliente Lista Negra''collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (9, convert(text, N''Agregado por calificación por ACD'' collate SQL_Latin1_General_CP1_CI_AS))
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

					Print ''Mensajes voz default''
					DELETE [dbo].[ccMsgFiles]
					DBCC CHECKIDENT (''[ccMsgFiles]'', RESEED, 0)
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default5'', ''Mensaje Bienvenida'' )
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default4'', ''Mensaje Transferencia'' )
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default3'', ''Mensaje Fuera de servicio'' )
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default2'', ''Mensaje Fuera de horario'' )
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default1'', ''Mensaje En espera'' )
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default7'', ''Mensaje Sin agentes firmados'' )
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default9'', ''Mensaje VoiceMail'')
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default10'', ''Mensaje Desborde'')
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default11'', ''Lista Negra'')


					Print ''Mensajes default chat''
					DELETE [dbo].[ccRIAChatInboundMsgs]
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default5'', ''!Bienvenido!'')
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default3'', ''El servicio no se encuentra disponible'')
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default2'', ''Nuestro horario de atención ha terminado'')
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default1'', ''Por favor espere mientras uno de nuestros agentes se encuentra disponible'')
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default7'', ''No hay agentes disponibles'')
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default10'', ''No podemos tomar su solicitud'')
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default12'', ''La sesión de chat ha estado inactiva mucho tiempo'')
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default13'', ''La sesión de chat ha concluido'')';
		EXEC(@sql);

		SET @process = 'K026001-Configuración de callbacks Se agrega insert en el apartado de Estableciendo Status de llamadas (línea 475) English'
		SET @sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEnglish]
					AS
					Print ''Iniciando proceso de configuracion en Ingles''

					Print ''Estableciendo Horarios''
					Delete [ccHorarios]
					DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
					INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Week'', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
					INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Night shift'', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
					INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Saturday'', 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
					INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Sunday'', 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

					Print ''Estableciendo Not Ready y graficas''
					Delete [ccRIANotReadyGraph]
					Delete [ccTipoNotReady]
					Delete [ccRIAGraphics]

					DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
					INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Not Clasified'')
					INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Break'')
					INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Bathroom'')
					INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''With client'')
					INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Supervisor'')
					INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Clarification'')
					INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Meeting'')
					INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Lunch'')
					INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Systems'')
					INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Other'')


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
					delete from [ccStatusLLamada]

					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, ''Initial'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Out of Schedule'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Out of Service'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''No Agents Logged in'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''On Hold'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandoned'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Time overflow'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Queue size overflow'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''With Message'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, ''Assigned Message'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, ''Assigned'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, ''Attended Message'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, ''Answered'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, ''Canceled Message'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, ''Assigned and Not Answered'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, ''Assigned and took line'')
					INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (18, ''Abandoned (Reminder)'')
					update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8, 18 )

					Print ''Estableciendo los tipos de dias''
					TRUNCATE TABLE [ccTipoDias]
					INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, ''Monday'')
					INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, ''Tuesday'')
					INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, ''Wednesday'')
					INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, ''Thursday'')
					INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, ''Friday'')
					INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, ''Saturday'')
					INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, ''Sunday'')

					Print ''Estableciendo resultados de marcacion''
					delete from [ccTipoResultadoDial]

					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Answer'')
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Busy'')
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Not Answer'')
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax/Modem'')
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Other'')
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, ''NoService'')
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, ''VoiceMail/Machine'')
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, ''Circuit busy'')
					INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, ''Cancelled'')

					Print ''Estableciendo los tipos de estado de los agentes''
					DELETE [ccTipoStatusAgente]

					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, ''LogOut'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, ''Unknown'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, ''Not Ready'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, ''Ready'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, ''Talking'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, ''Transfer'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, ''Wrapup'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, ''Other'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, ''Client'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, ''Ringing'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, ''Problem'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, ''Wait for manual call'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N''ChatReq'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N''Chatting'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, ''Xfer Fail'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, ''Ringing Fail'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (30, ''ReconnectKolob'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, ''Ready PreviewPro'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (32, ''Preview'')
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (33, convert(text, N''Assisted'' collate SQL_Latin1_General_CP1_CI_AS))
					INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (35, convert(text, N''Idle'' collate SQL_Latin1_General_CP1_CI_AS))

					Print ''Estableciendo los tipos de usuario''
					Delete [ccTipoUsers]
					INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, ''Agent'')
					INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, ''Supervisor'')
					INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, ''AVRS Access'')

					Print ''Estableciendo los dias''
					Delete [ccDias]
					DBCC CHECKIDENT (''[ccDias]'', RESEED, 0)
					SET IDENTITY_INSERT [ccDias] ON
					INSERT [ccDias] ([dia_id], [Name]) VALUES (1, ''Sunday'')
					INSERT [ccDias] ([dia_id], [Name]) VALUES (2, ''Monday'')
					INSERT [ccDias] ([dia_id], [Name]) VALUES (3, ''Tuesday'')
					INSERT [ccDias] ([dia_id], [Name]) VALUES (4, ''Wednesday'')
					INSERT [ccDias] ([dia_id], [Name]) VALUES (5, ''Thursday'')
					INSERT [ccDias] ([dia_id], [Name]) VALUES (6, ''Friday'')
					INSERT [ccDias] ([dia_id], [Name]) VALUES (7, ''Saturday'')
					SET IDENTITY_INSERT [ccDias] OFF

					Print ''Estableciendo los tipos de llamada''
					delete from cstoTarifa
					delete cstoTipoLlamada

					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''National LD'',''12'',''01%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Mobile'',''13'',''044%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''LD Mobile'',''13'',''045%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''USA LD'',''13'',''001%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''Inter LD'',''0'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''2-digit Local Area Code'',''8'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''3-digit Local Area Code'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''4-digit Local Area Code'',''6'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''2-digit Local Mobile Area Code'',''10'',''15%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''3-digit Local Mobile Area Code'',''9'',''15%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''4-digit Local Mobile Area Code'',''8'',''15%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Long Distance'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Long Distance Mobile'',''13'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Mobile'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''National LD'',''11'',''1%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''National LD'',''10'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Mobile'',''11'',''04%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Mobile'',''11'',''07%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''Inter LD'',''13'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''Old LD'',''9'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Mobile'',''10'',''05%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''New LD'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''Inter LD'',''13'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''Inter LD'',''0'',''0011%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Mobile'',''10'',''04%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Mobile '',''8'',''6%|7%|8%|9%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''9-digit Mobile'',''9'',''9%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''National LD'',''10'',''02%|03%|04%|05%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''National Mobile LD'',''10'',''06%|07%|08%|09%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''9-digit National Mobile LD'',''11'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''International LD'',''19'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Mobile'',''8'',''3%|4%|5%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''National LD'',''8'',''7%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''International LD'',''8'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''SIP Telephony'',''8'',''4%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Mobile Telephony'',''8'',''5%|6%|7%|8%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''International LD'',''0'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Reverse Charge'',''10'',''800%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Premium Rate'',''10'',''90%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Internet Access'',''10'',''900%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Special'',''0'',''08%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Landline'',''8'',''2%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Mobile'',''8'',''6%|7%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''International LD'',''0'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Mobile'',''9'',''6%|7%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''International LD'',''0'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Webservices'',''9'',''5%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''National LD'',''9'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Mobile'',''9'',''9%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''Inter LD'',''0'',''00%'')

					Print ''Estableciendo los movimientos de lista negra''
					Delete [ccTipoMovsListaNegra]
					SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Added to black list'')
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Blocked on loading'')
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Removed from campaign'')
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Replaced from black list'')
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Deleted from black list'')
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Added by Disposition'')
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, ''Load black list'')
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, ''Load customer black list'')
					INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (9, ''Added by Inbound Disposition'')
					SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

					Print ''Estableciendo los tipos de calificacion''
					Delete [ccTipoCalif]
					INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, ''Wrong area'', 0)
					INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, ''Disconnected call'', 0)
					INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, ''Wrong number'', 0)

					Print ''Estableciendo los tipos de calificacion de salida''
					Delete [ccTipoCalifOUT]
					INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, ''Effective call'', 0, 0, 1)
					INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, ''Leave a message'', 0, 1, 2)
					INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, ''Wrong number'', 0, 1, 3)

					Print ''Estableciendo proveedores''
					Delete [cstoProvedor]
					DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
					INSERT [cstoProvedor] ([descrip]) VALUES (''Carrier 1'')

					Print ''Tipo Msg ChatLog'' -- No se hace delete ni truncate ya que se perderia la integridad si ya hay registros, los id ya deberian estar creados por lo cual se genera el update
					Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes an individual message to agent'' where TipoMsgChat=1
					Update ccRIAChat_TipoMsg set MsgDetalle=''Agent writes a message to Administrator'' where TipoMsgChat=2
					Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes a global message'' where TipoMsgChat=3

					Print ''Mensajes default''
					DELETE [ccMsgFiles]
					DBCC CHECKIDENT (''[ccMsgFiles]'', RESEED, 0)
					INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default5'', ''Welcome message'' )
					INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default4'', ''Transfer message'' )
					INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default3'', ''Out of service message'' )
					INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default2'', ''After hours message'' )
					INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default1'', ''In queue message'' )
					INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default7'', ''No agents signed in message'' )
					INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default9'', ''VoiceMail message'')
					INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default10'', ''Overflow message'')
					INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default11'', ''DNC list'')

					Print ''Mensajes default chat''
					DELETE [ccRIAChatInboundMsgs]
					INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default5'', ''Welcome!'')
					INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default3'', ''Service currently unavailable'')
					INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default2'', ''Our schedule service has finished'')
					INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default1'', ''Please hold while one of our agents is available'')
					INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default7'', ''There are not available agents'')
					INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default10'', ''Your request can not be processed'')
					INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default12'', ''Chat session has been inactive for too long'')
					INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default13'', ''Chat session has finished'')';
		EXEC(@sql);

		SET @process = 'K026001-Configuración de callbacks Se agrega insert en el apartado de Estableciendo Status de llamadas (línea 780) Portugues'
		SET @sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosPortugues]
					AS
					Print ''Iniciando proceso de configuracion en Portugues''

					Print ''Estableciendo Horarios''
					Delete [dbo].[ccHorarios]
					DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
					INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Semana'', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
					INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Noite'', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
					INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Sabado'', 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
					INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Domingo'', 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

					Print ''Estableciendo Not Ready y graficas''
					Delete [ccRIANotReadyGraph]
					Delete [dbo].[ccTipoNotReady] 
					Delete [ccRIAGraphics]

					DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
					INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Não Clasified'')
					INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Pausa'')
					INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Casa de banho'')
					INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Com o cliente'')
					INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Supervisor'')
					INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Esclarecimento'')
					INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Reunião'')
					INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Almoço'')
					INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Sistemas'')
					INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Outros '')

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
					INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, ''Inicial'')
					INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Fora da agenda'')
					INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Fora de serviço'')
					INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''Não há agentes conectados'')
					INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''Em espera'')
					INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandonado'')
					INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Tempo de transbordo'')
					INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Tamanho da fila de transbordo'')
					INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''Com Mensagem'')
					INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10,''Mensagem atribuída'')
					INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11,''Atribuído'')
					INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12,''Mensagem compareceram'')
					INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12,''Abandonada (Reminder)'')
					update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8, 18 )

					Print ''Estableciendo los tipos de dias''
					TRUNCATE TABLE [dbo].[ccTipoDias]
					INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (1, ''segunda-feira'')
					INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (2, ''terça-feira'')
					INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (3, ''quarta-feira'')
					INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (4, ''quinta-feira'')
					INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (5, ''sexta-feira'')
					INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (6, ''sábado'')
					INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (7, ''domingo'')

					Print ''Estableciendo resultados de marcacion''
					TRUNCATE TABLE [dbo].[ccTipoResultadoDial]
					INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Resposta'')
					INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Ocupado'')
					INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Não resposta'')
					INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax / Modem'')
					INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
					INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Outros'')
					INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10,''NOservice'')
					INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11,''Correio de Voz / Máquina'')
					INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12,''Circuito ocupado'')
					INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13,''Cancelado'')

					Print ''Estableciendo los tipos de estado de los agentes''
					DELETE [dbo].[ccTipoStatusAgente]
					INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, ''LogOut'')
					INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, ''Desconhecido'')
					INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, ''Not Ready'')
					INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, ''Pronto'')
					INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, ''Conversando'')
					INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, ''Transferência'')
					INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, ''Wrapup'')
					INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, ''Outros'')
					INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, ''Cliente'')
					INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, ''Tocando'')
					INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11,''Problema'')
					INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21,''Espere por chamada manualmente'')

					Print ''Estableciendo los tipos de usuario''
					Delete [dbo].[ccTipoUsers]
					INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, ''Agente'')
					INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, ''Supervisor'')
					INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, ''Acesso AVRS'')

					Print ''Estableciendo los dias''
					Delete [dbo].[ccDias]
					SET IDENTITY_INSERT [dbo].[ccDias] ON
					INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (1, ''domingo'')
					INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (2, ''segunda-feira'')
					INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (3, ''terça-feira'')
					INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (4, ''quarta-feira'')
					INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (5, ''quinta-feira'')
					INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (6, ''sexta-feira'')
					INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (7, ''sábado'')
					SET IDENTITY_INSERT [dbo].[ccDias] OFF

					truncate table cstoTarifa

					Print ''Estableciendo los tipos de llamada''
					delete cstoTipoLlamada

					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''National LD'',''12'',''01%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Mobile'',''13'',''044%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''LD Mobile'',''13'',''045%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''USA LD'',''13'',''001%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''Inter LD'',''0'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''2-digit Local Area Code'',''8'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''3-digit Local Area Code'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''4-digit Local Area Code'',''6'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''2-digit Local Mobile Area Code'',''10'',''15%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''3-digit Local Mobile Area Code'',''9'',''15%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''4-digit Local Mobile Area Code'',''8'',''15%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Long Distance'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Long Distance Mobile'',''13'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Mobile'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''National LD'',''11'',''1%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''National LD'',''10'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Mobile'',''11'',''04%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Mobile'',''11'',''07%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''Inter LD'',''13'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''Old LD'',''9'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Mobile'',''10'',''05%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''New LD'',''11'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''Inter LD'',''13'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''Inter LD'',''0'',''0011%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Mobile'',''10'',''04%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Mobile '',''8'',''6%|7%|8%|9%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''9-digit Mobile'',''9'',''9%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''National LD'',''10'',''02%|03%|04%|05%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''National Mobile LD'',''10'',''06%|07%|08%|09%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''9-digit National Mobile LD'',''11'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''International LD'',''19'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Mobile'',''8'',''3%|4%|5%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''National LD'',''8'',''7%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''International LD'',''8'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''SIP Telephony'',''8'',''4%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Mobile Telephony'',''8'',''5%|6%|7%|8%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''International LD'',''0'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Reverse Charge'',''10'',''800%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Premium Rate'',''10'',''90%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Internet Access'',''10'',''900%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Special'',''0'',''08%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Landline'',''8'',''2%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Mobile'',''8'',''6%|7%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''International LD'',''0'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Mobile'',''9'',''6%|7%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''International LD'',''0'',''00%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Webservices'',''9'',''5%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''National LD'',''9'',''0%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Mobile'',''9'',''9%'')
					INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''Inter LD'',''0'',''00%'')

					Print ''Estableciendo los movimientos de lista negra''
					Delete [dbo].[ccTipoMovsListaNegra]
					SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] ON
					INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Adicionado à lista negra'')
					INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Bloqueado no carregamento'')
					INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Removido da campanha'')
					INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Substituído da lista negra'')
					INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Excluído da lista negra'')
					INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Adicionado por Disposição'')
					INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, ''Carregar lista negra'')
					INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, ''Carga cliente lista negra'')
					SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] OFF

					Print ''Estableciendo los tipos de calificacion''
					Delete [dbo].[ccTipoCalif]
					INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, ''Peça informações Geral'', 0)
					INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, ''Chame hung'', 0)
					INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, ''Wrong Number'', 0)

					Print ''Estableciendo los tipos de calificacion de salida''
					Delete [dbo].[ccTipoCalifOUT]
					INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, ''Chamada eficaz'' , 0, 0, 1)
					INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, ''Deixe um recado '', 0, 1, 2)
					INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, ''Wrong Number'', 0, 1, 3)

					--Pendiente validar rpoveedores portugal
					--Print ''Estableciendo proveedores''
					--Delete [dbo].[cstoProvedor]
					--DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
					--INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Carrier 1'')

					Print ''Tipo Msg ChatLog'' -- No se hace delete ni truncate ya que se perderia la integridad si ya hay registros, los id ya deberian estar creados por lo cual se genera el update
					Update ccRIAChat_TipoMsg set MsgDetalle=''Administrador escreve única mensagem para um agente'' where TipoMsgChat=1
					Update ccRIAChat_TipoMsg set MsgDetalle=''Agente escreve uma mensagem para o Administrador'' where TipoMsgChat=2
					Update ccRIAChat_TipoMsg set MsgDetalle=''Administrador escreve uma mensagem global'' where TipoMsgChat=3

					Print ''Mensajes defualt''
					DELETE [dbo].[ccMsgFiles]
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default5'', ''Mensagem de boas vindas'')
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default4'', ''Mensagem de transferência'')
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default3'', ''Mensagem de falta de serviço'')
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default2'', ''Depois de horas de mensagens'')
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default1'', ''Na fila de mensagens'')
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default7'', ''Nenhum agente assinado em mensagem'')
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default9'', ''Mensagem de voz'')
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default10'', ''Mensagem de Overflow'')
					INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default11'', ''Lista DNC'')

					Print ''Mensajes default chat''
					DELETE [dbo].[ccRIAChatInboundMsgs]
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default5'', ''Bem-vindo!'')
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default3'', ''Serviço está disponível no momento'')
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default2'', ''Nosso horário de serviço terminou'')
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default1'', ''Por favor aguarde enquanto um dos nossos agentes está disponível'')
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default7'', ''Há agentes não disponíveis'')
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default10'', ''Sua solicitação não pode ser processada'')
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default12'', ''Sessão de chat foi-inativo por muito tempo'')
					INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default13'', ''Sessão de chat terminou'')';
		EXEC(@sql);

		SET @process = 'K026001-Configuración de callbacks update para RiaLog para la actualización de las etiquetas'
		SET @sql = 'UPDATE ccRIALog_Operation SET descripcion = ''Editar configuración|Edit settings''
					WHERE operationType = 130';
		EXEC(@sql);

		SET @process = 'K026001-Configuración de callbacks update para RiaLog para la actualización de las etiquetas'
		SET @sql = 'UPDATE ccRIALog_Module SET descripcion = ''Devolución de llamadas|Callback Configuration'' 
					WHERE module_id = 37';
		EXEC(@sql);

		SET @process = 'K026001-Configuración de callbacks se modifico el sp [ccsp_RIAAbandon_Config] en donde se agrego la columna phoneFilter para la consulta de los callbacks (en @Type 2))'
		SET @sql = 'ALTER procedure [dbo].[ccsp_RIAAbandon_Config]
					@Type smallint, -- 1:Muestra ACD | 2:Muestra Tiempos y Status (ACD) | 3:Actualiza Configuracion
					@User_id smallint,
					@Inbound_id smallint=null,
					@minCallBackAbandon varchar(10)=null,
					@minCallBackAbandonXpire varchar(10)=null,
					@statuscall_id_Array varchar(1000)=null,
					@telFormato TinyInt= null

					as
					set nocount on
					declare @IDarea smallint
					select @IDarea=IDarea from ccUsers where user_id=@user_id

					if isnull(@IDarea,'''')=''''
					 begin
					  select -1, ''invalid user area''
					  return(0)
					 end

					if @Type=1
					 begin
					  select distinct I.inbound_id, I.descripcion, A.frame, C.cam_procesando
					  from ccinbound I join ccRIAinboundGraph G on I.inbound_id = G.inbound_id
					  join ccRIAGraphics A on G.graphic_id = A.graphic_id
					  join ccCamps C on I.cam_id=C.cam_id
					  where A.type_id = 1 and I.cam_id is not null and I.IDArea=@IDarea
					  order by descripcion
					  return(0)
					 end

					if not exists(select inbound_id from ccInbound where cam_id is not null and inbound_id=@inbound_id and IDArea=@IDArea)
					 begin
					  select -2, ''invalid inbound_id''
					  return(0)
					 end

					if @Type=2
					 begin
					  select @statuscall_id_Array = statuscall_id_Array from ccInbound where inbound_Id=@inbound_Id
					  select 0 [type], (minCallBackAbandon/60) setHrs, (minCallBackAbandon-((minCallBackAbandon/60)*60)) setMin, 
					  (minCallBackAbandonXpire/60) expHrs, (minCallBackAbandonXpire-((minCallBackAbandonXpire/60)*60)) expMin, 
					  null statusCall_id,null descripcion,null chk,telFormato phoneFilter
					  from ccInbound where inbound_id=@Inbound_id
					  union
					  select 1, null, null, null, null, SL.statusCall_id, SL.descripcion, cast(cast(isnull(F.value,0) as bit)as tinyint) chk, null phoneFilter
					  from ccStatusLLamada SL left join dbo.fn_RIASplitDelimited(@statuscall_id_Array, '','') 
					  F on SL.statusCall_id = F.value where SL.inAbandonConfig=1 
					  order by [type], descripcion
					  return(0)
					 end

					if @Type=3
					 begin
					  update ccInbound set 
					   minCallBackAbandon=case when @minCallBackAbandon is null then minCallBackAbandon else @minCallBackAbandon end,
					   minCallBackAbandonXpire=case when @minCallBackAbandonXpire is null then minCallBackAbandonXpire else @minCallBackAbandonXpire end,
					   statuscall_id_Array=case when @statuscall_id_Array is null then statuscall_id_Array else @statuscall_id_Array end,
					   telFormato = case when @telFormato is null then telFormato else @telFormato end   
					   where inbound_id=@Inbound_id
					  return(0)
					 end

					set nocount off';
		EXEC(@sql);
		---------------------------------------END K026001-Configuración de callbacks IVAN (GERARDO)-----------------------------------------
		--------------------------------BEGIN CW-7706 MARCO GARCÍA -----------------------------------------------------------------------------------------

	SET @process = 'CW-7706 delete procedure ccsp_GalateaAdminUploadBLst'
	SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaAdminUploadBLst'')
		BEGIN
			DROP PROCEDURE ccsp_GalateaAdminUploadBLst;
		END';
	EXEC(@sql);

	SET @process = 'CW-7706 create procedure ccsp_GalateaAdminUploadBLst'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaAdminUploadBLst]  @command TINYINT, @telephone VARCHAR(20) = 0, @idtipolista INT, @calKey AS VARCHAR(40) = NULL, @isKolob bit=0
		AS
		DECLARE @hashCalKey BIGINT, @hashPhone BIGINT

		SELECT @hashPhone = dbo.hashPhone(@telephone)

		IF @calKey IS NOT NULL
		BEGIN
		  SELECT @hashCalKey = dbo.hashList(@calKey)
		END

		IF @hashCalKey IS NULL
		BEGIN
		  IF @command IN (1, 4) --LookForNumber 
			AND EXISTS (
			  SELECT idtipolista
			  FROM cclistanegra
			  WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idtipolista
			  )
		  BEGIN
			SELECT 1

			RETURN (0)
		  END
		END
		ELSE
		BEGIN
		  IF @command IN (1, 4) --LookForNumber 
			AND EXISTS (
			  SELECT idtipolista
			  FROM cclistanegra
			  WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
			  )
		  BEGIN
			SELECT 1

			RETURN (0)
		  END
		END

		IF @command = 1 --Insert Number
		BEGIN
		  EXEC ccsp_InsertDNCList @telephone, @idtipolista, @hashCalKey

		  INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
		  VALUES (@telephone, 1, @idtipolista)

		  SELECT 200
		END

		IF @command = 2 --Delete Number
		BEGIN
		  --Check if phone number exists
			IF EXISTS(SELECT cln.Hashtel FROM dbo.ccListaNegra AS cln WHERE cln.Hashtel = @hashPhone AND cln.idtipolista = @idtipolista)
			BEGIN
				  IF @hashCalKey IS NULL
				  BEGIN
					--Check if request is from kolob or xion
					IF(@isKolob = 1)
					BEGIN
						--Check if phone number has calKey assigned
						SELECT @hashCalKey = cln.HashKey FROM dbo.ccListaNegra AS cln WHERE cln.Hashtel = @hashPhone AND cln.idtipolista = @idtipolista
						IF (@hashCalKey IS NOT NULL)
						BEGIN
							SELECT CAST(-1 AS INT) --Phone number need a calkey to delete it
						END
						ELSE
						BEGIN
							INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
							VALUES (@telephone, 5, @idtipolista)

							DELETE
							FROM cclistanegra
							WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idtipolista;
							SELECT CAST(1 AS INT)
						END
					END
					ELSE
					BEGIN
						INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
						VALUES (@telephone, 5, @idtipolista)

						DELETE
						FROM cclistanegra
						WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idtipolista
					END
				  END
				  ELSE
				  BEGIN
					--Check if phone with calKey exist
					IF NOT EXISTS (SELECT cln.HashKey FROM dbo.ccListaNegra AS cln WHERE cln.HashKey = @hashCalKey AND cln.idtipolista = @idtipolista)
					BEGIN
						SELECT CAST(-4 AS INT) --Phone Number with calKey not exist
					END
					ELSE
					BEGIN
						INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
						VALUES (@telephone, 5, @idtipolista)

						DELETE
						FROM cclistanegra
						WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
						IF(@isKolob = 1)
						BEGIN
							SELECT CAST(1 AS INT)
						END
					END
				  END
			END
			ELSE
			BEGIN
				SELECT CAST(-3 AS INT) --Phone Number not exist
			END
		  RETURN (0)
		END

		IF @command = 3 --Reemplaza
		BEGIN
		  INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
		  SELECT telefono, 4, @idtipolista
		  FROM cclistanegra
		  WHERE idtipolista = @idtipolista

		  DELETE
		  FROM cclistanegra
		  WHERE idtipolista = @idtipolista

		  RETURN (0)
		END

		IF @command = 5 --Delete by idtipolista
		BEGIN
		  UPDATE ccTiposListaNegra
		  SET STATUS = 0
		  WHERE idtipolista = @idtipolista

		  DELETE ccAgendaListaNegra
		  WHERE idagenda IN (
			  SELECT idagenda
			  FROM ccAgenda_TipolistaNegra
			  WHERE idtipolista = @idtipolista
			  )

		  DELETE ccAgenda_TipolistaNegra
		  WHERE idtipolista = @idtipolista

		  DELETE cccalifblacklist
		  WHERE idtipolista = @idtipolista

		  DELETE Camplistanegra
		  WHERE idtipolista = @idtipolista

		  DECLARE @telefono VARCHAR(10)

		  WHILE EXISTS (
			  SELECT telefono
			  FROM ccListaNegra
			  WHERE idtipolista = @idtipolista
			  )
		  BEGIN
			SELECT TOP 1 @hashPhone = Hashtel, @telefono = telefono
			FROM ccListaNegra
			WHERE idtipolista = @idtipolista

			INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
			VALUES (@telefono, 5, @idtipolista)

			DELETE
			FROM cclistanegra
			WHERE Hashtel = @hashPhone AND idtipolista = @idtipolista
		  END

		  RETURN (0)
		END

		SET NOCOUNT OFF'

	EXEC(@sql);

	--------------------------------END CW-7706 MARCO GARCÍA -----------------------------------------------------------------------------------------


	--------------------------------Jesus Esquipulas -----------------------------------------------------------------------------------------
	SET @process = 'K001085-Gestionar configuración de callbacks'
		SET @sql = 'if not exists (select * from ccPermissions where Permissions_Id = 10032)
		begin
					insert into ccPermissions values (10032,''Gestionar configuracion de callback'', ''RolesPermissionCallbackConf'',0,0,0,''N/A'',1)
		end';

		EXEC(@sql);

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
