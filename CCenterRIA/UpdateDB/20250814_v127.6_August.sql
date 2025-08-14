/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio García
Date: 2025/06/23
Description: Demo/Sprint2
Database: CCenterRia
Required version: 127.2
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
SET @versionfix = 6
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

	--------------------------------- BEGIN MACL ------------------------------------------------
	SET @process = 'K070253 - Inserting setting 290'
	SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 290)
	BEGIN
		INSERT INTO ccSettings2(setting_id, valor, descripcion, Status, tipo, detalle, description, bLoadSettings)
		VALUES(290, '''', ''URL para la API de Quantum'', 1, ''GRL'', ''URL para la API de Quantum'', ''API URL for Quantum'', 0)
	END'
		EXEC(@sql)

	SET @process = 'K070253 - delete store procedure [ccsp_ManageQuantumDispositions]'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_ManageQuantumDispositions'')
			BEGIN
				DROP PROCEDURE ccsp_ManageQuantumDispositions
			END'
	EXEC(@sql)

	SET @process = 'K070253 - create store procedure [ccsp_ManageQuantumDispositions]'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_ManageQuantumDispositions]
			@Action INT,
			@CampId INT = NULL,
			@CampType INT = NULL
	AS
	BEGIN
		DECLARE @Inbound INT = 0, @Outbound INT = 1
		IF @Action = 1 --Get API Data
		BEGIN
			DECLARE @key VARCHAR(255)
			SELECT @key = valor FROM ccSettings2 WHERE setting_id = 284
			SELECT valor AS ApiUrl, @key AS [Key] FROM ccSettings2 WHERE setting_id = 290
		END
		IF @Action = 2 --Get Quantum Agent Data
		BEGIN
			SELECT quantumAgentId from ccVirtualAgent where campType = @CampType and idCampaign = @CampId
		END
		IF @Action = 3 --Get Quantum Dispositions by camp
		BEGIN
			IF @CampType = @Inbound
			BEGIN
				SELECT tc.calif_id AS [Id], tc.[Description] AS [Description] FROM ccCalifCamp cc
				INNER JOIN ccTipoCalif tc
				ON cc.calif_id = tc.calif_id
				WHERE cc.tipo = 0
				AND cc.cam_id = @CampId
			END
			IF @CampType = @Outbound
			BEGIN
				SELECT tc.calif_id AS [Id], tc.[Description] AS [Description] FROM ccCalifCamp cc
				INNER JOIN ccTipoCalifOut tc
				ON cc.calif_id = tc.calif_id
				WHERE cc.tipo = 1
				AND cc.cam_id = @CampId
			END
		END
	END'
	EXEC(@sql)
	---------------------------------- END MACL -------------------------------------------------

	------------------- BEGIN MAGV --------------------------------
	/*DEV3-1182*/
	SET @process = 'K070088 - Se realiza cambio de tags, para portugues ya que estaba mal la etiqueta para el historial de actividad'
	SET @sql = '
	IF EXISTS (
		SELECT 1 FROM dbo.ccGalateaIdentifiers
		WHERE Description = ''COMMON_NONE_O''
	)
	BEGIN
		UPDATE dbo.ccGalateaIdentifiers
		SET TagEs = ''Ninguna'', TagPt = ''Nenhuma''
		WHERE Description = ''COMMON_NONE_O''
	END
	'
	EXEC(@sql)


	/*K070254*/
	-- Para ccoCallsOutDispositionIA
	SET @process = 'K070254 - add column disposition_id in ccoCallsOutDispositionIA table to save CW dispositions'
	SET @sql = 'IF NOT EXISTS (
		SELECT 1
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''ccoCallsOutDispositionIA''
		  AND COLUMN_NAME = ''disposition_id''
	)
	BEGIN
		ALTER TABLE ccoCallsOutDispositionIA ADD 
		disposition_id SMALLINT NULL
	END;'

	EXEC(@sql)

	-- Para ccCallsInDispositionIA
	SET @process = 'K070254 - add column disposition_id in ccCallsInDispositionIA table to save CW dispositions'
	SET @sql = 'IF NOT EXISTS (
		SELECT 1
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''ccCallsInDispositionIA''
		  AND COLUMN_NAME = ''disposition_id''
	)
	BEGIN
		ALTER TABLE ccCallsInDispositionIA ADD 
		disposition_id SMALLINT NULL
	END;'
	EXEC(@sql)

	SET @process = 'K070254 - delete store procedure [SaveDispositionsAI]'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''SaveDispositionsAI'')
			BEGIN
				DROP PROCEDURE SaveDispositionsAI
			END'
	EXEC(@sql)

	SET @process = 'K070254 - CREATE store procedure [SaveDispositionsAI]
	1.- Se le agregó al sp el parametro @disposition_Id para recibir la calificación de CW
	2.- Se modificaron las opciones 1 y 3, para agregarles el @disposition_Id y se pueda registrar '
	SET @sql = 'CREATE PROCEDURE [dbo].[SaveDispositionsAI]
			@action smallint = null,
			@call_Id int = null,
			@Qualification varchar(max) = null,
			@result VARCHAR(MAX) = null,
			@Observations VARCHAR(MAX) = null,
			@Transcription VARCHAR(MAX) = null,
			@CamType bit = 0,
			@disposition_Id SMALLINT = null

			AS
			IF @action = 1  --Outbound
			BEGIN
				insert into ccoCallsOutDispositionIA (call_id, Qualification, result, Observations, disposition_id) values (@call_Id, @Qualification, @result, @Observations, @disposition_Id)
			END
		
			IF @action = 2 --Outbound
			BEGIN
				insert into ccoCallsOutTranscriptionIA (call_id, Transcription) values (@call_Id, @Transcription)
			END

			IF @action = 3 --Inbound
			BEGIN
				insert into ccCallsInDispositionIA (call_id, Qualification, result, Observations, disposition_id) values (@call_Id, @Qualification, @result, @Observations, @disposition_Id)
			END

			IF @action = 4 --Inbound
			BEGIN
				insert into ccCallsInTranscriptionIA (call_id, Transcription) values (@call_Id, @Transcription)
			END'
	EXEC(@sql)
	------------------- END MAGV  ----------------------------------------
	------------------- Begin DMM  ----------------------------------------
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_AIToHumanTransfer'')
			BEGIN
				DROP PROCEDURE ccsp_AIToHumanTransfer
			END'
	EXEC(@sql)

	SET @process = 'se agregan @action 3 y @action=4 para transferencias de gesión exitosa y no entenidmiento'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_AIToHumanTransfer]
		@action int = null,
		@camId int = null,
		@CallOutId int = null,
		@acdId int = null

	AS
	BEGIN 
		if @action = 1
		Begin
			select Inbound_id from ccInbound where cam_id = @camId
		end

		if @action = 2
		Begin
			select data_overflow_variables_quantum from ccoCallsOutSource where callout_id = @CallOutId
		end

		if @action = 3
		Begin
			select idForNonComprehension from ccInbound where Inbound_id = @acdId
		end

		if @action = 4
		Begin
			select idForSuccessfulTransaction from ccInbound where Inbound_id = @acdId
		end
	END'
	EXEC(@sql)

	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_IVRGetEspecialidadByDnis'')
			BEGIN
				DROP PROCEDURE ccsp_IVRGetEspecialidadByDnis
			END'
	EXEC(@sql)

	SET @process = 'Se hacen modificaciones pera validar si la llamada será rechazada al ser xfer de IA a humano '
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_IVRGetEspecialidadByDnis] 
		@sDnis varchar (40),
		@sAni varchar (19) = null,
		@IsAITransferedToHuman bit = 0,
		@acdId int = 0
		AS
		set nocount on

		declare @inbound_id INT  = 0, @nMaxQue    SMALLINT = 0;

		if @IsAITransferedToHuman = 1
		begin
			SET @inbound_id = ISNULL(@acdId, 0);
		end
		else 
		begin
			if @sDnis =  ''''
				set @inbound_id = 0
			else
				select @inbound_id = inbound_id from ccInboundDnis where dni_id in (select dni_id from ccDnis where dni_numero like @sDnis)
		end

		if @inbound_id > 0 
		begin
			select @nMaxQue = nMaxQue from ccInbound where inbound_id = @inbound_id
	
			if @IsAITransferedToHuman = 0
			begin
				-- Verificamos si el Dnis no esta bloqueado
				if exists (select dni_id from ccDnis where dni_status=1 and dni_isBlock=1 and dni_numero = @sDnis) 
				begin
					select -1 inbound_id, @nMaxQue nMaxQue
					return(0)
				end
			end

			-- Valida si el ani esta en lista negra
			if @inbound_id > 0 and exists(select telefono from ACDlistanegra A join ccListaNegra L on A.idtipolista = L.idtipolista where A.status=1 and telefono=@sAni and inbound_id=@inbound_id) 
			begin
				select -1 inbound_id, @nMaxQue nMaxQue
				return(0)
			end

		end 

		select isNull(@inbound_id, 0) as inbound_id, 0 as ''is900'', @nMaxQue as nMaxQue
		return(0)

		set nocount off'
	EXEC(@sql)
------------------- End DMM  ----------------------------------------

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
