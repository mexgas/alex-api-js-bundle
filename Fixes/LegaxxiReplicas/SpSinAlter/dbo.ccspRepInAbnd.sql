ALTER PROCEDURE [dbo].[ccspRepInAbnd]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()
		
	declare @number int	
	
	CREATE TABLE #times(
      [ID] INT primary key,
      [Start] DATETIME,
      [Stop] DATETIME
      )
 
      create nonclustered index ix_times on #times(
      [Start] DESC,
      [Stop] DESC
      )
      create nonclustered index ix_times2 on #times([Start] DESC)
 
	select @number = 0
    while @number <= (datediff(mi,@from,@to)/15)
    begin
		insert into #times
		SELECT [Hour] = @number,
		StartTime = DATEADD(mi, @number*15, @from),
		EndTime = DATEADD(mi, (@number+1)*15, @from)
		set @number = @number +1
    end

	SELECT [date], areaId, CAST('' as varchar(50)) area, 0 workgroupId, CAST('' as varchar(50)) workgroup, inbound_id, isnull(inbound,'') inbound, amount, time_max,
		time_tot, LT10, LT20, LT30, LT40, LT50, LT60, LT120, LT180, LT240, LT300, GT300, [year], [month], [day], [hour], [minutes]
	INTO #AbndData
	FROM
	(SELECT timegroup [date]
		, IDArea areaId
		, xCalls.inbound_id, descripcion inbound
		, COUNT(cal_inicio) AS amount
		, MAX(tAbnd) AS time_max
		, SUM(tAbnd) AS time_tot
		, COUNT(CASE WHEN tAbnd < 10  THEN 1 ELSE NULL END) as [LT10]
		, COUNT(CASE WHEN tAbnd BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [LT20]
		, COUNT(CASE WHEN tAbnd BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [LT30]
		, COUNT(CASE WHEN tAbnd BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [LT40]
		, COUNT(CASE WHEN tAbnd BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [LT50]
		, COUNT(CASE WHEN tAbnd BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [LT60]
		, COUNT(CASE WHEN tAbnd BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [LT120]
		, COUNT(CASE WHEN tAbnd BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [LT180]
		, COUNT(CASE WHEN tAbnd BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [LT240]
		, COUNT(CASE WHEN tAbnd BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [LT300]
		, COUNT(CASE WHEN tAbnd >= 300  THEN 1 ELSE NULL END) as [GT300]
		, datepart(yyyy,timegroup) [year], datepart(mm,timegroup) [month], datepart(dd,timegroup) [day]
		, datepart(hh,timegroup) [hour], datepart(mi,timegroup) [minutes]
	 FROM	(
			SELECT start timegroup
				, cal_inicio
				, inbound_id				
				, statuscall_id
				, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,'1900-01-01 00:00:00') = '1900-01-01 00:00:00'))  THEN 1 ELSE NULL END) AS abnd 
				, (cal_twait + cal_txfer + cal_tring) AS tAbnd
			 FROM ccCallsIn ci with(nolock)
				JOIN #times th on cal_inicio between Start and [Stop]
				WHERE cal_inicio >= @from AND  cal_inicio < @to
				AND INBOUND_ID > 0
		) xCalls left join ccInbound Ib ON Ib.inbound_id=xCalls.inbound_id 
	WHERE (abnd IS NOT NULL) 
	GROUP BY timegroup, IDArea, xCalls.inbound_id, descripcion) Rep
	
	update #AbndData set
	[workgroupId] = b.idwg
	from #AbndData a, ccInboundAgentes b
	where a.inbound_id = b.inbound_id

	update #AbndData
	set workgroup = wgname, area = areaname
	from #AbndData a, ccriacat_workgroup b, ccriacat_areas c
	where a.[workgroupId] = b.idwg
	and a.areaId = c.idarea

	delete [RepInAbnd] with(rowlock)
	where [date] between @from and @to
	
	insert [RepInAbnd] select * from #AbndData
end