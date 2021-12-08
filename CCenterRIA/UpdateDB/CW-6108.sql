/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
Description:

Database: CCenterRia
Required version: 123.14

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
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 26
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


	set @process = 'CW-6052 DROP PROCEDURE ccsp_GalateaGetInboundConfiguration'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetInboundConfiguration'')
            begin
				DROP PROCEDURE ccsp_GalateaGetInboundConfiguration;
            end'
    EXEC(@sql)

    set @process = 'CW-6052 CREATE PROCEDURE ccsp_GalateaGetInboundConfiguration'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetInboundConfiguration]
	@command int,
	@inboundId int
AS
BEGIN
declare @mediaType tinyint

SET NOCOUNT ON;

if @command=0
begin
	select descripcion from ccInbound where Inbound_id = @inboundId
end
if @command=1	-- Voice campaign
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
	isnull(A.callerIdDesc, '''') [CallerIdDesc],
	isnull(A.startStopRecording,0) [StartStopRecording],
	case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyAgent  else cast(0 as bit) end [CallBackSurveyAgent],
	case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyClient else cast(0 as bit) end [CallBackSurveyClient],
	case when A.cam_id > 0  and C.callsBySurvey>0 then cast(1 as bit) else cast(0 as bit) end [IsRelationSurvey],
	isnull(A.editableDtmf,0) [EditableDtmf],
	isnull(A.addDataCallBackReminder,0) [AddDataCallBackReminder]
	from ccInbound A
	left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
	left join ccCamps C on C.cam_id=A.cam_id
	where A.Inbound_id=@inboundId
end
if @command=2	-- WhatsApp campaign
begin
	declare @numbers varchar(max)
	select @numbers=COALESCE(@numbers + '','', '''') + number from ccWhatsAppNumbers where inboundId = 0 and status = 1

	select i.Inbound_id [InboundId], i.descripcion [Description], i.chat [MediaType], i.Status, isnull(g.graphic_id,1) [Frame],
	ISNULL(c.conexionInfo,'''') [Number],
	ISNULL(@numbers,'''') [FreeNumbersStr],
	ISNULL(c.closeConversationTime, 0) [MaxAnswerTime],
	i.tNotas [tNotas],
	i.ExitWrapUpDisposition,
	i.ShowCalifWnd
	from ccInbound i left join ccRIAInboundGraph g on i.Inbound_id = g.Inbound_id
	left join contactMeanIn c on i.Inbound_id = c.inboundId and i.chat = 5 and c.meanContactTypeId = 5
	where i.Inbound_id=@inboundId
end
if @command=3	-- Email campaign
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
	C.connUser	[ConnUserName],
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
RETURN(0)
	
SET NOCOUNT OFF;    
END'
    EXEC(@sql)

	set @process = 'CW-6079 DROP PROCEDURE ccsp_RIALoadCamps'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIALoadCamps'')
            begin
				DROP PROCEDURE ccsp_RIALoadCamps;
            end'
    EXEC(@sql)

    set @process = 'CW-6079 CREATE PROCEDURE ccsp_RIALoadCamps'
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
	CAST(0 as tinyint) [MediaType]
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
    
	set @process = 'CW-6108 DROP PROCEDURE ccsp_GalateaUpdateVoiceConfiguration'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaUpdateVoiceConfiguration'')
            begin
				DROP PROCEDURE ccsp_GalateaUpdateVoiceConfiguration;
            end'
    EXEC(@sql)

    set @process = 'CW-6108 CREATE PROCEDURE ccsp_GalateaUpdateVoiceConfiguration'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaUpdateVoiceConfiguration]
	@inboundId				smallint,
	@description			varchar(50) = null,
	@mediaType				tinyint		= null,
	@status					smallint	= null,
	@tNotas					int			= null,
	@tMaxWaitCall			smallint	= null,
	@nMaxQue				smallint	= null,
	@tel_maxwait			varchar(15) = null,
	@tel_maxqueue			varchar(15) = null,
	@tel_outservice			varchar(15) = null,
	@tel_noct				varchar(15) = null,
	@showCalifWnd			bit			= null,
	@editableCallKey		bit			= null,
	@queuePosition			bit			= null,
	@tMaxQueueCallBack		smallint	= null,
	@stopRecording			bit			= null,
	@dialPrefixOverflow		varchar(10) = null,
	@callerIdDesc			varchar(15) = null,
	@startStopRecording		bit			= null,
	@callBackSurveyAgent	bit			= null,
	@callBackSurveyClient	bit			= null,
	@editableDtmf			bit			= null,
	@addDataCallBackReminder bit		= null

AS
BEGIN
	SET NOCOUNT ON;

	UPDATE ccInbound SET
		descripcion = ISNULL(@description, descripcion),
		chat = ISNULL(@mediaType, chat),
		Status = ISNULL(@status, Status),
		tNotas = ISNULL(@tNotas, tNotas),
		tMaxWaitCall = ISNULL(@tMaxWaitCall, tMaxWaitCall),
		nMaxQue = ISNULL(@nMaxQue, nMaxQue),
		tel_maxwait = ISNULL(@tel_maxwait, tel_maxwait),
		tel_maxqueue = ISNULL(@tel_maxqueue, tel_maxqueue),
		tel_outservice = ISNULL(@tel_outservice, tel_outservice),
		tel_noct = ISNULL(@tel_noct, tel_noct),
		bnocturno = CASE WHEN ISNULL(@tel_noct, 0) = ''0'' OR @tel_noct = '''' THEN ''0'' ELSE ''1'' END,
		editableCallKey = ISNULL(@editableCallKey, editableCallKey),
		queuePosition = ISNULL(@queuePosition, queuePosition),
		tMaxQueueCallBack = ISNULL(@tMaxQueueCallBack, tMaxQueueCallBack),
		stopRecording = ISNULL(@stopRecording, stopRecording),
		dialPrefixOverflow = ISNULL(@dialPrefixOverflow, dialPrefixOverflow),
		callerIdDesc = ISNULL(@callerIdDesc, callerIdDesc),
		startStopRecording = ISNULL(@startStopRecording, startStopRecording),
		callBackSurveyAgent = ISNULL(@callBackSurveyAgent, callBackSurveyAgent),
		callBackSurveyClient = ISNULL(@callBackSurveyClient, callBackSurveyClient),
		editableDtmf = ISNULL(@editableDtmf, editableDtmf),
		addDataCallBackReminder = ISNULL(@addDataCallBackReminder, addDataCallBackReminder)
	WHERE Inbound_id = @inboundId

	IF @showCalifWnd = 1
    BEGIN
		IF EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inboundId AND tipo = 0)
        BEGIN
			UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd)
            WHERE inbound_id = @inboundId
			SELECT 1 [Result]
			RETURN(0)
        END

        SELECT -1 [Result]
        RETURN(0)
     END
     ELSE
	 BEGIN
		UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId;
	 END

	SELECT 1 [Result]
	RETURN(0);

	SET NOCOUNT OFF;
END'
    EXEC(@sql)
	
	set @process = 'CW-6108 DROP PROCEDURE ccsp_GalateaUpdateWhatsAppConfiguration'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaUpdateWhatsAppConfiguration'')
            begin
				DROP PROCEDURE ccsp_GalateaUpdateWhatsAppConfiguration;
            end'
    EXEC(@sql)

    set @process = 'CW-6108 CREATE PROCEDURE ccsp_GalateaUpdateWhatsAppConfiguration'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaUpdateWhatsAppConfiguration]
	@inboundId				smallint,
	@description			varchar(50) = null,
	@mediaType				tinyint		= null,
	@status					smallint	= null,
	@number					varchar(400)= null,
	@maxAnswerTime			tinyint		= null,
	@tNotas					int			= null,
	@exitWrapUpDisposition	bit			= null,
	@showCalifWnd			bit			= null
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE ccInbound SET
		descripcion = ISNULL(@description, descripcion),
		chat = ISNULL(@mediaType, chat),
		Status = ISNULL(@status, Status),
		tNotas = ISNULL(@tNotas, tNotas),
		ExitWrapUpDisposition = ISNULL(@exitWrapUpDisposition, ExitWrapUpDisposition)
	WHERE Inbound_id = @inboundId

	DECLARE @descUpdate varchar(50)
	select @descUpdate = ISNULL(@description, descripcion) from ccInbound where Inbound_id =@inboundId

	IF NOT EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId=@inboundId) 
    BEGIN
        INSERT INTO contactMeanIn (meanContactTypeId, name, inboundId, isActive) 
		values (5, @descUpdate, @inboundId, (select status from ccInbound where Inbound_id=@inboundId));
    END

	 IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inboundId) 
     BEGIN
		UPDATE contactMeanIn set name=@descUpdate, conexionInfo=ISNULL(@number, conexionInfo), 
		closeConversationTime = ISNULL(@maxAnswerTime, closeConversationTime)   
		where inboundId = @inboundId;
     END

	IF @showCalifWnd = 1
    BEGIN
		IF EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inboundId AND tipo = 0)
        BEGIN
			UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd)
            WHERE inbound_id = @inboundId
			SELECT 1 [Result]
			RETURN(0)
        END

        SELECT -1 [Result]
        RETURN(0)
     END
     ELSE
	 BEGIN
		UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId;
	 END

	 SELECT 1 [Result]
	 RETURN(0)

	SET NOCOUNT OFF;
END'
    EXEC(@sql)
	
	set @process = 'CW-6108 Add values to ccRiaLog_Operation'
    set @sql = 'IF NOT EXISTS(SELECT * FROM ccRiaLog_Operation WHERE operationType = 183) 
BEGIN
	insert into ccRIALog_Operation (operationType, descripcion) values (183, ''APLICAR ENCUESTA (LLAMADAS FINALIZADAS POR EL AGENTE)|CONDUCT SURVEY (CALLS ENDED BY AGENT)'')
END
IF NOT EXISTS(SELECT * FROM ccRiaLog_Operation WHERE operationType = 184) 
BEGIN
	insert into ccRIALog_Operation (operationType, descripcion) values (184, ''APLICAR ENCUESTA REPROGRAMADA|CONDUCT CALLBACK SURVEY'')
END
IF NOT EXISTS(SELECT * FROM ccRiaLog_Operation WHERE operationType = 185) 
BEGIN
	insert into ccRIALog_Operation (operationType, descripcion) values (185, ''CALIFICAR CONVERSACION|DISPOSITION CONVERSATION'')
END
IF NOT EXISTS(SELECT * FROM ccRiaLog_Operation WHERE operationType = 186) 
BEGIN
	insert into ccRIALog_Operation (operationType, descripcion) values (186, ''DEVOLVER LLAMADA(REMINDER)|CALL BACK (REMINDER)'')
END
IF NOT EXISTS(SELECT * FROM ccRiaLog_Operation WHERE operationType = 187) 
BEGIN
	insert into ccRIALog_Operation (operationType, descripcion) values (187, ''TELEFONO ASOCIADO|ASSOCIATED PHONE NUMBER'')
END
IF NOT EXISTS(SELECT * FROM ccRiaLog_Operation WHERE operationType = 188) 
BEGIN
	insert into ccRIALog_Operation (operationType, descripcion) values (188, ''TIEMPO MAXIMO DE RESPUESTA|MAXIMUM ANSWER TIME'')
END
IF NOT EXISTS(SELECT * FROM ccRiaLog_Operation WHERE operationType = 189) 
BEGIN
	insert into ccRIALog_Operation (operationType, descripcion) values (189, ''FINALIZAR TIEMPO DE NOTAS AL CALIFICAR|EXIT WRAP-UP STATUS ON DISPOSITION'')
END'
    EXEC(@sql)


    set @process = ''
     set @sql = ''
    EXEC(@sql)
	
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


