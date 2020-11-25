CREATE PROCEDURE [dbo].[ccspRepAgentGI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS off
SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to =getdate()

if @action=1 begin


	IF OBJECT_ID('tempdb..#inboundData') IS NOT NULL drop table #inboundData
	IF OBJECT_ID('tempdb..#inboundData2') IS NOT NULL drop table #inboundData2
	IF OBJECT_ID('tempdb..#outboundData') IS NOT NULL drop table #outboundData
	IF OBJECT_ID('tempdb..#outboundData2') IS NOT NULL drop table #outboundData2
	IF OBJECT_ID('tempdb..#timeDetailAgent') IS NOT NULL drop table #timeDetailAgent
	IF OBJECT_ID('tempdb..#timeDetailAgent2') IS NOT NULL drop table #timeDetailAgent2
	IF OBJECT_ID('tempdb..#agentInformation') IS NOT NULL drop table #agentInformation
	IF OBJECT_ID('tempdb..#tempRepAgentGI') IS NOT NULL drop table #tempRepAgentGI

	IF OBJECT_ID('tempdb..#tempAgentLastStatus') IS NOT NULL drop table #tempAgentLastStatus
	IF OBJECT_ID('tempdb..#tempccLogAgentesDia') IS NOT NULL drop table #tempccLogAgentesDia
	IF OBJECT_ID('tempdb..#tempccLogAgentesDia2') IS NOT NULL drop table #tempccLogAgentesDia2
	IF OBJECT_ID('tempdb..#sessionTimeGroup') IS NOT NULL drop table #sessionTimeGroup

	declare @interval int
	declare @dateNow datetime,@maxLogout datetime
	DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
	SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
	DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

	EXEC @tresRing=ccspConfigTresRing
	EXEC @tresDialog=ccspConfigTresDialog
	EXEC @tresDelayIn=ccspConfigtresDelayIn

	set @dateNow=getdate()
	set @interval=15

	create table #inboundData(
	[row] int identity primary key,Inbound_id int,[User_id] int,phone_in varchar(30),cal_id int,dni_id int,
	dateStartDetail datetime,dateEndDetail datetime,timegroup datetime,timegroup_next datetime,
	time_endque datetime,time_ring datetime,time_dialog datetime,time_notes datetime,
	time_end_call datetime,ntotal int,ninitial int,nout_hour int,nout_service int,nabnd int,
	nno_agent int,nque int,ntimeout int,noverflow int,nxfer int,nxfer_que int,
	nabnd_xfer int,nabnd_ring int,nno_answer int,nabnd_dialog int,nanswer int,nlost int,
	nmsg int,nabnd_tres int,nansw_tres int,tque_max int,tque int,txfer int,tdialog int,
	tnotes int,tring int,tresp int,nMoh int,nWHag int,nWHcl int)

	create nonclustered index iX_InboundUserId on #inboundData([Inbound_id] DESC,[User_id] DESC)

	create table #outboundData(
	row int identity,cam_id int,[User_id] int,cal_id int,cal_puerto int,phone_out varchar(30),
	dateStartDetail datetime,dateEndDetail datetime,timegroup datetime,timegroup_next datetime,
	ntotal int,nno_agent int,nxfer int,nabnd_xfer int,nabnd_ring int,nno_answer int,nabnd_dialog int,nanswer int,
	nlost int,tque int,txfer int,tring int,tdialog int,tnotes int,tresp int,nhangup int,
	nMoh int,nWHag int,nWHcl int,time_endque datetime,time_ring datetime,time_dialog datetime,
	time_notes datetime,time_end_call datetime)

	create nonclustered index iX_CamUserId on #outboundData([cam_id] DESC,[User_id] DESC)	
	create table #timeDetailAgent([User_id] int null,dateStartDetail datetime null,dateEndDetail datetime null,timegroup datetime null,	timegroup_next datetime null,tunknown int null,tnot_av int null,tav int null,tprob int null,tother int null,nother int null,tmanualcall int null,tunknown2 decimal(10,3),tchatting int null)

	--Tiempo ultimo Status del agente
	create table #tempAgentLastStatus(id int,fecha datetime,tiempo int)

	--
	
	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)	

	--TIempos del agente
	create table #tempccLogAgentesDia(row int not null,user_id int not null,TipoStatusAge_id tinyint not null,tStatus int not null,dateIni datetime not null,dateEnd datetime not null,currentStatus int)
	
	select @maxLogout=max(logout) from TmpSessionTimeGroup

	if CONVERT(varchar(11),@maxLogout,121)=CONVERT(varchar(11),@dateNow,121) and @dateNow>@maxLogout set @dateNow=@maxLogout


	INSERT INTO #sessionTimeGroup
	select 
	 user_id,login,logout,extension
	 ,timegroup,timegroup_next,tlog
	from TmpSessionTimeGroup

	--inserto ultimo tiempo del agente del dia
	insert into #tempAgentLastStatus
	select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),@dateNow) from ccLogAgentesDia where convert(varchar(11),fecha,121)=CONVERT(varchar(11),@dateNow,121) group by User_id


	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service
	,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl
	)
	select * from (
	SELECT case when cal_Xfer is null or cal_Xfer ='1900-01-01 00:00:00' then cal_inicio else cal_Xfer end as dateStartDetail,
		   dateadd(ss,0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,
			case when cal_Xfer is null or cal_Xfer ='1900-01-01 00:00:00' then cal_inicio else cal_Xfer end )
			dateEndDetail
			,dbo.GetTimeGroup(case when cal_Xfer is null or cal_Xfer ='1900-01-01 00:00:00' then cal_inicio else cal_Xfer end,0) as timegroup	   
			,dbo.GetTimeGroup(dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer ='1900-01-01 00:00:00' then cal_inicio else cal_Xfer end )
			,1) as timegroup_next
		   ,case when cal_Xfer is null or cal_Xfer ='1900-01-01 00:00:00' then cal_inicio else cal_Xfer end as time_endque		   
		   ,DATEADD(ss,isnull(cal_txfer,0),case when cal_Xfer is null or cal_Xfer ='1900-01-01 00:00:00' then cal_inicio else cal_Xfer end ) as time_ring
		   ,DATEADD(ss,isnull(cal_txfer + cal_tring,0),case when cal_Xfer is null or cal_Xfer ='1900-01-01 00:00:00' then cal_inicio else cal_Xfer end ) as time_dialog
		   ,DATEADD(ss,isnull(cal_txfer + cal_tring + cal_tdialog,0),case when cal_Xfer is null or cal_Xfer ='1900-01-01 00:00:00' then cal_inicio else cal_Xfer end ) as time_notes
		   ,DATEADD(ss,isnull(cal_txfer + cal_tring + cal_tdialog + cal_tnotas,0),case when cal_Xfer is null or cal_Xfer ='1900-01-01 00:00:00' then cal_inicio else cal_Xfer end ) as time_end_call
		   ,cal_Ani as phone_in,cal_id,dni_id,Inbound_id,[User_id]
		   ,1 AS ntotal
		   ,ISNULL((CASE WHEN statuscall_id=1 THEN 1 ELSE 0 END),0) AS ninitial
		   ,ISNULL((CASE WHEN statuscall_id=2 THEN 1 ELSE 0 END),0) AS nout_hour
		   ,ISNULL((CASE WHEN statuscall_id=3 THEN 1 ELSE 0 END),0) AS nout_service
		   ,ISNULL((CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = '1900-01-01 00:00:00'))THEN 1 ELSE 0 END),0) AS nabnd
		   ,ISNULL((CASE WHEN(statuscall_id=4)THEN 1 ELSE 0 END),0) AS nno_agent
		   ,ISNULL((CASE WHEN(cal_que>0)THEN 1 ELSE 0 END),0) AS nque
		   ,ISNULL((CASE WHEN(statuscall_id=7)THEN 1 ELSE 0 END),0) AS ntimeout
		   ,ISNULL((CASE WHEN(statuscall_id=8)THEN 1 ELSE 0 END),0) AS noverflow
		   ,ISNULL((CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00'))THEN 1 ELSE 0 END),0) AS nxfer
		   ,ISNULL((CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00')))THEN 1 ELSE 0 END),0) AS nxfer_que
		   ,ISNULL((CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00'))THEN 1 ELSE 0 END),0) AS nabnd_xfer
		   ,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE 0 END),0) AS nabnd_ring
		   ,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE 0 END),0) AS nno_answer
		   ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE 0 END),0) AS nabnd_dialog
		   ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE 0 END),0) AS nanswer
		   ,ISNULL((CASE WHEN(statuscall_id=16)THEN 1 ELSE 0 END),0) AS nlost
		   ,ISNULL((CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE 0 END),0) AS nmsg
		   ,ISNULL((CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = '1900-01-01 00:00:00')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE 0 END),0) AS nabnd_tres
		   ,ISNULL((CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE 0 END),0) AS nansw_tres
		   ,cal_twait AS tque_max, cal_twait as tque, cal_txfer AS txfer
		   ,ISNULL((cal_tdialog),0)AS tdialog,ISNULL((cal_tnotas),0)AS tnotes,ISNULL((cal_tring),0)AS tring
		   ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE 0 END),0)AS tresp
		   ,ISNULL((case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
		   ,ISNULL((CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL((CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
		   FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		   WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
		   )inboundData
		   where not(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
		   AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
		   AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
		   AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)

	update C
	set C.dateEndDetail=@dateNow
	,C.timegroup_next= dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1 ) 
	,C.time_dialog= case when A.currentStatus in (4,5,9) then @dateNow when A.TipoStatusAge_id=4 then B.fecha else C.dateStartDetail end
	,C.time_notes=@dateNow
	,C.time_end_call=@dateNow
	,C.tdialog= case when A.currentStatus in (4,5,9) then B.tiempo when A.TipoStatusAge_id=4 then DATEDIFF(ss,C.dateStartDetail,B.fecha) else 0 end
	,C.tnotes= case when A.currentStatus = 6 then B.tiempo else 0 end
	from ccLogAgentesDia A
	inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id=B.id
	inner join #inboundData C on A.callID=C.cal_id
	WHERE currentStatus in (4,5,6,9) and A.Tipo=0

	select * into #inboundData2 from #inboundData where datediff(mi,timegroup,timegroup_next)>15
	delete #inboundData where datediff(mi,timegroup,timegroup_next) > 15

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	select dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next
	,time_endque,time_ring,time_dialog,time_notes,time_end_call
	,phone_in,cal_id,dni_id,Inbound_id,[User_id]
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ninitial else 0 end as ninitial
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_hour else 0 end as nout_hour
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_service else 0 end as nout_service
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd else 0 end as nabnd
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nque else 0 end as nque
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntimeout else 0 end as ntimeout
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then noverflow else 0 end as noverflow
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer_que else 0 end as nxfer_que
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nmsg else 0 end as nmsg
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_tres else 0 end as nabnd_tres
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nansw_tres else 0 end as nansw_tres
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tque_max else 0 end as tque_max
	 ,dbo.TimeInterval(th.start,th.stop,dateStartDetail,time_endque)  as tque	
	 ,dbo.TimeInterval(th.start,th.stop,time_endque,time_ring)  as txfer	     
	 ,dbo.TimeInterval(th.start,th.stop,time_dialog,time_notes)  as tdialog
	 ,dbo.TimeInterval(th.start,th.stop,time_notes,time_end_call)  as tnotes
	 ,dbo.TimeInterval(th.start,th.stop,time_ring,time_dialog)  as tring
	 ,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tresp,dateStartDetail))  as tresp	
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
	from #inboundData2 t
	join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	and th.Start between @from and @to
	order by cal_id

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto)
	select * from (
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		   ,dbo.GetTimeGroup(cal_inicio,0 ) as timegroup
		   ,dbo.GetTimeGroup(dateadd(ss,isnull(sum(cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),0 )  as timegroup_next
		   ,cam_id, [User_id]
		   ,COUNT(cal_id) AS ntotal
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END),0) AS nno_agent
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END),0) AS nxfer
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END),0) AS nabnd_xfer
		   ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END),0) AS nabnd_ring
		   ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END),0) AS nno_answer
		   ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END),0) AS nabnd_dialog
		   ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END),0) AS nanswer
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END),0) AS nlost
		   ,ISNULL(SUM(cal_twait),0) as tque
		   ,ISNULL(SUM(cal_txfer),0)AS txfer
		   ,isnull(SUM(cal_tring),0) as tring
		   ,isnull(SUM(cal_tdialog),0) as tdialog
		   ,isnull(SUM(cal_tnotas),0) as tnotes
		   ,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id=6)THEN cal_id ELSE NULL END),0) AS nhangup
		   ,ISNULL(SUM(CASE WHEN cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag
		   ,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
		  ,DATEADD(ss,isnull(sum(0),0),cal_inicio) as time_endque
		   ,DATEADD(ss,isnull(sum(0 + cal_txfer),0),cal_inicio) as time_ring
		   ,DATEADD(ss,isnull(sum(0 + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		   ,DATEADD(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		   ,DATEADD(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		   ,isnull(max(cal_telefono),0) as phone_out,cal_id,cal_puerto
		   FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
		   WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to
		   -- para contar bien las llamadas manuales
		   and cal_manual in(0,2)
		   group by cal_id,[User_id],cam_id,cal_Inicio,cal_puerto
		   )outboundData
		   where not(ntotal=0 AND nno_agent=0 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
				   AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
				   AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0 )


	 update C
	 set C.dateEndDetail=@dateNow
	 ,C.timegroup_next= dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1 )
	 ,C.time_dialog= case when A.currentStatus in (4,5,9) then @dateNow when A.TipoStatusAge_id=4 then B.fecha else C.dateStartDetail end
	 ,C.time_notes=@dateNow
	 ,C.time_end_call=@dateNow
	 ,C.tdialog= case when A.currentStatus in (4,5,9) then B.tiempo when A.TipoStatusAge_id=4 then DATEDIFF(ss,C.dateStartDetail,B.fecha) else 0 end
	 ,C.tnotes= case when A.currentStatus = 6 then B.tiempo else 0 end
	 from ccLogAgentesDia A
	 inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id=B.id
	 inner join #outboundData C on A.callID=C.cal_id
	 WHERE currentStatus in (4,5,6,9) and A.Tipo=1

	select * into #outboundData2 from #outboundData where datediff(mi,timegroup,timegroup_next)>15
	delete #outboundData where datediff(mi,timegroup,timegroup_next) > 15

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto)
	select
	dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,cam_id,[User_id]
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,time_endque)  as tque	
	 ,dbo.TimeInterval(th.start,th.stop,time_endque,time_ring)  as txfer	     
	 ,dbo.TimeInterval(th.start,th.stop,time_dialog,time_notes)  as tdialog
	 ,dbo.TimeInterval(th.start,th.stop,time_notes,time_end_call)  as tnotes
	 ,dbo.TimeInterval(th.start,th.stop,time_ring,time_dialog)  as tring
	 ,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tresp,dateStartDetail))  as tresp	
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nhangup else 0 end as nhangup
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
	,time_endque,time_ring,time_dialog,time_notes,time_end_call
	,phone_out,cal_id,cal_puerto
	from #outboundData2 t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	and th.Start between @from and @to

	insert into #tempccLogAgentesDia(row,[User_id],TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus)
	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY DATEADD(ss,-tStatus,fecha)) AS Row,User_id,
	TipoStatusAge_id,tStatus,DATEADD(ss,-tStatus,fecha) dateIni, fecha dateEnd, isnull(currentStatus,-2)
	from ccLogAgentesDia
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to


	delete A from(
	select case when A.tStatus>S.tStatus then S.row else A.row end row,A.user_id
	from #tempccLogAgentesDia A
	left join #tempccLogAgentesDia S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id=S.TipoStatusAge_id
	and (S.dateEnd between A.dateIni and A.dateEnd or S.dateIni between A.dateIni and A.dateEnd)
	and abs(DATEDIFF(ss,A.dateEnd,S.dateIni))>2
	)x
	inner join 	#tempccLogAgentesDia A on A.row=x.row and A.user_id=x.user_id

	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY dateIni) AS Row,User_id,TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus into #tempccLogAgentesDia2 from #tempccLogAgentesDia

	insert into #timeDetailAgent
	select A.user_id,A.dateIni,A.dateEnd
	,dbo.GetTimeGroup(A.dateIni,0 ) AS timegroup
	,dbo.GetTimeGroup(A.dateEnd,1 ) AS timegroup_next,	
	case when A.tipostatusage_id=1 then A.tStatus else 0 end tunknown,
	case when A.tipostatusage_id=2 then A.tStatus else 0 end tnot_av,
	case when A.tipostatusage_id=3 then A.tStatus else 0 end tav,
	case when A.tipostatusage_id in(11,25,26,27) then A.tStatus else 0 end tprob,--11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida
	case when A.tipostatusage_id=7 then A.tStatus else 0 end tother,
	case when A.tipostatusage_id=7 then 1 else 0 end nother,
	case when A.tipostatusage_id=21 then A.tStatus else 0 end tmanualcall,
	case when abs(isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) )>A.tStatus then 0
	when A.currentStatus in(0,-1,-2) then 0 --Logout
	when S.TipoStatusAge_id=1 then 0
	else isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) end	as tunknown2
	,case when A.tipostatusage_id in (23,24) then A.tStatus else 0 end  as tchatting
	from #tempccLogAgentesDia2 A
	left join #tempccLogAgentesDia2 S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id<>0


	update #timeDetailAgent set tunknown2=0  where abs(tunknown2)>2.7

	 insert into #timeDetailAgent(User_id,dateStartDetail,dateEndDetail,timegroup,timegroup_next,tunknown,tnot_av,tav,tprob,tother,nother,tmanualcall,tunknown2,tchatting)
	 select
	 	User_id,
	 	B.fecha as dateStartDetail,
	 	@dateNow as dateEndDetail
		,dbo.GetTimeGroup(B.fecha,0 ) AS timegroup
		,dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha), 1 ) AS timegroup_next
	 	,case when currentStatus = 1 then tiempo else 0 end as tunknown,
	 	case when currentStatus = 2 then tiempo else 0 end as tnot_av,
	 	case when tipostatusage_id=1 then tiempo when currentStatus = 3 then tiempo else 0 end as tav,
	 	 0,0,0,0,0 as tunknown2
		,case when currentStatus in (23,24) then tiempo else 0 end as tchatting
	 	from ccLogAgentesDia A
	 	inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id=B.id
		where A.currentStatus not in(-2,-1,0)


	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15
	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15


	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother,tmanualCall,tunknown2,tchatting)
	select
	dateStartDetail,dateEndDetail,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tunknown,dateStartDetail))  as tunknown
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail))  as tnot_av	
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tav,dateStartDetail))  as tav	
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tprob,dateStartDetail))  as tprob		
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tother,dateStartDetail))  as tother			
	,isnull((case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tmanualCall,dateStartDetail))  as tmanualCall			
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tunknown2 else 0 end as tunknown2
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tchatting,dateStartDetail))  as tchatting			
	from #timeDetailAgent2 t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	and th.Start between @from and @to

	select
	ROW_NUMBER() OVER(PARTITION BY xTimeDetail.user_id ORDER BY xTimeDetail.timegroup) AS Row,
	xTimeDetail.timegroup
	,xTimeDetail.[user_id]
	,timeSession.tlog
	,xTimeDetail.tav,xTimeDetail.tnot_av,xTimeDetail.tprob,xTimeDetail.tother,xTimeDetail.tunknown,xTimeDetail.tchatting,xTimeDetail.tmanualCall
	,xTimeDetail.nother
	,isnull(B.txfer,0)+isnull(C.txfer,0) as txfer
	,isnull(B.tdialog,0)+isnull(C.tdialog,0) as tdialog
	,isnull(B.tnotes,0)+isnull(C.tnotes,0) as tnotes
	,isnull(B.tring,0)+isnull(C.tring,0) as tring
	,isnull(B.nMoh,0)+isnull(C.nMoh,0) as nMoh
	,isnull(B.nWHag,0)+isnull(C.nWHag,0) as nWHag
	,isnull(B.nWHcl,0)+isnull(C.nWHcl,0) as nWHcl
	into #agentInformation
	from(
		select x.User_id,x.timegroup
		,case when sum(tunknown+tunknown2)>0 then sum(tunknown+tunknown2) else sum(tunknown) end as tunknown
		,sum(tnot_av) as tnot_av
		,case when sum(tav+tav2)>0 then sum(tav+tav2) else sum(tav) end as tav
		,case when sum(tprob+tprob2)>0 then sum(tprob+tprob2) else sum(tprob) end as tprob
		,case when sum(tother+tother2)>0 then sum(tother+tother2) else sum(tother) end as tother
		,case when sum(tmanualcall+tmanualcall2)>0 then sum(tmanualcall+tmanualcall2) else sum(tmanualcall) end as tmanualcall
		,sum(nother) as nother
		,case when sum(tchatting+tchatting2)>0 then sum(tchatting+tchatting2) else sum(tchatting) end as tchatting
			from(
		select User_id,timegroup
		,tunknown,tnot_av,tav,tprob,tother,tmanualcall,nother,tchatting
		,isnull(cast(case when tunknown>0 then tunknown2 else 0 end as int),0) as tunknown2
		,isnull(cast(case when tav>0 and (tav>abs(tunknown2) and (tunknown2+tav)>0 ) then tunknown2 else 0 end as int),0) as tav2
		,isnull(cast(case when tprob>0 then tunknown2 else 0 end as int),0) as tprob2
		,isnull(cast(case when tother>0 then tunknown2 else 0 end as int),0) as tother2
		,isnull(cast(case when tmanualcall>0 then tunknown2 else 0 end as int),0) as tmanualcall2
		,isnull(cast(case when tchatting>0 or (tchatting>abs(tunknown2) and (tunknown2+tchatting)>0 ) then tunknown2 else 0 end as int),0) as tchatting2
		from #timeDetailAgent A
		)x
		group by x.timegroup,x.User_id
	)xTimeDetail
	inner join
	(select user_id,timegroup,sum(tlog) as tlog from #sessionTimeGroup group by user_id,timegroup) timeSession
	on xTimeDetail.User_id=timeSession.user_id and xTimeDetail.timegroup=timeSession.timegroup
	left join
	(select user_id,timegroup,sum(txfer) as txfer,sum(tring) tring,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl from #inboundData group by user_id,timegroup) B
	on xTimeDetail.timegroup=B.timegroup and xTimeDetail.User_id=B.User_id
	left join
	(select user_id,timegroup,sum(txfer) as txfer,sum(tring) tring,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl from #outboundData group by user_id,timegroup) C
	on xTimeDetail.timegroup=C.timegroup and xTimeDetail.User_id=C.User_id

	update B
		set  B.tav=case when A.tav>0 and A.tav+A.tundefinded>=0 then A.tav+A.tundefinded else A.tav end
	 from (
	select User_id,timegroup,tlog,tav,tnot_av,tprob,tother,tunknown,tchatting,tmanualCall,nother,txfer,tdialog,tnotes,tring,
	tlog-tav-tnot_av-tprob-tother-tunknown-tchatting-tmanualCall-nother-txfer-tdialog-tnotes-tring as tundefinded from #agentInformation
	)A
	inner join #agentInformation B on A.User_id=B.User_id and A.timegroup=B.timegroup
	where A.tundefinded<0 and A.tav+A.tundefinded>=0


	update B
		set  B.tunknown=case when A.tunknown>0 and A.tunknown+A.tundefinded>=0 then A.tunknown+A.tundefinded else A.tunknown end
	 from (
	select User_id,timegroup,tlog,tav,tnot_av,tprob,tother,tunknown,tchatting,tmanualCall,nother,txfer,tdialog,tnotes,tring,
	tlog-tav-tnot_av-tprob-tother-tunknown-tchatting-tmanualCall-nother-txfer-tdialog-tnotes-tring as tundefinded from #agentInformation
	)A
	inner join #agentInformation B on A.User_id=B.User_id and A.timegroup=B.timegroup
	where A.tundefinded<0 and A.tunknown+A.tundefinded>=0



	select
	ROW_NUMBER() OVER(ORDER BY
						CASE WHEN agtInf.timegroup IS NOT NULL THEN agtInf.timegroup WHEN calls.timegroup IS NOT NULL  THEN calls.timegroup ELSE 0 END,
						CASE WHEN agtInf.user_id IS NOT NULL THEN agtInf.user_id WHEN calls.userId IS NOT NULL THEN calls.userId ELSE - 1 END
					) AS id,
	agtInf.[row] rowAgentInformation
	,isnull(rowIn,-1) rowIn,isnull(rowOut,-1) rowOut,
	isnull(callIdIn,'') callIdIn,isnull(phoneIn,'') phoneIn,isnull(dateStartDetailIn,'') dateStartDetailIn,
	isnull(callIdOut,'') callIdOut,isnull(phoneOut,'') phoneOut,isnull(dateStartDetailOut,'') dateStartDetailOut,
	(case when agtInf.timegroup IS NOT NULL then agtInf.timegroup when calls.timegroup IS NOT NULL  then calls.timegroup else '' END) [date],
	(case when agtInf.user_id IS NOT NULL THEN agtInf.user_id when calls.userId IS NOT NULL then calls.userId else -1 END) [userId],
	u.apellidopaterno + ' ' + u.apellidomaterno + ' ' + nombres as [user] , u.login as [login]
	,isnull(nxfer_in,0) as nxferin, isnull(nanswer_in,0) as nanswerin, isnull(nabnd_xfer_in,0) as nabndxferin
	,isnull(nabnd_ring_in,0) as nabndringin,isnull(nabnd_dlg_in,0) as nabnddlgin,isnull(abnd_a_xfer_in,0) as abndaxferin
	,isnull(nno_answer_in,0) as nnoanswerin,isnull(nlost_in,0) as nlostin,isnull(tdialog_in,0) as tdialogin
	,isnull(tnotes_in,0) as tnotesin,isnull(tring_in,0) as tringin,isnull(txfer_in,0) as txferin
	,isnull(nxfer_out,0) as nxferout,isnull(nanswer_out,0) as nanswerout,isnull(nabnd_xfer_out,0) as nabndxferout
	,isnull(nabnd_ring_out,0) as nabndringout,isnull(nabnd_dlg_out,0) as nabnddlgout,isnull(abnd_a_xfer_out,0) as abndaxferout
	,isnull(nno_answer_out,0) as nnoanswerout,isnull(nlost_out,0) as nlostout,isnull(tdialog_out,0) as tdialogout
	,isnull(tnotes_out,0) as tnotesout,isnull(tring_out,0) as tringout, isnull(txfer_out,0) as txferout

	,ISNULL(agtInf.nother, 0) AS nother
	,ISNULL(agtInf.tunknown, 0) AS tunknown
	,ISNULL(agtInf.tnot_av, 0) AS tnotav
	,agtInf.tlog as tlog
	,ISNULL(agtInf.tav, 0) AS tav
	,ISNULL(agtInf.tother, 0) + isnull(tmanualcall,0) AS tother
	,ISNULL(agtInf.tprob, 0) AS tprob
	,ISNULL(agtInf.tchatting, 0) AS tchatting

	,isnull(nMoh_in,0) as nMohin,isnull(nMoh_out,0) as nMohout,isnull(nWHag_in,0) as nWHagin
	,isnull(nWHag_out,0) as nWHagout,isnull(nWHcl_in,0) as nWHcliin,isnull(nWHcl_out,0) as nWHcliout
	, CASE WHEN agtInf.timegroup IS NOT NULL THEN datepart(yy,agtInf.timegroup)
						WHEN calls.timegroup IS NOT NULL THEN datepart(yy,calls.timegroup) ELSE 0 END AS [year]
		   , CASE WHEN agtInf.timegroup IS NOT NULL THEN datepart(mm,agtInf.timegroup)
						WHEN calls.timegroup IS NOT NULL THEN datepart(mm,calls.timegroup) ELSE 0 END AS [month]
		   , CASE WHEN agtInf.timegroup IS NOT NULL THEN datepart(dd,agtInf.timegroup)
						WHEN calls.timegroup IS NOT NULL THEN datepart(dd,calls.timegroup) ELSE 0 END AS [day]
		   , CASE WHEN agtInf.timegroup IS NOT NULL THEN datepart(hh,agtInf.timegroup)
						WHEN calls.timegroup IS NOT NULL THEN datepart(hh,calls.timegroup) ELSE 0 END AS [hour]
		   , CASE WHEN agtInf.timegroup IS NOT NULL THEN datepart(mi,agtInf.timegroup)
						WHEN calls.timegroup IS NOT NULL THEN datepart(mi,calls.timegroup) ELSE 0 END AS [minutes]
	into #tempRepAgentGI
	from #agentInformation agtInf
	left join ccUserView u ON agtInf.[user_id] = u.[user_id]
	left join
	(select
		(case when _in.timegroup is not null then _in.timegroup else _out.timegroup end) timegroup,
		(case when _in.[user_id] is not null then _in.[user_id] else _out.[user_id] end) [userId]
		,isnull(_in.row, -1) as rowIn,isnull(_out.row, -1) as rowOut
		,isnull((_in.nxfer), 0) AS nxfer_in, isnull((_in.nanswer), 0) AS nanswer_in, isnull((_in.nabnd_xfer), 0) AS nabnd_xfer_in
		,isnull((_in.nabnd_ring), 0) AS nabnd_ring_in, ISNULL((_in.nabnd_dialog), 0) AS nabnd_dlg_in
		,isnull((_in.nabnd_xfer), 0) + isnull((_in.nabnd_ring), 0) + isnull((_in.nabnd_dialog), 0) AS abnd_a_xfer_in
		,isnull((_in.nno_answer), 0) AS nno_answer_in, isnull((_in.nlost), 0) AS nlost_in, isnull((_in.tdialog), 0) AS tdialog_in
		,isnull((_in.tnotes), 0) AS tnotes_in, isnull((_in.tring), 0) AS tring_in, isnull((_in.txfer), 0) AS txfer_in
		,isnull((_in.nMoh), 0) AS nMoh_in, isnull((_in.nWHag), 0) AS nWHag_in,isnull((_in.nWHcl), 0) AS nWHcl_in
		,isnull((_out.nxfer), 0) AS nxfer_out, isnull((_out.nanswer), 0) AS nanswer_out, isnull((_out.nabnd_xfer), 0) AS nabnd_xfer_out
		,isnull((_out.nabnd_ring), 0) AS nabnd_ring_out, isnull((_out.nabnd_dialog), 0) AS nabnd_dlg_out
		,isnull((_out.nabnd_xfer), 0) + isnull((_out.nabnd_ring), 0) + isnull((_out.nabnd_dialog), 0) AS abnd_a_xfer_out
		,isnull((_out.nno_answer), 0) AS nno_answer_out, isnull((_out.nlost), 0) AS nlost_out, isnull((_out.tdialog), 0) AS tdialog_out
		,isnull((_out.tnotes), 0) AS tnotes_out, isnull((_out.tring), 0) AS tring_out, isnull((_out.txfer), 0) AS txfer_out
		,isnull((_out.nMoh), 0) AS nMoh_out, isnull((_out.nWHag), 0) AS nWHag_out,isnull((_out.nWHcl), 0) AS nWHcl_out
		,isnull((_in.cal_id),'') as callIdIn,isnull((_in.phone_in),'') as phoneIn,isnull((_in.dateStartDetail),'') as dateStartDetailIn
		,isnull((_out.cal_id),'') as callIdOut,isnull((_out.phone_out),'') as phoneOut,isnull((_out.dateStartDetail),'') as dateStartDetailOut
	from #inboundData _in
	FULL OUTER JOIN #outboundData _out on _in.timegroup=_out.timegroup AND _in.[user_id]=_out.[user_id])  calls
	on calls.timegroup = agtInf.timegroup and agtInf.[user_id]=calls.[userid]
	where agtInf.timegroup is not null

	update A set nother=0,tunknown=0,tnotav=0,tlog=0,tother=0,tprob=0,tav=0,tchatting=0 from (
	select RANK() OVER(PARTITION BY A.rowAgentInformation,A.userId ORDER by id) as [rank], A.id from
	#tempRepAgentGI A
	inner join (
	select temp.rowAgentInformation,temp.[UserId] from #tempRepAgentGI temp GROUP BY temp.rowAgentInformation,temp.[UserId] HAVING Count(*) > 1 )B
	on A.userId=B.userId and A.rowAgentInformation=B.rowAgentInformation)x
	inner join #tempRepAgentGI A on A.id=x.id
	where x.rank>1

	update A
	set nxferin=0,nanswerin=0,nabndxferin=0,nabndringin=0,nabnddlgin=0,abndaxferin=0,nnoanswerin=0,nlostin=0,tdialogin=0,tnotesin=0,tringin=0,txferin=0,nMohin=0,nWHagin=0,nWHcliin=0
	from (
	select RANK() OVER(PARTITION BY A.rowIn,A.userId ORDER by id) as [rank], A.id from
	#tempRepAgentGI A
	inner join (
		select temp.rowIn,temp.[UserId] from #tempRepAgentGI temp GROUP BY temp.rowIn,temp.[UserId] HAVING Count(*) > 1
		)B
		on A.userId=B.userId and A.rowIn=B.rowIn
	)x
	inner join #tempRepAgentGI A on A.id=x.id
	where x.rank>1

	update A
	set nxferout=0,nanswerout=0,nabndxferout=0,nabndringout=0,nabnddlgout=0,abndaxferout=0,nnoanswerout=0,nlostout=0,tdialogout=0,tnotesout=0,tringout=0,txferout=0,nMohout=0,nWHagout=0,nWHcliout=0
	from (
	select RANK() OVER(PARTITION BY A.rowOut,A.userId ORDER by id) as [rank], A.id from
	#tempRepAgentGI A
	inner join (
		select temp.rowOut,temp.[UserId] from #tempRepAgentGI temp GROUP BY temp.rowOut,temp.[UserId] HAVING Count(*) > 1
		)B
		on A.userId=B.userId and A.rowOut=B.rowOut
	)x
	inner join #tempRepAgentGI A on A.id=x.id
	where x.rank>1	

	delete from RepAgentGI where date >= @from AND date < @to

	insert into RepAgentGI(date,userId,[user],login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,--treq,
			tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotavg,tundefined,tchatting)
	select date,userId,isnull([user],'otro'),isnull(login,'otro') login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,--treq,
				tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotav,
				(tlog-tdialogin-tnotesin-tringin-txferin-tdialogout-tnotesout-tringout-txferout-tunknown-tnotav-tav-tother-tprob-tchatting) as tundefined
				,tChatting
	 from #tempRepAgentGI
	 

	---DROP TABLES TEMP	
	IF OBJECT_ID('tempdb..#inboundData') IS NOT NULL drop table #inboundData
	IF OBJECT_ID('tempdb..#inboundData2') IS NOT NULL drop table #inboundData2
	IF OBJECT_ID('tempdb..#outboundData') IS NOT NULL drop table #outboundData
	IF OBJECT_ID('tempdb..#outboundData2') IS NOT NULL drop table #outboundData2
	IF OBJECT_ID('tempdb..#timeDetailAgent') IS NOT NULL drop table #timeDetailAgent
	IF OBJECT_ID('tempdb..#timeDetailAgent2') IS NOT NULL drop table #timeDetailAgent2
	IF OBJECT_ID('tempdb..#agentInformation') IS NOT NULL drop table #agentInformation
	IF OBJECT_ID('tempdb..#tempRepAgentGI') IS NOT NULL drop table #tempRepAgentGI

	IF OBJECT_ID('tempdb..#tempAgentLastStatus') IS NOT NULL drop table #tempAgentLastStatus
	IF OBJECT_ID('tempdb..#tempccLogAgentesDia') IS NOT NULL drop table #tempccLogAgentesDia
	IF OBJECT_ID('tempdb..#tempccLogAgentesDia2') IS NOT NULL drop table #tempccLogAgentesDia2
	IF OBJECT_ID('tempdb..#sessionTimeGroup') IS NOT NULL drop table #sessionTimeGroup
end