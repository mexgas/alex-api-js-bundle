/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/* 
Author:  Jesus Gallardo
Date: 2014/08/08
Description:
	Se agrega columna RepIVRDetail agrega nombre del ivr
	Se agrega traduccio TranslatedReports para reportes de IVR
	Se modifica SP ccspRepIVRDetail 
	Se modifca SP ccspRepInCalls

	Se Borra objetos de la Base datos

Database: ccReportsRia
Required version: 19

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 20

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

			/* Start script release */
			set @process = 'Alter table - RepIVRDetail'
			set @sql='if not exists (select * from sys.columns where name = N''ivrName'' and Object_ID = Object_ID(N''RepIVRDetail''))
				alter table RepIVRDetail add ivrName varchar(50)'	
			EXEC(@sql)

			set @process = 'Insert - TranslatedReports'
			set @sql='if exists (select * from sys.tables where name = N''TranslatedReports'')
				insert TranslatedReports values (6010,''ivrName'')'	
			EXEC(@sql)

			set @process = 'Alter SP - ccspRepIVRDetail'
			if exists (select * from sys.procedures where name = N'ccspRepIVRDetail')
				set @sql='ALTER PROCEDURE [dbo].[ccspRepIVRDetail]
					@action as tinyint,
					@from as datetime = null,
					@to as datetime = null
					AS

					if @from is null
					select @from = convert(datetime,convert(varchar(11),getdate()))
					select @to = getdate()

					if @action = 1 
					begin

					select A.Ivr_id,A.cal_ani,isnull(B.user_id,0) as [user_id],isnull(B.calif_id,0) as [calif_id]
					,isnull(B.cal_id,0) as [cal_id],A.date,A.dnis
					into #IVRLlamadas
					from IVRCallsIn as A 
					left join ccCallsIn As B on  A.IVR_id = B.IVR_id 
					where date >= @from and date < @to
						
					delete from RepIVRDetail with(rowlock)
					where date >= @from AND date < @to
						
					insert into RepIVRDetail
						select #IVRLlamadas.date as fecha, cal_ani as telefono
							, isNull(u.nombres + '' '' + u.apellidopaterno + '' '' + u.apellidomaterno,'''') as nombre
							, isnull(calif.description, #IVRLlamadas.calif_id) as calificacion, cal_id as cal_id
							, isnull(
							(
								select selectedOption + '',''	from IVROptions (nolock)
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
							--isnull(name,''systemTranslated_NoName'') name
							case when name is NULL then ''systemTranslated_NoName'' when name = '''' then ''systemTranslated_NoName'' else name end
							from #IVRLlamadas
							left join
							(
								select ivr_id,name, max(date) as maxDate from IVROptions nolock
								group by ivr_id,name
							) optTime on #IVRLlamadas.ivr_id = optTime.ivr_id
							left join ccusers u (nolock) on (u.user_id = #IVRLlamadas.user_id)
							left join cctipocalif calif on (calif.calif_id = #IVRLlamadas.calif_id)
							where #IVRLlamadas.date >= @from and #IVRLlamadas.date < @to
							order by date

					drop table #IVRLlamadas
					end'	
			else
				set @sql = ''
			EXEC(@sql)

			set @process = 'Alter SP - ccspRepInCalls'
			if exists (select * from sys.procedures where name = N'ccspRepInCalls')
				set @sql='ALTER PROCEDURE [dbo].[ccspRepInCalls]
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

					declare @starttime datetime
					  declare @number int
					  set @starttime = @from
					  set @number = 0           
					 
					  create table [#callsin](
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
					  
					CREATE TABLE [dbo].[#ccGenInSpec](
						[timegroup] [smalldatetime] NOT NULL,
						[inbound_id] [smallint] NOT NULL,
						[pos_tot] [smallint] NOT NULL,
						[pos_time] [int] NOT NULL,
						[pos_efect] [smallint] NOT NULL
					) ON [PRIMARY]

					CREATE TABLE [dbo].[#ccGenSession](
						[user_id] [smallint] NOT NULL,
						[login] [datetime] NOT NULL,
						[logout] [datetime] NULL default(getdate()),
						[extension] [varchar](7) NOT NULL
					) ON [PRIMARY]

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

					insert into #callsin(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
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
					   
					delete #callsin WHERE timegroup>=@from AND timegroup<@to AND INBOUND_ID>0
					AND ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
					AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
					AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
					AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0                                                   

					select * into #callsin2 from #callsin where datediff(mi,timegroup,timegroup_next)>15

					delete #callsin where datediff(mi,timegroup,timegroup_next) > 15
					           
					insert into #callsin(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)     
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
						  from #callsin2 t
						  join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
						  where  datediff(ss,th.start,timegroup_next)>0
						  order by cal_id                         

					drop table #callsin2
					  
					-- Session Time
					insert into #ccGenSession
					select [user_id], [login], logout,extension
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
						set s.logout = (select dateadd(ss,-1,isnull(min(login),getdate())) from #ccGenSession where [login]>s.[login] and [user_id] = s.[user_id])
						from #ccGenSession s    
						where logout is null		

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
									 FROM #ccGenSession
									 WHERE [user_id]=xTimeDetail.[user_id]
										   AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
						  ),0)AS t1                               
						  ,ISNULL((SELECT top 1 900
										   FROM #ccGenSession
										   WHERE [user_id]=xTimeDetail.[user_id]
												 AND login<=xTimeDetail.timegroup AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
								),0)AS t2                         
						  ,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
										   FROM #ccGenSession
										   WHERE [user_id]=xTimeDetail.[user_id]
												 AND login>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
								),0)AS t3
						  ,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(mi,15,xTimeDetail.timegroup))
										   FROM #ccGenSession
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
					(select #callsin.timegroup as timegroup,
						  #callsin.[user_id] as [user_id]
						  ,ISNULL(SUM(#callsin.txfer),0) as txfer
						  ,ISNULL(SUM(#callsin.tdialog),0) as tdialog
						  ,ISNULL(SUM(#callsin.tnotes),0) as tnotes
						  ,ISNULL(SUM(#callsin.tring),0) as tring
						  ,ISNULL(SUM(#callsin.nMoh),0) as nMoh
						  ,ISNULL(SUM(#callsin.nWHag),0) as nWHag
						  ,ISNULL(SUM(#callsin.nWHcl),0) as nWHcl            
					from #callsin	
					group by
						  #callsin.timegroup, #callsin.[user_id]
					) as calls on calls.timegroup = xTimeDetail.timegroup and xTimeDetail.[user_id]=calls.[user_id]
					where xTimeDetail.timegroup is not null
					         
					drop table #timeDetailAgent

					INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
						SELECT timegroup, ccInboundAgentes.inbound_id
							, COUNT(DISTINCT #agentInformation.[user_id]) AS pos_max -- pos_tot
							, SUM((t1+t2+t3+t4) - (tnot_av + tprob + tother)) AS pos_time
							, COUNT(CASE WHEN ((t1+t2+t3+t4)- (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
						 FROM #agentInformation
							INNER JOIN ccInboundAgentes ON (#agentInformation.[user_id] = ccInboundAgentes.[user_id])
						 WHERE timegroup >= @from AND timegroup < @to  AND INBOUND_ID > 0
						 GROUP BY timegroup, ccInboundAgentes.inbound_id

					--Borrar lo que esta para no repetir
					delete from [RepInCalls] with(rowlock)
					where date >= @from AND date < @to

					insert into [RepInCalls]
					SELECT	timegroup as [date], ccInbound.inbound_id as inboundId, descripcion as inbound, 
						ccDnis.dni_id as dnisId, ccDnis.dni_descripcion as dnis, 0 as [workgroupId], '''' as [workgroup], 0 as [areaId], 
						'''' as [area], 
						ntotal, nxfer, 
						nabnd_que, nxfer_que, nno_xfer, tque_max , 
						tque, nque, nanswer, nno_answer, nlost, nabnd_xfer, nabnd_ring, nabnd_dialog, pos_tot, pos_time, SL_P_1, SL_P_2 , avg, SL,nMoh, 
						nWHag, nWHcl, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
						, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
						, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
						, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
						, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
						,cal_id,phone_in,dateStartDetail
						FROM (	
					SELECT cal_id,phone_in,isnull(dateStartDetail,'''') as dateStartDetail,
						ISNULL(xDetCall.tg, xDetSpec.tg ) as timegroup , ISNULL(xDetCall.inbound_id, xDetSpec.inbound_id) inbound_id, xDetCall.dni_id as dni_id, 
							ISNULL(ntotal, 0) ntotal, ISNULL(nxfer, 0) nxfer, ISNULL(nabnd_que, 0) nabnd_que , ISNULL(nxfer_que, 0) nxfer_que, 
							ISNULL(nno_xfer, 0) nno_xfer, ISNULL(tque_max, 0) tque_max , ISNULL(tque, 0) tque, ISNULL(nque, 0) nque, 
							ISNULL(nanswer, 0) nanswer , ISNULL(nno_answer, 0) nno_answer, ISNULL(nlost, 0) nlost, ISNULL(nabnd_xfer, 0) nabnd_xfer , 
							ISNULL(nabnd_ring, 0) nabnd_ring, ISNULL(nabnd_dialog, 0) nabnd_dialog, ISNULL(pos_tot, 0) pos_tot , ISNULL(pos_time, 0) pos_time, 
							ISNULL(SL_P_1, 0) SL_P_1, ISNULL(SL_P_2, 0) SL_P_2 , ISNULL(tque/ NULLIF(nque, 0), 0) avg, 
							ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0) SL, ISNULL(nMoh, 0) nMoh, ISNULL(nWHag,0) nWHag, ISNULL(nWHcl,0) nWHcl 
							FROM (SELECT cal_id,phone_in,dateStartDetail,timegroup as tg, inbound_id, dni_id, ntotal , nxfer, nabnd as nabnd_que, nxfer_que,
								(ninitial + nout_service + nout_hour + nno_agent + ntimeout + noverflow ) nno_xfer , tque_max, 
								tque, NULLIF(nque, 0) nque , nanswer, nno_answer , nlost, 
								(nabnd_xfer) nabnd_xfer , nabnd_ring, nabnd_dialog, nMoh, nWHag,
								nWHcl , (nansw_tres + nabnd_tres) AS SL_P_1 , 
								(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2 
								FROM #callsin  
								WHERE timegroup >= @from AND timegroup < @to) xDetCall
					FULL OUTER JOIN (SELECT  timegroup as tg, inbound_id, pos_tot, pos_time  
									FROM #ccGenInSpec  
									WHERE timegroup >= @from AND timegroup < @to) xDetSpec
						ON xDetCall.tg = xDetSpec.tg  AND xDetCall.inbound_id = xDetSpec.inbound_id ) xDetail 
					INNER JOIN ccInbound ON (xDetail.inbound_id = ccInbound.inbound_id) 
					LEFT OUTER JOIN ccDnis ON (xDetail.dni_id = ccDnis.dni_id)
					where ccInbound.inbound_id is not null and ccDnis.dni_id is not null
					order by descripcion, timegroup 
								
					update [RepInCalls] set
					[workgroupId] = b.idwg
					from [RepInCalls] a, ccInboundAgentes b
					where a.inboundId = b.inbound_id

					update [RepInCalls] set
					areaId = b.idarea
					from [RepInCalls] a, ccRIAAreaWorkGroup b
					where a.[workgroupId] = b.idwg

					update [RepInCalls]
					set workgroup = wgname, area = areaname
					from [RepInCalls] a, ccriacat_workgroup b, ccriacat_areas c
					where a.[workgroupId] = b.idwg
					and a.areaId = c.idarea

					drop table #times		
					drop table #callsin
					drop table #agentInformation		
					drop table #ccGenInSpec
					drop table #ccGenSession
					drop table #ccGenInCall		

					end'	
			else
				set @sql = ''
			EXEC(@sql)	


			set @process = 'Drop Object - Clean DATABASE'
			set @sql='-- Drop Stored Procedures
				if exists (select * from sys.procedures where name = N''A_ccHistorico'')
					DROP PROCEDURE [A_ccHistorico]
				
				if exists (select * from sys.procedures where name = N''A_cwCalifNoAnsw'')
					DROP PROCEDURE [A_cwCalifNoAnsw]

				if exists (select * from sys.procedures where name = N''A_cwRep2Calif_WG'')
					DROP PROCEDURE [A_cwRep2Calif_WG]

				if exists (select * from sys.procedures where name = N''A_cwRepInbCalif'')
					DROP PROCEDURE [A_cwRepInbCalif]
				
				if exists (select * from sys.procedures where name = N''A_cwRepNotReady'')
					DROP PROCEDURE [A_cwRepNotReady]

				if exists (select * from sys.procedures where name = N''A_cwReportDialCamp'')
					DROP PROCEDURE [A_cwReportDialCamp]

				if exists (select * from sys.procedures where name = N''A_cwReportDialWG'')
					DROP PROCEDURE [A_cwReportDialWG]

				if exists (select * from sys.procedures where name = N''A_cwReportMnzCalif'')					
					DROP PROCEDURE [A_cwReportMnzCalif]

				if exists (select * from sys.procedures where name = N''A_cwReportOutCtoCamp'')
					DROP PROCEDURE [A_cwReportOutCtoCamp]

				if exists (select * from sys.procedures where name = N''A_cwReportOutCtoProv'')
					DROP PROCEDURE [A_cwReportOutCtoProv]

				if exists (select * from sys.procedures where name = N''A_cwReportOutCtoUser'')
					DROP PROCEDURE [A_cwReportOutCtoUser]

				if exists (select * from sys.procedures where name = N''A_cwRepOutCalif'')
					DROP PROCEDURE [A_cwRepOutCalif]

				if exists (select * from sys.procedures where name = N''A_cwRepSubCalif'')
					DROP PROCEDURE [A_cwRepSubCalif]

				if exists (select * from sys.procedures where name = N''cc_InboundMetrics'')
					DROP PROCEDURE [cc_InboundMetrics]

				if exists (select * from sys.procedures where name = N''cc_InboundMetricsB'')
					DROP PROCEDURE [cc_InboundMetricsB]

				if exists (select * from sys.procedures where name = N''ccRepOutPortStats'')
					DROP PROCEDURE [ccRepOutPortStats]

				if exists (select * from sys.procedures where name = N''ccsp_ADMChecaLogin'')
					DROP PROCEDURE [ccsp_ADMChecaLogin]

				if exists (select * from sys.procedures where name = N''ccsp_GenHoldReport'')
					DROP PROCEDURE [ccsp_GenHoldReport]

				if exists (select * from sys.procedures where name = N''ccsp_GenKPIAgentes'')
					DROP PROCEDURE [ccsp_GenKPIAgentes]

				if exists (select * from sys.procedures where name = N''ccsp_GenKPIOutbound'')
					DROP PROCEDURE [ccsp_GenKPIOutbound]

				if exists (select * from sys.procedures where name = N''ccsp_LogInfo'')
					DROP PROCEDURE [ccsp_LogInfo]

				if exists (select * from sys.procedures where name = N''ccsp_repDIDRes'')
					DROP PROCEDURE [ccsp_repDIDRes]

				if exists (select * from sys.procedures where name = N''ccsp_reportInRejectCall'')
					DROP PROCEDURE [ccsp_reportInRejectCall]

				if exists (select * from sys.procedures where name = N''ccspGenABorraAntiguo'')
					DROP PROCEDURE [ccspGenABorraAntiguo]

				if exists (select * from sys.procedures where name = N''ccspGenAgent'')
					DROP PROCEDURE [ccspGenAgent]

				if exists (select * from sys.procedures where name = N''ccspGenAgentStatusNotReady'')
					DROP PROCEDURE [ccspGenAgentStatusNotReady]

				if exists (select * from sys.procedures where name = N''ccspGenAgentStatusSepHour'')
					DROP PROCEDURE [ccspGenAgentStatusSepHour]

				if exists (select * from sys.procedures where name = N''ccspGenAgentStatusSepHourNotReady'')
					DROP PROCEDURE [ccspGenAgentStatusSepHourNotReady]

				if exists (select * from sys.procedures where name = N''ccspGenCallBacksInfo'')
					DROP PROCEDURE [ccspGenCallBacksInfo]

				if exists (select * from sys.procedures where name = N''ccspGenExecuteOnline'')
					DROP PROCEDURE [ccspGenExecuteOnline]

				if exists (select * from sys.procedures where name = N''ccspGenInAbnd'')
					DROP PROCEDURE [ccspGenInAbnd]

				if exists (select * from sys.procedures where name = N''ccspGenInAbndWG'')
					DROP PROCEDURE [ccspGenInAbndWG]

				if exists (select * from sys.procedures where name = N''ccspGenInAnsw'')
					DROP PROCEDURE [ccspGenInAnsw]

				if exists (select * from sys.procedures where name = N''ccspGenInAnswWG'')
					DROP PROCEDURE [ccspGenInAnswWG]

				if exists (select * from sys.procedures where name = N''ccspGenInCalif'')
					DROP PROCEDURE [ccspGenInCalif]

				if exists (select * from sys.procedures where name = N''ccspGenInCalifWG'')
					DROP PROCEDURE [ccspGenInCalifWG]

				if exists (select * from sys.procedures where name = N''ccspGenInCall'')
					DROP PROCEDURE [ccspGenInCall]

				if exists (select * from sys.procedures where name = N''ccspGenInCallDNI'')
					DROP PROCEDURE [ccspGenInCallDNI]

				if exists (select * from sys.procedures where name = N''ccspGenInCallWG'')
					DROP PROCEDURE [ccspGenInCallWG]

				if exists (select * from sys.procedures where name = N''ccspGenInCDN'')
					DROP PROCEDURE [ccspGenInCDN]

				if exists (select * from sys.procedures where name = N''ccspGenInCDNdelay'')
					DROP PROCEDURE [ccspGenInCDNdelay]

				if exists (select * from sys.procedures where name = N''ccspGenInfo'')
					DROP PROCEDURE [ccspGenInfo]

				if exists (select * from sys.procedures where name = N''ccspGenInSpec'')
					DROP PROCEDURE [ccspGenInSpec]

				if exists (select * from sys.procedures where name = N''ccspGenInSpecWG'')
					DROP PROCEDURE [ccspGenInSpecWG]

				if exists (select * from sys.procedures where name = N''ccspGenInSubCalif'')
					DROP PROCEDURE [ccspGenInSubCalif]

				if exists (select * from sys.procedures where name = N''ccspGenMktIntervaloSalida'')
					DROP PROCEDURE [ccspGenMktIntervaloSalida]

				if exists (select * from sys.procedures where name = N''ccspGenOutCall'')
					DROP PROCEDURE [ccspGenOutCall]

				if exists (select * from sys.procedures where name = N''ccspGenOutCallCalif'')
					DROP PROCEDURE [ccspGenOutCallCalif]

				if exists (select * from sys.procedures where name = N''ccspGenOutCallCalifWG'')
					DROP PROCEDURE [ccspGenOutCallCalifWG]

				if exists (select * from sys.procedures where name = N''ccspGenOutCallDials'')
					DROP PROCEDURE [ccspGenOutCallDials]

				if exists (select * from sys.procedures where name = N''ccspGenOutCallDialsWG'')
					DROP PROCEDURE [ccspGenOutCallDialsWG]

				if exists (select * from sys.procedures where name = N''ccspGenOutCallWG'')
					DROP PROCEDURE [ccspGenOutCallWG]

				if exists (select * from sys.procedures where name = N''ccspGenOutCamp'')
					DROP PROCEDURE [ccspGenOutCamp]

				if exists (select * from sys.procedures where name = N''ccspGenOutCampWG'')
					DROP PROCEDURE [ccspGenOutCampWG]

				if exists (select * from sys.procedures where name = N''ccspGenOutCstoResumen'')
					DROP PROCEDURE [ccspGenOutCstoResumen]

				if exists (select * from sys.procedures where name = N''ccspGenOutDialCamp'')
					DROP PROCEDURE [ccspGenOutDialCamp]

				if exists (select * from sys.procedures where name = N''ccspGenOutMarcCalif'')
					DROP PROCEDURE [ccspGenOutMarcCalif]

				if exists (select * from sys.procedures where name = N''ccspGenOutPortStats'')
					DROP PROCEDURE [ccspGenOutPortStats]

				if exists (select * from sys.procedures where name = N''ccspGenOutSubCalif'')
					DROP PROCEDURE [ccspGenOutSubCalif]

				if exists (select * from sys.procedures where name = N''ccspGenResAgent'')
					DROP PROCEDURE [ccspGenResAgent]

				if exists (select * from sys.procedures where name = N''ccspGenSession'')
					DROP PROCEDURE [ccspGenSession]

				if exists (select * from sys.procedures where name = N''ccspGenTelMarcados'')
					DROP PROCEDURE [ccspGenTelMarcados]

				if exists (select * from sys.procedures where name = N''ccspIVRInfo'')
					DROP PROCEDURE [ccspIVRInfo]

				if exists (select * from sys.procedures where name = N''ccspIVRInsert'')
					DROP PROCEDURE [ccspIVRInsert]

				if exists (select * from sys.procedures where name = N''MLS_Report'')
					DROP PROCEDURE [MLS_Report]

				if exists (select * from sys.procedures where name = N''sp_mkt_Abandono_Porcentajes'')
					DROP PROCEDURE [sp_mkt_Abandono_Porcentajes]

				if exists (select * from sys.procedures where name = N''sp_mkt_Abandono_Tiempos'')
					DROP PROCEDURE [sp_mkt_Abandono_Tiempos]

				if exists (select * from sys.procedures where name = N''sp_mkt_agentes'')
					DROP PROCEDURE [sp_mkt_agentes]

				if exists (select * from sys.procedures where name = N''sp_mkt_diario'')
					DROP PROCEDURE [sp_mkt_diario]

				if exists (select * from sys.procedures where name = N''sp_mkt_diario_tiempostotales'')
					DROP PROCEDURE [sp_mkt_diario_tiempostotales]

				if exists (select * from sys.procedures where name = N''sp_mkt_intervalo_TiemposAcumuladosTotales'')
					DROP PROCEDURE [sp_mkt_intervalo_TiemposAcumuladosTotales]

				if exists (select * from sys.procedures where name = N''sp_mkt_intervalo_TiemposTotales'')
					DROP PROCEDURE [sp_mkt_intervalo_TiemposTotales]

				if exists (select * from sys.procedures where name = N''sp_mkt_intervalos'')
					DROP PROCEDURE [sp_mkt_intervalos]

				if exists (select * from sys.procedures where name = N''sp_mkt_intervalos_out'')
					DROP PROCEDURE [sp_mkt_intervalos_out]

				if exists (select * from sys.procedures where name = N''sp_mkt_mensual'')
					DROP PROCEDURE [sp_mkt_mensual]

				-- Drop Views
				if exists (select * FROM sys.views where name = N''ccGenViewAgent'')
					DROP VIEW [ccGenViewAgent]

				if exists (select * FROM sys.views where name = N''ccGenViewInCall'')
					DROP VIEW [ccGenViewInCall]

				if exists (select * FROM sys.views where name = N''ccGenViewOutCall'')
					DROP VIEW [ccGenViewOutCall]

				if exists (select * FROM sys.views where name = N''holdViewDataInbound'')
					DROP VIEW [holdViewDataInbound]

				if exists (select * FROM sys.views where name = N''holdViewDataOutbound'')
					DROP VIEW [holdViewDataOutbound]

				-- Drop Trigger
				IF EXISTS (select * from sys.triggers where name = ''trigPosicionEspecialidad'')
					DROP TRIGGER [trigPosicionEspecialidad]

				-- Drop tables
				if exists (select * from sys.tables where name = N''cccatgpo_camp'')
					DROP TABLE [cccatgpo_camp]

				if exists (select * from sys.tables where name = N''ccGen900'')
					DROP TABLE [ccGen900]

				if exists (select * from sys.tables where name = N''ccGenAgent'')
					DROP TABLE [ccGenAgent]

				if exists (select * from sys.tables where name = N''ccGenAgentNotReady'')
					DROP TABLE [ccGenAgentNotReady]

				if exists (select * from sys.tables where name = N''ccGenChart'')
					DROP TABLE [ccGenChart]

				if exists (select * from sys.tables where name = N''ccGenInAbnd'')
					DROP TABLE [ccGenInAbnd]

				if exists (select * from sys.tables where name = N''ccGenInAbndWG'')
					DROP TABLE [ccGenInAbndWG]

				if exists (select * from sys.tables where name = N''ccGenInAnsw'')
					DROP TABLE [ccGenInAnsw]

				if exists (select * from sys.tables where name = N''ccGenInAnswWG'')
					DROP TABLE [ccGenInAnswWG]

				if exists (select * from sys.tables where name = N''ccGenInCalif'')
					DROP TABLE [ccGenInCalif]

				if exists (select * from sys.tables where name = N''ccGenInCalifWG'')
					DROP TABLE [ccGenInCalifWG]

				if exists (select * from sys.tables where name = N''ccGenInCall'')
					DROP TABLE [ccGenInCall]

				if exists (select * from sys.tables where name = N''ccGenInCallDNI'')
					DROP TABLE [ccGenInCallDNI]

				if exists (select * from sys.tables where name = N''ccGenInCallWG'')
					DROP TABLE [ccGenInCallWG]

				if exists (select * from sys.tables where name = N''ccGenInSpec'')
					DROP TABLE [ccGenInSpec]

				if exists (select * from sys.tables where name = N''ccGenInSpecWG'')
					DROP TABLE [ccGenInSpecWG]

				if exists (select * from sys.tables where name = N''ccGenInSubCalif'')
					DROP TABLE [ccGenInSubCalif]

				if exists (select * from sys.tables where name = N''ccGenMktIntervaloSalida'')
					DROP TABLE [ccGenMktIntervaloSalida]

				if exists (select * from sys.tables where name = N''ccGenOutCall'')
					DROP TABLE [ccGenOutCall]

				if exists (select * from sys.tables where name = N''ccGenOutCallCalif'')
					DROP TABLE [ccGenOutCallCalif]

				if exists (select * from sys.tables where name = N''ccGenOutCallCalifWG'')
					DROP TABLE [ccGenOutCallCalifWG]

				if exists (select * from sys.tables where name = N''ccGenOutCallDials'')
					DROP TABLE [ccGenOutCallDials]

				if exists (select * from sys.tables where name = N''ccGenOutCallDialsWG'')
					DROP TABLE [ccGenOutCallDialsWG]

				if exists (select * from sys.tables where name = N''ccGenOutCallWG'')
					DROP TABLE [ccGenOutCallWG]

				if exists (select * from sys.tables where name = N''ccGenOutCamp'')
					DROP TABLE [ccGenOutCamp]

				if exists (select * from sys.tables where name = N''ccGenOutCampWG'')
					DROP TABLE [ccGenOutCampWG]

				if exists (select * from sys.tables where name = N''ccGenOutCstoResumen'')
					DROP TABLE [ccGenOutCstoResumen]

				if exists (select * from sys.tables where name = N''ccGenOutDialCamp'')
					DROP TABLE [ccGenOutDialCamp]

				if exists (select * from sys.tables where name = N''ccGenOutPortStats'')
					DROP TABLE [ccGenOutPortStats]

				if exists (select * from sys.tables where name = N''ccGenOutSubCalif'')
					DROP TABLE [ccGenOutSubCalif]

				if exists (select * from sys.tables where name = N''ccGenResumenAgente'')
					DROP TABLE [ccGenResumenAgente]

				if exists (select * from sys.tables where name = N''ccGenSession'')
					DROP TABLE [ccGenSession]

				if exists (select * from sys.tables where name = N''ccGenSessionAgent'')
					DROP TABLE [ccGenSessionAgent]

				if exists (select * from sys.tables where name = N''ccGenSessionInCall'')
					DROP TABLE [ccGenSessionInCall]

				if exists (select * from sys.tables where name = N''ccGenSessionInSpec'')
					DROP TABLE [ccGenSessionInSpec]

				if exists (select * from sys.tables where name = N''ccGenSessionNotReady'')
					DROP TABLE [ccGenSessionNotReady]

				if exists (select * from sys.tables where name = N''ccGenSessionOutCall'')
					DROP TABLE [ccGenSessionOutCall]

				if exists (select * from sys.tables where name = N''ccGenSessionOutCamp'')
					DROP TABLE [ccGenSessionOutCamp]

				if exists (select * from sys.tables where name = N''ccgenTelMarcados'')
					DROP TABLE [ccgenTelMarcados]

				if exists (select * from sys.tables where name = N''ccoDialerCamp'')
					DROP TABLE [ccoDialerCamp]

				if exists (select * from sys.tables where name = N''ccPosicionCamps'')
					DROP TABLE [ccPosicionCamps]

				if exists (select * from sys.tables where name = N''ccPosicionEspecialidad'')
					DROP TABLE [ccPosicionEspecialidad]

				if exists (select * from sys.tables where name = N''ccRIAWorkGroup_logdial_id'')
					DROP TABLE [ccRIAWorkGroup_logdial_id]

				if exists (select * from sys.tables where name = N''ccSup_Usuario'')
					DROP TABLE [ccSup_Usuario]

				if exists (select * from sys.tables where name = N''ccTipoStatusAgente'')
					DROP TABLE [ccTipoStatusAgente]

				if exists (select * from sys.tables where name = N''ccTipoUsers'')
					DROP TABLE [ccTipoUsers]

				if exists (select * from sys.tables where name = N''Exp_Jobs'')
					DROP TABLE [Exp_Jobs]

				if exists (select * from sys.tables where name = N''exportReports'')
					DROP TABLE [exportReports]

				if exists (select * from sys.tables where name = N''IVRLlamadas'')
					DROP TABLE [IVRLlamadas]

				-- Drop Functions
				if exists (select * from sys.objects where object_id = OBJECT_ID(N''fGetHHmmSS'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
					DROP FUNCTION [fGetHHmmSS]

				if exists (select * from sys.objects where object_id = OBJECT_ID(N''zeroCalendarPadding'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
					DROP FUNCTION [zeroCalendarPadding]'	
			EXEC(@sql)
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

/**************************/
/***** GUIDE AND HELP *****/
/**************************/

/* IMPORTANT: Consider objects manipulation in the sequence exposed in order to get consistency in the script, uncommon objects are prior to common ones in case of exist except replication */

/***** Language Reference *****/
/*
DDL (Data Definition Language)
	* Create
	* Drop
	* Alter

DML (Data Manipulation Language)
	* Select
	* Update
	* Delete
	* Insert

Contraint Object Types
	* C = CHECK constraint
	* D = DEFAULT (constraint or stand-alone)
	* F = FOREIGN KEY constraint
	* PK = PRIMARY KEY constraint
	* R = Rule (old-style, stand-alone)
	* UQ = UNIQUE constraint

Function Object Types
	* FN Scalar function
	* IF Inline table-valued function
	* TF Table-valued-function
	* FS Assembly (CLR) scalar-function
	* FT Assembly (CLR) table-valued function
*/

/***** Most common objects *****/
/* 
TABLES
-- When table exists
if exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

-- When table does not exists
if not exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

COLUMNS
-- When column exists
if exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When column does not exists
if not exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

CONSTRAINTS
-- When constraint exists
if exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

-- When constraint does not exists
if not exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

INDEXES
-- When index exists
if exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When index does not exists
if not exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

TRIGGERS
-- When trigger exists
if exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When trigger does not exists
if not exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

FUNCTIONS
-- When function exists
if exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

-- When function does not exists
if not exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

STORED PROCEDURES
-- When stored procedure exists
if exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

-- When stored procedure does not exists
if not exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

VIEWS
-- When view exists
if exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

-- When view does not exists
if not exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

JOBS (In this case be careful about what to do)
-- if you want to create, modify or delete use the script below
if exists (select * from msdb.dbo.sysjobs_view where name = N'yourJobName')
	begin
		exec msdb.dbo.sp_delete_job @job_name = N'yourJobName', @delete_unused_schedule=1
	end

-- After that, you could run the script to create the Job despite of being new or being modified
*/

/***** Uncommon objects *****/
/*
DATABASES
-- When database exists
if exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

-- When database does not exists
if not exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

LOGINS
-- When login exists
if exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

-- When login does not exists
if not exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

SERVER ROLES
-- When server role exists
if exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

-- When server role does not exists
if not exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

SCHEMAS
-- When schema exists
if exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

-- When schema does not exists
if not exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

Replication
-- Replication scripts are generated apart so you have to check them and consider the validations implemented on those scripts
	* Publications
	* Subscriptions on publisher
	* Subscriptions
	* Snapshots
*/