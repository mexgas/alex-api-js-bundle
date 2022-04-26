CREATE PROCEDURE [dbo].[ccspTmpTimesccLogtransfers] @from AS SMALLDATETIME, @to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N'tempdb..#tempccLogtransfers', N'U') IS NOT NULL
	DROP TABLE #tempccLogtransfers
IF OBJECT_ID(N'tempdb..#tempccLogtransfers2', N'U') IS NOT NULL
	DROP TABLE #tempccLogtransfers2

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = 'TmpTimesccLogtransfers'
		)
BEGIN
	CREATE TABLE TmpTimesccLogtransfers (
	dateIni DATETIME NOT NULL, dateEnd DATETIME NOT NULL, callId INT NOT NULL, tipo TINYINT NULL, modo TINYINT NULL
	, destino VARCHAR(100) NOT NULL, tAntesXfer INT, tDespuesXfer INT	
	, timegroup DATETIME NOT NULL
	,timegroup_next DATETIME NOT NULL
	)
END
ELSE
BEGIN
	TRUNCATE TABLE TmpTimesccLogtransfers
		--drop table TmpTimesccLogtransfers
END

CREATE TABLE #tempccLogtransfers (
	dateIni DATETIME NOT NULL, dateEnd DATETIME NOT NULL, callId INT NOT NULL, tipo TINYINT NULL, modo TINYINT NULL
	, destino VARCHAR(100) NOT NULL, tAntesXfer INT, tDespuesXfer INT
	,dateStarBeforetTransf DATETIME NOT NULL	
	, timegroup DATETIME NOT NULL
	,timegroup_next DATETIME NOT NULL
	)
	;

with logtransfer as(

SELECT DATEADD(ss, - tAntesXfer - tDespuesXfer, fechaFin)as  dateIni, fechaFin  as dateEnd
	, cal_id callId, tipo, modo, destino, tAntesXfer, tDespuesXfer
	, dbo.GetTimeGroup(DATEADD(ss, - tAntesXfer - tDespuesXfer, fechaFin), 0) AS timegroup
	, dbo.GetTimeGroup(fechaFin, 1) AS timegroup_next
FROM ccLogtransfers
WHERE fechaFin BETWEEN @from		AND @to

)

INSERT INTO #tempccLogtransfers
select dateIni,dateEnd,callId, tipo, modo, destino, tAntesXfer, tDespuesXfer
,dateadd(ss,tAntesXfer,dateIni) as dateStarBeforetTransf
,timegroup,timegroup_next
from logtransfer

select * into #tempccLogtransfers2 from #tempccLogtransfers where datediff(mi,timegroup,timegroup_next)>15
delete #tempccLogtransfers where datediff(mi,timegroup,timegroup_next) > 15

insert into TmpTimesccLogtransfers
select dateIni,dateEnd,callId
	,tipo, modo, destino
	,dbo.TimeInterval(th.start, th.stop, dateIni, dateStarBeforetTransf) AS tAntesXfer
	,dbo.TimeInterval(th.start, th.stop, dateStarBeforetTransf, dateEnd) AS tDespuesXfer	
,th.start as timegroup,th.stop as timegroup_next
	from #tempccLogtransfers2 t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
union all
select dateIni,dateEnd,callId	,tipo, modo, destino,
tAntesXfer,tDespuesXfer,timegroup,timegroup_next
from #tempccLogtransfers

IF OBJECT_ID(N'tempdb..#tempccLogtransfers', N'U') IS NOT NULL
	DROP TABLE #tempccLogtransfers
IF OBJECT_ID(N'tempdb..#tempccLogtransfers2', N'U') IS NOT NULL
	DROP TABLE #tempccLogtransfers2