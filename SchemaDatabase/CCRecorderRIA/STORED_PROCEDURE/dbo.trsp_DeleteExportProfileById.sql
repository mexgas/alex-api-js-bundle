CREATE PROCEDURE [dbo].[trsp_DeleteExportProfileById]
			@id int
			AS
			BEGIN
			SET NOCOUNT ON;
					DELETE FROM  RIA_ExportProfilesRecordingsManager
					WHERE [id] = @id
			END