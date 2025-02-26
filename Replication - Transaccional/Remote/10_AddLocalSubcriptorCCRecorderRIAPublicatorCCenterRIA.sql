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

	declare @hostName nvarchar(max),@indexInstancia tinyint
	select @hostName =@@servername
	select @indexInstancia =charindex('\',@hostName )
	if @indexInstancia>0
		set @hostName = substring(@hostName , 0, charindex('\',@hostName ))

	select @publicationServer = convert(nvarchar(max),par_valor) from TREC_PARAMETROS where par_id = 66
	select @publicationServer = substring(@publicationServer, 0, charindex('|',@publicationServer))

	declare @jobLogin nvarchar(max)
	declare @jobPassword nvarchar(max)
	declare @userNameSQL nvarchar(50)
	declare @passwordSQL nvarchar(50)
	declare @userNameWin nvarchar(50)
	declare @passwordWin nvarchar(50)

	declare @publDistLogin nvarchar(max)
	declare @publDistPassword nvarchar(max)

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
	set @publDistLogin =  isnull(@userNameSQL,'replication')
	set @publDistPassword =  isnull(@passwordSQL,'replication')

	---------------- INICIO SCRIPT ----------------

	
	declare @publicationId int,@publicationName varchar(100)
	
	update publicationTableCCenterRIA set status=0

	while exists(select publicationName from publicationTableCCenterRIA where status=0) begin
		select top 1 @publicationName=publicationName,@publicationId=Id from publicationTableCCenterRIA where status=0
		use [CCRecorderRIA]
		if not exists (SELECT * FROM sysobjects WHERE name = N'syssubscriptions')
		begin
			-- Crear la suscripción transaccional (PULL)
            EXEC sp_addpullsubscription 
                @publication = @publicationName, 
                @publisher = @publicationServer, 
                @publisher_db = N'CCenterRia', 
                @subscription_type = N'pull';

            -- Configurar el Agente de Distribución
            EXEC sp_addpullsubscription_agent 
                @publisher = @publicationServer, 
                @publisher_db = N'CCenterRia', 
                @publication = @publicationName, 
                @distributor = @publicationServer, 
                @distributor_security_mode = 0, 
                @distributor_login = @publDistLogin, 
                @distributor_password = @publDistPassword, 
                @enabled_for_syncmgr = N'False', 
                @frequency_type = 1,  -- 🔥 Manual
                @job_login = @jobLogin, 
                @job_password = @jobPassword, 
                @publisher_security_mode = 0, 
                @publisher_login = @publDistLogin, 
                @publisher_password = @publDistPassword;
		end
		else begin			
			IF NOT EXISTS (SELECT * FROM dbo.syssubscriptions 
                       WHERE publication_id = (SELECT publication_id FROM dbo.syspublications 
                                               WHERE name = @publicationName) 
                       AND subscriber_db = 'CCRecorderRIA')
			begin
				-- Crear la suscripción transaccional (PULL)
            EXEC sp_addpullsubscription 
                @publication = @publicationName, 
                @publisher = @publicationServer, 
                @publisher_db = N'CCenterRia', 
                @subscription_type = N'pull';

            -- Configurar el Agente de Distribución
            EXEC sp_addpullsubscription_agent 
                @publisher = @publicationServer, 
                @publisher_db = N'CCenterRia', 
                @publication = @publicationName, 
                @distributor = @publicationServer, 
                @distributor_security_mode = 0, 
                @distributor_login = @publDistLogin, 
                @distributor_password = @publDistPassword, 
                @enabled_for_syncmgr = N'False', 
                @frequency_type = 1,  -- 🔥 Manual
                @job_login = @jobLogin, 
                @job_password = @jobPassword, 
                @publisher_security_mode = 0, 
                @publisher_login = @publDistLogin, 
                @publisher_password = @publDistPassword;
			end
		end	
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
