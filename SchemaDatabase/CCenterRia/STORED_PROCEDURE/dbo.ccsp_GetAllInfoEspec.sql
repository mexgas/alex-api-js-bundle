CREATE PROCEDURE ccsp_GetAllInfoEspec
@dia as varchar(11),
@CveCamp int
AS
--HLAS NEW VERSION 20040802
declare @LastUpdate datetime 

declare @horasSinInsert int
declare @i int
select @horasSinInsert = datediff(hh, max(fecha), getdate()) from ccAllInfoEspec

select @i = 0
while @i < @horasSinInsert begin
	INSERT ccAllInfoEspec (inbound_id, fecha) select inbound_id, dateadd(hh, datepart(hh, getdate()) - @i, convert(varchar(11), getdate(), 101)) from ccInbound
	select @i = @i + 1
end


select @LastUpdate = max(LastUpdate) from ccAllInfoEspec
if datepart(hh, @LastUpdate) <> datepart(hh, getdate()) begin
	
	update ccAllInfoEspec set
	calls = res.calls,
	Abandon = res.Abandon,
	callsQueue = res.callsQueue,
	OverFlowQueue = res.OverFlowQueue,
	OverFlowTimeOut = res.OverFlowTimeOut,
	Dialogs = res.Dialogs,
	DlgsAveTime= res.dlgsAveTime,
	Dlgs35segs = res.Dlgs35segs,
	QueueAveTime = res.QueueAveTime,
	LastUpdate = getdate()
	from ( select
		inbound_id, 
		dateadd(hh, datepart(hh, cal_inicio), convert(varchar(11), cal_inicio, 101)) as hora,
		calls = ISNULL(count(*), 0),
		abandon = isnull(COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer IS NULL))  THEN 1 ELSE NULL END), 0),
		callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0),
		OverFlowQueue = ISNULL(count (case when  statusCall_id =8 then 1 else null end), 0),
		OverFlowTimeOut = ISNULL(count (case when  statusCall_id =7 then 1 else null end), 0),
		Dialogs = ISNULL(count (case when  statusCall_id = 13 then 1 else null end), 0),
		DlgsAveTime= ISNULL(sum (case when  statusCall_id = 13 then cal_tDialog + cal_tNotas else 0 end), 0),
		Dlgs35segs =ISNULL(count (case when  statusCall_id = 13 and cal_tdialog < 35 then 1 else null end), 0),
		QueueAveTime=ISNULL( avg( case when   cal_que > 0 then cal_tWait else null end), 0) 
		from ccCallsIn
		where cal_inicio between
			@LastUpdate and 
			dateadd(hh, datepart(hh, getdate()), convert(varchar(11), getdate(), 101))		
		group by inbound_id, dateadd(hh, datepart(hh, cal_inicio), convert(varchar(11), cal_inicio, 101))
	) res
	where ccAllInfoEspec.inbound_id = res.inbound_id
	and fecha = res.hora
end
if datediff(mi, @LastUpdate, getdate()) > 1 begin
	update ccAllInfoEspec set
	calls = res.calls,
	Abandon = res.Abandon,
	callsQueue = res.callsQueue,
	OverFlowQueue = res.OverFlowQueue,
	OverFlowTimeOut = res.OverFlowTimeOut,
	Dialogs = res.Dialogs,
	DlgsAveTime= res.dlgsAveTime,
	Dlgs35segs = res.Dlgs35segs,
	QueueAveTime = res.QueueAveTime,
	LastUpdate = getdate()
	from ( select
		inbound_id, 
		dateadd(hh, datepart(hh, cal_inicio), convert(varchar(11), cal_inicio, 101)) as hora,
		calls = ISNULL(count(*), 0),
		Abandon = ISNULL(count (case when statusCall_id in (2,3,4,6) then 1 else null end), 0),
		callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0),
		OverFlowQueue = ISNULL(count (case when  statusCall_id =8 then 1 else null end), 0),
		OverFlowTimeOut = ISNULL(count (case when  statusCall_id =7 then 1 else null end), 0),
		Dialogs = ISNULL(count (case when  statusCall_id = 13 then 1 else null end), 0),
		DlgsAveTime= ISNULL(sum (case when  statusCall_id = 13 then cal_tDialog + cal_tNotas else 0 end), 0),
		Dlgs35segs =ISNULL(count (case when  statusCall_id = 13 and cal_tdialog < 35 then 1 else null end), 0),
		QueueAveTime=ISNULL( sum( case when   cal_que > 0 then cal_tWait else null end), 0) 
		from ccCallsIn
		where cal_inicio between 
			dateadd(hh, datepart(hh, getdate()), convert(varchar(11), getdate(), 101)) and
			getdate()
		group by inbound_id, dateadd(hh, datepart(hh, cal_inicio), convert(varchar(11), cal_inicio, 101))
	) res
	where ccAllInfoEspec.inbound_id = res.inbound_id
	and fecha = res.hora

end

select 'Calls'=sum(Calls), 'Abandon'=sum(abandon), 'Queue'=sum(CallsQueue), 'OFQueue'=sum(OverFlowQueue),  'OFTimeOut'=sum(OverFlowTimeOut),
	'Dialogs'=sum(Dialogs), 'Dlgs35segs'=sum(Dlgs35segs), 'DlgsAveTime'= case sum(dialogs) when 0 then 0 else sum(DlgsAveTime)/sum(Dialogs) end, 
	'QueueAveTime'=case sum(CallsQueue) when 0 then 0 else sum(QueueAveTime)/sum(callsqueue) end
	from ccAllInfoEspec where inbound_id = @CveCamp and fecha between @dia and dateadd(dd, 1, @dia)


/*
declare @fechaI as datetime, @fechaF as datetime

declare @Calls as int
declare @CallsLost as int
declare @CallsQueue as int
declare @OverFlowQueue as int
declare @OverFlowTimeOut as int

declare @Dlgs as int
declare @Dlgs35segs as int
declare @DlgsAveTime as int
declare @QueueAveTime as int

--select @dia = '2003/01/22' --, @CveCamp=5
--select @dia = getdate()

select @dia=convert(CHAR(11), GETDATE(), 21)

select @fechaI = convert(datetime, @dia, 101)
select @fechaF = dateadd( d, 1, @fechaI )

select @Calls = 0, @CallsLost= 0, @CallsQueue = 0, @OverFlowQueue = 0,  @OverFlowTimeOut = 0,
	@Dlgs = 0, @Dlgs35segs = 0, @QueueAveTime = 0
	
	select 
	@calls = ISNULL(count(*), 0),
	@callsLost = ISNULL(count (case when statusCall_id in (2,3,4,6) then 1 else null end), 0),
	@callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0),
	@OverFlowQueue = ISNULL(count (case when  statusCall_id =8 then 1 else null end), 0),
	@OverFlowTimeOut = ISNULL(count (case when  statusCall_id =7 then 1 else null end), 0),
	@Dlgs = ISNULL(count (case when  statusCall_id = 13 then 1 else null end), 0),
	@DlgsAveTime= ISNULL(sum (case when  statusCall_id = 13 then cal_tDialog + cal_tNotas else 0 end), 0),
	@Dlgs35segs =ISNULL(count (case when  statusCall_id = 13 and cal_tdialog < 35 then 1 else null end), 0),
	@QueueAveTime=ISNULL( avg( case when   cal_que > 0 then cal_tWait else null end), 0) --statusCall_id = 13
	from ccCallsIn
	where cal_inicio between @fechaI and @fechaF and inbound_id = @cvecamp 

select 'Calls'=@Calls, 'Abandon'=@CallsLost, 'Queue'=@CallsQueue, 'OFQueue'=@OverFlowQueue,  'OFTimeOut'=@OverFlowTimeOut,
	'Dialogs'=@Dlgs, 'Dlgs35segs'=@Dlgs35segs, 'DlgsAveTime'=case @Dlgs when 0 then 0 else @DlgsAveTime/ @Dlgs end, 'QueueAveTime'=@QueueAveTime
*/