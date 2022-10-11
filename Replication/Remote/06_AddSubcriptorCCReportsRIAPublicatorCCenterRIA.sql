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
		
		declare @publicationTable table (id int identity, publicationName varchar(100),status bit)	

		insert into @publicationTable(publicationName,status) values(N'LogDials',0)
		insert into @publicationTable(publicationName,status) values(N'LogAgentesDia',0)	
		insert into @publicationTable(publicationName,status) values(N'Hold',0)	
		insert into @publicationTable(publicationName,status) values(N'CallsOutSource',0)	
		insert into @publicationTable(publicationName,status) values(N'CallsPreviewData',0)	
		insert into @publicationTable(publicationName,status) values(N'RegProcessPreviewRecord',0)	
		insert into @publicationTable(publicationName,status) values(N'CallsOut',0)	
		insert into @publicationTable(publicationName,status) values(N'CallsIn',0)	
		insert into @publicationTable(publicationName,status) values(N'OutIn',0)	
		insert into @publicationTable(publicationName,status) values(N'Users',0)	
		insert into @publicationTable(publicationName,status) values(N'Activity',0)	
		insert into @publicationTable(publicationName,status) values(N'IVR',0)	
		insert into @publicationTable(publicationName,status) values(N'Catalogs',0)	
		insert into @publicationTable(publicationName,status) values(N'LogAgentesDia_Dialog',0)	
		insert into @publicationTable(publicationName,status) values(N'Callbacks',0)	
		insert into @publicationTable(publicationName,status) values(N'Chats',0)	
		insert into @publicationTable(publicationName,status) values(N'SpecialAVRS',0)	
		insert into @publicationTable(publicationName,status) values(N'ccRIAWorkGroup_Calid',0)	
		insert into @publicationTable(publicationName,status) values(N'AVRSCampEsp',0)	
		insert into @publicationTable(publicationName,status) values(N'AVRSGraphs',0)	
		insert into @publicationTable(publicationName,status) values(N'AVRSSettings',0)	
		insert into @publicationTable(publicationName,status) values(N'MenuReportsRia',0)	
		insert into @publicationTable(publicationName,status) values(N'ConversationMail',0)	
		insert into @publicationTable(publicationName,status) values(N'Conversationtweet',0)	
		insert into @publicationTable(publicationName,status) values(N'ConversationWhatsApp',0)	

		declare @publicationId int,@publicationName varchar(100)
	
		while exists(select publicationName from @publicationTable where status=0) begin
			select top 1 @publicationName=publicationName,@publicationId=Id from @publicationTable where status=0

			if not exists(select * FROM dbo.sysmergesubscriptions  WHERE db_name = 'ccReportsRia' 
					AND pubid = (select pubid FROM dbo.sysmergepublications WHERE
						name = @publicationName and UPPER(publisher)=UPPER(publishingservername()) and publisher_db=db_name()) AND status <>2 
						and subscription_type <> 2 and subscription_type <> 3) begin
				
				exec sp_addmergesubscription @publication = @publicationName, 
				@subscriber = @subscriptionServer, 
				@subscriber_db = N'ccReportsRia', 
				@subscription_type = N'pull', 
				@subscriber_type = N'local', 
				@subscription_priority = 0, 
				@sync_type = N'Automatic'
		end

			update @publicationTable set status=1 where id=@publicationId
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
