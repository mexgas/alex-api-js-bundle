/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Karen Rodriguez
Date: 2019/01/08
Description:
CW-2258 Reporte Mkt Intervalos no coinciden datos con Xion
CW-2259 ccspRepMKTIntervalosTiemposAcuTotales no coinciden columnas con reporte de Xion 4
CW-2576 correccion de reporte de contestadas y transferidas

Database: ccReportsRia
Required version: 63


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 63

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
		SET @process = 'CW-2379 Drop View ccuserView '
		SET @sql = 'if exists(select * from sys.views where name=''ccuserView'')
drop view ccuserView'

		EXEC (@sql)

		SET @process = 'CW-2379 CREATE Table ccUsers_Consulta '
		SET @sql = 
			'if not exists (select * from sys.tables where name=''ccUsers_Consulta'') begin
CREATE TABLE [dbo].[ccUsers_Consulta](
	[User_id] [smallint] NOT NULL,
	[Login] [varchar](20) NOT NULL,
	[Nombres] [varchar](45) NULL,
	[ApellidoPaterno] [varchar](35) NULL,
	[ApellidoMaterno] [varchar](35) NULL,
	[TipoStatusAge_id] [tinyint] NOT NULL,
	[Password] [varchar](33) NOT NULL,
	[TipoUser_id] [int] NOT NULL,
	[Status] [tinyint] NOT NULL,
	[TipoLLamadas] [tinyint] NOT NULL,
	[Sexo] [bit] NOT NULL,
	[filter] [bit] NOT NULL,
	[CanChangeStatus] [bit] NOT NULL,
	[fCreate] [smalldatetime] NOT NULL,
	[DialMask] [tinyint] NOT NULL,
	[XferMask] [tinyint] NOT NULL,
	[LastPasswordChange] [smalldatetime] NULL,
	[IDArea] [smallint] NULL,
	[NotReadyRestricted] [tinyint] NOT NULL,
	[startStopRecording] [bit] NULL,
 CONSTRAINT [PK_ccUsers_Consulta] PRIMARY KEY CLUSTERED 
(
	[User_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

end'

		EXEC (@sql)

		SET @process = 'CW-2379 CREATE View ccuserView '
		SET @sql = 'CREATE VIEW [dbo].[ccUserView] AS
select User_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,TipoStatusAge_id,TipoUser_id,Status,Sexo,IDArea from ccUsers 
union
select User_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,TipoStatusAge_id,TipoUser_id,Status,Sexo,IDArea from ccUsers_Consulta'

		EXEC (@sql)

		SET @process = 'CW-2393 add translate media'
		SET @Sql = 'if not  exists(select * from TranslatedReports where id=8062)
	insert into TranslatedReports values(8062,''media'')

if not  exists(select * from TranslatedReports where id=8063)
	insert into TranslatedReports values(8063,''media'')

if not  exists(select * from TranslatedReports where id=8072)
	insert into TranslatedReports values(8072,''media'')

if not  exists(select * from TranslatedReports where id=8064)
	insert into TranslatedReports values(8064,''media'')'

		EXEC (@Sql)

		SET @process = 'CW-2259 no coinciden columnas en reporte ccspRepMKTIntervalosTiemposAcuTotales'
		SET @sql = 
			'Alter PROCEDURE [dbo].[ccspRepMKTIntervalosTiemposAcuTotales]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()
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
	CREATE TABLE #tempccHoldSession([fila] int NOT NULL,[call_id] [int] NOT NULL,[inbound_id] [int] NOT NULL,[hold] [datetime] NOT NULL,[unhold] [datetime] NULL,[Tipo_marca] [int] not null
				,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL primary key (fila,call_id)			)
	CREATE TABLE #holdMayores2 (call_id int not null, inbound_id int not null,  hold [datetime] not null , [unhold] [datetime] not null,Tipo_marca int not null,tiempoHold int not null,
					[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)
	CREATE TABLE #inbound([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,[cal_id] [int] NOT NULL,[LlamadasRecibidas] [int] NOT NULL, nacd int,nabnd int,
				tacd int,nacw int,tacw int,[txfer] int,[SalExt] int,tprosalext int,nhold int,nserv int,nring int, tring int, thold int,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
				,[dateTResp] datetime,[dateTRing] datetime,[dateTACD] datetime
				,[dateTTransferStart] datetime,[dateTTransferEnd] datetime
				,userId int, time_notes datetime, dateEndDetail datetime
				)
	CREATE TABLE #inboundTimeMayores([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,[cal_id] [int] NOT NULL,[LlamadasRecibidas] [int] NOT NULL, nacd int,
				nabnd int,tacd int,nacw int,tacw int,[txfer] int,[SalExt] int,tprosalext int,nhold int,nserv int,nring int, tring int,  thold int, [timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
				,[dateTResp] datetime,[dateTRing] datetime,[dateTACD] datetime
				,[dateTTransferStart] datetime,[dateTTransferEnd] datetime
				,userId int, time_notes datetime , dateEndDetail datetime
				)
	create table #tempccLogAgentesDia(row int not null,user_id int not null,[IdCampEsp] [int] not null,[callId] [int]not null,TipoStatusAge_id tinyint not null,tStatus int not null,dateIni datetime not null,dateEnd datetime not null,currentStatus int)
	create table #timeDetailAgent([User_id] int null,[IdCampEsp][int] not null,[callId][int] not null,dateStartDetail datetime null,dateEndDetail datetime null,timegroup datetime null,	timegroup_next datetime null,tunknown int null,tnot_av int null,tav int null,tprob int null,tother int null,nother int null,tmanualcall int null,tunknown2 decimal(10,3),tlogout int,tcliente int ,tchatting int null,[PromPosicionPersonal] [numeric](18, 1) NULL,)
	create table #tempAgentLastStatus(id int,fecha datetime,tiempo int)
	create table #ccLogAgentesDia(user_id int not null,[IdCampEsp] [int] not null,TipoStatusAge_id tinyint not null,tStatus int not null, nstatusfra int not null,dateIni datetime not null,dateEnd datetime not null,
	[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)
	create table #ccLogAgentesDiaMayores(user_id int not null,[IdCampEsp] [int] not null,TipoStatusAge_id tinyint not null,tStatus int not null, nstatusfra int not null, dateIni datetime not null,dateEnd datetime not null,
	[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)

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
	,dbo.GetTimeGroup(A.dateIni,0) AS timegroup
	,dbo.GetTimeGroup(A.dateEnd,1) AS timegroup_next,
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
		dbo.GetTimeGroup(B.fecha,0)  as timegroup,
		dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1)  as timegroup_next
	 	,case when currentStatus = 1 then tiempo else 0 end as tunknown,
	 	case when currentStatus = 2 then tiempo else 0 end as tnot_av,
	 	case when currentStatus = 3 then tiempo else 0 end as tav,
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

  select distinct
		isnull(c.IdCampEsp,0) as IdCampEsp
		,c.timegroup
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
		dateadd(ss,cal_tDialog+cal_tWait+cal_tXfer+cal_tRing,cal_Inicio) as [dateEnd]
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
		,dbo.GetTimeGroup(dateadd(ss,cal_tDialog+cal_tWait+cal_tXfer+cal_tRing,cal_Inicio) ,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,cal_tDialog+cal_tWait+cal_tXfer+cal_tRing,cal_Inicio) ,1) as timegroup_next
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring,cal_Inicio) as [dateTResp]
		,dateadd(ss,i.cal_twait + i.cal_txfer,cal_Inicio) as [dateTRing]
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring+i.cal_tdialog,cal_Inicio) as [dateTACD]	
		,dateadd(ss,-t.tAntesXfer - t.tDespuesXfer,fechaFin) as [dateTTransferStart]	
		,fechaFin as [dateTTransferEnd]
		,i.User_id
		,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) as time_notes,
		dateadd(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas ,cal_inicio) as dateEndDetail
	from cccallsin i (nolock) 
	left join ccLogTransfers t (nolock) on i.cal_id=t.cal_id and t.tipo=1
	 where cal_Inicio between @from and @to

				
	INSERT into #inboundTimeMayores SELECT * from #inbound where datediff(mi,timegroup,timegroup_next)>15
	delete #inbound where  datediff(mi,timegroup,timegroup_next)>15
	
	
	insert into #inbound
	select dateStart,dateEnd,
		inboundId
		,cal_id,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,[LlamadasRecibidas]) as[LlamadasRecibidas],
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacd) as nacd,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nabnd) as nabnd,		
		[dbo].TimeInterval( th.[start],th.[stop] ,dateTResp,[dateTACD]) as tacd,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacw) as nacw,
		[dbo].TimeInterval( th.[start],th.[stop] ,time_notes,dateEndDetail) as tacw,
		[dbo].TimeInterval( th.[start],th.[stop] ,dateStart,dateTResp) as txfer,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,SalExt) as SalExt,
		case when [dateTTransferStart] is null then 0 else  [dbo].TimeInterval( th.[start],th.[stop] ,[dateTTransferStart],[dateTTransferEnd]) end as tprosalext,	
		 dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nhold) as nhold,
		 dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nserv) as nserv,
		 dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nring) as nring,
		 [dbo].TimeInterval( th.[start],th.[stop] ,dateTRing,dateTResp) as tring,
		 thold,
		 th.[start] as timegroup,
		 th.[stop] as timegroup_next
		,[dateTResp],[dateTRing] ,[dateTACD] 
		,[dateTTransferStart] ,[dateTTransferEnd] 
		,UserId
		,time_notes
		, dateEndDetail
	from #inboundTimeMayores t 
	inner join #times th on (t.timegroup> th.Start and t.timegroup < th.stop) OR th.Stop between t.timegroup and t.timegroup_next
-----------------------------------------------------------------------------------
insert into #ccLogAgentesDia
	select [User_id]
	,IdCampEsp
	,TipoStatusAge_id
	,tStatus
	,case when tStatus is not null then 1 else 0 end nstatusfra
	,DATEADD(ss,-tStatus,fecha) dateIni
	,fecha dateEnd
	,dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha),0) as timegroup
	,dbo.GetTimeGroup(fecha,1) as timegroup_next
	from ccLogAgentesDia A
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
	and TipoStatusAge_id = 3

	INSERT into #ccLogAgentesDiaMayores 
	SELECT * from #ccLogAgentesDia where datediff(mi,dateIni,dateEnd)>15
	delete #ccLogAgentesDia where  datediff(mi,timegroup,timegroup_next)>15	

	insert into #ccLogAgentesDia
	select User_id,IdCampEsp
	,TipoStatusAge_id
	,[dbo].TimeInterval( th.[start],th.[stop], dateIni, dateEnd) as tstatus
	,nstatusfra
	,DATEADD(ss,-tStatus,dateEnd) dateIni
	,dateEnd dateEnd
	,th.[start] as timegroup
	,th.[stop] as timegroup_next
	from #ccLogAgentesDiaMayores A 
	inner join #times th on (A.timegroup > th.Start and A.timegroup < th.stop) OR th.Start between A.timegroup and A.timegroup_next
	WHERE dateIni>=@from AND dateIni<@to
	and TipoStatusAge_id = 3

	select User_id,IdCampEsp
		,TipoStatusAge_id
		,sum(tstatus) as tstatus
		,sum(nstatusfra) as nstatusfra
		,timegroup
	INTO #groupLog
	from #ccLogAgentesDia
	GROUP BY User_id,IdCampEsp,TipoStatusAge_id,timegroup
	
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
		select 
			timegroup
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
		left JOIN #groupLog lo on c.timegroup = lo.timegroup and c.inboundId = lo.IdCampEsp and c.userId = lo.user_id
	
	
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
		,sum(c.tlogout) as TiempoLogout --tLogout
		,sum(c.tunknown) as TiempoDescon --tDescon
		,sum(distinct c.tnot_av) as TiempoNoDispo --tnotav
		,sum(distinct d.tav) as TiempoDispo
		,sum(txfer) as TiempoXfer  --txfer
		,sum(c.tother) as TiempoOtra --tother
		,sum(c.tcliente) as TiempoCliente --tCliente
		,sum(tring) as TiempoRing --tring
		,sum(c.tprob) as TiempoProblema --tprob
		,sum(c.tmanualCall) as TiempoManual --tManual
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
		,sum(nacw) as nacw
		from #RepMKTIntervalosTiemposAcuTotalesTemp c
		Left join ccinbound  inb ON inb.Inbound_id = inboundId 
		left join #timeDetailAgentFinal d (nolock) on d.IdCampEsp=c.inboundId AND d.timegroup=c.date
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
	drop table #ccLogAgentesDia
	drop table #ccLogAgentesDiaMayores
	drop table #groupLog
 end
 '

		EXEC (@sql)

		SET @process = 'CW-2258 -- ALTER ST ccspRepMKTIntervalos'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccspRepMKTIntervalos]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

if @action = 1
begin
	delete from [RepMKTIntervalos] with(rowlock) 
	where date >= @from AND date <= @to

	CREATE TABLE #sessionTime(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL)
	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)
	CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)
	CREATE TABLE #sessionTimeMayores([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)

	CREATE TABLE #inbound([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,nacd int,tresp int,nabnd int,
	tAbnd int,tacd int,nacw int,tacw int,maxdem int,ncalque int,tcalque int,fent int,fsal int,SalExt int,tprosalext int,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
	,[dateTWait] datetime,[dateTResp] datetime,[dateTACD] datetime,[dateTTransferStart] datetime,[dateTTransferEnd] datetime,userId int, ntotal int
	)

	CREATE TABLE #inboundTimeMayores([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,nacd int,tresp int,nabnd int,
	tAbnd int,tacd int,nacw int,tacw int,maxdem int,ncalque int,tcalque int,fent int,fsal int,SalExt int,tprosalext int,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
	,[dateTWait] datetime,[dateTResp] datetime,[dateTACD] datetime,[dateTTransferStart] datetime,[dateTTransferEnd] datetime,userId int, ntotal int
	)

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

	INSERT into #sessionTimeMayores SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
	delete #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
		
	insert into #sessionTimeGroup
	select [User_id],[login],logout, th.[start] as timegroup,th.[stop] as timegroup_next,
		[dbo].TimeInterval( th.[start],th.[stop] ,[login],logout) as [tlog seg],inb_id
	from #sessionTimeMayores t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0		

	insert into #inbound
	select 
		cal_Inicio as [dateStart],
		dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio) as [dateEnd]
		,Inbound_id as inboundId
		,case when i.statusCall_id=13 then 1 else 0 end as nacd,
		case when i.statuscall_id = 13  then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end as tresp,
		case when (i.statuscall_id <> 13) then 1 else 0 end as nabnd,
		case when (i.statuscall_id <> 13) then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end AS tAbnd
		,case when i.statusCall_id=13 and i.cal_tdialog>=0 then i.cal_tdialog else 0 end as tacd
		,case when i.statusCall_id=13 and i.cal_tnotas>0 then 1 else 0 end as nacw
		,case when i.statusCall_id=13 then i.cal_tnotas else 0 end as tacw
		,case when i.statuscall_id = 13 then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end as maxdem
		,case when (i.statuscall_id in (7,8) AND (i.cal_que > 0) AND (i.cal_xfer=0)) then 1 else 0 end as ncalque
		,case when (i.statusCall_id in (7,8) AND (i.cal_que > 0) AND (i.cal_xfer=0)) then i.cal_tWait else 0 end as tcalque
		,CASE WHEN t.modo = 2 then 1 else 0 end as fent
		,CASE WHEN t.modo = 2 and t.tipo=1 then 1 else 0 end as fsal
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then 1 else 0 end as SalExt
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then (t.tAntesXfer + t.tDespuesXfer) else 0 end as tprosalext
		,dbo.GetTimeGroup(dateadd(ss,cal_tDialog+cal_tWait+cal_tXfer+cal_tRing,cal_Inicio) ,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,cal_tDialog+cal_tWait+cal_tXfer+cal_tRing,cal_Inicio) ,1) as timegroup
		,dateadd(ss,i.cal_twait,cal_Inicio) as [dateTWait]
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring,cal_Inicio) as [dateTResp]
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring+i.cal_tdialog,cal_Inicio) as [dateTACD]	
		,dateadd(ss,-t.tAntesXfer - t.tDespuesXfer,fechaFin) as [dateTTransferStart]	
		,fechaFin as [dateTTransferEnd]
		,i.User_id
		,1 as ntotal
	from cccallsin i (nolock) 
	left join ccLogTransfers t (nolock) on i.cal_id=t.cal_id and t.tipo=1
	where cal_Inicio between @from and @to
	
	INSERT into #inboundTimeMayores SELECT * from #inbound where datediff(mi,timegroup,timegroup_next)>15
	delete #inbound where  datediff(mi,timegroup,timegroup_next)>15	

	insert into #inbound
	select dateStart,dateEnd,inboundId,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacd) as nacd,
		[dbo].TimeInterval( th.[start],th.[stop] ,dateStart,dateTResp) as tresp,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nabnd) as nabnd,		
		case when tAbnd=0 then 0 else [dbo].TimeInterval( th.[start],th.[stop] ,dateStart,dateTResp) end as tAbnd,
		[dbo].TimeInterval( th.[start],th.[stop] ,dateTResp,[dateTACD]) as tacd,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacw) as nacw,
		[dbo].TimeInterval( th.[start],th.[stop] ,[dateTACD],dateEnd) as tacw,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,maxdem) as maxdem,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,ncalque) as ncalque,
		[dbo].TimeInterval( th.[start],th.[stop] ,dateStart,[dateTWait]) as tcalque,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,fent) as fent,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,fsal) as fsal,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,SalExt) as SalExt,
		case when [dateTTransferStart] is null then 0 else  [dbo].TimeInterval( th.[start],th.[stop] ,[dateTTransferStart],[dateTTransferEnd]) end as tprosalext,	
		 th.[start] as timegroup,th.[stop] as timegroup_next,
		[dateTWait] ,[dateTResp] ,[dateTACD] ,[dateTTransferStart] ,[dateTTransferEnd] 
		,UserId
		,dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,ntotal) as ntotal
	from #inboundTimeMayores t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		
	
	select case when c.timegroup is not null then c.timegroup else G.timegroup end  as [date]
		,isnull(c.inboundId,inb_id) as inboundId
		,isnull(c.tresp,0) as tresp,isnull(c.nacd,0) as nacd
		,isnull(c.tabnd,0) tabnd,isnull(c.nabnd,0) 	as nabnd	
		,isnull(c.tacd,0)tacd, isnull(c.tacw,0) tacw,isnull(c.nacw,0) nacw		
		,isnull(c.maxdem,0) maxdem
		,isnull(c.fent,0)  fent, isnull(c.fsal,0) fsal,isnull(c.SalExt,0)  SalExt,isnull(c.tprosalext,0)  tprosalext		
		,isnull(c.ncalque,0) ncalque,isnull(c.tcalque,0) tcalque
		,G.userId 
		,isnull(G.[tlog seg],0) as tlog
		,isnull(c.ntotal, 0) AS ntotal
	INTO #RepMKTIntervalosTemp 				
	 from (
		select [timegroup]
			,inboundId,userId	
			,sum(c.tresp) as tresp,sum(c.nacd) as nacd			
			,sum(c.tabnd) as tabnd
			,sum(c.nabnd) as nabnd
			,sum(c.tacd) as tacd
			,sum(c.tacw) as tacw
			,sum(c.nacw) as nacw			
			,max(c.maxdem) as maxdem			
			,sum(c.ncalque) as ncalque
			,sum(c.tcalque) as tcalque			
			,sum(fent) as fent
			,sum(fsal) as fsal
			,sum(SalExt) as SalExt
			,sum(tprosalext) as tprosalext
			,sum(ntotal) as ntotal	
		from #inbound as c 
		group by [timegroup],inboundId,userId) c		
		full join 
		(select [user_id] as userId, timegroup, inb_id,sum([tlog seg] ) as [tlog seg] from  #sessionTimeGroup group by [user_id] ,timegroup,inb_id ) G
		on G.timegroup=c.[timegroup] and c.inboundId = G.inb_id and G.userId=c.userId		
		
	INSERT INTO [RepMKTIntervalos]
	select 
		[date] as [date]
		,inboundId
		,inb.descripcion as Acds
		,case when sum(nacd)>0 then sum(tresp)/isnull(nullif(sum(nacd),0), 1) else 0 end as [avrAnswer]
		,case when sum(nabnd)>0 then sum(tabnd)/sum(nabnd) else 0 end as [AvgAbandonTime]
		,sum(nacd)  [acdCalls]
		,case when sum(nacd)>0 then sum(tacd)/isnull(nullif(sum(nacd),0), 1) else 0 end as [tPromACD]
		,case when sum(nacw)>0 then sum(tacw)/isnull(nullif(sum(nacw),0), 1) else 0 end as [tPromACW]
		,sum(nabnd) as [abondeonedCalls]
		,max(maxdem) as [maxDelay]
		,sum(fent) as  [entryFlow]	
		,sum(fsal) as  [outFLow]
		,sum(SalExt) as [calloutExt]	
		,isnull(case when sum(SalExt)>0 then sum(tprosalext)/isnull(nullif(sum(SalExt),0), 1) else 0 end,0) as [TPromSalidaExt]
		,sum(ncalque) as [callDeleteQue]	
		,case when sum(ncalque)>0 then sum(tcalque)/isnull(nullif(sum(ncalque),0), 1) else 0 end as [TpromElimCola]
		,case when round(case when count(distinct userId)>0 then ((convert(float,(sum(tlog)*100))/isnull(nullif(convert(float,count(distinct userId)*1800),0), 1))*count(distinct userId))/100 else 0 end,1)>0 
		then (case when convert(decimal(15,2),((sum(nacd) * case when sum(nacd)>0 then sum(tacd)/isnull(nullif(sum(nacd),0), 1) else 0 end) / convert(float,((round(case when (count(distinct userId))>0 then ((convert(float,(sum(tlog)*100))/isnull(nullif(convert(float,count(distinct userId)*1800),0), 1))*count(distinct userId))/100 else 0 end,1))*1800)))*100)>100 then 100 
			   else convert(decimal(15,2),((sum(nacd) * case when sum(nacd)>0 then sum(tacd)/isnull(nullif(sum(nacd),0), 1) else 0 end) / convert(float,((round(case when count(distinct userId)>0 then ((convert(float,(sum(tlog)*100))/isnull(nullif(convert(float,count(distinct userId)*1800),0), 1))*count(distinct userId))/100 else 0 end,1))*1800)))*100) end)
		else 0 end [% Tiempo ACD]
		,isnull(case when (sum(nacd)+sum(nabnd))>0 then convert(decimal(15,2),(convert(float,sum(nacd))*100)/isnull(nullif((convert(float,sum(nacd))+convert(float,sum(nabnd))),0), 1)) else 0 end,0) [% Llamadas Resp]
		,round(case when count(distinct userId)>1 then ((convert(float,(sum(tlog)*100))/ isnull(nullif(convert(float,count(distinct userId)*1800),0), 1))*count(distinct userId))/100 else 0 end,1) as [Llamadas por Posic.]
		,case when sum(nacd) >0 then (case when sum(nacd)/isnull(nullif(count(distinct (case when nacd > 0 then userId end)),0), 1) >0 then convert(int, sum(nacd)/isnull(nullif(count(distinct (case when nacd > 0 then userId end)),0), 1)) else 1 end) else 0 end as [LlamadasporPosicion]
		,sum(tresp) as tresp
		,sum(tabnd) as tabnd
		,sum(tacd) as tacd
		,sum(tacw) as tacw
		,sum(nacw) as nacw		
		,sum(tcalque) as tcalque			
		,sum(tprosalext) as tprosalext
		,sum(tlog) as tlog
		,isnull(userId,0) accountUserId			
		,DATEPART(YYYY, [date]) as [year] 
		,DATEPART(mm, [date]) as [month]
		,DATEPART(dd, [date]) as [day]
		,DATEPART(hh, [date]) as [hour]
		,DATEPART(mi, [date]) as [minutes]
		from #RepMKTIntervalosTemp
		Left join ccinbound  inb ON inb.Inbound_id = inboundId
		group by[date],inboundId, userId, inb.descripcion
		having sum(nacd)>0 or sum(nabnd)>0 or sum(tlog) >0	

	drop table #sessionTimeGroup;
	drop table #sessionTimeMayores;
	drop table #times;
	drop table #sessionTime;
	drop table #inbound
	drop table #inboundTimeMayores
	drop table #RepMKTIntervalosTemp
end
'

		EXEC (@sql)

		SET @process = 'CW-2258 - Reporte Mkt Intervalos no coinciden datos con Xion'
		SET @sql = 
			'DELETE FROM [dbo].[GroupByReports] WHERE [id] = 7140
	IF NOT EXISTS (SELECT * FROM [dbo].[GroupByReports] WHERE [id] = 7140)
	BEGIN
		INSERT INTO GroupByReports values(7140, ''Acds|inboundId|case when sum(acdCalls)>0 then sum(tresp)/sum(acdCalls) else 0 end:avrAnswer|case when sum(abandonedCalls)>0 then sum(tabnd)/sum(abandonedCalls) else 0 end:avgAbandonTime|
	sum(acdCalls):acdCalls|case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end:tPromACD|case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end:tPromACW|sum(abandonedCalls):abandonedCalls|max(maxDelay):maxDelay|
	sum(entryFlow):entryFlow|sum(outFlow):outFlow|sum(callsOutExt):callsOutExt|case when sum(callsOutExt)>0 then sum(tprosalext)/sum(callsOutExt) else 0 end:tPromSalidaExt|sum(callsDeleteQue):callsDeleteQue|
	case when sum(callsDeleteQue)>0 then sum(tcalque)/sum(callsDeleteQue) else 0 end:tPromElimCola|
	case when (case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end)>0 
			then (case when convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when (count(distinct accountUserId))>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end))*CONVERT(float_TIMEGROUP))))*100)>100 then 100 
				   else convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end))*CONVERT(float_TIMEGROUP))))*100) end)
			else 0 end:avrTimeACD|case when (sum(acdCalls)+sum(abandonedCalls))>0 then convert(decimal(15,2),(convert(float,sum(acdCalls))*100)/(convert(float,sum(acdCalls))+convert(float,sum(abandonedCalls)))) else 0 end:avrCallsAnswer|
	round(case when count(distinct accountUserId)>0 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end,1):PromPosicionPersonal|
	case when sum(acdCalls) >0 then (case when sum(acdCalls)/count(distinct(case when acdCalls > 0 then accountUserId end)) >0 then convert(int, sum(acdCalls)/count(distinct(case when acdCalls > 0 then accountUserId end))) else 1 end) else 0 end:LlamadasporPosicion'',''Acds|inboundId'')
	END'

		EXEC (@sql)

		SET @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
		SET @Sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE [name] = N''MSmerge_tr_altertable'' AND type in (N''TR'') AND is_disabled = 0)
	BEGIN
		DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
	END'

		EXEC (@Sql)

		SET @process = 'ccLogTransfers - Alter Table'
		SET @Sql = 'if not exists(select * from sys.columns where [name] = N''tipoLlamada_id'' and Object_ID = Object_ID(N''ccLogTransfers''))
	begin
		alter table ccLogTransfers
		add tipoLlamada_id smallint default(0)
	end'

		EXEC (@Sql)

	SET @process = 'CW-2576 correccion de reporte de contestadas y transferidas- Alter Table ccologdials'
	SET @Sql = 'if not exists(select * from sys.columns where [name] = N''tipoLlamada_id'' and Object_ID = Object_ID(N''ccologdials''))
	begin
		alter table ccologdials
		add tipoLlamada_id smallint default(0)
	end'
		
	EXEC (@Sql)

		SET @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
		SET @Sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE [name] = N''MSmerge_tr_altertable'' AND type in (N''TR'') AND is_disabled = 1)
	BEGIN 
		ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
	END'

		EXEC (@Sql)

		SET @process = 'CW-2576 correccion de reporte de contestadas y transferidas 2'
		SET @sql = 
			'ALTER function [dbo].[fnGetTipoLlamada]( @tel varchar(20) )
returns int
as
 begin
	declare @len integer, @tipo integer, @country varchar(5)
	declare @tipoLlamada_id smallint
	declare @prefijo varchar(15), @longitud varchar(15)

	declare @table table(
	id int not null,
	prefijo nvarchar(100) not null
	)

	select @country = valor from ccsettings where setting_id = 104
	set @len = len( @tel )
	set @tipo = 0

	declare @prefixTable table(
	tipoLlamada_id smallint not null,
	longitud varchar(15) not null,
	prefijo varchar(15) not null,
	[status] bit not null
	)

	insert into @prefixTable
	select tipoLlamada_id, longitud, prefijo, 0
	from cstoTipoLlamada with(index(IX_cstoTipoLlamada),nolock) 
	where country_id = @country 
	and (country_id <> 1 or (country_id = 1 and tipoLlamada_id not in (8,9,10,11))) --no incluir tarifas por region (Mexico)
	order by len(prefijo) desc -- para tomar el mas especifico si se devuelven varios patrones

	while (select count(*) from @prefixTable where [status] = 0) > 0
	begin
		select top 1 @tipoLlamada_id = tipoLlamada_id, @longitud = longitud, @prefijo = prefijo
		from @prefixTable 
		where [status] = 0

		insert into @table
		select * from fn_RIASplitDelimited(@prefijo,''|'') order by len(value) desc

		if (select count(*) from fn_RIASplitDelimited(@longitud,''|'') where value=@len) = 1
			begin
				if (select count(*)	from @table	where @tel like prefijo) = 1
					set @tipo = @tipoLlamada_id
			end
		else if @longitud = ''0''
			begin
				if (select count(*)	from @table	where @tel like prefijo) = 1
					set @tipo = @tipoLlamada_id
			end

		if @tipo <> 0
			update @prefixTable
			set [status] = 1
		else
			begin
				update @prefixTable
				set [status] = 1
				where tipoLlamada_id = @tipoLlamada_id

				delete @table
			end
	end

	if @tipo = 0 and len(@tel) = 12 and LEFT(@tel,5) = ''E_800'' begin
		set @tipo = 5
	end

	return @tipo
 end
 '

		EXEC (@sql)

		SET @process = 'CW-2576 correccion de reporte de contestadas y transferidas 3'
		SET @Sql = 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''GetProveedor'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
    begin
        drop function GetProveedor
    end'

		EXEC (@Sql)

		SET @process = 'CW-2576 correccion de reporte de contestadas y transferidas 4'
		SET @sql = '
CREATE function [dbo].[GetProveedor](@tel varchar(32), @pto int, @tipocall int)
RETURNS int 
AS  
BEGIN
declare @resultado int

select @resultado = d.provedor_id
from cstoTarifa t WITH(NOLOCK)
inner join ccoDialers d WITH(NOLOCK) on d.provedor_id = t.provedor_id
where t.tipollamada_id = @tipocall
and d.puerto = @pto


-- Termina
return @resultado

end'

		EXEC (@sql)

		SET @process = 'CW-2377 Alter SP ccspRepMKTTiemposTotales--  Report Info NUll '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepMKTTiemposTotales]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

if @action = 1
begin
	delete from [RepMKTTiemposTotales] with(rowlock) 
	where date >= @from AND date <= @to

	CREATE TABLE #sessionTime(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL)
	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)
	CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)
	CREATE TABLE #sessionTimeMayores([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)
	CREATE TABLE #inbound([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,ncalls int,nacd int,tresp int,nabnd int,
	nacw int,nring int,tacd int,tacw int,tring int,SalExt int,tprosalext int,nhold int,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
	,[dateTResp] datetime,[dateTACD] datetime,[dateTTransferStart] datetime,[dateTTransferEnd] datetime,userId int,ntotal int)
	CREATE TABLE #inboundTimeMayores([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,ncalls int,nacd int,tresp int,nabnd int,
	nacw int,nring int,tacd int,tacw int,tring int,SalExt int,tprosalext int,nhold int,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
	,[dateTResp] datetime,[dateTACD] datetime,[dateTTransferStart] datetime,[dateTTransferEnd] datetime,userId int,ntotal int)
	CREATE TABLE #holdTime([userId] int not null,inbound_id int not null,tiempohold int not null,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)
	create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on #times([Start] DESC)
	create table #ccLogAgentesDia(user_id int not null,[IdCampEsp] [int] not null,TipoStatusAge_id tinyint not null,tStatus int not null, nstatusfra int not null,dateIni datetime not null,dateEnd datetime not null,
	[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)
	create table #ccLogAgentesDiaMayores(user_id int not null,[IdCampEsp] [int] not null,TipoStatusAge_id tinyint not null,tStatus int not null, nstatusfra int not null, dateIni datetime not null,dateEnd datetime not null,
	[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)

	insert into #times
	exec ccspTimesReports @from=@from,@to=@to,@interval=15
	
	INSERT INTO #sessionTime
	exec ccspGenSession @from, @to	

	INSERT INTO #sessionTimeGroup
	select st.[user_id],[login],logout,dbo.GetTimeGroup([login],0) as timeGroup,dbo.GetTimeGroup(logout,1) as timeGroupNext,DATEDIFF(ss,[login],logout) as tlog, wg.IdCampEsp from #sessionTime st
		Inner Join ccriaworkgroupusers wgu ON st.User_id = wgu.User_id
		Inner Join ccRIACampEspWG wg ON wg.IDWG = WGU.IDWG
	where wg.Tipo = 0 		

	INSERT into #sessionTimeMayores SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
	delete #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
		
	insert into #sessionTimeGroup
	select [User_id],[login],logout, th.[start] as timegroup,th.[stop] as timegroup_next,
		[dbo].TimeInterval( th.[start],th.[stop] ,[login],logout) as [tlog seg],inb_id
	from #sessionTimeMayores t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0	
	
	insert into #inbound
	select 
		cal_Inicio as [dateStart],
		dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio) as [dateEnd]
		,Inbound_id as inboundId
		,1 as ncalls
		,case when i.statusCall_id=13 then 1 else 0 end as nacd
		,case when i.statuscall_id = 13  then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end as tresp
		,case when (i.statuscall_id <> 13) then 1 else 0 end as nabnd
		,case when i.statusCall_id=13 and i.cal_tnotas>0 then 1 else 0 end as nacw
		,case when i.statusCall_id=13 and i.cal_tring>0 then 1 else null end nring
		,case when i.statusCall_id=13 and i.cal_tdialog>=0 then i.cal_tdialog else 0 end as tacd	
		,case when i.statusCall_id=13 then i.cal_tnotas else 0 end as tacw
		,case when i.statusCall_id=13 then i.cal_tring else null end tring
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then 1 else 0 end as SalExt
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then (t.tAntesXfer + t.tDespuesXfer) else 0 end as tprosalext	
		,case when i.statusCall_id=13 and i.cal_tmoh>0 then 1 else 0 end nhold
		,dbo.GetTimeGroup(cal_Inicio,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio),1) as timegroup
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring,cal_Inicio) as [dateTResp]
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring+i.cal_tdialog,cal_Inicio) as [dateTACD]	
		,dateadd(ss,-t.tAntesXfer - t.tDespuesXfer,fechaFin) as [dateTTransferStart]	
		,fechaFin as [dateTTransferEnd]
		,i.User_id
		,1 as ntotal
	from cccallsin i (nolock) 
	left join ccLogTransfers t (nolock) on i.cal_id=t.cal_id and t.tipo=1
	where cal_Inicio between @from and @to
	
	INSERT into #inboundTimeMayores 
	SELECT * from #inbound where datediff(mi,timegroup,timegroup_next)>15
	delete #inbound where  datediff(mi,timegroup,timegroup_next)>15	

	insert into #inbound
	select dateStart,dateEnd,inboundId,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,ncalls) as ncalls,	
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacd) as nacd,	
		[dbo].TimeInterval( th.[start],th.[stop] ,dateStart,dateTResp) as tresp,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nabnd) as nabnd,		
		[dbo].TimeInterval( th.[start],th.[stop] ,dateTResp,[dateTACD]) as tacd,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacw) as nacw,
		[dbo].TimeInterval( th.[start],th.[stop] ,[dateTACD],dateEnd) as tacw,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nring) as nring
		,[dbo].TimeInterval( th.[start],th.[stop] ,[dateTACD],tring) as tring
		,dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,SalExt) as SalExt,
		case when [dateTTransferStart] is null then 0 else  [dbo].TimeInterval( th.[start],th.[stop] ,[dateTTransferStart],[dateTTransferEnd]) end as tprosalext,	
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nhold) as nhold,
		th.[start] as timegroup,th.[stop] as timegroup_next
		,[dateTResp] ,[dateTACD] ,[dateTTransferStart] ,[dateTTransferEnd] 
		,UserId
		,dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,ntotal) as ntotal
	from #inboundTimeMayores t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next	

	insert into #ccLogAgentesDia
	select [User_id]
	,IdCampEsp
	,TipoStatusAge_id
	,tStatus
	,case when tStatus is not null then 1 else 0 end nstatusfra
	,DATEADD(ss,-tStatus,fecha) dateIni
	,fecha dateEnd
	,dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha),0) as timegroup
	,dbo.GetTimeGroup(fecha,1) as timegroup_next
	from ccLogAgentesDia A
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
	and TipoStatusAge_id = 3

	INSERT into #ccLogAgentesDiaMayores 
	SELECT * from #ccLogAgentesDia where datediff(mi,dateIni,dateEnd)>15
	delete #ccLogAgentesDia where  datediff(mi,timegroup,timegroup_next)>15	

	insert into #ccLogAgentesDia
	select User_id,IdCampEsp
	,TipoStatusAge_id
	,[dbo].TimeInterval( th.[start],th.[stop], dateIni, dateEnd) as tstatus
	,nstatusfra
	,DATEADD(ss,-tStatus,dateEnd) dateIni
	,dateEnd dateEnd
	,th.[start] as timegroup
	,th.[stop] as timegroup_next
	from #ccLogAgentesDiaMayores A 
	inner join #times th on (A.timegroup > th.Start and A.timegroup < th.stop) OR th.Start between A.timegroup and A.timegroup_next
	WHERE dateIni>=@from AND dateIni<@to
	and TipoStatusAge_id = 3

	select User_id,IdCampEsp
		,TipoStatusAge_id
		,sum(tstatus) as tstatus
		,sum(nstatusfra) as nstatusfra
		,timegroup
	INTO #groupLog
	from #ccLogAgentesDia
	GROUP BY User_id,IdCampEsp,TipoStatusAge_id,timegroup

	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------HOLD TIME--------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	CREATE TABLE #hold ([userId] int not null,[dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,call_id int not null,inbound_id int not null,  marca int not null, Tipo_marca int not null,
					Tipo_llamada int not null,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL, [time_dialog] [datetime] not null,[time_notes] [datetime] not null
					,[time_hold] [datetime] not null)

	CREATE TABLE #tempccHoldSession([fila] int NOT NULL,[call_id] [int] NOT NULL,[userId] int not null,[inbound_id] [int] NOT NULL,[hold] [datetime] NOT NULL,[unhold] [datetime] NULL,[Tipo_marca] [int] not null
				,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL primary key (fila,call_id))	

	CREATE TABLE #holdMayores2 (call_id int not null,[userId] int not null,inbound_id int not null,  hold [datetime] not null , [unhold] [datetime] not null,Tipo_marca int not null,tiempoHold int not null,
					[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)

	insert into #hold
	select 
		User_id as userId
		,cal_Inicio as [dateStart],
		dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio) as [dateEnd]
		,cal_id as cal_id		
		,inbound_id as inbound_id
		,isnull(h.marca,0) as Marca,
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
	

	insert into #tempccHoldSession
	select A.Fila 
		,A.call_id
		,a.userId
		,a.inbound_id
		,A.time_hold hold,
		--S.fecha holdout
		isnull(S.time_hold,a.time_notes) unhold,
		a.Tipo_marca Tipo_marca
		,a.timegroup timegroup
		,a.timegroup_next timegroup_next
	from (
		select ROW_NUMBER() OVER(PARTITION BY call_id ORDER BY time_hold,tipo_marca) Fila,call_id,userId,inbound_id,marca,tipo_marca,tipo_llamada,time_hold,time_notes,timegroup,timegroup_next
		from #hold a where time_hold >= @from and time_hold <= @to
	)A
	left join (
		select ROW_NUMBER() OVER(PARTITION BY call_id ORDER BY time_hold,tipo_marca) Fila,call_id,userId,inbound_id,marca,tipo_marca,tipo_llamada,time_hold,time_notes,timegroup,timegroup_next
		from #hold a where time_hold >= @from	and time_hold <= @to
	) S
	on A.Fila=S.Fila-1 and A.call_id=S.call_id and A.tipo_marca=1 and S.tipo_marca=0
	where A.tipo_llamada=1 --and a.Tipo_marca=1 
	order by hold

	select 
		ths.call_id,
		ths.userId,
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
	
	INSERT into #holdMayores2 
	SELECT * from #tiempoHold where datediff(mi,timegroup,timegroup_next)>15 
	delete #tiempoHold where  datediff(mi,timegroup,timegroup_next)>15	

	insert into #tiempoHold
	select DISTINCT  call_id,
		userId as userId,
		inbound_id as inbound_id,
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
	userId,
	sum(tiempohold) as tiempohold,
	--sum(Tipo_marca) as Tipo_marca,
	timegroup,
	timegroup_next
	into #timeHoldInterval 
	from #tiempoHold 
	where tiempoHold>0 and Tipo_marca=1
	group by userId,inbound_id,timegroup,timegroup_next

	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	select case when c.timegroup is not null then c.timegroup else G.timegroup end  as [date]
		,isnull(c.inboundId,inb_id) as inboundId
		,isnull(c.nacd,0) as nacd
		,isnull(c.nabnd,0) 	as nabnd	
		,isnull(c.tacd,0)tacd, isnull(c.tacw,0) tacw,isnull(c.nacw,0) nacw		
		,isnull(c.SalExt,0)  SalExt,isnull(c.tprosalext,0)  tprosalext
		,G.userId 
		,isnull(G.[tlog seg],0) as tlog
		,isnull(c.ncalls, 0) AS ncalls		
		,isnull(c.tring, 0) AS tring
		,isnull(c.nring, 0) AS nring
		,isnull(c.nhold, 0) AS nhold
	 INTO #IntervalosInbound
	 from (
			select timegroup,inboundId,userId 
				,sum(c.nacd) as nacd			
				,sum(c.nabnd) as nabnd
				,sum(c.tacd) as tacd
				,sum(c.tacw) as tacw
				,sum(c.nacw) as nacw			
				,sum(SalExt) as SalExt
				,sum(tprosalext) as tprosalext
				,sum(c.ncalls) as ncalls	
				,SUM(c.tring) as tring
				,SUM(c.nring) as nring
				,SUM(c.nhold) as nhold
			from #inbound as c
			where inboundId > 0
			group by timegroup,inboundId,userId 
		) c		
	full join 
	(select [user_id] as userId, timegroup, inb_id,sum([tlog seg] ) as [tlog seg] from  #sessionTimeGroup group by [user_id] ,timegroup,inb_id ) G
	on G.timegroup=c.[timegroup] and c.inboundId = G.inb_id and G.userId=c.userId
	 
	select i.*
	,isnull(case when lo.TipoStatusAge_id=3 then isnull(lo.tStatus,0) end,0) tdispo
	,isnull(case when lo.TipoStatusAge_id=3 then lo.nstatusfra end,0) ndispo
	,isnull(h.tiempohold, 0) AS thold
	--,isnull(h.Tipo_marca, 0) AS nhold	
	INTO #HoldDisp
	from #IntervalosInbound i
	left JOIN #groupLog lo on i.date = lo.timegroup and i.inboundId = lo.IdCampEsp and i.userId = lo.user_id
	left JOIN #timeHoldInterval h on h.inbound_id = i.inboundId and i.date = h.timegroup and i.userId = h.userId

	INSERT INTO [RepMKTTiemposTotales]
	select 
		[date] as [date]
		,inboundId
		,inb.descripcion as Acds
		,round(case when count(distinct userId)>1 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct userId)*1800))*count(distinct userId))/100 else 0 end,1) as [Llamadas por Posic.]
		,sum(ncalls) [Recibidas]
		,sum(nacd) [Atendidas]
		,sum(nabnd) [Abandonadas]
		,case when sum(nacd)>0 then sum(tacd)/sum(nacd) else 0 end as [tPromACD]
		,case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end as [tPromACW]
		,case when sum(nhold)>0 then sum(thold)/sum(nhold) else 0 end as [tPromRetention]
		,sum(SalExt) as [callsOutExt]	
		,isnull(case when sum(SalExt)>0 then sum(tprosalext)/sum(SalExt) else 0 end,0) as [TPromSalidaExt]
		,case when sum(ndispo)>0 then sum(tdispo)/sum(ndispo) else 0 end as [TPromDispon]
		,case when sum(nring)>0 then sum(tring)/sum(nring) else 0 end [TPromRing]
		,sum(((case when nacd>0 then tacd/nacd else 0 end)+(case when nacw>0 then tacw/nacw else 0 end)+(case when nring>0 then tring/nring else 0 end)+(case when nhold>0 then thold/nhold else 0 end))) [AHT1]
		,sum(tacd) as tacd
		,sum(tacw) as tacw
		,sum(nacw) as nacw				
		,sum(tprosalext) as tprosalext
		,sum(tlog) as tlog
		,sum(nhold) as nhold
		,sum(thold) as thold
		,sum(tdispo) as tdispo
		,sum(ndispo) as ndispo
		,sum(tring) as tring
		,sum(nring) as nring
		,userId as accountUserId			
		,DATEPART(YYYY, [date]) as [year] 
		,DATEPART(mm, [date]) as [month]
		,DATEPART(dd, [date]) as [day]
		,DATEPART(hh, [date]) as [hour]
		,DATEPART(mi, [date]) as [minutes]
		from #HoldDisp
		Left join ccinbound  inb ON inb.Inbound_id = inboundId
		group by[date],inboundId, userId, inb.descripcion
		order by date
		--having sum(nacd)>0 --or sum(nabnd)>0 or sum(tlog) >0	

	drop table #sessionTimeGroup;
	drop table #sessionTimeMayores;
	drop table #times;
	drop table #sessionTime;
	drop table #inbound
	drop table #inboundTimeMayores
	drop table #holdTime
	DROP TABLE #hold
	DROP TABLE #tempccHoldSession
	DROP TABLE #tiempoHold
	DROP TABLE #holdMayores2
	DROP TABLE #timeHoldInterval
	DROP TABLE #IntervalosInbound
	DROP TABLE #ccLogAgentesDia
	DROP TABLE #ccLogAgentesDiaMayores
	drop table #HoldDisp
	drop table #groupLog

END
	'

		EXEC (@sql)

		SET @process = 'CW-2377 Alter SP ccspRepAnsweredCallsByDialingRetries --  Report Info NUll '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAnsweredCallsByDialingRetries]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepAnsweredCallsByDialingRetries with(rowlock)
	where date >= @from and date < @to

	INSERT INTO RepAnsweredCallsByDialingRetries
	select
	A.cal_Inicio as [date],
	A.cal_id as [calId],
	A.cal_telefono as [telephone],
	B.tipoResDial_id as [dialResultId],
	resDial.descripcion as [dialResult],
	isnull(C.cal_intentos,0) as [tries],
	A.cam_id as [campaignId],
	E.cam_descripcion as [campaign],
	A.User_id as [userId],
	ISnull(D.Nombres + '' '' + D.ApellidoPaterno + '' '' + D.ApellidoMaterno,''systemTranslated_NoName'') as [agentName],
	isnull(
	(select top 1 Extension from ccLogLogin where user_id=A.User_id and tipoMov=1 and fecha<A.cal_inicio order by fecha desc) 
	,'''')
	as [extension],
	convert(varchar(12),A.cal_Inicio,108) as [startHour],
	convert(varchar(12),dateadd(ss,A.cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,A.cal_Inicio),108) as [endHour],
	cal_tDialog as [dialogTime],
	isnull(A.calif_id,0) as [dispositionId],
	isnull(A.califSub_id,0) as [subDispositionId],
	isnull(disp.Description,''systemTranslated_Dispositionless'') as [disposition],
	isnull(subDisp.califSubDesc,''systemTranslated_NoSubDisposition'') as [subDisposition],
	A.cal_tNotas as [wrapup],
	datepart(yyyy,cal_Inicio) AS [year],
	datepart(mm,cal_Inicio) as [month],
	datepart(dd,cal_Inicio) as [day],
	datepart(hh,cal_Inicio) as [hour],
	datepart(mi,cal_Inicio) as [minutes]


	from ccoCallsOut A
	left join ccoLogDials B on A.cal_id=B.cal_id
	left join ccoCallsOutSource C on C.callout_id=A.callout_id
	left join ccuserView D on A.User_id=D.User_id
	left join ccCamps E on A.cam_id=E.cam_id
	left join ccTipoCalifOUT disp On disp.calif_id=A.calif_id
	left join ccTipoCalifSubOUT subDisp On subDisp.califSub_id=A.califSub_id
	left join ccTipoResultadoDial resDial on resDial.tipoResDial_id=B.tipoResDial_id

	where A.cal_Inicio >= @from
	and A.cal_Inicio < @to
	and A.cal_manual in(0,2)
	
	order by date
END'

		EXEC (@sql)

		SET @process = 'CW-2377 Alter SP ccspRepAgentCallStatusesByInterval--  Report Info NUll '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAgentCallStatusesByInterval]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

BEGIN
SET NOCOUNT ON

if @from is null
	select @from = CONVERT(datetime, convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1 begin

	declare @interval int
	declare @dateNow datetime,@maxLogout datetime
	DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
	declare @valuenav varchar(100)
	declare @tnav int, @twbCall int
	SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)

	select @valuenav = valor from ccSettings where setting_id = 40

	select @tnav = Value from dbo.fn_RIASplitDelimited(@valuenav,''|'') where Id = 1
	select @twbCall = Value from dbo.fn_RIASplitDelimited(@valuenav,''|'') where Id = 2

	create table #outboundData(row int identity, [User_id] int, cal_id int,
	dateStartDetail datetime, dateEndDetail datetime,
	timegroup datetime, timegroup_next datetime,
	tque int, txfer int, tring int, tdialog int, tnotes int,
	time_endque datetime, time_ring datetime, time_dialog datetime, time_notes datetime, time_end_call datetime)

	create nonclustered index iX_CamUserId on #outboundData([User_id] DESC)

	CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

	create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on #times([Start] DESC)

	--Tiempos del agente
	create table #tempccLogAgentesDia(row int not null,user_id int not null,TipoStatusAge_id tinyint not null,tStatus int not null,
	dateIni datetime not null,dateEnd datetime not null,currentStatus int)

	create table #timeDetailAgent([User_id] int null, dateStartDetail datetime null, dateEndDetail datetime null,
	timegroup datetime null, timegroup_next datetime null,
	tav int null, tother int null,  tunknown2 decimal(10,3))

	--Tiempo ultimo Status del agente
	create table #tempAgentLastStatus(id int,fecha datetime,tiempo int)

	create nonclustered index ix_timesNotReady on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_timesNotReady2 on #times([Start] DESC)

	--Tiempos del agente en not ready
	create table #tempccLogAgentesNotReadyDay (row int not null, user_id int not null, TipoNotReady_id tinyint not null, tStatus int not null,
	dateStart datetime null, dateEnd datetime null)

	create table #tempNotReady (user_id int not null,
	dateStartDetail datetime null, dateEndDetail datetime null,
	timegroup datetime null, timegroup_next datetime null, tnav int null, twbcall int null)

	--Tiempo en transferencia estado en llamada
	create nonclustered index ix_timesCallTransf on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_timesCallTransf2 on #times([Start] DESC)

	create table #tempccLogtransfers (user_id int not null, cal_id int,
	dateStartTransf datetime null, dateEndTransf datetime null,
	timegroup datetime null, timegroup_next datetime null, tcallTransf int not null )

	set @dateNow=getdate()
	set @interval=15

	insert into #times
	exec ccspTimesReports @from=@from,@to=@to,@interval=@interval

	-- Columnas Hora intervalo inicio = dateStartDetail, Hora intervalo fin = dateEndDetail, Tiempo en timbrando = tring, Tiempo de notas (acw) = tnotes
	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cal_id,User_id,tque,txfer,tring,tdialog,tnotes,time_endque,time_ring,time_dialog,time_notes,time_end_call)
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		   ,dbo.GetTimeGroup(cal_inicio,0) as timegroup
		   ,dbo.GetTimeGroup(dateadd(ss,(cal_txfer + cal_tring + cal_tdialog + cal_tnotas),cal_Inicio),1) as timegroup_next		   
		   ,cal_id
		   , [User_id]
		   ,ISNULL((cal_twait),0) as tque
		   ,ISNULL((cal_txfer),0)AS txfer
		   ,isnull((cal_tring),0) as tring
		   ,isnull((cal_tdialog),0) as tdialog
		   ,isnull((cal_tnotas),0) as tnotes
		  ,DATEADD(ss,isnull((0),0),cal_inicio) as time_endque
		   ,DATEADD(ss,isnull((0 + cal_txfer),0),cal_inicio) as time_ring
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		   FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
		   WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to

	 update C
	 set C.dateEndDetail=@dateNow
	 ,C.timegroup_next= dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1)	 
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

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tque,txfer,tring,tdialog,tnotes,time_endque,time_ring,time_dialog,time_notes,time_end_call,cal_id)
	select
	dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
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
	,time_endque,time_ring,time_dialog,time_notes,time_end_call,cal_id
	from #outboundData2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	-----------------------------------------------------------------------------------------------------------

	--Columnas Tiempo disponible = tav, Tiempo en otro = tother
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
	select A.user_id, A.dateIni, A.dateEnd
	,dbo.GetTimeGroup(A.dateIni,0) AS timegroup
	,dbo.GetTimeGroup(A.dateEnd,1) as timegroup_next,
	case when A.tipostatusage_id=3 then A.tStatus else 0 end tav,
	case when A.tipostatusage_id=7 then A.tStatus else 0 end tother,
	case when abs(isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) )>A.tStatus then 0
	when A.currentStatus in(0,-1,-2) then 0 --Logout
	when S.TipoStatusAge_id=1 then 0
	else isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) end	as tunknown2
	from #tempccLogAgentesDia2 A
	left join #tempccLogAgentesDia2 S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id<>0

	update #timeDetailAgent set tunknown2=0  where abs(tunknown2)>2.7

	 insert into #timeDetailAgent(User_id,dateStartDetail,dateEndDetail,timegroup,timegroup_next,tav,tother,tunknown2)
	 select
	 	User_id,
	 	B.fecha as dateStartDetail,
	 	@dateNow as dateEndDetail
		,dbo.GetTimeGroup(B.fecha,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1) as timegroup_next
	 	,case when tipostatusage_id=1 then tiempo when currentStatus = 3 then tiempo else 0 end as tav,
	 	0,0 as tunknown2
	 	from ccLogAgentesDia A
	 	inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id = B.id
		where A.currentStatus not in(-2,-1,0)

	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15
	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tav,tother,tunknown2)
	select
	dateStartDetail,dateEndDetail,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tunknown2 else 0 end as tunknown2
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	-----------------------------------------------------------------------------------

	--Columnas Tiempo en capacitación (ND) = tnav, Tiempo en “trabajo previo a llamada” = twbcall
	insert into #tempccLogAgentesNotReadyDay(row,[User_id],TipoNotReady_id,tStatus,dateStart,dateEnd)
	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY DATEADD(ss,-tStatus,fecha)) AS Row,User_id,
	TipoNotReady_id,tStatus,DATEADD(ss,-tStatus,fecha)as dateStart, fecha as dateEnd
	from cclogagentesnotready
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to and TipoNotReady_id in (@tnav,@twbCall)

	insert into #tempNotReady (user_id,dateStartDetail,dateEndDetail, timegroup, timegroup_next, tnav, twbcall)
	select user_id,dateStart,dateEnd
	,dbo.GetTimeGroup(A.dateStart,0)  AS timegroup
	,dbo.GetTimeGroup(A.dateEnd,1) as timegroup_next,
	case when A.TipoNotReady_id=@tnav then A.tStatus else 0 end tnav,
	case when A.TipoNotReady_id=@twbCall then A.tStatus else 0 end twbcall
	from #tempccLogAgentesNotReadyDay A
	where  A.dateStart>=@from AND A.dateStart<@to and A.TipoNotReady_id in (@tnav,@twbCall)

	select * into #tempNotReady2 from #tempNotReady where datediff(mi,timegroup,timegroup_next)>15
	delete #tempNotReady where datediff(mi,timegroup,timegroup_next) > 15

	insert into #tempNotReady (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tnav,twbcall)
	select dateStartDetail,dateEndDetail,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnav,dateStartDetail) and  th.stop > dateadd(ss,tnav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnav,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tnav,dateStartDetail) and  th.stop > dateadd(ss,tnav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnav,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tnav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,twbcall,dateStartDetail) and  th.stop > dateadd(ss,twbcall,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,twbcall,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,twbcall,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,twbcall,dateStartDetail) and  th.stop > dateadd(ss,twbcall,dateStartDetail) then datediff(ss,th.start,dateadd(ss,twbcall,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,twbcall,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
	from #tempNotReady2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	--------------------------------------------------------------------------------------------

	--Columnas Tiempo en “Transferencia estando en llamada” = tcallTransf
	insert into #tempccLogtransfers (user_id, cal_id, dateStartTransf, dateEndTransf, timegroup, timegroup_next, tcallTransf)
	select A.[User_id],A.cal_id, A.dateStartDetail, A.dateEndDetail
	,dbo.GetTimeGroup(A.dateStartDetail,0) AS timegroup
	,dbo.GetTimeGroup(A.dateEndDetail,1) as timegroup_next
	,isnull((0 + B.tAntesXfer + B.tDespuesXfer),0) as tcallTransf
	from #outboundData A
	left join ccLogtransfers B on A.cal_id=B.cal_id and Tipo=2 and modo <> 6
	where  A.dateStartDetail>=@from AND A.dateEndDetail<@to

	select * into #tempccLogtransfers2 from #tempccLogtransfers where datediff(mi,timegroup,timegroup_next)>15
	delete #tempccLogtransfers where datediff(mi,timegroup,timegroup_next) > 15
	--
	insert into #tempccLogtransfers (dateStartTransf,dateEndTransf,timegroup,timegroup_next,User_id,tcallTransf)
	select dateStartTransf,dateEndTransf,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,isnull((case when th.start <= dateStartTransf and  th.stop > dateStartTransf and th.start <= dateadd(ss,tcallTransf,dateStartTransf) and  th.stop > dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,dateStartTransf,dateadd(ss,tcallTransf,dateStartTransf))
				when th.start <= dateStartTransf and  th.stop > dateStartTransf and th.stop < dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,dateStartTransf,th.stop)
				when th.start > dateStartTransf and th.start <= dateadd(ss,tcallTransf,dateStartTransf) and  th.stop > dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,th.start,dateadd(ss,tcallTransf,dateStartTransf))
				when th.start > dateStartTransf and th.stop < dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,th.start,th.stop) else  0 end),0) as tcallTransf
	from #tempccLogtransfers2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	-----------------------------------------------------------------------------------------------------------------------------------
	delete RepAgentCallStatusesByInterval with(rowlock) where date >= @from AND date < @to

	insert into RepAgentCallStatusesByInterval
	select
		case when O.timegroup is not null then O.timegroup when Agent.timegroup is not null then Agent.timegroup else nReady.timegroup end as [date],
		case when U.user_id is not null then U.user_id when Agent.User_id is not null then Agent.User_id else nReady.user_id end as [userId],
		U.login as [agentName],
		case when O.timegroup is not null then O.timegroup when Agent.timegroup is not null then Agent.timegroup else nReady.timegroup end as [startInterval],
		case when O.timegroup_next is not null then O.timegroup_next when Agent.timegroup_next is not null then Agent.timegroup_next else nReady.timegroup_next end as [endInterval],
		case when Agent.tav is not null then Agent.tav else 0 end as [readyTime],
		case when O.tnotes is not null then O.tnotes else 0 end as [twrapup],
		case when O.tring is not null then O.tring else 0 end as [tring],
		case when Agent.tother is not null then Agent.tother else 0 end as [tother],
		case when nReady.tnav is not null then nReady.tnav else 0 end as [tnav],
		case when O.tcallTransf is not null then O.tcallTransf else 0 end as [tCallTransf],
		case when nReady.twbcall is not null then nReady.twbcall else 0 end as [twbCall],
		datepart(yyyy,O.timegroup) as [year], datepart(mm,O.timegroup)  as [month], datepart(dd,O.timegroup)  as [day],
		datepart(hh,O.timegroup) as [hour], datepart(mi,O.timegroup)  as [minutes]
		from
			(select O.timegroup, O.timegroup_next, O.User_id, sum(tnotes) as tnotes, sum(tring) as tring
			,isnull(sum(tcallTransf),0) as tcallTransf
			from #outboundData O
			left join #tempccLogtransfers L on O.cal_id=L.cal_id
			group by O.timegroup,O.timegroup_next, O.User_id) O
		full join
			(select timegroup,timegroup_next,User_id,sum(tav) as tav,sum(tother) as tother from #timeDetailAgent
			group by timegroup,timegroup_next,User_id)
		Agent on O.timegroup=Agent.timegroup and O.User_id=Agent.User_id
		full join
			(select timegroup, timegroup_next,user_id, sum(tnav) as tnav,sum(twbcall) as twbcall from #tempNotReady
			group by timegroup, timegroup_next,user_id)
		nReady on nReady.timegroup=O.timegroup and O.User_id=nReady.User_id
		inner join ccuserView U on O.User_id = U.User_id or Agent.User_id=U.User_id or nReady.User_id=U.User_id
		where  O.timegroup>=@from AND O.timegroup_next<@to
		


	---DROP TABLES TEMP
	drop table #tempccLogAgentesDia
	drop table #tempccLogAgentesDia2
	drop table #times
	drop table #timeDetailAgent
	drop table #timeDetailAgent2
	drop table #tempAgentLastStatus
	drop table #outboundData
	drop table #tempccLogAgentesNotReadyDay
	drop table #tempNotReady
	drop table #tempNotReady2
	drop table #outboundData2
	drop table #tempccLogtransfers
	drop table #tempccLogtransfers2
	end
end'

		EXEC (@sql)

		SET @process = 'CW-2393 Alter SP ccspRepAVRSAgent'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAVRSAgent]		
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN

	---Before insert delete first  table dbo.RepAVRSAgent 
	DELETE FROM dbo.RepAVRSAgent with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSAgent
	--By Agent		
	select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
		a.User_id,
		a.Login,
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
		f.total_forma AS scores, 
		f.total_forma AS scores, 
		f.total_forma AS scores,
		s.User_id,
		s.Login,
		(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
		f.id_formato,
		k.nombre,		
		f.id_grabacion,
		case f.tipo 
			when 1 then ''systemTranslated_Recording'' 
			when 2 then ''systemTranslated_Chat''
			when 3 then ''systemTranslated_Email''
			when 3 then ''systemTranslated_Twitter''
		end as Medio,		
		f.cam_id as CamId,
		f.tipo_llamada as TipoLlamada,	
		(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
			AS Cam,		 
		YEAR(f.fecha_calif) AS [year], 
		MONTH(f.fecha_calif) AS [month], 
		DAY(f.fecha_calif) AS [day], 
		CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
		CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
	from dbo.RIA_FORMACALIF f
	INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
	INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
	INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS 
								WHERE activo = 1 and tipo=1
								GROUP BY id_formato,nombre) as t 
								ON t.id_formato= f.id_formato
	INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
	left join cccamps AS e ON f.cam_id = e.cam_id
	left join ccinbound AS u ON f.cam_id = u.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
END'

		EXEC (@Sql)

		SET @process = 'CW-2393 Alter SP ccspRepAVRSDetailChat'
		SET @Sql = 
			'ALTER PROCEDURE  [dbo].[ccspRepAVRSDetailChat]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
set nocount on

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN		
	---Before insert delete first table dbo.RepAVRSQuestionDetail 
	DELETE FROM dbo.RepAVRSDetailChat with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSDetailChat

		select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
		a.User_id,
		a.Login,
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
		t.id_formato,
		t.nombre,
		p.enunciado_pregunta,
		r.etiquetas,
		r.peso as avgDisposition,
		i.Inbound_id AS inboundId,
		i.descripcion AS inbound	
	from RIA_RESULTADOSFORMA_CHAT r
	INNER JOIN dbo.RIA_FORMACALIF_CHAT f ON f.id_forma = r.id_forma
	INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
	INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1 and tipo=2
								GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
	INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
	INNER JOIN dbo.ccriachats c ON f.id_chat=c.chatId
	INNER JOIN ccinbound AS i ON c.inboundId = i.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
				
set nocount off
END'

		EXEC (@Sql)

		SET @process = 'CW-2393 Alter SP ccspRepAVRSSupervisor'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAVRSSupervisor]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()	

if @action = 1
BEGIN
---Before insert delete first  table dbo.RepAVRSSupervisor 
DELETE FROM dbo.RepAVRSSupervisor with(rowlock) 
where date >= @from AND date < @to

INSERT INTO dbo.RepAVRSSupervisor
--By Supervisor
select
	DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
	a.User_id,
	a.Login,
	(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
	f.total_forma AS scores, 
	f.total_forma AS scores, 
	f.total_forma AS scores,
	s.User_id,
	s.Login,
	(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
	f.id_formato,
	k.nombre,		
	f.id_grabacion,
	case f.tipo 
		when 1 then ''systemTranslated_Recording'' 
		when 2 then ''systemTranslated_Chat''
		when 3 then ''systemTranslated_Email''
		when 3 then ''systemTranslated_Twitter''
	end as Medio,	
	f.cam_id as CamId,
	f.tipo_llamada as TipoLlamada,	
	(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
		AS Cam,		 
	YEAR(f.fecha_calif) AS [year], 
	MONTH(f.fecha_calif) AS [month], 
	DAY(f.fecha_calif) AS [day], 
	CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
	CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
from dbo.RIA_FORMACALIF f
INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							FROM dbo.RIA_FORMATOS
							WHERE activo = 1
							GROUP BY id_formato,nombre) as t 
							ON t.id_formato= f.id_formato
INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
left join cccamps AS e ON f.cam_id = e.cam_id
left join ccinbound AS u ON f.cam_id = u.Inbound_id
WHERE f.fecha_calif >= @from AND f.fecha_calif < @to

END'

		EXEC (@Sql)

		SET @process = 'CW-2393 Alter SP ccspRepAVRSQuestion'
		SET @Sql = 
			'ALTER PROCEDURE  [dbo].[ccspRepAVRSQuestion]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
set nocount on


if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1 BEGIN		
---Before insert delete first table dbo.RepAVRSQuestionDetail 
DELETE FROM dbo.RepAVRSQuestion with(rowlock)
where date >= @from AND date < @to

INSERT INTO dbo.RepAVRSQuestion

select
	DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
	a.User_id,
	a.Login,
	(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
	s.User_id,
	s.Login,
	(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
	t.id_formato,
	t.nombre,
	c.id_concepto,
	c.con_descripcion,
	p.id_pregunta,
	p.enunciado_pregunta,
	r.peso as avgDisposition,
	r.peso as avgDisposition,
	r.peso as avgDisposition,
	f.id_grabacion,
	case f.tipo 
		when 1 then ''systemTranslated_Recording'' 
		when 2 then ''systemTranslated_Chat''
		when 3 then ''systemTranslated_Email''
		when 3 then ''systemTranslated_Twitter''
	end as Medio,		
	f.cam_id as CamId,
	(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
		AS Cam	
from RIA_RESULTADOSFORMA r
INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							FROM dbo.RIA_FORMATOS
							WHERE activo = 1 and tipo=1
							GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
left join cccamps AS e ON f.cam_id = e.cam_id
left join ccinbound AS u ON f.cam_id = u.Inbound_id
WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
				
set nocount off
END'

		EXEC (@Sql)

		SET @process = 'CW-2393 Alter SP ccspRepAVRSQuestionChat'
		SET @Sql = 
			'ALTER PROCEDURE  [dbo].[ccspRepAVRSQuestionChat]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
set nocount on

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN		
	---Before insert delete first table dbo.RepAVRSQuestionDetail 
	DELETE FROM dbo.RepAVRSQuestionChat with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSQuestionChat

		select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
		a.User_id,
		a.Login,
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
		t.id_formato,
		t.nombre,
		p.id_pregunta,
		p.enunciado_pregunta,
		r.peso as avgDisposition,
		r.peso as avgDisposition,
		r.peso as avgDisposition,
		i.Inbound_id AS inboundId,
		i.descripcion AS inbound	
	from RIA_RESULTADOSFORMA_CHAT r
	INNER JOIN dbo.RIA_FORMACALIF_CHAT f ON f.id_forma = r.id_forma
	INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
	INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1 and tipo=2
								GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
	INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
	INNER JOIN dbo.ccriachats c ON f.id_chat=c.chatId
	INNER JOIN ccinbound AS i ON c.inboundId = i.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
					
set nocount off
END'

		EXEC (@Sql)

		SET @process = 'CW-2393 Alter SP ccspRepAVRSQuestionDetail'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAVRSQuestionDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
set nocount on


if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN		
---Before insert delete first table dbo.RepAVRSQuestionDetail 
DELETE FROM dbo.RepAVRSQuestionDetail with(rowlock)
where date >= @from AND date < @to;

WITH reportQaEvaluation (Fecha,agentId, LoginAgent, Agent,SupId,LoginSup,Supervisor,formatId,nameTemplate,score,Medio)
AS
(
select
f.fecha_calif Fecha,
a.User_id agentId,
a.Login as LoginAgent,  
(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) Agent, 
s.User_id as SupId,
s.Login as LoginSup,
(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
t.id_formato formatId,
t.nombre as nameTemplate,
SUM (r.peso) as score,
f.tipo as medio
		

from RIA_RESULTADOSFORMA r
INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
INNER JOIN (SELECT id_formato,nombre
FROM dbo.RIA_FORMATOS
WHERE activo = 1 and tipo=1
GROUP BY id_formato,nombre) as t ON t.id_formato = f.id_formato
WHERE f.fecha_calif >= @from AND f.fecha_calif < @to	
GROUP BY f.fecha_calif,a.User_id,
(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres),a.Login,(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres), s.Login, t.nombre,f.tipo,s.User_id,t.id_formato
)
insert into RepAVRSQuestionDetail
select Fecha,agentId, LoginAgent, Agent, SupId,LoginSup,Supervisor,formatId,nameTemplate,score,
(case Medio 
when 1 then ''systemTranslated_Recording'' 
when 2 then ''systemTranslated_Chat''
when 3 then ''systemTranslated_Email''
when 3 then ''systemTranslated_Twitter''
end) as Medio,	
		
YEAR(Fecha) AS [year], 
MONTH(Fecha) AS [month], 
DAY(Fecha) AS [day],
DATEPART(HOUR,Fecha) AS [hour], 
DATEPART(MINUTE,Fecha) AS [minute]
from reportQaEvaluation


set nocount off
END	
			
'

		EXEC (@Sql)

		SET @process = 'CW-2393 Alter SP ccspRepAVRSRateDetail'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAVRSRateDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN
---Before insert delete first  table dbo.RepAVRRateDetail 
DELETE FROM dbo.RepAVRSRateDetail with(rowlock)
where date >= @from AND date < @to

INSERT INTO dbo.RepAVRSRateDetail

select
	DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
	a.User_id,
	a.Login,
	(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
	s.User_id,
	s.Login,
	(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
	f.id_grabacion,
	case f.tipo 
		when 1 then ''systemTranslated_Recording'' 
		when 2 then ''systemTranslated_Chat''
		when 3 then ''systemTranslated_Email''
		when 3 then ''systemTranslated_Twitter''
	end as Medio,	
	t.id_formato,
	t.nombre,
	c.con_descripcion,
	p.enunciado_pregunta,
	r.etiquetas,
	r.peso as avgDisposition,	
	r.peso as avgDisposition,	
	r.peso as avgDisposition,
	f.cam_id as CamId,
	f.tipo,
	(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
		AS Cam,
	r.id_forma,
	YEAR(f.fecha_calif) AS [year], 
	MONTH(f.fecha_calif) AS [month], 
	DAY(f.fecha_calif) AS [day], 
	CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
	CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]		
from RIA_RESULTADOSFORMA r
INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							FROM dbo.RIA_FORMATOS
							WHERE activo = 1 and tipo=1
							GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
left join cccamps AS e ON f.cam_id = e.cam_id
left join ccinbound AS u ON f.cam_id = u.Inbound_id
WHERE f.fecha_calif >= @from AND f.fecha_calif < @to

END
			'

		EXEC (@Sql)

		SET @process = 'CW-2393 Alter SP ccspRepAVRSSection'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAVRSSection]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN
---Before insert delete first  table dbo.RepAVRSSection 
DELETE FROM dbo.RepAVRSSection with(rowlock)
where date >= @from AND date < @to

INSERT INTO dbo.RepAVRSSection
				
select
	DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
	a.User_id,
	a.Login,
	(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
	s.User_id,
	s.Login,
	(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
	f.id_formato,
	t.nombre,
	c.id_concepto,
	c.con_descripcion,
	r.peso AS scores, 
	r.peso as avgDisposition,
	r.peso as avgDisposition,
	r.peso as avgDisposition,
	f.id_grabacion,
	case f.tipo 
		when 1 then ''systemTranslated_Recording'' 
		when 2 then ''systemTranslated_Chat''
		when 3 then ''systemTranslated_Email''
		when 3 then ''systemTranslated_Twitter''
	end as Medio,		
	f.cam_id as CamId,
	f.tipo_llamada as TipoLlamada,	
	(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
		AS Cam,
		f.id_forma,		 
	YEAR(f.fecha_calif) AS [year], 
	MONTH(f.fecha_calif) AS [month], 
	DAY(f.fecha_calif) AS [day], 
	CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
	CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]		
from RIA_RESULTADOSFORMA r
INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							FROM dbo.RIA_FORMATOS
							WHERE activo = 1 and tipo=1
							GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
left join cccamps AS e ON f.cam_id = e.cam_id
left join ccinbound AS u ON f.cam_id = u.Inbound_id
WHERE f.fecha_calif >= @from AND f.fecha_calif < @to

END'

		EXEC (@Sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAgentCallStatusesByInterval]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

BEGIN
SET NOCOUNT ON

if @from is null
	select @from = CONVERT(datetime, convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1 begin

	declare @interval int
	declare @dateNow datetime,@maxLogout datetime
	DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
	declare @valuenav varchar(100)
	declare @tnav int, @twbCall int
	SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)

	select @valuenav = valor from ccSettings where setting_id = 40

	select @tnav = Value from dbo.fn_RIASplitDelimited(@valuenav,''|'') where Id = 1
	select @twbCall = Value from dbo.fn_RIASplitDelimited(@valuenav,''|'') where Id = 2

	create table #outboundData(row int identity, [User_id] int, cal_id int,
	dateStartDetail datetime, dateEndDetail datetime,
	timegroup datetime, timegroup_next datetime,
	tque int, txfer int, tring int, tdialog int, tnotes int,
	time_endque datetime, time_ring datetime, time_dialog datetime, time_notes datetime, time_end_call datetime)

	create nonclustered index iX_CamUserId on #outboundData([User_id] DESC)

	CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

	create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on #times([Start] DESC)

	--Tiempos del agente
	create table #tempccLogAgentesDia(row int not null,user_id int not null,TipoStatusAge_id tinyint not null,tStatus int not null,
	dateIni datetime not null,dateEnd datetime not null,currentStatus int)

	create table #timeDetailAgent([User_id] int null, dateStartDetail datetime null, dateEndDetail datetime null,
	timegroup datetime null, timegroup_next datetime null,
	tav int null, tother int null,  tunknown2 decimal(10,3))

	--Tiempo ultimo Status del agente
	create table #tempAgentLastStatus(id int,fecha datetime,tiempo int)

	create nonclustered index ix_timesNotReady on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_timesNotReady2 on #times([Start] DESC)

	--Tiempos del agente en not ready
	create table #tempccLogAgentesNotReadyDay (row int not null, user_id int not null, TipoNotReady_id tinyint not null, tStatus int not null,
	dateStart datetime null, dateEnd datetime null)

	create table #tempNotReady (user_id int not null,
	dateStartDetail datetime null, dateEndDetail datetime null,
	timegroup datetime null, timegroup_next datetime null, tnav int null, twbcall int null)

	--Tiempo en transferencia estado en llamada
	create nonclustered index ix_timesCallTransf on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_timesCallTransf2 on #times([Start] DESC)

	create table #tempccLogtransfers (user_id int not null, cal_id int,
	dateStartTransf datetime null, dateEndTransf datetime null,
	timegroup datetime null, timegroup_next datetime null, tcallTransf int not null )

	set @dateNow=getdate()
	set @interval=15

	insert into #times
	exec ccspTimesReports @from=@from,@to=@to,@interval=@interval

	-- Columnas Hora intervalo inicio = dateStartDetail, Hora intervalo fin = dateEndDetail, Tiempo en timbrando = tring, Tiempo de notas (acw) = tnotes
	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cal_id,User_id,tque,txfer,tring,tdialog,tnotes,time_endque,time_ring,time_dialog,time_notes,time_end_call)
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		   ,dbo.GetTimeGroup(cal_inicio,0) as timegroup
		   ,dbo.GetTimeGroup(dateadd(ss,(cal_txfer + cal_tring + cal_tdialog + cal_tnotas),cal_Inicio),1) as timegroup_next		   
		   ,cal_id
		   , [User_id]
		   ,ISNULL((cal_twait),0) as tque
		   ,ISNULL((cal_txfer),0)AS txfer
		   ,isnull((cal_tring),0) as tring
		   ,isnull((cal_tdialog),0) as tdialog
		   ,isnull((cal_tnotas),0) as tnotes
		  ,DATEADD(ss,isnull((0),0),cal_inicio) as time_endque
		   ,DATEADD(ss,isnull((0 + cal_txfer),0),cal_inicio) as time_ring
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		   FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
		   WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to

	 update C
	 set C.dateEndDetail=@dateNow
	 ,C.timegroup_next= dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1)	 
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

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tque,txfer,tring,tdialog,tnotes,time_endque,time_ring,time_dialog,time_notes,time_end_call,cal_id)
	select
	dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
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
	,time_endque,time_ring,time_dialog,time_notes,time_end_call,cal_id
	from #outboundData2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	-----------------------------------------------------------------------------------------------------------

	--Columnas Tiempo disponible = tav, Tiempo en otro = tother
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
	select A.user_id, A.dateIni, A.dateEnd
	,dbo.GetTimeGroup(A.dateIni,0) AS timegroup
	,dbo.GetTimeGroup(A.dateEnd,1) as timegroup_next,
	case when A.tipostatusage_id=3 then A.tStatus else 0 end tav,
	case when A.tipostatusage_id=7 then A.tStatus else 0 end tother,
	case when abs(isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) )>A.tStatus then 0
	when A.currentStatus in(0,-1,-2) then 0 --Logout
	when S.TipoStatusAge_id=1 then 0
	else isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) end	as tunknown2
	from #tempccLogAgentesDia2 A
	left join #tempccLogAgentesDia2 S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id<>0

	update #timeDetailAgent set tunknown2=0  where abs(tunknown2)>2.7

	 insert into #timeDetailAgent(User_id,dateStartDetail,dateEndDetail,timegroup,timegroup_next,tav,tother,tunknown2)
	 select
	 	User_id,
	 	B.fecha as dateStartDetail,
	 	@dateNow as dateEndDetail
		,dbo.GetTimeGroup(B.fecha,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1) as timegroup_next
	 	,case when tipostatusage_id=1 then tiempo when currentStatus = 3 then tiempo else 0 end as tav,
	 	0,0 as tunknown2
	 	from ccLogAgentesDia A
	 	inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id = B.id
		where A.currentStatus not in(-2,-1,0)

	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15
	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tav,tother,tunknown2)
	select
	dateStartDetail,dateEndDetail,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tunknown2 else 0 end as tunknown2
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	-----------------------------------------------------------------------------------

	--Columnas Tiempo en capacitación (ND) = tnav, Tiempo en “trabajo previo a llamada” = twbcall
	insert into #tempccLogAgentesNotReadyDay(row,[User_id],TipoNotReady_id,tStatus,dateStart,dateEnd)
	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY DATEADD(ss,-tStatus,fecha)) AS Row,User_id,
	TipoNotReady_id,tStatus,DATEADD(ss,-tStatus,fecha)as dateStart, fecha as dateEnd
	from cclogagentesnotready
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to and TipoNotReady_id in (@tnav,@twbCall)

	insert into #tempNotReady (user_id,dateStartDetail,dateEndDetail, timegroup, timegroup_next, tnav, twbcall)
	select user_id,dateStart,dateEnd
	,dbo.GetTimeGroup(A.dateStart,0)  AS timegroup
	,dbo.GetTimeGroup(A.dateEnd,1) as timegroup_next,
	case when A.TipoNotReady_id=@tnav then A.tStatus else 0 end tnav,
	case when A.TipoNotReady_id=@twbCall then A.tStatus else 0 end twbcall
	from #tempccLogAgentesNotReadyDay A
	where  A.dateStart>=@from AND A.dateStart<@to and A.TipoNotReady_id in (@tnav,@twbCall)

	select * into #tempNotReady2 from #tempNotReady where datediff(mi,timegroup,timegroup_next)>15
	delete #tempNotReady where datediff(mi,timegroup,timegroup_next) > 15

	insert into #tempNotReady (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tnav,twbcall)
	select dateStartDetail,dateEndDetail,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnav,dateStartDetail) and  th.stop > dateadd(ss,tnav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnav,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tnav,dateStartDetail) and  th.stop > dateadd(ss,tnav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnav,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tnav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,twbcall,dateStartDetail) and  th.stop > dateadd(ss,twbcall,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,twbcall,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,twbcall,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,twbcall,dateStartDetail) and  th.stop > dateadd(ss,twbcall,dateStartDetail) then datediff(ss,th.start,dateadd(ss,twbcall,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,twbcall,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
	from #tempNotReady2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	--------------------------------------------------------------------------------------------

	--Columnas Tiempo en “Transferencia estando en llamada” = tcallTransf
	insert into #tempccLogtransfers (user_id, cal_id, dateStartTransf, dateEndTransf, timegroup, timegroup_next, tcallTransf)
	select A.[User_id],A.cal_id, A.dateStartDetail, A.dateEndDetail
	,dbo.GetTimeGroup(A.dateStartDetail,0) AS timegroup
	,dbo.GetTimeGroup(A.dateEndDetail,1) as timegroup_next
	,isnull((0 + B.tAntesXfer + B.tDespuesXfer),0) as tcallTransf
	from #outboundData A
	left join ccLogtransfers B on A.cal_id=B.cal_id and Tipo=2 and modo <> 6
	where  A.dateStartDetail>=@from AND A.dateEndDetail<@to

	select * into #tempccLogtransfers2 from #tempccLogtransfers where datediff(mi,timegroup,timegroup_next)>15
	delete #tempccLogtransfers where datediff(mi,timegroup,timegroup_next) > 15
	--
	insert into #tempccLogtransfers (dateStartTransf,dateEndTransf,timegroup,timegroup_next,User_id,tcallTransf)
	select dateStartTransf,dateEndTransf,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,isnull((case when th.start <= dateStartTransf and  th.stop > dateStartTransf and th.start <= dateadd(ss,tcallTransf,dateStartTransf) and  th.stop > dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,dateStartTransf,dateadd(ss,tcallTransf,dateStartTransf))
				when th.start <= dateStartTransf and  th.stop > dateStartTransf and th.stop < dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,dateStartTransf,th.stop)
				when th.start > dateStartTransf and th.start <= dateadd(ss,tcallTransf,dateStartTransf) and  th.stop > dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,th.start,dateadd(ss,tcallTransf,dateStartTransf))
				when th.start > dateStartTransf and th.stop < dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,th.start,th.stop) else  0 end),0) as tcallTransf
	from #tempccLogtransfers2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	-----------------------------------------------------------------------------------------------------------------------------------
	delete RepAgentCallStatusesByInterval with(rowlock) where date >= @from AND date < @to

	insert into RepAgentCallStatusesByInterval
	select
		case when O.timegroup is not null then O.timegroup when Agent.timegroup is not null then Agent.timegroup else nReady.timegroup end as [date],
		case when U.user_id is not null then U.user_id when Agent.User_id is not null then Agent.User_id else nReady.user_id end as [userId],
		U.login as [agentName],
		case when O.timegroup is not null then O.timegroup when Agent.timegroup is not null then Agent.timegroup else nReady.timegroup end as [startInterval],
		case when O.timegroup_next is not null then O.timegroup_next when Agent.timegroup_next is not null then Agent.timegroup_next else nReady.timegroup_next end as [endInterval],
		case when Agent.tav is not null then Agent.tav else 0 end as [readyTime],
		case when O.tnotes is not null then O.tnotes else 0 end as [twrapup],
		case when O.tring is not null then O.tring else 0 end as [tring],
		case when Agent.tother is not null then Agent.tother else 0 end as [tother],
		case when nReady.tnav is not null then nReady.tnav else 0 end as [tnav],
		case when O.tcallTransf is not null then O.tcallTransf else 0 end as [tCallTransf],
		case when nReady.twbcall is not null then nReady.twbcall else 0 end as [twbCall],
		datepart(yyyy,O.timegroup) as [year], datepart(mm,O.timegroup)  as [month], datepart(dd,O.timegroup)  as [day],
		datepart(hh,O.timegroup) as [hour], datepart(mi,O.timegroup)  as [minutes]
		from
			(select O.timegroup, O.timegroup_next, O.User_id, sum(tnotes) as tnotes, sum(tring) as tring
			,isnull(sum(tcallTransf),0) as tcallTransf
			from #outboundData O
			left join #tempccLogtransfers L on O.cal_id=L.cal_id
			group by O.timegroup,O.timegroup_next, O.User_id) O
		full join
			(select timegroup,timegroup_next,User_id,sum(tav) as tav,sum(tother) as tother from #timeDetailAgent
			group by timegroup,timegroup_next,User_id)
		Agent on O.timegroup=Agent.timegroup and O.User_id=Agent.User_id
		full join
			(select timegroup, timegroup_next,user_id, sum(tnav) as tnav,sum(twbcall) as twbcall from #tempNotReady
			group by timegroup, timegroup_next,user_id)
		nReady on nReady.timegroup=O.timegroup and O.User_id=nReady.User_id
		inner join ccUserView U on O.User_id = U.User_id or Agent.User_id=U.User_id or nReady.User_id=U.User_id
		where  O.timegroup>=@from AND O.timegroup_next<@to
		


	---DROP TABLES TEMP
	drop table #tempccLogAgentesDia
	drop table #tempccLogAgentesDia2
	drop table #times
	drop table #timeDetailAgent
	drop table #timeDetailAgent2
	drop table #tempAgentLastStatus
	drop table #outboundData
	drop table #tempccLogAgentesNotReadyDay
	drop table #tempNotReady
	drop table #tempNotReady2
	drop table #outboundData2
	drop table #tempccLogtransfers
	drop table #tempccLogtransfers2
	end
end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAgentGI]
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

	CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

	create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on #times([Start] DESC)

	create table #timeDetailAgent([User_id] int null,dateStartDetail datetime null,dateEndDetail datetime null,timegroup datetime null,	timegroup_next datetime null,tunknown int null,tnot_av int null,tav int null,tprob int null,tother int null,nother int null,tmanualcall int null,tunknown2 decimal(10,3),tchatting int null)

	--Tiempo ultimo Status del agente
	create table #tempAgentLastStatus(id int,fecha datetime,tiempo int)

	--
	CREATE TABLE #sessionTime(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL)
	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)
	CREATE TABLE #sessionTimeMayores(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)

	--TIempos del agente
	create table #tempccLogAgentesDia(row int not null,user_id int not null,TipoStatusAge_id tinyint not null,tStatus int not null,dateIni datetime not null,dateEnd datetime not null,currentStatus int)

	insert into #times
	exec ccspTimesReports @from=@from,@to=@to,@interval=@interval

	--Sessiones del agente
	insert into #sessionTime exec ccspGenSession @from=@from,@to=@to

	select @maxLogout=max(logout) from #sessionTime

	if CONVERT(varchar(11),@maxLogout,121)=CONVERT(varchar(11),@dateNow,121) and @dateNow>@maxLogout set @dateNow=@maxLogout

	INSERT INTO #sessionTimeGroup
	select user_id,login,logout,extension
	,dbo.GetTimeGroup(A.login,0 ) AS timegroup
	,dbo.GetTimeGroup(A.logout,1 ) as timegroup_next
	 ,datediff(ss,login,logout)
	 from #sessionTime as A

	 INSERT into #sessionTimeMayores SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
	delete #sessionTimeGroup where  datediff(mi,timegroup,timegroup_next)>15

	insert into #sessionTimeGroup
	 select [User_id],login,logout,extension, convert(varchar,th.start,121) as timegroup, convert(varchar, th.stop,121) as timegroup_next,
	 isnull((case when th.start <= login and  th.stop > login and th.start <= dateadd(ss,[tlog],login) and  th.stop > dateadd(ss,[tlog],login) then datediff(ss,login,dateadd(ss,[tlog],login))
					when th.start <= login and  th.stop > login and th.stop < dateadd(ss,[tlog],login) then datediff(ss,login,th.stop)
					when th.start > login and th.start <= dateadd(ss,[tlog],login) and  th.stop > dateadd(ss,[tlog],login) then datediff(ss,th.start,dateadd(ss,[tlog],login))
					when th.start > login and th.stop < dateadd(ss,[tlog],login) then datediff(ss,th.start,th.stop) else  0 end),0) as [tlog seg]

	from #sessionTimeMayores t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0;


	--inserto ultimo tiempo del agente del dia
	insert into #tempAgentLastStatus
	select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),@dateNow) from ccLogAgentesDia where convert(varchar(11),fecha,121)=CONVERT(varchar(11),@dateNow,121) group by User_id


	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service
	,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl
	)
	select * from (
	SELECT case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end as dateStartDetail,
		   dateadd(ss,0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,
			case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end )
			dateEndDetail,
		   case when datepart(mi,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) between 0 and 14 then convert(varchar(13),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ,121) + '':00:00.000''
			when datepart(mi,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) between 15 and 29 then convert(varchar(13),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ,121) + '':15:00.000''
		   when datepart(mi,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) between 30 and 44 then convert(varchar(13),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ,121) + '':30:00.000''
		   when datepart(mi,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) between 45 and 59 then convert(varchar(13),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ,121) + '':45:00.000'' end as timegroup
		   ,case when datepart(mi,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ))
		   between 0 and 14 then convert(varchar(13),dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ),121) + '':15:00.000''
		   when datepart(mi,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ))
		   between 15 and 29 then convert(varchar(13),dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ),121) + '':30:00.000''
		   when datepart(mi,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ))
		   between 30 and 44 then convert(varchar(13),dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ),121) + '':45:00.000''
		   when datepart(mi,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ))
		   between 45 and 59 then  convert(varchar(13), dateadd(hh,1,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ),121) + '':00:00.000'' end as timegroup_next
		   ,DATEADD(ss,isnull((0),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_endque
		   ,DATEADD(ss,isnull((0 + cal_txfer),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_ring
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_dialog
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_notes
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_end_call
		   ,cal_Ani as phone_in,cal_id,dni_id,Inbound_id,[User_id]
		   ,1 AS ntotal
		   ,ISNULL((CASE WHEN statuscall_id=1 THEN 1 ELSE 0 END),0) AS ninitial
		   ,ISNULL((CASE WHEN statuscall_id=2 THEN 1 ELSE 0 END),0) AS nout_hour
		   ,ISNULL((CASE WHEN statuscall_id=3 THEN 1 ELSE 0 END),0) AS nout_service
		   ,ISNULL((CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nabnd
		   ,ISNULL((CASE WHEN(statuscall_id=4)THEN 1 ELSE 0 END),0) AS nno_agent
		   ,ISNULL((CASE WHEN(cal_que>0)THEN 1 ELSE 0 END),0) AS nque
		   ,ISNULL((CASE WHEN(statuscall_id=7)THEN 1 ELSE 0 END),0) AS ntimeout
		   ,ISNULL((CASE WHEN(statuscall_id=8)THEN 1 ELSE 0 END),0) AS noverflow
		   ,ISNULL((CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nxfer
		   ,ISNULL((CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN 1 ELSE 0 END),0) AS nxfer_que
		   ,ISNULL((CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nabnd_xfer
		   ,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE 0 END),0) AS nabnd_ring
		   ,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE 0 END),0) AS nno_answer
		   ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE 0 END),0) AS nabnd_dialog
		   ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE 0 END),0) AS nanswer
		   ,ISNULL((CASE WHEN(statuscall_id=16)THEN 1 ELSE 0 END),0) AS nlost
		   ,ISNULL((CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE 0 END),0) AS nmsg
		   ,ISNULL((CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE 0 END),0) AS nabnd_tres
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
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tchatting,dateStartDetail) and  th.stop > dateadd(ss,tchatting,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tchatting,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tchatting,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tchatting,dateStartDetail) and  th.stop > dateadd(ss,tchatting,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tchatting,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tchatting,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tchatting
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0



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
	isnull(callIdIn,'''') callIdIn,isnull(phoneIn,'''') phoneIn,isnull(dateStartDetailIn,'''') dateStartDetailIn,
	isnull(callIdOut,'''') callIdOut,isnull(phoneOut,'''') phoneOut,isnull(dateStartDetailOut,'''') dateStartDetailOut,
	(case when agtInf.timegroup IS NOT NULL then agtInf.timegroup when calls.timegroup IS NOT NULL  then calls.timegroup else '''' END) [date],
	(case when agtInf.user_id IS NOT NULL THEN agtInf.user_id when calls.userId IS NOT NULL then calls.userId else -1 END) [userId],
	u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + nombres as [user] , u.login as [login]
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
		,isnull((_in.cal_id),'''') as callIdIn,isnull((_in.phone_in),'''') as phoneIn,isnull((_in.dateStartDetail),'''') as dateStartDetailIn
		,isnull((_out.cal_id),'''') as callIdOut,isnull((_out.phone_out),'''') as phoneOut,isnull((_out.dateStartDetail),'''') as dateStartDetailOut
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
	declare @userId int
	set @userId =15

	delete from RepAgentGI with(rowlock) where date >= @from AND date < @to

	insert into RepAgentGI(date,userId,[user],login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,--treq,
			tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotavg,tundefined,tchatting)
	select date,userId,isnull([user],''otro''),isnull(login,''otro''),nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,--treq,
				tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotav,
				(tlog-tdialogin-tnotesin-tringin-txferin-tdialogout-tnotesout-tringout-txferout-tunknown-tnotav-tav-tother-tprob-tchatting) as tundefined
				,tChatting
	 from #tempRepAgentGI


	---DROP TABLES TEMP
	drop table #sessionTime
	drop table #times
	drop table #inboundData
	drop table #inboundData2
	drop table #outboundData
	drop table #outboundData2
	drop table #timeDetailAgent
	drop table #timeDetailAgent2
	drop table #agentInformation
	drop table #tempRepAgentGI

	drop table #tempAgentLastStatus
	drop table #tempccLogAgentesDia
	drop table #tempccLogAgentesDia2
	drop table #sessionTimeGroup
	drop table #sessionTimeMayores;
end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'
ALTER PROCEDURE [dbo].[ccspRepAgentKPI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
	delete RepAgentKPI with(rowlock)
	where date >= @from AND date < @to

	create table #ccCalls_Temp(
	cal_id int, 
	User_id smallint, 
	statusCall_id tinyint, 
	cal_tDialog smallint, 
	cal_Inicio datetime, 
	cal_whoHung smallint, 
	tipoTabla tinyint)

	CREATE NONCLUSTERED INDEX IX_ccCalls_Temp ON #ccCalls_Temp (cal_id ASC)

	insert into #ccCalls_Temp 
	select cal_id, User_id, statusCall_id, cal_tDialog, convert(varchar(8), cal_Inicio, 112)+'' 00:00'', cal_whoHung, 0 
	from ccoCallsOut with(nolock, index(IX_ccoCallsOut_14))
	where cal_inicio between @from and @to and cal_manual < 3

	insert into #ccCalls_Temp 
	select cal_id, User_id, statusCall_id, cal_tDialog, convert(varchar(8), cal_Inicio, 112)+'' 00:00'', cal_whoHung, 1 
	from ccCallsIn with(nolock, index(IX_ccCallsIn))
	where cal_inicio between @from and @to 

	insert into RepAgentKPI
	select convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121)) date, Fst.Login as login, Fst.user_id as [userId],
	Nombres + isnull('' ''+ApellidoPaterno, '''') + isnull('' ''+ApellidoMaterno, '''') as [user], Total as totalCalls, Cin as callsIn, 
	Cout as callsOut, C10 as [finishedCalls10], C20 as [finishedCalls20], C30 as [finishedCalls30], cal_whoHung as whoHung, 
	isnull(avg_fCalc, 0) as callsAvgTime,
	datepart(yyyy,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(mm,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(dd,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(hh,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(mi,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121)))
	from 
	(
	select User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno 
	from ccUserView
	) as Fst
	join
	(
	select user_id, cal_Inicio, sum(Total) Total, sum(Cin) Cin, sum(Cout) Cout, sum(C10) C10, sum(C20) C20, sum(C30) C30, sum(cal_whoHung) cal_whoHung
	from (select user_id, cal_Inicio, 1 Total, tipoTabla Cin, case tipoTabla when 0 then 1 else 0 end Cout,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<10 then 1 else 0 end C10,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<20 then 1 else 0 end C20,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<30 then 1 else 0 end C30,
		cal_whoHung from #ccCalls_Temp
	) as Conteos group by user_id, cal_Inicio
	) as Snd
	on Fst.User_id = Snd.User_id
	left join 
	(
	select User_id, cast((AVG(convert(bigint,fecha_Calc_ms)))/1000.0 as decimal(10,0)) avg_fCalc 
	from ccLogAgentesDia_Dialog with(nolock, index(IX_ccLogAgentesDia_Dialog))
	where fecha_Dialog between @from and @to 
	group by User_id
	) as Trd
	on Snd.User_id = Trd.User_id

	drop table #ccCalls_Temp
end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAgentNotReady]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS OFF
SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

create table #timeDetailAgent(
	[User_id] int not null,
	dateStartDetail datetime null,dateEndDetail datetime null,dateNext datetime null
	,timegroup datetime null,
	timegroup_next datetime null,tunknown int null,
	tnot_av int null,tav int null,tprob int null,
	tother int null,nother int null,tmanualcall int null,
	tunknown2 decimal(10,3)
	)

create table #sessionTime(
	[User_id] int not null,
	[login] [datetime] NOT NULL,
	[logout] [datetime] NULL,
	[extension] [varchar](7) NOT NULL
	)

insert into #timeDetailAgent
 exec ccsprepLogAgentriaseparate @from=@from,@to=@to

 declare @dateNow datetime
declare @starttime datetime,@number int
 set @dateNow=getdate()
set @starttime = CONVERT(smalldatetime,CONVERT(varchar(13),@from,121)+ '':00'',121)
set @number = 0

create table #tempFechasR(id int,fecha datetime,tiempo int)

CREATE TABLE #times([ID] INT primary key, [Start] DATETIME,	[Stop] DATETIME	)

create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
create nonclustered index ix_times2 on #times([Start] DESC)

while @number <= (datediff(mi,@starttime,@to)/60) begin
   insert into #times
   select @number,DATEADD(mi, @number*60, @starttime),DATEADD(mi, (@number+1)*60, @StartTime)
   set @number = @number +1
end

if @action = 1
begin
	--

	-- Session Time
	insert into #sessionTime
 exec [ccspGenSession] @from=@from,@to=@to

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
	,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav
	,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob
	,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown
	,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother
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
				from #timeDetailAgent )x
				group by timegroup,User_id
				)xTimeDetail
					LEFT OUTER JOIN #inboundData ON(xTimeDetail.timegroup=#inboundData.timegroup AND xTimeDetail.[user_id]=#inboundData.[user_id])
					LEFT OUTER JOIN #outboundData ON(xTimeDetail.timegroup=#outboundData.timegroup AND xTimeDetail.[user_id]=#outboundData.[user_id])
				GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		 	)xDetail
	)xAllTimes
 WHERE tlog>0
 ORDER BY timegroup,[user_id]


  SELECT DATEADD(ss,-(tStatus),(fecha)) as dateStartDetail,(fecha) as dateEndDetail,
  convert(smalldatetime,convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000'',121) AS timegroup
  ,dateadd(hh,1,convert(smalldatetime,convert(varchar(13),fecha,121) + '':00:00.000'',121)) as timegroup_next, TipoNotReady_id
    ,[User_id],(tStatus) as [timeNotReady],1 as [count], tstatus as [time]
	into #notReady
  FROM ccLogAgentesNotReady
  WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to


  insert into #tempFechasR select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),@dateNow) from ccLogAgentesDia where CONVERT(varchar(11),fecha,121)=CONVERT(varchar(13), @dateNow,121) group by User_id

	insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next,TipoNotReady_id,[User_id],[timeNotReady],[count],[time])
	select
		B.fecha as dateStartDetail,
		@dateNow as dateEndDetail,
		CONVERT(smalldatetime,CONVERT(varchar(13),B.fecha,121)+ '':00'',121) AS timegroup,
		case when @dateNow=CONVERT(smalldatetime,CONVERT(varchar(13),@dateNow,121)+ '':00'',121) then CONVERT(smalldatetime,CONVERT(varchar(13),@dateNow,121)+ '':00'',121)
		else CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(hh,1,@dateNow),121)+ '':00'',121) end AS timegroup_next
		,0 as TipoNotReady_id,User_id,0 as timeNotReady,1 as [count],tiempo as [time]
		from ccLogAgentesDia A
		inner JOIN #tempFechasR B ON A.fecha=B.fecha  and A.User_id=B.id WHERE currentStatus =2

 select * into #notReady2 from #notReady where datediff(HH,timegroup,timegroup_next)>1
 delete #notReady where datediff(HH,timegroup,timegroup_next) > 1

 insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next, tiponotready_id,User_id,timeNotReady, [count], [time])
 select (dateStartDetail),(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next, tiponotready_id,[User_id]
 ,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,timeNotReady,dateStartDetail))
     when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
     when th.start > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,dateadd(ss,timeNotReady,dateStartDetail))
     when th.start > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as timeNotReady,1 as [count], isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,timeNotReady,dateStartDetail))
     when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
     when th.start > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,dateadd(ss,timeNotReady,dateStartDetail))
     when th.start > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as [time]
 from #notReady2 t
 inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
 where  datediff(ss,th.start,timegroup_next)>0

	delete from RepAgentNotReady with(rowlock) 	where date >= @from AND date < @to

	insert into RepAgentNotReady
	select a.timegroup as date, c.login, a.user_id as [userId], c.apellidopaterno + '' '' + c.apellidomaterno + '' '' + c.nombres as [user],
	a.tlog as sessionTime,
	isnull(d.tiponotready_id,0) tiponotready_id, isnull(d.descripcion,'''') descripcion,
	isnull(d.descripcion,'''') + ''_Count'' as descripcion_count, sum(isnull([count],0)) count, isnull(d.descripcion,'''') + ''_Time'' as descripcion_time,
	sum(isnull([time],0)) time, sum(isnull([time],0)) as timeSeconds--, amountReal
	,datepart(yyyy,a.timegroup) year, datepart(mm,a.timegroup) [mounth], datepart(dd,a.timegroup) [day], datepart(hh,a.timegroup) [hour], datepart(mi,a.timegroup) [minute]
	from #agentInformation a
	left outer join #notReady b on (a.timegroup = b.timegroup and  a.user_id =b.user_id)
	left outer join (
		select user_id, login, apellidopaterno, apellidomaterno, nombres
		from ccUserView
	) as c on (a.user_id = c.user_id)
	left outer join (
		select tiponotready_id, descripcion
		from ccTipoNotReady
	) as d on (b.tiponotready_id = d.tiponotready_id)
	group by a.timegroup, c.Login, a.user_id,c.apellidopaterno + '' '' + c.apellidomaterno + '' '' + c.nombres, a.tlog, d.tiponotready_id, d.descripcion



	drop table #sessionTime
	drop table #inboundData
	drop table #outboundData
	drop table #agentInformation
	drop table #notReady
	drop table #timeDetailAgent
	drop table #notReady2
	drop table #times
	drop table #tempFechasR


end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAgentNotReadyDet]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
	delete from RepAgentNotReadyDet with(rowlock)
	where date >= @from AND date < @to
	
	INSERT INTO RepAgentNotReadyDet
	SELECT convert(datetime,convert(varchar(11),fechaInicio)) as [date], isNull(usr.Login,''systemTranslated_NoUserName'') as login, usr.user_id as userId, 
	isNull(usr.ApellidoPaterno,'''') + '' '' + isNull(usr.ApellidoMaterno, '''') + '' '' + IsNull(usr.Nombres, ''systemTranslated_NoName'') as [user],
	isnull(tn.tiponotready_id,0) as tiponotreadyId,  
	isNull(tn.Descripcion, ''systemTranslated_NoStatus'')as [status], 
	fechaInicio as startDate, 
	case when fechaFin is null then fecha when separado = 0 then fecha when separado = 3  or separado = 1 then fechaFin end as endDate,
	case when fechafin is null then
			tStatus
		 when separado = 0 then 
			tStatus
		 when separado = 3  or separado = 1 then
			datediff( s, fechaInicio, fechaFin) end as statusTime,
	case when fechafin is null then tStatus when separado = 0 then tStatus when separado = 3  or separado = 1 then datediff( s, fechaInicio, fechaFin) end as statusTimeSeconds,
	datepart(yyyy,fechaInicio), datepart(mm,fechaInicio), datepart(dd,fechaInicio), datepart(hh,fechaInicio), datepart(mi,fechaInicio)
	From (select distinct user_id, 
		tiponotready_id, 
		DATEADD(s, -tstatus, fecha) AS fechaInicio, 
		separado, 
		tStatus, 
		fecha, 
		( select min( sub.fecha) 
			from ccLogAgentesNotReady sub 
			where sub.separado = 1 
			and sub.fecha = nr.fecha 
			and nr.user_id = sub.user_id 
			and nr.tiponotready_id = sub.tiponotready_id ) as fechaFin 
		from ccLogAgentesNotReady nr 
		WHERE fecha >= @from 
		AND fecha < @to )xdet 
	left join ccUserView usr on usr.user_id = xdet.user_id  
	left join ccTipoNotReady tn on tn.tipoNotready_id = xdet.tiponotready_id 
	where usr.user_id is not null
	order by [user], [status], fechaInicio

end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAgentSession]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

if @action = 1
begin

CREATE TABLE #sessionTime(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL)

delete from RepAgentSession with(rowlock) where date >= @from and date < @to

INSERT INTO #sessionTime
exec ccspGenSession @from=@from,@to=@to

insert into RepAgentSession(date,login,userId,[user],extension,loginTime,logoutTime,sessionTime,sessionTimeSeconds,year,month,day,hour,minutes)
select A.login as date,u.Login,A.user_id,
u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + u.nombres as [user], extension,
A.login,a.logout,
datediff(ss,A.login,logout) as sessionTime,
datediff(ss,A.login,logout) as sessionTimeSeconds,
datepart(yyyy,A.login), datepart(mm,A.login), datepart(dd,A.login),
datepart(hh,A.login), datepart(mi,A.login)
 from #sessionTime A
inner join ccUserView u on A.user_id=u.User_id

drop table #sessionTime

end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAgentSessionByInterval]
@action as tinyint,
@from as datetime=null,
@to as datetime=null
AS


if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

if @action = 1
begin

CREATE TABLE #sessionTime(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL)
CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL)
CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)
CREATE TABLE #sessionTimeMayores(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL)

create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
create nonclustered index ix_times2 on #times([Start] DESC)

insert into #times
exec ccspTimesReports @from=@from,@to=@to,@interval=15


INSERT INTO #sessionTime
exec ccspGenSession @from=@from,@to=@to

INSERT INTO #sessionTimeGroup
select user_id,login,logout,extension
,dbo.GetTimeGroup(A.login, 0 ) AS timegroup
,dbo.GetTimeGroup(A.logout, 1 ) AS timegroup_next
 ,datediff(ss,login,logout)
 from #sessionTime as A


INSERT into #sessionTimeMayores SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
delete #sessionTimeGroup where  datediff(mi,timegroup,timegroup_next)>15

insert into #sessionTimeGroup
 select [User_id],login,logout,extension, convert(varchar,th.start,121) as timegroup, convert(varchar, th.stop,121) as timegroup_next,
 isnull((case when th.start <= login and  th.stop > login and th.start <= dateadd(ss,[tlog seg],login) and  th.stop > dateadd(ss,[tlog seg],login) then datediff(ss,login,dateadd(ss,[tlog seg],login))
				when th.start <= login and  th.stop > login and th.stop < dateadd(ss,[tlog seg],login) then datediff(ss,login,th.stop)
				when th.start > login and th.start <= dateadd(ss,[tlog seg],login) and  th.stop > dateadd(ss,[tlog seg],login) then datediff(ss,th.start,dateadd(ss,[tlog seg],login))
				when th.start > login and th.stop < dateadd(ss,[tlog seg],login) then datediff(ss,th.start,th.stop) else  0 end),0) as [tlog seg]

from #sessionTimeMayores t
inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
where  datediff(ss,th.start,timegroup_next)>0;


delete from  RepAgentSessionByInterval where [date] between @from and @to;

insert into RepAgentSessionByInterval(date,login,userId,[user],extension,sessionTime,year,month,day,hour,minutes)
select  A.timegroup,
u.Login,A.user_id,
u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + u.nombres as [user], extension,
A.[tlog seg],
datepart(yyyy,A.timegroup), datepart(mm,A.timegroup), datepart(dd,A.timegroup),
datepart(hh,A.timegroup), datepart(mi,A.timegroup)
 from #sessionTimeGroup A
inner join ccUserView u on A.user_id=u.User_id

drop table #sessionTimeGroup;
drop table #sessionTimeMayores;
drop table #times;
drop table #sessionTime;

end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAnsweredCallsByDialingRetries]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepAnsweredCallsByDialingRetries with(rowlock)
	where date >= @from and date < @to

	INSERT INTO RepAnsweredCallsByDialingRetries
	select
	A.cal_Inicio as [date],
	A.cal_id as [calId],
	A.cal_telefono as [telephone],
	B.tipoResDial_id as [dialResultId],
	resDial.descripcion as [dialResult],
	isnull(C.cal_intentos,0) as [tries],
	A.cam_id as [campaignId],
	E.cam_descripcion as [campaign],
	A.User_id as [userId],
	ISnull(D.Nombres + '' '' + D.ApellidoPaterno + '' '' + D.ApellidoMaterno,''systemTranslated_NoName'') as [agentName],
	isnull(
	(select top 1 Extension from ccLogLogin where user_id=A.User_id and tipoMov=1 and fecha<A.cal_inicio order by fecha desc) 
	,'''')
	as [extension],
	convert(varchar(12),A.cal_Inicio,108) as [startHour],
	convert(varchar(12),dateadd(ss,A.cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,A.cal_Inicio),108) as [endHour],
	cal_tDialog as [dialogTime],
	isnull(A.calif_id,0) as [dispositionId],
	isnull(A.califSub_id,0) as [subDispositionId],
	isnull(disp.Description,''systemTranslated_Dispositionless'') as [disposition],
	isnull(subDisp.califSubDesc,''systemTranslated_NoSubDisposition'') as [subDisposition],
	A.cal_tNotas as [wrapup],
	datepart(yyyy,cal_Inicio) AS [year],
	datepart(mm,cal_Inicio) as [month],
	datepart(dd,cal_Inicio) as [day],
	datepart(hh,cal_Inicio) as [hour],
	datepart(mi,cal_Inicio) as [minutes]


	from ccoCallsOut A
	left join ccoLogDials B on A.cal_id=B.cal_id
	left join ccoCallsOutSource C on C.callout_id=A.callout_id
	left join ccUserView D on A.User_id=D.User_id
	left join ccCamps E on A.cam_id=E.cam_id
	left join ccTipoCalifOUT disp On disp.calif_id=A.calif_id
	left join ccTipoCalifSubOUT subDisp On subDisp.califSub_id=A.califSub_id
	left join ccTipoResultadoDial resDial on resDial.tipoResDial_id=B.tipoResDial_id

	where A.cal_Inicio >= @from
	and A.cal_Inicio < @to
	and A.cal_manual in(0,2)
	order by date
END'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAvgAnswerTimeChats]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
	begin
		delete RepAvgAnswerTimeChats with(rowlock)
		where date >= @from and date < @to

		insert into RepAvgAnswerTimeChats
		select CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121) as [date], userId, [Login], inboundId, [inbound],
		[user], convert(decimal(10,2),(convert(decimal(10,2),sum([answerTime])) / convert(decimal(10,2),count(*)))) as [avgAnswerTime]
		, datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		, datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		, datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		, datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		, datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
		from(
		select requestDate as [date], userId, [Login] as [login], 
		inboundId, c.descripcion as [inbound], nombres + '' '' + apellidopaterno + '' '' + apellidomaterno as [user],
		case when firstMessageTime is null then convert(int,isnull(firstMessageTime,0)) 
		else datediff(ss,chatdate,firstMessageTime) end as [answerTime]
		from ccriachats a
		left join ccUserView b on (a.userId = b.user_id)
		left join ccinbound c on (a.inboundId = c.inbound_id)
		where b.user_id is not null
		and c.inbound_id is not null
		and a.chatstatus = 4) as answerTime
		group by CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121), userId, [Login], inboundId, [inbound], [user]

	end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE  [dbo].[ccspRepAVRSAgentChat]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

if @action = 1
BEGIN

	---Before insert delete first  table dbo.RepAVRSAgent 
	DELETE FROM dbo.RepAVRSAgentChat with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSAgentChat
	select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS lDate,
		a.User_id AS userId,
		a.Login AS lUser,
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agentName, 
		f.total_forma AS Dispositions, 
		f.total_forma AS Disposition2, 
		f.total_forma AS avgDisposition,
		f.id_formato AS idFormato,
		k.nombre AS Template,		
		f.id_chat AS chatId,
		i.Inbound_id AS inboundId,
		i.descripcion AS inbound,	 
		YEAR(f.fecha_calif) AS [year], 
		MONTH(f.fecha_calif) AS [month], 
		DAY(f.fecha_calif) AS [day], 
		CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
		CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
	from dbo.RIA_FORMACALIF_CHAT f
		INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
		INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
									FROM dbo.RIA_FORMATOS
									WHERE activo = 1
									GROUP BY id_formato,nombre) as t 
									ON t.id_formato= f.id_formato
		INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
		INNER JOIN dbo.ccriachats c ON f.id_chat=c.chatId
		INNER JOIN ccinbound AS i ON c.inboundId = i.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
					
END'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAVRSDisposition]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRSDisposition 
	DELETE FROM dbo.RepAVRSDisposition with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSDisposition 
	SELECT f.fecha_calif,t.id_formato,t.nombre,u.User_id,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agente,f.id_grabacion,f.total_forma,
		   YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif),CAST(DATEPART(hour, f.fecha_calif) as varchar(2)),CAST(DATEPART(minute, f.fecha_calif) as varchar(2))
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUserView u 
		 ON f.age_id = u.User_id INNER JOIN( SELECT id_formato,nombre,MAX(version)AS version
							 FROM dbo.RIA_FORMATOS
							 WHERE activo = 1
							 GROUP BY id_formato,nombre ) AS t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	order by f.fecha_calif,t.nombre,u.login
END'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE  [dbo].[ccspRepAVRSRateChat]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN

	---Before insert delete first  table dbo.RepAVRSAgent 
	DELETE FROM dbo.RepAVRSRateChat with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSRateChat
	select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS lDate,
		a.User_id AS userId,
		a.Login AS lUser,
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agentName, 
		f.id_chat AS chatId,
		f.id_formato AS idFormato,
		k.nombre AS Template,
		p.enunciado_pregunta,
		r.etiquetas,
		r.peso AS Dispositions, 
		r.peso AS Disposition2, 
		r.peso AS avgDisposition,
		f.id_forma,
		u.Inbound_id,
		u.descripcion,		 
		YEAR(f.fecha_calif) AS [year], 
		MONTH(f.fecha_calif) AS [month], 
		DAY(f.fecha_calif) AS [day], 
		CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
		CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
	from dbo.RIA_FORMACALIF_CHAT f
		INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
		INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
									FROM dbo.RIA_FORMATOS
									WHERE activo = 1
									GROUP BY id_formato,nombre) as t 
									ON t.id_formato= f.id_formato
		INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
		INNER JOIN RIA_RESULTADOSFORMA_CHAT r ON f.id_forma=r.id_forma
		INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
		INNER JOIN dbo.ccriachats c ON f.id_chat=c.chatId
		INNER JOIN ccinbound AS u ON c.inboundId = u.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
					
END'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepAVRSScores]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null 
	select @to = getdate()	

if @action = 1
BEGIN
	---Before insert delete first  table dbo.RepAVRSDisposition 
	DELETE FROM dbo.RepAVRSScores with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSScores
	--By Agent
	SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS agent,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		YEAR(f.fecha_calif) AS [year],MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], 0 AS [hour], 0 AS [minute]
	FROM dbo.RIA_FORMACALIF f 
	INNER JOIN dbo.ccUserView u
		 ON f.age_id = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
							 FROM dbo.RIA_FORMATOS
							 WHERE activo = 1
							 GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)),u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres,YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif)
	UNION ALL
	--By Supervisor
	SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) as fecha,u.User_id,u.Login,(u.apellidopaterno+'' ''+u.apellidomaterno+'' ''+u.nombres) AS supervisor,count(u.User_id) AS scores,avg(cast(f.total_forma AS float)) AS average,
		  YEAR(f.fecha_calif) AS [year],MONTH(f.fecha_calif) AS [month], DAY(f.fecha_calif) AS [day], 0 AS [hour], 0 AS [minute]
	FROM dbo.RIA_FORMACALIF f INNER JOIN dbo.ccUserView u
		 ON f.id_supervisor = u.User_id INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1
								GROUP BY id_formato,nombre) as t
		 ON f.id_formato = t.id_formato AND f.version = t.version
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
	GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)),u.Login,u.User_id,u.apellidopaterno,u.apellidomaterno,u.nombres,YEAR(f.fecha_calif),MONTH(f.fecha_calif),DAY(f.fecha_calif)
END'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepCallXfer]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()

	delete RepCallXfer with(rowlock)
	where [date] between @from and @to
				
	insert RepCallXfer 
	select convert(varchar(10),fechafin,121) [date],
	clt.cal_id callid, case when tipo = 1 then ''systemTranslated_inbound'' else ''systemTranslated_outbound'' end CallTypes, 
	isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccUserView nolock where user_id = 
	(case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') Agent,
	case when modo = 0 then ''systemTranslated_blindXfer'' 
	when modo = 1 then ''systemTranslated_Agent'' 
	when modo = 2 then 
		case when cast(clt.destino as int) >= 0 then ''systemTranslated_acd'' else ''systemTranslated_Survey'' end
	when modo = 3 then ''systemTranslated_conference'' 
	when modo = 4 then ''systemTranslated_supXfer'' 
	when modo = 5 then ''systemTranslated_overflow'' end as xfertype,
	case when modo = 0 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
	when modo = 1 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),''systemTranslated_Indefinite'') 
	when modo = 2 then 
		case when cast(clt.destino as int) >= 0 then
			isnull((select descripcion from ccinbound where inbound_id = clt.destino),''systemTranslated_Indefinite'') 
		else
			isnull((select description from survey where scriptId = abs(cast(clt.destino as int))),''systemTranslated_Indefinite'') 
		end
	when modo = 3 then isnull((select nombre from telefonosConferencia where tel = clt.destino),clt.destino) 
	when modo = 4 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
	when modo = 5 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end destination,
	tantesxfer timebeforexfer,
	tdespuesxfer timeafterxfer,
	dateadd(ss,-(tantesxfer + tdespuesxfer),fechafin) startDate,
	fechafin as endDate,		
	case when camp.cam_descripcion is not null then  camp.cam_descripcion 
	when inbound.descripcion is not null then  inbound.descripcion				
	else ''systemTranslated_Indefinite'' end as Origin,
	tantesxfer+tdespuesxfer as TotalTimeDuration,				
	case tipo when 1 then isnull((select case dbo.fnGettipollamada(cal_ANI) when 1 then ''systemTranslated_fijo''
			when 3 then ''systemTranslated_cellPhone'' else ''systemTranslated_interno'' end from ccCallsIn where cal_id= clt.cal_id
			),''systemTranslated_Indefinite'')
	else
	isnull((
		select case dbo.fnGettipollamada(cal_telefono) when 1 then ''systemTranslated_fijo''
			when 3 then ''systemTranslated_cellPhone'' else ''systemTranslated_interno'' end from ccoCallsOut where cal_id = clt.cal_id					
	),''systemTranslated_Indefinite'')
	end as TipoTel
	from cclogtransfers clt 
	left join ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
	left join cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1
	left join cccamps camp on camp.cam_id =co.cam_id
	left join ccinbound inbound on inbound.Inbound_id =ci.Inbound_id
	WHERE fechafin >= @from and fechafin < @to
end
	'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepCatalogos]
@type as tinyint,
@action tinyint = 0 -- 0 Filter select; 1 Filters Range
,@userId int =0 ---- se agrega parametro para filtros

AS
declare @tablatemp table (id int, description varchar(100) null)
declare @tempwork table
(idwg int)

if @action = 0
begin


	-- CAMPAIGNS
if @type = 1 begin

	if @userId <> 0 begin

		insert into @tablatemp
		select distinct caesp.IdCampEsp,'''' as description  from ccUserView us
		inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
		inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=1
		where us.[User_id] = @userId

		SELECT cam_id as id, cam_descripcion as description, ''campaignId'' as dbColumn
			from ccCamps camp
			inner join @tablatemp A on camp.cam_id = A.id

	end
	else begin
		SELECT cam_id as id, cam_descripcion as description, ''campaignId'' as dbColumn
			from ccCamps camp

	end
end


	-- DIAL RESULTS
if @type = 2 begin
	Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn
	from ccTipoResultadoDial
	order by descripcion
end

	-- WORKGROUPS
if @type = 3 begin
	if @userId <> 0 begin

		insert into @tempwork
		select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

		select distinct catwor.IDWG as id,catwor.WGName as description,''workgroupId'' as dbColumn from ccRIAWorkGroupUsers wgu
		inner join ccRIACat_WorkGroup catwor on wgu.IDWG = catwor.IDWG
		left join @tempwork temp on wgu.IDWG = temp.idwg
		where catwor.StatusWorkGroup = 1
		return
	end
	else  begin
		select idwg as id, wgname as description, ''workgroupId'' as dbColumn
		from ccRIACat_WorkGroup
		group by idwg, wgname	select * from ccRIACat_WorkGroup
		order by wgname
	end
end


-- AREAS
if @type = 4 begin
if @userId <> 0 begin

	insert into @tablatemp
	select distinct wgu.User_id,caesp.IDArea  from ccUserView us
	inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
	left join ccUserView caesp on wgu.IDWG = caesp.User_id
	where us.[User_id] = @userId

	select distinct idArea as id, AreaName as description, ''areaId'' as dbColumn
	from ccRIACat_Areas area inner join @tablatemp tem on area.IDArea = tem.id
	return
end
	else begin

		select idArea as id, AreaName as description, ''areaId'' as dbColumn
		from ccRIACat_Areas
		group by idArea, AreaName
		order by AreaName
	end
end

-- DISPOSITIONS OUT
if @type = 5 begin
	SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
	FROM ccTipoCalifOut
	order by [description]
end

	-- USE
if @type = 6 	begin
	if @userId <> 0 begin

			insert into @tempwork
					select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

			select distinct us.User_id as id, us.Login as description,  ''userId'' as dbcolumn from ccUserView us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

			inner join @tempwork awg on wgu.IDWG = awg.idwg
			where us.TipoUser_id = 1 and [status] = 1

			return
		end

		else begin

			SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn
			FROM ccUserView B WHERE [status] = 1 and TipoUser_id = 1
			ORDER BY description
		end
end

	-- ACDS**************
if @type = 7 begin
	if @userId <> 0 begin
			insert into @tablatemp
			select distinct caesp.IdCampEsp,'''' as description  from ccUserView us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
			inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
			where us.[User_id] = @userId


			SELECT inbound_id as id, descripcion as description, ''inboundId'' as dbColumn
				from ccinbound B
				inner join @tablatemp A on B.inbound_id = A.id
				return
		end
		else begin
			select inbound_id as id, descripcion as description, ''inboundId'' as dbColumn
				from ccinbound
		end
end

	-- DIDS
if @type = 8 	begin
	select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
	from ccdnis
end

	--DISPOSITIONS IN
if @type = 9 begin
	SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
	FROM ccTipoCalif
	order by [description]
end

	--SUBDISPOSITIONS IN
if @type = 10	begin
	SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
	FROM ccTipoCalifSub
	order by [description]
end

	--PROVIDER
if @type = 11 begin
	SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
	FROM cstoProvedor
	order by [description]
end

	-- UNAVAILABLES
if @type = 12 begin
	SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn
	FROM cctiponotready
	order by descripcion
end

	-- DIALERS
if @type = 13 begin
	SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn
	FROM ccoDialers
	order by descripcion
end

	-- CallTYpes
if @type = 14	begin
		SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn
		FROM ccStatusLlamada
	order by descripcion
end

	-- SUBDISPOSITIONS OUT
if @type = 21	begin
	SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
	FROM cctipocalifsubout
	order by [description]
end

	-- AVRS TEMPLATE-SECTION
if @type = 15 	begin
	SELECT c.id_concepto as id, (t.nombre+''-''+c.con_descripcion) as description, ''sectionId'' as dbColumn
	FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,nombre,MAX(version) as version
									FROM RIA_FORMATOS
									WHERE activo = 1
									group by id_formato,nombre) as t
	ON f.id_formato = t.id_formato AND f.version = t.version INNER JOIN RIA_CONCEPTOS c
	ON t.id_formato = c.id_formato AND t.version = c.version
	order by f.nombre
end

	-- AVRS TEMPLATES
if @type = 16 	begin
	SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn
	FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
									FROM RIA_FORMATOS
									WHERE activo = 1
									group by id_formato) as t
	ON f.id_formato = t.id_formato AND f.version = t.version
	order by f.nombre
end

	-- AVRS SUPERVISOR
if @type = 17 	begin
	SELECT [user_id] as id, [login] AS description, ''supervisorId'' as dbColumn
	FROM ccUserView
	WHERE [status] = 1
	and TipoUser_id = 2
	ORDER BY [login]
end

	--Status Call
if @type = 25 	begin
	select statusCall_id as id, [descripcion] as description, ''statusCallId'' as dbcolumn
	from ccstatusllamada
	order by [descripcion]
end

	--Survey
if @type = 26 	begin
	select surveyId as id, [description] as description, ''surveyId'' as dbcolumn
	from Survey
	order by [description]
end

--dialType
if @type = 29 begin
	select dialId as id, [description] as description, ''dialId'' as dbcolumn
	from dialType
	order by [description]
end

	--dial
if @type = 30 	begin
	select id as id, [description] as description, ''dialId'' as dbcolumn
	from Dials
	order by [description]
end

end
-----------------------------------------------------------
if @action = 1 begin
	-- TRUNKS
	if @type = 13
	begin
		SELECT MIN(trunk) as [min],MAX(trunk) as [max],''trunk'' as dbColumn  from RepTrunkBusy
	end

	-- AVRS DISPOSITION
	if @type = 18
	begin
		SELECT 0 as [min], 100 as [max],''Disposition'' as dbColumn
	end

	-- AVG DISPOSITION
	if @type = 19
	begin
		SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
	end

	-- SCORE
	if @type = 20
	begin
		SELECT 0 as [min], 100 as [max],''score'' as dbColumn
	end
end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepChatsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1 
	begin
		
		delete from RepChatsDetail with(rowlock)
		where date >= @from AND date < @to
	
		insert into RepChatsDetail
			select requestDate,
			inboundId, b.descripcion, chatstatus, c.description, disposition, isnull(d.description,''''),
			subDisposition, isnull(califSubDesc,''''), domain, userid, isnull(f.login,''''), clientName, tqueue,
			0 as txfer, tchatting, 
			isnull(nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''') as Nombre,
			datepart(yyyy,CONVERT(varchar(20), requestDate, 120)) as [year],
			datepart(mm,CONVERT(varchar(20), requestDate, 120)) as [month],
			datepart(dd,CONVERT(varchar(20), requestDate, 120)) as [day],
			datepart(hh,CONVERT(varchar(20), requestDate, 120)) as [hour],
			datepart(mi,CONVERT(varchar(20), requestDate, 120)) as [minutes]
			from ccRIAChats
			left join ccInbound b on (inboundId = inbound_id)
			left join ccRIAChatStatus c on (chatstatus = id)
			left join ccTipoCalif d on (calif_id = disposition)
			left join ccTipoCalifSub e on (califSub_id = subDisposition)
			left join ccUserView f on (User_id = userid)
			where requestDate >= @from and requestDate < @to
			
			select isnull(datediff(ss,requestDate,chatdate) - tqueue,0) as xferTime, requestDate as date
			into #tmpxferTime
			from ccRIAChats where chatstatus = 4
			
			update RepChatsDetail set xferTime = b.xferTime
			from RepChatsDetail a, #tmpxferTime b where a.date = b.date 
			
			drop table #tmpxferTime 
	end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepDetailAgent]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
declare @califout as varchar(3) , @califin as varchar(3)

set @califout =''1''
set @califin =''1''


BEGIN
SET ANSI_WARNINGS off
SET NOCOUNT ON

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to =getdate()
if @action=1 begin

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
	declare @var varchar(100)
	select @var= valor from ccsettings where setting_id = 39
	select @califout = Value from dbo.fn_RIASplitDelimited(@var,''|'') where Id=1
	select @califin =  Value from dbo.fn_RIASplitDelimited(@var,''|'') where Id=2

	
	create table #inboundData(
	[row] int identity primary key,Inbound_id int,[User_id] int,phone_in varchar(30),cal_id int,dni_id int,
	dateStartDetail datetime,dateEndDetail datetime,timegroup datetime,timegroup_next datetime,
	time_endque datetime,time_ring datetime,time_dialog datetime,time_notes datetime,
	time_end_call datetime,ntotal int,ninitial int,nout_hour int,nout_service int,nabnd int,
	nno_agent int,nque int,ntimeout int,noverflow int,nxfer int,nxfer_que int,
	nabnd_xfer int,nabnd_ring int,nno_answer int,nabnd_dialog int,nanswer int,nlost int,
	nmsg int,nabnd_tres int,nansw_tres int,tque_max int,tque int,txfer int,tdialog int,
	tnotes int,tring int,tresp int,nMoh int,nWHag int,nWHcl int, calif_id int, califSub_id int)

	create nonclustered index iX_InboundUserId on #inboundData([Inbound_id] DESC,[User_id] DESC)

	create table #outboundData(
	row int identity,cam_id int,[User_id] int,cal_id int,cal_puerto int,phone_out varchar(30),
	dateStartDetail datetime,dateEndDetail datetime,timegroup datetime,timegroup_next datetime,
	ntotal int,nno_agent int,nxfer int,nabnd_xfer int,nabnd_ring int,nno_answer int,nabnd_dialog int,nanswer int,
	nlost int,tque int,txfer int,tring int,tdialog int,tnotes int,tresp int,nhangup int,
	nMoh int,nWHag int,nWHcl int,time_endque datetime,time_ring datetime,time_dialog datetime,
	time_notes datetime,time_end_call datetime, calif_id int, califSub_id int)

	create nonclustered index iX_CamUserId on #outboundData([cam_id] DESC,[User_id] DESC)

	CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

	create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on #times([Start] DESC)

	create table #timeDetailAgent([User_id] int null,dateStartDetail datetime null,dateEndDetail datetime null,timegroup datetime null,	timegroup_next datetime null,tunknown int null,tnot_av int null,tav int null,tprob int null,tother int null,nother int null,tmanualcall int null,tunknown2 decimal(10,3),tchatting int null)

	--Tiempo ultimo Status del agente
	create table #tempAgentLastStatus(id int,fecha datetime,tiempo int)

	--
	CREATE TABLE #sessionTime(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL)
	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)
	CREATE TABLE #sessionTimeMayores(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)

	--TIempos del agente
	create table #tempccLogAgentesDia(row int not null,user_id int not null,TipoStatusAge_id tinyint not null,tStatus int not null,dateIni datetime not null,dateEnd datetime not null,currentStatus int)

	insert into #times
	exec ccspTimesReports @from=@from,@to=@to,@interval=@interval

	--Sessiones del agente
	insert into #sessionTime exec ccspGenSession @from=@from,@to=@to	
	select @maxLogout=max(logout) from #sessionTime

	if CONVERT(varchar(11),@maxLogout,121)=CONVERT(varchar(11),@dateNow,121) and @dateNow>@maxLogout set @dateNow=@maxLogout

	INSERT INTO #sessionTimeGroup
	select user_id,login,logout,extension,
	dbo.GetTimeGroup(A.login,0) AS timegroup	
	,dbo.GetTimeGroup(A.logout,1) AS timegroup_next
	 ,datediff(ss,login,logout)
	 from #sessionTime as A

	 INSERT into #sessionTimeMayores SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
	delete #sessionTimeGroup where  datediff(mi,timegroup,timegroup_next)>15

	insert into #sessionTimeGroup
	 select [User_id],login,logout,extension, convert(varchar,th.start,121) as timegroup, convert(varchar, th.stop,121) as timegroup_next,
	 isnull((
		case when th.start <= login and  th.stop > login and th.start <= dateadd(ss,[tlog],login) and  th.stop > dateadd(ss,[tlog],login) then datediff(ss,login,dateadd(ss,[tlog],login))
			 when th.start <= login and  th.stop > login and th.stop < dateadd(ss,[tlog],login) then datediff(ss,login,th.stop)
			 when th.start > login and th.start <= dateadd(ss,[tlog],login) and  th.stop > dateadd(ss,[tlog],login) then datediff(ss,th.start,dateadd(ss,[tlog],login))
			 when th.start > login and th.stop < dateadd(ss,[tlog],login) then datediff(ss,th.start,th.stop) else  0 end),0) as [tlog seg]

	from #sessionTimeMayores t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0;

	--inserto ultimo tiempo del agente del dia
	insert into #tempAgentLastStatus
	select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),@dateNow) from ccLogAgentesDia where convert(varchar(11),fecha,121)=CONVERT(varchar(11),@dateNow,121) group by User_id

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service
	,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl, calif_id, califSub_id
	)
	select * from (
	SELECT case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end as dateStartDetail,
		   dateadd(ss,0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,
			case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end )
			dateEndDetail
			,dbo.GetTimeGroup(case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end,0) AS timegroup	
			,dbo.GetTimeGroup(
			dateadd(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas ,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end )
			,1) AS timegroup_next						 
		   ,DATEADD(ss,isnull((0),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_endque
		   ,DATEADD(ss,isnull((0 + cal_txfer),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_ring
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_dialog
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_notes
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_end_call
		   ,cal_Ani as phone_in,cal_id,dni_id,Inbound_id,[User_id]
		   ,1 AS ntotal
		   ,ISNULL((CASE WHEN statuscall_id=1 THEN 1 ELSE 0 END),0) AS ninitial
		   ,ISNULL((CASE WHEN statuscall_id=2 THEN 1 ELSE 0 END),0) AS nout_hour
		   ,ISNULL((CASE WHEN statuscall_id=3 THEN 1 ELSE 0 END),0) AS nout_service
		   ,ISNULL((CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nabnd
		   ,ISNULL((CASE WHEN(statuscall_id=4)THEN 1 ELSE 0 END),0) AS nno_agent
		   ,ISNULL((CASE WHEN(cal_que>0)THEN 1 ELSE 0 END),0) AS nque
		   ,ISNULL((CASE WHEN(statuscall_id=7)THEN 1 ELSE 0 END),0) AS ntimeout
		   ,ISNULL((CASE WHEN(statuscall_id=8)THEN 1 ELSE 0 END),0) AS noverflow
		   ,ISNULL((CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nxfer
		   ,ISNULL((CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN 1 ELSE 0 END),0) AS nxfer_que
		   ,ISNULL((CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nabnd_xfer
		   ,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE 0 END),0) AS nabnd_ring
		   ,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE 0 END),0) AS nno_answer
		   ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE 0 END),0) AS nabnd_dialog
		   ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE 0 END),0) AS nanswer
		   ,ISNULL((CASE WHEN(statuscall_id=16)THEN 1 ELSE 0 END),0) AS nlost
		   ,ISNULL((CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE 0 END),0) AS nmsg
		   ,ISNULL((CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE 0 END),0) AS nabnd_tres
		   ,ISNULL((CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE 0 END),0) AS nansw_tres
		   ,cal_twait AS tque_max, cal_twait as tque, cal_txfer AS txfer
		   ,ISNULL((cal_tdialog),0)AS tdialog,ISNULL((cal_tnotas),0)AS tnotes,ISNULL((cal_tring),0)AS tring
		   ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE 0 END),0)AS tresp
		   ,ISNULL((case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
		   ,ISNULL((CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL((CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
		   ,calif_id,califSub_id
		   FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		   WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
		   )inboundData
		   where not(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
		   AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
		   AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
		   AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)

	update C
	set C.dateEndDetail=@dateNow
	,C.timegroup_next= dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1) 	
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

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl,calif_id,califSub_id)
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
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl,
	t.calif_id, t.califsub_id
	from #inboundData2 t
	join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	order by cal_id

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,calif_id,califSub_id)
	select * from (
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		,dbo.GetTimeGroup(cal_inicio,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),1) as timegroup_next			   
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
		   ,calif_id,califSub_id
		   FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
		   WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to
		   -- para contar bien las llamadas manuales
		   and cal_manual in(0,2)
		   group by cal_id,[User_id],cam_id,cal_Inicio,cal_puerto,calif_id,califSub_id
		   )outboundData
		   where not(ntotal=0 AND nno_agent=0 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
				   AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
				   AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0 )

	 update C
	 set C.dateEndDetail=@dateNow
	 ,C.timegroup_next= dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1)	 
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

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,calif_id,califSub_id)
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
	,calif_id,califSub_id
	from #outboundData2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

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
	,dbo.GetTimeGroup(A.dateIni,0) as timegroup
	,dbo.GetTimeGroup(A.dateEnd,1) as timegroup_next,
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
		,dbo.GetTimeGroup(B.fecha,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1) as timegroup_next
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
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tchatting,dateStartDetail) and  th.stop > dateadd(ss,tchatting,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tchatting,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tchatting,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tchatting,dateStartDetail) and  th.stop > dateadd(ss,tchatting,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tchatting,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tchatting,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tchatting
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	select
	ROW_NUMBER() OVER(PARTITION BY xTimeDetail.user_id ORDER BY xTimeDetail.timegroup) AS Row,
	xTimeDetail.timegroup
	,xTimeDetail.[user_id]
	,timeSession.tlog
	,xTimeDetail.tav,
	xTimeDetail.tnot_av
	,xTimeDetail.tprob,xTimeDetail.tother,xTimeDetail.tunknown,xTimeDetail.tchatting,xTimeDetail.tmanualCall
	,xTimeDetail.nother
	,isnull(B.txfer,0)+isnull(C.txfer,0) as txfer
	,isnull(B.tdialog,0)+isnull(C.tdialog,0) as tdialog
	,isnull(B.tnotes,0)+isnull(C.tnotes,0) as tnotes
	,isnull(B.tring,0)+isnull(C.tring,0) as tring
	,isnull(B.nMoh,0)+isnull(C.nMoh,0) as nMoh
	,isnull(B.nWHag,0)+isnull(C.nWHag,0) as nWHag
	,isnull(B.nWHcl,0)+isnull(C.nWHcl,0) as nWHcl
	,isnull(B.ntotal,0)+isnull(C.ntotal,0) as ntotal
	,C.completeOut, B.completeIn
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
	(
		select user_id,timegroup,sum(tlog) as tlog from #sessionTimeGroup group by user_id,timegroup
	) timeSession
	on xTimeDetail.User_id=timeSession.user_id and xTimeDetail.timegroup=timeSession.timegroup
	left join
	(
		select user_id,timegroup,sum(txfer) as txfer,sum(tring) tring,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl,
		case when sum(ntotal)<count(A.calif_id) then count(A.calif_id) else sum(ntotal) end as ntotal
		,sum(case when A.calif_id = @califin then 1 else 0 end) as completeIn		
		from #inboundData A
		inner join cctipocalif B on A.calif_id=B.calif_id --and A.calif_id = @califin			
		group by user_id,timegroup
	) B
	on xTimeDetail.timegroup=B.timegroup and xTimeDetail.User_id=B.User_id
	left join	
	(
		select user_id,timegroup,sum(txfer) as txfer,sum(tring) tring,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl,
		case when sum(ntotal)<count(A.calif_id) then count(A.calif_id) else sum(ntotal) end as ntotal
		,sum(case when A.calif_id = @califout then 1 else 0 end) as completeOut
		from #outboundData A
		inner join cctipocalifout B on A.calif_id=B.calif_id 
		group by user_id,timegroup
	) C
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


		delete from RepDetailAgent where date>=@from and date<@to

		insert into RepDetailAgent
		select
		A.User_Id,
		min(B.Login) as ''usuario'',
		min((B.Nombres + space(1) + b.ApellidoPaterno + space(1) + b.ApellidoMaterno)) ''NombreAgente'',
		convert(varchar(14),A.timegroup,120)+''00:00'' as [fecha],
		sum(A.tlog) ''Tiempo de sesion'',
		sum(a.tlog - tnot_av) as [Tiempo de operacion] -- tlog - tiempoAuxiliares
		,sum(txfer+tring+tdialog+tnotes) as [Tiempo en dialogo]
		,sum(txfer+tring) as [Tiempo en espera]
		,sum(tnot_av) as [Tiempo en no disponibles]
		,sum(cast((convert(float,tdialog)/36) as decimal(18,3))) as [% en dialogo]
		,sum(cast((convert(float,txfer+tring)/36) as decimal(18,3))) as [% en espera]
		,sum(cast((convert(float,tav)/36) as decimal(18,3))) as [% en disponible]
		,convert(decimal(10,3), convert(decimal(10,3),sum(tlog - tnotes))/sum(tlog)) as [Adherencia]
		,sum(ntotal) as [Numero de llamadas]
		,sum(ntotal) as [Numero de llamadas por hora]--convert(decimal(10,4),convert(decimal(10,4),sum(ntotal))/7) as [Numero de llamadas por hora]
		,count(completeOut)+count(completeIn) as [Completo]
		,convert(decimal(10,4),convert(decimal(10,4),count(completeOut)+count(completeIn))/7) as [Completo por hora]
		,convert(decimal(10,4),isnull(convert(decimal(10,4),count(completeOut)+count(completeIn))/nullif(sum(ntotal),0),0)) as [Completo / llamadas]
		,datepart(YYYY,min(A.timegroup)) [year]
		,datepart(MM,min(A.timegroup)) [month]
		,datepart(DD,min(A.timegroup)) [day]
		,datepart(HH,min(A.timegroup)) [hour]
		,''0'' [minutes]
		from #agentInformation A
		inner join ccUserView B on A.User_id=B.User_id
		group by convert(varchar(14),A.timegroup,120)+''00:00'', A.User_id

	---DROP TABLES TEMP
	drop table #sessionTime
	drop table #times
	drop table #inboundData
	drop table #inboundData2
	drop table #outboundData
	drop table #outboundData2
	drop table #timeDetailAgent
	drop table #timeDetailAgent2
	drop table #agentInformation	

	drop table #tempAgentLastStatus
	drop table #tempccLogAgentesDia
	drop table #tempccLogAgentesDia2
	drop table #sessionTimeGroup
	drop table #sessionTimeMayores;
end
END'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepDialingResultsDetail]
@action as tinyint,
@from as datetime=null,
@to as datetime=null
AS

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

if @action = 1
begin


delete from  RepDialingResultsDetail where [date] between @from and @to

insert into RepDialingResultsDetail(date,telephone,dialResultId,dialResult,userId,login,campaignId,campaign,year,month,day,hour,minutes)
select dial.fecha as [date],dial.Telefono as [telephone],dial.tipoResDial_id as dialResultId,isnull(tr.descripcion,dial.disconnectCause) as dialResult,
isnull(co.User_id,0) as userId,isnull(cast(u.Login  as varchar(50)),''systemTranslated_NoUserName'') as [Login],
dial.cam_id as campaignId,camp.cam_descripcion as campaign
,datepart(yyyy,dial.fecha) as [year]
,datepart(mm,dial.fecha) as [month]
,datepart(dd,dial.fecha) as [day]
,datepart(hh,dial.fecha) as [hour]
,datepart(mi,dial.fecha) as [minute]
FROM ccoLogDials dial (nolock)
left join ccocallsout co (nolock) on dial.cal_id=co.cal_id
left join cctipoResultadoDial tr ON dial.tiporesdial_id=tr.tiporesdial_id
left join ccUserView u on u.user_id =co.User_id
left join ccCamps camp on camp.cam_id=dial.cam_id
where dial.fecha>=@from and dial.fecha<@to


end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepEmailACD]

@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

delete from RepEmailACD with(rowlock) where date >= @from AND date < @to

	insert into RepEmailACD
	select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121) date,
		isnull(descripcion,'''') as inboundName, isnull(inboundid,0) as inboundid,
		isnull(count(*),0) Downloads,isnull(sum(unassigned),0) as unassigned, isnull(sum(onTrack),0) onTrack,
		isnull(sum(rejected),0) rejected,isnull(sum(assigned),0) assigned,isnull(sum(actives),0) actives,
		isnull(sum(pendingSend),0) as pendingSend,
		isnull(sum(abandonedsystem),0) abandonedsystem, isnull(sum(abandonedbyagent),0) abandonedbyagent,
		isnull(sum(abandonedsystem+abandonedbyagent),0) finishedconversation,
		isnull(isnull(sum(sendMail),0)/nullif(cast(count(*) as float) ,0),0) * 100 as  sentvsdownloaded,
		isnull(sum(tQueue),0) tQueue, isnull(sum(tsent),0) tsent, isnull(sum(twait),0) twait,
		isnull(sum(tatention)/nullif(sum(pendingSend+onTrack+rejected+abandonedsystem+abandonedbyagent),0),0) tAvgAtentionMultimedia,
		isnull(sum(twrapup),0) twrapup,
		datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [year],
		datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [mounth],
		datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [day],
		datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [hour],
		datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [minute]
	 from (
		select msg.date date,
				 inbo.descripcion descripcion ,inbo.inbound_id inboundid,
				 case when msg.messagestatusid in (1,4) then 1 else 0 end unassigned,
				 case when msg.messagestatusid = 2 then 1 else 0 end assigned,
				 case when msg.messagestatusid = 3 then 1 else 0 end actives,
				 case when msg.messagestatusid = 5 then 1 else 0 end pendingSend,
				 case when msg.messagestatusid = 6 then 1 else 0 end onTrack,
				 case when msg.messagestatusid in (7,8,9) then 1 else 0 end rejected,
				 case when msg.messagestatusid = 10 then 1 else 0 end abandonedsystem,
				 case when msg.messagestatusid = 11 then 1 else 0 end abandonedbyagent,
				 case when msg.messagestatusid in(6,10,11) then 1 else 0 end sendMail,
				  case when msg.messagestatusid = 13 then 1 else 0 end emailSpam,

				 datediff(second,msg.date,isnull(msg.tqueue,getdate())) tQueue,
				 datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) tsent,
				 msg.twait twait,
				 msg.twait + msg.tretention + msg.tresponse tatention,
				 msg.twrapup twrapup
				 from [message] msg inner join [conversation] conv
				on msg.conversationId = conv.conversationId
				left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
				left join ccUserView usuario on usuario.User_id = msg.userid
				where msg.date >= @from AND msg.date < @to
				)x
				group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion ,inboundid
end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepEmailAgente]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepEmailAgente with(rowlock)	where date >= @from AND date < @to

	insert into RepEmailAgente
	select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121) date,
		isnull(name,'''') as name, isnull(userid,0) as userId,
		isnull(descripcion,'''') as inboundName, isnull(inboundid,0) as inboundid,
		isnull(count(*),0) Downloads,isnull(sum(messageUnAssigned),0) messageUnAssigned, isnull(sum(onTrack),0) onTrack,
		isnull(sum(rejected),0) rejected,isnull(sum(assigned),0) assigned,isnull(sum(actives),0) actives,
		isnull(sum(pendingSend),0) as pendingSend,
		isnull(sum(abandonedsystem),0) abandonedsystem, isnull(sum(abandonedbyagent),0) abandonedbyagent,
		isnull(sum(abandonedsystem+abandonedbyagent),0) finishedconversation,
		isnull(isnull(sum(sendMail),0)/nullif(cast(count(*) as float) ,0),0) * 100 as  sentvsdownloaded,

		isnull(sum(tQueue),0) tQueue, isnull(sum(tsent),0) tsent, isnull(sum(twait),0) twait,
		isnull(sum(tatention)/nullif(sum(pendingSend+onTrack+rejected+abandonedsystem+abandonedbyagent),0),0) tAvgAtentionMultimedia,
		isnull(sum(twrapup),0) twrapup,
		datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [year],
		datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [mounth],
		datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [day],
		datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [hour],
		datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [minute]
	 from (
		select msg.date date,msg.messageid,
			 inbo.descripcion descripcion ,inbo.inbound_id inboundid,
			 usuario.nombres as name,usuario.[User_Id] as userid,
			 case when msg.messagestatusid in (1,4) then 1 else 0 end unassigned,
			 case when msg.messagestatusid = 2 then 1 else 0 end assigned,
			 case when msg.messagestatusid = 3 then 1 else 0 end actives,
			 case when msg.messagestatusid = 5 then 1 else 0 end pendingSend,
			 case when msg.messagestatusid = 6 then 1 else 0 end onTrack,
			 case when msg.messagestatusid in (7,8,9) then 1 else 0 end rejected,
			 case when msg.messagestatusid = 10 then 1 else 0 end abandonedsystem,
			 case when msg.messagestatusid = 11 then 1 else 0 end abandonedbyagent,
			 case when msg.messagestatusid in(6,10,11) then 1 else 0 end sendMail,
			 case when msg.messagestatusid = 13 then 1 else 0 end emailSpam,
			 sum(case when msgun.messageid is null then 0 else 1 end) messageUnAssigned,
			 datediff(second,msg.date,isnull(msg.tqueue,getdate())) tQueue,
			 datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) tsent,
			 msg.twait twait,
			 msg.twait + msg.tretention + msg.tresponse tatention,
			 msg.twrapup twrapup
			 from [message] msg
			 inner join [conversation] conv on msg.conversationId = conv.conversationId
			 left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
			 left join ccUserView usuario on usuario.User_id = msg.userid
			 left join messageUnAssigned msgun on msg.UserId=msgun.UserId and msgun.messageId = msg.messageId
			 where  msg.userId>0 and msg.date >= @from AND msg.date < @to
			 group by msg.messageid,msg.date,inbo.descripcion,inbo.inbound_id,usuario.nombres,usuario.[User_Id],msg.messagestatusid,msg.tqueue,
			 msg.twait, msg.tretention, msg.tresponse, msg.twrapup, msg.tSend

			)x
			group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion ,inboundid,name,userId

end
	'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER procedure [dbo].[ccspRepEmailDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepEmailDetail with(rowlock)
	where date >= @from AND date < @to

	insert into RepEmailDetail
	select msg.date date,
	case when msg.messagestatusid = 1 then ''systemTranslated_Download_emails_from_server''
	when msg.messagestatusid = 2 then ''systemTranslated_Assign_message_to_agent''
	when msg.messagestatusid = 3 then ''systemTranslated_Read_the_message_agent''
	when msg.messagestatusid = 4 then ''systemTranslated_Unassign_message_to_agent''
	when msg.messagestatusid = 5 then ''systemTranslated_Message_answered_by_agent''
	when msg.messagestatusid = 6 then ''systemTranslated_Message_sent_to_the_client''
	when msg.messagestatusid in (7,8,9) then ''systemTranslated_Message_rejected_for_server''
	when msg.messagestatusid = 10 then ''systemTranslated_conversation_closed_for_system''
	when msg.messagestatusid = 13 then ''systemTranslated_Message_email_Spam''	
	when msg.messagestatusid = 11 then ''systemTranslated_Close_conversation_for_agent'' else '''' end statusMail,

	conv.mailClient mailClient, isnull(inbo.descripcion,'''') descripcion,
	isnull(inbo.inbound_id,0) inboundid, msg.conversationId conversationid,msg.messageId,
	msg.messagestatusid messagestatusid,
	isnull(datediff(second,msg.[date],isnull(msg.tqueue,getdate())),0) tQueue, msg.twait,
	isnull((msg.twait + msg.tretention + msg.tresponse),0) tAtentionMultimedia, msg.twrapup,
	isnull(datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend),0) tsent,
	datepart(yyyy,date) [year],
	datepart(mm,date) [mounth],
	datepart(dd,date) [day],
	datepart(hh,date) [hour],
	datepart(mi,date) [minute],
	msg.tresponse as tfocus
	from [message] msg inner join [conversation] conv
	on msg.conversationId = conv.conversationId left join [ccInbound] inbo
	on inbo.inbound_Id = conv.inboundId
	left join ccUserView usuario on usuario.User_id = msg.userid  left join messageUnAssigned msgun on msg.messageid = msgun.messageid
	where msg.date >= @from AND msg.date < @to
	order by date,msg.conversationId,msg.messageId

end
	'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER procedure [dbo].[ccspRepEmailGeneral]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepEmailGeneral with(rowlock) where date >= @from AND date < @to

	insert into RepEmailGeneral
	select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),isnull(descripcion,'''') descripcion ,inboundid,
	case max(messagestatusid) when 1 then ''systemTranslated_Download_emails_from_server''
	when 2 then ''systemTranslated_Assign_message_to_agent''
	when 3 then ''systemTranslated_Read_the_message_agent''
	when 4 then ''systemTranslated_Unassign_message_to_agent''
	when 5 then ''systemTranslated_Message_answered_by_agent''
	when 6 then ''systemTranslated_Message_sent_to_the_client''
	when 7 then ''systemTranslated_Message_rejected_for_server''
	when 8 then ''systemTranslated_Message_rejected_for_server''
	when 9 then ''systemTranslated_Message_rejected_for_server''
	when 10 then ''systemTranslated_conversation_closed_for_system''
	when 13 then ''systemTranslated_Message_email_Spam''
	when 11 then ''systemTranslated_Close_conversation_for_agent'' else '''' end statusMail,



	isnull(max(messagestatusid),0) messagestatusid,
	isnull(min(mailClient),'''') mailClient,
	conversationId, isnull(sum(tQueue),0) as [tQueueMultimedia],
	isnull(sum(twait),0) as  [twaitMultimedia], isnull(sum(tAtentionMultimedia),0) tAtentionMultimedia, isnull(sum(twrapup),0) twrapup,
	isnull(sum(tsent),0) tsent,
	datepart(yyyy,min(date)) [year],
	datepart(mm,min(date)) [mounth],
	datepart(dd,min(date)) [day],
	datepart(hh,min(date)) [hour],
	datepart(mi,min(date)) [minute],
	sum(tFocus) as tFocus
from(

select
	msg.date date,
	conv.mailClient mailClient, isnull(inbo.descripcion,'''') descripcion,
	isnull(inbo.inbound_id,0) inboundid, msg.conversationId conversationid,
	msg.messagestatusid messagestatusid,
	case when msg.tqueue is null then 0 else datediff(second,msg.[date],msg.tqueue)  end tQueue,
	msg.twait,
	isnull((msg.twait + msg.tretention + msg.tresponse),0) tAtentionMultimedia, msg.twrapup,
	case when msg.tsend is null then 0 else
		datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) end as tsent
	,msg.tresponse as tFocus
	from [message] msg inner join [conversation] conv
	on msg.conversationId = conv.conversationId
	inner join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
	inner join ccUserView usuario on usuario.User_id = msg.userid
	where msg.date >= @from AND msg.date < @to
	)x
	group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion,inboundid,conversationId

end
	'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepInCallsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

DECLARE @callId as int

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
				
	declare @tab table(callId int primary key, [Dato1] varchar(255),[Dato2] varchar(255),[Dato3] varchar(255),[Dato4] varchar(255),[Dato5] varchar(255))

	insert into @tab
	select callId,[Dato 1],[Dato 2],[Dato 3],[Dato 4],[Dato 5]
	from
	(select A.CallId,[Data],[Description] from DataCallIn A
	inner join ccCallsIn B on A.CallId=B.cal_id
	where b.cal_Inicio >= @from AND b.cal_Inicio < @to
	) as SourceTable
	pivot
	(
	max([Data])
	for [Description] in ([Dato 1],[Dato 2],[Dato 3],[Dato 4],[Dato 5])
	)as pvt


	--Borrar lo que esta para no repetir
	delete from RepInCallsDetail with(rowlock) where date >= @from AND date < @to

	insert into RepInCallsDetail(date,callid,inboundId,ACDGroup,callStatusId,callStatus,dispositionId,disposition,subDispositionId,subDisposition,dnisId,dnis,userId,userName,callKey,ANI,queueTime,xferTime,ringingTime,dialogTime,extension,agentName,whoHangUp,mohTime,year,month,day,hour,minutes,provedorId,provider,trunk,fileMoved,twrapup,AverageHandleTime,Dato1,Dato2,Dato3,Dato4,Dato5)
	select cal_inicio,cal_id ,Inbound_id, '''' as Inbound, statusCall_id, '''' as statusCall, calif_id, '''' as calif, isnull(califSub_id,0), '''' as califSub,
	dni_id, '''' as dni, user_id, '''' as agentName,
	isnull(cal_key,''''), cal_ANI, cal_tWait, cal_tXfer, cal_tRing, cal_tDialog, cal_extension, '''',
	case when a.cal_whoHung = 0 then ''systemTranslated_Client''
	when a.cal_whoHung = 1 then ''systemTranslated_Agent''
	else ''systemTranslated_AgentSurvey'' end [whoHangUp]
	, cal_tMoh, datepart(yyyy,cal_inicio), datepart(mm,cal_inicio), datepart(dd,cal_inicio)
	, datepart(hh,cal_inicio), datepart(mi,cal_inicio)
	,di.provedor_id,prov.descrip [Proveedor],a.cal_puerto
	,case when a.file_moved = 1 then ''systemTranslated_Remoto'' else ''Local'' end as file_Moved
	,cal_tNotas,AverageHandleTime= cal_tNotas+cal_tDialog
	,ISNULL(tab.Dato1,'''') as Dato1
	,ISNULL(tab.Dato2,'''') as Dato2
	,ISNULL(tab.Dato3,'''') as Dato3
	,ISNULL(tab.Dato4,'''') as Dato4
	,ISNULL(tab.Dato5,'''') as Dato5				
	from cccallsin a
	left join ccoDialers di on di.dialer_id = a.cal_puerto
	left join cstoProvedor prov on di.provedor_id = prov.provedor_id
	left join @tab tab on tab.callId=a.cal_id
	where cal_inicio >= @from AND cal_inicio < @to
				
	update a set acdGroup = isnull(descripcion,'''')
	from RepInCallsDetail a
	left join ccInbound b
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set callStatus = isnull(descripcion,'''')
	from RepInCallsDetail a
	left join ccstatusllamada b
	on a.callStatusId = b.statusCall_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,'''')
	from RepInCallsDetail a
	left join cctipocalif b
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set subDisposition = isnull(califSubDesc,'''')
	from RepInCallsDetail a
	left join cctipocalifsub b
	on a.subDispositionId = b.califSub_id
	where [date] >= @from AND [date] < @to

	update a set dnis = isnull(dni_numero,'''')
	from RepInCallsDetail a
	left join ccdnis b
	on a.dnisId = b.dni_id
	where [date] >= @from AND [date] < @to

	update a set userName = isnull(login,''''),
	agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInCallsDetail a
	left join ccUserView b
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepInDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInDispositions with(rowlock)
	where date >= @from AND date < @to
	
	insert into RepInDispositions 
	SELECT 
		CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),
		Inbound_id,'''' as ACDGroup, dispositionId, '''' as DispName,'''',
		count(dispositionId) DispAmount,user_id, '''' as login,'''' as username,IDArea, '''' as areaName,1 as wgId ,''systemTranslated_WorkGroup'' as wg ,
		datepart(yyyy,max(dateHour)) as year, datepart(mm,max(dateHour)), datepart(dd,max(dateHour)),
		datepart(hh,max(dateHour)), 0
		FROM (
			SELECT 
				a.cal_inicio as dateHour, a.Inbound_id, a.calif_id as dispositionId, user_id, b.IDArea
				from cccallsin a 		
				left join ccInbound b
				on	b.Inbound_id = a.Inbound_id		
				where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13	--Constestada
				and b.IDArea is not null
			UNION 
			SELECT 		
				requestDate,a.inboundId, a.disposition, a.userId, b.IDArea
				FROM ccRIAChats a
				left join ccInbound b
				on	b.Inbound_id = a.inboundId
				where requestDate >= @from AND requestDate < @to and a.chatStatus = 3 --Assigned
				and b.IDArea is not null		
	) as x group by CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),Inbound_id, dispositionId, user_id, IDArea
	
	update a set acdGroup = isnull(descripcion,'''')
	from RepInDispositions a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,''systemTranslated_Dispositionless''), disposition_count = isnull(description,''systemTranslated_Dispositionless'') + ''_Count''
	from RepInDispositions a
	left join cctipocalif b 
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepInDispositions a
	left join ccUserView b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInDispositions a
	left join ccUserView b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepInDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepInSubDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInSubDispositions with(rowlock)
	where date >= @from AND date < @to

	insert into RepInSubDispositions 
	SELECT 
		CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),
		Inbound_id,'''' as ACDGroup, subDispositionId, '''' as DispName, '''',
		count(dispositionId) DispAmount,user_id, '''' as login,'''' as username,IDArea, '''' as areaName,1 as wgId ,''systemTranslated_WorkGroup'' as wg ,
		datepart(yyyy,max(dateHour)) as year, datepart(mm,max(dateHour)), datepart(dd,max(dateHour)),
		datepart(hh,max(dateHour)), 0
	 FROM 
	(
		select 
		cal_inicio as dateHour, a.Inbound_id,isnull(a.califSub_id,0) as subDispositionId, calif_id as dispositionId, user_id, b.IDArea
		from cccallsin a 		
		left join ccInbound b
		on	b.Inbound_id = a.Inbound_id		
		where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13
		and b.IDArea is not null
		UNION 
		SELECT 		
			requestDate,a.inboundId, a.subDisposition, a.disposition, a.userId, b.IDArea
			FROM ccRIAChats a
			left join ccInbound b
			on	b.Inbound_id = a.inboundId
			where requestDate >= @from AND requestDate < @to and a.chatStatus = 3 --Assigned
			and b.IDArea is not null
	) as x group by CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),Inbound_id, subDispositionId, user_id, IDArea

	update a set acdGroup = isnull(descripcion,'''')
	from RepInSubDispositions a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set subDisposition = isnull(califSubDesc,''systemTranslated_Dispositionless''), subDisposition_count = isnull(califSubDesc,''systemTranslated_Dispositionless'') + ''_Count''
	from RepInSubDispositions a
	left join cctipocalifsub b 
	on a.subDispositionId = b.califSub_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepInSubDispositions a
	left join ccUserView b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInSubDispositions a
	left join ccUserView b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepInSubDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepIVRDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

if @action = 1 
	begin

	create table #IVRLlamadas(
	IVR_id int not null,
	cal_ani varchar(30) null,
	User_id smallint not null,
	calif_id smallint not null,
	cal_id int not null,
	date datetime not null,
	dnis varchar(50) not null
	)

	insert into #IVRLlamadas
	select A.Ivr_id,A.cal_ani,isnull(B.user_id,0) as [user_id],isnull(B.calif_id,0) as [calif_id]
	,isnull(B.cal_id,0) as [cal_id],B.cal_inicio as date,a.dnis
	from IVRCallsIn as A with(nolock)
	left join ccCallsIn As B with(nolock) on  A.IVR_id = B.IVR_id
	where date >= @from and date < @to
	and A.dnis <> ''''
	and B.cal_inicio is not null

	delete from RepIVRDetail with(rowlock)
	where date >= @from AND date < @to
		
	insert into RepIVRDetail
	select #IVRLlamadas.date as fecha, cal_ani as telefono
	, isNull(u.nombres + '' '' + u.apellidopaterno + '' '' + u.apellidomaterno,'''') as nombre
	, isnull(calif.description, #IVRLlamadas.calif_id) as calificacion, cal_id as cal_id
	, isnull(
	(
		select selectedOption + '',''	from IVROptions with(nolock)
		where IVROptions.ivr_id = #IVRLlamadas.ivr_id
		order by IVROptions.date for xml path('''')
	),'''') as opciones
	, isnull(datediff( ss, date, maxdate),0) as tiempo,
	datepart(yyyy,[date]),
	datepart(mm,[date]),
	datepart(dd,[date]),
	datepart(hh,[date]),
	datepart(mi,[date]),
	dnis as DNIS,
	case when name is NULL then ''systemTranslated_NoName'' when name = '''' then ''systemTranslated_NoName'' else name end
	from #IVRLlamadas
	left join
	(
		select ivr_id,name, max(date) as maxDate 
		from IVROptions with(nolock)
		where date >= @from and date < @to
		group by ivr_id,name
	) optTime on #IVRLlamadas.ivr_id = optTime.ivr_id
	left join ccUserView u with(nolock) on (u.user_id = #IVRLlamadas.user_id)
	left join cctipocalif calif with(nolock) on (calif.calif_id = #IVRLlamadas.calif_id)
	where #IVRLlamadas.date >= @from and #IVRLlamadas.date < @to
	order by date
	
	drop table #IVRLlamadas

end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepIVRSurveys]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
if @from is null
	select @from = convert(datetime,convert(varchar(14),getdate(),121)+ ''00'',121)
if @to is null
	select @to = getdate()


delete RepIVRSurveys with(rowlock)
	where [date] between @from and @to


insert RepIVRSurveys select [date],userId,[login],scriptId,surveyId,survey,calId,calKey,campaignId,inboundId,campACDDescription,
questionId,questionDescription,question_Count,[Count],[year],[month],[day],[hour],[minutes],clientPhoneNumber
from
(
	select
	cci.cal_Inicio as [date],
	isnull(cci.User_id, 0) as ''userId'',
	isnull(ccu.Login, ''No agent'') as ''login'',
	isnull(ivro.IVR_id, 0) as ''scriptId'',
		isnull(s.surveyId, 0) as ''surveyId'',
	isnull(s.description, '''') as ''survey'',
	isnull(cci.cal_id, 0) as ''calId'',
	isnull(cci.cal_Key, '''') as ''calKey'',
	0 as ''campaignId'',
	isnull(cci.Inbound_id, '''') as ''inboundId'',
	''ACD - '' + isnull(ccin.descripcion,'''') as ''campACDDescription'',
	isnull(ivro.questionId, 0) as ''questionId'',
	isnull(sq.description,'''') as ''questionDescription'',
	isnull(sq.description,'''')+ ''_UnCount'' as ''question_Count'',
	case when ivro.selectedOption = '''' then ''systemTranslated_No_Option''
	when r.questionId is null then ivro.selectedOption
	when r.answerId is not null and ivro.selectedOption = convert(varchar(5),r.digit) then r.desAnswer
	else ''systemTranslated_Invalid'' end as ''Count'',
	datepart(yy,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [year],
	datepart(MM,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [month],
	datepart(DD,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [day],
	datepart(HH,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [hour],
	datepart(MI,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [minutes]
	,rsq.orden, cal_ani clientPhoneNumber
	from ccCallsIn cci with(nolock)
	inner join IVROptions ivro on ivro.cal_id = cci.cal_id
	inner join ccUserView ccu on cci.User_id = ccu.User_id
	inner join Survey s on ivro.surveyId = s.surveyId
	inner join ccInbound ccin on cci.Inbound_id = ccin.Inbound_id
	inner join SurveyQuestion sq on ivro.questionId = sq.questionId
	inner join relationSurveyQuestion rsq on rsq.surveyId = ivro.surveyId and rsq.questionId=sq.questionId
	left join (
	select rqa.surveyId,rqa.questionId,min(rqa.answerId) answerId,sa.digit,min(description) as desAnswer from relationQuestionAnswer rqa
	inner join SurveyAnswer sa on  rqa.answerId=sa.answerId group by rqa.surveyId,rqa.questionId,sa.digit
	)r on convert(varchar(5),r.digit) = ivro.selectedOption and r.surveyId=ivro.surveyId and ivro.questionId=r.questionId
	where cal_inicio between @from and @to

	union all

	select distinct
	cco.cal_Inicio as [date],cco.User_id as ''userId'',
	isnull(ccu.Login, ''No agent'') as ''login'',
	isnull(ivro.IVR_id, 0) as ''scriptId'',
	isnull(s.surveyId, 0) as ''surveyId'',
	isnull(s.description, '''') as ''survey'',
	isnull(cco.cal_id, 0) as ''calId'',
	isnull(cco.cal_Key, '''') as ''calKey'',
	isnull(ccc.[cam_id], '''') as ''campaignId'',
	0 as ''inboundId'',
	''Camp - '' + isnull(ccc.[cam_descripcion],'''') as ''campACDDescription'',
	isnull(ivro.questionId, 0) as ''questionId'',
	isnull(sq.description,'''') as ''questionDescription'',
	isnull(sq.description,'''')+ ''_UnCount'' as ''question_Count'',
	case when ivro.selectedOption = '''' then ''systemTranslated_No_Option''
	when r.questionId is null then ivro.selectedOption
	when r.answerId is not null and ivro.selectedOption = convert(varchar(5),r.digit) then r.desAnswer
	else ''systemTranslated_Invalid'' end as ''Count'',
		datepart(yy,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [year],
	datepart(MM,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [month],
	datepart(DD,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [day],
	datepart(HH,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [hour],
	datepart(MI,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [minutes]
	,rsq.orden, cal_telefono clientPhoneNumber
	from ccoCallsOut cco
	inner join IVROptions ivro on cco.cal_id = ivro.cal_id
	inner join ccUserView ccu on cco.User_id = ccu.User_id
	inner join Survey s on ivro.surveyId = s.surveyId
	inner join ccCamps ccc on cco.cam_id = ccc.cam_id
	inner join SurveyQuestion sq on ivro.questionId = sq.questionId
	inner join relationSurveyQuestion rsq on rsq.surveyId = ivro.surveyId and rsq.questionId=sq.questionId
	left join (
	select rqa.surveyId,rqa.questionId,min(rqa.answerId) answerId,sa.digit,min(description) as desAnswer from relationQuestionAnswer rqa
	inner join SurveyAnswer sa on  rqa.answerId=sa.answerId group by rqa.surveyId,rqa.questionId,sa.digit
	)r on convert(varchar(5),r.digit) = ivro.selectedOption and r.surveyId=ivro.surveyId and ivro.questionId=r.questionId
	where cal_inicio between @from and @to

)surveys
order by calId,orden
end
'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepMKTAgentes]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
 set nocount on
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
		select @to = getdate()

if @action = 1 begin

CREATE TABLE #times(
	[ID] INT primary key,
	[Start] DATETIME,
	[Stop] DATETIME
	)

	create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on #times([Start] DESC)

declare @starttime datetime,@number int
	set @starttime = @from
	set @number = 0

while @number <= (datediff(mi,@starttime,@to)/15) begin
		   insert into #times
		   select @number,DATEADD(mi, @number*15, @starttime),DATEADD(mi, (@number+1)*15, @StartTime)
		   set @number = @number +1
	end

select
	cal_inicio dateStartDetail,
	dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
	[dbo].[GetTimeGroup](case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end,0) as timegroup,
	[dbo].[GetTimeGroup](
	dateadd(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end )	
	,1) as timegroup_next,
		 c.user_id,

		 isnull(count(case when c.statusCall_id=13 then 1 else null end),0) nacd,
         isnull(count(case when c.statusCall_id=13 and c.cal_tnotas>0 then 1 else null end),0) nacw,
         isnull(count(case when l.modo in (3,4) and l.tipo=1 then 1 else NULL end),0) cayuda,
         isnull(count(case when l.modo in (0,3,4) and l.tipo=1 then 1 else NULL end),0) nxfersal,
		 isnull(sum(case when c.statuscall_id = 13 then (c.cal_twait + c.cal_txfer + c.cal_tring) else 0 end),0) tresp,
		 isnull(sum(case when c.statusCall_id=13 and c.cal_tdialog>=0 then c.cal_tdialog else 0 end),0) tacd,
         isnull(sum(case when c.statusCall_id=13 then c.cal_tnotas else 0 end),0) tacw

		,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
	   into #timeAgenteTransfer
       from cccallsin c
       LEFT OUTER JOIN ccLogTransfers l (nolock) on (l.cal_id = c.cal_id and l.fechaFin between @from and @to)
       where c.cal_inicio between @from and @to and 
	   c.user_id>0
	   and c.inbound_id>0 	  
       group by c.user_id,cal_inicio
	   ,[dbo].[GetTimeGroup](case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end,0)
	   ,[dbo].[GetTimeGroup](
		dateadd(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end )	
		,1)

	select * into #timeAgenteTransfer2 from #timeAgenteTransfer where datediff(mi,timegroup,timegroup_next)>15
	delete #timeAgenteTransfer where datediff(mi,timegroup,timegroup_next) > 15
	insert into #timeAgenteTransfer
	select dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,
		[User_id]
		,case when th.start > dateStartDetail and th.stop > dateEndDetail then nacd else 0 end as nacd
		,case when th.start > dateStartDetail and th.stop > dateEndDetail then nacw else 0 end as nacw
		,case when th.start > dateStartDetail and th.stop > dateEndDetail then cayuda else 0 end as cayuda
		,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfersal else 0 end as nxfersal
		,[dbo].TimeInterval(th.Start,th.Stop,dateStartDetail,time_dialog) as tresp
		,[dbo].TimeInterval(th.Start,th.Stop,time_dialog,time_notes) as tacd
		,[dbo].TimeInterval(th.Start,th.Stop,time_notes,dateEndDetail) as tacw
		,time_dialog,time_notes,time_end_call

	from #timeAgenteTransfer2 t
	join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0  

select dateadd(ss,-tstatus,fecha) dateStartDetail,
		   fecha dateEndDetail,
	dbo.GetTimeGroup(dateadd(ss,isnull(-tstatus,0),fecha),0)  as timegroup,
	dbo.GetTimeGroup(fecha,1 ) as timegroup_next,
	user_id,
             (case when TipoStatusAge_id = 7 then tstatus else 0 end) t_otra,
             (case when TipoStatusAge_id = 2 then tstatus else 0 end) t_aux,
             (case when TipoStatusAge_id = 3 then tstatus else 0 end) t_disp,
             (case when TipoStatusAge_id = 4 then tstatus else 0 end) t_dialog,
             (case when TipoStatusAge_id = 6 then tstatus else 0 end) t_notas,
             tstatus t_pers
		, case when TipoStatusAge_id = 7 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_otra
, case when TipoStatusAge_id = 2 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_aux
, case when TipoStatusAge_id = 3 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_disp
, case when TipoStatusAge_id = 4 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_dialog
, case when TipoStatusAge_id = 6 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_notas
,fecha time_total
		into #timeAgenteStatus
       from cclogagentesdia
	   where fecha between @from and @to 
	order by user_id,fecha

	select * into #timeAgenteStatus2 from #timeAgenteStatus where datediff(mi,timegroup,timegroup_next)>15
	delete #timeAgenteStatus where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeAgenteStatus
	select dateStartDetail,dateEndDetail,th.start,th.stop,user_id
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_otra and  th.stop > time_otra and t_otra>0 then datediff(ss,dateStartDetail,time_otra)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_otra and t_otra>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_otra and  th.stop > time_otra and t_otra>0 then datediff(ss,th.start,time_otra)
	  when th.start > dateStartDetail and th.stop < time_otra and t_otra>0 then datediff(ss,th.start,th.stop) else  0 end as t_otra
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_aux and  th.stop > time_aux and t_aux>0  then datediff(ss,dateStartDetail,time_aux)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_aux and t_aux>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_aux and  th.stop > time_aux and t_aux>0 then datediff(ss,th.start,time_aux)
	  when th.start > dateStartDetail and th.stop < time_aux and t_aux>0 then datediff(ss,th.start,th.stop)  else  0 end as t_aux

	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_disp and  th.stop > time_disp and t_disp>0 then datediff(ss,dateStartDetail,time_disp)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_disp and t_disp>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_disp and  th.stop > time_disp and t_disp>0 then datediff(ss,th.start,time_disp)
	  when th.start > dateStartDetail and th.stop < time_disp and t_disp>0 then datediff(ss,th.start,th.stop) else  0 end as t_disp

	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_dialog and  th.stop > time_dialog and t_dialog>0 then datediff(ss,dateStartDetail,time_dialog)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_dialog and t_dialog>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_dialog and  th.stop > time_dialog and t_dialog>0 then datediff(ss,th.start,time_dialog)
	  when th.start > dateStartDetail and th.stop < time_dialog and t_dialog>0 then datediff(ss,th.start,th.stop) else  0 end as t_dialog
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_notas and  th.stop > time_notas and t_notas>0 then datediff(ss,dateStartDetail,time_notas)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_notas and t_notas>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_notas and  th.stop > time_notas and t_notas>0 then datediff(ss,th.start,time_notas)
	  when th.start > dateStartDetail and th.stop < time_notas and t_notas>0 then datediff(ss,th.start,th.stop) else  0 end as t_notas
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_total and  th.stop > time_total and t_pers>0 then datediff(ss,dateStartDetail,time_total)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_total and t_pers>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_total and  th.stop > time_total and t_pers>0 then datediff(ss,th.start,time_total)
	  when th.start > dateStartDetail and th.stop < time_total and t_pers>0 then datediff(ss,th.start,th.stop) else  0 end as t_pers
	,time_otra,time_aux,time_disp,time_dialog,time_notas,time_total
	from #timeAgenteStatus2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0


delete from dbo.RepMKTAgentes with(rowlock)
		where date >= @from AND date < @to

;WITH cte (date,user_id,CallsperACDGroupD,tACD,[tAgent],oHour,tAux,readyTime,tPer,Ayuda,nxfer,nacw,tACW, year, month,day,hour,minutes)
AS
(
select isnull(convert(varchar(24),acd.timegroup,121),convert(varchar(24),tready.timegroup,121)) date,
		isnull(acd.user_Id,tready.User_id),
		isnull(acd.nacd,0) [CallsperACDGroupD],
		isnull(acd.tacd,0) [tACD],
		isnull(acd.tresp,0) [tAgent],
		isnull(tready.t_otra,0) [oHour],
       isnull(tready.t_aux,0) [tAux],
       isnull(tready.t_disp,0) [readyTime],
       isnull(tready.t_pers,0) [tPer],
       isnull(acd.cayuda,0) [Ayuda],
       isnull(acd.nxfersal,0) [nxfer],
	   isnull(acd.nacw,0) [nacw],
	   isnull(acd.tACW,0) [tACW],
	isnull(datepart(yyyy,convert(varchar(24),acd.timegroup,121)),0) year,
	isnull(datepart(mm, acd.timegroup),0) month,
	isnull(datepart(dd, convert(varchar(24),acd.timegroup,121)),0) day,
	isnull(datepart(hh, convert(varchar(24),acd.timegroup,121)),0) hour,
	isnull(datepart(mi,convert(varchar(24),acd.timegroup,121)),0) minutes
from (
select 
acd.timegroup,
acd.user_id,
sum(nacd) nacd,
sum(nacw) nacw,
sum(cayuda) cayuda ,
sum(nxfersal) nxfersal,
sum(tresp) tresp,
sum(tacd) tacd,
sum(tacw) tacw
	from #timeAgenteTransfer acd group by acd.timegroup,acd.user_id 
	) acd
full join
(select 
timegroup,
user_id,
sum(t_otra) t_otra,
sum(t_aux) t_aux,
sum(t_disp) t_disp,
sum(t_pers) t_pers
	from #timeAgenteStatus group by timegroup,user_id)tready on tready.user_id=acd.user_id and tready.timegroup=acd.timegroup) 

insert into RepMKTAgentes(date,userId,login,agentName,CallsperACDGroupD,tACD,tAgent,oHour,tAux,readyTime,tPer,Ayuda,nxfer,nacw,tACW,year,month,day,hour,minutes)
select date,a.user_id,u.Login,
(isnull(u.apellidopaterno,u.apellidopaterno)+'' ''+isnull(u.apellidomaterno,'''')+'' ''+isnull(u.nombres,'''')) agt_name,
CallsperACDGroupD,tACD,[tAgent],oHour,tAux,readyTime,tPer,Ayuda,nxfer,nacw,tACW, year, month,day,hour,minutes from cte a
inner join ccUserView as u on a.user_id=u.user_id
order by date,Login

drop table #times
drop table #timeAgenteTransfer
drop table #timeAgenteTransfer2
drop table #timeAgenteStatus
drop table #timeAgenteStatus2

end
'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepMKTDiarioTiemposTotales]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

declare @dateNow datetime,@maxLogout datetime

if @action = 1
begin
delete from [RepMKTDiarioTiemposTotales] with(rowlock) 
	where date >= @from AND date <= @to 

CREATE TABLE #sessionAgent 
	(
		[user_id] [smallint] NOT NULL,
		[login] [datetime] NOT NULL,
		[logout] [datetime] NOT NULL,
		[extension] [varchar](7) NOT NULL,
	);
INSERT INTO #sessionAgent
	exec ccspGenSession @from, @to
	select ''#sessionAgent''

select 
	convert(datetime,convert(date,login)) fecha,
	SUM(DATEDIFF(ss, login, logout)) t_ses,
	count(distinct user_id) user_id
into #infoSession
from #sessionAgent
GROUP BY convert(datetime,convert(date,login))

SELECT 
		i.cal_Inicio as [date],
		i.user_id as acduser,
		i.Inbound_id as inboundId,
		case when i.statuscall_id=13 then i.cal_tmoh else 0 end thold,
		case when i.statusCall_id=13 then i.cal_tring else 0 end tring,
		case when i.statusCall_id=13 and i.cal_tdialog>=0 then i.cal_tdialog else 0 end tacd,
		case when i.statusCall_id=13 then i.cal_tnotas else 0 end tacw,
		case when i.statusCall_id=13 then 1 else null end nacd,
		case when i.statusCall_id=13 and i.cal_tnotas>0 then 1 else null end nacw,
		case when i.statusCall_id=13 and i.cal_tmoh>0 then 1 else null end nhold,
		case when i.statusCall_id=13 and i.cal_tring>0 then 1 else null end nring	
	into #inboundData2			
	FROM	cccallsin i (NOLOCK)	
	WHERE	i.cal_inicio between @from and @to

SELECT user_id AS agtuser_id,
	login AS agtlogin,
	ISNULL(apellidopaterno,'''')+'' ''+ISNULL(apellidomaterno,'''')+'' ''+ISNULL(nombres,'''') agt_name
	into #users
	FROM ccUserView (NOLOCK)

insert RepMKTDiarioTiemposTotales 
	select c.[date]	--
		,l.agtlogin as [OpaId]
		,l.agt_name [NombreDeOperadora]
		,[InboundID]--
		,[TiempoPromACD]--
		,[TiempoPromACW]--
		,[TiempoPromReten]
		,[TiempoPromRing]
		,[AHT]
		,[LlamadasAtendidas]
		,DATEPART(YYYY, c.[date]) as [year] 
		,DATEPART(mm, c.[date]) as [month]
		,DATEPART(dd, c.[date]) as [day]
		,DATEPART(hh, c.[date]) as [hour]
		,DATEPART(mi, c.[date]) as [minutes]
	 from (
		select convert(datetime,convert(date,[date])) as [date],
			acduser as [user],
			inboundId as [InboundId]
			,case when sum(c.nacd)>0 then sum(c.tacd)/sum(c.nacd) else 0 end as [TiempoPromACD]
			,case when sum(c.nacw)>0 then sum(c.tacw)/sum(c.nacw) else 0 end as [TiempoPromACW]
			,case when sum(c.nhold)>0 then sum(c.thold)/sum(c.nhold) else 0 end as [TiempoPromReten]
			,case when sum(c.nring)>0 then sum(c.tring)/sum(c.nring) else 0 end as [TiempoPromRing]
			,sum(((case when c.nacd>0 then c.tacd/c.nacd else 0 end)+(case when c.nacw>0 then c.tacw/c.nacw else 0 end)+(case when c.nring>0 then c.tring/c.nring else 0 end)+(case when c.nhold>0 then c.thold/c.nhold else 0 end))) [AHT]
			,isnull(sum(c.nacd),0) as [LlamadasAtendidas]
		from #inboundData2 as c 
		group by convert(datetime,convert(date,[date])),inboundId,acduser
	) c
	LEFT JOIN #infoSession G on G.fecha = c.date
	left join #users l on [user]=l.agtuser_id --and c.date=l.date
	--INNER JOIN ccinbound i on [ACD] = i.Inbound_id
	WHERE @from <= C.[date] AND @to >= c.[date] and [LlamadasAtendidas]>0
	order by [date]

drop table #inboundData2
drop table #sessionAgent
drop table #infoSession 
drop table #users
end
'

		EXEC (@sql)

		SET @process = 'CW-2379, CW-2576 Alter SP --  Report ccspRepOutAnswAndXferCalls ,use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

declare @IVA INT
declare @country as tinyint


select @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25
select @country = convert(tinyint,isnull(valor,1)) from ccsettings where setting_id = 104


if @country is null set @country = 1


if @action = 1
begin
	--Borrar lo que esta para no repetir
	delete from RepOutAnswAndXferCalls with(rowlock) where date >= @from AND date < @to

	insert into RepOutAnswAndXferCalls
	select COALESCE([Call].cal_inicio,ccld.fecha) as [date],
	isnull(ccld.cal_id,0) as [callid],
	isnull(ccld.cam_id,0) as [campaignId],
	ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign],
	isnull([Call].user_id,0) as [userId],
	ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, ''N/A'') as [Agent],
	case when (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) end as [dialog],
	ccld.telefono as [telephone],
	isnull(Call.cal_manual,0) as [dialId],
	isnull((select [description] from dialType where dialId = Call.cal_manual),''systemTranslated_Auto'') as [dialType],
	ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
	dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType), COALESCE(Call.provedor_id,ccld.proBIDs) , case when (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) end) as [ncost],
	@IVA as iva,
	convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType), COALESCE(Call.provedor_id,ccld.proBIDs) , case when (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) end),0.00) * (1 + (@IVA / 100.00))) as total
	from (select *, [dbo].[GetProveedor](Telefono, Puerto,CallType) as proBIDs from (select *, tipoLlamada_id as CallType from ccologdials WITH(NOLOCK) where fecha >= @from and fecha < @to and answerbit = 1 ) as basequery ) ccld
	LEFT JOIN ccoCallsOut Call WITH(NOLOCK) on ccld.cal_id = Call.cal_id and ccld.answerbit = 1
	LEFT JOIN ccCamps camps ON camps.[cam_id] = ccld.[cam_id]
	LEFT JOIN ccuserView Usr ON Usr.[user_id] = Call.[user_id]
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = COALESCE(Call.[tipoLlamada_id],ccld.CallType) and tl.Country_id = @country)
	order by date

	insert into RepOutAnswAndXferCalls
	select dateadd(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) as [date],
	clt.cal_id as [callid],
	'''' as [campaignId],
	'''' as [campaign],
	isnull((case tipo when 1 then ci.User_id else co.User_id end),0) as [userId],
	isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccuserView nolock where user_id = 
	(case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') as [Agent],
	case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else 60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end as [dialog],
	case when modo = 0 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino)  
	when modo = 3 then isnull((select tel from telefonosConferencia where tel = clt.destino),clt.destino) 
	when modo = 4 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino) 
	when modo = 5 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end as [telephone],
	3 as [dialId],
	(select [description] from dialType where dialId = 3) as [dialType],
	ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
	ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId, case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else 60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end), 0) as [ncost],
	@IVA as iva,
	convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId, case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else  60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end),0.00) * (1 + (@IVA / 100.00))) as [total]
	from (select *, tipoLlamada_id as CallType from cclogtransfers WITH(NOLOCK) where modo not in (1,2) and (tAntesXfer > 0 or tDespuesXfer > 0) and dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) >= @from and dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) < @to) clt
	LEFT JOIN cccallsin ci WITH(NOLOCK) on ci.cal_id=clt.cal_id and tipo=1
	LEFT JOIN ccocallsout co WITH(NOLOCK) on co.cal_id=clt.cal_id and tipo=2 
	LEFT JOIN ccChannelTransfer channel on clt.pbxId=channel.pbxId and clt.channel between channel.startChannel and channel.endChannel
	LEFT JOIN cstoTarifa tarifa on tarifa.provedor_id=channel.proveedorId and tarifa.tipoLlamada_id=dbo.fnGetTipoLlamada(clt.destino)
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = clt.CallType and tl.Country_id = @country)
	order by date 

end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepOutCallBacks]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

if @action = 1
begin
	delete RepOutCallBacks with(rowlock)
	where date >= @from and date < @to

	insert into RepOutCallBacks
	select cal_fecha as [date], b.user_id as [userId], b.login as [user], c.cam_id as [campaignId], c.cam_descripcion as [campaign],
	cal_key as [callKey], cal_telefono as [originalTel], cal_telCB as [scheduledTel], cal_fecha as [originalDate], 
	cal_fusercallback as [scheduledDate],
	case a.status when 0 then ''systemTranslated_Pending''
	when 1 then ''systemTranslated_Answer''
	when 2 then ''systemTranslated_NoAnswer''
	when 3 then ''systemTranslated_Recicled''
	when 4 then ''systemTranslated_Expired''
	when 5 then ''systemTranslated_OldRecord''
	when 6 then ''systemTranslated_LoadRecord'' end as [status], 
	case when cal_fcallback is null then ''''
		when convert(varchar(13),cal_fcallback) = ''jan 1 1900'' then ''''
		else convert(varchar(255),cal_fcallback) end as [dialDate]
	, datepart(yyyy,cal_fecha) as [year]
	, datepart(mm,cal_fecha) as [month]
	, datepart(dd,cal_fecha) as [day]
	, datepart(hh,cal_fecha) as [hour]
	, datepart(mi,cal_fecha) as [minutes]
	from ccocallbacks a, ccUserView b, cccamps c
	where cal_fecha between @from and @to
	and a.user_id = b.user_id
	and a.cam_id = c.cam_id
end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepOutCallBilling]
@action AS TINYINT,
@from AS DATETIME=null,
@to AS DATETIME=null

AS

DECLARE @country AS TINYINT
DECLARE @iva AS DECIMAL(3,2)
DECLARE @aux AS VARCHAR(3)

SELECT @country = CONVERT(TINYINT,isnull(valor,1)) FROM ccsettings WHERE setting_id = 104
SELECT @aux = isnull(valor,0) FROM ccsettings WHERE setting_id = 25
set @iva=CONVERT(DECIMAL(3,2),''1.''+@aux)

if @country is null 
set @country = 1
if @from is null
 select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

IF @action = 1
BEGIN
	DELETE FROM RepOutCallBilling WITH(rowlock) WHERE [date] >= @FROM AND [date] < @to
	---creamos tabla temporal con longitud
	IF EXISTS(SELECT longitud FROM cstoTipoLlamada WHERE CHARINDEX(''|'',longitud)<>0 AND country_id =@country) 
	BEGIN
		DECLARE @longitud VARCHAR(10)
		DECLARE @tipollamada INT
		DECLARE @prefijo VARCHAR(50)
		DECLARE @descrip VARCHAR(50)
		SELECT @longitud = CONVERT(VARCHAR(10),longitud),@descrip=descrip,@prefijo=prefijo, @tipollamada= tipoLlamada_id FROM cstoTipoLlamada WHERE CHARINDEX(''|'',longitud)<>0 AND country_id =@country
	END

	CREATE TABLE #cstoTipoLlamadaTemp(
		tipoLlamada_id SMALLINT NOT NULL,
		descrip VARCHAR(50) collate SQL_Latin1_General_CP1_CI_AS NOT NULL ,
		prefijo VARCHAR(50) collate SQL_Latin1_General_CP1_CI_AS NOT NULL,
		longitud INT NOT NULL
	)

	CREATE INDEX IX_CstoTipoLlamadaTemp ON #cstoTipoLlamadaTemp (longitud,tipoLlamada_id)

	CREATE TABLE #TempTransCallBilling(
		[date] datetime NOT NULL,
		camId INT NOT NULL,
		inboundId INT NOT NULL,
		userId INT NOT NULL,
		[proveedorId] INT NOT NULL,
		provedor VARCHAR(30) collate SQL_Latin1_General_CP1_CI_AS NOT NULL,
		[tipollamadaId] INT NOT NULL,	
		[tipoLlamada] VARCHAR(50) collate SQL_Latin1_General_CP1_CI_AS NOT NULL,
		[amount] INT NOT NULL,
		mins INT NOT NULL,
		costo DECIMAL(10,2) NOT NULL,
		costoIva DECIMAL(10,2) NOT NULL
	)

	INSERT INTO #TempTransCallBilling
	
	SELECT CONVERT(smalldatetime, CONVERT(varchar(13), [date], 121) + '':00'', 121) AS [date],
	[camp_id],[inbund_id],[user_id],[proveedorId],provedor,[tipollamadaId],[tipoLlamada],
	COUNT(*) AS amount,SUM(mins) AS mins,SUM([costo]) AS [costo],SUM( costo ) * @iva AS costoIva
	FROM (
		SELECT DATEADD(ss, -(tAntesXfer + tDespuesXfer),fechaFin) AS [date],cco.cam_id AS [camp_id], 
		0 AS [inbund_id],cco.[User_id] AS [user_id], channel.proveedorId AS [proveedorId],prov.descrip AS provedor,
		tipoLlam.tipoLlamada_id AS [tipollamadaId],tipoLlam.descrip AS [tipoLlamada],
		CEILING((tAntesXfer+tDespuesXfer +1 ) / 60.0 )AS [mins], dbo.fnGetCstoTarifa(dbo.fnGetTipoLlamada(trans.destino), 
		channel.proveedorId, tAntesXfer+tDespuesXfer+1) AS [costo]
		FROM 
		ccLogTransfers  trans 
		INNER JOIN ccoCallsOut cco ON cco.cal_id=trans.cal_id AND tipo = 2
		INNER JOIN cstoTipoLlamada tipoLlam ON  tipoLlam.country_id = @country AND tipoLlam.tipoLlamada_id = dbo.fnGetTipoLlamada(trans.destino)
		LEFT JOIN ccChannelTransfer channel ON channel.pbxId=trans.pbxId AND trans.channel BETWEEN channel.startChannel AND channel.endChannel
		LEFT JOIN cstoProvedor prov ON prov.provedor_id=channel.proveedorId
		WHERE channel.proveedorId is NOT NULL and trans.fechaFin between @from and @to
		UNION ALL
		SELECT DATEADD(ss, -(tAntesXfer + tDespuesXfer),fechaFin) AS [date],
		0 AS [camp_id], cci.Inbound_id AS [inbund_id],cci.[User_id] AS [user_id],  
		channel.proveedorId AS [proveedorId],prov.descrip AS provedor,tipoLlam.tipoLlamada_id AS [tipollamadaId],
		tipoLlam.descrip AS [tipoLlamada],CEILING((tAntesXfer+tDespuesXfer +1 ) / 60.0 )AS [mins],   
		dbo.fnGetCstoTarifa(dbo.fnGetTipoLlamada(trans.destino), 
		channel.proveedorId, tAntesXfer+tDespuesXfer+1) AS [costo]
		FROM	
		ccLogTransfers  trans 
		INNER JOIN ccCallsIn cci ON cci.cal_id=trans.cal_id AND tipo = 1
		INNER JOIN cstoTipoLlamada tipoLlam ON  tipoLlam.country_id = @country AND tipoLlam.tipoLlamada_id = dbo.fnGetTipoLlamada(trans.destino)
		LEFT JOIN ccChannelTransfer channel ON channel.pbxId=trans.pbxId AND trans.channel BETWEEN channel.startChannel AND channel.endChannel
		LEFT JOIN cstoProvedor prov ON prov.provedor_id=channel.proveedorId
		WHERE channel.proveedorId is NOT NULL and trans.fechaFin between @from and @to and modo NOT IN (1,2)
	)x
	WHERE [costo] > 0
	GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), [date], 121) + '':00'', 121),[camp_id],[inbund_id],[user_id],[proveedorId],provedor,[tipollamadaId],[tipoLlamada]
		
	INSERT INTO #cstoTipoLlamadaTemp
	SELECT tipoLlamada_id,descrip,prefijo,longitud
	FROM (
		SELECT tipoLlamada_id,descrip,prefijo,longitud FROM cstoTipoLlamada
		WHERE CHARINDEX(''|'',longitud)=0 AND country_id = @country
		union all
		SELECT @tipollamada AS tipoLlamada_id,@descrip AS descrip,@prefijo AS prefijo, Value AS longitud
		FROM dbo.fn_RIASplitDelimited(@longitud,''|'') WHERE @tipollamada is NOT NULL
	)x

	SELECT CONVERT(smalldatetime, CONVERT(VARCHAR(13), cal_inicio, 121) + '':00'', 121) AS date
	, cam_id,inboundId, [user_id],
	provedor_id, tipoLlamada_id , 
	MIN(tipoLlamada) AS tipoLlamada
	, COUNT(*) AS amount
	, SUM( mins) AS mins
	, SUM( costo ) AS costo
	, SUM( costo ) * @iva AS costoIva
	INTO #TempOutCallBilling
	FROM
	(
		SELECT cal_inicio, cco.cam_id AS cam_id,0 AS inboundId, cco.user_id AS user_id, cco.provedor_id,
		cco.tipoLlamada_id, t.descrip AS tipoLlamada, CEILING((cal_tXfer + cal_tRing + totalCall_Time +1 ) / 60.0 ) AS mins, 
		dbo.fnGetCstoTarifa(cco.tipoLlamada_id, cco.provedor_id, cco.totalCall_Time) AS costo
		FROM ccoCallsOut cco
		INNER JOIN cstoTipoLlamada t with(index(IX_cstoTipoLlamada),nolock) ON cco.tipoLlamada_id = t.tipoLlamada_id AND country_id = @country
		WHERE cal_inicio >= @FROM AND  cal_inicio < @to AND cco.provedor_id is NOT NULL AND cal_manual in (0,2) 
		UNION ALL
		---- Tambien las llamdas que fueron fax
		SELECT cco.fecha AS fecha, cco.cam_id,0 AS inboundId,0 AS userId, p.provedor_id, l.tipoLlamada_id,l.descrip AS tipoLlamada,1 AS mins, t.MinutoUno AS costo
		FROM ccoLogDials  cco with(index(IX_ccoLogDials),nolock)
		INNER JOIN ccoDialers cd with(index(IX_ccoDialers),nolock)  ON cco.puerto = cd.puerto
		INNER JOIN cstoProvedor p ON cd.provedor_id = p.provedor_id
		INNER JOIN cstoTarifa t ON  p.provedor_id = t.provedor_id
		INNER JOIN #cstoTipoLlamadaTemp l ON  l.longitud = len(cco.telefono) AND t.tipoLlamada_id = l.tipoLlamada_id
		WHERE cco.fecha >=  @FROM AND cco.fecha < @to  AND cco.answerbit = 1 AND cco.tiporesdial_id <> 1
		AND cco.telefono like l.prefijo
	) costo
	GROUP BY CONVERT(smalldatetime, CONVERT(VARCHAR(13), cal_inicio, 121) + '':00'', 121), cam_id,inboundId, [user_id], provedor_id, tipoLlamada_id
		
	INSERT RepOutCallBilling
	SELECT [date], [cam_id],[campACDDescription],[user_id],[agentName],[username],[provedor_id],[provedor],[tipoLlamada_id],
	(CASE WHEN tipo = ''amount'' THEN ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''Calls_Count''
	WHEN tipo = ''mins'' THEN + ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''MinBilled_Count''
	WHEN tipo = ''costo'' THEN + ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''Cost_Count''
	WHEN tipo = ''costoIva'' THEN + ''systemTranslated_'' + REPLACE([tipoLLamada],'' '','''') + ''Tax_Count''
	ELSE tipo END ) AS tipoLLamada_Count
	,CONVERT(VARCHAR,[tipollamada_Count])  AS [count]
	,[tipoLLamada] AS tipoLlamadaDesp, CASE WHEN tipo = ''costo'' THEN CONVERT(int,CONVERT(DECIMAL(10,2),[tipollamada_Count]) ) ELSE 0 END
	,DATEPART(yyyy,[date]) AS [year],DATEPART(mm,[date]) AS [month],DATEPART(dd,[date]) AS [day],DATEPART(hh,[date]) AS [hour],
	DATEPART(mi,[date]) AS [min],inboundId AS [inboundId],[dialId],[dialType]
	FROM(
		SELECT [date], temp.cam_id AS cam_id,inboundId,''Camp - '' + camps.cam_descripcion AS campACDDescription,
		ISNULL(ccuse.[user_id] ,0) AS [user_id], CASE WHEN ccuse.[user_id] IS NULL THEN ''systemTranslated_NoName'' ELSE  ccuse.Nombres+'' ''+ ccuse.ApellidoPaterno+'' ''+ccuse.ApellidoMaterno END AS agentName,
		CASE WHEN ccuse.[Login] IS NULL THEN ''systemTranslated_NoUserName'' ELSE ccuse.[Login] END AS username,
		temp.provedor_id AS provedor_id, prov.descrip AS provedor,
		[tipoLlamada_id], [tipoLLamada],[tipoLLamada] AS tipoLlamadaDesp,
		CONVERT(VARCHAR,[amount]) AS [amount], CONVERT(VARCHAR,[mins]) AS [mins], CONVERT(VARCHAR,[costo]) AS [costo], CONVERT(VARCHAR,[costoIva]) AS [costoIva]
		,di.id AS [dialId],
		di.[description] AS [dialType]
		FROM #TempOutCallBilling temp
		INNER JOIN ccCamps camps ON camps.cam_id = temp.cam_id
		LEFT JOIN ccUserView ccuse ON ccuse.[User_id] = temp.[user_id]
		INNER JOIN cstoprovedor prov ON prov.provedor_id = temp.provedor_id
		INNER JOIN Dials di ON di.Id = 2
		UNION ALL
		SELECT [date] ,	camId ,	inboundId ,
		CASE WHEN camps.cam_descripcion IS NULL THEN ''ACD - '' + cci.descripcion ELSE ''Camp - ''+ camps.cam_descripcion END AS campACDDescription
		,ISNULL(ccuse.[user_id] ,0) AS [user_id], CASE WHEN ccuse.[user_id] IS NULL THEN ''systemTranslated_NoName''  ELSE  ccuse.Nombres+'' ''+ ccuse.ApellidoPaterno+'' ''+ccuse.ApellidoMaterno END AS agentName,
		CASE WHEN ccuse.[Login] IS NULL THEN ''systemTranslated_NoUserName'' ELSE ccuse.[Login] END AS username 
		,[proveedorId] ,provedor,[tipollamadaId],[tipoLlamada] ,[tipoLlamada] [tipoLlamadaDesp] 
		,CONVERT(VARCHAR,[amount]) AS [amount], CONVERT(VARCHAR,[mins]) AS [mins], CONVERT(VARCHAR,[costo]) AS [costo], CONVERT(VARCHAR,[costoIva]) AS [costoIva]
		,di.Id AS [dialId],
		di.[description] AS [dialType]
		FROM #TempTransCallBilling temp
		LEFT JOIN ccCamps camps ON camps.cam_id = temp.camId
		LEFT JOIN ccinbound cci ON cci.Inbound_id=temp.inboundId 
		LEFT JOIN ccUserView ccuse ON ccuse.[User_id] = temp.userId
		INNER JOIN Dials di ON di.Id = 1
	) p
	UNPIVOT
		([tipollamada_Count] for tipo IN
		([amount], [mins], [costo], [costoIva])
	)AS unpvt
	DROP TABLE #TempOutCallBilling
	DROP TABLE #cstoTipoLlamadaTemp
	DROP TABLE #TempTransCallBilling	
END'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepOutCalls]
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
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nabnd
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0) AS nno_agent
		  ,ISNULL(COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END),0) AS nque
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0) AS ntimeout
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0) AS noverflow
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nxfer
		  ,ISNULL(COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END),0) AS nxfer_que
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nabnd_xfer
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END),0) AS nabnd_ring
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),0) AS nno_answer
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END),0) AS nabnd_dialog
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) AS nanswer
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0) AS nlost
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END),0) AS nmsg
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nabnd_tres
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
		  #outboundData.row, #outboundData.timegroup as [date],0 as areaId,'''' as area
		 ,idwg as workgroupid,'''' as workgroup
		 ,#outboundData.cam_id as campaignid,'''' as campaign
		 ,[User_id] as userId,'''' as [user]
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

end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

DECLARE @IVA INT
DECLARE @country AS TINYINT

SELECT @IVA = convert(INT, isnull(valor, 0))
FROM ccsettings
WHERE setting_id = 25

SELECT @country = convert(TINYINT, isnull(valor, 1))
FROM ccsettings
WHERE setting_id = 104

IF @country IS NULL
	SET @country = 1

IF @action = 1
BEGIN
	--Borrar lo que esta para no repetir
	DELETE
	FROM RepOutCallsDetail WITH (ROWLOCK)
	WHERE DATE >= @from AND DATE < @to

	INSERT INTO RepOutCallsDetail
	SELECT Call.cal_inicio AS [date], Call.cal_key AS [callKey], Call.cal_telefono AS [telephone], Call.cal_txfer + call.cal_tring AS [transfer], Call.cal_tdialog AS [dialog], ISNULL(Call.cal_tMoh, 0) AS [nque], Call.cal_tnotas AS [wrapup], ISNULL(Tipo.[description], '''') AS [CallDisposition], Call.cal_extension AS [extension], isnull(Usr.user_id, 0) AS [userId], ISNULL(convert(VARCHAR(255), Usr.LOGIN), ''systemTranslated_NoUserName'') [login], ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [username], camps.cam_id AS [campaignId], ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign], (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60) AS [duration], ISNULL(Call.costo, 0.00) AS [ncost], @IVA AS iva, convert(DECIMAL(10, 2), ISNULL(Call.costo, 0.00) * (1 + (@IVA / 100.00))) AS total, CASE WHEN prov.descrip IS NOT NULL THEN prov.descrip WHEN cstoProvedor.descrip IS NOT NULL THEN cstoProvedor.descrip ELSE 
				''systemTranslated_NoCarrier'' END AS [ByCarrier], ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [Calltypes], CASE WHEN Call.cal_manual = 0 THEN ''systemTranslated_Auto'' ELSE ''systemTranslated_Manual'' END AS [dialType], CASE WHEN cal_whoHung = 0 THEN ''systemTranslated_Client'' WHEN cal_whoHung = 1 THEN ''systemTranslated_Agent'' ELSE ''systemTranslated_AgentSurvey'' END [whoHangUp], CASE WHEN call.califsub_id = 0 THEN ''systemTranslated_NoSubDisposition'' ELSE isnull(sub.califSubDesc, '''') END AS [subDisposition], sta.descripcion AS [dialResult], Call.cal_id AS [calId], datepart(yyyy, Call.cal_inicio) AS [year], datepart(mm, Call.cal_inicio) AS [month], datepart(dd, Call.cal_inicio) AS [day], datepart(hh, Call.cal_inicio) AS [hour], datepart(mi, Call.cal_inicio) AS [minutes], Call.cal_puerto, ISNULL(cs.Dato1, '''') AS [data1], ISNULL(cs.Dato2, '''') AS [data2], ISNULL(cs.Dato3, '''') AS [data3], ISNULL(cs.Dato4, '''') AS [data4], ISNULL(cs.Dato5, '''') AS [data5], ISNULL(Call.cal_tMsg, 0) AS [MessageTime]
	FROM ccoCallsOut Call
	LEFT JOIN ccTipoCalifOUT Tipo ON Call.calif_id = Tipo.calif_id
	LEFT JOIN ccUserView Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
	LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]
	LEFT JOIN ccStatusLlamada sta ON call.statuscall_id = sta.statuscall_id
	LEFT JOIN cstoProvedor prov ON prov.[provedor_id] = Call.[provedor_id]
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] AND tl.Country_id = @country)
	LEFT JOIN ccTipoCalifSubOut sub ON call.califsub_id = sub.califsub_id
	LEFT JOIN ccoDialers di ON di.dialer_id = Call.cal_puerto
	LEFT JOIN ccoCallsOutSource cs ON Call.callout_id = cs.callout_id
	LEFT JOIN cstoProvedor ON di.provedor_id = cstoProvedor.provedor_id
	WHERE Call.cal_inicio >= @from AND Call.cal_inicio < @to AND cal_manual IN (0, 2)
	ORDER BY DATE
END
'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepOutCallsOnChatDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

DECLARE @IVA INT
declare @country as tinyint


select @country = convert(tinyint,isnull(valor,1)) from ccsettings where setting_id = 104
SELECT @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25

if @country is null set @country = 1


if @action = 1
	begin		
		--Borrar lo que esta para no repetir
		delete from RepOutCallsOnChatDetail with(rowlock)
		where date >= @from AND date < @to

		INSERT INTO RepOutCallsOnChatDetail
		SELECT Call.cal_inicio as [date],
		cal_key as [callKey],
		Call.cal_telefono AS [telephone], 
		Call.cal_txfer + call.cal_tring AS [transfer], 
		Call.cal_tdialog AS [dialog], 
		ISNULL(Call.cal_tMoh,0) as [nque],
		Call.cal_tnotas AS [wrapup], 
		ISNULL( Tipo.[description], '''') AS [CallDisposition], 
		Call.cal_extension AS [extension],
		Usr.user_id as [userId],
		ISNULL(Usr.login,''systemTranslated_NoUserName'') [login], 
		ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [username], 
		camps.cam_id as [campaignId],
		ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign], 
		(CEILING((cal_tXfer + cal_tRing + cal_tDialog +1) / 60.0 )* 60) AS [duration], 
		ISNULL(Call.costo,0.00) as [ncost], 
		@IVA as iva, 
		convert(decimal(10,2),ISNULL(Call.costo,0.00) * (1 + (@IVA / 100.00))) as total,
		case when prov.descrip is not null then prov.descrip when cstoProvedor.descrip is not null then cstoProvedor.descrip else ''systemTranslated_NoCarrier'' end as [ByCarrier],		
		ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [Calltypes], 
		case when Call.cal_manual = 0 then ''systemTranslated_Auto'' else ''systemTranslated_Manual'' end as [dialType], 
		case when cal_whoHung = 0 then ''systemTranslated_Client'' else ''systemTranslated_Agent'' end [whoHangUp], 
		case when call.califsub_id = 0 then ''systemTranslated_NoSubDisposition'' else isnull(sub.califSubDesc, '''') end as [subDisposition],
		sta.descripcion as [dialResult],
		Call.cal_id as [calId]
		,Call.cal_puerto
		, datepart(yyyy,Call.cal_inicio) AS [year]
		, datepart(mm,Call.cal_inicio) as [month]
		, datepart(dd,Call.cal_inicio) as [day]
		, datepart(hh,Call.cal_inicio) as [hour]
		, datepart(mi,Call.cal_inicio) as [minutes]
		FROM ccoCallsOut Call  
		LEFT JOIN ccTipoCalifOUT Tipo ON Call.calif_id=Tipo.calif_id  
		INNER JOIN ccUserView Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
		LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]  
		LEFT JOIN ccStatusLlamada sta on call.statuscall_id = sta.statuscall_id  
		LEFT JOIN cstoProvedor prov ON prov.[provedor_id] = Call.[provedor_id]  
		LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] and tl.Country_id = @country)  
		LEFT JOIN ccTipoCalifSubOut sub on call.califsub_id = sub.califsub_id 
		LEFT JOIN ccoDialers di on di.dialer_id = Call.cal_puerto
		LEFT JOIN cstoProvedor on di.provedor_id = cstoProvedor.provedor_id
		WHERE Call.cal_inicio >= @from
		AND Call.cal_inicio < @to
		and cal_manual = 3
		order by date
end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepOutDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepOutDispositions with(rowlock)
	where date >= @from AND date < @to

	insert into RepOutDispositions 
	select CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121) as dateHour, a.cam_id, '''' as Campaign, a.calif_id, '''' as DispName, '''', count(calif_id) DispAmount, user_id, '''' as login
	, '''' as username, b.IDArea, '''' as areaName, 1 as wgId, ''systemTranslated_WorkGroup'' as wg,
	datepart(yyyy,max(cal_inicio)) as year, datepart(mm,max(cal_inicio)), datepart(dd,max(cal_inicio)),
	datepart(hh,max(cal_inicio)), datepart(mi,max(cal_inicio))
	from ccocallsout a 		
	left join cccamps b
	on	b.cam_id = a.cam_id		
	where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13 and cal_manual in (0,2)
	and b.idArea is not null
	group by CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121),a.cam_id, a.calif_id, user_id,b.IDArea

	update a set campaign = isnull(cam_descripcion,'''')
	from RepOutDispositions a
	left join cccamps b 
	on a.campaignId = b.cam_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,''systemTranslated_Dispositionless''), disposition_count = isnull(description,''systemTranslated_Dispositionless'') + ''_Count''
	from RepOutDispositions a
	left join cctipocalifout b 
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepOutDispositions a
	left join ccUserView b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepOutDispositions a
	left join ccUserView b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepOutDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to


end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepOutKPI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete RepOutKPI with(rowlock)
	where date >= @from AND date < @to

	insert into RepOutKPI
	select dateHour, cam_id, campaign, sum(totalCalls) as totalCalls,
	sum(txfer)/sum(totalCalls) as avgXfer, sum(tDialog)/sum(totalCalls) as avgCallTime,
	sum(C10) as c10sec, sum(C20) as c20sec, sum(C30) as c30sec, sum(CMax) as cMax,
	sum(AnsweredCalls) as AnsweredCalls, (sum(AnsweredCalls) * 100.00)/sum(totalCalls) as AnsweredPctg,
	sum(RemainingCalls) as RemainingCalls, (sum(RemainingCalls) * 100.00)/sum(totalCalls) as RemainingPct,
	sum(AbandonedCalls) as AbandonedCalls, (sum(AbandonedCalls) * 100.00)/sum(totalCalls) as AbandonedPctg,
	(3600*1.00)/sum(totalCalls) as AvgTimeBtwCalls,
	datepart(yyyy,max(dateHour)) as [year], datepart(mm,max(dateHour)) as [month], datepart(dd,max(dateHour)) as [day],
	datepart(hh,max(dateHour)) as [hour], datepart(mi,max(dateHour)) as [minutes]
	from
	(
		select CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour, cam_id, '''' as campaign,
		count(*) as totalCalls,
		cal_tXfer as tXfer,
		cal_tDialog as tDialog,
		case when statusCall_id = 13 and cal_tDialog<=10 then 1 else 0 end C10,
		case when statusCall_id = 13 and cal_tDialog<=20 and cal_tDialog > 10 then 1 else 0 end C20,
		case when statusCall_id = 13 and cal_tDialog<=30 and cal_tDialog > 20 then 1 else 0 end C30,
		case when statusCall_id = 13 and cal_tDialog>30 then 1 else 0 end CMax,
		case when statusCall_id = 13 then 1 else 0 end as AnsweredCalls,
		0.00 as AnsweredPctg,
		case when statusCall_id not in (13,5) then 1 else 0 end  as RemainingCalls,
		0.00 as RemainingPct,
		case when statusCall_id in(5,6,7,8,9,10,11,15,16) then 1 else 0 end  as AbandonedCalls,
		0.00 as AbandonedPctg,
		0.00 as AvgTimeBtwCalls
		from ccocallsout with(index(IX_ccoCallsOut_2),nolock)
		where cal_inicio >= @from and cal_inicio < @to
		group by statusCall_id, cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121), cal_tXfer, cal_tDialog
	) as final
	group by dateHour, cam_id, campaign
	order by dateHour, cam_id

	update RepOutKPI with(rowlock)
	set campaign = isnull(b.cam_descripcion,'''')
	from RepOutKPI a
	left join ccCamps b
	on a.campaignId = b.cam_id
	where date >= @from AND date < @to

end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE[dbo].[ccspRepOutManagementBase]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null 
	select @to = getdate()

if @action = 1
begin
	delete from RepOutManagementBase with(rowlock)
	where [date] >= @from AND [date] < @to

	insert into RepOutManagementBase
	select  fecha as fecha,
		   cout.callout_id,isnull(resdial.tipoResDial_id,0) as dialResultId,isnull(resdial.descripcion,'''') as ResultadoMarcacion, --,cout.callout_id as llamada ,
		   isnull(tipocal.calif_id,0)as dispositionId,ISNULL( tipocal.Description,'''') as Calificacion,isnull(tiposubcal.califSub_id,0) as dispositionId,
		   isnull(tiposubcal.califSubDesc,'''') as SubCalificacion,isnull( SUM(cout.cal_manual),0) as total,
		   cout.User_id as Agent, cout.cam_id as campaign,
				 datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) AS [year],
				 datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [month],
				 datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [day],
				 datepart(hh,fecha) as [hour],
				 datepart(mi,fecha) as [minutes]
	from ccoCallsOut cout
		   left join ccoLogDials logdial on cout.callout_id = logdial.callout_id
		   left join cctipoResultadodial resdial on logdial.tipoResDial_id = resdial.tipoResDial_id
		   left join cctipocalifout tipocal on cout.calif_id = tipocal.calif_id
		   left join cctipocalifsubout tiposubcal on cout.califSub_id = tiposubcal.califSub_id
	where fecha >= @from and fecha < @to
	group by cout.callout_id,resdial.tipoResDial_id,resdial.descripcion,
	tipocal.Description,tiposubcal.califSubDesc,cout.cal_manual,fecha,tipocal.calif_id,tiposubcal.califSub_id, cout.User_id, cout.cam_id

	update a set campaigns = isnull(cam_descripcion,'''')
		from RepOutManagementBase a
		left join ccCamps b 
		on a.campaigns = b.cam_id
		where [date] >= @from AND [date] < @to

	update a set Agent = isnull(login,'''')
		from RepOutManagementBase a
		left join ccUserView b 
		on a.Agent = b.user_id
		where [date] >= @from AND [date] < @to


end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepOutSubDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepOutSubDispositions with(rowlock)
	where date >= @from AND date < @to

	insert into RepOutSubDispositions 
	select CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121) as dateHour, a.cam_id, '''' as Campaign, isnull(a.califSub_id,0), '''' as DispName, '''', count(calif_id) DispAmount, user_id, '''' as login
	, '''' as username, b.IDArea, '''' as areaName, 1 as wgId, ''systemTranslated_WorkGroup'' as wg,
	datepart(yyyy,max(cal_inicio)) as year, datepart(mm,max(cal_inicio)), datepart(dd,max(cal_inicio)),
	datepart(hh,max(cal_inicio)), datepart(mi,max(cal_inicio))
	from ccocallsout a (nolock)
	left join ccCamps b
	on	b.cam_Id = a.cam_id		
	where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13 and cal_manual in (0,2)
	and b.IDArea is not null
	group by CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121),a.cam_id, a.califSub_id, user_id,b.IDArea

	update a set campaign = isnull(cam_descripcion,'''')
	from RepOutSubDispositions a
	left join ccCamps b 
	on a.campaignId = b.cam_id
	where [date] >= @from AND [date] < @to

	update a set subDisposition = isnull(califSubDesc,''systemTranslated_Dispositionless''), subDisposition_count = isnull(califSubDesc,''systemTranslated_Dispositionless'') + ''_Count''
	from RepOutSubDispositions a
	left join cctipocalifsubout b 
	on a.subDispositionId = b.califSub_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepOutSubDispositions a
	left join ccUserView b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepOutSubDispositions a
	left join ccUserView b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepOutSubDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepSpececialAgtPerformance]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()
							
	DECLARE @data varchar(10), @promesa INT, @promesainb INT, @tresDialog AS smallint
	EXEC @tresDialog=ccspConfigTresDialog
	select @data = isnull(valor,''1|1'') from ccSettings where setting_id = 30
	SELECT @promesainb = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 1
	SELECT @promesa = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 2
						
	delete RepSpececialAgtPerformance with(rowlock)
	where [date] between @from and @to

	insert RepSpececialAgtPerformance select [date],rcalls.USER_ID [userId]
	,us.apellidopaterno + '' '' + us.apellidomaterno + '' '' + nombres [user],login [Agent]
	,answer Answered, promises, promisesPctg, dialog avgCallTime, wrapup avgWrapupTime
	from (
	select [date], user_id, SUM(answer) answer, SUM(promises) promises
	,isnull(cast(SUM(promises)*100.0/nullif(SUM(answer),0) as decimal(5,2)),0) promisesPctg
	,isnull(sum(dialog)/nullif(SUM(answer),0),0) dialog, isnull(sum(wrapup)/nullif(SUM(answer),0),0) wrapup
	from (
	select 
	CONVERT(varchar(10),cal_inicio,121) [date], user_id
	,isnull(sum(cal_tdialog),0) dialog, isnull(sum(cal_tnotas),0) wrapup
	,isnull(count(case calif_id when @promesa then 1 else null end),0) promises
	,isnull(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END),0) answer
	from ccoCallsOut with(index(IX_ccoCallsOut_2),nolock) where cal_inicio between @from and @to and cal_manual in(0,2) and USER_ID>0
	group by CONVERT(varchar(10),cal_inicio,121),user_id
	union all
	select
	CONVERT(varchar(10),cal_inicio,121) [date], user_id
	,isnull(sum(cal_tdialog),0) dialog, isnull(sum(cal_tnotas),0) wrapup
	,isnull(count(case calif_id when @promesainb then 1 else null end),0) promises
	,isnull(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) answer
	from ccCallsIn with(index(IX_ccCallsIn),nolock) where cal_inicio between @from and @to  and USER_ID>0
	group by CONVERT(varchar(10),cal_inicio,121),user_id) calls group by [date],user_id) rcalls 
	left join ccUserView us on us.user_id=rcalls.user_id
end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepSpececialCamMovs]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()

	delete RepSpececialCamMovs with(rowlock)
	where [date] between @from and @to

	insert RepSpececialCamMovs
	SELECT movs.fecha as [date], movs.cam_id campaignId, camp.cam_descripcion campaign, 
	CASE movs.TipoMov
	WHEN 0 THEN ''systemTranslated_Stop''
	WHEN 1 THEN ''systemTranslated_Start''
	WHEN 2 THEN ''systemTranslated_newRecords''
	WHEN 3 THEN ''systemTranslated_jobNew''
	WHEN 4 THEN ''systemTranslated_jobCB''
	WHEN 5 THEN ''systemTranslated_Delete''
	WHEN 6 THEN ''systemTranslated_jobBoth''
	END AS [action],
	CASE WHEN movs.prevMovs = 0 THEN ''systemTranslated_jobNew''
	WHEN movs.prevMovs = 1 THEN ''systemTranslated_jobCB''
	WHEN movs.prevMovs = 2 THEN ''systemTranslated_jobBoth''
	WHEN movs.prevMovs IS NULL THEN ''systemTranslated_noType''
	END AS [type],
	movs.NewRecords AS nnew, movs.CBRecords AS ncallback,
	CASE WHEN movs.cant_agent IS NULL THEN 0 ELSE movs.cant_agent END AS Agents,
	CASE WHEN movs.user_id IS NULL THEN ''systemTranslated_NoName''
	WHEN movs.user_id = 0 THEN ''systemTranslated_NoName''
	ELSE usr.Nombres+'' ''+ISNULL(usr.ApellidoPaterno,'''')+'' ''+ISNULL(usr.ApellidoMaterno,'''')
	END AS [user]
	FROM ccCampsMovs as movs JOIN ccCamps as camp ON movs.cam_id = camp.cam_id 
	LEFT OUTER JOIN ccUserView AS usr ON movs.user_id = usr.user_id
	WHERE movs.fecha BETWEEN @from AND @to
end'

		EXEC (@sql)

		SET @process = 'CW-2379 Alter SP --  Report use View ccuserView '
		SET @sql = 
			'ALTER PROCEDURE [dbo].[ccspRepSpecialCallKeyHistory]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()

	delete RepSpecialCallKeyHistory where [date] between @from and @to
	
	insert RepSpecialCallKeyHistory select CONVERT(varchar(16),fecha,121) [date], ISNULL(ld.cam_id, 0) campaignId,
		ISNULL(cam_descripcion, ''systemTranslated_NoCampaign'') campaign,
		ld.cal_Key callKey,ld.Telefono telephone,ISNULL(rd.descripcion, ''systemTranslated_NoStatus'') dialResult,
		ISNULL(cal.Description, ''systemTranslated_Dispositionless'') disposition, 
		ISNULL(cal_tdialog, 0) dialogTime, ISNULL(convert(varchar(30),cal_fcallback,121),''systemTranslated_NoCallback'') CallBacks,
		isNull(cast(us.Login as varchar(100)),''systemTranslated_NoUserName'') [login],
		isNull(us.ApellidoPaterno,'''') + '' '' + isNull(us.ApellidoMaterno, '''') + '' '' + IsNull(us.Nombres, ''systemTranslated_NoName'') as [user]
		from ccoLogDials ld with(index(IX_ccoLogDials),nolock)
		left join ccoCallsOut co (nolock) on co.cal_id = ld.cal_id
		left join ccTipoResultadoDial rd on rd.tipoResDial_id = ld.tipoResDial_id left join ccCamps ca on ca.cam_id = ld.cam_id
		left join ccTipoCalifOUT cal on cal.calif_id=co.calif_id 
		left join ccUserView us on us.User_id=co.User_id
		where ld.fecha between @from and @to and len(ld.cal_key)>0
end'

		EXEC (@sql)

		IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
