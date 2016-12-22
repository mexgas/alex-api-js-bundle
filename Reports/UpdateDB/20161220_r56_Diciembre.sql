/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2016/12/20
Description:
	Se modifica ccspGenOutCall por correcion de reporte en tiempo real

Database: ccReportsRia
Required version: 53

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 55

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version
	begin
		begin tran
		begin try


		set @process = ''
		set @Sql= ''
		EXEC(@Sql)

		set @process = 'Alter SP -- ccspGenOutCall'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspGenOutCall]
@from AS smalldatetime,
@to AS smalldatetime
AS

declare @dateNow datetime
DECLARE @HourExtend AS smallint
SELECT @HourExtend=2
DECLARE @fromExtended AS smalldatetime
SELECT @fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog

declare @starttime datetime,@number int
set @starttime =convert(varchar(13), @from,121) + '':00:00.000''
set @number = 0
set @dateNow =getdate()

CREATE TABLE #times(
[ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
create nonclustered index ix_times2 on #times([Start] DESC)

create table #outboundData(
row int identity,cam_id int,[User_id] int,dateStartDetail datetime,dateEndDetail datetime,timegroup datetime,timegroup_next datetime,
ntotal int,nno_agent int,nxfer int,nabnd_xfer int,nabnd_ring int,nno_answer int,nabnd_dialog int,nanswer int,nlost int,
tque int
,txfer int,tring int,tdialog int,tnotes int,tresp int,nhangup int,
nMoh int,nWHag int,nWHcl int,time_endque datetime,time_ring datetime,time_dialog datetime,
	time_notes datetime,time_end_call datetime,cal_id int)

--Tiempo ultimo Status del agente llamadas de Salida
create table #tempFechasO(id int,fecha datetime,tiempo int)

while @number <= (datediff(mi,@starttime,@to)/60) begin
		   insert into #times
		   select @number,DATEADD(mi, @number*60, @starttime),DATEADD(mi, (@number+1)*60, @StartTime)
		   set @number = @number +1
	end

create nonclustered index iX_CamUserId on #outboundData([cam_id] DESC,[User_id] DESC)

insert into #outboundData(
dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,user_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,
nanswer,nlost,tque,txfer,tring ,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
,time_endque,time_ring,time_dialog,time_notes,time_end_call,cal_id
)
select cal_Inicio AS dateStartDetail, DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,0),cal_Inicio) AS dateEndDetail,
convert(varchar(13),cal_Inicio,121) + '':00:00.000'' as timegroup,
--convert(varchar(13),cal_Inicio,121) + '':00:00.000'' as timegroup_next
	convert(varchar(13),
		DATEADD(ss,isnull((cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),dateadd(hh,1,cal_Inicio)
		)
		,121)  + '':00:00.000''
	 timegroup_next
, cam_id ,[User_id],1 as ntotal
,ISNULL((CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0) AS nno_agent
,ISNULL((CASE WHEN(statuscall_id>=10)THEN 1 ELSE NULL END),0) AS nxfer
,ISNULL((CASE WHEN(statuscall_id=11)THEN 1 ELSE NULL END),0) AS nabnd_xfer
,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END),0) AS nabnd_ring
,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),0) AS nno_answer
,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN 1 ELSE NULL END),0) AS nabnd_dialog
,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) AS nanswer
,ISNULL((CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0) AS nlost
,ISNULL((0),0) as tque
,ISNULL((cal_txfer),0)AS txfer
,isnull((cal_tring),0) as tring
,isnull((cal_tdialog),0) as tdialog
,isnull((cal_tnotas),0) as tnotes
,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
,ISNULL((CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0) AS nhangup
,ISNULL((CASE WHEN cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL((CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag
,ISNULL((CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
,DATEADD(ss,isnull((0),0),cal_inicio) as time_endque
,DATEADD(ss,isnull((0 + cal_txfer),0),cal_inicio) as time_ring
,DATEADD(ss,isnull((0 + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
,cal_id
FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to
-- para contar bien las llamadas manuales
and cal_manual in(0,2)


--inserto tiempo de llamada de salida
insert into #tempFechasO select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),@dateNow) from ccLogAgentesDia where CONVERT(varchar(11),fecha,121)=CONVERT(varchar(11),@dateNow,121)  group by User_id

update C
set C.dateEndDetail=@dateNow
,C.timegroup_next=
case when @dateNow=CONVERT(smalldatetime,CONVERT(varchar(13),@dateNow,121)+ '':00'',121) then CONVERT(smalldatetime,CONVERT(varchar(13),@dateNow,121)+ '':00'',121)
else CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(hh,1,@dateNow),121)+ '':00'',121) end
,C.time_dialog= case when A.currentStatus in (4,5,9) then @dateNow when A.TipoStatusAge_id=4 then B.fecha else C.dateStartDetail end
,C.time_notes=@dateNow
,C.time_end_call=@dateNow
,C.tdialog= case when A.currentStatus in (4,5,9) then B.tiempo when A.TipoStatusAge_id=4 then DATEDIFF(ss,C.dateStartDetail,B.fecha) else 0 end
,C.tnotes= case when A.currentStatus = 6 then B.tiempo else 0 end
from ccLogAgentesDia A
inner JOIN #tempFechasO B ON A.fecha=B.fecha and A.User_id=B.id
inner join #outboundData C on A.callID=C.cal_id
WHERE currentStatus in (4,5,6,9) and A.Tipo=1




select * into #outboundData2 from #outboundData where datediff(mi,timegroup,timegroup_next)>60
delete #outboundData where datediff(mi,timegroup,timegroup_next) > 60


insert into #outboundData(
dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,user_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,
nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
,time_endque,time_ring,time_dialog,time_notes,time_end_call
)
	select dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,user_id,
	ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,
	tque,txfer,tring,
	tdialog
	,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
,time_endque,time_ring,time_dialog,time_notes,time_end_call
	 from(
	select
		 dateStartDetail,dateEndDetail,th.start timegroup,th.stop timegroup_next,
		 cam_id,[User_id]
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
			   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,dateadd(ss,-1,th.stop))
			   when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
			   when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque
		 ,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
			   when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,dateadd(ss,-1,th.stop))
			   when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
			   when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer
		 ,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
			   when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,dateadd(ss,-1,th.stop))
			   when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
			   when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring
		 ,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
			   when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,dateadd(ss,-1,th.stop))
			   when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
			   when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop)
			   else  0 end as tdialog

		 ,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
			   when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,dateadd(ss,-1,th.stop))
			   when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
			   when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
		 ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tresp,dateStartDetail))
			   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
			   when th.start > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tresp,dateStartDetail))
			   when th.start > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end as tresp
		 --conteo
		 ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nhangup else 0 end as nhangup
		 ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		 ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		 ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
		  ,time_endque,time_ring,time_dialog,time_notes,time_end_call
		 from #outboundData2 t
		 inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		 where  datediff(ss,th.start,timegroup_next)>0
		 )X

DELETE FROM ccGenOutCall WHERE timegroup>=@from AND timegroup<=@to

INSERT INTO ccGenOutCall(timegroup,cam_id,[user_id]
	,ntotal,nno_agent,nxfer
	,nabnd_xfer,nabnd_ring,nno_answer
	,nabnd_dialog,nanswer,nlost
	,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl)
select  timegroup,cam_id,user_id
	,sum(ntotal) as ntotal,sum(nno_agent) as nno_agent,sum(nxfer) as nxfer,sum(nabnd_xfer) as nabnd_xfer,sum(nabnd_ring) as nabnd_ring,sum(nno_answer) as nno_answer,sum(nabnd_dialog) as nabnd_dialog
	,sum(nanswer) as nanswer,sum(nlost) as nlost
	,sum(txfer) as txfer,sum(tring) as tring,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(tresp) as tresp,sum(nhangup) as nhangup,sum(nMoh) as nMoh,sum(nWHag) as nWHag,sum(nWHcl) as nWHcl
	from #outboundData
	group by timegroup,cam_id,user_id
	--ORDER BY timegroup,cam_id,[user_id]

 drop table #times
 drop table #outboundData
 drop table #outboundData2
 drop table #tempFechasO'
		EXEC(@Sql)

		set @process = ''
		set @Sql= ''
		EXEC(@Sql)



			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			--exec ccsp_getVersion 'BD', @version

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