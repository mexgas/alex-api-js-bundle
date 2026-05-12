use CCReportsRIA
DECLARE @sql NVARCHAR(MAX)
DECLARE @process VARCHAR(MAX)

SET @process = 'Configuración de Menú (2150) - Agentes Virtuales';

SET @sql = '
IF NOT EXISTS (SELECT 1 FROM ccMenus WHERE menu_id = 2150)
BEGIN
    INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release) 
    VALUES (2150, ''Agentes virtuales|Virtual Agents'', 2000, ''B'', 2, 3, '''', ''505b0c30ff896f2db7e7b7946607de282293a6ed731cb58b9192c6d4a764bb05'');
    PRINT ''Menú 2150 insertado en ccMenus.'';
END

IF NOT EXISTS (SELECT 1 FROM ccMenuUser WHERE id_User = 1 AND id_Menu = 2150)
BEGIN
    INSERT INTO ccMenuUser (id_User, id_Menu, type) 
    VALUES (1, 2150, 3);
    PRINT ''Permiso asignado al usuario 1 en ccMenuUser.'';
END
'
EXEC(@sql);

------------------------------------ BEGIN Nueva Tabla RepVirtualAgent ------------------------------------
SET @process = 'Creación segura de tabla RepVirtualAgent e índices';

SET @sql = '
IF OBJECT_ID(''[dbo].[RepVirtualAgent]'', ''U'') IS NULL
BEGIN
    CREATE TABLE [dbo].[RepVirtualAgent] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [idAgent] INT NOT NULL,
        [Date] DATETIME NOT NULL,                   
        [ModelName] VARCHAR(255) NOT NULL,            
        [CampaignName] VARCHAR(50) NOT NULL,         
        [CallsHandled] INT NOT NULL,                 
        [CallsTransferred] INT NOT NULL,             
        [AverageHandleTime] INT NOT NULL,     
        [activeTime] INT NOT NULL             
    );
END
ELSE
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''idAgent'' AND Object_ID = Object_ID(N''dbo.RepVirtualAgent''))
    BEGIN
        ALTER TABLE dbo.RepVirtualAgent ADD idAgent INT NOT NULL DEFAULT 0;
    END
END

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_RepVirtualAgent_ReportDate_ModelName'' AND object_id = OBJECT_ID(''[dbo].[RepVirtualAgent]''))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RepVirtualAgent_ReportDate_ModelName] ON [dbo].[RepVirtualAgent] ([Date], [ModelName]);
END
'
EXEC(@sql);

------------------------------------ BEGIN Ajustes Tablas y Vistas ------------------------------------
SET @process = 'Agregar columnas a tablas Detalle y actualizar vistas';

SET @sql = '
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''ModelName'' AND Object_ID = Object_ID(N''dbo.RepInCallsDetail''))
    ALTER TABLE dbo.RepInCallsDetail ADD ModelName VARCHAR(MAX) DEFAULT ''N/A'';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''CapturedData'' AND Object_ID = Object_ID(N''dbo.RepInCallsDetail''))
    ALTER TABLE dbo.RepInCallsDetail ADD CapturedData VARCHAR(MAX) DEFAULT '''';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''ModelName'' AND Object_ID = Object_ID(N''dbo.RepOutDialDetail''))
    ALTER TABLE dbo.RepOutDialDetail ADD ModelName VARCHAR(MAX) DEFAULT ''N/A'';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''ani'' AND Object_ID = Object_ID(N''dbo.RepOutDialDetail''))
    ALTER TABLE dbo.RepOutDialDetail ADD ani VARCHAR(MAX) DEFAULT ''N/A'';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = N''CapturedData'' AND Object_ID = Object_ID(N''dbo.RepOutDialDetail''))
    ALTER TABLE dbo.RepOutDialDetail ADD CapturedData VARCHAR(MAX) DEFAULT '''';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = ''calId'' AND Object_ID = Object_ID(''dbo.RepOutDialDetail''))
    ALTER TABLE dbo.RepOutDialDetail ADD calId INT DEFAULT 0;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE Name = ''dialog'' AND Object_ID = Object_ID(''dbo.RepOutDialDetail''))
    ALTER TABLE dbo.RepOutDialDetail ADD dialog INT DEFAULT 0;
'
EXEC(@sql);

SET @sql = '
ALTER VIEW [dbo].[RepViewInCallsDetail] AS  
SELECT [date] AS receptionDate,
    cal_final,
    inboundId AS inboundCamp,
    ACDGroup AS campaign,
    ModelName,
    callStatusId,
    callStatus,
    dispositionId,
    disposition AS disposition_InCallsDetail,
    subDispositionId,
    subDisposition AS sub_Disposition,
    dnisId,
    dnis AS didNumber,
    userId,
    [user],
    callKey AS call_Key,
    [source],
    [destinationNumber],
    callbackDate,
    [cal_tWait] as queueTime,
    ANI AS aniNumber,
    queueTime AS queue_Time,
    xferTime,
    ringingTime,
    dialogTime AS dialog_Time,
    mohTime AS hold_Time,
    twrapup,
    AverageHandleTime AS handleTime,
    extension,
    agentName,
    whoHangUp AS endedBy,
    recibeCallBy
    [year],
    [month],
    [day],
    [hour],
    [minutes],
    provedorId,
    provider AS provider_InCallsDetail,
    trunk AS trunk_InCallsDetail,
    fileMoved,
    [CapturedData],
    Dato1,
    Dato2,
    Dato3,
    Dato4,
    Dato5,
    callid AS call_Id,
    grabId,
    nameDNI,
    numDNI,
    collectCall,
    timeTotalInCallSec,
    timeTotalInCallMin,
    statusCallByIVR,
    IVR_ID,
    callHung,
    areaId,
    area
FROM RepInCallsDetail WITH (NOLOCK);
'
EXEC(@sql);

SET @sql = '
ALTER VIEW [dbo].[RepOutDialDetailView] AS 
SELECT [date],
    [calId],
	[callKey],
	[telephone],
	[dialResultId],
	[dialResult],
    [dialog],
	[campaignId],
	[campaign],
	ModelName,
	[timeMessage],
	[year],
	[month],
	[day],
	[hour],
	[minutes],
	[listName],
	[billed],
	[CapturedData],
	[data1] AS [Dato1],
	[data2] AS [Dato2],
	[data3] AS [Dato3],
	[data4] AS [Dato4],
	[data5] AS [Dato5],
	[fileMoved],
	[DCCustomer],
	[disconnectCause],
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
	[login] AS [user],
	[areaId],
	[area],
	[ani]
FROM RepOutDialDetail WITH (NOLOCK);
'
EXEC(@sql);

------------------------------------ BEGIN Configuración Filtros ------------------------------------
SET @process = 'Configuración de Filtros para Reporte Virtual Agent';

SET @sql = '
IF NOT EXISTS (SELECT 1 FROM Filters WHERE id = 37)
    INSERT INTO Filters (id, name, type, xmlParentNode, xmlChildNode) VALUES (37, ''CampaignName'', 37, ''CampaignName'', ''CampaignName'');

IF NOT EXISTS (SELECT 1 FROM Filters WHERE id = 38)
    INSERT INTO Filters (id, name, type, xmlParentNode, xmlChildNode) VALUES (38, ''ModelName'', 38, ''ModelName'', ''ModelName'');

IF NOT EXISTS (SELECT 1 FROM ReportsFilters WHERE id = 2150 AND filterName = ''CampaignName'')
    INSERT INTO ReportsFilters (reportName, filterName, id) VALUES (''Virtual Agent'', ''CampaignName'', 2150);

IF NOT EXISTS (SELECT 1 FROM ReportsFilters WHERE id = 2150 AND filterName = ''ModelName'')
    INSERT INTO ReportsFilters (reportName, filterName, id) VALUES (''Virtual Agent'', ''ModelName'', 2150);

IF NOT EXISTS (SELECT 1 FROM ReportsFilters WHERE filterName = ''ModelName'' AND id = 3010)
BEGIN
	Insert into ReportsFilters VALUES(''Virtual Agent'',''ModelName'',3010)
END
IF NOT EXISTS (SELECT 1 FROM ReportsFilters WHERE filterName = ''ModelName'' AND id = 4010)
BEGIN
  Insert into ReportsFilters VALUES(''Virtual Agent'',''ModelName'',4010)
END
'
EXEC(@sql);

------------------------------------ BEGIN Agentes Virtuales (SP) ------------------------------------
SET @process = 'SP ccspRepVirtualAgent';

SET @sql = '
IF OBJECT_ID(''[dbo].[ccspRepVirtualAgent]'') IS NULL
BEGIN
    EXEC(''CREATE PROCEDURE [dbo].[ccspRepVirtualAgent] AS RETURN 0'')
END
'
EXEC(@sql);

SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepVirtualAgent]
    @action tinyint,
    @from   DATETIME,
    @to     DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    IF (@action = 1)
    BEGIN
        -- 1. LIMPIEZA PREVIA
        DELETE [dbo].[RepVirtualAgent]
        WHERE [date] >= @from
          AND [date] <  @to;

        ;WITH

        CTE_RawCalls AS (
            SELECT
                ci.User_id                                          AS idAgent,
                ci.Inbound_id,
                ci.cal_id,
                CAST(ci.cal_tDialog AS INT)                         AS tDialogSec,
                CAST(ci.cal_Inicio  AS DATE)                        AS CallDate,
                ci.cal_Inicio                                       AS StartTime,
                DATEADD(SECOND, CAST(ci.cal_tDialog AS INT),
                        ci.cal_Inicio)                              AS EndTime,
                CASE WHEN lt.cal_id IS NOT NULL THEN 1 ELSE 0 END   AS IsTransferred

            FROM ccCallsIn ci WITH (NOLOCK)

            LEFT JOIN (
                SELECT DISTINCT cal_id
                FROM ccLogTransfers
                WHERE tipo = 1
            ) lt ON ci.cal_id = lt.cal_id

            WHERE ci.cal_Inicio >= @from
              AND ci.cal_Inicio <  @to
              AND ci.cal_tDialog > 0
        ),

        CTE_VolumeMetrics AS (
            SELECT
                idAgent,
                Inbound_id,
                CallDate,
                COUNT(cal_id)       AS CallsHandled,
                SUM(IsTransferred)  AS CallsTransferred,
                SUM(tDialogSec)     AS TotalDialogTime
            FROM CTE_RawCalls
            GROUP BY idAgent, Inbound_id, CallDate
        ),

        CTE_OrderedCalls AS (
            SELECT
                idAgent,
                Inbound_id,
                CallDate,
                StartTime,
                EndTime,
                LAG(EndTime) OVER (
                    PARTITION BY idAgent, Inbound_id, CallDate
                    ORDER BY StartTime
                ) AS PrevEndTime
            FROM CTE_RawCalls
        ),

        CTE_IslandFlags AS (
            SELECT
                idAgent,
                Inbound_id,
                CallDate,
                StartTime,
                EndTime,
                CASE
                    WHEN PrevEndTime IS NULL OR StartTime > PrevEndTime THEN 1
                    ELSE 0
                END AS IsNewIsland
            FROM CTE_OrderedCalls
        ),

        CTE_Islands AS (
            SELECT
                idAgent,
                Inbound_id,
                CallDate,
                StartTime,
                EndTime,
                SUM(IsNewIsland) OVER (
                    PARTITION BY idAgent, Inbound_id, CallDate
                    ORDER BY StartTime
                    ROWS UNBOUNDED PRECEDING
                ) AS IslandID
            FROM CTE_IslandFlags
        ),

        CTE_UptimeByIsland AS (
            SELECT
                idAgent,
                Inbound_id,
                CallDate,
                IslandID,
                DATEDIFF(SECOND, MIN(StartTime), MAX(EndTime)) AS IslandSeconds
            FROM CTE_Islands
            GROUP BY idAgent, Inbound_id, CallDate, IslandID
        ),

        CTE_TotalUptime AS (
            SELECT
                idAgent,
                Inbound_id,
                CallDate,
                SUM(IslandSeconds) AS FinalUptime
            FROM CTE_UptimeByIsland
            GROUP BY idAgent, Inbound_id, CallDate
        )

        INSERT INTO [dbo].[RepVirtualAgent] (
            [idAgent],
            [Date],
            [ModelName],
            [CampaignName],
            [CallsHandled],
            [CallsTransferred],
            [AverageHandleTime],
            [activeTime]
        )
        SELECT
            vm.idAgent,
            vm.CallDate,
            va.nameAgent,
            camp.descripcion,
            vm.CallsHandled,
            vm.CallsTransferred,
            vm.TotalDialogTime / vm.CallsHandled,  -- CallsHandled >= 1 por el filtro tDialogSec > 0
            tu.FinalUptime

        FROM CTE_VolumeMetrics vm
        INNER JOIN CTE_TotalUptime tu
            ON  vm.idAgent    = tu.idAgent
            AND vm.Inbound_id = tu.Inbound_id
            AND vm.CallDate   = tu.CallDate
        INNER JOIN ccVirtualAgent va WITH (NOLOCK)
            ON vm.idAgent = va.idAgent
        INNER JOIN ccInbound camp WITH (NOLOCK)
            ON vm.Inbound_id = camp.Inbound_id;

    END
END'
EXEC(@sql);

SET @process = 'Insert ccspRepVirtualAgent in to ReportHighUse';

SET @sql = 'IF NOT EXISTS (SELECT 1 FROM ReportHighUse WHERE nameSp = ''ccspRepVirtualAgent'')
BEGIN
	INSERT INTO ReportHighUse VALUES (''ccspRepVirtualAgent'')
END'
EXEC(@sql);