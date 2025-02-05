/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio Chagolla
Date: 2024/09/30
Description: Release 126.20241218.0.0
Database: CCenterRia
Required version: 126.6
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
SET @version = 127 --**********actualizar a 124 sin fix
SET @versionfix = 0
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

	------------------------------------------- BEGIN Carlos Eduardo Muñoz Carbajal ----------------------------------------
	SET @process = 'Creation of Table for Luis Agent'
	SET @sql = '
		IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = ''ccVirtualAgent'')
		BEGIN
            CREATE TABLE dbo.ccVirtualAgent (
                idAgent INT IDENTITY(1,1) PRIMARY KEY,
                nameAgent VARCHAR(255) NOT NULL,
                statusAgent BIT NOT NULL,
                createDateAgent DATE NOT NULL DEFAULT GETDATE(),
                latestUpdateDateAgent DATE NULL,
                concurrentSessionsLimit INT,
                idCampaign SMALLINT NULL,
                mediaType TINYINT NULL,
                campType TINYINT NULL,
                location VARCHAR(50),
				quantumAgentId VARCHAR(50)
            );
		END'
	EXEC(@sql)

    SET @process = 'Creation of SP for consult, deletion, campaign assignation, and enable or disable virtual agents'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_VirtualAgents'')
			begin
				DROP PROCEDURE ccsp_VirtualAgents;
			end'
    EXEC(@sql)

    SET @sql = '
    CREATE PROCEDURE [dbo].[ccsp_VirtualAgents]
    @action INT,
	@idVirtualAgent INT = 0,
    @nameAgent NVARCHAR(255) = NULL,
    @statusAgent BIT = NULL,
	@campaignId INT = NULL,
	@mediaType INT = NULL, -- CALLS, WHATSAPP, SMS
	@campType INT = NULL, -- 0 IN - 1 OUT
	-- Masivo
	@virtualAgentIds VARCHAR(600) = NULL
    AS
    BEGIN
        IF @action = 1
        BEGIN
            SELECT
                va.idAgent AS idAgent,
                va.NameAgent AS nombre,
                ISNULL(CAST(va.idCampaign AS INT),0) AS idCampaign,
                ISNULL(va.concurrentSessionsLimit, 0) AS concurrentSessionsLimit,
                CAST(va.StatusAgent AS BIT) AS status,
                CAST(va.mediaType AS INT) as SubType,
                ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN ci.descripcion 
                        ELSE co.cam_descripcion
                    END, ''N/A''
                ) AS campName,
                ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN ci.IDArea -- Campaña de entrada
                        ELSE co.IDArea -- Campaña de salida
                    END,
                0) AS IDArea,
                CAST(ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN ig.graphic_id -- Icono para entrada
                        ELSE og.graphic_id -- Icono para salida
                    END, 0
                ) AS int) AS campaignGraph,
                CAST(va.CampType AS int) CampType,
                ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN CAST(ci.Status AS BIT) -- Estado de la campaña de entrada
                        ELSE CAST(co.cam_procesando AS BIT) -- Estado de la campaña de salida
                    END, 0
                ) AS IsActiveCampaign, -- Devuelve 1 o 0
                ISNULL(
                    CASE 
                        WHEN (va.CampType = 0 AND ci.chat = 5) THEN wn.Number
                        WHEN (va.CampType = 1 AND co.CampType = 5) THEN wno.Number
                        ELSE ''N/A''
                    END, ''N/A''
                ) AS NumeroAsociado,
                CONVERT(VARCHAR(10), va.createDateAgent, 120) AS FechaCreacion, -- Devuelve como ''YYYY-MM-DD''
                ISNULL(
                    CASE 
                        WHEN va.latestUpdateDateAgent IS NULL OR va.latestUpdateDateAgent = '''' THEN ''N/A''
                        ELSE CONVERT(VARCHAR(10), va.latestUpdateDateAgent, 120) -- Devuelve como ''YYYY-MM-DD''
                    END, ''N/A''
                ) AS FechaUltimaModificacion -- Devuelve ''YYYY-MM-DD'' o ''N/A''
            FROM dbo.ccVirtualAgent va
            LEFT JOIN dbo.ccInbound ci ON ci.Inbound_id = va.idCampaign AND va.campType = 0
            LEFT JOIN dbo.ccCamps co ON co.cam_id = va.idCampaign AND va.campType = 1
            LEFT JOIN dbo.ccMetaWhatsAppNumbers wn ON wn.Inbound_Id = va.idCampaign AND va.campType = 0 AND mediaType != 0
            LEFT JOIN dbo.ccMetaWhatsAppNumbers wno ON wno.Cam_Id = va.idCampaign AND va.campType = 1 AND mediaType != 0
            LEFT JOIN dbo.ccRIAInboundGraph ig ON ig.Inbound_id = va.idCampaign AND va.campType = 0
            LEFT JOIN dbo.ccRIACampsGraph og ON og.cam_id = va.idCampaign AND va.campType = 1
        END

        ELSE IF @action = 2
        BEGIN
            -- Creación de un nuevo agente virtual
            INSERT INTO dbo.ccVirtualAgent (
                nameAgent, 
                statusAgent, 
                createDateAgent, 
                latestUpdateDateAgent
            )
            VALUES (
                @nameAgent, 
                @statusAgent, 
                GETDATE(), -- Fecha de creación actual
                NULL -- latestUpdateDateAgent
            );

            -- Retornar mensaje de éxito
            SELECT ''Agente creado exitosamente'' AS Resultado, SCOPE_IDENTITY() AS IdAgenteCreado;
        END

        ELSE IF @action = 3 -- Elimination of virtual Agent
        BEGIN
            CREATE TABLE #deletedVirtualAgents(idAgent int, agentName varchar(255))

            DELETE FROM dbo.ccVirtualAgent
            OUTPUT deleted.idAgent, deleted.nameAgent INTO #deletedVirtualAgents
            WHERE idAgent IN(SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,'','')) AND statusAgent = 0;

            SELECT * FROM #deletedVirtualAgents
        END

        ELSE IF @action = 4 -- Assignment or deassignment of campaign
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM ccVirtualAgent WHERE idAgent != @idVirtualAgent AND idCampaign = @campaignId AND mediaType = @mediaType AND campType = @campType) OR
            (@campaignId = 0)
            BEGIN
                UPDATE ccVirtualAgent SET idCampaign = @campaignId, 
                                        mediaType = @mediaType, 
                                        campType = @campType,
                                        latestUpdateDateAgent = GETDATE()
                WHERE idAgent = @idVirtualAgent

                SELECT @@ROWCOUNT
            END
                
                SELECT 0
        END

        ELSE IF @action = 5 -- Status change
        BEGIN
            CREATE TABLE #updatedVirtualAgents(idAgent int, nameAgent varchar(255), newStatus BIT)

            UPDATE ccVirtualAgent SET statusAgent = @statusAgent,
                                    latestUpdateDateAgent = GETDATE()
            OUTPUT inserted.idAgent, inserted.nameAgent, inserted.statusAgent as newStatus INTO #updatedVirtualAgents
            WHERE idAgent IN (SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,'','')) and statusAgent != @statusAgent

            SELECT * FROM #updatedVirtualAgents
        END
    END'
    EXEC(@sql)

    SET @process = 'Insertion of new module for Activity history'
    SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaModules WHERE moduleId = 24)
	BEGIN
        INSERT INTO ccGalateaModules VALUES (24,''Agentes virtuales'',''Virtual agents'',''Agentes virtuais'');
	END
    '
    EXEC(@sql)

    SET @process = 'Insertion of Operation for elimination of virtual agents'
	SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 127)
	BEGIN
        INSERT INTO ccGalateaOperations VALUES(127,''Eliminar agente'',''Delete agent'',''Excluir agente'');
	END'
    EXEC (@sql)

    SET @process = 'Insertion of Operation for disable of virtual agents'
	SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 128)
	BEGIN
        INSERT INTO ccGalateaOperations VALUES(128,''Deshabilitar agente'',''Disable agent'',''Desativar agente'');
	END'
    EXEC(@sql)

    SET @process = 'Insertion of Operation for enable virtual agents'
	SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 129)
	BEGIN
        INSERT INTO ccGalateaOperations VALUES (129,''Habilitar agente'',''Enable agent'',''Ativar agente'');
	END'
    EXEC(@sql)

    SET @process = 'Insertion of relationships between operations and new module'
	SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaModOpRelation WHERE ModuleId = 24 AND OperationId = 127)
	BEGIN
        INSERT INTO ccGalateaModOpRelation VALUES (24,127)
	END'
    EXEC(@sql)

    SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaModOpRelation WHERE ModuleId = 24 AND OperationId = 128)
	BEGIN
        INSERT INTO ccGalateaModOpRelation VALUES (24,128)
	END'
    EXEC(@sql)

    SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaModOpRelation WHERE ModuleId = 24 AND OperationId = 129)
	BEGIN
        INSERT INTO ccGalateaModOpRelation VALUES (24,129)
	END'
    EXEC(@sql)

    SET @process = 'Se agrega setting para registrar el número de agentes contratados'
	SET @sql= 'IF NOT EXISTS (select * from ccSettings2 where setting_id = 281)
	BEGIN
		insert into ccSettings2(setting_id, valor,descripcion,Status,Tipo, detalle, description, bLoadSettings, validate)
		values (281,''0'',''Numero de agentes virtuales'',1,''ADM'',''Numero de agentes virtuales'',''Number of virtual agents'',1,NULL)
	END'
    EXEC(@sql)
    ------------------------- END Carlos Eduardo Muñoz Carbajal --------------------------------------------
    
    ------------------------- BEGIN Ivan Martin Enciso          --------------------------------------------
    SET @process = 'Se agregan nuevas columnas a la tabla ccCampsExtend para campañas AI'
	SET @sql= '
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = ''ccCampsExtend'' AND COLUMN_NAME = ''RescheduledSurveyAI'')
    BEGIN
        ALTER TABLE ccCampsExtend ADD RescheduledSurveyAI BIT DEFAULT 0 NOT NULL;
    END

    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_NAME = ''ccCampsExtend'' AND COLUMN_NAME = ''ImmediateSurveyAI'')
    BEGIN
        ALTER TABLE ccCampsExtend ADD ImmediateSurveyAI BIT DEFAULT 0 NOT NULL;
    END

    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_NAME = ''ccCampsExtend'' AND COLUMN_NAME = ''ApplyRescheduledSurveyForCompletedCallsAI'')
    BEGIN
        ALTER TABLE ccCampsExtend ADD ApplyRescheduledSurveyForCompletedCallsAI BIT DEFAULT 0 NOT NULL;
    END

    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_NAME = ''ccCampsExtend'' AND COLUMN_NAME = ''EnableCallRecordingAI'')
    BEGIN
        ALTER TABLE ccCampsExtend ADD EnableCallRecordingAI BIT DEFAULT 0 NOT NULL;
    END'
    EXEC(@sql)

    SET @process = 'Se elimina procedure ccsp_GalateaGetOutboundConfiguration'
    SET @sql = '
    IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = N''ccsp_GalateaGetOutboundConfiguration'')
    BEGIN
        DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration;
    END'
    EXEC(@sql)

    SET @process = 'Se elimina procedure ccsp_RIA_ABCCamps'
    SET @sql = '
    IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = N''ccsp_RIA_ABCCamps'')
    BEGIN
        DROP PROCEDURE ccsp_RIA_ABCCamps;
    END'
    EXEC(@sql)

    SET @process = 'Se elimina procedure ccsp_RIAConfCamp'
    SET @sql = '
    IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = N''ccsp_RIAConfCamp'')
    BEGIN
        DROP PROCEDURE ccsp_RIAConfCamp;
    END'
    EXEC(@sql)

    SET @process = 'Se elimina procedure ccsp_RIAUpdateCamConfigExtend'
    SET @sql = '
    IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = N''ccsp_RIAUpdateCamConfigExtend'')
    BEGIN
        DROP PROCEDURE ccsp_RIAUpdateCamConfigExtend;
    END'
    EXEC(@sql)

    SET @process = 'Se agregan nuevas configuraciones al procedimiento de guardado'
	SET @sql= '
    CREATE PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]
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
        ,MaxDaysPerWAConvo SMALLINT
        -- Outbound AI Campaign Special Settings
        ,RescheduledSurveyAI BIT
        ,ImmediateSurveyAI BIT
        ,ApplyRescheduledSurveyForCompletedCallsAI BIT
        ,EnableCallRecordingAI BIT
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
        ,MaxDaysPerWAConvo DaysVisualConversationWhatsApp
        -- Outbound AI Campaign Special Settings
        ,RescheduledSurveyAI
        ,ImmediateSurveyAI
        ,ApplyRescheduledSurveyForCompletedCallsAI
        ,EnableCallRecordingAI
        FROM @AllCampaigns
        WHERE cam_id = @campID
    END'
    EXEC(@sql)

    SET @process = 'Se agrega mediatype 9 para el log del activity'
	SET @sql= '
    CREATE PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
                @option smallint,
                @UserId int = null,
                @Descripcion varchar(40) = null,
                @Cam_id varchar(1000),
                @Activa tinyint = null,
                @IDArea smallint = null,
                @frame tinyint = null, 
                @MirrorInbound_Id smallint = null,
                @Prefijo varchar(40) = null,
                @MediaType int = null,
                @isCreating int = null,
                @module int = -1
                as
                set nocount on

                if @option = 0
                    begin
                        select cam_id,ISNULL(cam_descripcion,'''''''') as cam_descripcion,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'''') as AreaName
                        from ccCamps as CAMP with(nolock) 
                        left join ccRIACat_Areas as AREas with(nolock) on CAMP.IDArea = AREas.IDArea
                        return(0)
                    end

                if @option = 1 -- select Camp
                    begin
                        select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0) as Area_Id,
                        prefijo as Prefijo
                        from ccCamps a1 with(nolock) 
                        inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
                        inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
                        where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
                        return(0)
                    end

                if @option = 4 --Delete
                    begin
                        if exists (select inbound_id from ccInbound with(nolock) where cam_id = @Cam_id)
                        begin
                        declare @error varchar(70)
                        Select @error=case valor when 0 then ''No es posible eliminar la campa?a, esta asociada a una especialidad''
                            else ''Campaign can not be deleted, it has an association with an ACD'' end
                        from ccsettings with(nolock) where setting_id = 27
                        raiserror (@error,18,1)     
                        return(0)
                        end

                        delete ccCampsHorarios with(rowlock) where cam_id = @Cam_id
                        insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id) Values(@Cam_id, 5, 0, 0, @UserId)
                        Delete ccCalifCamp with(rowlock) where cam_id = @Cam_id and tipo = 1
                        Delete ccRIACampsGraph with(rowlock) where cam_id = @Cam_id
                        delete ccHistorialListaNegra with(rowlock) where cam_id = @Cam_id
                        delete ccRIARegistryLists with(rowlock) where cam_id = @Cam_id  
                        delete ccoCallsOut with(rowlock) where cam_id = @Cam_id
                        delete ccoCallsOutSource with(rowlock) where cam_id = @Cam_id
                        delete ccCampsAgente with(rowlock) where cam_id = @Cam_id
                        return(0)
                    end

                if @option = 2 --Insert
                    begin
                    declare @new_cam_id smallint
                    declare @isAssingPortbyCam bit

                    DECLARE @CampTypeNormal INT = 0

                    if exists(select cam_descripcion from ccCamps with(nolock) where cam_descripcion = @Descripcion)
                        begin
                        select -1 --, ''Nombre en Uso''
                        return(0)  
                        end

                    -- ODC: la campa?a siempre esta activa
                    set @Activa = 1
                    declare @pref int
                    select  @pref = valor from ccSettings where setting_id = 201
                    if (@pref = 0)
                        set @Prefijo = ''''


                    Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd,prefijo, CampType)
                    select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
                    case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end, @Prefijo, @CampTypeNormal

                    if @@rowcount = 1 BEGIN
                    select @new_cam_id = scope_identity()

                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                    SELECT 
                        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
                        getDate(), 
                        (SELECT [Login] FROM ccUsers WHERE User_id = @UserId), 
                        CASE 
                            WHEN @MediaType = 6 THEN 44
                            WHEN @MediaType = 5 THEN 46
                            WHEN @MediaType = 4 OR @MediaType = 9 THEN 48 -- TODO: Delete MediaType 4
                            WHEN @MediaType = 7 THEN 50
                            ELSE 42 END, 
                        3, 
                        '''',
                        '''', 
                        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @new_cam_id);

                    END else
                        begin
                        select -2 --, ''Error al crear campa?a''
                        return(0)
                        end

                    if isnull(@MirrorInbound_Id, 0)<>0
                        begin
                        if not exists(select inbound_id from ccInbound with(nolock) where inbound_id=@MirrorInbound_Id)
                            begin
                            select -3 -- Error al asignar campa?a a ACD, el ACD no existe o no pertenece a la misma area
                            return(0)
                            end

                        update ccinbound with(rowlock) set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
                        update cccamps with(rowlock) set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
                        end
                    set @isAssingPortbyCam=1

                    select @isAssingPortbyCam=valor from ccSettings where setting_id=232

                    if @isAssingPortbyCam=1 begin
                        insert into ccoDialerCamp (dialer_id, cam_id) 
                        select dialer_id, @new_cam_id from ccoDialers with(nolock) where status = 1
                    end

                    insert into ccCalifCamp (calif_id, cam_id, tipo) 
                    select calif_id, @new_cam_id, 1 from ccTipoCalifOUT with(nolock) where CalifOut_Status = 1

                    update ccCamps set keepDial=dbo.fn_keepDial_Camps(@new_cam_id) where cam_id=@new_cam_id

                    If not exists (select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
                        begin
                        insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
                        end

                    insert into ccRIACampsGraph (cam_id, graphic_id)
                    select @new_cam_id, graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock)  where frame = @frame and type_id = 1

                    --inserta la lista negra por default
                    if (select valor from ccsettings with(nolock) where setting_id=152)=''1''
                    begin
                        declare @tempId as int = 0
                        select @tempId = idtipolista from cctiposlistanegra where Tipolista = ''defaultList/General''
                        exec ccsp_RIABlackListCamp 4, @IDArea, @new_cam_id, @tempId, null
                    end

                    --select * from cctiposlistanegra

                    select @new_cam_id
                    return(0)
                    end

                if @option = 3 -- Update
                    begin
                        if not exists(select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
                        insert into ccRIAGraphics (frame,type_id) values (@frame,1)

                        Update ccCamps with(rowlock) set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id

                        DECLARE @PrevFrame SMALLINT = (SELECT [graphic_id] FROM ccRIACampsGraph WHERE cam_id = @Cam_id);

                        update ccRIACampsGraph with(rowlock)
                        set graphic_id = (select graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
                        where cam_id = @Cam_id

                        IF(@isCreating IS NOT NULL AND @isCreating = 2 AND @PrevFrame <> (SELECT [graphic_id] FROM ccRIACampsGraph WHERE cam_id = @Cam_id) AND @module = 3) BEGIN
                            DECLARE @Media INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @Cam_id);

                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                            SELECT 
                                (SELECT CRA.[AreaName] FROM ccRIACat_Areas AS CRA, ccCamps AS CCC WHERE CRA.IDArea = CCC.IDArea AND CCC.cam_id = @Cam_id),
                                getDate(), 
                                (SELECT [Login] FROM ccUsers WHERE User_id = @UserId), 
                                CASE
                                    WHEN @Media = 6 THEN 55
                                    WHEN @Media = 5 THEN 56
                                    WHEN @MediaType = 4 OR @MediaType = 9 THEN 57 -- TODO: Delete MediaType 4
                                    WHEN @Media = 7 THEN 58
                                    ELSE 54 END, 
                                3, 
                                '''',
                                ''OUT_CALL_EDIT_ICON'', 
                                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @Cam_id);
                        END

                        return(0)
                    end

                    if @option = 5 --Obtener relaciones de campa?as - campa?as
                    begin
                        if not exists (select cam_id from ccCamps with(nolock) where cam_id = @Cam_id) or
                        (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
                        not exists (select cam_id from ccCamps with(nolock) where cam_id=@descripcion))
                        begin
                        select -3 -- Campa?a invalida
                        return(0)
                        end
                                
                    if @descripcion=0
                        set @descripcion = null

                    update ccCamps with(rowlock) set surveyCamId = @descripcion where cam_id = @Cam_id
                    if @@rowcount=0
                        select -4 -- Error al actualizar
                                    
                    else
                        begin
                        delete cccalifcamp with(rowlock) where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

                        end

                    return(0)
                    end

                if @option = 6
                    begin
                        select cam_id, isnull(surveycamid,0)
                        from cccamps with(index(PK_ccCamps),nolock)
                        where cam_id = @Cam_id
                        return(0)
                    end

                if @option = 7 -- Checa si la campa?a no tiene grabaciones y se puede modificar el prefijo
                    begin   
                        select count(*) as Grabaciones from ccoCallsOut where cam_id = @Cam_id
                        --select 0 as Grabaciones   
                    end

                if @option = 8 -- Checa si la campa?a tiene asignada una campa?a tipo encuesta
                    begin   
                        SELECT CAST(CASE WHEN  isnull(surveycamid,0) != 0 THEN 1 ELSE 0 END AS bit)
                        from cccamps with(index(PK_ccCamps),nolock)
                        where cam_id = @Cam_id
                        return(0)
                    end

                return(0)
                set nocount off
    '
    EXEC(@sql)

    SET @process = 'Se agregan nuevas configuraciones al procedimiento de guardado'
	SET @sql= '
    CREATE PROCEDURE [dbo].[ccsp_RIAConfCamp]
        @User_id SMALLINT,
        @campID INT = NULL
    AS
        SET NOCOUNT ON;

        DECLARE @tableExistsRec TABLE (
            camId INT PRIMARY KEY,
            existRec BIT
        );
        DECLARE @camByUser TABLE (
            camId INT PRIMARY KEY,
            isCheck BIT
        );
        DECLARE @camId INT, @id INT;
        DECLARE @intenationalDialingPorts BIT;
        DECLARE @tempInternationalCode INT;

        IF (
            SELECT COUNT(*)
            FROM (
                SELECT TOP 1 IdCode
                FROM ccoDialers ccoDial
                INNER JOIN ccoDialerCamp ccoDialCamp ON ccoDialCamp.dialer_id = ccoDial.dialer_id
                WHERE ccoDialCamp.cam_id = @campID
                    AND ccoDial.DialingType = 0
            ) result
        ) > 0
        BEGIN
            SET @intenationalDialingPorts = 1;
        END
        ELSE
        BEGIN
            SET @intenationalDialingPorts = 0;
        END;

        IF NOT EXISTS (
            SELECT *
            FROM ccUsers_Roles
            WHERE User_id = @User_id
                AND Rol_id = 7
        )
        BEGIN
            INSERT INTO @camByUser
            SELECT *, 0
            FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
            WHERE @campID IS NULL
                OR cam_id = @campID;
        END
        ELSE
        BEGIN
            INSERT INTO @camByUser
            SELECT cam_id, 0
            FROM ccCamps
            WHERE (IDArea > 0 OR IDArea IS NULL)
                AND (@campID IS NULL OR cam_id = @campID);
        END;

        WHILE EXISTS (
            SELECT *
            FROM @camByUser
            WHERE isCheck = 0
        )
        BEGIN
            SELECT TOP 1 @camId = camId
            FROM @camByUser
            WHERE isCheck = 0;

            IF EXISTS (
                SELECT cam_id
                FROM ccoCallsOut
                WHERE cam_id = @camId
            )
            BEGIN
                INSERT INTO @tableExistsRec
                VALUES (@camId, 1);
            END
            ELSE
            BEGIN
                INSERT INTO @tableExistsRec
                VALUES (@camId, 0);
            END;

            UPDATE @camByUser
            SET isCheck = 1
            WHERE camId = @camId;
        END;

        SELECT 
            a1.cam_id,
            cam_Descripcion,
            cam_tNotas,
            CAST(cam_ocupado AS INT) AS cam_ocupado,
            cam_noInt_ocupado,
            cam_inter_ocupado,
            CAST(cam_nocontesto AS INT) AS cam_nocontesto,
            cam_noInt_nocontesto,
            cam_inter_nocontesto,
            CAST(cam_fax AS INT) AS cam_fax,
            cam_noInt_fax,
            cam_inter_fax,
            CAST(cam_modomanual AS INT) AS cam_modomanual,
            ANI,
            cam_ShowCalifWnd,
            cam_StartTimerOnHangUp,
            editableCallKey,
            cam_tNoContesta,
            iTipoDial,
            detectAnswerMachine,
            detectVoiceMail,
            compliance,
            cam_inter_graba,
            cam_noint_graba,
            CAST(progDial AS TINYINT) progDial,
            CAST(excCallBack AS TINYINT) excCallBack,
            dialOrder,
            dialPrefix,
            dialPrefixMan,
            dialPrefixXfe,
            listenManualCall,
            stopRecording,
            CAST(abandonCallback AS TINYINT) abandonCallback,
            a3.frame,
            a1.t_autoCB,
            a1.id_anilist,
            a1.tDialonWrapUp,
            dbo.fn_viewMode(@User_id, 10) viewMode,
            cam_maxqueue AS queSize,
            DNCScrub,
            callerIdDesc,
            timeZoneRule,
            callsBySurvey,
            ivrScript,
            surveyPctg,
            ISNULL(a1.call_record, 1) AS call_record,
            CAST(startStopRecording AS TINYINT) startStopRecording,
            leaveRecMessage,
            manualCallOnChat,
            callBackSurveyAgent,
            callBackSurveyClient,
            CASE 
                WHEN surveycamid IS NULL OR surveycamid = 0 THEN 0
                ELSE 1
            END isRelationSurvey,
            ISNULL(a1.funcEspDtmf, 0),
            ISNULL(sipHdrFormat, '''') sipHdrFormat,
            cam_inter_cancelled,
            prefijo,
            enbleprefix = CASE 
                WHEN existRec = 0 THEN 1
                ELSE 0
            END,
            ISNULL(exitAssisted, 0) exitAssisted,
            ISNULL(previewDiscard, 0) PreviewDiscard,
            case when CampType = 9 then 10 else ISNULL(CampType, 0) end as CampType,
            ISNULL(contact.conexionInfo, '''') conexionInfo,
            ISNULL(contact.connUser, '''') connUser,
            ISNULL(contact.closeConversationTime, 0) closeConversationTime,
            ISNULL(contact.answerTimeoutClient, 0) answerTimeoutClient,
            ISNULL(contact.allowFileAttachments, 0) allowFileAttachments,
            ISNULL(selectRotativeANI, 0) selectRotativeANI,
            ISNULL(rotativeAlgo, 0) rotativeAlgo,
            ISNULL(autoStart, 0) autoStart,
            ISNULL(messagingOrder, 0) messagingOrder,
            ISNULL(cam_tPreview, 0) AS CamTPreview,
            ISNULL(timesPreview, 0) AS TimesPreview,
            ISNULL(timesDiscard, 0) TimesDiscard,
            ISNULL(recordHold, 0) recordHold,
            ISNULL(campsExtention.zipCodeSchedule, 0) ZipCodeSchedule,
            ISNULL(campsExtention.RecordCalls, 1) RecordCalls,
            ISNULL(campsExtention.simultaneousRecs, 1) simultaneousRecs,
            ISNULL(campsExtention.EditableContactData, 0) EditableContactData,
            @intenationalDialingPorts intenationalDialingPorts,
            ISNULL(campsExtention.AssignConversationSameAgent, 0) AssignConversationSameAgent,
            ISNULL(contact.maxLimitQueueConversations, 99) maxLimitQueueConversations,
            ISNULL(contact.MaxDaysPerWAConvo, 5) MaxDaysPerWAConvo,
            -- Outbound AI Campaign Special Settings
            ISNULL(campsExtention.RescheduledSurveyAI, 0) RescheduledSurveyAI,
            ISNULL(campsExtention.ImmediateSurveyAI, 0) ImmediateSurveyAI,
            ISNULL(campsExtention.ApplyRescheduledSurveyForCompletedCallsAI, 0) ApplyRescheduledSurveyForCompletedCallsAI,
            ISNULL(campsExtention.EnableCallRecordingAI, 0) EnableCallRecordingAI
        FROM ccCamps a1
        INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
        INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
        INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
        LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
        LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
        ORDER BY cam_descripcion;

        RETURN (0);

        SET NOCOUNT OFF;
    '
    EXEC(@sql)

    SET @process = 'Se agregan nuevas configuraciones al procedimiento de actualización'
	SET @sql= '
    CREATE PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
        @cam_id SMALLINT,
        @zipCodeSchedule BIT = NULL,
        @userId SMALLINT = NULL,
        @idArea SMALLINT = NULL, 
        @isCreating SMALLINT = NULL,
        @simultaneousRecs SMALLINT = NULL,
        @module INT = -1,
        @recordCalls TINYINT = 1,
        @editableContactData BIT = 1,
        @assignConversationSameAgent BIT = 0,
        @RescheduledSurveyAI BIT = 0,
        @ImmediateSurveyAI BIT = 0,
        @ApplyRescheduledSurveyForCompletedCallsAI BIT = 0,
        @EnableCallRecordingAI BIT = 1
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @country INT = (SELECT valor FROM ccSettings WHERE setting_id = 104); 
        DECLARE @excludeIdentifier VARCHAR(255) = CASE WHEN @country = 4 THEN ''COMMON_INTERNATIONAL_RECORD_CALLS'' ELSE ''COMMON_USA_RECORD_CALLS'' END;

        IF EXISTS (SELECT * FROM ccCampsExtend WHERE cam_id = @cam_id) 
        BEGIN
            EXEC InsertLogAdminGalatea @action = 1, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userId;

            IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable;

            CREATE TABLE #ccCampsExtendTable 
            (
                columnInfo VARCHAR(255),
                dataInfo VARCHAR(255),
                identifierInfo VARCHAR(255)
            );

            DECLARE @Camptype INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @cam_id);
            DECLARE @operation SMALLINT = CASE 
                WHEN @isCreating = 1 THEN 
                    CASE 
                        WHEN @Camptype = 6 THEN 44
                        WHEN @Camptype = 5 THEN 46
                        WHEN @Camptype = 4 OR @Camptype = 9 THEN 48 -- TODO: Delete MediaType 4
                        WHEN @Camptype = 7 THEN 50
                        ELSE 42 
                    END
                ELSE 
                    CASE 
                        WHEN @Camptype = 6 THEN 55
                        WHEN @Camptype = 5 THEN 56
                        WHEN @Camptype = 4 OR @Camptype = 9 THEN 57 -- TODO: Delete MediaType 4
                        WHEN @Camptype = 7 THEN 58
                        ELSE 54 
                    END
                END;

            UPDATE ccCampsExtend
            SET
                zipCodeSchedule = ISNULL(@zipCodeSchedule, zipCodeSchedule),
                simultaneousRecs = ISNULL(@simultaneousRecs, simultaneousRecs),
                RecordCalls = ISNULL(@recordCalls, RecordCalls),
                EditableContactData = ISNULL(@editableContactData, EditableContactData),
                AssignConversationSameAgent = ISNULL(@assignConversationSameAgent, AssignConversationSameAgent),
                -- Outbound AI Campaign Special Settings
                RescheduledSurveyAI = ISNULL(@RescheduledSurveyAI, RescheduledSurveyAI),
                ImmediateSurveyAI = ISNULL(@ImmediateSurveyAI, ImmediateSurveyAI),
                ApplyRescheduledSurveyForCompletedCallsAI = ISNULL(@ApplyRescheduledSurveyForCompletedCallsAI, ApplyRescheduledSurveyForCompletedCallsAI),
                EnableCallRecordingAI = ISNULL(@EnableCallRecordingAI, EnableCallRecordingAI)
            WHERE cam_id = @cam_id;

            IF (@isCreating > 0 AND @module > -1) 
                EXEC InsertLogAdminGalatea @action = 2, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userId, @tableTemp = ''#ccCampsExtendTable'';

            IF (@idArea IS NULL OR @idArea = -1) 
                SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id);

            IF (@isCreating = 1) 
                DELETE FROM #ccCampsExtendTable WHERE identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') AND dataInfo = 0;

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
            SELECT 
                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
                GETDATE(), 
                (SELECT [Login] FROM ccUsers WHERE User_id = @userId), 
                @operation, 
                @module, 
                CCCE.identifierInfo,
                CASE 
                    WHEN CCCE.identifierInfo IS NOT NULL AND CCCE.identifierInfo <> '''' THEN
                        CASE 
                            WHEN CCCE.identifierInfo IN (''SETTINGS_CHANGED_AREAS_ZIP'', ''COMMON_INTERNATIONAL_RECORD_CALLS'', ''EDIT_CALL_DATASET'') THEN
                                CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                            WHEN @isCreating = 1 THEN
                                CASE WHEN CCCE.identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') THEN
                                    CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' END
                                END
                            WHEN @isCreating = 2 THEN
                                CASE WHEN CCCE.identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') THEN
                                    CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                                END
                            WHEN CCCE.identifierInfo IN (''COMMON_USA_RECORD_CALLS'') THEN
                                CASE 
                                    WHEN CCCE.dataInfo = 1 THEN ''COMMON_USA_RECORD_CALLS_MODE_ALL''
                                    WHEN CCCE.dataInfo = 2 THEN ''COMMON_USA_RECORD_CALLS_MODE_AUTH''
                                    WHEN CCCE.dataInfo = 4 THEN ''COMMON_USA_RECORD_CALLS_MODE_NOAUTH''
                                    ELSE ''COMMON_DISABLED'' 
                                END
                            ELSE CCCE.dataInfo 
                        END
                    ELSE '''' 
                END,
                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
            FROM #ccCampsExtendTable AS CCCE WHERE CCCE.identifierInfo != @excludeIdentifier;

            EXEC InsertLogAdminGalatea @action = 3, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userId;

            IF OBJECT_ID(N''tempdb..#ccCampsExtendTable'') IS NOT NULL DROP TABLE #ccCampsExtendTable;

        END
        ELSE 
        BEGIN
            INSERT INTO ccCampsExtend (
                cam_id, 
                zipCodeSchedule, 
                SimultaneousRecs, 
                RecordCalls, 
                AssignConversationSameAgent, 
                RescheduledSurveyAI, 
                ImmediateSurveyAI, 
                ApplyRescheduledSurveyForCompletedCallsAI, 
                EnableCallRecordingAI
            ) 
            VALUES (
                ISNULL(@cam_id, 0),                     
                ISNULL(@zipCodeSchedule, ''''),           
                ISNULL(@simultaneousRecs, 0),           
                ISNULL(@recordCalls, 0),                
                ISNULL(@assignConversationSameAgent, 0),
                -- Outbound AI Campaign Special Settings
                ISNULL(@RescheduledSurveyAI, 0),        
                ISNULL(@ImmediateSurveyAI, 0),          
                ISNULL(@ApplyRescheduledSurveyForCompletedCallsAI, 0),
                ISNULL(@EnableCallRecordingAI, 1)
            );

            UPDATE ccCamps SET call_record = @recordCalls WHERE cam_id = @cam_id;

            SET NOCOUNT OFF;
        END
    END'
    EXEC(@sql)
    ------------------------- END Ivan Martin Enciso          --------------------------------------------
	-------------------------BEGIN FRIDA ORTA-------------------------------------------------------------
	 SET @process = 'DEV2-825 delete sp ccsp_RIALoadCamps'
    SET @sql = '
    IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = N''ccsp_RIALoadCamps'')
    BEGIN
        DROP PROCEDURE ccsp_RIALoadCamps
    END'
    EXEC(@sql)
	SET @process = 'DEV2-825 create sp ccsp_RIALoadCamps'
    SET @sql = '        
CREATE PROCEDURE ccsp_RIALoadCamps @option SMALLINT, @AreaId SMALLINT = NULL, @Sup SMALLINT = NULL, @WGID SMALLINT = NULL
AS
SET NOCOUNT ON

DECLARE @loginDays INT

SET @loginDays = 0

IF @option = 1 -- Todas las campa?as
BEGIN
    SELECT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0), isnull(DNCscrub, 0)
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    WHERE a3.type_id = 1 AND a1.cam_id IN (
            SELECT cam_id
            FROM dbo.fGet_CampAcd_Area(@Sup, 1)
            )
    ORDER BY 5, 2

    RETURN (0)
END

IF @option = 2 -- Campa?as de un Area
BEGIN
    SELECT DISTINCT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG, CASE WHEN a1.ivrScript <> 0 AND a1.callsBySurvey <> 0 THEN 8 ELSE ISNULL(a1.CampType, 0) END as mode
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
    ORDER BY cam_descripcion

    RETURN (0)
END

IF @option = 3 -- Campa?as por Supervisor
BEGIN
    SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(a1.IDArea, 0) IDArea
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    JOIN ccSupervisorCam a4 ON a1.cam_id = a4.cam_id
    WHERE a3.type_id = 1 AND a4.tipo = 1 AND a4.user_id = @Sup
    ORDER BY 5, 2

    RETURN (0)
END

IF @option = 4 -- Rels Camps-Agents
BEGIN
    SELECT @loginDays = valor
    FROM ccSettings
    WHERE setting_id = 211 --Numero dias que cargara las relaciones

    SELECT LOGIN, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea, min(rel_id) rel_id
    FROM (
        SELECT A.LOGIN, A.User_id, Prioridad, Skill, C.cam_id, C.cam_descripcion, isnull(C.IDArea, 0) IDArea, CA.rel_id
        FROM ccCamps C
        JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id
        JOIN ccRIACampsGraph a2 ON C.cam_id = a2.cam_id
        JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
        JOIN ccUsers A ON A.User_id = CA.User_id AND A.TipoUser_id = 1 AND A.STATUS = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays)
        WHERE C.cam_id IN (
                SELECT cam_id
                FROM ccsupervisorcam
                WHERE user_id = CASE isnull(@Sup, 0) WHEN 0 THEN user_id ELSE @Sup END AND tipo = 1
                )
        ) Relations
    GROUP BY LOGIN, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea
    ORDER BY User_id, cam_descripcion, cam_id, Prioridad

    RETURN (0)
END

IF @option = 5 -- Campa?as por Supervisor
BEGIN
    SELECT @AreaId = IDArea
    FROM ccUsers
    WHERE User_id = @sup

    SELECT DISTINCT Camps.cam_id, Camps.cam_descripcion, a3.frame, Camps.cam_procesando, isnull(Camps.IDArea, 0) IDArea, IsNull(CN.New, 0) AS New, IsNull(CN.CB, 0) AS CB, IsNull(CN.Pro, 0) AS Pro, IsNull(CN.pen, 0) AS Pen, cast(Camps.cam_procesando AS INT) AS St, Camps.cam_TipoJobs AS Job, isnull(CN.Fin, 0) Fin, isnull(CP.prioridad, ''12345NNN'') prioridad, cast(camps.dialorder AS TINYINT) dialorder, cast(camps.progDial AS TINYINT) progDial, U.monitored, Camps.aggressionFactor
    FROM ccCamps Camps
    LEFT JOIN ccCampsPrioridadTel CP ON CP.cam_id = Camps.cam_id
    LEFT JOIN ccCampsNvosCB CN ON CN.id = Camps.cam_id
    JOIN ccRIACampsGraph a2 ON (Camps.cam_id = a2.cam_id)
    JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
    JOIN ccSupervisorCam U ON Camps.cam_id = U.cam_id
    WHERE U.user_id = @sup AND tipo = 1 AND a3.type_id = 1 AND Camps.cam_id IN (
            SELECT cam_id
            FROM ccSupervisorCam
            WHERE tipo = 1 AND user_id = @sup
            ) AND Camps.IDArea = @AreaId
    ORDER BY 5, cam_procesando DESC, cam_descripcion

    RETURN (0)
END

IF @option = 7 -- Una sola
BEGIN
    SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(IDArea, 0) IDArea, isnull(DNCscrub, 0) DNCScrub
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    WHERE a3.type_id = 1 AND isnull(a1.cam_id, 0) = isnull(@AreaId, 0)
    ORDER BY 5, 2

    RETURN (0)
END

IF @option = 8 -- Campa?as de un Agente
BEGIN
    SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    JOIN ccCampsAgente a4 ON a1.cam_id = a4.cam_id
    WHERE a3.type_id = 1 AND a4.user_id = @Sup
    ORDER BY 2

    RETURN (0)
END
IF @option = 9 -- Campa?as de un Area
BEGIN
    (SELECT DISTINCT a1.cam_id as CamID, cam_descripcion as CamDescription, frame as Frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) as RelationsWG,
	1 CamType, 
    ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 1 and IdCampEsp = a1.cam_id and IDWG = @WGID group by IdCampEsp),0) IsAssignedToCurrentWG,
    CAST(CASE WHEN a1.progDial = 3 THEN 6 WHEN a1.CampType = 4 THEN 4 WHEN a1.CampType = 5 THEN 5 WHEN a1.CampType=7 THEN 7 WHEN a1.ivrScript <> 0 AND a1.callsBySurvey <> 0 THEN 8 WHEN a1.CampType = 9 THEN 9  ELSE 0 END as [tinyint]) [MediaType]
	FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
    UNION
    SELECT DISTINCT b1.inbound_id, descripcion, frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(b1.inbound_id, 2) relationsWG, 0 CampType, 
    ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 0 and IdCampEsp = b1.inbound_id and IDWG = @WGID group by IdCampEsp),0) isAssignedToCurrentWG,
    b1.chat [MediaType]
    FROM ccinbound b1
    JOIN ccRIAinboundGraph b2 ON b1.inbound_id = b2.inbound_id
    INNER JOIN ccRIAGraphics b3 ON b2.graphic_id = b3.graphic_id
    LEFT JOIN (
        SELECT inbound_id, CASE WHEN (sum(skill) / count(user_id)) = max(skill) THEN 0 ELSE 1 END skillDif
        FROM ccSkills
        GROUP BY inbound_id
        ) S ON S.Inbound_id = b1.inbound_id
    WHERE b3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
    ) ORDER BY camtype desc,cam_descripcion

    RETURN (0)
END

RETURN (0)

SET NOCOUNT OFF
'
    EXEC(@sql)
	-------------------------END FRIDA ORTA-------------------------------------------------------------

	------------------------- BEGIN LRSV -----------------------------------------------------------

	set @process = 'K070042 Se agregan cambios para regresar OutboundType 10 si es de IA'
	set @sql = '
		if exists (select 1 from sys.procedures where name = N''ccsp_GalateaAdminCampaigns'')
		begin
			DROP PROCEDURE ccsp_GalateaAdminCampaigns;
		end'
	EXEC(@sql)

	set @process = 'K070042 Se agregan cambios para regresar OutboundType 10 si es de IA'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns]
					@Option AS      SMALLINT, 
					@CampType AS    SMALLINT = 0, 
					@WorkgroupId AS INT      = 0, 
					@Id AS          INT      = 0, 
					@AdminId AS     SMALLINT = 0, 
					@PinUpdate AS   SMALLINT = 0, 
					@LoadId AS      INT      = 0, 
					@Type AS        SMALLINT = 0,
					@InboundType    SMALLINT = 0,
					@AreaId         SMALLINT = 0,
					@multi_type     varchar(max) = null,
					@IsWhatsAppCampaign  bit = 0,
					@groupList as varchar (MAX) = NULL
					AS
					BEGIN
						SET NOCOUNT ON;
					IF @Option = 1 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type     
						IF @WorkgroupId IS NOT NULL BEGIN
							SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId
							ORDER BY IdCampEsp ASC;
						END;
						ELSE BEGIN
							RAISERROR(''ERROR. No existe una lista de campañas con el id de grupo de trabajo especificado'', 18, 1);
						END;
						RETURN 0;
					END;
					IF @Option = 2 BEGIN-- Get Campaign complete information per Campaign Type and Campaign Id      
						IF @CampType = 1 BEGIN-- Campaigns Out      
							IF @Id IS NOT NULL BEGIN
								SELECT DISTINCT 
								CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
								isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
								camps.cam_procesando IsStarted, 
								ISNULL(a.AreaName, '''') AS Area, 
								CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
								CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
								CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10  ELSE isnull(camps.CampType,0) END as OutboundType,
								ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
								a.ToolsTransfer         
								FROM ccCamps camps
								LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
								LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
								LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
								WHERE camps.cam_id = @Id
								ORDER BY camps.cam_descripcion ASC;
							END;
							ELSE BEGIN
								RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
							END;
						END;
						ELSE IF @CampType = 0 -- Campaigns In (ACD)
							BEGIN
								IF @Id IS NOT NULL
									BEGIN
										SELECT DISTINCT 
										CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, 
										ISNULL(a.AreaName, '''') AS Area, 
												CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType,
												a.ToolsTransfer
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
					ELSE IF @Option = 3  BEGIN -- Update OverallTotalNew By Campaign

						IF @Id IS NOT NULL BEGIN
							UPDATE ccCampsNvosCB SET  OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id;
						END;
						ELSE BEGIN
							RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
						END;
						RETURN 0;
					END;
					ELSE IF @Option = 4 -- Update Pin from Campaign per Admin
					BEGIN
						IF @Id IS NOT NULL
							AND @AdminId IS NOT NULL
						BEGIN
							IF @PinUpdate = 1
							BEGIN
								INSERT INTO PinedCampaigns (CampId, AdminId, Type)
								VALUES (@Id, @AdminId, @Type);
							END;

							IF @PinUpdate = 0
							BEGIN
								DELETE
								FROM PinedCampaigns
								WHERE CampId = @Id
									AND AdminId = @AdminId
									AND Type = @Type;
							END;
						END;
						ELSE
						BEGIN
							RAISERROR (''ERROR. La campañas o administrador no existen'', 18, 1
									);
						END;

						RETURN 0;
					END;

					ELSE IF @Option = 5 BEGIN  -- Get Pin from Campaign Ids per Admin       
						IF @AdminId IS NOT NULL BEGIN
							SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
							ORDER BY Id ASC;
						END;
						ELSE BEGIN
							RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
						END;
						RETURN 0;
					END;
					ELSE IF @Option = 6 -- Get Blacklist Ids by Campaign Id
					BEGIN
						IF @Id IS NOT NULL
						BEGIN
							DECLARE @BlackListIds VARCHAR(MAX);

							SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR
										(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
							FROM Camplistanegra
							WHERE cam_id = @Id
								AND STATUS = 1;

							SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
						END;
						ELSE
						BEGIN
							RAISERROR (''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
						END;

						RETURN 0;
					END;
            
					ELSE IF @Option = 7 -- Get RegistryListIds Ids by Campaign Id
					BEGIN
						IF (
								@Id IS NOT NULL
								AND EXISTS (
									SELECT *
									FROM cccamps
									WHERE cam_id = @Id
									)
								)
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
							RAISERROR (''ERROR. No existe una campaña con el id especificado'', 18, 1);
						END;

						RETURN 0;
					END;

					ELSE IF @Option = 8 -- Delete RegistryListIds Ids by LoadId
					BEGIN
						IF (
								@LoadId IS NOT NULL
								AND EXISTS (
									SELECT *
									FROM ccRIARegistryLists
									WHERE list_id = @loadID
										AND STATUS <> 0
									)
								)
						BEGIN
							UPDATE ccoCallsOutSource
							SET cal_status = ''5''
							WHERE list_id = @loadID;

							DELETE
							FROM ccoWorkingTable
							WHERE list_id = @LoadId;

							EXEC ccsp_RIARegistryLists @action = 6, @list_id = @LoadId;
						END;
						ELSE
						BEGIN
							--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
							RAISERROR (''ERROR. No existe una carga el id especificado'', 18, 1);
						END;

						RETURN 0;
					END;

					ELSE IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
					BEGIN
						DECLARE @table TABLE (camId INT, campType TINYINT, PRIMARY KEY (camId, campType)
							);

						INSERT INTO @table
						SELECT DISTINCT IdCampEsp, Tipo
						FROM ccRIACampEspWG wg
						WHERE wg.IDWG IN (
								SELECT IDWG
								FROM ccRIAWorkGroupUsers
								WHERE IDWG <> @WorkgroupId
									AND User_id = @AdminId
								);

						SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
						FROM @table A
						RIGHT JOIN (
							SELECT wg.IdCampEsp, wg.Tipo
							FROM ccRIACampEspWG wg
							WHERE wg.IDWG = @WorkgroupId
							) B ON A.camId = B.IdCampEsp
							AND A.campType = B.Tipo
						WHERE A.camId IS NULL
						ORDER BY IdCampEsp;

						RETURN 0;
					END;

					ELSE IF @option = 10 BEGIN -- Get Agents States with totals per campaign by admin id and campaign type **********************
						DECLARE @date DATETIME = CONVERT(DATE, DATEADD(hh, - 3, GETDATE()));
						DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY (id));
						DECLARE @AgentsList TABLE (id INT, PRIMARY KEY (id));
						DECLARE @tmpCamAgent TABLE (
							camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY (camId, userId
								)  
							);
						DECLARE @AgentStatus TABLE (CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT
							);
						DECLARE @CurrentStatus TABLE (userId INT, CurrentState INT, IdCampEsp INT, camType INT
							);
						DECLARE @campDataTotal TABLE (
							camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY (camId
								)
							);

						INSERT INTO @AdminWorkgroups
						SELECT DISTINCT IDWG
						FROM ccRIAWorkGroupUsers WG, ccUsers_Roles R
						WHERE WG.User_id = @AdminId 
							OR (
								R.User_id = @AdminId
								AND R.Rol_id = 7
								);

						INSERT INTO @AgentsList
						SELECT DISTINCT A.User_id
						FROM ccRIAWorkGroupUsers A
						INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
						INNER JOIN ccUsers C ON A.User_id = C.User_id
							AND C.TipoUser_id = 1
						ORDER BY A.User_id;

						IF @IsWhatsAppCampaign  = 1
						BEGIN
							INSERT INTO @tmpCamAgent --Obtiene las relaciones entre agentes y campañas
							SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, CASE WHEN @Id = 0
										AND @CampType = 0 THEN inbound.chat ELSE NULL END
							FROM ccRIACampEspWG campPerWg
							INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
							INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
							INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
							LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp
								AND @CampType = 0
							LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp
								AND @CampType = 1
							WHERE C.TipoUser_id = 1  
								AND (camps.CampType = 5 or inbound.chat = 5)
								AND campPerWg.Tipo = @CampType
								AND (
									@Id = 0
									OR campPerWg.IdCampEsp = @Id
									);
						END
						ELSE
						BEGIN
							INSERT INTO @tmpCamAgent
							SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, CASE WHEN @Id = 0
										AND @CampType = 0 THEN inbound.chat ELSE NULL END
							FROM ccRIACampEspWG campPerWg
							INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
							INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
							INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
							LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp
								AND @CampType = 0
							LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp
								AND @CampType = 1
							WHERE C.TipoUser_id = 1
								AND campPerWg.Tipo = @CampType
								AND (
									@Id = 0
									OR campPerWg.IdCampEsp = @Id
									);
						END;

						WITH lastState
						AS (
							SELECT A.user_id, MAX(A.fecha) AS fecha
							FROM ccLogAgentesDiaViewLast A
							INNER JOIN @AgentsList B ON A.User_id = B.id
							WHERE fecha >= @date
							GROUP BY user_id
							)
						INSERT INTO @CurrentStatus
						SELECT B.User_id, CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS 
							currentStatus, B.IdCampEsp, B.Tipo
						FROM lastState A
						INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
							AND A.fecha = B.fecha;

						IF @Id = 0
							AND @CampType = 0
						BEGIN
							DELETE
							FROM @tmpCamAgent
							WHERE multimediaType = 0
						END

						DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;

						IF @CampType = 1
						BEGIN
							SELECT @MultimediaType = meanContactTypeId
							FROM contactMeanOut
							WHERE camp_id = @Id
						END
						ELSE
						BEGIN
							SELECT @chatType = ci.chat
							FROM dbo.ccInbound AS ci
							WHERE ci.Inbound_id = @Id;

							SELECT @MultimediaType = meanContactTypeId
							FROM contactMeanIn
							WHERE inboundId = @Id
						END

						IF (@chatType = 1)
						BEGIN
							SET @MultimediaType = 1
						END

						DECLARE @StateIds VARCHAR(100) = (
								SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN 
												''23'' ELSE ''4,5,6,9'' END
								) -- Add more for multimediaTypes

						;with stateDialog as(
						SELECT cast(value as int) as CurrentState FROM dbo.fn_RIASplitDelimited(@StateIds,'','')
					)
						INSERT INTO @AgentStatus
						SELECT A.camId, A.userId, B.CurrentState,
						(CASE
							WHEN @chatType = 1 THEN
								CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) THEN 1 ELSE 0 END
							ELSE
								CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN 1 ELSE 0
							END
						END) AS isCampDialog, B.camType

						FROM @tmpCamAgent A
						INNER JOIN @CurrentStatus B ON A.userId = B.userId
						WHERE (
								@Id = 0
								OR A.camId = @Id
								)

						IF @CampType = 1
						BEGIN
								;

							WITH campDataTotal
							AS (
								SELECT camId, count(*) total
								FROM @tmpCamAgent A
								GROUP BY camId
								)
							INSERT INTO @campDataTotal
							SELECT A.camId, B.cam_descripcion AS campName, A.Total, C.AreaName AS Area
							FROM campDataTotal A
							INNER JOIN ccCamps B ON A.camId = B.cam_id
							INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
						END
						ELSE
						BEGIN
								;

							WITH campDataTotal
							AS (
								SELECT camId, count(*) total
								FROM @tmpCamAgent A
								GROUP BY camId
								)
							INSERT INTO @campDataTotal
							SELECT A.camId, B.descripcion AS campName, A.Total, C.AreaName AS Area
							FROM campDataTotal A
							INNER JOIN ccInbound B ON A.camId = B.Inbound_id
							INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
						END;

						WITH stateCamp
						AS (
							SELECT A.CampId, count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready, 
								count(CASE WHEN A.CurrentState NOT IN (- 2, - 1, 0, 3, 4, 5, 6, 9, 30, 34, 37
												) THEN 1 WHEN A.CurrentState IN (6, 4
												)
											AND (
												A.CampId != C.IdCampEsp
												OR A.campType != @CampType
												) THEN 1 ELSE NULL END) AS notReady,
												COUNT(CASE WHEN A.isCampDialog = 1 OR A.CurrentState = 34 THEN 1 ELSE NULL END) AS dialog, 
												COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected,
						COUNT(CASE WHEN A.CurrentState = 37 THEN 1 ELSE NULL END) AS auxiliaryReady
							FROM @AgentStatus A
							INNER JOIN @CurrentStatus C ON A.userId = C.userId
							GROUP BY A.CampId
							)
						SELECT A.camId, A.campName, A.Total, ISNULL(B.ready, 0) AS Ready, ISNULL(B.notReady, 
								0) AS NotReady, ISNULL(B.dialog, 0) AS Dialog, CASE WHEN B.disconnected IS NULL 
									THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady - B.auxiliaryReady END 
							Disconnected, ISNULL(B.auxiliaryReady, 0) AS AuxiliaryReady,A.Area
						FROM @campDataTotal A
						LEFT JOIN stateCamp B ON A.camId = B.CampId
						ORDER BY A.campName

						RETURN 0;
					END; -- *****************************************************************************************
					ELSE IF @Option = 11 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
						IF NOT EXISTS (
								SELECT *
								FROM ccUsers_Roles WITH (NOLOCK)
								WHERE User_id = @AdminId
									AND Rol_id = 7
								)
						BEGIN
							--print ''xxxx SIn Super''
								;

							WITH wgId
							AS (
								SELECT IDWG
								FROM ccRIAWorkGroupUsers WITH (NOLOCK)
								WHERE user_id = @AdminId
								)
							SELECT DISTINCT CAST(IdCampEsp AS INT) AS Id
							INTO #tempIds
							FROM ccRIACampEspWG A WITH (NOLOCK)
							INNER JOIN wgId ON wgId.IDWG = A.IDWG
								AND A.Tipo = @CampType;
	
							IF(@CampType = 1)
							BEGIN
								SELECT Id FROM #tempIds ids
								INNER JOIN ccCamps c on c.cam_id = ids.Id
								WHERE (c.CampType = 5 AND @IsWhatsAppCampaign = 1) 
								OR (c.CampType <> 5 AND @IsWhatsAppCampaign = 0)
							END
							ELSE
							BEGIN
								SELECT Id FROM #tempIds ids
								INNER JOIN ccInbound c on c.Inbound_id = ids.Id
								WHERE (c.chat = 5 AND @IsWhatsAppCampaign = 1) 
								OR (c.chat <> 5 AND @IsWhatsAppCampaign = 0)
							END
							DROP TABLE #tempIds
						END;
						ELSE
						BEGIN
							--print ''xxxx Super''
							IF @CampType = 1
							BEGIN
								SELECT DISTINCT CAST(cam_id AS INT) AS Id
								FROM ccCamps WITH (NOLOCK)
								WHERE IDArea IS NOT NULL
								AND(CampType = 5 AND @IsWhatsAppCampaign = 1) 
								OR (CampType <> 5 AND @IsWhatsAppCampaign = 0)
							END
							ELSE
							BEGIN
								SELECT DISTINCT CAST(Inbound_id AS INT) AS Id
								FROM ccInbound WITH (NOLOCK)
								WHERE IDArea IS NOT NULL
								AND (chat = 5 AND @IsWhatsAppCampaign = 1) 
								OR (chat <> 5 AND @IsWhatsAppCampaign = 0)
							END
						END;

						RETURN 0;
					END;

					ELSE IF @Option = 12 BEGIN-- Get All Campaigns complete information per Campaign Type and Campaign Id
						IF @CampType = 1 -- Campaigns Out
						BEGIN
										SELECT DISTINCT 
										CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
										isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
										camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
										CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, 
										CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10 ELSE isnull(camps.CampType,0) END as OutboundType,
										ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
							FROM ccCamps camps(NOLOCK)
							INNER JOIN ccRIACampsGraph graph(NOLOCK) ON camps.cam_id = graph.cam_id
							INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = camps.IDArea
							LEFT JOIN ccCampsExtend extended(NOLOCK) ON camps.cam_id = extended.cam_id
							ORDER BY camps.cam_descripcion ASC;
						END;
						ELSE
						BEGIN
							SELECT DISTINCT CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, isnull
								(CAST(graph.graphic_id AS INT), 1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(
									inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea AS INT) AS 
								AreaId, inb.chat AS InboundType, 0 AS OutboundType
							FROM ccInbound inb(NOLOCK)
												INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
							INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = inb.IDArea
							ORDER BY inb.descripcion ASC;
						END;

						RETURN 0;
					END;

					ELSE IF @Option = 13
					BEGIN
						BEGIN
							IF NOT EXISTS (
									SELECT *
									FROM ccUsers_Roles NOLOCK
									WHERE User_id = @AdminId
										AND Rol_id = 7
									)
							BEGIN
								IF @CampType = 1
								BEGIN
									WITH wgId
									AS (
										SELECT IDWG
										FROM ccRIAWorkGroupUsers NOLOCK
														WHERE user_id = @AdminId)
													SELECT DISTINCT 
														CAST(IdCampEsp AS INT) AS CampId,
														cam_descripcion AS Description,
														isnull(IDArea, -1) AS AreaID,
														CAST(-1 AS SMALLINT) AS CampaignType,
														CAST(-1 AS INT) AS RelatedCampId,
														CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
														CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
														CAST(1 AS INT) As CampType
									FROM ccRIACampEspWG A
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
										AND A.Tipo = 1
														INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id
														LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
								END
								ELSE
								BEGIN
									WITH wgId
									AS (
										SELECT IDWG
										FROM ccRIAWorkGroupUsers NOLOCK
														WHERE user_id = @AdminId)
													SELECT DISTINCT 
														CAST(IdCampEsp AS INT) AS CampId,
														descripcion AS Description,
														isnull(IDArea, -1) AS AreaID,
														CAST(chat AS SMALLINT) AS CampaignType,
														CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
														CAST(chat AS INT) AS Channel,
														CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
														CAST(0 AS INT) As CampType
									FROM ccRIACampEspWG A(NOLOCK)
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
										AND A.Tipo = 0
									INNER JOIN ccInbound cci(NOLOCK) ON A.IdCampEsp = cci.Inbound_id
														LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
														LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
														AND ((@multi_type is null AND cci.chat = @InboundType)
															OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
								END
							END;
							ELSE
							BEGIN
								IF @CampType = 1
								BEGIN
											SELECT DISTINCT 
													CAST(ccc.cam_id AS INT) AS CampId,
													cam_descripcion AS Description,
													isnull(IDArea, -1) AS AreaID,
													CAST(-1 AS SMALLINT) AS CampaignType,
													-1 AS RelatedCampId,
													CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
													CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
													CAST(1 AS INT) As CampType
											FROM ccCamps AS ccc (NOLOCK) 
												LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
											where IDArea = @AreaId
								END
								ELSE
								BEGIN
											SELECT DISTINCT 
													CAST(cci.Inbound_id AS INT) AS CampId,
													descripcion AS Description,
													isnull(IDArea, -1) AS AreaID,
													CAST(chat AS SMALLINT) AS CampaignType,
													CAST(chat AS INT) AS Channel,
													CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
													CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
													CAST(0 AS INT) As CampType
									FROM ccInbound cci(NOLOCK)
												LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
												LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
											where IDArea = @AreaId
											AND ((@multi_type is null AND cci.chat = @InboundType)
												OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

								END
							END;

							RETURN 0;
						END;
					END;
					ELSE IF @Option = 14
					BEGIN
						IF NOT EXISTS (
								SELECT *
								FROM ccUsers_Roles NOLOCK
								WHERE User_id = @AdminId
									AND Rol_id = 7
								)
						BEGIN
							WITH wgId
							AS (
								SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
													WHERE user_id = @AdminId)
												SELECT DISTINCT 
													CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
							FROM ccRIACampEspWG A(NOLOCK)
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

					ELSE IF @Option = 15
					BEGIN
								SELECT DISTINCT 
								CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
								FROM ccInbound NOLOCK where cam_id = @Id
					END
					ELSE IF  @Option=16
					begin
						DECLARE @from DATETIME = CAST(GETDATE() AS DATE);
						DECLARE @to DATETIME = DATEADD(MILLISECOND, -3, DATEADD(DAY, 1, @from));
						select @AreaId = IDArea from ccUsers where User_id = @Id
						declare @camps table (cam_id int)
						insert @camps	select cam_id  FROM  dbo.fGet_CampAcd_Area(@Id,5) group by cam_id
						if((select SUM(cam_id) from @camps) IS NULL)
							begin
								select '''' as CampName
								,0 as Conversations
								,0 as Assign
								,0 as OnQueu
								,0 AS FinishedBySystem
								,0 AS FinishedByAgent
								,'''' as AreaName
								,0 as IsAssignedCamps
							end
						else
							begin
								;with camDesc as(
								select 
								c.cam_id as cam_id
								,cam_descripcion as cam_desc
								,area.AreaName
								from ccCamps c with (nolock)
								inner join @camps id on c.cam_id = id.cam_id
								inner join ccRIACat_Areas area on area.IDArea = c.IDArea
								group by area.AreaName, c.cam_id, c.cam_descripcion
								)
								,
								currentConversationWa as (
								select conversationId, camId, assignDate, onQueue,finishedBy
								,case when conversationStatus = 2 then 1 else 0 end as assigned
								from ccWhatsAppConversationsOut with (nolock)
								where assignDate >= @from and assignDate <= @to
								)
								select 
								b.cam_desc as CampName
								,COALESCE(COUNT(ccw.conversationId), 0) AS Conversations
								,COALESCE(SUM(ccw.assigned), 0) AS Assign
								,COALESCE(count(ccw.onQueue),0) as OnQueu
								,SUM(CASE WHEN ccw.finishedBy = 1 THEN 1 ELSE 0 END) AS FinishedBySystem
								,SUM(CASE WHEN ccw.finishedBy = 2 THEN 1 ELSE 0 END) AS FinishedByAgent
								,b.AreaName as AreaName
								,1 as IsAssignedCamps
								from camDesc b
								left join currentConversationWa ccw on ccw.camId = b.cam_id
								group by b.cam_id, b.cam_desc, b.AreaName
							end
						end
					ELSE IF @Option = 17 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
							IF @groupList IS NOT NULL BEGIN
								IF OBJECT_ID(''tempdb..#WGDelete'') IS NOT NULL DROP TABLE #WGDelete;
								SELECT value As IDwg into #WGDelete FROM fn_RIASplitDelimited(@groupList, '','')
								SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type, IDWG AS IdWg FROM ccRIACampEspWG WHERE IDWG in (select IDwg from #WGDelete)
								ORDER BY IdCampEsp ASC;
							END;
							ELSE BEGIN
								RAISERROR(''ERROR. No existe una lista de campañas con los ids de grupo de trabajo especificados'', 18, 1);
							END;
							RETURN 0;
						END;
					END;
			'
        EXEC(@sql)

	------------------------- END LRSV -------------------------------------------------------------
--------------------------------------------------- START CW-8988 Hugo Longoria -------------------------------------------------------------

	SET @process = 'SPEC-99 setting para nueva telefonia'
	SET @sql= 'IF NOT EXISTS (select * from ccSettings where setting_id = 252)
	BEGIN
		insert ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values
		(252,''1|1-50|https://switch.nuxiba.com|engine||3|0|Freeswitch'',''Balancer Configuration'',1,''GRL'',''Balancer Configuration'',''Balancer Configuration'',0,''.*'')
	END'
	EXEC(@sql);

	SET @process = 'SPEC-99 tabla sip headers engine, antes en ini'
	SET @sql= 'IF NOT EXISTS (SELECT * 
					 FROM INFORMATION_SCHEMA.TABLES 
					 WHERE TABLE_SCHEMA = ''dbo'' 
					 AND  TABLE_NAME = ''ccSIPCustomHeaders'')
	BEGIN
		create table ccSIPCustomHeaders (header varchar(254) not null, value varchar(254) not null)
	END'
	EXEC(@sql);

	SET @process = 'SPEC-99 tabla ivr dnis, antes en xml ivr'
	SET @sql= 'IF NOT EXISTS (SELECT * 
					 FROM INFORMATION_SCHEMA.TABLES 
					 WHERE TABLE_SCHEMA = ''dbo'' 
					 AND  TABLE_NAME = ''ccIVRDnis'')
	BEGIN
		create table ccIVRDnis (ivr_id varchar(50) not null, ivr_name varchar(50), dni_number varchar(50) not null)
	END'
	EXEC(@sql);

	SET @process = 'DROP FUNCTION EnableCallRecord'
    SET @sql = 'IF EXISTS (SELECT 1 FROM sys.objects 
                    WHERE Name = ''EnableCallRecord'' 
                        AND Type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
        BEGIN
            DROP FUNCTION dbo.EnableCallRecord
        END'
    EXEC(@sql)

	SET @process = 'Create function EnableCallRecord'
	SET @sql = 'CREATE function [dbo].[EnableCallRecord](@call_record_cam tinyint,@pais tinyint, @tel varchar(32))
		RETURNS tinyint
		AS  
		BEGIN


		if @call_record_cam = 1  begin
			return 1 -- grabar 
		end

		else if @call_record_cam=3  begin
			return 0 -- no grabar
		end

		declare @callRecordOri bit

		set @callRecordOri=@call_record_cam

		-- grabar zonas permitidas
		if @pais=4 begin
			if len(@tel) = 10 begin
				select @call_record_cam = isnull(call_record,1)  from ccTimeZoneArea where id_country= @pais and area = left(@tel,3)		
			end
		end
		if @call_record_cam=0 begin
			if @callRecordOri=4 begin
				return @callRecordOri  --No Grabar pero puede cambiar a grabar desde el agente
			end	
		end

		return @call_record_cam
	
		END'
	EXEC(@sql)

	SET @process = 'Drop procedure ccsp_DLRInsertCall'
    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_DLRInsertCall'')
		BEGIN
			DROP PROCEDURE dbo.ccsp_DLRInsertCall
		END'
    EXEC(@sql);

	SET @process = 'CREATE procedure ccsp_DLRInsertCall'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_DLRInsertCall]
		@callout_id int,
		@cam_id smallint,
		@cal_Key varchar(20),
		@cal_Telefono varchar(14),
		@Puerto smallint,
		@logDial_id int=0
		AS

		INSERT ccoCallsOUT ( callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id ) --Status 6=Pide Agente
		  VALUES ( @callout_id, @cam_id, @cal_Key, @cal_Telefono, @Puerto, getdate(), 6 )

		select cast(scope_identity() as int) as cal_id'
	EXEC(@sql);

	SET @process = 'Drop procedure ccsp_IVRInCalls'
    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_IVRInCalls'')
		BEGIN
			DROP PROCEDURE dbo.ccsp_IVRInCalls
		END'
    EXEC(@sql);

	SET @process = 'CREATE procedure ccsp_IVRInCalls'
    SET @sql = 'CREATE procedure [dbo].[ccsp_IVRInCalls]
@action tinyint = 0 ,
@ani varchar(30) = null ,
@idIvr int = 0 ,
@option varchar(5)= null ,
@saveType tinyInt = null,
@dnis varchar(50) = null,
@name varchar(50) = null,
@questionId int = 0,
@surveyId int = 0,
@calId int = 0,
@callout_id int = 0,
@ttotalIVR int = 0,
@callType tinyint = null,
@callbackCamId int =0
-- saveType 1 es menu 2 es dato
-- accion 1 siempre @ani  -> @idIvr
-- accion 2 siempre @idIvr @opcionDigitada -> nada
AS
IF @action = 1
BEGIN
        IF @ani IS NOT NULL
        BEGIN
                INSERT INTO IVRCallsIn(cal_ani,date,dnis,callout_id) values(@ani,getDate(),isnull(@dnis,''''),@callout_id);
                UPDATE ccCallsIn SET cal_whoHung = 2 WHERE cal_id = @callout_id
        Select ''ID''=cast(scope_identity() as int)
        END
END
ELSE IF @action = 2
BEGIN
        IF @option IS NOT NULL AND @idIvr IS NOT NULL
        BEGIN
                INSERT INTO IVROptions(IVR_id,selectedOption,date,saveType,name, questionId, surveyId, cal_id, callType) values (@idIvr,@option,getDate(),@saveType,@name,isnull(@questionId,0),isnull(@surveyId,0),isnull(@calId,0),isnull(@callType,0))
                select 0
        END
        ELSE select -1
END
ELSE IF @action = 3
BEGIN
        UPDATE IVRCallsIn set tincall = @ttotalIVR where IVR_id = @idIvr and callout_id = @callout_id
        if @callout_id > 0 begin
                exec ccsp_EngineLogTransfers 4, @callout_id, 0, 0, null
                UPDATE ccoCallsOut set cal_whoHung = 2 where cal_id = @callout_id
        end
        if @callbackCamId >0  begin
                EXEC [ccsp_KolobUpdateCallback_AbandonIVR] @idIvr, @callbackCamId
        end
END'
	EXEC(@sql);

	SET @process = 'Drop procedure spInsertCall'
    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''spInsertCall'')
		BEGIN
			DROP PROCEDURE dbo.spInsertCall
		END'
    EXEC(@sql);

	SET @process = 'CREATE procedure spInsertCall'
    SET @sql = 'CREATE PROCEDURE [dbo].[spInsertCall]
		@Pto smallint,
		@DNIS varchar(14),
		@ANI as varchar(14),
		@inbound_id smallint=0,
		@IVR_id int = 0, --Id del IVR
		@CALLDATA as varchar(1275) = ''''
		AS
		declare @dni_id as smallint
		declare @cal_id as int
		declare @datacall as varchar(100)

		select @Ani = left(rtrim(ltrim(@ANI)), 13)
		select @DNIS = rtrim(ltrim(@DNIS))

		  --busca dni_id
		  select @dni_id = isnull ( ( select dni_id From ccDNIS Where dni_numero =  @DNIS and dni_status = 1 ), 0)
  
		  --busca especialidad
		  IF @inbound_id =0 and @dni_id >0
			select @Inbound_id=ED.Inbound_id from ccInboundDnis ED where ED.dni_id = @dni_id
  
		  INSERT ccCallsIN ( cal_ANI, dni_id, cal_puerto, cal_Inicio, inbound_id, IVR_id )
		  VALUES ( @ANI, @dni_id, @Pto, getdate(), @inbound_id, @IVR_id )

		  select @cal_id = scope_identity()

		  exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@inbound_id,@callType=0,@statusCallId=1

		  IF @inbound_id > 0 
		  BEGIN
			insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
			select idwg, @cal_id, 0 as user_id, getdate() timestamp, 0 as tipo from ccRIACampEspWG wg   
			where wg.tipo = 0 and wg.IdCampEsp = @Inbound_id

		  END

		  IF @CALLDATA <> ''''  BEGIN -- Transfer Reminder
			set @CALLDATA=SUBSTRING(@CALLDATA,0,len(@CALLDATA)-2)
			insert into DataCallIn (CallId, Data, Description) 
			select @cal_id,value,''Dato ''+cast(id as varchar(max)) from dbo.[fn_RIASplitDelimited](@CALLDATA,''~'')
		  END

		  Select @cal_id as IDCall'
	EXEC(@sql);

	SET @process = 'Drop procedure getPrefixByAcdId'
    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''getPrefixByAcdId'')
		BEGIN
			DROP PROCEDURE dbo.getPrefixByAcdId
		END'
    EXEC(@sql);

	SET @process = 'CREATE procedure getPrefixByAcdId'
    SET @sql = 'CREATE procedure [dbo].[getPrefixByAcdId] 
@inboundId int,@phone varchar(50) = ''''
as
declare @prefijo varchar(40),@recordHold bit,@call_record as tinyint
declare @countryId as tinyint 

select @countryId = valor from ccsettings with(nolock) where setting_id = 104

select @prefijo= isnull(prefijo,''''),@recordHold= ISNULL(recordHold,0)  ,@call_record=ISNULL(B.RecordCalls,1)
from ccInbound A
left join ccInboundExtend B on A.Inbound_id=B.Inbound_id
where A.Inbound_id = @inboundId

select @prefijo recordPrefix,@recordHold recordHold ,dbo.EnableCallRecord(@call_record,@countryId,@phone) callRecord
'
	EXEC(@sql);

---------------------------------------------------- END CW-8988 Hugo Longoria --------------------------------------------------------------

--------------------------------------------------- START CW-8987 Hugo Longoria -------------------------------------------------------------
	 SET @process = 'Se crea setting 285'
     SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 285)
		BEGIN
			insert ccsettings2 (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values (285,''0|5|3'',''Outbound Configuration'',1,''GRL'',''CheckProvider=>0:Any port,1:Cost-effective,2:Cost-effective-only|TimeTxCallsCampInfo|DefaultDialFactorIa'',''Outbound Configuration'',0,''.*'')
		END'
     EXEC(@sql);
	 
	 SET @process = 'KR106000 se agrega columna CancelAttempts en ccoworkingTable'
     SET @sql = 'IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''CancelAttempts'' AND Object_ID = Object_ID(N''dbo.ccoworkingTable''))
		BEGIN
			ALTER TABLE ccoworkingTable ADD CancelAttempts INT NULL;
		END'
     EXEC(@sql);

     SET @process = 'Drop procedure ccsp_OUT_JobsActions'
     SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_OUT_JobsActions'')
		BEGIN
			DROP PROCEDURE dbo.ccsp_OUT_JobsActions
		END'
     EXEC(@sql);

	 SET @process = '--KR106000 se crea sp ccsp_OUT_JobsActions'
	 SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_OUT_JobsActions]
		@Type SMALLINT,
		@callout_id INT = 0,
		@cam_id int = 0
	
		AS
			
		IF (@type = 1) 
		BEGIN
			update ccoWorkingTable set CancelAttempts = isnull(CancelAttempts, 0) + 1 where callout_id = @callout_id		
		END;'
	 EXEC(@sql);

	 SET @process = 'Drop procedure ccsp_OutPhonesInBL'
     SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_OutPhonesInBL'')
		BEGIN
			DROP PROCEDURE dbo.ccsp_OutPhonesInBL
		END'
     EXEC(@sql);

	 SET @process = 'Create procedure ccsp_OutPhonesInBL'
	 SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_OutPhonesInBL]
		@action as tinyint,
		@cam_id as smallint,
		@phones as varchar(max),
		@keys as varchar(max)
		AS
		if @action = 1 begin	
			SELECT phone
				FROM cclistanegra a1 (nolock)
				INNER JOIN camplistanegra a2 WITH (INDEX (IX_Camplistanegra)) ON a1.idtipolista = a2.idtipolista
				JOIN (select p.Value phone, dbo.hashPhone(p.Value) hashPhone,case when len(k.Value) > 0 then dbo.hashList(k.Value) else 0 end hashKey from dbo.fn_RIASplitDelimited(@phones,''|'') p left join  dbo.fn_RIASplitDelimited(@keys,''|'') k on p.Id=k.Id 
				) phones on a1.Hashtel = phones.hashPhone AND (a1.HashKey IS NULL OR a1.HashKey = phones.hashKey)
				WHERE a2.cam_id = @cam_id AND STATUS = 1
		end'
	 EXEC(@sql);

	 SET @process = 'DROP FUNCTION ValidateBlackListPhone'
     SET @sql = 'IF EXISTS (SELECT 1 FROM sys.objects 
                    WHERE Name = ''ValidateBlackListPhone'' 
                        AND Type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
        BEGIN
            DROP FUNCTION dbo.ValidateBlackListPhone
        END'
     EXEC(@sql)

	 SET @process = 'Create function ValidateBlackListPhone'
	 SET @sql = 'CREATE FUNCTION [dbo].[ValidateBlackListPhone] (@tel VARCHAR(32), @camId INT, @calKey VARCHAR(20))
RETURNS BIT
AS
BEGIN
	DECLARE @isBlackPhone BIT
	--PARA LA VALIDACION DE LISTAS NEGRAS CON HASH
	DECLARE @hasTelefono BIGINT

	SELECT @hasTelefono = dbo.hashPhone(@tel)

	DECLARE @hasCalKey BIGINT

	IF @calKey IS NOT NULL OR @calKey <> ''''
		SELECT @hasCalKey = dbo.hashList(@calKey)

	SET @isBlackPhone = 0

	IF EXISTS (
			SELECT a2.idtipolista
			FROM cclistanegra a1 (nolock)
			INNER JOIN camplistanegra a2 WITH (INDEX (IX_Camplistanegra)) ON a1.idtipolista = a2.idtipolista
			WHERE a2.cam_id = @camId AND STATUS = 1 AND a1.Hashtel = @hasTelefono AND (a1.HashKey IS NULL OR a1.HashKey = @hasCalKey)
			)
		SET @isBlackPhone = 1

	RETURN @isBlackPhone
END'
	 EXEC(@sql);

	 SET @process = 'Drop procedure ccspLoadCampsOutbound'
     SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccspLoadCampsOutbound'')
		BEGIN
			DROP PROCEDURE dbo.ccspLoadCampsOutbound
		END'
     EXEC(@sql);

	 SET @process = 'Create procedure ccspLoadCampsOutbound'
	 SET @sql = '
CREATE PROCEDURE ccspLoadCampsOutbound
    @action int,  
    @nType INT=0,
    @agentId int=0,
    @campId int=0
AS
declare @sql nvarchar(max)

if @action= 0 begin
    set @sql=''SELECT cc.cam_id
                ,cam_descripcion
                ,cam_activo
                ,cam_ModoManual
                ,cam_modpredictivo
                ,cam_callratio
                ,cam_procesando
                ,convert(VARCHAR(8), cast(cam_maxdlrxage AS FLOAT)) cam_maxdlrxage
                ,cam_fDialOnWU
                ,cam_fDialOnDLG
                ,cam_tDialAfterWU
                ,cam_tDialBeforeReady
                ,cam_tDialAfterDLG
                ,compliance
                ,progDial
                ,excCallBack
                ,aggressionFactor
                ,listenManualCall
                ,tDialOnWrapUp
                ,callsbySurvey
                ,ivrscript
                ,cam_tNoContesta
                ,cam_inter_cancelled
                ,ISNULL(cc.CampType, 0) AS CampType
                ,ISNULL(cc.CamCanceled, 4) AS CamCanceled
                ,ISNULL(ex.SimultaneousRecs, 0) AS SimultaneousRecs
                ,ISNULL(cva.concurrentSessionsLimit, 0) AS NumberSessions
                FROM ccCamps cc (NOLOCK) 
                LEFT JOIN ccCampsExtend ex (NOLOCK) ON ex.cam_id = cc.cam_id
                LEFT JOIN ccVirtualAgent cva ON cva.idCampaign = cc.cam_id AND cva.campType = 1
                WHERE CampType not in (5,7)''
    if @nType=2 
        set @sql=@sql+'' AND cam_bNew = 2 ''
    else if @nType=3
        set @sql=@sql+'' AND cam_bNew in (1,2) ''
    set @sql=@sql+'' ORDER BY cam_descripcion''
    --print(@sql)
    exec (@sql)
end
else if @action= 1 begin
    set @sql=''SELECT distinct C.cam_id, C.cam_descripcion, Prioridad, A.Login, A.User_id, Skill
        from ccCamps C (nolock) join ccCampsAgente CA on C.cam_id = CA.cam_id AND CampType not in (5,7)
        join ccUsers A (nolock) on A.User_id = CA.User_id and A.TipoUser_id =1 AND A.Status=1 ''
    if @nType=2 
        set @sql=@sql+'' and C.cam_bNew=2''
    else if @nType=3
        set @sql=@sql+'' and C.cam_bNew in (1,2)''
    if @campId > 0
        set @sql=@sql+'' where C.cam_id = '' + cast(@campId as varchar(5))
    set @sql=@sql+'' order by C.cam_id, CA.Prioridad''
    --print(@sql)
    exec (@sql)
end
else if @action= 2 begin
    set @sql=''select distinct A.Login, Prioridad, C.cam_id, Skill
            from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id AND CampType not in (5,7)
            join ccUsers A  on A.User_id = CA.User_id and A.TipoUser_id =1 AND A.Status=1
            Where A.User_id = @agentId
            order by C.cam_id, CA.Prioridad''
    --print(@sql)
    exec sp_executesql @sql, N''@agentId int'', @agentId
end
else if @action= 3 begin
    set @sql=''SELECT dialer_id, C.cam_id FROM ccoDialerCamp R (nolock) join ccCamps C (nolock) on R.cam_id=C.cam_id AND CampType not in (5,7) ''
    if @nType=2 
        set @sql=@sql+'' and C.cam_bNew = 2 ''
    else if @nType=3
        set @sql=@sql+'' and C.cam_bNew in (1,2) ''
    if @campId > 0
        set @sql=@sql+'' where C.cam_id = '' + cast(@campId as varchar(5))
    set @sql=@sql+'' ORDER BY cam_descripcion''
    --print(@sql)
    exec (@sql)
end
else if @action= 4 begin
    set @sql=''SELECT Login, TipoLLamadas, user_id FROM ccUsers A JOIN ccTipoUsers T on A.TipoUser_id=T.TipoUser_id
                WHERE A.TipoUser_id =1 AND A.Status=1 AND User_id = CASE WHEN @agentId = 0 THEN User_id ELSE @agentId END
                ORDER BY Login''
    exec sp_executesql @sql, N''@agentId int'', @agentId
end'
	 EXEC(@sql);

	 SET @process = 'KR110001 TABLE CodesInterDialing'
     SET @sql = '
                if not exists(select * from sys.tables where name=''CodesInterDialing'')
                begin
                    create table CodesInterDialing(id int not null identity(1,1), Description varchar (50), ES varchar(max), EN varchar(max), PT varchar(max), Code varchar(25))

                    set identity_insert CodesInterDialing on

                    insert into CodesInterDialing(id, Description, ES, EN, PT)
                    values(1, ''america-code-1'', ''Estados Unidos de América (+1)'', ''United States of America (+1)'', ''Estados Unidos da América (+1)'')
                    ,(2, ''america-code-2'', ''Islas Vírgenes de EE. UU. (+1-340)'', ''Virgin Islands (U.S.) (+1-340)'', ''Ilhas Virgens Americanas (+1-340)'')
                    ,(3, ''america-code-3'', ''Islas Marianas del Norte (+1-670)'', ''Northern Mariana Islands (+1-670)'', ''Ilhas Marianas do Norte (+1-670)'')
                    ,(4, ''america-code-4'', ''Guam (+1-671)'', ''Guam (+1-671)'', ''Guam (+1-671)'')
                    ,(5, ''america-code-5'', ''Samoa Oriental (+1-684)'', ''American Samoa (+1-684)'', ''Samoa Americana  (+1-684)'')
                    ,(6, ''america-code-6'', ''Puerto Rico (+1)'', ''Puerto Rico (+1)'', ''Porto Rico (+1)'')
                    ,(7, ''america-code-7'', ''Canadá (+1)'', ''Canada (+1)'', ''Canadá (+1)'')
                    ,(8, ''america-code-8'', ''Bahamas (+1-242)'', ''Bahamas (+1-242)'', ''Bahamas (+1-242)'')
                    ,(9, ''america-code-9'', ''Barbados (+1-246)'', ''Barbados (+1-246)'', ''Barbados (+1-246)'')
                    ,(10, ''america-code-10'', ''Anguila (+1-264)'', ''Anguilla (+1-264)'', ''Anguila (+1-264)'')
                    ,(11, ''america-code-11'', ''Antigua y Barbuda (+1-268)'', ''Antigua and Barbuda (+1-268)'', ''Antígua e Barbuda (+1-268)'')
                    ,(12, ''america-code-12'', ''Islas Vírgenes Británicas (+1-284)'', ''Virgin Islands (British) (+1-284)'', ''Ilhas Virgens Britânicas (+1-284)'')
                    ,(13, ''america-code-13'', ''Islas Caimán (+1-345)'', ''Cayman Islands (+1-345)'', ''Ilhas Cayman (+1-345)'')
                    ,(14, ''america-code-14'', ''Bermudas (+1-441)'', ''Bermuda (+1-441)'', ''Bermudas (+1-441)'')
                    ,(15, ''america-code-15'', ''Granada (+1-473)'', ''Grenada (+1-473)'', ''Granada (+1-473)'')
                    ,(16, ''america-code-16'', ''Islas Turcas y Caicos (+1-649)'', ''Turks & Caicos (+1-649)'', ''Ilhas Turcos e Caicos (+1-649)'')
                    ,(17, ''america-code-17'', ''Jamaica (+1-876)'', ''Jamaica (+1-876)'', ''Jamaica (+1-876)'')
                    ,(18, ''america-code-18'', ''Montserrat (+1-664)'', ''Montserrat (+1-664)'', ''Montserrat (+1-664)'')
                    ,(19, ''america-code-19'', ''San Martín (zona neerlandesa) (+721)'', ''Sint Maarten (+721)'', ''São Martinho (parte holandesa) (+721)'')
                    ,(20, ''america-code-20'', ''Santa Lucía (+1-758)'', ''St. Lucia (+1-758)'', ''Santa Lúcia (+1-758)'')
                    ,(21, ''america-code-21'', ''Dominica (+1-767)'', ''Dominica (+1-767)'', ''Dominica (+1-767)'')
                    ,(22, ''america-code-22'', ''San Vicente y las Granadinas(+1-784)'', ''St. Vincent and the Grenadines (+1-784)'', ''São Vincente e Granadinas (+1-784)'')
                    ,(23, ''america-code-23'', ''República Dominicana (+1)'', ''Dominican Republic (+1)'', ''República Dominicana (+1)'')
                    ,(24, ''america-code-24'', ''Trinidad y Tobago (+1-868)'', ''Trinidad & Tobago (+1-868)'', ''Trinidad e Tobago (+1-868)'')
                    ,(25, ''america-code-25'', ''San Cristóbal y Nieves (+1-869)'', ''St. Kitts/Nevis (+1-869)'', ''São Cristóvão e Névis (+1-869)'')
                    ,(26, ''america-code-26'', ''Islas Malvinas (+500)'', ''Falkland Islands (+500)'', ''Ilhas Malvinas (+500)'')
                    ,(27, ''america-code-27'', ''Georgia del Sur e Islas Sandwich del Sur (+500)'', ''South Georgia and the South Sandwich Islands (+500)'', ''Ilhas Geórgia do Sul e Sandwich do Sul (+500)'')
                    ,(28, ''america-code-28'', ''Belice (+501)'', ''Belize (+501)'', ''Belize (+501)'')
                    ,(29, ''america-code-29'', ''Guatemala (+502)'', ''Guatemala (+502)'', ''Guatemala (+502)'')
                    ,(30, ''america-code-30'', ''El Salvador (+503)'', ''El Salvador (+503)'', ''El Salvador (+503)'')
                    ,(31, ''america-code-31'', ''Honduras (+504)'', ''Honduras (+504)'', ''Honduras (+504)'')
                    ,(32, ''america-code-32'', ''Nicaragua (+505)'', ''Nicaragua (+505)'', ''Nicarágua (+505)'')
                    ,(33, ''america-code-33'', ''Costa Rica (+506)'', ''Costa Rica (+506)'', ''Costa Rica (+506)'')
                    ,(34, ''america-code-34'', ''Panamá (+507)'', ''Panama (+507)'', ''Panamá (+507)'')
                    ,(35, ''america-code-35'', ''San Pedro y Miquelón (+508)'', ''St. Pierre and Miquelon (+508)'', ''São Pedro e Miquelon (+508)'')
                    ,(36, ''america-code-36'', ''Haití (+509)'', ''Haiti (+509)'', ''Haiti (+509)'')
                    ,(37, ''america-code-37'', ''Perú (+51)'', ''Peru (+51)'', ''Peru (+51)'')
                    ,(38, ''america-code-38'', ''México (+52)'', ''Mexico (+52)'', ''México (+52)'')
                    ,(39, ''america-code-39'', ''Cuba (+53)'', ''Cuba (+53)'', ''Cuba (+53)'')
                    ,(40, ''america-code-40'', ''Argentina (+54)'', ''Argentina (+54)'', ''Argentina (+54)'')
                    ,(41, ''america-code-41'', ''Brasil (+55)'', ''Brazil (+55)'', ''Brasil (+55)'')
                    ,(42, ''america-code-42'', ''Chile (+56)'', ''Chile (+56)'', ''Chile (+56)'')
                    ,(43, ''america-code-43'', ''Colombia (+57)'', ''Colombia (+57)'', ''Colômbia (+57)'')
                    ,(44, ''america-code-44'', ''Venezuela (+58)'', ''Venezuela (+58)'', ''Venezuela (+58)'')
                    ,(45, ''america-code-45'', ''Guadalupe (+590)'', ''Guadeloupe (+590)'', ''Guadalupe (+590)'')
                    ,(46, ''america-code-46'', ''Bolivia (+591)'', ''Bolivia (+591)'', ''Bolívia (+591)'')
                    ,(47, ''america-code-47'', ''Guyana (+592)'', ''Guyana (+592)'', ''Guiana (+592)'')
                    ,(48, ''america-code-48'', ''Ecuador (+593)'', ''Ecuador (+593)'', ''Equador (+593)'')
                    ,(49, ''america-code-49'', ''Guyana Francesa (+594)'', ''French Guiana (+594)'', ''Guiana Francesa (+594)'')
                    ,(50, ''america-code-50'', ''Paraguay (+595)'', ''Paraguay (+595)'', ''Paraguai (+595)'')
                    ,(51, ''america-code-51'', ''Martinica (+596)'', ''Martinique (+596)'', ''Martinica (+596)'')
                    ,(52, ''america-code-52'', ''Surinam (+597)'', ''Suriname (+597)'', ''Suriname (+597)'')
                    ,(53, ''america-code-53'', ''Uruguay (+598)'', ''Uruguay (+598)'', ''Uruguai (+598)'')
                    ,(54, ''america-code-54'', ''Antillas Neerlandesas (+599)'', ''Netherlands Antilles (+599)'', ''Antilhas Holandesas (+599)'')
                    ,(55, ''america-code-55'', ''Bonaire, San Eustaquio y Saba (+599)'', ''Bonaire, Sint Eustatius and Saba (+599)'', ''Bonaire, Santo Eustáquio e Saba(+599)'')
                    ,(56, ''america-code-56'', ''Curazao (+599)'', ''Curaçao (+599)'', ''Curaçao (+599)'')
                    ,(57, ''europa-code-1'', ''Grecia (+30)'', ''Greece (+30)'', ''Grécia (+30)'')
                    ,(58, ''europa-code-2'', ''Países Bajos (+31)'', ''Netherlands (+31)'', ''Países Baixos (+31)'')
                    ,(59, ''europa-code-3'', ''Bélgica (+32)'', ''Belgium (+32)'', ''Bélgica (+32)'')
                    ,(60, ''europa-code-4'', ''Francia (+33)'', ''France (+33)'', ''França (+33)'')
                    ,(61, ''europa-code-5'', ''España (+34)'', ''Spain (+34)'', ''Espanha (+34)'')
                    ,(62, ''europa-code-6'', ''Gibraltar (+350)'', ''Gibraltar (+350)'', ''Gibraltar (+350)'')
                    ,(63, ''europa-code-7'', ''Portugal (+351)'', ''Portugal (+351)'', ''Portugal (+351)'')
                    ,(64, ''europa-code-8'', ''Luxemburgo (+352)'', ''Luxembourg (+352)'', ''Luxemburgo (+352)'')
                    ,(65, ''europa-code-9'', ''Irlanda (+353)'', ''Ireland (+353)'', ''Irlanda (+353)'')
                    ,(66, ''europa-code-10'', ''Islandia (+354)'', ''Iceland (+354)'', ''Islândia (+354)'')
                    ,(67, ''europa-code-11'', ''Albania (+355)'', ''Albania (+355)'', ''Albânia (+355)'')
                    ,(68, ''europa-code-12'', ''Malta (+356)'', ''Malta (+356)'', ''Malta (+356)'')
                    ,(69, ''europa-code-13'', ''Chipre (+357)'', ''Cyprus (+357)'', ''Chipre (+357)'')
                    ,(70, ''europa-code-14'', ''Finlandia (+358)'', ''Finland (+358)'', ''Finlândia (+358)'')
                    ,(71, ''europa-code-15'', ''Bulgaria (+359)'', ''Bulgaria (+359)'', ''Bulgária (+359)'')
                    ,(72, ''europa-code-16'', ''Hungría (+36)'', ''Hungary (+36)'', ''Hungria (+36)'')
                    ,(73, ''europa-code-17'', ''Lituania (+370)'', ''Lithuania (+370)'', ''Lituânia (+370)'')
                    ,(74, ''europa-code-18'', ''Letonia (+371)'', ''Latvia (+371)'', ''Letônia (+371)'')
                    ,(75, ''europa-code-19'', ''Estonia (+372)'', ''Estonia (+372)'', ''Estônia (+372)'')
                    ,(76, ''europa-code-20'', ''Moldavia (+373)'', ''Moldova (+373)'', ''Moldova (+373)'')
                    ,(77, ''europa-code-21'', ''Armenia (+374)'', ''Armenia (+374)'', ''Armênia (+374)'')
                    ,(78, ''europa-code-22'', ''Bielorrusia (+375)'', ''Belarus (+375)'', ''Bielo-Rússia (+375)'')
                    ,(79, ''europa-code-23'', ''Andorra (+376)'', ''Andorra (+376)'', ''Andorra (+376)'')
                    ,(80, ''europa-code-24'', ''Mónaco (+377)'', ''Monaco (+377)'', ''Mônaco (+377)'')
                    ,(81, ''europa-code-25'', ''San Marino (+378)'', ''San Marino (+378)'', ''São Marinho (+378)'')
                    ,(82, ''europa-code-26'', ''Ciudad del Vaticano (+379)'', ''Vatican City (+379)'', ''Cidade do Vaticano (+379)'')
                    ,(83, ''europa-code-27'', ''Ucrania (+380)'', ''Ukraine (+380)'', ''Ucrânia (+380)'')
                    ,(84, ''europa-code-28'', ''Serbia (+381)'', ''Serbia (+381)'', ''Sérvia (+381)'')
                    ,(85, ''europa-code-29'', ''Montenegro (+382)'', ''Montenegro (+382)'', ''Montenegro (+382)'')
                    ,(86, ''europa-code-30'', ''Kosovo (+383)'', ''Kosovo (+383)'', ''Kosovo (+383)'')
                    ,(87, ''europa-code-31'', ''Croacia (+385)'', ''Croatia (+385)'', ''Croácia (+385)'')
                    ,(88, ''europa-code-32'', ''Eslovenia (+386)'', ''Slovenia (+386)'', ''Eslovênia (+386)'')
                    ,(89, ''europa-code-33'', ''Bosnia y Herzegovina (+387)'', ''Bosnia/Herzegovina (+387)'', ''Bósnia e Herzegovina (+387)'')
                    ,(90, ''europa-code-34'', ''Macedonia (+389)'', ''Macedonia (+389)'', ''Macedônia (+389)'')
                    ,(91, ''europa-code-35'', ''Italia (+39)'', ''Italy (+39)'', ''Itália (+39)'')
                    ,(92, ''europa-code-36'', ''Rumania (+40)'', ''Romania (+40)'', ''Romênia (+40)'')
                    ,(93, ''europa-code-37'', ''Suiza (+41)'', ''Switzerland (+41)'', ''Suíça (+41)'')
                    ,(94, ''europa-code-38'', ''República Checa (+420)'', ''Czech Republic (+420)'', ''República Tcheca (+420)'')
                    ,(95, ''europa-code-39'', ''República Eslovaca (+421)'', ''Slovak Republic (+421)'', ''República Eslovaca (+421)'')
                    ,(96, ''europa-code-40'', ''Liechtenstein (+423)'', ''Liechtenstein (+423)'', ''Liechtenstein (+423)'')
                    ,(97, ''europa-code-41'', ''Austria (+43)'', ''Austria (+43)'', ''Áustria (+43)'')
                    ,(98, ''europa-code-42'', ''Reino Unido (+44)'', ''United Kingdom (+44)'', ''Reino Unido (+44)'')
                    ,(99, ''europa-code-43'', ''Guernesey (+44-1481)'', ''Guernsey (+44-1481)'', ''Guernsey (+44-1481)'')
                    ,(100, ''europa-code-44'', ''Bailía de Jersey (+44-1534)'', ''Jersey (+44-1534)'', ''Protetorado de Jersey (+44-1534)'')
                    ,(101, ''europa-code-45'', ''Isla de Man (+44-1624)'', ''Isle of Man (+44-1624)'', ''Ilha de Man (+44-1624)'')
                    ,(102, ''europa-code-46'', ''Dinamarca (+45)'', ''Denmark (+45)'', ''Dinamarca (+45)'')
                    ,(103, ''europa-code-47'', ''Suecia (+46)'', ''Sweden (+46)'', ''Suécia (+46)'')
                    ,(104, ''europa-code-48'', ''Noruega (+47)'', ''Norway (+47)'', ''Noruega (+47)'')
                    ,(105, ''europa-code-49'', ''Islas Svalbard y Jan Mayen(+47)'', ''Svalbard and Jan Mayen (+47)'', ''Ilhas de Svalbard e Jan Mayen(+47)'')
                    ,(106, ''europa-code-50'', ''Polonia (+48)'', ''Poland (+48)'', ''Polônia (+48)'')
                    ,(107, ''europa-code-51'', ''Alemania (+49)'', ''Germany (+49)'', ''Alemanha (+49)'')

                    set identity_insert CodesInterDialing off

                    update CodesInterDialing
                    set Code = SUBSTRING(ES, CHARINDEX(''+'', ES) + 1, CHARINDEX(''+'', REVERSE(ES)) - 2)


                    alter table ccoDialers add DialingType bit not null default 1, IdCode int not null default 0                        
                end'
     EXEC(@sql);

 ---------------------------------------------------- END CW-8987 Hugo Longoria --------------------------------------------------------------

---------------------------------------------------- BEGIN Isaac -------------------------------------------------------------
    SET @process = 'Drop procedure ccspCCserverLoadCamp'
    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccspCCserverLoadCamp'')
		BEGIN
			DROP PROCEDURE dbo.ccspCCserverLoadCamp
		END'
    EXEC(@sql);

    SET @process = 'Create procedure ccspCCserverLoadCamp'
    SET @sql = '
CREATE PROCEDURE ccspCCserverLoadCamp
@Type as smallint
AS
BEGIN
	DECLARE @sql NVARCHAR(max)

	SET @sql = ''SELECT
					c.cam_id
				   ,ISNULL(g.graphic_id, 1) graphic_id
				   ,c.cam_descripcion
				   ,c.cam_tnotas
				   ,c.cam_maxqueue
				   ,c.cam_procesando
				   ,c.CampType
				   ,ISNULL(v.concurrentSessionsLimit, 0) AS AgtVirtual
				FROM ccCamps c (NOLOCK)
				LEFT JOIN ccRIACampsGraph g (NOLOCK) ON g.cam_id = c.cam_id
				LEFT JOIN ccVirtualAgent v (NOLOCK) ON v.idCampaign = c.cam_id
				WHERE cam_activo = 1''

	IF @Type<>1 BEGIN
		SET @sql = @sql + '' AND cam_bNew=2''
	END
    EXEC (@sql)
END
    '
    EXEC(@sql);
---------------------------------------------------- END Isaac --------------------------------------------------------------
 


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
