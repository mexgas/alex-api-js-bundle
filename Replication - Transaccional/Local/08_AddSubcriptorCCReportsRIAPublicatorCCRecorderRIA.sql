set nocount on

use [CCRecorderRIA]

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '9'

select @Version_Actual = par_valor from TREC_PARAMETROS where par_id = 30

if @Version_Actual >= @Version
 begin
	declare @Sql nvarchar(max)	
	
	declare @subscriptionServer nvarchar(max)
	select @subscriptionServer = convert(nvarchar(max),par_valor) from TREC_PARAMETROS where par_id = 64
	select @subscriptionServer = substring(@subscriptionServer, 0, charindex('|',@subscriptionServer))	
	
	------------------ INICIO SCRIPT ------------------	

	if @subscriptionServer <> '' begin
		use [CCRecorderRIA]
		declare @publicationId int,@publicationName varchar(100)

		update subcripcionTableCCReportsRIA set status=0
		
		while exists(select publicationName from subcripcionTableCCReportsRIA where status=0) begin
			select top 1 @publicationName=publicationName,@publicationId=Id from subcripcionTableCCReportsRIA where status=0

			if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' 
					AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
						name = @publicationName and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 
						and subscription_type <> 2 and subscription_type <> 3) begin
				
				exec sp_addmergesubscription @publication = @publicationName, 
				@subscriber = @subscriptionServer, 
				@subscriber_db = N'ccReportsRia', 
				@subscription_type = N'pull', 
				@subscriber_type = N'local', 
				@subscription_priority = 1, 
				@sync_type = N'Automatic'
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
