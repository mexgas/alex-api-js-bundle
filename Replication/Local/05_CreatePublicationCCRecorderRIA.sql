set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '9'
use [CCRecorderRIA]

select @Version_Actual = par_valor from TREC_PARAMETROS where par_id = 30

if @Version_Actual >= @Version
 begin
	declare @dataBaseName varchar(100)
	set @dataBaseName=N'CCRecorderRIA';

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
	select @settingBD = par_valor from TREC_PARAMETROS where par_id = 73

	insert into @temp select id,Value from fn_RIASplitDelimited(@settingBD,'|')

	
	select @userNameSQL = value  from @temp where id = 3
	select @passwordSQL = value  from @temp where id = 4
	select @hostName = value  from @temp where id = 5		

	-----agregado de credenciales SQL SERVER-----
	set @publisherLogin = isnull(@userNameSQL,'replication')
	set @publisherPassword = isnull(@passwordSQL,'replication')	
	

	declare @retentionDay int
	set @retentionDay=7

	
	declare @publicationTable table (id int identity, publicationName varchar(100),status bit)
	declare @articleTable table (id int identity, articleName varchar(100),publicationId int,status bit)
	declare @idInt int=1

	insert into @publicationTable(publicationName,status) values(N'AVRSTemplatesRate',0)
	insert into @articleTable(articleName,publicationId,status) values(N'RIA_FORMACALIF',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'RIA_RESULTADOSFORMA',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'RIA_FORMACALIF_CHAT',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'RIA_RESULTADOSFORMA_CHAT',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'AVRSTemplates',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'RIA_FORMATOS',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'RIA_CONCEPTOS',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'RIA_PREGUNTAS',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'RIA_RESPUESTAS',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'AVRSRecordings',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'RIA_GRABACION',@idInt,0)
	insert into @articleTable(articleName,publicationId,status) values(N'RIA_GRABACIONCONSULTA',@idInt,0)

	set @idInt=@idInt+1
	insert into @publicationTable(publicationName,status) values(N'AVRSRecordings',0)	
	insert into @articleTable(articleName,publicationId,status) values(N'RIA_GRABACION',@idInt,0)


	declare @publicationId int,@publicationName varchar(100)
	declare @articleId int,@articleName varchar(100)

	while exists(select publicationName from @publicationTable where status=0) begin
		select top 1 @publicationName=publicationName,@publicationId=Id from @publicationTable where status=0

		IF NOT EXISTS (SELECT * FROM dbo.sysmergepublications WHERE [name] = @publicationName) BEGIN
		-- Adding the merge publication
		exec sp_addmergepublication @publication = @publicationName, 
		@description = N'Merge publication of database CCRecorderRIA', 
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
			use [CCRecorderRIA]
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
