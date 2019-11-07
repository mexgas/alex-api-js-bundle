CREATE  PROCEDURE [dbo].[trsp_AdmGetChatInfoFormatScored]
			@chat_id int,
			@id_formato int

			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

			declare @version int

			set @version = (select MAX(version) from CCRecorderRIA.dbo.RIA_FORMACALIF where id_grabacion = @chat_id and id_formato = @id_formato)
			select id_forma, fecha_calif, id_calificador, id_supervisor, id_grabacion, id_formato,total_forma,age_id, version from CCRecorderRIA.dbo.RIA_FORMACALIF where version = @version and id_grabacion = @chat_id and id_formato = @id_formato

			END