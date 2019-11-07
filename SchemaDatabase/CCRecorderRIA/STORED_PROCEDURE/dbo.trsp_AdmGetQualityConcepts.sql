-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: June 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmGetQualityConcepts]
	-- Add the parameters for the stored procedure here

@id_formato int,
@version int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

select id_concepto, num_concepto, con_descripcion from CCRecorderRIA.dbo.RIA_CONCEPTOS where id_formato = @id_formato and version = @version order by id_concepto


END