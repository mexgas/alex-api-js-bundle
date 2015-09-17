/*
Autor: Raymundo Gonzalez
Fecha: 2013/07/31
Descripcion: 
	Init Services Replication
	
Version minima requerida: 102
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '9'
create table #temp([version] int)

insert into #temp
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

drop table #temp


if @Version_Actual >= @Version
 begin
	exec sp_configure 'allow updates',0
	reconfigure
	
	declare @Sql nvarchar(max)
	
	declare @publicationServer nvarchar(max)
	declare @subscriptionServer nvarchar(max)
	declare @name nvarchar(max)
	declare @ip nvarchar(max)
	declare @registryValue nvarchar(max)
	
	set @subscriptionServer = convert(nvarchar(max),@@servername)
		
	select @publicationServer = convert(nvarchar(max),valor) from ccsettings where setting_id = 32
		
	select @name = substring(@publicationServer, 0, charindex('|',@publicationServer))
	
	/******************************************************************
	/*** Inicia los servicios necesarios para las replicas remotas ***/
	******************************************************************/
	if @name <> '' and @name <> @subscriptionServer
	begin
		exec sp_configure 'show advanced options', 1
		reconfigure
		exec sp_configure 'xp_cmdshell',1
		reconfigure
		exec xp_cmdshell 'sc config "RasMan" start= auto'
		exec xp_cmdshell 'sc config "RasAuto" start= auto'
		exec xp_cmdshell 'sc config "Netman" start= auto'
		exec xp_cmdshell 'sc config "RemoteAccess" start= auto'
		exec xp_cmdshell 'sc config "RpcSs" start= auto'
		exec xp_cmdshell 'sc config "SQLBrowser" start= auto'

		exec xp_cmdshell 'net start RasMan'
		exec xp_cmdshell 'net start RasAuto'
		exec xp_cmdshell 'net start Netman'
		exec xp_cmdshell 'net start RemoteAccess'
		exec xp_cmdshell 'net start RpcSs'
		exec xp_cmdshell 'net start SQLBrowser'
		
		/****************************************************/
		/*** Crea registro de Alias para replicas remotas ***/
		/****************************************************/
					
		select @ip = substring(@publicationServer, charindex('|',@publicationServer) + 1, len(@publicationServer))
		select @registryValue = 'DBMSSOCN,'+@ip+',1433'
		
		
		set @Sql = 'EXECUTE [master].[dbo].[xp_regwrite]
		@rootkey = N''HKEY_LOCAL_MACHINE''
		,@key = N''Software\Microsoft\MSSQLServer\Client\ConnectTo''
		,@value_name = ''' + @name + '''
		,@type = N''REG_SZ''
		,@value = ''' + @registryValue + ''''
		EXEC(@Sql)

		set @Sql = 'EXECUTE [master].[dbo].[xp_regwrite]
		@rootkey = N''HKEY_LOCAL_MACHINE''
		,@key = N''SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo''
		,@value_name = ''' + @name + '''
		,@type = N''REG_SZ''
		,@value = ''' + @registryValue + ''''
		EXEC(@Sql)
		
	end	

	select 'Init Services Replication'
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
