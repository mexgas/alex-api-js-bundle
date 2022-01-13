/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/01/13
Description:

Database: CCenterRia
Required version: 123.26

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
SET @version = 123 --**********actualizar a 123 sin fix
SET @versionfix = 27
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

	set @process = 'CW-6199 Add value to ccRiaLog_Operation'
    set @sql = 'IF NOT EXISTS(SELECT * FROM ccRiaLog_Operation WHERE operationType = 190) 
BEGIN
	insert into ccRIALog_Operation (operationType, descripcion) values (190, ''ACTUALIZAR ICONO|UPDATE ICON'')
END'
    EXEC(@sql)

    
	set @process = 'CW-6199 DROP PROCEDURE ccsp_GalateaUpdateVoiceConfiguration'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaUpdateVoiceConfiguration'')
            begin
				DROP PROCEDURE ccsp_GalateaUpdateVoiceConfiguration;
            end'
    EXEC(@sql)

    set @process = 'CW-6199 CREATE PROCEDURE ccsp_GalateaUpdateVoiceConfiguration'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaUpdateVoiceConfiguration]
	@inboundId				smallint,
	@frame					smallint	= null,
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
	DECLARE @graph_id smallint

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

	IF @frame IS NOT NULL
	BEGIN
		SELECT @graph_id = graphic_id from ccRIAGraphics where frame = @frame and [type_id] = 1
		UPDATE ccRIAInboundGraph set graphic_id = ISNULL(@graph_id, graphic_id) where inbound_id = @inboundId
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
		UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId;
	 END

	SELECT 1 [Result]
	RETURN(0);

	SET NOCOUNT OFF;
END'
    EXEC(@sql)
	
	set @process = 'CW-6199 DROP PROCEDURE ccsp_GalateaUpdateWhatsAppConfiguration'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaUpdateWhatsAppConfiguration'')
            begin
				DROP PROCEDURE ccsp_GalateaUpdateWhatsAppConfiguration;
            end'
    EXEC(@sql)

    set @process = 'CW-6199 CREATE PROCEDURE ccsp_GalateaUpdateWhatsAppConfiguration'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaUpdateWhatsAppConfiguration]
	@inboundId				smallint,
	@frame					smallint	= null,
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
	DECLARE @graph_id smallint

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

	IF @frame IS NOT NULL
	BEGIN
		SELECT @graph_id = graphic_id from ccRIAGraphics where frame = @frame and [type_id] = 1
		UPDATE ccRIAInboundGraph set graphic_id = ISNULL(@graph_id, graphic_id) where inbound_id = @inboundId
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

    
    set @process = 'AutoInicio DROP PROCEDURE ccsp_RIAADMAutoInicio'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAADMAutoInicio'')
            begin
				DROP PROCEDURE ccsp_RIAADMAutoInicio;
            end'
    EXEC(@sql)


    set @process = 'AutoInicio CREATE PROCEDURE ccsp_RIAADMAutoInicio'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAADMAutoInicio]
    @cam_id smallint,
    @AutoInicio bit = 0,
    @tipoRegistros  tinyint = 0,
    @delaCampana    int = 0,
    @condicion  tinyint = 0,
    @numero int = 0,
    @AutoInicioHora bit = 0,
    @hora   smalldatetime = ''01/01/1900'',
    @type tinyint,
    @tipoRegistros2 tinyint = NULL,
    @condicion2 tinyint = NULL,
    @numero2 int = NULL,
    @camps varchar(max) = NULL
AS

IF @Type = 1
begin
    select AutoInicio, tipoRegistros, delaCampana, condicion, numero, AutoInicioHora, hora, tipoRegistros2, condicion2, numero2
    from ccCampsAutoInicio
    where cam_id = @cam_id
end

IF @Type = 2
Begin
    UPDATE ccCampsAutoInicio SET AutoInicio= @AutoInicio, AutoInicioHora = @AutoInicioHora
    WHERE cam_id=@cam_id

    IF @AutoInicio = 1
    begin
        UPDATE ccCampsAutoInicio SET tipoRegistros = @tipoRegistros, delaCampana = @delaCampana, condicion = @condicion, numero = @numero,  tipoRegistros2 = @tipoRegistros2, condicion2 = @condicion2, numero2 = @numero2
        WHERE cam_id=@cam_id
    end

    IF @AutoInicioHora = 1
    begin
        UPDATE ccCampsAutoInicio SET hora = @hora
        WHERE cam_id=@cam_id
    end
end

IF @Type = 3
Begin
    Insert into ccCampsAutoInicio (cam_id, hora) values(@cam_id, getdate())
End

IF @Type = 4
Begin
    declare @Camps_Ids table (id int primary key not null)

    if @cam_id is null
        begin
        insert into @Camps_Ids
        select value from dbo.fn_RIASplitDelimited (@camps, '','')
        end
    else
        begin
        insert into @Camps_Ids
        select @cam_id
        end

    IF @AutoInicio = 1
    begin
        UPDATE ccCampsAutoInicio SET tipoRegistros = @tipoRegistros, delaCampana = @delaCampana, condicion = @condicion, numero = @numero,  tipoRegistros2 = @tipoRegistros2, condicion2 = @condicion2, numero2 = @numero2, AutoInicio=0
        WHERE cam_id in (select id from @Camps_Ids)

        select 1
    end

    IF @AutoInicioHora = 1
    begin
        UPDATE ccCampsAutoInicio SET hora = @hora, AutoInicioHora=0
        WHERE cam_id in (select id from @Camps_Ids)

        select 1
    end
end'
    EXEC(@sql)


    set @process = 'AutoInicio DROP PROCEDURE ccsp_OutGenerateAutoinicio'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_OutGenerateAutoinicio'')
            begin
                DROP PROCEDURE ccsp_OutGenerateAutoinicio;
            end'
    EXEC(@sql)


    set @process = 'AutoInicio CREATE PROCEDURE ccsp_OutGenerateAutoinicio'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_OutGenerateAutoinicio]
AS
set nocount on

declare @today smalldatetime
set @today = getdate()
declare @CampsToStart table (cam_id int)

/**************************/
/*** Iniciar la campaña ***/
/**************************/

--Actualiza ccCamps si es necesario iniciar una campaña
;with Camps as( 
--buscar las que se tienen que iniciar por hora
select ccCampsAutoInicio.cam_id from ccCampsAutoInicio
join ccCamps  on ccCamps.cam_id = ccCampsAutoInicio.cam_id
where AutoInicioHora = 1
and hora between dateadd( mi, -10, @today ) and dateadd( mi, 5, @today )
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas

union
--buscar las que se tienen que iniciar con base a otra campaña
select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is NULL
and condicion2 is NULL
and numero2 is NULL

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (       
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (       
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (       
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is NULL
and condicion2 is NULL
and numero2 is NULL

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (       
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (       
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (       
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (       
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (       
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (       
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is NULL
and condicion2 is NULL
and numero2 is NULL

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (       
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (       
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (       
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 0
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (       
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 0
and cai.tiporegistros2 is NULL
and condicion2 is NULL
and numero2 is NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (       
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 0
and cai.tiporegistros2 is NULL
and condicion2 is NULL
and numero2 is NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (       
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (       
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 0
and cai.tiporegistros2 is NULL
and condicion2 is NULL
and numero2 is NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (       
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 0
and cai.tiporegistros2 is NULL
and condicion2 is NULL
and numero2 is NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (       
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero2) --solo las que estan detendias, para iniciarlas

insert into @CampsToStart select cam_id from Camps
update ccCamps set cam_procesando = 1, cam_bNew = 3 where cam_id in(select cam_id from @CampsToStart)
update ccCampsAutoInicio set iniciada=GETDATE() where cam_id in(select cam_id from @CampsToStart)

declare @camps_ids varchar(max);
select @camps_ids = STUFF((SELECT '', '' + CAST(c.cam_id AS varchar) FROM @CampsToStart c FOR XML PATH ('''')),1,2,'''')

if(LEN(@camps_ids) > 0)
    exec ccsp_RIAADMAutoInicio @type=4,@cam_id=null,@AutoInicio=1,@AutoInicioHora=1,@hora=@today, @camps=@camps_ids

/**************************/
/*** Detener la campaña ***/
/**************************/

update ccCamps set cam_procesando = 0, cam_bNew = 0 where cam_id in(
select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (>)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) < cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) > cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (=)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) = cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (
    select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (
    select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
    from ccCampsNvosCB wt
    where wt.id = cai.delacampana) <> cai.numero2)

set nocount off'
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


