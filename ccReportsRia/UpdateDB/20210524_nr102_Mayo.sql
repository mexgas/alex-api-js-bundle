SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 102

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'CW-5178 Create Table ccRIACampEspWGConsulta'
		SET @sql = 'if not exists(select * from sys.tables where name=''ccRIACampEspWGConsulta'')begin

CREATE TABLE [dbo].[ccRIACampEspWGConsulta](
	[IDWG] [smallint] NOT NULL,
	[Tipo] [smallint] NOT NULL,
	[IdCampEsp] [smallint] NOT NULL	
)

end'
		EXEC(@sql)

		SET @process = 'CW-5178 DROP Create View'
		SET @sql = 'if exists (select * FROM sys.views where name = N''ccRIACampEspWGView'')
    begin
        DROP VIEW [dbo].[ccRIACampEspWGView]
    end'
		EXEC(@sql)

		SET @process = 'CW-5178 create View'
		SET @sql = 'CREATE VIEW [dbo].[ccRIACampEspWGView] AS
select A.IDWG,B.IdCampEsp,A.WGName, Tipo from ccriacat_workgroup A 
	inner join ccRIACampEspWG B on A.IDWG=B.IDWG 

union
select A.IDWG,B.IdCampEsp,A.WGName, Tipo from ccriacat_workgroup A 
	inner join ccRIACampEspWGConsulta B on A.IDWG=B.IDWG '
		EXEC(@sql)

		SET @process = 'CW-5178 ALTER SP '
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

create table #detailWorkGroup(
	IDWG int not null,
	idCampaing int not null,
	WGName varchar(45)
)

if @action = 1
begin

	insert into #detailWorkGroup
	SELECT IDWG, IdCampEsp, WGName from ccRIACampEspWGView where Tipo = 1
	 
	--Borrar lo que esta para no repetir
	delete from RepOutDispositions with(rowlock) 	where date >= @from AND date < @to

	--CTE
	;with callOut as(
	select CONVERT(smalldatetime, CONVERT(varchar(13), a.cal_inicio,121) + '':00'', 121) as date, 
		a.cam_id, a.calif_id, count(calif_id) DispAmount, user_id	
		from ccocallsout a 			
		where cal_inicio >= @from AND cal_inicio < @to and 
		a.statuscall_id = 13 and cal_manual in (0,2)	
		group by CONVERT(smalldatetime, CONVERT(varchar(13), a.cal_inicio,121) + '':00'', 121), a.cam_id, a.calif_id, user_id
		)

insert into  RepOutDispositions
	select A.date,a.cam_id, ISNULL(b.cam_descripcion,'''') as Campaign,
	a.calif_id, isnull(c.Description,''systemTranslated_Dispositionless'') as DispName, 
	isnull(c.Description,''systemTranslated_Dispositionless'')+''_Count'' as disposition_count,
    a.DispAmount as [count], A.user_id, ISNULL(d.login,'''') [login],
    isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''') as username, 
	isnull(b.IDArea,0) as IDArea, isnull(e.AreaName,'''') as areaName, 1 as wgId, ''systemTranslated_WorkGroup'' as wg,
	datepart(yyyy,date) as year, datepart(mm,date) as mounth, datepart(dd,date) as day,
	datepart(hh,date) as hour, datepart(mi,date) as min
	from callOut A
	left join cccamps b on a.cam_id = b.cam_id
	left join cctipocalifout c on A.calif_id = c.calif_id
	left join ccUserView d on a.User_id = d.User_id
	left join ccRIACat_Areas e on b.IDArea = e.IDArea

	update A set A.areaId = B.IDArea, A.area = C.AreaName
    from RepOutDispositions A
    inner join ccRIAAreaWorkGroup B on A.workgroupId = B.IDWG
    inner join ccRIACat_Areas C on C.IDArea = B.IDArea
    where [date] >= @from AND [date] < @to and areaId=0 
    
    update a set a.workgroupId = isnull(b.IDWG,0), a.wg = isnull(b.WGName, ''-'')
	from RepOutDispositions a
	left join #detailWorkGroup b	
    on a.campaignId = b.idCampaing
	where [date] >= @from AND [date] < @to

	drop table #detailWorkGroup

end'
		EXEC(@sql)


		SET @process = 'CW-5047 Eliminar procedure ccspRepCallTimeSummary'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccspRepCallTimeSummary'')
		begin
			DROP PROCEDURE ccspRepCallTimeSummary;
		end'
		EXEC(@sql)


		SET @process = 'CW-5047 Creacion de StoreProcedure ccspRepCallTimeSummary'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccspRepCallTimeSummary]
		@action AS TINYINT, 
		@from AS DATETIME = NULL, 
		@to AS DATETIME = NULL
		AS
		IF @from IS NULL
			SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

		IF @to IS NULL
			SELECT @to = getdate()

		IF @action = 1

		BEGIN
			DELETE	FROM RepCallTimeSummary WITH (ROWLOCK)		WHERE DATE >= @from AND DATE < @to
		
			IF OBJECT_ID(''tempdb..#aband'') IS NOT NULL drop table #aband;
			IF OBJECT_ID(''tempdb..#inboundTime'') IS NOT NULL drop table #inboundTime;
			IF OBJECT_ID(''tempdb..#inboundTimeMayores'') IS NOT NULL drop table #inboundTimeMayores;
			IF OBJECT_ID(''tempdb..#outboundTime'') IS NOT NULL drop table #outboundTime;
			IF OBJECT_ID(''tempdb..#outboundTimeMayores'') IS NOT NULL drop table #outboundTimeMayores;
			IF OBJECT_ID(''tempdb..#chats'') IS NOT NULL drop table #chats;
			IF OBJECT_ID(''tempdb..#chatsMayores'') IS NOT NULL drop table #chatsMayores;
			IF OBJECT_ID(''tempdb..#aux'') IS NOT NULL drop table #aux;
			IF OBJECT_ID(''tempdb..#auxMayores'') IS NOT NULL drop table #auxMayores;

		CREATE TABLE #aband([user_id] [smallint] NOT NULL
		,callDialogStart datetime not null,callDialogEnd datetime not null
		,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [cal_tWait] [INT] NULL
		,cal_id int not null,total int not null
		)

		CREATE TABLE #inboundTime([user_id] [smallint] NOT NULL
		,callDialogStart datetime not null,callDialogEnd datetime not null
		,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [cal_tDialog] [INT] NULL
		,cal_id int not null,total int not null
		)

		CREATE TABLE #inboundTimeMayores([user_id] [smallint] NOT NULL
		,callDialogStart datetime not null,callDialogEnd datetime not null
		,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [cal_tDialog] [INT] NULL
		,cal_id int not null,total int not null
		)

		CREATE TABLE #outboundTime([user_id] [smallint] NOT NULL
		,callDialogStart datetime not null,callDialogEnd datetime not null
		,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [cal_tDialog] [INT] NULL
		,cal_id int not null,total int not null
		)

		CREATE TABLE #outboundTimeMayores([user_id] [smallint] NOT NULL
		,callDialogStart datetime not null,callDialogEnd datetime not null
		,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [cal_tDialog] [INT] NULL
		,cal_id int not null,total int not null
		)

		CREATE TABLE #chats([user_id] [smallint] NOT NULL
		,chatStart datetime not null,chatEnd datetime not null, timeChat smallint not null
		,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL,chat_id int not null,total int not null
		)

		CREATE TABLE #chatsMayores([user_id] [smallint] NOT NULL
		,chatStart datetime not null,chatEnd datetime not null,timeChat smallint not null
		,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL,chat_id int not null,total int not null
		)

		CREATE TABLE #aux([user_id] [smallint] NOT NULL,TipoStatusAge_id int not null
		,auxStart datetime not null,auxEnd datetime not null, timeAux smallint not null
		,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL
		)

		CREATE TABLE #auxMayores([user_id] [smallint] NOT NULL,TipoStatusAge_id int not null
		,auxStart datetime not null,auxEnd datetime not null,timeAux smallint not null
		,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL
		)
		-------------------------Entrada-----------------------------
		;with timeCall as( --CTE
		select User_id,cal_inicio,dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_inicio) dateEnd
		,dateadd(ss,cal_tXfer+cal_tRing,cal_inicio) callDialogStart,
		dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog,cal_inicio) callDialogEnd
		,cal_tDialog,cal_id
		from ccCallsIn where cal_Inicio between @from and @to
		)

		insert into #inboundTime
		select User_id,callDialogStart,callDialogEnd,
		dbo.GetTimeGroup(callDialogStart,0),dbo.GetTimeGroup(callDialogEnd,1),cal_tDialog,cal_id,1 as total
		from timeCall

		INSERT into #inboundTimeMayores SELECT * from #inboundTime where datediff(mi,timegroup,timegroup_next)>15
		delete #inboundTime where  datediff(mi,timegroup,timegroup_next)>15

		insert into #inboundTime
		select [User_id]
		,t.callDialogStart,t.callDialogEnd, convert(varchar,th.start,121) as timegroup, convert(varchar, th.stop,121) as timegroup_next,
			dbo.TimeInterval(th.start,th.stop,t.callDialogStart,t.callDialogEnd) as [tlog seg]	 
			,cal_id
			,case when th.start > t.callDialogStart and th.stop > t.callDialogEnd then 1 else 0 end as ntotal
		from #inboundTimeMayores t
		inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		where  datediff(ss,th.start,timegroup_next)>0;
		------------------------- SALIDA --------------------------------
		;with timeCall as( --CTE
		select User_id,cal_inicio,dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_inicio) dateEnd
		,dateadd(ss,cal_tXfer+cal_tRing,cal_inicio) callDialogStart,
		dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog,cal_inicio) callDialogEnd
		,cal_tDialog,cal_id
		from ccoCallsout where cal_Inicio between @from and @to
		)

		insert into #outboundTime
		select User_id,callDialogStart,callDialogEnd,
		dbo.GetTimeGroup(callDialogStart,0),dbo.GetTimeGroup(callDialogEnd,1),cal_tDialog,cal_id,1 as total
		from timeCall

		INSERT into #outboundTimeMayores SELECT * from #outboundTime where datediff(mi,timegroup,timegroup_next)>15
		delete #outboundTime where  datediff(mi,timegroup,timegroup_next)>15

		insert into #outboundTime
		select [User_id]
		,t.callDialogStart,t.callDialogEnd, convert(varchar,th.start,121) as timegroup, convert(varchar, th.stop,121) as timegroup_next,
			dbo.TimeInterval(th.start,th.stop,t.callDialogStart,t.callDialogEnd) as [tlog seg]	 
			,cal_id
			,case when th.start > t.callDialogStart and th.stop > t.callDialogEnd then 1 else 0 end as ntotal
		from #outboundTimeMayores t
		inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		where  datediff(ss,th.start,timegroup_next)>0;
		--------------------CHATS---------------------------------------
		;with timeChats as( --CTE
		select userId,isnull(chatDate,requestDate) as chatStart,dateadd(ss,tChatting,isnull(chatDate,requestDate)) as chatEnd,tChatting,chatId
		from ccriachats where chatStatus=4 and userId>0 and requestDate between @from and @to
		)

		insert into #chats
		select userId,chatStart,chatEnd,tChatting,
		dbo.GetTimeGroup(chatStart,0),dbo.GetTimeGroup(chatEnd,1),chatId,1 as total
		from timeChats

		INSERT into #chatsMayores SELECT * from #chats where datediff(mi,timegroup,timegroup_next)>15
		delete #chats where  datediff(mi,timegroup,timegroup_next)>15


		insert into #chats
		select [user_id],t.chatStart,t.chatEnd, 
			dbo.TimeInterval(th.start,th.stop,t.chatStart,t.chatEnd) as [tChatting]	 
			,convert(datetime,th.start,121) as timegroup, convert(datetime, th.stop,121) as timegroup_next
			,chat_id
			,case when th.start > t.chatStart and th.stop > t.chatEnd then 1 else 0 end as ntotal
		from #chatsMayores t
		inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		where  datediff(ss,th.start,timegroup_next)>0;

		------------------------------AUXILIARES y DISPONIBLES--------------------------------------------
		;with timeAuxs as( --CTE
		select user_id,TipoStatusAge_id,dateadd(ss,-tStatus,fecha) as auxStart,fecha as auxEnd,tStatus
		from ccLogAgentesDia where fecha between @from and @to and TipoStatusAge_id in (2,3)
		)

		insert into #aux
		select user_id,TipoStatusAge_id,auxStart,auxEnd,tStatus,
		dbo.GetTimeGroup(auxStart,0),dbo.GetTimeGroup(auxEnd,1)
		from timeAuxs

		INSERT into #auxMayores SELECT * from #aux where datediff(mi,timegroup,timegroup_next)>15
		delete #aux where  datediff(mi,timegroup,timegroup_next)>15

		insert into #aux
		select [user_id],TipoStatusAge_id,t.auxStart,t.auxEnd, 
			dbo.TimeInterval(th.start,th.stop,t.auxStart,t.auxEnd) as [tAux]	 
			,convert(datetime,th.start,121) as timegroup, convert(datetime, th.stop,121) as timegroup_next
		from #auxMayores t
		inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		where  datediff(ss,th.start,timegroup_next)>0;
		---------------------------ABANDONADAS-------------------
		;with timeAband as( --CTE
		select User_id,cal_inicio,dateadd(ss,cal_tXfer+cal_tRing+cal_tWait+cal_tNotas,cal_inicio) dateEnd
		,dateadd(ss,cal_tXfer+cal_tRing,cal_inicio) callDialogStart,
		dateadd(ss,cal_tXfer+cal_tRing+cal_tWait,cal_inicio) callDialogEnd
		,cal_tWait,cal_id
		from ccCallsIn where cal_Inicio between @from and @to and statusCall_id in (select statusCall_id from ccstatusllamada where inAbandonConfig=1)
		)

		insert into #aband
		select User_id,callDialogStart,callDialogEnd,
		dbo.GetTimeGroup(callDialogStart,0),dbo.GetTimeGroup(callDialogEnd,1),cal_tWait,cal_id,1 as total
		from timeAband
		-------------------------------CTE''S--------------------------
		;with timeLogin as( --CTE
		select A.user_id,A.timegroup,A.timegroup_next,sum(A.tlog) as tlog,min(A.login) login,max(a.logout) logout from tmpSessionTimeGroup A
		group by A.[User_id],A.timegroup,A.timegroup_next
		)
		,callTimeGroup as( --CTE
		select A.user_id,A.timegroup,sum(cal_tDialog) as cal_tDialog,sum(total) as totalIn,avg(cal_tDialog) avgtimein from #inboundTime A
		group by A.[User_id],A.timegroup
		)
		,callTimeGroupOutbound as( --CTE
		select A.user_id,A.timegroup,sum(cal_tDialog) as cal_tDialog,sum(total) as totalIn,avg(cal_tDialog) avgtimeout from #outboundTime A
		group by A.[User_id],A.timegroup
		)
		,chatTime as( --CTE
		select A.user_id,A.timegroup,sum(timeChat) as timeChat,sum(total) as totalChat,avg(total) avgtTotal,avg(timeChat) avgttimeChat from #chats A
		group by A.[User_id],A.timegroup
		)
		,auxiliaresTime as( --CTE
		select A.user_id,A.timegroup,sum(case when A.TipoStatusAge_id=2 then timeAux else 0 end) as timeAux,
		sum(case when TipoStatusAge_id=3 then timeAux else 0 end) as timeDisp from #aux A
		group by A.timegroup,A.[User_id],A.timegroup_next
		)
		,AbandTime as( --CTE
		select A.user_id,A.timegroup,sum(total) as totalAband from #aband A
		group by A.[User_id],A.timegroup
		)
		--------------------QUERY---------------------------------------
		INSERT INTO RepCallTimeSummary
		select A.timegroup ''Fecha'',A.user_id ''ID agente''
		,u.Nombres+'' ''+u.ApellidoPaterno ''username'',u.Login ''agentName'',a.tlog ''sesionTime''
		,ISNULL(auxt.timeAux,0) ''tiemponoDisponible'',ISNULL(auxt.timeDisp,0) ''tiempoDisponible''
		,stuff(right(convert(varchar(30), A.login, 109), 14), 9, 4, '' '') ''sessionStart'',stuff(right(convert(varchar(30), A.logout, 109), 14), 9, 4, '' '') ''sessionEnd''
		,(isnull(callIn.cal_tDialog,0)+isnull(callOut.cal_tDialog,0)) ''generalDialog''
		,isnull((isnull(callIn.cal_tDialog,0)+isnull(callOut.cal_tDialog,0))/( nullif( isnull(callIn.totalIn,0)+isnull(callOut.totalIn,0),0)),0) ''avgCallTime''
		,isnull(callIn.cal_tDialog,0) ''inboundDialog'',isnull(callIn.avgtimein,0) as ''avginboundDialog''
		,isnull(callOut.cal_tDialog,0) ''outboundDialog'',isnull(callOut.avgtimeout,0) ''avgoutboundDialog''
		,isnull(chatTime.timeChat,0) as ''chatTime'',ISNULL(chatTime.avgttimeChat,0) as ''avgchatTime'',
		isnull(chatTime.totalChat,0) as ''attendedChat'',isnull(callOut.totalIn,0) as ''callsOut'',
		isnull(callIn.totalIn,0) as ''callsIn'',isnull(abant.totalAband,0) as ''abandonedCalls''
		,(isnull(callOut.totalIn,0)+isnull(callIn.totalIn,0)) ''answerCalls''
		,datepart(yyyy,A.timegroup) as [year],
		datepart(mm,A.timegroup) as [month],
		datepart(dd,A.timegroup) as [day],
		datepart(hh,A.timegroup) as [hour],
		datepart(mi,A.timegroup) as [minutes]
		from timeLogin A
		left join callTimeGroup callIn on A.user_id=callIn.user_id and A.timegroup=callIn.timegroup
		left join callTimeGroupOutbound callOut on A.user_id=callOut.user_id and A.timegroup=callOut.timegroup
		left join chatTime chatTime on A.user_id=chatTime.user_id and A.timegroup=chatTime.timegroup
		left join auxiliaresTime auxt on A.user_id=auxt.user_id and A.timegroup=auxt.timegroup
		left join ccUserView u on A.user_id=u.User_id
		left join AbandTime abant on A.timegroup=abant.timegroup
		order by Fecha,[ID agente]

		IF OBJECT_ID(''tempdb..#aband'') IS NOT NULL drop table #aband;
		IF OBJECT_ID(''tempdb..#inboundTime'') IS NOT NULL drop table #inboundTime;
		IF OBJECT_ID(''tempdb..#inboundTimeMayores'') IS NOT NULL drop table #inboundTimeMayores;
		IF OBJECT_ID(''tempdb..#outboundTime'') IS NOT NULL drop table #outboundTime;
		IF OBJECT_ID(''tempdb..#outboundTimeMayores'') IS NOT NULL drop table #outboundTimeMayores;
		IF OBJECT_ID(''tempdb..#chats'') IS NOT NULL drop table #chats;
		IF OBJECT_ID(''tempdb..#chatsMayores'') IS NOT NULL drop table #chatsMayores;
		IF OBJECT_ID(''tempdb..#aux'') IS NOT NULL drop table #aux;
		IF OBJECT_ID(''tempdb..#auxMayores'') IS NOT NULL drop table #auxMayores;
	
		END'
		EXEC(@sql)

		SET @process = 'CW-5047 Creacion de tabla RepCallTimeSummary'
		SET @sql = 'if not exists (SELECT * FROM sys.tables WHERE name=N''RepCallTimeSummary'')
		begin
			CREATE TABLE [dbo].[RepCallTimeSummary](
				[date] [datetime] NOT NULL,
				[userId] [smallint] NOT NULL,
				[user] [varchar] (255) NOT NULL,
				[Agent] [varchar] (255) NOT NULL,
				[sessionTime] [int] NOT NULL,
				[unavailableTime] [smallint] NOT NULL,
				[TiempoDispo] [smallint] NOT NULL,
				[loginTime] [varchar] (20) NOT NULL,
				[logoutTime] [varchar] (20)NOT NULL,
				[genDialogTime] [int] NOT NULL,
				[avgCallTime] [int] NOT NULL,
				[inboundTime] [int] NOT NULL,
				[avginboundTime] [int] NOT NULL,
				[outboundTime] [int] NOT NULL,
				[avgoutboundTime] [int] NOT NULL,
				[tChatting] [smallint] NOT NULL,
				[avgchatTime] [smallint] NOT NULL,
				[chatsAttended] [int] NOT NULL,
				[callsOut] [int] NOT NULL,
				[callsIn] [int] NOT NULL,
				[abandonedCalls] [int] NOT NULL,
				[nanswer2] [int] NOT NULL,
				[year] [int] NOT NULL,
				[month] [int] NOT NULL,
				[day] [int] NOT NULL,
				[hour] [int] NOT NULL,
				[minutes] [int] NOT NULL
			) ON [PRIMARY]
		end'
		EXEC(@sql)


		SET @process = 'CW-5047 Creacion de filtros en ReportsFiltersMenus'
		SET @sql = 'if not exists (select * from ReportsFiltersMenus where idReport=7190)
		begin
			insert into ReportsFiltersMenus values (7190,''date'',1,'''')
			insert into ReportsFiltersMenus values (7190,''filterby'',1,'''')
			insert into ReportsFiltersMenus values (7190,''groupby'',1,'''')
		end'
		EXEC(@sql)


		SET @process = 'CW-5047 Creacion de filtro en ReportsFilters'
		SET @sql = 'if not exists(select * from ReportsFilters where id=7190)
		begin
		insert into ReportsFilters values(''Call Time Summary'',''users'',7190)
		end'
		EXEC(@sql)

		SET @process = 'CW-5047 Creacion de Agrupacion en GroupByReports'
		SET @sql = 'if not exists(select * from GroupByReports where id=7190)
		begin
		insert into GroupByReports values(7190,
		''userId|max([user]):user|max([Agent]):Agent|sum([sessionTime]):sessionTime|sum(unavailableTime):unavailableTime|
		sum(TiempoDispo):TiempoDispo|min(loginTime):loginTime|max(logoutTime):logoutTime|sum(genDialogTime):genDialogTime|
		isnull(sum(genDialogTime)/nullif(count(genDialogTime),0),0):avgCallTime|sum(inboundTime):inboundTime|
		isnull(sum(inboundTime)/nullif(count(inboundTime),0),0):avginboundTime|sum(outboundTime):outboundTime|
		isnull(sum(outboundTime)/nullif(count(outboundTime),0),0):avgoutboundTime|sum(tChatting):tChatting|
		isnull(sum(tChatting)/nullif(count(tChatting),0),0):avgchatTime|sum(chatsAttended):chatsAttended|
		sum(callsOut):callsOut|sum(callsIn):callsIn|sum(abandonedCalls):abandonedCalls|sum(nanswer2):nanswer2''
		,''userId'')
		end'
		EXEC(@sql)

		SET @process = 'CW-5047 Creacion de totales en ReportsTotals'
		SET @sql = 'if not exists(select * from ReportsTotals where id=7190)
		begin
		insert into ReportsTotals values(7190,
		''sum:sessionTime|sum:unavailableTime|sum:TiempoDispo|sum:genDialogTime|sum:avgCallTime|sum:inboundTime|
		special:avginboundTime:isnull(sum(inboundTime)/nullif(sum([callsIn]),0),0)|
		sum:outboundTime|special:avgoutboundTime:isnull(sum(outboundTime)/nullif(sum([callsOut]),0),0)|sum:tChatting|sum:avgchatTime|sum:chatsAttended|
		sum:callsOut|sum:callsIn|sum:abandonedCalls|sum:nanswer2''
		)
		end'
		EXEC(@sql)

		SET @process = 'CW-5047 Creacion de indice IX_RepCallTimeSummary'
		SET @sql = 'if not exists (select * from sys.indexes where name = N''IX_RepCallTimeSummary'' and object_id = OBJECT_ID(N''RepCallTimeSummary''))
		begin
			CREATE INDEX IX_RepCallTimeSummary ON RepCallTimeSummary(date)
		end'
		EXEC(@sql)

		
		IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF

