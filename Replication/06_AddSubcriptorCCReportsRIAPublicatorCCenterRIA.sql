-----06 cccenterria

/*
Autor: Raymundo Gonzalez
Fecha: 2013/11/30
Descripcion:
	Merge Replication (Publications)

Version minima requerida: 102
*/
set nocount on

use [CCenterRia]
declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '119'


create table #temp([version] int)
insert into #temp
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

drop table #temp

if @Version_Actual >= @Version
 begin
	declare @Sql nvarchar(max)
	
	declare @subscriptionServerReportsRia nvarchar(max)
	select @subscriptionServerReportsRia = convert(nvarchar(max),valor) from ccsettings where setting_id = 137

	/****************************************************/
	/*** Crea registro de Alias para replicas remotas ***/
	/****************************************************/
	declare @name nvarchar(max)
	declare @ip nvarchar(max)
	declare @registryValue nvarchar(max)

	if @subscriptionServerReportsRia <> '' begin

		select @name = substring(@subscriptionServerReportsRia, 0, charindex('|',@subscriptionServerReportsRia))
		select @ip = substring(@subscriptionServerReportsRia, charindex('|',@subscriptionServerReportsRia) + 1, len(@subscriptionServerReportsRia))
		select @registryValue = 'DBMSSOCN,'+@ip+',1433'

		
		select @subscriptionServerReportsRia = @name
	end
	
	------------------ INICIO SCRIPT ------------------


	/******************************/
	/*** Change user dboowner *****/
	/******************************/

	if exists (select * from sys.databases where name='CCenterRia')
	begin
		if not exists (select * from sys.databases where suser_sname(owner_sid)<>'sa' and name='CCenterRia')
			ALTER AUTHORIZATION ON DATABASE::CCenterRia TO sa
	end

	if @subscriptionServerReportsRia <> '' begin
		use [CCenterRia]
		-- Adding Subscription
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'LogDials' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'LogDials', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'LogAgentesDia' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'LogAgentesDia', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'CallsOutSource' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'CallsOutSource', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'CallsOut' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'CallsOut', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'CallsIn' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'CallsIn', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'OutIn' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'OutIn', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'Users' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'Users', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'Activity' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'Activity', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'IVR' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'IVR', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'Catalogs' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'Catalogs', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'LogAgentesDia_Dialog' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'LogAgentesDia_Dialog', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'Callbacks' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'Callbacks', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'Chats' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'Chats', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'SpecialAVRS' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'SpecialAVRS', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'MenuReportsRia' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'MenuReportsRia', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'AVRSCampEsp' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'AVRSCampEsp', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end
		--nuevo agregado

		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'ConversationMail' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'ConversationMail', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
		end

		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'Conversationtweet' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'Conversationtweet', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 0, @sync_type = N'Automatic'
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
