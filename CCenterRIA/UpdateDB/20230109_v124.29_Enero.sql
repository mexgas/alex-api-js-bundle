/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.25

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
SET @versionfix = 29
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

		-------------------------------------------------------- IVAN feature/IM-K038001-Add_camp_type_to_ccCamps ----------------------------------------------------------
		
		set @process = 'K038001 Remove publication for ccCamps in order to rename column'
		set @sql = 'DECLARE @publication AS sysname;  
					DECLARE @article1 AS sysname;  

					SET @publication = N''SpecialAVRS'';  
					SET @article1 = N''cccamps'';  
					IF EXISTS(SELECT * FROM sys.tables WHERE name=''sysmergepublications'') BEGIN
					IF EXISTS(SELECT * FROM dbo.sysmergepublications WHERE name=@publication)
					BEGIN	
						-- Remove articles from a merge publication.  
						USE CCenterRIA  
						EXEC sp_dropmergearticle   
						  @publication = @publication,   
						  @article = @article1,  
						  @force_invalidate_snapshot = 1;  
					END END'
		EXEC(@sql)

		set @process = 'K038001 Rename column if exists'
		set @sql = 'IF EXISTS (SELECT 1 FROM sys.columns WHERE name = N''chat'' AND object_name(object_id) = N''ccCamps'') 
					AND NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = ''CampType'' AND  object_name(object_id) = N''ccCamps'')
					BEGIN 
						EXEC sp_RENAME ''dbo.ccCamps.chat'', ''CampType'', ''COLUMN'';
					END'
		EXEC(@sql)

		set @process = 'K038001 Drop procedure ccsp_RIALoadCamps'
		set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_RIALoadCamps'')
					BEGIN
						DROP PROCEDURE ccsp_RIALoadCamps;
					END'
		EXEC(@sql)

		set @process = 'K038001 Change column name in ccsp_RIALoadCamps lines (1190 and 1550)'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIALoadCamps] @option SMALLINT, @AreaId SMALLINT = NULL, @Sup SMALLINT = NULL, @WGID SMALLINT = NULL
					AS
					SET NOCOUNT ON

					DECLARE @loginDays INT

					SET @loginDays = 0

					IF @option = 1 -- Todas las campañas
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

					IF @option = 2 -- Campañas de un Area
					BEGIN
						SELECT DISTINCT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG
						FROM ccCamps a1
						JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
						JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
						WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
						ORDER BY cam_descripcion

						RETURN (0)
					END

					IF @option = 3 -- Campañas por Supervisor
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

					IF @option = 5 -- Campañas por Supervisor
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

					IF @option = 8 -- Campañas de un Agente
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
					IF @option = 9 -- Campañas de un Area
					BEGIN
						(SELECT DISTINCT a1.cam_id as CamID, cam_descripcion as CamDescription, frame as Frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) as RelationsWG,1 CamType, 
						ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 1 and IdCampEsp = a1.cam_id and IDWG = @WGID group by IdCampEsp),0) IsAssignedToCurrentWG,
						CAST(CASE WHEN a1.progDial = 3 THEN 6 WHEN a1.CampType = 5 THEN 5 ELSE 0 END as [tinyint]) [MediaType]
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

					SET NOCOUNT OFF'
		EXEC(@sql)

		set @process = 'K038001 Drop procedure ccsp_RIAConfCamp'
		set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_RIAConfCamp'')
					BEGIN
						DROP PROCEDURE ccsp_RIAConfCamp;
					END'
		EXEC(@sql)

		set @process = 'K038001 Change column name in ccsp_RIAConfCamp'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAConfCamp]
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
					isnull(exitAssisted, 0) exitAssisted, isnull(previewDiscard, 0) PreviewDiscard, isnull(CampType, 0) Chat, isnull(contact.conexionInfo,'''') conexionInfo, isnull(contact.closeConversationTime,0) closeConversationTime, isnull(contact.answerTimeoutClient,0) answerTimeoutClient, isnull(contact.allowFileAttachments,0) allowFileAttachments
					from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
					inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
					inner join @tableExistsRec a4 on a1.cam_id=a4.camId
					left join contactMeanOut contact on a1.cam_id = contact.camp_id
					order by cam_descripcion
					return(0)
					set nocount off'
		EXEC(@sql)

		set @process = 'K038001 Drop procedure ccsp_UpdateOutWhatsappConfig'
		set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_UpdateOutWhatsappConfig'')
					BEGIN
						DROP PROCEDURE ccsp_UpdateOutWhatsappConfig;
					END'

		EXEC(@sql)

		set @process = 'K038001 Change column name in ccsp_UpdateOutWhatsappConfig'
		set @sql = 'CREATE PROCEDURE  [dbo].[ccsp_UpdateOutWhatsappConfig] 
					@ConexionInfo varchar(400),
					@outbound_id int,
					@descripcion varchar(400), 
					@ConnUser varchar(60),
					@tNotas int,
					@closeConversationTime tinyint,
					@ShowCalifWnd bit,
					@ExitAssisted bit,
					@MUTimeOutClient int,
					@allowFileAttachments bit
					AS
					set nocount on
					IF NOT EXISTS (SELECT camp_id FROM ContactMeanOut WHERE camp_id = @outbound_id) 
							BEGIN
								INSERT INTO ContactMeanOut (meanContactTypeId, name, camp_id, isActive, numMessages,conexionInfo,connUser,closeConversationTime,ConnPass,answerTimeoutClient,allowFileAttachments) values 
								(5, @descripcion, @outbound_id, (select cam_activo  from ccCamps where cam_id = @outbound_id),3,@conexionInfo,@connUser,@closeConversationTime,''N/A'',@MUTimeOutClient,@allowFileAttachments);
								UPDATE ccWhatsAppNumbers SET camp_id = @outbound_id WHERE number = @conexionInfo
						END;

					IF EXISTS (SELECT cam_id FROM ccCamps WHERE cam_id = @outbound_id) 
					BEGIN
						UPDATE ccCamps SET cam_tnotas = @tNotas, cam_ShowCalifWnd = @ShowCalifWnd, exitAssisted = @ExitAssisted, CampType = 5 where cam_id = @outbound_id;
					END;
					SELECT @outbound_id;

					set nocount off'
		EXEC(@sql)

		set @process = 'K038001 Drop procedure ccsp_GalateaGetOutboundConfiguration'
		set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_GalateaGetOutboundConfiguration'')
					BEGIN
						DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration;
					END'

		EXEC(@sql)

		set @process = 'K038001 Change column name in ccsp_GalateaGetOutboundConfiguration'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]
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
						prefijo varchar(40),enbleprefix bit,exitAssisted bit,previewDiscard bit , CampType int, conexionInfo varchar(15), closeConversationTime smallint, answerTimeoutClient int, allowFileAttachments bit)
						
							INSERT INTO @AllCampaigns EXEC ccsp_RIAConfCamp @adminID, @campID

							SELECT dialPrefixMan DialPrefixMan, dialPrefixXfe DialPrefixXfe, listenManualCall  ListenManualCall, stopRecording StopRecording, abandonCallback AbandonCallBack,
							t_autoCB AutoCB,id_anilist IdIstANI,tDialonWrapUp TDialOnWrapup, queSize Quesize, DNCScrub, callerIdDesc CallerIdDesc, timeZoneRule TimeZoneRule,callsBySurvey CallsBySurvey,
							ivrScript IvrScript, surveyPctg SurveyPctg, call_record CallRecord,startStopRecording StartStopRecording, leaveRecMessage LeaveRecMessage,manualCallOnChat ManualCallOnChat,
							callBackSurveyClient CallBackSurveyClient, callBackSurveyAgent CallBackSurveyAgent, funcEspDtmf FuncEspDtmf,sipHdrFormat SipHdrsCfg, dialPrefix DialPrefix,
							prefijo Prefix, dialOrder DialOrder, progDial ProgDial, cam_Descripcion CamDescription, cam_tNotas CamTnotas, cam_ocupado CamBusy, cam_noInt_ocupado CamNoIntBusy,
							cam_inter_ocupado CamInterBusy,cam_nocontesto CamNoAnswer, cam_noInt_nocontesto CamNoIntNoAnswer,cam_inter_nocontesto CamInterNoAnswer, (cam_inter_cancelled/60) CamInterCancelled,
							cam_fax CamFax, cam_noInt_fax CamNoIntFax,cam_inter_fax CamInterFax, cam_modomanual CamModoManual,ANI ,cam_StartTimerOnHangUp CamStartTimerOnHangUp,
							editableCallKey EditableCallKey, cam_tNoContesta CamTNoAnswer, iTipoDial  CamIntensiveDialing, detectAnswerMachine DetectAnswerMachine, detectVoiceMail DetectVoiceMail, 
							compliance Compliance, cam_inter_graba CamInterRecord,cam_noint_graba CamNoIntRecord,excCallBack ExcCallBack, cam_ShowCalifWnd CamShowCalifWnd, frame Frame, exitAssisted ExitAssistedDialMode, previewDiscard PreviewDiscard, CampType Chat,
							conexionInfo ConexionInfo, closeConversationTime CloseConversationTime, answerTimeoutClient MUTimeOutClient, allowFileAttachments AllowFileAttachments
							from @AllCampaigns WHERE cam_id = @campID
					END'
		EXEC(@sql)

		set @process = 'K038001 Drop procedure ccsp_RIA_ABCCamps'
		set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_RIA_ABCCamps'')
					BEGIN
						DROP PROCEDURE ccsp_RIA_ABCCamps;
					END'

		EXEC(@sql)

		set @process = 'K038001 Add CampType 1 insertion when normal campaign is created lines 792 and 810'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
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
							Select @error=case valor when 0 then ''No es posible eliminar la campaña, esta asociada a una especialidad''
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

						if @@rowcount = 1
						select @new_cam_id = scope_identity()

						else
							begin
							select -2 --, ''Error al crear campaña''
							return(0)
							end

						if isnull(@MirrorInbound_Id, 0)<>0
							begin
							if not exists(select inbound_id from ccInbound with(nolock) where inbound_id=@MirrorInbound_Id)
								begin
								select -3 -- Error al asignar campaña a ACD, el ACD no existe o no pertenece a la misma area
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
							declare @tempId as int
							DECLARE @dnclId TABLE 
							(
								id int 
							);
							insert into @dnclId
							exec dbo.ccsp_RIACATBList null, null, 5
							select @tempId=id from @dnclId;
							exec ccsp_RIABlackListCamp 4, @IDArea, @new_cam_id, @tempId, null
						end

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

						if @option = 5 --Obtener relaciones de campañas - campañas
						begin
							if not exists (select cam_id from ccCamps with(nolock) where cam_id = @Cam_id) or
							(@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
							not exists (select cam_id from ccCamps with(nolock) where cam_id=@descripcion))
							begin
							select -3 -- Campaña invalida
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

					if @option = 7 -- Checa si la campaña no tiene grabaciones y se puede modificar el prefijo
						begin	
							select count(*) as Grabaciones from ccoCallsOut where cam_id = @Cam_id
							--select 0 as Grabaciones	
						end

					if @option = 8 -- Checa si la campaña tiene asignada una campaña tipo encuesta
						begin	
							SELECT CAST(CASE WHEN  isnull(surveycamid,0) != 0 THEN 1 ELSE 0 END AS bit)
							from cccamps with(index(PK_ccCamps),nolock)
							where cam_id = @Cam_id
							return(0)
						end

					return(0)
					set nocount off'

		EXEC(@sql)

		set @process = 'K038001 Drop procedure ccsp_RIAUpdateCamConfig'
		set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_RIAUpdateCamConfig'')
					BEGIN
						DROP PROCEDURE ccsp_RIAUpdateCamConfig;
					END'

		EXEC(@sql)

		set @process = 'K038001 Add CampType 3 when preview campaign is created line 1102'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
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
	                @timesDiscard tinyint = null
	                as
	                set nocount on
	                DECLARE @timesDiscardActual int = (SELECT timesDiscard FROM ccCamps WHERE cam_id = @cam_id)
	                DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)

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
	                 CampType = (CASE WHEN @progDial = 3 THEN @progDiaL ELSE 1 END)

	                Where cam_id = @cam_id

	                if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
	                begin
	                    EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
	                end

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

	    set @process = 'K038001 Drop procedure ccsp_GalateaAdminCampaigns'
		set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_GalateaAdminCampaigns'')
					BEGIN
						DROP PROCEDURE ccsp_GalateaAdminCampaigns;
					END'
		EXEC(@sql)
					
		set @process = 'K038001 Change ccCamps column chat to CampType'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS      SMALLINT, 
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
					                                                            CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType
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
					                                                    CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType, 0 as OutboundType
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
					  INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
					  INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
					  left JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp and @CampType = 0
					  left JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp and @CampType = 1
					  where C.TipoUser_id = 1
					  AND campPerWg.Tipo = @CampType
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
					                                            CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType
					                    FROM ccCamps camps (NOLOCK)
					                         INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
					                         INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
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
					                    
		set @process = 'K038001 Add publication back'
		set @sql = 'IF EXISTS(SELECT is_published FROM sys.databases WHERE is_published = 1 OR is_subscribed = 1 OR
													   is_merge_published = 1 OR is_distributor = 1 
													   AND databases.name = ''CCenterRIA'') 
					BEGIN
						use [CCenterRia]
						DECLARE @publicationName AS sysname;  
						DECLARE @articleName AS sysname;  


						SET @publicationName = N''SpecialAVRS'';  
						SET @articleName = N''cccamps'';  

						exec sp_addmergearticle @publication = @publicationName, 
						@article = @articleName, 
						@source_owner = N''dbo'', 
						@source_object = @articleName, 
						@type = N''table'', 
						@description = N'''', 
						@creation_script = null, 
						@pre_creation_cmd = N''drop'', 
						@schema_option = 0x000000000C034FD1, 
						@identityrangemanagementoption = N''manual'', 
						@destination_owner = N''dbo'', 
						@force_reinit_subscription = 1, 
						@column_tracking = N''false'', 
						@subset_filterclause = null, 
						@vertical_partition = N''false'', 
						@verify_resolver_signature = 1, 
						@allow_interactive_resolver = N''false'', 
						@fast_multicol_updateproc = N''true'', 
						@check_permissions = 0, 
						@subscriber_upload_options = 1, 
						@delete_tracking = N''true'', 
						@compensate_for_errors = N''false'', 
						@stream_blob_columns = N''false'', 
						@partition_options = 0
					END'
		EXEC(@sql)

-------------------------------------------------------- END IVAN feature/IM-K038001-Add_camp_type_to_ccCamps ----------------------------------------------------------

-------------------------------------------------------BEGIN MARCO GARCIA KR011005-Inspeccionar mensaje campaña de entrada ------------------------------------------------
	SET @process = 'KR011005-Inspeccionar mensaje campaña de entrada delete procedure ccsp_GalateaAgentAutomaticMessages'
	SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaAgentAutomaticMessages'')
		BEGIN
			DROP PROCEDURE ccsp_GalateaAgentAutomaticMessages;
		END';
	EXEC(@sql);


	SET @process = 'KR011005-Inspeccionar mensaje campaña de entrada create procedure ccsp_GalateaAgentAutomaticMessages'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaAgentAutomaticMessages] 
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
                select ISNULL(msgName, msgFile) [MsgName], [Description] [MsgDescription], [MsgFile] [MsgFile], [MsgId] [MsgId] from ccAgentMsgFiles         
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

                insert into [ccAgentMsgRelationFiles] (MsgId,CamId,CamType)   values(@MsgId,@camId,@CampType)

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

        END
        ELSE IF @action = 11 -- Relation Campaign and Audio Msg
		BEGIN
			 (select IC.Inbound_id as Camp_Id, Camp_Type = 0,ISNULL(descripcion,'''''''') as [Name], Graphics.frame as Frame, Type = CONVERT(TINYINT ,16), ISNULL(IC.IDArea,0) as IdArea, ISNULL(AREas.AreaName,'''') as AreaName
            from ccInbound as IC with(nolock) 
            left join ccRIACat_Areas as AREas with(nolock) on IC.IDArea = AREas.IDArea
            inner join ccRIAInboundGraph as CampsGraph on IC.Inbound_id = CampsGraph.Inbound_id
            inner join ccRIAGraphics as Graphics on Graphics.graphic_id = CampsGraph.graphic_id
            inner join ccAgentMsgRelationFiles IM on IM.CamId = IC.Inbound_id
            Where IM.MsgId = @MsgId)
		END 
	END'

	EXEC(@sql);


	SET @process = 'KR011005-Inspeccionar mensaje campaña de entrada delete procedure ccsp_GalateaAutomaticMessages'
	SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaAutomaticMessages'')
		BEGIN
			DROP PROCEDURE ccsp_GalateaAutomaticMessages;
		END';
	EXEC(@sql);

	SET @process = 'KR011005-Inspeccionar mensaje campaña create procedure ccsp_GalateaAutomaticMessages'
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
            select ISNULL(msgName, msgFile) [MsgName], Descripcion [MsgDescription], msgFile [MsgFile], msg_id [MsgId], DefaultMessage, ISNULL(idArea, -1) [IdArea] from ccMsgFiles
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

		EXEC(@sql)

-------------------------------------------------------END MARCO GARCIA KR011005-Inspeccionar mensaje campaña de entrada ------------------------------------------------

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
