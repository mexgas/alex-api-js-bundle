-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: August 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmGetNumericAnswer_02]
	-- Add the parameters for the stored procedure here

@id_formato int,
@version int,
@id_pregunta int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
declare @id_forma as int

set @id_forma = (select id_forma from CCRecorderRIA.dbo.RIA_FORMACALIF where id_formato = @id_formato and version = @version)

select ISNULL(peso,0) from CCRecorderRIA.dbo.RIA_RESULTADOSFORMA where id_forma = @id_forma and id_pregunta = @id_pregunta


END