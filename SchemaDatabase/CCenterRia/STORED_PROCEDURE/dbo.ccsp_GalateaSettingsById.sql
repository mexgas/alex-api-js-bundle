CREATE PROCEDURE [dbo].[ccsp_GalateaSettingsById]
						@Id tinyint = NULL
					AS
					BEGIN

						SET NOCOUNT ON;

						SELECT [setting_id]
								,[valor]
								,[Status]
								,[Tipo]
								,[bLoadSettings]
							FROM [dbo].[ccSettings] WITH(NOLOCK)
							WHERE (@Id IS NULL OR [setting_id]=@Id)

					END