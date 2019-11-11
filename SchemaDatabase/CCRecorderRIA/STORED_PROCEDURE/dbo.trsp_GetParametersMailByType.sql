Create PROCEDURE [dbo].[trsp_GetParametersMailByType]
				@mailType int
				AS
				BEGIN
					SELECT [server],[port],[user],[pass],isnull([ssl],0)
					FROM TREC_PARAMMAIL
					where MailType = @mailType
				END