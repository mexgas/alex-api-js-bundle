/*
Autor: Raymundo Gonzalez
Fecha: 2013/11/30
Descripcion:
	Merge Replication (Subscriptions)

Version minima requerida: 9
*/
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

	select @publicationServer = convert(nvarchar(max),par_valor)
	from TREC_PARAMETROS where par_id = 66

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

	if not exists (SELECT * FROM sysobjects WHERE name = N'sysmergepublications')
	begin
		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'AVRSCampEsp', @publisher_db = N'CCenterRia', @subscriber_type = N'Global', @subscription_priority = 1, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'AVRSCampEsp', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'AVRSGraphs', @publisher_db = N'CCenterRia', @subscriber_type = N'Global', @subscription_priority = 1, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'AVRSGraphs', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'AVRSSettings', @publisher_db = N'CCenterRia', @subscriber_type = N'Global', @subscription_priority = 1, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'AVRSSettings', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'SpecialAVRS', @publisher_db = N'CCenterRia', @subscriber_type = N'Global', @subscription_priority = 1, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'SpecialAVRS', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'Chats', @publisher_db = N'CCenterRia', @subscriber_type = N'Global', @subscription_priority = 1, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'Chats', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		
		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'OutIn', @publisher_db = N'CCenterRia', @subscriber_type = N'Global', @subscription_priority = 1, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'OutIn', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0		

		exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'ConversationMail', @publisher_db = N'CCenterRia', @subscriber_type = N'Global', @subscription_priority = 1, @description = N'', @sync_type = N'Automatic'
		exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'ConversationMail', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
	end
	else
	begin
		use [CCRecorderRIA]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'AVRSCampEsp'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'AVRSCampEsp', @publisher_db = N'CCenterRia', @subscriber_type = N'Global', @subscription_priority = 1, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'AVRSCampEsp', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [CCRecorderRIA]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'AVRSGraphs'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'AVRSGraphs', @publisher_db = N'CCenterRia', @subscriber_type = N'Global', @subscription_priority = 1, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'AVRSGraphs', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [CCRecorderRIA]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'AVRSSettings'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'AVRSSettings', @publisher_db = N'CCenterRia', @subscriber_type = N'Global', @subscription_priority = 1, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'AVRSSettings', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [CCRecorderRIA]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'SpecialAVRS'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'SpecialAVRS', @publisher_db = N'CCenterRia', @subscriber_type = N'Global', @subscription_priority = 1, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'SpecialAVRS', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end

		use [CCRecorderRIA]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'Chats'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'Chats', @publisher_db = N'CCenterRia', @subscriber_type = N'Global', @subscription_priority = 1, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'Chats', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end
		use [CCRecorderRIA]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'OutIn'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'OutIn', @publisher_db = N'CCenterRia', @subscriber_type = N'Global', @subscription_priority = 1, @description = N'', @sync_type = N'Automatic'
			exec sp_addmergepullsubscription_agent @publisher = @publicationServer, @publisher_db = N'CCenterRia', @publication = N'OutIn', @distributor = @publicationServer, @distributor_security_mode = 0, @distributor_login = @publDistLogin, @distributor_password = @publDistPassword, @enabled_for_syncmgr = N'False', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 0, @active_start_date = 0, @active_end_date = 19950101, @alt_snapshot_folder = N'', @working_directory = N'', @use_ftp = N'False', @job_login = @jobLogin, @job_password = @jobPassword, @publisher_security_mode = 0, @publisher_login = @publDistLogin, @publisher_password = @publDistPassword, @use_interactive_resolver = N'False', @dynamic_snapshot_location = null, @use_web_sync = 0
		end
		----Suscripcion para Email
		use [CCRecorderRIA]
		if not exists (select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRia' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE name = 'ConversationMail'))
		begin
			exec sp_addmergepullsubscription @publisher = @publicationServer, @publication = N'ConversationMail', @publisher_db = N'CCenterRia', @subscriber_type = N'Global', @subscription_priority = 1, @description = N'', @sync_type = N'Automatic'
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
