CREATE PROCEDURE [dbo].[ccsp_RIAADMCampMsgs]
@Command tinyint, -- 1=Query, 2=Insert
@msg_id int = null,
@cam_id smallint = null,
@order tinyint = null,
@Type tinyint = null,
@queue bit = null,
@msgFile varchar(40) = '',
@description varchar(40) = ''
as
set nocount on
if @Command=1
 begin
	select A.type, A.orden, msgFile, A.Msg_id, D.msg_mostrar
	from ccCampsMsgs A 
	join ccCamps B on A.cam_id = B.cam_id
	join ccMsgFiles C on A.Msg_id = C.Msg_id 
	left join ccTipoMsgs D on A.type = D.tipomsg_id
	where A.cam_id = @cam_id
	order by A.type, A.orden
	return(0) 
 end

If @Command=2
 begin
	if not exists (select msg_id from ccCampsMsgs where msg_id=@msg_id and cam_id=@cam_id and type=@type)
		insert into ccCampsMsgs (msg_id, cam_id, orden, type) values (@msg_id, @cam_id, @order, @Type)
	return(0)
 end
 
If @Command=3
	begin
		exec @msg_id = ccsp_RIACATMessages 5, 0, @msgFile, @description
		if @msg_id <> 0
			insert into ccCampsMsgs (msg_id, cam_id, orden, type) values (@msg_id, @cam_id, @order, @Type)
		return(0)
	end

set nocount off