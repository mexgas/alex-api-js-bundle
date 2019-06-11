/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.35

Se agrega la tarea
cw-2915
cw-3001
CW-3201
CW-3032

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
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 37
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 36
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'cw-3201 drop function hashPhone'
		SET @Sql = 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''hashPhone'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
    begin
        Drop function hashPhone
    end'
		EXEC (@Sql)


		set @process = 'cw-2915 drop sp'
		set @sql = 'if exists (select * from sys.procedures where name = N''cc_DNCKillList'')
    begin
        DROP PROCEDURE cc_DNCKillList;
    end'

		exec (@sql)

		SET @process = 'cw-3201 CREATE FUNCTION hashPhone'
		SET @Sql = 'CREATE FUNCTION [dbo].[hashPhone] (@phoneNumber varchar(30)) 
RETURNS bigint AS
BEGIN
  return convert(bigint,@phoneNumber) % 127499997
END
'
		EXEC (@Sql)

		SET @process = 'Galatea Admin CW CW-2976 check exist ccspGalateaGetAgentCounters '
		SET @Sql = '   
			if exists (select * from sys.procedures where name = N''ccspGalateaGetAgentCounters'')
			begin
				drop procedure ccspGalateaGetAgentCounters
			end'
		EXEC (@Sql)


		SET @process = 'Galatea Admi CW-2976 add ccspGalateaGetAgentCounters '
		SET @Sql = '   
create procedure ccspGalateaGetAgentCounters
@type as int, @sup_id as int = 0 as
set nocount on
if @type = 1
    begin
        ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login 
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where 
        wgAdmin.User_id=@sup_id
    )


        select a.user_id, a.login as UserName, CONCAT(a.Nombres, '' '', a.ApellidoPaterno, '' '',a.ApellidoMaterno) as Name
        from ccusers a (nolock)--, ccGenViewRelsSupsAgent b
        inner join TableUserAgent b on a.User_id=b.userId       
    end

set nocount on
		 '

		EXEC (@Sql)

	
		SET @process = 'cw-2915 add kill list setting'
		SET @Sql = 'IF NOT EXISTS (
		SELECT setting_id
		FROM ccSettings
		WHERE setting_id = 215
		) 
BEGIN
	INSERT INTO ccSettings (
		setting_id
		,valor
		,descripcion
		,STATUS
		,Tipo
		,detalle
		,description
		,bLoadSettings
		,validate
		)
	VALUES (
		215
		,''48''
		,''Tiempo (horas) que un teléfono permanecerá en la lista negra predeterminada''
		,0
		,''ADM''
		,''Tiempo en horas que estara un numero en DNC default/KillList''
		,''Time (hours) that a phone number will remain in the default DNC/kill list''
		,0
		,''.*''
	)
END'
		EXEC (@Sql)

		set @process = 'cw-2915 create dnc kill list'
		set @sql = 'if not exists(select Tipolista from ccTiposListaNegra where Tipolista = ''default/KillList'') 
begin
	insert into ccTiposListaNegra (Tipolista, Status) values(''default/KillList'', 1)
end'
		exec (@sql)

		set @process = 'cw-2915 create table cc_killList table'
		set @sql = 'if not exists (select * from sys.tables where name = N''cc_KillList'')
    begin
       CREATE TABLE [dbo].[cc_KillList](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[hashTel] [int] NOT NULL,
	[hashkey] [int] NULL,
	[id_tipoLista] [int] NOT NULL,
	[date] [datetime] NOT NULL
) ON [PRIMARY]
    end'
		exec (@sql)
		

		set @process = 'cw-2915 create sp'
		set @sql = 'CREATE PROCEDURE [dbo].[cc_DNCKillList]
	
AS
BEGIN
	DECLARE @minTime AS INT 
	declare @killListID int = (SELECT idtipolista FROM ccTiposListaNegra WHERE Tipolista = ''default/KillList'')
	declare @killListSetting int = (select status from ccSettings where setting_id = 215)

	if(@killListSetting = 1)
	begin
		select @minTime = valor from ccSettings where setting_id = 215

	create table #temp(
		hashtel int not null
	)
	insert into #temp
	select a.hashtel from cc_killlist a inner join ccListaNegra b 
	on a.Hashtel = b.hashTel 
	WHERE datediff(HH, [date],getdate()) > @minTime

	delete from cc_KillList where hashTel in (select hashtel from #temp)
	delete from ccListaNegra where Hashtel in (select hashtel from #temp) and idtipolista = @killListID

	drop table #temp
	end
END'
		exec (@sql)

		set @process = 'cw-2915 y cw-3201 modify sp ccsp_AgentUpdateCallCALIF'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentUpdateCallCALIF] @IDCall INT, @calif_id SMALLINT, @TipoCall SMALLINT, @Origin INT = 0, @cal_key VARCHAR(20) = NULL, @callOutId INT = 0, @subId SMALLINT = 0
AS
SET NOCOUNT ON

DECLARE @RecicleSIC TINYINT, @Reprogram TINYINT, @DateNewDial SMALLDATETIME, @idTipoLista INT, @autoCB TINYINT, @tel VARCHAR(30), @camp INT, @iddncList AS INT
DECLARE @userid INT

SELECT @RecicleSIC = valor
FROM ccSettings
WHERE setting_id = 60

SELECT @RecicleSIC = IsNull(@RecicleSIC, 0)

DECLARE @hashTel INT
DECLARE @killListID INT = (
		SELECT idtipolista
		FROM ccTiposListaNegra
		WHERE Tipolista = ''default/KillList''
		)
DECLARE @killListSetting INT = (
		SELECT STATUS
		FROM ccSettings
		WHERE setting_id = 215
		)

IF @TipoCall = 1
BEGIN
	UPDATE ccCallsIN
	SET calif_id = @calif_id, cal_origin_id = @Origin, cal_key = isnull(@cal_key, cal_key), califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
	WHERE cal_id = @IDCall

	IF EXISTS (
			SELECT idTipoLista
			FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
			WHERE tipo = 0 AND calif_id = @calif_id
			)
	BEGIN
		SELECT @tel = dbo.Completa_ListaNegra(ci.cal_ANI), @iddncList = cbl.idTipoLista
		FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
		JOIN cccalifblacklist AS cbl ON ci.calif_id = cbl.calif_id
		WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0

		IF @tel IS NOT NULL AND @iddncList IS NOT NULL
		BEGIN
			--insert ccListaNegra
			INSERT INTO cclistanegra (telefono, idtipolista)
			VALUES (@tel, @iddncList)

			--insert cc_killlist
			IF (@killListSetting = 1 AND @iddncList = @killListID) -- verifies if kill list setting is active and if the list_id matches killList id
			BEGIN
				select @hashTel = dbo.hashPhone(@tel)

				IF NOT EXISTS (
						SELECT hashtel
						FROM cc_KillList
						WHERE hashTel = @hashTel
						)
				BEGIN
					INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
					VALUES (@hashTel, @iddncList, GETDATE())
				END
			END

			INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
			SELECT dbo.Completa_ListaNegra(ci.cal_ANI), cbl.idTipoLista, ci.Inbound_id, getdate(), ci.dni_id, 6
			FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
			JOIN cccalifblacklist cbl ON ci.calif_id = cbl.calif_id
			WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0
		END
	END

	RETURN (0)
END

IF @TipoCall = 2
BEGIN
	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	SELECT @autoCB = autocallback
	FROM ccTipoCalifSubout
	WHERE califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	IF @autoCB IS NULL
	BEGIN
		SELECT @autoCB = autocallback
		FROM cctipocalifout
		WHERE calif_id = @calif_id
	END

	IF @autoCB = 1
	BEGIN
		SELECT @callOutId = callout_id, @camp = cam_id, @userid = user_id
		FROM ccocallsout
		WHERE Cal_id = @IDCall

		SELECT @DateNewDial = dateadd(mi, t_autoCB, getdate())
		FROM cccamps cam
		WHERE cam.cam_id = @camp

		EXEC ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
	END

	UPDATE ccoCallsOUT
	SET calif_id = @calif_id, califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
	WHERE cal_id = @IDCall

	IF EXISTS (
			SELECT idTipoLista
			FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
			WHERE tipo = 1 AND calif_id = @calif_id
			) AND NOT EXISTS (
			SELECT co.cal_telefono
			FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
			JOIN ccListaNegra bl ON dbo.Completa_ListaNegra(co.cal_telefono) = bl.telefono OR co.cal_telefono = bl.telefono
			WHERE co.cal_id = @idCall AND bl.idtipolista IN (
					SELECT idTipoLista
					FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
					WHERE tipo = 1 AND calif_id = @calif_id
					)
			)
	BEGIN
		SELECT @tel = dbo.Completa_ListaNegra(co.cal_telefono), @iddncList = cbl.idTipoLista
		FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
		JOIN cccalifblacklist cbl ON co.calif_id = cbl.calif_id
		WHERE co.cal_id = @idCall AND left(dbo.Completa_ListaNegra(co.cal_telefono), 1) <> ''E'' AND cbl.tipo = 1

		IF @tel IS NOT NULL AND @iddncList IS NOT NULL
		BEGIN
			EXEC ccsp_InsertDNCList @tel, @iddncList

			IF (@killListSetting = 1 AND @iddncList = @killListID)
			BEGIN
				select @hashTel = dbo.hashPhone(@tel)

				IF NOT EXISTS (
						SELECT hashtel
						FROM cc_KillList
						WHERE hashTel = @hashTel
						)
				BEGIN
					INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
					VALUES (@hashTel, @iddncList, GETDATE())
				END
			END

			INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
			SELECT dbo.Completa_ListaNegra(co.cal_telefono), cbl.idTipoLista, co.cam_id, getdate(), co.callout_id, 6
			FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
			JOIN cccalifblacklist cbl ON co.calif_id = cbl.calif_id
			WHERE co.cal_id = @idCall AND left(dbo.Completa_ListaNegra(co.cal_telefono), 1) <> ''E'' AND cbl.tipo = 1
		END
	END

	IF @RecicleSIC = 1
	BEGIN
		-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
		SELECT @Reprogram = CanReprogram
		FROM ccTipoCalifSubout
		WHERE califSub_Id = @subId

		-- Si no tiene subcalificacion toma la de la calificacion
		IF @Reprogram IS NULL
		BEGIN
			SELECT @Reprogram = CanReprogram
			FROM ccTipoCalifOUT
			WHERE calif_id = @calif_id
		END

		IF @callOutId = 0
			SELECT @callOutId = callout_id
			FROM ccocallsout
			WHERE Cal_id = @IDCall

		UPDATE ccoWorkingTable
		SET calif_id = @calif_id, cal_status = CASE @Reprogram WHEN 0 THEN 3 ELSE cal_status END
		WHERE callout_id = @callOutId
	END

	DECLARE @keepDial BIT
	DECLARE @finishPreview SMALLINT

	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	SELECT @keepDial = keepDial
	FROM ccTipoCalifSubout
	WHERE califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	IF @keepDial IS NULL
	BEGIN
		SELECT @keepDial = keepDial
		FROM ccTipoCalifout
		WHERE calif_id = @calif_id
	END

	SELECT @finishPreview = isnull(finishPreview, 0)
	FROM ccTipoCalifout
	WHERE calif_id = @calif_id

	IF @keepDial = 1
	BEGIN
		UPDATE ccologdials
		SET TipoDialingMode = dbo.fn_getDialingMode(@IDCall, 3, 0, @camp)
		WHERE logDial_id IN (
				SELECT TOP 1 L.logDial_id
				FROM ccoLogDials L WITH (INDEX (IX_ccoLogDials_2), NOLOCK)
				JOIN ccoCallsOut O WITH (INDEX (PK_ccoCallsOut), NOLOCK) ON L.callout_id = O.callout_id
				WHERE O.cal_id = @IDCall
				ORDER BY L.logDial_id DESC
				)
	END

	SELECT @keepDial, @finishPreview

	RETURN (0)
END

SET NOCOUNT OFF
'
		EXEC (@Sql)

		SET @process = 'cw-3201 Alter SP ccsp_RIADNCList'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIADNCList] @phoneNumber AS VARCHAR(30), @idDNCList AS INTEGER, @tipoMov AS TINYINT, @calKey AS VARCHAR(20) = NULL
AS
DECLARE @hashCalKey INT, @hashPhone BIGINT

IF @calKey IS NOT NULL
BEGIN
	SELECT @hashCalKey = dbo.hashList(@calKey)
END

IF @tipoMov = 1
BEGIN -- Inserta Lista Negra	
	EXEC ccsp_InsertDNCList @telephone = @phoneNumber, @ln_id = @idDNCList, @hashCalKey = @hashCalKey

	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	VALUES (@phoneNumber, 7, @idDNCList)
END

IF @tipoMov = 2
BEGIN -- Borra Lista Negra	
	SELECT @hashPhone = dbo.hashPhone(@phoneNumber)

	IF @hashCalKey IS NULL
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idDNCList
	END
	ELSE
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idDNCList
	END

	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	VALUES (@phoneNumber, 5, @idDNCList)
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
END
'
		EXEC (@Sql)	

		set @process = 'cw-3001 alter procedure getUnavailableTimes'
		set @sql = '
ALTER PROCEDURE [dbo].[ccsp_GetUnavailableTypes] @action INT
	,@startDate DATETIME =  null
	,@endDate DATETIME = null
	,@unavailable_id VARCHAR(300) = null
AS
IF (@action = 0)
BEGIN
	SELECT TipoNotReady_id AS [unavailable_id]
		,Descripcion AS [description]
		,Time_Acum AS [MaxTime]
		,Time_xEv AS [MaxTimePerEvent]
		,Pas_Sup AS [AdminPw]
		,NextStatus AS [NextStatus]
		,IsSup AS [AdminOnly]
		,StatusTipoNotReady AS [UnavailableStatus]
	FROM ccTipoNotReady
END

IF (@action = 1)
BEGIN
	DECLARE @tabla TABLE (notReadyId INT PRIMARY KEY)

	INSERT INTO @tabla
	SELECT value
	FROM dbo.fn_RIASplitDelimited(@unavailable_id, '','')
	
	SELECT user_id, sum(tstatus)
	FROM ccLogAgentesNotReady A WITH (NOLOCK)
	INNER JOIN @tabla B ON A.TipoNotReady_id = B.notReadyId
	WHERE fecha >= @startDate
		AND fecha <= @enddate
	GROUP BY user_id
END'

		exec (@sql)
		

		SET @process = 'cw-3201 ALTER FUNCTION ValidateBlackListPhone'
		SET @Sql = 'ALTER FUNCTION [dbo].[ValidateBlackListPhone] (@tel VARCHAR(32), @camId INT, @calKey VARCHAR(20))
RETURNS BIT
AS
BEGIN
	DECLARE @isBlackPhone BIT
	--PARA LA VALIDACION DE LISTAS NEGRAS CON HASH
	DECLARE @hasTelefono BIGINT

	SELECT @hasTelefono = dbo.hashPhone(@tel)

	DECLARE @hasCalKey BIGINT

	IF @calKey IS NOT NULL OR @calKey <> ''''
		SELECT @hasCalKey = dbo.hashList(@calKey)

	SET @isBlackPhone = 0

	IF EXISTS (
			SELECT a2.idtipolista
			FROM cclistanegra a1
			INNER JOIN camplistanegra a2 WITH (INDEX (IX_Camplistanegra)) ON a1.idtipolista = a2.idtipolista
			WHERE a2.cam_id = @camId AND STATUS = 1 AND a1.Hashtel = @hasTelefono AND (a1.HashKey IS NULL OR a1.HashKey = @hasCalKey)
			)
		SET @isBlackPhone = 1

	RETURN @isBlackPhone
END
'
		EXEC (@Sql)

		SET @process = 'cw-3201 Alter SP ccsp_RIAUploadBLst'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUploadBLst] @command TINYINT, @telephone VARCHAR(20) = 0, @idtipolista INT, @calKey AS VARCHAR(20) = NULL
AS
SET NOCOUNT ON

DECLARE @hashCalKey INT, @hashPhone BIGINT

SELECT @hashPhone = dbo.hashPhone(@telephone)

IF @calKey IS NOT NULL
BEGIN
	SELECT @hashCalKey = dbo.hashList(@calKey)
END

IF @hashCalKey IS NULL
BEGIN
	IF @command IN (1, 4) --LookForNumber	
		AND EXISTS (
			SELECT idtipolista
			FROM cclistanegra
			WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idtipolista
			)
	BEGIN
		SELECT 1

		RETURN (0)
	END
END
ELSE
BEGIN
	IF @command IN (1, 4) --LookForNumber	
		AND EXISTS (
			SELECT idtipolista
			FROM cclistanegra
			WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
			)
	BEGIN
		SELECT 1

		RETURN (0)
	END
END

IF @command = 1 --Insert Number
BEGIN
	EXEC ccsp_InsertDNCList @telephone, @idtipolista, @hashCalKey

	INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
	VALUES (@telephone, 1, @idtipolista)

	RETURN (0)
END

IF @command = 2 --Delete Number
BEGIN
	INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
	VALUES (@telephone, 5, @idtipolista)

	IF @hashCalKey IS NULL
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey IS NULL
	END
	ELSE
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey
	END

	RETURN (0)
END

IF @command = 3 --Reemplaza
BEGIN
	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	SELECT telefono, 4, @idtipolista
	FROM cclistanegra
	WHERE idtipolista = @idtipolista

	DELETE
	FROM cclistanegra
	WHERE idtipolista = @idtipolista

	RETURN (0)
END

IF @command = 5 --Delete by idtipolista
BEGIN
	UPDATE ccTiposListaNegra
	SET STATUS = 0
	WHERE idtipolista = @idtipolista

	DELETE ccAgendaListaNegra
	WHERE idagenda IN (
			SELECT idagenda
			FROM ccAgenda_TipolistaNegra
			WHERE idtipolista = @idtipolista
			)

	DELETE ccAgenda_TipolistaNegra
	WHERE idtipolista = @idtipolista

	DELETE cccalifblacklist
	WHERE idtipolista = @idtipolista

	DELETE Camplistanegra
	WHERE idtipolista = @idtipolista

	DECLARE @telefono VARCHAR(10)

	WHILE EXISTS (
			SELECT telefono
			FROM ccListaNegra
			WHERE idtipolista = @idtipolista
			)
	BEGIN
		SELECT TOP 1 @hashPhone = Hashtel, @telefono = telefono
		FROM ccListaNegra
		WHERE idtipolista = @idtipolista

		INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
		VALUES (@telefono, 5, @idtipolista)

		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND idtipolista = @idtipolista
	END

	RETURN (0)
END

SET NOCOUNT OFF
'
		EXEC (@Sql)

		SET @process = 'cw-3201 Alter Trigger ccListaNegra.[trigHashPhone]'
		SET @Sql = 'ALTER TRIGGER [dbo].[trigHashPhone] ON [dbo].[ccListaNegra]
FOR INSERT
AS
SET NOCOUNT ON
begin	
	update A set A.Hashtel= dbo.hashPhone(B.telefono) from ccListaNegra A
	inner join INSERTED B on  A.idtipolista=B.idtipolista and A.telefono=B.telefono 

end'
		EXEC (@Sql)


		SET @process = 'CW-3032 Alter SP ccsp_AgentLastNotReady'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentLastNotReady] 
				@user_id SMALLINT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @lastStatus TINYINT;
	DECLARE @info VARCHAR(100);

	
	SELECT @lastStatus = 0;

	SELECT TOP 1 @lastStatus = ISNULL(tipoStatusAge_id, 0)
	FROM ccLogAgentesDia 
	WHERE user_id = @user_id and tipoStatusAge_id not in(0,1)
	ORDER BY fecha DESC;

	IF @lastStatus = 2
	BEGIN
		SELECT TOP 1 tipoNotReady_Id
		FROM ccLogAgentesNotReady
		WHERE user_id = @user_id
		ORDER BY fecha DESC;
	
		RETURN( 0 );
	END;

	SELECT 0 AS tipoNotReady_Id;

	SET NOCOUNT OFF;
END;'
		EXEC (@Sql)


		set @process = 'cw-2915 delete  job dnckillList'
		set @sql= 'USE [msdb]
if exists (select * from msdb.dbo.sysjobs_view where name = N''DNCKillList'')
    begin
        exec msdb.dbo.sp_delete_job @job_name = N''DNCKillList'', @delete_unused_schedule=1
    end
/****** Object:  Job [DNCKillList]    Script Date: 03/06/2019 12:35:07 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 03/06/2019 12:35:07 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''DNCKillList'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Deletes from cc_KillList table according to an specific time (setting 215)'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ccKillList]    Script Date: 03/06/2019 12:35:07 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''ccKillList'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec cc_DNCKillList'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ccKillList'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20190531, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
'

		exec (@sql)

		SET @process = 'cw-3201 JOB CW Update ccListaNegra Hashtel'
		SET @Sql = 'USE [msdb]


if exists(select * from msdb.dbo.sysjobs_view where name=N''CW Update ccListaNegra Hashtel'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW Update ccListaNegra Hashtel'', @delete_unused_schedule=1

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Update ccListaNegra Hashtel'', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp]    Script Date: 05/06/2019 10:12:59 a. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run sp'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''if exists(select * from ccListaNegra where Hashtel is null) begin
    update top (20000) ccListaNegra set  Hashtel=dbo.hashPhone(telefono) where Hashtel is null
end
else begin 
    EXEC msdb.dbo.sp_delete_job @job_name=N''''CW Update ccListaNegra Hashtel'''', @delete_unused_schedule=1
end'', 
		@database_name=N''CCenterRia'', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''CW Update ccListaNegra Hashtel schedule'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20041022, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		EXEC (@Sql)



		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
