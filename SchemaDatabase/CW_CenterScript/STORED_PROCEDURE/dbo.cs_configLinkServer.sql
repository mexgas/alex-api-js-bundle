CREATE procedure [dbo].[cs_configLinkServer]
as


exec msdb.dbo.sp_configure 'show advanced options', 1
RECONFIGURE WITH OverRide
exec msdb.dbo.sp_configure 'Ad Hoc Distributed Queries', 1
RECONFIGURE WITH OverRide


EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 
EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 
EXEC master..sp_addsrvrolemember @loginame = N'ccuser', @rolename = N'sysadmin'