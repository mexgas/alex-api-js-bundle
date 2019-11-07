CREATE function [dbo].[fn_ccCamps_SelMessage](@cam_id smallint)
returns @SelMessage table (msg_mostrar varchar(max), msg_mostrar_dnc varchar(max), msg_mostrar_dnc_confirm varchar(max) )
as
begin
declare @msg_mostrar varchar(max), @msg_mostrar_dnc varchar(max), @msg_mostrar_dnc_confirm varchar(max)
select @msg_mostrar='', @msg_mostrar_dnc='', @msg_mostrar_dnc_confirm = ''

select @msg_mostrar=@msg_mostrar+coalesce(msgFile+',','')
from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id
where M.cam_id = @cam_id and type = 8 order by orden

select @msg_mostrar_dnc=@msg_mostrar_dnc+coalesce(msgFile+',','')
from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id
where M.cam_id = @cam_id and type = 11 order by orden

select @msg_mostrar_dnc_confirm=@msg_mostrar_dnc_confirm+coalesce(msgFile+',','')
from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id
where M.cam_id = @cam_id and type = 14 order by orden

insert into @SelMessage select 
case when len(isnull(@msg_mostrar,''))>0 then left(@msg_mostrar, len(@msg_mostrar)-1) else '' end,
case when len(isnull(@msg_mostrar_dnc,''))>0 then left(@msg_mostrar_dnc, len(@msg_mostrar_dnc)-1) else '' end,
case when len(isnull(@msg_mostrar_dnc_confirm,''))>0 then left(@msg_mostrar_dnc_confirm, len(@msg_mostrar_dnc_confirm)-1) else '' end

return
end