CREATE PROCEDURE [dbo].[ccspRepChatsEffectiveness]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete from RepChatsEffectiveness with(rowlock)
	where date >= @from AND date < @to

	insert into RepChatsEffectiveness
	select 
		a.date, a.inboundId, d.descripcion as [inbound]
		,a.ntotalChat, isnull(b.nanswer,0) as nanswerChat, isnull(c.nabnd,0) as nabnd
		, convert(decimal(10,2),isnull(convert(decimal(10,0),b.nAnswerTime)/convert(decimal(10,0),nAnswer),0)) as [avgAnswerTime]	
		, convert(decimal(10,2),isnull(convert(decimal(10,0),b.tSumQueue)/convert(decimal(10,0),nAnswer),0)) as [avgQueueTime]	
		, convert(decimal(10,2),isnull(convert(decimal(10,0),c.tSumAbandon)/convert(decimal(10,0),c.nabnd),0)) as [avgAbandonTime]
		, datepart(yyyy,a.date) as [year], datepart(mm,a.date) as [mount]
		, datepart(dd,a.date) as [day], datepart(hh,a.date) as [hh], datepart(mi,a.date) as [minutes]
	FROM(
		(SELECT 
			CONVERT(smalldatetime,CONVERT(varchar(13),a.requestDate,121)+ ':00',121) as [date],
			a.inboundId , count(*) as ntotalChat
			FROM ccRIaChats a		
			where requestDate >= @from AND requestDate < @to
			group by CONVERT(smalldatetime,CONVERT(varchar(13),a.requestDate,121)+ ':00',121), a.inboundId	
		) as a	
		LEFT JOIN
		(SELECT 
			CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ ':00',121) as date,
			inboundId , count(*) as nAnswer
			,sum(case when firstMessageTime is null then convert(int,isnull(firstMessageTime,0)) 
				else datediff(ss,chatdate,firstMessageTime) end ) as [nAnswerTime]
			,sum(tQueue) as tSumQueue
			FROM ccRIaChats
			where chatStatus = 4 AND requestDate >= @from AND requestDate < @to -- Contestados
			group by CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ ':00',121), inboundId	
		)as b
		ON a.date =  b.date AND a.inboundId = b.inboundId
		LEFT JOIN 
		(SELECT 
			CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ ':00',121) as date,
			inboundId , count(*) as nabnd, sum(tQueue) as tSumAbandon
			FROM ccRIaChats
			where chatStatus = 9 AND requestDate >= @from AND requestDate < @to -- abandonadas		
			group by CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ ':00',121), inboundId	
		)as c
		ON a.date = c.date AND a.inboundId = c.inboundId	
		INNER JOIN ccinbound d on (a.inboundId = d.inbound_id)
	)
	
end