/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio Chagolla
Date: 2024/09/30
Description: Release 126.20241218.0.0
Database: CCenterRia
Required version: 126.6
IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON
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
SET @version = 127 --**********actualizar a 124 sin fix
SET @versionfix = 0
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end
IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END
IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY

	------------------------------------------- BEGIN Carlos Eduardo Muñoz Carbajal ----------------------------------------
	SET @process = 'Creation of Table for Luis Agent'
	SET @sql = '
		IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = ''ccVirtualAgent'')
		BEGIN
            CREATE TABLE dbo.ccVirtualAgent (
                idAgent INT IDENTITY(1,1) PRIMARY KEY,
                nameAgent VARCHAR(255) NOT NULL,
                statusAgent BIT NOT NULL,
                createDateAgent DATE NOT NULL DEFAULT GETDATE(),
                latestUpdateDateAgent DATE NULL,
                concurrentSessionsLimit INT,
                idCampaign SMALLINT NULL,
                mediaType TINYINT NULL,
                campType TINYINT NULL,
                location VARCHAR(50),
				quantumAgentId VARCHAR(50)
            );
		END'
	EXEC(@sql)

    SET @process = 'Creation of SP for consult, deletion, campaign assignation, and enable or disable virtual agents'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_VirtualAgents'')
			begin
				DROP PROCEDURE ccsp_VirtualAgents;
			end'
    EXEC(@sql)

    SET @sql = '
    CREATE PROCEDURE [dbo].[ccsp_VirtualAgents]
    @action INT,
	@idVirtualAgent INT = 0,
    @nameAgent NVARCHAR(255) = NULL,
    @statusAgent BIT = NULL,
	@campaignId INT = NULL,
	@mediaType INT = NULL, -- CALLS, WHATSAPP, SMS
	@campType INT = NULL, -- 0 IN - 1 OUT
	-- Masivo
	@virtualAgentIds VARCHAR(600) = NULL
    AS
    BEGIN
        IF @action = 1
        BEGIN
            SELECT
                va.idAgent AS idAgent,
                va.NameAgent AS nombre,
                ISNULL(CAST(va.idCampaign AS INT),0) AS idCampaign,
                ISNULL(va.concurrentSessionsLimit, 0) AS concurrentSessionsLimit,
                CAST(va.StatusAgent AS BIT) AS status,
                CAST(va.mediaType AS INT) as SubType,
                ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN ci.descripcion 
                        ELSE co.cam_descripcion
                    END, ''N/A''
                ) AS campName,
                ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN ci.IDArea -- Campaña de entrada
                        ELSE co.IDArea -- Campaña de salida
                    END,
                0) AS IDArea,
                CAST(ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN ig.graphic_id -- Icono para entrada
                        ELSE og.graphic_id -- Icono para salida
                    END, 0
                ) AS int) AS campaignGraph,
                CAST(va.CampType AS int) CampType,
                ISNULL(
                    CASE 
                        WHEN va.CampType = 0 THEN CAST(ci.Status AS BIT) -- Estado de la campaña de entrada
                        ELSE CAST(co.cam_procesando AS BIT) -- Estado de la campaña de salida
                    END, 0
                ) AS IsActiveCampaign, -- Devuelve 1 o 0
                ISNULL(
                    CASE 
                        WHEN (va.CampType = 0 AND ci.chat = 5) THEN wn.Number
                        WHEN (va.CampType = 1 AND co.CampType = 5) THEN wno.Number
                        ELSE ''N/A''
                    END, ''N/A''
                ) AS NumeroAsociado,
                CONVERT(VARCHAR(10), va.createDateAgent, 120) AS FechaCreacion, -- Devuelve como ''YYYY-MM-DD''
                ISNULL(
                    CASE 
                        WHEN va.latestUpdateDateAgent IS NULL OR va.latestUpdateDateAgent = '''' THEN ''N/A''
                        ELSE CONVERT(VARCHAR(10), va.latestUpdateDateAgent, 120) -- Devuelve como ''YYYY-MM-DD''
                    END, ''N/A''
                ) AS FechaUltimaModificacion -- Devuelve ''YYYY-MM-DD'' o ''N/A''
            FROM dbo.ccVirtualAgent va
            LEFT JOIN dbo.ccInbound ci ON ci.Inbound_id = va.idCampaign AND va.campType = 0
            LEFT JOIN dbo.ccCamps co ON co.cam_id = va.idCampaign AND va.campType = 1
            LEFT JOIN dbo.ccMetaWhatsAppNumbers wn ON wn.Inbound_Id = va.idCampaign AND va.campType = 0 AND mediaType != 0
            LEFT JOIN dbo.ccMetaWhatsAppNumbers wno ON wno.Cam_Id = va.idCampaign AND va.campType = 1 AND mediaType != 0
            LEFT JOIN dbo.ccRIAInboundGraph ig ON ig.Inbound_id = va.idCampaign AND va.campType = 0
            LEFT JOIN dbo.ccRIACampsGraph og ON og.cam_id = va.idCampaign AND va.campType = 1
        END

        ELSE IF @action = 2
        BEGIN
            -- Creación de un nuevo agente virtual
            INSERT INTO dbo.ccVirtualAgent (
                nameAgent, 
                statusAgent, 
                createDateAgent, 
                latestUpdateDateAgent
            )
            VALUES (
                @nameAgent, 
                @statusAgent, 
                GETDATE(), -- Fecha de creación actual
                NULL -- latestUpdateDateAgent
            );

            -- Retornar mensaje de éxito
            SELECT ''Agente creado exitosamente'' AS Resultado, SCOPE_IDENTITY() AS IdAgenteCreado;
        END

        ELSE IF @action = 3 -- Elimination of virtual Agent
        BEGIN
            CREATE TABLE #deletedVirtualAgents(idAgent int, agentName varchar(255))

            DELETE FROM dbo.ccVirtualAgent
            OUTPUT deleted.idAgent, deleted.nameAgent INTO #deletedVirtualAgents
            WHERE idAgent IN(SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,'','')) AND statusAgent = 0;

            SELECT * FROM #deletedVirtualAgents
        END

        ELSE IF @action = 4 -- Assignment or deassignment of campaign
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM ccVirtualAgent WHERE idAgent != @idVirtualAgent AND idCampaign = @campaignId AND mediaType = @mediaType AND campType = @campType) OR
            (@campaignId = 0)
            BEGIN
                UPDATE ccVirtualAgent SET idCampaign = @campaignId, 
                                        mediaType = @mediaType, 
                                        campType = @campType,
                                        latestUpdateDateAgent = GETDATE()
                WHERE idAgent = @idVirtualAgent

                SELECT @@ROWCOUNT
            END
                
                SELECT 0
        END

        ELSE IF @action = 5 -- Status change
        BEGIN
            CREATE TABLE #updatedVirtualAgents(idAgent int, nameAgent varchar(255), newStatus BIT)

            UPDATE ccVirtualAgent SET statusAgent = @statusAgent,
                                    latestUpdateDateAgent = GETDATE()
            OUTPUT inserted.idAgent, inserted.nameAgent, inserted.statusAgent as newStatus INTO #updatedVirtualAgents
            WHERE idAgent IN (SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,'','')) and statusAgent != @statusAgent

            SELECT * FROM #updatedVirtualAgents
        END
    END'
    EXEC(@sql)

    SET @process = 'Insertion of new module for Activity history'
    SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaModules WHERE moduleId = 24)
	BEGIN
        INSERT INTO ccGalateaModules VALUES (24,''Agentes virtuales'',''Virtual agents'',''Agentes virtuais'');
	END
    '
    EXEC(@sql)

    SET @process = 'Insertion of Operation for elimination of virtual agents'
	SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 127)
	BEGIN
        INSERT INTO ccGalateaOperations VALUES(127,''Eliminar agente'',''Delete agent'',''Excluir agente'');
	END'
    EXEC (@sql)

    SET @process = 'Insertion of Operation for disable of virtual agents'
	SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 128)
	BEGIN
        INSERT INTO ccGalateaOperations VALUES(128,''Deshabilitar agente'',''Disable agent'',''Desativar agente'');
	END'
    EXEC(@sql)

    SET @process = 'Insertion of Operation for enable virtual agents'
	SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 129)
	BEGIN
        INSERT INTO ccGalateaOperations VALUES (129,''Habilitar agente'',''Enable agent'',''Ativar agente'');
	END'
    EXEC(@sql)

    SET @process = 'Insertion of relationships between operations and new module'
	SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaModOpRelation WHERE ModuleId = 24 AND OperationId = 127)
	BEGIN
        INSERT INTO ccGalateaModOpRelation VALUES (24,127)
	END'
    EXEC(@sql)

    SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaModOpRelation WHERE ModuleId = 24 AND OperationId = 128)
	BEGIN
        INSERT INTO ccGalateaModOpRelation VALUES (24,128)
	END'
    EXEC(@sql)

    SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaModOpRelation WHERE ModuleId = 24 AND OperationId = 129)
	BEGIN
        INSERT INTO ccGalateaModOpRelation VALUES (24,129)
	END'
    EXEC(@sql)

    SET @process = 'Se agrega setting para registrar el número de agentes contratados'
	SET @sql= 'IF NOT EXISTS (select * from ccSettings2 where setting_id = 281)
	BEGIN
		insert into ccSettings2(setting_id, valor,descripcion,Status,Tipo, detalle, description, bLoadSettings, validate)
		values (281,''0'',''Numero de agentes virtuales'',1,''ADM'',''Numero de agentes virtuales'',''Number of virtual agents'',1,NULL)
	END'
    EXEC(@sql)
------------------------- END Carlos Eduardo Muñoz Carbajal --------------------------------------------

        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)
        COMMIT TRAN
    END TRY
    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()
        RAISERROR (@errorGenerated, 11, 1)
        ROLLBACK TRAN
    END CATCH
END 
