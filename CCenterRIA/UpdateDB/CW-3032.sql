/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 


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
