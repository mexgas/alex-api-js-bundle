CREATE PROCEDURE [dbo].[trsp_UpdateActiveExportProfileById]
				@id as int,
				@active as bit
				AS

				BEGIN

					update RIA_ExportProfilesRecordingsManager
					set active = 0

					update RIA_ExportProfilesRecordingsManager
					set active = @active
					where [id] = @id
				END