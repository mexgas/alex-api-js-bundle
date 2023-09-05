SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 122

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY



	set @process = 'DEV3-463 DROP PROCEDURE ccspRepChatsDetail'
	set @Sql= 'if exists (select * from sys.procedures where name = N''ccspRepChatsDetail'')
    begin
       DROP PROCEDURE ccspRepChatsDetail;
    end'
	EXEC(@Sql)	

	set @process = 'DEV3-463 CREATE PROCEDURE ccspRepChatsDetail'
	set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepChatsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1 
begin
	delete from RepChatsDetail with(rowlock) where date >= @from AND date < @to
	
	insert into RepChatsDetail
	select requestDate,
	inboundId, b.descripcion, chatstatus, c.description, disposition, isnull(d.description,''''),
	subDisposition, isnull(califSubDesc,''''), domain, userid, isnull(f.login,''''), clientName, tqueue [mohTime],
	case when chatStatus = 4 then
		case 
			when (isnull(datediff(ss,requestDate,chatdate),0) - tqueue) < 0 then 0 
			else  isnull(datediff(ss,requestDate,chatdate) - tqueue,0) end
	else 0 	end	txfer,
	tchatting, 
	isnull(nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''') as Nombre,
	YEAR(requestDate) as [year],
	MONTH(requestDate) as [month],
	DAY(requestDate) as [day],
	DATEPART(hour, requestDate) as [hour],
	DATEPART(minute, requestDate) as [minutes],
	chatId
	from ccRIAChats
	left join ccInbound b on (inboundId = inbound_id)
	left join ccRIAChatStatus c on (chatstatus = id)
	left join ccTipoCalif d on (calif_id = disposition)
	left join ccTipoCalifSub e on (califSub_id = subDisposition)
	left join ccUserView f on (User_id = userid)
	where requestDate >= @from and requestDate < @to
end'
	EXEC(@Sql)


	set @process = 'DEV3-466 DROP PROCEDURE ccspRepChatsEffectiveness'
	set @Sql= 'if exists (select * from sys.procedures where name = N''ccspRepChatsEffectiveness'')
    begin
       DROP PROCEDURE ccspRepChatsEffectiveness;
    end'
	EXEC(@Sql)	

	set @process = 'DEV3-466 CREATE PROCEDURE ccspRepChatsEffectiveness'
	set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepChatsEffectiveness]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete from RepChatsEffectiveness with(rowlock)
	where date >= @from AND date < @to

	insert into RepChatsEffectiveness
	select 
		[date], inboundId, descripcion [inbound]
		, ntotalChat, nanswer [nanswerChat], nabnd [nabnd]
		, case when nAnswer = 0 then 0 else convert(decimal(10,2),convert(decimal(10,0),nAnswerTime)/convert(decimal(10,0),nAnswer)) end [avgAnswerTime]	
		, case when nAnswer = 0 then 0 else convert(decimal(10,2),convert(decimal(10,0),tSumQueue)/convert(decimal(10,0),nAnswer)) end [avgQueueTime]	
		, case when nabnd = 0 then 0 else convert(decimal(10,2),convert(decimal(10,0),tSumAbandon)/convert(decimal(10,0),nabnd)) end [avgAbandonTime]
		, YEAR(date) [year], MONTH(date) [month]
		, DAY(date) [day], datepart(HOUR,date) [hh], datepart(MINUTE,date) [minutes]
	FROM (SELECT
		CONVERT(smalldatetime,CONVERT(varchar(13), requestDate,121)+ '':00'',121) [date],
		inboundId, 
		d.descripcion, 
		count(*) [ntotalChat]
		,sum(case when chatStatus = 4 then 1 else 0 end) [nAnswer]
		,sum(case when chatStatus = 4 then
			case when firstMessageTime is null then 0
			else ISNULL(datediff(ss,chatdate,firstMessageTime),0) end 
			else 0 end) [nAnswerTime]
		,sum(case when chatStatus = 4 then tQueue else 0 end) [tSumQueue]
		,sum(case when chatStatus = 9 then 1 else 0 end) [nabnd]
		,sum(case when chatStatus = 9 then tQueue else 0 end) [tSumAbandon]
		FROM ccRIaChats a INNER JOIN ccinbound d on (a.inboundId = d.inbound_id)
		where requestDate >= @from AND requestDate < @to
		group by CONVERT(smalldatetime,CONVERT(varchar(13),a.requestDate,121)+ '':00'',121), inboundId, d.descripcion		
	) x
	
end'
	EXEC(@Sql)


	set @process = 'DEV3-466 UPDATE ReportsTotals'
	set @Sql= 'update ReportsTotals set totalColumns =''sum:ntotalChat|sum:nanswerChat|sum:nabndChat|avg:avgAnswerTime|avg:avgQueueTime|avg:avgAbandonTimeChat'' where id = 3135'
	EXEC(@Sql)	


	set @process = 'DEV3-467 DROP PROCEDURE ccspRepChatsAndCallsGeneral'
	set @Sql= 'if exists (select * from sys.procedures where name = N''ccspRepChatsAndCallsGeneral'')
    begin
       DROP PROCEDURE ccspRepChatsAndCallsGeneral;
    end'
	EXEC(@Sql)	

	set @process = 'DEV3-467 CREATE PROCEDURE ccspRepChatsAndCallsGeneral'
	set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepChatsAndCallsGeneral]
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

DECLARE @HourExtend AS smallint, @fromExtended AS smalldatetime
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
	FROM
	(
		SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
		,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
		,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
		,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
		,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
		,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
		,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
		,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		FROM
		(
			SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,dni_id,[user_id]
			,COUNT(cal_id)AS ntotal
			,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
			,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour 
			,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
			,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer is null))THEN 1 ELSE NULL END)AS abnd
			,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent
			,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que 
			,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout
			,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow
			,COUNT(CASE WHEN((statuscall_id in(11,13,15,16))OR(statuscall_id=6 AND cal_xfer is not null))THEN 1 ELSE NULL END)AS xfer
			,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,13,15,16)OR(statuscall_id=6 AND cal_xfer is not null)))THEN cal_xfer ELSE NULL END)AS xfer_que
			,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer is not null))THEN 1 ELSE NULL END)AS abnd_xfer
			,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
			,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer
			,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
			,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
			,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost
			,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg
			,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer is null) AND (cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres
			,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
			,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
			,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
			,ISNULL(SUM(CASE WHEN((statuscall_id=13) AND (cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE 0 END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
			,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
			FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
			WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
			GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,dni_id,[user_id]
		)xDetailCount
		right JOIN
		(
			SELECT timegroup,inbound_id,dni_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
			,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
			FROM
			(
				SELECT timegroup,inbound_id,dni_id,[user_id]
				,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
				,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
				,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
				,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
				,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
				FROM
				(
					SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
					,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
					,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
					,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
					,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
					,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
					,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
					,*
					FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
				)xDetail
				UNION
				SELECT timegroup_next,inbound_id,dni_id,[user_id]
				,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
				,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
				,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
				,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
				,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
				FROM
				(
					SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
					,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
					,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
					,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
					,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
					,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
					,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
					,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) 
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
				)xDetail
			)xTimeDetail
			GROUP BY timegroup,inbound_id,dni_id,[user_id]
		)xDetailTime
		ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id = xDetailCount.dni_id AND xDetailTime.[user_id]=xDetailCount.[user_id])
	)xComplete
	WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
	AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
	AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
	AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)


	SELECT CONVERT(varchar(20), timegroup, 120) as [date], ccInbound.inbound_id as inboundId, descripcion as inbound, 
	ntotal, nabnd_que, tque_max, nnoanswer, nanswer, SL, avgTQueue
	into #partialCalls
	FROM 
	(	
		SELECT xDetCall.tg as timegroup , xDetCall.inbound_id  as inbound_id,
		ISNULL(ntotal, 0) ntotal, ISNULL(nabnd_que, 0) nabnd_que , ISNULL(tque_max, 0) tque_max , 
		ISNULL(tque, 0) tque, ISNULL(nanswer, 0) nanswer , ISNULL(tque/ NULLIF(nque, 0), 0) avgTQueue, 
		convert(decimal(10,2),ISNULL(SL_P_1 * 100 / NULLIF(ntotal,0), 0)) SL, ninitial + [nout_hour] + nabnd_xfer + nabnd_ring + nabnd_dialog + nno_agent + ntimeout + noverflow + nno_answer + nlost as nnoanswer,
		SL_P_1, SL_P_2
		FROM 
		(
			SELECT timegroup as tg, inbound_id, SUM(ntotal) ntotal , SUM(nabnd) nabnd_que , 
			MAX(tque_max) tque_max, NULLIF(SUM(nque), 0) nque,
			SUM(tque) tque, SUM(nanswer) nanswer, SUM(nanswer) AS SL_P_1 , 
			SUM(ninitial + [nout_hour] +  nabnd_xfer + nabnd_ring + nabnd_dialog + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, 
			SUM(nabnd) nabnd, SUM(nno_agent) nno_agent, SUM(ntimeout) ntimeout, SUM(noverflow) noverflow, 
			SUM(nno_answer) nno_answer, SUM(nlost) nlost, sum([nout_hour]) [nout_hour], sum(nabnd_xfer) nabnd_xfer,
			SUM(nabnd_ring) nabnd_ring, SUM(nabnd_dialog) nabnd_dialog, SUM(ninitial) ninitial
			FROM #callsin  
			WHERE timegroup >= @from 
			AND timegroup < @to
			GROUP BY  timegroup, inbound_id
		) xDetCall
	) xDetail  
	INNER JOIN ccInbound ON (xDetail.inbound_id = ccInbound.inbound_id) 
	where ccInbound.inbound_id is not null

	
	select [date], inboundId, descripcion, [totalChats], [waitingAbandoned], maxTQueue, notConnected, Connected, 
	convert(decimal(10,2),ISNULL(convert(float,[Connected_AbandonValid]) * 100 / NULLIF(convert(float,Total),0), 0)) as SL,
	avgTQueue
	into #partialChats
	from
	(
		select fecha as [date],
		inboundId, b.descripcion,
		max([totalChats]) as [totalChats],
		sum([waitingAbandoned]) as [waitingAbandoned],
		max(maxTQueue) as maxTQueue,
		sum([UnavailableAgents] + [OutOfService] + [OutOfSchedule] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow] + [Assigned] + [Connected<DT]) as [notConnected],
		sum([Connected]) as [Connected],
		max(avgTQueue) as avgTQueue,
		sum([Connected] + [AbandonValid]) as [Connected_AbandonValid], 
		sum([Connected] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow] + [UnavailableAgents] + [OutOfService] + [OutOfSchedule]) as Total
		from(
			select inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as fecha,
			count(*) as [totalChats],
			ISNULL(count(CASE WHEN(chatstatus = 4 and tChatting >= @DTChat) THEN 1 ELSE NULL END),0)AS [Connected],
			ISNULL(count(CASE WHEN(chatstatus = 4 and tChatting < @DTChat) THEN 1 ELSE NULL END),0)AS [Connected<DT],
			ISNULL(count(CASE WHEN(chatstatus = 2)THEN 1 ELSE NULL END),0)AS [UnavailableAgents],
			ISNULL(count(CASE WHEN(chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
			ISNULL(count(CASE WHEN(chatstatus = 5)THEN 1 ELSE NULL END),0)AS [OutOfService],
			ISNULL(count(CASE WHEN(chatstatus = 6)THEN 1 ELSE NULL END),0)AS [OutOfSchedule],
			ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
			ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
			ISNULL(count(CASE WHEN(chatstatus = 9 and tQueue>=@tresDialog) THEN 1 ELSE NULL END),0)AS [waitingAbandoned],
			ISNULL(count(CASE WHEN(chatstatus = 9 and tQueue<@tresDialog)THEN 1 ELSE NULL END),0)AS [AbandonValid],
			ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
			ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow],
			max(tqueue) as maxTQueue,
			avg(tqueue) as avgTQueue
			from ccRIAChats a
			where requestDate >= @from and requestDate < @to and
			chatStatus in (2,3,4,5,6,7,9,10,11)
			group by inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121)
		) as ChatDetail
		left join ccInbound b on (b.inbound_id = ChatDetail.inboundId)
		where fecha >= @from and fecha < @to
		group by inboundId, fecha, b.descripcion
	) as ChatSummary 
	

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
	YEAR(convert(datetime,isnull(a.date, b.date))) as [year],
	MONTH(convert(datetime,isnull(a.date, b.date))) as [month],
	DAY(convert(datetime,isnull(a.date, b.date))) as [day],
	datepart(HOUR, convert(datetime,isnull(a.date, b.date))) as [hour],
	datepart(MINUTE,convert(datetime,isnull(a.date, b.date))) as [minutes]
	from #partialCalls a
	full join #partialChats b on (a.date = b.date and a.inboundId = b.inboundId)

		
	drop table #partialChats
	drop table #partialCalls
	drop table #callsin
end'
	EXEC(@Sql)

-----------------------------------------------------Begin Jesus Gallardo hotfix/125.20230719.0.2-----------------------------------------------------------------
	set @process = 'DEV1-339 Delete DetailReports RepAgentGI-2010'
	set @sql = 'delete from DetailReports where id=2010 --Elimina el detalle del reporte RepAgentGI'
	EXEC(@sql)
	
	set @process = 'DEV1-339 drop table tmpccLogAgentesDia'
	set @sql = 'IF EXISTS (SELECT *	FROM sys.tables	WHERE name = ''tmpccLogAgentesDia'')
BEGIN
	drop table tmpccLogAgentesDia
END'
	EXEC(@sql)

	set @process = 'DEV1-339 drop table tmpTimesInboundData'
	set @sql = 'IF EXISTS (SELECT *	FROM sys.tables	WHERE name = ''tmpTimesInboundData'')
BEGIN
	drop table tmpTimesInboundData
END'
	EXEC(@sql)

	set @process = 'DEV1-339 drop table tmpTimesOutboundData'
	set @sql = 'IF EXISTS (SELECT *	FROM sys.tables	WHERE name = ''tmpTimesOutboundData'')
BEGIN
	drop table tmpTimesOutboundData
END'
	EXEC(@sql)

	set @process = 'DEV1-339 Rename Table -> RepAgentSummary RepAgentSummary_VersionAmatech'
	set @sql = 'if not exists(select * from sys.tables where name=''RepAgentSummary_VersionAmatech'') begin
	EXEC sp_rename ''RepAgentSummary'', ''RepAgentSummary_VersionAmatech'';
	--drop table [RepAgentSummary]
	CREATE TABLE [dbo].[RepAgentSummary](
	[date] [datetime] NOT NULL,
	[login] [varchar](40) NULL,
	[user] [varchar](255) NULL,	
	[sessionTime] [int] NULL,
	[loginMktTime] [datetime] NOT NULL,
	[logoutMktTime] [datetime] NOT NULL,
	[callTengaged] [int] NOT NULL,
	[ndTime] [int] NOT NULL,
	[NCallsOut] [int] NOT NULL,
	[NCallsIn] [int] NOT NULL,
	[NCallsCorta] [int] NOT NULL,
	[NAtend] [int] NOT NULL,
	[NNoCalif] [int] NOT NULL,
	[Available] [int] NOT NULL,
	[avgCallTengaged] [int] NOT NULL,	
	[twrapup] [int] NULL,
	[userId] [smallint] NULL,
	[TypeNotReady] int not null,
	[descripcion] varchar(255) not null,
	[descripcion_time] varchar(255) not null,
	[time] int not null,
	[transferStatus] [int] not NULL, --xferTime
	[ringingTime] [int] not NULL, --ringingTime
	[unknownStatus] [int] not NULL,	
	[otherStatus] [int] not NULL,
	[failureStatus] [int] not NULL,
	[chatTengaged] [int] not NULL,
	[undefinedTime][int] not NULL,
	[dialingStatus]  [int] not NULL
)
end
else begin	
	if not exists (select * from sys.columns where name = N''transferStatus'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		ALTER TABLE RepAgentSummary ADD [transferStatus] [int] NULL;        
    end	
	if not exists (select * from sys.columns where name = N''ringingTime'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		ALTER TABLE RepAgentSummary ADD [ringingTime] [int] NULL;        
    end
	
	if not exists (select * from sys.columns where name = N''unknownStatus'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		ALTER TABLE RepAgentSummary ADD [unknownStatus] [int] NULL;        
    end
	
	if not exists (select * from sys.columns where name = N''otherStatus'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		ALTER TABLE RepAgentSummary ADD [otherStatus] [int] NULL;        
    end
	
	if not exists (select * from sys.columns where name = N''failureStatus'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		ALTER TABLE RepAgentSummary ADD [failureStatus] [int] NULL;        
    end
	
	if not exists (select * from sys.columns where name = N''chatTengaged'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		ALTER TABLE RepAgentSummary ADD [chatTengaged] [int] NULL;        
    end
	
	if not exists (select * from sys.columns where name = N''undefinedTime'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		ALTER TABLE RepAgentSummary ADD [undefinedTime] [int] NULL;        
    end
	
	if not exists (select * from sys.columns where name = N''dialingStatus'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		ALTER TABLE RepAgentSummary ADD [dialingStatus] [int] NULL;        
    end	
end
'
	EXEC(@sql)

	set @process = 'DEV1-339 Rename columns RepAgentSummary.dialogTime-> callTengaged'
	set @sql = 'if exists (select * from sys.columns where name = N''dialogTime'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		EXEC sp_rename ''RepAgentSummary.dialogTime'', ''callTengaged'', ''COLUMN'';       
    end	
	'
	EXEC(@sql)

	set @process = 'DEV1-339 Rename columns RepAgentSummary.PromDialog-> avgCallTengaged'
	set @sql = 'if exists (select * from sys.columns where name = N''PromDialog'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		EXEC sp_rename ''RepAgentSummary.PromDialog'', ''avgCallTengaged'', ''COLUMN'';       
    end	
	'
	EXEC(@sql)

	set @process = 'DEV1-339 Rename columns RepAgentSummary.xferTime-> transferStatus'
	set @sql = 'if exists (select * from sys.columns where name = N''xferTime'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		EXEC sp_rename ''RepAgentSummary.xferTime'', ''transferStatus'', ''COLUMN'';
	end
	'
	EXEC(@sql)

	set @process = 'DEV1-339 Rename columns RepAgentSummary.ringingTime-> ringingTime'
	set @sql = 'if exists (select * from sys.columns where name = N''ringingTime'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		EXEC sp_rename ''RepAgentSummary.ringingTime'', ''ringingTime'', ''COLUMN'';
	end
	'
	EXEC(@sql)

	set @process = 'DEV1-339 Rename columns RepAgentSummary.tunknown-> unknownStatus'
	set @sql = 'if exists (select * from sys.columns where name = N''tunknown'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		EXEC sp_rename ''RepAgentSummary.tunknown'', ''unknownStatus'', ''COLUMN'';
	end	
	'
	EXEC(@sql)

	set @process = 'DEV1-339 Rename columns RepAgentSummary.tother-> otherStatus'
	set @sql = 'if exists (select * from sys.columns where name = N''tother'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		EXEC sp_rename ''RepAgentSummary.tother'', ''otherStatus'', ''COLUMN'';
	end	
	'
	EXEC(@sql)

	set @process = 'DEV1-339 Rename columns RepAgentSummary.tprob-> failureStatus'
	set @sql = 'if exists (select * from sys.columns where name = N''tprob'' and Object_ID = Object_ID(N''RepAgentSummary''))    
	begin
		EXEC sp_rename ''RepAgentSummary.tprob'', ''failureStatus'', ''COLUMN'';
	end	
	'
	EXEC(@sql)

	set @process = 'DEV1-339 Rename columns RepAgentSummary.tChatting-> chatTengaged'
	set @sql = 'if exists (select * from sys.columns where name = N''tChatting'' and Object_ID = Object_ID(N''RepAgentSummary''))
   begin
		EXEC sp_rename ''RepAgentSummary.tChatting'', ''chatTengaged'', ''COLUMN'';
	end
	'
	EXEC(@sql)

	set @process = 'DEV1-339 Rename columns RepAgentSummary.tundefined-> unknownStatus'
	set @sql = 'if exists (select * from sys.columns where name = N''tundefined'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		EXEC sp_rename ''RepAgentSummary.tundefined'', ''unknownStatus'', ''COLUMN'';
	end
	'
	EXEC(@sql)

	set @process = 'DEV1-339 Rename columns RepAgentSummary.tManual-> dialingStatus'
	set @sql = 'if exists (select * from sys.columns where name = N''tManual'' and Object_ID = Object_ID(N''RepAgentSummary''))
    begin
		EXEC sp_rename ''RepAgentSummary.tManual'', ''dialingStatus'', ''COLUMN'';
	end
	'
	EXEC(@sql)

	set @process = 'DEV1-339 update RepAgentSummary'
	set @sql = 'update RepAgentSummary set [transferStatus]=0,[ringingTime]=0,[unknownStatus]=0,[otherStatus]=0
,[failureStatus]=0,[chatTengaged]=0,[dialingStatus]=0 
where [dialingStatus] is null'
	EXEC(@sql)

	set @process = 'DEV1-339 Rename Table -> RepAgentGI RepAgentGI_VersionOld'
	set @sql = 'if not exists(select * from sys.tables where name=''RepAgentGI_VersionOld'') begin
	EXEC sp_rename ''RepAgentGI'', ''RepAgentGI_VersionOld'';
	--drop table RepAgentGI
	CREATE TABLE [dbo].[RepAgentGI](
	[date] [datetime] NOT NULL,
	[userId] [int] NOT NULL,
	[user] [varchar](255) NOT NULL,
	[login] [varchar](40) NOT NULL,
	
	[tlog] [int] NOT NULL,
	[tunknown] [int] NOT NULL,
	[tav] [int] NOT NULL,
	[tnotav] [int] NOT NULL,
	[tother] [int] NOT NULL,
	[tprob] [int] NOT NULL,
	[tChatting] [int] NULL,
	[tundefined] [int] NULL,

	[nxferin] [int] NOT NULL,
	[nanswerin] [int] NOT NULL,
	[nabndxferin] [int] NOT NULL,
	[nabndringin] [int] NOT NULL,
	[nabnddlgin] [int] NOT NULL,
	[abndaxferin] [int] NOT NULL,
	[nnoanswerin] [int] NOT NULL,
	[nlostin] [int] NOT NULL,
	[tdialogin] [int] NOT NULL,
	[tnotesin] [int] NOT NULL,
	[tringin] [int] NOT NULL,
	[txferin] [int] NOT NULL,
	[nxferout] [int] NOT NULL,
	[nanswerout] [int] NOT NULL,
	[nabndxferout] [int] NOT NULL,
	[nabndringout] [int] NOT NULL,
	[nabnddlgout] [int] NOT NULL,
	[abndaxferout] [int] NOT NULL,
	[nnoanswerout] [int] NOT NULL,
	[nlostout] [int] NOT NULL,
	[tdialogout] [int] NOT NULL,
	[tnotesout] [int] NOT NULL,
	[tringout] [int] NOT NULL,
	[txferout] [int] NOT NULL,
	[nother] [int] NOT NULL,		
	[nmohin] [int] NOT NULL,
	[nmohout] [int] NOT NULL,
	[nwhagin] [int] NOT NULL,
	[nwhagout] [int] NOT NULL,
	[nwhcliin] [int] NOT NULL,
	[nwhcliout] [int] NOT NULL,		
	
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL,
	[tManual] [int] not NULL
)
end
else begin
	if not exists (select * from sys.columns where name = N''tManual'' and Object_ID = Object_ID(N''RepAgentGI''))
    begin
		ALTER TABLE RepAgentGI ADD [tManual] [int] NULL;        
    end	
end
'
	EXEC(@sql)

	set @process = 'DEV1-339 Rename Table -> RepAgentGI RepAgentGI_VersionOld'
	set @sql = 'update RepAgentGI set [tManual]=0 where [tManual] is null'
	EXEC(@sql)

	set @process = 'DEV1-339 DEV1-339 sp_rename INDEX IX_RepAgentGI -> IX_RepAgentGI_VersionOld'
	set @sql = 'if  exists (select * from sys.indexes where name = N''IX_RepAgentGI'' and object_id = OBJECT_ID(N''RepAgentGI_VersionOld''))
begin
    EXEC sp_rename N''RepAgentGI_VersionOld.IX_RepAgentGI'', N''IX_RepAgentGI_VersionOld'', N''INDEX''; 
end
'
	EXEC(@sql)

	set @process = 'DEV1-339 DEV1-339 CREATE INDEX IX_RepAgentSummary columns date,userId'
	set @sql = 'if not exists (select * from sys.indexes where name = N''IX_RepAgentSummary'' and object_id = OBJECT_ID(N''RepAgentSummary''))
begin
    CREATE NONCLUSTERED INDEX [IX_RepAgentSummary] ON [dbo].[RepAgentSummary]([date] ASC)
end
'
	EXEC(@sql)	

	set @process = 'DEV1-339 DEV1-339 CREATE INDEX IX_RepAgentGI columns date,userId '
	set @sql = 'if not exists (select * from sys.indexes where name = N''IX_RepAgentGI'' and object_id = OBJECT_ID(N''RepAgentGI''))
begin
    CREATE NONCLUSTERED INDEX [IX_RepAgentGI] ON [dbo].[RepAgentGI]
	(
	[date] ASC,userId
	)
end'
	EXEC(@sql)


	set @process = 'DEV1-339 DEV1-339 DROP AND CREATE INDEX IX_RepAgentKPI columns date,userId'
	set @sql = 'if exists (
select i.[name] as index_name    
from sys.objects t
inner join sys.indexes i on t.object_id = i.object_id
cross apply (
	select col.[name] + '', '' from sys.index_columns ic
	inner join sys.columns col on ic.object_id = col.object_id and ic.column_id = col.column_id
	where ic.object_id = t.object_id and ic.index_id = i.index_id
	order by key_ordinal for xml path ('''') 
	) D (column_names)
where t.is_ms_shipped <> 1
and index_id > 0
and t.[name] = ''RepAgentKPI'' and substring(column_names, 1, len(column_names)-1)=''date''
) begin
	DROP INDEX IX_RepAgentKPI ON RepAgentKPI 

    CREATE NONCLUSTERED INDEX [IX_RepAgentKPI] ON [dbo].[RepAgentKPI] ([date] ASC,userId)
end'
	EXEC(@sql)


	set @process = 'DEV1-339 DEV1-339 DROP AND CREATE INDEX IX_RepAgentNotReady columns date,userId'
	set @sql = 'if exists (
select i.[name] as index_name    
from sys.objects t
inner join sys.indexes i on t.object_id = i.object_id
cross apply (
	select col.[name] + '', '' from sys.index_columns ic
	inner join sys.columns col on ic.object_id = col.object_id and ic.column_id = col.column_id
	where ic.object_id = t.object_id and ic.index_id = i.index_id
	order by key_ordinal for xml path ('''') 
	) D (column_names)
where t.is_ms_shipped <> 1
and index_id > 0
and t.[name] = ''RepAgentNotReady'' and substring(column_names, 1, len(column_names)-1)=''date''
) begin
	DROP INDEX IX_RepAgentNotReady ON RepAgentNotReady 

    CREATE NONCLUSTERED INDEX [IX_RepAgentNotReady] ON [dbo].[RepAgentNotReady] ([date] ASC,userId)
end'
	EXEC(@sql)

	set @process = 'DEV1-339 DEV1-339 DROP AND CREATE INDEX IX_RepAgentSession columns date,userId'
	set @sql = 'if exists (
select i.[name] as index_name    
from sys.objects t
inner join sys.indexes i on t.object_id = i.object_id
cross apply (
	select col.[name] + '', '' from sys.index_columns ic
	inner join sys.columns col on ic.object_id = col.object_id and ic.column_id = col.column_id
	where ic.object_id = t.object_id and ic.index_id = i.index_id
	order by key_ordinal for xml path ('''') 
	) D (column_names)
where t.is_ms_shipped <> 1
and index_id > 0
and t.[name] = ''RepAgentSession'' and substring(column_names, 1, len(column_names)-1)=''date''
) begin
	DROP INDEX IX_RepAgentSession ON RepAgentSession 

    CREATE NONCLUSTERED INDEX [IX_RepAgentSession] ON [dbo].[RepAgentSession] ([date] ASC,userId)
end'
	EXEC(@sql)


	set @process = 'DEV1-339 DEV1-339 DROP AND CREATE INDEX  IX_RepAgentSessionByInterval columns date,userId '
	set @sql = 'if exists (
select i.[name] as index_name    
from sys.objects t
inner join sys.indexes i on t.object_id = i.object_id
cross apply (
	select col.[name] + '', '' from sys.index_columns ic
	inner join sys.columns col on ic.object_id = col.object_id and ic.column_id = col.column_id
	where ic.object_id = t.object_id and ic.index_id = i.index_id
	order by key_ordinal for xml path ('''') 
	) D (column_names)
where t.is_ms_shipped <> 1
and index_id > 0
and t.[name] = ''RepAgentSessionByInterval'' and substring(column_names, 1, len(column_names)-1)=''date''
) begin
	DROP INDEX IX_RepAgentSessionByInterval ON RepAgentSessionByInterval 

    CREATE NONCLUSTERED INDEX [IX_RepAgentSessionByInterval] ON [dbo].[RepAgentSessionByInterval] ([date] ASC,userId)
end'
	EXEC(@sql)

	set @process = 'DEV1-339 DROP AND CREATE INDEX  IX_RepAgentNotReadyDet columns date,userId'
	set @sql = 'if exists (
select i.[name] as index_name    
from sys.objects t
inner join sys.indexes i on t.object_id = i.object_id
cross apply (
	select col.[name] + '', '' from sys.index_columns ic
	inner join sys.columns col on ic.object_id = col.object_id and ic.column_id = col.column_id
	where ic.object_id = t.object_id and ic.index_id = i.index_id
	order by key_ordinal for xml path ('''') 
	) D (column_names)
where t.is_ms_shipped <> 1
and index_id > 0
and t.[name] = ''RepAgentNotReadyDet'' and substring(column_names, 1, len(column_names)-1)=''date''
) begin
	DROP INDEX IX_RepAgentNotReadyDet ON RepAgentNotReadyDet 

    CREATE NONCLUSTERED INDEX [IX_RepAgentNotReadyDet] ON [dbo].[RepAgentNotReadyDet] ([date] ASC,userId)
end'
	EXEC(@sql)	


	set @process = 'DEV1-339 Add pivotReports ReportAgentSummary'
	set @sql = 'if not exists(select * from pivotReports where id=2100) begin
	insert into pivotReports values(2100,''descripcion_time'',''date|login|user|loginMktTime|logoutMktTime|sessionTime|unknownStatus|otherStatus|Available|ndTime|transferStatus|ringingTime|callTengaged|twrapup|failureStatus|chatTengaged|dialingStatus|undefinedTime|NCallsOut|NCallsIn|NCallsCorta|NAtend|NNoCalif|avgCallTengaged'',''max'',1)
end
else begin
	update pivotReports set columns=''descripcion_time'',complementColumns=''date|login|user|loginMktTime|logoutMktTime|sessionTime|unknownStatus|otherStatus|Available|ndTime|transferStatus|ringingTime|callTengaged|twrapup|failureStatus|chatTengaged|dialingStatus|undefinedTime|NCallsOut|NCallsIn|NCallsCorta|NAtend|NNoCalif|avgCallTengaged''
	where id=2100
end
update ReportsTotals set totalColumns=''sum:sessionTime,sum:dialogTime,sum:unknownStatus,sum:NCallsOut,sum:otherStatus,sum:Available,sum:ndTime,sum:transferStatus,sum:ringingTime,sum:callTengaged,sum:twrapup,sum:failureStatus,sum:chatTengaged,sum:dialingStatus,sum:undefinedTime,sum:NCallsOut,sum:NCallsIn,sum:NCallsCorta,sum:NAtend,sum:NNoCalif,avg:avgCallTengaged'' where id=2100
'
	EXEC(@sql)

	set @process = 'DEV1-339 Se oculta la columna completeByHour por que no es relevante'
	set @sql = 'if exists (select * from sys.columns where name = N''completeByHour'' and Object_ID = Object_ID(N''RepDetailAgent''))
begin
    EXEC sp_rename ''RepDetailAgent.completeByHour'', ''completeByHourHideAndRename'', ''COLUMN'';
end'
	EXEC(@sql)

	set @process = 'DEV1-339 Alter Sp ReportsMasterProcessWIthOnlyGenerate'
	set @sql = 'ALTER PROCEDURE [dbo].[ReportsMasterProcessWIthOnlyGenerate] @from AS DATETIME = NULL
	,@to AS DATETIME = NULL
	,@scheduleTime INT = 10
	,@dateStart DATETIME = NULL
AS
SET ANSI_WARNINGS OFF
SET NOCOUNT ON

DECLARE @i INT,@count INT
DECLARE @SQL nVARCHAR(4000)
DECLARE @name SYSNAME
DECLARE @descError NVARCHAR(max)
DECLARE @dateSP DATETIME

IF @from IS NULL
BEGIN
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))
END

IF @to IS NULL
BEGIN
	SET @to = getdate()
END

IF @dateStart IS NULL
BEGIN
	SET @dateStart = getdate()
END

EXEC ccspTmpTimesInterval @from = @from	,@to = @to	,@interval = 15 --Tabla TmpTimesInterval Temporal para tener Intervalos de 15 Minutos
EXEC ccspTmpSessionGeneral @from = @from	,@to = @to				--Tabla tmpSessionGeneral para tener la sesiones de agentes
EXEC ccspTmpSessionTimeGroup @from = @from	,@to = @to				--Tabla tmpSessionTimeGroup para dividir la sesion en intervalos de 15 Minutos
EXEC ccspTimesccLogAgentesDia @from = @from	,@to = @to				--Tabla tmpccLogAgentesDia tener los movimientos de los agentes
EXEC ccspTimesOutboundData @from = @from	,@to = @to				--Tabla tmpTimesOutboundData para los tiempos de las llamadas de salida
EXEC ccspTimesInboundData @from = @from	,@to = @to					--Tabla tmpTimesInboundData para los tiempos de las llamadas de entrada
exec ccspTmpTimesccLogtransfers @from = @from, @to = @to			--Tabla TmpTimesccLogtransfers para los tiempos de las llamadas que son trasferidas
exec ccsptmpTimesHoldIn @from = @from, @to = @to					--Tabla tmpTimesHoldIn para los tiempos cuando se pone en hold en llamadas de entrada

CREATE TABLE #tmpProcedureReports (
	id INT
	,name SYSNAME
	)

declare @tableSpDontProcess table(nameSp varchar(300) primary key not null)

insert into @tableSpDontProcess values(''ccspRepCatalogos'') -- ccspRepCatalogos es para catalogos por eso no se debe correr
insert into @tableSpDontProcess values(''ccsprepLogAgentriaseparate'') -- ccsprepLogAgentriaseparate Separa en intervalos de 15 Minutos ccloAgentDia 
insert into @tableSpDontProcess values(''ccspRepAgentSession'') -- ccspRepAgentSession Genera el reporte de sesiones para alimentar  
-- insert into @tableSpDontProcess values(''ccspRepTrunkBusy'') -- ccspRepTrunkBusy Es necesario revisar si se ocupan estos reportes y encaso de procesar mucha informacion crear un job para que se ejecute cada 2 horas o algo por el estilo
insert into @tableSpDontProcess values(''ccspRepAgentNotReadyDet'') -- ccspRepAgentNotReadyDet sabemos cuando inicia y cuando termina los no disponibles 
insert into @tableSpDontProcess values(''ccspRepAgentNotReady'') -- ccspRepAgentNotReady Agrupa por hora
insert into @tableSpDontProcess values(''ccspRepAgentGI'') 		-- ccspRepAgentGI Agrupa por hora

INSERT INTO #tmpProcedureReports
SELECT ROW_NUMBER() OVER (
		ORDER BY [name]
		) AS id
	,[name]
FROM sys.procedures
WHERE [name] LIKE ''ccspRep%''
	AND [name] NOT IN (select nameSp from @tableSpDontProcess)
	AND name NOT IN (
		SELECT name
		FROM logsReportsMaster
		WHERE STATUS = 0
			AND dateStart >= @dateStart
		)

--1 Se saca este reporte primero para reutilizarlo en otros reportes que lo necesiten
exec ccspRepAgentSession @action=1,@from=@from,@to=@to --Saca el detalle de las sesiones
exec ccspRepAgentNotReadyDet @action=1,@from=@from,@to=@to --Saca el detalle de los no disponibles
exec ccspRepAgentNotReady @action=1,@from=@from,@to=@to --Agrupa a los no disponibles por hora
exec ccspRepAgentGI @action=1,@from=@from,@to=@to 	--Agrupa por 15 minutos

INSERT INTO [logsReportsMaster] (
	name
	,STATUS
	,dateStart
	,dateEnd
	,error
	,maxTime
	)
SELECT name
	,0
	,''19000101''
	,''19000101''
	,''''
	,@scheduleTime
FROM #tmpProcedureReports

SELECT @i = 1, @count = count(*) FROM #tmpProcedureReports

WHILE @i <= @count
	AND datediff(mi, @dateStart, getdate()) < @scheduleTime
BEGIN
	SELECT @name = name
	FROM #tmpProcedureReports
	WHERE id = @i

	SET @sql = ''EXEC '' + @name + '' @action=1, @from=@from, @to=@to''
	
	SET @dateSP = getdate()

	BEGIN TRY
		--print @sql
		
		exec sp_executesql @sql, N''@from DATETIME, @to DATETIME'',@from, @to  				

		IF (datediff(ss, @dateStart, getdate()) > @scheduleTime * 60)
		BEGIN
			UPDATE [logsReportsMaster]
			SET STATUS = 2
				,dateStart = @dateSP
				,dateEnd = getdate()
				,maxTime = @scheduleTime + 1
				,error = ''Increment time shuduler '' + convert(VARCHAR(max), @scheduleTime)
			WHERE name = @name
				AND STATUS = 0
				AND dateStart = ''19000101''
				AND dateEnd = ''19000101''

			UPDATE [logsReportsMaster]
			SET dateStart = @dateSP
				,dateEnd = getdate()
				,maxTime = @scheduleTime
			WHERE STATUS = 0
				AND dateStart = ''19000101''
				AND dateEnd = ''19000101''

			BREAK
		END

		UPDATE [logsReportsMaster]
		SET STATUS = 1
			,dateStart = @dateSP
			,dateEnd = getdate()
		WHERE name = @name
			AND STATUS = 0
			AND dateStart = ''19000101''
			AND dateEnd = ''19000101''
			
	END TRY

	BEGIN CATCH
		SELECT @descError = ''Line: '' + cast(error_line() AS NVARCHAR) + '' Number: '' + cast(@@error AS NVARCHAR) + '' Message: '' + error_message()

		SELECT @descError,@name

		UPDATE [logsReportsMaster]
		SET STATUS = 3
			,dateStart = @dateSP
			,dateEnd = getdate()
			,error = @descError
		WHERE name = @name
			AND STATUS = 0
			AND dateStart = ''19000101''
			AND dateEnd = ''19000101''
	END CATCH

	SET @i = @i + 1
END

DROP TABLE #tmpProcedureReports'
	EXEC(@sql)

	set @process = 'DEV1-339 Alter Sp ccspGenSession se verifica los login y logout sean los mismos'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspGenSession]
@from AS SMALLDATETIME,
@to AS SMALLDATETIME
AS
SET NOCOUNT ON

DECLARE @date DATETIME

CREATE TABLE #tempccGenSession ([fila] INT NOT NULL, [user_id] [smallint] NOT NULL, [login] [datetime] NOT NULL, [logout] [datetime] NULL, [extension] [varchar](7) NOT NULL, PRIMARY KEY (fila, user_id))
CREATE TABLE #temUserIdLogoutNull ([user_id] [smallint] NOT NULL)
CREATE TABLE #temIdMaxLogoutNull ([fila] INT NOT NULL, [user_id] [smallint] NOT NULL, PRIMARY KEY (fila, user_id))


;with dataLoginLogout as(
select ROW_NUMBER() OVER (
PARTITION BY user_id ORDER BY FECHA, tipoMov
) Fila
,User_id,Extension,TipoMov,
case when TipoMov =1 then
dateadd(ms, - DATEPART(ms, fecha), fecha) 
else fecha  end 
fecha 
from ccLogLogin where fecha between @from and @to 
)

INSERT INTO #tempccGenSession
select A.Fila, A.User_id
,dateadd(ms, - DATEPART(ms, A.fecha), A.fecha) LOGIN,  S.fecha logout
, A.Extension
from dataLoginLogout A
left join dataLoginLogout S on A.Fila =S.Fila-1 and A.TipoMov=1 and S.TipoMov=0 AND A.User_id = S.User_id
where A.TipoMov=1
	

UPDATE x
SET x.fila = x.row
FROM (
	SELECT fila, ROW_NUMBER() OVER (
			PARTITION BY user_id ORDER BY LOGIN
			) row
	FROM #tempccGenSession
	) x

INSERT INTO #temUserIdLogoutNull
	SELECT user_id
	FROM #tempccGenSession
	WHERE logout IS NULL
	GROUP BY user_id

INSERT INTO #temIdMaxLogoutNull
	SELECT A.fila, A.user_id
	FROM #tempccGenSession A
	INNER JOIN (
		SELECT max(fila) fila, user_id
		FROM #tempccGenSession
		WHERE user_id IN (
				SELECT user_id
				FROM #temUserIdLogoutNull
				)
		GROUP BY user_id
		) B
		ON A.fila = B.fila
			AND A.user_id = B.user_id
	WHERE A.logout IS NULL



SET @date = GETDATE()

UPDATE A
	SET A.logout = CASE WHEN @to < @date THEN @to ELSE @date END
	FROM #tempccGenSession A
	INNER JOIN #temIdMaxLogoutNull B
		ON A.user_id = B.user_id
			AND A.fila = B.fila

	;with logoutAgentDia as(
	select A.fila,A.user_id,A.login, A.extension,
	(
	select max( fecha) from ccLogAgentesDia where fecha between A.login and B.login
	and User_id=A.user_id 
	) logout2
	FROM #tempccGenSession A
	LEFT JOIN #tempccGenSession B
		ON A.fila = B.fila - 1
			AND A.user_id = B.user_id
	WHERE A.logout IS NULL
	)

	update A set A.logout=B.logout2
	--select A.fila,A.user_id,A.login,B.logout2 as logout, A.extension 
	from #tempccGenSession A
	inner join logoutAgentDia B on A.fila=B.fila and A.user_id=B.user_id 
	where A.logout is null

DELETE
FROM #tempccGenSession
WHERE LOGIN = logout

DELETE A
FROM #tempccGenSession A
INNER JOIN (
	SELECT user_id, [login], logout
	FROM #tempccGenSession
	GROUP BY user_id, [login], logout
	HAVING count(*) > 1
	) B
	ON A.user_id = B.user_id
		AND A.LOGIN = B.LOGIN
		AND A.logout = B.logout

UPDATE a
WITH (ROWLOCK)

SET a.logout = b.logout
FROM #tempccGenSession b
INNER JOIN #tempccGenSession a
	ON a.user_id = b.user_id
		AND a.LOGIN = b.LOGIN
		AND a.logout <> b.logout;

	;WITH tmpccGenSession
	AS (
		SELECT user_id, [login], [logout], extension
		, dbo.GetTimeGroup([login], 0) AS timeGroup, dbo.GetTimeGroup([logout], 1) AS timeGroupNext
		FROM #tempccGenSession
		)
	SELECT A.*, datediff(ss, [login], [logout]) AS tlog
	FROM tmpccGenSession A

DROP TABLE #tempccGenSession
DROP TABLE #temUserIdLogoutNull
DROP TABLE #temIdMaxLogoutNull

SET NOCOUNT OFF'
	EXEC(@sql)

	set @process = 'DEV1-339 Alter Sp ccspTimesInboundData Se agrega para saber cuando inicio xfer y separar los tiempos correctamente'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspTimesInboundData]
@from AS SMALLDATETIME, @to AS SMALLDATETIME
AS

SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#inboundData2'', N''U'') IS NOT NULL
	DROP TABLE #inboundData2

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = ''tmpTimesInboundData''
		)
BEGIN
	CREATE TABLE tmpTimesInboundData (
		[row] INT, dateStartDetail DATETIME, dateEndDetail DATETIME, timegroup DATETIME, timegroup_next DATETIME, time_endque 
		DATETIME, dateXferAgtStart datetime, time_ring DATETIME, time_dialog DATETIME, time_notes DATETIME, time_end_call DATETIME, phone_in VARCHAR(40), 
		cal_id INT, dni_id INT, Inbound_id INT, [User_id] INT, ntotal INT, ninitial INT, nout_hour INT, nout_service INT, nabnd INT, 
		nno_agent INT, nque INT, ntimeout INT, noverflow INT, nxfer INT, nxfer_que INT, nabnd_xfer INT, nabnd_ring INT, nno_answer INT, 
		nabnd_dialog INT, nanswer INT, nlost INT, nmsg INT, nabnd_tres INT, nansw_tres INT, tque_max INT, tque INT, txfer INT, tdialog INT, 
		tnotes INT, tring INT, tresp INT, nMoh INT, nWHag INT, nWHcl INT, statusCall_id INT, [dateTResp] DATETIME, [dateTACD] DATETIME, 
		calif_id INT, cal_tMoh INT, cal_puerto INT
		);
END
ELSE
BEGIN
	TRUNCATE TABLE tmpTimesInboundData	
END

DECLARE @relastionCampWg TABLE (idwg INT, camId INT)

INSERT INTO @relastionCampWg
SELECT MAX(IDWG) AS IDWG, IdCampEsp AS Id
FROM ccRIACampEspWG
WHERE Tipo = 0
GROUP BY IdCampEsp

DECLARE @HourExtend AS SMALLINT

SELECT @HourExtend = 2

DECLARE @fromExtended AS SMALLDATETIME

SELECT @fromExtended = DATEADD(hh, - @HourExtend, @from)

DECLARE @tresRing AS SMALLINT
DECLARE @tresDialog AS SMALLINT
DECLARE @tresDelayIn AS SMALLINT

EXEC @tresRing = ccspConfigTresRing

EXEC @tresDialog = ccspConfigTresDialog

EXEC @tresDelayIn = ccspConfigtresDelayIn


DECLARE @dateNow DATETIME

SET @dateNow = GETDATE();

WITH inboundData
AS (
	SELECT ROW_NUMBER() OVER (ORDER BY cal_id ASC) AS rowId
	, CASE WHEN cal_Xfer IS NULL OR cal_Xfer = ''1900-01-01 00:00:00'' THEN cal_inicio ELSE cal_Xfer END AS dateStartDetail	
	,cal_id,Inbound_id,cal_tWait,cal_tXfer,cal_tRing,cal_tDialog,cal_tNotas	
	,cal_Ani, dni_id, User_id, statuscall_id, cal_que, cal_Xfer
	,cal_tMoh, cal_whoHung, calif_id, cal_puerto
	FROM ccCallsIn
	WHERE cal_inicio between @fromExtended AND @to AND INBOUND_ID > 0	
	)
	,callInStart as(
	select distinct userId,min(dateIni) dateIni,callId,camType
	from tmpccLogAgentesDia 
	where callId>0 and  camType=0 and TipoStatusAge_id in(5,9,4,6)
	group by userId,callId,camType
	) 
	,callDataStartXfer as(
	select A.userId,B.callId,B.camType,B.camId,min(B.dateIni) dateIni from callInStart A
	inner join tmpccLogAgentesDia B on A.userId=B.userId and A.dateIni=B.dateIni
	where B.tStatus>0
	group by A.userId,B.callId,B.camType,B.camId
	),inboundDataWithXferAgent  as(
	select rowId
	,cal_id,Inbound_id,cal_tWait,cal_tXfer,cal_tRing,cal_tDialog,cal_tNotas	
	,dateStartDetail	
	,DATEADD(ss, cal_tWait, A.dateStartDetail) as time_endque
	,ISNULL(B.dateIni,A.dateStartDetail) as dateXferAgtStart
	,DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, ISNULL(B.dateIni,A.dateStartDetail)) as dateEndDetail
	,cal_Ani, dni_id, User_id, statuscall_id, cal_que, cal_Xfer
	,cal_tMoh, cal_whoHung, calif_id, cal_puerto
	from inboundData A
	left join callDataStartXfer B on A.cal_id= B.callId and A.Inbound_id=B.camId and A.User_id=B.userId
	)	
	

	

	INSERT INTO tmpTimesInboundData
	select rowId, dateStartDetail,dateEndDetail
	, dbo.GetTimeGroup(dateStartDetail, 0) AS timegroup
	, dbo.GetTimeGroup(dateEndDetail, 1	) AS timegroup_next
	, time_endque, dateXferAgtStart
	, DATEADD(ss, cal_txfer, dateXferAgtStart) AS time_ring
	, DATEADD(ss, cal_txfer + cal_tring, dateXferAgtStart) AS time_dialog
	, DATEADD(ss, cal_txfer + cal_tring + cal_tdialog, dateXferAgtStart) AS time_notes	
	, dateEndDetail AS time_end_call
	, cal_Ani AS phone_in, cal_id, dni_id, Inbound_id, [User_id], 1 AS ntotal
	, CASE WHEN statuscall_id = 1 THEN 1 ELSE 0 END AS ninitial
	, CASE WHEN statuscall_id = 2 THEN 1 ELSE 0 END AS nout_hour
	, CASE WHEN statuscall_id = 3 THEN 1 ELSE 0 END AS nout_service
	, CASE WHEN statuscall_id IN (5, 6)	AND cal_que > 0	AND (cal_xfer IS NULL OR cal_xfer = ''1900-01-01 00:00:00'') THEN 1 ELSE 0 END AS nabnd
	, CASE WHEN statuscall_id = 4 THEN 1 ELSE 0 END AS nno_agent
	, CASE WHEN cal_que > 0 THEN 1 ELSE 0 END AS  nque
	, CASE WHEN statuscall_id = 7 THEN 1 ELSE 0 END AS ntimeout
	, CASE WHEN statuscall_id = 8 THEN 1 ELSE 0 END AS noverflow
	, CASE WHEN statuscall_id IN (11, 15, 13, 16)OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'' ) THEN 1 ELSE 0 END AS nxfer
	, CASE WHEN cal_que > 0	AND ( statuscall_id IN (11, 15, 13, 16) OR ( statuscall_id = 6	AND cal_xfer <> ''1900-01-01 00:00:00'') ) THEN 1 ELSE 0 END AS nxfer_que
	, CASE WHEN statuscall_id = 11 OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'') THEN 1 ELSE 0 END AS nabnd_xfer
	, CASE WHEN statuscall_id = 15 AND cal_tring <= @tresRing	 THEN 1 ELSE 0 END AS nabnd_ring
	, CASE WHEN statuscall_id = 15 AND cal_tring > @tresRing  THEN 1 ELSE 0 END AS nno_answer
	, CASE WHEN statuscall_id = 13 AND cal_tdialog <= @tresDialog  THEN 1 ELSE 0 END AS nabnd_dialog
	, CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog   THEN 1 ELSE 0 END AS nanswer
	, CASE WHEN statuscall_id = 16 THEN 1 ELSE 0 END AS nlost
	, CASE WHEN statuscall_id IN (9, 10, 12, 14)  THEN 1 ELSE 0 END AS nmsg
	, CASE WHEN ( (	statuscall_id IN (5, 6) AND cal_que > 0	AND (cal_xfer IS NULL OR cal_xfer = ''1900-01-01 00:00:00'')	)
					AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE 0 END AS nabnd_tres
	, CASE WHEN ((statuscall_id = 13 AND cal_tdialog > @tresDialog)	AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn) ) THEN 1 ELSE 0 END AS nansw_tres	
	, cal_twait AS tque_max, cal_twait AS tque, cal_txfer AS txfer, cal_tdialog AS tdialog
	, cal_tnotas AS tnotes, cal_tring AS tring
	, CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog THEN cal_twait + cal_txfer + cal_tring ELSE 0 END AS tresp
	, CASE WHEN cal_tMoh > 0 THEN 1 ELSE 0 END AS nMoh
	, CASE WHEN cal_whoHung > 0 THEN 1 ELSE 0 END AS nWHag
	, CASE WHEN cal_whoHung = 0 THEN 1 ELSE 0 END AS nWHcl
	, statusCall_id
	, dateadd(ss, cal_txfer + cal_tring, dateXferAgtStart) AS [dateTResp]
	, dateadd(ss, cal_txfer + cal_tring + cal_tdialog, dateXferAgtStart) AS [dateTACD]
	, calif_id, cal_tMoh, cal_puerto
	from inboundDataWithXferAgent

/******************* Revisa si los datos son del dia ******************************/

declare @today date
set @today =convert(date,@dateNow,121)

IF @today = CONVERT(DATE, @to, 121)
BEGIN
		;

	WITH lastAgentStatus
	AS (
		SELECT userId, max(dateIni) dateIn
		FROM tmpccLogAgentesDia
		WHERE dateIni BETWEEN @today AND @to
		GROUP BY userId
		), timeAcumlate
	AS (
		SELECT A.userId, A.camId, A.callId, sum(CASE WHEN A.currentStatus IN (4, 5, 9) THEN A.tStatus 
					ELSE 0 END) AS tdialog, sum(CASE WHEN A.currentStatus = 6 THEN A.tStatus ELSE 0 END) AS tnotes, max(A.dateEnd) AS 
			dateEnd, max(A.timeGroupNext) AS timeGroupNext
		FROM tmpccLogAgentesDia A
		INNER JOIN lastAgentStatus B ON A.userId = B.userId
			AND A.dateIni = B.dateIn
		WHERE A.dateIni BETWEEN @today AND @to
			AND currentStatus IN (4, 5, 6, 9)
			AND A.camType = 0
		GROUP BY A.userId, A.camId, A.callId
		)
	UPDATE A
	SET A.dateEndDetail = B.dateEnd, A.timegroup_next = B.timeGroupNext, A.tdialog = CASE WHEN B.tdialog > 0 THEN B.tdialog ELSE A.
				tdialog END, A.tnotes = CASE WHEN B.tnotes > 0 THEN B.tnotes ELSE A.tnotes END, A.time_notes = CASE WHEN B.tdialog > 0 THEN B.
					dateEnd ELSE A.time_dialog END, A.time_end_call = CASE WHEN B.tnotes > 0 THEN B.dateEnd ELSE A.time_notes END, A.
		User_id = CASE WHEN A.User_id > 0 THEN B.userId ELSE A.User_id END
	FROM tmpTimesInboundData A
	INNER JOIN timeAcumlate B ON A.Inbound_id = B.camId
		AND A.cal_id = B.callId
END

SELECT *
INTO #inboundData2
FROM tmpTimesInboundData
WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

DELETE tmpTimesInboundData
WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

INSERT INTO tmpTimesInboundData
SELECT [row], dateStartDetail, dateEndDetail, th.start AS timegroup, th.stop AS timegroup_next, time_endque
,dateXferAgtStart, time_ring, time_dialog, time_notes, time_end_call, phone_in, cal_id, dni_id, Inbound_id, [User_id] 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN ntotal ELSE 0 END AS ntotal 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN ninitial ELSE 0 END AS ninitial 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nout_hour ELSE 0 END AS nout_hour 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nout_service ELSE 0 END AS nout_service 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd ELSE 0 END AS nabnd 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nno_agent ELSE 0 END AS nno_agent 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nque ELSE 0 END AS nque 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN ntimeout ELSE 0 END AS ntimeout 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN noverflow ELSE 0 END AS noverflow 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nxfer ELSE 0 END AS nxfer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nxfer_que ELSE 0 END AS nxfer_que 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_xfer ELSE 0 END AS nabnd_xfer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_ring ELSE 0 END AS nabnd_ring 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nno_answer ELSE 0 END AS nno_answer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_dialog ELSE 0 END AS nabnd_dialog 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nanswer ELSE 0 END AS nanswer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nlost ELSE 0 END AS nlost 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nmsg ELSE 0 END AS nmsg 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_tres ELSE 0 END AS nabnd_tres 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nansw_tres ELSE 0 END AS nansw_tres 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN tque_max ELSE 0 END AS tque_max
, dbo.TimeInterval(th.start, th.stop, dateStartDetail, 	time_endque) AS tque
, dbo.TimeInterval(th.start, th.stop, dateXferAgtStart, time_ring) AS txfer
, dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog
, dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes
, dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring
, dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tresp, dateStartDetail)) AS tresp 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nMoh ELSE 0 END AS nMoh 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nWHag ELSE 0 END AS nWHag 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nWHcl ELSE 0 END AS nWHcl, statusCall_id, [dateTResp], [dateTACD] 
, CASE WHEN th.start >  dateStartDetail AND th.stop > dateEndDetail THEN calif_id ELSE - 2 END AS calif_id, dbo.AccountInterval(th.start, th.stop, dateStartDetail
		, dateEndDetail, cal_tMoh) AS cal_tMoh, cal_puerto
FROM #inboundData2 t
INNER JOIN TmpTimesInterval th ON (
		t.timegroup > th.Start
		AND t.timegroup < th.stop
		)
	OR th.Start BETWEEN t.timegroup AND t.timegroup_next
WHERE DATEDIFF(ss, th.start, timegroup_next) > 0
	AND th.Start BETWEEN @from AND @to
ORDER BY [row], th.start


IF OBJECT_ID(N''tempdb..#inboundData2'', N''U'') IS NOT NULL
	DROP TABLE #inboundData2
'
	EXEC(@sql)

	set @process = 'DEV1-339 Alter Sp ccspTimesOutboundData Se agrega para saber cuando inicio xfer y separar los tiempos correctamente'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspTimesOutboundData] 
@from AS SMALLDATETIME, @to AS SMALLDATETIME
AS
SET NOCOUNT ON


IF OBJECT_ID(N''tempdb..#outboundData2'', N''U'') IS NOT NULL
	DROP TABLE #outboundData2

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = ''tmpTimesOutboundData''
		)
BEGIN
	CREATE TABLE tmpTimesOutboundData (
		row INT identity, dateStartDetail DATETIME, dateEndDetail DATETIME, timegroup DATETIME, timegroup_next DATETIME, cam_id INT, 
		User_id INT, ntotal INT, nno_agent INT, nxfer INT, nabnd_xfer INT, nabnd_ring INT, nno_answer INT, nabnd_dialog INT, nanswer INT, 
		nlost INT, tque INT, txfer INT, tring INT, tdialog INT, tnotes INT, tresp INT, nhangup INT, nMoh INT, nWHag INT, nWHcl INT, 
		time_endque DATETIME,dateXferAgtStart datetime, time_ring DATETIME, time_dialog DATETIME, time_notes DATETIME, time_end_call DATETIME, phone_out 
		VARCHAR(30), cal_id INT, cal_puerto INT, idwg INT, statuscall_id INT, calif_id INT, cal_manual INT, cal_tMoh INT
		)
END
ELSE
BEGIN
	TRUNCATE TABLE tmpTimesOutboundData
END

DECLARE @relastionCampWg TABLE (idwg INT, camId INT)

INSERT INTO @relastionCampWg
SELECT max(IDWG) AS IDWG, IdCampEsp AS Id
FROM ccRIACampEspWG
WHERE Tipo = 1
GROUP BY IdCampEsp

DECLARE @HourExtend AS SMALLINT
DECLARE @fromExtended AS SMALLDATETIME
DECLARE @tresRing AS SMALLINT
DECLARE @tresDialog AS SMALLINT
DECLARE @tresDelayIn AS SMALLINT

SELECT @HourExtend = 2

SELECT @fromExtended = DATEADD(hh, - @HourExtend, @from)

EXEC @tresRing = ccspConfigTresRing

EXEC @tresDialog = ccspConfigTresDialog

EXEC @tresDelayIn = ccspConfigtresDelayIn

DECLARE @dateNow DATETIME

SET @dateNow = GETDATE();

WITH outboundData AS (
SELECT ROW_NUMBER() OVER (ORDER BY cal_id ASC) AS rowId
, cal_inicio AS dateStartDetail	
,cal_id,cam_id,cal_tWait,cal_tXfer,cal_tRing,cal_tDialog,cal_tNotas	
,cal_telefono, User_id, statuscall_id, cal_que
,cal_tMoh, cal_whoHung, calif_id, cal_puerto
FROM ccoCallsOut
WHERE cal_inicio between @fromExtended AND @to AND cam_id > 0	
)
,callOutStart as(
select userId,MIN(dateIni) dateIni,callId,camType,camId
from tmpccLogAgentesDia 
where callId>0 and camType=1 and TipoStatusAge_id in(5,9,4,6)
group by userId,callId,camType,camId
)
, callDataStartXfer as(
select A.userId,B.callId,B.camType,B.camId,min(B.dateIni) as dateIni from callOutStart A
inner join tmpccLogAgentesDia B on A.userId=B.userId and A.dateIni=B.dateIni 
where B.tStatus>0
group by A.userId,B.callId,B.camType,B.camId
)
,outData  as(
	select 
	
	cal_Inicio AS dateStartDetail	
	, DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, ISNULL(B.dateIni,A.cal_Inicio)) AS dateEndDetail
	,cam_id,[User_id], 1 AS ntotal
	,CASE WHEN statuscall_id = 4 THEN 1 ELSE 0 END AS nno_agent
	,CASE WHEN statuscall_id >= 10 THEN 1 ELSE 0 END AS nxfer
	,CASE WHEN statuscall_id = 11 THEN 1 ELSE 0 END AS nabnd_xfer
	, CASE WHEN statuscall_id = 15 AND cal_tring <= @tresRing THEN 1 ELSE 0 END AS nabnd_ring
	, CASE WHEN statuscall_id = 15 AND cal_tring > @tresRing THEN 1 ELSE 0 END AS nno_answer
	, CASE WHEN statuscall_id = 13 AND cal_tdialog <= @tresDialog THEN 1 ELSE 0 END AS nabnd_dialog
	, CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog THEN 1 ELSE 0 END AS nanswer
	, CASE WHEN statuscall_id = 16 THEN 1 ELSE 0 END AS nlost
	, cal_twait AS tque, cal_txfer AS txfer, cal_tring AS tring, cal_tdialog AS tdialog, cal_tnotas AS tnotes
	, CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog THEN cal_txfer + cal_tring ELSE 0 END AS tresp
	, CASE WHEN statuscall_id = 6 THEN 1 ELSE 0 END AS nhangup
	, CASE WHEN cal_tMoh > 0 THEN 1 ELSE 0 END AS nMoh
	, CASE WHEN cal_whoHung > 0 THEN 1 ELSE 0 END AS nWHag
	, CASE WHEN cal_whoHung = 0 THEN 1 ELSE 0 END AS nWHcl
	, DATEADD(ss, cal_twait, cal_inicio) AS time_endque
	, ISNULL(B.dateIni,A.cal_Inicio) as dateXferAgtStart
	, DATEADD(ss, cal_txfer, ISNULL(B.dateIni,A.cal_Inicio)) AS time_ring
	, DATEADD(ss, cal_txfer + cal_tring, ISNULL(B.dateIni,A.cal_Inicio)) AS time_dialog
	, DATEADD(ss, cal_txfer + cal_tring + cal_tdialog, ISNULL(B.dateIni,A.cal_Inicio)) AS time_notes
	, DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, ISNULL(B.dateIni,A.cal_Inicio)) AS time_end_call
	, cal_telefono AS phone_out, cal_id, cal_puerto, C.idwg AS idwg
	, A.statuscall_id, A.calif_id, A.cal_manual, A.cal_tMoh
	from ccoCallsOut A
	left join callDataStartXfer B on A.cal_id= B.callId and A.cam_id=B.camId
	LEFT JOIN @relastionCampWg C ON A.cam_id = C.camId
	WHERE A.cal_Inicio between @fromExtended AND @to
)

	

INSERT INTO tmpTimesOutboundData (
	dateStartDetail, dateEndDetail, cam_id, User_id, ntotal, nno_agent, nxfer, nabnd_xfer, nabnd_ring, nno_answer, nabnd_dialog, 
	nanswer, nlost, tque, txfer, tring, tdialog, tnotes, tresp, nhangup, nMoh, nWHag, nWHcl, time_endque,dateXferAgtStart, time_ring, time_dialog, 
	time_notes, time_end_call, phone_out, cal_id, cal_puerto, idwg, statuscall_id, calif_id, cal_manual, cal_tMoh, timegroup, 
	timegroup_next
	)
SELECT A.*, dbo.GetTimeGroup(dateStartDetail, 0) AS timegroup, dbo.GetTimeGroup(dateEndDetail, 1) AS timegroup_next
FROM outData A




declare @today date
set @today =convert(date,@dateNow,121)


/******************* Revisa si los datos son del dia ******************************/

IF @today = CONVERT(DATE, @to, 121)
BEGIN
		;

	WITH lastAgentStatus
	AS (
		SELECT userId, max(dateIni) dateIn
		FROM tmpccLogAgentesDia
		WHERE dateIni BETWEEN @today AND @to
		GROUP BY userId
		), timeAcumlate
	AS (
		SELECT A.userId, A.camId, A.callId, sum(CASE WHEN A.currentStatus IN (4, 5, 9) THEN A.tStatus 
					ELSE 0 END) AS tdialog, sum(CASE WHEN A.currentStatus = 6 THEN A.tStatus ELSE 0 END) AS tnotes, max(A.dateEnd) AS 
			dateEnd, max(A.timeGroupNext) AS timeGroupNext
		FROM tmpccLogAgentesDia A
		INNER JOIN lastAgentStatus B ON A.userId = B.userId
			AND A.dateIni = B.dateIn
		WHERE A.dateIni BETWEEN @today	 AND @to
			AND currentStatus IN (4, 5, 6, 9)
			AND A.camType = 1
		GROUP BY A.userId, A.camId, A.callId
		)
	UPDATE A
	SET A.dateEndDetail = B.dateEnd, A.timegroup_next = B.timeGroupNext, A.tdialog = CASE WHEN B.tdialog > 0 THEN B.tdialog ELSE A.
				tdialog END, A.tnotes = CASE WHEN B.tnotes > 0 THEN B.tnotes ELSE A.tnotes END, A.time_notes = CASE WHEN B.tdialog > 0 THEN B.
					dateEnd ELSE A.time_dialog END, A.time_end_call = CASE WHEN B.tnotes > 0 THEN B.dateEnd ELSE A.time_notes END
	FROM tmpTimesOutboundData A
	INNER JOIN timeAcumlate B ON A.User_id = B.userId
		AND A.cam_id = B.camId
		AND A.cal_id = B.callId
END

SELECT *
INTO #outboundData2
FROM tmpTimesOutboundData
WHERE datediff(mi, timegroup, timegroup_next) > 15

DELETE tmpTimesOutboundData
WHERE datediff(mi, timegroup, timegroup_next) > 15

INSERT INTO tmpTimesOutboundData (
	dateStartDetail, dateEndDetail, timegroup, timegroup_next, cam_id, User_id, ntotal, nno_agent, nxfer, nabnd_xfer, nabnd_ring, 
	nno_answer, nabnd_dialog, nanswer, nlost, tque, txfer, tring, tdialog, tnotes, tresp, nhangup, nMoh, nWHag, nWHcl, time_endque, 
	dateXferAgtStart, time_ring, time_dialog, time_notes, time_end_call, phone_out, cal_id, cal_puerto, idwg, statuscall_id, calif_id,  
	cal_manual, cal_tMoh
	)
SELECT dateStartDetail, dateEndDetail, th.start AS timegroup, th.stop AS timegroup_next, cam_id, [User_id]
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN ntotal ELSE 0 END AS ntotal
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nno_agent ELSE 0 END AS nno_agent
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nxfer ELSE 0 END AS nxfer
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nabnd_xfer ELSE 0 END AS nabnd_xfer
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nabnd_ring ELSE 0 END AS nabnd_ring
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nno_answer ELSE 0 END AS nno_answer
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nabnd_dialog ELSE 0 END AS nabnd_dialog
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nanswer ELSE 0 END AS nanswer
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nlost ELSE 0 END AS nlost
	, dbo.TimeInterval(th.start, th.stop, dateStartDetail, time_endque) AS tque
	, dbo.TimeInterval(th.start, th.stop, dateXferAgtStart, time_ring) AS txfer
	, dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring
	, dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog
	, dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes
	, dbo.TimeInterval(th.start, th.stop, dateStartDetail
	, dateadd(ss, tresp, dateStartDetail)) AS tresp
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nhangup ELSE 0 END AS nhangup
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nMoh ELSE 0 END AS nMoh
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nWHag ELSE 0 END AS nWHag
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nWHcl ELSE 0 END AS nWHcl
	, time_endque, dateXferAgtStart, time_ring, time_dialog, time_notes, time_end_call 
	, phone_out, cal_id, cal_puerto, idwg, statuscall_id
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  calif_id ELSE - 2 END AS calif_id
	, cal_manual
	, dbo.AccountInterval(th.start, th.stop, dateStartDetail, dateEndDetail, cal_tMoh) AS cal_tMoh
	FROM #outboundData2 t
	INNER JOIN TmpTimesInterval th ON  ( t.timegroup > th.Start AND t.timegroup < th.stop)	OR th.Start BETWEEN t.timegroup AND t.timegroup_next
	WHERE datediff(ss, th.start, timegroup_next) > 0
	

IF OBJECT_ID(N''tempdb..#outboundData2'', N''U'') IS NOT NULL
	DROP TABLE #outboundData2
'
	EXEC(@sql)
	

	set @process = 'DEV1-339 Alter Sp ccspTimesccLogAgentesDia Se modifica para que le ms para ajustar los tiempos y se mas cercanos y se quita los datos son
	repetidos por los eventos de desconexion '
	set @sql = 'ALTER PROCEDURE [dbo].[ccspTimesccLogAgentesDia] @from AS SMALLDATETIME, @to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia2'', N''U'') IS NOT NULL Begin
	DROP TABLE #tempccLogAgentesDia2
End

IF NOT EXISTS (SELECT *	FROM sys.tables	WHERE name = ''tmpccLogAgentesDia'')
BEGIN
	CREATE TABLE tmpccLogAgentesDia (
		id INT NOT NULL 
		,userId INT NOT NULL
		,TipoStatusAge_id TINYINT NOT NULL
		,tStatus FLOAT NOT NULL
		,dateIni DATETIME NOT NULL
		,dateEnd DATETIME NOT NULL
		,currentStatus INT NOT NULL
		,timeGroup DATETIME NOT NULL
		,timeGroupNext DATETIME NOT NULL
		,camId SMALLINT
		,camType SMALLINT
		,callId INT,
		primary key (id,userId)
		);

		CREATE NONCLUSTERED INDEX [IX_tmpccLogAgentesDia_TipoStatusAge_id]
		ON [dbo].[tmpccLogAgentesDia] ([TipoStatusAge_id])
		INCLUDE ([tStatus],[timeGroupNext])
END
ELSE
BEGIN
	TRUNCATE TABLE tmpccLogAgentesDia		
END

CREATE TABLE #tempccLogAgentesDia2 (
	rowId INT NOT NULL
	,userId INT NOT NULL
	,TipoStatusAge_id TINYINT NOT NULL
	,tStatus FLOAT NOT NULL
	,dateIni DATETIME NOT NULL
	,dateEnd DATETIME NOT NULL
	,currentStatus INT
	,timeGroup DATETIME NOT NULL
	,timeGroupNext DATETIME NOT NULL
	,camId SMALLINT
	,camType SMALLINT
	,callId INT
	);

WITH tmpLog
AS (
	SELECT User_id AS userId
		,TipoStatusAge_id
		,tStatus
		,DATEADD(ms, - tStatus*1000, fecha) dateIni
		,fecha dateEnd
		,ISNULL(currentStatus, 0) AS currentStatus
		,dbo.GetTimeGroup(DATEADD(ms, - tStatus*1000, fecha), 0) AS timegroup
		,dbo.GetTimeGroup(fecha, 1) AS timegroup_next
		,IdCampEsp AS camId
		,Tipo AS camType
		,callId
	FROM ccLogAgentesDia
	WHERE DATEADD(ss, - tStatus, fecha) BETWEEN @from AND @to 	
	)
, cteLogAgentesDia as (

SELECT ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId
	,userId
	,TipoStatusAge_id
	,tStatus
	,dateIni
	,dateEnd
	,currentStatus
	,timegroup
	,timegroup_next
	,camId
	,camType
	,callId
FROM tmpLog
)
insert into tmpccLogAgentesDia
select * from cteLogAgentesDia


/***** Elimina los repetidos ******/
; with regDeleteRepLogout as(
SELECT 
	case when A.currentStatus=-2 then S.Id else A.Id end [rowId], A.userId	
	FROM tmpccLogAgentesDia A
	LEFT JOIN tmpccLogAgentesDia S ON A.Id = S.Id - 1
		AND A.userId = S.userId
	WHERE A.dateIni >= @from
		AND A.dateIni < @to
		AND A.tStatus >0 and S.tStatus >0
		AND A.TipoStatusAge_id = S.TipoStatusAge_id
		AND A.TipoStatusAge_id>0		
		AND ABS(DATEDIFF(ss, A.dateEnd, S.dateIni)) > 1				
),
rowReconnectLogout as(
select ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId,* 
from tmpccLogAgentesDia where currentStatus in(30,-2) and tStatus>0
)
,
regDeleteReconnect as( 
 select 
case when A.currentStatus=-2 then S.Id else A.Id end [rowId], A.userId
--,A.userId,S.userId,A.RowId,S.RowId,A.timeGroup,S.timeGroupNext,A.id,S.id,A.TipoStatusAge_id,S.TipoStatusAge_id,A.tStatus,S.tStatus
--,A.dateIni,A.dateEnd,S.dateIni,S.dateEnd
--,ABS(A.tStatus-S.tStatus)
from rowReconnectLogout A
inner join rowReconnectLogout S on A.userId=S.userId and A.RowId=S.RowId-1 
and A.TipoStatusAge_id=S.TipoStatusAge_id 
where ( A.dateIni between S.dateIni and S.dateEnd or S.dateIni between A.dateIni and A.dateEnd)
 )
 , rowDelete as(
 select * from regDeleteRepLogout
 union 
 select * from regDeleteReconnect
 )

--SELECT A.*
Delete A
from tmpccLogAgentesDia A
inner join rowDelete X  ON A.id = x.rowId AND A.userId = x.userId;

	
/***** Revisa si es el dia actual para calcular el tiempo del estado ******/
declare @today date,@dateNow datetime
SET @today = convert(DATE, GETDATE(), 121)
SET @dateNow=GETDATE()


IF @today = CONVERT(DATE, @to, 121)
BEGIN
	;	
	WITH tmpAgentLastStatus
	AS (
		SELECT userId ,MAX(dateEnd) AS dateStart
		FROM tmpccLogAgentesDia
		WHERE dateEnd BETWEEN @today AND @to
		GROUP BY userId
		)			

	INSERT INTO tmpccLogAgentesDia
	SELECT 0
		,A.userId
		,A.currentStatus
		,DATEDIFF(ss, A.dateEnd, @dateNow) AS tStatus
		,B.dateStart
		,@dateNow
		,A.currentStatus
		,dbo.GetTimeGroup(B.dateStart, 0) AS timegroup
		,dbo.GetTimeGroup(@dateNow, 1) AS timegroup_next
		,A.camId
		,A.camType
		,A.callId
	FROM tmpccLogAgentesDia A
	INNER JOIN tmpAgentLastStatus B ON A.dateEnd = B.dateStart AND A.userId = B.userId
	WHERE A.dateIni BETWEEN @today AND @to
		AND A.currentStatus NOT IN (- 2, - 1, 0);
END


/***** Separa los estados para tenerlos en intervalos 15 minutos para algunos reportes ******/
INSERT INTO #tempccLogAgentesDia2
SELECT * FROM tmpccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15


DELETE tmpccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15;



INSERT INTO tmpccLogAgentesDia
SELECT-1* ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId
	,t.userId
	,TipoStatusAge_id
	,dbo.TimeInterval(th.start, th.stop, dateIni, dateEnd) AS tStatus
	,dateIni
	,dateEnd
	,currentStatus
	,th.start AS timegroup
	,th.stop AS timegroup_next
	,t.camId
	,t.camType
	,t.callId
FROM #tempccLogAgentesDia2 t
INNER JOIN TmpTimesInterval th ON (
		t.timegroup > th.Start
		AND t.timegroup < th.stop
		)
	OR th.Start BETWEEN t.timegroup
		AND t.timeGroupNext
WHERE DATEDIFF(ss, th.start, timeGroupNext) > 0
	AND th.Start BETWEEN @from
		AND @to
order by dateIni,timegroup


IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia2'', N''U'') IS NOT NULL
	DROP TABLE #tempccLogAgentesDia2

'
	EXEC(@sql)

	set @process = 'DEV1-339 Alter FN TimeInterval Se modifica para regresar float'
	set @sql = 'ALTER FUNCTION [dbo].[TimeInterval] (@start datetime,@stop datetime,@state1 datetime,@state2 datetime)  
RETURNS float
AS  
BEGIN 
	declare @time float
	
	set @time= 
	case when @start <= @state1 and  @stop > @state1 and @start<= @state2 and  @stop > @state2 then datediff(ms,@state1,@state2)/1000.0
	 when @start<= @state1 and  @stop > @state1 and @stop < @state2 then datediff(ms,@state1,@stop)/1000.0
	 when @start> @state1 and @start<= @state2 and  @stop > @state2 then datediff(ms,@start,@state2)/1000.0
	 when @start> @state1 and @stop < @state2 then datediff(ms,@start,@stop)/1000.0 else  0 end

	RETURN (@time)
END'
	EXEC(@sql)

	set @process = 'DEV1-339  Alter Sp ccspRepAgentNotReady Se reutiliza el SP RepAgentNotReadyDet'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentNotReady]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

IF OBJECT_ID(''tempdb..#notReady'') IS NOT NULL
	DROP TABLE #notReady
IF OBJECT_ID(''tempdb..#notReady2'') IS NOT NULL
	DROP TABLE #notReady2;

WITH notReadyDetail
AS (
select userId,startDate,endDate,statusTime as tStatus,0 separado,TipoNotReadyId	
,convert(DATETIME, convert(VARCHAR(13), startDate, 121) + '':00:00'', 121) AS timegroup
,convert(DATETIME, convert(VARCHAR(13), dateadd(hh, 1, endDate), 121) + '':00:00'', 121) AS timegroup_next
from RepAgentNotReadyDet with(nolock) where startDate between @from and @to
)

SELECT timegroup, timegroup_next, userId, TipoNotReadyId, tStatus AS [time], startDate, endDate, 1 AS [count]
INTO #notReady
FROM notReadyDetail

SELECT *
INTO #notReady2
FROM #notReady WHERE DATEDIFF(hh, timegroup, timegroup_next) > 1

DELETE #notReady
WHERE datediff(HH, timegroup, timegroup_next) > 1	
;
	
--Delete repetidos
delete from RepAgentNotReady with(rowlock) 	where date >= @from AND date < @to;
	
;WITH timebyHour
AS (
	SELECT convert(DATETIME, convert(VARCHAR(13), Start, 121) + '':00:00'', 121) AS [start]
	, convert(DATETIME, convert(VARCHAR(13), dateadd(hh, 1, Start), 121) + '':00:00'', 121) AS [stop]
	FROM TmpTimesInterval
	GROUP BY convert(VARCHAR(13), Start, 121), convert(DATETIME, convert(VARCHAR(13), dateadd(hh, 1, Start), 121) + '':00:00'', 121)
	), notReadybyHour
AS (
	SELECT th.start AS timegroup, th.stop AS timegroup_next, userId, TipoNotReadyId, dbo.TimeInterval(th.start, th.stop, startDate, endDate) AS [time], startDate, endDate, dbo.AccountInterval(th.start, th.stop, 
			startDate, endDate, [count]) AS [count]
	FROM #notReady2 t
	INNER JOIN timebyHour th
	ON (t.timegroup > th.Start AND t.timegroup < th.stop) OR th.Start BETWEEN t.timegroup AND t.timegroup_next
	WHERE datediff(ss, th.start, timegroup_next) > 0
	)

	insert into #notReady
	select * from notReadybyHour

	delete from RepAgentNotReady where [date] between @from and @to
	
	;with notReadyGroupbyHour as(
		select timegroup,userId,tiponotreadyId,SUM(time) as time, 
		SUM(count) as [count]
		from #notReady
		group by timegroup,userId,tiponotreadyId		
	)
	,timeSessionByHour
AS (
	SELECT convert(DATETIME, convert(VARCHAR(13), timegroup, 121) + '':00:00'', 121) AS timegroup, user_id AS userId, sum(tlog) AS tlog
	FROM TmpSessionTimeGroup
	GROUP BY convert(DATETIME, convert(VARCHAR(13), timegroup, 121) + '':00:00'', 121), user_id
	)

insert into RepAgentNotReady
SELECT A.timegroup, userView.[Login]
, A.userId, userView.apellidopaterno + '' '' + userView.apellidomaterno + '' '' + userView.nombres AS [user]
, A.tlog AS sessionTime
, isnull(notReady.TipoNotReadyId,0) as TipoNotReadyId, isnull(d.descripcion, '''') 
descripcion, isnull(d.descripcion, '''') + ''_Count'' AS descripcion_count, isnull(notReady.[count], 0) [count], isnull(d.descripcion, '''') + ''_Time'' AS descripcion_time, isnull(notReady.TIME, 0) AS [time], isnull(
notReady.TIME, 0) AS timeSeconds
,datepart(yyyy,A.timegroup) as [year]
,datepart(HH,A.timegroup) as [mount]
,datepart(MM,A.timegroup) as [day]
,datepart(mi,A.timegroup) as [hour]
,0 as minute
FROM timeSessionByHour A
INNER JOIN ccUserView userView ON A.userId = userView.User_id
LEFT JOIN notReadyGroupbyHour notReady	ON notReady.userId = A.userId AND A.timegroup = notReady.timegroup
LEFT JOIN ccTipoNotReady d	ON notReady.TipoNotReadyId = d.TipoNotReady_id

IF OBJECT_ID(''tempdb..#notReady'') IS NOT NULL
	DROP TABLE #notReady

IF OBJECT_ID(''tempdb..#notReady2'') IS NOT NULL
	DROP TABLE #notReady2
end'
	EXEC(@sql)

	set @process = 'DEV1-339 Alter SP ccspRepAgentSummary Se modifica el SP para agregar todos los no disponibles reporte pivoteado'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentSummary] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()))

IF @to IS NULL
	SELECT @to = GETDATE()

if(@to = convert(datetime,convert(varchar(11),getdate(),121)+''03:00:00'',121)) AND @from = DATEADD(dd,-1,@to)
BEGIN	
	select @from = convert(datetime,convert(varchar(11),@from))
END

IF @action = 1
BEGIN
		
	DELETE RepAgentSummary WHERE DATE BETWEEN @from	AND @to;
	;
	WITH AgentSession
	AS (
		SELECT dbo.getdaygroup(loginTime) AS [date], userId, min([login]) AS [login], [user] AS [user], MIN(loginTime) AS dateLogin, MAX(logoutTime) AS logout, SUM(sessionTimeSeconds) AS sessionTime
		FROM RepAgentSession
		WHERE dbo.getdaygroup(loginTime) BETWEEN @from AND @to
		GROUP BY dbo.getdaygroup(logintime), userId, [user]
		),
		-------------OUT -------------------
	dataCallsOut
	AS (
		SELECT DISTINCT cal_id, max(calif_id) calif_id, statusCall_id
		FROM tmpTimesOutboundData
		where cal_manual in (0,2,3)
		GROUP BY cal_id, statusCall_id
		), dataCallsOutByDay
	AS (
		SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogOut, SUM(tnotes) tNotesOut, sum(nabnd_xfer) nabnd_xfer
		, sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
		, SUM(txfer)  txferOut, SUM(tring)  tringOut
		FROM tmpTimesOutboundData
		where cal_manual in (0,2,3)
		GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
		), tmpCallout
	AS (
		SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifOut
		, isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallOut
		, isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallOut
		, sum(tDialogOut) AS tDialogOut, sum(tNotesOut) AS tNotesOut, sum(nabnd_xfer) abnd_xfer, sum(nabnd_ring) abnd_ring
		, sum(nabnd_dialog) abnd_dialog, [date]
		, SUM(txferOut)  txferOut, SUM(tringOut)  tringOut
		FROM dataCallsOutByDay A
		INNER JOIN dataCallsOut B
			ON A.cal_id = B.cal_id
		GROUP BY [date], User_id
		),
		------------- IN -------------------
	dataCallsIn
	AS (
		SELECT DISTINCT cal_id, max(calif_id) calif_id, statusCall_id
		FROM tmpTimesInboundData
		GROUP BY cal_id, statusCall_id
		), dataCallsInByDay
	AS (
		SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogIn, SUM(tnotes) tNotesIn
		, sum(nabnd_xfer) nabnd_xfer, sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
		, SUM(txfer)  txferIn, SUM(tring)  tringIn
		FROM tmpTimesInboundData
		GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
		), tmpCallIn
	AS (
		SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifIn
		, isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallIn
		, isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallIn
		, sum(tDialogIn) AS tDialogIn, sum(tNotesIn) AS tNotesIn, sum(nabnd_xfer) abnd_xfer
		, sum(nabnd_ring) abnd_ring, sum(nabnd_dialog) abnd_dialog, [date]
		, SUM(txferIn)  txferIn, SUM(tringIn)  tringIn
		FROM dataCallsInByDay A
		INNER JOIN dataCallsIn B
			ON A.cal_id = B.cal_id
		GROUP BY [date], User_id
		), RepDetail
	AS (
		SELECT r.userId, SUM(r.timeSeconds) AS notReady, dbo.getdaygroup(r.DATE) AS daygroup
		FROM RepAgentNotReady r with(nolock)
		WHERE r.DATE BETWEEN @from AND @to
		GROUP BY dbo.getdaygroup(r.DATE), r.userId
		)
	,notReadyDay as(
	SELECT r.userId, SUM(r.timeSeconds) AS timeSeconds, dbo.getdaygroup(r.DATE) AS daygroup
		,descripcion_time,descripcion,tiponotreadyId
		FROM RepAgentNotReady r with(nolock)
		WHERE r.DATE BETWEEN @from AND @to
		GROUP BY dbo.getdaygroup(r.DATE), r.userId,descripcion,descripcion_time,tiponotreadyId
	), RepAgentGIGroup as(
		SELECT dbo.getdaygroup([date]) AS [date], userId, SUM(tav) AS tav
		, SUM(tunknown) AS tunknown
		, SUM(tother) AS tother
		, SUM(tprob) AS tprob
		, SUM(tChatting) AS tChatting		
		, SUM(tundefined) AS tundefined
		, SUM([tManual]) AS [tManual]
		FROM RepAgentGI
		WHERE [date] BETWEEN @from AND @to
		GROUP BY dbo.getdaygroup([date]), userId
	)

	INSERT INTO RepAgentSummary (date,login,[user],sessionTime,loginMktTime,logoutMktTime,callTengaged,ndTime,NCallsOut,NCallsIn,NCallsCorta,NAtend,NNoCalif
	,Available,avgCallTengaged,twrapup,userId,TypeNotReady,descripcion,descripcion_time,time,transferStatus,ringingTime,unknownStatus,otherStatus,failureStatus
	,chatTengaged,undefinedTime,dialingStatus)
	SELECT A.[date], A.[login], A.[user], A.sessionTime, A.dateLogin AS loginMktTime
	, A.logout AS logoutMktTime
	, isnull(co.tDialogOut, 0) + isnull(ci.tDialogIn, 0) callTengaged
	, ISNULL(r.notready, 0) AS ndTime, isnull(co.AttendedCallOut, 0) AS NCallsOut, isnull(ci.AttendedCallIn, 0) AS NCallsIn
	, ISNULL(co.abnd_xfer, 0) + isnull(co.abnd_ring, 0) + isnull(co.abnd_ring, 0) + isnull(ci.abnd_xfer, 0) + isnull(ci.abnd_ring, 0) + isnull(ci.abnd_ring, 0) AS NCallsCorta
	, ISNULL(co.NotAttendedCallOut, 0) + ISNULL(ci.NotAttendedCallIn, 0) AS NAtend
	, ISNULL(ci.NoCalifIn, 0) + ISNULL(co.NoCalifOut, 0) AS NNoCalif	
	, ISNULL(AgtGI.tav, 0) AS Available
		,ISNULL(	
		(	ISNULL(co.tDialogOut, 0) + ISNULL(co.tNotesOut, 0) + ISNULL(ci.tDialogIn, 0) + ISNULL(ci.tNotesIn, 0) )
			/
		 nullif(isnull(co.AttendedCallOut,0) + isnull(ci.AttendedCallIn,0),0)
		, 0) AS avgCallTengaged
		
		,ISNULL(co.tNotesOut, 0) + ISNULL(ci.tNotesIn, 0) AS twrapup, A.userId AS userId
		, notReady.TipoNotReadyId
		, notReady.descripcion
		, notReady.descripcion_time
		, notReady.timeSeconds
		, ISNULL(co.txferOut, 0) + ISNULL(ci.txferIn, 0) AS transferStatus
		, ISNULL(co.tringOut, 0) + ISNULL(ci.tringIn, 0) AS ringingTime
		, ISNULL(AgtGI.tunknown, 0) unknownStatus
		, ISNULL(AgtGI.tother, 0) otherStatus
		, ISNULL(AgtGI.tprob, 0) failureStatus
		, ISNULL(AgtGI.tChatting, 0) chatTengaged
		, ISNULL(AgtGI.tundefined, 0) undefinedTime
		, ISNULL(AgtGI.tManual, 0) dialingStatus
	FROM AgentSession A
	LEFT JOIN tmpCallout co ON A.DATE = co.DATE	AND A.userId = co.userId
	LEFT JOIN tmpCallIn ci	ON A.DATE = ci.DATE	AND A.userId = ci.userId
	LEFT JOIN RepDetail r	ON r.daygroup = A.DATE AND A.userId = r.userId
	inner join notReadyDay notReady on notReady.userId=A.userId and notReady.daygroup=A.date
	left join RepAgentGIGroup AgtGI on AgtGI.date=A.date and AgtGI.userId=A.userId
	
	order by A.[date],A.userId

END'
	EXEC(@sql)

	set @process = 'DEV1-339  Alter SP ccspRepDetailAgent Se modifica para reutilzar las tablas RepAgentSessionByInterval,RepAgentNotReady,tmpTimesOutboundData,tmpccLogAgentesDia y tmpTimesInboundData'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepDetailAgent]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET NOCOUNT ON

declare @califout int , @califin int
declare @var varchar(100)

BEGIN
SET ANSI_WARNINGS off
SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to =getdate()

if @action=1 begin

	
set @califout =1
set @califin =1

select @var= valor from ccsettings where setting_id = 39
select @califout = Value from dbo.fn_RIASplitDelimited(@var,''|'') where Id=1
select @califin =  Value from dbo.fn_RIASplitDelimited(@var,''|'') where Id=2

delete from RepDetailAgent where date>=@from and date<@to

 ;with notReady as(
 select A.date,A.userId,SUM(A.timeSeconds) as tnot_av
 from RepAgentNotReady A 
 where A.date between @from and @to
 group by A.date,A.userId
 ) , AgentSession as (
 select A.userId,A.login as [user],A.[user] as [userName]
 ,convert(datetime,convert(varchar(14),A.date,121)+''00:00'',121) as [date]
 ,sum(A.sessionTime) as sessionTime
 from RepAgentSessionByInterval A
 where A.date between @from and @to
 group by A.userId,A.login ,A.[user],convert(datetime,convert(varchar(14),A.date,121)+''00:00'',121)
 ), callDataOut as(
 select convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121) as [date]
 ,A.User_id as UserId,sum(A.txfer) as txfer,sum(A.tring) as tring  ,sum(A.tdialog) as tdialog
 ,sum(A.tnotes) as tnotes, SUM(ntotal) as ntotal
 ,count(case when A.calif_id = @califout then 1 else null end) as completeOut --Revisar el calificacionId
 from tmpTimesOutboundData A
 where A.cal_manual in(0,2)
 group by convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121),A.User_id
 ), callDataIn as(
 select convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121) as [date]
 ,A.User_id as UserId,sum(A.txfer) as txfer,sum(A.tring) as tring  ,sum(A.tdialog) as tdialog
 ,sum(A.tnotes) as tnotes, SUM(ntotal) as ntotal
 ,count(case when A.calif_id = @califin then 1 else null end) as completeIn --Revisar el calificacionId
 from tmpTimesInboundData A
 group by convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121),A.User_id
 ),timeAgent as(  
 select convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121) as [date]
 ,userId,
 sum(case when TipoStatusAge_id =3 then tStatus else 0 end) tav 
 from tmpccLogAgentesDia A
where TipoStatusAge_id>0
group by convert(datetime,convert(varchar(14),A.timegroup,121)+''00:00'',121),userId
 )
 , callData as(   
 select isnull(callOut.date,callIn.date) as [date],isnull(callOut.userId,callIn.UserId) as UserId
 ,isnull(callOut.txfer,0) +isnull(callIn.txfer,0) as txfer
 ,isnull(callOut.tring,0) +isnull(callIn.tring,0) as tring
 ,isnull(callOut.tdialog,0) +isnull(callIn.tdialog,0) as tdialog
 ,isnull(callOut.tnotes,0) +isnull(callIn.tnotes,0) as tnotes
 ,isnull(callOut.ntotal,0)+isnull(callIn.ntotal,0) as ntotal 
 ,isnull(callOut.completeOut,0)+isnull(callIn.completeIn,0) as  [complete]
 from callDataOut callOut
 full outer join callDataIn callIn on callOut.[date]=callIn.[date] and callOut.UserId=callIn.userId
 )

 insert into RepDetailAgent
 select A.userId,A.[user],A.userName,A.[date],A.sessionTime
 ,A.sessionTime - isnull(B.tnot_av,0) as [activeTime]
 ,isnull(C.txfer+C.tring+C.tdialog+C.tnotes,0) as [talkingtTime]
 ,isnull(C.txfer+C.tring,0) as [holdTime]
 ,isnull(B.tnot_av,0) as [unavaibleTime]
 ,convert ( decimal(18,3),  isnull(C.tdialog*1.0 ,0)/36.0 ) as [talkingPercent]
 ,convert ( decimal(18,3),  isnull((C.txfer+C.tring)*1.0 ,0)/36.0 ) as [waitpercent]
 ,convert ( decimal(18,3), isnull(t.tav *1.0,0) /36.0 ) as [readyPercent]
 ,convert ( decimal(10,3), ( (1.0*A.sessionTime)-( isnull(B.tnot_av,0) ))/A.sessionTime  ) as [adherencia]
 ,isnull(C.ntotal,0) as [totalCalls]
 ,isnull(C.ntotal,0)  as [callsByHour]
 ,isnull(C.[complete],0) as  [complete]
 ,convert(decimal(10,4),  (isnull(C.[complete]*1.0,0) )/7.0) as  [completeByHour] --se va ocultar en la interfaz
 ,case when C.ntotal=0 or C.ntotal is null then 0.0000
	else convert(decimal(10,4), isnull( ( C.[complete]*1.0)/ C.ntotal,0) )  end as [percentComplete]
 ,datepart(YYYY,A.[date]) [year]
,datepart(MM,A.[date]) [month]
,datepart(DD,A.[date]) [day]
,datepart(HH,A.[date]) [hour]
,0 [minutes]
 from AgentSession A 
 left join notReady B on A.date=B.date and A.userId=B.userId
 left join callData C on A.date=C.date and A.userId=C.userId 
 left join timeAgent t on A.date=t.date and A.userId=t.userId
 order by A.[date]
		
	
end
END'
	EXEC(@sql)


	set @process = 'DEV1-339  Alter SP ccspRepAgentGI se modifica para quitar el detalle y reutilizar las tablas tmpccLogAgentesDia,tmpTimesInboundData,tmpTimesOutboundData y TmpSessionTimeGroup'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentGI] 
@action AS TINYINT ,@from AS DATETIME ,@to AS DATETIME
AS
SET ANSI_WARNINGS OFF;
SET NOCOUNT ON;

IF @from IS NULL
	SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

IF @to IS NULL
	SELECT @to = GETDATE();

IF @action = 1
BEGIN
	
	DELETE	FROM RepAgentGI	WHERE DATE >= @from	AND DATE < @to

	;with timeDetailAgent as(	
	SELECT userId, timegroup		
		,sum(CASE WHEN tipostatusage_id = 1 THEN tStatus ELSE 0 END) tunknown
		,sum(CASE WHEN tipostatusage_id = 2 THEN tStatus ELSE 0 END) tNotReady
		,sum(CASE WHEN tipostatusage_id IN (3, 31) THEN tStatus ELSE 0 END) tReady 	--3	Ready y 31	Ready PreviewPro	
		,sum(CASE WHEN tipostatusage_id IN (11, 25, 26, 27) THEN tStatus ELSE 0 END) tprob --11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida		
		,sum(CASE WHEN tipostatusage_id = 7 THEN tStatus ELSE 0 END) tother
		,sum(CASE WHEN tipostatusage_id = 7 THEN 1 ELSE 0 END) nother
		,sum(CASE WHEN tipostatusage_id = 21 THEN tStatus ELSE 0 END) tmanualcall		
		,sum(CASE WHEN tipostatusage_id IN (23, 24) THEN tStatus ELSE 0 END) AS tchatting
		,sum(CASE WHEN tipostatusage_id = 30 THEN tStatus ELSE 0 END) AS tReconnectKolob
		,sum(CASE WHEN tipostatusage_id = 32 THEN tStatus ELSE 0 END) AS tPreview
		,sum(CASE WHEN tipostatusage_id = 33 THEN tStatus ELSE 0 END) AS tAssisted
		,sum(CASE WHEN tipostatusage_id = 34 THEN tStatus ELSE 0 END) AS tDialogoWhatsApp
		FROM tmpccLogAgentesDia A
		group by A.userId,A.timegroup
	)	
	,inboundCount
	AS (
		SELECT timegroup
			,user_id AS userId
			,sum(nxfer) AS nxferin
			,sum(nanswer) AS nanswerin
			,sum(nabnd_xfer) AS nabndxferin
			,sum(nabnd_ring) AS nabndringin
			,sum(nabnd_dialog) AS nabnddlgin
			,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) AS abndaxferin
			,sum(nno_answer) AS nnoanswerin
			,sum(nlost) AS nlostin
			,sum(nMoh) AS nMohIn
			,sum(nWHag) AS nWHagIn
			,sum(nWHcl) AS nWHclIn
			,sum(tdialog) AS tdialogIn
			,sum(tnotes) AS tnotesIn
			,sum(tring) AS tringIn
			,sum(txfer) AS txferIn			
		FROM tmpTimesInboundData
		WHERE user_id > 0
		group by timegroup,user_id
		)
		,outboundCount
	AS (
		SELECT timegroup
			,user_id AS userId
			,sum(nxfer) AS nxferOut
			,sum(nanswer) AS nanswerOut
			,sum(nabnd_xfer) AS nabndxferOut
			,sum(nabnd_ring) AS nabndringOut
			,sum(nabnd_dialog) AS nabnddlgOut
			,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) AS abndaxferOut
			,sum(nno_answer) AS nnoanswerOut
			,sum(nlost) AS nlostOut
			,sum(nMoh) AS nMohOut
			,sum(nWHag) AS nWHagOut
			,sum(nWHcl) AS nWHclOut
			,sum(tdialog) AS tdialogOut
			,sum(tnotes) AS tnotesOut
			,sum(tring) AS tringOut
			,sum(txfer) AS txferOut			
		FROM tmpTimesOutboundData
		WHERE user_id > 0
			AND cal_manual IN (0, 2, 3)
			group by timegroup,user_id
		)
	
	
	
	INSERT INTO RepAgentGI
	SELECT A.timegroup AS [date]
		,A.user_id AS userId
		,u.Nombres + '' '' + u.ApellidoPaterno + '' '' + u.ApellidoMaterno AS [user]
		,u.LOGIN
		,A.tlog
		,isnull(atgStatus.tunknown,0) as tunknown
		,isnull(atgStatus.tReady,0) as tReady
		,isnull(atgStatus.tNotReady,0) as tNotReady
		,isnull(atgStatus.tother,0) as tother
		,isnull(atgStatus.tprob,0) as tprob
		,isnull(atgStatus.tchatting,0) as tchatting
		,isnull(A.tlog-( 
		isnull(atgStatus.tunknown+atgStatus.tReady+atgStatus.tNotReady+atgStatus.tother+atgStatus.tprob+atgStatus.tchatting+atgStatus.tmanualcall,0)
		+isnull( txferin+tringin+tdialogin+tnotesIn,0)
		+isnull(txferout+tringout+tdialogout+tnotesout,0)
		
		),0) as tundefined
		
		------------------ Count IN Call -----------------------
		,ISNULL(inCount.nxferin, 0) nXferIn
		,ISNULL(inCount.nanswerin, 0) nAnswerIn
		,ISNULL(inCount.nabndxferin, 0) nAbndXferIn
		,ISNULL(inCount.nabndringin, 0) nAbndRingIn
		,ISNULL(inCOunt.nabnddlgin, 0) AS nAbnddlgIn
		,ISNULL(inCount.abndaxferin, 0) abndaXferIn
		,ISNULL(inCount.nnoanswerin, 0) AS nnoAnswerIn
		,ISNULL(inCount.nlostIn, 0) AS nlostIn
		,isnull(inCount.tdialogIn, 0) AS tdialogIn
		,isnull(inCount.tnotesIn, 0) tnotesIn
		,isnull(inCount.tringIn, 0) tringIn
		,isnull(inCount.txferIn, 0) txferIn

		------------------ Count Out Call -----------------------      
		,isnull(outTime.nXferOut, 0) nXferOut
		,isnull(outTime.nAnswerOut, 0) nAnswerOut
		,isnull(outTime.nAbndXferOut, 0) nAbndXferOut
		,isnull(outTime.nAbndRingOut, 0) nAbndRingOut
		,isnull(outTime.nAbnddlgOut, 0) AS nAbnddlgOut
		,isnull(outTime.abndaXferOut, 0) abndaXferOut
		,isnull(outTime.nnoAnswerOut, 0) AS nnoAnswerOut
		,isnull(outTime.nlostOut, 0) AS nlostOut
		,ISNULL(outTime.tdialogOut, 0) tdialogOut
		,ISNULL(outTime.tnotesOut, 0) tnotesOut
		,ISNULL(outTime.tringOut, 0) tringOut
		,ISNULL(outTime.txferOut, 0) txferOut
		
		------------------ Time Agent Common -----------------------      
		,ISNULL(atgStatus.nother,0) nOther
		
		------------------ Count In/Out Call-----------------------      
		,isnull(inCount.nMohIn, 0) AS nMohIn
		,isnull(outTime.nMohOut, 0) AS nMohOut
		,isnull(inCount.nWHagIn, 0) AS nWHagIn
		,isnull(outTime.nWHagOut, 0) AS nWHagOut 
		,isnull(inCount.nWHclIn, 0) AS nWHclIn
		,isnull(outTime.nWHclOut, 0) AS nWHclOut				

		,datepart(yyyy, A.timegroup) AS [year]
		,datepart(mm, A.timegroup) AS [mount]
		,datepart(dd, A.timegroup) AS [day]
		,datepart(HH, A.timegroup) AS [hour]
		,datepart(mi, A.timegroup) AS [minutes]
		,isnull(atgStatus.tmanualcall,0) as tmanualcall
		
	FROM TmpSessionTimeGroup A
	LEFT JOIN ccUserView u ON A.[user_id] = u.[user_id]
	left join timeDetailAgent as atgStatus on atgStatus.userId=A.user_id and atgStatus.timegroup=A.timegroup
	LEFT JOIN inboundCount inCount ON A.timegroup = inCount.timegroup AND A.User_Id = inCount.userId
	left join outboundCount outTime ON outTime.timegroup = A.timegroup AND outTime.userId = A.User_id
		
END;
'
	EXEC(@sql)

	set @process = 'DEV1-339 Alter SP ccspRepAgentKPI Se modifica para no ocupar tabla temporal y agrupar por dia avg_fCalc'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentKPI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS


SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if(@to = convert(datetime,convert(varchar(11),getdate(),121)+''03:00:00'',121)) AND @from = DATEADD(dd,-1,@to)
BEGIN	
	select @from = convert(datetime,convert(varchar(11),@from))
END

if @action = 1
begin
	delete RepAgentKPI with(rowlock) where date >= @from AND date < @to
	
	;with callTemp as(	
	select  User_id, statusCall_id, cal_tDialog, convert(date, cal_Inicio, 121) as cal_Inicio, cal_whoHung, 0  as callType
	from ccoCallsOut with(nolock)
	where cal_inicio between @from and @to and cal_manual < 3
	union all
	select  User_id, statusCall_id, cal_tDialog, convert(date, cal_Inicio, 121) as cal_Inicio, cal_whoHung, 1 as callType
	from ccCallsIn with(nolock)
	where cal_inicio between @from and @to 
	) 
	, Conteos as(
	select user_id, cal_Inicio, 1 Total, case callType when 1 then 1 else 0 end Cin, case callType when 0 then 1 else 0 end Cout,
	case when statusCall_id in (11,13,15,16,17) and cal_tDialog<10 then 1 else 0 end C10,
	case when statusCall_id in (11,13,15,16,17) and cal_tDialog<20 then 1 else 0 end C20,
	case when statusCall_id in (11,13,15,16,17) and cal_tDialog<30 then 1 else 0 end C30,
	cal_whoHung from callTemp
	)
	, Trd as(	
	select  User_id, cast((AVG(convert(bigint,fecha_Calc_ms)))/1000.0 as decimal(10,0)) avg_fCalc
	, CONVERT(date,fecha_Dispo,121) as fecha_Dispo
	from ccLogAgentesDia_Dialog with(nolock)
	where fecha_Dialog between @from and @to 
	group by User_id,CONVERT(date,fecha_Dispo,121)
	)
	, Snd as(
	select user_id, cal_Inicio, sum(Total) Total, sum(Cin) Cin, sum(Cout) Cout,
	sum(C10) C10, sum(C20) C20, sum(C30) C30, sum(cal_whoHung) cal_whoHung
	from Conteos group by user_id, cal_Inicio
	)

	insert into RepAgentKPI
	select Snd.cal_Inicio,Fst.Login as login , Fst.user_id as [userId]
	,Nombres + isnull('' ''+ApellidoPaterno, '''') + isnull('' ''+ApellidoMaterno, '''') as [user]
	,Total as totalCalls, Cin as callsIn
	,Cout as callsOut, C10 as [finishedCalls10], C20 as [finishedCalls20], C30 as [finishedCalls30], cal_whoHung as whoHung
	,isnull(avg_fCalc, 0) as callsAvgTime
	,datepart(yyyy,Snd.cal_Inicio) [year]
	,datepart(mm,Snd.cal_Inicio) [mounth]
	,datepart(dd,Snd.cal_Inicio) [day]
	,0 as [hour]
	,0 as [minute]
	from Snd
	inner join ccUserView Fst on Fst.User_id = Snd.User_id
	left join Trd on Trd.User_id=Snd.User_id and Trd.fecha_Dispo=Snd.cal_Inicio

end'
	EXEC(@sql)


	set @process = 'DEV1-339 Alter SP ccspRepAgentNotReadyDet para cuando se regenera se valida que no tenga datos repetidos if(@to = convert(datetime,convert(varchar(11),getdate(),121)+''03:00:00'',121)) AND @from = DATEADD(dd,-1,@to)'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentNotReadyDet] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

if(@to = convert(datetime,convert(varchar(11),getdate(),121)+''03:00:00'',121)) AND @from = DATEADD(dd,-1,@to)
BEGIN	
	select @from = convert(datetime,convert(varchar(11),@from))
END

IF @action = 1
BEGIN
	DELETE FROM RepAgentNotReadyDet	WHERE startDate >= @from AND startDate < @to;

	WITH notReadyDetail
	AS (
		SELECT user_id, DATEADD(s, - tstatus, fecha) AS fechaInicio, fecha, tStatus, separado, TipoNotReady_id		
		FROM ccLogAgentesNotReady
		WHERE fecha BETWEEN @from AND @to
		)
	
	INSERT INTO RepAgentNotReadyDet
	SELECT convert(DATE, fechaInicio, 121) [date], isNull(usr.[Login], ''systemTranslated_NoUserName'') AS [login], xdet.user_Id AS userId, isNull(usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno + '' '' + usr.Nombres, 
			''systemTranslated_NoName'') AS [user], xdet.TipoNotReady_id AS tiponotreadyId, isNull(tn.Descripcion, ''systemTranslated_NoStatus'') AS [status], fechaInicio AS startDate, fecha AS endDate, 
			convert(int,tStatus) AS 	statusTime, convert(int,tStatus) AS statusTimeSeconds, datepart(yyyy, fechaInicio) [year]
			, datepart(mm, fechaInicio) [mounth], datepart(dd, fechaInicio) [day], datepart(hh, fechaInicio) [hour], datepart(mi, fechaInicio) 	[minute]			
	FROM notReadyDetail xdet
	LEFT JOIN ccUserView usr ON usr.user_id = xdet.user_id
	LEFT JOIN ccTipoNotReady tn	ON tn.tipoNotready_id = xdet.tiponotready_id	
END'
	EXEC(@sql)


	set @process = 'DEV1-339  Update ReportAgentGI'
	set @sql = 'update GroupByReports set 
columns=''userId|max([user]):user|max([login]):login|sum([tlog]):tlog|sum([tunknown]):tunknown|sum([tav]):tav|sum([tnotav]):tnotav|sum([tother]):tother|sum([tprob]):tprob|sum([tChatting]):tChatting|sum([tManual]):tManual|sum([tundefined]):tundefined|sum([nxferin]):nxferin|sum([nanswerin]):nanswerin|sum([nabndxferin]):nabndxferin|sum([nabndringin]):nabndringin|sum([nabnddlgin]):nabnddlgin|sum([abndaxferin]):abndaxferin|sum([nnoanswerin]):nnoanswerin|sum([nlostin]):nlostin|sum([tdialogin]):tdialogin|sum([tnotesin]):tnotesin|sum([tringin]):tringin|sum([txferin]):txferin|sum([nxferout]):nxferout|sum([nanswerout]):nanswerout|sum([nabndxferout]):nabndxferout|sum([nabndringout]):nabndringout|sum([nabnddlgout]):nabnddlgout|sum([abndaxferout]):abndaxferout|sum([nnoanswerout]):nnoanswerout|sum([nlostout]):nlostout|sum([tdialogout]):tdialogout|sum([tnotesout]):tnotesout|sum([tringout]):tringout|sum([txferout]):txferout|sum([nother]):nother|sum([nmohin]):nmohin|sum([nmohout]):nmohout|sum([nwhagin]):nwhagin|sum([nwhagout]):nwhagout|sum([nwhcliin]):nwhcliin|sum([nwhcliout]):nwhcliout|isnull(sum([tdialogin]+[tdialogout])/nullif(sum([nanswerin]+[nanswerout])_0)_0):tnotavg''
 where id=2010'
	EXEC(@sql)

-----------------------------------------------------END Jesus Gallardo hotfix/125.20230719.0.2-----------------------------------------------------------------

-----------------------------------------------------BEGIN Enrique Ruiz hotfix/125.20230719.0.2-----------------------------------------------------------------

	set @process = 'DEV1-303, DEV1-332  Generación y Optimización Reportes XLSX y PDF, Se añade un Setting'
	set @sql = 'if not exists(select * from ccsettings where setting_id=44) begin
	insert into ccsettings values(44,''100000|1000000|2500000|10000|250000|2500000|44'',''Registros por worksheet|Registros por query XLSX|Registros por zip XLSZ|Registros por archivo PDF|Registros por query PDF|Registros por zip PDF'',1,''X'')
		end'

	EXEC(@sql)

-----------------------------------------------------END Enrique Ruiz hotfix/125.20230719.0.2-----------------------------------------------------------------


	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

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
