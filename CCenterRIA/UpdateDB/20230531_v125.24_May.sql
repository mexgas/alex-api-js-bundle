/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 24
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci�n para cuando pasamos a una nueva versi�n LTS
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

	---------------------------------------BEGIN Ricardo ---------------------------------------------------------

	SET @process = 'Add column SimultaneousRecs'
	SET @sql = '
	if not exists (select * from sys.columns where name = N''SimultaneousRecs'' and Object_ID = Object_ID(N''ccCampsExtend''))
	begin
		alter table ccCampsExtend add SimultaneousRecs smallint null
	end
	'
	EXEC(@sql)

	SET @process = 'Drop SP ccsp_RIAConfCamp'
	SET @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_RIAConfCamp'')
			BEGIN
				DROP PROCEDURE [dbo].[ccsp_RIAConfCamp]
			END'
	EXEC(@sql)

	SET @process = 'Add column SimultaneousRecs to ccsp_RIAConfCamp'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_RIAConfCamp] @User_id SMALLINT, @campID INT = NULL
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
		,isnull(sipHdrFormat, '''') sipHdrFormat
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
		,isnull(contact.connUser, '''') connUser
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
		,isnull(campsExtention.simultaneousRecs, 1) simultaneousRecs
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
	EXEC(@sql)

	SET @process = 'Drop SP ccsp_GalateaGetOutboundConfiguration'
	SET @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_GalateaGetOutboundConfiguration'')
			BEGIN
				DROP PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]
			END'
	EXEC(@sql)

	SET @process = 'Add column SimultaneousRecs to ccsp_GalateaGetOutboundConfiguration'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT
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
	,closeConversationTime SMALLINT
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
	,simultaneousRecs smallint
	)
	DECLARE @numbers VARCHAR(max)

	SELECT @numbers = COALESCE(@numbers + '''', '''', '''''''') + number
	FROM ccWhatsAppNumbers
	WHERE camp_id = 0
	AND STATUS = 1

	INSERT INTO @AllCampaigns
	EXEC ccsp_RIAConfCamp @adminID
	,@campID

	SELECT dialPrefixMan DialPrefixMan
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
	,simultaneousRecs SimultaneousRecs
	FROM @AllCampaigns
	WHERE cam_id = @campID
	END
	'
	EXEC(@sql)

	SET @process = 'Drop SP ccsp_RIAUpdateCamConfigExtend'
	SET @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_RIAUpdateCamConfigExtend'')
			BEGIN
				DROP PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
			END'
	EXEC(@sql)

	SET @process = 'Add column SimultaneousRecs to ccsp_RIAUpdateCamConfigExtend'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
		@cam_id smallint,
		@zipCodeSchedule BIT = NULL,
		@userId	SMALLINT = NULL,
		@idArea SMALLINT = NULL, 
		@isCreating SMALLINT = NULL,
		@simultaneousRecs SMALLINT = NULL,
		@module INT = -1
	AS
	BEGIN
		SET NOCOUNT ON;
		if exists(select * from ccCampsExtend where cam_id=@cam_id) begin

			EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCampsExtend'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

			IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

			Create table #ccCampsExtendTable 
			(
				columnInfo VARCHAR(255),
				dataInfo VARCHAR(255),
				identifierInfo VARCHAR(255)
			)

			DECLARE @Camptype INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @cam_id);
			DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN 
																		CASE 
																			WHEN @Camptype = 6	THEN 44
																			WHEN @Camptype = 5	THEN 46
																			WHEN @Camptype = 4	THEN 48
																			WHEN @Camptype = 7	THEN 50
																			ELSE 42 END
																	ELSE 
																		CASE 
																			WHEN @Camptype = 6	THEN 55
																			WHEN @Camptype = 5	THEN 56
																			WHEN @Camptype = 4	THEN 57
																			WHEN @Camptype = 7	THEN 58
																			ELSE 54 END
																	END;

			UPDATE ccCampsExtend SET
				zipCodeSchedule = isnull(@zipCodeSchedule,zipCodeSchedule),
				simultaneousRecs = isnull(@simultaneousRecs,simultaneousRecs)
			Where cam_id = @cam_id	

			IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsExtendTable'';

			IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
			SELECT 
				(SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
				getDate(), 
				(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
				@operation, 
				@module, 
				CCCE.identifierInfo,
				CASE WHEN CCCE.identifierInfo IS NOT NULL AND CCCE.identifierInfo <> '''' THEN
					CASE 
						WHEN CCCE.identifierInfo IN (''SETTINGS_CHANGED_AREAS_ZIP'') THEN
							CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
						
						ELSE CCCE.dataInfo END
				ELSE '''' END, 
				(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
			FROM #ccCampsExtendTable AS CCCE;

			EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
			IF OBJECT_ID(N''tempdb..#ccCampsExtendTable'') IS NOT NULL DROP TABLE #ccCampsExtendTable

		end
		else begin
			INSERT INTO ccCampsExtend(cam_id,zipCodeSchedule) values (@cam_id,@zipCodeSchedule)
		end
		set nocount off
	END
	'
	EXEC(@sql)

	set @process = 'Create setting 248'
	set @sql = 'IF NOT EXISTS (SELECT * FROM ccSettings WHERE setting_id = 248) 
	BEGIN
		INSERT INTO [dbo].[ccSettings]
			([setting_id]
			,[valor]
			,[descripcion]
			,[Status]
			,[Tipo]
			,[detalle]
			,[description]
			,[bLoadSettings]
			,[validate])
		VALUES
			(248
			,0
			,''Permite determinar la forma en que deben ser asignados los registros al tener configurada la campaña con vista simultánea de registros >1''
			,1
			,''X''
			,''0: Asignar registros hasta que el agente termine de atender los registros que tiene asignados por el sistema (valor default). 1: Asignar registros conforme el agente libere registros previamente asignados (dependiendo de cómo tenga configurado el parámetro vista simultánea de registros la campaña que está trabajando el agente)''
			,''It allows determining the way records should be assigned when the campaign is configured with simultaneous viewing of records >1''
			,0
			,''.*'')
	END'
    EXEC(@sql)

	---------------------------------------END Ricardo ---------------------------------------------------------
	---------------------------------------BEGIN Gabriela ---------------------------------------------------------
	SET @process = 'add module calls by agent'
	SET @sql = 'if not exists (select * from ccGalateaModules where ModuleId=4)
	begin
	  insert into ccGalateaModules(ModuleId,MTagEs,MTagEn,MTagPt) values (4,''Factor de marcación fijo'',''Fixed dialing rate'',''Fator de discagem fixo'')
	end';
	EXEC(@sql);


	SET @process = 'Add operation calls by agent'
	SET @sql = 'if not exists (select * from ccGalateaOperations where OperationId=62)
	begin
	  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (62,''Editar llamadas por agente'',''Edit calls by agent'',''Editar chamadas por agente'')
	  insert into ccGalateaModOpRelation (ModuleId,OperationId) values(4,62)
	end';
	EXEC(@sql);

	
	SET @process = 'Add identifier calls by agent'
	SET @sql = 'if not exists (select * from ccGalateaIdentifiers where Description like ''%T$NUMBER_CALLS%'')
	begin
	  insert into ccGalateaIdentifiers(Description,TagEs,TagEn,TagPt) values (''T$NUMBER_CALLS'',''Número de llamadas'',''Number of calls'',''Número de chamadas'')
	end';
	EXEC(@sql);


	SET @process = 'Drop SP ccsp_GalateaConfAggrFct'
	SET @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_GalateaConfAggrFct'')
			BEGIN
				DROP PROCEDURE [dbo].[ccsp_GalateaConfAggrFct]
			END'
	EXEC(@sql);


	SET @process = 'Create SP ccsp_GalateaConfAggrFct'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaConfAggrFct]
@Type tinyint,    -- 1:Muestra | 2:Actualiza Camp | 3:Actualiza Todas por Usuario
@cam_id varchar(255) = null,
@User_id int = null,
@aggressionFactor float = null
AS
set nocount on
if @Type=1
 begin
	if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
			select cam_id, cam_Descripcion, aggressionFactor
			from ccCamps where cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
			order by cam_descripcion
		end
		else begin
			select cam_id, cam_Descripcion, aggressionFactor from ccCamps where cam_activo <> 0 and IDArea is not null
		end
    return(0)
 end

if @Type=2
 begin
    UPDATE ccCamps SET aggressionFactor = isnull(@aggressionFactor,aggressionFactor) 
    Where cam_id in (select value from dbo.fn_RIASplitDelimited(@cam_id, '',''))

	if @@ROWCOUNT > 0
		select cam_id, aggressionFactor, cam_descripcion as cam_description from ccCamps Where cam_id in (select value from dbo.fn_RIASplitDelimited(@cam_id, '',''))
    return(0)
 end

if @Type=3
 begin
	if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
			UPDATE ccCamps SET aggressionFactor = isnull(@aggressionFactor,aggressionFactor)
			Where cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))

			if @@ROWCOUNT > 0
				select cam_id, aggressionFactor, cam_descripcion as cam_description from ccCamps where cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
		end
		else begin
			UPDATE ccCamps SET aggressionFactor = isnull(@aggressionFactor,aggressionFactor)
			where cam_activo <> 0 and IDArea is not null

			if @@ROWCOUNT > 0
				select cam_id, aggressionFactor, cam_descripcion as cam_description from ccCamps where cam_activo <> 0 and IDArea is not null
		end
    return(0)
 end

set nocount off';
	EXEC(@sql);
	---------------------------------------END Gabriela ---------------------------------------------------------
	---------------------------------------BEGIN Frida ---------------------------------------------------------
	SET @process = ''
	SET @sql = 'if not exists (select * from sys.columns where name = N''allowSelectCamp'' and Object_ID = Object_ID(N''ccusers''))
    begin
	   alter table ccUsers add allowSelectCamp bit null
    end'
	EXEC(@sql);

	SET @process = ' DROP PROCEDURE ccsp_GalateaAdminGetPermissions'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminGetPermissions'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminGetPermissions
    end'
	EXEC(@sql);

	SET @process = 'create sp ccsp_GalateaAdminGetPermissions'
	SET @sql = 'Create PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
	@user_id varchar(255),
	@Type int
	AS
	set nocount on

	declare @isRoot int;

	if exists (Select Rol_id from ccUsers A join ccUsers_Roles B on A.User_id = B.User_id where A.User_id = @user_id and rol_id = 7) set @isRoot = 1 else set @isRoot = 0;
	print @isRoot

	IF @isRoot = 1
	BEGIN
		Select 
		User_id as AgentId, 
		Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
		cast(dialMask & 1 as int) as AllowCellPhoneCalls,
		cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
		cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
		cast( xfermask as int) as AllowTransferCalls, 
		cast(CanChangeStatus as tinyint) CanChangeStatus,
		cast(XferAgents as tinyint) XferAgents,
		ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
		cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
		ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
		ISNULL(agentsPermissions.AllowUnassign, 0) AS AllowUnassign,
		ISNULL(agentsPermissions.AllowSpam, 0 ) AS AllowSpam,
		ISNULL(agentsPermissions.AllowPlayRecordsOnCallHistory, 0) AS AllowPlayRecordsOnCallHistory,
		cast(AllowDeleteRecord as int) as AgentPermissionDelete,
		AllowMarks as AllowMarks,
		ISNULL(allowSelectCamp,0) as AllowSelectCamp
	from 
		ccUsers users
		left join ccRIAAgentsPermissions agentsPermissions on
		users.User_id = agentsPermissions.AgentId
	where 
	   tipoUser_id = 1
	return(0)
	END
	ELSE
	BEGIN
		Select distinct 
		A.User_id as AgentId, 
		Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
		cast(dialMask & 1 as int) as AllowCellPhoneCalls,
		cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
		cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
		cast( xfermask as int) as AllowTransferCalls, 
		cast(CanChangeStatus as tinyint) CanChangeStatus,
		cast(XferAgents as tinyint) XferAgents,
		ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
		cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
		ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
		ISNULL(agentsPermissions.AllowUnassign, 0) AS AllowUnassign,
		ISNULL(agentsPermissions.AllowSpam, 0 ) AS AllowSpam,
		ISNULL(agentsPermissions.AllowPlayRecordsOnCallHistory, 0) AS AllowPlayRecordsOnCallHistory,
		cast(AllowDeleteRecord as int) as AgentPermissionDelete,
		AllowMarks as AllowMarks,
		ISNULL(allowSelectCamp,0) as AllowSelectCamp
	from 
		ccUsers A
	join ccRIAWorkGroupUsers B on 
		A.user_id = B.user_id
	left join ccRIAAgentsPermissions agentsPermissions on
		A.User_id = agentsPermissions.AgentId
	where 
		tipoUser_id = 1 and 
		IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
	return(0)
	END
	set nocount off
	'
	EXEC(@sql);

	SET @process = 'Drop sp ccsp_GalateaAdminSetPermissions'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSetPermissions'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminSetPermissions
    end'
	EXEC(@sql);

	SET @process = 'create sp ccsp_GalateaAdminSetPermissions'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
	@adminId SMALLINT,
	@areaId SMALLINT,
	@agentsIds VARCHAR(MAX),
	@allAgentsSelected BIT, 
	@permissionName VARCHAR(255),
	@permissionValue INT
	AS
	SET NOCOUNT ON


	declare @changeBitTable table(permissionName VARCHAR(255), valueBit int)

	insert into @changeBitTable values(''AllowCellPhoneCalls'',1)
	insert into @changeBitTable values(''startStopRecording'',1)
	insert into @changeBitTable values(''XferManual'',1)
	insert into @changeBitTable values(''AllowTransferCalls'',1)
	insert into @changeBitTable values(''AgentPermissionDailing'',1)
	insert into @changeBitTable values(''DailingMode'',1)
	insert into @changeBitTable values(''AgentPermissionDelete'',1)
	insert into @changeBitTable values(''AllowSelectCamp'',1)

	insert into @changeBitTable values(''AllowLongDistanceCalls'',2)
	insert into @changeBitTable values(''XferExt'',2)

	insert into @changeBitTable values(''AllowLocalCalls'',4)
	insert into @changeBitTable values(''XferCamps'',4)

	insert into @changeBitTable values(''XferAgents'',8)

	DECLARE @changeBit INT

	set @changeBit=0

	select @changeBit=valueBit from @changeBitTable where permissionName=@permissionName

	--print(@changeBit)
	IF @agentsIds IS NOT NULL
	BEGIN
		DECLARE @AgentIdsTemp TABLE (AgentId INT, Status BIT)
		INSERT INTO @AgentIdsTemp SELECT VALUE, 0 FROM dbo.fn_RIASplitDelimited(@agentsIds,'','')

		IF @permissionName = ''AllowUnassign'' 
		BEGIN                       
			UPDATE permissions SET permissions.AllowUnassign = @permissionValue FROM @AgentIdsTemp agentIds
			INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

			INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory)
			SELECT agentIds.AgentId , @permissionValue, 0, 0 FROM @AgentIdsTemp agentIds
			LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
			WHERE permissions.AgentId IS NULL
		END
		IF @permissionName = ''AllowSpam''
		BEGIN 
			UPDATE permissions SET permissions.AllowSpam = @permissionValue FROM @AgentIdsTemp agentIds
			INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

			INSERT INTO ccRIAAgentsPermissions(AgentId, AllowSpam, AllowUnassign, AllowPlayRecordsOnCallHistory)
			SELECT agentIds.AgentId , @permissionValue, 0, 0 FROM @AgentIdsTemp agentIds
			LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
			WHERE permissions.AgentId IS NULL
		END

		IF @permissionName = ''AllowPlayRecordsOnCallHistory''
		BEGIN 
			UPDATE permissions SET permissions.AllowPlayRecordsOnCallHistory = @permissionValue FROM @AgentIdsTemp agentIds
			INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

			INSERT INTO ccRIAAgentsPermissions(AgentId, AllowPlayRecordsOnCallHistory, AllowSpam, AllowUnassign)
			SELECT agentIds.AgentId , @permissionValue, 0, 0 FROM @AgentIdsTemp agentIds
			LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
			WHERE permissions.AgentId IS NULL
		END

		UPDATE
			ccUsers
		SET DialMask =
			CASE
			WHEN @permissionName = ''AllowCellPhoneCalls''
			OR @permissionName = ''AllowLongDistanceCalls''
			OR @permissionName = ''AllowLocalCalls''
			THEN 
				CASE
				WHEN @permissionValue = 1
				THEN
					CASE
					WHEN (DialMask & @changeBit) <> @changeBit
					THEN DialMask ^ @changeBit
					ELSE DialMask
					END
				WHEN @permissionValue = 0
				THEN
					CASE
					WHEN (DialMask & @changeBit) = @changeBit
					THEN DialMask ^ @changeBit
					ELSE DialMask
					END
				END 
			ELSE DialMask
			END,
							
			XferMask =
			CASE
			WHEN @permissionName = ''AllowTransferCalls''
			THEN
				CASE
				WHEN @permissionValue = 1
				THEN
					CASE
					WHEN (XferMask & @changeBit) <> @changeBit
					THEN XferMask ^ @changeBit
					ELSE XferMask
					END
				WHEN @permissionValue = 0
				THEN
					CASE
					WHEN (XferMask & @changeBit) = @changeBit
					THEN XferMask ^ @changeBit
					ELSE XferMask
					END
				END
			ELSE XferMask
			END,

			XferAgents =
			CASE
			WHEN @permissionName = ''XferAgents''
			OR @permissionName = ''XferCamps'' 
			OR @permissionName = ''XferExt'' 
			OR @permissionName = ''XferManual'' 
			THEN 
				CASE
				WHEN @permissionValue = 1
				THEN
					CASE
					WHEN (XferAgents & @changeBit) <> @changeBit
					THEN XferAgents ^ @changeBit
					ELSE XferAgents
					END
				WHEN @permissionValue = 0
				THEN
					CASE
					WHEN (XferAgents & @changeBit) = @changeBit
					THEN XferAgents ^ @changeBit
					ELSE XferAgents
					END
				END
			ELSE XferAgents
			END,

			startStopRecording =
			CASE
			WHEN @permissionName = ''startStopRecording'' 
			THEN 
				CASE
				WHEN @permissionValue = 1
				THEN 1
				WHEN @permissionValue = 0
				THEN 0
				END
			ELSE startStopRecording
			END,

			DialingMode = 
			CASE
			WHEN @permissionName = ''DailingMode'' 
			THEN 
				CASE
				WHEN @permissionValue = 1
				THEN
					CASE
					WHEN (DialingMode & @changeBit) <> @changeBit
					THEN DialingMode ^ @changeBit
					ELSE DialingMode
					END
				WHEN @permissionValue = 0
				THEN
					CASE
					WHEN (DialingMode & @changeBit) = @changeBit
					THEN DialingMode ^ @changeBit
					ELSE DialingMode
					END
				END 
			ELSE DialingMode
			END,
			AllowChangeDialingMode = 
			CASE
			WHEN @permissionName = ''AgentPermissionDailing'' 
			THEN 
				CASE
				WHEN @permissionValue = 1
				THEN 1
				WHEN @permissionValue = 0
				THEN 0
				END
			ELSE AllowChangeDialingMode
			END,
			AllowDeleteRecord= 
			CASE
			WHEN @permissionName = ''AgentPermissionDelete'' 
			THEN 
				CASE
				WHEN @permissionValue = 1
				THEN 1
				WHEN @permissionValue = 0
				THEN 0
				END
			ELSE AllowDeleteRecord
			END,
			AllowMarks= 
			CASE
			WHEN @permissionName = ''AllowMarks'' 
			THEN 
				CASE
				WHEN @permissionValue = 1 THEN 1
				WHEN @permissionValue = 0 THEN 0
				END
			ELSE AllowMarks
			END,
			allowselectcamp=
			CASE
			WHEN @permissionName = ''AllowSelectCamp'' 
			THEN 
				CASE
				WHEN @permissionValue = 1
				THEN 1
				WHEN @permissionValue = 0
				THEN 0
				END
			ELSE allowselectcamp
			END
		WHERE User_id IN (SELECT AgentId FROM @AgentIdsTemp)

					
		DECLARE @Login VARCHAR(20) = (SELECT Login FROM ccUsers WHERE User_id = @adminId)
		DECLARE @AreaName VARCHAR(50) = (SELECT AreaName FROM ccRIACat_Areas WHERE IDArea = @areaId)
		DECLARE @OperationType TINYINT = (SELECT CASE WHEN @permissionValue = 1 THEN 33 ELSE 35 END)
		DECLARE @Language TINYINT = (SELECT valor FROM ccSettings WHERE setting_id = 27)
		DECLARE @Tag varchar(100) = (SELECT PermissionTag FROM ccRIAAgentsPermissionsTags WHERE PermissionName = @permissionName)        
		DECLARE @Value VARCHAR(250) = (SELECT permissions.Value 
										FROM  dbo.fn_RIASplitDelimited(@Tag,''|'') permissions
										WHERE permissions.Id = @Language + 1)

		DECLARE @AgentId INT = 0
		DECLARE @AgentName VARCHAR(20) = ''''

		set @Value = isnull(@Value,@permissionName)

		IF @allAgentsSelected = 0
		BEGIN
			WHILE EXISTS(SELECT * FROM @AgentIdsTemp WHERE Status = 0)
			BEGIN 
				SELECT TOP 1 @AgentId = AgentId FROM @AgentIdsTemp WHERE Status = 0
				SET @AgentName = (SELECT Login FROM ccUsers WHERE User_id = @AgentId)
						
				EXEC ccsp_RIA_ABCLog @option = 2, @areaName = @AreaName, @operationType = @OperationType, 
				@login = @Login, @moduleId = 4, @value = @Value , @target = @AgentName
							
				UPDATE @AgentIdsTemp SET Status = 1 WHERE AgentId = @AgentId
			END
		END
		ELSE
		BEGIN
			SET @AgentName = (SELECT AllAgentsTag FROM ccRIAUserPermissionsStatusTags WHERE Language = @Language)
						
			EXEC ccsp_RIA_ABCLog @option = 2, @areaName = @AreaName, @operationType = @OperationType, 
			@login = @Login, @moduleId = 4, @value = @Value , @target = @AgentName
							
			UPDATE @AgentIdsTemp SET Status = 1
		END


	END

	SET NOCOUNT OFF
'
	EXEC(@sql);

	SET @process = 'add column FinishRecordPreview'
	SET @sql = '
	if not exists (select * from sys.columns where name = N''FinishRecordPreview'' and Object_ID = Object_ID(N''ccTipoCalifOUT''))
    begin
        alter table ccTipoCalifOUT add FinishRecordPreview bit null
    end'
	EXEC(@sql);

	SET @process = 'drop sp ccsp_GalateaAdminDispositions'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminDispositions'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminDispositions;
    end'
	EXEC(@sql);

	SET @process = 'create ccsp_GalateaAdminDispositions'
	SET @sql = 'create PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
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
            @allNumbersToBlacklist bit = 0,
			@FinishRecordPreview bit = 0
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
              IsNull(C.finishPreview,0) as finishPreview, graphColor, allNumbersToBlacklist, ISNULL(C.FinishRecordPreview,0) as FinishRecordPreview
              from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
              where C.CalifOut_Status=1
              group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
              C.contactOwner, C.finishPreview, graphColor, allNumbersToBlacklist, C.FinishRecordPreview
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
                finishPreview=isnull(@finishPreview,0), graphColor=isnull(@graphColor, ''1DB4E2''), FinishRecordPreview = isnull(@FinishRecordPreview,0)
                output inserted.calif_id into @inserted
                where calif_id=@calif_id
                select ID [result] from @inserted 
                return(0)
             end

             insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, graphColor, allNumbersToBlacklist,FinishRecordPreview)
             output inserted.calif_id into @inserted
             select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, isnull(@canReprogram,0), isnull(@keepDial,0), 
             isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, ''1DB4E2''), ISNULL(@allNumbersToBlacklist,0), FinishRecordPreview = isnull(@FinishRecordPreview,0) from ccTipoCalifOut
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
                finishPreview = isnull(@finishPreview,finishPreview), allNumbersToBlacklist = isnull(@allNumbersToBlacklist, allNumbersToBlacklist),  FinishRecordPreview = isnull(@FinishRecordPreview,FinishRecordPreview)
                output inserted.calif_id into @inserted
                where calif_id=@calif_id

                if @keepDial is not null
                begin
                    update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
                end

                select ID [result] from @inserted
                return(0) 
                end

            set nocount off
select * from ccTipoCalifOUT
'
	EXEC(@sql);


	---------------------------------------END Frida ---------------------------------------------------------


	
		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
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
