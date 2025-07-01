set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
    Set @Version = 99
    Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
    begin tran
    begin try

	-------------------------------------------------BEGIN MACL-------------------------------------------------
    SET @process = 'ALTER TABLES TO ADD VirtualAgentId'
    SET @sql = 'IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N''virtualAgentId''
          AND Object_ID = Object_ID(N''ria_grabacion''))
BEGIN
    ALTER TABLE ria_grabacion ADD virtualAgentId VARCHAR(50)
END

IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N''virtualAgentId''
          AND Object_ID = Object_ID(N''ria_grabacionconsulta''))
BEGIN
    ALTER TABLE ria_grabacionconsulta ADD virtualAgentId VARCHAR(50)
END

IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N''virtualAgentId''
          AND Object_ID = Object_ID(N''ria_grabacion_temp''))
BEGIN
    ALTER TABLE ria_grabacion_temp ADD virtualAgentId VARCHAR(50)
END'
    EXEC(@sql)

	SET @process = 'Alter sp ccsp_InsertOrUpdateRecordingRIA_Grabacion to add VirtualAgentId'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertOrUpdateRecordingRIA_Grabacion]
AS
BEGIN
    -- Declaramos una tabla temporal para almacenar grab_id, cal_id, tipo_llamada y AvrTransferId de los registros procesados
    DECLARE @ProcessedRecords TABLE (       
        grab_id BIGINT,
        cal_id INT,
        tipo_llamada INT,
        AvrTransferId int
    );

    -- Utilizamos MERGE para insertar o actualizar registros en la tabla ria_grabacion
    
    MERGE INTO ria_grabacion AS Target
    USING RIA_GRABACION_TEMP AS Source
    ON Target.cal_id = Source.cal_id AND Target.tipo_llamada = Source.tipo_llamada
    WHEN MATCHED THEN 
        UPDATE SET
            Target.calif_id = Source.calif_id,
            Target.califSub_id = Source.califSub_id,
            Target.cal_tMoh = Source.cal_tMoh,
            Target.duracion = Source.duracion,
            Target.cal_extension = Source.cal_extension,
            Target.IDWG = Source.IDWG,
            Target.extra_info = Source.extra_info,
            Target.extra_info2 = Source.extra_info2,
			Target.virtualAgentId = source.virtualAgentId
        --OUTPUT ''UPDATE'' AS ActionType, inserted.grab_id, inserted.cal_id, inserted.tipo_llamada INTO @ProcessedRecords
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (tipo_llamada, cal_id, age_id, cam_id, calif_id, cal_extension, finicio, ffin, ani, duracion, cal_key, puerto_id, dni_id, id_repositorio, razon_id, tipo_grab_id,
                fvalida, cal_whohung, califSub_id, cal_tMoh, cal_manual, id_nivel_grito, prefijo, dni, IDWG, extra_info, extra_info2, virtualAgentId)
        VALUES (Source.tipo_llamada, Source.cal_id, Source.age_id, Source.cam_id, Source.calif_id, Source.cal_extension, Source.finicio, Source.ffin, Source.ani, Source.duracion, 
                Source.cal_key, Source.puerto_id, Source.dni_id, Source.id_repositorio, Source.razon_id, Source.tipo_grab_id, Source.fvalida, Source.cal_whohung, Source.califSub_id, 
                Source.cal_tMoh, Source.cal_manual, Source.id_nivel_grito, Source.prefijo, Source.dni, Source.IDWG, Source.extra_info, Source.extra_info2, source.virtualAgentId)
       
       OUTPUT inserted.grab_id, inserted.cal_id, inserted.tipo_llamada 
       INTO @ProcessedRecords(grab_id,cal_id,tipo_llamada)
        ;
    -- Ahora añadimos el AvrTransferId a @ProcessedRecords uniendo con RIA_GRABACION_TEMP
    UPDATE PR
    SET PR.AvrTransferId = S.AvrTransferId
    FROM @ProcessedRecords PR
    INNER JOIN RIA_GRABACION_TEMP S ON PR.cal_id = S.cal_id AND PR.tipo_llamada = S.tipo_llamada;

    -- Regresamos grab_id, cal_id, tipo_llamada y AvrTransferId para los registros insertados o actualizados
    SELECT grab_id, cal_id, tipo_llamada, AvrTransferId FROM @ProcessedRecords;

    -- Limpiar la tabla temporal
    TRUNCATE TABLE RIA_GRABACION_TEMP;
END;
'
    EXEC(@sql)

	SET @process = 'alter sp trsp_InsertRecNodeGrabIds to add Virtual Agent Name to the call in the finder'
    SET @sql = 'ALTER PROCEDURE [dbo].[trsp_InsertRecNodeGrabIds]
@grabIds varchar(8000),
@rateEvaluationFormatKolob int = -1
AS
BEGIN
    declare @grabIdTmp table(grabId bigint primary key)
    declare @tEvaluationTmp table(grabId bigint primary key,total float)    
    DECLARE @XMLTable TABLE (grab_id INT, dateIn datetime, [node] xml, [status] bit);
    
    DECLARE @RecNodeTable TABLE (
    Date datetime,
    CDATE VARCHAR(23),  -----> Date Generic
    CID int,            -----> CamId
    CType int,          -----> Tipo de llamada
    C01 bigint,         -----> grab_id
    C02 VARCHAR(50),    -----> Type of Recording (Inbound/Outbound)
    C03 VARCHAR(250),   -----> Camp/ACD descripcion
    C04 INT,            -----> ShoutLevel
    C05 VARCHAR(250),   -----> Agent Login
    C06 VARCHAR(50),    -----> Formated date
    C07 VARCHAR(50),    -----> Position Computer
    C08 VARCHAR(50),    -----> Duration
    C09 VARCHAR(50),    -----> Ani
    C10 VARCHAR(50),    -----> Dnis
    C11 VARCHAR(100),   -----> Calkey
    C12 VARCHAR(50),    -----> Manual
    C13 INT,            -----> User ID
    C14 int,            -----> cal ID
    C15 INT,            -----> Cam /ACD ID
    C16 VARCHAR(12),    -----> Duration Reco@rding as 00:00:00
    C17 INT,            -----> Position Extension
    C18 VARCHAR(50),    -----> rating(Scoring Template)
    C19 INT,            -----> Reposiory ID
    C20 VARCHAR(250),   -----> Disposition
    C21 INT,            -----> Disposition ID
    C22 TINYINT,        -----> Has Video
    C23 VARCHAR(300),   -----> Agent Full Name
    C24 VARCHAR(300),   -----> Supervisor Name
    C25 VARCHAR(250),   -----> Score Template
    C26 INT,            -----> graphic_id
    C27 VARCHAR(250),   -----> Prefix recording
    C28 VARCHAR(250),   -----> subDisposition
    C29 BIT,            -----> LLamada Grabada --@extraInfo 1 Record, 0 Dont Record
    C30 BIT             ------> LLamada VoiceMail @extraInfo 2
);
insert into @grabIdTmp
select value from  dbo.fn_RIASplitDelimited(@grabIds,'','')


if @rateEvaluationFormatKolob = 0 begin
    ;with maxFechaCalif as(
    select max(fecha_calif) as fecha_calif,B.grabId from ria_formacalif A 
    inner join @grabIdTmp B on A.id_grabacion=B.grabId
    group by B.grabId
    ), ria_formacalifTop as(
    select A.grabId,B.total_forma from maxFechaCalif A
    inner join ria_formacalif B on A.grabId=B.id_grabacion and A.fecha_calif=B.fecha_calif
    )
    insert into @tEvaluationTmp
    select * from ria_formacalifTop
end
else if @rateEvaluationFormatKolob = 1 begin
    insert into @tEvaluationTmp
    SELECT A.grab_id,AVG(totalPoints) FROM RECORDERRIA_RECORDINGEVALUATION  A
    inner join @grabIdTmp T on A.grab_id=T.grabId
    WHERE deleted != 1 
    group by A.grab_id
end

;with GrabacionSource AS (
    SELECT rec.grab_id, rec.tipo_llamada, rec.Prefijo, rec.cal_manual, rec.id_nivel_grito, 
    rec.cal_id, rec.finicio, rec.extra_info, rec.extra_info2, rec.video, 
    isnull(E.total,0) AS total_forma
    ,calif_id,cam_id,duracion,ani,dni,cal_key,id_repositorio,califSub_id,age_id
    ,cal_extension, rec.virtualAgentId
    FROM ria_grabacion rec with(nolock)
    inner join @grabIdTmp t on rec.grab_id=t.grabId
    left join @tEvaluationTmp E on t.grabId=E.grabId    
    UNION ALL
    SELECT rec.grab_id, rec.tipo_llamada, '''' AS Prefijo, rec.cal_manual, rec.id_nivel_grito, 
    rec.cal_id, rec.finicio, rec.extra_info, rec.extra_info2, NULL AS video,
    isnull(E.total,0) AS total_forma
    ,calif_id,cam_id,duracion,ani,dni,cal_key,id_repositorio,califSub_id,age_id
    ,cal_extension, rec.virtualAgentId
    FROM RIA_GRABACIONCONSULTA rec with(nolock)
    inner join @grabIdTmp t on rec.grab_id=t.grabId
    left join @tEvaluationTmp E on t.grabId=E.grabId
)
INSERT INTO @RecNodeTable
SELECT 
rec.finicio,
CONVERT(VARCHAR(23), rec.finicio, 126) AS ''@CDATE'',
rec.cam_id AS ''@CID'',
rec.tipo_llamada AS ''@CType'',
rec.grab_id AS ''@C01'',
CASE WHEN rec.tipo_llamada = 1 THEN ''Inbound'' ELSE ''Outbound'' END AS ''@C02'',
CASE WHEN rec.tipo_llamada = 1 THEN inb.descripcion ELSE outb.cam_descripcion END AS ''@C03'',
ISNULL(rec.id_nivel_grito, -1) AS ''@C04'',
CASE WHEN ISNULL(rec.virtualAgentId, 0) > 0 THEN va.nameAgent ELSE
ISNULL(usr.LOGIN, ''N/A'') END AS ''@C05'',
CONVERT(VARCHAR(23), rec.finicio, 126) AS ''@C06'',
pos.Computer AS ''@C07'',
CONVERT(NVARCHAR(10), rec.duracion) AS ''@C08'',
rec.ani AS ''@C09'',
rec.dni AS ''@C10'',
rec.cal_key AS ''@C11'',
CASE WHEN rec.cal_manual = 0 THEN ''N/A'' ELSE ''Manual'' END AS ''@C12'',
ISNULL(usr.[User_id], 0) AS ''@C13'',
rec.cal_id AS ''@C14'',
rec.cam_id AS ''@C15'',
CONVERT(CHAR(8), DATEADD(SECOND, rec.duracion, 0), 108) AS ''@C16'',
ISNULL(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END, -1) AS ''@C17'',
ISNULL(rec.total_forma, 0) AS ''@C18'',
rec.id_repositorio AS ''@C19'',
case when rec.calif_id<=0 then ''N/A'' when rec.tipo_llamada = 1 then e.description  when rec.tipo_llamada = 2 then eOut.Description end  AS ''@C20'',
rec.calif_id AS ''@C21'',
rec.video AS ''@C22'',
ISNULL(usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno, ''N/A'') AS ''@C23'',
'''' AS ''@C24'',
'''' AS ''@C25'',
isnull(grap.graphic_id,1) AS ''@C26'',
rec.Prefijo AS ''@C27'',    
case when  rec.califSub_id<=0 then ''N/A'' when rec.tipo_llamada = 1 then subDisposition.califSubDesc  when rec.tipo_llamada = 2 then subDispositionOut.califSubDesc end  AS ''@C28'',    
CONVERT(BIT, ISNULL(rec.extra_info, ''1'')) AS ''@C29'',
CONVERT(BIT, ISNULL(rec.extra_info2, ''0'')) AS ''@C30''
FROM GrabacionSource rec
LEFT JOIN ccinbound inb ON rec.cam_id = inb.Inbound_id AND rec.tipo_llamada = 1
LEFT JOIN cccamps outb ON rec.cam_id = outb.cam_id AND rec.tipo_llamada = 2
LEFT JOIN ccUsers usr ON usr.User_id = rec.age_id
LEFT JOIN ccPosicion pos ON pos.pos_id = rec.cal_extension * -1
LEFT JOIN ccTipoCalif AS e ON rec.calif_id = e.calif_id AND rec.tipo_llamada = 1
LEFT JOIN ccTipoCalifOUT AS eOut ON rec.calif_id = eOut.calif_id AND rec.tipo_llamada = 2
LEFT JOIN cctipocalifsub AS subDisposition ON rec.califSub_id = subDisposition.califSub_id
LEFT JOIN cctipocalifsubout AS subDispositionOut ON rec.califSub_id = subDispositionOut.califSub_id AND rec.tipo_llamada = 2
LEFT JOIN ccRIAInboundGraph grap ON grap.Inbound_id = inb.Inbound_id AND rec.tipo_llamada = 1
LEFT JOIN ccRIACampsGraph grapOut ON grapOut.cam_id = outb.cam_id AND rec.tipo_llamada = 2
LEFT JOIN ccVirtualAgent va ON rec.virtualAgentId = va.idAgent


insert into @XMLTable (grab_id,status, dateIn, node)       
SELECT  
    C01,0 [status],[date],
    case when C03 is null then null 
    when (C30=0 and C05 is not null and C20 is not null and C28 is not null) or  (C30=1) then   
    (
        SELECT 
            CDATE AS "@CDATE",
            CID As "@CID",
            CType As "@CType",
            C01 AS "@C01",
            C02 AS "@C02",
            C03 AS "@C03",
            C04 AS "@C04",
            C05 AS "@C05",
            C06 AS "@C06",
            C07 AS "@C07",
            C08 AS "@C08",
            C09 AS "@C09",
            C10 AS "@C10",
            C11 AS "@C11",
            C12 AS "@C12",
            C13 AS "@C13",
            C14 AS "@C14",
            C15 AS "@C15",
            C16 AS "@C16",
            C17 AS "@C17",
            C18 AS "@C18",
            C19 AS "@C19",
            C20 AS "@C20",
            C21 AS "@C21",
            C22 AS "@C22",
            C23 AS "@C23",
            C24 AS "@C24",
            C25 AS "@C25",
            C26 AS "@C26",
            C27 AS "@C27",
            C28 AS "@C28",
            C29 AS "@C29",
            C30 AS "@C30"
        FROM @RecNodeTable AS innerTable
        WHERE innerTable.C01 = outerTable.C01       
        FOR XML PATH(''R02''), TYPE
    ) 
    end AS node
FROM @RecNodeTable AS outerTable;


INSERT INTO ria_RecNode (grab_id, node, dateIn, [status]) 
select X.grab_id,X.[node],X.dateIn,-1 from @XMLTable X
left join ria_RecNode R on R.grab_id=X.grab_id
where X.node is null and R.grab_id is null

delete  from @XMLTable where node is null

update h set h.node=t.node,h.status=2
from RIA_RecNodeHistory h with(nolock)
inner join @XMLTable t on h.grab_id=t.grab_id and t.node is not null

update t set t.status=1
from RIA_RecNodeHistory h with(nolock)
inner join @XMLTable t on h.grab_id=t.grab_id and t.node is not null

if exists(select 1 from @XMLTable where status=0) begin
    update h set h.node=t.node,h.status=2
    from ria_RecNode h with(nolock)
    inner join @XMLTable t on h.grab_id=t.grab_id

    update t set t.status=1
    from ria_RecNode h with(nolock)
    inner join @XMLTable t on h.grab_id=t.grab_id
end
if exists(select 1 from @XMLTable where status=0) begin
    INSERT INTO ria_RecNode (grab_id, node, dateIn, [status]) 
    select grab_id,[node],dateIn,0 from @XMLTable where status=0    
end

END'
    EXEC(@sql)
	
	--------------------------------------------------END MACL--------------------------------------------------

	------------------------------------------ Begin Transactional Replication ----------------------------------------
	
	SET @process = 'Shorten namePublication values to max 17 chars in PublicationHighLoad'
    SET @sql='
if exists(select * from PublicationHighLoad where namePublication=''ccRIAWorkGroup_Calid'') begin
    update PublicationHighLoad set namePublication=''WorkGroup_Calid'' where namePublication=''ccRIAWorkGroup_Calid''
end
'
    EXEC(@sql)
	
	
	SET @process = 'DROP PROCEDURE ReportsMasterProcessAVRS'
    SET @Sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ReportsMasterProcessAVRS'')
		BEGIN
			DROP PROCEDURE ReportsMasterProcessAVRS;
		END'
    EXEC(@Sql)
	
	SET @process = 'CREATE procedure ReportsMasterProcessAVRS'
    SET @Sql = 'CREATE procedure [dbo].[ReportsMasterProcessAVRS] as
set nocount on
declare @replicationName varchar(max)
declare @dateStart datetime
declare @schedule_id int,@scheduleTime int

declare @sessionKIll table(id int, sessionId int)
declare @i int,@count int
declare @sessionId int
declare @SQL varchar(max)


set @dateStart = getdate()
set @scheduleTime = 5


print ''---Get schedule_id and @scheduleTime ----''
select @schedule_id=C.schedule_id, @scheduleTime=C.freq_subday_interval
	FROM msdb.dbo.sysjobs A
	LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
	INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
	where A.name=''ReportsMasterProcessAVRS''



print ''---Kill Process Replication Merge Agent----''
while exists(SELECT	s.session_id AS SessionID		
	from [master].sys.dm_exec_sessions  as s 
	LEFT OUTER JOIN [master].sys.sysprocesses p	ON s.session_id = p.spid
	where s.session_id in(
	select distinct r.blocking_session_id
	FROM [master].sys.dm_exec_sessions AS s
	INNER JOIN [master].sys.dm_exec_requests AS r ON r.session_id = s.session_id
	WHERE    r.session_id != @@SPID and  r.blocking_session_id   <>0
	)
	and s.[program_name] like ''%Replication Merge Agent%''	
	and DB_NAME(p.dbid)=''CCRecorderRIA''	
) begin
	insert into @sessionKIll(id,sessionId)
	
	SELECT	ROW_NUMBER() OVER(ORDER BY s.session_id) AS Row#, s.session_id AS SessionID		
	from [master].sys.dm_exec_sessions  as s 
	LEFT OUTER JOIN [master].sys.sysprocesses p	ON s.session_id = p.spid
	where s.session_id in(
	select distinct r.blocking_session_id
	FROM [master].sys.dm_exec_sessions AS s
	INNER JOIN [master].sys.dm_exec_requests AS r ON r.session_id = s.session_id
	WHERE    r.session_id != @@SPID and  r.blocking_session_id   <>0
	)
	and s.[program_name] like ''%Replication Merge Agent%''
	and DB_NAME(p.dbid)=''CCRecorderRIA''

	select * from @sessionKIll

	select @i=1,@count =COUNT(*) from @sessionKIll
	while @i<=@count begin
		select @sessionId=sessionId from @sessionKIll where id=@i
		SET @SQL = ''KILL '' + CAST(@sessionId as varchar(max))
		begin try
			EXEC (@SQL)
		end try
		begin catch
			print @SQL+ '' is proccess end''
		end catch
		set @i=@i+1
	end
	delete from @sessionKIll
end



PRINT ''---Get Jobs Replication ----'';
CREATE TABLE #replications ([name] NVARCHAR(500), flag BIT);

INSERT INTO #replications
SELECT DISTINCT A.[name], 0
FROM msdb.dbo.sysjobs A
LEFT JOIN PublicationLowLoad B ON A.[name] LIKE ''%'' + B.namePublication + ''%''
LEFT JOIN PublicationHighLoad C ON A.[name] LIKE ''%'' + C.namePublication + ''%''
WHERE A.[name] LIKE ''%CCRecorderRIA%'' AND A.[name] LIKE ''%CCenterRIA%''
AND B.namePublication IS NULL AND C.namePublication IS NULL;

SELECT @count = COUNT(*) FROM #replications;

WHILE (SELECT COUNT(*) FROM #replications WITH (NOLOCK) WHERE flag = 0) > 0
  AND DATEDIFF(SECOND, @dateStart, GETDATE()) < (@scheduleTime * 60)
BEGIN
    SET ROWCOUNT 1;
    SELECT @replicationName = [name]
    FROM #replications WITH (NOLOCK)
    WHERE flag = 0;
    SET ROWCOUNT 0;

    DECLARE @isRunning INT;

    SELECT @isRunning = COUNT(*)
    FROM msdb.dbo.sysjobs_view job
    INNER JOIN msdb.dbo.sysjobactivity activity ON job.job_id = activity.job_id
    INNER JOIN msdb.dbo.syssessions sess ON sess.session_id = activity.session_id
    INNER JOIN (
        SELECT MAX(agent_start_date) AS max_agent_start_date
        FROM msdb.dbo.syssessions
    ) sess_max ON sess.agent_start_date = sess_max.max_agent_start_date
    WHERE activity.run_requested_date IS NOT NULL 
        AND activity.stop_execution_date IS NULL
        AND job.name = @replicationName;

    IF @isRunning = 0
    BEGIN
        EXEC msdb.dbo.sp_start_job @job_name = @replicationName;
        PRINT ''sp_start_job '' + @replicationName;
    END
    ELSE
    BEGIN
        PRINT ''Job is already running: '' + @replicationName;
    END

    UPDATE #replications WITH (ROWLOCK)
    SET flag = 1
    WHERE [name] = @replicationName;

    WAITFOR DELAY ''00:00:03'';

    DECLARE @jobStart DATETIME = GETDATE();

    WHILE EXISTS (
        SELECT 1
        FROM msdb.dbo.sysjobs_view job
        INNER JOIN msdb.dbo.sysjobactivity activity ON job.job_id = activity.job_id
        INNER JOIN msdb.dbo.syssessions sess ON sess.session_id = activity.session_id
        INNER JOIN (
            SELECT MAX(agent_start_date) AS max_agent_start_date
            FROM msdb.dbo.syssessions
        ) sess_max ON sess.agent_start_date = sess_max.max_agent_start_date
        WHERE activity.run_requested_date IS NOT NULL 
            AND activity.stop_execution_date IS NULL
            AND job.name = @replicationName
    )
    BEGIN
        WAITFOR DELAY ''00:00:01'';
        PRINT ''In Progress Job in ReplicationName: '' + @replicationName;

        IF DATEDIFF(SECOND, @jobStart, GETDATE()) > ((@scheduleTime * 60) / @count)
        BEGIN
            PRINT ''Timeout reached. Stop waiting for: '' + @replicationName;
            BREAK;
        END
    END

    PRINT ''Progress End Job in ReplicationName: '' + @replicationName;
END

DROP TABLE #replications;





if not exists (select * from sys.indexes where name = N''IX_ccRIAWorkGroupUsersConsulta2'' and object_id = OBJECT_ID(N''ccRIAWorkGroupUsersConsulta''))
begin
	CREATE NONCLUSTERED INDEX [IX_ccRIAWorkGroupUsersConsulta2] ON [dbo].[ccRIAWorkGroupUsersConsulta]
		(
			[IDWG] ASC,
			[User_id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
end

print ''-------------------------Add Trigger IX_ccRIAWorkGroupUsersConsulta2-------------------------''



if DATEDIFF(mi,@dateStart,getdate())>@scheduleTime begin
	set @scheduleTime=@scheduleTime+1
	if  @scheduleTime< 59 begin
		EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = @scheduleTime
	end
	
end'
    EXEC(@Sql)
	
	SET @process = 'DROP PROCEDURE ReportsMasterProcessAVRSPublicationHighLoad'
    SET @Sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ReportsMasterProcessAVRSPublicationHighLoad'')
		BEGIN
			DROP PROCEDURE ReportsMasterProcessAVRSPublicationHighLoad;
		END'
    EXEC(@Sql)
	
	SET @process = 'CREATE PROCEDURE ReportsMasterProcessAVRSPublicationHighLoad'
    SET @Sql = 'CREATE PROCEDURE [dbo].[ReportsMasterProcessAVRSPublicationHighLoad]
AS
SET NOCOUNT ON;

DECLARE @replicationName VARCHAR(MAX);
DECLARE @dateStart DATETIME = GETDATE();
DECLARE @schedule_id INT, @scheduleTime INT;
DECLARE @count INT;

SET @scheduleTime = 5;

PRINT ''---Get schedule_id and @scheduleTime ----'';
SELECT 
    @schedule_id = C.schedule_id,
    @scheduleTime = C.freq_subday_interval
FROM msdb.dbo.sysjobs A
LEFT JOIN msdb.dbo.sysjobschedules B ON A.job_id = B.job_id
INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
WHERE A.name = ''ReportsMasterProcessAVRSPublicationHighLoad'';

PRINT ''---Get Jobs Replication ----'';
CREATE TABLE #replications ([name] NVARCHAR(500), flag BIT);

INSERT INTO #replications
SELECT DISTINCT A.[name], 0
FROM msdb.dbo.sysjobs A
INNER JOIN PublicationHighLoad C ON A.[name] LIKE ''%'' + C.namePublication + ''%''
WHERE A.[name] LIKE ''%CCRecorderRIA%'' AND A.[name] LIKE ''%CCenterRIA%'';

SELECT @count = COUNT(*) FROM #replications;

WHILE (
    SELECT COUNT(*) FROM #replications WITH (NOLOCK) WHERE flag = 0
) > 0 AND DATEDIFF(SECOND, @dateStart, GETDATE()) < (@scheduleTime * 60)
BEGIN
    SET ROWCOUNT 1;
    SELECT @replicationName = [name]
    FROM #replications WITH (NOLOCK)
    WHERE flag = 0;
    SET ROWCOUNT 0;

    DECLARE @isRunning INT;

    SELECT @isRunning = COUNT(*)
    FROM msdb.dbo.sysjobs_view job
    INNER JOIN msdb.dbo.sysjobactivity activity ON job.job_id = activity.job_id
    INNER JOIN msdb.dbo.syssessions sess ON sess.session_id = activity.session_id
    INNER JOIN (
        SELECT MAX(agent_start_date) AS max_agent_start_date
        FROM msdb.dbo.syssessions
    ) sess_max ON sess.agent_start_date = sess_max.max_agent_start_date
    WHERE activity.run_requested_date IS NOT NULL
      AND activity.stop_execution_date IS NULL
      AND job.name = @replicationName;

    IF @isRunning = 0
    BEGIN
        EXEC msdb.dbo.sp_start_job @job_name = @replicationName;
        PRINT ''sp_start_job '' + @replicationName;
    END
    ELSE
    BEGIN
        PRINT ''Job is already running: '' + @replicationName;
    END

    UPDATE #replications WITH (ROWLOCK)
    SET flag = 1
    WHERE [name] = @replicationName;

    WAITFOR DELAY ''00:00:03'';

    DECLARE @jobStart DATETIME = GETDATE();

    WHILE EXISTS (
        SELECT 1
        FROM msdb.dbo.sysjobs_view job
        INNER JOIN msdb.dbo.sysjobactivity activity ON job.job_id = activity.job_id
        INNER JOIN msdb.dbo.syssessions sess ON sess.session_id = activity.session_id
        INNER JOIN (
            SELECT MAX(agent_start_date) AS max_agent_start_date
            FROM msdb.dbo.syssessions
        ) sess_max ON sess.agent_start_date = sess_max.max_agent_start_date
        WHERE activity.run_requested_date IS NOT NULL
          AND activity.stop_execution_date IS NULL
          AND job.name = @replicationName
    )
    BEGIN
        WAITFOR DELAY ''00:00:01'';
        PRINT ''In Progress Job in ReplicationName: '' + @replicationName;

        IF DATEDIFF(SECOND, @jobStart, GETDATE()) > ((@scheduleTime * 60) / @count)
        BEGIN
            PRINT ''Stop Job in ReplicationName (timeout): '' + @replicationName;
            BREAK;
        END
    END

    PRINT ''Progress End Job in ReplicationName: '' + @replicationName;
END

DROP TABLE #replications;'
    EXEC(@Sql)
	
	SET @process = 'DROP PROCEDURE ReportsMasterProcessAVRSPublicationLowLoad'
    SET @Sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ReportsMasterProcessAVRSPublicationLowLoad'')
		BEGIN
			DROP PROCEDURE ReportsMasterProcessAVRSPublicationLowLoad;
		END'
    EXEC(@Sql)

	SET @process = 'CREATE PROCEDURE ReportsMasterProcessAVRSPublicationLowLoad'
    SET @Sql = 'CREATE PROCEDURE [dbo].[ReportsMasterProcessAVRSPublicationLowLoad]
AS
SET NOCOUNT ON;

DECLARE @replicationName VARCHAR(MAX);
DECLARE @dateStart DATETIME = GETDATE();
DECLARE @schedule_id INT, @scheduleTime INT;
DECLARE @count INT;

SET @scheduleTime = 15;

PRINT ''---Get schedule_id and @scheduleTime ----'';
SELECT 
    @schedule_id = C.schedule_id,
    @scheduleTime = C.freq_subday_interval
FROM msdb.dbo.sysjobs A
LEFT JOIN msdb.dbo.sysjobschedules B ON A.job_id = B.job_id
INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
WHERE A.name = ''ReportsMasterProcessAVRSPublicationLowLoad'';

PRINT ''---Get Jobs Replication ----'';
CREATE TABLE #replications ([name] NVARCHAR(500), flag BIT);

INSERT INTO #replications
SELECT DISTINCT A.[name], 0
FROM msdb.dbo.sysjobs A
INNER JOIN PublicationLowLoad C ON A.[name] LIKE ''%'' + C.namePublication + ''%''
WHERE A.[name] LIKE ''%CCRecorderRIA%'' AND A.[name] LIKE ''%CCenterRIA%'';

SELECT @count = COUNT(*) FROM #replications;

WHILE (
    SELECT COUNT(*) FROM #replications WITH (NOLOCK) WHERE flag = 0
) > 0 AND DATEDIFF(SECOND, @dateStart, GETDATE()) < (@scheduleTime * 60)
BEGIN
    SET ROWCOUNT 1;
    SELECT @replicationName = [name]
    FROM #replications WITH (NOLOCK)
    WHERE flag = 0;
    SET ROWCOUNT 0;

    DECLARE @isRunning INT;

    SELECT @isRunning = COUNT(*)
    FROM msdb.dbo.sysjobs_view job
    INNER JOIN msdb.dbo.sysjobactivity activity ON job.job_id = activity.job_id
    INNER JOIN msdb.dbo.syssessions sess ON sess.session_id = activity.session_id
    INNER JOIN (
        SELECT MAX(agent_start_date) AS max_agent_start_date
        FROM msdb.dbo.syssessions
    ) sess_max ON sess.agent_start_date = sess_max.max_agent_start_date
    WHERE activity.run_requested_date IS NOT NULL
      AND activity.stop_execution_date IS NULL
      AND job.name = @replicationName;

    IF @isRunning = 0
    BEGIN
        EXEC msdb.dbo.sp_start_job @job_name = @replicationName;
        PRINT ''sp_start_job '' + @replicationName;
    END
    ELSE
    BEGIN
        PRINT ''Job is already running: '' + @replicationName;
    END

    UPDATE #replications WITH (ROWLOCK)
    SET flag = 1
    WHERE [name] = @replicationName;

    WAITFOR DELAY ''00:00:03'';

    DECLARE @jobStart DATETIME = GETDATE();

    WHILE EXISTS (
        SELECT 1
        FROM msdb.dbo.sysjobs_view job
        INNER JOIN msdb.dbo.sysjobactivity activity ON job.job_id = activity.job_id
        INNER JOIN msdb.dbo.syssessions sess ON sess.session_id = activity.session_id
        INNER JOIN (
            SELECT MAX(agent_start_date) AS max_agent_start_date
            FROM msdb.dbo.syssessions
        ) sess_max ON sess.agent_start_date = sess_max.max_agent_start_date
        WHERE activity.run_requested_date IS NOT NULL
          AND activity.stop_execution_date IS NULL
          AND job.name = @replicationName
    )
    BEGIN
        WAITFOR DELAY ''00:00:01'';
        PRINT ''In Progress Job in ReplicationName: '' + @replicationName;

        IF DATEDIFF(SECOND, @jobStart, GETDATE()) > ((@scheduleTime * 60) / @count)
        BEGIN
            PRINT ''Stop Job in ReplicationName (timeout): '' + @replicationName;
            BREAK;
        END
    END

    PRINT ''Progress End Job in ReplicationName: '' + @replicationName;
END

DROP TABLE #replications;'
    EXEC(@Sql)	
	
	------------------------------------------ End Transactional Replication ----------------------------------------
	------------------------------------------Begin Frida .31 ------------------------------------------------------------
	SET @process = 'CW-9760 delete table  ccBaseXDB'
    SET @sql = '
	   IF EXISTS (
		SELECT 1
		FROM sys.columns c
		INNER JOIN sys.tables t ON c.object_id = t.object_id
		WHERE t.name = N''ccBaseXDB''
		  AND c.name = N''id''
		  AND c.is_identity = 1
	)
	BEGIN
	 DROP TABLE ccBaseXDB;
	END'
    EXEC(@sql)

	SET @process = 'CW-9760 create table  ccsp_BaseXmngr'
    SET @sql = '
	if not exists (select * from sys.tables where name = N''ccBaseXDB'')
    begin
        CREATE TABLE ccBaseXDB (
            id INT NOT NULL,
            serviceId INT NULL,
            dateStart DATETIME NULL,
            dateEnd DATETIME NULL,
            Xname VARCHAR(25) NULL,
            isFull BIT NULL
        );
    end'
    EXEC(@sql)

	SET @process = 'CW-9760 DROP PROCEDURE ccsp_BaseXmngr';
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_BaseXmngr'')
    begin
        DROP PROCEDURE ccsp_BaseXmngr;
    end';
	EXEC(@sql);

	SET @process = 'CW-9760 CREATE PROCEDURE ccsp_BaseXmngr';
	SET @sql = 'CREATE PROCEDURE ccsp_BaseXmngr
@action int = 0,
@option int = 0,
@idService int = 0,
@name varchar(25) = NULL,
@top varchar(max) = NULL,
@ids varchar(max)=null,
@dateStart dateTime= null,
@grabIds varchar(4000) = null

AS
declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
declare @parameterDefinition nvarchar(max)
declare @status tinyint

set @sql = ''''
if @action in(1,6) begin--obtiene los nodos a insertar en BX
	if @option = 2 begin
		if @action = 1 set @status =0
		else if @action = 6 set @status = 2

		set @parameterDefinition =N''@status int, @top int''

		set @sql=''declare @basexName varchar(25)
							select @basexName = Xname 
							from ccBaseXDB 
							where serviceId = @status and isFull = 0;

							with nodeA as (
								select top(@top) 
									grab_id,
									node,
									isnull(node.value(''''(/R02/@CDATE)[1]'''', ''''datetime''''), node.value(''''(/R02/@C06)[1]'''', ''''datetime'''')) as dateNode
								from ria_RecNode with(nolock)
								
							),
							nodeB as (
								select top(@top) 
									grab_id,
									node,
									isnull(node.value(''''(/R02/@CDATE)[1]'''', ''''datetime''''), node.value(''''(/R02/@C06)[1]'''', ''''datetime'''')) as dateNode
								from ria_RecNodeHistory with(nolock)
	
							),
							combinedNodes as (
								select grab_id, node, dateNode from nodeA
								union all
								select grab_id, node, dateNode from nodeB
							),
							formattedNodes as (
								select 
									grab_id,
									replace(replace(convert(nvarchar(max), node), ''''{'''', ''''&#123;''''), ''''}'''', ''''&#125;'''') as xmlString,
									dateNode
								from combinedNodes
							)
							select 
								fn.grab_id,
								fn.xmlString,
								isnull(b.Xname, @basexName) as Xname
							from formattedNodes fn
							left join ccBaseXDB b 
								on b.serviceId = 2 
								and fn.dateNode between b.dateStart and isnull(b.dateEnd, getdate())
							order by b.Xname''
	--print(@sql)
	--exec(@sql)
	EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top

	end
end
if @action in(2,7) begin--actualiza los nodos insertados en BX
	if @option = 2 begin
		if @action = 2 set @status=0
		else if @action = 7 set @status = 2
		set @parameterDefinition =N''@status int''
		set @sql=''update ria_RecNode with(rowlock) set [status] =@status+ 1 , dateOut = getDate() where grab_id in(''+ @ids +'') and [status] = @status''		
							
		EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
		set @sql=''update RIA_RecNodeHistory with(rowlock) set [status] =@status+ 1 , dateOut = getDate() where grab_id in(''+ @ids +'') and [status] = @status''
							
		EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
	end
end
else if @action = 3 begin--trae el nombre de la base de datos en BX
	select Xname from ccBaseXDB where serviceId = @option and isFull=0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
	insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option, @dateStart, @name,0)
end
else if @action = 11 begin--trae el nombre de la base de datos en BX
	if @option =2 begin
		SELECT ISNULL(min(node.value(''(/R02/@CDATE)[1]'',''datetime'')),GETDATE()) as node FROM RIA_RecNode where status = 0
	end
	end
else if @action =12 begin
	declare @replicationName nvarchar(500)
		select @replicationName = name from msdb.dbo.sysjobs where name like ''%-CCRecorderRIA- 0'' and name like ''%SpecialAVRS%''
		exec msdb.dbo.sp_start_job @job_name = @replicationName
		while(
		SELECT count(*) FROM msdb.dbo.sysjobactivity ja
		LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
		INNER JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
		INNER JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
		WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions   ORDER BY agent_start_date DESC)
		AND start_execution_date is not null AND stop_execution_date is null and j.name=@replicationName
	) > 0
	begin
		WAITFOR DELAY ''00:00:10''
	end
end

else if @action = 13 begin
	set @sql = ''''
	select @tableName=''RIA_RecNode'',@tableNameHistory=''RIA_RecNodeHistory'',@columnId=''grab_id''
	set @sql=''
	;
	with duplicateIds as(
	select ''+@columnId+'',dateIn from ''+@tableName+'' where ''+@columnId+'' in(''+@grabIds+'')
	union
	select ''+@columnId+'',dateIn from ''+@tableNameHistory+'' where ''+@columnId+'' in(''+@grabIds+'')
	)

	select A.''+@columnId+'' as Id,min(B.Xname) Xname from duplicateIds A
	inner join ccbasexDB B on B.serviceId=2 and( A.dateIn between B.dateStart and B.dateEnd or A.dateIn>= B.dateStart)
	group by A.''+@columnId+'',A.dateIn
	Having count(*)>1
	order by Xname
	''
	exec (@sql)

end
else if @action = 14 begin

							
	if exists(
	select id,serviceId,dateStart,dateEnd,Xname,isFull
	FROM ccBaseXDB 
	WHERE serviceId=2
	)select 1
	else select 0
end';
	EXEC(@sql);
		------------------------------------------End Frida .31------------------------------------------------------------

    update trec_parametros set par_valor = @Version where par_id = 30
    set @Version_Actual=@Version_Actual+1

    select par_valor from trec_parametros where par_id = 30

    commit tran

    end try
    begin catch
        select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
        RAISERROR(@errorGenerated, 11, 1)
    rollback tran
    end catch
 end
 else begin
    select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end