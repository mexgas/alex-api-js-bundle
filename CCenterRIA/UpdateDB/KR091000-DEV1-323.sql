/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCenterRia
Required version: 125.33

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
SET @versionfix = 34
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

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

	---------------------------------------BEGIN KR091000 Setting grabar llamadas por campaña ---------------------------------------------------------

set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
    begin
    DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
    end'
EXEC(@sql)

SET @process = 'KR091000 Alter Column ccoCallsout.file_moved tinyint'
SET @sql = 'if exists (SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = ''ccoCallsout'' and COLUMN_NAME=''file_moved'' and DATA_TYPE=''bit''
)
begin
    alter table ccoCallsout alter column file_moved tinyint;
end'
EXEC(@sql)

SET @process = 'KR091000 Alter Column ccCallsIn.file_moved tinyint'
SET @sql = 'if exists (SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = ''ccCallsIn'' and COLUMN_NAME=''file_moved'' and DATA_TYPE=''bit''
)
begin
    alter table ccCallsIn alter column file_moved tinyint;
end'
EXEC(@sql)

set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
        begin
        ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
        end'
EXEC(@sql)

SET @process = 'KR091000 Alter SP getPrefixByAcdId Add parameter @phone'
SET @sql = 'ALTER procedure [dbo].[getPrefixByAcdId] 
@inboundId int,@phone varchar(50) = ''''
as
declare @prefijo varchar(40),@recordHold tinyint,@call_record as tinyint
declare @countryId as tinyint 

select @countryId = valor from ccsettings with(nolock) where setting_id = 104

select @prefijo= isnull(prefijo,''''),@recordHold= ISNULL(recordHold,0)  ,@call_record=ISNULL(B.RecordCalls,1)
from ccInbound A
left join ccInboundExtend B on A.Inbound_id=B.Inbound_id
where A.Inbound_id = @inboundId

select @prefijo prefijo,@recordHold recordHold ,dbo.EnableCallRecord(@call_record,@countryId,@phone)  callRecord
'
EXEC(@sql)

SET @process = 'KR091000 Alter FN EnableCallRecord Add @call_record_cam option 3 y 4'
SET @sql = 'ALTER function [dbo].[EnableCallRecord](@call_record_cam tinyint,@pais tinyint, @tel varchar(32))
RETURNS tinyint
AS  
BEGIN


if @call_record_cam = 1  begin
	return 1 -- grabar 
end

else if @call_record_cam=3  begin
	return 0 -- no grabar
end

declare @callRecordOri tinyint

set @callRecordOri=@call_record_cam

-- grabar zonas permitidas
if @pais=4 begin
	if len(@tel) = 10 begin
		select @call_record_cam = isnull(call_record,1)  from ccTimeZoneArea where id_country= @pais and area = left(@tel,3)		
	end
end
if @call_record_cam=0 begin
	if @callRecordOri=4 begin
		return @callRecordOri  --No Grabar pero puede cambiar a grabar desde el agente
	end	
end

return @call_record_cam
	
END'
EXEC(@sql)

SET @process = 'KR091000 ALTER SP ccspAgent_GetLastCalls @lastCallAgt--> PRIMARY KEY(id,tipo)'
SET @sql = 'ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
AS
SET NOCOUNT ON;
DECLARE @lastCallAgt TABLE(id           INT NOT NULL
						, tipo         VARCHAR(10) NOT NULL
						, Hora         DATETIME NOT NULL --VARCHAR(19) NOT NULL, 
						, Telefono     VARCHAR(55) NOT NULL
						, EspCamp      VARCHAR(55) NOT NULL
						, Calificacion VARCHAR(60)
						, Duracion     VARCHAR(10) NOT NULL
						, CallBack     DATETIME
						, cal_key      VARCHAR(40)
						, IDCampEsp    SMALLINT NOT NULL
						, prefijo      VARCHAR(255) NULL
						, GraphicID    INT
						, CamManualMode INT
						, SelectRotativeANI INT
						, PRIMARY KEY(id,tipo)
);

DECLARE @pais TINYINT;
DECLARE @maxHours SMALLINT;
DECLARE @topRows INT;
DECLARE @setting VARCHAR(6);
DECLARE @hidePhone BIT;
DECLARE @dateStart DATETIME;

SET @hidePhone = 1;

SELECT @setting = valor FROM ccSettings WHERE setting_id = 255;

SET @maxHours = CAST(SUBSTRING(@setting, 1, (SELECT PATINDEX(''%|%'', @setting)) - 1) AS SMALLINT);
SET @topRows = CAST(SUBSTRING(@setting, (SELECT PATINDEX(''%|%'', @setting)) + 1, LEN(@setting)) AS INT);

IF @maxHours = 0
BEGIN
	SELECT Id
		, tipo
		, (CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) AS Hora
		, Telefono
		, EspCamp
		, Calificacion
		, CallBack
		, Duracion
		, '''' AS CallBack
		, cal_key
		, IDCampEsp
		, prefijo
		, GraphicID
		, SelectRotativeANI
		, @hidePhone AS HidePhone FROM @lastCallAgt;

	RETURN 0;
END;

SELECT @pais = valor FROM ccSettings WHERE setting_id = 104;

SELECT @hidePhone = CASE WHEN valor = ''0''
					THEN 0 ELSE 1
					END FROM ccSettings WHERE setting_id = 223;

IF @topRows = 0
BEGIN
	SET @topRows = 10000;
END;

SET @dateStart = DATEADD(hh, -@maxHours, GETDATE());

WITH timeTransfer
	AS (SELECT cal_id
			, tipo
			, SUM(tAntesXfer) AS tAntesXfer
			, SUM(tDespuesXfer) AS tDespuesXfer FROM ccLogTransfers
		WHERE fechaFin > @dateStart
		GROUP BY cal_id
				, tipo)

	INSERT INTO @lastCallAgt
			---Insert OUT
			SELECT TOP (@topRows) c.cal_id AS id
								, ''OUT'' AS Tipo
								, cal_inicio
								, cal_telefono AS Telefono
								, cam_descripcion AS EspCamp
								, ISNULL(cal.Description, '''') AS Calificacion
								, CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
																						THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
																						END, 0), 114) AS Duracion
								, cal_fcallback AS CallBack
								, cal_key
								, c.cam_id AS IDCampEsp
								, ISNULL(ccCamps.prefijo, '''') Prefijo
								, graph.graphic_id GraphicID
								, cam_ModoManual as CamManualMode 
								, ISNULL(selectRotativeANI, 0) as SelectRotativeANI FROM ccoCallsOut c
																INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
																LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
																LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
																LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
																							AND t.tipo = 2
			WHERE user_id = @user_id
				AND cal_inicio > @dateStart
			UNION
			--- IN
			SELECT TOP (@topRows) c.cal_id AS id
								, ''IN'' AS Tipo
								, cal_inicio
								, cal_ani AS Telefono
								, descripcion AS EspCamp
								, ISNULL(cal.Description, '''') AS Calificacion
								, CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
																								THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
																								END, 0), 108) Duracion
								, NULL AS CallBack
								, cal_key
								, c.inbound_id AS IDCampEsp
								, ISNULL(ccInbound.prefijo, '''') Prefijo
								, graph.graphic_id GraphicID
								, '''' as CamManualMode 
								, 0 as SelectRotativeANI FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
																JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
																INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
																LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
																LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
																							AND t.tipo = 1
			WHERE user_id = @user_id
				AND cal_inicio > @dateStart;

SELECT Id
	, tipo
	, CASE WHEN @pais = 4
	THEN(CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) ELSE(CONVERT(VARCHAR(10), Hora, 103) + '' '' + CONVERT(VARCHAR(8), Hora, 14))
	END AS Hora
	, Telefono
	, EspCamp
	, Calificacion
	, ISNULL(CONVERT(VARCHAR(16), CallBack, 121), '''') AS CallBack
	, Duracion
	, CallBack
	, cal_key
	, IDCampEsp
	, prefijo
	, GraphicID
	, @hidePhone AS HidePhone 
	, CamManualMode 
	, SelectRotativeANI FROM @lastCallAgt
ORDER BY hora DESC;
SET NOCOUNT OFF;
		'
EXEC(@sql)

SET @process = 'KR091000 ALTER SP ccsp_LoadGraphics @realValue variable bit->int'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_LoadGraphics]
@Id as smallint,
@callType as smallint,
@UserId as smallint,
@phone varchar(50)=null
AS
BEGIN
		
	SET NOCOUNT ON	
	DECLARE @realValue int		
	exec @realValue= ccsp_AgentGetStartStopPermission @age_id=@UserId, @cam_id=@Id, @call_type=@callType,@phone=@phone
	
	if (@callType=1)
	begin
		DECLARE @canReprogram bit  
		create table #canReprogram (canReprogram bit)
		insert into #canReprogram
		exec ccsp_AgentGetCampReprogramData @Id, @callType
		select @canReprogram = canReprogram from #canReprogram
		drop table #canReprogram

		select a1.Inbound_id id, a2.descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey, 0 as leaveRecMessage ,
		case when isnull(a4.callsBySurvey,0) > 0 then 1 else 0 end isRelationSurvey ,
		isnull(a2.callBackSurveyAgent,1) callBackSurveyAgent,isnull(a2.callBackSurveyClient,1) callBackSurveyClient,
		a2.ShowCalifWnd as ShowDisposition,
		isnull(a2.startStopRecording,0) as StartStopRecording,
		@realValue as IsStartStopRecording,
		isnull(a2.editableDtmf, 0) as isEditDtmf,
		@canReprogram  CanReprogram
		from ccRIAInboundGraph a1 
		inner join ccInbound a2 on (a1.inbound_id=a2.inbound_id)
		 inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id) 
		 left join ccCamps a4 on a4.cam_id=a2.cam_id  where a1.inbound_id=@Id and type_id in(1,2,3) order by type_id		
	 end	
	 else
	 begin
		select a1.cam_id Id, a2.cam_descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey,
		case when msgFile <> '''' and leaveRecMessage = 1 then 1 else 0 end as leaveRecMessage, 
		case when isnull(a2.surveyCamId,0) >0 then 1 else 0 end isRelationSurvey ,
		a2.cam_ShowCalifWnd as ShowDisposition,
		a2.callBackSurveyAgent,a2.callBackSurveyClient,
		isnull(a2.startStopRecording,0) as StartStopRecording,
		@realValue as IsStartStopRecording
		from ccRIACampsGraph a1 
		inner join ccCamps a2 on (a1.cam_id=a2.cam_id)
		inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id)
		left outer join (select top 1 M.cam_id, coalesce(msgFile+'''','''','''') as msgFile 
		from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id 
		where M.cam_id = @Id and type = 8) b 
		on (a2.cam_id = b.cam_id) 
		where a1.cam_id=@Id and type_id in(1,2,3) order by type_id
	 end	
END
'
EXEC(@sql)

SET @process = 'KR091000 ALTER SP ccsp_DLRgetDialPrefix variable @call_record_cam bit->tinyint'
SET @sql = 'ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]
@cam_id smallint=0,
@iPortNumber smallint = 0,
@phone varchar(30) = '''',
@callout_id int = 0
as
declare @prefix as varchar(15), @sipheader varchar(500)
declare @ani as varchar(32)
declare @call_record_cam as tinyint
declare @pais as tinyint 
declare @aniglobal varchar(32), @sipHdrFormat varchar(255)
declare @ivr_script smallint, @surveycamid int
declare @call_record tinyint, @tNoContesta tinyint, @detectAnswerMachine smallint, @detectVoiceMail tinyint
declare @PrefixRec varchar(40)
declare @carrier varchar(255)
declare @recordHold bit

select @pais = valor from ccsettings with(nolock) where setting_id = 104
select @call_record_cam = call_record from ccCamps where cam_id = @cam_id
select @aniglobal = valor from ccsettings with(nolock) where setting_id = 177

set @prefix =''''
-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )

-- Prefijo por campaña,
if @prefix =''''
	select @prefix = dialPrefixMan from ccCamps where cam_id = @cam_id

-- Prefijo general
if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 2 = 2)
	select @prefix = valor from ccsettings with(nolock) where setting_id =101

-- Ani
set @ani = dbo.TelAni(@phone, (select id_anilist from ccCamps where cam_id =@cam_id) )

--AnswerMachine Message Files
DECLARE @MsgFiles VARCHAR(8000) 
SELECT @MsgFiles = COALESCE(@MsgFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 8 ORDER BY orden

--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000) 
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

select @surveycamid = 0, @ivr_script = 0

select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta = cam_tNoContesta, @ani = case when @ani = '''' then ani else @ani end
,@detectAnswerMachine = detectAnswerMachine, @detectVoiceMail = detectVoiceMail
,@call_record = dbo.EnableCallRecord(@call_record_cam,@pais,@phone), @surveycamid = isnull(surveycamid,0), @recordHold=ISNULL(recordHold,0)
from ccCamps where cam_id = @cam_id

SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)

if @surveycamid > 0
	select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid


if @ani = '''' begin 
set @ani = @aniglobal 
end 

 select @PrefixRec=ISNULL(prefijo,'''') from ccCamps where cam_id = @cam_id

 set @carrier = ''''
 select @carrier = dbo.GetCarrierByTel(@phone)

select @prefix as sDialPrefix, @tNoContesta as tNoContesta,@ani as ani, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail,
@call_record as call_record, isnull(@MsgFiles,'''') as messageFiles, isnull(@MohFiles,'''') as mohFiles, @ivr_script ivrScript, @sipheader data
,@PrefixRec PrefijoRec, @carrier Carrier, @recordHold recordHold'
EXEC(@sql)

SET @process = 'KR091000 ALTER SP ccsp_AvrsSyncronization change column isCallRecord convert(bit, case when isnull(calls.file_moved,1)=2 then 0 else 1 end)  AS isCallRecord'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AvrsSyncronization] @action SMALLINT, @maxRecordsToTransfer INT = 10, @id INT = 0
AS
SET NOCOUNT ON

IF @action = 1
BEGIN
	DECLARE @countrId INT

	SET @countrId = 1

	SELECT @countrId = valor
	FROM ccSettings
	WHERE setting_id = 104;

	WITH callsIn
	AS (
		SELECT TOP (@maxRecordsToTransfer) 
		calls.cal_id, user_id, calls.Inbound_id, calls.calif_id 
		, cast(cal_extension AS INT) AS cal_extension, cal_inicio, cal_ANI AS phone
		, isnull(cal_tDialog - cal_tMoh, 0) + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration
		, cal_key, 0 AS cal_manual, cal_puerto
		, calls.dni_id, fvalida, cal_whohung
		, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id
		, CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh
		, dateadd(ss, isnull(cal_tDialog, 0), cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, ccInbound.prefijo
		
		, convert(bit, case when isnull(calls.file_moved,1)=2 then 0 else 1 end)  AS isCallRecord
		, isnull(dni.dni_numero, '''') AS DNIS, dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG
		
		FROM ccCallsIn  AS  calls 	with(nolock)
		INNER JOIN ccInbound ON ccInbound.Inbound_id = calls.Inbound_id
		INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id	AND avrs.tipo = 0
		LEFT JOIN ccDNIS dni ON dni.dni_id = calls.dni_id
		left join ccInboundExtend inbExt on inbExt.Inbound_id=calls.Inbound_id
		LEFT JOIN (
			SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
			FROM ccLogTransfers
			WHERE tipo = 1
			GROUP BY cal_id, tipo
			) trans ON calls.cal_id = trans.cal_id
		WHERE calls.User_id > 0
		), callsOut
	AS (
		SELECT TOP (@maxRecordsToTransfer) 
		calls.cal_id AS CallId, user_id AS UserId, calls.cam_id AS camAcdId
		, cast(calls.calif_id AS SMALLINT) AS califId, cast(cal_extension AS INT) AS extension, cal_inicio, cal_telefono
		, isnull(cal_tDialog - cal_tMoh, 0) + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration
		, cal_key, cal_manual, cal_puerto, 0 AS dni_id, fvalida, cal_whohung
		, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id
		, CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh
		, dateadd(ss, isnull(cal_tDialog, 0), cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, camps.prefijo
		
		, convert(bit, case when isnull(calls.file_moved,1)=2 then 0 else 1 end)  AS isCallRecord
		, '''' AS DNIS, dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG
		FROM ccoCallsOut AS calls with(nolock)
		INNER JOIN ccCamps camps ON camps.cam_id = calls.cam_id
		INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 1
		LEFT JOIN (
			SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
			FROM ccLogTransfers
			WHERE tipo = 2
			GROUP BY cal_id, tipo
			) trans ON calls.cal_id = trans.cal_id
		WHERE calls.User_id > 0
		)

		select * from callsIn
		union 
		select * from callsOut
		
END
ELSE IF @action = 2
BEGIN
	DELETE
	FROM ccAVRSTransfer
	WHERE id = @id
END
'
EXEC(@sql)

SET @process = 'KR091000 ALTER SP ccsp_AgentGetStartStopPermission change statement->return and validate value @callrecord'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentGetStartStopPermission]
@age_id int,
@cam_id int,
@call_type int,
@phone varchar(50)=null
AS
BEGIN
	SET NOCOUNT ON;

	declare @agentRec int, @valor as int
	declare @callrecord tinyint
	set @valor = 0
	select @agentRec=isnull(startStopRecording,0) from ccusers (nolock) where [User_id] = @age_id
	
	IF @agentRec = 1
	BEGIN
		
		---------- Entra agente con permiso de StartStopRecording
		IF @call_type = 1 ------- Revisamos camp In
			select @valor=isnull(startStopRecording,0),@callrecord=ISNULL(B.RecordCalls,1) from ccInbound  A (nolock) 
			left join ccInboundExtend B on A.Inbound_id=B.Inbound_id
			where A.Inbound_id = @cam_id
		ELSE ------- Revisamos Camp Out
			select @valor=isnull(startStopRecording,0),@callrecord=ISNULL(call_record,1) from ccCamps (nolock) where cam_id = @cam_id		

		if @valor=0 begin
			return 0 --Permiso desactivo antes
		end
		declare @countryId as tinyint 
		select @countryId = valor from ccsettings with(nolock) where setting_id = 104

		set @callrecord=dbo.EnableCallRecord(@callrecord,@countryId,@phone)
				
		return @callrecord
	END	
	return 0
END'
EXEC(@sql)

SET @process = 'KR091000 ALTER SP'
SET @sql = ''
EXEC(@sql)

SET @process = 'KR091000 ALTER SP'
SET @sql = ''
EXEC(@sql)

SET @process = 'KR091000 ALTER SP'
SET @sql = ''
EXEC(@sql)

SET @process = 'KR091000 ALTER SP'
SET @sql = ''
EXEC(@sql)

SET @process = 'KR091000 ALTER SP'
SET @sql = ''
EXEC(@sql)

SET @process = 'KR091000 ALTER SP'
SET @sql = ''
EXEC(@sql)


---------------------------------------END KR091000 Setting grabar llamadas por campaña ---------------------------------------------------------
		/* End script release */		/* Upgrade database version (first and the last number of setting 77) */
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
