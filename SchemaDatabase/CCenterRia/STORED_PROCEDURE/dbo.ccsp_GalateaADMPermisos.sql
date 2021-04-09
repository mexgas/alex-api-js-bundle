CREATE PROCEDURE [dbo].[ccsp_GalateaADMPermisos]
@users_id varchar(255),
@Type int, -- 1.- cambia permiso, 2.- obtiene lista de permisos
@Permit int, -- 1.- Permiso de marcacion
@Value int --Valor para permiso tipo de marcacion
AS
set nocount on

If @Type = 1 --1 Update Permission DialingMode
 begin
	 if @permit = 1 --DialingMode/PreviewPro
	 begin
		 if @Value = 0
		 begin
	   			UPDATE ccUsers SET DialingMode = @Value
				where user_id in (select value from dbo.fn_RIASplitDelimited(@users_id, ','))
				return(0)
		 end
		 if @Value = 1
		 begin
	   			UPDATE ccUsers SET  DialingMode = @Value
				where user_id in (select value from dbo.fn_RIASplitDelimited(@users_id, ','))
				return(0)
		 end
		 if @Value = 2
		 begin
	   			UPDATE ccUsers SET AllowChangeDialingMode = 1
				where user_id in (select value from dbo.fn_RIASplitDelimited(@users_id, ','))
				return(0)
		 end
		 if @Value = 3
		 begin
	   			UPDATE ccUsers SET AllowChangeDialingMode = 0
				where user_id in (select value from dbo.fn_RIASplitDelimited(@users_id, ','))
				return(0)
		 end
	end
 end

if @Type = 2 --Get Permission
begin
	return(0)
end

set nocount off