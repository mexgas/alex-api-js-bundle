/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/* 
Author: Jesus Gallardo
Date: 2014/08/08
Description:
	Se crea la tabla telefonosConferencia
	Se crea la tabla telefonosTransferencia
	Se crea la tabla ccCampsAgente
	Se crea la tabla ccRIACampEspWG
	Se crea la tabla ccCalifCamp

	Se agrega clave foranea ccCampsAgente FK
	se agrega CONSTRAINT ccCampsAgente FK_ccCampsAgente_ccCamps
	Se agrega clave foranea ccPosicion FK
	Se agrega CONSTRAINT ccPosicion FK_ccPosicion_ccMonitorExt
	Se modifica el tipo de dato RepSpececialPromises
	Se modifica el tipo de dato RepSpececialCamMovs
	Se modifica el SP ccspRepOutAnswCalls
	Se modifica el SP ccspRepOutKPI
	Se modifica el SP ccspRepSpececialAgent
	Se modifica el SP ccspRepSpececialAgtPerformance

	Se modifica el job ShrinkLogCCReportsRia
	Se modifica el job DatabaseCentinella

Database: ccReportsRia
Required version: 20

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 21

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

			/* Start script release */
			set @process = 'Create table - telefonosConferencia'
			set @sql='if not exists (select * from sysobjects where name=''telefonosConferencia'' and type=''U'')  
				begin
					CREATE TABLE [dbo].[telefonosConferencia](
						[numcon_id] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
						[nombre] [varchar](50) NULL,
						[tel] [varchar](50) NULL,
					 CONSTRAINT [PK_telefonosConferencia] PRIMARY KEY CLUSTERED 
					(
						[numcon_id] ASC
					)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
					) ON [PRIMARY]
				end'	
			EXEC(@sql)
	
			set @process = 'Create table - telefonosTransferencia'
			set @sql='if not exists (select * from sysobjects where name=''telefonosTransferencia'' and type=''U'')  
				begin
					CREATE TABLE [dbo].[telefonosTransferencia](
						[numtra_id] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
						[nombre] [varchar](50) NULL,
						[tel] [varchar](50) NULL,
					 CONSTRAINT [PK_telefonosTransferencia] PRIMARY KEY CLUSTERED 
					(
						[numtra_id] ASC
					)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
					) ON [PRIMARY]
				end'	
			EXEC(@sql)
	
			set @process = 'Create table - ccCampsAgente'
			set @sql='if not exists (select * from sysobjects where name=''ccCampsAgente'' and type=''U'')  
				begin
					CREATE TABLE [dbo].[ccCampsAgente](
						[user_id] [smallint] NULL,
						[cam_id] [smallint] NOT NULL,
						[prioridad] [tinyint] NOT NULL CONSTRAINT [DF_ccCampsAgente_prioridad]  DEFAULT ((1)),
						[skill] [tinyint] NOT NULL CONSTRAINT [DF_ccCampsAgente_skill]  DEFAULT ((1)),
						[rel_id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
						[IDWG] [int] NOT NULL CONSTRAINT [DF_ccCampsAgente_IDWG]  DEFAULT ((0)),
					 CONSTRAINT [PK_ccCampsAgente] PRIMARY KEY CLUSTERED 
					(
						[rel_id] ASC
					)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
					) ON [PRIMARY]
				end'
			EXEC(@sql)
	
			set @process = 'Create table - ccRIACampEspWG'
			set @sql='if not exists (select * from sysobjects where name=''ccRIACampEspWG'' and type=''U'')  
				begin
					CREATE TABLE [dbo].[ccRIACampEspWG](
						[IDWG] [smallint] NOT NULL,
						[Tipo] [smallint] NOT NULL,
						[IdCampEsp] [smallint] NOT NULL,
						[priority] [tinyint] NOT NULL DEFAULT ((1))
					) ON [PRIMARY]
				end'	
			EXEC(@sql)
	
			set @process = 'Create table - ccCalifCamp'
			set @sql='if not exists (select * from sysobjects where name=''ccCalifCamp'' and type=''U'')  
				begin
					CREATE TABLE [dbo].[ccCalifCamp](
						[calif_id] [smallint] NOT NULL,
						[cam_id] [smallint] NOT NULL,
						[tipo] [bit] NOT NULL,
					 CONSTRAINT [uc_ccCalifCamp] UNIQUE NONCLUSTERED 
					(
						[calif_id] ASC,
						[cam_id] ASC,
						[tipo] ASC
					)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
					) ON [PRIMARY]
				end'	
			EXEC(@sql)
		
			set @process = 'Alter table - ccCampsAgente FK'
			set @sql='if exists (select * from sys.tables where name = N''ccCampsAgente'')
				ALTER TABLE [dbo].[ccCampsAgente] ADD FOREIGN KEY([cam_id]) REFERENCES [dbo].[ccCamps] ([cam_id])'	
			EXEC(@sql)
			
			set @process = 'Alter table - ccCampsAgente FK'
			set @sql='if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''FK_ccCampsAgente_ccCamps'')
				ALTER TABLE [dbo].[ccCampsAgente]  WITH NOCHECK ADD  CONSTRAINT [FK_ccCampsAgente_ccCamps] FOREIGN KEY([cam_id]) REFERENCES [dbo].[ccCamps] ([cam_id])'	
			EXEC(@sql)

			set @process = 'Alter table - ccCampsAgente CONSTRAINT FK_ccCampsAgente_ccCamps'
			set @sql='if exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''FK_ccCampsAgente_ccCamps'')
				ALTER TABLE [dbo].[ccCampsAgente] CHECK CONSTRAINT [FK_ccCampsAgente_ccCamps]'	
			EXEC(@sql)
			
			set @process = 'Alter Table - RepSpececialPromises'
			set @sql='if exists (select * from sys.columns where name = N''type'' and Object_ID = Object_ID(N''RepSpececialPromises''))
				ALTER TABLE RepSpececialPromises ALTER COLUMN type VARCHAR(100)'	
			EXEC(@sql)

			set @process = 'Alter Table - RepSpececialCamMovs'
			set @sql='if exists (select * from sys.columns where name = N''nnew'' and Object_ID = Object_ID(N''RepSpececialCamMovs''))
				ALTER TABLE RepSpececialCamMovs ALTER COLUMN nnew INT'	
			EXEC(@sql)
			
			set @process = 'Alter Table - RepSpececialCamMovs'
			set @sql='if exists (select * from sys.columns where name = N''ncallback'' and Object_ID = Object_ID(N''RepSpececialCamMovs''))
				ALTER TABLE RepSpececialCamMovs ALTER COLUMN ncallback INT'	
			EXEC(@sql)
			
			set @process = 'Alter Table - RepSpececialCamMovs'
			set @sql='if exists (select * from sys.columns where name = N''Agents'' and Object_ID = Object_ID(N''RepSpececialCamMovs''))
				ALTER TABLE RepSpececialCamMovs ALTER COLUMN Agents INT'	
			EXEC(@sql)
	
			set @process = 'Alter SP - ccspRepOutAnswCalls'
			if exists (select * from sys.procedures where name = N'ccspRepOutAnswCalls')
				set @sql='ALTER PROCEDURE [dbo].[ccspRepOutAnswCalls]
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
						abnd.IDWG workgroupId, e.WGName workgroup, isnull(f.IDArea,0) areaId, g.AreaName area, total,
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
			else
				set @sql = ''	
			EXEC(@sql)
			
			set @process = 'Alter Sp - ccspRepOutKPI'
			if exists (select * from sys.procedures where name = N'ccspRepOutKPI')
				set @sql='ALTER PROCEDURE [dbo].[ccspRepOutKPI]
					@action as tinyint,
					@from as datetime = null,
					@to as datetime = null
					AS

					if @from is null
						select @from = convert(datetime,convert(varchar(11),getdate()))
					select @to = getdate()

					if @action = 1
					begin
						delete RepOutKPI with(rowlock)
						where date >= @from AND date < @to

						insert into RepOutKPI
						select dateHour, cam_id, '''' as campaign, totalCalls, avgXfer, avgCallTime, c10sec, c20sec, c30sec, cMax, AnsweredCalls, ISNULL((AnsweredCalls * 100.00)/NULLIF(totalCalls,0),0) as AnsweredPctg,
							ComplementCalls as RemainingCalls,  ISNULL((ComplementCalls * 100.00)/NULLIF(totalCalls,0),0) as RemainingPct, AbandonedCalls, ISNULL((AbandonedCalls * 100.00)/NULLIF(totalCalls,0),0) as AbandonedPctg, ISNULL((3600*1.00/NULLIF(totalCalls,0)),0) as AvgTimeBtwCalls, 
								[year], [month], [day],  [hour], [minutes] from (
								select CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) as dateHour,
								calls.cam_id, sum(isnull(total,0)) + sum(isnull(total2,0)) + sum(isnull(total3,0)) as totalCalls,avg(calls.cal_tXfer) as avgXfer, avg(calls.cal_tDialog) as avgCallTime,
								sum(isnull(c10,0)) as c10sec ,sum(isnull(c20,0)) as c20sec ,sum(isnull(c30,0)) as c30sec, sum(isnull(cMax,0)) as cMax,
								sum(isnull(total,0)) as AnsweredCalls, sum(isnull(total2,0)) as ComplementCalls, sum(isnull(total3,0)) as AbandonedCalls,
								datepart(yyyy,max(cal_inicio)) as [year], datepart(mm,max(cal_inicio)) as [month], datepart(dd,max(cal_inicio)) as [day],
								datepart(hh,max(cal_inicio)) as [hour], datepart(mi,max(cal_inicio)) as [minutes]
								from ccocallsout as calls with(nolock)
								left join (
										select count(cal_id) as total,cal_id,cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour,
										case when statusCall_id = 13 and cal_tDialog<=10 then 1 else 0 end C10,
										case when statusCall_id = 13 and cal_tDialog<=20 and cal_tDialog > 10 then 1 else 0 end C20,
										case when statusCall_id = 13 and cal_tDialog<=30 and cal_tDialog > 20 then 1 else 0 end C30,
										case when statusCall_id = 13 and cal_tDialog>30 then 1 else 0 end CMax
										 from ccocallsout with(nolock) where statusCall_id = 13 and cal_inicio >= @from and cal_inicio < @to group by statusCall_id,cal_tDialog,cal_id,cam_id,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 
								) as times 
								on (CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) = times.dateHour and calls.cal_id = times.cal_id ) 
								left join (
										select count(cal_id) as total2, cal_id,cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour
										 from ccocallsout with(index(IX_ccoCallsOut_13),nolock) where statusCall_id not in(13,5) and cal_inicio >= @from and cal_inicio < @to group by statusCall_id,cal_tDialog,cal_id,cam_id,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 
								) as times2 
								on (CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) = times2.dateHour and calls.cal_id = times2.cal_id )
								left join (
										select count(cal_id) as total3, cal_id,cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) as dateHour
										 from ccocallsout with(index(IX_ccoCallsOut_13),nolock) where statusCall_id in(5) and cal_inicio >= @from and cal_inicio < @to group by statusCall_id,cal_tDialog,cal_id,cam_id,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 
								) as times3
								on (CONVERT(smalldatetime,CONVERT(varchar(13),calls.cal_inicio,121)+ '':00'',121) = times2.dateHour and calls.cal_id = times2.cal_id )
								group by calls.cam_id, CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121) 	
								) as tablon

								update RepOutKPI with(rowlock) 
								set campaign = isnull(b.cam_descripcion,'''')
								from RepOutKPI a
								left join ccCamps b
								on a.campaignId = b.cam_id
								where date >= @from AND date < @to
						
					end'	
			else
				set @sql = ''
			EXEC(@sql)
	
			set @process = 'Alter SP - ccspRepSpececialAgent'
			if exists (select * from sys.procedures where name = N'ccspRepSpececialAgent')
				set @sql='ALTER PROCEDURE [dbo].[ccspRepSpececialAgent]
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
						,ISNULL(nd.total,0) ndTime
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
			else
				set @sql = ''
			EXEC(@sql)
	
			set @process = 'Alter SP - ccspRepSpececialAgtPerformance'
			if exists (select * from sys.procedures where name = N'ccspRepSpececialAgtPerformance')
				set @sql='ALTER PROCEDURE [dbo].[ccspRepSpececialAgtPerformance]
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
						left join ccusers us on us.user_id=rcalls.user_id
					end'	
			else
				set @sql = ''
			EXEC(@sql)	
		
			set @process = 'Alter job - ShrinkLogCCReportsRia'
			set @sql='USE [msdb]

				/****** Object:  Job [ShrinkLogCCReportsRia]    Script Date: 10/09/2014 20:55:58 ******/
				IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''ShrinkLogCCReportsRia'')
					EXEC msdb.dbo.sp_delete_job @job_name=N''ShrinkLogCCReportsRia'', @delete_unused_schedule=1

				/****** Object:  Job [ShrinkLogCCReportsRia]    Script Date: 10/09/2014 20:56:23 ******/
				BEGIN TRANSACTION
				DECLARE @ReturnCode INT
				SELECT @ReturnCode = 0
				/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 10/09/2014 20:56:23 ******/
				IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
				BEGIN
				EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

				END

				DECLARE @jobId BINARY(16)
				EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ShrinkLogCCReportsRia'', 
						@enabled=1, 
						@notify_level_eventlog=0, 
						@notify_level_email=0, 
						@notify_level_netsend=0, 
						@notify_level_page=0, 
						@delete_level=0, 
						@description=N''Shrink Log CCReportsRia'', 
						@category_name=N''[Uncategorized (Local)]'', 
						@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				/****** Object:  Step [Check Database Integrity Task]    Script Date: 10/09/2014 20:56:25 ******/
				EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Database Integrity Task'', 
						@step_id=1, 
						@cmdexec_success_code=0, 
						@on_success_action=3, 
						@on_success_step_id=0, 
						@on_fail_action=2, 
						@on_fail_step_id=0, 
						@retry_attempts=0, 
						@retry_interval=0, 
						@os_run_priority=0, @subsystem=N''TSQL'', 
						@command=N''DBCC CHECKDB WITH NO_INFOMSGS'', 
						@database_name=N''ccReportsRia'', 
						@flags=0
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				/****** Object:  Step [Checkpoint DB]    Script Date: 10/09/2014 20:56:25 ******/
				EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Checkpoint DB'', 
						@step_id=2, 
						@cmdexec_success_code=0, 
						@on_success_action=3, 
						@on_success_step_id=0, 
						@on_fail_action=2, 
						@on_fail_step_id=0, 
						@retry_attempts=0, 
						@retry_interval=0, 
						@os_run_priority=0, @subsystem=N''TSQL'', 
						@command=N''CHECKPOINT'', 
						@database_name=N''ccReportsRia'', 
						@flags=0
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				/****** Object:  Step [Shrink Log Task]    Script Date: 10/09/2014 20:56:25 ******/
				EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Shrink Log Task'', 
						@step_id=3, 
						@cmdexec_success_code=0, 
						@on_success_action=1, 
						@on_success_step_id=0, 
						@on_fail_action=2, 
						@on_fail_step_id=0, 
						@retry_attempts=0, 
						@retry_interval=0, 
						@os_run_priority=0, @subsystem=N''TSQL'', 
						@command=N''DBCC SHRINKFILE(''''ccReports_Log'''',1)'', 
						@database_name=N''ccReportsRia'', 
						@flags=0
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Weekly'', 
						@enabled=1, 
						@freq_type=8, 
						@freq_interval=1, 
						@freq_subday_type=1, 
						@freq_subday_interval=0, 
						@freq_relative_interval=1, 
						@freq_recurrence_factor=1, 
						@active_start_date=20000101, 
						@active_end_date=99991231, 
						@active_start_time=10000, 
						@active_end_time=235959
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				COMMIT TRANSACTION
				GOTO EndSave
				QuitWithRollback:
				    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
				EndSave:'	
			EXEC(@sql)
	
			set @process = 'Alter job - DatabaseCentinella'
			set @sql='USE [master]

				if exists (select * from sys.tables where name = ''indexMaintenance'')
					DROP TABLE [dbo].[indexMaintenance]    

				if exists (select * from sys.tables where name = ''logCentinella'')
					DROP TABLE [dbo].[logCentinella]    

				if exists (select * from sys.tables where name = ''userDatabases'')
					DROP TABLE [dbo].[userDatabases]

				USE [msdb]

				if exists (select * from msdb.dbo.sysjobs_view where name = N''DatabaseCentinella'')
					EXEC msdb.dbo.sp_delete_job @job_name=N''DatabaseCentinella'', @delete_unused_schedule=1

				USE [msdb]
				
				/****** Object:  Job [DatabaseCentinella]    Script Date: 15/10/2014 09:25:39 PM ******/
				BEGIN TRANSACTION
				DECLARE @ReturnCode INT
				SELECT @ReturnCode = 0
				/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 15/10/2014 09:25:39 PM ******/
				IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
				BEGIN
				EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

				END

				DECLARE @jobId BINARY(16)
				EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''DatabaseCentinella'', 
						@enabled=1, 
						@notify_level_eventlog=0, 
						@notify_level_email=0, 
						@notify_level_netsend=0, 
						@notify_level_page=0, 
						@delete_level=0, 
						@description=N''Autor: Raymundo Gonzalez
				Fecha: 2014/10/15
				Descripcion:
					Centinela para monitoreo de performance y mantenimiento de las BD de SQL
				'', 
						@category_name=N''[Uncategorized (Local)]'', 
						@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				/****** Object:  Step [DatabaseCentinellaTasks]    Script Date: 15/10/2014 09:25:40 PM ******/
				EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''DatabaseCentinellaTasks'', 
						@step_id=1, 
						@cmdexec_success_code=0, 
						@on_success_action=1, 
						@on_success_step_id=0, 
						@on_fail_action=2, 
						@on_fail_step_id=0, 
						@retry_attempts=0, 
						@retry_interval=0, 
						@os_run_priority=0, @subsystem=N''TSQL'', 
						@command=N''use [master]

				set nocount on

				declare @idDb int
				declare @dbName nvarchar(100)
				declare @dbLog nvarchar(100)
				declare @sql nvarchar(max)
				declare @idIndex int
				declare @tableName nvarchar(100)
				declare @indexName nvarchar(100)
				declare @process int
				declare @firstSunday datetime
				declare @idCmdSql int
				declare @cmdSql nvarchar(max)
				declare @maxTimeSeconds int
				declare @maxTimeSecondsSunday int
				declare @dateExecution datetime

				set @idDb = 0
				set @dbName = ''''''''
				set @dbLog = ''''''''
				set @sql = ''''''''
				set @idIndex = 0
				set @tableName = ''''''''
				set @indexName = ''''''''
				set @process = 1
				set @firstSunday = DATEADD(WEEKDAY,(8-(DATEPART(WEEKDAY,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))))%7,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))
				set @idCmdSql = 0
				set @cmdSql = ''''''''
				set @maxTimeSeconds = 7200
				set @maxTimeSecondsSunday = 14400
				set @dateExecution = getdate()

				if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
					begin
						if exists (select * from sys.tables where name = ''''userDatabases'''')
							drop table userDatabases

						if exists (select * from sys.tables where name = ''''indexMaintenance'''')
							drop table indexMaintenance

						if exists (select * from sys.tables where name = ''''logCentinella'''')
							drop table logCentinella
					end

				if not exists (select * from sys.tables where name = ''''userDatabases'''')
					begin
						create table dbo.userDatabases(
							[idDb] int not null identity primary key,
							[dbName] nvarchar(100) not null,
							[dbLog] nvarchar(100) not null,
							[status] bit not null
						)

						CREATE NONCLUSTERED INDEX [IX_userDatabases1] ON [dbo].[userDatabases]
						(
							[dbName] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

						CREATE NONCLUSTERED INDEX [IX_userDatabases2] ON [dbo].[userDatabases]
						(
							[status] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					end

				if not exists (select * from sys.tables where name = ''''indexMaintenance'''')
					begin
						create table dbo.indexMaintenance(
							[idIndex] int not null identity primary key,
							[dbName] nvarchar(100) not null,
							[tableName] nvarchar(100) not null,
							[indexName] nvarchar(100) not null,
							[indexType] nvarchar(100) not null,
							[indexFragmentation] nvarchar(100) not null,
							[status] bit not null
						)

						CREATE NONCLUSTERED INDEX [IX_indexMaintenance1] ON [dbo].[indexMaintenance]
						(
							[dbName] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

						CREATE NONCLUSTERED INDEX [IX_indexMaintenance2] ON [dbo].[indexMaintenance]
						(
							[tableName] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

						CREATE NONCLUSTERED INDEX [IX_indexMaintenance3] ON [dbo].[indexMaintenance]
						(
							[status] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					end

				if not exists (select * from sys.tables where name = ''''logCentinella'''')
					begin
						create table dbo.logCentinella(
							[idCmdSql] int not null identity primary key,
							[date] datetime not null,
							[cmdSql] nvarchar(max) not null,
							[status] int not null,
							[dateStart] datetime not null,
							[dateEnd] datetime not null,
							[executionTimeSeconds] int not null
						)

						CREATE NONCLUSTERED INDEX [IX_logCentinella1] ON [dbo].[logCentinella]
						(
							[date] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

						CREATE NONCLUSTERED INDEX [IX_logCentinella2] ON [dbo].[logCentinella]
						(
							[status] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					end

				insert into userDatabases
				select db_name(database_id), '''''''', 0
				from sys.master_files
				where state = 0 
				and has_dbaccess(db_name(database_id)) = 1
				and db_name(database_id) NOT IN (''''master'''', ''''tempdb'''', ''''model'''', ''''msdb'''', ''''resource'''', ''''distribution'''', ''''reportservice'''', ''''reportservicetempdb'''')
				and type = 0

				update userDatabases
				set [dbLog] = name
				from sys.master_files
				inner join userDatabases on (db_name(database_id) = [dbName] and type = 1)

				while (select count(*) from userDatabases where status = 0) > 0
					begin
						set rowcount 1
							select @idDb = idDb, @dbName = dbName from userDatabases where status = 0 order by idDb
						set rowcount 0

						select @sql = ''''use ['''' + @dbName + ''''] 

				insert into master.dbo.indexMaintenance
				SELECT '''''''''''' + @dbName + '''''''''''', OBJECT_NAME(ind.OBJECT_ID), ind.name, indexstats.index_type_desc, indexstats.avg_fragmentation_in_percent, 0
				FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats 
				INNER JOIN sys.indexes ind ON (ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id and ind.type > 0)
				inner join sysobjects obj on (obj.id = indexstats.object_id and xtype=''''''''U'''''''' and category = 0)
				WHERE indexstats.avg_fragmentation_in_percent > 30 
				ORDER BY OBJECT_NAME(ind.OBJECT_ID), ind.name''''

						exec(@sql)

						update userDatabases
						set status = 1
						where idDb = @idDb
					end

				while (select count(*) from indexMaintenance where status = 0) > 0
					begin
						set rowcount 1
							select @idIndex = idIndex, @dbName = dbName, @tableName = tableName, @indexName = indexName from indexMaintenance where status = 0 order by idIndex
						set rowcount 0

						select @sql = ''''use ['''' + @dbName + ''''] ''''

						if @process = 1
								select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REORGANIZE WITH ( LOB_COMPACTION = ON )'''' 
						else if @process = 2
								select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )'''' 
						else if @process = 3
								select @sql = @sql + ''''UPDATE STATISTICS [dbo].['''' + @tableName + ''''] WITH FULLSCAN'''' 

						insert into logCentinella
						select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

						if @process < 3
							update indexMaintenance set status = 1 where idIndex = @idIndex
						else
							update indexMaintenance set status = 1 where dbName = @dbName and tableName = @tableName

						if @process < 3
							begin
								if (select count(*) from indexMaintenance where status = 0) = 0
									begin
										update indexMaintenance 
										set status = 0

										set @process = @process + 1
									end
							end
					end

				if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
					begin
						update userDatabases
						set status = 0

						while (select count(*) from userDatabases where status = 0) > 0
							begin
								set rowcount 1
									select @idDb = idDb, @dbName = dbName, @dbLog = dbLog from userDatabases where status = 0 order by idDb
								set rowcount 0

								select @sql = ''''use ['''' + @dbName + ''''] DBCC CHECKDB WITH NO_INFOMSGS''''
								
								insert into logCentinella
								select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0
								
								select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKDATABASE(N'''''''''''' + @dbName + '''''''''''', 10, TRUNCATEONLY)''''
								
								insert into logCentinella
								select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

								select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKFILE('''''''''''' + @dbLog + '''''''''''',1)''''

								insert into logCentinella
								select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

								select @sql = ''''use [master] 

				DECLARE @currentdate datetime
				declare @date varchar(200)
				declare @rutaBak as nvarchar(2000)

				set @currentdate = CURRENT_TIMESTAMP
				select @date = '''''''''''' + @dbName + ''''_Backup_Centinella_'''''''' + convert(varchar(19),dateadd(ww,-3,getdate()),112) + ''''''''.bak''''''''

				create table #RutaBak(
				Value nvarchar(2000) not null,
				Data nvarchar(2000) not null)

				insert into #RutaBak
				EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

				select @rutaBak = Data
				from #RutaBak

				select @rutaBak= @rutaBak + ''''''''\'''''''' + @date

				drop table #RutaBak

				BACKUP DATABASE ['''' + @dbName + ''''] TO  DISK = @rutaBak WITH NOFORMAT, NOINIT,  NAME = @date, SKIP, REWIND, NOUNLOAD,  STATS = 10''''

								insert into logCentinella
								select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

								update userDatabases
								set status = 1
								where idDb = @idDb
							end

						select @sql = ''''use [master] 

				DECLARE @currentdate datetime
				declare @date datetime
				declare @rutaBak as nvarchar(2000)

				set @currentdate = CURRENT_TIMESTAMP
				select @date = dateadd(ww,-3,getdate())

				create table #RutaBak(
				Value nvarchar(2000) not null,
				Data nvarchar(2000) not null)

				insert into #RutaBak
				EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

				select @rutaBak = Data
				from #RutaBak

				EXECUTE master.dbo.xp_delete_file 0,@rutaBak,N''''''''bak'''''''',@date

				drop table #RutaBak''''

						insert into logCentinella
						select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

					end

				set @dateExecution = getdate()

				while (select count(*) from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate()))) > 0
					begin
						set rowcount 1
							select @idCmdSql = idCmdSql, @cmdSql = cmdSql from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate())) order by idCmdSql
						set rowcount 0
						
						update logCentinella
						set dateStart = getdate()
						where idCmdSql = @idCmdSql	

						exec(@cmdSql)

						WAITFOR DELAY ''''00:00:01''''

						while(SELECT count(*)
								FROM sys.dm_exec_requests a 
								INNER JOIN sys.dm_exec_connections b       
								ON a.session_id = b.session_id       
								INNER JOIN sys.dm_exec_sessions c        
								ON c.session_id = a.session_id       
								CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d       
								WHERE a.session_id > 50   
								AND a.session_id = @@SPID
								and d.text = @cmdSql) > 0
							begin
								WAITFOR DELAY ''''00:00:01''''
							end

						if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
							begin
								if((datediff(ss,@dateExecution,getdate())) > @maxTimeSecondsSunday)
									BREAK
							end
						else
							begin
								if((datediff(ss,@dateExecution,getdate())) > @maxTimeSeconds)
									BREAK
							end

						update logCentinella
						set status = 1, dateEnd = getdate(), executionTimeSeconds = datediff(ss,dateStart,getdate())
						where idCmdSql = @idCmdSql
					end

				delete userDatabases
				delete indexMaintenance'', 
						@database_name=N''master'', 
						@flags=0
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''DatabaseCentinellaSchedule'', 
						@enabled=1, 
						@freq_type=4, 
						@freq_interval=1, 
						@freq_subday_type=1, 
						@freq_subday_interval=0, 
						@freq_relative_interval=0, 
						@freq_recurrence_factor=0, 
						@active_start_date=20140724, 
						@active_end_date=99991231, 
						@active_start_time=10000, 
						@active_end_time=235959
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
				COMMIT TRANSACTION
				GOTO EndSave
				QuitWithRollback:
				    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
				EndSave:'	
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