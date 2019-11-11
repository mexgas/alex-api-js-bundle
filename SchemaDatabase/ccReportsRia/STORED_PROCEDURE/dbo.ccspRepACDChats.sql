CREATE PROCEDURE [dbo].[ccspRepACDChats]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin
	
		delete from RepACDChats with(rowlock)
		where date >= @from AND date < @to
		
		insert into RepACDChats
			select fecha,
			inboundId, b.descripcion, ChatDetail.domain, b.IDArea, c.AreaName,
			max([totalChats]),
			sum([waitingAbandoned]),
			sum([waitingConnected]),
			max(maxTQueue),
			max(avgTQueue),
			sum([onQueue]),
			sum([Connected]),
			sum([UnavailableAgents] + [OutOfService] + [OutOfSchedule] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]),
			0.00 as levelService,
			sum([byCostumer]) as finishedByCostumer,
			sum([byAgent]) as finishedByAgent,
			sum([bySystem]) as finishedBySystem,
			sum([byAdmin]) as finishedByAdmin,
			datepart(yyyy,CONVERT(varchar(20), fecha, 120)) as [year],
			datepart(mm,CONVERT(varchar(20), fecha, 120)) as [month],
			datepart(dd,CONVERT(varchar(20), fecha, 120)) as [day],
			datepart(hh,CONVERT(varchar(20), fecha, 120)) as [hour],
			datepart(mi,CONVERT(varchar(20), fecha, 120)) as [minutes]
			from(

				select inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ ':00',121) as fecha,
				count(*) as [totalChats],
				domain,
				ISNULL(count(CASE WHEN (chatstatus = 9) and onQueue = 1 THEN 1 ELSE NULL END),0)AS [waitingAbandoned],
				ISNULL(count(CASE WHEN (chatstatus = 4) and onQueue = 1 THEN 1 ELSE NULL END),0)AS [waitingConnected],
				ISNULL(count(CASE WHEN (chatstatus = 4) THEN 1 ELSE NULL END),0)AS [Connected],
				ISNULL(count(CASE WHEN onQueue = 1 THEN 1 ELSE NULL END),0)AS [onQueue],
				ISNULL(count(CASE WHEN(chatstatus = 2)THEN 1 ELSE NULL END),0)AS [UnavailableAgents],
				ISNULL(count(CASE WHEN(chatstatus = 5)THEN 1 ELSE NULL END),0)AS [OutOfService],
				ISNULL(count(CASE WHEN(chatstatus = 6)THEN 1 ELSE NULL END),0)AS [OutOfSchedule],
				ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
				ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
				ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
				ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow],
				ISNULL(count(CASE WHEN(finishedBy = 0)THEN 1 ELSE NULL END),0) AS [byCostumer],
				ISNULL(count(CASE WHEN(finishedBy = 1)THEN 1 ELSE NULL END),0) AS [byAgent],
				ISNULL(count(CASE WHEN(finishedBy = 2)THEN 1 ELSE NULL END),0) AS [bySystem],
				ISNULL(count(CASE WHEN(finishedBy = 3)THEN 1 ELSE NULL END),0) AS [byAdmin],
				max(tqueue) as maxTQueue,
				avg(tqueue) as avgTQueue
				from ccRIAChats a
				where
				chatStatus in (2,5,4,7,9,10,11)
				group by inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ ':00',121), domain
				
			) as ChatDetail
			left join ccInbound b on (b.inbound_id = ChatDetail.inboundId)
			left join ccRIACat_Areas c on (c.IDArea = b.IDArea)
			where fecha >= @from and fecha < @to
			group by inboundId, fecha, b.descripcion, ChatDetail.domain, b.IDArea, c.AreaName
			
			declare @DTChat as int
			select @DTChat = valor from ccsettings where setting_id = 33
			
			select inboundId, descripcion, date,
			isnull(convert(decimal(10,2),convert(float,[Connected]) / NULLIF(convert(float, Total) * 100.00,0)),0) as NS
			into #tmpns
			from
			(select inboundId, descripcion, Date,
			sum([Connected>DT]) as [Connected], 
			sum([Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as NotConnected,
			sum([Connected>DT] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as Total
			from (
			select inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ ':00',121) as Date,
			ISNULL(count(CASE WHEN chatstatus = 4 and tChatting >= @DTChat THEN 1 ELSE NULL END),0)AS [Connected>DT],
			ISNULL(count(CASE WHEN chatstatus = 4 and tChatting < @DTChat THEN 1 ELSE NULL END),0)AS [Connected<DT],
			ISNULL(count(CASE WHEN(chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
			ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
			ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
			ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
			ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow]
			from ccRIAChats a
			left outer join ccInbound c on (inboundId = inbound_id)
			where chatStatus in (3,4,7,9,10,11)
			and chatDate is not null
			group by inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ ':00',121)) as ChatDetail
			group by inboundId, descripcion, Date) as ChatSummary order by date, inboundid
			
			update RepACDChats set SL = b.NS 
			from RepACDChats a, #tmpns b where a.date = b.date and a.inboundId = b.inboundId
			drop table #tmpns
	end