CREATE PROCEDURE [dbo].[ccsp_CWCheckMigration]
AS
BEGIN
		if not exists(select * from migrationAVRS WHERE status=0)
		begin
			return 1
		end
		else
		begin
			return 0
		end
END