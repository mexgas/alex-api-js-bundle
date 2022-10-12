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

		set @process = 'DEV2-3_K004023-Admin-Config_Times_Preview add column timesPreview'
        set @sql = '
		if not exists (select * from sys.columns where name = N''timesPreview'' and Object_ID = Object_ID(N''ccCamps''))
		begin
			alter table ccCamps add timesPreview tinyint not null default 5
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
 ------------------------------------------------------------ DEV2-3_K004023-labels-reports---------------------------------------------------------------------
		set @process = 'DEV2-17_K004022-Admin-Config_Tiempo_Preview add column cam_tPreview'
        set @sql = '
		if not exists(select typeProcess_id from ccTypeProcessPreview where typeProcess_id = 8)
			begin
			insert into  ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (8, ''systemTranslated_DiscardByMaxTimes'','''')
		end
'
		EXEC(@sql)
		------------------------------------------------------------  END  DEV2-3_K004023-labels-reports ---------------------------------------------------------------------


        ------------------------------------------------------------ DEV2-17_K004022, DEV2-3-K004023 ---------------------------------------------------------------------
		set @process = 'DEV2-3_K004023-Admin-Config_Times_Preview edit sp ccsp_RegProcessPreviewRecord'
        set @sql = '
				ALTER PROCEDURE [dbo].[ccsp_RegProcessPreviewRecord](
        @process smallint,
        @callout_id int,
        @agent_id smallint,
        @camId int,
		@previewTime smallint,
		@callId int)
        AS
        DECLARE @result_callout_id INT
		DECLARE @result_maxtimespreview INT = 0
		DECLARE @insert_date DATETIME = SYSDATETIME()
		DECLARE @first_date DATETIME = DATEADD(hh, 00, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
		DECLARE @process_insert int =  @process

        if(exists(select top 1 1 from ccoWorkingTable nolock where callout_id = @callout_id)) begin
            set @result_callout_id =1
        end

        IF (@process=1 AND @result_callout_id > 0)
        BEGIN
            DELETE ccoWorkingTable WHERE callout_id = @callout_id
			RETURN
        END

		IF (@process NOT IN (1, 7))
		BEGIN
			if(
				(SELECT COUNT(process) FROM RegProcessPreviewRecord 
				WHERE reg_date BETWEEN @first_date AND @insert_date
				and (process != 1 AND process != 7) 
				and (callout_id=@callout_id)
				)
				>=
				(SELECT timesPreview FROM ccCamps WHERE cam_id = @camId)
				)
			begin
					set @result_maxtimespreview = 1
					set @process_insert = 8
					DELETE ccoWorkingTable WHERE callout_id = @callout_id
			end
		END

		IF (@result_callout_id > 0 or @process in (4,7))
        BEGIN
            INSERT INTO RegProcessPreviewRecord(userId,process,callout_id,camId,reg_date,tPreview, callID) VALUES (@agent_id,@process_insert,@callout_id,@camId,@insert_date,@previewTime,@callId)
		END

		select @result_maxtimespreview as ''value'''
		EXEC(@sql)
		------------------------------------------------------------  END  DEV2-17_K004022, DEV2-3-K004023 ---------------------------------------------------------------------

	SET @process = 'DEV3-19 Alter procedure ccsp_AgentUpdateCallCALIF'
	SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_AgentUpdateCallCALIF] @IDCall INT, @calif_id SMALLINT, @TipoCall SMALLINT, @Origin INT = 0, @cal_key VARCHAR(40) = NULL, @callOutId INT = 0, @subId SMALLINT = 0
AS
SET NOCOUNT ON

DECLARE @RecicleSIC TINYINT, @Reprogram TINYINT, @DateNewDial SMALLDATETIME, @idTipoLista INT, @autoCB TINYINT, @tel VARCHAR(30), @camp INT, @iddncList AS INT
DECLARE @userid INT

SELECT @RecicleSIC = valor
FROM ccSettings
WHERE setting_id = 60

SELECT @RecicleSIC = IsNull(@RecicleSIC, 0)

DECLARE @hashTel INT
DECLARE @killListID INT = (
		SELECT idtipolista
		FROM ccTiposListaNegra
		WHERE Tipolista = ''default/KillList''
		)
DECLARE @killListSetting INT = (
		SELECT STATUS
		FROM ccSettings
		WHERE setting_id = 215
		)

IF @TipoCall = 1
BEGIN
	UPDATE ccCallsIN
	SET calif_id = @calif_id, cal_origin_id = @Origin, cal_key = isnull(@cal_key, cal_key), califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
	WHERE cal_id = @IDCall

	IF EXISTS (
			SELECT idTipoLista
			FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
			WHERE tipo = 0 AND calif_id = @calif_id
			)
	BEGIN
		SELECT @tel = dbo.Completa_ListaNegra(ci.cal_ANI), @iddncList = cbl.idTipoLista
		FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
		JOIN cccalifblacklist AS cbl ON ci.calif_id = cbl.calif_id
		WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0

		IF @tel IS NOT NULL AND @iddncList IS NOT NULL
		BEGIN
			--insert ccListaNegra
			INSERT INTO cclistanegra (telefono, idtipolista)
			VALUES (@tel, @iddncList)

			--insert cc_killlist
			IF (@killListSetting = 1 AND @iddncList = @killListID) -- verifies if kill list setting is active and if the list_id matches killList id
			BEGIN
				select @hashTel = dbo.hashPhone(@tel)

				IF NOT EXISTS (
						SELECT hashtel
						FROM cc_KillList
						WHERE hashTel = @hashTel
						)
				BEGIN
					INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
					VALUES (@hashTel, @iddncList, GETDATE())
				END
			END

			INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
			SELECT dbo.Completa_ListaNegra(ci.cal_ANI), cbl.idTipoLista, ci.Inbound_id, getdate(), ci.dni_id, 6
			FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
			JOIN cccalifblacklist cbl ON ci.calif_id = cbl.calif_id
			WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0
		END
	END

	RETURN (0)
END

IF @TipoCall = 2
BEGIN
	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	SELECT @autoCB = autocallback
	FROM ccTipoCalifSubout
	WHERE califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	IF @autoCB IS NULL
	BEGIN
		SELECT @autoCB = autocallback
		FROM cctipocalifout
		WHERE calif_id = @calif_id
	END

	IF @autoCB = 1
	BEGIN
		SELECT @callOutId = callout_id, @camp = cam_id, @userid = user_id
		FROM ccocallsout
		WHERE Cal_id = @IDCall

		SELECT @DateNewDial = dateadd(mi, t_autoCB, getdate())
		FROM cccamps cam
		WHERE cam.cam_id = @camp

		EXEC ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
	END

	UPDATE ccoCallsOUT
	SET calif_id = @calif_id, califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
	WHERE cal_id = @IDCall

	IF EXISTS (
			SELECT idTipoLista
			FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
			WHERE tipo = 1 AND calif_id = @calif_id
			) AND NOT EXISTS (
			SELECT co.cal_telefono
			FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
			JOIN ccListaNegra bl ON dbo.Completa_ListaNegra(co.cal_telefono) = bl.telefono OR co.cal_telefono = bl.telefono
			WHERE co.cal_id = @idCall AND bl.idtipolista IN (
					SELECT idTipoLista
					FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
					WHERE tipo = 1 AND calif_id = @calif_id
					)
			)
	BEGIN --IF

		CREATE TABLE #NUMANDBL (id int identity,  iddncList int)
		CREATE TABLE #NUMBERS (id int identity, number varchar(30))
		DECLARE @allnumbersToBl BIT
		DECLARE @number varchar(30)

		SELECT @allnumbersToBl = allNumbersToBlacklist FROM ccTipoCalifOUT WHERE calif_id = @calif_id

		IF(@allnumbersToBl = 1)
		BEGIN
			DECLARE @camid SMALLINT
			SELECT @camid = cam_id FROM ccoCallsOut WITH (INDEX (PK_ccoCallsOut)) WHERE cal_id = @IDCall
			DECLARE @i SMALLINT = 0
			WHILE (@i < 5 )
			BEGIN
				SELECT @number = CASE @i 
									WHEN 0 THEN cal_telefono 
									WHEN 1 THEN cal_telefono2
									WHEN 2 THEN cal_telefono3
									WHEN 3 THEN cal_telefono4
									WHEN 4 THEN cal_telefono5
									END FROM ccoCallsOutSource WHERE callout_id = @callOutId AND cam_id = @camid
				SET @number = dbo.Completa_ListaNegra(@number)
				IF(LEFT(@number, 1) <> ''E'') 
				BEGIN
					INSERT INTO #NUMBERS (number) VALUES (@number)
				END
				SET @i = @i + 1
			END
		END
		ELSE
		BEGIN
			SELECT @number = co.cal_telefono
			FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
			WHERE co.cal_id = @idCall 
			SET @number = dbo.Completa_ListaNegra(@number)
			IF(LEFT(@number, 1) <> ''E'') 
			BEGIN
				INSERT INTO #NUMBERS (number) VALUES (@number)
			END
		END

		IF((SELECT COUNT(*) FROM #NUMBERS) > 0) begin
			INSERT INTO #NUMANDBL (iddncList) 
			select cbl.idTipoLista from cccalifblacklist cbl  where cbl.calif_id=@calif_id and cbl.tipo = 1
		END

		DECLARE @Count int		
		WHILE (SELECT count(id) from #NUMANDBL) > 0
		BEGIN  --WHILE
			select @Count = count(id) from #NUMANDBL
			SELECT @iddncList = iddncList from #NUMANDBL where id = @Count
			DECLARE @countNumbers INT, @indexNumbers INT = 1
			SELECT @countNumbers = COUNT(*) FROM #NUMBERS
			WHILE( @indexNumbers <= @countNumbers) --WHILE NUMBERS
			BEGIN 
				SELECT @tel = number FROM #NUMBERS WHERE id = @indexNumbers
				IF @tel IS NOT NULL AND @iddncList IS NOT NULL
				BEGIN--Tel adn iddnclist
					EXEC ccsp_InsertDNCList @tel, @iddncList

					IF (@killListSetting = 1 AND @iddncList = @killListID)
					BEGIN
						select @hashTel = dbo.hashPhone(@tel)

						IF NOT EXISTS (SELECT hashtel FROM cc_KillList WHERE hashTel = @hashTel)
						BEGIN
							INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
							VALUES (@hashTel, @iddncList, GETDATE())
						END
					END

					INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
					SELECT @tel, @iddncList, co.cam_id, getdate(), co.callout_id, 6
					FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
					--JOIN cccalifblacklist cbl ON co.calif_id = cbl.calif_id
					WHERE co.cal_id = @idCall 
				END --Tel adn iddnclist
				SET @indexNumbers = @indexNumbers + 1
			END --WHILE NUMBERS
			delete from #NUMANDBL where id = @Count
		END --WHILE
		DROP TABLE #NUMANDBL
		DROP TABLE #NUMBERS
	END --IF
	IF @RecicleSIC = 1
	BEGIN
		-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
		SELECT @Reprogram = CanReprogram
		FROM ccTipoCalifSubout
		WHERE califSub_Id = @subId

		-- Si no tiene subcalificacion toma la de la calificacion
		IF @Reprogram IS NULL
		BEGIN
			SELECT @Reprogram = CanReprogram
			FROM ccTipoCalifOUT
			WHERE calif_id = @calif_id
		END

		IF @callOutId = 0
			SELECT @callOutId = callout_id
			FROM ccocallsout
			WHERE Cal_id = @IDCall

		UPDATE ccoWorkingTable
		SET calif_id = @calif_id, cal_status = CASE @Reprogram WHEN 0 THEN 3 ELSE cal_status END
		WHERE callout_id = @callOutId
	END

	DECLARE @keepDial BIT
	DECLARE @finishPreview SMALLINT

	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	SELECT @keepDial = keepDial
	FROM ccTipoCalifSubout
	WHERE califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	IF @keepDial IS NULL
	BEGIN
		SELECT @keepDial = keepDial
		FROM ccTipoCalifout
		WHERE calif_id = @calif_id
	END

	SELECT @finishPreview = isnull(finishPreview, 0)
	FROM ccTipoCalifout
	WHERE calif_id = @calif_id

	IF @keepDial = 1
	BEGIN
		UPDATE ccologdials
		SET TipoDialingMode = dbo.fn_getDialingMode(@IDCall, 3, 0, @camp)
		WHERE logDial_id IN (
				SELECT TOP 1 L.logDial_id
				FROM ccoLogDials L WITH (INDEX (IX_ccoLogDials_2), NOLOCK)
				JOIN ccoCallsOut O WITH (INDEX (PK_ccoCallsOut), NOLOCK) ON L.callout_id = O.callout_id
				WHERE O.cal_id = @IDCall
				ORDER BY L.logDial_id DESC
				)
	END

	SELECT @keepDial, @finishPreview

	RETURN (0)
END

SET NOCOUNT OFF'
	EXEC (@sql)

        --- IVAN MARTIN  DEV1-23- Permiso para reproducir grabaciones en historial de llamadas ---

		set @process = 'DEV1-23 Rename table ccRIAUsersPermissions for better code understanding'
		set @sql = 'IF EXISTS (SELECT * FROM sys.tables WHERE name = N''ccRIAUsersPermissions'')
					BEGIN
						EXEC sp_rename ''ccRIAUsersPermissions'', ''ccRIAAgentsPermissionsTags''
					END'
		EXEC(@sql)

		set @process = 'DEV1-23 Rename table ccRIAMultimediaUsersPermissions for better code understanding'
		set @sql = 'IF EXISTS (SELECT * FROM sys.tables WHERE name = N''ccRIAMultimediaUsersPermissions'')
					BEGIN
						EXEC sp_rename ''ccRIAMultimediaUsersPermissions'', ''ccRIAAgentsPermissions''
					END'
		EXEC(@sql)

		set @process = 'DEV1-23 Add new column to table ccRIAAgentsPermissions'
		set @sql = 'IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''AllowPlayRecordsOnCallHistory'' AND Object_ID = Object_ID(N''ccRIAAgentsPermissions''))
					BEGIN
						ALTER TABLE ccRIAAgentsPermissions
						ADD AllowPlayRecordsOnCallHistory BIT NOT NULL
					END'
		EXEC(@sql)

		set @process = 'DEV1-23 Insert new tags to ccRIAAgentsPermissionsTags'
		set @sql = 'IF EXISTS (SELECT * FROM sys.tables WHERE name = N''ccRIAAgentsPermissionsTags'')
					BEGIN
						INSERT INTO ccRIAAgentsPermissionsTags (PermissionId, PermissionName, PermissionTag)
						VALUES (14, ''AllowPlayRecordsOnCallHistory'',  ''Reproducir grabaciones en historial|Play back recordings in log|Reproduzir gravações no histórico'')
					END'
		EXEC(@sql)

		set @process = 'DEV1-23 Drop procedure ccsp_GalateaCreateUser'
		set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_GalateaCreateUser'')
					BEGIN
					    DROP PROCEDURE ccsp_GalateaCreateUser;
					END'
		EXEC(@sql)

		set @process = 'DEV1-23 Add insertion into table ccRIAAgentsPermissions (line 127 and 159) for new column AllowPlayRecordsOnCallHistory when user is created'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaCreateUser]
					@UserId int,
					@Login varchar(40),
					@Nombres varchar(45),
					@LastName varchar(45),
					@NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
					@Password varchar(200),
					@Sexo bit,
					@canChangeStatus bit,
					@AreaId int,
					@UserType tinyint
					as

					Declare @ApellidoMaterno varchar(45)
					Declare @ApellidoPaterno varchar(45)

					--Obtiene el idioma de de Centerware
					Declare @lenguageXion varchar
					select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

					--se acondiciona los apellidos con el nombre opcional dependiendo del idioma
						if @lenguageXion= ''0'' or @lenguageXion= ''2'' --para español y portugues
						begin
							set @ApellidoPaterno = @LastName
							set @ApellidoMaterno = @NombreOpcionalExtra
						end
						else-- es idioma ingles
						begin
							set @ApellidoPaterno = @NombreOpcionalExtra 
							set @ApellidoMaterno = @LastName
						end

					-- validaciones 
						if exists(select Login from ccUsers where Login=@Login)
						begin
						select -1 as ResponseCode--,''Login en Uso''
						return(0)
						end

						if exists(select Login from ccUsers_Consulta where Login = @Login)
						begin
						select -4 as ResponseCode -- ''Login en Uso aunque el usuario ya se halla borrado de la base de datos'' -- quiza falta la validacion cuando el usuario ya se ha borrado pero mediante borrado logico
						return(0)
						end

						if exists(select Nombres from ccUsers where Nombres=@Nombres
						and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
						begin
						select -2 as ResponseCode--,''Nombre completo en Uso''-- valida todos los campos de nombre para ver que no existan en la base de datos
						return(0)
						end


					--insert
					IF( select isnull(max(user_id),0) from ccusers) > 32700
					BEGIN
						set @UserId = null
						SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID
						FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
						LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
						INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
						FROM ccusers) AS w ON w.recID = d.recID

						if @UserId is null
						begin
						select -3 as ResponseCode --Error_when_inserting_user
						return(0)
						end

						set identity_insert ccusers on
						insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
						Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
						select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
						1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
						set identity_insert ccusers off

						delete ccMenuUser where id_User = @UserId
						delete ccRIAUserRole where user_id = @UserId

						exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

						--Insert Agent into ccRIAAgentsPermissions
						IF EXISTS (SELECT * FROM ccUsers WHERE User_id = @UserId AND TipoUser_id = 1) 
						BEGIN
						IF NOT EXISTS (SELECT * FROM ccRIAAgentsPermissions WHERE AgentId = @UserId)
						BEGIN 
							INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory)
							VALUES (@UserId, 0, 0, 0)
						END
						END

					END
					ELSE
					BEGIN
						insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
						Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
						select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
						1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end

						if @@rowcount=1
						select @UserId=scope_identity()
						else
						begin
						select -2--insert Error
						return(0)
						end
					END
						insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
						insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
						insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
						--Menu para roles RepotsRia
						exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

						--Insert Agent into ccRIAAgentsPermissions
						IF EXISTS (SELECT * FROM ccUsers WHERE User_id = @UserId AND TipoUser_id = 1) 
						BEGIN
						IF NOT EXISTS (SELECT * FROM ccRIAAgentsPermissions WHERE AgentId = @UserId)
						BEGIN 
							INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory)
							VALUES (@UserId, 0, 0, 0)
						END 
						END
					select 200 as ResponseCode -- indica que se agrego correctamente un nuevo usuario'
		EXEC(@sql)

		set @process = 'DEV1-23 Drop procedure ccsp_GalateaAdminSetPermissions'
		set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_GalateaAdminSetPermissions'')
					BEGIN
					    DROP PROCEDURE ccsp_GalateaAdminSetPermissions;
					END'
		EXEC(@sql)

		set @process = 'DEV1-23 Add implementation to set AllowPlayRecordsOnCallHistory (lines 237 to 246)'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
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

					SET NOCOUNT OFF'
		EXEC(@sql)

		set @process = 'DEV1-23 Drop procedure ccsp_GalateaAdminGetPermissions'
		set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_GalateaAdminGetPermissions'')
					BEGIN
					    DROP PROCEDURE ccsp_GalateaAdminGetPermissions;
					END'
		EXEC(@sql)

		set @process = 'DEV1-23 Implementation to get AllowPlayRecordsOnCallHistory (lines 464 and 490)'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
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
					    cast(AllowDeleteRecord as int) as AgentPermissionDelete
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
					    cast(AllowDeleteRecord as int) as AgentPermissionDelete
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
					set nocount off'
		EXEC(@sql)

		--- END IVAN MARTIN  DEV1-23- Permiso para reproducir grabaciones en historial de llamadas ---}

				 ---------------- KR008000_Callkey_en_llamadas_manuales ----------------------------------------------------
		set @process = 'KR008000_Callkey_en_llamadas_manuales create table ccOdbc'
        set @sql = 'if not exists (select * from sys.tables where name = N''ccOdbc'')
        begin
            create table [dbo].[ccOdbc](
			[odbc_id] [SMALLINT] PRIMARY KEY IDENTITY(1,1) NOT NULL,
			[value] [VARCHAR](300) NULL,
			[description] [VARCHAR](600) NOT NULL,
			[status] [TINYINT] NULL,
			[detail] [VARCHAR](600) NULL,
			[tableName] [VARCHAR](300) NULL,
			[columnName] [VARCHAR](300) NULL,
			[columnPhone] [VARCHAR](300) NULL,
			[columnCallKey] [VARCHAR](300) NULL)
        end'
        EXEC(@sql)

		SET @process = 'KR008000_Callkey_en_llamadas_manuales add column to ccCamps table'
		set @sql = 'IF not exists (SELECT * FROM sys.columns WHERE name = N''odbc_id'' AND Object_ID = Object_ID(N''ccCamps''))
			BEGIN
				alter table ccCamps add odbc_id smallint null
			END'
		EXEC(@sql)

		set @process = 'KR008000_Callkey_en_llamadas_manuales Add Constraint FK_ccCamps_ccOdbc'
        set @sql = 'IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
            WHERE CONSTRAINT_NAME =''FK_ccCamps_ccOdbc'')
            BEGIN
				ALTER TABLE dbo.ccCamps DROP CONSTRAINT FK_ccCamps_ccOdbc
            END
			ALTER TABLE dbo.ccCamps ADD CONSTRAINT FK_ccCamps_ccOdbc FOREIGN KEY (odbc_id) REFERENCES dbo.ccOdbc(odbc_id)'

		EXEC(@sql)

		set @process = 'KR008000_Callkey_en_llamadas_manuales add setting 239'
        set @sql = 'IF NOT EXISTS(	SELECT cs.setting_id FROM dbo.ccSettings AS cs WHERE cs.setting_id = 239)
            BEGIN
				INSERT INTO dbo.ccSettings(setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate)
				VALUES(239, ''0'', ''Tipo de ODBC a utilizar'', 1, ''AGT'', ''Permite elegir el método de ODBC a utilizar en Agente Kolob. Valores(0,1,2). 0 = No configurado (valor default), 1 = Configuración de un ODBC, 2 = Configuración de más de un ODBC.'', 
				''ODBC type to use'', 1, ''^[0-2]$'')
            END'

		EXEC(@sql)

		set @process = 'KR008000_Callkey_en_llamadas_manuales Drop procedure ccsp_ODBCCampaign '
		 SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''P'' AND name = ''ccsp_ODBCCampaign'')
					BEGIN
                        DROP PROCEDURE ccsp_ODBCCampaign
                    END'
        EXEC(@sql)

			set @process = 'KR008000_Callkey_en_llamadas_manuales Create procedure ccsp_ODBCCampaign '
		 SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_ODBCCampaign]
						@campID SMALLINT
					AS
					BEGIN
					SET NOCOUNT ON;

					SELECT co.value, co.tableName, co.columnName,co.columnPhone,co.columnCallKey FROM dbo.ccCamps AS cc
					INNER JOIN dbo.ccOdbc AS co
					ON co.odbc_id = cc.odbc_id
					WHERE cc.cam_id = @campID AND co.status = 1;

					END'
        EXEC(@sql)

		SET @process = 'KR008000_Callkey_en_llamadas_manuales add column to ccoCallsOUT table'
		set @sql = 'IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''cal_odbc'' AND Object_ID = Object_ID(N''ccoCallsOUT''))
			BEGIN
				ALTER TABLE ccoCallsOUT ADD cal_odbc bit NOT NULL default(0)
			END'
		EXEC(@sql)

		SET @process = 'KR008000_Callkey_en_llamadas_manuales Alter procedure ccsp_AGENTInsertCallOut'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_AGENTInsertCallOut]
		@cam_id smallint,
		@cal_Key varchar(40),
		@cal_Telefono varchar(30),
		@user_id int,
		@cal_extension varchar(7),
		@sData varchar(255) = '''', --HLAS para guardar notas de la llamada
		@existCallOut as int = 0,
		@callmode as smallint = 0,
		@odbc AS BIT = 0
		AS
		set 
		nocount on
		declare @fecha as datetime, @callout_id as int, @cal_id as int, @calloutMaxTime as int
		select @fecha=getdate()
		declare @dialPrefix integer
		select @dialPrefix = valor from ccSettings where setting_id = 202

		if @callmode = 1 begin
			INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
			select @existCallOut, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 0, @cal_extension, @odbc
			select @cal_id = scope_identity()

			insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
			select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
			from ccRIACampEspWG wg 
			where wg.tipo = 1 and wg.idcampesp =@cam_id

			select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
			select @existCallOut as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
		  return(0)
		end

		if @existCallOut=0  begin
			declare @prefijoMarcacion varchar(100) 
			set @prefijoMarcacion = ''''
			declare @LasCallKey varchar(20)
			set @LasCallKey = @cal_Key
			declare @settingCallKey as int
			select @settingCallKey = valor from ccSettings where setting_id = 194
	  
			if(@settingCallKey = 1) begin
				if (@cal_Key='''' or @cal_Key is null) begin   
					select top 1 @LasCallKey=cal_Key from ccoCallsOut where cam_id=@cam_id and cal_Inicio>=convert(datetime,getdate()) and cal_manual=0 order by cal_id desc
					set @cal_Key= @LasCallKey
				end
			end

			if @dialPrefix = 1 and len(@cal_telefono)>20
				begin
					set @prefijoMarcacion = LEFT(@cal_telefono ,len(@cal_telefono)-10)
					set @cal_telefono = RIGHT(@cal_telefono,10)		
				end
			else 
				begin
					set @prefijoMarcacion =''''			 
				end
		
			INSERT ccocallsoutsource (cal_key, cam_id, cal_telefono, cal_status, user_id, cal_fechaDial, dato1,dialPrefix)
			select @cal_Key, @cam_id, substring(@cal_Telefono, 1, 19), 6, @user_id, @fecha, @sData,@prefijoMarcacion
			select @callout_id = scope_identity()

			INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
			select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension, @odbc
			select @cal_id = scope_identity()

		
		 end

		else begin --@existCallOut<>0
			Update ccocallsoutsource set cam_id=@cam_id, cal_telefono=substring(@cal_Telefono, 1, 19), dato1=@sData where callout_id = @existCallOut	
			Update ccocallsout set cam_id=@cam_id, cal_telefono=@cal_Telefono where callout_id = @existCallOut
		
			set @callout_id = @existCallOut

			select top 1 @cal_id=cal_id from ccocallsout where callout_id = @callout_id order by cal_id desc
		
			if exists(select * from ccoLogDials where cal_id=@cal_id) begin
				INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
				select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension, @odbc
				select @cal_id = scope_identity()
			end
		 
		 end
		
		insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
		select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
		from dbo.ccRIACampEspWG wg 
		where wg.tipo = 1 and wg.idcampesp =@cam_id


		select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
		select @callout_id as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
		return(0)
	set nocount off'
		EXEC(@sql)

		SET @process = 'KR008000_Callkey_en_llamadas_manuales Alter function fn_getDialingMode '
		set @sql = 'ALTER function [dbo].[fn_getDialingMode](@call_id int, @TipoDialingMode tinyint, @logDial_id int, @cam_id int)
	returns nvarchar(9)
	as
	begin
		declare @valor nvarchar(9), @calif_id smallint, @califSub_id smallint, @cal_manual tinyint, @keepDial char(1), @cal_odbc bit
		set @keepDial=''0''

		-- En el caso de que no cuente con cal_id, se debe contar con logDial_id, por lo cual se busca el registro
		if @call_id is null
		 begin
			select top 1 @call_id=o.cal_id from ccoLogDials l with(nolock,index(PK_ccoLogDials)) join ccocallsout o with(nolock,index(IX_ccoCallsOut_2))
				on l.callout_id = o.callout_id and l.Puerto = o.cal_puerto
			where l.logDial_id = @logDial_id and l.fecha between convert(varchar(19), dateadd(minute, -5, o.cal_inicio), 121)
			and convert(varchar(19), dateadd(minute, 5, o.cal_inicio), 121)
			order by datediff(ss, l.fecha, o.cal_inicio) asc -- en caso de tener mas de uno, toma el que tenga menor diferencia en tiempo
		 end

		if @cam_id is null
		 begin
			select @calif_id=calif_id, @califSub_id=califSub_id, @cal_manual=cal_manual, @cam_id=cam_id, @cal_odbc = cal_odbc
			from ccocallsout O with(nolock,index(PK_ccoCallsOut))
			where O.cal_id = @call_id
		 end
		else
		 begin
			select @calif_id=calif_id, @califSub_id=califSub_id, @cal_manual=cal_manual, @cal_odbc = cal_odbc
			from ccocallsout O with(nolock,index(PK_ccoCallsOut))
			where O.cal_id = @call_id
		 end

		select @valor=isnull((select case when progDial=3 then ''100'' when progDial=2 then ''010'' when progDial=1 then ''001'' else ''000'' end + cast(iTipoDial as char(1)) + cast(abandonCallback as char(1))
		 + cast(excCallback as char(1)) from cccamps where cam_id=@cam_id), ''000000'')

		if ((select keepDial from ccTipoCalifOUT where calif_id = @calif_id)=1
		or (select keepDial from ccTipoCalifSubOUT where califSub_id = @califSub_id)=1)
			set @keepDial=''1''

		select @valor = @valor + @keepDial + case @cal_manual when 1 then ''10'' when 2 then ''01'' else ''00'' end
		
		  select @valor=substring(@valor, 1, 3) +
		  case @TipoDialingMode when 6 then ''1'' else substring(@valor, 4, 1) end + substring(@valor, 5, 2) +
		  case @TipoDialingMode when 3 then ''1'' else substring(@valor, 7, 1) end + substring(@valor, 8, 2)

		  -- Se obtiene el valor del bit en caso de que la llamada manual haya sido mediante ODBC
		  SET @valor = (CASE WHEN @cal_odbc = 1 THEN ''1'' ELSE ''0'' END)+SUBSTRING(@valor,2, LEN(@valor));
		  
	 return @valor
	end'
		EXEC(@sql)


	---------------- KR008000_Callkey_en_llamadas_manuales ----------------------------------------------------


		set @process = 'SPEC-59, DEV2-26'
        set @sql = 'delete ccsettings where setting_id in (236,238)'
		EXEC(@sql)

		set @process = 'SPEC-59 ccsettings grabacion early media'
        set @sql = 'insert ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values
			(236,0,''Habilita la grabacion de audio antes de que se conteste la llamada'',1,''GRL'',
			''Habilita la grabacion de audio antes de que se conteste la llamada (Early Media). 0-Deshabilitado, 1-Habilitado'',
			''Enable audio recording before the call is answered (Early Media). 0-Disabled, 1-Enabled'',
			1,''^[0-1]$'')'
		EXEC(@sql)

		set @process = 'DEV2-26_KR021006_CPS ccsettings cps'
        set @sql = 'insert ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values
			(238,30,''Limite de llamadas por segundo generadas por el servidor de marcacion'',1,''GRL'',
			''Llamadas por segundo (CPS). Parametro por sistema independiente de la configuracion de las troncales'',
			''Calls Per Second (CPS). Setting operate on a per-system basis, regardless of trunks settings'',
			1,''^\d{1,3}$'')'
		EXEC(@sql)

------------------------------------------------------------  Inicia Ciro ---------------------------------------------------------------------
		set @process = 'Setting para ocultar tareas de Whatsapp salida'
        set @sql = 'if not exists (select * from ccsettings where setting_id = 241)
					begin
						 insert into ccSettings (setting_id, valor, descripcion, Status, tipo, detalle, description, bLoadSettings, validate) values (241,0,''Permitir configuración de whatsapp salida'',1,''GRL'',''Habilitar campañas de WhatsApp de salida'',''Enable outbound WhatsApp campaigns'',0,''^[0-1]$'')
					end '
		EXEC(@sql)

		set @process = 'K020002 Crear campaña WhatsApp Out'
        set @sql = '
					if not exists (select * from sys.columns where name = N''camp_id'' or name = N''numMessages'' or name = N''closeConversationTime''  or name = N''answerTimeoutClient''  or name = N''allowFileAttachments'' and Object_ID = Object_ID(N''contactmeanout''))
					begin
						ALTER TABLE contactmeanout ADD camp_id int null, numMessages tinyint null, closeConversationTime tinyint null, answerTimeoutClient tinyint null, allowFileAttachments bit null
					end

					if exists (select * from sys.columns where name = N''conexionInfo'' and Object_ID = Object_ID(N''contactmeanout''))
					begin
						ALTER TABLE contactmeanout Alter column conexionInfo varchar(255) null;
					end

					if exists (select * from sys.columns where name = N''connUser'' and Object_ID = Object_ID(N''contactmeanout''))
					begin
						ALTER TABLE contactmeanout Alter column connUser varchar(60) null;
					end

					if exists (select * from sys.columns where name = N''ConnPass'' and Object_ID = Object_ID(N''contactmeanout''))
					begin
						ALTER TABLE contactmeanout Alter column ConnPass varchar(30) null;
					end

					if not exists (select * from sys.columns where name = N''chat'' and Object_ID = Object_ID(N''ccCamps''))
					begin
						ALTER TABLE ccCamps ADD chat int null
					end

					if not exists (select * from sys.columns where name = N''camp_id'' and Object_ID = Object_ID(N''ccWhatsAppNumbers''))
					begin
						ALTER TABLE ccWhatsAppNumbers ADD camp_id int null
					end'
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
															CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.chat,0) as OutboundType
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
											CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.chat,0) as OutboundType
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

		set @process = 'K020002 Drop procedure ccsp_UpdateOutWhatsappConfig'
		set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_UpdateOutWhatsappConfig'')
					BEGIN
					    DROP PROCEDURE ccsp_UpdateOutWhatsappConfig;
					END'
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
						(5, @descripcion, @outbound_id, (select cam_activo  from ccCamps where cam_id = @outbound_id),3,@conexionInfo,@connUser,@closeConversationTime,''N/A'',@MUTimeOutClient,@allowFileAttachments);
						UPDATE ccWhatsAppNumbers SET camp_id = @outbound_id WHERE number = @conexionInfo
				END;

			IF EXISTS (SELECT cam_id FROM ccCamps WHERE cam_id = @outbound_id) 
			BEGIN
				UPDATE ccCamps SET cam_tnotas = @tNotas, cam_ShowCalifWnd = @ShowCalifWnd, exitAssisted = @ExitWrapUpDisposition, chat = 5 where cam_id = @outbound_id;
			END;
			SELECT @outbound_id;

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

		set @process = 'Eliminar constraint unique de contactmeanout'
        set @sql = 'declare @name nvarchar(max),@sql2 nvarchar(max)
					SELECT
						@name=   dc.Name  
					FROM sys.tables t
					INNER JOIN sys.key_constraints dc ON t.object_id = dc.parent_object_id
					where t.name=''ContactMeanOut''  and dc.type=''UQ'' 
					ORDER BY t.Name
					select @name
					if @name is not null begin
					set @sql2=''ALTER TABLE ContactMeanOut DROP CONSTRAINT ''+@name
						exec (@sql2)
					end'
		EXEC(@sql)

		set @process = 'Añadir constraint condicional unique a contactmeanout'
        set @sql = 'create unique index UniqueIndex
					on contactmeanout(connUser)
					where meanContactTypeId != 5;'
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

