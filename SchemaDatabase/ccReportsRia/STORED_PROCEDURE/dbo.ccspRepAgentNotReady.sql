CREATE PROCEDURE [dbo].[ccspRepAgentNotReady]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS


if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
		
	
IF OBJECT_ID('tempdb..#notReady') IS NOT NULL
	DROP TABLE #notReady

IF OBJECT_ID('tempdb..#notReady2') IS NOT NULL
	DROP TABLE #notReady2;

WITH notReadyDetail
AS (
	SELECT user_id userId, DATEADD(s, - tstatus, fecha) AS startDate, fecha endDate, tStatus, separado, TipoNotReady_id AS TipoNotReadyId, convert(DATETIME, convert(VARCHAR(13), DATEADD(ss, - tStatus, fecha), 121) + ':00:00'
			, 121) AS timegroup, convert(DATETIME, convert(VARCHAR(13), dateadd(hh, 1, fecha), 121) + ':00:00', 121) AS timegroup_next
	FROM ccLogAgentesNotReady
	WHERE fecha BETWEEN @from
			AND @to
	)
--TmpSessionTimeGroup
SELECT timegroup, timegroup_next, userId, TipoNotReadyId, tStatus AS [time], startDate, endDate, 1 AS [count]
INTO #notReady
FROM notReadyDetail

SELECT *
INTO #notReady2
FROM #notReady
WHERE DATEDIFF(hh, timegroup, timegroup_next) > 1

DELETE #notReady
WHERE datediff(HH, timegroup, timegroup_next) > 1	
	;

	
	--Delete tepetidos
	delete from RepAgentNotReady with(rowlock) 	where date >= @from AND date < @to;
	

WITH timebyHour
AS (
	SELECT convert(DATETIME, convert(VARCHAR(13), Start, 121) + ':00:00', 121) AS [start], convert(DATETIME, convert(VARCHAR(13), dateadd(hh, 1, Start), 121) + ':00:00', 121) AS [stop]
	FROM TmpTimesInterval
	GROUP BY convert(VARCHAR(13), Start, 121), convert(DATETIME, convert(VARCHAR(13), dateadd(hh, 1, Start), 121) + ':00:00', 121)
	), notReadybyHour
AS (
	SELECT th.start AS timegroup, th.stop AS timegroup_next, userId, TipoNotReadyId, dbo.TimeInterval(th.start, th.stop, startDate, endDate) AS [time], startDate, endDate, dbo.AccountInterval(th.start, th.stop, 
			startDate, endDate, [count]) AS [count]
	FROM #notReady2 t
	INNER JOIN timebyHour th
		ON (
				t.timegroup > th.Start
				AND t.timegroup < th.stop
				)
			OR th.Start BETWEEN t.timegroup
				AND t.timegroup_next
	WHERE datediff(ss, th.start, timegroup_next) > 0
	
	UNION
	
	SELECT *
	FROM #notReady
	), timeSessionByHour
AS (
	SELECT convert(DATETIME, convert(VARCHAR(13), timegroup, 121) + ':00:00', 121) AS timegroup, user_id AS userId, sum(tlog) AS tlog
	FROM TmpSessionTimeGroup
	GROUP BY convert(DATETIME, convert(VARCHAR(13), timegroup, 121) + ':00:00', 121), user_id
	), notReadyGroupbyHour
AS (
	SELECT timegroup, timegroup_next, userId, TipoNotReadyId, sum([time]) AS [time], min(startDate) startDate, max(endDate) endDate, sum([count]) [count]
	FROM notReadybyHour
	GROUP BY timegroup, timegroup_next, userId, TipoNotReadyId
	)

insert into RepAgentNotReady
SELECT A.timegroup, userView.[Login]
, A.userId, userView.apellidopaterno + ' ' + userView.apellidomaterno + ' ' + userView.nombres AS [user]
, A.tlog AS sessionTime
, isnull(notReady.TipoNotReadyId,0) as TipoNotReadyId, isnull(d.descripcion, '') 
	descripcion, isnull(d.descripcion, '') + '_Count' AS descripcion_count, isnull(notReady.[count], 0) [count], isnull(d.descripcion, '') + '_Time' AS descripcion_time, isnull(notReady.TIME, 0) AS [time], isnull(
		notReady.TIME, 0) AS timeSeconds
		,datepart(yyyy,A.timegroup) as [year]
		,datepart(HH,A.timegroup) as [mount]
		,datepart(MM,A.timegroup) as [day]
		,datepart(mi,A.timegroup) as [hour]
		,0 as minute
FROM timeSessionByHour A
INNER JOIN ccUserView userView
	ON A.userId = userView.User_id
LEFT JOIN notReadyGroupbyHour notReady
	ON notReady.userId = A.userId
		AND A.timegroup = notReady.timegroup
LEFT JOIN ccTipoNotReady d
	ON notReady.TipoNotReadyId = d.TipoNotReady_id

IF OBJECT_ID('tempdb..#notReady') IS NOT NULL
	DROP TABLE #notReady

IF OBJECT_ID('tempdb..#notReady2') IS NOT NULL
	DROP TABLE #notReady2


	
end