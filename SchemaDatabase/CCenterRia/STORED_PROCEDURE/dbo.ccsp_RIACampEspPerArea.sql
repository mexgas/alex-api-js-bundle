CREATE PROCEDURE [dbo].[ccsp_RIACampEspPerArea]
@Type smallint,
@IDArea smallint = 0

AS

If (@Type = 1) -- get ACDs
begin
	If @IDArea = 0
	begin
		select a.Inbound_id, a.descripcion,c.frame from ccInbound a
		left join ccRIAInboundGraph b on a.inbound_id = b.inbound_id
		left join ccRIAGraphics c on c.graphic_id = b.graphic_id
		where a.IDArea is null
	end
	else
	begin
		select a.Inbound_id, a.descripcion,c.frame from ccInbound a
		left join ccRIAInboundGraph b on a.inbound_id = b.inbound_id
		left join ccRIAGraphics c on c.graphic_id = b.graphic_id
		where a.IDArea = @IDArea
	end
end
If (@Type = 2) -- get ACDGroups
begin
	IF @IDArea = 0
	begin
		select a.cam_id, a.cam_descripcion, c.frame, a.cam_activo from ccCamps a
		left join ccRIACampsGraph b on a.cam_id = b.cam_id
		left join ccRIAGraphics c on c.graphic_id = b.graphic_id
		where a.IDArea is null
	end
	else
	begin
		select a.cam_id, a.cam_descripcion, c.frame, a.cam_activo from ccCamps a
		left join ccRIACampsGraph b on a.cam_id = b.cam_id
		left join ccRIAGraphics c on c.graphic_id = b.graphic_id
		where a.IDArea = @IDArea
	end
end