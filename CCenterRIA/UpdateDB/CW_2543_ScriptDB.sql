/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Sonia
		
Date: 2019/04/16
Description: 

Database: CCenterRia
Required version: 121.34

Se agrega la tarea
CW-SETTNGS

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
SET @versionfix = 35

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 34
BEGIN
	BEGIN TRAN
	BEGIN TRY
		
			EXEC (@Sql)

		-- *********************** START  CW-2543 Enmascaramiento y plan de marcación en llamadas manuales *********************** ---

		SET @process = 'CW-2543 Insert setting 213'
		SET @Sql = 'IF NOT EXISTS (SELECT * FROM ccSettings WHERE setting_id = 213)
BEGIN
	INSERT INTO ccSettings (setting_id, valor, descripcion, STATUS, Tipo, detalle, description, bLoadSettings, validate)
	VALUES (213, ''0'', ''Marcar números a 10 dígitos al utilizar un ANI local predeterminado.'', 1, ''X'', ''0 - Marcacion normal / 1 - Marcacion de ANI local a 10 digitos'', ''Set dialing format according to custom local ANI numbers.'', 0, ''^[0-1]$'')
END'
		EXEC (@Sql)

		SET @process = 'CW-2543 '
		SET @Sql = 'IF NOT EXISTS (select * from sys.objects where object_id = OBJECT_ID(N'[dbo].[fGetCldMexico]')
BEGIN
CREATE FUNCTION [dbo].[fGetCldMexico] (@tel VARCHAR(32))
RETURNS VARCHAR(32) AS
BEGIN

DECLARE @lon TINYINT
DECLARE @ld VARCHAR(7)

	SELECT @lon = len(@tel)

	IF @lon < 10
		BEGIN
			RETURN ''E_'' + @tel
		END

	SELECT @tel = right(@tel, 10)
	SELECT @lon = len(@tel)

		IF @lon = 10
		BEGIN
			IF exists (SELECT TOP 1 area FROM ccEstadosAni WHERE area = left(@tel, 3)) ----tabla donde llena el ani
			BEGIN
				SELECT @ld = left(@tel, 3)
			END
			ELSE IF exists (SELECT TOP 1 area FROM ccEstadosAni WHERE area = left(@tel, 2))
			BEGIN
				SELECT @ld = left(@tel, 2)
			END
			ELSE
				RETURN ''E_'' + @tel
		END
RETURN @ld
END
END'
		EXEC (@Sql)

				

		-- *********************** END  CW-2543 Enmascaramiento y plan de marcación en llamadas manuales *********************** ---

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
