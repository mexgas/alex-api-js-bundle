CREATE PROCEDURE [dbo].[trsp_saveExportProfileByUserID]
				@userId  as int,
				@struct as nvarchar(255),
				@profile as nvarchar(255),
				@Id as int
				AS

				BEGIN
				SET NOCOUNT ON;

					IF @Id = 0
						Begin
							insert into RIA_ExportProfilesRecordingsManager
							([profile],[user_id],struct,active)
							values
							(@profile,@userId,@struct,0)
							select Scope_Identity()
						End
					Else
						Begin
							update RIA_ExportProfilesRecordingsManager
							set struct = @struct
							where id = @Id
						End
				END