CREATE  PROCEDURE [dbo].[trsp_AdmGetNumericAnswerChat]
			@id_formato int,
			@version int,
			@id_pregunta int,
			@id_chat int

			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here
			declare @id_forma as int

			set @id_forma = (select id_forma from CCRecorderRIA.dbo.RIA_FORMACALIF where version = @version and id_grabacion = @id_chat and id_formato = @id_formato and tipo=2)

			select ISNULL(peso,0) from CCRecorderRIA.dbo.RIA_RESULTADOSFORMA where id_forma = @id_forma and id_pregunta = @id_pregunta

			END