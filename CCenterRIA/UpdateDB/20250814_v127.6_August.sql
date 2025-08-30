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

	--------------------------------- BEGIN ALTERS AND ADD ------------------------------------------------
	SET @process = 'K070253 - Inserting setting 290'
	SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 290)
	BEGIN
		INSERT INTO ccSettings2(setting_id, valor, descripcion, Status, tipo, detalle, description, bLoadSettings)
		VALUES(290, '''', ''URL para la API de Quantum'', 1, ''GRL'', ''URL para la API de Quantum'', ''API URL for Quantum'', 0)
	END'
		EXEC(@sql)

	SET @process = 'K070248 - add setting for transcription 289'
	SET @sql = '
		IF NOT EXISTS (
			SELECT 1
			FROM [CCenterRIA].[dbo].[ccSettings2]
			WHERE setting_id = 289
		)
		BEGIN
			INSERT INTO [CCenterRIA].[dbo].[ccSettings2] (
				[setting_id],
				[valor],
				[descripcion],
				[Status],
				[Tipo],
				[detalle],
				[description],
				[bLoadSettings],
				[validate]
			)
			VALUES (
				289,
				''1|521|12'',
				''Permite configurar el estado, peso máximo y tiempo de retención de la transcripción de llamadas.'',
				1,
				''ADM'',
				''0:Disabled,1:Enabled|Maximum information weight|Retention time'',
				''Allows configuring the status, maximum weight, and retention time of the call transcription.'',
				1,
				''.*''
			);
		END
	'

	EXEC(@sql)

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

	SET @process = 'K070108 - add column CallbackAT in ccCallsInDispositionIA table'
	SET @sql = '
		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''CallbackAT'' AND Object_ID = Object_ID(N''ccCallsInDispositionIA''))
		BEGIN
			ALTER TABLE ccCallsInDispositionIA ADD CallbackAT DATETIME NULL
		END
	'
	EXEC(@sql)

	--------------------------------- END ALTERS AND ADD ------------------------------------------------

			--------------------------------- BEGIN JUAN MEDINA ------------------------------------------------


	-- K070248 AND K070108

	SET @process = 'K070248 & K070108 - Drop SP SaveDispositionsAI'

    SET @sql = 'if exists (select * from sys.procedures where name = N''SaveDispositionsAI'')
    BEGIN
        DROP PROCEDURE dbo.SaveDispositionsAI;
    END'
    EXEC(@sql);

	 SET @process = 'K070248 & K070108- CREATE SP SaveDispositionsAI'

    SET @sql = '
		
	CREATE PROCEDURE SaveDispositionsAI
    @action        smallint    = NULL,
    @call_Id       int         = NULL,
    @Qualification varchar(MAX)= NULL,
    @result        varchar(MAX)= NULL,
    @Observations  varchar(MAX)= NULL,
	@CallbackAT    DATETIME = NULL,
    @Transcription varchar(MAX)= NULL,
    @CamType       bit         = 0,
	@disposition_Id SMALLINT = null
	AS
	BEGIN
		SET NOCOUNT ON;
		--Variables para devolución de llamada 
		DECLARE @cal_key varchar(40) ='''';
		DECLARE @cam_id smallint;
		DECLARE @cal_telefono varchar(19);
		DECLARE @inbound_id smallint = NULL;
		DECLARE @CanReprogram smallint  = null

		-- Validacion del Status del Setting 289
		DECLARE @trans_status BIT = NULL;
		
		DECLARE @valor  NVARCHAR(15) = NULL;

		SELECT @valor = TRY_CAST(valor AS NVARCHAR(15))	
		FROM ccSettings2
		WHERE setting_id = 289;

		DECLARE @status NVARCHAR(5);
		DECLARE @sep    INT;

		SET @sep = CHARINDEX(''|'', ISNULL(@valor, ''''));
		SET @status = CASE
						WHEN @sep > 0 THEN SUBSTRING(@valor, 1, @sep - 1)
						ELSE ISNULL(@valor, '''')
					  END;

		IF @action = 1  -- Outbound
		BEGIN
			INSERT INTO ccoCallsOutDispositionIA (call_id, Qualification, result, Observations,disposition_id)
			VALUES (@call_Id, @Qualification, @result, @Observations,@disposition_Id);
		END

		IF @action = 2 AND @status = ''1''   -- Outbound
		BEGIN
			--Se deja pendiente para el siguiente Sprint 
			--DECLARE @cam_id smallint = NULL;

			--Select @cam_id = cam_id 
			--From ccoCallsOut
			--Where cal_id = @call_Id

			--Select @trans_status = IsCallTranscriptionEnabled
			--From ccCampsExtend
			--Where cam_id  = @cam_id

			--IF @trans_status = 1
			--BEGIN
			--	INSERT INTO ccoCallsOutTranscriptionIA (call_id, Transcription)
			--	VALUES (@call_Id, @Transcription);
			--END

			INSERT INTO ccoCallsOutTranscriptionIA (call_id, Transcription)
				VALUES (@call_Id, @Transcription);
		END

		IF @action = 3  -- Inbound
		BEGIN
			Select @CanReprogram = CanReprogram from ccTipoCalif where calif_id = @disposition_Id
			
			IF (@CallbackAT IS NOT NULL  
				AND CONVERT(datetime, @CallbackAT, 120) IS NOT NULL 
				AND CONVERT(datetime, @CallbackAT, 120) > GETDATE()  
				AND @CanReprogram <> 0)
			BEGIN
				INSERT INTO ccCallsInDispositionIA (call_id, Qualification, result, Observations, CallbackAT,disposition_id)
				VALUES (@call_Id, @Qualification, @result, @Observations,@CallbackAT,@disposition_Id);

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
			END

			ELSE BEGIN
				INSERT INTO ccCallsInDispositionIA (call_id, Qualification, result, Observations,disposition_id)
				VALUES (@call_Id, @Qualification, @result, @Observations,@disposition_Id);
			END

		END

		IF @action = 4 AND @status = ''1''   -- Inbound
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
	END
	
	'

	EXEC(@sql);


	SET @process = 'K070108 - Drop SP ccsp_INInsertaCallBack'

    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_INInsertaCallBack'')
    BEGIN
        DROP PROCEDURE dbo.ccsp_INInsertaCallBack;
    END'
    EXEC(@sql);

	 SET @process = 'K070108 - CREATE SP ccsp_INInsertaCallBack'

    SET @sql = '
	
	CREATE PROCEDURE ccsp_INInsertaCallBack
	@cal_key varchar(40) ='''',
	@cam_id smallint,
	@cal_telefono varchar(19),
	@fechadial varchar(30),
	@dato1 varchar(255) = '''',
	@dato2 varchar(255) = '''',
	@dato3 varchar(255) = '''',
	@dato4 varchar(255) = '''',
	@dato5 varchar(255) = '''',
	@TelReprograma smallint = -1,
	@user_id int=0,
	@isAuto bit=0
	AS
	set nocount on
	declare @TelOriginal as varchar(15)
	declare @FechaOriginal as datetime

	if len(@cal_telefono)<=3
		return(0)

	if isnull(@cal_key,'''') = ''''
	 begin
		  -- Generamos cal_key aleatorio para casos de reprogramacion inbound --
		  Genera_cal_key:
		  select @cal_key = right(newID(), 10)
		  if exists (select cal_key from ccoCallsOutSource where cal_key=@cal_key)
				goto Genera_cal_key
	 end

	declare @bIsDaylight as bit
	declare @idioma as int
	declare @country_id as varchar(3)

	select @country_id = valor from ccsettings where setting_id = 104

	select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

	declare @difference as int
	declare @Fecha smalldatetime, @callout_id int, @iZonaHoraria int,@iZonaHoraria_verano int, @cal_statusTemp tinyint
	declare @iZonaHoraria2 int,@iZonaHoraria_verano2 int
	declare @iZonaHoraria3 int,@iZonaHoraria_verano3 int
	declare @iZonaHoraria4 int,@iZonaHoraria_verano4 int
	declare @iZonaHoraria5 int,@iZonaHoraria_verano5 int
	if @isAuto=0
		select @difference = isNull(dbo.fnGetTimeDifference(dbo.fnGetTimeZone(@cal_telefono,@bIsDaylight)),0)
	else
		set @difference = 0
	select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))

	if exists(select cal_Key, cam_id from ccoCallsOutSource where cal_Key = @cal_key and cam_id =@cam_id)
	 begin
		select @callout_id=callout_id,@cal_statusTemp =cal_status,
		@iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end,@iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end, 
		@iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end,@iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end, 
		@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end,@iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end, 
		@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end,@iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end, 
		@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end,@iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end, 
		@TelOriginal = cal_telefono, @FechaOriginal = cal_fechadial from ccoCallsOutSource 
		where cal_Key = @cal_key and cam_id = @cam_id

		update ccoCallsOutSource set cal_status = ''2'',cal_telefono=@cal_telefono where cal_key = @cal_key and cam_id = @cam_id

		if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
			UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
		else
			INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw
			,iZonaHoraria,iZonaHoraria_verano
			,iZonaHoraria2,iZonaHoraria_verano2
			,iZonaHoraria3,iZonaHoraria_verano3
			,iZonaHoraria4,iZonaHoraria_verano4
			,iZonaHoraria5,iZonaHoraria_verano5)
			select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key
			,@iZonaHoraria,@iZonaHoraria_verano
			,@iZonaHoraria2,@iZonaHoraria_verano2
			,@iZonaHoraria3,@iZonaHoraria_verano3
			,@iZonaHoraria4,@iZonaHoraria_verano4
			,@iZonaHoraria5,@iZonaHoraria_verano5

			if not exists (select callout_id from ccoCallBacks with(nolock) where callout_id = @callout_id)
				begin
					insert into ccoCallBacks (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus)
					values (@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
				end
			else
				begin
					update ccoCallBacks
					set user_id = @user_id, cam_id = @cam_id, cal_key = @cal_key, cal_telefono = @TelOriginal, cal_telCB = @cal_telefono, cal_fecha = @FechaOriginal, cal_fusercallback = @Fecha, cal_fcallback = NULL, status = 0, schedulerStatus = 1
					where callout_id = @callout_id
				end
	  end

	else
	 begin
		select @FechaOriginal = getdate()

		insert into ccoCallsOutSource (cal_key,cam_id,cal_telefono,cal_fechadial,Dato1,Dato2,Dato3,Dato4,Dato5,cal_status)
		values (@cal_key,@cam_id,@cal_telefono,@FechaOriginal,@dato1,@dato2,@dato3,@dato4,@dato5,''2'')

		select @TelOriginal = @cal_telefono

		select @callout_id = scope_identity()
		select @iZonaHoraria=iZonaHoraria,@iZonaHoraria_verano=iZonaHoraria_verano from ccocallsoutsource where callout_id=@callout_id

		select @callout_id=callout_id,
		@iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end,@iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end, 
		@iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end,@iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end, 
		@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end,@iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end, 
		@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end,@iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end, 
		@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end,@iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end
		from ccoCallsOutSource 
		where callout_id=@callout_id


		 if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
			UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
		 else
			INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw
			,iZonaHoraria,iZonaHoraria_verano
			,iZonaHoraria2,iZonaHoraria_verano2
			,iZonaHoraria3,iZonaHoraria_verano3
			,iZonaHoraria4,iZonaHoraria_verano4
			,iZonaHoraria5,iZonaHoraria_verano5)
			select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key
			,@iZonaHoraria,@iZonaHoraria_verano
			,@iZonaHoraria2,@iZonaHoraria_verano2
			,@iZonaHoraria3,@iZonaHoraria_verano3
			,@iZonaHoraria4,@iZonaHoraria_verano4
			,@iZonaHoraria5,@iZonaHoraria_verano5

			if not exists (select callout_id from ccoCallBacks with(nolock) where callout_id = @callout_id)
				begin
					insert into ccoCallBacks (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus)
					values (@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
				end
			else
				begin
					update ccoCallBacks
					set user_id = @user_id, cam_id = @cam_id, cal_key = @cal_key, cal_telefono = @TelOriginal, cal_telCB = @cal_telefono, cal_fecha = @FechaOriginal, cal_fusercallback = @Fecha, cal_fcallback = NULL, status = 0, schedulerStatus = 1
					where callout_id = @callout_id
				end
	end

	if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id)
		update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id
	else
		insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@cam_id

	return(@callout_id)
	set nocount off
	
	'

	EXEC(@sql);

		--------------------------------- END JUAN MEDINA ------------------------------------------------

	--------------------------------- BEGIN MACL ------------------------------------------------
	
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
				SELECT tc.calif_id AS [Id], tc.[Description] AS [Description], tc.CanReprogram as Callback
				FROM ccCalifCamp cc INNER JOIN ccTipoCalif tc
				ON cc.calif_id = tc.calif_id
				WHERE cc.tipo = 0
				AND cc.cam_id = @CampId
			END
			IF @CampType = @Outbound
			BEGIN
				SELECT tc.calif_id AS [Id], tc.[Description] AS [Description], tc.CanReprogram as Callback
				FROM ccCalifCamp cc INNER JOIN ccTipoCalifOut tc
				ON cc.calif_id = tc.calif_id
				WHERE cc.tipo = 1
				AND cc.cam_id = @CampId
			END
		END
	END'
	EXEC(@sql)

	SET @process = 'K070320 - Se ajusta para poder asociar campañas de devolicion a campañas de ia de entrada [ccsp_GalateaAdminInbound]'
	SET @sql = '    ALTER PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT, 
                                            @InboundId AS SMALLINT = 0,
											@User_id AS SMALLINT = 0,
											@OutboundID AS SMALLINT = 0,
											@multi_cam as varchar(max) = null,
											@Module AS SMALLINT = 13,
											@Type AS SMALLINT = 0,
											@HistoryAction AS SMALLINT = 1,
											@AreaId AS SMALLINT = 0,
											@NonComprehensionId AS SMALLINT = -1,
											@SuccessfulTransactionCampaignId AS SMALLINT = -1,
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

			if(@Option = 1) -- Por campaña 
			begin
			    select 
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
			    where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) and a.inbound_id = @InboundId

			end

			if(@Option = 2) -- Todas las campañas 
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

			if(@Option = 3) -- Obtiene los datos de las llamadas de todos los ACD, datos que se muestran en el tablero de información del administrador 
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
					--assignedAndNotAnswered = ISNULL(COUNT (CASE WHEN statusCall_id =15 THEN 1 ELSE NULL END), 0), -- asignada y no contestada
					--assignedAndTookLine = ISNULL(COUNT (CASE WHEN statusCall_id =16 THEN 1 ELSE NULL END), 0), -- asignada y toma linea
					callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0)
					--onQueue = ISNULL(COUNT(CASE WHEN statusCall_id = 5 THEN 1 ELSE NULL END), 0)
					--initCalls = CAST(ISNULL(COUNT(CASE WHEN statusCall_id = 1 THEN 1 ELSE NULL END), 0) AS varchar(7))+''|''+
					--			ISNULL((SELECT STUFF((SELECT ''|'' + cast(ci.cal_id AS varchar(7))
					--			FROM ccCallsin ci (nolock) WHERE cal_inicio > dateadd(mi,-5,getdate()) AND ci.inbound_id=a.inbound_id
					--			FOR XML PATH('''')) ,1,1,'''')),''0'')
				FROM ccCallsIn a (nolock)
				WHERE cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))
						--and a.inbound_id in (select cam_id from ccSupervisorCam where user_id = @User_id and tipo = 0)
				GROUP BY a.inbound_id
			--	SET nocount off
			--	return(0)
			end

			if(@Option = 4) -- Carga los ACD del administrador mandado
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

				DECLARE @CurrentNonComprehensionId SMALLINT, 
						@CurrentCallbackId SMALLINT, 
						@CurrentSuccessfullTransactionId SMALLINT,
						@UserName VARCHAR(40),
						@AreaName VARCHAR(50),
						@CampaignName VARCHAR(40)

				SELECT @AreaName = AreaName  FROM ccRIACat_Areas WHERE IDArea = @AreaId
				SELECT @UserName = Login FROM ccUsers WHERE User_id = @User_id

				SELECT 
					@CurrentNonComprehensionId = ISNULL( idForNonComprehension , -1 ),
					@CurrentCallbackId = ISNULL( cam_id, -1 ),
					@CurrentSuccessfullTransactionId = ISNULL( idForSuccessfulTransaction, -1),
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

				IF @CurrentNonComprehensionId <> @NonComprehensionId AND @NonComprehensionId <> -1
				BEGIN
					UPDATE ccInbound
					SET idForNonComprehension = @NonComprehensionId
					WHERE Inbound_id = @InboundId

					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@AreaName, 
							GETDATE(), 
							@UserName, 
							@operation, 
							@Module, 
							''ASSOCIATED_CAMP_XFER_IA'', 
							CASE @NonComprehensionId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT descripcion FROM ccInbound WHERE Inbound_id = @NonComprehensionId) END,
							@CampaignName)
				END

				IF @CurrentSuccessfullTransactionId <> @SuccessfulTransactionCampaignId AND @SuccessfulTransactionCampaignId <> -1
				BEGIN
					UPDATE ccInbound
					SET idForSuccessfulTransaction = @SuccessfulTransactionCampaignId
					WHERE Inbound_id = @InboundId

					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@AreaName, 
							GETDATE(), 
							@UserName, 
							@operation, 
							@Module, 
							''ASSOCIATED_CAMP_SUCCESSFUL_TRANSACTION'', 
							CASE @SuccessfulTransactionCampaignId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT descripcion FROM ccInbound WHERE Inbound_id = @SuccessfulTransactionCampaignId) END,
							@CampaignName)
				END

				SELECT 1
			END
		END
    '
	EXEC(@sql)

	SET @process = 'CW-10097 - se modifica [ccsp_RIADNCList] para que solo inserte en historial cuando se elimina un telefono'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIADNCList] 
	@phoneNumber AS NVARCHAR(30) = NULL, 
	@idDNCList AS INTEGER, 
	@tipoMov AS TINYINT, 
	@calKey AS VARCHAR(40) = NULL,
	@cleanType int=0 --0 limpia,2 verifica
	AS
	DECLARE @hashCalKey bigint, @hashPhone BIGINT

	IF @calKey IS NOT NULL
	BEGIN
		SELECT @hashCalKey = dbo.hashList(@calKey)
	END

	IF @tipoMov = 1
	BEGIN -- Inserta Lista Negra    
		EXEC ccsp_InsertDNCList @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null,@cleanType=@cleanType
		EXEC ccsp_InsertDNCListSms @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null
		EXEC [ccsp_InsertDNCListWhatsApp] @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null
	END

	IF @tipoMov = 2
	BEGIN -- Borra Lista Negra  
		SELECT @hashPhone = dbo.hashPhone(@phoneNumber)
		DECLARE @deletedRows INT
		IF @hashCalKey IS NULL
		BEGIN
			DELETE
			FROM cclistanegra
			WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idDNCList
			SELECT @deletedRows = @@ROWCOUNT
		END
		ELSE
		BEGIN
			DELETE
			FROM cclistanegra
			WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idDNCList
			SELECT @deletedRows = @@ROWCOUNT
		END

		IF(@deletedRows > 0)
		BEGIN
			INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
			VALUES (@phoneNumber, 5, @idDNCList)
		END
	END

	IF @tipoMov = 3
	BEGIN -- Reemplaza Lista Negra
		INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
		SELECT telefono, ''4'', @idDNCList
		FROM cclistanegra
		WHERE idtipolista = @idDNCList

		DELETE
		FROM cclistanegra
		WHERE idtipolista = @idDNCList
	END '
	EXEC(@sql)


	SET @process = 'Internal - se modifica [ccsp_InsertDNCList] para que valide correctamente por id de lista al eliminar de la temporal'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as nvarchar(30)=null,
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL,
@cleanType int=0 --0 limpia,2 verifica
AS

Set nocount on

declare @sqlcmd nvarchar(max), @tmpTableName varchar(40), @sqlcmd_replace nvarchar(max),
@dropTmpPhone nvarchar(max) = null
,@fnPhone nvarchar(100) =null
,@motivo nvarchar(100)
,@keyTranslate nvarchar(100)
,@params nvarchar(max)  

declare @phoneEmpty nvarchar(1)
set @phoneEmpty =''''


set @fnPhone=case when @cleanType=0 then ''[dbo].[Limpia](@telephone)'' else  ''[dbo].[Verifica](@telephone)'' end

set @motivo=case when @cleanType=0 then ''Length exceeded'' else  ''Error en COFETEL'' end
set @keyTranslate=case when @cleanType=0 then ''description-length'' else  ''description-cofetel'' end


SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));

if (@telephone is not null) -- Para insertar un solo numero cuando se manda a BL por calificación
BEGIN
    IF EXISTS (SELECT * from ccListaNegra where idtipolista = @ln_id and telefono = @telephone and HashKey = dbo.hashList(@calKey)) begin
        RETURN 0;
    end

    set @tmpTableName = ''TMP_BLACKLIST_'' + @telephone;
    SET @dropTmpPhone = ''if exists (select * from sys.tables where name = N'''''' + @tmpTableName + '''''') drop table '' + @tmpTableName;

    SET @sqlcmd = ''CREATE TABLE '' + @tmpTableName + ''(
    [phoneNumber] VARCHAR(30),
    [calKey] VARCHAR(40)); 

    INSERT INTO '' + @tmpTableName + ''(phoneNumber, calKey) values(''+@fnPhone+'',@calKey );
    '';
    EXEC (@dropTmpPhone);   
    
    EXEC sp_executesql @sqlcmd, N''@telephone nvarchar(40), @calKey VARCHAR(40)'', @telephone,@calKey;
    
END
else if @cleanType<>0 begin
    set @fnPhone=case when @cleanType=0 then ''[dbo].[Limpia](phoneNumber)'' else  ''[dbo].[Verifica](phoneNumber)'' end
    
    set @sqlcmd=''update '' + @tmpTableName + '' set phoneNumber=''+@fnPhone
    
    EXEC (@sqlcmd);

    set @sqlcmd=''
    Insert into ccRIALogPhones 
select @ln_id,@phoneEmpty,phoneNumber,0,@motivo,@keyTranslate 
from ''+ @tmpTableName+''
where left(phoneNumber,1)= ''''E''''
delete from ''+ @tmpTableName+'' where left(phoneNumber,1)= ''''E''''
''
    
    set @params=''@ln_id int, @phoneEmpty nvarchar(1),@motivo nvarchar(100),@keyTranslate nvarchar(100)''
    EXEC sp_executesql @sqlcmd,@params,
    @ln_id=@ln_id
    ,@phoneEmpty=@phoneEmpty,@motivo =@motivo ,@keyTranslate =@keyTranslate 

end

set @sqlcmd=''delete A
FROM '' + @tmpTableName + '' A
left join cclistanegra B with(nolock,index(IX_ccListaNegra_1)) on A.phoneNumber=B.telefono AND (A.calKey = B.calKey OR (A.calKey IS NULL and B.calKey IS NULL ))
where B.idtipolista = '' + CAST(@ln_id as varchar(10)) + '' AND B.telefono is not null''

EXEC (@sqlcmd);   

SET @sqlcmd = ''INSERT INTO cclistanegra(telefono,idtipolista,HashKey, calKey)
SELECT phoneNumber, @ln_id as idtipolista, dbo.hashList(calKey) as HashKey, calkey 
FROM '' + @tmpTableName + '' A 

INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
SELECT phoneNumber as telefono, 7 as idtipomov, @ln_id as idtipolista 
FROM '' + @tmpTableName + '' A '';


EXEC sp_executesql @sqlcmd, N''@ln_id int'', @ln_id;

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall


CREATE TABLE [dbo].[#mycamps] ( [campsid] [int] NULL)

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id and B.CampType not in(7,5)


CREATE TABLE [dbo].[#myprincipaltempCall](
    [callout_id] [bigint] NULL, 
    [cam_id] [int] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL,
    [cal_telefono] [varchar] (30) NULL ,
    [cal_telefono2] [varchar] (30) NULL ,
    [cal_telefono3] [varchar] (30) NULL ,
    [cal_telefono4] [varchar] (30) NULL ,
    [cal_telefono5] [varchar] (30) NULL
    )

CREATE CLUSTERED INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltempCall]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltempCall]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltempCall]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltempCall]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltempCall]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltempCall]([cal_telefono5]) 

CREATE TABLE [dbo].[#helpTempCall](
    [callout_id] [bigint] NULL, 
    [cam_id] [int] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL,
    [cal_telefono] [varchar] (30) NULL ,
    [cal_telefono2] [varchar] (30) NULL ,
    [cal_telefono3] [varchar] (30) NULL ,
    [cal_telefono4] [varchar] (30) NULL ,
    [cal_telefono5] [varchar] (30) NULL
    )

CREATE TABLE [dbo].[#mytempCall](
    [callout_id] [bigint] NULL, 
    [telefono] [varchar] (30) NULL ,
    [cam_id] [smallint] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempCall]([callout_id]) 

declare @fech datetime = getdate()-30
    SET @sqlcmd = ''
    insert into [#helpTempCall]
    SELECT a.callout_id as callout_id, a.cam_id,3, @ln_id as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
    FROM [ccoCallsOutSource] as a with(nolock)
    inner join #mycamps as b  on a.cam_id = b.campsid
    inner join '' + @tmpTableName +'' t on 
    t.phoneNumber IN ([SPACE_TEL])  AND t.calKey IS NULL
    where  cal_fechadial > getdate()-30
    ''

SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono'')   
EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

DECLARE @columnIndex INT = 2;
WHILE @columnIndex <= 5
BEGIN
    SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono''+CONVERT(varchar(10),@columnIndex))
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;
    set @columnIndex=@columnIndex+1;
END

    SET @sqlcmd = ''insert into [#helpTempCall]
    SELECT a.callout_id as callout_id, a.cam_id,3, @ln_id as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
    FROM [ccoCallsOutSource] as a with(nolock)
    inner join #mycamps as b  on a.cam_id = b.campsid
    inner join '' + @tmpTableName +'' t on a.cal_Key=t.calKey
    where cal_fechadial > getdate()-30;
    '';
    
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

    INSERT INTO #myprincipaltempCall
    SELECT * FROM #helpTempCall
    GROUP BY callout_id, cam_id, tipomov, idtipolista, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5

if EXISTS (select * from #myprincipaltempCall)
begin
    declare @column nvarchar(max), @sql nvarchar(max)
    ,@sqlDeleteWorking nvarchar(max)
    ,@sqlUpdateWorking nvarchar(max)
    ,@sqlCaseWorking nvarchar(max)
      
    ,@sqlWithReplace nvarchar(max)
    
    set @column=''cal_telefono''
    set @params=''@phoneEmpty varchar(1),@fech datetime''
    set @sqlDeleteWorking=''and cs.cal_telefono2=@phoneEmpty
    and cs.cal_telefono3=@phoneEmpty
    and cs.cal_telefono4=@phoneEmpty
    and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono2<>@phoneEmpty then cs.cal_telefono2 
    when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
    when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
    when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
    else @phoneEmpty end ''

    set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
    update wt 
    set cal_telefono = CASE_UPDATE_WT
    from ccoCallsOutSource cs 
    inner join ccoWOrkingTable wt on cs.callout_id = wt.callout_id
    inner join #mytempCall t on cs.callout_id = t.callout_id
    where cs.cal_fechadial > @fech and cs.COLUMN_CHECK= wt.cal_telefono''

    set @sql=''
insert #mytempCall
select callout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempCall] as a with(nolock)
inner join '' + @tmpTableName + '' t on
t.phoneNumber = COLUMN_CHECK
where COLUMN_CHECK<>@phoneEmpty


if EXISTS (select * from #mytempCall)
begin       
    -- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
    delete wt with(rowlock)
    from ccoWOrkingTable wt 
    inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
    inner join #mytempCall t on wt.callout_id = t.callout_id
    where cs.cal_fechadial > @fech and
    cs.COLUMN_CHECK = wt.cal_telefono
    AND_DELETE_WT

    UPDATE_SMS_WT_QUERY

    --insertar el historial
    insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
    select * from #mytempCall where [telefono]<>@phoneEmpty

    -- Eliminamos el telefono1 de CS
    update ccoCallsOutSource 
    set COLUMN_CHECK = @phoneEmpty
    from ccoCallsOutSource cs 
    inner join #mytempCall t on cs.callout_id = t.callout_id
    where cs.cal_fechadial > @fech      

    truncate table #mytempCall
end''

    
    /******************/
    /*** Telefono 1 ***/
    /******************/
    
    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    print(@sqlWithReplace)  
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  

    /******************/
    /*** Telefono 2 ***/
    /******************/
    set @column=''cal_telefono2''
    
    set @sqlDeleteWorking='' and cs.cal_telefono3=@phoneEmpty
        and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
        when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  

    /******************/
    /*** Telefono 3 ***/
    /******************/
    set @column=''cal_telefono3''
    
    set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  
    
    /******************/
    /*** Telefono 4 ***/
    /******************/    
    
    set @column=''cal_telefono4''
    
    set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  
    
    /******************/
    /*** Telefono 5 ***/
    /******************/

    set @column=''cal_telefono5''   
    set @sqlDeleteWorking='' and cs.cal_telefono5=@phoneEmpty'' 
    set @sqlCaseWorking=''''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',''''),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  

end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall
IF @dropTmpPhone IS NOT NULL EXEC (@dropTmpPhone);'
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

-------------------- Begin Carlos Muñoz --------------------

	SET @process = 'K070251 Se agrega apartado para traer las transcripciones de los agentes virtuales'
	SET @sql = '
		ALTER PROCEDURE [dbo].[ccspGalatea_Finder] 
				@action INT, 
				@userId INT = 0, 
				@conversationId BIGINT = 0,
				@isSuperUser bit=0,
				@callId int = 0,
				@callType int = 0
				AS
				IF @action = 1
				    BEGIN--trae el nombre de la base de datos en BX
				    if @isSuperUser =0 begin

				            SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, c.cam_descripcion AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
				                INNER JOIN ccCamps c ON WGCam.IdCampEsp = c.cam_id
				                                        AND WGCam.Tipo = 1
				            WHERE Wguser.User_id = @userId
				            UNION
				            SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, inb.descripcion AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
				                INNER JOIN ccInbound inb ON WGCam.IdCampEsp = inb.Inbound_id
				                                            AND WGCam.Tipo = 0
				            WHERE Wguser.User_id = @userId;
				        end
				        else begin
				        SELECT CAST(c.cam_id AS INT) AS [Value], CAST(2 AS INT) AS callType, c.cam_descripcion AS label FROM ccCamps c
				        UNION
				        SELECT CAST(inb.Inbound_id AS INT) AS [Value], CAST(1 AS INT) AS callType, inb.descripcion AS label FROM ccInbound inb;
				        end
				        RETURN 0;
				END;
				IF @action = 2
				    BEGIN
				    if @isSuperUser =0 begin
				        WITH WgId
				            AS (SELECT IDWG
				                FROM ccRIAWorkGroupUsers Wguser
				                WHERE Wguser.User_id = @userId)
				            SELECT DISTINCT 
				                    CAST(Wguser.User_id AS INT) AS [Value], CONCAT(ccUsers.Nombres, '' '', ccUsers.ApellidoPaterno, '' '', ccUsers.ApellidoMaterno)  AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN WgId ON Wguser.IDWG = WgId.IDWG
				                INNER JOIN ccUsers ON ccUsers.User_id = Wguser.User_id
				                                        AND TipoUser_id = 1;
				end
				else begin
				        select CAST(ccUsers.User_id AS INT) AS [Value], CONCAT(ccUsers.Nombres, '' '', ccUsers.ApellidoPaterno, '' '', ccUsers.ApellidoMaterno)  AS label
				        from ccUsers where TipoUser_id = 1;
				end
				        RETURN 0;
				END;
				IF @action = 3
				         BEGIN--Informacion de la conversacion de whatsApp
				               SELECT A.ConversationID, A.inboundId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneACD AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID, C.Login AS UserName
				                        ,(cast(sum(A.tConversation) / 3600 as varchar(10)) + '':'' + 
				                        right(''0'' + cast((sum(A.tConversation) % 3600) / 60 as varchar(10)), 2) + '':'' + 
				                        right(''0'' + cast(sum(A.tConversation) % 60 as varchar(10)), 2)) as Duration
				             FROM ccWhatsAppConversations A
				                  LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
				                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
				                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
				                  LEFT JOIN ccRIAInboundGraph graph ON graph.Inbound_id = A.inboundId
				                  LEFT JOIN ccUsers C ON A.agentId = C.User_id
				             WHERE A.conversationId = @conversationId
				             group by A.conversationId, A.inboundId, graph.graphic_id, A.phoneACD, A.clientId, B.descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc, conversationDate, requestDate, A.agentId, C.Login;

				             RETURN 0;
				     END;
				IF @action = 4
				         BEGIN--Informacion de la conversacion de whatsApp out
				               SELECT A.ConversationID, A.camId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneCamp AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.cam_descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID, C.Login AS UserName
				                        ,(cast(sum(A.tConversation) / 3600 as varchar(10)) + '':'' + 
				                        right(''0'' + cast((sum(A.tConversation) % 3600) / 60 as varchar(10)), 2) + '':'' + 
				                        right(''0'' + cast(sum(A.tConversation) % 60 as varchar(10)), 2)) as Duration
				             FROM ccWhatsAppConversationsOut A
				                  LEFT JOIN ccCamps B ON A.camId = B.cam_id
				                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
				                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
				                  LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = A.camId
				                  LEFT JOIN ccUsers C ON A.agentId = C.User_id
				             WHERE A.conversationId = @conversationId
				             group by A.conversationId, A.camid, graph.graphic_id, A.phoneCamp, A.clientId, B.cam_descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc, conversationDate, requestDate, A.agentId, C.Login;

				             RETURN 0;
				     END;
				IF @action = 5
				         BEGIN--Informacion de la conversacion de Chat
				                SELECT A.ChatId AS ConversationID, A.inboundId AS CampaignId, A.userId AS AgentID, ISNULL(B.descripcion, ''N/A'') AS CampaignName,
							   ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, 
							   C.Login AS UserName, A.clientName as Client, ISNULL(A.chatDate, A.requestDate) as DateStart,
							   (cast(sum(A.tChatting) / 3600 as varchar(10)) + '':'' + 
				                right(''0'' + cast((sum(A.tChatting) % 3600) / 60 as varchar(10)), 2) + '':'' + 
				                right(''0'' + cast(sum(A.tChatting) % 60 as varchar(10)), 2)) as Duration
				             FROM ccRIAChats A
				                  LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
				                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
				                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
				                  LEFT JOIN ccUsers C ON A.userId = C.User_id
				             WHERE A.chatId = @conversationId
				             group by A.chatId, A.inboundId, A.userId, A.userId, B.descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc,
							 chatDate, requestDate, A.userId, C.Login, tChatting, clientName;

				             RETURN 0;
				     END;
				IF @action = 6
				BEGIN
					SELECT cfwadm.FinderWhatsAppMessageId,
                           cfwadm.Description,
                           cfwadm.OpTagEs,
                           cfwadm.OpTagEn,
                           cfwadm.OpTagPt FROM dbo.ccFinderWhatsAppDownloadedMessage AS cfwadm
					RETURN 0
				END
				IF @action = 7
				BEGIN
					SELECT [Description] AS [Label],  CAST(calif_id as VARCHAR) + ''|2'' AS [Value] FROM cctipocalifout
					UNION
					SELECT [Description] AS [Label],  CAST(calif_id as VARCHAR) + ''|1'' AS [Value] FROM cctipocalif
					RETURN 0
				END
				IF @action = 8
				BEGIN
					IF @callType = 11
					BEGIN
						SELECT Transcription FROM ccCallsInTranscriptionIA where call_id = @callId
					END
					ELSE IF @callType = 12
					BEGIN 
						SELECT Transcription FROM ccoCallsOutTranscriptionIA where call_id = @callId
					END
				END
				
				'
	EXEC(@sql)

	SET @process = 'K070105 Se evita conflictos con variables cargadas en campaña de entrada y salida con el mismo ID'
	SET @sql = '
		ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]
    @adminID INT
    ,@campID INT
    AS
    BEGIN

        DECLARE @AllCampaigns TABLE (
        cam_id SMALLINT
        ,cam_Descripcion VARCHAR(60)
        ,cam_tNotas SMALLINT
        ,cam_ocupado SMALLINT
        ,cam_noInt_ocupado SMALLINT
        ,cam_inter_ocupado SMALLINT
        ,cam_nocontesto SMALLINT
        ,cam_noInt_nocontesto SMALLINT
        ,cam_inter_nocontesto SMALLINT
        ,cam_fax SMALLINT
        ,cam_noInt_fax SMALLINT
        ,cam_inter_fax SMALLINT
        ,cam_modomanual SMALLINT
        ,ANI VARCHAR(15)
        ,cam_ShowCalifWnd BIT
        ,cam_StartTimerOnHangUp BIT
        ,editableCallKey BIT
        ,cam_tNoContesta SMALLINT
        ,iTipoDial SMALLINT
        ,detectAnswerMachine SMALLINT
        ,detectVoiceMail SMALLINT
        ,compliance SMALLINT
        ,cam_inter_graba SMALLINT
        ,cam_noint_graba SMALLINT
        ,progDial SMALLINT
        ,excCallBack SMALLINT
        ,dialOrder SMALLINT
        ,dialPrefix VARCHAR(10)
        ,dialPrefixMan VARCHAR(10)
        ,dialPrefixXfe VARCHAR(10)
        ,listenManualCall BIT
        ,stopRecording BIT
        ,abandonCallback BIT
        ,frame SMALLINT
        ,t_autoCB SMALLINT
        ,id_anilist INT
        ,tDialonWrapUp SMALLINT
        ,viewMode TINYINT
        ,queSize SMALLINT
        ,DNCScrub INT
        ,callerIdDesc VARCHAR(15)
        ,timeZoneRule INT
        ,callsBySurvey INT
        ,ivrScript INT
        ,surveyPctg INT
        ,call_record SMALLINT
        ,startStopRecording BIT
        ,leaveRecMessage BIT
        ,manualCallOnChat BIT
        ,callBackSurveyAgent BIT
        ,callBackSurveyClient BIT
        ,isRelationSurvey BIT
        ,funcEspDtmf INT
        ,sipHdrFormat VARCHAR(255)
        ,cam_inter_cancelled SMALLINT
        ,prefijo VARCHAR(40)
        ,enbleprefix BIT
        ,exitAssisted BIT
        ,previewDiscard BIT
        ,CampType INT
        ,conexionInfo VARCHAR(50)
        ,connUser VARCHAR(15)
        ,closeConversationTime INT
        ,answerTimeoutClient INT
        ,allowFileAttachments BIT
        ,selectRotativeANI INT
        ,rotativeAlgo TINYINT
        ,autoStart BIT
        ,messagingOrder BIT
        ,CamTPreview SMALLINT
        ,TimesPreview TINYINT
        ,timesDiscard TINYINT
        ,recordHold BIT
        ,zipCodeSchedule BIT
        ,RecordCalls tinyint
        ,simultaneousRecs smallint
        ,EditableContactData bit
        ,internationalDialingPortsAssigned bit
        ,AssignConversationSameAgent bit
        ,maxLimitQueueConversations SMALLINT
        ,MaxDaysPerWAConvo SMALLINT
        ,RecordIvr BIT
        ,CamCanceled INT
        ,surveyCamId int
        -- Outbound AI Campaign Special Settings
        ,RescheduledSurveyAI BIT
        ,ImmediateSurveyAI BIT
        ,ApplyRescheduledSurveyForCompletedCallsAI BIT
        ,EnableCallRecordingAI BIT
        )
        DECLARE @numbers VARCHAR(max)

        SELECT @numbers = COALESCE(@numbers + '','', '''')+ number
        FROM ccWhatsAppNumbers
        WHERE camp_id = 0
        AND STATUS = 1
            
        SELECT @numbers = COALESCE(@numbers + '','', '''')+ number
        FROM ccMetaWhatsAppNumbers
        WHERE Cam_Id = 0 or Cam_Id is null
        AND STATUS = 1

        INSERT INTO @AllCampaigns
        EXEC ccsp_RIAConfCamp @adminID
        ,@campID

        -- consulta para extraer las variables del script
        DECLARE @ScriptVariables NVARCHAR(MAX);
        WITH RecursiveExtraction AS (
            SELECT
                CAST(SUBSTRING(scriptAgent, CHARINDEX(''{{'', scriptAgent) + 2,
                CHARINDEX(''}}'', scriptAgent) - CHARINDEX(''{{'', scriptAgent) - 2) AS VARCHAR(MAX)) AS Variable,
                CAST(STUFF(scriptAgent, CHARINDEX(''{{'', scriptAgent),
                CHARINDEX(''}}'', scriptAgent) - CHARINDEX(''{{'', scriptAgent) + 2, '''') AS VARCHAR(MAX)) AS RemainingText
            FROM dbo.ccVirtualAgent
            WHERE CHARINDEX(''{{'', scriptAgent) > 0
            AND idCampaign = @campID AND campType = 1

            UNION ALL

            SELECT
                CAST(SUBSTRING(RemainingText, CHARINDEX(''{{'', RemainingText) + 2,
                CHARINDEX(''}}'', RemainingText) - CHARINDEX(''{{'', RemainingText) - 2) AS VARCHAR(MAX)) AS Variable,
                CAST(STUFF(RemainingText, CHARINDEX(''{{'', RemainingText),
                CHARINDEX(''}}'', RemainingText) - CHARINDEX(''{{'', RemainingText) + 2, '''') AS VARCHAR(MAX)) AS RemainingText
            FROM RecursiveExtraction
            WHERE CHARINDEX(''{{'', RemainingText) > 0
        )
        SELECT @ScriptVariables = STUFF((
            SELECT '', '' + Variable
            FROM RecursiveExtraction
            FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''');

        SELECT 
        dialPrefixMan DialPrefixMan
        ,dialPrefixXfe DialPrefixXfe
        ,listenManualCall ListenManualCall
        ,stopRecording StopRecording
        ,abandonCallback AbandonCallBack
        ,t_autoCB AutoCB
        ,id_anilist IdIstANI
        ,tDialonWrapUp TDialOnWrapup
        ,queSize Quesize
        ,DNCScrub
        ,callerIdDesc CallerIdDesc
        ,timeZoneRule TimeZoneRule
        ,callsBySurvey CallsBySurvey
        ,ivrScript IvrScript
        ,surveyPctg SurveyPctg
        ,call_record CallRecord
        ,startStopRecording StartStopRecording
        ,leaveRecMessage LeaveRecMessage
        ,manualCallOnChat ManualCallOnChat
        ,callBackSurveyClient CallBackSurveyClient
        ,callBackSurveyAgent CallBackSurveyAgent
        ,funcEspDtmf FuncEspDtmf
        ,sipHdrFormat SipHdrsCfg
        ,dialPrefix DialPrefix
        ,prefijo Prefix
        ,dialOrder DialOrder
        ,progDial ProgDial
        ,cam_Descripcion CamDescription
        ,cam_tNotas CamTnotas
        ,cam_ocupado CamBusy
        ,cam_noInt_ocupado CamNoIntBusy
        ,cam_inter_ocupado CamInterBusy
        ,cam_nocontesto CamNoAnswer
        ,cam_noInt_nocontesto CamNoIntNoAnswer
        ,cam_inter_nocontesto CamInterNoAnswer
        ,(cam_inter_cancelled / 60) CamInterCancelled
        ,cam_fax CamFax
        ,cam_noInt_fax CamNoIntFax
        ,cam_inter_fax CamInterFax
        ,cam_modomanual CamModoManual
        ,ANI
        ,cam_StartTimerOnHangUp CamStartTimerOnHangUp
        ,editableCallKey EditableCallKey
        ,cam_tNoContesta CamTNoAnswer
        ,iTipoDial CamIntensiveDialing
        ,detectAnswerMachine DetectAnswerMachine
        ,detectVoiceMail DetectVoiceMail
        ,compliance Compliance
        ,cam_inter_graba CamInterRecord
        ,cam_noint_graba CamNoIntRecord
        ,excCallBack ExcCallBack
        ,cam_ShowCalifWnd CamShowCalifWnd
        ,frame Frame
        ,exitAssisted ExitAssistedDialMode
        ,previewDiscard PreviewDiscard
        ,CampType
        ,conexionInfo ConexionInfo
        ,connUser ConnUser
        ,closeConversationTime CloseConversationTime
        ,answerTimeoutClient MUTimeOutClient
        ,allowFileAttachments AllowFileAttachments
        ,CamTPreview
        ,CAST(TimesPreview AS SMALLINT) TimesPreview
        ,@numbers AS FreeNumbers
        ,selectRotativeANI SelectRotativeANIManualCall
        ,rotativeAlgo RotativeAlgo
        ,autoStart AutoStart
        ,messagingOrder MessagingOrder
        ,timesDiscard TimesDiscard
        ,recordHold RecordHold
        ,zipCodeSchedule ZipCodeSchedule
        ,RecordCalls RecordCalls
        ,simultaneousRecs SimultaneousRecs
        ,EditableContactData EditableContactData
        ,internationalDialingPortsAssigned internationalDialingPortsAssigned
        ,AssignConversationSameAgent AssignConversationSameAgent
        ,maxLimitQueueConversations MaxLimitQueueConversations
        ,MaxDaysPerWAConvo DaysVisualConversationWhatsApp
        ,RecordIvr
        ,ISNULL(CamCanceled, 0) CamCanceled
        ,surveyCamId SurveyCamId
        -- Outbound AI Campaign Special Settings
        ,RescheduledSurveyAI
        ,ImmediateSurveyAI
        ,ApplyRescheduledSurveyForCompletedCallsAI
        ,EnableCallRecordingAI
        ,@ScriptVariables AS ScriptVariables
        FROM @AllCampaigns
        WHERE cam_id = @campID
    END
	
	'
	EXEC(@sql)

--------------------- End Carlos Muñoz ---------------------

--------------------- Begin Rod Salazar ---------------------
SET @process = 'LRSV ccsp_GalateaAdminCampaign cambio para pavel'
	SET @sql = '
	
    ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns]
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
								SELECT DISTINCT 
								CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
								isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
								camps.cam_procesando IsStarted, 
								ISNULL(a.AreaName, '''') AS Area, 
								CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
								CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
								CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10  ELSE isnull(camps.CampType,0) END as OutboundType,
								ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
								a.ToolsTransfer         
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
							--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
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

					ELSE IF @option = 10 BEGIN -- Get Agents States with totals per campaign by admin id and campaign type **********************
						DECLARE @date DATETIME = CONVERT(DATE, DATEADD(hh, - 3, GETDATE()));
						DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY (id));
						DECLARE @AgentsList TABLE (id INT, PRIMARY KEY (id));
						DECLARE @tmpCamAgent TABLE (
							camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY (camId, userId
								)  
							);
						DECLARE @AgentStatus TABLE (CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT
							);
						DECLARE @CurrentStatus TABLE (userId INT, CurrentState INT, IdCampEsp INT, camType INT
							);
						DECLARE @campDataTotal TABLE (
							camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), NumberOfVirtualAgents INT, PRIMARY KEY (camId
								)
							);

						INSERT INTO @AdminWorkgroups
						SELECT DISTINCT IDWG
						FROM ccRIAWorkGroupUsers WG, ccUsers_Roles R
						WHERE WG.User_id = @AdminId 
							OR (
								R.User_id = @AdminId
								AND R.Rol_id = 7
								);

						INSERT INTO @AgentsList
						SELECT DISTINCT A.User_id
						FROM ccRIAWorkGroupUsers A
						INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
						INNER JOIN ccUsers C ON A.User_id = C.User_id
							AND C.TipoUser_id = 1
						ORDER BY A.User_id;

						IF @IsWhatsAppCampaign  = 1
						BEGIN
							INSERT INTO @tmpCamAgent --Obtiene las relaciones entre agentes y campañas
							SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, CASE WHEN @Id = 0
										AND @CampType = 0 THEN inbound.chat ELSE NULL END
							FROM ccRIACampEspWG campPerWg
							INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
							INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
							INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
							LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp
								AND @CampType = 0
							LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp
								AND @CampType = 1
							WHERE C.TipoUser_id = 1  
								AND (camps.CampType = 5 or inbound.chat = 5)
								AND campPerWg.Tipo = @CampType
								AND (
									@Id = 0
									OR campPerWg.IdCampEsp = @Id
									);
						END
						ELSE
						BEGIN
							INSERT INTO @tmpCamAgent
							SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, CASE WHEN @Id = 0
										AND @CampType = 0 THEN inbound.chat ELSE NULL END
							FROM ccRIACampEspWG campPerWg
							INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
							INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
							INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
							LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp
								AND @CampType = 0
							LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp
								AND @CampType = 1
							WHERE C.TipoUser_id = 1
								AND campPerWg.Tipo = @CampType
								AND (
									@Id = 0
									OR campPerWg.IdCampEsp = @Id
									);
						END;

						INSERT INTO @CurrentStatus
							SELECT A.user_id, CASE WHEN A.currentStatus <= 0 THEN 0 ELSE A.currentStatus END AS 
						        currentStatus,A.IdCampEsp, A.Tipo
						        FROM ccLogAgentesDiaViewLast A
						        INNER JOIN @AgentsList B ON A.User_id = B.id
						        WHERE fecha >= @date

						IF @Id = 0
							AND @CampType = 0
						BEGIN
							DELETE
							FROM @tmpCamAgent
							WHERE multimediaType = 0
						END

						DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;

						IF @CampType = 1
						BEGIN
							SELECT @MultimediaType = meanContactTypeId
							FROM contactMeanOut
							WHERE camp_id = @Id
						END
						ELSE
						BEGIN
							SELECT @chatType = ci.chat
							FROM dbo.ccInbound AS ci
							WHERE ci.Inbound_id = @Id;

							SELECT @MultimediaType = meanContactTypeId
							FROM contactMeanIn
							WHERE inboundId = @Id
						END

						IF (@chatType = 1)
						BEGIN
							SET @MultimediaType = 1
						END

						DECLARE @StateIds VARCHAR(100) = (
								SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN 
												''23'' ELSE ''4,5,6,9'' END
								) -- Add more for multimediaTypes

						;with stateDialog as(
						SELECT cast(value as int) as CurrentState FROM dbo.fn_RIASplitDelimited(@StateIds,'','')
					)
						INSERT INTO @AgentStatus
						SELECT A.camId, A.userId, B.CurrentState,
						(CASE
							WHEN @chatType = 1 THEN
								CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) THEN 1 ELSE 0 END
							ELSE
								CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN 1 ELSE 0
							END
						END) AS isCampDialog, B.camType

						FROM @tmpCamAgent A
						INNER JOIN @CurrentStatus B ON A.userId = B.userId
						WHERE (
								@Id = 0
								OR A.camId = @Id
								)

						IF @CampType = 1
						BEGIN
								;

							WITH campDataTotal
							AS (
								SELECT camId, count(*) total
								FROM @tmpCamAgent A
								GROUP BY camId
								)
							INSERT INTO @campDataTotal
							SELECT A.camId, B.cam_descripcion AS campName, A.Total, C.AreaName AS Area, ISNULL(va.concurrentSessionsLimit,0) as NumberOfVirtualAgents 
							FROM campDataTotal A
							INNER JOIN ccCamps B ON A.camId = B.cam_id
							INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                            LEFT JOIN ccVirtualAgent va ON B.cam_id = va.idCampaign AND va.campType = 1
						END
						ELSE
						BEGIN
								;

							WITH campDataTotal
							AS (
								SELECT camId, count(*) total
								FROM @tmpCamAgent A
								GROUP BY camId
								)
							INSERT INTO @campDataTotal
							SELECT A.camId, B.descripcion AS campName, A.Total, C.AreaName AS Area, 0 as NumberOfVirtualAgents 
							FROM campDataTotal A
							INNER JOIN ccInbound B ON A.camId = B.Inbound_id
							INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
						END;

						WITH stateCamp
						AS (
							SELECT A.CampId, count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready, 
								count(CASE WHEN A.CurrentState NOT IN (- 2, - 1, 0, 3, 4, 5, 6, 9, 30, 34, 37
												) THEN 1 WHEN A.CurrentState IN (6, 4
												)
											AND (
												A.CampId != C.IdCampEsp
												OR A.campType != @CampType
												) THEN 1 ELSE NULL END) AS notReady,
												COUNT(CASE WHEN A.isCampDialog = 1 OR A.CurrentState = 34 THEN 1 ELSE NULL END) AS dialog, 
												COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected,
						COUNT(CASE WHEN A.CurrentState = 37 THEN 1 ELSE NULL END) AS auxiliaryReady
							FROM @AgentStatus A
							INNER JOIN @CurrentStatus C ON A.userId = C.userId
							GROUP BY A.CampId
							)
						SELECT A.camId, A.campName, (A.Total + A.NumberOfVirtualAgents) AS Total, ISNULL(B.ready, 0) AS Ready, ISNULL(B.notReady, 
								0) AS NotReady, ISNULL(B.dialog, 0) AS Dialog, CASE WHEN B.disconnected IS NULL 
									THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady - B.auxiliaryReady END 
							Disconnected, ISNULL(B.auxiliaryReady, 0) AS AuxiliaryReady, A.NumberOfVirtualAgents ,A.Area
						FROM @campDataTotal A
						LEFT JOIN stateCamp B ON A.camId = B.CampId
						ORDER BY A.campName

						RETURN 0;
					END; -- *****************************************************************************************
					ELSE IF @Option = 11 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
						IF NOT EXISTS (
								SELECT *
								FROM ccUsers_Roles WITH (NOLOCK)
								WHERE User_id = @AdminId
									AND Rol_id = 7
								)
						BEGIN
							--print ''xxxx SIn Super''
								;

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
							--print ''xxxx Super''
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

					ELSE IF @Option = 12 BEGIN-- Get All Campaigns complete information per Campaign Type and Campaign Id
						IF @CampType = 1 -- Campaigns Out
						BEGIN
										SELECT DISTINCT 
										CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
										isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
										camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
										CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, 
										CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10 ELSE isnull(camps.CampType,0) END as OutboundType,
										ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
							FROM ccCamps camps(NOLOCK)
							INNER JOIN ccRIACampsGraph graph(NOLOCK) ON camps.cam_id = graph.cam_id
							INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = camps.IDArea
							LEFT JOIN ccCampsExtend extended(NOLOCK) ON camps.cam_id = extended.cam_id
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
														CAST(ISNULL(cci.Inbound_id, -1) AS INT) AS RelatedCampId,
														CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
														CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
														CAST(1 AS INT) As CampType
									FROM ccRIACampEspWG A
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
										AND A.Tipo = 1
														INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id
														LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
														LEFT JOIN ccInbound cci ON ccc.cam_id = cci.cam_id
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
													isnull(IDArea, -1) AS AreaID,
													CAST(-1 AS SMALLINT) AS CampaignType,
													-1 AS RelatedCampId,
													CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
													CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
													CAST(1 AS INT) As CampType
											FROM ccCamps AS ccc (NOLOCK) 
												LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
											where IDArea = @AreaId
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
								SELECT *
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
													CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
							FROM ccRIACampEspWG A(NOLOCK)
							INNER JOIN wgId ON wgId.IDWG = A.IDWG
								AND A.Tipo = 0
													INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND isnull(cci.cam_id,-1) = -1
													AND ((@multi_type is null AND cci.chat = @InboundType)
														OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

						END
						ELSE
						BEGIN
										SELECT DISTINCT 
										CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
										FROM ccInbound cci (NOLOCK) where IDArea = @AreaId AND isnull(cam_id,-1) = -1
										AND ((@multi_type is null AND cci.chat = @InboundType)
											OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

						END
					END

					ELSE IF @Option = 15
					BEGIN
								SELECT DISTINCT 
								CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
								FROM ccInbound NOLOCK where cam_id = @Id and chat IN (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))
					END
					ELSE IF  @Option=16
					begin
						DECLARE @from DATETIME = CAST(GETDATE() AS DATE);
						DECLARE @to DATETIME = DATEADD(MILLISECOND, -3, DATEADD(DAY, 1, @from));
						select @AreaId = IDArea from ccUsers where User_id = @Id
						declare @camps table (cam_id int)
						insert @camps	select cam_id  FROM  dbo.fGet_CampAcd_Area(@Id,5) group by cam_id
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
						END;

					ELSE IF @Option = 19
						BEGIN

							DECLARE @SuccessId INT, @NonComprehensionId INT;
							DECLARE @IsSuperUser BIT = 0;
							DECLARE @wgId TABLE (IDWG INT);

							IF EXISTS (SELECT * FROM ccUsers_Roles NOLOCK WHERE User_id = @AdminId AND Rol_id = 7)
							BEGIN
								SET @IsSuperUser = 1;
							END
							ELSE
							BEGIN
								INSERT INTO @wgId (IDWG)
								SELECT IDWG
								FROM ccRIAWorkGroupUsers WITH (NOLOCK)
								WHERE user_id = @AdminId;
							END

							SELECT 
								@SuccessId = ISNULL(idForSuccessfulTransaction, -1),
								@NonComprehensionId = ISNULL(idForNonComprehension, -1)
							FROM ccInbound WITH (NOLOCK)
							WHERE Inbound_id = @CampId;

							WITH MainCampaigns AS (
								SELECT 
									CAST(cci.Inbound_id AS INT) AS CampId,
									cci.descripcion AS Description,
									ISNULL(cci.IDArea, -1) AS AreaID,
									CAST(cci.chat AS SMALLINT) AS CampaignType,
									CAST(0 AS BIT) AS IsSuccessTransfer,
									CAST(0 AS BIT) AS IsNonComprehensionTransfer
								FROM ccInbound cci WITH (NOLOCK)
								WHERE 
								(
									-- Superusuario: por Área
									(@IsSuperUser = 1 AND cci.IDArea = @AreaId)
									OR
									-- Usuario normal: por Workgroup
									(@IsSuperUser = 0 AND EXISTS (
										SELECT 1 FROM ccRIACampEspWG A WITH (NOLOCK)
										INNER JOIN @wgId wg ON wg.IDWG = A.IDWG
										WHERE A.Tipo = 0 AND A.IdCampEsp = cci.Inbound_id
									))
								)
								AND cci.chat = 0
								AND cci.IDArea = @AreaId
							),
							ReferencedCampaigns AS (
								SELECT 
									CAST(cci.Inbound_id AS INT) AS CampId,
									cci.descripcion AS Description,
									ISNULL(cci.IDArea, -1) AS AreaID,
									CAST(cci.chat AS SMALLINT) AS CampaignType,
									CASE WHEN cci.Inbound_id = @SuccessId THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsSuccessTransfer,
									CASE WHEN cci.Inbound_id = @NonComprehensionId THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsNonComprehensionTransfer
								FROM ccInbound cci WITH (NOLOCK)
								WHERE cci.Inbound_id IN (@SuccessId, @NonComprehensionId)
							)

							SELECT * FROM ReferencedCampaigns
							UNION ALL
							SELECT m.*
							FROM MainCampaigns m
							LEFT JOIN ReferencedCampaigns r
							  ON m.CampId = r.CampId
							WHERE r.CampId IS NULL;
						END;
					END;
    
    
	'
	EXEC(@sql)
--------------------- End Rod Salazar ---------------------

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
