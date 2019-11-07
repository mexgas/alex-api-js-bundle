CREATE PROCEDURE [dbo].[trsp_UpdateActiveDirectoryExportProfileById]
				@id as int,
				@active as bit
				AS

				BEGIN

					update RIA_DIRECTORY_EXPORT_PROFILES
					set active = 0

					update RIA_DIRECTORY_EXPORT_PROFILES
					set active = @active
					where [id] = @id
				END