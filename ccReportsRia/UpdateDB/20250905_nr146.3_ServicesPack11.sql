/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2025/03/25
Description: ServicesPACK9

Database: CCReportsRIA
Required version: 146

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

SET NOCOUNT ON --

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
SET @version = 146 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	
    SET @process = 'CREATE CLUSTERED INDEX CIX_RepOutTrunkBusy_Date'
    SET @sql = 'IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = ''CIX_RepOutTrunkBusy_Date''
          AND object_id = OBJECT_ID(''dbo.RepOutTrunkBusy'')
    )
    BEGIN
        CREATE CLUSTERED INDEX CIX_RepOutTrunkBusy_Date
        ON dbo.RepOutTrunkBusy([date]);
    END'
    exec (@sql)

    SET @process = 'DROP INDEX IX_RepOutTrunkBusy'
    SET @sql = 'IF EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = ''IX_RepOutTrunkBusy''
          AND object_id = OBJECT_ID(''dbo.RepOutTrunkBusy'')
    )
    BEGIN
        DROP INDEX IX_RepOutTrunkBusy
        ON dbo.RepOutTrunkBusy;
    END'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepTrunkBusy] se modifica para DELETE TOP (10000) FROM dbo.RepTrunkBusy'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepTrunkBusy] @action AS TINYINT
    ,@from AS DATETIME = NULL
    ,@to AS DATETIME = NULL
AS
SET ANSI_WARNINGS OFF
SET NOCOUNT ON

IF @from IS NULL
    SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

SELECT @to = getdate()

IF @action = 1
BEGIN
    CREATE TABLE #RtnValue (
        fecha DATETIME
        ,puerto INT
        ,cam_id INT
        ,tbusy INT
        ,contador INT
        ,fechafin DATETIME
        ,timegroup DATETIME
        ,timegroupNext DATETIME
        )

    CREATE TABLE #RtnValue2 (
        fecha DATETIME
        ,puerto INT
        ,cam_id INT
        ,tbusy INT
        ,contador INT
        ,fechafin DATETIME
        ,timegroup DATETIME
        ,timegroupNext DATETIME
        );

    WITH trunkOut
    AS (
        SELECT dials.fecha
            ,dials.Puerto
            ,dials.cam_id
            ,dials.tDialing + dials.tBusy + isnull(calls.cal_tDialog + calls.cal_tXfer + calls.cal_tRing, 0) AS tBusy
            ,1 AS contador
            ,dateadd(ss, dials.tDialing + dials.tBusy + isnull(calls.cal_tDialog + calls.cal_tXfer + calls.cal_tRing, 0), dials.fecha) AS fechafin
        FROM ccologdials AS dials
        LEFT JOIN ccocallsout AS calls ON (
                dials.Puerto = calls.cal_puerto
                AND dials.cal_id = calls.cal_id
                )
        WHERE dials.fecha BETWEEN @from
                AND @to
        )
    INSERT INTO #RtnValue
    SELECT fecha
        ,puerto
        ,cam_id
        ,tBusy
        ,contador
        ,fechafin
        ,dbo.GetTimeGroup(fecha, 0) AS timegroup
        ,dbo.GetTimeGroup(fechafin, 0) AS timegroupNext
    FROM trunkOut
    WHERE tBusy > 0

    INSERT INTO #RtnValue2
    SELECT *
    FROM #RtnValue
    WHERE datediff(mi, fecha, fechafin) > 15

    DELETE #RtnValue
    WHERE datediff(mi, fecha, fechafin) > 15

    INSERT INTO #RtnValue
    SELECT t.fecha
        ,t.Puerto
        ,t.cam_id
        ,dbo.TimeInterval(th.start, th.stop, t.fecha, fechafin) AS tBusy
        ,t.contador AS llamadas
        ,fechafin
        ,th.start
        ,th.stop
    FROM #RtnValue2 t
    INNER JOIN TmpTimesInterval th ON (
            t.fecha > th.Start
            AND t.fecha < th.stop
            )
        OR th.Start BETWEEN t.fecha
            AND t.fechafin

    SELECT timegroup
        ,puerto AS [port]
        ,cam_id
        ,SUM(tBusy) tBusy
        ,sum(contador) AS llamadas
        ,1 AS tipo
    INTO #ccGenOutPortStats
    FROM #RtnValue
    GROUP BY timegroup
        ,puerto
        ,cam_id

    INSERT INTO #ccGenOutPortStats
    SELECT timegroup
        ,cal_puerto AS [port]
        ,Inbound_id AS cam_id
        ,sum(txfer + tRing + tDialog) AS tBusy
        ,count(*) llamadas
        ,0 AS tipo
    FROM tmpTimesInboundData
    GROUP BY timegroup
        ,cal_puerto
        ,Inbound_id
    HAVING sum(txfer + tRing + tDialog) > 0

    
    WHILE 1 = 1
    BEGIN
        DELETE TOP (10000)
        FROM dbo.RepInTrunkBusy
        WHERE [date] >= @from
          AND [date] < @to;

        IF @@ROWCOUNT = 0
            BREAK;
    END;    

    INSERT INTO RepInTrunkBusy
    SELECT timegroup
        ,A.cam_id
        ,[in].descripcion
        ,[port]
        ,tbusy
        ,llamadas
        ,datepart(yyyy, timegroup) AS [year]
        ,datepart(mm, timegroup) AS [month]
        ,datepart(dd, timegroup) AS [day]
        ,datepart(hh, timegroup) AS [hour]
        ,datepart(mi, timegroup) AS [minutes]
    FROM #ccGenOutPortStats A
    INNER JOIN ccInbound [in] ON [in].inbound_id = A.cam_id
        AND A.tipo = 0

    WHILE 1 = 1
    BEGIN
        DELETE TOP (10000)
        FROM dbo.RepOutTrunkBusy
        WHERE [date] >= @from
          AND [date] < @to;

        IF @@ROWCOUNT = 0
            BREAK;
    END;

    INSERT INTO RepOutTrunkBusy
    SELECT timegroup
        ,A.cam_id
        ,[out].cam_descripcion
        ,[port]
        ,tbusy
        ,llamadas
        ,datepart(yyyy, timegroup) AS [year]
        ,datepart(mm, timegroup) AS [month]
        ,datepart(dd, timegroup) AS [day]
        ,datepart(hh, timegroup) AS [hour]
        ,datepart(mi, timegroup) AS [minutes]
    FROM #ccGenOutPortStats A
    INNER JOIN cccamps [out] ON (
            [out].cam_id = A.cam_id
            AND A.tipo = 1
            )

    WHILE 1 = 1
    BEGIN
        DELETE TOP (10000)
        FROM dbo.RepTrunkBusy
        WHERE [date] >= @from
          AND [date] < @to;

        IF @@ROWCOUNT = 0
            BREAK;
    END;

    INSERT INTO RepTrunkBusy
    SELECT timegroup
        ,port
        ,tbusy
        ,llamadas
        ,datepart(yyyy, timegroup) AS [year]
        ,datepart(mm, timegroup) AS [month]
        ,datepart(dd, timegroup) AS [day]
        ,datepart(hh, timegroup) AS [hour]
        ,datepart(mi, timegroup) AS [minutes]
    FROM #ccGenOutPortStats A

    DROP TABLE #RtnValue

    DROP TABLE #RtnValue2

    DROP TABLE #ccGenOutPortStats
END

'
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


  
    	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
