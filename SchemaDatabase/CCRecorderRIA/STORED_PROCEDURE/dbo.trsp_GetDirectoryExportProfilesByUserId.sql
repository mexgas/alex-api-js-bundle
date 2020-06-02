CREATE PROCEDURE [dbo].[trsp_GetDirectoryExportProfilesByUserId]
				@userID int
				AS
				BEGIN
						SELECT id, user_id, name,fields,active
						FROM RIA_DIRECTORY_EXPORT_PROFILES
						WHERE [user_id] = @userID
				END