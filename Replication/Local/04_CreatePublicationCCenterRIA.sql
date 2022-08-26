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
	
	declare @userNameSQL nvarchar(50)
	declare @passwordSQL nvarchar(50)

	declare @publisherLogin nvarchar(max)
	declare @publisherPassword nvarchar(max)
	declare @snapshotFolder nvarchar(max)


	declare @settingBD nvarchar(100)

	declare @temp table	(id int, value nvarchar(100));
	select @settingBD = valor from ccSettings where setting_id = 176
	insert into @temp select id,Value from fn_RIASplitDelimited(@settingBD,'|')
	
	select @userNameSQL = value  from @temp where id = 3
	select @passwordSQL = value  from @temp where id = 4
	select @hostName = value  from @temp where id = 5
	

	-----Agregado de credenciales SQL SERVER-----
	set @publisherLogin = isnull(@userNameSQL,'replication')
	set @publisherPassword =  isnull(@passwordSQL,'replication')

	-----Folder compartido para las replicas-----
	set @snapshotFolder =  'C:\Centerware\ReplData2'-- '\\' + @hostName + '\ReplData\'+@publicationServer

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
			exec sp_adddistributiondb @database= N'distribution', @security_mode = 0,@login =@publisherLogin, @password =@publisherPassword 
		end

	if (select [is distribution publisher] from #distributor) = 0
		begin			
			exec sp_adddistpublisher @publisher = @publicationServer, 
			@distribution_db = N'distribution' , @security_mode =0,  @login =@publisherLogin,@password = @publisherPassword
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
	set @retentionDay=7

	/****************/
	/*** Publicaciones ***/
	/****************/
	use [CCenterRia]

	declare @publicationTable table (id int identity, publicationName varchar(100),status bit)
	declare @articleTable table (id int identity, articleName varchar(100),publicationId int,status bit)
	declare @idInt int=1

	insert into @publicationTable(publicationName,status) values(N'LogDials',0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccoLogDials',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'LogAgentesDia',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccLogAgentesDia',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'Hold',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'RiaMarkHold',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'CallsOutSource',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccoCallsOutSource',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'CallsPreviewData',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccoCallsPreviewData',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'RegProcessPreviewRecord',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'RegProcessPreviewRecord',@idInt,0)
	
	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'CallsOut',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccoCallsOut',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'CallsIn',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccCallsIn',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'DataCallIn',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'OutIn',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'cctipocalifsubout',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'cctipocalifsub',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'cctiposubcalifrel',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccCampsMovs',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'telefonosConferencia',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'telefonosTransferencia',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'messageStatus',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'Users',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccriacat_areas',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccinboundagentes',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccriaareaworkgroup',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccsupervisorcam',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccCampsAgente',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'Activity',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'cclogagentesnotready',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccloglogin',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'cccallsreject',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccLogtransfers',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccChannelTransfer',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'IVR',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ivrstructure',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ivrcallsin',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ivroptions',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'Survey',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'SurveyQuestion',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'SurveyAnswer',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'relationSurveyQuestion',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'relationQuestionAnswer',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'Catalogs',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'cctipoResultadodial',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'cctiponotready',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccodialers',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccdnis',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccstatusllamada',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'cstoprovedor',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'cstotipollamada',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'cstotarifa',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccRIARegistryLists',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccCallCost_RIA',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccEstadosAni',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccTypeProcessPreview',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'LogAgentesDia_Dialog',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccLogAgentesDia_Dialog',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'Callbacks',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccoCallbacks',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'Chats',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccriachats',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccriachatstatus',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'SpecialAVRS',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccinbound',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'cctipocalif',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccUsers',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccUsers_Consulta',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'cccamps',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccriacat_workgroup',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccriaworkgroupusers',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'cctipocalifout',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccBaseXDB',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'ccRIAWorkGroup_Calid',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccRIAWorkGroup_Calid',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'AVRSCampEsp',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccRIACampEspWG',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccCalifCamp',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccPosicion',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'AVRSGraphs',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccRIACampsGraph',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccRIAGraphics',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccRIAInboundGraph',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccRIACampEspWGConsulta',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccRIAWorkGroupUsersConsulta',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'AVRSSettings',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccSettings',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'MenuReportsRia',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccMenus',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccMenuUser',@idInt,0)
	
	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'ConversationMail',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'conversation',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'message',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'messageUnAssigned',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'Conversationtweet',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'relationMessageDispositionTwit',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'messageUnAssingedTwit',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'messageOutTwitter',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'conversationTwitter',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'searchConversationTwitter',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'messageInTwitter',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'ConversationWhatsApp',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'ccWhatsAppConversations',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccWhatsAppSpam',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccWAMessagesConversations',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'ccWhatsAppConversationsRelationship',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'contactMeanIn',@idInt,0)		
	
	declare @publicationId int,@publicationName varchar(100)
	declare @articleId int,@articleName varchar(100)

	while exists(select publicationName from @publicationTable where status=0) begin
		select top 1 @publicationName=publicationName,@publicationId=Id from @publicationTable where status=0

		IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = @publicationName) BEGIN
		-- Adding the merge publication
		exec sp_addmergepublication @publication = @publicationName, 
		@description = N'Merge publication of database CCenterRIA', 
		@sync_mode = N'native', 
		@retention = @retentionDay,
		@allow_push = N'true', 
		@allow_pull = N'true', 
		@allow_anonymous = N'true', 
		@enabled_for_internet = N'false', 
		@snapshot_in_defaultfolder = N'true',
		@compress_snapshot = N'false', 
		@ftp_port = 21, 
		@ftp_login = N'anonymous', 
		@allow_subscription_copy = N'false', 
		@add_to_active_directory = N'false',
		@dynamic_filters = N'false', 
		@conflict_retention = @retentionDay, 
		@keep_partition_changes = N'false', 
		@allow_synctoalternate = N'false', 
		@max_concurrent_merge = 0,
		@max_concurrent_dynamic_snapshots = 0, 
		@use_partition_groups = null, 
		@publication_compatibility_level = N'90RTM', 
		@replicate_ddl = 1,
		@allow_subscriber_initiated_snapshot = N'false', 
		@allow_web_synchronization = N'false', 
		@allow_partition_realignment = N'true', 
		@retention_period_unit = N'days',
		@conflict_logging = N'both', 
		@automatic_reinitialization_policy = 0,
		@generation_leveling_threshold=0


		exec sp_addpublication_snapshot @publication =@publicationName, 
		@frequency_type = 1, 
		@frequency_interval = 0, 
		@frequency_relative_interval = 0, 
		@frequency_recurrence_factor = 0, 
		@frequency_subday = 0, 
		@frequency_subday_interval = 0, 
		@active_start_time_of_day = 500, 
		@active_end_time_of_day = 235959, 
		@active_start_date = 0, 
		@active_end_date = 0, 
		@publisher_security_mode = 0,
		@publisher_login = @publisherLogin, 
		@publisher_password = @publisherPassword 		

		while exists(select articleName from @articleTable where publicationId=@publicationId and status=0) begin
			select top 1 @articleName=articleName,@articleId=id from @articleTable where publicationId=@publicationId and status=0

			-- Adding articles
			use [CCenterRia]
			exec sp_addmergearticle @publication = @publicationName, 
			@article = @articleName, 
			@source_owner = N'dbo', 
			@source_object = @articleName, 
			@type = N'table', 
			@description = N'', 
			@creation_script = null, 
			@pre_creation_cmd = N'drop', 
			@schema_option = 0x000000000C034FD1, 
			@identityrangemanagementoption = N'manual', 
			@destination_owner = N'dbo', 
			@force_reinit_subscription = 1, 
			@column_tracking = N'false', 
			@subset_filterclause = null, 
			@vertical_partition = N'false', 
			@verify_resolver_signature = 1, 
			@allow_interactive_resolver = N'false', 
			@fast_multicol_updateproc = N'true', 
			@check_permissions = 0, 
			@subscriber_upload_options = 1, 
			@delete_tracking = N'true', 
			@compensate_for_errors = N'false', 
			@stream_blob_columns = N'false', 
			@partition_options = 0

			update @articleTable set status=1 where id=@articleId 
		end	

--		-- Add login to the PAL
		exec sp_grant_publication_access @publication = @publicationName,  @login = @publisherLogin
	END

		update @publicationTable set status=1 where id=@publicationId
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