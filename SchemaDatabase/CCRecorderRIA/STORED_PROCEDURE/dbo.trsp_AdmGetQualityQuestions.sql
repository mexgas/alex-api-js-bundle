-- =============================================
-- Author:		 Javier Ruelas Rossier
-- Create date:  June 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmGetQualityQuestions]
	-- Add the parameters for the stored procedure here

@id_concepto int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

select id_pregunta, num_pregunta, id_TipoPregunta, enunciado_pregunta, peso, valor_inicial, incremento from CCRecorderRIA.dbo.RIA_PREGUNTAS where id_concepto = @id_concepto order by id_pregunta

END