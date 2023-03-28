/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 8
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci�n para cuando pasamos a una nueva versi�n LTS
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
		-------------------------------------------- BEGIN IVAN K020099 OUTBOUND TEMPLATES ------------------------------
		SET @process = 'IM-K020099 Create reference table for languages (ccWhatsAppOutboundTemplateLanguages)'
		SET @sql = 'IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = N''ccWhatsAppOutboundTemplateLanguages'')
					BEGIN
						CREATE TABLE ccWhatsAppOutboundTemplateLanguages (
							LanguageId INT NOT NULL,
							Language varchar(100) NOT NULL,
							LanguageCode varchar(50)NOT NULL
							PRIMARY KEY (LanguageId)
						);
					END'
		EXEC(@sql)

		SET @process = 'IM-K020099 Create table for templates (ccWhatsAppOutboundTemplates)'
		SET @sql = 'IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = N''ccWhatsAppOutboundTemplates'')
					BEGIN
						CREATE TABLE ccWhatsAppOutboundTemplates (
							TemplateId INT NOT NULL,
							Category VARCHAR(25) NOT NULL,
							TableName VARCHAR(500),
							LanguageId INT,
							State BIT,
							AsociatedNumber VARCHAR(30)
							PRIMARY KEY (TemplateId)
						);
					END'
		EXEC(@sql)

		SET @process = 'IM-K020099'
		SET @sql = ''
		EXEC(@sql)

		-------------------------------------------- END IVAN K020099 OUTBOUND TEMPLATES   ------------------------------
		
----------------------------------------------------------------------------------------------------------------------------
		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
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
