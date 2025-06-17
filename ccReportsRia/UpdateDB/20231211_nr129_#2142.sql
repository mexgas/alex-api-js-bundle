/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCReportsRIA
Required version: 128

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
SET @version = 129 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	---------------------------------------BEGIN Marco García #2142---------------------------------------------------------


     set @process = '#2142 Alter SP ccspTimesccLogAgentesDia se modifica para poner @maxID en la línea 161 - 177'
    set @sql='ALTER PROCEDURE [dbo].[ccspTimesccLogAgentesDia] @from AS SMALLDATETIME, @to AS SMALLDATETIME -- Se realizó cambio para el ticket #2142
AS
SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia2'', N''U'') IS NOT NULL Begin
    DROP TABLE #tempccLogAgentesDia2
End

TRUNCATE TABLE tmpccLogAgentesDia

IF not EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_tmpccLogAgentesDia_TipoStatusAge_id'')   Begin
    CREATE NONCLUSTERED INDEX [IX_tmpccLogAgentesDia_TipoStatusAge_id]
    ON [dbo].[tmpccLogAgentesDia] ([TipoStatusAge_id])
    INCLUDE ([tStatus],[timeGroupNext])
end

CREATE TABLE #tempccLogAgentesDia2 (
    rowId INT NOT NULL
    ,userId INT NOT NULL
    ,TipoStatusAge_id TINYINT NOT NULL
    ,tStatus FLOAT NOT NULL
    ,dateIni DATETIME NOT NULL
    ,dateEnd DATETIME NOT NULL
    ,currentStatus INT
    ,timeGroup DATETIME NOT NULL
    ,timeGroupNext DATETIME NOT NULL
    ,camId SMALLINT
    ,camType SMALLINT
    ,callId INT
    );

WITH tmpLog
AS (
    SELECT User_id AS userId
        ,TipoStatusAge_id
        ,tStatus
        ,DATEADD(ms, - tStatus*1000, fecha) dateIni
        ,fecha dateEnd
        ,ISNULL(currentStatus, 0) AS currentStatus
        ,dbo.GetTimeGroup(DATEADD(ms, - tStatus*1000, fecha), 0) AS timegroup
        ,dbo.GetTimeGroup(fecha, 1) AS timegroup_next
        ,IdCampEsp AS camId
        ,Tipo AS camType
        ,callId
    FROM ccLogAgentesDia with(nolock,index(IX_ccLogAgentesDia_6))
    WHERE DATEADD(ss, - tStatus, fecha) BETWEEN @from AND @to   
    )
, cteLogAgentesDia as (

SELECT ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId
    ,userId
    ,TipoStatusAge_id
    ,tStatus
    ,dateIni
    ,dateEnd
    ,currentStatus
    ,timegroup
    ,timegroup_next
    ,camId
    ,camType
    ,callId
FROM tmpLog
)
insert into tmpccLogAgentesDia
select * from cteLogAgentesDia

/***** Elimina los repetidos ******/
; with regDeleteRepLogout as(
SELECT 
    case when A.dateIni<S.dateIni or A.currentStatus<0 then S.id else A.Id end [rowId]  
    , A.userId      
    FROM tmpccLogAgentesDia A
    LEFT JOIN tmpccLogAgentesDia S ON A.Id = S.Id - 1
        AND A.userId = S.userId
    WHERE A.tStatus >0 and S.tStatus >0
        AND A.TipoStatusAge_id = S.TipoStatusAge_id
        AND A.TipoStatusAge_id>0    
        and (A.dateEnd between S.dateIni and S.dateEnd
        or S.dateEnd between A.dateIni and A.dateEnd
        )
        and ABS( A.tStatus-S.tStatus)<=2
),
rowReconnectLogout as(
select ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId,* 
from tmpccLogAgentesDia where currentStatus in(30,-2) and tStatus>0
)
,
regDeleteReconnect as( 
 select 
case when A.currentStatus=-2 then S.Id else A.Id end [rowId], A.userId
--,A.userId,S.userId,A.RowId,S.RowId,A.timeGroup,S.timeGroupNext,A.id,S.id,A.TipoStatusAge_id,S.TipoStatusAge_id,A.tStatus,S.tStatus
--,A.dateIni,A.dateEnd,S.dateIni,S.dateEnd
--,ABS(A.tStatus-S.tStatus)
from rowReconnectLogout A
inner join rowReconnectLogout S on A.userId=S.userId and A.RowId=S.RowId-1 
and A.TipoStatusAge_id=S.TipoStatusAge_id 
where ( A.dateIni between S.dateIni and S.dateEnd or S.dateIni between A.dateIni and A.dateEnd)
 )
 , rowDelete as(
 select * from regDeleteRepLogout
 union 
 select * from regDeleteReconnect
 )

            
--SELECT A.*
Delete A
from tmpccLogAgentesDia A
inner join rowDelete X  ON A.id = x.rowId AND A.userId = x.userId;

/***** Revisa si es el dia actual para calcular el tiempo del estado ******/
declare @today date,@dateNow datetime
SET @today = convert(DATE, GETDATE(), 121)
SET @dateNow=GETDATE()


declare @maxId int

select @maxId =isnull(max(id),0)+1 from tmpccLogAgentesDia

IF @today = CONVERT(DATE, @to, 121)
BEGIN
    ;   
    WITH tmpAgentLastStatus
    AS (
        SELECT userId ,MAX(dateEnd) AS dateStart
        FROM tmpccLogAgentesDia
        WHERE dateEnd BETWEEN @today AND @to
        GROUP BY userId
        )           

   INSERT INTO tmpccLogAgentesDia
     SELECT @maxId+ ROW_NUMBER() OVER (PARTITION BY A.userId ORDER BY B.dateStart) AS RowId
        ,A.userId
        ,A.currentStatus
        ,DATEDIFF(ss, A.dateEnd, @dateNow) AS tStatus
        ,B.dateStart
        ,@dateNow
        ,A.currentStatus
        ,dbo.GetTimeGroup(B.dateStart, 0) AS timegroup
        ,dbo.GetTimeGroup(@dateNow, 1) AS timegroup_next
        ,A.camId
        ,A.camType
        ,A.callId
    FROM tmpccLogAgentesDia A
    INNER JOIN tmpAgentLastStatus B ON A.dateEnd = B.dateStart AND A.userId = B.userId
    WHERE A.dateIni BETWEEN @today AND @to
        AND A.currentStatus NOT IN (- 2, - 1, 0);
END


/***** Separa los estados para tenerlos en intervalos 15 minutos para algunos reportes ******/
INSERT INTO #tempccLogAgentesDia2
SELECT * FROM tmpccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15


DELETE tmpccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15;



INSERT INTO tmpccLogAgentesDia
SELECT-1* ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId
    ,t.userId
    ,TipoStatusAge_id
    ,dbo.TimeInterval(th.start, th.stop, dateIni, dateEnd) AS tStatus
    ,dateIni
    ,dateEnd
    ,currentStatus
    ,th.start AS timegroup
    ,th.stop AS timegroup_next
    ,t.camId
    ,t.camType
    ,t.callId
FROM #tempccLogAgentesDia2 t
INNER JOIN TmpTimesInterval th ON (
        t.timegroup > th.Start
        AND t.timegroup < th.stop
        )
    OR th.Start BETWEEN t.timegroup
        AND t.timeGroupNext
WHERE DATEDIFF(ss, th.start, timeGroupNext) > 0
    AND th.Start BETWEEN @from
        AND @to
order by dateIni,timegroup


IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia2'', N''U'') IS NOT NULL
    DROP TABLE #tempccLogAgentesDia2'
    EXEC(@sql)


    
---------------------------------------END Marco García #2142---------------------------------------------------------

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
