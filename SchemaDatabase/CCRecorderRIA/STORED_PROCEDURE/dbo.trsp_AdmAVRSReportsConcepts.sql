-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmAVRSReportsConcepts]
	-- Add the parameters for the stored procedure here

@id_formato int,
@version int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select con_descripcion from CCRecorderRIA.dbo.RIA_CONCEPTOS where id_formato = @id_formato and version = @version order by id_concepto



END