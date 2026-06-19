SET NOCOUNT ON

declare @serverName varchar(200)
use [CCReportsRIA]
declare @temp table	(id int, value nvarchar(100));
declare @settingBD varchar(500)
	select @settingBD = valor from ccSettings where setting_id = 31
	insert into @temp select id,Value from fn_RIASplitDelimited(@settingBD,'|')

	select @serverName = value  from @temp where id = 1
	
	/*Comienza creacion de linked server*/
	if(@serverName!=@@servername)
	begin
	USE [master]
		IF NOT EXISTS ( SELECT TOP (1) * FROM sysservers WHERE srvname = 'SvrPublisher_transactional' )
		begin
			EXEC master.dbo.sp_addlinkedserver @server = N'SvrPublisher_transactional', @srvproduct=N'SQLSERVER', @provider=N'SQLNCLI11', @datasrc=@serverName
			EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'SvrPublisher_transactional',@useself=N'False',@locallogin=NULL,@rmtuser=N'replication',@rmtpassword='replication'
			EXEC master.dbo.sp_serveroption @server=N'SvrPublisher_transactional', @optname=N'collation compatible', @optvalue=N'false'
			EXEC master.dbo.sp_serveroption @server=N'SvrPublisher_transactional', @optname=N'data access', @optvalue=N'true'
			EXEC master.dbo.sp_serveroption @server=N'SvrPublisher_transactional', @optname=N'dist', @optvalue=N'false'
			EXEC master.dbo.sp_serveroption @server=N'SvrPublisher_transactional', @optname=N'pub', @optvalue=N'false'
			EXEC master.dbo.sp_serveroption @server=N'SvrPublisher_transactional', @optname=N'rpc', @optvalue=N'true'
			EXEC master.dbo.sp_serveroption @server=N'SvrPublisher_transactional', @optname=N'rpc out', @optvalue=N'true'
			EXEC master.dbo.sp_serveroption @server=N'SvrPublisher_transactional', @optname=N'sub', @optvalue=N'false'
			EXEC master.dbo.sp_serveroption @server=N'SvrPublisher_transactional', @optname=N'connect timeout', @optvalue=N'0'
			EXEC master.dbo.sp_serveroption @server=N'SvrPublisher_transactional', @optname=N'collation name', @optvalue=null
			EXEC master.dbo.sp_serveroption @server=N'SvrPublisher_transactional', @optname=N'lazy schema validation', @optvalue=N'false'
			EXEC master.dbo.sp_serveroption @server=N'SvrPublisher_transactional', @optname=N'query timeout', @optvalue=N'0'
			EXEC master.dbo.sp_serveroption @server=N'SvrPublisher_transactional', @optname=N'use remote collation', @optvalue=N'true'
			EXEC master.dbo.sp_serveroption @server=N'SvrPublisher_transactional', @optname=N'remote proc transaction promotion', @optvalue=N'true'

		end
	end 
	/*termina creacion de linked server*/

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

IF @actualVersion >= @version and @serverName not like 'servername'
 begin
 	BEGIN TRAN

	BEGIN TRY


	set @process = 'Drop Table migration'
	set @Sql = 'IF EXISTS (SELECT * FROM dbo.sysobjects WHERE [name] = ''migration'')
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
ROW_NUMBER() OVER(ORDER BY [description] desc)+99 AS id
,[description]
,status
,error
,dateStart
,dateEnd
,publisher_db
from
(
	select 
	distinct
	  B.name as [description],0 as status,'''' as error,''1901-01-01'' as dateStart,''1901-01-01'' as dateEnd
	, publisher_db=''CCenterRIA''
	FROM 
		'+case when @serverName!=@@servername then '[SvrPublisher_transactional].' else '' end+'CCenterRIA.dbo.syspublications B 
	INNER JOIN 
		'+case when @serverName!=@@servername then '[SvrPublisher_transactional].' else '' end+'CCenterRIA.dbo.sysarticles C 
	ON c.pubid = b.pubid
	INNER JOIN 
		'+case when @serverName!=@@servername then '[SvrPublisher_transactional].' else '' end+'CCenterRIA.dbo.syssubscriptions A  
	ON c.artid = A.artid
	WHERE
		A.dest_db in(''CCReportsRIA'')
UNION 
	select
	distinct
	  B.name as [description],0 as status,'''' as error,''1901-01-01'' as dateStart,''1901-01-01'' as dateEnd
	, publisher_db=''CCRecorderRIA''
	FROM 
		CCRecorderRIA.dbo.syspublications B 
	INNER JOIN 
		CCRecorderRIA.dbo.sysarticles C 
	ON c.pubid = b.pubid
	INNER JOIN 
		CCRecorderRIA.dbo.syssubscriptions A  
	ON c.artid = A.artid
	WHERE
		A.dest_db in(''CCReportsRIA'')
)
migration
order by description,publisher_db'
	EXEC(@Sql)


	set @Sql = 'exec msdb..sp_update_job @job_name = ''ReportsMasterProcess'', @enabled = 0 --Enable
exec msdb..sp_update_job @job_name = ''ReportMasterProcessGenerateLow'', @enabled = 0 --Enable
exec msdb..sp_update_job @job_name = ''ReportsMasterProcessYesterday'', @enabled = 0 --Enable
'
	EXEC(@Sql)


	SET @process = 'Drop Procedure sp_GetDistributionInfo'
    SET @sql = '
	if exists (select * from sys.procedures where name = N''sp_GetDistributionInfo'')
	begin
		DROP PROCEDURE sp_GetDistributionInfo
	end'
    EXEC(@sql)


	SET @process = 'Create Procedure sp_GetDistributionInfo'
    SET @sql = 'CREATE PROCEDURE [dbo].[sp_GetDistributionInfo]
    @publicationName VARCHAR(MAX),
    @publisherDB SYSNAME,
    @subscriberDB SYSNAME,
    @option INT,
    @linkedServerName SYSNAME = NULL,
    @hasSubscription BIT OUTPUT,
    @runstatus INT OUTPUT,
    @undeliveredCmds INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX)
    DECLARE @prefix NVARCHAR(200) = ISNULL(QUOTENAME(@linkedServerName) + ''.'', '''')
    DECLARE @params NVARCHAR(MAX)

    SET @hasSubscription = 0
    SET @runstatus = NULL
    SET @undeliveredCmds = NULL

    IF @option = 1
    BEGIN
        -- Verificar si existe la suscripción
        SET @sql = ''
        IF EXISTS (
            SELECT 1
            FROM '' + @prefix + ''distribution.dbo.MSsubscriptions
            WHERE publication_id IN (
                SELECT publication_id FROM '' + @prefix + ''distribution.dbo.MSpublications
                WHERE publication = @publicationName
            )
            AND publisher_db = @publisherDB
            AND subscriber_db = @subscriberDB
            AND subscriber_db <> ''''virtual''''
        )
            SET @hasSubscription = 1''

        SET @params = N''@publicationName VARCHAR(MAX), @publisherDB SYSNAME, @subscriberDB SYSNAME, @hasSubscription BIT OUTPUT''
        EXEC sp_executesql @sql, @params, 
            @publicationName = @publicationName, 
            @publisherDB = @publisherDB, 
            @subscriberDB = @subscriberDB, 
            @hasSubscription = @hasSubscription OUTPUT
    END
    ELSE IF @option = 2
    BEGIN
        -- Obtener estado de la suscripción
        SET @sql = ''
        SELECT TOP 1 
            @runstatus = mdh.runstatus, 
            @undeliveredCmds = und.UndelivCmdsInDistDB
        FROM '' + @prefix + ''distribution.dbo.MSdistribution_agents mda
        LEFT JOIN '' + @prefix + ''distribution.dbo.MSdistribution_history mdh ON mdh.agent_id = mda.id
        JOIN (
            SELECT s.agent_id, MaxAgentValue.[time],
                   SUM(CASE WHEN xact_seqno > MaxAgentValue.maxseq THEN 1 ELSE 0 END) AS UndelivCmdsInDistDB
            FROM '' + @prefix + ''distribution.dbo.MSrepl_commands t WITH (NOLOCK)
            JOIN '' + @prefix + ''distribution.dbo.MSsubscriptions s WITH (NOLOCK)
              ON t.article_id = s.article_id AND t.publisher_database_id = s.publisher_database_id
            JOIN (
                SELECT hist.agent_id, MAX(hist.[time]) AS [time], h.maxseq
                FROM '' + @prefix + ''distribution.dbo.MSdistribution_history hist WITH (NOLOCK)
                JOIN (
                    SELECT agent_id, ISNULL(MAX(xact_seqno), 0x0) AS maxseq
                    FROM '' + @prefix + ''distribution.dbo.MSdistribution_history WITH (NOLOCK)
                    GROUP BY agent_id
                ) h ON hist.agent_id = h.agent_id AND h.maxseq = hist.xact_seqno
                GROUP BY hist.agent_id, h.maxseq
            ) MaxAgentValue ON MaxAgentValue.agent_id = s.agent_id
            GROUP BY s.agent_id, MaxAgentValue.[time]
        ) und ON mda.id = und.agent_id AND und.[time] = mdh.[time]
        WHERE mda.publication = @publicationName
          AND mda.subscriber_db = @subscriberDB
          AND mda.publisher_db = @publisherDB''

        SET @params = N''@publicationName VARCHAR(MAX), @publisherDB SYSNAME, @subscriberDB SYSNAME, @runstatus INT OUTPUT, @undeliveredCmds INT OUTPUT''
        EXEC sp_executesql @sql, @params,
            @publicationName = @publicationName, 
            @publisherDB = @publisherDB, 
            @subscriberDB = @subscriberDB, 
            @runstatus = @runstatus OUTPUT, 
            @undeliveredCmds = @undeliveredCmds OUTPUT
    END
END'
    EXEC(@sql)


	SET @process = 'Drop Procedure sp_ExecPendingSubscriptions_CCReportsRIA'
    SET @sql = '
	if exists (select * from sys.procedures where name = N''sp_ExecPendingSubscriptions_CCReportsRIA'')
	begin
		DROP PROCEDURE sp_ExecPendingSubscriptions_CCReportsRIA
	end'
    EXEC(@sql)


	SET @process = 'Create Procedure sp_ExecPendingSubscriptions_CCReportsRIA'
    SET @sql = 'CREATE PROCEDURE [dbo].[sp_ExecPendingSubscriptions_CCReportsRIA]
AS
BEGIN
    DECLARE @id INT, @maxId INT
    DECLARE @runStatus INT, @undeliveredCmds INT, @hasSubscription BIT
    DECLARE @publicationName VARCHAR(MAX), @publisherDBName SYSNAME, @jobName VARCHAR(MAX)
    DECLARE @dateNow DATETIME, @linkedServer SYSNAME
    DECLARE @subscriberDB SYSNAME
    DECLARE @errorMsg NVARCHAR(MAX)

    SET NOCOUNT ON;

    SET @subscriberDB = DB_NAME()

    SELECT @maxId = ISNULL(MAX(id), 1), @id = 0, @dateNow = GETDATE() FROM migration

    WHILE DATEDIFF(SECOND, @dateNow, GETDATE()) < 59 
          AND EXISTS(SELECT 1 FROM migration WHERE status IN (0,1)) 
          AND @id <= @maxId
    BEGIN
        SELECT TOP 1 
            @publicationName = [description], 
            @publisherDBName = [db_name], 
            @id = id 
        FROM migration 
        WHERE status IN (0,1) AND id >= @id 
        ORDER BY id

		'
		+case when @serverName!=@@servername then 'SET @linkedServer = CASE WHEN @publisherDBName = ''CCenterRIA'' THEN ''SvrPublisher_transactional'' ELSE NULL END' 
		else 'SET @linkedServer = NULL' end+
		'

        -- Verificar existencia de suscripcion
        EXEC dbo.sp_GetDistributionInfo 
            @publicationName = @publicationName,
            @publisherDB = @publisherDBName,
            @subscriberDB = @subscriberDB,
            @option = 1,
            @linkedServerName = @linkedServer,
            @hasSubscription = @hasSubscription OUTPUT,
            @runstatus = @runStatus OUTPUT,
            @undeliveredCmds = @undeliveredCmds OUTPUT

        IF @hasSubscription = 0
        BEGIN
            SET @errorMsg = ''No subscription found for publication: '' + @publicationName
            PRINT @errorMsg

            UPDATE migration WITH (ROWLOCK) 
            SET status = 3, dateStart = GETDATE(), dateEnd = GETDATE(), [error] = @errorMsg
            WHERE id = @id

            SET @id = @id + 1
            CONTINUE
        END

        -- Obtener estado actual
        EXEC dbo.sp_GetDistributionInfo 
            @publicationName = @publicationName,
            @publisherDB = @publisherDBName,
            @subscriberDB = @subscriberDB,
            @option = 2,
            @linkedServerName = @linkedServer,
            @hasSubscription = @hasSubscription OUTPUT,
            @runstatus = @runStatus OUTPUT,
            @undeliveredCmds = @undeliveredCmds OUTPUT

        IF @runStatus = 6
        BEGIN
            SET @errorMsg = ''Replication agent failed before starting job. Publication: '' + @publicationName
            PRINT @errorMsg

            UPDATE migration WITH (ROWLOCK) 
            SET status = 3, dateStart = GETDATE(), dateEnd = GETDATE(), [error] = @errorMsg
            WHERE id = @id

            SET @id = @id + 1
            CONTINUE
        END

        IF (@undeliveredCmds = 0 AND @runStatus = 2) 
           OR (@runStatus IN (1,3,5))
        BEGIN
            UPDATE migration WITH (ROWLOCK) 
            SET status = 2, dateStart = GETDATE(), dateEnd = GETDATE(), [error] = ''''
            WHERE id = @id

            SET @id = @id + 1
            CONTINUE
        END

        -- Buscar el job
        SELECT @jobName = name 
        FROM msdb.dbo.sysjobs 
        WHERE name LIKE ''%'' + @subscriberDB + ''%'' 
          AND name LIKE ''%'' + @publisherDBName + ''%'' 
          AND name LIKE ''%'' + @publicationName + ''-%''

        IF @jobName IS NULL
        BEGIN
            SET @errorMsg = ''Job not found for publication: '' + @publicationName
            PRINT @errorMsg

            UPDATE migration WITH (ROWLOCK) 
            SET status = 3, dateStart = GETDATE(), dateEnd = GETDATE(), [error] = @errorMsg
            WHERE id = @id

            SET @id = @id + 1
            CONTINUE
        END

        -- Iniciar job
        UPDATE migration WITH (ROWLOCK) 
        SET status = 1, dateStart = GETDATE(), [error] = ''''
        WHERE id = @id

        EXEC msdb.dbo.sp_start_job @job_name = @jobName

        IF @@ERROR <> 0
        BEGIN
            SET @errorMsg = ''Error starting job: '' + @jobName
            PRINT @errorMsg

            UPDATE migration WITH (ROWLOCK) 
            SET status = 3, dateEnd = GETDATE(), [error] = @errorMsg
            WHERE id = @id

            SET @id = @id + 1
            CONTINUE
        END

        WAITFOR DELAY ''00:00:01''

        -- Monitorear la replicacion en tiempo real
        WHILE 1 = 1
        BEGIN
            EXEC dbo.sp_GetDistributionInfo 
                @publicationName = @publicationName,
                @publisherDB = @publisherDBName,
                @subscriberDB = @subscriberDB,
                @option = 2,
                @linkedServerName = @linkedServer,
                @hasSubscription = @hasSubscription OUTPUT,
                @runstatus = @runStatus OUTPUT,
                @undeliveredCmds = @undeliveredCmds OUTPUT

            IF @runStatus = 6
            BEGIN
                SET @errorMsg = ''Replication agent failed while monitoring. Publication: '' + @publicationName
                PRINT @errorMsg

                UPDATE migration WITH (ROWLOCK) 
                SET status = 3, dateEnd = GETDATE(), [error] = @errorMsg
                WHERE id = @id

                BREAK
            END

            IF @runStatus NOT IN (1,3,4,5) OR @undeliveredCmds = 0
                BREAK

            WAITFOR DELAY ''00:00:01''
            PRINT ''Job in progress: '' + @jobName

            IF DATEDIFF(SECOND, @dateNow, GETDATE()) > 59
            BEGIN
                PRINT ''Timeout reached for publication: '' + @publicationName
                BREAK
            END
        END

        -- Finalizar actualizacion
        IF @runStatus = 2
        BEGIN
            UPDATE migration WITH (ROWLOCK) 
            SET status = 2, dateEnd = GETDATE(), [error] = ''''
            WHERE id = @id
        END
        ELSE IF @runStatus IN (1,3,5)
        BEGIN
            UPDATE migration WITH (ROWLOCK) 
            SET status = 1, dateEnd = GETDATE(), [error] = ''''
            WHERE id = @id
        END

        SET @id = @id + 1
    END
END'
	EXEC(@sql)

	set @process = 'Create Job CW_Tran_Replication_CCReportsRIA'
	set @Sql='USE [msdb]
if exists( select * from msdb.dbo.sysjobs where name=''CW_Tran_Replication_CCReportsRIA'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW_Tran_Replication_CCReportsRIA'', @delete_unused_schedule=1

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW_Tran_Replication_CCReportsRIA'',
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

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW_Tran_Replication_CCReportsRIA'',
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
exec sp_ExecPendingSubscriptions_CCReportsRIA

if not exists(select * from migration where status in(0,1)) BEGIN
	exec msdb..sp_update_job @job_name = ''''ReportsMasterProcess'''', @enabled = 1 --Enable
	exec msdb..sp_update_job @job_name = ''''ReportsMasterProcessYesterday'''', @enabled = 0 --Disable
	exec msdb..sp_update_job @job_name = ''''ReportMasterProcessGenerateLow'''', @enabled = 1 --Enable
	exec msdb..sp_update_job @job_name = ''''CW_Tran_Replication_CCReportsRIA'''', @enabled = 0 --Disable

	exec ccSpCreateIndexReport
END
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
EndSave:'

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
