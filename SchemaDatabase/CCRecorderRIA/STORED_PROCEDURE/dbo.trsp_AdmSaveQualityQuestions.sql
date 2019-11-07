-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: June 20123
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmSaveQualityQuestions]
	-- Add the parameters for the stored procedure here

@id_concepto int,
@num_pregunta int,
@tipo_pregunta int,
@enunciado_pregunta varchar(256),
@peso int,
@valor_inicial int,
@incremento int


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

insert RIA_PREGUNTAS (id_concepto,num_pregunta,id_TipoPregunta,enunciado_pregunta,peso,valor_inicial,incremento)
values (@id_concepto,@num_pregunta,@tipo_pregunta,@enunciado_pregunta,@peso,@valor_inicial,@incremento)


select CAST(SCOPE_IDENTITY() as varchar(MAX)) as id_pregunta

END