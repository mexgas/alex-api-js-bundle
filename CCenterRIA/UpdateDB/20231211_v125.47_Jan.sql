/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K089000

Database: CCenterRia
Required version: 125.37

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
SET @versionfix = 47
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

        -----------------------------------------------------BEGIN TT7955 Uriel Cabrera ----------------------------------------------------------------

        SET @process = 'TT7955 Se elimina si existe ccsp_GalateaGetAgentsRelations'
        SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetAgentsRelations'')
                    begin
                        DROP PROCEDURE ccsp_GalateaGetAgentsRelations;
                    end'
        EXEC(@sql);
        
        SET @process = 'TT7955 Se crea prcedimeinto para relaciones de campañas agente en GalateaAgent'
        SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetAgentsRelations] @Option AS SMALLINT,
                    @Type AS SMALLINT = 0
                    AS
                    BEGIN
                        SET NOCOUNT ON;
                        IF @Option = 1 BEGIN
                            SELECT C.cam_id, C.cam_descripcion, CA.prioridad, A.Login, A.User_id, CA.skill 
                            FROM ccCamps AS C
                            JOIN ccCampsAgente AS CA ON C.cam_id = CA.cam_id 
                            JOIN ccUsers AS A  ON A.User_id = CA.User_id AND A.TipoUser_id=1 AND A.Status = 1 AND C.cam_activo=1 and A.IDArea = C.IDArea
                            WHERE (@Type = 2 AND C.cam_bNew = 2) OR @Type != 2
                            ORDER BY C.cam_id, CA.prioridad
                        END
                        ELSE IF @Option = 2 BEGIN
                            SELECT distinct I.Inbound_id, I.descripcion, prioridad, A.Login, A.User_id, skill
                            FROM ccInboundAgentes G JOIN ccInbound I ON G.Inbound_id = I.Inbound_id
                            JOIN ccUsers A  ON A.user_id = G.user_id AND A.Status = 1 AND I.IDArea = A.IDArea
                            ORDER BY I.Inbound_id, Prioridad
                        END
                    END
                    '
        EXEC(@sql);

        -----------------------------------------------------END TT7955 Uriel Cabrera ----------------------------------------------------------------

                ----------------------------------------------------- BEGIN Hotfix SMS Ivan Martin ----------------------------------------------------------------

        SET @process = 'Hotfix SMS - Create new table for messages without a status update'
        SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''UnchangedStatusSmsMessages'')
                    BEGIN
                        CREATE TABLE UnchangedStatusSmsMessages (
                            SystemApiId VARCHAR(100) NOT NULL,
                            StatusSystemsId INT NOT NULL
                        );
                    END;'
        EXEC(@sql);

        SET @process = 'Hotfix SMS - Adding indexes'
        SET @sql = 'if not exists (select * from sys.indexes where name = N''IX_smsccoLogDial_2'' and object_id = OBJECT_ID(N''smsccoLogDial''))
                    begin
                        CREATE INDEX IX_smsccoLogDial_2 ON smsccoLogDial(smsDate,statusSystemsId);
                    end'
        EXEC(@sql);

        set @process = 'Dineria: Se cambia action 1 para que regrese solo campañas con horario valido. Se cambia completamente action 7 para que actualice los estados en paquetes de la tabla ProcessingSmsStatusUpdates. Se agrega WITH(NOLOCK) en acceso a tablas smsOutSource/smsccoLogDial en actions 7 y 9'
    set @sql='ALTER procedure [dbo].[ccspOutboundSmsMessage] 
        @action int,
        @camId int = null,
        @SentMsg int=null,
        @smsoutIds varchar(max)=null,
        @SystemApiId varchar(100)=null,
        @statusSystemsId int =null,
        @InsufficientBalance int=null,
        @date datetime =null,
        @addingCampaign bit = null
        as
        declare @sql varchar(max)
        if @action=1 begin
            set @date=getdate()

            if @addingCampaign = 1 begin
                select distinct cast(c. cam_id as int) as CamId,
                                cam_descripcion as [Name],
                                cam_procesando as [Start],
                                0 AS MessageQuantity
                from ccCamps c
                where CampType=7 and c.IDArea is not null and c.cam_id=@camId
            end
            else begin
                SELECT DISTINCT CAST(c. cam_id AS INT) AS CamId,
                                cam_descripcion AS Name,
                                cam_procesando AS Start,
                                ISNULL((w.new + w.pro),0) AS MessageQuantity
                FROM ccCamps c
                LEFT JOIN ccSmsSchedules s ON s.cam_id = c.cam_id
                LEFT JOIN ccCampsNvosCB  w ON c.cam_id = w.id
                WHERE CampType=7 AND c.IDArea IS NOT NULL AND(@camId IS NULL or @camId=0 OR c.cam_id = @camId)
                AND @date BETWEEN dateadd(hh,-12,iDate) AND dateadd(hh,12,fDate)
            end
        end
        else if @action=2 begin
            select tz_offset from ccTimeZones ORDER BY tz_id
        end
        else if @action=3 begin
            select cast(camId as int) CamId,SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected 
            from ccSmsConversationsResult where ( @camId is null or camId=@camId)
        end
        else if @action=4 begin
            truncate table ccSmsConversationsResult
        end
        else if @action=5 begin
            if not exists(select * from ccSmsConversationsResult where camId=@camId) begin
                insert into ccSmsConversationsResult values(@camId,@SentMsg,0,0,0,0,@InsufficientBalance,0)
            end
            else begin
                update ccSmsConversationsResult set SentMsg=SentMsg+@SentMsg 
                ,InsufficientBalance=InsufficientBalance+@InsufficientBalance
                where camId=@camId
            end
        end
        else if @action=6 begin 
            set @sql=''delete from smsWorkingTable where smsout_id in(''+@smsoutIds+'')''
            exec (@sql)
        end
        else if @action=7 begin
            DECLARE @TemporalProcessingSmsStatusUpdates TABLE(SystemApiId VARCHAR(100) PRIMARY KEY, StatusSystemsId INT, IsCharged BIT)
            INSERT INTO @TemporalProcessingSmsStatusUpdates
            SELECT SystemApiId, StatusSystemsId, IsCharged FROM ProcessingSmsStatusUpdates

            DECLARE @ChargedMessages INT = (SELECT SUM(CASE WHEN IsCharged = 1 THEN 1 ELSE 0 END) FROM @TemporalProcessingSmsStatusUpdates)
            IF @ChargedMessages <> 0
            BEGIN
                UPDATE ccSettings2 WITH(TABLOCK) SET valor = valor - @ChargedMessages WHERE setting_id = 258 AND valor > 0;
            END

            DECLARE @UpdatingSmsWorkingTable TABLE(SystemApiId VARCHAR(100) PRIMARY KEY, OldStatusSystemsId INT, NewStatusSystemsId INT, CampaignId INT)
            INSERT INTO @UpdatingSmsWorkingTable
            SELECT S.SystemApiId, S.StatusSystemsId, T.StatusSystemsId, S.cam_id FROM smsccoLogDial S WITH(NOLOCK)
            INNER JOIN @TemporalProcessingSmsStatusUpdates T ON S.SystemApiId = T.SystemApiId
            
            ;WITH CTE AS (
            SELECT
                CampaignId,
                COUNT(CASE WHEN NewStatusSystemsId = 0 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 0 THEN 1 END) AS SentMsg,
                COUNT(CASE WHEN NewStatusSystemsId = 1 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 1 THEN 1 END) AS Delivered,
                COUNT(CASE WHEN NewStatusSystemsId = 2 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 2 THEN 1 END) AS NotDelivered,
                COUNT(CASE WHEN NewStatusSystemsId = 3 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 3 THEN 1 END) AS RecipientRejected,
                COUNT(CASE WHEN NewStatusSystemsId = 4 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 4 THEN 1 END) AS CarrierRejected,
                COUNT(CASE WHEN NewStatusSystemsId = 5 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 5 THEN 1 END) AS Exception,
                COUNT(CASE WHEN NewStatusSystemsId = 6 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 6 THEN 1 END) AS InsufficientBalance

            FROM @UpdatingSmsWorkingTable
            GROUP BY CampaignId
            )

            MERGE INTO ccSmsConversationsResult AS Target
            USING CTE AS Source ON Target.camId = Source.CampaignId
            WHEN MATCHED THEN
                UPDATE SET
                    Target.SentMsg = CASE WHEN (Target.SentMsg + Source.SentMsg) < 0 THEN 0 ELSE (Target.SentMsg + Source.SentMsg) END,
                    Target.Delivered = CASE WHEN (Target.Delivered + Source.Delivered) < 0 THEN 0 ELSE (Target.Delivered + Source.Delivered) END,
                    Target.NotDelivered = CASE WHEN (Target.NotDelivered + Source.NotDelivered) < 0 THEN 0 ELSE (Target.NotDelivered + Source.NotDelivered) END,
                    Target.RecipientRejected = CASE WHEN (Target.RecipientRejected + Source.RecipientRejected) < 0 THEN 0 ELSE (Target.RecipientRejected + Source.RecipientRejected) END,
                    Target.CarrierRejected = CASE WHEN (Target.CarrierRejected + Source.CarrierRejected) < 0 THEN 0 ELSE (Target.CarrierRejected + Source.CarrierRejected) END,
                    Target.Exception = CASE WHEN (Target.Exception + Source.Exception) < 0 THEN 0 ELSE (Target.Exception + Source.Exception) END,
                    Target.InsufficientBalance = CASE WHEN (Target.InsufficientBalance + Source.InsufficientBalance) < 0 THEN 0 ELSE (Target.InsufficientBalance + Source.InsufficientBalance) END

            WHEN NOT MATCHED BY TARGET THEN
            INSERT (camId, SentMsg, Delivered, NotDelivered, RecipientRejected, CarrierRejected, Exception, InsufficientBalance)
            VALUES (Source.CampaignId, Source.SentMsg, Source.Delivered, Source.NotDelivered, Source.RecipientRejected, Source.CarrierRejected, Source.Exception, Source.InsufficientBalance);

            UPDATE smsccoLogDial SET Bill = (CASE WHEN T.StatusSystemsId IN (0, 1, 2) THEN 0.7 ELSE 0 END),
                                     statusSystemsId = T.StatusSystemsId
            FROM smsccoLogDial S WITH(NOLOCK)
            INNER JOIN @TemporalProcessingSmsStatusUpdates T ON T.SystemApiId = S.SystemApiId

            DELETE FROM ProcessingSmsStatusUpdates 
            WHERE SystemApiId IN (SELECT SystemApiId FROM @TemporalProcessingSmsStatusUpdates);

            SELECT @@ROWCOUNT;
        end
        else if @action=8 begin
            update smsccoLogDial set Bill=0.70 where smsDate>=@date and statusSystemsId not in(3,4,5,6)
        end
        else if @action=9 begin
            CREATE TABLE #TempSmsOutIds (
            smsout_id INT
            );

            INSERT INTO #TempSmsOutIds (smsout_id)
            SELECT DISTINCT wt.smsout_id
            FROM smsWorkingTable wt WITH(NOLOCK)
            JOIN smsOutSource os WITH(NOLOCK) ON wt.smsout_id = os.smsout_id
            LEFT JOIN smsccoLogDial cco WITH(NOLOCK) ON wt.smsout_id = cco.smsout_id
            WHERE wt.cam_id=@camId and wt.sms_status IN(1,2) 
            AND cco.smsout_id IS NULL;
            

            UPDATE wt
            SET wt.sms_status = 0
            FROM smsWorkingTable wt
            JOIN #TempSmsOutIds temp ON wt.smsout_id = temp.smsout_id;

            DROP TABLE #TempSmsOutIds;
        end
        else if @action=10 begin
            SELECT COUNT(*) FROM smsWorkingTable with (NOLOCK) WHERE cam_id = @camId
        end
        else if @action=12 begin
            IF EXISTS (SELECT 1 FROM ccSmsSchedules WITH (NOLOCK) WHERE cam_id = @camId 
            AND GETDATE() BETWEEN dateadd(hh,-12,iDate) AND dateadd(hh,12,fDate)
            )
            AND EXISTS (SELECT 1 FROM smsWorkingTable WITH (NOLOCK) WHERE cam_id = @camId)
            BEGIN
                SELECT CAST(0 AS BIT);
                RETURN;
            END
            ELSE BEGIN
                UPDATE ccCamps SET cam_procesando = 0 WHERE cam_id = @camId
                SELECT CAST(1 AS BIT);
                RETURN;
            END
        end'
    EXEC(@sql)


        ----------------------------------------------------- END Hotfix SMS Ivan Martin ----------------------------------------------------------------


        -----------------------BEGIN hotfix TT7668 -AgenteKolob - Configuración en el tiempo de notas Marco Garcia--------------------------------------------
set @process = 'Delete if exist sp ccsp_RIAUpdateEspecConfig TT7668 -AgenteKolob - Configuración en el tiempo de notas'
set @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateEspecConfig'')
        begin
        DROP PROCEDURE ccsp_RIAUpdateEspecConfig;
        end'
EXEC(@Sql)
    
set @process = 'Create sp ccsp_RIAUpdateEspecConfig TT7668 -AgenteKolob - Configuración en el tiempo de notas'
SET @sql = '
    CREATE PROCEDURE [dbo].[ccsp_RIAUpdateEspecConfig] 
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
    @editableContactData     BIT          = NULL,
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
    tNotas = ISNULL(CASE WHEN @chat <> 5  OR @chat IS NULL THEN @tNotas ELSE 10 END, tNotas),
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
    recordHold = ISNULL(@recordHold, recordHold),
    EditableContactData = ISNULL(@editableContactData, EditableContactData)
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
                WHEN CCIT.identifierInfo IN (''IN_RECORD_ON_HOLD'',''IN_PLAY_QUEUE_ORDER'', ''IN_STOP_RECORDING'', ''IN_SHOW_DISPOSITIONS'', ''IN_CALL_KEY'', ''IN_CONDUCT_CALLBACK_SURVEY'', ''IN_RECEIVE_DTMF_TONES'', ''IN_CALL_BACK'', ''EDIT_CALL_DATASET'') THEN
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

SET NOCOUNT OFF
    ';
EXEC(@sql)



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
