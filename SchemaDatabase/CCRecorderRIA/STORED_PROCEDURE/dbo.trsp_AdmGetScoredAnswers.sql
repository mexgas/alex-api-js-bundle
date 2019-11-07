-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmGetScoredAnswers]
	-- Add the parameters for the stored procedure here

@id_forma int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

select id_respuesta from CCRecorderRIA.dbo.RIA_RESULTADOSFORMA where id_forma = @id_forma


END