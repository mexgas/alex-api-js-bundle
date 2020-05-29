/*
Autor: Raymundo Gonzalez
Fecha: 2013/12/31
Descripcion:
	Se crea la tabla RepSpecialCallKeyHistory para nuevo reporte de M&A
	Se crea la tabla ReportsFiltersText para nuevo reporte de M&A
	Se crean los indices IX_RepSpecialCallKeyHistory y IX_RepSpecialCallKeyHistory2 en la tabla RepSpecialCallKeyHistory
	Se agrega la columna tnotavg a la tabla RepAgentGI
	Se agrega la columna tabndtot a la tala RepInEffectiveness
	Se agrega la columna cal_Key a la tabla ccoLogDials
	Se insertan registros en las tablas filtersmenus, ReportsFiltersMenus, ReportsFilters, TranslatedReports, ReportsTotals, ReportsFiltersText para nuevo reporte de M&A
	Se actualiza la tabla GroupByReports para considerar la columna tnotavg del reporte de informaciÃ³n general
	Se actualiza la tabla ReportsTotals para considerar la columna tnotavg del reporte de informaciÃ³n general y la columna tabndtot del reporte de efectividad
	Se crea el SP ccspRepSpecialCallKeyHistory para nuevo reporte de M&A
	Se modifica el SP ccspRepAgentGI para agregar columna de tiempo de abandono
	Se modifica el SP ccspRepInEffectiveness agregar columna de tiempo de abandono
	Se modifica el SP GetReportMenus para corregir fix en menu de reportes
	Se modifica el SP GetReportFilters para nuevo reporte de M&A
	Se crea el Job ccspRepSpecialCallKeyHistory para nuevo reporte de M&A
	
Version requerida: 10
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '11'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @process = 'RepSpecialCallKeyHistory - Create Table'
		set @Sql='CREATE TABLE [dbo].[RepSpecialCallKeyHistory](
[date] [datetime] NOT NULL,
[campaignId] [int] NOT NULL,
[campaign] [varchar](255) NOT NULL,
[callKey] [varchar](20) NOT NULL,
[telephone] [varchar](30) NOT NULL,
[dialResult] [varchar](255) NOT NULL,
disposition [varchar](255) NOT NULL,
dialogTime int not null,
CallBacks [varchar](255) NOT NULL,
[login] [varchar](255) NOT NULL,
[user] [varchar](255) NOT NULL,
) ON [PRIMARY]'

	EXEC(@Sql)
	
		set @process = 'ReportsFiltersText - Create Table'
		set @Sql='CREATE TABLE [dbo].[ReportsFiltersText](
	[reportName] [nvarchar](100) NOT NULL,
	[restrictExp] [varchar] (100) not null,
	[dbColumn] [nvarchar] (100) not null,
	[id] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC,
	[restrictExp] ASC,
	[dbColumn] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]'

	EXEC(@Sql)
	
		set @process = 'RepSpecialCallKeyHistory - Create Index'
		set @Sql = 'CREATE NONCLUSTERED INDEX [IX_RepSpecialCallKeyHistory] ON [dbo].[RepSpecialCallKeyHistory] 
(
	[date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_RepSpecialCallKeyHistory2] ON [dbo].[RepSpecialCallKeyHistory] 
(
	[callKey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]'

	EXEC(@Sql)

		set @process = 'RepAgentGI - Alter Table'
		set @Sql='ALTER TABLE RepAgentGI 
ADD tnotavg int'

	EXEC(@Sql)
	
		set @process = 'RepInEffectiveness - Alter Table'
		set @Sql='ALTER TABLE RepInEffectiveness 
ADD tabndtot int'

	EXEC(@Sql)

		set @process = 'ccoLogDials - Alter Table'
		set @Sql = 'if not exists(select * from sys.columns where Name = N''cal_Key'' and Object_ID = Object_ID(N''ccoLogDials''))
begin
    alter table ccoLogDials
    add cal_Key [varchar](20) NOT NULL DEFAULT ''''
end'
		
	EXEC(@Sql)
	
		set @process = 'filtersmenus - Insert'
		set @Sql='insert filtersmenus values (''text'')'
		
	EXEC(@Sql)
	
		set @process = 'ReportsFiltersMenus - Insert'
		set @Sql='insert ReportsFiltersMenus values (7060,''date'')
insert ReportsFiltersMenus values (7060,''filterby'')
insert ReportsFiltersMenus values (7060,''text'')'

	EXEC(@Sql)

		set @process = 'ReportsFilters - Insert'
		set @Sql='insert ReportsFilters values (''Account history'',''campaigns'',7060)'
		
	EXEC(@Sql)
	
		set @process = 'TranslatedReports - Insert'
		set @Sql='insert into [TranslatedReports] values (7060, ''campaign|dialResult|disposition|CallBacks|login|user'')'
		
	EXEC(@Sql)
	
		set @process = 'ReportsTotals - Insert'
		set @Sql='insert into ReportsTotals values (7060,'''')'
		
	EXEC(@Sql)
	
		set @process = 'ReportsFiltersText - Insert'
		set @Sql='insert ReportsFiltersText values(''Account history'',''A-Z a-z0-9 _\-'',''callKey'',7060)'
		
	EXEC(@Sql)
	
		set @process = 'GroupByReports - Alter Table'
		set @Sql='update GroupByReports 
set columns=''userId|max([user]):user|max([login]):login|sum([nxferin]):nxferin|sum([nanswerin]):nanswerin|sum([nabndxferin]):nabndxferin|sum([nabndringin]):nabndringin|sum([nabnddlgin]):nabnddlgin|sum([abndaxferin]):abndaxferin|sum([nnoanswerin]):nnoanswerin|sum([nlostin]):nlostin|sum([tdialogin]):tdialogin|sum([tnotesin]):tnotesin|sum([tringin]):tringin|sum([txferin]):txferin|sum([nxferout]):nxferout|sum([nanswerout]):nanswerout|sum([nabndxferout]):nabndxferout|sum([nabndringout]):nabndringout|sum([nabnddlgout]):nabnddlgout|sum([abndaxferout]):abndaxferout|sum([nnoanswerout]):nnoanswerout|sum([nlostout]):nlostout|sum([tdialogout]):tdialogout|sum([tnotesout]):tnotesout|sum([tringout]):tringout|sum([txferout]):txferout|sum([nother]):nother|sum([tunknown]):tunknown|sum([tnotav]):tnotav|sum([tlog]):tlog|sum([treq]):treq|sum([tav]):tav|sum([tother]):tother|sum([tprob]):tprob|sum([nmohin]):nmohin|sum([nmohout]):nmohout|sum([nwhagin]):nwhagin|sum([nwhagout]):nwhagout|sum([nwhcliin]):nwhcliin|sum([nwhcliout]):nwhcliout|isnull(sum([tnotavg])/nullif(sum([nanswerin]+[nanswerout]),0),0):tnotavg'' 
where id = 2010'

	EXEC(@Sql)
	
		set @process = 'ReportsTotals - Alter Table'
		set @Sql='update ReportsTotals 
set totalColumns=''sum:nxferin|sum:nanswerin|sum:nabndxferin|sum:nabndringin|sum:nabnddlgin|sum:abndaxferin|sum:nnoanswerin|sum:nlostin|sum:tdialogin|sum:tnotesin|sum:tringin|sum:txferin|sum:nxferout|sum:nanswerout|sum:nabndxferout|sum:nabndringout|sum:nabnddlgout|sum:abndaxferout|sum:nnoanswerout|sum:nlostout|sum:tdialogout|sum:tnotesout|sum:tringout|sum:txferout|sum:nother|sum:tunknown|sum:tnotav|sum:tlog|sum:treq|sum:tav|sum:tother|sum:tprob|sum:nmohin|sum:nmohout|sum:nwhagin|sum:nwhagout|sum:nwhcliin|sum:nwhcliout|special:tnotavg:isnull(sum([tnotavg])/nullif(sum([nanswerin]+[nanswerout]),0),0)''
where id = 2010

update ReportsTotals 
set totalColumns=''sum:ntotalin|sum:nanswer2|sum:nabnd|special:tatencion:isnull(sum(tatencion*nanswer2)/nullif(sum(nanswer2),0),0)|special:tqueavg:ISNULL(sum(tQuetot)/ NULLIF(sum(nQuetot), 0), 0)|sum:tQuetot|sum:nQuetot|special:avgAbandonTime:isnull(sum(tabndtot) / NULLIF(sum(nabnd),0),0)|sum:tresp|avg:poscount|special:Porcentaje:ISNULL(SUM(SLP1) * 100/ NULLIF(SUM(SLP2)_ 0)_ 0)|special:avgAbandon:convert(decimal(10,2),(sum(nabnd)/nullif(convert(decimal(10,2),sum(ntotalin)),0))*100)''
where id = 3060'

	EXEC(@Sql)

		set @process = 'ccspRepSpecialCallKeyHistory - Create Procedure'
		set @Sql='CREATE PROCEDURE ccspRepSpecialCallKeyHistory
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
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
		left join ccoCallsOut co on co.cal_id = ld.cal_id
		left join ccTipoResultadoDial rd on rd.tipoResDial_id = ld.tipoResDial_id left join ccCamps ca on ca.cam_id = ld.cam_id
		left join ccTipoCalifOUT cal on cal.calif_id=co.calif_id left join ccUsers us on us.User_id=co.User_id
		where ld.fecha between @from and @to
end'

	EXEC(@Sql)

		set @process = 'ccspRepAgentGI - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccspRepAgentGI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
 
SET ANSI_WARNINGS off

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()
 
DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint
 
EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn
 
if @action = 1
begin
 
      declare @starttime datetime
      declare @number int
      set @starttime = @from
      set @number = 0     
      create table #notReady(
            [Row] int identity,
            dateStartDetail datetime,
            dateEndDetail     datetime,
            timegroup   datetime,
            timegroup_next    datetime,
            User_id     int,
            timeNotReady int
      )
     
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
      cal_puerto int)
     
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
	         
	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto)
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
		  group by cal_id,[User_id],cam_id,cal_Inicio,cal_puerto

	delete from #outboundData WHERE timegroup>=@from AND timegroup<@to
		  AND ntotal=0 AND nno_agent=0 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		  AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		  AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0       
               
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

	insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,timeNotReady)
	SELECT DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
			  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
					when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
					when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
					when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end) AS timegroup
			  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
					when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
					when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
					when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end) as timegroup_next
					,[User_id],SUM(tStatus) as [timeNotReady]                
			  FROM ccLogAgentesNotReady
			  WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to     
		GROUP BY
			  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
					when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
					when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
					when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end)
			  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
					when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
					when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
					when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end), [User_id]
	               
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
	   
	drop table #notReady2
	               

	select
		ROW_NUMBER() OVER(ORDER BY  CASE WHEN #agentInformation.timegroup IS NOT NULL THEN #agentInformation.timegroup
					WHEN calls.timegroup IS NOT NULL  THEN calls.timegroup ELSE 0 END,CASE WHEN #agentInformation.user_id IS NOT NULL THEN #agentInformation.user_id
					WHEN calls.userId IS NOT NULL THEN calls.userId ELSE - 1 END) AS id
		,dbo.#agentInformation.row as rowAgentInformation
		,isnull(dbo.#notReady.Row,-1) as rowNotReady        
		,rowIn,rowOut,
		calLIdIn,phoneIn,dateStartDetailIn,callIdOut,phoneOut,dateStartDetailOut,                          
		CASE WHEN #agentInformation.timegroup IS NOT NULL THEN #agentInformation.timegroup
			  WHEN calls.timegroup IS NOT NULL  THEN calls.timegroup ELSE 0 END AS date
		,CASE WHEN #agentInformation.user_id IS NOT NULL THEN #agentInformation.user_id
				WHEN calls.userId IS NOT NULL THEN calls.userId ELSE - 1 END AS [userId]
		,u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + nombres as [user] , u.login as [login]
		,isnull(nxfer_in,0) as nxferin, isnull(nanswer_in,0) as nanswerin, isnull(nabnd_xfer_in,0) as nabndxferin
		,isnull(nabnd_ring_in,0) as nabndringin,isnull(nabnd_dlg_in,0) as nabnddlgin,isnull(abnd_a_xfer_in,0) as abndaxferin
		,isnull(nno_answer_in,0) as nnoanswerin,isnull(nlost_in,0) as nlostin,isnull(tdialog_in,0) as tdialogin
		,isnull(tnotes_in,0) as tnotesin,isnull(tring_in,0) as tringin,isnull(txfer_in,0) as txferin
		,isnull(nxfer_out,0) as nxferout,isnull(nanswer_out,0) as nanswerout,isnull(nabnd_xfer_out,0) as nabndxferout
		,isnull(nabnd_ring_out,0) as nabndringout,isnull(nabnd_dlg_out,0) as nabnddlgout,isnull(abnd_a_xfer_out,0) as abndaxferout
		,isnull(nno_answer_out,0) as nnoanswerout,isnull(nlost_out,0) as nlostout,isnull(tdialog_out,0) as tdialogout
		,isnull(tnotes_out,0) as tnotesout,isnull(tring_out,0) as tringout, isnull(txfer_out,0) as txferout
	   
		,ISNULL(dbo.#agentInformation.nother, 0) AS nother, ISNULL(dbo.#agentInformation.tunknown, 0) AS tunknown
		,ISNULL(dbo.#agentInformation.tnot_av, 0) AS tnotav
		,ISNULL(dbo.#agentInformation.t1, 0)+ISNULL(dbo.#agentInformation.t2, 0)+ISNULL(dbo.#agentInformation.t3, 0)+ISNULL(dbo.#agentInformation.t4, 0)  AS tlog
		,ISNULL(dbo.#notReady.timeNotReady, 0) AS treq
		,ISNULL(dbo.#agentInformation.tav, 0) AS tav, ISNULL(dbo.#agentInformation.tother, 0) AS tother
		,ISNULL(dbo.#agentInformation.tprob, 0) AS tprob
	   
		,isnull(nMoh_in,0) as nMohin,isnull(nMoh_out,0) as nMohout,isnull(nWHag_in,0) as nWHagin
		,isnull(nWHag_out,0) as nWHagout,isnull(nWHcl_in,0) as nWHcliin,isnull(nWHcl_out,0) as nWHcliout
		, CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(yy,#agentInformation.timegroup)
					WHEN calls.timegroup IS NOT NULL THEN datepart(yy,calls.timegroup) ELSE 0 END AS [year]
		  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(mm,#agentInformation.timegroup)
					WHEN calls.timegroup IS NOT NULL THEN datepart(mm,calls.timegroup) ELSE 0 END AS [month]
		  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(dd,#agentInformation.timegroup)
					WHEN calls.timegroup IS NOT NULL THEN datepart(dd,calls.timegroup) ELSE 0 END AS [day]
		  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(hh,#agentInformation.timegroup)
					WHEN calls.timegroup IS NOT NULL THEN datepart(hh,calls.timegroup) ELSE 0 END AS [hour]
		  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(mi,#agentInformation.timegroup)
					WHEN calls.timegroup IS NOT NULL THEN datepart(mi,calls.timegroup) ELSE 0 END AS [minutes]
	into #tempRepAgentGI
	FROM  dbo.#agentInformation
	LEFT OUTER JOIN dbo.ccusers u ON (#agentInformation.[user_id] = u.[user_id])
	LEFT OUTER JOIN dbo.#notReady ON #agentInformation.[user_id] = dbo.#notReady.[user_id] AND dbo.#notReady.timegroup = dbo.#agentInformation.timegroup
	right join
		(
	   
		select
			  CASE WHEN #inboundData.timegroup IS NOT NULL THEN #inboundData.timegroup
						 WHEN #outboundData.timegroup IS NOT NULL THEN #outboundData.timegroup ELSE NULL END timegroup,
			  CASE WHEN #inboundData.[user_id] IS NOT NULL THEN #inboundData.[user_id]
					  WHEN #outboundData.[user_id] IS NOT NULL THEN #outboundData.[user_id] ELSE NULL END as [userId]
			  ,ISNULL(dbo.#inboundData.row, -1) as rowIn,ISNULL(dbo.#outboundData.row, -1) as rowOut
			  ,ISNULL((dbo.#inboundData.nxfer), 0) AS nxfer_in, ISNULL((dbo.#inboundData.nanswer), 0) AS nanswer_in, ISNULL((dbo.#inboundData.nabnd_xfer), 0) AS nabnd_xfer_in
			  ,ISNULL((dbo.#inboundData.nabnd_ring), 0) AS nabnd_ring_in, ISNULL((dbo.#inboundData.nabnd_dialog), 0) AS nabnd_dlg_in
			  ,ISNULL((dbo.#inboundData.nabnd_xfer), 0) + ISNULL((dbo.#inboundData.nabnd_ring), 0) + ISNULL((dbo.#inboundData.nabnd_dialog), 0) AS abnd_a_xfer_in
			  ,ISNULL((dbo.#inboundData.nno_answer), 0) AS nno_answer_in, ISNULL((dbo.#inboundData.nlost), 0) AS nlost_in, ISNULL((dbo.#inboundData.tdialog), 0) AS tdialog_in
			  ,ISNULL((dbo.#inboundData.tnotes), 0) AS tnotes_in, ISNULL((dbo.#inboundData.tring), 0) AS tring_in, ISNULL((dbo.#inboundData.txfer), 0) AS txfer_in
			  ,ISNULL((dbo.#inboundData.nMoh), 0) AS nMoh_in, ISNULL((dbo.#inboundData.nWHag), 0) AS nWHag_in,ISNULL((dbo.#inboundData.nWHcl), 0) AS nWHcl_in               
			  ,ISNULL((dbo.#outboundData.nxfer), 0) AS nxfer_out, ISNULL((dbo.#outboundData.nanswer), 0) AS nanswer_out, ISNULL((dbo.#outboundData.nabnd_xfer), 0) AS nabnd_xfer_out
			  ,ISNULL((dbo.#outboundData.nabnd_ring), 0) AS nabnd_ring_out, ISNULL((dbo.#outboundData.nabnd_dialog), 0) AS nabnd_dlg_out
			  ,ISNULL((dbo.#outboundData.nabnd_xfer), 0) + ISNULL((dbo.#outboundData.nabnd_ring), 0) + ISNULL((dbo.#outboundData.nabnd_dialog), 0) AS abnd_a_xfer_out
			  ,ISNULL((dbo.#outboundData.nno_answer), 0) AS nno_answer_out, ISNULL((dbo.#outboundData.nlost), 0) AS nlost_out, ISNULL((dbo.#outboundData.tdialog), 0) AS tdialog_out
			  ,ISNULL((dbo.#outboundData.tnotes), 0) AS tnotes_out, ISNULL((dbo.#outboundData.tring), 0) AS tring_out, ISNULL((dbo.#outboundData.txfer), 0) AS txfer_out
			  ,ISNULL((dbo.#outboundData.nMoh), 0) AS nMoh_out, ISNULL((dbo.#outboundData.nWHag), 0) AS nWHag_out,ISNULL((dbo.#outboundData.nWHcl), 0) AS nWHcl_out
			  ,isnull((dbo.#inboundData.cal_id),'''') as callIdIn,isnull((dbo.#inboundData.phone_in),'''') as phoneIn,isnull((dbo.#inboundData.dateStartDetail),'''') as dateStartDetailIn
			  ,isnull((dbo.#outboundData.cal_id),'''') as callIdOut,isnull((dbo.#outboundData.phone_out),'''') as phoneOut,isnull((dbo.#outboundData.dateStartDetail),'''') as dateStartDetailOut
		from #inboundData
		FULL OUTER JOIN #outboundData ON(#inboundData.timegroup=#outboundData.timegroup AND #inboundData.[user_id]=#outboundData.[user_id])       
		)calls on calls.timegroup = #agentInformation.timegroup and #agentInformation.[user_id]=calls.[userid]    
		where #agentInformation.timegroup is not null
     
     
      SELECT 
      RANK() OVER(PARTITION BY rowAgentInformation ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      into #tempTime
      FROM #tempRepAgentGI
      where rowAgentInformation in
            (select rowAgentInformation from #tempRepAgentGI temp GROUP BY temp.rowAgentInformation HAVING Count(*) > 1 )
           
      update t
            set nother=0,tunknown=0,tnotav=0,tlog=0,tother=0,tprob=0,tav=0
            from #tempRepAgentGI t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1
     
      delete #tempTime
     
      insert into #tempTime
      SELECT 
      RANK() OVER(PARTITION BY rowNotReady ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      FROM #tempRepAgentGI
      where rowNotReady in
            (select rowNotReady from #tempRepAgentGI temp GROUP BY temp.rowNotReady HAVING Count(*) > 1 )   
                 
      update t
            set treq=0
            from #tempRepAgentGI t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1
     
      delete #tempTime
     
      insert into #tempTime
      SELECT 
      RANK() OVER(PARTITION BY rowIn ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
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
     
      delete from RepAgentGI with(rowlock)
	  where date >= @from AND date < @to
           
      insert into RepAgentGI(date,userId,[user],login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,treq,tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotavg)
      select
            date,userId,[user],login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,treq,tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotav
      from #tempRepAgentGI           
       
      drop table #times
      drop table #sessionTime
      drop table #inboundData
      drop table #outboundData
      drop table #agentInformation
      drop table #notReady
      drop table #tempTime
      drop table #tempRepAgentGI        
     
end'

	EXEC(@Sql)

		set @process = 'ccspRepInEffectiveness - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccspRepInEffectiveness]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

set nocount on
set ansi_nulls off 
set ANSI_WARNINGS off

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

if @action = 1
begin
CREATE TABLE [dbo].[#ccGenInCall](
[timegroup] [smalldatetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[dni_id] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL,
[ntotal] [smallint] NOT NULL,
[ninitial] [smallint] NOT NULL,
[nout_hour] [smallint] NOT NULL,
[nout_service] [smallint] NOT NULL,
[nabnd] [smallint] NOT NULL,
[nno_agent] [smallint] NOT NULL,
[nque] [smallint] NOT NULL,
[ntimeout] [smallint] NOT NULL,
[noverflow] [smallint] NOT NULL,
[nxfer] [smallint] NOT NULL,
[nxfer_que] [smallint] NOT NULL,
[nabnd_xfer] [smallint] NOT NULL,
[nabnd_ring] [smallint] NOT NULL,
[nno_answer] [smallint] NOT NULL,
[nabnd_dialog] [smallint] NOT NULL,
[nanswer] [smallint] NOT NULL,
[nlost] [smallint] NOT NULL,
[nmsg] [smallint] NOT NULL,
[nabnd_tres] [smallint] NOT NULL,
[nansw_tres] [smallint] NOT NULL,
[tque_max] [smallint] NOT NULL,
[tque] [int] NOT NULL,
[txfer] [int] NOT NULL,
[tdialog] [int] NOT NULL,
[tnotes] [int] NOT NULL,
[tring] [int] NOT NULL,
[tresp] [int] NOT NULL,
[nMoh] [smallint] NOT NULL DEFAULT ((0)),
[nWHag] [smallint] NOT NULL DEFAULT ((0)),
[nWHcl] [smallint] NOT NULL DEFAULT ((0))
) ON [PRIMARY]

CREATE TABLE [dbo].[#ccGenSession](
[user_id] [smallint] NOT NULL,
[login] [datetime] NOT NULL,
[logout] [datetime] NOT NULL,
[extension] [varchar](7) NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[#agents](
[timegroup] [smalldatetime] NOT NULL,
[user_id] [smallint] NOT NULL,
[tlog] [int] NOT NULL DEFAULT (0),
[treq] [int] NOT NULL DEFAULT (0),
[tnot_av] [int] NOT NULL,
[tav] [int] NOT NULL DEFAULT (0),
[tprob] [int] NOT NULL DEFAULT (0),
[tunknown] [int] NOT NULL DEFAULT (0),
[tother] [int] NOT NULL DEFAULT (0),
[nother] [int] NOT NULL DEFAULT (0),
[nMoh] [int] NOT NULL DEFAULT ((0)),
[nWHag] [int] NOT NULL DEFAULT ((0)),
[nWHcl] [int] NOT NULL DEFAULT ((0))
) ON [PRIMARY]		

CREATE TABLE [dbo].[#ccGenInSpec](
[timegroup] [smalldatetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[pos_tot] [smallint] NOT NULL,
[pos_time] [int] NOT NULL,
[pos_efect] [smallint] NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[#ccGenInAbnd](
[timegroup] [smalldatetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[amount] [smallint] NOT NULL,
[time_max] [smallint] NOT NULL,
[time_tot] [bigint] NOT NULL,
[<10] [smallint] NOT NULL,
[<20] [smallint] NOT NULL,
[<30] [smallint] NOT NULL,
[<40] [smallint] NOT NULL,
[<50] [smallint] NOT NULL,
[<60] [smallint] NOT NULL,
[<120] [smallint] NOT NULL,
[<180] [smallint] NOT NULL,
[<240] [smallint] NOT NULL,
[<300] [smallint] NOT NULL,
[+300] [smallint] NOT NULL
) ON [PRIMARY]

INSERT INTO #ccGenInCall(timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque
,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg
,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
SELECT timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,dni_id,[user_id]
,COUNT(cal_id)AS ntotal
,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour 
,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(isnull(cal_xfer,'''') = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd 
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
GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,dni_id,[user_id])xDetailCount
right JOIN(SELECT timegroup,inbound_id,dni_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
FROM(SELECT timegroup,inbound_id,dni_id,[user_id]
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
SELECT timegroup_next,inbound_id,dni_id,[user_id]
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
GROUP BY timegroup,inbound_id,dni_id,[user_id])xDetailTime
ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id=xDetailCount.dni_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
WHERE timegroup>=@from AND timegroup<@to
AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
ORDER BY timegroup,inbound_id,dni_id,[user_id]

INSERT INTO #ccGenSession ([user_id], extension, login, logout)
SELECT uid, max(ext) ext, login, max(logout) logout
FROM 
(SELECT uid, ext, login, ISNULL(logout, (SELECT MIN(fecha) FROM ccLogLogin /*with (nolock, index(ccLogLogin_fecha))*/
WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout 
FROM
	(SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout
	FROM 
		(SELECT uid, ext, MAX(login) as login, logout
		FROM
			(SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha) 
			FROM ccLogLogin subLogin /*with (nolock, index(ccLogLogin_fecha))*/ WHERE subLogin.tipomov = 0 
			AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout] 
			FROM ccLogLogin Login /*with (nolock, index(ccLogLogin_fecha))*/
			WHERE login.fecha >= dateadd(dd, -5, @from) and tipomov = 1
			GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail 
		WHERE logout IS NOT NULL GROUP BY uid, ext, logout) Login 
	RIGHT OUTER JOIN ccLogLogin  /*with (nolock, index(ccLogLogin_fecha))*/
	ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login AND ccLogLogin.extension = Login.ext)
	WHERE tipomov = 1
	and ccLogLogin.fecha >= dateadd( dd, -5, @from)) Det 
) LoginDetail 
WHERE logout IS NOT NULL
AND login >= @from and login < @to
GROUP BY uid, login

INSERT INTO #agents(timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl)
SELECT timegroup,[user_id],tlog,tnot_av
,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav
,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob
,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown
,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother
,nother,nMoh,nWHag,nWHcl
FROM(
	SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
		,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl
	 FROM(
		SELECT 
			xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
			,ISNULL(SUM(#ccGenInCall.txfer),0) as txfer
			,ISNULL(SUM(#ccGenInCall.tdialog),0) as tdialog
			,ISNULL(SUM(#ccGenInCall.tnotes),0) as tnotes
			,ISNULL(SUM(#ccGenInCall.tring),0) as tring
			,ISNULL(SUM(#ccGenInCall.nMoh),0) as nMoh
			,ISNULL(SUM(#ccGenInCall.nWHag),0) as nWHag
			,ISNULL(SUM(#ccGenInCall.nWHcl),0) as nWHcl

			,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t1
			,ISNULL((SELECT top 1 3600
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t2
			,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t3
			,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t4

		 FROM(
				SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup
					,ccLogAgentesDia.[user_id]
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother
					,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
				 FROM ccLogAgentesDia
				 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
			)xTimeDetail
				LEFT OUTER JOIN #ccGenInCall ON(xTimeDetail.timegroup=#ccGenInCall.timegroup AND xTimeDetail.[user_id]=#ccGenInCall.[user_id])
			GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		)xDetail
)xAllTimes
WHERE tlog>0
ORDER BY timegroup,[user_id]

INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
SELECT timegroup, ccInboundAgentes.inbound_id
	, COUNT(DISTINCT #agents.[user_id]) AS pos_max -- pos_tot
	, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
 FROM #agents
	INNER JOIN ccInboundAgentes ON (#agents.[user_id] = ccInboundAgentes.[user_id])
 WHERE timegroup >= @from AND timegroup < @to  AND INBOUND_ID > 0
 GROUP BY timegroup, ccInboundAgentes.inbound_id

insert into #ccGenInAbnd (timegroup, inbound_id, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])
SELECT timegroup
, inbound_id
, COUNT(cal_inicio) AS amount
, MAX(tAbnd) AS time_max
, SUM(tAbnd) AS time_tot
, COUNT(CASE WHEN tAbnd < 10  THEN 1 ELSE NULL END) as [<10]
, COUNT(CASE WHEN tAbnd BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [<20]
, COUNT(CASE WHEN tAbnd BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [<30]
, COUNT(CASE WHEN tAbnd BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [<40]
, COUNT(CASE WHEN tAbnd BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [<50]
, COUNT(CASE WHEN tAbnd BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [<60]
, COUNT(CASE WHEN tAbnd BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [<120]
, COUNT(CASE WHEN tAbnd BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [<180]
, COUNT(CASE WHEN tAbnd BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [<240]
, COUNT(CASE WHEN tAbnd BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [<300]
, COUNT(CASE WHEN tAbnd >= 300  THEN 1 ELSE NULL END) as [+300]
FROM	(
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, cal_inicio
	, inbound_id
	, statuscall_id
	, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,'''') = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
	, (cal_twait + cal_txfer + cal_tring) AS tAbnd
 FROM ccCallsIn
	WHERE cal_inicio >= @from AND  cal_inicio < @to
	AND INBOUND_ID > 0
) xCalls
WHERE (abnd IS NOT NULL) 
GROUP BY timegroup, inbound_id

--Borrar lo que esta para no repetir
delete from RepInEffectiveness with(rowlock)
where date >= @from AND date < @to

insert into RepInEffectiveness
SELECT timegroup as date, xDetail.inbound_id, isnull(descripcion, ''systemTranslated_NoACDGroup'') descripcion , ntotal, nanswer, nabnd , isnull(tatention / nullif(nanswer,0),0), 
tque_avg as tqueavg, tQue_tot as tQuetot, nQue_tot as nQuetot, isnull(tabnd_tot / NULLIF(nabnd,0),0) as avgAbandonTime, SL_P_1 as SLP1, SL_P_2 as SLP2, tresp, 
/*pos_tot as postot,*/ pos_count as poscount, ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0)  as Porcentaje
, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes] 
, convert(decimal(10,2),(nabnd/nullif(convert(decimal(10,2),ntotal),0))*100) as [avgAbandon]
, tabnd_tot as tabndtot
FROM ( 

SELECT ISNULL(xDetCall.timegroup, ISNULL(xDetSpec.timegroup, xDetAbnd.timegroup)) timegroup, ISNULL(xDetCall.inbound_id, 
ISNULL(xDetSpec.inbound_id, xDetAbnd.inbound_id)) inbound_id, ISNULL(ntotal, 0) ntotal, ISNULL(nanswer, 0) nanswer, ISNULL(nabnd, 0) nabnd, 
ISNULL(tatention, 0) tatention, ISNULL(tque_avg, 0) tque_avg, isnull(tQue_tot, 0) tQue_tot, isnull(nQue_tot, 0) nQue_tot, ISNULL(tabnd_tot, 0) tabnd_tot, 
ISNULL(SL_P_1, 0) SL_P_1, ISNULL(SL_P_2, 0) SL_P_2, ISNULL(tresp, 0) tresp, ISNULL(pos_tot, 0) pos_tot, ISNULL(pos_count, 0) pos_count

FROM (

SELECT timegroup, inbound_id, SUM(ntotal) AS ntotal, SUM(nanswer) AS nanswer, SUM(nabnd) AS nabnd, SUM(tdialog + tnotes) tatention, 
ISNULL(sum(tque)/ NULLIF(sum(nque), 0), 0) AS tque_avg, sum(tque) as tQue_tot, sum(nQue) as nQue_tot, SUM(nansw_tres + nabnd_tres) AS SL_P_1, 
SUM(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, SUM(tresp) AS tresp
FROM #ccGenInCall  
WHERE timegroup >= @from
AND timegroup < @to 
GROUP BY timegroup , inbound_id) xDetCall  
LEFT JOIN (
SELECT timegroup, inbound_id, SUM(pos_tot) AS pos_tot, SUM(pos_tot) AS pos_avg, SUM(pos_efect) AS pos_efect, COUNT(pos_tot) AS pos_count  
FROM #ccGenInSpec 
WHERE timegroup >= @from
AND timegroup < @to 
GROUP BY timegroup , inbound_id) xDetSpec 
ON (xDetCall.timegroup = xDetSpec.timegroup AND xDetCall.inbound_id = xDetSpec.inbound_id)  
LEFT JOIN (
SELECT timegroup, inbound_id, SUM(time_tot) AS tabnd_tot   
FROM #ccGenInAbnd  
WHERE timegroup >= @from 
AND timegroup < @to 
GROUP BY timegroup , inbound_id) xDetAbnd 
ON (xDetCall.timegroup = xDetAbnd.timegroup AND xDetCall.inbound_id = xDetAbnd.inbound_id) 
) xDetail  
LEFT JOIN ccInbound ON (xDetail.inbound_id=ccInbound.inbound_id)  
ORDER BY date

drop table #ccGenInCall
drop table #ccGenInSpec
drop table #ccGenSession
drop table #agents
drop table #ccGenInAbnd
end'

	EXEC(@Sql)
	
		set @process = 'GetReportMenus - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[GetReportMenus]
	@userId int,
	@activeChat tinyint,
	@activeAVRS tinyint
AS
BEGIN

	Select distinct
		b.Nivel as Nivel,
		substring(b.menu_descrip, charindex(''|'', b.menu_descrip) + 1, len(b.menu_descrip)) as menu_descrip,
		b.menu_id as menu_id,
		b.ordengral as ordengral,
		5 as filtersType
	from
		ccMenus as b with(nolock)
		inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId
	where
		b.type = 3
		and (menu_id >= 2000) 
		and (menu_id not in (3130,3131,3132,3133,3134,3135,3136,8050,8060,8061,8062,8063,8070,8071,8072,8080))
		or  (menu_id     in (3130,3131,3132,3133,3134,3135,3136) and @activeChat = 1 )
		or  (menu_id     in (8050,8060,8061,8062,8063,8070,8071,8072,8080) and @activeAVRS = 1)
			
union
	select distinct b.Nivel as Nivel,
			substring(b.menu_descrip, charindex(''|'', b.menu_descrip) + 1, len(b.menu_descrip)) as menu_descrip,
			b.menu_id as menu_id,
			b.ordengral as ordengral,
			5 as filtersType from (
	Select distinct	b.Parent
		from ccMenus as b with(nolock)
			inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId
			where b.type = 3 and (menu_id >= 2000)  and (menu_id not in (3130,3131,3132,3133,3134,3135,3136,8050,8060,8061,8062,8063,8070,8071,8072,8080))
		or  (menu_id     in (3130,3131,3132,3133,3134,3135,3136) and @activeChat = 1 )
		or  (menu_id     in (8050,8060,8061,8062,8063,8070,8071,8072,8080) and @activeAVRS = 1)
	)x inner join ccMenus b on x.Parent = b.menu_id where type =3
union
	select distinct b.Nivel as Nivel,
			substring(b.menu_descrip, charindex(''|'', b.menu_descrip) + 1, len(b.menu_descrip)) as menu_descrip,
			b.menu_id as menu_id, b.ordengral as ordengral,	5 as filtersType from(
	select b.Parent from (Select distinct	b.Parent
		from ccMenus as b with(nolock)
			inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId
			where b.type = 3 and (menu_id >= 2000)  and (menu_id not in (3130,3131,3132,3133,3134,3135,3136,8050,8060,8061,8062,8063,8070,8071,8072,8080))
		or  (menu_id     in (3130,3131,3132,3133,3134,3135,3136) and @activeChat = 1 )
		or  (menu_id     in (8050,8060,8061,8062,8063,8070,8071,8072,8080) and @activeAVRS = 1)
	)x inner join ccMenus b on x.Parent = b.menu_id where type =3
	)y inner join ccMenus b on y.Parent = b.menu_id where type =3
order by menu_id
END'

	EXEC(@Sql)
	
		set @process = 'GetReportFilters - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[GetReportFilters] @id nvarchar(100), @action tinyint = 0 -- 0 Filter select; 1 Filters Range 
AS
BEGIN
	if @action = 0 begin
		SELECT Filters.[type],Filters.xmlParentNode,Filters.xmlChildNode
		FROM Filters, ReportsFilters 
		WHERE Filters.name = ReportsFilters.filterName 
		AND ReportsFilters.id = @id
	end
	if @action = 1 begin
		SELECT Filters.[type], Filters.xmlParentNode, Filters.xmlChildNode
		FROM Filters, ReportsFiltersRange 
		WHERE Filters.name = ReportsFiltersRange.filterName 
		AND ReportsFiltersRange.id = @id
	end
	if @action = 2 begin
		SELECT restrictExp, dbColumn
		FROM ReportsFiltersText 
		WHERE id = @id
	end
END'

	EXEC(@Sql)
	
		set @process = 'ccspRepSpecialCallKeyHistory - Create Job'
		set @Sql = 'USE [msdb]

/****** Object:  Job [ccspRepSpecialCallKeyHistory]    Script Date: 11/28/2013 22:07:00 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 11/28/2013 22:07:01 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ccspRepSpecialCallKeyHistory'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [LoadInformationReport]    Script Date: 11/28/2013 22:07:03 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''LoadInformationReport'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec [ccspRepSpecialCallKeyHistory] 1'', 
		@database_name=N''ccReportsRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		
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
