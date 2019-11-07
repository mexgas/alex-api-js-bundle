CREATE PROCEDURE [dbo].[ccspRepInEffectiveness]  
@action as tinyint,  
@from as datetime = null,  
@to as datetime = null  
AS  
  
set nocount on  
set ansi_nulls off   
set ANSI_WARNINGS off  
  
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
--Consulta de agentes conectados agrupados por hora e inboundid
		create table #RtnValue(
		IDWG int,
		Inbound_id int,
		extension varchar(100),
		user_id int,
		subLogin datetime,
		subLogout dateTime,
		sessionMinutes int,
		fechaInicio datetime,
		fechaFinal datetime
		)
		
		create nonclustered index ix_RtnValue on #RtnValue(
		[subLogin] DESC,
		[subLogout] DESC
		)

		create nonclustered index ix_RtnValue2 on #RtnValue(
		[subLogin] DESC,
		[subLogout] DESC
		)

		create table #RtnValue2(
		IDWG int,
		Inbound_id int,
		extension int,
		user_id int,
		subLogin datetime,
		subLogout dateTime,
		sessionMinutes int,
		fechaInicio datetime,
		fechaFinal datetime)

		create nonclustered index ix_RtnValue on #RtnValue2(
		[subLogin] DESC,
		[subLogout] DESC
		)
		declare @starttime datetime
		declare @number int
		set @starttime = @from
		select @number = 0

		CREATE TABLE #times(
		[ID] INT primary key,
		[Start] DATETIME,
		[Stop] DATETIME
		)

		create nonclustered index ix_times on #times(
		[Start] DESC,
		[Stop] DESC
		)
		create nonclustered index ix_times2 on #times(
		[Start] DESC
		)

		while @number <= (datediff(mi,@starttime,getdate())/60)
		begin
			insert into #times
			SELECT [Hour] = @number,
			StartTime = DATEADD(mi, @number*60, @starttime),
			EndTime = DATEADD(mi, (@number+1)*60, @StartTime)

			set @number = @number +1
		end


		insert into #RtnValue
		select x.IDWG,x.Inbound_id,x.Extension,x.User_id,x.subLogin,x.subLogout, DATEDIFF(mi,x.sublogin,x.sublogout) as sessionMinutes,null,null from (
		select d.IDWG, d.Inbound_id, a.extension, a.user_id, a.fecha as subLogin,
		(select isnull(max(Fecha),getdate()) from ccLogLogin b with(nolock)
		where b.user_id = a.user_id and b.tipomov = 0 and  b.fecha >= a.fecha and b.fecha <=
		( select isnull(min(fecha),'99991231 23:59:59.998') from ccLogLogin with(nolock)
		where user_id = b.user_id and tipomov = 1 and fecha > a.fecha)
		) as subLogout
		 from ccLogLogin a
		inner join ccinboundagentes d  on a.user_id = d.User_id
		where a.tipomov=1 and fecha >= @from and fecha <= @to
		)as x
						
		
		insert into #RtnValue2
		select x.IDWG,x.Inbound_id,x.Extension,x.User_id,x.subLogin,x.subLogout, x.sessionMinutes,th.Start,th.Stop
		from #RtnValue x
		join #times th on (x.subLogin > th.Start and x.subLogin < th.stop) OR th.Start between x.subLogin and x.subLogout
		

		create table #RtnValue3(
		cont int ,
		user_id int,
		Inbound_id int,
		fechaInicio datetime,
		fechaFinal datetime)
		
		insert into #RtnValue3
		select distinct 1,user_id,Inbound_id,fechaInicio,fechaFinal from #RtnValue2 order by fechaInicio,fechaFinal,Inbound_id	 

		create table #AgentsperInbound(
		NumberAgents int ,
		fechaInicio datetime,
		fechaFinal datetime,
		Inbound_id int)
		
		INSERT INTO #AgentsperInbound
		select sum(cont) as NumberAgents,fechaInicio,fechaFinal,Inbound_id from #RtnValue3 group by fechaInicio,fechaFinal,Inbound_id
		
		
--Fin consulta agentes conectados por inbound

CREATE TABLE [dbo].[#ccGenInCall](  
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
[nMoh] [smallint] NOT NULL DEFAULT ((0)),  
[nWHag] [smallint] NOT NULL DEFAULT ((0)),  
[nWHcl] [smallint] NOT NULL DEFAULT ((0))  
) ON [PRIMARY]  
  
CREATE TABLE [dbo].[#ccGenSession](  
[user_id] [smallint] NOT NULL,  
[login] [datetime] NOT NULL,  
[logout] [datetime] NOT NULL,  
[extension] [varchar](7) NOT NULL  
) ON [PRIMARY]  
  
CREATE TABLE [dbo].[#agents](  
[timegroup] [smalldatetime] NOT NULL,  
[user_id] [smallint] NOT NULL,  
[tlog] [int] NOT NULL DEFAULT (0),  
[treq] [int] NOT NULL DEFAULT (0),  
[tnot_av] [int] NOT NULL,  
[tav] [int] NOT NULL DEFAULT (0),  
[tprob] [int] NOT NULL DEFAULT (0),  
[tunknown] [int] NOT NULL DEFAULT (0),  
[tother] [int] NOT NULL DEFAULT (0),  
[nother] [int] NOT NULL DEFAULT (0),  
[nMoh] [int] NOT NULL DEFAULT ((0)),  
[nWHag] [int] NOT NULL DEFAULT ((0)),  
[nWHcl] [int] NOT NULL DEFAULT ((0))  
) ON [PRIMARY]    
  
CREATE TABLE [dbo].[#ccGenInSpec](  
[timegroup] [smalldatetime] NOT NULL,  
[inbound_id] [smallint] NOT NULL,  
[pos_tot] [smallint] NOT NULL,  
[pos_time] [int] NOT NULL,  
[pos_efect] [smallint] NOT NULL  
) ON [PRIMARY]  
  
CREATE TABLE [dbo].[#ccGenInAbnd](  
[timegroup] [smalldatetime] NOT NULL,  
[inbound_id] [smallint] NOT NULL,  
[amount] [smallint] NOT NULL,  
[time_max] [smallint] NOT NULL,  
[time_tot] [bigint] NOT NULL,  
[<10] [smallint] NOT NULL,  
[<20] [smallint] NOT NULL,  
[<30] [smallint] NOT NULL,  
[<40] [smallint] NOT NULL,  
[<50] [smallint] NOT NULL,  
[<60] [smallint] NOT NULL,  
[<120] [smallint] NOT NULL,  
[<180] [smallint] NOT NULL,  
[<240] [smallint] NOT NULL,  
[<300] [smallint] NOT NULL,  
[+300] [smallint] NOT NULL  
) ON [PRIMARY]  
  
INSERT INTO #ccGenInCall(timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque  
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
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121)AS timegroup,inbound_id,dni_id,[user_id]  
,COUNT(cal_id)AS ntotal  
,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial  
,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour   
,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service  
,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(isnull(cal_xfer,'') = '1900-01-01 00:00:00'))THEN 1 ELSE NULL END)AS abnd   
,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent  
,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que   
,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout  
,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow  
,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00'))THEN 1 ELSE NULL END)AS xfer  
,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00')))THEN cal_xfer ELSE NULL END)AS xfer_que  
,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00'))THEN 1 ELSE NULL END)AS abnd_xfer  
,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring  
,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer  
,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog  
,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer  
,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost  
,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg  
,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = '1900-01-01 00:00:00')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres  
,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres  
,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer  
,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring  
,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh  
,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl  
FROM ccCallsIn with (nolock, index(IX_ccCallsIn))  
WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0  
GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121),inbound_id,dni_id,[user_id])xDetailCount  
right JOIN(SELECT timegroup,inbound_id,dni_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer  
,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes  
FROM(SELECT timegroup,inbound_id,dni_id,[user_id]  
,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait  
,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer  
,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring  
,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog  
,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas  
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121)AS timegroup  
,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121)) AS timegroup_next  
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
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121)AS timegroup  
,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ ':00',121)) AS timegroup_next  
,DATEADD(ss,cal_twait,cal_inicio) AS time_endque  
,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring  
,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog  
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes  
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call  
,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail  
GROUP BY timegroup,inbound_id,dni_id,[user_id])xDetailTime  
ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id=xDetailCount.dni_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete  
WHERE timegroup>=@from AND timegroup<@to  
AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0  
AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0  
AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0  
AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)  
ORDER BY timegroup,inbound_id,dni_id,[user_id]  
  
INSERT INTO #ccGenSession ([user_id], extension, login, logout)  
SELECT uid, max(ext) ext, login, max(logout) logout  
FROM   
(SELECT uid, ext, login, ISNULL(logout, (SELECT MIN(fecha) FROM ccLogLogin /*with (nolock, index(ccLogLogin_fecha))*/  
WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout   
FROM  
 (SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout  
 FROM   
  (SELECT uid, ext, MAX(login) as login, logout  
  FROM  
   (SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha)   
   FROM ccLogLogin subLogin /*with (nolock, index(ccLogLogin_fecha))*/ WHERE subLogin.tipomov = 0   
   AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout]   
   FROM ccLogLogin Login /*with (nolock, index(ccLogLogin_fecha))*/  
   WHERE login.fecha >= dateadd(dd, -5, @from) and tipomov = 1  
   GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail   
  WHERE logout IS NOT NULL GROUP BY uid, ext, logout) Login   
 RIGHT OUTER JOIN ccLogLogin  /*with (nolock, index(ccLogLogin_fecha))*/  
 ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login AND ccLogLogin.extension = Login.ext)  
 WHERE tipomov = 1  
 and ccLogLogin.fecha >= dateadd( dd, -5, @from)) Det   
) LoginDetail   
WHERE logout IS NOT NULL  
AND login >= @from and login < @to  
GROUP BY uid, login  
  
INSERT INTO #agents(timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl)  
SELECT timegroup,[user_id],tlog,tnot_av  
,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav  
,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob  
,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown  
,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother  
,nother,nMoh,nWHag,nWHcl  
FROM(  
 SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother  
  ,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl  
  FROM(  
  SELECT   
   xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother  
   ,ISNULL(SUM(#ccGenInCall.txfer),0) as txfer  
   ,ISNULL(SUM(#ccGenInCall.tdialog),0) as tdialog  
   ,ISNULL(SUM(#ccGenInCall.tnotes),0) as tnotes  
   ,ISNULL(SUM(#ccGenInCall.tring),0) as tring  
   ,ISNULL(SUM(#ccGenInCall.nMoh),0) as nMoh  
   ,ISNULL(SUM(#ccGenInCall.nWHag),0) as nWHag  
   ,ISNULL(SUM(#ccGenInCall.nWHcl),0) as nWHcl  
  
   ,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)  
       FROM #ccGenSession  
       WHERE [user_id]=xTimeDetail.[user_id]  
       AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)  
    ),0)AS t1  
   ,ISNULL((SELECT top 1 3600  
       FROM #ccGenSession  
       WHERE [user_id]=xTimeDetail.[user_id]  
       AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)  
    ),0)AS t2  
   ,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))  
       FROM #ccGenSession  
       WHERE [user_id]=xTimeDetail.[user_id]  
       AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)  
    ),0)AS t3  
   ,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))  
       FROM #ccGenSession  
       WHERE [user_id]=xTimeDetail.[user_id]  
       AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)  
    ),0)AS t4  
  
   FROM(  
    SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ ':00',121)AS timegroup  
     ,ccLogAgentesDia.[user_id]  
     ,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown  
     ,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av  
     ,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav  
     ,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob  
     ,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother  
     ,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother  
     FROM ccLogAgentesDia  
     WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to  
     GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ ':00',121),ccLogAgentesDia.[user_id]  
   )xTimeDetail  
    LEFT OUTER JOIN #ccGenInCall ON(xTimeDetail.timegroup=#ccGenInCall.timegroup AND xTimeDetail.[user_id]=#ccGenInCall.[user_id])  
   GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown  
  )xDetail  
)xAllTimes  
WHERE tlog>0  
ORDER BY timegroup,[user_id]  
  
INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)  
SELECT timegroup, ccInboundAgentes.inbound_id  
 , COUNT(DISTINCT #agents.[user_id]) AS pos_max -- pos_tot  
 , SUM(tlog - (tnot_av + tprob + tother)) AS pos_time  
 , COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos  
 FROM #agents  
 INNER JOIN ccInboundAgentes ON (#agents.[user_id] = ccInboundAgentes.[user_id])  
 WHERE timegroup >= @from AND timegroup < @to  AND INBOUND_ID > 0  
 GROUP BY timegroup, ccInboundAgentes.inbound_id  
  
insert into #ccGenInAbnd (timegroup, inbound_id, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])  
SELECT timegroup  
, inbound_id  
, COUNT(cal_inicio) AS amount  
, MAX(tAbnd) AS time_max  
, SUM(tAbnd) AS time_tot  
, COUNT(CASE WHEN tAbnd < 10  THEN 1 ELSE NULL END) as [<10]  
, COUNT(CASE WHEN tAbnd BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [<20]  
, COUNT(CASE WHEN tAbnd BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [<30]  
, COUNT(CASE WHEN tAbnd BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [<40]  
, COUNT(CASE WHEN tAbnd BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [<50]  
, COUNT(CASE WHEN tAbnd BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [<60]  
, COUNT(CASE WHEN tAbnd BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [<120]  
, COUNT(CASE WHEN tAbnd BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [<180]  
, COUNT(CASE WHEN tAbnd BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [<240]  
, COUNT(CASE WHEN tAbnd BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [<300]  
, COUNT(CASE WHEN tAbnd >= 300  THEN 1 ELSE NULL END) as [+300]  
FROM (  
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + ':00', 121) AS timegroup  
 , cal_inicio  
 , inbound_id  
 , statuscall_id  
 , (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,'') = '1900-01-01 00:00:00'))  THEN 1 ELSE NULL END) AS abnd   
 , (cal_twait + cal_txfer + cal_tring) AS tAbnd  
 FROM ccCallsIn  
 WHERE cal_inicio >= @from AND  cal_inicio < @to  
 AND INBOUND_ID > 0  
) xCalls  
WHERE (abnd IS NOT NULL)   
GROUP BY timegroup, inbound_id  
  
--Borrar lo que esta para no repetir  
delete from RepInEffectiveness with(rowlock)  
where date >= @from AND date < @to  
  
insert into RepInEffectiveness  
SELECT timegroup as date, xDetail.inbound_id, isnull(descripcion, 'systemTranslated_NoACDGroup') descripcion , ntotal, nanswer, nabnd , isnull(tatention / nullif(nanswer,0),0),   
tque_avg as tqueavg, tQue_tot as tQuetot, nQue_tot as nQuetot, isnull(tabnd_tot / NULLIF(nabnd,0),0) as avgAbandonTime, SL_P_1 as SLP1, SL_P_2 as SLP2, tresp,   
/*pos_tot as postot,*/ pos_count as poscount, ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0)  as Porcentaje  
, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]  
, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]  
, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]  
, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]  
, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]   
, convert(decimal(10,2),(nabnd/nullif(convert(decimal(10,2),ntotal),0))*100) as [avgAbandon]  
, tabnd_tot as tabndtot  
FROM (   
  
SELECT ISNULL(xDetCall.timegroup, ISNULL(xDetSpec.timegroup, xDetAbnd.timegroup)) timegroup, ISNULL(xDetCall.inbound_id,   
ISNULL(xDetSpec.inbound_id, xDetAbnd.inbound_id)) inbound_id, ISNULL(ntotal, 0) ntotal, ISNULL(nanswer, 0) nanswer, ISNULL(nabnd, 0) nabnd,   
ISNULL(tatention, 0) tatention, ISNULL(tque_avg, 0) tque_avg, isnull(tQue_tot, 0) tQue_tot, isnull(nQue_tot, 0) nQue_tot, ISNULL(tabnd_tot, 0) tabnd_tot,   
ISNULL(SL_P_1, 0) SL_P_1, ISNULL(SL_P_2, 0) SL_P_2, ISNULL(tresp, 0) tresp, ISNULL(pos_tot, 0) pos_tot, ISNULL(pos_count, 0) pos_count  
  
FROM (  
  
SELECT timegroup, inbound_id, SUM(ntotal) AS ntotal, SUM(nanswer) AS nanswer, SUM(nabnd) AS nabnd, SUM(tdialog + tnotes) tatention,   
ISNULL(sum(tque)/ NULLIF(sum(nque), 0), 0) AS tque_avg, sum(tque) as tQue_tot, sum(nQue) as nQue_tot, SUM(nansw_tres + nabnd_tres) AS SL_P_1,   
SUM(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, SUM(tresp) AS tresp  
FROM #ccGenInCall    
WHERE timegroup >= @from  
AND timegroup < @to   
GROUP BY timegroup , inbound_id) xDetCall    
LEFT JOIN (  
SELECT timegroup, inbound_id, SUM(pos_tot) AS pos_tot, SUM(pos_tot) AS pos_avg, SUM(pos_efect) AS pos_efect, COUNT(pos_tot) AS pos_count    
FROM #ccGenInSpec   
WHERE timegroup >= @from  
AND timegroup < @to   
GROUP BY timegroup , inbound_id) xDetSpec   
ON (xDetCall.timegroup = xDetSpec.timegroup AND xDetCall.inbound_id = xDetSpec.inbound_id)    
LEFT JOIN (  
SELECT timegroup, inbound_id, SUM(time_tot) AS tabnd_tot     
FROM #ccGenInAbnd    
WHERE timegroup >= @from   
AND timegroup < @to   
GROUP BY timegroup , inbound_id) xDetAbnd   
ON (xDetCall.timegroup = xDetAbnd.timegroup AND xDetCall.inbound_id = xDetAbnd.inbound_id)   
) xDetail    
LEFT JOIN ccInbound ON (xDetail.inbound_id=ccInbound.inbound_id)    
ORDER BY date  
--Update numero de agentes del reporte de efectividad por hora e inbound_Id
update RepInEffectiveness set poscount = ISNULL((select NumberAgents from #AgentsperInbound where fechaInicio = [dbo].[RepInEffectiveness].date and Inbound_Id=[dbo].[RepInEffectiveness].inboundId),0)

drop table #ccGenInCall  
drop table #ccGenInSpec  
drop table #ccGenSession  
drop table #agents  
drop table #ccGenInAbnd  
drop table #times
drop table #RtnValue
drop table #RtnValue2
drop table #RtnValue3
drop table #AgentsperInbound
end