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
SET @versionfix = 8
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
		-------------------------------------------- BEGIN URIEL CABRERA and IVAN MARTIN Add Zipcode To Campaign Configuration ------------------------------
		SET @process = 'Create new table ccCampsExtend, which is an extention to ccCamps. This was done due to the number of settings in ccCamps'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccCampsExtend'') begin
						CREATE TABLE [dbo].[ccCampsExtend] (
							cam_id SMALLINT NOT NULL,
							zipCodeSchedule BIT NULL,
						)
					end'
		EXEC(@sql)

		SET @process = 'Alter Procedure ccsp_RIA_ABCCamps to add new record on ccCampsExtend. Lines (79 and 84)'
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

						-- ODC: la campa?a siempre esta activa
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
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
						@cam_id smallint,
						@zipCodeSchedule BIT = NULL
					AS
					BEGIN
						SET NOCOUNT ON;
						UPDATE ccCampsExtend SET
						zipCodeSchedule = isnull(@zipCodeSchedule,zipCodeSchedule)
						Where cam_id = @cam_id
						return(0)
						set nocount off
					END'
		EXEC(@sql)
		
		SET @process = 'Adding parameter ZipCodeSchedule to ccsp_RIAConfCamp as well as inner join with new table ccCampsExtend. Lines (228 and 234)'
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
						,isnull(campsExtention.zipCodeSchedule, 0) ZipCodeSchedule
					FROM ccCamps a1
					INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
					INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
					INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
					LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
					INNER JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
					ORDER BY cam_descripcion

					RETURN (0)

					SET NOCOUNT OFF'
		EXEC(@sql)

		SET @process = 'Adding parameter ZipCodeSchedule to ccsp_GalateaGetOutboundConfiguration. Lines(318 and 400)'
		SET @sql = 'Alter PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT, @campID INT
					AS
					BEGIN
						DECLARE @AllCampaigns TABLE (		cam_id SMALLINT
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
							,selectRotativeANI int
							,rotativeAlgo TINYINT
							,autoStart BIT
							,messagingOrder BIT
							,CamTPreview SMALLINT
							,TimesPreview TINYINT
							,timesDiscard TINYINT
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
							,zipCodeSchedule ZipCodeSchedule
						FROM @AllCampaigns
						WHERE cam_id = @campID
					END'
		EXEC(@sql)
		-------------------------------------------- END IVAN OUTBOUND HISTORICAL CHAT ------------------------------
		
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
