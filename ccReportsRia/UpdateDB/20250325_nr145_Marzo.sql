/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2025/03/28
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
SET @version = 145 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

    -------------------------------------------  BEGIN Ricardo Nunez LRSV  ----------------------------------------
	set @process = 'DELETE FROM ccWhatsOringCountry'
		set @sql='IF EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = ''ccWhatsOringCountry''
            AND COLUMN_NAME = ''CountryAbbreviation''
        )
        AND EXISTS (
            SELECT 1 FROM CCReportsRIA.dbo.ccWhatsOringCountry
        )
        BEGIN
            DELETE FROM CCReportsRIA.dbo.ccWhatsOringCountry;
        END'
		EXEC(@sql)


	set @process = 'INSERT VALUES TO COUNTRYABBREVIATION'
		set @sql='IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccWhatsOringCountry'' AND COLUMN_NAME = ''CountryAbbreviation'')
        BEGIN
			INSERT INTO CCReportsRIA.dbo.ccWhatsOringCountry
            SELECT * FROM CCenterRIA.dbo.ccWhatsOringCountry;
		END'
		EXEC(@sql)



    set @process = 'Facturación - Validación sp ccsp_GalateaWhastappBilling'
    set @sql='
    if exists (select * from sys.procedures where name = N''ccsp_GalateaWhastappBilling'')
    begin
        DROP PROCEDURE ccsp_GalateaWhastappBilling
    end'
    EXEC(@sql)

    SET @process = 'Facturación - Creación sp ccsp_GalateaWhastappBilling'
    SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaWhastappBilling] 
    @action SMALLINT,
    @DateFrom DATETIME = NULL,
    @DateTo DATETIME = NULL,
    @CompanyName VARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ip VARCHAR(16) = ''''
    DECLARE @ipSettings VARCHAR(50) = ''''

    SELECT @ipSettings = valor FROM ccSettings WHERE setting_id = 31
    SELECT @ip = value FROM dbo.fn_RIASplitDelimited(@ipSettings, ''|'') WHERE Id = 2

    IF @DateFrom IS NULL AND @DateTo IS NULL
    BEGIN
        SET @DateFrom = DATEADD(DAY, -1, CAST(GETDATE() AS DATETIME));
        SET @DateTo = DATEADD(SECOND, -1, DATEADD(DAY, 0, CAST(GETDATE() AS DATETIME)));
    END
    ELSE
    BEGIN
        SET @DateFrom = ISNULL(CONVERT(DATETIME, CONVERT(VARCHAR(10), @DateFrom, 120) + '' 00:00:00''), ''1900-01-01 00:00:00'');
        SET @DateTo = ISNULL(CONVERT(DATETIME, CONVERT(VARCHAR(10), @DateTo, 120) + '' 23:59:59''), ''9999-12-31 23:59:59'');
    END

    -- Crear tabla temporal completa
    IF OBJECT_ID(''tempdb..#Temp_Facturacion'') IS NOT NULL DROP TABLE #Temp_Facturacion;

    CREATE TABLE #Temp_Facturacion (
        Account VARCHAR(MAX),
        IPAddress VARCHAR(16),
        Service VARCHAR(50),
        Billed VARCHAR(10),
        Type VARCHAR(20),
        OriginCountry VARCHAR(10),
        OriginCountryCode VARCHAR(10),
        OriginNumber VARCHAR(50),
        TargetCountry VARCHAR(10),
        TargetCountryCode VARCHAR(10),
        TargetNumber VARCHAR(50),
        ConversationDate VARCHAR(30),
        ConversationTime VARCHAR(20),
        CReserved01 VARCHAR(100),
        CReserved02 VARCHAR(100),
        CReserved03 VARCHAR(100),
        CReserved04 VARCHAR(100),
        CReserved05 VARCHAR(100),
        CReserved06 VARCHAR(100),
        CReserved07 VARCHAR(100),
        BillingIDWhatsApp VARCHAR(100),
        TemplateCategory VARCHAR(100),
        TemplateName VARCHAR(200),
        PaymentCodeWA VARCHAR(50),
		WAReserved01 VARCHAR(100),
		WAReserved02 VARCHAR(100),
		WAReserved03 VARCHAR(100),
		WAReserved04 VARCHAR(100),
		WAReserved05 VARCHAR(100),
		WAReserved06 VARCHAR(100),
        ConversationIDSMS VARCHAR(100),
        NumberType VARCHAR(50),
        MessageCharacters VARCHAR(10),
        TargetCarrier VARCHAR(100),
		SMSReserved01 VARCHAR(100),
		SMSReserved02 VARCHAR(100),
		SMSReserved03 VARCHAR(100),
		SMSReserved04 VARCHAR(100),
		SMSReserved05 VARCHAR(100),
		SMSReserved06 VARCHAR(100),
        VirtualAgentID VARCHAR(100),
        ConversationID VARCHAR(100),
        Channel VARCHAR(50),
        ConversationDuration VARCHAR(20),
        Seconds VARCHAR(10),
        Minutes VARCHAR(10),
		VAReserved01 VARCHAR(100),
		VAReserved02 VARCHAR(100),
		VAReserved03 VARCHAR(100),
		VAReserved04 VARCHAR(100),
        CallID VARCHAR(100),
        Detection VARCHAR(100),
        DurationSeconds VARCHAR(10),
        DurationMinutes VARCHAR(10),
		VMReserved01 VARCHAR(100),
		VMReserved02 VARCHAR(100),
		VMReserved03 VARCHAR(100),
		VMReserved04 VARCHAR(100),
		VMReserved05 VARCHAR(100),
		VMReserved06 VARCHAR(100)
    );
	IF @action = 0
	BEGIN
		INSERT INTO #Temp_Facturacion (
			Account, IPAddress, Service, Billed, Type,
			OriginCountry, OriginCountryCode, OriginNumber,
			TargetCountry, TargetCountryCode, TargetNumber,
			ConversationDate, ConversationTime,
			CReserved01, CReserved02, CReserved03, CReserved04, CReserved05, CReserved06, CReserved07,
			BillingIDWhatsApp, TemplateCategory, TemplateName, PaymentCodeWA,
			WAReserved01, WAReserved02, WAReserved03, WAReserved04, WAReserved05, WAReserved06,
			ConversationIDSMS, NumberType, MessageCharacters, TargetCarrier,
			SMSReserved01, SMSReserved02, SMSReserved03, SMSReserved04, SMSReserved05, SMSReserved06,
			VirtualAgentID, ConversationID, Channel, ConversationDuration, Seconds, Minutes,
			VAReserved01, VAReserved02, VAReserved03, VAReserved04,
			CallID, Detection, DurationSeconds, DurationMinutes,
			VMReserved01, VMReserved02, VMReserved03, VMReserved04, VMReserved05, VMReserved06
		)
		SELECT 
			@CompanyName, ISNULL(@ip, ''''), ''WhatsApp'',
			ISNULL(CAST(IsBilled AS VARCHAR), ''0''),
			CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''inbound'' ELSE ''outbound'' END,
			ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 1), ''''),
			ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 0), ''''),
			ISNULL(AssociatedNumber, ''''),
			ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 1), ''''),
			ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 0), ''''),
			ISNULL(ClientNumber, ''''),
			CAST(CAST(FirstMessageDateFromAgent AS DATE) AS VARCHAR(MAX)),
			FORMAT(FirstMessageDateFromAgent, ''HH:mm:ss''),
			'''', '''', '''', '''', '''', '''', '''',
			ISNULL(GlobalId, NULL),
			ISNULL(wa.Category, ''''),
			ISNULL(mt.TemplateName, ''''),
			CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''Wa In'' ELSE ''Wa Out'' END,
			'''', '''', '''', '''', '''', '''',
			'''', '''', '''', '''',
			'''', '''', '''', '''', '''', '''',
			'''', '''', '''', '''', '''', '''',
			'''', '''', '''', '''',
			'''', '''', '''', '''', '''', '''',
			'''', '''', '''', ''''

		FROM ccWhatsAppGlobalIds wa
		LEFT JOIN ccoWhatsLogDials a ON a.ConversationId = wa.FirstMessageConversationIdFromAgent
		LEFT JOIN ccMetaWAOutboundTemplates mt ON mt.Id = a.TemplateId
		WHERE FirstMessageDateFromAgent BETWEEN @DateFrom AND @DateTo;

		SELECT * FROM #Temp_Facturacion ORDER BY ConversationDate;
	END

    -- Acción 1: WhatsApp
    IF @action = 1
    BEGIN
        INSERT INTO #Temp_Facturacion (
            Account, IPAddress, Service, Billed, Type,
            OriginCountry, OriginCountryCode, OriginNumber,
            TargetCountry, TargetCountryCode, TargetNumber,
            ConversationDate, ConversationTime,
            CReserved01, CReserved02, CReserved03, CReserved04, CReserved05, CReserved06, CReserved07,
            BillingIDWhatsApp, TemplateCategory, TemplateName, PaymentCodeWA,
			WAReserved01, WAReserved02, WAReserved03, WAReserved04, WAReserved05, WAReserved06
        )
        SELECT 
            @CompanyName,
            ISNULL(@ip, ''''),
            ''WhatsApp'',
            ISNULL(CAST(IsBilled AS VARCHAR), ''0''),
            CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''inbound'' ELSE ''outbound'' END,
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 0), ''''),
            ISNULL(AssociatedNumber, ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 0), ''''),
            ISNULL(ClientNumber, ''''),
            CAST(CAST(FirstMessageDateFromAgent AS DATE) AS VARCHAR(MAX)),
            FORMAT(FirstMessageDateFromAgent, ''HH:mm:ss''),
            '''', '''', '''', '''', '''', '''', '''',
            ISNULL(GlobalId, NULL),
            ISNULL(wa.Category, ''''),
            ISNULL(mt.TemplateName, ''''),
            CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''Wa In'' ELSE ''Wa Out'' END,
			'''', '''', '''', '''', '''', ''''
        FROM ccWhatsAppGlobalIds wa
        LEFT JOIN ccoWhatsLogDials a ON a.ConversationId = wa.FirstMessageConversationIdFromAgent
        LEFT JOIN ccMetaWAOutboundTemplates mt ON mt.Id = a.TemplateId
        WHERE FirstMessageDateFromAgent BETWEEN @DateFrom AND @DateTo;
    END

    -- Acción 2: SMS
    IF @action = 2
    BEGIN
        INSERT INTO #Temp_Facturacion (
            Account, IPAddress, Service, Billed, Type,
            OriginCountry, OriginCountryCode, OriginNumber,
            TargetCountry, TargetCountryCode, TargetNumber,
            ConversationDate, ConversationTime,
            CReserved01, CReserved02, CReserved03, CReserved04, CReserved05, CReserved06, CReserved07,
            ConversationIDSMS, NumberType, MessageCharacters, TargetCarrier
        )
        SELECT 
            @CompanyName,
            ISNULL(@ip, ''''),
            ''SMS'',
            ISNULL(CAST(IsBilled AS VARCHAR), ''0''),
            CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''inbound'' ELSE ''outbound'' END,
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 0), ''''),
            ISNULL(AssociatedNumber, ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 0), ''''),
            ISNULL(ClientNumber, ''''),
            CAST(CAST(FirstMessageDateFromAgent AS DATE) AS VARCHAR(MAX)),
            FORMAT(FirstMessageDateFromAgent, ''HH:mm:ss''),
            '''', '''', '''', '''', '''', '''', '''',
            '''', '''', '''', ''''
        FROM ccWhatsAppGlobalIds wa
        WHERE FirstMessageDateFromAgent BETWEEN @DateFrom AND @DateTo;
    END

    -- Acción 3: VA
    IF @action = 3
    BEGIN
        INSERT INTO #Temp_Facturacion (
            Account, IPAddress, Service, Billed, Type,
            OriginCountry, OriginCountryCode, OriginNumber,
            TargetCountry, TargetCountryCode, TargetNumber,
            ConversationDate, ConversationTime,
            CReserved01, CReserved02, CReserved03, CReserved04, CReserved05, CReserved06, CReserved07,
            VirtualAgentID, ConversationID, Channel,
            ConversationDuration, Seconds, Minutes
        )
        SELECT 
            @CompanyName,
            ISNULL(@ip, ''''),
            ''Virtual Agent'',
            ISNULL(CAST(IsBilled AS VARCHAR), ''0''),
            CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''inbound'' ELSE ''outbound'' END,
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 0), ''''),
            ISNULL(AssociatedNumber, ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 0), ''''),
            ISNULL(ClientNumber, ''''),
            CAST(CAST(FirstMessageDateFromAgent AS DATE) AS VARCHAR(MAX)),
            FORMAT(FirstMessageDateFromAgent, ''HH:mm:ss''),
            '''', '''', '''', '''', '''', '''', '''',
            '''', '''', '''', '''', '''', ''''
        FROM ccWhatsAppGlobalIds wa
        WHERE FirstMessageDateFromAgent BETWEEN @DateFrom AND @DateTo;
    END

    -- Acción 4: VM
    IF @action = 4
    BEGIN
        INSERT INTO #Temp_Facturacion (
            Account, IPAddress, Service, Billed, Type,
            OriginCountry, OriginCountryCode, OriginNumber,
            TargetCountry, TargetCountryCode, TargetNumber,
            ConversationDate, ConversationTime,
            CReserved01, CReserved02, CReserved03, CReserved04, CReserved05, CReserved06, CReserved07,
            CallID, Detection, DurationSeconds, DurationMinutes
        )
        SELECT 
            @CompanyName,
            ISNULL(@ip, ''''),
            ''VMR'',
            ISNULL(CAST(IsBilled AS VARCHAR), ''0''),
            CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''inbound'' ELSE ''outbound'' END,
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 0), ''''),
            ISNULL(AssociatedNumber, ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 0), ''''),
            ISNULL(ClientNumber, ''''),
            CAST(CAST(FirstMessageDateFromAgent AS DATE) AS VARCHAR(MAX)),
            FORMAT(FirstMessageDateFromAgent, ''HH:mm:ss''),
            '''', '''', '''', '''', '''', '''', '''',
            '''', '''', '''', ''''
        FROM ccWhatsAppGlobalIds wa
        WHERE FirstMessageDateFromAgent BETWEEN @DateFrom AND @DateTo;
    END

    ---------------------------
    -- Mostrar columnas por acción
    ---------------------------
    IF @action = 1
    BEGIN
        SELECT Account, IPAddress, Service, Billed, Type,
               OriginCountry, OriginCountryCode, OriginNumber,
               TargetCountry, TargetCountryCode, TargetNumber,
               ConversationDate, ConversationTime,
               CReserved01, CReserved02, CReserved03, CReserved04,
               CReserved05, CReserved06, CReserved07,
               BillingIDWhatsApp, TemplateCategory, TemplateName, PaymentCodeWA,
			   WAReserved01, WAReserved02, WAReserved03, WAReserved04, WAReserved05, WAReserved06
        FROM #Temp_Facturacion
        ORDER BY ConversationDate;
    END
    ELSE IF @action = 2
    BEGIN
        SELECT Account, IPAddress, Service, Billed, Type,
               OriginCountry, OriginCountryCode, OriginNumber,
               TargetCountry, TargetCountryCode, TargetNumber,
               ConversationDate, ConversationTime,
               CReserved01, CReserved02, CReserved03, CReserved04,
               CReserved05, CReserved06, CReserved07,
               ConversationIDSMS, NumberType, MessageCharacters, TargetCarrier,
			   SMSReserved01, SMSReserved02, SMSReserved03, SMSReserved04, SMSReserved05, SMSReserved06
        FROM #Temp_Facturacion
        ORDER BY ConversationDate;
    END
    ELSE IF @action = 3
    BEGIN
        SELECT Account, IPAddress, Service, Billed, Type,
               OriginCountry, OriginCountryCode, OriginNumber,
               TargetCountry, TargetCountryCode, TargetNumber,
               ConversationDate, ConversationTime,
               CReserved01, CReserved02, CReserved03, CReserved04,
               CReserved05, CReserved06, CReserved07,
               VirtualAgentID, ConversationID, Channel,
               ConversationDuration, Seconds, Minutes,
			   VAReserved01, VAReserved02, VAReserved03, VAReserved04
        FROM #Temp_Facturacion
        ORDER BY ConversationDate;
    END
    ELSE IF @action = 4
    BEGIN
        SELECT Account, IPAddress, Service, Billed, Type,
               OriginCountry, OriginCountryCode, OriginNumber,
               TargetCountry, TargetCountryCode, TargetNumber,
               ConversationDate, ConversationTime,
               CReserved01, CReserved02, CReserved03, CReserved04,
               CReserved05, CReserved06, CReserved07,
               CallID, Detection, DurationSeconds, DurationMinutes,
			   VMReserved01, VMReserved02, VMReserved03, VMReserved04, VMReserved05, VMReserved06
        FROM #Temp_Facturacion
        ORDER BY ConversationDate;
    END

    DROP TABLE #Temp_Facturacion;
END;
'
    EXEC(@sql)
	
    -------------------------------------------  END Ricardo Nunez LRSV  ----------------------------------------

    SET @process = ''
    SET @sql = ''
    EXEC(@sql)
    -------------------------------------------------------------------------------------------------------------

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
