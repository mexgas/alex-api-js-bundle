CREATE procedure [dbo].[cssp_getCamRelations]
	@calltype int,
	@relatedCam int

	AS
	SET NOCOUNT ON;

	if(@calltype = 1)
begin
	select @calltype as [callType], @relatedCam as [camRelated] , a.template_id, convert(int,b.actityAgent) as [template_status] from Inbound_Campaign a
	right join Templates b on a.Template_id  = b.Template_id
	 where inbound_id = @relatedCam
	 and b.status = 1 
end
else if(@calltype = 2)
begin
	select @calltype as [callType], @relatedCam as [camRelated], a.template_id,convert(int, b.actityAgent) as [template_status] from Campaign a
	right join Templates b on a.Template_id = b.Template_id
	 where Cam_id = @relatedCam
	 and b.status = 1
end