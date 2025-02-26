set nocount on

use [CCenterRia]
declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '123'

exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual >= @Version
 begin
	declare @Sql nvarchar(max)

	 -- Declaración de credenciales y variables adicionales
    DECLARE @jobLogin NVARCHAR(MAX)
    DECLARE @jobPassword NVARCHAR(MAX)
    DECLARE @userNameSQL NVARCHAR(50)
    DECLARE @passwordSQL NVARCHAR(50)
    DECLARE @userNameWin NVARCHAR(50)
    DECLARE @passwordWin NVARCHAR(50)
	DECLARE @hostName NVARCHAR(MAX)
	
    DECLARE @publisherLogin NVARCHAR(MAX)
    DECLARE @publisherPassword NVARCHAR(MAX)    
	
	DECLARE @settingBD NVARCHAR(300)

	declare @subscriptionServer nvarchar(max)
	declare @subscriptionServerIP nvarchar(max)
	select @subscriptionServer = convert(nvarchar(max),valor) from ccsettings where setting_id = 137

	DECLARE @temp TABLE (id INT, value NVARCHAR(100));
    SELECT @settingBD = valor FROM ccSettings WHERE setting_id = 176
    INSERT INTO @temp SELECT id, Value FROM fn_RIASplitDelimited(@settingBD, '|')

    -- Asigna valores de configuración a variables
    SELECT @userNameWin = value  FROM @temp WHERE id = 1
    SELECT @passwordWin = value  FROM @temp WHERE id = 2
    SELECT @userNameSQL = value  FROM @temp WHERE id = 3
    SELECT @passwordSQL = value  FROM @temp WHERE id = 4
    SELECT @hostName = value  FROM @temp WHERE id = 5


	  -- Credenciales WINDOWS
    SET @jobLogin = ISNULL(@userNameWin, @hostName + '\SnapshotReplication')
    SET @jobPassword = ISNULL(@passwordWin, 'Nuxiba2010')

    -- Credenciales SQL SERVER
    SET @publisherLogin = ISNULL(@userNameSQL, 'replication')
    SET @publisherPassword = ISNULL(@passwordSQL, 'replication')

	/****************************************************/
	/*** Crea registro de Alias para replicas remotas ***/
	/****************************************************/

	

	if @subscriptionServer <> '' begin
		select @subscriptionServerIP =value from dbo.fn_RIASplitDelimited(@subscriptionServer,'|') where id=2
		select @subscriptionServer = substring(@subscriptionServer, 0, charindex('|',@subscriptionServer))
		
		select @subscriptionServerIP = value from dbo.fn_RIASplitDelimited(@subscriptionServer,'|') where id=2
		select @subscriptionServer= value from dbo.fn_RIASplitDelimited(@subscriptionServer,'|') where id=1
	end	

	------------------ INICIO SCRIPT ------------------

	if @subscriptionServer <> '' begin
		use [CCenterRia]		
		
		update subcripcionTableCCReportsRIA set status=0

		declare @publicationId int,@publicationName varchar(100)

		update subcripcionTableCCReportsRIA set status=0
	
		while exists(select publicationName from subcripcionTableCCReportsRIA where status=0) begin
			select top 1 @publicationName=publicationName,@publicationId=Id from subcripcionTableCCReportsRIA where status=0		

			IF NOT EXISTS (
			SELECT 1     
				FROM syspublications p
				INNER JOIN sysarticles a 
					ON p.pubid = a.pubid
				INNER JOIN syssubscriptions s 
					ON a.artid = s.artid
				where p.name=@publicationName
				and s.dest_db='ccReportsRia'

		)
			begin

			select @publicationName,@subscriptionServer
				use [CCenterRia]	

				exec sp_addsubscription 
				@publication = @publicationName, 
				@subscriber = @subscriptionServer, 
				@destination_db = N'CCReportsRIA', 
				@sync_type = N'automatic', 
				@subscription_type = N'pull', 
				@update_mode = N'read only', 
				@subscriber_type = 0, 
				@memory_optimized = 1


				exec sp_addpushsubscription_agent 
				@publication = @publicationName, 
				@subscriber = @subscriptionServer, 
				@subscriber_db = N'CCReportsRIA', 
				@job_login = @jobLogin, 
				@job_password = @jobPassword, 
				@subscriber_security_mode = 0, 
				@subscriber_login = @publisherLogin, 
				@subscriber_password = @publisherPassword, 
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
				@enabled_for_syncmgr = N'False', 
				@dts_package_location = N'Distributor'

				break;

		end

			update subcripcionTableCCReportsRIA set status=1 where id=@publicationId
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
