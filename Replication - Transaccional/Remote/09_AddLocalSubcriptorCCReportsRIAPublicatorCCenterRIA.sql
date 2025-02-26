set nocount on
use [ccReportsRia]
declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '102'

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

	select @publicationServer = convert(nvarchar(max),valor) from ccsettings where setting_id = 31
	select @publicationServer = substring(@publicationServer, 0, charindex('|',@publicationServer))

	declare @jobLogin nvarchar(max)
	declare @jobPassword nvarchar(max)
	declare @userNameSQL nvarchar(50)
	declare @passwordSQL nvarchar(50)
	declare @userNameWin nvarchar(50)
	declare @passwordWin nvarchar(50)
	DECLARE @snapshotFolder NVARCHAR(MAX);
	

	declare @publDistLogin nvarchar(max)
	declare @publDistPassword nvarchar(max)

	declare @settingBD nvarchar(100)

	declare @temp table	(id int, value nvarchar(100));
	select @settingBD = valor from ccSettings where setting_id = 35

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
	set @publDistLogin = isnull(@userNameSQL,'replication')
	set @publDistPassword = isnull(@passwordSQL,'replication')

	SET @snapshotFolder = '\\' + @hostName + '\ReplData\' + @publicationServer;

	---------------- INICIO SCRIPT ----------------

	/******************************/
	/*** Change user dboowner *****/
	/******************************/

	if exists (select * from sys.databases where name='ccReportsRia')
	begin
		if not exists (select * from sys.databases where suser_sname(owner_sid)<>'sa' and name='ccReportsRia')
			ALTER AUTHORIZATION ON DATABASE::ccReportsRia TO sa
	end
		

	declare @publicationId int,@publicationName varchar(100)
	update publicationTableCCenterRIA set status=0
	
	while exists(select publicationName from publicationTableCCenterRIA where status=0) begin
		use [ccReportsRia]

		select top 1 @publicationName=publicationName,@publicationId=Id from publicationTableCCenterRIA where status=0
		
		select @publicationName,@publicationServer,@jobLogin,@jobPassword,@publDistLogin,@publDistPassword


		exec sp_addpullsubscription 
			@publisher = @publicationServer, 
			@publication = @publicationName, 
			@publisher_db = N'CCenterRIA', 
			@independent_agent = N'True', 
			@subscription_type = N'pull', 
			@description = N'', 
			@update_mode = N'read only', 
			@immediate_sync = 0

		exec sp_link_publication 
			@publisher = @publicationServer, 
			@publication = @publicationName, 
			@publisher_db = N'CCenterRIA', 
			@security_mode = 0, 
			@login =@publDistLogin, 
			@password = @publDistPassword

		exec sp_addpullsubscription_agent 
			@publisher = @publicationServer, 
			@publisher_db = N'CCenterRIA', 
			@publication = @publicationName, 
			@distributor = @publicationServer, 
			@distributor_security_mode = 0, 
			@distributor_login =@publDistLogin, 
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
			@working_directory = @snapshotFolder, 
			@use_ftp = N'False', 
			@job_login = @jobLogin, 
			@job_password = @jobPassword, 
			@publication_type = 0

		update publicationTableCCenterRIA set status=1 where id=@publicationId
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
