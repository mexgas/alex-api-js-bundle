CREATE PROCEDURE [dbo].[ccspRepOutCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

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

     CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

    create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
    create nonclustered index ix_times2 on #times([Start] DESC)
	CREATE TABLE #sessionTime([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL)


	insert into #times
	exec ccspTimesReports @from=@from,@to=@to,@interval=@interval

	insert into #sessionTime
	exec ccspGenSession @from=@from,@to=@to

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	SELECT      cal_inicio as dateStartDetail,
		  dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
		  dbo.GetTimeGroup(cal_inicio,0) as timegroup,
		  dbo.GetTimeGroup(
		  dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio)
		  ,1)  as timegroup_next
		  ,DATEADD(ss,isnull(sum(cal_twait),0),cal_inicio) as time_endque
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer),0),cal_inicio) as time_ring
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		  ,isnull(max(cal_Ani),0) as phone_in,cal_id,dni_id,Inbound_id,[User_id]
		  ,COUNT(cal_id)AS ntotal
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END),0) AS ninitial
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END),0) AS nout_hour
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END),0) AS nout_service
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = '1900-01-01 00:00:00'))THEN 1 ELSE NULL END),0) AS nabnd
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0) AS nno_agent
		  ,ISNULL(COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END),0) AS nque
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0) AS ntimeout
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0) AS noverflow
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00'))THEN 1 ELSE NULL END),0) AS nxfer
		  ,ISNULL(COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00')))THEN cal_xfer ELSE NULL END),0) AS nxfer_que
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> '1900-01-01 00:00:00'))THEN 1 ELSE NULL END),0) AS nabnd_xfer
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END),0) AS nabnd_ring
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),0) AS nno_answer
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END),0) AS nabnd_dialog
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) AS nanswer
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0) AS nlost
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END),0) AS nmsg
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = '1900-01-01 00:00:00')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nabnd_tres
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nansw_tres
		  ,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
		  ,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
		  ,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
		  ,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
		  ,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
		  FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		  WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
		  group by cal_id,[User_id],Inbound_id,cal_inicio,dni_id

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
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,dateStartDetail,time_endque)
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
				  when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque
		  ,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
				  when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,th.stop)
				  when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
				  when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer               ,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
				  when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
				  when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
				  when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tdialog
		  ,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
				  when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
				  when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
				  when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
		  ,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
				  when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,th.stop)
				  when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
				  when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tresp,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tresp,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end as tresp
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
		  from #inboundData2 t
		  join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		  where  datediff(ss,th.start,timegroup_next)>0
		  order by cal_id

	drop table #inboundData2


	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,idwg)
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull(sum(cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		,dbo.GetTimeGroup(cal_inicio,0) as timegroup
		 ,dbo.GetTimeGroup(
		 dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio)
		 ,1) as timegroup_next
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
			,ISNULL(COUNT(CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0) AS nhangup
			,ISNULL(SUM(CASE WHEN cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag
			,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
			,DATEADD(ss,isnull(sum(cal_twait),0),cal_inicio) as time_endque
			,DATEADD(ss,isnull(sum(cal_twait + cal_txfer),0),cal_inicio) as time_ring
			,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
			,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
			,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
			,isnull(max(cal_telefono),0) as phone_out,cal_id,cal_puerto, 0 as idwg
		  FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
		  WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to
		  -- para contar bien las llamadas manuales
		  and cal_manual in (0,2,3)
		  group by cal_id,[User_id],cam_id,cal_Inicio,cal_puerto


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

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,idwg)
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
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,dateStartDetail,time_endque)
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
				  when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque
		  ,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
				  when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,th.stop)
				  when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
				  when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer
		  ,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
				  when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,th.stop)
				  when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
				  when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring
		  ,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
				  when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
				  when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
				  when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tdialog
		  ,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
				  when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
				  when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
				  when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tresp,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tresp,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end as tresp
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nhangup else 0 end as nhangup
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
		  ,time_endque,time_ring,time_dialog,time_notes,time_end_call
		  ,phone_out,cal_id,cal_puerto,idwg
		  from #outboundData2 t
		  inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		  where  datediff(ss,th.start,timegroup_next)>0


	drop table #outboundData2

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
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tunknown,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tunknown,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tunknown
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnot_av,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tnot_av
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tprob,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tprob,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tprob
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
		  ,isnull(sum(case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	group by th.start,th.stop,[User_id]

	drop table #timeDetailAgent2

	select ROW_NUMBER() OVER(ORDER BY xTimeDetail.timegroup,xTimeDetail.[user_id] ) AS Row,
		  xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
		  ,ISNULL(calls.txfer,0) as txfer,ISNULL(tdialog,0) as tdialog,ISNULL(tnotes,0) as tnotes,ISNULL(tring,0) as tring
		  ,ISNULL(nMoh,0) as nMoh,ISNULL(nWHag,0) as nWHag,ISNULL(nWHcl,0) as nWHcl
		  ,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
					 FROM #sessionTime
					 WHERE [user_id]=xTimeDetail.[user_id]
						   AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
		  ),0)AS t1
		  ,ISNULL((SELECT top 1 900
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login<=xTimeDetail.timegroup AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t2
		  ,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t3
		  ,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(mi,15,xTimeDetail.timegroup))
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login>xTimeDetail.timegroup AND login<DATEADD(mi,15,xTimeDetail.timegroup)AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t4
		  into #agentInformation
		  from (select min(dateStartDetail) as dateStartDetail,min(dateEndDetail) as dateEndDetail,timegroup,timegroup_next,[User_id]
			 ,sum(tunknown) as tunknown,sum(tnot_av) as tnot_av,sum(tav) as tav,sum(tprob) as tprob,sum(tother) as tother,sum(nother) as nother
				from #timeDetailAgent
				group by timegroup,timegroup_next,user_id
				)xTimeDetail
	right join
	(select CASE WHEN #inboundData.timegroup IS NOT NULL THEN #inboundData.timegroup
					 WHEN #outboundData.timegroup IS NOT NULL THEN #outboundData.timegroup ELSE NULL END timegroup,
		  CASE WHEN #inboundData.[user_id] IS NOT NULL THEN #inboundData.[user_id]
				  WHEN #outboundData.[user_id] IS NOT NULL THEN #outboundData.[user_id] ELSE NULL END as [user_id]
		  ,ISNULL(SUM(#inboundData.txfer),0)+ ISNULL(SUM(#outboundData.txfer),0)as txfer
		  ,ISNULL(SUM(#inboundData.tdialog),0)+ ISNULL(SUM(#outboundData.tdialog),0)as tdialog
		  ,ISNULL(SUM(#inboundData.tnotes),0)+ ISNULL(SUM(#outboundData.tnotes),0)as tnotes
		  ,ISNULL(SUM(#inboundData.tring),0)+ ISNULL(SUM(#outboundData.tring),0)as tring
		  ,ISNULL(SUM(#inboundData.nMoh),0)+ ISNULL(SUM(#outboundData.nMoh),0)as nMoh
		  ,ISNULL(SUM(#inboundData.nWHag),0)+ ISNULL(SUM(#outboundData.nWHag),0)as nWHag
		  ,ISNULL(SUM(#inboundData.nWHcl),0)+ ISNULL(SUM(#outboundData.nWHcl),0)as nWHcl
	from #inboundData
	FULL OUTER JOIN #outboundData ON(#inboundData.timegroup=#outboundData.timegroup AND #inboundData.[user_id]=#outboundData.[user_id])
	group by
		  case when #inboundData.timegroup IS NOT NULL then #inboundData.timegroup
				 when #outboundData.timegroup IS NOT NULL then #outboundData.timegroup else NULL end
		  ,case when #inboundData.[user_id] IS NOT NULL then #inboundData.[user_id]
				  when #outboundData.[user_id] IS NOT NULL then #outboundData.[user_id] else NULL end
	) as calls on calls.timegroup = xTimeDetail.timegroup and xTimeDetail.[user_id]=calls.[user_id]
	where xTimeDetail.timegroup is not null

	drop table #timeDetailAgent


	 SELECT timegroup, ccCampsAgente.cam_id
		, SUM((t1+t2+t3+t4) - (tnot_av + tprob + tother)) AS pos_time
		, COUNT(CASE WHEN ((t1+t2+t3+t4) - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE 0 END) AS tresPos
	 INTO #ccGenOutCamp
	 FROM #agentInformation
		INNER JOIN ccCampsAgente ON (#agentInformation.[user_id] = ccCampsAgente.[user_id])
	 WHERE timegroup >= @from AND timegroup < @to
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
	delete from RepOutCalls with(rowlock)
	where date >= @from AND date < @to

     insert into RepOutCalls
		select date,areaId,area,workgroupid,workgroup,campaignid,campaign,userId,user,ntotal,nxfer,nno_agent,nanswer,nno_answer,nlost,nabnd_xfer,nabnd_ring,nabnd_dialog
		,isnull(pos_tot,0),isnull(pos_time,0),nhangup,tatencion,year,mounth,day,hour,minutes,cal_id,phone_out,dateStartDetail
		from #tempRepOutCalls order by cal_id


	delete RepOutCalls
	where userId = 0
	and [date] >= @from and [date] < @to

	update RepOutCalls
	set areaId = idArea
	from RepOutCalls
	left outer join ccriaareaworkgroup on (workgroupid = idwg)
	where idarea is not null
	and [date] >= @from and [date] < @to

	delete RepOutCalls
	where areaId = 0
	and [date] >= @from and [date] < @to

	update RepOutCalls set
	area = (select areaname from ccriacat_areas where idarea = areaid)
	,workgroup = (select wgname from ccriacat_workgroup where idwg = workgroupid)
	,campaign = (select cam_descripcion from cccamps where cam_id = campaignid)
	,[user] = (select login from ccUserView where user_id = userid)
	where [date] >= @from and [date] < @to

	drop table #times
	drop table #sessionTime
	drop table #inboundData
	drop table #outboundData
	drop table #agentInformation
	drop table #ccGenOutCamp
	drop table #tempTime
	drop table #tempRepOutCalls

end