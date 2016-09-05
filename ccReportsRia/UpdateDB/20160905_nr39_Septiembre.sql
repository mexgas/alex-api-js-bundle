/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 20160608
Description:

	SP ReportsMasterProcess: Se cambia para que se ejecuten la replicas de manera paulatina
Database: ccReportsRiaPara
Required version: 37

----ALTER PROCEDURE [dbo].[ccspRepCatalogos]

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 38

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		
		set @process = 'ALTER SP -- ccspRepAgentGI'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAgentGI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS off
SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action=1 begin

	DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
	SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
	DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

	EXEC @tresRing=ccspConfigTresRing
	EXEC @tresDialog=ccspConfigTresDialog
	EXEC @tresDelayIn=ccspConfigtresDelayIn

	declare @starttime datetime,@number int
	set @starttime = @from
	set @number = 0

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

	CREATE TABLE #times(
	[ID] INT primary key,
	[Start] DATETIME,
	[Stop] DATETIME
	)

	create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on #times([Start] DESC)

	create table #timeDetailAgent(
	[User_id] int null,
	dateStartDetail datetime null,dateEndDetail datetime null,timegroup datetime null,
	timegroup_next datetime null,tunknown int null,
	tnot_av int null,tav int null,tprob int null,
	tother int null,nother int null,tmanualcall int null)

	create table #notReady(
	[Row] int identity primary key,
	dateStartDetail datetime,dateEndDetail datetime,
	timegroup   datetime,timegroup_next datetime,
	[User_id] int,timeNotReady int)

	while @number <= (datediff(mi,@starttime,@to)/15) begin
		   insert into #times
		   select @number,DATEADD(mi, @number*15, @starttime),DATEADD(mi, (@number+1)*15, @StartTime)
		   set @number = @number +1
	end


	-- Session Time
	select sessiontime.user_id as user_id, subLogin as login,subLogout as logout, extension
	into #sessionTime
		   from(
				 select a.extension, a.user_id, a.fecha as 'subLogin',
							   (
							   select isnull(max(Fecha),getdate()) from ccLogLogin b with(nolock) where b.user_id = a.user_id and b.tipomov = 0 and b.fecha >= a.fecha and b.fecha <=
									  (
									  select isnull(min(fecha),'99991231 23:59:59.998') from ccLogLogin with(nolock) where user_id = b.user_id and tipomov = 1 and fecha > a.fecha
									  )
							   ) as 'subLogout'
						from ccLogLogin a where a.tipomov=1 and fecha >= @from and fecha <= @to
		   ) as sessiontime
		   left join ccusers u on (sessiontime.user_id = u.user_id)
		   where u.login is not null
		   order by user_id, login

	--Contabliza el tiempo que exceda las 24hrs
	SELECT TOP 0 * INTO #temp_RepAgentSession FROM #sessionTime
	INSERT INTO #temp_RepAgentSession
	select sessiontime.user_id as user_id, subLogin as login,  subLogout as logout, extension from (
	select a.extension, a.user_id,a.fecha as 'subLogout',
		(
			select isnull(max(b.fecha),getdate()) from ccLogLogin b with(nolock)
				where b.user_id = a.user_id and b.tipomov = 1 and b.fecha <= a.fecha
				and b.fecha >= (
					select isnull(max(fecha),b.fecha) from ccLogLogin with(nolock) where user_id = b.user_id and tipomov = 0 and fecha < a.fecha
					)

				 )  as 'subLogin'
		from ccLogLogin a where a.tipomov=0 and fecha >= @from and fecha <= @to)sessiontime
		left join ccusers u on (sessiontime.user_id = u.user_id)
		where datediff(day,subLogin,subLogout) >= 1
		order by user_id, login

	UPDATE a with (rowlock) set a.logout = b.logout
		   FROM #temp_RepAgentSession b
		   INNER JOIN #sessionTime a on a.user_Id = b.user_Id and a.login = b.login and a.logout <> b.logout

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	select * from (
	SELECT cal_inicio as dateStartDetail,
		   dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
		   case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_inicio,121) + ':00:00.000'
				 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_inicio,121) + ':15:00.000'
		   when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_inicio,121) + ':30:00.000'
		   when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_inicio,121) + ':45:00.000' end as timegroup,
		   case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + ':15:00.000'
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + ':30:00.000'
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + ':45:00.000'
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 45 and 59 then  convert(varchar(13), dateadd(hh,1,cal_Inicio),121) + ':00:00.000' end as timegroup_next
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
		   group by cal_id,[User_id],Inbound_id,cal_inicio,dni_id)inboundData
		   where not(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
		   AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
		   AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
		   AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)


--inserto tiempo de llamada de entrada	
create table #tempFechasI(id int,fecha datetime,tiempo int)
	insert into #tempFechasI select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),GETDATE()) from ccLogAgentesDia where CONVERT(date,fecha)=CONVERT(date, getdate()) AND Tipo=0  group by User_id
	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	select 
		#tempFechasI.fecha as dateStartDetail,
		getdate() as dateEndDetail,
		case when datepart(mi,#tempFechasI.fecha) between 0 and 14 then convert(varchar(13),#tempFechasI.fecha,121) + ':00:00.000'
			when datepart(mi,#tempFechasI.fecha) between 15 and 29 then convert(varchar(13),#tempFechasI.fecha,121) + ':15:00.000'
			when datepart(mi,#tempFechasI.fecha) between 30 and 44 then convert(varchar(13),#tempFechasI.fecha,121) + ':30:00.000'
			when datepart(mi,#tempFechasI.fecha) between 45 and 59 then convert(varchar(13),#tempFechasI.fecha,121) + ':45:00.000' end as timegroup
		,case when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasI.fecha))
			between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasI.fecha),121) + ':15:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasI.fecha))
			between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasI.fecha),121) + ':30:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),0))
			between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasI.fecha),121) + ':45:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasI.fecha))
			between 45 and 59 then  convert(varchar(13),dateadd(hh,1,#tempFechasI.fecha),121) + ':00:00.000' end as timegroup_next
		,#tempFechasI.fecha as time_endque,#tempFechasI.fecha as time_ring
		,GETDATE() as time_dialog,GETDATE() as time_notes,GETDATE() as time_end_call,'' as phone_in
		,ccLogAgentesDia.callID as cal_id,0 as dni_id,IdCampEsp as Inbound_id,User_id,0 as ntotal,0 as ninitial
		,0 as nout_hour,0 as nout_service,0 as nabnd,0 as nno_agent,0 as nque,0 as ntimeout,0 as noverflow
		,0 as nxfer,0 as nxfer_que,0 as nabnd_xfer,0 as nabnd_ring,0 as nno_answer,0 as nabnd_dialog
		,0 as nanswer,0 as nlost,0 as nmsg,0 as nabnd_tres,0 as nansw_tres,0 as tque_max,0 as tque
		,0 as txfer,tiempo as tdialog,0 as tnotes,0 as tring,0 as tresp,0 as nMoh,0 as WHag,0 as nWHcl
		from ccLogAgentesDia JOIN #tempFechasI ON ccLogAgentesDia.fecha=#tempFechasI.fecha WHERE currentStatus in (4,5,9) and Tipo=0 group by #tempFechasI.fecha,IdCampEsp,User_id,tiempo,callID

	drop table #tempFechasI
	
	create table #tempFechasWI(id int,fecha datetime,tiempo int)
	insert into #tempFechasWI select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),GETDATE()) from ccLogAgentesDia where CONVERT(date,fecha)=CONVERT(date, getdate()) AND Tipo=0  group by User_id
	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	select 
		#tempFechasWI.fecha as dateStartDetail,
		getdate() as dateEndDetail,
		case when datepart(mi,#tempFechasWI.fecha) between 0 and 14 then convert(varchar(13),#tempFechasWI.fecha,121) + ':00:00.000'
			when datepart(mi,#tempFechasWI.fecha) between 15 and 29 then convert(varchar(13),#tempFechasWI.fecha,121) + ':15:00.000'
			when datepart(mi,#tempFechasWI.fecha) between 30 and 44 then convert(varchar(13),#tempFechasWI.fecha,121) + ':30:00.000'
			when datepart(mi,#tempFechasWI.fecha) between 45 and 59 then convert(varchar(13),#tempFechasWI.fecha,121) + ':45:00.000' end as timegroup
		,case when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasWI.fecha))
			between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasWI.fecha),121) + ':15:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasWI.fecha))
			between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasWI.fecha),121) + ':30:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),0))
			between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasWI.fecha),121) + ':45:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasWI.fecha))
			between 45 and 59 then  convert(varchar(13),dateadd(hh,1,#tempFechasWI.fecha),121) + ':00:00.000' end as timegroup_next
		,#tempFechasWI.fecha as time_endque,#tempFechasWI.fecha as time_ring
		,GETDATE() as time_dialog,GETDATE() as time_notes,GETDATE() as time_end_call,'' as phone_in
		,ccLogAgentesDia.callID as cal_id,0 as dni_id,IdCampEsp as Inbound_id,User_id,0 as ntotal,0 as ninitial
		,0 as nout_hour,0 as nout_service,0 as nabnd,0 as nno_agent,0 as nque,0 as ntimeout,0 as noverflow
		,0 as nxfer,0 as nxfer_que,0 as nabnd_xfer,0 as nabnd_ring,0 as nno_answer,0 as nabnd_dialog
		,0 as nanswer,0 as nlost,0 as nmsg,0 as nabnd_tres,0 as nansw_tres,0 as tque_max,0 as tque
		,0 as txfer
		,DATEDIFF(ss,(select dateadd(ss,cal_txfer,cal_Xfer) from ccCallsIn where cal_id=callID),#tempFechasWI.fecha) as tdialog,tiempo as tnotes
		,0 as tring,0 as tresp,0 as nMoh,0 as WHag,0 as nWHcl
		from ccLogAgentesDia JOIN #tempFechasWI ON ccLogAgentesDia.fecha=#tempFechasWI.fecha WHERE currentStatus in (6) and Tipo=0 group by #tempFechasWI.fecha,IdCampEsp,User_id,tiempo,callID

	drop table #tempFechasWI
	
	select * into #inboundData2 from #inboundData where datediff(mi,timegroup,timegroup_next)>15
	delete #inboundData where datediff(mi,timegroup,timegroup_next) > 15

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	select dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call
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

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto)
	select * from (
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull(sum(cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		   ,case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_Inicio,121) + ':00:00.000'
				 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_Inicio,121) + ':15:00.000'
		   when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_Inicio,121) + ':30:00.000'
		   when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_Inicio,121) + ':45:00.000' end as timegroup
		   ,case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
		   between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + ':15:00.000'
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
		   between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + ':30:00.000'
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
		   between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + ':45:00.000'
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
		   between 45 and 59 then  convert(varchar(13),dateadd(hh,1,cal_Inicio),121) + ':00:00.000' end as timegroup_next
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
		   ,DATEADD(ss,isnull(sum(cal_twait),0),cal_inicio) as time_endque
		   ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer),0),cal_inicio) as time_ring
		   ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		   ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		   ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		   ,isnull(max(cal_telefono),0) as phone_out,cal_id,cal_puerto
		   FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
		   WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to
		   -- para contar bien las llamadas manuales
		   and cal_manual in(0,2)
		   group by cal_id,[User_id],cam_id,cal_Inicio,cal_puerto)outboundData
		   where not(ntotal=0 AND nno_agent=0 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
				   AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
				   AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0 )
		
--inserto tiempo de llamada de salida
create table #tempFechasO(id int,fecha datetime,tiempo int)
	insert into #tempFechasO select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),GETDATE()) from ccLogAgentesDia where CONVERT(date,fecha)=CONVERT(date, getdate()) AND Tipo=1 group by User_id
	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto)
	select 
		#tempFechasO.fecha as dateStartDetail,
		getdate() as dateEndDetail,
		case when datepart(mi,#tempFechasO.fecha) between 0 and 14 then convert(varchar(13),#tempFechasO.fecha,121) + ':00:00.000'
			when datepart(mi,#tempFechasO.fecha) between 15 and 29 then convert(varchar(13),#tempFechasO.fecha,121) + ':15:00.000'
			when datepart(mi,#tempFechasO.fecha) between 30 and 44 then convert(varchar(13),#tempFechasO.fecha,121) + ':30:00.000'
			when datepart(mi,#tempFechasO.fecha) between 45 and 59 then convert(varchar(13),#tempFechasO.fecha,121) + ':45:00.000' end as timegroup
		,case when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasO.fecha))
			between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasO.fecha),121) + ':15:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasO.fecha))
			between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasO.fecha),121) + ':30:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),0))
			between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasO.fecha),121) + ':45:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasO.fecha))
			between 45 and 59 then  convert(varchar(13),dateadd(hh,1,#tempFechasO.fecha),121) + ':00:00.000' end as timegroup_next
		,IdCampEsp as cam_id,User_id,0 as ntotal,0 as nno_agent
		,0 as nxfer,0 as nabnd_xfer,0 as nabnd_ring,0 as nno_answer,0 as nabnd_dialog
		,0 as nanswer,0 as nlost,0 as tque,0 as txfer,0 as tring,tiempo as tdialog,0 as tnotes
		,0 as tresp,0 as nhangup,0 as nMoh,0 as WHag,0 as nWHcl,#tempFechasO.fecha as time_endque
		,#tempFechasO.fecha as time_ring,GETDATE() as time_dialog,GETDATE() as time_notes
		,GETDATE() as time_end_call,'' as phone_out,ccLogAgentesDia.callID as cal_id,0 
		from ccLogAgentesDia JOIN #tempFechasO ON ccLogAgentesDia.fecha=#tempFechasO.fecha WHERE currentStatus in (4,5,9) and Tipo=1 group by #tempFechasO.fecha,IdCampEsp,User_id,tiempo,callID

	drop table #tempFechasO
	
--inserto tiempo de notas y llamada de salida
create table #tempFechasWO(id int,fecha datetime,tiempo int)
	insert into #tempFechasWO select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),GETDATE()) from ccLogAgentesDia where CONVERT(date,fecha)=CONVERT(date, getdate()) AND Tipo=1  group by User_id
	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto)
	select 
		#tempFechasWO.fecha as dateStartDetail,
		getdate() as dateEndDetail,
		case when datepart(mi,#tempFechasWO.fecha) between 0 and 14 then convert(varchar(13),#tempFechasWO.fecha,121) + ':00:00.000'
			when datepart(mi,#tempFechasWO.fecha) between 15 and 29 then convert(varchar(13),#tempFechasWO.fecha,121) + ':15:00.000'
			when datepart(mi,#tempFechasWO.fecha) between 30 and 44 then convert(varchar(13),#tempFechasWO.fecha,121) + ':30:00.000'
			when datepart(mi,#tempFechasWO.fecha) between 45 and 59 then convert(varchar(13),#tempFechasWO.fecha,121) + ':45:00.000' end as timegroup
		,case when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasWO.fecha))
			between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasWO.fecha),121) + ':15:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasWO.fecha))
			between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasWO.fecha),121) + ':30:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),0))
			between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasWO.fecha),121) + ':45:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasWO.fecha))
			between 45 and 59 then  convert(varchar(13),dateadd(hh,1,#tempFechasWO.fecha),121) + ':00:00.000' end as timegroup_next
		,IdCampEsp as cam_id,User_id,0 as ntotal,0 as nno_agent
		,0 as nxfer,0 as nabnd_xfer,0 as nabnd_ring,0 as nno_answer,0 as nabnd_dialog
		,0 as nanswer,0 as nlost,0 as tque,0 as txfer,0 as tring
		,DATEDIFF(ss,(select cal_Inicio from ccoCallsOut where cal_id=callID),#tempFechasWO.fecha) as tdialog
		,tiempo as tnotes
		,0 as tresp,0 as nhangup,0 as nMoh,0 as WHag,0 as nWHcl,#tempFechasWO.fecha as time_endque
		,#tempFechasWO.fecha as time_ring,GETDATE() as time_dialog,GETDATE() as time_notes
		,GETDATE() as time_end_call,'' as phone_out,ccLogAgentesDia.callID as cal_id,0 
		from ccLogAgentesDia JOIN #tempFechasWO ON ccLogAgentesDia.fecha=#tempFechasWO.fecha WHERE currentStatus in (6) AND Tipo=1 group by #tempFechasWO.fecha,IdCampEsp,User_id,tiempo,callID

	drop table #tempFechasWO
	
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
				 ,phone_out,cal_id,cal_puerto
				 from #outboundData2 t
				 inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
				 where  datediff(ss,th.start,timegroup_next)>0

	insert into #timeDetailAgent
	select [User_id],DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
		   convert(datetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':00:00.000'
				 when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':15:00.000'
				 when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':30:00.000'
				 when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':45:00.000' end) AS timegroup
		   ,convert(datetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + ':15:00.000'
				 when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + ':30:00.000'
				 when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + ':45:00.000'
				 when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + ':00:00.000' end) as timegroup_next
				 ,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE 0 END),0) AS tunknown
				 ,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE 0 END),0) AS tnot_av
				 ,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE 0 END),0) AS tav
				 ,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE 0 END),0) AS tprob
				 ,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE 0 END),0) AS tother
				 ,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
				 ,ISNULL(SUM(CASE WHEN(tipostatusage_id=21)THEN tStatus ELSE 0 END),0) AS tmanualcall
				 --into #timeDetailAgent
		   from ccLogAgentesDia
		   WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
		   GROUP BY
		   convert(datetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':00:00.000'
				 when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':15:00.000'
				 when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':30:00.000'
				 when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':45:00.000' end)
		   ,convert(datetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + ':15:00.000'
				 when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + ':30:00.000'
				 when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + ':45:00.000'
				 when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + ':00:00.000' end), [User_id]

--inserto tiempo READY
create table #tempFechasR(id int,fecha datetime,tiempo int)
	insert into #tempFechasR select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),GETDATE()) from ccLogAgentesDia where CONVERT(date,fecha)=CONVERT(date, getdate()) group by User_id
	insert into #timeDetailAgent(User_id,dateStartDetail,dateEndDetail,timegroup,timegroup_next,tunknown,tnot_av,tav,tprob,tother,nother,tmanualcall)
	select 
		User_id,
		#tempFechasR.fecha as dateStartDetail,
		getdate() as dateEndDetail,
		case when datepart(mi,#tempFechasR.fecha) between 0 and 14 then convert(varchar(13),#tempFechasR.fecha,121) + ':00:00.000'
			when datepart(mi,#tempFechasR.fecha) between 15 and 29 then convert(varchar(13),#tempFechasR.fecha,121) + ':15:00.000'
			when datepart(mi,#tempFechasR.fecha) between 30 and 44 then convert(varchar(13),#tempFechasR.fecha,121) + ':30:00.000'
			when datepart(mi,#tempFechasR.fecha) between 45 and 59 then convert(varchar(13),#tempFechasR.fecha,121) + ':45:00.000' end as timegroup
		,case when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasR.fecha))
			between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasR.fecha),121) + ':15:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasR.fecha))
			between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasR.fecha),121) + ':30:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),0))
			between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasR.fecha),121) + ':45:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasR.fecha))
			between 45 and 59 then  convert(varchar(13),dateadd(hh,1,#tempFechasR.fecha),121) + ':00:00.000' end as timegroup_next
		,0,0,tiempo,0,0,0,0
		from ccLogAgentesDia JOIN #tempFechasR ON ccLogAgentesDia.fecha=#tempFechasR.fecha WHERE currentStatus in (3) group by #tempFechasR.fecha,IdCampEsp,User_id,tiempo,callID

	drop table #tempFechasR
	
--inserto tiempo NOT READY
create table #tempFechasNR(id int,fecha datetime,tiempo int)
	insert into #tempFechasNR select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),GETDATE()) from ccLogAgentesDia where CONVERT(date,fecha)=CONVERT(date, getdate()) group by User_id
	insert into #timeDetailAgent(User_id,dateStartDetail,dateEndDetail,timegroup,timegroup_next,tunknown,tnot_av,tav,tprob,tother,nother,tmanualcall)
	select 
		User_id,
		#tempFechasNR.fecha as dateStartDetail,
		getdate() as dateEndDetail,
		case when datepart(mi,#tempFechasNR.fecha) between 0 and 14 then convert(varchar(13),#tempFechasNR.fecha,121) + ':00:00.000'
			when datepart(mi,#tempFechasNR.fecha) between 15 and 29 then convert(varchar(13),#tempFechasNR.fecha,121) + ':15:00.000'
			when datepart(mi,#tempFechasNR.fecha) between 30 and 44 then convert(varchar(13),#tempFechasNR.fecha,121) + ':30:00.000'
			when datepart(mi,#tempFechasNR.fecha) between 45 and 59 then convert(varchar(13),#tempFechasNR.fecha,121) + ':45:00.000' end as timegroup
		,case when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasNR.fecha))
			between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasNR.fecha),121) + ':15:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasNR.fecha))
			between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasNR.fecha),121) + ':30:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),0))
			between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasNR.fecha),121) + ':45:00.000'
			when datepart(mi,dateadd(ss,isnull(sum(0 + 0 + 0 + tiempo + 0),0),#tempFechasNR.fecha))
			between 45 and 59 then  convert(varchar(13),dateadd(hh,1,#tempFechasNR.fecha),121) + ':00:00.000' end as timegroup_next
		,0,tiempo,0,0,0,0,0
		from ccLogAgentesDia JOIN #tempFechasNR ON ccLogAgentesDia.fecha=#tempFechasNR.fecha WHERE currentStatus in (2) group by #tempFechasNR.fecha,IdCampEsp,User_id,tiempo,callID

	drop table #tempFechasNR


	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15
	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother,tmanualCall)
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
				 ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tmanualCall,dateStartDetail) and  th.stop > dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tmanualCall,dateStartDetail))
							   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
							   when th.start > dateStartDetail and th.start <= dateadd(ss,tmanualCall,dateStartDetail) and  th.stop > dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tmanualCall,dateStartDetail))
							   when th.start > dateStartDetail and th.stop < dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tmanualCall
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	group by th.start,th.stop,[User_id]

	select ROW_NUMBER() OVER(ORDER BY xTimeDetail.timegroup,xTimeDetail.[user_id] ) AS Row,
	xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother,
	isnull(calls.txfer,0) txfer,isnull(tdialog,0) tdialog,isnull(tnotes,0) tnotes,isnull(tring,0) tring,
	isnull(nMoh,0) nMoh,isnull(nWHag,0) nWHag,isnull(nWHcl,0) nWHcl,isnull(tmanualcall,0) tmanualcall,
	isnull((
		--SELECT top 1 DATEDIFF(ss,login,DATEADD(ss,900,xTimeDetail.timegroup)) FROM #sessionTime WHERE [user_id]=xTimeDetail.[user_id]
		--AND login>=xTimeDetail.timegroup AND login<DATEADD(ss,900,xTimeDetail.timegroup) AND logout>=DATEADD(ss,900,xTimeDetail.timegroup)
		SELECT top 1 DATEDIFF(ss,xTimeDetail.timegroup,logout) FROM #sessionTime WHERE [user_id]=xTimeDetail.[user_id]
		AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(ss,900,xTimeDetail.timegroup)
	),0) t1,
	isnull((
		--SELECT top 1 DATEDIFF(ss,login,logout) FROM #sessionTime WHERE [user_id]=xTimeDetail.[user_id]
		--AND login>=xTimeDetail.timegroup  AND login<DATEADD(ss,900,xTimeDetail.timegroup) AND logout<DATEADD(ss,900,xTimeDetail.timegroup)
		--AND login < logout
		SELECT top 1 900 FROM #sessionTime WHERE [user_id]=xTimeDetail.[user_id]
			AND login<=xTimeDetail.timegroup AND logout>DATEADD(ss,900,xTimeDetail.timegroup)
	),0) t2,
	isnull((
		--SELECT top 1 DATEDIFF(ss,xTimeDetail.timegroup ,logout) FROM #sessionTime WHERE [user_id]=xTimeDetail.[user_id]
		--AND login<xTimeDetail.timegroup  AND logout<=DATEADD(ss,900,xTimeDetail.timegroup) AND logout>xTimeDetail.timegroup
		SELECT SUM(DATEDIFF(ss,login,logout)) FROM #sessionTime WHERE [user_id]=xTimeDetail.[user_id]
		AND login>xTimeDetail.timegroup AND logout<DATEADD(ss,900,xTimeDetail.timegroup)
	),0)t3,
	isnull((
		--SELECT top 1 DATEDIFF(ss,xTimeDetail.timegroup ,DATEADD(ss,900,xTimeDetail.timegroup)) FROM #sessionTime
		--WHERE [user_id]=xTimeDetail.[user_id] AND login<xTimeDetail.timegroup  AND logout>DATEADD(ss,900,xTimeDetail.timegroup)
		SELECT top 1 DATEDIFF(ss,login,DATEADD(ss,900,xTimeDetail.timegroup)) FROM #sessionTime WHERE [user_id]=xTimeDetail.[user_id]
		AND login>xTimeDetail.timegroup AND login<DATEADD(ss,900,xTimeDetail.timegroup)AND logout>DATEADD(ss,900,xTimeDetail.timegroup)
	),0)t4
	into #agentInformation
	from(
		select [User_id],min(dateStartDetail) dateStartDetail,min(dateEndDetail) dateEndDetail,timegroup,timegroup_next
			   ,sum(tunknown) as tunknown,sum(tnot_av) as tnot_av,sum(tav) as tav,sum(tprob) as tprob,sum(tother) as tother,sum(nother) as nother, sum(tmanualcall) as tmanualcall
			   from #timeDetailAgent
			   group by timegroup,timegroup_next,user_id
	)xTimeDetail
	full join
	(
		select (case when _in.timegroup is not null then _in.timegroup else _out.timegroup end) timegroup,
			(case when _in.[user_id] is not null then _out.[user_id] else _out.[user_id] end ) [user_id],
			sum(isnull(_in.txfer,0)) + sum(isnull(_out.txfer,0)) txfer,
			sum(isnull(_in.tdialog,0)) + sum(isnull(_out.tdialog,0)) tdialog,
			sum(isnull(_in.tnotes,0)) + sum(isnull(_out.tnotes,0)) tnotes,
			sum(isnull(_in.tring,0)) + sum(isnull(_out.tring,0)) tring,
			sum(isnull(_in.nMoh,0)) + sum(isnull(_out.nMoh,0)) nMoh,
			sum(isnull(_in.nWHag,0)) + sum(isnull(_out.nWHag,0)) nWHag,
			sum(isnull(_in.nWHcl,0)) + sum(isnull(_out.nWHcl,0)) nWHcl
		from
			(select timegroup,[user_id],
			sum(txfer) txfer,sum(tdialog) tdialog,sum(tnotes) tnotes,
			sum(tring) tring,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl
			from #inboundData group by timegroup,[user_id]) _in
			full join
			(select timegroup,[user_id],
			sum(txfer) txfer,sum(tdialog) tdialog,sum(tnotes) tnotes,
			sum(tring) tring,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl
			from #outboundData group by timegroup,[user_id]) _out
		on _in.timegroup=_out.timegroup and _in.[user_id]=_out.[user_id]
		where (case when _in.[user_id] is not null then _out.[user_id] else _out.[user_id] end ) is not null
		and (case when _in.[user_id] is not null then _out.[user_id] else _out.[user_id] end )=2
		group by
		(case when _in.timegroup is not null then _in.timegroup else _out.timegroup end),
		(case when _in.[user_id] is not null then _out.[user_id] else _out.[user_id] end )
	) calls
	on calls.timegroup = xTimeDetail.timegroup and xTimeDetail.[user_id]=calls.[user_id]
	where xTimeDetail.timegroup is not null
	order by  xTimeDetail.[user_id], xTimeDetail.timegroup

	insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,timeNotReady)
	SELECT DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
		convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':00:00.000'
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':15:00.000'
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':30:00.000'
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':45:00.000' end) AS timegroup
		,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + ':15:00.000'
				when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + ':30:00.000'
				when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + ':45:00.000'
				when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + ':00:00.000' end) as timegroup_next
				,[User_id],SUM(tStatus) as [timeNotReady]
		FROM ccLogAgentesNotReady
		WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to
	GROUP BY
		convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':00:00.000'
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':15:00.000'
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':30:00.000'
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + ':45:00.000' end)
		,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + ':15:00.000'
				when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + ':30:00.000'
				when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + ':45:00.000'
				when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + ':00:00.000' end), [User_id]

	select * into #notReady2 from #notReady where datediff(mi,timegroup,timegroup_next)>15
	delete #notReady where datediff(mi,timegroup,timegroup_next) > 15

	insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,timeNotReady)
	select min(dateStartDetail),min(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
	,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,timeNotReady,dateStartDetail))
					when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
					when th.start > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,dateadd(ss,timeNotReady,dateStartDetail))
					when th.start > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as timeNotReady
	from #notReady2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	group by th.start,th.stop,[User_id]

	select
	ROW_NUMBER() OVER(ORDER BY
						CASE WHEN agtInf.timegroup IS NOT NULL THEN agtInf.timegroup WHEN calls.timegroup IS NOT NULL  THEN calls.timegroup ELSE 0 END,
						CASE WHEN agtInf.user_id IS NOT NULL THEN agtInf.user_id WHEN calls.userId IS NOT NULL THEN calls.userId ELSE - 1 END
					) AS id,
	agtInf.[row] rowAgentInformation,
	isnull(#notReady.Row,-1) as rowNotReady
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
	,ISNULL(agtInf.t1, 0)+ISNULL(agtInf.t2, 0)+ISNULL(agtInf.t3, 0)+ISNULL(agtInf.t4, 0)  AS tlog
	--,ISNULL(dbo.#notReady.timeNotReady, 0) AS treq
	,ISNULL(agtInf.tav, 0) AS tav
	,ISNULL(agtInf.tother, 0) + isnull(tmanualcall,0) AS tother
	,ISNULL(agtInf.tprob, 0) AS tprob

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
	left join ccusers u ON agtInf.[user_id] = u.[user_id]
	left join #notReady ON agtInf.[user_id] = #notReady.[user_id] AND #notReady.timegroup = agtInf.timegroup
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


	SELECT
		   RANK() OVER(PARTITION BY rowAgentInformation ORDER by id) as [rank],
		   ROW_NUMBER() OVER(Order by id) as rowNumber,id
		   into #tempTime
		   FROM #tempRepAgentGI
		   where rowAgentInformation in
				 (select rowAgentInformation from #tempRepAgentGI temp GROUP BY temp.rowAgentInformation HAVING Count(*) > 1 )

	update t set nother=0,tunknown=0,tnotav=0,tlog=0,tother=0,tprob=0,tav=0
		   from #tempRepAgentGI t     inner join #tempTime temp on t.id = temp.id
		   where [rank]>1

	delete #tempTime

	insert into #tempTime
	SELECT
	RANK() OVER(PARTITION BY rowNotReady ORDER by id) as [rank],
	ROW_NUMBER() OVER(Order by id) as rowNumber,id
	FROM #tempRepAgentGI
	where rowNotReady in
		   (select rowNotReady from #tempRepAgentGI temp GROUP BY temp.rowNotReady HAVING Count(*) > 1 )

	--update t set treq=0
	--	   from #tempRepAgentGI t inner join #tempTime temp on t.id = temp.id
	--	   where [rank]>1

	delete #tempTime

	insert into #tempTime
	SELECT
		   RANK() OVER(PARTITION BY rowIn ORDER by id) as [rank],
		   ROW_NUMBER() OVER(Order by id) as rowNumber,id
		   FROM #tempRepAgentGI
		   where rowIn in
				 (select rowIn from #tempRepAgentGI temp GROUP BY temp.rowIn HAVING Count(*) > 1 )

	update t
		   set nxferin=0,nanswerin=0,nabndxferin=0,nabndringin=0,nabnddlgin=0,abndaxferin=0,nnoanswerin=0
						,nlostin=0,tdialogin=0,tnotesin=0,tringin=0,txferin=0,nMohin=0,nWHagin=0,nWHcliin=0
		   from #tempRepAgentGI t
		   inner join #tempTime temp on t.id = temp.id
		   where [rank]>1

	delete #tempTime

	insert into #tempTime
	SELECT
	RANK() OVER(PARTITION BY rowOut ORDER by id) as [rank],
	ROW_NUMBER() OVER(Order by id) as rowNumber,
	id
	FROM #tempRepAgentGI
	where rowOut in
		   (select rowOut from #tempRepAgentGI temp GROUP BY temp.rowOut HAVING Count(*) > 1 )

	update t
		   set nxferout=0,nanswerout=0,nabndxferout=0,nabndringout=0,nabnddlgout=0,abndaxferout=0,nnoanswerout=0,nlostout=0,tdialogout=0
						,tnotesout=0,tringout=0,txferout=0,nMohout=0,nWHagout=0,nWHcliout=0
		   from #tempRepAgentGI t
		   inner join #tempTime temp on t.id = temp.id
		   where [rank]>1

	delete from RepAgentGI with(rowlock) where date >= @from AND date < @to
	--update #tempRepAgentGI set tlog = 0 where tdialogout = 0 and tlog > 0

	

	insert into RepAgentGI(date,userId,[user],login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,--treq,
			tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotavg)
	select date,userId,isnull([user],'otro'),isnull(login,'otro'),nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,--treq,
				tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotav
	 from #tempRepAgentGI

	 
	---DROP TABLES TEMP
	drop table #sessionTime
	drop table #times
	drop table #temp_RepAgentSession
	drop table #inboundData
	drop table #inboundData2
	drop table #outboundData
	drop table #outboundData2
	drop table #timeDetailAgent
	drop table #timeDetailAgent2
	drop table #notReady
	drop table #notReady2
	drop table #agentInformation
	drop table #tempTime
	drop table #tempRepAgentGI


end'
		EXEC(@Sql)


		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
		set @actualVersion = @version
		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
if @actualVersion = @version begin
	begin tran
	begin try

	commit tran
	end try

	begin catch

	/* Error generated based on sintax */
	select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch
end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off