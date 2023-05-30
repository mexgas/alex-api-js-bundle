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
SET @versionfix = 22
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
	,SimultaneousRecs, SimultaneousRecs
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

	set @process = 'KR082000 Drop SP ccspGalatea_Finder'
	set @sql = 'IF NOT EXISTS (SELECT * FROM ccSettings WHERE setting_id = 248) INSERT INTO [dbo].[ccSettings]
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
           ,''.*'')'
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

	
	SET @process = 'K049003 Add identifier calls by agent'
	SET @sql = 'if not exists (select * from ccGalateaIdentifiers where Description like ''%T$NUMBER_CALLS%'')
	begin
	  insert into ccGalateaIdentifiers(Description,TagEs,TagEn,TagPt) values (''T$NUMBER_CALLS'',''Número de llamadas'',''Number of calls'',''Número de chamadas'')
	end';
	EXEC(@sql);


	SET @process = 'Drop SP ccsp_RIAUpdateCamConfigExtend'
	SET @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_RIAUpdateCamConfigExtend'')
			BEGIN
				DROP PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
			END'
	EXEC(@sql);


	SET @process = 'K049003 Add identifier calls by agent'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaConfAggrFct]
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
