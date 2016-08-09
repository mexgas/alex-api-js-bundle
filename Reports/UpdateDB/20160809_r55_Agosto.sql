/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/* 
Author: Jesus Gallardo
Date: 2014/08/08
Description:
	

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

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

			/* Start script release */
			set @process = 'ADD Column ccGenAgent.tunknown2'
			set @sql='if not exists (select * from sys.columns where name = N''ccGenAgent'' and Object_ID = Object_ID(N''tunknown2''))
    begin
       ALTER TABLE ccGenAgent ADD tunknown2 int
    end'
			EXEC(@sql)

			set @process = 'Alter view -- ccGenViewAgent'
			set @sql='ALTER VIEW [dbo].[ccGenViewAgent]
AS
SELECT        CASE WHEN ccGEnAgent.timegroup IS NOT NULL THEN ccGEnAgent.timegroup WHEN ccGenViewIncall.timegroup IS NOT NULL THEN ccGenViewIncall.timegroup WHEN ccGenViewOutcall.timegroup IS NOT NULL 
    THEN ccGenViewOutcall.timegroup ELSE 0 END AS timegroup, CASE WHEN ccGEnAgent.user_id IS NOT NULL THEN ccGEnAgent.user_id WHEN ccGenViewIncall.user_id IS NOT NULL 
    THEN ccGenViewIncall.user_id WHEN ccGenViewOutcall.user_id IS NOT NULL THEN ccGenViewOutcall.user_id ELSE - 1 END AS user_id, ISNULL(dbo.ccGenViewInCall.nxfer, 0) AS nxfer_in, 
    ISNULL(dbo.ccGenViewInCall.nanswer, 0) AS nanswer_in, ISNULL(dbo.ccGenViewInCall.nabnd_xfer, 0) AS nabnd_xfer_in, ISNULL(dbo.ccGenViewInCall.nabnd_ring, 0) AS nabnd_ring_in, 
    ISNULL(dbo.ccGenViewInCall.nabnd_dialog, 0) AS nabnd_dlg_in, ISNULL(dbo.ccGenViewInCall.nabnd_xfer, 0) + ISNULL(dbo.ccGenViewInCall.nabnd_ring, 0) + ISNULL(dbo.ccGenViewInCall.nabnd_dialog, 0) 
    AS abnd_a_xfer_in, ISNULL(dbo.ccGenViewInCall.nno_answer, 0) AS nno_answer_in, ISNULL(dbo.ccGenViewInCall.nlost, 0) AS nlost_in, ISNULL(dbo.ccGenViewInCall.tdialog, 0) AS tdialog_in, 
    ISNULL(dbo.ccGenViewInCall.tnotes, 0) AS tnotes_in, ISNULL(dbo.ccGenViewInCall.tring, 0) AS tring_in, ISNULL(dbo.ccGenViewInCall.txfer, 0) AS txfer_in, ISNULL(dbo.ccGenViewOutCall.nxfer, 0) AS nxfer_out, 
    ISNULL(dbo.ccGenViewOutCall.nanswer, 0) AS nanswer_out, ISNULL(dbo.ccGenViewOutCall.nabnd_xfer, 0) AS nabnd_xfer_out, ISNULL(dbo.ccGenViewOutCall.nabnd_ring, 0) AS nabnd_ring_out, 
    ISNULL(dbo.ccGenViewOutCall.nabnd_dialog, 0) AS nabnd_dlg_out, ISNULL(dbo.ccGenViewOutCall.nabnd_xfer, 0) + ISNULL(dbo.ccGenViewOutCall.nabnd_ring, 0) + ISNULL(dbo.ccGenViewOutCall.nabnd_dialog, 0) 
    AS abnd_a_xfer_out, ISNULL(dbo.ccGenViewOutCall.nno_answer, 0) AS nno_answer_out, ISNULL(dbo.ccGenViewOutCall.nlost, 0) AS nlost_out, ISNULL(dbo.ccGenViewOutCall.tdialog, 0) AS tdialog_out, 
    ISNULL(dbo.ccGenViewOutCall.tnotes, 0) AS tnotes_out, ISNULL(dbo.ccGenViewOutCall.tring, 0) AS tring_out, ISNULL(dbo.ccGenViewOutCall.txfer, 0) AS txfer_out, ISNULL(dbo.ccGenAgent.nother, 0) AS nother, 
    ISNULL(dbo.ccGenAgent.tunknown, 0) AS tunknown, ISNULL(dbo.ccGenAgent.tnot_av, 0) AS tnot_av, ISNULL(dbo.ccGenAgent.tlog, 0) AS tlog, ISNULL(dbo.ccGenAgent.treq, 0) AS treq, ISNULL(dbo.ccGenAgent.tav, 
    0) AS tav, ISNULL(dbo.ccGenAgent.tother, 0) AS tother, ISNULL(dbo.ccGenAgent.tprob, 0) AS tprob, ISNULL(dbo.ccGenViewInCall.nMoh, 0) AS nMoh_in, ISNULL(dbo.ccGenViewOutCall.nMoh, 0) AS nMoh_out, 
    ISNULL(dbo.ccGenViewInCall.nWHag, 0) AS nWHag_in, ISNULL(dbo.ccGenViewOutCall.nWHag, 0) AS nWHag_out, ISNULL(dbo.ccGenViewInCall.nWHcl, 0) AS nWHcl_in, ISNULL(dbo.ccGenViewOutCall.nWHcl, 0) 
    AS nWHcl_out, ISNULL(dbo.ccGenAgent.tmanualcall, 0) AS tmanualcall,ISNULL(dbo.ccGenAgent.tunknown2, 0) AS tunknown2
FROM            dbo.ccGenAgent FULL OUTER JOIN
    dbo.ccGenViewInCall ON dbo.ccGenViewInCall.timegroup = dbo.ccGenAgent.timegroup AND dbo.ccGenViewInCall.user_id = dbo.ccGenAgent.user_id FULL OUTER JOIN
    dbo.ccGenViewOutCall ON dbo.ccGenViewOutCall.timegroup = dbo.ccGenAgent.timegroup AND dbo.ccGenViewOutCall.user_id = dbo.ccGenAgent.user_id'
			EXEC(@sql)

			set @process = 'Alter SP -- ccspGenAgent'
			set @sql='ALTER PROCEDURE [dbo].[ccspGenAgent]
@from AS smalldatetime,
@to AS smalldatetime
AS


declare @starttime datetime,@number int
set @starttime = @from
set @number = 0


CREATE TABLE #times([ID] INT primary key, [Start] DATETIME,	[Stop] DATETIME	)

create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
create nonclustered index ix_times2 on #times([Start] DESC)

while @number <= (datediff(mi,@starttime,@to)/60) begin
   insert into #times
   select @number,DATEADD(mi, @number*60, @starttime),DATEADD(mi, (@number+1)*60, @StartTime)
   set @number = @number +1
end

create table #tempccLogAgentesDia(
	row int not null,user_id int not null,TipoStatusAge_id tinyint not null,
	tStatus int not null,dateIni datetime not null,dateEnd datetime not null
)

create table #timeDetailAgent(	
	[User_id] int not null,
	dateStartDetail datetime null,dateEndDetail datetime null,dateNext datetime null
	,timegroup datetime null,
	timegroup_next datetime null,tunknown int null,
	tnot_av int null,tav int null,tprob int null,
	tother int null,nother int null,tmanualcall int null,
	tunknown2 decimal(10,3) 
	)

insert into #tempccLogAgentesDia(row,[User_id],TipoStatusAge_id,tStatus,dateIni,dateEnd)
select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY fecha) AS Row,User_id,
TipoStatusAge_id,tStatus,DATEADD(ss,-tStatus,fecha) dateIni, fecha dateEnd from ccLogAgentesDia 
WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to 
---and User_id in(3455)

insert into #timeDetailAgent
select A.user_id,A.dateIni,A.dateEnd,S.dateIni dateNext,
	CONVERT(smalldatetime,CONVERT(varchar(13),A.dateIni,121)+ '':00'',121) AS timegroup,
	CONVERT(smalldatetime,CONVERT(varchar(13),A.dateEnd,121)+ '':00'',121) AS timegroup_next,
	case when A.tipostatusage_id=1 then A.tStatus else 0 end tunknown,
	case when A.tipostatusage_id=2 then A.tStatus else 0 end tnot_av,
	case when A.tipostatusage_id=3 then A.tStatus else 0 end tav,
	case when A.tipostatusage_id=11 then A.tStatus else 0 end tprob,
	case when A.tipostatusage_id=7 then A.tStatus else 0 end tother,
	case when A.tipostatusage_id=7 then 1 else 0 end nother,
	case when A.tipostatusage_id=21 then A.tStatus else 0 end tmanualcall,
	isnull(
	cast(		
		case when A.TipoStatusAge_id=1 and S.TipoStatusAge_id=9 then 0 
		when A.TipoStatusAge_id = S.TipoStatusAge_id then 0
	 else 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  end as decimal(10,3)) 
	,0)	as tunknown2		
	
	from #tempccLogAgentesDia A
	left join #tempccLogAgentesDia S on A.Row=S.Row-1 and A.user_id=S.user_id	
	WHERE  A.dateIni>=@from AND A.dateIni<@to	    

	update A set tunknown2=0  from #timeDetailAgent A 
	left join ccGenSession B on A.User_id=B.user_id	and B.login<=A.dateEndDetail and B.logout>A.dateNext
	where B.login is null		

	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(hh,timegroup,timegroup_next)>1
	delete #timeDetailAgent where datediff(hh,timegroup,timegroup_next) > 1	
	
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

DELETE ccGenAgent with(rowlock) WHERE timegroup>=@from AND timegroup<@to
INSERT INTO ccGenAgent(timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl,tmanualCall,tunknown2)

SELECT timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl,tmanualCall,tunknown2
FROM(
	SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
		,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring + tmanualCall) AS ttot,nMoh,nWHag,nWHcl,tmanualCall,
		tunknown2
	 FROM(
		SELECT 
			xTimeDetail.timegroup
			,xTimeDetail.[user_id],
			sum(tnot_av) as tnot_av
			,sum(tav) as tav,sum(tprob) as tprob,sum(tother) as tother, sum(tunknown) as tunknown,
			sum(nother) as nother
			,ISNULL(SUM(ccGenViewInCall.txfer),0)+ ISNULL(SUM(ccGenViewOutCall.txfer),0)as txfer
			,ISNULL(SUM(ccGenViewInCall.tdialog),0)+ ISNULL(SUM(ccGenViewOutCall.tdialog),0)as tdialog
			,ISNULL(SUM(ccGenViewInCall.tnotes),0)+ ISNULL(SUM(ccGenViewOutCall.tnotes),0)as tnotes
			,ISNULL(SUM(ccGenViewInCall.tring),0)+ ISNULL(SUM(ccGenViewOutCall.tring),0)as tring
			,ISNULL(SUM(ccGenViewInCall.nMoh),0)+ ISNULL(SUM(ccGenViewOutCall.nMoh),0)as nMoh
			,ISNULL(SUM(ccGenViewInCall.nWHag),0)+ ISNULL(SUM(ccGenViewOutCall.nWHag),0)as nWHag
			,ISNULL(SUM(ccGenViewInCall.nWHcl),0)+ ISNULL(SUM(ccGenViewOutCall.nWHcl),0)as nWHcl
			,sum(tmanualCall) as tmanualCall,sum(tunknown2) as tunknown2
	
			,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
						 FROM ccGenSession --with(nolock, index(IX_ccGenSession))
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t1
			,ISNULL((SELECT top 1 3600
						 FROM ccGenSession --with(nolock, index(IX_ccGenSession))
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t2
			,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
						 FROM ccGenSession --with(nolock, index(IX_ccGenSession))
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t3
			,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
						 FROM ccGenSession --with(nolock, index(IX_ccGenSession))
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t4
		
		 FROM(
			select 
				min(dateStartDetail) as dateStartDetail,max(dateEndDetail) as dateEndDetail,timegroup,User_id,
				sum(tunknown) as tunknown, sum(tnot_av) as tnot_av,sum(tav) as tav,sum(tprob) as tprob,sum(tother) as tother,
				sum(nother) as nother,sum(tmanualCall) as tmanualCall,sum(tunknown2) as tunknown2
			 from #timeDetailAgent
			 group by timegroup,User_id						 
			)xTimeDetail
			LEFT OUTER JOIN ccGenViewInCall ON(xTimeDetail.timegroup=ccGenViewInCall.timegroup AND xTimeDetail.[user_id]=ccGenViewInCall.[user_id])
			LEFT OUTER JOIN ccGenViewOutCall ON(xTimeDetail.timegroup=ccGenViewOutCall.timegroup AND xTimeDetail.[user_id]=ccGenViewOutCall.[user_id])
			GROUP BY xTimeDetail.timegroup, xTimeDetail.[user_id]			
 		)xDetail
)xAllTimes
WHERE tlog>0
ORDER BY timegroup,[user_id]


drop table #tempccLogAgentesDia
drop table #times
drop table #timeDetailAgent
drop table #timeDetailAgent2'
			EXEC(@sql)

			set @process = 'Alter SP -- ccspGenOutCall'
			set @sql='ALTER PROCEDURE [dbo].[ccspGenOutCall]
@from AS smalldatetime,
@to AS smalldatetime
AS


DECLARE @HourExtend AS smallint
SELECT @HourExtend=2
DECLARE @fromExtended AS smalldatetime
SELECT @fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog

declare @starttime datetime,@number int
set @starttime = @from
set @number = 0

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
	time_notes datetime,time_end_call datetime)

while @number <= (datediff(mi,@starttime,@to)/60) begin
		   insert into #times
		   select @number,DATEADD(mi, @number*60, @starttime),DATEADD(mi, (@number+1)*60, @StartTime)
		   set @number = @number +1
	end

create nonclustered index iX_CamUserId on #outboundData([cam_id] DESC,[User_id] DESC)

insert into #outboundData(
dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,user_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,
nanswer,nlost,tque,txfer,tring ,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
,time_endque,time_ring,time_dialog,time_notes,time_end_call
)
select cal_Inicio AS dateStartDetail, DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,0),cal_Inicio) AS dateEndDetail,
convert(varchar(13),cal_Inicio,121) + '':00:00.000'' as timegroup,
convert(varchar(13),
	DATEADD(ss,isnull((cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),DATEADD(HH,1,cal_Inicio)) 
	,121) + '':00:00.000'' as timegroup_next	
, cam_id ,[User_id],1 as ntotal
,ISNULL((CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0) AS nno_agent
,ISNULL((CASE WHEN(statuscall_id>=10)THEN 1 ELSE NULL END),0) AS nxfer
,ISNULL((CASE WHEN(statuscall_id=11)THEN 1 ELSE NULL END),0) AS nabnd_xfer
,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END),0) AS nabnd_ring
,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),0) AS nno_answer
,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN 1 ELSE NULL END),0) AS nabnd_dialog
,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) AS nanswer
,ISNULL((CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0) AS nlost
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

FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to 
-- para contar bien las llamadas manuales
and cal_manual in(0,2) 
 --)  outboundData 
--where  not(ntotal=0 AND nno_agent=0 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
--	AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
--	AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0 )



select * into #outboundData2 from #outboundData where datediff(mi,timegroup,timegroup_next)>60
delete #outboundData where datediff(mi,timegroup,timegroup_next) > 60
	
	
insert into #outboundData(
dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,user_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,
nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
,time_endque,time_ring,time_dialog,time_notes,time_end_call
)
	select dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,user_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,
nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
,time_endque,time_ring,time_dialog,time_notes,time_end_call
	 from(
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
		 --Tiempos		 
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
				
DELETE FROM ccGenOutCall WHERE timegroup>=@from AND timegroup<@to

INSERT INTO ccGenOutCall(timegroup,cam_id,[user_id]
	,ntotal,nno_agent,nxfer
	,nabnd_xfer,nabnd_ring,nno_answer
	,nabnd_dialog,nanswer,nlost
	,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl)
select timegroup,cam_id,user_id
	,sum(ntotal) as ntotal,sum(nno_agent) as nno_agent,sum(nxfer) as nxfer,sum(nabnd_xfer) as nabnd_xfer,sum(nabnd_ring) as nabnd_ring,sum(nno_answer) as nno_answer,sum(nabnd_dialog) as nabnd_dialog
	,sum(nanswer) as nanswer,sum(nlost) as nlost--,SUM(tque)as tque
	,sum(txfer) as txfer,sum(tring) as tring,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(tresp) as tresp,sum(nhangup) as nhangup,sum(nMoh) as nMoh,sum(nWHag) as nWHag,sum(nWHcl) as nWHcl 	
	from #outboundData		
	group by timegroup,timegroup_next,cam_id,user_id
	 ORDER BY timegroup,cam_id,[user_id]

 drop table #times
 drop table #outboundData
 drop table #outboundData2	'
			EXEC(@sql)

			set @process = 'Alter SP -- ccspGenSession'
			set @sql='ALTER PROCEDURE [dbo].[ccspGenSession]
@from as smalldatetime,
@to as smalldatetime
AS
set nocount on


CREATE TABLE #tempccGenSession(
	[fila] int NOT NULL,
	[user_id] [smallint] NOT NULL,
	[login] [datetime] NOT NULL,
	[logout] [datetime] NULL,
	[extension] [varchar](7) NOT NULL,
	primary key (fila,user_id)	
)

CREATE TABLE #temUserIdLogoutNull([user_id] [smallint] NOT NULL)
CREATE TABLE #temIdMaxLogoutNull([fila] int NOT NULL,[user_id] [smallint] NOT NULL,primary key (fila,user_id))


insert into #tempccGenSession
select Actual.Fila, Actual.User_id,Actual.fecha login,Siguiente.fecha logout,Actual.Extension
from (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,* from ccLogLogin a where fecha >= @from	and fecha <= @to --and user_id=@userId
)Actual
left join (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,* from ccLogLogin a where fecha >= @from	and fecha <= @to --and user_id=@userId
) Siguiente
on Actual.Fila=Siguiente.Fila-1 and Actual.User_id=Siguiente.User_id and Actual.TipoMov=1 and Siguiente.TipoMov=0 -- and Actual.fecha<Siguiente.fecha 
where Actual.TipoMov=1
order by login

insert into #temUserIdLogoutNull
select user_id from #tempccGenSession where logout is null group by user_id


insert into #temIdMaxLogoutNull
select A.fila,A.user_id from #tempccGenSession A 
inner join (
select max(fila) fila,user_id from #tempccGenSession where user_id in( select user_id from #temUserIdLogoutNull ) group by user_id)B
	on A.fila=B.fila and A.user_id=B.user_id
	where A.logout is null


update A set A.logout=GETDATE() from #tempccGenSession A
inner join #temIdMaxLogoutNull B on A.user_id=B.user_id and A.fila=B.fila

update A set A.logout=DATEADD(ms,10,A.login) from #tempccGenSession A where logout is null

delete  from ccGenSession with(rowlock) where login >= @from and login<@to

insert into ccGenSession
select user_id,[login],[logout],extension from #tempccGenSession



SELECT TOP 0 * INTO #temp_ccGenSession FROM ccGenSession

INSERT INTO #temp_ccGenSession ([user_id], extension, login, logout)
select user_id, ext, login, logout
from(select a.user_id, max(Extension) as ext, a.fecha as ''logout'',
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
		) as ''login''
		from ccLogLogin a
		where a.tipomov=0
		and fecha >= @from
		and fecha <= @to
		group by a.user_id, a.fecha) as sessiontime
		where datediff(day,login,logout) >= 1
order by user_id, login

UPDATE a with (ROWLOCK)
SET a.logout = b.logout
FROM #temp_ccGenSession b
INNER JOIN ccGenSession a
on a.user_id = b.user_id
and a.login = b.login
and a.logout <> b.logout

DROP TABLE #temp_ccGenSession
drop table #tempccGenSession
drop table #temUserIdLogoutNull
drop table #temIdMaxLogoutNull


return(0)
set nocount off
'
			EXEC(@sql)

			set @process = ''
			set @sql=''
			EXEC(@sql)
			
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