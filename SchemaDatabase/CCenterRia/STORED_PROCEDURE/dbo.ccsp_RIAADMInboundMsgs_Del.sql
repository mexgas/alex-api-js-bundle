CREATE PROCEDURE dbo.ccsp_RIAADMInboundMsgs_Del
@msg_id varchar(255) = null,
@Inbound_id smallint = null,
@order varchar(255) = null,
@Type varchar(255) = null
as
set nocount on

declare @i int, @x int
declare @T_msg_id as table (id int, msg_id varchar(255))
declare @T_order as table (id int, [order] varchar(255))
declare @T_Type as table (id int, [type] varchar(255))
declare @T_all as table (id int, Inbound_id int, msg_id int, [order] int, [type] int)
declare @temp_ccInboundMsgs as table(id int identity, Msg_id int, Inbound_id smallint, orden tinyint, Type tinyint, queue bit)

insert @T_msg_id select * from dbo.fn_RIASplitDelimited(@msg_id, ',')
insert @T_order select * from dbo.fn_RIASplitDelimited(@order, ',')
insert @T_Type select * from dbo.fn_RIASplitDelimited(@Type, ',')

insert @T_all select m.id, @Inbound_id, msg_id, [order], [type] 
	from @T_msg_id m join @T_order o on m.id = o.id join @T_Type t on o.id = t.id
	order by o.[order]

select @i = 1, @x = count(id) from @T_all

while @i <= @x
begin
	delete ccInboundMsgs 
	where Inbound_id = @Inbound_id 
	and msg_id in (select msg_id from @T_all where id = @i) 
	and orden in (select [order] from @T_all where id = @i)
	and Type in (select Type from @T_all where id = @i)
	set @i = @i+1
end

	insert @temp_ccInboundMsgs select distinct r.*
	from ccInboundMsgs r join @T_all a on
	r.Inbound_id = a.Inbound_id and r.Type = a.Type
	order by orden

select @i = 1, @x = count(id) from @temp_ccInboundMsgs

while @i <= @x
begin
	delete ccInboundMsgs 
	where Inbound_id = @Inbound_id 
	and msg_id in (select msg_id from @temp_ccInboundMsgs where id = @i) 
	and orden in (select orden from @temp_ccInboundMsgs where id = @i)
	and Type in (select Type from @temp_ccInboundMsgs where id = @i)
	set @i = @i+1
end

	update @temp_ccInboundMsgs set orden = id
	insert into ccInboundMsgs (Msg_id, Inbound_id, orden, Type, queue)
	select Msg_id, Inbound_id, orden, Type, queue from @temp_ccInboundMsgs
	
return(0)
set nocount off