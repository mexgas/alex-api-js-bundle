CREATE PROCEDURE [dbo].[ccsp_AVRSCheckMigration]
		AS
		BEGIN
				if not exists(select * from MigrationAVRSReports WHERE status=0)
				begin
					return 1
				end
				else
				begin
					return 0
				end
		END