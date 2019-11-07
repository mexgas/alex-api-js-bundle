CREATE PROCEDURE [dbo].[trsp_GetExportProfilesByUserID]
				@userId int
				AS
				BEGIN
				SET NOCOUNT ON;
						select id,profile,struct,active from RIA_ExportProfilesRecordingsManager where [user_id] = @userId
				END