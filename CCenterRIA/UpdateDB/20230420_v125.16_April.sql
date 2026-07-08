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
SET @versionfix = 16
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

IF @version >= @actualVersion  and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN

	BEGIN TRY
		-------------------------------------------- BEGIN URIEL CABRERA and IVAN MARTIN Add Zipcode To Campaign Configuration ------------------------------
		SET @process = 'Create new table ccCampsExtend, which is an extention to ccCamps. This was done due to the number of settings in ccCamps'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccCampsExtend'') begin
	CREATE TABLE [dbo].[ccCampsExtend] (
		cam_id SMALLINT NOT NULL PRIMARY key,
		zipCodeSchedule BIT NULL,
	)
end'
		EXEC(@sql)

		SET @process = 'Alter Procedure ccsp_RIA_ABCCamps to add new record on ccCampsExtend. Lines (151 and 84)'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
@option smallint,
@UserId int = null,
@Descripcion varchar(40) = null,
@Cam_id varchar(1000),
@Activa tinyint = null,
@IDArea smallint = null,
@frame tinyint = null, 
@MirrorInbound_Id smallint = null,
@Prefijo varchar(40) = null
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
		return(0)
	end

if @option = 2 --Insert
	begin
	declare @new_cam_id smallint
	declare @isAssingPortbyCam bit

	DECLARE @CampTypeNormal INT = 1

	if exists(select cam_descripcion from ccCamps with(nolock) where cam_descripcion = @Descripcion)
		begin
		select -1 --, ''Nombre en Uso''
		return(0)  
		end

	-- ODC: la campaña siempre esta activa
	set @Activa = 1
	declare @pref int
	select  @pref = valor from ccSettings where setting_id = 201
	if (@pref = 0)
		set @Prefijo = ''''


	Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd,prefijo, CampType)
	select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
	case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end, @Prefijo, @CampTypeNormal

	if @@rowcount = 1 begin
		select @new_cam_id = scope_identity()
		if not exists (select * from ccCampsExtend where cam_id = @new_cam_id) begin
			Insert into ccCampsExtend (cam_id) values (@new_cam_id);
		end
	end
	else
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

		update ccRIACampsGraph with(rowlock)
		set graphic_id = (select graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
		where cam_id = @Cam_id

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
set nocount off'
EXEC(@sql)

SET @process = 'Create new procedure ccsp_RIAUpdateCamConfigExtend, which will update the new column zipCodeSchedule in ccCampsExtend table.'
SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateCamConfigExtend'') begin
	Drop PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
end'
		EXEC(@sql)

SET @process = 'Create new procedure ccsp_RIAUpdateCamConfigExtend, which will update the new column zipCodeSchedule in ccCampsExtend table.'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
	@cam_id smallint,
	@zipCodeSchedule BIT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	if exists(select * from ccCampsExtend where cam_id=@cam_id) begin
		UPDATE ccCampsExtend SET
		zipCodeSchedule = isnull(@zipCodeSchedule,zipCodeSchedule)
		Where cam_id = @cam_id	
	end
	else begin
		INSERT INTO ccCampsExtend(cam_id,zipCodeSchedule) values (@cam_id,@zipCodeSchedule)
	end
	set nocount off
END'
		EXEC(@sql)
		
		SET @process = 'Adding parameter ZipCodeSchedule to ccsp_RIAConfCamp as well as left join with new table ccCampsExtend. Lines (228 and 234)'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp] @User_id SMALLINT, @campID INT = NULL
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
	,isnull(sipHdrFormat, '''''''') sipHdrFormat
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
	,isnull(contact.conexionInfo, '''''''') conexionInfo
	,isnull(contact.connUser, '''''''') connUser
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
FROM ccCamps a1
INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
ORDER BY cam_descripcion

RETURN (0)

SET NOCOUNT OFF'
		EXEC(@sql)

		SET @process = 'Adding parameter recordHold, ZipCodeSchedule to ccsp_GalateaGetOutboundConfiguration. Lines(553,554)'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT
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
					FROM @AllCampaigns
					WHERE cam_id = @campID
					END'
		EXEC(@sql)

		SET @process = 'KR083000 ALTER PROCEDURE Modification on Option 2 to include ZipCodeSchedule in ccsp_GalateaAdminCampaigns (lines 691 and 695)'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] 
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
							RAISERROR(''ERROR. No existe una lista de campa?as de salida con el id de grupo de trabajo especificado'', 18, 1);
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
							RAISERROR(''ERROR. No existe una lista de campa?as de entrada con el id de grupo de trabajo especificado'', 18, 1);
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
							CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
							isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
							camps.cam_procesando IsStarted, a.AreaName AS Area,  
							CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType,
							ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
							FROM ccCamps camps
							LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
							LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
							LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
							WHERE camps.cam_id = @Id
							ORDER BY camps.cam_descripcion ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe campa?as de salida con el id especificado'', 18, 1);
					END;
			END;
			IF @CampType = 0 -- Campaigns In (ACD)
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							SELECT DISTINCT 
													CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType, 0 as OutboundType
							FROM ccInbound inb
									LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
									LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
							WHERE inb.Inbound_id = @Id
									ORDER BY inb.descripcion ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe campa?as de entrada con el id especificado'', 18, 1);
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
					RAISERROR(''ERROR. No existe la campa?as de entrada con el id especificado'', 18, 1);
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
					RAISERROR(''ERROR. La campa?as o administrador no existen'', 18, 1);
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
					RAISERROR(''ERROR. La campa?as con el id seleccionado no existe'', 18, 1);
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
	DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT );
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
	INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
	INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
	left JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp and @CampType = 0
	left JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp and @CampType = 1
	where C.TipoUser_id = 1
	AND campPerWg.Tipo = @CampType
	AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
			  
	;WITH lastState AS (
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

	DECLARE @MultimediaType SMALLINT
	IF @CampType = 1 BEGIN
	SELECT @MultimediaType = meanContactTypeId FROM contactMeanOut WHERE camp_id = @Id
	END
	ELSE BEGIN
	SELECT @MultimediaType = meanContactTypeId FROM contactMeanIn WHERE inboundId = @Id
	END 

	DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes

	INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
	(CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = @CampType
	THEN @CampType ELSE null END) AS isCampDialog, B.camType
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
			WHEN A.CurrentState IN (6, 34, 4) AND (A.CampId != C.IdCampEsp OR A.campType != @CampType) THEN 1 ELSE NULL END) AS notReady,
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
					CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
					isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
					camps.cam_procesando IsStarted, a.AreaName AS Area,  
					CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType,
					ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
					FROM ccCamps camps (NOLOCK)
					INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
					INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
					INNER JOIN ccCampsExtend extended (NOLOCK) ON camps.cam_id = extended.cam_id
					--WHERE camps.cam_id = @Id
					ORDER BY camps.cam_descripcion ASC;
			END;
			ELSE
				BEGIN
					SELECT DISTINCT 
											CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType, 0 as OutboundType
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
		-------------------------------------------- END IVAN ZIPCODE CONFIGURATION ------------------------------
		SET @process = 'Se agregan columnas ccRIALogPhones keyTranslate,regsNotLoadedCp,telsNotLoadedCp'
		SET @sql = 'if not exists (select * from sys.columns where name = N''keyTranslate'' and Object_ID = Object_ID(N''ccRIALogPhones''))
begin
    alter table ccRIALogPhones add keyTranslate varchar(max)
end

if not exists (select * from sys.columns where name = N''regsNotLoadedCp'' and Object_ID = Object_ID(N''ccRIALoading''))
begin
    alter table ccRIALoading add regsNotLoadedCp int
end
if not exists (select * from sys.columns where name = N''telsNotLoadedCp'' and Object_ID = Object_ID(N''ccRIALoading''))
begin
    alter table ccRIALoading add telsNotLoadedCp int
end'
		EXEC(@sql)

		SET @process = 'Create table ccTimeZoneAreaCP'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccTimeZoneAreaCP'')begin
	create table ccTimeZoneAreaCP(
		ZipCode varchar(30) not null,
		State  varchar(5)  not null,
		Municipality varchar(5)  null,
		Location varchar(5)  null,
		StartDate DateTime not null,
		Description varchar(500)  not null,
		StartMonthSummerTime varchar(50)  NULL,
		StartDaySummerTime varchar(50)  NULL,
		SummerTimeDifference int not null,
		StartMonthWinterHours varchar(50)  NULL,
		StartDayWinterHours varchar(50)  null,
		WinterTimeDifference int not null,
	)
end'
		EXEC(@sql)

		SET @process = 'Create table tableLangueDbLoader'
		SET @sql = 'if not exists(select * from sys.tables where name=''tableLangueDbLoader'')begin
create table tableLangueDbLoader (
	languageId int not null,
	tag varchar(255) not null,
	translate varchar(255) not null			
	)
end
truncate table tableLangueDbLoader

insert into tableLangueDbLoader values(0,''column-file-field'',''Columna de archivo '')
insert into tableLangueDbLoader values(1,''column-file-field'',''File column '')
insert into tableLangueDbLoader values(2,''column-file-field'',''Coluna do arquivo '')

insert into tableLangueDbLoader values(0,''type-not-loaded-num'',''Teléfono no cargado'')
insert into tableLangueDbLoader values(1,''type-not-loaded-num'',''Not loaded number'')
insert into tableLangueDbLoader values(2,''type-not-loaded-num'',''Telefone não carregado'')

insert into tableLangueDbLoader values(0,''type-blocked-num'',''Teléfono bloqueado'')
insert into tableLangueDbLoader values(1,''type-blocked-num'',''Blocked number'')
insert into tableLangueDbLoader values(2,''type-blocked-num'',''Telefone bloqueado'')

insert into tableLangueDbLoader values(0,''type-updated-num'',''Teléfono actualizado'')
insert into tableLangueDbLoader values(1,''type-updated-num'',''Updated number'')
insert into tableLangueDbLoader values(2,''type-updated-num'',''Telefone atualizado'')

insert into tableLangueDbLoader values(0,''description-dnc-list'',''Teléfono en lista negra'')
insert into tableLangueDbLoader values(1,''description-dnc-list'',''Number in DNC list'')
insert into tableLangueDbLoader values(2,''description-dnc-list'',''Telefone em lista negra'')

insert into tableLangueDbLoader values(0,''type-blocked-records'',''Registro bloqueado'')
insert into tableLangueDbLoader values(1,''type-blocked-records'',''Blocked record'')
insert into tableLangueDbLoader values(2,''type-blocked-records'',''Registro bloqueado'')

insert into tableLangueDbLoader values(0,''type-incorrect-records'',''Registro no cargado'')
insert into tableLangueDbLoader values(1,''type-incorrect-records'',''Not loaded record'')
insert into tableLangueDbLoader values(2,''type-incorrect-records'',''Registro não carregado'')

insert into tableLangueDbLoader values(0,''description-blocked-records'',''Todos los teléfonos bloqueados'')
insert into tableLangueDbLoader values(1,''description-blocked-records'',''All numbers are blocked'')
insert into tableLangueDbLoader values(2,''description-blocked-records'',''Todos os telefones bloqueados'')

insert into tableLangueDbLoader values(0,''description-incorrect-records'',''Todos los teléfonos inválidos'')
insert into tableLangueDbLoader values(1,''description-incorrect-records'',''All numbers are invalid'')
insert into tableLangueDbLoader values(2,''description-incorrect-records'',''Todos os telefones inválidos'')

insert into tableLangueDbLoader values(0,''description-length'',''Longitud excedida'')
insert into tableLangueDbLoader values(1,''description-length'',''Length exceeded'')
insert into tableLangueDbLoader values(2,''description-length'',''Comprimento excedido'')

insert into tableLangueDbLoader values(0,''field-phone-auto'',''Teléfono '')
insert into tableLangueDbLoader values(1,''field-phone-auto'',''Phone number '')
insert into tableLangueDbLoader values(2,''field-phone-auto'',''Telefone '')

insert into tableLangueDbLoader values(0,''description-zip1'',''Código postal vacío o incompleto'')
insert into tableLangueDbLoader values(1,''description-zip1'',''Incomplete or missing ZIP code'')
insert into tableLangueDbLoader values(2,''description-zip1'',''CEP vazio ou incompleto'')

insert into tableLangueDbLoader values(0,''description-zip2'',''Código postal inválido'')
insert into tableLangueDbLoader values(1,''description-zip2'',''Invalid ZIP code'')
insert into tableLangueDbLoader values(2,''description-zip2'',''CEP inválido'')

insert into tableLangueDbLoader values(0,''CalKeyInvalido'',''Longitud de registro incorrecta'')
insert into tableLangueDbLoader values(1,''CalKeyInvalido'',''Invalid record length'')
insert into tableLangueDbLoader values(2,''CalKeyInvalido'',''Comprimento de registro incorreto'')

insert into tableLangueDbLoader values(0,''description-cofetel'',''Error en COFETEL'')
insert into tableLangueDbLoader values(1,''description-cofetel'',''Error in COFETEL'')
insert into tableLangueDbLoader values(2,''description-cofetel'',''Erro no COFETEL'')

if not exists(select * from ccRIACATLogPhones where tipoMov=-1) begin
	insert into ccRIACATLogPhones(tipoMov,descTipoMov) values(-1,''Function'')
end
	'
		EXEC(@sql)

		SET @process = 'Alter SP ccsp_GalateaGetRecordsImportStatus if @action=2, @action=1 se agrega columnas regsNotLoadedCp, y isnull(telsNotLoadedCp,0) as telsNotLoadedCp'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetRecordsImportStatus]
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
        SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked+isnull(regsNotLoadedCp,0)  as regsNotLoaded, state, loadDate	
        FROM ccRIALoading riaLoad
        JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
        WHERE 
        loadDate>=@today and loadType = 0
        ORDER BY riaLoad.loadDate DESC
    END
else
    BEGIN
        SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked+isnull(regsNotLoadedCp,0) as regsNotLoaded, state, loadDate
		
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
         telsLoaded, telsBlocked, telsNotLoaded, isnull(regsNotLoadedCp,0) as regsNotLoadedCp
		 , isnull(telsNotLoadedCp,0) as telsNotLoadedCp
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



		SET @process = 'Alter SP ccsp_RIALogPhones Se cambia para las etiquetas para saber Cp '
		SET @sql = 'Alter procedure [dbo].[ccsp_RIALogPhones]
@load_id int,
@Type smallint,
@GenCSV bit = 1, -- 0:100 / 1:todos
@isKolob bit = 0,
@PageIndex      INT = 0,
@PageSize       INT = 0,
@option SMALLINT = NULL
as
set nocount ON

declare @CaseType varchar(2000), @sql nvarchar(MAX), @nType char(5), @MovType SMALLINT, @language int
SELECT @language = cs.valor FROM dbo.ccSettings AS cs WHERE cs.setting_id = 27;
declare @PageStart int,@PageEnd int

select @CaseType = '''', @nType = right(''0000''+cast(@Type as varchar(5)), 5)

if @nType like ''%____1%''
	select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 0 
	''

if @nType like ''%___1_%''
	select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov in(-1,0) 
	''

if @nType like ''%__1__%''
	select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 1 
	''

if @nType like ''%_1___%''
	select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov = 1 
	''

if @nType like ''%1____%''
	select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 2 ''

if @CaseType = '''' and @nType <> 0
	return(0)


		
IF(@option = 1)
BEGIN	
	SET @sql = ''SELECT count(*) AS listSize FROM (
select crlp.load_id
from ccRIALogPhones AS crlp 
where crlp.load_id = @load_id'' 
+ @CaseType +'') tmp '' +
case @GenCSV when 0 then ''WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd'' else '''' end
			--EXEC(@sql);
			select @PageStart=@PageSize*(@PageIndex-1),@PageEnd=@PageSize*@PageIndex
		Exec sp_executesql @sql
                 , N''@PageStart int,@PageEnd int,@language int,@load_id int''
                 , @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id
			RETURN (0);
		END
		ELSE 
		BEGIN
				IF(@isKolob = 1)
				BEGIN

				declare @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200), @typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200)
, @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max);


select @typeDescriptionPhoneBlocked=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-num''
select @typeDescriptionPhoneUpdated=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-num''
select @typeIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-incorrect-records''
select @typeBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-records''
select @typeDescriptionPhoneNotLoaded=translate from tableLangueDbLoader where languageId=@language and tag=''type-not-loaded-num''

select @typeDescriptionPhoneBlackList=translate from tableLangueDbLoader where languageId=@language and tag=''description-dnc-list''
select @descriptionIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-incorrect-records''
select @descriptionBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-blocked-records''

select @column=translate from tableLangueDbLoader where languageId=@language and tag=''column-file-field''

select @headerPhone=header_phone,@headerPhone2=header_phone2,@headerPhone3=header_phone3,@headerPhone4=header_phone4 
,@headerPhone5=header_phone5
from fileHeadersPhoneLoad where load_id=@load_id
			
					set @CaseType=case when @CaseType <> '''' then '' and ('' + substring(@CaseType, 5, len(@CaseType)) + '')'' else '''' END
					SET @sql = '';with result as(
SELECT * FROM (select  
ROW_NUMBER() OVER(ORDER BY crlp.cal_key ASC) AS RowNum,
crlp.load_id,
crlp.cal_key, 
crlp.telefono AS phone,
CASE
	WHEN crlp.tipoMov in (1,4)  THEN @typeDescriptionPhoneBlocked  
	WHEN crlp.tipoMov = 2 THEN @typeDescriptionPhoneUpdated	
	WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @typeIncorrectRecords
	WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @typeBlockedRecords
	WHEN crlp.tipoMov in(-1,0) THEN @typeDescriptionPhoneNotLoaded
	WHEN crlp.keyTranslate is not null THEN isnull(tlan.translate,crlp2.descTipoMov)
ELSE 
	crlp2.descTipoMov  
END AS Tipo,
case when CHARINDEX('''':'''',crlp.motivo)=0 then 0 else
	convert(int,substring(crlp.motivo ,CHARINDEX('''':'''',crlp.motivo)-1 ,1))
end
 AS ColumnFile, 
CASE  WHEN crlp.tipoMov = 2 THEN ''''N/A'''' 
		WHEN crlp.tipoMov in (1,4) THEN @typeDescriptionPhoneBlackList							  
		WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @descriptionIncorrectRecords
		WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @descriptionBlockedRecords
		WHEN crlp.keyTranslate is not null THEN tlan.translate 
ELSE crlp.motivo END AS motivo
from ccRIALogPhones AS crlp 
INNER JOIN dbo.ccRIACATLogPhones AS  crlp2 ON crlp.tipoMov = crlp2.tipoMov
left join tableLangueDbLoader tlan on tlan.tag=crlp.keyTranslate and tlan.languageId=@language
where crlp.load_id = @load_id '' 				
+ @CaseType +'') tmp '' +
case @GenCSV when 0 then '' WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd '' else '''' end +'' 
) 
select  crlp.RowNum,
crlp.load_id,
crlp.cal_key, 
crlp.phone,
crlp.Tipo,
case when crlp.ColumnFile=1 then @column+ '''' ''''+@headerPhone
when crlp.ColumnFile=2 then @column+ '''' ''''+@headerPhone2
when crlp.ColumnFile=3 then @column+ '''' ''''+@headerPhone3
when crlp.ColumnFile=4 then @column+ '''' ''''+@headerPhone4
when crlp.ColumnFile=5 then @column+ '''' ''''+@headerPhone5
else '''''''' end ColumnFile,
crlp.motivo
from result crlp ''
	END
	ELSE
	BEGIN
		set @sql = ''select '' + case @GenCSV when 0 then ''top 100 '' else '''' end 
		+ ''load_id, cal_key, telefono, tipoMov, motivo from ccRIALogPhones AS crlp where load_id = @load_id '' 
		+ @CaseType
	END  
	PRINT(@sql);

	select @PageStart=@PageSize*(@PageIndex-1),@PageEnd=@PageSize*@PageIndex
	Exec sp_executesql @sql
    , N''@PageStart int,@PageEnd int,@language int,@load_id int, @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200),
	@typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200)
, @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max)''
    , @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id,@column=@column,@typeDescriptionPhoneNotLoaded=@typeDescriptionPhoneNotLoaded
	,@typeDescriptionPhoneBlocked=@typeDescriptionPhoneBlocked,@typeDescriptionPhoneUpdated=@typeDescriptionPhoneUpdated,@typeDescriptionPhoneBlackList=@typeDescriptionPhoneBlackList
	,@typeBlockedRecords=@typeBlockedRecords,@typeIncorrectRecords=@typeIncorrectRecords,@descriptionBlockedRecords=@descriptionBlockedRecords,@descriptionIncorrectRecords=@descriptionIncorrectRecords
	,@headerPhone=@headerPhone,@headerPhone2=@headerPhone2,@headerPhone3=@headerPhone3,@headerPhone4=@headerPhone4,@headerPhone5=@headerPhone5
	
return(0)
END
set nocount OFF'
		EXEC(@sql)		
		
		SET @process = 'DROP TRIGGER dbo.trigZonaHoraria;'
		SET @sql = 'IF OBJECT_ID(N''dbo.trigZonaHoraria'', N''TR'') IS NOT NULL
BEGIN
    DROP TRIGGER dbo.trigZonaHoraria;
END'
		EXEC(@sql)

		SET @process = 'Alter SP trigZonaHoraria Se modifica para validar si el zipCodeSchedule es 1 para no validar por telefono'
		SET @sql = 'CREATE TRIGGER [dbo].[trigZonaHoraria] ON [dbo].[ccoCallsOutSource]
FOR INSERT,UPDATE
AS
SET NOCOUNT ON
begin
declare @country as tinyint,@zipCodeSchedule bit 
declare @tableCpZoneSchedule table(callout_id int primary key,iZonaHoraria int,iZonaHoraria_verano int)

select @country =convert(tinyint, valor) from ccSettings with(nolock) where setting_id = 104
if @country =1 begin
	select @zipCodeSchedule=zipCodeSchedule from ccCampsExtend where cam_id in(select top 1 cam_id from inserted)
end
if @zipCodeSchedule is null begin
	set @zipCodeSchedule=0
end

if @zipCodeSchedule = 1 begin
	
	insert into @tableCpZoneSchedule
	select cs.callout_id, inv.tz_id,v.tz_id
	from ccTimeZoneAreaCP zoneCp with(nolock) 
	inner join inserted cs on zoneCp.ZipCode=cs.Dato1	
	inner join ccTimeZones V on V.tz_offset=zoneCp.SummerTimeDifference
	inner join ccTimeZones inv on inv.tz_offset=zoneCp.WinterTimeDifference
	

end


if update(cal_telefono) begin
	update ccoCallsOutSource 
	set iZonaHoraria =case when @zipCodeSchedule=1 then cp.iZonaHoraria else dbo.fnGetTimeZone(cs.cal_telefono,0) end,
	iZonaHoraria_verano =case when @zipCodeSchedule=1 then cp.iZonaHoraria_verano else dbo.fnGetTimeZone(cs.cal_telefono,1) end
	from ccoCallsOutSource cs 
	inner join inserted i
	left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id
	on cs.callout_id = i.callout_id
end

if update(cal_telefono2) begin
	update ccoCallsOutSource 
	set iZonaHoraria2 = case when @zipCodeSchedule=1 then cp.iZonaHoraria else dbo.fnGetTimeZone(cs.cal_telefono2,0) end,
	iZonaHoraria_verano2 = case when @zipCodeSchedule=1 then cp.iZonaHoraria_verano else  dbo.fnGetTimeZone(cs.cal_telefono2,1) end
	from ccoCallsOutSource cs 
	inner join inserted i on cs.callout_id = i.callout_id
	left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id
	
end

if update(cal_telefono3) begin
	update ccoCallsOutSource 
	set iZonaHoraria3 =  case when @zipCodeSchedule=1 then cp.iZonaHoraria else dbo.fnGetTimeZone(cs.cal_telefono3,0) end,
	iZonaHoraria_verano3 = case when @zipCodeSchedule=1 then cp.iZonaHoraria_verano else  dbo.fnGetTimeZone(cs.cal_telefono3,1) end
	from ccoCallsOutSource cs 
	inner join inserted i on cs.callout_id = i.callout_id
	left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id
end

if update(cal_telefono4) begin
	update ccoCallsOutSource 
	set iZonaHoraria4 = case when @zipCodeSchedule=1 then cp.iZonaHoraria else dbo.fnGetTimeZone(cs.cal_telefono4,0) end,
	iZonaHoraria_verano4 = case when @zipCodeSchedule=1 then cp.iZonaHoraria_verano else   dbo.fnGetTimeZone(cs.cal_telefono4,1) end
	from ccoCallsOutSource cs 
	inner join inserted i on cs.callout_id = i.callout_id
	left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id
end

if update(cal_telefono5) begin
	update ccoCallsOutSource 
	set iZonaHoraria5 = case when @zipCodeSchedule=1 then cp.iZonaHoraria else dbo.fnGetTimeZone(cs.cal_telefono5,0) end,
	iZonaHoraria_verano5 = case when @zipCodeSchedule=1 then cp.iZonaHoraria_verano else   dbo.fnGetTimeZone(cs.cal_telefono5,1) end
	from ccoCallsOutSource cs 
	inner join inserted i on cs.callout_id = i.callout_id
	left join @tableCpZoneSchedule cp on cp.callout_id= i.callout_id
end
end'
		EXEC(@sql)

		SET @process = 'Alter function Limpia se quita la recursividad'
		SET @sql = 'ALTER FUNCTION [dbo].[Limpia](@Cadena varchar(32))
RETURNS varchar(32) AS  
BEGIN
declare @tel varchar(32),@digit varchar(1)
declare @i int,@count int

select @i=1,@count=len(@Cadena),@tel=''''
while @i<=@count begin
	set @digit=SUBSTRING(@cadena,@i,1)
	set @tel=@tel+case when CHARINDEX(@digit, ''1234567890'')=0 then '''' else @digit end	
	set @i=@i+1
end
return @tel
end'
		EXEC(@sql)

		SET @process = 'DISABLE TRIGGER dbo.trigZonaHoraria'
		SET @sql = 'DISABLE TRIGGER dbo.trigZonaHoraria ON dbo.ccoCallsOutSource;'
		EXEC(@sql)

		
		----------------------------------------------------------------------------------------------------------------------------
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


