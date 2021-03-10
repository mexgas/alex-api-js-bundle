CREATE PROCEDURE [dbo].[ccsp_GalateaADMPermisos]
@users_id varchar(255),
@Type int, -- 1.- cambia permiso, 2.- obtiene lista de permisos
@Permit int, -- 1.- AllowChangeDialingMode
@isActive int
AS
set nocount on

If @Type = 1 --1 Update Permission
 begin
	 if @permit = 1   --AllowChangeDialingMode
	   		UPDATE ccUsers SET AllowChangeDialingMode = @isActive where user_id in (select value from dbo.fn_RIASplitDelimited(@users_id, ','))

	 return(0)
 end

if @Type = 2 --Get Permission
begin
	return(0)
end

set nocount off