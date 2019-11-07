-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: August 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmDeleteSupervisorMarks]
	-- Add the parameters for the stored procedure here

@id_marca int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

delete from CCRecorderRIA.dbo.RIA_MARCAS where id_marca = @id_marca


END