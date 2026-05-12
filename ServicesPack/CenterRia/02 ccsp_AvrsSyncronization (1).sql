USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_AvrsSyncronization]    Script Date: 18/03/2026 09:19:52 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccsp_AvrsSyncronization]
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
            ISNULL(dni.dni_numero, '') AS DNIS,
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
            '' AS DNIS,
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
    inner join dbo.fn_RIASplitDelimited(@ids,',') t on A.id=t.Value

END
END;
