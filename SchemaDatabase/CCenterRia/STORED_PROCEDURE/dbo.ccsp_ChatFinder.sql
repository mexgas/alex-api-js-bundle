CREATE PROCEDURE [dbo].[ccsp_ChatFinder] 
@option int, 
@dateStart varchar(11),
@dateEnd varchar(11),
@acdGroup varchar(max),
@agents varchar(max),
@dispositions varchar(max),
@durationStart varchar(max),
@durationEnd varchar(max),
@chatId varchar(max),
@client varchar(max),
@domain varchar(max)
as

declare @sql nvarchar(max)

if @option = 1
begin
	set @sql = 'select chatId, isnull(b.descripcion,'''') as [acdGroup], isnull(c.description,'''') as [disposition], 
	isnull(login,'''') as [agent], chatDate, tChatting as [duration], clientName, domain
	from dbo.ccRIAChats a
	left join ccinbound b on (a.inboundId = b.inbound_id)
	left join ccTipoCalif c on (a.disposition = c.calif_id)
	left join ccusers d on (a.userId = d.user_id)
	where chatStatus = 4 '

	if @chatId <> ''
		set @sql = @sql + 'and chatId = ' + @chatId + ' '
	else
		begin
			if @dateStart <> ''
				set @sql = @sql + 'and chatDate >= ''' + @dateStart + ' 00:00:00' + ''' '

			if @dateEnd <> ''
				set @sql = @sql + 'and chatDate < ''' + @dateEnd + ' 23:59:59' + ''' '

			if @acdGroup <> ''
				set @sql = @sql + 'and a.inboundId in (' + @acdGroup + ') '

			if @agents <> ''
				set @sql = @sql + 'and a.userId in (' + @agents + ') '

			if @dispositions <> ''
				set @sql = @sql + 'and a.disposition in (' + @dispositions + ') '

			if (@durationStart <> '' and @durationEnd = '')
				set @sql = @sql + 'and tChatting >= ' + @durationStart + ' '

			if (@durationStart = '' and @durationEnd <> '')
				set @sql = @sql + 'and tChatting <= ' + @durationEnd + ' '

			if (@durationStart <> '' and @durationEnd <> '') and (convert(int,@durationStart) <= convert(int,@durationEnd))
				set @sql = @sql + 'and tChatting between ' + @durationStart + ' and ' + @durationEnd + ' '

			if @client <> ''
				set @sql = @sql + 'and clientName like ''%' + @client + '%'' '

			if @domain <> ''
				set @sql = @sql + 'and domain like ''%' + @domain + '%'' '
		end

	set @sql = @sql + 'order by chatId'

	--print (@sql)
	exec (@sql)
end