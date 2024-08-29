/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2024/07/04
Description: KR140000
Database: CCenterRia
Required version: 126.16
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 16
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end
IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END
IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY
        
-------------------------------------------------- Start Uriel Cabrera K064009 -----------------------------------------------------------------------------------

SET @process = 'K064009 - Add Transfer Agent TipoStatusAge_id = 37- sp configuraIdiomaCatalogosEspañol '
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
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, convert(text, N''Fuera de horario'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, convert(text, N''Fuera de servicio'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, convert(text, N''Sin agentes conectados'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, convert(text, N''En espera'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, convert(text, N''Abandonada'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, convert(text, N''Desbordada (tiempo de espera excedido)'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, convert(text, N''Desbordada (número en espera excedido)'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, convert(text, N''Con Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, convert(text, N''Asignada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, convert(text, N''Asignada en falla'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, convert(text, N''Atendida Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, convert(text, N''Atendida'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, convert(text, N''Cancelada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, convert(text, N''Asignada y perdida'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, convert(text, N''Asignada en tono de línea'' collate SQL_Latin1_General_CP1_CI_AS))
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
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (34, convert(text, N''Dialogo de Whatsapp'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (35, convert(text, N''Inactivo'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (36, convert(text, N''En diálogo Correo'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (37, convert(text, ''Disponible auxiliar'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (38, convert(text, ''Transferencia Agent'' collate SQL_Latin1_General_CP1_CI_AS))

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
            INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default13'', ''La sesión de chat ha concluido'')'
EXEC(@sql);

SET @process = 'K064009 - Add Transfer Agent TipoStatusAge_id = 37- - sp configuraIdiomaCatalogosEnglish'
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
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Out of schedule'')
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Out of service'')
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''No online agents'')
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''On Hold'')
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandoned'')
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Overflow (wait time exceeded)'')
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Overflow (queue limit exceeded)'')
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''With Message'')
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, ''Assigned Message'')
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, ''Assigned on failure'')
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, ''Attended Message'')
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, ''Answered'')
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, ''Cancelled Message'')
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, ''Assigned and missed'')
            INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, ''Assigned on dial tone'')
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
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (34, convert(text, N''Whatsapp Dialog'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (35, convert(text, N''Idle'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (36, convert(text, N''Engaged Email'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (37, convert(text, ''Auxiliary available'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (38, convert(text, ''Transfer Agent'' collate SQL_Latin1_General_CP1_CI_AS))

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

SET @process = 'K064009 - Add Transfer Agent TipoStatusAge_id = 37- - sp configuraIdiomaCatalogosPortugues'
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
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Fora de horário'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Fora de serviço'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''Sem agentes conectados'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''Em espera'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandonada'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Estourada (tempo de espera excedido)'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Estourada (limite da fila excedido)'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''Com Mensagem'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10,''Mensagem atribuída'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11,''Atribuída em falha'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12,''Mensagem compareceram'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13,''Atendida'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14,''Cancelada mensagem'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15,''Atribuída e perdida'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16,''Atribuída em tom de linha'')
            INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (18,''Abandonada (Reminder)'')
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
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, ''LogOut'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, ''Desconhecido'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, ''Not Ready'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, ''Pronto'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, ''Conversando'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, ''Transferência'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, ''Wrapup'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, ''Outros'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, ''Cliente'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, ''Tocando'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11,''Problema'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21,''Espere por chamada manualmente'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N''ChatReq'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N''Chatting'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, ''Transferência Fail'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, ''Tocando Fail'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (30, ''ReconnectKolob'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, ''Ready PreviewPro'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (32, ''Preview'')
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (33, convert(text, N''Assisted'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (34, convert(text, N''Em diálogo Whatsapp'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (35, convert(text, N''Idle'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (36, convert(text, N''Em diálogo E-mail'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (37, convert(text, ''Auxiliar disponível'' collate SQL_Latin1_General_CP1_CI_AS))
            INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (38, convert(text, ''Agente de transferência'' collate SQL_Latin1_General_CP1_CI_AS))


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


SET @process = 'K064009 - Add Transfer Agent to ccTipoStatusAgente table'
SET @sql = '
    declare  @language int
    select @language = valor from ccSettings where setting_id = 27; 
    declare @descripTransfer varchar(200), @descripNotReadyAux varchar(200)
    if @language = 2 begin
        set @descripTransfer=''Agente de transferência''
        set @descripNotReadyAux=''Auxiliar disponível''
    end
    else if @language = 0 begin
        set @descripTransfer=''Transferencia Agent''
        set @descripNotReadyAux=''Disponible auxiliar''
    end
    else begin
        set @descripTransfer=''Transfer Agent''
        set @descripNotReadyAux=''Auxiliary available''
    end 

    if not exists (select 1 from ccTipoStatusAgente where TipoStatusAge_id = 37)
    begin
        insert into ccTipoStatusAgente values (37, @descripNotReadyAux)
    end
    else begin
      update  ccTipoStatusAgente set [descripcion]=@descripNotReadyAux  where TipoStatusAge_id = 37
    end

    if not exists(select * from ccTipoStatusAgente where TipoStatusAge_id = 38) begin
        INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (38, @descripTransfer)
    end
    else begin
      update  ccTipoStatusAgente set [descripcion]=@descripTransfer  where TipoStatusAge_id = 38
    end
'

EXEC(@sql)

    -------------------------------------------------- End Uriel Cabrera K064009 -----------------------------------------------------------------------------------

    -------------------------------------------------- Begin Joel Colin -----------------------------------------------------------------------------------
    SET @process = 'CW-8707   DROP PROCEDURE ccsp_WhatsAppInformation'
        SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_WhatsAppInformation'')
    begin
        DROP PROCEDURE ccsp_WhatsAppInformation;
    end'
        EXEC(@sql)
        
    SET @process = 'CW-8707 Se agrega etiqueta en Portugues when 2 then Sem classificação '
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_WhatsAppInformation]
@Option SMALLINT,
@InboundId SMALLINT = 0,
@ConversationId INT = 0,
@AgentsAvailables INT = 0,
@IncreaseDecreaseAgent BIT = NULL

AS
SET NOCOUNT ON

IF @Option = 0 BEGIN-- Reset TABLES
    TRUNCATE TABLE ccWAOperatingSummary;
    TRUNCATE TABLE ccWAAverageConversations;
    TRUNCATE TABLE ccLastMessageAgentByConversation;
END


IF @InboundId IS NULL or  
NOT EXISTS (SELECT * FROM ccInbound with(nolock) WHERE Inbound_id = @InboundId AND chat = 5) 
BEGIN
RETURN (-1)
END

    DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
    
IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
BEGIN
    IF EXISTS (SELECT * FROM ccWAAverageConversations with(nolock)
                WHERE InboundId = @InboundId
                AND (LastUpdate IS NULL
                OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
                OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
    BEGIN
        -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

        DECLARE @AverageConversationTime INT = 0;
        DECLARE @AverageDialogTime INT = 0;
        DECLARE @AverageWaitingTime INT = 0;
        DECLARE @MaximumWaitingTime INT = 0;
        DECLARE @DefaultValue INT = (SELECT CASE 
                WHEN defaultServiceLevelParameter IS NULL THEN 2 
                WHEN defaultServiceLevelParameter = 0 THEN 2
                ELSE defaultServiceLevelParameter END
        FROM contactMeanIn WHERE inboundId = @InboundId);
        SET @DefaultValue = @DefaultValue * 60;
        DECLARE @LessThanDefault INT = 0;
        DECLARE @ReceivedConversations INT = 0;
        DECLARE @ServiceLevel SMALLINT = 0;

        --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

        SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
                @AverageDialogTime = ROUND(AVG(tChatting), 4),
                @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
                @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
                @ReceivedConversations = COUNT(conversationDate),
                @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
        FROM ccWhatsAppConversations WHERE inboundId = @InboundId
        AND requestDate >= @Today

        SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

        ----------------------------------------------------- Update table --------------------------------------------------------

        IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
        BEGIN
            UPDATE ccWAAverageConversations
            SET AverageConversationTime = @AverageConversationTime,
                AverageDialogTime = @AverageDialogTime,
                AverageWaitingTime = @AverageWaitingTime,
                MaximumWaitingTime = @MaximumWaitingTime,
                ServiceLevel = @ServiceLevel,
                StatusUpdate = 0,
                LastUpdate = GETDATE()
            WHERE InboundId = @InboundId
        END
        ELSE
        BEGIN
            INSERT INTO ccWAAverageConversations (InboundId, AverageConversationTime, AverageDialogTime,
                                                    AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
            VALUES(@InboundId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
                    @ServiceLevel, 0 , GETDATE())
        END
    END
    --------------------------------- Results -----------------------------------

    if exists (select * from ccWAOperatingSummary with(nolock) where Inboundid=@InboundId
    and (OnQueue<0 or Assigned<0)
    ) begin                                
        set @Today =convert(date,getdate(),121)

        ;with waOperationSummary as(
                select 
        inboundId
        --,count(case when finishedBy=1 then 1 end) Attend
        ,count(case when onQueue=1 and finishedBy=0 then 1 end) onQueue
        ,count(case when finishedBy=0 and agentId>0 then 1 end) Assigned
        --,count(*) Request
        --,count(case when finishedBy=2 then 1 end) EndedBySystem
        from ccWhatsAppConversations with(nolock)
        where inboundId=@InboundId
        and requestDate>=@Today
        group by inboundId
        )
        update A 
        set A.OnQueue=B.onQueue, A.Assigned=B.Assigned
        from ccWAOperatingSummary A 
        inner join waOperationSummary B on A.Inboundid=B.inboundId
    end


    SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
        ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
        ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
        ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
        ISNULL(ServiceLevel, 0) AS ServiceLevel,
        ISNULL(Attended, 0) AS Attended,
        ISNULL(Assigned, 0) AS Assigned,
        ISNULL(OnQueue, 0) AS OnQueue,
        ISNULL(EndedBySystem, 0) AS EndedBySystem,
        ISNULL(Available, 0) AS Available,
        ISNULL(Request, 0) AS Request
    FROM ccWAAverageConversations conv
    RIGHT JOIN ccWAOperatingSummary summary ON conv.InboundId = summary.InboundId
    WHERE conv.inboundId = @InboundId OR summary.InboundId = @InboundId
END
ELSE IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
    -- Average Queue/Waiting Time, and Service Level)
    BEGIN
        IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
        BEGIN
            UPDATE ccWAAverageConversations SET StatusUpdate = 1
            WHERE InboundId = @InboundId
        END
        ELSE
        BEGIN
            INSERT INTO ccWAAverageConversations (InboundId, StatusUpdate)
            VALUES(@InboundId, 1)
        END
    END
ELSE IF @Option = 3 -- Save time from accepted conversation by agent
    BEGIN
        IF @ConversationId IS NOT NULL
        BEGIN
            UPDATE ccWhatsAppConversations SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
            --Save Conversation Assigned
            SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
            UPDATE ccWAOperatingSummary SET Assigned = (Assigned + 1) WHERE InboundId = @inboundId
            --EXEC ccsp_WhatsAppOperatingSummary @Option = 2, @InboundId = @CampIdTemp;
        END
    END
ELSE IF @Option = 4 -- Get Disposition Information
    BEGIN
        declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
        select @nIdioma = case valor 
            when 0 then ''Sin calificación''
            when 2 then ''Sem classificação'' 
            else ''No disposition'' end
        from ccsettings where setting_id = 27 -- 0esp
        SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
                        ISNULL(disposition.calif_id, 0) AS DispositionId,
                        COUNT(whatsConv.disposition) AS Total,
                        ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
                        COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
        FROM ccWhatsAppConversations whatsConv with(nolock) 
        LEFT JOIN cctipocalif disposition ON disposition.calif_id = whatsConv.disposition
        WHERE inboundId = @InboundId AND assignDate >= @Today
                and whatsConv.conversationStatus != 2
        GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
    END
ELSE IF @Option = 5 -- Get Subdisposition Information
    BEGIN
        SELECT relation.calif_id AS DispositionId,
                subDispositions.califSubDesc AS SubDispositionsName,
                COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
        FROM cctipoSubCalifRel relation
        INNER JOIN ccTipoCalifSub subDispositions ON subDispositions.califSub_id = relation.califSub_id
        INNER JOIN ccWhatsAppConversations whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
        WHERE whatsConv.inboundId = @InboundId AND
                whatsConv.assignDate >= @Today AND
                relation.tipoSubRel = 1
        GROUP BY subDispositions.califSubDesc, relation.calif_id
    END
ELSE IF @Option = 6 -- Agents Availables
    BEGIN
    IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @InboundId)
        BEGIN
            INSERT INTO ccWAOperatingSummary (InboundId, Available) VALUES (@InboundId, @AgentsAvailables);
        END
    ELSE
    BEGIN
        UPDATE ccWAOperatingSummary SET Available = @AgentsAvailables WHERE InboundId = @InboundId
    END
END

RETURN(0)
SET NOCOUNT OFF'
    EXEC(@sql)

    -------------------------------------------------- End Joel Colin -----------------------------------------------------------------------------------



    -------------------------------------------------- Begin Isaac -----------------------------------------------------------------------------------
    SET @process = 'DEV2-637 modificar sp ccsp_MultimediaCommon para obtener correctamente el caption'
    SET @sql = '
        IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_MultimediaCommon'')
        BEGIN
            DROP PROCEDURE ccsp_MultimediaCommon;
        END'
    EXEC(@sql)

    SET @process = 'DEV2-637 modificar sp ccsp_MultimediaCommon para obtener correctamente el caption'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_MultimediaCommon]
@Option AS SMALLINT,
@inboundId AS SMALLINT = 0,
@conversationId AS INT = 0,
@ServiceType AS SMALLINT = 0,
@status as SMALLINT =0,
@messagesList as varchar(max) = '''',
@agentId AS SMALLINT = 0,
@CampType bit =0
AS
BEGIN
    SET NOCOUNT ON;

    IF @Option = 0 --  Obtener lista de configuraciones de campañas
    BEGIN
        SELECT CAST(campaign.cam_id AS INT) AS Id,
               campaign.cam_descripcion AS [Name],
               ISNULL(configuration.number, '''') AS Phone,
               CAST(graphics.graphic_id AS INT) AS GraphicId,
               0 AS isMeta
        FROM ccCamps campaign 
        INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
        INNER JOIN ccWhatsAppNumbers configuration ON campaign.cam_id = configuration.camp_id
        WHERE configuration.status != 0 AND campaign.CampType = 5

        UNION ALL

        SELECT CAST(campaign.cam_id AS INT) AS Id, -- Meta WhatsApp
               campaign.cam_descripcion AS [Name],
               ISNULL(configuration.number, '''') AS Phone,
               CAST(graphics.graphic_id AS INT) AS GraphicId,
               1 AS isMeta
        FROM ccCamps campaign 
        INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
        INNER JOIN ccMetaWhatsAppNumbers configuration ON campaign.cam_id = configuration.Cam_Id
        WHERE configuration.status != 0 AND campaign.CampType = 5   
                                                            
    END

    ELSE IF @Option = 1 -- Obtener lista de configuraciones de ACDs
    BEGIN
        SELECT CAST(inbound.Inbound_id AS INT) AS Id,
               inbound.descripcion AS [Name],
               ISNULL(numbers.number, '''') AS Phone,
               CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
               inbound.tNotas AS WrapUpTime,
               CAST(graphics.graphic_id AS INT) AS GraphicId,
               0 AS isMeta
        FROM ccInbound inbound
        INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
        INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
        INNER JOIN ccWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.inboundId  
        WHERE inbound.Status != 0 AND configuration.meanContactTypeId = 5 AND numbers.status != 0 

        UNION ALL

        SELECT CAST(inbound.Inbound_id AS INT) AS Id, -- Meta WhatsApp
               inbound.descripcion AS [Name],
               ISNULL(numbers.number, '''') AS Phone,
               CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
               inbound.tNotas AS WrapUpTime,
               CAST(graphics.graphic_id AS INT) AS GraphicId,
               1 AS isMeta
        FROM ccInbound inbound
        INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
        INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
        INNER JOIN ccMetaWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.Inbound_Id
        WHERE inbound.Status != 0 AND configuration.meanContactTypeId = 5 AND numbers.status != 0 
                                                            
    END

     ELSE IF(@Option = 2)
    BEGIN
        DECLARE @OldAgentId INT = 0
        DECLARE @OldConversationId INT = 0

        IF @CampType = 0 BEGIN -- ACD
            SELECT @OldAgentId = conv.agentId,
                   @OldConversationId = rel.conversationIdBefore
            FROM ccWhatsAppConversationsRelationship rel 
            RIGHT JOIN ccWhatsAppConversations conv ON conv.conversationId = rel.conversationIdBefore
            WHERE rel.conversationIdAfter = @conversationId

            SELECT CAST(i.chat AS int) AS ServiceType,
                   CAST(c.conversationId AS int) AS ConversationID,
                   c.clientId AS ClientId,
                   cm.conexionInfo AS [To],
                   CAST(i.Inbound_id AS int) AS ACDId,
                   i.descripcion AS ACDName,
                   CAST(g.graphic_id AS int) AS ACDGraphicId,
                   CAST(cm.closeConversationTime AS int) AS [TimeOut],
                   CAST(cm.answerTimeOut AS int) AS [TimeOutWarning],
                   i.ExitWrapUpDisposition AS [ExitWrapUpDisposition],
                   i.tNotas AS [WrapUpTime],
                   i.ShowCalifWnd,
                   CAST(ISNULL(answerTimeoutClient, 30) AS int) AS [AnswerTimeoutClient],
                   ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS [SecTimeOutLastMessageAgent],
                   ISNULL(permission.AllowUnassign, 0) AS AllowUnassign,
                   ISNULL(permission.AllowSpam, 0) AS AllowSpam,
                   ISNULL(@OldAgentId, 0) AS OldAgentId,
                   ISNULL(@OldConversationId, 0) AS OldConversationId,
                   c.agentId AS AgentId,
                   ISNULL(c.IsAgentLoggingOut, 0) AS IsAgentLoggingOut,
                   ISNULL(cm.allowFileAttachments, 0) AS AllowFileAttachments
            FROM ccWhatsAppConversations c
            LEFT JOIN ccInbound i ON c.inboundId = i.Inbound_id 
            LEFT JOIN contactMeanIn cm ON i.Inbound_id = cm.inboundId    
            LEFT JOIN ccRIAInboundGraph g ON g.Inbound_id = i.Inbound_id
            LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
            LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
            WHERE c.conversationId = @conversationId

        END ELSE BEGIN -- Campaña
            SELECT @OldAgentId = conv.agentId,
                   @OldConversationId = rel.conversationIdBefore
            FROM ccWhatsAppConversationsRelationshipOut rel 
            RIGHT JOIN ccWhatsAppConversationsOut conv ON conv.conversationId = rel.conversationIdBefore
            WHERE rel.conversationIdAfter = @conversationId

            SELECT CAST(i.CampType AS int) AS ServiceType,
                   CAST(c.conversationId AS int) AS ConversationID,
                   c.clientId AS ClientId,
                   c.phoneCamp AS [To],
                   CAST(i.cam_id AS int) AS ACDId,
                   i.cam_descripcion AS ACDName,
                   CAST(g.graphic_id AS int) AS ACDGraphicId,
                   CAST(cm.closeConversationTime AS int) AS [TimeOut],
                   CAST(cm.answerTimeoutClient AS int) AS [TimeOutWarning],
                   i.exitAssisted AS [ExitWrapUpDisposition],              
                   CAST(i.cam_tnotas AS int) AS [WrapUpTime],
                   i.cam_ShowCalifWnd AS ShowCalifWnd, 
                   CAST(ISNULL(answerTimeoutClient, 30) AS int) AS [AnswerTimeoutClient],
                   ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS [SecTimeOutLastMessageAgent],
                   ISNULL(permission.AllowUnassign, 0) AS AllowUnassign,
                   ISNULL(permission.AllowSpam, 0) AS AllowSpam,
                   ISNULL(@OldAgentId, 0) AS OldAgentId,
                   ISNULL(@OldConversationId, 0) AS OldConversationId,
                   c.agentId AS AgentId,
                   ISNULL(cm.allowFileAttachments, 0) AS AllowFileAttachments
            FROM ccWhatsAppConversationsOut c
            LEFT JOIN ccCamps i ON c.camId = i.cam_id 
            LEFT JOIN contactMeanOut cm ON c.camId = cm.camp_id
            LEFT JOIN ccRIACampsGraph g ON g.cam_id = c.camId
            LEFT JOIN ccLastMessageAgentByConversationOut lm ON lm.conversationId = c.conversationId
            LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
            WHERE c.conversationId = @conversationId
        END
    END
    
     ELSE IF(@Option = 3)
    BEGIN
        IF @CampType = 0 BEGIN -- ACD
            SELECT CAST(inbound.Inbound_id AS INT) AS Id,
                   inbound.descripcion AS Name,
                   ISNULL(configuration.conexionInfo, '''') AS Phone,
                   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                   inbound.tNotas AS WrapUpTime,
                   CAST(ISNULL(graphics.graphic_id, 1) AS INT) AS GraphicId,
                   0 AS isMeta
            FROM ccInbound inbound
            INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
            INNER JOIN ccWhatsAppNumbers von ON von.inboundId = inbound.Inbound_id
            INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
            WHERE inbound.Inbound_id = @inboundId

            UNION ALL

            SELECT CAST(inbound.Inbound_id AS INT) AS Id, -- Meta WhatsApp
                   inbound.descripcion AS [Name],
                   ISNULL(numbers.number, '''') AS Phone,
                   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                   inbound.tNotas AS WrapUpTime,
                   CAST(graphics.graphic_id AS INT) AS GraphicId,
                   1 AS isMeta
            FROM ccInbound inbound
            INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
            INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
            INNER JOIN ccMetaWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.Inbound_Id 
            WHERE inbound.Inbound_id = @inboundId       
        END ELSE BEGIN
            SELECT CAST(campaign.cam_id AS INT) AS Id,
                   campaign.cam_descripcion AS [Name],
                   ISNULL(configuration.conexionInfo, '''') AS Phone,
                   CAST(ISNULL(configuration.answerTimeoutClient, 0) AS int) AS TimeOut,
                   CAST(campaign.cam_tnotas AS int) AS WrapUpTime,
                   CAST(graphics.graphic_id AS INT) AS GraphicId,
                   0 AS isMeta
            FROM ccCamps campaign
            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
            INNER JOIN ccWhatsAppNumbers von ON von.camp_id = campaign.cam_id
            INNER JOIN contactMeanOut configuration ON campaign.cam_id = configuration.camp_id 
            WHERE campaign.cam_id = @inboundId

            UNION ALL

            SELECT CAST(campaign.cam_id AS INT) AS Id, -- Meta WhatsApp
                   campaign.cam_descripcion AS [Name],
                   ISNULL(configuration.number, '''') AS Phone,
                   CAST(ISNULL(configurationOut.answerTimeoutClient, 0) AS int) AS TimeOut,
                   CAST(campaign.cam_tnotas AS int) AS WrapUpTime,
                   CAST(graphics.graphic_id AS INT) AS GraphicId,
                   1 AS isMeta
            FROM ccCamps campaign 
            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
            INNER JOIN ccMetaWhatsAppNumbers configuration ON campaign.cam_id = configuration.Cam_Id
            INNER JOIN contactMeanOut configurationOut ON (campaign.cam_id = configurationOut.camp_id AND campaign.cam_id = @inboundId)
            WHERE campaign.cam_id = @inboundId
        END
    END

    ELSE IF(@Option = 4)
    Begin
        DECLARE @pathFile AS VARCHAR(MAX);
        DECLARE @filetype AS VARCHAR(5);
        DECLARE @mensajes TABLE(idMessage VARCHAR(150));
        DECLARE @tmpMessageConversations TABLE(
            [messageId] VARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
            [conversationId] INT NOT NULL,
            [timeStampMessage] DATETIME NOT NULL,
            [originType] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
            [price] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
            [messageIdUi] INT NULL,
            [currency] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [typeMessage] VARCHAR(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [content] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [clientNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [vonageNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [timeStampMessageUTC] DATETIME NULL,
            [messageStatus] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
        );


       INSERT INTO @mensajes
       SELECT value FROM dbo.fn_RIASplitDelimited(@messagesList, '','');

                                                        
      IF (@CampType = 0)
        BEGIN
            INSERT INTO @tmpMessageConversations (messageId, conversationId, timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus)
            SELECT messageId, conversationId, timeStampMessageUTC AS timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus
            FROM ccWAMessagesConversations 
            WHERE messageId IN (SELECT idMessage FROM @mensajes);
        END
        IF (@CampType = 1)
        BEGIN
            INSERT INTO @tmpMessageConversations (messageId, conversationId, timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus)
            SELECT messageId, conversationId, timeStampMessageUTC AS timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus
            FROM ccWAMessagesConversationsOut 
            WHERE messageId IN (SELECT idMessage FROM @mensajes);
        END

        SELECT @pathFile = valor FROM ccSettings WHERE setting_id = 230;

        SELECT
            messageId AS MessageId,
            messageStatus AS Status,
            originType AS Origin,
            CASE 
                WHEN originType = ''Client'' THEN 3
                WHEN originType = ''Agent'' THEN 2
                WHEN originType = ''Admin'' THEN 1
                ELSE 0 
            END AS OriginType,
            timeStampMessage AS [Timestamp],
            CASE 
                WHEN typeMessage IN (''text'', ''template'', ''image'', ''video'') THEN content 
                ELSE '''' 
            END AS Content,
            typeMessage AS Type,
            CASE 
                WHEN typeMessage IN (''file'', ''image'', ''video'') THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 1), '':'') WHERE id = 2)
                WHEN typeMessage NOT IN (''text'', ''location'', ''file'', ''template'', ''image'', ''video'') THEN content
                ELSE '''' 
            END AS Caption,
            CASE 
                WHEN originType = ''Client'' THEN 
                    CASE
                        WHEN typeMessage = ''text'' OR typeMessage = ''location'' OR (typeMessage = ''file'' AND (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 2), '':'') WHERE id = 2) = '''') THEN ''''
                        ELSE @pathFile + char(92) + CASE WHEN @CampType = 0 THEN ''INBOUND'' ELSE ''OUTBOUND'' END + char(92) + CAST(conversationId / 1000 AS VARCHAR(30)) + char(92) + CAST(conversationId AS VARCHAR(20)) + char(92) + typeMessage + char(92) + messageId + 
                            CASE
                                WHEN typeMessage = ''video'' THEN ''.mp4''
                                WHEN typeMessage = ''image'' THEN ''.jpg''
                                WHEN typeMessage = ''audio'' THEN ''.mp3''
                                WHEN typeMessage = ''file'' THEN (SELECT SUBSTRING(content, LEN(content) - CHARINDEX(''.'', REVERSE(content)) + 1, LEN(content)))
                                ELSE '''' 
                            END
                    END
                ELSE 
                    CASE
                        WHEN typeMessage = ''text'' OR typeMessage = ''location'' OR typeMessage = ''template'' THEN ''''
                        ELSE content
                    END
            END AS [Url],
            CASE 
                WHEN typeMessage = ''file'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 3), '':'') WHERE id = 2)
                ELSE '''' 
            END AS [FileSize],
            CASE 
                WHEN typeMessage = ''file'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 4), '':'') WHERE id = 2)
                ELSE '''' 
            END AS [FileName],
            CASE 
                WHEN typeMessage = ''location'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 1), '':'') WHERE id = 2)
                ELSE '''' 
            END AS [Address],
            CASE 
                WHEN typeMessage = ''location'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 2), '':'') WHERE id = 2)
                ELSE '''' 
            END AS [Lat],
            CASE 
                WHEN typeMessage = ''location'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 3), '':'') WHERE id = 2)
                ELSE '''' 
            END AS [Long],
            CASE 
                WHEN typeMessage = ''location'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 4), '':'') WHERE id = 2)
                ELSE '''' 
            END AS [Name],
            CASE 
                WHEN typeMessage = ''location'' THEN ''https://www.google.com/maps/search/'' + (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 2), '':'') WHERE id = 2) + '','' + (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 3), '':'') WHERE id = 2)
                ELSE '''' 
            END AS [LocationURL]
        FROM @tmpMessageConversations
        ORDER BY Timestamp ASC;
    END
                                                                            
    ELSE IF(@Option = 5)
    BEGIN
        if @CampType =0 begin
            SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
                FROM contactMeanIn
            WHERE inboundId = @inboundId
        end 
        else begin
            SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
                FROM contactMeanOut
            WHERE camp_id = @inboundId
        end 
    END
    ELSE IF(@Option = 6)
    BEGIN
        SELECT [Login] AS ''OriginName''
            FROM [ccUsers]
        WHERE [User_id] = @agentId
    END
END'
    EXEC(@sql)

    SET @process = 'DEV2-637 modificar sp ccsp_AgentHistoricalChat para obtener correctamente el caption del historial de conversaciones'
    SET @sql = '
        IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_AgentHistoricalChat'')
        BEGIN
            DROP PROCEDURE ccsp_AgentHistoricalChat;
        END'
    EXEC(@sql)

    SET @process = 'DEV2-637 modificar sp ccsp_AgentHistoricalChat para obtener correctamente el caption del historial de conversaciones'
    SET @sql = '
        CREATE PROCEDURE [dbo].[ccsp_AgentHistoricalChat] 
        @option SMALLINT, 
        @clientNum VARCHAR(15) = '''', 
        @conversationId AS INT = 0, 
        @inboundId AS SMALLINT = 0, 
        @serviceType AS SMALLINT = 0,
        @campType AS INT = 0
        AS
        BEGIN
            IF @option = 1 --whatsapp, get conversation ids
            BEGIN
                DECLARE @tempId INT = 0
                IF @campType = 0 -- INBOUND
                BEGIN
                    SELECT conversationId AS ConversationId,
                        @campType AS CampType,
                        assignDate AS Date
                    FROM ccWhatsAppConversations with(nolock)
                    WHERE clientId = @clientNum AND assignDate IS NOT NULL
                    GROUP BY conversationId, assignDate
                END
                ELSE
                BEGIN  -- OUTBOUND
                    SELECT conversationId AS ConversationId,
                        @campType AS CampType,
                        assignDate AS Date
                    FROM ccWhatsAppConversationsOut with(nolock)
                    WHERE clientId = @clientNum AND assignDate IS NOT NULL
                    GROUP BY conversationId, assignDate
                END
            END

            IF @option = 2 --whatsapp, get acdId by conversation id
            BEGIN
                IF @campType = 0
                BEGIN
                    SELECT CAST(inboundId AS INT)
                    FROM [ccWhatsAppConversations] with(nolock)
                    WHERE conversationId = @conversationId
                END
                ELSE
                BEGIN
                    SELECT CAST(camId AS INT)
                    FROM [ccWhatsAppConversationsOut] with(nolock)
                    WHERE conversationId = @conversationId
                END
            END

            IF @option = 3 --get data conversation
            BEGIN
                DECLARE @OldAgentId INT = 0
                DECLARE @OldConversationId INT = 0

                SELECT @OldAgentId = conv.agentId, @OldConversationId = rel.conversationIdBefore
                FROM ccWhatsAppConversationsRelationship rel with(nolock)
                RIGHT JOIN ccWhatsAppConversations conv with(nolock) ON conv.conversationId = rel.conversationIdBefore
                WHERE rel.conversationIdAfter = @conversationId

                SELECT cast(i.chat AS INT) AS ServiceType, cast(c.conversationId AS INT) AS ConversationID, c.clientId AS ClientId, cm.conexionInfo AS [To], cast(i.Inbound_id AS INT) AS ACDId, i.descripcion AS ACDName, cast(g.
                        graphic_id AS INT) AS ACDGraphicId, cast(cm.closeConversationTime AS INT) AS [TimeOut], cast(cm.answerTimeOut AS INT) AS [TimeOutWarning], i.ExitWrapUpDisposition AS [ExitWrapUpDisposition], i.tNotas AS 
                    [WrapUpTime], i.ShowCalifWnd, cast(ISNULL(answerTimeoutClient, 30) AS INT) AS [AnswerTimeoutClient], ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS 
                    [SecTimeOutLastMessageAgent], isnull(permission.AllowUnassign, 0) AS AllowUnassign, isnull(permission.AllowSpam, 0) AS AllowSpam, ISNULL(@OldAgentId, 0) AS OldAgentId, ISNULL(@OldConversationId, 0) AS 
                    OldConversationId, c.agentId AS AgentId
                FROM ccInbound i
                INNER JOIN contactMeanIn cm ON i.Inbound_id = cm.inboundId
                INNER JOIN ccWhatsAppConversations c with(nolock) ON (
                        c.inboundId = i.Inbound_id
                        AND c.conversationId = @conversationId
                        )
                INNER JOIN ccRIAInboundGraph g ON g.Inbound_id = i.Inbound_id
                LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
                LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
                WHERE i.chat = @serviceType
                    AND i.Inbound_id = @inboundId

            END

            IF @option = 4 --get messages from conversation id
            BEGIN
                DECLARE @filetype AS VARCHAR(5)
                DECLARE @camp_acd_id INT = 0;

                IF @campType = 0
                BEGIN
                    SET @camp_acd_id = (SELECT inboundId FROM ccWhatsAppConversations with(nolock) WHERE conversationId = @conversationId)

                    SELECT messageId AS MessageId, messageStatus AS STATUS, originType AS Origin, CASE 
                    WHEN originType = ''Client''
                        THEN 3
                    WHEN originType = ''Agent''
                        THEN 2
                    WHEN originType = ''Admin''
                        THEN 1
                    ELSE 0
                    END AS OriginType, timeStampMessage AS [Timestamp], CASE 
                    WHEN typeMessage <> ''text''
                        THEN ''''
                    ELSE content
                    END AS Content, typeMessage AS Type, CASE 
                    WHEN typeMessage IN (''image'', ''file'', ''video'')
                        THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 1), '':'') WHERE id = 2)
                    WHEN typeMessage NOT IN (''text'', ''location'')
                        THEN content
                    ELSE ''''
                    END AS Caption, CASE 
                    WHEN originType = ''Client''
                        THEN CASE 
                                WHEN typeMessage = ''text''
                                    OR typeMessage = ''location''
                                    THEN ''''
                                ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + ''INBOUND'' + CHAR(92)+ CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
                                    typeMessage + CHAR(92) + CHAR(92) + messageId + ''.'' + CASE 
                                        WHEN typeMessage = ''video''
                                            THEN ''mp4''
                                        WHEN typeMessage = ''image''
                                            THEN ''jpg''
                                        WHEN typeMessage = ''audio''
                                            THEN ''mp3''
                                        WHEN typeMessage = ''file''
                                            THEN (
                                                    SELECT substring(content, CHARINDEX(''.'', content) + 1, len(content))
                                                    )
                                        ELSE ''''
                                        END
                                END
                    ELSE CASE 
                            WHEN typeMessage = ''text''
                                OR typeMessage = ''location''
                                THEN ''''
                            ELSE content
                            END
                    END AS [Url], CASE 
                    WHEN typeMessage = ''location''
                        THEN (
                                SELECT value
                                FROM dbo.fn_RIASplitDelimited((
                                            SELECT value
                                            FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                            WHERE id = 1
                                            ), '':'')
                                WHERE id = 2
                                )
                    ELSE ''''
                    END AS [Address], CASE 
                    WHEN typeMessage = ''location''
                        THEN (
                                SELECT value
                                FROM dbo.fn_RIASplitDelimited((
                                            SELECT value
                                            FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                            WHERE id = 2
                                            ), '':'')
                                WHERE id = 2
                                )
                    ELSE ''''
                    END AS [Lat], CASE 
                    WHEN typeMessage = ''location''
                        THEN (
                                SELECT value
                                FROM dbo.fn_RIASplitDelimited((
                                            SELECT value
                                            FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                            WHERE id = 3
                                            ), '':'')
                                WHERE id = 2
                                )
                    ELSE ''''
                    END AS [Long], CASE 
                    WHEN typeMessage = ''location''
                        THEN (
                                SELECT value
                                FROM dbo.fn_RIASplitDelimited((
                                            SELECT value
                                            FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                            WHERE id = 4
                                            ), '':'')
                                WHERE id = 2
                                )
                    ELSE ''''
                    END AS [Name], CASE 
                    WHEN typeMessage = ''location''
                        THEN ''https://www.google.com/maps/search/'' + (
                                SELECT value
                                FROM dbo.fn_RIASplitDelimited((
                                            SELECT value
                                            FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                            WHERE id = 2
                                            ), '':'')
                                WHERE id = 2
                                ) + '','' + (
                                SELECT value
                                FROM dbo.fn_RIASplitDelimited((
                                            SELECT value
                                            FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                            WHERE id = 3
                                            ), '':'')
                                WHERE id = 2
                                )
                    ELSE ''''
                    END AS [LocationURL],
                    graphics.graphic_id AS GraphicId
                    FROM ccWAMessagesConversations
                    LEFT JOIN ccRIAInboundGraph graphics ON Inbound_id = @camp_acd_id
                    WHERE conversationId = @conversationId
                    ORDER BY TIMESTAMP ASC
                END
                ELSE
                BEGIN
                    SET @camp_acd_id = (SELECT camId FROM ccWhatsAppConversationsOut with(nolock) WHERE conversationId = @conversationId)

                    SELECT messageId AS MessageId, messageStatus AS STATUS, originType AS Origin, CASE 
                    WHEN originType = ''Client''
                        THEN 3
                    WHEN originType = ''Agent''
                        THEN 2
                    WHEN originType = ''Admin''
                        THEN 1
                    ELSE 0
                    END AS OriginType, timeStampMessage AS [Timestamp], CASE 
                    WHEN typeMessage IN (''text'', ''template'')
                        THEN content 
                    ELSE ''''
                    END AS Content, typeMessage AS Type, CASE 
                    WHEN typeMessage IN (''image'', ''file'', ''video'')
                        THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 1), '':'') WHERE id = 2)
                    WHEN typeMessage NOT IN (''text'', ''location'', ''template'')
                        THEN content
                    ELSE ''''
                    END AS Caption, CASE 
                    WHEN originType = ''Client''
                        THEN CASE 
                                WHEN typeMessage = ''text''
                                    OR typeMessage = ''location''
                                    THEN ''''
                                ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + ''OUTBOUND'' + CHAR(92)+ CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
                                    typeMessage + CHAR(92) + CHAR(92) + messageId + ''.'' + CASE 
                                        WHEN typeMessage = ''video''
                                            THEN ''mp4''
                                        WHEN typeMessage = ''image''
                                            THEN ''jpg''
                                        WHEN typeMessage = ''audio''
                                            THEN ''mp3''
                                        WHEN typeMessage = ''file''
                                            THEN (
                                                    SELECT substring(content, CHARINDEX(''.'', content) + 1, len(content))
                                                    )
                                        ELSE ''''
                                        END
                                END
                    ELSE CASE 
                            WHEN typeMessage = ''text''
                                OR typeMessage = ''location''
                                OR typeMessage = ''template''
                                THEN ''''
                            ELSE content
                            END
                    END AS [Url], CASE 
                    WHEN typeMessage = ''location''
                        THEN (
                                SELECT value
                                FROM dbo.fn_RIASplitDelimited((
                                            SELECT value
                                            FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                            WHERE id = 1
                                            ), '':'')
                                WHERE id = 2
                                )
                    ELSE ''''
                    END AS [Address], CASE 
                    WHEN typeMessage = ''location''
                        THEN (
                                SELECT value
                                FROM dbo.fn_RIASplitDelimited((
                                            SELECT value
                                            FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                            WHERE id = 2
                                            ), '':'')
                                WHERE id = 2
                                )
                    ELSE ''''
                    END AS [Lat], CASE 
                    WHEN typeMessage = ''location''
                        THEN (
                                SELECT value
                                FROM dbo.fn_RIASplitDelimited((
                                            SELECT value
                                            FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                            WHERE id = 3
                                            ), '':'')
                                WHERE id = 2
                                )
                    ELSE ''''
                    END AS [Long], CASE 
                    WHEN typeMessage = ''location''
                        THEN (
                                SELECT value
                                FROM dbo.fn_RIASplitDelimited((
                                            SELECT value
                                            FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                            WHERE id = 4
                                            ), '':'')
                                WHERE id = 2
                                )
                    ELSE ''''
                    END AS [Name], CASE 
                    WHEN typeMessage = ''location''
                        THEN ''https://www.google.com/maps/search/'' + (
                                SELECT value
                                FROM dbo.fn_RIASplitDelimited((
                                            SELECT value
                                            FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                            WHERE id = 2
                                            ), '':'')
                                WHERE id = 2
                                ) + '','' + (
                                SELECT value
                                FROM dbo.fn_RIASplitDelimited((
                                            SELECT value
                                            FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                            WHERE id = 3
                                            ), '':'')
                                WHERE id = 2
                                )
                    ELSE ''''
                    END AS [LocationURL],
                    graphics.graphic_id AS GraphicId
                    
                    FROM ccWAMessagesConversationsOut
                    LEFT JOIN ccRIACampsGraph graphics ON cam_id = @camp_acd_id
                    WHERE conversationId = @conversationId
                    ORDER BY TIMESTAMP ASC
                END
                
            END

            IF @option = 5 --get if conversation is reassigned
            BEGIN
                IF @campType = 0
                BEGIN
                    SELECT CASE 
                        WHEN EXISTS (
                                SELECT *
                                FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationship] with(nolock)
                                WHERE conversationIdAfter = @conversationId
                                )
                            THEN CAST(1 AS BIT)
                        ELSE CAST(0 AS BIT)
                        END
                END
                ELSE
                BEGIN
                    SELECT CASE 
                        WHEN EXISTS (
                                SELECT *
                                FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationshipOut] with(nolock)
                                WHERE conversationIdAfter = @conversationId
                                )
                            THEN CAST(1 AS BIT)
                        ELSE CAST(0 AS BIT)
                        END
                END
            END
        END
    '
    EXEC(@sql)

    --------------------------------------------------- End Isaac ------------------------------------------------------------------------------------
    --------------------------------------------------- Start Jonathan Ramirez ------------------------------------------------------------------------------------

    SET @process = 'Se modifica SP ccsp_WhatsAppInformationOut, calificaciones, se agrega etiqueta en PT Sem classificação';
    SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformationOut]
    @Option SMALLINT,
    @camId SMALLINT = 0,
    @ConversationId INT = 0,
    @AgentsAvailables INT = 0,
    @IncreaseDecreaseAgent BIT = NULL

    AS
    SET NOCOUNT ON
    IF @camId>0 and NOT EXISTS (SELECT * FROM ccCamps WHERE cam_Id = @camId AND CampType = 5) BEGIN
        print (''Camp Is Not WhatsApp'')
        return(-1);
    End

     
          
    DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
    --set @Today SMALLDATETIME = ''2022-03-24''
    IF @Option = 0 BEGIN-- Reset TABLES
        TRUNCATE TABLE ccWAConversationsResult
        TRUNCATE table ccWAOperatingSummaryOut;
        TRUNCATE TABLE ccWAAverageConversationsOut;
        TRUNCATE TABLE ccLastMessageAgentByConversationOut;
    END    
    else IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
    BEGIN
        IF EXISTS (SELECT * FROM ccWAAverageConversationsOut
                    WHERE CamId = @camId
                    AND (LastUpdate IS NULL
                    OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
                    OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
        BEGIN
            -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

            DECLARE @AverageConversationTime INT = 0;
            DECLARE @AverageDialogTime INT = 0;
            DECLARE @AverageWaitingTime INT = 0;
            DECLARE @MaximumWaitingTime INT = 0;
            DECLARE @DefaultValue INT = 2
            

            SET @DefaultValue = @DefaultValue * 60;
            DECLARE @LessThanDefault INT = 0;
            DECLARE @ReceivedConversations INT = 0;
            DECLARE @ServiceLevel SMALLINT = 0;

            --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

            SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
                    @AverageDialogTime = ROUND(AVG(tChatting), 4),
                    @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
                    @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
                    @ReceivedConversations = COUNT(conversationDate),
                    @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
            FROM ccWhatsAppConversationsOut with(nolock) WHERE camId = @camId
            AND requestDate >= @Today

            SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

            ----------------------------------------------------- Update table --------------------------------------------------------

            IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE camId = @camId)
            BEGIN
                UPDATE ccWAAverageConversationsOut
                SET AverageConversationTime = @AverageConversationTime,
                    AverageDialogTime = @AverageDialogTime,
                    AverageWaitingTime = @AverageWaitingTime,
                    MaximumWaitingTime = @MaximumWaitingTime,
                    ServiceLevel = @ServiceLevel,
                    StatusUpdate = 0,
                    LastUpdate = GETDATE()
                WHERE CamId = @camId
            END
            ELSE
            BEGIN
                INSERT INTO ccWAAverageConversationsOut (CamId, AverageConversationTime, AverageDialogTime,
                                                        AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
                VALUES(@camId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
                        @ServiceLevel, 0 , GETDATE())
            END
        END
        --------------------------------- Results -----------------------------------

        if exists (select * from ccWAOperatingSummaryOut with(nolock) where CamId=@camId
                    and (OnQueue<0 or Assigned<0)
                    ) begin
                    
                set @Today =convert(date,getdate(),121)

                ;with waOperationSummary as(
                select 
                CamId
                ,count(case when finishedBy=1 then 1 end) Attended
                ,count(case when onQueue=1 and finishedBy=0 then 1 end) onQueue
                ,count(case when finishedBy=0 and agentId>0 then 1 end) Assigned
                ,count(*) Request
                ,count(case when finishedBy=2 then 1 end) EndedBySystem
                from ccWhatsAppConversationsOut with(nolock)
                where camId = @camId and requestDate>=@Today
                group by CamId
                )
                update A 
                set A.Attended=B.Attended, A.Assigned=B.Assigned
                
                ,A.Request=B.Request,A.EndedBySystem=B.EndedBySystem
                from ccWAOperatingSummaryOut A 
                inner join waOperationSummary B on A.CamId=B.CamId
        end

        SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
                ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
                ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
                ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
                ISNULL(ServiceLevel, 0) AS ServiceLevel,
                ISNULL(Attended, 0) AS Attended,
                ISNULL(Assigned, 0) AS Assigned,
                ISNULL(OnQueue, 0) AS OnQueue,
                ISNULL(EndedBySystem, 0) AS EndedBySystem,
                ISNULL(Available, 0) AS Available,
                ISNULL(Request, 0) AS Request
        FROM ccWAAverageConversationsOut conv
        RIGHT JOIN ccWAOperatingSummaryOut summary ON conv.CamId = summary.camId
        WHERE conv.CamId = @camId OR summary.camId = @camId
    END
    else IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
                    -- Average Queue/Waiting Time, and Service Level)
    BEGIN
        IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE CamId = @camId)
            BEGIN
                UPDATE ccWAAverageConversationsOut SET StatusUpdate = 1
                WHERE CamId = @camId
            END
            ELSE
            BEGIN
                INSERT INTO ccWAAverageConversationsOut (CamId, StatusUpdate)
                VALUES(@camId, 1)
            END
    END
    else IF @Option = 3 -- Save time from accepted conversation by agent
    BEGIN
        IF @ConversationId IS NOT NULL
        BEGIN
            UPDATE ccWhatsAppConversationsOut SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
            --Save Conversation Assigned
            SELECT @camId = camId FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;
            UPDATE ccWAOperatingSummaryOut SET Assigned = (Assigned + 1) WHERE camId = @camId
            
        END
    END
    else IF @Option = 4 -- Get Disposition Information
    BEGIN
    declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
    select @nIdioma = case valor 
        when 0 then ''Sin calificación'' 
        when 2 then ''Sem classificação''
        else ''No disposition'' end
    from ccsettings where setting_id = 27 -- 0esp
    SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
            ISNULL(disposition.calif_id, 0) AS DispositionId,
            COUNT(whatsConv.disposition) AS Total,
            ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
            COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
    FROM ccWhatsAppConversationsOut whatsConv with(nolock)
    LEFT JOIN ccTipoCalifOUT disposition ON disposition.calif_id = whatsConv.disposition
    WHERE camId = @camId AND assignDate >= @Today
        and whatsConv.conversationStatus != 2
    GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
    END
    else IF @Option = 5 -- Get Subdisposition Information
    BEGIN
        SELECT relation.calif_id AS DispositionId,
                subDispositions.califSubDesc AS SubDispositionsName,
                COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
        FROM cctipoSubCalifRel relation
        INNER JOIN ccTipoCalifSubOUT subDispositions ON subDispositions.califSub_id = relation.califSub_id
        INNER JOIN ccWhatsAppConversationsOut whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
        WHERE whatsConv.camId = @camId AND
                whatsConv.assignDate >= @Today AND
                relation.tipoSubRel = 0
        GROUP BY subDispositions.califSubDesc, relation.calif_id
    END
    ELSE IF @Option = 6 -- Agents Availables
    BEGIN
        IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId)
            BEGIN
                INSERT INTO ccWAOperatingSummaryOut (camId, Available) VALUES (@camId, @AgentsAvailables);
            END
        ELSE
            BEGIN
                UPDATE ccWAOperatingSummaryOut SET Available = @AgentsAvailables WHERE camId = @camId
            END
    END

    ELSE IF @Option = 7 -- Whats Conversations Results
    BEGIN
        SELECT ISNULL(SentMsg, 0) AS SentMsg,
                ISNULL(Delivered, 0) AS Delivered,
                ISNULL(NotDelivered, 0) AS NotDelivered,
                ISNULL(ReadMsg, 0) AS ReadMsg,
                ISNULL(NotSupported, 0) AS NotSupported
        FROM ccWAConversationsResult
        WHERE camId = @camId
    END

    ELSE IF @Option = 8 -- whats outbound conversations
    BEGIN
        DECLARE @ActualDay DATE = GETDATE()

        SELECT
            COUNT(CASE WHEN cco.conversationStatus NOT IN (10,11,17,18) THEN 1 ELSE NULL END) Active,
            COUNT(CASE WHEN conversationStatus = 1 THEN 1 ELSE null END) Queued,
            COUNT(CASE WHEN conversationStatus = 11 THEN 1 ELSE null END) FinishedAgent,
            COUNT(CASE WHEN conversationStatus = 10 THEN 1 ELSE null END) FinishedSystem
        FROM ccWhatsAppConversationsOut cco WITH(NOLOCK)
        WHERE cco.camId = @camId AND CAST(cco.conversationDate AS DATE) = @ActualDay
    END
        
    SET NOCOUNT OFF
    ';
    EXEC(@sql)

    SET @process = 'Se modifica SP ccsp_RIAADMgetAbandonoSalida_Fix, se cambia el valor de @to para cada 10 min, line 1896';
    SET @sql = '
    ALTER procedure [dbo].[ccsp_RIAADMgetAbandonoSalida_Fix]
as
set nocount on
declare @to smalldatetime, @from smalldatetime
declare @interval int
declare @i int
declare @row int

declare @tempChart table(
cam_id  int,
countAbnd int,
countAll int,
timestamp   smalldatetime
)

set @interval=10
set @to = convert(datetime, convert(varchar(16), getdate(), 121)+''0:00'',121)

set @to = dateadd(mi,10,@to)
set @from = dateadd( mi, -@interval*30, @to)

set @row=DATEDIFF(mi,@from,@to)
select @row=ABS( CEILING(1.0*@row/@interval))


;WITH Numbers AS
(
    SELECT TOP (@row) n = CONVERT(INT, ROW_NUMBER() OVER (ORDER BY s1.[object_id]))
    FROM sys.all_objects AS s1 CROSS JOIN sys.all_objects AS s2
)
, times as(
    SELECT  ROW_NUMBER() OVER (ORDER BY n) as [ID], DATEADD(MINUTE,@interval* (n-1), @from) as [Start], DATEADD(MINUTE,@interval* (n), @from) as [Stop]
    FROM Numbers
), tempChart as(
    select cam_id,case statuscall_id when 6 then 1 end  as countAbnd
    ,convert(datetime,  convert(varchar(15), cal_inicio, 121)+''0:00'',121) as timeSpam     
    from ccoCallsOut
    with( index(IX_ccoCallsOut_2),nolock )
    where cal_manual in (0,2 ) and cal_inicio between @from and @to
),timeCamps as(
    select c.cam_id,t.Start as timeSpam from times t
    cross join ccCamps c
    where c.IDArea is not null
),tempChartGroup as(
    select cam_id,count(countAbnd) as countAbnd,
    COUNT(*) as countAll,timeSpam
    from tempChart
    group by cam_id,timeSpam
)

insert into @tempChart
select tCamp.cam_id,isnull(countAbnd,0) as countAbnd,isnull(countAll,0) countAll
,tCamp.timeSpam from timeCamps tCamp
left join tempChartGroup chart on tCamp.cam_id=chart.cam_id and tCamp.timeSpam=chart.timeSpam

truncate table ccAbandonoSalida_Chart

insert into ccAbandonoSalida_Chart
select cam_id,
CONVERT(decimal(10,2),
case when countAll=0 then 0 else countAbnd*100.00/countAll end
),[timestamp]
  from @tempChart order by cam_id 

truncate table ccAbandonoSalida  
  
 insert into ccAbandonoSalida
 select cam_id,
 CONVERT(decimal(10,2),
 case when sum(countAll) =0 then 0 else 
 SUM(countAbnd*100.0)/sum(countAll) end 
 ) as AbndPctg 

 from @tempChart
 group by cam_id
 
set nocount off
    ';
    EXEC(@sql)
    --------------------------------------------------- End Jonathan Ramirez ------------------------------------------------------------------------------------
--------------------------------------------------- Begin Jesus Gallardo ------------------------------------------------------------------------------------
    SET @process = 'Whatsapp Meta Alter SP ccsp_GalateaGetOutboundConfiguration'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]
@adminID INT
,@campID INT
AS
BEGIN

    DECLARE @AllCampaigns TABLE (
    cam_id SMALLINT
    ,cam_Descripcion VARCHAR(60)
    ,cam_tNotas SMALLINT
    ,cam_ocupado SMALLINT
    ,cam_noInt_ocupado SMALLINT
    ,cam_inter_ocupado SMALLINT
    ,cam_nocontesto SMALLINT
    ,cam_noInt_nocontesto SMALLINT
    ,cam_inter_nocontesto SMALLINT
    ,cam_fax SMALLINT
    ,cam_noInt_fax SMALLINT
    ,cam_inter_fax SMALLINT
    ,cam_modomanual SMALLINT
    ,ANI VARCHAR(15)
    ,cam_ShowCalifWnd BIT
    ,cam_StartTimerOnHangUp BIT
    ,editableCallKey BIT
    ,cam_tNoContesta SMALLINT
    ,iTipoDial SMALLINT
    ,detectAnswerMachine SMALLINT
    ,detectVoiceMail SMALLINT
    ,compliance SMALLINT
    ,cam_inter_graba SMALLINT
    ,cam_noint_graba SMALLINT
    ,progDial SMALLINT
    ,excCallBack SMALLINT
    ,dialOrder SMALLINT
    ,dialPrefix VARCHAR(10)
    ,dialPrefixMan VARCHAR(10)
    ,dialPrefixXfe VARCHAR(10)
    ,listenManualCall BIT
    ,stopRecording BIT
    ,abandonCallback BIT
    ,frame SMALLINT
    ,t_autoCB SMALLINT
    ,id_anilist INT
    ,tDialonWrapUp SMALLINT
    ,viewMode TINYINT
    ,queSize SMALLINT
    ,DNCScrub INT
    ,callerIdDesc VARCHAR(15)
    ,timeZoneRule INT
    ,callsBySurvey INT
    ,ivrScript INT
    ,surveyPctg INT
    ,call_record SMALLINT
    ,startStopRecording BIT
    ,leaveRecMessage BIT
    ,manualCallOnChat BIT
    ,callBackSurveyAgent BIT
    ,callBackSurveyClient BIT
    ,isRelationSurvey BIT
    ,funcEspDtmf INT
    ,sipHdrFormat VARCHAR(255)
    ,cam_inter_cancelled SMALLINT
    ,prefijo VARCHAR(40)
    ,enbleprefix BIT
    ,exitAssisted BIT
    ,previewDiscard BIT
    ,CampType INT
    ,conexionInfo VARCHAR(50)
    ,connUser VARCHAR(15)
    ,closeConversationTime INT
    ,answerTimeoutClient INT
    ,allowFileAttachments BIT
    ,selectRotativeANI INT
    ,rotativeAlgo TINYINT
    ,autoStart BIT
    ,messagingOrder BIT
    ,CamTPreview SMALLINT
    ,TimesPreview TINYINT
    ,timesDiscard TINYINT
    ,recordHold BIT
    ,zipCodeSchedule BIT
    ,RecordCalls tinyint
    ,simultaneousRecs smallint
    ,EditableContactData bit
    ,internationalDialingPortsAssigned bit
    ,AssignConversationSameAgent bit
    ,maxLimitQueueConversations SMALLINT
    )
    DECLARE @numbers VARCHAR(max)

    SELECT @numbers = COALESCE(@numbers + '','', '''')+ number
    FROM ccWhatsAppNumbers
    WHERE camp_id = 0
    AND STATUS = 1
        
    SELECT @numbers = COALESCE(@numbers + '','', '''')+ number
    FROM ccMetaWhatsAppNumbers
    WHERE Cam_Id = 0 or Cam_Id is null
    AND STATUS = 1

    INSERT INTO @AllCampaigns
    EXEC ccsp_RIAConfCamp @adminID
    ,@campID

    SELECT 
    dialPrefixMan DialPrefixMan
    ,dialPrefixXfe DialPrefixXfe
    ,listenManualCall ListenManualCall
    ,stopRecording StopRecording
    ,abandonCallback AbandonCallBack
    ,t_autoCB AutoCB
    ,id_anilist IdIstANI
    ,tDialonWrapUp TDialOnWrapup
    ,queSize Quesize
    ,DNCScrub
    ,callerIdDesc CallerIdDesc
    ,timeZoneRule TimeZoneRule
    ,callsBySurvey CallsBySurvey
    ,ivrScript IvrScript
    ,surveyPctg SurveyPctg
    ,call_record CallRecord
    ,startStopRecording StartStopRecording
    ,leaveRecMessage LeaveRecMessage
    ,manualCallOnChat ManualCallOnChat
    ,callBackSurveyClient CallBackSurveyClient
    ,callBackSurveyAgent CallBackSurveyAgent
    ,funcEspDtmf FuncEspDtmf
    ,sipHdrFormat SipHdrsCfg
    ,dialPrefix DialPrefix
    ,prefijo Prefix
    ,dialOrder DialOrder
    ,progDial ProgDial
    ,cam_Descripcion CamDescription
    ,cam_tNotas CamTnotas
    ,cam_ocupado CamBusy
    ,cam_noInt_ocupado CamNoIntBusy
    ,cam_inter_ocupado CamInterBusy
    ,cam_nocontesto CamNoAnswer
    ,cam_noInt_nocontesto CamNoIntNoAnswer
    ,cam_inter_nocontesto CamInterNoAnswer
    ,(cam_inter_cancelled / 60) CamInterCancelled
    ,cam_fax CamFax
    ,cam_noInt_fax CamNoIntFax
    ,cam_inter_fax CamInterFax
    ,cam_modomanual CamModoManual
    ,ANI
    ,cam_StartTimerOnHangUp CamStartTimerOnHangUp
    ,editableCallKey EditableCallKey
    ,cam_tNoContesta CamTNoAnswer
    ,iTipoDial CamIntensiveDialing
    ,detectAnswerMachine DetectAnswerMachine
    ,detectVoiceMail DetectVoiceMail
    ,compliance Compliance
    ,cam_inter_graba CamInterRecord
    ,cam_noint_graba CamNoIntRecord
    ,excCallBack ExcCallBack
    ,cam_ShowCalifWnd CamShowCalifWnd
    ,frame Frame
    ,exitAssisted ExitAssistedDialMode
    ,previewDiscard PreviewDiscard
    ,CampType
    ,conexionInfo ConexionInfo
    ,connUser ConnUser
    ,closeConversationTime CloseConversationTime
    ,answerTimeoutClient MUTimeOutClient
    ,allowFileAttachments AllowFileAttachments
    ,CamTPreview
    ,CAST(TimesPreview AS SMALLINT) TimesPreview
    ,@numbers AS FreeNumbers
    ,selectRotativeANI SelectRotativeANIManualCall
    ,rotativeAlgo RotativeAlgo
    ,autoStart AutoStart
    ,messagingOrder MessagingOrder
    ,timesDiscard TimesDiscard
    ,recordHold RecordHold
    ,zipCodeSchedule ZipCodeSchedule
    ,RecordCalls RecordCalls
    ,simultaneousRecs SimultaneousRecs
    ,EditableContactData EditableContactData
    ,internationalDialingPortsAssigned internationalDialingPortsAssigned
    ,AssignConversationSameAgent AssignConversationSameAgent
    ,maxLimitQueueConversations MaxLimitQueueConversations
    FROM @AllCampaigns
    WHERE cam_id = @campID
END'
    EXEC(@sql)

    


--------------------------------------------------- End Jesus Gallardo ------------------------------------------------------------------------------------

        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
       EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
       EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

        COMMIT TRAN
    END TRY
    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()
        RAISERROR (@errorGenerated, 11, 1)
        ROLLBACK TRAN
    END CATCH
END 
