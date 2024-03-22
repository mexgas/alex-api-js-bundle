ALTER PROCEDURE [dbo].[ccspRepInAnsw]
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
	DECLARE @tresDialog AS smallint
	EXEC @tresDialog = ccspConfigTresDialog
	
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
	INTO #AnswData
	FROM
	(SELECT timegroup [date]
		, IDArea areaId
		, xCalls.inbound_id, descripcion inbound
		, COUNT(cal_inicio) AS amount
		, MAX(tAnsw) AS time_max
		, SUM(tAnsw) AS time_tot
		, COUNT(CASE WHEN tAnsw < 10  THEN 1 ELSE NULL END) as [LT10]
		, COUNT(CASE WHEN tAnsw BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [LT20]
		, COUNT(CASE WHEN tAnsw BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [LT30]
		, COUNT(CASE WHEN tAnsw BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [LT40]
		, COUNT(CASE WHEN tAnsw BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [LT50]
		, COUNT(CASE WHEN tAnsw BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [LT60]
		, COUNT(CASE WHEN tAnsw BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [LT120]
		, COUNT(CASE WHEN tAnsw BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [LT180]
		, COUNT(CASE WHEN tAnsw BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [LT240]
		, COUNT(CASE WHEN tAnsw BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [LT300]
		, COUNT(CASE WHEN tAnsw >= 300  THEN 1 ELSE NULL END) as [GT300]
		, datepart(yyyy,timegroup) [year], datepart(mm,timegroup) [month], datepart(dd,timegroup) [day]
		, datepart(hh,timegroup) [hour], datepart(mi,timegroup) [minutes]
	 FROM	(
			SELECT start timegroup
				, cal_inicio
				, inbound_id				
				, statuscall_id
				, (CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
				, (cal_twait + cal_txfer + cal_tring) AS tAnsw
			 FROM ccCallsIn ci with(nolock)
				JOIN #times th on cal_inicio between Start and [Stop]
				WHERE cal_inicio >= @from AND  cal_inicio < @to
				AND INBOUND_ID > 0
		) xCalls left join ccInbound Ib ON Ib.inbound_id=xCalls.inbound_id 
	WHERE (answer IS NOT NULL) 
	GROUP BY timegroup, IDArea, xCalls.inbound_id, descripcion) Rep
	
	update #AnswData set
	[workgroupId] = b.idwg
	from #AnswData a, ccInboundAgentes b
	where a.inbound_id = b.inbound_id

	update #AnswData
	set workgroup = wgname, area = areaname
	from #AnswData a, ccriacat_workgroup b, ccriacat_areas c
	where a.[workgroupId] = b.idwg
	and a.areaId = c.idarea

	delete [RepInAnsw] with(rowlock)
	where [date] between @from and @to
	
	insert [RepInAnsw] select * from #AnswData
end