/*
Autor: Raymundo Gonzalez 
Fecha: 2013/11/30
Descripcion: 
	Merge Replication (Publications)
	
Version minima requerida: 9
*/
set nocount on

use [CCRecorderRIA]

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '9'

select @Version_Actual = par_valor from TREC_PARAMETROS where par_id = 30 

if @Version_Actual >= @Version
 begin
	declare @Sql nvarchar(max)
	
	declare @publicationServer nvarchar(max)
	declare @name nvarchar(max)
	declare @ip nvarchar(max)
	declare @registryValue nvarchar(max)
	
	set @publicationServer = convert(nvarchar(max),@@servername)
	
	declare @subscriptionServerReportsRia nvarchar(max)	
	select @subscriptionServerReportsRia = convert(nvarchar(max),par_valor) from TREC_PARAMETROS where par_id = 64
	select @name = substring(@subscriptionServerReportsRia, 0, charindex('|',@subscriptionServerReportsRia))
	/****************************************************/
	/*** Crea registro de Alias para replicas remotas ***/
	/****************************************************/
			
	
	if @subscriptionServerReportsRia <> '' begin	
		
		select @ip = substring(@subscriptionServerReportsRia, charindex('|',@subscriptionServerReportsRia) + 1, len(@subscriptionServerReportsRia))
		select @registryValue = 'DBMSSOCN,'+@ip+',1433'

		if @publicationServer <> @name
		begin
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
				
	end
		
	/******************************************************************
	/*** Inicia los servicios necesarios para las replicas remotas ***/
	******************************************************************/	
	
	if @subscriptionServerReportsRia <> '' and @publicationServer <> @name
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
	end		
	select @subscriptionServerReportsRia = @name
	------------------ INICIO SCRIPT ------------------
	
	if @subscriptionServerReportsRia <> '' begin
		use [CCRecorderRIA]
		-- Adding Subscription		
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE 
			name = 'AVRSRecordings' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin					
				exec sp_addmergesubscription @publication = N'AVRSRecordings', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 1, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE 
			name = 'AVRSTemplates' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin					
				exec sp_addmergesubscription @publication = N'AVRSTemplates', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 1, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE 
			name = 'AVRSTemplatesRate' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin					
				exec sp_addmergesubscription @publication = N'AVRSTemplatesRate', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 1, @sync_type = N'Automatic'
		end		
	end	
	
	------------------ FIN SCRIPT ------------------

	select 'Merge Publications Finished'
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
