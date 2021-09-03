CREATE Procedure [dbo].[ccsp_CleanNodeBaseX]

	@option int
	AS
	BEGIN

		declare @percentage int,@setting int
		declare @top int
		declare @table table(id bigint primary key,node xml not null,dateStart datetime, status	tinyint not null)
		declare @tableNotExists table(id bigint primary key)

		set @percentage=20 --porcentaje de registros que se pasaran esta en funcion del setting 188

		select  @setting  = valor from ccSettings where setting_id = 188
		if @setting is null set @setting = 40000
		set @top=@setting/@percentage
	
		if @option = 1 begin
		
				insert into @table
				select top (@top)  A.chatId, A.node,A.dateIn, status from ccChatsNode A with(nolock) where A.status in(1,3) order by chatId
		
				insert into @tableNotExists
				select A.id from  @table A 
				left join ccChatsNodeHistory  B with(nolock)  on B.chatId=A.id 
				where B.chatId is null
		
				insert into ccChatsNodeHistory(chatId,node,dateIn,status)		
				select  A.id,A.node,A.dateStart,A.status from @table A
				inner join @tableNotExists B on A.id=B.id

				delete from ccChatsNode where chatId in(select id from @table)

		end
		else if @option = 3  begin
	
			insert into @table
			select top (@top)  A.emailId, A.node,A.dateIn,status from ccEmailNode A with(nolock) where A.status in(1,3) order by emailId
		
			insert into @tableNotExists
			select A.id from  @table A 
			left join ccEmailNodeHistory  B with(nolock)  on B.emailId=A.id 
			where B.emailId is null
		
			insert into ccEmailNodeHistory(emailId,node,dateIn,status)		
			select  A.id,A.node,A.dateStart,A.status from @table A
			inner join @tableNotExists B on A.id=B.id

			delete from ccEmailNode where emailId in(select id from @table)
		end
		else if @option = 4  begin
	
			insert into @table
			select top (@top)  A.conversationTwitterId, A.node,A.dateIn,status from ccTwitterNode A with(nolock) where A.status in(1,3) order by conversationTwitterId
		
			insert into @tableNotExists
			select A.id from  @table A 
			left join ccTwitterNodeHistory  B with(nolock)  on B.conversationTwitterId=A.id 
			where B.conversationTwitterId is null
		
			insert into ccTwitterNodeHistory(conversationTwitterId,node,dateIn,status)		
			select  A.id,A.node,A.dateStart,A.status from @table A
			inner join @tableNotExists B on A.id=B.id

			delete from ccTwitterNode where conversationTwitterId in(select id from @table)
		end

	END