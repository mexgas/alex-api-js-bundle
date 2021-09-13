CREATE PROCEDURE [dbo].[ccsp_GalateaConfAggrFct]
@Type tinyint,    -- 1:Muestra | 2:Actualiza Camp | 3:Actualiza Todas por Usuario
@cam_id varchar(255) = null,
@User_id int = null,
@aggressionFactor float = null
AS
set nocount on
if @Type=1
 begin
	if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
			select cam_id, cam_Descripcion, aggressionFactor
			from ccCamps where cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
			order by cam_descripcion
		end
		else begin
			select cam_id, cam_Descripcion, aggressionFactor from ccCamps where cam_activo <> 0 and IDArea is not null
		end
    return(0)
 end

if @Type=2
 begin
    UPDATE ccCamps SET aggressionFactor = isnull(@aggressionFactor,aggressionFactor) 
    Where cam_id in (select value from dbo.fn_RIASplitDelimited(@cam_id, ','))

	if @@ROWCOUNT > 0
		select cam_id, aggressionFactor from ccCamps Where cam_id in (select value from dbo.fn_RIASplitDelimited(@cam_id, ','))
    return(0)
 end

if @Type=3
 begin
	if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
			UPDATE ccCamps SET aggressionFactor = isnull(@aggressionFactor,aggressionFactor)
			Where cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))

			if @@ROWCOUNT > 0
				select cam_id, aggressionFactor from ccCamps where cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
		end
		else begin
			UPDATE ccCamps SET aggressionFactor = isnull(@aggressionFactor,aggressionFactor)
			where cam_activo <> 0 and IDArea is not null

			if @@ROWCOUNT > 0
				select cam_id, aggressionFactor from ccCamps where cam_activo <> 0 and IDArea is not null
		end
    return(0)
 end

set nocount off