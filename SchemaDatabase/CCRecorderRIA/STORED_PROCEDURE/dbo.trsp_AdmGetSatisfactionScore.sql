CREATE  PROCEDURE [dbo].[trsp_AdmGetSatisfactionScore]
			@id_chat as Int
			AS
			BEGIN
				SET NOCOUNT ON;
				select total_forma from RIA_FORMACALIF_CHAT where id_chat = @id_chat
			END