CREATE PROCEDURE [dbo].[ccsp_RIAChatADMInboundMsgs]
@Command tinyint, -- 1=Query, 2=Insert, 3=Delete
@msg_id int=null,
@Inbound_id smallint=null,
@order tinyint=null,
@Type tinyint=null
as
set nocount on
if @Command=1
begin
select A.type, A.orden, msg, A.Msg_id, D.msg_mostrar
from ccRIAChatInboundMsgs A join ccInbound B on A.Inbound_id=B.Inbound_id
join ccRIAChatMsg C on A.Msg_id=C.Msg_id left join ccTipoMsgs D on A.type=D.tipomsg_id
where A.Inbound_id=@Inbound_id
order by A.type, A.orden
return(0)
end

If @Command=2
begin
if not exists(select msg_id from ccRIAChatInboundMsgs where msg_id=@msg_id and inbound_id=@inbound_id and type=@type)
	insert into ccRIAChatInboundMsgs (msg_id, inbound_id, orden, type) values (@msg_id, @Inbound_id, @order, @Type)
return(0)
end
/*
if @Command=4
begin
update ccRIAChatInboundMsgs set queue=@queue 
where Inbound_id=@Inbound_id and Msg_id=@msg_id and orden=@order and type=1
return(0)
end
*/
set nocount off