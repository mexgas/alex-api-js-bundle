CREATE PROCEDURE [dbo].[ccspRepOutCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS off
SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to =  getdate()


DECLARE @HourExtend AS smallint
SELECT @HourExtend=2
DECLARE @fromExtended AS smalldatetime
SELECT @fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint
DECLARE @tresDelayIn AS smallint

if @action = 1
begin

	EXEC @tresRing=ccspConfigTresRing
	EXEC @tresDialog=ccspConfigTresDialog
	EXEC @tresDelayIn=ccspConfigtresDelayIn

	declare @interval int
	 declare @starttime datetime
     declare @number int
     set @starttime = @from
     set @number = 0
	 set @interval=15

	IF OBJECT_ID('tempdb..#inboundData') IS NOT NULL drop table #inboundData
	IF OBJECT_ID('tempdb..#inboundData2') IS NOT NULL drop table #inboundData2
	IF OBJECT_ID('tempdb..#outboundData') IS NOT NULL drop table #outboundData
	IF OBJECT_ID('tempdb..#agentInformation') IS NOT NULL drop table #agentInformation
	IF OBJECT_ID('tempdb..#ccGenOutCamp') IS NOT NULL drop table #ccGenOutCamp
	IF OBJECT_ID('tempdb..#tempTime') IS NOT NULL drop table #tempTime
	IF OBJECT_ID('tempdb..#tempRepOutCalls') IS NOT NULL drop table #tempRepOutCalls
	IF OBJECT_ID('tempdb..#timeDetailAgent') IS NOT NULL drop table #timeDetailAgent
	IF OBJECT_ID('tempdb..#timeDetailAgent2') IS NOT NULL drop table #timeDetailAgent2

      create table #inboundData(row int identity, dateStartDetail datetime,
      dateEndDetail datetime,      timegroup datetime, timegroup_next datetime,      time_endque datetime,
      time_ring datetime,      time_dialog datetime, time_notes datetime,      time_end_call datetime,
      phone_in varchar(30),      cal_id int, dni_id int,      Inbound_id int,
      User_id int,      ntotal int, ninitial int,      nout_hour int,
      nout_service int, nabnd int,     nno_agent int,
      nque int,      ntimeout int,    noverflow int,
      nxfer int,      nxfer_que int,     nabnd_xfer int,      nabnd_ring int,
      nno_answer int,      nabnd_dialog int,
      nanswer int,      nlost int,     nmsg int,      nabnd_tres int,
      nansw_tres int,      tque_max int,
      tque int,      txfer int,     tdialog int,      tnotes int,
      tring int,      tresp int,     nMoh int,      nWHag int,
      nWHcl int)

      create table #outboundData( row int identity,
      dateStartDetail datetime, dateEndDetail datetime,
      timegroup datetime, timegroup_next datetime,
      cam_id int,User_id int,ntotal int,nno_agent int,
      nxfer int,nabnd_xfer int,nabnd_ring int, nno_answer int,
      nabnd_dialog int,nanswer int,
      nlost int,tque int,txfer int,tring int,
      tdialog int,tnotes int,tresp int,nhangup int, nMoh int,nWHag int,nWHcl int,time_endque datetime,
      time_ring datetime,time_dialog datetime,
      time_notes datetime,time_end_call datetime,
      phone_out varchar(30),cal_id int,cal_puerto int, idwg int)
    	
	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
		  SELECT      cal_inicio as dateStartDetail,
		  dateadd(ss,isnull((cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
		  dbo.GetTimeGroup(cal_inicio,0) as timegroup,
		  dbo.GetTimeGroup(
		  dateadd(ss,isnull((cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio)
		  ,1)  as timegroup_next
		  ,DATEADD(ss,isnull((cal_twait),0),cal_inicio) as time_endque
		  ,DATEADD(ss,isnull((cal_twait + cal_txfer),0),cal_inicio) as time_ring
		  ,DATEADD(ss,isnull((cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		  ,DATEADD(ss,isnull((cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		  ,DATEADD(ss,isnull((cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		  ,isnull((cal_Ani),0) as phone_in,cal_id,dni_id,Inbound_id,[User_id]
		  ,1 AS ntotal
		  ,ISNULL((CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END),0) AS ninitial
		  ,ISNULL((CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END),0) AS nout_hour
		  ,ISNULL((CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END),0) AS nout_service
		  ,ISNULL((CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = '1900-01-01 00:00:00'))THEN 1 ELSE NULL END),0) AS nabnd
		  ,ISNULL((CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0) AS nno_agent
		  ,ISNULL((CASE WHEN(cal_que>0)THEN 1 ELSE NULL END),0) AS nque
		  ,ISNULL((CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0) AS ntimeout
		  ,ISNULL((CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0) AS noverflow
		  ,ISNULL((CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00'))THEN 1 ELSE NULL END),0) AS nxfer
		  ,ISNULL((CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00')))THEN 1 ELSE NULL END),0) AS nxfer_que
		  ,ISNULL((CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00'))THEN 1 ELSE NULL END),0) AS nabnd_xfer
		  ,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END),0) AS nabnd_ring
		  ,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),0) AS nno_answer
		  ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END),0) AS nabnd_dialog
		  ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) AS nanswer
		  ,ISNULL((CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0) AS nlost
		  ,ISNULL((CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END),0) AS nmsg
		  ,ISNULL((CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = '1900-01-01 00:00:00')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nabnd_tres
		  ,ISNULL((CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nansw_tres
		  ,ISNULL((cal_twait),0)AS tque_max,ISNULL((cal_twait),0)AS tque,ISNULL((cal_txfer),0)AS txfer
		  ,ISNULL((cal_tdialog),0)AS tdialog,ISNULL((cal_tnotas),0)AS tnotes,ISNULL((cal_tring),0)AS tring
		  ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
		  ,ISNULL((case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
		  ,ISNULL((CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL((CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
		  FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		  WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0

	delete #inboundData WHERE timegroup>=@from AND timegroup<@to AND INBOUND_ID>0
	AND ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
	AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
	AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
	AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0

	select * into #inboundData2 from #inboundData where datediff(mi,timegroup,timegroup_next)>15

	delete #inboundData where datediff(mi,timegroup,timegroup_next) > 15

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	select
		  dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call
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
		    ,dbo.TimeInterval(th.start,th.stop,dateStartDetail,time_endque) as tque
		  ,dbo.TimeInterval(th.start,th.stop,time_endque,time_ring) as txfer
		  ,dbo.TimeInterval(th.start,th.stop,time_ring,time_notes) as tdialog		  
		  ,dbo.TimeInterval(th.start,th.stop,time_notes,time_end_call) as tnotes
		  ,dbo.TimeInterval(th.start,th.stop,time_ring,time_dialog) as tring
		  ,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tresp,dateStartDetail)) as tresp			  
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
		  from #inboundData2 t
		  join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		  where  th.start between @from and @to and datediff(ss,th.start,timegroup_next)>0
		  and th.Start between @from and @to


	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,idwg)
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull((cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
	,dbo.GetTimeGroup(cal_inicio,0) as timegroup
	 ,dbo.GetTimeGroup(
	 dateadd(ss,isnull((cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio)
	 ,1) as timegroup_next
		,cam_id, [User_id]
		,1 AS ntotal
		,ISNULL((CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END),0) AS nno_agent
		,ISNULL((CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END),0) AS nxfer
		,ISNULL((CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END),0) AS nabnd_xfer
		,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END),0) AS nabnd_ring
		,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END),0) AS nno_answer
		,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END),0) AS nabnd_dialog
		,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END),0) AS nanswer
		,ISNULL((CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END),0) AS nlost
		,ISNULL((cal_twait),0) as tque
		,ISNULL((cal_txfer),0)AS txfer
		,isnull((cal_tring),0) as tring
		,isnull((cal_tdialog),0) as tdialog
		,isnull((cal_tnotas),0) as tnotes
		,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
		,ISNULL((CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0) AS nhangup
		,ISNULL((CASE WHEN cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL((CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag
		,ISNULL((CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
		,DATEADD(ss,isnull((cal_twait),0),cal_inicio) as time_endque
		,DATEADD(ss,isnull((cal_twait + cal_txfer),0),cal_inicio) as time_ring
		,DATEADD(ss,isnull((cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		,DATEADD(ss,isnull((cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		,DATEADD(ss,isnull((cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		,isnull((cal_telefono),0) as phone_out,cal_id,cal_puerto, 0 as idwg
	  FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
	  WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to
	  -- para contar bien las llamadas manuales
	  and cal_manual in (0,2,3)

	delete from #outboundData WHERE timegroup>=@from AND timegroup<@to
		  AND ntotal=0 AND nno_agent=0 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		  AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		  AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0  and nhangup=0

    update A
    set idwg = B.idwg
    from #outboundData A
    inner join ccriaworkgroup_calid B on A.cal_id = B.cal_id


	select * into #outboundData2 from #outboundData where datediff(mi,timegroup,timegroup_next)>15

	delete #outboundData where datediff(mi,timegroup,timegroup_next) > 15

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost
	,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,idwg)
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
		  ,dbo.TimeInterval(th.start,th.stop,dateStartDetail,time_endque) as tque
		  ,dbo.TimeInterval(th.start,th.stop,time_endque,time_ring) as txfer
		  ,dbo.TimeInterval(th.start,th.stop,time_ring,time_dialog) as tring
		  ,dbo.TimeInterval(th.start,th.stop,time_dialog,time_notes) as tdialog
		  ,dbo.TimeInterval(th.start,th.stop,time_notes,time_end_call) as tnotes		  
		  ,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tresp,dateStartDetail)) as tresp		  		  		  
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nhangup else 0 end as nhangup
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
		  ,time_endque,time_ring,time_dialog,time_notes,time_end_call
		  ,phone_out,cal_id,cal_puerto,idwg
		  from #outboundData2 t
		  inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		  where  th.start between @from and @to and datediff(ss,th.start,timegroup_next)>0		  
		  and th.Start between @from and @to
	

	select DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail
		,convert(smalldatetime,
		dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha),0)
		) as timegroup
		,convert(smalldatetime,
			dbo.GetTimeGroup(fecha,1)
		) as timegroup_next
				,[User_id]
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE 0 END),0) AS tunknown
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE 0 END),0) AS tnot_av
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE 0 END),0) AS tav
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE 0 END),0) AS tprob
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE 0 END),0) AS tother
				,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
				into #timeDetailAgent
		  from ccLogAgentesDia
		  WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
		  GROUP BY
		 convert(smalldatetime,		dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha),0)		) 
		,convert(smalldatetime,			dbo.GetTimeGroup(fecha,1)		)
		 , [User_id]

	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15

	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother)
	select
		  min(dateStartDetail),min(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
		    ,sum(dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tunknown,dateStartDetail) )) as tunknown	
			,sum(dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail) )) as tnot_av
			,sum(dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tav,dateStartDetail) )) as tav
			,sum(dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tprob,dateStartDetail) )) as tprob
			,sum(dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tother,dateStartDetail) )) as tother		  		 		  
		  ,isnull(sum(case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
	from #timeDetailAgent2 t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where th.start between @from and @to and datediff(ss,th.start,timegroup_next)>0
	and th.Start between @from and @to
	group by th.start,th.stop,[User_id]	

	;
	with timeDetailAgent as(
	select min(dateStartDetail) as dateStartDetail,max(dateEndDetail) as dateEndDetail,timegroup,User_id
	,sum(tunknown) as tunknown,sum(tnot_av) as tnot_av,sum(tav) as tav,sum(tprob) as tprob,sum(tother) as tother,sum(nother) nother
	from #timeDetailAgent 	
	group by timegroup,timegroup_next,User_id
	)
	, callIn as(
	select timegroup,[user_id],sum(txfer) as txfer,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(tring) as tring,sum(nMoh) as nMoh,sum(nWHag) as nWHag,sum(nWHcl) as nWHcl
	from #inboundData	
	group by timegroup,[user_id]
	)

	, callOut  as(
	select timegroup,[user_id],sum(txfer) as txfer,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(tring) as tring,sum(nMoh) as nMoh,sum(nWHag) as nWHag,sum(nWHcl) as nWHcl
	from #outboundData	
	group by timegroup,[user_id]
	)
	
	select 
	ROW_NUMBER() OVER(ORDER BY session.timegroup,session.[user_id] ) AS Row,
	session.timeGroup,session.user_id
	, isnull(tnot_av,0 ) as tnot_av,isnull(tav,0) as tav,isnull(tprob,0) as tprob,isnull(tother,0) as tother,isnull(tunknown,0) as tunknown,isnull(nother,0) as nother
	,isnull(callOut.txfer,0) + isnull(callIn.txfer,0) as txfer,isnull(callOut.tdialog,0) + isnull(callIn.tdialog,0) as tdialog,isnull(callOut.tnotes,0) + isnull(callIn.tnotes,0) as tnotes,isnull(callOut.tring,0) + isnull(callIn.tring,0) as tring,isnull(callOut.nMoh,0) + isnull(callIn.nMoh,0) as nMoh,isnull(callOut.nWHag,0) + isnull(callIn.nWHag,0) as nWHag,isnull(callOut.nWHcl,0) + isnull(callIn.nWHcl,0) as nWHcl	
	,session.tlog
	into #agentInformation
	from TmpSessionTimeGroup as session 
	left join timeDetailAgent timeAgent on session.timeGroup=timeAgent.timeGroup and session.user_id=timeAgent.user_Id
	left join callIn on session.timeGroup= callIn.timeGroup and session.user_id=callIn.user_Id
	left join callOut on session.timeGroup= callOut.timeGroup and session.user_id=callOut.user_Id		
	where session.login between @from and @to

	 SELECT timegroup, ccCampsAgente.cam_id
		, SUM((tlog) - (tnot_av + tprob + tother)) AS pos_time
		, COUNT(CASE WHEN ((tlog) - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE 0 END) AS tresPos
	 INTO #ccGenOutCamp
	 FROM #agentInformation
		INNER JOIN ccCampsAgente ON (#agentInformation.[user_id] = ccCampsAgente.[user_id])	 
	 GROUP BY timegroup, ccCampsAgente.cam_id

	 select ROW_NUMBER() OVER(Order by row) as id,
		  #outboundData.row, #outboundData.timegroup as [date],0 as areaId,'' as area
		 ,idwg as workgroupid,'' as workgroup
		 ,#outboundData.cam_id as campaignid,'' as campaign
		 ,[User_id] as userId,'' as [user]
		 ,ntotal, nxfer, nno_agent, nanswer, nno_answer, nlost, nabnd_xfer, nabnd_ring, nabnd_dialog
		 ,1 as pos_tot, pos_time, nhangup, (tdialog + tnotes) as  tatencion
		 ,datepart(yy,convert(datetime,#outboundData.timegroup)) as [year]
		 ,datepart(mm,convert(datetime,#outboundData.timegroup)) as [mounth]
		 ,datepart(dd,convert(datetime,#outboundData.timegroup)) as [day]
		 ,datepart(hh,convert(datetime,#outboundData.timegroup)) as [hour]
		 ,datepart(mi,convert(datetime,#outboundData.timegroup)) as [minutes]
		 ,cal_id,phone_out,dateStartDetail
		 into #tempRepOutCalls
		 from #outboundData
		 left join #ccGenOutCamp  ON (#outboundData.timegroup = #ccGenOutCamp.timegroup and #outboundData.cam_id=#ccGenOutCamp.cam_id)

	 SELECT
      RANK() OVER(PARTITION BY row ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      into #tempTime
      FROM #tempRepOutCalls
      where row in
            (select row from #tempRepOutCalls temp GROUP BY temp.row HAVING Count(*) > 1 )

       update t
            set ntotal=0,nxfer=0,nno_agent=0,nanswer=0,nno_answer=0,nlost=0,nabnd_xfer=0,nabnd_ring=0,nabnd_dialog=0,tatencion=0
            from #tempRepOutCalls t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1

    delete #tempTime

    insert into #tempTime([rank],rowNumber,id)
    SELECT
      RANK() OVER(PARTITION BY cal_id ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      FROM #tempRepOutCalls
      where cal_id in
            (select cal_id from #tempRepOutCalls temp GROUP BY temp.cal_id HAVING Count(*) > 1 )

       update t
            set pos_tot=0
            from #tempRepOutCalls t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1

    --Borrar lo que esta para no repetir
	delete from RepOutCalls	where date >= @from AND date < @to

    insert into RepOutCalls
		select date,isnull(B.IDArea, areaId) as areaId,isnull(Area.AreaName, area) as area,isnull(wg.IDWG,workgroupid) as workgroupid,isnull(wg.WGName, workgroup) as workgroup
		,campaignid,isnull(B.cam_descripcion, campaign) as campaign,userId,isnull(userView.Login, [user]) as [user],ntotal,nxfer,nno_agent,nanswer,nno_answer,nlost,nabnd_xfer,nabnd_ring,nabnd_dialog
		,isnull(pos_tot,0) as pos_tot,isnull(pos_time,0) as pos_time,nhangup,tatencion,year,mounth,day,hour,minutes,cal_id,phone_out,dateStartDetail
		from #tempRepOutCalls A
		left join cccamps B on A.campaignid=B.cam_id
		left join ccriacat_workgroup wg on A.workgroupid=wg.IDWG
		left join ccriacat_areas Area on B.IDArea=Area.IDArea
		left join ccUserView userView on userView.User_id=A.userId
		where A.userId <> 0
		order by date

	IF OBJECT_ID('tempdb..#inboundData') IS NOT NULL drop table #inboundData
	IF OBJECT_ID('tempdb..#inboundData2') IS NOT NULL drop table #inboundData2
	IF OBJECT_ID('tempdb..#outboundData') IS NOT NULL drop table #outboundData
	IF OBJECT_ID('tempdb..#outboundData2') IS NOT NULL drop table #outboundData2
	IF OBJECT_ID('tempdb..#agentInformation') IS NOT NULL drop table #agentInformation
	IF OBJECT_ID('tempdb..#ccGenOutCamp') IS NOT NULL drop table #ccGenOutCamp
	IF OBJECT_ID('tempdb..#tempTime') IS NOT NULL drop table #tempTime
	IF OBJECT_ID('tempdb..#tempRepOutCalls') IS NOT NULL drop table #tempRepOutCalls
	IF OBJECT_ID('tempdb..#timeDetailAgent') IS NOT NULL drop table #timeDetailAgent
	IF OBJECT_ID('tempdb..#timeDetailAgent2') IS NOT NULL drop table #timeDetailAgent2

end