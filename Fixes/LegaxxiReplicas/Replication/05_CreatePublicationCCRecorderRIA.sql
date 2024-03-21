set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '9'
use [CCRecorderRIA]

select @Version_Actual = par_valor from TREC_PARAMETROS where par_id = 30

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
	select @settingBD = par_valor from TREC_PARAMETROS where par_id = 73

	insert into @temp select id,Value from fn_RIASplitDelimited(@settingBD,'|')

	select @userNameWin = value  from @temp where id = 1
	select @passwordWin = value  from @temp where id = 2
	select @userNameSQL = value  from @temp where id = 3
	select @passwordSQL = value  from @temp where id = 4
	select @hostName = value  from @temp where id = 5

	-----agregado de credenciales WINDOWS-----
	set @jobLogin = isnull(@userNameWin,@hostName+'\SnapshotReplication')
	set @jobPassword = isnull(@passwordWin,'Nuxiba2010')

	-----agregado de credenciales SQL SERVER-----
	set @publisherLogin = isnull(@userNameSQL,'replication')
	set @publisherPassword = isnull(@passwordSQL,'replication')

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
	use master

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

	USE [CCRecorderRia]
	exec sp_changedistpublisher @publisher = @publicationServer, @property = 'working_directory', @value = @snapshotFolder

	/***********************************/
	/*** Enable replication database ***/
	/***********************************/
	use [master]
	exec sp_replicationdboption @dbname = N'CCRecorderRIA', @optname = N'merge publish', @value = N'true'


	/***********************************/
	/*** Create replication profiles ***/
	/***********************************/
	use [CCRecorderRia]

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

	if exists (select * from sys.databases where name='CCRecorderRIA')
	begin
		if not exists (select * from sys.databases where suser_sname(owner_sid)<>'sa' and name='CCRecorderRIA')
			ALTER AUTHORIZATION ON DATABASE::CCRecorderRIA TO sa
	end

	declare @retentionDay int
	set @retentionDay=3

	/*************************/
	/*** AVRSTemplatesRate ***/
	/*************************/
	use [CCRecorderRIA]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'AVRSTemplatesRate')
	BEGIN
		-- Adding the merge publication
		use [CCRecorderRIA]
		exec sp_addmergepublication @publication = N'AVRSTemplatesRate', @description = N'Merge publication of database CCRecorderRIA', @sync_mode = N'native', @retention = @retentionDay, 
		@allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = 14, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'AVRSTemplatesRate', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCRecorderRIA]
		exec sp_addmergearticle @publication = N'AVRSTemplatesRate', @article = N'RIA_FORMACALIF', @source_owner = N'dbo', @source_object = N'RIA_FORMACALIF', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'AVRSTemplatesRate', @article = N'RIA_RESULTADOSFORMA', @source_owner = N'dbo', @source_object = N'RIA_RESULTADOSFORMA', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'AVRSTemplatesRate', @article = N'RIA_FORMACALIF_CHAT', @source_owner = N'dbo', @source_object = N'RIA_FORMACALIF_CHAT', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'AVRSTemplatesRate', @article = N'RIA_RESULTADOSFORMA_CHAT', @source_owner = N'dbo', @source_object = N'RIA_RESULTADOSFORMA_CHAT', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'AVRSTemplatesRate',  @login = @publisherlogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'AVRSTemplatesRate' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'AVRSTemplatesRate', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/*********************/
	/*** AVRSTemplates ***/
	/*********************/
	use [CCRecorderRIA]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'AVRSTemplates')
	BEGIN
		-- Adding the merge publication
		use [CCRecorderRIA]
		exec sp_addmergepublication @publication = N'AVRSTemplates', @description = N'Merge publication of database CCRecorderRIA', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = 14, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'AVRSTemplates', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCRecorderRIA]
		exec sp_addmergearticle @publication = N'AVRSTemplates', @article = N'RIA_FORMATOS', @source_owner = N'dbo', @source_object = N'RIA_FORMATOS', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'AVRSTemplates', @article = N'RIA_CONCEPTOS', @source_owner = N'dbo', @source_object = N'RIA_CONCEPTOS', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'AVRSTemplates', @article = N'RIA_PREGUNTAS', @source_owner = N'dbo', @source_object = N'RIA_PREGUNTAS', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'AVRSTemplates', @article = N'RIA_RESPUESTAS', @source_owner = N'dbo', @source_object = N'RIA_RESPUESTAS', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'AVRSTemplates',  @login = @publisherlogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'AVRSTemplates' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'AVRSTemplates', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
	END

	/*********************/
	/*** AVRSRecordings ***/
	/*********************/
	use [CCRecorderRIA]
	IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'AVRSRecordings')
	BEGIN
		-- Adding the merge publication
		use [CCRecorderRIA]
		exec sp_addmergepublication @publication = N'AVRSRecordings', @description = N'Merge publication of database CCRecorderRIA', @sync_mode = N'native', @retention = @retentionDay, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = 14, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'90RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0,@generation_leveling_threshold=0
		exec sp_addpublication_snapshot @publication = N'AVRSRecordings', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publisherLogin, @publisher_password = @publisherPassword

		-- Adding articles
		use [CCRecorderRIA]
		exec sp_addmergearticle @publication = N'AVRSRecordings', @article = N'RIA_GRABACION', @source_owner = N'dbo', @source_object = N'RIA_GRABACION', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
		exec sp_addmergearticle @publication = N'AVRSRecordings', @article = N'RIA_GRABACIONCONSULTA', @source_owner = N'dbo', @source_object = N'RIA_GRABACIONCONSULTA', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000800B311, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 1, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0

		-- Add login to the PAL
		exec sp_grant_publication_access @publication = N'AVRSRecordings',  @login = @publisherlogin
	END
	IF EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = N'AVRSRecordings' and [retention]<>@retentionDay)
	BEGIN
		exec sp_changemergepublication @publication = N'AVRSRecordings', @property='retention',  @value=@retentionDay, @force_reinit_subscription=1
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
