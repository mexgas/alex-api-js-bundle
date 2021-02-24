Create PROCEDURE [dbo].[ExportAnwsAndXfers]
@type as tinyint,
@serverName as varchar(300),
@page as tinyint
as

declare @s_Page as int
declare @f_page as int
declare @pageSize as int
declare @Public_IP as varchar(20)

set @pageSize = 10000

select @Public_IP = valor from ccSettings where setting_id = 7

if (@type = 0)
begin
	select case when count(callid)% @pageSize = 0 then count(callid) / @pageSize else (count(callid) + (@pageSize - count(callid) % @pageSize))/ @pageSize end  cantidad from RepOutAnswAndXferCalls where date >= dateadd(D,-1,convert(smalldatetime,convert(varchar(10),getdate(),120),120)) and date < convert(smalldatetime,convert(varchar(10),getdate(),120),120)
end

if (@type = 1)
begin
	set @s_Page = (@page -1) * @pageSize
	set @f_page = @page * @pageSize
	--select @s_Page, @f_page

	select * from (select convert(varchar(24),[date],121) [date], isnull(callid,'') callid, isnull(campaignId,'') campaignId,isnull(campaign,'') campaign , isnull(userId,'') userId ,isnull(Agent,'') Agent ,isnull(dialog,'') dialog ,isnull(telephone,'') telephone ,isnull(dialId,'') dialId , isnull(dialType,'') dialType , isnull(Calltypes,'') Calltypes , convert(varchar(10),isnull(ncost,'0')) ncost, convert(varchar(3),isnull(iva,'0')) iva, convert(varchar(10),isnull(total,'0')) total, @Public_IP as serverIP, @serverName as SystemName, isnull(convert(int,[trunk]),'') [trunk], isnull([ANI],'') [ANI], isnull(convert(int,[dialTimeSec]), '') [dialTimeSec], convert(int, ROW_NUMBER() OVER (ORDER BY date)) as rowd  from RepOutAnswAndXferCalls where date >= dateadd(D,-1,convert(smalldatetime,convert(varchar(10),getdate(),120),120)) and date < convert(smalldatetime,convert(varchar(10),getdate(),120),120)) as a where rowd >= @s_Page and rowd < @f_page
end