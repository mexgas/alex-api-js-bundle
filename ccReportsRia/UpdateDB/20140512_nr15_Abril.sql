/*
Autor: Jesus Gallardo
Fecha: 2014/05/12
Descripcion:
	Se actuliza la descripcion del menu 3060 de efectividad ACD
	Se actuliza el parent del menu AVRS -- Disposition por 8000 al 8050 que es el padre correcto
	Se modifica el SP GetReportMenus para fix de los menus
	Se modifica el SP ccspRepSpececialAbnd para fix en reportey llamadas con chat
	Se modifica el SP ccspRepSpececialAgtPerformance para fix en reporte
	se modifica el SP ccspRepSpececialCamMovs para fix en reporte
	se modifica el SP ccspRepSpececialPromises para fix en reporte
	se modifica el SP ccspRepOutCalls para fix en reporte llamadas con chat
	se modifica el SP ccspRepOutDispositions para fix en reporte llamadas con chat
	se modifica el SP ccspRepOutDispositions para fix en reporte llamadas con chat
	se modifica el SP ccspRepOutSubDispositions para fix en reporte llamadas con chat
	se modifica el SP ccspRepSpecialCallKeyHistory para fix tipo dato
	se modifica el SP ccspRepCallXfer para fix tipo dato
	se modifica el SP ccspRepInAbnd para fix tipo dato
	se modifica el SP ccspRepInAnsw para fix tipo dato
	se modifica el SP ccspRepOutAnswCalls para fix tipo dato
	se modifica el SP ccspRepSpececialAgent para fix tipo dato
	
Version requerida: 14
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '15'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------
		
		
		set @process = 'update -Table ccmenus'
		set @Sql = 'update ccmenus set menu_descrip =''Efectividad|Effectiveness'' where menu_id=3060 and type=3
		update ccmenus set parent=8050 where type = 3 and menu_id= 8080'
		
		EXEC(@Sql)
		
		
		set @process = 'GetReportMenus - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[GetReportMenus]
	@userId int,
	@activeChat tinyint,
	@activeAVRS tinyint
AS
BEGIN
	
	select menu_id,
		substring(menu_descrip, charindex(''|'', menu_descrip) + 1, len(menu_descrip)) as menu_descrip,
		nullif(parent,menu_id) as parent,Nivel,ordengral
		into #tempCCMenus from ccMenus with(nolock) 
		where type = 3 and menu_id >= 2000 and(
			(menu_id not in (3130,3131,3132,3133,3134,3135,3136,8050,8060,8061,8062,8063,8070,8071,8072,8080))
			or  (@activeChat = 1 and menu_id in (3130,3131,3132,3133,3134,3135,3136))
			or  (@activeAVRS = 1 and menu_id in (8050,8060,8061,8062,8063,8070,8071,8072,8080) ))
			order by menu_id
			

	;WITH ccMenusUserRec(Nivel, menu_descrip, menu_id, ordengral, parent)
	AS
	(
		select 
			distinct b.Nivel as Nivel,	
			b.menu_descrip as menu_descrip,
			b.menu_id as menu_id,
			b.ordengral as ordengral,
			b.parent as parent			
			from #tempCCMenus as b
			inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId and b.menu_id<>b.parent
		UNION ALL
	--RECURSIViDAD
		select a.Nivel, a.menu_descrip, a.menu_id, a.ordengral, a.parent
			from #tempCCMenus a inner join ccMenusUserRec b on a.menu_id=b.parent		
	)

	select distinct Nivel,menu_descrip,menu_id,ordengral,parent into #tempCCMenusUser from ccMenusUserRec order by menu_id	
	
	select distinct A.Nivel, A.menu_descrip, A.menu_id, A.ordengral,5 filtersType from #tempCCMenusUser A	
	where  menu_id not in 
		(select distinct parent from  #tempCCMenus where Nivel=''C'' and parent not in (select distinct  A.parent from  #tempCCMenusUser A where A.Nivel=''C''))	
	order by menu_id	
		
	drop table #tempCCMenus
	drop table #tempCCMenusUser

END'
		
		EXEC(@Sql)
		
		set @process = 'ccspRepSpececialAbnd - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbnd]
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

	delete RepSpececialAbnd with(rowlock)
	where [date] between @from and @to
	
	insert RepSpececialAbnd select [date], campaignId, inboundId, [Espec/Camp], total, abandonedCalls, 
	cast(((abandonedCalls*100.0)/total) as decimal(5,2)) abandonedCallsPctg from (
		select convert(varchar(10),cal_inicio,121) [date], 0 campaignId, ci.inbound_id inboundId, 
		''ACD - '' + descripcion [Espec/Camp], count(*) total, 
		COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,''1900-01-01 00:00:00'') = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) abandonedCalls
		from cccallsin ci with(index(IX_ccCallsIn),nolock) left join ccinbound ib on ib.inbound_id=ci.inbound_id 
		where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, ''ACD - '' + descripcion
		union all
		select convert(varchar(10),cal_inicio,121) [date], co.cam_id campaignId, 0 inboundId, 
		''Camp - '' + cam_descripcion [Espec/Camp], count(*) total, 
		COUNT(CASE WHEN(statuscall_id in(11,15,16))THEN cal_id ELSE NULL END) abandonedCalls
		from ccocallsout co with(index(IX_ccoCallsOut_2),nolock) left join cccamps ca on ca.cam_id=co.cam_id 
		where cal_inicio between @from and @to and cal_manual in (0,2) group by convert(varchar(10),cal_inicio,121), co.cam_id, ''Camp - '' + cam_descripcion
    ) abnd
end'

	EXEC(@Sql)

		set @process = 'ccspRepSpececialAgtPerformance - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccspRepSpececialAgtPerformance]
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
	
	delete RepSpececialAgent with(rowlock)
	where [date] between @from and @to

	insert RepSpececialAgtPerformance select [date],rcalls.USER_ID [userId]
	,us.apellidopaterno + '' '' + us.apellidomaterno + '' '' + nombres [user],login [Agent]
	,answer Answered, promises, promisesPctg, dialog avgCallTime, wrapup avgWrapupTime
	from (
	select [date], user_id, SUM(answer) answer, SUM(promises) promises
	,cast(SUM(promises)*100.0/SUM(answer) as decimal(5,2)) promisesPctg
	,sum(dialog)/SUM(answer) dialog, sum(wrapup)/SUM(answer) wrapup
	from (
	select 
	CONVERT(varchar(10),cal_inicio,121) [date], user_id
	,sum(cal_tdialog) dialog, sum(cal_tnotas) wrapup
	,count(case calif_id when @promesa then 1 else null end) promises
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END) answer
	from ccoCallsOut with(index(IX_ccoCallsOut_2),nolock) where cal_inicio between @from and @to and cal_manual in(0,2) and USER_ID>0
	group by CONVERT(varchar(10),cal_inicio,121),user_id
	union all
	select
	CONVERT(varchar(10),cal_inicio,121) [date], user_id
	,sum(cal_tdialog) dialog, sum(cal_tnotas) wrapup
	,count(case calif_id when @promesainb then 1 else null end) promises
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END) answer
	from ccCallsIn with(index(IX_ccCallsIn),nolock) where cal_inicio between @from and @to  and USER_ID>0
	group by CONVERT(varchar(10),cal_inicio,121),user_id) calls group by [date],user_id) rcalls 
	left join ccusers us on us.user_id=rcalls.user_id
end'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepSpececialCamMovs - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccspRepSpececialCamMovs]
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
	LEFT OUTER JOIN ccUsers AS usr ON movs.user_id = usr.user_id
	WHERE movs.fecha BETWEEN @from AND @to
end'
	
	EXEC(@Sql)
	
		set @process = 'ccspRepSpececialPromises - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccspRepSpececialPromises]
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

	DECLARE @data varchar(10), @promesa INT, @promesainb INT
	select @data = isnull(valor,''1|1'') from ccSettings where setting_id = 30
	SELECT @promesainb = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 1
	SELECT @promesa = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 2

	delete RepSpececialPromises with(rowlock)
	where [date] between @from and @to
	
	insert RepSpececialPromises SELECT convert(varchar(10),[date],121) [date], ''systemTranslated_outbound'' [type],
	cout.campaignId campaignId, 0 inboundId,
	camp.cam_descripcion [campACDDescription],
	ISNULL(SUM(CASE cout.dispositionId WHEN @promesa THEN cout.count ELSE 0 END),0) AS promises,
	ISNULL(SUM(cout.count),0) AS total,
	CASE ISNULL(SUM(cout.count),0) WHEN 0 THEN 0 ELSE  
	CONVERT(decimal,ISNULL(SUM(CASE cout.dispositionId WHEN @promesa THEN cout.count ELSE 0 END),0))/ 
	CONVERT(decimal,ISNULL(SUM(cout.count),0)) END AS percentage 
	FROM RepOutDispositions as cout JOIN ccCamps as camp ON camp.cam_id = cout.campaignId 
	WHERE cout.date BETWEEN @from AND @to GROUP BY convert(varchar(10),[date],121), cout.campaignId, camp.cam_descripcion
	union all
	SELECT convert(varchar(10),[date],121) [date], ''systemTranslated_inbound'' [type],
	0 campaignId, cin.inboundId inboundId,
	espe.descripcion [campACDDescription],
	ISNULL(SUM(CASE cin.dispositionId WHEN @promesainb THEN cin.count ELSE 0 END),0) AS promises,
	ISNULL(SUM(cin.count),0) AS TOTAL,
	CASE ISNULL(SUM(cin.count),0) WHEN 0 THEN 0 ELSE
	CONVERT(decimal,ISNULL(SUM(CASE cin.dispositionId WHEN @promesainb THEN cin.count ELSE 0 END),0))/ 
	CONVERT(decimal,ISNULL(SUM(cin.count),0)) END AS percentage
	FROM RepInDispositions as cin JOIN ccInbound as espe ON espe.inbound_id = cin.inboundId
	WHERE cin.date BETWEEN @from AND @to GROUP BY convert(varchar(10),[date],121), cin.inboundId, espe.descripcion
end'
	
	EXEC(@Sql)

		set @process = 'ccspRepAgentKPI - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentKPI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
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
	from ccoCallsOut nolock
	where cal_inicio between @from and @to and cal_manual < 3

	insert into #ccCalls_Temp 
	select cal_id, User_id, statusCall_id, cal_tDialog, convert(varchar(8), cal_Inicio, 112)+'' 00:00'', cal_whoHung, 1 
	from ccCallsIn nolock
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
	from ccUsers
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
	from ccLogAgentesDia_Dialog where fecha_Dialog between @from and @to 
	group by User_id
	) as Trd
	on Snd.User_id = Trd.User_id

	drop table #ccCalls_Temp
end'

	EXEC(@Sql)

	set @process = 'ccspRepOutCalls - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCalls]
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

	 declare @starttime datetime
     declare @number int
     set @starttime = @from
     set @number = 0   

      create table #inboundData(
      row int identity,
      dateStartDetail datetime,
      dateEndDetail datetime,
      timegroup datetime,
      timegroup_next datetime,
      time_endque datetime,
      time_ring datetime,
      time_dialog datetime,
      time_notes datetime,
      time_end_call datetime,
      phone_in varchar(30),
      cal_id int,
      dni_id int,
      Inbound_id int,
      User_id int,
      ntotal int,
      ninitial int,
      nout_hour int,
      nout_service int,
      nabnd int,
      nno_agent int,
      nque int,
      ntimeout int,
      noverflow int,
      nxfer int,
      nxfer_que int,
      nabnd_xfer int,
      nabnd_ring int,
      nno_answer int,
      nabnd_dialog int,
      nanswer int,
      nlost int,
      nmsg int,
      nabnd_tres int,
      nansw_tres int,
      tque_max int,
      tque int,
      txfer int,
      tdialog int,
      tnotes int,
      tring int,
      tresp int,
      nMoh int,
      nWHag int,
      nWHcl int)
     
      create table #outboundData(
      row int identity,
      dateStartDetail datetime,
      dateEndDetail datetime,
      timegroup datetime,
      timegroup_next datetime,
      cam_id int,      
      User_id int,
      ntotal int,
      nno_agent int,
      nxfer int,
      nabnd_xfer int,
      nabnd_ring int,
      nno_answer int,
      nabnd_dialog int,
      nanswer int,
      nlost int,
      tque int,
      txfer int,
      tring int,
      tdialog int,
      tnotes int,
      tresp int,
      nhangup int,
      nMoh int,
      nWHag int,
      nWHcl int,
      time_endque datetime,
      time_ring datetime,
      time_dialog datetime,
      time_notes datetime,
      time_end_call datetime,
      phone_out varchar(30),
      cal_id int,
      cal_puerto int,
      idwg int)
     
     CREATE TABLE #times(
      [ID] INT primary key,
      [Start] DATETIME,
      [Stop] DATETIME
      )
 
      create nonclustered index ix_times on #times(
      [Start] DESC,
      [Stop] DESC
      )
      create nonclustered index ix_times2 on #times([Start] DESC)
 
      while @number <= (datediff(mi,@starttime,@to)/15)
      begin
            insert into #times
            SELECT [Hour] = @number,
            StartTime = DATEADD(mi, @number*15, @starttime),
            EndTime = DATEADD(mi, (@number+1)*15, @StartTime)
 
            set @number = @number +1
      end

	-- Session Time	
	select [user_id], [login], logout, extension
	into #sessionTime
	from(select a.extension, a.user_id, a.fecha as ''login'',
	(select max(Fecha)
	from ccLogLogin b with(nolock)
	where b.user_id = a.user_id and
	b.tipomov = 0 and
	b.fecha >= a.fecha and
	b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
		  from ccLogLogin with(nolock)
		  where user_id = b.user_id and
		  tipomov = 1 and
		  fecha > a.fecha)) as ''logout''
	from ccLogLogin a
	where a.tipomov=1
	and fecha >= @from
	and fecha <= @to) as sessiontime
	order by user_id, login
 
	update s
		set s.logout = (select dateadd(ss,-1,isnull(min(login),getdate())) from #sessionTime where [login]>s.[login] and [user_id] = s.[user_id])
		from #sessionTime s    
		where logout is null

	SELECT TOP 0 * INTO #temp_RepAgentSession FROM #sessionTime

	INSERT INTO #temp_RepAgentSession
	select sessiontime.user_id, sublogin, sublogout, extension
	from(select a.extension, a.user_id, a.fecha as ''subLogout'',
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
	) as ''subLogin''
	from ccLogLogin a
	where a.tipomov=0
	and fecha >= @from
	and fecha <= @to
	) as sessiontime
	left join ccusers u on (sessiontime.user_id = u.user_id)
	where datediff(day,subLogin,subLogout) >= 1
	order by sessiontime.user_id, sublogin

	UPDATE a with (rowlock)
	SET a.logout = b.logout
	FROM #temp_RepAgentSession b
	INNER JOIN #sessionTime a
	on a.user_Id = b.user_Id
	and a.login = b.login
	and a.logout <> b.logout

	DROP TABLE #temp_RepAgentSession

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	SELECT      cal_inicio as dateStartDetail,
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
				between 45 and 59 then  convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas+60),0),cal_inicio) ,121) + '':00:00.000'' end as timegroup_next
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
		  ,case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_Inicio,121) + '':00:00.000''
				 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_Inicio,121) + '':15:00.000''
				when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_Inicio,121) + '':30:00.000''
				when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_Inicio,121) + '':45:00.000'' end as timegroup
		  ,case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':15:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':30:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':45:00.000''
		  when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				between 45 and 59 then  convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas + 60),0),cal_Inicio) ,121) + '':00:00.000'' end as timegroup_next 
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
		
	select DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
		  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end) AS timegroup
		  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
				when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
				when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
				when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end) as timegroup_next
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
		  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end)
		  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
				when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
				when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
				when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end), [User_id]
                  
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
	,[user] = (select login from ccusers where user_id = userid)
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

	EXEC(@Sql)

	set @process = 'ccspRepOutDispositions - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
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
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepOutDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepOutDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to


end'

	EXEC(@Sql)

	set @process = 'ccspRepOutSubDispositions - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutSubDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
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
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepOutSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepOutSubDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'

	EXEC(@Sql)
	
	set @process = 'ccspRepSpecialCallKeyHistory - Alter Procedure'
	set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepSpecialCallKeyHistory]
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
		left join ccTipoCalifOUT cal on cal.calif_id=co.calif_id left join ccUsers us on us.User_id=co.User_id
		where ld.fecha between @from and @to and len(ld.cal_key)>0
end'
	
	EXEC(@Sql)
	
	set @process = 'ccspRepCallXfer - Alter Procedure'
	set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepCallXfer]
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
	
	insert RepCallXfer select convert(varchar(10),fechafin,121) [date],
	clt.cal_id callid, case when tipo = 1 then ''systemTranslated_inbound'' else ''systemTranslated_outbound'' end CallTypes, 
	isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccusers nolock where user_id = 
	(case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') Agent,
	case when modo = 0 then ''systemTranslated_blindXfer'' 
	when modo = 1 then ''systemTranslated_Agent'' 
	when modo = 2 then ''systemTranslated_acd'' 
	when modo = 3 then ''systemTranslated_conference'' 
	when modo = 4 then ''systemTranslated_supXfer'' 
	when modo = 5 then ''systemTranslated_overflow'' end as xfertype,
	case when modo = 0 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
	when modo = 1 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),''systemTranslated_Indefinite'') 
	when modo = 2 then isnull((select descripcion from ccinbound where inbound_id = clt.destino),''systemTranslated_Indefinite'') 
	when modo = 3 then isnull((select nombre from telefonosConferencia where tel = clt.destino),clt.destino) 
	when modo = 4 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
	when modo = 5 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end destination,
	tantesxfer timebeforexfer,
	tdespuesxfer timeafterxfer,
	dateadd(ss,-(tantesxfer + tdespuesxfer),fechafin) startDate,
	fechafin as endDate
	from cclogtransfers clt left join ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=1 left join 
	cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=0
	WHERE fechafin >= @from and fechafin < @to
end'
	
	EXEC(@Sql)
	
	set @process = 'ccspRepInAbnd - Alter Procedure'
	set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInAbnd]
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
		
	declare @number int	
	
	CREATE TABLE #times(
      [ID] INT primary key,
      [Start] DATETIME,
      [Stop] DATETIME
      )
 
      create nonclustered index ix_times on #times(
      [Start] DESC,
      [Stop] DESC
      )
      create nonclustered index ix_times2 on #times([Start] DESC)
 
	select @number = 0
    while @number <= (datediff(mi,@from,@to)/15)
    begin
		insert into #times
		SELECT [Hour] = @number,
		StartTime = DATEADD(mi, @number*15, @from),
		EndTime = DATEADD(mi, (@number+1)*15, @from)
		set @number = @number +1
    end

	SELECT [date], areaId, CAST('''' as varchar(50)) area, 0 workgroupId, CAST('''' as varchar(50)) workgroup, inbound_id, isnull(inbound,'''') inbound, amount, time_max,
		time_tot, LT10, LT20, LT30, LT40, LT50, LT60, LT120, LT180, LT240, LT300, GT300, [year], [month], [day], [hour], [minutes]
	INTO #AbndData
	FROM
	(SELECT timegroup [date]
		, IDArea areaId
		, xCalls.inbound_id, descripcion inbound
		, COUNT(cal_inicio) AS amount
		, MAX(tAbnd) AS time_max
		, SUM(tAbnd) AS time_tot
		, COUNT(CASE WHEN tAbnd < 10  THEN 1 ELSE NULL END) as [LT10]
		, COUNT(CASE WHEN tAbnd BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [LT20]
		, COUNT(CASE WHEN tAbnd BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [LT30]
		, COUNT(CASE WHEN tAbnd BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [LT40]
		, COUNT(CASE WHEN tAbnd BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [LT50]
		, COUNT(CASE WHEN tAbnd BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [LT60]
		, COUNT(CASE WHEN tAbnd BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [LT120]
		, COUNT(CASE WHEN tAbnd BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [LT180]
		, COUNT(CASE WHEN tAbnd BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [LT240]
		, COUNT(CASE WHEN tAbnd BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [LT300]
		, COUNT(CASE WHEN tAbnd >= 300  THEN 1 ELSE NULL END) as [GT300]
		, datepart(yyyy,timegroup) [year], datepart(mm,timegroup) [month], datepart(dd,timegroup) [day]
		, datepart(hh,timegroup) [hour], datepart(mi,timegroup) [minutes]
	 FROM	(
			SELECT start timegroup
				, cal_inicio
				, inbound_id				
				, statuscall_id
				, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,''1900-01-01 00:00:00'') = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
				, (cal_twait + cal_txfer + cal_tring) AS tAbnd
			 FROM ccCallsIn ci with(index(IX_ccCallsIn),nolock)
				JOIN #times th on cal_inicio between Start and [Stop]
				WHERE cal_inicio >= @from AND  cal_inicio < @to
				AND INBOUND_ID > 0
		) xCalls left join ccInbound Ib ON Ib.inbound_id=xCalls.inbound_id 
	WHERE (abnd IS NOT NULL) 
	GROUP BY timegroup, IDArea, xCalls.inbound_id, descripcion) Rep
	
	update #AbndData set
	[workgroupId] = b.idwg
	from #AbndData a, ccInboundAgentes b
	where a.inbound_id = b.inbound_id

	update #AbndData
	set workgroup = wgname, area = areaname
	from #AbndData a, ccriacat_workgroup b, ccriacat_areas c
	where a.[workgroupId] = b.idwg
	and a.areaId = c.idarea

	delete [RepInAbnd] with(rowlock)
	where [date] between @from and @to
	
	insert [RepInAbnd] select * from #AbndData
end'
	
	EXEC(@Sql)
	
	set @process = 'ccspRepInAnsw - Alter Procedure'
	set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInAnsw]
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
		
	declare @number int	
	DECLARE @tresDialog AS smallint
	EXEC @tresDialog = ccspConfigTresDialog
	
	CREATE TABLE #times(
      [ID] INT primary key,
      [Start] DATETIME,
      [Stop] DATETIME
      )
 
      create nonclustered index ix_times on #times(
      [Start] DESC,
      [Stop] DESC
      )
      create nonclustered index ix_times2 on #times([Start] DESC)
 
	select @number = 0
    while @number <= (datediff(mi,@from,@to)/15)
    begin
		insert into #times
		SELECT [Hour] = @number,
		StartTime = DATEADD(mi, @number*15, @from),
		EndTime = DATEADD(mi, (@number+1)*15, @from)
		set @number = @number +1
    end

	SELECT [date], areaId, CAST('''' as varchar(50)) area, 0 workgroupId, CAST('''' as varchar(50)) workgroup, inbound_id, isnull(inbound,'''') inbound, amount, time_max,
		time_tot, LT10, LT20, LT30, LT40, LT50, LT60, LT120, LT180, LT240, LT300, GT300, [year], [month], [day], [hour], [minutes]
	INTO #AnswData
	FROM
	(SELECT timegroup [date]
		, IDArea areaId
		, xCalls.inbound_id, descripcion inbound
		, COUNT(cal_inicio) AS amount
		, MAX(tAnsw) AS time_max
		, SUM(tAnsw) AS time_tot
		, COUNT(CASE WHEN tAnsw < 10  THEN 1 ELSE NULL END) as [LT10]
		, COUNT(CASE WHEN tAnsw BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [LT20]
		, COUNT(CASE WHEN tAnsw BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [LT30]
		, COUNT(CASE WHEN tAnsw BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [LT40]
		, COUNT(CASE WHEN tAnsw BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [LT50]
		, COUNT(CASE WHEN tAnsw BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [LT60]
		, COUNT(CASE WHEN tAnsw BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [LT120]
		, COUNT(CASE WHEN tAnsw BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [LT180]
		, COUNT(CASE WHEN tAnsw BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [LT240]
		, COUNT(CASE WHEN tAnsw BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [LT300]
		, COUNT(CASE WHEN tAnsw >= 300  THEN 1 ELSE NULL END) as [GT300]
		, datepart(yyyy,timegroup) [year], datepart(mm,timegroup) [month], datepart(dd,timegroup) [day]
		, datepart(hh,timegroup) [hour], datepart(mi,timegroup) [minutes]
	 FROM	(
			SELECT start timegroup
				, cal_inicio
				, inbound_id				
				, statuscall_id
				, (CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
				, (cal_twait + cal_txfer + cal_tring) AS tAnsw
			 FROM ccCallsIn ci with(index(IX_ccCallsIn),nolock)
				JOIN #times th on cal_inicio between Start and [Stop]
				WHERE cal_inicio >= @from AND  cal_inicio < @to
				AND INBOUND_ID > 0
		) xCalls left join ccInbound Ib ON Ib.inbound_id=xCalls.inbound_id 
	WHERE (answer IS NOT NULL) 
	GROUP BY timegroup, IDArea, xCalls.inbound_id, descripcion) Rep
	
	update #AnswData set
	[workgroupId] = b.idwg
	from #AnswData a, ccInboundAgentes b
	where a.inbound_id = b.inbound_id

	update #AnswData
	set workgroup = wgname, area = areaname
	from #AnswData a, ccriacat_workgroup b, ccriacat_areas c
	where a.[workgroupId] = b.idwg
	and a.areaId = c.idarea

	delete [RepInAnsw] with(rowlock)
	where [date] between @from and @to
	
	insert [RepInAnsw] select * from #AnswData
end'
	
	EXEC(@Sql)
	
	set @process = 'ccspRepOutAnswCalls - Alter Procedure'
	set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutAnswCalls]
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
		
	delete RepOutAnswCalls with(rowlock)
	where [date] between @from and @to
	
	insert RepOutAnswCalls select [date], campaignId, ca.cam_descripcion campaign, 
	abnd.IDWG workgroupId, e.WGName workgroup, f.IDArea areaId, g.AreaName area, total,
	cast(((nasig_tl*100.0)/total) as decimal(5,2)) asig_tl,
	cast(((nasig_nc*100.0)/total) as decimal(5,2)) asig_nc,
	cast(((nAnswered*100.0)/total) as decimal(5,2)) Answered,
	cast(((nassigned*100.0)/total) as decimal(5,2)) assigned,
	cast(((nabdn_sis*100.0)/total) as decimal(5,2)) abdn_sis
	from (
		select convert(varchar(10),cal_inicio,121) [date], co.cam_id campaignId, min(d.IDWG) idwg, count(*) total, 
		COUNT(CASE WHEN(statusCall_id = 16)THEN co.cal_id ELSE NULL END) nasig_tl,
		COUNT(CASE WHEN(statuscall_id = 15)THEN co.cal_id ELSE NULL END) nasig_nc,
		COUNT(CASE WHEN(statuscall_id = 13)THEN co.cal_id ELSE NULL END) nAnswered,
		COUNT(CASE WHEN(statuscall_id = 11)THEN co.cal_id ELSE NULL END) nassigned,
		COUNT(CASE WHEN(statuscall_id in (6,4))THEN co.cal_id ELSE NULL END) nabdn_sis
		from ccocallsout co with(index(IX_ccoCallsOut_2),nolock) 
		left join ccRIAWorkGroup_Calid d on (d.cal_id = co.cal_id)
		where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121),co.cam_id
    ) abnd left join cccamps ca on ca.cam_id=abnd.campaignId 
    left join ccRIACat_WorkGroup as e on (e.idwg = abnd.idwg)
	left join ccRIAAreaWorkGroup as f on (f.idwg = e.idwg)
	left join ccRIACat_Areas as g on (g.idarea = f.idarea)
end'
	
	EXEC(@Sql)
	
	set @process = 'ccspRepSpececialAgent - Alter Procedure'
	set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAgent]
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
		
	DECLARE @tresRing AS smallint
	DECLARE @tresDialog AS smallint
	EXEC @tresRing=ccspConfigTresRing
	EXEC @tresDialog=ccspConfigTresDialog

	delete RepSpececialAgent with(rowlock) 
	where [date] between @from and @to
	
	insert RepSpececialAgent select ses.date,ses.userId,[user],login
	,[session] sessionTime,loginTime,logoutTime
	,isnull(cout.dialog,0)+isnull(cin.dialog,0)+isnull(cin.wrapup,0)+isnull(cout.wrapup,0) dialogTime 
	,nd.total ndTime
	,ISNULL(cout.ncalls,0) callsOut
	,ISNULL(cin.ncalls,0) callsIn
	,ISNULL(cout.abnd_xfer,0)+ISNULL(cout.abnd_ring,0)+ISNULL(cout.abnd_dialog,0)+ISNULL(cin.abnd_xfer,0)+ISNULL(cin.abnd_ring,0)+ISNULL(cin.abnd_dialog,0) abandonedCalls
	,ISNULL(cout.answer,0)+ISNULL(cin.answer,0) nanswer2
	,ISNULL(cout.nocalif,0)+ISNULL(cin.nocalif,0) unrated
	from 
	(select convert(varchar(10),[date],121) [date], login, userid, [user], 
	sum(sessionTimeSeconds) [session], 
	min(logintime) loginTime, max(logouttime) logoutTime
	from RepAgentsession where [date] between @from and @to group by convert(varchar(10),[date],121), login, userId, [user]) ses left join 
	(select convert(varchar(10),[date],121) [date], userId,SUM(timeseconds) total from RepAgentNotReady
	where [date] between @from and @to group by convert(varchar(10),[date],121), userId) nd on nd.date=ses.date and nd.userId=ses.userId left join 
	(select 
	CONVERT(varchar(10),cal_inicio,121) [date], USER_ID
	,SUM(cal_tdialog) dialog, SUM(cal_tnotas) wrapup
	,COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END)AS ncalls
	,COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END)AS abnd_xfer
	,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END)AS abnd_ring
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END)AS abnd_dialog
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END)AS answer
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog)AND ISNULL(calif_id,0)=0) THEN cal_id ELSE NULL END)AS nocalif
	from ccoCallsOut with(index(IX_ccoCallsOut_2),nolock) where cal_inicio between @from and @to and cal_manual in(0,2)
	group by CONVERT(varchar(10),cal_inicio,121),USER_ID) cout on cout.date=ses.date and cout.User_id = ses.userId left join 
	(select
	CONVERT(varchar(10),cal_inicio,121) [date], USER_ID
	,SUM(cal_tdialog) dialog, SUM(cal_tnotas) wrapup
	,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND (isnull(cal_xfer,''1900-01-01 00:00:00'') <> ''1900-01-01 00:00:00'')))THEN 1 ELSE NULL END)AS ncalls
	,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer
	,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog)AND ISNULL(calif_id,0)=0) THEN cal_id ELSE NULL END)AS nocalif
	from ccCallsIn with(index(IX_ccCallsIn),nolock) where cal_inicio between @from and @to
	group by CONVERT(varchar(10),cal_inicio,121),USER_ID) cin on cin.date = ses.date and cin.User_id=ses.userId
end'
	
	EXEC(@Sql)
	
------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
