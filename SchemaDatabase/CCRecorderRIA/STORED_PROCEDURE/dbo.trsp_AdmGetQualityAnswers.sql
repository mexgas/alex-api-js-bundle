-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: June 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmGetQualityAnswers]
	-- Add the parameters for the stored procedure here

@id_pregunta int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

select id_respuesta, etiqueta, peso from CCRecorderRIA.dbo.RIA_RESPUESTAS where id_pregunta = @id_pregunta order by id_respuesta


END