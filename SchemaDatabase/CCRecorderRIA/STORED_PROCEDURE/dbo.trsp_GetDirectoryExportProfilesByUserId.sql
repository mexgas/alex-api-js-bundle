--USE [CCRecorderRIA]
--GO
--/****** Object:  StoredProcedure [dbo].[trsp_GetDirectoryExportProfilesByUserId]    Script Date: 22/05/2020 01:13:42 p. m. ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
CREATE PROCEDURE [dbo].[trsp_GetDirectoryExportProfilesByUserId]
				@userID int
				AS
				BEGIN
						SELECT id, user_id, name,fields,active
						FROM RIA_DIRECTORY_EXPORT_PROFILES
						WHERE [user_id] = @userID
				END