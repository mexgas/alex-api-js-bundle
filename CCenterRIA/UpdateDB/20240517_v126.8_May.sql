/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2023/07/04
Description: K089000
Database: CCenterRia
Required version: 125.37
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
SET @version = 126 --**********actualizar a 124 sin fix
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
		----------------------------------------------------- BEGIN Ulises KR134024 KR134025 KR134026 KR134027  ----------------------------------------------------------------
		SET @process = 'KR134024 KR134025 KR134026 KR134027 Modulo';
    	SET @sql = 'if not exists ( select 1 from ccGalateaModules where ModuleId = 22)
		begin
			INSERT INTO ccGalateaModules(ModuleId, MTagEs, MTagEn, MTagPt) 
				values(22,''Roles de usuario'', ''User roles'', ''Funções de usuário'')
		end';
	   EXEC (@sql);

	   SET @process = 'KR134024 KR134025 KR134026 KR134027 operation 114';
	   SET @sql = 'if not exists ( select 1 from ccGalateaOperations where OperationId = 114)
		begin
			INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
				VALUES (114, ''Crear rol de usuario'', ''Create user role'', ''Criar função de usuário'')
		end';
	   EXEC (@sql);

	   SET @process = 'KR134024 KR134025 KR134026 KR134027 operation 115';
	   SET @sql = 'if not exists ( select 1 from ccGalateaOperations where OperationId = 115)
		begin
			INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
				VALUES (115, ''Editar rol de usuario'', ''Edit user role'', ''Editar função de usuário'')
		end';
	   EXEC (@sql);

	   SET @process = 'KR134024 KR134025 KR134026 KR134027 operation 116';
	   SET @sql = 'if not exists ( select 1 from ccGalateaOperations where OperationId = 116)
		begin
			INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
				VALUES (116, ''Eliminar rol de usuario'', ''Delete user role'', ''Excluir função de usuário'')
		end';
	   EXEC (@sql);

	   SET @process = 'KR134024 KR134025 KR134026 KR134027 operation 117';
	   SET @sql = 'if not exists ( select 1 from ccGalateaOperations where OperationId = 117)
		begin
			INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
				VALUES (117, ''Asignar rol de usuario'', ''Assign user role'', ''Atribuir função de usuário'')
		end';
	   EXEC (@sql);

	   SET @process = 'KR134024 KR134025 KR134026 KR134027 operation 118';
	   SET @sql = 'if not exists ( select 1 from ccGalateaOperations where OperationId = 118)
		begin
			INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
				VALUES (118, ''Desasignar rol de usuario'', ''Unassign user role'', ''Cancelar atribuição de função de usuário'')
		end';
	   EXEC (@sql);

		----------------------------------------------------- END Ulises KR134024 KR134025 KR134026 KR134027  ----------------------------------------------------------------
        ----------------------------------------------------- BEGIN KR134000-SMS Masivo Muñoz, Ivan Martin  ----------------------------------------------------------------
    	SET @process = 'KR134000 Creación de tabla de status de referencia para email de mensajes sms. ';
    	SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N''ccSmsEmailResultStatus'')
                    BEGIN
                        CREATE TABLE ccSmsEmailResultStatus (
                            Id INT PRIMARY KEY IDENTITY(1,1),
                            Name VARCHAR(50) NOT NULL,
                            Description NVARCHAR(MAX) NOT NULL
                        );
                    END';
    	EXEC (@sql);

        SET @process = 'KR134000 Se insertan valores en la tabla';
        SET @sql = 'IF NOT EXISTS (SELECT * FROM ccSmsEmailResultStatus)
                    BEGIN
                        INSERT INTO ccSmsEmailResultStatus (Name, Description)
                        VALUES 
                            (''Success'', ''Message successfully sent''),
                            (''SendEmailError'', ''An error occurred while sending the message''),
                            (''AdminWithoutAssignedEmail'', ''Admin without assigned email''),
                            (''CenterwareWithoutOutboundEmail'', ''Centerware without outbound email'');
                    END;';
        EXEC (@sql);

        SET @process = 'KR134000 Creación de tabla para guardar mensajes';
        SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N''ccSmsResponseMessages'')
                    BEGIN
                        CREATE TABLE ccSmsResponseMessages (
                            Id INT PRIMARY KEY IDENTITY(1,1),
                            Destination VARCHAR(32) NOT NULL,
                            Source VARCHAR(32) NOT NULL,
                            Text NVARCHAR(MAX) NOT NULL,
                            Date DATETIME NOT NULL,
                            SystemApiId VARCHAR(100) NOT NULL, 
                            EmailAttempts INT NOT NULL DEFAULT 0,
                            EmailResultStatus SMALLINT NOT NULL DEFAULT 0,
                        );
                    END';
        EXEC (@sql);

        SET @process = 'KR134000 Se crea índice para SystemApiId';
        SET @sql = 'IF OBJECT_ID(N''IX_ccSmsResponseMessages_SystemApiId'', N''INDEX'') IS NULL
                    BEGIN
                        CREATE INDEX IX_ccSmsResponseMessages_SystemApiId ON ccSmsResponseMessages (SystemApiId);
                    END';
        EXEC (@sql);
		
        SET @process = 'KR134000 Creación de tabla para hacer BulkCopy al terminar procesamiento de correos y actualizar estados.';
        SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N''ProcessingSmsClientMessagesEmails'')
                    BEGIN
                        CREATE TABLE ProcessingSmsClientMessagesEmails (
                            Destination VARCHAR(32) NOT NULL,
                            Source VARCHAR(32) NOT NULL,
                            Text NVARCHAR(MAX) NOT NULL,
                            Date DATETIME NOT NULL,
                            SystemApiId VARCHAR(100) NOT NULL, 
                            UserEmail NVARCHAR(255), 
                            EmailAttempts INT NOT NULL DEFAULT 0,
                            EmailResultStatus SMALLINT NOT NULL DEFAULT 0,
                        );
                    END';
        EXEC (@sql);

        SET @process = 'KR134000 Drop procedure ccspSmsClientsResponse';
        SET @sql = 'IF EXISTS(SELECT * FROM sys.procedures WHERE name = N''ccspSmsClientsResponse'')
                    BEGIN
                      DROP PROCEDURE ccspSmsClientsResponse
                    END';
        EXEC (@sql);

        SET @process = 'KR134000 Se crea procedimiento almacenado ccspSmsClientsResponse';
        SET @sql = 'CREATE PROCEDURE [dbo].[ccspSmsClientsResponse] 
                    @Action SMALLINT, 
                    @Destination VARCHAR(32) = NULL, 
                    @Source VARCHAR(32) = NULL,
                    @Text VARCHAR(MAX) = NULL,
                    @Date DATETIME = NULL,
                    @SystemApiId VARCHAR(100) = NULL
                    AS

                    IF @Action IS NOT NULL BEGIN
                        IF @Action = 0 BEGIN        -- Insert new client message
                            INSERT INTO ccSmsResponseMessages (Destination, Source, Text, Date, SystemApiId) VALUES (@Destination, @Source, @Text, @Date, @SystemApiId)
                        END

                        IF @Action = 1 BEGIN        -- Get sender email information
                            SELECT valor FROM ccSettings WHERE setting_id = 98
                        END

                        IF @Action = 2 BEGIN        -- Get admin email information
                            SELECT LD.cam_id AS CampaignId, 
                                   U.notificationEmail AS AdminEmails
                            FROM ccSmsResponseMessages RM
                            INNER JOIN smsccoLogDial LD ON LD.SystemApiId = RM.SystemApiId
                            INNER JOIN ccSupervisorCam SC ON SC.cam_id = LD.cam_id 
                            INNER JOIN ccUsers U ON U.User_id = SC.user_id
                            WHERE RM.EmailResultStatus <> 1     -- Get all non successful email messages
                            GROUP BY LD.cam_id, U.notificationEmail;
                        END

                        IF @Action = 3 BEGIN        -- Get messages to send an email
                            SELECT  RM.Destination, 
                                    RM.Source, 
                                    RM.Text, 
                                    RM.Date, 
                                    RM.SystemApiId, 
                                    LD.cam_id AS CampaignId,
                                    RM.EmailResultStatus,
                                    RM.EmailAttempts
                            FROM ccSmsResponseMessages RM
                            INNER JOIN smsccoLogDial LD ON LD.SystemApiId = RM.SystemApiId
                            WHERE  RM.EmailResultStatus <> 1 
                        END

                        IF @Action = 4 BEGIN        -- Update email attempts and status BEGIN TRY
                            BEGIN TRY
                            BEGIN TRANSACTION;
                                UPDATE ccSmsResponseMessages
                                SET EmailAttempts = PM.EmailAttempts,
                                    EmailResultStatus = PM.EmailResultStatus
                                FROM ccSmsResponseMessages RM
                                INNER JOIN ProcessingSmsClientMessagesEmails PM ON RM.SystemApiId = PM.SystemApiId

                                COMMIT TRANSACTION;
                                RETURN @@ROWCOUNT;
                            END TRY
                            BEGIN CATCH
                                IF @@TRANCOUNT > 0
                                    ROLLBACK TRANSACTION;

                                RETURN -1;
                            END CATCH
                        END
                    END
                    ELSE BEGIN
                        RAISERROR(''Invalid action specified.'', 16, 1);
                        RETURN -1;
                    END';
        EXEC (@sql);
        
        ----------------------------------------------------- END KR134000-SMS Masivo Muñoz, Ivan Martin  ----------------------------------------------------------------
		
		------------------------------------------------------BEGIN MACL---------------------------------------------------------------------
		SET @process = 'KR134013 - se elimina la funcion .';
        SET @sql = 'if object_id(''VerifySmsMCA'') is not NULL
BEGIN
	DROP FUNCTION VerifySmsMCA
END'
		EXEC @sql;

		SET @process = 'KR134013 - se crea la funcion VerifySmsMCA paraverificar los numero moviles.';
        SET @sql = 'CREATE FUNCTION [dbo].[VerifySmsMCA] (@tel VARCHAR(32))
RETURNS INT
AS
BEGIN
	DECLARE @ld VARCHAR(7)
	DECLARE @lon TINYINT
	DECLARE @result TINYINT
	DECLARE @mod VARCHAR(10)
	DECLARE @tipo VARCHAR(10)
	DECLARE @Cadena VARCHAR(32)
	DECLARE @isLocal BIT
	declare @serie varchar(10)
	DECLARE @pais TINYINT = 0;
	DECLARE @cldLocal VARCHAR(7);


	SET @pais = 1;
	SELECT @cldLocal = valor
	FROM ccSettings WITH (NOLOCK)
	WHERE setting_id = 17

	SELECT @tel = dbo.limpia(@tel)

	IF @pais = 1
	BEGIN --Empieza Mexico
		SELECT @lon = len(@tel), @mod = ''''

		IF @lon < 10
		BEGIN
			RETURN 3
		END

		SELECT @tel = right(@tel, 10)

		SELECT @lon = len(@tel)

		IF @lon = 10
		BEGIN
			IF EXISTS (
					SELECT TOP 1 cld
					FROM series NOLOCK
					WHERE cld = left(@tel, 3)
					and serie=SUBSTRING(@tel,4,3)
					)
				SELECT @ld = left(@tel, 3),@serie=SUBSTRING(@tel,4,3)
			ELSE IF EXISTS (
					SELECT TOP 1 cld
					FROM series NOLOCK
					WHERE cld = left(@tel, 2)
					and serie=SUBSTRING(@tel,3,4)
					)
				SELECT @ld = left(@tel, 2),@serie=SUBSTRING(@tel,3,4)
			ELSE
				RETURN 3

			SELECT TOP 1 @mod = modalidad, @tipo = [TIPO DE RED]
			FROM series NOLOCK
			WHERE cld = @ld AND serie = @serie AND right(@tel, 4) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

			IF @mod = ''FIJO''
			BEGIN
				RETURN 5
			END
			
			IF @tipo <> ''MOVIL''
			BEGIN
				RETURN 5
			END

			RETURN 0;
		END
		ELSE
		BEGIN
			RETURN 3
		END
	END
	RETURN 3;
END';
        EXEC (@sql);

		SET @process = 'KR134015 - Se cambian etiquetas para la car';
        SET @sql = 'IF NOT EXISTS (select 1 from tableLangueDbLoader where tag = ''column-file-field'' and [translate] = ''Columna de archivo/tabla'')
BEGIN
	UPDATE tableLangueDbLoader set translate = ''Columna de archivo/tabla'' where tag = ''column-file-field'' and languageId = 0
	UPDATE tableLangueDbLoader set translate = ''File/Table column'' where tag = ''column-file-field'' and languageId = 1
	UPDATE tableLangueDbLoader set translate = ''Coluna do arquivo/tabela'' where tag = ''column-file-field'' and languageId = 2
END';
        EXEC (@sql);

		SET @process = 'KR134000 - Se cambia el valor maximo de la colimna NUM_CUENTA de la tabla SmsRemesasMuñozDay';
        SET @sql = 'IF NOT EXISTS(
	select column_name, data_type, character_maximum_length    
	from information_schema.columns  
	where table_name = ''SmsRemesasMuñozDay''
	AND column_name = ''NUM_CUENTA'' and CHARACTER_MAXIMUM_LENGTH = 20)
BEGIN
	ALTER TABLE SmsRemesasMuñozDay ALTER COLUMN NUM_CUENTA VARCHAR(20)
END';
        EXEC (@sql);

		SET @process = 'KR134018 - se crea tabla para guardar los resultados de la validación de segmentos';
        SET @sql = 'IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = ''SmsSegmentsValidationResult'')
BEGIN
	CREATE TABLE SmsSegmentsValidationResult(
		id_credito bigint not null,
		credito nvarchar(40) null,
		TELEFONOS1 nvarchar(50) null,
		TDCT varchar(255) not null, 
		RESULTADO varchar(50) null,
		RESULTADO_ID INT null,
		validation_date datetime null
	)
	CREATE INDEX IX_SmsSegmentsValidationResult_TDCT ON SmsSegmentsValidationResult (TDCT)
	CREATE INDEX IX_SmsSegmentsValidationResult_CREDITO ON SmsSegmentsValidationResult (CREDITO)
	CREATE INDEX IX_SmsSegmentsValidationResult_RESULTADO_ID ON SmsSegmentsValidationResult (RESULTADO_ID)
END';
        EXEC (@sql);

		SET @process = 'KR134013 - se agrega fecha final y bandera de carga por segmento';
        SET @sql = 'IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''smsOutSource'' and COLUMN_NAME = ''sms_dateDialEnd'')
BEGIN
	ALTER TABLE smsOutSource add sms_dateDialEnd datetime
	ALTER TABLE smsOutSource add isSegmentLoad bit
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''smsWorkingTable'' and COLUMN_NAME = ''sms_dateDialEnd'')
BEGIN
	ALTER TABLE smsWorkingTable add sms_dateDialEnd datetime
	ALTER TABLE smsWorkingTable add isSegmentLoad bit
END

IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccRIALoading'' and COLUMN_NAME = ''LoadBySegment'')
BEGIN
	ALTER TABLE ccRIALoading ADD LoadBySegment bit
END';
        EXEC (@sql);

		SET @process = 'KR134000 - Se actualiza action 2 para obtener si es carga por segmento';
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetRecordsImportStatus]
		-- @Type = 1:Detalle general de carga de registros | 2:Detalle específico de carga de registros | 3:Porcentaje de carga de registros
		@action tinyint, 
		@loadID int = NULL, 
		@userID smallint = NULL

		AS
		declare @today datetime
		select @today =convert(datetime, convert(varchar(11),getdate(),121),121)
		SET nocount ON
		if @action not IN (1,2,3)
		raiserror(''ERROR. No se ingreso parametro de entrada'', 18, 1)

		if @action=1 -- Detalle general de carga de registros
		BEGIN
		if not exists(SELECT User_id FROM ccUsers WHERE TipoUser_id IN(2,6) AND Status>0 AND User_id=@userID)
		 BEGIN
		  raiserror(''ERROR. invalid user id'', 18, 1)
		  return(0)
		 END

		if exists (select * from ccUsers_Roles where User_id = @userID and Rol_id = (select Rol_id from ccRoles where Level = 7))
			BEGIN
				SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked+isnull(regsNotLoadedCp,0)+ISNULL(recordsNotLoadedPort,0) as regsNotLoaded, state, loadDate	
				FROM ccRIALoading riaLoad
				JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
				WHERE 
				loadDate>=@today and loadType = 0
				ORDER BY riaLoad.loadDate DESC
			END
		else
			BEGIN
				SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked+isnull(regsNotLoadedCp,0)+ISNULL(recordsNotLoadedPort,0) as regsNotLoaded, state, loadDate
		
				FROM ccRIALoading riaLoad
				JOIN ccSupervisorCam superCam ON riaLoad.cam_id = superCam.cam_id
				JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
				WHERE 
				loadDate>=@today AND
				superCam.user_id = @userID
				AND superCam.tipo = 1
				ORDER BY riaLoad.loadDate DESC
			END

		return(0)
		END

		if @action=2 -- Detalle específico de carga de registros
		BEGIN
		if not exists(SELECT load_id FROM ccRIALoading)
		 BEGIN
		  raiserror(''ERROR. invalid template ID'', 18, 1)
		  return(0)
		 END

		  SELECT regsLoaded, alreadyLoaded, regsBlocked, regsNotLoaded,
				 telsLoaded, telsBlocked, telsNotLoaded, isnull(regsNotLoadedCp,0) as regsNotLoadedCp
				 , isnull(telsNotLoadedCp,0) as telsNotLoadedCp, ISNULL(recordsNotLoadedPort,0) as recordsNotLoadedPort, ISNULL(phonesNotLoadedPort, 0) as phonesNotLoadedPort, 
				 ISNULL(LoadBySegment, CAST(0 AS BIT)) as IsSegmentLoad
		  FROM ccRIALoading
		  WHERE load_id  = @loadID

		END

		if @action=3 -- Porcentaje de carga de registros
		BEGIN
		if not exists(SELECT load_id FROM ccRIALoading)
		 BEGIN
		  raiserror(''ERROR. invalid load ID'', 18, 1)
		  return(0)
		 END

		  SELECT state, pctg
		  FROM ccRIALoading
		  WHERE load_id  = @loadID

		END
		SET nocount off';
        EXEC (@sql);

		SET @process = 'KR134013 - Se agrega condicion para cuando sea carga por segmento, solo traer registros dentro del horario';
        SET @sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewJobsSMS]
@CAMPID INT,
@action INT=0, --0 select and update, 1 select registry
@topCount INT=50

as
set nocount on
DECLARE @iZonas INT = NULL
DECLARE @bIsDaylight bit, @revHorario bit
DECLARE @country_id INT, @TipoJobs INT

DECLARE @sql nvarchar(MAX), @Order_Asc_Desc char(4)
declare @sqlInsertGeneric nvarchar(MAX)
declare @parameters nvarchar(MAX)
		
-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
SELECT @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
SELECT @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

exec @iZonas= ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0

if exists(SELECT cam_id from ccSmsSchedules where cam_id=@campid)
begin
	if @iZonas = 0 begin
		SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
		return
	end
end


IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS

CREATE TABLE #NEW_JOBS (
	SmsOutId INT
	,CamId INT
	,Phone VARCHAR(30) collate SQL_Latin1_General_CP1_CI_AS
	,SmsStatus TINYINT
	,DateDial DATETIME
	,Tz1 INT
	,Tz2 INT
	,Tz3 INT
	,Tz4 INT
	,Tz5 INT
	,CallKey VARCHAR(40)
	,Message VARCHAR(255)
	)
set @sql=''''

DECLARE @new_calls_date VARCHAR(max) = '''';
		

SELECT @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

DECLARE @isVerano varchar(max)

	set @isVerano = ''W.iTimeZone'' + case @bIsDaylight when 1 then ''_summer'' else '''' END

	select @sqlInsertGeneric=nchar(13)+ ''INSERT #NEW_JOBS
SELECT top(@topCount) W.smsout_id, W.cam_id, W.sms_phoneNumber, W.sms_status, W.sms_dateDial,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
sos.callkey as CallKey
,msg.message as Message
FROM smsWorkingTable W 
left join smsOutSource sos (nolock) on sos.smsout_id=W.smsout_id
left join smsoutSourceMessage msg (nolock) on msg.smsout_id =W.smsout_id
WHERE STATUS_REPLACE_QUERY
and DATE_REPLACE_QUERY
and W.cam_id=@CAMPID
and (
   ( (''+@isVerano+''  & @iZonas)>0 or ''+@isVerano+''=0) 
or ( (''+@isVerano+''2 & @iZonas)>0 or ''+@isVerano+''2=0) 
or ( (''+@isVerano+''3 & @iZonas)>0 or ''+@isVerano+''3=0) 
or ( (''+@isVerano+''4 & @iZonas)>0 or ''+@isVerano+''4=0)
or ( (''+@isVerano+''5 & @iZonas)>0 or ''+@isVerano+''5=0)
)''
print(@sqlInsertGeneric);
if @TipoJobs in(0,2)--** INCLUIR LOS NUEVAS
begin				
	select @sql=@sql+nchar(13)+''--INCLUIR LAS NUEVAS--''
	select @sql=@sql+REPLACE(
	REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.sms_dateDial < dateadd(mi, 5, getdate()) AND (ISNULL(W.isSegmentLoad, 0) = 0 OR (ISNULL(W.isSegmentLoad, 0) = 1 AND W.sms_dateDialEnd > getdate()))'')
		,''STATUS_REPLACE_QUERY'',''W.sms_status=0'')
	select @sql=@sql+nchar(13)+'' order by W.sms_dateDial ''+ @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc
	--print(@sql)
end -- TOMA EN CUENTA LAS NUEVAS

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin
	select @sql=@sql+nchar(13)+''--INCLUIR LOS CALLBACKS--''
	select @sql=@sql+nchar(13)+REPLACE(
		REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.cal_fechaDial<dateadd(mi, 5, getdate())'')
	,''STATUS_REPLACE_QUERY'',''W.sms_status=1 -- CallBacks'')
	select @sql=@sql+nchar(13)+'' order by priority_cb desc, W.sms_dateDial ''  + @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
		
					
end -- TOMA EN CUENTA LOS CALLBACKS
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
set @parameters=''@CAMPID int,@topCount int,@iZonas int''		

if @action=0
begin
	
	SELECT @sql=@sql+nchar(13)+ ''UPDATE smsWorkingTable with (rowlock) SET sms_status=2 --CALLBACK IN PROGRESS
	WHERE smsout_id in(SELECT SmsOutId from #NEW_JOBS)''	
end

		
	select @sql=@sql+nchar(13)+ ''SELECT SmsOutId, CamId, Phone, SmsStatus, DateDial,
Tz1,Tz2,Tz3,Tz4,Tz5,CallKey as RegistryClient,Message
FROM #NEW_JOBS where len(Phone)>0
''

print(''-------------------------------------------'')
print (@sql)

exec sp_executesql  @sql,@parameters,
@CAMPID=@CAMPID
,@topCount=@topCount
,@iZonas=@iZonas

IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS

return(0)';
        EXEC (@sql);

		SET @process = 'KR134015 - Se agrega cambio para obtener si es carga por segmento';
        SET @sql = 'ALTER procedure [dbo].[ccsp_RIALogPhones]
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

		if @nType like ''%____1%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov in (0,8)
			''

		if @nType like ''%___1_%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov in(-1,0,8) 
			''

		if @nType like ''%__1__%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov IN (1,0) 
			''

		if @nType like ''%_1___%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov IN (1,4) 
			''

		if @nType like ''%1____%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 2 ''

		if @CaseType = '''' and @nType <> 0
			return(0)

		if @nType like ''%____1%''
			select @CaseType = @CaseType + ''  or telefono<>'''''''' and crlp.tipoMov = 0''

		select @PageStart=@PageSize*(@PageIndex-1),@PageEnd=@PageSize*@PageIndex

		IF(@option = 1)
		BEGIN	
			SET @sql = ''SELECT count(*) AS listSize FROM (
		select crlp.load_id
		from ccRIALogPhones AS crlp 
		where crlp.load_id = @load_id'' 
		+ @CaseType +'') tmp '' +
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
						@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @typeUpdatedRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200), @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max);


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
							crlp.telefono AS phone,
							CASE
								WHEN crlp.tipoMov in (1,4)  THEN @typeDescriptionPhoneBlocked  
								WHEN crlp.tipoMov = 2 THEN @typeUpdatedRecords	
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @typeIncorrectRecords
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @typeBlockedRecords
								WHEN crlp.tipoMov in(-1,0) THEN @typeDescriptionPhoneNotLoaded
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
			, @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max), @typeUpdatedRecords varchar(200)''
			, @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id,@column=@column,@typeDescriptionPhoneNotLoaded=@typeDescriptionPhoneNotLoaded
			,@typeDescriptionPhoneBlocked=@typeDescriptionPhoneBlocked,@typeDescriptionPhoneUpdated=@typeDescriptionPhoneUpdated,@typeDescriptionPhoneBlackList=@typeDescriptionPhoneBlackList
			,@typeBlockedRecords=@typeBlockedRecords,@typeIncorrectRecords=@typeIncorrectRecords,@descriptionBlockedRecords=@descriptionBlockedRecords,@descriptionIncorrectRecords=@descriptionIncorrectRecords,
			 @descriptionInternationalPortNotFound= @descriptionInternationalPortNotFound 
			,@headerPhone=@headerPhone,@headerPhone2=@headerPhone2,@headerPhone3=@headerPhone3,@headerPhone4=@headerPhone4,@headerPhone5=@headerPhone5,@typeUpdatedRecords=@typeUpdatedRecords
	
		return(0)
		END
		set nocount OFF';
        EXEC (@sql);

		SET @process = 'KR134013 - cambios para obtener solo registros dentro de horario cuando fue carga por segmento';
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000
    AS
    SET NOCOUNT ON

    DECLARE @prioridad VARCHAR(8)
    DECLARE @batchsizeIni AS INT
    DECLARE @batchsizeFin AS INT
    DECLARE @rango AS DECIMAL
    DECLARE @rowstoInsert AS INT
    DECLARE @campType AS INT
    DECLARE @recordsQuantitySetting VARCHAR(8)
    DECLARE @settingValueP1 VARCHAR(25)

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
			and ((@date >= sos.sms_dateDial AND sos.isSegmentLoad = 1) OR sos.isSegmentLoad = 0) 

            UNION

            SELECT top(@top) swt2.smsout_id
            FROM dbo.smsOutSource AS sos2 WITH (INDEX (IX_smsOutSource_2), NOLOCK)
            inner join dbo.smsWorkingTable AS swt2 (NOLOCK)on sos2.smsout_id = swt2.smsout_id 
            WHERE sos2.cam_id = @camp_id AND (sos2.sms_status < 2 OR sos2.sms_status = 7)
			and ((@date >= sos2.sms_dateDial AND sos2.isSegmentLoad = 1) OR sos2.isSegmentLoad = 0) 

            INSERT INTO #smsoutIdSource2
            SELECT top(@top) sos.smsout_id
            FROM dbo.smsOutSource AS sos WITH (INDEX (IX_smsOutSource_1), NOLOCK)
            WHERE sos.sms_status IN (0, 1, 7) AND cam_id = @camp_id
			and ((@date >= sos.sms_dateDial  AND sos.isSegmentLoad = 1) OR sos.isSegmentLoad = 0) 

            INSERT #tempsmsOutSource(smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, cal_keyw, iTimeZone, 
            iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4,
             iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
            SELECT TOP(@top) smsout_id, cam_id, RTRIM(LEFT(LTRIM(sms_phoneNumber + ''        '' + sms_phoneNumber2 + ''         '' 
            + sms_phoneNumber3 + ''         '' + sms_phoneNumber4 + ''         '' + sms_phoneNumber5 + ''         ''), 13)) AS sms_phoneNumber,
             CASE sms_status WHEN 7 THEN 1 ELSE sms_status END sms_status, sms_dateDial, callkey, 
             CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone ELSE NULL END iTimeZone,
              CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone_summer ELSE NULL END iTimeZone_summer, 
              CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone2 ELSE NULL END iTimeZone2,
               CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone_summer2 ELSE NULL END iTimeZone_summer2, 
               CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone3 ELSE NULL END iTimeZone3, 
               CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone_summer3 ELSE NULL END iTimeZone_summer3,
                CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone4 ELSE NULL END iTimeZone4, 
                CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone_summer4 ELSE NULL END iTimeZone_summer4, 
                CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone5 ELSE NULL END iTimeZone5, 
                CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone_summer5 ELSE 
                        NULL END iTimeZone_summer5, list_id, sms_dateDialEnd, ISNULL(isSegmentLoad, 0)
            FROM dbo.smsOutSource  WITH (INDEX (IX_smsOutSource_1), NOLOCK)
            WHERE cam_id = @camp_id AND (sms_status < 2 OR sms_status = 7) 

            SELECT @rowstoInsert = COUNT(*) FROM #tempsmsOutSource AS tos;

            
            IF EXISTS(SELECT * FROM #tempsmsOutSource)
            BEGIN
                SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
                FROM #tempsmsOutSource  WITH (NOLOCK)

                SET @batchsizeFin = @batchsizeFin + @rango

                WHILE 1 = 1
                BEGIN
                    -- Nuevos Jobs
                    INSERT INTO dbo.smsWorkingTable
                    WITH (TABLOCKX) (smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, attemps, user_id,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
                    SELECT smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, 0, 0 ,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad
                    FROM #tempsmsOutSource 
                    WHERE id > @batchsizeIni AND id <= @batchsizeFin
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
                FROM dbo.smsOutSource AS sos WITH (NOLOCK), #smsoutIdSource2  cis3 WITH (NOLOCK)
                WHERE sos.smsout_id = cis3.smsout_id
            END

            DROP TABLE #smsoutIdSource

            DROP TABLE #smsoutIdSource2

            DROP TABLE #tempsmsOutSource
    END
    ELSE
    BEGIN
            CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19), cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(40), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT, iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT, iZonaHoraria_verano5 INT, list_id INT)

            CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
                WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

            CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

            CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

            INSERT INTO #calloutIdSource
            SELECT top(@top) cs.callout_id
            FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_15), NOLOCK)
            inner join ccoWorkingTable wt WITH (INDEX (IX_ccoWorkingTable_15), NOLOCK) 
            on cs.callout_id = wt.callout_id AND cs.cam_id = wt.cam_id 
            WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

            UNION

            SELECT top(@top) Cout.callout_id
            FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK)
            inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id 
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

            INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, 
            iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
             iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
            SELECT TOP(@top) callout_id, cam_id, CASE WHEN ISNULL(recycleType, 1) = 0 THEN 
            CASE 
                WHEN recyclePhone = 1 THEN cal_telefono
                WHEN recyclePhone = 2 THEN cal_telefono2
                WHEN recyclePhone = 3 THEN cal_telefono3
                WHEN recyclePhone = 4 THEN cal_telefono4
                else cal_telefono5
            END
            ELSE rtrim(left(ltrim(cal_telefono + ''        '' + cal_telefono2 + ''         '' 
                + cal_telefono3 + ''         '' + cal_telefono4 + ''         '' + cal_telefono5 + ''         ''), 13)) 
            END AS cal_telefono,
             CASE cal_status WHEN 7 THEN 1 ELSE cal_status END cal_status, cal_fechaDial, cal_key, 
             CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria ELSE NULL END iZonaHoraria,
              CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano, 
              CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria2 ELSE NULL END iZonaHoraria2,
               CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2, 
               CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria3 ELSE NULL END iZonaHoraria3, 
               CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
                CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria4 ELSE NULL END iZonaHoraria4, 
                CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4, 
                CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria5 ELSE NULL END iZonaHoraria5, 
                CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE 
                        NULL END iZonaHoraria_verano5, list_id
            FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
            WHERE cam_id = @camp_id AND (cal_status < 2 OR cal_status = 7) /*AND CONVERT(VARCHAR(10),cal_fechaDial, 103) >= CONVERT(VARCHAR(10), GETDATE(), 103)*/

            SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

            IF EXISTS(SELECT * FROM #tempCallsOutSource)
            BEGIN
                SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
                FROM #tempCallsOutSource WITH (NOLOCK)

                SET @batchsizeFin = @batchsizeFin + @rango

                WHILE 1 = 1
                BEGIN
                    -- Nuevos Jobs
                    INSERT INTO ccoWorkingTable
                    WITH (TABLOCKX) (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
                    SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id
                    FROM #tempCallsOutSource
                    WHERE id > @batchsizeIni AND id <= @batchsizeFin

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
                FROM ccoCallsOutSource co WITH (NOLOCK), #calloutIdSource2 cis3 WITH (NOLOCK)
                WHERE co.callout_id = cis3.callout_id
            END

            DROP TABLE #calloutIdSource

            DROP TABLE #calloutIdSource2

            DROP TABLE #tempCallsOutSource
    END

    UPDATE ccCampsNvosCB
    SET dateUpdate = NULL
    WHERE id = @camp_id

    SET NOCOUNT OFF
    ';
        EXEC (@sql);

		SET @process = 'KR134014 - Se agrega opcion 15 para obtener los resultados de la validacion por segmentos, 
		KR134018 - se guarda el resultado de la validación la tabla SmsSegmentsValidationResult';
        SET @sql = 'ALTER procedure [dbo].[ccspLoadRegistrySegments] 
@action int,
@camId int = null,
@typeTemplate int=2, --1 Segmentos, 2 Plantillas Archivos
@phone varchar(32)=null,
@templateId int=null,
@callKey varchar(60)=null,
@userId int=0,
@msg varchar(160)=null,
@smsout_id int=null,
@SystemApiId varchar(100)=null,
@statusSystemsId int=null,
@dateStart datetime=null,
@dateEnd datetime=null,
@segmentIds varchar(max)='''',
@columns varchar(max)=''*''
as

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

DECLARE @sql VARCHAR(max)
declare @today date=convert(date,getdate(),121)
declare @monday datetime


if @action=1 begin --List Segments
	select SegmentId,Name from ccSmsSegments where IsGlobal=1 or CampaignId=@camId
end
else if @action=2 begin  --ListColumnsTable
    SELECT name
	FROM sys.columns
	WHERE object_id = OBJECT_ID(''SmsRemesasMuñoz'')
	and name like ''TELEFONOS[0-9]%''
end
else if @action=3 begin --List Plantillas
    select TemplateId,Description as Name,MessageTemplate from ccSmsTemplate where Type=@typeTemplate
end
else if @action=4 begin
    Select iDate DateStart,fDate DateEnd from ccSmsSchedules where cam_id=@camId
end
else if @action=5 begin
    select top 1 * from SmsRemesasMuñoz
end
else if @action=6 begin
    SET @columns = ''''
	SELECT @columns = @columns + ''isnull(max(len('' + COLUMN_NAME + '')),0)as '' + COLUMN_NAME + '',''
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = ''SmsRemesasMuñoz''
	AND DATA_TYPE IN (''varchar'', ''nvarchar'', ''char'', ''nchar'');

	SET @columns = SUBSTRING(@columns, 0, len(@columns))
	SET @sql = ''select '' + @columns + '' from SmsRemesasMuñoz''

	--PRINT (@sql)
	EXEC (@sql)

end
else if @action=7 begin
    declare @valueInt int, @value varchar(100)
	select @valueInt=valor from ccSettings where setting_id=104
	select @value=valor from ccSettings where setting_id=17		

	select @phone= dbo.Verifica2(@phone,@valueInt,@value,1)
	if LEFT(@phone, 1)=''E'' begin
		select -1 as Result,''is not cellPhone''
		return -1;
	end
	select @valueInt=valor from ccSettings2 where setting_id=258
	if @valueInt<=0 begin
		select -2 as Result,''Credit Sms Zero''
	end
	select @value=valor from ccSettings where setting_id=247

	select 1 as Result,@value as ApiBackBone
	,MessageTemplate
	from ccSmsTemplate where TemplateId=@templateId
end
else if @action=8 begin --smsOutSource
    insert into smsOutSource (callkey,cam_id,sms_phoneNumber,sms_status,sms_attemps,user_id,sms_dateDial,dial_tels)
	values (@callKey,@camId,@phone,0,0,@userId,getdate(),''12345NNN'')
	select @smsout_id=SCOPE_IDENTITY()

	insert into smsoutSourceMessage(smsout_id,message)
	values(@smsout_id,@msg)

	select @smsout_id as smsoutId
end
else if @action=9 begin --smsccoLogDial
	insert into smsccoLogDial (smsout_id,cam_id,phone,smsDate,registryClient,SystemApiId,statusSystemsId,Bill,ProviderId)
	values (@smsout_id,@camId,@phone,getdate(),@callKey,@SystemApiId,@statusSystemsId,
	case when @statusSystemsId=0 then 0.7 else 0 end,0
	)	
end
else if @action=10 begin --ChangeSchedule
	delete from ccSmsSchedules where cam_id=@camId
	insert into ccSmsSchedules(cam_id,iDate,fDate) values(@camId,@dateStart,@dateEnd)
end
else if @action=11 begin --Carga los registros cargados
	truncate table ccSmsValidateRegistryWeek;
	SELECT @monday= DATEADD(DAY, -(DATEPART(WEEKDAY, @today) + @@DATEFIRST - 2) % 7, CAST(@today AS DATE))
	---------------Revisa la lista de registros es necesario moverlo a otro proceso para que lo tenga en la carga---------------------
	insert into ccSmsValidateRegistryWeek(registryClient,total,totaltoDay,loadRegistry)
	select registryClient,count(*) total,
	count(case when smsDate>=@today  then 1 end) totaltoday,
	0 loadRegistry
	from smsccoLogDial with(nolock)
	where smsDate>=@monday
	group by registryClient

end
else if @action in(12,13) begin --Validar Carga

	
	declare @segmentTable table(id int, status bit, segmentName VARCHAR(10))
	declare @segmentNames varchar(max)
	declare @conditionTable table(conditionId int,smsCondition varchar(max),DailyLimit int,WeeklyLimit int,status bit)
	--declare @SmsRemesasId table (credictId int)
	create table #SmsRemesasId(creditId nvarchar(40), TDCT VARCHAR(max))
	create table #SmsRemesasIdTemp(creditId nvarchar(40), TDCT VARCHAR(max))
	create table #functionalState(creditId nvarchar(40), smsSent int)
	declare @FlagB table(credictId int, TDCT VARCHAR(max))
	------------Se obtiene los dias de la semana que han pasado
	DECLARE @lastMonday datetime, @WeekStart datetime;
	DECLARE @DaysFromWeek int, @LastMondaymonth int, @ActualMonth int
	DECLARE @actualDate datetime = getdate()
	SET @lastMonday = DATEADD(DAY, -(DATEPART(WEEKDAY, @actualDate) + 5) % 7, @actualDate);
	--select @lastMonday lastMonday, @actualDate actualDate

	SET @LastMondaymonth = DATEPART(MONTH, @lastMonday);
	SET @ActualMonth = DATEPART(MONTH, @actualDate);

	IF(@ActualMonth = @LastMondaymonth)
	BEGIN
		SELECT @DaysFromWeek = DATEDIFF(DAY, @lastMonday, @actualDate);
	END
	ELSE BEGIN
		SELECT @DaysFromWeek = DATEDIFF(DAY, DATEADD(DAY, 1 - DATEPART(DAY, @actualDate), @actualDate), @actualDate);
	END
	SET @WeekStart = CONVERT(datetime, CONVERT(date, @actualDate-@DaysFromWeek));
	

	--------------------------Comienza validacion--------------

	insert into @segmentTable
	select a.value,0 status, s.Name from dbo.fn_RIASplitDelimited(@segmentIds,'','') a
	inner join ccSmsSegments s on s.segmentId = a.value

	--Condicion para obtener solo los que coincidan con SegmentoMC
	SELECT @segmentNames = COALESCE(@segmentNames + '', '', '''') + QUOTENAME(a.segmentName, '''''''')
	FROM @segmentTable a

	--Tabla con todos los id de la tabla remesa que hacen match con los segmentos
	INSERT INTO #SmsRemesasIdTemp
	SELECT a.credito, a.TDCT from SmsRemesasMuñozDay a 
	INNER JOIN @segmentTable b on a.SegmentoMC = b.segmentName
	--Reseteamos todos los resultados para los segmentos
	UPDATE rmd SET rmd.RESULTADO = '''', rmd.RESULTADO_ID = 0
	FROM SmsRemesasMuñozDay rmd 
	INNER JOIN #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
	--Actualizamos resultado para FLAG B
	UPDATE rmd SET rmd.RESULTADO = ''FLAG B'', rmd.RESULTADO_ID = 1
	FROM SmsRemesasMuñozDay rmd
	inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
	inner join ccSmsSegmentFlagB sfb on rmd.Fila = sfb.Validation
	WHERE rmd.RESULTADO_ID = 0 AND sfb.IsActive = 1

	--Actualizamos resultado para Telefono fijo y telefono no existe
	UPDATE rmd SET 
	rmd.RESULTADO = CASE 
		WHEN dbo.VerifySmsMCA(rmd.TELEFONOS1) = 3 THEN ''NO ES POSIBLE ENVIO, CELUAR NO SE ENCUENTRA EN IFT''
		WHEN dbo.VerifySmsMCA(rmd.TELEFONOS1) = 5 THEN ''TELEFONO FIJO''
		ELSE '''' END,
	rmd.RESULTADO_ID = dbo.VerifySmsMCA(rmd.TELEFONOS1)
	FROM SmsRemesasMuñozDay rmd
	inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
	WHERE rmd.RESULTADO_ID = 0

	--Regla de Estado Funcional para segmento BMX_122
	UPDATE rmd SET rmd.RESULTADO = ''NO SE ENVIA POR REGLA DE ESTADO FUNCIONAL'', rmd.RESULTADO_ID = 4
	FROM SmsRemesasMuñozDay rmd
	inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
	WHERE rmd.RESULTADO_ID = 0 AND rmd.SegmentoMC = ''BMX_122''
	AND ESTADO_FUNCIONAL <> ''F''

	INSERT INTO #functionalState
	select rid.creditId, count(rid.creditId) from smsccoLogDial ld
	inner join #SmsRemesasIdTemp rid on rid.TDCT = ld.callkey
	where ld.smsDate >= @WeekStart
	GROUP BY rid.creditId

	UPDATE rmd SET rmd.RESULTADO = ''NO SE ENVIA POR REGLA DE ESTADO FUNCIONAL'', rmd.RESULTADO_ID = 4
	FROM SmsRemesasMuñozDay rmd
	inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
	inner join #functionalState fs on rmd.id_credito = fs.creditId
	WHERE rmd.RESULTADO_ID = 0 AND rmd.SegmentoMC = ''BMX_122''
	AND fs.smsSent >= 3;


	declare @subQuery nvarchar(max)
	
	SELECT @monday= DATEADD(DAY, -(DATEPART(WEEKDAY, @today) + @@DATEFIRST - 2) % 7, CAST(@today AS DATE))
	
	if not exists(select * from ccSmsValidateRegistryWeek)begin
		exec ccspLoadRegistrySegments @action=11
	end
	

	declare @conditionId int,@segmentId int,@SubConditionId int
	declare @conditionWhere varchar(max)
	declare @SubConditionWhere varchar(max),@LogicConector varchar(20)
	declare @DailyLimit int,@WeeklyLimit int

	DECLARE @Params NVARCHAR(MAX)
	SET @Params = N''@WeeklyLimit int,@DailyLimit int'';
	
---Lista de @segmentIds
while exists(select * from @segmentTable where status=0) begin
	select top 1 @segmentId=id from @segmentTable where status=0		
	set @conditionId=0
	-------------------------------- Revisa las condiciones por segmentId --------------------------------
	while exists(select * from ccSmsConditions where SegmentId=@segmentId and ConditionId>@conditionId) begin
		
		select top 1
		@DailyLimit=DailyLimit,	@WeeklyLimit=WeeklyLimit,@conditionId=ConditionId,
		@conditionWhere= PrimaryField+LogicOperator
		+case when isnull(ComparisonValue,'''') <>'''' then ComparisonValue else''(''+ ComparisonField end 					
		+case when isnull(ComparisonValue,'''') <>'''' or  isnull(ArithmeticOperator,'''')='''' or isnull(Value,'''')=''''then '''' else isnull(ArithmeticOperator,'''')+isnull(Value,'''') end 
		+case when isnull(ComparisonValue,'''') <>'''' then '''' else'')'' end 
		from ccSmsConditions where SegmentId=@segmentId and ConditionId>@conditionId
		
		set @SubConditionId=0
		while exists(select * from ccSmsSubconditions where ConditionId=@conditionId and SubconditionId>@SubConditionId) 
		begin
		
			select top 1
			@LogicConector=LogicConector,
			@SubConditionId=SubconditionId,
			@SubConditionWhere=
			PrimaryField+LogicOperator
			+case when isnull(ComparisonValue,'''') <>'''' then ComparisonValue else''(''+ ComparisonField end 					
			+case when isnull(ComparisonValue,'''') <>'''' or  isnull(ArithmeticOperator,'''')='''' or isnull(Value,'''')='''' then '''' else isnull(ArithmeticOperator,'''')+isnull(Value,'''') end
			+case when isnull(ComparisonValue,'''') <>'''' then '''' else'')'' end 
			from ccSmsSubconditions where ConditionId=@conditionId and SubconditionId>@SubConditionId

			set @conditionWhere=@conditionWhere+'' ''+ @LogicConector+'' '' +@SubConditionWhere

			
		end
			
		insert into @conditionTable values(@conditionId,@conditionWhere,@DailyLimit,@WeeklyLimit,0)		
	end 
	-------------------------------- Termina las condiciones por segmentId --------------------------------
	update @segmentTable set status=1 where id=@segmentId
end
while exists(select * from @conditionTable where status=0) begin		
	select top 1 
	@conditionId=conditionId, @DailyLimit=DailyLimit, @WeeklyLimit=WeeklyLimit,	@conditionWhere=smsCondition
	from @conditionTable 
	where status=0
	
	set @subQuery= ''select A.id_credito, A.TDCT from SmsRemesasMuñozDay A with(nolock)
	left join ccSmsValidateRegistryWeek B on A.credito=B.registryClient and B.total<@WeeklyLimit and B.totaltoDay<@DailyLimit
	where  SegmentoMC in ('' + @segmentNames + '') AND RESULTADO_ID = 0 AND '' + @conditionWhere	
	print(@subQuery)
	insert into #SmsRemesasId
	EXEC sp_executesql @subQuery,@Params,@WeeklyLimit,@DailyLimit;
	update @conditionTable set status=1 where @conditionId=conditionId
end

--Actualizamos los ids que no coindiden
UPDATE rmd SET rmd.RESULTADO = ''CUENTA CON T. Celular para envio de sms'' , rmd.RESULTADO_ID = 6
FROM SmsRemesasMuñozDay rmd
INNER JOIN #SmsRemesasId rid on rid.TDCT = rmd.TDCT
WHERE RESULTADO_ID = 0;

--Actualizamos todo lo que no cumple
UPDATE rmd SET rmd.RESULTADO = ''NO CUMPLE CON REGLA DE CORTE'' , rmd.RESULTADO_ID = 2
FROM SmsRemesasMuñozDay rmd
INNER JOIN #SmsRemesasIdTemp rid on rid.TDCT = rmd.TDCT
WHERE RESULTADO_ID = 0;
	
if @action=12 begin
	declare @countValidate int,@nonValid int
	select @countValidate=count(1) from SmsRemesasMuñozDay A with(nolock)
	inner join #SmsRemesasIdTemp b on a.TDCT = b.TDCT where a.RESULTADO_ID = 6

	select @nonValid=count(1) from SmsRemesasMuñozDay A with(nolock)
	inner join #SmsRemesasIdTemp b on a.TDCT = b.TDCT where a.RESULTADO_ID <> 6

	INSERT INTO SmsSegmentsValidationResult(id_credito, credito, TELEFONOS1, TDCT, RESULTADO, RESULTADO_ID, validation_date)
	SELECT A.id_credito, A.credito, TELEFONOS1, A.TDCT, A.RESULTADO, A.RESULTADO_ID, GETDATE() FROM SmsRemesasMuñozDay A
	inner join #SmsRemesasIdTemp b on A.TDCT = b.TDCT

	select @countValidate as ValidRecords,@nonValid as InvalidRecords
end
else begin
	
	set @sql=''select ''+@columns+'',0 PhoneStatus,0 callout_id,credito as Record_id,convert(varchar(100),'''''''') as DataPhone, TDCT as call_Key1
	into TEMPO_''+convert(varchar(10),@camId)+''
	from SmsRemesasMuñozDay A with(nolock) where A.TDCT in(select TDCT from #SmsRemesasId)''
	print(@sql)
	exec(@sql)
end
drop table #SmsRemesasId
drop table #SmsRemesasIdTemp
drop table #functionalState
end
else if @action =14 begin 
	select MessageTemplate from ccSmsTemplate where TemplateId=@templateId
end

else if @action =15 begin --Obtener resultados de validación por segmentos

	DECLARE @counter int = 0
	DECLARE @ActualDay DATETIME = GETDATE();
	DECLARE @FirstDayMonth DATETIME = DATEADD(MONTH, DATEDIFF(MONTH, 0, @ActualDay),0)
	DECLARE @DayCounter DATETIME;
	DECLARE @WeekCount int = 0;

	WHILE @counter < DAY(@ActualDay)
	BEGIN
		SET @DayCounter =  DATEADD(DAY, @counter, @FirstDayMonth)
		IF DATEPART(WEEKDAY,@DayCounter) = 2
			SET @WeekCount = @WeekCount + 1
		print @DayCounter
		set @counter = @counter + 1
	END

	IF DATEPART(WEEKDAY, @FirstDayMonth) <> 2 BEGIN
		SET @WeekCount = @WeekCount + 1
	END

	declare @segments table(segmentName VARCHAR(10))

	insert into @segments
	select s.Name from dbo.fn_RIASplitDelimited(@segmentIds,'','') a
	inner join ccSmsSegments s on s.segmentId = a.value

	select	id_credito AS id_credit, credito AS credit, GETDATE() as snapshot_date, MESES_VENCIDOS as expired_month, SEG_CUENTA as seg_account,
			FILA as seg_row, LOCACION as [location], DIA_CORTE as cut_day, SegmentoMC as segment_mc, @WeekCount as [week], DATEPART(WEEKDAY, @ActualDay) week_day,
			TELEFONOS1 as phones1, RESULTADO as result, ISNULL(ESTADO_FUNCIONAL, '''') as functional_state, ISNULL(CORTE_REAL, '''')  as real_cut
	from SmsRemesasMuñozDay rmd
	inner join @segments s on rmd.SegmentoMC = s.segmentName;
	
end';
        EXEC (@sql);

		SET @process = 'KR134018 - Se actualiza job para eliminar los registros de más de 30 días de la tabla SmsSegmentsValidationResult';
        SET @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''CW Delete old records'') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N''CW Delete old records'', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Delete old records'', 
		@enabled=1, 
		@notify_level_eventlog=2,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''No description available.'', 
		@category_name=N''Nuxiba'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run sp'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0,  @subsystem=N''TSQL'', 
		@command=N''/***********************************************/
-- Delete Old Records New Version Febrero 2016 --
/***********************************************/
set nocount on

declare @idSqlCmd int
declare @sqlCmd nvarchar(max)
declare @days int

set @idSqlCmd = 0
set @sqlCmd  =''''''''
set @days = 30

create table #sqlCmdDeleteOldRecords(
idSqlCmd int identity primary key,
sqlCmd nvarchar(max) not null,
[status] int not null,
isReplicated bit not null
)

create table #ccoCallsOutSourceIds(
callout_id int not null primary key
)

insert into #ccoCallsOutSourceIds (callout_id)
select callout_id
from ccoCallsOutSource
where cal_fechadial < dateadd(dd, -@days, getdate())

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccBorrardasReciclaje'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccLogCampsAgentesDia'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table cclogInfo'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccUploadTemporal'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogReciclaje where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccPosicionCamps where Fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccPosicionEspecialidad where Fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAlog where operationDate < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRiaChat_log where fecha_chat < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIALogAgentesNotReady where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAWorkGroup_logDial_id where timestamp < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete xxclientehistorial where fechaAct < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccCallsIn where cal_Inicio < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete cccallsreject where cal_inicio < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesDia where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesDia_Dialog where fecha_Dialog < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesNotReady where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogLogin where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogtransfers where fechaFin < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccriachats where chatDate < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAWorkGroup_Calid where timestamp < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ivrcallsin where date < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ivroptions where date < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete SmsSegmentsValidationResult where validation_date < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

/******************************************************************/
/* Delete by date because rows in ccoLogDials > ccoCallsOutSource */
/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoLogDials where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete cchistoriallistanegra from cchistoriallistanegra as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoWorkingTable from ccoWorkingTable as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccocallbacks from ccocallbacks as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoCallsOut from ccoCallsOut as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoLogDials from ccoLogDials as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoCallsOutSource from ccoCallsOutSource as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

while (select count(*) from #sqlCmdDeleteOldRecords where [status] = 0 ) > 0
	begin
		set rowcount 1
			select @idSqlCmd = idSqlCmd, @sqlCmd = SqlCmd from #sqlCmdDeleteOldRecords where [status] = 0 order by idSqlCmd
		set rowcount 0

		exec(@sqlCmd)

		WAITFOR DELAY ''''00:00:01''''

		while(SELECT count(*)
				FROM sys.dm_exec_requests a
				INNER JOIN sys.dm_exec_connections b
				ON a.session_id = b.session_id
				INNER JOIN sys.dm_exec_sessions c
				ON c.session_id = a.session_id
				CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d
				WHERE a.session_id > 50
				AND a.session_id = @@SPID
				and d.text = @sqlCmd) > 0
			begin
				WAITFOR DELAY ''''00:00:01''''
			end

		update #sqlCmdDeleteOldRecords
		set [status] = 1
		where idSqlCmd = @idSqlCmd
	end

drop table #sqlCmdDeleteOldRecords
drop table #ccoCallsOutSourceIds'',
		@database_name=N''CCenterRia'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Tuesday, Thursday and Saturday at 3:00 am'', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=84, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
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
EndSave:';
        EXEC (@sql);

		------------------------------------------------------BEGIN MACL---------------------------------------------------------------------
 	
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
