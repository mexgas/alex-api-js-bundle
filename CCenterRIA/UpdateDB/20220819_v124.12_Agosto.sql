/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/02/15
Description: Merge con los cambios de sorteos

Database: CCenterRia
Required version: 123.27

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
SET @versionfix = 12
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;


IF @actualVersion = @version and @actualVersionFix >= 1
BEGIN
    BEGIN TRAN

    BEGIN TRY
        
        ----------------------------------IVAN MARTIN | AUTOMATIC MESSAGES | SCP-71 DEFAULT MESSAGES --------------------------------------------------
    
        set @process = 'SCP-71 Create new column DefaultMessage to table ccMsgFiles'
        set @sql = 'IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''DefaultMessage'' AND Object_ID = Object_ID(N''ccMsgFiles''))
                    BEGIN
                        ALTER TABLE ccMsgFiles
                        ADD DefaultMessage BIT NULL 
                        CONSTRAINT DefaultMessage_Default_Value DEFAULT 0
                        WITH VALUES;
                    END'
        EXEC(@sql)

        set @process = 'SCP-71 Insert value to default columns'
        set @sql = 'UPDATE ccMsgFiles SET DefaultMessage = 1 WHERE msgFile LIKE ''%Default%'''
        EXEC(@sql)
        
        set @process = 'SCP-71 Alter procedure configuraIdiomaCatalogosEnglish: Insert values 1 in DefaultMessage column in ccMsgFiles'
        set @sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEnglish]
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
                    update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

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

                    Print ''Mensajes defualt''
                    DELETE [ccMsgFiles]
                    DBCC CHECKIDENT (''[ccMsgFiles]'', RESEED, 0)
                    INSERT [ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default5'', ''Welcome message'', 1)
                    INSERT [ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default4'', ''Transfer message'', 1)
                    INSERT [ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default3'', ''Out of service message'', 1)
                    INSERT [ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default2'', ''After hours message'', 1)
                    INSERT [ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default1'', ''In queue message'', 1)
                    INSERT [ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default7'', ''No agents signed in message'', 1)
                    INSERT [ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default9'', ''VoiceMail message'', 1)
                    INSERT [ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default10'', ''Overflow message'', 1)
                    INSERT [ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default11'', ''DNC list'', 1)

                    Print ''Mensajes default chat''
                    DELETE [ccRIAChatInboundMsgs]
                    INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default5'', ''Welcome!'')
                    INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default3'', ''Service currently unavailable'')
                    INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default2'', ''Our schedule service has finished'')
                    INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default1'', ''Please hold while one of our agents is available'')
                    INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default7'', ''There are not available agents'')
                    INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default10'', ''Your request can not be processed'')
                    INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default12'', ''Chat session has been inactive for too long'')
                    INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default13'', ''Chat session has finished'')'
        EXEC(@sql)

        set @process = 'SCP-71 Alter procedure configuraIdiomaCatalogosEspañol: Insert values 1 in DefaultMessage column in ccMsgFiles'
        set @sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEspañol] 
                    AS
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
                    update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

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

                    Print ''Mensajes voz defualt''
                    DELETE [dbo].[ccMsgFiles]
                    DBCC CHECKIDENT (''[ccMsgFiles]'', RESEED, 0)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_Sp\Default5'', ''Mensaje Bienvenida'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_Sp\Default4'', ''Mensaje Transferencia'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_Sp\Default3'', ''Mensaje Fuera de servicio'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_Sp\Default2'', ''Mensaje Fuera de horario'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_Sp\Default1'', ''Mensaje En espera'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_Sp\Default7'', ''Mensaje Sin agentes firmados'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_Sp\Default9'', ''Mensaje VoiceMail'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_Sp\Default10'', ''Mensaje Desborde'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_Sp\Default11'', ''Lista Negra'', 1)


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

        set @process = 'SCP-71 Alter procedure configuraIdiomaCatalogosPortugues: Insert values 1 in DefaultMessage column in ccMsgFiles'
        set @sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosPortugues]
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
                    update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

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
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default5'', ''Mensagem de boas vindas'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default4'', ''Mensagem de transferência'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default3'', ''Mensagem de falta de serviço'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default2'', ''Depois de horas de mensagens'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default1'', ''Na fila de mensagens'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default7'', ''Nenhum agente assinado em mensagem'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default9'', ''Mensagem de voz'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default10'', ''Mensagem de Overflow'', 1)
                    INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion], [DefaultMessage]) VALUES ( ''Default_En\Default11'', ''Lista DNC'', 1)

                    Print ''Mensajes default chat''
                    DELETE [dbo].[ccRIAChatInboundMsgs]
                    INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default5'', ''Bem-vindo!'')
                    INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default3'', ''Serviço está disponível no momento'')
                    INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default2'', ''Nosso horário de serviço terminou'')
                    INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default1'', ''Por favor aguarde enquanto um dos nossos agentes está disponível'')
                    INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default7'', ''Há agentes não disponíveis'')
                    INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default10'', ''Sua solicitação não pode ser processada'')
                    INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default12'', ''Sessão de chat foi-inativo por muito tempo'')
                    INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default13'', ''Sessão de chat terminou'')'
        EXEC(@sql)

       
-------------------------------- Begin Ciro -----------------------------------------
    set @process = 'K002133-Consulta conversación reasignada'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_CreateNodeMultimedia] @conversationId BIGINT
                                                , @supervisor     VARCHAR(255) = ''''
                                                , @template       VARCHAR(255) = ''''
                                                , @ScoreTemplate  INT          = 0
                                                , @type           INT                                                
                    AS
                    BEGIN

                        DECLARE @xml XML, @dateStart DATETIME;
                        DECLARE @info VARCHAR(255);
                        DECLARE @infoEscape VARCHAR(MAX);
                        DECLARE @charEscape VARCHAR(255), @charReplace VARCHAR(MAX);
                        SET @charEscape = ''"|''''''''|<|>|&'';
                        SET @charReplace = ''&quot;|&apos;|&lt;|&gt;|&amp;'';

                        DECLARE @existAttached BIT, @numInteracion SMALLINT;
                        IF @type = 1
                        BEGIN--CHAT
                            SELECT @xml = CONVERT(XML, ''<R01 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126))) 
                                + ''" CID="'' + CONVERT(VARCHAR(MAX), ccRIAChats.inboundid) 
                            + ''" CType="1'' 
                            + ''" C01="'' + CONVERT(VARCHAR(MAX), chatId) 
                            + ''" C02="'' + CONVERT(VARCHAR(MAX), ISNULL(ccinbound.descripcion, '''')) 
                            + ''" C03="'' + CONVERT(VARCHAR(MAX), domain) 
                            + ''" C04="'' + CONVERT(VARCHAR(MAX), ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'')) 
                            + ''" C05="'' + CONVERT(VARCHAR(MAX), tchatting) 
                            + ''" C06="'' + CONVERT(VARCHAR(MAX), ISNULL(cctipocalif.[Description], ''N/A'')) 
                            + ''" C07="'' + CONVERT(VARCHAR(MAX), ISNULL(cctipocalifsub.califSubdesc, ''N/A'')) 
                            + ''" C08="'' + CONVERT(VARCHAR(MAX), clientname) 
                            + ''" C09="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126))) 
                            + ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
                            + ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
                            + ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
                            + ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(ccusers.[Login], '''')) 
                            + ''"/>'')
                                 , @dateStart = ISNULL(chatDate, requestDate) FROM ccRIAChats
                                                                                   LEFT OUTER JOIN ccinbound ON ccinbound.inbound_id = ccRIAChats.inboundid
                                                                                   LEFT OUTER JOIN ccusers ON ccusers.user_id = ccRIAChats.userid
                                                                                   LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = ccRIAChats.disposition
                                                                                   LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = ccRIAChats.subdisposition
                                                                                                                     AND ccRIAChats.subdisposition <> 0
                            WHERE chatId = @conversationId
                                  AND chatStatus = 4              

                        END;
                        ELSE
                            IF @type = 3
                            BEGIN--EMAIL
                                SELECT @existAttached = CASE WHEN COUNT(*) > 0
                                                        THEN 1 ELSE 0
                                                        END FROM attached
                                WHERE messageId IN(SELECT messageId FROM message WHERE conversationId = @conversationId);
                                SELECT @numInteracion = COUNT(*) FROM message WHERE conversationId = @conversationId;
                                --Replaza los caracteres por los comunes
                                SELECT @info = info FROM conversation WHERE conversationId = @conversationId;
                                SELECT @info = replace(@info, A.Value, B.Value) FROM dbo.fn_RIASplitDelimited(@charEscape, ''|'') A
                                                                                     INNER JOIN dbo.fn_RIASplitDelimited(@charReplace, ''|'') B ON A.Id = B.Id;

                                SELECT @xml = CONVERT(XML, ''<R03 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126))) 
                                    + ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid) 
                                + ''" CType="1'' 
                                + ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationId) 
                                + ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126))) 
                                + ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion)) 
                                + ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''''))) 
                                + ''" C05="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalif.[Description], ''N/A''))) 
                                + ''" C06="'' + CONVERT(VARCHAR, MAX(replace(replace(a.mailClient, ''<'', '' ''), ''>'', '' ''))) 
                                + ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup)) 
                                + ''" C08="'' + CONVERT(VARCHAR(MAX), MIN(ISNULL(@info, ''''))) 
                                + ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid)) 
                                + ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0)) 
                                + ''" C11="'' + CONVERT(VARCHAR(MAX), @existAttached) 
                                + ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
                                + ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
                                + ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
                                + ''" C15="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalifsub.califSubdesc, ''N/A''))) 
                                + ''" C16="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), '''')) 
                                + ''"/>'')
                                     , @dateStart = ISNULL(MAX(b.tsend), GETDATE()) FROM conversation a
                                                                                         INNER JOIN message b ON a.conversationid = b.conversationid
                                                                                         LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
                                                                                         LEFT OUTER JOIN ccusers d ON d.user_id = b.userid
                                                                                         LEFT OUTER JOIN relationmessageDisposition e ON e.messageId = b.messageId
                                                                                         LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = e.dispositionId
                                                                                         LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = e.subdispositionId
                                                                                                                           AND e.subdispositionId <> 0
                                WHERE a.conversationId = @conversationId
                                GROUP BY a.conversationId
                                       , a.inboundid;

                            END;
                            ELSE
                                IF @type = 4
                                BEGIN--Twitter
                                    SELECT @numInteracion = SUM(ninteration) FROM messageOutTwitter
                                    WHERE conversationTwitterId = @conversationId;

                                    SELECT @xml = CONVERT(XML, ''<R04 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), MIN(b.date), 126))) 
                                        + ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid) 
                                    + ''" CType="1'' 
                                    + ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationTwitterId) 
                                    + ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), MIN(b.date), 126))) 
                                    + ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion)) 
                                    + ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''''))) 
                                    + ''" C05="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalif.[Description], ''N/A''))) 
                                    + ''" C06="'' + MAX(a.screenNameClient) 
                                    + ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup)) 
                                    + ''" C08="'' + MAX(a.screenNameInbound) 
                                    + ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid)) 
                                    + ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0)) 
                                    + ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
                                    + ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
                                    + ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
                                    + ''" C14="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalifsub.califSubdesc, ''N/A''))) 
                                    + ''" C15="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), '''')) 
                                    + ''"/>'')
                                         , @dateStart = ISNULL(MIN(b.date), GETDATE()) FROM conversationTwitter a
                                                                                            INNER JOIN messageOutTwitter b ON a.conversationTwitterId = b.conversationTwitterId
                                                                                            LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
                                                                                            LEFT OUTER JOIN ccusers d ON d.user_id = b.userid
                                                                                            LEFT OUTER JOIN relationMessageDispositionTwit e ON e.messageOutTwitterId = b.messageOutTwitterId
                                                                                            LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = e.dispositionId
                                                                                            LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = e.subdispositionId
                                                                                                                              AND e.subdispositionId <> 0
                                    WHERE a.conversationTwitterId = @conversationId
                                    GROUP BY a.conversationTwitterId
                                           , a.inboundid;
                                END;
                                ELSE
                                    IF @type = 5
                                    BEGIN --WhatsApp
                                        SELECT @xml = CONVERT(XML, ''<R05 CDATE="'' + CONVERT(VARCHAR(23), ISNULL(conversationDate, requestDate), 126) 
                                            + ''" CID="'' + CONVERT(VARCHAR(MAX), A.inboundid) 
                                        + ''" CType="5'' 
                                        + ''" C01="'' + CONVERT(VARCHAR(MAX), A.conversationId) 
                                        + ''" C02="'' + ISNULL(inbound.descripcion, '''') 
                                        + ''" C03="'' + ISNULL(ccusers.[Login], '''') 
                                        + ''" C04="'' + ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'') 
                                        + ''" C05="'' + clientId 
                                        + ''" C06="'' + CONVERT(VARCHAR(MAX), tConversation) 
                                        + ''" C07="'' + ISNULL(cctipocalif.[Description], ''N/A'') 
                                        + ''" C08="'' + ISNULL(cctipocalifsub.califSubdesc, ''N/A'') 
                                        + ''" C09="'' + CONVERT(VARCHAR(MAX), A.agentId) 
                                        + ''" C10="'' + phoneACD 
                                        + ''" C11="'' + CONVERT(VARCHAR(MAX), A.agentId) 
                                        + ''" C12="'' + ISNULL(@supervisor, '''') 
                                        + ''" C13="'' + ISNULL(@template, '''') 
                                        + ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
                                        + ''"/>'')
                                             , @dateStart = ISNULL(conversationDate, requestDate) FROM ccWhatsAppConversations A
                                                                                                       LEFT OUTER JOIN ccinbound inbound ON inbound.inbound_id = A.inboundid
                                                                                                       LEFT OUTER JOIN ccusers ON ccusers.user_id = A.agentId
                                                                                                       LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
                                                                                                       LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
                                        WHERE A.conversationId = @conversationId;

                                    END;

                        DECLARE @sql NVARCHAR(MAX), @tableName NVARCHAR(MAX), @columnId NVARCHAR(MAX), @tableNameHistory NVARCHAR(MAX);
                        DECLARE @parameterDefinition NVARCHAR(MAX);

                        SELECT @tableName = tableName
                             , @tableNameHistory = tableNameHistory
                             , @columnId = columnId FROM ccFinderServices
                        WHERE id = @type;

                        SET @parameterDefinition = N''@conversationId bigint,@xml xml,@dateStart datetime'';

                        IF @xml IS NOT NULL
                        BEGIN        

                            SET @sql = ''IF EXISTS(SELECT * FROM '' + @tableNameHistory + '' WHERE ''+@columnId+'' = @conversationId)
                            BEGIN
                                UPDATE '' + @tableNameHistory + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
                            END
                            else IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
                            BEGIN
                                UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
                            END
                            else begin
                                INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, 0);
                            end     
                            '';
                            
                        END
                        else begin
                             SET @sql ='' IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
                            BEGIN
                                UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = -1 WHERE ''+@columnId+'' = @conversationId;
                            END
                            else begin
                                INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, -1);
                            end '';
                        end

                         EXECUTE sp_executesql
                                    @sql
                                  , @parameterDefinition
                                  , @conversationId = @conversationId
                                  , @xml = @xml
                                  , @dateStart = @dateStart;

                    END;'
                    EXEC(@sql)
-------------------------------- END Ciro -----------------------------------------
    -------------------------- BEGIN SANTI ----------------------------------

    set @process = 'CW-7182 Alter SP ccspGalatea_Finder change label'
    set @sql = 'ALTER PROCEDURE [dbo].[ccspGalatea_Finder] 
@action INT, 
@userId INT = 0, 
@conversationId BIGINT = 0,
@isSuperUser bit=0
AS
IF @action = 1
    BEGIN--trae el nombre de la base de datos en BX
    if @isSuperUser =0 begin

            SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, c.cam_descripcion AS label
            FROM ccRIAWorkGroupUsers Wguser
                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                INNER JOIN ccCamps c ON WGCam.IdCampEsp = c.cam_id
                                        AND WGCam.Tipo = 1
            WHERE Wguser.User_id = @userId
            UNION
            SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, inb.descripcion AS label
            FROM ccRIAWorkGroupUsers Wguser
                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                INNER JOIN ccInbound inb ON WGCam.IdCampEsp = inb.Inbound_id
                                            AND WGCam.Tipo = 0
            WHERE Wguser.User_id = @userId;
        end
        else begin
        SELECT CAST(c.cam_id AS INT) AS [Value], CAST(2 AS INT) AS callType, c.cam_descripcion AS label FROM ccCamps c
        UNION
        SELECT CAST(inb.Inbound_id AS INT) AS [Value], CAST(1 AS INT) AS callType, inb.descripcion AS label FROM ccInbound inb;
        end
        RETURN 0;
END;
IF @action = 2
    BEGIN
    if @isSuperUser =0 begin
        WITH WgId
            AS (SELECT IDWG
                FROM ccRIAWorkGroupUsers Wguser
                WHERE Wguser.User_id = @userId)
            SELECT DISTINCT 
                    CAST(Wguser.User_id AS INT) AS [Value], CONCAT(ccUsers.Nombres, '' '', ccUsers.ApellidoPaterno, '' '', ccUsers.ApellidoMaterno)  AS label
            FROM ccRIAWorkGroupUsers Wguser
                INNER JOIN WgId ON Wguser.IDWG = WgId.IDWG
                INNER JOIN ccUsers ON ccUsers.User_id = Wguser.User_id
                                        AND TipoUser_id = 1;
end
else begin
        select CAST(ccUsers.User_id AS INT) AS [Value], CONCAT(ccUsers.Nombres, '' '', ccUsers.ApellidoPaterno, '' '', ccUsers.ApellidoMaterno)  AS label
        from ccUsers where TipoUser_id = 1;
end
        RETURN 0;
END;
IF @action = 3
    BEGIN--Informacion de la conversacion de whatsApp
        SELECT A.ConversationID, A.inboundId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneACD AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID
        FROM ccWhatsAppConversations A
            LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
            LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
            LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
            LEFT JOIN ccRIAInboundGraph graph ON graph.Inbound_id = A.inboundId
        WHERE A.conversationId = @conversationId;
        RETURN 0;
END;

IF @action = 3
    BEGIN--Informacion de la conversacion de whatsApp
        SELECT A.ConversationID, A.inboundId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneACD AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID
        FROM ccWhatsAppConversations A
            LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
            LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
            LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
            LEFT JOIN ccRIAInboundGraph graph ON graph.Inbound_id = A.inboundId
        WHERE A.conversationId = @conversationId;
        RETURN 0;
END;'
    EXEC(@sql)

    set @process = ''
    set @sql = ''
    EXEC(@sql)

------------------------------------------------------------  END  ----------------------------------------------------------------------------------------------------------------------------------

        ----------------------------------GMZ | K002130-Editar telefono --------------------------------------------------

        set @process = 'K002130-Editar telefono'
        set @sql = 'if not exists( select * from ccRIALog_Operation where operationType in (195,196))
        begin
            insert into ccRIALog_Operation (operationType, descripcion) VALUES (195, ''DESASOCIAR TELÉFONO|DISASSOCIATE PHONE NUMBER'')
            insert into ccRIALog_Operation (operationType, descripcion) VALUES (196, ''ASOCIAR TELÉFONO|ASSOCIATE PHONE NUMBER'')
        end'
        EXEC(@sql)

        set @process = 'K002130-Editar telefono'
        set @sql = 'if not exists( select * from ccRIALog_Module where module_id = 61 )
        begin
            INSERT INTO ccRIALog_Module (module_id, descripcion) VALUES (61, ''CONFIGURACIÓN DE CAMPAÑA (WHATSAPP ENTRADA)|CAMPAIGN CONFIGURATION (INBOUND WHATSAPP)'')
        end'
        EXEC(@sql)

        ------------------------------------------------------------  END  ----------------------------------------------------------------------------------------------------------------------------------

        ----------------------------------GMZ | Reincio MCS --------------------------------------------------

        set @process = 'Reincio MCS se crea tabla ccDisconnectionMCS'
        set @sql = 'if not exists (select * from sys.tables where name = N''ccDisconnectionMCS'')
        begin
            CREATE TABLE [dbo].[ccDisconnectionMCS](
            [disconnectionId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
            [timeStampDisconnection] [DATETIME] NOT NULL,
            [timeStampConnection] [DATETIME]
            
            CONSTRAINT [pk_ccRIADisconnectionMCS_1] PRIMARY KEY CLUSTERED
            (
                [disconnectionId] ASC
            )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
            )ON [PRIMARY]
        end'
        EXEC(@sql)

        set @process = 'Reincio MCS se altera sp ccsp_ConversationWASave (se agrego action 13 y 14)'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
                                              , @conversationId     INT         = 0
                                              , @inboundId          SMALLINT    = NULL
                                              , @phoneACD           VARCHAR(50) = NULL
                                              , @clientId           VARCHAR(25) = NULL
                                              , @conversationStatus SMALLINT    = 0
                                              , @tChatting          FLOAT    = 0
                                              , @tWrapUp            SMALLINT    = 0
                                              , @finishedBy         TINYINT     = 0
                                              , @onQueue            BIT         = NULL
                                              , @tQueue             SMALLINT    = 0
                                              , @tTimeout           INT         = 0
                                              , @disposition        SMALLINT    = 0
                                              , @subDisposition     SMALLINT    = 0
                                              , @agentId            INT         = 0
                                              --VAR MESSAGES
                                              , @messageId          VARCHAR(50) = NULL
                                              , @messageIdUi        INT         = NULL
                                              , @clientNum          VARCHAR(15) = NULL
                                              , @vonageNum          VARCHAR(15) = NULL
                                              , @typeMessage        VARCHAR(25) = ''''
                                              , @content            NVARCHAR(MAX)= NULL
                                              , @timeStampMessage   DATETIME    = NULL
                                              , @timeStampMessageUTC DATETIME   = NULL
                                              , @originType         VARCHAR(15) = NULL
                                              , @currency           VARCHAR(10) = ''-''
                                              , @price              VARCHAR(10) = ''0.00''
                                              , @messageStatus      VARCHAR(15) = ''N/A''
                                              , @listConversationsIds   VARCHAR(MAX) = NULL
        AS
        BEGIN
            DECLARE @isEndConversation BIT;
            DECLARE @meanContactTypeId SMALLINT;
            DECLARE @conversationIdNew INT;
            SET @meanContactTypeId = 1;
            SET NOCOUNT ON;

            IF @action = 1
            BEGIN --new Conversation
                IF NOT EXISTS
                              (SELECT A.conversationId conversationId FROM ccWhatsAppConversations A
                               WHERE A.conversationId = @conversationId
                              )
                BEGIN
                    INSERT INTO [ccWhatsAppConversations]
                    (inboundId
                   , phoneACD
                   , clientId
                   , conversationStatus
                   , tChatting
                   , tWrapUp
                   , finishedBy
                   , onQueue
                   , tQueue
                   , tTimeout
                   , disposition
                   , subDisposition
                   , agentId
                    )
                    VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);

                    IF NOT EXISTS (SELECT WhatsAppSpamId FROM ccWhatsAppSpam WHERE NumberClient = @clientId and InboundId = @inboundId) BEGIN
                        SELECT @conversationId = SCOPE_IDENTITY();
                        SELECT @conversationId AS ConversationId;
                    END
                    ELSE BEGIN

                        declare @conversationIdTemporal     INT;
                        SELECT @conversationIdTemporal = SCOPE_IDENTITY();
                        EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationIdTemporal, @conversationStatus = 13
                        SELECT 0 AS ConversationId;
                    END;

                    --Save new request
                    IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @inboundId)
                        BEGIN
                            INSERT INTO ccWAOperatingSummary (InboundId, Request) VALUES (@inboundId, 1);
                        END
                    ELSE
                        BEGIN
                            UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId
                        END



                    RETURN(0);
                END
                ELSE
                BEGIN
                    DECLARE @conversationStatusTemp INT = @conversationStatus;
                    IF @conversationStatus in(17,18) BEGIN
                        SET @conversationStatusTemp = 1
                    END
                     INSERT INTO [ccWhatsAppConversations]
                    (inboundId
                   , phoneACD
                   , clientId
                   , conversationStatus
                   , tChatting
                   , tWrapUp
                   , finishedBy
                   , onQueue
                   , tQueue
                   , tTimeout
                   , disposition
                   , subDisposition
                   , agentId
                    )
                    VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
                    SELECT @conversationIdNew = SCOPE_IDENTITY();

                    INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore
                                                                     , conversationIdAfter)
                        VALUES (@conversationId, @conversationIdNew);
                    --Save new request by reassign
                    UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId

                EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

                SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship where conversationIdBefore = @conversationId;
                RETURN(0);
            END;
        END;

        IF @action = 2
        BEGIN --save conversation Times
            DECLARE @conversationIdTemp INT;
            DECLARE @TablaTemp TABLE (conversationId INT, status bit);

            IF @listConversationsIds IS NOT NULL begin
                INSERT INTO @TablaTemp
                SELECT value,0
                FROM fn_RIASplitDelimited(@listConversationsIds, '','')
                where value is not null and value<>''''
            end
            else begin
                INSERT INTO @TablaTemp values(@conversationId,0)
            end

            UPDATE ccWhatsAppConversations
            SET
            conversationStatus = @conversationStatus
            , finishedBy = case when @conversationStatus = 10 then 2
                when @conversationStatus = 17 then 2
                when @conversationStatus = 18 then 2
                else 1 end
            , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
            ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
            ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
            WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

             WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
            BEGIN
                select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
                exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5

                IF @conversationStatus in(13,10,17,18,11) BEGIN
                    DECLARE @conversationDateTemp INT;
                    select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end from ccWhatsAppConversations where conversationId = @conversationId;

                    IF @conversationStatus = 13 BEGIN
                        IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
                            INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
                        END
                    END
                    ELSE IF @conversationStatus in(10,17,18) BEGIN --Save conversation Ended by system
                        IF @conversationDateTemp > 0 BEGIN
                            UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
                        END
                        ELSE BEGIN
                             UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1) WHERE InboundId = @inboundId
                        END
                    END
                    ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
                        UPDATE ccWAOperatingSummary SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
                    END
                END
                update @TablaTemp set status=1 where conversationId=@conversationIdTemp
            END

        END;

        IF @action = 3
        BEGIN --save conversation Status
            UPDATE ccWhatsAppConversations
                   SET
                       --conversationDate = GETDATE(),
                       conversationStatus = @conversationStatus
            WHERE conversationId = @conversationId;
        END;

        IF @action = 4 BEGIN --save messages from conversation
            IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId)
                AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversations A WHERE A.messageId=@messageId)
            BEGIN
                IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
                    (SELECT messageIdUi
                      FROM ccWAMessagesConversations
                     WHERE originType IN (''Agent'', ''Admin'')
                       AND conversationId = @conversationId)
                    BEGIN
                        UPDATE ccWhatsAppConversations
                           SET FirstMessageAgent = @timeStampMessage
                         WHERE conversationId = @conversationId;
                    END

                INSERT INTO [ccWAMessagesConversations](
                                                    messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
                                                   (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
                SELECT @messageId=SCOPE_IDENTITY()
                SELECT @messageId as MessageId
                RETURN (0)
            END
            ELSE BEGIN
                SELECT 0 AS MessageId
                RETURN (0)
            END
        END;

            IF @action = 5
            BEGIN --save onQueue
                UPDATE ccWhatsAppConversations
                       SET onQueue = 1,
                       conversationStatus = @conversationStatus
                WHERE conversationId = @conversationId;
                SELECT @inboundId = inboundId FROM ccWhatsAppConversations where conversationId=@conversationId;
                UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue + 1) WHERE InboundId = @inboundId
            END;

        IF @action = 6
        BEGIN --save agent, assigdate and tqueue
            declare @agentIdTmp int
            SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversations A where A.conversationId = @conversationId

            IF (@agentIdTmp is null or @agentIdTmp=0)
            BEGIN
                UPDATE ccWhatsAppConversations
                       SET agentId = @agentId,
                       assignDate = getdate(),
                       conversationStatus = @conversationStatus
                       ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
                WHERE conversationId = @conversationId;

                SELECT @conversationId as conversationId
            SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations where conversationId=@conversationId;

            IF @onQueue = 1 BEGIN
            UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1) WHERE InboundId = @inboundId
            END
            END
        END;

            IF @action = 7
            BEGIN --update price message
                UPDATE ccWAMessagesConversations
                       SET price = @price,
                           currency = @currency
                WHERE messageId = @messageId;
            END;

            IF @action = 8
            BEGIN --update status message
                IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
                    UPDATE ccWAMessagesConversations
                           SET messageStatus = @messageStatus
                    WHERE messageId = @messageId;
                END;
            END;

            IF @action = 9
            BEGIN --Save last message time by conversationID
                IF (SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversation A WHERE A.conversationId=@conversationId) IS NULL BEGIN
                    INSERT INTO ccLastMessageAgentByConversation (conversationId) VALUES (@conversationId)
                END;
                ELSE
                    BEGIN
                        UPDATE ccLastMessageAgentByConversation
                           SET timeStampLastMessageAgent = getDate()
                        WHERE conversationId = @conversationId;
                    END;
            END;

            IF @action = 10
            BEGIN --drop and insert register by conversationID
                DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
            END;

            IF @action = 11
            BEGIN --register desconnection agent by conversationID
                UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
            END;

            IF @action = 12
            BEGIN --Obtain conversationsWA post MCS reset

                declare @disconnectionIdTemp int = (select top 1 disconnectionId from ccDisconnectionMCS where timeStampConnection is null order by timeStampDisconnection desc);
                UPDATE ccDisconnectionMCS SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

                declare @from as datetime;-- = ''01-07-2022'';
                select @from = convert(datetime,convert(varchar(11),getdate()))
                set @from=DATEADD(dd,-1,@from);
                    select A.conversationId, A.inboundId, A.phoneACD, A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, A.onQueue, A.agentId, isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
                    ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
                    from ccWhatsAppConversations A
                    left join ccWAMessagesConversations B on A.conversationId = B.conversationId
                    left join ccDisconnectionMCS C on C.disconnectionId = @disconnectionIdTemp
                    --where B.conversationId is null
                    where A.requestDate >= @from 
                        and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
                    order by agentId desc, requestDate,timeStampMessage, inboundId, clientId 
            END;
            IF @action = 13
            BEGIN ---Obtain agents ON STATUS READY
                WITH agents
                AS(
                    SELECT c.User_id, c.fecha, c.currentStatus
                    FROM ccLogAgentesDia c
                    INNER JOIN 
                    (
                      SELECT User_id, MAX(fecha) max_time
                      FROM ccLogAgentesDia
                      GROUP BY User_id
                    ) AS t
                    ON c.fecha = t.max_time
                    AND c.User_id=t.User_id AND currentStatus in (3,34)
                ), usersByCampigns
                AS (
                    select IdCampEsp, User_id from ccRIACampEspWG A
                    Inner join ccRIAWorkGroupUsers B
                    on A.IDWG = B.IDWG
                    Inner join contactMeanIn C
                    ON A.idCampEsp = C.inboundId
                    where A.IDWG = 1 and A.Tipo = 0
                    AND C.meanContactTypeId = 5
                )

                select DISTINCT A.User_Id from agents A
                left join usersByCampigns B on A.User_Id = B.User_Id
            END;

            IF @action = 14
            BEGIN --register desconnection MCS
                INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
            END;
        END;'
        EXEC(@sql)

        set @process = 'Reinicio MCS se altera sp ccsp_ConversationWASave (se quito option 7)'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformation]
            @Option SMALLINT,
            @InboundId SMALLINT = 0,
            @ConversationId INT = 0,
            @AgentsAvailables INT = 0,
            @IncreaseDecreaseAgent BIT = NULL

            AS
            SET NOCOUNT ON

            IF @InboundId IS NOT NULL BEGIN
                IF EXISTS (SELECT * FROM ccInbound WHERE Inbound_id = @InboundId AND chat = 5) BEGIN
                    DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
                    --DECLARE @Today SMALLDATETIME = ''2022-03-24''
                    IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
                        BEGIN
                            IF EXISTS (SELECT * FROM ccWAAverageConversations
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
                                DECLARE @DefaultValue INT = (SELECT ISNULL(defaultServiceLevelParameter, 2) FROM contactMeanIn WHERE inboundId = @InboundId);
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
                    IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
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
                    IF @Option = 3 -- Save time from accepted conversation by agent
                    BEGIN
                        IF @ConversationId IS NOT NULL
                        BEGIN
                            UPDATE ccWhatsAppConversations SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
                            --Save Conversation Assigned
                            SELECT @inboundId = inboundId FROM ccWhatsAppConversations where conversationId=@conversationId;
                            UPDATE ccWAOperatingSummary SET Assigned = (Assigned + 1) WHERE InboundId = @inboundId
                            --EXEC ccsp_WhatsAppOperatingSummary @Option = 2, @InboundId = @CampIdTemp;
                        END
                    END
                    IF @Option = 4 -- Get Disposition Information
                    BEGIN
                        SELECT disposition.Description AS DispositionName,
                               disposition.calif_id AS DispositionId,
                               COUNT(whatsConv.disposition) AS Total,
                               disposition.GraphColor,
                               COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
                        FROM ccWhatsAppConversations whatsConv
                        INNER JOIN cctipocalif disposition ON disposition.calif_id = whatsConv.disposition
                        WHERE inboundId = @InboundId AND assignDate >= @Today
                        GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
                    END
                    IF @Option = 5 -- Get Subdisposition Information
                    BEGIN
                        SELECT relation.calif_id AS DispositionId,
                               subDispositions.califSubDesc AS SubDispositionsName,
                               COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
                        FROM cctipoSubCalifRel relation
                        INNER JOIN ccTipoCalifSub subDispositions ON subDispositions.califSub_id = relation.califSub_id
                        INNER JOIN ccWhatsAppConversations whatsConv ON whatsConv.subDisposition = subDispositions.califSub_id
                        WHERE whatsConv.inboundId = @InboundId AND
                              whatsConv.assignDate >= @Today AND
                              relation.tipoSubRel = 1
                        GROUP BY subDispositions.califSubDesc, relation.calif_id
                    END
                    IF @Option = 6 -- Agents Availables
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

                END
            END
            IF @Option = 0 BEGIN-- Reset TABLES
                TRUNCATE TABLE ccWAOperatingSummary;
                TRUNCATE TABLE ccWAAverageConversations;
                TRUNCATE TABLE ccLastMessageAgentByConversation;
            END
            RETURN(0)
            SET NOCOUNT OFF
        '
        EXEC(@sql)

        ------------------------------------------------------------  END  ----------------------------------------------------------------------------------------------------------------------------------

        ----------------------------------GMZ | CW-7258_GetCampaignByAudio --------------------------------------------------

        set @process = 'CW-7258_GetCampaignByAudio se modifica sp de ccsp_GalateaAutomaticMessages (se agrego action 11), Changes in action 1, adding the return of DefaultMessage column'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAutomaticMessages]
        @action as tinyint,
        @type as int = null,
        @msgFile as varchar(40) = '''',
        @Description as varchar(40) = '''',
        @length as int = null,
        @CampId INT = 0,
        @CampType SMALLINT = 0,
        @MessageType TINYINT = 0,
        @msgIdLst varchar(8000) = null,
        @msgName as varchar(40) = '''',
        @msg_id int = 0,
        @VariableData TINYINT = 0,
        @TtsType TINYINT = 0,
        @VariableOrder TINYINT = 0,
        @MsgRelation varchar(8000) = null

        AS

        SET NOCOUNT ON

        if @action = 1  -- Get audio catalog
        begin
            select ISNULL(msgName, msgFile) [MsgName], Descripcion [MsgDescription], msg_id [MsgId], DefaultMessage from ccMsgFiles
            where msgFile not like ''TTS|%''
            return (0)
        end

        if @action = 2
        begin
            if EXISTS(select msgName from ccMsgFiles where msgName=@msgName)
            begin
                select 1 as result
            end
            else
            begin 
                insert into ccMsgFiles (msgFile, descripcion, length, msgName) values (@msgFile, @Description, @length, @msgName)
                select 0 as result
            end 
            
        end 

        if @action = 3
        begin
            select msg_id from ccMsgFiles where msgName=@msgName
        end

        IF @action = 4 -- Get Assigned Messages by Campaign Id and Campaign Type
        BEGIN
            DECLARE @CampaignMessagesRelation TABLE (MessageType TINYINT, MessageOrder TINYINT, MessageFile VARCHAR(MAX), 
                                                     MessageId INT, MessageDescription VARCHAR(MAX), Queue BIT)
            IF @CampType = 0  -- Inbound Campaigns
                BEGIN
                    INSERT INTO @CampaignMessagesRelation (MessageType, MessageOrder, MessageFile, MessageId, MessageDescription, Queue) 
                    EXEC ccsp_RIAADMInboundMsgs @Command = 1,@Inbound_id = @CampId
                END
            ELSE              -- Outbound Campaigns
                BEGIN 
                    INSERT INTO @CampaignMessagesRelation (MessageType, MessageOrder, MessageFile, MessageId, MessageDescription)
                    EXEC ccsp_RIAADMCampMsgs @Command = 1, @cam_id = @CampId
                    UPDATE @CampaignMessagesRelation SET Queue = 0
                END
            SELECT * FROM @CampaignMessagesRelation WHERE MessageType = @MessageType
        END 

        IF @action = 5 -- Delete audio message
        begin
            if exists(select Msg_id from ccInboundMsgs where Msg_id in (select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')))
            begin
                select 0 as result
                return(0)
            end
            if exists(select Msg_id from ccCampsMsgs where Msg_id in (
        select B.msg_id from dbo.fn_RIASplitDelimited(@msgIdLst, '','') A
        inner join ccMsgFiles B on A.Value=B.msg_id 
        where msgFile not like ''TTS|%''
        )
        )
            begin
                select 0 as result
                return(0)
            end
            
            delete A from ccCampsMsgs A where Msg_id in (
            select B.msg_id from dbo.fn_RIASplitDelimited(@msgIdLst, '','') A
            inner join ccMsgFiles B on A.Value=B.msg_id 
            where msgFile like ''TTS|%'')

            delete ccMsgFiles Where msg_id in (select value from dbo.fn_RIASplitDelimited(@msgIdLst, '',''))
            select 1 as result
            return(0)
        end 

        if @action = 6
        BEGIN
            if @type = 0
                BEGIN
                    update ccMsgFiles set Descripcion = @Description, msgName = @msgName where msg_id = @msg_id
                END
            else
                BEGIN
                    update ccMsgFiles set Descripcion = @Description, msgName = @msgName, msgFile = @msgFile, length = @length where msg_id = @msg_id
                END
        END 

        if @action = 7
        BEGIN
            select msg_id as msgId, msgName as MsgName, Descripcion as MsgDescription from ccMsgFiles where msg_id = @msg_id
        END

        IF @action = 8
        BEGIN
            DECLARE @Language TINYINT = (SELECT valor from ccSettings where setting_id = 27)
            DECLARE @TempMsgFile VARCHAR(10) = (''TTS'' + ''|'' + CONVERT(VARCHAR(2), @TtsType) + ''|'' + CONVERT(VARCHAR(2), @VariableData))
            SET @Description = (SELECT CASE WHEN @Language = 0 THEN TtsTypesTagsSpanish 
                                            WHEN @Language = 1 THEN TtsTypesTagsEnglish 
                                            ELSE TtsTypesTagsPortuguese END 
                                FROM ccRIA_AutamaticMessages_TtsTypesTags 
                                WHERE Id = @VariableData) 
                                + ''|'' + 
                                (SELECT VariableDataTag FROM ccRIA_AutamaticMessages_VariableDataTags 
                                WHERE LanguageId = @Language)
                                + CONVERT(VARCHAR(2), @VariableData) 
                                + ''|'' + CONVERT(VARCHAR(2), @CampId) 

            IF @msg_id = 0
            BEGIN
            EXEC ccsp_RIAADMCampMsgs @Command = 3, @cam_id = @CampId, @order = @VariableOrder,@type=8,@msgFile=@TempMsgFile,@description=@Description   
            END
            ELSE
            BEGIN
                UPDATE ccMsgFiles SET msgFile = @TempMsgFile, Descripcion = @Description where msg_id = @msg_id
            END
            
        END

        IF @action = 9
        BEGIN
            select msgFile [MsgFile] from ccMsgFiles where msg_id in (select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')) and msgFile not like ''TTS|%''
        END

        IF @action = 10
        BEGIN
            IF @CampType = 0  -- Inbound Campaigns
                BEGIN
                    UPDATE b SET b.orden = a.Id - 1 FROM dbo.fn_RIASplitDelimited(@MsgRelation, '','') a INNER JOIN ccInboundMsgs b ON b.Inbound_id = @CampId AND b.Type = @MessageType AND b.Msg_id = a.Value 
                END
            ELSE              -- Outbound Campaigns
                BEGIN 
                    UPDATE b SET b.orden = a.Id - 1 FROM dbo.fn_RIASplitDelimited(@MsgRelation, '','') a INNER JOIN ccCampsMsgs b ON b.cam_id = @CampId AND b.Type = @MessageType AND b.Msg_id = a.Value 
                END
        END

        IF @action = 11
        BEGIN
            (select OC.cam_id as Camp_Id, Camp_Type = 1, ISNULL(cam_descripcion,'''''''') as [Name], Graphics.frame as Frame, CM.Type, ISNULL(OC.IDArea,0) as IdArea, ISNULL(AREas.AreaName,'''') as AreaName
            from ccCamps as OC with(nolock) 
            left join ccRIACat_Areas as AREas with(nolock) on OC.IDArea = AREas.IDArea
            inner join ccRIACampsGraph as CampsGraph on OC.cam_id = CampsGraph.cam_id
            inner join ccRIAGraphics as Graphics on Graphics.graphic_id = CampsGraph.graphic_id
            inner join ccCampsMsgs CM on CM.cam_id = OC.cam_id
            Where CM.msg_id = @msg_id)
            UNION ALL
            (select IC.Inbound_id as Camp_Id, Camp_Type = 0,ISNULL(descripcion,'''''''') as [Name], Graphics.frame as Frame, IM.Type, ISNULL(IC.IDArea,0) as IdArea, ISNULL(AREas.AreaName,'''') as AreaName
            from ccInbound as IC with(nolock) 
            left join ccRIACat_Areas as AREas with(nolock) on IC.IDArea = AREas.IDArea
            inner join ccRIAInboundGraph as CampsGraph on IC.Inbound_id = CampsGraph.Inbound_id
            inner join ccRIAGraphics as Graphics on Graphics.graphic_id = CampsGraph.graphic_id
            inner join ccInboundMsgs IM on IM.Inbound_id = IC.Inbound_id
            Where IM.msg_id = @msg_id)
        END


        SET NOCOUNT OFF'
    EXEC(@sql)

        ------------------------------------------------------------  END  ----------------------------------------------------------------------------------------------------------------------------------

        ----------------------------------GMZ | K002145-Historial --------------------------------------------------

        set @process = 'K002145-Historial se modifica option 1, se agrego parametro inboundId en los filtros de la consulta'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentHistoricalChat] @option SMALLINT, @clientNum VARCHAR(15) = '''', @conversationId AS INT = 0, @inboundId AS SMALLINT = 0, @serviceType AS SMALLINT = 0
            AS
            BEGIN
                IF @option = 1 --whatsapp, get conversation ids
                BEGIN
                    SELECT conversationId
                    FROM [CCenterRIA].[dbo].[ccWhatsAppConversations]
                    WHERE clientId = @clientNum AND
                        inboundId = @inboundId 
                    GROUP BY conversationId
                END

                IF @option = 2 --whatsapp, get acdId by conversation id
                BEGIN
                    SELECT CAST(inboundId AS INT)
                    FROM [CCenterRIA].[dbo].[ccWhatsAppConversations]
                    WHERE conversationId = @conversationId
                END

                IF @option = 3 --get data conversation
                BEGIN
                    DECLARE @OldAgentId INT = 0
                    DECLARE @OldConversationId INT = 0

                    SELECT @OldAgentId = conv.agentId, @OldConversationId = rel.conversationIdBefore
                    FROM ccWhatsAppConversationsRelationship rel
                    RIGHT JOIN ccWhatsAppConversations conv ON conv.conversationId = rel.conversationIdBefore
                    WHERE rel.conversationIdAfter = @conversationId

                    SELECT cast(i.chat AS INT) AS ServiceType, cast(c.conversationId AS INT) AS ConversationID, c.clientId AS ClientId, cm.conexionInfo AS [To], cast(i.Inbound_id AS INT) AS ACDId, i.descripcion AS ACDName, cast(g.
                            graphic_id AS INT) AS ACDGraphicId, cast(cm.closeConversationTime AS INT) AS [TimeOut], cast(cm.answerTimeOut AS INT) AS [TimeOutWarning], i.ExitWrapUpDisposition AS [ExitWrapUpDisposition], i.tNotas AS 
                        [WrapUpTime], i.ShowCalifWnd, cast(ISNULL(answerTimeoutClient, 30) AS INT) AS [AnswerTimeoutClient], ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS 
                        [SecTimeOutLastMessageAgent], isnull(permission.AllowUnassign, 0) AS AllowUnassign, isnull(permission.AllowSpam, 0) AS AllowSpam, ISNULL(@OldAgentId, 0) AS OldAgentId, ISNULL(@OldConversationId, 0) AS 
                        OldConversationId, c.agentId AS AgentId
                    FROM ccInbound i
                    INNER JOIN contactMeanIn cm ON i.Inbound_id = cm.inboundId
                    INNER JOIN ccWhatsAppConversations c ON (
                            c.inboundId = i.Inbound_id
                            AND c.conversationId = @conversationId
                            )
                    INNER JOIN ccRIAInboundGraph g ON g.Inbound_id = i.Inbound_id
                    LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
                    LEFT JOIN ccRIAMultimediaUsersPermissions permission ON permission.AgentId = c.agentId
                    WHERE i.chat = @serviceType
                        AND i.Inbound_id = @inboundId

                END

                IF @option = 4 --get messages from conversation id
                BEGIN
                    DECLARE @filetype AS VARCHAR(5)

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
                            WHEN typeMessage NOT IN (''text'', ''location'')
                                THEN content
                            ELSE ''''
                            END AS Caption, CASE 
                            WHEN originType = ''Client''
                                THEN CASE 
                                        WHEN typeMessage = ''text''
                                            OR typeMessage = ''location''
                                            THEN ''''
                                        ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
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
                            END AS [LocationURL]
                    FROM ccWAMessagesConversations
                    WHERE conversationId = @conversationId
                    ORDER BY TIMESTAMP ASC
                END

                IF @option = 5 --get if conversation is reassigned
                BEGIN
                    SELECT CASE 
                            WHEN EXISTS (
                                    SELECT *
                                    FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationship]
                                    WHERE conversationIdAfter = @conversationId
                                    )
                                THEN CAST(1 AS BIT)
                            ELSE CAST(0 AS BIT)
                            END
                END
            END'
        EXEC(@sql)

        ----------------- GG |  CW-6927|CW-7423 DNIS Asociados | CW-7422 Campa?s relacionadas--------------------------------------------------

        set @process = 'CW-6927 y CW-7422 Se agrega IDWG en select y delete en ccInboundDnis'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaDeleteCampaignAndACD]
        @userId           SMALLINT,
        @DeleteCamId      VARCHAR(MAX),
        @DeleteACDGroupId VARCHAR(MAX),
        @moduleId         SMALLINT = 49
    AS
    BEGIN

        IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
            SELECT value As DeleteCamId, c.IDArea AS IDAreaCamp, 1 AS CampTypeCamp, ISNULL(wg.IDWG,0) as IDWG
            INTO #CampsDelete
            FROM fn_RIASplitDelimited(@DeleteCamId, '','') a
            inner join ccCamps c on  a.value = c.cam_id and c.IDArea IS NOT NULL
            left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=1
        IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
            SELECT value As DeleteACDId, c.IDArea AS IDAreaACD, 0 AS CampTypeACD, ISNULL(wg.IDWG,0) as IDWG
            INTO #ACDDelete
            FROM fn_RIASplitDelimited(@DeleteACDGroupId, '','') a
            inner join ccInbound c on  a.value = c.Inbound_id and c.IDArea IS NOT NULL
            left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=0

        IF  not Exists (select * from #CampsDelete union select * from #ACDDelete )
        begin
            select ''-1'' AS Result
            return
        end

        IF datalength(@DeleteCamId) > 0
            BEGIN

            if exists(select cam_id from ccInbound where cam_id in (select DeleteCamId from #CampsDelete)) begin
                --Borra las calificacion con reprogramacion
                delete ccCalifCamp from ccInbound A
                inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
                inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
                where A.cam_id in (select DeleteCamId from #CampsDelete)
                --Borra las subcalificacion con reprogramacion
                delete rel from ccInbound A
                inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
                inner join ccTipoCalif C on B.calif_id=C.calif_id
                inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
                inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
                where A.cam_id in (select DeleteCamId from #CampsDelete) and sb.canReprogram=1

                update ccInbound set cam_id = null where cam_id in (select DeleteCamId from #CampsDelete)

            end

            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
            select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete)

            delete from ccCampsAgente where cam_id in (select DeleteCamId from #CampsDelete)
            insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
            select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete) and A.tipo = 1

            delete from ccSupervisorCam where cam_id in (select DeleteCamId from #CampsDelete) and tipo = 1
            delete from ccRIACampEspWG where IdCampEsp in (select DeleteCamId from #CampsDelete) and tipo = 1

            IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
            SELECT ca.AreaName,
                   GETDATE() operationDate,
                   27 operationType,
                   (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                   @moduleId module_id,
                   c.cam_descripcion value,
                   ca.AreaName AS target
            INTO #CampLog
            FROM ccRIACat_Areas ca
            Inner join ccCamps c with(nolock) on ca.IDArea = c.IDArea
            WHERE c.cam_id in (select DeleteCamId from #CampsDelete)

            Update ccCamps set IDArea = null where cam_id in (select DeleteCamId from #CampsDelete)

        END
        IF datalength(@DeleteACDGroupId) > 0
            BEGIN

            if exists(select top 1 cam_id from ccInbound where Inbound_id in (select DeleteACDId from #ACDDelete))
                begin
                    update ccInbound set cam_id = null where Inbound_id in (select DeleteACDId from #ACDDelete)
            end

            IF OBJECT_ID(''tempdb..#AllWGACD'') IS NOT NULL DROP TABLE #AllWGACD
            SELECT DISTINCT(IDWG)
            INTO #AllWGACD
            FROM ccRIACampEspWG ce
            WHERE IDCampEsp in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0

            insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
            select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG
            from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id
            where B.User_id is null and A.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

            delete ccInboundHorarios Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
            delete ccInboundMsgs Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
            delete ccInboundDnis where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
            select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG
            from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id
            where B.User_id is null and A.cam_id in (SELECT DeleteACDId FROM #ACDDelete)

            delete ccSupervisorCam where cam_id in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0
            delete ccInboundAgentes where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
            delete ccRIACampEspWG where IdCampEsp  in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0


            IF OBJECT_ID(''tempdb..#ACDLog'') IS NOT NULL DROP TABLE #ACDLog
            SELECT ca.AreaName,
                    GETDATE() operationDate,
                    28 operationType,
                    (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                    @moduleId module_id,
                    i.descripcion value,
                    ca.AreaName AS target
            INTO #ACDLog
            FROM ccRIACat_Areas ca
            inner join ccInbound i with(nolock) on ca.IDArea = i.IDArea
            WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

            Update ccInbound set IDArea = null, status = 0 where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

            if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
                begin
                    update ContactMeanIn set name = '''', conexionInfo = ''usuarioID|token|tokenSecret|1|0'', connUser = '''', isActive = 0
                    where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=2
            end
            if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
                begin
                    update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=1
            end
            update ccinbound set chatDomain = '''' where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)--para desasociar el dominio del chat

            if exists (SELECT inboundId FROM contactMeanIn WHERE inboundId in (select DeleteACDId from #ACDDelete))
                begin
                    update contactMeanIn set isActive = 0 where inboundId in (select DeleteACDId from #ACDDelete)
            end

            if exists (SELECT inboundId FROM ccWhatsAppNumbers WHERE inboundId in (select DeleteACDId from #ACDDelete))
                begin
                    update ccWhatsAppNumbers set inboundId = 0 where inboundId in (select DeleteACDId from #ACDDelete)
            end
        END

        IF datalength(@DeleteCamId) > 0
            Insert into ccRIALog Select * from #CampLog
        IF datalength(@DeleteACDGroupId) > 0
            Insert into ccRIALog Select * from #ACDLog

        SELECT DeleteCamId AS DeleteId,IDAreaCamp AS IDArea,CampTypeCamp AS CampType,''1'' AS Result, cast(IDWG as smallint) IDWG FROM #CampsDelete
        UNION
        SELECT DeleteACDId,IDAreaACD,CampTypeACD,''1'' AS Result, cast(IDWG as smallint) IDWG FROM #ACDDelete
        IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
        IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
    END'
        EXEC(@sql)

        set @process = 'CW-7423 Se agrega delete ccInboundDnis en option 6 y 8'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAManageAreas]
@option tinyint,
@IDArea smallint = 0,
@InsertUserId smallint =null,
@DeleteUserId varchar(255)=null,
@InsertCamId smallint=null,
@DeleteCamId smallint=null,
@InsertACDGroupId smallint=null,
@DeleteACDGroupId smallint=null
as
set nocount on

if @option = 1 -- Insert User Area
    begin
    if not exists(select IDArea from ccUsers where IDArea = @IDArea AND User_id = @InsertUserId)
        begin
        Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @InsertUserId
        return(0)
        end 
                     
    select 1
    return(0)
    end

if @option = 3 -- Insert camp area
    begin
    if not exists(select IDArea from ccCamps where IDArea = @IDArea and cam_id = @InsertCamId)
        begin
        Update ccCamps set IDArea = case @IDArea when 0 then null else @IDArea end
        where cam_id = @InsertCamId
        return(0)
        end

    select 1
    return(0)
    end

if @option = 4 begin-- Delete camp area
    

    --Si existe una campa? relacionada con el grupo
    if exists(select cam_id from ccInbound where cam_id=@DeleteCamId) begin
        select -4
        return(0)    
    end

    insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId
                 
    delete from ccCampsAgente where cam_id = @DeleteCamId   

    insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1    

    delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
    delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1  
    delete from ccoWorkingTable where cam_id = @DeleteCamId
    
    Update ccCamps set IDArea= null where cam_id=@DeleteCamId--, cam_activo = 0 
    return(0)
    end

if @option = 5 -- Insert ACDGroup area
    begin
    if not exists(select IDArea from ccInbound where IDArea = @IDArea and Inbound_Id = @InsertACDGroupId)
        begin
        Update ccInbound set IDArea = @IDArea, status = 1 where Inbound_id = @InsertACDGroupId
        return(0)
        end

    select 1
    return(0)
    end

if @option = 6 -- Delete ACDGroup area
    begin
        insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

    delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
    delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId
    delete ccInboundDnis where Inbound_id = @DeleteACDGroupId

    insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId and A.tipo = 0

    delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
    delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
    delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

    Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId
    select 1
    return(0)
    end

if @option in (2, 9, 10, 11)
    begin
        declare @Type tinyint
    select @Type = TipoUser_id from ccUsers where User_id = @DeleteUserId
                    
    if @option in (2, 10, 11) -- Delete User area
        begin
        if @Type = 1 -- Agente
            begin

            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
            insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

            delete from ccCampsAgente where user_id = @DeleteUserId
            delete from ccInboundAgentes where user_id = @DeleteUserId

            if @option = 11
                begin
                    select IDWG, User_id into #WorkGroupUsers from ccRIAWorkGroupUsers where user_id = @DeleteUserId

                    delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
                                    
                    select * from #WorkGroupUsers
                    drop table #WorkGroupUsers
                                    
                    return(0)
                end
            end

        else if @Type in (2, 6) -- Supervisor
        begin
            insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
            delete from ccSupervisorCam where user_id = @DeleteUserId
        end

        delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
                        
        if @option=2
            begin
            update ccPosicion set user_id = 0 where user_id = @DeleteUserId
            update ccUsers set IDArea = null where user_id = @DeleteUserId  
            end
        return(0)
    end

    declare @UserWG varchar(100)
    -- @option = 9 -- Delete User area and get his workgroups

    select @UserWG = IDWG from ccRIAWorkGroupUsers where user_id = @DeleteUserId

    if @Type = 1 -- Agente
        begin
        insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG   from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
        insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

        delete from ccCampsAgente where user_id = @DeleteUserId
        delete from ccInboundAgentes where user_id = @DeleteUserId
        end

    if @Type in (2, 6) -- Supervisor
        begin
        insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId

        delete from ccSupervisorCam where user_id = @DeleteUserId
        delete from ccMenuUser where id_User = @DeleteUserId
        end

    delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
    update ccPosicion set user_id = 0 where user_id = @DeleteUserId
                    
    if @option <> 11
        update ccUsers set IDArea = null where user_id = @DeleteUserId
                    
    select @UserWG, @Type
    return(0)
    end

declare @AllWG varchar(400), @CurrentWG varchar(400), @AreaDescripcion varchar(40)

if @option = 7 begin-- Delete camp area
    
    if exists(select cam_id from ccInbound where cam_id=@DeleteCamId) begin
    
        ---Borra las calificacion con reprogramacion
        delete ccCalifCamp from ccInbound A 
        inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
        inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
        where A.cam_id=@DeleteCamId
        ---Borra las subcalificacion con reprogramacion
        delete rel from ccInbound A 
        inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
        inner join ccTipoCalif C on B.calif_id=C.calif_id 
        inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
        inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
        where A.cam_id=@DeleteCamId and sb.canReprogram=1
    
        update ccInbound set cam_id = null where cam_id=@DeleteCamId                
         
    end

    select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

    insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId

    delete from ccCampsAgente where cam_id = @DeleteCamId
    insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1

    delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
    delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1
    
    delete from ccoWorkingTable where cam_id = @DeleteCamId  

    select @CurrentWG = coalesce(@CurrentWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

    select @AreaDescripcion = area.AreaName
    from ccCamps as camp with(nolock)inner join ccRIACat_Areas as area 
        with(nolock) on camp.IDArea = area.IDArea
    where camp.cam_id = @DeleteCamId
    Update ccCamps set IDArea = null where cam_id = @DeleteCamId

    If @CurrentWG is null
        set @CurrentWG = 0

    If @AllWG is null
        set @AllWG = 0

    select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
    return(0)
    end

if @option = 8 --Delete ACDGroup area
    begin
    if (select cam_id from ccInbound where Inbound_id = @DeleteACDGroupId) is not null
    begin
        update ccInbound set cam_id = null where Inbound_id = @DeleteACDGroupId
    end

    select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

    insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

    delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
    delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId
    delete ccInboundDnis where Inbound_id = @DeleteACDGroupId

    insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId 

    delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
    delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
    delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

    select @CurrentWG = coalesce(@CurrentWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

    select @AreaDescripcion = area.AreaName
    from ccInbound as ACD with(nolock) inner join ccRIACat_Areas as area 
        with(nolock) on ACD.IDArea = area.IDArea
    where ACD.Inbound_id = @DeleteACDGroupId
    Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId

    If @CurrentWG is null
        set @CurrentWG = 0

    If @AllWG is null
        set @AllWG = 0

    select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
    
    if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId=@DeleteACDGroupId)--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
    begin
        DECLARE @TwitterResult table(--Se declaro por que el SP ccsp_MailAdminAccount regresa una consulta.  
        result int,  
        operation varchar(30));
        insert @TwitterResult
        EXEC [dbo].[ccsp_MailAdminAccount] @action = 22,@meanContactTypeId = 2, @inboundId = @DeleteACDGroupId--se ejecutara el SP para desasociar la cuenta de mail
    end
    if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId=@DeleteACDGroupId)--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
    begin
        update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId = @DeleteACDGroupId and meanContactTypeId=1
    end
    update ccinbound set chatDomain = '''' where inbound_id = @DeleteACDGroupId--para desasociar el dominio del chat
    return(0)
    end

return(0)
set nocount off'
        EXEC(@sql)

       ----------------------------------CW-7233 Orden de marcacion --------------------------------------------------
    
        set @process = 'ALter sp ccsp_RIAAdmPrioridadTelefonos se agrega return'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAAdmPrioridadTelefonos]
          @cam_id int,
          @prioridad varchar(8),
          @callbacks bit = 0,
          @Type tinyint
        AS


        IF @Type = 3
            BEGIN
                INSERT INTO ccCampsPrioridadTel
                VALUES
                (@cam_id, 
                 ''12345NNN''
                )
        END
        IF @Type = 2
            BEGIN
                IF NOT EXISTS
                (
                    SELECT *
                    FROM ccCampsPrioridadTel
                    WHERE cam_id = @cam_id
                )
                    BEGIN
                        INSERT INTO ccCampsPrioridadTel
                        VALUES
                        (@cam_id, 
                         ''12345NNN''
                        )
                END
                UPDATE ccCampsPrioridadTel
                  SET 
                      prioridad = @prioridad
                WHERE cam_id = @cam_id
                IF @callbacks = 1
                    BEGIN
                        --Ahora cambia todos los registros en ccCampsPrioridadTel.  Solo nuevos
                        UPDATE ccCampsPrioridadTel
                          SET 
                              Prioridad = @prioridad
                        WHERE cam_id = @cam_id
                              AND cam_id IN
                        (
                            SELECT cam_id
                            FROM ccoWorkingTable
                            WHERE cam_id = @cam_id
                                  AND cal_status = 0
                        )
                END
                SELECT @cam_id
        END
        IF @Type = 1
            BEGIN
                SELECT ccCamps.cam_id, 
                       Prioridad
                FROM ccCamps, 
                     ccCampsPrioridadTel
                WHERE ccCamps.cam_id = @cam_id
                      AND ccCampsPrioridadTel.cam_id = @cam_id
        END
'

        EXEC(@sql)
----------------------------------K013000 DASHBOARD --------------------------------------------------
                set @process = 'ALter sp ccsp_OUTGetNewJobs se agrega nombre del agente y orden por calloutID'
        set @sql = '
        ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
        @CAMPID int,
        @test int=0,
        @nAgentsLogin int=1,
        @iZonas int = null
        as
        --set nocount on
        declare @total int
        declare @topCount smallint, @bIsDaylight bit, @revHorario bit
        declare @country_id int, @TipoJobs int
        --declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
        declare @sql varchar(MAX), @Order_Asc_Desc char(4)
        declare @camSurvey int
        select @camSurvey = 0
        DECLARE @iZonasTable TABLE (value int)

        select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

        -- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
        SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
        select @revHorario=valor from ccsettings where setting_id = 112
        -- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
        SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
        SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

        SET DATEFIRST 1
        --Checamos si es horario de verano
        select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

        if @iZonas is null begin

              INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
              select @iZonas=value from @iZonasTable
        --Checamos si la campaÃ±a tiene horarios configurados
              if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
              begin
                          if @iZonas = 0 begin
                                SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                                return
                          end
              end
              else begin
                    if @camSurvey > 0
                          begin
                                SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                                return
                          end
              end
        end

        set @sql=''CREATE TABLE #NEW_JOBS
        (callout_id int,
              cam_id int,
              cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
              cal_status tinyint,
              cal_fechaDial datetime,
              user_id int,
              tz int,
        tz2 int,
        tz3 int,
        tz4 int,
        tz5 int,
        list_id int,
        sequence smallint,
        calkey varchar(max),
        nDescartes int,
        name_agent varchar(max)
        )''


        -- 0=Ambas, 1=CallBacks, 2=Nuevas
        select @topCount=valor from ccSettings where setting_id=94

        if isnull(@topCount,0)=0
        select @topCount=case when @nAgentsLogin<3 then 30
              when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
              when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
              when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
              when @nAgentsLogin>=16 then 240 else 20 end

        select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

        declare @isVerano varchar(max)
        set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

        if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
        begin

                    select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

                    select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
                    SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
                    +@isVerano+'',''
                    +@isVerano+''2,''
                    +@isVerano+''3,''
                    +@isVerano+''4,''
                    +@isVerano+''5,
                    W.list_id, isNull(R.sequence,0) as sequence,
                    cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
                    isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent
                    FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
                    left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
                    left join ccUsers us (nolock) on us.User_id=w.user_id
                    WHERE W.cal_status=1 -- CallBacks
                    and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
                    and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
                    and (
                          ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                    or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                          ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                    or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                          ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                    or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                          ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                    or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                          ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                    or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
                    )
                    and isnull(R.status,2) = 2
                    order by prioridad_cb desc, W.cal_fechaDial ''  + @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
                    
                    --select @sql
        end -- TOMA EN CUENTA LOS CALLBACKS

        if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
        begin
                    select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

                    select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
                    SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
                    +@isVerano+'',''
                    +@isVerano+''2,''
                    +@isVerano+''3,''
                    +@isVerano+''4,''
                    +@isVerano+''5,
                    W.list_id, isNull(R.sequence,0) as sequence,
                    cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
                    isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent
                    FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
                    left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
                    left join ccUsers us (nolock) on us.User_id=w.user_id
                    WHERE W.cal_status=0 -- Nuevas
                    and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
                    and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
                    and (
                          ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                    or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                           ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                    or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                           ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                    or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                           ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                    or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                           ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                    or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
                    )
                    and isnull(R.status,2) = 2
                    order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc

        end -- TOMA EN CUENTA LAS NUEVAS
        ----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
        select @sql=@sql+nchar(13)+ ''SET rowcount 0''
        if @Test=0
              begin
                    select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
                    WHERE callout_id in(select callout_id from #NEW_JOBS)''
        end

        if @Test = 2
        begin
              select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
              declare @nSQL nvarchar(4000)
              set @nSQL=cast(@sql as nvarchar(4000))
              exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
              return(@total)
        end
        else
        begin
              select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
        user_id, tz, tz2, tz3, tz4, tz5,
        case when tz is null then '''''''' else cal_telefono end as tel,
        case when tz2 is null then '''''''' else cal_telefono end as tel2,
        case when tz3 is null then '''''''' else cal_telefono end as tel3,
        case when tz4 is null then '''''''' else cal_telefono end as tel4,
        case when tz5 is null then '''''''' else cal_telefono end as tel5,
        NULL as dialOrder, list_id, sequence, calkey,
        0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type, nDescartes, name_agent
        FROM #NEW_JOBS where len(cal_telefono)>0

        ---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
        declare @regval int
        SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
        exec ccsp_GetCampsNvosCB @cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + '',@Tipo=0,@user_id =0
        ''
        end

        set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
        print (@sql)
        exec(@sql)

        return(0)

            '

        EXEC(@sql)
        set @process = 'ALter sp [ccsp_GetCampsNvosCB] se cambia nuevos por new'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GetCampsNvosCB]
            @cam_id integer = 0,
            @Tipo tinyint=0,
            @user_id int=0
            AS
            set nocount on
            declare @RecicleSIC tinyint,@sFin int,@sql varchar(8000)
            select @RecicleSIC=IsNull(valor,0)FROM ccSettings WHERE setting_id=60
            select @sFin=case when @RecicleSIC=0 and USER_NAME()<>''dbo'' then 0 else 1 end

            select @sql=''declare @ultimo as datetime
            if ''+cast(isnull(@Tipo,0) as varchar(10))+''=0
              begin
                if ''+cast(isnull(@cam_id,0) as varchar(10))+''=0 begin
                  select Camps.cam_id as ID,cam_descripcion as ''''Campaña'''',
                    IsNull(Jobs.New,0)as New,IsNull(Jobs.CB,0)as CB,IsNull(Jobs.Pro,0)as Pro,
                    IsNull(Pends.pend,0)as Pen,''+case when @sFin=1 then ''IsNull(Jobs.Fin,0)as Fin,'' else '''' end+''
                    case cam_procesando when 1 then ''''Pro'''' when 0 then '''''''' end as St,
                    case cam_TipoJobs when 2 then ''''New'''' when 1 then ''''CB'''' when 0 then ''''Amb'''' end as Job     
                  from ccCamps Camps(nolock)Left Join 
                  (select cam_id,
                    count(case cal_status when 0 then 1 else null end)as New,
                    count(case cal_status when 1 then 1 else null end)as CB,
                    count(case cal_status when 2 then 1 else null end)as Pro''
                    +case when @sFin=1 then '',count(case cal_status when 3 then 1 else null end)as Fin'' else '''' end+''
                  from ccoWorkingTable(nolock) group by cam_id)Jobs
                  on Camps.cam_id=Jobs.cam_id Left Join
                  (select cam_id,count(*)as Pend
                      from ccocallsoutsource(nolock)where cal_status=0
                      and cal_fechadial>dateadd(dd,-5,getdate())
                      group by cam_id)Pends
                  On Camps.cam_id=Pends.cam_id
                  Order by cam_procesando desc,cam_descripcion
                end 
                else
                begin
                  select wt.cam_id,cam_descripcion,
                  count(case cal_status when 0 then 1 else null end)as New,
                  count(case cal_status when 1 then 1 else null end)as CB
                  from ccoworkingtable wt(nolock)inner join cccamps c(nolock)
                  on wt.cam_id=c.cam_id and wt.cam_id=''+cast(isnull(@cam_id,0) as varchar(10))+'' group by wt.cam_id,cam_descripcion
                  order by cam_descripcion
                end
              end

              if ''+cast(isnull(@Tipo,0) as varchar(10))+''=1
              begin
                if(''+cast(isnull(@cam_id,0) as varchar(10))+''>0)
                  begin
                  select Camps.cam_id as ID,cam_descripcion as ''''Campaña'''',
                    IsNull(Jobs.New,0)as New,IsNull(Jobs.CB,0)as CB,IsNull(Jobs.Pro,0)as Pro,
                    IsNull(Pends.pend,0)as Pen,''+case when @sFin=1 then ''IsNull(Jobs.Fin,0)as Fin,'' else '''' end+''
                    case cam_procesando when 1 then ''''Pro'''' when 0 then '''''''' end as St,
                    case cam_TipoJobs when 2 then ''''New'''' when 1 then ''''CB''''  when 0 then ''''Amb'''' end as Job
                  from ccCamps Camps(nolock)Left Join 
                  (select cam_id,
                    count(case cal_status when 0 then 1 else null end)as New,
                    count(case cal_status when 1 then 1 else null end)as CB,
                    count(case cal_status when 2 then 1 else null end)as Pro''
                    +case when @sFin=1 then '',count(case cal_status when 3 then 1 else null end)as Fin'' else '''' end+''
                  from ccoWorkingTable(nolock) group by cam_id)Jobs
                  on Camps.cam_id=Jobs.cam_id Left Join
                  (select cam_id,count(*)as Pend
                      from ccocallsoutsource(nolock)where cal_status=0
                      and cal_fechadial>dateadd(dd,-5,getdate())
                      group by cam_id)Pends
                  On Camps.cam_id=Pends.cam_id
                  Where Camps.cam_id=''+cast(isnull(@cam_id,0) as varchar(10))+''
                  Order by cam_procesando desc,cam_descripcion
                end
              end

              if ''+cast(isnull(@Tipo,0) as varchar(10))+''=2
              begin
                if(''+cast(isnull(@user_id,0) as varchar(10))+''>0)
                  begin
                  select distinct Camps.cam_id as ID,cam_descripcion as ''''Campaña'''',
                    IsNull(Jobs.New,0)as New,IsNull(Jobs.CB,0)as CB,IsNull(Jobs.Pro,0)as Pro,
                    isnull(Pends.Pend,0)Pen,''+case when @sFin=1 then ''IsNull(Jobs.Fin,0)as Fin,'' else '''' end+''
                    case cam_procesando when 1 then ''''Pro'''' when 0 then '''''''' end as St,     
                    case cam_TipoJobs when 2 then ''''New'''' when 1 then ''''CB'''' when 0 then ''''Amb'''' end as Job     
                  from ccCamps Camps(nolock)Left Join 
                  ccCampsNvosCB jobs(nolock)on Camps.cam_id=Jobs.id
                  inner join ccSupervisorCam U(nolock)on Camps.cam_id=U.cam_id left Join
                  (select cam_id,count(*)as Pend
                      from ccocallsoutsource(nolock)where cal_status=0
                      and cal_fechadial>dateadd(dd,-5,getdate())
                      group by cam_id)Pends
                  On Camps.cam_id=Pends.cam_id
                  Where U.user_id=''+cast(isnull(@user_id,0) as varchar(10))+'' and tipo=1
                  Order by Camps.cam_id desc,cam_descripcion
                end
              end

              if ''+cast(isnull(@Tipo,0) as varchar(10))+''=3
              begin

                select @ultimo=isnull(cast(valor as datetime),dateadd(hh,-1,getdate())) from ccSettings where setting_id=21
                if datediff(mi,@ultimo,getdate())>=1 begin
                  update ccsettings set valor=convert(varchar(25),getdate(),121)where setting_id=21
                  delete ccCampsNvosCB
                  insert ccCampsNvosCB(ID,Campaña,new,cb,pen,pro,''+case when @sFin=1 then ''fin,'' else '''' end+''st,job)
                  select Camps.cam_id as ID,cam_descripcion as ''''Campaña'''',
                    IsNull(Jobs.New,0)as New,IsNull(Jobs.CB,0)as CB,0 as pen,IsNull(Jobs.Pro,0)as Pro,''+case when @sFin=1 then ''IsNull(Jobs.Fin,0)as Fin,'' else '''' end+''cam_procesando as st,cam_TipoJobs as Job
                    from ccCamps Camps(nolock)Left Join 
                    ( select cam_id,
                      count(case cal_status when 0 then 1 else null end)as New,
                      count(case cal_status when 1 then 1 else null end)as CB,
                      count(case cal_status when 2 then 1 else null end)as Pro''
                      +case when @sFin=1 then '',count(case cal_status when 3 then 1 else null end)as Fin'' else '''' end+''
                      from ccoWorkingTable(nolock)
                      group by cam_id
                    )Jobs on Camps.cam_id=Jobs.cam_id
                end
                select ID,Campaña,St as cam_procesando,Job as cam_tipoJobs,New,CB,Pro''+case when @sFin=1 then '',Fin'' else '''' end+''
                from ccCampsNvosCB (nolock)
                Order by ID
              end''

            exec(@sql)'
        EXEC(@sql)
        ------------------------------------------------------------  END  ---------------------------------------------------------------------


        ------------------------------------------------------------  Jesus Gallardo  ---------------------------------------------------------------------

 set @process = 'CW-7231 Alter SP ccsp_GalateaDnis change  @Tipo = 2'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaDnis]
@User varchar(10),
@Tipo tinyint,
@Dnis varchar(40) = null,
@Inbound_id smallint = null,
@dni_id as smallint = null,
@dnis_ids as varchar(MAX) = null,
@dni_description as varchar(40) = null,
@dni_isBlock as bit = null
as
set nocount on


if @Tipo = 1 -- carga dnis
 begin
    select dni_id, dni_numero as dni_number, dni_descripcion as dni_description, case when dni_id in(select dni_id from ccInboundDnis) then 1 else 0 end dni_isRelated
    from ccDnis where dni_Status=1 order by 2
    return(0)
 end

if @Tipo = 2 -- carga relaciones de dnis
 begin
    declare @UserId int=cast(@user as smallint)
    declare @isSuperUser bit=0

    if @UserId > 0 and exists (
        select * from ccUsers_Roles A
        inner join ccRoles R on A.Rol_id=R.Rol_id and R.Level=7
            where User_id = @UserId
        ) begin
            set @isSuperUser =1
        end

    ;with relationDnis as(
        select a1.Inbound_id, cast(0 as smallint) dni_id, a1.descripcion as description,'''' as dni_number,'''' as dni_description, cast(0 as tinyint) dni_isBlock
        from ccInbound a1
        inner join ccRIAInboundGraph a2 on (a1.Inbound_id = a2.Inbound_id)
        inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
        where a3.type_id = 1 and IDArea is not null 
        and a1.Inbound_id not in (select Inbound_id from ccInboundDnis)
        union
        select ci.inbound_id, cid.dni_id, ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock
        from ccInboundDnis cid 
        inner join ccInbound ci on ci.inbound_id = cid.inbound_id 
        join ccDnis cd on cd.dni_id = cid.dni_id 
        where cd.dni_Status=1
    )

    select * from relationDnis a1
    where @isSuperUser=1 or a1.Inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@UserId, 2))
    order by 3,4

    return(0)
 end

if @Tipo = 3 -- Agrega Dnis
 begin
    if not exists(select dni_numero from ccDnis where dni_Status=1 and dni_numero like @Dnis)
     begin
        insert into ccDnis (dni_id, dni_numero, dni_tpoMaxEspera, tipodni_id, dni_Descripcion, dni_tipo)
        select isNull(max(dni_id), 0) + 1, @Dnis , 0, 1, @dni_description, 2 from ccDnis
        select top(1) dni_id from ccDNIS order by dni_id desc
        return(0)
     end
     
    select cast(-1 as smallint)
 end

if @Tipo = 4 -- Elimina Dnis
 begin
    delete from ccInboundDnis where inbound_id = @Inbound_Id and dni_id = @dni_id
    
    select ci.inbound_id, cd.dni_id, ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock
    from ccInbound ci , ccDNIS cd
    where ci.Inbound_id=@Inbound_id and dni_id=@dni_id
 end

if @Tipo = 5 -- Agrega Relacion
 begin
    insert into ccInboundDnis (Inbound_id, dni_id)
    select @Inbound_Id,B.Value from  dbo.fn_RIASplitDelimited (@dnis_Ids, '','') B
    left join ccInboundDnis A on A.dni_id=B.Value 
    where  A.dni_id is null

    select cast(@Inbound_Id as smallint) inbound_id,cast(B.Value as smallint) dni_id, 
    ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock        
    ,case when cid.Inbound_id is null then 0 else 1 end isAssigned
    from  dbo.fn_RIASplitDelimited (@dnis_Ids, '','') B
    left join ccInboundDnis cid on cid.dni_id=B.Value and cid.Inbound_id=@Inbound_Id
    left join ccInbound ci on ci.inbound_id = @Inbound_Id
    inner join ccDnis cd on cd.dni_id = B.Value
    order by 3,4
 end

if @Tipo = 6 -- Elimina Dnis sin pedir inbound_id
 begin
    if exists(select dni_id from ccInboundDnis where dni_id in (select value from dbo.fn_RIASplitDelimited (@dnis_Ids, '','')) and isnull(inbound_id, 0) <> 0)
        select -1

    else begin
        update ccDNIS set dni_Status=0 where dni_id in (select value from dbo.fn_RIASplitDelimited (@dnis_Ids, '',''))--= @dni_id -- delete from ccdnis where dni_id = @dni_id
        select 1
    end
 end

if @tipo = 7
 begin
    if @Dnis = (select dni_numero from ccDNIS where dni_id=@dni_id) begin
        update ccDnis set 
        dni_Descripcion=isnull(@dni_description,dni_Descripcion)
        where dni_id = @dni_id 
        
        select 1
        return(0)
    end

    if not exists(select dni_numero from ccDnis where dni_Status=1 and dni_numero like @Dnis) begin
        update ccDnis set 
        dni_numero=case when @Dnis <> ''0'' then @Dnis else dni_numero end,
        dni_Descripcion=isnull(@dni_description,dni_Descripcion),
        dni_isBlock = isnull(@dni_isBlock,dni_isBlock)
        where dni_id = @dni_id 

        select 1
        --select dni_id,dni_numero as dni_number, dni_Descripcion as dni_Descriptiondni_id, dni_isBlock from ccDNIS where dni_id=@
        return(0)
    end
    
    select -1
 end

set nocount off'
    EXEC(@sql)

    set @process = 'CW-7276 CREATE TABLE [dbo].[ccAgentMsgFiles]'
    set @sql = 'if not exists(select * from sys.tables where name=''ccAgentMsgFiles'') begin
CREATE TABLE [dbo].[ccAgentMsgFiles](
    [MsgId] [int] primary key identity NOT NULL,
    [MsgFile] [varchar](100) NOT NULL,
    [Description] [varchar](40) NOT NULL,
    [Duration] [smallint] NOT NULL,
    [MsgName] [varchar](40) NOT NULL)
end'
    EXEC(@sql)

    set @process = 'CW-7276 CREATE TABLE [dbo].[ccAgentMsgRelationFiles]'
    set @sql = 'if not exists(select * from sys.tables where name=''ccAgentMsgRelationFiles'') begin
CREATE TABLE [dbo].[ccAgentMsgRelationFiles](
    [MsgId] [int] NOT NULL FOREIGN KEY REFERENCES ccAgentMsgFiles(MsgId),
    [CamId] [int] NOT NULL,
    [CamType] [tinyint] NOT NULL,
    primary key([MsgId],[CamId],[CamType])  
    )       
end'
    EXEC(@sql)

    set @process = 'CW-7276 add ccTipoMsgs '
    set @sql = 'if not exists(select * from ccTipoMsgs where tipomsg_id=16) begin
    insert into ccTipoMsgs values(16,''Message Agent befor xfer'',''Message Agent befor xfer'')
end'
    EXEC(@sql)

    set @process = 'CW-7276 DROP PROCEDURE ccsp_GalateaAgentAutomaticMessages '
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAgentAutomaticMessages'')
    begin
        DROP PROCEDURE ccsp_GalateaAgentAutomaticMessages;
    end'
    EXEC(@sql)

    set @process = 'CW-7276 Create SP ccsp_GalateaAgentAutomaticMessages '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAgentAutomaticMessages] 
    @action as tinyint,
    @msgName as varchar(40) = '''',
    @msgFile as varchar(100) = null,
    @Description as varchar(40) = '''',
    @duration as int = -1,
    @CampType tinyint = 0,
    @msgIdLst varchar(8000) = null,
    @camId int =null,
    @MsgId int = null
AS
BEGIN
    SET NOCOUNT ON
    declare @tableMsgId table(MsgId int not null)
    declare @campName varchar(70)

    if @action in (3,7) begin --Assin/Unassign
        if @CampType=0
            select @campName =descripcion from ccInbound where Inbound_id=@camId
        else
            select @campName =cam_descripcion from ccCamps where cam_id=@camId
    end

    if @action = 1  -- GET_AUDIO_CATALOG
    begin
        select ISNULL(msgName, msgFile) [MsgName], [Description] [MsgDescription], [MsgId] [MsgId] from ccAgentMsgFiles     
        return (0)
    end
    else if @action = 2 --CREATE_NEW_MSG
    begin
        if EXISTS(select msgName from ccAgentMsgFiles where msgName=@msgName)
        begin
            select -1 as result
        end
        else
        begin 
            insert into ccAgentMsgFiles (msgFile, [Description], Duration, msgName) 
            values (@msgFile, @Description, @duration, @msgName)
            select cast(@@identity as int) as result
        end 
    
    end 
    else IF @action = 3 -- Assing
    begin   
        if not exists(select MsgId from ccAgentMsgFiles where MsgId=@MsgId)
        begin
            select ''0'' as result
            return(0)
        end

        if exists(select MsgId from [ccAgentMsgRelationFiles] where CamId=@camId and CamType=@CampType)
        begin
            select ''-1'' as result
            return(0)
        end

        insert into [ccAgentMsgRelationFiles](MsgId,CamId,CamType)    values(@MsgId,@camId,@CampType)

        select @campName

    end
    
    else IF @action = 4 -- GET_CAMP_MESSAGES_RELATION
    begin   
        select MsgId from [ccAgentMsgRelationFiles] where CamId=@camId and CamType=@CampType         
    end
    else IF @action = 5 -- DELETE_AUDIO_MSG
    begin
    
        insert into @tableMsgId
        select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')

        if exists(select A.MsgId from [ccAgentMsgRelationFiles] A 
                  inner join @tableMsgId B on A.MsgId=B.MsgId
        )
        begin
            select 0 as result
            return(0)
        end

         delete A from ccAgentMsgFiles A 
         inner join @tableMsgId B on A.MsgId=B.MsgId
         
         select 1 as result  
         return(0)
    end
        
    else if @action = 6 --EDIT_AUDIO_MSG
    BEGIN    
        update ccAgentMsgFiles set [Description] = isnull(@Description,[Description]), MsgName = isnull(@msgName,MsgName),
        MsgFile = isnull(@msgFile,MsgFile), Duration=case when @duration is null or @duration<=0 then Duration else @duration end
        where MsgId = @MsgId    
    END
    else IF @action = 7 -- UnAssing
    begin       
        if not exists(select MsgId from [ccAgentMsgRelationFiles] where MsgId=@MsgId and CamId=@camId and CamType=@CampType)
        begin
            select ''-1'' as result
            return(0)
        end

        delete from [ccAgentMsgRelationFiles] where MsgId=@MsgId and CamId=@camId and CamType=@CampType 
        select @campName
    end
    
    else IF @action = 8 -- list fileName
    begin               
        insert into @tableMsgId
        select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')
        
        select A.MsgFile from ccAgentMsgFiles A 
                  inner join @tableMsgId B on A.MsgId=B.MsgId
    end
    else IF @action = 9 -- Relation CampIn and MsgFile
    begin               
        select A.CamId,B.MsgFile,B.Duration from [ccAgentMsgRelationFiles] A
        inner join ccAgentMsgFiles B on A.MsgId=B.MsgId
        where CamType=@CampType 

    end
    else IF @action = 10 -- Relation CampIn and MsgFile
    begin
        select MsgId,MsgFile ,Duration from ccAgentMsgFiles where MsgId=@MsgId

    end
    
END
'
    EXEC(@sql)
        ------------------------------------------------------------ End Jesus Gallardo  ---------------------------------------------------------------------
        ------------------------------------------------------------ Start Hugo Longoria ---------------------------------------------------------------------
        SET @process = 'ANIRotative Create/Alter table ccRotativeANIListDetail';
        SET @sql = '
    IF NOT EXISTS (
        SELECT 1
        FROM sys.tables t
        INNER JOIN sys.schemas s 
            ON t.schema_id = s.schema_id
        WHERE s.name = ''dbo''
          AND t.name = ''ccRotativeANIListDetail''
    )
    BEGIN
        CREATE TABLE [dbo].[ccRotativeANIListDetail]
        (
            [id_RAniList] [smallint] NOT NULL,
            [telAni] [varchar](32) NOT NULL,
            [loadDate] [smalldatetime] NOT NULL 
                CONSTRAINT [DF_ccRotativeANIListDetail_loadDate] DEFAULT GETDATE()
        );
    END
    ELSE
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM sys.columns c
            INNER JOIN sys.tables t 
                ON c.object_id = t.object_id
            INNER JOIN sys.schemas s 
                ON t.schema_id = s.schema_id
            WHERE s.name = ''dbo''
              AND t.name = ''ccRotativeANIListDetail''
              AND c.name = ''loadDate''
        )
        BEGIN
            ALTER TABLE [dbo].[ccRotativeANIListDetail]
            ADD [loadDate] [smalldatetime] NOT NULL
                CONSTRAINT [DF_ccRotativeANIListDetail_loadDate] DEFAULT GETDATE()
                WITH VALUES;
        END
    END;
    ';

    EXEC(@sql);
        
        set @process = 'K005012'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
            @command int,
            @calif_id smallint = null,
            @califIdLst varchar(8000) = null,
            @description varchar(60)=null,
            @order tinyint=null,
            @canReprogram bit = null,
            @graphColor varchar(15) = null,
            @endConversation bit=null,
            @keepDial bit=null,
            @autoCB bit=null,
            @contactOwner bit=null,
            @finishPreview bit = 0,
            @allNumbersToBlacklist bit = 0
            AS
            set nocount on
            declare @inserted table (ID smallint)

            if @command=1 -- Load Inbound Dispositions
            begin
              Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner, 
              cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd, graphColor
              from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
              where C.Calif_Status=1
              group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation, graphColor
              order by 2
              return(0)
            end

            If @command=2 -- Load Outbound Dispositions
            begin
              Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,  
              cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner, 
              IsNull(C.finishPreview,0) as finishPreview, graphColor, allNumbersToBlacklist
              from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
              where C.CalifOut_Status=1
              group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
              C.contactOwner, C.finishPreview, graphColor, allNumbersToBlacklist
              order by 2
              return(0)
            end

            If @command=3 -- New ccTipoCalif
            begin
              If exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@description)
                begin
                  select cast(-1 as smallint) [result]  -- Disposition already exists
                  return(0)
                end

              If exists(select calif_id from ccTipoCalif where Calif_Status=0 and description=@description)
              begin
                select top 1 @calif_id = calif_id from ccTipoCalif where Calif_Status=0 and description=@description order by calif_id desc
                update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0), 
                graphColor=isnull(@graphColor, ''1DB4E2''), Calif_Status=1
                output inserted.calif_id into @inserted
                where calif_id=@calif_id
                select ID [result] from @inserted 
                return(0)
              end

              insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , graphColor)
              output inserted.calif_id into @inserted
              select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalif
              select ID [result] from @inserted
              return(0)
            end

            If @command=4 -- New ccTipoCalifOUT
            begin
              If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
              begin
              select cast(-1 as smallint) [result]  -- Disposition already exists
              return(0)
              end

             If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
             begin
                select top 1 @calif_id = calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description order by calif_id desc
                update ccTipoCalifOut set autoTime=0, orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), idTipoLista=0,
                Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), 
                finishPreview=isnull(@finishPreview,0), graphColor=isnull(@graphColor, ''1DB4E2'')
                output inserted.calif_id into @inserted
                where calif_id=@calif_id
                select ID [result] from @inserted 
                return(0)
             end

             insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, graphColor, allNumbersToBlacklist)
             output inserted.calif_id into @inserted
             select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, isnull(@canReprogram,0), isnull(@keepDial,0), 
             isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, ''1DB4E2''), ISNULL(@allNumbersToBlacklist,0) from ccTipoCalifOut
             select ID [result] from @inserted 
             return(0)
            end
            If @command=5 -- Delete Inbound Dispositions
            begin
                delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
                delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
                update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
                return(0)
            end
            if @command=6 -- Delete Outbound Disposition
            begin
                delete from ccCalifCamp where tipo=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
                delete from cctipoSubCalifRel where tipoSubRel=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
                update ccTipoCalifOUT set CalifOut_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
                update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
                return(0)
            end
            if @command=7 -- Update Inbound Disposition
            begin
                if(exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@Description and calif_id<>@calif_id))
                begin
                    select cast(-1 as smallint) [result]    -- Disposition already exists
                    return(0)
                end

                UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
                canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  
                EndConversation=isnull(@endConversation,EndConversation)
                output inserted.calif_id into @inserted
                where calif_id=@calif_id

                delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
                tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

                select ID [result] from @inserted
                return(0)
            end
            if @command=8 -- Update Outbound Disposition
            begin
                if(exists(select calif_id from ccTipoCalifOUT where CalifOut_Status=1 and Description=@description and calif_id<>@calif_id))
                begin
                    select cast(-1 as smallint) [result]    -- Disposition already exists
                    return(0)
                end

                UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
                canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  keepDial=isnull(@keepDial,keepDial), 
                autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner), 
                finishPreview = isnull(@finishPreview,finishPreview), allNumbersToBlacklist = isnull(@allNumbersToBlacklist, allNumbersToBlacklist)
                output inserted.calif_id into @inserted
                where calif_id=@calif_id

                if @keepDial is not null
                begin
                    update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
                end

                select ID [result] from @inserted
                return(0) 
                end

            set nocount off'
        EXEC(@sql)

        set @process = 'add ani to ccologdials'
        set @sql = 'IF COL_LENGTH(''dbo.ccologdials'', ''ani'') IS NULL
            BEGIN
                alter table ccologdials add ani varchar(32) null
            END'
        EXEC(@sql)

        set @process = 'ANI logDials'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRSaveDialResult] 
                    @callout_id INT, @cam_id SMALLINT, @tipoResDial_id TINYINT, @Telefono VARCHAR(30), @Puerto SMALLINT,
                    @tDialing TINYINT= 0, @tBusy SMALLINT= 0, @call_id INT= 0, @answerbit BIT= NULL, @tAnswerBit SMALLINT= 0,
                    @canceledNoAgents BIT= 0, @disconnectCause VARCHAR(250)= '''', @cal_key VARCHAR(40)= '''', @call_TS VARCHAR(15)='''',
                    @ani varchar(32)=''''
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @tNow AS DATETIME, @RecicleSIC TINYINT;
        DECLARE @logDial_id INT;
        DECLARE @tAnswerBitFinal AS DATETIME;
        DECLARE @tTotal SMALLINT;

        SELECT @RecicleSIC = ISNULL(valor, 0)
        FROM ccSettings
        WHERE setting_id = 60;

        SELECT @tTotal = @tDialing + @tAnswerBit;

        SELECT @tNow = GETDATE();

        SELECT @tAnswerBitFinal = DATEADD(ss, -@tAnswerBit, @tNow);

        IF @call_id > 0 AND 
           @tipoResDial_id = 1
        BEGIN
            INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
            TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id, ani )
                   SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
                   ''000000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.
                   fnGetTipoLlamada( @Telefono ), @ani;
        END;
             ELSE
        BEGIN
            INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
            TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id, ani )
                   SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
                   ''000000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(
                   @Telefono ), @ani;
        END;

        SELECT @logDial_id = SCOPE_IDENTITY();

        IF @RecicleSIC = 1
        BEGIN
            UPDATE ccoWorkingTable WITH(ROWLOCK)
              SET tipoResDial_id = @tipoResDial_id
            WHERE callout_id = @callout_id;
        END;

        -- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
        IF @call_id > 0 AND 
           @tipoResDial_id = 1
        BEGIN
            UPDATE ccoCallsOut WITH(ROWLOCK)
              SET cal_puerto = @Puerto, cal_manual = CASE
                                                     WHEN cal_manual = 1 THEN 2
                                                          ELSE cal_manual
                                                     END
            WHERE cal_id = @call_id AND 
                  cal_puerto = 0;

            EXEC ccsp_CstoCalculaCosto @call_id;

            IF @cal_key = ''''
            BEGIN
                SELECT @cal_key = cal_key
                FROM ccoCallsOutSource WITH(NOLOCK)
                WHERE @callout_id = callout_id;

                UPDATE ccologdials WITH(ROWLOCK)
                  SET cal_key = @cal_key
                WHERE logDial_id = @logDial_id;
            END;
        END;


        --2020-06-04 para marcaciones manuales no efectivas guarda el cal_id
                        if @call_id > 0 and @tipoResDial_id != 1
                        begin
                            update ccologdials with(rowlock) set cal_id=@call_id where logDial_id=@logDial_id
                        end

        -- inserta informacion para reportes de workgroup
        INSERT INTO ccRIAWorkGroup_logDial_id( IDWG, logDial_id, cam_id, TIMESTAMP )
               SELECT IDWG, @logDial_id, IdCampEsp, GETDATE()
               FROM ccRIACampEspWG
               WHERE tipo = 1 AND 
                     IdCampEsp = @cam_id;

        -- Guarda configuracion de TipoDialingMode
        UPDATE ccoLogDials WITH(ROWLOCK)
          SET TipoDialingMode = dbo.fn_getDialingMode( @call_id, 0, @logDial_id, @cam_id )
        WHERE logDial_id = @logDial_id;
        SET NOCOUNT OFF;
    END;

        SELECT @logDial_id as LogDialId'
        EXEC(@sql)

        set @process = 'add id_RAniList to ccoworkingtable'
        set @sql = 'IF COL_LENGTH(''dbo.ccoworkingtable'', ''id_RAniList'') IS NULL
            BEGIN
                alter table ccoworkingtable add id_RAniList int null
            END'
        EXEC(@sql)

        set @process = 'add ani_idx to ccoworkingtable'
        set @sql = 'IF COL_LENGTH(''dbo.ccoworkingtable'', ''ani_idx'') IS NULL
            BEGIN
                alter table ccoworkingtable add ani_idx varchar(500) null
            END'
        EXEC(@sql)

        
    set @process = 'ANIRotative Add column rotativeAlgo on ccCamps'
    set @sql = 'IF not exists (SELECT * FROM sys.columns WHERE name = N''rotativeAlgo'' AND Object_ID = Object_ID(N''ccCamps''))
        BEGIN
            alter table ccCamps add rotativeAlgo tinyint null
        END'
    EXEC(@sql)

        set @process = 'DROP VIEW GetNewID'
        set @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(''dbo.GetNewID'') AND type = ''V'')
            BEGIN
                DROP VIEW dbo.GetNewID
            END'
        EXEC(@sql)

        set @process = 'CREATE VIEW GetNewID'
        set @sql = 'CREATE VIEW dbo.GetNewID AS SELECT NewId() AS [NewID]'
        EXEC(@sql)

        

        set @process = 'DROP FUNCTION fnGetRotativeANI'
        set @sql = 'IF EXISTS (SELECT 1 FROM sys.objects 
                       WHERE Name = ''fnGetRotativeANI'' 
                         AND Type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
            BEGIN
                DROP FUNCTION dbo.fnGetRotativeANI
            END'
        EXEC(@sql)

        set @process = 'CREATE FUNCTION fnGetRotativeANI'
        set @sql = 'CREATE FUNCTION [dbo].[fnGetRotativeANI] (@aniListId int, @aniIdx varchar(max), @cld varchar(3) = '''', @serie varchar(4) = '''')
                RETURNS @retANIinfo TABLE 

                (
                    telAni varchar(30) NULL, 
                    idx int NULL
                )
                AS
                BEGIN
                    DECLARE @AniList table (aniIdx varchar(30))
                    DECLARE @ani varchar(30), @idx int

                    INSERT @AniList 
                    SELECT value aniIdx FROM fn_RIASplitDelimited(@aniIdx, '','') WHERE len(value)>0

                    SELECT TOP 1 @ani = telAni, @idx = cast(RowNum as varchar(8))
                    FROM RowRotativeAniListDetail NOLOCK
                    WHERE id_RAniList = @aniListId and RowNum not in (SELECT aniIdx FROM @AniList) 
                        and (len(@cld) = 0 or left(telAni, len(@cld)) = @cld) 
                        and (len(@serie) = 0 or substring(telAni, len(@cld)+1, 6-len(@cld)) != @serie) 
                    ORDER BY (SELECT [NewId] FROM GetNewID)

                    INSERT @retANIinfo
                    SELECT @ani, @idx

                    RETURN
                END'
        EXEC(@sql)

        set @process = 'DROP SP ccsp_DLRGetRotativeANI'
        set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_DLRGetRotativeANI'')
            BEGIN
                DROP PROCEDURE [dbo].[ccsp_DLRGetRotativeANI]
            END'
        EXEC(@sql)

        set @process = 'CREATE SP ccsp_DLRGetRotativeANI'
        set @sql = 'CREATE PROCEDURE [dbo].[ccsp_DLRGetRotativeANI]
                @callout_id int,
                @phones varchar(max),
                @aniList int,
                @algo tinyint
                AS
                set nocount on
                DECLARE @aniIdx varchar(500), @aniCnt smallint, @aniCurList int, @usedAniCnt int, @phoneCnt int, @ani varchar(32), @idx varchar(8)
                DECLARE @Tels table (id int, pid varchar(2), phone varchar(32), ani varchar(32))
                DECLARE @id_phone INT, @phone varchar(32), @usedAni varchar(30)

                SELECT @aniCnt = count(*) FROM ccRotativeAniListDetail NOLOCK WHERE id_RAniList = @aniList          
                SELECT @aniCurList=isnull(id_RAniList,0),@aniIdx=isnull(ani_idx,'''') FROM ccoWorkingTable NOLOCK WHERE callout_id = @callout_id

                IF @aniList != @aniCurList SET @aniIdx = ''''

                IF isnull(@aniCnt,0) > 0
                BEGIN
                    INSERT @Tels 
                    SELECT id,''p''+cast(id as varchar(1)),value,'''' FROM fn_RIASplitDelimited(@phones, '';'') WHERE len(value)>0

                    IF OBJECT_ID(''tempdb..#UsedAniList'') IS NOT NULL DROP TABLE #UsedAniList;
                    SELECT * INTO #UsedAniList FROM fn_RIASplitDelimited(@aniIdx, '','') WHERE len(value)>0
                    SELECT @usedAniCnt=count(*) FROM #UsedAniList

                    IF @algo = 3 and @usedAniCnt > 0 and @usedAniCnt < 2
                    SELECT @usedAni = telAni FROM RowRotativeAniListDetail NOLOCK WHERE id_RAniList = @aniList AND RowNum=(SELECT TOP 1 value from #UsedAniList)

                    DECLARE CUR_TEST CURSOR FAST_FORWARD FOR SELECT Id, phone FROM @Tels ORDER BY Id;
                    OPEN CUR_TEST FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone

                    WHILE @@FETCH_STATUS = 0
                    BEGIN
            
                        IF @usedAniCnt >= @aniCnt SET @aniIdx = ''''

                        IF @algo = 0
                        BEGIN
                            SELECT @ani = dbo.TelAni(@phone,@aniList)
                        END
                        ELSE IF @algo = 1
                        BEGIN
                            SELECT TOP 1 @ani=telAni, @idx=idx FROM fnGetRotativeANI(@aniList, @aniIdx, default, default)
                        END
                        ELSE IF @algo = 2 or @algo = 3
                        BEGIN
                            DECLARE @cld varchar(3), @serie varchar(4), @cldCnt smallint
                            IF len(@phone) < 10
                            BEGIN
                                FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone
                                CONTINUE
                            END
                            IF @algo = 3 and @usedAniCnt > 0 and @usedAniCnt < 2
                            BEGIN
                                IF EXISTS(SELECT TOP 1 1 FROM Series NOLOCK WHERE CLD=left(@usedAni, 2))
                                    SELECT @serie = substring(@usedAni, 3, 4)
                                ELSE
                                    SELECT @serie = substring(@usedAni, 4, 3)
                            END
                            IF @algo = 2 or (@algo = 3 and @usedAniCnt < 2)
                            BEGIN
                                IF EXISTS(SELECT TOP 1 1 FROM Series NOLOCK WHERE CLD=left(@phone, 2))
                                    SET @cld = left(@phone, 2)
                                ELSE
                                    SET @cld = left(@phone, 3)
                            END
                            SELECT @cldCnt = count(*) 
                            FROM ccRotativeAniListDetail NOLOCK 
                            WHERE id_RAniList = @aniList 
                                AND (((@algo = 2 or (@algo = 3 and @usedAniCnt < 2)) and left(telAni, len(@cld))=@cld) or (@algo = 3 and @usedAniCnt >= 2))
                                AND (@algo = 2 OR @usedAni is null OR left(telAni, 6) != left(@usedAni, 6) OR @usedAniCnt >= 2)
                            IF @cldCnt > 0 and @usedAniCnt >= @cldCnt and @algo = 2 SET @aniIdx = ''''
                            SELECT TOP 1 @ani=telAni, @idx=idx 
                            FROM fnGetRotativeANI(@aniList, @aniIdx
                                , case when @cldCnt > 0 and (@algo = 2 or (@algo = 3 and @usedAniCnt < 2)) then @cld else '''' end
                                , case when @algo = 2 then '''' when @usedAniCnt = 1 and @serie is not null then @serie else '''' end)
                        END

                        SELECT @aniIdx = @aniIdx+'',''+@idx, @usedAniCnt = @usedAniCnt+1, @usedAni = @ani

                        UPDATE @Tels SET ani=@ani WHERE id=@id_phone

                        FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone
                    END
                    CLOSE CUR_TEST
                    DEALLOCATE CUR_TEST

                    UPDATE ccoWorkingTable SET id_RAniList=@aniList, ani_idx=isnull(@aniIdx,'''') WHERE callout_id=@callout_id
                END

                SELECT * FROM @Tels

                set nocount off'
        EXEC(@sql)

        set @process = 'ALTER SP ccsp_DLRGetDialInfo'
        set @sql = 'ALTER procedure [dbo].[ccsp_DLRGetDialInfo]
            @callout_id int,
            @cam_id smallint=0,
            @iPortNumber smallint = 0
            AS
            set nocount on
            declare @message_name as varchar(8000), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)    
            declare @prefix as varchar(15)
            declare @prefixCalKey as varchar(30)
            declare @tNoContesta as tinyint
            declare @ani as varchar(32)
            declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint, @rotativeAlgo tinyint
            declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint
            declare @ivr_script smallint, @surveycamid int
            declare @call_record_cam as tinyint
            declare @pais as tinyint 
            declare @sipHdrFormat varchar(255)
            declare @PrefixRec varchar(40)

            set @prefix =''''
            set @tNoContesta = 25
            set @ani=''''
            set @iTipoDial = 0
            set @detectAnswerMachine = 0
            set @detectVoiceMail =1
            set @cam_tnotas = 30
            set @keepDial = 0

            select @pais = valor from ccsettings where setting_id = 104
            select @PrefixRec=ISNULL(prefijo,'''') from ccCamps nolock where cam_id = @cam_id

            -- Mensajes
            select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
            from dbo.fn_ccCamps_SelMessage(@cam_id)

            -- Prefijo por puerto
            select @prefix = prefix from cstoProvedor nolock where provedor_id = (select provedor_id from ccodialers nolock where puerto = @iPortNumber )
            -- Prefijo por campa?a
            if @prefix =''''
                select @prefix = dialPrefix from ccCamps nolock where cam_id = @cam_id
            -- Prefijo general, si es que esta habilitado
            if @prefix ='''' and ((select cast(valor as int) from ccsettings nolock where setting_id =102) & 1 = 1)
                select @prefix = valor from ccsettings nolock where setting_id =101

            select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

            -- Propiedades de campa?a
            select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
            @detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
            @call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0), @rotativeAlgo=isnull(rotativeAlgo,0)
            from ccCamps C (nolock) where C.cam_id=@cam_id

            if @surveycamid > 0
                select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

            --Custom MOH Files
            DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)
            SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
            FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

            --Agrega prefijo Marcacion con directo
            declare @mainPrefix varchar(1), @phones varchar(max)
            set @prefixCalKey=''''
            select @mainPrefix = valor from ccSettings where setting_id=202
            SELECT @prefixCalKey=CASE WHEN @mainPrefix=''1'' THEN isnull(dialPrefix,'''') ELSE '''' END,
                @phones=cal_telefono+'';''+cal_telefono2+'';''+cal_telefono3+'';''+cal_telefono4+'';''+cal_telefono5
            FROM ccoCallsOutSource NOLOCK WHERE callout_id=@callout_id 

            if @iPortNumber >= 0 
            begin
                declare @Anis table(id int, pid varchar(2), phone varchar(32), ani varchar(32))

                insert @Anis
                exec ccsp_DLRGetRotativeANI @callout_id=@callout_id,@phones=@phones,@aniList=@lista_id,@algo=@rotativeAlgo

                SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
    
                SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)+''~''+rtrim(dato5)
                , ISNULL(cpt.Prioridad,''12345NNN'') dial_tels
                , C.cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, isnull(@message_name, '''') as message_name
                , @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
                , case when anis.p1 <> '''' then anis.p1 else @ani end ani
                , case when anis.p2 <> '''' then anis.p2 else @ani end ani2
                , case when anis.p3 <> '''' then anis.p3 else @ani end ani3
                , case when anis.p4 <> '''' then anis.p4 else @ani end ani4
                , case when anis.p5 <> '''' then anis.p5 else @ani end ani5
                , @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail
                , @cam_tnotas cam_tnotas, @keepDial keepDial
                , isnull(@messageDNCL_name, '''') as messageDNCL_name
                ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono) as call_record
                ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono2) as call_record2
                ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono3) as call_record3
                ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono4) as call_record4
                ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono5) as call_record5
                , isnull(@messageDNCLConfirm_name, '''') as messageDNCLConfirm_name
                , isnull(@MohFiles,'''') as mohFiles
                ,@ivr_script ivrScript
                ,@sipheader data
                ,@PrefixRec as Prefijo,
                dbo.GetCarrierByTel(C.cal_telefono) carrier1, 
                dbo.GetCarrierByTel(cal_telefono2) carrier2, 
                dbo.GetCarrierByTel(cal_telefono3) carrier3, 
                dbo.GetCarrierByTel(cal_telefono4) carrier4, 
                dbo.GetCarrierByTel(cal_telefono5) carrier5
                FROM ccoCallsOutSource C with(nolock)
                left join ccoCallPriorityOrder cpo on cpo.callout_id = c.callout_id
                left join ccCampsPrioridadTel cpt on cpt.cam_id = c.cam_id
                left join (SELECT * FROM (SELECT pid,ani FROM @Anis)a PIVOT(MAX(ani) FOR pid IN(p1,p2,p3,p4,p5)) AS pt) anis on 0=0
                WHERE C.callout_id = @callout_id
                return
            end 

            set nocount off'
        EXEC(@sql)

        


        set @process = 'DROP VIEW RowRotativeAniListDetail'
        set @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(''dbo.RowRotativeAniListDetail'') AND type = ''V'')
            BEGIN
                DROP VIEW dbo.RowRotativeAniListDetail
            END'
        EXEC(@sql)

        set @process = 'CREATE VIEW RowRotativeAniListDetail'
        set @sql = 'CREATE VIEW dbo.RowRotativeAniListDetail
                AS
                SELECT 
                Row_Number() OVER (ORDER By id_RAniList) As RowNum
                , * FROM ccRotativeAniListDetail NOLOCK'
        EXEC(@sql)

        ------------------------------------------------------------ End Hugo Longoria ---------------------------------------------------------------------

        ---------------------------------- ANIRotative --------------------------------------------------

        
        set @process = 'ANIRotative Create table ccRotativeANIList'
        set @sql = 'IF (NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = ''dbo'' 
                 AND  TABLE_NAME = ''ccRotativeANIList''))
                BEGIN
                CREATE TABLE [dbo].[ccRotativeANIList](
                    [id_RAniList] [smallint] IDENTITY(1,1) NOT NULL,
                    [description] [varchar](50) NOT NULL,
                    [idArea] [smallint] NOT NULL,
                    CONSTRAINT [PK_ccRotativeANIList] PRIMARY KEY CLUSTERED ( [id_RAniList] ASC ))
                END'
        EXEC(@sql)
        
        
        
        set @process = 'ANIRotative Add Constraint FK_ccRotativeANIListDetail_ccRotativeANIList'
        set @sql = 'IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
            WHERE CONSTRAINT_NAME =''FK_ccRotativeANIListDetail_ccRotativeANIList'')
            BEGIN
                ALTER TABLE [dbo].[ccRotativeANIListDetail] DROP CONSTRAINT FK_ccRotativeANIListDetail_ccRotativeANIList
            END
            ALTER TABLE [dbo].[ccRotativeANIListDetail] WITH CHECK ADD CONSTRAINT [FK_ccRotativeANIListDetail_ccRotativeANIList] 
            FOREIGN KEY([id_RAniList])
            REFERENCES [dbo].[ccRotativeANIList] ([id_RAniList])
            ALTER TABLE [dbo].[ccRotativeANIListDetail] CHECK CONSTRAINT [FK_ccRotativeANIListDetail_ccRotativeANIList]'
        EXEC(@sql)
        
        SET @process = 'ANIRotative Create index for ccRotativeANIListDetail'
        SET @sql = 'IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = ''index_tel'' AND object_id = OBJECT_ID(''ccRotativeANIListDetail''))
        BEGIN
           CREATE INDEX index_tel ON ccRotativeANIListDetail (id_RAniList, telAni);
        END'
        EXEC(@sql)
        
        set @process = 'ANIRotative Create table ccLoadType'
        set @sql = 'if not exists (select * from sys.tables where name = N''ccLoadType'')
            begin
                     create table ccLoadType(
                              loadType_ID smallint primary key not null,
                     description varchar (100),
                     status bit)
            end'
        EXEC(@sql)

        set @process = 'ANIRotative Add data to ccLoadType '
        set @sql = 'if not exists(select loadType_ID from ccLoadType where loadType_ID = 0)
                          begin
                               insert into dbo.ccLoadType(loadType_ID, description, status) values (0, ''Campaign'', 1)
                          end
                     if not exists(select loadType_ID from ccLoadType where loadType_ID = 1)
                          begin
                               insert into dbo.ccLoadType(loadType_ID, description, status) values (1, ''BlackList'', 1)
                          end
                     if not exists(select loadType_ID from ccLoadType where loadType_ID = 2)
                          begin
                               insert into dbo.ccLoadType(loadType_ID, description, status) values (2, ''RotativeANIList'', 1)
                          end'
        EXEC(@sql)

        set @process = 'ANIRotative Add module to ccRIALog_Module'
        set @sql = 'if not exists (select module_id from ccRIALog_Module where module_id = 62)
                        begin
                            insert into dbo.ccRIALog_Module(module_id, descripcion) values (62, ''CARGA DE LISTA ANI ROTATIVA | ROTATIVE ANI LIST UPLOAD'')
                        end'
        EXEC(@sql)

		set @process = 'ccRiaLoading add UserID column if not exist '
        set @sql = 'IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N''UserID''
          AND Object_ID = Object_ID(N''ccRIALoading''))
BEGIN
   ALTER TABLE ccRiaLoading
   ADD UserID smallint
END'
        EXEC(@sql)
        
        set @process = 'ANIRotative Drop procedure ccsp_GalateaAdminRotativeANI'
        set @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''P'' AND name = ''ccsp_GalateaAdminRotativeANI'') begin
                        DROP PROCEDURE ccsp_GalateaAdminRotativeANI
                    end'
        EXEC(@sql)
        
        set @process = 'ANIRotative Create procedure ccsp_GalateaAdminRotativeANI'
        set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminRotativeANI]
    @type SMALLINT,
    @idArea SMALLINT = NULL,
    @descriptionList VARCHAR(50) = NULL,
    @id_RAniList SMALLINT = NULL,
    @PageIndex      INT = 0,
    @PageSize       INT = 0,
	@UserId			SMALLINT = 0

AS
BEGIN
    SET NOCOUNT ON;

    IF (@type = 1) -- Read Rotative ANI List Catalog
    BEGIN
        SELECT cral.id_RAniList,
               cral.description,
               cral.idArea
        FROM dbo.ccRotativeANIList AS cral
        WHERE cral.idArea IN (@idArea,-1) 
        AND cral.id_RAniList = ISNULL(@id_RAniList, cral.id_RAniList);
        RETURN 0;
    END;
    IF (@type = 2)
    BEGIN
        SELECT * 
        FROM
            (SELECT ROW_NUMBER() OVER(ORDER BY loadDate ASC) AS RowNum,
                id_RAniList,
                telAni,
                loadDate
            FROM dbo.ccRotativeANIListDetail
            WHERE id_RAniList = @id_RAniList) tmp
        WHERE  tmp.RowNum > @PageSize * (@PageIndex - 1)
        AND tmp.RowNum <= @PageSize * @PageIndex
        RETURN 0;
    END;
    If @type=3 --Create Rotative ANI List
    begin
        declare @newANILstId SMALLINT = -1 --Name in use

        if not exists(select id_RAniList from ccRotativeANIList where description = @descriptionList)
        begin
            insert into ccRotativeANIList (description,idArea) values(@descriptionList, @idArea)
            select @newANILstId = SCOPE_IDENTITY() 
        end

        select @newANILstId as [result]
        return(0)
    end
    If @type=4 --Update Rotative ANI List
    begin
        declare @idAreaOfExistingLst smallint

        select @idAreaOfExistingLst = idArea from ccRotativeANIList where id_RAniList = @id_RAniList
        if(@idAreaOfExistingLst = -1 and @idArea <> @idAreaOfExistingLst)   --Changing from global to particular idArea
        begin
            if exists(select cam_id from ccCamps where IDArea <> @idArea and id_anilist = @id_RAniList and ISNULL(rotativeAlgo, 0) > 0)
            begin
                select -2 as [result] --Cant change idArea cause the ANI list is related to camps on other IDArea
                return(0)
            end
        end

        if exists(select id_RAniList from ccRotativeANIList where [description] = @descriptionList and id_RAniList <> @id_RAniList)
        begin
            SELECT -1 as [result] --Name in use
            return(0)
        end
        
        update ccRotativeANIList set [description] = @descriptionList, idArea = @idArea where id_RAniList = @id_RAniList
        SELECT 1 as [result]
        return(0)
    end
    If @type=5 --Delete Rotative ANI List
    begin
        declare @result int = -2   --ANI list is related to campaign

        if not exists(select cam_id from ccCamps where id_anilist = @id_RAniList and ISNULL(rotativeAlgo, 0) > 0)
        begin
            delete ccRotativeANIListDetail where id_RAniList = @id_RAniList
            delete ccRotativeANIList where id_RAniList = @id_RAniList
            select @result = 1
        end

        select @result as [result]
        return(0)
    END
    IF (@type = 6) -- Read Rotative ANI List By Id
    BEGIN
        SELECT cral.id_RAniList,
               cral.description,
               cral.idArea
        FROM dbo.ccRotativeANIList AS cral
        WHERE cral.id_RAniList = @id_RAniList
        RETURN 0;
    END

    IF (@type = 7) -- Get List size
    BEGIN
        SELECT COUNT(*) AS listSize FROM dbo.ccRotativeANIListDetail WHERE id_RAniList = @id_RAniList
        RETURN 0;
    END
    IF(@type = 8) --Check if exist an other process executing
    BEGIN 
        SELECT CASE WHEN COUNT(crl.load_id) > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS isProcessExecuting FROM dbo.ccRIALoading AS crl
        WHERE crl.cam_id = @id_RAniList AND crl.state IN (0,2) AND crl.loadType = 2;
        RETURN (0);
    END
    IF(@type = 9) --Check if exist a campaign executing
    BEGIN
        SELECT CASE WHEN COUNT(cc.cam_id) > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS isCampaignExecuting   FROM dbo.ccCamps AS cc
        WHERE cc.id_anilist = @id_RAniList AND cc.rotativeAlgo IN (1,2,3)
        AND cc.cam_procesando = 1
        RETURN 0;
    END
	IF(@type = 10) --Update current Rotative ANI List loads to error
	BEGIN
		IF(@UserId = 0)
		BEGIN
			UPDATE ccRIALoading SET [state] = 4 WHERE loadType = 2 AND [state] < 3
		END
		UPDATE ccRIALoading SET [state] = 4
		WHERE loadType = 2 AND [state] < 3 AND userID = @UserId 
		SELECT CASE WHEN @@ROWCOUNT > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS LoadError
		RETURN 0;
	END

SET NOCOUNT OFF

END'
        EXEC(@sql)
        
        set @process = 'ANIRotative Drop procedure ccsp_GalateaAdminRotativeANIImportStatus '
        set @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''P'' AND name = ''ccsp_GalateaAdminRotativeANIImportStatus'') begin
DROP PROCEDURE ccsp_GalateaAdminRotativeANIImportStatus
end'
        EXEC(@sql)
        
        set @process = 'ANIRotative Create procedure ccsp_GalateaAdminRotativeANIImportStatus'
        set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminRotativeANIImportStatus]
@command int,
@loadID int = NULL
AS

SET nocount ON

declare @today datetime
select @today = convert(datetime, convert(varchar(10), getdate(), 121), 121)

If @command = 1
BEGIN
    select distinct load_id [LoadId], camName [RotANILst], pctg [ProgressPercentage], regsNotLoaded+regsBlocked [RecordsNotLoaded], 
    regsLoaded [RecordsLoaded], [state] [LoadState], loadDate [LoadDate]
    from ccRIALoading
    where loadDate >= @today and loadType = 2
    order by loadDate desc
    return (0)
END
If @command = 2
BEGIN
    select distinct load_id [LoadId], camName [RotANILst], pctg [ProgressPercentage], regsNotLoaded+regsBlocked [RecordsNotLoaded], 
    regsLoaded [RecordsLoaded], [state] [LoadState], loadDate [LoadDate]
    from ccRIALoading
    where load_id  = @loadID
    return (0)
END

SET nocount OFF'
        EXEC(@sql)
        
        SET @process = 'ANIRotative Drop procedure ccsp_GalateaAdminRotANICreateTempTable'
        SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''P'' AND name = ''ccsp_GalateaAdminRotANICreateTempTable'')
        BEGIN
            DROP PROCEDURE ccsp_GalateaAdminRotANICreateTempTable
        END'
        EXEC(@sql)
        
        SET @process = 'ANIRotative Create procedure ccsp_GalateaAdminRotANICreateTempTable'
        SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminRotANICreateTempTable] 
        @TableName VARCHAR(50) = NULL
        AS
        BEGIN
            IF @TableName IS NOT NULL AND @TableName != ''''
                BEGIN

					DECLARE @query VARCHAR(max)
					SET @query= ''if not exists(select * from sys.tables where name=''''''+ @TableName +'''''')''
								+ ''create table '' + @TableName + '' (Phone varchar(32))''
					exec(@query)
					SELECT 1 AS [result]
					return(0)
				END
			ELSE
				BEGIN
					SELECT -1 AS [result]
					return(0)
				END
		END'
		EXEC(@sql)

        SET @process = 'ANIRotative Drop procedure ccsp_GalateaAdminRotANIDeleteFromTemp'
        SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''P'' AND name = ''ccsp_GalateaAdminRotANIDeleteFromTemp'')
        BEGIN
            DROP PROCEDURE ccsp_GalateaAdminRotANIDeleteFromTemp
        END'
        EXEC(@sql)
        
        SET @process = 'ANIRotative Create procedure ccsp_GalateaAdminRotANIDeleteFromTemp'
        SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminRotANIDeleteFromTemp] 
        @TableName VARCHAR(50) = NULL,
        @id_RAniList smallint = -1
        AS
        BEGIN
            IF @TableName IS NOT NULL AND @TableName != '''' AND @id_RAniList != -1
                BEGIN

                    DECLARE @query VARCHAR(max)
                    SET @query= ''if exists(select * from sys.tables where name=''''''+ @TableName +'''''')
                                DELETE details FROM ccRotativeANIListDetail details
                                INNER JOIN ''  + @TableName + '' tmp ON details.telAni = tmp.Phone 
                                WHERE details.id_RAniList =  '' + CAST(@id_RAniList as varchar(max))
                    exec(@query)
                    SELECT @@ROWCOUNT AS [result]
                    return(0)
                END
            ELSE
                BEGIN
                    SELECT -1 AS [result]
                    return(0)
                END
        END'
        EXEC(@sql)

        SET @process = 'ANIRotative Drop procedure ccsp_ANIListDetails'
        SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''P'' AND name = ''ccsp_ANIListDetails'')
        BEGIN
            DROP PROCEDURE ccsp_ANIListDetails
        END'
        EXEC(@sql)
        
        SET @process = 'ANIRotative Create procedure ccsp_ANIListDetails'
        SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_ANIListDetails] @phoneNumber AS VARCHAR(30), @id_RotativeANI AS INTEGER, @tipoMov AS TINYINT
        AS
        DECLARE @Phone BIGINT

        IF @tipoMov = 1
        BEGIN -- Inserta ANI LIST   
            INSERT ccRotativeANIListDetail(id_RAniList, telAni) VALUES(@id_RotativeANI, @phoneNumber)
        END

        IF @tipoMov = 2
        BEGIN -- Borra datos de ANI LIST    
            SELECT @Phone = dbo.hashPhone(@phoneNumber)

            DELETE FROM ccRotativeANIListDetail
            WHERE telAni = @Phone AND id_RAniList = @id_RotativeANI
        END

        IF @tipoMov = 3
        BEGIN -- Reemplaza ANI LIST
            DELETE
            FROM ccRotativeANIListDetail
            WHERE id_RAniList = @id_RotativeANI
        END'
        EXEC(@sql)
        
        set @process = 'ANIRotative Alter procedure ccsp_GalateaGetBlacklistImportStatus'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetBlacklistImportStatus]
@action tinyint,
@loadID int = NULL

AS
declare @today datetime
select @today =convert(datetime, convert(varchar(11),getdate(),121),121)

SET nocount ON
if @action not IN (1,2)
    BEGIN
        raiserror(''ERROR. No se ingreso parametro de entrada'', 18, 1)
        return (0)
    END

if @action=1 -- Detalle general de carga de registros a listas Negras
BEGIN
     SELECT DISTINCT load_id as LoadId, camName as BlacklistName, cam_id as BlacklistId, pctg as ProgressPercentage , regsNotLoaded+regsBlocked as PhonesNotLoaded,
        regsLoaded as PhonesLoaded, state as LoadState, loadDate as StartLoadDate
        FROM ccRIALoading riaLoad
        WHERE 
        loadDate>=@today and loadType = 1
        ORDER BY riaLoad.loadDate DESC
END

if @action=2 -- obtiene datos especificos de una carga a listas Negras a partir del id de carga
BEGIN
     SELECT DISTINCT load_id as LoadId, camName as BlacklistName, cam_id as BlacklistId, pctg as ProgressPercentage , regsNotLoaded+regsBlocked as PhonesNotLoaded,
        regsLoaded as PhonesLoaded, state as LoadState, loadDate as StartLoadDate
        FROM ccRIALoading riaLoad
        WHERE 
        load_id=@loadID
END'
        EXEC(@sql)
        
        set @process = 'ANIRotative Alter procedure ccsp_GalateaGetRecordsImportStatus'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetRecordsImportStatus]
-- @Type = 1:Detalle general de carga de registros | 2:Detalle específico de carga de registros | 3:Porcentaje de carga de registros
@action tinyint, 
@loadID int = NULL, 
@userID smallint = NULL

AS
declare @today datetime
select @today =convert(datetime, convert(varchar(11),getdate(),121),121)
SET nocount ON
if @action not IN (1,2,3)
raiserror(''ERROR. No se ingreso parametro de entrada'', 18, 1)

if @action=1 -- Detalle general de carga de registros
BEGIN
if not exists(SELECT User_id FROM ccUsers WHERE TipoUser_id IN(2,6) AND Status>0 AND User_id=@userID)
 BEGIN
  raiserror(''ERROR. invalid user id'', 18, 1)
  return(0)
 END

if exists (select * from ccUsers_Roles where User_id = @userID and Rol_id = (select Rol_id from ccRoles where Level = 7))
    BEGIN
        SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked as regsNotLoaded, state, loadDate
        FROM ccRIALoading riaLoad
        JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
        WHERE 
        loadDate>=@today and loadType = 0
        ORDER BY riaLoad.loadDate DESC
    END
else
    BEGIN
        SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked as regsNotLoaded, state, loadDate
        FROM ccRIALoading riaLoad
        JOIN ccSupervisorCam superCam ON riaLoad.cam_id = superCam.cam_id
        JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
        WHERE 
        loadDate>=@today AND
        superCam.user_id = @userID
        AND superCam.tipo = 1
        ORDER BY riaLoad.loadDate DESC
    END

return(0)
END

if @action=2 -- Detalle específico de carga de registros
BEGIN
if not exists(SELECT load_id FROM ccRIALoading)
 BEGIN
  raiserror(''ERROR. invalid template ID'', 18, 1)
  return(0)
 END

  SELECT regsLoaded, alreadyLoaded, regsBlocked, regsNotLoaded,
         telsLoaded, telsBlocked, telsNotLoaded
  FROM ccRIALoading
  WHERE load_id  = @loadID

END

if @action=3 -- Porcentaje de carga de registros
BEGIN
if not exists(SELECT load_id FROM ccRIALoading)
 BEGIN
  raiserror(''ERROR. invalid load ID'', 18, 1)
  return(0)
 END

  SELECT state, pctg
  FROM ccRIALoading
  WHERE load_id  = @loadID

END
SET nocount off'
        EXEC(@sql)
        
        set @process = 'ANIRotative Alter procedure ccsp_GalateaGetOutboundConfiguration'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]
@adminID int,
@campID int
AS
BEGIN

    declare @AllCampaigns table 
    (cam_id smallint, cam_Descripcion varchar(40), cam_tNotas smallint, cam_ocupado smallint,cam_noInt_ocupado smallint, cam_inter_ocupado smallint,
    cam_nocontesto smallint, cam_noInt_nocontesto smallint, cam_inter_nocontesto smallint, cam_fax smallint, cam_noInt_fax smallint, cam_inter_fax smallint,
    cam_modomanual smallint, ANI varchar(15), cam_ShowCalifWnd bit, cam_StartTimerOnHangUp bit, editableCallKey bit, cam_tNoContesta smallint, iTipoDial smallint,
    detectAnswerMachine smallint,detectVoiceMail smallint, compliance smallint, cam_inter_graba smallint, cam_noint_graba smallint, progDial smallint, excCallBack smallint, dialOrder smallint,
    dialPrefix varchar(10),dialPrefixMan varchar(10), dialPrefixXfe varchar(10),listenManualCall bit,  stopRecording bit,abandonCallback bit, frame smallint,
    t_autoCB smallint, id_anilist int, tDialonWrapUp smallint, viewMode tinyint, queSize smallint, DNCScrub int, callerIdDesc varchar (15), timeZoneRule int,
    callsBySurvey int, ivrScript int, surveyPctg int,call_record smallint,startStopRecording bit,  leaveRecMessage  bit, manualCallOnChat bit, 
    callBackSurveyAgent bit, callBackSurveyClient bit, isRelationSurvey bit, funcEspDtmf int,  sipHdrFormat varchar(255), cam_inter_cancelled smallint, 
    prefijo varchar(40),enbleprefix bit,exitAssisted bit,previewDiscard bit, rotativeAlgo tinyint )
     
        INSERT INTO @AllCampaigns EXEC ccsp_RIAConfCamp @adminID, @campID

        SELECT dialPrefixMan DialPrefixMan, dialPrefixXfe DialPrefixXfe, listenManualCall  ListenManualCall, stopRecording StopRecording, abandonCallback AbandonCallBack,
        t_autoCB AutoCB,id_anilist IdIstANI,tDialonWrapUp TDialOnWrapup, queSize Quesize, DNCScrub, callerIdDesc CallerIdDesc, timeZoneRule TimeZoneRule,callsBySurvey CallsBySurvey,
        ivrScript IvrScript, surveyPctg SurveyPctg, call_record CallRecord,startStopRecording StartStopRecording, leaveRecMessage LeaveRecMessage,manualCallOnChat ManualCallOnChat,
        callBackSurveyClient CallBackSurveyClient, callBackSurveyAgent CallBackSurveyAgent, funcEspDtmf FuncEspDtmf,sipHdrFormat SipHdrsCfg, dialPrefix DialPrefix,
        prefijo Prefix, dialOrder DialOrder, progDial ProgDial, cam_Descripcion CamDescription, cam_tNotas CamTnotas, cam_ocupado CamBusy, cam_noInt_ocupado CamNoIntBusy,
        cam_inter_ocupado CamInterBusy,cam_nocontesto CamNoAnswer, cam_noInt_nocontesto CamNoIntNoAnswer,cam_inter_nocontesto CamInterNoAnswer, (cam_inter_cancelled/60) CamInterCancelled,
        cam_fax CamFax, cam_noInt_fax CamNoIntFax,cam_inter_fax CamInterFax, cam_modomanual CamModoManual,ANI ,cam_StartTimerOnHangUp CamStartTimerOnHangUp,
        editableCallKey EditableCallKey, cam_tNoContesta CamTNoAnswer, iTipoDial  CamIntensiveDialing, detectAnswerMachine DetectAnswerMachine, detectVoiceMail DetectVoiceMail, 
        compliance Compliance, cam_inter_graba CamInterRecord,cam_noint_graba CamNoIntRecord,excCallBack ExcCallBack, cam_ShowCalifWnd CamShowCalifWnd, frame Frame, exitAssisted ExitAssistedDialMode, 
        previewDiscard PreviewDiscard, rotativeAlgo RotativeAlgo
        from @AllCampaigns WHERE cam_id = @campID
END'
        EXEC(@sql)
        
        set @process = 'ANIRotative Alter procedure ccsp_RIAConfCamp'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
@User_id smallint,
@campID int =null
AS
set nocount on
declare @tableExistsRec table (camId int primary key,existRec bit)
declare @camByUser table (camId int primary key,isCheck bit)
declare @camId int,@id int;

IF Not EXISTS
    (
        SELECT *
        FROM ccUsers_Roles
        WHERE User_id = @User_id
                AND Rol_id = 7
    )begin
    insert into @camByUser 
    select *,0 from dbo.fGet_CampAcd_Area (@User_id, 1) B 
    where @campID is null or cam_id=@campID
end
else begin
    insert into @camByUser 
    select cam_id,0 from ccCamps 
    where (IDArea>0 or IDArea is null)
    and (@campID is null or cam_id=@campID)
end


while exists(select * from @camByUser where isCheck=0)
begin
    select top 1 @camId=camId  from @camByUser where isCheck=0 
    if exists(select cam_id from ccoCallsOut where cam_id=@camId) begin
        insert into @tableExistsRec values(@camId,1)
    end
    else begin
        insert into @tableExistsRec values(@camId,0)
    end

    update  @camByUser  set isCheck=1 where camId=@camId
end

select a1.cam_id, cam_Descripcion
, cam_tNotas, cast(cam_ocupado as int) as cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto as int) as cam_nocontesto
, cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax as int) as cam_fax, cam_noInt_fax, cam_inter_fax
, cast(cam_modomanual as int) as cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial
, detectAnswerMachine, detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial as tinyint)progDial
, cast(excCallBack as tinyint)excCallBack, dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall
, stopRecording, cast(abandonCallback as tinyint)abandonCallback, a3.frame, a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, 
cam_maxqueue as queSize,
DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record,1) as call_record
    ,cast (startStopRecording as tinyint)startStopRecording, leaveRecMessage, manualCallOnChat
,callBackSurveyAgent,callBackSurveyClient,case when surveycamid is null or surveycamid = 0 then 0 else 1 end isRelationSurvey,isnull(a1.funcEspDtmf,0)
,isnull(sipHdrFormat, '''') sipHdrFormat
,cam_inter_cancelled
,prefijo,   enbleprefix = case when existRec = 0 then 1 else 0 end,
isnull(exitAssisted, 0) exitAssisted, isnull(previewDiscard, 0) PreviewDiscard, isnull(rotativeAlgo, 0 ) rotativeAlgo
from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
inner join @tableExistsRec a4 on a1.cam_id=a4.camId
--where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
order by cam_descripcion
return(0)
set nocount off'
        EXEC(@sql)
        
        set @process = 'ANIRotative Alter procedure ccsp_RIAUpdateCamConfig'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
                @cam_id smallint,
                @cam_descripcion varchar(40) = null,
                @cam_tnotas smallint = null,
                @cam_ocupado tinyint = null,
                @cam_NoInt_ocupado tinyint = null,
                @cam_inter_ocupado smallint = null,
                @cam_nocontesto tinyint = null,
                @cam_NoInt_nocontesto tinyint = null,
                @cam_inter_nocontesto smallint = null,
                @cam_fax tinyint = null,
                @cam_NoInt_fax tinyint = null,
                @cam_inter_fax smallint = null,
                @cam_ModoManual tinyint= null,
                @ANI varchar(15) = null,
                @cam_ShowCalifWnd bit = null,
                @cam_StartTimerOnHangUp bit = null,
                @editableCallKey bit = null,
                @cam_tNoContesta tinyint = null,
                @cam_intensive_dialing tinyint = null,
                @detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
                @detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
                @compliance TinyInt = null,
                @cam_inter_graba smallint = null,
                @cam_NoInt_graba tinyint = null,
                @progDial smallint = null,
                @excCallBack Tinyint = null,
                @dialOrder Tinyint = null,
                @dialPrefix varchar(10) = null,
                @dialPrefixMan varchar(10) = null,
                @dialPrefixXfe varchar(10) = null,
                @listenManualCall bit = null,
                @stopRecording bit = null,
                @abandonCallback bit = null,
                @autoCB smallint = null,
                @id_listAni int = null,
                @tDialonWrapUp smallint = null,
                @quesize smallint=null,
                @DNCScrub int=null,
                @callerIdDesc varchar(15)=null,
                @timeZoneRule int=null,
                @callsBySurvey int=null,
                @ivrScript int=null,
                @surveyPctg int=null,
                @call_record tinyint=null,
                @dRestrictPlay bit = null,
                @leaveRecMessage bit = null,
                @manualCallOnChat bit = null,
                @callBackSurveyClient bit = null,
                @callBackSurveyAgent bit = null,
                @funcEspDtmf int =null,
                @sipHdrsCfg varchar(255) = null,
                @cam_inter_cancelled smallint = null,
                @prefijo varchar(max) = null,
                @exitAssisted bit = null,
                @previewDiscard bit = null,
                @rotativeAlgo tinyint = null
                as
                set nocount on
                UPDATE ccCamps SET
                 cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
                 cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
                 cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
                 cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
                 cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
                 cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
                 cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
                 cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
                 cam_inter_cancelled = isnull(@cam_inter_cancelled,cam_inter_cancelled),
                 cam_fax = isnull(@cam_fax,cam_fax),
                 cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
                 cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
                 cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
                 ANI = isnull(@ANI,ANI),
                 cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
                 editableCallKey = isnull(@editableCallKey, editableCallKey),
                 cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
                 iTipoDial = isnull(@cam_intensive_dialing, iTipoDial),
                 detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine),
                 detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
                 compliance = isnull(@compliance, compliance),
                 cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
                 cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
                 cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
                 progDial = isnull(@progDial, progDial),
                 excCallBack = isnull(@excCallBack,excCallBack),
                 dialOrder = isnull(@dialOrder, dialOrder),
                 dialPrefix = isnull(@dialPrefix, dialPrefix),
                 dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
                 dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
                 listenManualCall = isnull(@listenManualCall, listenManualCall),
                 stopRecording = isnull(@stopRecording, stopRecording),
                 abandonCallback = isnull(@abandonCallback, abandonCallback),
                 t_autoCB = isnull(@autoCB,t_autoCB),
                 id_anilist = isnull(@id_listAni,id_anilist),
                 tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
                 cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
                 cam_maxqueue = isnull(@quesize,cam_maxqueue),
                 DNCScrub = isnull(@DNCScrub,DNCScrub),
                 callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
                 timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
                 callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
                 ivrScript = isnull(@ivrScript,ivrScript),
                 surveyPctg = isnull(@surveyPctg,surveyPctg),
                 call_record = isnull(@call_record,call_record),
                 startStopRecording = isnull(@dRestrictPlay, startStopRecording),
                 leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
                 manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
                 callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
                 callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
                 funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf ),
                 sipHdrFormat = isnull(@sipHdrsCfg, sipHdrFormat),
                 prefijo = isnull(@prefijo, prefijo),
                 exitAssisted = isnull(@exitAssisted, exitAssisted),
                 previewDiscard = isnull(@previewDiscard, previewDiscard),
                 rotativeAlgo = isnull(@rotativeAlgo, rotativeAlgo)
                Where cam_id = @cam_id

                if @cam_ShowCalifWnd = 1
                 begin
                 If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1)
                  begin
                  select 0
                  return(0)
                  end

                 UPDATE ccCamps SET cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd, cam_ShowCalifWnd)
                 where cam_id = @cam_id
                 select 1
                 return(0)
                  end

                --else
                UPDATE ccCamps SET
                cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
                where cam_id = @cam_id
                select 2
                return(0)
                set nocount off'
        EXEC(@sql)
        ------------------------------------------------------------  END  ANIRotative ---------------------------------------------------------------------

  ------------------------------------------------------------  KR011000 Notificación recepción de llamada de entrada ---------------------------------------------------------------------

set @process = 'CW-7276 KR011000 CREATE TABLE ccAgentMsgFiles'
set @sql = 'if not exists(select * from sys.tables where name=''ccAgentMsgFiles'') begin
CREATE TABLE [dbo].[ccAgentMsgFiles](
        [MsgId] [int] primary key identity NOT NULL,
        [MsgFile] [varchar](100) NOT NULL,
        [Description] [varchar](40) NOT NULL,
        [Duration] [smallint] NOT NULL,
        [MsgName] [varchar](40) NOT NULL)
end'
EXEC(@sql)

set @process = 'CW-7276 KR011000 CREATE TABLE ccAgentMsgRelationFiles'
set @sql = 'if not exists(select * from sys.tables where name=''ccAgentMsgRelationFiles'') begin
CREATE TABLE [dbo].[ccAgentMsgRelationFiles](
        [MsgId] [int] NOT NULL FOREIGN KEY REFERENCES ccAgentMsgFiles(MsgId),
        [CamId] [int] NOT NULL,
        [CamType] [tinyint] NOT NULL,
        primary key([MsgId],[CamId],[CamType])  
        )               
end'
EXEC(@sql)

set @process = 'CW-7276 KR011000 Add ccTipoMsgs 16'
set @sql = 'if not exists(select * from ccTipoMsgs where tipomsg_id=16) begin
        insert into ccTipoMsgs values(16,''Message Agent befor xfer'',''Message Agent befor xfer'')
end'
EXEC(@sql)

set @process = 'CW-7276 KR011000 CREATE PROCEDURE ccsp_GalateaAgentAutomaticMessages'
set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAgentAutomaticMessages'')
    begin
        DROP PROCEDURE ccsp_GalateaAgentAutomaticMessages;
    end'
EXEC(@sql)

set @process = 'CW-7276 KR011000 CREATE PROCEDURE ccsp_GalateaAgentAutomaticMessages'
set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAgentAutomaticMessages] 
        @action as tinyint,
        @msgName as varchar(40) = '''',
        @msgFile as varchar(100) = null,
        @Description as varchar(40) = '''',
        @duration as int = -1,
        @CampType tinyint = 0,
        @msgIdLst varchar(8000) = null,
        @camId int =null,
        @MsgId int = null
AS
BEGIN
        SET NOCOUNT ON
        declare @tableMsgId table(MsgId int not null)
        declare @campName varchar(70)

        if @action in (3,7) begin --Assin/Unassign
                if @CampType=0
                        select @campName =descripcion from ccInbound where Inbound_id=@camId
                else
                        select @campName =cam_descripcion from ccCamps where cam_id=@camId
        end

        if @action = 1  -- GET_AUDIO_CATALOG
        begin
                select ISNULL(msgName, msgFile) [MsgName], [Description] [MsgDescription], [MsgId] [MsgId] from ccAgentMsgFiles         
                return (0)
        end
        else if @action = 2 --CREATE_NEW_MSG
        begin
                if EXISTS(select msgName from ccAgentMsgFiles where msgName=@msgName)
                begin
                        select -1 as result
                end
                else
                begin 
                        insert into ccAgentMsgFiles (msgFile, [Description], Duration, msgName) 
                        values (@msgFile, @Description, @duration, @msgName)
                        select cast(@@identity as int) as result
                end 
    
        end 
        else IF @action = 3 -- Assing
        begin   
                if not exists(select MsgId from ccAgentMsgFiles where MsgId=@MsgId)
                begin
                        select ''0'' as result
                        return(0)
                end

                if exists(select MsgId from [ccAgentMsgRelationFiles] where CamId=@camId and CamType=@CampType)
                begin
                        select ''-1'' as result
                        return(0)
                end

                insert into [ccAgentMsgRelationFiles](MsgId,CamId,CamType)    values(@MsgId,@camId,@CampType)

                select @campName

        end
        
        else IF @action = 4 -- GET_CAMP_MESSAGES_RELATION
        begin   
                select MsgId from [ccAgentMsgRelationFiles] where CamId=@camId and CamType=@CampType             
        end
        else IF @action = 5 -- DELETE_AUDIO_MSG
        begin
        
                insert into @tableMsgId
                select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')

                if exists(select A.MsgId from [ccAgentMsgRelationFiles] A 
                                  inner join @tableMsgId B on A.MsgId=B.MsgId
                )
                begin
                        select 0 as result
                        return(0)
                end

                 delete A from ccAgentMsgFiles A 
                 inner join @tableMsgId B on A.MsgId=B.MsgId
                 
                 select 1 as result  
                 return(0)
        end
                
        else if @action = 6 --EDIT_AUDIO_MSG
        BEGIN    
                update ccAgentMsgFiles set [Description] = isnull(@Description,[Description]), MsgName = isnull(@msgName,MsgName),
                MsgFile = isnull(@msgFile,MsgFile), Duration=case when @duration is null or @duration<=0 then Duration else @duration end
                where MsgId = @MsgId    
        END
        else IF @action = 7 -- UnAssing
        begin           
                if not exists(select MsgId from [ccAgentMsgRelationFiles] where MsgId=@MsgId and CamId=@camId and CamType=@CampType)
                begin
                        select ''-1'' as result
                        return(0)
                end

                delete from [ccAgentMsgRelationFiles] where MsgId=@MsgId and CamId=@camId and CamType=@CampType 
                select @campName
        end
        
        else IF @action = 8 -- list fileName
        begin                           
                insert into @tableMsgId
                select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')
                
                select A.MsgFile from ccAgentMsgFiles A 
                                  inner join @tableMsgId B on A.MsgId=B.MsgId
        end
        else IF @action = 9 -- Relation CampIn and MsgFile
        begin                           
                select A.CamId,B.MsgFile,B.Duration from [ccAgentMsgRelationFiles] A
                inner join ccAgentMsgFiles B on A.MsgId=B.MsgId
                where CamType=@CampType 

        end
        else IF @action = 10 -- Relation CampIn and MsgFile
        begin
                select MsgId,MsgFile ,Duration from ccAgentMsgFiles where MsgId=@MsgId

        end
        
END
'
EXEC(@sql)


        
        ------------------------------------------------------------  END  KR011000 Notificación recepción de llamada de entrada ---------------------------------------------------------------------

        set @process = 'Retorna status de resultado de SP ccsp_RIARegistryLists'
        set @sql = 'ALTER Procedure [dbo].[ccsp_RIARegistryLists]
@action tinyint = 0, 
@list_id int = 0,
@cam_id smallint = 0,
@name varchar(80) = '''',
@status tinyint = 0,
@sequence smallint = 0,
@load_id int = 0
AS

--Status lista 0: inactiva, 1:pausa, 2:procesar

--Insert
IF @action = 1 begin

	IF @cam_id <> 0 begin
		select @sequence = isnull(max( sequence ),0) from ccRIARegistryLists where cam_id = @cam_id
		set @sequence = @sequence + 1
		Insert into ccRIARegistryLists(cam_id,name,status,sequence) values (@cam_id, @name, 2, @sequence)
		select max(list_id) from ccRIARegistryLists
	end
end

--Update sequence
IF @action = 2 begin
	
	declare @oldSeq as int
	select @oldSeq = sequence, @cam_id = cam_id from ccRIARegistryLists where list_id = @list_id

	if @oldSeq <> @sequence begin
		
		if @oldSeq > @sequence begin
			update ccRIARegistryLists set sequence = sequence + 1 where cam_id = @cam_id and sequence >= @sequence and sequence < @oldSeq
		end

		if @oldSeq < @sequence begin
			update ccRIARegistryLists set sequence = sequence - 1 where cam_id = @cam_id and sequence <= @sequence and sequence > @oldSeq
		end

		update ccRIARegistryLists set sequence = @sequence where list_id = @list_id

	end

end

--Change status
IF @action = 3 begin
	
	update ccRIARegistryLists set status = @status where list_id = @list_id
	SELECT 200 as ReturnValue

end

-- lista campañas y listas de registros
IF @action = 4 begin
	select a.cam_id, b.cam_descripcion, count(list_id) as NoListas, c.graphic_id as Frame from ccRIARegistryLists a 
	left join cccamps b on a.cam_id = b.cam_id
	left join ccRIACampsGraph c on a.cam_id = c.cam_id
	where b.cam_activo = 1 and a.cam_id in ( select distinct(cam_id) from ccRIARegistryLists ) 
	group by a.cam_id,b.cam_descripcion,c.graphic_id order by a.cam_id asc

end

-- listas de registros y no. registros
IF @action = 5 
begin
	select a.list_id,a.name,count(b.list_id) as NoRegistros,a.sequence   
	from ccRIARegistryLists a with(index(IX_ccRIARegistryLists_1),nolock) 
	left join ccocallsoutsource b with(index(IX_ccoCallsOutSource_13),nolock) 
	on b.cam_id = @cam_id and a.list_id = b.list_id 
	where a.status > 0 and a.cam_id = @cam_id and status > 0 
	group by a.list_id,a.name,a.sequence 
	order by a.sequence
end

-- borrar lista
IF @action = 6 begin

	select @cam_id = cam_id from ccRIARegistryLists where list_id = @list_id
	select @sequence = max(sequence) from ccRIARegistryLists where cam_id = @cam_id
	exec ccsp_RIARegistryLists @action = 3, @status = 0, @list_id = @list_id
	exec ccsp_RIARegistryLists @action = 2, @sequence = @sequence, @list_id = @list_id
	SELECT 200 as ReturnValue

end

-- Detalle de numero de registros
IF @action = 7 begin

	declare @total as int

	select @total = count(*) from ccocallsoutsource where list_id = @list_id
	select @total = (@total - count(*)) from ccoworkingtable where list_id = @list_id

	if exists(select list_id from ccoWorkingTable where list_id = @list_id) begin
		select @status = status from ccRIARegistryLists where list_id = @list_id
		select @list_id as list_id,cast(cam_id as smallint) as cam_id, @status as status,
			count(case cal_status when 0 then 1 else null end) as New,
			count(case cal_status when 1 then 1 else null end) as CB,
			count(case cal_status when 2 then 1 else null end) as Pro, 
			@total as Fin
		from ccoWorkingTable where list_id = @list_id group by cam_id
	end
	ELSE begin
		select list_id, cam_id, status, 
		0 as New,
		0 as CB,
		0 as Pro,
		0 as Fin
		from ccRIARegistryLists where list_id = @list_id
	end


end

-- Cambia de nombre a la lista
IF @action = 8 begin
	
	update ccRIARegistryLists set name = @name where list_id = @list_id

end

-- Borra listas sin registros y reordena las listas
IF @action = 9 begin

	Create table #TempRegs(
		list_id int,
		[name] varchar(100),
		NoRegistros int,
		sequence int)

	insert into #TempRegs 
		select a.list_id,a.name,count(b.list_id) as NoRegistros,a.sequence 
		from ccRIARegistryLists a with(index(IX_ccRIARegistryLists_1),nolock)
		left join ccocallsoutsource b with(index(IX_ccoCallsOutSource_14),nolock)
		on a.list_id = b.list_id
		where a.status > 0 and a.cam_id = @cam_id and status > 0 
		group by a.list_id,a.name,a.sequence,a.status order by a.sequence

	while ( exists( select list_id from #TempRegs where NoRegistros = 0 ) ) begin
		declare @listToDelete as int
		select top 1 @listToDelete = list_id from #TempRegs where NoRegistros = 0
		exec ccsp_RIARegistryLists @action = 6, @list_id = @listToDelete
		delete from #TempRegs where list_id =  @listToDelete
	end

	drop table #TempRegs
	
	select @sequence=min(sequence) from ccRIARegistryLists where  cam_id = @cam_id and status = 0 

	select @list_id= list_id from ccRIARegistryLists where sequence =(
	select  max(sequence) as sequence from ccRIARegistryLists where  cam_id = @cam_id and status > 0 ) and cam_id = @cam_id
	update ccRIALoading set list_id = @list_id where load_id=@load_id
	exec ccsp_RIARegistryLists @action=2,@list_id=@list_id,@sequence=@sequence

	end'
        EXEC(@sql)


        set @process = 'Retorna status de resultado de SP ccsp_RIA_mnuReciclar'
        set @sql = 'ALTER proc [dbo].[ccsp_RIA_mnuReciclar]
@cam_id int,
@type tinyint, -- 0:recicla todo / 1:recicla no efectivos / 2:recicla los efectivos calificados /
--                3:recicla no efectivos y efectivos calificados (1 y 2) / 4:Recicla status "Finalizado"
@calif_id varchar(1500) = null,
@user_id as integer = null,
@list_id as integer = 0
as
set nocount on
declare @Valor int, @SQL varchar(4000)
select @Valor = valor from ccSettings with(nolock) where setting_id = 60

If @Valor = 1
 begin
    declare @ultimoReciclaje datetime, @siguienteReciclaje datetime, @difDateAdd datetime
    select @Valor = valor from ccSettings with(nolock) where setting_id = 59

    If @Valor = 0
     begin
        select -2, ''No hay un limite para volver a reciclar''
        return(0)
     end

    select top 1 @ultimoReciclaje = max(fecha) from ccLogReciclaje where cam_id = @cam_id

    -- Se crea log, ccsp_ADMlogReciclaje para que esta informacion la traiga, por que no se esta metiendo
    select @user_id = isnull(@user_id, ''0''), @calif_id = isnull(@calif_id, ''0'')

    exec dbo.ccsp_ADMlogReciclaje @cam_id, @user_id, @type, @calif_id

    If @ultimoReciclaje is not null and getdate() < DateAdd(n, @Valor, @ultimoReciclaje)
    begin
        select -3, ''No se puede realizar un reciclaje hasta que pase el tiempo limite''
        return(0)
    end

 end

if @type=0
 begin
    if @list_id = 0 begin
        create table #allReciycled(callout_id int not null primary key)

        insert into #allReciycled
        select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_8),nolock) where cam_id = @cam_id and cal_status = 1

        update ccoCallBacks
        set [status] = 3, schedulerStatus = 1
        from ccoCallBacks a with(index([IX_ccoCallBacks6])) join #allReciycled b on (a.callout_id = b.callout_id)
        where [status] = 0

        update ccoWorkingTable
        set cal_status = 0
        from ccoWorkingTable a join #allReciycled b on (a.callout_id = b.callout_id)

        drop table #allReciycled
    end
    else begin
        create table #allListReciycled(callout_id int not null primary key)

        insert into #allListReciycled
        select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_10),nolock) where cam_id = @cam_id and cal_status = 1 and list_id = @list_id

        update ccoCallBacks
        set [status] = 3, schedulerStatus = 1
        from ccoCallBacks a with(index([IX_ccoCallBacks6])) join #allListReciycled b on (a.callout_id = b.callout_id)
        where [status] = 0

        update ccoWorkingTable
        set cal_status = 0
        from ccoWorkingTable a join #allListReciycled b on (a.callout_id = b.callout_id)

        drop table #allListReciycled
    end
	select 1
    return(0)
 end

if @type in(1,3)
 begin

    update ccoCallBacks
    set [status] = 3, schedulerStatus = 1
    where callout_id in (select distinct(callout_id)
                         from ccoWorkingTable with(index(IX_ccoWorkingTable_12),nolock)
                         where cam_id = @cam_id
                         and cal_status = 1
                         and tiporesdial_id <> 1
                         and callout_id in (select distinct(b.callout_id)
                                                from ccologdials a with (index (IX_ccoLogDials_4),nolock)
                                                left join ccocallsout b with(index(IX_ccoCallsOut12),nolock)
                                                on a.callout_id = b.callout_id
                                                and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
                                                where calif_id = 0
                                                and calif_id is not null))
    and [status] = 0

    update ccoWorkingTable
    set cal_status = 0, tiporesdial_id = 0
    where cam_id = @cam_id
    and cal_status = 1
    and tiporesdial_id <> 1
    and callout_id in (select distinct(b.callout_id)
                           from ccologdials a with (index (IX_ccoLogDials_4),nolock)
                           left join ccocallsout b with(index(IX_ccoCallsOut12),nolock)
                           on a.callout_id = b.callout_id
                           and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
                           where calif_id = 0
                           and calif_id is not null)
 end

if @type in(2,3)
 begin

    Set @SQL = ''update ccoCallBacks with(rowlock) set [status] = 3, schedulerStatus = 1'' +
     ''where callout_id in ('' +
     ''select distinct(callout_id) from ccoWorkingTable with(index(IX_ccoWorkingTable_14),nolock) '' +
     ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 '' +
     ''and calif_id in ('' + @calif_id + ''))'' +
     ''and [status] = 0''

    exec(@SQL)

    Set @SQL = ''update ccoWorkingTable set cal_status = 0, tiporesdial_id = 0, calif_id = 0 '' +
     ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 ''
     + -- and tiporesdial_id = 1 '' +
     ''and calif_id in ('' + @calif_id + '')''

    exec(@SQL)
 end

if @type = 4
 begin

    update ccoCallBacks
    set [status] = 3, schedulerStatus = 1
    where callout_id in (select distinct(callout_id)
                         from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock)
                         where cam_id = @cam_id and cal_status = 3)
    and [status] = 0

    update ccoWorkingTable
  set cal_status = 0, tiporesdial_id = 0
    where cam_id = @cam_id and cal_status = 3
 end

return(0)
set nocount off'
        EXEC(@sql)


        set @process = 'Se quita parametro opcion para retornar resultado individual ccsp_OUTGetNewJobs'
        set @sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
		@CAMPID int,
		@test int=0,
		@nAgentsLogin int=1,
		@iZonas int = null
		as
		--set nocount on
		declare @total int
		declare @topCount smallint, @bIsDaylight bit, @revHorario bit
		declare @country_id int, @TipoJobs int
		--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
		declare @sql varchar(MAX), @Order_Asc_Desc char(4)
		declare @camSurvey int
		select @camSurvey = 0
		DECLARE @iZonasTable TABLE (value int)

		select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

		-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
		SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
		select @revHorario=valor from ccsettings where setting_id = 112
		-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
		SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
		SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

		SET DATEFIRST 1
		--Checamos si es horario de verano
		select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

		if @iZonas is null begin

			  INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
			  select @iZonas=value from @iZonasTable
		--Checamos si la campaÃ±a tiene horarios configurados
			  if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
			  begin
						  if @iZonas = 0 begin
								SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
								return
						  end
			  end
			  else begin
					if @camSurvey > 0
						  begin
								SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
								return
						  end
			  end
		end

		set @sql=''CREATE TABLE #NEW_JOBS
		(callout_id int,
			  cam_id int,
			  cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
			  cal_status tinyint,
			  cal_fechaDial datetime,
			  user_id int,
			  tz int,
		tz2 int,
		tz3 int,
		tz4 int,
		tz5 int,
		list_id int,
		sequence smallint,
		calkey varchar(max),
		nDescartes int,
		name_agent varchar(max)
		)''


		-- 0=Ambas, 1=CallBacks, 2=Nuevas
		select @topCount=valor from ccSettings where setting_id=94

		if isnull(@topCount,0)=0
		select @topCount=case when @nAgentsLogin<3 then 30
			  when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
			  when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
			  when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
			  when @nAgentsLogin>=16 then 240 else 20 end

		select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

		declare @isVerano varchar(max)
		set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

		if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
		begin

					select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

					select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
					SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
					+@isVerano+'',''
					+@isVerano+''2,''
					+@isVerano+''3,''
					+@isVerano+''4,''
					+@isVerano+''5,
					W.list_id, isNull(R.sequence,0) as sequence,
					cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
					isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent
					FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
					left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
					left join ccUsers us (nolock) on us.User_id=w.user_id
					WHERE W.cal_status=1 -- CallBacks
					and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
					and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
					and (
						  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
						  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
						  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
						  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
						  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
					)
					and isnull(R.status,2) = 2
					order by prioridad_cb desc, W.cal_fechaDial ''  + @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
					
					--select @sql
		end -- TOMA EN CUENTA LOS CALLBACKS

		if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
		begin
					select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

					select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
					SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
					+@isVerano+'',''
					+@isVerano+''2,''
					+@isVerano+''3,''
					+@isVerano+''4,''
					+@isVerano+''5,
					W.list_id, isNull(R.sequence,0) as sequence,
					cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
					isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent
					FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
					left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
					left join ccUsers us (nolock) on us.User_id=w.user_id
					WHERE W.cal_status=0 -- Nuevas
					and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
					and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
					and (
						  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
					)
					and isnull(R.status,2) = 2
					order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc

		end -- TOMA EN CUENTA LAS NUEVAS
		----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
		select @sql=@sql+nchar(13)+ ''SET rowcount 0''
		if @Test=0
			  begin
					select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
					WHERE callout_id in(select callout_id from #NEW_JOBS)''
		end

		if @Test = 2
		begin
			  select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
			  declare @nSQL nvarchar(4000)
			  set @nSQL=cast(@sql as nvarchar(4000))
			  exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
			  return(@total)
		end
		else
		begin
			select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
			user_id, tz, tz2, tz3, tz4, tz5,
			case when tz is null then '''''''' else cal_telefono end as tel,
			case when tz2 is null then '''''''' else cal_telefono end as tel2,
			case when tz3 is null then '''''''' else cal_telefono end as tel3,
			case when tz4 is null then '''''''' else cal_telefono end as tel4,
			case when tz5 is null then '''''''' else cal_telefono end as tel5,
			NULL as dialOrder, list_id, sequence, calkey,
			0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type, nDescartes, name_agent
			FROM #NEW_JOBS where len(cal_telefono)>0

			---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
			declare @regval int
			SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
			exec ccsp_GetCampsNvosCB @cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + '',@Tipo=0,@user_id =0
			''
		end

		set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
		print (@sql)
		exec(@sql)

		return(0)'
        EXEC(@sql)
        ------------------------------------------ Correcion Catalogo Agente -----------------------------------------------

set @process = 'Correcion Catalog Agente alter configuraIdiomaCatalogosEspañol'
    set @sql='ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEspañol] AS
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
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

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
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (34, convert(text, N''Dialogo WhatsApp'' collate SQL_Latin1_General_CP1_CI_AS))
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
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default13'', ''La sesión de chat ha concluido'')
                '
    EXEC(@sql)

    set @process = 'Correcion Catalogo Agente alter configuraIdiomaCatalogosEnglish'
    set @sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEnglish]
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
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

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
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default13'', ''Chat session has finished'')
'
    EXEC(@sql)




    set @process = 'Add State Dialog WhatsAPP ccTipoStatusAgente'
    set @sql = 'if not exists(select * from ccTipoStatusAgente nolock where TipoStatusAge_id=34)
        begin
            insert ccTipoStatusAgente values (34, ''Dialogo WhatsApp'')
        end'
    EXEC(@sql)
        ------------------------------------------ Correcion Catalogo Agente -----------------------------------------------

    set @process = 'Modificacion opcion 10 para on¡btener valores de campañas de campañas de entrada y salida'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS      SMALLINT, 
                                       @CampType AS    SMALLINT = 0, 
                                       @WorkgroupId AS INT      = 0, 
                                       @Id AS          INT      = 0, 
                                       @AdminId AS     SMALLINT = 0, 
                                       @PinUpdate AS   SMALLINT = 0, 
                                       @LoadId AS      INT      = 0, 
                                               @Type AS        SMALLINT = 0,
											   @InboundType	   SMALLINT = 0,
											   @AreaId		   SMALLINT = 0,
											   @multi_type     varchar(max) = null
AS
BEGIN
    SET NOCOUNT ON;
    IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                        BEGIN
                            SELECT CAST(IdCampEsp AS INT) AS Id
                            FROM ccRIACampEspWG
                            WHERE IDWG = @WorkgroupId
                                  AND Tipo = 1
                                   ORDER BY IdCampEsp ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe una lista de campañas de salida con el id de grupo de trabajo especificado'', 18, 1);
                    END;
            END;
            IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                        BEGIN
                            SELECT CAST(IdCampEsp AS INT) AS Id
                            FROM ccRIACampEspWG
                            WHERE IDWG = @WorkgroupId
                                  AND Tipo = 0
                                   ORDER BY IdCampEsp ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe una lista de campañas de entrada con el id de grupo de trabajo especificado'', 18, 1);
                    END;
            END;
            RETURN 0;
    END;
    IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            SELECT DISTINCT 
                                   CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area,  
                                        CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType
                            FROM ccCamps camps
                                 LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                                 LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
                            WHERE camps.cam_id = @Id
                                   ORDER BY camps.cam_descripcion ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
                    END;
            END;
            IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            SELECT DISTINCT 
                                   CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType
                            FROM ccInbound inb
                                 LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                                 LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
                            WHERE inb.Inbound_id = @Id
                                   ORDER BY inb.descripcion ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe campañas de entrada con el id especificado'', 18, 1);
                    END;
            END;
            RETURN 0;
    END;
    IF @Option = 3   -- Update OverallTotalNew By Campaign
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    UPDATE ccCampsNvosCB
                      SET 
                          OverallTotalNew = ccCampsNvosCB.new
                    WHERE id = @Id;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 4   -- Update Pin from Campaign per Admin
        BEGIN
            IF @Id IS NOT NULL
               AND @AdminId IS NOT NULL
                BEGIN
                    IF @PinUpdate = 1
                        BEGIN
                            INSERT INTO PinedCampaigns(CampId, AdminId, Type)
                        VALUES(@Id, @AdminId, @Type);
                    END;
                    IF @PinUpdate = 0
                        BEGIN
                            DELETE FROM PinedCampaigns
                            WHERE CampId = @Id
                                  AND AdminId = @AdminId
                                  AND Type = @Type;
                    END;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. La campañas o administrador no existen'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 5   -- Get Pin from Campaign Ids per Admin
        BEGIN
            IF @AdminId IS NOT NULL
                BEGIN
                    SELECT CampId AS Id
                    FROM PinedCampaigns
                    WHERE AdminId = @AdminId
                          AND Type = @Type
                           ORDER BY Id ASC;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 6   -- Get Blacklist Ids by Campaign Id
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    DECLARE @BlackListIds VARCHAR(MAX);
                    SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
                    FROM Camplistanegra
                    WHERE cam_id = @Id
                          AND STATUS = 1;
                    SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 7   -- Get RegistryListIds Ids by Campaign Id
        BEGIN
            IF(@Id IS NOT NULL
               AND EXISTS
            (
                SELECT *
                FROM cccamps
                WHERE cam_id = @Id
            ))
                BEGIN
                    SELECT TOP 1 list_id
                    FROM ccRIARegistryLists
                    WHERE cam_id = @Id
                          AND STATUS = 2
                           ORDER BY list_id DESC;
            END;
            ELSE
                BEGIN
                    --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                    RAISERROR(''ERROR. No existe una campa?a con el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 8   -- Delete RegistryListIds Ids by LoadId
        BEGIN
            IF(@LoadId IS NOT NULL
               AND EXISTS
            (
                SELECT *
                FROM ccRIARegistryLists
                WHERE list_id = @loadID
                      AND STATUS <> 0
            ))
                BEGIN
                    UPDATE ccoCallsOutSource
                      SET 
                          cal_status = ''5''
                    WHERE list_id = @loadID;
                    DELETE FROM ccoWorkingTable
                    WHERE list_id = @LoadId;
                    EXEC ccsp_RIARegistryLists 
                         @action = 6, 
                         @list_id = @LoadId;
            END;
            ELSE
                BEGIN
                    --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                    RAISERROR(''ERROR. No existe una carga el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @option = 9   -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
        BEGIN
            DECLARE @table TABLE
            (camId    INT, 
             campType TINYINT, 
             PRIMARY KEY(camId, campType)
            );
            INSERT INTO @table
                   SELECT DISTINCT 
                          IdCampEsp, Tipo
                   FROM ccRIACampEspWG wg
                   WHERE wg.IDWG IN
                   (
                       SELECT IDWG
                       FROM ccRIAWorkGroupUsers
                       WHERE IDWG <> @WorkgroupId
                             AND User_id = @AdminId
                   );
            SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
            FROM @table A
                 RIGHT JOIN
            (
                SELECT wg.IdCampEsp, wg.Tipo
                FROM ccRIACampEspWG wg
                WHERE wg.IDWG = @WorkgroupId
            ) B ON A.camId = B.IdCampEsp
                   AND A.campType = B.Tipo
            WHERE A.camId IS NULL
                   ORDER BY IdCampEsp;
            RETURN 0;
    END;
    IF @option = 10  -- Get Agents States with totals per campaign by admin id and campaign type
    BEGIN
  DECLARE @date DATETIME= CONVERT(DATE, DATEADD(hh, -3, GETDATE()));
  DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY(id));
  DECLARE @AgentsList TABLE(id INT, PRIMARY KEY(id));
  DECLARE @tmpCamAgent TABLE(camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY(camId, userId));
  DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT);
  DECLARE @CurrentStatus TABLE(userId INT, CurrentState INT, IdCampEsp INT, camType INT);
  DECLARE @campDataTotal TABLE(camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY(camId));

  INSERT INTO @AdminWorkgroups SELECT DISTINCT IDWG
  FROM ccRIAWorkGroupUsers WG, 
     ccUsers_Roles R
  WHERE WG.User_id = @AdminId
  OR (R.User_id = @AdminId
  AND R.Rol_id = 7);
    
  INSERT INTO @AgentsList SELECT DISTINCT A.User_id
  FROM ccRIAWorkGroupUsers A
  INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
  INNER JOIN ccUsers C ON A.User_id = C.User_id 
  AND C.TipoUser_id = 1
    ORDER BY A.User_id;

  INSERT INTO @tmpCamAgent SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id,
  CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
  FROM ccRIACampEspWG campPerWg
  INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
  INNER JOIN ccRIAWorkGroupUsers wgUser (nolock) ON wgUser.IDWG = wg.id
  INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
  LEFT JOIN ccInbound inbound ON Inbound_id = campPerWg.IdCampEsp 
  AND C.TipoUser_id = 1
  WHERE campPerWg.Tipo = @CampType
  AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
  
  WITH lastState AS (
  SELECT A.user_id, MAX(A.fecha) AS fecha
  FROM ccLogAgentesDia A
  INNER JOIN @AgentsList B ON A.User_id = B.id
  WHERE fecha >= @date
  GROUP BY user_id)

    INSERT INTO @CurrentStatus 
  SELECT B.User_id,
  CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS currentStatus,
  B.IdCampEsp,
  B.Tipo
  FROM lastState A
  INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
  AND A.fecha = B.fecha;

  IF @Id = 0 AND @CampType = 0 
  BEGIN
    DELETE FROM @tmpCamAgent WHERE multimediaType = 5
  END

  DECLARE @MultimediaType SMALLINT = (SELECT CASE WHEN @CampType = 1 THEN -1 ELSE meanContactTypeId END
                    FROM contactMeanIn WHERE inboundId = @Id)

  DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes

  INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
  (CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = @CampType
   THEN @CampType ELSE null END) AS isCampDialog 
  FROM @tmpCamAgent A
  INNER JOIN @CurrentStatus B ON A.userId = B.userId
  WHERE (@Id = 0 or A.camId = @Id)

  IF @CampType = 1
    BEGIN
    ;with  campDataTotal as(
      select camId,count(*) total from @tmpCamAgent A group by camId
    )

    insert into @campDataTotal
    select 
      A.camId,
      B.cam_descripcion as campName 
      ,A.Total
      ,C.AreaName as Area
      from campDataTotal A
      INNER JOIN ccCamps B ON A.camId= B.cam_id 
      INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END
  ELSE
    BEGIN    
    ;with  campDataTotal as(
      select camId,count(*) total from @tmpCamAgent A group by camId
    )

    insert into @campDataTotal
    select 
      A.camId,
      B.descripcion as campName 
      ,A.Total
      ,C.AreaName as Area
      from campDataTotal A
        INNER JOIN ccInbound B ON A.camId = B.Inbound_id 
      INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END 


  ;WITH stateCamp AS(
    SELECT A.CampId,
    count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready,
    count(CASE WHEN A.CurrentState NOT IN(-2, -1, 0, 3, 4, 5, 6, 9, 30, 34) THEN 1 
           WHEN A.CurrentState IN (6, 34) AND A.CampId != C.IdCampEsp THEN 1 ELSE NULL END) AS notReady,
    COUNT(isCampDialog) AS dialog,
    COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected 
    FROM @AgentStatus A
    INNER JOIN @CurrentStatus C ON A.userId = C.userId
    GROUP BY A.CampId
  )

  SELECT 
    A.camId,
    A.campName,
    A.Total,
      ISNULL(B.ready, 0) AS Ready,
    ISNULL(B.notReady, 0 ) AS NotReady, 
    ISNULL(B.dialog, 0) AS Dialog,
    CASE WHEN B.disconnected IS NULL THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END Disconnected,
    A.Area
  FROM @campDataTotal A
  LEFT JOIN stateCamp B ON A.camId = B.CampId
  ORDER BY A.campName

        RETURN 0;
    END;
    IF @Option = 11  -- Get Campaigns Ids List Per Workgroup and Campaign Type
        BEGIN                
            IF Not EXISTS
            (
                SELECT *
                FROM ccUsers_Roles NOLOCK
                WHERE User_id = @AdminId
                      AND Rol_id = 7
            )
                BEGIN
        print ''xxxx SIn Super''
                    ;WITH wgId
                         AS (SELECT IDWG
                             FROM ccRIAWorkGroupUsers NOLOCK
                             WHERE user_id = @AdminId)
                         SELECT DISTINCT 
                                CAST(IdCampEsp AS INT) AS Id
                         FROM ccRIACampEspWG A (NOLOCK)
                              INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                 AND A.Tipo = @CampType;
            END;
            ELSE
                BEGIN
      --print ''xxxx Super''
      IF @CampType = 1
        BEGIN
          SELECT DISTINCT 
               CAST(cam_id AS INT) AS Id
                        FROM ccCamps (NOLOCK) where IDArea IS NOT NULL
        END
      ELSE
        BEGIN 
          SELECT DISTINCT 
               CAST(Inbound_id AS INT) AS Id
                        FROM ccInbound (NOLOCK) where IDArea IS NOT NULL
        END
            END;
            RETURN 0;
    END;
    IF @Option = 12  -- Get All Campaigns complete information per Campaign Type and Campaign Id
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    SELECT DISTINCT 
                           CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area,  
                           CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType
                    FROM ccCamps camps (NOLOCK)
                         INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
                         INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
                           --WHERE camps.cam_id = @Id
                           ORDER BY camps.cam_descripcion ASC;
            END;
            ELSE
                BEGIN
                    SELECT DISTINCT 
                           CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType
                    FROM ccInbound inb (NOLOCK)
                         INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
                         INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = inb.IDArea
                           ORDER BY inb.descripcion ASC;
            END;
            RETURN 0;
    END;
	IF @Option = 13
	BEGIN
		BEGIN                
			IF NOT EXISTS
			(
				SELECT *
				FROM ccUsers_Roles NOLOCK
				WHERE User_id = @AdminId
						AND Rol_id = 7
			)
				BEGIN
					IF @CampType = 1
						BEGIN
							WITH wgId
								AS (SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT 
									CAST(IdCampEsp AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,CAST(-1 AS INT) AS RelatedCampId
								FROM ccRIACampEspWG A
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 1
									INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id;
						END
					ELSE
						BEGIN
							WITH wgId
								AS (SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT 
									CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
								FROM ccRIACampEspWG A (NOLOCK)
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 0
									INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id 
									AND ((@multi_type is null AND cci.chat = @InboundType)
										OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
						END
			END;
			ELSE
				BEGIN
				IF @CampType = 1
					BEGIN
						SELECT DISTINCT 
								CAST(cam_id AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,-1 AS RelatedCampId
						FROM ccCamps NOLOCK where IDArea = @AreaId
					END
				ELSE
					BEGIN 
						SELECT DISTINCT 
								CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
						FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
						AND ((@multi_type is null AND cci.chat = @InboundType)
							OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

					END
			END;
			RETURN 0;
		END;
	END;

	IF @Option = 14
		BEGIN
			IF NOT EXISTS
			(
					SELECT *
					FROM ccUsers_Roles NOLOCK
					WHERE User_id = @AdminId
							AND Rol_id = 7
			)
				BEGIN
					WITH wgId
							AS (SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT 
								CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
							FROM ccRIACampEspWG A (NOLOCK)
								INNER JOIN wgId ON wgId.IDWG = A.IDWG
													AND A.Tipo = 0
								INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND isnull(cci.cam_id,-1) = -1
								AND ((@multi_type is null AND cci.chat = @InboundType)
									OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

				END
			ELSE
				BEGIN
					SELECT DISTINCT 
					CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
					FROM ccInbound cci (NOLOCK) where IDArea = @AreaId AND isnull(cam_id,-1) = -1
					AND ((@multi_type is null AND cci.chat = @InboundType)
						OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

				END
		END
    IF @Option = 15
        BEGIN
            SELECT DISTINCT 
            CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
            FROM ccInbound NOLOCK where cam_id = @Id
        END
END;'
    EXEC(@sql)


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
