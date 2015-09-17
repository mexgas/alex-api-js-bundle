----09

/*
Autor: Raymundo Gonzalez
Fecha: 2013/11/30
Descripcion:
	Merge Replication (Subscriptions)

Version minima requerida: 9
*/
set nocount on
use [ccReportsRia]
declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '26'

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


	select @publicationServer = convert(nvarchar(max),valor)
	from ccsettings where setting_id = 31

	select @publicationServer = substring(@publicationServer, 0, charindex('|',@publicationServer))

	declare @jobLogin nvarchar(max)
	declare @jobPassword nvarchar(max)
	set @jobLogin = @hostName + '\SnapshotReplication'
	set @jobPassword = 'Nuxiba2010'

	declare @publDistLogin nvarchar(max)
	declare @publDistPassword nvarchar(max)
	set @publDistLogin = 'replication'
	set @publDistPassword = 'replication'

	---------------- INICIO SCRIPT ----------------

	/******************************/
	/*** Change user dboowner *****/
	/******************************/

	if exists (select * from sys.databases where name='ccReportsRia')
	begin
		if not exists (select * from sys.databases where suser_sname(owner_sid)<>'sa' and name='ccReportsRia')
			ALTER AUTHORIZATION ON DATABASE::ccReportsRia TO sa
	end

	if not exists (SELECT * FROM sysobjects WHERE name = N'sysmergepublications')
	begin
		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'LogDials', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'LogDials', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'LogAgentesDia', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'LogAgentesDia', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'CallsOutSource', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'CallsOutSource', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'CallsOut', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'CallsOut', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'CallsIn', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'CallsIn', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'OutIn', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'OutIn', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'Users', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'Users', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'Activity', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'Activity', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'IVR', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'IVR', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'Catalogs', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'Catalogs', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'LogAgentesDia_Dialog', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'LogAgentesDia_Dialog', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'Callbacks', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'Callbacks', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'Chats', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'Chats', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'SpecialAVRS', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'SpecialAVRS', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'MenuReportsRia', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'MenuReportsRia', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'AVRSCampEsp', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'AVRSCampEsp', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		--Suscripcion para Email

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'ConversationMail', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'ConversationMail', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0		

	end
	else
	begin
		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'LogDials'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'LogDials', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'LogDials', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'LogAgentesDia'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'LogAgentesDia', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'LogAgentesDia', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'CallsOutSource'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'CallsOutSource', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'CallsOutSource', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'CallsOut'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'CallsOut', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'CallsOut', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'CallsIn'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'CallsIn', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'CallsIn', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'OutIn'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'OutIn', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'OutIn', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'Users'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'Users', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'Users', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'Activity'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'Activity', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'Activity', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'IVR'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'IVR', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'IVR', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'Catalogs'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'Catalogs', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'Catalogs', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'LogAgentesDia_Dialog'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'LogAgentesDia_Dialog', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'LogAgentesDia_Dialog', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'Callbacks'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'Callbacks', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'Callbacks', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'Chats'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'Chats', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'Chats', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'SpecialAVRS'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'SpecialAVRS', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'SpecialAVRS', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'MenuReportsRia'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'MenuReportsRia', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'MenuReportsRia', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'AVRSCampEsp'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'AVRSCampEsp', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'AVRSCampEsp', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end
		----Suscripcion para Email

		use [ccReportsRia]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'ConversationMail'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'ConversationMail', @publisher_db = N'CCenterRia', @subscriber_type = N'Local', @subscription_priority = 0, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'ConversationMail', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end
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
