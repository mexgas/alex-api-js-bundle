SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 98

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'CW-4463 se modifica sp ccspRepACDChats'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepACDChats]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
Begin
select @from = convert(datetime,convert(varchar(11),getdate()))
End
if @to is null 
begin
select @to = convert(datetime,convert(varchar(11),getdate()))
end

DECLARE @tresDialog AS smallint
EXEC @tresDialog =  ccspConfigTresDialog

declare @DTChat as int
select @DTChat = valor from ccsettings where setting_id = 33

if @action = 1 
begin

	delete from RepACDChats with(rowlock)
	where date >= @from AND date < @to
	
	insert into RepACDChats
		select fecha,
		inboundId, b.descripcion, ChatDetail.domain, b.IDArea, c.AreaName,
		max([totalChats]) TotalChats,
		sum([waitingAbandoned])waitingAbandoned,
		sum([waitingConnected])waitingConnected,
		max(maxTQueue)maxTQueue,
		max(avgTQueue)avgTQueue,
		sum([onQueue])onQueue,
		sum([Connected])Connected,
		sum([UnavailableAgents] + [OutOfService] + [OutOfSchedule] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow] + [Assigned] + [Connected<DT])NoConnected,
		0.00 as levelService,
		sum([byCostumer]) as finishedByCostumer,
		sum([byAgent]) as finishedByAgent,
		sum([bySystem]) as finishedBySystem,
		sum([byAdmin]) as finishedByAdmin,
		datepart(yyyy,CONVERT(varchar(20), fecha, 120)) as [year],
		datepart(mm,CONVERT(varchar(20), fecha, 120)) as [month],
		datepart(dd,CONVERT(varchar(20), fecha, 120)) as [day],
		datepart(hh,CONVERT(varchar(20), fecha, 120)) as [hour],
		datepart(mi,CONVERT(varchar(20), fecha, 120)) as [minutes]
		from(

			select inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as fecha,
			count(*) as [totalChats],
			domain,
			ISNULL(count(CASE WHEN (chatstatus = 9 and tQueue>=@tresDialog) THEN 1 ELSE NULL END),0)AS [waitingAbandoned],
			ISNULL(count(CASE WHEN (chatstatus = 4 and onQueue = 1) THEN 1 ELSE NULL END),0)AS [waitingConnected],
			ISNULL(count(CASE WHEN (chatstatus = 4 and tChatting >= @DTChat) THEN 1 ELSE NULL END),0)AS [Connected],
			ISNULL(count(CASE WHEN (chatstatus = 4 and tChatting < @DTChat) THEN 1 ELSE NULL END),0)AS [Connected<DT],
			ISNULL(count(CASE WHEN onQueue = 1 THEN 1 ELSE NULL END),0)AS [onQueue],
			ISNULL(count(CASE WHEN(chatstatus = 2)THEN 1 ELSE NULL END),0)AS [UnavailableAgents],
			ISNULL(count(CASE WHEN (chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
			ISNULL(count(CASE WHEN(chatstatus = 5)THEN 1 ELSE NULL END),0)AS [OutOfService],
			ISNULL(count(CASE WHEN(chatstatus = 6)THEN 1 ELSE NULL END),0)AS [OutOfSchedule],
			ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
			ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
			ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
			ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow],
			ISNULL(count(CASE WHEN(finishedBy = 0)THEN 1 ELSE NULL END),0) AS [byCostumer],
			ISNULL(count(CASE WHEN(finishedBy = 1)THEN 1 ELSE NULL END),0) AS [byAgent],
			ISNULL(count(CASE WHEN(finishedBy = 2)THEN 1 ELSE NULL END),0) AS [bySystem],
			ISNULL(count(CASE WHEN(finishedBy = 3)THEN 1 ELSE NULL END),0) AS [byAdmin],
			max(tqueue) as maxTQueue,
			avg(tqueue) as avgTQueue
			from ccRIAChats a
			where
			chatStatus in (2,3,4,5,6,7,9,10,11)
			group by inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121), domain
			
		) as ChatDetail
		left join ccInbound b on (b.inbound_id = ChatDetail.inboundId)
		left join ccRIACat_Areas c on (c.IDArea = b.IDArea)
		where fecha >= @from and fecha < @to
		group by inboundId, fecha, b.descripcion, ChatDetail.domain, b.IDArea, c.AreaName
		
		
		select inboundId, descripcion, date,
		isnull(convert(decimal(10,2),convert(float,([Connected]+[AbandonnedValid])/NULLIF(convert(float, Total),0))* 100.00),0) as NS
		into #tmpns
		from (
		select inboundId, descripcion, Date,
		sum([Connected>DT]) as [Connected], 
		sum([CCAb]) as [AbandonnedValid],
		sum([Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow] + [UnavailableAgents] + [OutOfService] + [OutOfSchedule]) as NotConnected,
		sum([Connected>DT] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow] + [UnavailableAgents] + [OutOfService] + [OutOfSchedule]) as Total
		from (
		select inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as Date ,
		ISNULL(count(case when (chatStatus = 9 and tQueue<@tresDialog) then 1 else null end),0) As [CCAb],
		ISNULL(count(CASE WHEN (chatstatus = 4 and tChatting >= @DTChat) THEN 1 ELSE NULL END),0)AS [Connected>DT],
		ISNULL(count(CASE WHEN (chatstatus = 4 and tChatting < @DTChat) THEN 1 ELSE NULL END),0)AS [Connected<DT],
		ISNULL(count(CASE WHEN (chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
		ISNULL(count(CASE WHEN(chatstatus = 2)THEN 1 ELSE NULL END),0)AS [UnavailableAgents],
		ISNULL(count(CASE WHEN(chatstatus = 5)THEN 1 ELSE NULL END),0)AS [OutOfService],
		ISNULL(count(CASE WHEN(chatstatus = 6)THEN 1 ELSE NULL END),0)AS [OutOfSchedule],
		ISNULL(count(CASE WHEN (chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
		ISNULL(count(CASE WHEN (chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
		ISNULL(count(CASE WHEN (chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
		ISNULL(count(CASE WHEN (chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow]
		from ccRIAChats a
		left outer join ccInbound c on (inboundId = inbound_id)
		where chatStatus in (2,3,4,5,6,7,9,10,11)
		and requestDate  >= @from and requestDate < @to
		group by inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121)) as ChatDetail
		group by inboundId, descripcion, Date) as ChatSummary order by date, inboundid

		update RepACDChats set SL = b.NS
		from RepACDChats a, #tmpns b where a.date = b.date and a.inboundId = b.inboundId and b.date >= @from and b.date < @to
		drop table #tmpns
end'
		EXEC(@sql)

		SET @process = 'CW-4463 se modifica sp ccspRepChatsAndCallsGeneral'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepChatsAndCallsGeneral]
					@action as tinyint,
					@from as datetime = null,
					@to as datetime = null
					AS

					if @from is null
					begin
						select @from = convert(datetime,convert(varchar(11),getdate()))
					end
					if @from is null
					begin
						select @to = convert(datetime,convert(varchar(11),getdate()))
					end

					DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
					SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
					DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

					EXEC @tresRing=ccspConfigTresRing
					EXEC @tresDialog=ccspConfigTresDialog
					EXEC @tresDelayIn=ccspConfigtresDelayIn
					
					declare @DTChat as int
					select @DTChat = valor from ccsettings where setting_id = 33

					if @action = 1
						begin
							CREATE TABLE [dbo].[#callsin](
								[timegroup] [smalldatetime] NOT NULL,
								[inbound_id] [smallint] NOT NULL,
								[dni_id] [smallint] NOT NULL,
								[user_id] [smallint] NOT NULL,
								[ntotal] [smallint] NOT NULL,
								[ninitial] [smallint] NOT NULL,
								[nout_hour] [smallint] NOT NULL,
								[nout_service] [smallint] NOT NULL,
								[nabnd] [smallint] NOT NULL,
								[nno_agent] [smallint] NOT NULL,
								[nque] [smallint] NOT NULL,
								[ntimeout] [smallint] NOT NULL,
								[noverflow] [smallint] NOT NULL,
								[nxfer] [smallint] NOT NULL,
								[nxfer_que] [smallint] NOT NULL,
								[nabnd_xfer] [smallint] NOT NULL,
								[nabnd_ring] [smallint] NOT NULL,
								[nno_answer] [smallint] NOT NULL,
								[nabnd_dialog] [smallint] NOT NULL,
								[nanswer] [smallint] NOT NULL,
								[nlost] [smallint] NOT NULL,
								[nmsg] [smallint] NOT NULL,
								[nabnd_tres] [smallint] NOT NULL,
								[nansw_tres] [smallint] NOT NULL,
								[tque_max] [smallint] NOT NULL,
								[tque] [int] NOT NULL,
								[txfer] [int] NOT NULL,
								[tdialog] [int] NOT NULL,
								[tnotes] [int] NOT NULL,
								[tring] [int] NOT NULL,
								[tresp] [int] NOT NULL,
								[nMoh] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCall_nMoh]  DEFAULT ((0)),
								[nWHag] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCall_nWHag]  DEFAULT ((0)),
								[nWHcl] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCall_nWHcl]  DEFAULT ((0)),
							) ON [PRIMARY]

							INSERT INTO #callsin(timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque
							,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg
							,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
							SELECT timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
							,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
							,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
							FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
								,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
								,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
								,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
								,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
								,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
								,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
								,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
							FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,dni_id,[user_id]
								,COUNT(cal_id)AS ntotal
								,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
								,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour 
								,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
								,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd 
								,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent
								,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que 
								,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout
								,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow
								,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS xfer
								,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END)AS xfer_que
								,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer
								,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
								,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer
								,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
								,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
								,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost
								,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg
								,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres
								,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
								,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
								,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
								,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
								,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
							FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
							GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,dni_id,[user_id])xDetailCount
							right JOIN(SELECT timegroup,inbound_id,dni_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
								,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
							FROM(SELECT timegroup,inbound_id,dni_id,[user_id]
								,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
								,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
								,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
								,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
								,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
							FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
								,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
								,*
							FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
							UNION
							SELECT timegroup_next,inbound_id,dni_id,[user_id]
								,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
								,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
								,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
								,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
								,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
							FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
								,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
								,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
							GROUP BY timegroup,inbound_id,dni_id,[user_id])xDetailTime
							ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id = xDetailCount.dni_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
							WHERE timegroup>=@from AND timegroup<@to
							AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
							AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
							AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
							AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
							ORDER BY timegroup,inbound_id,dni_id,[user_id]

							SELECT CONVERT(varchar(20), timegroup, 120) as [date], ccInbound.inbound_id as inboundId, descripcion as inbound, 
							ntotal, nabnd_que, tque_max, nnoanswer, nanswer, SL, avgTQueue
							into #partialCalls
							FROM (SELECT xDetCall.tg as timegroup , xDetCall.inbound_id  as inbound_id,
								ISNULL(ntotal, 0) ntotal, ISNULL(nabnd_que, 0) nabnd_que , ISNULL(tque_max, 0) tque_max , 
								ISNULL(tque, 0) tque, ISNULL(nanswer, 0) nanswer , ISNULL(tque/ NULLIF(nque, 0), 0) avgTQueue, 
								convert(decimal(10,2),ISNULL(SL_P_1 * 100 / NULLIF(ntotal,0), 0)) SL, ninitial + [nout_hour] + nabnd_xfer + nabnd_ring + nabnd_dialog + nno_agent + ntimeout + noverflow + nno_answer + nlost as nnoanswer,
								SL_P_1, SL_P_2
								FROM (SELECT timegroup as tg, inbound_id, SUM(ntotal) ntotal , SUM(nabnd) nabnd_que , 
									MAX(tque_max) tque_max, NULLIF(SUM(nque), 0) nque,
									SUM(tque) tque, SUM(nanswer) nanswer, SUM(nanswer) AS SL_P_1 , 
									SUM(ninitial + [nout_hour] +  nabnd_xfer + nabnd_ring + nabnd_dialog + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, 
									SUM(nabnd) nabnd, SUM(nno_agent) nno_agent, SUM(ntimeout) ntimeout, SUM(noverflow) noverflow, 
									SUM(nno_answer) nno_answer, SUM(nlost) nlost, sum([nout_hour]) [nout_hour], sum(nabnd_xfer) nabnd_xfer,
									SUM(nabnd_ring) nabnd_ring, SUM(nabnd_dialog) nabnd_dialog, SUM(ninitial) ninitial
									FROM #callsin  
									WHERE timegroup >= @from 
									AND timegroup < @to
									GROUP BY  timegroup, inbound_id) xDetCall) xDetail  
							INNER JOIN ccInbound ON (xDetail.inbound_id = ccInbound.inbound_id) 
							where ccInbound.inbound_id is not null
							order by descripcion, CONVERT(varchar(20), timegroup, 120)

							select fecha as date,
							inboundId, b.descripcion,
							max([totalChats]) as [totalChats],
							sum([waitingAbandoned]) as [waitingAbandoned],
							max(maxTQueue) as maxTQueue,
							sum([UnavailableAgents] + [OutOfService] + [OutOfSchedule] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow] + [Assigned] + [Connected<DT]) as [notConnected],
							sum([Connected]) as [Connected],
							''000.00'' as SL,
							max(avgTQueue) as avgTQueue
							into #partialChats
							from(

								select inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as fecha,
								count(*) as [totalChats],
								domain,
								ISNULL(count(CASE WHEN (chatstatus = 9and tQueue>=@tresDialog) THEN 1 ELSE NULL END),0)AS [waitingAbandoned],
								ISNULL(count(CASE WHEN (chatstatus = 4 and tChatting >= @DTChat) THEN 1 ELSE NULL END),0)AS [Connected],
								ISNULL(count(CASE WHEN(chatstatus = 4 and tChatting < @DTChat) THEN 1 ELSE NULL END),0)AS [Connected<DT],
								ISNULL(count(CASE WHEN(chatstatus = 2)THEN 1 ELSE NULL END),0)AS [UnavailableAgents],
								ISNULL(count(CASE WHEN (chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
								ISNULL(count(CASE WHEN(chatstatus = 5)THEN 1 ELSE NULL END),0)AS [OutOfService],
								ISNULL(count(CASE WHEN(chatstatus = 6)THEN 1 ELSE NULL END),0)AS [OutOfSchedule],
								ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
								ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
								ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
								ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow],
								max(tqueue) as maxTQueue,
								avg(tqueue) as avgTQueue
								from ccRIAChats a
								where
								chatStatus in (2,3,5,6,4,7,9,10,11)
								group by inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121), domain
			
							) as ChatDetail
							left join ccInbound b on (b.inbound_id = ChatDetail.inboundId)
							where fecha >= @from and fecha < @to
							group by inboundId, fecha, b.descripcion
							

							select inboundId, descripcion, date,
							convert(decimal(10,2),ISNULL(convert(float,[Connected]) * 100 / NULLIF(convert(float,Total),0), 0)) as NS
							into #tmpns
							from
							(select inboundId, descripcion, Date,
							sum([Connected>DT] + [AbandonValid]) as [Connected], 
							sum([Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow] + [UnavailableAgents] + [OutOfService] + [OutOfSchedule]) as NotConnected,
							sum([Connected>DT] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow] + [UnavailableAgents] + [OutOfService] + [OutOfSchedule]) as Total
							from (
							select inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as Date,
							ISNULL(count(CASE WHEN(chatstatus = 4 and tChatting >= @DTChat) THEN 1 ELSE NULL END),0)AS [Connected>DT],
							ISNULL(count(CASE WHEN(chatstatus = 4 and tChatting < @DTChat) THEN 1 ELSE NULL END),0)AS [Connected<DT],
							ISNULL(count(CASE WHEN(chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
							ISNULL(count(CASE WHEN(chatstatus = 2)THEN 1 ELSE NULL END),0)AS [UnavailableAgents],
							ISNULL(count(CASE WHEN(chatstatus = 5)THEN 1 ELSE NULL END),0)AS [OutOfService],
							ISNULL(count(CASE WHEN(chatstatus = 6)THEN 1 ELSE NULL END),0)AS [OutOfSchedule],
							ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
							ISNULL(count(CASE WHEN(chatstatus = 9 and tQueue<@tresDialog)THEN 1 ELSE NULL END),0)AS [AbandonValid],
							ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
							ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
							ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow]
							from ccRIAChats a
							left outer join ccInbound c on (inboundId = inbound_id)
							where chatStatus in (2,3,4,5,6,7,9,10,11)
							and requestDate  >= @from and requestDate < @to
							group by inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121)) as ChatDetail
							group by inboundId, descripcion, Date) as ChatSummary order by date, inboundid
		
							update #partialChats set SL = b.NS
							from #partialChats a, #tmpns b where a.date = b.date and a.inboundId = b.inboundId

							delete RepChatsAndCallsGeneral with(rowlock)
							where date >= @from and date <= @to

							insert into RepChatsAndCallsGeneral
							select 
							convert(datetime,isnull(a.date, b.date)) as date,
							isnull(a.inboundId,b.inboundId) as inboundId, 
							isnull(a.inbound,b.descripcion) as descripcion,
							isnull(ntotal,0) as ntotal, 
							isnull(totalChats,0) as totalChats, 
							isnull(nabnd_que,0) as nabnd_que, 
							isnull(waitingAbandoned,0) as waitingAbandoned, --CHAT en espera abandonas
							isnull(tque_max,0) as tque_max, 
							isnull(maxTQueue,0) as maxTQueue, -- Tiempo en espera
							isnull(nnoanswer,0) as nnoanswer, 
							isnull(notConnected,0) as notConnected,
							isnull(nanswer,0) as nanswer, 
							isnull(Connected,0) as Connected, 
							isnull(a.SL,0) as SL1,
							isnull(b.SL,0) as SL2, 
							isnull(a.avgTQueue,0) as avgTQueue1, 
							isnull(b.avgTQueue,0) as avgTQueue2,
							datepart(yyyy,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [year],
							datepart(mm,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [month],
							datepart(dd,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [day],
							datepart(hh,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [hour],
							datepart(mi,CONVERT(varchar(20), convert(datetime,isnull(a.date, b.date)), 120)) as [minutes]
							from #partialCalls a
							full join #partialChats b on (a.date = b.date and a.inboundId = b.inboundId)

		
							drop table #tmpns
							drop table #partialChats
							drop table #partialCalls
							drop table #callsin
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

