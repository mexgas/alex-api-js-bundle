CREATE PROCEDURE [dbo].[ccspGenExecute]
as
declare @dbname varchar(50), @server varchar(50)
declare @xSql varchar(200)
if @@version like '%sql server 2008%'
begin
	select @dbname = name from sys.database_files where type =1
	set @xSql='DBCC SHRINKFILE ('+@dbName+', 1) WITH NO_INFOMSGS'
	exec (@xSql)
end
else begin
	select @dbname = db_name(dbid) from master..sysprocesses where spid=@@SPID 
	set @xSql='BACKUP LOG '+@dbName+' with truncate_only'
	exec (@xSql)
end

select @server = valor from ccSettings where setting_id = 22
EXEC ccspGenCatalogos @server