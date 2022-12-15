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
SET @versionfix = 25
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
		
		SET @process = 'K012009_Catálogo_de mensajes_Área add column idArea to ccMsgFiles table'
		set @sql = 'IF not exists (SELECT * FROM sys.columns WHERE name = N''idArea'' AND Object_ID = Object_ID(N''ccMsgFiles''))
			BEGIN
				ALTER TABLE ccMsgFiles ADD idArea SMALLINT NULL
			END'
		EXEC(@sql)


		SET @process = 'K012009_Catálogo_de mensajes_Área delete procedure ccsp_GalateaAutomaticMessages'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaAutomaticMessages'')
			BEGIN
				DROP PROCEDURE ccsp_GalateaAutomaticMessages
			END'
		EXEC(@sql)

		

		SET @process = 'K012009_Catálogo_de mensajes_Área create procedure ccsp_GalateaAutomaticMessages'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaAutomaticMessages]
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
        @MsgRelation varchar(8000) = NULL,
		@idArea SMALLINT = NULL

        AS

        SET NOCOUNT ON

        if @action = 1  -- Get audio catalog
        begin
            select ISNULL(msgName, msgFile) [MsgName], Descripcion [MsgDescription], msg_id [MsgId], DefaultMessage, ISNULL(idArea, -1) [IdArea] from ccMsgFiles
            where msgFile not like ''TTS|%'' AND (idArea IN (@idArea,-1) OR idArea IS NULL)
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
                insert into ccMsgFiles (msgFile, descripcion, length, msgName, idArea) values (@msgFile, @Description, @length, @msgName, @idArea)
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
                    update ccMsgFiles set Descripcion = @Description, msgName = @msgName, idArea = @idArea where msg_id = @msg_id
                END
            else
                BEGIN
                    update ccMsgFiles set Descripcion = @Description, msgName = @msgName, msgFile = @msgFile, length = @length, idArea = @idArea where msg_id = @msg_id
                END
        END 

        if @action = 7
        BEGIN
            select msg_id as msgId, msgName as MsgName, Descripcion as MsgDescription, ISNULL(idArea,-1) AS IdArea from ccMsgFiles where msg_id = @msg_id
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

