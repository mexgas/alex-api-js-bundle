SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 103

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
    begin
    DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
    end'
EXEC(@sql)

		set @process = 'CW-5047 Alter Table Add COlumn ccStatusLLamada.inAbandonConfig'
    	set @Sql= 'if not exists (select * from sys.columns where name = N''inAbandonConfig'' and Object_ID = Object_ID(N''ccStatusLLamada''))
    begin
        Alter table ccStatusLLamada ADD inAbandonConfig bit
    end'
		EXEC(@Sql)


		set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
		set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
        begin
        ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
        end'
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


		SET @process = 'CW-5047 Version BD 100 Creacion de filtro en ReportsFilters'
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

		SET @process = 'CW-5047 Eliminar procedure ccspRepCallTimeSummary'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccspRepCallTimeSummary'')
		begin
			DROP PROCEDURE ccspRepCallTimeSummary;
		end'
		EXEC(@sql)


		SET @process = 'CW-5047 Version BD 100 Creacion de StoreProcedure ccspRepCallTimeSummary'
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

		set @process = 'CW-5437 Drop Report RepAgentGI'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepAgentGI'')
		begin
			DROP PROCEDURE ccspRepAgentGI;
		end'
		EXEC(@sql)

		set @process = 'CW-5437 Create Report RepAgentGI'
		set @sql = 'CREATE PROCEDURE [dbo].[ccspRepAgentGI]
@action AS TINYINT,
@from AS DATETIME,
@to AS DATETIME
AS

SET ANSI_WARNINGS OFF;
SET NOCOUNT ON;
IF @from IS NULL
    SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));
IF @to IS NULL
    SELECT @to = GETDATE();
IF @action = 1
    BEGIN
        IF OBJECT_ID(''tempdb..#inboundData'') IS NOT NULL
            DROP TABLE #inboundData;
        IF OBJECT_ID(''tempdb..#inboundData2'') IS NOT NULL
            DROP TABLE #inboundData2;
        IF OBJECT_ID(''tempdb..#outboundData'') IS NOT NULL
            DROP TABLE #outboundData;
        IF OBJECT_ID(''tempdb..#outboundData2'') IS NOT NULL
            DROP TABLE #outboundData2;
        IF OBJECT_ID(''tempdb..#timeDetailAgent'') IS NOT NULL
            DROP TABLE #timeDetailAgent;
        IF OBJECT_ID(''tempdb..#timeDetailAgent2'') IS NOT NULL
            DROP TABLE #timeDetailAgent2;
        IF OBJECT_ID(''tempdb..#agentInformation'') IS NOT NULL
            DROP TABLE #agentInformation;
        IF OBJECT_ID(''tempdb..#tempRepAgentGI'') IS NOT NULL
            DROP TABLE #tempRepAgentGI;
        IF OBJECT_ID(''tempdb..#tempAgentLastStatus'') IS NOT NULL
            DROP TABLE #tempAgentLastStatus;
        IF OBJECT_ID(''tempdb..#tempccLogAgentesDia'') IS NOT NULL
            DROP TABLE #tempccLogAgentesDia;
        IF OBJECT_ID(''tempdb..#tempccLogAgentesDia2'') IS NOT NULL
            DROP TABLE #tempccLogAgentesDia2;
        IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL
            DROP TABLE #sessionTimeGroup;

        DECLARE @interval INT;
        DECLARE @dateNow DATETIME, @maxLogout DATETIME;
        DECLARE @HourExtend AS SMALLINT, @fromExtended AS SMALLDATETIME;

        SELECT @HourExtend = 2, 
               @fromExtended = DATEADD(hh, -@HourExtend, @from);
        DECLARE @tresRing AS SMALLINT, @tresDialog AS SMALLINT, @tresDelayIn AS SMALLINT;

        EXEC @tresRing = ccspConfigTresRing;
        EXEC @tresDialog = ccspConfigTresDialog;
        EXEC @tresDelayIn = ccspConfigtresDelayIn;

        SET @dateNow = GETDATE();
        SET @interval = 15;

        CREATE TABLE #inboundData
        ([row]           INT IDENTITY PRIMARY KEY, 
         Inbound_id      INT, 
         [User_id]       INT, 
         phone_in        VARCHAR(30), 
         cal_id          INT, 
         dni_id          INT, 
         dateStartDetail DATETIME, 
         dateEndDetail   DATETIME, 
         timegroup       DATETIME, 
         timegroup_next  DATETIME, 
         time_endque     DATETIME, 
         time_ring       DATETIME, 
         time_dialog     DATETIME, 
         time_notes      DATETIME, 
         time_end_call   DATETIME, 
         ntotal          INT, 
         ninitial        INT, 
         nout_hour       INT, 
         nout_service    INT, 
         nabnd           INT, 
         nno_agent       INT, 
         nque            INT, 
         ntimeout        INT, 
         noverflow       INT, 
         nxfer           INT, 
         nxfer_que       INT, 
         nabnd_xfer      INT, 
         nabnd_ring      INT, 
         nno_answer      INT, 
         nabnd_dialog    INT, 
         nanswer         INT, 
         nlost           INT, 
         nmsg            INT, 
         nabnd_tres      INT, 
         nansw_tres      INT, 
         tque_max        INT, 
         tque            INT, 
         txfer           INT, 
         tdialog         INT, 
         tnotes          INT, 
         tring           INT, 
         tresp           INT, 
         nMoh            INT, 
         nWHag           INT, 
         nWHcl           INT
        );

        CREATE NONCLUSTERED INDEX iX_InboundUserId ON #inboundData([Inbound_id] DESC, [User_id] DESC);

        CREATE TABLE #outboundData
        (row             INT IDENTITY, 
         cam_id          INT, 
         [User_id]       INT, 
         cal_id          INT, 
         cal_puerto      INT, 
         phone_out       VARCHAR(30), 
         dateStartDetail DATETIME, 
         dateEndDetail   DATETIME, 
         timegroup       DATETIME, 
         timegroup_next  DATETIME, 
         ntotal          INT, 
         nno_agent       INT, 
         nxfer           INT, 
         nabnd_xfer      INT, 
         nabnd_ring      INT, 
         nno_answer      INT, 
         nabnd_dialog    INT, 
         nanswer         INT, 
         nlost           INT, 
         tque            INT, 
         txfer           INT, 
         tring           INT, 
         tdialog         INT, 
         tnotes          INT, 
         tresp           INT, 
         nhangup         INT, 
         nMoh            INT, 
         nWHag           INT, 
         nWHcl           INT, 
         time_endque     DATETIME, 
         time_ring       DATETIME, 
         time_dialog     DATETIME, 
         time_notes      DATETIME, 
         time_end_call   DATETIME
        );

        CREATE NONCLUSTERED INDEX iX_CamUserId ON #outboundData([cam_id] DESC, [User_id] DESC);

        CREATE TABLE #timeDetailAgent
        ([User_id]       INT NULL, 
         dateStartDetail DATETIME NULL, 
         dateEndDetail   DATETIME NULL, 
         timegroup       DATETIME NULL, 
         timegroup_next  DATETIME NULL, 
         tunknown        INT NULL, 
         tnot_av         INT NULL, 
         tav             INT NULL, 
         tprob           INT NULL, 
         tother          INT NULL, 
         nother          INT NULL, 
         tmanualcall     INT NULL, 
         tunknown2       DECIMAL(10, 3), 
         tchatting       INT NULL
        );

        --Tiempo ultimo Status del agente
        CREATE TABLE #tempAgentLastStatus
        (id     INT, 
         fecha  DATETIME, 
         tiempo INT
        );

        CREATE TABLE #sessionTimeGroup
        ([user_id]        [SMALLINT] NOT NULL, 
         [login]          [DATETIME] NOT NULL, 
         [logout]         [DATETIME] NULL, 
         [extension]      [VARCHAR](7) NOT NULL, 
         [timegroup]      [DATETIME] NOT NULL, 
         [timegroup_next] [DATETIME] NOT NULL, 
         [tlog]           [INT] NULL
        );

        --TIempos del agente
        CREATE TABLE #tempccLogAgentesDia
        (row              INT NOT NULL, 
         user_id          INT NOT NULL, 
         TipoStatusAge_id TINYINT NOT NULL, 
         tStatus          INT NOT NULL, 
         dateIni          DATETIME NOT NULL, 
         dateEnd          DATETIME NOT NULL, 
         currentStatus    INT
        );

        SELECT @maxLogout = MAX(logout)
        FROM TmpSessionTimeGroup;

        IF CONVERT(VARCHAR(11), @maxLogout, 121) = CONVERT(VARCHAR(11), @dateNow, 121)
           AND @dateNow > @maxLogout
            SET @dateNow = @maxLogout;

        INSERT INTO #sessionTimeGroup
               SELECT user_id, 
                      login, 
                      logout, 
                      extension, 
                      timegroup, 
                      timegroup_next, 
                      tlog
               FROM TmpSessionTimeGroup;

        --inserto ultimo tiempo del agente del dia
        INSERT INTO #tempAgentLastStatus
               SELECT User_id, 
                      MAX(fecha) AS maxfecha, 
                      DATEDIFF(ss, MAX(fecha), @dateNow)
               FROM ccLogAgentesDia
               WHERE CONVERT(VARCHAR(11), fecha, 121) = CONVERT(VARCHAR(11), @dateNow, 121)
               GROUP BY User_id;

        INSERT INTO #inboundData
        (dateStartDetail, 
         dateEndDetail, 
         timegroup, 
         timegroup_next, 
         time_endque, 
         time_ring, 
         time_dialog, 
         time_notes, 
         time_end_call, 
         phone_in, 
         cal_id, 
         dni_id, 
         Inbound_id, 
         User_id, 
         ntotal, 
         ninitial, 
         nout_hour, 
         nout_service, 
         nabnd, 
         nno_agent, 
         nque, 
         ntimeout, 
         noverflow, 
         nxfer, 
         nxfer_que, 
         nabnd_xfer, 
         nabnd_ring, 
         nno_answer, 
         nabnd_dialog, 
         nanswer, 
         nlost, 
         nmsg, 
         nabnd_tres, 
         nansw_tres, 
         tque_max, 
         tque, 
         txfer, 
         tdialog, 
         tnotes, 
         tring, 
         tresp, 
         nMoh, 
         nWHag, 
         nWHcl
        )
               SELECT *
               FROM
               (
                   SELECT CASE
                              WHEN cal_Xfer IS NULL
                                   OR cal_Xfer = ''1900-01-01 00:00:00''
                              THEN cal_inicio
                              ELSE cal_Xfer
                          END AS dateStartDetail, 
                          DATEADD(ss, 0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,
                                                                                CASE
                                                                                    WHEN cal_Xfer IS NULL
                                                                                         OR cal_Xfer = ''1900-01-01 00:00:00''
                                                                                    THEN cal_inicio
                                                                                    ELSE cal_Xfer
                                                                                END) dateEndDetail, 
                          dbo.GetTimeGroup
                   (CASE
                        WHEN cal_Xfer IS NULL
                             OR cal_Xfer = ''1900-01-01 00:00:00''
                        THEN cal_inicio
                        ELSE cal_Xfer
                    END, 0
                   ) AS timegroup, 
                          dbo.GetTimeGroup
                   (DATEADD(ss, ISNULL((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas), 0),
                                                                                                CASE
                                                                                                    WHEN cal_Xfer IS NULL
                                                                                                         OR cal_Xfer = ''1900-01-01 00:00:00''
                                                                                                    THEN cal_inicio
                                                                                                    ELSE cal_Xfer
                                                                                                END), 1
                   ) AS timegroup_next,
                          CASE
                              WHEN cal_Xfer IS NULL
                                   OR cal_Xfer = ''1900-01-01 00:00:00''
                              THEN cal_inicio
                              ELSE cal_Xfer
                          END AS time_endque, 
                          DATEADD(ss, ISNULL(cal_txfer, 0),
                                                         CASE
                                                             WHEN cal_Xfer IS NULL
                                                                  OR cal_Xfer = ''1900-01-01 00:00:00''
                                                             THEN cal_inicio
                                                             ELSE cal_Xfer
                                                         END) AS time_ring, 
                          DATEADD(ss, ISNULL(cal_txfer + cal_tring, 0),
                                                                     CASE
                                                                         WHEN cal_Xfer IS NULL
                                                                              OR cal_Xfer = ''1900-01-01 00:00:00''
                                                                         THEN cal_inicio
                                                                         ELSE cal_Xfer
                                                                     END) AS time_dialog, 
                          DATEADD(ss, ISNULL(cal_txfer + cal_tring + cal_tdialog, 0),
                                                                                   CASE
                                                                                       WHEN cal_Xfer IS NULL
                                                                                            OR cal_Xfer = ''1900-01-01 00:00:00''
                                                                                       THEN cal_inicio
                                                                                       ELSE cal_Xfer
                                                                                   END) AS time_notes, 
                          DATEADD(ss, ISNULL(cal_txfer + cal_tring + cal_tdialog + cal_tnotas, 0),
                                                                                                CASE
                                                                                                    WHEN cal_Xfer IS NULL
                                                                                                         OR cal_Xfer = ''1900-01-01 00:00:00''
                                                                                                    THEN cal_inicio
                                                                                                    ELSE cal_Xfer
                                                                                                END) AS time_end_call, 
                          cal_Ani AS phone_in, 
                          cal_id, 
                          dni_id, 
                          Inbound_id, 
                          [User_id], 
                          1 AS ntotal, 
                          ISNULL((CASE
                                      WHEN statuscall_id = 1
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS ninitial, 
                          ISNULL((CASE
                                      WHEN statuscall_id = 2
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nout_hour, 
                          ISNULL((CASE
                                      WHEN statuscall_id = 3
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nout_service, 
                          ISNULL((CASE
                                      WHEN(statuscall_id IN(5, 6)
                                           AND (cal_que > 0)
                                           AND (cal_xfer = ''1900-01-01 00:00:00''))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nabnd, 
                          ISNULL((CASE
                                      WHEN(statuscall_id = 4)
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nno_agent, 
                          ISNULL((CASE
                                      WHEN(cal_que > 0)
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nque, 
                          ISNULL((CASE
                                      WHEN(statuscall_id = 7)
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS ntimeout, 
                          ISNULL((CASE
                                      WHEN(statuscall_id = 8)
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS noverflow, 
                          ISNULL((CASE
                                      WHEN((statuscall_id IN(11, 15, 13, 16))
                                           OR (statuscall_id = 6
                                               AND cal_xfer <> ''1900-01-01 00:00:00''))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nxfer, 
                          ISNULL((CASE
                                      WHEN((cal_que > 0)
                                           AND (statuscall_id IN(11, 15, 13, 16)
                                                OR (statuscall_id = 6
                                                    AND cal_xfer <> ''1900-01-01 00:00:00'')))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nxfer_que, 
                          ISNULL((CASE
                                      WHEN((statuscall_id = 11)
                                           OR (statuscall_id = 6
                                               AND cal_xfer <> ''1900-01-01 00:00:00''))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nabnd_xfer, 
                          ISNULL((CASE
                                      WHEN((statuscall_id = 15)
                                           AND (cal_tring <= @tresRing))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nabnd_ring, 
                          ISNULL((CASE
                                      WHEN((statuscall_id = 15)
                                           AND (cal_tring > @tresRing))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nno_answer, 
                          ISNULL((CASE
                                      WHEN((statuscall_id = 13)
                                           AND (cal_tdialog <= @tresDialog))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nabnd_dialog, 
                          ISNULL((CASE
                                      WHEN((statuscall_id = 13)
                                           AND (cal_tdialog > @tresDialog))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nanswer, 
                          ISNULL((CASE
                                      WHEN(statuscall_id = 16)
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nlost, 
                          ISNULL((CASE
                                      WHEN(statuscall_id IN(9, 10, 12, 14))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nmsg, 
                          ISNULL((CASE
                                      WHEN((statuscall_id IN(5, 6)
                                            AND cal_que > 0
                                            AND cal_xfer = ''1900-01-01 00:00:00'')
                                           AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nabnd_tres, 
                          ISNULL((CASE
                                      WHEN((statuscall_id = 13
                                            AND cal_tdialog > @tresDialog)
                                           AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nansw_tres, 
                          cal_twait AS tque_max, 
                          cal_twait AS tque, 
                          cal_txfer AS txfer, 
                          ISNULL((cal_tdialog), 0) AS tdialog, 
                          ISNULL((cal_tnotas), 0) AS tnotes, 
                          ISNULL((cal_tring), 0) AS tring, 
                          ISNULL((CASE
                                      WHEN((statuscall_id = 13)
                                           AND (cal_tdialog > @tresDialog))
                                      THEN(cal_twait + cal_txfer + cal_tring)
                                      ELSE 0
                                  END), 0) AS tresp, 
                          ISNULL((CASE
                                      WHEN cal_tMoh > 0
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nMoh, 
                          ISNULL((CASE
                                      WHEN cal_whoHung > 0
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nWHag, 
                          ISNULL((CASE
                                      WHEN cal_whoHung = 0
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nWHcl
                   FROM ccCallsIn WITH (NOLOCK, INDEX(IX_ccCallsIn))
                   WHERE cal_inicio >= @fromExtended
                         AND cal_inicio < @to
                         AND INBOUND_ID > 0
               ) inboundData
               WHERE NOT(ntotal = 0
                         AND nout_hour = 0
                         AND nout_service = 0
                         AND nabnd = 0
                         AND nno_agent = 0
                         AND nque = 0
                         AND ntimeout = 0
                         AND noverflow = 0
                         AND nxfer = 0
                         AND nxfer_que = 0
                         AND nabnd_xfer = 0
                         AND nabnd_ring = 0
                         AND nno_answer = 0
                         AND nabnd_dialog = 0
                         AND nanswer = 0
                         AND nlost = 0
                         AND nmsg = 0
                         AND nabnd_tres = 0
                         AND nansw_tres = 0
                         AND tque_max = 0
                         AND tque = 0
                         AND txfer = 0
                         AND tring = 0
                         AND tdialog = 0
                         AND tnotes = 0
                         AND tresp = 0);


        UPDATE C
          SET 
              C.dateEndDetail = @dateNow, 
              C.timegroup_next = dbo.GetTimeGroup(DATEADD(ss, tiempo, B.fecha), 1), 
              C.time_dialog = CASE
                                  WHEN A.currentStatus IN(4, 5, 9)
                                  THEN @dateNow
                                  WHEN A.TipoStatusAge_id = 4
                                  THEN B.fecha
                                  ELSE C.dateStartDetail
                              END, 
              C.time_notes = @dateNow, 
              C.time_end_call = @dateNow, 
              C.tdialog = CASE
                              WHEN A.currentStatus IN(4, 5, 9)
                              THEN B.tiempo
                              WHEN A.TipoStatusAge_id = 4
                              THEN DATEDIFF(ss, C.dateStartDetail, B.fecha)
                              ELSE 0
                          END, 
              C.tnotes = CASE
                             WHEN A.currentStatus = 6
                             THEN B.tiempo
                             ELSE 0
                         END
        FROM ccLogAgentesDia A
             INNER JOIN #tempAgentLastStatus B ON A.fecha = B.fecha
                                                  AND A.User_id = B.id
             INNER JOIN #inboundData C ON A.callID = C.cal_id
        WHERE currentStatus IN(4, 5, 6, 9)
        AND A.Tipo = 0;


        SELECT *
        INTO #inboundData2
        FROM #inboundData
        WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

        DELETE #inboundData
        WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

        INSERT INTO #inboundData
        (dateStartDetail, 
         dateEndDetail, 
         timegroup, 
         timegroup_next, 
         time_endque, 
         time_ring, 
         time_dialog, 
         time_notes, 
         time_end_call, 
         phone_in, 
         cal_id, 
         dni_id, 
         Inbound_id, 
         [User_id], 
         ntotal, 
         ninitial, 
         nout_hour, 
         nout_service, 
         nabnd, 
         nno_agent, 
         nque, 
         ntimeout, 
         noverflow, 
         nxfer, 
         nxfer_que, 
         nabnd_xfer, 
         nabnd_ring, 
         nno_answer, 
         nabnd_dialog, 
         nanswer, 
         nlost, 
         nmsg, 
         nabnd_tres, 
         nansw_tres, 
         tque_max, 
         tque, 
         txfer, 
         tdialog, 
         tnotes, 
         tring, 
         tresp, 
         nMoh, 
         nWHag, 
         nWHcl
        )
               SELECT dateStartDetail, 
                      dateEndDetail, 
                      CONVERT(VARCHAR, th.start, 121) AS timegroup, 
                      CONVERT(VARCHAR, th.stop, 121) AS timegroup_next, 
                      time_endque, 
                      time_ring, 
                      time_dialog, 
                      time_notes, 
                      time_end_call, 
                      phone_in, 
                      cal_id, 
                      dni_id, 
                      Inbound_id, 
                      [User_id],
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN ntotal
                          ELSE 0
                      END AS ntotal,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN ninitial
                          ELSE 0
                      END AS ninitial,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nout_hour
                          ELSE 0
                      END AS nout_hour,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nout_service
                          ELSE 0
                      END AS nout_service,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd
                          ELSE 0
                      END AS nabnd,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nno_agent
                          ELSE 0
                      END AS nno_agent,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nque
                          ELSE 0
                      END AS nque,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN ntimeout
                          ELSE 0
                      END AS ntimeout,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN noverflow
                          ELSE 0
                      END AS noverflow,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nxfer
                          ELSE 0
                      END AS nxfer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nxfer_que
                          ELSE 0
                      END AS nxfer_que,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd_xfer
                          ELSE 0
                      END AS nabnd_xfer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd_ring
                          ELSE 0
                      END AS nabnd_ring,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nno_answer
                          ELSE 0
                      END AS nno_answer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd_dialog
                          ELSE 0
                      END AS nabnd_dialog,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nanswer
                          ELSE 0
                      END AS nanswer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nlost
                          ELSE 0
                      END AS nlost,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nmsg
                          ELSE 0
                      END AS nmsg,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd_tres
                          ELSE 0
                      END AS nabnd_tres,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nansw_tres
                          ELSE 0
                      END AS nansw_tres,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN tque_max
                          ELSE 0
                      END AS tque_max, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, time_endque) AS tque, 
                      dbo.TimeInterval(th.start, th.stop, time_endque, time_ring) AS txfer, 
                      dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog, 
                      dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes, 
                      dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tresp, dateStartDetail)) AS tresp,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nMoh
                          ELSE 0
                      END AS nMoh,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nWHag
                          ELSE 0
                      END AS nWHag,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nWHcl
                          ELSE 0
                      END AS nWHcl
               FROM #inboundData2 t
                    JOIN TmpTimesInterval th ON(t.timegroup > th.Start
                                                AND t.timegroup < th.stop)
                                               OR th.Start BETWEEN t.timegroup AND t.timegroup_next
               WHERE DATEDIFF(ss, th.start, timegroup_next) > 0
                     AND th.Start BETWEEN @from AND @to
               ORDER BY cal_id;


        INSERT INTO #outboundData
        (dateStartDetail, 
         dateEndDetail, 
         timegroup, 
         timegroup_next, 
         cam_id, 
         User_id, 
         ntotal, 
         nno_agent, 
         nxfer, 
         nabnd_xfer, 
         nabnd_ring, 
         nno_answer, 
         nabnd_dialog, 
         nanswer, 
         nlost, 
         tque, 
         txfer, 
         tring, 
         tdialog, 
         tnotes, 
         tresp, 
         nhangup, 
         nMoh, 
         nWHag, 
         nWHcl, 
         time_endque, 
         time_ring, 
         time_dialog, 
         time_notes, 
         time_end_call, 
         phone_out, 
         cal_id, 
         cal_puerto
        )
               SELECT *
               FROM
               (
                   SELECT cal_Inicio AS dateStartDetail, 
                          DATEADD(ss, ISNULL(SUM(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas), 0), cal_Inicio) AS dateEndDetail, 
                          dbo.GetTimeGroup(cal_inicio, 0) AS timegroup, 
                          dbo.GetTimeGroup(DATEADD(ss, ISNULL(SUM(cal_txfer + cal_tring + cal_tdialog + cal_tnotas), 0), cal_Inicio), 1) AS timegroup_next, 
                          cam_id, 
                          [User_id], 
                          COUNT(cal_id) AS ntotal, 
                          ISNULL(COUNT(CASE
                                           WHEN(statuscall_id = 4)
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nno_agent, 
                          ISNULL(COUNT(CASE
                                           WHEN(statuscall_id >= 10)
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nxfer, 
                          ISNULL(COUNT(CASE
                                           WHEN(statuscall_id = 11)
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nabnd_xfer, 
                          ISNULL(COUNT(CASE
                                           WHEN((statuscall_id = 15)
                                                AND (cal_tring <= @tresRing))
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nabnd_ring, 
                          ISNULL(COUNT(CASE
                                           WHEN((statuscall_id = 15)
                                                AND (cal_tring > @tresRing))
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nno_answer, 
                          ISNULL(COUNT(CASE
                                           WHEN((statuscall_id = 13)
                                                AND (cal_tdialog <= @tresDialog))
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nabnd_dialog, 
                          ISNULL(COUNT(CASE
                                           WHEN((statuscall_id = 13)
                                                AND (cal_tdialog > @tresDialog))
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nanswer, 
                          ISNULL(COUNT(CASE
                                           WHEN(statuscall_id = 16)
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nlost, 
                          ISNULL(SUM(cal_twait), 0) AS tque, 
                          ISNULL(SUM(cal_txfer), 0) AS txfer, 
                          ISNULL(SUM(cal_tring), 0) AS tring, 
                          ISNULL(SUM(cal_tdialog), 0) AS tdialog, 
                          ISNULL(SUM(cal_tnotas), 0) AS tnotes, 
                          ISNULL(SUM(CASE
                                         WHEN((statuscall_id = 13)
                                              AND (cal_tdialog > @tresDialog))
                                         THEN(cal_txfer + cal_tring)
                                         ELSE NULL
                                     END), 0) AS tresp, 
                          ISNULL(COUNT(CASE
                                           WHEN(statuscall_id = 6)
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nhangup, 
                          ISNULL(SUM(CASE
                                         WHEN cal_tMoh > 0
                                         THEN 1
                                         ELSE 0
                                     END), 0) AS nMoh, 
                          ISNULL(SUM(CASE
                                         WHEN cal_whoHung > 0
                                         THEN 1
                                         ELSE 0
                                     END), 0) AS nWHag, 
                          ISNULL(SUM(CASE
                                         WHEN cal_whoHung = 0
                                         THEN 1
                                         ELSE 0
                                     END), 0) AS nWHcl, 
                          DATEADD(ss, ISNULL(SUM(0), 0), cal_inicio) AS time_endque, 
                          DATEADD(ss, ISNULL(SUM(0 + cal_txfer), 0), cal_inicio) AS time_ring, 
                          DATEADD(ss, ISNULL(SUM(0 + cal_txfer + cal_tring), 0), cal_inicio) AS time_dialog, 
                          DATEADD(ss, ISNULL(SUM(0 + cal_txfer + cal_tring + cal_tdialog), 0), cal_inicio) AS time_notes, 
                          DATEADD(ss, ISNULL(SUM(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas), 0), cal_inicio) AS time_end_call, 
                          ISNULL(MAX(cal_telefono), 0) AS phone_out, 
                          cal_id, 
                          cal_puerto
                   FROM ccoCallsOut WITH (NOLOCK, INDEX(IX_ccoCallsOut_2))
                   WHERE cal_Inicio >= @fromExtended
                         AND cal_inicio < @to
                         -- para contar bien las llamadas manuales
                         AND cal_manual IN(0, 2)
                   GROUP BY cal_id, 
                            [User_id], 
                            cam_id, 
                            cal_Inicio, 
                            cal_puerto
               ) outboundData
               WHERE NOT(ntotal = 0
                         AND nno_agent = 0
                         AND nxfer = 0
                         AND nabnd_xfer = 0
                         AND nabnd_ring = 0
                         AND nno_answer = 0
                         AND nabnd_dialog = 0
                         AND nanswer = 0
                         AND nlost = 0
                         AND txfer = 0
                         AND tring = 0
                         AND tdialog = 0
                         AND tnotes = 0
                         AND tresp = 0)

        UPDATE C
          SET 
              C.dateEndDetail = @dateNow, 
              C.timegroup_next = dbo.GetTimeGroup(DATEADD(ss, tiempo, B.fecha), 1), 
              C.time_dialog = CASE
                                  WHEN A.currentStatus IN(4, 5, 9)
                                  THEN @dateNow
                                  WHEN A.TipoStatusAge_id = 4
                                  THEN B.fecha
                                  ELSE C.dateStartDetail
                              END, 
              C.time_notes = @dateNow, 
              C.time_end_call = @dateNow, 
              C.tdialog = CASE
                              WHEN A.currentStatus IN(4, 5, 9)
                              THEN B.tiempo
                              WHEN A.TipoStatusAge_id = 4
                              THEN DATEDIFF(ss, C.dateStartDetail, B.fecha)
                              ELSE 0
                          END, 
              C.tnotes = CASE
                             WHEN A.currentStatus = 6
                             THEN B.tiempo
                             ELSE 0
                         END
        FROM ccLogAgentesDia A
             INNER JOIN #tempAgentLastStatus B ON A.fecha = B.fecha
                                                  AND A.User_id = B.id
             INNER JOIN #outboundData C ON A.callID = C.cal_id
        WHERE currentStatus IN(4, 5, 6, 9)
        AND A.Tipo = 1;

        SELECT *
        INTO #outboundData2
        FROM #outboundData
        WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

        DELETE #outboundData
        WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

        INSERT INTO #outboundData
        (dateStartDetail, 
         dateEndDetail, 
         timegroup, 
         timegroup_next, 
         cam_id, 
         User_id, 
         ntotal, 
         nno_agent, 
         nxfer, 
         nabnd_xfer, 
         nabnd_ring, 
         nno_answer, 
         nabnd_dialog, 
         nanswer, 
         nlost, 
         tque, 
         txfer,
		 tdialog,
		 tnotes,
         tring,
		 tresp, 
         nhangup, 
         nMoh, 
         nWHag, 
         nWHcl, 
         time_endque, 
         time_ring, 
         time_dialog, 
         time_notes, 
         time_end_call, 
         phone_out, 
         cal_id, 
         cal_puerto
        )
               SELECT dateStartDetail, 
                      dateEndDetail, 
                      CONVERT(VARCHAR, th.start, 121) AS timegroup, 
                      CONVERT(VARCHAR, th.stop, 121) AS timegroup_next, 
                      cam_id, 
                      [User_id],
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN ntotal
                          ELSE 0
                      END AS ntotal,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nno_agent
                          ELSE 0
                      END AS nno_agent,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nxfer
                          ELSE 0
                      END AS nxfer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd_xfer
                          ELSE 0
                      END AS nabnd_xfer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd_ring
                          ELSE 0
                      END AS nabnd_ring,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nno_answer
                          ELSE 0
                      END AS nno_answer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd_dialog
                          ELSE 0
                      END AS nabnd_dialog,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nanswer
                          ELSE 0
                      END AS nanswer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nlost
                          ELSE 0
                      END AS nlost, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, time_endque) AS tque, 
                      dbo.TimeInterval(th.start, th.stop, time_endque, time_ring) AS txfer, 
                      dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog, 
                      dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes, 
                      dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tresp, dateStartDetail)) AS tresp,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nhangup
                          ELSE 0
                      END AS nhangup,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nMoh
                          ELSE 0
                      END AS nMoh,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nWHag
                          ELSE 0
                      END AS nWHag,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nWHcl
                          ELSE 0
                      END AS nWHcl, 
                      time_endque, 
                      time_ring, 
                      time_dialog, 
                      time_notes, 
                      time_end_call, 
                      phone_out, 
                      cal_id, 
                      cal_puerto
               FROM #outboundData2 t
                    INNER JOIN TmpTimesInterval th ON(t.timegroup > th.Start
                                                      AND t.timegroup < th.stop)
                                                     OR th.Start BETWEEN t.timegroup AND t.timegroup_next
               WHERE DATEDIFF(ss, th.start, timegroup_next) > 0
                     AND th.Start BETWEEN @from AND @to
			   order by timegroup


        INSERT INTO #tempccLogAgentesDia
        (row, 
         [User_id], 
         TipoStatusAge_id, 
         tStatus, 
         dateIni, 
         dateEnd, 
         currentStatus
        )
               SELECT ROW_NUMBER() OVER(PARTITION BY user_id
                      ORDER BY DATEADD(ss, -tStatus, fecha)) AS Row, 
                      User_id, 
                      TipoStatusAge_id, 
                      tStatus, 
                      DATEADD(ss, -tStatus, fecha) dateIni, 
                      fecha dateEnd, 
                      ISNULL(currentStatus, -2)
               FROM ccLogAgentesDia
               WHERE DATEADD(ss, -tStatus, fecha) >= @from
                     AND DATEADD(ss, -tStatus, fecha) < @to;


        DELETE A
        FROM
        (
            SELECT CASE
                       WHEN A.tStatus > S.tStatus
                       THEN S.row
                       ELSE A.row
                   END row, 
                   A.user_id
            FROM #tempccLogAgentesDia A
                 LEFT JOIN #tempccLogAgentesDia S ON A.Row = S.Row - 1
                                                     AND A.user_id = S.user_id
            WHERE A.dateIni >= @from
                  AND A.dateIni < @to
                  AND A.TipoStatusAge_id = S.TipoStatusAge_id
                  AND (S.dateEnd BETWEEN A.dateIni AND A.dateEnd
                       OR S.dateIni BETWEEN A.dateIni AND A.dateEnd)
                  AND ABS(DATEDIFF(ss, A.dateEnd, S.dateIni)) > 2
        ) x
        INNER JOIN #tempccLogAgentesDia A ON A.row = x.row
                                             AND A.user_id = x.user_id;


        SELECT ROW_NUMBER() OVER(PARTITION BY user_id
               ORDER BY dateIni) AS Row, 
               User_id, 
               TipoStatusAge_id, 
               tStatus, 
               dateIni, 
               dateEnd, 
               currentStatus
        INTO #tempccLogAgentesDia2
        FROM #tempccLogAgentesDia;


        INSERT INTO #timeDetailAgent
               SELECT A.user_id, 
                      A.dateIni, 
                      A.dateEnd, 
                      dbo.GetTimeGroup(A.dateIni, 0) AS timegroup, 
                      dbo.GetTimeGroup(A.dateEnd, 1) AS timegroup_next,
                      CASE
                          WHEN A.tipostatusage_id = 1
                          THEN A.tStatus
                          ELSE 0
                      END tunknown,
                      CASE
                          WHEN A.tipostatusage_id = 2
                          THEN A.tStatus
                          ELSE 0
                      END tnot_av,
                      CASE
                          WHEN A.tipostatusage_id = 3
                          THEN A.tStatus
                          ELSE 0
                      END tav,
                      CASE
                          WHEN A.tipostatusage_id IN(11, 25, 26, 27)
                          THEN A.tStatus
                          ELSE 0
                      END tprob, --11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida
                      CASE
                          WHEN A.tipostatusage_id = 7
                          THEN A.tStatus
                          ELSE 0
                      END tother,
                      CASE
                          WHEN A.tipostatusage_id = 7
                          THEN 1
                          ELSE 0
                      END nother,
                      CASE
                          WHEN A.tipostatusage_id = 21
                          THEN A.tStatus
                          ELSE 0
                      END tmanualcall,
                      CASE
                          WHEN ABS(ISNULL(1.0 * DATEDIFF(ms, A.dateEnd, S.dateIni) / 1000, 0)) > A.tStatus
                          THEN 0
                          WHEN A.currentStatus IN(0, -1, -2)
                          THEN 0 --Logout
                          WHEN S.TipoStatusAge_id = 1
                          THEN 0
                          ELSE ISNULL(1.0 * DATEDIFF(ms, A.dateEnd, S.dateIni) / 1000, 0)
                      END AS tunknown2,
                      CASE
                          WHEN A.tipostatusage_id IN(23, 24)
                          THEN A.tStatus
                          ELSE 0
                      END AS tchatting
               FROM #tempccLogAgentesDia2 A
                    LEFT JOIN #tempccLogAgentesDia2 S ON A.Row = S.Row - 1
                                                         AND A.user_id = S.user_id
               WHERE A.dateIni >= @from
                     AND A.dateIni < @to
                     AND A.TipoStatusAge_id <> 0;


        UPDATE #timeDetailAgent
          SET 
              tunknown2 = 0
        WHERE ABS(tunknown2) > 2.7;


        INSERT INTO #timeDetailAgent
        (User_id, 
         dateStartDetail, 
         dateEndDetail, 
         timegroup, 
         timegroup_next, 
         tunknown, 
         tnot_av, 
         tav, 
         tprob, 
         tother, 
         nother, 
         tmanualcall, 
         tunknown2, 
         tchatting
        )
               SELECT User_id, 
                      B.fecha AS dateStartDetail, 
                      @dateNow AS dateEndDetail, 
                      dbo.GetTimeGroup(B.fecha, 0) AS timegroup, 
                      dbo.GetTimeGroup(DATEADD(ss, tiempo, B.fecha), 1) AS timegroup_next,
                      CASE
                          WHEN currentStatus = 1
                          THEN tiempo
                          ELSE 0
                      END AS tunknown,
                      CASE
                          WHEN currentStatus = 2
                          THEN tiempo
                          ELSE 0
                      END AS tnot_av,
                      CASE
                          WHEN tipostatusage_id = 1
                          THEN tiempo
                          WHEN currentStatus = 3
                          THEN tiempo
                          ELSE 0
                      END AS tav, 
                      0, 
                      0, 
                      0, 
                      0, 
                      0 AS tunknown2,
                      CASE
                          WHEN currentStatus IN(23, 24)
                          THEN tiempo
                          ELSE 0
                      END AS tchatting
               FROM ccLogAgentesDia A
                    INNER JOIN #tempAgentLastStatus B ON A.fecha = B.fecha
                                                         AND A.User_id = B.id
               WHERE A.currentStatus NOT IN(-2, -1, 0);


        SELECT *
        INTO #timeDetailAgent2
        FROM #timeDetailAgent
        WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;


        DELETE #timeDetailAgent
        WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;


        INSERT INTO #timeDetailAgent
        (dateStartDetail, 
         dateEndDetail, 
         timegroup, 
         timegroup_next, 
         User_id, 
         tunknown, 
         tnot_av, 
         tav, 
         tprob, 
         tother, 
         nother, 
         tmanualCall, 
         tunknown2, 
         tchatting
        )
               SELECT dateStartDetail, 
                      dateEndDetail, 
                      th.start AS timegroup, 
                      th.stop AS timegroup_next, 
                      [User_id], 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tunknown, dateStartDetail)) AS tunknown, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tnot_av, dateStartDetail)) AS tnot_av, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tav, dateStartDetail)) AS tav, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tprob, dateStartDetail)) AS tprob, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tother, dateStartDetail)) AS tother, 
                      ISNULL((CASE
                                  WHEN th.start > dateStartDetail
                                       AND th.stop > dateEndDetail
                                  THEN nother
                                  ELSE 0
                              END), 0) AS nother, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tmanualCall, dateStartDetail)) AS tmanualCall,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN tunknown2
                          ELSE 0
                      END AS tunknown2, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tchatting, dateStartDetail)) AS tchatting
               FROM #timeDetailAgent2 t
                    INNER JOIN TmpTimesInterval th ON(t.timegroup > th.Start
                                                      AND t.timegroup < th.stop)
                                                     OR th.Start BETWEEN t.timegroup AND t.timegroup_next
               WHERE DATEDIFF(ss, th.start, timegroup_next) > 0
                     AND th.Start BETWEEN @from AND @to;


        SELECT ROW_NUMBER() OVER(PARTITION BY xTimeDetail.user_id
               ORDER BY xTimeDetail.timegroup) AS Row, 
               xTimeDetail.timegroup, 
               xTimeDetail.[user_id], 
               timeSession.tlog, 
               xTimeDetail.tav, 
               xTimeDetail.tnot_av, 
               xTimeDetail.tprob, 
               xTimeDetail.tother, 
               xTimeDetail.tunknown, 
               xTimeDetail.tchatting, 
               xTimeDetail.tmanualCall, 
               xTimeDetail.nother, 
               ISNULL(B.txfer, 0) + ISNULL(C.txfer, 0) AS txfer, 
               ISNULL(B.tdialog, 0) + ISNULL(C.tdialog, 0) AS tdialog, 
               ISNULL(B.tnotes, 0) + ISNULL(C.tnotes, 0) AS tnotes, 
               ISNULL(B.tring, 0) + ISNULL(C.tring, 0) AS tring, 
               ISNULL(B.nMoh, 0) + ISNULL(C.nMoh, 0) AS nMoh, 
               ISNULL(B.nWHag, 0) + ISNULL(C.nWHag, 0) AS nWHag, 
               ISNULL(B.nWHcl, 0) + ISNULL(C.nWHcl, 0) AS nWHcl
        INTO #agentInformation
        FROM
        (
            SELECT x.User_id, 
                   x.timegroup,
                   CASE
                       WHEN SUM(tunknown + tunknown2) > 0
                       THEN SUM(tunknown + tunknown2)
                       ELSE SUM(tunknown)
                   END AS tunknown, 
                   SUM(tnot_av) AS tnot_av,
                   CASE
                       WHEN SUM(tav + tav2) > 0
                       THEN SUM(tav + tav2)
                       ELSE SUM(tav)
                   END AS tav,
                   CASE
                       WHEN SUM(tprob + tprob2) > 0
                       THEN SUM(tprob + tprob2)
                       ELSE SUM(tprob)
                   END AS tprob,
                   CASE
                       WHEN SUM(tother + tother2) > 0
                       THEN SUM(tother + tother2)
                       ELSE SUM(tother)
                   END AS tother,
                   CASE
                       WHEN SUM(tmanualcall + tmanualcall2) > 0
                       THEN SUM(tmanualcall + tmanualcall2)
                       ELSE SUM(tmanualcall)
                   END AS tmanualcall, 
                   SUM(nother) AS nother,
                   CASE
                       WHEN SUM(tchatting + tchatting2) > 0
                       THEN SUM(tchatting + tchatting2)
                       ELSE SUM(tchatting)
                   END AS tchatting
            FROM
            (
                SELECT User_id, 
                       timegroup, 
                       tunknown, 
                       tnot_av, 
                       tav, 
                       tprob, 
                       tother, 
                       tmanualcall, 
                       nother, 
                       tchatting, 
                       ISNULL(CAST(CASE
                                       WHEN tunknown > 0
                                       THEN tunknown2
                                       ELSE 0
                                   END AS INT), 0) AS tunknown2, 
                       ISNULL(CAST(CASE
                                       WHEN tav > 0
                                            AND (tav > ABS(tunknown2)
                                                 AND (tunknown2 + tav) > 0)
                                       THEN tunknown2
                                       ELSE 0
                                   END AS INT), 0) AS tav2, 
                       ISNULL(CAST(CASE
                                       WHEN tprob > 0
                                       THEN tunknown2
                                       ELSE 0
                                   END AS INT), 0) AS tprob2, 
                       ISNULL(CAST(CASE
                                       WHEN tother > 0
                                       THEN tunknown2
                                       ELSE 0
                                   END AS INT), 0) AS tother2, 
                       ISNULL(CAST(CASE
                                       WHEN tmanualcall > 0
                                       THEN tunknown2
                                       ELSE 0
                                   END AS INT), 0) AS tmanualcall2, 
                       ISNULL(CAST(CASE
                                       WHEN tchatting > 0
                                            OR (tchatting > ABS(tunknown2)
                                                AND (tunknown2 + tchatting) > 0)
                                       THEN tunknown2
                                       ELSE 0
                                   END AS INT), 0) AS tchatting2
                FROM #timeDetailAgent A
            ) x
            GROUP BY x.timegroup, 
                     x.User_id
        ) xTimeDetail
        INNER JOIN
        (
            SELECT user_id, 
                   timegroup, 
                   SUM(tlog) AS tlog
            FROM #sessionTimeGroup
            GROUP BY user_id, 
                     timegroup
        ) timeSession ON xTimeDetail.User_id = timeSession.user_id
                         AND xTimeDetail.timegroup = timeSession.timegroup
        LEFT JOIN
        (
            SELECT user_id, 
                   timegroup, 
                   SUM(txfer) AS txfer, 
                   SUM(tring) tring, 
                   SUM(tdialog) AS tdialog, 
                   SUM(tnotes) AS tnotes, 
                   SUM(nMoh) nMoh, 
                   SUM(nWHag) nWHag, 
                   SUM(nWHcl) nWHcl
            FROM #inboundData
            GROUP BY user_id, 
                     timegroup
        ) B ON xTimeDetail.timegroup = B.timegroup
               AND xTimeDetail.User_id = B.User_id
        LEFT JOIN
        (
            SELECT user_id, 
                   timegroup, 
                   SUM(txfer) AS txfer, 
                   SUM(tring) tring, 
                   SUM(tdialog) AS tdialog, 
                   SUM(tnotes) AS tnotes, 
                   SUM(nMoh) nMoh, 
                   SUM(nWHag) nWHag, 
                   SUM(nWHcl) nWHcl
            FROM #outboundData
            GROUP BY user_id, 
                     timegroup
        ) C ON xTimeDetail.timegroup = C.timegroup
               AND xTimeDetail.User_id = C.User_id;


        UPDATE B
          SET 
              B.tav = CASE
                          WHEN A.tav > 0
                               AND A.tav + A.tundefinded >= 0
                          THEN A.tav + A.tundefinded
                          ELSE A.tav
                      END
        FROM
        (
            SELECT User_id, 
                   timegroup, 
                   tlog, 
                   tav, 
                   tnot_av, 
                   tprob, 
                   tother, 
                   tunknown, 
                   tchatting, 
                   tmanualCall, 
                   nother, 
                   txfer, 
                   tdialog, 
                   tnotes, 
                   tring, 
                   tlog - tav - tnot_av - tprob - tother - tunknown - tchatting - tmanualCall - nother - txfer - tdialog - tnotes - tring AS tundefinded
            FROM #agentInformation
        ) A
        INNER JOIN #agentInformation B ON A.User_id = B.User_id
                                          AND A.timegroup = B.timegroup
        WHERE A.tundefinded < 0
              AND A.tav + A.tundefinded >= 0;


        UPDATE B
          SET 
              B.tunknown = CASE
                               WHEN A.tunknown > 0
                                    AND A.tunknown + A.tundefinded >= 0
                               THEN A.tunknown + A.tundefinded
                               ELSE A.tunknown
                           END
        FROM
        (
            SELECT User_id, 
                   timegroup, 
                   tlog, 
                   tav, 
                   tnot_av, 
                   tprob, 
                   tother, 
                   tunknown, 
                   tchatting, 
                   tmanualCall, 
                   nother, 
                   txfer, 
                   tdialog, 
                   tnotes, 
                   tring, 
                   tlog - tav - tnot_av - tprob - tother - tunknown - tchatting - tmanualCall - nother - txfer - tdialog - tnotes - tring AS tundefinded
            FROM #agentInformation
        ) A
        INNER JOIN #agentInformation B ON A.User_id = B.User_id
                                          AND A.timegroup = B.timegroup
        WHERE A.tundefinded < 0
              AND A.tunknown + A.tundefinded >= 0;


        SELECT ROW_NUMBER() OVER(
               ORDER BY CASE
                            WHEN agtInf.timegroup IS NOT NULL
                            THEN agtInf.timegroup
                            WHEN calls.timegroup IS NOT NULL
                            THEN calls.timegroup
                            ELSE 0
                        END,
                        CASE
                            WHEN agtInf.user_id IS NOT NULL
                            THEN agtInf.user_id
                            WHEN calls.userId IS NOT NULL
                            THEN calls.userId
                            ELSE-1
                        END) AS id, 
               agtInf.[row] rowAgentInformation, 
               ISNULL(rowIn, -1) rowIn, 
               ISNULL(rowOut, -1) rowOut, 
               ISNULL(callIdIn, '''') callIdIn, 
               ISNULL(phoneIn, '''') phoneIn, 
               ISNULL(dateStartDetailIn, '''') dateStartDetailIn, 
               ISNULL(callIdOut, '''') callIdOut, 
               ISNULL(phoneOut, '''') phoneOut, 
               ISNULL(dateStartDetailOut, '''') dateStartDetailOut, 
               (CASE
                    WHEN agtInf.timegroup IS NOT NULL
                    THEN agtInf.timegroup
                    WHEN calls.timegroup IS NOT NULL
                    THEN calls.timegroup
                    ELSE ''''
                END) [date], 
               (CASE
                    WHEN agtInf.user_id IS NOT NULL
                    THEN agtInf.user_id
                    WHEN calls.userId IS NOT NULL
                    THEN calls.userId
                    ELSE-1
                END) [userId], 
               u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + nombres AS [user], 
               u.login AS [login], 
               ISNULL(nxfer_in, 0) AS nxferin, 
               ISNULL(nanswer_in, 0) AS nanswerin, 
               ISNULL(nabnd_xfer_in, 0) AS nabndxferin, 
               ISNULL(nabnd_ring_in, 0) AS nabndringin, 
               ISNULL(nabnd_dlg_in, 0) AS nabnddlgin, 
               ISNULL(abnd_a_xfer_in, 0) AS abndaxferin, 
               ISNULL(nno_answer_in, 0) AS nnoanswerin, 
               ISNULL(nlost_in, 0) AS nlostin, 
               ISNULL(tdialog_in, 0) AS tdialogin, 
               ISNULL(tnotes_in, 0) AS tnotesin, 
               ISNULL(tring_in, 0) AS tringin, 
               ISNULL(txfer_in, 0) AS txferin, 
               ISNULL(nxfer_out, 0) AS nxferout, 
               ISNULL(nanswer_out, 0) AS nanswerout, 
               ISNULL(nabnd_xfer_out, 0) AS nabndxferout, 
               ISNULL(nabnd_ring_out, 0) AS nabndringout, 
               ISNULL(nabnd_dlg_out, 0) AS nabnddlgout, 
               ISNULL(abnd_a_xfer_out, 0) AS abndaxferout, 
               ISNULL(nno_answer_out, 0) AS nnoanswerout, 
               ISNULL(nlost_out, 0) AS nlostout, 
               ISNULL(tdialog_out, 0) AS tdialogout, 
               ISNULL(tnotes_out, 0) AS tnotesout, 
               ISNULL(tring_out, 0) AS tringout, 
               ISNULL(txfer_out, 0) AS txferout, 
               ISNULL(agtInf.nother, 0) AS nother, 
               ISNULL(agtInf.tunknown, 0) AS tunknown, 
               ISNULL(agtInf.tnot_av, 0) AS tnotav, 
               agtInf.tlog AS tlog, 
               ISNULL(agtInf.tav, 0) AS tav, 
               ISNULL(agtInf.tother, 0) + ISNULL(tmanualcall, 0) AS tother, 
               ISNULL(agtInf.tprob, 0) AS tprob, 
               ISNULL(agtInf.tchatting, 0) AS tchatting, 
               ISNULL(nMoh_in, 0) AS nMohin, 
               ISNULL(nMoh_out, 0) AS nMohout, 
               ISNULL(nWHag_in, 0) AS nWHagin, 
               ISNULL(nWHag_out, 0) AS nWHagout, 
               ISNULL(nWHcl_in, 0) AS nWHcliin, 
               ISNULL(nWHcl_out, 0) AS nWHcliout,
               CASE
                   WHEN agtInf.timegroup IS NOT NULL
                   THEN DATEPART(yy, agtInf.timegroup)
                   WHEN calls.timegroup IS NOT NULL
                   THEN DATEPART(yy, calls.timegroup)
                   ELSE 0
               END AS [year],
               CASE
                   WHEN agtInf.timegroup IS NOT NULL
                   THEN DATEPART(mm, agtInf.timegroup)
                   WHEN calls.timegroup IS NOT NULL
                   THEN DATEPART(mm, calls.timegroup)
                   ELSE 0
               END AS [month],
               CASE
                   WHEN agtInf.timegroup IS NOT NULL
                   THEN DATEPART(dd, agtInf.timegroup)
                   WHEN calls.timegroup IS NOT NULL
                   THEN DATEPART(dd, calls.timegroup)
                   ELSE 0
               END AS [day],
               CASE
                   WHEN agtInf.timegroup IS NOT NULL
                   THEN DATEPART(hh, agtInf.timegroup)
                   WHEN calls.timegroup IS NOT NULL
                   THEN DATEPART(hh, calls.timegroup)
                   ELSE 0
               END AS [hour],
               CASE
                   WHEN agtInf.timegroup IS NOT NULL
                   THEN DATEPART(mi, agtInf.timegroup)
                   WHEN calls.timegroup IS NOT NULL
                   THEN DATEPART(mi, calls.timegroup)
                   ELSE 0
               END AS [minutes]
        INTO #tempRepAgentGI
        FROM #agentInformation agtInf
             LEFT JOIN ccUserView u ON agtInf.[user_id] = u.[user_id]
             LEFT JOIN
        (
            SELECT(CASE
                       WHEN _in.timegroup IS NOT NULL
                       THEN _in.timegroup
                       ELSE _out.timegroup
                   END) timegroup, 
                  (CASE
                       WHEN _in.[user_id] IS NOT NULL
                       THEN _in.[user_id]
                       ELSE _out.[user_id]
                   END) [userId], 
                  ISNULL(_in.row, -1) AS rowIn, 
                  ISNULL(_out.row, -1) AS rowOut, 
                  ISNULL((_in.nxfer), 0) AS nxfer_in, 
                  ISNULL((_in.nanswer), 0) AS nanswer_in, 
                  ISNULL((_in.nabnd_xfer), 0) AS nabnd_xfer_in, 
                  ISNULL((_in.nabnd_ring), 0) AS nabnd_ring_in, 
                  ISNULL((_in.nabnd_dialog), 0) AS nabnd_dlg_in, 
                  ISNULL((_in.nabnd_xfer), 0) + ISNULL((_in.nabnd_ring), 0) + ISNULL((_in.nabnd_dialog), 0) AS abnd_a_xfer_in, 
                  ISNULL((_in.nno_answer), 0) AS nno_answer_in, 
                  ISNULL((_in.nlost), 0) AS nlost_in, 
                  ISNULL((_in.tdialog), 0) AS tdialog_in, 
                  ISNULL((_in.tnotes), 0) AS tnotes_in, 
                  ISNULL((_in.tring), 0) AS tring_in, 
                  ISNULL((_in.txfer), 0) AS txfer_in, 
                  ISNULL((_in.nMoh), 0) AS nMoh_in, 
                  ISNULL((_in.nWHag), 0) AS nWHag_in, 
                  ISNULL((_in.nWHcl), 0) AS nWHcl_in, 
                  ISNULL((_out.nxfer), 0) AS nxfer_out, 
                  ISNULL((_out.nanswer), 0) AS nanswer_out, 
                  ISNULL((_out.nabnd_xfer), 0) AS nabnd_xfer_out, 
                  ISNULL((_out.nabnd_ring), 0) AS nabnd_ring_out, 
                  ISNULL((_out.nabnd_dialog), 0) AS nabnd_dlg_out, 
                  ISNULL((_out.nabnd_xfer), 0) + ISNULL((_out.nabnd_ring), 0) + ISNULL((_out.nabnd_dialog), 0) AS abnd_a_xfer_out, 
                  ISNULL((_out.nno_answer), 0) AS nno_answer_out, 
                  ISNULL((_out.nlost), 0) AS nlost_out, 
                  ISNULL((_out.tdialog), 0) AS tdialog_out, 
                  ISNULL((_out.tnotes), 0) AS tnotes_out, 
                  ISNULL((_out.tring), 0) AS tring_out, 
                  ISNULL((_out.txfer), 0) AS txfer_out, 
                  ISNULL((_out.nMoh), 0) AS nMoh_out, 
                  ISNULL((_out.nWHag), 0) AS nWHag_out, 
                  ISNULL((_out.nWHcl), 0) AS nWHcl_out, 
                  ISNULL((_in.cal_id), '''') AS callIdIn, 
                  ISNULL((_in.phone_in), '''') AS phoneIn, 
                  ISNULL((_in.dateStartDetail), '''') AS dateStartDetailIn, 
                  ISNULL((_out.cal_id), '''') AS callIdOut, 
                  ISNULL((_out.phone_out), '''') AS phoneOut, 
                  ISNULL((_out.dateStartDetail), '''') AS dateStartDetailOut
            FROM #inboundData _in
                 FULL OUTER JOIN #outboundData _out ON _in.timegroup = _out.timegroup
                                                       AND _in.[user_id] = _out.[user_id]
        ) calls ON calls.timegroup = agtInf.timegroup
                   AND agtInf.[user_id] = calls.[userid]
        WHERE agtInf.timegroup IS NOT NULL;


        UPDATE A
          SET 
              nother = 0, 
              tunknown = 0, 
              tnotav = 0, 
              tlog = 0, 
              tother = 0, 
              tprob = 0, 
              tav = 0, 
              tchatting = 0
        FROM
        (
            SELECT RANK() OVER(PARTITION BY A.rowAgentInformation, 
                                            A.userId
                   ORDER BY id) AS [rank], 
                   A.id
            FROM #tempRepAgentGI A
                 INNER JOIN
            (
                SELECT temp.rowAgentInformation, 
                       temp.[UserId]
                FROM #tempRepAgentGI temp
                GROUP BY temp.rowAgentInformation, 
                         temp.[UserId]
                HAVING COUNT(*) > 1
            ) B ON A.userId = B.userId
                   AND A.rowAgentInformation = B.rowAgentInformation
        ) x
        INNER JOIN #tempRepAgentGI A ON A.id = x.id
        WHERE x.rank > 1;


        UPDATE A
          SET 
              nxferin = 0, 
              nanswerin = 0, 
              nabndxferin = 0, 
              nabndringin = 0, 
              nabnddlgin = 0, 
              abndaxferin = 0, 
              nnoanswerin = 0, 
              nlostin = 0, 
              tdialogin = 0, 
              tnotesin = 0, 
              tringin = 0, 
              txferin = 0, 
              nMohin = 0, 
              nWHagin = 0, 
              nWHcliin = 0
        FROM
        (
            SELECT RANK() OVER(PARTITION BY A.rowIn, 
                                            A.userId
                   ORDER BY id) AS [rank], 
                   A.id
            FROM #tempRepAgentGI A
                 INNER JOIN
            (
                SELECT temp.rowIn, 
                       temp.[UserId]
                FROM #tempRepAgentGI temp
                GROUP BY temp.rowIn, 
                         temp.[UserId]
                HAVING COUNT(*) > 1
            ) B ON A.userId = B.userId
                   AND A.rowIn = B.rowIn
        ) x
        INNER JOIN #tempRepAgentGI A ON A.id = x.id
        WHERE x.rank > 1;


        UPDATE A
          SET 
              nxferout = 0, 
              nanswerout = 0, 
              nabndxferout = 0, 
              nabndringout = 0, 
              nabnddlgout = 0, 
              abndaxferout = 0, 
              nnoanswerout = 0, 
              nlostout = 0, 
              tdialogout = 0, 
              tnotesout = 0, 
              tringout = 0, 
              txferout = 0, 
              nMohout = 0, 
              nWHagout = 0, 
              nWHcliout = 0
        FROM
        (
            SELECT RANK() OVER(PARTITION BY A.rowOut, 
                                            A.userId
                   ORDER BY id) AS [rank], 
                   A.id
            FROM #tempRepAgentGI A
                 INNER JOIN
            (
                SELECT temp.rowOut, 
                       temp.[UserId]
                FROM #tempRepAgentGI temp
                GROUP BY temp.rowOut, 
                         temp.[UserId]
                HAVING COUNT(*) > 1
            ) B ON A.userId = B.userId
                   AND A.rowOut = B.rowOut
        ) x
        INNER JOIN #tempRepAgentGI A ON A.id = x.id
        WHERE x.rank > 1;


        DELETE FROM RepAgentGI
        WHERE date >= @from
              AND date < @to;


        INSERT INTO RepAgentGI
        (date, 
         userId, 
         [user], 
         login, 
         nxferin, 
         nanswerin, 
         nabndxferin, 
         nabndringin, 
         nabnddlgin, 
         abndaxferin, 
         nnoanswerin, 
         nlostin, 
         tdialogin, 
         tnotesin, 
         tringin, 
         txferin, 
         nxferout, 
         nanswerout, 
         nabndxferout, 
         nabndringout, 
         nabnddlgout, 
         abndaxferout, 
         nnoanswerout, 
         nlostout, 
         tdialogout, 
         tnotesout, 
         tringout, 
         txferout, 
         nother, 
         tunknown, 
         tnotav, 
         tlog, --treq,
         tav, 
         tother, 
         tprob, 
         nmohin, 
         nmohout, 
         nwhagin, 
         nwhagout, 
         nwhcliin, 
         nwhcliout, 
         year, 
         month, 
         day, 
         hour, 
         minutes, 
         phonein, 
         dateStartDetailIn, 
         callIdIn, 
         phoneout, 
         dateStartDetailOut, 
         callIdOut, 
         tnotavg, 
         tundefined, 
         tchatting
        )
               SELECT date, 
                      userId, 
                      ISNULL([user], ''otro''), 
                      ISNULL(login, ''otro'') login, 
                      nxferin, 
                      nanswerin, 
                      nabndxferin, 
                      nabndringin, 
                      nabnddlgin, 
                      abndaxferin, 
                      nnoanswerin, 
                      nlostin, 
                      tdialogin, 
                      tnotesin, 
                      tringin, 
                      txferin, 
                      nxferout, 
                      nanswerout, 
                      nabndxferout, 
                      nabndringout, 
                      nabnddlgout, 
                      abndaxferout, 
                      nnoanswerout, 
                      nlostout, 
                      tdialogout, 
                      tnotesout, 
                      tringout, 
                      txferout, 
                      nother, 
                      tunknown, 
                      tnotav, 
                      tlog, --treq,
                      tav, 
                      tother, 
                      tprob, 
                      nmohin, 
                      nmohout, 
                      nwhagin, 
                      nwhagout, 
                      nwhcliin, 
                      nwhcliout, 
                      year, 
                      month, 
                      day, 
                      hour, 
                      minutes, 
                      phonein, 
                      dateStartDetailIn, 
                      callIdIn, 
                      phoneout, 
                      dateStartDetailOut, 
                      callIdOut, 
                      tnotav, 
                      (tlog - tdialogin - tnotesin - tringin - txferin - tdialogout - tnotesout - tringout - txferout - tunknown - tnotav - tav - tother - tprob - tchatting) AS tundefined, 
                      tChatting
               FROM #tempRepAgentGI;

		
        --DROP TABLES TEMP	
        IF OBJECT_ID(''tempdb..#inboundData'') IS NOT NULL
            DROP TABLE #inboundData;
        IF OBJECT_ID(''tempdb..#inboundData2'') IS NOT NULL
            DROP TABLE #inboundData2;
        IF OBJECT_ID(''tempdb..#outboundData'') IS NOT NULL
            DROP TABLE #outboundData;
        IF OBJECT_ID(''tempdb..#outboundData2'') IS NOT NULL
            DROP TABLE #outboundData2;
        IF OBJECT_ID(''tempdb..#timeDetailAgent'') IS NOT NULL
            DROP TABLE #timeDetailAgent;
        IF OBJECT_ID(''tempdb..#timeDetailAgent2'') IS NOT NULL
            DROP TABLE #timeDetailAgent2;
        IF OBJECT_ID(''tempdb..#agentInformation'') IS NOT NULL
            DROP TABLE #agentInformation;
        IF OBJECT_ID(''tempdb..#tempRepAgentGI'') IS NOT NULL
            DROP TABLE #tempRepAgentGI;
        IF OBJECT_ID(''tempdb..#tempAgentLastStatus'') IS NOT NULL
            DROP TABLE #tempAgentLastStatus;
        IF OBJECT_ID(''tempdb..#tempccLogAgentesDia'') IS NOT NULL
            DROP TABLE #tempccLogAgentesDia;
        IF OBJECT_ID(''tempdb..#tempccLogAgentesDia2'') IS NOT NULL
            DROP TABLE #tempccLogAgentesDia2;
        IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL
            DROP TABLE #sessionTimeGroup;
END;'
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

