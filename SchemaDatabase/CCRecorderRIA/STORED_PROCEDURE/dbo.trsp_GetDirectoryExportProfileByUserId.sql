CREATE PROCEDURE [dbo].[trsp_GetDirectoryExportProfileByUserId]
				@user_id int
				AS
				BEGIN
							select isnull(max(fields),'') from RIA_DIRECTORY_EXPORT_PROFILES where user_id = @user_id and active =1
				END