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
	select @subscriptionServer = convert(nvarchar(max),valor) from ccsettings where setting_id = 137

	/****************************************************/
	/*** Crea registro de Alias para replicas remotas ***/
	/****************************************************/

	if @subscriptionServer <> '' begin
		select @subscriptionServer = substring(@subscriptionServer, 0, charindex('|',@subscriptionServer))
	end

	------------------ INICIO SCRIPT ------------------

	if @subscriptionServer <> '' begin
		use [CCenterRia]		
		
		update subcripcionTableCCReportsRIA set status=0

		declare @publicationId int,@publicationName varchar(100)

		update subcripcionTableCCReportsRIA set status=0
	
		while exists(select publicationName from subcripcionTableCCReportsRIA where status=0) begin
			select top 1 @publicationName=publicationName,@publicationId=Id from subcripcionTableCCReportsRIA where status=0

		if not exists
			(
				select 
					1 
				from 
					dbo.syssubscriptions 
				where 
					dest_db= 'ccReportsRia' 
					AND artid in
								(
									select 
										artid 
									from 
										dbo.sysarticles 
									where
										pubid = 
												(
													select 
														pubid 
													FROM 
														dbo.syspublications 
													WHERE 
														name = @publicationName --and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()
												)
								)
					--the status and subscription_types are different on transactional publications
					--AND status <>2 
						--and subscription_type <> 2 and subscription_type <> 3
			)	
		begin
				
				exec sp_addsubscription @publication = @publicationName, 
				@subscriber = @subscriptionServer, 
				@destination_db = N'ccReportsRia', 
				@subscription_type = N'Pull', 
				@sync_type = N'automatic', 
				--@article = N'all', 
				@update_mode = N'read only', 
				@subscriber_type = 0
		end

			update subcripcionTableCCReportsRIA set status=1 where id=@publicationId
		end

	end

	------------------ FIN SCRIPT ------------------

	SELECT 'Subscriptions successfully added to the transactional publications';
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: '
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
