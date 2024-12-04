/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: David Medina Medina
Date: 2024/09/30
Description: Release 126.20240930.0.0
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
SET @versionfix = 26
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

SET @process = 'Alter SP ccsp_GalateaGetInboundConfiguration'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetInboundConfiguration]
@command int,
@inboundId int
AS
BEGIN

SET NOCOUNT ON;

if @command=0
begin
select descripcion from ccInbound where Inbound_id = @inboundId
end
if @command=1 -- Voice campaign
begin
	select 
	A.Inbound_id [InboundId],
	A.descripcion [Description],
	A.chat [MediaType],
	A.Status,
	isnull(gra.graphic_id,1) [Frame],
	A.tNotas,
	A.tMaxWaitCall,
	A.nMaxQue,
	A.tel_maxwait,
	A.tel_maxqueue,
	A.tel_outservice,
	A.tel_noct,
	A.ShowCalifWnd,
	A.editableCallKey [EditableCallKey],
	A.queuePosition [QueuePosition],
	A.tMaxQueueCallBack,
	A.stopRecording [StopRecording],
	A.dialPrefixOverflow [DialPrefixOverflow],
	isnull(AE.SurveyCamId,0)	 [SurveyCamId],
	isnull(A.callerIdDesc, '''') [CallerIdDesc],
	isnull(A.startStopRecording,0) [StartStopRecording],
	case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then A.callBackSurveyAgent  else cast(0 as bit) end [CallBackSurveyAgent],
	case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then A.callBackSurveyClient else cast(0 as bit) end [CallBackSurveyClient],
	case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then cast(1 as bit) else cast(0 as bit) end [IsRelationSurvey],
	isnull(A.editableDtmf,0) [EditableDtmf],
	isnull(A.addDataCallBackReminder,0) [AddDataCallBackReminder],
	isnull(A.recordHold, 0) [RecordHold],
	isnull(AE.RecordCalls, 1) [RecordCalls],
	isnull(A.EditableContactData, 0) [EditableContactData]
	from ccInbound A
	left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
	left join ccInboundExtend AE on AE.Inbound_id = @inboundId
	left join ccCamps C on C.cam_id=A.cam_id
	where A.Inbound_id=@inboundId
end
if @command=2 -- WhatsApp campaign
begin
	declare @numbers varchar(max)
	select @numbers=COALESCE(@numbers + '','', '''') + number from ccWhatsAppNumbers where inboundId is null or inboundId = 0 and status = 1
	select @numbers=COALESCE(@numbers + '','', '''') + number from ccMetaWhatsAppNumbers where Inbound_Id is null or Inbound_Id = 0 and status = 1

	select i.Inbound_id [InboundId], i.descripcion [Description], i.chat [MediaType], i.Status, isnull(g.graphic_id,1) [Frame],
	ISNULL(c.conexionInfo,'''') [Number],
	ISNULL(@numbers,'''') [FreeNumbersStr],
	CAST(ISNULL(c.closeConversationTime, 0) AS INT) [MaxAnswerTime],
	ISNULL(c.answerTimeoutClient, 30) [MUTimeOutClient],
	ISNULL(c.allowFileAttachments, 0) [AllowFileAttachments],
	i.tNotas [tNotas],
	i.ExitWrapUpDisposition,
	i.ShowCalifWnd,
	i.AssignConversationSameAgent,
	i.ConversationHistoryTime,
	i.MaximumLimitConversationsInQueue as MaxLimitQueueConversations
	from ccInbound i left join ccRIAInboundGraph g on i.Inbound_id = g.Inbound_id
	left join contactMeanIn c on i.Inbound_id = c.inboundId and i.chat = 5 and c.meanContactTypeId = 5
	where i.Inbound_id=@inboundId
end
if @command=3 -- Email campaign
begin
	select 
	A.Inbound_id [InboundId],
	A.descripcion [Description],
	A.chat [MediaType],
	A.Status,
	isnull(gra.graphic_id,1) [Frame],
	A.tNotas,
	A.ShowCalifWnd,
	C.conexionInfo [ConnInfo],
	C.connUser  [ConnUserName],
	C.ConnPass [ConnPwd],
	C.isActive [IsActive],
	C.timeAlertMessage,
	C.closeConversationTime [CloseConversationTime],
	C.answerTimeOut [AnswerTimeOut],
	C.name [SenderName]
	from ccInbound A
	left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
	left join contactMeanIn C on A.Inbound_id = C.inboundId and C.meanContactTypeId=1
	where A.Inbound_id=@inboundId
end
if @command=4 -- Chat campaign
begin
	select 
	i.Inbound_id [InboundId],
	i.descripcion [Description],
	i.chat [MediaType],
	i.Status,
	isnull(ig.graphic_id,1) [Frame],
	i.tNotas,
	i.ShowCalifWnd,
	i.inactiveChatTime [InactiveChatTime],
	i.chatDomain [ChatDomain],
	i.chatTimeOverflow [ChatTimeOverflow],
	i.chatQueueOverflow [ChatQueueOverflow]
	from ccInbound i
	left join ccRIAInboundGraph ig on ig.Inbound_id=i.Inbound_id
	where i.Inbound_id =@inboundId
end

RETURN(0)

SET NOCOUNT OFF;    
END'
EXEC(@sql);

SET @process = 'Alter SP ccsp_GalateaGetOutboundConfiguration'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]
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
	,MaxDaysPerWAConvo SMALLINT,
	RecordIvr bit,
	CamCanceled int
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
	,RecordIvr
	,isnull(CamCanceled,0) as CamCanceled
    FROM @AllCampaigns
    WHERE cam_id = @campID
END'
EXEC(@sql);

SET @process = 'Alter SP ccsp_OUTGetNewJobs'
SET @sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID int,
@test int=0,
@nAgentsLogin int=1,
@iZonas int = NULL,
@isDashboardApi BIT = 0
as
--set nocount on
declare @total int
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @sql varchar(MAX), @Order_Asc_Desc char(4)
declare @camSurvey INT, @campType INT;
select @camSurvey = 0
DECLARE @iZonasTable TABLE (value int)
declare @maxRecs varchar(3) = 0
select @maxRecs = valor from ccsettings (nolock) where setting_id = 251 and Status = 1		
select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0;
SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id =  @CAMPID;
-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')
SET DATEFIRST 1
--Checamos si es horario de verano
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
if @iZonas is null begin
exec @iZonas=ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0              
--Checamos si la campaña tiene horarios configurados
	if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
	begin
	if @iZonas = 0 begin
			SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
			return
	end
	end
	else begin
	if @camSurvey > 0
		begin
		SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
		return
		end
	end
end
set @sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
	cam_id int,
	cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
	cal_status tinyint,
	cal_fechaDial datetime,
	user_id int,
	tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
list_id int,
sequence smallint,
calkey varchar(max),
nDescartes int,
name_agent varchar(max),
SimultaneousRecs int,
international int,
tz_tmp int,
tz2_tmp int,
tz3_tmp int,
tz4_tmp int,
tz5_tmp int,
cancelAttempts int
)''
-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94
if isnull(@topCount,0)=0
select @topCount=case when @nAgentsLogin<3 then 30
when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
when @nAgentsLogin>=16 then 240 else 20 end
select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID
declare @isVerano varchar(max)
set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' END


if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin
select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )
select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';
    
	select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
W.list_id, isNull(R.sequence,0) as sequence,
cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs, isnull(cs.international, 0) international,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
isnull(w.CancelAttempts, 0) as cancelAttempts
FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
left join ccUsers us (nolock) on us.User_id=w.user_id
left join ccCampsExtend ce on ce.cam_id=W.cam_id
WHERE W.cal_status=1 -- CallBacks
and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
and (
	( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
)
and isnull(R.status,2) = 2
order by prioridad_cb desc, W.cal_fechaDial ''  + @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
											
end -- TOMA EN CUENTA LOS CALLBACKS
if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin
	select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar );
	select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';


select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
W.list_id, isNull(R.sequence,0) as sequence,
cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs, isnull(cs.international, 0) international,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
isnull(w.CancelAttempts, 0) as cancelAttempts
FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
left join ccUsers us (nolock) on us.User_id=w.user_id
left join ccCampsExtend ce on ce.cam_id=W.cam_id
WHERE W.cal_status=0 -- Nuevas
and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
and (
	( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
)
and isnull(R.status,2) = 2
order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc

end -- TOMA EN CUENTA LAS NUEVAS
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @sql=@sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
	begin
	select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
	WHERE callout_id in(select callout_id from #NEW_JOBS)''
end
if @Test = 2
begin
	select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
	declare @nSQL nvarchar(4000)
	set @nSQL=cast(@sql as nvarchar(4000))
	exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
	return(@total)
end
else
BEGIN
	IF(@isDashboardApi = 1)
	BEGIN
select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )
select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
W.list_id, isNull(R.sequence,0) as sequence,
cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs, isnull(cs.international, 0) international,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
isnull(w.CancelAttempts, 0) as cancelAttempts
FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
left join ccUsers us (nolock) on us.User_id=w.user_id
left join ccCampsExtend ce on ce.cam_id=W.cam_id
WHERE W.cal_status= 2 -- Procesando
and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
and (
	( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
)
and isnull(R.status,2) = 2
order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc
-- TOMA EN CUENTA LOS REGISTROS PROCESANDOSE
	END
	select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
	user_id,
case when tz>0  then tz  else tz_tmp end as tz,
case when tz2>0 then tz2 else tz2_tmp end as tz2,
case when tz3>0 then tz3 else tz3_tmp end as tz3,
case when tz4>0 then tz4 else tz4_tmp end as tz4,
case when tz5>0 then tz5 else tz5_tmp end as tz5,							
case when tz is null then '''''''' else cal_telefono end as tel,
case when tz2 is null then '''''''' else cal_telefono end as tel2,
case when tz3 is null then '''''''' else cal_telefono end as tel3,
case when tz4 is null then '''''''' else cal_telefono end as tel4,
case when tz5 is null then '''''''' else cal_telefono end as tel5,
NULL as dialOrder, list_id, sequence, calkey,
0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type, nDescartes, name_agent, SimultaneousRecs,'' + @maxRecs + '' maxRecs, international, cancelAttempts
FROM #NEW_JOBS where len(cal_telefono)>0
---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
declare @regval int
SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
''
end
set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print (@sql)
exec(@sql)
return(0)
'
EXEC(@sql);

SET @process = 'Alter SP ccsp_RIAConfCamp'
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
	,ISNULL(RecordIvr,0) as RecordIvr
	,isnull(CamCanceled,0) as CamCanceled
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
EXEC(@sql);

SET @process = 'Alter SP '
SET @sql = ''
EXEC(@sql);


	
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
