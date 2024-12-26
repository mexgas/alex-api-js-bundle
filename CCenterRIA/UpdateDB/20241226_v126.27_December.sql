/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio Chagolla
Date: 2024/09/30
Description: Release 126.20241218.0.0
Database: CCenterRia
Required version: 126.6
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
SET @versionfix = 27
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

	------------------------------------------- BEGIN IC ----------------------------------------
	SET @process = 'K020042 delete sp ccsp_WhatsAppOutboundTemplates'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_WhatsAppOutboundTemplates'')
    BEGIN
        DROP PROCEDURE ccsp_WhatsAppOutboundTemplates;
    END
    '
	EXEC(@sql)

    SET @process = 'K020042 create sp ccsp_WhatsAppOutboundTemplates'
	SET @sql = '
CREATE PROCEDURE ccsp_WhatsAppOutboundTemplates
@Action SMALLINT, 
@TemplateName VARCHAR(500) = '''',
@isMeta int=0,
@ConversationId INT = 0
AS  
SET NOCOUNT ON;  
IF @Action = 0  -- Get all template information
BEGIN	
	SELECT TemplateName, LanguageCode, Type, Format, Body FROM ccWhatsAppOutboundTemplates WHERE TemplateName = @TemplateName
END
IF @Action = 1  -- Get template body 
BEGIN
	if @isMeta =0 begin
		SELECT Body FROM ccWhatsAppOutboundTemplates WHERE TemplateName = @TemplateName
	end
	else begin
		SELECT
			header AS Header
		   ,body AS Body
		   ,footer AS Footer
		   ,Status AS StatusMeta
		   ,buttons AS Buttons
		   ,headerLink AS HeaderLink
		FROM ccMetaWAOutboundTemplates
		WHERE TemplateName = @TemplateName 
	end
END
					
IF @Action = 2  -- Get category from ccWhatsAppGlobalIds
BEGIN
	SELECT UPPER(wagi.Category) AS Category
	FROM ccWhatsAppGlobalIds wagi
	INNER JOIN ccWhatsAppGlobalIdsRelationship wagir ON wagi.GlobalId = wagir.GlobalId
	WHERE wagir.ConversationId = @ConversationId AND wagir.ConversationType = 1;
END

SET NOCOUNT OFF 
    '
	EXEC(@sql)


    -------------------------------------------- END IC -----------------------------------------

	
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
