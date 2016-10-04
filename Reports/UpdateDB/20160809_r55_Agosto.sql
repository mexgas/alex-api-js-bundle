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

if @actualVersion = @version
	begin
		begin tran
		begin try

			
			set @process = 'Adding currentStatus column to ccLogAgentesDia '
		set @Sql= 'if not exists (select * from sys.columns where name = N''currentStatus'' and Object_ID = Object_ID(N''ccLogAgentesDia'')) ALTER TABLE ccLogAgentesDia ADD currentStatus int'
		EXEC(@Sql)

		set @process = 'Adding callID column to ccLogAgentesDia '
		set @Sql= 'if not exists (select * from sys.columns where name = N''callID'' and Object_ID = Object_ID(N''ccLogAgentesDia'')) ALTER TABLE ccLogAgentesDia ADD callID int'
		EXEC(@Sql)

		set @process = 'ADD Column ccGenAgent.tunknown2'
		set @sql='if not exists (select * from sys.columns where name = N''tunknown2'' and Object_ID = Object_ID(N''ccGenAgent'')) ALTER TABLE ccGenAgent ADD tunknown2 int'
		EXEC(@sql)

		set @process = 'update Columns Sheduller'
		set @sql='update exportReports set cols=''User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus, callID'' where jobId=8'
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

declare @dateNow datetime
declare @starttime datetime,@number int
set @dateNow=getdate()
set @starttime = CONVERT(smalldatetime,CONVERT(varchar(13),@from,121)+ '':00'',121)
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
	tStatus int not null,dateIni datetime not null,dateEnd datetime not null,
	currentStatus int
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


create table #tempFechasR(id int,fecha datetime,tiempo int)

select * into #tempccGenSession from ccGenSession where login>=@from and login<@to

insert into #tempccLogAgentesDia(row,[User_id],TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus)
select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY DATEADD(ss,-tStatus,fecha)) AS Row,User_id,
TipoStatusAge_id,tStatus,DATEADD(ss,-tStatus,fecha) dateIni, fecha dateEnd,currentStatus
from ccLogAgentesDia 
WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to 
--and User_id in(4512)

delete A from(
	select case when A.tStatus>S.tStatus then S.row else A.row end row,A.user_id
	from #tempccLogAgentesDia A
	left join #tempccLogAgentesDia S on A.Row=S.Row-1 and A.user_id=S.user_id	
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id=S.TipoStatusAge_id
	and (S.dateEnd between A.dateIni and A.dateEnd or S.dateIni between A.dateIni and A.dateEnd)
	and abs(DATEDIFF(ss,A.dateEnd,S.dateIni))>2
	)x
inner join 	#tempccLogAgentesDia A on A.row=x.row and A.user_id=x.user_id

select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY dateIni) AS Row,User_id,
TipoStatusAge_id,tStatus,dateIni, dateEnd
	 into #tempccLogAgentesDia2 
from #tempccLogAgentesDia

insert into #timeDetailAgent
select A.user_id,A.dateIni,A.dateEnd,S.dateIni dateNext,
	CONVERT(smalldatetime,CONVERT(varchar(13),A.dateIni,121)+ '':00'',121) AS timegroup,
	case when A.dateEnd=CONVERT(smalldatetime,CONVERT(varchar(13),A.dateEnd,121)+ '':00'',121) then CONVERT(smalldatetime,CONVERT(varchar(13),A.dateEnd,121)+ '':00'',121)
	else CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(hh,1,A.dateEnd),121)+ '':00'',121) end AS timegroup_next,
	case when A.tipostatusage_id=1 then A.tStatus else 0 end tunknown,
	case when A.tipostatusage_id=2 then A.tStatus else 0 end tnot_av,
	case when A.tipostatusage_id=3 then A.tStatus else 0 end tav,
	case when A.tipostatusage_id in(11,25,26,27) then A.tStatus else 0 end tprob,--11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida
	case when A.tipostatusage_id=7 then A.tStatus else 0 end tother,
	case when A.tipostatusage_id=7 then 1 else 0 end nother,
	case when A.tipostatusage_id=21 then A.tStatus else 0 end tmanualcall,
	case when abs(isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) )>A.tStatus then 0 
	when A.TipoStatusAge_id=25 and S.TipoStatusAge_id=5 or A.TipoStatusAge_id=5 and S.TipoStatusAge_id=25  then 0
	when S.TipoStatusAge_id=1 then 0
	else isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) end	as tunknown2	
	from #tempccLogAgentesDia2 A
	left join #tempccLogAgentesDia2 S on A.Row=S.Row-1 and A.user_id=S.user_id	
	WHERE  A.dateIni>=@from AND A.dateIni<@to				
	
	update #timeDetailAgent set tunknown2=0  where tunknown2>2.5


	insert into #tempFechasR select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),@dateNow) from ccLogAgentesDia where CONVERT(varchar(11),fecha,121)=CONVERT(varchar(11),@dateNow,121) group by User_id

	
	insert into #timeDetailAgent(User_id,dateStartDetail,dateEndDetail,timegroup,timegroup_next,tunknown,tnot_av,tav,tprob,tother,nother,tmanualcall)
	select 
		User_id,
		B.fecha as dateStartDetail,
		@dateNow as dateEndDetail,
		CONVERT(smalldatetime,CONVERT(varchar(13),B.fecha,121)+ '':00'',121) AS timegroup,
		case when @dateNow=CONVERT(smalldatetime,CONVERT(varchar(13),@dateNow,121)+ '':00'',121) then CONVERT(smalldatetime,CONVERT(varchar(13),@dateNow,121)+ '':00'',121)
		else CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(hh,1,@dateNow),121)+ '':00'',121) end AS timegroup_next
		,case when currentStatus=1 then tiempo else 0 end as tunknown,
		case when currentStatus=2 then tiempo else 0 end as tnot_av,
		case when currentStatus=3 then tiempo else 0 end as tav,
		 0,0,0,0
		from #tempccLogAgentesDia A
		inner JOIN #tempFechasR B ON A.fecha=B.fecha WHERE currentStatus in (1,2,3)	


	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(hh,timegroup,timegroup_next)>1
	delete #timeDetailAgent where datediff(hh,timegroup,timegroup_next) > 1		


	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother,tmanualCall)
	select
	 min(dateStartDetail),min(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
	 ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tunknown,dateStartDetail))
				   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,-1,th.stop))
				   when th.start > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tunknown,dateStartDetail))
				   when th.start > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tunknown
	 ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail))
				   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,-1,th.stop))
				   when th.start > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnot_av,dateStartDetail))
				   when th.start > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tnot_av
	 ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
				   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,-1,th.stop))
				   when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
				   when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
	 ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tprob,dateStartDetail))
				   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,-1,th.stop))
				   when th.start > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tprob,dateStartDetail))
				   when th.start > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tprob
	 ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
				   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,-1,th.stop))
				   when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
				   when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
	 ,isnull(sum(case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
	 ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tmanualCall,dateStartDetail) and  th.stop > dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tmanualCall,dateStartDetail))
				   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,-1,th.stop))
				   when th.start > dateStartDetail and th.start <= dateadd(ss,tmanualCall,dateStartDetail) and  th.stop > dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tmanualCall,dateStartDetail))
				   when th.start > dateStartDetail and th.stop < dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tmanualCall
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	group by th.start,th.stop,[User_id]
							

SELECT timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl,tmanualCall,cast(round(tunknown2,0) as int)tunknown2,0 as treq
into #tempccGenAgent
FROM(
	SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
		,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring + tmanualCall) AS ttot,nMoh,nWHag,nWHcl,tmanualCall,
		tunknown2
	 FROM(
		SELECT 
			xTimeDetail.timegroup--,xTimeDetail.timegroup_next
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
						 FROM #tempccGenSession --with(nolock, index(IX_ccGenSession))
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t1
			,ISNULL((SELECT top 1 3600
						 FROM #tempccGenSession --with(nolock, index(IX_ccGenSession))
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login<=xTimeDetail.timegroup AND logout>=DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t2
			,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
						 FROM #tempccGenSession --with(nolock, index(IX_ccGenSession))
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login>xTimeDetail.timegroup AND logout<=DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t3
			,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
						 FROM #tempccGenSession --with(nolock, index(IX_ccGenSession))
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t4
		
		 FROM(						
			select User_id,timegroup
				,case when sum(tunknown2)>0 then sum(tunknown+tunknown2) else sum(tunknown) end as tunknown
				,case when sum(tnot_av2)>0 then sum(tnot_av+tnot_av2) else sum(tnot_av) end as tnot_av
				,case when sum(tav2)>0 then sum(tav+tav2) else sum(tav) end as tav
				,case when sum(tprob2)>0 then sum(tprob+tprob2) else sum(tprob) end as tprob
				,case when sum(tother2)>0 then sum(tother+tother2) else sum(tother) end as tother
				,case when sum(tmanualcall2)>0 then sum(tmanualcall+tmanualcall2) else sum(tmanualcall) end as tmanualcall
				,sum(nother) as nother
				--,sum(tunknown2Other) as tunknown2Other,
				,0 as tunknown2
					from(
				select User_id,timegroup
				,tunknown,tnot_av,tav,tprob,tother,tmanualcall,nother
				,cast(case when tunknown>0 then tunknown2 else 0 end as int) as tunknown2
				,cast(case when tnot_av>0 then tunknown2 else 0 end as int) as tnot_av2
				,cast(case when tav>0 then tunknown2 else 0 end as int) as tav2
				,cast(case when tprob>0 then tunknown2 else 0 end as int) as tprob2
				,cast(case when tother>0 then tunknown2 else 0 end as int) as tother2
				,cast(case when tmanualcall>0 then tunknown2 else 0 end as int) as tmanualcall2
				--,cast(case when tunknown=0 and tnot_av=0 and tav=0 and tprob=0 and tother=0 and tmanualcall=0 then tunknown2 else 0 end as int) as tunknown2Other
				from #timeDetailAgent 	
				)x
				group by timegroup,User_id					
					 
			)xTimeDetail
			LEFT OUTER JOIN ccGenViewInCall ON(xTimeDetail.timegroup=ccGenViewInCall.timegroup AND xTimeDetail.[user_id]=ccGenViewInCall.[user_id])
			LEFT OUTER JOIN ccGenViewOutCall ON(xTimeDetail.timegroup=ccGenViewOutCall.timegroup AND xTimeDetail.[user_id]=ccGenViewOutCall.[user_id])
			GROUP BY xTimeDetail.timegroup, xTimeDetail.[user_id]			
 		)xDetail
)xAllTimes
WHERE tlog>0
ORDER BY timegroup,[user_id]
			 
DELETE ccGenAgent with(rowlock) WHERE timegroup>=@from AND timegroup<@to
INSERT INTO ccGenAgent(timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl,tmanualCall,tunknown2,treq)

select timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl,tmanualCall,tunknown2,treq from #tempccGenAgent 


drop table #tempccLogAgentesDia
drop table #times
drop table #timeDetailAgent
drop table #timeDetailAgent2
drop table #tempccGenAgent
drop table #tempccLogAgentesDia2
drop table #tempccGenSession
drop table #tempFechasR'
			EXEC(@sql)

			set @process = 'Alter SP -- ccspGenOutCall'
			set @sql='ALTER PROCEDURE [dbo].[ccspGenOutCall]
@from AS smalldatetime,
@to AS smalldatetime
AS
--declare @from datetime,@to datetime
--set @from=''2016-08-13 01:32:00''
--set @to =DATEADD(hh,24,@from)

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
	time_notes datetime,time_end_call datetime)

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
,time_endque,time_ring,time_dialog,time_notes,time_end_call
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

FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to 
-- para contar bien las llamadas manuales
and cal_manual in(0,2) 


--inserto tiempo de llamada de salida
insert into #tempFechasO select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),@dateNow) from ccLogAgentesDia where CONVERT(varchar(11),fecha,121)=CONVERT(varchar(11),@dateNow,121) AND Tipo=1 group by User_id

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
			EXEC(@sql)

			set @process = 'Alter SP -- ccspGenSession'
			set @sql='ALTER PROCEDURE [dbo].[ccspGenSession]
@from as smalldatetime,
@to as smalldatetime
AS
set nocount on

--declare @from AS smalldatetime,@to AS smalldatetime
--select  @from=''2016-08-24 03:00:00'',@to=''2016-08-25 03:00:00''

declare @date datetime
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
select A.Fila, A.User_id,A.fecha login,S.fecha logout,A.Extension
from (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,User_id,Extension,TipoMov,fecha--convert(varchar(19),fecha,121) fecha 
from ccLogLogin a where fecha >= @from and fecha <= @to
)A
left join (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,User_id,Extension,TipoMov,fecha from ccLogLogin a where fecha >= @from	and fecha <= @to 
) S
on A.Fila=S.Fila-1 and A.User_id=S.User_id and A.TipoMov=1 and S.TipoMov=0
where A.TipoMov=1 --and A.User_id in(3754)
order by login


update x  set x.fila = x.row
from(
	select fila, ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY login) row from #tempccGenSession
)x
	

insert into #temUserIdLogoutNull
select user_id from #tempccGenSession where logout is null group by user_id


insert into #temIdMaxLogoutNull
select A.fila,A.user_id from #tempccGenSession A 
inner join (
select max(fila) fila,user_id from #tempccGenSession where user_id in( select user_id from #temUserIdLogoutNull ) group by user_id)B
	on A.fila=B.fila and A.user_id=B.user_id
	where A.logout is null

set @date=GETDATE()
update A set A.logout=case when @to<@date then @to else @date end from #tempccGenSession A
inner join #temIdMaxLogoutNull B on A.user_id=B.user_id and A.fila=B.fila


update A set A.logout =
	(select case when  max(fecha) is not null then max(fecha) when DATEDIFF(ss,A.login,B.login)<2 then DATEADD(ms,-10,B.login) else DATEADD(ms,5,A.login) end from ccLogAgentesDia C where A.user_Id=C.User_id and fecha between A.login and B.login ) --logout,
 from #tempccGenSession A 
left join #tempccGenSession B on A.fila=B.fila-1  and A.user_id=B.user_id
where A.logout is null 


delete from #tempccGenSession where login=logout

delete A
from #tempccGenSession A
inner join
(
select user_id,convert(varchar(19),[login],121)[login],convert(varchar(19),logout,121)logout  from #tempccGenSession 
group by user_id,convert(varchar(19),[login],121),convert(varchar(19),logout,121) having count(*)>1
) B
on A.user_id=B.user_id and convert(varchar(19), A.login,121) =B.login and convert(varchar(19), A.logout,121)=B.logout


delete  from ccGenSession with(rowlock) where login >= @from and login<=	@to

insert into ccGenSession
--select user_id,convert(varchar(19),[login],121)  [login],convert(varchar(19),dateadd(ss,1,[logout]),121),extension from #tempccGenSession
select user_id, dateadd(ss,-1,[login]),convert(varchar(19),dateadd(ss,1,[logout]),121),extension from #tempccGenSession


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


--return(0)
--set nocount off
'
			EXEC(@sql)

			set @process = 'Alter SP -- ccspGenInCall'
			set @sql='ALTER PROCEDURE [dbo].[ccspGenInCall]
@from AS smalldatetime,
@to AS smalldatetime
AS
set nocount on
set ansi_nulls off 
set ANSI_WARNINGS off

declare @dateNow datetime

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

create table [#callsin](
row int identity,dateStartDetail datetime,dateEndDetail datetime,timegroup datetime,timegroup_next datetime,
time_endque datetime,time_ring datetime,time_dialog datetime,time_notes datetime,time_end_call datetime,phone_in varchar(30),
cal_id int,dni_id int,Inbound_id int,User_id int,ntotal int,ninitial int,nout_hour int,nout_service int,nabnd int,nno_agent int,
nque int,ntimeout int,noverflow int,nxfer int,nxfer_que int,nabnd_xfer int,nabnd_ring int,nno_answer int,nabnd_dialog int,nanswer int,
nlost int,nmsg int,nabnd_tres int,nansw_tres int,tque_max int,tque int,txfer int,tdialog int,tnotes int,tring int,tresp int,nMoh int,
nWHag int,nWHcl int)

declare @starttime datetime,@number int
set @starttime =convert(varchar(13), @from,121) + '':00:00.000''
set @number = 0
set @dateNow=getdate()


CREATE TABLE #times(
[ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
create nonclustered index ix_times2 on #times([Start] DESC)

--Tiempo ultimo Status del agente llamadas de entrada
create table #tempFechasI(id int,fecha datetime,tiempo int)

while @number <= (datediff(mi,@starttime,@to)/60) begin
		insert into #times
		select @number,DATEADD(mi, @number*60, @starttime),DATEADD(mi, (@number+1)*60, @StartTime)
		set @number = @number +1
end

--inserto tiempo de llamada de entrada	
insert into #tempFechasI 
select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),@dateNow) from ccLogAgentesDia where CONVERT(varchar(11),fecha,121)=CONVERT(varchar(11),@dateNow,121) AND Tipo=0  group by User_id


insert into #callsin(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal
,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer
,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl
)
SELECT   case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end as dateStartDetail,
		dateadd(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,
			case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end )
			dateEndDetail,
		--dateadd(ss,isnull((cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
		convert(varchar(13),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ,121) + '':00:00.000'' as timegroup,
	 convert(datetime,	convert(varchar(13),
			DATEADD(ss,isnull((cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),dateadd(hh,1,
			case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end
			)
			) 
		,121)  + '':00:00.000''
		)  timegroup_next
		,DATEADD(ss,isnull((cal_twait),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end) as time_endque
		,DATEADD(ss,isnull((cal_twait + cal_txfer),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end) as time_ring
		,DATEADD(ss,isnull((cal_twait + cal_txfer + cal_tring),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end) as time_dialog
		,DATEADD(ss,isnull((cal_twait + cal_txfer + cal_tring + cal_tdialog),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end) as time_notes
		,DATEADD(ss,isnull((cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end) as time_end_call
		,cal_Ani as phone_in,cal_id,cin.dni_id,Inbound_id,[User_id]            
		,1 AS ntotal
		,ISNULL((CASE WHEN statuscall_id=1 THEN 1 ELSE 0 END),0) AS ninitial
		,ISNULL((CASE WHEN statuscall_id=2 THEN 1 ELSE 0 END),0) AS nout_hour
		,ISNULL((CASE WHEN statuscall_id=3 THEN 1 ELSE 0 END),0) AS nout_service
		,ISNULL((CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nabnd
		,ISNULL((CASE WHEN(statuscall_id=4)THEN 1 ELSE 0 END),0) AS nno_agent
		,ISNULL((CASE WHEN(cal_que>0)THEN 1 ELSE NULL END),0) AS nque
		,ISNULL((CASE WHEN(statuscall_id=7)THEN 1 ELSE 0 END),0) AS ntimeout
		,ISNULL((CASE WHEN(statuscall_id=8)THEN 1 ELSE 0 END),0) AS noverflow
		,ISNULL((CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nxfer
		,ISNULL( (CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN 1 ELSE 0 END),0) AS nxfer_que
		,ISNULL((CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nabnd_xfer
		,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE 0 END),0) AS nabnd_ring
		,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE 0 END),0) AS nno_answer
		,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE 0 END),0) AS nabnd_dialog
		,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE 0 END),0) AS nanswer
		,ISNULL((CASE WHEN(statuscall_id=16)THEN 1 ELSE 0 END),0) AS nlost
		,ISNULL((CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE 0 END),0) AS nmsg
		,ISNULL((CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE 0 END),0) AS nabnd_tres
		,ISNULL((CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nansw_tres
		,ISNULL((cal_twait),0)AS tque_max,ISNULL((cal_twait),0)AS tque,ISNULL((cal_txfer),0)AS txfer
		,ISNULL((cal_tdialog),0)AS tdialog,ISNULL((cal_tnotas),0)AS tnotes,ISNULL((cal_tring),0)AS tring
		,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
		,ISNULL((case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
		,ISNULL((CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL((CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl           
		FROM ccCallsIn cin with (nolock, index(IX_ccCallsIn))
		left join ccdnis dnis on dnis.dni_id = cin.dni_id
		WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0		
		--and cin.user_id=5193

delete #callsin WHERE timegroup>=@from AND timegroup<@to AND INBOUND_ID>0
AND ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0   

---Actualiza las llamadas
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
	inner JOIN #tempFechasI B ON A.fecha=B.fecha and A.User_id=B.id
	inner join #inboundData C on A.callID=C.cal_id
	WHERE currentStatus in (4,5,6,9) and A.Tipo=0 	


select * into #callsin2 from #callsin where datediff(hh,timegroup,timegroup_next)>1
delete #callsin where datediff(hh,timegroup,timegroup_next) > 1

insert into #callsin(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)     
select
		dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,th.stop as timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call                                
		,phone_in,cal_id,t.dni_id,Inbound_id,[User_id]
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
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,dateadd(ss,-1,th.stop))
				when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
				when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque         
		,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
				when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,dateadd(ss,-1,th.stop))
				when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
				when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer,
		case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
				when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,dateadd(ss,-1,th.stop))
				when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
				when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tdialog
		,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
				when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,dateadd(ss,-1,th.stop))
				when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
				when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
		,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
				when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,dateadd(ss,-1,th.stop))
				when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
				when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring              
		,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tresp,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tresp,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end as tresp                                                                      
		,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl               
		from #callsin2 t
		join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		left join ccdnis dnis on dnis.dni_id = t.dni_id 
		where  datediff(ss,th.start,timegroup_next)>0
		order by cal_id  

				
DELETE FROM ccGenInCall WHERE timegroup>=@from AND timegroup<=@to


INSERT INTO ccGenInCall(timegroup,inbound_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque
,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg
,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
select A.timegroup,A.Inbound_id,A.User_id,sum(A.ntotal) ntotal,sum(A.nout_hour) nout_hour,sum(A.nout_service) nout_service
,sum(A.nabnd) nabnd,sum(A.nno_agent) nno_agent,sum(A.nque) nque,sum(A.ntimeout) ntimeout,sum(A.noverflow) as noverflow
,sum(A.nxfer) nxfer,sum(A.nxfer_que) nxfer_que,sum(A.nabnd_xfer) nabnd_xfer,sum(A.nabnd_ring) nabnd_ring,sum(A.nno_answer) nno_answer
,sum(A.nabnd_dialog) nabnd_dialog
,sum(A.nanswer) nanswer,sum(A.nlost) nlost,sum(A.nmsg) nmsg,sum(A.nabnd_tres) nabnd_tres,sum(A.nansw_tres) nansw_tres
,max(A.tque_max) tque_max,sum(A.tque) tque,sum(A.txfer) txfer
,sum(A.tring) tring,sum(A.tdialog) tdialog,sum(A.tnotes) tnotes,sum(A.tresp) tresp,sum(A.ninitial) ninitial,sum(A.nMoh) nMoh,sum(A.nWHag) nWHag
,sum(A.nWHcl) nWHcl
 from #callsin A 
 group by A.timegroup,A.Inbound_id,A.User_id 
 


drop table #times		
drop table #callsin
drop table #callsin2
drop table #tempFechasI'
			EXEC(@sql)

			set @process = 'Alter SP -- ccspGenAgentStatusNotReady'
			set @sql='ALTER PROCEDURE [dbo].[ccspGenAgentStatusNotReady]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenAgentNotReady WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenAgentNotReady (timegroup, [user_id], tiponotready_id, amount, [time], amountReal)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121) AS timegroup
	, [user_id], tiponotready_id
	, COUNT(tStatus), SUM(tStatus)
	, sum( case when separado in (0,3) then 1 else null end ) --amount Real
 FROM ccLogAgentesNotReady
 WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121), [user_id], tiponotready_id

 
INSERT INTO ccGenAgentNotReady (timegroup, [user_id], tiponotready_id, amount, [time], amountReal)
select A.timegroup,A.user_id,0 as tiponotready_id,0 amount,0 time,0 amountReal from ccGenAgent A
left join (select timegroup,user_id from ccGenAgentNotReady where timegroup>=@from and timegroup<=@to group by timegroup,USER_ID) B on A.timegroup=B.timegroup and A.user_id=B.user_id 
where A.timegroup>=@from and A.timegroup<=@to
and B.timegroup is null
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