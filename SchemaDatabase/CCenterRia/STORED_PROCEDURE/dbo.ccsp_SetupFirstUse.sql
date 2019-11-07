CREATE PROCEDURE ccsp_SetupFirstUse
AS
if not exists (select * from master.dbo.syslogins where loginname = N'CCUser')
BEGIN
	declare @logindb nvarchar(132), @loginlang nvarchar(132) select @logindb = N'ccenter', @loginlang = N'us_english'
	if @logindb is null or not exists (select * from master.dbo.sysdatabases where name = @logindb)
		select @logindb = N'CCenter'
	if @loginlang is null or (not exists (select * from master.dbo.syslanguages where name = @loginlang) and @loginlang <> N'us_english')
		select @loginlang = @@language
	exec sp_addlogin N'CCUser', 'guess', @logindb, @loginlang
END

if not exists (select * from dbo.sysusers where name = N'CCUser' and uid < 16382)
	EXEC sp_grantdbaccess N'CCUser', N'CCUser'

exec sp_addrolemember N'db_owner', N'CCUser'