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
use master
declare @sql nvarchar(max)
DECLARE @subscriptionReportsRiaDB AS sysname,@subscriptionAVRSDB AS sysname
DECLARE @publicationCWDB as sysname,@publicationAVRSDB as sysname
SET @subscriptionReportsRiaDB = N'ccReportsRia'
SET @subscriptionAVRSDB = N'CCRecorderRIA'
SET @publicationCWDB =N'CCenterRia'
SET @publicationAVRSDB =N'CCRecorderRIA'


-- Quita las Replicas de la carpeta Replication--> Local Subscriptions
if exists(SELECT * FROM master.DBO.SYSDATABASES WHERE NAME ='ccReportsRia') begin
	begin try
	set @sql ='use [ccReportsRia]'
	exec (@sql)
	EXEC sp_removedbreplication @subscriptionReportsRiaDB
	select 'Se quito Subcriptions Local ccReportsRia'
	end try
	begin catch
		select 'No tiene Subcriptions Local ccReportsRia'
	end catch
end


if exists(SELECT * FROM master.DBO.SYSDATABASES WHERE NAME ='CCRecorderRIA') begin
	set @sql ='use [CCRecorderRIA]'
	exec (@sql)
	begin try
	EXEC sp_removedbreplication @subscriptionAVRSDB
	EXEC sp_msforeachtable @command1 = 'declare @int int set @int =object_id("?") EXEC sys.sp_identitycolumnforreplication @int, 0'
	select 'Se quito Subcriptions Local CCRecorderRIA'
	end try
	begin catch
		select 'No tiene Subcriptions Local CCRecorderRIA'
	end catch
end

if exists(SELECT * FROM master.DBO.SYSDATABASES WHERE NAME ='CCenterRia') begin
	set @sql ='use [CCenterRia]'
	exec (@sql)
	begin try
	EXEC sp_removedbreplication @publicationCWDB

	EXEC sp_msforeachtable @command1 = 'declare @int int set @int =object_id("?") EXEC sys.sp_identitycolumnforreplication @int, 0'

	select 'Se quita Publicaciones Local CCenterRia'
	end try
	begin catch
		select 'No tiene Publicaciones Local CCenterRia'
	end catch
end

if exists(SELECT * FROM master.DBO.SYSDATABASES WHERE NAME ='CCRecorderRIA') begin
	set @sql ='use [CCRecorderRIA]'
	exec (@sql)
	begin try
	EXEC sp_removedbreplication @publicationAVRSDB
	EXEC sp_msforeachtable @command1 = 'declare @int int set @int =object_id("?") EXEC sys.sp_identitycolumnforreplication @int, 0'
	select 'Se quita Publicaciones Local CCRecorderRIA'
	end try
	begin catch
		select 'No tiene Publicaciones Local CCRecorderRIA'
	end catch
end

begin try
	EXEC sp_dropdistributor @no_checks = 1, @ignore_distributor = 1;
	select 'Se quito las replicas'
end try
begin catch
	select 'No esta instalada las replicas'
end catch


if exists(SELECT * FROM master.DBO.SYSDATABASES WHERE NAME ='CCenterRia') begin
	set @sql ='use [CCenterRia]'
	exec (@sql)
	IF EXISTS (SELECT * FROM sysobjects WHERE name='migration') BEGIN
		drop table migration
	END
	IF EXISTS (SELECT * FROM sysobjects WHERE name='migrationAVRS') BEGIN
		drop table migrationAVRS
	END
end

if exists(SELECT * FROM master.DBO.SYSDATABASES WHERE NAME ='CCRecorderRia') begin
	set @sql ='use [CCRecorderRia]'
	exec (@sql)
	IF EXISTS (SELECT * FROM sysobjects WHERE name='migrationAVRSReports') BEGIN
		drop table migrationAVRSReports
	END
END

USE msdb
if exists(select * from msdb.dbo.sysjobs where name = 'CW Merge Replication') begin
	exec sp_delete_job @job_name = N'CW Merge Replication'
end
if exists(select * from msdb.dbo.sysjobs where name = 'AVRS Merge Replication') begin
	exec sp_delete_job @job_name = N'AVRS Merge Replication'
end
if exists(select * from msdb.dbo.sysjobs where name = 'AVRSReports Merge Replication') begin
	exec sp_delete_job @job_name = N'AVRSReports Merge Replication'
end
