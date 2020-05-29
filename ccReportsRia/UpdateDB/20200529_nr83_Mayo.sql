SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 83

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'Alter SP ccspGenSession correcion ccspGenSession para logout'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspGenSession]
@from as smalldatetime,
@to as smalldatetime
AS
set nocount on

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
where A.TipoMov=1
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



SELECT TOP 0 * INTO #temp_ccGenSession FROM #tempccGenSession

INSERT INTO #temp_ccGenSession (Fila,[user_id], extension, login, logout)
select ROW_NUMBER() OVER(ORDER BY login)+1000 Fila,
user_id, ext, login, logout
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
FROM #tempccGenSession b
INNER JOIN #tempccGenSession a on a.user_id = b.user_id and a.login = b.login and a.logout <> b.logout


select user_id, [login],[logout],extension from #tempccGenSession

DROP TABLE #temp_ccGenSession
drop table #tempccGenSession
drop table #temUserIdLogoutNull
drop table #temIdMaxLogoutNull


return(0)
set nocount off'
		EXEC(@sql)

		SET @process = 'Alter SP ccspRepIVRSurveys CW-4072-Reporte Encuestas IVR'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepIVRSurveys]
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
	inner join (IVROptions ivro inner join (select distinct cal_id,questionId,max(date) date from ivroptions group by cal_id,questionId)ivro2 on ivro.cal_id=ivro2.cal_id and ivro.date=ivro2.date) on cci.cal_id = ivro.cal_id
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
	inner join (IVROptions ivro inner join (select distinct cal_id,questionId,max(date) date from ivroptions group by cal_id,questionId)ivro2 on ivro.cal_id=ivro2.cal_id and ivro.date=ivro2.date) on cco.cal_id = ivro.cal_id
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
end'
		EXEC(@sql)


		
		SET @process = 'CW-Update MDF JOB ReportsMasterProcess'
		SET @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''ReportsMasterProcess'') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcess'', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcess'', 
		@enabled=1, 
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''ReportsMasterProcess'', 
		@category_name=N''Nuxiba'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0,  @subsystem=N''TSQL'', 
		@command=N''EXEC ReportsMasterProcess'',
		@database_name=N''ccReportsRia'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''RepotsMasterProcess'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130912, 
		@active_end_date=99991231, 
		@active_start_time=0,  
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

		SET @process = 'CW-Update MDF JOB ReportsMasterProcessPublicationHighLoad'
		SET @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''ReportsMasterProcessPublicationHighLoad'') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessPublicationHighLoad'', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcessPublicationHighLoad'', 
		@enabled=1, 
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''ReportsMasterProcess'', 
		@category_name=N''Nuxiba'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0,  @subsystem=N''TSQL'', 
		@command=N''EXEC ReportsMasterProcessPublicationHighLoad'',
		@database_name=N''ccReportsRia'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''RepotsMasterProcess'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130912, 
		@active_end_date=99991231, 
		@active_start_time=0,  
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

		SET @process = 'CW-Update MDF JOB ReportsMasterProcessPublicationLowLoad'
		SET @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''ReportsMasterProcessPublicationLowLoad'') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessPublicationLowLoad'', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcessPublicationLowLoad'', 
		@enabled=1, 
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''ReportsMasterProcess'', 
		@category_name=N''Nuxiba'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0,  @subsystem=N''TSQL'', 
		@command=N''EXEC ReportsMasterProcessPublicationLowLoad'',
		@database_name=N''ccReportsRia'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''RepotsMasterProcess'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130912, 
		@active_end_date=99991231, 
		@active_start_time=0,  
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

		SET @process = 'CW-Update MDF JOB ReportsMasterProcessYesterday'
		SET @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''ReportsMasterProcessYesterday'') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessYesterday'', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcessYesterday'', 
		@enabled=1, 
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''ReportsMasterProcess'', 
		@category_name=N''Nuxiba'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0,  @subsystem=N''TSQL'', 
		@command=N''EXEC ReportsMasterProcess'',
		@database_name=N''ccReportsRia'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''
declare @from datetime
declare @hour varchar(10)
set @hour =''03:00''
select @from= convert(datetime, convert(varchar(11),get'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130912, 
		@active_end_date=99991231, 
		@active_start_time=30000,  
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
