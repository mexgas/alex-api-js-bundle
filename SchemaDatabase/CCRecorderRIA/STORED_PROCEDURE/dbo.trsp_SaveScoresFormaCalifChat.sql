CREATE PROCEDURE [dbo].[trsp_SaveScoresFormaCalifChat]
			@id_formato int,
			@total_weight int,
			@age_id int,
			@version int,
			@id_chat int

			AS

			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

			Insert CCRecorderRIA.dbo.RIA_FORMACALIF_CHAT (fecha_calif,id_formato,age_id,version,id_chat, total_forma)
			values
			(GetDate(),@id_formato,@age_id,@version,@id_chat, @total_weight)

			select Scope_Identity()

			END