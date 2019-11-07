CREATE PROCEDURE [dbo].[ccsp_RIAChatGetAutoMessage]
@action as tinyint,
@inboundId as int=null,
@type as tinyint=null,
@session as varchar(50)=null
AS
BEGIN

if @action = 1 begin

	select b.msg_id,b.msg from ccRIAChatInboundMsgs a inner join ccRIAChatMsg b 
	on a.msg_id = b.msg_id where Inbound_id = @inboundId and type = @type order by orden

end	
if @action = 2 begin
	select b.msg_id,b.msg from ccRIAChatInboundMsgs a 
	inner join ccRIAChatMsg b on a.msg_id = b.msg_id 
	inner join ccRiaChats c on a.Inbound_id = c.inboundId
	where c.[session] = @session
	and type = @type
	and convert(smalldatetime,CONVERT(varchar(11),c.requestDate,121)) = convert(smalldatetime,CONVERT(varchar(11),getdate(),121))
	order by orden

end

END