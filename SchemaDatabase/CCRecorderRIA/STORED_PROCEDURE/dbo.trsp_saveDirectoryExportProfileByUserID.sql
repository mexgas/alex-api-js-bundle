CREATE PROCEDURE [dbo].[trsp_saveDirectoryExportProfileByUserID]
				@userId  as int,
				@fields as nvarchar(255),
				@name as nvarchar(255),
				@Id as int
				AS


				BEGIN
				SET NOCOUNT ON;


					IF @Id = 0
						Begin

							insert into RIA_DIRECTORY_EXPORT_PROFILES
							([name],[user_id],fields,active)
							values
							(@name,@userId,@fields,0)
							select Scope_Identity()
						End
					Else
						Begin
							update RIA_DIRECTORY_EXPORT_PROFILES
							set fields = @fields
							where id = @Id
						End
				END