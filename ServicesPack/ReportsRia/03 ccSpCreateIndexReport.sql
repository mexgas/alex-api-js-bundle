USE [CCReportsRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccSpCreateIndexReport]    Script Date: 20/03/2026 12:54:45 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccSpCreateIndexReport]  
AS
BEGIN
    SET NOCOUNT ON;

declare @tIndexMerge table(id int identity,tableName varchar(255),status bit)
declare @sql nvarchar(max),@tableName varchar(255),@id int
declare @column varchar(255),@indexName varchar(255)

/****************************INDICES PARA REPORTES *******************************/
if not exists (select * from sys.indexes where name = N'IX_ccoCallsOut13' and object_id = OBJECT_ID(N'ccoCallsOut'))
begin
   CREATE NONCLUSTERED INDEX IX_ccoCallsOut13
ON [dbo].[ccoCallsOut] ([cal_Inicio])
INCLUDE ([cal_id],[cal_telefono],[cal_puerto],[cam_id],[User_id],[statusCall_id],[calif_id],[cal_tDialog],[cal_tNotas],[cal_tXfer],[cal_tRing],[cal_manual],[cal_tMoh],[cal_whoHung],[cal_twait])
end

if not exists (select * from sys.indexes where name = N'IX_RIA_GRABACION_11' and object_id = OBJECT_ID(N'RIA_GRABACION'))
begin
CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_11
ON [dbo].[RIA_GRABACION] ([tipo_llamada],[cal_id])
INCLUDE ([grab_id])
end

if not exists (select * from sys.indexes where name = N'IX_ccLogTransfers_3' and object_id = OBJECT_ID(N'ccLogtransfers'))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogTransfers_3
ON [dbo].[ccLogtransfers] ([fechaFin])
INCLUDE ([cal_id],[tipo],[modo],[destino],[tAntesXfer],[tDespuesXfer])
end

if not exists (select * from sys.indexes where name = N'IX_ccLogAgentesDia_6' and object_id = OBJECT_ID(N'ccLogAgentesDia'))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_6
ON [dbo].[ccLogAgentesDia] ([fecha])
INCLUDE ([User_id],[TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N'IX_ccLogAgentesNotReady_5' and object_id = OBJECT_ID(N'cclogagentesnotready'))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesNotReady_5
ON [dbo].[cclogagentesnotready] ([fecha])
INCLUDE ([User_id],[TipoNotReady_id],[tStatus])
end
    
if not exists (select * from sys.indexes where name = N'IX_ccLogLogin_6' and object_id = OBJECT_ID(N'ccloglogin'))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogLogin_6
ON [dbo].[ccloglogin] ([fecha])
INCLUDE ([User_id],[Extension],[TipoMov])
end

if not exists (select * from sys.indexes where name = N'IX_ccoLogDials_8' and object_id = OBJECT_ID(N'ccoLogDials'))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_8
ON [dbo].[ccoLogDials] ([fecha],[cal_id])
INCLUDE ([tipoResDial_id])
end

if not exists (select * from sys.indexes where name = N'IX_ccCallsIn_8' and object_id = OBJECT_ID(N'ccCallsIn'))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_8
ON [dbo].[ccCallsIn] ([IVR_id])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N'IX_ccCallsIn_9' and object_id = OBJECT_ID(N'ccCallsIn'))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_9
ON [dbo].[ccCallsIn] ([cal_Inicio])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N'IX_tmpSessionTimeGroup_1' and object_id = OBJECT_ID(N'tmpSessionTimeGroup'))
begin
CREATE NONCLUSTERED INDEX IX_tmpSessionTimeGroup_1
ON [dbo].[tmpSessionTimeGroup] ([user_id])
INCLUDE ([timegroup],[tlog])
end
   
if not exists (select * from sys.indexes where name = N'IX_tmpccLogAgentesDia_2' and object_id = OBJECT_ID(N'tmpccLogAgentesDia'))
begin
CREATE NONCLUSTERED INDEX IX_tmpccLogAgentesDia_2
ON [dbo].[tmpccLogAgentesDia] ([userId],[timeGroup])
INCLUDE ([TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N'IX_tmpTimesInboundData_1' and object_id = OBJECT_ID(N'tmpTimesInboundData'))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_1
ON [dbo].[tmpTimesInboundData] ([statusCall_id])
INCLUDE ([timegroup],[Inbound_id],[nabnd],[tque],[txfer],[tring])
end
    
if not exists (select * from sys.indexes where name = N'IX_tmpTimesInboundData_2' and object_id = OBJECT_ID(N'tmpTimesInboundData'))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_2
ON [dbo].[tmpTimesInboundData] ([cal_id])
INCLUDE ([Inbound_id],[User_id])
end

if not exists (select * from sys.indexes where name = N'IX_tmpTimesOutboundData_1' and object_id = OBJECT_ID(N'tmpTimesOutboundData'))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_1
ON [dbo].[tmpTimesOutboundData] ([timegroup],[cal_id])
INCLUDE ([User_id])
end
    
if not exists (select * from sys.indexes where name = N'IX_tmpTimesOutboundData_2' and object_id = OBJECT_ID(N'tmpTimesOutboundData'))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_2
ON [dbo].[tmpTimesOutboundData] ([cal_manual])
INCLUDE ([timegroup],[User_id],[nabnd_xfer],[nabnd_ring],[tdialog],[tnotes],[cal_id])
end


/**************************** INDICES Reportes *******************************/
set @column='date'
delete from @tIndexMerge

insert into @tIndexMerge(tableName,status)
SELECT     
    t.TABLE_NAME,0
FROM 
    INFORMATION_SCHEMA.COLUMNS c
INNER JOIN 
    INFORMATION_SCHEMA.TABLES t 
    ON c.TABLE_NAME = t.TABLE_NAME AND c.TABLE_SCHEMA = t.TABLE_SCHEMA
WHERE 
    t.TABLE_NAME LIKE 'Rep%'
    AND c.COLUMN_NAME = 'date'
    AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY 
    t.TABLE_SCHEMA, t.TABLE_NAME;

while exists(select 1 from @tIndexMerge where status=0) begin
    select top 1 @tableName=tableName,@id=id from @tIndexMerge where status=0 
    set @indexName=N'IX_'+ @tableName+'_date' 

    set @sql='
-- Validar que NO exista ya un indice equivalente NONCLUSTERED ([date])
if not exists
(
    SELECT 1
    FROM sys.indexes i
    WHERE i.object_id = OBJECT_ID(@tableName)
      AND i.is_hypothetical = 0
      AND i.type = 2 -- NONCLUSTERED
      AND i.is_primary_key = 0
      AND i.is_unique_constraint = 0

      -- Debe tener exactamente una columna key
      AND
      (
          SELECT COUNT(*)
          FROM sys.index_columns ic
          WHERE ic.object_id = i.object_id
            AND ic.index_id = i.index_id
            AND ic.is_included_column = 0
      ) = 1

      -- No debe tener columnas INCLUDE
      AND
      (
          SELECT COUNT(*)
          FROM sys.index_columns ic
          WHERE ic.object_id = i.object_id
            AND ic.index_id = i.index_id
            AND ic.is_included_column = 1
      ) = 0

      -- La unica columna key debe ser [date]
      AND exists
      (
          SELECT 1
          FROM sys.index_columns ic
          INNER JOIN sys.columns c
              ON ic.object_id = c.object_id
             AND ic.column_id = c.column_id
          WHERE ic.object_id = i.object_id
            AND ic.index_id = i.index_id
            AND ic.is_included_column = 0
            AND ic.key_ordinal = 1
            AND c.name=@column
      )
)

-- Seguridad adicional: evitar duplicar nombre del indice
and not exists
(
    select 1
    from sys.indexes
    where name = @indexName
      and object_id = OBJECT_ID(@tableName)
)

-- Validar que la columna exista en la tabla
and exists
(
    select 1
    from sys.columns
    where name = @column
      and object_id = object_id(@tableName)
)

begin
    CREATE NONCLUSTERED INDEX '+@indexName+'
    ON [dbo].['+@tableName+'] ([date])
end
    '

    EXEC sp_executesql @sql, 
    N'@tableName varchar(255),@column varchar(255),@indexName varchar(255)', 
    @tableName = @tableName, 
    @indexName = @indexName,
    @column = @column;
	--print (@sql)

    update @tIndexMerge set status=1 where @id=id
end


    
if not exists (select * from sys.indexes where name = N'IX_RepAgentNotReadyDet_2' and object_id = OBJECT_ID(N'RepAgentNotReadyDet'))
begin
CREATE NONCLUSTERED INDEX IX_RepAgentNotReadyDet_2
ON [dbo].[RepAgentNotReadyDet] ([tiponotreadyId],[startDate])
INCLUDE ([userId],[status],[statusTime])
end

 

end