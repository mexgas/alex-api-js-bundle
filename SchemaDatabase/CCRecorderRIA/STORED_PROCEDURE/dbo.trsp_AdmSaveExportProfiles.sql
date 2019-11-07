-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: Noviembre 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmSaveExportProfiles]
	-- Add the parameters for the stored procedure here

@id int,
@id_usuario int,
@campos nvarchar(255),
@active smallint,
@nombre nvarchar(255)


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

--We reset all the active status in the export profiles
update CCRecorderRIA.dbo.RIA_PERFILES_EXPORTACION set active = 0 where id_usuario = @id_usuario

IF @id = 0

Begin

Insert CCRecorderRIA.dbo.RIA_PERFILES_EXPORTACION (id_usuario,campos,active,nombre) values (@id_usuario,@campos,@active,@nombre)

End

Else
Begin


update CCRecorderRIA.dbo.RIA_PERFILES_EXPORTACION set campos=@campos, active=@active, nombre=@nombre where id=@id and id_usuario = @id_usuario

End

END