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
                campType TINYINT NULL
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
            ISNULL(CampType, 0) CampType,
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
