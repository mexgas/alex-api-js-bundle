/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCReportsRIA
Required version: 128

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
SET @version = 144 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

    -------------------------------------------  BEGIN Ricardo Nunez LRSV  ----------------------------------------

    set @process = 'Facturación - Validación funcion GetCountryDetailWhatsApp'
    set @sql='
    if exists (select * from sys.objects where object_id = OBJECT_ID(N''GetCountryDetailWhatsApp'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
    begin
        drop function GetCountryDetailWhatsApp
    end'
    EXEC(@sql)

    set @process = 'Facturación - Creación funcion GetCountryDetailWhatsApp'
    set @sql='
    CREATE FUNCTION [dbo].[GetCountryDetailWhatsApp](
        @phone VARCHAR(50),
        @flag INT -- 0 para CodeCountry, 1 para CountryAbbreviation
        )
        RETURNS VARCHAR(255)
        AS  
        BEGIN
            DECLARE @result VARCHAR(255);

            SELECT TOP 1 
                @result = CASE
                    WHEN @flag = 0 THEN CAST(CodeCountry AS VARCHAR(50))
                    WHEN @flag = 1 THEN CountryAbbreviation
                END
            FROM ccWhatsOringCountry
            WHERE LEFT(@phone, LEN(CodeCountry)) = CodeCountry
            ORDER BY LEN(CodeCountry) DESC;

            RETURN @result;
        END;'
    EXEC(@sql)

    set @process = 'Facturación - Validación sp ccsp_GalateaWhastappBilling'
    set @sql='
    if exists (select * from sys.procedures where name = N''ccsp_WAOUTGetNewJobs'')
    begin
        DROP PROCEDURE ccsp_WAOUTGetNewJobs
    end'
    EXEC(@sql)

    set @process = 'Facturación - Creación sp ccsp_GalateaWhastappBilling'
    set @sql='
    CREATE PROCEDURE [dbo].[ccsp_GalateaWhastappBilling]
        @DateFrom DATETIME = NULL,
        @DateTo DATETIME = NULL,
        @CompanyName VARCHAR(MAX) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;

        -- Si DateFrom y DateTo son NULL, establecer rango para el día anterior
        IF @DateFrom IS NULL AND @DateTo IS NULL
        BEGIN
            SET @DateFrom = DATEADD(DAY, -1, CAST(GETDATE() AS DATETIME)); -- Inicio del día anterior
            SET @DateTo = DATEADD(SECOND, -1, DATEADD(DAY, 0, CAST(GETDATE() AS DATETIME))); -- Fin del día anterior
        END
        ELSE
        BEGIN
            -- Ajustar DateFrom y DateTo al inicio y final del día respectivamente
            SET @DateFrom = ISNULL(CONVERT(DATETIME, CONVERT(VARCHAR(10), @DateFrom, 120) + '' 00:00:00''), ''1900-01-01 00:00:00'');
            SET @DateTo = ISNULL(CONVERT(DATETIME, CONVERT(VARCHAR(10), @DateTo, 120) + '' 23:59:59''), ''9999-12-31 23:59:59'');
        END

        IF OBJECT_ID(''tempdb..#Temp_Facturacion'') IS NOT NULL DROP TABLE #Temp_Facturacion

        -- Crear la tabla temporal con valores predeterminados
        SELECT 
            @CompanyName AS ClientAccount, -- Insertar el parámetro en la columna
            ISNULL((SELECT valor FROM ccSettings WHERE setting_id = 7), '''') AS ClientIP,
            ''WhatsApp'' AS Provider,
            ISNULL(CAST(IsBilled AS VARCHAR), ''0'') AS IsBilled,
            CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''inbound'' ELSE ''outbound'' END AS Direction,
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 1), '''') AS CountryFrom, -- Abreviatura del país
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 0), '''') AS CountryCodeFrom, -- Código de país
            ISNULL(AssociatedNumber, '''') AS ClientNumberFrom,
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 1), '''') AS CountryTo,       -- Abreviatura del país
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 0), '''') AS CountryCodeTo,       -- Código de país
            ISNULL(ClientNumber, '''') AS ClientNumberTo,
            CAST(CAST(FirstMessageDateFromAgent AS DATE)AS VARCHAR(MAX)) AS ConversationDate, -- Mostrar solo la fecha
            FORMAT(FirstMessageDateFromAgent, ''HH:mm:ss'') AS ConversationTime, -- Hora completa en formato HH:MM:SS
            ISNULL(NULL, '''') AS CReserved01,
            ISNULL(NULL, '''') AS CReserved02,
            ISNULL(NULL, '''') AS CReserved03,
            ISNULL(NULL, '''') AS CReserved04,
            ISNULL(GlobalId, NULL) AS GlobalId,
            ISNULL(wa.Category, '''') AS TemplateType,
            ISNULL(mt.TemplateName, '''') AS TemplateName, -- Relacionar con ccMetaWAOutboundTemplates
            CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''Wa In'' ELSE ''Wa Out'' END AS PaymentCodeWA, -- Nueva columna
            ISNULL(NULL, '''') AS WAReserved01,
            ISNULL(NULL, '''') AS WAReserved02,
            ISNULL(NULL, '''') AS WAReserved03,
            ISNULL(NULL, '''') AS WAReserved04,
            ISNULL(NULL, '''') AS WAReserved05,
            ISNULL(NULL, '''') AS WAReserved06,
            ISNULL(NULL, '''') AS WAReserved07,
            ISNULL(NULL, 0) AS SMSConversationID,
            ISNULL(NULL, '''') AS NumberType,
            ISNULL(NULL, 0) AS MessageLength,
            ISNULL(NULL, '''') AS TelephoneCompany,
            ISNULL(NULL, '''') AS SMSReserved01,
            ISNULL(NULL, '''') AS SMSReserved02,
            ISNULL(NULL, '''') AS SMSReserved03,
            ISNULL(NULL, '''') AS SMSReserved04,
            ISNULL(NULL, '''') AS SMSReserved05,
            ISNULL(NULL, '''') AS SMSReserved06,
            ISNULL(NULL,0) AS VirtualAgentID,
            ISNULL(NULL, 0) AS CWConversationID,
            ISNULL(NULL, '''') AS InteractionType,
            ISNULL(NULL, '''') AS InteractionTime,
            ISNULL(NULL, 0) AS TokenQuantity,
            ISNULL(NULL, '''') AS VAReserved01,
            ISNULL(NULL, '''') AS VAReserved02,
            ISNULL(NULL, '''') AS VAReserved03,
            ISNULL(NULL, '''') AS VAReserved04,
            ISNULL(NULL, '''') AS VAReserved05,
            ISNULL(NULL, 0) AS EmailConversationID,
            ISNULL(NULL, '''') AS SenderDirection,
            ISNULL(NULL, '''') AS RecipientDirection,
            ISNULL(NULL, '''') AS ShippingSize,
            ISNULL(NULL, '''') AS EReserved01,
            ISNULL(NULL, '''') AS EReserved02,
            ISNULL(NULL, '''') AS EReserved03,
            ISNULL(NULL, '''') AS EReserved04,
            ISNULL(NULL, '''') AS EReserved05,
            ISNULL(NULL, '''') AS EReserved06
        INTO #Temp_Facturacion
        FROM ccWhatsAppGlobalIds wa
        INNER JOIN ccoWhatsLogDials a ON a.ConversationId = wa.FirstMessageConversationIdFromAgent
        INNER JOIN ccMetaWAOutboundTemplates mt ON mt.Id = a.TemplateId -- Obtener TemplateName
        WHERE 
            FirstMessageDateFromAgent BETWEEN @DateFrom AND @DateTo;

        -- Mostrar los resultados ordenados por ConversationDate
        SELECT * 
        FROM #Temp_Facturacion
        ORDER BY ConversationDate ASC;

        -- Limpiar la tabla temporal
        IF OBJECT_ID(''tempdb..#Temp_Facturacion'') IS NOT NULL DROP TABLE #Temp_Facturacion
    END;'
    EXEC(@sql)
   
   -------------------------------------------  END Ricardo Nunez LRSV  ----------------------------------------
	
	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
