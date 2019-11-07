CREATE PROCEDURE [dbo].[ccsp_RIAADMCampsMsgs_Del]
@msg_id varchar(255) = null,
@cam_id smallint = null,
@order varchar(255) = null,
@Type varchar(255) = null
as
set nocount on
declare @i int, @x int
declare @T_msg_id as table (id int, msg_id varchar(255))
declare @T_order as table (id int, [order] varchar(255))
declare @T_Type as table (id int, [type] varchar(255))
declare @T_all as table (id int, cam_id int, msg_id int, [order] int, [type] int)
declare @temp_ccCampsMsgs as table(id int identity, Msg_id int, cam_id smallint, orden tinyint, Type tinyint)

insert @T_msg_id select * from dbo.fn_RIASplitDelimited(@msg_id, ',')
insert @T_order select * from dbo.fn_RIASplitDelimited(@order, ',')
insert @T_Type select * from dbo.fn_RIASplitDelimited(@Type, ',')

insert @T_all select m.id, @cam_id, msg_id, [order], [type] 
	from @T_msg_id m join @T_order o on m.id = o.id join @T_Type t on o.id = t.id
	order by o.[order]

select @i = 1, @x = count(id) from @T_all

while @i <= @x
 begin
	delete ccCampsMsgs 
	where cam_id = @cam_id 
	and msg_id in (select msg_id from @T_all where id = @i) 
	and orden in (select [order] from @T_all where id = @i)
	and Type in (select Type from @T_all where id = @i)
	
	delete ccMsgFiles
	where msg_id in (select msg_id from @T_all where id = @i)
	and msgFile like '%TTS%'
	set @i = @i+1
 end

	insert @temp_ccCampsMsgs select distinct r.*
	from ccCampsMsgs r join @T_all a on
	r.cam_id = a.cam_id and r.Type = a.Type
	order by orden

select @i = 1, @x = count(id) from @temp_ccCampsMsgs

while @i <= @x
begin
	delete ccCampsMsgs 
	where cam_id = @cam_id
	and msg_id in (select msg_id from @temp_ccCampsMsgs where id = @i) 
	and orden in (select orden from @temp_ccCampsMsgs where id = @i)
	and Type in (select Type from @temp_ccCampsMsgs where id = @i)
	
	delete ccMsgFiles
	where msg_id in (select msg_id from @T_all where id = @i)
	and msgFile like '%TTS%'
	set @i = @i+1
end

	update @temp_ccCampsMsgs set orden = id
	insert into ccCampsMsgs (Msg_id, cam_id, orden, Type)
	select Msg_id, cam_id, orden, Type from @temp_ccCampsMsgs
return(0)
set nocount off