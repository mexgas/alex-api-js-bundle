-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: November 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmDeleteExportProfiles]
	-- Add the parameters for the stored procedure here
@id int,
@deleteAll int,
@id_usuario int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
IF @deleteAll = 1
BEGIN
Delete from CCRecorderRIA.dbo.RIA_PERFILES_EXPORTACION where id_usuario = @id_usuario
END
ELSE
BEGIN
Delete from CCRecorderRIA.dbo.RIA_PERFILES_EXPORTACION where id = @id
END

END