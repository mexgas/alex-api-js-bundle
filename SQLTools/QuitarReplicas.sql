/*
Disable Publishing and Distributor
Drop table migration in CCenterRia
Drop table migrationAVRS in CCenterRia
Drop table migrationAVRSReports in CCRecorderRia
Drop job CW Merge Replication
Drop job AVRS Merge Replication
Drop job AVRS Reports Merge Replication
*/
-- Remove replication objects from the subscription database on MYSUB.

declare @sql nvarchar(max)
DECLARE @subscriptionReportsRiaDB AS sysname,@subscriptionAVRSDB AS sysname
DECLARE @publicationCWDB as sysname,@publicationAVRSDB as sysname
SET @subscriptionReportsRiaDB = N'ccReportsRia'
SET @subscriptionAVRSDB = N'CCRecorderRIA'
SET @publicationCWDB =N'CCenterRia'
SET @publicationAVRSDB =N'CCRecorderRIA'



if exists(SELECT * FROM master.DBO.SYSDATABASES WHERE NAME ='CCenterRia') begin
	set @sql ='use [CCenterRia]
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''migration'') BEGIN
		drop table migration
	END
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''migrationAVRS'') BEGIN
		drop table migrationAVRS
	END'
	
	EXECUTE sp_executesql @sql
end


if exists(SELECT * FROM master.DBO.SYSDATABASES WHERE NAME ='CCRecorderRia') begin
	set @sql ='use [CCRecorderRia]
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''migrationAVRSReports'') BEGIN
		drop table migrationAVRSReports
	END'
	EXECUTE sp_executesql @sql
end	


-- Quita las Replicas de la carpeta Replication--> Local Subscriptions
if exists(SELECT * FROM master.DBO.SYSDATABASES WHERE NAME ='ccReportsRia') begin
	begin try
		set @sql ='use [ccReportsRia]
		EXEC sp_removedbreplication @subscriptionReportsRiaDB'
		EXECUTE sp_executesql @sql, N'@subscriptionReportsRiaDB sysname', @subscriptionReportsRiaDB = @subscriptionReportsRiaDB
	
		select 'Se quito Subcriptions Local ccReportsRia'
	end try
	begin catch
		select 'No tiene Subcriptions Local ccReportsRia'
	end catch
end


if exists(SELECT * FROM master.DBO.SYSDATABASES WHERE NAME ='CCRecorderRIA') begin
	set @sql ='use [CCRecorderRIA]
	EXEC sp_removedbreplication @subscriptionAVRSDB
	EXEC sp_msforeachtable @command1 = ''declare @int int set @int =object_id("?") EXEC sys.sp_identitycolumnforreplication @int, 0''
	'
	
	begin try
		EXECUTE sp_executesql @sql, N'@subscriptionAVRSDB sysname', @subscriptionAVRSDB = @subscriptionAVRSDB
		select 'Se quito Subcriptions Local CCRecorderRIA'
	end try
	begin catch
		select 'No tiene Subcriptions Local CCRecorderRIA'
	end catch
end

if exists(SELECT * FROM master.DBO.SYSDATABASES WHERE NAME ='CCenterRia') begin
	set @sql ='use [CCenterRia]
	EXEC sp_removedbreplication @publicationCWDB

	EXEC sp_msforeachtable @command1 = ''declare @int int set @int =object_id("?") EXEC sys.sp_identitycolumnforreplication @int, 0''
'
	
	begin try
		EXECUTE sp_executesql @sql, N'@publicationCWDB sysname', @publicationCWDB = @publicationCWDB
		select 'Se quita Publicaciones Local CCenterRia'
	end try
	begin catch
		select 'No tiene Publicaciones Local CCenterRia'
	end catch
end

if exists(SELECT * FROM master.DBO.SYSDATABASES WHERE NAME ='CCRecorderRIA') begin
	set @sql ='use [CCRecorderRIA]
	EXEC sp_removedbreplication @publicationAVRSDB
	EXEC sp_msforeachtable @command1 = ''declare @int int set @int =object_id("?") EXEC sys.sp_identitycolumnforreplication @int, 0''
	'
	
	begin try
		EXECUTE sp_executesql @sql, N'@publicationAVRSDB sysname', @publicationAVRSDB = @publicationAVRSDB
		select 'Se quita Publicaciones Local CCRecorderRIA'
	end try
	begin catch
		select 'No tiene Publicaciones Local CCRecorderRIA'
	end catch
end

begin try
	exec sp_dropdistributor @no_checks = 1
	select 'Se quito las replicas'
end try
begin catch
	select 'No esta instalada las replicas'
end catch
