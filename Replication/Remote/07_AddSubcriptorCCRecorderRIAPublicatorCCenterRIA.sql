set nocount on
use [CCenterRia]

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '123'

exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual >= @Version
 begin
	declare @Sql nvarchar(max)
	
	declare @subscriptionServer nvarchar(max)
	select @subscriptionServer = convert(nvarchar(max),valor) from ccsettings where setting_id = 138
	
	select @subscriptionServer = substring(@subscriptionServer, 0, charindex('|',@subscriptionServer))
	------------------ INICIO SCRIPT ------------------


	if @subscriptionServer <> '' begin
		use [CCenterRia]
				
		declare @publicationId int,@publicationName varchar(100)
		update subcripcionTableCCRecorderRIA set status=0
	
		while exists(select publicationName from subcripcionTableCCRecorderRIA where status=0) begin
			select top 1 @publicationName=publicationName,@publicationId=Id from subcripcionTableCCRecorderRIA where status=0

			if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'CCRecorderRIA' 
					AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
						name = @publicationName and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 
						and subscription_type <> 2 and subscription_type <> 3) begin
				
				exec sp_addmergesubscription @publication = @publicationName, 
				@subscriber = @subscriptionServer, 
				@subscriber_db = N'CCRecorderRIA', 
				@subscription_type = N'pull', 
				@subscriber_type = N'global', 
				@subscription_priority = 0, 
				@sync_type = N'Automatic'
		end

			update subcripcionTableCCRecorderRIA set status=1 where id=@publicationId
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
