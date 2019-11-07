CREATE procedure [dbo].[ccsp_RIAtmpChart]
@inbound_id smallint = NULL,
@graphicType smallint = NULL
as
SET NOCOUNT ON

declare @DT as int
select @DT = valor from ccsettings where setting_id = 12

Declare @Times Table (
	StartDate datetime not null,
	EndDate datetime not null,
	[timestamp] varchar(5) not null)

Declare @Start DateTime
Declare @End Datetime
Declare @descripcion varchar(50)

declare @DTChat as int
select @DTChat = valor from ccsettings where setting_id = 141

if @graphicType = 1 --Call
begin
	declare @Fecha smalldatetime, @FechaW smalldatetime

	select @Fecha=convert(varchar(10), getdate(), 121)

	if exists(select cal_Inicio from cccallsin_tmpChart where cal_inicio < @Fecha)  truncate table cccallsin_tmpChart

	delete cccallsin_tmpChart where inbound_id = @inbound_id and cal_inicio >= @Fecha
	select @FechaW=@Fecha

	 while @FechaW <= convert(varchar(15), getdate(), 121)+'0:00' begin
		if exists(Select SL.inbound_id from (select NS.inbound_id, @fechaW cal_inicio, sum(NS.LCt) LCt,  sum(NS.LAt) LAt,  sum(NS.LS) LS,  sum(NS.LA) LA,  sum(NS.LDt) LDt,
			sum(NS.LDc) LDc, sum(NS.LC) LC, sum(NS.LNC) LNC, sum(NS.LP) LP, @DT DyTrh
			from (Select @inbound_id inbound_id, @fechaW cal_inicio,
			ISNULL(count(CASE WHEN(statuscall_id in(13))and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LCt,
			ISNULL(count(CASE WHEN(statuscall_id=6)and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LAt,
			ISNULL(count(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0)AS LS,
			ISNULL(count(CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0)AS LA,
			ISNULL(count(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0)AS LDt,
			ISNULL(count(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0)AS LDc,
			ISNULL(count(CASE WHEN(statuscall_id in(13))THEN 1 ELSE NULL END),0)AS LC,
			ISNULL(count(CASE WHEN(statuscall_id=15)THEN 1 ELSE NULL END),0)AS LNC,
			ISNULL(count(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0)AS LP
			from cccallsin where inbound_id=@inbound_id and cal_inicio between @Fecha and @FechaW and statuscall_id IN(4,6,7,8,11,13,15,16)
			group by convert(varchar(15), cal_inicio, 121)+'0:00') as NS group by NS.inbound_id) as SL)
	   begin
		   insert into cccallsin_tmpChart (inbound_id, cal_Inicio, LCt, LAt, LS, LA, LDt, LDc, LC, LNC, LP, DT, NS)
			select SL.* ,case when (LC+LA+LS+LDt+LDc+LNC+LP) = 0 then '1' else cast((cast((LCt+LAt) as float)/cast((LC+LA+LS+LDt+LDc+LNC+LP)
				as float))*100 as decimal(18,2))end ServN
					from (select NS.inbound_id, @fechaW cal_inicio, sum(NS.LCt) LCt,  sum(NS.LAt) LAt,  sum(NS.LS) LS,  sum(NS.LA) LA,  sum(NS.LDt) LDt,
				sum(NS.LDc) LDc, sum(NS.LC) LC, sum(NS.LNC) LNC, sum(NS.LP) LP, @DT DyTrh
					from (Select @inbound_id inbound_id, @fechaW cal_inicio,
						ISNULL(count(CASE WHEN(statuscall_id in(13))and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LCt,
						ISNULL(count(CASE WHEN(statuscall_id=6)and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LAt,
						ISNULL(count(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0)AS LS,
						ISNULL(count(CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0)AS LA,
						ISNULL(count(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0)AS LDt,
						ISNULL(count(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0)AS LDc,
						ISNULL(count(CASE WHEN(statuscall_id in(13))THEN 1 ELSE NULL END),0)AS LC,
						ISNULL(count(CASE WHEN(statuscall_id=15)THEN 1 ELSE NULL END),0)AS LNC,
						ISNULL(count(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0)AS LP
					from cccallsin where inbound_id=@inbound_id and cal_inicio between @Fecha and @FechaW and statuscall_id IN(4,6,7,8,11,13,15,16)
				group by convert(varchar(15), cal_inicio, 121)+'0:00') as NS group by NS.inbound_id) as SL
	   end

		else begin
			insert into cccallsin_tmpChart (inbound_id, cal_Inicio, LCt, LAt, LS, LA, LDt, LDc, LC, LNC, LP, DT, NS)
			Select @inbound_id, @FechaW, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		end

	  select @FechaW=dateadd(minute, 10, @FechaW)
	 end

	if not exists(select d.descripcion from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart)) join (select c.inbound_id, i.descripcion, c.NS, convert(varchar(5), max(c.cal_inicio), 108) timestamp
		from cccallsin_tmpChart c join ccinbound i on c.inbound_id = i.inbound_id
		where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+'0:00') and c.inbound_id = @inbound_id
		group by c.inbound_id, i.descripcion, c.NS) D on c.inbound_id = d.inbound_id
		where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+'0:00') and c.inbound_id = @inbound_id)
	begin
		raiserror('without ACD Group information  ', 18, 1)
		return(0)
	end

 select * from
	(select top 20 @inbound_id inbound_id, d.descripcion, d.NS LastNS, convert(varchar(5), c.cal_inicio, 108) timestamp, c.NS
		from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart))
	inner join
	(select top 1 c.inbound_id, i.descripcion, c.NS, convert(varchar(5), max(c.cal_inicio), 108) timestamp
		from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart)) join ccinbound i on c.inbound_id = i.inbound_id
		where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+'0:00') and c.inbound_id = @inbound_id
  --and c.cal_inicio < convert(varchar(15), getdate(), 121)+'0:00'
		group by c.inbound_id, i.descripcion, c.NS order by timestamp desc) D on c.inbound_id = d.inbound_id
	where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+'0:00') and c.inbound_id = @inbound_id
  --and c.cal_inicio < convert(varchar(15), getdate(), 121)+'0:00'
 order by 4 desc) as chart order by 4
 return(0)
end

if @graphicType in(2,3,4) begin--Init tabla timer

	set @End = getdate()
	set @Start = convert(varchar(15),dateadd(minute, -200, @end),121) + '0:00'

	while @Start < @End begin
		insert @Times(StartDate, EndDate, [timestamp]) values(@Start, DateAdd(minute, 10, @Start), convert(varchar(5), convert(datetime,@Start), 108))
		set @Start = DateAdd(minute, 10, @Start)
	end

	select @descripcion = descripcion  from ccinbound where inbound_id = @inbound_id

	create table #MultimediaSummary(
		inboundId smallint not null,
		descripcion varchar(50) not null,
		LastNS decimal(10,2) not null,
		[timestamp] varchar(5) not null,
		NS decimal(10,2) not null
	)

	create table #MultimediaChart(
		inboundId smallint not null,
		descripcion varchar(50) not null,
		LastNS decimal(10,2) not null,
		[timestamp] varchar(5) not null,
		NS decimal(10,2) not null
	)


end

if @graphicType = 2 begin --CHAT
	insert into #MultimediaSummary
	 select inboundId, descripcion, 0.00 as LastNS,
	 convert(varchar(5), convert(datetime,Date), 108) [timestamp],
	 convert(decimal(10,2),convert(float,[Connected]) / convert(float, Total) * 100.00) as NS
	 from
		 (select inboundId, descripcion, Date,
		 sum([Connected>DT]) as [Connected],
		 sum([Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as NotConnected,
		 sum([Connected>DT] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as Total
		 from (
			 select inboundId, descripcion, convert(varchar(15), chatDate, 121)+'0:00' as Date,
			 ISNULL(count(CASE WHEN chatstatus = 4 and tChatting >= @DTChat THEN 1 ELSE NULL END),0)AS [Connected>DT],
			 ISNULL(count(CASE WHEN chatstatus = 4 and tChatting < @DTChat THEN 1 ELSE NULL END),0)AS [Connected<DT],
			 ISNULL(count(CASE WHEN(chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
			 ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
			 ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
			 ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
			 ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow]
			 from ccRIAChats a
			 right outer join @times b on (chatDate >= StartDate and chatDate < EndDate)
			 left outer join ccInbound c on (inboundId = inbound_id)
			 where inboundId = @inbound_id and chatStatus in (3,4,7,9,10,11) and chatDate is not null
			 group by inboundId, descripcion, convert(varchar(15), chatDate, 121)+'0:00') as ChatDetail
	group by inboundId, descripcion, Date) as ChatSummary

end

else if @graphicType = 4 begin--Email
	insert into #MultimediaSummary
	select	x.inboundId,x.descripcion, 0.00 as LastNS,
	convert(varchar(5), convert(datetime,Date), 108) [timestamp],
	convert(decimal(10,2),convert(float,sent+forwarding+closed) / convert(float, received) * 100.00) as NS
	from
		(select
		inboundId,c.descripcion, convert(varchar(15), msg.date, 121)+'0:00' as Date,
		count(*) received,
		count(case when messageStatusId in (5,6) then 1 else null end) sent,
		count(case when messageStatusId = 9 then 1 else null end) forwarding,
		count(case when messageStatusId in (10,11) then 1 else null end) closed
		from messageOutTwitter msg (nolock) join conversationTwitter con (nolock) on con.conversationTwitterId=msg.conversationTwitterId
		right outer join @times b on msg.date >= StartDate and msg.date < EndDate
		left outer join ccInbound c on con.inboundId = c.inbound_id
		where inboundId = @inbound_id
		group by inboundId,c.descripcion, convert(varchar(15), date, 121)+'0:00'
		)x

end
else if @graphicType = 3 begin--Email
	insert into #MultimediaSummary
	select	x.inboundId,x.descripcion, 0.00 as LastNS,
	convert(varchar(5), convert(datetime,Date), 108) [timestamp],
	convert(decimal(10,2),convert(float,sent+forwarding+closed) / convert(float, received) * 100.00) as NS
	from
		(select
		inboundId,c.descripcion, convert(varchar(15), msg.date, 121)+'0:00' as Date,
		count(*) received,
		count(case when messageStatusId in (5,6,1) then 1 else null end) sent,
		count(case when messageStatusId = 9 then 1 else null end) forwarding,
		count(case when messageStatusId in (10,11) then 1 else null end) closed
		from message msg (nolock) join conversation con (nolock) on con.conversationId=msg.conversationId
		right outer join @times b on msg.date >= StartDate and msg.date < EndDate
		left outer join ccInbound c on con.inboundId = c.inbound_id
		where inboundId = @inbound_id
		group by inboundId,c.descripcion, convert(varchar(15), date, 121)+'0:00'
		)x
end

if @graphicType in(2,3,4) begin--Se coloca al final la parte que son iguales todos los servicios multimedia

	insert into #MultimediaChart
	 select case when (inboundId is null) then @inbound_id else inboundID end as inboundId,
		case when (descripcion is null) then @descripcion else descripcion end as descripcion,
		case when (LastNS is null) then 0.00 else LastNS end as LastNS,
		case when (a.[timestamp] is null) then b.[timestamp] else a.[timestamp] end as [timestamp],
		case when (NS is null) then 0.00 else NS end as NS
		from #MultimediaSummary a
	 full outer join @times b on (a.[timestamp] = b.[timestamp])
	 order by b.[timestamp]

	 select a.inboundId, a.descripcion, b.NS as LastNS, a.[timestamp], a.NS
	 from #MultimediaChart a, #MultimediaChart b
	 where convert(varchar(5),dateadd(minute, -10, convert(datetime,a.[timestamp])), 108) = b.[timestamp]
	 order by a.[timestamp]


	drop table #MultimediaSummary
	drop table #MultimediaChart
end