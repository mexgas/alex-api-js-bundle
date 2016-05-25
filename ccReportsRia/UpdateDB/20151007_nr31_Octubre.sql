/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2015/10/19
Description:

	Se agrega fix para ejeccuion por tiempo report master process
Database: ccReportsRiaPara 
Required version: 30

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 31

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try


	set @process = 'update [dbo].[GroupByReports] y [ReportsTotals] ---------'
	set @Sql= 'update [dbo].[GroupByReports]
		set columns = ''userId|max([user]):user|max([login]):login|sum([nxferin]):nxferin|sum([nanswerin]):nanswerin|sum([nabndxferin]):nabndxferin|sum([nabndringin]):nabndringin|sum([nabnddlgin]):nabnddlgin|sum([abndaxferin]):abndaxferin|sum([nnoanswerin]):nnoanswerin|sum([nlostin]):nlostin|sum([tdialogin]):tdialogin|sum([tnotesin]):tnotesin|sum([tringin]):tringin|sum([txferin]):txferin|sum([nxferout]):nxferout|sum([nanswerout]):nanswerout|sum([nabndxferout]):nabndxferout|sum([nabndringout]):nabndringout|sum([nabnddlgout]):nabnddlgout|sum([abndaxferout]):abndaxferout|sum([nnoanswerout]):nnoanswerout|sum([nlostout]):nlostout|sum([tdialogout]):tdialogout|sum([tnotesout]):tnotesout|sum([tringout]):tringout|sum([txferout]):txferout|sum([nother]):nother|sum([tunknown]):tunknown|sum([tnotav]):tnotav|sum([tlog]):tlog|sum([treq]):treq|sum([tav]):tav|sum([tother]):tother|sum([tprob]):tprob|sum([nmohin]):nmohin|sum([nmohout]):nmohout|sum([nwhagin]):nwhagin|sum([nwhagout]):nwhagout|sum([nwhcliin]):nwhcliin|sum([nwhcliout]):nwhcliout|isnull(sum([tdialogin]+[tdialogout])/nullif(sum([nanswerin]+[nanswerout])_0)_0):tnotavg''
		where id = 2010

		update [dbo].[ReportsTotals]
		set totalColumns = ''sum:nxferin|sum:nanswerin|sum:nabndxferin|sum:nabndringin|sum:nabnddlgin|sum:abndaxferin|sum:nnoanswerin|sum:nlostin|sum:tdialogin|sum:tnotesin|sum:tringin|sum:txferin|sum:nxferout|sum:nanswerout|sum:nabndxferout|sum:nabndringout|sum:nabnddlgout|sum:abndaxferout|sum:nnoanswerout|sum:nlostout|sum:tdialogout|sum:tnotesout|sum:tringout|sum:txferout|sum:nother|sum:tunknown|sum:tnotav|sum:tlog|sum:treq|sum:tav|sum:tother|sum:tprob|sum:nmohin|sum:nmohout|sum:nwhagin|sum:nwhagout|sum:nwhcliin|sum:nwhcliout|special:tnotavg:isnull(sum([tdialogin]+[tdialogout])/nullif(sum([nanswerin]+[nanswerout]),0),0)''
		where id = 2010'
	EXEC(@Sql)


	set @process = 'DROP TRIGGER [dbo].[trigPosicionEspecialidad]' ---------'
	set @Sql= 'IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N''[dbo].[trigPosicionEspecialidad]''))
			DROP TRIGGER [dbo].[trigPosicionEspecialidad]'
	EXEC(@Sql)

	set @process = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail] ---------'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @IVA INT
SELECT @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25

if @action = 1
	begin		
		--Borrar lo que esta para no repetir
		delete from RepOutCallsDetail with(rowlock)
		where date >= @from AND date < @to

		INSERT INTO RepOutCallsDetail
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
		case when cal_whoHung = 0 then ''systemTranslated_Client''
		when cal_whoHung = 1 then ''systemTranslated_Agent''
		else ''systemTranslated_AgentSurvey'' end [whoHangUp], 
		case when call.califsub_id = 0 then ''systemTranslated_NoSubDisposition'' else isnull(sub.califSubDesc, '''') end as [subDisposition],
		sta.descripcion as [dialResult],
		Call.cal_id as [calId]
		, datepart(yyyy,Call.cal_inicio) AS [year]
		, datepart(mm,Call.cal_inicio) as [month]
		, datepart(dd,Call.cal_inicio) as [day]
		, datepart(hh,Call.cal_inicio) as [hour]
		, datepart(mi,Call.cal_inicio) as [minutes]
		,Call.cal_puerto
		FROM ccoCallsOut Call  
		LEFT JOIN ccTipoCalifOUT Tipo ON Call.calif_id=Tipo.calif_id  
		INNER JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
		LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]  
		LEFT JOIN ccStatusLlamada sta on call.statuscall_id = sta.statuscall_id  
		LEFT JOIN cstoProvedor prov ON prov.[provedor_id] = Call.[provedor_id]  
		LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] and tl.Country_id = 1)  
		LEFT JOIN ccTipoCalifSubOut sub on call.califsub_id = sub.califsub_id 
		LEFT JOIN ccoDialers di on di.dialer_id = Call.cal_puerto
		LEFT JOIN cstoProvedor on di.provedor_id = cstoProvedor.provedor_id
		WHERE Call.cal_inicio >= @from
		AND Call.cal_inicio < @to
		and cal_manual in (0, 2) 
		order by date
	end'
	EXEC(@Sql)

	


	set @process = 'ALTER PROCEDURE [dbo].[ccspRepIVRDetail] ---------'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepIVRDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
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
	,isnull(B.cal_id,0) as [cal_id],A.date,A.dnis
	from IVRCallsIn as A
	left join ccCallsIn As B on  A.IVR_id = B.IVR_id
	where date >= @from and date < @to
	and A.dnis <> ''''


	delete from RepIVRDetail with(rowlock)
	where date >= @from AND date < @to

	insert into RepIVRDetail
		select #IVRLlamadas.date as fecha, cal_ani as telefono
			, isNull(u.nombres + '' '' + u.apellidopaterno + '' '' + u.apellidomaterno,'''') as nombre
			, isnull(calif.description, #IVRLlamadas.calif_id) as calificacion, cal_id as cal_id
			, isnull(
			(
				select selectedOption + '',''	from IVROptions
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
				select ivr_id,name, max(date) as maxDate from IVROptions
				group by ivr_id,name
			) optTime on #IVRLlamadas.ivr_id = optTime.ivr_id
			left join ccusers u on (u.user_id = #IVRLlamadas.user_id)
			left join cctipocalif calif on (calif.calif_id = #IVRLlamadas.calif_id)
			where #IVRLlamadas.date >= @from and #IVRLlamadas.date < @to
			order by date

	drop table #IVRLlamadas
	end'
	EXEC(@Sql)


	set @process = 'ALTER PROCEDURE [dbo].[ccspRepMKTAgentes] ---------'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepMKTAgentes]
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
	case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_inicio,121) + '':00:00.000''
	     when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_inicio,121) + '':15:00.000''
		 when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_inicio,121) + '':30:00.000''
		 when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_inicio,121) + '':45:00.000'' end as timegroup,
	case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':15:00.000''
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':30:00.000''
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':45:00.000''
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 45 and 59 then  convert(varchar(13), dateadd(hh,1,cal_Inicio),121) + '':00:00.000'' end as timegroup_next,
		 c.user_id,isnull(count(case when c.statusCall_id=13 then 1 else null end),0) nacd,
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
       where c.cal_inicio between @from and @to and c.user_id>0 and c.inbound_id>0
       group by c.user_id,cal_inicio

	select * into #timeAgenteTransfer2 from #timeAgenteTransfer where datediff(mi,timegroup,timegroup_next)>15
	delete #timeAgenteTransfer where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeAgenteTransfer
	select dateStartDetail,dateEndDetail,th.start,th.stop,user_id
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nacd else 0 end nacd
,case when th.start > dateStartDetail and th.stop > dateEndDetail then nacw else 0 end nacw
,case when th.start > dateStartDetail and th.stop > dateEndDetail then cayuda else 0 end cayuda
,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfersal else 0 end nxfersal
,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,dateStartDetail,time_dialog)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_dialog then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_dialog and  th.stop > time_notes then datediff(ss,th.start,time_dialog)
	  when th.start > dateStartDetail and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tresp
,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
	  when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
	  when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
	  when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tacd
,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
	  when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
	  when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
	  when th.start > time_notes and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tacd
,time_dialog,time_notes,time_end_call
	from #timeAgenteTransfer2 t
	join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0


select dateadd(ss,isnull(-tstatus,0),fecha) dateStartDetail,fecha dateEndDetail,
	case when datepart(mi,dateadd(ss,isnull(-tstatus,0),fecha))
		   between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(-tstatus,0),fecha),121) + '':00:00.000''
		   when datepart(mi,dateadd(ss,isnull(-tstatus,0),fecha))
		   between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(-tstatus,0),fecha),121) + '':15:00.000''
		   when datepart(mi,dateadd(ss,isnull(-tstatus,0),fecha))
		   between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(-tstatus,0),fecha),121) + '':30:00.000''
		   when datepart(mi,dateadd(ss,isnull(-tstatus,0),fecha))
		   between 45 and 59 then convert(varchar(13),dateadd(ss,isnull(-tstatus,0),fecha),121) + '':45:00.000'' end as timegroup,
	case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
	     when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
		 when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
		 when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end as timegroup_next,
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
       --group by user_id,fecha

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


insert into RepMKTAgentes(date,userId,login,agentName,CallsperACDGroupD,tACD,tAgent,oHour,tAux,readyTime,tPer,Ayuda,nxfer,nacw,tACW,year,month,day,hour,minutes)
select convert(varchar(24),acd.timegroup,121) date,acd.user_Id,(isnull(users.login,'''')) [Login],
		(isnull(users.apellidopaterno,'''')+'' ''+isnull(users.apellidomaterno,'''')+'' ''+isnull(users.nombres,'''')) agt_name
		,acd.nacd [CallsperACDGroupD],
		acd.tacd [tACD],
		acd.tresp [tAgent],
		tready.t_otra [oHour],
       tready.t_aux [tAux],
       tready.t_disp [readyTime],
       tready.t_pers [tPer],
       acd.cayuda [Ayuda],
       acd.nxfersal [nxfer],
	   acd.nacw [nacw],
	   acd.tACW [tACW],
datepart(yyyy,convert(varchar(24),acd.timegroup,121)) year,
	datepart(mm, acd.timegroup) month,
	datepart(dd, convert(varchar(24),acd.timegroup,121)) day,
	datepart(hh, convert(varchar(24),acd.timegroup,121)) hour,
	datepart(mi,convert(varchar(24),acd.timegroup,121)) minutes
from (
select acd.timegroup,acd.user_id,sum(nacd) nacd,sum(nacw) nacw,sum(cayuda) cayuda ,sum(nxfersal) nxfersal,sum(tresp) tresp,sum(tacd) tacd,sum(tacw) tacw
	from #timeAgenteTransfer acd group by acd.timegroup,acd.user_id) acd
left join
(select timegroup,user_id,sum(t_otra) t_otra,sum(t_aux) t_aux,sum(t_disp) t_disp,sum(t_pers) t_pers
	from #timeAgenteStatus group by timegroup,user_id) tready on tready.user_id=acd.user_id and tready.timegroup=acd.timegroup

left join ccusers users ON users.user_id=acd.user_id
order by date,Login
drop table #times
drop table #timeAgenteTransfer
drop table #timeAgenteTransfer2
drop table #timeAgenteStatus
drop table #timeAgenteStatus2

END '
	EXEC(@Sql)
	
			/* End script release */

			/* Upgrade database version (use your own script to do it) */
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