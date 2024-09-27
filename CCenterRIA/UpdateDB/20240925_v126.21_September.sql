/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: David Medina Medina
Date: 2024/09/19
Description: Release 126.20240919.0.0
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 21
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
    	
		------------------------------------------------- Start Gaby----------------------------------------------------------------------------------
		------------------------------------------------------- Tablas ------------------------------------------------------------------------------------------
		SET @process = 'K020140 Se añade columna MaxDaysPerWAConvo para el máximo de días a visualizar'
		SET @sql = '
			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''MaxDaysPerWAConvo'' AND Object_ID = Object_ID(N''dbo.contactMeanOut''))
			BEGIN
				ALTER TABLE contactMeanOut ADD MaxDaysPerWAConvo smallint default 5 WITH VALUES;
			END'
		EXEC(@sql)

		SET @process = 'K020140 Se agrega relación del indentificador y la tabla para el maximo de días a visualizar'
		SET @sql = '
			IF NOT EXISTS (SELECT 1 FROM relationTableColumnIdentifiers WHERE colunName = ''MaxDaysPerWAConvo'' AND tableName = ''contactMeanOut'')
			BEGIN
				insert into relationTableColumnIdentifiers(Identifiers,tableName,colunName)
				values (''T$WA_CONVERSATION_LOG_OUT'',''contactMeanOut'',''MaxDaysPerWAConvo'')
			END'
		EXEC(@sql)

		SET @process = 'K020140 Se agrega identificador para el maximo de días a visualizar'
		SET @sql = '
			IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''T$WA_CONVERSATION_LOG_OUT'')
			BEGIN
				insert into ccGalateaIdentifiers(Description,TagEs,TagEn,TagPt)
				values (''T$WA_CONVERSATION_LOG_OUT'',''Tiempo de historial de conversaciones (días)'',''Conversations log period (days)'',''Tempo de histórico de conversas (dias)'')
			END'
		EXEC(@sql)
		--------------------------------------------------------- SPs -------------------------------------------------------------------------------------------
		SET @process = 'K020140 Se elimina SP ccsp_RIAConfCamp'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAConfCamp'')
					begin
						DROP PROCEDURE ccsp_RIAConfCamp;
					end'
		EXEC(@sql)

		SET @process = 'KO20140 Create SP con las modificaciones para obtener el valor DaysVisualConversationWhatsApp'
		SET @sql = 'CREATE PROCEDURE ccsp_RIAConfCamp @User_id SMALLINT, @campID INT = NULL
		AS
		SET NOCOUNT ON

		DECLARE @tableExistsRec TABLE (
			camId INT PRIMARY KEY
			,existRec BIT
			)
		DECLARE @camByUser TABLE (
			camId INT PRIMARY KEY
			,isCheck BIT
			)
		DECLARE @camId INT
			,@id INT;
		DEClARE @intenationalDialingPorts bit;
		declare @tempInternationalCode int
 
		if((select COUNT(*) from ( select  top 1 IdCode from ccoDialers ccoDial inner join ccoDialerCamp ccoDialCamp on ccoDialCamp.dialer_id = ccoDial.dialer_id where ccoDialCamp.cam_id = @campID and ccoDial.DialingType=0  ) result ) > 0)
		BEGIN
			set @intenationalDialingPorts = 1
		END
		ElSE
		BEGIN
			set @intenationalDialingPorts = 0;
		END

		IF NOT EXISTS (
				SELECT *
				FROM ccUsers_Roles
				WHERE User_id = @User_id
					AND Rol_id = 7
				)
		BEGIN
			INSERT INTO @camByUser
			SELECT *
				,0
			FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
			WHERE @campID IS NULL
				OR cam_id = @campID
		END
		ELSE
		BEGIN
			INSERT INTO @camByUser
			SELECT cam_id
				,0
			FROM ccCamps
			WHERE (
					IDArea > 0
					OR IDArea IS NULL
					)
				AND (
					@campID IS NULL
					OR cam_id = @campID
					)
		END

		WHILE EXISTS (
				SELECT *
				FROM @camByUser
				WHERE isCheck = 0
				)
		BEGIN
			SELECT TOP 1 @camId = camId
			FROM @camByUser
			WHERE isCheck = 0

			IF EXISTS (
					SELECT cam_id
					FROM ccoCallsOut
					WHERE cam_id = @camId
					)
			BEGIN
				INSERT INTO @tableExistsRec
				VALUES (
					@camId
					,1
					)
			END
			ELSE
			BEGIN
				INSERT INTO @tableExistsRec
				VALUES (
					@camId
					,0
					)
			END

			UPDATE @camByUser
			SET isCheck = 1
			WHERE camId = @camId
		END

		SELECT a1.cam_id
			,cam_Descripcion
			,cam_tNotas
			,cast(cam_ocupado AS INT) AS cam_ocupado
			,cam_noInt_ocupado
			,cam_inter_ocupado
			,cast(cam_nocontesto AS INT) AS cam_nocontesto
			,cam_noInt_nocontesto
			,cam_inter_nocontesto
			,cast(cam_fax AS INT) AS cam_fax
			,cam_noInt_fax
			,cam_inter_fax
			,cast(cam_modomanual AS INT) AS cam_modomanual
			,ANI
			,cam_ShowCalifWnd
			,cam_StartTimerOnHangUp
			,editableCallKey
			,cam_tNoContesta
			,iTipoDial
			,detectAnswerMachine
			,detectVoiceMail
			,compliance
			,cam_inter_graba
			,cam_noint_graba
			,cast(progDial AS TINYINT) progDial
			,cast(excCallBack AS TINYINT) excCallBack
			,dialOrder
			,dialPrefix
			,dialPrefixMan
			,dialPrefixXfe
			,listenManualCall
			,stopRecording
			,cast(abandonCallback AS TINYINT) abandonCallback
			,a3.frame
			,a1.t_autoCB
			,a1.id_anilist
			,a1.tDialonWrapUp
			,dbo.fn_viewMode(@User_id, 10) viewMode
			,cam_maxqueue AS queSize
			,DNCScrub
			,callerIdDesc
			,timeZoneRule
			,callsBySurvey
			,ivrScript
			,surveyPctg
			,isnull(a1.call_record, 1) AS call_record
			,cast(startStopRecording AS TINYINT) startStopRecording
			,leaveRecMessage
			,manualCallOnChat
			,callBackSurveyAgent
			,callBackSurveyClient
			,CASE 
				WHEN surveycamid IS NULL
					OR surveycamid = 0
					THEN 0
				ELSE 1
				END isRelationSurvey
			,isnull(a1.funcEspDtmf, 0)
			,isnull(sipHdrFormat,'''' ) sipHdrFormat
			,cam_inter_cancelled
			,prefijo
			,enbleprefix = CASE 
				WHEN existRec = 0
					THEN 1
				ELSE 0
				END
			,isnull(exitAssisted, 0) exitAssisted
			,isnull(previewDiscard, 0) PreviewDiscard	
			,isnull(CampType, 0) CampType
			,isnull(contact.conexionInfo, '''') conexionInfo
			,isnull(contact.connUser,'''' ) connUser
			,isnull(contact.closeConversationTime, 0) closeConversationTime
			,isnull(contact.answerTimeoutClient, 0) answerTimeoutClient
			,isnull(contact.allowFileAttachments, 0) allowFileAttachments
			,isnull(selectRotativeANI, 0) selectRotativeANI
			,ISNULL(rotativeAlgo, 0) rotativeAlgo
			,isnull(autoStart, 0) autoStart
			,isnull(messagingOrder, 0) messagingOrder
			,ISNULL(cam_tPreview, 0) AS CamTPreview
			,ISNULL(timesPreview, 0) AS TimesPreview
			,isnull(timesDiscard, 0) TimesDiscard
			,ISNULL(recordHold, 0) recordHold
			,isnull(campsExtention.zipCodeSchedule, 0) ZipCodeSchedule
			,isnull(campsExtention.RecordCalls, 1) RecordCalls
			,isnull(campsExtention.simultaneousRecs, 1) simultaneousRecs
			,isnull(campsExtention.EditableContactData, 0) EditableContactData
			,@intenationalDialingPorts intenationalDialingPorts 
			,isnull(campsExtention.AssignConversationSameAgent, 0) AssignConversationSameAgent
			,ISNULL(contact.maxLimitQueueConversations, 99) maxLimitQueueConversations
			,isnull(contact.MaxDaysPerWAConvo, 5) MaxDaysPerWAConvo
		FROM ccCamps a1
		INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
		INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
		INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
		LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
		LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
		ORDER BY cam_descripcion

		RETURN (0)

		SET NOCOUNT OFF
		'
		EXEC (@sql)

		SET @process = 'K02014 Se elimina SP ccsp_GalateaGetOutboundConfiguration'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetOutboundConfiguration'')
					begin
						DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration;
					end'
		EXEC(@sql)

		SET @process = 'KO20140 Create SP con las modificaciones para obtener el valor DaysVisualConversationWhatsApp'
		SET @sql = 'CREATE PROCEDURE ccsp_GalateaGetOutboundConfiguration
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
    FROM @AllCampaigns
    WHERE cam_id = @campID
END'
		EXEC (@sql)

		
		SET @process = 'K020140 Se elimina SP ccsp_UpdateOutWhatsappConfig'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_UpdateOutWhatsappConfig'')
					begin
						DROP PROCEDURE ccsp_UpdateOutWhatsappConfig;
					end'
		EXEC(@sql)

		SET @process = 'K02014 Create SP con las modificaciones para actualizar el valor DaysVisualConversationWhatsApp'
		SET @sql = 'CREATE PROCEDURE ccsp_UpdateOutWhatsappConfig
	            @ConexionInfo varchar(400),
	            @outbound_id int,
	            @descripcion varchar(400), 
	            @ConnUser varchar(60),
	            @tNotas int,
	            @closeConversationTime int,
	            @ShowCalifWnd bit,
	            @ExitAssisted bit,
	            @MUTimeOutClient int,
	            @allowFileAttachments bit,
	            @userId SMALLINT, 
	            @idArea SMALLINT, 
	            @isCreating SMALLINT,
		    @maxLimitQueueConversations SMALLINT, 
				@maxDaysPerWAConvo SMALLINT

	            AS
	            set nocount on
	            IF NOT EXISTS (SELECT camp_id FROM ContactMeanOut WHERE camp_id = @outbound_id) BEGIN

	                INSERT INTO contactMeanOut (meanContactTypeId, name, camp_id, isActive, numMessages,conexionInfo,connUser,closeConversationTime,ConnPass,answerTimeoutClient,allowFileAttachments, maxLimitQueueConversations, MaxDaysPerWAConvo)
	                VALUES (5, @descripcion, @outbound_id, (select cam_activo  from ccCamps where cam_id = @outbound_id), 3, NULL, NULL, NULL, ''N/A'', NULL, NULL, NULL,5);

	            END

	                        IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

	                        Create table #contactMeanOutTable 
	                        (
	                            columnInfo VARCHAR(255),
	                            dataInfo VARCHAR(255),
	                            identifierInfo VARCHAR(255)
	                        )

	                        EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @outbound_id, @userId= @userid


	                        UPDATE contactMeanOut SET
	                            conexionInfo = @conexionInfo,
	                            connUser = @connUser,
	                            closeConversationTime = @closeConversationTime,
	                            answerTimeoutClient = @MUTimeOutClient,
	                            allowFileAttachments = @allowFileAttachments,
				    maxLimitQueueConversations = @maxLimitQueueConversations,
					MaxDaysPerWAConvo = @maxDaysPerWAConvo 
	                        WHERE camp_id = @outbound_id

	                        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @outbound_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';

	                        DELETE FROM #contactMeanOutTable WHERE dataInfo = '''';

	                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
	                        SELECT 
	                            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
	                            getDate(), 
	                            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
	                            46, 
	                            3, 
	                            CMOT.identifierInfo,
	                            CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
	                                CASE
	                                    WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
	                                        CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
	            
	                                    ELSE CMOT.dataInfo END
	                            ELSE '''' END, 
	                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @outbound_id)
	                        FROM #contactMeanOutTable AS CMOT;

	                        EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @outbound_id, @userId = @userid;
	                        IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

	                        UPDATE ccWhatsAppNumbers SET camp_id = @outbound_id WHERE number = @conexionInfo

	            IF EXISTS (SELECT cam_id FROM ccCamps WHERE cam_id = @outbound_id) 
	            BEGIN

	                        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

	                        Create table #ccCampsTable 
	                        (
	                            columnInfo VARCHAR(255),
	                            dataInfo VARCHAR(255),
	                            identifierInfo VARCHAR(255)
	                        )

	                        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @outbound_id, @userId= @userid

	                        UPDATE ccCamps SET cam_tnotas = @tNotas, cam_ShowCalifWnd = @ShowCalifWnd, exitAssisted = @ExitAssisted, CampType = 5 where cam_id = @outbound_id;

	                        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @outbound_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

	                        DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'');

	                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
	                        SELECT 
	                            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
	                            getDate(), 
	                            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
	                            46, 
	                            3, 
	                            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
	                                CASE WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN ''OUT_WHATS_EXIT_ASSISTED''
	                                ELSE CCCT.identifierInfo END
	                            ELSE CCCT.identifierInfo END,
	                            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
	                                CASE
	                                    WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'') THEN
	                                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
	            
	                                    ELSE CCCT.dataInfo END
	                            ELSE '''' END, 
	                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @outbound_id)
	                        FROM #ccCampsTable AS CCCT;

	                        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @outbound_id, @userId = @userid;
	                        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

	            END;
	            SELECT @outbound_id;

	            set nocount off'
		EXEC (@sql)

		
		SET @process = 'K020140 Se elimina SP ccsp_RIAUpdateCamConfig'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateCamConfig'')
					begin
						DROP PROCEDURE ccsp_RIAUpdateCamConfig;
					end'
		EXEC(@sql)


		SET @process = 'K020140 Se crea Sp con modificaciones para actualizar obtener y actualizar cambios en creación de campaña'
		SET @sql = '
	CREATE PROCEDURE ccsp_RIAUpdateCamConfig
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
	@rotativeAlgo tinyint = null,
	@timesPreview tinyint = null,
	@cam_tPreview smallint = null,
	@timesDiscard tinyint = null,
	@CampType int = null,
	@agentCloseConversationTime SMALLINT = NULL,
	@adminCloseConversationTime INT = NULL,
	@ConexionInfo VARCHAR(400) = NULL,
	@allowFileAttachments BIT = NULL,
	@selectRotativeANI int = null,
	@messagingOrder bit = null,
	@autoStart bit = null,
	@recordHold bit = null,
	@userId                SMALLINT     = NULL, 
	@idArea                SMALLINT     = NULL, 
	@isCreating            SMALLINT          = NULL,
	@camCanceled int = null,
	@recordIvr bit = null,
	@module INT = -1,
	@maxLimitQueueConversations SMALLINT = NULL,
	@maxDaysPerWAConvo SMALLINT = NULL
	as
	set nocount on
	
	IF EXISTS (SELECT 1 FROM ccCamps WHERE cam_descripcion = @cam_descripcion AND cam_id <> @cam_id)
	BEGIN
		SELECT -1 -- Nombre ya esta en uso
		RETURN(0)
	END
	
	DECLARE @timesDiscardActual int = -1, @camCanceledActual int = -1, @recordIvrActual int = -1
	SELECT @timesDiscardActual = timesDiscard, @camCanceledActual = camcanceled, @recordIvrActual = recordIvr FROM ccCamps WHERE cam_id = @cam_id
	DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)
		DECLARE @PrevName VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
		EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

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
		rotativeAlgo = isnull(@rotativeAlgo, rotativeAlgo),
		timesPreview = isnull(@timesPreview, timesPreview),
		cam_tPreview = isnull(@cam_tPreview,cam_tPreview),
		timesDiscard = isnull(@timesDiscard, timesDiscard),
		CampType = (CASE WHEN @callsBySurvey is not null AND @ivrScript is not null THEN
						CASE WHEN @callsBySurvey=0 and @ivrScript=0 THEN 0 
							ELSE 8 
						END
					WHEN @CampType is not null THEN @CampType 
					WHEN @progDial = 2 THEN 6 
					WHEN @progDial IS NOT NULL AND @progDial <> 2 THEN 0 
					WHEN CampType is not null THEN CampType ELSE 0 END),
		selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
		messagingOrder = isnull(@messagingorder, messagingOrder),
		autoStart = isnull(@autoStart,autoStart),
		recordHold = isnull(@recordHold, recordHold),
	CamCanceled = ISNULL(@camCanceled, CamCanceled),
	recordIvr = isnull(@recordIvr, recordIvr)

		Where cam_id = @cam_id

			IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

			Create table #ccCampsTable 
			(
				columnInfo VARCHAR(255),
				dataInfo VARCHAR(255),
				identifierInfo VARCHAR(255)
			)

			DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN 
																		CASE 
																			WHEN @Camptype = 6  THEN 44
																			WHEN @Camptype = 5  THEN 46
																			WHEN @Camptype = 4  THEN 48
																			WHEN @Camptype = 7  THEN 50
																			ELSE 42 END
																	ELSE 
																		CASE 
																			WHEN @Camptype = 6  THEN 55
																			WHEN @Camptype = 5  THEN 56
																			WHEN @Camptype = 4  THEN 57
																			WHEN @Camptype = 7  THEN 58
																			ELSE 54 END
																	END;
			
			IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

			IF(@isCreating = 1) 
			BEGIN
				DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
				IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''camCanceled'') and dataInfo = 4) DELETE FROM #ccCampsTable WHERE columnInfo IN (''camCanceled'');
				IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''recordIvr'') and dataInfo = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''recordIvr'');
			END

			IF(@isCreating = 2) 
			BEGIN
				IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''recordIvr'') and dataInfo = 1) AND @recordIvrActual is null DELETE FROM #ccCampsTable WHERE columnInfo IN (''recordIvr'');
				IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''camCanceled'') and dataInfo = 4) and @camCanceledActual is null DELETE FROM #ccCampsTable WHERE columnInfo IN (''camCanceled'');				
			END
				
			DELETE FROM #ccCampsTable WHERE columnInfo IN (''startStopRecording'');
			DELETE FROM #ccCampsTable WHERE dataInfo = '''''''';
				
			IF(@CampType = 6) DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'', ''cam_fDialOnWU'', ''ProgDial'');
			ELSE IF(@CampType = 5 AND @isCreating = 2) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'', ''cam_descripcion'', ''exitAssisted'');
			ELSE IF(@CampType = 5) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'');
			ELSE IF(@CampType = 7) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''messagingOrder'', ''autoStart'', ''rotativeAlgo'', ''id_anilist'', ''cam_descripcion'');
			ELSE DELETE FROM #ccCampsTable WHERE columnInfo IN (''previewDiscard'', ''CampType'', ''cam_fDialOnWU'', ''ProgDial'');

			IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
			SELECT 
				(SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
				getDate(), 
				(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
				@operation, 
				@module,
				CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> ''''
					THEN
						CASE
							WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN
								CASE WHEN @isCreating = 1 THEN '''' ELSE CCCT.identifierInfo END
							WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN 
								CASE WHEN @CampType = 5 THEN ''OUT_WHATS_EXIT_ASSISTED'' ELSE CCCT.identifierInfo END
							WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
								CASE WHEN @Camptype = 5 THEN ''OUT_MANUAL_DIALING_WHATS'' ELSE CCCT.identifierInfo END
							ELSE
								CCCT.identifierInfo
							END
					ELSE
					''''
					END,
				CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
					CASE 
						WHEN CCCT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
							CASE WHEN CCCT.dataInfo = ''VOICEMAIL'' 
								THEN ''COMMON_VOICE_MAIL'' 
								ELSE 
									CASE WHEN CCCT.dataInfo IS NOT NULL THEN CCCT.dataInfo ELSE ''T&COMMON_NONE'' END 
								END
						WHEN CCCT.identifierInfo = ''OUT_DIALING_ORDER'' THEN 
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_DESCENDING'' ELSE ''COMMON_ASCENDING'' END

						WHEN CCCT.identifierInfo = ''OUT_SMS_MESSAGING_ORDER'' THEN 
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ASCENDING'' ELSE ''COMMON_DESCENDING'' END

						WHEN CCCT.identifierInfo = ''OUT_ANSWER_MACHINE_DETC'' THEN 
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_BASIC'' 
								WHEN CCCT.dataInfo = 1 THEN ''COMMON_LIGHT''
								WHEN CCCT.dataInfo = 2 THEN ''COMMON_MODERATE''
								WHEN CCCT.dataInfo = 3 THEN ''COMMON_HIGH''
								ELSE ''T&COMMON_NONE'' END

						WHEN CCCT.identifierInfo = ''OUT_ANI_MODE'' THEN 
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ANI_LOCAL'' 
								WHEN CCCT.dataInfo = 1 THEN ''COMMON_ANI_ROTATIVE''
								WHEN CCCT.dataInfo = 2 THEN ''COMMON_ANI_ROTATIVE_REG''
								WHEN CCCT.dataInfo = 3 THEN ''COMMON_ANI_ROTATIVE_SMART''
								ELSE ''T&COMMON_NONE'' END

						WHEN CCCT.identifierInfo = ''OUT_DIALING_MODE'' THEN 
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_PREDICTIVE'' 
								WHEN CCCT.dataInfo = 1 THEN ''COMMON_PROGRESIVE''
								ELSE ''COMMON_ASSISTED'' END

						WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
							CASE WHEN  @CampType = 5 THEN 
								CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
							ELSE
								CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_VIA_KEYPAD_LOG''
									WHEN CCCT.dataInfo = 2 THEN ''COMMON_VIA_CALLS_LOG''
									WHEN CCCT.dataInfo = 3 THEN ''COMMON_VIA_CALLS_LOG''
									ELSE ''T&COMMON_NONE'' END
							END

						WHEN CCCT.identifierInfo = ''OUT_ANI_LIST'' THEN
									ISNULL((SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo), CCCT.dataInfo)

						WHEN CCCT.identifierInfo = ''OUT_CONDUCT_SURVEY'' THEN
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
						WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING_ON_CHAT'', ''OUT_TIME_ZONE_VALIDATION_MANUAL'', ''OUT_INTENSIVE_DIALING'', ''OUT_CALLBACK_EXCLUSIVE_AGENT'', ''OUT_VOIEMAIL_DETECTION'',
													''OUT_CALLBACK_FAILED'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'', ''OUT_EDIT_CALL_KEY'', ''OUT_STOP_RECORDING'', ''OUT_LEAVE_PRERECORDED'',
													''OUT_CONDUCT_CALLBACK_SURVEY'', ''OUT_RECEIVE_DTMF'', ''OUT_SELECT_ANI_ON_DIALING'', ''OUT_SMS_START_CAMP_AUTO'', ''OUT_RECORD_ON_HOLD'', ''OUT_LISTEN_TONE'', ''OUT_UNASSIGN_RECORDS'') THEN
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
						WHEN CCCT.identifierInfo = ''STOP_RECORDING_IVR_TRANSFER'' THEN
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
							
						ELSE CCCT.dataInfo END
				ELSE '''' END, 
				CASE WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN @PrevName ELSE (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id) END
			FROM #ccCampsTable AS CCCT;

			EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
			IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

	if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
	begin
		EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
	end

	IF (@CampType IS NOT NULL AND @CampType IN (3, 5))
	BEGIN
		IF NOT EXISTS(SELECT camp_id FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id)
		BEGIN
			SELECT 0
			RETURN(0)
		END

		IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

		Create table #contactMeanOutTable 
		(
			columnInfo VARCHAR(255),
			dataInfo VARCHAR(255),
			identifierInfo VARCHAR(255)
		)

		EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @cam_id, @userId= @userid

		DECLARE @PrevConexionInfo VARCHAR(MAX) = (SELECT [conexionInfo] FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id);

		set @ConexionInfo = case when  @ConexionInfo is null or @ConexionInfo in('''',''0'',''None'',''Ninguno'') then CASE WHEN @isCreating > 0 AND @PrevConexionInfo <> '''' THEN ''Ninguno'' ELSE '''' END else @ConexionInfo end
		UPDATE contactMeanOut SET conexionInfo = @ConexionInfo, ConnPass = @ConexionInfo, connUser = @ConexionInfo,
												closeConversationTime = CAST(@agentCloseConversationTime AS INT), answerTimeoutClient = @adminCloseConversationTime,
								allowFileAttachments = @allowFileAttachments,
					maxLimitQueueConversations = @maxLimitQueueConversations,
					MaxDaysPerWAConvo = @maxDaysPerWAConvo
		WHERE @CampType = meanContactTypeId AND camp_id = @cam_id

			
		IF(@isCreating > 0 AND @module > -1) BEGIN 
			EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';
			IF(@ConexionInfo IS NULL OR @ConexionInfo IN ('''',''0'',''None'',''Ninguno'') AND @PrevConexionInfo <> @ConexionInfo) UPDATE contactMeanOut SET conexionInfo = '''' WHERE @CampType = meanContactTypeId AND camp_id = @cam_id
		END

		DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''conexionInfo'') AND  dataInfo = '''''''';
		DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''ConnPass'', ''connUser'') ;

		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		SELECT 
			(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
			getDate(), 
			(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
			@operation, 
			@module, 
			CMOT.identifierInfo,
			CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
				CASE
					WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
						CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
					WHEN CMOT.identifierInfo = ''OUT_WHATS_ASSOCIATED_PHONE'' THEN
						CASE WHEN CMOT.dataInfo = ''Ninguno'' THEN ''COMMON_NONE_O'' ELSE CMOT.dataInfo END
					ELSE CMOT.dataInfo END
			ELSE '''' END, 
			(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
		FROM #contactMeanOutTable AS CMOT;

		EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid;
		IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

		IF @CampType = 5 BEGIN
			update ccWhatsAppNumbers set camp_id=0 where camp_id=@cam_id
			update ccMetaWhatsAppNumbers set Cam_Id=0 where Cam_Id=@cam_id

			IF(@ConexionInfo <> '''')
			BEGIN
				IF EXISTS (SELECT number FROM ccWhatsAppNumbers WHERE number = @ConexionInfo)
					UPDATE ccWhatsAppNumbers SET camp_id = @cam_id WHERE number = @ConexionInfo
				IF EXISTS (SELECT number FROM ccMetaWhatsAppNumbers WHERE number = @ConexionInfo)
					UPDATE ccMetaWhatsAppNumbers SET Cam_Id = @cam_id WHERE number = @ConexionInfo
			END
		END
	END 
	DECLARE @prevCalif BIT = (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id);

	IF @cam_ShowCalifWnd = 1
	BEGIN
		IF NOT EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @cam_id and tipo = 1)
		BEGIN
			SELECT 0
			RETURN(0)
		END

		UPDATE ccCamps SET
		cam_ShowCalifWnd = ISNULL(@cam_ShowCalifWnd,cam_ShowCalifWnd)
		WHERE cam_id = @cam_id


		IF(@prevCalif <> @cam_ShowCalifWnd AND @isCreating > 0) BEGIN
			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
			SELECT 
				(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
				getDate(), 
				(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
				@operation, 
				3, 
				''OUT_SHOW_DISPOSITIONS'',
				CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
				(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
		END

		SELECT 1
		RETURN(0)
	END

	UPDATE ccCamps SET
	cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
	where cam_id = @cam_id

	IF(@prevCalif <> @cam_ShowCalifWnd AND @isCreating > 0) BEGIN
		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		SELECT 
			(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
			getDate(), 
			(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
			@operation, 
			3, 
			''OUT_SHOW_DISPOSITIONS'',
			CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
			(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
	END

	SELECT 2
	RETURN(0)

	set nocount off'
		EXEC(@sql)
		
------------------------------------------- end Gaby ----------------------------------------------------------

		------------------------------------------------- Start Isaac -------------------------------------------------
		SET @process = 'K020118 Se elimina SP ccsp_MetaWAOutboundTemplates'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_MetaWAOutboundTemplates'')
					begin
						DROP PROCEDURE ccsp_MetaWAOutboundTemplates;
					end'
		EXEC(@sql)

		SET @process = 'K020118 Se crea SP ccsp_MetaWAOutboundTemplates con modificacion en accion 9 para obtener el valor correcto de IsEditable'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_MetaWAOutboundTemplates]
			@action TINYINT = NULL,
			@whatsAppTemplateID BIGINT = 0,
			@id varchar(200) = NULL,
			@Category varchar(50) = NULL,
			@TemplateName varchar(512) = NULL,
			@AllowCategoryChange tinyint = NULL,
			@LanguageCode varchar(10)= NULL,
			@Status varchar(200)= NULL, 
			@header nvarchar(max)= null,
			@body nvarchar(max) = null,
			@footer nvarchar(max) = null,
			@buttons nvarchar(max) = null,
			@metaStatus varchar(30) = NULL,
			@FilePath varchar(1024) = null,
			@HistoryLog varchar(max) = null,
			@campId SMALLINT = NULL,
			@UserId	SMALLINT = 0,
			@MetaId INT = 0
		AS
		BEGIN
			IF(@action = 1) -- get template by id
			BEGIN
				SELECT 
				cmwot.Id 
				,cmwot.TemplateName AS Name
				,cmwot.Status AS Status
				,Category AS Category
				,ISNULL(cmwot.notes, '''' ) AS Notes
				,cmwot.header AS Header
				,Body
				,cmwot.footer AS Footer
				,cmwot.buttons AS Buttons
				,cmwot.LanguageCode
				,ISNULL(cmwot.quality,0) AS Quality
				,cmwot.IsPendingQuality
				,cmwot.FilePath
				,cmwot.Status AS Status
				FROM  dbo.ccMetaWAOutboundTemplates AS cmwot
				WHERE cmwot.Id = @whatsAppTemplateID
			END
			ELSE IF(@action = 2)
			BEGIN
				SELECT cmwan.MetaId AS Id, cmwan.Number FROM dbo.ccMetaWhatsAppNumbers AS cmwan
				Left JOIN dbo.ccMetaWhatsAppConfigurations AS cmwac
				ON cmwan.MetaId = cmwac.Id
				WHERE cmwan.Status = 1
			END
			ELSE IF(@action = 3)
			BEGIN
				UPDATE ccMetaWAOutboundTemplates SET StatusCW = 0 WHERE Id = @whatsAppTemplateID
				SELECT @@ROWCOUNT;
				RETURN 0;
			END
			ELSE IF(@action = 4) --create
			BEGIN
				insert into ccMetaWAOutboundTemplates (Id, Category,TemplateName,AllowCategoryChange,LanguageCode,Status,header,body,footer,buttons,FilePath,MetaId,StatusCW)
									values (@Id, @Category,@TemplateName,@AllowCategoryChange,@LanguageCode,@Status,@header,@body,@footer,@buttons,@FilePath,@MetaId,1)
			END
			ELSE IF(@action = 5) -- Get Template Config By Id
			BEGIN
				SELECT n.WAAccountId, n.Token, c.Url as [Url], t.TemplateName 
				FROM ccMetaWAOutboundTemplates t
				INNER JOIN ccMetaWhatsAppNumbers n on t.MetaId = n.MetaId
				left JOIN ccMetaWhatsAppConfigurations c on c.Id = 2
				WHERE t.Id = @whatsAppTemplateID
				RETURN 0;
			END
			ELSE IF(@action = 6) -- update status to delete
			BEGIN
				DECLARE @newStatus bit = 1;
				IF(@metaStatus = ''DELETED'')
				BEGIN
					SET @newStatus = 0
				END
				UPDATE ccMetaWAOutboundTemplates SET 
				[Status] = @metaStatus, 
				StatusCW = @newStatus,
				RemovalDate = ISNULL(RemovalDate, GETDATE())
				WHERE Id = @whatsAppTemplateID
				AND [StatusCW] = 1;
				SELECT @@ROWCOUNT;
				RETURN 0;
			END
			ELSE IF(@action = 7) -- Get template campaigns associated
			BEGIN
				SELECT ISNULL(n.Cam_Id,0) as Cam_Id, ISNULL(n.Inbound_Id,0) AS Inbound_Id FROM ccMetaWAOutboundTemplates t
				INNER JOIN ccMetaWhatsAppNumbers n on t.MetaId = n.MetaId
				left JOIN ccMetaWhatsAppConfigurations c on n.MetaId = c.Id
				WHERE t.Id = @whatsAppTemplateID
				RETURN 0;
			END
			ELSE IF (@action = 8) -- update template
			BEGIN
				DECLARE @tableHistoryLog TABLE (Id INT, Value VARCHAR(MAX))
				DECLARE @areaName VARCHAR(50),
						@login VARCHAR(50)

				SELECT
					@areaName = ca.AreaName,
					@login = cu.Login
				FROM ccUsers cu
				INNER JOIN ccRIACat_Areas ca with(nolock) ON cu.IDArea = ca.IDArea
				WHERE cu.User_id = @UserId

				INSERT INTO @tableHistoryLog 
				SELECT tb.Id, tb.Value
				FROM dbo.fn_RIASplitDelimited(@HistoryLog, '',,'') tb


				-- insert into activity log table and update template data
				IF @header IS NULL OR LEN(@header) = 0 AND (SELECT LEN(ISNULL(header,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when header is null or '''' and before update header contains data
				BEGIN
					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_HEADER'',''COMMON_NONE_O'',''root'')
				END
				IF @footer IS NULL OR LEN(@footer) = 0 AND (SELECT LEN(ISNULL(footer,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when footer is null or '''' and before update footer contains data
				BEGIN
					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_FOOTER'',''COMMON_NONE_O'',''root'')
				END
				IF @buttons IS NULL OR LEN(@buttons) = 0 AND (SELECT LEN(ISNULL(buttons,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when buttons is null or '''' and before update buttons contains data
				BEGIN
					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_BUTTONS'',''COMMON_NONE_O'',''root'')
				END
				
				EXEC InsertLogAdminGalatea @action=1, @tableName=''ccMetaWAOutboundTemplates'', @columnNameId=''Id'', @valueId= @Id, @userId= 1
				Create table #ccMetaWAOutboundTemplates 
				(
					columnInfo VARCHAR(MAX),
					dataInfo VARCHAR(MAX),
					identifierInfo VARCHAR(MAX)
				)

				UPDATE ccMetaWAOutboundTemplates
				SET Category = @Category,
					header = @header,
					body = @body,
					footer = @footer,
					buttons = @buttons,
					FilePath = @FilePath
				WHERE Id = @Id

				EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccMetaWAOutboundTemplates'', @columnNameId = ''Id'', @valueId = @Id, @userId = 1,  @tableTemp=''#ccMetaWAOutboundTemplates'';

				INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
				SELECT
					@areaName,
					GETDATE(),
					@login,
					122,
					20,
					cc.identifierInfo,
					tb1.Value,
					@id
				FROM #ccMetaWAOutboundTemplates cc
				INNER JOIN  @tableHistoryLog  tb1 ON cc.columnInfo = (CASE 
																		WHEN tb1.Id = 1 THEN ''Category''
																		WHEN tb1.Id = 2 THEN ''header'' 
																		WHEN tb1.Id = 3 THEN ''body'' 
																		WHEN tb1.Id = 4 THEN ''footer''
																		WHEN tb1.Id > 4 THEN ''buttons''
																		END)
			END
			else IF(@action = 9) -- get templates by phone number
			BEGIN
				;WITH tb1 as(
					SELECT
						gal.Target AS Id,
						MAX(gal.ActivityDate) AS Date
					FROM ccGalateaActivityLog gal 
					WHERE gal.OperationId = 122 
					AND gal.ModuleId = 20 
					AND CAST(gal.ActivityDate AS DATE) >= DATEADD(DD,-30, CAST(GETDATE() AS DATE))
					GROUP BY gal.Target, CAST(gal.ActivityDate AS DATE)
				)
				,TemplateIsEditable AS (
					SELECT
						tb1.Id,
						CASE WHEN COUNT(*) >= 10 THEN 2 WHEN MAX(tb1.Date) >= DATEADD(HOUR, -24, GETDATE()) THEN 1 ELSE 0 END AS IsEditable
					FROM tb1
					GROUP BY tb1.Id
				)
				SELECT 
				cmwot.Id 
				,cmwot.TemplateName AS Name
				,cmwot.Status AS Status
				,Category AS Category
				,ISNULL(cmwot.notes, '''' ) AS Notes
				,cmwot.header AS Header
				,Body
				,cmwot.footer AS Footer
				,cmwot.buttons AS Buttons
				,cmwot.LanguageCode
				,ISNULL(cmwot.quality,0) AS Quality
				,cmwot.IsPendingQuality
				,ISNULL(tie.IsEditable, 0) AS IsEditable
				,cmwot.FilePath
				FROM  dbo.ccMetaWAOutboundTemplates cmwot
				LEFT JOIN TemplateIsEditable tie ON tie.Id = CAST(cmwot.Id AS VARCHAR(MAX))
				WHERE cmwot.MetaId = @whatsAppTemplateID
				AND cmwot.StatusCW = 1
			END
			ELSE IF(@action = 10) -- Check if an other load is executing for the campaign
			BEGIN
				SELECT CASE WHEN COUNT(crl.load_id) > 0 THEN CONVERT(BIT , 1) ELSE CONVERT(BIT, 0) END AS IsProcessExecuting FROM dbo.ccRIALoading AS crl
				WHERE crl.cam_id = @campId AND crl.state IN (0,2) AND crl.loadType = 3;
			END
			ELSE IF(@action = 11) --Check if the campaign was eliminated or desasigned
			BEGIN
				DECLARE @campaignIsEliminateDesasigned BIT = 0;
				DECLARE @idAreaNull SMALLINT = 0;

				SELECT  @idAreaNull = cc.IDArea FROM dbo.ccCamps AS cc WHERE cc.cam_id = @campId

				IF(@idAreaNull IS NULL)
				BEGIN
					SET @campaignIsEliminateDesasigned = 1; --La campaña fue eliminada
				END

				IF NOT EXISTS(SELECT TOP 1 crcew.IdCampEsp FROM dbo.ccRIACampEspWG AS crcew INNER JOIN dbo.ccRIAWorkGroupUsers AS crwgu
				ON crwgu.IDWG = crcew.IDWG
				WHERE crwgu.User_id = @UserId AND crcew.Tipo = 1 AND crcew.IdCampEsp = @campId)
				BEGIN 
					SET @campaignIsEliminateDesasigned = 1; --La campaña fue desasignada del grupo de trabajo
				END

				SELECT @campaignIsEliminateDesasigned;
			END
			ELSE IF(@action = 12) --Get new numbers loaded in  ccWhatsAppOutSource 
			BEGIN
				SELECT cwt.Callkey FROM dbo.ccoWAWorkingTable AS cwt WHERE cwt.CamId = @campId AND cwt.WaStatus = 0
				UNION
				SELECT cwaos.CallKey FROM dbo.ccWhatsAppOutSource AS cwaos 
				WHERE cwaos.camId = @campId AND cwaos.Status = 0
			END
			IF(@action = 13) -- Get templates by campaign number assigned
			BEGIN
				SELECT 
				cmwot.Id 
				,cmwot.TemplateName AS Name
				,cmwot.Status AS Status
				,Category AS Category
				,ISNULL(cmwot.notes, '''' ) AS Notes
				,cmwot.header AS Header
				,Body
				,cmwot.footer AS Footer
				,cmwot.buttons AS Buttons
				,cmwot.LanguageCode
				,ISNULL(cmwot.quality,0) AS Quality
				,cmwot.IsPendingQuality
				,cmwot.FilePath
				FROM  dbo.ccMetaWAOutboundTemplates AS cmwot
				INNER JOIN dbo.ccMetaWhatsAppNumbers AS cmwan ON 
				cmwot.MetaId = cmwan.MetaId
				WHERE cmwot.StatusCW = 1 AND cmwan.Cam_Id = @campId AND cmwot.Status = ''APPROVED''
			END
			ELSE IF (@action = 14) -- check if campaing exists
			BEGIN
				IF EXISTS(SELECT 1 FROM dbo.ccMetaWAOutboundTemplates cmwot WHERE cmwot.Id = @whatsAppTemplateID)
					SELECT 1
				ELSE
					SELECT 0
			END
		END
		'
		EXEC(@sql)
		-------------------------------------------------  END Isaac  -------------------------------------------------

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
