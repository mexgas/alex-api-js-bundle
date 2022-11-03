set nocount on
use [ccReportsRia]

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '9'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual >= @Version
 begin
	declare @Sql nvarchar(max)
	declare @publicationServer nvarchar(max)

	declare @hostName nvarchar(max),@indexInstancia tinyint
	select @hostName =@@servername
	select @indexInstancia =charindex('\',@hostName )
	if @indexInstancia>0
		set @hostName = substring(@hostName , 0, charindex('\',@hostName ))

	select @publicationServer = convert(nvarchar(max),valor)
	from ccsettings where setting_id = 32

	select @publicationServer = substring(@publicationServer, 0, charindex('|',@publicationServer))
	
	declare @userNameSQL nvarchar(50)
	declare @passwordSQL nvarchar(50)	

	declare @settingBD nvarchar(100)

	declare @publDistLogin nvarchar(max)
	declare @publDistPassword nvarchar(max)

	declare @temp table  (id int, value nvarchar(100));
	select @settingBD = valor from ccSettings where setting_id = 35

	insert into @temp
	 select id,Value from fn_RIASplitDelimited(@settingBD,'|')

	
	select @userNameSQL = value  from @temp where id = 3
	select @passwordSQL = value  from @temp where id = 4
	select @hostName = value  from @temp where id = 5

	
	-----agregado de credenciales SQL SERVER-----
	set @publDistLogin = isnull(@userNameSQL,'replication')
	set @publDistPassword = isnull(@passwordSQL,'replication')


	---------------- INICIO SCRIPT ----------------	

	declare @publicationId int,@publicationName varchar(100)

	update publicationTableCCRecorderRIA set status=0
	
	while exists(select publicationName from publicationTableCCRecorderRIA where status=0) begin
		select top 1 @publicationName=publicationName,@publicationId=Id from publicationTableCCRecorderRIA where status=0
		use [ccReportsRia]
		if not exists (SELECT * FROM sysobjects WHERE name = N'sysmergepublications')
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, 
			@publication = @publicationName, 
			@publisher_db = N'CCRecorderRIA', 
			@subscriber_type = N'Local', 
			@subscription_priority = 0, 
			@description = N'', 
			@sync_type = N'Automatic'

			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, 
			@publisher_db = N'CCRecorderRIA', 
			@publication = @publicationName, 
			@distributor = @publicationServer, 
			@distributor_security_mode = 0, 
			@distributor_login = @publDistLogin, 
			@distributor_password = @publDistPassword, 
			@enabled_for_syncmgr = N'False', 
			@frequency_type = 1, 
			@frequency_interval = 0, 
			@frequency_relative_interval = 0, 
			@frequency_recurrence_factor = 0, 
			@frequency_subday = 0, 
			@frequency_subday_interval = 0, 
			@active_start_time_of_day = 0, 
			@active_end_time_of_day = 0, 
			@active_start_date = 0, 
			@active_end_date = 19950101, 
			@alt_snapshot_folder = N'', 
			@working_directory = N'', 
			@use_ftp = N'False', 			
			@publisher_security_mode = 0, 
			@publisher_login = @publDistLogin, 
			@publisher_password = @publDistPassword, 
			@use_interactive_resolver = N'False', 
			@dynamic_snapshot_location = null, 
			@use_web_sync = 0	
		end
		else begin			
			if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' 
			AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = @publicationName))
			begin
				exec sp_addmergepullsubscription @publisher = @publicationServer, 
				@publication = @publicationName, 
				@publisher_db = N'CCRecorderRIA', 
				@subscriber_type = N'Local', 
				@subscription_priority = 0, 
				@description = N'', 
				@sync_type = N'Automatic'
			
				exec sp_addmergepullsubscription_agent @publisher = @publicationServer, 
				@publisher_db = N'CCRecorderRIA', 
				@publication = @publicationName, 
				@distributor = @publicationServer, 
				@distributor_security_mode = 0, 
				@distributor_login = @publDistLogin, 
				@distributor_password = @publDistPassword, 
				@enabled_for_syncmgr = N'False', 
				@frequency_type = 1, 
				@frequency_interval = 0, 
				@frequency_relative_interval = 0, 
				@frequency_recurrence_factor = 0, 
				@frequency_subday = 0, 
				@frequency_subday_interval = 0, 
				@active_start_time_of_day = 0, 
				@active_end_time_of_day = 0, 
				@active_start_date = 0, 
				@active_end_date = 19950101, 
				@alt_snapshot_folder = N'', 
				@working_directory = N'', 
				@use_ftp = N'False', 				
				@publisher_security_mode = 0, 
				@publisher_login = @publDistLogin, 
				@publisher_password = @publDistPassword, 
				@use_interactive_resolver = N'False', 
				@dynamic_snapshot_location = null, 
				@use_web_sync = 0
			end
		end	
		update publicationTableCCRecorderRIA set status=1 where id=@publicationId
	end

	------------------ FIN SCRIPT ------------------

	select 'Merge Subscriptions Finished'
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: '
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
