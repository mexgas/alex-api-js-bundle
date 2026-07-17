/*******************************/
/*******************************/
/*
Author: Equipo Galatea
Date: 2026/07/15
Description: July Release - K070177 (Dashboard Campana IA de Entrada) + K070381 (Extraccion de datos en Calificaciones IA)
Database: CCenterRia
Required version: 127.7
IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
USE CCenterRIA;

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
    SET @versionfix = 8
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

	---- =============================================================================== ----- 
	----SPRINT6FINALPART CREACIÓN y EDICIÓN / MODIFICACIÓN DE TABLAS E INSERCIÓN DE REGISTROS A CATALOGOS -----

	SET  @process = 'CW-11162 update value to zipCodeSchedule columna to 1, because old campaigns muste be active in this check'
	SET @sql = 'IF EXISTS (
			SELECT 1 FROM sys.columns 
			WHERE object_id = OBJECT_ID(''ccCampsExtend'') AND name = ''zipCodeSchedule''
		)
		BEGIN
			-- El UPDATE está directo, pero el truco evita que el compilador falle si la columna no existe
			UPDATE ccCampsExtend 
			SET zipCodeSchedule = COALESCE(zipCodeSchedule, 1);
		END'
	EXEC(@sql);

	SET  @process = 'CW-11162 update value identifier to SETTINGS_CHANGED_AREAS_ZIP cause the correct description'
	SET @sql = 'IF EXISTS(select 1 from ccGalateaIdentifiers 
			where [Description] = ''SETTINGS_CHANGED_AREAS_ZIP'')
			BEGIN
				UPDATE dbo.ccGalateaIdentifiers SET TagEs = ''Validación de zona horaria en marcación manual'',
				TagEn = ''Time zone validation on manual dialing'', TagPt = ''Validação de fuso horário em discagem manual''
				WHERE Description = ''SETTINGS_CHANGED_AREAS_ZIP''
			END'
	EXEC(@sql);

	 SET @process = 'KM28003 - CREATE TABLE ccoCallsOutSource_ZipCode TO CALLS'
    SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = ''ccoCallsOutSource_ZipCode'' AND schema_id = SCHEMA_ID(''dbo''))
		BEGIN
			CREATE TABLE dbo.ccoCallsOutSource_ZipCode (
				callout_id INT NOT NULL, 
        
				zipCode VARCHAR(10) DEFAULT(''''),
				isZipCodeValidation BIT DEFAULT(0)
        
				CONSTRAINT PK_ccoCallsOutSource_ZipCode PRIMARY KEY CLUSTERED (callout_id),
				CONSTRAINT FK_ccoCallsOutSource_ZipCode_Main FOREIGN KEY (callout_id) 
					REFERENCES dbo.ccoCallsOutSource(callout_id) ON DELETE CASCADE
			);

			CREATE INDEX IX_ccoCallsOutSource_ZipCode_Zip1 ON dbo.ccoCallsOutSource_ZipCode(zipCode);
		END'
    exec (@sql)

	SET @process = 'KM28003 - CREATE TABLE ccWhatsAppOutSource_ZipCode TO whatsapp'
    SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = ''ccWhatsAppOutSource_ZipCode'' AND schema_id = SCHEMA_ID(''dbo''))
	BEGIN
		CREATE TABLE dbo.ccWhatsAppOutSource_ZipCode (
			WAOut_Id BIGINT NOT NULL, 
			zipCode VARCHAR(10) DEFAULT(''''),
			isZipCodeValidation BIT DEFAULT(0),
        
			CONSTRAINT PK_ccWhatsAppOutSource_ZipCode PRIMARY KEY CLUSTERED (WAOut_Id),
			CONSTRAINT FK_ccWhatsAppOutSource_ZipCode_Main FOREIGN KEY (WAOut_Id) 
				REFERENCES dbo.ccWhatsAppOutSource(WAOut_Id) ON DELETE CASCADE
		);
	END'
    exec (@sql)

		SET @process = 'KM28003 - CREATE TABLE smsOutSource_ZipCode TO sms'
    SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = ''smsOutSource_ZipCode'' AND schema_id = SCHEMA_ID(''dbo''))
		BEGIN
			CREATE TABLE dbo.smsOutSource_ZipCode (
				smsout_id INT NOT NULL, 
				zipCode VARCHAR(10) DEFAULT(''''),
				isZipCodeValidation BIT DEFAULT(0),
        
				CONSTRAINT PK_smsOutSource_ZipCode PRIMARY KEY CLUSTERED (smsout_id),
				CONSTRAINT FK_smsOutSource_ZipCode_Main FOREIGN KEY (smsout_id) 
					REFERENCES dbo.smsOutSource(smsout_id) ON DELETE CASCADE
			);
		END'
    exec (@sql)

	SET @process = 'KM28003 - ALTER COLUMN TimeZone from ccWhatsAppOutSource table'
    SET @sql = 'IF EXISTS (
			SELECT 1 FROM sys.columns 
			WHERE object_id = OBJECT_ID(''dbo.ccWhatsAppOutSource'') AND name = ''TimeZone''
		)
		BEGIN
			ALTER TABLE ccWhatsAppOutSource 
			ALTER COLUMN TimeZone INT NULL;
		END;'
    exec (@sql)

	SET @process = 'KM28003 - ALTER COLUMN TimeZone_Summer from ccWhatsAppOutSource table'
    SET @sql = 'IF EXISTS (
			SELECT 1 FROM sys.columns 
			WHERE object_id = OBJECT_ID(''dbo.ccWhatsAppOutSource'') AND name = ''TimeZone_Summer''
		)
		BEGIN
			ALTER TABLE ccWhatsAppOutSource 
			ALTER COLUMN TimeZone_Summer INT NULL;
		END;'
    exec (@sql)

	SET @process = 'KM28003 - ALTER COLUMN TimeZone from ccoWAWorkingTable table'
    SET @sql = 'IF EXISTS (
				SELECT 1 FROM sys.columns 
				WHERE object_id = OBJECT_ID(''dbo.ccoWAWorkingTable'') AND name = ''TimeZone''
			)
			BEGIN
				ALTER TABLE dbo.ccoWAWorkingTable 
				ALTER COLUMN TimeZone INT NULL;
			END;'
    exec (@sql)

	SET @process = 'KM28003 - ALTER COLUMN TimeZone_Summer from ccoWAWorkingTable table'
    SET @sql = 'IF EXISTS (
			SELECT 1 FROM sys.columns 
			WHERE object_id = OBJECT_ID(''dbo.ccoWAWorkingTable'') AND name = ''TimeZone_Summer''
		)
		BEGIN
			ALTER TABLE ccoWAWorkingTable 
			ALTER COLUMN TimeZone_Summer INT NULL;
		END;'
    exec (@sql)

	 SET @process = 'KM28003 drop function fnGetTimeZoneByZip'
        SET @Sql = 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''fnGetTimeZoneByZip'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
		begin
			Drop function fnGetTimeZoneByZip
		end'
        EXEC (@Sql)
		SET @process = 'KM28003 CREATE function fnGetTimeZoneByZip'
		SET @sql = 'CREATE FUNCTION [dbo].[fnGetTimeZoneByZip]
		(
			@zipCode VARCHAR(30)
		)
		RETURNS TABLE
		AS
		RETURN
		(
			-- Devuelve ambos tz_id en una sola evaluación (invierno/verano)
			SELECT 
				inv.tz_id AS tz_id_invierno,
				v.tz_id   AS tz_id_verano,
				z.State
			FROM ccTimeZoneAreaCP AS z WITH (NOLOCK)
			INNER JOIN ccTimeZones AS inv
				ON inv.tz_offset = z.WinterTimeDifference
			INNER JOIN ccTimeZones AS v
				ON v.tz_offset   = z.SummerTimeDifference
			WHERE z.ZipCode = @zipCode
		);';
		EXEC(@sql);

		----SPRINT 7 CREACIÓN y EDICIÓN / MODIFICACIÓN DE TABLAS E INSERCIÓN DE REGISTROS A CATALOGOS -----

		SET @process = 'delete column TransferToHumanAgents from ccInboundExtend table'
		SET @sql= 'if exists (select * from sys.columns where name = N''TransferToHumanAgents'' 
		and Object_ID = Object_ID(N''ccInboundExtend''))
			begin
				ALTER TABLE dbo.ccInboundExtend DROP COLUMN TransferToHumanAgents
			end'
		EXEC(@sql);

		SET @process = 'delete column TransferOnFallback_ExternalNumber from ccInboundExtend table'
				SET @sql= 'if exists (select * from sys.columns where name = N''TransferOnFallback_ExternalNumber'' 
				and Object_ID = Object_ID(N''ccInboundExtend''))
			begin
				ALTER TABLE dbo.ccInboundExtend DROP COLUMN TransferOnFallback_ExternalNumber
			end'
		EXEC(@sql);

		SET @process = 'ALTER TABLE ccInboundExtend DROP CONSTRAINT FK_ccIBX_Fallback_Directory'
			SET @sql = 'IF exists(SELECT 1
		FROM sys.foreign_keys fk
		INNER JOIN sys.objects o ON fk.parent_object_id = o.object_id
		WHERE o.name = ''ccInboundExtend''
		  AND fk.name = ''FK_ccIBX_Fallback_Directory'') BEGIN
			ALTER TABLE ccInboundExtend
			DROP CONSTRAINT FK_ccIBX_Fallback_Directory;
		END
		'
			EXEC(@sql)

		SET @process = 'delete column TransferOnFallback_ExternalNumber from ccInboundExtend table'
				SET @sql= 'if exists (select * from sys.columns where name = N''TransferOnFallback_DirectoryId'' 
				and Object_ID = Object_ID(N''ccInboundExtend''))
			begin
				ALTER TABLE dbo.ccInboundExtend DROP COLUMN TransferOnFallback_DirectoryId
			end'
		EXEC(@sql);

		SET @process = 'delete column TransferOnFallback_Mode from ccInboundExtend table'
				SET @sql= 'if exists (select * from sys.columns where name = N''TransferOnFallback_Mode'' 
				and Object_ID = Object_ID(N''ccInboundExtend''))
			begin
	
				ALTER TABLE dbo.ccInboundExtend 
				DROP CONSTRAINT DF_ccIBX_Fallback_Mode;
				ALTER TABLE dbo.ccInboundExtend DROP COLUMN TransferOnFallback_Mode
			end'
		EXEC(@sql);

		SET @process = 'delete column TransferOnFallback_TimeoutSec from ccInboundExtend table'
				SET @sql= 'if exists (select * from sys.columns where name = N''TransferOnFallback_TimeoutSec'' 
				and Object_ID = Object_ID(N''ccInboundExtend''))
			begin
	
		
				ALTER TABLE dbo.ccInboundExtend 
				DROP CONSTRAINT DF_ccIBX_Fallback_TimeoutSec;
				ALTER TABLE dbo.ccInboundExtend DROP COLUMN TransferOnFallback_TimeoutSec
			end'
		EXEC(@sql);


		SET @process = 'delete column TransferOnSuccessfulHandling from ccInboundExtend table'
				SET @sql= 'if exists (select * from sys.columns where name = N''TransferOnSuccessfulHandling'' 
				and Object_ID = Object_ID(N''ccInboundExtend''))
			begin
	
				ALTER TABLE dbo.ccInboundExtend DROP COLUMN TransferOnSuccessfulHandling
			end'
		EXEC(@sql);

		SET @process = 'delete column TransferOnSuccess_ExternalNumber from ccInboundExtend table'
				SET @sql= 'if exists (select * from sys.columns where name = N''TransferOnSuccess_ExternalNumber'' 
				and Object_ID = Object_ID(N''ccInboundExtend''))
			begin
	
				ALTER TABLE dbo.ccInboundExtend DROP COLUMN TransferOnSuccess_ExternalNumber
			end'
		EXEC(@sql);

		SET @process = 'ALTER TABLE ccInboundExtend DROP CONSTRAINT FK_ccIBX_Success_Directory'
			SET @sql = 'IF exists(SELECT 1
		FROM sys.foreign_keys fk
		INNER JOIN sys.objects o ON fk.parent_object_id = o.object_id
		WHERE o.name = ''ccInboundExtend''
		  AND fk.name = ''FK_ccIBX_Success_Directory'') BEGIN
			ALTER TABLE ccInboundExtend
			DROP CONSTRAINT FK_ccIBX_Success_Directory;
		END
		'
			EXEC(@sql)

			SET @process = 'delete column TransferOnSuccess_DirectoryId from ccInboundExtend table'
				SET @sql= 'if exists (select * from sys.columns where name = N''TransferOnSuccess_DirectoryId'' 
				and Object_ID = Object_ID(N''ccInboundExtend''))
			begin
				ALTER TABLE dbo.ccInboundExtend DROP COLUMN TransferOnSuccess_DirectoryId
			end'
		EXEC(@sql);

		SET @process = 'delete column TransferOnSuccess_Mode from ccInboundExtend table'
				SET @sql= 'if exists (select * from sys.columns where name = N''TransferOnSuccess_Mode'' 
				and Object_ID = Object_ID(N''ccInboundExtend''))
			begin
				ALTER TABLE dbo.ccInboundExtend 
				DROP CONSTRAINT DF_ccIBX_Success_Mode;
				ALTER TABLE dbo.ccInboundExtend DROP COLUMN TransferOnSuccess_Mode
			end'
		EXEC(@sql);

		SET @process = 'delete column TransferOnSuccess_TimeoutSec from ccInboundExtend table'
				SET @sql= 'if exists (select * from sys.columns where name = N''TransferOnSuccess_TimeoutSec'' 
				and Object_ID = Object_ID(N''ccInboundExtend''))
			begin
		
				ALTER TABLE dbo.ccInboundExtend 
				DROP CONSTRAINT DF_ccIBX_Success_TimeoutSec;
				ALTER TABLE dbo.ccInboundExtend DROP COLUMN TransferOnSuccess_TimeoutSec
			end'
		EXEC(@sql);

		SET @process = 'delete identifier from ccGalateaIdentifier table'
		SET @sql = 'IF EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_ON_FALLBACK_MODE'') 
		BEGIN
			DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_ON_FALLBACK_MODE''
		END'
		EXEC(@sql)
		SET @process = 'delete identifier from ccGalateaIdentifier table'
		SET @sql = 'IF EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_ON_SUCCESSFUL_HANDLING'') 
		BEGIN
			DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_ON_SUCCESSFUL_HANDLING''
		END'
		EXEC(@sql)

		SET @process = 'delete identifier from ccGalateaIdentifier table'
		SET @sql = 'IF EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_ON_SUCCESS_MODE'') 
		BEGIN
			DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_ON_SUCCESS_MODE''
		END'
		EXEC(@sql)

		SET @process = 'delete identifier from ccGalateaIdentifier table'
		SET @sql = 'IF EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_BLIND_MODE'') 
		BEGIN
			DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_BLIND_MODE''
		END'
		EXEC(@sql)

		SET @process = 'delete identifier from ccGalateaIdentifier table'
		SET @sql = 'IF EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_TO_HUMAN_AGENTS'') 
		BEGIN
			DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_TO_HUMAN_AGENTS''
		END'
		EXEC(@sql)

		SET @process = 'delete identifier from ccGalateaIdentifier table'
		SET @sql = 'IF EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_DIRECTORY'') 
		BEGIN
			DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = ''COMMON_DIRECTORY''
		END'
		EXEC(@sql)

		SET @process = 'delete identifier from ccGalateaIdentifier table'
		SET @sql = 'IF EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_EXTERNAL_NUMBER'') 
		BEGIN
			DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = ''COMMON_EXTERNAL_NUMBER''
		END'
		EXEC(@sql)

		SET @process = 'delete identifier from ccGalateaIdentifier table'
		SET @sql = 'IF EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_ON_FALLBACK_TIMEOUTSEC'') 
		BEGIN
			DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_ON_FALLBACK_TIMEOUTSEC''
		END'
		EXEC(@sql)

		SET @process = 'delete identifier from ccGalateaIdentifier table'
		SET @sql = 'IF EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_ON_SUCCESS_TIMEOUTSEC'') 
		BEGIN
			DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_ON_SUCCESS_TIMEOUTSEC''
		END'
		EXEC(@sql)

		SET @process = 'delete identifier from ccGalateaIdentifier table'
		SET @sql = 'IF EXISTS (SELECT * FROM relationTableColumnIdentifiers WHERE tableName = ''ccInboundExtend'' and colunName IN 
		(
		''TransferToHumanAgents'',
		''TransferOnSuccessfulHandling'',
		''TransferOnFallback_Mode'',
		''TransferOnFallback_TimeoutSec'',
		''TransferOnSuccess_Mode'',
		''TransferOnSuccess_TimeoutSec''
		)) 
		BEGIN
			DELETE FROM dbo.relationTableColumnIdentifiers WHERE tableName = ''ccInboundExtend'' AND colunName IN
		(
		''TransferToHumanAgents'',
		''TransferOnSuccessfulHandling'',
		''TransferOnFallback_Mode'',
		''TransferOnFallback_TimeoutSec'',
		''TransferOnSuccess_Mode'',
		''TransferOnSuccess_TimeoutSec''
		)
		END'
		EXEC(@sql)

		SET @process = 'K070406 delete column idForSuccessfulTransaction from ccInbound table MAGV '
		SET @sql= 'if exists (select * from sys.columns where name = N''idForSuccessfulTransaction'' 
		and Object_ID = Object_ID(N''ccInbound''))
			begin
				ALTER TABLE dbo.ccInbound DROP COLUMN idForSuccessfulTransaction
			end'
		EXEC(@sql);

		SET @process = 'K070406 DROP column idForSuccessfulTransaction from ccInbound table MAGV'
				SET @sql= 'if exists (select * from sys.columns where name = N''idForNonComprehension'' 
				and Object_ID = Object_ID(N''ccInbound''))
			begin
				ALTER TABLE dbo.ccInbound DROP COLUMN idForNonComprehension
			end'
		EXEC(@sql);

		SET @process = 'K070406 delete identifier from ccGalateaIdentifier table MAGV'
		SET @sql = 'IF EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''ASSOCIATED_CAMP_XFER_IA'') 
		BEGIN
			DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = ''ASSOCIATED_CAMP_XFER_IA''
		END'
		EXEC(@sql)

		SET @process = 'K070406 delete identifier from ccGalateaIdentifier table MAGV'
		SET @sql = 'IF EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''ASSOCIATED_CAMP_SUCCESSFUL_TRANSACTION'') 
		BEGIN
			DELETE FROM dbo.ccGalateaIdentifiers WHERE Description = ''ASSOCIATED_CAMP_SUCCESSFUL_TRANSACTION''
		END'
		EXEC(@sql)


		SET @process = 'K070407 insert new idenfitifiers to the activity historical'
		SET @sql = 'IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_RETRY_DIALING'')
		BEGIN
			INSERT INTO dbo.ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''AI_UPDATE_DISPOSITION_RETRY_DIALING'', ''Reintentar marcación'', ''Retry dialing'', ''Tentar discagem novamente'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_RETRIES_NUMBER'')
		BEGIN
			INSERT INTO dbo.ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''AI_UPDATE_DISPOSITION_RETRIES_NUMBER'', ''Reintentos de marcación'', ''Dialing retries'', ''Tentativas de discagem'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_RETRIES_INTERVAL'')
		BEGIN
			INSERT INTO dbo.ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''AI_UPDATE_DISPOSITION_RETRIES_INTERVAL'', ''Intervalo entre reintentos de marcación (min)'', ''Interval between dialing retries (min)'', ''Intervalo entre tentativas de discagem (min)'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_TRANSFER_MODE'')
		BEGIN
			INSERT INTO dbo.ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''AI_UPDATE_DISPOSITION_TRANSFER_MODE'', ''Modalidad de transferencia'', ''Transfer mode'', ''Modalidade de transferência'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_TRANSFER_OPTION_HUMAN_AGENT'')
		BEGIN
			INSERT INTO dbo.ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''AI_UPDATE_DISPOSITION_TRANSFER_OPTION_HUMAN_AGENT'', ''Agente humano'', ''Live agent'', ''Agente humano'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_TRANSFER_OPTION_ASSISTED'')
		BEGIN
			INSERT INTO dbo.ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''AI_UPDATE_DISPOSITION_TRANSFER_OPTION_ASSISTED'', ''Asistida'', ''Assisted'', ''Assistida'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_TRANSFER_OPTION_BLIND'')
		BEGIN
			INSERT INTO dbo.ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''AI_UPDATE_DISPOSITION_TRANSFER_OPTION_BLIND'', ''Ciega'', ''Blind'', ''Cega'');
		END

		IF NOT EXISTS (SELECT 1 FROM dbo.ccGalateaIdentifiers WHERE Description = ''AI_UPDATE_DISPOSITION_TRANSFER_MAX_TRANSFER_TIME'')
		BEGIN
			INSERT INTO dbo.ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''AI_UPDATE_DISPOSITION_TRANSFER_MAX_TRANSFER_TIME'', ''Tiempo máximo de transferencia'', ''Maximum transfer time'', ''Tempo máximo de transferência'');
		END'

		EXEC(@sql)


		set @process = 'K070407 Alter Column Description_cal from table cctipoCalif_IA MAGV'
		set @Sql= 'if exists (select * from sys.columns where name = N''Description_cal'' and Object_ID = Object_ID(N''dbo.cctipoCalif_IA'')) 
					BEGIN
						ALTER TABLE dbo.cctipoCalif_IA
						ALTER COLUMN Description_cal VARCHAR(500);
					END'
		EXEC(@Sql)

		SET @process = 'K070407 cctipoCalif_IA - Alter Table MAGV'
		SET @sql = '
			IF NOT EXISTS (
				SELECT 1
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = ''cctipoCalif_IA''
					AND COLUMN_NAME = ''AplRetryDialing''
			)
			BEGIN
				ALTER TABLE cctipoCalif_IA ADD AplRetryDialing bit
			END
		';

		EXEC(@sql);

		SET @process = 'K070407 cctipoCalif_IA - Alter Table Add CallbackTries and CallbackInterval MAGV'
		SET @sql = '
			IF NOT EXISTS (
				SELECT 1
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = ''cctipoCalif_IA''
					AND COLUMN_NAME = ''CallbackTries''
			)
			BEGIN
				ALTER TABLE cctipoCalif_IA ADD CallbackTries INT NULL
			END

			IF NOT EXISTS (
				SELECT 1
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = ''cctipoCalif_IA''
					AND COLUMN_NAME = ''CallbackInterval''
			)
			BEGIN
				ALTER TABLE cctipoCalif_IA ADD CallbackInterval INT NULL
			END
		';

		EXEC(@sql);
		SET @process = 'K070407 CREATE TABLE dbo.ccCalif_IA_TransferOptionCatalog MAGV'
		SET @sql = 'IF OBJECT_ID(''dbo.ccCalif_IA_TransferOptionCatalog'', ''U'') IS NULL
		BEGIN
			CREATE TABLE dbo.ccCalif_IA_TransferOptionCatalog (
				TransferOptionId SMALLINT NOT NULL,
				Name VARCHAR(50) NOT NULL,
				Description VARCHAR(250) NULL,
        
				CONSTRAINT PK_ccCalif_IA_TransferOptionCatalog PRIMARY KEY CLUSTERED (TransferOptionId)
			);
		END'
		EXEC(@sql);

	SET @process = 'K070407 INSERT INTO rows in ccCalif_IA_TransferOptionCatalog MAGV'
	SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM dbo.ccCalif_IA_TransferOptionCatalog WHERE TransferOptionId = 1)
	BEGIN
		INSERT INTO dbo.ccCalif_IA_TransferOptionCatalog (TransferOptionId, Name, Description)
		VALUES (1, ''Asistida'', ''The virtual agent waits for the destination to answer before fully transferring the customer (Warm Transfer)'');
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.ccCalif_IA_TransferOptionCatalog WHERE TransferOptionId = 2)
	BEGIN
		INSERT INTO dbo.ccCalif_IA_TransferOptionCatalog (TransferOptionId, Name, Description)
		VALUES (2, ''Ciega'', ''The virtual agent transfers the customer immediately without waiting for a response from the destination (Blind Transfer)'');
	END'
	EXEC (@sql)

	SET @process = 'K070407 CREATE TABLE dbo.ccCalif_IA_DestinationTypeCatalog MAGV'
	SET @sql = 'IF OBJECT_ID(''dbo.ccCalif_IA_DestinationTypeCatalog'', ''U'') IS NULL
	BEGIN
	   CREATE TABLE dbo.ccCalif_IA_DestinationTypeCatalog (
		DestinationTypeId SMALLINT NOT NULL, 
		Name VARCHAR(50) NOT NULL,
		Description VARCHAR(150) NULL,
    
			CONSTRAINT PK_ccCalif_IA_DestinationTypeCatalog PRIMARY KEY CLUSTERED (DestinationTypeId)
		);
	END'
	EXEC(@sql);

	SET @process = 'K070407 INSERT INTO rows in ccCalif_IA_DestinationTypeCatalog'
	SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM dbo.ccCalif_IA_DestinationTypeCatalog WHERE DestinationTypeId = 1)
	BEGIN
		INSERT INTO dbo.ccCalif_IA_DestinationTypeCatalog (DestinationTypeId, Name, Description)
		VALUES (1, ''Campaña'', ''Destination oriented toward internal system campaigns'');
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.ccCalif_IA_DestinationTypeCatalog WHERE DestinationTypeId = 2)
	BEGIN
		INSERT INTO dbo.ccCalif_IA_DestinationTypeCatalog (DestinationTypeId, Name, Description)
		VALUES (2, ''Número Externo'', ''Destination toward a phone number outside the system or a directory'');
	END'
	EXEC (@sql)

		SET @process = 'K070407 CREATE TABLE dbo.ccCalif_IA_TransferConfig MAGV'
	SET @sql = 'IF OBJECT_ID(''dbo.ccCalif_IA_TransferConfig'', ''U'') IS NULL
	BEGIN
		CREATE TABLE dbo.ccCalif_IA_TransferConfig (
			DispositionId SMALLINT NOT NULL,
			DestinationTypeId SMALLINT NOT NULL,      
			TransferOptionId SMALLINT NOT NULL,   
			MaxTransferTime SMALLINT NOT NULL DEFAULT 60,

			DestinationCampId SMALLINT NULL,               
			DestinationNumber VARCHAR(10) NULL,       
			DestinationDirectoryId SMALLINT NULL,          

			-- Llaves Primarias y Foráneas
			CONSTRAINT PK_ccCalif_IA_TransferConfig PRIMARY KEY CLUSTERED (DispositionId),
    
			CONSTRAINT FK_TransferConfig_cctipoCalif_IA FOREIGN KEY (DispositionId) 
				REFERENCES dbo.cctipoCalif_IA (calif_id) ON DELETE CASCADE,
        
			CONSTRAINT FK_TransferConfig_DestinationTypeCatalog FOREIGN KEY (DestinationTypeId) 
				REFERENCES dbo.ccCalif_IA_DestinationTypeCatalog (DestinationTypeId),

			CONSTRAINT FK_TransferConfig_TransferOptionCatalog FOREIGN KEY (TransferOptionId) 
				REFERENCES dbo.ccCalif_IA_TransferOptionCatalog (TransferOptionId)
		);
	END'
	exec (@sql)






    -- =====================================================================
    -- K070177 - Calificaciones de campana de llamadas de entrada (IA) en Dashboard
    -- BD: CCenterRIA
    -- Cambios:
    --   1. SP ccsp_GalateaGetCalifDayIA: conteo del dia de calificaciones
    --      puestas por agentes virtuales en campanas IA de entrada, para la
    --      card "Calificaciones" del Dashboard (grafica de pastel + desglose).
    -- Notas:
    --   - Devuelve TODAS las calificaciones configuradas en la campana
    --     (ccCalifCampIA) aunque tengan 0 usos, para que la card muestre el
    --     catalogo completo.
    --   - Fila con CalificationId = 0 representa "Sin calificacion":
    --     llamadas atendidas (statusCall_id = 13) del dia sin calificacion.
    --     El front traduce la etiqueta (ES/EN/PT).
    --   - Registros con calificacion cuentan sin filtrar status (una llamada
    --     reencolada/abandonada puede conservar la calif del agente virtual).
    --   - Porcentajes se calculan en el front.
    -- =====================================================================
    SET @process = 'K070177 - DROP ccsp_GalateaGetCalifDayIA'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetCalifDayIA'')
    begin
            DROP PROCEDURE ccsp_GalateaGetCalifDayIA;
    end'
    exec (@sql)

    SET @process = 'K070177 - CREATE ccsp_GalateaGetCalifDayIA'
    SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaGetCalifDayIA]
    @InboundId SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @today DATETIME = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 101));

    SELECT
        cat.calif_id                       AS CalificationId,
        cat.Name_cal                       AS Calification,
        ISNULL(cat.Color, '''')            AS GraphColor,
        ISNULL(cnt.Total, 0)               AS Total
    FROM ccCalifCampIA rel WITH (NOLOCK)
    INNER JOIN cctipoCalif_IA cat WITH (NOLOCK)
        ON cat.calif_id = rel.calif_id
    LEFT JOIN (
        SELECT calif_id, COUNT(*) AS Total
        FROM ccCallsIn WITH (NOLOCK)
        WHERE cal_Inicio > @today
          AND Inbound_id = @InboundId
          AND ISNULL(calif_id, 0) > 0
        GROUP BY calif_id
    ) cnt ON cnt.calif_id = cat.calif_id
    WHERE rel.cam_id = @InboundId
      AND rel.tipo = 0

    UNION ALL

    SELECT
        CAST(0 AS SMALLINT)                AS CalificationId,
        ''systemTranslated_NoDisposition'' AS Calification,
        ''''                               AS GraphColor,
        COUNT(*)                           AS Total
    FROM ccCallsIn WITH (NOLOCK)
    WHERE cal_Inicio > @today
      AND Inbound_id = @InboundId
      AND statusCall_id = 13
      AND ISNULL(calif_id, 0) = 0
END
'
    exec (@sql)

    -- =====================================================================
    -- K070381 - Mejoras en la extraccion de datos (Calificaciones IA)
    -- BD: CCenterRIA
    -- Cambios:
    --   1. Tabla ccExtractionDataCatalog: catalogo global (por cliente) de
    --      "datos a extraer" configurables desde el panel "Anadir dato"
    --      del modal de Calificacion IA (Nombre/Tipo/Descripcion).
    --   2. Tabla ccDispositionExtractionData: relacion N:M entre una
    --      Calificacion IA (cctipoCalif_IA) y los items del catalogo
    --      seleccionados para esa calificacion (maximo 10, validado en
    --      capa de aplicacion).
    --   3. SP ccsp_GalateaAdminExtractionDataCatalog: CRUD del catalogo
    --      (patron identico a BlackList.Catalog: @Option + acciones).
    --   4. SP ccsp_GalateaAdminDispositionExtractionData: guarda/lee la
    --      relacion N:M para una calificacion (delete+insert, mismo
    --      patron que listas separadas por coma via fn_RIASplitDelimited).
    --   5. ALTER ccsp_ManageQuantumDispositions (Action=3): se deja de leer
    --      cci.ExtDescription (texto libre, no cumplia el contrato
    --      documentado por Quantum) como fuente de required_data.
    --   6. ALTER ccsp_ManageQuantumDispositions: se agrega Action=7, que
    --      devuelve los items de extraccion requeridos por calificacion
    --      para toda la campana, para que la capa de aplicacion arme
    --      required_data: [{name,type,description}] al sincronizar con
    --      Quantum.
    --   7. Migracion de cctipoCalif_IA a IDENTITY (ver detalle abajo).
    -- Notas:
    --   - Sin FOR JSON / OPENJSON (SQL Server 2012): el JSON de
    --     required_data se arma en C#.
    --   - Type en catalogo: 0=Numero, 1=Texto, 2=Fecha.
    -- =====================================================================
    SET @process = 'K070381 - CREATE TABLE ccExtractionDataCatalog'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = ''ccExtractionDataCatalog'')
    BEGIN
        CREATE TABLE dbo.ccExtractionDataCatalog (
            Id              INT IDENTITY(1,1) NOT NULL,
            Name            VARCHAR(20)  NOT NULL,
            [Key]           VARCHAR(30)  NOT NULL,
            Type            TINYINT      NOT NULL, -- 0=Numero, 1=Texto, 2=Fecha
            Description     VARCHAR(150) NULL,
            Active          BIT          NOT NULL DEFAULT 1,
            CreatedBy       SMALLINT     NULL,
            CreatedDate     DATETIME     NOT NULL DEFAULT GETDATE(),
            CONSTRAINT PK_ccExtractionDataCatalog PRIMARY KEY CLUSTERED (Id),
            CONSTRAINT UQ_ccExtractionDataCatalog_Key UNIQUE ([Key])
        )
    END
'
    exec (@sql)

    SET @process = 'K070381 - CREATE TABLE ccDispositionExtractionData'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = ''ccDispositionExtractionData'')
    BEGIN
        CREATE TABLE dbo.ccDispositionExtractionData (
            calif_id         SMALLINT NOT NULL,
            ExtractionDataId INT      NOT NULL,
            CONSTRAINT PK_ccDispositionExtractionData PRIMARY KEY CLUSTERED (calif_id, ExtractionDataId),
            CONSTRAINT FK_ccDispositionExtractionData_Calif FOREIGN KEY (calif_id)
                REFERENCES dbo.cctipoCalif_IA (calif_id),
            CONSTRAINT FK_ccDispositionExtractionData_Catalog FOREIGN KEY (ExtractionDataId)
                REFERENCES dbo.ccExtractionDataCatalog (Id)
        )
    END
'
    exec (@sql)

    SET @process = 'K070381 - DROP ccsp_GalateaAdminExtractionDataCatalog'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminExtractionDataCatalog'')
    begin
            DROP PROCEDURE ccsp_GalateaAdminExtractionDataCatalog;
    end'
    exec (@sql)

    SET @process = 'K070381 - CREATE ccsp_GalateaAdminExtractionDataCatalog'
    SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminExtractionDataCatalog]
    @Option      SMALLINT,           -- 1=CREATE, 2=READ (list), 3=UPDATE, 4=DEACTIVATE
    @Id          INT           = NULL,
    @Name        VARCHAR(20)   = NULL,
    @Key         VARCHAR(30)   = NULL,
    @Type        TINYINT       = NULL,
    @Description VARCHAR(150)  = NULL,
    @User_id     SMALLINT      = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Option = 1 -- CREATE
    BEGIN
        IF EXISTS (SELECT 1 FROM ccExtractionDataCatalog WHERE [Key] = @Key AND Active = 1)
        BEGIN
            RAISERROR(''Duplicate extraction data key'', 16, 1)
            RETURN
        END

        INSERT INTO ccExtractionDataCatalog (Name, [Key], Type, Description, Active, CreatedBy, CreatedDate)
        VALUES (@Name, @Key, @Type, @Description, 1, @User_id, GETDATE())

        SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id, @Name AS Name, @Key AS [Key], @Type AS Type, @Description AS Description
    END

    IF @Option = 2 -- READ (catalogo completo activo)
    BEGIN
        SELECT
            Id,
            Name,
            [Key],
            Type,
            Description
        FROM ccExtractionDataCatalog WITH (NOLOCK)
        WHERE Active = 1
        ORDER BY Name
    END

    IF @Option = 3 -- UPDATE
    BEGIN
        UPDATE ccExtractionDataCatalog
        SET Name = ISNULL(@Name, Name),
            Type = ISNULL(@Type, Type),
            Description = @Description
        WHERE Id = @Id

        SELECT Id, Name, [Key], Type, Description FROM ccExtractionDataCatalog WHERE Id = @Id
    END

    IF @Option = 4 -- DEACTIVATE (no se borra fisicamente por integridad con relaciones historicas)
    BEGIN
        UPDATE ccExtractionDataCatalog SET Active = 0 WHERE Id = @Id
    END
END
'
    exec (@sql)

    SET @process = 'K070381 - DROP ccsp_GalateaAdminDispositionExtractionData'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminDispositionExtractionData'')
    begin
            DROP PROCEDURE ccsp_GalateaAdminDispositionExtractionData;
    end'
    exec (@sql)

    SET @process = 'K070381 - CREATE ccsp_GalateaAdminDispositionExtractionData'
    SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminDispositionExtractionData]
    @Option              SMALLINT,          -- 1=SAVE (delete+insert), 2=GET
    @CalifId             SMALLINT,
    @ExtractionDataIds   VARCHAR(MAX) = NULL -- CSV de Id''s, solo para @Option=1
AS
BEGIN
    SET NOCOUNT ON;

    IF @Option = 1 -- SAVE
    BEGIN
        DELETE FROM ccDispositionExtractionData WHERE calif_id = @CalifId

        IF @ExtractionDataIds IS NOT NULL AND LEN(@ExtractionDataIds) > 0
        BEGIN
            INSERT INTO ccDispositionExtractionData (calif_id, ExtractionDataId)
            SELECT @CalifId, CAST(value AS INT)
            FROM dbo.fn_RIASplitDelimited(@ExtractionDataIds, '','')
        END
    END

    IF @Option = 2 -- GET
    BEGIN
        SELECT
            cat.Id,
            cat.Name,
            cat.[Key],
            cat.Type,
            cat.Description
        FROM ccDispositionExtractionData rel WITH (NOLOCK)
        INNER JOIN ccExtractionDataCatalog cat WITH (NOLOCK)
            ON cat.Id = rel.ExtractionDataId
        WHERE rel.calif_id = @CalifId
        ORDER BY cat.Name
    END
END
'
    exec (@sql)

    SET @process = 'K070381 - ALTER ccsp_ManageQuantumDispositions (Action=3 fix + Action=7 extraction data, preservando limpieza de Marco/K070405: sin Action=5, Transfer via ccCalif_IA_TransferConfig)'
    SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_ManageQuantumDispositions]
        @Action INT,
        @CampId INT = NULL,
        @AgentId INT = NULL,
        @CampType INT = NULL,
        @VoiceId INT = NULL
AS
BEGIN
    DECLARE @Inbound INT = 0, @Outbound INT = 1
    IF @Action = 1 --Get API Data
    BEGIN
        DECLARE @key VARCHAR(255)
        SELECT @key = valor FROM ccSettings2 WHERE setting_id = 284
        SELECT valor AS ApiUrl, @key AS [Key] FROM ccSettings2 WHERE setting_id = 290
    END
    IF @Action = 2 --Get Quantum Id Agent Data
    BEGIN
        SELECT quantumAgentId
        FROM ccVirtualAgent
        WHERE
            (@AgentId IS NOT NULL AND idAgent = @AgentId)
            OR (@AgentId IS NULL AND campType = @CampType AND idCampaign = @CampId);
    END
    IF @Action = 3 --Get Quantum Dispositions by camp
    BEGIN
        -- Result set 1: cabecera de disposiciones (sin ExtDescription -- K070381).
        -- Transfer usa dbo.ccCalif_IA_TransferConfig (K070405, ya vigente en produccion),
        -- no AplTransfer solo -- mantener alineado con el SP que Marco ya desplego.
        SELECT
            cci.calif_id AS [Id],
        cci.Name_cal AS [Name],
        cci.Description_cal AS [Description],
        CAST(CASE WHEN cci.CanReprogram = 1 OR cci.autoCallback = 1 THEN 1 ELSE 0 END AS INT) AS Callback,
        CAST(
            CASE
                WHEN cci.AplTransfer = 1 AND EXISTS (
                    SELECT 1
                    FROM dbo.ccCalif_IA_TransferConfig AS ccitc
                    WHERE ccitc.DispositionId = cci.calif_id
                      AND (
                          NULLIF(ccitc.DestinationNumber, '''') IS NOT NULL
                          OR ISNULL(ccitc.DestinationCampId, 0) > 0
                          OR ISNULL(ccitc.DestinationDirectoryId, 0) > 0
                      )
                ) THEN 1
                ELSE 0
            END
        AS INT) AS Transfer
        FROM dbo.ccCalifCampIA AS ccci INNER JOIN dbo.cctipoCalif_IA AS cci
        ON cci.calif_id = ccci.calif_id
        WHERE ccci.tipo = @CampType
        AND ccci.cam_id = @CampId
    END
    IF @Action = 4 -- Get Quantum Agent Voice Id
    BEGIN
        SELECT ISNULL(
            (SELECT QuantumVoiceId
             FROM ccVirtualAgentVoices
             WHERE ID = @VoiceId),
            ''''
        ) AS QuantumVoiceId;
    END

    IF @Action = 6 -- Agent Id By Campaign
    BEGIN
        IF(@CampType = 0)
        BEGIN

            SELECT ISNULL(
                (SELECT TOP 1 idAgent
                 FROM ccVirtualAgent
                 WHERE idCampaign = @CampId
                   AND mediaType = 11
                   AND campType = 0),
                0
            ) AS idAgent;
        END
        ELSE
        BEGIN
            SELECT ISNULL(
                    (SELECT TOP 1 idAgent
                     FROM ccVirtualAgent
                     WHERE idCampaign = @CampId
                       AND mediaType = 10 AND campType = 1),
                    0
                ) AS idAgent;
        END
    END

    IF @Action = 7 -- Get Quantum Extraction Data by camp (K070381)
    BEGIN
        -- Items de extraccion requeridos por calificacion, para toda la
        -- campana. Action independiente (no segundo result set de
        -- Action=3) porque el helper base de acceso a datos en C# solo
        -- lee un result set por llamada. Reemplaza el uso de
        -- cci.ExtDescription (texto libre) como fuente de required_data
        -- -- ahora se arma en C# como [{name,type,description}]
        SELECT
            ccci.calif_id           AS [Id],
            cat.Name                AS [Name],
            cat.Type                AS [Type],
            cat.Description         AS [Description]
        FROM dbo.ccCalifCampIA AS ccci
        INNER JOIN dbo.ccDispositionExtractionData AS rel
            ON rel.calif_id = ccci.calif_id
        INNER JOIN dbo.ccExtractionDataCatalog AS cat
            ON cat.Id = rel.ExtractionDataId
        WHERE ccci.tipo = @CampType
        AND ccci.cam_id = @CampId
        AND cat.Active = 1
        ORDER BY ccci.calif_id
    END
END
'
    exec (@sql)

    -- =====================================================================
    -- K070381 - Migrar cctipoCalif_IA a IDENTITY
    -- Motivo: la tabla se creo originalmente "Sin identity" (calif_id
    -- calculado a mano con MAX(calif_id)+1), y en algun punto de
    -- ServicesPack9 la SP dejo de calcularlo, provocando "Cannot insert
    -- the value NULL into column calif_id" al crear una calificacion IA
    -- nueva. Ademas, el calculo manual MAX+1 es una condicion de carrera
    -- real en un sistema concurrente. Se resuelve pasando la columna a
    -- IDENTITY, que es atomico.
    --
    -- ADVERTENCIA - REPLICACION: cctipoCalif_IA puede ser articulo de
    -- replicacion (transaccional/snapshot) en instalaciones existentes.
    -- Este bloque ABORTA si detecta que la tabla sigue siendo articulo
    -- de una publicacion -- en ese caso, el despliegue de esta version
    -- DEBE ejecutarse con la opcion "Eliminar Replicas" activa en el
    -- instalador (installGroup.replicationRemove) antes de correr este
    -- script.
    -- =====================================================================
    SET @process = 'K070381 - Migrar cctipoCalif_IA a IDENTITY'
    SET @sql = '
    IF NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(''dbo.cctipoCalif_IA'') AND name = ''calif_id'' AND is_identity = 1
    )
    BEGIN
        IF EXISTS (
            SELECT 1 FROM sysarticles a
            INNER JOIN syspublications p ON a.pubid = p.pubid
            WHERE a.name = ''cctipoCalif_IA''
        )
        BEGIN
            RAISERROR(''cctipoCalif_IA sigue siendo articulo de replicacion. Ejecutar el update con "Eliminar Replicas" activo en el instalador antes de aplicar este script.'', 16, 1)
        END
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = ''FK_ccDispositionExtractionData_Calif'')
            ALTER TABLE dbo.ccDispositionExtractionData DROP CONSTRAINT FK_ccDispositionExtractionData_Calif

        EXEC sp_rename ''dbo.cctipoCalif_IA'', ''cctipoCalif_IA_old''
        EXEC sp_rename ''dbo.cctipoCalifIA'', ''cctipoCalifIA_old'', ''OBJECT''

        CREATE TABLE dbo.cctipoCalif_IA (
            calif_id smallint IDENTITY(1,1) NOT NULL,
            Name_cal varchar(150) NULL,
            Description_cal varchar(100) NULL,
            CanReprogram bit DEFAULT 0,
            autoCallback bit DEFAULT 0,
            ReturnCall smallint DEFAULT 0,
            Color varchar(15) NULL,
            AplTransfer bit DEFAULT 0,
            TransferOpcion smallint DEFAULT 0,
            DestinyIVR bit DEFAULT 0,
            DestinyIVR_camp smallint DEFAULT 0,
            DestinyIVR_number VARCHAR(20) NULL,
            DestinyIVR_directory smallint DEFAULT 0,
            AplExtDate bit DEFAULT 0,
            ExtDescription varchar(150) NULL,
            AplBlackList bit NULL,
            Cali_StatusIA bit NULL,
            DirectoryNumberFlag bit DEFAULT 1,
            CONSTRAINT cctipoCalifIA PRIMARY KEY CLUSTERED (calif_id)
        )

        SET IDENTITY_INSERT dbo.cctipoCalif_IA ON

        INSERT INTO dbo.cctipoCalif_IA (
            calif_id, Name_cal, Description_cal, CanReprogram, autoCallback, ReturnCall, Color,
            AplTransfer, TransferOpcion, DestinyIVR, DestinyIVR_camp, DestinyIVR_number,
            DestinyIVR_directory, AplExtDate, ExtDescription, AplBlackList, Cali_StatusIA, DirectoryNumberFlag
        )
        SELECT
            calif_id, Name_cal, Description_cal, CanReprogram, autoCallback, ReturnCall, Color,
            AplTransfer, TransferOpcion, DestinyIVR, DestinyIVR_camp, DestinyIVR_number,
            DestinyIVR_directory, AplExtDate, ExtDescription, AplBlackList, Cali_StatusIA, DirectoryNumberFlag
        FROM dbo.cctipoCalif_IA_old

        SET IDENTITY_INSERT dbo.cctipoCalif_IA OFF

        DECLARE @maxCalifId INT
        SELECT @maxCalifId = ISNULL(MAX(calif_id), 0) FROM dbo.cctipoCalif_IA
        DBCC CHECKIDENT (''dbo.cctipoCalif_IA'', RESEED, @maxCalifId)

        ALTER TABLE dbo.ccDispositionExtractionData
            ADD CONSTRAINT FK_ccDispositionExtractionData_Calif FOREIGN KEY (calif_id)
            REFERENCES dbo.cctipoCalif_IA (calif_id)

        DROP TABLE dbo.cctipoCalif_IA_old
    END
'
    exec (@sql)

    SET @process = 'K070300 - CREATE TABLE ccLogTransfers_IA (captura de transferencias IA para reporte de Agentes Virtuales)'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = ''ccLogTransfers_IA'')
    BEGIN
        CREATE TABLE dbo.ccLogTransfers_IA (
            cal_id INT NOT NULL,
            tipo TINYINT NOT NULL,
            modo TINYINT NOT NULL,
            destino VARCHAR(50) NULL,
            tAntesXfer INT NULL,
            tDespuesXfer INT NULL,
            fechaFin DATETIME NOT NULL,
            pbxId TINYINT NULL,
            channel INT NULL,
            tipoLlamada_id SMALLINT NULL,
            callerAni VARCHAR(50) NULL,
            replkey UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ccLogTransfers_IA_replkey DEFAULT (NEWSEQUENTIALID()),
            destination VARCHAR(50) NULL,
            destination_name VARCHAR(50) NULL,
            rowguid UNIQUEIDENTIFIER NOT NULL ROWGUIDCOL CONSTRAINT DF_ccLogTransfers_IA_rowguid DEFAULT (NEWSEQUENTIALID()),
            CONSTRAINT PK_ccLogTransfers_IA PRIMARY KEY CLUSTERED (cal_id, tipo)
        )
    END

    IF OBJECT_ID(''dbo.ccsp_InsertLogTransfers_IA'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_InsertLogTransfers_IA
    '
    exec (@sql)

    SET @process = 'K070300 - CREATE ccsp_InsertLogTransfers_IA'
    SET @sql = '
CREATE PROCEDURE dbo.ccsp_InsertLogTransfers_IA
    @cal_id INT,
    @tipo TINYINT,
    @modo TINYINT,
    @fechaFin DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.ccLogTransfers_IA (cal_id, tipo, modo, fechaFin)
    VALUES (@cal_id, @tipo, @modo, @fechaFin);
END
'
    exec (@sql)

    SET @process = 'KM28005 - DROP ccsp_ValidateZipCodeCampSchedule si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_ValidateZipCodeCampSchedule'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_ValidateZipCodeCampSchedule
    '
    exec (@sql)

    SET @process = 'KM28005 - CREATE ccsp_ValidateZipCodeCampSchedule (valida CP contra horario real de campana, CW-11164/CW-11166)'
    SET @sql = '
CREATE PROCEDURE dbo.ccsp_ValidateZipCodeCampSchedule
    @campId  INT,
    @zipCode NVARCHAR(5)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @offset INT;
    SELECT @offset = WinterTimeDifference
    FROM ccTimeZoneAreaCP
    WHERE ZipCode = @zipCode;

    IF @offset IS NULL
    BEGIN
        SELECT CAST(1 AS BIT) AS IsAllowed;
        RETURN;
    END

    SET DATEFIRST 1;

    DECLARE @utcNow DATETIME = GETUTCDATE();
    DECLARE @localTime DATETIME = DATEADD(HOUR, @offset, @utcNow);
    DECLARE @h  INT = DATEPART(HH, @localTime);
    DECLARE @m  INT = DATEPART(MI, @localTime);
    DECLARE @dw INT = DATEPART(DW, @localTime);

    SELECT CAST(
        CASE WHEN EXISTS (
            SELECT 1
            FROM ccHorarios h
            INNER JOIN ccCampsHorarios ch ON h.horario_id = ch.Horario_id
            WHERE ch.cam_id = @campId
              AND ( @h > h.HoraInicio OR (@h = h.HoraInicio AND @m >= h.MinInicio) )
              AND ( @h < h.HoraFin    OR (@h = h.HoraFin    AND @m <= h.MinFin)    )
              AND (
                    (@dw = 1 AND h.Lunes     = 1) OR
                    (@dw = 2 AND h.Martes    = 1) OR
                    (@dw = 3 AND h.Miercoles = 1) OR
                    (@dw = 4 AND h.Jueves    = 1) OR
                    (@dw = 5 AND h.Viernes   = 1) OR
                    (@dw = 6 AND h.Sabado    = 1) OR
                    (@dw = 7 AND h.Domingo   = 1)
              )
        ) THEN 1 ELSE 0 END
    AS BIT) AS IsAllowed;
END
'
    exec (@sql)

    -- =====================================================================
    -- Sprint6_finalPart (David Medina) - transferencias de entrada IA
    -- Guarda el id del agente virtual en ccCallsIn para que el StateMachine
    -- pueda leer la info del agente virtual al procesar la llamada de
    -- entrada (ya existia el equivalente de salida via ccoCallsOut.virtualAgentId).
    -- Se llama desde InBridgeAgentQuantumHelper (cw-service-telephony,
    -- rama demo/sprint6_finalpart). Confirmado vigente para Sprint 7 por
    -- David Medina (autor) el 2026-07-15 -- es independiente del rediseno
    -- de transferencias por calificacion, solo persiste el agente virtual.
    -- =====================================================================
    SET @process = 'Sprint6_finalPart - ALTER TABLE ccCallsIn ADD virtualAgentId'
    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''dbo.ccCallsIn'') AND name = ''virtualAgentId'')
    BEGIN
        ALTER TABLE dbo.ccCallsIn ADD virtualAgentId INT NULL
    END
    '
    exec (@sql)

    SET @process = 'Sprint6_finalPart - DROP ccsp_UpdateVirtualAgentId si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_UpdateVirtualAgentId'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_UpdateVirtualAgentId
    '
    exec (@sql)

    SET @process = 'Sprint6_finalPart - CREATE ccsp_UpdateVirtualAgentId'
    SET @sql = '
CREATE PROCEDURE dbo.ccsp_UpdateVirtualAgentId
    @callId INT,
    @virtualAgentId INT
AS
BEGIN
    UPDATE dbo.ccCallsIn SET virtualAgentId = @virtualAgentId WHERE cal_id = @callId
END
'
    exec (@sql)

    -- =====================================================================
    -- K070334 - Fix mapeo ORM card "Resultados de Marcacion" (Dashboard IA Entrada)
    -- BD: CCenterRIA
    -- Causa raiz: ccsp_GalateaAdminInbound @Option=1 (query "Inbound.GetInboundCallsState")
    -- devolvia columnas (Calls, Answer, Abandon, OverflowedCalls, NoAgentsCalls,
    -- InterruptedCalls) con nombres distintos a las propiedades de
    -- InboundCallsStateDashboardDto (TotalCalls, Attended, Abandoned, TotalOverflow,
    -- NoLoggedInAgents, ShortDialogs, Assigned). Database.SqlQuery<T> de Entity
    -- Framework mapea por nombre de columna, no por posicion -- al no coincidir,
    -- casi todas las propiedades del DTO quedaban en su valor default (0), aunque
    -- el SP devolviera datos reales. Solo OutOfServiceCalls/OutOfScheduleCalls
    -- coincidian por casualidad de nombre.
    -- Fix: se renombran los alias de columnas de la rama @Option=1 (unica
    -- consumida por el codigo C#, confirmado sin otras referencias en el repo)
    -- para que coincidan exactamente con las propiedades del DTO, y se agrega
    -- Assigned (status=11, mismo criterio que @Option=3). Las demas ramas
    -- (@Option=2..10) quedan sin cambios.
    -- =====================================================================
    SET @process = 'K070334 - DROP ccsp_GalateaAdminInbound si existe (fix de alias @Option=1 para mapeo ORM InboundCallsStateDashboardDto)
	y K070406 (se quito lo relacionado con *idForSuccessfulTransaction
*NonComprehensionId
y el @Option = 10 se modifico para que no tome en cuenta las columnas de asociación de transferencia solo tome en cuenta el callback )'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminInbound'')
    begin
            DROP PROCEDURE ccsp_GalateaAdminInbound;
    end'
    exec (@sql)

    SET @process = 'K070334 - CREATE ccsp_GalateaAdminInbound (alias @Option=1 corregidos: Calls->TotalCalls, Answer->Attended, Abandon->Abandoned, OverflowedCalls->TotalOverflow, NoAgentsCalls->NoLoggedInAgents, InterruptedCalls->ShortDialogs, agrega Assigned,
		y K070406 (se quito lo relacionado con 
		*idForSuccessfulTransaction
      *NonComprehensionId
		y el @Option = 10 se modifico para que no tome en cuenta las columnas de asociación de transferencia solo tome en cuenta el callback)'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT, 
                                            @InboundId AS SMALLINT = 0,
											@User_id AS SMALLINT = 0,
											@OutboundID AS SMALLINT = 0,
											@multi_cam as varchar(max) = null,
											@Module AS SMALLINT = 13,
											@Type AS SMALLINT = 0,
											@HistoryAction AS SMALLINT = 1,
											@AreaId AS SMALLINT = 0,
											@CallBackCampaignId AS SMALLINT = -1,
											@IsEditing AS BIT = 0
		AS
		BEGIN
			set nocount on;

			DECLARE @idArea SMALLINT = NULL;
			DECLARE @operation INT = -1;
			DECLARE @mediaType INT = 0;

			IF(@Option IN (5, 6)) BEGIN
				IF(@Module IS NOT NULL AND @Module <> 13) BEGIN
				
					IF(@Type = 0)BEGIN
						
						IF(@multi_cam is not null) BEGIN
							SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
						END ELSE BEGIN
							SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id = @InboundId)
						END

						SET @operation = CASE WHEN @HistoryAction = 1 THEN 
																			CASE 
																					WHEN @mediaType = 1  THEN 63
																					WHEN @mediaType = 5  THEN 40
																					ELSE 60 END
																	  ELSE 
																			CASE 
																					WHEN @mediaType = 1  THEN 64
																					WHEN @mediaType = 5  THEN 53
																					ELSE 52 END
																	  END;
					END ELSE BEGIN

						SET @mediaType = (SELECT [CampType] FROM ccCamps WHERE cam_id = @OutboundID)

						SET @operation = CASE WHEN @HistoryAction = 1 THEN 
																			CASE 
																					WHEN @mediaType = 6  THEN 44
																					WHEN @mediaType = 5  THEN 46
																					WHEN @mediaType = 9  THEN 48
																					WHEN @mediaType = 7  THEN 50
																					ELSE 42 END
																	   ELSE 
																			CASE 
																					WHEN @mediaType = 6  THEN 55
																					WHEN @mediaType = 5  THEN 56
																					WHEN @mediaType = 9  THEN 57
																					WHEN @mediaType = 7  THEN 58
																					ELSE 54 END
																	    END;
					END

				END ELSE BEGIN
					SET @operation = CASE WHEN @Option = 5 THEN 93 ELSE 94 END;
				END
			END

			if(@Option = 1) -- To campaign 
			begin
			    select 
            ISNULL(count (*), 0) as TotalCalls,
            ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Attended,
            ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandoned,
            ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as TotalOverflow,
			        ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
			        ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
            ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoLoggedInAgents, -- sin agentes firmados
            ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as ShortDialogs,
			        ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as Assigned,
			        ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
			        THEN 1 ELSE NULL END), 0) AS Other
			    from ccCallsIn a (nolock)
			    where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) and a.inbound_id = @InboundId

			end

			if(@Option = 2) -- All campaigns
			begin
			    select 
					inbound.Inbound_id as IDEspec,
					inbound.descripcion as Name,
			        ISNULL(count (*), 0) as Calls,
			        ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
			        ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
			        ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
			        ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
			        ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
			        ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
			        ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
			        ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
			        ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
			        THEN 1 ELSE NULL END), 0) AS Other
			    from ccCallsIn a (nolock)
				left join ccInbound inbound on a.inbound_id = inbound.Inbound_id
			    where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) 
				group by inbound.Inbound_id, inbound.descripcion
			end

			if(@Option = 3) -- Get All ACD call data, the data is showing in the administrator dashboard information
			begin
				SELECT 
					a.inbound_id, calls = ISNULL(COUNT(*), 0), -- calls
					Dialogs = ISNULL(COUNT (CASE WHEN statusCall_id = 13 THEN 1 ELSE NULL END), 0), -- Answered
					DlgsAveTime =CONVERT(int, ISNULL(SUM (CASE WHEN statusCall_id = 13 THEN cal_tDialog + cal_tNotas ELSE 0 END), 0)),
					QueueAveTime =ISNULL( avg( CASE WHEN cal_que > 0 THEN cal_tWait ELSE NULL END), 0) ,
					abandon = ISNULL(COUNT(CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0), -- Abandoned
					OverFlowQueue = ISNULL(COUNT (CASE WHEN statusCall_id =8 THEN 1 ELSE NULL END), 0),
					OverFlowTimeOut = ISNULL(COUNT (CASE WHEN statusCall_id =7 THEN 1 ELSE NULL END), 0), -- OverFlowQueue+OverFlowTimeOut = not answered
					outOfSchedule = ISNULL(COUNT (CASE WHEN statusCall_id =2 THEN 1 ELSE NULL END), 0), -- fuera de horario
					outOfService = ISNULL(COUNT (CASE WHEN statusCall_id =3 THEN 1 ELSE NULL END), 0), -- fuera de servicio
					noAgentsLoggedIn = ISNULL(COUNT (CASE WHEN statusCall_id =4 THEN 1 ELSE NULL END), 0), -- sin agentes firmados
					assigned = ISNULL(COUNT (CASE WHEN statusCall_id =11 THEN 1 ELSE NULL END), 0), -- asignada
					callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0)
				FROM ccCallsIn a (nolock)
				WHERE cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))
				GROUP BY a.inbound_id
			end

			if(@Option = 4) -- Load ACD of administrator that sent
			begin
				SELECT cam_id 
				FROM ccSupervisorCam  nolock
				WHERE user_id = @User_id and tipo = 0
				SET nocount off
				return(0)
			end

			IF(@Option = 5) -- Relate the inbound campaign with the outbound campaign
			BEGIN
				IF(@idArea IS NULL OR @idArea = -1) SET @idArea = 
					CASE WHEN @Type = 0 
						THEN 
							CASE WHEN @multi_cam IS NULL
								THEN (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @InboundID) 
								ELSE (SELECT [IDArea] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
								END
						ELSE (SELECT [IDArea] FROM ccCamps WHERE cam_id = @OutboundID)
						END

				IF(@multi_cam is not null)
				BEGIN
					UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id IN (
						SELECT value from dbo.fn_RIASplitDelimited(@multi_cam,'',''))

					IF (@multi_cam <> '''' )
					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
					SELECT
						(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
						getDate(), 
						(SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
						@operation,
						@Module,
						CASE WHEN @Module = 13 THEN '''' ELSE ''ASSOCIATED_CAMP_CALLBACK'' END,
						CASE WHEN @Type = 0 THEN
												(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @OutboundID)
											ELSE 
												(SELECT [descripcion] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
											END,
						CASE WHEN @Type = 0 THEN
												(SELECT [descripcion] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
											ELSE 
												(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @OutboundID)
											END

					SELECT 1;
					RETURN 1;
				END
				IF((SELECT ISNULL(cam_id,0) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId and chat in (0,11)) != 0 )
					BEGIN
						SELECT -1;
						RETURN -1;
					END;
				ELSE
					BEGIN
						UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id = @InboundID;
							
						IF(@Type <> 1 AND @InboundID <> 0)
						INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
						SELECT
							(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
							getDate(), 
							(SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
							@operation,
							@Module,
							CASE WHEN @Module = 13 THEN '''' ELSE ''ASSOCIATED_CAMP_CALLBACK'' END,
							(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [cam_id] FROM ccInbound WHERE Inbound_id = @InboundID)),
							(SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @InboundID)

						SELECT 1;
						RETURN 1;
					END;
			END;        
			IF(@Option = 6) -- Delete the relation between inbound and outbound campaigns
			BEGIN

			IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @InboundID)
							
				INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
				SELECT
					(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
					getDate(), 
					(SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
					@operation,
					@Module,
					CASE WHEN @Module = 13 THEN '''' ELSE ''DISASSOCIATED_CAMP_CALLBACK'' END,
					(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [cam_id] FROM ccInbound WHERE Inbound_id = @InboundID)),
					(SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @InboundID)

				UPDATE ccInbound SET cam_id = null WHERE Inbound_id = @InboundId;
				SELECT 1;
				RETURN 1;
			END;
			IF(@Option = 7) -- Check if the inbound Campaign is related
			BEGIN
				SELECT CAST(CASE WHEN cam_id IS NULL OR cam_id = 0 THEN -1 ELSE cam_id END AS INT) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId;
			END
			IF(@Option = 8) -- Delete the relation between inbound campaings which are related to outdbound campaign
			BEGIN
				UPDATE ccInbound SET cam_id = null WHERE cam_id = @OutboundID;
				SELECT 1;
				RETURN 1;
			END
			IF(@Option = 9)
			BEGIN
				
				SET @Module = 3 --Corresponds to "Area", reference in ccGalateaModules
				SET @operation = CASE @IsEditing WHEN 1 THEN 138 ELSE 137 END -- Corresponds to edition and creation, reference ccGalateaOperations

				DECLARE 
						@CurrentCallbackId SMALLINT, 
						@UserName VARCHAR(40),
						@AreaName VARCHAR(50),
						@CampaignName VARCHAR(40)

				SELECT @AreaName = AreaName  FROM ccRIACat_Areas WHERE IDArea = @AreaId
				SELECT @UserName = Login FROM ccUsers WHERE User_id = @User_id

				SELECT 
					@CurrentCallbackId = ISNULL( cam_id, -1 ),
					@CampaignName = descripcion
				FROM ccInbound WHERE Inbound_id = @InboundId

				IF @CurrentCallbackId <> @CallBackCampaignId AND @CallBackCampaignId <> -1
				BEGIN
					UPDATE ccInbound
					SET cam_id = @CallBackCampaignId
					WHERE Inbound_id = @InboundId

					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@AreaName, 
							GETDATE(), 
							@UserName, 
							@operation, 
							@Module, 
							''ASSOCIATED_CAMP_CALLBACK'', 
							CASE @CallBackCampaignId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT cam_descripcion FROM ccCamps WHERE cam_id = @CallBackCampaignId) END,
							@CampaignName)
				END

				SELECT 1
			END
			IF(@Option = 10) -- Get Dispositions Not Assigned To Inbound IA  Campaign
			BEGIN
				SELECT CAST(calif_id AS INT) AS calif_id  
					FROM cctipoCalif_IA MAIN
					WHERE MAIN.Cali_StatusIA = 1
					AND EXISTS (
						SELECT 1 
						FROM ccInbound I
						WHERE I.Inbound_id = @InboundId
						AND (
								-- Rescheduling / Callback Validation
								-- If rescheduling is required, it MUST have a cam_id.
							   (MAIN.CanReprogram = 1 OR MAIN.autoCallback = 1) 
							   AND 
							   (I.cam_id IS NULL OR I.cam_id = 0)
						)
					) 
			END
		END'
    exec (@sql)
		 -- =============================================================================
    -- Sprint 6 final part (Marco García) Carga de base de datos para campañas de salida
	-- validar el código postal cuando se realiza la carga si el check esta seleccionad
	-- deberia de validar el código postal que se ingrese en el dropdown
	-- de igual forma guardar los mensajes de validación cuando el código postal esta mal
	--estos cambios son para la HU KM28003 y KM28004
    -- =============================================================================
    SET @process = 'Sprint6_finalPart - DROP ccsp_UpdateCallsOutFromTempAction si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_UpdateCallsOutFromTempAction'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_UpdateCallsOutFromTempAction
    '
    exec (@sql)
	SET @process = 'Sprint6_finalPart - CREATE'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_UpdateCallsOutFromTempAction]
		@action INT,
		@tableName NVARCHAR(255),
		@cal_status int = 0,
		@idLoad int=0,
		@motivo varchar(50)=null,
		@cam_id int=null,
		@isIAQuantumCamp bit =0,
		@internationalRecords int=0,
		@isZipCodeValidation BIT = 0

	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @sql NVARCHAR(MAX);
		DECLARE @paramDef NVARCHAR(300);    
		DECLARE @count INT;
		declare @empty varchar(1)='''',@zipCodeSchedule bit = 0;
		declare @columnsIAQuntum varchar(max)='''' , @columnsZipCode varchar(max)='''', @valuesColumnsZipCode varchar(max)='''';  

		IF @action = 1
		BEGIN
			SET @sql = ''
			UPDATE '' + QUOTENAME(@tableName) + ''
			SET international = 1'';
		   
			EXEC sp_executesql @sql;
		END
		ELSE IF @action = 2
		BEGIN
				
			if @isIAQuantumCamp =1 begin
				set @columnsIAQuntum='', data_api_quantum, data_overflow_variables_quantum''
			END

			SET @sql = ''
			INSERT INTO dbo.ccoCallsOutSource (
				cal_Key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
				Dato1, Dato2, Dato3, Dato4, Dato5,
				dialPrefix, list_id, cam_id, Region, Localidad, cal_status, cal_fechaDial
				,iZonaHoraria,iZonaHoraria_verano
				,iZonaHoraria2,iZonaHoraria_verano2
				,iZonaHoraria3,iZonaHoraria_verano3
				,iZonaHoraria4,iZonaHoraria_verano4
				,iZonaHoraria5,iZonaHoraria_verano5
				'' + @columnsIAQuntum + ''
			)
			SELECT
				cal_Key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
				Dato1, Dato2, Dato3, Dato4, Dato5,
				dialPrefix, list_id, cam_id, Region, Localidad, cal_status, cal_fechaDial
				,iZonaHoraria,iZonaHoraria_verano
				,iZonaHoraria2,iZonaHoraria_verano2
				,iZonaHoraria3,iZonaHoraria_verano3
				,iZonaHoraria4,iZonaHoraria_verano4
				,iZonaHoraria5,iZonaHoraria_verano5
				'' + @columnsIAQuntum + ''
			FROM '' + QUOTENAME(@tableName) + ''
			WHERE callout_id = 0;'';

			IF (@isZipCodeValidation = 1)
			BEGIN
				SET @columnsZipCode = '', zipCode, isZipCodeValidation''
				SET @valuesColumnsZipCode = '', T.cal_zipCodeValidation, '' +CAST(@isZipCodeValidation AS VARCHAR(1));

				SET @sql += ''
				INSERT INTO dbo.ccoCallsOutSource_ZipCode (callout_id '' + @columnsZipCode  + '')
				SELECT 
					C.callout_id
					'' + @valuesColumnsZipCode  + ''
				FROM '' + QUOTENAME(@tableName) + '' AS T
				INNER JOIN dbo.ccoCallsOutSource AS C WITH (NOLOCK)
					ON T.cal_Key = C.cal_Key 
					AND T.cam_id = C.cam_id
				WHERE T.callout_id = 0 
				  AND T.cal_zipCodeValidation IS NOT NULL 
				  AND T.cal_zipCodeValidation <> '''''''';'';
			END

			EXEC sp_executesql @sql;
		END
		
		ELSE IF @action = 3
		BEGIN
			SET @sql = ''
			INSERT INTO dbo.ccoCallsPreviewData (
				cal_Key, cam_id, TotalData, Headers,
				Dato6, Dato7, Dato8, Dato9, Dato10,
				Dato11, Dato12, Dato13, Dato14, Dato15
			)
			SELECT 
				A.cal_Key, A.cam_id, A.TotalData, A.Headers,
				A.Dato6, A.Dato7, A.Dato8, A.Dato9, A.Dato10,
				A.Dato11, A.Dato12, A.Dato13, A.Dato14, A.Dato15
			FROM '' + QUOTENAME(@tableName) + '' A
			left join ccoCallsPreviewData B on A.cal_Key=B.cal_Key and A.cam_id=B.cam_id
			WHERE B.cam_id is null;
			'';
		
			EXEC sp_executesql @sql;
		END
		ELSE IF @action = 4
		BEGIN
			SET @sql = ''
			UPDATE C SET
				C.Headers = A.Headers,
				C.TotalData = A.TotalData,
				C.Dato6 = A.Dato6, C.Dato7 = A.Dato7, C.Dato8 = A.Dato8, C.Dato9 = A.Dato9, C.Dato10 = A.Dato10,
				C.Dato11 = A.Dato11, C.Dato12 = A.Dato12, C.Dato13 = A.Dato13, C.Dato14 = A.Dato14, C.Dato15 = A.Dato15
			FROM '' + QUOTENAME(@tableName) + '' A
			INNER JOIN dbo.ccoCallsPreviewData C WITH (ROWLOCK, UPDLOCK)
				ON A.cal_Key = C.cal_Key AND A.cam_id = C.cam_id;
			'';
		
			EXEC sp_executesql @sql;
		END
		ELSE IF @action =5
		BEGIN
			if @isIAQuantumCamp =1 begin
				set @columnsIAQuntum='', C.data_api_quantum = A.data_api_quantum, C.data_overflow_variables_quantum = A.data_overflow_variables_quantum''
			END

			SET @sql = ''
			UPDATE C SET
				C.cal_status = CASE WHEN B.callout_id IS NULL THEN @cal_status_param ELSE C.cal_status END,
				C.cal_telefono = A.cal_telefono,
				C.cal_telefono2 = A.cal_telefono2,
				C.cal_telefono3 = A.cal_telefono3,
				C.cal_telefono4 = A.cal_telefono4,
				C.cal_telefono5 = A.cal_telefono5,
				C.Dato1 = A.Dato1,
				C.Dato2 = A.Dato2,
				C.Dato3 = A.Dato3,
				C.Dato4 = A.Dato4,
				C.Dato5 = A.Dato5,
				C.dialPrefix = A.dialPrefix,
				C.list_id = A.list_id,
				C.cal_fechaDial = case when ISNULL(B.cal_status, 0) = 1 then C.cal_fechaDial else A.cal_fechaDial end,
				C.Region = A.Region,
				C.Localidad = A.Localidad,
				C.international = A.international,
				C.recycledByResult = @empty,
				C.recycledByDisposition = 0,
				C.recyclePhone = 0,
				C.recycleType = 1
				,C.iZonaHoraria=A.iZonaHoraria,C.iZonaHoraria_verano=A.iZonaHoraria_verano
				,C.iZonaHoraria2=A.iZonaHoraria2,C.iZonaHoraria_verano2=A.iZonaHoraria_verano2
				,C.iZonaHoraria3=A.iZonaHoraria3,C.iZonaHoraria_verano3=A.iZonaHoraria_verano3
				,C.iZonaHoraria4=A.iZonaHoraria4,C.iZonaHoraria_verano4=A.iZonaHoraria_verano4
				,C.iZonaHoraria5=A.iZonaHoraria5,C.iZonaHoraria_verano5=A.iZonaHoraria_verano5
				'' + @columnsIAQuntum + ''
			FROM '' + QUOTENAME(@tableName) + '' A
			LEFT JOIN dbo.ccoWorkingTable B WITH (ROWLOCK, UPDLOCK, READPAST) ON A.callout_id = B.callout_id AND B.cal_status <= 2
			INNER JOIN dbo.ccoCallsOutSource C WITH (ROWLOCK, UPDLOCK) ON A.callout_id = C.callout_id;'';

			IF (@isZipCodeValidation = 1)
			BEGIN
				SET @columnsZipCode = ''Z.zipCode = A.cal_zipCodeValidation, Z.isZipCodeValidation = '' + CAST(@isZipCodeValidation AS VARCHAR(1));

				SET @sql += ''
				UPDATE Z SET 
					'' + @columnsZipCode + ''
				FROM '' + QUOTENAME(@tableName) + '' A
				LEFT JOIN dbo.ccoWorkingTable B WITH (ROWLOCK, UPDLOCK, READPAST) ON A.callout_id = B.callout_id AND B.cal_status <= 2
				INNER JOIN dbo.ccoCallsOutSource_ZipCode Z WITH (ROWLOCK, UPDLOCK) ON A.callout_id = Z.callout_id;

				INSERT INTO dbo.ccoCallsOutSource_ZipCode (callout_id, zipCode, isZipCodeValidation)
				SELECT A.callout_id, A.cal_zipCodeValidation, 1
				FROM '' + QUOTENAME(@tableName) + '' A
				WHERE A.callout_id > 0 
				  AND A.cal_zipCodeValidation IS NOT NULL 
				  AND A.cal_zipCodeValidation <> ''''''''
				  AND NOT EXISTS (SELECT 1 FROM dbo.ccoCallsOutSource_ZipCode Z WHERE Z.callout_id = A.callout_id);'';
			END
			
			SET @paramDef = N''@cal_status_param TINYINT, @empty varchar(1)'';
			EXEC sp_executesql @sql, @paramDef, @cal_status_param = @cal_status, @empty= @empty;
		END
		ELSE IF @action = 6
		BEGIN
			DECLARE @today DATE = CONVERT(DATE, GETDATE());

			SET @sql = ''
		UPDATE B
		SET B.list_id = A.list_id
		FROM '' + QUOTENAME(@tableName) + '' A
		INNER JOIN ccoCallsOutSource C WITH (NOLOCK)  ON A.callout_id = C.callout_id
		INNER JOIN ccoWorkingTable B WITH (NOLOCK)    ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id
		WHERE B.list_id <> A.list_id;

		WHILE 1 = 1
		BEGIN
		    ;WITH cte AS
		    (
		        SELECT TOP (200) ld.logDial_id
		        FROM '' + QUOTENAME(@tableName) + '' t
		        LEFT JOIN ccoWorkingTable wt WITH (READPAST, UPDLOCK) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
		        INNER JOIN ccoLogDials ld WITH (UPDLOCK) ON ld.callout_id = t.callout_id
		        WHERE wt.callout_id IS NULL AND ld.fecha >= @today AND (ld.canBeRecycled = 1 OR ld.canBeRecycled IS NULL)
				ORDER BY ld.logDial_id
		    )
		    UPDATE ld
		    SET ld.canBeRecycled = 0
		    FROM ccoLogDials ld
		    INNER JOIN cte x
		        ON ld.logDial_id = x.logDial_id;

		    IF @@ROWCOUNT = 0 BREAK;

			WAITFOR DELAY ''''00:00:00.05'''';
		END


		WHILE 1 = 1
		BEGIN
		    ;WITH cte AS
		    (
		        SELECT TOP (200) co.cal_id
		        FROM '' + QUOTENAME(@tableName) + '' t
		        LEFT JOIN ccoWorkingTable wt WITH (READPAST, UPDLOCK) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
		        INNER JOIN ccoCallsOut co WITH (UPDLOCK) ON co.callout_id = t.callout_id
		        WHERE wt.callout_id IS NULL AND co.cal_Inicio >= @today AND (co.canBeRecycled = 1 OR co.canBeRecycled IS NULL)
				ORDER BY co.cal_id
		    )
		    UPDATE co
		    SET co.canBeRecycled = 0
		    FROM ccoCallsOut co
		    INNER JOIN cte x
		        ON co.cal_id = x.cal_id;

		    IF @@ROWCOUNT = 0 BREAK;

			WAITFOR DELAY ''''00:00:00.05'''';
		END

			'';
			--print(@sql)
    --EXEC sp_executesql @sql, N''@today DATE'', @today=@today;
		END
		ELSE IF @action = 7
		BEGIN       

			-- Contar registros inválidos
			SET @sql = ''
			SELECT @cnt = COUNT(*)
			FROM '' + QUOTENAME(@tableName) + '' A
			LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
				ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
			WHERE B.callout_id IS NULL and A.callout_id > 0;'';

			EXEC sp_executesql @sql, N''@cnt INT OUTPUT'', @cnt = @count OUTPUT;

			-- Insertar en ccRIALogPhones los registros sin match
			SET @sql = ''
			INSERT INTO ccRIALogPhones(load_id, cal_key, telefono, tipoMov, motivo,internationalRecords)
			SELECT @idLoad, A.cal_Key, @empty, 2, @motivo,@internationalRecords
			FROM '' + QUOTENAME(@tableName) + '' A
			LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
				ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
			WHERE B.callout_id IS NULL;'';

			EXEC sp_executesql @sql,
				N''@idLoad INT, @motivo NVARCHAR(200),@empty varchar(1),@internationalRecords int'',
				@idLoad = @idLoad,
				@motivo = @motivo,
				@internationalRecords =@internationalRecords,
				@empty=@empty;

			-- Eliminar los registros sin match
			SET @sql = ''
			DELETE A
			FROM '' + QUOTENAME(@tableName) + '' A
			LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
				ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
			WHERE B.callout_id IS NULL;'';

			EXEC(@sql);

			-- Retornar el count como resultado
			SELECT @count AS RegistrosEliminados;
		END
		ELSE IF @action = 8
		BEGIN
			

			-- Contar total de registros antes del borrado
			SET @sql = ''
			SELECT @cnt = COUNT(*) FROM '' + QUOTENAME(@tableName) + '';'';
		
			EXEC sp_executesql @sql, N''@cnt INT OUTPUT'', @cnt = @count OUTPUT;

			-- Log en ccRIALogPhones todos los registros de la tabla temporal
			SET @sql = ''
			INSERT INTO ccRIALogPhones(load_id, cal_key, telefono, tipoMov, motivo,internationalRecords)
			SELECT @idLoad, cal_Key, @empty, 6, @motivo,@internationalRecords FROM '' + QUOTENAME(@tableName) + '';'';

			EXEC sp_executesql @sql,
					N''@idLoad INT, @motivo NVARCHAR(200),@empty varchar(1),@internationalRecords int'',
				@idLoad = @idLoad,
				@motivo = @motivo,
				@internationalRecords =@internationalRecords,
				@empty=@empty;

			-- Eliminar todos los registros de la tabla temporal
			SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '';'';
			EXEC(@sql);

			-- Retornar el número de registros eliminados
			SELECT @count AS RegistrosEliminados;
		END
		ELSE IF @action = 9 BEGIN
			
			DECLARE @country TINYINT;
			DECLARE @zipLogic_Inv VARCHAR(100) = '''';
			DECLARE @zipLogic_Ver VARCHAR(100) = '''';
			DECLARE @zipJoin VARCHAR(MAX) = '''';
			DECLARE @zipRegion VARCHAR(MAX) = '''';

			SELECT @country = CONVERT(TINYINT, valor) FROM ccSettings WITH (NOLOCK) WHERE setting_id = 104;
			
			if @country =1 begin
				select @zipCodeSchedule=@isZipCodeValidation;
			end
			if @zipCodeSchedule is null begin
				set @zipCodeSchedule=0
			END
        
			IF @zipCodeSchedule = 1 
			BEGIN
				SET @zipLogic_Inv = ''WHEN @country=1 THEN ISNULL(Z.tz_id_invierno,0) '';
				SET @zipLogic_Ver = ''WHEN @country=1 THEN ISNULL(Z.tz_id_verano,0) '';
				SET @zipJoin = '' OUTER APPLY dbo.fnGetTimeZoneByZip(T.cal_zipCodeValidation) AS Z '';
				SET @zipRegion = '', Region = Z.State'';
			END

			SET @sql = ''
			UPDATE T SET 
				iZonaHoraria = CASE 
					WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @empty) THEN 0 
					'' + @zipLogic_Inv + '' 
					ELSE dbo.fnGetTimeZone(T.cal_telefono,  0) END,
	 
				iZonaHoraria_verano = CASE 
					WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @empty) THEN 0 
					 '' + @zipLogic_Ver + '' 
					 ELSE dbo.fnGetTimeZone(T.cal_telefono,  1) END,
	 
				iZonaHoraria2 = CASE 
					WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @empty) THEN 0 
					 '' + @zipLogic_Inv + ''             
					 ELSE dbo.fnGetTimeZone(T.cal_telefono2,  0) END,
	 
				iZonaHoraria_verano2 = CASE 
					WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @empty) THEN 0  
					 '' + @zipLogic_Ver + ''            
					 ELSE dbo.fnGetTimeZone(T.cal_telefono2,  1) END,

				iZonaHoraria3 = CASE 
					WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @empty) THEN 0 
					 '' + @zipLogic_Inv + ''            
					 ELSE dbo.fnGetTimeZone(T.cal_telefono3,  0) END,
	 
				iZonaHoraria_verano3 = CASE 
					WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @empty) THEN 0 
					 '' + @zipLogic_Ver + ''           
					 ELSE dbo.fnGetTimeZone(T.cal_telefono3,  1) END,

				iZonaHoraria4 = CASE 
					WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @empty) THEN 0 
					 '' + @zipLogic_Inv + ''             
					 ELSE dbo.fnGetTimeZone(T.cal_telefono4,  0) END,
	 
				iZonaHoraria_verano4 = CASE 
					WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @empty) THEN 0 
					 '' + @zipLogic_Ver + ''          
					 ELSE dbo.fnGetTimeZone(T.cal_telefono4,  1) END,

				iZonaHoraria5 = CASE 
					WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @empty) THEN 0 
					 '' + @zipLogic_Inv + ''              
					 ELSE dbo.fnGetTimeZone(T.cal_telefono5,  0) END,
	 
				iZonaHoraria_verano5 = CASE 
					WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @empty) THEN 0 
					 '' + @zipLogic_Ver + ''           
					 ELSE dbo.fnGetTimeZone(T.cal_telefono5,  1) END
					'' + @zipRegion + ''

			FROM '' + QUOTENAME(@tableName) + '' T '' + @zipJoin;
		
			EXEC sp_executesql @sql,
				N''@country TINYINT,@empty varchar(1)'',
				@country = @country,
				@empty = @empty

		END
		ELSE IF @action = 10
		BEGIN
			SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '' WHERE callout_id = 0;'';    
			EXEC sp_executesql @sql;
		END
		 ELSE IF @action = 11 BEGIN
					
			SET @sql = ''
		UPDATE T SET 
			international=@internationalRecords
		FROM '' + QUOTENAME(@tableName) + '' T
		''
		EXEC sp_executesql @sql,
				N''@internationalRecords int'',         
				@empty = @empty

		END
		ELSE
		BEGIN
			RAISERROR(''Acción inválida: %d. Use 1 = UpdateOutSource, 2 = UpdateLogDials, 3 = UpdateCallsOut, 4 = UpdateInternational'', 16, 1, @action);
			RETURN;
		END
	END'
	EXEC(@sql)

	 SET @process = 'Sprint6_finalPart - DROP ccsp_UpdateSmsOutFromTempAction si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_UpdateSmsOutFromTempAction'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_UpdateSmsOutFromTempAction
    '
    exec (@sql)
	SET @process = 'Sprint6_finalPart - CREATE'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_UpdateSmsOutFromTempAction]
    @action INT,
    @tableName NVARCHAR(255),
    @sms_status int = 0,
    @idLoad int=0,
    @motivo varchar(50)=null,   
    @DateStart varchar(50) = null,
    @DateEnd varchar(50) = null,
    @internationalRecords int=0,
	@isZipCodeValidation BIT = 0

AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @paramDef NVARCHAR(300);
    DECLARE @date datetime = getdate()  
    declare @empty varchar(1)='''',@zipCodeSchedule BIT = 0 ;
	DECLARE @columnsZipCode varchar(max)='''', @valuesColumnsZipCode varchar(max)='''';

    IF @action = 1
    BEGIN
        SET @sql = ''INSERT INTO dbo.smsOutSource(callkey,sms_phoneNumber,sms_phoneNumber2,sms_phoneNumber3,sms_phoneNumber4,sms_phoneNumber5,
        data1,data2,data3,data4,data5,list_id,cam_id,Region,Localidad,sms_status,sms_dateDial,
        iTimeZone,iTimeZone_summer,iTimeZone2,iTimeZone_summer2,iTimeZone3,iTimeZone_summer3,iTimeZone4,iTimeZone_summer4,iTimeZone5,iTimeZone_summer5)
        select cal_Key,cal_telefono,cal_telefono2,cal_telefono3,cal_telefono4,cal_telefono5
        ,Dato1,Dato2,Dato3,Dato4,Dato5,list_id,cam_id,Region,Localidad,cal_status,cal_fechaDial 
        ,iZonaHoraria,iZonaHoraria_verano
        ,iZonaHoraria2,iZonaHoraria_verano2
        ,iZonaHoraria3,iZonaHoraria_verano3
        ,iZonaHoraria4,iZonaHoraria_verano4
        ,iZonaHoraria5,iZonaHoraria_verano5
        from '' + QUOTENAME(@tableName) + '' where callout_id=0;'';

		IF (@isZipCodeValidation = 1)
		BEGIN
			SET @columnsZipCode = '', zipCode, isZipCodeValidation''
			SET @valuesColumnsZipCode = '', T.cal_zipCodeValidation, '' +CAST(@isZipCodeValidation AS VARCHAR(1));

			SET @sql += ''
			INSERT INTO dbo.smsOutSource_ZipCode (smsout_id '' + @columnsZipCode  + '')
			SELECT 
				C.smsout_id
				'' + @valuesColumnsZipCode  + ''
			FROM '' + QUOTENAME(@tableName) + '' AS T
			INNER JOIN dbo.smsOutSource AS C WITH (NOLOCK)
				ON T.cal_Key = C.callkey 
				AND T.cam_id = C.cam_id
			WHERE T.callout_id=0
				AND T.cal_zipCodeValidation IS NOT NULL 
				AND T.cal_zipCodeValidation <> '''''''';'';
		END
       
        EXEC sp_executesql @sql;
    END
    ELSE IF @action = 2
    BEGIN
        SET @sql = N''
UPDATE A
SET A.cal_fechaDial = CASE 
                         WHEN A.callout_id > 0 THEN B.sms_dateDial 
                         ELSE @date
                      END
FROM '' + QUOTENAME(@tableName) + '' AS A
INNER JOIN smsOutSource AS B WITH (NOLOCK)
    ON A.callout_id = B.smsout_id;
'';
        SET @paramDef =  N''@date DATETIME'';
        EXEC sp_executesql @sql,@paramDef , @date = @date;
    END
    
    ELSE IF @action = 3
    BEGIN
        SET @sql = ''update C set C.sms_status = @sms_status,
C.sms_phoneNumber = A.cal_telefono,C.sms_phoneNumber2 = A.cal_telefono2,C.sms_phoneNumber3 = A.cal_telefono3,C.sms_phoneNumber4 = A.cal_telefono4,
C.sms_phoneNumber5 = A.cal_telefono5,
C.data1 = A.Dato1,C.data2 = A.Dato2,C.data3 = A.Dato3,C.data4 = A.Dato4,C.data5 = A.Dato5,
C.list_id = A.list_id,
C.sms_dateDial =  ''''''+@DateStart+'''''', C.sms_dateDialEnd =  ''''''+@DateEnd+'''''',
C.Region = A.Region,
C.Localidad = A.Localidad,
C.isSegmentLoad = 1
,C.iTimeZone=A.iZonaHoraria,C.iTimeZone_summer=A.iZonaHoraria_verano
,C.iTimeZone2=A.iZonaHoraria2,C.iTimeZone_summer2=A.iZonaHoraria_verano2
,C.iTimeZone3=A.iZonaHoraria3,C.iTimeZone_summer3=A.iZonaHoraria_verano3
,C.iTimeZone4=A.iZonaHoraria4,C.iTimeZone_summer4=A.iZonaHoraria_verano4
,C.iTimeZone5=A.iZonaHoraria5,C.iTimeZone_summer5=A.iZonaHoraria_verano5
from '' + QUOTENAME(@tableName) + '' A 
left join dbo.smsWorkingTable  B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
inner join dbo.smsOutSource  C with(nolock) on A.callout_id=C.smsout_id
where B.smsout_id is null;'';
        
        SET @paramDef =   N''@sms_status int'';
        EXEC sp_executesql @sql,@paramDef ,@sms_status=@sms_status;
    END
    ELSE IF @action = 4
    BEGIN

        SET @sql = ''update C set C.sms_status = @sms_status,
		C.sms_phoneNumber = A.cal_telefono,C.sms_phoneNumber2 = A.cal_telefono2,C.sms_phoneNumber3 = A.cal_telefono3,C.sms_phoneNumber4 = A.cal_telefono4,
		C.sms_phoneNumber5 = A.cal_telefono5,
		C.data1 = A.Dato1,C.data2 = A.Dato2,C.data3 = A.Dato3,C.data4 = A.Dato4,C.data5 = A.Dato5,
		C.list_id = A.list_id,
		C.sms_dateDial =  A.cal_fechaDial,
		C.Region = A.Region,
		C.Localidad = A.Localidad
		,C.isSegmentLoad = 0
		from  '' + QUOTENAME(@tableName) + '' A 
		left join dbo.smsWorkingTable  B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
		inner join dbo.smsOutSource  C with(nolock) on A.callout_id=C.smsout_id
		where B.smsout_id is null;'';
		
		IF (@isZipCodeValidation = 1)
			BEGIN
				SET @columnsZipCode = ''Z.zipCode = '' + CASE WHEN @isZipCodeValidation = 1 THEN ''A.cal_zipCodeValidation'' ELSE ''@empty'' END + 
                        '', Z.isZipCodeValidation = '' + CAST(@isZipCodeValidation AS VARCHAR(1));

				SET @sql += ''
				UPDATE Z SET 
					'' + @columnsZipCode + ''
				FROM '' + QUOTENAME(@tableName) + '' A
				LEFT JOIN dbo.smsWorkingTable B WITH (ROWLOCK, UPDLOCK, READPAST) ON A.callout_id = B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
				INNER JOIN dbo.smsOutSource_ZipCode Z WITH (ROWLOCK, UPDLOCK) ON A.callout_id = Z.smsout_id
				WHERE B.smsout_id IS NULL;

				INSERT INTO dbo.smsOutSource_ZipCode (smsout_id, zipCode, isZipCodeValidation)
				SELECT A.callout_id, A.cal_zipCodeValidation, 1
				FROM '' + QUOTENAME(@tableName) + '' A
				WHERE A.callout_id > 0 
					AND A.cal_zipCodeValidation IS NOT NULL 
					AND A.cal_zipCodeValidation <> ''''''''
					AND NOT EXISTS (SELECT 1 FROM dbo.smsOutSource_ZipCode Z WHERE Z.smsout_id = A.callout_id);'';
			END
        
        SET @paramDef =   N''@sms_status int, @empty varchar(1)'';
        EXEC sp_executesql @sql,@paramDef ,@sms_status=@sms_status, @empty = @empty;     

    END
    ELSE IF @action =5
    BEGIN
        SET @sql = ''select count(*) from '' + QUOTENAME(@tableName) + '' A
left join smsWorkingTable B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
where B.smsout_id is null;'';
        
        EXEC sp_executesql @sql;
    END
    ELSE IF @action =6
    BEGIN
        SET @sql = ''Insert into ccRIALogPhones(load_id,cal_key,telefono,tipoMov,motivo,internationalRecords)
select @idLoad, A.cal_Key,@empty, 2, @motivo, @internationalRecords from '' + QUOTENAME(@tableName) + '' A
left join smsWorkingTable B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
where B.smsout_id is null;

delete A from '' + QUOTENAME(@tableName) + '' A
left join smsWorkingTable B with (nolock) on A.callout_id=B.smsout_id and A.cam_id=B.cam_id and B.sms_status <=2
where B.smsout_id is null;'';

        SET @paramDef = N''@empty varchar(1),@idLoad int,@motivo varchar(50),@internationalRecords int'';
        EXEC sp_executesql @sql, @paramDef, 
        @empty=@empty,
        @idLoad=@idLoad,
        @motivo=@motivo,
        @internationalRecords =@internationalRecords;
    END

    ELSE IF @action =7
    BEGIN
        SET @sql = ''select count(*) from '' + QUOTENAME(@tableName) + '';
Insert into ccRIALogPhones(load_id,cal_key,telefono,tipoMov,motivo)
select @idLoad, A.cal_Key,@empty, 2, @motivo from '' + QUOTENAME(@tableName) + '' A;
delete from '' + QUOTENAME(@tableName) + '';'';

        SET @paramDef = N''@empty varchar(1),@idLoad int,@motivo varchar(50)'';
        EXEC sp_executesql @sql, @paramDef, @empty = @empty,@idLoad=@idLoad,@motivo=@motivo;
    END
    ELSE IF @action = 8
    BEGIN
        SET @sql = ''select count(*) from '' + QUOTENAME(@tableName) + '' where callout_id=0;
delete from '' + QUOTENAME(@tableName) + '' where callout_id=0;'';

        EXEC sp_executesql @sql;
    END
    ELSE IF @action =9
    BEGIN
        SET @sql = ''Insert into ccRIALogPhones(load_id,cal_key,telefono,tipoMov,motivo,internationalRecords)
select @idLoad, A.cal_Key,@empty, 6, @motivo, @internationalRecords from '' + QUOTENAME(@tableName) + '' A;
delete from '' + QUOTENAME(@tableName) + '';'';

        SET @paramDef = N''@empty varchar(1),@idLoad int,@motivo varchar(50), @internationalRecords int'';
        EXEC sp_executesql @sql, @paramDef, 
        @empty=@empty,
        @idLoad=@idLoad,
        @motivo=@motivo,
        @internationalRecords =@internationalRecords;       
    END 
    ELSE IF @action = 10
    BEGIN
        SET @sql = ''select count(*) from '' + QUOTENAME(@tableName) + '';'';
        EXEC sp_executesql @sql
    END
    ELSE IF @action = 11 BEGIN

		DECLARE @country TINYINT;
		DECLARE @zipLogic_Inv VARCHAR(100) = '''';
		DECLARE @zipLogic_Ver VARCHAR(100) = '''';
		DECLARE @zipJoin VARCHAR(MAX) = '''';
		DECLARE @zipRegion VARCHAR(MAX) = '''';

		SELECT @country = CONVERT(TINYINT, valor) FROM ccSettings WITH (NOLOCK) WHERE setting_id = 104;
		IF @country =1 begin
				select @zipCodeSchedule=@isZipCodeValidation;
		END
        
		if @zipCodeSchedule is null begin
			set @zipCodeSchedule=0
		END
        
		IF @zipCodeSchedule = 1 
		BEGIN
			SET @zipLogic_Inv = ''WHEN @country=1 THEN ISNULL(Z.tz_id_invierno,0) '';
			SET @zipLogic_Ver = ''WHEN @country=1 THEN ISNULL(Z.tz_id_verano,0) '';
			SET @zipJoin = '' OUTER APPLY dbo.fnGetTimeZoneByZip(T.cal_zipCodeValidation) AS Z '';
			SET @zipRegion = '', Region = Z.State'';
		END
                
        SET @sql = ''
		UPDATE T SET 
			iZonaHoraria = CASE 
				WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @empty) THEN 0   
				 '' + @zipLogic_Inv + '' 
				  ELSE dbo.fnGetTimeZone(T.cal_telefono,  0) END,
 
			iZonaHoraria_verano = CASE 
			  WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @empty) THEN 0  
			   '' + @zipLogic_Ver + ''   
				 ELSE dbo.fnGetTimeZone(T.cal_telefono,  1) END,
 
			iZonaHoraria2 = CASE 
				WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @empty) THEN 0 
				 '' + @zipLogic_Inv + '' 
				  ELSE dbo.fnGetTimeZone(T.cal_telefono2,  0) END,
 
			iZonaHoraria_verano2 = CASE 
			  WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @empty) THEN 0               
			   '' + @zipLogic_Ver + ''   
				 ELSE dbo.fnGetTimeZone(T.cal_telefono2,  1) END,

			iZonaHoraria3 = CASE 
				WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @empty) THEN 0
				 '' + @zipLogic_Inv + '' 
				 ELSE dbo.fnGetTimeZone(T.cal_telefono3,  0) END,
 
			iZonaHoraria_verano3 = CASE 
			  WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @empty) THEN 0  
			   '' + @zipLogic_Ver + ''   
				 ELSE dbo.fnGetTimeZone(T.cal_telefono3,  1) END,

			iZonaHoraria4 = CASE 
				WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @empty) THEN 0  
				 '' + @zipLogic_Inv + '' 
				 ELSE dbo.fnGetTimeZone(T.cal_telefono4,  0) END,
 
			iZonaHoraria_verano4 = CASE 
			  WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @empty) THEN 0 
			   '' + @zipLogic_Ver + ''   
				ELSE dbo.fnGetTimeZone(T.cal_telefono4,  1) END,

			iZonaHoraria5 = CASE 
				WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @empty) THEN 0 
				 '' + @zipLogic_Inv + '' 
				 ELSE dbo.fnGetTimeZone(T.cal_telefono5,  0) END,
 
			iZonaHoraria_verano5 = CASE 
			   WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @empty) THEN 0 
			    '' + @zipLogic_Ver + ''         
				 ELSE dbo.fnGetTimeZone(T.cal_telefono5,  1) END
			'' + @zipRegion + ''

		FROM '' + QUOTENAME(@tableName) + '' T '' + @zipJoin;

		EXEC sp_executesql @sql,
				N''@country TINYINT,@empty varchar(1)'', 
				@country = @country,
				@empty = @empty

    END
    ELSE
    BEGIN
        RAISERROR(''Acción inválida: %d. Use 1 = UpdateOutSource, 2 = UpdateLogDials, 3 = UpdateCallsOut, 4 = UpdateInternational'', 16, 1, @action);
        RETURN;
    END
END'
	EXEC(@sql)

	 SET @process = 'Sprint6_finalPart - DROP ccsp_UpdateWhatsAppOutFromTempAction si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_UpdateWhatsAppOutFromTempAction'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_UpdateWhatsAppOutFromTempAction
    '
    exec (@sql)
	SET @process = 'Sprint6_finalPart - CREATE'
	SET @sql = 'CREATE PROCEDURE ccsp_UpdateWhatsAppOutFromTempAction 
    @action INT,
    @tableName NVARCHAR(255),
    @isZipCodeValidation BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX);
	DECLARE @paramDef NVARCHAR(300);
	DECLARE @empty varchar(1)='''',@zipCodeSchedule BIT;
	declare @columnsZipCode varchar(max)='''', @valuesColumnsZipCode varchar(max)='''';  


	IF @action = 1 -- insert into ccWhatsAppOutSource from tableTmp
	BEGIN
		SET @sql = ''INSERT INTO dbo.ccWhatsAppOutSource(
		CallKey, camId, PhoneNumber, Status, TimeZone, TimeZone_Summer,
		List_id, User_id, TemplateId, componentJson, Data1,
		Data2, Data3, Data4, Data5, dateDial, MessageContent
		)
		SELECT CallKey, camId, PhoneNumber, Status, 
		TimeZone, TimeZone_Summer, List_id, 
		User_id, TemplateId, componentJson,
		Data1, Data2, Data3, 
		Data4, Data5, dateDial, 
		MessageContent 
		FROM '' + QUOTENAME(@tableName) + '' 
		where IsUpdated=0 AND IsReadyToDelete=0;''


		IF (@isZipCodeValidation = 1)
		BEGIN
			SET @columnsZipCode = '', zipCode, isZipCodeValidation''
			SET @valuesColumnsZipCode = '', T.cal_zipCodeValidation, '' +CAST(@isZipCodeValidation AS VARCHAR(1));

			SET @sql += ''
			INSERT INTO dbo.ccWhatsAppOutSource_ZipCode (WAOut_Id '' + @columnsZipCode  + '')
			SELECT 
				C.WAOut_Id
				'' + @valuesColumnsZipCode  + ''
			FROM '' + QUOTENAME(@tableName) + '' AS T
			INNER JOIN dbo.ccWhatsAppOutSource AS C WITH (NOLOCK)
				ON T.CallKey = C.CallKey 
				AND T.camId = C.camId
			WHERE T.IsUpdated = 0 AND T.IsReadyToDelete = 0
				AND T.cal_zipCodeValidation IS NOT NULL 
				AND T.cal_zipCodeValidation <> '''''''';'';
		END

		SET @sql += ''UPDATE '' + QUOTENAME(@tableName) + '' SET IsReadyToDelete = 1 WHERE IsUpdated = 0 AND IsReadyToDelete = 0;'';

		EXEC sp_executesql @sql;
	END
	ELSE IF @action = 2 -- update info in ccWhatsAppOutSource from tableTmp
	BEGIN


		SET @sql = ''UPDATE cwaos
            SET
                PhoneNumber = A.PhoneNumber,
                Data1 = A.Data1,
                Data2 = A.Data2,
                Data3 = A.Data3,
                Data4 = A.Data4,
                Data5 = A.Data5,
                componentJson = A.componentJson,
                MessageContent = A.MessageContent,
                TemplateId = A.TemplateId,
                dateDial = CASE WHEN ISNULL(cwwt.WaStatus, 0) = 0 THEN  A.dateDial ELSE cwaos.dateDial END,
				Status = CASE WHEN cwwt.WAOut_id IS NULL THEN 0 ELSE cwaos.Status END
            FROM '' + QUOTENAME(@tableName) + ''  as A
            inner join dbo.ccWhatsAppOutSource AS cwaos with(nolock) on A.WAOut_id = cwaos.WAOut_id
            left join dbo.ccoWAWorkingTable AS cwwt with(nolock) ON A.WAOut_id = cwwt.WAOut_id
            WHERE (cwwt.WAOut_id is null OR cwwt.WaStatus = 0)  and A.IsUpdated = 1 AND A.IsReadyToDelete = 0;'';


			IF (@isZipCodeValidation = 1)
			BEGIN
				SET @columnsZipCode = ''Z.zipCode = '' + CASE WHEN @isZipCodeValidation = 1 THEN ''A.cal_zipCodeValidation'' ELSE ''@empty'' END + 
                        '', Z.isZipCodeValidation = '' + CAST(@isZipCodeValidation AS VARCHAR(1));

				SET @sql += ''
				UPDATE Z SET 
					'' + @columnsZipCode + ''
				FROM '' + QUOTENAME(@tableName) + '' A
				LEFT JOIN dbo.ccoWAWorkingTable B WITH (ROWLOCK, UPDLOCK, READPAST) ON A.WAOut_id = B.WAOut_id
				INNER JOIN dbo.ccWhatsAppOutSource_ZipCode Z WITH (ROWLOCK, UPDLOCK) ON A.WAOut_id = Z.WAOut_id
				WHERE (B.WAOut_id is null OR B.WaStatus = 0)  and A.IsUpdated = 1 AND A.IsReadyToDelete = 0;

				INSERT INTO dbo.ccWhatsAppOutSource_ZipCode (WAOut_id, zipCode, isZipCodeValidation)
				SELECT A.WAOut_id, A.cal_zipCodeValidation, 1
				FROM '' + QUOTENAME(@tableName) + '' A
				inner join dbo.ccWhatsAppOutSource AS cwaos with(nolock) on A.WAOut_id = cwaos.WAOut_id
				LEFT JOIN dbo.ccoWAWorkingTable B WITH (NOLOCK) ON A.WAOut_id = B.WAOut_id
				WHERE A.WAOut_id > 0 
					AND A.IsUpdated = 1 AND A.IsReadyToDelete = 0
					AND (B.WAOut_id IS NULL OR B.WaStatus = 0)
					AND A.cal_zipCodeValidation IS NOT NULL 
					AND A.cal_zipCodeValidation <> ''''''''
					AND NOT EXISTS (SELECT 1 FROM dbo.ccWhatsAppOutSource_ZipCode Z WHERE Z.WAOut_id = A.WAOut_id);'';
			END

			SET @sql += ''UPDATE '' + QUOTENAME(@tableName) + '' SET IsReadyToDelete = 1 WHERE IsUpdated = 1 AND IsReadyToDelete = 0;'';
			

		EXEC sp_executesql @sql,
			N''@empty varchar(1)'',
			@empty = @empty;
	END
    ELSE IF @action = 3 -- update phone number in workingtable if it is exist and WaStatus is Zero, not load by outbound whatsapp
	BEGIN
		SET @sql = ''UPDATE cwwt
            SET
                cwwt.PhoneNumber = A.phoneNumber,
				cwwt.dateDial = cwaos.dateDial
          FROM '' + QUOTENAME(@tableName) + '' as A inner join dbo.ccoWAWorkingTable AS cwwt with(nolock) ON A.WAOut_Id = cwwt.WAOut_Id
            inner join dbo.ccWhatsAppOutSource AS cwaos with(nolock) on A.WAOut_Id = cwaos.WAOut_Id
            WHERE A.IsUpdated = 1 and cwwt.WaStatus = 0;''

			EXEC sys.sp_executesql @sql;
	END
	ELSE IF @action = 4 -- update time zone
	BEGIN
		DECLARE @country TINYINT;
		DECLARE @zipLogic_Inv VARCHAR(100) = '''';
		DECLARE @zipLogic_Ver VARCHAR(100) = '''';
		DECLARE @zipJoin VARCHAR(MAX) = '''';

		SELECT @country = CONVERT(TINYINT, valor) FROM ccSettings WITH (NOLOCK) WHERE setting_id = 104;
		IF @country = 1
		BEGIN
			select @zipCodeSchedule=@isZipCodeValidation;
		END
		  
		if @zipCodeSchedule is null begin
			set @zipCodeSchedule=0
		END

		IF @zipCodeSchedule = 1 
		BEGIN
			SET @zipLogic_Inv = ''WHEN @country=1 THEN ISNULL(Z.tz_id_invierno,0) '';
			SET @zipLogic_Ver = ''WHEN @country=1 THEN ISNULL(Z.tz_id_verano,0) '';
			SET @zipJoin = '' OUTER APPLY dbo.fnGetTimeZoneByZip(T.cal_zipCodeValidation) AS Z '';
		END
        
		SET @sql = ''
		UPDATE T SET 
			TimeZone = CASE 
				WHEN (PhoneNumber IS NULL OR LTRIM(RTRIM(PhoneNumber)) = @empty) THEN 0   
				 '' + @zipLogic_Inv + '' 
				  ELSE dbo.fnGetTimeZone(T.PhoneNumber,  0) END,
			TimeZone_Summer = CASE 
				WHEN (PhoneNumber IS NULL OR LTRIM(RTRIM(PhoneNumber)) = @empty) THEN 0  
				 '' + @zipLogic_Ver + ''   
				  ELSE dbo.fnGetTimeZone(T.PhoneNumber,  1) END
		FROM '' + QUOTENAME(@tableName) + '' T '' + @zipJoin;

		EXEC sp_executesql @sql,
		N''@country TINYINT,@empty varchar(1)'',
			@country = @country,
			@empty = @empty;
	END
	ELSE IF @action = 5 --- delete table temp registries
	BEGIN
	 SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '' WHERE IsReadyToDelete = 1;'';    
			EXEC sp_executesql @sql;
	END
END;'
	EXEC(@sql)

	 SET @process = 'Sprint6_finalPart - DROP ccsp_RIAOUTInsertNewJOBS_WT_Camp si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_RIAOUTInsertNewJOBS_WT_Camp'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_RIAOUTInsertNewJOBS_WT_Camp
    '
    exec (@sql)
	SET @process = 'Sprint6_finalPart - CREATE'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000   
AS
SET NOCOUNT ON
SET XACT_ABORT ON

DECLARE @HadError BIT = 0
DECLARE @ErrMsg NVARCHAR(4000) = NULL
DECLARE @ErrSeverity INT = 16
DECLARE @ErrState INT = 1

DECLARE @prioridad VARCHAR(8)
DECLARE @batchsizeIni AS INT
DECLARE @batchsizeFin AS INT
DECLARE @rango AS DECIMAL
DECLARE @rowstoInsert AS INT
DECLARE @campType AS INT
DECLARE @recordsQuantitySetting VARCHAR(8)
DECLARE @settingValueP1 VARCHAR(25)
DECLARE @InsertedRows INT = 0;

SET @rowstoInsert = 0
SET @batchsizeIni = 0
SET @batchsizeFin = 0
SET @rango = 0.00

IF EXISTS(SELECT * FROM sys.views WHERE NAME = ''VIEW_SETTINGS'') BEGIN
    SELECT @recordsQuantitySetting = [valor] FROM VIEW_SETTINGS WHERE setting_id = 257;
    IF(@recordsQuantitySetting IS NOT NULL AND @recordsQuantitySetting <> '''') BEGIN
        SELECT @settingValueP1 = SUBSTRING(@recordsQuantitySetting, CHARINDEX(''|'', @recordsQuantitySetting)+1, LEN(@recordsQuantitySetting)),
                @top = (SUBSTRING(@settingValueP1, 1, CHARINDEX(''|'', @settingValueP1)-1));
    END ELSE SET @top = 3000
END ELSE SET @top = 3000

SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
FROM ccCampsPrioridadTel WITH (NOLOCK)
WHERE cam_id = @camp_id

SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id = @camp_id;

DELETE ccUploadTemporal
WHERE cam_id = @camp_id

IF(@campType = 7)
BEGIN
        CREATE TABLE #tempsmsOutSource (Id INT PRIMARY KEY identity, smsout_id INT, cam_id INT, sms_phoneNumber VARCHAR(19), sms_status TINYINT, sms_dateDial DATETIME, cal_keyw VARCHAR(40), iTimeZone INT, iTimeZone_summer INT, iTimeZone2 INT, iTimeZone_summer2 INT, iTimeZone3 INT, iTimeZone_summer3 INT, iTimeZone4 INT, iTimeZone_summer4 INT, iTimeZone5 INT, iTimeZone_summer5 INT, list_id INT, sms_dateDialEnd datetime, isSegmentLoad bit)

        CREATE NONCLUSTERED INDEX [IX_TempSMSO] ON [dbo].[#tempsmsOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

        CREATE TABLE #smsoutIdSource (smsout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #smsoutIdSource2 (smsout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #claimSmsIds (smsout_id INT NOT NULL PRIMARY KEY, old_sms_status TINYINT)

        --UPDATING TABLES BEFORE LOADING
        DECLARE @date datetime = GETDATE()
        UPDATE smsOutSource SET sms_status = 2 where sms_dateDialEnd < @date and isSegmentLoad = 1
        UPDATE smsWorkingTable SET sms_status = 2 where sms_dateDialEnd < @date and isSegmentLoad = 1

        INSERT INTO #smsoutIdSource
        SELECT top(@top) sos.smsout_id
        FROM dbo.smsOutSource AS sos  WITH (INDEX (IX_smsOutSource_2), NOLOCK)
        inner join dbo.smsWorkingTable AS swt WITH (INDEX (IX_smsWorkingTable_2), NOLOCK) 
        on sos.callkey = swt.cal_keyw AND sos.cam_id = swt.cam_id 
        WHERE sos.cam_id = @camp_id and sos.sms_status IN (0, 7) AND swt.sms_status <= 2

        UNION

        SELECT top(@top) swt2.smsout_id
        FROM dbo.smsOutSource AS sos2 WITH (INDEX (IX_smsOutSource_2), NOLOCK)
        inner join dbo.smsWorkingTable AS swt2 (NOLOCK)on sos2.smsout_id = swt2.smsout_id 
        WHERE sos2.cam_id = @camp_id AND (sos2.sms_status < 2 OR sos2.sms_status = 7)

        INSERT INTO #smsoutIdSource2
        SELECT top(@top) sos.smsout_id
        FROM dbo.smsOutSource AS sos WITH (INDEX (IX_smsOutSource_1), NOLOCK)
        WHERE sos.sms_status IN (0, 1, 7) AND cam_id = @camp_id

        BEGIN TRY
        BEGIN TRAN

        INSERT INTO #claimSmsIds(smsout_id, old_sms_status)
        SELECT smsout_id, old_sms_status
        FROM (
            UPDATE TOP(@top) sos WITH (UPDLOCK, READPAST, ROWLOCK)
            SET sms_status = 4
            OUTPUT inserted.smsout_id, deleted.sms_status
            FROM dbo.smsOutSource AS sos
            WHERE sos.cam_id = @camp_id AND (sos.sms_status < 2 OR sos.sms_status = 7)
        ) AS X(smsout_id, old_sms_status);


        INSERT #tempsmsOutSource(smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, cal_keyw, iTimeZone, 
        iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4,
            iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
        SELECT TOP(@top) sos.smsout_id, sos.cam_id, RTRIM(LEFT(LTRIM(sos.sms_phoneNumber + ''        '' + sos.sms_phoneNumber2 + ''         '' 
        + sos.sms_phoneNumber3 + ''         '' + sos.sms_phoneNumber4 + ''         '' + sos.sms_phoneNumber5 + ''         ''), 13)) AS sms_phoneNumber,
            CASE c.old_sms_status WHEN 7 THEN 1 ELSE c.old_sms_status END sms_status, sos.sms_dateDial, sos.callkey, 
            CASE WHEN LEN(sos.sms_phoneNumber) > 0 THEN sos.iTimeZone ELSE NULL END iTimeZone,
            CASE WHEN LEN(sos.sms_phoneNumber) > 0 THEN sos.iTimeZone_summer ELSE NULL END iTimeZone_summer, 
            CASE WHEN LEN(sos.sms_phoneNumber2) > 0 THEN sos.iTimeZone2 ELSE NULL END iTimeZone2,
            CASE WHEN LEN(sos.sms_phoneNumber2) > 0 THEN sos.iTimeZone_summer2 ELSE NULL END iTimeZone_summer2, 
            CASE WHEN LEN(sos.sms_phoneNumber3) > 0 THEN sos.iTimeZone3 ELSE NULL END iTimeZone3, 
            CASE WHEN LEN(sos.sms_phoneNumber3) > 0 THEN sos.iTimeZone_summer3 ELSE NULL END iTimeZone_summer3,
            CASE WHEN LEN(sos.sms_phoneNumber4) > 0 THEN sos.iTimeZone4 ELSE NULL END iTimeZone4, 
            CASE WHEN LEN(sos.sms_phoneNumber4) > 0 THEN sos.iTimeZone_summer4 ELSE NULL END iTimeZone_summer4, 
            CASE WHEN LEN(sos.sms_phoneNumber5) > 0 THEN sos.iTimeZone5 ELSE NULL END iTimeZone5, 
            CASE WHEN LEN(sos.sms_phoneNumber5) > 0 THEN sos.iTimeZone_summer5 ELSE 
                    NULL END iTimeZone_summer5, sos.list_id, sos.sms_dateDialEnd, ISNULL(sos.isSegmentLoad, 0)
        FROM dbo.smsOutSource AS sos
        INNER JOIN #claimSmsIds c ON c.smsout_id = sos.smsout_id
        WHERE sos.cam_id = @camp_id

        SELECT @rowstoInsert = COUNT(*) FROM #tempsmsOutSource AS tos;

        IF EXISTS(SELECT * FROM #tempsmsOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempsmsOutSource  WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
             -- Nuevos Jobs
               INSERT INTO dbo.smsWorkingTable  WITH (ROWLOCK)
                (smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, attemps, user_id,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
                SELECT t.smsout_id, t.cam_id, t.sms_phoneNumber, t.sms_status, t.sms_dateDial, 0, 0 
                ,t.cal_keyw, t.iTimeZone, t.iTimeZone_summer, t.iTimeZone2, t.iTimeZone_summer2, t.iTimeZone3, t.iTimeZone_summer3
                , t.iTimeZone4, t.iTimeZone_summer4, t.iTimeZone5, t.iTimeZone_summer5, t.list_id,t.sms_dateDialEnd, t.isSegmentLoad
                FROM #tempsmsOutSource t
                WHERE id > @batchsizeIni AND id <= @batchsizeFin
                AND NOT EXISTS (
                    SELECT 1 FROM smsWorkingTable swt WITH (UPDLOCK, HOLDLOCK) WHERE swt.smsout_id = t.smsout_id
                )
                SET @InsertedRows += @@ROWCOUNT;
                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE dbo.smsOutSource
            SET sms_status = 2
            FROM dbo.smsOutSource AS sos
            INNER JOIN #claimSmsIds c ON sos.smsout_id = c.smsout_id
        END

        COMMIT
        END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
END CATCH

        DROP TABLE #claimSmsIds
        DROP TABLE #smsoutIdSource
        DROP TABLE #smsoutIdSource2
        DROP TABLE #tempsmsOutSource
END
ELSE IF(@campType = 5)
BEGIN
    CREATE TABLE #tempWhatsAppOutSource (Id INT PRIMARY KEY identity, WAOut_Id INT, CallKey VARCHAR(40), camId INT, PhoneNumber VARCHAR(30), Status INT, TimeZone int, TimeZone_Summer int, List_id INT, User_id SMALLINT, dateDial DATETIME)
    CREATE NONCLUSTERED INDEX [IX_TempWAO] ON [dbo].[#tempWhatsAppOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

    CREATE TABLE #WAIdSource (WAOut_Id INT NOT NULL PRIMARY KEY)

    CREATE TABLE #claimWAIds (WAOut_Id INT NOT NULL PRIMARY KEY, old_Status INT)

    INSERT INTO #WAIdSource
    SELECT top(@top) cwaos.WAOut_Id
        FROM dbo.ccWhatsAppOutSource AS cwaos WITH (INDEX (IX_WASource_1), NOLOCK)
        WHERE cwaos.Status IN (0) AND cwaos.camId = @camp_id

    BEGIN TRY
    BEGIN TRAN

    INSERT INTO #claimWAIds(WAOut_Id, old_Status)
    SELECT WAOut_Id, old_Status
    FROM (
        UPDATE TOP(@top) cwaos WITH (UPDLOCK, READPAST, ROWLOCK)
        SET Status = 4
        OUTPUT inserted.WAOut_Id, deleted.Status
        FROM dbo.ccWhatsAppOutSource AS cwaos
        WHERE cwaos.camId = @camp_id AND cwaos.Status = 0
    ) AS X(WAOut_Id, old_Status);

    INSERT INTO #tempWhatsAppOutSource
    (
        WAOut_Id,
        CallKey,
        camId,
        PhoneNumber,
        Status,
        TimeZone,
        TimeZone_Summer,
        List_id,
        User_id,
        dateDial
    )
        SELECT TOP(@top) cwaos.WAOut_Id, cwaos.CallKey,cwaos.camId, RTRIM(LEFT(LTRIM(cwaos.PhoneNumber + ''        '' ), 13)) AS phoneNumber,
            c.old_Status AS WAStatus,
            CASE WHEN LEN(cwaos.PhoneNumber) > 0 THEN cwaos.TimeZone  ELSE NULL END,
            CASE WHEN LEN(cwaos.PhoneNumber) > 0 THEN  cwaos.TimeZone_Summer ELSE NULL END, 
            list_id, cwaos.User_id, cwaos.dateDial
        FROM dbo.ccWhatsAppOutSource AS cwaos
        INNER JOIN #claimWAIds c ON c.WAOut_Id = cwaos.WAOut_Id
        WHERE cwaos.camId = @camp_id

    SELECT @rowstoInsert = COUNT(*) FROM #tempWhatsAppOutSource AS tos;

        IF EXISTS(SELECT * FROM #tempWhatsAppOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempWhatsAppOutSource  WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango
                
            WHILE 1 = 1
            BEGIN
                INSERT INTO dbo.ccoWAWorkingTable(WAOut_id, PhoneNumber, Callkey, CamId, WaStatus, dateDial, UserId,TimeZone, TimeZone_Summer)
                SELECT WAOut_Id, PhoneNumber, CallKey, camId, Status, dateDial , User_id, TimeZone ,TimeZone_Summer
                FROM #tempWhatsAppOutSource 
                WHERE id > @batchsizeIni AND id <= @batchsizeFin
                SET @InsertedRows += @@ROWCOUNT;

                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE dbo.ccWhatsAppOutSource
            SET 
            Status = 2,
            TimeZone = cis3.TimeZone,
            TimeZone_Summer = cis3.TimeZone_Summer
            FROM dbo.ccWhatsAppOutSource AS cwaos
            INNER JOIN #tempWhatsAppOutSource  cis3 ON cwaos.WAOut_Id = cis3.WAOut_Id
        END

    COMMIT
    END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;

    RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
END CATCH

        DROP TABLE #claimWAIds
        DROP TABLE #WAIdSource
        DROP TABLE #tempWhatsAppOutSource
END
ELSE
BEGIN
        CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19), 
        cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(40), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT, 
        iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT, 
        iZonaHoraria_verano5 INT, list_id INT, new_status int)

        CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

        CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #claimCallIds (callout_id INT NOT NULL PRIMARY KEY, old_cal_status TINYINT)

        INSERT INTO #calloutIdSource
        SELECT top(@top) cs.callout_id
        FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
        inner join ccoWorkingTable wt WITH (INDEX (PK_ccoWorkingTable), NOLOCK) 
        on cs.callout_id = wt.callout_id AND cs.cam_id = wt.cam_id 
        WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

        UNION

        SELECT top(@top) Cout.callout_id
        FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK)
        inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id 
        AND cout.cam_id = Wtab.cam_id
        WHERE Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)
    

        INSERT INTO #calloutIdSource2
        SELECT top(@top) callout_id
        FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_11), NOLOCK)
        WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

        IF exists(SELECT * FROM #calloutIdSource) 
        BEGIN
            UPDATE ccoCallBacks
            SET [status] = 6, schedulerStatus = 1
            WHERE callout_id IN (
                    SELECT callout_id
                    FROM #calloutIdSource cis
                    )

            UPDATE ccoCallsOutSource
            SET cal_Status = 4
            WHERE callout_id IN (
                    SELECT callout_id
                    FROM #calloutIdSource cis
                    )
        END

        BEGIN TRY
        BEGIN TRAN

        INSERT INTO #claimCallIds(callout_id, old_cal_status)
        SELECT callout_id, old_cal_status
        FROM (
            UPDATE TOP(@top) cs WITH (UPDLOCK, READPAST, ROWLOCK)
            SET cal_status = 4
            OUTPUT inserted.callout_id, deleted.cal_status
            FROM ccoCallsOutSource cs
            WHERE cs.cam_id = @camp_id AND (cs.cal_status < 2 OR cs.cal_status = 7)
        ) AS X(callout_id, old_cal_status);


        INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, 
        iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
            iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
        SELECT TOP(@top) cs.callout_id, cs.cam_id, CASE WHEN ISNULL(cs.recycleType, 1) = 0 THEN 
        CASE 
            WHEN cs.recyclePhone = 1 THEN cs.cal_telefono
            WHEN cs.recyclePhone = 2 THEN cs.cal_telefono2
            WHEN cs.recyclePhone = 3 THEN cs.cal_telefono3
            WHEN cs.recyclePhone = 4 THEN cs.cal_telefono4
            else cs.cal_telefono5
        END
        ELSE rtrim(left(ltrim(cs.cal_telefono + ''        '' + cs.cal_telefono2 + ''         '' 
            + cs.cal_telefono3 + ''         '' + cs.cal_telefono4 + ''         '' + cs.cal_telefono5 + ''         ''), 13)) 
        END AS cal_telefono,
            CASE c.old_cal_status WHEN 7 THEN 1 ELSE c.old_cal_status END cal_status, cs.cal_fechaDial, cs.cal_key, 
            CASE WHEN LEN(cs.cal_telefono) > 0 THEN cs.iZonaHoraria ELSE NULL END iZonaHoraria,
            CASE WHEN LEN(cs.cal_telefono) > 0 THEN cs.iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano, 
            CASE WHEN LEN(cs.cal_telefono2) > 0 THEN cs.iZonaHoraria2 ELSE NULL END iZonaHoraria2,
            CASE WHEN LEN(cs.cal_telefono2) > 0 THEN cs.iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2, 
            CASE WHEN LEN(cs.cal_telefono3) > 0 THEN cs.iZonaHoraria3 ELSE NULL END iZonaHoraria3, 
            CASE WHEN LEN(cs.cal_telefono3) > 0 THEN cs.iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
            CASE WHEN LEN(cs.cal_telefono4) > 0 THEN cs.iZonaHoraria4 ELSE NULL END iZonaHoraria4, 
            CASE WHEN LEN(cs.cal_telefono4) > 0 THEN cs.iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4, 
            CASE WHEN LEN(cs.cal_telefono5) > 0 THEN cs.iZonaHoraria5 ELSE NULL END iZonaHoraria5, 
            CASE WHEN LEN(cs.cal_telefono5) > 0 THEN cs.iZonaHoraria_verano5 ELSE 
                    NULL END iZonaHoraria_verano5, cs.list_id
        FROM ccoCallsOutSource cs
        INNER JOIN #claimCallIds c ON c.callout_id = cs.callout_id
        WHERE cs.cam_id = @camp_id
    --Se elimina de workingtable en caso de que no se hayan borrado correctamente no genere error al insertar nuevos registros
        DELETE wt FROM ccoWorkingTable wt
        INNER JOIN #tempCallsOutSource tcs on wt.callout_id = tcs.callout_id
        WHERE wt.cam_id = @camp_id

        SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

        IF EXISTS(SELECT * FROM #tempCallsOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempCallsOutSource WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                 INSERT INTO ccoWorkingTable  WITH (ROWLOCK)
                (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
                SELECT t.callout_id, t.cam_id, t.cal_telefono, t.cal_status, t.cal_fechaDial, t.cal_keyw,
                       t.iZonaHoraria, t.iZonaHoraria_verano, t.iZonaHoraria2, t.iZonaHoraria_verano2,
                       t.iZonaHoraria3, t.iZonaHoraria_verano3, t.iZonaHoraria4, t.iZonaHoraria_verano4,
                       t.iZonaHoraria5, t.iZonaHoraria_verano5, t.list_id
                FROM #tempCallsOutSource t
                WHERE t.id > @batchsizeIni AND t.id <= @batchsizeFin
                  AND NOT EXISTS (
                    SELECT 1 FROM ccoWorkingTable w WITH (UPDLOCK, HOLDLOCK) WHERE w.callout_id = t.callout_id
                );

                SET @InsertedRows += @@ROWCOUNT;

                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE ccoCallsOutSource
            SET cal_status = 2, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
            FROM ccoCallsOutSource co
            INNER JOIN #claimCallIds c ON co.callout_id = c.callout_id
        END

        COMMIT
        END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
END CATCH
        DROP TABLE #claimCallIds
        DROP TABLE #calloutIdSource
        DROP TABLE #calloutIdSource2
        DROP TABLE #tempCallsOutSource
END

_FIN:
UPDATE ccCampsNvosCB
SET dateUpdate = NULL
WHERE id = @camp_id

IF @HadError = 1
BEGIN
    RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
END

SELECT @InsertedRows AS InsertedRows;
RETURN 0;

SET NOCOUNT OFF
'
	EXEC(@sql);

	 SET @process = 'Sprint6_finalPart - DROP ccsp_RIALogPhones si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_RIALogPhones'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_RIALogPhones
    '
    exec (@sql)
	SET @process = 'Sprint6_finalPart - CREATE SP ccsp_RIALogPhones 
	Se quito la línea
	   if @nType like %____1%
            select @CaseType = @CaseType +   or telefono<> '' and crlp.tipoMov = 0
	Debido a que al filtrar solo por registros no cargados tambien traia los telefonos, y eso estaba
	mal ya que para ver los telefonos no cargados existe el filtro de telefonos'
	SET @sql = 'CREATE procedure [dbo].[ccsp_RIALogPhones]
		@load_id int,
		@Type smallint,
		@GenCSV bit = 1, -- 0:100 / 1:todos
		@isKolob bit = 0,
		@PageIndex      INT = 0,
		@PageSize       INT = 0,
		@option SMALLINT = NULL
		as
		set nocount ON
 
 
		declare @CaseType varchar(2000), @sql nvarchar(MAX), @nType char(5), @MovType SMALLINT, @language int, @LoadBySegment varchar(1)
		SELECT @language = cs.valor FROM dbo.ccSettings AS cs WHERE cs.setting_id = 27;
		declare @PageStart int,@PageEnd int
		SELECT @LoadBySegment = CAST(ISNULL(LoadBySegment,''0'') as varchar) from ccRIALoading where load_id = @load_id
		IF(@option = 0)
		BEGIN
			select CAST(@LoadBySegment as bit) as LoadBySegment
			return 0;
		END
 
		select @CaseType = '''', @nType = right(''0000''+cast(@Type as varchar(5)), 5)
		
		if @nType like ''%____1%'' --Record Not Loaded
            select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov in (0,6,7,8)
			''
		
		if @nType like ''%___1_%''--Number Not Loaded
            select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov in(-1,0,6,7,8)
			''
 
		if @nType like ''%__1__%''--Record Blocked
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov IN (1)
			''
 
		if @nType like ''%_1___%''--Number blocked
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov IN (1,4) 
			''
 
		if @nType like ''%1____%''--Record Updated
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 2 ''
 
		if @CaseType = '''' and @nType <> 0
			return(0)
 
		select @PageStart=@PageSize*(@PageIndex-1),@PageEnd=@PageSize*@PageIndex
 
		IF(@option = 1)
		BEGIN	
			SET @sql = ''SELECT count(*) AS listSize FROM (
		select crlp.load_id
		from ccRIALogPhones AS crlp 
		where crlp.load_id = @load_id and ('' 
		+ ISNULL(STUFF(@CaseType,CHARINDEX(''or'',@CaseType),LEN(''or''),''''),'''') +'')) tmp '' +
		case @GenCSV when 0 then ''WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd'' else '''' end
					--EXEC(@sql);
 
				Exec sp_executesql @sql
						 , N''@PageStart int,@PageEnd int,@language int,@load_id int''
						 , @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id
					RETURN (0);
				END
				ELSE 
				BEGIN
						IF(@isKolob = 1)
						BEGIN
 
						declare @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200), @typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
                        @typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @typeUpdatedRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200), @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max), @descriptionProcessingRecords VARCHAR(200),@descriptionEmpty VARCHAR(200);
 
 
						select @typeDescriptionPhoneBlocked=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-num''
						select @typeDescriptionPhoneUpdated=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-num''
						select @typeIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-incorrect-records''
						select @typeBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-records''
						select @typeDescriptionPhoneNotLoaded=translate from tableLangueDbLoader where languageId=@language and tag=''type-not-loaded-num''
 
						select @typeDescriptionPhoneBlackList=translate from tableLangueDbLoader where languageId=@language and tag=''description-dnc-list''
						select @descriptionIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-incorrect-records''
						select @descriptionBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-blocked-records''
						select @typeUpdatedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-records''
						select @descriptionInternationalPortNotFound=TRANSLATE from tableLangueDbLoader where languageId=@language and tag=''type-camp-no-international-port''
                        select @descriptionProcessingRecords = translate from tableLangueDbLoader where languageId = @language and tag = ''record-not-loaded-processing'';
                        select @descriptionEmpty = translate from tableLangueDbLoader where languageId = @language and tag = ''description-empty'';
 
						select @column=translate from tableLangueDbLoader where languageId=@language and tag=''column-file-field''
 
						select @headerPhone=header_phone,@headerPhone2=header_phone2,@headerPhone3=header_phone3,@headerPhone4=header_phone4 
						,@headerPhone5=header_phone5
						from fileHeadersPhoneLoad where load_id=@load_id
							set @CaseType=case when @CaseType <> '''' then '' and ('' + substring(@CaseType, 5, len(@CaseType)) + '')'' else '''' END
							SET @sql = '';with result as(
							SELECT * FROM (select  
							ROW_NUMBER() OVER(ORDER BY crlp.cal_key ASC) AS RowNum,
							crlp.load_id,
							crlp.cal_key, 
							CASE
								WHEN ISNULL(crlp.telefono, '''''''') = '''''''' THEN ''''''''
								WHEN crlp.internationalRecords = 0 THEN ''''N-'''' + REPLACE(crlp.telefono, ''''E_'''', '''''''')
								ELSE ''''I-'''' + REPLACE(crlp.telefono, ''''E_'''', '''''''')
							END AS phone,
							CASE
								WHEN crlp.tipoMov in (1,4)  THEN @typeDescriptionPhoneBlocked  
								WHEN crlp.tipoMov = 2 THEN @typeUpdatedRecords	
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @typeIncorrectRecords
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @typeBlockedRecords
								WHEN crlp.tipoMov in(-1,0) THEN @typeDescriptionPhoneNotLoaded
                                WHEN crlp.tipoMov = 6 THEN @descriptionProcessingRecords
                                WHEN crlp.tipoMov = 7 THEN @descriptionEmpty
								WHEN crlp.tipoMov in(8) THEN @descriptionInternationalPortNotFound
								WHEN crlp.keyTranslate is not null THEN isnull(tlan.translate,crlp2.descTipoMov)
							ELSE 
								crlp2.descTipoMov  
							END AS Tipo,
							case when CHARINDEX('''':'''',crlp.motivo)=0 then 0 else
								convert(int,substring(crlp.motivo ,CHARINDEX('''':'''',crlp.motivo)-1 ,1))
							end
							 AS ColumnFile, 
							CASE  WHEN crlp.tipoMov = 2 THEN ''''N/A'''' 
									WHEN crlp.tipoMov in (1,4) THEN @typeDescriptionPhoneBlackList							  
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @descriptionIncorrectRecords
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @descriptionBlockedRecords
                                    WHEN crlp.tipoMov = 6 THEN @descriptionProcessingRecords
                                    WHEN crlp.tipoMov = 7 THEN @descriptionEmpty
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-camp-no-international-port'''') THEN  @descriptionInternationalPortNotFound
									WHEN crlp.keyTranslate is not null THEN tlan.translate 
							ELSE crlp.motivo END AS motivo,
							CAST('' + @LoadBySegment + '' as BIT) AS LoadBySegment
							from ccRIALogPhones AS crlp 
							INNER JOIN dbo.ccRIACATLogPhones AS  crlp2 ON crlp.tipoMov = crlp2.tipoMov
							left join tableLangueDbLoader tlan on tlan.tag=crlp.keyTranslate and tlan.languageId=@language
							where crlp.load_id = @load_id '' 				
							+ @CaseType +'') tmp '' +
							case @GenCSV when 0 then '' WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd '' else '''' end +'' 
							) 
							select  crlp.RowNum,
							crlp.load_id,
							crlp.cal_key, 
							crlp.phone,
							crlp.Tipo,
							case when crlp.ColumnFile=1 then @headerPhone
							when crlp.ColumnFile=2 then @headerPhone2
							when crlp.ColumnFile=3 then @headerPhone3
							when crlp.ColumnFile=4 then @headerPhone4
							when crlp.ColumnFile=5 then @headerPhone5
							else '''''''' end ColumnFile,
							crlp.motivo
							from result crlp ''
			END
			ELSE
			BEGIN
				set @sql = ''select '' + case @GenCSV when 0 then ''top 100 '' else '''' end 
				+ ''load_id, cal_key, telefono, tipoMov, motivo from ccRIALogPhones AS crlp where load_id = @load_id '' 
				+ @CaseType
			END  
			--PRINT(@sql);
 
 
			Exec sp_executesql @sql, N''@PageStart int,@PageEnd int,@language int,@load_id int, @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200),
			@typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
			@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200)
            , @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max), @typeUpdatedRecords varchar(200),@descriptionProcessingRecords VARCHAR(200),@descriptionEmpty VARCHAR(200)''
			, @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id,@column=@column,@typeDescriptionPhoneNotLoaded=@typeDescriptionPhoneNotLoaded
			,@typeDescriptionPhoneBlocked=@typeDescriptionPhoneBlocked,@typeDescriptionPhoneUpdated=@typeDescriptionPhoneUpdated,@typeDescriptionPhoneBlackList=@typeDescriptionPhoneBlackList
			,@typeBlockedRecords=@typeBlockedRecords,@typeIncorrectRecords=@typeIncorrectRecords,@descriptionBlockedRecords=@descriptionBlockedRecords,@descriptionIncorrectRecords=@descriptionIncorrectRecords,
			 @descriptionInternationalPortNotFound= @descriptionInternationalPortNotFound 
            ,@headerPhone=@headerPhone,@headerPhone2=@headerPhone2,@headerPhone3=@headerPhone3,@headerPhone4=@headerPhone4,@headerPhone5=@headerPhone5,@typeUpdatedRecords=@typeUpdatedRecords,@descriptionProcessingRecords=@descriptionProcessingRecords,@descriptionEmpty=@descriptionEmpty
		return(0)
		END
		set nocount OFF'
	EXEC(@sql)


		 SET @process = 'Sprint6_finalPart - DROP ccsp_RIAConfCamp si existe'
    SET @sql = '
    IF OBJECT_ID(''dbo.ccsp_RIAConfCamp'', ''P'') IS NOT NULL
        DROP PROCEDURE dbo.ccsp_RIAConfCamp
    '
    exec (@sql)
	SET @process = 'Solución para el ticket CW-11150 - Sprint6_finalPart - CREATE ccsp_RIAConfCamp'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAConfCamp]
    @User_id SMALLINT,
    @campID INT = NULL
AS
    SET NOCOUNT ON;

    DECLARE @tableExistsRec TABLE (
        camId INT PRIMARY KEY,
        existRec BIT
    );
    DECLARE @camByUser TABLE (
        camId INT PRIMARY KEY,
        isCheck BIT
    );
    DECLARE @camId INT, @id INT;
    DECLARE @intenationalDialingPorts BIT;
    DECLARE @tempInternationalCode INT;

    IF (
        SELECT COUNT(*)
        FROM (
            SELECT TOP 1 IdCode
            FROM ccoDialers ccoDial
            INNER JOIN ccoDialerCamp ccoDialCamp ON ccoDialCamp.dialer_id = ccoDial.dialer_id
            WHERE ccoDialCamp.cam_id = @campID
                AND ccoDial.DialingType = 0
        ) result
    ) > 0
    BEGIN
        SET @intenationalDialingPorts = 1;
    END
    ELSE
    BEGIN
        SET @intenationalDialingPorts = 0;
    END;

    IF NOT EXISTS (
        SELECT *
        FROM ccUsers_Roles
        WHERE User_id = @User_id
            AND Rol_id = 7
    )
    BEGIN
        INSERT INTO @camByUser
        SELECT *, 0
        FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
        WHERE @campID IS NULL
            OR cam_id = @campID;
    END
    ELSE
    BEGIN
        INSERT INTO @camByUser
        SELECT cam_id, 0
        FROM ccCamps
        WHERE (IDArea > 0 OR IDArea IS NULL)
            AND (@campID IS NULL OR cam_id = @campID);
    END;

    WHILE EXISTS (
        SELECT *
        FROM @camByUser
        WHERE isCheck = 0
    )
    BEGIN
        SELECT TOP 1 @camId = camId
        FROM @camByUser
        WHERE isCheck = 0;

        IF EXISTS (
            SELECT cam_id
            FROM ccoCallsOut
            WHERE cam_id = @camId
        )
        BEGIN
            INSERT INTO @tableExistsRec
            VALUES (@camId, 1);
        END
        ELSE
        BEGIN
            INSERT INTO @tableExistsRec
            VALUES (@camId, 0);
        END;

        UPDATE @camByUser
        SET isCheck = 1
        WHERE camId = @camId;
    END;

    SELECT
        a1.cam_id,
        cam_Descripcion,
        cam_tNotas,
        CAST(cam_ocupado AS INT) AS cam_ocupado,
        cam_noInt_ocupado,
        cam_inter_ocupado,
        CAST(cam_nocontesto AS INT) AS cam_nocontesto,
        cam_noInt_nocontesto,
        cam_inter_nocontesto,
        CAST(cam_fax AS INT) AS cam_fax,
        cam_noInt_fax,
        cam_inter_fax,
        CAST(cam_modomanual AS INT) AS cam_modomanual,
        ANI,
        cam_ShowCalifWnd,
        cam_StartTimerOnHangUp,
        editableCallKey,
        cam_tNoContesta,
        iTipoDial,
        detectAnswerMachine,
        detectVoiceMail,
        compliance,
        cam_inter_graba,
        cam_noint_graba,
        CAST(progDial AS TINYINT) progDial,
        CAST(excCallBack AS TINYINT) excCallBack,
        dialOrder,
        dialPrefix,
        dialPrefixMan,
        dialPrefixXfe,
        listenManualCall,
        stopRecording,
        CAST(abandonCallback AS TINYINT) abandonCallback,
        a3.frame,
        a1.t_autoCB,
        a1.id_anilist,
        a1.tDialonWrapUp,
        dbo.fn_viewMode(@User_id, 10) viewMode,
        cam_maxqueue AS queSize,
        DNCScrub,
        callerIdDesc,
        timeZoneRule,
        callsBySurvey,
        ivrScript,
        surveyPctg,
        ISNULL(a1.call_record, 1) AS call_record,
        CAST(startStopRecording AS TINYINT) startStopRecording,
        leaveRecMessage,
        manualCallOnChat,
        callBackSurveyAgent,
        callBackSurveyClient,
        CASE
            WHEN surveycamid IS NULL OR surveycamid = 0 THEN 0
            ELSE 1
        END isRelationSurvey,
        ISNULL(a1.funcEspDtmf, 0) funcEspDtmf,
        ISNULL(sipHdrFormat, '''') sipHdrFormat,
        cam_inter_cancelled,
        prefijo,
        enbleprefix = CASE
            WHEN existRec = 0 THEN 1
            ELSE 0
        END,
        ISNULL(exitAssisted, 0) exitAssisted,
        ISNULL(previewDiscard, 0) PreviewDiscard,
        case when CampType = 9 then 10 else ISNULL(CampType, 0) end as CampType,
        ISNULL(contact.conexionInfo, '''') conexionInfo,
        ISNULL(contact.connUser, '''') connUser,
        ISNULL(contact.closeConversationTime, 0) closeConversationTime,
        ISNULL(contact.answerTimeoutClient, 0) answerTimeoutClient,
        ISNULL(contact.allowFileAttachments, 0) allowFileAttachments,
        ISNULL(selectRotativeANI, 0) selectRotativeANI,
        ISNULL(rotativeAlgo, 0) rotativeAlgo,
        ISNULL(autoStart, 0) autoStart,
        ISNULL(messagingOrder, 0) messagingOrder,
        ISNULL(cam_tPreview, 0) AS CamTPreview,
        ISNULL(timesPreview, 0) AS TimesPreview,
        ISNULL(timesDiscard, 0) TimesDiscard,
        ISNULL(recordHold, 0) recordHold,
        ISNULL(campsExtention.zipCodeSchedule, 1) AS ZipCodeSchedule,

        ISNULL(campsExtention.RecordCalls, 1) RecordCalls,
        ISNULL(campsExtention.simultaneousRecs, 1) simultaneousRecs,
        ISNULL(campsExtention.EditableContactData, 0) EditableContactData,
        @intenationalDialingPorts intenationalDialingPorts,
        ISNULL(campsExtention.AssignConversationSameAgent, 0) AssignConversationSameAgent,
        ISNULL(contact.maxLimitQueueConversations, 99) maxLimitQueueConversations,
        ISNULL(contact.MaxDaysPerWAConvo, 5) MaxDaysPerWAConvo,
        isnull(recordIvr, 1) recordIvr,
        ISNULL(CamCanceled, 4) CamCanceled,
        ISNULL(surveyCamId, 0) surveyCamId,
        -- Outbound AI Campaign Special Settings
        ISNULL(campsExtention.RescheduledSurveyAI, 0) RescheduledSurveyAI,
        ISNULL(campsExtention.ImmediateSurveyAI, 0) ImmediateSurveyAI,
        ISNULL(campsExtention.ApplyRescheduledSurveyForCompletedCallsAI, 0) ApplyRescheduledSurveyForCompletedCallsAI,
        ISNULL(campsExtention.EnableCallRecordingAI, 0) EnableCallRecordingAI,
        -- Manual Rotation Dialing Configurations
        ISNULL(a1.rotativeAlgorithmManual, 4) RotativeAlgorithmManual,
        ISNULL(a1.idAniListManual, 0) IdAniListManual,
        ISNULL(campsExtention.ManualCallANIMode, 0) ManualCallANIMode,
        ISNULL(campsExtention.IsCallTranscriptionEnabled, 0) IsCallTranscriptionEnabled
    FROM ccCamps a1
    INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
    INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
    INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
    LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
    LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
    ORDER BY cam_descripcion;

    RETURN (0);

    SET NOCOUNT OFF;'
	EXEC(@sql)


	 -- =============================================================================
    -- KM020000 validar si la campaña tiene alguna asignación o esta asignada a una campaña de entrada
	-- se modificó el option 4 para incluir la validación
    -- =============================================================================
	set @process = 'KM020000 drop ccsp_GalateaManageWG'
set @sql='
    if exists (select * from sys.procedures where name = N''ccsp_GalateaManageWG'')
        begin
            DROP PROCEDURE ccsp_GalateaManageWG;
        end'
EXEC(@sql)

SET @process = 'KM020000 UPDATE ccsp_GalateaManageWG, validate if campaign has any asociación en option 4'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaManageWG]
@option smallint,
@IDWG smallint,
@Type smallint = 0,
@usersList varchar(max) ='''',
@ListCampsIn varchar(max) = '''',
@ListCampsOut varchar(max) ='''',
@idNewArea int = 0,
@LoginId int = 0,
@AreaId int = 0
as
set nocount on
declare @count int
declare @id int
declare @user int
declare @IDCampEsp varchar(max)
declare @Assigned  varchar(max)
declare @AssignedCampsIn  varchar(max)
declare @AssignedCampsOut  varchar(max)
declare @settings table (
setting_id tinyint,
valor varchar(300)
)
insert into @settings (setting_id, valor) select setting_id,valor from ccSettings where setting_id in (63,64,180)

set @id = 1
set @Assigned = ''''
set @AssignedCampsIn = ''''
set @AssignedCampsOut = ''''


IF OBJECT_ID(''tempdb..#UsersList'') IS NOT NULL DROP TABLE #UsersList;
IF OBJECT_ID(''tempdb..#CampsInOutList'') IS NOT NULL DROP TABLE #CampsInOutList;

select *  into #CampsInOutList from (
select ROW_NUMBER() OVER(ORDER BY [CampEsp] ASC) AS Row, [CampEsp], [Type] from (
    select 0 as [Type],
    [value] As [CampEsp]
    FROM fn_RIASplitDelimited(@ListCampsIn, '','') where [value] > 0
    union
    select 1 as [Type],
    [value] As [CampEsp]
    FROM fn_RIASplitDelimited(@ListCampsOut, '','') where [value] > 0
    ) as Camps ) as CampsInOut

select ROW_NUMBER() OVER(ORDER BY value ASC) AS Row,
    value As user_id
    into #UsersList
    FROM fn_RIASplitDelimited(@usersList, '','')

select @count = count(user_id) from #UsersList

IF(@option = 1 OR @option = 2) BEGIN

    DECLARE @areaName VARCHAr(50);
    DECLARE @userLogin VARCHAR(40);
    DECLARE @workGroupName VARCHAR(40);
    DECLARE @userToAffect VARCHAR(40);
    DECLARE @campName VARCHAR(40);

END

if @option = 1 -- Insert Agente-Supervisor in WorkGroup
 begin

    IF EXISTS (SELECT IDWG FROM ccRIAAreaWorkGroup WHERE IDWG = @IDWG AND IDArea = @AreaId) BEGIN
    while @id<=@count
    begin
        select @user = user_id from #UsersList where Row= @id
        select @Type = tipoUser_id from ccUsers where user_id = @user

        if @Type in(1, 2, 6)
        begin

            if not exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @user)
            begin
            

                If @Type = 1
                 begin

                        If (select count(User_id) from ccRIAWorkGroupUsers where User_id = @user) < (select valor from @settings where setting_id=63)
                         begin
                            insert into ccRIAWorkGroupUsers(IDWG, User_id) values(@IDWG,@user)

                            --INSERT LOG RECORD (ASSIGN AGENT)
                            SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                            SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                            SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 23, 3, '''', @userToAffect, @workGroupName);

                            select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                            --insert skill media
                            exec ccsp_Skills @action= 5,@userId=@user

                            --select * from cccampsAgente where user_id=@user and 

                            insert into cccampsAgente (user_id, cam_id, prioridad, skill, IDWG)
                            select @user [User_id], A.idCampEsp [cam_id], dbo.fn_Calcula_UsrPriority(@user,0) [prioridad], 1 [skill], @IDWG IDWG
                            
                            from ccRIACampEspWG A
                            inner join ccCamps C on A.Tipo=1 and A.idCampEsp=C.cam_id                           
                            where A.tipo = 1 and A.IDWG = @IDWG and
                             idCampEsp not in (select cam_id from cccampsAgente where user_id=@user and IDWG=@IDWG)
                             


                           insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, IDWG)
                            select @user, A.idCampEsp, 0, dbo.fn_Calcula_UsrPriority(@user,0), 1, @IDWG
                            from ccRIACampEspWG A
                            inner join ccInbound C on A.Tipo=0 and A.idCampEsp=C.Inbound_id
                            where A.tipo = 0 and IDWG = @IDWG and

                            idCampEsp not in (select inbound_id from ccInboundAgentes where user_id=@user and IDWG=@IDWG)

                            if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
                                insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
                            end
                        end
                 end
                 else if @Type in(2, 6)
                 begin
                    -- -Supervisor  @Type in (2,6)
                    insert into ccRIAWorkGroupUsers(IDWG, User_id) values (@IDWG, @user)

                    --INSERT LOG RECORD (ASSIGN ADMIN)
                    SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                    SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                    SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 30, 3, '''', @userToAffect, @workGroupName);

                    select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                    if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
                        insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
                    end

                    insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                    select @user, idCampEsp, 0, @IDWG
                    from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
                     and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@user and tipo=0 and IDWG=@IDWG)

                    update ccSupervisorCam
                    set monitored = 1
                    where user_id = @user
                    and cam_id in (select cam_id from ccSupervisorCam where user_id=@user and tipo=0 and IDWG=@IDWG)
                    and tipo = 0
                    and IDWG <> @IDWG
                    and monitored = 0

                    insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                    select @user, idCampEsp, 1, @IDWG
                    from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
                     and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@user and tipo=1 and IDWG=@IDWG)

                    update ccSupervisorCam
                    set monitored = 1
                    where user_id = @user
                    and cam_id in (select cam_id from ccSupervisorCam where user_id=@user and tipo=1 and IDWG=@IDWG)
                    and tipo = 1
                    and IDWG <> @IDWG
                    and monitored = 0
                end
                
            end
        end
        set @id = @id+1
    end
    end
end




if @option = 2 -- Delete Agent-Supervisor from WorkGroup
 begin

    while @id<=@count
    begin
        select @user = user_id from #UsersList where Row= @id
        select @Type = tipoUser_id from ccUsers where user_id = @user
        
        if @Type = 1 --delete skill media
        exec ccsp_Skills @action= 4,@userId=@user,@idwg=@IDWG

        IF(@Type = 1)
        BEGIN
            INSERT INTO dbo.unassignAgentInfoTmp
            (
                userId,
                idcamp,
                tipo,
                prioridad,
                skill
            )
            SELECT DISTINCT crwgu.User_id, crcew.IdCampEsp, crcew.Tipo,  COALESCE(CA.prioridad, IA.prioridad, 1) AS Prioridad,COALESCE(CA.skill, IA.skill, 1) AS Skill FROM dbo.ccRIAWorkGroupUsers AS crwgu 
            INNER JOIN dbo.ccRIACampEspWG AS crcew
            ON crcew.IDWG = crwgu.IDWG
            LEFT JOIN ccCampsAgente CA WITH(NOLOCK) 
            ON crcew.IdCampEsp = CA.cam_id AND crcew.Tipo = 1 AND crwgu.User_id = CA.User_id
            LEFT JOIN ccInboundAgentes IA WITH(NOLOCK) 
                ON crcew.IdCampEsp = IA.inbound_id AND crcew.Tipo = 0 AND crwgu.User_id = IA.User_id
            WHERE crwgu.User_id = @user AND crwgu.IDWG = @IDWG;
        END
        
        if exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @user)
        begin
        
            Delete ccRIAWorkGroupUsers where IDWG = @IDWG and User_id = @user
        

            if @Type = 1 -- Agente
             begin

                --INSERT LOG RECORD (UNASSIGN AGENT)

                SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 24, 3, '''', @userToAffect, @workGroupName);

                select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG   from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
                insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG

                delete from cccampsagente where user_id=@user and IDWG=@IDWG
                delete from ccInboundagentes where user_id=@user and IDWG=@IDWG

                --update preview permission
                update ccusers set 
                AllowChangeDialingMode=(case when assigned is null then 0 else 1 end),
                DialingMode=(case when assigned is null then 0 else 1 end) from ccusers us (nolock) left join (
                select count(1) assigned,user_id from ccCampsAgente ca (nolock) join ccCamps cc (nolock) on cc.cam_id=ca.cam_id
                where progDial=3 and user_id = @user group by user_id)c on us.User_id=c.user_id
                where us.user_id = @user
                --select @Type
             end
             else if @Type in(2, 6) -- Supervisor
             begin

                --INSERT LOG RECORD (UNASSIGN ADMIN)

                SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 31, 3, '''', @userToAffect, @workGroupName);

                select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
                delete ccSupervisorCam where user_id=@user and IDWG=@IDWG
                --select @Type
            end
        end
        set @id = @id+1
    end
end
if @option in (1,2)
begin
    if LEN(@Assigned) > 0
        select SUBSTRING(@Assigned,0,Len(@Assigned))
    else
        select @Assigned

    return(0)
end

if @option = 3 -- Insert WorkGroup in Camp or ACDGroup  
  begin
    select @count = count(CampEsp) from #CampsInOutList

    while @id<=@count
    begin
         select @IDCampEsp = CampEsp, @Type = Type from #CampsInOutList where Row= @id
         

         if (select count(IdCampEsp) from ccRIACampEspWG where IdCampEsp=@IDCampEsp and Tipo=@Type) <= (select valor from @settings where setting_id=180) -- limit
             begin

                if (select count(IDWG) from ccRIACampEspWG where IDWG=@IDWG) <= (select valor from @settings where setting_id=64) -- limit
                    begin

                        if not exists (select IDWG from ccRIACampEspWG where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) -- No existe el grupo en el ACD o Especialidad
                        begin

                            insert into ccRIACampEspWG (IDWG, Tipo, IdCampEsp, priority) values (@IDWG, @Type, @IDCampEsp, 1)
                            if not exists(select * from ccRIACampEspWGConsulta where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) begin
                                insert into ccRIACampEspWGConsulta (IDWG, Tipo, IdCampEsp) values (@IDWG, @Type, @IDCampEsp)
                            end   

                            SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                            
                            IF(@Type = 1) SET @campName = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @IDCampEsp)
                            ELSE SET @campName = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @IDCampEsp)
                             
                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                            VALUES (
                                (SELECT [AreaName] FROM ccRIACat_Areas AS CRA, ccRIAAreaWorkGroup AS CRAW WHERE CRAW.IDWG = @IDWG AND CRA.IDArea = CRAW.IDArea), 
                                getDate(), 
                                @userLogin, 
                                36, 
                                3, 
                                '''', 
                                @campName,
                                (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG)
                            );

                            exec ccsp_RIACalcula_WGPriority @IDWG, @IDCampEsp, @Type
                            if @Type in (0, 1) -- ACDGroup
                            begin

                                if @IDWG is not null or @IDWG = 0
                                begin
                                    if @Type=0 --ACDGroup
                                    begin
                                        select @AssignedCampsIn = @AssignedCampsIn+ cast(@IDCampEsp as varchar(5))+'',''
                                        insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
                                        SELECT distinct u.user_id, @IDCampEsp, 0 cli_id, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG 
                                        FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
                                            join ccusers s on u.user_id = s.user_id
                                        WHERE c.tipo=0 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and c.IDWG=@IDWG 
                                        and u.User_id not in (select User_id from ccInboundAgentes where Inbound_id=@IDCampEsp and IDWG=@IDWG)

                                        insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                                        select b.user_id, @IDCampEsp, 0, @IDWG
                                        from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
                                            join ccusers s on b.user_id = s.user_id
                                        where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=0
                                            and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=0 and IDWG=@IDWG)
             
                                        --return(0)
                                    end

                                    else if @Type = 1 -- Camp
                                    begin
                                        select @AssignedCampsOut = @AssignedCampsOut+ cast(@IDCampEsp as varchar(5))+'',''
                                        insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
                                        SELECT distinct u.user_id, @IDCampEsp, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG
                                        FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
                                        join ccusers s on u.user_id = s.user_id
                                        WHERE c.tipo=1 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and u.IDWG=@IDWG 
                                            and u.User_id not in (select User_id from ccCampsAgente where cam_id=@IDCampEsp and IDWG=@IDWG)
            
                                        insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                                        select b.user_id, @IDCampEsp, 1, @IDWG
                                        from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
                                            join ccusers s on b.user_id = s.user_id
                                        where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=1
                                            and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=1 and IDWG=@IDWG)
                                    end
                            end
                        end
                    end
                end
            end
        set @id = @id + 1
   end
end

if @option = 3
begin
    
if LEN(@AssignedCampsIn) > 0 or LEN(@AssignedCampsOut) > 0
        select SUBSTRING(@AssignedCampsIn,0,Len(@AssignedCampsIn)) as CampsInAssigned, SUBSTRING(@AssignedCampsOut,0,Len(@AssignedCampsOut)) as CampsOutAssigned 
    else
        select @AssignedCampsIn as CampsInAssigned, @AssignedCampsOut as CampsOutAssigned

    return(0)
end

if @option = 4  --Delete relatoion Camp with WG
begin
declare @multipleAgents varchar(1000)
declare @multipleAdmins varchar(2000)
declare @sql varchar(max)
DECLARE @HasErrorsResult INT = 1
DECLARE @Unassigned TABLE (CampEspId INT, [Type] INT)

select @count = count(CampEsp) from #CampsInOutList
 while @id<=@count
  begin

        select @IDCampEsp = CampEsp, @Type = Type from #CampsInOutList where Row= @id
		
		IF @Type = 1
			BEGIN 
				IF EXISTS(SELECT 1 FROM dbo.ccCamps AS cc WHERE cc.cam_id = @IDCampEsp AND cc.surveyCamId IS NOT NULL
				AND cc.surveyCamId > 0)
				OR EXISTS(SELECT 1 FROM dbo.ccInbound AS ci WHERE ci.cam_id = @IDCampEsp)
				BEGIN
					SET @HasErrorsResult = -3
					SET @id = @id + 1
					CONTINUE
				END
			END
		ELSE 
		BEGIN
            IF EXISTS ( SELECT 1 FROM dbo.ccInbound AS ci WHERE ci.Inbound_id = @IDCampEsp
			AND (ci.cam_id IS NOT NULL AND ci.cam_id > 0))
			OR EXISTS ( SELECT 1 FROM dbo.ccInboundExtend AS cie WHERE cie.Inbound_id = @IDCampEsp
			AND cie.SurveyCamId IS NOT NULL AND cie.SurveyCamId > 0)
			BEGIN
				SET @HasErrorsResult = -3
				SET @id = @id + 1
                CONTINUE
			END
		end

        SELECT @multipleAgents = coalesce(@multipleAgents + '','', '''') + CAST(A.user_id AS VARCHAR(40))
        FROM ccRIAWorkGroupUsers A
        JOIN ccUsers B ON A.user_id = B.user_id
        WHERE IDWG = @IDWG AND TipoUser_id = 1

        SELECT @multipleAdmins = coalesce(@multipleAdmins + '','', '''') + CAST(A.user_id AS VARCHAR(40))
        FROM ccRIAWorkGroupUsers A
        JOIN ccUsers B ON A.user_id = B.user_id
        WHERE IDWG = @IDWG AND TipoUser_id = 2


        if right( @multipleAgents,1)='','' begin
            set @multipleAgents=SUBSTRING(@multipleAgents,0,len(@multipleAgents)-1)
        end
        if right( @multipleAdmins,1)='','' begin
            set @multipleAdmins=SUBSTRING(@multipleAdmins,0,len(@multipleAdmins)-1)
        end


        --Delete Agent from WorkGroup
           set @sql = ''ccsp_RIA_ABCAgents @option=7,@UserId=''''0'''',@Login='''''''',@Nombres='''''''',@ApellidoPaterno='''''''',@ApellidoMaterno='''''''',@Password='''''''',@Sexo=0,@canChangeStatus=0,
                    @AreaId=0,@UserType=0,@IDWG=''+cast(@IDWG as varchar(4))+'',@DeleteUsers=0,@InOut=''+cast(@Type as varchar(4))+'',@IDCampEsp=''+cast(@IDCampEsp as varchar(4))+'',@multipleUsers=''''''+@multipleAgents+''''''''
           
           exec(@sql)

         --Delete Supervisor from WorkGroup

         set @sql = ''ccsp_RIA_ABCAgents @option=8,@UserId=''''0'''',@Login='''''''',@Nombres='''''''',@ApellidoPaterno='''''''',@ApellidoMaterno='''''''',@Password='''''''',@Sexo=0,@canChangeStatus=0,
                    @AreaId=0,@UserType=0,@IDWG=''+cast(@IDWG as varchar(4))+'',@DeleteUsers=0,@InOut=''+cast(@Type as varchar(4))+'',@IDCampEsp=''+cast(@IDCampEsp as varchar(4))+'',@multipleUsers=''''''+@multipleAdmins+''''''''
           
           exec(@sql)

        --Delete WokGroup from ACD or Camp 

        SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                            
        IF(@Type = 1) SET @campName = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @IDCampEsp)
        ELSE SET @campName = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @IDCampEsp)
                             
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        VALUES (
            (SELECT [AreaName] FROM ccRIACat_Areas AS CRA, ccRIAAreaWorkGroup AS CRAW WHERE CRAW.IDWG = @IDWG AND CRA.IDArea = CRAW.IDArea), 
            getDate(), 
            @userLogin, 
            59, 
            3, 
            '''', 
            @campName,
            (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG)
        );


         set @sql = ''exec ccsp_RIA_ABCWorkGroups @option=7,@IDWG=''+cast(@IDWG as varchar(4))+'',@IDCampEsp=''''''+cast(@IDCampEsp as varchar(4))+'''''',@Type=''+cast(@Type as varchar(4))+''''
         exec(@sql)

		INSERT INTO @Unassigned (CampEspId, [Type]) VALUES (@IDCampEsp, @Type)
         
        set @id = @id + 1
    
    end

    IF EXISTS (SELECT 1 FROM @Unassigned)
    BEGIN
        SELECT CampEspId, [Type], @HasErrorsResult AS HasErrorsResult FROM @Unassigned
    END
    ELSE
    BEGIN
        SELECT NULL AS CampEspId, NULL AS [Type], @HasErrorsResult AS HasErrorsResult
    END

    return 0
end

if @option = 5  --Change Admin Administrator.
begin
declare @user_id int
select @user_id = value FROM fn_RIASplitDelimited(@usersList, '','')
select @Type = TipoUser_id from ccUsers where User_id = @user_id

        if @Type = 1 -- Agente
        begin

            if(select count(user_id) from ccCampsAgente where user_id = @user_id) >0 or 
            (select count(user_id) from ccInboundAgentes where user_id = @user_id) >0 or
            (select count(user_id) from ccRIAWorkGroupUsers where user_id = @user_id) > 0
            begin
                select -1
                return 0
            end
            else

                SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user_id AND CCRA.IDArea = CCU.IDArea;
                SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                VALUES (@areaName, getDate(), @userLogin, 27, 3, ''T&CHANGE_USER_AREA'', (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idNewArea), @userToAffect);

                update ccUsers set IDArea = @idNewArea where user_id = @user_id
        end

        
    if @Type in (2, 6) -- Supervisor
    begin

        if(select count(user_id) from ccSupervisorCam where user_id = @user_id) > 0 or
        (select count(user_id) from ccRIAWorkGroupUsers where user_id = @user_id) > 0
        begin
            select -1
            return 0
        end
        else

            SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user_id AND CCRA.IDArea = CCU.IDArea;
            SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
            VALUES (@areaName, getDate(), @userLogin, 34, 3, ''T&CHANGE_USER_AREA'', (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idNewArea), @userToAffect);

            update ccUsers set IDArea = @idNewArea where user_id = @user_id
    end

    update ccPosicion set user_id = 0 where user_id = @user_id

    select 1

end

set nocount off';

EXEC(@sql)
 -- =============================================================================
    -- K070407 (Marco Garcia) agregar las tablas ccCalif_IA_TransferConfig, ccCalif_IA_TransferOptionCatalog, ccCalif_IA_DestinationTypeCatalog
	-- para la configuración de las transferencia en la creación, edición de las calificaciónes
	-- de igual forma agregar la columna AplRetryDialing a la tabla cctipoCalif_IA, para realizar la configuración de "reintentos de marcación" desde
	-- el aparto de calificaciones
	-- se modifica el sp SaveDispositionsAI, para que los reintentos de marcación se haga por minuto tal cual dice la HU 
	-- tambien se modificaron los sp ccsp_GalateaAdminDispositions, ccsp_GalateaDeleteCampaignAndACD
	-- y se agregaron identificadores nuevos para cubrir la etiquetas del historial
	-- tambien el sp SaveDispositionsAI ya tiene los cambios de sprint6_finalpart
	------------------------------------------------------------------------------------------------------
	  -- Sprint 6 final part (Marco García, David Medina) - Transferencia de salida IA y transferencia de entrada IA
    -- Se agregaron los action 5 , 6 y 7 al sp SaveDispositionsAI, para obtener la información del agente virtual 
    -- y la transcripción de la llamada.
    -- el state machine consulta esa información, para poder mostrarla en la UI 
    -- =============================================================================
	SET @process = 'K070407 Drop procedure SaveDispositionsAI MAGV'
	SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''SaveDispositionsAI'')
		BEGIN
			DROP PROCEDURE dbo.SaveDispositionsAI
		END'
	EXEC(@sql);

	SET @process = 'K070407 Se modificó la línea SET @CallbackAT = DATEADD(ss,@IntervalInMinutes,GETDATE()),
	para que se realice por minutos y no por segundos , de igual forma se modificó el nombre de la variable
	@IntervalInSeconds a @IntervalInMinutes MAGV'
	SET @sql = 'CREATE PROCEDURE [dbo].[SaveDispositionsAI]
	@action        smallint    = NULL,
	@call_Id       int         = NULL,
	@Qualification varchar(MAX)= NULL,
	@result        varchar(MAX)= NULL,
	@Observations  varchar(MAX)= NULL,
	@CallbackAT    DATETIME = NULL,
	@Transcription varchar(MAX)= NULL,
	@CamType       bit         = 0,
	@disposition_Id SMALLINT = null,
	@CapturedData varchar(max) = null
	AS
	BEGIN
		SET NOCOUNT ON;
		--Variables para devolución de llamada 
		DECLARE @cal_key varchar(40) ='''';
		DECLARE @cam_id smallint;
		DECLARE @cal_telefono varchar(19);
		DECLARE @inbound_id smallint = NULL;
		DECLARE @CanReprogram smallint  = null
		DECLARE @NumberOfTries INT = null, @IntervalInMinutes INT = null;

		-- Validacion del Status del Setting 289
		DECLARE @trans_status BIT = NULL;
	
		DECLARE @valor  NVARCHAR(15) = NULL;

		SELECT @valor = TRY_CAST(valor AS NVARCHAR(15))	
		FROM ccSettings2
		WHERE setting_id = 289;

		DECLARE @status NVARCHAR(5);
		DECLARE @sep    INT;
		declare @name_cal varchar(150) = '''';

		SET @sep = CHARINDEX(''|'', ISNULL(@valor, ''''));
		SET @status = CASE
						WHEN @sep > 0 THEN SUBSTRING(@valor, 1, @sep - 1)
						ELSE ISNULL(@valor, '''')
					  END;

		IF @action = 1  -- Outbound
		BEGIN
			DECLARE @pendingTriesByDisp INT = 0
			DECLARE @initialDisposition SMALLINT = 0;
			DECLARE @callKey VARCHAR(40) = ''''

			select @name_cal = isnull(Name_cal, ''N/A''),
				   @NumberOfTries = ISNULL(CallbackTries, 0),
				   @IntervalInMinutes = ISNULL(CallbackInterval,0)
			from cctipoCalif_IA where calif_id = @disposition_Id
			IF EXISTS (SELECT 1 FROM ccoCallsOutDispositionIA WHERE call_id = @call_Id)
			BEGIN
				UPDATE ccoCallsOutDispositionIA
				SET Qualification = @Qualification,
					name_cal = @name_cal,
					result = @result,
					Observations = @Observations,
					CapturedData = @CapturedData
				WHERE call_id = @call_Id;
			END
			ELSE
			BEGIN
				INSERT INTO ccoCallsOutDispositionIA (call_id, name_cal, Qualification, result, Observations,CapturedData)
				VALUES (@call_Id, @name_cal, @Qualification, @result, @Observations,@CapturedData);
			END

			IF EXISTS (SELECT 1 FROM cctipoCalif_IA WHERE calif_id = @disposition_Id)
			BEGIN
				DECLARE @callout_id int = 0;
				UPDATE dbo.ccoCallsOut 
				SET 
					calif_id = @disposition_Id
				WHERE cal_id = @call_Id;

				SELECT @callout_id = callout_id,
					   @cam_id = cam_id,
					   @cal_telefono = cal_telefono
				FROM dbo.ccoCallsOut
				WHERE cal_id = @call_Id;
				SELECT @callKey = ISNULL(cal_key,''''),
				   @pendingTriesByDisp = ISNULL(PendingTriesByDisposition,0), 
				   @initialDisposition = ISNULL(DispositionId,0) FROM ccoCallsOutSource WHERE callout_id = @callout_id;

				IF @initialDisposition > 0
				BEGIN
					SELECT @IntervalInMinutes = ISNULL(CallbackInterval, 0)
					FROM cctipoCalif_IA 
					WHERE calif_id = @initialDisposition;
				END


				SET @pendingTriesByDisp = CASE WHEN @pendingTriesByDisp > 0 AND @initialDisposition > 0 THEN @pendingTriesByDisp - 1
											   WHEN @pendingTriesByDisp = 0 AND @initialDisposition = 0 THEN @NumberOfTries - 1
											   WHEN @pendingTriesByDisp = 0 AND @initialDisposition > 0 THEN -1
											   ELSE -1
											   END

				IF(@NumberOfTries > 0 AND @IntervalInMinutes > 0 AND @pendingTriesByDisp >= 0) -- Disposition with reprogramming
				BEGIN
					SET @CallbackAT = DATEADD(mi,@IntervalInMinutes,GETDATE())

					SET @initialDisposition = CASE WHEN @initialDisposition <> 0 THEN @initialDisposition
												   WHEN @initialDisposition = 0 THEN @disposition_Id
											  END

					EXEC ccsp_INInsertaCallBack
					@cal_key = @callKey,
					@cam_id = @cam_id,
					@cal_telefono = @cal_telefono,
					@fechadial = @CallbackAT,
					@dato4 = @result,
					@dato5 = @Observations,
					@NumberOfTries = @pendingTriesByDisp,
					@disposition_Id = @initialDisposition
				END
			END
		END

		ELSE IF @action = 2 AND @status = ''1''   -- Outbound
		BEGIN
			Select @cam_id = cam_id
			From ccoCallsOut
			Where cal_id = @call_Id

			Select @trans_status = IsCallTranscriptionEnabled
			From ccCampsExtend
			Where cam_id  = @cam_id

			if  @trans_status = 1 BEGIN
				IF  EXISTS (SELECT 1 FROM ccoCallsOutTranscriptionIA WHERE call_id = @call_Id)
				BEGIN
					UPDATE ccoCallsOutTranscriptionIA
					SET Transcription = @Transcription
					WHERE call_id = @call_Id;
				END
				ELSE
				BEGIN
					INSERT INTO ccoCallsOutTranscriptionIA (call_id, Transcription)
					VALUES (@call_Id, @Transcription);
				END
			END
		END

		ELSE IF @action = 3  -- Inbound
		BEGIN
			Select @CanReprogram = CanReprogram from dbo.cctipoCalif_IA  where calif_id = @disposition_Id
		
			IF (@CallbackAT IS NOT NULL  
				AND CONVERT(datetime, @CallbackAT, 120) IS NOT NULL 
				AND CONVERT(datetime, @CallbackAT, 120) > GETDATE()  
				AND @CanReprogram <> 0)
			BEGIN
				INSERT INTO ccCallsInDispositionIA (call_id, Qualification, result, Observations, CallbackAT,disposition_id,CapturedData)
				VALUES (@call_Id, @Qualification, @result, @Observations,@CallbackAT,@disposition_Id,@CapturedData);

				SELECT @inbound_id = Inbound_id, @cal_telefono = cal_ANI
					FROM ccCallsIn 
					WHERE cal_id = @call_Id;

				SELECT @cam_id = cam_id
					FROM ccInbound
					WHERE Inbound_id  = @inbound_id

				EXEC ccsp_INInsertaCallBack
					@cal_key = @call_Id,
					@cam_id = @cam_id,
					@cal_telefono = @cal_telefono,
					@fechadial = @CallbackAT,
					@dato4 = @result,
					@dato5 = @Observations

				IF EXISTS (SELECT 1 FROM dbo.cctipoCalif_IA WHERE calif_id = @disposition_Id)
				BEGIN
					UPDATE ccCallsIn
					SET calif_id = @disposition_Id
					WHERE cal_id = @call_Id;
				END
			END

			ELSE BEGIN
				INSERT INTO ccCallsInDispositionIA (call_id, Qualification, result, Observations,disposition_id,CapturedData)
				VALUES (@call_Id, @Qualification, @result, @Observations,@disposition_Id,@CapturedData);

				IF EXISTS (SELECT 1 FROM dbo.cctipoCalif_IA WHERE calif_id = @disposition_Id)
				BEGIN
					UPDATE ccCallsIn
					SET calif_id = @disposition_Id
					WHERE cal_id = @call_Id;
				END
			END

		END

		ELSE IF @action = 4 AND @status = ''1''   -- Inbound
		BEGIN
		
			Select @inbound_id = Inbound_id 
				From ccCallsIn 
				Where cal_id = @call_Id
		
			Select @trans_status = IsCallTranscriptionEnabled
				From ccInboundExtend
				Where Inbound_id  = @inbound_id

			IF @trans_status = 1
			BEGIN
				INSERT INTO ccCallsInTranscriptionIA (call_id, Transcription)
				VALUES (@call_Id, @Transcription);
			END
		END

		ELSE IF @action = 5 -- Get ia call transcription by callId  
		BEGIN
			IF(@CamType = 1)
			BEGIN
				SELECT ccoti.call_id AS CallId ,
					   ccoti.Transcription,
					   ISNULL(ccodi.disposition_id, 0) AS DispositionID ,
					   ISNULL(ccodi.Qualification, '''') AS Qualification,
					   ccodi.result AS DispositionResult
					   FROM dbo.ccoCallsOutTranscriptionIA AS ccoti
					   INNER JOIN dbo.ccoCallsOutDispositionIA AS ccodi
					   ON ccodi.call_id = ccoti.call_id 
				WHERE ccoti.call_id = @call_Id
			END
			ELSE
			BEGIN
				SELECT cciti.call_id AS CallId,
					   cciti.Transcription,
					   ISNULL(ccidi.disposition_id, 0) AS DispositionID ,
					   ISNULL(ccidi.Qualification, '''') AS Qualification,
					   ccidi.result AS DispositionResult
					   FROM dbo.ccCallsInTranscriptionIA AS cciti
					   INNER JOIN dbo.ccCallsInDispositionIA AS ccidi  
					   ON ccidi.call_id = cciti.call_id 
				WHERE cciti.call_id = @call_Id
			END
		END

		ELSE IF @action = 6 -- Get IA Call Model by call_id
		BEGIN
			IF(@CamType = 1)
			BEGIN
				SELECT cva.idAgent AS IdAgent, cva.nameAgent AS NameAgent FROM dbo.ccoCallsOut AS cco
				INNER JOIN dbo.ccVirtualAgent AS cva
				ON cco.virtualAgentId = cva.idAgent
				WHERE cco.cal_id = @call_Id
			END
			ELSE 
			BEGIN
				select cva.idAgent AS IdAgent, cva.nameAgent AS NameAgent FROM dbo.ccCallsIn AS cci
				INNER JOIN dbo.ccVirtualAgent AS cva
				ON cci.virtualAgentId = cva.idAgent
				WHERE cci.cal_id = @call_Id
			END 
		END

	ELSE IF @action = 7 -- Verify if IA data is completely saved (Retry Pattern Flag)
		BEGIN
			DECLARE @IsDataReady BIT = 0;

			IF(@CamType = 1)
			BEGIN
				IF EXISTS (SELECT 1 FROM dbo.ccoCallsOutDispositionIA WHERE call_id = @call_Id)
				BEGIN
					SET @IsDataReady = 1;
				END
			END
			ELSE
			BEGIN
				IF EXISTS (SELECT 1 FROM dbo.ccCallsInDispositionIA WHERE call_id = @call_Id)
				BEGIN
					SET @IsDataReady = 1;
				END
			END

			-- Retornamos el flag
			SELECT @IsDataReady AS IsDataReady;
		END
	END'
	EXEC(@sql);

	SET @process = 'K070407 Drop Procedure [dbo].[ccsp_GalateaAdminDispositions] MAGV ';
	SET @sql = N'
		If Exists (Select 1 From sys.procedures Where name = N''ccsp_GalateaAdminDispositions'')
			Begin
				DROP PROCEDURE ccsp_GalateaAdminDispositions
			End';
	EXEC(@sql);

	SET @process = 'K070407 Se modificó el sp para agregarle cambios referentes a 
	@AplRetryDialing BIT = 0,
			@CallbackTries INT = 0,
			@CallbackInterval INT = 0,
				@DestinationType SMALLINT = null,
			@MaxTransferTime SMALLINT = 0,
			@DestinationCampaign INT = null,
			@DestinationNumber VARCHAR(10) = NULL,
			@DestinationDirectory SMALLINT = null
			para la actualización de las transferencias en las calificaciones MAGV'
	SET  @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
			@command int,
			@calif_id smallint = null,
			@califIdLst varchar(8000) = null,
			@description varchar(150)=null,
			@order tinyint=null,
			@canReprogram bit = null,
			@graphColor varchar(15) = null,
			@endConversation bit=null,
			@keepDial bit=null,
			@autoCB bit=null,
			@contactOwner bit=null,
			@finishPreview bit = 0,
			@allNumbersToBlacklist bit = 0,
			@FinishRecordPreview bit = 0,
			@Name_cal varchar(150) = null,
			@Description_cal varchar(500) = null,
			@ReturnCall smallint = null,
			@AplTransfer bit = 0,
			@TransferOpcion smallint = 0,
			@DestinyIVR bit = 0,
			@DestinyIVR_camp smallint = null,
			@DestinyIVR_number varchar(20) = null,
			@DestinyIVR_directory smallint = null,
			@AplExtDate bit = 0,
			@ExtDescription varchar(100) = null,
			@AplBlackList bit = 0,
			@Cali_StatusIA bit = 1,  
			@DirectoryNumberFlag bit = 1,
			@user_id INT = NULL,
			@type TINYINT = NULL,
			@acdId SMALLINT = NULL,
			@directoryId SMALLINT = NULL,
			/**BEGIN AI retry dialing atributes*/
			@AplRetryDialing BIT = 0,
			@CallbackTries INT = 0,
			@CallbackInterval INT = 0,
			/**END AI retry dialing atributes*/
			/*BEGIN AI transfer disposition*/
			@DestinationType SMALLINT = null,
			@MaxTransferTime SMALLINT = 0,
			@DestinationCampaign INT = null,
			@DestinationNumber VARCHAR(10) = NULL,
			@DestinationDirectory SMALLINT = null
			/*END AI transfer disposition*/


			AS
			set nocount on
			declare @inserted table (ID smallint)

		
			if @command=1 -- Load Inbound Dispositions
			begin
			  Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner, 
			  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd, graphColor
			  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
			  where C.Calif_Status=1
			  group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation, graphColor
			  order by 2
			  return(0)
			end

			If @command=2 -- Load Outbound Dispositions
			begin
			  Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,  
			  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner, 
			  IsNull(C.finishPreview,0) as finishPreview, graphColor, allNumbersToBlacklist, ISNULL(C.FinishRecordPreview,0) as FinishRecordPreview
			  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
			  where C.CalifOut_Status=1
			  group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
			  C.contactOwner, C.finishPreview, graphColor, allNumbersToBlacklist, C.FinishRecordPreview
			  order by 2
			  return(0)
			end

			If @command=3 -- New ccTipoCalif
			begin
			  If exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@description)
				begin
				  select cast(-1 as smallint) [result]  -- Disposition already exists
				  return(0)
				end

			  If exists(select calif_id from ccTipoCalif where Calif_Status=0 and description=@description)
			  begin
				select top 1 @calif_id = calif_id from ccTipoCalif where Calif_Status=0 and description=@description order by calif_id desc
				update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0), 
				graphColor=isnull(@graphColor, ''1DB4E2''), Calif_Status=1
				output inserted.calif_id into @inserted
				where calif_id=@calif_id
				select ID [result] from @inserted 
				return(0)
			  end

			  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , graphColor)
			  output inserted.calif_id into @inserted
			  select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalif
			  select ID [result] from @inserted
			  return(0)
			end

			If @command=4 -- New ccTipoCalifOUT
			begin
			  If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
			  begin
			  select cast(-1 as smallint) [result]  -- Disposition already exists
			  return(0)
			  end

			 If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
			 begin
				select top 1 @calif_id = calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description order by calif_id desc
				update ccTipoCalifOut set autoTime=0, orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), idTipoLista=0,
				Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), 
				finishPreview=isnull(@finishPreview,0), graphColor=isnull(@graphColor, ''1DB4E2''), FinishRecordPreview = isnull(@FinishRecordPreview,0)
				output inserted.calif_id into @inserted
				where calif_id=@calif_id
				select ID [result] from @inserted 
				return(0)
			 end

			 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, graphColor, allNumbersToBlacklist,FinishRecordPreview)
			 output inserted.calif_id into @inserted
			 select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, isnull(@canReprogram,0), isnull(@keepDial,0), 
			 isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, ''1DB4E2''), ISNULL(@allNumbersToBlacklist,0), FinishRecordPreview = isnull(@FinishRecordPreview,0) from ccTipoCalifOut
			 select ID [result] from @inserted 
			 return(0)
			end
			If @command=5 -- Delete Inbound Dispositions
			begin
				delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
				delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
				update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
				return(0)
			end
		   if @command=6 -- Delete Outbound Disposition
	begin
		declare @cams table (cam_id int)

		insert into @cams
		select distinct cam_id
		from ccCalifCamp
		where tipo = 1
		and calif_id in (
			select value from dbo.fn_RIASplitDelimited(@califIdLst, '','')
		)

		-- deletes
		delete from ccCalifCamp 
		where tipo=1 
		and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))

		delete from cctipoSubCalifRel 
		where tipoSubRel=0 
		and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))

		update ccTipoCalifOUT 
		set CalifOut_Status=0 
		where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))

		update ccCamps 
		set keepDial = dbo.fn_keepDial_Camps(cam_id)
		where cam_id in (select cam_id from @cams)

		select 200 as ResponseCode, ''SUCCESS'' as ResponseCodeDescription

	end
			if @command=7 -- Update Inbound Disposition
			begin
				if(exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@Description and calif_id<>@calif_id))
				begin
					select cast(-1 as smallint) [result]    -- Disposition already exists
					return(0)
				end

				UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
				canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  
				EndConversation=isnull(@endConversation,EndConversation)
				output inserted.calif_id into @inserted
				where calif_id=@calif_id

				delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
				tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

				select ID [result] from @inserted
				return(0)
			end
			if @command=8 -- Update Outbound Disposition
			begin
				if(exists(select calif_id from ccTipoCalifOUT where CalifOut_Status=1 and Description=@description and calif_id<>@calif_id))
				begin
					select cast(-1 as smallint) [result]    -- Disposition already exists
					return(0)
				end

				UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
				canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  keepDial=isnull(@keepDial,keepDial), 
				autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner), 
				finishPreview = isnull(@finishPreview,finishPreview), allNumbersToBlacklist = isnull(@allNumbersToBlacklist, allNumbersToBlacklist),  FinishRecordPreview = isnull(@FinishRecordPreview,FinishRecordPreview)
				output inserted.calif_id into @inserted
				where calif_id=@calif_id

				if @keepDial is not null
				begin
					update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
				end

				select ID [result] from @inserted
				return(0) 
				end


			if @command=9 
			begin
				Select 
					C.calif_id, 
					C.Name_cal as Description, 
					C.Description_cal, 
					C.CanReprogram, 
					C.autoCallback as autocallback, 
					C.ReturnCall,
					C.AplTransfer, 
					C.TransferOpcion, 
					C.DestinyIVR, 
					C.DestinyIVR_camp, 
					C.DestinyIVR_number, 
					C.DestinyIVR_directory,
					C.AplExtDate, 
					C.ExtDescription, 
					C.AplBlackList,
					C.Cali_StatusIA as CaliStatusIA,
					C.Color as graphColor,
					C.DirectoryNumberFlag,
					/**BEGIN AI retry dialing atributes*/
					ISNULL(AplRetryDialing, 0) AS AplRetryDialing,
					ISNULL(CallbackTries, 0) AS CallbackTries,
					ISNULL(CallbackInterval,0) AS CallbackInterval,
					/**END AI retry dialing atributes*/
					/*BEGIN AI transfer disposition*/
					ISNULL(ccitc.DestinationTypeId,0) AS DestinationTypeId,
					ISNULL(ccitc.TransferOptionId, 0) AS TransferOptionId,
					ISNULL(ccitc.MaxTransferTime, 0) AS MaxTransferTime,
					ISNULL(ccitc.DestinationCampId, 0) AS DestinationCampId,
					ISNULL(ccitc.DestinationNumber, '''') AS DestinationNumber,
					ISNULL(ccitc.DestinationDirectoryId, 0) AS DestinationDirectoryId
					/*END AI transfer disposition*/
				from cctipoCalif_IA C 
				LEFT JOIN dbo.ccCalif_IA_TransferConfig AS ccitc
				ON ccitc.DispositionId = C.calif_id
				where C.Cali_StatusIA = 1
				order by C.Name_cal
				return(0)
			end
    
		   If @command = 10 -- New ccTipoCalif_IA
					BEGIN
						if @DestinyIVR_number IS NOT NULL AND @DestinyIVR_number <> ''''
							set @DirectoryNumberFlag = 0
						else if @DestinyIVR_directory IS NOT NULL AND @DestinyIVR_directory <> 0
							set @DirectoryNumberFlag = 1

						if exists (select 1 from cctipoCalif_IA where Cali_StatusIA = 1 and Name_cal = @Name_cal)
						begin
							select cast(-1 as smallint) as [result]  
							return(0)
						END
                    
						IF @DestinationType = 1 AND NOT EXISTS (
							SELECT 1 FROM dbo.ccInbound WHERE Inbound_id = @DestinationCampaign
						)
						BEGIN
							SELECT CAST(-3 AS SMALLINT) AS [result];
							RETURN(0)
						END

						if exists (select 1 from cctipoCalif_IA where Cali_StatusIA = 0 and Name_cal = @Name_cal)
						begin
							select top 1 @calif_id = calif_id 
							from cctipoCalif_IA 
							where Cali_StatusIA = 0 and Name_cal = @Name_cal 
							order by calif_id desc

							update cctipoCalif_IA
							set 
								Name_cal              = @Name_cal,
								Description_cal       = @Description_cal,
								CanReprogram          = isnull(@canReprogram, 0),
								autoCallback          = isnull(@autoCB, 0),
								ReturnCall            = @ReturnCall,
								Color                 = isnull(@graphColor, ''1DB4E2''),
								AplTransfer           = isnull(@AplTransfer, 0),
								TransferOpcion        = isnull(@TransferOpcion, 0),
								DestinyIVR            = isnull(@DestinyIVR, 0),
								DestinyIVR_camp       = @DestinyIVR_camp,
								DestinyIVR_number     = @DestinyIVR_number,
								DestinyIVR_directory  = @DestinyIVR_directory,
								AplExtDate            = isnull(@AplExtDate, 0),
								ExtDescription        = @ExtDescription,
								AplBlackList          = isnull(@AplBlackList, 0),
								Cali_StatusIA         = 1,
								DirectoryNumberFlag   = isnull(@DirectoryNumberFlag, 1),
								/**BEGIN AI retry dialing atributes*/
								AplRetryDialing = ISNULL(@AplRetryDialing, 0),
								CallbackTries = ISNULL(@CallbackTries, 0),
								CallbackInterval = ISNULL(@CallbackInterval,0)
								/**END AI retry dialing atributes*/
							output inserted.calif_id into @inserted
							where calif_id = @calif_id


							IF @AplTransfer = 1
							BEGIN
								MERGE dbo.ccCalif_IA_TransferConfig AS target
								USING (SELECT @calif_id AS DispositionId) AS source
								ON (target.DispositionId = source.DispositionId)
								WHEN MATCHED THEN
									UPDATE SET 
										DestinationTypeId = @DestinationType,
										TransferOptionId = @TransferOpcion,
										MaxTransferTime = @MaxTransferTime,
										DestinationCampId = @DestinationCampaign,
										DestinationNumber = @DestinationNumber,
										DestinationDirectoryId = @DestinationDirectory
								WHEN NOT MATCHED THEN
									INSERT (DispositionId, DestinationTypeId, TransferOptionId, MaxTransferTime, DestinationCampId, DestinationNumber, DestinationDirectoryId)
									VALUES (source.DispositionId, @DestinationType, @TransferOpcion, @MaxTransferTime, @DestinationCampaign, @DestinationNumber, @DestinationDirectory);
							END
							ELSE
							BEGIN
								DELETE FROM dbo.ccCalif_IA_TransferConfig WHERE DispositionId = @calif_id;
							END

							select ID [result] from @inserted

							return(0)
						end

						insert into cctipoCalif_IA (
							Name_cal,
							Description_cal,
							CanReprogram,
							autoCallback,
							ReturnCall,
							Color,
							AplTransfer,
							TransferOpcion,
							DestinyIVR,
							DestinyIVR_camp,
							DestinyIVR_number,
							DestinyIVR_directory,
							AplExtDate,
							ExtDescription,
							AplBlackList,
							Cali_StatusIA,
							DirectoryNumberFlag,
							AplRetryDialing,
							CallbackTries,
							CallbackInterval
						)
						output inserted.calif_id into @inserted
						values (
							@Name_cal,
							@Description_cal,
							isnull(@canReprogram, 0),
							isnull(@autoCB, 0),
							@ReturnCall,
							isnull(@graphColor, ''1DB4E2''),
							isnull(@AplTransfer, 0),
							isnull(@TransferOpcion, 0),
							isnull(@DestinyIVR, 0),
							@DestinyIVR_camp,
							@DestinyIVR_number,
							@DestinyIVR_directory,
							isnull(@AplExtDate, 0),
							@ExtDescription,
							isnull(@AplBlackList, 0),
							1,                                  
							isnull(@DirectoryNumberFlag, 1),
							ISNULL(@AplRetryDialing, 0),
							ISNULL(@CallbackTries, 0),
							ISNULL(@CallbackInterval, 0)
						)

						SELECT TOP 1 @calif_id = ID FROM @inserted ORDER BY ID DESC

						IF @AplTransfer = 1
						BEGIN
							INSERT INTO dbo.ccCalif_IA_TransferConfig
							(
								DispositionId,
								DestinationTypeId,
								TransferOptionId,
								MaxTransferTime,
								DestinationCampId,
								DestinationNumber,
								DestinationDirectoryId
							)
							VALUES
							(   @calif_id,  -- DispositionId - smallint
								@DestinationType,  -- DestinationTypeId - smallint
								@TransferOpcion,  -- TransferOptionId - smallint
								@MaxTransferTime,  -- MaxTransferTime - smallint
								@DestinationCampaign,  -- DestinationCampId - int
								@DestinationNumber, -- DestinationNumber - varchar(10)
								@DestinationDirectory   -- DestinationDirectoryId - smallint
								)
						END

						select ID [result] from @inserted

				
						return(0)
					end
    
				-- Comando 11: DELETE_IA_BOUND_DISPOSITION
				if @command=11 -- Delete IA Bound Disposition
				BEGIN
					delete from ccCalifCamp where tipo=2 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
					delete from cctipoSubCalifRel where tipoSubRel=2 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
					update ccTipoCalif_IA set Cali_StatusIA=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
					-- Agregar aquí cualquier limpieza adicional específica para IA si es necesario
					return(0)
				end
    
				if @command=12 -- Update IA Bound Disposition
					BEGIN
						if(exists(select calif_id from ccTipoCalif_IA where Cali_StatusIA=1 and Name_cal=@Name_cal and calif_id<>@calif_id))
						begin
							select cast(-1 as smallint) [result]    -- Disposition already exists
							return(0)
						END
                    
						IF @DestinationType = 1 AND NOT EXISTS (
							SELECT 1 FROM dbo.ccInbound WHERE Inbound_id = @DestinationCampaign
						)
						BEGIN
							SELECT CAST(-3 AS SMALLINT) AS [result];
							RETURN(0)
						END

						if @DestinyIVR_number IS NOT NULL AND @DestinyIVR_number <> ''''
							set @DirectoryNumberFlag = 0
						else if @DestinyIVR_directory IS NOT NULL AND @DestinyIVR_directory <> 0
							set @DirectoryNumberFlag = 1

						UPDATE ccTipoCalif_IA set Name_cal=isnull(@Name_cal, Name_cal), Description_cal=isnull(@Description_cal, Description_cal),
						CanReprogram=isnull(@canReprogram, CanReprogram), Color=isnull(@graphColor, Color), autoCallback=isnull(@autoCB, autoCallback),
						ReturnCall=isnull(@ReturnCall, ReturnCall), AplTransfer=@AplTransfer, TransferOpcion=@TransferOpcion,
						DestinyIVR=@DestinyIVR, DestinyIVR_camp=@DestinyIVR_camp,
						DestinyIVR_number=@DestinyIVR_number, DestinyIVR_directory=@DestinyIVR_directory,
						AplExtDate=@AplExtDate, ExtDescription=@ExtDescription, DirectoryNumberFlag=isnull(@DirectoryNumberFlag, DirectoryNumberFlag),
						AplBlackList=@AplBlackList, Cali_StatusIA=isnull(@Cali_StatusIA, Cali_StatusIA),
						/**BEGIN AI retry dialing */
						AplRetryDialing = ISNULL(@AplRetryDialing, 0),
						CallbackTries = ISNULL(@CallbackTries, 0),
						CallbackInterval = ISNULL(@CallbackInterval, 0)
						/**END AI retry dialing */
						output inserted.calif_id into @inserted
						where calif_id=@calif_id

						IF (@AplTransfer = 1)
						BEGIN
							MERGE dbo.ccCalif_IA_TransferConfig AS target
							USING (SELECT @calif_id AS DispositionId) AS source
							ON (target.DispositionId = source.DispositionId)
                        
							WHEN MATCHED THEN
								UPDATE SET 
									TransferOptionId = @TransferOpcion,
									DestinationTypeId = @DestinationType,
									DestinationNumber = @DestinationNumber,
									DestinationCampId = @DestinationCampaign,
									DestinationDirectoryId = @DestinationDirectory,
									MaxTransferTime = @MaxTransferTime 
                                
							WHEN NOT MATCHED THEN
								INSERT (DispositionId, DestinationTypeId, TransferOptionId, MaxTransferTime, DestinationCampId, DestinationNumber, DestinationDirectoryId)
								VALUES (source.DispositionId, @DestinationType, @TransferOpcion, @MaxTransferTime, @DestinationCampaign, @DestinationNumber, @DestinationDirectory);
						END
						ELSE
						BEGIN
							DELETE FROM dbo.ccCalif_IA_TransferConfig 
							WHERE DispositionId = @calif_id;
						END


						select ID [result] from @inserted
						return(0)
					end

	IF @command = 13  -- DELETE IA
	BEGIN  
		BEGIN TRY  
			-- 0. Validación inicial
			IF @califIdLst IS NULL OR LTRIM(RTRIM(@califIdLst)) = ''''
			BEGIN
				SELECT -10 AS ResponseCode,
					   ''califIdLst is empty'' AS ResponseCodeDescription,
					   '''' AS CalifIdLst
				RETURN
			END

			DECLARE @Ids TABLE (calif_id INT)  
			DECLARE @Active TABLE (calif_id INT)  
			DECLARE @ToDelete TABLE (calif_id INT)  

			-- 1. Parseo de IDs
			INSERT INTO @Ids  
			SELECT TRY_CAST(value AS INT)  
			FROM dbo.fn_RIASplitDelimited(@califIdLst, '','')  
			WHERE TRY_CAST(value AS INT) IS NOT NULL

			IF NOT EXISTS (SELECT 1 FROM @Ids)
			BEGIN
				SELECT -11 AS ResponseCode,
					   ''No valid IDs received'' AS ResponseCodeDescription,
					   '''' AS CalifIdLst
				RETURN
			END

			-- 2. Detectar activos (solo campañas ACTIVAS)
			INSERT INTO @Active  
			SELECT DISTINCT c.calif_id  
			FROM ccCalifCampIA c  
			INNER JOIN @Ids i ON i.calif_id = c.calif_id  
			WHERE 
			(
				c.tipo = 1 AND EXISTS (
					SELECT 1 
					FROM ccCamps o
					WHERE o.cam_id = c.cam_id 
					  AND o.cam_procesando = 1
				)
			)
			OR
			(
				c.tipo = 0 AND EXISTS (
					SELECT 1 
					FROM ccInbound ib
					WHERE ib.Inbound_id = c.cam_id 
					  AND ib.Status = 1
				)
			)

			-- 3. Determinar eliminables
			INSERT INTO @ToDelete  
			SELECT i.calif_id 
			FROM @Ids i
			LEFT JOIN @Active a ON i.calif_id = a.calif_id
			WHERE a.calif_id IS NULL

			-- 4. Si TODOS están activos → NO borrar nada
			IF NOT EXISTS (SELECT 1 FROM @ToDelete)
			BEGIN  
				SELECT 
					-27 AS ResponseCode,  
					''All dispositions are active in campaigns.'' AS ResponseCodeDescription,
					'''' AS CalifIdLst
				RETURN  
			END  

			-- 5. ELIMINACIÓN REAL
			UPDATE cctipoCalif_IA  
			SET Cali_StatusIA = 0  
			WHERE calif_id IN (SELECT calif_id FROM @ToDelete)  

			DELETE FROM ccCalifCampIA  
			WHERE calif_id IN (SELECT calif_id FROM @ToDelete)  

			-- 6. LOG
			IF EXISTS (SELECT 1 FROM @ToDelete)
			BEGIN
							INSERT INTO ccGalateaActivityLog
	(Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
	SELECT   
		ISNULL((
			SELECT TOP 1 AreaName FROM ccRIACat_Areas
		), ''Default''),

		GETDATE(),  
		(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),  
		177,  
		7,  

		'''',             

		c.Name_cal,  

		''IA Disposition Delete''  
	FROM cctipoCalif_IA c  
	WHERE calif_id IN (SELECT calif_id FROM @ToDelete)
			END

			-- 7. RESPUESTA

			-- Parcial
			IF EXISTS (SELECT 1 FROM @Active)
			BEGIN  
				SELECT 
					-28 AS ResponseCode,  
					''Partial Success. Some dispositions are active.'' AS ResponseCodeDescription,
			STUFF((
				SELECT '','' + CAST(td.calif_id AS VARCHAR(20))
				FROM @ToDelete td
				FOR XML PATH(''''), TYPE
			).value(''.'', ''VARCHAR(MAX)''), 1, 1, '''') AS CalifIdLst
				RETURN  
			END  

			-- Éxito total
			SELECT 
				200 AS ResponseCode,  
				''SUCCESS'' AS ResponseCodeDescription,
		STUFF((
			SELECT '','' + CAST(td.calif_id AS VARCHAR(20))
			FROM @ToDelete td
			FOR XML PATH(''''), TYPE
		).value(''.'', ''VARCHAR(MAX)''), 1, 1, '''') AS CalifIdLst

		END TRY  
		BEGIN CATCH  
			SELECT 
				-1 AS ResponseCode,  
				ERROR_MESSAGE() AS ResponseCodeDescription,
				'''' AS CalifIdLst
		END CATCH  
	END

	IF @command = 14 
	BEGIN 
	SELECT Name_cal AS [Name],
		   Description_cal AS [Description],
		   CanReprogram AS Reprogram,
		   autoCallback AS Callback,
		   Color AS Color,
		   ISNULL(AplTransfer, 0) AS [Transfer],
		   ISNULL(TransferOpcion, 0) AS TransferOption,
		   ISNULL(DestinyIVR, 0) AS DestinyDropDown,
		   DestinyIVR_camp AS DestinyCamp,
		   ISNULL(DirectoryNumberFlag, 0) AS NumberDropDown,
		   DestinyIVR_number AS DestinyNumber,
		   DestinyIVR_directory AS DestinyDirectory,
		   ISNULL(AplExtDate, 0) AS Extraction,
		   ExtDescription AS ExtractionDescription,
		   ISNULL(AplBlackList, 0) AS DNC,
		   /**BEGIN AI retry dialing */
		   ISNULL(AplRetryDialing, 0) AS  AplRetryDialing,
		   ISNULL(CallbackTries, 0) AS CallbackTries,
		   ISNULL(CallbackInterval, 0) AS CallbackInterval,
		   /**END AI retry dialing*/
		   /*BEGIN AI transfer disposition*/
		   ISNULL(ccitc.DestinationTypeId,0) AS DestinationTypeId,
		   ISNULL(ccitc.TransferOptionId, 0) AS TransferOptionId,
		   ISNULL(ccitc.MaxTransferTime, 0) AS MaxTransferTime,
		   ISNULL(ccitc.DestinationCampId, 0) AS DestinationCampId,
		   ISNULL(ccitc.DestinationNumber, '''') AS DestinationNumber,
		   ISNULL(ccitc.DestinationDirectoryId, 0) AS DestinationDirectoryId
		   /*END AI transfer disposition*/

	FROM cctipoCalif_IA 
	LEFT JOIN dbo.ccCalif_IA_TransferConfig AS ccitc
	ON ccitc.DispositionId = cctipoCalif_IA.calif_id
	WHERE calif_id = @calif_id
	END


	IF @command = 15 
	BEGIN 
		select descripcion from ccinbound where inbound_id = @acdId
	END

	IF @command = 16
	BEGIN 
		SELECT tel FROM dbo.telefonosTransferencia where numtra_id = @directoryId 
	END

	SET NOCOUNT OFF 
	'
	EXEC(@sql);


	SET @process = 'KM020000 Drop Procedure [dbo].[ccsp_GalateaDeleteCampaignAndACD] MAGV';
	SET @sql = N'
		If Exists (Select 1 From sys.procedures Where name = N''ccsp_GalateaDeleteCampaignAndACD'')
			Begin
				DROP PROCEDURE ccsp_GalateaDeleteCampaignAndACD
			End';
	EXEC(@sql);

	SET @process = 'KM020000 Se modificó el para que al eliminar la campaña tambien se quite la relación que haya con calificaciones ia MAGV'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaDeleteCampaignAndACD]
		@userId           SMALLINT,
		@DeleteCamId      VARCHAR(MAX),
		@DeleteACDGroupId VARCHAR(MAX),
		@moduleId         SMALLINT = 49
	AS
	BEGIN

		IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete;
		SELECT value As DeleteCamId, c.IDArea AS IDAreaCamp, 1 AS CampTypeCamp, ISNULL(wg.IDWG,0) as IDWG, ISNULL(c.CampType, 0) AS MediaType
		INTO #CampsDelete
		FROM fn_RIASplitDelimited(@DeleteCamId, '','') a
		inner join ccCamps c on  a.value = c.cam_id and c.IDArea IS NOT NULL
		left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=1;

		IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete;
		SELECT value As DeleteACDId, c.IDArea AS IDAreaACD, 0 AS CampTypeACD, ISNULL(wg.IDWG,0) as IDWG, cast(ISNULL(chat, 0) as int) AS MediaType
		INTO #ACDDelete
		FROM fn_RIASplitDelimited(@DeleteACDGroupId, '','') a
		inner join ccInbound c on  a.value = c.Inbound_id and c.IDArea IS NOT NULL
		left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=0;

		DECLARE @DispositionsDeleted TABLE (DispositionId INT);

		IF  not Exists (select * from #CampsDelete union select * from #ACDDelete )
		begin
			select ''-1'' AS Result
			return
		end

		IF datalength(@DeleteCamId) > 0
		BEGIN

			if exists(select cam_id from ccInbound where cam_id in (select DeleteCamId from #CampsDelete)) begin
				--Borra las calificacion con reprogramacion
				delete ccCalifCamp from ccInbound A
				inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
				inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
				where A.cam_id in (select DeleteCamId from #CampsDelete)
				--Borra las subcalificacion con reprogramacion
				delete rel from ccInbound A
				inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
				inner join ccTipoCalif C on B.calif_id=C.calif_id
				inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
				inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
				where A.cam_id in (select DeleteCamId from #CampsDelete) and sb.canReprogram=1

				update ccInbound set cam_id = null where cam_id in (select DeleteCamId from #CampsDelete)

			end

			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
			select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete)

			delete from ccCampsAgente where cam_id in (select DeleteCamId from #CampsDelete)
			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
			select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete) and A.tipo = 1

			delete from ccSupervisorCam where cam_id in (select DeleteCamId from #CampsDelete) and tipo = 1
			delete from ccRIACampEspWG where IdCampEsp in (select DeleteCamId from #CampsDelete) and tipo = 1


			DELETE FROM dbo.ccCalifCampIA WHERE cam_id IN (SELECT DeleteCamId FROM #CampsDelete) AND tipo = 1


			IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog;
			SELECT ca.AreaName,
					GETDATE() operationDate,
					27 operationType,
					(SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
					@moduleId module_id,
					c.cam_descripcion value,
					ca.AreaName AS target
			INTO #CampLog
			FROM ccRIACat_Areas ca
			Inner join ccCamps c with(nolock) on ca.IDArea = c.IDArea
			WHERE c.cam_id in (select DeleteCamId from #CampsDelete)

			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
			SELECT A.AreaName, GETDATE(), (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
			CASE
				WHEN CampType = 6 THEN 45
				WHEN CampType = 5 THEN 47
				WHEN CampType = 9 THEN 49
				WHEN CampType = 7 THEN 51
			ELSE 43 END,
			3,
			'''',
			'''',
			c.cam_descripcion
			FROM ccRIACat_Areas A INNER JOIN ccCamps c on A.IDArea = c.IDArea
			where c.cam_id in (select DeleteCamId from #CampsDelete)

			Update ccCamps set IDArea = null where cam_id in (select DeleteCamId from #CampsDelete)

			update contactMeanOut set name = '''', conexionInfo = '''', connUser = '''', isActive = 0
			where camp_id in (SELECT DeleteCamId FROM #CampsDelete) and meanContactTypeId=5

			update ccWhatsAppNumbers set camp_id = 0 where camp_id in (select DeleteCamId from #CampsDelete)

			update ccMetaWhatsAppNumbers set Cam_Id = 0 where Cam_Id in (select DeleteCamId from #CampsDelete)

		END

		IF datalength(@DeleteACDGroupId) > 0
		BEGIN

			if exists(select top 1 cam_id from ccInbound where Inbound_id in (select DeleteACDId from #ACDDelete))
			begin
					update ccInbound set cam_id = null where Inbound_id in (select DeleteACDId from #ACDDelete)
			end

			IF OBJECT_ID(''tempdb..#AllWGACD'') IS NOT NULL DROP TABLE #AllWGACD;
			SELECT DISTINCT(IDWG)
			INTO #AllWGACD
			FROM ccRIACampEspWG ce
			WHERE IDCampEsp in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0

			insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
			select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG
			from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id
			where B.User_id is null and A.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

			delete ccInboundHorarios Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
			delete ccInboundMsgs Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
			delete ccInboundDnis where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
			select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG
			from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id
			where B.User_id is null and A.cam_id in (SELECT DeleteACDId FROM #ACDDelete)

			delete ccSupervisorCam where cam_id in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0
			delete ccInboundAgentes where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
			delete ccRIACampEspWG where IdCampEsp  in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0

		

			DELETE FROM dbo.ccCalif_IA_TransferConfig
			OUTPUT deleted.DispositionId INTO @DispositionsDeleted 
			WHERE DestinationCampId IN (SELECT DeleteACDId FROM #ACDDelete);

			UPDATE dbo.cctipoCalif_IA 
			SET AplTransfer = 0 
			WHERE calif_id IN (SELECT DispositionId FROM @DispositionsDeleted);

			DELETE FROM dbo.ccCalifCampIA WHERE calif_id IN (SELECT DispositionId FROM @DispositionsDeleted)
			DELETE FROM dbo.ccCalifCampIA WHERE cam_id IN (SELECT DeleteACDId FROM #ACDDelete) AND tipo = 0;

			IF OBJECT_ID(''tempdb..#ACDLog'') IS NOT NULL DROP TABLE #ACDLog;
			SELECT ca.AreaName,
					GETDATE() operationDate,
					28 operationType,
					(SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
					@moduleId module_id,
					i.descripcion value,
					ca.AreaName AS target
			INTO #ACDLog
			FROM ccRIACat_Areas ca
			inner join ccInbound i with(nolock) on ca.IDArea = i.IDArea
			WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
			SELECT a.AreaName, GETDATE(), (SELECT [Login] FROM ccUsers WHERE User_id = @userId),
			CASE
				WHEN chat = 5 THEN 41
				WHEN chat = 1 THEN 65
				WHEN chat = 11 THEN 156
				ELSE 61 END,
			3,
			'''',
			'''',
			i.descripcion
			FROM ccRIACat_Areas a inner join ccInbound i on a.IDArea = i.IDArea
			WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

			Update ccInbound set IDArea = null, cam_id = null, status = 0 where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

			if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))
				begin
					update ContactMeanIn set name = '''', conexionInfo = ''usuarioID|token|tokenSecret|1|0'', connUser = '''', isActive = 0
					where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=2
			end
			if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))
				begin
					update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=1
			end
			update ccinbound set chatDomain = '''' where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

			if exists (SELECT inboundId FROM contactMeanIn WHERE inboundId in (select DeleteACDId from #ACDDelete))
				begin
					update contactMeanIn set isActive = 0 where inboundId in (select DeleteACDId from #ACDDelete)
			end
			update ccWhatsAppNumbers set inboundId = 0 where inboundId in (select DeleteACDId from #ACDDelete)

			update ccMetaWhatsAppNumbers set Inbound_Id = 0 where Inbound_Id in (select DeleteACDId from #ACDDelete)

		END

		IF datalength(@DeleteCamId) > 0
			Insert into ccRIALog Select * from #CampLog
		IF datalength(@DeleteACDGroupId) > 0
			Insert into ccRIALog Select * from #ACDLog

		SELECT DeleteCamId AS DeleteId,IDAreaCamp AS IDArea,CampTypeCamp AS CampType,''1'' AS Result, cast(IDWG as smallint) IDWG, MediaType FROM #CampsDelete
		UNION
		SELECT DeleteACDId,IDAreaACD,CampTypeACD,''1'' AS Result, cast(IDWG as smallint) IDWG, MediaType FROM #ACDDelete

		IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
		IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
		IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
	END'
	EXEC(@sql);

	SET @process = 'K070406 Drop Procedure [dbo].[ccsp_GalateaAdminDispositionRelations] MAGV';
	SET @sql = N'
		If Exists (Select 1 From sys.procedures Where name = N''ccsp_GalateaAdminDispositionRelations'')
			Begin
				DROP PROCEDURE ccsp_GalateaAdminDispositionRelations
			End';
	EXEC(@sql);

	SET @process = 'K070406 Se modificó el option @command = 6, para que ya no valide transferencia exitosa o por no entendimiento MAGV'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminDispositionRelations]
	@command INT,
	@type TINYINT = NULL, --0=In, 1=Out
	@cam_id SMALLINT = NULL,
	@califIdLst VARCHAR(8000) = NULL,
	@user_id SMALLINT = NULL,
	@operationId INT = NULL,
	@model_id SMALLINT = NULL
	AS
	set nocount on
	declare @sql as nvarchar(max)

	If @command = 1
	begin
		select 
			cast (0 as int) [type], 
			i.inbound_id as cam_id, 
			c.calif_id 
		from ccInbound i inner join ccCalifCamp c on i.inbound_id = c.cam_id and c.tipo = 0
		inner join ccTipoCalif t on c.calif_id = t.calif_id
		UNION
		select 
			cast (1 as int) [type], 
			o.cam_id, 
			c.calif_id 
		from ccCamps o inner join ccCalifCamp c on o.cam_id = c.cam_id and c.tipo = 1
		inner join ccTipoCalifOUT co on c.calif_id = co.calif_id
		order by [type], cam_id, calif_id
	end
	IF @command=2  -- Assign disposition to inbound or outbound campaign
	 BEGIN 
		IF @Type=0 
		begin	
			set @sql = ''declare @NotAssigned table(NotAssigned int); 
			declare @Assigned table(Assigned int);

			insert into @NotAssigned (NotAssigned)
			select calif_id from ccTipoCalif where CanReprogram=1 and calif_id in ('' + @califIdLst + '')
			and exists(select inbound_id from ccInbound where cam_id is null and Inbound_id= '' + cast(@cam_id as varchar(10)) + '')

			insert into ccCalifCamp(calif_id,cam_id,tipo) 
			select f.calif_id, e.inbound_id, 0 
			from ccInbound e, cctipoCalif f 
			where f.Calif_Status=1 and f.calif_id in ('' + @califIdLst + '') and f.calif_id not in (select NotAssigned from @NotAssigned)
			and Inbound_id = '' + cast(@cam_id as varchar(10)) + ''
			and not exists(
				select a.calif_id,c.inbound_id,0 from cctipoCalif a
				join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 0
				join ccInbound c on c.inbound_id = b.cam_id
				where f.calif_id = a.calif_id and e.inbound_id = c.inbound_id
				and c.Inbound_id = '' + cast(@cam_id as varchar(10)) + '')

			insert into @Assigned (Assigned)
			select calif_id from ccTipoCalif where calif_id in ('' + @califIdLst + '') and calif_id not in (select NotAssigned from @NotAssigned)

			declare @NotAssignedStr varchar(8000), @AssignedStr varchar(8000)
			SELECT @AssignedStr = COALESCE(@AssignedStr + '''','''', '''''''') + cast(Assigned as varchar(10)) from @Assigned
			select @NotAssignedStr = coalesce(@NotAssignedStr + '''','''', '''''''') + cast(NotAssigned as varchar(10)) from @NotAssigned

			select @AssignedStr [Assigned], @NotAssignedStr [NotAssigned]''
			EXECUTE sp_executesql @sql
		END
		ELSE
		BEGIN
			SET @sql = ''insert into ccCalifCamp(calif_id,cam_id,tipo) 
			select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalifOUT f where 
			f.CalifOut_Status=1 and f.calif_id in ('' + @califIdLst + '') and cam_id = '' + CAST(@cam_id AS VARCHAR(10)) + ''
			and not exists(
			select a.calif_id,c.cam_id, 1 from cctipoCalifOUT a
			join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 1
			join ccCamps c on c.cam_id = b.cam_id
			where f.calif_id = a.calif_id and e.cam_id = c.cam_id
			and b.cam_id = '' + CAST(@cam_id AS VARCHAR(10)) + '')''
			EXECUTE sp_executesql @sql
			UPDATE ccCamps SET keepDial=dbo.fn_keepDial_Camps(@cam_id) WHERE cam_id=@cam_id	
			RETURN(0)
		END
	 END
	 IF @command=3 -- Unassign disposition to inbound or outbound
	 BEGIN
		DELETE ccCalifCamp WHERE cam_id=@cam_id AND tipo=@type AND calif_id IN (SELECT value FROM dbo.fn_RIASplitDelimited(@califIdLst, '',''))
		UPDATE ccCamps SET keepDial=dbo.fn_keepDial_Camps(@cam_id) WHERE cam_id=@cam_id
		RETURN(0)
	 END
	 IF @command=4 
	 BEGIN
		IF(@type = 0) 
		BEGIN
			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
			SELECT 
				(SELECT AreaName FROM ccRIACat_Areas c INNER JOIN ccInbound i ON c.IDArea = i.IDArea WHERE Inbound_id = @cam_id),
				GETDATE(),
				(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
				68,
				7,
				'''',
				Description,
				(SELECT descripcion FROM ccInbound WHERE Inbound_id = @cam_id)
				FROM ccTipoCalif 
				WHERE calif_id IN (SELECT value FROM dbo.fn_RIASplitDelimited(@califIdLst, '',''))
		END
	 END
	 IF @command=5
	 BEGIN
		IF(@type = 0) 
		BEGIN
			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
			SELECT 
				(SELECT AreaName FROM ccRIACat_Areas c INNER JOIN ccInbound i ON c.IDArea = i.IDArea WHERE Inbound_id = @cam_id),
				GETDATE(),
				(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
				69,
				7,
				'''',
				Description,
				(SELECT descripcion FROM ccInbound WHERE Inbound_id = @cam_id)
				FROM ccTipoCalif 
				WHERE calif_id IN (SELECT value FROM dbo.fn_RIASplitDelimited(@califIdLst, '',''))
		END
	 END
	 IF @command = 6 -- Assign dispositions to inbound or outbound AI campaign
	 BEGIN
 		if @Type=0 
		begin	
			set @sql = ''declare @NotAssigned table(NotAssigned int); 
			declare @Assigned table(Assigned int);

			insert into @NotAssigned (NotAssigned)
			SELECT calif_id 
			FROM cctipoCalif_IA MAIN
			WHERE MAIN.calif_id IN (''+ @califIdLst+ '')
			AND EXISTS (
				SELECT 1 
				FROM ccInbound I
				WHERE I.Inbound_id = '' + cast(@cam_id as varchar(10)) + ''
				AND (
					------------------------------------------------------------
					-- Rescheduling / Callback Validation
					-- If rescheduling is required, it MUST have a cam_id.
					------------------------------------------------------------
					(MAIN.CanReprogram = 1 OR MAIN.autoCallback = 1) 
					AND 
					(I.cam_id IS NULL OR I.cam_id = 0)
				)
			)

			insert into ccCalifCampIA(calif_id,cam_id,tipo) 
			select f.calif_id, e.inbound_id, 0 
			from ccInbound e, cctipoCalif_IA f 
			where f.Cali_StatusIA=1 and f.calif_id in ('' + @califIdLst + '') and f.calif_id not in (select NotAssigned from @NotAssigned)
			and Inbound_id = '' + cast(@cam_id as varchar(10)) + ''
			and not exists(
				select a.calif_id,c.inbound_id,0 from cctipoCalif a
				join ccCalifCampIA b on a.calif_id = b.calif_id and tipo = 0
				join ccInbound c on c.inbound_id = b.cam_id
				where f.calif_id = a.calif_id and e.inbound_id = c.inbound_id
				and c.Inbound_id = '' + cast(@cam_id as varchar(10)) + '')

			insert into @Assigned (Assigned)
			select calif_id from cctipoCalif_IA where calif_id in ('' + @califIdLst + '') and calif_id not in (select NotAssigned from @NotAssigned)

			declare @NotAssignedStr varchar(8000), @AssignedStr varchar(8000)
			SELECT @AssignedStr = COALESCE(@AssignedStr + '''','''', '''''''') + cast(Assigned as varchar(10)) from @Assigned
			select @NotAssignedStr = coalesce(@NotAssignedStr + '''','''', '''''''') + cast(NotAssigned as varchar(10)) from @NotAssigned

			select @AssignedStr [Assigned], @NotAssignedStr [NotAssigned], cast(1 as bit) as IsAICamp''
			execute sp_executesql @sql
			return(0)
		end
		else
		begin
			set @sql = ''insert into ccCalifCampIA(calif_id,cam_id,tipo) 
			select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalif_IA f where 
			f.Cali_StatusIA=1 and f.calif_id in ('' + @califIdLst + '') and cam_id = '' + cast(@cam_id as varchar(10)) + ''
			and not exists(
			select a.calif_id,c.cam_id, 1 from cctipoCalif_IA a
			join ccCalifCampIA b on a.calif_id = b.calif_id and tipo = 1
			join ccCamps c on c.cam_id = b.cam_id
			where f.calif_id = a.calif_id and e.cam_id = c.cam_id
			and b.cam_id = '' + cast(@cam_id as varchar(10)) + '')''
			execute sp_executesql @sql
			return(0)
		end
	 END
	 IF @command = 7 -- Unassign dispositions to inbound or outbound AI campaign
	 BEGIN 
		delete ccCalifCampIA WHERE cam_id=@cam_id and tipo=@type and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
		return(0)
	 END
	 If @command = 8
	begin
		select 
			cast (0 as int) [type], 
			i.inbound_id as cam_id, 
			c.calif_id 
		from ccInbound i inner join dbo.ccCalifCampIA AS c on i.inbound_id = c.cam_id and c.tipo = 0
		inner join dbo.cctipoCalif_IA AS t on c.calif_id = t.calif_id
		UNION
		select 
			cast (1 as int) [type], 
			o.cam_id, 
			c.calif_id 
		from ccCamps o inner join ccCalifCampIA c on o.cam_id = c.cam_id and c.tipo = 1
		inner join cctipoCalif_IA co on c.calif_id = co.calif_id
		order by [type], cam_id, calif_id
	END
	IF @command = 9 -- Registry AI dispositions log to assign/unassign
	BEGIN
		IF(@type = 0)
		BEGIN 
			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
			SELECT 
				(select AreaName from ccRIACat_Areas c inner join ccInbound i on c.IDArea = i.IDArea where Inbound_id = @cam_id),
				getDate(),
				(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
				@operationId,
				7,
				'''',
				Name_cal,
				(select descripcion from ccInbound where Inbound_id = @cam_id)
				from cctipoCalif_IA 
				where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
		END
		ELSE
		BEGIN
			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
			SELECT 
				(select AreaName from dbo.ccRIACat_Areas AS crca inner join dbo.ccCamps AS cc  on crca.IDArea = cc.IDArea where cc.cam_id = @cam_id),
				getDate(),
				(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
				@operationId,
				7,
				'''',
				Name_cal,
				(select cam_descripcion from dbo.ccCamps  where cam_id = @cam_id)
				from cctipoCalif_IA 
				where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
		end
	END
	IF @command = 10  -- DELETE IA  
	BEGIN  
		BEGIN TRY  
  
			DECLARE @Ids TABLE (calif_id INT)  
			DECLARE @Active TABLE (calif_id INT)  
			DECLARE @ToDelete TABLE (calif_id INT)  
  
			-- IDs enviados  
			INSERT INTO @Ids  
			SELECT CAST(value AS INT)  
			FROM dbo.fn_RIASplitDelimited(@califIdLst, '','')  
  
			-- Detectar campañas activas  
			INSERT INTO @Active  
			SELECT DISTINCT c.calif_id  
			FROM ccCalifCampIA c  
			INNER JOIN @Ids i ON i.calif_id = c.calif_id  
			LEFT JOIN ccCamps o ON o.cam_id = c.cam_id AND c.tipo = 1  
			LEFT JOIN ccInbound ib ON ib.Inbound_id = c.cam_id AND c.tipo = 0  
			WHERE   
				(c.tipo = 1 AND o.cam_procesando = 1)  
				OR  
				(c.tipo = 0 AND ib.Status = 1)  
  
			-- Si todos están activos  
			IF (SELECT COUNT(*) FROM @Ids) = (SELECT COUNT(*) FROM @Active)  
			BEGIN  
				SELECT -27 AS ResponseCode,  
					   ''All dispositions are active in campaigns.'' AS ResponseCodeDescription  
				RETURN  
			END  
  
			-- Determinar cuáles sí se pueden borrar  
			INSERT INTO @ToDelete  
			SELECT calif_id FROM @Ids  
			WHERE calif_id NOT IN (SELECT calif_id FROM @Active)  
  
			-- Eliminación lógica  
			UPDATE cctipoCalif_IA  
			SET Cali_StatusIA = 0  
			WHERE calif_id IN (SELECT calif_id FROM @ToDelete)  
  
			-- Eliminar relaciones  
			DELETE FROM ccCalifCampIA  
			WHERE calif_id IN (SELECT calif_id FROM @ToDelete)  
  
			-- Log por cada nombre eliminado  
			INSERT INTO ccGalateaActivityLog  
			(Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)  
			SELECT   
				NULL,  
				GETDATE(),  
				(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),  
		  177,  
				7,  
				'''',  
				Name_cal,  
				''IA Disposition Delete''  
			FROM cctipoCalif_IA  
			WHERE calif_id IN (SELECT calif_id FROM @ToDelete)  
  
			-- Si hubo algunas activas / parcial  
			IF EXISTS (SELECT 1 FROM @Active)  
			BEGIN  
				SELECT -28 AS ResponseCode,  
					   ''Partial Success. Some dispositions are active.'' AS ResponseCodeDescription  
				RETURN  
			END  
  
			-- Todo correcto  
			SELECT 200 AS ResponseCode,  
				   ''SUCCESS'' AS ResponseCodeDescription  
  
		END TRY  
		BEGIN CATCH  
			SELECT -1 AS ResponseCode,  
				   ERROR_MESSAGE() AS ResponseCodeDescription  
		END CATCH  
	END  

	IF @command = 11  -- Calificaciones de Modelo IA  
	BEGIN  
		BEGIN TRY
			DECLARE
			@IAModeloId INT = @model_id,
			@Camp_Id INT,
			@Camp_Type INT

			-- 1. Validar si existe el agente virtual y obtener su campaña
			SELECT
				@IAModeloId = v.idAgent,
				@Camp_Id = v.idCampaign, 
				@Camp_Type = v.campType
			FROM ccVirtualAgent AS v
			WHERE idAgent = @IAModeloId

			-- EXCEPCIÓN 1: El modelo no está asociado a una campaña
			IF @Camp_Id IS NULL OR @Camp_Id = 0
			BEGIN
				-- Retornamos una tabla de control con el código de error exacto
				SELECT ''ERROR_MODEL_WITHOUT_ASSOCIATED_CAMPAIGN'' AS ControlCode
				RETURN;
			END

			-- 2. Si tiene campaña, procedemos a validar/extraer calificaciones según el tipo
			IF @Camp_Type = 0
			BEGIN
				-- Validar si la campaña tiene calificaciones antes de hacer el JOIN completo
				IF NOT EXISTS (SELECT 1 FROM dbo.ccCalifCampIA WHERE cam_id = @Camp_Id AND tipo = @Camp_Type)
				BEGIN
					SELECT ''ERROR_CAMPAIGN_WITHOUT_DISPOSITIONS'' AS ControlCode
					RETURN;
				END

				-- Si pasa la validación, traemos los datos reales
				SELECT
					''SUCCESS'' AS ControlCode,
					@IAModeloId AS idAgent,
					CAST(0 AS INT) [type], 
					i.inbound_id AS cam_id, 
					c.calif_id,
					t.Name_cal
				FROM ccInbound i 
				INNER JOIN dbo.ccCalifCampIA AS c ON i.inbound_id = c.cam_id AND c.tipo = @Camp_Type
				INNER JOIN dbo.cctipoCalif_IA AS t ON c.calif_id = t.calif_id
				WHERE i.inbound_id = @Camp_Id AND t.Cali_StatusIA = 1
				ORDER BY t.Name_cal
			END
			ELSE IF @Camp_Type = 1
			BEGIN
				-- Validar si la campaña tiene calificaciones
				IF NOT EXISTS (SELECT 1 FROM dbo.ccCalifCampIA WHERE cam_id = @Camp_Id AND tipo = @Camp_Type)
				BEGIN
					SELECT ''ERROR_CAMPAIGN_WITHOUT_DISPOSITIONS'' AS ControlCode
					RETURN;
				END

				SELECT
					''SUCCESS'' AS ControlCode,
					@IAModeloId AS idAgent,
					CAST(1 AS INT) [type], 
					o.cam_id, 
					c.calif_id,
					co.Name_cal
				FROM ccCamps o 
				INNER JOIN ccCalifCampIA c ON o.cam_id = c.cam_id AND c.tipo = @Camp_Type
				INNER JOIN cctipoCalif_IA co ON c.calif_id = co.calif_id
				WHERE o.cam_id = @Camp_Id AND co.Cali_StatusIA = 1
				ORDER BY co.Name_cal
			END

		END TRY  
		BEGIN CATCH
			SELECT ''ERROR_INTERNAL_SERVER'' AS ControlCode
		END CATCH
	END


	set nocount OFF'
	EXEC(@sql);

	SET @process = 'K070406 Drop Procedure [dbo].[ccsp_AIToHumanTransfer]';
	SET @sql = N'
		If Exists (Select 1 From sys.procedures Where name = N''ccsp_AIToHumanTransfer'')
			Begin
				DROP PROCEDURE ccsp_AIToHumanTransfer
			End';
	EXEC(@sql);

	SET @process = 'K070406 Se quitaron los options 3 y 4 por que ya no se ocuparan'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_AIToHumanTransfer]
			@action int = null,
			@camId int = null,
			@CallOutId int = null,
			@acdId int = null

		AS
		BEGIN 
			if @action = 1
			Begin
				select Inbound_id AS ACDToTranfer, CAST(0 AS BIT) AS TransferMode , 0 AS TransferTo, '''' AS TransferToExternalNumber, '''' AS TransferToExternalDirectoryNumber   from ccInbound where cam_id = @camId
			end

			if @action = 2
			Begin
				select data_overflow_variables_quantum from ccoCallsOutSource where callout_id = @CallOutId
			end
		END';
	EXEC(@sql);

	SET @process = 'K070406 Drop Procedure [dbo].[ccsp_VerifyCampaignRelationships]';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_VerifyCampaignRelationships'')
        Begin
            DROP PROCEDURE ccsp_VerifyCampaignRelationships
        End';
EXEC(@sql);

SET @process = 'K070406 Se agregó un opción 2 para obtener las que tienen asignada una calificación la cual se elimino la campaña asociada'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_VerifyCampaignRelationships]
	@Option SMALLINT = 0,
            	@CamIds VARCHAR(MAX)
            AS
            BEGIN
            	SET NOCOUNT ON;

            	DECLARE @CurrentId INT;
            	DECLARE @HasRelations BIT;

            	IF @Option = 0 --ACDs
            	BEGIN
            		IF OBJECT_ID(''tempdb..#TmpACDs'') IS NOT NULL DROP TABLE #TmpACDs;
            		IF OBJECT_ID(''tempdb..#FinalACDs'') IS NOT NULL DROP TABLE #FinalACDs;
            		IF OBJECT_ID(''tempdb..#ClassifiedACDs'') IS NOT NULL DROP TABLE #ClassifiedACDs;

            		CREATE TABLE #TmpACDs (Id INT);
            		CREATE TABLE #FinalACDs (Id INT);
            		CREATE TABLE #ClassifiedACDs (
            			Id INT,
            			HasWGRelation BIT,
            			HasCampaignRelation BIT,
            			UnassignVirtualAgent BIT
            		);

            		INSERT INTO #TmpACDs (Id)
            		SELECT CAST(Value AS INT)
            		FROM dbo.fn_RIASplitDelimited(@CamIds, '','');

            		INSERT INTO #ClassifiedACDs (Id, HasWGRelation, HasCampaignRelation, UnassignVirtualAgent)
            		SELECT
            			t.Id,
            			CASE WHEN r.IdCampEsp IS NOT NULL THEN 1 ELSE 0 END AS HasWGRelation,
						CASE WHEN i.inbound_id IS NOT NULL AND i.cam_id > 0 THEN 1 ELSE 0 END AS HasCampaignRelation,
            			CASE WHEN v.idCampaign IS NOT NULL THEN 1 ELSE 0 END AS UnassignVirtualAgent
            		FROM #TmpACDs t
            		LEFT JOIN ccRIACampESPWG r
            			ON r.IdCampEsp = t.Id AND r.Tipo = 0
            		LEFT JOIN ccinbound i
            			ON i.inbound_id = t.Id
            		LEFT JOIN ccVirtualAgent v
            			ON v.idCampaign = t.Id AND v.campType = 0 AND v.mediaType = 11;

            		INSERT INTO #FinalACDs (Id)
            		SELECT Id
            		FROM #ClassifiedACDs
            		WHERE HasWGRelation = 0 AND HasCampaignRelation = 0 AND UnassignVirtualAgent = 0;

            		DECLARE cur CURSOR LOCAL FOR
            		SELECT Id
            		FROM #ClassifiedACDs
            		WHERE HasWGRelation = 0 AND HasCampaignRelation = 0 AND UnassignVirtualAgent = 1;

            		OPEN cur;
            		FETCH NEXT FROM cur INTO @CurrentId;

            		WHILE @@FETCH_STATUS = 0
            		BEGIN
            			UPDATE ccVirtualAgent
            			SET idCampaign = 0,
            				mediaType = NULL
            			WHERE idCampaign = @CurrentId AND campType = 0 AND mediaType = 11;

            			INSERT INTO #FinalACDs (Id) VALUES (@CurrentId);

            			FETCH NEXT FROM cur INTO @CurrentId;
            		END

            		CLOSE cur;
            		DEALLOCATE cur;

            		DECLARE @CleanACDIds VARCHAR(MAX);
            		SELECT @CleanACDIds =
            		STUFF((
            			SELECT '','' + CAST(Id AS VARCHAR)
            			FROM #FinalACDs
            			ORDER BY Id
            			FOR XML PATH(''''), TYPE
            		).value(''.'', ''VARCHAR(MAX)''), 1, 1, '''');

            		SET @HasRelations = CASE
            										WHEN (SELECT COUNT(*) FROM #FinalACDs) < (SELECT COUNT(*) FROM #TmpACDs)
            										THEN 1 ELSE 0
            									END;


            		SELECT
            			@HasRelations AS HasRelations,
            			ISNULL(@CleanACDIds, '''') AS ACDIds;

            		IF OBJECT_ID(''tempdb..#TmpACDs'') IS NOT NULL DROP TABLE #TmpACDs;
            		IF OBJECT_ID(''tempdb..#FinalACDs'') IS NOT NULL DROP TABLE #FinalACDs;
            		IF OBJECT_ID(''tempdb..#ClassifiedACDs'') IS NOT NULL DROP TABLE #ClassifiedACDs;
            	END


                ELSE IF @Option = 1 -- Camps
                BEGIN

                    IF OBJECT_ID(''tempdb..#TmpOutIDs'') IS NOT NULL DROP TABLE #TmpOutIDs;
                    IF OBJECT_ID(''tempdb..#FinalCampsId'') IS NOT NULL DROP TABLE #FinalCampsId;
                    IF OBJECT_ID(''tempdb..#ClassifiedCamps'') IS NOT NULL DROP TABLE #ClassifiedCamps;

                    CREATE TABLE #TmpOutIDs (Id INT NOT NULL PRIMARY KEY);
                    CREATE TABLE #FinalCampsId (Id INT NOT NULL PRIMARY KEY);
                    CREATE TABLE #ClassifiedCamps (
                        Id INT NOT NULL,
                        HasWGRelation BIT NOT NULL,
                        HasCampaignRelation BIT NOT NULL,
                        UnassignVirtualAgent BIT NOT NULL
                    );

                    INSERT INTO #TmpOutIDs (Id)
                    SELECT DISTINCT CAST(Value AS INT)
                    FROM dbo.fn_RIASplitDelimited(@CamIds, '','');

                    INSERT INTO #ClassifiedCamps (Id, HasWGRelation, HasCampaignRelation, UnassignVirtualAgent)
                    SELECT
                        t.Id,
                        CASE WHEN r.IdCampEsp IS NOT NULL THEN 1 ELSE 0 END AS HasWGRelation,
                        CASE
                            WHEN i.inbound_id IS NOT NULL
                                 THEN CASE WHEN (i.cam_id IS NULL OR i.cam_id = 0) THEN 0 ELSE 1 END
                            ELSE 0
                        END AS HasCampaignRelation,
                        CASE WHEN v.idCampaign IS NOT NULL THEN 1 ELSE 0 END AS UnassignVirtualAgent
                    FROM #TmpOutIDs AS t
                    LEFT JOIN ccRIACampESPWG AS r
                        ON r.IdCampEsp = t.Id AND r.Tipo = 1
                    LEFT JOIN ccinbound AS i
                    ON i.cam_id = t.Id and i.IDArea is not null
                    LEFT JOIN ccVirtualAgent AS v
                        ON v.idCampaign = t.Id AND v.campType = 1 AND v.mediaType = 10;

                    BEGIN TRY
                        BEGIN TRAN;

                        UPDATE va SET va.idCampaign = 0, va.mediaType  = NULL FROM ccVirtualAgent AS va
                                                                              JOIN #ClassifiedCamps AS c ON c.Id = va.idCampaign
                                                                              WHERE va.campType = 1
                                                                                AND va.mediaType = 10
                                                                                AND c.HasWGRelation = 0
                                                                                AND c.HasCampaignRelation = 0
                                                                                AND c.UnassignVirtualAgent = 1;

                        DELETE dc FROM ccoDialerCamp AS dc WHERE dc.cam_id IN (SELECT Id FROM #ClassifiedCamps WHERE HasWGRelation = 0 AND HasCampaignRelation = 0);

                        INSERT INTO #FinalCampsId (Id) SELECT DISTINCT Id FROM #ClassifiedCamps WHERE HasWGRelation = 0 AND HasCampaignRelation = 0;

                        COMMIT;
                    END TRY
                    BEGIN CATCH
                        IF XACT_STATE() <> 0 ROLLBACK;

                        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE(),
                                @ErrSeverity INT = ERROR_SEVERITY(),
                                @ErrState INT = ERROR_STATE();
                        RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
                        RETURN;
                    END CATCH

                    DECLARE @CleanCampsIds VARCHAR(MAX);

                    SELECT @CleanCampsIds =
                    STUFF((
                        SELECT '','' + CONVERT(VARCHAR(10), Id)
                        FROM (SELECT DISTINCT Id FROM #FinalCampsId) d
                        ORDER BY Id
                        FOR XML PATH(''''), TYPE
                    ).value(''.'', ''VARCHAR(MAX)''), 1, 1, '''');

                    SET @HasRelations = CASE
                        WHEN (SELECT COUNT(*) FROM #FinalCampsId) < (SELECT COUNT(*) FROM #TmpOutIDs)
                        THEN 1 ELSE 0 END;

                    SELECT @HasRelations AS HasRelations,
                           ISNULL(@CleanCampsIds, '''') AS CampsIds;

                    IF OBJECT_ID(''tempdb..#TmpOutIDs'') IS NOT NULL DROP TABLE #TmpOutIDs;
                    IF OBJECT_ID(''tempdb..#FinalCampsId'') IS NOT NULL DROP TABLE #FinalCampsId;
                    IF OBJECT_ID(''tempdb..#ClassifiedCamps'') IS NOT NULL DROP TABLE #ClassifiedCamps;
                END
				ELSE IF (@Option = 2) -- get campaigns that have dispositions assigned by campaigns are going to delete
				BEGIN
					IF OBJECT_ID(''tempdb..#TmpACDDeleted'') IS NOT NULL DROP TABLE #TmpACDDeleted;

					CREATE TABLE #TmpACDDeleted (Id INT);	

					INSERT INTO #TmpACDDeleted (Id)
            		SELECT CAST(Value AS INT)
            		FROM dbo.fn_RIASplitDelimited(@CamIds, '','');

					SELECT ccci.cam_id AS CampaignAssigned, cva.idAgent AS IdAgentModel, ccci.tipo AS Type, ccitc.DestinationCampId AS CampaignToDelete FROM 
					#TmpACDDeleted a
					INNER JOIN dbo.ccCalif_IA_TransferConfig AS ccitc
					ON a.Id = ccitc.DestinationCampId
					INNER JOIN dbo.ccCalifCampIA AS ccci
					ON ccci.calif_id = ccitc.DispositionId 
					INNER JOIN dbo.ccVirtualAgent AS cva
					ON ccci.cam_id = cva.idCampaign
					AND ccci.tipo = cva.campType
					GROUP BY ccci.cam_id,
                             cva.idAgent,
                             ccci.tipo,
                             ccitc.DestinationCampId;

					IF OBJECT_ID(''tempdb..#TmpACDDeleted'') IS NOT NULL DROP TABLE #TmpACDDeleted;
				END
            END'
EXEC(@sql);

SET @process = 'K070406 Drop Procedure [dbo].[ccsp_GalateaAdminCampaigns] MAGV';
SET @sql = N'
    If Exists (Select 1 From sys.procedures Where name = N''ccsp_GalateaAdminCampaigns'')
        Begin
            DROP PROCEDURE ccsp_GalateaAdminCampaigns
        End';
EXEC(@sql);

	SET @process = 'K070406 create sp ccsp_GalateaAdminCampaigns
	Se elimina el opción 19, ya que se ocupaba para obtener las campañas relacionadas a una campaña de ia de entrada para transferencia MAGV'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns]
	@Option AS      SMALLINT,
	@CampType AS    SMALLINT = 0,
	@WorkgroupId AS INT      = 0,
	@Id AS          INT      = 0,
	@AdminId AS     SMALLINT = 0,
	@PinUpdate AS   SMALLINT = 0,
	@LoadId AS      INT      = 0,
	@Type AS        SMALLINT = 0,
	@InboundType    SMALLINT = 0,
	@AreaId         SMALLINT = 0,
	@multi_type     varchar(max) = null,
	@IsWhatsAppCampaign  bit = 0,
	@groupList as varchar (MAX) = NULL,
	@CampId AS      SMALLINT = 0
	AS
	BEGIN
		SET NOCOUNT ON;
	IF @Option = 1 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
		IF @WorkgroupId IS NOT NULL BEGIN
			SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId
			ORDER BY IdCampEsp ASC;
		END;
		ELSE BEGIN
			RAISERROR(''ERROR. No existe una lista de campañas con el id de grupo de trabajo especificado'', 18, 1);
		END;
		RETURN 0;
	END;
	IF @Option = 2 BEGIN-- Get Campaign complete information per Campaign Type and Campaign Id
		IF @CampType = 1 BEGIN-- Campaigns Out
			IF @Id IS NOT NULL BEGIN
				DECLARE @HasWorkingRowsForCampaign BIT = 0, @HasTemplatePaused   bit = 0,
			@HasTemplateDisabled bit = 0;

				IF EXISTS (
					SELECT 1
					FROM dbo.ccoWAWorkingTable AS cwwt
					WHERE cwwt.camId = @Id
				)
				BEGIN
					SET @HasWorkingRowsForCampaign = 1;
				END

				IF EXISTS (
					SELECT 1
					FROM dbo.ccoWAWorkingTable cwwt
					JOIN dbo.ccWhatsAppOutSource cwaos  ON cwaos.WAOut_Id = cwwt.WAOut_id
					JOIN dbo.ccMetaWAOutboundTemplates cmwot ON cmwot.Id = cwaos.TemplateId
					WHERE cwaos.camId = @Id AND cmwot.Status = ''PAUSED''
				) SET @HasTemplatePaused = 1;

				IF EXISTS(
				SELECT 1 FROM dbo.ccMetaWAOutboundTemplates AS cmwot
					INNER JOIN dbo.ccMetaWhatsAppNumbers AS cmwan
					ON cmwan.MetaId = cmwot.MetaId
					WHERE cmwan.Cam_Id = @Id AND cmwot.Status = ''DISABLED''
					AND cmwot.StatusCW = 1
				)
				BEGIN
					SET @HasTemplateDisabled = 1;
				END

				SELECT DISTINCT
				CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
				isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
				camps.cam_procesando IsStarted,
				ISNULL(a.AreaName, '''') AS Area,
				CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
				CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
				CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10  ELSE isnull(camps.CampType,0) END as OutboundType,
				ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
				a.ToolsTransfer,
				@HasTemplatePaused AS HasTemplatePaused,
				@HasTemplateDisabled AS HasTemplateDisabled,
				@HasWorkingRowsForCampaign AS HasWorkingRowsForCampaign
				FROM ccCamps camps
				LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
				LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
				LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
				WHERE camps.cam_id = @Id
				ORDER BY camps.cam_descripcion ASC;
			END;
			ELSE BEGIN
				RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
			END;
		END;
		ELSE IF @CampType = 0 -- Campaigns In (ACD)
			BEGIN
				IF @Id IS NOT NULL
					BEGIN
						SELECT DISTINCT
						CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted,
						ISNULL(a.AreaName, '''') AS Area,
								CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType,
								a.ToolsTransfer
						FROM ccInbound inb
								LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
								LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
						WHERE inb.Inbound_id = @Id
								ORDER BY inb.descripcion ASC;
				END;
				ELSE
					BEGIN
						RAISERROR(''ERROR. No existe campañas de entrada con el id especificado'', 18, 1);
				END;
		END;
		RETURN 0;
	END;
	ELSE IF @Option = 3  BEGIN -- Update OverallTotalNew By Campaign

		IF @Id IS NOT NULL BEGIN
			UPDATE ccCampsNvosCB SET  OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id;
		END;
		ELSE BEGIN
			RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
		END;
		RETURN 0;
	END;
	ELSE IF @Option = 4 -- Update Pin from Campaign per Admin
	BEGIN
		IF @Id IS NOT NULL
			AND @AdminId IS NOT NULL
		BEGIN
			IF @PinUpdate = 1
			BEGIN
				INSERT INTO PinedCampaigns (CampId, AdminId, Type)
				VALUES (@Id, @AdminId, @Type);
			END;

			IF @PinUpdate = 0
			BEGIN
				DELETE
				FROM PinedCampaigns
				WHERE CampId = @Id
					AND AdminId = @AdminId
					AND Type = @Type;
			END;
		END;
		ELSE
		BEGIN
			RAISERROR (''ERROR. La campañas o administrador no existen'', 18, 1
					);
		END;

		RETURN 0;
	END;

	ELSE IF @Option = 5 BEGIN  -- Get Pin from Campaign Ids per Admin
		IF @AdminId IS NOT NULL BEGIN
			SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
			ORDER BY Id ASC;
		END;
		ELSE BEGIN
			RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
		END;
		RETURN 0;
	END;
	ELSE IF @Option = 6 -- Get Blacklist Ids by Campaign Id
	BEGIN
		IF @Id IS NOT NULL
		BEGIN
			DECLARE @BlackListIds VARCHAR(MAX);

			SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR
						(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
			FROM Camplistanegra
			WHERE cam_id = @Id
				AND STATUS = 1;

			SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
		END;
		ELSE
		BEGIN
			RAISERROR (''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
		END;

		RETURN 0;
	END;

	ELSE IF @Option = 7 -- Get RegistryListIds Ids by Campaign Id
	BEGIN
		IF (
				@Id IS NOT NULL
				AND EXISTS (
					SELECT *
					FROM cccamps
					WHERE cam_id = @Id
					)
				)
		BEGIN
			SELECT TOP 1 list_id
			FROM ccRIARegistryLists
			WHERE cam_id = @Id
				AND STATUS = 2
			ORDER BY list_id DESC;
		END;
		ELSE
		BEGIN        
			RAISERROR (''ERROR. No existe una campaña con el id especificado'', 18, 1);
		END;

		RETURN 0;
	END;

	ELSE IF @Option = 8 -- Delete RegistryListIds Ids by LoadId
	BEGIN
		IF (
				@LoadId IS NOT NULL
				AND EXISTS (
					SELECT *
					FROM ccRIARegistryLists
					WHERE list_id = @loadID
						AND STATUS <> 0
					)
				)
		BEGIN
			UPDATE ccoCallsOutSource
			SET cal_status = ''5''
			WHERE list_id = @loadID;

			DELETE
			FROM ccoWorkingTable
			WHERE list_id = @LoadId;

			EXEC ccsp_RIARegistryLists @action = 6, @list_id = @LoadId;
		END;
		ELSE
		BEGIN
			--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
			RAISERROR (''ERROR. No existe una carga el id especificado'', 18, 1);
		END;

		RETURN 0;
	END;

	ELSE IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
	BEGIN
		DECLARE @table TABLE (camId INT, campType TINYINT, PRIMARY KEY (camId, campType)
			);

		INSERT INTO @table
		SELECT DISTINCT IdCampEsp, Tipo
		FROM ccRIACampEspWG wg
		WHERE wg.IDWG IN (
				SELECT IDWG
				FROM ccRIAWorkGroupUsers
				WHERE IDWG <> @WorkgroupId
					AND User_id = @AdminId
				);

		SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
		FROM @table A
		RIGHT JOIN (
			SELECT wg.IdCampEsp, wg.Tipo
			FROM ccRIACampEspWG wg
			WHERE wg.IDWG = @WorkgroupId
			) B ON A.camId = B.IdCampEsp
			AND A.campType = B.Tipo
		WHERE A.camId IS NULL
		ORDER BY IdCampEsp;

		RETURN 0;
	END;

	ELSE IF @option = 10
	BEGIN -- Get Agents States with totals per campaign by admin id and campaign type **********************
		DECLARE @date DATETIME = CONVERT(DATE, DATEADD(hh, - 3, GETDATE()));
		DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY (id));
		DECLARE @AgentsList TABLE (id INT, PRIMARY KEY (id));
		DECLARE @tmpCamAgent TABLE (
			camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY (camId, userId)
		);
		DECLARE @AgentStatus TABLE (CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT);
		DECLARE @CurrentStatus TABLE (userId INT, CurrentState INT, IdCampEsp INT, camType INT);
		DECLARE @campDataTotal TABLE (
			camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), NumberOfVirtualAgents INT, PRIMARY KEY (camId)
		);

		INSERT INTO @AdminWorkgroups
		SELECT DISTINCT IDWG
		FROM ccRIAWorkGroupUsers WG, ccUsers_Roles R
		WHERE WG.User_id = @AdminId
			OR (R.User_id = @AdminId AND R.Rol_id = 7);

		INSERT INTO @AgentsList
		SELECT DISTINCT A.User_id
		FROM ccRIAWorkGroupUsers A
		INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
		INNER JOIN ccUsers C ON A.User_id = C.User_id AND C.TipoUser_id = 1
		ORDER BY A.User_id;

		IF @IsWhatsAppCampaign = 1
		BEGIN
			INSERT INTO @tmpCamAgent
			SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, 
				   CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
			FROM ccRIACampEspWG campPerWg
			INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
			INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
			INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
			LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp AND @CampType = 0
			LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp AND @CampType = 1
			WHERE C.TipoUser_id = 1
				AND (camps.CampType = 5 or inbound.chat = 5)
				AND campPerWg.Tipo = @CampType
				AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
		END
		ELSE
		BEGIN
			INSERT INTO @tmpCamAgent
			SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, 
				   CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
			FROM ccRIACampEspWG campPerWg
			INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
			INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
			INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
			LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp AND @CampType = 0
			LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp AND @CampType = 1
			WHERE C.TipoUser_id = 1
				AND campPerWg.Tipo = @CampType
				AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
		END;

		;WITH lastState AS (
			SELECT A.user_id, A.fecha,
				   CASE WHEN A.currentStatus <= 0 THEN 0 ELSE A.currentStatus END AS currentStatus,
				   IdCampEsp, Tipo
			FROM ccLogAgentesDiaLast A WITH(NOLOCK)
			INNER JOIN @AgentsList B ON A.User_id = B.id
			WHERE fecha >= @date
		)
		INSERT INTO @CurrentStatus
		SELECT A.User_id, currentStatus, IdCampEsp, Tipo
		FROM lastState A;

		IF @Id = 0 AND @CampType = 0
		BEGIN
			DELETE FROM @tmpCamAgent WHERE multimediaType = 0;
		END

		DECLARE @MultimediaType SMALLINT = 0, @chatType SMALLINT = 0;

		IF @Id > 0
		BEGIN
			IF @CampType = 1
			BEGIN
				SELECT @MultimediaType = ISNULL(meanContactTypeId, 0) FROM contactMeanOut WHERE camp_id = @Id;
			END
			ELSE
			BEGIN
				SELECT @chatType = ISNULL(chat, 0) FROM dbo.ccInbound WHERE Inbound_id = @Id;
				SELECT @MultimediaType = ISNULL(meanContactTypeId, 0) FROM contactMeanIn WHERE inboundId = @Id;
			END
		END

		IF (@chatType = 1) SET @MultimediaType = 1;

		DECLARE @StateIds VARCHAR(100) = (
			SELECT CASE 
				WHEN @MultimediaType = 5 THEN ''6,34'' 
				WHEN @MultimediaType = 1 THEN ''23'' 
				ELSE ''4,5,6,9'' 
			END
		);

		;WITH stateDialog AS (
			SELECT CAST(value AS INT) AS CurrentState FROM dbo.fn_RIASplitDelimited(@StateIds,'','')
		)
		INSERT INTO @AgentStatus
		SELECT A.camId, A.userId, B.CurrentState,
		(CASE
			WHEN @chatType = 1 THEN
				CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) THEN 1 ELSE 0 END
			ELSE
				CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) 
					 AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN 1 ELSE 0 END
		END) AS isCampDialog, B.camType
		FROM @tmpCamAgent A
		INNER JOIN @CurrentStatus B ON A.userId = B.userId
		WHERE (@Id = 0 OR A.camId = @Id);

		IF @CampType = 1
		BEGIN
			WITH campDataTotal AS (
				SELECT camId, COUNT(*) AS total
				FROM @tmpCamAgent
				GROUP BY camId
			)
			INSERT INTO @campDataTotal
			SELECT A.camId, B.cam_descripcion, A.total, C.AreaName, ISNULL(va.concurrentSessionsLimit,0)
			FROM campDataTotal A
			INNER JOIN ccCamps B ON A.camId = B.cam_id
			INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
			LEFT JOIN ccVirtualAgent va ON B.cam_id = va.idCampaign AND va.campType = 1;
		END
		ELSE
		BEGIN
			WITH campDataTotal AS (
				SELECT camId, COUNT(*) AS total
				FROM @tmpCamAgent
				GROUP BY camId
			)
			INSERT INTO @campDataTotal
			SELECT A.camId, B.descripcion, A.total, C.AreaName, 0
			FROM campDataTotal A
			INNER JOIN ccInbound B ON A.camId = B.Inbound_id
			INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea;
		END;

		WITH stateCamp AS (
			SELECT A.CampId, 
				   COUNT(CASE WHEN A.CurrentState = 3 THEN 1 END) AS ready,
				   COUNT(CASE 
							WHEN A.CurrentState NOT IN (-2, -1, 0, 3, 4, 5, 6, 9, 30, 34, 37) THEN 1 
							WHEN A.CurrentState IN (6, 4) AND (A.CampId != C.IdCampEsp OR A.campType != @CampType) THEN 1 
						 END) AS notReady,
				   COUNT(CASE WHEN A.isCampDialog = 1 OR A.CurrentState = 34 THEN 1 END) AS dialog,
				   COUNT(CASE WHEN A.CurrentState <= 0 THEN 1 END) AS disconnected,
				   COUNT(CASE WHEN A.CurrentState = 37 THEN 1 END) AS auxiliaryReady
			FROM @AgentStatus A
			INNER JOIN @CurrentStatus C ON A.userId = C.userId
			GROUP BY A.CampId
		)
		SELECT A.camId, A.campName, (A.Total + A.NumberOfVirtualAgents) AS Total, 
			   ISNULL(B.ready, 0) AS Ready, 
			   ISNULL(B.notReady, 0) AS NotReady, 
			   ISNULL(B.dialog, 0) AS Dialog, 
			   CASE WHEN B.disconnected IS NULL THEN A.Total 
					ELSE A.Total - ISNULL(B.ready,0) - ISNULL(B.dialog,0) - ISNULL(B.notReady,0) - ISNULL(B.auxiliaryReady,0) 
			   END AS Disconnected, 
			   ISNULL(B.auxiliaryReady, 0) AS AuxiliaryReady, 
			   A.NumberOfVirtualAgents, A.Area
		FROM @campDataTotal A
		LEFT JOIN stateCamp B ON A.camId = B.CampId
		ORDER BY A.campName;

		RETURN 0;
	END
	ELSE IF @Option = 11
	BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
		IF NOT EXISTS (
				SELECT *
				FROM ccUsers_Roles WITH (NOLOCK)
				WHERE User_id = @AdminId
					AND Rol_id = 7
				)
		BEGIN        
			WITH wgId
			AS (
				SELECT IDWG
				FROM ccRIAWorkGroupUsers WITH (NOLOCK)
				WHERE user_id = @AdminId
				)
			SELECT DISTINCT CAST(IdCampEsp AS INT) AS Id
			INTO #tempIds
			FROM ccRIACampEspWG A WITH (NOLOCK)
			INNER JOIN wgId ON wgId.IDWG = A.IDWG
				AND A.Tipo = @CampType;

			IF(@CampType = 1)
			BEGIN
				SELECT Id FROM #tempIds ids
				INNER JOIN ccCamps c on c.cam_id = ids.Id
				WHERE (c.CampType = 5 AND @IsWhatsAppCampaign = 1)
				OR (c.CampType <> 5 AND @IsWhatsAppCampaign = 0)
			END
			ELSE
			BEGIN
				SELECT Id FROM #tempIds ids
				INNER JOIN ccInbound c on c.Inbound_id = ids.Id
				WHERE (c.chat = 5 AND @IsWhatsAppCampaign = 1)
				OR (c.chat <> 5 AND @IsWhatsAppCampaign = 0)
			END
			DROP TABLE #tempIds
		END;
		ELSE
		BEGIN        
			IF @CampType = 1
			BEGIN
				SELECT DISTINCT CAST(cam_id AS INT) AS Id
				FROM ccCamps WITH (NOLOCK)
				WHERE IDArea IS NOT NULL
				AND(CampType = 5 AND @IsWhatsAppCampaign = 1)
				OR (CampType <> 5 AND @IsWhatsAppCampaign = 0)
			END
			ELSE
			BEGIN
				SELECT DISTINCT CAST(Inbound_id AS INT) AS Id
				FROM ccInbound WITH (NOLOCK)
				WHERE IDArea IS NOT NULL
				AND (chat = 5 AND @IsWhatsAppCampaign = 1)
				OR (chat <> 5 AND @IsWhatsAppCampaign = 0)
			END
		END;

		RETURN 0;
	END;

	ELSE IF @Option = 12
	BEGIN-- Get All Campaigns complete information per Campaign Type and Campaign Id
		IF @CampType = 1 -- Campaigns Out
		BEGIN
			;WITH StopByCamp AS (
			SELECT
				cwaos.camId,
				IsStopDueTemplateStatusChange = CAST(
					CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END AS BIT
				)
			FROM dbo.ccoWAWorkingTable AS cwwt
			INNER JOIN dbo.ccWhatsAppOutSource AS cwaos
				ON cwaos.WAOut_Id = cwwt.WAOut_id
			INNER JOIN dbo.ccMetaWAOutboundTemplates AS cmwot
				ON cmwot.Id = cwaos.TemplateId
			WHERE cmwot.Status IN (''PAUSED'', ''DISABLED'')
			GROUP BY cwaos.camId
			)

			SELECT DISTINCT
			CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
			isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
			camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
			CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
			CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10 ELSE isnull(camps.CampType,0) END as OutboundType,
			ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
			ISNULL(sbc.IsStopDueTemplateStatusChange, 0) AS IsStopDueTemplateStatusChange
			FROM ccCamps camps(NOLOCK)
			INNER JOIN ccRIACampsGraph graph(NOLOCK) ON camps.cam_id = graph.cam_id
			INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = camps.IDArea
			LEFT JOIN ccCampsExtend extended(NOLOCK) ON camps.cam_id = extended.cam_id
			LEFT  JOIN StopByCamp       sbc                   ON sbc.camId = camps.cam_id
			ORDER BY camps.cam_descripcion ASC;
		END;
		ELSE
		BEGIN
			SELECT DISTINCT CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, isnull
				(CAST(graph.graphic_id AS INT), 1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(
					inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea AS INT) AS
				AreaId, inb.chat AS InboundType, 0 AS OutboundType
			FROM ccInbound inb(NOLOCK)
								INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
			INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = inb.IDArea
			ORDER BY inb.descripcion ASC;
		END;

		RETURN 0;
	END;

	ELSE IF @Option = 13
	BEGIN
		BEGIN
			IF NOT EXISTS (
					SELECT *
					FROM ccUsers_Roles NOLOCK
					WHERE User_id = @AdminId
						AND Rol_id = 7
					)
			BEGIN
				IF @CampType = 1
				BEGIN
					WITH wgId
					AS (
						SELECT IDWG
						FROM ccRIAWorkGroupUsers NOLOCK
										WHERE user_id = @AdminId)
									SELECT DISTINCT
										CAST(IdCampEsp AS INT) AS CampId,
										cam_descripcion AS Description,
										isnull(ccc.IDArea, -1) AS AreaID,
										CAST(-1 AS SMALLINT) AS CampaignType,
										CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
										CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
										CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
										CAST(1 AS INT) As CampType
					FROM ccRIACampEspWG A
					INNER JOIN wgId ON wgId.IDWG = A.IDWG AND A.Tipo = 1
					INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id
					LEFT JOIN ccInbound cci(NOLOCK) ON ccc.cam_id = cci.cam_id
					LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
				END
				ELSE
				BEGIN
					WITH wgId
					AS (
						SELECT IDWG
						FROM ccRIAWorkGroupUsers NOLOCK
										WHERE user_id = @AdminId)
									SELECT DISTINCT
										CAST(IdCampEsp AS INT) AS CampId,
										descripcion AS Description,
										isnull(IDArea, -1) AS AreaID,
										CAST(chat AS SMALLINT) AS CampaignType,
										CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
										CAST(chat AS INT) AS Channel,
										CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
										CAST(0 AS INT) As CampType
					FROM ccRIACampEspWG A(NOLOCK)
					INNER JOIN wgId ON wgId.IDWG = A.IDWG
						AND A.Tipo = 0
					INNER JOIN ccInbound cci(NOLOCK) ON A.IdCampEsp = cci.Inbound_id
										LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
										LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
										AND ((@multi_type is null AND cci.chat = @InboundType)
											OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
				END
			END;
			ELSE
			BEGIN
				IF @CampType = 1
				BEGIN
							SELECT DISTINCT
									CAST(ccc.cam_id AS INT) AS CampId,
									cam_descripcion AS Description,
									isnull(ccc.IDArea, -1) AS AreaID,
									CAST(-1 AS SMALLINT) AS CampaignType,
									CAST(ISNULL(i.Inbound_id,-1) AS INT) AS RelatedCampId,
									CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
									CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
									CAST(1 AS INT) As CampType
							FROM ccCamps AS ccc (NOLOCK)
								LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
								left join ccInbound i on i.cam_id = ccc.cam_id
							where ccc.IDArea = @AreaId
				END
				ELSE
				BEGIN
							SELECT DISTINCT
									CAST(cci.Inbound_id AS INT) AS CampId,
									descripcion AS Description,
									isnull(IDArea, -1) AS AreaID,
									CAST(chat AS SMALLINT) AS CampaignType,
									CAST(chat AS INT) AS Channel,
									CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
									CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
									CAST(0 AS INT) As CampType
					FROM ccInbound cci(NOLOCK)
								LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
								LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
							where IDArea = @AreaId
							AND ((@multi_type is null AND cci.chat = @InboundType)
								OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

				END
			END;

			RETURN 0;
		END;
	END;
	ELSE IF @Option = 14
	BEGIN
		IF NOT EXISTS (
				SELECT 1
				FROM ccUsers_Roles NOLOCK
				WHERE User_id = @AdminId
					AND Rol_id = 7
				)
		BEGIN
			WITH wgId
			AS (
				SELECT IDWG
				FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT
									CAST(IdCampEsp AS INT) AS CampId,
									descripcion AS Description,
									isnull(IDArea, -1) AS AreaID,
									CAST(chat AS SMALLINT) AS CampaignType,
									CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
			FROM ccRIACampEspWG A(NOLOCK)
			INNER JOIN wgId ON wgId.IDWG = A.IDWG
				AND A.Tipo = 0
			INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id
				AND ((@multi_type is null AND cci.chat = @InboundType) OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

		END
		ELSE
		BEGIN
						SELECT DISTINCT
						CAST(Inbound_id AS INT) AS CampId,
						descripcion AS Description,
						isnull(IDArea, -1) AS AreaID,
						CAST(chat AS SMALLINT) AS CampaignType,
						CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
						FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
						AND ((@multi_type is null AND cci.chat = @InboundType)
							OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

		END
	END

	ELSE IF @Option = 15
	BEGIN
		select
			CAST(Inbound_id AS INT) AS CampId,
			cci.descripcion AS Description,
			isnull(cci.IDArea, -1) AS AreaID,
			CAST(cci.chat AS SMALLINT) AS CampaignType,
			CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId
		from ccCamps ccc
		INNER JOIN ccInbound cci ON cci.IDArea = ccc.IDArea
		where ccc.cam_id = @Id
			and cci.chat IN (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))
			and isnull(cci.cam_id,-1) > 0

	END
	ELSE IF  @Option=16
	begin
		DECLARE @from DATETIME = CAST(GETDATE() AS DATE);
		DECLARE @to DATETIME = DATEADD(MILLISECOND, -3, DATEADD(DAY, 1, @from));
		select @AreaId = IDArea from ccUsers where User_id = @Id
		declare @camps table (cam_id int)
		insert @camps   select cam_id  FROM  dbo.fGet_CampAcd_Area(@Id,5) group by cam_id
		if((select SUM(cam_id) from @camps) IS NULL)
			begin
				select '''' as CampName
				,0 as Conversations
				,0 as Assign
				,0 as OnQueu
				,0 AS FinishedBySystem
				,0 AS FinishedByAgent
				,'''' as AreaName
				,0 as IsAssignedCamps
			end
		else
			begin
				;with camDesc as(
				select
				c.cam_id as cam_id
				,cam_descripcion as cam_desc
				,area.AreaName
				from ccCamps c with (nolock)
				inner join @camps id on c.cam_id = id.cam_id
				inner join ccRIACat_Areas area on area.IDArea = c.IDArea
				group by area.AreaName, c.cam_id, c.cam_descripcion
				)
				,
				currentConversationWa as (
				select conversationId, camId, assignDate, onQueue,finishedBy
				,case when conversationStatus = 2 then 1 else 0 end as assigned
				from ccWhatsAppConversationsOut with (nolock)
				where assignDate >= @from and assignDate <= @to
				)
				select
				b.cam_desc as CampName
				,COALESCE(COUNT(ccw.conversationId), 0) AS Conversations
				,COALESCE(SUM(ccw.assigned), 0) AS Assign
				,COALESCE(count(ccw.onQueue),0) as OnQueu
				,SUM(CASE WHEN ccw.finishedBy = 1 THEN 1 ELSE 0 END) AS FinishedBySystem
				,SUM(CASE WHEN ccw.finishedBy = 2 THEN 1 ELSE 0 END) AS FinishedByAgent
				,b.AreaName as AreaName
				,1 as IsAssignedCamps
				from camDesc b
				left join currentConversationWa ccw on ccw.camId = b.cam_id
				group by b.cam_id, b.cam_desc, b.AreaName
			end
		end
	ELSE IF @Option = 17 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
			IF @groupList IS NOT NULL BEGIN
				IF OBJECT_ID(''tempdb..#WGDelete'') IS NOT NULL DROP TABLE #WGDelete;
				SELECT value As IDwg into #WGDelete FROM fn_RIASplitDelimited(@groupList, '','')
				SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type, IDWG AS IdWg FROM ccRIACampEspWG WHERE IDWG in (select IDwg from #WGDelete)
				ORDER BY IdCampEsp ASC;
			END;
			ELSE BEGIN
				RAISERROR(''ERROR. No existe una lista de campañas con los ids de grupo de trabajo especificados'', 18, 1);
			END;
			RETURN 0;
		END;

	ELSE IF @Option = 18 BEGIN -- Validar si la campaña fue eliminada del area
			DECLARE @activo INT;

			IF @CampType = 0 BEGIN
				SELECT @activo = ISNULL(IDArea, 0)
				FROM ccInbound
				WHERE Inbound_id = @Id;
			END;

			ELSE BEGIN
				SELECT @activo = ISNULL(IDArea, 0)
				FROM ccCamps
				WHERE cam_id = @Id;
			END;

			SELECT @activo;
		END
	END;';
	EXEC(@sql)

	-- =============================================================================
    -- KR243003 (Marco Garcia) 
	-- Se modificó el action 1, para que el valor de isvoicemail, tambien tome sl status 20
	-- CASE WHEN calls.statusCall_id in (19,20) THEN 1 ELSE 0 END AS IsVoicemail,
    -- =============================================================================

SET @process = 'KR243003 drop sp ccsp_AvrsSyncronization MAGV'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_AvrsSyncronization'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_AvrsSyncronization
	END'

EXEC(@sql)

SET  @process = 'KR243003 create sp ccsp_AvrsSyncronization,
modified action 1, to take status 19 and 20
calls.statusCall_id in (19,20)
'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_AvrsSyncronization]
@action SMALLINT,
@maxRecordsToTransfer INT = 10,
@ids varchar(max)= 0
AS
BEGIN
SET NOCOUNT ON;

IF @action = 1
BEGIN
    DECLARE @countrId INT;
    SET @countrId = 1;

    SELECT @countrId = valor
    FROM ccSettings
    WHERE setting_id = 104;

          -- Declarar la variable tipo tabla
        declare @tempCalls table(
        cal_id INT,
        user_id INT,
        Inbound_id INT,
        calif_id int,
        cal_extension INT,
        cal_inicio DATETIME,
        phone VARCHAR(50),
        duration INT,
        cal_key VARCHAR(50),
        cal_manual int,
        cal_puerto INT,
        dni_id INT,
        fvalida datetime,
        cal_whohung int,
        califSub_id int,
        cal_tMoh INT,
        dateEnd DATETIME,
        callType INT,
        avrsId INT,
        prefijo VARCHAR(20),
        isCallRecord BIT,
        DNIS VARCHAR(50),
        IDWG VARCHAR(1000),
        IsVoicemail BIT,
        VirtualAgentId int
    );

        declare @deleteRow table(id int primary key);
        declare @relationCallIdUser table(cal_id int, user_id int);

    WITH callsIn AS (
        SELECT TOP (@maxRecordsToTransfer)
            calls.cal_id as CallId,
            CASE WHEN ccInbound.chat = 11 THEN 0 ELSE calls.[User_id] END AS [user_id],
            calls.Inbound_id,
            calls.calif_id,
            CAST(cal_extension AS INT) AS cal_extension,
            cal_inicio,
            cal_ANI AS phone,
            ISNULL(cal_tDialog - CASE WHEN ccInbound.recordHold = 1 THEN 0 ELSE cal_tMoh END, 0)
            + CASE WHEN stopRecording = 0 THEN ISNULL(trans.tDespuesXfer, 0) ELSE 0 END AS duration,
            cal_key,
            0 AS cal_manual,
            cal_puerto,
            calls.dni_id,
            fvalida,
            cal_whohung,
            ISNULL(CAST(califSub_id AS SMALLINT), 0) AS califSub_id,
            CASE
                WHEN trans.tAntesXfer IS NULL THEN cal_tMoh
                WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0
                ELSE cal_tMoh - trans.tAntesXfer
            END AS cal_tMoh,
            DATEADD(ss, ISNULL(cal_tDialog, 0), cal_inicio) AS dateEnd,
            avrs.tipo + 1 AS callType,
            avrs.id AS avrsId,
            ccInbound.prefijo,
            CONVERT(BIT, CASE WHEN ISNULL(calls.file_moved, 1) = 2 THEN 0 ELSE 1 END) AS isCallRecord,
            ISNULL(dni.dni_numero, '''') AS DNIS,
            dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG,
            0 AS IsVoicemail,
            CASE WHEN ccInbound.chat = 11 THEN calls.[User_id] ELSE 0 END AS VirtualAgentId
        FROM ccCallsIn AS calls WITH (NOLOCK)
        INNER JOIN ccInbound ON ccInbound.Inbound_id = calls.Inbound_id
        INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 0
        LEFT JOIN ccDNIS dni ON dni.dni_id = calls.dni_id
        LEFT JOIN ccInboundExtend inbExt ON inbExt.Inbound_id = calls.Inbound_id
        LEFT JOIN (
            SELECT cal_id, tipo, SUM(tAntesXfer) AS tAntesXfer, SUM(tDespuesXfer) AS tDespuesXfer
            FROM ccLogTransfers  with(nolock)
            WHERE tipo = 1 AND modo != 7
            GROUP BY cal_id, tipo
        ) trans ON calls.cal_id = trans.cal_id
    ),
    callsOut AS (
        SELECT TOP (@maxRecordsToTransfer)
            calls.cal_id AS CallId,
            user_id AS UserId,
            calls.cam_id AS camAcdId,
            CAST(calls.calif_id AS SMALLINT) AS califId,
            CAST(cal_extension AS INT) AS extension,
            cal_inicio,
            cal_telefono,
            ISNULL(cal_tDialog - CASE WHEN camps.recordHold = 1 THEN 0 ELSE cal_tMoh END, 0)
            + CASE WHEN stopRecording = 0 THEN ISNULL(trans.tDespuesXfer, 0) ELSE 0 END AS duration,
            cal_key,
            cal_manual,
            cal_puerto,
            0 AS dni_id,
            fvalida,
            cal_whohung,
            ISNULL(CAST(califSub_id AS SMALLINT), 0) AS califSub_id,
            CASE
                WHEN trans.tAntesXfer IS NULL THEN cal_tMoh
                WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0
                ELSE cal_tMoh - trans.tAntesXfer
            END AS cal_tMoh,
            DATEADD(ss, ISNULL(cal_tDialog, 0), cal_inicio) AS dateEnd,
            avrs.tipo + 1 AS callType,
            avrs.id AS avrsId,
            camps.prefijo,
            CONVERT(BIT, CASE WHEN ISNULL(calls.file_moved, 1) = 2 THEN 0 ELSE 1 END) AS isCallRecord,
            '''' AS DNIS,
            dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG,
            CASE WHEN calls.statusCall_id in (19,20) THEN 1 ELSE 0 END AS IsVoicemail,
            calls.virtualAgentId as VirtualAgentId
        FROM ccoCallsOut AS calls WITH (NOLOCK)
        INNER JOIN ccCamps camps ON camps.cam_id = calls.cam_id
        INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 1
        LEFT JOIN (
            SELECT cal_id, tipo, SUM(tAntesXfer) AS tAntesXfer, SUM(tDespuesXfer) AS tDespuesXfer
            FROM ccLogTransfers with(nolock)
            WHERE tipo = 2
            GROUP BY cal_id, tipo
        ) trans ON calls.cal_id = trans.cal_id
    )

    INSERT INTO @tempCalls
    SELECT * FROM callsIn
    UNION
    SELECT * FROM callsOut;


    insert into @deleteRow
    select min(avrsId) id
    from @tempCalls
    group by cal_id,callType
    having count(*)>1

    delete from @tempCalls where avrsId in( select id from @deleteRow )
        delete from ccAVRSTransfer where id in( select id from @deleteRow )

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE callType=0 and user_id=0 and virtualAgentId=0)
    BEGIN
                insert into @relationCallIdUser
                select A.cal_id,aglog.User_id from @tempCalls A
                inner join ccCallsIn B with(nolock) on A.cal_id=B.cal_id and A.callType=0
                inner join ccLogAgentesDia aglog with(nolock) on aglog.callID=B.cal_id and aglog.Tipo=A.callType and aglog.TipoStatusAge_id=4

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join ccCallsIn B with(nolock) on A.cal_id=B.cal_id

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join @tempCalls B on A.cal_id=B.cal_id and B.callType=0

                delete from @relationCallIdUser
        END

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE  user_id=0 and virtualAgentId=0 and callType=1 and IsVoicemail =0)
    BEGIN
                insert into @relationCallIdUser
                select A.cal_id,aglog.User_id from @tempCalls A
                inner join ccoCallsOut B with(nolock) on A.cal_id=B.cal_id and A.callType=1
                inner join ccLogAgentesDia aglog with(nolock) on aglog.callID=B.cal_id and aglog.Tipo=A.callType and aglog.TipoStatusAge_id=4

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join ccoCallsOut B with(nolock) on A.cal_id=B.cal_id

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join @tempCalls B on A.cal_id=B.cal_id and B.callType=1
        END

     -- Revisar si hay registros con IsVoicemail = 1
    IF EXISTS (SELECT 1 FROM @tempCalls WHERE IsVoicemail = 1)
    BEGIN
                update A
                set A.duration=B.tDialing
                FROM @tempCalls A
                Inner JOIN ccoLogDials B with(nolock) ON A.cal_id=B.cal_id
        WHERE A.IsVoicemail = 1;
    END

    --elimina los registros y se agrega tabla temporal para revision
    if exists(SELECT 1 FROM @tempCalls WHERE user_id=0 and virtualAgentId=0 and IsVoicemail=0)
    begin
        delete FROM @tempCalls WHERE user_id=0 and IsVoicemail=0 and virtualAgentId=0 and datediff(hh,cal_inicio,getdate())<8
    end
        IF EXISTS (SELECT 1 FROM @tempCalls WHERE user_id=0 and virtualAgentId=0 and IsVoicemail=0)
    BEGIN
                delete A from ccAVRSTransfer A
                inner join @tempCalls t on A.id=t.avrsId
                where t.user_id=0 and t.virtualAgentId=0 and t.IsVoicemail=0
        END

    -- Si no hay registros con IsVoicemail, simplemente devolver los resultados de la variable tipo tabla
    SELECT * FROM @tempCalls;

END
ELSE IF @action = 2
BEGIN
    Delete A
    from ccAVRSTransfer A
    inner join dbo.fn_RIASplitDelimited(@ids,'','') t on A.id=t.Value

END
END;
'
EXEC(@sql);

-- =============================================================================
    -- K070405 (Marco Garcia) 
	-- Se modificaron los sp ccsp_GalateaGetInboundConfiguration, ccsp_ManageQuantumDispositions, ccsp_RIAUpdateACDConfigExtend
	-- debido a que se quito todo lo referebte a las configuración de transferencia de ia desde campañas
	--isnull(AE.TransferToHumanAgents,0) [TransferToHumanAgents],
	--isnull(AE.TransferOnSuccessfulHandling,0) [TransferOnSuccessfulHandling],
	--AE.TransferOnFallback_ExternalNumber,
	--isnull(AE.TransferOnFallback_DirectoryId,0) [TransferOnFallback_DirectoryId],
	--isnull(AE.TransferOnFallback_Mode,0) [TransferOnFallback_Mode],
	--isnull(AE.TransferOnFallback_TimeoutSec,60) [TransferOnFallback_TimeoutSec],
	--AE.TransferOnSuccess_ExternalNumber,
	--isnull(AE.TransferOnSuccess_DirectoryId,0) [TransferOnSuccess_DirectoryId],
	--isnull(AE.TransferOnSuccess_Mode,0) [TransferOnSuccess_Mode],
	--isnull(AE.TransferOnSuccess_TimeoutSec,60) [TransferOnSuccess_TimeoutSec]'
    -- =============================================================================
	set @process = 'K070405 drop sp ccsp_GalateaGetInboundConfiguration MAGV '
set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetInboundConfiguration'')
            begin
            DROP PROCEDURE ccsp_GalateaGetInboundConfiguration;
            end'
EXEC(@sql)

SET @process = 'K070405 create sp ccsp_GalateaGetInboundConfiguration  Se quito lo siguiente en el command 6 MAGV
--isnull(AE.TransferToHumanAgents,0) [TransferToHumanAgents],
	--isnull(AE.TransferOnSuccessfulHandling,0) [TransferOnSuccessfulHandling],
	--AE.TransferOnFallback_ExternalNumber,
	--isnull(AE.TransferOnFallback_DirectoryId,0) [TransferOnFallback_DirectoryId],
	--isnull(AE.TransferOnFallback_Mode,0) [TransferOnFallback_Mode],
	--isnull(AE.TransferOnFallback_TimeoutSec,60) [TransferOnFallback_TimeoutSec],
	--AE.TransferOnSuccess_ExternalNumber,
	--isnull(AE.TransferOnSuccess_DirectoryId,0) [TransferOnSuccess_DirectoryId],
	--isnull(AE.TransferOnSuccess_Mode,0) [TransferOnSuccess_Mode],
	--isnull(AE.TransferOnSuccess_TimeoutSec,60) [TransferOnSuccess_TimeoutSec]'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetInboundConfiguration]
@command int,
@inboundId int,
@AdminId int = 0,
@AreaId SMALLINT = 0
AS
BEGIN

SET NOCOUNT ON;

if @command=0
begin
select descripcion from ccInbound where Inbound_id = @inboundId
end
if @command=1 -- Voice campaign
begin
	select 
	A.Inbound_id [InboundId],
	A.descripcion [Description],
	A.chat [MediaType],
	A.Status,
	isnull(gra.graphic_id,1) [Frame],
	A.tNotas,
	A.tMaxWaitCall,
	A.nMaxQue,
	A.tel_maxwait,
	A.tel_maxqueue,
	A.tel_outservice,
	A.tel_noct,
	A.ShowCalifWnd,
	A.editableCallKey [EditableCallKey],
	A.queuePosition [QueuePosition],
	A.tMaxQueueCallBack,
	A.stopRecording [StopRecording],
	A.dialPrefixOverflow [DialPrefixOverflow],
	isnull(AE.SurveyCamId,0)	 [SurveyCamId],
	isnull(A.callerIdDesc, '''') [CallerIdDesc],
	isnull(A.startStopRecording,0) [StartStopRecording],
	case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then A.callBackSurveyAgent  else cast(0 as bit) end [CallBackSurveyAgent],
	case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then A.callBackSurveyClient else cast(0 as bit) end [CallBackSurveyClient],
	case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then cast(1 as bit) else cast(0 as bit) end [IsRelationSurvey],
	isnull(A.editableDtmf,0) [EditableDtmf],
	isnull(A.addDataCallBackReminder,0) [AddDataCallBackReminder],
	isnull(A.recordHold, 0) [RecordHold],
	isnull(AE.RecordCalls, 1) [RecordCalls],
	isnull(A.EditableContactData, 0) [EditableContactData]
	from ccInbound A
	left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
	left join ccInboundExtend AE on AE.Inbound_id = @inboundId
	left join ccCamps C on C.cam_id=A.cam_id
	where A.Inbound_id=@inboundId
end
if @command=2 -- WhatsApp campaign
begin
	declare @numbers varchar(max)
	select @numbers=COALESCE(@numbers + '','', '''') + number from ccWhatsAppNumbers where inboundId is null or inboundId = 0 and status = 1
	select @numbers=COALESCE(@numbers + '','', '''') + number from ccMetaWhatsAppNumbers where Inbound_Id is null or Inbound_Id = 0 and status = 1

	select i.Inbound_id [InboundId], i.descripcion [Description], i.chat [MediaType], i.Status, isnull(g.graphic_id,1) [Frame],
	ISNULL(c.conexionInfo,'''') [Number],
	ISNULL(@numbers,'''') [FreeNumbersStr],
	CAST(ISNULL(c.closeConversationTime, 0) AS INT) [MaxAnswerTime],
	ISNULL(c.answerTimeoutClient, 30) [MUTimeOutClient],
	ISNULL(c.allowFileAttachments, 0) [AllowFileAttachments],
	i.tNotas [tNotas],
	i.ExitWrapUpDisposition,
	i.ShowCalifWnd,
	i.AssignConversationSameAgent,
	i.ConversationHistoryTime,
	i.MaximumLimitConversationsInQueue as MaxLimitQueueConversations
	from ccInbound i left join ccRIAInboundGraph g on i.Inbound_id = g.Inbound_id
	left join contactMeanIn c on i.Inbound_id = c.inboundId and i.chat = 5 and c.meanContactTypeId = 5
	where i.Inbound_id=@inboundId
end
if @command=3 -- Email campaign
begin
	select 
	A.Inbound_id [InboundId],
	A.descripcion [Description],
	A.chat [MediaType],
	A.Status,
	isnull(gra.graphic_id,1) [Frame],
	A.tNotas,
	A.ShowCalifWnd,
	C.conexionInfo [ConnInfo],
	C.connUser  [ConnUserName],
	C.ConnPass [ConnPwd],
	C.isActive [IsActive],
	C.timeAlertMessage,
	C.closeConversationTime [CloseConversationTime],
	C.answerTimeOut [AnswerTimeOut],
	C.name [SenderName]
	from ccInbound A
	left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
	left join contactMeanIn C on A.Inbound_id = C.inboundId and C.meanContactTypeId=1
	where A.Inbound_id=@inboundId
end
if @command=4 -- Chat campaign
begin
	select 
	i.Inbound_id [InboundId],
	i.descripcion [Description],
	i.chat [MediaType],
	i.Status,
	isnull(ig.graphic_id,1) [Frame],
	i.tNotas,
	i.ShowCalifWnd,
	i.inactiveChatTime [InactiveChatTime],
	i.chatDomain [ChatDomain],
	i.chatTimeOverflow [ChatTimeOverflow],
	i.chatQueueOverflow [ChatQueueOverflow]
	from ccInbound i
	left join ccRIAInboundGraph ig on ig.Inbound_id=i.Inbound_id
	where i.Inbound_id =@inboundId
end
IF @command = 5
BEGIN
	IF EXISTS(
				SELECT TOP 1 1 FROM ccUsers_Roles ur
				INNER JOIN ccRoles_Permissions rp ON ur.Rol_id = rp.Rol_Id
				WHERE ur.[User_id] = @AdminId AND rp.Permissions_Id = 10041
			)
	BEGIN
		SELECT i.Inbound_id AS InboundId, i.descripcion as [Description], ''ACD'' as [Type], i.IDArea as AreaId
		FROM ccInbound i INNER JOIN ccRIACampEspWG wgc on i.Inbound_id = wgc.IdCampEsp AND wgc.Tipo = 0
		WHERE [Status] = 1 AND CHAT = 0
	END
	ELSE BEGIN
		DECLARE @InboundAreaID SMALLINT
		IF(@AreaId > 0)
		BEGIN
			SET @InboundAreaID =  @AreaId
		END
		ELSE BEGIN
			SELECT @InboundAreaID = IDArea FROM ccInbound WHERE Inbound_id = @inboundId
		END

		SELECT i.Inbound_id AS InboundId, i.descripcion as [Description], ''ACD'' as [Type], i.IDArea as AreaId
		FROM ccInbound i INNER JOIN ccRIAAreaWorkGroup awg on i.IDArea = awg.IDArea
		INNER JOIN ccRIACampEspWG wgc on awg.IDWG = wgc.IDWG AND i.Inbound_id = wgc.IdCampEsp AND wgc.Tipo = 0
		WHERE i.IDArea = @InboundAreaID AND i.[Status] = 1 AND i.CHAT = 0
	END
END

IF @command = 6 -- Agente Virtual
BEGIN
	select 
	A.Inbound_id [InboundId],
	A.descripcion [Description],
	A.chat [MediaType],
	A.Status,
	isnull(gra.graphic_id,1) [Frame],
	A.tMaxWaitCall,
	A.nMaxQue,
	A.tel_maxwait,
	A.tel_maxqueue,
	A.tel_outservice,
	A.tel_noct,
	A.ShowCalifWnd,
	A.editableCallKey [EditableCallKey],
	A.queuePosition [QueuePosition],
	A.tMaxQueueCallBack,
	A.stopRecording [StopRecording],
	A.dialPrefixOverflow [DialPrefixOverflow],
	isnull(AE.SurveyCamId,0)	 [SurveyCamId],
	isnull(A.callerIdDesc, '''') [CallerIdDesc],
	isnull(A.startStopRecording,0) [StartStopRecording],
	case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then A.callBackSurveyAgent  else cast(0 as bit) end [CallBackSurveyAgent],
	case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then A.callBackSurveyClient else cast(0 as bit) end [CallBackSurveyClient],
	case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then cast(1 as bit) else cast(0 as bit) end [IsRelationSurvey],
	isnull(A.editableDtmf,0) [EditableDtmf],
	isnull(A.addDataCallBackReminder,0) [AddDataCallBackReminder],
	isnull(A.recordHold, 0) [RecordHold],
	isnull(AE.RecordCalls, 1) [RecordCalls],
	isnull(A.EditableContactData, 0) [EditableContactData],
	isnull(AE.IsCallTranscriptionEnabled,1) [IsCallTranscriptionEnabled]
	from ccInbound A
	left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
	left join ccInboundExtend AE on AE.Inbound_id = @inboundId
	left join ccCamps C on C.cam_id=A.cam_id
	where A.Inbound_id=@inboundId
END

RETURN(0)

SET NOCOUNT OFF;    
END
'
EXEC(@sql)

SET @process = 'K070405 - drop sp ccsp_RIAUpdateACDConfigExtend MAGV'
	SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_RIAUpdateACDConfigExtend'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_RIAUpdateACDConfigExtend
	END
	'
    EXEC(@sql)
	SET @process = 'K070405 create sp ccsp_RIAUpdateACDConfigExtend MAGV
	se quito todo lo referente a 
--@transferToHumanAgents INT = 0,
	--@transferOnFallbackExternalNumber VARCHAR(10) = NULL,
	--@transferOnFallbackDirectoryId INT = NULL,
	--@transferOnFallbackMode BIT = NULL,
	--@transferOnFallbackTimeoutSec SMALLINT = NULL,
	--@transferOnSuccessfulHandling INT = 0,
	--@transferOnSuccessExternalNumber VARCHAR(10) = NULL,
	--@transferOnSuccessDirectoryId INT = NULL,
	--@transferOnSuccessMode BIT = NULL,
	--@transferOnSuccessTimeoutSec SMALLINT = NULL'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAUpdateACDConfigExtend]
	@inbound_id smallint,
	@recordCalls tinyint = NULL,
	@userId smallint = NULL,
	@idArea smallint = NULL,
	@isCreating smallint = NULL,
	@module int = -1,
	@isCallTranscriptionEnabled BIT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @country INT = (select valor from ccSettings where setting_id = 104); 
	DECLARE @excludeIdentifier VARCHAR(255) = CASE WHEN @country = 4 THEN ''IN_COMMON_INTERNATIONAL_RECORD_CALLS'' ELSE ''IN_COMMON_USA_RECORD_CALLS'' END;
	EXEC InsertLogAdminGalatea @action = 1,
								@tableName = ''ccInboundExtend'',
								@columnNameId = ''inbound_id'',
								@valueId = @inbound_id,
								@userId = @userid
	CREATE TABLE #ccInboundExtendTable (
	columnInfo varchar(255),
	dataInfo varchar(255),
	identifierInfo varchar(255)
	)


	DECLARE @chatType INT;

	SELECT @chatType = chat FROM ccInbound WHERE Inbound_id = @inbound_id;

	DECLARE @operation SMALLINT;

	IF @chatType = 11
	BEGIN
			SET @operation = CASE 
							 WHEN @isCreating = 1 THEN 137  -- Crear campaña IA
							 ELSE 138                       -- Editar campaña IA
            END;
	END
	ELSE
	BEGIN
			SET @operation = CASE 
							WHEN @isCreating = 1 THEN 60   -- Crear campaña normal
							ELSE 52                        -- Editar campaña normal
            END;
	END

	IF EXISTS (SELECT * FROM ccInboundExtend WHERE Inbound_id = @inbound_id)
	BEGIN
		
		
		UPDATE ccInboundExtend
		SET 
		    RecordCalls = ISNULL(@recordCalls, RecordCalls),
		    IsCallTranscriptionEnabled = ISNULL(@isCallTranscriptionEnabled, 1)
		WHERE Inbound_id = @inbound_id;

	END
	ELSE
	BEGIN
		INSERT INTO ccInboundExtend (
			Inbound_id, RecordCalls, IsCallTranscriptionEnabled
			)
		VALUES (
			@inbound_id, @recordCalls, @isCallTranscriptionEnabled
			)
	END

	IF (@isCreating > 0  AND @module > -1) 
	BEGIN
		EXEC InsertLogAdminGalatea @action = 2,
									@tableName = ''ccInboundExtend'',
									@columnNameId = ''Inbound_id'',
									@valueId = @inbound_id,
									@userId = @userid,
									@tableTemp = ''#ccInboundExtendTable''
	END
	ELSE IF (@isCreating = 1  AND @chatType = 11)
	BEGIN
		EXEC InsertLogAdminGalatea @action = 2,
									@tableName = ''ccInboundExtend'',
									@columnNameId = ''Inbound_id'',
									@valueId = @inbound_id,
									@userId = @userid,
									@tableTemp = ''#ccInboundExtendTable''
	END
	ELSE 
	BEGIN
		IF (@recordCalls != 1)
			EXEC InsertLogAdminGalatea @action = 2,
										@tableName = ''ccInboundExtend'',
										@columnNameId = ''Inbound_id'',
										@valueId = @inbound_id,
										@userId = @userid,
										@tableTemp = ''#ccInboundExtendTable'';
	END

	INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
	SELECT
		(SELECT
			[AreaName]
		FROM ccRIACat_Areas
		WHERE IDArea = @idArea),
		GETDATE(),
		(SELECT
			[Login]
		FROM ccUsers
		WHERE User_id = @userid),
		@operation,
		CASE WHEN @isCreating = 1 THEN 3 ELSE @module END,
		CCIE.identifierInfo,
		CASE
			WHEN CCIE.identifierInfo IS NOT NULL AND CCIE.identifierInfo <> '''' THEN 
					CASE
						WHEN CCIE.identifierInfo IN (''IN_COMMON_INTERNATIONAL_RECORD_CALLS'') 
							THEN 
								CASE
									WHEN CCIE.dataInfo = 1 THEN ''COMMON_ENABLED''
									ELSE ''COMMON_DISABLED''
								END
						WHEN CCIE.identifierInfo IN (''IN_COMMON_USA_RECORD_CALLS'') 
							THEN
								CASE 
									WHEN CCIE.dataInfo = 1 THEN ''COMMON_USA_RECORD_CALLS_MODE_ALL''
									WHEN CCIE.dataInfo = 2 THEN ''COMMON_USA_RECORD_CALLS_MODE_AUTH''
									WHEN CCIE.dataInfo = 4 THEN ''COMMON_USA_RECORD_CALLS_MODE_NOAUTH''
									ELSE ''COMMON_DISABLED'' 
								END
						WHEN CCIE.identifierInfo IN (''IN_CALL_IA_CALL_TRANSCRIPTION'') 
							THEN
								CASE
									WHEN CCIE.dataInfo = 1 THEN ''COMMON_ENABLED''
									ELSE ''COMMON_DISABLED''
								END
						ELSE CCIE.dataInfo
					END
				ELSE ''''
			END,
			(SELECT
				[descripcion]
			FROM ccInbound
			WHERE inbound_id = @inbound_id)
	FROM #ccInboundExtendTable AS CCIE 
	where CCIE.identifierInfo != @excludeIdentifier;

	EXEC InsertLogAdminGalatea	@action = 3,
								@tableName = ''ccInboundExtend'',
								@columnNameId = ''Inbound_id'',
								@valueId = @inbound_id,
								@userId = @userid;

	IF OBJECT_ID(N''tempdb..#ccInboundExtendTable'') IS NOT NULL
		DROP TABLE #ccInboundExtendTable
	SET NOCOUNT OFF;
END'
EXEC(@sql);

    -- =====================================================================
    -- KR243002 - se realizaron cambios en los sp ccsp_DLRGetDialInfo y ccsp_DLRgetDialPrefix
	-- para obtener la configuración de grabación por campaña
    -- =====================================================================
	SET @process = 'KR243002 Drop Procedure ccsp_DLRGetDialInfo '
SET @sql = '
    IF EXISTS (SELECT * from sys.procedures WHERE name = N''ccsp_DLRGetDialInfo'')
    BEGIN
        DROP PROCEDURE dbo.ccsp_DLRGetDialInfo;
    END'
EXEC(@sql);
SET @process = 'KR243002 Se añadio la variable @recordVoiceMail, el cual el valor se obtiene de ccampsExtend'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_DLRGetDialInfo]
@callout_id int,
@cam_id smallint=0,
@iPortNumber smallint = 0,
@trunkId int=0
AS
set nocount on
declare @message_name as varchar(8000), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)    
declare @prefix as varchar(15), @trunk varchar(200)
declare @prefixCalKey as varchar(30)
declare @tNoContesta as tinyint
declare @ani as varchar(32)
declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint, @rotativeAlgo tinyint
declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint
declare @ivr_script smallint, @surveycamid int
declare @call_record_cam as tinyint
declare @pais as tinyint 
declare @sipHdrFormat varchar(255)
declare @PrefixRec varchar(40)
declare @recordHold bit, @recordIvr BIT, @recordVoiceMail bit
declare @croute varchar(32)

set @prefix =''''
set @tNoContesta = 25
set @ani=''''
set @iTipoDial = 0
set @detectAnswerMachine = 0
set @detectVoiceMail =1
set @cam_tnotas = 30
set @keepDial = 0

select @pais = valor from ccsettings with(nolock) where setting_id = 104
select @PrefixRec=ISNULL(prefijo,'''') from ccCamps nolock where cam_id = @cam_id

-- Mensajes
select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
from dbo.fn_ccCamps_SelMessage(@cam_id)

-- Prefijo por puerto
select @prefix = prefix, @trunk=isnull(trunk,'''') from cstoProvedor with(nolock) where provedor_id = (
    select provedor_id from ccodialers with(nolock) where puerto = @iPortNumber )
-- Prefijo por campa?a
if @prefix =''''
    select @prefix = dialPrefix from ccCamps with(nolock) where cam_id = @cam_id
-- Prefijo general, si es que esta habilitado
if @prefix ='''' and ((select cast(valor as int) from ccsettings nolock where setting_id =102) & 1 = 1)
    select @prefix = valor from ccsettings with(nolock) where setting_id =101

select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

-- Propiedades de campa?a
select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
@call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0), @rotativeAlgo=isnull(rotativeAlgo,0), @recordHold=ISNULL(recordHold,0)
,@PrefixRec=ISNULL(prefijo,''''), @recordIvr=ISNULL(recordIvr,0)
from ccCamps C with(nolock) where C.cam_id=@cam_id


SELECT @recordVoiceMail = ISNULL(cce.CanRecordVoicemail, 0)
FROM dbo.ccCampsExtend AS cce
WHERE cce.cam_id = @cam_id;


if @surveycamid > 0
    select @ivr_script = isnull(ivrscript,0) from cccamps with(nolock) where cam_id = @surveycamid
        
--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile
FROM ccCampsMsgs VE with(nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

--Agrega prefijo Marcacion con directo
declare @mainPrefix varchar(1), @phones varchar(max), @apikeyQuantum VARCHAR(300);
set @prefixCalKey=''''
select @mainPrefix = valor from ccSettings where setting_id=202
select @apikeyQuantum = ISNULL(valor, '''') from dbo.ccSettings2 where setting_id=284
declare @tmpccoCallsOutSource table(callout_id int primary key,dialPrefix   varchar(30) null
,cal_Key    varchar(40)
,cal_telefono   varchar(30),cal_telefono2   varchar(30),cal_telefono3   varchar(30),cal_telefono4   varchar(30),cal_telefono5   varchar(30)
,Dato1  varchar(255),Dato2  varchar(255),Dato3  varchar(255),Dato4  varchar(255),Dato5  varchar(255)
,recyclePhone   SMALLINT
,recycleType BIT
,data_api_quantum VARCHAR(MAX)
)
insert into @tmpccoCallsOutSource
SELECT 
    c.callout_id,
    c.dialPrefix,
    c.cal_Key,
    c.cal_telefono, c.cal_telefono2, c.cal_telefono3, c.cal_telefono4, c.cal_telefono5,
    c.Dato1, c.Dato2, c.Dato3, c.Dato4, c.Dato5,
    c.recyclePhone, c.recycleType,
    (
        CASE 
            WHEN RIGHT(RTRIM(ISNULL(c.data_api_quantum, N''{}'')), 1) = N''}''
                THEN LEFT(RTRIM(ISNULL(c.data_api_quantum, N''{}'')), LEN(RTRIM(ISNULL(c.data_api_quantum, N''{}''))) - 1)
            ELSE RTRIM(ISNULL(c.data_api_quantum, N''{}''))
        END
        +
        CASE 
            WHEN LEN(
                    LTRIM(RTRIM(
                        CASE 
                            WHEN LEFT(LTRIM(RTRIM(ISNULL(c.data_api_quantum, N''{}''))),1) = N''{'' 
                            AND RIGHT(RTRIM(ISNULL(c.data_api_quantum, N''{}'')),1) = N''}''
                            THEN SUBSTRING(
                                    LTRIM(RTRIM(ISNULL(c.data_api_quantum, N''{}''))),
                                    2,
                                    LEN(LTRIM(RTRIM(ISNULL(c.data_api_quantum, N''{}'')))) - 2
                                )
                            ELSE LTRIM(RTRIM(ISNULL(c.data_api_quantum, N''{}'')))
                        END
                    ))
                ) > 0 
            THEN N'','' ELSE N'''' 
        END
        +
        N''"country": '' + CONVERT(NVARCHAR(20),@pais)
        +
        N'', "time_zone": '' + CONVERT(NVARCHAR(20),
                            CASE
                                WHEN c.iZonaHoraria  > 0 THEN c.iZonaHoraria
                                WHEN c.iZonaHoraria2 > 0 THEN c.iZonaHoraria2
                                WHEN c.iZonaHoraria3 > 0 THEN c.iZonaHoraria3
                                WHEN c.iZonaHoraria4 > 0 THEN c.iZonaHoraria4
                                WHEN c.iZonaHoraria5 > 0 THEN c.iZonaHoraria5
                                ELSE 0
                            END
                        )
        +
        N''}''
    ) AS data_api_quantum
FROM ccoCallsOutSource AS c WITH (NOLOCK)
WHERE c.callout_id = @callout_id;

SELECT @prefixCalKey=CASE WHEN @mainPrefix=''1'' THEN isnull(dialPrefix,'''') ELSE '''' END,
    @phones=cal_telefono+'';''+cal_telefono2+'';''+cal_telefono3+'';''+cal_telefono4+'';''+cal_telefono5
FROM @tmpccoCallsOutSource

if @iPortNumber >= 0 
begin
    declare @Anis table(id int, pid varchar(2), phone varchar(32), ani varchar(32))

    insert @Anis
    exec ccsp_DLRGetRotativeANI @callout_id=@callout_id,@phones=@phones,@aniList=@lista_id,@algo=@rotativeAlgo

    SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
    if len(@sipheader)>32 and left(@sipheader,1)=''@''
        select @croute=substring(@sipheader, 2, 32)
            
    SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)
    , ISNULL(cpt.Prioridad,''12345NNN'') dial_tels
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 1) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE C.cal_telefono  END cal_telefono
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 2) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono2 END cal_telefono2
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 3) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono3 END cal_telefono3
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 4) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono4 END cal_telefono4
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 5) AND ISNULL(recycleType, 1) = 0) THEN '''' Else c.cal_telefono5 END cal_telefono5
    , isnull(@message_name, '''') as message_name
    , @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
    , case when anis.p1 <> '''' then anis.p1 else @ani end ani
    , case when anis.p2 <> '''' then anis.p2 else @ani end ani2
    , case when anis.p3 <> '''' then anis.p3 else @ani end ani3
    , case when anis.p4 <> '''' then anis.p4 else @ani end ani4
    , case when anis.p5 <> '''' then anis.p5 else @ani end ani5
    , @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail
    , @cam_tnotas cam_tnotas, @keepDial keepDial
    , isnull(@messageDNCL_name, '''') as messageDNCL_name
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono) as call_record
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono2) as call_record2
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono3) as call_record3
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono4) as call_record4
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono5) as call_record5
    , isnull(@messageDNCLConfirm_name, '''') as messageDNCLConfirm_name
    , isnull(@MohFiles,'''') as mohFiles
    ,@ivr_script ivrScript
    ,@sipheader data
    ,@PrefixRec as Prefijo,
    dbo.GetCarrierByTel(C.cal_telefono) carrier1, 
    dbo.GetCarrierByTel(cal_telefono2) carrier2, 
    dbo.GetCarrierByTel(cal_telefono3) carrier3, 
    dbo.GetCarrierByTel(cal_telefono4) carrier4, 
    dbo.GetCarrierByTel(cal_telefono5) carrier5,
    @recordHold as recordHold,
    @recordIvr as recordIvr,
    isnull(C.data_api_quantum, '''') AS data_api_quantum,
    @apikeyQuantum AS key_api_quantum,
    dbo.GetRoute(C.cal_telefono,isnull(@croute,''''),@trunkId) destination,
    @trunk trunk,
	@recordVoiceMail as recordVoiceMail
    FROM @tmpccoCallsOutSource C
    left join ccoCallPriorityOrder cpo with(nolock) on cpo.callout_id = c.callout_id
    left join ccCampsPrioridadTel cpt on cpt.cam_id = @cam_id
    left join (SELECT * FROM (SELECT pid,ani FROM @Anis)a PIVOT(MAX(ani) FOR pid IN(p1,p2,p3,p4,p5)) AS pt) anis on 0=0
    WHERE C.callout_id = @callout_id
    OPTION (RECOMPILE);
    return
end 
set nocount off'
EXEC(@sql);

SET @process = 'KR243002 DROP PROCEDURE ccsp_DLRgetDialPrefix'
SET @sql = '
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = N''ccsp_DLRgetDialPrefix'')
BEGIN
    DROP PROCEDURE ccsp_DLRgetDialPrefix;
END'
EXEC(@sql)

SET @process = 'KR243002 CREATE SP ccsp_DLRgetDialPrefix se agregó la variable @recordVoiceMail, para validar cuando se tiene
que grabar desde el timbrado y cuando desde que el cliente contesta'
SET @sql = 'CREATE procedure [dbo].[ccsp_DLRgetDialPrefix]
    @cam_id smallint=0,
    @iPortNumber smallint = 0,
    @phone varchar(30) = '''',
    @callout_id int = 0,
    @trunkId int=0
    as
    declare @prefix as varchar(15), @sipheader varchar(500), @trunk varchar(200)
    declare @ani as varchar(32)
    declare @pais as tinyint
    declare @aniglobal varchar(32), @sipHdrFormat varchar(255)
    declare @ivr_script smallint, @surveycamid int
    declare @call_record tinyint, @tNoContesta tinyint, @detectAnswerMachine smallint, @detectVoiceMail tinyint
    declare @PrefixRec varchar(40)
    declare @carrier varchar(255)
    declare @recordHold bit, @recordIvr BIT, @recordVoiceMail bit
    declare @RotativeAlgo int ,@aniList smallint
    declare @croute varchar(32)

    select @pais = valor from ccsettings with(nolock) where setting_id = 104
    select @aniglobal = valor from ccsettings with(nolock) where setting_id = 177

    set @prefix =''''
    -- Prefijo por puerto
    select @prefix = prefix, @trunk=isnull(trunk,'''') from cstoProvedor nolock where provedor_id = (
        select provedor_id from ccodialers nolock where puerto = @iPortNumber )

    -- Prefijo por campa?a,
    if @prefix =''''
        select @prefix = dialPrefixMan from ccCamps where cam_id = @cam_id

    -- Prefijo general
    if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 2 = 2)
        select @prefix = valor from ccsettings with(nolock) where setting_id =101

    -- Ani
    select @RotativeAlgo = RotativeAlgo from ccCamps where cam_id = @cam_id
    select @aniList = id_anilist from ccCamps where cam_id =@cam_id

	SELECT @recordVoiceMail = ISNULL(cce.CanRecordVoicemail, 0)
	FROM dbo.ccCampsExtend AS cce
	WHERE cce.cam_id = @cam_id;

    if @RotativeAlgo=0 and @aniList>0  begin
    set @ani = dbo.TelAni(@phone, @aniList )
    end
    else begin
        set @ani=''''
    end
    set @ani = dbo.TelAni(@phone, (select id_anilist from ccCamps where cam_id =@cam_id) )

    --AnswerMachine Message Files
    DECLARE @MsgFiles VARCHAR(8000)
    SELECT @MsgFiles = COALESCE(@MsgFiles + '','', '''') + V.msgfile
    FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 8 ORDER BY orden

    IF EXISTS (select 1 from ccCampsMsgs where Type = 20 and cam_id = @cam_id)
    BEGIN
        select @MsgFiles = @MsgFiles + '',TTS/message.wav''
    END

    --Custom MOH Files
    DECLARE @MohFiles VARCHAR(8000)
    SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile
    FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

    select @surveycamid = 0, @ivr_script = 0

    select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta = cam_tNoContesta, @ani = case when @ani = '''' then ani else @ani end
    ,@detectAnswerMachine = detectAnswerMachine, @detectVoiceMail = detectVoiceMail
    ,@call_record = dbo.EnableCallRecord(call_record, @pais, @phone), @surveycamid = isnull(surveycamid,0), @recordHold=ISNULL(recordHold,0)
    ,@recordIvr=ISNULL(recordIvr,0), @PrefixRec = ISNULL(prefijo,'''')
    from ccCamps NOLOCK where cam_id = @cam_id

    SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
    if len(@sipheader)>32 and left(@sipheader,1)=''@''
        select @croute=substring(@sipheader, 2, 32)

    if @surveycamid > 0
        select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid


    if @ani = '''' begin
    set @ani = @aniglobal
    end

        set @carrier = ''''
        select @carrier = dbo.GetCarrierByTel(@phone)

    select @prefix as sDialPrefix, @tNoContesta as tNoContesta,@ani as ani, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail,
    @call_record as call_record, isnull(@MsgFiles,'''') as messageFiles, isnull(@MohFiles,'''') as mohFiles, @ivr_script ivrScript, @sipheader data
    ,@PrefixRec PrefijoRec, @carrier Carrier, @recordHold recordHold, @recordIvr recordIvr,
    dbo.GetRoute(@phone,isnull(@croute,''''),@trunkId) destination, @trunk trunk, @recordVoiceMail as recordVoiceMail'

EXEC(@sql);













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
