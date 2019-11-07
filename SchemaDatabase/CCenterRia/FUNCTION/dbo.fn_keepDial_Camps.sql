CREATE function [dbo].[fn_keepDial_Camps](@cam_id smallint)
returns bit
as
begin
declare @calif_id bit

select @calif_id=sum(cast(keepDial as int)) + sum( cast(isNull(subKeepDial,0) as int) )
from ccTipoCalifOUT O join ccCalifCamp C on O.calif_id = C.calif_id
left join 
(
	select cctipoSubCalifRel.calif_id, cctipoSubCalifRel.califSub_id, keepDial as subKeepDial
	from cctipocalifSubOUT 
	join cctipoSubCalifRel on cctipocalifSubOUT.califsub_id = cctipoSubCalifRel.califSub_id
	where cctipoSubCalifRel. tipoSubRel = 0
)x on C.calif_id = x.calif_id
where C.tipo=1 and C.cam_id = @cam_id

return isnull(cast(@calif_id as bit),0)
end