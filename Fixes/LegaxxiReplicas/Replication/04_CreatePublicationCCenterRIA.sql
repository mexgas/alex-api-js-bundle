set nocount on
use [ccenterria]

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '121'

create table #temp([version] int)
insert into #temp
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

drop table #temp

if @Version_Actual >= @Version
 begin
	declare @Sql nvarchar(max)
	declare @publicationServer nvarchar(max)

	declare @hostName nvarchar(max),@indexInstancia tinyint
	select @hostName =@@servername
	select @indexInstancia =charindex('\',@hostName )
	if @indexInstancia>0
		set @hostName = substring(@hostName , 0, charindex('\',@hostName ))


	set @publicationServer = convert(nvarchar(max),@@servername)


	declare @jobLogin nvarchar(max)
	declare @jobPassword nvarchar(max)
	declare @userNameSQL nvarchar(50)
	declare @passwordSQL nvarchar(50)
	declare @userNameWin nvarchar(50)
	declare @passwordWin nvarchar(50)

	declare @publisherLogin nvarchar(max)
	declare @publisherPassword nvarchar(max)
	declare @snapshotFolder nvarchar(max)


	declare @settingBD nvarchar(100)

	declare @temp table	(id int, value nvarchar(100));
	select @settingBD = valor from ccSettings where setting_id = 176
	insert into @temp select id,Value from fn_RIASplitDelimited(@settingBD,'|')

	select @userNameWin = value  from @temp where id = 1
	select @passwordWin = value  from @temp where id = 2
	select @userNameSQL = value  from @temp where id = 3
	select @passwordSQL = value  from @temp where id = 4
	select @hostName = value  from @temp where id = 5


	-----Agregado de credenciales WINDOWS-----
	set @jobLogin = isnull(@userNameWin,@hostName+'\SnapshotReplication')
	set @jobPassword = isnull(@passwordWin,'Nuxiba2010')

	-----Agregado de credenciales SQL SERVER-----
	set @publisherLogin = isnull(@userNameSQL,'replication')
	set @publisherPassword =  isnull(@passwordSQL,'replication')

	-----Folder compartido para las replicas-----
	set @snapshotFolder = '\\' + @hostName + '\ReplData\'+@publicationServer

	/***********************************************/
	/*** Revisa la BD distribution para replicas ***/
	/***********************************************/
	declare @DefaultData nvarchar(512)
	declare @DefaultLog nvarchar(512)

	exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @DefaultData output
	exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @DefaultLog output

	declare @MasterData nvarchar(512)
	exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters', N'SqlArg0', @MasterData output
	select @MasterData=substring(@MasterData, 3, 255)
	select @MasterData=substring(@MasterData, 1, len(@MasterData) - charindex('\', reverse(@MasterData)))

	declare @MasterLog nvarchar(512)
	exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters', N'SqlArg2', @MasterLog output
	select @MasterLog=substring(@MasterLog, 3, 255)
	select @MasterLog=substring(@MasterLog, 1, len(@MasterLog) - charindex('\', reverse(@MasterLog)))

	declare @distributionMDF varchar(512)
	declare @distributionLDF varchar(512)
	declare @exists int
	set @exists = 0

	select @distributionMDF = isnull(@DefaultData, @MasterData) + '\distribution.mdf'
	select @distributionLDF = isnull(@DefaultLog, @MasterLog) + '\distribution.ldf'

	if exists (SELECT name FROM master..sysdatabases where name = 'distribution')
		select @exists = 1

	DECLARE @out INT
	EXEC xp_fileexist @distributionMDF, @out OUTPUT;
	if (@out = 1 and @exists = 0)
		begin
			exec sp_configure 'show advanced options', 1
			reconfigure
			exec sp_configure 'xp_cmdshell', 1
			reconfigure
			declare @delDistributionMDF sysname
			set @delDistributionMDF = 'del "' + @distributionMDF + '"'
			exec xp_cmdshell @delDistributionMDF, no_output
		end

	EXEC xp_fileexist @distributionLDF, @out OUTPUT;
	if (@out = 1 and @exists = 0)
		begin
			exec sp_configure 'show advanced options', 1
			reconfigure
			exec sp_configure 'xp_cmdshell', 1
			reconfigure
			declare @delDistributionLDF varchar(512)
			set @delDistributionLDF = 'del "' + @distributionLDF + '"'
			exec xp_cmdshell @delDistributionLDF, no_output
		end

	/*******************************************/
	/*** Revisa el servicio de Agente de SQL ***/
	/*******************************************/
	CREATE TABLE #SQLAgentStatus
	(
	[Status] varchar(50),
	[Timestamp] smalldatetime default (getdate())
	)

	-- Check status
	INSERT #SQLAgentStatus ([Status])
	EXEC xp_servicecontrol N'QUERYSTATE',N'SQLServerAGENT'

	IF (select replace([Status],'.','') from #SQLAgentStatus) = 'Stopped'
		-- START SQL Server Agent
		EXEC xp_servicecontrol N'START',N'SQLServerAGENT'

	drop table #SQLAgentStatus

	------------------ INICIO SCRIPT ------------------

	/***************************/
	/*** Install Distributor ***/
	/***************************/
	use [master]

	create table #distributor(
	[installed] [int] null,
	[distribution server] [sysname] null,
	[distribution db installed] [int] null,
	[is distribution publisher] [int] null,
	[has remote distribution publisher] [int] null
	)

	insert into #distributor
		exec sp_get_distributor

	if (select [installed] from #distributor) = 0
		begin
			exec sp_adddistributor @distributor = @publicationServer
		end

	if (select [distribution db installed] from #distributor) = 0
		begin
			exec sp_adddistributiondb @database= N'distribution'
		end

	if (select [is distribution publisher] from #distributor) = 0
		begin
			exec sp_adddistpublisher @publisher = @publicationServer , @distribution_db = N'distribution'
		end

	drop table #distributor

	/**************************************/
	/*** Change default Snapshot Folder ***/
	/**************************************/

	USE [CCenterRia]
	exec sp_changedistpublisher @publisher = @publicationServer, @property = 'working_directory', @value = @snapshotFolder

	/***********************************/
	/*** Enable replication database ***/
	/***********************************/
	use [master]
	exec sp_replicationdboption @dbname = N'CCenterRia', @optname = N'merge publish', @value = N'true'


	/***********************************/
	/*** Create replication profiles ***/
	/***********************************/
	use [CCenterRia]

	if not exists(SELECT * FROM msdb..MSagent_profiles  WHERE profile_name = 'Nuxiba' collate database_default AND agent_type = 3)
		exec sp_add_agent_profile @profile_name = 'Nuxiba', @profile_type = 1, @agent_type = 3, @default = 1


	if not exists(SELECT * FROM msdb..MSagent_profiles  WHERE profile_name = 'Nuxiba' collate database_default AND agent_type = 4)
		exec sp_add_agent_profile @profile_name = 'Nuxiba', @profile_type = 1, @agent_type = 4, @default = 1


	DECLARE @profileidDA AS int
	DECLARE @profileidMA AS int

	CREATE TABLE #profiles (
		profile_id int,
		profile_name sysname,
		agent_type int,
		[type] int,
		description varchar(3000),
		def_profile bit)

	INSERT INTO #profiles (profile_id, profile_name,
		agent_type, [type],description, def_profile)
		EXEC sp_help_agent_profile

	SET @profileidDA = (SELECT profile_id FROM #profiles where agent_type = 3 and profile_name = 'Nuxiba' )
	SET @profileidMA = (SELECT profile_id FROM #profiles where agent_type = 4 and profile_name = 'Nuxiba' )

	DROP TABLE #profiles

	EXEC sp_change_agent_parameter @profile_id = @profileidDA, @parameter_name = N'-QueryTimeout', @parameter_value = 3600
	EXEC sp_change_agent_parameter @profile_id = @profileidMA, @parameter_name = N'-QueryTimeout', @parameter_value = 3600

	/******************************/
	/*** Change user dboowner *****/
	/******************************/

	if exists (select * from sys.databases where name='CCenterRia')
	begin
		if not exists (select * from sys.databases where suser_sname(owner_sid)<>'sa' and name='CCenterRia')
			ALTER AUTHORIZATION ON DATABASE::CCenterRia TO sa
	end

	declare @retentionDay int
	set @retentionDay=3

	/****************/
	/*** LogDials ***/
	/****************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'LogDials')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'LogDials', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay,
		 @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true',
		 @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false',
		 @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0,
		 @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1,
		 @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days',
		 @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0


		exec sp_addpublication_snapshot @publication = N'LogDials', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'LogDials', @article = N'ccoLogDials', @source_owner = N'dbo', @source_object = N'ccoLogDials', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'LogDials',  @login = @publisherLogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'LogDials' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'LogDials', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END


	/*********************/
	/*** LogAgentesDia ***/
	/*********************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'LogAgentesDia')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'LogAgentesDia', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'LogAgentesDia', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'LogAgentesDia', @article = N'ccLogAgentesDia', @source_owner = N'dbo', @source_object = N'ccLogAgentesDia', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'LogAgentesDia',  @login = @publisherLogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'LogAgentesDia' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'LogAgentesDia', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/**********************/
	/*** Hold ***/
	/**********************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'Hold')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'Hold', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'Hold', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'Hold', @article = N'RiaMarkHold', @source_owner = N'dbo', @source_object = N'RiaMarkHold', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'Hold',  @login = @publisherLogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'Hold' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'Hold', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/**********************/
	/*** CallsOutSource ***/
	/**********************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'CallsOutSource')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'CallsOutSource', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'CallsOutSource', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'CallsOutSource', @article = N'ccoCallsOutSource', @source_owner = N'dbo', @source_object = N'ccoCallsOutSource', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'CallsOutSource',  @login = @publisherLogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'CallsOutSource' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'CallsOutSource', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

		/**********************/
	/*** CallsPreviewData ***/
	/**********************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'CallsPreviewData')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'CallsPreviewData', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'CallsPreviewData', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'CallsPreviewData', @article = N'ccoCallsPreviewData', @source_owner = N'dbo', @source_object = N'ccoCallsPreviewData', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'CallsPreviewData',  @login = @publisherLogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'CallsPreviewData' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'CallsPreviewData', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

		/**********************/
	/*** RegProcessPreviewRecord ***/
	/**********************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'RegProcessPreviewRecord')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'RegProcessPreviewRecord', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'RegProcessPreviewRecord', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'RegProcessPreviewRecord', @article = N'RegProcessPreviewRecord', @source_owner = N'dbo', @source_object = N'RegProcessPreviewRecord', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'RegProcessPreviewRecord',  @login = @publisherLogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'RegProcessPreviewRecord' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'RegProcessPreviewRecord', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/****************/
	/*** CallsOut ***/
	/****************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'CallsOut')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'CallsOut', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'CallsOut', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'CallsOut', @article = N'ccoCallsOut', @source_owner = N'dbo', @source_object = N'ccoCallsOut', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'CallsOut',  @login = @publisherLogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'CallsOut' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'CallsOut', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/***************/
	/*** CallsIn ***/
	/***************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'CallsIn')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'CallsIn', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'CallsIn', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'CallsIn', @article = N'ccCallsIn', @source_owner = N'dbo', @source_object = N'ccCallsIn', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		exec sp_addmergearticle @publication = N'CallsIn', @article = N'DataCallIn', @source_owner = N'dbo', @source_object = N'DataCallIn', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'CallsIn',  @login = @publisherLogin
	END
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'DataCallIn')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'CallsIn', @article = N'DataCallIn', @source_owner = N'dbo', @source_object = N'DataCallIn', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'CallsIn' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'CallsIn', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/****************/
	/*** OutIn ***/
	/****************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'OutIn')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'OutIn', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'OutIn', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'OutIn', @article = N'cctipocalifsubout', @source_owner = N'dbo', @source_object = N'cctipocalifsubout', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'OutIn', @article = N'cctipocalifsub', @source_owner = N'dbo', @source_object = N'cctipocalifsub', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'OutIn', @article = N'cctiposubcalifrel', @source_owner = N'dbo', @source_object = N'cctiposubcalifrel', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'OutIn', @article = N'ccCampsMovs', @source_owner = N'dbo', @source_object = N'ccCampsMovs', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'OutIn', @article = N'telefonosConferencia', @source_owner = N'dbo', @source_object = N'telefonosConferencia', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'OutIn', @article = N'telefonosTransferencia', @source_owner = N'dbo', @source_object = N'telefonosTransferencia', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'OutIn', @article = N'messageStatus', @source_owner = N'dbo', @source_object = N'messageStatus', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'OutIn',  @login = @publisherLogin
	END
	BEGIN
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'telefonosConferencia')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'OutIn', @article = N'telefonosConferencia', @source_owner = N'dbo', @source_object = N'telefonosConferencia', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'telefonosTransferencia')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'OutIn', @article = N'telefonosTransferencia', @source_owner = N'dbo', @source_object = N'telefonosTransferencia', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'messageStatus')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'OutIn', @article = N'messageStatus', @source_owner = N'dbo', @source_object = N'messageStatus', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'OutIn' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'OutIn', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/*************/
	/*** Users ***/
	/*************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'Users')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'Users', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'Users', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'Users', @article = N'ccriacat_areas', @source_owner = N'dbo', @source_object = N'ccriacat_areas', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Users', @article = N'ccinboundagentes', @source_owner = N'dbo', @source_object = N'ccinboundagentes', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Users', @article = N'ccriaareaworkgroup', @source_owner = N'dbo', @source_object = N'ccriaareaworkgroup', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Users', @article = N'ccsupervisorcam', @source_owner = N'dbo', @source_object = N'ccsupervisorcam', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Users', @article = N'ccCampsAgente', @source_owner = N'dbo', @source_object = N'ccCampsAgente', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'Users',  @login = @publisherlogin
	END
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'ccCampsAgente')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'Users', @article = N'ccCampsAgente', @source_owner = N'dbo', @source_object = N'ccCampsAgente', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'Users' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'Users', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/****************/
	/*** Activity ***/
	/****************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'Activity')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'Activity', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'Activity', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'Activity', @article = N'cclogagentesnotready', @source_owner = N'dbo', @source_object = N'cclogagentesnotready', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Activity', @article = N'ccloglogin', @source_owner = N'dbo', @source_object = N'ccloglogin', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Activity', @article = N'cccallsreject', @source_owner = N'dbo', @source_object = N'cccallsreject', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Activity', @article = N'ccLogtransfers', @source_owner = N'dbo', @source_object = N'ccLogtransfers', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Activity', @article = N'ccChannelTransfer', @source_owner = N'dbo', @source_object = N'ccChannelTransfer', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'Activity',  @login = @publisherlogin
	END
	ELSE BEGIN
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'ccChannelTransfer')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'Activity', @article = N'ccChannelTransfer', @source_owner = N'dbo', @source_object = N'ccChannelTransfer', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'Activity' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'Activity', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/***********/
	/*** IVR ***/
	/***********/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'IVR')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'IVR', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'IVR', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'IVR', @article = N'ivrstructure', @source_owner = N'dbo', @source_object = N'ivrstructure', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'IVR', @article = N'ivrcallsin', @source_owner = N'dbo', @source_object = N'ivrcallsin', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'IVR', @article = N'ivroptions', @source_owner = N'dbo', @source_object = N'ivroptions', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		exec sp_addmergearticle @publication = N'IVR', @article = N'Survey', @source_owner = N'dbo', @source_object = N'Survey', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'IVR', @article = N'SurveyQuestion', @source_owner = N'dbo', @source_object = N'SurveyQuestion', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
        exec sp_addmergearticle @publication = N'IVR', @article = N'SurveyAnswer', @source_owner = N'dbo', @source_object = N'SurveyAnswer', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
	    exec sp_addmergearticle @publication = N'IVR', @article = N'relationSurveyQuestion', @source_owner = N'dbo', @source_object = N'relationSurveyQuestion', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
        exec sp_addmergearticle @publication = N'IVR', @article = N'relationQuestionAnswer', @source_owner = N'dbo', @source_object = N'relationQuestionAnswer', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'IVR',  @login = @publisherlogin
	END
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'Survey')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'IVR', @article = N'Survey', @source_owner = N'dbo', @source_object = N'Survey', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'SurveyQuestion')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'IVR', @article = N'SurveyQuestion', @source_owner = N'dbo', @source_object = N'SurveyQuestion', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'SurveyAnswer')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'IVR', @article = N'SurveyAnswer', @source_owner = N'dbo', @source_object = N'SurveyAnswer', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'relationSurveyQuestion')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'IVR', @article = N'relationSurveyQuestion', @source_owner = N'dbo', @source_object = N'relationSurveyQuestion', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'relationQuestionAnswer')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'IVR', @article = N'relationQuestionAnswer', @source_owner = N'dbo', @source_object = N'relationQuestionAnswer', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'IVR' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'IVR', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/****************/
	/*** Catalogs ***/
	/****************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'Catalogs')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'Catalogs', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'Catalogs', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'Catalogs', @article = N'cctipoResultadodial', @source_owner = N'dbo', @source_object = N'cctipoResultadodial', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Catalogs', @article = N'cctiponotready', @source_owner = N'dbo', @source_object = N'cctiponotready', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Catalogs', @article = N'ccodialers', @source_owner = N'dbo', @source_object = N'ccodialers', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Catalogs', @article = N'ccdnis', @source_owner = N'dbo', @source_object = N'ccdnis', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Catalogs', @article = N'ccstatusllamada', @source_owner = N'dbo', @source_object = N'ccstatusllamada', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Catalogs', @article = N'cstoprovedor', @source_owner = N'dbo', @source_object = N'cstoprovedor', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Catalogs', @article = N'cstotipollamada', @source_owner = N'dbo', @source_object = N'cstotipollamada', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Catalogs', @article = N'cstotarifa', @source_owner = N'dbo', @source_object = N'cstotarifa', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Catalogs', @article = N'ccRIARegistryLists', @source_owner = N'dbo', @source_object = N'ccRIARegistryLists', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Catalogs', @article = N'ccCallCost_RIA', @source_owner = N'dbo', @source_object = N'ccCallCost_RIA', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Catalogs', @article = N'ccEstadosAni', @source_owner = N'dbo', @source_object = N'ccEstadosAni', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Catalogs', @article = N'ccTypeProcessPreview', @source_owner = N'dbo', @source_object = N'ccTypeProcessPreview', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'Catalogs',  @login = @publisherlogin
	END
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'ccRIARegistryLists')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'Catalogs', @article = N'ccRIARegistryLists', @source_owner = N'dbo', @source_object = N'ccRIARegistryLists', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'ccCallCost_RIA')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'Catalogs', @article = N'ccCallCost_RIA', @source_owner = N'dbo', @source_object = N'ccCallCost_RIA', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'ccEstadosAni')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'Catalogs', @article = N'ccEstadosAni', @source_owner = N'dbo', @source_object = N'ccEstadosAni', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'ccTypeProcessPreview')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'Catalogs', @article = N'ccTypeProcessPreview', @source_owner = N'dbo', @source_object = N'ccTypeProcessPreview', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
	END
	
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'Catalogs' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'Catalogs', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/****************************/
	/*** LogAgentesDia_Dialog ***/
	/****************************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'LogAgentesDia_Dialog')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'LogAgentesDia_Dialog', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'LogAgentesDia_Dialog', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'LogAgentesDia_Dialog', @article = N'ccLogAgentesDia_Dialog', @source_owner = N'dbo', @source_object = N'ccLogAgentesDia_Dialog', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'LogAgentesDia_Dialog',  @login = @publisherlogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'LogAgentesDia_Dialog' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'LogAgentesDia_Dialog', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/*****************/
	/*** Callbacks ***/
	/*****************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'Callbacks')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'Callbacks', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'Callbacks', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'Callbacks', @article = N'ccoCallbacks', @source_owner = N'dbo', @source_object = N'ccoCallbacks', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'Callbacks',  @login = @publisherlogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'Callbacks' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'Callbacks', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END
	/*************/
	/*** Chats ***/
	/*************/
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'Chats')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'Chats', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'Chats', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'Chats', @article = N'ccriachats', @source_owner = N'dbo', @source_object = N'ccriachats', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Chats', @article = N'ccriachatstatus', @source_owner = N'dbo', @source_object = N'ccriachatstatus', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'Chats',  @login = @publisherlogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'Chats' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'Chats', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/*******************/
	/*** SpecialAVRS ***/
	/*******************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'SpecialAVRS')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'SpecialAVRS', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'SpecialAVRS', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'SpecialAVRS', @article = N'ccinbound', @source_owner = N'dbo', @source_object = N'ccinbound', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'SpecialAVRS', @article = N'cctipocalif', @source_owner = N'dbo', @source_object = N'cctipocalif', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'SpecialAVRS', @article = N'ccUsers', @source_owner = N'dbo', @source_object = N'ccUsers', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'SpecialAVRS', @article = N'ccUsers_Consulta', @source_owner = N'dbo', @source_object = N'ccUsers_Consulta', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'SpecialAVRS', @article = N'cccamps', @source_owner = N'dbo', @source_object = N'cccamps', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'SpecialAVRS', @article = N'ccriacat_workgroup', @source_owner = N'dbo', @source_object = N'ccriacat_workgroup', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'SpecialAVRS', @article = N'ccriaworkgroupusers', @source_owner = N'dbo', @source_object = N'ccriaworkgroupusers', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0		
		exec sp_addmergearticle @publication = N'SpecialAVRS', @article = N'cctipocalifout', @source_owner = N'dbo', @source_object = N'cctipocalifout', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'SpecialAVRS', @article = N'ccBaseXDB', @source_owner = N'dbo', @source_object = N'ccBaseXDB', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'SpecialAVRS',  @login = @publisherlogin
	END
	ELSE
	BEGIN
		---Delete Add new Publications
		if exists(SELECT P.name as namePublish,Art.name nameArticle FROM dbo.sysmergepublications P inner join dbo.sysmergearticles Art on Art.pubid=P.pubid
				where Art.name = 'ccRIAWorkGroup_Calid' and P.name ='SpecialAVRS') begin
			EXEC sp_dropmergearticle     @publication = 'SpecialAVRS',     @article = 'ccRIAWorkGroup_Calid',    @force_invalidate_snapshot = 1; 
		end

		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'cctipocalifout')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'SpecialAVRS', @article = N'cctipocalifout', @source_owner = N'dbo', @source_object = N'cctipocalifout', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'ccBaseXDB')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'SpecialAVRS', @article = N'ccBaseXDB', @source_owner = N'dbo', @source_object = N'ccBaseXDB', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'ccUsers_Consulta')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'SpecialAVRS', @article = N'ccUsers_Consulta', @source_owner = N'dbo', @source_object = N'ccUsers_Consulta', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'SpecialAVRS' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'SpecialAVRS', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/****************************/
	/*** ccRIAWorkGroup_Calid ***/
	/****************************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'ccRIAWorkGroup_Calid')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'ccRIAWorkGroup_Calid', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'ccRIAWorkGroup_Calid', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		
		exec sp_addmergearticle @publication = N'ccRIAWorkGroup_Calid', @article = N'ccRIAWorkGroup_Calid', @source_owner = N'dbo', @source_object = N'ccRIAWorkGroup_Calid', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0		

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'ccRIAWorkGroup_Calid',  @login = @publisherlogin
	END	
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'ccRIAWorkGroup_Calid' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'ccRIAWorkGroup_Calid', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END



	/*******************/
	/*** AVRSCampEsp ***/
	/*******************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'AVRSCampEsp')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'AVRSCampEsp', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'AVRSCampEsp', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'AVRSCampEsp', @article = N'ccRIACampEspWG', @source_owner = N'dbo', @source_object = N'ccRIACampEspWG', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'AVRSCampEsp', @article = N'ccCalifCamp', @source_owner = N'dbo', @source_object = N'ccCalifCamp', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'AVRSCampEsp', @article = N'ccPosicion', @source_owner = N'dbo', @source_object = N'ccPosicion', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'AVRSCampEsp',  @login = @publisherlogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'AVRSCampEsp' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'AVRSCampEsp', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/******************/
	/*** AVRSGraphs ***/
	/******************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'AVRSGraphs')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'AVRSGraphs', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'AVRSGraphs', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'AVRSGraphs', @article = N'ccRIACampsGraph', @source_owner = N'dbo', @source_object = N'ccRIACampsGraph', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'AVRSGraphs', @article = N'ccRIAGraphics', @source_owner = N'dbo', @source_object = N'ccRIAGraphics', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'AVRSGraphs', @article = N'ccRIAInboundGraph', @source_owner = N'dbo', @source_object = N'ccRIAInboundGraph', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'AVRSGraphs', @article = N'ccRIACampEspWGConsulta', @source_owner = N'dbo', @source_object = N'ccRIACampEspWGConsulta', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'AVRSGraphs', @article = N'ccRIAWorkGroupUsersConsulta', @source_owner = N'dbo', @source_object = N'ccRIAWorkGroupUsersConsulta', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'AVRSGraphs',  @login = @publisherlogin
	END
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'ccRIACampEspWGConsulta')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'AVRSGraphs', @article = N'ccRIACampEspWGConsulta', @source_owner = N'dbo', @source_object = N'ccRIACampEspWGConsulta', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'ccRIAWorkGroupUsersConsulta')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'AVRSGraphs', @article = N'ccRIAWorkGroupUsersConsulta', @source_owner = N'dbo', @source_object = N'ccRIAWorkGroupUsersConsulta', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'AVRSGraphs' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'AVRSGraphs', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/********************/
	/*** AVRSSettings ***/
	/********************/
	use [CCenterRia]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'AVRSSettings')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'AVRSSettings', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'AVRSSettings', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'AVRSSettings', @article = N'ccSettings', @source_owner = N'dbo', @source_object = N'ccSettings', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'AVRSSettings',  @login = @publisherlogin
	END	
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'AVRSSettings' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'AVRSSettings', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END
	/**********************/
	/*** MenuReportsRia ***/
	/**********************/
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'MenuReportsRia')
	BEGIN
		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'MenuReportsRia', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'MenuReportsRia', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'MenuReportsRia', @article = N'ccMenus', @source_owner = N'dbo', @source_object = N'ccMenus', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'MenuReportsRia', @article = N'ccMenuUser', @source_owner = N'dbo', @source_object = N'ccMenuUser', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'MenuReportsRia',  @login = @publisherlogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'MenuReportsRia' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'MenuReportsRia', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/********************/
	/*** Conversation MAIL***/
	/********************/
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'ConversationMail')
	BEGIN

		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'ConversationMail', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'ConversationMail', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'ConversationMail', @article = N'conversation', @source_owner = N'dbo', @source_object = N'conversation', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'ConversationMail', @article = N'message', @source_owner = N'dbo', @source_object = N'message', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'ConversationMail', @article = N'messageUnAssigned', @source_owner = N'dbo', @source_object = N'messageUnAssigned', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'ConversationMail',  @login = @publisherlogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'ConversationMail' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'ConversationMail', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END
	/********************/
	/*** TWETTER***/
	/********************/

	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'Conversationtweet')
	BEGIN

		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'Conversationtweet', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'Conversationtweet', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'Conversationtweet', @article = N'relationMessageDispositionTwit', @source_owner = N'dbo', @source_object = N'relationMessageDispositionTwit', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Conversationtweet', @article = N'messageUnAssingedTwit', @source_owner = N'dbo', @source_object = N'messageUnAssingedTwit', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		exec sp_addmergearticle @publication = N'Conversationtweet', @article = N'messageOutTwitter', @source_owner = N'dbo', @source_object = N'messageOutTwitter', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Conversationtweet', @article = N'conversationTwitter', @source_owner = N'dbo', @source_object = N'conversationTwitter', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Conversationtweet', @article = N'searchConversationTwitter', @source_owner = N'dbo', @source_object = N'searchConversationTwitter', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'Conversationtweet', @article = N'messageInTwitter', @source_owner = N'dbo', @source_object = N'messageInTwitter', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0


		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'Conversationtweet',  @login = @publisherlogin
	END


	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'Conversationtweet' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'Conversationtweet', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END


	/********************/
	/*** WHATSAPP***/
	/********************/

	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'ConversationWhatsApp')
	BEGIN

		-- Adding the merge publication
		use [CCenterRia]
		exec sp_addmergepublication @publication = N'ConversationWhatsApp', @description = N'Merge publication of database CCenterRia', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = @retentionDay, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'ConversationWhatsApp', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCenterRia]
		exec sp_addmergearticle @publication = N'ConversationWhatsApp', @article = N'ccWhatsAppConversations', @source_owner = N'dbo', @source_object = N'ccWhatsAppConversations', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		
		exec sp_addmergearticle @publication = N'ConversationWhatsApp', @article = N'ccWhatsAppSpam', @source_owner = N'dbo', @source_object = N'ccWhatsAppSpam', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		exec sp_addmergearticle @publication = N'ConversationWhatsApp', @article = N'ccWAMessagesConversations', @source_owner = N'dbo', @source_object = N'ccWAMessagesConversations', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		exec sp_addmergearticle @publication = N'ConversationWhatsApp', @article = N'ccWhatsAppConversationsRelationship', @source_owner = N'dbo', @source_object = N'ccWhatsAppConversationsRelationship', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		exec sp_addmergearticle @publication = N'ConversationWhatsApp', @article = N'contactMeanIn', @source_owner = N'dbo', @source_object = N'contactMeanIn', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0	

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'ConversationWhatsApp',  @login = @publisherlogin
	END
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT * FROM dbo.sysmergearticles WHERE [name] = N'contactMeanIn')
		BEGIN
			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = N'ConversationWhatsApp', @article = N'contactMeanIn', @source_owner = N'dbo', @source_object = N'contactMeanIn', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0, @force_invalidate_snapshot = 1
		END
		
	END

	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'ConversationWhatsApp' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'ConversationWhatsApp', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

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