/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2020/01/06
Description: 

Database: CCenterRia
Required version: 122.12

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
SET @versionfix = 13
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

		set @process = 'CW-3764 - Actualizar orden de marcacion'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAAdmPrioridadTelefonos]
  @cam_id int,
  @prioridad varchar(8),
  @callbacks bit = 0,
  @Type tinyint
AS


IF @Type = 3
    BEGIN
        INSERT INTO ccCampsPrioridadTel
        VALUES
        (@cam_id, 
         ''12345NNN''
        )
END
IF @Type = 2
    BEGIN
        IF NOT EXISTS
        (
            SELECT *
            FROM ccCampsPrioridadTel
            WHERE cam_id = @cam_id
        )
            BEGIN
                INSERT INTO ccCampsPrioridadTel
                VALUES
                (@cam_id, 
                 ''12345NNN''
                )
        END
        UPDATE ccCampsPrioridadTel
          SET 
              prioridad = @prioridad
        WHERE cam_id = @cam_id
        IF @callbacks = 1
            BEGIN
                --Ahora cambia todos los registros en ccCampsPrioridadTel.  Solo nuevos
                UPDATE ccCampsPrioridadTel
                  SET 
                      Prioridad = @prioridad
                WHERE cam_id = @cam_id
                      AND cam_id IN
                (
                    SELECT cam_id
                    FROM ccoWorkingTable
                    WHERE cam_id = @cam_id
                          AND cal_status = 0
                )
        END
END
IF @Type = 1
    BEGIN
        SELECT ccCamps.cam_id, 
               Prioridad
        FROM ccCamps, 
             ccCampsPrioridadTel
        WHERE ccCamps.cam_id = @cam_id
              AND ccCampsPrioridadTel.cam_id = @cam_id
END'
		EXEC(@sql)

			
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
