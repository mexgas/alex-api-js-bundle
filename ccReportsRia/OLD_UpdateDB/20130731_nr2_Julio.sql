/*
Autor: Raymundo Gonzalez
Fecha: 2013/07/31
Descripcion: 
	Se modifica el SP ccspRepAgentGI para calculo de tiempos de sesion
	Se modifica el SP ccspRepAgentSession para cambio en reporte
	
Version requerida: 1
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '2'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------
		
		set @process = 'ccspRepAgentGI - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccspRepAgentGI] 
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS off
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

if @action = 1
begin
	delete from RepAgentGI where date >= @from AND date < @to

	-- Session Time
	select [user_id], [login], logout, extension
	into #sessionTime
	from(select a.extension, a.user_id, a.fecha as ''login'',
	(select isnull(max(Fecha),getdate())
	 from ccLogLogin b with(nolock)
	 where b.user_id = a.user_id and
	 b.tipomov = 0 and
	 b.fecha >= a.fecha and
	 b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
		from ccLogLogin with(nolock)
		where user_id = b.user_id and
		tipomov = 1 and
		fecha > a.fecha)) as ''logout''
	from ccLogLogin a
	where a.tipomov=1
	and fecha >= @from
	and fecha <= @to) as sessiontime
	order by user_id, login

	SELECT TOP 0 * INTO #temp_RepAgentSession FROM #sessionTime

	INSERT INTO #temp_RepAgentSession
	select sessiontime.user_id, sublogin, sublogout, extension
	from(select a.extension, a.user_id, a.fecha as ''subLogout'',
	(select isnull(max(Fecha),getdate())
	 from ccLogLogin b with(nolock)
	 where b.user_id = a.user_id and
	 b.tipomov = 1 and
	 b.fecha <= a.fecha and
	 b.fecha >= (select isnull(max(fecha),b.fecha)
		from ccLogLogin with(nolock)
		where user_id = b.user_id and
		tipomov = 0 and
		fecha < a.fecha)
	) as ''subLogin''
	from ccLogLogin a
	where a.tipomov=0
	and fecha >= @from
	and fecha <= @to
	) as sessiontime
	left join ccusers u on (sessiontime.user_id = u.user_id)
	where datediff(day,subLogin,subLogout) >= 1
	order by sessiontime.user_id, sublogin

	UPDATE a with (rowlock)
	SET a.logout = b.logout
	FROM #temp_RepAgentSession b
	INNER JOIN #sessionTime a
	on a.user_Id = b.user_Id
	and a.login = b.login
	and a.logout <> b.logout

	DROP TABLE #temp_RepAgentSession
	
	-- Inbound Data
	SELECT timegroup,inbound_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
	,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
	,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
	into #inboundData
	FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
		,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
		,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
		,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
		,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
		,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
		,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
		,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
	FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,[user_id]
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
	GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,[user_id])xDetailCount
	right JOIN(SELECT timegroup,inbound_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
		,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
	FROM(SELECT timegroup,inbound_id,[user_id]
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
	SELECT timegroup_next,inbound_id,[user_id]
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
	GROUP BY timegroup,inbound_id,[user_id])xDetailTime
	ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
	WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
	AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
	AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
	AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
	ORDER BY timegroup,inbound_id,[user_id]

	--Outbound Data
	SELECT timegroup,cam_id,[user_id],ntotal
	,nno_agent,nxfer
	,nabnd_xfer,nabnd_ring,nno_answer
	,nabnd_dialog,nanswer,nlost
	,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
	into #outboundData
	FROM(		
		SELECT xDetailTime.timegroup,xDetailTime.cam_id,xDetailTime.[user_id]
			,ISNULL(ntotal,0)AS ntotal
			,ISNULL(no_agent,0)AS nno_agent,ISNULL(xfer,0)AS nxfer
			,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost
			,xDetailTime.txfer,xDetailTime.tring
			,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp
			,ISNULL(hung_up,0)AS nhangup,ISNULL(nMoh,0) as nMoh,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		 FROM(	 
				SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
					,cam_id
					,[user_id]
					,COUNT(cal_id)AS ntotal
					,COUNT(CASE WHEN(statuscall_id=6)THEN cal_id ELSE NULL END)AS hung_up --Ne se usa,as que es igual a total para las llamadas sin agente asignada(->agente 0)
					,COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END)AS no_agent
					,COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END)AS xfer
					--,COUNT(CASE WHEN(statuscall_id in(11,15,13,16))THEN 1 ELSE NULL END)AS xfer
					,COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END)AS abnd_xfer
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END)AS abnd_ring
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END)AS no_answer
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END)AS abnd_dialog
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END)AS answer
					,COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END)AS lost
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
					,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
				 FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
					-- para contar bien las llamadas manuales
					and cal_manual in(0,2)
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),cam_id,[user_id]
			)xDetailCount
			--RIGHT OUTER JOIN 
			LEFT JOIN
			(
				SELECT timegroup
					,cam_id
					,[user_id]
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(cal_tring),0)AS tring
					,ISNULL(SUM(cal_tdialog),0)AS tdialog
					,ISNULL(SUM(cal_tnotas),0)AS tnotes
				 FROM(	SELECT timegroup,cam_id,[user_id]
						,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call								,*
							FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							-- para contar bien las llamadas manuales
							and cal_manual in(0,2)
						)xDetail
					UNION
					SELECT timegroup_next,cam_id,[user_id]
						,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 AS time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
								,*
							FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							-- para contar bien las llamadas manuales
							and cal_manual in(0,2)
						)xDetail
					)xTimeDetail
				 GROUP BY timegroup,cam_id,[user_id]
			)xDetailTime
			ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.cam_id=xDetailCount.cam_id AND xDetailTime.[user_id]=xDetailCount.[user_id])
	)xComplete
	WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nno_agent=0
		 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		 AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
	ORDER BY timegroup,cam_id,[user_id]

		-- Agent Information
	SELECT timegroup,[user_id],tlog, 0 as treq, tnot_av
	--,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav
	--,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob
	--,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown
	--,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother
	,tav
	,tprob
	,tunknown
	,tother
	,nother,nMoh,nWHag,nWHcl
	into #agentInformation
 FROM(
		SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
			,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl
		 FROM(
			SELECT 
				xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
				,ISNULL(SUM(#inboundData.txfer),0)+ ISNULL(SUM(#outboundData.txfer),0)as txfer
				,ISNULL(SUM(#inboundData.tdialog),0)+ ISNULL(SUM(#outboundData.tdialog),0)as tdialog
				,ISNULL(SUM(#inboundData.tnotes),0)+ ISNULL(SUM(#outboundData.tnotes),0)as tnotes
				,ISNULL(SUM(#inboundData.tring),0)+ ISNULL(SUM(#outboundData.tring),0)as tring
				,ISNULL(SUM(#inboundData.nMoh),0)+ ISNULL(SUM(#outboundData.nMoh),0)as nMoh
				,ISNULL(SUM(#inboundData.nWHag),0)+ ISNULL(SUM(#outboundData.nWHag),0)as nWHag
				,ISNULL(SUM(#inboundData.nWHcl),0)+ ISNULL(SUM(#outboundData.nWHcl),0)as nWHcl
		
				,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t1
				,ISNULL((SELECT top 1 3600
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t2
				,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t3
				,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t4
			
			 FROM(
					SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup
						,ccLogAgentesDia.[user_id]
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother
						,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
					 FROM ccLogAgentesDia
					 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
					 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
				)xTimeDetail
					LEFT OUTER JOIN #inboundData ON(xTimeDetail.timegroup=#inboundData.timegroup AND xTimeDetail.[user_id]=#inboundData.[user_id])
					LEFT OUTER JOIN #outboundData ON(xTimeDetail.timegroup=#outboundData.timegroup AND xTimeDetail.[user_id]=#outboundData.[user_id])
				GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		 	)xDetail
	)xAllTimes
 WHERE tlog>0
 ORDER BY timegroup,[user_id]

SELECT CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121) AS timegroup
		, [user_id],SUM(tStatus) as [timeNotReady]
	 into #notReady
		 FROM ccLogAgentesNotReady
		 WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to
		 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121), [user_id]

INSERT INTO RepAgentGI
	SELECT     
	CASE WHEN #agentInformation.timegroup IS NOT NULL THEN #agentInformation.timegroup WHEN #inboundData.timegroup IS NOT NULL 
	  THEN #inboundData.timegroup WHEN #outboundData.timegroup IS NOT NULL THEN #outboundData.timegroup ELSE 0 END AS date, 
	  CASE WHEN #agentInformation.user_id IS NOT NULL THEN #agentInformation.user_id WHEN #inboundData.user_id IS NOT NULL 
	  THEN #inboundData.user_id WHEN #outboundData.user_id IS NOT NULL THEN #outboundData.user_id ELSE - 1 END AS user_id,
	  u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + nombres as [user] , u.login as [login],
	  ISNULL(dbo.#inboundData.nxfer, 0) AS nxfer_in, ISNULL(dbo.#inboundData.nanswer, 0) AS nanswer_in, ISNULL(dbo.#inboundData.nabnd_xfer, 0) 
	  AS nabnd_xfer_in, ISNULL(dbo.#inboundData.nabnd_ring, 0) AS nabnd_ring_in, ISNULL(dbo.#inboundData.nabnd_dialog, 0) AS nabnd_dlg_in, 
	  ISNULL(dbo.#inboundData.nabnd_xfer, 0) + ISNULL(dbo.#inboundData.nabnd_ring, 0) + ISNULL(dbo.#inboundData.nabnd_dialog, 0) AS abnd_a_xfer_in, 
	  ISNULL(dbo.#inboundData.nno_answer, 0) AS nno_answer_in, ISNULL(dbo.#inboundData.nlost, 0) AS nlost_in, ISNULL(dbo.#inboundData.tdialog, 0) 
	  AS tdialog_in, ISNULL(dbo.#inboundData.tnotes, 0) AS tnotes_in, ISNULL(dbo.#inboundData.tring, 0) AS tring_in, ISNULL(dbo.#inboundData.txfer, 0) AS txfer_in, 
	  ISNULL(dbo.#outboundData.nxfer, 0) AS nxfer_out, ISNULL(dbo.#outboundData.nanswer, 0) AS nanswer_out, ISNULL(dbo.#outboundData.nabnd_xfer, 0) 
	  AS nabnd_xfer_out, ISNULL(dbo.#outboundData.nabnd_ring, 0) AS nabnd_ring_out, ISNULL(dbo.#outboundData.nabnd_dialog, 0) AS nabnd_dlg_out, 
	  ISNULL(dbo.#outboundData.nabnd_xfer, 0) + ISNULL(dbo.#outboundData.nabnd_ring, 0) + ISNULL(dbo.#outboundData.nabnd_dialog, 0) AS abnd_a_xfer_out, 
	  ISNULL(dbo.#outboundData.nno_answer, 0) AS nno_answer_out, ISNULL(dbo.#outboundData.nlost, 0) AS nlost_out, ISNULL(dbo.#outboundData.tdialog, 0) 
	  AS tdialog_out, ISNULL(dbo.#outboundData.tnotes, 0) AS tnotes_out, ISNULL(dbo.#outboundData.tring, 0) AS tring_out, ISNULL(dbo.#outboundData.txfer, 0) 
	  AS txfer_out, ISNULL(dbo.#agentInformation.nother, 0) AS nother, ISNULL(dbo.#agentInformation.tunknown, 0) AS tunknown, ISNULL(dbo.#agentInformation.tnot_av, 0) AS tnot_av, 
	  ISNULL(dbo.#agentInformation.tlog, 0) AS tlog
	  ,ISNULL(dbo.#notReady.timeNotReady, 0) AS treq --  ,0 as treq	
	, ISNULL(dbo.#agentInformation.tav, 0) AS tav, ISNULL(dbo.#agentInformation.tother, 0) AS tother, 
	  ISNULL(dbo.#agentInformation.tprob, 0) AS tprob, ISNULL(dbo.#inboundData.nMoh, 0) AS nMoh_in, ISNULL(dbo.#outboundData.nMoh, 0) AS nMoh_out, 
	  ISNULL(dbo.#inboundData.nWHag, 0) AS nWHag_in, ISNULL(dbo.#outboundData.nWHag, 0) AS nWHag_out, ISNULL(dbo.#inboundData.nWHcl, 0) 
	  AS nWHcl_in, ISNULL(dbo.#outboundData.nWHcl, 0) AS nWHcl_out
	  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(yy,#agentInformation.timegroup) WHEN #inboundData.timegroup IS NOT NULL 
	  THEN datepart(yy,#inboundData.timegroup) WHEN #outboundData.timegroup IS NOT NULL THEN datepart(yy,#outboundData.timegroup) ELSE 0 END AS [year]
	  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(mm,#agentInformation.timegroup) WHEN #inboundData.timegroup IS NOT NULL 
	  THEN datepart(mm,#inboundData.timegroup) WHEN #outboundData.timegroup IS NOT NULL THEN datepart(mm,#outboundData.timegroup) ELSE 0 END AS [month]
	  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(dd,#agentInformation.timegroup) WHEN #inboundData.timegroup IS NOT NULL 
	  THEN datepart(dd,#inboundData.timegroup) WHEN #outboundData.timegroup IS NOT NULL THEN datepart(dd,#outboundData.timegroup) ELSE 0 END AS [day]
	  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(hh,#agentInformation.timegroup) WHEN #inboundData.timegroup IS NOT NULL 
	  THEN datepart(hh,#inboundData.timegroup) WHEN #outboundData.timegroup IS NOT NULL THEN datepart(hh,#outboundData.timegroup) ELSE 0 END AS [hour]
	  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(mi,#agentInformation.timegroup) WHEN #inboundData.timegroup IS NOT NULL 
	  THEN datepart(mi,#inboundData.timegroup) WHEN #outboundData.timegroup IS NOT NULL THEN datepart(mi,#outboundData.timegroup) ELSE 0 END AS [minutes]
FROM  dbo.#agentInformation FULL OUTER JOIN
      dbo.#inboundData ON dbo.#inboundData.timegroup = dbo.#agentInformation.timegroup AND dbo.#inboundData.user_id = dbo.#agentInformation.user_id 
	  FULL OUTER JOIN
      dbo.#outboundData ON dbo.#outboundData.timegroup = dbo.#agentInformation.timegroup AND dbo.#outboundData.user_id = dbo.#agentInformation.user_id 
	  LEFT OUTER JOIN
	  dbo.ccusers u ON (#agentInformation.[user_id] = u.[user_id])
	  LEFT OUTER JOIN dbo.#notReady ON #agentInformation.[user_id] = dbo.#notReady.[user_id] AND dbo.#notReady.timegroup = dbo.#agentInformation.timegroup 
WHERE #agentInformation.[user_id] IS NOT NULL


drop table #sessionTime
drop table #inboundData
drop table #outboundData
drop table #agentInformation
drop table #notReady

end'
		
	EXEC(@Sql)

		set @process = 'ccspRepAgentSession - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccspRepAgentSession]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
if @from is null
 select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
   delete from RepAgentSession with(rowlock)
   where date >= @from and date < @to

   insert into RepAgentSession
   select subLogin as date, u.login as userLogin, sessiontime.user_id, 
   u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + u.nombres as [user], extension, subLogin as loginTime, 
   subLogout as logoutTime,
   datediff(ss,subLogin,subLogout) as sessionTime, 
   datediff(ss,subLogin,subLogout) as sessionTimeSeconds,
   datepart(yyyy,subLogin), datepart(mm,subLogin), datepart(dd,subLogin), 
   datepart(hh,subLogin), datepart(mi,subLogin) 
   from(select a.extension, a.user_id, a.fecha as ''subLogin'',
    (select isnull(max(Fecha),getdate())
     from ccLogLogin b with(nolock)
     where b.user_id = a.user_id and
     b.tipomov = 0 and
     b.fecha >= a.fecha and
     b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
        from ccLogLogin with(nolock)
        where user_id = b.user_id and
        tipomov = 1 and
        fecha > a.fecha)
    ) as ''subLogout''
    from ccLogLogin a
    where a.tipomov=1
    and fecha >= @from
    and fecha <= @to
   ) as sessiontime
   left join ccusers u on (sessiontime.user_id = u.user_id)
  order by user_id, loginTime
  
  SELECT TOP 0 * INTO #temp_RepAgentSession FROM RepAgentSession

  INSERT INTO #temp_RepAgentSession
  select subLogin as date, u.login as userLogin, sessiontime.user_id, 
  u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + u.nombres as [user], extension, subLogin as loginTime, 
  subLogout as logoutTime,
  datediff(ss,subLogin,subLogout) as sessionTime, 
  datediff(ss,subLogin,subLogout) as sessionTimeSeconds,
  datepart(yyyy,subLogin), datepart(mm,subLogin), datepart(dd,subLogin), 
  datepart(hh,subLogin), datepart(mi,subLogin)
  from(select a.extension, a.user_id, a.fecha as ''subLogout'',
    (select isnull(max(Fecha),getdate())
     from ccLogLogin b with(nolock)
     where b.user_id = a.user_id and
     b.tipomov = 1 and
     b.fecha <= a.fecha and
     b.fecha >= (select isnull(max(fecha),b.fecha)
        from ccLogLogin with(nolock)
        where user_id = b.user_id and
        tipomov = 0 and
        fecha < a.fecha)
    ) as ''subLogin''
    from ccLogLogin a
    where a.tipomov=0
    and fecha >= @from
    and fecha <= @to
   ) as sessiontime
   left join ccusers u on (sessiontime.user_id = u.user_id)
   where datediff(day,subLogin,subLogout) >= 1
  order by user_id, loginTime
  
  UPDATE a with (rowlock)
  SET a.logoutTime = b.logoutTime,
  a.sessionTime = b.sessionTime,
  a.sessionTimeSeconds = b.sessionTimeSeconds
  FROM #temp_RepAgentSession b
  INNER JOIN RepAgentSession a
  on a.userId = b.userId
  and a.loginTime = b.loginTime
  and a.logoutTime <> b.logoutTime
  
  DROP TABLE #temp_RepAgentSession
  
end'
		
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
