CREATE PROCEDURE [dbo].[ccspRepAvgAnswerTimeChats]
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
		delete RepAvgAnswerTimeChats with(rowlock)
		where date >= @from and date < @to

		insert into RepAvgAnswerTimeChats
		select CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ ':00',121) as [date], userId, [Login], inboundId, [inbound],
		[user], convert(decimal(10,2),(convert(decimal(10,2),sum([answerTime])) / convert(decimal(10,2),count(*)))) as [avgAnswerTime]
		, datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ ':00',121))
		, datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ ':00',121))
		, datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ ':00',121))
		, datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ ':00',121))
		, datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ ':00',121))
		from(
		select requestDate as [date], userId, [Login] as [login], 
		inboundId, c.descripcion as [inbound], nombres + ' ' + apellidopaterno + ' ' + apellidomaterno as [user],
		case when firstMessageTime is null then convert(int,isnull(firstMessageTime,0)) 
		else datediff(ss,chatdate,firstMessageTime) end as [answerTime]
		from ccriachats a
		left join ccUserView b on (a.userId = b.user_id)
		left join ccinbound c on (a.inboundId = c.inbound_id)
		where b.user_id is not null
		and c.inbound_id is not null
		and a.chatstatus = 4) as answerTime
		group by CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ ':00',121), userId, [Login], inboundId, [inbound], [user]

	end