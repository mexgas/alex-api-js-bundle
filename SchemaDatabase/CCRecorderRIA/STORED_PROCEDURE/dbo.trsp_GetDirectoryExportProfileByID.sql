CREATE PROCEDURE [dbo].[trsp_GetDirectoryExportProfileByID]
				@id int
				AS
				BEGIN
						SELECT id, name,fields,active
						FROM RIA_DIRECTORY_EXPORT_PROFILES
						WHERE [id] = @id
				END