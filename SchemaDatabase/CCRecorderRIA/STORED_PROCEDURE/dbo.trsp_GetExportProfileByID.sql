CREATE PROCEDURE [dbo].[trsp_GetExportProfileByID]
				@id int
				AS
				BEGIN
					SELECT id,profile,struct,active
					FROM RIA_ExportProfilesRecordingsManager
					WHERE id = @id
				END