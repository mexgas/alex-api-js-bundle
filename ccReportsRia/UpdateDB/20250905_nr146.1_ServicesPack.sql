/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2025/03/25
Description: ServicesPACK9

Database: CCReportsRIA
Required version: 146

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON --

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 146 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		--- BEGIN Services Pack 1-8 --

    SET @process = 'ALTER TABLE RepOutCallsDetail ADD callStatusId tinyint NULL;'
    SET @sql = 'IF NOT EXISTS (
    SELECT TOP 1 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(''RepOutCallsDetail'') 
      AND name = ''callStatusId''
)
BEGIN
    ALTER TABLE RepOutCallsDetail ADD callStatusId tinyint NULL;
END'
    exec (@sql)

    SET @process = ''
    SET @sql = 'CREATE VIEW [dbo].[RepViewOutCallsDetail] AS 
    SELECT
    [date],
    [callKey],
    [originNumber],
    [telephone],
    [transfer] as transferTime,
    [queueTimes],
    [ringingTime],
    [dialog],
    [nque],
    [wrapup],
    [CallDisposition],
    [subDisposition],
    [callbackDate],
    [extension],
    [userId],
    [login] [agentName],
    [username] [login],
    [campaign],
    [duration],
    [ncost],
    [iva],
    [total] as [totalRow],
    [ByCarrier],
    [Calltypes],
    [dialType],
    [whoHangUp],
    [dialResult] as [callStatus],
    [calId],
    [year],
    [month],
    [day],
    [hour],
    [minutes],
    [trunk],
    [data1] [Dato1],
    [data2] [Dato2],
    [data3] [Dato3],
    [data4] [Dato4],
    [data5] [Dato5],
    [MessageTime],
    [grabId],
    [campaignId],
    [areaId],
    [area],
    [callStatusId]
    FROM RepOutCallsDetail nolock
'
    exec (@sql)

    SET @process = 'ALTER TABLE RepOutSMSSentMessagesDetail.SystemApiId'
    SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE Name = N''SystemApiId''
      AND Object_ID = Object_ID(N''RepOutSMSSentMessagesDetail'')
)
BEGIN
    ALTER TABLE RepOutSMSSentMessagesDetail
    ADD SystemApiId VARCHAR(100) NULL;
END'
    exec (@sql)

	SET @process = '#6535 ALTER VIEW [dbo].[ccUserView]'
	SET @sql = 'ALTER VIEW [dbo].[ccUserView] AS
SELECT 
    User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, 
    TipoStatusAge_id, TipoUser_id, Status, Sexo, isnull(IDArea,1) IDArea, fCreate 
FROM ccUsers
UNION
SELECT 
    User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, 
    TipoStatusAge_id, TipoUser_id, Status, Sexo, isnull(IDArea,1) IDArea, fCreate 
FROM ccUsers_Consulta;'
	exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccSpCreateIndexReport]  '
    SET @sql = 'ALTER PROCEDURE [dbo].[ccSpCreateIndexReport]  
AS
BEGIN
    SET NOCOUNT ON;

declare @tIndexMerge table(id int identity,tableName varchar(255),status bit)
declare @sql nvarchar(max),@tableName varchar(255),@id int
declare @column varchar(255),@indexName varchar(255)

/****************************INDICES PARA REPORTES *******************************/
if not exists (select * from sys.indexes where name = N''IX_ccoCallsOut13'' and object_id = OBJECT_ID(N''ccoCallsOut''))
begin
   CREATE NONCLUSTERED INDEX IX_ccoCallsOut13
ON [dbo].[ccoCallsOut] ([cal_Inicio])
INCLUDE ([cal_id],[cal_telefono],[cal_puerto],[cam_id],[User_id],[statusCall_id],[calif_id],[cal_tDialog],[cal_tNotas],[cal_tXfer],[cal_tRing],[cal_manual],[cal_tMoh],[cal_whoHung],[cal_twait])
end

if not exists (select * from sys.indexes where name = N''IX_RIA_GRABACION_11'' and object_id = OBJECT_ID(N''RIA_GRABACION''))
begin
CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_11
ON [dbo].[RIA_GRABACION] ([tipo_llamada],[cal_id])
INCLUDE ([grab_id])
end

if not exists (select * from sys.indexes where name = N''IX_ccLogTransfers_3'' and object_id = OBJECT_ID(N''ccLogtransfers''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogTransfers_3
ON [dbo].[ccLogtransfers] ([fechaFin])
INCLUDE ([cal_id],[tipo],[modo],[destino],[tAntesXfer],[tDespuesXfer])
end

if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesDia_6'' and object_id = OBJECT_ID(N''ccLogAgentesDia''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_6
ON [dbo].[ccLogAgentesDia] ([fecha])
INCLUDE ([User_id],[TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesNotReady_5'' and object_id = OBJECT_ID(N''cclogagentesnotready''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesNotReady_5
ON [dbo].[cclogagentesnotready] ([fecha])
INCLUDE ([User_id],[TipoNotReady_id],[tStatus])
end
    
if not exists (select * from sys.indexes where name = N''IX_ccLogLogin_6'' and object_id = OBJECT_ID(N''ccloglogin''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogLogin_6
ON [dbo].[ccloglogin] ([fecha])
INCLUDE ([User_id],[Extension],[TipoMov])
end

if not exists (select * from sys.indexes where name = N''IX_ccoLogDials_8'' and object_id = OBJECT_ID(N''ccoLogDials''))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_8
ON [dbo].[ccoLogDials] ([fecha],[cal_id])
INCLUDE ([tipoResDial_id])
end

if not exists (select * from sys.indexes where name = N''IX_ccCallsIn_8'' and object_id = OBJECT_ID(N''ccCallsIn''))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_8
ON [dbo].[ccCallsIn] ([IVR_id])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N''IX_ccCallsIn_9'' and object_id = OBJECT_ID(N''ccCallsIn''))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_9
ON [dbo].[ccCallsIn] ([cal_Inicio])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N''IX_tmpSessionTimeGroup_1'' and object_id = OBJECT_ID(N''tmpSessionTimeGroup''))
begin
CREATE NONCLUSTERED INDEX IX_tmpSessionTimeGroup_1
ON [dbo].[tmpSessionTimeGroup] ([user_id])
INCLUDE ([timegroup],[tlog])
end
   
if not exists (select * from sys.indexes where name = N''IX_tmpccLogAgentesDia_2'' and object_id = OBJECT_ID(N''tmpccLogAgentesDia''))
begin
CREATE NONCLUSTERED INDEX IX_tmpccLogAgentesDia_2
ON [dbo].[tmpccLogAgentesDia] ([userId],[timeGroup])
INCLUDE ([TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N''IX_tmpTimesInboundData_1'' and object_id = OBJECT_ID(N''tmpTimesInboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_1
ON [dbo].[tmpTimesInboundData] ([statusCall_id])
INCLUDE ([timegroup],[Inbound_id],[nabnd],[tque],[txfer],[tring])
end
    
if not exists (select * from sys.indexes where name = N''IX_tmpTimesInboundData_2'' and object_id = OBJECT_ID(N''tmpTimesInboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_2
ON [dbo].[tmpTimesInboundData] ([cal_id])
INCLUDE ([Inbound_id],[User_id])
end

if not exists (select * from sys.indexes where name = N''IX_tmpTimesOutboundData_1'' and object_id = OBJECT_ID(N''tmpTimesOutboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_1
ON [dbo].[tmpTimesOutboundData] ([timegroup],[cal_id])
INCLUDE ([User_id])
end
    
if not exists (select * from sys.indexes where name = N''IX_tmpTimesOutboundData_2'' and object_id = OBJECT_ID(N''tmpTimesOutboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_2
ON [dbo].[tmpTimesOutboundData] ([cal_manual])
INCLUDE ([timegroup],[User_id],[nabnd_xfer],[nabnd_ring],[tdialog],[tnotes],[cal_id])
end


/**************************** INDICES Reportes *******************************/
set @column=''date''
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
    t.TABLE_NAME LIKE ''Rep%''
    AND c.COLUMN_NAME = ''date''
    AND t.TABLE_TYPE = ''BASE TABLE''
ORDER BY 
    t.TABLE_SCHEMA, t.TABLE_NAME;

while exists(select 1 from @tIndexMerge where status=0) begin
    select top 1 @tableName=tableName,@id=id from @tIndexMerge where status=0 
    set @indexName=N''IX_''+ @tableName+''_date'' 

    set @sql=''
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
    CREATE NONCLUSTERED INDEX ''+@indexName+''
    ON [dbo].[''+@tableName+''] ([date])
end
    ''

    EXEC sp_executesql @sql, 
    N''@tableName varchar(255),@column varchar(255),@indexName varchar(255)'', 
    @tableName = @tableName, 
    @indexName = @indexName,
    @column = @column;
    --print (@sql)

    update @tIndexMerge set status=1 where @id=id
end


    
if not exists (select * from sys.indexes where name = N''IX_RepAgentNotReadyDet_2'' and object_id = OBJECT_ID(N''RepAgentNotReadyDet''))
begin
CREATE NONCLUSTERED INDEX IX_RepAgentNotReadyDet_2
ON [dbo].[RepAgentNotReadyDet] ([tiponotreadyId],[startDate])
INCLUDE ([userId],[status],[statusTime])
end

 

end'
    exec (@sql)

    SET @process = 'DROP INDEX DATE REP'
    SET @sql = '
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepACDChats_date''AND object_id = OBJECT_ID(''RepACDChats'') ) BEGIN DROP INDEX IX_RepACDChats_date ON RepACDChats END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentCallStatusesByInterval_date''AND object_id = OBJECT_ID(''RepAgentCallStatusesByInterval'') ) BEGIN DROP INDEX IX_RepAgentCallStatusesByInterval_date ON RepAgentCallStatusesByInterval END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentGI_VersionOld_date''AND object_id = OBJECT_ID(''RepAgentGI_VersionOld'') ) BEGIN DROP INDEX IX_RepAgentGI_VersionOld_date ON RepAgentGI_VersionOld END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentHSBCKPI_date''AND object_id = OBJECT_ID(''RepAgentHSBCKPI'') ) BEGIN DROP INDEX IX_RepAgentHSBCKPI_date ON RepAgentHSBCKPI END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAgentSummary_date''AND object_id = OBJECT_ID(''RepAgentSummary'') ) BEGIN DROP INDEX IX_RepAgentSummary_date ON RepAgentSummary END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAnsweredCallsByDialingRetries_date''AND object_id = OBJECT_ID(''RepAnsweredCallsByDialingRetries'') ) BEGIN DROP INDEX IX_RepAnsweredCallsByDialingRetries_date ON RepAnsweredCallsByDialingRetries END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAvgAnswerTimeChats_date''AND object_id = OBJECT_ID(''RepAvgAnswerTimeChats'') ) BEGIN DROP INDEX IX_RepAvgAnswerTimeChats_date ON RepAvgAnswerTimeChats END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepAVRSDisposition_date''AND object_id = OBJECT_ID(''RepAVRSDisposition'') ) BEGIN DROP INDEX IX_RepAVRSDisposition_date ON RepAVRSDisposition END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepCallTimeSummary_date''AND object_id = OBJECT_ID(''RepCallTimeSummary'') ) BEGIN DROP INDEX IX_RepCallTimeSummary_date ON RepCallTimeSummary END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepCallXfer_date''AND object_id = OBJECT_ID(''RepCallXfer'') ) BEGIN DROP INDEX IX_RepCallXfer_date ON RepCallXfer END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepChatsAndCallsGeneral_date''AND object_id = OBJECT_ID(''RepChatsAndCallsGeneral'') ) BEGIN DROP INDEX IX_RepChatsAndCallsGeneral_date ON RepChatsAndCallsGeneral END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepChatsDetail_date''AND object_id = OBJECT_ID(''RepChatsDetail'') ) BEGIN DROP INDEX IX_RepChatsDetail_date ON RepChatsDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepChatsEffectiveness_date''AND object_id = OBJECT_ID(''RepChatsEffectiveness'') ) BEGIN DROP INDEX IX_RepChatsEffectiveness_date ON RepChatsEffectiveness END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepChatsNotContacted_date''AND object_id = OBJECT_ID(''RepChatsNotContacted'') ) BEGIN DROP INDEX IX_RepChatsNotContacted_date ON RepChatsNotContacted END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepDetailAgent_date''AND object_id = OBJECT_ID(''RepDetailAgent'') ) BEGIN DROP INDEX IX_RepDetailAgent_date ON RepDetailAgent END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepDialingResultsDetail_date''AND object_id = OBJECT_ID(''RepDialingResultsDetail'') ) BEGIN DROP INDEX IX_RepDialingResultsDetail_date ON RepDialingResultsDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepEmailACD_date''AND object_id = OBJECT_ID(''RepEmailACD'') ) BEGIN DROP INDEX IX_RepEmailACD_date ON RepEmailACD END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepEmailAgente_date''AND object_id = OBJECT_ID(''RepEmailAgente'') ) BEGIN DROP INDEX IX_RepEmailAgente_date ON RepEmailAgente END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepEmailDetail_date''AND object_id = OBJECT_ID(''RepEmailDetail'') ) BEGIN DROP INDEX IX_RepEmailDetail_date ON RepEmailDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepEmailGeneral_date''AND object_id = OBJECT_ID(''RepEmailGeneral'') ) BEGIN DROP INDEX IX_RepEmailGeneral_date ON RepEmailGeneral END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInAbnd_date''AND object_id = OBJECT_ID(''RepInAbnd'') ) BEGIN DROP INDEX IX_RepInAbnd_date ON RepInAbnd END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInAnsw_date''AND object_id = OBJECT_ID(''RepInAnsw'') ) BEGIN DROP INDEX IX_RepInAnsw_date ON RepInAnsw END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInBill01900_date''AND object_id = OBJECT_ID(''RepInBill01900'') ) BEGIN DROP INDEX IX_RepInBill01900_date ON RepInBill01900 END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInboundKPI_date''AND object_id = OBJECT_ID(''RepInboundKPI'') ) BEGIN DROP INDEX IX_RepInboundKPI_date ON RepInboundKPI END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInCalls_date''AND object_id = OBJECT_ID(''RepInCalls'') ) BEGIN DROP INDEX IX_RepInCalls_date ON RepInCalls END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInCallsDetail_date''AND object_id = OBJECT_ID(''RepInCallsDetail'') ) BEGIN DROP INDEX IX_RepInCallsDetail_date ON RepInCallsDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInChangeFlow_date''AND object_id = OBJECT_ID(''RepInChangeFlow'') ) BEGIN DROP INDEX IX_RepInChangeFlow_date ON RepInChangeFlow END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInDIDResume_date''AND object_id = OBJECT_ID(''RepInDIDResume'') ) BEGIN DROP INDEX IX_RepInDIDResume_date ON RepInDIDResume END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInDispositions_date''AND object_id = OBJECT_ID(''RepInDispositions'') ) BEGIN DROP INDEX IX_RepInDispositions_date ON RepInDispositions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInEffectiveness_date''AND object_id = OBJECT_ID(''RepInEffectiveness'') ) BEGIN DROP INDEX IX_RepInEffectiveness_date ON RepInEffectiveness END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInNotTransferred_date''AND object_id = OBJECT_ID(''RepInNotTransferred'') ) BEGIN DROP INDEX IX_RepInNotTransferred_date ON RepInNotTransferred END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInRejectedCalls_date''AND object_id = OBJECT_ID(''RepInRejectedCalls'') ) BEGIN DROP INDEX IX_RepInRejectedCalls_date ON RepInRejectedCalls END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInSubDispositions_date''AND object_id = OBJECT_ID(''RepInSubDispositions'') ) BEGIN DROP INDEX IX_RepInSubDispositions_date ON RepInSubDispositions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepInTrunkBusy_date''AND object_id = OBJECT_ID(''RepInTrunkBusy'') ) BEGIN DROP INDEX IX_RepInTrunkBusy_date ON RepInTrunkBusy END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepIVRByOptions_date''AND object_id = OBJECT_ID(''RepIVRByOptions'') ) BEGIN DROP INDEX IX_RepIVRByOptions_date ON RepIVRByOptions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepIVRDetail_date''AND object_id = OBJECT_ID(''RepIVRDetail'') ) BEGIN DROP INDEX IX_RepIVRDetail_date ON RepIVRDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepIVRFirstOption_date''AND object_id = OBJECT_ID(''RepIVRFirstOption'') ) BEGIN DROP INDEX IX_RepIVRFirstOption_date ON RepIVRFirstOption END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepIVRGeneral_date''AND object_id = OBJECT_ID(''RepIVRGeneral'') ) BEGIN DROP INDEX IX_RepIVRGeneral_date ON RepIVRGeneral END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutAnswCalls_date''AND object_id = OBJECT_ID(''RepOutAnswCalls'') ) BEGIN DROP INDEX IX_RepOutAnswCalls_date ON RepOutAnswCalls END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutboundKPI_date''AND object_id = OBJECT_ID(''RepOutboundKPI'') ) BEGIN DROP INDEX IX_RepOutboundKPI_date ON RepOutboundKPI END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutCallBacks_date''AND object_id = OBJECT_ID(''RepOutCallBacks'') ) BEGIN DROP INDEX IX_RepOutCallBacks_date ON RepOutCallBacks END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutCalls_date''AND object_id = OBJECT_ID(''RepOutCalls'') ) BEGIN DROP INDEX IX_RepOutCalls_date ON RepOutCalls END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutCallsByTelephone_date''AND object_id = OBJECT_ID(''RepOutCallsByTelephone'') ) BEGIN DROP INDEX IX_RepOutCallsByTelephone_date ON RepOutCallsByTelephone END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutCallsDetail_date''AND object_id = OBJECT_ID(''RepOutCallsDetail'') ) BEGIN DROP INDEX IX_RepOutCallsDetail_date ON RepOutCallsDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutCallsOnChatDetail_date''AND object_id = OBJECT_ID(''RepOutCallsOnChatDetail'') ) BEGIN DROP INDEX IX_RepOutCallsOnChatDetail_date ON RepOutCallsOnChatDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutDialDetail_date''AND object_id = OBJECT_ID(''RepOutDialDetail'') ) BEGIN DROP INDEX IX_RepOutDialDetail_date ON RepOutDialDetail END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutDials_date''AND object_id = OBJECT_ID(''RepOutDials'') ) BEGIN DROP INDEX IX_RepOutDials_date ON RepOutDials END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutDispositions_date''AND object_id = OBJECT_ID(''RepOutDispositions'') ) BEGIN DROP INDEX IX_RepOutDispositions_date ON RepOutDispositions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutKPI_date''AND object_id = OBJECT_ID(''RepOutKPI'') ) BEGIN DROP INDEX IX_RepOutKPI_date ON RepOutKPI END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutSubDispositions_date''AND object_id = OBJECT_ID(''RepOutSubDispositions'') ) BEGIN DROP INDEX IX_RepOutSubDispositions_date ON RepOutSubDispositions END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepOutTrunkBusy_date''AND object_id = OBJECT_ID(''RepOutTrunkBusy'') ) BEGIN DROP INDEX IX_RepOutTrunkBusy_date ON RepOutTrunkBusy END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpececialAbnd_date''AND object_id = OBJECT_ID(''RepSpececialAbnd'') ) BEGIN DROP INDEX IX_RepSpececialAbnd_date ON RepSpececialAbnd END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpececialAgent_date''AND object_id = OBJECT_ID(''RepSpececialAgent'') ) BEGIN DROP INDEX IX_RepSpececialAgent_date ON RepSpececialAgent END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpececialAgtPerformance_date''AND object_id = OBJECT_ID(''RepSpececialAgtPerformance'') ) BEGIN DROP INDEX IX_RepSpececialAgtPerformance_date ON RepSpececialAgtPerformance END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpececialCamMovs_date''AND object_id = OBJECT_ID(''RepSpececialCamMovs'') ) BEGIN DROP INDEX IX_RepSpececialCamMovs_date ON RepSpececialCamMovs END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpececialPromises_date''AND object_id = OBJECT_ID(''RepSpececialPromises'') ) BEGIN DROP INDEX IX_RepSpececialPromises_date ON RepSpececialPromises END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpecialCallKeyHistory_date''AND object_id = OBJECT_ID(''RepSpecialCallKeyHistory'') ) BEGIN DROP INDEX IX_RepSpecialCallKeyHistory_date ON RepSpecialCallKeyHistory END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepSpecialTimes_date''AND object_id = OBJECT_ID(''RepSpecialTimes'') ) BEGIN DROP INDEX IX_RepSpecialTimes_date ON RepSpecialTimes END
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepTrunkBusy_date''AND object_id = OBJECT_ID(''RepTrunkBusy'') ) BEGIN DROP INDEX IX_RepTrunkBusy_date ON RepTrunkBusy END


IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = ''IX_RepOutDialDetail''
    AND object_id = OBJECT_ID(''RepOutDialDetail'')
)
BEGIN
    DROP INDEX IX_RepOutDialDetail ON RepOutDialDetail;
END



IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = ''IX_RepOutDialDetail_date''
    AND object_id = OBJECT_ID(''RepOutDialDetail'')
)
BEGIN
    DROP INDEX IX_RepOutDialDetail_date ON RepOutDialDetail;
END
'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail] 
@action AS TINYINT,
@from   AS DATETIME = NULL,
@to     AS DATETIME = NULL
AS
--declare
--@action AS TINYINT = 1,
--@from   AS DATETIME = ''2026-04-23 00:00:000'',
--@to     AS DATETIME = ''2026-04-23 23:59:000''
SET NOCOUNT ON

IF @from IS NULL
    SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()))

IF @to IS NULL
    SELECT @to = GETDATE()

IF @action = 1
BEGIN
    DECLARE @country SMALLINT

    SELECT @country = valor
    FROM ccSettings
    WHERE setting_id = 104

    DELETE FROM RepOutDialDetail
    WHERE [date] >= @from
      AND [date] < @to

    IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL DROP TABLE #dials
    IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL DROP TABLE #codeSip
    IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL DROP TABLE #relationCodeSip

    CREATE TABLE #dials
    (
        logDial_id        INT          NOT NULL,
        callout_id        INT          NOT NULL,
        cam_id            INT          NOT NULL,
        tipoResDial_id    SMALLINT     NOT NULL,
        resultDialDesc    VARCHAR(50)  NOT NULL,
        Telefono          VARCHAR(30)  NOT NULL,
        Puerto            SMALLINT     NOT NULL,
        fecha             DATETIME     NOT NULL,
        tDialing          SMALLINT     NOT NULL,
        dialType          VARCHAR(50)  NULL,
        tBusy             SMALLINT     NOT NULL,
        answerbit         BIT          NULL,
        canceledNoAgents  BIT          NULL,
        cal_id            INT          NOT NULL,
        disconnectCause   VARCHAR(250) NOT NULL,
        cal_key           VARCHAR(40)  NULL,
        file_moved        TINYINT      NULL,
        tipoLlamada_id    SMALLINT     NULL,
        CallDisposition   VARCHAR(150) NULL,
        CallDisposition_IA VARCHAR(150)NULL,
        califSubDesc      VARCHAR(150) NULL,
        codeSip           VARCHAR(3)   NOT NULL,
        TipoTel           VARCHAR(30)  NOT NULL,
        tpreview          SMALLINT     NOT NULL,
        UserID            SMALLINT     NOT NULL,
        virtualAgentId    int          NOT NULL,
        ani               VARCHAR(32)  NOT NULL,
        CapturedData      Varchar(MAX) NOT NULL
    )

    INSERT INTO #dials
    (
        logDial_id,
        callout_id,
        cam_id,
        tipoResDial_id,
        resultDialDesc,
        Telefono,
        Puerto,
        fecha,
        tDialing,
        dialType,
        tBusy,
        answerbit,
        canceledNoAgents,
        cal_id,
        disconnectCause,
        cal_key,
        file_moved,
        tipoLlamada_id,
        CallDisposition,
        califSubDesc,
        codeSip,
        TipoTel,
        tpreview,
        UserID,
        virtualAgentId,
        ani,
        CapturedData,
        CallDisposition_IA
    )
    SELECT
         dial.logDial_id
        ,dial.callout_id
        ,dial.cam_id
        ,CASE 
            WHEN co.statusCall_Id = 20 THEN 15 
            WHEN dial.canceledNoAgents = 1 THEN 14 
            ELSE dial.tipoResDial_id 
         END AS tipoResDial_id
        ,CASE 
            WHEN co.statusCall_Id = 20 THEN ''systemTranslated_QuantumVoicemail'' 
            ELSE ISNULL(tr.descTranslate,'''') 
         END AS resultDialDesc
        ,dial.Telefono AS cal_telefono
        ,dial.Puerto
        ,dial.fecha
        ,ISNULL(co.cal_tDialog, 0) AS cal_tDialog
        ,CASE WHEN dial.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview''
              WHEN SUBSTRING(dial.TipoDialingMode, 2, 1) = ''1'' AND co.cal_manual = 0 THEN ''systemTranslated_Assisted''
              WHEN RIGHT(dial.TipoDialingMode,5) IN (''01000'',''10000'') THEN ''systemTranslated_Callback''
              WHEN RIGHT(dial.TipoDialingMode, 2) = ''00'' THEN ''systemTranslated_Auto''
              WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') AND ISNULL(dial.manualCRM,0) = 1 THEN ''systemTranslated_Manual_Mode_Integration''
              WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' END AS dialType
        ,dial.tBusy
        ,dial.answerbit
        ,dial.canceledNoAgents
        ,ISNULL(dial.cal_id,0) AS cal_id
        ,dial.disconnectCause
        ,co.cal_key
        ,co.file_moved
        ,dial.tipoLlamada_id
        ,tco.[Description] AS CallDisposition
        ,tsco.califSubDesc
        ,CASE WHEN dial.disconnectCause <> '''' THEN SUBSTRING(dial.disconnectCause, 21, 3) ELSE '''' END AS codeSip
        ,CASE
            WHEN @country<>1 THEN ''''
            WHEN dial.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo''
            WHEN dial.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone''
            ELSE ''systemTranslated_Indefinite''
         END AS TipoTel
        ,ISNULL(regp.tPreview,0) AS tpreview
        ,ISNULL(co.User_id,0) AS UserID
        ,ISNULL(co.virtualAgentId,0) AS virtualAgentId
        ,dial.ani
        ,ISNULL(CapturedData,'''') AS CapturedData
        ,CASE 
            WHEN co.statusCall_Id = 20 THEN ''Buzón de voz'' 
            ELSE ISNULL(tc_ia.Name_cal,''N/A'') 
         END AS CallDisposition_IA
    FROM ccoLogDials dial (NOLOCK)
    LEFT JOIN ccoCallsOut co (NOLOCK) ON dial.cal_id = co.cal_id
    LEFT JOIN ccTipoCalifOUT tco WITH (NOLOCK) ON tco.calif_id = co.calif_id
    LEFT JOIN cctipoCalif_IA tc_ia WITH (NOLOCK) ON tc_ia.calif_id = co.calif_id
    LEFT JOIN ccTipoCalifSubOUT tsco WITH (NOLOCK) ON tsco.califSub_id = co.califSub_id
    LEFT JOIN RegProcessPreviewRecord regp WITH (NOLOCK)
        ON regp.callout_id = co.callout_id AND regp.callId = co.cal_id
    LEFT JOIN ccTipoResultadoDial tr (NOLOCK) ON dial.tipoResDial_id = tr.tipoResDial_id
    LEFT JOIN ccoCallsOutDispositionIA codia (NOLOCK) ON codia.call_id = dial.cal_id
    WHERE dial.fecha >= @from
      AND dial.fecha < @to

    UNION

    SELECT
         0                              AS logDial_id
        ,reg.callout_id                 AS callout_id
        ,reg.camId                      AS cam_id
        ,CONVERT(SMALLINT, reg.process) AS tipoResDial_id
        ,ISNULL(cctyp.translatedDesc,'''') AS resultDialDesc
        ,ISNULL(ccoa.cal_telefono,'''')   AS cal_telefono
        ,0                              AS Puerto
        ,reg.reg_date                   AS fecha
        ,0                              AS tDialing
        ,''systemTranslated_Preview''     AS dialType
        ,0                              AS tBusy
        ,CONVERT(BIT, 0)                AS answerbit
        ,CONVERT(BIT, 0)                AS canceledNoAgents
        ,0                              AS cal_id
        ,''''                             AS disconnectCause
        ,NULL                           AS cal_key
        ,CONVERT(TINYINT, 0)            AS file_moved
        ,NULL                           AS tipoLlamada_id
        ,''''                             AS CallDisposition
        ,''''                             AS califSubDesc
        ,''''                             AS codeSip
        ,''''                             AS TipoTel
        ,reg.tPreview                   AS tpreview
        ,reg.userId                     AS UserID
        ,ISNULL(ccoa.virtualAgentId,0) AS virtualAgentId
        ,''''                             AS ani
        ,''''                             AS CapturedData
        ,''N/A''                          AS CallDisposition_IA
    FROM RegProcessPreviewRecord reg (NOLOCK)
    LEFT JOIN ccoCallsOut ccoa (NOLOCK)
        ON reg.callout_id = ccoa.callout_id
    LEFT JOIN ccTypeProcessPreview cctyp (NOLOCK)
        ON cctyp.typeProcess_id = reg.process
    WHERE reg.reg_date >= @from
      AND reg.reg_date < @to
      AND reg.process NOT IN (5,7,13,14)

    CREATE NONCLUSTERED INDEX IX_#dials_logDial_id
    ON #dials(logDial_id)

    CREATE NONCLUSTERED INDEX IX_#dials_callout_id
    ON #dials(callout_id)

    SELECT DISTINCT
         CAST(codeSip AS INT) AS codeSip
        ,disconnectCause
    INTO #codeSip
    FROM #dials
    WHERE codeSip <> ''''
      AND ISNUMERIC(codeSip) = 1

    SELECT
         A.codeSip
        ,A.disconnectCause
        ,B.[description]
    INTO #relationCodeSip
    FROM #codeSip A
    INNER JOIN DC_Extra B ON A.codeSip = B.id


    INSERT INTO RepOutDialDetail(
        [date],
        [calId],
        [callKey],
        [telephone],
        [dialResultId],
        [dialResult],
        [dialog],
        [campaignId],
        [campaign],
        [ModelName],
        [timeMessage],
        [year],
        [month],
        [day],
        [hour],
        [minutes],
        [listName],
        [billed],
        [data1],
        [data2],
        [data3],
        [data4],
        [data5],
        [fileMoved],
        [disconnectCause],
        [DCCustomer],
        [dialType],
        [TipoTel],
        [CallDisposition],
        [CallSubDisposition],
        [data6],
        [data7],
        [data8],
        [data9],
        [data10],
        [data11],
        [data12],
        [data13],
        [data14],
        [data15],
        [preview_Time],
        [login],
        [areaId],
        [area],
        [ani],
        [CapturedData]
    )
        SELECT 
             fecha AS [date]
             ,cal_id
            ,CASE 
                WHEN dials.cal_key IS NULL AND cs.cal_key IS NULL THEN '''' 
                WHEN dials.cal_key IS NOT NULL THEN dials.cal_key 
                ELSE cs.cal_key 
             END AS cal_key
            ,ISNULL(dials.Telefono,'''') AS telephone
            ,dials.tipoResDial_id        AS tiporesdialId
            ,CASE 
                WHEN dials.tipoResDial_id = 14 THEN 
                    CASE 
                        WHEN camps.campType = 6 THEN ''systemTranslated_CancelledByEngaged'' 
                        ELSE ''systemTranslated_CancelledBySystem'' 
                    END
                ELSE ISNULL(dials.resultDialDesc, '''') 
             END AS dialResult
            ,tDialing
            ,ISNULL(dials.cam_id,'''')   AS campaignId
            ,ISNULL(RTRIM(LTRIM(camps.cam_descripcion)),''systemTranslated_NoCampaign'') AS campaign
            ,ISNULL(va.nameAgent,''NA'') AS ModelName
            ,dials.tbusy                 AS timeMessage
            ,DATEPART(yyyy, fecha)       AS year 
            ,DATEPART(mm,   fecha)       AS month  
            ,DATEPART(dd,   fecha)       AS day    
            ,DATEPART(hh,   fecha)       AS hour   
            ,DATEPART(mi,   fecha)       AS minutes
            ,ISNULL(rl.[name], '''')     AS listName
            ,CASE 
                WHEN answerbit = 1 THEN ''systemTranslated_Charged'' 
                ELSE ''systemTranslated_NotCharged'' 
             END AS billed
            ,ISNULL(ldd.Data1, ISNULL(cs.Dato1, '''')) AS data1
            ,ISNULL(ldd.Data2, ISNULL(cs.Dato2, '''')) AS data2
            ,ISNULL(ldd.Data3, ISNULL(cs.Dato3, '''')) AS data3
            ,ISNULL(ldd.Data4, ISNULL(cs.Dato4, '''')) AS data4
            ,ISNULL(ldd.Data5, ISNULL(cs.Dato5, '''')) AS data5
            ,CASE 
                WHEN dials.file_moved = 1 THEN ''systemTranslated_Remoto'' 
                WHEN dials.file_moved = 2 THEN ''systemTranslated_noRecordingCamp''
                ELSE ''systemTranslated_Local'' 
             END AS fileMoved
            ,dials.disconnectCause
            ,COALESCE(dat.[description], tr.descTranslate, ''N/A'') AS DCCustomer
            ,dials.dialType
            ,TipoTel
            ,CASE
                WHEN camps.campType = 9 THEN dials.CallDisposition_IA
                ELSE ISNULL(CallDisposition, ''N/A'')
            END AS CallDisposition
            ,ISNULL(califSubDesc, ''N/A'')       AS CallSubDisposition
            ,ISNULL(csP.Dato6,  '''')            AS data6
            ,ISNULL(csP.Dato7,  '''')            AS data7
            ,ISNULL(csP.Dato8,  '''')            AS data8
            ,ISNULL(csP.Dato9,  '''')            AS data9
            ,ISNULL(csP.Dato10, '''')            AS data10
            ,ISNULL(csP.Dato11, '''')            AS data11
            ,ISNULL(csP.Dato12, '''')            AS data12
            ,ISNULL(csP.Dato13, '''')            AS data13
            ,ISNULL(csP.Dato14, '''')            AS data14
            ,ISNULL(csP.Dato15, '''')            AS data15
            ,dials.tpreview                     AS preview_Time
            ,CASE 
                WHEN camps.CampType = 9 THEN ''N/A'' 
                ELSE ISNULL(us.[Login],''N/A'') 
             END AS [Login]
            ,ISNULL(ar.IDArea, 1)               AS areaId   
            ,ISNULL(ar.AreaName,''Default'')    AS area
            ,dials.ani                        AS ani
            ,CASE 
                WHEN dials.CapturedData = '''' THEN ''N/A''
                ELSE dials.CapturedData
             END AS CapturedData
    FROM #dials AS dials
    LEFT JOIN ccoCallsOutSource cs  (NOLOCK) ON dials.callout_id = cs.callout_id
    LEFT JOIN ccoLogDialsData   ldd (NOLOCK) ON ldd.logDial_id   = dials.logDial_id
    LEFT JOIN ccTipoResultadoDial tr (NOLOCK) ON dials.tipoResDial_id = tr.tipoResDial_id
    LEFT JOIN ccCamps           camps (NOLOCK) ON camps.cam_id    = dials.cam_id
    LEFT JOIN ccVirtualAgent va (NOLOCK) ON va.idAgent = dials.virtualAgentId
    LEFT JOIN ccRIARegistryLists rl (NOLOCK) ON cs.list_id        = rl.list_id
    LEFT JOIN #relationCodeSip  dat           ON dat.disconnectCause = dials.disconnectCause
    LEFT JOIN ccoCallsPreviewData csP         ON (dials.cal_Key = csP.cal_Key AND dials.cam_id = csP.cam_id)
    LEFT JOIN ccUsers           us  (NOLOCK)  ON us.User_id       = dials.UserID
    LEFT JOIN ccRIACat_Areas    ar  (NOLOCK)  ON ar.IDArea        = camps.IDArea

    IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL DROP TABLE #dials
    IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL DROP TABLE #codeSip
    IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL DROP TABLE #relationCodeSip
END
'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepOutSMSAnswDetailByCamp] '
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutSMSAnswDetailByCamp] 
@action as tinyint,
@from as datetime = NULL,
@to as datetime = NULL
AS

IF @from IS NULL
    SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
    SELECT @to = getdate()

IF @action = 1
BEGIN
    --Borrar lo que esta para no repetir
    DELETE
    FROM RepOutSMSAnswDetailByCamp WITH (ROWLOCK)
    WHERE date >= @from AND date < @to

    INSERT INTO RepOutSMSAnswDetailByCamp
    SELECT smsDate date, cam.cam_id camId, cam_descripcion campaignName,isnull(smslog.Message,src.message) message, phone senderNumber, cam.cam_id campaignId
    FROM smsccoLogDial smslog (nolock)
        LEFT JOIN cccamps cam on cam.cam_id=smslog.cam_id
        LEFT JOIN smsoutSourceMessage src on src.smsout_id=smslog.smsout_id
    WHERE smsDate >= @from AND smsDate < @to
END
'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepOutSMSSentMessagesDetail] '
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutSMSSentMessagesDetail] 
@action as tinyint,
@from as datetime = NULL,
@to as datetime = NULL
AS

IF @from IS NULL
    SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
    SELECT @to = getdate()

IF @action = 1
BEGIN
    --Borrar lo que esta para no repetir
    DELETE
    FROM RepOutSMSSentMessagesDetail WITH (ROWLOCK)
    WHERE date >= @from AND date < @to

    INSERT INTO RepOutSMSSentMessagesDetail (recordId,campaign,recipientNumber,date,messageResult,ncost,messageId,campaignId,SystemApiId)
    SELECT smsout_id, cam_descripcion, phone, smsDate,res.translatedDesc, bill, logId, smslog.cam_id campaignId,smslog.SystemApiId
    FROM smsccoLogDial smslog (nolock)
        LEFT JOIN cccamps cam on cam.cam_id=smslog.cam_id
        LEFT JOIN ccSMSResult res on res.resultId=smslog.statusSystemsId 
    WHERE smsDate >= @from AND smsDate < @to
    ORDER BY smsDate
END'
    exec (@sql)

   

    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepInNotTransferred]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepInNotTransferred]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
    --1 as wgId
    --Borrar lo que esta para no repetir
    delete from RepInNotTransferred with(rowlock)
    where date >= @from AND date < @to

    ;with ccWgByAcdViewDistinct as(

        select distinct Inbound_id,IDArea,IDWG,descripcion from ccWgByAcdView 
    )

    insert into RepInNotTransferred
    select a.cal_Inicio as [date], a.Inbound_id, 
    b.descripcion as acd, a.statusCall_id, isnull(d.descripcion,'''') as statusCall,isnull(d.descripcion,'''')  + ''_Count'' as statusCallCount,1 as [count],  b.IDArea, 
    isnull(Area.AreaName, '''') as area, c.IDWG as wgId, isnull(c.WGName,''systemTranslated_WorkGroup'') as wg
    ,datepart(yyyy,cal_inicio) as [year]
    ,datepart(mm,cal_inicio) as [mount]
    ,datepart(dd,cal_inicio) as [day]
    ,datepart(hh,cal_inicio) as [hour]
    ,datepart(mi,cal_inicio) as [minutes]
    ,a.cal_id as cal_id,isnull(a.cal_Ani,'''') as phone_in
    from cccallsin a        
    inner join ccWgByAcdViewDistinct b on a.Inbound_id=b.Inbound_id
    left join ccRIACat_WorkGroup c on c.IDWG=b.IDWG
    left join ccstatusllamada d on a.statusCall_id = d.statusCall_id
    left join ccRIACat_Areas Area on Area.IDArea=b.IDArea
    where cal_inicio >= @from AND cal_inicio < @to and 
    a.statuscall_id in (1,2,3,4,6,7,8)
    and  b.IDArea is not null
end'
    exec (@sql)

    

    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepOutSMSSentMessagesDetail]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutSMSSentMessagesDetail] 
@action as tinyint,
@from as datetime = NULL,
@to as datetime = NULL
AS

IF @from IS NULL
    SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
    SELECT @to = getdate()

IF @action = 1
BEGIN
    --Borrar lo que esta para no repetir
    DELETE
    FROM RepOutSMSSentMessagesDetail WITH (ROWLOCK)
    WHERE date >= @from AND date < @to

    INSERT INTO RepOutSMSSentMessagesDetail (recordId,campaign,recipientNumber,date,messageResult,ncost,messageId,campaignId,SystemApiId)
    SELECT smsout_id, cam_descripcion, phone, smsDate,res.translatedDesc, bill, logId, smslog.cam_id campaignId,smslog.SystemApiId
    FROM smsccoLogDial smslog (nolock)
        LEFT JOIN cccamps cam on cam.cam_id=smslog.cam_id
        LEFT JOIN ccSMSResult res on res.resultId=smslog.statusSystemsId 
    WHERE smsDate >= @from AND smsDate < @to
    ORDER BY smsDate
END
'
    exec (@sql)

    

    --- BEGIN Carlos Muñoz ---
    SET @process = 'KM52000 Calculo de información de columna de posiciones en reporte de llamadas contestadas por campaña.' 
    
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM GroupByReports WHERE id = 4030)
    BEGIN
        INSERT INTO GroupByReports VALUES (4030, ''max([areaId]):areaId|max([area]):area|workgroupId|max([workgroup]):workgroup|campaignId|max([campaign]):campaign|userId|max([user]):user|sum([ntotal]):ntotal|sum([nxfer]):nxfer|sum([nnoagent]):nnoagent|sum([nanswer]):nanswer|sum([nnoanswer]):nnoanswer|sum([nlost]):nlost|sum([nabndxfer]):nabndxfer|sum([nabndring]):nabndring|sum([nabnddialog]):nabnddialog|sum([postot]):postot|sum([postime]):postime|sum([nhangup]):nhangup|sum([tatencion]):tatencion'', ''campaignId|userId|workgroupId'')
    END
    ELSE
    BEGIN
        UPDATE GroupByReports set columns = ''max([areaId]):areaId|max([area]):area|workgroupId|max([workgroup]):workgroup|campaignId|max([campaign]):campaign|userId|max([user]):user|sum([ntotal]):ntotal|sum([nxfer]):nxfer|sum([nnoagent]):nnoagent|sum([nanswer]):nanswer|sum([nnoanswer]):nnoanswer|sum([nlost]):nlost|sum([nabndxfer]):nabndxfer|sum([nabndring]):nabndring|sum([nabnddialog]):nabnddialog|sum([postot]):postot|sum([postime]):postime|sum([nhangup]):nhangup|sum([tatencion]):tatencion'' WHERE id = 4030;
    END'
    
    EXEC(@sql)
    --- END Carlos Muñoz ---

	--- END Services Pack 1-8 ----


    SET @process = 'INSERT INTO ReportsFilters calltypes 4020'
    SET @sql = 'IF NOT EXISTS (
    SELECT TOP 1 1 
    FROM ReportsFilters 
    WHERE ReportName = ''Answered Calls Detail'' 
      AND FilterType = ''calltypes'' 
      AND FilterValue = 4020
)
BEGIN
    INSERT INTO ReportsFilters (ReportName, FilterType, FilterValue)
    VALUES (''Answered Calls Detail'', ''calltypes'', 4020)
END'
    exec (@sql)

    

    SET @process = ''
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail] 
        @action AS TINYINT,
        @from  AS DATETIME = NULL,
        @to    AS DATETIME = NULL
    AS
        IF @from IS NULL
            SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

        IF @to IS NULL
            SELECT @to = GETDATE();
            print(@from)
            print(@to)
        DECLARE @IVA INT, @IVAstring VARCHAR(3);
        DECLARE @country AS TINYINT;

        SELECT @IVA = CONVERT(INT, ISNULL(valor, 0))
        FROM ccsettings
        WHERE setting_id = 25;

        SELECT @IVAstring = CONVERT(VARCHAR(5), @IVA) + ''%'';

        SELECT @country = CONVERT(TINYINT, ISNULL(valor, 1))
        FROM ccsettings
        WHERE setting_id = 104;

        IF @country IS NULL
            SET @country = 1;

        IF @action = 1
        BEGIN
            DELETE FROM RepOutCallsDetail WITH (ROWLOCK)
            WHERE DATE >= @from 
              AND DATE <  @to;

            INSERT INTO dbo.RepOutCallsDetail
            (
                [date],
                [callKey],
                [telephone],
                [transfer],
                [dialog],
                [nque],
                [wrapup],
                [CallDisposition],
                [extension],
                [userId],
                [login],
                [username],
                [campaignId],
                [campaign],
                [duration],
                [ncost],
                [iva],
                [total],
                [ByCarrier],
                [Calltypes],
                [dialType],
                [whoHangUp],
                [subDisposition],
                [dialResult],
                [calId],
                [year],
                [month],
                [day],
                [hour],
                [minutes],
                [trunk],
                [data1],
                [data2],
                [data3],
                [data4],
                [data5],
                [MessageTime],
                [grabId],
                [areaId],
                [area],
        originNumber,
        callbackDate,
        queueTimes,
        ringingTime,
        callStatusId
            )
            SELECT 
                Call.cal_inicio AS [date],
                Call.cal_key AS [callKey],
                Call.cal_telefono AS [telephone],
                Call.cal_txfer + Call.cal_tring AS [transfer],
                Call.cal_tdialog AS [dialog],
                ISNULL(Call.cal_tMoh, 0) AS [nque],
                Call.cal_tnotas AS [wrapup],
                ISNULL(Tipo.[description], '''') AS [CallDisposition],
                Call.cal_extension AS [extension],
                ISNULL(Usr.user_id, 0) AS [userId],
                ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [login],
                ISNULL(CONVERT(VARCHAR(255), Usr.[LOGIN]), ''systemTranslated_NoUserName'') AS [username],
                camps.cam_id AS [campaignId],
                ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
                (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60) AS [duration],
                CONVERT(DECIMAL(10, 2), dbo.fnGetCstoTarifa(
                    Call.tipoLlamada_id, 
                    Call.provedor_id, 
                    (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),
                    @country
                )) AS [ncost],
                @IVAstring AS iva,
                CONVERT(DECIMAL(10, 2), dbo.fnGetCstoTarifa(
                    Call.tipoLlamada_id, 
                    Call.provedor_id, 
                    (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),
                    @country
                ) * (1 + (@IVA / 100.00))) AS total,
                CASE 
                    WHEN prov.descrip IS NOT NULL THEN prov.descrip
                    ELSE ''systemTranslated_NoCarrier'' 
                END AS [ByCarrier],
                CASE 
                    WHEN @country <> 1 THEN ''''
                    WHEN ld.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo'' 
                    WHEN ld.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone'' 
                    ELSE ''systemTranslated_Indefinite'' 
                END AS [Calltypes],
                CASE 
                    WHEN ld.TipoDialingMode = ''100000000''  THEN ''systemTranslated_Preview'' 
                    WHEN SUBSTRING(ld.TipoDialingMode, 2, 1) = ''1'' AND Call.cal_manual = 0 THEN ''systemTranslated_Assisted''
                    WHEN ld.TipoDialingMode IN (''00001000'',''00010000'', ''000010000'') THEN ''systemTranslated_Callback'' 
                    WHEN RIGHT(ld.TipoDialingMode, 3) = ''100'' THEN ''systemTranslated_Auto'' 
                    WHEN RIGHT(ld.TipoDialingMode, 2) IN (''10'', ''01'') AND ISNULL(ld.manualCRM,0) = 1 THEN ''systemTranslated_Manual_Mode_Integration''
                    WHEN RIGHT(ld.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' 
                    WHEN ld.TipoDialingMode = ''000000000'' THEN ''systemTranslated_Auto''
                    ELSE ''''
                END AS [dialType], 
                CASE 
                    WHEN Call.cal_whoHung = 0 THEN ''systemTranslated_Client'' 
                    WHEN Call.cal_whoHung = 1 THEN ''systemTranslated_Agent'' 
                    ELSE ''systemTranslated_AgentSurvey'' 
                END AS [whoHangUp], 
                CASE 
                    WHEN Call.califsub_id = 0 THEN ''systemTranslated_NoSubDisposition'' 
                    ELSE ISNULL(sub.califSubDesc, '''') 
                END AS [subDisposition],
                ISNULL(sta.descTranslated,'''') AS  [dialResult], 
                Call.cal_id AS [calId],
                DATEPART(yyyy, Call.cal_inicio) AS [year],
                DATEPART(mm,   Call.cal_inicio) AS [month],
                DATEPART(dd,   Call.cal_inicio) AS [day],
                DATEPART(hh,   Call.cal_inicio) AS [hour],
                DATEPART(mi,   Call.cal_inicio) AS [minutes],
                Call.cal_puerto,
                ISNULL(cod.Data1, ISNULL(cs.Dato1, '''')) AS [data1],
                ISNULL(cod.Data2, ISNULL(cs.Dato2, '''')) AS [data2],
                ISNULL(cod.Data3, ISNULL(cs.Dato3, '''')) AS [data3],
                ISNULL(cod.Data4, ISNULL(cs.Dato4, '''')) AS [data4],
                ISNULL(cod.Data5, ISNULL(cs.Dato5, '''')) AS [data5],
                ISNULL(Call.cal_tMsg, 0) AS [MessageTime],
                ISNULL(rc.grab_id, 0) AS grabId,
                camps.IDArea AS [areaId],
                ar.AreaName AS [area],
        ld.ani as originNumber,
        call.cal_fcallback as callbackDate,
        cal_que as queueTimes,
        Call.cal_txfer + call.cal_tring 
        + CASE WHEN RIGHT(ld.TipoDialingMode, 2) IN (''10'', ''01'') THEN ld.tDialing ELSE 0 END
        as ringingTime,
        Call.statusCall_id as callStatusId
            FROM ccoCallsOut Call (NOLOCK)
            LEFT JOIN ccoLogDials      ld   (NOLOCK) ON Call.cal_id    = ld.cal_id
            LEFT JOIN ccTipoCalifOUT   Tipo (NOLOCK) ON Call.calif_id  = Tipo.calif_id
            LEFT JOIN ccUserView       Usr  (NOLOCK) ON Usr.[user_id]  = Call.[user_id]
            LEFT JOIN ccCamps          camps(NOLOCK) ON camps.[cam_id] = Call.[cam_id]
            LEFT JOIN ccStatusLlamada  sta  (NOLOCK) ON Call.statuscall_id = sta.statuscall_id
            LEFT JOIN cstoProvedor     prov (NOLOCK) ON prov.[provedor_id] = Call.[provedor_id]
            LEFT JOIN cstoTipoLlamada  tl   (NOLOCK) ON tl.[tipoLlamada_id] = ld.[tipoLlamada_id] 
                                                    AND tl.Country_id       = @country
            LEFT JOIN ccTipoCalifSubOut sub (NOLOCK) ON Call.califsub_id = sub.califsub_id
            LEFT JOIN ccoDialers       di   (NOLOCK) ON di.dialer_id = Call.cal_puerto 
                                                    AND Call.provedor_id = di.provedor_id
            LEFT JOIN ccoCallsOutSource cs  (NOLOCK) ON Call.callout_id = cs.callout_id
            LEFT JOIN ccoCallsOutData  cod  (NOLOCK) ON cod.cal_id = Call.cal_id
            LEFT JOIN ccCallCost_RIA   cc   (NOLOCK) ON cc.country_id = tl.country_id 
                                                    AND cc.tipoLlamada_id = tl.tipoLlamada_id
            LEFT JOIN Ria_grabacion    rc   (NOLOCK) ON rc.cal_id = Call.cal_id 
                                                    AND rc.tipo_llamada = 2
            LEFT JOIN dbo.ccRIACat_Areas AS ar (NOLOCK) ON ar.IDArea = camps.IDArea
            WHERE Call.cal_inicio >= @from 
              AND Call.cal_inicio <  @to 
              AND Call.cal_manual IN (0, 2) 
              AND ld.TipoDialingMode IS NOT NULL
            ORDER BY DATE;
        END

'
    exec (@sql)

    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
  
    	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

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
