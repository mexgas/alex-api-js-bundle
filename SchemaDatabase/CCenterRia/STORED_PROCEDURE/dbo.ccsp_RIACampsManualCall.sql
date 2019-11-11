CREATE PROCEDURE [dbo].[ccsp_RIACampsManualCall]
		@UserID int,
		@onChat int = 0
		AS
		set nocount on

		if (@onChat = 0)
		begin
			declare @mod smallint
			select @mod = defCampaing from ccRIACat_Areas A
			where A.IDArea = (select IDArea from ccUsers where User_id = @UserID) 

			select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [isDefault],  g.graphic_id
			from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
			join ccRIACampsGraph g ON g.cam_id = c.cam_id
			where ca.user_id = @UserID and cam_modoManual = 1
			order by cam_descripcion
		end
		else
			select distinct c.cam_id, c.cam_descripcion,  g.graphic_id
			from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
			join ccRIACampsGraph g ON g.cam_id = c.cam_id
			where ca.user_id = @UserID and manualCallOnChat = 1
			order by cam_descripcion

set nocount off