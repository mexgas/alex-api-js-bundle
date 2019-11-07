CREATE procedure getPrefixByAcdId 
@inboundId int 
as
select isnull(prefijo,'') from ccInbound where Inbound_id = @inboundId