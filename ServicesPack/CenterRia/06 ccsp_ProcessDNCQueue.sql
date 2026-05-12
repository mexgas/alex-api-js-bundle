USE [CCenterRIA]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[ccsp_ProcessDNCQueue]
    @BatchSize INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LockResult INT;

    EXEC @LockResult = sp_getapplock
        @Resource = 'dbo.ccsp_ProcessDNCQueue',
        @LockMode = 'Exclusive',
        @LockOwner = 'Session',
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

        IF OBJECT_ID('tempdb..#QueueBatch') IS NOT NULL DROP TABLE #QueueBatch;
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
                @Resource = 'dbo.ccsp_ProcessDNCQueue',
                @LockOwner = 'Session';
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

        IF OBJECT_ID('tempdb..#mycamps') IS NOT NULL DROP TABLE #mycamps;
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

        IF OBJECT_ID('tempdb..#AffectedCalls') IS NOT NULL DROP TABLE #AffectedCalls;
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

        IF OBJECT_ID('tempdb..#ToRemove') IS NOT NULL DROP TABLE #ToRemove;
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
        WHERE ISNULL(v.tel, '') <> ''
          AND v.tel = b.telefono;

        /* Limpia solo la posicion encontrada */
        UPDATE cs
           SET cs.cal_telefono = '',
               cs.iZonaHoraria = 0,
               cs.iZonaHoraria_verano = 0
        FROM dbo.ccoCallsOutSource cs
        INNER JOIN #ToRemove r
            ON r.callout_id = cs.callout_id
           AND r.pos = 1
        WHERE cs.cal_telefono = r.telefono;       
        
        UPDATE cs
           SET cs.cal_telefono2 = '',
               cs.iZonaHoraria2 = 0,
               cs.iZonaHoraria_verano2 = 0
        FROM dbo.ccoCallsOutSource cs
        INNER JOIN #ToRemove r
            ON r.callout_id = cs.callout_id
           AND r.pos = 2
        WHERE cs.cal_telefono2 = r.telefono;  

        UPDATE cs
           SET cs.cal_telefono3 = '',
               cs.iZonaHoraria3 = 0,
               cs.iZonaHoraria_verano3 = 0
        FROM dbo.ccoCallsOutSource cs
        INNER JOIN #ToRemove r
            ON r.callout_id = cs.callout_id
           AND r.pos = 3
        WHERE cs.cal_telefono3 = r.telefono; 

        UPDATE cs
           SET cs.cal_telefono4 = '',
               cs.iZonaHoraria4 = 0,
               cs.iZonaHoraria_verano4 = 0
        FROM dbo.ccoCallsOutSource cs
        INNER JOIN #ToRemove r
            ON r.callout_id = cs.callout_id
           AND r.pos = 4
        WHERE cs.cal_telefono4 = r.telefono;

        UPDATE cs
           SET cs.cal_telefono5 = '',
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
        WHERE NULLIF(cs.cal_telefono, '') IS NULL
          AND NULLIF(cs.cal_telefono2, '') IS NULL
          AND NULLIF(cs.cal_telefono3, '') IS NULL
          AND NULLIF(cs.cal_telefono4, '') IS NULL
          AND NULLIF(cs.cal_telefono5, '') IS NULL;


        UPDATE wt
        SET wt.cal_telefono = COALESCE(
                NULLIF(cs.cal_telefono,''),
                NULLIF(cs.cal_telefono2,''),
                NULLIF(cs.cal_telefono3,''),
                NULLIF(cs.cal_telefono4,''),
                NULLIF(cs.cal_telefono5,''),
                ''
            ),
            wt.iZonaHoraria = CASE WHEN NULLIF(cs.cal_telefono,'') IS NULL THEN NULL ELSE cs.iZonaHoraria END,
            wt.iZonaHoraria_verano = CASE WHEN NULLIF(cs.cal_telefono,'') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano END,
            wt.iZonaHoraria2 = CASE WHEN NULLIF(cs.cal_telefono2,'') IS NULL THEN NULL ELSE cs.iZonaHoraria2 END,
            wt.iZonaHoraria_verano2 = CASE WHEN NULLIF(cs.cal_telefono2,'') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano2 END,
            wt.iZonaHoraria3 = CASE WHEN NULLIF(cs.cal_telefono3,'') IS NULL THEN NULL ELSE cs.iZonaHoraria3 END,
            wt.iZonaHoraria_verano3 = CASE WHEN NULLIF(cs.cal_telefono3,'') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano3 END,
            wt.iZonaHoraria4 = CASE WHEN NULLIF(cs.cal_telefono4,'') IS NULL THEN NULL ELSE cs.iZonaHoraria4 END,
            wt.iZonaHoraria_verano4 = CASE WHEN NULLIF(cs.cal_telefono4,'') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano4 END,
            wt.iZonaHoraria5 = CASE WHEN NULLIF(cs.cal_telefono5,'') IS NULL THEN NULL ELSE cs.iZonaHoraria5 END,
            wt.iZonaHoraria_verano5 = CASE WHEN NULLIF(cs.cal_telefono5,'') IS NULL THEN NULL ELSE cs.iZonaHoraria_verano5 END
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
            @Resource = 'dbo.ccsp_ProcessDNCQueue',
            @LockOwner = 'Session';

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

        IF OBJECT_ID('tempdb..#ToRemove') IS NOT NULL DROP TABLE #ToRemove;
        IF OBJECT_ID('tempdb..#AffectedCalls') IS NOT NULL DROP TABLE #AffectedCalls;
        IF OBJECT_ID('tempdb..#mycamps') IS NOT NULL DROP TABLE #mycamps;
        IF OBJECT_ID('tempdb..#QueueBatch') IS NOT NULL DROP TABLE #QueueBatch;

        EXEC sp_releaseapplock
            @Resource = 'dbo.ccsp_ProcessDNCQueue',
            @LockOwner = 'Session';

        THROW;
    END CATCH
END
GO