/*
Autor: Raymundo Gonzalez
Fecha: 2014/07/09
Descripcion:
	Se modifica el SP GetReportMenus para fix en construccion de menus de reportes
	Se modifica el SP ccspRepInNotTransferred para agregar columna de short call a reporte de llamadas no transferidas
	Se modifica el SP ReportsMasterProcess para agregar sincreonizacion de suscripciones de AVRS
Version requerida: 16
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '17'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------
		
		set @process = 'GetReportMenus - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[GetReportMenus]
	@userId int,
	@activeChat tinyint,
	@activeAVRS tinyint
AS
BEGIN
	
	select menu_id,
		substring(menu_descrip, charindex(''|'', menu_descrip) + 1, len(menu_descrip)) as menu_descrip,
		nullif(parent,menu_id) as parent,Nivel,ordengral
		into #tempCCMenus from ccMenus with(nolock) 
		where type = 3 and menu_id >= 2000 and(
			(menu_id not in (3130,3131,3132,3133,3134,3135,3136,8050,8060,8061,8062,8063,8070,8071,8072,8080))
			or  (@activeChat = 1 and menu_id in (3130,3131,3132,3133,3134,3135,3136))
			or  (@activeAVRS = 1 and menu_id in (8050,8060,8061,8062,8063,8070,8071,8072,8080) ))
			order by menu_id
			

	;WITH ccMenusUserRec(Nivel, menu_descrip, menu_id, ordengral, parent)
	AS
	(
		select 
			distinct b.Nivel as Nivel,	
			b.menu_descrip as menu_descrip,
			b.menu_id as menu_id,
			b.ordengral as ordengral,
			b.parent as parent			
			from #tempCCMenus as b
			inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId and b.menu_id<>b.parent and a.type = 3
		UNION ALL
	--RECURSIViDAD
		select a.Nivel, a.menu_descrip, a.menu_id, a.ordengral, a.parent
			from #tempCCMenus a inner join ccMenusUserRec b on a.menu_id=b.parent		
	)

	select distinct Nivel,menu_descrip,menu_id,ordengral,parent into #tempCCMenusUser from ccMenusUserRec order by menu_id	
	
	select distinct A.Nivel, A.menu_descrip, A.menu_id, A.ordengral,5 filtersType from #tempCCMenusUser A	
	where  menu_id not in 
		(select distinct parent from  #tempCCMenus where Nivel=''C'' and parent not in (select distinct  A.parent from  #tempCCMenusUser A where A.Nivel=''C''))	
	order by menu_id	
		
	drop table #tempCCMenus
	drop table #tempCCMenusUser

END'

	EXEC(@Sql)
	
		set @process = 'ccspRepInNotTransferred - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccspRepInNotTransferred]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInNotTransferred with(rowlock)
	where date >= @from AND date < @to

	insert into RepInNotTransferred
	select a.cal_Inicio as [date], a.Inbound_id, 
	'''' as acd, statusCall_id, '''' as statusCall,'''' as statusCallCount,1 as [count],  b.IDArea, 
	'''' as area, 1 as wgId, ''systemTranslated_WorkGroup'' as wg
	,datepart(yyyy,cal_inicio) as [year]
	,datepart(mm,cal_inicio) as [mount]
	,datepart(dd,cal_inicio) as [day]
	,datepart(hh,cal_inicio) as [hour]
	,datepart(mi,cal_inicio) as [minutes]
	,0 as cal_id,isnull(a.cal_Ani,'''') as phone_in
	from cccallsin a 		
	left join ccInbound b
	on	b.Inbound_id = a.Inbound_id
	where cal_inicio >= @from AND cal_inicio < @to and statuscall_id in (1,2,3,4,6,7,8)
	and  b.IDArea is not null	

	update a set acdGroup = isnull(descripcion,'''')
	from RepInNotTransferred a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set callStatus = isnull(descripcion,''''), callStatus_Count = isnull(descripcion,'''') + ''_Count''
	from RepInNotTransferred a
	left join ccstatusllamada b 
	on a.callStatusId = b.statusCall_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepInNotTransferred a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'

	EXEC(@Sql)

		set @process = 'ReportsMasterProcess - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ReportsMasterProcess] as

declare @dateStart datetime
declare @delay int
declare @strDelay nvarchar(8)
declare @reportName nvarchar(100)
declare @replicationName nvarchar(100)
declare @numOfReports int
declare @numOfReplications int
declare @repDelay int
declare @repStrDelay nvarchar(8)
declare @minReplication int
declare @minReports int

set nocount on

set @dateStart = getdate()
set @delay = 0
set @strDelay = ''''
set @reportName = ''''
set @replicationName = ''''
set @numOfReports = 0
set @numOfReplications = 0
set @repDelay = 0
set @repStrDelay = ''''
set @minReplication = 0
set @minReports = 0

select @minReplication = cast(substring(valor, 0, charindex(''|'',valor)) as int)
from ccsettings
where setting_id = 28

select @minReports = cast(substring(valor, charindex(''|'',valor) + 1, len(valor)) as int)
from ccsettings
where setting_id = 28

if (@minReplication + @minReports) <> 10
begin
	set @minReplication = 300
	set @minReports = 300
end
else
begin
	set @minReplication = @minReplication * 60
	set @minReports = @minReports * 60
end

create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select [name], 0 as flag
from msdb.dbo.sysjobs
where [name] like ''%ccReportsRia- 0%''
and [name] like ''%CCenterRia%''

insert into #replications
select [name], 0 as flag
from msdb.dbo.sysjobs
where [name] like ''%ccReportsRia- 0%''
and [name] like ''%CCRecorderRia%''
order by [name]

select @numOfReplications = count(*)
from #replications with(nolock)

set @repDelay = floor(cast(@minReplication as decimal) / cast(@numOfReplications as decimal))

set @repStrDelay = STUFF(STUFF(REPLICATE(''0'',6-LEN(@repDelay)) + convert(VARCHAR(6),@repDelay),3,0,'':''),6,0,'':'')

while(select count(*) from #replications with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_start_job @job_name = @replicationName

	update #replications with(rowlock)
	set flag = 1
	where [name] = @replicationName

	waitfor delay @repStrDelay
end

drop table #replications

declare @avrsIntegration int
set @avrsIntegration = (select valor from ccSettings where setting_id = 29) 

create table #reports ([name] nvarchar(100), flag bit)

insert into #reports
select [name], 0 as flag
from msdb.dbo.sysjobs
where ([name] like ''ccsp%'' and [name] not like ''ccspRepAVRS%'')
or ([name] like ''ccspRepAVRS%'' and @avrsIntegration = 1)
order by [name]

select @numOfReports = count(*)
from #reports with(nolock)

set @delay = floor(cast(@minReports as decimal) / cast(@numOfReports as decimal))

set @strDelay = STUFF(STUFF(REPLICATE(''0'',6-LEN(@delay)) + convert(VARCHAR(6),@delay),3,0,'':''),6,0,'':'')

while(select count(*) from #reports with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @reportName = [name]
		from #reports with(nolock)
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_start_job @job_name = @reportName

	update #reports with(rowlock)
	set flag = 1
	where [name] = @reportName

	waitfor delay @strDelay
end

drop table #reports

declare @lastTenMinuteFirst datetime
declare @lastTenMinuteSecond datetime
declare @id int
declare @publisher_reinit nvarchar(max)
declare @publisher_db_reinit nvarchar(max)
declare @publication_reinit nvarchar(max)
declare @upload_first_reinit nvarchar(max)

set @lastTenMinuteFirst = dateadd(minute,-10,dateadd(minute, datepart(minute, getdate()) / 10 * 10, dateadd(hour, datediff(hour, 0,getdate()), 0)))
set @lastTenMinuteSecond = dateadd(minute,10,@lastTenMinuteFirst)

create table #reinitmergepullsubscription(
id int not null identity,
publisher nvarchar(max) not null,
publisher_db nvarchar(max)not null,
publication nvarchar(max) not null,
upload_first nvarchar(max) not null,
[status] bit not null
)

insert into #reinitmergepullsubscription
select s.name, ma.publisher_db, ma.publication, ''false'', 0
from distribution.dbo.MSmerge_history mh
left outer join distribution.dbo.MSrepl_errors me
on (mh.error_id = me.id)
left outer join distribution.dbo.MSmerge_agents ma
on (mh.agent_id = ma.id)
left outer join master.sys.servers s
on (ma.publisher_id = s.server_id)
where mh.comments like ''%You must reinitialize the subscription (without upload)%''
and me.error_code = -2147199402
and mh.time >= @lastTenMinuteFirst
and mh.time < @lastTenMinuteSecond
and ma.subscriber_db = ''ccReportsRia''
order by mh.time desc

while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
	begin
		set rowcount 1
		select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first 
		from #reinitmergepullsubscription
		where [status] = 0
		set rowcount 0

		EXEC sp_reinitmergepullsubscription @publisher = @publisher_reinit, @publisher_db = @publisher_db_reinit, @publication = @publication_reinit, @upload_first = @upload_first_reinit

		update #reinitmergepullsubscription
		set [status] = 1
		where id = @id
	end

drop table #reinitmergepullsubscription'

	EXEC(@Sql)

------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
