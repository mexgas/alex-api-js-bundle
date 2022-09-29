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
