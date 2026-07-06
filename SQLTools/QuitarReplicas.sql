USE master;
GO

SET NOCOUNT ON;

DECLARE @sql NVARCHAR(MAX);

PRINT '=== INICIO LIMPIEZA DE REPLICACION ===';

------------------------------------------------------------
-- 1. Quitar replicacion de bases conocidas
------------------------------------------------------------

IF DB_ID(N'ccReportsRia') IS NOT NULL
BEGIN
    BEGIN TRY
        EXEC sys.sp_removedbreplication @dbname = N'ccReportsRia';
        PRINT 'Se quito replicacion de ccReportsRia';
    END TRY
    BEGIN CATCH
        PRINT 'No se pudo quitar replicacion de ccReportsRia: ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    PRINT 'No existe ccReportsRia';
END


IF DB_ID(N'CCRecorderRIA') IS NOT NULL
BEGIN
    BEGIN TRY
        EXEC sys.sp_removedbreplication @dbname = N'CCRecorderRIA';
        PRINT 'Se quito replicacion de CCRecorderRIA';
    END TRY
    BEGIN CATCH
        PRINT 'No se pudo quitar replicacion de CCRecorderRIA: ' + ERROR_MESSAGE();
    END CATCH

    BEGIN TRY
        SET @sql = N'
        USE [CCRecorderRIA];

        EXEC sp_msforeachtable 
            @command1 = ''DECLARE @int INT; 
                          SET @int = OBJECT_ID("?"); 
                          IF @int IS NOT NULL 
                             EXEC sys.sp_identitycolumnforreplication @int, 0;'';
        ';

        EXEC sp_executesql @sql;

        PRINT 'Se deshabilito identity for replication en CCRecorderRIA';
    END TRY
    BEGIN CATCH
        PRINT 'No se pudo limpiar identity for replication en CCRecorderRIA: ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    PRINT 'No existe CCRecorderRIA';
END


IF DB_ID(N'CCenterRia') IS NOT NULL
BEGIN
    BEGIN TRY
        EXEC sys.sp_removedbreplication @dbname = N'CCenterRia';
        PRINT 'Se quito replicacion de CCenterRia';
    END TRY
    BEGIN CATCH
        PRINT 'No se pudo quitar replicacion de CCenterRia: ' + ERROR_MESSAGE();
    END CATCH

    BEGIN TRY
        SET @sql = N'
        USE [CCenterRia];

        EXEC sp_msforeachtable 
            @command1 = ''DECLARE @int INT; 
                          SET @int = OBJECT_ID("?"); 
                          IF @int IS NOT NULL 
                             EXEC sys.sp_identitycolumnforreplication @int, 0;'';
        ';

        EXEC sp_executesql @sql;

        PRINT 'Se deshabilito identity for replication en CCenterRia';
    END TRY
    BEGIN CATCH
        PRINT 'No se pudo limpiar identity for replication en CCenterRia: ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    PRINT 'No existe CCenterRia';
END


------------------------------------------------------------
-- 2. Deshabilitar opciones de publicacion si siguen activas
------------------------------------------------------------

IF DB_ID(N'CCenterRia') IS NOT NULL
BEGIN
    BEGIN TRY
        EXEC sys.sp_replicationdboption 
            @dbname = N'CCenterRia',
            @optname = N'publish',
            @value = N'false';

        PRINT 'Se deshabilito publish en CCenterRia';
    END TRY
    BEGIN CATCH
        PRINT 'No se pudo deshabilitar publish en CCenterRia: ' + ERROR_MESSAGE();
    END CATCH

    BEGIN TRY
        EXEC sys.sp_replicationdboption 
            @dbname = N'CCenterRia',
            @optname = N'merge publish',
            @value = N'false';

        PRINT 'Se deshabilito merge publish en CCenterRia';
    END TRY
    BEGIN CATCH
        PRINT 'No se pudo deshabilitar merge publish en CCenterRia: ' + ERROR_MESSAGE();
    END CATCH
END


IF DB_ID(N'CCRecorderRIA') IS NOT NULL
BEGIN
    BEGIN TRY
        EXEC sys.sp_replicationdboption 
            @dbname = N'CCRecorderRIA',
            @optname = N'publish',
            @value = N'false';

        PRINT 'Se deshabilito publish en CCRecorderRIA';
    END TRY
    BEGIN CATCH
        PRINT 'No se pudo deshabilitar publish en CCRecorderRIA: ' + ERROR_MESSAGE();
    END CATCH

    BEGIN TRY
        EXEC sys.sp_replicationdboption 
            @dbname = N'CCRecorderRIA',
            @optname = N'merge publish',
            @value = N'false';

        PRINT 'Se deshabilito merge publish en CCRecorderRIA';
    END TRY
    BEGIN CATCH
        PRINT 'No se pudo deshabilitar merge publish en CCRecorderRIA: ' + ERROR_MESSAGE();
    END CATCH
END


------------------------------------------------------------
-- 3. Eliminar jobs conocidos de replicacion
------------------------------------------------------------

USE msdb;
GO

SET NOCOUNT ON;

DECLARE @job_id UNIQUEIDENTIFIER;

DECLARE cur_jobs CURSOR LOCAL FAST_FORWARD FOR
SELECT job_id
FROM msdb.dbo.sysjobs
WHERE name IN
(
    N'CW Merge Replication',
    N'AVRS Merge Replication',
    N'AVRSReports Merge Replication'
);

OPEN cur_jobs;

FETCH NEXT FROM cur_jobs INTO @job_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC msdb.dbo.sp_delete_job @job_id = @job_id;
        PRINT 'Job eliminado';
    END TRY
    BEGIN CATCH
        PRINT 'No se pudo eliminar job: ' + ERROR_MESSAGE();
    END CATCH;

    FETCH NEXT FROM cur_jobs INTO @job_id;
END

CLOSE cur_jobs;
DEALLOCATE cur_jobs;

GO

USE master;
GO

SET NOCOUNT ON;

DECLARE @sql NVARCHAR(MAX);

------------------------------------------------------------
-- 4. Intentar quitar el distribuidor
------------------------------------------------------------

BEGIN TRY
    EXEC master.dbo.sp_dropdistributor 
        @no_checks = 1, 
        @ignore_distributor = 1;

    PRINT 'Se ejecuto sp_dropdistributor';
END TRY
BEGIN CATCH
    PRINT 'No se pudo ejecutar sp_dropdistributor: ' + ERROR_MESSAGE();
END CATCH;


------------------------------------------------------------
-- 5. Intentar quitar la base distribution con procedimiento
------------------------------------------------------------

IF DB_ID(N'distribution') IS NOT NULL
BEGIN
    BEGIN TRY
        EXEC master.dbo.sp_dropdistributiondb @database = N'distribution';
        PRINT 'Se elimino distribution con sp_dropdistributiondb';
    END TRY
    BEGIN CATCH
        PRINT 'No se pudo eliminar distribution con sp_dropdistributiondb: ' + ERROR_MESSAGE();
    END CATCH
END


------------------------------------------------------------
-- 6. Forzar eliminacion fisica de distribution si aun existe
------------------------------------------------------------

IF DB_ID(N'distribution') IS NOT NULL
BEGIN
    BEGIN TRY
        PRINT 'La base distribution aun existe. Se forzara SINGLE_USER y DROP DATABASE.';

        ALTER DATABASE [distribution] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

        DROP DATABASE [distribution];

        PRINT 'Se elimino fisicamente la base distribution';
    END TRY
    BEGIN CATCH
        PRINT 'No se pudo eliminar fisicamente distribution: ' + ERROR_MESSAGE();

        BEGIN TRY
            ALTER DATABASE [distribution] SET MULTI_USER;
        END TRY
        BEGIN CATCH
            PRINT 'No se pudo regresar distribution a MULTI_USER: ' + ERROR_MESSAGE();
        END CATCH
    END CATCH
END
ELSE
BEGIN
    PRINT 'La base distribution ya no existe';
END


------------------------------------------------------------
-- 7. Eliminar tablas migration
------------------------------------------------------------

IF DB_ID(N'CCenterRia') IS NOT NULL
BEGIN
    SET @sql = N'
    USE [CCenterRia];

    IF OBJECT_ID(N''dbo.migration'', N''U'') IS NOT NULL
    BEGIN
        DROP TABLE dbo.migration;
        PRINT ''Se elimino dbo.migration en CCenterRia'';
    END

    IF OBJECT_ID(N''dbo.migrationAVRS'', N''U'') IS NOT NULL
    BEGIN
        DROP TABLE dbo.migrationAVRS;
        PRINT ''Se elimino dbo.migrationAVRS en CCenterRia'';
    END
    ';

    EXEC sp_executesql @sql;
END


IF DB_ID(N'CCRecorderRIA') IS NOT NULL
BEGIN
    SET @sql = N'
    USE [CCRecorderRIA];

    IF OBJECT_ID(N''dbo.migrationAVRSReports'', N''U'') IS NOT NULL
    BEGIN
        DROP TABLE dbo.migrationAVRSReports;
        PRINT ''Se elimino dbo.migrationAVRSReports en CCRecorderRIA'';
    END
    ';

    EXEC sp_executesql @sql;
END


------------------------------------------------------------
-- 8. Validacion final
------------------------------------------------------------

PRINT '=== VALIDACION FINAL ===';

SELECT 
    name,
    database_id,
    state_desc
FROM sys.databases
WHERE name IN 
(
    N'distribution',
    N'CCenterRia',
    N'CCRecorderRIA',
    N'ccReportsRia'
);

SELECT 
    name AS job_name
FROM msdb.dbo.sysjobs
WHERE name IN
(
    N'CW Merge Replication',
    N'AVRS Merge Replication',
    N'AVRSReports Merge Replication'
);

EXEC master.dbo.sp_get_distributor;


USE msdb;
GO

SET NOCOUNT ON;

DECLARE 
    @job_id UNIQUEIDENTIFIER,
    @job_name SYSNAME,
    @category_name SYSNAME,
    @is_running BIT;

DECLARE cur_jobs CURSOR LOCAL FAST_FORWARD FOR
SELECT 
    j.job_id,
    j.name,
    c.name AS category_name
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.syscategories c
    ON j.category_id = c.category_id
WHERE 
    c.name LIKE 'REPL%'
    OR j.name LIKE '%Replication%'
    OR j.name LIKE '%REPL%'
    OR j.name LIKE '%Merge%'
    OR j.name LIKE '%Log Reader%'
    OR j.name LIKE '%Distribution%'
    OR j.name LIKE '%Snapshot%';

OPEN cur_jobs;

FETCH NEXT FROM cur_jobs INTO @job_id, @job_name, @category_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Procesando job: ' + @job_name + ' | Categoria: ' + ISNULL(@category_name, '');

    ------------------------------------------------------------
    -- 1. Deshabilitar job
    ------------------------------------------------------------
    BEGIN TRY
        EXEC msdb.dbo.sp_update_job 
            @job_id = @job_id,
            @enabled = 0;

        PRINT '  Job deshabilitado';
    END TRY
    BEGIN CATCH
        PRINT '  No se pudo deshabilitar job: ' + ERROR_MESSAGE();
    END CATCH;


    ------------------------------------------------------------
    -- 2. Validar si esta corriendo
    ------------------------------------------------------------
    SET @is_running = 0;

    IF EXISTS
    (
        SELECT 1
        FROM msdb.dbo.sysjobactivity ja
        INNER JOIN
        (
            SELECT MAX(session_id) AS session_id
            FROM msdb.dbo.syssessions
        ) s
            ON ja.session_id = s.session_id
        WHERE 
            ja.job_id = @job_id
            AND ja.start_execution_date IS NOT NULL
            AND ja.stop_execution_date IS NULL
    )
    BEGIN
        SET @is_running = 1;
    END


    ------------------------------------------------------------
    -- 3. Detener job si esta corriendo
    ------------------------------------------------------------
    IF @is_running = 1
    BEGIN
        BEGIN TRY
            EXEC msdb.dbo.sp_stop_job @job_id = @job_id;
            PRINT '  Job detenido';
        END TRY
        BEGIN CATCH
            PRINT '  No se pudo detener job: ' + ERROR_MESSAGE();
        END CATCH;
    END
    ELSE
    BEGIN
        PRINT '  Job no esta corriendo';
    END


    ------------------------------------------------------------
    -- 4. Eliminar job
    ------------------------------------------------------------
    BEGIN TRY
        EXEC msdb.dbo.sp_delete_job 
            @job_id = @job_id,
            @delete_unused_schedule = 1;

        PRINT '  Job eliminado';
    END TRY
    BEGIN CATCH
        PRINT '  No se pudo eliminar job: ' + ERROR_MESSAGE();
    END CATCH;

    PRINT '------------------------------------------------------------';

    FETCH NEXT FROM cur_jobs INTO @job_id, @job_name, @category_name;
END

CLOSE cur_jobs;
DEALLOCATE cur_jobs;

PRINT 'Proceso terminado';
GO

PRINT '=== FIN LIMPIEZA DE REPLICACION ===';
GO