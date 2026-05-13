/*******************************/
/*******************************/
/*
Author: Marco Antonio García
Date: 2025/06/23
Description: Demo/Sprint2
Database: CCenterRia
Required version: 127.2
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
    SET @version = 127 --**********actualizar a 124 sin fix
    SET @versionfix = 7
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


	--- BEGIN Services Pack 1-8 --

    SET @process = 'Drop Procedure [dbo].[ccsp_RIACATNotReadyTypes]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_RIACATNotReadyTypes'')
        Begin
            DROP PROCEDURE ccsp_RIACATNotReadyTypes
        End';
    EXEC(@sql);

    SET @process = 'Drop Procedure [dbo].[ccsp_GetCommonNotReadyStates]';
    SET @sql = N'
        If Exists (Select 1 From sys.procedures Where name = N''ccsp_GetCommonNotReadyStates'')
            Begin
                DROP PROCEDURE ccsp_GetCommonNotReadyStates
            End';
    EXEC(@sql);

    SET @process = 'Drop Procedure [dbo].[ccsp_ProcessDNCQueue]';
    SET @sql = N'
        If Exists (Select 1 From sys.procedures Where name = N''ccsp_ProcessDNCQueue'')
            Begin
                DROP PROCEDURE ccsp_ProcessDNCQueue
            End';
    EXEC(@sql);   

    SET @process = 'Drop Procedure [dbo].[ccsp_RIACATNotReadyTypes]';
    SET @sql = N'
        If Exists (Select 1 From sys.procedures Where name = N''ccsp_RIACATNotReadyTypes'')
            Begin
                DROP PROCEDURE ccsp_RIACATNotReadyTypes
            End';
    EXEC(@sql);


	SET @process = 'CREATE TABLE dbo.ccDNCQueue'
	SET @sql = 'IF OBJECT_ID(''dbo.ccDNCQueue'', ''U'') IS NULL
BEGIN
    CREATE TABLE dbo.ccDNCQueue
    (
        QueueId BIGINT IDENTITY(1,1) PRIMARY KEY,
        telefono VARCHAR(30) NOT NULL,
        ln_id INT NOT NULL,
        calKey VARCHAR(40) NULL,
        status TINYINT NOT NULL DEFAULT 0,
        created_at DATETIME NOT NULL DEFAULT GETDATE(),
        started_at DATETIME NULL,
        retry_count INT NOT NULL DEFAULT 0,
        error_message VARCHAR(1000) NULL
    );
END'
	exec (@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_AvrsSyncronization] error agentes virtuales'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AvrsSyncronization]
@action SMALLINT,
@maxRecordsToTransfer INT = 10,
@ids varchar(max)= 0
AS
BEGIN
SET NOCOUNT ON;

IF @action = 1
BEGIN
    DECLARE @countrId INT;
    SET @countrId = 1;

    SELECT @countrId = valor
    FROM ccSettings
    WHERE setting_id = 104;

          -- Declarar la variable tipo tabla
        declare @tempCalls table(
        cal_id INT,
        user_id INT,
        Inbound_id INT,
        calif_id int,
        cal_extension INT,
        cal_inicio DATETIME,
        phone VARCHAR(50),
        duration INT,
        cal_key VARCHAR(50),
        cal_manual int,
        cal_puerto INT,
        dni_id INT,
        fvalida datetime,
        cal_whohung int,
        califSub_id int,
        cal_tMoh INT,
        dateEnd DATETIME,
        callType INT,
        avrsId INT,
        prefijo VARCHAR(20),
        isCallRecord BIT,
        DNIS VARCHAR(50),
        IDWG VARCHAR(1000),
        IsVoicemail BIT,
        VirtualAgentId int
    );

        declare @deleteRow table(id int primary key);
        declare @relationCallIdUser table(cal_id int, user_id int);

    WITH callsIn AS (
        SELECT TOP (@maxRecordsToTransfer)
            calls.cal_id as CallId,
            CASE WHEN ccInbound.chat = 11 THEN 0 ELSE calls.[User_id] END AS [user_id],
            calls.Inbound_id,
            calls.calif_id,
            CAST(cal_extension AS INT) AS cal_extension,
            cal_inicio,
            cal_ANI AS phone,
            ISNULL(cal_tDialog - CASE WHEN ccInbound.recordHold = 1 THEN 0 ELSE cal_tMoh END, 0)
            + CASE WHEN stopRecording = 0 THEN ISNULL(trans.tDespuesXfer, 0) ELSE 0 END AS duration,
            cal_key,
            0 AS cal_manual,
            cal_puerto,
            calls.dni_id,
            fvalida,
            cal_whohung,
            ISNULL(CAST(califSub_id AS SMALLINT), 0) AS califSub_id,
            CASE
                WHEN trans.tAntesXfer IS NULL THEN cal_tMoh
                WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0
                ELSE cal_tMoh - trans.tAntesXfer
            END AS cal_tMoh,
            DATEADD(ss, ISNULL(cal_tDialog, 0), cal_inicio) AS dateEnd,
            avrs.tipo + 1 AS callType,
            avrs.id AS avrsId,
            ccInbound.prefijo,
            CONVERT(BIT, CASE WHEN ISNULL(calls.file_moved, 1) = 2 THEN 0 ELSE 1 END) AS isCallRecord,
            ISNULL(dni.dni_numero, '''') AS DNIS,
            dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG,
            0 AS IsVoicemail,
            CASE WHEN ccInbound.chat = 11 THEN calls.[User_id] ELSE 0 END AS VirtualAgentId
        FROM ccCallsIn AS calls WITH (NOLOCK)
        INNER JOIN ccInbound ON ccInbound.Inbound_id = calls.Inbound_id
        INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 0
        LEFT JOIN ccDNIS dni ON dni.dni_id = calls.dni_id
        LEFT JOIN ccInboundExtend inbExt ON inbExt.Inbound_id = calls.Inbound_id
        LEFT JOIN (
            SELECT cal_id, tipo, SUM(tAntesXfer) AS tAntesXfer, SUM(tDespuesXfer) AS tDespuesXfer
            FROM ccLogTransfers  with(nolock)
            WHERE tipo = 1 AND modo != 7
            GROUP BY cal_id, tipo
        ) trans ON calls.cal_id = trans.cal_id
    ),
    callsOut AS (
        SELECT TOP (@maxRecordsToTransfer)
            calls.cal_id AS CallId,
            user_id AS UserId,
            calls.cam_id AS camAcdId,
            CAST(calls.calif_id AS SMALLINT) AS califId,
            CAST(cal_extension AS INT) AS extension,
            cal_inicio,
            cal_telefono,
            ISNULL(cal_tDialog - CASE WHEN camps.recordHold = 1 THEN 0 ELSE cal_tMoh END, 0)
            + CASE WHEN stopRecording = 0 THEN ISNULL(trans.tDespuesXfer, 0) ELSE 0 END AS duration,
            cal_key,
            cal_manual,
            cal_puerto,
            0 AS dni_id,
            fvalida,
            cal_whohung,
            ISNULL(CAST(califSub_id AS SMALLINT), 0) AS califSub_id,
            CASE
                WHEN trans.tAntesXfer IS NULL THEN cal_tMoh
                WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0
                ELSE cal_tMoh - trans.tAntesXfer
            END AS cal_tMoh,
            DATEADD(ss, ISNULL(cal_tDialog, 0), cal_inicio) AS dateEnd,
            avrs.tipo + 1 AS callType,
            avrs.id AS avrsId,
            camps.prefijo,
            CONVERT(BIT, CASE WHEN ISNULL(calls.file_moved, 1) = 2 THEN 0 ELSE 1 END) AS isCallRecord,
            '''' AS DNIS,
            dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG,
            CASE WHEN calls.statusCall_id = 19 THEN 1 ELSE 0 END AS IsVoicemail,
            calls.virtualAgentId as VirtualAgentId
        FROM ccoCallsOut AS calls WITH (NOLOCK)
        INNER JOIN ccCamps camps ON camps.cam_id = calls.cam_id
        INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 1
        LEFT JOIN (
            SELECT cal_id, tipo, SUM(tAntesXfer) AS tAntesXfer, SUM(tDespuesXfer) AS tDespuesXfer
            FROM ccLogTransfers with(nolock)
            WHERE tipo = 2
            GROUP BY cal_id, tipo
        ) trans ON calls.cal_id = trans.cal_id
    )

    INSERT INTO @tempCalls
    SELECT * FROM callsIn
    UNION
    SELECT * FROM callsOut;


    insert into @deleteRow
    select min(avrsId) id
    from @tempCalls
    group by cal_id,callType
    having count(*)>1

    delete from @tempCalls where avrsId in( select id from @deleteRow )
        delete from ccAVRSTransfer where id in( select id from @deleteRow )

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE callType=0 and user_id=0 and virtualAgentId=0)
    BEGIN
                insert into @relationCallIdUser
                select A.cal_id,aglog.User_id from @tempCalls A
                inner join ccCallsIn B with(nolock) on A.cal_id=B.cal_id and A.callType=0
                inner join ccLogAgentesDia aglog with(nolock) on aglog.callID=B.cal_id and aglog.Tipo=A.callType and aglog.TipoStatusAge_id=4

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join ccCallsIn B with(nolock) on A.cal_id=B.cal_id

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join @tempCalls B on A.cal_id=B.cal_id and B.callType=0

                delete from @relationCallIdUser
        END

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE  user_id=0 and virtualAgentId=0 and callType=1 and IsVoicemail =0)
    BEGIN
                insert into @relationCallIdUser
                select A.cal_id,aglog.User_id from @tempCalls A
                inner join ccoCallsOut B with(nolock) on A.cal_id=B.cal_id and A.callType=1
                inner join ccLogAgentesDia aglog with(nolock) on aglog.callID=B.cal_id and aglog.Tipo=A.callType and aglog.TipoStatusAge_id=4

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join ccoCallsOut B with(nolock) on A.cal_id=B.cal_id

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join @tempCalls B on A.cal_id=B.cal_id and B.callType=1
        END

     -- Revisar si hay registros con IsVoicemail = 1
    IF EXISTS (SELECT 1 FROM @tempCalls WHERE IsVoicemail = 1)
    BEGIN
                update A
                set A.duration=B.tDialing
                FROM @tempCalls A
                Inner JOIN ccoLogDials B with(nolock) ON A.cal_id=B.cal_id
        WHERE A.IsVoicemail = 1;
    END

    --elimina los registros y se agrega tabla temporal para revision
    if exists(SELECT 1 FROM @tempCalls WHERE user_id=0 and virtualAgentId=0 and IsVoicemail=0)
    begin
        delete FROM @tempCalls WHERE user_id=0 and virtualAgentId=0 and IsVoicemail=0 and  datediff(hh,cal_inicio,getdate())<8
    end
        IF EXISTS (SELECT 1 FROM @tempCalls WHERE user_id=0 and virtualAgentId=0 and IsVoicemail=0)
    BEGIN
                delete A from ccAVRSTransfer A
                inner join @tempCalls t on A.id=t.avrsId
                where t.user_id=0 and t.virtualAgentId=0 and t.IsVoicemail=0
        END

    -- Si no hay registros con IsVoicemail, simplemente devolver los resultados de la variable tipo tabla
    SELECT * FROM @tempCalls;

END
ELSE IF @action = 2
BEGIN
    Delete A
    from ccAVRSTransfer A
    inner join dbo.fn_RIASplitDelimited(@ids,'','') t on A.id=t.Value

END
END;
'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList_Static]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList_Static]
    @telephone NVARCHAR(30) = NULL,
    @ln_id INT,
    @calKey VARCHAR(40) = NULL,
    @skipWorkingCleanup BIT = 0 -- 0 = limpia WT/CS, 1 = solo inserta en ccListaNegra
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @telefonoLimpio VARCHAR(30);

    IF @telephone IS NULL OR @telephone = ''''
        RETURN;

    SET @telefonoLimpio = CONVERT(VARCHAR(30), dbo.Limpia(@telephone));

    IF @telefonoLimpio IS NULL OR @telefonoLimpio = ''''
        RETURN;
 
    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.ccListaNegra with(nolock)
        WHERE idtipolista = @ln_id
            AND telefono = @telefonoLimpio
            AND (calKey = @calKey OR (calKey IS NULL AND @calKey IS NULL))
    )
    BEGIN       

        INSERT INTO dbo.ccListaNegra
        (
            telefono,
            idtipolista,
            HashKey,
            calKey
        )
        VALUES
        (
            @telefonoLimpio,
            @ln_id,
            dbo.hashList(@calKey),
            @calKey
        );

        INSERT INTO dbo.cchistoriallistanegra
        (
            telefono,
            idtipomov,
            idtipolista
        )
        VALUES
        (
            @telefonoLimpio,
            7,
            @ln_id
        );

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.ccDNCQueue
            WHERE telefono = @telefonoLimpio
              AND ln_id = @ln_id
              AND (calKey = @calKey OR (calKey IS NULL AND @calKey IS NULL))
        )
        BEGIN
            INSERT INTO dbo.ccDNCQueue (telefono, ln_id, calKey)
            VALUES (@telefonoLimpio, @ln_id, @calKey);
        END
    END
END
'
    exec (@sql)
    

    SET @process = 'CREATE PROCEDURE ccsp_RIACATNotReadyTypes'
    SET @sql = 'CREATE PROCEDURE ccsp_RIACATNotReadyTypes
    @TipoNotReady_id varchar(5)='''',
    @Descripcion varchar(30)='''',
    @Time_Acum varchar(10)='''',
    @Time_xEv varchar(5)='''',
    @Pas_Sup varchar(2)='''',
    @NextStatus varchar(5)='''',
    @graphic_id varchar(5)='''',
    @Type varchar(1)='''',
    @IsSup int = null,
    @super_id as int = null,
    @agent_id as int = null
    AS
    set nocount on
    DECLARE @sql nvarchar(4000), @graph nvarchar(1000), @id smallint, @newGraph smallint
    DECLARE @NotReadybyCampACD INT;
    
    if @Type=0
    begin
        SELECT TipoNotReady_id, Descripcion FROM ccTipoNotReady WITH(NOLOCK) WHERE StatusTipoNotReady=1
        return(0)
    end
    
    if @Type=6 -- LOAD by setting
    begin
        SELECT @Type = valor FROM ccSettings WHERE setting_id = 87;
        SELECT @NotReadybyCampACD = valor FROM ccSettings WHERE setting_id = 135;
        CREATE TABLE #NotReadyData (
            TipoNotReady_id INT,
            NumEvents VARCHAR(6)
        );
        IF (@NotReadybyCampACD = 0)
        BEGIN
            INSERT INTO #NotReadyData (TipoNotReady_id, NumEvents)
            SELECT 
                a1.TipoNotReady_id,
                dbo.NeventsNRdisp(@agent_id, a1.tiponotready_id, GETDATE()) AS NumEvents
            FROM 
                ccTipoNotReady a1
            WHERE 
                a1.TipoNotReady_id > 0 
                AND a1.IsSup = 0;
        END
        ELSE IF (@NotReadybyCampACD = 1)
        BEGIN
            INSERT INTO #NotReadyData (TipoNotReady_id, NumEvents) -- Ticket #7674 
            SELECT 
                t.TipoNotReady_id,
                MAX(t.NumEvents) AS NumEvents
            FROM (
                SELECT 
                    a1.TipoNotReady_id,
                    dbo.NeventsNRdisp(@agent_id, a1.tiponotready_id, GETDATE()) AS NumEvents
                FROM 
                    ccTipoNotReady a1
                INNER JOIN 
                    ccUnavailableRelation a4 ON a4.idunavailable = a1.tiponotready_id
                WHERE 
                    a1.TipoNotReady_id > 0 
                    AND a1.IsSup = 0
                    AND a4.idCampACD IN (
                        SELECT DISTINCT(inbound_id) FROM ccInboundAgentes WHERE user_id = @agent_id
                    )
                    AND a4.type = 0
    
                UNION ALL
    
                SELECT 
                    a1.TipoNotReady_id,
                    dbo.NeventsNRdisp(@agent_id, a1.tiponotready_id, GETDATE()) AS NumEvents
                FROM 
                    ccTipoNotReady a1
                INNER JOIN 
                    ccUnavailableRelation a4 ON a4.idunavailable = a1.tiponotready_id
                WHERE 
                    a1.TipoNotReady_id > 0 
                    AND a1.IsSup = 0
                    AND a4.idCampACD IN (
                        SELECT DISTINCT(cam_id) FROM ccCampsAgente WHERE user_id = @agent_id
                    )
                    AND a4.type = 1
            ) t
            GROUP BY 
                t.TipoNotReady_id; -- Change for TT#7674
        END
    
        IF @Type = 4 
        BEGIN
            SELECT 
                a1.TipoNotReady_id, 
                a1.Descripcion, 
                a1.Time_Acum, 
                a1.Time_xEv, 
                a1.Pas_Sup, 
                a1.NextStatus, 
                frame, 
                a1.IsSup,
                CASE 
                    WHEN nr.NumEvents IS NULL THEN 1
                    WHEN (nr.NumEvents = ''n'' OR nr.NumEvents > 0) THEN 1 
                    ELSE 0 
                END AS expiredAttempts 
            FROM 
                ccTipoNotReady a1
            INNER JOIN 
                ccRIAnotreadyGraph a2 ON a1.tiponotready_id = a2.tiponotready_id
            INNER JOIN 
                ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
            INNER JOIN 
                ccsupervisor_notready snd ON a1.tiponotready_id = snd.tiponotready_id AND snd.user_id = @super_id
            INNER JOIN 
                #NotReadyData nr ON a1.tiponotready_id = nr.TipoNotReady_id
            WHERE 
                a1.TipoNotReady_id > 0 
                AND a1.StatusTipoNotReady = 1;
        END
        ELSE 
        BEGIN
            SELECT 
                a1.TipoNotReady_id, 
                a1.Descripcion, 
                a1.Time_Acum, 
                a1.Time_xEv, 
                a1.Pas_Sup, 
                a1.NextStatus, 
                frame, 
                a1.IsSup,
                CASE 
                    WHEN nr.NumEvents IS NULL THEN 1
                    WHEN (nr.NumEvents = ''n'' OR nr.NumEvents > 0) THEN 1 
                    ELSE 0 
                END AS expiredAttempts
            FROM 
                ccTipoNotReady a1
            INNER JOIN 
                ccRIAnotreadyGraph a2 ON a1.tiponotready_id = a2.tiponotready_id
            INNER JOIN 
                ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
            LEFT JOIN 
                #NotReadyData nr ON a1.tiponotready_id = nr.TipoNotReady_id
            WHERE 
                a1.TipoNotReady_id > 0 
                AND a1.IsSup = CASE 
                    WHEN @Type = 1 THEN (SELECT valor FROM ccSettings WHERE setting_id = 28)
                    WHEN @Type = 2 THEN a1.IsSup 
                    ELSE 1 
                END
                AND a1.StatusTipoNotReady = 1;
        END
    
        DROP TABLE #NotReadyData;
        return(0)
    end
    
    if @Type=1 -- LOAD
    begin
        select @NotReadybyCampACD = valor from ccsettings where setting_id = 135
        
        if (@NotReadybyCampACD = 0)
        begin
            SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
            FROM ccTipoNotReady a1 
            inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
            inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
            where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
        end
        else if (@NotReadybyCampACD = 1)
            begin
                SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
                FROM ccTipoNotReady a1 
                inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
                inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
                inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
                where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
                and a4.idCampACD in (select distinct(cam_id) from ccSupervisorCam where user_id = @super_id)
                AND a4.type = 0
                union
                SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
                FROM ccTipoNotReady a1 
                inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
                inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
                inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
                where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
                and a4.idCampACD in (select distinct(cam_id) from ccSupervisorCam where user_id = @super_id)
                AND a4.type = 1
            end
        return(0)
    end
    
    If @Type=2 -- INSERT
    begin
        if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Descripcion)
        begin       
            select 1
            return(0)
        end
        if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=0 and Descripcion=@Descripcion)
            begin       
                select @id=TipoNotReady_id from ccTipoNotReady where Descripcion=@Descripcion
                update ccTipoNotReady set 
                Time_acum=@Time_Acum,
                Time_xEv=@Time_xEv,
                Pas_Sup=@Pas_Sup,
                NextStatus=@NextStatus,
                IsSup=@IsSup,
                StatusTipoNotReady=1
                where Descripcion=@Descripcion
                If not exists(select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
                    Begin
                        insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
                    End
        
                insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
                return(0)       
            end
        If not exists(select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
        Begin
            insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
        End
    
        insert ccTipoNotReady (Descripcion, Time_Acum, Time_xEv, Pas_Sup, NextStatus, IsSup,StatusTipoNotReady) 
        select @Descripcion, @Time_Acum, @Time_xEv, @Pas_Sup, @NextStatus, @IsSup,1
        select @id=SCOPE_IDENTITY()
        insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
        return(0)
    end
    
    If @Type=3 -- DELETE
    begin
        exec ccsp_AdminNotready 3,0,@TipoNotReady_id,0
        delete ccRIANotReadyGraph where tipoNotReady_id = @TipoNotReady_id
        update ccTipoNotReady set StatusTipoNotReady=0 where tipoNotReady_id = @TipoNotReady_id
    end
    
    if(@Type=4) --UPDATE
    begin
    
        if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Descripcion)
        begin       
            select @Descripcion=''''
        end
    
        update ccTipoNotReady set 
        Descripcion=case @Descripcion when '''' then Descripcion else @Descripcion end,
        Time_Acum=case @Time_Acum when '''' then Time_Acum else @Time_Acum end,
        Time_xEv=case @Time_xEv when '''' then Time_xEv else @Time_xEv end,
        Pas_Sup=case @Pas_Sup when '''' then Pas_Sup else @Pas_Sup end,
        NextStatus=case @NextStatus when '''' then NextStatus else @NextStatus end,
        IsSup=ISNULL(@IsSup,IsSup)
        where TipoNotReady_id=@TipoNotReady_id
    
        IF ISNULL(@graphic_id,'''') not in('''')
        BEGIN
            If not exists (select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
            begin
                insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
            end
    
            select @graph = graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
            update ccRIANotReadyGraph set graphic_id=cast(@graph as smallint) where TipoNotReady_id=cast(@TipoNotReady_id as tinyint)
        END
        return(0)
    end
    
    if @Type = 7 -- LOAD
        begin
            SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
            FROM ccTipoNotReady a1 
            inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
            inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
            where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
            return(0)
        end
    
    if @Type = 8 -- Check admin permission
        begin
            select @Type = valor from ccSettings where setting_id = 87
    
            if @Type = 4 begin
                SELECT CAST( count(snd.TipoNotReady_id) AS BIT) AS hasPermission
                FROM ccTipoNotReady a1 
                inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
                inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
                inner join ccsupervisor_notready snd on (a1.tiponotready_id = snd.tiponotready_id and snd.user_id = @super_id)
                where a1.TipoNotReady_id = @TipoNotReady_id 
                and a1.StatusTipoNotReady=1
            end
            else begin
                SELECT CAST(1 AS bit) AS  hasPermission
            end
        end'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_OUTGetCallsInfo_AllCamps]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTGetCallsInfo_AllCamps]
@Tipo as tinyint= 1,
@cam_id as smallint = 0,
@sup_id as smallint= 0
AS

declare @mToday as smalldatetime
            
select @mToday = convert(smalldatetime, convert(varchar(11), getdate() ), 101)
if @Tipo = 0
begin
    SELECT cam_id, cam_descripcion, 0 AS pContesta, 0 AS pOcupado, 0 AS pNoContesta, 0 AS pFaxModem, 0
AS pNoService, 0 AS Marcaciones, 0 AS Contestan, 0 AS Ocupado, 0 AS NoContesta, 0 AS FaxModem, 0 AS NoService
FROM ccCamps
        ORDER BY cam_id;
end

else if @Tipo = 1
begin
    select L.cam_id, L.Campana,
    ((L.Contestan*100)/ L.Marcaciones) as pContesta,
    ((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
    ((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
    ((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
    ((L.NoService*100)/ L.Marcaciones) as pNoService,
    L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
    ,L.Otro,L.Cancelado,L.buzon,L.NoDialTone,L.congestion
    ,isnull(Assigned,0) As Assigned,isnull(Attended,0) As Attended,isnull(Abandon,0) As Abandoned
    from (
    select cam_id, '''' as Campana,
    count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
    count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
    count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
    count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
    count(*) as Marcaciones
    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Otro
    ,count(case tipoResDial_id when 13 then 1 else null end) as Cancelado
    ,count(case tipoResDial_id when 11 then 1 else null end) as buzon
    ,count(case tipoResDial_id when 5 then 1 else null end) as NoDialTone
    ,count(case tipoResDial_id when 12 then 1 else null end) as congestion

    from ccoLogDials with(nolock)
    Where fecha >  @mToday
     and (@cam_id=0 or cam_id=@cam_id)
    group by cam_id
    ) L 
    left join (select 
    cam_id
    ,count(case statuscall_id when 6 then 1 else null end) as Abandon
    ,count(*) as Contesta
    ,count(case when statuscall_id in(11, 12,15,16)  then 1 else null end) as [Assigned]
    ,count(case statuscall_id when 13 then 1 else null end) as [Attended]
    from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
    where cal_Inicio > @mToday
    and (@cam_id=0 or cam_id=@cam_id)
    group by cam_id) callsOut on L.cam_id = callsOut.cam_id
              
    order by Campana

end

else if @Tipo = 2
begin
    select cam_id, L.Campana,
    ((L.Contestan*100)/ L.Marcaciones) as pContesta,
    ((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
    ((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
    ((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
    ((L.NoService*100)/ L.Marcaciones) as pNoService,
    L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
    from (
    select C.cam_id as cam_id, cam_descripcion as Campana,
    count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
    count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
    count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
    count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
    count(*) as Marcaciones
    from ccoLogDials L with(nolock)
    inner join ccCamps C on L.cam_id=C.cam_id
    Where fecha >  @mToday
    group by C.cam_id, cam_descripcion
    ) L order by Campana
end

else if @Tipo = 3 --Busqueda por campa?a
begin
    select L.cam_id,
    L.Calls, L.Answer, L.Busy, L.NoAnswer, L.Fax, L.NoService
    ,L.Other,L.Canceled,L.Machine,L.NoTone,L.Congestion, isnull(callsOut.Abandon,0) as Abandon
    from (
    select cam_id,
    count(case tipoResDial_id when 1 then 1 else null end) as Answer,
    count(case tipoResDial_id when 2 then 1 else null end) as Busy,
    count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer,
    count(case tipoResDial_id when 4 then 1 else null end) as Fax,
    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
    count(*) as Calls
    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
    ,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
    ,count(case tipoResDial_id when 11 then 1 else null end) as Machine
    ,count(case tipoResDial_id when 5 then 1 else null end) as NoTone
    ,count(case tipoResDial_id when 12 then 1 else null end) as Congestion

    from ccoLogDials with(nolock)
    Where cam_id = @cam_id
    and fecha >  @mToday
    group by cam_id
    ) L 
    left join (select 
    cam_id,
    count(case statuscall_id when 6 then 1 else null end) as Abandon,
    count(*) as Contesta    
    from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
    where cal_Inicio > @mToday
    group by cam_id) callsOut on L.cam_id = callsOut.cam_id

end

else if @Tipo = 4-- Busqueda por campa?as asociadas a admin
begin
    select L.cam_id,
    L.Calls, L.Answer, L.Busy, L.NoAnswer, L.Fax, L.NoService
    ,L.Other,L.Canceled,L.Machine,L.NoTone,L.Congestion, isnull(callsOut.Abandon,0) as Abandon
    ,isnull(Assigned,0) As Assigned,isnull(Attended,0) As Attended
    from (
    select logDials.cam_id,
    count(case tipoResDial_id when 1 then 1 else null end) as Answer,
    count(case tipoResDial_id when 2 then 1 else null end) as Busy,
    count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer,
    count(case tipoResDial_id when 4 then 1 else null end) as Fax, 
    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
    count(*) as Calls
    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
    ,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
    ,count(case tipoResDial_id when 11 then 1 else null end) as Machine
    ,count(case tipoResDial_id when 5 then 1 else null end) as NoTone
    ,count(case tipoResDial_id when 12 then 1 else null end) as Congestion
    from ccoLogDials logDials with(nolock)
    right join (select distinct cam_id from ccSupervisorCam supCam where user_id=@sup_id) B ON logDials.cam_id = B.cam_id
    Where fecha >  @mToday
    group by logDials.cam_id
    ) L 
    left join (select 
    cam_id
    ,count(case statuscall_id when 6 then 1 else null end) as Abandon
    ,count(*) as Contesta
    ,count(case when statuscall_id in(11, 12,15,16)  then 1 else null end) as [Assigned]
    ,count(case statuscall_id when 13 then 1 else null end) as [Attended]
    from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
    where cal_Inicio > @mToday
    group by cam_id) callsOut on L.cam_id = callsOut.cam_id
    order by L.cam_id
end
else if @Tipo = 5-- lista campañas
begin
;with callResult as(
select logDials.cam_id,
    count(*) as Calls,
    count(case tipoResDial_id when 1 then 1 else null end) as Answer,
    count(case tipoResDial_id when 2 then 1 else null end) as Busy,
    count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer          
    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
    ,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
    ,count(case tipoResDial_id when 11 then 1 else null end) as Machine         
    from ccoLogDials logDials with(nolock,index(IX_ccoLogDials))          
    Where fecha >  @mToday
    group by logDials.cam_id
),callData as(
select 
    cam_id                      
    ,count(case when statuscall_id in(11, 12,15,16)  then 1 else null end) as [Assigned]
    ,count(case statuscall_id when 13 then 1 else null end) as [Attended]
    from ccoCallsOut with(nolock,index(IX_ccoCallsOut_13))
    where cal_Inicio > @mToday
    group by cam_id
)

select  cast(L.cam_id as int) as Id,
    C.cam_descripcion as CampName,
    L.Calls, L.Answer,L.NoAnswer,isnull(Attended,0) As Attended , 
    L.Canceled
    ,isnull(Assigned,0) As Assigned
    ,c.aggressionFactor as AggressionFactor
    ,L.Busy
    ,L.Machine
    ,isnull(Other,0) as Other
    ,area.AreaName as Area
    from callResult as L 
    inner join ccCamps C on L.cam_id=C.cam_id
    inner join ccRIACat_Areas area on area.IDArea=c.IDArea
    left join callData callsOut on L.cam_id = callsOut.cam_id
        
    order by L.cam_id

end
    
else if @Tipo = 6
begin
    select 
    cam_id
    ,count(case statuscall_id when 6 then 1 else null end) as Abandon    
    ,count(case when statuscall_id in(11, 12,15,16)  then 1 else null end) as [Assigned]    
    from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
    where cal_Inicio > @mToday
    and cam_id=@cam_id
    group by cam_id

end'
    exec (@sql)
    

   

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_PhoneInBL]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_PhoneInBL]
@action as tinyint,
@cam_id as smallint = null,
@telefono as varchar(30) = null,
@cal_key as varchar(40) = null,
@telefono2 varchar(30) = null,
@telefono3 varchar(30) = null,
@telefono4 varchar(30) = null,
@telefono5 varchar(30) = null,
@insertRow nvarchar(max) =null

AS

declare @sql nvarchar(max)
DECLARE @tableName NVARCHAR(255)

if @action = 1 begin
    if (select dbo.ValidateBlackListPhone(@telefono,@cam_id,@cal_key)) = 1 begin
        select 1 as IsBlackList
    end
    else begin
        select 0 as IsBlackList
    end
end
else if @action =2 begin
    DECLARE @hKey BIGINT = dbo.hashList(@cal_key);

    ;WITH Phones AS (
      SELECT * FROM (
        SELECT 1 AS ord, dbo.hashPhone(@telefono) AS hTel
        UNION ALL
        SELECT 2, dbo.hashPhone(@telefono2)
        UNION ALL
        SELECT 3, dbo.hashPhone(@telefono3)
        UNION ALL
        SELECT 4, dbo.hashPhone(@telefono4)
        UNION ALL
        SELECT 5, dbo.hashPhone(@telefono5)
      ) AS phones
      WHERE hTel IS NOT NULL
    )
    SELECT
      MAX(CASE WHEN p.ord = 1 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList,
      MAX(CASE WHEN p.ord = 2 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList2,
      MAX(CASE WHEN p.ord = 3 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList3,
      MAX(CASE WHEN p.ord = 4 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList4,
      MAX(CASE WHEN p.ord = 5 AND m.match_flag = 1 THEN 1 ELSE 0 END) AS hasBlackList5
    FROM Phones p
    LEFT JOIN (
      SELECT
        cn.Hashtel,
        cn.HashKey,
        cl.cam_id,
        1 AS match_flag
      FROM camplistanegra cl with(nolock)
      Inner JOIN cclistanegra  cn with(nolock) ON cn.idtipolista = cl.idtipolista AND (cn.HashKey IS NULL OR cn.HashKey = @hKey)
      WHERE cl.STATUS = 1
      and cl.cam_id = @cam_id
    ) m
      ON m.Hashtel  = p.hTel
end
else if @action =3 begin
    exec [ccsp_PhoneInBL] @action=6,@cam_id=@cam_id
    set @tableName = ''PhoneListTemp_'' + CAST(@cam_id AS VARCHAR);

    set @sql=''CREATE TABLE ''+@tableName+''(
        callout_id INT
        , hKey bigint
        , hTel bigint
        , ord int
        )
        CREATE NONCLUSTERED INDEX IX_''+@tableName+''_1 ON ''+@tableName+''(hTel, hKey);
        ''
    --print(@sql)
    exec(@sql)
end
else if @action = 4 begin
    exec(@insertRow)
end

else if @action = 5 begin
    set @tableName = ''PhoneListTemp_'' + CAST(@cam_id AS VARCHAR);

    SET @sql = ''SELECT 
    p.callout_id,

    MAX(CASE WHEN p.ord = 1 AND n.Hashtel IS NOT NULL THEN 1 ELSE 0 END) AS hasBlackList,
    MAX(CASE WHEN p.ord = 2 AND n.Hashtel IS NOT NULL THEN 1 ELSE 0 END) AS hasBlackList2,
    MAX(CASE WHEN p.ord = 3 AND n.Hashtel IS NOT NULL THEN 1 ELSE 0 END) AS hasBlackList3,
    MAX(CASE WHEN p.ord = 4 AND n.Hashtel IS NOT NULL THEN 1 ELSE 0 END) AS hasBlackList4,
    MAX(CASE WHEN p.ord = 5 AND n.Hashtel IS NOT NULL THEN 1 ELSE 0 END) AS hasBlackList5

FROM '' + @tableName + '' p
LEFT JOIN cclistanegra n WITH (NOLOCK) 
    ON p.hTel = n.Hashtel 

LEFT JOIN camplistanegra cl 
    ON cl.idtipolista = n.idtipolista 
    AND cl.status = 1 
    AND cl.cam_id =  @cam_id

GROUP BY p.callout_id
    OPTION (RECOMPILE);
    '';
--    print(@sql)
    EXEC sp_executesql @sql, N''@cam_id INT'', @cam_id = @cam_id;

end

else if @action = 6 begin
    set @tableName = ''PhoneListTemp_'' + CAST(@cam_id AS VARCHAR);

    set @sql = ''if exists( select * from sys.tables where name=''''''+@tableName+'''''') begin
    DROP TABLE ''+@tableName+''
end'';

    EXEC sp_executesql @sql;
end
'
    exec (@sql)
    

    SET @process = 'CREATE PROCEDURE [dbo].[ccsp_ProcessDNCQueue]'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_ProcessDNCQueue]
    @BatchSize INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LockResult INT;

    EXEC @LockResult = sp_getapplock
        @Resource = ''dbo.ccsp_ProcessDNCQueue'',
        @LockMode = ''Exclusive'',
        @LockOwner = ''Session'',
        @LockTimeout = 0;

    IF @LockResult < 0
        RETURN;

    BEGIN TRY

        /* Recupera registros atorados en procesando */
        UPDATE dbo.ccDNCQueue
           SET status = 0,
               started_at = NULL
         WHERE status = 1
           AND started_at < DATEADD(MINUTE, -10, GETDATE());

        IF OBJECT_ID(''tempdb..#QueueBatch'') IS NOT NULL DROP TABLE #QueueBatch;
        CREATE TABLE #QueueBatch
        (
            QueueId BIGINT NOT NULL PRIMARY KEY,
            telefono VARCHAR(30) NOT NULL,
            ln_id INT NOT NULL,
            calKey VARCHAR(40) NULL
        );

        ;WITH cte AS
        (
            SELECT TOP (@BatchSize)
                   q.QueueId,
                   q.telefono,
                   q.ln_id,
                   q.calKey
            FROM dbo.ccDNCQueue q WITH (READPAST, UPDLOCK, ROWLOCK)
            WHERE q.status = 0
            ORDER BY q.QueueId
        )
        INSERT INTO #QueueBatch (QueueId, telefono, ln_id, calKey)
        SELECT QueueId, telefono, ln_id, calKey
        FROM cte;

        IF NOT EXISTS (SELECT 1 FROM #QueueBatch)
        BEGIN
            DROP TABLE #QueueBatch;
            EXEC sp_releaseapplock
                @Resource = ''dbo.ccsp_ProcessDNCQueue'',
                @LockOwner = ''Session'';
            RETURN;
        END

        UPDATE q
           SET q.status = 1,
               q.started_at = GETDATE(),
               q.retry_count = ISNULL(q.retry_count, 0) + 1,
               q.error_message = NULL
        FROM dbo.ccDNCQueue q
        INNER JOIN #QueueBatch b
            ON b.QueueId = q.QueueId;

        IF OBJECT_ID(''tempdb..#mycamps'') IS NOT NULL DROP TABLE #mycamps;
        CREATE TABLE #mycamps
        (
            QueueId BIGINT NOT NULL,
            cam_id INT NOT NULL,
            PRIMARY KEY (QueueId, cam_id)
        );

        INSERT INTO #mycamps (QueueId, cam_id)
        SELECT DISTINCT
               b.QueueId,
               cln.cam_id
        FROM #QueueBatch b
        INNER JOIN dbo.Camplistanegra cln
            ON cln.idtipolista = b.ln_id
        INNER JOIN dbo.ccCamps c
            ON c.cam_id = cln.cam_id
        WHERE c.CampType NOT IN (5,7);

        IF OBJECT_ID(''tempdb..#AffectedCalls'') IS NOT NULL DROP TABLE #AffectedCalls;
        CREATE TABLE #AffectedCalls
        (
            QueueId BIGINT NOT NULL,
            callout_id INT NOT NULL,
            cam_id INT NOT NULL,
            cal_key VARCHAR(40) NULL,
            cal_telefono VARCHAR(30) NULL,
            cal_telefono2 VARCHAR(30) NULL,
            cal_telefono3 VARCHAR(30) NULL,
            cal_telefono4 VARCHAR(30) NULL,
            cal_telefono5 VARCHAR(30) NULL,
            PRIMARY KEY (QueueId, callout_id)
        );

        INSERT INTO #AffectedCalls
        (
            QueueId,
            callout_id,
            cam_id,
            cal_key,
            cal_telefono,
            cal_telefono2,
            cal_telefono3,
            cal_telefono4,
            cal_telefono5
        )
        SELECT DISTINCT
               b.QueueId,
               a.callout_id,
               a.cam_id,
               a.cal_key,
               a.cal_telefono,
               a.cal_telefono2,
               a.cal_telefono3,
               a.cal_telefono4,
               a.cal_telefono5
        FROM #QueueBatch b
        INNER JOIN #mycamps mc
            ON mc.QueueId = b.QueueId
        INNER JOIN dbo.ccoCallsOutSource a WITH (NOLOCK)
            ON a.cam_id = mc.cam_id
        WHERE b.telefono IN
        (
            a.cal_telefono,
            a.cal_telefono2,
            a.cal_telefono3,
            a.cal_telefono4,
            a.cal_telefono5
        );

        IF OBJECT_ID(''tempdb..#ToRemove'') IS NOT NULL DROP TABLE #ToRemove;
        CREATE TABLE #ToRemove
        (
            QueueId BIGINT NOT NULL,
            callout_id INT NOT NULL,
            cam_id INT NOT NULL,
            pos TINYINT NOT NULL,
            telefono VARCHAR(30) NOT NULL,
            cal_key VARCHAR(40) NULL,
            PRIMARY KEY (QueueId, callout_id, pos)
        );

        INSERT INTO #ToRemove
        (
            QueueId,
            callout_id,
            cam_id,
            pos,
            telefono,
            cal_key    
        )
        SELECT
            ac.QueueId,
            ac.callout_id,
            ac.cam_id,
            v.pos,
            v.tel,
            ac.cal_key
        FROM #AffectedCalls ac
        INNER JOIN #QueueBatch b
            ON b.QueueId = ac.QueueId
        CROSS APPLY
        (
            VALUES
                (1, ac.cal_telefono),
                (2, ac.cal_telefono2),
                (3, ac.cal_telefono3),
                (4, ac.cal_telefono4),
                (5, ac.cal_telefono5)
        ) v(pos, tel)
        WHERE ISNULL(v.tel, '''') <> ''''
          AND v.tel = b.telefono;

        /* Limpia solo la posicion encontrada */
        UPDATE cs
           SET cs.cal_telefono = '''',
               cs.iZonaHoraria = 0,
               cs.iZonaHoraria_verano = 0
        FROM dbo.ccoCallsOutSource cs
        INNER JOIN #ToRemove r
            ON r.callout_id = cs.callout_id
           AND r.pos = 1
        WHERE cs.cal_telefono = r.telefono;       
        
        UPDATE cs
           SET cs.cal_telefono2 = '''',
               cs.iZonaHoraria2 = 0,
               cs.iZonaHoraria_verano2 = 0
        FROM dbo.ccoCallsOutSource cs
        INNER JOIN #ToRemove r
            ON r.callout_id = cs.callout_id
           AND r.pos = 2
        WHERE cs.cal_telefono2 = r.telefono;  

        UPDATE cs
           SET cs.cal_telefono3 = '''',
               cs.iZonaHoraria3 = 0,
               cs.iZonaHoraria_verano3 = 0
        FROM dbo.ccoCallsOutSource cs
        INNER JOIN #ToRemove r
            ON r.callout_id = cs.callout_id
           AND r.pos = 3
        WHERE cs.cal_telefono3 = r.telefono; 

        UPDATE cs
           SET cs.cal_telefono4 = '''',
               cs.iZonaHoraria4 = 0,
               cs.iZonaHoraria_verano4 = 0
        FROM dbo.ccoCallsOutSource cs
        INNER JOIN #ToRemove r
            ON r.callout_id = cs.callout_id
           AND r.pos = 4
        WHERE cs.cal_telefono4 = r.telefono;

        UPDATE cs
           SET cs.cal_telefono5 = '''',
               cs.iZonaHoraria5 = 0,
               cs.iZonaHoraria_verano5 = 0
        FROM dbo.ccoCallsOutSource cs
        INNER JOIN #ToRemove r
            ON r.callout_id = cs.callout_id
           AND r.pos = 5
        WHERE cs.cal_telefono5 = r.telefono;



        /* Elimina de working table si despues de limpiar ya no quedan telefonos */
        DELETE wt
        FROM dbo.ccoWorkingTable wt
        INNER JOIN
        (
            SELECT DISTINCT callout_id
            FROM #ToRemove
        ) x
            ON x.callout_id = wt.callout_id
        INNER JOIN dbo.ccoCallsOutSource cs
            ON cs.callout_id = wt.callout_id
        WHERE NULLIF(cs.cal_telefono, '''') IS NULL
          AND NULLIF(cs.cal_telefono2, '''') IS NULL
          AND NULLIF(cs.cal_telefono3, '''') IS NULL
          AND NULLIF(cs.cal_telefono4, '''') IS NULL
          AND NULLIF(cs.cal_telefono5, '''') IS NULL;


        UPDATE wt
        SET wt.cal_telefono = COALESCE(
                NULLIF(cs.cal_telefono,''''),
                NULLIF(cs.cal_telefono2,''''),
                NULLIF(cs.cal_telefono3,''''),
                NULLIF(cs.cal_telefono4,''''),
                NULLIF(cs.cal_telefono5,''''),
                ''''
            ),
            wt.iZonaHoraria = CASE WHEN NULLIF(cs.cal_telefono,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria END,
            wt.iZonaHoraria_verano = CASE WHEN NULLIF(cs.cal_telefono,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano END,
            wt.iZonaHoraria2 = CASE WHEN NULLIF(cs.cal_telefono2,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria2 END,
            wt.iZonaHoraria_verano2 = CASE WHEN NULLIF(cs.cal_telefono2,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano2 END,
            wt.iZonaHoraria3 = CASE WHEN NULLIF(cs.cal_telefono3,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria3 END,
            wt.iZonaHoraria_verano3 = CASE WHEN NULLIF(cs.cal_telefono3,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano3 END,
            wt.iZonaHoraria4 = CASE WHEN NULLIF(cs.cal_telefono4,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria4 END,
            wt.iZonaHoraria_verano4 = CASE WHEN NULLIF(cs.cal_telefono4,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano4 END,
            wt.iZonaHoraria5 = CASE WHEN NULLIF(cs.cal_telefono5,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria5 END,
            wt.iZonaHoraria_verano5 = CASE WHEN NULLIF(cs.cal_telefono5,'''') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano5 END
        FROM dbo.ccoWorkingTable wt
        INNER JOIN dbo.ccoCallsOutSource cs
            ON cs.callout_id = wt.callout_id
        INNER JOIN
        (
            SELECT DISTINCT callout_id
            FROM #ToRemove
        ) r
            ON r.callout_id = wt.callout_id;

        /* Borra de cola todo el lote procesado correctamente */
        DELETE q
        FROM dbo.ccDNCQueue q
        INNER JOIN #QueueBatch b
            ON b.QueueId = q.QueueId
        WHERE q.status = 1;

        DROP TABLE #ToRemove;
        DROP TABLE #AffectedCalls;
        DROP TABLE #mycamps;
        DROP TABLE #QueueBatch;

        EXEC sp_releaseapplock
            @Resource = ''dbo.ccsp_ProcessDNCQueue'',
            @LockOwner = ''Session'';

    END TRY
    BEGIN CATCH

        DECLARE @ErrorMessage VARCHAR(1000);
        SET @ErrorMessage = ERROR_MESSAGE();

        UPDATE q
           SET q.status = 2,
               q.error_message = LEFT(@ErrorMessage, 1000)
        FROM dbo.ccDNCQueue q
        INNER JOIN #QueueBatch b
            ON b.QueueId = q.QueueId
        WHERE q.status = 1;

        IF OBJECT_ID(''tempdb..#ToRemove'') IS NOT NULL DROP TABLE #ToRemove;
        IF OBJECT_ID(''tempdb..#AffectedCalls'') IS NOT NULL DROP TABLE #AffectedCalls;
        IF OBJECT_ID(''tempdb..#mycamps'') IS NOT NULL DROP TABLE #mycamps;
        IF OBJECT_ID(''tempdb..#QueueBatch'') IS NOT NULL DROP TABLE #QueueBatch;

        EXEC sp_releaseapplock
            @Resource = ''dbo.ccsp_ProcessDNCQueue'',
            @LockOwner = ''Session'';

        THROW;
    END CATCH
END'
    exec (@sql)

    SET @process = 'ALTER FUNCTION [dbo].[hashPhone] (@phoneNumber varchar(30)) '
    SET @sql = 'ALTER FUNCTION [dbo].[hashPhone] (@phoneNumber varchar(30)) 
RETURNS bigint AS
BEGIN
    set @phoneNumber=dbo.Limpia(@phoneNumber)
    if @phoneNumber='''' or @phoneNumber is null return 0

  return convert(bigint,@phoneNumber) % 99999999999973
END'
    exec (@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_ValidateManualRotation]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ValidateManualRotation]
@camId INT
AS
set nocount on

SELECT TOP 1 CONVERT(int, ISNULL(selectRotationManualDialing, 0)) as selectRotationManualDialing FROM ccCamps WHERE cam_id = @camId;

set nocount off'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccspGalatea_Finder]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspGalatea_Finder] 
@action INT, 
@userId INT = 0, 
@conversationId BIGINT = 0,
@isSuperUser bit=0,
@callId int = 0,
@callType int = 0
AS
IF @action = 1
    BEGIN--trae el nombre de la base de datos en BX
    if @isSuperUser =0 begin

            SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, c.cam_descripcion AS label
            FROM ccRIAWorkGroupUsers Wguser
                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                INNER JOIN ccCamps c ON WGCam.IdCampEsp = c.cam_id
                                        AND WGCam.Tipo = 1
            WHERE Wguser.User_id = @userId
            UNION
            SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, inb.descripcion AS label
            FROM ccRIAWorkGroupUsers Wguser
                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                INNER JOIN ccInbound inb ON WGCam.IdCampEsp = inb.Inbound_id
                                            AND WGCam.Tipo = 0
            WHERE Wguser.User_id = @userId;
        end
        else begin
        SELECT CAST(c.cam_id AS INT) AS [Value], CAST(2 AS INT) AS callType, c.cam_descripcion AS label FROM ccCamps c
        UNION
        SELECT CAST(inb.Inbound_id AS INT) AS [Value], CAST(1 AS INT) AS callType, inb.descripcion AS label FROM ccInbound inb;
        end
        RETURN 0;
END;
IF @action = 2
    BEGIN
    if @isSuperUser =0 begin
        WITH WgId
            AS (SELECT IDWG
                FROM ccRIAWorkGroupUsers Wguser
                WHERE Wguser.User_id = @userId)
            SELECT DISTINCT 
                    CAST(Wguser.User_id AS INT) AS [Value], CONCAT(ccUsers.Nombres, '' '', ccUsers.ApellidoPaterno, '' '', ccUsers.ApellidoMaterno)  AS label
            FROM ccRIAWorkGroupUsers Wguser
                INNER JOIN WgId ON Wguser.IDWG = WgId.IDWG
                INNER JOIN ccUsers ON ccUsers.User_id = Wguser.User_id
                                        AND TipoUser_id = 1;
end
else begin
        select CAST(ccUsers.User_id AS INT) AS [Value], CONCAT(ccUsers.Nombres, '' '', ccUsers.ApellidoPaterno, '' '', ccUsers.ApellidoMaterno)  AS label
        from ccUsers where TipoUser_id = 1;
end
        RETURN 0;
END;
IF @action = 3
            BEGIN--Informacion de la conversacion de whatsApp
                SELECT A.ConversationID, A.inboundId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneACD AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID, C.Login AS UserName
                        ,(cast(sum(A.tConversation) / 3600 as varchar(10)) + '':'' + 
                        right(''0'' + cast((sum(A.tConversation) % 3600) / 60 as varchar(10)), 2) + '':'' + 
                        right(''0'' + cast(sum(A.tConversation) % 60 as varchar(10)), 2)) as Duration
                FROM ccWhatsAppConversations A
                    LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
                    LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
                    LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
                    LEFT JOIN ccRIAInboundGraph graph ON graph.Inbound_id = A.inboundId
                    LEFT JOIN ccUsers C ON A.agentId = C.User_id
                WHERE A.conversationId = @conversationId
                group by A.conversationId, A.inboundId, graph.graphic_id, A.phoneACD, A.clientId, B.descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc, conversationDate, requestDate, A.agentId, C.Login;

                RETURN 0;
        END;
IF @action = 4
            BEGIN--Informacion de la conversacion de whatsApp out
                SELECT A.ConversationID, A.camId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneCamp AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.cam_descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID, C.Login AS UserName
                        ,(cast(sum(A.tConversation) / 3600 as varchar(10)) + '':'' + 
                        right(''0'' + cast((sum(A.tConversation) % 3600) / 60 as varchar(10)), 2) + '':'' + 
                        right(''0'' + cast(sum(A.tConversation) % 60 as varchar(10)), 2)) as Duration
                FROM ccWhatsAppConversationsOut A
                    LEFT JOIN ccCamps B ON A.camId = B.cam_id
                    LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
                    LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
                    LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = A.camId
                    LEFT JOIN ccUsers C ON A.agentId = C.User_id
                WHERE A.conversationId = @conversationId
                group by A.conversationId, A.camid, graph.graphic_id, A.phoneCamp, A.clientId, B.cam_descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc, conversationDate, requestDate, A.agentId, C.Login;

                RETURN 0;
        END;
IF @action = 5
            BEGIN--Informacion de la conversacion de Chat
                SELECT A.ChatId AS ConversationID, A.inboundId AS CampaignId, A.userId AS AgentID, ISNULL(B.descripcion, ''N/A'') AS CampaignName,
                ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, 
                C.Login AS UserName, A.clientName as Client, ISNULL(A.chatDate, A.requestDate) as DateStart,
                (cast(sum(A.tChatting) / 3600 as varchar(10)) + '':'' + 
                right(''0'' + cast((sum(A.tChatting) % 3600) / 60 as varchar(10)), 2) + '':'' + 
                right(''0'' + cast(sum(A.tChatting) % 60 as varchar(10)), 2)) as Duration
                FROM ccRIAChats A
                    LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
                    LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
                    LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
                    LEFT JOIN ccUsers C ON A.userId = C.User_id
                WHERE A.chatId = @conversationId
                group by A.chatId, A.inboundId, A.userId, A.userId, B.descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc,
                chatDate, requestDate, A.userId, C.Login, tChatting, clientName;

                RETURN 0;
        END;
IF @action = 6
BEGIN
    SELECT cfwadm.FinderWhatsAppMessageId,
            cfwadm.Description,
            cfwadm.OpTagEs,
            cfwadm.OpTagEn,
            cfwadm.OpTagPt FROM dbo.ccFinderWhatsAppDownloadedMessage AS cfwadm
    RETURN 0
END
IF @action = 7
BEGIN
    SELECT [Description] AS [Label],  CAST(calif_id as VARCHAR) + ''|2'' AS [Value] FROM cctipocalifout
    UNION
    SELECT [Description] AS [Label],  CAST(calif_id as VARCHAR) + ''|1'' AS [Value] FROM cctipocalif
    RETURN 0
END
IF @action = 8
BEGIN
    IF @callType = 11
    BEGIN
        SELECT Transcription FROM ccCallsInTranscriptionIA where call_id = @callId
    END
    ELSE IF @callType = 10
    BEGIN 
        SELECT Transcription FROM ccoCallsOutTranscriptionIA where call_id = @callId
    END
END
                
                '
    exec (@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall]

@option int,
@UserID int = 0,
@onChat int = 0,
@campId int = 0
AS
set nocount on
if(@option = 1)
begin
    if (@onChat = 0)
    begin
        declare @mod smallint
        declare @IdArea smallint
        declare @DialingMode tinyint
        select @IdArea = IDArea, @DialingMode = DialingMode from ccUsers where User_id = @UserID
        select @mod = defCampaing from ccRIACat_Areas A
        where A.IDArea = @IdArea
        select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [isDefault],  g.graphic_id, c.cam_ModoManual,
        isnull(c.selectRotativeANI, 0) selectRotativeANI
        , CASE WHEN c.ivrScript <> 0 AND c.callsBySurvey <> 0 THEN 8 ELSE isnull(c.CampType,0) END as CampType,
        CASE WHEN @DialingMode = 1 THEN (select count(1) from ccoWorkingTable nolock where cam_id = c.cam_id) ELSE 0 END AS countJobs,
        isnull(c.timesPreview, 0) timesPreview,
        isnull(ce.zipCodeSchedule, 0) AS zipCodeSchedule
        from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id and c.IDArea = @IdArea
        join ccRIACampsGraph g ON g.cam_id = c.cam_id
        left join ccCampsExtend ce ON ce.cam_id = c.cam_id
        where ca.user_id = @UserID
            and cam_ModoManual = case when @DialingMode = 1 OR (@DialingMode = 0 AND cam_ModoManual in (1,3)) then cam_ModoManual else -1 end AND CampType = CASE WHEN @DialingMode = 1 THEN 6 ELSE CampType END
        order by cam_descripcion
    end
    else
    begin
        select distinct c.cam_id, c.cam_descripcion,  g.graphic_id,  c.cam_ModoManual
        , isnull(c.CampType,0) as CampType,
        isnull(ce.zipCodeSchedule, 0) AS zipCodeSchedule
        from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
        join ccRIACampsGraph g ON g.cam_id = c.cam_id
        join ccCampsExtend ce ON ce.cam_id = c.cam_id
        where ca.user_id = @UserID and manualCallOnChat = 1
        order by cam_descripcion
        SET NOCOUNT OFF;
    end
end
if(@option = 2)
begin
    declare @aniList int
    declare @rotativeAniListId int
    select @aniList = id_anilist, @rotativeAniListId  = rotativeAlgo from ccCamps where cam_id = @campId
    if @rotativeAniListId >0 begin
        select telAni from ccRotativeANIListDetail with(nolock) where id_RAniList = @aniList
    end
    else begin
        select top 0 '''' telAni
    end
end'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns]
@Option AS      SMALLINT,
@CampType AS    SMALLINT = 0,
@WorkgroupId AS INT      = 0,
@Id AS          INT      = 0,
@AdminId AS     SMALLINT = 0,
@PinUpdate AS   SMALLINT = 0,
@LoadId AS      INT      = 0,
@Type AS        SMALLINT = 0,
@InboundType    SMALLINT = 0,
@AreaId         SMALLINT = 0,
@multi_type     varchar(max) = null,
@IsWhatsAppCampaign  bit = 0,
@groupList as varchar (MAX) = NULL,
@CampId AS      SMALLINT = 0
AS
BEGIN
    SET NOCOUNT ON;
IF @Option = 1 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
    IF @WorkgroupId IS NOT NULL BEGIN
        SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId
        ORDER BY IdCampEsp ASC;
    END;
    ELSE BEGIN
        RAISERROR(''ERROR. No existe una lista de campañas con el id de grupo de trabajo especificado'', 18, 1);
    END;
    RETURN 0;
END;
IF @Option = 2 BEGIN-- Get Campaign complete information per Campaign Type and Campaign Id
    IF @CampType = 1 BEGIN-- Campaigns Out
        IF @Id IS NOT NULL BEGIN
            DECLARE @HasWorkingRowsForCampaign BIT = 0, @HasTemplatePaused   bit = 0,
        @HasTemplateDisabled bit = 0;

            IF EXISTS (
                SELECT 1
                FROM dbo.ccoWAWorkingTable AS cwwt
                WHERE cwwt.camId = @Id
            )
            BEGIN
                SET @HasWorkingRowsForCampaign = 1;
            END

            IF EXISTS (
                SELECT 1
                FROM dbo.ccoWAWorkingTable cwwt
                JOIN dbo.ccWhatsAppOutSource cwaos  ON cwaos.WAOut_Id = cwwt.WAOut_id
                JOIN dbo.ccMetaWAOutboundTemplates cmwot ON cmwot.Id = cwaos.TemplateId
                WHERE cwaos.camId = @Id AND cmwot.Status = ''PAUSED''
            ) SET @HasTemplatePaused = 1;

            IF EXISTS(
            SELECT 1 FROM dbo.ccMetaWAOutboundTemplates AS cmwot
                INNER JOIN dbo.ccMetaWhatsAppNumbers AS cmwan
                ON cmwan.MetaId = cmwot.MetaId
                WHERE cmwan.Cam_Id = @Id AND cmwot.Status = ''DISABLED''
                AND cmwot.StatusCW = 1
            )
            BEGIN
                SET @HasTemplateDisabled = 1;
            END

            SELECT DISTINCT
            CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
            isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
            camps.cam_procesando IsStarted,
            ISNULL(a.AreaName, '''') AS Area,
            CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
            CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
            CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10  ELSE isnull(camps.CampType,0) END as OutboundType,
            ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
            a.ToolsTransfer,
            @HasTemplatePaused AS HasTemplatePaused,
            @HasTemplateDisabled AS HasTemplateDisabled,
            @HasWorkingRowsForCampaign AS HasWorkingRowsForCampaign
            FROM ccCamps camps
            LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
            LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
            LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
            WHERE camps.cam_id = @Id
            ORDER BY camps.cam_descripcion ASC;
        END;
        ELSE BEGIN
            RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
        END;
    END;
    ELSE IF @CampType = 0 -- Campaigns In (ACD)
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    SELECT DISTINCT
                    CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted,
                    ISNULL(a.AreaName, '''') AS Area,
                            CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType,
                            a.ToolsTransfer
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
ELSE IF @Option = 3  BEGIN -- Update OverallTotalNew By Campaign

    IF @Id IS NOT NULL BEGIN
        UPDATE ccCampsNvosCB SET  OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id;
    END;
    ELSE BEGIN
        RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
    END;
    RETURN 0;
END;
ELSE IF @Option = 4 -- Update Pin from Campaign per Admin
BEGIN
    IF @Id IS NOT NULL
        AND @AdminId IS NOT NULL
    BEGIN
        IF @PinUpdate = 1
        BEGIN
            INSERT INTO PinedCampaigns (CampId, AdminId, Type)
            VALUES (@Id, @AdminId, @Type);
        END;

        IF @PinUpdate = 0
        BEGIN
            DELETE
            FROM PinedCampaigns
            WHERE CampId = @Id
                AND AdminId = @AdminId
                AND Type = @Type;
        END;
    END;
    ELSE
    BEGIN
        RAISERROR (''ERROR. La campañas o administrador no existen'', 18, 1
                );
    END;

    RETURN 0;
END;

ELSE IF @Option = 5 BEGIN  -- Get Pin from Campaign Ids per Admin
    IF @AdminId IS NOT NULL BEGIN
        SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
        ORDER BY Id ASC;
    END;
    ELSE BEGIN
        RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
    END;
    RETURN 0;
END;
ELSE IF @Option = 6 -- Get Blacklist Ids by Campaign Id
BEGIN
    IF @Id IS NOT NULL
    BEGIN
        DECLARE @BlackListIds VARCHAR(MAX);

        SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR
                    (MAX)), CAST(idtipolista AS VARCHAR(MAX)))
        FROM Camplistanegra
        WHERE cam_id = @Id
            AND STATUS = 1;

        SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
    END;
    ELSE
    BEGIN
        RAISERROR (''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
    END;

    RETURN 0;
END;

ELSE IF @Option = 7 -- Get RegistryListIds Ids by Campaign Id
BEGIN
    IF (
            @Id IS NOT NULL
            AND EXISTS (
                SELECT *
                FROM cccamps
                WHERE cam_id = @Id
                )
            )
    BEGIN
        SELECT TOP 1 list_id
        FROM ccRIARegistryLists
        WHERE cam_id = @Id
            AND STATUS = 2
        ORDER BY list_id DESC;
    END;
    ELSE
    BEGIN        
        RAISERROR (''ERROR. No existe una campaña con el id especificado'', 18, 1);
    END;

    RETURN 0;
END;

ELSE IF @Option = 8 -- Delete RegistryListIds Ids by LoadId
BEGIN
    IF (
            @LoadId IS NOT NULL
            AND EXISTS (
                SELECT *
                FROM ccRIARegistryLists
                WHERE list_id = @loadID
                    AND STATUS <> 0
                )
            )
    BEGIN
        UPDATE ccoCallsOutSource
        SET cal_status = ''5''
        WHERE list_id = @loadID;

        DELETE
        FROM ccoWorkingTable
        WHERE list_id = @LoadId;

        EXEC ccsp_RIARegistryLists @action = 6, @list_id = @LoadId;
    END;
    ELSE
    BEGIN
        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
        RAISERROR (''ERROR. No existe una carga el id especificado'', 18, 1);
    END;

    RETURN 0;
END;

ELSE IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
BEGIN
    DECLARE @table TABLE (camId INT, campType TINYINT, PRIMARY KEY (camId, campType)
        );

    INSERT INTO @table
    SELECT DISTINCT IdCampEsp, Tipo
    FROM ccRIACampEspWG wg
    WHERE wg.IDWG IN (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers
            WHERE IDWG <> @WorkgroupId
                AND User_id = @AdminId
            );

    SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
    FROM @table A
    RIGHT JOIN (
        SELECT wg.IdCampEsp, wg.Tipo
        FROM ccRIACampEspWG wg
        WHERE wg.IDWG = @WorkgroupId
        ) B ON A.camId = B.IdCampEsp
        AND A.campType = B.Tipo
    WHERE A.camId IS NULL
    ORDER BY IdCampEsp;

    RETURN 0;
END;

ELSE IF @option = 10
BEGIN -- Get Agents States with totals per campaign by admin id and campaign type **********************
    DECLARE @date DATETIME = CONVERT(DATE, DATEADD(hh, - 3, GETDATE()));
    DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY (id));
    DECLARE @AgentsList TABLE (id INT, PRIMARY KEY (id));
    DECLARE @tmpCamAgent TABLE (
        camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY (camId, userId)
    );
    DECLARE @AgentStatus TABLE (CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT);
    DECLARE @CurrentStatus TABLE (userId INT, CurrentState INT, IdCampEsp INT, camType INT);
    DECLARE @campDataTotal TABLE (
        camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), NumberOfVirtualAgents INT, PRIMARY KEY (camId)
    );

    INSERT INTO @AdminWorkgroups
    SELECT DISTINCT IDWG
    FROM ccRIAWorkGroupUsers WG, ccUsers_Roles R
    WHERE WG.User_id = @AdminId
        OR (R.User_id = @AdminId AND R.Rol_id = 7);

    INSERT INTO @AgentsList
    SELECT DISTINCT A.User_id
    FROM ccRIAWorkGroupUsers A
    INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
    INNER JOIN ccUsers C ON A.User_id = C.User_id AND C.TipoUser_id = 1
    ORDER BY A.User_id;

    IF @IsWhatsAppCampaign = 1
    BEGIN
        INSERT INTO @tmpCamAgent
        SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, 
               CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
        FROM ccRIACampEspWG campPerWg
        INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
        INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
        INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
        LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp AND @CampType = 0
        LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp AND @CampType = 1
        WHERE C.TipoUser_id = 1
            AND (camps.CampType = 5 or inbound.chat = 5)
            AND campPerWg.Tipo = @CampType
            AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
    END
    ELSE
    BEGIN
        INSERT INTO @tmpCamAgent
        SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, 
               CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
        FROM ccRIACampEspWG campPerWg
        INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
        INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
        INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
        LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp AND @CampType = 0
        LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp AND @CampType = 1
        WHERE C.TipoUser_id = 1
            AND campPerWg.Tipo = @CampType
            AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
    END;

    ;WITH lastState AS (
        SELECT A.user_id, A.fecha,
               CASE WHEN A.currentStatus <= 0 THEN 0 ELSE A.currentStatus END AS currentStatus,
               IdCampEsp, Tipo
        FROM ccLogAgentesDiaLast A WITH(NOLOCK)
        INNER JOIN @AgentsList B ON A.User_id = B.id
        WHERE fecha >= @date
    )
    INSERT INTO @CurrentStatus
    SELECT A.User_id, currentStatus, IdCampEsp, Tipo
    FROM lastState A;

    IF @Id = 0 AND @CampType = 0
    BEGIN
        DELETE FROM @tmpCamAgent WHERE multimediaType = 0;
    END

    DECLARE @MultimediaType SMALLINT = 0, @chatType SMALLINT = 0;

    IF @Id > 0
    BEGIN
        IF @CampType = 1
        BEGIN
            SELECT @MultimediaType = ISNULL(meanContactTypeId, 0) FROM contactMeanOut WHERE camp_id = @Id;
        END
        ELSE
        BEGIN
            SELECT @chatType = ISNULL(chat, 0) FROM dbo.ccInbound WHERE Inbound_id = @Id;
            SELECT @MultimediaType = ISNULL(meanContactTypeId, 0) FROM contactMeanIn WHERE inboundId = @Id;
        END
    END

    IF (@chatType = 1) SET @MultimediaType = 1;

    DECLARE @StateIds VARCHAR(100) = (
        SELECT CASE 
            WHEN @MultimediaType = 5 THEN ''6,34'' 
            WHEN @MultimediaType = 1 THEN ''23'' 
            ELSE ''4,5,6,9'' 
        END
    );

    ;WITH stateDialog AS (
        SELECT CAST(value AS INT) AS CurrentState FROM dbo.fn_RIASplitDelimited(@StateIds,'','')
    )
    INSERT INTO @AgentStatus
    SELECT A.camId, A.userId, B.CurrentState,
    (CASE
        WHEN @chatType = 1 THEN
            CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) THEN 1 ELSE 0 END
        ELSE
            CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) 
                 AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN 1 ELSE 0 END
    END) AS isCampDialog, B.camType
    FROM @tmpCamAgent A
    INNER JOIN @CurrentStatus B ON A.userId = B.userId
    WHERE (@Id = 0 OR A.camId = @Id);

    IF @CampType = 1
    BEGIN
        WITH campDataTotal AS (
            SELECT camId, COUNT(*) AS total
            FROM @tmpCamAgent
            GROUP BY camId
        )
        INSERT INTO @campDataTotal
        SELECT A.camId, B.cam_descripcion, A.total, C.AreaName, ISNULL(va.concurrentSessionsLimit,0)
        FROM campDataTotal A
        INNER JOIN ccCamps B ON A.camId = B.cam_id
        INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
        LEFT JOIN ccVirtualAgent va ON B.cam_id = va.idCampaign AND va.campType = 1;
    END
    ELSE
    BEGIN
        WITH campDataTotal AS (
            SELECT camId, COUNT(*) AS total
            FROM @tmpCamAgent
            GROUP BY camId
        )
        INSERT INTO @campDataTotal
        SELECT A.camId, B.descripcion, A.total, C.AreaName, 0
        FROM campDataTotal A
        INNER JOIN ccInbound B ON A.camId = B.Inbound_id
        INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea;
    END;

    WITH stateCamp AS (
        SELECT A.CampId, 
               COUNT(CASE WHEN A.CurrentState = 3 THEN 1 END) AS ready,
               COUNT(CASE 
                        WHEN A.CurrentState NOT IN (-2, -1, 0, 3, 4, 5, 6, 9, 30, 34, 37) THEN 1 
                        WHEN A.CurrentState IN (6, 4) AND (A.CampId != C.IdCampEsp OR A.campType != @CampType) THEN 1 
                     END) AS notReady,
               COUNT(CASE WHEN A.isCampDialog = 1 OR A.CurrentState = 34 THEN 1 END) AS dialog,
               COUNT(CASE WHEN A.CurrentState <= 0 THEN 1 END) AS disconnected,
               COUNT(CASE WHEN A.CurrentState = 37 THEN 1 END) AS auxiliaryReady
        FROM @AgentStatus A
        INNER JOIN @CurrentStatus C ON A.userId = C.userId
        GROUP BY A.CampId
    )
    SELECT A.camId, A.campName, (A.Total + A.NumberOfVirtualAgents) AS Total, 
           ISNULL(B.ready, 0) AS Ready, 
           ISNULL(B.notReady, 0) AS NotReady, 
           ISNULL(B.dialog, 0) AS Dialog, 
           CASE WHEN B.disconnected IS NULL THEN A.Total 
                ELSE A.Total - ISNULL(B.ready,0) - ISNULL(B.dialog,0) - ISNULL(B.notReady,0) - ISNULL(B.auxiliaryReady,0) 
           END AS Disconnected, 
           ISNULL(B.auxiliaryReady, 0) AS AuxiliaryReady, 
           A.NumberOfVirtualAgents, A.Area
    FROM @campDataTotal A
    LEFT JOIN stateCamp B ON A.camId = B.CampId
    ORDER BY A.campName;

    RETURN 0;
END
ELSE IF @Option = 11
BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
    IF NOT EXISTS (
            SELECT *
            FROM ccUsers_Roles WITH (NOLOCK)
            WHERE User_id = @AdminId
                AND Rol_id = 7
            )
    BEGIN        
        WITH wgId
        AS (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers WITH (NOLOCK)
            WHERE user_id = @AdminId
            )
        SELECT DISTINCT CAST(IdCampEsp AS INT) AS Id
        INTO #tempIds
        FROM ccRIACampEspWG A WITH (NOLOCK)
        INNER JOIN wgId ON wgId.IDWG = A.IDWG
            AND A.Tipo = @CampType;

        IF(@CampType = 1)
        BEGIN
            SELECT Id FROM #tempIds ids
            INNER JOIN ccCamps c on c.cam_id = ids.Id
            WHERE (c.CampType = 5 AND @IsWhatsAppCampaign = 1)
            OR (c.CampType <> 5 AND @IsWhatsAppCampaign = 0)
        END
        ELSE
        BEGIN
            SELECT Id FROM #tempIds ids
            INNER JOIN ccInbound c on c.Inbound_id = ids.Id
            WHERE (c.chat = 5 AND @IsWhatsAppCampaign = 1)
            OR (c.chat <> 5 AND @IsWhatsAppCampaign = 0)
        END
        DROP TABLE #tempIds
    END;
    ELSE
    BEGIN        
        IF @CampType = 1
        BEGIN
            SELECT DISTINCT CAST(cam_id AS INT) AS Id
            FROM ccCamps WITH (NOLOCK)
            WHERE IDArea IS NOT NULL
            AND(CampType = 5 AND @IsWhatsAppCampaign = 1)
            OR (CampType <> 5 AND @IsWhatsAppCampaign = 0)
        END
        ELSE
        BEGIN
            SELECT DISTINCT CAST(Inbound_id AS INT) AS Id
            FROM ccInbound WITH (NOLOCK)
            WHERE IDArea IS NOT NULL
            AND (chat = 5 AND @IsWhatsAppCampaign = 1)
            OR (chat <> 5 AND @IsWhatsAppCampaign = 0)
        END
    END;

    RETURN 0;
END;

ELSE IF @Option = 12
BEGIN-- Get All Campaigns complete information per Campaign Type and Campaign Id
    IF @CampType = 1 -- Campaigns Out
    BEGIN
        ;WITH StopByCamp AS (
        SELECT
            cwaos.camId,
            IsStopDueTemplateStatusChange = CAST(
                CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END AS BIT
            )
        FROM dbo.ccoWAWorkingTable AS cwwt
        INNER JOIN dbo.ccWhatsAppOutSource AS cwaos
            ON cwaos.WAOut_Id = cwwt.WAOut_id
        INNER JOIN dbo.ccMetaWAOutboundTemplates AS cmwot
            ON cmwot.Id = cwaos.TemplateId
        WHERE cmwot.Status IN (''PAUSED'', ''DISABLED'')
        GROUP BY cwaos.camId
        )

        SELECT DISTINCT
        CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
        isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
        camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
        CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
        CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10 ELSE isnull(camps.CampType,0) END as OutboundType,
        ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
        ISNULL(sbc.IsStopDueTemplateStatusChange, 0) AS IsStopDueTemplateStatusChange
        FROM ccCamps camps(NOLOCK)
        INNER JOIN ccRIACampsGraph graph(NOLOCK) ON camps.cam_id = graph.cam_id
        INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = camps.IDArea
        LEFT JOIN ccCampsExtend extended(NOLOCK) ON camps.cam_id = extended.cam_id
        LEFT  JOIN StopByCamp       sbc                   ON sbc.camId = camps.cam_id
        ORDER BY camps.cam_descripcion ASC;
    END;
    ELSE
    BEGIN
        SELECT DISTINCT CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, isnull
            (CAST(graph.graphic_id AS INT), 1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(
                inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea AS INT) AS
            AreaId, inb.chat AS InboundType, 0 AS OutboundType
        FROM ccInbound inb(NOLOCK)
                            INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
        INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = inb.IDArea
        ORDER BY inb.descripcion ASC;
    END;

    RETURN 0;
END;

ELSE IF @Option = 13
BEGIN
    BEGIN
        IF NOT EXISTS (
                SELECT *
                FROM ccUsers_Roles NOLOCK
                WHERE User_id = @AdminId
                    AND Rol_id = 7
                )
        BEGIN
            IF @CampType = 1
            BEGIN
                WITH wgId
                AS (
                    SELECT IDWG
                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT
                                    CAST(IdCampEsp AS INT) AS CampId,
                                    cam_descripcion AS Description,
                                    isnull(ccc.IDArea, -1) AS AreaID,
                                    CAST(-1 AS SMALLINT) AS CampaignType,
                                    CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
                                    CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
                                    CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
                                    CAST(1 AS INT) As CampType
                FROM ccRIACampEspWG A
                INNER JOIN wgId ON wgId.IDWG = A.IDWG AND A.Tipo = 1
                INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id
                LEFT JOIN ccInbound cci(NOLOCK) ON ccc.cam_id = cci.cam_id
                LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
            END
            ELSE
            BEGIN
                WITH wgId
                AS (
                    SELECT IDWG
                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT
                                    CAST(IdCampEsp AS INT) AS CampId,
                                    descripcion AS Description,
                                    isnull(IDArea, -1) AS AreaID,
                                    CAST(chat AS SMALLINT) AS CampaignType,
                                    CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
                                    CAST(chat AS INT) AS Channel,
                                    CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                    CAST(0 AS INT) As CampType
                FROM ccRIACampEspWG A(NOLOCK)
                INNER JOIN wgId ON wgId.IDWG = A.IDWG
                    AND A.Tipo = 0
                INNER JOIN ccInbound cci(NOLOCK) ON A.IdCampEsp = cci.Inbound_id
                                    LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
                                    LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
                                    AND ((@multi_type is null AND cci.chat = @InboundType)
                                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
            END
        END;
        ELSE
        BEGIN
            IF @CampType = 1
            BEGIN
                        SELECT DISTINCT
                                CAST(ccc.cam_id AS INT) AS CampId,
                                cam_descripcion AS Description,
                                isnull(ccc.IDArea, -1) AS AreaID,
                                CAST(-1 AS SMALLINT) AS CampaignType,
                                CAST(ISNULL(i.Inbound_id,-1) AS INT) AS RelatedCampId,
                                CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
                                CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
                                CAST(1 AS INT) As CampType
                        FROM ccCamps AS ccc (NOLOCK)
                            LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
                            left join ccInbound i on i.cam_id = ccc.cam_id
                        where ccc.IDArea = @AreaId
            END
            ELSE
            BEGIN
                        SELECT DISTINCT
                                CAST(cci.Inbound_id AS INT) AS CampId,
                                descripcion AS Description,
                                isnull(IDArea, -1) AS AreaID,
                                CAST(chat AS SMALLINT) AS CampaignType,
                                CAST(chat AS INT) AS Channel,
                                CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
                                CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                CAST(0 AS INT) As CampType
                FROM ccInbound cci(NOLOCK)
                            LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
                            LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
                        where IDArea = @AreaId
                        AND ((@multi_type is null AND cci.chat = @InboundType)
                            OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

            END
        END;

        RETURN 0;
    END;
END;
ELSE IF @Option = 14
BEGIN
    IF NOT EXISTS (
            SELECT 1
            FROM ccUsers_Roles NOLOCK
            WHERE User_id = @AdminId
                AND Rol_id = 7
            )
    BEGIN
        WITH wgId
        AS (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers NOLOCK
                                WHERE user_id = @AdminId)
                            SELECT DISTINCT
                                CAST(IdCampEsp AS INT) AS CampId,
                                descripcion AS Description,
                                isnull(IDArea, -1) AS AreaID,
                                CAST(chat AS SMALLINT) AS CampaignType,
                                CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
        FROM ccRIACampEspWG A(NOLOCK)
        INNER JOIN wgId ON wgId.IDWG = A.IDWG
            AND A.Tipo = 0
        INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id
            AND ((@multi_type is null AND cci.chat = @InboundType) OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

    END
    ELSE
    BEGIN
                    SELECT DISTINCT
                    CAST(Inbound_id AS INT) AS CampId,
                    descripcion AS Description,
                    isnull(IDArea, -1) AS AreaID,
                    CAST(chat AS SMALLINT) AS CampaignType,
                    CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                    FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
                    AND ((@multi_type is null AND cci.chat = @InboundType)
                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

    END
END

ELSE IF @Option = 15
BEGIN
    select
        CAST(Inbound_id AS INT) AS CampId,
        cci.descripcion AS Description,
        isnull(cci.IDArea, -1) AS AreaID,
        CAST(chat AS SMALLINT) AS CampaignType,
        CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId
    from ccCamps ccc
    INNER JOIN ccInbound cci ON cci.IDArea = ccc.IDArea
    where ccc.cam_id = @Id
        and chat IN (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))
        and isnull(cci.cam_id,-1) > 0

END
ELSE IF  @Option=16
begin
    DECLARE @from DATETIME = CAST(GETDATE() AS DATE);
    DECLARE @to DATETIME = DATEADD(MILLISECOND, -3, DATEADD(DAY, 1, @from));
    select @AreaId = IDArea from ccUsers where User_id = @Id
    declare @camps table (cam_id int)
    insert @camps   select cam_id  FROM  dbo.fGet_CampAcd_Area(@Id,5) group by cam_id
    if((select SUM(cam_id) from @camps) IS NULL)
        begin
            select '''' as CampName
            ,0 as Conversations
            ,0 as Assign
            ,0 as OnQueu
            ,0 AS FinishedBySystem
            ,0 AS FinishedByAgent
            ,'''' as AreaName
            ,0 as IsAssignedCamps
        end
    else
        begin
            ;with camDesc as(
            select
            c.cam_id as cam_id
            ,cam_descripcion as cam_desc
            ,area.AreaName
            from ccCamps c with (nolock)
            inner join @camps id on c.cam_id = id.cam_id
            inner join ccRIACat_Areas area on area.IDArea = c.IDArea
            group by area.AreaName, c.cam_id, c.cam_descripcion
            )
            ,
            currentConversationWa as (
            select conversationId, camId, assignDate, onQueue,finishedBy
            ,case when conversationStatus = 2 then 1 else 0 end as assigned
            from ccWhatsAppConversationsOut with (nolock)
            where assignDate >= @from and assignDate <= @to
            )
            select
            b.cam_desc as CampName
            ,COALESCE(COUNT(ccw.conversationId), 0) AS Conversations
            ,COALESCE(SUM(ccw.assigned), 0) AS Assign
            ,COALESCE(count(ccw.onQueue),0) as OnQueu
            ,SUM(CASE WHEN ccw.finishedBy = 1 THEN 1 ELSE 0 END) AS FinishedBySystem
            ,SUM(CASE WHEN ccw.finishedBy = 2 THEN 1 ELSE 0 END) AS FinishedByAgent
            ,b.AreaName as AreaName
            ,1 as IsAssignedCamps
            from camDesc b
            left join currentConversationWa ccw on ccw.camId = b.cam_id
            group by b.cam_id, b.cam_desc, b.AreaName
        end
    end
ELSE IF @Option = 17 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
        IF @groupList IS NOT NULL BEGIN
            IF OBJECT_ID(''tempdb..#WGDelete'') IS NOT NULL DROP TABLE #WGDelete;
            SELECT value As IDwg into #WGDelete FROM fn_RIASplitDelimited(@groupList, '','')
            SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type, IDWG AS IdWg FROM ccRIACampEspWG WHERE IDWG in (select IDwg from #WGDelete)
            ORDER BY IdCampEsp ASC;
        END;
        ELSE BEGIN
            RAISERROR(''ERROR. No existe una lista de campañas con los ids de grupo de trabajo especificados'', 18, 1);
        END;
        RETURN 0;
    END;

ELSE IF @Option = 18 BEGIN -- Validar si la campaña fue eliminada del area
        DECLARE @activo INT;

        IF @CampType = 0 BEGIN
            SELECT @activo = ISNULL(IDArea, 0)
            FROM ccInbound
            WHERE Inbound_id = @Id;
        END;

        ELSE BEGIN
            SELECT @activo = ISNULL(IDArea, 0)
            FROM ccCamps
            WHERE cam_id = @Id;
        END;

        SELECT @activo;
    END;

ELSE IF @Option = 19
    BEGIN

        DECLARE @SuccessId INT, @NonComprehensionId INT;
        DECLARE @IsSuperUser BIT = 0;
        DECLARE @wgId TABLE (IDWG INT);

        IF EXISTS (SELECT * FROM ccUsers_Roles NOLOCK WHERE User_id = @AdminId AND Rol_id = 7)
        BEGIN
            SET @IsSuperUser = 1;
        END
        ELSE
        BEGIN
            INSERT INTO @wgId (IDWG)
            SELECT IDWG
            FROM ccRIAWorkGroupUsers WITH (NOLOCK)
            WHERE user_id = @AdminId;
        END

        SELECT
            @SuccessId = ISNULL(idForSuccessfulTransaction, -1),
            @NonComprehensionId = ISNULL(idForNonComprehension, -1)
        FROM ccInbound WITH (NOLOCK)
        WHERE Inbound_id = @CampId;

        WITH MainCampaigns AS (
            SELECT
                CAST(cci.Inbound_id AS INT) AS CampId,
                cci.descripcion AS Description,
                ISNULL(cci.IDArea, -1) AS AreaID,
                CAST(cci.chat AS SMALLINT) AS CampaignType,
                CAST(0 AS BIT) AS IsSuccessTransfer,
                CAST(0 AS BIT) AS IsNonComprehensionTransfer
            FROM ccInbound cci WITH (NOLOCK)
            WHERE
            (
                -- Superusuario: por Área
                (@IsSuperUser = 1 AND cci.IDArea = @AreaId)
                OR
                -- Usuario normal: por Workgroup
                (@IsSuperUser = 0 AND EXISTS (
                    SELECT 1 FROM ccRIACampEspWG A WITH (NOLOCK)
                    INNER JOIN @wgId wg ON wg.IDWG = A.IDWG
                    WHERE A.Tipo = 0 AND A.IdCampEsp = cci.Inbound_id
                ))
            )
            AND cci.chat = 0
            AND cci.IDArea = @AreaId
        ),
        ReferencedCampaigns AS (
            SELECT
                CAST(cci.Inbound_id AS INT) AS CampId,
                cci.descripcion AS Description,
                ISNULL(cci.IDArea, -1) AS AreaID,
                CAST(cci.chat AS SMALLINT) AS CampaignType,
                CASE WHEN cci.Inbound_id = @SuccessId THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsSuccessTransfer,
                CASE WHEN cci.Inbound_id = @NonComprehensionId THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsNonComprehensionTransfer
            FROM ccInbound cci WITH (NOLOCK)
            WHERE cci.Inbound_id IN (@SuccessId, @NonComprehensionId)
        )

        SELECT * FROM ReferencedCampaigns
        UNION ALL
        SELECT m.*
        FROM MainCampaigns m
        LEFT JOIN ReferencedCampaigns r
        ON m.CampId = r.CampId
        WHERE r.CampId IS NULL;
    END;
END;'
    exec (@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]'
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
    ,MaxDaysPerWAConvo SMALLINT
    ,RecordIvr BIT
    ,CamCanceled INT
    ,surveyCamId int
    -- Outbound AI Campaign Special Settings
    ,RescheduledSurveyAI BIT
    ,ImmediateSurveyAI BIT
    ,ApplyRescheduledSurveyForCompletedCallsAI BIT
    ,EnableCallRecordingAI BIT
    -- Manual Rotation Dialing Configurations
    ,rotativeAlgorithmManual SMALLINT
    ,idAniListManual SMALLINT
    ,selectRotationManualDialing BIT
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

    -- consulta para extraer las variables del script
    DECLARE @ScriptVariables NVARCHAR(MAX);
    WITH RecursiveExtraction AS (
        SELECT
            CAST(SUBSTRING(scriptAgent, CHARINDEX(''{{'', scriptAgent) + 2,
            CHARINDEX(''}}'', scriptAgent) - CHARINDEX(''{{'', scriptAgent) - 2) AS VARCHAR(MAX)) AS Variable,
            CAST(STUFF(scriptAgent, CHARINDEX(''{{'', scriptAgent),
            CHARINDEX(''}}'', scriptAgent) - CHARINDEX(''{{'', scriptAgent) + 2, '''') AS VARCHAR(MAX)) AS RemainingText
        FROM dbo.ccVirtualAgent
        WHERE CHARINDEX(''{{'', scriptAgent) > 0
        AND idCampaign = @campID AND campType = 1

        UNION ALL

        SELECT
            CAST(SUBSTRING(RemainingText, CHARINDEX(''{{'', RemainingText) + 2,
            CHARINDEX(''}}'', RemainingText) - CHARINDEX(''{{'', RemainingText) - 2) AS VARCHAR(MAX)) AS Variable,
            CAST(STUFF(RemainingText, CHARINDEX(''{{'', RemainingText),
            CHARINDEX(''}}'', RemainingText) - CHARINDEX(''{{'', RemainingText) + 2, '''') AS VARCHAR(MAX)) AS RemainingText
        FROM RecursiveExtraction
        WHERE CHARINDEX(''{{'', RemainingText) > 0
    )
    SELECT @ScriptVariables = STUFF((
        SELECT '', '' + Variable
        FROM RecursiveExtraction
        FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''');

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
    ,ISNULL(CamCanceled, 0) CamCanceled
    ,surveyCamId SurveyCamId
    -- Outbound AI Campaign Special Settings
    ,RescheduledSurveyAI
    ,ImmediateSurveyAI
    ,ApplyRescheduledSurveyForCompletedCallsAI
    ,EnableCallRecordingAI
    -- Manual Rotation Dialing Configurations
    ,ISNULL(rotativeAlgorithmManual, 4) RotativeAlgorithmManual
    ,idAniListManual IdAniListManual
    ,selectRotationManualDialing SelectRotationManualDialing
    ,@ScriptVariables AS ScriptVariables
    FROM @AllCampaigns
    WHERE cam_id = @campID
END'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_UpdateCallsOutFromTempAction]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_UpdateCallsOutFromTempAction]
@action INT,
@tableName NVARCHAR(255),
@cal_status int = 0,
@idLoad int=0,
@motivo varchar(50)=null,
@cam_id int=null,
@isIAQuantumCamp bit =0,
@internationalRecords int=0

AS
BEGIN
SET NOCOUNT ON;

DECLARE @sql NVARCHAR(MAX);
DECLARE @paramDef NVARCHAR(300);
DECLARE @count INT;
declare @emtpy varchar(1)='''',@zipCodeSchedule bit
declare @columnsIAQuntum varchar(max)=''''

IF @action = 1
BEGIN
    SET @sql = ''
    UPDATE '' + QUOTENAME(@tableName) + ''
    SET international = 1'';

    EXEC sp_executesql @sql;
END
ELSE IF @action = 2
BEGIN

    if @isIAQuantumCamp =1 begin
        set @columnsIAQuntum='', data_api_quantum, data_overflow_variables_quantum''
    end

    SET @sql = ''
    INSERT INTO dbo.ccoCallsOutSource (
        cal_Key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
        Dato1, Dato2, Dato3, Dato4, Dato5,
        dialPrefix, list_id, cam_id, Region, Localidad, cal_status, cal_fechaDial
        ,iZonaHoraria,iZonaHoraria_verano
        ,iZonaHoraria2,iZonaHoraria_verano2
        ,iZonaHoraria3,iZonaHoraria_verano3
        ,iZonaHoraria4,iZonaHoraria_verano4
        ,iZonaHoraria5,iZonaHoraria_verano5
        '' + @columnsIAQuntum + ''
    )
    SELECT
        cal_Key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
        Dato1, Dato2, Dato3, Dato4, Dato5,
        dialPrefix, list_id, cam_id, Region, Localidad, cal_status, cal_fechaDial
        ,iZonaHoraria,iZonaHoraria_verano
        ,iZonaHoraria2,iZonaHoraria_verano2
        ,iZonaHoraria3,iZonaHoraria_verano3
        ,iZonaHoraria4,iZonaHoraria_verano4
        ,iZonaHoraria5,iZonaHoraria_verano5
        '' + @columnsIAQuntum + ''
    FROM '' + QUOTENAME(@tableName) + ''
    WHERE callout_id = 0'';

    EXEC sp_executesql @sql;
END

ELSE IF @action = 3
BEGIN
    SET @sql = ''
    INSERT INTO dbo.ccoCallsPreviewData (
        cal_Key, cam_id, TotalData, Headers,
        Dato6, Dato7, Dato8, Dato9, Dato10,
        Dato11, Dato12, Dato13, Dato14, Dato15
    )
    SELECT
        A.cal_Key, A.cam_id, A.TotalData, A.Headers,
        A.Dato6, A.Dato7, A.Dato8, A.Dato9, A.Dato10,
        A.Dato11, A.Dato12, A.Dato13, A.Dato14, A.Dato15
    FROM '' + QUOTENAME(@tableName) + '' A
    left join ccoCallsPreviewData B on A.cal_Key=B.cal_Key and A.cam_id=B.cam_id
    WHERE B.cam_id is null;
    '';

    EXEC sp_executesql @sql;
END
ELSE IF @action = 4
BEGIN
    SET @sql = ''
    UPDATE C SET
        C.Headers = A.Headers,
        C.TotalData = A.TotalData,
        C.Dato6 = A.Dato6, C.Dato7 = A.Dato7, C.Dato8 = A.Dato8, C.Dato9 = A.Dato9, C.Dato10 = A.Dato10,
        C.Dato11 = A.Dato11, C.Dato12 = A.Dato12, C.Dato13 = A.Dato13, C.Dato14 = A.Dato14, C.Dato15 = A.Dato15
    FROM '' + QUOTENAME(@tableName) + '' A
    INNER JOIN dbo.ccoCallsPreviewData C WITH (ROWLOCK, UPDLOCK)
        ON A.cal_Key = C.cal_Key AND A.cam_id = C.cam_id;
    '';

    EXEC sp_executesql @sql;
END
ELSE IF @action =5
BEGIN
    if @isIAQuantumCamp =1 begin
        set @columnsIAQuntum='', C.data_api_quantum = A.data_api_quantum, C.data_overflow_variables_quantum = A.data_overflow_variables_quantum''
    end

    SET @sql = ''
    UPDATE C SET
        C.cal_status = CASE WHEN B.callout_id IS NULL THEN @cal_status_param ELSE C.cal_status END,
        C.cal_telefono = A.cal_telefono,
        C.cal_telefono2 = A.cal_telefono2,
        C.cal_telefono3 = A.cal_telefono3,
        C.cal_telefono4 = A.cal_telefono4,
        C.cal_telefono5 = A.cal_telefono5,
        C.Dato1 = A.Dato1,
        C.Dato2 = A.Dato2,
        C.Dato3 = A.Dato3,
        C.Dato4 = A.Dato4,
        C.Dato5 = A.Dato5,
        C.dialPrefix = A.dialPrefix,
        C.list_id = A.list_id,
        C.cal_fechaDial = case when ISNULL(B.cal_status, 0) = 1 then C.cal_fechaDial else A.cal_fechaDial end,
        C.Region = A.Region,
        C.Localidad = A.Localidad,
        C.international = A.international,
        C.recycledByResult = @emtpy,
        C.recycledByDisposition = 0,
        C.recyclePhone = 0,
        C.recycleType = 1
        ,C.iZonaHoraria=A.iZonaHoraria,C.iZonaHoraria_verano=A.iZonaHoraria_verano
        ,C.iZonaHoraria2=A.iZonaHoraria2,C.iZonaHoraria_verano2=A.iZonaHoraria_verano2
        ,C.iZonaHoraria3=A.iZonaHoraria3,C.iZonaHoraria_verano3=A.iZonaHoraria_verano3
        ,C.iZonaHoraria4=A.iZonaHoraria4,C.iZonaHoraria_verano4=A.iZonaHoraria_verano4
        ,C.iZonaHoraria5=A.iZonaHoraria5,C.iZonaHoraria_verano5=A.iZonaHoraria_verano5
        '' + @columnsIAQuntum + ''
    FROM '' + QUOTENAME(@tableName) + '' A
    LEFT JOIN dbo.ccoWorkingTable B WITH (ROWLOCK, UPDLOCK, READPAST) ON A.callout_id = B.callout_id AND B.cal_status <= 2
    INNER JOIN dbo.ccoCallsOutSource C WITH (ROWLOCK, UPDLOCK) ON A.callout_id = C.callout_id'';

    SET @paramDef = N''@cal_status_param TINYINT, @emtpy varchar(1)'';
    EXEC sp_executesql @sql, @paramDef, @cal_status_param = @cal_status, @emtpy= @emtpy;
END
ELSE IF @action = 6
BEGIN
    DECLARE @today DATE = CONVERT(DATE, GETDATE());

    SET @sql = ''
UPDATE B
SET B.list_id = A.list_id
FROM '' + QUOTENAME(@tableName) + '' A
INNER JOIN ccoCallsOutSource C WITH (NOLOCK)  ON A.callout_id = C.callout_id
INNER JOIN ccoWorkingTable B WITH (NOLOCK)    ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id
WHERE B.list_id <> A.list_id;

WHILE 1 = 1
BEGIN
    ;WITH cte AS
    (
        SELECT TOP (200) ld.logDial_id
        FROM '' + QUOTENAME(@tableName) + '' t
        LEFT JOIN ccoWorkingTable wt WITH (READPAST, UPDLOCK) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
        INNER JOIN ccoLogDials ld WITH (UPDLOCK) ON ld.callout_id = t.callout_id
        WHERE wt.callout_id IS NULL AND ld.fecha >= @today AND (ld.canBeRecycled = 1 OR ld.canBeRecycled IS NULL)
        ORDER BY ld.logDial_id
    )
    UPDATE ld
    SET ld.canBeRecycled = 0
    FROM ccoLogDials ld
    INNER JOIN cte x
        ON ld.logDial_id = x.logDial_id;

    IF @@ROWCOUNT = 0 BREAK;

    WAITFOR DELAY ''''00:00:00.05'''';
END


WHILE 1 = 1
BEGIN
    ;WITH cte AS
    (
        SELECT TOP (200) co.cal_id
        FROM '' + QUOTENAME(@tableName) + '' t
        LEFT JOIN ccoWorkingTable wt WITH (READPAST, UPDLOCK) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
        INNER JOIN ccoCallsOut co WITH (UPDLOCK) ON co.callout_id = t.callout_id
        WHERE wt.callout_id IS NULL AND co.cal_Inicio >= @today AND (co.canBeRecycled = 1 OR co.canBeRecycled IS NULL)
        ORDER BY co.cal_id
    )
    UPDATE co
    SET co.canBeRecycled = 0
    FROM ccoCallsOut co
    INNER JOIN cte x
        ON co.cal_id = x.cal_id;

    IF @@ROWCOUNT = 0 BREAK;

    WAITFOR DELAY ''''00:00:00.05'''';
END

    '';
    --print(@sql)
    --EXEC sp_executesql @sql, N''@today DATE'', @today=@today;
END
ELSE IF @action = 7
BEGIN

    -- Contar registros inválidos
    SET @sql = ''
    SELECT @cnt = COUNT(*)
    FROM '' + QUOTENAME(@tableName) + '' A
    LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
        ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
    WHERE B.callout_id IS NULL and A.callout_id > 0;'';

    EXEC sp_executesql @sql, N''@cnt INT OUTPUT'', @cnt = @count OUTPUT;

    -- Insertar en ccRIALogPhones los registros sin match
    SET @sql = ''
    INSERT INTO ccRIALogPhones(load_id, cal_key, telefono, tipoMov, motivo,internationalRecords)
    SELECT @idLoad, A.cal_Key, @emtpy, 2, @motivo,@internationalRecords
    FROM '' + QUOTENAME(@tableName) + '' A
    LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
        ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
    WHERE B.callout_id IS NULL;'';

    EXEC sp_executesql @sql,
        N''@idLoad INT, @motivo NVARCHAR(200),@emtpy varchar(1),@internationalRecords int'',
        @idLoad = @idLoad,
        @motivo = @motivo,
        @internationalRecords =@internationalRecords,
        @emtpy=@emtpy;

    -- Eliminar los registros sin match
    SET @sql = ''
    DELETE A
    FROM '' + QUOTENAME(@tableName) + '' A
    LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
        ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
    WHERE B.callout_id IS NULL;'';

    EXEC(@sql);

    -- Retornar el count como resultado
    SELECT @count AS RegistrosEliminados;
END
ELSE IF @action = 8
BEGIN


    -- Contar total de registros antes del borrado
    SET @sql = ''
    SELECT @cnt = COUNT(*) FROM '' + QUOTENAME(@tableName) + '';'';

    EXEC sp_executesql @sql, N''@cnt INT OUTPUT'', @cnt = @count OUTPUT;

    -- Log en ccRIALogPhones todos los registros de la tabla temporal
    SET @sql = ''
    INSERT INTO ccRIALogPhones(load_id, cal_key, telefono, tipoMov, motivo,internationalRecords)
    SELECT @idLoad, cal_Key, @emtpy, 6, @motivo,@internationalRecords FROM '' + QUOTENAME(@tableName) + '';'';

    EXEC sp_executesql @sql,
            N''@idLoad INT, @motivo NVARCHAR(200),@emtpy varchar(1),@internationalRecords int'',
        @idLoad = @idLoad,
        @motivo = @motivo,
        @internationalRecords =@internationalRecords,
        @emtpy=@emtpy;

    -- Eliminar todos los registros de la tabla temporal
    SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '';'';
    EXEC(@sql);

    -- Retornar el número de registros eliminados
    SELECT @count AS RegistrosEliminados;
END
ELSE IF @action = 9 BEGIN

    DECLARE @country TINYINT;
    SELECT @country = CONVERT(TINYINT, valor) FROM ccSettings WITH (NOLOCK) WHERE setting_id = 104;
    if @country =1 begin
        select @zipCodeSchedule=zipCodeSchedule from ccCampsExtend where cam_id =@cam_id
    end
    if @zipCodeSchedule is null begin
        set @zipCodeSchedule=0
    end

    SET @sql = ''
UPDATE T SET
    iZonaHoraria = CASE
        WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
        WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
        ELSE dbo.fnGetTimeZone(T.cal_telefono,  0) END,

    iZonaHoraria_verano = CASE
        WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
        WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
        ELSE dbo.fnGetTimeZone(T.cal_telefono,  1) END,

    iZonaHoraria2 = CASE
        WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
        WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
        ELSE dbo.fnGetTimeZone(T.cal_telefono2,  0) END,

    iZonaHoraria_verano2 = CASE
        WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
        WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
        ELSE dbo.fnGetTimeZone(T.cal_telefono2,  1) END,

    iZonaHoraria3 = CASE
        WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
        WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
        ELSE dbo.fnGetTimeZone(T.cal_telefono3,  0) END,

    iZonaHoraria_verano3 = CASE
        WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
        WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
        ELSE dbo.fnGetTimeZone(T.cal_telefono3,  1) END,

    iZonaHoraria4 = CASE
        WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
        WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
        ELSE dbo.fnGetTimeZone(T.cal_telefono4,  0) END,

    iZonaHoraria_verano4 = CASE
        WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
        WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
        ELSE dbo.fnGetTimeZone(T.cal_telefono4,  1) END,

    iZonaHoraria5 = CASE
        WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
        WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
        ELSE dbo.fnGetTimeZone(T.cal_telefono5,  0) END,

    iZonaHoraria_verano5 = CASE
        WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
        WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
        ELSE dbo.fnGetTimeZone(T.cal_telefono5,  1) END

FROM '' + QUOTENAME(@tableName) + '' T
OUTER APPLY dbo.fnGetTimeZoneByZip(T.Dato1) AS Z
''
EXEC sp_executesql @sql,
        N''@zipCodeSchedule bit,@country TINYINT,@emtpy varchar(1)'',
        @zipCodeSchedule = @zipCodeSchedule,
        @country = @country,
        @emtpy = @emtpy

--print(@sql)
END
ELSE IF @action = 10
BEGIN
    SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '' WHERE callout_id = 0;'';
    EXEC sp_executesql @sql;
END
    ELSE IF @action = 11 BEGIN

    SET @sql = ''
UPDATE T SET
    international=@internationalRecords
FROM '' + QUOTENAME(@tableName) + '' T
''
EXEC sp_executesql @sql,
        N''@internationalRecords int'',
        @emtpy = @emtpy

END


ELSE
BEGIN
    RAISERROR(''Acción inválida: %d. Use 1 = UpdateOutSource, 2 = UpdateLogDials, 3 = UpdateCallsOut, 4 = UpdateInternational'', 16, 1, @action);
    RETURN;
END
END'
    exec (@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccspLoadCampsOutbound]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspLoadCampsOutbound]
    @action int,  
    @nType INT=0,
    @agentId int=0,
    @campId int=0
AS
declare @sql nvarchar(max)

if @action= 0 begin
    set @sql=''SELECT cc.cam_id
                ,cam_descripcion
                ,cam_activo
                ,cam_ModoManual
                ,cam_modpredictivo
                ,cam_callratio
                ,cam_procesando
                ,convert(VARCHAR(8), cast(cam_maxdlrxage AS FLOAT)) cam_maxdlrxage
                ,cam_fDialOnWU
                ,cam_fDialOnDLG
                ,cam_tDialAfterWU
                ,cam_tDialBeforeReady
                ,cam_tDialAfterDLG
                ,compliance
                ,progDial
                ,excCallBack
                ,aggressionFactor
                ,listenManualCall
                ,tDialOnWrapUp
                ,callsbySurvey
                ,ivrscript
                ,cam_tNoContesta
                ,cam_inter_cancelled
                ,ISNULL(cc.CampType, 0) AS CampType
                ,ISNULL(cc.CamCanceled, 4) AS CamCanceled
                ,ISNULL(ex.SimultaneousRecs, 0) AS SimultaneousRecs
                ,ISNULL(cva.idAgent, 0) AS IdAgentVirtual
                                ,ISNULL(cva.nameAgent, '''''''') AS NameAgentVirtual
                ,ISNULL(cva.concurrentSessionsLimit, 0) AS NumberSessions
                FROM ccCamps cc (NOLOCK) 
                LEFT JOIN ccCampsExtend ex (NOLOCK) ON ex.cam_id = cc.cam_id
                LEFT JOIN ccVirtualAgent cva ON cva.idCampaign = cc.cam_id AND cva.campType = 1
                WHERE cc.CampType not in (5,7)''
    if @nType=2 
        set @sql=@sql+'' AND cc.cam_bNew = 2 ''
    else if @nType=3
        set @sql=@sql+'' AND cc.cam_bNew in (1,2) ''
    set @sql=@sql+'' ORDER BY cc.cam_descripcion''
    --print(@sql)
    exec (@sql)
end
else if @action= 1 begin
    set @sql=''SELECT distinct C.cam_id, C.cam_descripcion, Prioridad, A.Login, A.User_id, Skill
        from ccCamps C (nolock) join ccCampsAgente CA on C.cam_id = CA.cam_id AND CampType not in (5,7)
        join ccUsers A (nolock) on A.User_id = CA.User_id and A.TipoUser_id =1 AND A.Status=1 ''
    if @nType=2 
        set @sql=@sql+'' and C.cam_bNew=2''
    else if @nType=3
        set @sql=@sql+'' and C.cam_bNew in (1,2)''
    if @campId > 0
        set @sql=@sql+'' where C.cam_id = '' + cast(@campId as varchar(5))
    set @sql=@sql+'' order by C.cam_id, CA.Prioridad''
    --print(@sql)
    exec (@sql)
end
else if @action= 2 begin
    set @sql=''select distinct A.Login, Prioridad, C.cam_id, Skill
            from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id AND CampType not in (5,7)
            join ccUsers A  on A.User_id = CA.User_id and A.TipoUser_id =1 AND A.Status=1
            Where A.User_id = @agentId
            order by C.cam_id, CA.Prioridad''
    --print(@sql)
    exec sp_executesql @sql, N''@agentId int'', @agentId
end
else if @action= 3 begin
    set @sql=''SELECT dialer_id, C.cam_id FROM ccoDialerCamp R (nolock) join ccCamps C (nolock) on R.cam_id=C.cam_id AND CampType not in (5,7) ''
    if @nType=2 
        set @sql=@sql+'' and C.cam_bNew = 2 ''
    else if @nType=3
        set @sql=@sql+'' and C.cam_bNew in (1,2) ''
    if @campId > 0
        set @sql=@sql+'' where C.cam_id = '' + cast(@campId as varchar(5))
    set @sql=@sql+'' ORDER BY cam_descripcion''
    --print(@sql)
    exec (@sql)
end
else if @action= 4 begin
    set @sql=''
    declare @today datetime

    set @today=CONVERT(date,GETDATE(),121)

    SELECT A.Login, A.TipoLLamadas, A.user_id 
    FROM ccUsers A 
    INNER JOIN ccTipoUsers T on A.TipoUser_id=T.TipoUser_id   
    WHERE A.TipoUser_id =1 AND A.Status=1 AND A.User_id = CASE WHEN @agentId = 0 THEN A.User_id ELSE @agentId END
    ORDER BY Login''
    exec sp_executesql @sql, N''@agentId int'', @agentId
end

'
    exec (@sql)

    SET @process = ''
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRGetDialInfo]
@callout_id int,
@cam_id smallint=0,
@iPortNumber smallint = 0,
@trunkId int=0
AS
set nocount on
declare @message_name as varchar(8000), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)    
declare @prefix as varchar(15), @trunk varchar(200)
declare @prefixCalKey as varchar(30)
declare @tNoContesta as tinyint
declare @ani as varchar(32)
declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint, @rotativeAlgo tinyint
declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint
declare @ivr_script smallint, @surveycamid int
declare @call_record_cam as tinyint
declare @pais as tinyint 
declare @sipHdrFormat varchar(255)
declare @PrefixRec varchar(40)
declare @recordHold bit, @recordIvr bit
declare @croute varchar(32)

set @prefix =''''
set @tNoContesta = 25
set @ani=''''
set @iTipoDial = 0
set @detectAnswerMachine = 0
set @detectVoiceMail =1
set @cam_tnotas = 30
set @keepDial = 0

select @pais = valor from ccsettings with(nolock) where setting_id = 104
select @PrefixRec=ISNULL(prefijo,'''') from ccCamps nolock where cam_id = @cam_id

-- Mensajes
select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
from dbo.fn_ccCamps_SelMessage(@cam_id)

-- Prefijo por puerto
select @prefix = prefix, @trunk=isnull(trunk,'''') from cstoProvedor with(nolock) where provedor_id = (
    select provedor_id from ccodialers with(nolock) where puerto = @iPortNumber )
-- Prefijo por campa?a
if @prefix =''''
    select @prefix = dialPrefix from ccCamps with(nolock) where cam_id = @cam_id
-- Prefijo general, si es que esta habilitado
if @prefix ='''' and ((select cast(valor as int) from ccsettings nolock where setting_id =102) & 1 = 1)
    select @prefix = valor from ccsettings with(nolock) where setting_id =101

select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

-- Propiedades de campa?a
select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
@call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0), @rotativeAlgo=isnull(rotativeAlgo,0), @recordHold=ISNULL(recordHold,0)
,@PrefixRec=ISNULL(prefijo,''''), @recordIvr=ISNULL(recordIvr,0)
from ccCamps C with(nolock) where C.cam_id=@cam_id

if @surveycamid > 0
    select @ivr_script = isnull(ivrscript,0) from cccamps with(nolock) where cam_id = @surveycamid
        
--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile
FROM ccCampsMsgs VE with(nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

--Agrega prefijo Marcacion con directo
declare @mainPrefix varchar(1), @phones varchar(max), @apikeyQuantum VARCHAR(300);
set @prefixCalKey=''''
select @mainPrefix = valor from ccSettings where setting_id=202
select @apikeyQuantum = ISNULL(valor, '''') from dbo.ccSettings2 where setting_id=284
declare @tmpccoCallsOutSource table(callout_id int primary key,dialPrefix   varchar(30) null
,cal_Key    varchar(40)
,cal_telefono   varchar(30),cal_telefono2   varchar(30),cal_telefono3   varchar(30),cal_telefono4   varchar(30),cal_telefono5   varchar(30)
,Dato1  varchar(255),Dato2  varchar(255),Dato3  varchar(255),Dato4  varchar(255),Dato5  varchar(255)
,recyclePhone   SMALLINT
,recycleType BIT
,data_api_quantum VARCHAR(MAX)
)
insert into @tmpccoCallsOutSource
SELECT 
    c.callout_id,
    c.dialPrefix,
    c.cal_Key,
    c.cal_telefono, c.cal_telefono2, c.cal_telefono3, c.cal_telefono4, c.cal_telefono5,
    c.Dato1, c.Dato2, c.Dato3, c.Dato4, c.Dato5,
    c.recyclePhone, c.recycleType,
    (
        CASE 
            WHEN RIGHT(RTRIM(ISNULL(c.data_api_quantum, N''{}'')), 1) = N''}''
                THEN LEFT(RTRIM(ISNULL(c.data_api_quantum, N''{}'')), LEN(RTRIM(ISNULL(c.data_api_quantum, N''{}''))) - 1)
            ELSE RTRIM(ISNULL(c.data_api_quantum, N''{}''))
        END
        +
        CASE 
            WHEN LEN(
                    LTRIM(RTRIM(
                        CASE 
                            WHEN LEFT(LTRIM(RTRIM(ISNULL(c.data_api_quantum, N''{}''))),1) = N''{'' 
                            AND RIGHT(RTRIM(ISNULL(c.data_api_quantum, N''{}'')),1) = N''}''
                            THEN SUBSTRING(
                                    LTRIM(RTRIM(ISNULL(c.data_api_quantum, N''{}''))),
                                    2,
                                    LEN(LTRIM(RTRIM(ISNULL(c.data_api_quantum, N''{}'')))) - 2
                                )
                            ELSE LTRIM(RTRIM(ISNULL(c.data_api_quantum, N''{}'')))
                        END
                    ))
                ) > 0 
            THEN N'','' ELSE N'''' 
        END
        +
        N''"country": '' + CONVERT(NVARCHAR(20),@pais)
        +
        N'', "time_zone": '' + CONVERT(NVARCHAR(20),
                            CASE
                                WHEN c.iZonaHoraria  > 0 THEN c.iZonaHoraria
                                WHEN c.iZonaHoraria2 > 0 THEN c.iZonaHoraria2
                                WHEN c.iZonaHoraria3 > 0 THEN c.iZonaHoraria3
                                WHEN c.iZonaHoraria4 > 0 THEN c.iZonaHoraria4
                                WHEN c.iZonaHoraria5 > 0 THEN c.iZonaHoraria5
                                ELSE 0
                            END
                        )
        +
        N''}''
    ) AS data_api_quantum
FROM ccoCallsOutSource AS c WITH (NOLOCK)
WHERE c.callout_id = @callout_id;

SELECT @prefixCalKey=CASE WHEN @mainPrefix=''1'' THEN isnull(dialPrefix,'''') ELSE '''' END,
    @phones=cal_telefono+'';''+cal_telefono2+'';''+cal_telefono3+'';''+cal_telefono4+'';''+cal_telefono5
FROM @tmpccoCallsOutSource

if @iPortNumber >= 0 
begin
    declare @Anis table(id int, pid varchar(2), phone varchar(32), ani varchar(32))

    insert @Anis
    exec ccsp_DLRGetRotativeANI @callout_id=@callout_id,@phones=@phones,@aniList=@lista_id,@algo=@rotativeAlgo

    SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
    if len(@sipheader)>32 and left(@sipheader,1)=''@''
        select @croute=substring(@sipheader, 2, 32)
            
    SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)
    , ISNULL(cpt.Prioridad,''12345NNN'') dial_tels
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 1) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE C.cal_telefono  END cal_telefono
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 2) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono2 END cal_telefono2
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 3) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono3 END cal_telefono3
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 4) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono4 END cal_telefono4
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 5) AND ISNULL(recycleType, 1) = 0) THEN '''' Else c.cal_telefono5 END cal_telefono5
    , isnull(@message_name, '''') as message_name
    , @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
    , case when anis.p1 <> '''' then anis.p1 else @ani end ani
    , case when anis.p2 <> '''' then anis.p2 else @ani end ani2
    , case when anis.p3 <> '''' then anis.p3 else @ani end ani3
    , case when anis.p4 <> '''' then anis.p4 else @ani end ani4
    , case when anis.p5 <> '''' then anis.p5 else @ani end ani5
    , @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail
    , @cam_tnotas cam_tnotas, @keepDial keepDial
    , isnull(@messageDNCL_name, '''') as messageDNCL_name
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono) as call_record
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono2) as call_record2
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono3) as call_record3
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono4) as call_record4
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono5) as call_record5
    , isnull(@messageDNCLConfirm_name, '''') as messageDNCLConfirm_name
    , isnull(@MohFiles,'''') as mohFiles
    ,@ivr_script ivrScript
    ,@sipheader data
    ,@PrefixRec as Prefijo,
    dbo.GetCarrierByTel(C.cal_telefono) carrier1, 
    dbo.GetCarrierByTel(cal_telefono2) carrier2, 
    dbo.GetCarrierByTel(cal_telefono3) carrier3, 
    dbo.GetCarrierByTel(cal_telefono4) carrier4, 
    dbo.GetCarrierByTel(cal_telefono5) carrier5,
    @recordHold as recordHold,
    @recordIvr as recordIvr,
    isnull(C.data_api_quantum, '''') AS data_api_quantum,
    @apikeyQuantum AS key_api_quantum,
    dbo.GetRoute(C.cal_telefono,isnull(@croute,''''),@trunkId) destination,
    @trunk trunk
    FROM @tmpccoCallsOutSource C
    left join ccoCallPriorityOrder cpo with(nolock) on cpo.callout_id = c.callout_id
    left join ccCampsPrioridadTel cpt on cpt.cam_id = @cam_id
    left join (SELECT * FROM (SELECT pid,ani FROM @Anis)a PIVOT(MAX(ani) FOR pid IN(p1,p2,p3,p4,p5)) AS pt) anis on 0=0
    WHERE C.callout_id = @callout_id
    OPTION (RECOMPILE);
    return
end 
set nocount off
     '
    exec (@sql)
    

    SET @process = 'ALTER procedure [dbo].[ccsp_DLRgetXferInfo]'
    SET @sql = 'ALTER procedure [dbo].[ccsp_DLRgetXferInfo]
@camEspecId smallint=0,
@iPortNumber smallint = 0,
@type smallint,
@typeTransfer smallint = 0,
@phone varchar(50) = '''',
@trunkId int=0
as
-- @type: 1 transferencia entrada, 2 transferencia salida, 3 desborde (siempre es entrada, con o sin especialidad)
declare @prefix as varchar(15), @trunk varchar(200)
declare @timeout int
declare @ani as varchar(32)
declare @stop int
declare @ivr_script smallint, @surveycamid int

set @prefix =''''
set @timeout = 20
set @ani = ''''
set @stop = 0

-- Prefijo por puerto
select @prefix = prefix, @trunk=isnull(trunk,'''') from cstoProvedor nolock where provedor_id = (
    select provedor_id from ccodialers nolock where puerto = @iPortNumber )
-- Prefijo por campaña o especialidad
if @prefix =''''
    if @type = 2
        select @prefix = dialPrefixXfe from ccCamps where cam_id = @camEspecId
    else
        select @prefix = dialPrefixOverflow from ccInbound where inbound_id= @camEspecId
-- Prefijo general
if @prefix ='''' and (@type =1 or @type=2) and ((select cast(valor as int) from ccsettings where setting_id =102) & 4 = 4)
    select @prefix = valor from ccsettings where setting_id =101
if @prefix ='''' and (@type =3) and ((select cast(valor as int) from ccsettings where setting_id =102) & 8 = 8)
    select @prefix = valor from ccsettings where setting_id =101

-- Tiempo de marcado
select @timeout = cast(valor as int) from ccSettings where setting_id = 109

-- Ani y stopRecord
if @type = 2
    select @ani = callerIdDesc, @stop = isnull(stopRecording, 0) from ccCamps nolock where cam_id = @camEspecId
else
begin
    select @ani = callerIdDesc, @stop = stopRecording, @surveycamid = isnull(extend.SurveyCamId,0)
    from ccInbound i (nolock)
    left join ccInboundExtend extend on extend.Inbound_id = i.Inbound_id
    where i.inbound_id= @camEspecId

    if @surveycamid > 0
        select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid
end

if (@typeTransfer in (0,4) and @type = 2 and @phone is not null and @phone <> '''')
begin
    select @stop = case when @typeTransfer = 0 then isnull(stopRecording, 1) else ISNULL(stopRecordingAssisted, 1) end from telefonosTransferencia where tel = @phone
end

select @prefix as sDialPrefix, @timeout as tNoContesta, @ani as ani, @stop as stopRecording, @ivr_script as ivrScript,
dbo.GetRoute(@phone,'''',@trunkId) destination, @trunk trunk'
    exec (@sql)

    SET @process = 'ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]'
    SET @sql = 'ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]
    @cam_id smallint=0,
    @iPortNumber smallint = 0,
    @phone varchar(30) = '''',
    @callout_id int = 0,
    @trunkId int=0
    as
    declare @prefix as varchar(15), @sipheader varchar(500), @trunk varchar(200)
    declare @ani as varchar(32)
    declare @pais as tinyint
    declare @aniglobal varchar(32), @sipHdrFormat varchar(255)
    declare @ivr_script smallint, @surveycamid int
    declare @call_record tinyint, @tNoContesta tinyint, @detectAnswerMachine smallint, @detectVoiceMail tinyint
    declare @PrefixRec varchar(40)
    declare @carrier varchar(255)
    declare @recordHold bit, @recordIvr bit
    declare @RotativeAlgo int ,@aniList smallint
    declare @croute varchar(32)

    select @pais = valor from ccsettings with(nolock) where setting_id = 104
    select @aniglobal = valor from ccsettings with(nolock) where setting_id = 177

    set @prefix =''''
    -- Prefijo por puerto
    select @prefix = prefix, @trunk=isnull(trunk,'''') from cstoProvedor nolock where provedor_id = (
        select provedor_id from ccodialers nolock where puerto = @iPortNumber )

    -- Prefijo por campa?a,
    if @prefix =''''
        select @prefix = dialPrefixMan from ccCamps where cam_id = @cam_id

    -- Prefijo general
    if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 2 = 2)
        select @prefix = valor from ccsettings with(nolock) where setting_id =101

    -- Ani
    select @RotativeAlgo = RotativeAlgo from ccCamps where cam_id = @cam_id
    select @aniList = id_anilist from ccCamps where cam_id =@cam_id

    if @RotativeAlgo=0 and @aniList>0  begin
    set @ani = dbo.TelAni(@phone, @aniList )
    end
    else begin
        set @ani=''''
    end
    set @ani = dbo.TelAni(@phone, (select id_anilist from ccCamps where cam_id =@cam_id) )

    --AnswerMachine Message Files
    DECLARE @MsgFiles VARCHAR(8000)
    SELECT @MsgFiles = COALESCE(@MsgFiles + '','', '''') + V.msgfile
    FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 8 ORDER BY orden

    IF EXISTS (select 1 from ccCampsMsgs where Type = 20 and cam_id = @cam_id)
    BEGIN
        select @MsgFiles = @MsgFiles + '',TTS/message.wav''
    END

    --Custom MOH Files
    DECLARE @MohFiles VARCHAR(8000)
    SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile
    FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

    select @surveycamid = 0, @ivr_script = 0

    select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta = cam_tNoContesta, @ani = case when @ani = '''' then ani else @ani end
    ,@detectAnswerMachine = detectAnswerMachine, @detectVoiceMail = detectVoiceMail
    ,@call_record = dbo.EnableCallRecord(call_record, @pais, @phone), @surveycamid = isnull(surveycamid,0), @recordHold=ISNULL(recordHold,0)
    ,@recordIvr=ISNULL(recordIvr,0), @PrefixRec = ISNULL(prefijo,'''')
    from ccCamps NOLOCK where cam_id = @cam_id

    SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
    if len(@sipheader)>32 and left(@sipheader,1)=''@''
        select @croute=substring(@sipheader, 2, 32)

    if @surveycamid > 0
        select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid


    if @ani = '''' begin
    set @ani = @aniglobal
    end

        set @carrier = ''''
        select @carrier = dbo.GetCarrierByTel(@phone)

    select @prefix as sDialPrefix, @tNoContesta as tNoContesta,@ani as ani, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail,
    @call_record as call_record, isnull(@MsgFiles,'''') as messageFiles, isnull(@MohFiles,'''') as mohFiles, @ivr_script ivrScript, @sipheader data
    ,@PrefixRec PrefijoRec, @carrier Carrier, @recordHold recordHold, @recordIvr recordIvr,
    dbo.GetRoute(@phone,isnull(@croute,''''),@trunkId) destination, @trunk trunk'
    exec (@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_AgentUpdateCallCALIF]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentUpdateCallCALIF]
@IDCall INT,
@calif_id SMALLINT,
@TipoCall SMALLINT,
@Origin INT = 0,
@cal_key VARCHAR(40) = NULL,
@callOutId INT = 0,
@subId SMALLINT = 0
AS
SET NOCOUNT ON

DECLARE @RecicleSIC TINYINT, @Reprogram TINYINT, @DateNewDial SMALLDATETIME, @idTipoLista INT, @autoCB TINYINT,
@tel VARCHAR(30), @camp INT, @iddncList AS INT,@completatel VARCHAR(30),@camId int,@dni_id int
,@useCalkeyBlackList bit
,@userid INT
,@statusCallId int
,@hashTel INT
,@portId int
,@isInternationalPort bit=0

SELECT @RecicleSIC = valor
FROM ccSettings
WHERE setting_id = 60


SELECT @RecicleSIC = IsNull(@RecicleSIC, 0)


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
    SET calif_id = @calif_id, cal_origin_id = @Origin, cal_key = isnull(@cal_key, cal_key)
    , califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
    WHERE cal_id = @IDCall


    exec ccspSaveDispositionResult @action=2, @callid=@IDCall, @camId=@camp,@callType=0,
    @dispotitionId=@calif_id,@subDispotitionId=@subId,@statusCallId=13

    IF EXISTS (
            SELECT idTipoLista
            FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
            WHERE tipo = 0 AND calif_id = @calif_id
            )
    BEGIN
        SELECT @tel = dbo.Limpia(ci.cal_ANI)       
        ,@camId=Inbound_id,@dni_id=dni_id
        ,@portId=cal_puerto
        FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
        if @tel='''' or LEFT(@tel,1)=''E''
            return(0) -- si esta vacio o marca error 


        select top 1 @iddncList = idTipoLista from cccalifblacklist WHERE tipo = 0 AND calif_id = @calif_id


        IF @tel IS NOT NULL AND @iddncList IS NOT NULL AND @iddncList is null
        BEGIN
            SELECT @useCalkeyBlackList = valor
            FROM ccSettings2
            WHERE setting_id = 288

            if @useCalkeyBlackList is null set @useCalkeyBlackList=0

            if @useCalkeyBlackList=0 set @cal_key=null


            --insert ccListaNegra
            INSERT INTO cclistanegra (telefono, idtipolista, calKey)
            VALUES (@tel, @iddncList, @cal_key)

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
            values (@tel,@iddncList,@camId,getdate(),@dni_id,6)
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

    SELECT @callOutId = callout_id, @camp = cam_id, @userid = user_id
    ,@statusCallId=statusCall_id
    ,@tel=cal_telefono
        FROM ccocallsout
        WHERE Cal_id = @IDCall

    IF @autoCB = 1
    BEGIN
        SELECT @DateNewDial = dateadd(mi, t_autoCB, getdate())
        FROM cccamps cam
        WHERE cam.cam_id = @camp

        EXEC ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
    END

    UPDATE ccoCallsOUT
    SET calif_id = @calif_id, califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
    WHERE cal_id = @IDCall

    exec ccspSaveDispositionResult @action=2, @callid=@IDCall, @camId=@camp,@callType=1,
    @dispotitionId=@calif_id,@subDispotitionId=@subId,@statusCallId=@statusCallId

    SELECT @useCalkeyBlackList = valor
    FROM ccSettings2
    WHERE setting_id = 288

    if @useCalkeyBlackList is null set @useCalkeyBlackList=0

    set @completatel=dbo.Completa_ListaNegra(@tel)

    if @useCalkeyBlackList=0 set @cal_key=null

    IF EXISTS (
            SELECT idTipoLista
            FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
            WHERE tipo = 1 AND calif_id = @calif_id
            ) AND NOT EXISTS (
            select 1 from ccListaNegra bl with(nolock)
            where (telefono=@tel or telefono =@completatel)
            and calKey=@cal_key
            AND bl.idtipolista IN (
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

       SELECT @number = co.cal_telefono
            ,@camId=cam_id
             ,@portId= cal_puerto
            FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
            WHERE co.cal_id = @idCall

        if exists (select 1 from ccoDialerCamp A
        inner join ccoDialers D on A.dialer_id=D.dialer_id
        where cam_id=@camId and D.Puerto=@portId and DialingType=0)
        begin
            set @isInternationalPort=1
        end

        IF(@allnumbersToBl = 1)
        BEGIN
            INSERT INTO #NUMBERS (number)
            SELECT n.number
            FROM ccoCallsOutSource c
            CROSS APPLY
            (
                VALUES
                    (c.cal_telefono),
                    (c.cal_telefono2),
                    (c.cal_telefono3),
                    (c.cal_telefono4),
                    (c.cal_telefono5)
            ) v(phone)
            CROSS APPLY
            (
                VALUES
                (
                    CASE 
                        WHEN @isInternationalPort = 1 
                            THEN dbo.Limpia(v.phone)
                        ELSE dbo.Completa_ListaNegra(v.phone)
                    END
                )
            ) n(number)
            WHERE c.callout_id = @callOutId
              AND ISNULL(n.number, '''') <> ''''
              AND LEFT(n.number, 1) <> ''E'';

        END
        ELSE
        BEGIN
            
            SET @number =case when @isInternationalPort=1 then dbo.Limpia(@number) else dbo.Completa_ListaNegra(@number) end
            
            IF(@number<>'''' or LEFT(@number, 1) <> ''E'')
            BEGIN
                INSERT INTO #NUMBERS (number) VALUES (@number)
            END
        END

        IF exists(SELECT 1 FROM #NUMBERS) begin
            INSERT INTO #NUMANDBL (iddncList)
            select cbl.idTipoLista from cccalifblacklist cbl  where cbl.calif_id=@calif_id and cbl.tipo = 1
        END

        DECLARE @Count int
        DECLARE @firstList bit = 1;  -- Solo la primera lista dispara limpieza WT/CS

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
                    EXEC ccsp_InsertDNCList_Static
                        @telephone          = @tel,
                        @ln_id              = @iddncList,
                        @calKey             = @cal_key,
                        @skipWorkingCleanup = 0;
                    
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
                    WHERE co.cal_id = @idCall
                END --Tel adn iddnclist
                SET @indexNumbers = @indexNumbers + 1
            END --WHILE NUMBERS

            -- Despues de procesar la primera lista negra,
            -- marcamos que las siguientes ya NO deben limpiar WT/CS.
            IF (@firstList = 1)
                SET @firstList = 0;

            DELETE #NUMANDBL WHERE id = @Count
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
    DECLARE @finishPreview BIT

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

    SELECT @keepDial as keepDial, @finishPreview as finishPreview

    RETURN (0)
END

SET NOCOUNT OFF'
    exec (@sql)

     SET @process = 'CREATE PROCEDURE ccsp_GetCommonNotReadyStates'
    SET @sql = 'CREATE PROCEDURE ccsp_GetCommonNotReadyStates
    @superId INT,
    @agentIds VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------
    -- 1. Agentes
    ---------------------------------
    DECLARE @AgentIdsTemp TABLE (AgentId INT PRIMARY KEY);

    INSERT INTO @AgentIdsTemp(AgentId)
    SELECT VALUE
    FROM dbo.fn_RIASplitDelimited(@agentIds, '','')
    WHERE VALUE IS NOT NULL;

    DECLARE @agentCount INT = (SELECT COUNT(*) FROM @AgentIdsTemp);

    ---------------------------------
    -- 2. Settings
    ---------------------------------
    DECLARE @TypeSetting INT;
    DECLARE @NotReadybyCampACD INT;
    DECLARE @Setting28 INT;

    SELECT @TypeSetting = valor FROM ccSettings WHERE setting_id = 87;
    SELECT @NotReadybyCampACD = valor FROM ccSettings WHERE setting_id = 135;
    SELECT @Setting28 = valor FROM ccSettings WHERE setting_id = 28;

    ---------------------------------
    -- 3. Base con NumEvents y filtro IsSup optimizado
    ---------------------------------
    ;WITH NotReadyBase AS (
        SELECT
            ag.AgentId,
            a1.TipoNotReady_id,
            dbo.NeventsNRdisp(ag.AgentId, a1.TipoNotReady_id, GETDATE()) AS NumEvents,
            a1.IsSup,
            a1.Descripcion,
            a1.Time_Acum,
            a1.Time_xEv,
            a1.Pas_Sup,
            a1.NextStatus,
            g.frame
        FROM @AgentIdsTemp ag
        INNER JOIN ccTipoNotReady a1
            ON a1.TipoNotReady_id > 0
           AND a1.StatusTipoNotReady = 1
           -- Filtrado IsSup según setting87 y setting28
           AND (
                (@TypeSetting = 1 AND a1.IsSup = @Setting28)
                OR (@TypeSetting = 2)
                OR (@TypeSetting = 3 AND a1.IsSup = 1)
                OR (@TypeSetting = 4)
           )
        INNER JOIN ccRIAnotreadyGraph ngr
            ON ngr.TipoNotReady_id = a1.TipoNotReady_id
        INNER JOIN ccRIAGraphics g
            ON g.graphic_id = ngr.graphic_id
        WHERE
            -- Filtrado por campanas solo si setting135 = 1 y TypeSetting = 4
            (
                @NotReadybyCampACD = 0
                OR @TypeSetting <> 4
                OR EXISTS (
                    SELECT 1
                    FROM ccUnavailableRelation ur
                    WHERE ur.idunavailable = a1.TipoNotReady_id
                    AND (
                        (ur.type = 0 AND ur.idCampACD IN (
                            SELECT inbound_id
                            FROM ccInboundAgentes
                            WHERE user_id = ag.AgentId
                        ))
                        OR
                        (ur.type = 1 AND ur.idCampACD IN (
                            SELECT cam_id
                            FROM ccCampsAgente
                            WHERE user_id = ag.AgentId
                        ))
                    )
                )
            )
    )

    ---------------------------------
    -- 4. Filtro supervisor (setting87)
    ---------------------------------
    SELECT
        TipoNotReady_id,
        Descripcion,
        Time_Acum,
        Time_xEv,
        Pas_Sup,
        NextStatus,
        frame,
        IsSup,
        CASE 
            WHEN MIN(NumEvents) IS NULL THEN 1
            WHEN MIN(NumEvents) = ''n'' OR MIN(NumEvents) > 0 THEN 1
            ELSE 0
        END AS expiredAttempts
    FROM NotReadyBase nrb
    WHERE
        (
            @TypeSetting <> 4
            OR EXISTS (
                SELECT 1
                FROM ccsupervisor_notready snd
                WHERE snd.TipoNotReady_id = nrb.TipoNotReady_id
                  AND snd.user_id = @superId
            )
        )
    GROUP BY
        TipoNotReady_id,
        Descripcion,
        Time_Acum,
        Time_xEv,
        Pas_Sup,
        NextStatus,
        frame,
        IsSup
    HAVING COUNT(DISTINCT AgentId) = @agentCount
    ORDER BY TipoNotReady_id;

END'
    exec (@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_AgentUpdateCallTimes]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentUpdateCallTimes]
@IDCall int,
@cal_tXfer float,
@cal_tDialog float,
@cal_tNotas float,
@TipoCall tinyint,
@cal_tRing float=0,
@mtmoh smallint = 0,
@isChatCall bit = 0,
@isErroManualCall bit =0,
@isTransferEngine bit =0,
@cal_twait float = null,
@cal_whoHung smallint = null,
@statusCall tinyint = 0
AS
set nocount on
if @IDCall<=0 
    return(0)

declare @tMinAVRS smallint
declare @cal_manual int
declare @minimoDialogo tinyint 
select @minimoDialogo = valor from ccSettings where setting_id = 13

set @cal_manual=0

if @TipoCall=1 begin--INBOUND
  if @cal_tDialog < @minimoDialogo and @isTransferEngine =1 begin
    --el status 18 es para llamada cortada con transferencia en Reminder
    exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @IDCall, @nStatus = 18
  end
  Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, 
    cal_tDialog=case when @cal_tDialog > 0 and @cal_tDialog > cal_tDialog then @cal_tDialog else cal_tDialog end, 
  cal_tNotas=@cal_tNotas, 
  cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, 
  cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end
  Where cal_id= @IDCall

  exec ccspSaveDispositionResult @action=2, @callid=@IDCall,@callType=0,@statusCallId=13


  --Actualizar tiempo total de llamada
  exec ccsp_EngineLogTransfers 2, @IDCall, @TipoCall, 2, null, @cal_tXfer, @cal_tDialog

  -- Elimina callback generado por abandono

  if @isTransferEngine = 0  begin
  Declare @ANI_x varchar(19)
  select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

  DELETE ccoWorkingTable with(rowlock ) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
  DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
  end
end
else if @TipoCall=2 begin--OUTBOUND 
    declare @calloutId int, @NotTransferQuantum bit
    select @NotTransferQuantum=case when @statusCall in (6,20) then 1 else 0 end
    Update ccoCallsOUT with(rowlock) Set cal_tXfer=case when @cal_tXfer > 0 then @cal_tXfer else cal_tXfer end, 
        cal_tRing=case when @cal_tRing > 0 then @cal_tRing else cal_tRing end, 
        cal_tDialog = case 
                when @NotTransferQuantum = 1 then 0
                when @cal_tDialog > 0 and @cal_tDialog > cal_tDialog then @cal_tDialog 
                else cal_tDialog 
                end,

        cal_tNotas=case when @cal_tNotas > 0 then @cal_tNotas else cal_tNotas end, 
        cal_tMoh=case when @mtmoh > 0 then @mtmoh else cal_tMoh end,

        cal_manual=case when @isChatCall=1 then 3 else cal_manual end,
        cal_colgada=0,
        statusCall_id = case 
                        when @statusCall != 0 then @statusCall
                        when @isErroManualCall = 0 then 13 
                        else statusCall_id 
                    end,
        totalCall_Time=case when totalCall_Time is null then @cal_tDialog else totalCall_Time end 
        ,@calloutId=callout_id,
        cal_twait = case 
                    when @NotTransferQuantum = 1 then @cal_tDialog
                    else ISNULL(@cal_twait, cal_twait)
                end,
        cal_que = case 
                when @statusCall = 6 then 1
                else cal_que
              end,
        cal_whoHung = ISNULL(@cal_whoHung, cal_whoHung)
        Where cal_id=@IDCall

    if @NotTransferQuantum = 1 return

    exec ccspSaveDispositionResult @action=2, @callid=@IDCall,@callType=1,@statusCallId=13
    
    DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE callout_id=@calloutId

    -- calcula el costo de la llamada
    exec ccsp_CstoCalculaCosto @IDCall
  select @cal_manual=cal_manual from ccoCallsOUT with(nolock) Where cal_id=@IDCall

 end

select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

if @cal_tDialog >= @tMinAVRS and @cal_manual<>1
  begin 
        insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
end

return(0)
set nocount off'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_DLRGetRotativeANI]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRGetRotativeANI]
@callout_id int,
@phones varchar(max),
@aniList int,
@algo tinyint
AS
set nocount on
DECLARE @Tels table (id int, pid varchar(2), phone varchar(32), ani varchar(32))
if @aniList<=0 begin
    SELECT * FROM @Tels
    return(0)
end

DECLARE @aniIdx varchar(500), @aniCnt smallint, @aniCurList int, @usedAniCnt int, @phoneCnt int, @ani varchar(32), @idx varchar(8)
DECLARE @id_phone INT, @phone varchar(32), @usedAni varchar(30)

if exists(select top 1 1 FROM ccRotativeAniListDetail with(nolock) WHERE id_RAniList = @aniList)
begin
    set @aniCnt= case when @algo = 3 then 2 else 1 end
end
else begin
    set @aniCnt=0
end

SELECT @aniCurList=isnull(id_RAniList,0),@aniIdx=isnull(ani_idx,'''') FROM ccoWorkingTable with(nolock) WHERE callout_id = @callout_id

IF @aniList != @aniCurList SET @aniIdx = ''''

IF @aniCnt > 0
BEGIN
    INSERT @Tels
    SELECT id,''p''+cast(id as varchar(1)),value,'''' FROM fn_RIASplitDelimited(@phones, '';'') WHERE len(value)>0

    IF OBJECT_ID(''tempdb..#UsedAniList'') IS NOT NULL DROP TABLE #UsedAniList;
    SELECT * INTO #UsedAniList FROM fn_RIASplitDelimited(@aniIdx, '','') WHERE len(value)>0
    SELECT @usedAniCnt=count(*) FROM #UsedAniList

    IF @algo = 3 and @usedAniCnt > 0 and @usedAniCnt < 2
    SELECT @usedAni = telAni FROM RowRotativeAniListDetail NOLOCK WHERE id_RAniList = @aniList AND RowNum=(
    SELECT TOP 1 value from #UsedAniList)

    DECLARE CUR_TEST CURSOR FAST_FORWARD FOR SELECT Id, phone FROM @Tels ORDER BY Id;
    OPEN CUR_TEST FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone

    WHILE @@FETCH_STATUS = 0
    BEGIN

        IF @usedAniCnt >= @aniCnt SET @aniIdx = ''''

        IF @algo = 0
        BEGIN
            SELECT @ani = dbo.TelAni(@phone,@aniList)
        END
        ELSE IF @algo = 1
        BEGIN
            SELECT TOP 1 @ani=telAni, @idx=idx FROM fnGetRotativeANI(@aniList, @aniIdx, default, default)
        END
        ELSE IF @algo = 2 or @algo = 3
        BEGIN
            DECLARE @cld varchar(3), @serie varchar(4), @cldCnt smallint
            IF len(@phone) < 10
            BEGIN
                FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone
                CONTINUE
            END
            print(@usedAni)
            IF @algo = 3 and @usedAniCnt > 0 and @usedAniCnt < 2
            BEGIN
                IF EXISTS(SELECT TOP 1 1 FROM Series NOLOCK WHERE CLD=left(@usedAni, 2))
                    SELECT @serie = substring(@usedAni, 3, 4)
                ELSE
                    SELECT @serie = substring(@usedAni, 4, 3)
            END
            print(''serie:''+@serie)
            IF @algo = 2 or (@algo = 3 and @usedAniCnt < 2)
            BEGIN
                IF EXISTS(SELECT TOP 1 1 FROM Series NOLOCK WHERE CLD=left(@phone, 2))
                    SET @cld = left(@phone, 2)
                ELSE
                    SET @cld = left(@phone, 3)
            END
            SELECT @cldCnt = count(*)
            FROM ccRotativeAniListDetail NOLOCK
            WHERE id_RAniList = @aniList
                AND (((@algo = 2 or (@algo = 3 and @usedAniCnt < 2)) and left(telAni, len(@cld))=@cld) or (@algo = 3 and @usedAniCnt >= 2))
                AND (@algo = 2 OR @usedAni is null OR left(telAni, 6) != left(@usedAni, 6) OR @usedAniCnt >= 2)
            IF @cldCnt > 0 and @usedAniCnt >= @cldCnt and @algo = 2 SET @aniIdx = ''''
            print(''@cldCnt:''+cast(@cldCnt as varchar(10)))
            DECLARE @newCld varchar(3) = case when @cldCnt > 0 and (@algo = 2 or (@algo = 3 and @usedAniCnt < 2)) then @cld else '''' end
            declare @newSerie varchar(4) = case when @algo = 2 then '''' when @usedAniCnt = 2 and @serie is not null then @serie else '''' end
            SELECT TOP 1 @ani=telAni, @idx=idx
            FROM fnGetRotativeANI(@aniList, @aniIdx
                , @newCld
                , @newSerie)
            print(''newcld:''+@newcld)
            print(''newSeries:''+@newSerie)
            print(''usedanicnt:''+cast(@usedAniCnt as varchar(10)))

        END

        SELECT @aniIdx = @aniIdx+'',''+@idx, @usedAniCnt = @usedAniCnt+1, @usedAni = @ani

        UPDATE @Tels SET ani=@ani WHERE id=@id_phone

        FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone
    END
    CLOSE CUR_TEST
    DEALLOCATE CUR_TEST

    IF @usedAniCnt > @aniCnt SET @aniIdx = ''''

    UPDATE ccoWorkingTable --WITH (ROWLOCK)
    SET id_RAniList = @aniList, ani_idx = ISNULL(@aniIdx,'''')
    WHERE callout_id = @callout_id
END

SELECT * FROM @Tels

set nocount off'
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)


    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    
    --- END  ----


    

    

    

	
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
