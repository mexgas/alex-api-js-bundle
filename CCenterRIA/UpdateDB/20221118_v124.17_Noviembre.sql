/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/02/15
Description: Merge con los cambios de sorteos

Database: CCenterRia
Required version: 123.27

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
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 15
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

	------------------------------------------------------------- Max Times Discard ---------------------------------------------------

		SET @process = 'Add column timesDiscard in workingTable'
		SET @sql = 'if not exists (select * from sys.columns where name = N''timesDiscard'' and Object_ID = Object_ID(N''ccoWorkingTable''))
		begin
			ALTER TABLE ccoWorkingTable ADD timesDiscard tinyint not null DEFAULT(0)
		end';
		EXEC(@sql);

		SET @process = 'Add module for preview log'
		SET @sql = 'IF EXISTS (SELECT * FROM sys.tables WHERE name = N''ccRIALog_Module'')
					BEGIN
						IF NOT EXISTS (SELECT * FROM ccRIALog_Module WHERE module_id = 63)
						BEGIN
							INSERT INTO ccRIALog_Module(module_id,descripcion)
							VALUES (63, ''CONFIGURACIÓN DE CAMPAÑA (VISTA PREVIA)|CAMPAIGN CONFIGURATION (PREVIEW)|CONFIGURAÇÃO DE CAMPANHA (VISUALIZAÇÃO)'')
						END
					END';
		EXEC(@sql);

		SET @process = 'Add operation for preview log'
		SET @sql = 'IF EXISTS (SELECT * FROM sys.tables WHERE name = N''ccRIALog_Operation'')
					BEGIN
						IF NOT EXISTS (SELECT * FROM ccRIALog_Operation WHERE operationType = 198)
						BEGIN
							INSERT INTO ccRIALog_Operation(operationType,descripcion)
							VALUES (198,''EDITAR AJUSTE|EDIT SETTING'')
						END
					END';
		EXEC(@sql);

		SET @process = 'Add value for preview log'
		SET @sql = 'IF EXISTS (SELECT * FROM sys.tables WHERE name = N''valueRecord'')
					BEGIN
						IF NOT EXISTS (SELECT * FROM valueRecord WHERE valueT= ''UNASSIGNMENT ATTEMPTS'')
						BEGIN
							INSERT INTO valueRecord(valueT,es,en,pt)
							VALUES (''UNASSIGNMENT ATTEMPTS'',''NÚMERO MÁXIMO DE DESASIGNACIONES'',''MAXIMUM UNASSIGNMENT ATTEMPTS'',''LIMITE DE CANCELAMENTO DE ATRIBUIÇÃO'')
						END
					END';
		EXEC(@sql);

		SET @process = 'Add relation between preview module and preview operation'
		SET @sql = 'IF EXISTS (SELECT * FROM sys.tables WHERE name = N''ccRIALog_Cat_Relation'')
					BEGIN
						IF NOT EXISTS (SELECT * FROM ccRIALog_Cat_Relation WHERE module_id=63 AND operationType=198)
						BEGIN
							INSERT INTO ccRIALog_Cat_Relation(module_id,operationType)
							VALUES (63,198)
						END
					END';
		EXEC(@sql);

		SET @process = ''
		SET @sql = '';
		EXEC(@sql);


		----------------------------------------------------------------------------------------------------------------

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

