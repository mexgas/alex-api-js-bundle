/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/04/28
Description: 

Database: CCenterRia
Required version: 121.41

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
SET @version = 122 --**********actualizar a 122 sin fix
SET @versionfix = 11
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF (@actualVersion = @version AND @actualVersionFix >= 11) OR (@actualVersion = @version-1 AND @actualVersionFix >= 41)
BEGIN
	BEGIN TRAN

	BEGIN TRY
	
	set @process = 'CW-3557 Error en totales de registros cargados'
	set @sql = '
	ALTER PROCEDURE [dbo].[ccsp_GalateaGetRecordsImportStatus]
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

		            SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked as regsNotLoaded, state, loadDate
		            FROM ccRIALoading riaLoad
		            JOIN ccSupervisorCam superCam ON riaLoad.cam_id = superCam.cam_id
					JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
		            WHERE 
					loadDate>=@today AND
					superCam.user_id = @userID
		            AND superCam.tipo = 1
					ORDER BY riaLoad.loadDate DESC

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
		                     telsLoaded, telsBlocked, telsNotLoaded
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
		          SET nocount off

'
	exec (@sql)
	set @process = 'CW-3610 Setting_ID 217 Información del certificado'
	    set @Sql= '
		IF not exists (SELECT * FROM ccSettings WHERE setting_id = 217)
		INSERT INTO ccSettings (setting_id, valor, descripcion,	Status,	Tipo,detalle,description,bLoadSettings,	validate)
		VALUES	(217, 
				''D:\Centerware\certs\nuxiba_pfx.pfx|e7451896fd98715c9e67f110351b5719'',
				''Parámetros del Certificado de seguridad (.PFX)'',	
				1,
				''X'',
				''Información del certificado de seguridad Ubicación|Contraseña cifrada'',
				''Security Certificate Information'',
				0,
				 ''.*'')
		'
	exec (@sql)

	set @process = 'CenterScript -- drop sp getACDCampaignList'
	set @sql = 'if exists (select * from sys.procedures where name = N''cs_GetACDCampaignList'')
    begin
        DROP PROCEDURE cs_GetACDCampaignList;
    end'
    exec (@sql)

    set @process = 'CenterScript -- create sp getACDCampaignList'
    set @sql = '
    	CREATE PROCEDURE [dbo].[cs_GetACDCampaignList] @action AS SMALLINT
AS
IF (@action = 1)
BEGIN
	SELECT cam_id AS [cam_id]
		,cam_descripcion AS [name]
	FROM ccCamps
	WHERE cam_activo = 1 and cam_id not in (select Cam_id from CW_CenterScript..Campaign )
		AND IDArea > 0
END

IF (@action = 2)
BEGIN
	SELECT inbound_id
		,descripcion AS [name]
	FROM ccInbound
	WHERE STATUS = 1 and Inbound_id not in (select Inbound_id from CW_CenterScript..ACD)
		AND IDArea > 0
END

IF (@action = 3)
BEGIN
	SELECT cam_id AS [cam_id]
		,cam_descripcion AS [name]
	FROM ccCamps
	WHERE cam_activo = 1 
		AND IDArea > 0
END

IF (@action = 4)
BEGIN
	SELECT inbound_id
		,descripcion AS [name]
	FROM ccInbound
	WHERE STATUS = 1 
		AND IDArea > 0
END

    ' 
    exec (@sql)
			
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
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
