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
        SET @sql = 'if exists (select * from master.sys.databases where name = N''ccsp_GalateaGetAgentsRelations'')
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
        SET @sql = 'if not exists (select * from sys.indexes where name = N''IX_smsccoLogDial_'' and object_id = OBJECT_ID(N''smsccoLogDial''))
				    begin
				        CREATE INDEX IX_smsccoLogDial_ 2 ON smsccoLogDial(smsDate,statusSystemsId);
				    end'
        EXEC(@sql);

        SET @process = 'Hotfix SMS - Addition of actions 13 and 14 to update sms status when they are not updated correctly'
        SET @sql = 'ALTER procedure [dbo].[ccspOutboundSmsMessage] 
                        @action int,
                        @camId int = null,
                        @SentMsg int=null,
                        @smsoutIds varchar(max)=null,
                        @SystemApiId varchar(100)=null,
                        @statusSystemsId int =null,
                        @InsufficientBalance int=null,
                        @date datetime =null,
                        @IsCharged BIT = null,
                        @smsOutId INT = NULL,
						@TotalMessages INT = NULL
                        as
                        declare @sql varchar(max)
                        if @action=1 begin
                            select distinct cast(c. cam_id as int) as CamId,cam_descripcion as [Name],cam_procesando as [Start] 
                            from ccCamps c with(nolock)
                            left join ccCampsNvosCB w with(nolock) on c.cam_id = w.id
                            where CampType=7 and c.IDArea is not null and( @camId is null or c.cam_id=@camId) and w.new >0
    
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
                            if not exists(select 1 from ccSmsConversationsResult where camId=@camId) begin
                                insert into ccSmsConversationsResult values(@camId,@SentMsg,0,0,0,0,@InsufficientBalance,0)
                            end
                            else begin
                                update ccSmsConversationsResult set SentMsg=SentMsg+@SentMsg 
                                ,InsufficientBalance=InsufficientBalance+@InsufficientBalance
                                where camId=@camId
                            end
                        end
                        else if @action=6 begin 
                            set @sql=''declare @listCamId table(camId int,status bit)

                        declare @camId int
                        insert into @listCamId
                        select distinct cam_id,0 from smsWorkingTable with(nolock) where smsout_id in(''+@smsoutIds+'')

                        while exists(select 1 from @listCamId where status=0)begin
                            select top 1 @camId=CamId from @listCamId where status=0
                            
                            exec ccsp_GalateaGetCampsNvosCB @cam_id=@camId,@Tipo=2,@regval=1
                            update @listCamId set status=1 where status=0 and @camId=CamId 
                        end
                        delete from smsWorkingTable where smsout_id in(''+@smsoutIds+'')
                            ''
                            exec (@sql)
                        end
                        else if @action=7 begin

                            IF @IsCharged = 1
                            BEGIN
                                UPDATE ccSettings2 WITH(TABLOCK) SET valor = valor - 1 WHERE setting_id = 258 AND valor > 0;
                            END

                            declare @statusSystemsIdOld int
                            declare @ccSmsConversationsResult table(camId int,statusSystemsId int,description varchar(255), value int)
                            select top(1) @camId =cam_id,@statusSystemsIdOld=statusSystemsId, @smsOutId=smsout_id from smsccoLogDial with(nolock) where SystemApiId=@SystemApiId
                            update smsccoLogDial set statusSystemsId=@statusSystemsId where SystemApiId=@SystemApiId
                            
							IF @camId IS NULL BEGIN
								INSERT INTO UnchangedStatusSmsMessages (SystemApiId, StatusSystemsId) VALUES (@SystemApiId, @statusSystemsId)
							END

                            insert into @ccSmsConversationsResult
                            select camId, ROW_NUMBER() OVER(ORDER BY camId ASC)-1 AS statusSystemsId, description,value
                            from ccSmsConversationsResult
                            unpivot
                            (
                                value
                                for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected, Exception, InsufficientBalance)
                            ) unpiv
                            where camId= @camId

                            update @ccSmsConversationsResult set value =case when value>0 then value-1 else 0 end where statusSystemsId=@statusSystemsIdOld
                            update @ccSmsConversationsResult set value =value+1 where statusSystemsId=@statusSystemsId
                            
                            ;with res as(
                            select * from 
                            (
                                select camId, description, value
                                from @ccSmsConversationsResult 
                            ) src
                            pivot
                            (
                            sum(value)
                            for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected, Exception, InsufficientBalance)
                            ) piv
                            )

                            update B 
                            set B.SentMsg=A.SentMsg
                            ,B.Delivered=A.Delivered
                            ,B.NotDelivered=A.NotDelivered
                            ,B.RecipientRejected=A.RecipientRejected
                            ,B.CarrierRejected=A.CarrierRejected
                            ,B.Exception=A.Exception
                            ,B.InsufficientBalance=A.InsufficientBalance
                            from
                            res A
                            inner join ccSmsConversationsResult B on A.camId=B.camId

                            exec ccspOutboundSmsMessage @action = 11, @smsOutId=@smsOutId
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
                            FROM smsWorkingTable wt
                            JOIN smsOutSource os ON wt.smsout_id = os.smsout_id
                            LEFT JOIN smsccoLogDial cco ON wt.smsout_id = cco.smsout_id
                            WHERE wt.sms_status IN(1,2) 
                            AND wt.cam_id = @camId;

                            UPDATE wt
                            SET wt.sms_status = 0, sms_dateDial = DATEADD(mi,30,GETDATE())
                            FROM smsWorkingTable wt
                            JOIN #TempSmsOutIds temp ON wt.smsout_id = temp.smsout_id;

                            DROP TABLE #TempSmsOutIds;
                        end

                        else if @action=10 begin
                            IF NOT EXISTS(SELECT 1 FROM smsWorkingTable WHERE cam_id = @camId) BEGIN
                                UPDATE ccCamps SET cam_procesando = 0 WHERE cam_id = @camId
                                SELECT CAST(0 AS BIT) 
                            END
                            ELSE BEGIN
                                SELECT CAST(1 AS BIT) -- Has unsent messages 
                            END
                        end

                        else if @action=11 begin
                            UPDATE wt
                            SET sms_status = 0, sms_dateDial = DATEADD(mi,30,GETDATE())
                            FROM smsWorkingTable wt with (rowlock) WHERE smsout_id = @smsOutId;
                        end
                        else if @action=12 begin
                            if exists(select 1 from ccSmsSchedules with(nolock) where cam_id = @camId and getdate() between iDate and fDate)
                            begin
                                if exists(select 1 from smsWorkingTable with(nolock) where cam_id = @camId)
                                begin
                                    select cast(1 as bit)
                                    return
                                end
                            end
                            select cast(0 as bit)
                            update ccCamps set cam_procesando=0 where cam_id=@camId
                        end

						else if @action=13 begin
							SELECT cam_id AS CampaingId, U.statusSystemsId AS StatusSystemsId, COUNT(*) AS TotalMessages
							FROM smsccoLogDial S
							INNER JOIN UnchangedStatusSmsMessages U ON S.SystemApiId = U.SystemApiId
							GROUP BY S.cam_id, U.statusSystemsId
                        end

						else if @action=14 begin
							
							DECLARE @TemporalUnchangedStatusSmsMessages TABLE (SystemApiId VARCHAR(100), StatusSystemsId INT, StatusSystemsIdOld INT)
							INSERT INTO @TemporalUnchangedStatusSmsMessages
								SELECT U.SystemApiId, U.statusSystemsId, S.statusSystemsId
								FROM UnchangedStatusSmsMessages U  with(nolock) 
								INNER JOIN smsccoLogDial S ON S.SystemApiId = U.SystemApiId			

							------------------------Update smsccoLogDial---------------------------------------
							UPDATE S SET S.StatusSystemsId = U.StatusSystemsId
							FROM smsccoLogDial S
							INNER JOIN @TemporalUnchangedStatusSmsMessages U ON S.SystemApiId = U.SystemApiId;
						
							DECLARE @TemporalSmsConversationsResult TABLE(camId INT, statusSystemsId INT, description VARCHAR(255), value INT)
							INSERT INTO @TemporalSmsConversationsResult
							SELECT camId, ROW_NUMBER() OVER(ORDER BY camId ASC)-1 AS statusSystemsId, description, value
							FROM ccSmsConversationsResult
							UNPIVOT
							(
								value
								FOR description IN (SentMsg, Delivered, NotDelivered, RecipientRejected, CarrierRejected, Exception, InsufficientBalance)
							) AS unpiv
							WHERE camId = @camId;

							--------------------------Update ccSmsConversationsResult --------------------------
							SELECT StatusSystemsIdOld, COUNT(*) AS DecrementCount
							INTO #DecrementCounts
							FROM @TemporalUnchangedStatusSmsMessages
							GROUP BY StatusSystemsIdOld;

							SELECT StatusSystemsId, COUNT(*) AS IncrementCount
							INTO #IncrementCounts
							FROM @TemporalUnchangedStatusSmsMessages
							GROUP BY StatusSystemsId;

							UPDATE T SET T.value = CASE WHEN T.value > D.DecrementCount THEN T.value - D.DecrementCount ELSE 0 END
							FROM @TemporalSmsConversationsResult T
							INNER JOIN #DecrementCounts D ON T.statusSystemsId = D.StatusSystemsIdOld;

							UPDATE T SET T.value = T.value + I.IncrementCount
							FROM @TemporalSmsConversationsResult T
							INNER JOIN #IncrementCounts I ON T.statusSystemsId = I.StatusSystemsId;

							DROP TABLE #DecrementCounts;
							DROP TABLE #IncrementCounts;
							---Return the results to the original table
							;WITH res AS
							(
								SELECT * FROM 
								(
									SELECT camId, description, value
									FROM @TemporalSmsConversationsResult 
								) AS src
								PIVOT
								(
									SUM(value)
									FOR description IN (SentMsg, Delivered, NotDelivered, RecipientRejected, CarrierRejected, Exception, InsufficientBalance)
								) AS piv
							)

							UPDATE B 
							SET B.SentMsg = A.SentMsg,
								B.Delivered = A.Delivered,
								B.NotDelivered = A.NotDelivered,
								B.RecipientRejected = A.RecipientRejected,
								B.CarrierRejected = A.CarrierRejected,
								B.Exception = A.Exception,
								B.InsufficientBalance = A.InsufficientBalance
							FROM
								res AS A
							INNER JOIN ccSmsConversationsResult AS B ON A.camId = B.camId;
                            -- Delete updated messages
							DELETE FROM UnchangedStatusSmsMessages WHERE SystemApiId IN (SELECT SystemApiId FROM @TemporalUnchangedStatusSmsMessages);
                        END'
        EXEC(@sql);


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
