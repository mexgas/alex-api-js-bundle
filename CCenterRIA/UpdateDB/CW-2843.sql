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
CW-2831
CW-2645 
CW-2556
CW-2543

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
SET @versionfix = 36

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 35
BEGIN
	BEGIN TRAN
	BEGIN TRY
					
		SET @process = 'CW-2843 Alter ccsp_ExtAppsCamList'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_ExtAppsCamList] @action SMALLINT, @area INT = 0
AS
SET NOCOUNT ON

IF @action = 1
BEGIN
	IF @area = 0
		SELECT a1.inbound_id, descripcion, a1.STATUS
		FROM ccinbound a1
		JOIN ccRIAinboundGraph a2 ON (a1.inbound_id = a2.inbound_id)
		JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
		WHERE a3.type_id = 1
		ORDER BY descripcion
	ELSE
		SELECT DISTINCT a1.inbound_id, descripcion, a1.STATUS
		FROM ccinbound a1
		JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
		JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
		WHERE a3.type_id = 1 AND (@area IS NULL OR IDArea = @area)
		ORDER BY descripcion

	RETURN (0)
END

IF @action = 2
BEGIN
	IF @area = 0
		SELECT a1.cam_id, cam_descripcion, cam_activo
		FROM ccCamps a1
		JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
		JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
		WHERE a3.type_id = 1
		ORDER BY cam_descripcion
	ELSE
		SELECT DISTINCT a1.cam_id, cam_descripcion, cam_activo
		FROM ccCamps a1
		JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
		JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
		WHERE a3.type_id = 1 AND (@area IS NULL OR IDArea = @area)
		ORDER BY cam_descripcion

	RETURN (0)
END

SET NOCOUNT OFF'
		EXEC (@Sql)
		
		
		-- *********************** END 121.03-6_20190521 *********************** ---

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
