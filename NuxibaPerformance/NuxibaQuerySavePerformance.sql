USE NuxibaPerformance
GO
/****** Object:  StoredProcedure [dbo].[ccsp_ADMAddAgent]    Script Date: 16/06/2020 07:03:45 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].NuxibaQuerySavePerformance
AS
set nocount on

 IF NOT EXISTS
     (
         SELECT *
         FROM sys.tables
         WHERE name = 'Performance'
     )
         BEGIN
             CREATE TABLE Performance
             (dateStart       DATETIME DEFAULT(GETDATE()), 
              nameProcess     VARCHAR(100) NOT NULL, 
              AverageTime     BIGINT NOT NULL, 
              TotalTime       BIGINT NOT NULL, 
              ExecutionCount  BIGINT NOT NULL, 
              IndividualQuery NVARCHAR(MAX) NOT NULL, 
              ParentQuery     NVARCHAR(MAX) NOT NULL, 
              DatabaseName    SYSNAME NULL
             );
     END;
     INSERT INTO Performance
     (nameProcess, 
      AverageTime, 
      TotalTime, 
      ExecutionCount, 
      IndividualQuery, 
      ParentQuery, 
      DatabaseName
     )
            SELECT TOP 50 'Block' AS nameProcess, 
                          [Average Time Blocked] = (total_elapsed_time - total_worker_time) / qs.execution_count, 
                          [Total Time Blocked] = total_elapsed_time - total_worker_time, 
                          [Execution count] = qs.execution_count, 
                          [Individual Query] = SUBSTRING(qt.text, qs.statement_start_offset / 2, (CASE
                                                                                                      WHEN qs.statement_end_offset = -1
                                                                                                      THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
                                                                                                      ELSE qs.statement_end_offset
                                                                                                  END - qs.statement_start_offset) / 2), 
                          [Parent Query] = qt.text, 
                          DatabaseName = DB_NAME(qt.dbid)
            FROM sys.dm_exec_query_stats qs
                 CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
            --where DB_NAME(qt.dbid) is not null
            ORDER BY [Average Time Blocked] DESC;
     INSERT INTO Performance
     (nameProcess, 
      AverageTime, 
      TotalTime, 
      ExecutionCount, 
      IndividualQuery, 
      ParentQuery, 
      DatabaseName
     )
            SELECT TOP 50 'E/S' AS nameProcess, 
                          [Average IO] = (total_logical_reads + total_logical_writes) / qs.execution_count, 
                          [Total IO] = (total_logical_reads + total_logical_writes), 
                          [Execution count] = qs.execution_count, 
                          [Individual Query] = SUBSTRING(qt.text, qs.statement_start_offset / 2, (CASE
                                                                                                      WHEN qs.statement_end_offset = -1
                                                                                                      THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
                                                                                                      ELSE qs.statement_end_offset
                                                                                                  END - qs.statement_start_offset) / 2), 
                          [Parent Query] = qt.text, 
                          DatabaseName = DB_NAME(qt.dbid)
            FROM sys.dm_exec_query_stats qs
                 CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
            --where DB_NAME(qt.dbid) is not null
            ORDER BY [Average IO] DESC;
     INSERT INTO Performance
     (nameProcess, 
      AverageTime, 
      TotalTime, 
      ExecutionCount, 
      IndividualQuery, 
      ParentQuery, 
      DatabaseName
     )
            SELECT TOP 50 'CPU' AS nameProcess, 
                          [Average CPU used] = total_worker_time / qs.execution_count, 
                          [Total CPU used] = total_worker_time, 
                          [Execution count] = qs.execution_count, 
                          [Individual Query] = SUBSTRING(qt.text, qs.statement_start_offset / 2, (CASE
                                                                                                      WHEN qs.statement_end_offset = -1
                                                                                                      THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
                                                                                                      ELSE qs.statement_end_offset
                                                                                                  END - qs.statement_start_offset) / 2), 
                          [Parent Query] = qt.text, 
                          DatabaseName = DB_NAME(qt.dbid)
            FROM sys.dm_exec_query_stats qs
                 CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
            ORDER BY [Average CPU used] DESC;
set nocount off