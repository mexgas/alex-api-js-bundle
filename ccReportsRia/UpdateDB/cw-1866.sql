/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author:Mike Trejo
Date: 2018/06/22
Description:
**********************************************************************************************
CW-1866  - Resumen de intervalo de tiempos acumulados totales
**********************************************************************************************
Database: ccReportsRia
Required version: 51


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =52
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try

	set @process = 'CW-1866 '
    	set @Sql= 'if exists (select * from sys.procedures where name = N''ccspRepMKTIntervalosTiemposAcuTotales'')
    begin
        DROP PROCEDURE ccspRepMKTIntervalosTiemposAcuTotales;
    end'
	EXEC(@sql)

	set @process = 'CW-1866 '
    	set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepMKTIntervalosTiemposAcuTotales]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = convert(datetime,convert(varchar(11),getdate()))

declare @dateNow datetime,@maxLogout datetime

if @action = 1
begin
delete from [RepMKTIntervalosTiemposAcuTotales] with(rowlock) 
	where date >= @from AND date <= @to 

	CREATE TABLE #sessionTime(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL)
	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)
	CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)
	CREATE TABLE #sessionTimeMayores([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)
	CREATE TABLE #hold ([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,call_id int not null,inbound_id int not null,  marca int not null, Tipo_marca int not null,
					Tipo_llamada int not null,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL, [time_dialog] [datetime] not null,[time_notes] [datetime] not null
					,[time_hold] [datetime] not null)
	CREATE TABLE #tempccHoldSession([fila] int NOT NULL,[call_id] [smallint] NOT NULL,[inbound_id] [int] NOT NULL,[hold] [datetime] NOT NULL,[unhold] [datetime] NULL,[Tipo_marca] [int] not null
				,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL primary key (fila,call_id)			)
	CREATE TABLE #holdMayores2 (call_id int not null, inbound_id int not null,  hold [datetime] not null , [unhold] [datetime] not null,Tipo_marca int not null,tiempoHold int not null,
					[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)
	CREATE TABLE #inbound([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,[cal_id] [int] NOT NULL,[LlamadasRecibidas] [int] NOT NULL, nacd int,nabnd int,
				tacd int,nacw int,tacw int,[txfer] int,[SalExt] int,tprosalext int,nhold int,nserv int,nring int, tring int, thold int,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
				,[dateTResp] datetime,[dateTRing] datetime,[dateTACD] datetime
				,[dateTTransferStart] datetime,[dateTTransferEnd] datetime
				,userId int
				)
	CREATE TABLE #inboundTimeMayores([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,[cal_id] [int] NOT NULL,[LlamadasRecibidas] [int] NOT NULL, nacd int,
				nabnd int,tacd int,nacw int,tacw int,[txfer] int,[SalExt] int,tprosalext int,nhold int,nserv int,nring int, tring int,  thold int, [timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
				,[dateTResp] datetime,[dateTRing] datetime,[dateTACD] datetime
				,[dateTTransferStart] datetime,[dateTTransferEnd] datetime
				,userId int
				)
	create table #tempccLogAgentesDia(row int not null,user_id int not null,[IdCampEsp] [int] not null,[callId] [int]not null,TipoStatusAge_id tinyint not null,tStatus int not null,dateIni datetime not null,dateEnd datetime not null,currentStatus int)
	create table #timeDetailAgent([User_id] int null,[IdCampEsp][int] not null,[callId][int] not null,dateStartDetail datetime null,dateEndDetail datetime null,timegroup datetime null,	timegroup_next datetime null,tunknown int null,tnot_av int null,tav int null,tprob int null,tother int null,nother int null,tmanualcall int null,tunknown2 decimal(10,3),tlogout int,tcliente int ,tchatting int null,[PromPosicionPersonal] [numeric](18, 1) NULL,)
	create table #tempAgentLastStatus(id int,fecha datetime,tiempo int)


	create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on #times([Start] DESC)

	insert into #times
	exec ccspTimesReports @from=@from,@to=@to,@interval=15
	INSERT INTO #sessionTime
	exec ccspGenSession @from, @to	
	INSERT INTO #sessionTimeGroup
	select st.[user_id],[login],logout,dbo.GetTimeGroup([login],0) as timeGroup,dbo.GetTimeGroup(logout,1) as timeGroupNext,DATEDIFF(ss,[login],logout) as tlog, wg.IdCampEsp from #sessionTime st
		Inner Join ccriaworkgroupusers wgu ON st.User_id = wgu.User_id
		Inner Join ccRIACampEspWG wg ON wg.IDWG = WGU.IDWG
	where wg.Tipo = 0 		
	INSERT into #sessionTimeMayores 
	SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
	delete #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
		
	insert into #sessionTimeGroup
	select [User_id],[login],logout, th.[start] as timegroup,th.[stop] as timegroup_next,
		[dbo].TimeInterval( th.[start],th.[stop] ,[login],logout) as [tlog seg],inb_id
	from #sessionTimeMayores t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0		

-------------------HOLD PROCESS-------------------
insert into #hold
	select 
		cal_Inicio as [dateStart],
		dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio) as [dateEnd]
		,cal_id as cal_id,
		inbound_id as inbound_id,
		isnull(h.marca,0) as Marca,
		case when (h.tipo_marca>0) then h.tipo_marca else 0 end as Tipo_marca,
		isnull(tipo_llamada,0) as Tipo_llamada
		,dbo.GetTimeGroup(cal_Inicio,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio),1) as timegroup_next
		,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring,0),cal_inicio) as time_dialog
		,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog,0),cal_inicio) as time_notes
		,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + marca,0),cal_Inicio) as time_hold
		
	from cccallsin i (nolock) 
	left join RiaMarkHold h (nolock) on i.cal_id=h.call_id and h.tipo_llamada=1
	where cal_Inicio between @from and @to 
select * from #hold
insert into #tempccHoldSession
select A.Fila, A.call_id
,a.inbound_id
,A.time_hold hold,
isnull(S.time_hold,a.time_notes) unhold,
a.Tipo_marca Tipo_marca
,a.timegroup timegroup
,a.timegroup_next timegroup_next
from (select ROW_NUMBER() OVER(PARTITION BY call_id ORDER BY time_hold,tipo_marca) Fila,call_id,inbound_id,marca,tipo_marca,tipo_llamada,time_hold,time_notes,timegroup,timegroup_next
from #hold a where time_hold >= @from and time_hold <= @to
)A
left join (select ROW_NUMBER() OVER(PARTITION BY call_id ORDER BY time_hold,tipo_marca) Fila,call_id,inbound_id,marca,tipo_marca,tipo_llamada,time_hold,time_notes,timegroup,timegroup_next
from #hold a where time_hold >= @from	and time_hold <= @to
) S
on A.Fila=S.Fila-1 and A.call_id=S.call_id and A.tipo_marca=1 and S.tipo_marca=0
where A.tipo_llamada=1 
order by hold


select 
	ths.call_id,
	ths.inbound_id,
	ths.hold,
	ths.unhold,
	ths.Tipo_marca,
	[dbo].TimeInterval( th.[start],th.[stop],ths.hold ,ths.unhold) as tiempohold,
	ths.timegroup,
	ths.timegroup_next
	into #tiempoHold
 from #tempccHoldSession ths
 inner join #times th on (ths.timegroup > th.Start and ths.timegroup < th.stop) OR th.Start between ths.timegroup and ths.timegroup_next
 where [dbo].TimeInterval( th.[start],th.[stop],ths.hold ,ths.unhold)>0 and Tipo_marca=1
 INSERT into #holdMayores2 SELECT * from #tiempoHold where datediff(mi,timegroup,timegroup_next)>15 
	delete #tiempoHold where  datediff(mi,timegroup,timegroup_next)>15	

insert into #tiempoHold
	select DISTINCT  call_id,
		inbound_id,
		hold,
		unhold,
		Tipo_marca,
		[dbo].TimeInterval( th.[start],th.[stop],hold ,unhold) as tiempohold,
		th.[start] as timegroup,
		th.[stop] as timegroup_next
	from #holdMayores2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop ) OR th.Start between t.timegroup and t.timegroup_next
	where [dbo].TimeInterval( th.[start],th.[stop],hold ,unhold)>0 
select 
inbound_id,
sum(tiempohold) tiempohold,
timegroup,
timegroup_next
 into #timeHoldInterval from #tiempoHold where tiempoHold>0 and Tipo_marca=1
 group by inbound_id,timegroup,Tipo_marca,timegroup_next
 ---------------------FINAL HOLD PROCESS----------------------
---------------------oRows---------------------

insert into #tempccLogAgentesDia(row,[User_id],[IdCampEsp],[callId],TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus)
	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY DATEADD(ss,-tStatus,fecha)) AS Row,User_id,IdCampEsp,callID,
	TipoStatusAge_id,tStatus,DATEADD(ss,-tStatus,fecha) dateIni, fecha dateEnd, isnull(currentStatus,-2)
	from ccLogAgentesDia
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
	delete A from(
	select case when A.tStatus>S.tStatus then S.row else A.row end row,A.user_id,a.IdCampEsp,a.callId
	from #tempccLogAgentesDia A
	left join #tempccLogAgentesDia S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id=S.TipoStatusAge_id
	and (S.dateEnd between A.dateIni and A.dateEnd or S.dateIni between A.dateIni and A.dateEnd)
	and abs(DATEDIFF(ss,A.dateEnd,S.dateIni))>2
	)x
	inner join 	#tempccLogAgentesDia A on A.row=x.row and A.user_id=x.user_id

	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY dateIni) AS Row,User_id,IdCampEsp,callId,TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus into #tempccLogAgentesDia2 from #tempccLogAgentesDia

	insert into #timeDetailAgent
	select A.user_id,A.IdCampEsp,A.callId,A.dateIni,A.dateEnd
	,convert(datetime,case when datepart(mi,A.dateIni) between 0 and 14 then convert(varchar(13),A.dateIni,121) + '':00:00.000''
			when datepart(mi,A.dateIni) between 15 and 29 then convert(varchar(13),A.dateIni,121) + '':15:00.000''
			when datepart(mi,A.dateIni) between 30 and 44 then convert(varchar(13),A.dateIni,121) + '':30:00.000''
			when datepart(mi,A.dateIni) between 45 and 59 then convert(varchar(13),A.dateIni,121) + '':45:00.000'' end) AS timegroup
	,convert(datetime,case when datepart(mi,A.dateEnd) between 0 and 14 then convert(varchar(13),A.dateEnd,121) + '':15:00.000''
			when datepart(mi,A.dateEnd) between 15 and 29 then convert(varchar(13),A.dateEnd,121) + '':30:00.000''
			when datepart(mi,A.dateEnd) between 30 and 44 then convert(varchar(13),A.dateEnd,121) + '':45:00.000''
			when datepart(mi,A.dateEnd) between 45 and 59 then convert(varchar(13),dateadd(hh,1,A.dateEnd),121) + '':00:00.000'' end) as timegroup_next,
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
	,isnull(case when A.TipoStatusAge_id=0 then A.tStatus end,0) tlogout
	,isnull(case when A.TipoStatusAge_id=8 then A.tStatus end,0) tcliente	
	,case when A.tipostatusage_id in (23,24) then A.tStatus else 0 end  as tchatting
	,0.0 [PromPosicionPersonal]
	from #tempccLogAgentesDia2 A
	left join #tempccLogAgentesDia2 S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id<>0

	update #timeDetailAgent set tunknown2=0  where abs(tunknown2)>2.7

insert into #timeDetailAgent(User_id,IdCampEsp,callId,dateStartDetail,dateEndDetail,timegroup,timegroup_next,tunknown,tnot_av,tav,tprob,tother,nother,tmanualcall,tunknown2,tlogout,tcliente,tchatting)
	 select
	 	User_id,
		IdCampEsp,
		callId,
	 	B.fecha as dateStartDetail,
	 	@dateNow as dateEndDetail,
	 	case when datepart(mi,B.fecha) between 0 and 14 then convert(varchar(13),B.fecha,121) + '':00:00.000''
	 		when datepart(mi,B.fecha) between 15 and 29 then convert(varchar(13),B.fecha,121) + '':15:00.000''
	 		when datepart(mi,B.fecha) between 30 and 44 then convert(varchar(13),B.fecha,121) + '':30:00.000''
	 		when datepart(mi,B.fecha) between 45 and 59 then convert(varchar(13),B.fecha,121) + '':45:00.000'' end as timegroup
	 	,case when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 0 and 14 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':15:00.000''
	 		when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 15 and 29 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':30:00.000''
	 		when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 30 and 44 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':45:00.000''
	 		when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 45 and 59 then  convert(varchar(13),dateadd(hh,1,B.fecha),121) + '':00:00.000'' end as timegroup_next
	 	,case when currentStatus = 1 then tiempo else 0 end as tunknown,
	 	case when currentStatus = 2 then tiempo else 0 end as tnot_av,
	 	case when tipostatusage_id=1 then tiempo when currentStatus = 3 then tiempo else 0 end as tav,
	 	 0,0,0,0,0 as tunknown2
		 ,0,0
		,case when currentStatus in (23,24) then tiempo else 0 end as tchatting
	 	from ccLogAgentesDia A
	 	inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id=B.id
		where A.currentStatus not in(-2,-1,0)

select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15
	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,IdCampEsp,callId,tunknown,tnot_av,tav,tprob,tother,nother,tmanualCall,tunknown2,tlogout,tcliente,tchatting)

	select
	dateStartDetail,dateEndDetail,th.start as timegroup,th.stop as timegroup_next,[User_id],IdCampEsp,callId
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tunknown,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tunknown,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tunknown
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnot_av,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tnot_av
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tprob,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tprob,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tprob
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
	,isnull((case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tmanualCall,dateStartDetail) and  th.stop > dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tmanualCall,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tmanualCall,dateStartDetail) and  th.stop > dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tmanualCall,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tmanualCall
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tunknown2 else 0 end as tunknown2
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tlogout,dateStartDetail) and  th.stop > dateadd(ss,tlogout,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tlogout,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tlogout,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tlogout,dateStartDetail) and  th.stop > dateadd(ss,tlogout,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tlogout,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tlogout,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tlogout
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tcliente,dateStartDetail) and  th.stop > dateadd(ss,tcliente,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tcliente,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tcliente,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tcliente,dateStartDetail) and  th.stop > dateadd(ss,tcliente,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tcliente,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tcliente,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tcliente
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tchatting,dateStartDetail) and  th.stop > dateadd(ss,tchatting,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tchatting,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tchatting,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tchatting,dateStartDetail) and  th.stop > dateadd(ss,tchatting,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tchatting,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tchatting,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tchatting
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

  select 
		isnull(c.IdCampEsp,0) as IdCampEsp
		,C.timegroup
		,isnull(c.tunknown,0) as tunknown
		,isnull(c.tnot_av,0) as tnot_av
		,isnull(c.tav,0) as tav
		,isnull(c.tother,0) as tother
		,isnull(c.tprob,0) as tprob
		,isnull(c.tmanualCall,0) as tmanualCall
		,isnull(c.tlogout,0) as tlogout
		,isnull(c.tcliente,0) as tcliente
	INTO #timeDetailAgentFinal		
	 from (
		select IdCampEsp,
				timegroup,
				sum(tunknown) tunknown,
				sum(tnot_av) tnot_av,
				sum(tav) tav,
				sum(tother) tother,
				sum(tprob) tprob,
				sum(tmanualCall) tmanualCall,
				sum(tlogout) tlogout,
				sum(tcliente) tcliente
		from #timeDetailAgent as c 
		group by [timegroup],IdCampEsp) c
		left join #sessionTimeGroup s (nolock) on s.inb_id=c.IdCampEsp AND s.timegroup=C.timegroup
----------------------------------------------------------
	insert into #inbound
	select 
		cal_Inicio as [dateStart],
		dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio) as [dateEnd]
		,i.Inbound_id as inboundId
		,i.cal_id as cal_id
		,1 as [LlamadasRecibidas]
		,case when i.statusCall_id=13 then 1 else 0 end as nacd, --[LlamadasAtendidas]
		case when (i.statuscall_id <> 13) then 1 else 0 end as nabnd
		,case when i.statusCall_id=13 and i.cal_tdialog>=0 then i.cal_tdialog else 0 end as tacd
		,case when i.statusCall_id=13 and i.cal_tnotas>0 then 1 else null end as nacw
		,case when i.statusCall_id=13 then i.cal_tnotas else 0 end as tacw
		,case when i.statusCall_id=13 then i.cal_txfer else 0 end as txfer
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then 1 else 0 end as SalExt
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then (t.tAntesXfer + t.tDespuesXfer) else 0 end as tprosalext
		,case when i.statusCall_id=13 and i.cal_tmoh>0 then 1 else 0 end nhold
		,case when i.statusCall_id=13 and (i.cal_twait+i.cal_txfer+i.cal_tring)<40 then 1 else null end as nserv
		,case when i.statusCall_id=13 and i.cal_tring>0 then 1 else 0 end as nring
		,case when i.statusCall_id=13 then i.cal_tring else 0 end as tring
		,case when i.statuscall_id = 13 then i.cal_tmoh else 0 end as thold
		,dbo.GetTimeGroup(cal_Inicio,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio),1) as timegroup
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring,cal_Inicio) as [dateTResp]
		,dateadd(ss,i.cal_twait + i.cal_txfer,cal_Inicio) as [dateTRing]
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring+i.cal_tdialog,cal_Inicio) as [dateTACD]	
		,dateadd(ss,-t.tAntesXfer - t.tDespuesXfer,fechaFin) as [dateTTransferStart]	
		,fechaFin as [dateTTransferEnd]
		,i.User_id
	from cccallsin i (nolock) 
	left join ccLogTransfers t (nolock) on i.cal_id=t.cal_id and t.tipo=1
	where cal_Inicio between @from and @to

	select * from #inbound

				
	INSERT into #inboundTimeMayores SELECT * from #inbound where datediff(mi,timegroup,timegroup_next)>15
	delete #inbound where  datediff(mi,timegroup,timegroup_next)>15	

	insert into #inbound
	select dateStart,dateEnd,
		inboundId
		,cal_id
		,dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,[LlamadasRecibidas]) as[LlamadasRecibidas],
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacd) as nacd,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nabnd) as nabnd,		
		[dbo].TimeInterval( th.[start],th.[stop] ,dateTResp,[dateTACD]) as tacd,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacw) as nacw,
		[dbo].TimeInterval( th.[start],th.[stop] ,[dateTACD],dateEnd) as tacw,
		[dbo].TimeInterval( th.[start],th.[stop] ,dateStart,dateTResp) as txfer,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,SalExt) as SalExt,
		case when [dateTTransferStart] is null then 0 else  [dbo].TimeInterval( th.[start],th.[stop] ,[dateTTransferStart],[dateTTransferEnd]) end as tprosalext,	
		 dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nhold) as nhold,
		 dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nserv) as nserv,
		 dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nring) as nring,
		 [dbo].TimeInterval( th.[start],th.[stop] ,dateTRing,dateTResp) as tring,
		 thold,
		 th.[start] as timegroup,th.[stop] as timegroup_next
		,[dateTResp] ,[dateTACD] 
		,[dateTTransferStart] ,[dateTTransferEnd] 
		,UserId
	from #inboundTimeMayores t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	
	 select distinct case when c.timegroup is not null then c.timegroup else G.timegroup end  as [date]
		,isnull(c.inboundId,inb_id) as inboundId
		,isnull(ci.descripcion,'''') as [descripcion]
		,isnull(c.ncalls,0) as ncalls--LlamadasRecibidas
		,isnull(c.nacd,0) as nacd	--atendidas
		,isnull(c.nabnd,0) as nabnd	--abandonadas
		,isnull(c.tacd,0) as tacd --TiempoACD
		,isnull(c.tacw,0) as tacw --TiempoACW
		,isnull(d.tlogout,0) as tlogout --TiempoLogout
		,isnull(c.nacw,0) as nacw --nACW
		,isnull(d.tunknown,0) as tunknown --TiempoDescon
		,isnull(d.tnot_av,0) as tnot_av --TiempoNoDispo
		,isnull(d.tav,0) as tav --TiempoDispo
		,isnull(c.txfer,0) as txfer --TiempoXfer
		,isnull(d.tother,0) as tother --TiempoOtra
		,isnull(d.tcliente,0) as tcliente --TiempoCliente
		,isnull(d.tprob,0) as tprob --TiempoProblema
		,isnull(d.tmanualCall,0) as tmanualCall --TiempoManual
		,G.userId 
		,isnull(G.[tlog seg],0) as tlog
		,isnull(hi.tiempohold,0) as tiempoHold
		,isnull(c.SalExt,0) as SalExt
		,isnull(c.tprosalext,0)  tprosalext	
		,isnull(c.nhold,0) nhold
		,isnull(thold,0) thold
		,isnull(c.nserv,0) nserv
		,isnull(c.nring,0) nring
		,isnull(c.tring,0) tring
	INTO #RepMKTIntervalosTiemposAcuTotalesTemp				
	 from (
		select [timegroup]
			,inboundId,userId	
			,sum(nacd) as nacd			
			,sum(nabnd) as nabnd
			,sum(tacd) as tacd
			,sum(tacw) as tacw
			,sum(nacw) as nacw
			,sum(LlamadasRecibidas) as ncalls
			,sum(txfer) as txfer
			,sum(SalExt) as SalExt
			,sum(tprosalext) as tprosalext
			,sum(nhold) as nhold
			,count(nserv) as nserv
			,sum(tring) as tring
			,sum(nring) as nring
			,sum(thold) as thold
		from #inbound as c 
		group by [timegroup],inboundId,userId) c
		full join 
		(select [user_id] as userId, timegroup, inb_id,sum([tlog seg] ) as [tlog seg] from  #sessionTimeGroup group by [user_id] ,timegroup,inb_id ) G
		on G.timegroup=c.[timegroup] and c.inboundId = G.inb_id and G.userId=c.userId
		LEFT JOIN #timeHoldInterval hi ON hi.inbound_id=C.inboundId AND hi.timegroup=C.timegroup
		left join ccinbound ci (nolock) on ci.Inbound_id=c.inboundId	
		left join #timeDetailAgentFinal d (nolock) on d.IdCampEsp=ci.Inbound_id AND d.timegroup=C.timegroup

	
insert INTO [RepMKTIntervalosTiemposAcuTotales]
	select 
		[date] as [date]
		,inboundId
		,inb.descripcion as descripcion
	    ,round(case when count(distinct userId)>1 then ((convert(float,(sum([tlog])*100))/convert(float,count(distinct userId)*1800))*count(distinct userId))/100 else 0 end,1) as [PromPosicionPersonal]
		,sum(ncalls) LlamadasRecibidas
		,sum(nacd)  LlamadasAtendidas
		,sum(nabnd)  LlamadasAban
		,sum(tacd) as TiempoACD --tACD
		,sum(tacw) as TiempoACW --tACW
		,sum(tlogout) as TiempoLogout --tLogout
		,sum(tunknown) as TiempoDescon --tDescon
		,sum(tnot_av) as TiempoNoDispo --tnotav
		,sum(tav) as TiempoDispo
		,sum(txfer) as TiempoXfer  --txfer
		,sum(tother) as TiempoOtra --tother
		,sum(tcliente) as TiempoCliente --tCliente
		,sum(tring) as TiempoRing --tring
		,sum(tprob) as TiempoProblema --tprob
		,sum(tmanualCall) as TiempoManual --tManual
		,sum(tiempoHold) as TiempoReten --[timeretention]
		,sum(SalExt) as LlamadasSalidaExt
		,case when sum(SalExt)>0 then sum(tprosalext) else 0 end as [TiempoSalidaExt]
		,case when sum(ncalls)>0 then (sum(nserv) * 100) / sum(ncalls) else 0 end [PorcNiveldeServicio4080]
		,((case when sum(nacd)>0 then sum(tacd)/sum(nacd) else 0 end)+(case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end)+(case when sum(nring)>0 then sum(tring)/sum(nring) else 0 end)+(case when sum(nhold)>0 then sum(thold)/sum(nhold) else 0 end)) [AHT]
		,sum(nhold) as LlamadasRetenidas
		,sum(nring) as LlamadasenRing
		,DATEPART(YYYY, [date]) as [year] 
		,DATEPART(mm, [date]) as [month]
		,DATEPART(dd, [date]) as [day]
		,DATEPART(hh, [date]) as [hour]
		,DATEPART(mi, [date]) as [minutes]
		,sum(nserv) as nserv
		from #RepMKTIntervalosTiemposAcuTotalesTemp
		Left join ccinbound  inb ON inb.Inbound_id = inboundId
		group by[date],inboundId,  inb.descripcion
		having sum(nacd)>0 or sum(nabnd)>0 or sum(tlog) >0	

	drop table #sessionTimeGroup;
	drop table #sessionTimeMayores;
	drop table #times;
	drop table #sessionTime;
	drop table #inbound
	drop table #inboundTimeMayores
	drop table #RepMKTIntervalosTiemposAcuTotalesTemp 
	drop table #hold
	drop table #tempccHoldSession
	drop table #holdMayores2
	drop table #tiempoHold
	drop table #timeHoldInterval
	drop table #tempccLogAgentesDia
	drop table #tempccLogAgentesDia2
	drop table #timeDetailAgent
	drop table #timeDetailAgent2
	drop table #tempAgentLastStatus
	drop table #timeDetailAgentFinal

end'
	EXEC(@sql)

	set @process = 'CW-1866 CREATE TABLE RepMKTIntervalosTiemposAcuTotales'
    	set @Sql= 'if not exists (select * from sys.tables where name = N''RepMKTIntervalosTiemposAcuTotales'')
    begin
        CREATE TABLE [dbo].[RepMKTIntervalosTiemposAcuTotales](
	[date] [datetime] NOT NULL,
	[inboundId] [varchar](5) NULL,
	[descripcion] [varchar](50) NULL,
	[PromPosicionPersonal] [numeric](18, 1) NULL,
	[LlamadasRecibidas] [int] NULL,
	[LlamadasAtendidas] [int] NULL,
	[LlamadasAban] [int] NULL,
	[tACD] [int] NULL,
	[tACW] [int] NULL,
	[tLogout] [int] NULL,
	[tDescon] [int] NULL,
	[tnotav] [int] NULL,
	[TiempoDispo] [int] NULL,
	[txfer] [int] NULL,
	[tother] [int] NULL,
	[tCliente] [int] NULL,
	[tring] [int] NULL,
	[tprob] [int] NULL,
	[tManual] [int] NULL,
	[timeretention] [int] NULL,
	[LlamadasSalidaExt] [int] NULL,
	[TiempoSalidaExt] [int] NULL,
	[PorcNiveldeServicio4080] [int] NULL,
	[AHT] [int] NULL,
	[LlamadasRetenidas] [int] NULL,
	[LlamadasenRing] [int] NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL,
	[nserv] [int] null,
	[nacw] [int] null,
) ON [PRIMARY]
    end'
	EXEC(@sql)
	
	set @process = 'CW-1866 insert into ReportsFilters'
    	set @Sql= 'delete from ccMenus where menu_id=7160
		insert into ReportsFilters (reportName,filterName,id)
values(''Summary of Total Accumulated Time Intervals'',''acds'',7160)
'
	EXEC(@sql)

	set @process = 'CW-1866 insert into ReportsFiltersMenus'
    	set @Sql= 'delete from ReportsFiltersMenus where menu_id=7160
		insert into ReportsFiltersMenus values 
(7160,''groupby''),
(7160,''filterby''),
(7160,''date'')'
	EXEC(@sql)

	set @process = 'CW-1866 insert into GroupByReports'
    	set @Sql= 'delete from GroupByReports where id=7160
insert into GroupByReports values(7160,''InboundId|max([descripcion]):descripcion|sum([PromPosicionPersonal]):PromPosicionPersonal|sum([LlamadasRecibidas]):LlamadasRecibidas|sum([LlamadasAtendidas]):LlamadasAtendidas|sum([LlamadasAban]):LlamadasAban|sum([tacd]):tACD|sum([tACW]):tACW|sum([tLogout]):tLogout|sum([tDescon]):tDescon|sum([tnotav]):tnotav|sum([TiempoDispo]):TiempoDispo|sum([txfer]):txfer|sum([tother]):tother|sum([tCliente]):tCliente|sum([tring]):tring|sum([tprob]):tprob|sum([tManual]):tManual|sum([timeretention]):timeretention|sum([LlamadasSalidaExt]):LlamadasSalidaExt|sum([TiempoSalidaExt]):TiempoSalidaExt|case when sum(LlamadasRecibidas)>0 then (sum(nserv) * 100) / sum(LlamadasRecibidas) else 0 end:PorcNiveldeServicio4080|((case when sum(LlamadasAtendidas)>0 then sum(tACD)/sum(LlamadasAtendidas) else 0 end)+(case when sum(nacw)>0 then sum(tACW)/sum(nacw) else 0 end)+(case when sum(LlamadasenRing)>0 then sum(tring)/sum(LlamadasenRing) else 0 end)+(case when sum(LlamadasRetenidas)>0 then sum([timeretention])/sum(LlamadasRetenidas) else 0 end)):AHT|sum([LlamadasRetenidas]):LlamadasRetenidas|sum([LlamadasenRing]):LlamadasenRing'',''InboundId'')
'
	EXEC(@sql)

	set @process = 'CW-1866 insert into ReportsTotals'
    	set @Sql= 'delete from ReportsTotals where id = 7160
insert into ReportsTotals values (7160,''special:PromPosicionPersonal:sum(PromPosicionPersonal)|special:LlamadasRecibidas:sum(LlamadasRecibidas)|special:LlamadasAtendidas:sum(LlamadasAtendidas)|special:LlamadasAban:sum(LlamadasAban)|special:tACD:sum(tACD)|special:tACW:sum(tACW)|special:tLogout:sum(tLogout)|special:tDescon:sum(tDescon)|special:tnotav:sum(tnotav)|special:TiempoDispo:sum(TiempoDispo)|special:txfer:sum(txfer)|special:tother:sum(tother)|special:tCliente:sum(tCliente)|special:tring:sum(tring)|special:tprob:sum(tprob)|special:tManual:sum(tManual)|special:timeretention:sum(timeretention)|special:LlamadasSalidaExt:sum(LlamadasSalidaExt)|special:TiempoSalidaExt:sum(TiempoSalidaExt)|special:PorcNiveldeServicio4080:case when sum(LlamadasRecibidas)>0 then (sum(nserv) * 100) / sum(LlamadasRecibidas) else 0 end|special:AHT:((case when sum(LlamadasAtendidas)>0 then sum(tACD)/sum(LlamadasAtendidas) else 0 end)+(case when sum(nacw)>0 then sum(tACW)/sum(nacw) else 0 end)+(case when sum(LlamadasenRing)>0 then sum(tring)/sum(LlamadasenRing) else 0 end)+(case when sum(LlamadasRetenidas)>0 then sum([timeretention])/sum(LlamadasRetenidas) else 0 end))|special:LlamadasRetenidas:sum(LlamadasRetenidas)|special:LlamadasenRing:sum(LlamadasenRing)'')
'
	EXEC(@sql)


		 if @actualVersion  = @version - 1
	 	exec ccsp_getVersion 'BD', @version


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