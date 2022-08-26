set nocount on
use [CCenterRia]

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
	
	declare @subscriptionServerAVRS nvarchar(max)
	select @subscriptionServerAVRS = convert(nvarchar(max),valor) from ccsettings where setting_id = 138
	
	select @subscriptionServerAVRS = substring(@subscriptionServerAVRS, 0, charindex('|',@subscriptionServerAVRS))
	------------------ INICIO SCRIPT ------------------

	if exists (select * from sys.databases where name='CCenterRia')
	begin
		if not exists (select * from sys.databases where suser_sname(owner_sid)<>'sa' and name='CCenterRia')
			ALTER AUTHORIZATION ON DATABASE::CCenterRia TO sa
	end

	if @subscriptionServerAVRS <> '' begin
		use [CCenterRia]		
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'SpecialAVRS' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'SpecialAVRS', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'ccRIAWorkGroup_Calid' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'ccRIAWorkGroup_Calid', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'AVRSCampEsp' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'AVRSCampEsp', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'AVRSGraphs' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'AVRSGraphs', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'AVRSSettings' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'AVRSSettings', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end
	
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'OutIn' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'OutIn', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end

		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'Chats' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'Chats', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end

		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'ConversationMail' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'ConversationMail', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
		end
				
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA' AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'Conversationtweet' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin

				exec sp_addmergesubscription @publication = N'Conversationtweet', @subscriber = @subscriptionServerAVRS, @subscriber_db = N'CCRecorderRIA', @subscription_type = N'pull', @subscriber_type = N'global', @subscription_priority = 1, @sync_type = N'Automatic'
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
