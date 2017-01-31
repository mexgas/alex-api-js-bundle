/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2017/01/06
Description:
**********************************************************************************************
	Se agrega tarea CW-561_GASJ_Reportes_Errescuer_Fase_2
Database: ccReportsRia
Required version: 40



IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =42
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try

	set @process = 'Drop SP -- ccspRepDialingResultsDetail 4180'
	set @Sql= 'if exists (select * from sys.procedures where name = ''ccspRepDialingResultsDetail'') DROP PROCEDURE [dbo].[ccspRepDialingResultsDetail]'
	EXEC(@sql)


	set @process = 'Drop SP -- RepOutManagementBase 4170'
	set @Sql= 'if exists (select * from sys.procedures where name = ''ccspRepOutManagementBase'') DROP PROCEDURE [dbo].[ccspRepOutManagementBase]'
	EXEC(@sql)

	set @process = 'Drop SP -- ccspRepAgentCallStatusesByInterval 2070'
	set @Sql= 'if exists (select * from sys.procedures where name = ''ccspRepAgentCallStatusesByInterval'') DROP PROCEDURE [dbo].[ccspRepAgentCallStatusesByInterval]'
	EXEC(@sql)

	set @process = 'Create Table -- RepDialingResultsDetail 4180'
	set @Sql= 'if not exists(select * from sys.tables where name=''RepDialingResultsDetail'')
create table RepDialingResultsDetail(
	[date] [datetime] NOT NULL,
	[telephone] [varchar](30) NOT NULL,
	[dialResultId] int NOT NULL,
	[dialResult] varchar(30) NOT NULL,
	[userId] [int] NOT NULL,
	[login] [varchar](50) NOT NULL,
	[campaignId] int NOT NULL,
	[campaign] [varchar](40) NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]'
	EXEC(@sql)

	set @process = 'create table RepOutManagementBase----'
	set @Sql= 'if not exists(select * from sys.tables where name=''RepOutManagementBase'')
	create table RepOutManagementBase
(
[date] datetime,
cCodigo int not null,
tipoResDial_id int not null,
ResultadoMarcacion varchar(20),
calif_id int not null,
Calificacion varchar(30),
califSub_id int not null, 
SubCalificacion varchar(30),
total int,
[year] int,
[month] int,
[day] int,
[hour] int,
[minutes] int
);'

	EXEC(@sql)

	set @process = 'Create table -- ccspRepAgentCallStatusesByInterval 2070'
	set @Sql= 'if not exists (select * from sys.tables where name = ''RepAgentCallStatusesByInterval'')
CREATE TABLE [dbo].[RepAgentCallStatusesByInterval](
[date][datetime] NOT NULL, 
[userId][int] NOT NULL,
[agentName][varchar](255) NOT NULL,
[startInterval][datetime] NOT NULL,
[endInterval][datetime] NOT NULL,
[readyTime][int] NOT NULL, 
[twrapup][int] NOT NULL, 
[tring][int] NOT NULL,
[tother][int] NOT NULL,
[tnav][int] NOT NULL,
[tCallTransf][int] NOT NULL,
[twbCall][int] NOT NULL,
[year][int] NOT NULL,
[month][int] NOT NULL,
[day][int] NOT NULL,
[hour][int] NOT NULL,
[minutes][int] NOT NULL
) ON [PRIMARY]'
	EXEC(@sql)

	set @process = 'Create SP -- ccspRepDialingResultsDetail 4180'
	set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepDialingResultsDetail]
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
FROM ccoLogDials dial
left join ccocallsout co on  dial.callout_id = co.callout_id and dial.Telefono=co.cal_telefono
left join cctipoResultadoDial tr ON dial.tiporesdial_id=tr.tiporesdial_id
left join ccUsers u on u.user_id =co.User_id
left join ccCamps camp on camp.cam_id=dial.cam_id
where dial.fecha>=@from and dial.fecha<@to


end'
	EXEC(@sql)


	set @process = 'Create SP -- ccspRepOutManagementBase 4170'
	set @Sql= 'CREATE PROCEDURE[dbo].[ccspRepOutManagementBase]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete from RepOutManagementBase with(rowlock)
	where [date] >= @from AND [date] < @to
	
insert into RepOutManagementBase 
select  CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121) as fecha,
	cout.callout_id,isnull(resdial.tipoResDial_id,0) as dialResultId,resdial.descripcion as ResultadoMarcacion, --,cout.callout_id as llamada , 
	isnull(tipocal.calif_id,0)as dispositionId,ISNULL( tipocal.Description,'''') as Calificacion,isnull(tiposubcal.califSub_id,0) as dispositionId,
	isnull(tiposubcal.califSubDesc,'''') as SubCalificacion,SUM(cout.cal_manual) as total,
		datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) AS [year],
		datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [month],
		datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [day],
		datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [hour],
		datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [minutes]
from ccoCallsOut cout 
	left join ccoLogDials logdial on cout.callout_id = logdial.callout_id
	left join cctipoResultadodial resdial on logdial.tipoResDial_id = logdial.tipoResDial_id
	left join cctipocalif tipocal on cout.calif_id = tipocal.calif_id
	left join cctipocalifsub tiposubcal on cout.califSub_id = tiposubcal.califSub_id
where fecha >= @from and fecha < @to
group by cout.callout_id,resdial.tipoResDial_id,resdial.descripcion,
tipocal.Description,tiposubcal.califSubDesc,cout.cal_manual,fecha,tipocal.calif_id,tiposubcal.califSub_id

end '
	EXEC(@sql)

	set @process = 'Create SP -- ccspRepAgentCallStatusesByInterval 2070'
	set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepAgentCallStatusesByInterval]
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
		   ,case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_Inicio,121) + '':00:00.000''
				 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_Inicio,121) + '':15:00.000''
		   when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_Inicio,121) + '':30:00.000''
		   when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_Inicio,121) + '':45:00.000'' end as timegroup
		   ,case when datepart(mi,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
		   between 0 and 14 then convert(varchar(13),dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':15:00.000''
		   when datepart(mi,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
		   between 15 and 29 then convert(varchar(13),dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':30:00.000''
		   when datepart(mi,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
		   between 30 and 44 then convert(varchar(13),dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':45:00.000''
		   else  convert(varchar(13),dateadd(hh,1,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio)),121) + '':00:00.000'' end as timegroup_next		  
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
	 ,C.timegroup_next=
	 case when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 0 and 14 then convert(varchar(13),dateadd(ss, tiempo,B.fecha),121) + '':15:00.000''
	 	when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 15 and 29 then convert(varchar(13),dateadd(ss, tiempo,B.fecha),121) + '':30:00.000''
	 	when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 30 and 44 then convert(varchar(13),dateadd(ss, tiempo,B.fecha),121) + '':45:00.000''
	 	when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 45 and 59 then convert(varchar(13),dateadd(hh,1,B.fecha),121) + '':00:00.000'' end
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
	,convert(datetime,case when datepart(mi,A.dateIni) between 0 and 14 then convert(varchar(13),A.dateIni,121) + '':00:00.000''
			when datepart(mi,A.dateIni) between 15 and 29 then convert(varchar(13),A.dateIni,121) + '':15:00.000''
			when datepart(mi,A.dateIni) between 30 and 44 then convert(varchar(13),A.dateIni,121) + '':30:00.000''
			when datepart(mi,A.dateIni) between 45 and 59 then convert(varchar(13),A.dateIni,121) + '':45:00.000'' end) AS timegroup
	,convert(datetime,case when datepart(mi,A.dateEnd) between 0 and 14 then convert(varchar(13),A.dateEnd,121) + '':15:00.000''
			when datepart(mi,A.dateEnd) between 15 and 29 then convert(varchar(13),A.dateEnd,121) + '':30:00.000''
			when datepart(mi,A.dateEnd) between 30 and 44 then convert(varchar(13),A.dateEnd,121) + '':45:00.000''
			when datepart(mi,A.dateEnd) between 45 and 59 then convert(varchar(13),dateadd(hh,1,A.dateEnd),121) + '':00:00.000'' end) as timegroup_next,
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
	 	@dateNow as dateEndDetail,
	 	case when datepart(mi,B.fecha) between 0 and 14 then convert(varchar(13),B.fecha,121) + '':00:00.000''
	 		when datepart(mi,B.fecha) between 15 and 29 then convert(varchar(13),B.fecha,121) + '':15:00.000''
	 		when datepart(mi,B.fecha) between 30 and 44 then convert(varchar(13),B.fecha,121) + '':30:00.000''
	 		when datepart(mi,B.fecha) between 45 and 59 then convert(varchar(13),B.fecha,121) + '':45:00.000'' end as timegroup
	 	,case when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 0 and 14 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':15:00.000''
	 		when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 15 and 29 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':30:00.000''
	 		when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 30 and 44 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':45:00.000''
	 		when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 45 and 59 then  convert(varchar(13),dateadd(hh,1,B.fecha),121) + '':00:00.000'' end as timegroup_next
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
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to and TipoNotReady_id in(1,2)

	insert into #tempNotReady (user_id,dateStartDetail,dateEndDetail, timegroup, timegroup_next, tnav, twbcall)
	select user_id,dateStart,dateEnd
	,convert(datetime,case when datepart(mi,A.dateStart) between 0 and 14 then convert(varchar(13),A.dateStart,121) + '':00:00.000''
			when datepart(mi,A.dateStart) between 15 and 29 then convert(varchar(13),A.dateStart,121) + '':15:00.000''
			when datepart(mi,A.dateStart) between 30 and 44 then convert(varchar(13),A.dateStart,121) + '':30:00.000''
			when datepart(mi,A.dateStart) between 45 and 59 then convert(varchar(13),A.dateStart,121) + '':45:00.000'' end) AS timegroup
	,convert(datetime,case when datepart(mi,A.dateEnd) between 0 and 14 then convert(varchar(13),A.dateEnd,121) + '':15:00.000''
			when datepart(mi,A.dateEnd) between 15 and 29 then convert(varchar(13),A.dateEnd,121) + '':30:00.000''
			when datepart(mi,A.dateEnd) between 30 and 44 then convert(varchar(13),A.dateEnd,121) + '':45:00.000''
			when datepart(mi,A.dateEnd) between 45 and 59 then convert(varchar(13),dateadd(hh,1,A.dateEnd),121) + '':00:00.000'' end) as timegroup_next,
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
	,convert(datetime,case when datepart(mi,A.dateStartDetail) between 0 and 14 then convert(varchar(13),A.dateStartDetail,121) + '':00:00.000''
			when datepart(mi,A.dateStartDetail) between 15 and 29 then convert(varchar(13),A.dateStartDetail,121) + '':15:00.000''
			when datepart(mi,A.dateStartDetail) between 30 and 44 then convert(varchar(13),A.dateStartDetail,121) + '':30:00.000''
			when datepart(mi,A.dateStartDetail) between 45 and 59 then convert(varchar(13),A.dateStartDetail,121) + '':45:00.000'' end) AS timegroup
	,convert(datetime,case when datepart(mi,A.dateEndDetail) between 0 and 14 then convert(varchar(13),A.dateEndDetail,121) + '':15:00.000''
			when datepart(mi,A.dateEndDetail) between 15 and 29 then convert(varchar(13),A.dateEndDetail,121) + '':30:00.000''
			when datepart(mi,A.dateEndDetail) between 30 and 44 then convert(varchar(13),A.dateEndDetail,121) + '':45:00.000''
			when datepart(mi,A.dateEndDetail) between 45 and 59 then convert(varchar(13),dateadd(hh,1,A.dateEndDetail),121) + '':00:00.000'' end) as timegroup_next
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
		left join ccUsers U on O.User_id = U.User_id or Agent.User_id=U.User_id or nReady.User_id=U.User_id
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
	EXEC(@sql)

	set @process = 'Create Index -- RepDialingResultsDetail.IX_RepDialingResultsDetail 4180'
	set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_RepDialingResultsDetail'' and object_id = OBJECT_ID(N''RepDialingResultsDetail''))
    begin
        CREATE NONCLUSTERED INDEX [IX_RepDialingResultsDetail] ON [dbo].[RepDialingResultsDetail]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
    end'
	EXEC(@sql)

	set @process = 'Create Index -- RepAgentCallStatusesByInterval.IX_RepAgentCallStatusesByInterval 2070'
	set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_RepAgentCallStatusesByInterval'' and object_id = OBJECT_ID(N''RepAgentCallStatusesByInterval''))
    begin
        CREATE NONCLUSTERED INDEX [IX_RepAgentCallStatusesByInterval] ON [dbo].[RepAgentCallStatusesByInterval]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
    end'
	EXEC(@sql)

	set @process = 'Create ReportsFiltersMenus -- 4180'
	set @Sql= 'if not exists(select * from ReportsFiltersMenus where idReport=4180) begin
	insert into ReportsFiltersMenus(idReport,filterMenuName) values(4180,N''date'')
	insert into ReportsFiltersMenus(idReport,filterMenuName) values(4180,N''filterby'')
end'
	EXEC(@sql)

	set @process = 'Create ReportsFilters -- 4180'
	set @Sql= 'if not exists(select * from ReportsFilters where id=4180) begin
	insert into ReportsFilters(reportName,filterName,id) values(''Report detail Calling Dialing Errescuer'',''campaigns'',4180)
	insert into ReportsFilters(reportName,filterName,id) values(''Report detail Calling Dialing Errescuer'',''users'',4180)
end'
	EXEC(@sql)

	set @process = 'Create ReportsCharts -- 4180'
	set @Sql= 'if not exists(select * from ReportsCharts where id=4180) begin
	insert into ReportsCharts(id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
	values(4180,''Report detail Calling Dialing Errescuer'',1,''campaign'','''','''','''',''sum([dialResultId])'',''Answered calls detail per Campaign'',0)
	insert into ReportsCharts(id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
	values(4180,''Report detail Calling Dialing Errescuer'',2,''campaign'',''dialResult'','''','''','''',''Dial Results per Campaign'',0)
end'
	EXEC(@sql)

	set @process = 'Create TranslatedReports -- 4180'
	set @Sql= 'if not exists(select * from TranslatedReports where id=4180) insert into TranslatedReports (id,columns) values(4180,''login'')'
	EXEC(@sql)

	set @process = 'Create ReportsTotals -- 4180'
	set @Sql= 'if not exists(select * from ReportsTotals where id=4180) insert into ReportsTotals(id,totalColumns) values(4180,'''')'
	EXEC(@sql)

	set @process = 'Create Index -- RepOutManagementBase.IX_RepOutManagementBase 4170'
	set @Sql= ' if not exists (select * from sys.indexes where name = N''IX_RepOutManagementBase'' and object_id = OBJECT_ID(N''RepOutManagementBase''))
	begin 
	CREATE NONCLUSTERED INDEX [IX_RepOutManagementBase] ON [dbo].RepOutManagementBase
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
    end '
	EXEC(@sql)

	set @process = 'Insert into ReportsFiltersMenus ----'
	set @Sql= 'if not exists(select * from ReportsFiltersMenus where id=4170) 
	begin 
		insert into ReportsFiltersMenus 
		values (4170,''date'')
	end'
	EXEC(@sql)

	set @process = 'insert into ReportsFilters----'
	set @Sql= 'if not exists(select * from ReportsFilters where id=4170)
	begin 
		insert into ReportsFilters
		values(''Report Out Management Base'',''campaigns'',4170)
	end'
	EXEC(@sql)

	set @process = 'insert into ReportsCharts ---------'
	set @Sql= 'if not exists(select * from ReportsFilters where id=4170) 
	begin
	insert into ReportsCharts 
	values(4170,''Report Out Management Base'',1,''campaign'','''','''','''','''',''Management Base'',0)
	end'
	EXEC(@sql)

	set @process = 'insert into ReportsTotals--------'
	set @Sql= 'if not exists(select * from ReportsFilters where id=4170) 
	begin
		insert into ReportsTotals
		values(4170,''sum:total'')
	end'
	EXEC(@sql)

	set @process = 'Insert ReportsFiltersMenus -- 2070'
	set @Sql= 'if not exists(select * from ReportsFiltersMenus where idReport=2070) 
begin
INSERT ReportsFiltersMenus (idReport, filterMenuName) VALUES (2070, N''date'')
INSERT ReportsFiltersMenus (idReport, filterMenuName) VALUES (2070, N''filterby'')
end'
	EXEC(@sql)

	set @process = 'Insert ReportsFilters -- 2070'
	set @Sql= 'if not exists(select * from ReportsFilters where id=2070)
begin
INSERT ReportsFilters VALUES (''Agent and Call Statuses by Interval'',''users'',2070)
end'
	EXEC(@sql)

	set @process = 'Insert ReportsTotals -- 2070'
	set @Sql= 'if not exists (select * from ReportsTotals where id = 2070)
begin
INSERT INTO ReportsTotals values (2070,''sum:readyTime|sum:tring|sum:twrapup|sum:tother|sum:tnav|sum:tCallTransf|sum:twbCall'')
end'
	EXEC(@sql)

	set @process = 'Insert ccSettings -- 40'
	set @Sql= 'if not exists (select * from ccSettings where setting_id = 40)
begin
INSERT ccSettings (setting_id,valor,descripcion,Status,Tipo) VALUES (40,''1|2'',''Id No disponible 1|Id No disponible 2 especificados por el cliente'',1,''RPT'')
end'
	EXEC(@sql)

	set @process = ''
	set @Sql= ''
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