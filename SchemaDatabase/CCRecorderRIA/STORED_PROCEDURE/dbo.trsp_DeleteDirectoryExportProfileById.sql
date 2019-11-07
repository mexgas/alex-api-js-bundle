CREATE PROCEDURE [dbo].[trsp_DeleteDirectoryExportProfileById]
			@id int
			AS
			BEGIN
			SET NOCOUNT ON;
					DELETE
					FROM  RIA_DIRECTORY_EXPORT_PROFILES
					WHERE [id] = @id
			END