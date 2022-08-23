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

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
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

        set @process = 'SCP-71 Alter procedure ccsp_GalateaAutomaticMessages: Changes in action 1, adding the return of DefaultMessage column'
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
                                update ccMsgFiles set Descripcion = @Description, msgName = @msgName, msgFile = @msgFile where msg_id = @msg_id
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


                    SET NOCOUNT OFF'
        EXEC(@sql)

        set @process = 'SCP-71 Alter procedure configuraIdiomaCatalogosEnglish: Insert values 1 in DefaultMessage column in ccMsgFiles'
        set @sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEnglish
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

	    ----------------------------------GMZ | CW-7258_GetCampaignByAudio --------------------------------------------------

        set @process = 'CW-7258_GetCampaignByAudio se modifica sp de ccsp_GalateaAutomaticMessages (se agrego action 11)'
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
		    select ISNULL(msgName, msgFile) [MsgName], Descripcion [MsgDescription], msg_id [MsgId] from ccMsgFiles
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
