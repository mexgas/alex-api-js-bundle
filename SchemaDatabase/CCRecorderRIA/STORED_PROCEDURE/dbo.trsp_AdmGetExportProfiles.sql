-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: November 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmGetExportProfiles]
	-- Add the parameters for the stored procedure here
@id_usuario  int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

select id,id_usuario,campos,active,[nombre] from CCRecorderRIA.dbo.RIA_PERFILEs_EXPORTACION where id_usuario = @id_usuario order by 2

END