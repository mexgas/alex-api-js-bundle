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

	--------------------------------------------------------------------------------------------------

	SET @process = 'K007000 Insert New Modules and Operations'
	SET @sql = '
IF NOT EXISTS(SELECT * FROM ccGalateaModules WHERE ModuleId = 6) INSERT INTO ccGalateaModules (ModuleId, MTagEs, MTagEn, MTagPt) VALUES (6, ''Horarios'', ''Schedules'', ''Horários'');
IF NOT EXISTS(SELECT * FROM ccGalateaModules WHERE ModuleId = 7) INSERT INTO ccGalateaModules (ModuleId, MTagEs, MTagEn, MTagPt) VALUES (7, ''Calificaciones'', ''Dispositions'', ''Classificações'');

IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 63) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (63, ''Crear campaña (chat)'', ''Create campaign (chat)'', ''Criar campanha (chat)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 63);
END

IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 64) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (64, ''Editar campaña (chat)'', ''Edit campaign (chat)'', ''Editar campanha (chat)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 64);
	INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (5, 64);
END

IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 65) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (65, ''Eliminar campaña (chat)'', ''Delete campaign (chat)'', ''Excluir campanha (chat)'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 65);
END

IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 66) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (66, ''Asignar horario'', ''Assign schedule'', ''Atribuir horário'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (6, 66);
END

IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 67) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (67, ''Desasignar horario'', ''Unassign schedule'', ''Cancelar atribuição de horário'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (6, 67);
END

IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 68) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (68, ''Asignar calificación de entrada'', ''Assign inbound disposition'', ''Atribuir classificação de entrada'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (7, 68);
END

IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 69) BEGIN 
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (69, ''Desasignar calificación de entrada'', ''Unassign inbound disposition'', ''Cancelar atribuição de classificação de entrada'');
    INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (7, 69)
END'
	EXEC(@sql)

	SET @process = 'K007000 Insert Identifiers'
	SET @sql = '
IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&CHAT_MAX_ANSWER_TIME'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&CHAT_MAX_ANSWER_TIME'', ''Tiempo máximo de respuesta'', ''Maximum answer time'', ''Tempo máximo de resposta'')

IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&CHAT_DOMAIN'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&CHAT_DOMAIN'', ''Dominio'', ''Domain'', ''Domínio'')

IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&CHAT_MAX_WAIT_TIME'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&CHAT_MAX_WAIT_TIME'', ''Tiempo máximo de espera'', ''Maximum wait time'', ''Tempo máximo de espera'')

IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''T&CHAT_MAX_CONVERSATIONS_IN_QUEUE'') INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&CHAT_MAX_CONVERSATIONS_IN_QUEUE'', ''Número máximo en espera'', ''Maximum conversations in queue'', ''Número máximo na fila'')
'
	EXEC(@sql)

	SET @process = 'K007000 Insert relationTableColumnIdentifiers'
	SET @sql = '
IF NOT EXISTS (SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''T&CHAT_MAX_ANSWER_TIME'') INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) VALUES (''T&CHAT_MAX_ANSWER_TIME'', ''ccInbound'', ''inactiveChatTime'')
IF NOT EXISTS (SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''T&CHAT_DOMAIN'') INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) VALUES (''T&CHAT_DOMAIN'', ''ccInbound'', ''chatDomain'')
IF NOT EXISTS (SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''T&CHAT_MAX_WAIT_TIME'') INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) VALUES (''T&CHAT_MAX_WAIT_TIME'', ''ccInbound'', ''chatTimeOverflow'')
IF NOT EXISTS (SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''T&CHAT_MAX_CONVERSATIONS_IN_QUEUE'') INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) VALUES (''T&CHAT_MAX_CONVERSATIONS_IN_QUEUE'', ''ccInbound'', ''chatQueueOverflow'')
'
	EXEC(@sql)

	SET @process = 'K007000 Alter sp ccsp_GalateacampaingManager'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateacampaingManager] 
@option           SMALLINT, 
@Activa           SMALLINT     = NULL, 
@Descripcion      VARCHAR(40) = '''', 
@IDArea           SMALLINT, 
@MirrorInbound_Id SMALLINT    = NULL, 
@frame            SMALLINT, 
@Prefijo          VARCHAR(40) = '''', 
@Type             SMALLINT, 
@userId           SMALLINT, 
@moduleId         SMALLINT    = 49,
@MediaType        SMALLINT,
@chatDomain		  VARCHAR(500) = null
AS
BEGIN
IF(@option = 2)
BEGIN

    IF OBJECT_ID(''tempdb..#Campaing'') IS NOT NULL DROP TABLE #Campaing
    CREATE TABLE #Campaing(IdCampaing INT)

    IF @type = 1
    BEGIN
        INSERT INTO #Campaing
        EXEC ccsp_RIA_ABCCamps 
                @option = @option, 
                @Descripcion = @Descripcion, 
                @Cam_id = ''0'', 
                @Activa = 1, 
                @IDArea = @IDArea, 
                @frame = @frame, 
                @Prefijo = @Prefijo,
                @UserId = @userId,
                @MediaType = @MediaType
    END
    ELSE
    IF @type = 0
    BEGIN
        INSERT INTO #Campaing
        EXEC ccsp_RIA_ABCACDGroups 
                @option = @option, 
                @descripcion = @Descripcion, 
                @inbound_id = ''0'', 
                @idarea = @IDArea, 
                @frame = @frame, 
                @Prefijo = @Prefijo,
                @userid = @userId,
                @MediaType = @MediaType,
				@chatDomain = @chatDomain
    END

    IF((SELECT TOP 1 IdCampaing FROM #Campaing ) > 0)
    BEGIN
        INSERT INTO ccRIALog
        VALUES(
        (SELECT AreaName FROM ccRIACat_Areas WHERE IDArea = @IDArea), 
        GETDATE(),
        CASE
            WHEN @type = 1
            THEN 25
            ELSE 26
        END, 
        (SELECT Login FROM ccUsers WHERE User_Id = @userId), 
        @moduleId, 
        '''', 
        @Descripcion)
    END

    SELECT TOP 1 IdCampaing FROM #Campaing
    IF OBJECT_ID(''tempdb..#Campaing'') IS NOT NULL DROP TABLE #Campaing
END
END'
	EXEC(@sql)

	SET @process = 'K007000 Alter sp ccsp_RIA_ABCACDGroups'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCACDGroups]
@option smallint,
@userid int,
@descripcion varchar(40),
@inbound_id varchar(1000),
@idarea smallint = null,
@frame tinyint,
@Prefijo varchar(40) = null,
@MediaType int = 0,
@chatDomain varchar(500) = null
AS
SET NOCOUNT ON

declare @new_inbound_id smallint, @graph_id smallint

if @option = 0 -- all acd
 begin
     select acd.inbound_id, acd.descripcion, isnull(acd.idarea,0) as idarea,
    isnull(areas.areaname,'''') as areaname
     from ccinbound as acd with(nolock)
     left join dbo.ccriacat_areas as areas with(nolock) on acd.idarea = areas.idarea
     return(0)
 end

if @option = 1 -- select acd
 begin
     select a1.inbound_id, a1.descripcion, a3.frame, a1.showcalifwnd, a1.starttimeronhangup, isnull(a1.idarea,0), isnull(a1.cam_id,0) cam_id,
     prefijo as Prefijo
     from ccinbound a1 
      inner join ccriainboundgraph a2 on (a1.inbound_id=a2.inbound_id)
      inner join ccriagraphics a3 on (a2.graphic_id=a3.graphic_id)
     where a3.type_id = 1 and a1.inbound_id = (cast(@inbound_id as int))
     order by descripcion
     return(0)
 end

if @option = 2 -- insert
 begin
 
    if exists (select descripcion from ccinbound where descripcion = @descripcion and status = 1)
    begin
        select -1	-- ''Nombre en uso''
        return(0)
    end
	
	if (@MediaType = 1 and @chatDomain <> '''' and @chatDomain is not null)
	begin
		if exists (select 1 from ccInbound where chatDomain = @chatDomain and Status = 1)
		begin
			select -3	-- ''Domain in use''
			return(0)
		end
	end
    
    if @idarea = 0
		set @idarea = null

    declare @pref int
    select  @pref = valor from ccSettings where setting_id = 201
    if (@pref = 0)
        set @Prefijo = ''''
    
    DECLARE @tempDesc VARCHAR(40);
    SET @tempDesc = CASE WHEN @MediaType = 5 THEN @descripcion ELSE @descripcion+''Tmp'' END;

    insert into ccinbound (descripcion, starttimeronhangup, idarea, showcalifwnd,prefijo)
    select @tempDesc, 1, @idarea,case when exists(select calif_id from cctipocalif where Calif_Status = 1) then 1 else 0 end, @Prefijo
    
    if @@rowcount = 1
        select @new_inbound_id = inbound_id from ccinbound where descripcion = @tempDesc and status = 1
    else
    begin
		select -2 -- Error al insertar
        return(0)
    end

    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @new_inbound_id, @userId= @userid

    UPDATE ccInbound SET descripcion = @descripcion, ShowCalifWnd = case when exists(select calif_id from cctipocalif where Calif_Status = 1) then 1 else 0 end
    WHERE Inbound_id = @new_inbound_id

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    Create table #ccInboundTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )

    EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @new_inbound_id, @userId = @userid, @tableTemp=''#ccInboundTable'';  
    
    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        CASE 
			WHEN @MediaType = 5 THEN 40
			WHEN @MediaType = 1 THEN 63
			ELSE 60 END, 
        3, 
        CASE WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
                CASE WHEN @MediaType = 5 THEN ''IN_SHOW_DISPOSITIONS_WHATS'' ELSE  CCIT.identifierInfo END
             WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN ''''
        ELSE
            CCIT.identifierInfo
        END,
        CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
            CASE 
                WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN ''''
                ELSE CCIT.dataInfo END
        ELSE '''' END, 
        (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @new_inbound_id)
    FROM #ccInboundTable AS CCIT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @new_inbound_id, @userId = @userid;

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    insert into cccalifcamp (calif_id, cam_id, tipo) select calif_id, @new_inbound_id, 0 from cctipocalif where CanReprogram=0 and Calif_Status = 1

    if not exists (select msg_id from ccInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccMsgFiles where msgFile like ''%\Default%''))
    begin
		insert into ccInboundMsgs (msg_id, inbound_id, orden, type, queue)
		select msg_id, @new_inbound_id, 0, cast(substring(msgFile, 19,3) as integer),0 from ccMsgFiles where msgFile like ''%\Default%''
    end

    if not exists (select msg_id from ccRIAChatInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccRIAChatMsg where Descripcion like ''%\Default%''))
    begin
        insert into ccRIAChatInboundMsgs (msg_id, inbound_id, orden, type)
        select msg_id, @new_inbound_id, 0, cast(substring(Descripcion, 19,3) as integer) from ccRIAChatMsg where Descripcion like ''%\Default%''
    end

    if not exists(select frame from ccriagraphics where frame = @frame and type_id = 1)
		insert into ccriagraphics (frame,type_id) values (@frame,1)
    
    select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
     
    insert into ccriainboundgraph(Inbound_id,graphic_id) values(@new_inbound_id,@graph_id)
    select @new_inbound_id
    return(0) 
 end

if @option = 3 -- update
 begin
     if not exists (select frame from ccriagraphics where frame=@frame and type_id=1)
        insert into ccriagraphics (frame, type_id) values (@frame, 1)

     select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
     update ccinbound set descripcion = @descripcion where inbound_id = (cast(@inbound_id as int))
     update ccriainboundgraph set graphic_id = @graph_id where inbound_id = (cast(@inbound_id as int))
     return(0)
 end

if @option = 4 -- delete
 begin
     delete cccalifcamp where cam_id = @inbound_id and tipo = 0
     delete ccinboundhorarios where inbound_id = @inbound_id
     delete ccriainboundgraph where inbound_id = @inbound_id
     delete ccInboundMsgs where inbound_id = @inbound_id
     delete ccRIAChatInboundMsgs where inbound_id = @inbound_id
     delete ccinbound where inbound_id = @inbound_id
     return(0)
 end

if @option = 5 -- asignar campaña a ACD
 begin
    if not exists (select inbound_id from ccInbound where inbound_id=@inbound_id) or
     (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
        not exists (select cam_id from ccCamps where cam_id=@descripcion))
     begin
        select -3 -- Campaña o ACD invalido
        return(0)
     end
    
    if @descripcion=0 begin

        set @descripcion = null
        --quitamos calificaciones relacionadas a la campaña
        DELETE c FROM ccCalifCamp c
        INNER JOIN ccTipoCalif ci ON  ci.calif_id=c.calif_id
        Where c.cam_id=@inbound_id and ci.CanReprogram =1
        --quitamos subcalificaciones relacionadas a la calificacion
        DELETE rel FROM ccCalifCamp c
        INNER JOIN ccTipoCalif ci ON  ci.calif_id=c.calif_id and tipo=0
        inner join cctipoSubCalifRel rel on rel.calif_id=ci.calif_id and rel.tipoSubRel=1
        left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
        Where c.cam_id=@inbound_id and sb.canReprogram=1
                
    end
    
    update ccInbound set cam_id = @descripcion where Inbound_id = @inbound_id
        
    if @@rowcount=0
        select -4 -- Error al actualizar

    return(0)
 end
set nocount off
'
	EXEC(@sql)
	
	SET @process = 'K007000 Alter sp ccsp_RIAUpdateEspecConfig'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateEspecConfig] 
	@inbound_id              SMALLINT, 
    @descripcion             VARCHAR(50)  = NULL, 
    @Status                  TINYINT      = NULL, 
    @tNotas                  INT          = NULL, 
    @tMaxWaitCall            INT          = NULL, 
    @nMaxQue                 INT          = NULL, 
    @tel_maxwait             VARCHAR(15)  = NULL, 
    @tel_MaxQueue            VARCHAR(15)  = NULL, 
    @tel_outservice          VARCHAR(15)  = NULL, 
    @tel_noct                VARCHAR(15)  = NULL, 
    @ShowCalifWnd            BIT          = NULL, 
    @StartTimerOnHangUp      BIT          = NULL, 
    @editableCallKey         BIT          = NULL, 
    @queuePosition           BIT          = NULL, 
    @tMaxQueueCallBack       SMALLINT     = NULL, 
    @stopRecording           BIT          = NULL, 
    @dialPrefixOverflow      VARCHAR(10)  = NULL, 
    @OpriorityT              SMALLINT     = NULL, 
    @callerIdDesc            VARCHAR(15)  = NULL, 
    @chat                    TINYINT      = NULL, 
    @inactiveChatTime        SMALLINT     = NULL, 
    @maxChats                TINYINT      = NULL, 
    @chatDomain              VARCHAR(MAX) = NULL, 
    @chatQueue               SMALLINT     = NULL, 
    @chatTime                SMALLINT     = NULL, 
    @dRestrictPlay           BIT          = NULL, 
    @callBackSurveyAgent     BIT          = NULL, 
    @callBackSurveyClient    BIT          = NULL, 
    @agts_notavailable       VARCHAR(15)  = NULL, 
    @editableDtmf            BIT          = NULL, 
    @prefijo                 VARCHAR(MAX) = NULL, 
    @addDataCallBackReminder BIT          = NULL,
    @recordHold              BIT          = NULL,
    @userId                  SMALLINT     = NULL, 
    @idArea                  SMALLINT     = NULL, 
    @isCreating              BIT          = NULL
AS
SET NOCOUNT ON;

declare @domainInUse bit = 0
declare @returnValue int = 2

EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inbound_id, @userId= @userid

UPDATE ccInbound
SET 
    descripcion = ISNULL(@descripcion, descripcion), 
    STATUS = ISNULL(@status, STATUS), 
    tNotas = ISNULL(CASE WHEN @chat <> 5 THEN @tNotas ELSE 10 END, tNotas), 
    tMaxWaitCall = ISNULL(@tMaxWaitCall, tMaxWaitCall), 
    nMaxQue = ISNULL(@nMaxQue, nMaxQue), 
    tel_maxwait = ISNULL(@tel_maxwait, tel_maxwait), 
    tel_MaxQueue = ISNULL(@tel_MaxQueue, tel_MaxQueue), 
    tel_outservice = ISNULL(@tel_outservice, tel_outservice), 
    tel_noct = ISNULL(@tel_noct, tel_noct), 
    bnocturno = CASE
                    WHEN ISNULL(@tel_noct, 0) = ''0''
                        OR @tel_noct = ''''
                    THEN ''0''
                    ELSE ''1''
                END, 
    StartTimerOnHangUp = ISNULL(@StartTimerOnHangUp, StartTimerOnHangUp), 
    editableCallKey = ISNULL(@editableCallKey, editableCallKey), 
    queuePosition = ISNULL(@queuePosition, queuePosition), 
    tMaxQueueCallBack = ISNULL(@tMaxQueueCallBack, tMaxQueueCallBack), 
    stopRecording = ISNULL(@stopRecording, stopRecording), 
    dialPrefixOverflow = ISNULL(@dialPrefixOverflow, dialPrefixOverflow), 
    OpriorityT = ISNULL(@OpriorityT, OpriorityT), 
    callerIdDesc = ISNULL(@callerIdDesc, callerIdDesc), 
    chat = ISNULL(@chat, chat), 
    inactiveChatTime = ISNULL(@inactiveChatTime, inactiveChatTime), 
    maxChats = ISNULL(@maxChats, maxChats), 
    chatQueueOverflow = ISNULL(@chatQueue, ISNULL(chatQueueOverflow, 15)), 
    chatTimeOverflow = ISNULL(@chatTime, ISNULL(chatTimeOverflow, 300)), 
    startStopRecording = ISNULL(@dRestrictPlay, startStopRecording), 
    callBackSurveyAgent = ISNULL(@callBackSurveyAgent, callBackSurveyAgent), 
    callBackSurveyClient = ISNULL(@callBackSurveyClient, callBackSurveyClient), 
    agts_notavailable = ISNULL(@agts_notavailable, agts_notavailable), 
    editableDtmf = ISNULL(@editableDtmf, editableDtmf), 
    prefijo = ISNULL(@prefijo, prefijo), 
    addDataCallBackReminder = ISNULL(@addDataCallBackReminder, addDataCallBackReminder),
    recordHold = ISNULL(@recordHold, recordHold)
WHERE inbound_id = @inbound_id;


IF NOT EXISTS (SELECT inbound_id FROM ccinbound WHERE inbound_id <> @inbound_id AND chatDomain = @chatDomain AND chatDomain <> '''')
BEGIN
	IF @chatDomain IS NOT NULL
	BEGIN
		UPDATE ccinbound SET chatDomain = @chatDomain WHERE inbound_id = @inbound_id
	END
END
ELSE
BEGIN
	UPDATE ccinbound SET chatDomain = '''' WHERE inbound_id = @inbound_id
	set @domainInUse = 1
END


IF @ShowCalifWnd = 1
BEGIN
	IF EXISTS (SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inbound_id AND tipo = 0)
	BEGIN
		UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inbound_id;
		SET @returnValue = 1
	END
	ELSE
	BEGIN
		SET @returnValue = 0
	END
END;
ELSE
	UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inbound_id;



IF(@chat <> 5) 
BEGIN
	IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable
	Create table #ccInboundTable 
	(
		columnInfo VARCHAR(255),
		dataInfo VARCHAR(255),
		identifierInfo VARCHAR(255)
	)
    
	IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid, @tableTemp=''#ccInboundTable'';

	DELETE FROM #ccInboundTable WHERE columnInfo IN (''bnocturno'');

	INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
	SELECT 
		(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
		getDate(), 
		(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
		CASE
			WHEN @chat = 1 THEN 63
			ELSE 60 END,
		3, 
		CCIT.identifierInfo,
		CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
			CASE 
				WHEN CCIT.identifierInfo IN (''IN_DESTINATION_WAIT_TIME'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
					CASE WHEN CCIT.dataInfo = ''VOICEMAIL'' 
						THEN ''COMMON_VOICE_MAIL'' 
						ELSE 
							CASE WHEN CCIT.dataInfo IS NOT NULL THEN CCIT.dataInfo ELSE ''T&COMMON_NONE'' END 
						END
				WHEN CCIT.identifierInfo IN (''IN_RECORD_ON_HOLD'',''IN_PLAY_QUEUE_ORDER'', ''IN_STOP_RECORDING'', ''IN_SHOW_DISPOSITIONS'', ''IN_CALL_KEY'', ''IN_CONDUCT_CALLBACK_SURVEY'', ''IN_RECEIVE_DTMF_TONES'', ''IN_CALL_BACK'') THEN
					CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
				WHEN CCIT.identifierInfo = ''IN_CONDUCT_SURVEY'' THEN
					CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
				ELSE CCIT.dataInfo END
		ELSE '''' END, 
		(SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inbound_id)
	FROM #ccInboundTable AS CCIT;

	EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid;

	IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable
END

IF @chat = 5 
BEGIN
    IF NOT EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
    BEGIN
        INSERT INTO contactMeanIn (meanContactTypeId, name, inboundId, isActive) values (@chat, @descripcion, @inbound_id, (select status from ccInbound where Inbound_id = @inbound_id));

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        VALUES (
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            40, 
            3,'''','''', 
            @descripcion);
    END
END;

if (@domainInUse = 1)
BEGIN
	RAISERROR(''Domain already in another ACD Group'', 15, 4)
END

if(@returnValue <> 2)
	SELECT @returnValue
ELSE
	SELECT 2
RETURN(0)

SET NOCOUNT OFF'
	EXEC(@sql)
	
	SET @process = 'K007000 Alter sp ccsp_GalateaGetInboundConfiguration'
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
	isnull(A.callerIdDesc, '''') [CallerIdDesc],
	isnull(A.startStopRecording,0) [StartStopRecording],
	case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyAgent  else cast(0 as bit) end [CallBackSurveyAgent],
	case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyClient else cast(0 as bit) end [CallBackSurveyClient],
	case when A.cam_id > 0  and C.callsBySurvey>0 then cast(1 as bit) else cast(0 as bit) end [IsRelationSurvey],
	isnull(A.editableDtmf,0) [EditableDtmf],
	isnull(A.addDataCallBackReminder,0) [AddDataCallBackReminder],
	isnull(A.recordHold, 0) [RecordHold]
	from ccInbound A
	left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
	left join ccCamps C on C.cam_id=A.cam_id
	where A.Inbound_id=@inboundId
end
if @command=2 -- WhatsApp campaign
begin
	declare @numbers varchar(max)
	select @numbers=COALESCE(@numbers + '','', '''') + number from ccWhatsAppNumbers where inboundId = 0 and status = 1

	select i.Inbound_id [InboundId], i.descripcion [Description], i.chat [MediaType], i.Status, isnull(g.graphic_id,1) [Frame],
	ISNULL(c.conexionInfo,'''') [Number],
	ISNULL(@numbers,'''') [FreeNumbersStr],
	ISNULL(c.closeConversationTime, 0) [MaxAnswerTime],
	ISNULL(c.answerTimeoutClient, 30) [MUTimeOutClient],
	ISNULL(c.allowFileAttachments, 0) [AllowFileAttachments],
	i.tNotas [tNotas],
	i.ExitWrapUpDisposition,
	i.ShowCalifWnd
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
	EXEC(@sql)
	
	SET @process = 'K007000 Drop procedure ccsp_GalateaUpdateChatConfiguration'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaUpdateChatConfiguration'')
		BEGIN
			DROP PROCEDURE ccsp_GalateaUpdateChatConfiguration
		END'
	EXEC(@sql)
	
	SET @process = 'K007000 Create procedure ccsp_GalateaUpdateChatConfiguration'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaUpdateChatConfiguration]
    @inboundId              smallint,
    @frame                  smallint    = null,
    @description            varchar(50) = null,
    @tNotas                 int         = null,
    @showCalifWnd           bit         = null,
	@inactiveChatTime		smallint	= null,
	@chatDomain				varchar(500)= null,
	@chatTimeOverflow		smallint	= null,
	@chatQueueOverflow		smallint	= null,
    @userId                 smallint    = null,
	@module					int 		= -1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @graph_id smallint
	DECLARE @returnValue int = 1
	
	set @module = case when @module = -1 then 3 else @module end

    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inboundId, @userId= @userId
	
    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable
    Create table #ccInboundTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )
  
    DECLARE @PrevDesc VARCHAR(MAX) = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @inboundId);


	IF NOT EXISTS (SELECT inbound_id FROM ccinbound WHERE inbound_id <> @inboundId AND chatDomain = @chatDomain AND chatDomain <> '''')
	BEGIN
		IF @chatDomain IS NOT NULL
		BEGIN
			UPDATE ccinbound SET chatDomain = @chatDomain WHERE inbound_id = @inboundId
			if @chatDomain = ''''
			BEGIN
				INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
				SELECT AreaName, getDate(), (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 64, @module, ''T&CHAT_DOMAIN'', ''COMMON_NONE_O'', [descripcion]
				FROM ccInbound i inner join ccRIACat_Areas c on i.IDArea = c.IDArea WHERE inbound_id = @inboundId
			END
		END
	END
	ELSE
	BEGIN	-- @chatDomain in use
		EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId;
		IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

		SELECT -2 [Result]
		return (0)
	END

    UPDATE ccInbound SET
        descripcion = ISNULL(@description, descripcion),
        tNotas = ISNULL(@tNotas, tNotas),
		inactiveChatTime = ISNULL(@inactiveChatTime, inactiveChatTime),
		chatTimeOverflow = ISNULL(@chatTimeOverflow, chatTimeOverflow),
		chatQueueOverflow = ISNULL(@chatQueueOverflow, chatQueueOverflow)
    WHERE Inbound_id = @inboundId

	IF @showCalifWnd = 1
    BEGIN
        IF EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inboundId AND tipo = 0)
        BEGIN
            UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId
        END
		ELSE
		BEGIN
			SET @returnValue = -1
		END
     END
     ELSE
     BEGIN
        UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId;
     END

	
    EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId, @tableTemp=''#ccInboundTable''; 

    --DELETE FROM #ccInboundTable WHERE columnInfo IN (''bnocturno'');

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
		(select AreaName from ccRIACat_Areas c inner join ccInbound i on c.IDArea = i.IDArea where Inbound_id = @inboundId),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        64, 
        @module,
        CCIT.identifierInfo,
        CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
            CASE
				WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN @description
                WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                ELSE CCIT.dataInfo END
        ELSE '''' END,
        CASE WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN @PrevDesc ELSE (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId) END
    FROM #ccInboundTable AS CCIT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId;

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable
	

    IF @frame IS NOT NULL
    BEGIN
        SELECT @graph_id = graphic_id from ccRIAGraphics where frame = @frame and [type_id] = 1
        UPDATE ccRIAInboundGraph set graphic_id = ISNULL(@graph_id, graphic_id) where inbound_id = @inboundId

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (select AreaName from ccRIACat_Areas c inner join ccInbound i on c.IDArea = i.IDArea where Inbound_id = @inboundId),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            64,
            @module,
            ''IN_CALL_EDIT_ICON'', 
			'''',
            (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)
    END

    IF(@returnValue <> 1)
		SELECT @returnValue [Result]
	ELSE
		SELECT 1 [Result]

    RETURN(0);

    SET NOCOUNT OFF;
END'
	EXEC(@sql)
	
	SET @process = 'K007000 Alter sp ccsp_GalateaDeleteCampaignAndACD'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaDeleteCampaignAndACD]
            @userId           SMALLINT,
            @DeleteCamId      VARCHAR(MAX),
            @DeleteACDGroupId VARCHAR(MAX),
            @moduleId         SMALLINT = 49
        AS
        BEGIN

            IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
				SELECT value As DeleteCamId, c.IDArea AS IDAreaCamp, 1 AS CampTypeCamp, ISNULL(wg.IDWG,0) as IDWG, ISNULL(c.CampType, 0) AS MediaType
                INTO #CampsDelete
                FROM fn_RIASplitDelimited(@DeleteCamId, '','') a
                inner join ccCamps c on  a.value = c.cam_id and c.IDArea IS NOT NULL
                left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=1
            IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
				SELECT value As DeleteACDId, c.IDArea AS IDAreaACD, 0 AS CampTypeACD, ISNULL(wg.IDWG,0) as IDWG, cast(ISNULL(chat, 0) as int) AS MediaType
                INTO #ACDDelete
                FROM fn_RIASplitDelimited(@DeleteACDGroupId, '','') a
                inner join ccInbound c on  a.value = c.Inbound_id and c.IDArea IS NOT NULL
                left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=0

            IF  not Exists (select * from #CampsDelete union select * from #ACDDelete )
            begin
                select ''-1'' AS Result
                return
            end

            IF datalength(@DeleteCamId) > 0
                BEGIN

                if exists(select cam_id from ccInbound where cam_id in (select DeleteCamId from #CampsDelete)) begin
                    --Borra las calificacion con reprogramacion
                    delete ccCalifCamp from ccInbound A
                    inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
                    inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
                    where A.cam_id in (select DeleteCamId from #CampsDelete)
                    --Borra las subcalificacion con reprogramacion
                    delete rel from ccInbound A
                    inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
                    inner join ccTipoCalif C on B.calif_id=C.calif_id
                    inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
                    inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
                    where A.cam_id in (select DeleteCamId from #CampsDelete) and sb.canReprogram=1

                    update ccInbound set cam_id = null where cam_id in (select DeleteCamId from #CampsDelete)

                end

                insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
                select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete)

                delete from ccCampsAgente where cam_id in (select DeleteCamId from #CampsDelete)
                insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
                select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete) and A.tipo = 1

                delete from ccSupervisorCam where cam_id in (select DeleteCamId from #CampsDelete) and tipo = 1
                delete from ccRIACampEspWG where IdCampEsp in (select DeleteCamId from #CampsDelete) and tipo = 1

                IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
                SELECT ca.AreaName,
                       GETDATE() operationDate,
                       27 operationType,
                       (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                       @moduleId module_id,
                       c.cam_descripcion value,
                       ca.AreaName AS target
                INTO #CampLog
                FROM ccRIACat_Areas ca
                Inner join ccCamps c with(nolock) on ca.IDArea = c.IDArea
                WHERE c.cam_id in (select DeleteCamId from #CampsDelete)

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
				SELECT A.AreaName, GETDATE(), (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
				CASE 
					WHEN CampType = 6 THEN 45
					WHEN CampType = 5 THEN 47
					WHEN CampType = 4 THEN 49
					WHEN CampType = 7 THEN 51
				ELSE 43 END, 
				3, 
				'''',
				'''', 
				c.cam_descripcion
				FROM ccRIACat_Areas A INNER JOIN ccCamps c on A.IDArea = c.IDArea
				where c.cam_id in (select DeleteCamId from #CampsDelete)

                Update ccCamps set IDArea = null where cam_id in (select DeleteCamId from #CampsDelete)
        
                update contactMeanOut set name = '''', conexionInfo = '''', connUser = '''', isActive = 0
                where camp_id in (SELECT DeleteCamId FROM #CampsDelete) and meanContactTypeId=5
        
                update ccWhatsAppNumbers set camp_id = 0 where camp_id in (select DeleteCamId from #CampsDelete)
        

            END
            IF datalength(@DeleteACDGroupId) > 0
                BEGIN

                if exists(select top 1 cam_id from ccInbound where Inbound_id in (select DeleteACDId from #ACDDelete))
                begin
                        update ccInbound set cam_id = null where Inbound_id in (select DeleteACDId from #ACDDelete)
                end

                IF OBJECT_ID(''tempdb..#AllWGACD'') IS NOT NULL DROP TABLE #AllWGACD
                SELECT DISTINCT(IDWG)
                INTO #AllWGACD
                FROM ccRIACampEspWG ce
                WHERE IDCampEsp in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0

                insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
                select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG
                from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id
                where B.User_id is null and A.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                delete ccInboundHorarios Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
                delete ccInboundMsgs Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
                delete ccInboundDnis where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
                select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG
                from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id
                where B.User_id is null and A.cam_id in (SELECT DeleteACDId FROM #ACDDelete)

                delete ccSupervisorCam where cam_id in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0
                delete ccInboundAgentes where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
                delete ccRIACampEspWG where IdCampEsp  in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0


                IF OBJECT_ID(''tempdb..#ACDLog'') IS NOT NULL DROP TABLE #ACDLog
                SELECT ca.AreaName,
                        GETDATE() operationDate,
                        28 operationType,
                        (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                        @moduleId module_id,
                        i.descripcion value,
                        ca.AreaName AS target
                INTO #ACDLog
                FROM ccRIACat_Areas ca
                inner join ccInbound i with(nolock) on ca.IDArea = i.IDArea
                WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
				SELECT a.AreaName, GETDATE(), (SELECT [Login] FROM ccUsers WHERE User_id = @userId),
				CASE 
					WHEN chat = 5 THEN 41
					WHEN chat = 1 THEN 65
					ELSE 61 END, 
				3, 
				'''', 
				'''', 
				i.descripcion
				FROM ccRIACat_Areas a inner join ccInbound i on a.IDArea = i.IDArea
				WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                Update ccInbound set IDArea = null, status = 0 where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
                    begin
                        update ContactMeanIn set name = '''', conexionInfo = ''usuarioID|token|tokenSecret|1|0'', connUser = '''', isActive = 0
                        where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=2
                end
                if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo email asociado al ACD
                    begin
                        update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=1
                end
                update ccinbound set chatDomain = '''' where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)--para desasociar el dominio del chat

                if exists (SELECT inboundId FROM contactMeanIn WHERE inboundId in (select DeleteACDId from #ACDDelete))
                    begin
                        update contactMeanIn set isActive = 0 where inboundId in (select DeleteACDId from #ACDDelete)
                end            
                update ccWhatsAppNumbers set inboundId = 0 where inboundId in (select DeleteACDId from #ACDDelete)
        
            END

            IF datalength(@DeleteCamId) > 0
                Insert into ccRIALog Select * from #CampLog
            IF datalength(@DeleteACDGroupId) > 0
                Insert into ccRIALog Select * from #ACDLog

            SELECT DeleteCamId AS DeleteId,IDAreaCamp AS IDArea,CampTypeCamp AS CampType,''1'' AS Result, cast(IDWG as smallint) IDWG, MediaType FROM #CampsDelete
            UNION
            SELECT DeleteACDId,IDAreaACD,CampTypeACD,''1'' AS Result, cast(IDWG as smallint) IDWG, MediaType FROM #ACDDelete
            IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
            IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
            IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
        END'
	EXEC(@sql)
	
	SET @process = 'K007000 Alter procedure ccsp_GalateaAdminSchedulesManagement'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminSchedulesManagement]
	@option smallint = -1,
	@camId int = -1,
	@camType smallint = -1,
	@scheduleId int = -1,
	@areaId smallint = -1,
	@moduleId tinyint = 0,
	@userId smallint = -1,
	@operationType tinyint = 0
AS
SET NOCOUNT ON;
DECLARE @transtate BIT
IF @@TRANCOUNT = 0
BEGIN
	SET @transtate = 1
	BEGIN TRANSACTION transtate
	END
	BEGIN TRY
		IF @option = 1 --Obtener horarios
		BEGIN
			SELECT horario_id as ScheduleId, Descripcion as [Description],
			HoraInicio as StartHour, MinInicio as StartMinute, HoraFin as EndHour,
			MinFin as EndMinute, Lunes as Monday, Martes as Tuesday, Miercoles as Wednesday,
			Jueves as Thursday, Viernes as Friday, Sabado as Saturday, Domingo as Sunday FROM ccHorarios
		END
		IF @option = 2 --Obtener relaciones de horarios y campañas
		BEGIN
			IF(@camType=1)
			BEGIN
				SELECT cam_id as CampId, Horario_id as ScheduleId FROM ccCampsHorarios WHERE cam_id = @camId
			END
			IF(@camType=0)--campañas de entrada
			BEGIN
				SELECT CONVERT(INT, Inbound_id) as CampId, Horario_id as ScheduleId FROM ccInboundHorarios WHERE Inbound_id = CONVERT(SMALLINT, @camId)
			END
		END
		IF @option =3--agregar la relación de horarios con campañas de salida y entrada
		BEGIN
			IF(@camType =1)
			BEGIN
				IF NOT EXISTs (SELECT cam_id, Horario_id FROM ccCampsHorarios WHERE cam_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					INSERT INTO [CCenterRIA].[dbo].[ccCampsHorarios](cam_id, Horario_id)
						VALUES (@camId, @scheduleId)
					SELECT 1
				END
				SELECT 0
			END
			IF(@camType = 0)
			BEGIN
				IF NOT EXISTs (SELECT Inbound_id, Horario_id FROM ccInboundHorarios WHERE Inbound_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					INSERT INTO [CCenterRIA].[dbo].ccInboundHorarios(Inbound_id, Horario_id) VALUES (@camId, @scheduleId)
					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					SELECT 
						(select AreaName from ccRIACat_Areas c inner join ccInbound i on c.IDArea = i.IDArea where Inbound_id = @camId),
						getDate(),
						(SELECT [Login] FROM ccUsers WHERE User_id = @userid),
						66,
						6,
						'''',
						(select Descripcion from ccHorarios where horario_id = @scheduleId),
						(select descripcion from ccInbound where Inbound_id = @camId)
					SELECT 1
				END
				SELECT 0
			END
		END
		IF @option = 4 --eliminar relación del horario
		BEGIN
			IF(@camType = 1)
			BEGIN
				IF EXISTs (SELECT cam_id, Horario_id FROM ccCampsHorarios WHERE cam_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					DELETE ccCampsHorarios where cam_id=@camId and horario_id=@scheduleId
					SELECT 1
				END
				SELECT 0
			END
			IF(@camType = 0)
			BEGIN
				IF EXISTs (SELECT Inbound_id, Horario_id FROM ccInboundHorarios WHERE Inbound_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					DELETE ccInboundHorarios where inbound_id=@camId and horario_id=@scheduleId
					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					SELECT 
						(select AreaName from ccRIACat_Areas c inner join ccInbound i on c.IDArea = i.IDArea where Inbound_id = @camId),
						getDate(),
						(SELECT [Login] FROM ccUsers WHERE User_id = @userid),
						67,
						6,
						'''',
						(select Descripcion from ccHorarios where horario_id = @scheduleId),
						(select descripcion from ccInbound where Inbound_id = @camId)
					SELECT 1
				END
				SELECT 0
			END
		END
		IF @option = 5
		BEGIN
			IF (EXISTS(SELECT Horario_id FROM ccInboundHorarios WHERE horario_id = @scheduleId) OR EXISTS(SELECT Horario_id FROM ccCampsHorarios WHERE Horario_id = @scheduleId))
			BEGIN
				SELECT 1
			END
			ELSE
			BEGIN
				SELECT 0
			END
		END
		IF @option = 7 --insetar log
		BEGIN
			DECLARE @area nvarchar(max) = (SELECT AreaName FROM [CCenterRIA].[dbo].[ccRIACat_Areas] where IDArea = @areaId)
			DECLARE @userName nvarchar(max) = (SELECT [Login] FROM [CCenterRIA].[dbo].[ccUsers] where [User_id] = @userId)
			DECLARE @campDescription nvarchar(max) 
			DECLARE @scheduleName nvarchar(max)
			IF(@camType = 1)
			BEGIN
				SET @campDescription = (SELECT cam_descripcion FROM [CCenterRIA].[dbo].[ccCamps] WHERE cam_id = @camId)
			END
			IF(@camType = 0)
			BEGIN
				SET @campDescription = (SELECT descripcion FROM [CCenterRIA].[dbo].[ccInbound] WHERE Inbound_id = @camId)
			END
			IF(@camType = 2)--actualizar horarios
			BEGIN
				IF (@scheduleId = 0)
				BEGIN
					SET @campDescription = ''''
					DECLARE @MAXID INT = (SELECT MAX(horario_id) FROM ccHorarios)
					SET @scheduleName = (SELECT Descripcion FROM [CCenterRIA].[dbo].[ccHorarios] WHERE horario_id = @MAXID)
				END
				ELSE
				BEGIN
					SET @campDescription = (SELECT Descripcion FROM [CCenterRIA].[dbo].ccHorarios where horario_id = @scheduleId)
					SET @scheduleName = ''''
				END
			END
			ELSE
			BEGIN
				SET @scheduleName = (SELECT Descripcion FROM [CCenterRIA].[dbo].[ccHorarios] WHERE horario_id = @scheduleId)
			END
			INSERT INTO [CCenterRIA].[dbo].[ccRIALog](areaName, operationDate, operationType, login, module_id, value, target)
				VALUES (@area, GETDATE(), @operationType, @userName, @moduleId, @scheduleName, @campDescription)
		END
		IF @option = 8 --obtener los ids de las campañas con el horario asignado
		BEGIN
			SELECT cam_id FROM ccCampsHorarios WHERE Horario_id=@scheduleId
		END
		IF @option = 9
		BEGIN
			SELECT Descripcion FROM ccHorarios
		END
		IF @option = 10
		BEGIN
			SELECT MAX(horario_id) FROM ccHorarios
		END
		IF @transtate = 1 AND XACT_STATE() = 1
		BEGIN
			COMMIT TRANSACTION transtate
		END;
	END TRY
	BEGIN CATCH
		DECLARE @error INT, @message VARCHAR(4000), @xstate INT;
		SELECT @error = ERROR_NUMBER(), @message = ERROR_MESSAGE(), @xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			ROLLBACK
		IF @xstate = 1
			ROLLBACK TRANSACTION ccsp_GalateaAdminPortsManagement;
		RAISERROR (''ccsp_GalateaAdminSchedulesManagement: %d: %s'', 16, 1, @error, @message) ;
	END CATCH;'
	EXEC(@sql)
	
	SET @process = 'K007000 Alter procedure ccsp_GalateaAdminDispositionRelations'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminDispositionRelations]
@command int,
@type tinyint = null, --0=In, 1=Out
@cam_id smallint = null,
@califIdLst varchar(8000) = null,
@user_id smallint = null
AS
set nocount on
declare @sql as nvarchar(max)

If @command = 1
begin
	select 
		cast (0 as int) [type], 
		i.inbound_id as cam_id, 
		c.calif_id 
	from ccInbound i inner join ccCalifCamp c on i.inbound_id = c.cam_id and c.tipo = 0
	inner join ccTipoCalif t on c.calif_id = t.calif_id
	UNION
	select 
		cast (1 as int) [type], 
		o.cam_id, 
		c.calif_id 
	from ccCamps o inner join ccCalifCamp c on o.cam_id = c.cam_id and c.tipo = 1
	inner join ccTipoCalifOUT co on c.calif_id = co.calif_id
	order by [type], cam_id, calif_id
end
If @command=2  --Asignar calificacion(es) a una campaña de entrada o salida
 begin 
	if @Type=0 
	begin	
		set @sql = ''declare @NotAssigned table(NotAssigned int); 
		declare @Assigned table(Assigned int);

		insert into @NotAssigned (NotAssigned)
		select calif_id from ccTipoCalif where CanReprogram=1 and calif_id in ('' + @califIdLst + '')
		and exists(select inbound_id from ccInbound where cam_id is null and Inbound_id= '' + cast(@cam_id as varchar(10)) + '')

		insert into ccCalifCamp(calif_id,cam_id,tipo) 
		select f.calif_id, e.inbound_id, 0 
		from ccInbound e, cctipoCalif f 
		where f.Calif_Status=1 and f.calif_id in ('' + @califIdLst + '') and f.calif_id not in (select NotAssigned from @NotAssigned)
		and Inbound_id = '' + cast(@cam_id as varchar(10)) + ''
		and not exists(
			select a.calif_id,c.inbound_id,0 from cctipoCalif a
			join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 0
			join ccInbound c on c.inbound_id = b.cam_id
			where f.calif_id = a.calif_id and e.inbound_id = c.inbound_id
			and c.Inbound_id = '' + cast(@cam_id as varchar(10)) + '')

		insert into @Assigned (Assigned)
		select calif_id from ccTipoCalif where calif_id in ('' + @califIdLst + '') and calif_id not in (select NotAssigned from @NotAssigned)

		declare @NotAssignedStr varchar(8000), @AssignedStr varchar(8000)
		SELECT @AssignedStr = COALESCE(@AssignedStr + '''','''', '''''''') + cast(Assigned as varchar(10)) from @Assigned
		select @NotAssignedStr = coalesce(@NotAssignedStr + '''','''', '''''''') + cast(NotAssigned as varchar(10)) from @NotAssigned

		select @AssignedStr [Assigned], @NotAssignedStr [NotAssigned]''
		execute sp_executesql @sql
	end
	else
	begin
		set @sql = ''insert into ccCalifCamp(calif_id,cam_id,tipo) 
		select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalifOUT f where 
		f.CalifOut_Status=1 and f.calif_id in ('' + @califIdLst + '') and cam_id = '' + cast(@cam_id as varchar(10)) + ''
		and not exists(
		select a.calif_id,c.cam_id, 1 from cctipoCalifOUT a
		join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 1
		join ccCamps c on c.cam_id = b.cam_id
		where f.calif_id = a.calif_id and e.cam_id = c.cam_id
		and b.cam_id = '' + cast(@cam_id as varchar(10)) + '')''
		execute sp_executesql @sql
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(@cam_id) where cam_id=@cam_id	
		return(0)
	end
 end
 If @command=3 -- Desasignar calificacion de campaña de entrada o salida
 begin
	delete ccCalifCamp where cam_id=@cam_id and tipo=@type and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(@cam_id) where cam_id=@cam_id
	return(0)
 end
 If @command=4 
 begin
	IF(@type = 0) 
	BEGIN
		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
		SELECT 
			(select AreaName from ccRIACat_Areas c inner join ccInbound i on c.IDArea = i.IDArea where Inbound_id = @cam_id),
			getDate(),
			(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
			68,
			7,
			'''',
			Description,
			(select descripcion from ccInbound where Inbound_id = @cam_id)
			from ccTipoCalif 
			where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	END
 end
 If @command=5
 begin
	IF(@type = 0) 
	BEGIN
		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
		SELECT 
			(select AreaName from ccRIACat_Areas c inner join ccInbound i on c.IDArea = i.IDArea where Inbound_id = @cam_id),
			getDate(),
			(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
			69,
			7,
			'''',
			Description,
			(select descripcion from ccInbound where Inbound_id = @cam_id)
			from ccTipoCalif 
			where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	END
 end

set nocount off'
	EXEC(@sql)

	
	--------------------------------------------------------------------------------------------------
	
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
