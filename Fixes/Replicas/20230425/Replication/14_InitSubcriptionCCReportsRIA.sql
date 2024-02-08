set nocount on

use [CCReportsRIA]

SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 104

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion >= @version
 begin
 	BEGIN TRAN

	BEGIN TRY

	set @process = 'Drop Table migration'
	set @Sql = '--

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE [name] = ''migration'')
BEGIN
	drop table migration
END	'
	EXEC(@Sql)

	set @process = 'CREATE Table migration'
	set @Sql = 'IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE [name] = ''migration'')
BEGIN
	CREATE TABLE [dbo].[migration](
	[id] [int] NOT NULL,
	[description] [varchar](255) NOT NULL,		
	[status] [int] NOT NULL,
	[error] [nvarchar](max) NOT NULL,
	[dateStart] datetime NOT NULL,
	[dateEnd] datetime NOT NULL,
	[db_name] [sysname] NULL,
	) ON [PRIMARY]		
END
truncate table migration;

insert into migration
select
ROW_NUMBER() OVER(ORDER BY B.name desc)+99 AS id, B.name as [description],0 as status,'''' as error,''1901-01-01'' as dateStart,''1901-01-01'' as dateEnd
,null db_name

from sysmergesubscriptions A
inner join sysmergepublications B on A.pubid=B.pubid
where A.db_name in(''CCReportsRIA'')
order by B.name,A.db_name


;with dbNamePublication as(

select A.description,s.db_name,S.status 
from migration A
inner join sysmergepublications B on A.description=B.name
inner join sysmergesubscriptions S on B.pubid=S.pubid 
where S.db_name in(''CCenterRIA'',''CCRecorderRIA'')
)
update M
set M.db_name=A.db_name
from dbNamePublication A
inner join migration M on A.description=M.description
'
	EXEC(@Sql)

	set @Sql = 'exec msdb..sp_update_job @job_name = ''ReportsMasterProcess'', @enabled = 0 --Enable
exec msdb..sp_update_job @job_name = ''ReportMasterProcessGenerateLow'', @enabled = 0 --Enable
exec msdb..sp_update_job @job_name = ''ReportsMasterProcessPublicationHighLoad'', @enabled = 0 --Enable
exec msdb..sp_update_job @job_name = ''ReportsMasterProcessPublicationLowLoad'', @enabled = 0 --Enable
exec msdb..sp_update_job @job_name = ''ReportsMasterProcessYesterday'', @enabled = 0 --Enable
'
		EXEC(@Sql)

	set @process = 'Create Job CW_Merge_Replication_CCreportsRIA'
	set @Sql='USE [msdb]

if exists( select * from msdb.dbo.sysjobs where name=''CW_Merge_Replication_CCreportsRIA'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW_Merge_Replication_CCreportsRIA'', @delete_unused_schedule=1

/****** Object:  Job [CW Merge Replication]    Script Date: 23/06/2018 11:12:45 a.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW_Merge_Replication_CCreportsRIA'', 
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

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW_Merge_Replication_CCreportsRIA'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''
declare @id int,@i int
declare @publicationName varchar(max),@dbName sysname,@jobName varchar(max)
declare @dateStart datetime,@dateNow datetime
declare @statusSubcription int
declare @maxId int

select @maxId=isnull(max(id),1),@id=0,@i=0,@dateNow =getdate()
FROM migration


while DATEDIFF(ss,@dateNow,getdate())<59  and
 exists(select * FROM migration where status in(0,1))
and @id<= @maxId

begin
	select top 1 @publicationName=[description],  @dateStart  = dateStart,@dbName =[db_name],@id=id 
	from migration 
	where status in(0,1) and id>=@id
	order by id
				
	------ Revisa si ya se genero la primera subcripcion ------
	select @statusSubcription= S.status
	from sysmergepublications B 
	inner join sysmergesubscriptions S on B.pubid=S.pubid 		
	where S.db_name =DB_NAME() and B.name=@publicationName

	if @statusSubcription=1 begin
		select @statusSubcription,* from migration  where id=@id

		update migration with (rowlock) set [status] = 2,dateStart=GETDATE(), [dateEnd] = getdate() where id=@id
		set @i=@i+1
		set @id=@id+1			

		continue;
	end

	select @jobName= A.[name] from msdb.dbo.sysjobs A 		
	where A.[name] like ''''%''''+DB_NAME()+''''- 0%'''' and A.[name] like ''''%''''+@dbName+''''%''''
	and A.[name] like ''''%''''+@publicationName+''''-%''''


	
	update migration with (rowlock) set [status] = 1, [dateStart] = getdate() where id=@id
	exec msdb.dbo.sp_start_job @job_name = @jobName

		WAITFOR DELAY ''''00:00:01''''   

		while exists(
		select S.status
		from sysmergepublications B 
		inner join sysmergesubscriptions S on B.pubid=S.pubid 		
		where S.db_name =DB_NAME() and B.name=@publicationName
		and S.status<>1
		) 
	begin   
		WAITFOR DELAY ''''00:00:01''''
		print ''''In Progress Job in ReplicationName: ''''+@jobName        
		if DATEDIFF(ss,@dateNow,getdate())>59 begin
			select @publicationName publicationName, @jobName jobName
			break;
		end
	end
		print ''''Progress End Job in ReplicationName: ''''+@jobName

	select @statusSubcription= S.status
	from sysmergepublications B 
	inner join sysmergesubscriptions S on B.pubid=S.pubid 		
	where S.db_name =DB_NAME() and B.name=@publicationName
	and S.status<>1

	WAITFOR DELAY ''''00:00:01''''

	if @statusSubcription=1 begin	
		update migration with (rowlock) set [status] = 2, [dateEnd] = getdate() where id=@id
	end
		
	set @i=@i+1
	set @id=@id+1
		
end
select @dateNow, DATEDIFF(ss,@dateNow,getdate())


if not exists(select * from migration where status in(0,1)) begin
	exec msdb..sp_update_job @job_name = ''''ReportsMasterProcess'''', @enabled = 1 --Enable
	exec msdb..sp_update_job @job_name = ''''ReportsMasterProcessPublicationHighLoad'''', @enabled = 1 --Enable
	exec msdb..sp_update_job @job_name = ''''ReportsMasterProcessPublicationLowLoad'''', @enabled = 1 --Enable
	exec msdb..sp_update_job @job_name = ''''ReportsMasterProcessYesterday'''', @enabled = 1 --Enable
	exec msdb..sp_update_job @job_name = ''''ReportsMasterSubProcess'''', @enabled = 1 --Enable
	exec msdb..sp_update_job @job_name = ''''ReportMasterProcessGenerateLow'''', @enabled = 1 --Enable
	exec msdb..sp_update_job @job_name = ''''CW_Merge_Replication_CCreportsRIA'''', @enabled = 0 --Disable

	if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccoLogDials'''' and object_id = OBJECT_ID(N''''ccoLogDials'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccoLogDials''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoLogDials] on [dbo].[ccoLogDials](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccLogAgentesDia'''' and object_id = OBJECT_ID(N''''ccLogAgentesDia'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccLogAgentesDia''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccLogAgentesDia] on [dbo].[ccLogAgentesDia](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_RiaMarkHold'''' and object_id = OBJECT_ID(N''''RiaMarkHold'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''RiaMarkHold''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RiaMarkHold] on [dbo].[RiaMarkHold](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccoCallsOutSource'''' and object_id = OBJECT_ID(N''''ccoCallsOutSource'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccoCallsOutSource''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoCallsOutSource] on [dbo].[ccoCallsOutSource](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccoCallsPreviewData'''' and object_id = OBJECT_ID(N''''ccoCallsPreviewData'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccoCallsPreviewData''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoCallsPreviewData] on [dbo].[ccoCallsPreviewData](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_RegProcessPreviewRecord'''' and object_id = OBJECT_ID(N''''RegProcessPreviewRecord'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''RegProcessPreviewRecord''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_RegProcessPreviewRecord] on [dbo].[RegProcessPreviewRecord](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccoCallsOut'''' and object_id = OBJECT_ID(N''''ccoCallsOut'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccoCallsOut''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoCallsOut] on [dbo].[ccoCallsOut](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccCallsIn'''' and object_id = OBJECT_ID(N''''ccCallsIn'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccCallsIn''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCallsIn] on [dbo].[ccCallsIn](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_DataCallIn'''' and object_id = OBJECT_ID(N''''DataCallIn'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''DataCallIn''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_DataCallIn] on [dbo].[DataCallIn](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_cctipocalifsubout'''' and object_id = OBJECT_ID(N''''cctipocalifsubout'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''cctipocalifsubout''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipocalifsubout] on [dbo].[cctipocalifsubout](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_cctipocalifsub'''' and object_id = OBJECT_ID(N''''cctipocalifsub'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''cctipocalifsub''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipocalifsub] on [dbo].[cctipocalifsub](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_cctiposubcalifrel'''' and object_id = OBJECT_ID(N''''cctiposubcalifrel'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''cctiposubcalifrel''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctiposubcalifrel] on [dbo].[cctiposubcalifrel](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccCampsMovs'''' and object_id = OBJECT_ID(N''''ccCampsMovs'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccCampsMovs''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCampsMovs] on [dbo].[ccCampsMovs](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_telefonosConferencia'''' and object_id = OBJECT_ID(N''''telefonosConferencia'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''telefonosConferencia''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_telefonosConferencia] on [dbo].[telefonosConferencia](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_telefonosTransferencia'''' and object_id = OBJECT_ID(N''''telefonosTransferencia'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''telefonosTransferencia''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_telefonosTransferencia] on [dbo].[telefonosTransferencia](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_messageStatus'''' and object_id = OBJECT_ID(N''''messageStatus'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''messageStatus''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageStatus] on [dbo].[messageStatus](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccriacat_areas'''' and object_id = OBJECT_ID(N''''ccriacat_areas'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccriacat_areas''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriacat_areas] on [dbo].[ccriacat_areas](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccinboundagentes'''' and object_id = OBJECT_ID(N''''ccinboundagentes'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccinboundagentes''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccinboundagentes] on [dbo].[ccinboundagentes](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccriaareaworkgroup'''' and object_id = OBJECT_ID(N''''ccriaareaworkgroup'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccriaareaworkgroup''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriaareaworkgroup] on [dbo].[ccriaareaworkgroup](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccsupervisorcam'''' and object_id = OBJECT_ID(N''''ccsupervisorcam'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccsupervisorcam''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccsupervisorcam] on [dbo].[ccsupervisorcam](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccCampsAgente'''' and object_id = OBJECT_ID(N''''ccCampsAgente'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccCampsAgente''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCampsAgente] on [dbo].[ccCampsAgente](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_cclogagentesnotready'''' and object_id = OBJECT_ID(N''''cclogagentesnotready'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''cclogagentesnotready''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cclogagentesnotready] on [dbo].[cclogagentesnotready](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccloglogin'''' and object_id = OBJECT_ID(N''''ccloglogin'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccloglogin''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccloglogin] on [dbo].[ccloglogin](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_cccallsreject'''' and object_id = OBJECT_ID(N''''cccallsreject'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''cccallsreject''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cccallsreject] on [dbo].[cccallsreject](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccLogtransfers'''' and object_id = OBJECT_ID(N''''ccLogtransfers'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccLogtransfers''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccLogtransfers] on [dbo].[ccLogtransfers](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccChannelTransfer'''' and object_id = OBJECT_ID(N''''ccChannelTransfer'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccChannelTransfer''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccChannelTransfer] on [dbo].[ccChannelTransfer](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ivrstructure'''' and object_id = OBJECT_ID(N''''ivrstructure'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ivrstructure''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ivrstructure] on [dbo].[ivrstructure](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ivrcallsin'''' and object_id = OBJECT_ID(N''''ivrcallsin'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ivrcallsin''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ivrcallsin] on [dbo].[ivrcallsin](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ivroptions'''' and object_id = OBJECT_ID(N''''ivroptions'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ivroptions''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ivroptions] on [dbo].[ivroptions](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_Survey'''' and object_id = OBJECT_ID(N''''Survey'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''SurveyeName''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_Survey] on [dbo].[Survey](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_SurveyQuestion'''' and object_id = OBJECT_ID(N''''SurveyQuestion'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''SurveyQuestion''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_SurveyQuestion] on [dbo].[SurveyQuestion](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_SurveyAnswer'''' and object_id = OBJECT_ID(N''''SurveyAnswer'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''SurveyAnswer''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_SurveyAnswer] on [dbo].[SurveyAnswer](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_relationSurveyQuestion'''' and object_id = OBJECT_ID(N''''relationSurveyQuestion'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''relationSurveyQuestion''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_relationSurveyQuestion] on [dbo].[relationSurveyQuestion](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_relationQuestionAnswer'''' and object_id = OBJECT_ID(N''''relationQuestionAnswer'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''relationQuestionAnswer''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_relationQuestionAnswer] on [dbo].[relationQuestionAnswer](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_cctipoResultadodial'''' and object_id = OBJECT_ID(N''''cctipoResultadodial'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''cctipoResultadodial''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipoResultadodial] on [dbo].[cctipoResultadodial](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_cctiponotready'''' and object_id = OBJECT_ID(N''''cctiponotready'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''cctiponotready''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctiponotready] on [dbo].[cctiponotready](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccodialers'''' and object_id = OBJECT_ID(N''''ccodialers'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccodialers''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccodialers] on [dbo].[ccodialers](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccdnis'''' and object_id = OBJECT_ID(N''''ccdnis'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccdniseName''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccdnis] on [dbo].[ccdnis](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccstatusllamada'''' and object_id = OBJECT_ID(N''''ccstatusllamada'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccstatusllamada''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccstatusllamada] on [dbo].[ccstatusllamada](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_cstoprovedor'''' and object_id = OBJECT_ID(N''''cstoprovedor'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''cstoprovedor''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cstoprovedor] on [dbo].[cstoprovedor](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_cstotipollamada'''' and object_id = OBJECT_ID(N''''cstotipollamada'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''cstotipollamada''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cstotipollamada] on [dbo].[cstotipollamada](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_cstotarifa'''' and object_id = OBJECT_ID(N''''cstotarifa'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''cstotarifa''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cstotarifa] on [dbo].[cstotarifa](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccRIARegistryLists'''' and object_id = OBJECT_ID(N''''ccRIARegistryLists'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccRIARegistryLists''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIARegistryLists] on [dbo].[ccRIARegistryLists](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccCallCost_RIA'''' and object_id = OBJECT_ID(N''''ccCallCost_RIA'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccCallCost_RIA''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCallCost_RIA] on [dbo].[ccCallCost_RIA](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccEstadosAni'''' and object_id = OBJECT_ID(N''''ccEstadosAni'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccEstadosAni''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccEstadosAni] on [dbo].[ccEstadosAni](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccTypeProcessPreview'''' and object_id = OBJECT_ID(N''''ccTypeProcessPreview'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccTypeProcessPreview''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccTypeProcessPreview] on [dbo].[ccTypeProcessPreview](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccLogAgentesDia_Dialog'''' and object_id = OBJECT_ID(N''''ccLogAgentesDia_Dialog'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccLogAgentesDia_Dialog''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccLogAgentesDia_Dialog] on [dbo].[ccLogAgentesDia_Dialog](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccoCallbacks'''' and object_id = OBJECT_ID(N''''ccoCallbacks'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccoCallbacks''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccoCallbacks] on [dbo].[ccoCallbacks](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccRIACallBack_Queue'''' and object_id = OBJECT_ID(N''''ccRIACallBack_Queue'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccRIACallBack_Queue''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIACallBack_Queue] on [dbo].[ccRIACallBack_Queue](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccriachats'''' and object_id = OBJECT_ID(N''''ccriachats'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccriachats''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriachats] on [dbo].[ccriachats](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccriachatstatus'''' and object_id = OBJECT_ID(N''''ccriachatstatus'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccriachatstatus''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriachatstatus] on [dbo].[ccriachatstatus](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccinbound'''' and object_id = OBJECT_ID(N''''ccinbound'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccinbound''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccinbound] on [dbo].[ccinbound](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_cctipocalif'''' and object_id = OBJECT_ID(N''''cctipocalif'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''cctipocalif''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipocalif] on [dbo].[cctipocalif](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccUsers'''' and object_id = OBJECT_ID(N''''ccUsers'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccUsersame''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccUsers] on [dbo].[ccUsers](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccUsers_Consulta'''' and object_id = OBJECT_ID(N''''ccUsers_Consulta'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccUsers_Consulta''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccUsers_Consulta] on [dbo].[ccUsers_Consulta](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_cccamps'''' and object_id = OBJECT_ID(N''''cccamps'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''cccampsame''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cccamps] on [dbo].[cccamps](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccriacat_workgroup'''' and object_id = OBJECT_ID(N''''ccriacat_workgroup'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccriacat_workgroup''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriacat_workgroup] on [dbo].[ccriacat_workgroup](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccriaworkgroupusers'''' and object_id = OBJECT_ID(N''''ccriaworkgroupusers'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccriaworkgroupusers''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccriaworkgroupusers] on [dbo].[ccriaworkgroupusers](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_cctipocalifout'''' and object_id = OBJECT_ID(N''''cctipocalifout'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''cctipocalifout''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_cctipocalifout] on [dbo].[cctipocalifout](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccBaseXDB'''' and object_id = OBJECT_ID(N''''ccBaseXDB'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccBaseXDB''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccBaseXDB] on [dbo].[ccBaseXDB](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccRIAWorkGroup_Calid'''' and object_id = OBJECT_ID(N''''ccRIAWorkGroup_Calid'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccRIAWorkGroup_Calid''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIAWorkGroup_Calid] on [dbo].[ccRIAWorkGroup_Calid](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccRIACampEspWG'''' and object_id = OBJECT_ID(N''''ccRIACampEspWG'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccRIACampEspWG''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIACampEspWG] on [dbo].[ccRIACampEspWG](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccCalifCamp'''' and object_id = OBJECT_ID(N''''ccCalifCamp'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccCalifCamp''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccCalifCamp] on [dbo].[ccCalifCamp](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccPosicion'''' and object_id = OBJECT_ID(N''''ccPosicion'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccPosicion''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccPosicion] on [dbo].[ccPosicion](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccRIACampsGraph'''' and object_id = OBJECT_ID(N''''ccRIACampsGraph'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccRIACampsGraph''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIACampsGraph] on [dbo].[ccRIACampsGraph](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccRIAGraphics'''' and object_id = OBJECT_ID(N''''ccRIAGraphics'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccRIAGraphics''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIAGraphics] on [dbo].[ccRIAGraphics](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccRIAInboundGraph'''' and object_id = OBJECT_ID(N''''ccRIAInboundGraph'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccRIAInboundGraph''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIAInboundGraph] on [dbo].[ccRIAInboundGraph](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccRIACampEspWGConsulta'''' and object_id = OBJECT_ID(N''''ccRIACampEspWGConsulta'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccRIACampEspWGConsulta''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIACampEspWGConsulta] on [dbo].[ccRIACampEspWGConsulta](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccRIAWorkGroupUsersConsulta'''' and object_id = OBJECT_ID(N''''ccRIAWorkGroupUsersConsulta'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccRIAWorkGroupUsersConsulta''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccRIAWorkGroupUsersConsulta] on [dbo].[ccRIAWorkGroupUsersConsulta](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccSettings'''' and object_id = OBJECT_ID(N''''ccSettings'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccSettings''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccSettings] on [dbo].[ccSettings](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccMenus'''' and object_id = OBJECT_ID(N''''ccMenus'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccMenusame''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccMenus] on [dbo].[ccMenus](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccMenuUser'''' and object_id = OBJECT_ID(N''''ccMenuUser'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccMenuUser''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccMenuUser] on [dbo].[ccMenuUser](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_conversation'''' and object_id = OBJECT_ID(N''''conversation'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''conversation''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_conversation] on [dbo].[conversation](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_message'''' and object_id = OBJECT_ID(N''''message'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''messageame''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_message] on [dbo].[message](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_messageUnAssigned'''' and object_id = OBJECT_ID(N''''messageUnAssigned'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''messageUnAssigned''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageUnAssigned] on [dbo].[messageUnAssigned](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_relationMessageDispositionTwit'''' and object_id = OBJECT_ID(N''''relationMessageDispositionTwit'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''relationMessageDispositionTwit''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_relationMessageDispositionTwit] on [dbo].[relationMessageDispositionTwit](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_messageUnAssingedTwit'''' and object_id = OBJECT_ID(N''''messageUnAssingedTwit'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''messageUnAssingedTwit''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageUnAssingedTwit] on [dbo].[messageUnAssingedTwit](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_messageOutTwitter'''' and object_id = OBJECT_ID(N''''messageOutTwitter'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''messageOutTwitter''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageOutTwitter] on [dbo].[messageOutTwitter](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_conversationTwitter'''' and object_id = OBJECT_ID(N''''conversationTwitter'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''conversationTwitter''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_conversationTwitter] on [dbo].[conversationTwitter](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_searchConversationTwitter'''' and object_id = OBJECT_ID(N''''searchConversationTwitter'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''searchConversationTwitter''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_searchConversationTwitter] on [dbo].[searchConversationTwitter](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_messageInTwitter'''' and object_id = OBJECT_ID(N''''messageInTwitter'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''messageInTwitter''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_messageInTwitter] on [dbo].[messageInTwitter](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccWhatsAppConversations'''' and object_id = OBJECT_ID(N''''ccWhatsAppConversations'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccWhatsAppConversations''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccWhatsAppConversations] on [dbo].[ccWhatsAppConversations](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccWhatsAppSpam'''' and object_id = OBJECT_ID(N''''ccWhatsAppSpam'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccWhatsAppSpam''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccWhatsAppSpam] on [dbo].[ccWhatsAppSpam](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccWAMessagesConversations'''' and object_id = OBJECT_ID(N''''ccWAMessagesConversations'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccWAMessagesConversations''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccWAMessagesConversations] on [dbo].[ccWAMessagesConversations](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_ccWhatsAppConversationsRelationship'''' and object_id = OBJECT_ID(N''''ccWhatsAppConversationsRelationship'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''ccWhatsAppConversationsRelationship''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_ccWhatsAppConversationsRelationship] on [dbo].[ccWhatsAppConversationsRelationship](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_contactMeanIn'''' and object_id = OBJECT_ID(N''''contactMeanIn'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''contactMeanIn''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_contactMeanIn] on [dbo].[contactMeanIn](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_smsccoLogDial'''' and object_id = OBJECT_ID(N''''smsccoLogDial'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''smsccoLogDial''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_smsccoLogDial] on [dbo].[smsccoLogDial](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_smsOutSource'''' and object_id = OBJECT_ID(N''''smsOutSource'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''smsOutSource''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_smsOutSource] on [dbo].[smsOutSource](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end
if not exists (select * from sys.indexes where name = N''''MSmerge_index_smsoutSourceMessage'''' and object_id = OBJECT_ID(N''''smsoutSourceMessage'''')) 
and exists (select * from sys.columns where name = N''''rowguid'''' and Object_ID = Object_ID(N''''smsoutSourceMessage''''))
begin
CREATE UNIQUE NONCLUSTERED INDEX [MSmerge_index_smsoutSourceMessage] on [dbo].[smsoutSourceMessage](
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end


end
'', 
		@database_name=N''CCReportsRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''replication'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130625, 
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
EndSave:
	'

		EXEC(@Sql)

	------------------ FIN SCRIPT @Sql ------------------

	select 'Merge Snapshots Finished'

	COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
	
 end

else
 begin
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
 end
set nocount off
