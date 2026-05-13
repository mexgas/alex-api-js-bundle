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
USE CCenterRIA;

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

		SET @process = 'KM47001 - Se crea campo para el tipo de ANI en llamada manual'
	SET @sql = 'IF not exists (SELECT 1 FROM SYS.columns WHERE name=''ManualCallANIMode'' 
AND OBJECT_ID = OBJECT_ID(''ccCampsExtend''))
begin
	ALTER TABLE ccCampsExtend
	ADD ManualCallANIMode SMALLINT NULL;
end'
	EXEC(@sql)

	SET @process = 'KM47001 - Se elimina el campo que ya no se va a utilizar'
	SET @sql = 'IF exists (SELECT 1 FROM SYS.columns WHERE name=''selectRotationManualDialing'' 
AND OBJECT_ID = OBJECT_ID(''ccCamps''))
begin
	ALTER TABLE ccCamps
	DROP COLUMN selectRotationManualDialing
end'
	EXEC(@sql)

	SET @process = 'KM47001 - Se agrega relación para identitificadores del log'
	SET @sql = 'IF NOT EXISTS(select 1 from relationTableColumnIdentifiers 
where tableName = ''cccampsextend'' and colunName = ''ManualCallANIMode'')
BEGIN
	INSERT INTO relationTableColumnIdentifiers(Identifiers, tableName, colunName)
	VALUES(''OUT_MANUAL_CALL_ANI_MODE'', ''ccCampsExtend'', ''ManualCallANIMode'')
END'
	EXEC(@sql)
	
	SET @process = 'KM47001 - Se agregan etiquetas'
	SET @sql = 'IF NOT EXISTS(select 1 from ccGalateaIdentifiers 
where [Description] = ''OUT_MANUAL_CALL_ANI_MODE'')
BEGIN
	INSERT INTO ccGalateaIdentifiers([Description], TagEs, TagEn, TagPt) VALUES
	(''OUT_MANUAL_CALL_ANI_MODE'', ''Asignación de ANI (llamada manual)'', ''ANI assignment (manual call)'', ''Atribuição de ANI (chamada manual)''),
	(''OUT_MANUAL_CALL_ANI_MODE_SYSTEM'', ''Por sistema'', ''By system'', ''Pelo sistema''),
	(''OUT_MANUAL_CALL_ANI_MODE_AGENT'', ''Por agente'', ''By agent'', ''Pelo agente''),
	(''OUT_MANUAL_CALL_ANI_MODE_NONE'', ''Ninguna'', ''None'', ''Nenhuma'')
END	'
	EXEC(@sql)


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

     SET @process = 'Drop Procedure [dbo].[ccsp_GalateaGetCampaignsIAController]';
    SET @sql = N'
        If Exists (Select 1 From sys.procedures Where name = N''ccsp_GalateaGetCampaignsIAController'')
            Begin
                DROP PROCEDURE ccsp_GalateaGetCampaignsIAController
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
		CASE WHEN isnull(ce.ManualCallANIMode, 0) = 2 THEN 1 ELSE 0 END as selectRotativeANI
		, CASE WHEN c.ivrScript <> 0 AND c.callsBySurvey <> 0 THEN 8 ELSE isnull(c.CampType,0) END as CampType,
		CASE WHEN @DialingMode = 1 THEN (select count(1) from ccoWorkingTable nolock where cam_id = c.cam_id) ELSE 0 END AS countJobs,
		isnull(c.timesPreview, 0) timesPreview,
		isnull(ce.zipCodeSchedule, 0) AS zipCodeSchedule,
		ISNULL(rotativeAlgorithmManual,0) as ManualCallAniAlgorithm
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
	declare @rotativeAlgorithmManual int
	select @aniList = idAniListManual, @rotativeAlgorithmManual  = rotativeAlgorithmManual from ccCamps where cam_id = @campId
	if @rotativeAlgorithmManual > 0 begin
		select telAni from ccRotativeANIListDetail where id_RAniList = @aniList
	end
	else BEGIN
		if exists(select 1 from ccEstadosAni where id_AniList = @aniList and telAni != '''' ) BEGIN
			select telAni from ccEstadosAni where id_AniList = @aniList and telAni != ''''
		END
		ELSE BEGIN
			select top 0 '''' telAni 
		END
	END			
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

------------------------------------------ BEGIN Pavel Martinez ---------------------------------------------

SET @process = 'Cambio para las HU KM56000 GalateaAdminPortsManagement'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminPortsManagement]
@action SMALLINT,
@dialer_id INT = 0,
@cam_id SMALLINT = 0,
@list_dialier_id varchar(max) ='''',
@user_id SMALLINT = 0
AS
SET NOCOUNT ON;
DECLARE @transtate BIT
IF @@TRANCOUNT = 0
BEGIN
    SET @transtate = 1
BEGIN TRANSACTION transtate
END
BEGIN TRY
    
    IF @action IN (3,4) -- activity log
    BEGIN
        DECLARE @login VARCHAR(50) = '''',
                @camp VARCHAR(40) = ''''
        DECLARE @dialerSource TABLE (dialer_id INT)

        IF @list_dialier_id = ''''
            INSERT INTO @dialerSource VALUES (@dialer_id)
        ELSE
            INSERT INTO @dialerSource
            SELECT Value FROM fn_RIASplitDelimited(@list_dialier_id, '','')
            
        SELECT 
            @login = cu.Login
        FROM ccUsers cu
        WHERE cu.User_id = @user_id

        SELECT 
            @camp = cc.cam_descripcion
        FROM ccCamps cc WHERE cc.cam_id = @cam_id

        -- activity log
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT
            ''Default'',
            GETDATE(),
            @login,
            CASE WHEN @action = 3 THEN 135 ELSE 136 END,
            14,
            cd.Descripcion,
            '''',
            @camp
        FROM ccoDialers cd
        WHERE cd.dialer_id IN (SELECT dialer_id FROM @dialerSource)
    END

    IF @action = 1 --return all ports
    BEGIN
        SELECT Dialers.dialer_id AS DialerId, Dialers.Descripcion AS PortDescription, Provedor.Descrip AS ProviderDescription, Dialers.Puerto, XferType, DialingType, case when DialingType = 1 then 0 else IdCode end AS DialingCode
        FROM [CCenterRIA].[dbo].[ccoDialers] AS Dialers INNER JOIN [CCenterRIA].[dbo].[cstoProvedor] AS Provedor 
        ON Dialers.provedor_id = Provedor.provedor_id
    END;
    IF @action = 2 --return ports for camp
    BEGIN
        SELECT dialer_id AS DialerId, cam_id AS CampId FROM [CCenterRIA].[dbo].[ccoDialerCamp] ORDER BY cam_id
    END;
    IF @action = 3 --insert port
    BEGIN
        IF @list_dialier_id = ''''
        BEGIN
            IF NOT EXISTS (SELECT dialer_id, cam_id FROM [CCenterRIA].[dbo].[ccoDialerCamp]
                WHERE dialer_id=@dialer_id AND cam_id=@cam_id)
            BEGIN
                INSERT INTO [CCenterRIA].[dbo].[ccoDialerCamp](dialer_id, cam_id) VALUES (@dialer_id, @cam_id)
            END;
        END
        ELSE
        BEGIN
            INSERT INTO [CCenterRIA].[dbo].[ccoDialerCamp](dialer_id, cam_id)
            SELECT dialer_id,@cam_id 
            FROM ccoDialers 
            WHERE dialer_id NOT IN (
                SELECT dialer_id FROM [CCenterRIA].[dbo].[ccoDialerCamp]
                WHERE dialer_id IN (SELECT dialer_id FROM @dialerSource WHERE dialer_id > 0) 
                AND cam_id=@cam_id
            ) 
            AND dialer_id IN (SELECT dialer_id FROM @dialerSource)
        END;
    END;
    IF @action = 4 --delete port
    BEGIN
        IF @list_dialier_id = ''''
        BEGIN
            DELETE FROM [CCenterRIA].[dbo].[ccoDialerCamp] WITH(ROWLOCK) WHERE cam_id = @cam_id AND dialer_id = @dialer_id
        END
        ELSE
        BEGIN
            DELETE FROM [CCenterRIA].[dbo].[ccoDialerCamp] WITH(ROWLOCK) 
            WHERE cam_id = @cam_id AND dialer_id IN (
                SELECT dialer_id 
                FROM @dialerSource 
                WHERE dialer_id > 0
            )
        END;
    END;

    IF @action = 5 --return ports for single camp
    BEGIN
        SELECT dialer_id AS DialerId, cam_id AS CampId FROM [CCenterRIA].[dbo].[ccoDialerCamp] WHERE cam_id = @cam_id ORDER BY cam_id
    END;

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
RAISERROR (''ccsp_GalateaAdminPortsManagement: %d: %s'', 16, 1, @error, @message) ;
END CATCH;'
EXEC(@sql)

SET @process = 'Cambio para las HU KM56000 GalateaDialer'
SET @sql = '    ALTER PROCEDURE [dbo].[ccsp_GalateaDialer]
    @Description varchar(40)='''',
    @DialerId int = 0,
    @PortNumber int = 0,
    @Status varchar(1)='''',
    @action smallint=0,
    @Provider smallint=0,
    @XferType smallint=0,
    @PortEnd int = 0,
    @CampId smallint = 0,
    @dialer_ids varchar(max)='''',
    @DialingType tinyint = 0,
    @idDialingCode int = 0
    AS
    set nocount on
    if @action=1
    begin
        select provedor_id as ProviderId, descrip as ProviderName  from cstoProvedor
    end
    if @action=2 --Insert
    begin
        create table #tempPortTable( portId int primary key)
        if @PortEnd>0 begin
            begin transaction
                while @PortNumber<=@portEnd begin
                insert into #tempPortTable values(@PortNumber)
                set @PortNumber=@PortNumber+1
                end
            commit transaction
        end
        else begin
            insert into #tempPortTable values(@PortNumber)
        end

        if exists(select Puerto from ccoDialers where Puerto in (select portId from #tempPortTable))
        begin
            drop table #tempPortTable
            select -1 as ResponseCode
            return(0)
        end
        Insert ccoDialers (Descripcion, Puerto, Status, provedor_id, xfertype, DialingType, IdCode)
        Select @Description+''_''+CAST(portId as varchar(5)), portId, @Status, @Provider, @XferType, case @DialingType when 2 then 0 else @DialingType end, @idDialingCode from #tempPortTable t
        select 200 as ResponseCode, dialer_id as DialerId, Descripcion as PortDescription,
        p.descrip as ProviderDescription, Puerto, XferType, DialingType, IdCode as DialingCode
        from ccoDialers d
        inner join cstoProvedor p on p.provedor_id=d.provedor_id
        where Puerto in (select portId from #tempPortTable)
        drop table #tempPortTable
    end
    if @action=3 --Update
    begin
        if exists(select Puerto from ccoDialers where Puerto=@PortNumber and dialer_id <> @DialerId)
        begin
            select -1 as ResponseCode ---Port already exists
            return(0)
        end
        Update ccoDialers set Descripcion=case @Description when '''' then Descripcion else @Description+''_''+cast(@PortNumber as varchar(5)) end,
        Puerto=case @PortNumber when '''' then Puerto else @PortNumber end, Status=case @Status when '''' then Status else @status end,
        provedor_id=case @Provider when '''' then provedor_id else @Provider end,
        xfertype = case @XferType when 0 then xfertype else @XferType end,
        DialingType = case when @DialingType = 0 then DialingType when @DialingType = 2 then 0 else @DialingType end,
        IdCode = case when @DialingType = 1 then 0 when @idDialingCode != IdCode then @idDialingCode else IdCode end
        where Dialer_id=cast(@DialerId as int)

        select 200 as ResponseCode, dialer_id as DialerId, Descripcion as PortDescription,
        p.descrip as ProviderDescription, Puerto, XferType, DialingType, case when DialingType = 1 then 0 else IdCode end as DialingCode
        from ccoDialers d
        inner join cstoProvedor p on p.provedor_id=d.provedor_id
        where dialer_id=@DialerId
    end
    if @action=4 --Delete
    begin
        if exists(select Dialer_id from ccoDialerCamp where
            Dialer_id in (select Value from dbo.fn_RIASplitDelimited (@dialer_ids, '','')))
        begin
            select -2 as ResponseCode --Existe alguna campaña que esta utilizando este dialer
            return(0)
        end
        declare @portsDelete table(DialerId int, Port int,PortDescription varchar(15))
        insert @portsDelete (DialerId,Port,PortDescription)
        select Value, Puerto,Descripcion from dbo.fn_RIASplitDelimited (@dialer_ids, '','')
        inner join ccoDialers on dialer_id=Value
        delete from ccoDialers Where Dialer_id in (select DialerId from @portsDelete)

        select 200 as ResponseCode, DialerId, PortDescription
        from @portsDelete
    end
    if @action=5 --Ports Info
    begin
        select dc.cam_id as CampId, c.cam_descripcion as CampName, graphic_id as Frame, c.IDArea, a.AreaName
        from ccoDialerCamp dc
        inner join ccCamps c on c.cam_id=dc.cam_id
        inner join ccRIACat_Areas a on a.IDArea=c.IDArea
        inner join ccRIACampsGraph cg on c.cam_id=cg.cam_id
        where dc.dialer_id=@DialerId
        return(0)
    end
    if @action = 6
begin
    select dialer_id as PortId, Descripcion as PortName from ccoDialers where dialer_id in (select Value from dbo.fn_RIASplitDelimited(@dialer_ids, '',''))
    return(0)
end

if @action = 7
begin
    select cam_descripcion from ccCamps where @CampId = cam_id
    return(0)
end

if @action = 8
begin
    select
        case
            when @Description <> '''' and @Description + ''_'' + CAST(d.Puerto as varchar) <> d.Descripcion then cast(1 as bit)
            else cast(0 as bit)
        end as NameChanged,

        case
            when @XferType <> 0 and @XferType <> d.xfertype then cast(1 as bit)
            else cast(0 as bit)
        end as XferTypeChanged,

        case
            when @Provider <> 0 and @Provider <> d.provedor_id then cast(1 as bit)
            else cast(0 as bit)
        end as ProviderChanged,

        case
            when @PortNumber <> 0 and @PortNumber <> d.Puerto then cast(1 as bit)
            else cast(0 as bit)
        end as PortNumberChanged,

        d.Descripcion as PortName,

        p.descrip as ProviderName,

        x.description as XferName

    from ccoDialers d
    left join cstoProvedor p on p.provedor_id = @Provider
    left join ccoXferType x on x.XferType_id = @XferType
    where d.dialer_id = @DialerId

    return(0)
end
    set nocount off'
EXEC(@sql)


SET @process = 'Cambio para las HU KM46002 ccsp_GalateaAreas'
set @sql='        ALTER procedure [dbo].[ccsp_GalateaAreas] 
        @option int = 2,
        @IDArea smallint = 0,
        @Descripcion varchar(40) = NULL,
        @maxMails smallint = 3,
        @maxChats smallint = 3,
        @maxTweets smallint = 3,
        @maxWhats smallint = 3,
        @maxWhatsOut smallint = 3,
        @callWhileChat bit = 0,
        @callWhileEmail bit = 0,
        @callWhileTwitter bit = 0,
        @CallWhileWhatsAppIn bit = 0,
        @CallWhileWhatsAppOut bit = 0,
        @defCampaing smallint = 0,
        @movesfromArea bit = 0,
        @userId int = NULL,
        @groupAreas varchar (MAX) = NULL,
        @toolsTransfer tinyint = NULL 
    AS

    SET NOCOUNT ON;
    
        declare @opt int = @option -1
    
        DECLARE @userLogin as varchar(40);
        SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @userId);

        if @option = 1 --Superuser info
        begin
            create table #campsIds(
                id int,
                cadena varchar(max)
            )
            
            declare @sql varchar(max),@idPivots varchar(max),@idConcat varchar(max)
            
            set @idPivots =''''
            set @idConcat=''''
            
            select @idPivots=@idPivots+Id+'','',
                @idConcat=@idConcat+''case when ''+id+'' is not null then convert(varchar(max),''+ id+'') + '''','''' else '''''''' end + 
                ''
                from (
                select distinct ''[''+convert(varchar(max),cam_id)+'']'' as Id from ccCamps   
                )x
            
            set @idPivots =SUBSTRING(@idPivots,0,len(@idPivots))
            set @idConcat =SUBSTRING(@idConcat,0,len(@idConcat)-7)
            
            set @sql=''
                select IDArea,''+@idConcat+'' from 
                (   select IDArea, cam_id from ccCamps) as T
                PIVOT (
                max(cam_id) for cam_id in (''+@idPivots+'') ) as P''

            insert into #campsIds
            exec(@sql)
            
            select a.IDArea Id, 
                a.AreaName Name, 
                a.StatusArea Status, 
                a.maxMails Mails, 
                a.maxChats Chats, 
                a.maxTweets Tweets, 
                a.maxWhats Whats,
                a.maxWhatsOut WhatsOut,
                a.callWhileChat callChat,
                a.callWhileEmail callEmail,
                a.CallWhileWhatsAppIn callWhatsIn,
                a.CallWhileWhatsAppOut callWhatsOut,
                a.CreateDate as CreateDate,         
                ISNULL(b.cadena, 0) as CampaignIds  
            from ccRIACat_Areas a --Falta el datetime 
            left join #campsIds b on a.IDArea = b.id

            drop table #campsIds
        end
        if @option = 2 -- Select de las areas
        begin
            IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
            Create table #Areas(
                IDArea smallint,
                AreaName varchar(MAX),
                maxChats tinyint ,
                maxMails tinyint ,
                maxWhats tinyint ,
                maxWhatsOut tinyint ,
                callWhileChat bit, 
                callWhileEmail bit,
                CallWhileWhatsAppIn bit,
                CallWhileWhatsAppOut bit,
                users int,
                admins int,
                camps int,
                acds int,
                maxTweets tinyint,
                toolsTransfer tinyint
            )
            insert into #Areas
            EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@maxWhats=@maxWhats,@maxWhatsOut=@maxWhatsOut,@callWhileChat=@callWhileChat,@callWhileEmail=@callWhileEmail,@callWhileWhatsAppIn=@callWhileWhatsAppIn,@callWhileWhatsAppOut=@callWhileWhatsAppOut,@defCampaing=@defCampaing, @isKolob=1
            select a.*,rca.CreateDate,Isnull(rca.defCampaing,0) as defCampaing
            from #Areas a
            inner join ccRIACat_Areas rca with(nolock) on a.IDArea = rca.IDArea

            IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
        end
        if @option = 3 -- Insert new area
        begin
        IF OBJECT_ID(''tempdb..#InsertAreas'') IS NOT NULL DROP TABLE #InsertAreas;
            Create table #InsertAreas(
                result int,
                idAreas decimal
            )
            insert into #InsertAreas
            EXEC ccsp_RIA_ABCAreas 
                @option = @opt,
                @IDArea=@IDArea,
                @Descripcion=@Descripcion,
                @maxMails=@maxMails,
                @maxChats=@maxChats,
                @maxTweets=@maxTweets,
                @maxWhats=@maxWhats,
                @maxWhatsOut=@maxWhatsOut,
                @callWhileChat=@callWhileChat,
                @callWhileEmail=@callWhileEmail,
                @callWhileWhatsAppIn=@callWhileWhatsAppIn,
                @callWhileWhatsAppOut=@callWhileWhatsAppOut,
                @defCampaing=@defCampaing,
                @toolsTransfer=@toolsTransfer
            if (select result from #InsertAreas) = 1
                begin

                    --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD AL CREAR UN AREA
                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@Descripcion, getDate(), @userLogin, 17, 3, '''', '''', @Descripcion);

                    if(@movesfromArea = 1) begin
                        Update ccUsers set IDArea = (select idAreas from #InsertAreas), status = 1 where User_id = @userId
                    end
                end
            Select * from #InsertAreas
        end
        if @option = 4 -- Delete Areas
        begin
            IF OBJECT_ID(''tempdb..#AreasDelete'') IS NOT NULL DROP TABLE #AreasDelete;
            SELECT value As IDArea into #AreasDelete FROM fn_RIASplitDelimited(@groupAreas, '','')
        
        
            if (exists(select IDArea from ccUsers where IDArea=(Select top 1 IDArea from #AreasDelete)) or exists(select IDArea from ccCamps where IDArea = (Select top 1 IDArea from #AreasDelete))
              or exists(select IDArea from ccInbound where IDArea=(Select top 1 IDArea from #AreasDelete))) and (select valor from ccSettings where setting_id=95)<>1
            BEGIN
                Select -1 as result
            END
            ELSE
            BEGIN
                declare @DWorkGroups as varchar(500)
                insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
                select user_id,cam_id,prioridad,skill,rel_id,IDWG
                from ccCampsAgente
                where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
                select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
                from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))
                Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
                select user_id,cam_id,tipo,IDWG,monitored
                from ccSupervisorCam
                where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

                delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
                delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
                delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
                where cam_id in (select cam_id from ccCamps where IDArea in (Select IDArea from #AreasDelete)))

                Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))
                Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))

                Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
                Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
                Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))

                select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)
                Delete from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)

                if (select valor from ccSettings where setting_id=95)=1
                begin
                Update ccInbound set IDArea=NULL, status=0 where IDArea in (Select IDArea from #AreasDelete)
                Update ccCamps set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
                Update ccUsers set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
                end

                Update ccRIACat_Areas set StatusArea=0 where IDArea in (Select IDArea from #AreasDelete)

                --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA AREA ELIMINADA
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                SELECT AreaName, getDate(), @userLogin, 19, 3, '''', '''', AreaName
                FROM ccRIACat_Areas 
                WHERE IDArea in (Select IDArea from #AreasDelete);

                select 1 as result
            END --  exec ccsp_GalateaAreas @option=5,@IDArea=1,@Descripcion=NULL,@maxMails=NULL,@maxChats=NULL,@maxWhats=NULL,@maxWhatsOut=NULL,@callWhileChat=1,@callWhileEmail=1,@callWhileWhatsAppIn=0,@callWhileWhatsAppOut=0,@defCampaing=NULL,@movesfromArea=0,@userId=17,@toolsTransfer=3;
        end
        if @option = 5 -- update Areas       
        begin
            if exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion and IDArea <> @IDArea)
                begin
                    select -1 as result
                    return
                end
            else
                begin

                    --INICIO - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

                    DECLARE @PrevDescription AS VARCHAR(50);
                    DECLARE @SelectedArea AS VARCHAR(10) = CAST(@IDArea AS varchar(10));

                    SELECT @PrevDescription = AreaName
                    FROM ccRIACat_Areas 
                    WHERE IDArea = @IDArea;

                    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

                        CREATE TABLE #CCAreasTable 
                    (
                        columnInfo VARCHAR(255),
                        dataInfo VARCHAR(255),
                        identifierInfo VARCHAR(255)
                    );  

                    update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),maxWhats=isnull(@maxWhats,maxWhats),maxWhatsOut=isnull(@maxWhatsOut,maxWhatsOut),callWhileChat=isnull(@callWhileChat,callWhileChat),callWhileEmail=isnull(@callWhileEmail,callWhileEmail),callWhileWhatsAppIn=isnull(@callWhileWhatsAppIn,callWhileWhatsAppIn),callWhileWhatsAppOut=isnull(@callWhileWhatsAppOut,callWhileWhatsAppOut),defCampaing=isnull(@defCampaing, 0), ToolsTransfer=case when @toolsTransfer = 3 then ToolsTransfer else @toolsTransfer end where IDArea=@IDArea

                   EXEC InsertLogAdminGalatea @action=2, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId, @tableTemp=''#CCAreasTable'';

                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                    SELECT 
                        CASE WHEN AT.identifierInfo IS NOT NULL THEN
                            CASE 
                                WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                        ELSE '''' END,
                        getDate(), 
                        @userLogin, 
                        18, 
                        3, 
                        AT.identifierInfo,
                        CASE WHEN AT.identifierInfo IS NOT NULL THEN
                            CASE 
                                WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @Descripcion
                                WHEN AT.identifierInfo = ''T&SET_CAMPAIGN'' THEN 
                                    CASE 
                                        WHEN @defCampaing IS NOT NULL AND @defCampaing <> 0 THEN
                                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @defCampaing)
                                        ELSE ''T&COMMON_NONE'' END
                                WHEN AT.identifierInfo = ''T&SET_TOOLSTRANSFER'' THEN
                                    CASE
                                        WHEN @toolsTransfer = 1 THEN ''COMMON_ENABLED''
                                        ELSE ''COMMON_DISABLED'' END
                                when at.identifierInfo = ''T&SET_CALL_WHILE_CHAT'' then 
                                    case 
                                        when @callWhileChat = 1 then ''COMMON_ENABLED''
                                        else ''COMMON_DISABLED'' end
                                when at.identifierInfo = ''T&SET_CALL_WHILE_EMAIL'' then 
                                    case 
                                        when @callWhileEmail = 1 then ''COMMON_ENABLED''
                                            else ''COMMON_DISABLED'' end
                when at.identifierInfo = ''T&SET_CALL_WHILE_WHATSAPP_IN'' then 
                        case 
                        when @CallWhileWhatsAppIn = 1 then ''COMMON_ENABLED''
                            else ''COMMON_DISABLED'' end
                when at.identifierInfo = ''T&SET_CALL_WHILE_WHATSAPP_OUT'' then 
                    case 
                    when @CallWhileWhatsAppOut= 1 then ''COMMON_ENABLED''
                        else ''COMMON_DISABLED'' end

                                ELSE AT.dataInfo END
                        ELSE '''' END, 
                        CASE WHEN AT.identifierInfo IS NOT NULL THEN
                            CASE 
                                WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                        ELSE '''' END
                    FROM #CCAreasTable AS AT;

                    EXEC InsertLogAdminGalatea @action=3, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

                    IF OBJECT_ID(N''tempdb..#CCUsersTable'') IS NOT NULL DROP TABLE #CCUsersTable

                    --FIN - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

                end
            if @maxChats is not null
                begin
                    Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
                end
            if @movesfromArea = 1
            Begin
                Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @userId
            End
            select 1 as result
        END
        IF @option = 6 -- get configAreaMultimedia by userId
        BEGIN
            SELECT 
            crca.callWhileChat
            , crca.callWhileEmail
            , crca.CallWhileWhatsAppIn
            , crca.CallWhileWhatsAppOut
            FROM  
            dbo.ccRIAWorkGroupUsers AS crwgu INNER JOIN dbo.ccRIAAreaWorkGroup AS crawg 
            ON crawg.IDWG = crwgu.IDWG INNER JOIN dbo.ccRIACat_Areas AS crca 
            ON crca.IDArea = crawg.IDArea WHERE crwgu.User_id = @userId 
            GROUP BY crca.IDArea, crca.callWhileChat, crca.callWhileEmail, crca.CallWhileWhatsAppIn, crca.CallWhileWhatsAppOut

            RETURN (0)
        END
        IF(@option = 7) -- get area campaign relation by areaId
        BEGIN
            SELECT crcew.IdCampEsp, crawg.IDArea FROM dbo.ccRIACampEspWG AS crcew 
                                    INNER JOIN dbo.ccRIAAreaWorkGroup AS crawg
                                    ON crawg.IDWG = crcew.IDWG
                                    WHERE crcew.Tipo = 1 AND crawg.IDArea = @idArea
            RETURN (0)
        END
        IF @option = 9 
        BEGIN
            IF EXISTS (SELECT 1 FROM ccRIACat_Areas WHERE AreaName = @Descripcion AND StatusArea = 0)
                SELECT 1 AS Result 
            ELSE
                SELECT 0 AS Result 
            RETURN
        END
        
    SET NOCOUNT ON;'
EXEC(@sql)
------------------------------------------ END Pavel Martinez ---------------------------------------------

    
------------------------------------------ END Ulises ---------------------------------------------

    SET @process = 'CREATE TABLE dbo.ccCalifCampIA'
    SET @sql = 'IF not exists(select * from sys.tables where name=''ccCalifCampIA'') begin
    CREATE TABLE dbo.ccCalifCampIA (
        calif_id smallint NOT NULL,
        cam_id   smallint NOT NULL,
        tipo     bit      NOT NULL,
        CONSTRAINT PK_ccCalifCampIA PRIMARY KEY (calif_id, cam_id, tipo)
    );  
end'
    exec (@sql)  
    

    SET @process = 'insert ccGalateaOperations 175,176,177'
    SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM ccGalateaOperations
    WHERE OperationId = 175
)
BEGIN
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
    VALUES (175, ''Asignar calificación de agente virtual'', ''Assign virtual agent disposition'', ''Atribuir classificação de agente virtual'');
END
IF NOT EXISTS (
    SELECT 1
    FROM ccGalateaOperations
    WHERE OperationId = 176
)
BEGIN
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
    VALUES (176, ''Desasignar calificación de agente virtual'', ''Unassign virtual agent disposition'', ''Cancelar atribuição de classificação de agente virtual'');
END

IF NOT EXISTS (
    SELECT 1
    FROM ccGalateaOperations
    WHERE OperationId = 177
)
BEGIN
    INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
    VALUES (
        177,
        ''Eliminar calificación de agente virtual'',
        ''Delete virtual agent disposition'',
        ''Excluir classificação de agente virtual''
    );
END

IF NOT EXISTS (
    SELECT 1
    FROM ccGalateaOperations
    WHERE OperationId = 178
)
BEGIN
    insert into ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
    values (178, ''Crear calificación de agente virtual'', ''Create virtual agent disposition'', ''Criar classificação de agente virtual'')
END

IF NOT EXISTS (
    SELECT 1
    FROM ccGalateaOperations
    WHERE OperationId = 179
)
BEGIN
    insert into ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
    values (179, ''Editar calificación de agente virtual'', ''Edit virtual agent disposition'', ''Editar classificação de agente virtual'')
END

--Nombre
 IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''AI_UPDATE_DISPOSITION_NAME'' 
    AND tableName = ''cctipoCalif_IA'' AND colunName = ''Name_cal'')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values (''AI_UPDATE_DISPOSITION_NAME'', ''cctipoCalif_IA'', ''Name_cal'')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_NAME'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_NAME'', ''Nombre'', ''Name'', ''Nome'')
END

--Descripción
 IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''AI_UPDATE_DISPOSITION_DESCRIPTION'' 
    AND tableName = ''cctipoCalif_IA'' AND colunName = ''Description_cal'')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values (''AI_UPDATE_DISPOSITION_DESCRIPTION'', ''cctipoCalif_IA'', ''Description_cal'')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_DESCRIPTION'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_DESCRIPTION'', ''Descripción'', ''Description'', ''Descrição'')
END

--Devolver llamada 
 IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''AI_UPDATE_DISPOSITION_CALLBACK'' 
    AND tableName = ''cctipoCalif_IA'' AND colunName = ''CanReprogram'')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values (''AI_UPDATE_DISPOSITION_CALLBACK'', ''cctipoCalif_IA'', ''CanReprogram'')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_CALLBACK'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_CALLBACK'', ''Devolver llamada'', ''Call back'', ''Retornar chamada'')
END
--Color
 IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''AI_UPDATE_DISPOSITION_COLOR'' 
    AND tableName = ''cctipoCalif_IA'' AND colunName = ''Color'')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values (''AI_UPDATE_DISPOSITION_COLOR'', ''cctipoCalif_IA'', ''Color'')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_COLOR'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_COLOR'', ''Color'', ''Color'', ''Cor'')
END
--Transferencia
IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''AI_UPDATE_DISPOSITION_TRANSFER'' 
    AND tableName = ''cctipoCalif_IA'' AND colunName = ''AplTransfer'')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values (''AI_UPDATE_DISPOSITION_TRANSFER'', ''cctipoCalif_IA'', ''AplTransfer'')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_TRANSFER'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_TRANSFER'', ''Transferir llamada'', ''Transfer call'', ''Tipo da transferência'')
END
--Transferencia RadioButton
IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''AI_UPDATE_DISPOSITION_TRANSFER_OPTION'' 
    AND tableName = ''cctipoCalif_IA'' AND colunName = ''TransferOpcion'')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values (''AI_UPDATE_DISPOSITION_TRANSFER_OPTION'', ''cctipoCalif_IA'', ''TransferOpcion'')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_TRANSFER_OPTION'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_TRANSFER_OPTION'', ''Tipo de transferencia'', ''Transfer type'', ''Tipo da transferência'')
END
--Extracción
IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''AI_UPDATE_DISPOSITION_EXTRACTION'' 
    AND tableName = ''cctipoCalif_IA'' AND colunName = ''AplExtDate'')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values (''AI_UPDATE_DISPOSITION_EXTRACTION'', ''cctipoCalif_IA'', ''AplExtDate'')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_EXTRACTION'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_EXTRACTION'', ''Capturar datos automáticamente'', ''Capture data automatically'', ''Capturar dados automaticamente'')
END
--Descripción Extracción
IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''AI_UPDATE_DISPOSITION_EXTRACTION_DESCRIPTION'' 
    AND tableName = ''cctipoCalif_IA'' AND colunName = ''ExtDescription'')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values (''AI_UPDATE_DISPOSITION_EXTRACTION_DESCRIPTION'', ''cctipoCalif_IA'', ''ExtDescription'')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_EXTRACTION_DESCRIPTION'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_EXTRACTION_DESCRIPTION'', ''Datos a capturar'', ''Data to capture'', ''Dados a capturar'')
END
--LN
IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''AI_UPDATE_DISPOSITION_DNC'' 
    AND tableName = ''cctipoCalif_IA'' AND colunName = ''AplBlackList'')
BEGIN
    insert into relationTableColumnIdentifiers(Identifiers, tableName, colunName) 
    values (''AI_UPDATE_DISPOSITION_DNC'', ''cctipoCalif_IA'', ''AplBlackList'')
END
IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_DNC'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_DNC'', ''Adicionar registro a lista negra'', ''Add record to DNC list'', ''Adicionar registro a lista negra'')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_TRANSFER_OPTION_1'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_TRANSFER_OPTION_1'', ''Por escalamiento'', ''On escalation'', ''Por escalonamento'')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_TRANSFER_OPTION_2'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_TRANSFER_OPTION_2'', ''Por gestión exitosa'', ''On successful interaction'', ''Por interação bem‑sucedida'')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_TRANSFER_OPTION_3'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_TRANSFER_OPTION_3'', ''Por seguimiento (IVR)'', ''On follow‑up (IVR)'', ''Por acompanhamento (IVR)'')
END



IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_CALLBACK_OPTION_1'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_CALLBACK_OPTION_1'', ''Deshabilitado'', ''Disabled'', ''Desativado'')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_CALLBACK_OPTION_2'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_CALLBACK_OPTION_2'', ''Programable'', ''Custom'', ''Programável'')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_CALLBACK_OPTION_3'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_CALLBACK_OPTION_3'', ''Por defecto'', ''Default'', ''Padrão'')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_CAMPAIGN'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_CAMPAIGN'', '' Destino de transferencia: Campaña'', ''Transfer destination: Campaign'', ''Destino da transferência: Campanha'')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_NUMBER'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_NUMBER'', ''Destino de transferencia: Número externo'', ''Transfer destination: External number'', ''Destino da transferência: Número externo'')
END

IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_DIRECTORY'')
BEGIN
    insert into ccGalateaIdentifiers(Description, TagEs, TagEn, TagPt) 
    values (''AI_UPDATE_DISPOSITION_TRANSFER_DESTINY_DIRECTORY'', ''Destino de transferencia: Directorio'', ''Transfer destination: Transfer list'', ''Destino da transferência: Catálogo'')
END

'
    exec (@sql)
    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminDispositionRelations]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminDispositionRelations]
@command INT,
@type TINYINT = NULL, --0=In, 1=Out
@cam_id SMALLINT = NULL,
@califIdLst VARCHAR(8000) = NULL,
@user_id SMALLINT = NULL,
@operationId INT = NULL
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
IF @command=2  -- Assign disposition to inbound or outbound campaign
 BEGIN 
    IF @Type=0 
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
        EXECUTE sp_executesql @sql
    END
    ELSE
    BEGIN
        SET @sql = ''insert into ccCalifCamp(calif_id,cam_id,tipo) 
        select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalifOUT f where 
        f.CalifOut_Status=1 and f.calif_id in ('' + @califIdLst + '') and cam_id = '' + CAST(@cam_id AS VARCHAR(10)) + ''
        and not exists(
        select a.calif_id,c.cam_id, 1 from cctipoCalifOUT a
        join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 1
        join ccCamps c on c.cam_id = b.cam_id
        where f.calif_id = a.calif_id and e.cam_id = c.cam_id
        and b.cam_id = '' + CAST(@cam_id AS VARCHAR(10)) + '')''
        EXECUTE sp_executesql @sql
        UPDATE ccCamps SET keepDial=dbo.fn_keepDial_Camps(@cam_id) WHERE cam_id=@cam_id 
        RETURN(0)
    END
 END
 IF @command=3 -- Unassign disposition to inbound or outbound
 BEGIN
    DELETE ccCalifCamp WHERE cam_id=@cam_id AND tipo=@type AND calif_id IN (SELECT value FROM dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    UPDATE ccCamps SET keepDial=dbo.fn_keepDial_Camps(@cam_id) WHERE cam_id=@cam_id
    RETURN(0)
 END
 IF @command=4 
 BEGIN
    IF(@type = 0) 
    BEGIN
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT 
            (SELECT AreaName FROM ccRIACat_Areas c INNER JOIN ccInbound i ON c.IDArea = i.IDArea WHERE Inbound_id = @cam_id),
            GETDATE(),
            (SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
            68,
            7,
            '''',
            Description,
            (SELECT descripcion FROM ccInbound WHERE Inbound_id = @cam_id)
            FROM ccTipoCalif 
            WHERE calif_id IN (SELECT value FROM dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    END
 END
 IF @command=5
 BEGIN
    IF(@type = 0) 
    BEGIN
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT 
            (SELECT AreaName FROM ccRIACat_Areas c INNER JOIN ccInbound i ON c.IDArea = i.IDArea WHERE Inbound_id = @cam_id),
            GETDATE(),
            (SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
            69,
            7,
            '''',
            Description,
            (SELECT descripcion FROM ccInbound WHERE Inbound_id = @cam_id)
            FROM ccTipoCalif 
            WHERE calif_id IN (SELECT value FROM dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    END
 END
 IF @command = 6 -- Assign dispositions to inbound or outbound AI campaign
 BEGIN
    if @Type=0 
    begin   
        set @sql = ''declare @NotAssigned table(NotAssigned int); 
        declare @Assigned table(Assigned int);

        insert into @NotAssigned (NotAssigned)
        SELECT calif_id 
        FROM cctipoCalif_IA MAIN
        WHERE MAIN.calif_id IN (''+ @califIdLst+ '')
        AND EXISTS (
            SELECT 1 
            FROM ccInbound I
            WHERE I.Inbound_id = '' + cast(@cam_id as varchar(10)) + ''
            AND (
                ------------------------------------------------------------
                -- GRUPO 1: Validación de Reprogramación / Callback
                -- Si pide reprogramar, DEBE tener cam_id.
                ------------------------------------------------------------
                (
                   (MAIN.CanReprogram = 1 OR MAIN.autoCallback = 1) 
                   AND 
                   (I.cam_id IS NULL OR I.cam_id = 0)
                )

                OR 
                ------------------------------------------------------------
                -- GRUPO 2: Validación de Transferencia (AplTransfer)
                -- Si pide transferir, DEBE tener los IDs configurados.
                ------------------------------------------------------------
                (
                    MAIN.AplTransfer = 1 
                    AND (
                        -- Si Opcion es 1, ERROR si falta idForNonComprehension
                        (MAIN.TransferOpcion = 1 
                        AND (I.idForNonComprehension IS NULL OR I.idForNonComprehension = 0))
                
                        OR
                
                        -- Si Opcion es 2, ERROR si falta idForSuccessfulTransaction
                        (MAIN.TransferOpcion = 2 AND 
                        (I.idForSuccessfulTransaction IS NULL OR I.idForSuccessfulTransaction = 0))
                    )
                )
            )
        )

        insert into ccCalifCampIA(calif_id,cam_id,tipo) 
        select f.calif_id, e.inbound_id, 0 
        from ccInbound e, cctipoCalif_IA f 
        where f.Cali_StatusIA=1 and f.calif_id in ('' + @califIdLst + '') and f.calif_id not in (select NotAssigned from @NotAssigned)
        and Inbound_id = '' + cast(@cam_id as varchar(10)) + ''
        and not exists(
            select a.calif_id,c.inbound_id,0 from cctipoCalif a
            join ccCalifCampIA b on a.calif_id = b.calif_id and tipo = 0
            join ccInbound c on c.inbound_id = b.cam_id
            where f.calif_id = a.calif_id and e.inbound_id = c.inbound_id
            and c.Inbound_id = '' + cast(@cam_id as varchar(10)) + '')

        insert into @Assigned (Assigned)
        select calif_id from cctipoCalif_IA where calif_id in ('' + @califIdLst + '') and calif_id not in (select NotAssigned from @NotAssigned)

        declare @NotAssignedStr varchar(8000), @AssignedStr varchar(8000)
        SELECT @AssignedStr = COALESCE(@AssignedStr + '''','''', '''''''') + cast(Assigned as varchar(10)) from @Assigned
        select @NotAssignedStr = coalesce(@NotAssignedStr + '''','''', '''''''') + cast(NotAssigned as varchar(10)) from @NotAssigned

        select @AssignedStr [Assigned], @NotAssignedStr [NotAssigned], cast(1 as bit) as IsAICamp''
        execute sp_executesql @sql
        return(0)
    end
    else
    begin
        set @sql = ''insert into ccCalifCampIA(calif_id,cam_id,tipo) 
        select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalif_IA f where 
        f.Cali_StatusIA=1 and f.calif_id in ('' + @califIdLst + '') and cam_id = '' + cast(@cam_id as varchar(10)) + ''
        and not exists(
        select a.calif_id,c.cam_id, 1 from cctipoCalif_IA a
        join ccCalifCampIA b on a.calif_id = b.calif_id and tipo = 1
        join ccCamps c on c.cam_id = b.cam_id
        where f.calif_id = a.calif_id and e.cam_id = c.cam_id
        and b.cam_id = '' + cast(@cam_id as varchar(10)) + '')''
        execute sp_executesql @sql
        return(0)
    end
 END
 IF @command = 7 -- Unassign dispositions to inbound or outbound AI campaign
 BEGIN 
    delete ccCalifCampIA WHERE cam_id=@cam_id and tipo=@type and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    return(0)
 END
 If @command = 8
begin
    select 
        cast (0 as int) [type], 
        i.inbound_id as cam_id, 
        c.calif_id 
    from ccInbound i inner join dbo.ccCalifCampIA AS c on i.inbound_id = c.cam_id and c.tipo = 0
    inner join dbo.cctipoCalif_IA AS t on c.calif_id = t.calif_id
    UNION
    select 
        cast (1 as int) [type], 
        o.cam_id, 
        c.calif_id 
    from ccCamps o inner join ccCalifCampIA c on o.cam_id = c.cam_id and c.tipo = 1
    inner join cctipoCalif_IA co on c.calif_id = co.calif_id
    order by [type], cam_id, calif_id
END
IF @command = 9 -- Registry AI dispositions log to assign/unassign
BEGIN
    IF(@type = 0)
    BEGIN 
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT 
            (select AreaName from ccRIACat_Areas c inner join ccInbound i on c.IDArea = i.IDArea where Inbound_id = @cam_id),
            getDate(),
            (SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
            @operationId,
            7,
            '''',
            Name_cal,
            (select descripcion from ccInbound where Inbound_id = @cam_id)
            from cctipoCalif_IA 
            where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    END
    ELSE
    BEGIN
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT 
            (select AreaName from dbo.ccRIACat_Areas AS crca inner join dbo.ccCamps AS cc  on crca.IDArea = cc.IDArea where cc.cam_id = @cam_id),
            getDate(),
            (SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
            @operationId,
            7,
            '''',
            Name_cal,
            (select cam_descripcion from dbo.ccCamps  where cam_id = @cam_id)
            from cctipoCalif_IA 
            where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    end
END

IF @command = 10  -- DELETE IA  
BEGIN  
    BEGIN TRY  
  
        DECLARE @Ids TABLE (calif_id INT)  
        DECLARE @Active TABLE (calif_id INT)  
        DECLARE @ToDelete TABLE (calif_id INT)  
  
        -- IDs enviados  
        INSERT INTO @Ids  
        SELECT CAST(value AS INT)  
        FROM dbo.fn_RIASplitDelimited(@califIdLst, '','')  
  
        -- Detectar campañas activas  
        INSERT INTO @Active  
        SELECT DISTINCT c.calif_id  
        FROM ccCalifCampIA c  
        INNER JOIN @Ids i ON i.calif_id = c.calif_id  
        LEFT JOIN ccCamps o ON o.cam_id = c.cam_id AND c.tipo = 1  
        LEFT JOIN ccInbound ib ON ib.Inbound_id = c.cam_id AND c.tipo = 0  
        WHERE   
            (c.tipo = 1 AND o.cam_procesando = 1)  
            OR  
            (c.tipo = 0 AND ib.Status = 1)  
  
        -- Si todos están activos  
        IF (SELECT COUNT(*) FROM @Ids) = (SELECT COUNT(*) FROM @Active)  
        BEGIN  
            SELECT -27 AS ResponseCode,  
                   ''All dispositions are active in campaigns.'' AS ResponseCodeDescription  
            RETURN  
        END  
  
        -- Determinar cuáles sí se pueden borrar  
        INSERT INTO @ToDelete  
        SELECT calif_id FROM @Ids  
        WHERE calif_id NOT IN (SELECT calif_id FROM @Active)  
  
        -- Eliminación lógica  
        UPDATE cctipoCalif_IA  
        SET Cali_StatusIA = 0  
        WHERE calif_id IN (SELECT calif_id FROM @ToDelete)  
  
        -- Eliminar relaciones  
        DELETE FROM ccCalifCampIA  
        WHERE calif_id IN (SELECT calif_id FROM @ToDelete)  
  
        -- Log por cada nombre eliminado  
        INSERT INTO ccGalateaActivityLog  
        (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)  
        SELECT   
            NULL,  
            GETDATE(),  
            (SELECT [Login] FROM ccUsers WHERE User_id = @user_id),  
      177,  
            7,  
            '''',  
            Name_cal,  
            ''IA Disposition Delete''  
        FROM cctipoCalif_IA  
        WHERE calif_id IN (SELECT calif_id FROM @ToDelete)  
  
        -- Si hubo algunas activas / parcial  
        IF EXISTS (SELECT 1 FROM @Active)  
        BEGIN  
            SELECT -28 AS ResponseCode,  
                   ''Partial Success. Some dispositions are active.'' AS ResponseCodeDescription  
            RETURN  
        END  
  
        -- Todo correcto  
        SELECT 200 AS ResponseCode,  
               ''SUCCESS'' AS ResponseCodeDescription  
  
    END TRY  
    BEGIN CATCH  
        SELECT -1 AS ResponseCode,  
               ERROR_MESSAGE() AS ResponseCodeDescription  
    END CATCH  
END  

set nocount OFF'
    exec (@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_ManageQuantumDispositions]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ManageQuantumDispositions]
        @Action INT,
        @CampId INT = NULL,
        @AgentId INT = NULL,
        @CampType INT = NULL,
        @VoiceId INT = NULL
AS
BEGIN
    DECLARE @Inbound INT = 0, @Outbound INT = 1
    IF @Action = 1 --Get API Data
    BEGIN
        DECLARE @key VARCHAR(255)
        SELECT @key = valor FROM ccSettings2 WHERE setting_id = 284
        SELECT valor AS ApiUrl, @key AS [Key] FROM ccSettings2 WHERE setting_id = 290
    END
    IF @Action = 2 --Get Quantum Id Agent Data
    BEGIN
        SELECT quantumAgentId
        FROM ccVirtualAgent
        WHERE 
            (@AgentId IS NOT NULL AND idAgent = @AgentId)
            OR (@AgentId IS NULL AND campType = @CampType AND idCampaign = @CampId);
    END
    IF @Action = 3 --Get Quantum Dispositions by camp
    BEGIN
        SELECT 
            cci.calif_id AS [Id],
        cci.Description_cal AS [Description],
        CAST(CASE WHEN cci.CanReprogram = 1 OR cci.autoCallback = 1 THEN 1 ELSE 0 END AS INT) AS Callback,
        CAST(CASE 
        WHEN cci.TransferOpcion = 1 THEN 2 /*Modificar esta parte para que mande si es asistida o ciega*/ ELSE 0 END  AS INT) AS Fallback,
        CAST(CASE 
        WHEN cci.TransferOpcion = 2  THEN 2 /*Modificar esta parte para que mande si es asistida o ciega*/ ELSE 0  END AS INT) AS Success,
        CAST(CASE 
        WHEN cci.TransferOpcion = 3 THEN 2 /*Modificar esta parte para que mande si es asistida o ciega*/ ELSE 0 END AS INT) AS Ivr,
        cci.ExtDescription AS RequiredData
        FROM dbo.ccCalifCampIA AS ccci INNER JOIN dbo.cctipoCalif_IA AS cci
        ON cci.calif_id = ccci.calif_id
        WHERE ccci.tipo = @CampType
        AND ccci.cam_id = @CampId
    END
    IF @Action = 4 -- Get Quantum Agent Voice Id
    BEGIN
        SELECT ISNULL(
            (SELECT QuantumVoiceId 
             FROM ccVirtualAgentVoices 
             WHERE ID = @VoiceId), 
            ''''
        ) AS QuantumVoiceId;
    END

    IF @Action = 5 -- Get Transfer Status 
    BEGIN
        IF @CampType = 0
        BEGIN
            SELECT 
                 CASE 
                -- 1. If both transfer options are disabled (0), return FALSE (0).
                WHEN ISNULL(cie.TransferToHumanAgents, 0) = 0 
                     AND ISNULL(cie.TransferOnSuccessfulHandling, 0) = 0 THEN CAST(0 AS BIT)

                -- 2. LOGICAL VALIDATION:
                -- Ensure that all active configurations are valid and have no missing requirements.
                WHEN 
                    (
                        -- Validate ''TransferToHumanAgents'' integrity
                        CASE 
                            WHEN cie.TransferToHumanAgents = 2 THEN 1 -- Valid: External transfer
                            WHEN cie.TransferToHumanAgents = 1 AND ISNULL(ci2.idForNonComprehension, 0) <> 0 THEN 1 -- Valid: Campaign transfer with assigned ID
                            WHEN cie.TransferToHumanAgents = 0 THEN 1 -- Valid: Option is disabled, skip validation
                            ELSE 0 -- Invalid: Option enabled but missing target campaign ID
                        END = 1
                    )
                    AND -- ALL enabled configurations must be valid simultaneously
                    (
                        -- Validate ''TransferOnSuccessfulHandling'' integrity
                        CASE 
                            WHEN cie.TransferOnSuccessfulHandling = 2 THEN 1 -- Valid: External transfer
                            WHEN cie.TransferOnSuccessfulHandling = 1 AND ISNULL(ci2.idForSuccessfulTransaction, 0) <> 0 THEN 1 -- Valid: Campaign transfer with assigned ID
                            WHEN cie.TransferOnSuccessfulHandling = 0 THEN 1 -- Valid: Option is disabled, skip validation
                            ELSE 0 -- Invalid: Option enabled but missing target campaign ID
                        END = 1
                    )
                    THEN CAST(1 AS BIT)

                ELSE CAST(0 AS BIT)
            END
            FROM dbo.ccInboundExtend AS cie
            INNER JOIN dbo.ccInbound AS ci2
            ON ci2.Inbound_id = cie.Inbound_id
            WHERE cie.Inbound_id= @CampId;
        END
        ELSE
        BEGIN
            SELECT 
            CASE 
                WHEN EXISTS (SELECT 1 FROM dbo.ccInbound WHERE cam_id = @CampId) 
                THEN CAST(1 AS BIT) 
                ELSE CAST(0 AS BIT) 
            END AS ExisteCampana;
        END
    END

    IF @Action = 6 -- Agent Id By Campaign 
    BEGIN
        IF(@CampType = 0)
        BEGIN
        
            SELECT ISNULL(
                (SELECT TOP 1 idAgent 
                 FROM ccVirtualAgent 
                 WHERE idCampaign = @CampId 
                   AND mediaType = 11
                   AND campType = 0),
                0
            ) AS idAgent;
        END
        ELSE
        BEGIN
            SELECT ISNULL(
                    (SELECT TOP 1 idAgent 
                     FROM ccVirtualAgent 
                     WHERE idCampaign = @CampId 
                       AND mediaType = 10 AND campType = 1),
                    0
                ) AS idAgent;
        END
    END
END'
    exec (@sql)


    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminInbound]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT, 
                                    @InboundId AS SMALLINT = 0,
                                    @User_id AS SMALLINT = 0,
                                    @OutboundID AS SMALLINT = 0,
                                    @multi_cam as varchar(max) = null,
                                    @Module AS SMALLINT = 13,
                                    @Type AS SMALLINT = 0,
                                    @HistoryAction AS SMALLINT = 1,
                                    @AreaId AS SMALLINT = 0,
                                    @NonComprehensionId AS SMALLINT = -1,
                                    @SuccessfulTransactionCampaignId AS SMALLINT = -1,
                                    @CallBackCampaignId AS SMALLINT = -1,
                                    @IsEditing AS BIT = 0
AS
BEGIN
    set nocount on;

    DECLARE @idArea SMALLINT = NULL;
    DECLARE @operation INT = -1;
    DECLARE @mediaType INT = 0;

    IF(@Option IN (5, 6)) BEGIN
        IF(@Module IS NOT NULL AND @Module <> 13) BEGIN
        
            IF(@Type = 0)BEGIN
                
                IF(@multi_cam is not null) BEGIN
                    SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
                END ELSE BEGIN
                    SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id = @InboundId)
                END

                SET @operation = CASE WHEN @HistoryAction = 1 THEN 
                                                                    CASE 
                                                                            WHEN @mediaType = 1  THEN 63
                                                                            WHEN @mediaType = 5  THEN 40
                                                                            ELSE 60 END
                                                              ELSE 
                                                                    CASE 
                                                                            WHEN @mediaType = 1  THEN 64
                                                                            WHEN @mediaType = 5  THEN 53
                                                                            ELSE 52 END
                                                              END;
            END ELSE BEGIN

                SET @mediaType = (SELECT [CampType] FROM ccCamps WHERE cam_id = @OutboundID)

                SET @operation = CASE WHEN @HistoryAction = 1 THEN 
                                                                    CASE 
                                                                            WHEN @mediaType = 6  THEN 44
                                                                            WHEN @mediaType = 5  THEN 46
                                                                            WHEN @mediaType = 9  THEN 48
                                                                            WHEN @mediaType = 7  THEN 50
                                                                            ELSE 42 END
                                                               ELSE 
                                                                    CASE 
                                                                            WHEN @mediaType = 6  THEN 55
                                                                            WHEN @mediaType = 5  THEN 56
                                                                            WHEN @mediaType = 9  THEN 57
                                                                            WHEN @mediaType = 7  THEN 58
                                                                            ELSE 54 END
                                                                END;
            END

        END ELSE BEGIN
            SET @operation = CASE WHEN @Option = 5 THEN 93 ELSE 94 END;
        END
    END

    if(@Option = 1) -- To campaign 
    begin
        select 
            ISNULL(count (*), 0) as Calls,
            ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
            ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
            ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
            ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
            ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
            ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
            ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
            ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
            ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
            THEN 1 ELSE NULL END), 0) AS Other
        from ccCallsIn a (nolock)
        where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) and a.inbound_id = @InboundId

    end

    if(@Option = 2) -- All campaigns
    begin
        select 
            inbound.Inbound_id as IDEspec,
            inbound.descripcion as Name,
            ISNULL(count (*), 0) as Calls,
            ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
            ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
            ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
            ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
            ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
            ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
            ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
            ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
            ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
            THEN 1 ELSE NULL END), 0) AS Other
        from ccCallsIn a (nolock)
        left join ccInbound inbound on a.inbound_id = inbound.Inbound_id
        where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) 
        group by inbound.Inbound_id, inbound.descripcion
    end

    if(@Option = 3) -- Get All ACD call data, the data is showing in the administrator dashboard information
    begin
        SELECT 
            a.inbound_id, calls = ISNULL(COUNT(*), 0), -- calls
            Dialogs = ISNULL(COUNT (CASE WHEN statusCall_id = 13 THEN 1 ELSE NULL END), 0), -- Answered
            DlgsAveTime =CONVERT(int, ISNULL(SUM (CASE WHEN statusCall_id = 13 THEN cal_tDialog + cal_tNotas ELSE 0 END), 0)),
            QueueAveTime =ISNULL( avg( CASE WHEN cal_que > 0 THEN cal_tWait ELSE NULL END), 0) ,
            abandon = ISNULL(COUNT(CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0), -- Abandoned
            OverFlowQueue = ISNULL(COUNT (CASE WHEN statusCall_id =8 THEN 1 ELSE NULL END), 0),
            OverFlowTimeOut = ISNULL(COUNT (CASE WHEN statusCall_id =7 THEN 1 ELSE NULL END), 0), -- OverFlowQueue+OverFlowTimeOut = not answered
            outOfSchedule = ISNULL(COUNT (CASE WHEN statusCall_id =2 THEN 1 ELSE NULL END), 0), -- fuera de horario
            outOfService = ISNULL(COUNT (CASE WHEN statusCall_id =3 THEN 1 ELSE NULL END), 0), -- fuera de servicio
            noAgentsLoggedIn = ISNULL(COUNT (CASE WHEN statusCall_id =4 THEN 1 ELSE NULL END), 0), -- sin agentes firmados
            assigned = ISNULL(COUNT (CASE WHEN statusCall_id =11 THEN 1 ELSE NULL END), 0), -- asignada
            --assignedAndNotAnswered = ISNULL(COUNT (CASE WHEN statusCall_id =15 THEN 1 ELSE NULL END), 0), -- asignada y no contestada
            --assignedAndTookLine = ISNULL(COUNT (CASE WHEN statusCall_id =16 THEN 1 ELSE NULL END), 0), -- asignada y toma linea
            callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0)
            --onQueue = ISNULL(COUNT(CASE WHEN statusCall_id = 5 THEN 1 ELSE NULL END), 0)
            --initCalls = CAST(ISNULL(COUNT(CASE WHEN statusCall_id = 1 THEN 1 ELSE NULL END), 0) AS varchar(7))+''|''+
            --          ISNULL((SELECT STUFF((SELECT ''|'' + cast(ci.cal_id AS varchar(7))
            --          FROM ccCallsin ci (nolock) WHERE cal_inicio > dateadd(mi,-5,getdate()) AND ci.inbound_id=a.inbound_id
            --          FOR XML PATH('''')) ,1,1,'''')),''0'')
        FROM ccCallsIn a (nolock)
        WHERE cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))
                --and a.inbound_id in (select cam_id from ccSupervisorCam where user_id = @User_id and tipo = 0)
        GROUP BY a.inbound_id
    --  SET nocount off
    --  return(0)
    end

    if(@Option = 4) -- Load ACD of administrator that sent
    begin
        SELECT cam_id 
        FROM ccSupervisorCam  nolock
        WHERE user_id = @User_id and tipo = 0
        SET nocount off
        return(0)
    end

    IF(@Option = 5) -- Relate the inbound campaign with the outbound campaign
    BEGIN
        IF(@idArea IS NULL OR @idArea = -1) SET @idArea = 
            CASE WHEN @Type = 0 
                THEN 
                    CASE WHEN @multi_cam IS NULL
                        THEN (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @InboundID) 
                        ELSE (SELECT [IDArea] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
                        END
                ELSE (SELECT [IDArea] FROM ccCamps WHERE cam_id = @OutboundID)
                END

        IF(@multi_cam is not null)
        BEGIN
            UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id IN (
                SELECT value from dbo.fn_RIASplitDelimited(@multi_cam,'',''))

            IF (@multi_cam <> '''' )
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
            SELECT
                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
                getDate(), 
                (SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
                @operation,
                @Module,
                CASE WHEN @Module = 13 THEN '''' ELSE ''ASSOCIATED_CAMP_CALLBACK'' END,
                CASE WHEN @Type = 0 THEN
                                        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @OutboundID)
                                    ELSE 
                                        (SELECT [descripcion] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
                                    END,
                CASE WHEN @Type = 0 THEN
                                        (SELECT [descripcion] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
                                    ELSE 
                                        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @OutboundID)
                                    END

            SELECT 1;
            RETURN 1;
        END
        IF((SELECT ISNULL(cam_id,0) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId and chat in (0,11)) != 0 )
            BEGIN
                SELECT -1;
                RETURN -1;
            END;
        ELSE
            BEGIN
                UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id = @InboundID;
                    
                IF(@Type <> 1 AND @InboundID <> 0)
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                SELECT
                    (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
                    getDate(), 
                    (SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
                    @operation,
                    @Module,
                    CASE WHEN @Module = 13 THEN '''' ELSE ''ASSOCIATED_CAMP_CALLBACK'' END,
                    (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [cam_id] FROM ccInbound WHERE Inbound_id = @InboundID)),
                    (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @InboundID)

                SELECT 1;
                RETURN 1;
            END;
    END;        
    IF(@Option = 6) -- Delete the relation between inbound and outbound campaigns
    BEGIN

    IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @InboundID)
                    
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
            @operation,
            @Module,
            CASE WHEN @Module = 13 THEN '''' ELSE ''DISASSOCIATED_CAMP_CALLBACK'' END,
            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [cam_id] FROM ccInbound WHERE Inbound_id = @InboundID)),
            (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @InboundID)

        UPDATE ccInbound SET cam_id = null WHERE Inbound_id = @InboundId;
        SELECT 1;
        RETURN 1;
    END;
    IF(@Option = 7) -- Check if the inbound Campaign is related
    BEGIN
        SELECT CAST(CASE WHEN cam_id IS NULL OR cam_id = 0 THEN -1 ELSE cam_id END AS INT) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId;
    END
    IF(@Option = 8) -- Delete the relation between inbound campaings which are related to outdbound campaign
    BEGIN
        UPDATE ccInbound SET cam_id = null WHERE cam_id = @OutboundID;
        SELECT 1;
        RETURN 1;
    END
    IF(@Option = 9)
    BEGIN
        
        SET @Module = 3 --Corresponds to "Area", reference in ccGalateaModules
        SET @operation = CASE @IsEditing WHEN 1 THEN 138 ELSE 137 END -- Corresponds to edition and creation, reference ccGalateaOperations

        DECLARE @CurrentNonComprehensionId SMALLINT, 
                @CurrentCallbackId SMALLINT, 
                @CurrentSuccessfullTransactionId SMALLINT,
                @UserName VARCHAR(40),
                @AreaName VARCHAR(50),
                @CampaignName VARCHAR(40)

        SELECT @AreaName = AreaName  FROM ccRIACat_Areas WHERE IDArea = @AreaId
        SELECT @UserName = Login FROM ccUsers WHERE User_id = @User_id

        SELECT 
            @CurrentNonComprehensionId = ISNULL( idForNonComprehension , -1 ),
            @CurrentCallbackId = ISNULL( cam_id, -1 ),
            @CurrentSuccessfullTransactionId = ISNULL( idForSuccessfulTransaction, -1),
            @CampaignName = descripcion
        FROM ccInbound WHERE Inbound_id = @InboundId

        IF @CurrentCallbackId <> @CallBackCampaignId AND @CallBackCampaignId <> -1
        BEGIN
            UPDATE ccInbound
            SET cam_id = @CallBackCampaignId
            WHERE Inbound_id = @InboundId

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@AreaName, 
                    GETDATE(), 
                    @UserName, 
                    @operation, 
                    @Module, 
                    ''ASSOCIATED_CAMP_CALLBACK'', 
                    CASE @CallBackCampaignId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT cam_descripcion FROM ccCamps WHERE cam_id = @CallBackCampaignId) END,
                    @CampaignName)
        END

        IF @CurrentNonComprehensionId <> @NonComprehensionId AND @NonComprehensionId <> -1
        BEGIN
            UPDATE ccInbound
            SET idForNonComprehension = @NonComprehensionId
            WHERE Inbound_id = @InboundId

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@AreaName, 
                    GETDATE(), 
                    @UserName, 
                    @operation, 
                    @Module, 
                    ''ASSOCIATED_CAMP_XFER_IA'', 
                    CASE @NonComprehensionId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT descripcion FROM ccInbound WHERE Inbound_id = @NonComprehensionId) END,
                    @CampaignName)
        END

        IF @CurrentSuccessfullTransactionId <> @SuccessfulTransactionCampaignId AND @SuccessfulTransactionCampaignId <> -1
        BEGIN
            UPDATE ccInbound
            SET idForSuccessfulTransaction = @SuccessfulTransactionCampaignId
            WHERE Inbound_id = @InboundId

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@AreaName, 
                    GETDATE(), 
                    @UserName, 
                    @operation, 
                    @Module, 
                    ''ASSOCIATED_CAMP_SUCCESSFUL_TRANSACTION'', 
                    CASE @SuccessfulTransactionCampaignId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT descripcion FROM ccInbound WHERE Inbound_id = @SuccessfulTransactionCampaignId) END,
                    @CampaignName)
        END

        SELECT 1
    END
    IF(@Option = 10) -- Get Dispositions Not Assigned To Inbound IA  Campaign
    BEGIN
        SELECT CAST(calif_id AS INT) AS calif_id  
            FROM cctipoCalif_IA MAIN
            WHERE MAIN.Cali_StatusIA = 1
            AND EXISTS (
                SELECT 1 
                FROM ccInbound I
                WHERE I.Inbound_id = @InboundId
                AND (
                    ------------------------------------------------------------
                    -- GRUPO 1: Validación de Reprogramación / Callback
                    -- Si pide reprogramar, DEBE tener cam_id.
                    ------------------------------------------------------------
                    (
                       (MAIN.CanReprogram = 1 OR MAIN.autoCallback = 1) 
                       AND 
                       (I.cam_id IS NULL OR I.cam_id = 0)
                    )

                    OR 
                    ------------------------------------------------------------
                    -- GRUPO 2: Validación de Transferencia (AplTransfer)
                    -- Si pide transferir, DEBE tener los IDs configurados.
                    ------------------------------------------------------------
                    (
                        MAIN.AplTransfer = 1 
                        AND (
                            -- Si Opcion es 1, ERROR si falta idForNonComprehension
                            (MAIN.TransferOpcion = 1 
                            AND (I.idForNonComprehension IS NULL OR I.idForNonComprehension = 0))
        
                            OR
        
                            -- Si Opcion es 2, ERROR si falta idForSuccessfulTransaction
                            (MAIN.TransferOpcion = 2 AND 
                            (I.idForSuccessfulTransaction IS NULL OR I.idForSuccessfulTransaction = 0))
                        )
                    )
                )
            ) 
    END
END'
    exec (@sql)
    

    SET @process = 'CREATE TABLE cctipoCalif_IA'
    SET @sql = 'if not exists (select 1 from sys.tables where name=''cctipoCalif_IA'' )
begin
CREATE TABLE cctipoCalif_IA
    (
        calif_id smallint IDENTITY(1,1) NOT NULL,
        Name_cal varchar(150) NULL,
        Description_cal varchar(100) NULL,
        CanReprogram bit DEFAULT 0,
        autoCallback bit DEFAULT 0,
        ReturnCall smallint DEFAULT 0,
        Color varchar(15) NULL,
        AplTransfer bit DEFAULT 0,
        TransferOpcion smallint DEFAULT 0,
        DestinyIVR bit DEFAULT 0,
        DestinyIVR_camp smallint DEFAULT 0,
        DestinyIVR_number VARCHAR (20) NULL,
        DestinyIVR_directory smallint DEFAULT 0,
        AplExtDate bit DEFAULT 0,
        ExtDescription varchar(150) NULL,
        AplBlackList bit NULL,
        Cali_StatusIA bit NULL,
        DirectoryNumberFlag bit DEFAULT 1,
        CONSTRAINT cctipoCalifIA PRIMARY KEY CLUSTERED (calif_id)
    );
END'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
    @command int,
    @calif_id smallint = null,
    @califIdLst varchar(8000) = null,
    @description varchar(150)=null,
    @order tinyint=null,
    @canReprogram bit = null,
    @graphColor varchar(15) = null,
    @endConversation bit=null,
    @keepDial bit=null,
    @autoCB bit=null,
    @contactOwner bit=null,
    @finishPreview bit = 0,
    @allNumbersToBlacklist bit = 0,
    @FinishRecordPreview bit = 0,
    @Name_cal varchar(150) = null,
    @Description_cal varchar(100) = null,
    @ReturnCall smallint = null,
    @AplTransfer bit = 0,
    @TransferOpcion smallint = 0,
    @DestinyIVR bit = 0,
    @DestinyIVR_camp smallint = null,
    @DestinyIVR_number varchar(20) = null,
    @DestinyIVR_directory smallint = null,
    @AplExtDate bit = 0,
    @ExtDescription varchar(100) = null,
    @AplBlackList bit = 0,
    @Cali_StatusIA bit = 1,  
    @DirectoryNumberFlag bit = 1,
    @user_id INT = NULL,
    @type TINYINT = NULL,
    @acdId SMALLINT = NULL,
    @directoryId SMALLINT = NULL


    AS
    set nocount on
    declare @inserted table (ID smallint)

    if @command=1 -- Load Inbound Dispositions
    begin
      Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner, 
      cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd, graphColor
      from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
      where C.Calif_Status=1
      group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation, graphColor
      order by 2
      return(0)
    end

    If @command=2 -- Load Outbound Dispositions
    begin
      Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,  
      cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner, 
      IsNull(C.finishPreview,0) as finishPreview, graphColor, allNumbersToBlacklist, ISNULL(C.FinishRecordPreview,0) as FinishRecordPreview
      from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
      where C.CalifOut_Status=1
      group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
      C.contactOwner, C.finishPreview, graphColor, allNumbersToBlacklist, C.FinishRecordPreview
      order by 2
      return(0)
    end

    If @command=3 -- New ccTipoCalif
    begin
      If exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@description)
        begin
          select cast(-1 as smallint) [result]  -- Disposition already exists
          return(0)
        end

      If exists(select calif_id from ccTipoCalif where Calif_Status=0 and description=@description)
      begin
        select top 1 @calif_id = calif_id from ccTipoCalif where Calif_Status=0 and description=@description order by calif_id desc
        update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0), 
        graphColor=isnull(@graphColor, ''1DB4E2''), Calif_Status=1
        output inserted.calif_id into @inserted
        where calif_id=@calif_id
        select ID [result] from @inserted 
        return(0)
      end

      insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , graphColor)
      output inserted.calif_id into @inserted
      select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalif
      select ID [result] from @inserted
      return(0)
    end

    If @command=4 -- New ccTipoCalifOUT
    begin
      If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
      begin
      select cast(-1 as smallint) [result]  -- Disposition already exists
      return(0)
      end

     If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
     begin
        select top 1 @calif_id = calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description order by calif_id desc
        update ccTipoCalifOut set autoTime=0, orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), idTipoLista=0,
        Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), 
        finishPreview=isnull(@finishPreview,0), graphColor=isnull(@graphColor, ''1DB4E2''), FinishRecordPreview = isnull(@FinishRecordPreview,0)
        output inserted.calif_id into @inserted
        where calif_id=@calif_id
        select ID [result] from @inserted 
        return(0)
     end

     insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, graphColor, allNumbersToBlacklist,FinishRecordPreview)
     output inserted.calif_id into @inserted
     select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, isnull(@canReprogram,0), isnull(@keepDial,0), 
     isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, ''1DB4E2''), ISNULL(@allNumbersToBlacklist,0), FinishRecordPreview = isnull(@FinishRecordPreview,0) from ccTipoCalifOut
     select ID [result] from @inserted 
     return(0)
    end
    If @command=5 -- Delete Inbound Dispositions
    begin
        delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
        delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
        update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
        return(0)
    end
   if @command=6 -- Delete Outbound Disposition
begin
declare @cams table (cam_id int)

insert into @cams
select distinct cam_id
from ccCalifCamp
where tipo = 1
and calif_id in (
    select value from dbo.fn_RIASplitDelimited(@califIdLst, '','')
)

-- deletes
delete from ccCalifCamp 
where tipo=1 
and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))

delete from cctipoSubCalifRel 
where tipoSubRel=0 
and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))

update ccTipoCalifOUT 
set CalifOut_Status=0 
where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))

update ccCamps 
set keepDial = dbo.fn_keepDial_Camps(cam_id)
where cam_id in (select cam_id from @cams)

select 200 as ResponseCode, ''SUCCESS'' as ResponseCodeDescription

end
    if @command=7 -- Update Inbound Disposition
    begin
        if(exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@Description and calif_id<>@calif_id))
        begin
            select cast(-1 as smallint) [result]    -- Disposition already exists
            return(0)
        end

        UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
        canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  
        EndConversation=isnull(@endConversation,EndConversation)
        output inserted.calif_id into @inserted
        where calif_id=@calif_id

        delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
        tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

        select ID [result] from @inserted
        return(0)
    end
    if @command=8 -- Update Outbound Disposition
    begin
        if(exists(select calif_id from ccTipoCalifOUT where CalifOut_Status=1 and Description=@description and calif_id<>@calif_id))
        begin
            select cast(-1 as smallint) [result]    -- Disposition already exists
            return(0)
        end

        UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
        canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  keepDial=isnull(@keepDial,keepDial), 
        autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner), 
        finishPreview = isnull(@finishPreview,finishPreview), allNumbersToBlacklist = isnull(@allNumbersToBlacklist, allNumbersToBlacklist),  FinishRecordPreview = isnull(@FinishRecordPreview,FinishRecordPreview)
        output inserted.calif_id into @inserted
        where calif_id=@calif_id

        if @keepDial is not null
        begin
            update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
        end

        select ID [result] from @inserted
        return(0) 
        end


    if @command=9 
    begin
        Select 
            C.calif_id, 
            C.Name_cal as Description, 
            C.Description_cal, 
            C.CanReprogram, 
            C.autoCallback as autocallback, 
            C.ReturnCall,
            C.AplTransfer, 
            C.TransferOpcion, 
            C.DestinyIVR, 
            C.DestinyIVR_camp, 
            C.DestinyIVR_number, 
            C.DestinyIVR_directory,
            C.AplExtDate, 
            C.ExtDescription, 
            C.AplBlackList,
            C.Cali_StatusIA as CaliStatusIA,
            C.Color as graphColor,
            C.DirectoryNumberFlag
        from cctipoCalif_IA C 
        where C.Cali_StatusIA = 1
        order by C.Name_cal
        return(0)
    end

   If @command = 10 -- New ccTipoCalif_IA
            begin
                if @DestinyIVR_number IS NOT NULL AND @DestinyIVR_number <> ''''
                    set @DirectoryNumberFlag = 0
                else if @DestinyIVR_directory IS NOT NULL AND @DestinyIVR_directory <> 0
                    set @DirectoryNumberFlag = 1

                if exists (select 1 from cctipoCalif_IA where Cali_StatusIA = 1 and Name_cal = @Name_cal)
                begin
                    select cast(-1 as smallint) as [result]  
                    return(0)
                end

                if exists (select 1 from cctipoCalif_IA where Cali_StatusIA = 0 and Name_cal = @Name_cal)
                begin
                    select top 1 @calif_id = calif_id 
                    from cctipoCalif_IA 
                    where Cali_StatusIA = 0 and Name_cal = @Name_cal 
                    order by calif_id desc

                    update cctipoCalif_IA
                    set 
                        Name_cal              = @Name_cal,
                        Description_cal       = @Description_cal,
                        CanReprogram          = isnull(@canReprogram, 0),
                        autoCallback          = isnull(@autoCB, 0),
                        ReturnCall            = @ReturnCall,
                        Color                 = isnull(@graphColor, ''1DB4E2''),
                        AplTransfer           = isnull(@AplTransfer, 0),
                        TransferOpcion        = isnull(@TransferOpcion, 0),
                        DestinyIVR            = isnull(@DestinyIVR, 0),
                        DestinyIVR_camp       = @DestinyIVR_camp,
                        DestinyIVR_number     = @DestinyIVR_number,
                        DestinyIVR_directory  = @DestinyIVR_directory,
                        AplExtDate            = isnull(@AplExtDate, 0),
                        ExtDescription        = @ExtDescription,
                        AplBlackList          = isnull(@AplBlackList, 0),
                        Cali_StatusIA         = 1,
                        DirectoryNumberFlag   = isnull(@DirectoryNumberFlag, 1)
                    output inserted.calif_id into @inserted
                    where calif_id = @calif_id

                    select ID [result] from @inserted
                    return(0)
                end

                insert into cctipoCalif_IA (
                    Name_cal,
                    Description_cal,
                    CanReprogram,
                    autoCallback,
                    ReturnCall,
                    Color,
                    AplTransfer,
                    TransferOpcion,
                    DestinyIVR,
                    DestinyIVR_camp,
                    DestinyIVR_number,
                    DestinyIVR_directory,
                    AplExtDate,
                    ExtDescription,
                    AplBlackList,
                    Cali_StatusIA,
                    DirectoryNumberFlag
                )
                output inserted.calif_id into @inserted
                values (
                    @Name_cal,
                    @Description_cal,
                    isnull(@canReprogram, 0),
                    isnull(@autoCB, 0),
                    @ReturnCall,
                    isnull(@graphColor, ''1DB4E2''),
                    isnull(@AplTransfer, 0),
                    isnull(@TransferOpcion, 0),
                    isnull(@DestinyIVR, 0),
                    @DestinyIVR_camp,
                    @DestinyIVR_number,
                    @DestinyIVR_directory,
                    isnull(@AplExtDate, 0),
                    @ExtDescription,
                    isnull(@AplBlackList, 0),
                    1,
                    isnull(@DirectoryNumberFlag, 1)
                )

                select ID [result] from @inserted
                return(0)
            end

        -- Comando 11: DELETE_IA_BOUND_DISPOSITION
        if @command=11 -- Delete IA Bound Disposition
        begin
            delete from ccCalifCamp where tipo=2 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
            delete from cctipoSubCalifRel where tipoSubRel=2 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
            update ccTipoCalif_IA set Cali_StatusIA=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
            -- Agregar aquí cualquier limpieza adicional específica para IA si es necesario
            return(0)
        end

        if @command=12 -- Update IA Bound Disposition
            begin
                if(exists(select calif_id from ccTipoCalif_IA where Cali_StatusIA=1 and Name_cal=@Name_cal and calif_id<>@calif_id))
                begin
                    select cast(-1 as smallint) [result]    -- Disposition already exists
                    return(0)
                end

                if @DestinyIVR_number IS NOT NULL AND @DestinyIVR_number <> ''''
                    set @DirectoryNumberFlag = 0
                else if @DestinyIVR_directory IS NOT NULL AND @DestinyIVR_directory <> 0
                    set @DirectoryNumberFlag = 1

                UPDATE ccTipoCalif_IA set Name_cal=isnull(@Name_cal, Name_cal), Description_cal=isnull(@Description_cal, Description_cal),
                CanReprogram=isnull(@canReprogram, CanReprogram), Color=isnull(@graphColor, Color), autoCallback=isnull(@autoCB, autoCallback),
                ReturnCall=isnull(@ReturnCall, ReturnCall), AplTransfer=@AplTransfer, TransferOpcion=@TransferOpcion,
                DestinyIVR=@DestinyIVR, DestinyIVR_camp=@DestinyIVR_camp,
                DestinyIVR_number=@DestinyIVR_number, DestinyIVR_directory=@DestinyIVR_directory,
                AplExtDate=@AplExtDate, ExtDescription=@ExtDescription, DirectoryNumberFlag=isnull(@DirectoryNumberFlag, DirectoryNumberFlag),
                AplBlackList=@AplBlackList, Cali_StatusIA=isnull(@Cali_StatusIA, Cali_StatusIA)
                output inserted.calif_id into @inserted
                where calif_id=@calif_id

                select ID [result] from @inserted
                return(0)
            end

IF @command = 13  -- DELETE IA
BEGIN  
BEGIN TRY  

    -- 0. Validación inicial
    IF @califIdLst IS NULL OR LTRIM(RTRIM(@califIdLst)) = ''''
    BEGIN
        SELECT -10 AS ResponseCode,
               ''califIdLst is empty'' AS ResponseCodeDescription,
               '''' AS CalifIdLst
        RETURN
    END

    DECLARE @Ids TABLE (calif_id INT)  
    DECLARE @Active TABLE (calif_id INT)  
    DECLARE @ToDelete TABLE (calif_id INT)  

    -- 1. Parseo de IDs
    INSERT INTO @Ids  
    SELECT TRY_CAST(value AS INT)  
    FROM dbo.fn_RIASplitDelimited(@califIdLst, '','')  
    WHERE TRY_CAST(value AS INT) IS NOT NULL

    IF NOT EXISTS (SELECT 1 FROM @Ids)
    BEGIN
        SELECT -11 AS ResponseCode,
               ''No valid IDs received'' AS ResponseCodeDescription,
               '''' AS CalifIdLst
        RETURN
    END

    -- 2. Detectar activos (solo campañas ACTIVAS)
    INSERT INTO @Active  
    SELECT DISTINCT c.calif_id  
    FROM ccCalifCampIA c  
    INNER JOIN @Ids i ON i.calif_id = c.calif_id  
    WHERE 
    (
        c.tipo = 1 AND EXISTS (
            SELECT 1 
            FROM ccCamps o
            WHERE o.cam_id = c.cam_id 
              AND o.cam_procesando = 1
        )
    )
    OR
    (
        c.tipo = 0 AND EXISTS (
            SELECT 1 
            FROM ccInbound ib
            WHERE ib.Inbound_id = c.cam_id 
              AND ib.Status = 1
        )
    )

    -- 3. Determinar eliminables
    INSERT INTO @ToDelete  
    SELECT i.calif_id 
    FROM @Ids i
    LEFT JOIN @Active a ON i.calif_id = a.calif_id
    WHERE a.calif_id IS NULL

    -- 4. Si TODOS están activos → NO borrar nada
    IF NOT EXISTS (SELECT 1 FROM @ToDelete)
    BEGIN  
        SELECT 
            -27 AS ResponseCode,  
            ''All dispositions are active in campaigns.'' AS ResponseCodeDescription,
            '''' AS CalifIdLst
        RETURN  
    END  

    -- 5. ELIMINACIÓN REAL
    UPDATE cctipoCalif_IA  
    SET Cali_StatusIA = 0  
    WHERE calif_id IN (SELECT calif_id FROM @ToDelete)  

    DELETE FROM ccCalifCampIA  
    WHERE calif_id IN (SELECT calif_id FROM @ToDelete)  

    -- 6. LOG
    IF EXISTS (SELECT 1 FROM @ToDelete)
    BEGIN
                    INSERT INTO ccGalateaActivityLog
(Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
SELECT   
ISNULL((
    SELECT TOP 1 AreaName FROM ccRIACat_Areas
), ''Default''),

GETDATE(),  
(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),  
177,  
7,  

'''',             

c.Name_cal,  

''IA Disposition Delete''  
FROM cctipoCalif_IA c  
WHERE calif_id IN (SELECT calif_id FROM @ToDelete)
    END

    -- 7. RESPUESTA

    -- Parcial
    IF EXISTS (SELECT 1 FROM @Active)
    BEGIN  
        --SELECT 
        --    -28 AS ResponseCode,  
        --    ''Partial Success. Some dispositions are active.'' AS ResponseCodeDescription,
        --    STRING_AGG(CAST(calif_id AS VARCHAR), '','') AS CalifIdLst
        --FROM @ToDelete
        SELECT 
        -28 AS ResponseCode,  
        ''Partial Success. Some dispositions are active.'' AS ResponseCodeDescription,
        STUFF((
            SELECT '','' + CAST(td.calif_id AS VARCHAR(20))
            FROM @ToDelete td
            FOR XML PATH(''''), TYPE
        ).value(''.'', ''VARCHAR(MAX)''), 1, 1, '''') AS CalifIdLst
        RETURN  
    END  

    -- Éxito total
    --SELECT 
    --    200 AS ResponseCode,  
    --    ''SUCCESS'' AS ResponseCodeDescription,
    --    STRING_AGG(CAST(calif_id AS VARCHAR), '','') AS CalifIdLst
    --FROM @ToDelete
    SELECT 
    200 AS ResponseCode,  
    ''SUCCESS'' AS ResponseCodeDescription,
    STUFF((
        SELECT '','' + CAST(td.calif_id AS VARCHAR(20))
        FROM @ToDelete td
        FOR XML PATH(''''), TYPE
    ).value(''.'', ''VARCHAR(MAX)''), 1, 1, '''') AS CalifIdLst

END TRY  
BEGIN CATCH  
    SELECT 
        -1 AS ResponseCode,  
        ERROR_MESSAGE() AS ResponseCodeDescription,
        '''' AS CalifIdLst
END CATCH  
END

IF @command = 14 
BEGIN 
SELECT Name_cal AS [Name],
   Description_cal AS [Description],
   CanReprogram AS Reprogram,
   autoCallback AS Callback,
   Color AS Color,
   ISNULL(AplTransfer, 0) AS [Transfer],
   ISNULL(TransferOpcion, 0) AS TransferOption,
   ISNULL(DestinyIVR, 0) AS DestinyDropDown,
   DestinyIVR_camp AS DestinyCamp,
   ISNULL(DirectoryNumberFlag, 0) AS NumberDropDown,
   DestinyIVR_number AS DestinyNumber,
   DestinyIVR_directory AS DestinyDirectory,
   ISNULL(AplExtDate, 0) AS Extraction,
   ExtDescription AS ExtractionDescription,
   ISNULL(AplBlackList, 0) AS DNC
FROM cctipoCalif_IA 
WHERE calif_id = @calif_id
END
--select * from cctipoCalif_IA


IF @command = 15 
BEGIN 
select descripcion from ccinbound where inbound_id = @acdId
END

IF @command = 16
BEGIN 
SELECT tel FROM dbo.telefonosTransferencia where numtra_id = @directoryId 
END

SET NOCOUNT OFF'
    exec (@sql)
    

    SET @process = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetCampaignsIAController]'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetCampaignsIAController]
    @Option INT,      
    @AdminID INT      
AS
BEGIN
    SET NOCOUNT ON;

    IF @Option = 1
    BEGIN
        SELECT
            cast(i.Inbound_id as int) AS inbound_id,
            i.descripcion AS description,
            cast(i.chat as smallint) as chat
        FROM
            ccRIAWorkGroupUsers wgu
            INNER JOIN ccRIACampEspWG cwg ON wgu.IDWG = cwg.IDWG
            INNER JOIN ccInbound i ON cwg.IdCampEsp = i.Inbound_id
        WHERE
            wgu.user_id = @AdminID
            AND cwg.Tipo = 0               
        ORDER BY
            i.Inbound_id;                
    END
    
END
'
    exec (@sql)
    SET @process = 'ALTER TABLE dbo.ccVirtualAgent'
    SET @sql = 'ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN ReplyGreeting NVARCHAR(1000);
ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN ReplyFarewell NVARCHAR(1000);
ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN ReplySystemFailure NVARCHAR(1000);
ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN ReplyNoUnderstanding NVARCHAR(1000);

ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN rules VARCHAR(6000);
ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN instructions VARCHAR(MAX);'
    exec (@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_AIToHumanTransfer]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AIToHumanTransfer]
    @action int = null,
    @camId int = null,
    @CallOutId int = null,
    @acdId int = null

AS
BEGIN 
    if @action = 1
    Begin
        select Inbound_id AS ACDToTranfer, CAST(0 AS BIT) AS TransferMode , 0 AS TransferTo, '''' AS TransferToExternalNumber, '''' AS TransferToExternalDirectoryNumber   from ccInbound where cam_id = @camId
    end

    if @action = 2
    Begin
        select data_overflow_variables_quantum from ccoCallsOutSource where callout_id = @CallOutId
    end

    if @action = 3
    Begin
        select cci.idForNonComprehension AS ACDToTranfer, ISNULL(TransferOnFallback_Mode,1) AS TransferMode , ISNULL(TransferToHumanAgents,0) AS TransferTo, 
        ISNULL(cie.TransferOnFallback_ExternalNumber,'''') AS TransferToExternalNumber,
        ISNULL(tt.tel,'''') AS TransferToExternalDirectoryNumber  FROM ccInbound  AS  cci
        INNER JOIN  dbo.ccInboundExtend AS cie
        ON cie.Inbound_id = cci.Inbound_id
        LEFT JOIN dbo.telefonosTransferencia AS tt
        ON tt.numtra_id = cie.TransferOnFallback_DirectoryId
        WHERE cci.Inbound_id = @acdId
    end

    if @action = 4
    Begin
        select cci.idForSuccessfulTransaction AS ACDToTranfer, ISNULL(TransferOnSuccess_Mode,1) AS TransferMode , ISNULL(TransferOnSuccessfulHandling,0) AS TransferTo,
        ISNULL(cie.TransferOnSuccess_ExternalNumber,'''') AS TransferToExternalNumber,
        ISNULL(tt.tel,'''') AS TransferToExternalDirectoryNumber
        FROM ccInbound  AS  cci
        INNER JOIN  dbo.ccInboundExtend AS cie
        ON cie.Inbound_id = cci.Inbound_id
        LEFT JOIN dbo.telefonosTransferencia AS tt
        ON tt.numtra_id = cie.TransferOnSuccess_DirectoryId
        WHERE cci.Inbound_id = @acdId
    end
END'
    exec (@sql)


    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_VirtualAgents]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_VirtualAgents]
    @action INT = 0,

    @idVirtualAgent INT = 0,
    --Creation
    @nameAgent NVARCHAR(255) = NULL,
    @responseTone TINYINT = 0,
    @languageAgent TINYINT = 0,
    @quantumRoleId INT = 0,
    @roleDescription NVARCHAR(30) = '''',
    @responseLength TINYINT = 0,
    @numberOfAgents INT = 0,
    @quantumAgentId NVARCHAR(50) = '''',
    @replyGreeting NVARCHAR(1000) = '''',
    @replyFarewell NVARCHAR(1000) = '''',
    @replySystemFailure NVARCHAR(1000) = '''',
    @replyNoUnderstanding NVARCHAR(1000) = '''',
    @statusAgent BIT = NULL,
    @campaignId INT = NULL,
    @mediaType INT = NULL, -- CALLS, WHATSAPP, SMS
    @campType INT = NULL, -- 0 IN - 1 OUT
    @voiceID INT= 0,
    @adminId INT = 0,
    @originalAgentId INT = 0,

    --Definition
    @objective VARCHAR(1200) = NULL,
    @rules VARCHAR(6000) = NULL,
    @instructions VARCHAR(MAX) = NULL,
    @variables VARCHAR(500) = NULL,

    -- Masivo
    @virtualAgentIds VARCHAR(600) = NULL
    AS
    BEGIN
        DECLARE @idArea SMALLINT, @userName varchar(40)

        IF @action = 1
        BEGIN
            SELECT
                va.idAgent AS idAgent,
                va.NameAgent AS nombre,
                ISNULL(CAST(va.idCampaign AS INT),0) AS idCampaign,
                ISNULL(va.concurrentSessionsLimit, 0) AS concurrentSessionsLimit,
                CAST(va.StatusAgent AS BIT) AS status,
                CAST(va.mediaType AS INT) as SubType,
                ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN ci.descripcion 
                        ELSE co.cam_descripcion
                    END, ''N/A''
                ) AS campName,
                ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN ci.IDArea -- Campaña de entrada
                        ELSE co.IDArea -- Campaña de salida
                    END,
                0) AS IDArea,
                CAST(ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN ig.graphic_id -- Icono para entrada
                        ELSE og.graphic_id -- Icono para salida
                    END, 0
                ) AS int) AS campaignGraph,
                CAST(va.CampType AS int) CampType,
                ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN CAST(ci.Status AS BIT) -- Estado de la campaña de entrada
                        ELSE CAST(co.cam_procesando AS BIT) -- Estado de la campaña de salida
                    END, 0
                ) AS IsActiveCampaign, -- Devuelve 1 o 0
                ISNULL(
                    CASE 
                        WHEN (va.CampType = 0 AND ci.chat = 5) THEN wn.Number
                        WHEN (va.CampType = 1 AND co.CampType = 5) THEN wno.Number
                        ELSE ''N/A''
                    END, ''N/A''
                ) AS NumeroAsociado,
                CONVERT(VARCHAR(10), va.createDateAgent, 120) AS FechaCreacion, -- Devuelve como ''YYYY-MM-DD''
                ISNULL(
                    CASE 
                        WHEN va.latestUpdateDateAgent IS NULL OR va.latestUpdateDateAgent = '''' THEN ''N/A''
                        ELSE CONVERT(VARCHAR(10), va.latestUpdateDateAgent, 120) -- Devuelve como ''YYYY-MM-DD''
                    END, ''N/A''
                ) AS FechaUltimaModificacion, -- Devuelve ''YYYY-MM-DD'' o ''N/A''
                ISNULL(va.voice,1) as Voice,
                va.scriptAgent as ScriptAgent,
                CAST(CASE
                    WHEN va.instructions IS NULL OR va.instructions = '''' THEN 0
                    ELSE 1
                    END AS bit) AS HasInstructions, 
                ISNULL(va.ReplyGreeting, '''') AS ReplyGreeting,
                ISNULL(va.ReplyFarewell, '''') AS ReplyFarewell,
                ISNULL(va.ReplySystemFailure, '''') AS ReplySystemFailure,
                ISNULL(va.ReplyNoUnderstanding, '''') AS ReplyNoUnderstanding,
                ISNULL(va.quantumRoleId, 0) AS QuantumRolId,
                ISNULL(va.responseLength, 0) AS ResponseLength,
                ISNULL(va.responseTone, 0) AS ResponseTone,
                ISNULL(va.roleName, '''') AS RolName,
                ISNULL(va.Language, 0) as Language,
                ISNULL(CopiesCount, 0) As CopiesCount,
                ISNULL(OriginalAgentId, 0) As OriginalAgentId
            FROM dbo.ccVirtualAgent va
            LEFT JOIN dbo.ccInbound ci ON ci.Inbound_id = va.idCampaign AND va.campType = 0
            LEFT JOIN dbo.ccCamps co ON co.cam_id = va.idCampaign AND va.campType = 1
            LEFT JOIN dbo.ccMetaWhatsAppNumbers wn ON wn.Inbound_Id = va.idCampaign AND va.campType = 0 AND mediaType != 0
            LEFT JOIN dbo.ccMetaWhatsAppNumbers wno ON wno.Cam_Id = va.idCampaign AND va.campType = 1 AND mediaType != 0
            LEFT JOIN dbo.ccRIAInboundGraph ig ON ig.Inbound_id = va.idCampaign AND va.campType = 0
            LEFT JOIN dbo.ccRIACampsGraph og ON og.cam_id = va.idCampaign AND va.campType = 1
            WHERE va.wasDeleted = 0
        END

        ELSE IF @action = 2
        BEGIN
            -- We validate the capacity defined in the setting 281 with the received value. 
            DECLARE @TotalOfConcurrentAgents INT, 
                    @UsedConcurrentAgents INT

            IF EXISTS(SELECT 1 FROM ccVirtualAgent WHERE nameAgent = @nameAgent and wasDeleted = 0)
            BEGIN
                SELECT ''A virtual agent with the same name already exists'' as Result, 1 as ErrorCode
                RETURN
            END

            SELECT @TotalOfConcurrentAgents = CAST(valor AS int) FROM ccSettings2 WHERE setting_id = 281
            SELECT @UsedConcurrentAgents = ISNULL(SUM(concurrentSessionsLimit), 0) FROM ccVirtualAgent WHERE wasDeleted = 0

            IF((@UsedConcurrentAgents + @numberOfAgents) <= @TotalOfConcurrentAgents)
            BEGIN
                -- Creación de un nuevo agente virtual
                DECLARE @newModelId int;

                INSERT INTO dbo.ccVirtualAgent (
                    nameAgent, 
                    statusAgent, 
                    createDateAgent, 
                    latestUpdateDateAgent,
                    concurrentSessionsLimit,
                    responseTone,
                    language,
                    quantumAgentId,
                    quantumRoleId,
                    roleName,
                    responseLength,
                    ReplyGreeting,
                    ReplyFarewell,
                    ReplySystemFailure,
                    ReplyNoUnderstanding,
                    voice
                )
                VALUES (
                    @nameAgent, 
                    0, 
                    GETDATE(),
                    GETDATE(),
                    @numberOfAgents,
                    @responseTone,
                    @languageAgent,
                    @quantumAgentId,
                    @quantumRoleId,
                    @roleDescription,
                    @responseLength,
                    @replyGreeting,
                    @replyFarewell,
                    @replySystemFailure,
                    @replyNoUnderstanding,
                    @voiceID
                );

                SET @newModelId = SCOPE_IDENTITY();

                -- Activity History 
            
                SELECT @idArea = IDArea, @userName = Login FROM ccUsers where User_id = @adminId

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                    SELECT
                        (SELECT ISNULL(AreaName, '''') FROM ccRIACat_Areas WHERE IDArea = @idArea),
                        getDate(), 
                        @userName, 
                        169,
                        24,
                        '''',
                        '''',
                        @nameAgent

                IF @campaignId = 0
                BEGIN
                    SELECT ''Agent created correctly'' AS Result, 0 AS ErrorCode, @newModelId as IdAgent;
                    RETURN
                END

                -- Invoke campaign association and return association results
    
                CREATE TABLE #associationResult (Result varchar(100), ErrorCode int, idAgent int, nameAgent varchar(255), idCampaign int, campaignName varchar(40))

                INSERT INTO #associationResult(Result, ErrorCode,idAgent,nameAgent,idCampaign,campaignName)
                EXEC dbo.ccsp_VirtualAgents
                        @action=4,@adminId=@adminId, @campType=@campType, @campaignId=@campaignId, @mediaType=@mediaType, @idVirtualAgent=@newModelId;

                SELECT Result, ErrorCode, idAgent as IdAgent FROM #associationResult
                RETURN
            END
            ELSE
            BEGIN
                SELECT ''There are not contracted agents available'' AS Result, 2 AS ErrorCode; 
            END
        END

        ELSE IF @action = 3 -- Elimination of virtual Agent
        BEGIN
            CREATE TABLE #deletedVirtualAgents(idAgent int, agentName varchar(255), quantumAgentId VARCHAR(50))

            UPDATE dbo.ccVirtualAgent
            SET
                idCampaign = 0,
                mediaType = 0,
                concurrentSessionsLimit = 0,
                campType = 0,
                wasDeleted = 1
            OUTPUT deleted.idAgent, deleted.nameAgent, deleted.quantumAgentId INTO #deletedVirtualAgents
            WHERE idAgent IN(SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,'','')) AND statusAgent = 0;

            SELECT * FROM #deletedVirtualAgents
        END

        ELSE IF @action = 4 -- Change of associated campaign. Brings the info for Activity history
        BEGIN
            DECLARE @PreviousAgentData AS TABLE(
                idAgent INT,
                nameAgent VARCHAR(255),
                idCampaign SMALLINT,
                camptype TINYINT
            );

            IF(@campaignId <> 0)
            BEGIN
                -- *** VALIDATIONS FOR CAMPAIGN ASSIGNATION ***
                -- Campaign was deleted
                DECLARE @campaignArea AS SMALLINT

                IF @campType = 0
                BEGIN
                    SELECT @campaignArea =
                        CASE
                            WHEN EXISTS (SELECT 1 FROM ccInbound_Consulta WHERE Inbound_id = @campaignId)
                                THEN 1
                            ELSE 0
                        END;
                END
                ELSE IF @campType = 1
                BEGIN
                    SELECT @campaignArea =
                        CASE
                            WHEN EXISTS (SELECT 1 FROM ccCamps_Consulta WHERE cam_id = @campaignId)
                                THEN 1
                            ELSE 0
                        END;
                END

                IF @campaignArea <> 0
                BEGIN
                    SELECT ''Campaign was deleted'' AS Result, 3 AS ErrorCode , 0 AS idAgent, '''' as nameAgent, 0 AS idCampaign, '''' AS nameCampaign
                    RETURN
                END

                    --- Campaign was assigned to another model
                IF EXISTS (SELECT 1 FROM ccVirtualAgent WHERE idAgent != @idVirtualAgent AND idCampaign = @campaignId AND mediaType = @mediaType AND campType = @campType)
                BEGIN
                    SELECT ''Campaign has already been assigned'' as Result, 4 AS ErrorCode , 0 AS idAgent, '''' as nameAgent, 0 AS idCampaign, '''' AS nameCampaign;
                    RETURN
                END

                --- Campaign doesn''t belong to the same wg than te user
                DECLARE @CampaignIsNotInUserWorkgroup  BIT = 0;

                IF NOT EXISTS (SELECT * FROM ccUsers_Roles NOLOCK WHERE User_id = @AdminId AND Rol_id = 7) -- It''s not a superUser
                BEGIN
                    SELECT @CampaignIsNotInUserWorkgroup =
                        CASE WHEN NOT EXISTS (
                            SELECT 1
                            FROM dbo.ccRIAWorkGroupUsers AS userWG
                                JOIN dbo.ccRIACampEspWG AS campaignWg ON campaignWg.IDWG = userWG.IDWG
                            WHERE userWG.User_id    = @adminId
                                AND campaignWg.Tipo       = @campType 
                                AND campaignWg.IdCampEsp  = @campaignId
                            )
                            THEN 1 ELSE 0 END;

                    IF @CampaignIsNotInUserWorkgroup = 1
                    BEGIN
                        SELECT ''Campaign doesn''''t belong to admin workgroups'' as Result, 5 AS ErrorCode , 0 AS idAgent, '''' as nameAgent, 0 AS idCampaign, '''' AS nameCampaign;
                        RETURN
                    END
                END
            END

            UPDATE ccVirtualAgent SET idCampaign = @campaignId,
                                        mediaType = @mediaType,
                                        camptype = @campType,
                                        latestUpdateDateAgent = GETDATE()
                                        OUTPUT deleted.idAgent, deleted.nameAgent, deleted.idCampaign, deleted.campType INTO @PreviousAgentData
                                        WHERE idAgent = @idVirtualAgent
            IF @campaignId <> 0
                BEGIN
                    SELECT
                        ''Campaign changed'' AS Result,
                        0 AS ErrorCode,
                        va.idAgent,
                        va.nameAgent,
                        CAST(va.idCampaign as int) idCampaign,
                        CASE 
                            WHEN @campType = 0 THEN i.descripcion
                            ELSE cout.cam_descripcion 
                        END AS campaignName
                    FROM ccVirtualAgent va
                        LEFT JOIN ccInbound i ON va.idCampaign = i.Inbound_id AND @campType = 0
                        LEFT JOIN ccCamps cout ON va.idCampaign = cout.cam_id AND @campType = 1
                    WHERE va.idAgent = @idVirtualAgent;
                END
            ELSE
                BEGIN
                    SELECT
                        ''Campaign retired'' AS Result,
                        0 AS ErrorCode,
                        pvd.idAgent,
                        pvd.nameAgent,
                        CAST(0 as int) idCampaign,
                        CASE 
                            WHEN pvd.camptype = 0 THEN i.descripcion
                            ELSE cout.cam_descripcion 
                        END AS campaignName
                    FROM @PreviousAgentData pvd
                        LEFT JOIN ccInbound i ON pvd.idCampaign = i.Inbound_id AND pvd.camptype = 0
                        LEFT JOIN ccCamps cout ON pvd.idCampaign = cout.cam_id AND pvd.camptype = 1
                END

        END

        ELSE IF @action = 5 -- Status change
        BEGIN
            CREATE TABLE #updatedVirtualAgents(idAgent int, nameAgent varchar(255), newStatus BIT)

            UPDATE ccVirtualAgent SET statusAgent = @statusAgent
            OUTPUT inserted.idAgent, inserted.nameAgent, inserted.statusAgent as newStatus INTO #updatedVirtualAgents
            WHERE idAgent IN (SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,'','')) and statusAgent != @statusAgent

            SELECT * FROM #updatedVirtualAgents
        END

        ELSE IF @action = 6 --Check if there''s enabled related agent to camp 
        BEGIN
            DECLARE @result bit = 0;

            IF EXISTS (SELECT 1 FROM ccVirtualAgent WHERE idCampaign = @campaignId)
            BEGIN
                SELECT @result = statusAgent from ccVirtualAgent where idCampaign = @campaignId
            END

            select @result
        
        END
        ELSE IF (@action = 7) --- Get virtual agents by campaign id and camptype
        BEGIN
            DECLARE @defaultVoiceId VARCHAR(MAX)
            SELECT @defaultVoiceId = QuantumVoiceId FROM ccVirtualAgentVoices WHERE IsDefault = 1

            SELECT 
            cva.idAgent
            , ISNULL(cva.quantumAgentId,'''') AS QuantumAgentId
            , ISNULL(cva.location,'''') AS Location
            , ISNULL('''','''')  AS ProjectId
            , CASE 
                WHEN cva.voice IS NULL OR cva.voice = '''' THEN @defaultVoiceId
                ELSE ISNULL(cvav.QuantumVoiceId, @defaultVoiceId)
                END AS Voice
            FROM dbo.ccVirtualAgent AS cva
            LEFT JOIN ccVirtualAgentVoices cvav ON cvav.ID = cva.voice
            WHERE cva.idCampaign = @campaignId AND cva.campType = @campType;
        END
        ELSE IF (@action = 8) --- Reload virtual agent association
        BEGIN
            IF (@campType = 0)
                BEGIN 
                    SELECT 
                    cva.idAgent AS IdAgentVirtual
                    ,cva.nameAgent AS NameAgentVirtual
                    ,ISNULL(cva.concurrentSessionsLimit, 0) AS NumberSessions
                    ,CONVERT(INT, cva.idCampaign) AS IdCampaign
                    , cva.campType AS CampType
                FROM ccVirtualAgent cva
                LEFT JOIN ccInbound ci ON cva.idCampaign = ci.Inbound_id AND cva.campType = @campType
                WHERE cva.idAgent = (CASE WHEN @idVirtualAgent = 0 THEN cva.idAgent ELSE @idVirtualAgent END) 
                END
            ELSE 
            BEGIN 
                    SELECT 
                    cva.idAgent AS IdAgentVirtual
                    ,cva.nameAgent AS NameAgentVirtual
                    ,ISNULL(cva.concurrentSessionsLimit, 0) AS NumberSessions
                    ,CONVERT(INT, cva.idCampaign) AS IdCampaign
                    , cva.campType AS CampType
                FROM ccVirtualAgent cva
                LEFT JOIN ccCamps cc ON cva.idCampaign = cc.cam_id AND cva.campType = @campType
                WHERE cva.idAgent = (CASE WHEN @idVirtualAgent = 0 THEN cva.idAgent ELSE @idVirtualAgent END) 
                END
            END
        ELSE IF (@action = 9) --Get FileLocation from ccVirtualAgentVoices
        BEGIN
            select Name, FileName from ccVirtualAgentVoices where ID = @voiceID
        END
        ELSE IF (@action = 10) --Update voice
        BEGIN
            if exists(select * from ccVirtualAgent where idAgent=@idVirtualAgent)
            BEGIN
                update ccVirtualAgent set voice=@voiceID where idAgent=@idVirtualAgent
                select 1
            END
            ELSE BEGIN
                select 0
            END
        END
        ELSE IF(@action = 11) --get voice library
        BEGIN 
            select ID,Name,Gender, FileName, Language from ccVirtualAgentVoices
        END
        ELSE IF(@action = 12) -- get voice info by its Id
        BEGIN
            select QuantumVoiceId from ccVirtualAgentVoices where ID = @voiceID
        END
        ELSE IF (@action = 13) --Register model definition (Objectives, instructions, rules and variables)
        BEGIN
            DECLARE @modifiedModelName VARCHAR(255);

            IF NOT EXISTS(SELECT 1 FROM ccVirtualAgent WHERE idAgent = @idVirtualAgent and wasDeleted = 0)
            BEGIN
                SELECT 2 AS ErrorCode -- Agent deleted before saving changes
                RETURN
            END

            UPDATE ccVirtualAgent
            SET
                objective   = @objective,
                rules       = @rules,
                instructions = @instructions,
                scriptAgent = @variables,
                latestUpdateDateAgent = GETDATE(),
                statusAgent = CASE WHEN idCampaign <> 0 THEN 1 ELSE 0 END
            WHERE idAgent = @idVirtualAgent;

            IF @@ROWCOUNT = 1
            BEGIN
                SELECT @modifiedModelName = nameAgent
                FROM ccVirtualAgent
                WHERE idAgent = @idVirtualAgent;

                SELECT @idArea = IDArea, @userName = Login FROM ccUsers where User_id = @adminId

                -- ACTIVITY HISTORY REGISTER
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                    SELECT
                        (SELECT ISNULL(AreaName, '''') FROM ccRIACat_Areas WHERE IDArea = @idArea),
                        getDate(), 
                        @userName, 
                        170,
                        24,
                        ''VA_STRUCTURE_CONFIGURATION'',
                        '''',
                        @modifiedModelName
            
                SELECT 0 AS ErrorCode -- Success
            END
            ELSE
            BEGIN
                SELECT 1 AS ErrorCode -- Agent with no changes or not found
            END

        END
        ELSE IF (@action = 14)
        BEGIN
            SELECT
                idAgent As IdAgent,
                nameAgent As Nombre,
                statusAgent As Status,
                ISNULL(concurrentSessionsLimit,0) As concurrentSessionsLimit,
                ISNULL(CAST(idCampaign AS INT),0) As idCampaign,
                ISNULL(CAST(mediaType AS INT),0) As SubType,
                ISNULL(CAST(campType AS INT),0) As campType,
                ISNULL(location,'''') As location,
                ISNULL(quantumAgentId,'''') As QuantumAgentId,
                ISNULL(scriptAgent,'''') As scriptAgent,
                ISNULL(voice,'''') As voice,
                ISNULL(ReplyGreeting,'''') As ReplyGreeting,
                ISNULL(ReplyFarewell,'''')As ReplyFarewell,
                ISNULL(ReplySystemFailure,'''') As ReplySystemFailure,
                ISNULL(ReplyNoUnderstanding,'''') As ReplyNoUnderstanding,
                ISNULL(language,0) As language,
                ISNULL(responseTone,0) As responseTone,
                ISNULL(roleName,'''') As RolName,
                ISNULL(responseLength,0) As responseLength,
                ISNULL(quantumRoleId,0) As quantumRolId,
                ISNULL(objective,'''') As objective,
                ISNULL(rules,'''') As rules,
                ISNULL(instructions,'''') As instructions
            FROM 
                ccVirtualAgent
            WHERE 
                idAgent = @idVirtualAgent
        END
        ELSE IF (@action = 15) -- UPDATE Agent Virtual 
        BEGIN

            -- No deletion validation
            IF NOT EXISTS(SELECT 1 FROM ccVirtualAgent WHERE idAgent = @idVirtualAgent and wasDeleted = 0)
            BEGIN
                SELECT ''The agent was deleted before saving changes.'' AS Result, 7 AS ErrorCode
                RETURN
            END
            -- 

             -- *** NUEVA LÓGICA: Manejo automático de voz al cambiar idioma ***
            DECLARE @currentVoice INT,
                    @currentLanguage INT,
                    @currentGender NVARCHAR(10),
                    @homonymousVoiceID INT = NULL;
    
            SELECT @currentVoice = ISNULL(voice, 0), 
                   @currentLanguage = ISNULL(language, 0)
            FROM ccVirtualAgent 
            WHERE idAgent = @idVirtualAgent;
    
            IF @languageAgent IS NOT NULL 
               AND @languageAgent <> @currentLanguage
            BEGIN
                SELECT @currentGender = Gender 
                FROM ccVirtualAgentVoices 
                WHERE ID = @currentVoice;
        
                IF @currentGender IS NOT NULL
                BEGIN
                    SELECT TOP 1 @homonymousVoiceID = ID
                    FROM ccVirtualAgentVoices 
                    WHERE Language = @languageAgent 
                      AND Gender = @currentGender
                    ORDER BY IsDefault DESC, ID; -- Priorizar voz por defecto del idioma
            
                    IF @homonymousVoiceID IS NOT NULL AND (@voiceID IS NULL OR @voiceID = 0 OR @voiceID = @currentVoice)
                    BEGIN
                        SET @voiceID = @homonymousVoiceID; -- Actualizar a voz homónima
                    END
                END
            END
    
            IF (@voiceID IS NULL OR @voiceID = 0) AND @homonymousVoiceID IS NULL
            BEGIN
                SET @voiceID = @currentVoice;
            END

            DECLARE @AreaName  NVARCHAR(200),
                    @Login NVARCHAR(200),
                    @NameCampaing NVARCHAR(200);

            EXEC InsertLogAdminGalatea @action = 1,
                                        @tableName = ''ccVirtualAgent'',
                                        @columnNameId = ''idAgent'',
                                        @valueId = @idVirtualAgent,
                                        @userId = @adminId
            CREATE TABLE #ccVirtualAgentTable (
                columnInfo varchar(255),
                dataInfo varchar(255),
                identifierInfo varchar(255)
            )

            UPDATE ccVirtualAgent
            SET
                nameAgent = CASE 
                                WHEN @nameAgent IS NOT NULL 
                                        AND LTRIM(RTRIM(@nameAgent)) <> '''' 
                                        AND @nameAgent <> nameAgent 
                                THEN @nameAgent 
                                ELSE nameAgent 
                            END,

                latestUpdateDateAgent = GETDATE(),

                responseTone = CASE 
                                    WHEN @responseTone IS NOT NULL 
                                        AND @responseTone > 0 
                                        AND (@responseTone <> responseTone OR responseTone IS NULL)
                                    THEN @responseTone 
                                    ELSE responseTone 
                                END,

                language = CASE 
                                    WHEN @languageAgent IS NOT NULL 
                                        AND (@languageAgent <> language OR language IS NULL)
                                    THEN @languageAgent 
                                    ELSE language 
                                END,

                concurrentSessionsLimit = CASE 
                                                WHEN @numberOfAgents IS NOT NULL 
                                                    AND @numberOfAgents > 0 
                                                    AND (@numberOfAgents <> concurrentSessionsLimit OR concurrentSessionsLimit IS NULL)
                                                THEN @numberOfAgents 
                                                ELSE concurrentSessionsLimit 
                                            END,

                responseLength = CASE 
                                        WHEN @responseLength IS NOT NULL 
                                            AND @responseLength > 0 
                                            AND (@responseLength <> responseLength OR responseLength IS NULL)
                                        THEN @responseLength 
                                        ELSE responseLength 
                                    END,

                ReplyGreeting = CASE 
                                    WHEN @replyGreeting IS NOT NULL 
                                            AND LTRIM(RTRIM(@replyGreeting)) <> '''' 
                                            AND (@replyGreeting <> ReplyGreeting OR ReplyGreeting IS NULL)
                                    THEN @replyGreeting 
                                    ELSE ReplyGreeting 
                                END,

                ReplyFarewell = CASE 
                                    WHEN @replyFarewell IS NOT NULL 
                                            AND LTRIM(RTRIM(@replyFarewell)) <> '''' 
                                            AND (@replyFarewell <> ReplyFarewell OR ReplyFarewell IS NULL)
                                    THEN @replyFarewell 
                                    ELSE ReplyFarewell 
                                END,

                ReplySystemFailure = CASE 
                                            WHEN @replySystemFailure IS NOT NULL 
                                                AND LTRIM(RTRIM(@replySystemFailure)) <> '''' 
                                                AND (@replySystemFailure <> ReplySystemFailure OR ReplySystemFailure IS NULL)
                                            THEN @replySystemFailure 
                                            ELSE ReplySystemFailure 
                                        END,

                ReplyNoUnderstanding = CASE 
                                            WHEN @replyNoUnderstanding IS NOT NULL 
                                                AND LTRIM(RTRIM(@replyNoUnderstanding)) <> '''' 
                                                AND (@replyNoUnderstanding <> ReplyNoUnderstanding OR ReplyNoUnderstanding IS NULL)
                                            THEN @replyNoUnderstanding 
                                            ELSE ReplyNoUnderstanding 
                                        END,

                voice = CASE 
                            WHEN @voiceID IS NOT NULL 
                                    AND @voiceID > 0 
                                    AND (@voiceID <> voice OR voice IS NULL)
                            THEN @voiceID 
                            ELSE voice 
                        END
            WHERE idAgent = @idVirtualAgent;

            IF @campaignId IS NOT NULL
            BEGIN
                EXEC dbo.ccsp_VirtualAgents
                        @action=4,@adminId=@adminId, @campType=@campType, @campaignId=@campaignId, @mediaType=@mediaType, @idVirtualAgent=@idVirtualAgent;
                IF @campaignId <> 0
                BEGIN
                    IF @mediaType = 11
                    BEGIN
                        SELECT
                            @NameCampaing = [descripcion]
                        FROM ccInbound
                        WHERE inbound_id = @campaignId
                    END
                    ELSE
                        SELECT
                            @NameCampaing = cam_descripcion
                        FROM ccCamps
                        WHERE cam_id = @campaignId
                END
            END

            EXEC InsertLogAdminGalatea @action = 2,
                                        @tableName = ''ccVirtualAgent'',
                                        @columnNameId = ''idAgent'',
                                        @valueId = @idVirtualAgent,
                                        @userId = @adminId,
                                        @tableTemp = ''#ccVirtualAgentTable''

            SELECT  @Login = U.[Login],
                    @AreaName = A.[AreaName]
            FROM ccUsers AS U
            LEFT JOIN ccRIACat_Areas AS A
                ON A.IDArea = U.IDArea
            WHERE U.User_id = @adminId;

            SELECT @NameAgent = v.nameAgent
            FROM dbo.ccVirtualAgent AS v
            WHERE v.idAgent = @idVirtualAgent;

            ;WITH src AS (
                SELECT 
                    CCVA.*,
                    ROW_NUMBER() OVER (
                        PARTITION BY CCVA.identifierInfo 
                        ORDER BY CCVA.columnInfo 
                    ) AS rn
                FROM #ccVirtualAgentTable AS CCVA
            )
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            SELECT
                @AreaName,
                GETDATE(),
                @Login,
                171,
                24,
                S.identifierInfo,
                CASE
                    WHEN S.identifierInfo IS NOT NULL AND S.identifierInfo <> '''' THEN 
                        CASE
                            WHEN S.identifierInfo = ''VA_LANGUAGE'' THEN
                                CASE S.dataInfo
                                    WHEN 1 THEN ''VA_ENGLISH_EN''
                                    WHEN 2 THEN ''VA_PORTUGUESE_PT''
                                    ELSE ''VA_SPANISH_ES''
                                END
                            WHEN S.identifierInfo = ''VA_TONE_OF_VOICE'' THEN
                                CASE S.dataInfo
                                    WHEN 1 THEN ''VA_FORTHRIGHT_AND_CONCISE''
                                    WHEN 2 THEN ''VA_SYMPATHETIC_AND_WARM''
                                    WHEN 3 THEN ''VA_PERSUASIVE_AND_ACTION_ORIENTED''
                                    WHEN 4 THEN ''VA_NEUTRAL_AND_OBJECTIVE''
                                    WHEN 5 THEN ''VA_RELAXED_AND_FRIENDLY''
                                    ELSE ''VA_NONE_TV''
                                END
                            WHEN S.identifierInfo = ''VA_RESPONSE_LENGTH'' THEN
                                CASE S.dataInfo
                                    WHEN 1 THEN ''VA_SHORT_RESPONSE''
                                    WHEN 2 THEN ''VA_MEDIUM_RESPONSE''
                                    WHEN 3 THEN ''VA_LONG_RESPONSE''
                                    ELSE ''VA_NONE''
                                END
                            WHEN S.identifierInfo = ''VA_VIRTUAL_AGENT_CAMPAIGN'' THEN
                                CASE S.dataInfo
                                    WHEN 0 THEN ''VA_NONE'' 
                                    ELSE @NameCampaing
                                END
                            WHEN S.identifierInfo = ''VA_VOICE_TYPE'' THEN
                                CASE S.dataInfo
                                    WHEN 1 THEN ''VA_VOICE_FEMALE''
                                    WHEN 3 THEN ''VA_VOICE_FEMALE''
                                    WHEN 5 THEN ''VA_VOICE_FEMALE''
                                    WHEN 2 THEN ''VA_VOICE_MALE''
                                    WHEN 4 THEN ''VA_VOICE_MALE''
                                    WHEN 6 THEN ''VA_VOICE_MALE''
                                    ELSE ''VA_VOICE_MALE''
                                END
                            WHEN S.identifierInfo = ''VA_SCRIPTED_RESPONSES'' THEN
                                ''VA_RESPONSES'' 
                            ELSE S.dataInfo
                        END
                    ELSE ''''
                END,
                @NameAgent
            FROM src AS S
            WHERE NULLIF(LTRIM(RTRIM(S.identifierInfo)), '''') IS NOT NULL
                AND NOT (S.identifierInfo = ''VA_SCRIPTED_RESPONSES'' AND S.rn > 1)

        
            EXEC InsertLogAdminGalatea @action = 3,
                                        @tableName = ''ccVirtualAgent'',
                                        @columnNameId = ''idAgent'',
                                        @valueId = @idVirtualAgent,
                                        @userId = @adminId

            IF OBJECT_ID(N''tempdb..#ccVirtualAgentTable'') IS NOT NULL
            DROP TABLE #ccVirtualAgentTable

            SELECT ''Agent successfully updated'' AS Result, 0 AS ErrorCode, @idVirtualAgent as IdAgent;
        END

        ELSE IF (@action = 16) -- Duplicate virtual agent
        BEGIN
            SET NOCOUNT ON;

            DECLARE @newAgentId INT;

            IF EXISTS(SELECT 1 FROM ccVirtualAgent WHERE nameAgent = @nameAgent and wasDeleted = 0)
            BEGIN
                SELECT ''A virtual agent with the same name already exists'' as Result, 1 as ErrorCode
                RETURN
            END
    
            -- Validación de capacidad (variables con nombres únicos)
            DECLARE @TotalOfConcurrentAgents_16 INT,
                    @UsedConcurrentAgents_16   INT;

            SELECT @TotalOfConcurrentAgents_16 = CAST(valor AS INT)
            FROM ccSettings2
            WHERE setting_id = 281;

            SELECT @UsedConcurrentAgents_16 = ISNULL(SUM(concurrentSessionsLimit), 0)
            FROM ccVirtualAgent
            WHERE wasDeleted = 0;

            IF ((@UsedConcurrentAgents_16 + ISNULL(@numberOfAgents,0)) > ISNULL(@TotalOfConcurrentAgents_16,0))
            BEGIN
                SELECT ''There are not contracted agents available'' AS Result, 2 AS ErrorCode;
                RETURN;
            END

            -- Crear el duplicado copiando del original y sobrescribiendo con valores del frontend
            INSERT INTO ccVirtualAgent (
                nameAgent,
                statusAgent,
                createDateAgent,
                latestUpdateDateAgent,
                responseTone,
                language,
                quantumRoleId,
                roleName,
                responseLength,
                quantumAgentId,
                concurrentSessionsLimit,
                voice,
                ReplyGreeting,
                ReplyFarewell,
                ReplySystemFailure,
                ReplyNoUnderstanding,
                objective,
                rules,
                instructions,
                scriptAgent,
                OriginalAgentId,
                CopiesCount,
                wasDeleted,
                idCampaign,
                mediaType,
                campType
            )
            SELECT
                @nameAgent,                    
                0,                             
                GETDATE(),
                GETDATE(),
                @responseTone,                
                @languageAgent,                
                @quantumRoleId,                 
                @roleDescription,                      
                @responseLength,               
                @quantumAgentId,               
                @numberOfAgents,               
                @voiceID,                         
                @ReplyGreeting,                 
                @ReplyFarewell,                
                @ReplySystemFailure,            
                @ReplyNoUnderstanding,         
                objective,                     
                rules,                         
                instructions,                 
                scriptAgent,                   
                @originalAgentId,                       
                0,                             -- Sin copias propias todavía
                0,                             -- No eliminado
                0,                             -- Sin campaña
                0,                             -- Sin mediaType
                0                              -- Sin campType
            FROM ccVirtualAgent
            WHERE idAgent = @originalAgentId;

            SET @newAgentId = SCOPE_IDENTITY();

            IF (@newAgentId IS NULL)
            BEGIN
                SELECT ''Source agent not found'' AS Result, 2 AS ErrorCode, NULL AS IdAgent, @originalAgentId AS OriginalAgentId;
                RETURN;
            END

            -- Actualizar contador del padre
            UPDATE ccVirtualAgent 
            SET CopiesCount = ISNULL(CopiesCount, 0) + 1,
                latestUpdateDateAgent = GETDATE()
            WHERE idAgent = @originalAgentId;

            -- Registrar actividad
            SELECT @idArea = IDArea, @userName = Login 
            FROM ccUsers 
            WHERE User_id = @adminId;

            INSERT INTO ccGalateaActivityLog (
                Area, 
                ActivityDate, 
                Login, 
                OperationId, 
                ModuleId, 
                Identifier, 
                Value, 
                Target
            )
            SELECT
                (SELECT ISNULL(AreaName, '''') FROM ccRIACat_Areas WHERE IDArea = @idArea),
                GETDATE(), 
                @userName, 
                174,
                24,
                '''',
                '''',
                @nameAgent;

            -- Retornar resultado
            SELECT ''Agent duplicated successfully'' AS Result,
                    0 AS ErrorCode,
                    @newAgentId AS IdAgent,
                    @originalAgentId AS OriginalAgentId;
        END
    END     '
    exec (@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[SaveDispositionsAI]'
    SET @sql = 'ALTER PROCEDURE [dbo].[SaveDispositionsAI]
@action        smallint    = NULL,
@call_Id       int         = NULL,
@Qualification varchar(MAX)= NULL,
@result        varchar(MAX)= NULL,
@Observations  varchar(MAX)= NULL,
@CallbackAT    DATETIME = NULL,
@Transcription varchar(MAX)= NULL,
@CamType       bit         = 0,
@disposition_Id SMALLINT = null,
@CapturedData varchar(max) = null
AS
BEGIN
    SET NOCOUNT ON;
    --Variables para devolución de llamada 
    DECLARE @cal_key varchar(40) ='''';
    DECLARE @cam_id smallint;
    DECLARE @cal_telefono varchar(19);
    DECLARE @inbound_id smallint = NULL;
    DECLARE @CanReprogram smallint  = null

    -- Validacion del Status del Setting 289
    DECLARE @trans_status BIT = NULL;

    DECLARE @valor  NVARCHAR(15) = NULL;

    SELECT @valor = TRY_CAST(valor AS NVARCHAR(15)) 
    FROM ccSettings2
    WHERE setting_id = 289;

    DECLARE @status NVARCHAR(5);
    DECLARE @sep    INT;
    declare @name_cal varchar(150) = '''';

    SET @sep = CHARINDEX(''|'', ISNULL(@valor, ''''));
    SET @status = CASE
                    WHEN @sep > 0 THEN SUBSTRING(@valor, 1, @sep - 1)
                    ELSE ISNULL(@valor, '''')
                  END;

    IF @action = 1  -- Outbound
    BEGIN
    
        select @name_cal = isnull(Name_cal, ''N/A'') from cctipoCalif_IA where Description_cal = @Qualification

        IF EXISTS (SELECT 1 FROM ccoCallsOutDispositionIA WHERE call_id = @call_Id)
        BEGIN   
            UPDATE ccoCallsOutDispositionIA
            SET Qualification = @Qualification,
                name_cal = @name_cal,
                result = @result,
                Observations = @Observations,
                CapturedData = @CapturedData
            WHERE call_id = @call_Id;
        END
        ELSE
        BEGIN
            INSERT INTO ccoCallsOutDispositionIA (call_id, name_cal, Qualification, result, Observations,CapturedData)
            VALUES (@call_Id, @name_cal, @Qualification, @result, @Observations,@CapturedData);
        END

        IF EXISTS (SELECT 1 FROM dbo.cctipoCalif_IA AS cci WHERE cci.calif_id = @disposition_Id)
        BEGIN
            UPDATE dbo.ccoCallsOut 
            SET calif_id = @disposition_Id
            WHERE cal_id = @call_Id;
        END
    END

    ELSE IF @action = 2 AND @status = ''1''   -- Outbound
    BEGIN
        Select @cam_id = cam_id
        From ccoCallsOut
        Where cal_id = @call_Id

        Select @trans_status = IsCallTranscriptionEnabled
        From ccCampsExtend
        Where cam_id  = @cam_id
    
        if  @trans_status = 1 BEGIN
            IF  EXISTS (SELECT 1 FROM ccoCallsOutTranscriptionIA WHERE call_id = @call_Id)
            BEGIN
                UPDATE ccoCallsOutTranscriptionIA
                SET Transcription = @Transcription
                WHERE call_id = @call_Id;
            END
            ELSE
            BEGIN
                INSERT INTO ccoCallsOutTranscriptionIA (call_id, Transcription)
                VALUES (@call_Id, @Transcription);
            END
        END
    END

    ELSE IF @action = 3  -- Inbound
    BEGIN
        Select @CanReprogram = CanReprogram from dbo.cctipoCalif_IA  where calif_id = @disposition_Id
    
        IF (@CallbackAT IS NOT NULL  
            AND CONVERT(datetime, @CallbackAT, 120) IS NOT NULL 
            AND CONVERT(datetime, @CallbackAT, 120) > GETDATE()  
            AND @CanReprogram <> 0)
        BEGIN
            INSERT INTO ccCallsInDispositionIA (call_id, Qualification, result, Observations, CallbackAT,disposition_id,CapturedData)
            VALUES (@call_Id, @Qualification, @result, @Observations,@CallbackAT,@disposition_Id,@CapturedData);

            SELECT @inbound_id = Inbound_id, @cal_telefono = cal_ANI
                FROM ccCallsIn 
                WHERE cal_id = @call_Id;

            SELECT @cam_id = cam_id
                FROM ccInbound
                WHERE Inbound_id  = @inbound_id

            EXEC ccsp_INInsertaCallBack
                @cal_key = @call_Id,
                @cam_id = @cam_id,
                @cal_telefono = @cal_telefono,
                @fechadial = @CallbackAT,
                @dato4 = @result,
                @dato5 = @Observations

            IF EXISTS (SELECT 1 FROM dbo.cctipoCalif_IA WHERE calif_id = @disposition_Id)
            BEGIN
                UPDATE ccCallsIn
                SET calif_id = @disposition_Id
                WHERE cal_id = @call_Id;
            END
        END

        ELSE BEGIN
            INSERT INTO ccCallsInDispositionIA (call_id, Qualification, result, Observations,disposition_id,CapturedData)
            VALUES (@call_Id, @Qualification, @result, @Observations,@disposition_Id,@CapturedData);

            IF EXISTS (SELECT 1 FROM dbo.cctipoCalif_IA WHERE calif_id = @disposition_Id)
            BEGIN
                UPDATE ccCallsIn
                SET calif_id = @disposition_Id
                WHERE cal_id = @call_Id;
            END
        END

    END

    ELSE IF @action = 4 AND @status = ''1''   -- Inbound
    BEGIN
    
        Select @inbound_id = Inbound_id 
            From ccCallsIn 
            Where cal_id = @call_Id
    
        Select @trans_status = IsCallTranscriptionEnabled
            From ccInboundExtend
            Where Inbound_id  = @inbound_id

        IF @trans_status = 1
        BEGIN
            INSERT INTO ccCallsInTranscriptionIA (call_id, Transcription)
            VALUES (@call_Id, @Transcription);
        END
    END
END'
    exec (@sql)

    ------------------------------------ BEGIN Configuración Menú (CCenterRIA) ------------------------------------
SET @process = 'Configuración de Menú (2150) - Agentes Virtuales';

SET @sql = '
IF NOT EXISTS (SELECT 1 FROM ccMenus WHERE menu_id = 2150)
BEGIN
    INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release) 
    VALUES (2150, ''Agentes virtuales|Virtual Agents'', 2000, ''B'', 2, 3, '''', ''505b0c30ff896f2db7e7b7946607de282293a6ed731cb58b9192c6d4a764bb05'');
    PRINT ''Menú 2150 insertado en ccMenus.'';
END

IF NOT EXISTS (SELECT 1 FROM ccMenuUser WHERE id_User = 1 AND id_Menu = 2150)
BEGIN
    INSERT INTO ccMenuUser (id_User, id_Menu, type) 
    VALUES (1, 2150, 3);
    PRINT ''Permiso asignado al usuario 1 en ccMenuUser.'';
END
'
EXEC(@sql);

------------------------------------ BEGIN Ajuste Tablas DispositionIA ------------------------------------
SET @process = 'Agregar columna CapturedData a tablas de Disposición IA';

SET @sql = '
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''CapturedData'' AND Object_ID = Object_ID(N''dbo.ccoCallsOutDispositionIA''))
BEGIN
    ALTER TABLE dbo.ccoCallsOutDispositionIA ADD CapturedData VARCHAR(MAX) DEFAULT '''' WITH VALUES;
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''CapturedData'' AND Object_ID = Object_ID(N''dbo.ccCallsInDispositionIA''))
BEGIN
    ALTER TABLE dbo.ccCallsInDispositionIA ADD CapturedData VARCHAR(MAX) DEFAULT '''' WITH VALUES;
END
'
EXEC(@sql);

    SET @process = ' ALTER TABLE ccCampsExtend ADD IsCallTranscriptionEnabled BIT NULL'
    SET @sql = '
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''IsCallTranscriptionEnabled'' AND Object_ID = Object_ID(N''ccCampsExtend''))
BEGIN
    ALTER TABLE ccCampsExtend ADD IsCallTranscriptionEnabled BIT NULL
END

IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''IN_CALL_IA_CALL_TRANSCRIPTION'' AND tableName = ''ccCampsExtend'') BEGIN 
    INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
    VALUES (''IN_CALL_IA_CALL_TRANSCRIPTION'',''ccCampsExtend'',''IsCallTranscriptionEnabled'')
END'
    exec (@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
    @User_id SMALLINT,
    @campID INT = NULL
AS
    SET NOCOUNT ON;

    DECLARE @tableExistsRec TABLE (
        camId INT PRIMARY KEY,
        existRec BIT
    );
    DECLARE @camByUser TABLE (
        camId INT PRIMARY KEY,
        isCheck BIT
    );
    DECLARE @camId INT, @id INT;
    DECLARE @intenationalDialingPorts BIT;
    DECLARE @tempInternationalCode INT;

    IF (
        SELECT COUNT(*)
        FROM (
            SELECT TOP 1 IdCode
            FROM ccoDialers ccoDial
            INNER JOIN ccoDialerCamp ccoDialCamp ON ccoDialCamp.dialer_id = ccoDial.dialer_id
            WHERE ccoDialCamp.cam_id = @campID
                AND ccoDial.DialingType = 0
        ) result
    ) > 0
    BEGIN
        SET @intenationalDialingPorts = 1;
    END
    ELSE
    BEGIN
        SET @intenationalDialingPorts = 0;
    END;

    IF NOT EXISTS (
        SELECT *
        FROM ccUsers_Roles
        WHERE User_id = @User_id
            AND Rol_id = 7
    )
    BEGIN
        INSERT INTO @camByUser
        SELECT *, 0
        FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
        WHERE @campID IS NULL
            OR cam_id = @campID;
    END
    ELSE
    BEGIN
        INSERT INTO @camByUser
        SELECT cam_id, 0
        FROM ccCamps
        WHERE (IDArea > 0 OR IDArea IS NULL)
            AND (@campID IS NULL OR cam_id = @campID);
    END;

    WHILE EXISTS (
        SELECT *
        FROM @camByUser
        WHERE isCheck = 0
    )
    BEGIN
        SELECT TOP 1 @camId = camId
        FROM @camByUser
        WHERE isCheck = 0;

        IF EXISTS (
            SELECT cam_id
            FROM ccoCallsOut
            WHERE cam_id = @camId
        )
        BEGIN
            INSERT INTO @tableExistsRec
            VALUES (@camId, 1);
        END
        ELSE
        BEGIN
            INSERT INTO @tableExistsRec
            VALUES (@camId, 0);
        END;

        UPDATE @camByUser
        SET isCheck = 1
        WHERE camId = @camId;
    END;

    SELECT
        a1.cam_id,
        cam_Descripcion,
        cam_tNotas,
        CAST(cam_ocupado AS INT) AS cam_ocupado,
        cam_noInt_ocupado,
        cam_inter_ocupado,
        CAST(cam_nocontesto AS INT) AS cam_nocontesto,
        cam_noInt_nocontesto,
        cam_inter_nocontesto,
        CAST(cam_fax AS INT) AS cam_fax,
        cam_noInt_fax,
        cam_inter_fax,
        CAST(cam_modomanual AS INT) AS cam_modomanual,
        ANI,
        cam_ShowCalifWnd,
        cam_StartTimerOnHangUp,
        editableCallKey,
        cam_tNoContesta,
        iTipoDial,
        detectAnswerMachine,
        detectVoiceMail,
        compliance,
        cam_inter_graba,
        cam_noint_graba,
        CAST(progDial AS TINYINT) progDial,
        CAST(excCallBack AS TINYINT) excCallBack,
        dialOrder,
        dialPrefix,
        dialPrefixMan,
        dialPrefixXfe,
        listenManualCall,
        stopRecording,
        CAST(abandonCallback AS TINYINT) abandonCallback,
        a3.frame,
        a1.t_autoCB,
        a1.id_anilist,
        a1.tDialonWrapUp,
        dbo.fn_viewMode(@User_id, 10) viewMode,
        cam_maxqueue AS queSize,
        DNCScrub,
        callerIdDesc,
        timeZoneRule,
        callsBySurvey,
        ivrScript,
        surveyPctg,
        ISNULL(a1.call_record, 1) AS call_record,
        CAST(startStopRecording AS TINYINT) startStopRecording,
        leaveRecMessage,
        manualCallOnChat,
        callBackSurveyAgent,
        callBackSurveyClient,
        CASE
            WHEN surveycamid IS NULL OR surveycamid = 0 THEN 0
            ELSE 1
        END isRelationSurvey,
        ISNULL(a1.funcEspDtmf, 0) funcEspDtmf,
        ISNULL(sipHdrFormat, '''') sipHdrFormat,
        cam_inter_cancelled,
        prefijo,
        enbleprefix = CASE
            WHEN existRec = 0 THEN 1
            ELSE 0
        END,
        ISNULL(exitAssisted, 0) exitAssisted,
        ISNULL(previewDiscard, 0) PreviewDiscard,
        case when CampType = 9 then 10 else ISNULL(CampType, 0) end as CampType,
        ISNULL(contact.conexionInfo, '''') conexionInfo,
        ISNULL(contact.connUser, '''') connUser,
        ISNULL(contact.closeConversationTime, 0) closeConversationTime,
        ISNULL(contact.answerTimeoutClient, 0) answerTimeoutClient,
        ISNULL(contact.allowFileAttachments, 0) allowFileAttachments,
        ISNULL(selectRotativeANI, 0) selectRotativeANI,
        ISNULL(rotativeAlgo, 0) rotativeAlgo,
        ISNULL(autoStart, 0) autoStart,
        ISNULL(messagingOrder, 0) messagingOrder,
        ISNULL(cam_tPreview, 0) AS CamTPreview,
        ISNULL(timesPreview, 0) AS TimesPreview,
        ISNULL(timesDiscard, 0) TimesDiscard,
        ISNULL(recordHold, 0) recordHold,
        ISNULL(campsExtention.zipCodeSchedule, 0) ZipCodeSchedule,
        ISNULL(campsExtention.RecordCalls, 1) RecordCalls,
        ISNULL(campsExtention.simultaneousRecs, 1) simultaneousRecs,
        ISNULL(campsExtention.EditableContactData, 0) EditableContactData,
        @intenationalDialingPorts intenationalDialingPorts,
        ISNULL(campsExtention.AssignConversationSameAgent, 0) AssignConversationSameAgent,
        ISNULL(contact.maxLimitQueueConversations, 99) maxLimitQueueConversations,
        ISNULL(contact.MaxDaysPerWAConvo, 5) MaxDaysPerWAConvo,
        isnull(recordIvr, 1) recordIvr,
        ISNULL(CamCanceled, 4) CamCanceled,
        ISNULL(surveyCamId, 0) surveyCamId,
        -- Outbound AI Campaign Special Settings
        ISNULL(campsExtention.RescheduledSurveyAI, 0) RescheduledSurveyAI,
        ISNULL(campsExtention.ImmediateSurveyAI, 0) ImmediateSurveyAI,
        ISNULL(campsExtention.ApplyRescheduledSurveyForCompletedCallsAI, 0) ApplyRescheduledSurveyForCompletedCallsAI,
        ISNULL(campsExtention.EnableCallRecordingAI, 0) EnableCallRecordingAI,
		-- Manual Rotation Dialing Configurations
		ISNULL(a1.rotativeAlgorithmManual, 4) RotativeAlgorithmManual ,
		ISNULL(a1.idAniListManual, 0) IdAniListManual ,
		ISNULL(campsExtention.ManualCallANIMode, 0) ManualCallANIMode,
    	ISNULL(campsExtention.IsCallTranscriptionEnabled, 0) IsCallTranscriptionEnabled
    FROM ccCamps a1
    INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
    INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
    INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
    LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
    LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
    ORDER BY cam_descripcion;

    RETURN (0);

    SET NOCOUNT OFF;
'
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
		,ManualCallANIMode SMALLINT
		,TranscribeCalls bit	
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
		,ManualCallANIMode ManualCallANIMode
        ,@ScriptVariables AS ScriptVariables
	,ISNULL(TranscribeCalls, 0) as TranscribeCalls
        FROM @AllCampaigns
        WHERE cam_id = @campID
    END'
    exec (@sql)


    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
        @cam_id SMALLINT,
        @zipCodeSchedule BIT = NULL,
        @userId SMALLINT = NULL,
        @idArea SMALLINT = NULL,
        @isCreating SMALLINT = NULL,
        @simultaneousRecs SMALLINT = NULL,
        @module INT = -1,
        @recordCalls TINYINT = 1,
        @editableContactData BIT = 1,
        @assignConversationSameAgent BIT = 0,
        @RescheduledSurveyAI BIT = 0,
        @ImmediateSurveyAI BIT = 0,
        @ApplyRescheduledSurveyForCompletedCallsAI BIT = 0,
        @EnableCallRecordingAI BIT = 1,
	@IsCallTranscriptionEnabled BIT=0,
	@ManualCallANIMode SMALLINT = 0
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @country INT = (SELECT valor FROM ccSettings WHERE setting_id = 104);
        DECLARE @excludeIdentifier VARCHAR(255) = CASE WHEN @country = 4 THEN ''COMMON_INTERNATIONAL_RECORD_CALLS'' ELSE ''COMMON_USA_RECORD_CALLS'' END;

        IF EXISTS (SELECT * FROM ccCampsExtend WHERE cam_id = @cam_id)
        BEGIN
            EXEC InsertLogAdminGalatea @action = 1, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userId;

            IF OBJECT_ID(N''tempdb..#ccCampsExtendTable'') IS NOT NULL DROP TABLE #ccCampsExtendTable;

            CREATE TABLE #ccCampsExtendTable
            (
                columnInfo VARCHAR(255),
                dataInfo VARCHAR(255),
                identifierInfo VARCHAR(255)
            );

            DECLARE @Camptype INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @cam_id);
            DECLARE @operation SMALLINT = CASE
                WHEN @isCreating = 1 THEN
                    CASE
                        WHEN @Camptype = 6 THEN 44
                        WHEN @Camptype = 5 THEN 46
                        WHEN @Camptype = 4 OR @Camptype = 9 THEN 48 -- TODO: Delete MediaType 4
                        WHEN @Camptype = 7 THEN 50
                        ELSE 42
                    END
                ELSE
                    CASE
                        WHEN @Camptype = 6 THEN 55
                        WHEN @Camptype = 5 THEN 56
                        WHEN @Camptype = 4 OR @Camptype = 9 THEN 57 -- TODO: Delete MediaType 4
                        WHEN @Camptype = 7 THEN 58
                        ELSE 54
                    END
                END;

            UPDATE ccCampsExtend
            SET
                zipCodeSchedule = ISNULL(@zipCodeSchedule, zipCodeSchedule),
                simultaneousRecs = ISNULL(@simultaneousRecs, simultaneousRecs),
                RecordCalls = ISNULL(@recordCalls, RecordCalls),
                EditableContactData = ISNULL(@editableContactData, EditableContactData),
                AssignConversationSameAgent = ISNULL(@assignConversationSameAgent, AssignConversationSameAgent),
                -- Outbound AI Campaign Special Settings
                RescheduledSurveyAI = ISNULL(@RescheduledSurveyAI, RescheduledSurveyAI),
                ImmediateSurveyAI = ISNULL(@ImmediateSurveyAI, ImmediateSurveyAI),
                ApplyRescheduledSurveyForCompletedCallsAI = ISNULL(@ApplyRescheduledSurveyForCompletedCallsAI, ApplyRescheduledSurveyForCompletedCallsAI),
                EnableCallRecordingAI = ISNULL(@EnableCallRecordingAI, EnableCallRecordingAI),
		ManualCallANIMode = ISNULL(@ManualCallANIMode, ManualCallANIMode),
		IsCallTranscriptionEnabled = ISNULL(@IsCallTranscriptionEnabled, IsCallTranscriptionEnabled)
            WHERE cam_id = @cam_id;

            IF (@isCreating > 0 AND @module > -1)
                EXEC InsertLogAdminGalatea @action = 2, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userId, @tableTemp = ''#ccCampsExtendTable'';

            IF (@idArea IS NULL OR @idArea = -1)
                SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id);

            IF (@isCreating = 1) BEGIN
                DELETE FROM #ccCampsExtendTable WHERE identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') AND dataInfo = 0;
		DELETE FROM #ccCampsExtendTable WHERE identifierInfo IN (''OUT_ANI_MODE_MANUAL'') 
	    END
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            SELECT
                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
                GETDATE(),
                (SELECT [Login] FROM ccUsers WHERE User_id = @userId),
                @operation,
                @module,
                CCCE.identifierInfo,
                CASE
                    WHEN CCCE.identifierInfo IS NOT NULL AND CCCE.identifierInfo <> '''' THEN
                        CASE
			    WHEN CCCE.identifierInfo = ''OUT_MANUAL_CALL_ANI_MODE'' THEN
				CASE
					WHEN @ManualCallANIMode = 0 THEN ''OUT_MANUAL_CALL_ANI_MODE_NONE''
					WHEN @ManualCallANIMode = 1 THEN ''OUT_MANUAL_CALL_ANI_MODE_SYSTEM''
					WHEN @ManualCallANIMode = 2 THEN ''OUT_MANUAL_CALL_ANI_MODE_AGENT''
					ELSE ''''
				END
                            WHEN CCCE.identifierInfo IN (''SETTINGS_CHANGED_AREAS_ZIP'', ''COMMON_INTERNATIONAL_RECORD_CALLS'', ''EDIT_CALL_DATASET'') THEN
                                CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                            WHEN @isCreating = 1 THEN
                                CASE WHEN CCCE.identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') THEN
                                    CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' END
                                END
                            WHEN @isCreating = 2 THEN
                                CASE WHEN CCCE.identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') THEN
                                    CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                                END
                            WHEN CCCE.identifierInfo IN (''COMMON_USA_RECORD_CALLS'') THEN
                                CASE
                                    WHEN CCCE.dataInfo = 1 THEN ''COMMON_USA_RECORD_CALLS_MODE_ALL''
                                    WHEN CCCE.dataInfo = 2 THEN ''COMMON_USA_RECORD_CALLS_MODE_AUTH''
                                    WHEN CCCE.dataInfo = 4 THEN ''COMMON_USA_RECORD_CALLS_MODE_NOAUTH''
                                    ELSE ''COMMON_DISABLED''
                                END
                            ELSE CCCE.dataInfo
                        END
                    ELSE ''''
                END,
                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
            FROM #ccCampsExtendTable AS CCCE WHERE CCCE.identifierInfo != @excludeIdentifier;

            EXEC InsertLogAdminGalatea @action = 3, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userId;

            IF OBJECT_ID(N''tempdb..#ccCampsExtendTable'') IS NOT NULL DROP TABLE #ccCampsExtendTable;

        END
        ELSE
        BEGIN
            INSERT INTO ccCampsExtend (
                cam_id,
                zipCodeSchedule,
                SimultaneousRecs,
                RecordCalls,
                AssignConversationSameAgent,
                RescheduledSurveyAI,
                ImmediateSurveyAI,
                ApplyRescheduledSurveyForCompletedCallsAI,
                EnableCallRecordingAI,
		ManualCallANIMode,
		IsCallTranscriptionEnabled
            )
            VALUES (
                ISNULL(@cam_id, 0),
                ISNULL(@zipCodeSchedule, ''''),
                ISNULL(@simultaneousRecs, 0),
                ISNULL(@recordCalls, 0),
                ISNULL(@assignConversationSameAgent, 0),
                -- Outbound AI Campaign Special Settings
                ISNULL(@RescheduledSurveyAI, 0),
                ISNULL(@ImmediateSurveyAI, 0),
                ISNULL(@ApplyRescheduledSurveyForCompletedCallsAI, 0),
                ISNULL(@EnableCallRecordingAI, 1),
		ISNULL(@ManualCallANIMode, 0),
            	ISNULL(@IsCallTranscriptionEnabled, 0)
            );

            SET NOCOUNT OFF;
        END
        UPDATE ccCamps SET call_record = @recordCalls WHERE cam_id = @cam_id;
    END'
    exec (@sql)

	SET @process = 'KM47001 alter procedure to call rotation from the agent'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ManualCallGetRotativeAni]
@phones VARCHAR(MAX),
@camId INT
AS
set nocount on
DECLARE @ManualCallANIMode SMALLINT

SELECT @ManualCallANIMode = ISNULL(ManualCallANIMode, 0) FROM ccCampsExtend WHERE cam_id = @camId;

IF(@ManualCallANIMode > 0) BEGIN
	DECLARE @aniId INT;
	DECLARE @rotativeAlgo INT;
	DECLARE @Anis TABLE(id INT, pid VARCHAR(2), phone VARCHAR(32), ani VARCHAR(32));

	SELECT @aniId = [idAniListManual], @rotativeAlgo = [rotativeAlgorithmManual] FROM ccCamps WHERE cam_id = @camId;

	INSERT @Anis
	EXEC ccsp_DLRGetRotativeANI @callout_id=0, @phones=@phones, @aniList=@aniId,@algo=@rotativeAlgo;

	IF EXISTS(SELECT 1 FROM @Anis) BEGIN
		SELECT TOP 1 ani FROM @Anis
	END ELSE IF EXISTS (SELECT valor FROM ccSettings WHERE setting_id = 177) BEGIN
		SELECT * FROM ccSettings WHERE setting_id = 177
	END ELSE BEGIN
		SELECT ''''
	END
END
ELSE BEGIN
	SELECT ''''
END
set nocount off'
        EXEC(@sql);

    
    SET @process= 'KM47001 ALTER ccsp_RIAUpdateCamConfig'
	SET @sql ='ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
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
    @cam_tPreview smallint = null,
    @timesDiscard tinyint = null,
    @CampType int = null,
    @agentCloseConversationTime SMALLINT = NULL,
    @adminCloseConversationTime INT = NULL,
    @ConexionInfo VARCHAR(400) = NULL,
    @allowFileAttachments BIT = NULL,
    @selectRotativeANI int = null,
    @messagingOrder bit = null,
    @autoStart bit = null,
    @recordHold bit = null,
    @userId                SMALLINT     = NULL,
    @idArea                SMALLINT     = NULL,
    @isCreating            SMALLINT          = NULL,
    @camCanceled int = null,
    @recordIvr bit = null,
    @module INT = -1,
    @maxLimitQueueConversations SMALLINT = NULL,
    @maxDaysPerWAConvo SMALLINT = NULL,
	@rotativeAlgorithmManual smallint = null,
	@idAniListManual smallint = NULL,
	@selectRotationManualDialing BIT = NULL
    as
    set nocount ON

    IF EXISTS (SELECT 1 FROM ccCamps WHERE cam_descripcion = @cam_descripcion AND cam_id <> @cam_id)
    BEGIN
        SELECT -1 -- Nombre ya esta en uso
        RETURN(0)
    END

    DECLARE @timesDiscardActual int = -1, @camCanceledActual int = -1, @recordIvrActual int = -1
    SELECT @timesDiscardActual = timesDiscard, @camCanceledActual = camcanceled, @recordIvrActual = recordIvr FROM ccCamps WHERE cam_id = @cam_id
    DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)
        DECLARE @PrevName VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

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
        cam_tPreview = isnull(@cam_tPreview,cam_tPreview),
        timesDiscard = isnull(@timesDiscard, timesDiscard),
        CampType = (CASE WHEN @callsBySurvey is not null AND @ivrScript is not null THEN
                        CASE WHEN @callsBySurvey=0 and @ivrScript=0 THEN 0
                            ELSE 8
                        END
                    WHEN @CampType is not null THEN @CampType
                    WHEN @progDial = 2 THEN 6
                    WHEN @progDial IS NOT NULL AND @progDial <> 2 and @CampType is not null THEN 0
                    WHEN CampType is not null THEN CampType ELSE 0 END),
        selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
        messagingOrder = isnull(@messagingorder, messagingOrder),
        autoStart = isnull(@autoStart,autoStart),
        recordHold = isnull(@recordHold, recordHold),
        CamCanceled = ISNULL(@camCanceled, CamCanceled),
        recordIvr = isnull(@recordIvr, recordIvr),
		rotativeAlgorithmManual = ISNULL(@rotativeAlgorithmManual, rotativeAlgorithmManual),
		idAniListManual = ISNULL(@idAniListManual, idAniListManual)
        Where cam_id = @cam_id

            IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

            Create table #ccCampsTable
            (
                columnInfo VARCHAR(255),
                dataInfo VARCHAR(255),
                identifierInfo VARCHAR(255)
            )

            DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN
                                                                        CASE
                                                                            WHEN @Camptype = 6  THEN 44
                                                                            WHEN @Camptype = 5  THEN 46
                                                                            WHEN @Camptype IN(4, 9, 10)  THEN 48
                                                                            WHEN @Camptype = 7  THEN 50
                                                                            ELSE 42 END
                                                                    ELSE
                                                                        CASE
                                                                            WHEN @Camptype = 6  THEN 55
                                                                            WHEN @Camptype = 5  THEN 56
                                                                            WHEN @Camptype IN(4, 9, 10)  THEN 57
                                                                            WHEN @Camptype = 7  THEN 58
                                                                            ELSE 54 END
                                                                    END;

            IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

            IF(@isCreating = 1)
            BEGIN
                DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
                IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''camCanceled'') and dataInfo = 4) DELETE FROM #ccCampsTable WHERE columnInfo IN (''camCanceled'');
                IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''recordIvr'') and dataInfo = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''recordIvr'');
		        DELETE FROM #ccCampsTable WHERE identifierInfo =''OUT_ANI_MODE_MANUAL'' and dataInfo NOT IN (0,1,2,3); 
            END

            IF(@isCreating = 2)
            BEGIN
                IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''recordIvr'') and dataInfo = 1) AND @recordIvrActual is null DELETE FROM #ccCampsTable WHERE columnInfo IN (''recordIvr'');
                IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''camCanceled'') and dataInfo = 4) and @camCanceledActual is null DELETE FROM #ccCampsTable WHERE columnInfo IN (''camCanceled'');
            END

            DELETE FROM #ccCampsTable WHERE columnInfo IN (''startStopRecording'');
            DELETE FROM #ccCampsTable WHERE dataInfo = '''''''';

            IF(@CampType = 6) DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'', ''cam_fDialOnWU'', ''ProgDial'');
            ELSE IF(@CampType = 5 AND @isCreating = 2) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'', ''cam_descripcion'', ''exitAssisted'');
            ELSE IF(@CampType = 5) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'');
            ELSE IF(@CampType = 7) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''messagingOrder'', ''autoStart'', ''rotativeAlgo'', ''id_anilist'', ''cam_descripcion'');
            ELSE IF(@CampType = 9) DELETE FROM #ccCampsTable WHERE columnInfo IN (''timeZoneRule'', ''CampType'');
            ELSE DELETE FROM #ccCampsTable WHERE columnInfo IN (''previewDiscard'', ''CampType'', ''cam_fDialOnWU'', ''ProgDial'');

            IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            SELECT
                (SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
                getDate(),
                (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
                @operation,
                @module,
                CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> ''''
                    THEN
                        CASE
                            WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN
                                CASE WHEN @isCreating = 1 THEN '''' ELSE CCCT.identifierInfo END
                            WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN
                                CASE WHEN @CampType = 5 THEN ''OUT_WHATS_EXIT_ASSISTED'' ELSE CCCT.identifierInfo END
                            WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
                                CASE WHEN @Camptype = 5 THEN ''OUT_MANUAL_DIALING_WHATS'' ELSE CCCT.identifierInfo END
                            ELSE
                                CCCT.identifierInfo
                            END
                    ELSE
                    ''''
                    END,
                CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
                    CASE
                        WHEN CCCT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
                            CASE WHEN CCCT.dataInfo = ''VOICEMAIL''
                                THEN ''COMMON_VOICE_MAIL''
                                ELSE
                                    CASE WHEN CCCT.dataInfo IS NOT NULL THEN CCCT.dataInfo ELSE ''T&COMMON_NONE'' END
                                END
                        WHEN CCCT.identifierInfo = ''OUT_DIALING_ORDER'' THEN
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_DESCENDING'' ELSE ''COMMON_ASCENDING'' END

                        WHEN CCCT.identifierInfo = ''OUT_SMS_MESSAGING_ORDER'' THEN
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ASCENDING'' ELSE ''COMMON_DESCENDING'' END

                        WHEN CCCT.identifierInfo = ''OUT_ANSWER_MACHINE_DETC'' THEN
                            CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_BASIC''
                                WHEN CCCT.dataInfo = 1 THEN ''COMMON_LIGHT''
                                WHEN CCCT.dataInfo = 2 THEN ''COMMON_MODERATE''
                                WHEN CCCT.dataInfo = 3 THEN ''COMMON_HIGH''
                                ELSE ''T&COMMON_NONE'' END

                        WHEN CCCT.identifierInfo in (''OUT_ANI_MODE'', ''OUT_ANI_MODE_MANUAL'') THEN
                            CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ANI_LOCAL''
                                WHEN CCCT.dataInfo = 1 THEN ''COMMON_ANI_ROTATIVE''
                                WHEN CCCT.dataInfo = 2 THEN ''COMMON_ANI_ROTATIVE_REG''
                                WHEN CCCT.dataInfo = 3 THEN ''COMMON_ANI_ROTATIVE_SMART''
                                ELSE ''T&COMMON_NONE'' END

                        WHEN CCCT.identifierInfo = ''OUT_DIALING_MODE'' THEN
                            CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_PREDICTIVE''
                                WHEN CCCT.dataInfo = 1 THEN ''COMMON_PROGRESIVE''
                                ELSE ''COMMON_ASSISTED'' END

                        WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
                            CASE WHEN  @CampType = 5 THEN
                                CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                            ELSE
                                CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_VIA_KEYPAD_LOG''
                                    WHEN CCCT.dataInfo = 2 THEN ''COMMON_VIA_CALLS_LOG''
                                    WHEN CCCT.dataInfo = 3 THEN ''COMMON_VIA_CALLS_LOG''
                                    ELSE ''T&COMMON_NONE'' END
                            END

                        WHEN CCCT.identifierInfo = ''OUT_ANI_LIST'' THEN
                                    CASE @rotativeAlgo
                                                WHEN 1 THEN
                                                    ISNULL(
                                                        (SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo),
                                                        CCCT.dataInfo
                                                    )
                                                WHEN 0 THEN
                                                    ISNULL(
                                                        (SELECT [description] FROM ccEdoAniList WHERE id_AniList = CCCT.dataInfo),
                                                        CCCT.dataInfo
                                                    )
                                                ELSE
                                                    ISNULL(
                                                        (SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = TRY_CAST(CCCT.dataInfo AS INT)),
                                                        ISNULL(
                                                            (SELECT [description] FROM ccEdoAniList WHERE id_AniList = TRY_CAST(CCCT.dataInfo AS INT)),
                                                            CCCT.dataInfo
                                                        )
                                                    )
                                    END
						WHEN CCCT.identifierInfo = ''OUT_ANI_LIST_MANUAL'' THEN
								CASE @rotativeAlgorithmManual
												WHEN 4 THEN  ''T&COMMON_NONE''
                                                WHEN 1 THEN
                                                    ISNULL(
                                                        (SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo),
                                                        CCCT.dataInfo
                                                    )
                                                WHEN 0 THEN
                                                    ISNULL(
                                                        (SELECT [description] FROM ccEdoAniList WHERE id_AniList = CCCT.dataInfo),
                                                        CCCT.dataInfo
                                                    )
                                                ELSE
                                                    ISNULL(
                                                        (SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = TRY_CAST(CCCT.dataInfo AS INT)),
                                                        ISNULL(
                                                            (SELECT [description] FROM ccEdoAniList WHERE id_AniList = TRY_CAST(CCCT.dataInfo AS INT)),
                                                            CCCT.dataInfo
                                                        )
                                                    )
                                    END
                        WHEN CCCT.identifierInfo = ''OUT_CONDUCT_SURVEY'' THEN
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
                        WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING_ON_CHAT'', ''OUT_TIME_ZONE_VALIDATION_MANUAL'', ''OUT_INTENSIVE_DIALING'', ''OUT_CALLBACK_EXCLUSIVE_AGENT'', ''OUT_VOIEMAIL_DETECTION'',
                                                    ''OUT_CALLBACK_FAILED'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'', ''OUT_EDIT_CALL_KEY'', ''OUT_STOP_RECORDING'', ''OUT_LEAVE_PRERECORDED'',
                                                    ''OUT_CONDUCT_CALLBACK_SURVEY'', ''OUT_RECEIVE_DTMF'', ''OUT_SELECT_ANI_ON_DIALING'', ''OUT_SMS_START_CAMP_AUTO'', ''OUT_RECORD_ON_HOLD'', ''OUT_LISTEN_TONE'', ''OUT_UNASSIGN_RECORDS'',
													''OUT_SELECT_ANI_MANUAL_DIALING'') THEN
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                        WHEN CCCT.identifierInfo = ''STOP_RECORDING_IVR_TRANSFER'' THEN
                            CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END

                        ELSE CCCT.dataInfo END
                ELSE '''' END,
                CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN @PrevName ELSE (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id) END
            FROM #ccCampsTable AS CCCT
            WHERE CCCT.identifierInfo IS NOT NULL;

            EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
            IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

    if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
    begin
        EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
    end

    IF @CampType = 5 BEGIN
        update ccWhatsAppNumbers set camp_id=0 where camp_id=@cam_id
        update ccMetaWhatsAppNumbers set Cam_Id=0 where Cam_Id=@cam_id

        IF(@ConexionInfo <> '''')
        BEGIN
            IF EXISTS (SELECT number FROM ccWhatsAppNumbers WHERE number = @ConexionInfo)
                UPDATE ccWhatsAppNumbers SET camp_id = @cam_id WHERE number = @ConexionInfo
            IF EXISTS (SELECT number FROM ccMetaWhatsAppNumbers WHERE number = @ConexionInfo)
                UPDATE ccMetaWhatsAppNumbers SET Cam_Id = @cam_id WHERE number = @ConexionInfo
        END
    END

    IF (@CampType IS NOT NULL AND @CampType IN (3, 5))
    BEGIN
        IF NOT EXISTS(SELECT camp_id FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id)
        BEGIN
            SELECT 0
            RETURN(0)
        END

        IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

        Create table #contactMeanOutTable
        (
            columnInfo VARCHAR(255),
            dataInfo VARCHAR(255),
            identifierInfo VARCHAR(255)
        )

        EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @cam_id, @userId= @userid

        DECLARE @PrevConexionInfo VARCHAR(MAX) = (SELECT [conexionInfo] FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id);

        set @ConexionInfo = case when  @ConexionInfo is null or @ConexionInfo in('''',''0'',''None'',''Ninguno'') then CASE WHEN @isCreating > 0 AND @PrevConexionInfo <> '''' THEN ''Ninguno'' ELSE '''' END else @ConexionInfo end
        UPDATE contactMeanOut SET conexionInfo = @ConexionInfo, ConnPass = @ConexionInfo, connUser = @ConexionInfo,
                                                closeConversationTime = CAST(@agentCloseConversationTime AS INT), answerTimeoutClient = @adminCloseConversationTime,
                                allowFileAttachments = @allowFileAttachments,
                    maxLimitQueueConversations = @maxLimitQueueConversations,
                    MaxDaysPerWAConvo = @maxDaysPerWAConvo
        WHERE @CampType = meanContactTypeId AND camp_id = @cam_id


        IF(@isCreating > 0 AND @module > -1) BEGIN
            EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';
            IF(@ConexionInfo IS NULL OR @ConexionInfo IN ('''',''0'',''None'',''Ninguno'') AND @PrevConexionInfo <> @ConexionInfo) UPDATE contactMeanOut SET conexionInfo = '''' WHERE @CampType = meanContactTypeId AND camp_id = @cam_id
        END

        DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''conexionInfo'') AND  dataInfo = '''''''';
        DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''ConnPass'', ''connUser'') ;
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
            getDate(),          (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
            @operation,
            @module,
            CMOT.identifierInfo,
            CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
                CASE
                    WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
                        CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    WHEN CMOT.identifierInfo = ''OUT_WHATS_ASSOCIATED_PHONE'' THEN
                        CASE WHEN CMOT.dataInfo = ''Ninguno'' THEN ''COMMON_NONE_O'' ELSE CMOT.dataInfo END
                    ELSE CMOT.dataInfo END
            ELSE '''' END,
            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
        FROM #contactMeanOutTable AS CMOT;

        EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid;
        IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable
    END
    DECLARE @prevCalif BIT = (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id);

    IF @cam_ShowCalifWnd = 1
    BEGIN
        IF NOT EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @cam_id and tipo = 1)
        BEGIN
            SELECT 0
            RETURN(0)
        END

        UPDATE ccCamps SET
        cam_ShowCalifWnd = ISNULL(@cam_ShowCalifWnd,cam_ShowCalifWnd)
        WHERE cam_id = @cam_id


        IF(@prevCalif <> @cam_ShowCalifWnd AND @isCreating > 0) BEGIN
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            SELECT
                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
                getDate(),
                (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
                @operation,
                3,
                ''OUT_SHOW_DISPOSITIONS'',
                CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END,
                (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
        END

        SELECT 1
        RETURN(0)
    END

    UPDATE ccCamps SET
    cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
    where cam_id = @cam_id

    IF(@prevCalif <> @cam_ShowCalifWnd AND @isCreating > 0) BEGIN
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
            getDate(),
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
            @operation,
            3,
            ''OUT_SHOW_DISPOSITIONS'',
            CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END,
            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
    END

    SELECT 2
    RETURN(0)

    set nocount off'
	EXEC(@sql)
    

    SET @process = 'ALTER sp ccsp_RIAOUTInsertNewJOBS_WT_Camp Sears mejora en el proceso de carga';
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000
AS
SET NOCOUNT ON

DECLARE @prioridad VARCHAR(8)
DECLARE @batchsizeIni AS INT
DECLARE @batchsizeFin AS INT
DECLARE @rango AS DECIMAL
DECLARE @rowstoInsert AS INT
DECLARE @campType AS INT
DECLARE @recordsQuantitySetting VARCHAR(8)
DECLARE @settingValueP1 VARCHAR(25)

SET @rowstoInsert = 0
SET @batchsizeIni = 0
SET @batchsizeFin = 0
SET @rango = 0.00

IF EXISTS(SELECT * FROM sys.views WHERE NAME = ''VIEW_SETTINGS'') BEGIN
    SELECT @recordsQuantitySetting = [valor] FROM VIEW_SETTINGS WHERE setting_id = 257;
    IF(@recordsQuantitySetting IS NOT NULL AND @recordsQuantitySetting <> '''') BEGIN
        SELECT @settingValueP1 = SUBSTRING(@recordsQuantitySetting, CHARINDEX(''|'', @recordsQuantitySetting)+1, LEN(@recordsQuantitySetting)),
                @top = (SUBSTRING(@settingValueP1, 1, CHARINDEX(''|'', @settingValueP1)-1));
    END ELSE SET @top = 3000
END ELSE SET @top = 3000

SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
FROM ccCampsPrioridadTel WITH (NOLOCK)
WHERE cam_id = @camp_id

SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id = @camp_id;

DELETE ccUploadTemporal
WHERE cam_id = @camp_id

IF(@campType = 7)
BEGIN
        CREATE TABLE #tempsmsOutSource (Id INT PRIMARY KEY identity, smsout_id INT, cam_id INT, sms_phoneNumber VARCHAR(19), sms_status TINYINT, sms_dateDial DATETIME, cal_keyw VARCHAR(40), iTimeZone INT, iTimeZone_summer INT, iTimeZone2 INT, iTimeZone_summer2 INT, iTimeZone3 INT, iTimeZone_summer3 INT, iTimeZone4 INT, iTimeZone_summer4 INT, iTimeZone5 INT, iTimeZone_summer5 INT, list_id INT, sms_dateDialEnd datetime, isSegmentLoad bit)

        CREATE NONCLUSTERED INDEX [IX_TempSMSO] ON [dbo].[#tempsmsOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

        CREATE TABLE #smsoutIdSource (smsout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #smsoutIdSource2 (smsout_id INT NOT NULL PRIMARY KEY)
        --UPDATING TABLES BEFORE LOADING
        DECLARE @date datetime = GETDATE()
        UPDATE smsOutSource SET sms_status = 2 where sms_dateDialEnd < @date and isSegmentLoad = 1
        UPDATE smsWorkingTable SET sms_status = 2 where sms_dateDialEnd < @date and isSegmentLoad = 1

        INSERT INTO #smsoutIdSource
        SELECT top(@top) sos.smsout_id
        FROM dbo.smsOutSource AS sos  WITH (INDEX (IX_smsOutSource_2), NOLOCK)
        inner join dbo.smsWorkingTable AS swt WITH (INDEX (IX_smsWorkingTable_2), NOLOCK)
        on sos.callkey = swt.cal_keyw AND sos.cam_id = swt.cam_id
        WHERE sos.cam_id = @camp_id and sos.sms_status IN (0, 7) AND swt.sms_status <= 2

        UNION

        SELECT top(@top) swt2.smsout_id
        FROM dbo.smsOutSource AS sos2 WITH (INDEX (IX_smsOutSource_2), NOLOCK)
        inner join dbo.smsWorkingTable AS swt2 (NOLOCK)on sos2.smsout_id = swt2.smsout_id
        WHERE sos2.cam_id = @camp_id AND (sos2.sms_status < 2 OR sos2.sms_status = 7)

        INSERT INTO #smsoutIdSource2
        SELECT top(@top) sos.smsout_id
        FROM dbo.smsOutSource AS sos WITH (INDEX (IX_smsOutSource_1), NOLOCK)
        WHERE sos.sms_status IN (0, 1, 7) AND cam_id = @camp_id

        INSERT #tempsmsOutSource(smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, cal_keyw, iTimeZone,
        iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4,
            iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
        SELECT TOP(@top) smsout_id, cam_id, RTRIM(LEFT(LTRIM(sms_phoneNumber + ''        '' + sms_phoneNumber2 + ''         ''
        + sms_phoneNumber3 + ''         '' + sms_phoneNumber4 + ''         '' + sms_phoneNumber5 + ''         ''), 13)) AS sms_phoneNumber,
            CASE sms_status WHEN 7 THEN 1 ELSE sms_status END sms_status, sms_dateDial, callkey,
            CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone ELSE NULL END iTimeZone,
            CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone_summer ELSE NULL END iTimeZone_summer,
            CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone2 ELSE NULL END iTimeZone2,
            CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone_summer2 ELSE NULL END iTimeZone_summer2,
            CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone3 ELSE NULL END iTimeZone3,
            CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone_summer3 ELSE NULL END iTimeZone_summer3,
            CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone4 ELSE NULL END iTimeZone4,
            CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone_summer4 ELSE NULL END iTimeZone_summer4,
            CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone5 ELSE NULL END iTimeZone5,
            CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone_summer5 ELSE
                    NULL END iTimeZone_summer5, list_id, sms_dateDialEnd, ISNULL(isSegmentLoad, 0)
        FROM dbo.smsOutSource  WITH (INDEX (IX_smsOutSource_1), NOLOCK)
        WHERE cam_id = @camp_id AND (sms_status < 2 OR sms_status = 7)

        SELECT @rowstoInsert = COUNT(*) FROM #tempsmsOutSource AS tos;


        IF EXISTS(SELECT * FROM #tempsmsOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempsmsOutSource  WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                -- Nuevos Jobs
               INSERT INTO dbo.smsWorkingTable  WITH (ROWLOCK)
                (smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, attemps, user_id,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
                SELECT t.smsout_id, t.cam_id, t.sms_phoneNumber, t.sms_status, t.sms_dateDial, 0, 0
                ,t.cal_keyw, t.iTimeZone, t.iTimeZone_summer, t.iTimeZone2, t.iTimeZone_summer2, t.iTimeZone3, t.iTimeZone_summer3
                , t.iTimeZone4, t.iTimeZone_summer4, t.iTimeZone5, t.iTimeZone_summer5, t.list_id,t.sms_dateDialEnd, t.isSegmentLoad
                FROM #tempsmsOutSource t
                WHERE id > @batchsizeIni AND id <= @batchsizeFin
                AND NOT EXISTS (
                    SELECT 1 FROM smsWorkingTable swt WHERE swt.smsout_id = t.smsout_id
                )

                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE dbo.smsOutSource
            SET sms_status = 2
            FROM dbo.smsOutSource AS sos WITH (NOLOCK), #smsoutIdSource2  cis3 WITH (NOLOCK)
            WHERE sos.smsout_id = cis3.smsout_id
        END

        DROP TABLE #smsoutIdSource

        DROP TABLE #smsoutIdSource2

        DROP TABLE #tempsmsOutSource
END
ELSE IF(@campType = 5)
BEGIN
    CREATE TABLE #tempWhatsAppOutSource (Id INT PRIMARY KEY identity, WAOut_Id INT, CallKey VARCHAR(40), camId INT, PhoneNumber VARCHAR(30), Status INT, TimeZone int, TimeZone_Summer int, List_id INT, User_id SMALLINT, dateDial DATETIME)
    CREATE NONCLUSTERED INDEX [IX_TempWAO] ON [dbo].[#tempWhatsAppOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

    CREATE TABLE #WAIdSource (WAOut_Id INT NOT NULL PRIMARY KEY)

    INSERT INTO #WAIdSource
    SELECT top(@top) cwaos.WAOut_Id
        FROM dbo.ccWhatsAppOutSource AS cwaos WITH (INDEX (IX_WASource_1), NOLOCK)
        WHERE cwaos.Status IN (0) AND cwaos.camId = @camp_id

    INSERT INTO #tempWhatsAppOutSource
    (
        WAOut_Id,
        CallKey,
        camId,
        PhoneNumber,
        Status,
        TimeZone,
        TimeZone_Summer,
        List_id,
        User_id,
        dateDial
    )
        SELECT TOP(@top) cwaos.WAOut_Id, cwaos.CallKey,cwaos.camId, RTRIM(LEFT(LTRIM(cwaos.PhoneNumber + ''        '' ), 13)) AS phoneNumber,
            cwaos.Status AS WAStatus,
            CASE WHEN cwaos.TimeZone = 0 THEN  dbo.fnGetTimeZone(cwaos.PhoneNumber,0) ELSE cwaos.TimeZone END,
            CASE WHEN cwaos.TimeZone_Summer = 0 THEN  dbo.fnGetTimeZone(cwaos.PhoneNumber,1) ELSE cwaos.TimeZone_Summer END,
            list_id, cwaos.User_id, cwaos.dateDial
        FROM dbo.ccWhatsAppOutSource AS cwaos  WITH (INDEX (IX_WASource_1), NOLOCK)
        WHERE cwaos.camId = @camp_id AND (cwaos.Status = 0)

    SELECT @rowstoInsert = COUNT(*) FROM #tempWhatsAppOutSource AS tos;

        IF EXISTS(SELECT * FROM #tempWhatsAppOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempWhatsAppOutSource  WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                -- Nuevos Jobs
                INSERT INTO dbo.ccoWAWorkingTable(WAOut_id, PhoneNumber, Callkey, CamId, WaStatus, dateDial, UserId,TimeZone, TimeZone_Summer)
                SELECT WAOut_Id, PhoneNumber, CallKey, camId, Status, dateDial , User_id, TimeZone ,TimeZone_Summer
                FROM #tempWhatsAppOutSource
                WHERE id > @batchsizeIni AND id <= @batchsizeFin

                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE dbo.ccWhatsAppOutSource
            SET
            Status = 2,
            TimeZone = cis3.TimeZone,
            TimeZone_Summer = cis3.TimeZone_Summer
            FROM dbo.ccWhatsAppOutSource AS cwaos  WITH (NOLOCK), #tempWhatsAppOutSource  cis3 WITH (NOLOCK)
            WHERE cwaos.WAOut_Id = cis3.WAOut_Id
        END

        DROP TABLE #WAIdSource

        DROP TABLE #tempWhatsAppOutSource
END
ELSE
BEGIN
        CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19),
        cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(40), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT,
        iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT,
        iZonaHoraria_verano5 INT, list_id INT, new_status int)

        CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

        CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

        INSERT INTO #calloutIdSource
        SELECT top(@top) cs.callout_id
        FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
        inner join ccoWorkingTable wt WITH (INDEX (PK_ccoWorkingTable), NOLOCK)
        on cs.callout_id = wt.callout_id AND cs.cam_id = wt.cam_id
        WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

        UNION

        SELECT top(@top) Cout.callout_id
        FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK)
        inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id
        AND cout.cam_id = Wtab.cam_id
        WHERE Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)


        INSERT INTO #calloutIdSource2
        SELECT top(@top) callout_id
        FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_11), NOLOCK)
        WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

        IF exists(SELECT * FROM #calloutIdSource)
        BEGIN
            UPDATE ccoCallBacks
            SET [status] = 6, schedulerStatus = 1
            WHERE callout_id IN (
                    SELECT callout_id
                    FROM #calloutIdSource cis
                    )

            UPDATE ccoCallsOutSource
            SET cal_Status = 4
            WHERE callout_id IN (
                    SELECT callout_id
                    FROM #calloutIdSource cis
                    )
        END

        INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria,
        iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
            iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
        SELECT TOP(@top) callout_id, cam_id, CASE WHEN ISNULL(recycleType, 1) = 0 THEN
        CASE
            WHEN recyclePhone = 1 THEN cal_telefono
            WHEN recyclePhone = 2 THEN cal_telefono2
            WHEN recyclePhone = 3 THEN cal_telefono3
            WHEN recyclePhone = 4 THEN cal_telefono4
            else cal_telefono5
        END
        ELSE rtrim(left(ltrim(cal_telefono + ''        '' + cal_telefono2 + ''         ''
            + cal_telefono3 + ''         '' + cal_telefono4 + ''         '' + cal_telefono5 + ''         ''), 13))
        END AS cal_telefono,
            CASE cal_status WHEN 7 THEN 1 ELSE cal_status END cal_status, cal_fechaDial, cal_key,
            CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria ELSE NULL END iZonaHoraria,
            CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano,
            CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria2 ELSE NULL END iZonaHoraria2,
            CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2,
            CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria3 ELSE NULL END iZonaHoraria3,
            CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
            CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria4 ELSE NULL END iZonaHoraria4,
            CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4,
            CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria5 ELSE NULL END iZonaHoraria5,
            CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE
                    NULL END iZonaHoraria_verano5, list_id
        FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
        WHERE cam_id = @camp_id AND (cal_status < 2 OR cal_status = 7) /*AND CONVERT(VARCHAR(10),cal_fechaDial, 103) >= CONVERT(VARCHAR(10), GETDATE(), 103)*/

		--Se elimina de workingtable en caso de que no se hayan borrado correctamente no genere error al insertar nuevos registros
		DELETE wt FROM ccoWorkingTable wt
		INNER JOIN #tempCallsOutSource tcs on wt.callout_id = tcs.callout_id
		WHERE wt.cam_id = @camp_id

        SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

        IF EXISTS(SELECT * FROM #tempCallsOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempCallsOutSource WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                -- Nuevos Jobs
                 INSERT INTO ccoWorkingTable  WITH (ROWLOCK)
                (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
                SELECT t.callout_id, t.cam_id, t.cal_telefono, t.cal_status, t.cal_fechaDial, t.cal_keyw,
                       t.iZonaHoraria, t.iZonaHoraria_verano, t.iZonaHoraria2, t.iZonaHoraria_verano2,
                       t.iZonaHoraria3, t.iZonaHoraria_verano3, t.iZonaHoraria4, t.iZonaHoraria_verano4,
                       t.iZonaHoraria5, t.iZonaHoraria_verano5, t.list_id
                FROM #tempCallsOutSource t
                WHERE t.id > @batchsizeIni AND t.id <= @batchsizeFin
                  AND NOT EXISTS (
                    SELECT 1 FROM ccoWorkingTable w WHERE w.callout_id = t.callout_id
                );


                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE ccoCallsOutSource
            SET cal_status = 2, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
            FROM ccoCallsOutSource co WITH (NOLOCK), #calloutIdSource2 cis3 WITH (NOLOCK)
            WHERE co.callout_id = cis3.callout_id
        END

        DROP TABLE #calloutIdSource

        DROP TABLE #calloutIdSource2

        DROP TABLE #tempCallsOutSource
END

UPDATE ccCampsNvosCB
SET dateUpdate = NULL
WHERE id = @camp_id

SET NOCOUNT OFF';
    EXEC(@sql);

    
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
