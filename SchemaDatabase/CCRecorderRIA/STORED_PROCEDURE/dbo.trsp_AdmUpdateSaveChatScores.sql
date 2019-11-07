CREATE PROCEDURE [dbo].[trsp_AdmUpdateSaveChatScores]
			@id_forma int,
			@id_chat int,
			@id_calificador int,
			@id_supervisor int,
			@id_formato int,
			@total_forma int,
			@version int


			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

			Delete from CCRecorderRIA.dbo.RIA_RESULTADOSFORMA where id_forma = @id_forma

			Update CCRecorderRIA.dbo.RIA_FORMACALIF 
			set fecha_calif = GetDate(), id_calificador=@id_calificador,id_supervisor=@id_supervisor,total_forma=@total_forma, version=@version 
			where id_forma=@id_forma and id_grabacion=@id_chat and id_formato=@id_formato

			select @id_forma

			END