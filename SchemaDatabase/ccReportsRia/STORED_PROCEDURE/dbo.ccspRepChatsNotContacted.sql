CREATE PROCEDURE [dbo].[ccspRepChatsNotContacted]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete from RepChatsNotContacted with(rowlock)
	where date >= @from AND date < @to

	insert INTO RepChatsNotContacted
	SELECT 
		CONVERT(smalldatetime,CONVERT(varchar(13),a.requestDate,121)+ ':00',121) as date,
		inboundId,MAX(b.descripcion) as Inbound, MAX(b.IDArea) as areaID, MAX(c.AreaName) as area,
		DATEPART(yyyy,MAX(requestDate)) as [year], DATEPART(mm,MAX(requestDate)) as [mounth], DATEPART(dd,MAX(requestDate)) as [day],
		DATEPART(hh,MAX(requestDate)) as [hour], 0 as minutes,
		a.chatStatus as chatStatus,MIN(d.description)+'_Count' as descriptionCount, COUNT(a.chatStatus) as [count]
		FROM ccRIaChats a
		INNER JOIN ccInbound b ON a.inboundId = b.Inbound_id
		INNER JOIN ccRIACat_Areas c ON c.IDArea = b.IDArea 
		INNER JOIN ccRIAChatStatus d ON d.id = a.chatStatus
		where a.chatStatus IN(10,11,6,5,7) AND a.requestDate >= @from AND a.requestDate < @to
		group by CONVERT(smalldatetime,CONVERT(varchar(13),a.requestDate,121)+ ':00',121), a.inboundId, b.IDArea, a.chatStatus 
end