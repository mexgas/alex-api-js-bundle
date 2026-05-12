-- TT#7675 Create a new procedure for implements get notReady catalog to multiple agents 
USE CCenterRIA;
go

CREATE PROCEDURE ccsp_GetCommonNotReadyStates
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
    FROM dbo.fn_RIASplitDelimited(@agentIds, ',')
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
            WHEN MIN(NumEvents) = 'n' OR MIN(NumEvents) > 0 THEN 1
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

END