/*
Autor: Raymundo Gonzalez 
Fecha: 2013/11/30
Descripcion: 
	Merge Replication (Publications)
----07 	CCenterRia
Version minima requerida: 102
*/
set nocount on
use [CCenterRia]

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '118'


create table #temp([version] int)
insert into #temp
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

drop table #temp

if @Version_Actual >= @Version
 begin
	declare @Sql nvarchar(max)
	
	declare @publicationServer nvarchar(max)
	set @publicationServer = convert(nvarchar(max),@@servername)
	
	declare @subscriptionServerAVRS nvarchar(max)	
	select @subscriptionServerAVRS = convert(nvarchar(max),valor) from ccsettings where setting_id = 138

	/****************************************************/
	/*** Crea registro de Alias para replicas remotas ***/
	/****************************************************/
	declare @name nvarchar(max)
	declare @ip nvarchar(max)
	declare @registryValue nvarchar(max)		
	
	if @subscriptionServerAVRS <> '' begin	
		select @name = substring(@subscriptionServerAVRS, 0, charindex('|',@subscriptionServerAVRS))
		select @ip = substring(@subscriptionServerAVRS, charindex('|',@subscriptionServerAVRS) + 1, len(@subscriptionServerAVRS))
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
		
		select @subscriptionServerAVRS = @name
	end
		
	/******************************************************************
	/*** Inicia los servicios necesarios para las replicas remotas ***/
	******************************************************************/	
	
	if @subscriptionServerAVRS <> '' and @publicationServer <> @subscriptionServerAVRS
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

	------------------ INICIO SCRIPT ------------------
	
	if @subscriptionServerAVRS <> '' begin
		use [CCenterRia]
		-- Adding Subscription		
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE 
			name = 'SpecialAVRS' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin					
				exec sp_addmergesubscription @publication = N'SpecialAVRS', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE 
			name = 'AVRSCampEsp' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin					
				exec sp_addmergesubscription @publication = N'AVRSCampEsp', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE 
			name = 'AVRSGraphs' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin					
				exec sp_addmergesubscription @publication = N'AVRSGraphs', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE 
			name = 'AVRSSettings' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin					
				exec sp_addmergesubscription @publication = N'AVRSSettings', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end	

		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE 
			name = 'Chats' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin					
				exec sp_addmergesubscription @publication = N'Chats', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE 
			name = 'SpecialAVRS' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin					
				exec sp_addmergesubscription @publication = N'SpecialAVRS', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE 
			name = 'OutIn' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin					
				exec sp_addmergesubscription @publication = N'OutIn', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end	

		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE 
			name = 'ConversationMail' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin					
				exec sp_addmergesubscription @publication = N'ConversationMail', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
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
