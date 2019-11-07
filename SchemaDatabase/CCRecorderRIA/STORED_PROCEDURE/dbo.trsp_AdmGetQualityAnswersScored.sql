CREATE PROCEDURE [dbo].[trsp_AdmGetQualityAnswersScored]
			@id_pregunta int,
			@id_respuesta int,
			@id_forma int,
			@tipo int = 1

			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

					select b.id_respuesta, b.etiquetas, a.peso 
					from CCRecorderRIA.dbo.RIA_RESPUESTAS a 
					Inner join CCRecorderRIA.dbo.RIA_RESULTADOSFORMA b
					on a.id_pregunta = @id_pregunta and a.id_respuesta = @id_respuesta  and b.id_pregunta = @id_pregunta and b.id_respuesta = @id_respuesta and b.id_forma = 
					(select ISNULL(id_forma,0) from RIA_FORMACALIF where id_forma=@id_forma and tipo=@tipo) order by a.id_respuesta

			END