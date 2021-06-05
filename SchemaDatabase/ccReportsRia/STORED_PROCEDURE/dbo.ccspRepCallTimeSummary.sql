CREATE PROCEDURE [dbo].[ccspRepCallTimeSummary]
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
		
			IF OBJECT_ID('tempdb..#aband') IS NOT NULL drop table #aband;
			IF OBJECT_ID('tempdb..#inboundTime') IS NOT NULL drop table #inboundTime;
			IF OBJECT_ID('tempdb..#inboundTimeMayores') IS NOT NULL drop table #inboundTimeMayores;
			IF OBJECT_ID('tempdb..#outboundTime') IS NOT NULL drop table #outboundTime;
			IF OBJECT_ID('tempdb..#outboundTimeMayores') IS NOT NULL drop table #outboundTimeMayores;
			IF OBJECT_ID('tempdb..#chats') IS NOT NULL drop table #chats;
			IF OBJECT_ID('tempdb..#chatsMayores') IS NOT NULL drop table #chatsMayores;
			IF OBJECT_ID('tempdb..#aux') IS NOT NULL drop table #aux;
			IF OBJECT_ID('tempdb..#auxMayores') IS NOT NULL drop table #auxMayores;

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
		-------------------------------CTE'S--------------------------
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
		select A.timegroup 'Fecha',A.user_id 'ID agente'
		,u.Nombres+' '+u.ApellidoPaterno 'username',u.Login 'agentName',a.tlog 'sesionTime'
		,ISNULL(auxt.timeAux,0) 'tiemponoDisponible',ISNULL(auxt.timeDisp,0) 'tiempoDisponible'
		,stuff(right(convert(varchar(30), A.login, 109), 14), 9, 4, ' ') 'sessionStart',stuff(right(convert(varchar(30), A.logout, 109), 14), 9, 4, ' ') 'sessionEnd'
		,(isnull(callIn.cal_tDialog,0)+isnull(callOut.cal_tDialog,0)) 'generalDialog'
		,isnull((isnull(callIn.cal_tDialog,0)+isnull(callOut.cal_tDialog,0))/( nullif( isnull(callIn.totalIn,0)+isnull(callOut.totalIn,0),0)),0) 'avgCallTime'
		,isnull(callIn.cal_tDialog,0) 'inboundDialog',isnull(callIn.avgtimein,0) as 'avginboundDialog'
		,isnull(callOut.cal_tDialog,0) 'outboundDialog',isnull(callOut.avgtimeout,0) 'avgoutboundDialog'
		,isnull(chatTime.timeChat,0) as 'chatTime',ISNULL(chatTime.avgttimeChat,0) as 'avgchatTime',
		isnull(chatTime.totalChat,0) as 'attendedChat',isnull(callOut.totalIn,0) as 'callsOut',
		isnull(callIn.totalIn,0) as 'callsIn',isnull(abant.totalAband,0) as 'abandonedCalls'
		,(isnull(callOut.totalIn,0)+isnull(callIn.totalIn,0)) 'answerCalls'
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

		IF OBJECT_ID('tempdb..#aband') IS NOT NULL drop table #aband;
		IF OBJECT_ID('tempdb..#inboundTime') IS NOT NULL drop table #inboundTime;
		IF OBJECT_ID('tempdb..#inboundTimeMayores') IS NOT NULL drop table #inboundTimeMayores;
		IF OBJECT_ID('tempdb..#outboundTime') IS NOT NULL drop table #outboundTime;
		IF OBJECT_ID('tempdb..#outboundTimeMayores') IS NOT NULL drop table #outboundTimeMayores;
		IF OBJECT_ID('tempdb..#chats') IS NOT NULL drop table #chats;
		IF OBJECT_ID('tempdb..#chatsMayores') IS NOT NULL drop table #chatsMayores;
		IF OBJECT_ID('tempdb..#aux') IS NOT NULL drop table #aux;
		IF OBJECT_ID('tempdb..#auxMayores') IS NOT NULL drop table #auxMayores;
	
		END