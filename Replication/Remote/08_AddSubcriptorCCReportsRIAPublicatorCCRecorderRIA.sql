set nocount on

use [CCRecorderRIA]

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '9'

select @Version_Actual = par_valor from TREC_PARAMETROS where par_id = 30

if @Version_Actual >= @Version
 begin
	declare @Sql nvarchar(max)	
	
	declare @subscriptionServerReportsRia nvarchar(max)
	select @subscriptionServerReportsRia = convert(nvarchar(max),par_valor) from TREC_PARAMETROS where par_id = 64
	select @subscriptionServerReportsRia = substring(@subscriptionServerReportsRia, 0, charindex('|',@subscriptionServerReportsRia))
	
	
	------------------ INICIO SCRIPT ------------------

	if exists (select * from sys.databases where name='CCRecorderRIA')
	begin
		if not exists (select * from sys.databases where suser_sname(owner_sid)<>'sa' and name='CCRecorderRIA')
			ALTER AUTHORIZATION ON DATABASE::CCRecorderRIA TO sa
	end

	if @subscriptionServerReportsRia <> '' begin
		use [CCRecorderRIA]
		-- Adding Subscription
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'AVRSRecordings' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'AVRSRecordings', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 1, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'AVRSTemplates' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'AVRSTemplates', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 1, @sync_type = N'Automatic'
		end
		if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia'AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
			name = 'AVRSTemplatesRate' and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 and subscription_type <> 2 and subscription_type <> 3) begin
				exec sp_addmergesubscription @publication = N'AVRSTemplatesRate', @subscriber = @subscriptionServerReportsRia, @subscriber_db = N'ccReportsRia', @subscription_type = N'pull', @subscriber_type = N'local', @subscription_priority = 1, @sync_type = N'Automatic'
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
