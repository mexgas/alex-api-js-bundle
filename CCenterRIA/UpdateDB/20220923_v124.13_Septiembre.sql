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
SET @versionfix = 13
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
	 ------------------------------------------------------------ DEV2-17_K004022, DEV2-3-K004023 ---------------------------------------------------------------------
		set @process = 'DEV2-17_K004022-Admin-Config_Tiempo_Preview add column cam_tPreview'
        set @sql = '
		if not exists (select * from sys.columns where name = N''cam_tPreview'' and Object_ID = Object_ID(N''ccCamps''))
		begin
			alter table ccCamps add cam_tPreview smallint not null default 180
		end'
		EXEC(@sql)

		set @process = 'DEV2-17_K004022-Admin-Config_Tiempo_Preview add column descTranslate'
        set @sql = '
		if not exists (select * from sys.columns where name = N''descTranslate'' and Object_ID = Object_ID(N''ccTipoResultadoDial''))
		begin
			alter table ccTipoResultadoDial add descTranslate varchar(50)
		end'
		EXEC(@sql)

		set @process = 'DEV2-17_K004022-Admin-Config_Tiempo_Preview add values to  descTranslate'
        set @sql = '
		if exists (select * from sys.columns where name = N''descTranslate'' and Object_ID = Object_ID(N''ccTipoResultadoDial''))
		begin
				update  ccTipoResultadoDial set descTranslate=''systemTranslated_Answer'' where tipoResDial_id=1
				update  ccTipoResultadoDial set descTranslate=''systemTranslated_Busy'' where tipoResDial_id=2
				update  ccTipoResultadoDial set descTranslate=''systemTranslated_NoAnswer'' where tipoResDial_id=3
				update  ccTipoResultadoDial set descTranslate=''systemTranslated_Fax'' where tipoResDial_id=4
				update  ccTipoResultadoDial set descTranslate=''systemTranslated_NoDialTone'' where tipoResDial_id=5
				update  ccTipoResultadoDial set descTranslate=''systemTranslated_Other'' where tipoResDial_id=8
				update  ccTipoResultadoDial set descTranslate=''systemTranslated_NoService'' where tipoResDial_id=10
				update  ccTipoResultadoDial set descTranslate=''systemTranslated_VoiceMail'' where tipoResDial_id=11
				update  ccTipoResultadoDial set descTranslate=''systemTranslated_Congestion'' where tipoResDial_id=12
		end'
		EXEC(@sql)

		set @process = 'DEV2_16_K004019-Historial_de_gestiones '
        set @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_GetPreviewHistory'')
		begin
			DROP PROCEDURE ccsp_GetPreviewHistory;
		end'
		EXEC(@sql)

		set @process = 'DEV2_16_K004019-Historial_de_gestiones create sp ccsp_GetPreviewHistory'
        set @sql = '
		create Proc ccsp_GetPreviewHistory( @callOut_Id int ,@initialRow smallint,@finalRow smallint)
		AS
		declare @initialDate datetime, @finalDate datetime
		set @finalDate= GETDATE()
		set @initialDate = (select DATEDIFF(day,30,@finalDate))

		declare @temTable table (callOut_id int, dialResult varchar(50),disposition varchar(100),date datetime)
		insert into @temTable 
					select co.callout_id as callOut_id, 
					trd.descTranslate dialResult,
					ISNULL( tco.Description,'''') as calificacion,
					ld.fecha as fecha
					from ccoCallsOut co 
					left join ccoLogDials ld on co.callout_id = ld.callout_id
					left join cctipoResultadoDial trd ON ld.tipoResDial_id = trd.tiporesdial_id
					LEFT JOIN cctipocalifout tco ON tco.calif_id = co.calif_id
					where co.callout_id = @callOut_Id and ld.fecha >= @initialDate and ld.fecha <=@finalDate and ld.tipoResDial_id != 13

					union 
					select rppr.callout_id,
					tpp.descripcion,
					'''',
					rppr.reg_date
					from RegProcessPreviewRecord rppr
					join ccTypeProcessPreview tpp on rppr.process= tpp.typeProcess_id
					where rppr.process NOT IN (1, 7) and rppr.callout_id = @callOut_Id and rppr.reg_date >= @initialDate and rppr.reg_date <=@finalDate
			

		SELECT  * FROM    
				( SELECT    ROW_NUMBER() OVER ( ORDER BY date ) AS RowNum, *
				  FROM      @temTable 
				) AS RowConstrainedResult
		WHERE   RowNum >= @initialRow
			AND RowNum <= @finalRow 
		ORDER BY RowNum	'
		EXEC(@sql)

		set @process = 'DEV2-17_K004022, DEV2-3-K004023 alter ccsp_RIAConfCamp'
        set @sql = '
		ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
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
		isnull(exitAssisted, 0) exitAssisted, isnull(previewDiscard, 0) PreviewDiscard, isnull(rotativeAlgo, 0 ) rotativeAlgo, isnull(timesPreview,0) TimesPreview, cam_tPreview
		from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
		inner join @tableExistsRec a4 on a1.cam_id=a4.camId
		--where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
		order by cam_descripcion
		return(0)
		set nocount off
		'
		EXEC(@sql)

		set @process = 'DEV2-17_K004022, DEV2-3-K004023 alter ccsp_GalateaGetOutboundConfiguration'
        set @sql = '
		ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]
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
			prefijo varchar(40),enbleprefix bit,exitAssisted bit,previewDiscard bit, rotativeAlgo tinyint , timesPreview smallint, cam_tPreview smallint)
     
				INSERT INTO @AllCampaigns EXEC ccsp_RIAConfCamp @adminID, @campID

				SELECT dialPrefixMan DialPrefixMan, dialPrefixXfe DialPrefixXfe, listenManualCall  ListenManualCall, stopRecording StopRecording, abandonCallback AbandonCallBack,
				t_autoCB AutoCB,id_anilist IdIstANI,tDialonWrapUp TDialOnWrapup, queSize Quesize, DNCScrub, callerIdDesc CallerIdDesc, timeZoneRule TimeZoneRule,callsBySurvey CallsBySurvey,
				ivrScript IvrScript, surveyPctg SurveyPctg, call_record CallRecord,startStopRecording StartStopRecording, leaveRecMessage LeaveRecMessage,manualCallOnChat ManualCallOnChat,
				callBackSurveyClient CallBackSurveyClient, callBackSurveyAgent CallBackSurveyAgent, funcEspDtmf FuncEspDtmf,sipHdrFormat SipHdrsCfg, dialPrefix DialPrefix,
				prefijo Prefix, dialOrder DialOrder, progDial ProgDial, cam_Descripcion CamDescription, cam_tNotas CamTnotas, cam_ocupado CamBusy, cam_noInt_ocupado CamNoIntBusy,
				cam_inter_ocupado CamInterBusy,cam_nocontesto CamNoAnswer, cam_noInt_nocontesto CamNoIntNoAnswer,cam_inter_nocontesto CamInterNoAnswer, (cam_inter_cancelled/60) CamInterCancelled,
				cam_fax CamFax, cam_noInt_fax CamNoIntFax,cam_inter_fax CamInterFax, cam_modomanual CamModoManual,ANI ,cam_StartTimerOnHangUp CamStartTimerOnHangUp,
				editableCallKey EditableCallKey, cam_tNoContesta CamTNoAnswer, iTipoDial  CamIntensiveDialing, detectAnswerMachine DetectAnswerMachine, detectVoiceMail DetectVoiceMail, 
				compliance Compliance, cam_inter_graba CamInterRecord,cam_noint_graba CamNoIntRecord,excCallBack ExcCallBack, cam_ShowCalifWnd CamShowCalifWnd, frame Frame, exitAssisted ExitAssistedDialMode, 
				previewDiscard PreviewDiscard, rotativeAlgo RotativeAlgo, timesPreview TimesPreview, cam_tPreview CamTPreview
				from @AllCampaigns WHERE cam_id = @campID
		END
		'
		EXEC(@sql)

		set @process = 'DEV2-17_K004022, DEV2-3-K004023 alter ccsp_RIAUpdateCamConfig'
        set @sql = '
		ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
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
				@cam_tPreview smallint = null
                as
					set nocount on
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
				 cam_tPreview = isnull(@cam_tPreview,cam_tPreview)
                Where cam_id = @cam_id

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
        ------------------------------------------------------------  END  DEV2-17_K004022, DEV2-3-K004023 ---------------------------------------------------------------------
		
		------------------------------------------------------------  Inicia Ciro ---------------------------------------------------------------------
		set @process = 'Setting para ocultar tareas de Whatsapp salida'
        set @sql = 'if not exists (select * from ccsettings where setting_id = 233)
					begin
						insert into ccSettings values (241,0,''Permitir configuracipon de Whatsapp'',1,''GRL'',''Parametro para permitir al cliente tener las configuraciones y accesos para Whatsapp'',''Permitir configuracipon de Whatsapp'',0,''^[0-1]$'',CAST(''00000000-0000-0000-0000-000000000000'' AS UNIQUEIDENTIFIER))
					end '
		EXEC(@sql)

		set @process = 'SP para consultar setting para ocultar tareas de Whatsapp salida'
        set @sql = 'CREATE PROCEDURE GetWhatsAppAllowConfiguration
					AS
					select valor from ccSettings WHERE setting_id = 241'
		EXEC(@sql)

		set @process = 'K020002 Crear campaña WhatsApp Out'
        set @sql = 'ALTER TABLE contactmeanout ADD camp_id int null, numMessages tinyint null, closeConversationTime tinyint null, answerTimeoutClient tinyint null, allowFileAttachments bit null
					ALTER TABLE contactmeanout Alter column conexionInfo varchar(255) null;
					ALTER TABLE contactmeanout Alter column connUser varchar(60) null;
					ALTER TABLE contactmeanout Alter column ConnPass varchar(30) null;
					ALTER TABLE ccCamps ADD chat int null
					ALTER TABLE ccWhatsAppNumbers ADD camp_id int null'
		EXEC(@sql)

		set @process = 'K020002 Crear campaña WhatsApp Out ccsp_MultimediaConfigurations'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_MultimediaConfigurations] 
				@Option AS SMALLINT,
				@ServiceType AS SMALLINT = 0,
				@Number AS VARCHAR(25) = ''''
				AS
				BEGIN
				    SET NOCOUNT ON;
					BEGIN
				    IF(@Option = 1) -- Get Vonage Configurations depending the Service Type and number 
						BEGIN
							SELECT config.applicationId AS ApplicationId,
								   config.secretKey AS SecretKey,
								   config.messagesUrl AS MessagesUrl
							FROM ccVonageConfigurations config
							INNER JOIN ccWhatsAppNumbers numbers ON config.vonageId = numbers.vonageId 
							AND numbers.number = @Number 
							AND config.serviceType = @ServiceType   -- 5 = WhatsApp
						END 

					IF(@Option = 2) -- Get WhatsApp registered numbers 
						BEGIN
							SELECT number AS AvailableNumbers FROM ccWhatsAppNumbers Numbers 
							INNER JOIN ccVonageConfigurations Configurations 
							ON Numbers.vonageId = Configurations.vonageId 
							AND Numbers.inboundId = 0 
							AND Numbers.status = 1 
							AND Configurations.serviceType = 5
						END 
					IF(@Option = 3) -- Get WhatsApp registered numbers Outbound
						BEGIN
							SELECT number AS AvailableNumbers FROM ccWhatsAppNumbers Numbers 
							INNER JOIN ccVonageConfigurations Configurations 
							ON Numbers.vonageId = Configurations.vonageId 
							AND Numbers.camp_id IS NULL
							AND Numbers.status = 1 
							AND Configurations.serviceType = 5
						END
					END
				END'
		EXEC(@sql)

		set @process = 'K020002 Crear campaña WhatsApp Out ccsp_GalateaAdminCampaigns'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS      SMALLINT, 
                                       @CampType AS    SMALLINT = 0, 
                                       @WorkgroupId AS INT      = 0, 
                                       @Id AS          INT      = 0, 
                                       @AdminId AS     SMALLINT = 0, 
                                       @PinUpdate AS   SMALLINT = 0, 
                                       @LoadId AS      INT      = 0, 
                                               @Type AS        SMALLINT = 0,
											   @InboundType	   SMALLINT = 0,
											   @AreaId		   SMALLINT = 0,
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
															CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, CONVERT(tinyint,isnull(camps.chat,0)) as OutboundType
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
													CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType, CAST(0 AS tinyint) as OutboundType
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
					INNER JOIN ccInbound inbound ON Inbound_id = campPerWg.IdCampEsp 
					AND C.TipoUser_id = 1
					WHERE campPerWg.Tipo = @CampType
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
											CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, CONVERT(tinyint,isnull(camps.chat,0)) as OutboundType
										FROM ccCamps camps (NOLOCK)
											INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
											INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
											--WHERE camps.cam_id = @Id
											ORDER BY camps.cam_descripcion ASC;
								END;
								ELSE
									BEGIN
										SELECT DISTINCT 
											CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType, CAST(0 AS tinyint) as OutboundType
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

		set @process = 'K020002 Crear campaña WhatsApp Out ccsp_UpdateOutWhatsappConfig'
        set @sql = 'CREATE PROCEDURE  [dbo].[ccsp_UpdateOutWhatsappConfig] 
			@ConexionInfo varchar(400),
			@outbound_id int,
			@descripcion varchar(400), 
			@ConnUser varchar(60),
			@tNotas int,
			@closeConversationTime tinyint,
			@ShowCalifWnd bit,
			@ExitWrapUpDisposition bit,
			@MUTimeOutClient int,
			@allowFileAttachments bit
			AS
			set nocount on
			IF NOT EXISTS (SELECT camp_id FROM ContactMeanOut WHERE camp_id = @outbound_id) 
					BEGIN
						INSERT INTO ContactMeanOut (meanContactTypeId, name, camp_id, isActive, numMessages,conexionInfo,connUser,closeConversationTime,ConnPass,answerTimeoutClient,allowFileAttachments) values 
						(5, @descripcion, @outbound_id, (select cam_activo  from ccCamps where cam_id = 4),3,@conexionInfo,@connUser,@closeConversationTime,''N/A'',@MUTimeOutClient,@allowFileAttachments);
					END

			IF EXISTS (SELECT camp_id FROM ContactMeanOut WHERE camp_id = @outbound_id)
			BEGIN
			
				UPDATE ccWhatsAppNumbers SET camp_id = @outbound_id WHERE number = @conexionInfo
			END;

			IF EXISTS (SELECT cam_id FROM ccCamps WHERE cam_id = @outbound_id) 
			BEGIN
				UPDATE ccCamps SET cam_tnotas = @tNotas, cam_ShowCalifWnd = @ShowCalifWnd, exitAssisted = @ExitWrapUpDisposition, chat = 5 where cam_id = @outbound_id;
			END;
			SELECT @outbound_id;
			return(@outbound_id)

			set nocount off'
		EXEC(@sql)

		set @process = 'K020002 Crear campaña WhatsApp Out ccsp_RIALoadCamps'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIALoadCamps] @option SMALLINT, @AreaId SMALLINT = NULL, @Sup SMALLINT = NULL, @WGID SMALLINT = NULL
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
			CAST(CASE WHEN a1.progDial = 3 THEN 6 WHEN a1.chat = 5 THEN 5 ELSE 0 END as [tinyint]) [MediaType]
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

		set @process = 'K020002 Crear campaña WhatsApp Out ccsp_GalateaGetOutboundConfiguration'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]
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
			prefijo varchar(40),enbleprefix bit,exitAssisted bit,previewDiscard bit , chat int )
			
				INSERT INTO @AllCampaigns EXEC ccsp_RIAConfCamp @adminID, @campID

				SELECT dialPrefixMan DialPrefixMan, dialPrefixXfe DialPrefixXfe, listenManualCall  ListenManualCall, stopRecording StopRecording, abandonCallback AbandonCallBack,
				t_autoCB AutoCB,id_anilist IdIstANI,tDialonWrapUp TDialOnWrapup, queSize Quesize, DNCScrub, callerIdDesc CallerIdDesc, timeZoneRule TimeZoneRule,callsBySurvey CallsBySurvey,
				ivrScript IvrScript, surveyPctg SurveyPctg, call_record CallRecord,startStopRecording StartStopRecording, leaveRecMessage LeaveRecMessage,manualCallOnChat ManualCallOnChat,
				callBackSurveyClient CallBackSurveyClient, callBackSurveyAgent CallBackSurveyAgent, funcEspDtmf FuncEspDtmf,sipHdrFormat SipHdrsCfg, dialPrefix DialPrefix,
				prefijo Prefix, dialOrder DialOrder, progDial ProgDial, cam_Descripcion CamDescription, cam_tNotas CamTnotas, cam_ocupado CamBusy, cam_noInt_ocupado CamNoIntBusy,
				cam_inter_ocupado CamInterBusy,cam_nocontesto CamNoAnswer, cam_noInt_nocontesto CamNoIntNoAnswer,cam_inter_nocontesto CamInterNoAnswer, (cam_inter_cancelled/60) CamInterCancelled,
				cam_fax CamFax, cam_noInt_fax CamNoIntFax,cam_inter_fax CamInterFax, cam_modomanual CamModoManual,ANI ,cam_StartTimerOnHangUp CamStartTimerOnHangUp,
				editableCallKey EditableCallKey, cam_tNoContesta CamTNoAnswer, iTipoDial  CamIntensiveDialing, detectAnswerMachine DetectAnswerMachine, detectVoiceMail DetectVoiceMail, 
				compliance Compliance, cam_inter_graba CamInterRecord,cam_noint_graba CamNoIntRecord,excCallBack ExcCallBack, cam_ShowCalifWnd CamShowCalifWnd, frame Frame, exitAssisted ExitAssistedDialMode, previewDiscard PreviewDiscard, chat Chat
				from @AllCampaigns WHERE cam_id = @campID
		END'
		EXEC(@sql)

		set @process = 'K020002 Crear campaña WhatsApp Out ccsp_RIAConfCamp'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
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
			isnull(exitAssisted, 0) exitAssisted, isnull(previewDiscard, 0) PreviewDiscard, isnull(chat, 0) Chat
			from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
			inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
			inner join @tableExistsRec a4 on a1.cam_id=a4.camId
			--where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
			order by cam_descripcion
			return(0)
			set nocount off'
		EXEC(@sql)
		------------------------------------------------------------  Termina Ciro ---------------------------------------------------------------------
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