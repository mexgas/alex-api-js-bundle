CREATE  PROCEDURE [dbo].[trsp_SaveScoresResultFormaChat]
			@id_format int,
			@id_question int,
			@id_answer int,
			@answer_weight int,
			@label nvarchar(MAX)

			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

			Insert CCRecorderRIA.dbo.RIA_RESULTADOSFORMA_CHAT (id_forma,id_pregunta,id_respuesta,etiquetas,peso)
			values(@id_format,@id_question, @id_answer,@label,@answer_weight)

			END