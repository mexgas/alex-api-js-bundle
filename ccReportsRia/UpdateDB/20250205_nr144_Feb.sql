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
	set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
		set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
			begin
			DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
			end'
		EXEC(@sql)

	SET @process = 'Facturacion - Columna CountryAbbreviation en ccWhatsOringCountry'
        SET @sql = 'IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccWhatsOringCountry'' AND COLUMN_NAME = ''CountryAbbreviation'')
		BEGIN
			ALTER TABLE ccWhatsOringCountry
			ADD CountryAbbreviation VARCHAR(2) NULL;
		END'
        EXEC(@sql)


    SET @process = 'CREATE TABLE [dbo].[ccCamps_consulta] Reports'
        SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''ccCamps_consulta'') AND type in (N''U''))
BEGIN
    CREATE TABLE [dbo].[ccCamps_consulta](
    [cam_id] [smallint] NOT NULL,
    [cli_id] [int] NOT NULL,
    [cam_descripcion] [varchar](40) NOT NULL,
    [cam_activo] [smallint] NOT NULL,
    [cam_ModoManual] [tinyint] NOT NULL,
    [cam_modpredictivo] [tinyint] NOT NULL,
    [cam_TipoJobs] [tinyint] NOT NULL,
    [cam_tNoContesta] [tinyint] NOT NULL,
    [cam_SortColumns] [tinyint] NOT NULL,
    [cam_ocupado] [tinyint] NOT NULL,
    [cam_nocontesto] [tinyint] NOT NULL,
    [cam_graba] [tinyint] NOT NULL,
    [cam_fax] [tinyint] NOT NULL,
    [cam_callratio] [tinyint] NOT NULL,
    [cam_inter_ocupado] [smallint] NOT NULL,
    [cam_inter_nocontesto] [smallint] NOT NULL,
    [cam_inter_graba] [smallint] NOT NULL,
    [cam_inter_fax] [smallint] NOT NULL,
    [cam_NoInt_ocupado] [tinyint] NOT NULL,
    [cam_NoInt_nocontesto] [tinyint] NOT NULL,
    [cam_NoInt_graba] [tinyint] NOT NULL,
    [cam_NoInt_fax] [tinyint] NOT NULL,
    [cam_procesando] [bit] NOT NULL,
    [cam_dsn] [varchar](10) NOT NULL,
    [cam_sql] [varchar](10) NOT NULL,
    [cam_tnotas] [smallint] NOT NULL,
    [cam_tDialAfterWU] [smallint] NOT NULL,
    [cam_tDialAfterDLG] [smallint] NOT NULL,
    [cam_fDialOnWU] [tinyint] NOT NULL,
    [cam_fDialOnDLG] [tinyint] NOT NULL,
    [cam_tDialBeforeWU] [smallint] NOT NULL,
    [cam_tDialBeforeReady] [smallint] NOT NULL,
    [cam_bValidaTel] [tinyint] NOT NULL,
    [cam_bNew] [tinyint] NULL,
    [cam_ShowCalifWnd] [bit] NOT NULL,
    [cam_StartTimerOnHangUp] [bit] NOT NULL,
    [cam_fCreate] [smalldatetime] NOT NULL,
    [cam_MaxDlrXage] [decimal](3, 1) NULL,
    [ani] [varchar](15) NOT NULL,
    [IDArea] [smallint] NULL,
    [EditableCallKey] [bit] NOT NULL,
    [iTipoDial] [tinyint] NOT NULL,
    [detectAnswerMachine] [smallint] NOT NULL,
    [detectVoiceMail] [tinyint] NOT NULL,
    [compliance] [tinyint] NOT NULL,
    [surveyCamId] [int] NULL    
) 
END
'
        EXEC(@sql)

	set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
			begin
			ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
			end'
	EXEC(@sql)


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
    if exists (select * from sys.procedures where name = N''ccsp_GalateaWhastappBilling'')
    begin
        DROP PROCEDURE ccsp_GalateaWhastappBilling
    end'
    EXEC(@sql)

    set @process = 'Facturación - Creación sp ccsp_GalateaWhastappBilling'
    set @sql='CREATE PROCEDURE [dbo].[ccsp_GalateaWhastappBilling] 
    @DateFrom DATETIME = NULL,
    @DateTo DATETIME = NULL,
    @CompanyName VARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

	declare @ip varchar(16) = ''''
	declare @ipSettings varchar(50) = ''''

	select @ipSettings = valor from ccSettings where setting_id = 31


	select @ip = value from dbo.fn_RIASplitDelimited(@ipSettings, ''|'') where Id = 2

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
        @CompanyName AS Account, -- Insertar el parámetro en la columna
        ISNULL(@ip, '''') AS IPAddress,
        ''WhatsApp'' AS Service,
		ISNULL(CAST(IsBilled AS VARCHAR), ''0'') AS Billed, --rodrigo
        CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''inbound'' ELSE ''outbound'' END AS Type,
        ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 1), '''') AS OriginCountry, -- Abreviatura del país
        ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 0), '''') AS OriginCountryCode, -- Código de país
        ISNULL(AssociatedNumber, '''') AS OriginNumber,
        ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 1), '''') AS TargetCountry,       -- Abreviatura del país
        ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 0), '''') AS TargetCountryCode,       -- Código de país
        ISNULL(ClientNumber, '''') AS TargetNumber,
        CAST(CAST(FirstMessageDateFromAgent AS DATE)AS VARCHAR(MAX)) AS ConversationDate, -- Mostrar solo la fecha
        FORMAT(FirstMessageDateFromAgent, ''HH:mm:ss'') AS ConversationTime, -- Hora completa en formato HH:MM:SS
        ISNULL(NULL, '''') AS CReserved01,
        ISNULL(NULL, '''') AS CReserved02,
        ISNULL(NULL, '''') AS CReserved03,
        ISNULL(NULL, '''') AS CReserved04,
		ISNULL(NULL, '''') AS CReserved05,
        ISNULL(NULL, '''') AS CReserved06,
        ISNULL(NULL, '''') AS CReserved07,
        ISNULL(GlobalId, NULL) AS BillingIDWhatsApp,
        ISNULL(wa.Category, '''') AS TemplateCategory,
        ISNULL(mt.TemplateName, '''') AS TemplateName, -- Relacionar con ccMetaWAOutboundTemplates
        CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''Wa In'' ELSE ''Wa Out'' END AS PaymentCodeWA, -- Nueva columna
        ISNULL(NULL, '''') AS WAReserved01,
        ISNULL(NULL, '''') AS WAReserved02,
        ISNULL(NULL, '''') AS WAReserved03,
        ISNULL(NULL, '''') AS WAReserved04,
        ISNULL(NULL, '''') AS WAReserved05,
        ISNULL(NULL, '''') AS WAReserved06,
        ISNULL(NULL, '''') AS ConversationIDSMS,
        ISNULL(NULL, '''') AS NumberType,
        ISNULL(NULL, '''') AS MessageCharacters,
        ISNULL(NULL, '''') AS TargetCarrier,
        ISNULL(NULL, '''') AS SMSReserved01,
        ISNULL(NULL, '''') AS SMSReserved02,
        ISNULL(NULL, '''') AS SMSReserved03,
        ISNULL(NULL, '''') AS SMSReserved04,
        ISNULL(NULL, '''') AS SMSReserved05,
        ISNULL(NULL, '''') AS SMSReserved06,
        ISNULL(NULL, '''') AS VirtualAgentID,
        ISNULL(NULL, '''') AS ConversationID,
        ISNULL(NULL, '''') AS Channel,
        ISNULL(NULL, '''') AS ConversationDuration,
        ISNULL(NULL, '''') AS NumberOfTokens,
        ISNULL(NULL, '''') AS Seconds,
        ISNULL(NULL, '''') AS Minutes,
        ISNULL(NULL, '''') AS VAReserved01,
        ISNULL(NULL, '''') AS VAReserved02,
        ISNULL(NULL, '''') AS VAReserved03,
        ISNULL(NULL, '''') AS ConversationIDEmail,
        ISNULL(NULL, '''') AS FromAddress,
        ISNULL(NULL, '''') AS ToAddress,
        ISNULL(NULL, '''') AS EmailSize,
        ISNULL(NULL, '''') AS PaymentCodeEmail,
        ISNULL(NULL, '''') AS EReserved01,
        ISNULL(NULL, '''') AS EReserved02,
        ISNULL(NULL, '''') AS EReserved03,
        ISNULL(NULL, '''') AS EReserved04,
        ISNULL(NULL, '''') AS EReserved05
    INTO #Temp_Facturacion
    FROM ccWhatsAppGlobalIds wa--select * from ccMetaWAOutboundTemplates
    LEFT JOIN ccoWhatsLogDials a ON a.ConversationId = wa.FirstMessageConversationIdFromAgent
    LEFT JOIN ccMetaWAOutboundTemplates mt ON mt.Id = a.TemplateId -- Obtener TemplateName
    WHERE 
        FirstMessageDateFromAgent BETWEEN @DateFrom AND @DateTo;

    -- Mostrar los resultados ordenados por ConversationDate
    SELECT * 
    FROM #Temp_Facturacion
    ORDER BY ConversationDate ASC;

    -- Limpiar la tabla temporal
    IF OBJECT_ID(''tempdb..#Temp_Facturacion'') IS NOT NULL DROP TABLE #Temp_Facturacion
END;

'
    EXEC(@sql)
   
   -------------------------------------------  END Ricardo Nunez LRSV  ----------------------------------------
   -------------------------------------------  BEGIN Hector Chavez  -------------------------------------------
SET @process = 'KR1170000 Create table RepAgentTimeShift'
    SET @sql = ' IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''RepAgentTimeShift'' )
                 BEGIN
                   CREATE TABLE [dbo].[RepAgentTimeShift](
                        [userId] [int] NOT NULL,
                        [userName] [varchar](255) NOT NULL,
                        [fullName] [varchar](40) NOT NULL,
                        [date] [datetime] NOT NULL,
                        [floginTime] [datetime] NOT NULL,
                        [flogoutTime] [datetime] NOT NULL,
                        [statusAgente] [varchar](255) NOT NULL,
                        [areaName] [varchar](255) NOT NULL,
                        [tDialogo] [int] NOT NULL,
                        [tManualAgent] [int] NOT NULL,
                        [tPredictivo] [int] NOT NULL,
                        [tIn] [int] NOT NULL,
                        [tWAIn] [int] NOT NULL,
                        [tWAOut] [int] NOT NULL,
                        [tTransferRecivied] [int] NOT NULL, 
                        [tWaiting] [int] NOT NULL, 
                        [tDialing] [int] NOT NULL,
                        [tNotes] [int] NOT NULL,
                        [tHold] [int] NOT NULL,
                        [tGlobalNotReady] [int] NOT NULL,
                        [descripcion] [varchar](255) NULL,
                        [descripcion_time] [varchar](255) NULL,
                        [time] [int] NULL,
                        [tProblem] [int] NOT NULL,
                        [tOthers] [int] NOT NULL,
                        [pDialog] [decimal](10, 2) NOT NULL,
                        [pManual] [decimal](10, 2) NOT NULL,
                        [pPredictivo] [decimal](10, 2) NOT NULL,
                        [pIn] [decimal](10, 2) NOT NULL,
                        [pWAIn] [decimal](10, 2) NOT NULL,  
                        [pWAOut] [decimal](10, 2) NOT NULL, 
                        [pTransferRecivied] [decimal](10, 2) NOT NULL, 
                        [pWaiting] [decimal](10, 2) NOT NULL,
                        [pDialing] [decimal](10, 2) NOT NULL,
                        [pNotes] [decimal](10, 2) NOT NULL,
                        [pHold] [decimal](10, 2) NOT NULL,
                        [pGlobalNotReady] [decimal](10, 2) NOT NULL,
                        [descripcion_percentage] [varchar](255) NULL,
                        [percentage] [decimal](10, 2) NULL,
                        [pProblem] [decimal](10, 2) NOT NULL,
                        [pOther] [decimal](10, 2) NOT NULL,
                        [pRealTime] [decimal](10, 2) NOT NULL,
                        [nTotalAgente] [int] NOT NULL,
                        [nManual] [int] NOT NULL,
                        [nPredictivo] [int] NOT NULL,
                        [nIn] [int] NOT NULL,
                        [nTransferRecivied] [int] NOT NULL,
                        [nTransferDone] [int] NOT NULL,
                        [nWAIn] [int] NOT NULL,
                        [nWAOut] [int] NOT NULL,
                        [tRealTime] [int] NOT NULL,
                        [tOccupation] [int] NOT NULL,
                        [tWorkTime] [int] NOT NULL,
                        [year] [int] NOT NULL,
                        [month] [int] NOT NULL,
                        [day] [int] NOT NULL,
                        [hour] [int] NOT NULL,
                        [minutes] [int] NOT NULL
                    ) 
                 END
               '
    EXEC(@sql);

    SET @process = 'KR170000 Create index for the table RepAgentTimeShift'
    SET @sql = ' IF NOT EXISTS(SELECT * FROM sys.indexes where name = N''IX_RepAgentTimeShift'' AND object_id = OBJECT_ID(N''RepAgentTimeShift''))
             BEGIN
                CREATE INDEX IX_RepAgentTimeShift ON RepAgentTimeShift(date,userId)
             END
        '
    EXEC(@sql);

    SET @process = 'Delete View ccUserView for KR170000'
    SET @sql = 'IF EXISTS (SELECT 1 FROM sys.views WHERE name = ''ccUserView'' AND schema_id = SCHEMA_ID(''dbo''))
        BEGIN
            DROP VIEW [dbo].[ccUserView];
        END
    '
    EXEC(@sql)

    SET @process = 'Generate View ccUserView for report KR170000 '
    SET @sql='
        CREATE VIEW [dbo].[ccUserView] AS
        SELECT 
            User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, 
            TipoStatusAge_id, TipoUser_id, Status, Sexo, IDArea, fCreate 
        FROM ccUsers
        UNION
        SELECT 
            User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, 
            TipoStatusAge_id, TipoUser_id, Status, Sexo, IDArea, fCreate 
        FROM ccUsers_Consulta;
    '
    EXEC(@sql)

    SET @process = 'KR170000 Delete SP for RepAgentTimeShift'

    SET @sql='
	    IF EXISTS(select 1 from sys.procedures where name = ''ccspRepAgentTimeShift'')
	    BEGIN
		    DROP PROCEDURE [dbo].[ccspRepAgentTimeShift]
	    END
    '
    EXEC(@sql)

	SET @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
		set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
			begin
			DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
			end'
		EXEC(@sql)

	SET @process = 'Alter table for CampType KR170000'
        SET @sql = 'IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccCamps'' AND COLUMN_NAME = ''CampType'')
		BEGIN
			ALTER TABLE ccCamps
			ADD CampType int NULL;

			
		END'
        EXEC(@sql)

	SET @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
	SET @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
			begin
			ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
			end'
	EXEC(@sql)


    SET @process = 'KR170000 Create SP for RepAgentTimeShift'
    SET @sql = '      
        CREATE PROCEDURE [dbo].[ccspRepAgentTimeShift]
        @action AS TINYINT ,@from AS DATETIME ,@to AS DATETIME AS

        IF @from IS NULL
        	SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

        IF @to IS NULL
        	SELECT @to = GETDATE();

        IF @action = 1
	    BEGIN
	    	DELETE	FROM RepAgentTimeShift WHERE [date] >= @from AND [date] <= @to

	    	DECLARE @now DATETIME
	    	SET @now=GETDATE()
	    	;WITH sessionAgt AS(
	    		SELECT user_id,
	    			extension
	    			,MIN(login) AS login
	    			,MAX(logout) AS logout
	    			,SUM(tlog) AS tlog
	    			,dbo.getdaygroup(timeGroup) AS timeGroupDay
	    		from tmpSessionTimeGroup
	    		GROUP BY 
	    		dbo.getdaygroup(timeGroup)
	    		,user_id,extension
	    	), callIn AS (
	    		SELECT User_id AS userId
	    		,SUM(tdialog) AS tdialogIn
	    		,SUM(tnotes) AS tnotes
	    		,SUM(cal_tMoh) AS cal_tMoh
	    		,dbo.getdaygroup(timeGroup) AS timeGroupDay
	    		,SUM(ntotal) AS ntotal
	    		FROM tmpTimesInboundData
	    		GROUP BY 
	    		dbo.getdaygroup(timeGroup),User_id
	    	),campsOut AS(
	    		SELECT cam_id, progDial FROM cccamps WHERE CampType IN (0,5) AND progDial =0
	    	),callOut AS (
	    		SELECT 
	    		t.User_id AS userId
	    		,SUM(t.tdialog) AS tdialogOut
	    		,SUM(t.tnotes) AS tnotes
	    		,SUM(t.cal_tMoh) AS cal_tMoh
	    		,SUM(CASE WHEN t.cal_manual IN (1,2) THEN t.tdialog ELSE 0 END) AS tMdialogOut
	    		,SUM(CASE WHEN t.cal_manual IN (1,2) THEN t.tnotes ELSE 0 END) AS tMnotes
	    		,SUM(CASE WHEN t.cal_manual IN (1,2) THEN t.cal_tMoh ELSE 0 END) AS Mcal_tMoh
	    		,dbo.getdaygroup(timeGroup) AS timeGroupDay
	    		,SUM(t.ntotal) AS ntotal
	    		,SUM(CASE WHEN t.cal_manual IN (1,2) THEN t.ntotal ELSE 0 END) AS isManual
	    		FROM tmpTimesOutboundData t
	    		INNER JOIN campsOut o ON t.cam_id=o.cam_id
	    		GROUP BY 
	    		dbo.getdaygroup(timeGroup)
	    		,t.User_id
	    	),whatsAppIn AS(
	    		SELECT agentId AS userId
	    		,dbo.getdaygroup(conversationDate) AS timeGroupDay
	    		,SUM(1) AS nWAIn
	    		,SUM(tWrapUp) AS tNotes
	    		FROM ccWhatsAppConversations
	    		WHERE conversationDate BETWEEN @from AND @to
	    		GROUP BY 
	    		agentId,
	    		dbo.getdaygroup(conversationDate)
	    	),whatsAppOut AS(
	    		SELECT agentId AS userId
	    		,dbo.getdaygroup(conversationDate) timeGroupDay
	    		,sum(1) AS nWAOut
	    		,sum(tWrapUp) AS tNotes
	    		FROM ccWhatsAppConversationsout
	    		WHERE conversationDate BETWEEN @from AND @to
	    		GROUP BY 
	    		agentId
	    		,dbo.getdaygroup(conversationDate)
	    	),logAgt AS (
	    		SELECT  userId AS userId
	    		,dbo.getdaygroup(timeGroup) AS timeGroupDay
	    		,CONVERT(INT,SUM(CASE WHEN tipostatusage_id = 2 THEN tStatus ELSE 0 END)) AS tNotReady
	    		,CONVERT(INT,SUM(CASE WHEN tipostatusage_id = 3 THEN tStatus ELSE 0 END)) AS tReady
	    		,CONVERT(INT,SUM(CASE WHEN tipostatusage_id IN (11, 25, 26, 27) THEN tStatus ELSE 0 END)) AS tProb
	    		,CONVERT(INT,SUM(CASE WHEN tipostatusage_id NOT IN (2, 3, 11, 25, 26, 27, 21, 34, 6, 5, 0,4,7,9) THEN tStatus ELSE 0 END)) AS tOther
	    		,CONVERT(INT,SUM(CASE WHEN tipostatusage_id = 21 THEN tStatus ELSE 0 END)) AS tManualcall
	    		,CONVERT(INT,SUM(CASE WHEN tipostatusage_id = 34 and camType=0 and camId>0 THEN tStatus ELSE 0 END)) AS tWAIn
	    		,CONVERT(INT,SUM(CASE WHEN tipostatusage_id = 34 and camType=1 and camId>0 THEN tStatus ELSE 0 END)) AS tWAOut
	    		FROM tmpccLogAgentesDia
	    		GROUP BY dbo.getdaygroup(timeGroup),userId
	    	),notReadyDay as(
	    		SELECT r.userId, SUM(r.timeSeconds) AS timeSeconds, dbo.getdaygroup(r.DATE) AS daygroup
	    		,descripcion_time,descripcion,tiponotreadyId
	    		FROM RepAgentNotReady r with(nolock)
	    		WHERE r.DATE BETWEEN @from AND @to
	    		GROUP BY dbo.getdaygroup(r.DATE), r.userId,descripcion,descripcion_time,tiponotreadyId
	    	),logTransferRecivied AS(
	    		SELECT agt.User_id
	    		,transfer.destino
	    		,SUM(tDespuesXfer) AS TimeInTransfer
	    		,dbo.getdaygroup(timeGroup) AS timeGroupDay
	    		,SUM (1) AS ntotal
	    		FROM TmpTimesccLogtransfers transfer
	    		INNER JOIN sessionAgt agt ON agt.Extension=transfer.destino AND agt.timeGroupDay= dbo.getdaygroup(transfer.timeGroup)
	    		WHERE modo=1 AND tipo IN (1,2)
	    		GROUP BY dbo.getdaygroup(timeGroup),
	    		destino,
	    		agt.User_id
	    	),logTransferDoneIN AS(
	    		select 
	    			cin.User_id
	    			,SUM(tDespuesXfer) AS time
	    			,dbo.getdaygroup(transfer.timeGroup) AS timeGroupDay
	    			,SUM (ntotal) ntotal 
	    		FROM TmpTimesccLogtransfers transfer
	    		LEFT JOIN tmpTimesInboundData cin ON transfer.callId =cin.cal_id  AND transfer.timegroup=cin.timegroup 
	    		WHERE tipo=1 AND modo=1
	    		GROUP BY dbo.getdaygroup(transfer.timeGroup),cin.User_id
	    	),logTransferDoneOut AS(
	    		SELECT 
	    			out.User_id,
	    			SUM(tDespuesXfer) AS time,
	    			dbo.getdaygroup(transfer.timeGroup) AS timeGroupDay,
	    			SUM (ntotal) AS ntotal 
	    		FROM TmpTimesccLogtransfers transfer
	    		LEFT JOIN tmpTimesOutboundData out ON transfer.callId =out.cal_id AND transfer.timegroup=out.timegroup 
	    		WHERE tipo=2 AND modo=1
	    		GROUP BY 
	    		dbo.getdaygroup(transfer.timeGroup),
	    		out.User_id
	    	),timeWorkTime AS(
	    		SELECT A.user_id
	    		,DATEDIFF(ss,MIN(A.Login),MAX(A.Logout)) AS tWorkTime 
	    		,MIN(A.Login) AS [Login]
	    		,MAX(A.Logout) AS [Logout]
	    		,A.timeGroupDay
	    		AS timeGroupDay
	    		FROM sessionAgt A 
	    		GROUP BY 
	    		A.timeGroupDay,
	    		A.user_id
	    	),Totales AS (
	    		SELECT A.user_id AS userId
	    		,A.timeGroupDay
	    		,SUM(ISNULL(callIn.tdialogIn,0)+ISNULL(callOut.tdialogOut,0)+ISNULL(logAgt.tWAIn,0)+ISNULL(logAgt.tWAOut,0) + ISNULL(logTransferRecivied.TimeInTransfer,0))
	    		AS tDialog
	    		,SUM(ISNULL(callOut.tMdialogOut,0)) AS tMdialogOut
	    		,SUM(ISNULL(callOut.tdialogOut-callOut.tMdialogOut,0)) AS tPredictivo
	    		,SUM(ISNULL(callIn.tnotes,0)+ISNULL(callOut.tnotes,0) + ISNULL(whatsAppIn.tNotes,0)+ ISNULL(whatsAppOut.tNotes,0)) AS tNotes
	    		,SUM(ISNULL(callIn.cal_tMoh,0)+ISNULL(callOut.cal_tMoh,0)) AS tHold
	    		,SUM(ISNULL(A.tlog,0)) AS tRealTime
	    		,SUM(ISNULL(timeWorkTime.tWorkTime,0)) AS tWorkTime
	    		,SUM(ISNULL(A.tlog,0) - ISNULL(logAgt.tNotReady,0)) AS tOccupation
	    		,SUM(ISNULL(callIn.nTotal,0) + ISNULL(callOut.nTotal,0) + ISNULL(logTransferRecivied.ntotal,0) + ISNULL(whatsAppIn.nWAIn,0)+ ISNULL(whatsAppOut.nWAOut,0)) AS nTotal
	    		,SUM(ISNULL(callOut.isManual,0)) AS nManual
	    		,SUM(ISNULL(callOut.ntotal-callOut.isManual,0)) AS nPredictivo
	    		,SUM(ISNULL(callIn.ntotal,0)) AS nIn
	    		,SUM(ISNULL(whatsAppIn.nWAIn,0)) AS nWAIn
	    		,SUM(ISNULL(whatsAppOut.nWAOut,0)) AS nWAOut
	    		,SUM(ISNULL(logTransferRecivied.ntotal,0)) AS nTransferRecivied
	    		,SUM(ISNULL(logTransferDoneIN.ntotal,0)+ISNULL(logTransferDoneOut.ntotal,0)) AS nTransferDone
	    		FROM sessionAgt A 
	    		LEFT JOIN callIn ON callIn.userId=A.user_id AND callIn.timeGroupDay=A.timeGroupDay
	    		LEFT JOIN callOut ON callOut.userId=A.user_id AND callOut.timeGroupDay=A.timeGroupDay
	    		LEFT JOIN logTransferRecivied ON logTransferRecivied.User_id=A.user_id AND logTransferRecivied.timeGroupDay=A.timeGroupDay
	    		LEFT JOIN logTransferDoneIN ON logTransferDoneIN.User_id=A.user_id AND logTransferDoneIN.timeGroupDay=A.timeGroupDay
	    		LEFT JOIN logTransferDoneOut ON logTransferDoneOut.User_id=A.user_id AND logTransferDoneOut.timeGroupDay=A.timeGroupDay
	    		LEFT JOIN timeWorkTime ON timeWorkTime.user_Id=A.user_id AND timeWorkTime.timeGroupDay=A.timeGroupDay
	    		LEFT JOIN logAgt ON logAgt.userId=A.user_id AND logAgt.timeGroupDay=A.timeGroupDay
	    		LEFT JOIN whatsAppIn ON whatsAppIn.userId=A.user_id AND whatsAppIn.timeGroupDay=A.timeGroupDay
	    		LEFT JOIN whatsAppOut ON whatsAppOut.userId=A.user_id AND whatsAppOut.timeGroupDay=A.timeGroupDay
	    		GROUP BY A.timeGroupDay
	    		,A.user_id
	    	)

	    	INSERT INTO RepAgentTimeShift
	    	SELECT  
	    	A.user_id AS userId
	    	,u.Login AS userName
	    	,u.Nombres+'' ''+u.ApellidoPaterno+'' ''+u.ApellidoMaterno AS fullName
	    	,A.timeGroupDay AS [date]
	    	,timeWorkTime.login as floginTime
	    	,timeWorkTime.logout as flogoutTime
	    	,CASE WHEN DATEDIFF(dd,u.fCreate,@now)<31 THEN ''systemTranslated_Nuevo'' ELSE ''systemTranslated_Experimentado'' END AS statusAgente
	    	,area.AreaName AS areaName
	    	,t.tDialog AS tDialogo
	    	,ISNULL(callOut.tMdialogOut,0) AS tManualAgent
	    	,t.tPredictivo AS tPredictivo
	    	,ISNULL(callIn.tdialogIn,0) AS tIn
	    	,ISNULL(logAgt.tWAIn,0) AS tWAIn
	    	,ISNULL(logAgt.tWAOut,0) AS tWAOut
			,ISNULL(logTransferRecivied.TimeInTransfer,0) AS tTransferRecivied
            ,ISNULL(logAgt.tReady,0) AS tWaiting
	    	,ISNULL(logAgt.tManualcall,0) AS tDialing
	    	,t.tNotes AS tNotes
	    	,t.tHold AS tHold
	    	,ISNULL(logAgt.tNotReady,0) AS tGlobalNotReady
	    	, notReady.descripcion as descripcion
            , notReady.descripcion_time as descripcion_time
            , notReady.timeSeconds as time
	    	,ISNULL(logAgt.tProb,0) AS tProblem
	    	,ISNULL(logAgt.tOther,0) AS tOthers
	    	,CAST(
	    	CASE 
	    			WHEN t.tDialog > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(t.tDialog, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2))
	    	 AS pDialog
	    	 ,CAST(CASE 
	    			WHEN callOut.tMdialogOut > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(callOut.tMdialogOut, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2))
	    	 AS pManual
	    	 ,CAST(CASE 
	    			WHEN t.tPredictivo > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(t.tPredictivo, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2))
	    	 AS pPredictivo
	    	 ,CAST(CASE 
	    			WHEN callIn.tdialogIn > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(callIn.tdialogIn, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2))
	    	 AS pIn
			  ,CAST(CASE 
	    			WHEN logAgt.tWAIn > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(logAgt.tWAIn, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2))
	    	 AS pWAIn
	    	,CAST(CASE 
	    			WHEN logAgt.tWAOut > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(logAgt.tWAOut, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2))
	    	 as pWAOut
			 ,CAST(CASE 
	    			WHEN logTransferRecivied.TimeInTransfer > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(logTransferRecivied.TimeInTransfer, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2))
	    	 AS pTransferRecivied
             ,CAST(CASE 
	    			WHEN logAgt.tReady > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(logAgt.tReady, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2))
	    	 AS pWaiting
	    	,CAST(CASE 
	    			WHEN logAgt.tManualcall > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(logAgt.tManualcall, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2))
	    	 AS pDialing
	    	  ,CAST(CASE 
	    			WHEN t.tNotes > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(t.tNotes, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2))
	    	 AS pNotes
	    	 ,CAST(CASE 
	    			WHEN t.tHold > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(t.tHold, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2))
	    	 AS pHold
	    	,CAST(CASE 
	    			WHEN logAgt.tNotReady > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(logAgt.tNotReady, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2)) AS pGlobalNotReady
            ,notReady.descripcion+''_Percentage'' as descripcion_percentage
	    	,CAST(CASE 
	    			WHEN notReady.timeSeconds > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(notReady.timeSeconds, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2)) AS [percentage]
	    	,CAST(CASE 
	    			WHEN logAgt.tProb > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(logAgt.tProb, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2)) AS pProblem
	    	,CAST(CASE 
	    			WHEN logAgt.tOther > 0 AND t.tRealTime > 0 THEN 
	    				CAST(dbo.fPorcentaje(logAgt.tOther, t.tRealTime) AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2)) AS pOther
	    	 ,CAST(CASE 
	    			WHEN t.tRealTime > 0 AND t.tWorkTime > 0 THEN 
	    				CAST(
	    				dbo.fPorcentaje(t.tRealTime, t.tWorkTime) 
	    				AS DECIMAL(18, 2))
	    			ELSE 
	    				0
	    		END AS DECIMAL(18, 2))
	    	 AS pRealTime
	    	,t.nTotal AS nTotalAgente
	    	,t.nManual AS nManual
	    	,t.nPredictivo AS nPredictivo
	    	,t.nIn AS nIn
	    	,t.nTransferRecivied AS nTransferRecivied
	    	,t.nTransferDone AS nTransferDone
            ,t.nWAIn AS nWAIn
	    	,t.nWAOut AS nWAOut
	    	,t.tRealTime AS tRealTime
	    	,t.tOccupation AS tOccupation
	    	,t.tWorkTime AS tWorkTime
	    	,datepart(yyyy, A.timeGroupDay) AS [year]
	    	,datepart(mm, A.timeGroupDay) AS [mount]
	    	,datepart(dd, A.timeGroupDay) AS [day]
	    	,datepart(HH, A.timeGroupDay) AS [hour]
	    	,datepart(mi, A.timeGroupDay) AS [minutes]
	    	FROM sessionAgt A 
	    	LEFT JOIN ccUserView u ON u.User_id=A.user_id 
	    	LEFT JOIN timeWorkTime ON timeWorkTime.user_Id=A.user_id and timeWorkTime.timeGroupDay=A.timeGroupDay
	    	LEFT JOIN ccriacat_areas area ON area.IDArea=u.IDArea
	    	LEFT JOIN callIn ON callIn.userId=A.user_id AND callIn.timeGroupDay=A.timeGroupDay
	    	LEFT JOIN callOut ON callOut.userId=A.user_id AND callOut.timeGroupDay=A.timeGroupDay
	    	LEFT JOIN logTransferRecivied ON logTransferRecivied.User_id=A.user_id AND logTransferRecivied.timeGroupDay=A.timeGroupDay
	    	LEFT JOIN logAgt ON logAgt.userId=A.user_id AND logAgt.timeGroupDay=A.timeGroupDay
	    	LEFT JOIN Totales t ON A.user_id=t.userId AND a.timeGroupDay=t.timeGroupDay
	    	LEFT join notReadyDay notReady on notReady.userId=A.user_id and notReady.daygroup=A.timeGroupDay
	    	order by A.timeGroupDay,A.user_id
        END;
    '
    EXEC(@sql);

    SET @process = 'KR170000 Attach date filter for RepAgentTimeShift report'
    SET @sql = ' IF NOT EXISTS(SELECT * FROM ReportsFiltersMenus where idReport = 2110)
             BEGIN
               INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(2110,N''date'')
             END
            '
    EXEC(@sql);

    SET @process = 'KR170000 Attach filter by for RepAgentTimeShift report'
    SET @sql = ' IF NOT EXISTS(SELECT * FROM ReportsFiltersMenus WHERE idReport = 2110)
              BEGIN
                INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(2110,N''filterby'')
              END
           '
    EXEC(@sql);

    SET @process = 'KR170000 Attach user filter for RepAgentTimeShift report'
    SET @sql = 'IF NOT EXISTS(SELECT * FROM ReportsFilters WHERE id=2110)
            BEGIN
             INSERT INTO ReportsFilters(reportName,filterName,id) values(''Shift Time'',''users'',2110)
            END
           '
    EXEC(@sql);

    SET @process = 'KR170000 Pivot the fields for the RepAgentTimeShift report'
    SET @sql = 'IF NOT EXISTS(SELECT * FROM PivotReports WHERE id=2110)
            BEGIN
                INSERT INTO PivotReports(id, columns, complementColumns, pivotFunction, isGroupPivot) 
                VALUES(2110, ''descripcion_time|descripcion_percentage'', 
                       ''userId|userName|fullName|date|floginTime|flogoutTime|statusAgente|areaName|tDialogo|tManualAgent|tPredictivo|tIn|tWAIn|tWAOut|tTransferRecivied|tWaiting|tDialing|tNotes|tHold|tGlobalNotReady|tProblem|tOthers|pDialog|pManual|pPredictivo|pIn|pWAIn|pWAOut|pTransferRecivied|pWaiting|pDialing|pNotes|pHold|pGlobalNotReady|pOther|pRealTime|nTotalAgente|nManual|nPredictivo|nIn|nWAIn|nWAOut|nTransferRecivied|nTransferDone|tRealTime|tOccupation|tWorkTime|year|month|day|hour|minutes'', 
                       ''max'', 1);
            END';
    EXEC(@sql);

	SET @process = 'KR170000 Translate Report'
    SET @sql = 'IF NOT EXISTS(select * from TranslatedReports where id = 2110)
            BEGIN
                INSERT INTO TranslatedReports VALUES (2110, ''statusAgente'')
            END';
    EXEC(@sql);
   -------------------------------------------  END Hector Chavez    -------------------------------------------
   

   SET @process = 'DROP VIEW [dbo].[ccCampsView] '
   SET @sql = 'IF EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N''ccCampsView''))
BEGIN
    DROP VIEW [dbo].[ccCampsView];
END;'
   EXEC(@sql)

   SET @process = 'CREATE VIEW [dbo].[ccCampsView]'
   SET @sql = 'CREATE VIEW [dbo].[ccCampsView] AS
SELECT 
    cam_id, cam_descripcion, IDArea
FROM ccCamps
UNION
SELECT 
    cam_id, cam_descripcion, IDArea
FROM ccCamps_consulta;'
   EXEC(@sql)

   SET @process = 'ALTER PROCEDURE [dbo].[ccspRepOutDials] Se modifica para usar vista ccCampsView'
   SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDials]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null 
    select @to = getdate()

if @action = 1 
begin
    declare @total decimal(10,2)
        
        

    select @total = count(*) from ccologdials as a WITH(NOLOCK, INDEX(IX_ccoLogDials_8))
    inner join ccTipoResultadoDial as b (NOLOCK) on (a.tipoResDial_id = b.tipoResDial_id)
    where fecha >= @from and fecha < @to        
    and cal_id is not null
        
    delete from RepOutDials where date >= @from AND date < @to
        
        
    ;with tmpRepOutDials as(
    select  DATEADD(HOUR, DATEDIFF(HOUR, 0, fecha), 0) as fecha ,cal_id
    ,a.tipoResDial_id, descripcion,cam_id
    from ccologdials as a WITH(NOLOCK, INDEX(IX_ccoLogDials_8))
    inner join ccTipoResultadoDial as b (NOLOCK) on (a.tipoResDial_id = b.tipoResDial_id)
    where fecha >= @from and fecha < @to        
    and a.cal_id is not null
    )

    
    insert into RepOutDials

    select fecha as [date]      
    ,isnull(a.cam_id,0) as campaignId, isnull(c.cam_descripcion,'''') as campaign
    , isnull(min(d.idwg),1) as workgroupId, isnull(min(wgname),'''') as workgroup, isnull(min(c.idarea),1) as areaId, isnull(min(areaname),'''') as area
        
    ,a.tipoResDial_id, descripcion,
    descripcion + ''_Count'' as descripcion_count,
    count(*) as count,
    descripcion + ''_Avg'' as descripcion_avg,
    convert(decimal(10,2), (count(*)/@total)*100.00) as avg,
    datepart(yyyy,fecha) AS [year],
    datepart(mm,fecha) as [month],
    datepart(dd,fecha) as [day],
    datepart(hh,fecha) as [hour],
    0 as [minutes]
    from  tmpRepOutDials as a
    left join ccCampsView as c (NOLOCK) on (a.cam_id = c.cam_id)
    left join ccRIACampEspWG as d (NOLOCK) on a.cam_id = d.IdCampEsp and d.tipo = 1 
    left join ccRIACat_WorkGroup as e (NOLOCK) on (d.idwg = e.idwg)
    left join ccRIAAreaWorkGroup as f (NOLOCK) on (e.idwg = f.idwg)
    left join ccRIACat_Areas as g (NOLOCK) on (c.idarea = g.idarea)     
    group by fecha ,        
    a.cam_id, c.cam_descripcion, a.tipoResDial_id, descripcion  
    
end'
   EXEC(@sql)


   SET @process = 'DROP SP ccspRepTwitterACD'
   SET @sql = '-- Eliminar si existen antes de crearlos
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''ccspRepTwitterACD'') AND type = ''P'')
    DROP PROCEDURE [dbo].[ccspRepTwitterACD];'
   EXEC(@sql)

   SET @process = 'DROP SP ccspRepTwitterAgente'
   SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''ccspRepTwitterAgente'') AND type = ''P'')
    DROP PROCEDURE [dbo].[ccspRepTwitterAgente];
'
   EXEC(@sql)

   SET @process = 'DROP SP ccspRepTwitterDetail'
   SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''ccspRepTwitterDetail'') AND type = ''P'')
    DROP PROCEDURE [dbo].[ccspRepTwitterDetail];
'
   EXEC(@sql)

   SET @process = 'DROP SP ccspRepTwitterGeneral'
   SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''ccspRepTwitterGeneral'') AND type = ''P'')
    DROP PROCEDURE [dbo].[ccspRepTwitterGeneral];'
   EXEC(@sql)

    SET @process = 'DROP SP RepOutCallsOnChatDetail'
   SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''RepOutCallsOnChatDetail'') AND type = ''P'')
    DROP PROCEDURE [dbo].[RepOutCallsOnChatDetail];'
   EXEC(@sql)
      ------------------------------------begin ulises ----------------------------------------------------------------
   set @process = 'Se crean indices'
	set @sql='IF NOT EXISTS (
    SELECT * FROM sys.indexes 
    WHERE name = ''IX_RepInCallsDetail_IVR_ID'' 
      AND object_id = OBJECT_ID(''dbo.RepInCallsDetail'')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RepInCallsDetail_IVR_ID]
    ON [dbo].[RepInCallsDetail] ([IVR_ID])
END'
	EXEC(@sql)
	set @process = 'Se crean indices'
	set @sql='IF NOT EXISTS (
    SELECT * FROM sys.indexes 
    WHERE name = ''IX_RepIVRDetail_IVR_ID'' 
      AND object_id = OBJECT_ID(''dbo.RepIVRDetail'')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RepIVRDetail_IVR_ID]
    ON [dbo].[RepIVRDetail] ([IVR_ID])
    INCLUDE ([callid],[callStatus])
END'
	EXEC(@sql)
   ------------------------------------End Ulises  -----------------------------------------------------------------
   ------------------------------------- Begin Gaby ---------------------------------------------------------------

    set @process = 'TT13556, TT14757 - Se modifica delete en sp ccspRepSpececialAgent'
    set @sql='
    ALTER   PROCEDURE [dbo].[ccspRepSpececialAgent] @action AS TINYINT
    ,@from AS DATETIME = NULL
    ,@to AS DATETIME = NULL
AS
IF @action = 1
BEGIN
    IF @from IS NULL
        SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

    IF @to IS NULL
        SELECT @to = getdate()

    DELETE RepSpececialAgent    WHERE [loginTime] BETWEEN @from          AND @to

    ;WITH outCall
    AS (
        SELECT convert([date], timegroup, 121) [date]
            ,User_id AS userId
            ,COUNT(CASE WHEN statuscall_id >= 10
                        AND ntotal > 0 THEN 1 ELSE NULL END) AS ncalls
            ,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) nabnd
            ,sum(nanswer) AS nanswer
            ,COUNT(CASE WHEN statuscall_id = 13
                        AND ntotal > 0
                        AND (
                            calif_id IS NULL
                            OR calif_id = 0
                            ) THEN 1 ELSE NULL END) AS nocalif
        FROM tmpTimesOutboundData
        GROUP BY convert([date], timegroup, 121)
            ,User_id
        )
        ,inCall
    AS (
        SELECT convert([date], timegroup, 121) [date]
            ,User_id AS userId
            ,COUNT(CASE WHEN statuscall_id >= 10
                        AND ntotal > 0 THEN 1 ELSE NULL END) AS ncalls
            ,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) nabnd
            ,sum(nanswer) AS nanswer
            ,COUNT(CASE WHEN statuscall_id = 13
                        AND ntotal > 0
                        AND (
                            calif_id IS NULL
                            OR calif_id = 0
                            ) THEN 1 ELSE NULL END) AS nocalif
        FROM tmpTimesInboundData
        GROUP BY convert([date], timegroup, 121)
            ,User_id
        )
        ,AgentGI
    AS (
        SELECT convert([date], [date], 121) [date]
            ,userId
            ,[user]
            ,[login]
            ,sum(tlog) [session]
            ,sum(tnotav) ndTime
            ,sum(tdialogin + tnotesin + tdialogout + tnotesout) dialogTime
            ,sum(tauxiliarready) as tauxiliarready
        FROM RepAgentGI WITH (NOLOCK)
        WHERE [date] BETWEEN @from
                AND @to
        GROUP BY convert([date], [date], 121)
            ,userId
            ,[user]
            ,[login]
        )
        ,ses
    AS (
        SELECT convert([date], [date], 121) [date]
            ,userId
            ,min(logintime) loginTime
            ,max(logouttime) logoutTime
        FROM RepAgentsession WITH (NOLOCK)
        WHERE [date] BETWEEN @from
                AND @to
        GROUP BY convert([date], [date], 121)
            ,userId
        )
    INSERT RepSpececialAgent
    SELECT A.[date]
        ,A.userId
        ,A.[user]
        ,A.[login]
        ,A.[session]
        ,ses.loginTime
        ,ses.logoutTime
        ,A.dialogTime
        ,A.ndTime
        ,ISNULL(cout.ncalls, 0) callsOut
        ,ISNULL(cin.ncalls, 0) callsIn
        ,isnull(cout.nabnd, 0) + isnull(cin.nabnd, 0) AS abandonedCalls
        ,ISNULL(cout.nanswer, 0) + ISNULL(cin.nanswer, 0) nanswer2
        ,ISNULL(cout.nocalif, 0) + ISNULL(cin.nocalif, 0) unrated
        ,isnull(A.tauxiliarReady,0) as tauxiliarready
    FROM AgentGI A
    INNER JOIN ses ON ses.[date] = A.[date]
        AND ses.userId = A.userId
    LEFT JOIN outCall cout ON cout.[date] = A.[date]
        AND cout.userId = A.userId
    LEFT JOIN inCall cin ON cin.[date] = A.[date]
        AND cin.userId = A.userId
END'
    EXEC(@sql)



    set @process = 'TT14595 - Se agrega modo 7 para telephone en ccspRepOutAnswAndXferCalls'
    set @sql='ALTER PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = NULL

AS

SET NOCOUNT ON

IF @from IS NULL
    SELECT @from = CONVERT(DATETIME,CONVERT(VARCHAR(11),GETDATE()))
IF @to IS NULL
    SELECT @to = GETDATE()

DECLARE @IVA INT
DECLARE @country AS TINYINT
SELECT @IVA = CONVERT(INT,ISNULL(valor,0)) FROM ccsettings WHERE setting_id = 25
SELECT @country = CONVERT(TINYINT,ISNULL(valor,1)) FROM ccsettings WHERE setting_id = 104

IF @country IS NULL SET @country = 1

IF @action = 1
BEGIN
--Borrar lo que esta para no repetir
DELETE FROM RepOutAnswAndXferCalls WHERE DATE >= @from AND DATE < @TO

declare @descriptionXfer varchar(100)

SELECT @descriptionXfer=[description] FROM dialType WHERE dialId = 3

;with ccld as(
    SELECT *, [dbo].[GetProveedor](Telefono, Puerto,tipoLlamada_id) AS proBIDs,tipoLlamada_id as CallType  FROM ccologdials
    WHERE fecha between @from and @to and answerbit = 1
)

INSERT INTO RepOutAnswAndXferCalls
SELECT COALESCE([Call].cal_inicio,ccld.fecha) AS [date],
    ISNULL(ccld.cal_id,0) AS [callid],
    ISNULL(ccld.cam_id,0) AS [campaignId],
    ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
    ISNULL([Call].user_id,0) AS [userId],
    ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, ''N/A'') AS [Agent],
    dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg) AS [dialog],
    ccld.telefono AS [telephone],
    ISNULL(Call.cal_manual,0) AS [dialId],
    ISNULL(dialType.[description],''systemTranslated_Auto'') AS [dialType],
    ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
    CASE 
        WHEN provedor_id IS NOT NULL THEN dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),COALESCE(Call.provedor_id,ccld.proBIDs),
            dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg), @country)
        ELSE  CONVERT(DECIMAL(10,2),(CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) / 60) * ccost.additional_min)))
    END AS [ncost],
    @IVA AS iva,
    CASE
        WHEN provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),
                COALESCE(Call.provedor_id,ccld.proBIDs), dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg), @country),0.00) * (1 + (@IVA / 100.00)))
        ELSE  CONVERT(DECIMAL(10,2),((CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) / 60) * ccost.additional_min)) * (1 + (@IVA / 100.00))))
    END AS total,
    COALESCE(ccld.Puerto, Call.cal_puerto, 0) as [trunk],
    case when (ccld.ani is not null and ccld.ani<>'''') then ccld.ani when dbo.TelAni(ccld.Telefono, camps.id_anilist) <> '''' then dbo.TelAni(ccld.Telefono, camps.id_anilist) else camps.ani end [ANI],
    COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0) + ISNULL(ccld.tdialing,0), ccld.tdialing) as dialTimeSec
FROM ccld
    LEFT JOIN ccoCallsOut Call WITH(NOLOCK) ON ccld.cal_id = Call.cal_id
            AND ccld.answerbit = 1
    LEFT JOIN ccCamps camps ON camps.[cam_id] = ccld.[cam_id]
    LEFT JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id]
    LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = COALESCE(Call.[tipoLlamada_id],ccld.CallType) and tl.Country_id = @country)
    LEFT JOIN ccCallCost_RIA ccost (NOLOCK) ON ccost.tipoLlamada_id = tl.tipoLlamada_id     AND ccost.country_id = tl.country_id
    left join dialType on dialType.dialId = Call.cal_manual


;with clt as (

SELECT *
, DATEADD(ss,-(tAntesXfer + tDespuesXfer),fechaFin) AS [date]
, tipoLlamada_id AS  CallType 
,case WHEN modo in(5,6) then abs(destino) else null end posicion
    FROM cclogtransfers WITH(NOLOCK) 
    WHERE modo not in (1,2) 
        AND (tAntesXfer > 0 or tDespuesXfer > 0) 
        AND fechaFin between @from and @to
)


INSERT INTO RepOutAnswAndXferCalls  
SELECT clt.[date],
    clt.cal_id AS [callid],
    COALESCE(co.cam_id,ci.inbound_id,''0'')  AS [campaignId],
    COALESCE(camps.cam_descripcion, ACD.descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
    ISNULL((CASE tipo 
                WHEN 1 THEN ci.User_id 
                ELSE co.User_id 
            END),0) AS [userId],
    ISNULL((SELECT nombres + '' '' + apellidopaterno + '' '' + apellidomaterno FROM ccusers NOLOCK WHERE user_id = 
                (CASE tipo 
                    WHEN 1 THEN ci.User_id 
                    ELSE co.User_id 
                END)),''systemTranslated_NoName'') as [Agent],
    dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) AS [dialog],
    CASE 
        WHEN modo = 0 THEN clt.destino
        WHEN modo = 3 THEN clt.destino 
        WHEN modo = 4 THEN clt.destino 
        WHEN modo = 7 THEN clt.destino
        WHEN modo in(5,6) THEN isnull((SELECT top 1 Computer FROM ccposicion WHERE pos_id = posicion),clt.destino) 
    END AS [telephone],
    3 AS [dialId],
    @descriptionXfer AS [dialType],
    ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
    CASE 
        WHEN tarifa.provedor_id IS NOT NULL THEN ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
            dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) ,@country), 0) 
        ELSE cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)
    END AS [ncost],
    @IVA AS iva,
    CASE 
        WHEN tarifa.provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
            dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0)
            ,@country),0.00) * (1 + (@IVA / 100.00))) 
        ELSE (cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)) * (1 + (@IVA / 100.00))
    END AS [total],
    IsNull(clt.channel, 0) as [trunk],
    case when (@country = 1 and modo = 4) then case when dbo.TelAni(clt.destino, camps.id_anilist) <> '''' then dbo.TelAni(clt.destino,camps.id_anilist) else camps.ani end else '''' end [ANI],
    ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) as dialTimeSec
FROM clt
    LEFT JOIN cccallsin ci WITH(NOLOCK) ON ci.cal_id=clt.cal_id AND tipo=1
    LEFT JOIN ccocallsout co WITH(NOLOCK) ON co.cal_id=clt.cal_id AND tipo=2 
    LEFT JOIN ccChannelTransfer channel ON clt.pbxId=channel.pbxId AND clt.channel BETWEEN channel.startChannel AND channel.endChannel
    LEFT JOIN cstoTarifa tarifa ON tarifa.provedor_id=channel.proveedorId AND tarifa.tipoLlamada_id = clt.CallType
    LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = clt.CallType AND tl.Country_id = @country)
    LEFT JOIN ccCallCost_RIA cCall ON cCall.country_id = tl.country_id AND cCall.tipoLlamada_id = tl.tipoLlamada_id
    LEFT JOIN ccCamps camps ON camps.[cam_id] = co.cam_id
    LEFT JOIN ccInbound ACD ON ACD.[Inbound_id] = ci.Inbound_id

end'
    EXEC(@sql)
    ------------------------------------ End Gaby ---------------------------------------------------------------------
	----------------------------------------- v 127.20250130.0.7 -------------------------------------------------------------
    --------------------------------------- Begin Gaby --------------------------------------------------------------
    
    set @process = 'TT14713 - Se modifica el sp ccspRepCatalogos'
    set @sql='
ALTER  PROCEDURE [dbo].[ccspRepCatalogos]
    @type as tinyint,
    @action tinyint = 0 -- 0 Filter select; 1 Filters Range
    ,@userId int =0 ---- se agrega parametro para filtros
    ,@menuId INT = 0

    AS
    declare @tablatemp table (id int, description varchar(100) null)
    declare @tempwork table (idwg int)
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @condition NVARCHAR(300) = '''';
    DECLARE @columnName NVARCHAR(100) = '''';
    DECLARE @consult NVARCHAR (2000) = '''';

    if @action = 0
    BEGIN
    IF OBJECT_ID(''TEMPDB..#filters'') IS NULL
    BEGIN
        CREATE TABLE #filters ([Type] VARCHAR(200))
    END

        -- CAMPAIGNS
    IF @type = 1 BEGIN

        INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId
        IF EXISTS (SELECT * FROM #filters)
        BEGIN
            SET @condition = '' WHERE camp.campType IN (SELECT * FROM #filters)''
            SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId;
        END
        ELSE BEGIN
            SET @columnName =   ''campaignId'';
        END

        SET @consult = N'' SELECT cam_id as id, cam_descripcion as description, @columnName as dbColumn FROM ccCamps camp''

        IF @userId <> 0 BEGIN

            SET @SQL = '' declare @tablatemp table (id int, description varchar(100) null)  
                insert into @tablatemp
                select distinct caesp.IdCampEsp,'''' '''' as description  from ccUserView us
                inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
                inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=1
                where us.[User_id] = @userId ''
                +''if exists(select 1 from @tablatemp) begin''
                + @consult + '' inner join @tablatemp A on camp.cam_id = A.id'' + @condition
                +''end
                else begin
                    SELECT 0 as id, ''''N/A'''' as description, ''''campaignId'''' as dbColumn
                end'';
        END
        ELSE BEGIN
            SET @SQL = @consult + @condition;
        END
        EXEC sp_executesql @SQL, N''@userId AS int = 0, @columnName AS NVARCHAR(100)'', @userId=@userId, @columnName=@columnName;
    END


        -- DIAL RESULTS
    if @type = 2 begin
        Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn
        from ccTipoResultadoDial
        order by descripcion
    end

        -- WORKGROUPS
    if @type = 3 begin
        if @userId <> 0 begin
            select v.IDWG as id, c.WGName as description, ''workgroupId'' as dbColumn
            from ccWgByAcdView v
            inner join ccriacat_workgroup c on c.IDWG=v.IDWG
            where USER_ID= @userId
            return
        end
        else  begin
            select idwg as id, wgname as description, ''workgroupId'' as dbColumn
            from ccRIACat_WorkGroup
            group by idwg, wgname   select * from ccRIACat_WorkGroup
            order by wgname
        end
    end


    -- AREAS
    if @type = 4 begin
    if @userId <> 0 begin

        insert into @tablatemp
        select distinct isnull(us.IDArea,0) as IDArea, wgu.User_id from ccUserView us
        inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
        where us.[User_id] = @userId

        select distinct idArea as id, isnull(AreaName,''S/AREA'') as description, ''areaId'' as dbColumn
        from ccRIACat_Areas area inner join @tablatemp tem on area.IDArea = tem.id
        return
    end
        else begin

            select idArea as id, AreaName as description, ''areaId'' as dbColumn
            from ccRIACat_Areas
            group by idArea, AreaName
            order by AreaName
        end
    end

    -- DISPOSITIONS OUT
    if @type = 5 begin
        SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
        FROM ccTipoCalifOut
        order by [description]
    end

        -- USER
    if @type = 6    begin
        if @userId <> 0 begin

                insert into @tempwork
                        select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

                select distinct us.User_id as id, us.Login as description,  ''userId'' as dbcolumn from ccUserView us
                inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

                inner join @tempwork awg on wgu.IDWG = awg.idwg
                where us.TipoUser_id = 1 and [status] = 1

                return
            end

            else begin

                SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn
                FROM ccUserView B WHERE [status] = 1 and TipoUser_id = 1
                ORDER BY description
            end
    end

        -- ACDS**************
    IF @type = 7 BEGIN

        INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId
        IF EXISTS (SELECT * FROM #filters)
        BEGIN
            SET @condition = '' WHERE B.chat IN (SELECT * FROM #filters)''
            SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId;
        END
        ELSE BEGIN
            SET @columnName = ''inboundId'';
        END

        SET @consult = N'' SELECT inbound_id AS id, descripcion AS description, @columnName AS dbColumn
            FROM ccinbound B''

        IF @userId <> 0 BEGIN

            SET @SQL = '' declare @tablatemp table (id int, description varchar(100) null)
                insert into @tablatemp
                select distinct caesp.IdCampEsp,'''''''' as description  from ccUserView us
                inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
                inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
                where us.[User_id] = @userId;''
                +''if exists(select 1 from @tablatemp) begin''
                + @consult + '' inner join @tablatemp A on B.inbound_id = A.id'' + @condition + '' return;''
                +''end
                else begin
                    SELECT 0 as id, ''''N/A'''' as description, ''''inboundId'''' as dbColumn
                end'';   
        END
        ELSE BEGIN
            SET @SQL = @consult + @condition;
        END
        EXEC sp_executesql @SQL, N''@userId INT = 0, @columnName AS NVARCHAR(100)'',@userId=@userId, @columnName=@columnName;
    end

        -- DIDS
    if @type = 8    begin
        select 0 as id, ''S/DNIS''  as description, ''dnisId'' as dbColumn
        union
        select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
        from ccdnis
    end

        --DISPOSITIONS IN
    if @type = 9 begin
        SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
        FROM ccTipoCalif
        order by [description]
    end

        --SUBDISPOSITIONS IN
    if @type = 10   begin
        SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
        FROM ccTipoCalifSub
        order by [description]
    end

        --PROVIDER
    if @type = 11 begin
        SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
        FROM cstoProvedor
        order by [description]
    end

        -- UNAVAILABLES
    if @type = 12 begin
        SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn
        FROM cctiponotready
        order by descripcion
    end

        -- DIALERS
    if @type = 13 begin
        SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn
        FROM ccoDialers
        order by descripcion
    end

        -- CallTYpes
    if @type = 14   begin
            SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn
            FROM ccStatusLlamada
        order by descripcion
    end

        -- SUBDISPOSITIONS OUT
    if @type = 21   begin
        SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
        FROM cctipocalifsubout
        order by [description]
    end

        --AVRS TEMPLATE-SECTION
    if @type = 15   begin
        SELECT fc.id as id, (rf.nombre +'' ''+ rc.con_descripcion)+'' ''+convert(varchar(10),fc.id) as description, ''templateSectionId'' as dbColumn
        FROM RIA_FORMATOCONCEPTO fc
        INNER JOIN  (SELECT id_formato, nombre, MAX(version) as version
                                        FROM RIA_FORMATOS
                                        WHERE activo = 1
                                        group by id_formato, nombre) as rf
        ON rf.id_formato = fc.templateId
        inner join RIA_CONCEPTOS rc ON rc.id_concepto = fc.sectionId
        order by fc.id
    END

    --exec dbo.ccspRepCatalogos @type=15,@action=0

        --AVRS TEMPLATES
    if @type = 16   begin
        SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn
        FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
                                        FROM RIA_FORMATOS
                                        WHERE activo = 1
                                        group by id_formato) as t
        ON f.id_formato = t.id_formato AND f.version = t.version
        order by f.nombre
    end

        --AVRS TEMPLATES
    if @type = 31   begin
        SELECT c.id_concepto as id, c.con_descripcion as description, ''sectionId'' as dbColumn
        FROM RIA_CONCEPTOS c INNER JOIN (SELECT id_concepto,MAX(version) as version
                                        FROM RIA_CONCEPTOS
                                        group by id_concepto) as t
        ON c.id_concepto = t.id_concepto AND c.version = t.version
        order by c.con_descripcion
    END

        --AVRS QUESTIONS
    if @type = 23   begin
        SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
        FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
                                        FROM RIA_PREGUNTAS
                                        group by id_pregunta) as t
        ON p.id_pregunta = t.id_pregunta
        order by p.enunciado_pregunta
    END


    --AVRS QUESTIONS CHAT
    if @type = 24   begin
        SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
        FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
                                        FROM RIA_PREGUNTAS
                                        group by id_pregunta) as t
        ON p.id_pregunta = t.id_pregunta
        order by p.enunciado_pregunta
    END

        -- AVRS SUPERVISOR
    if @type = 17   begin
        SELECT [user_id] as id, [login] AS description, ''supervisorId'' as dbColumn
        FROM ccUserView
        WHERE [status] = 1
        and TipoUser_id = 2
        ORDER BY [login]
    end

        --Status Call
    if @type = 25   begin
        select statusCall_id as id, [descripcion] as description, ''statusCallId'' as dbcolumn
        from ccstatusllamada
        order by [descripcion]
    end

        --Survey
    if @type = 26   begin
        select surveyId as id, [description] as description, ''surveyId'' as dbcolumn
        from Survey
        order by [description]
    end

    --dialType
    if @type = 29 begin
        select dialId as id, [description] as description, ''dialId'' as dbcolumn
        from dialType
        order by [description]
    end

        --dial
    if @type = 30   begin
        select id as id, [description] as description, ''dialId'' as dbcolumn
        from Dials
        order by [description]
    end

    if @type = 33 begin
        if @userId <> 0 begin
            insert into @tablatemp
            select distinct caesp.IdCampEsp,'''' as description  from ccUserView us
            inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
            inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
            inner join ccinbound i on caesp.IdCampEsp = i.Inbound_id and i.chat = 0
            where us.[User_id] = @userId

            SELECT inbound_id as id, descripcion as description, ''inboundCamp'' as dbColumn
            from ccinbound B
            inner join @tablatemp A on B.inbound_id = A.id
            return
        end
        else begin
            select inbound_id as id, descripcion as description, ''inboundCamp'' as dbColumn
            from ccinbound where chat = 0
        end
    end
    IF @type = 34   
    BEGIN
        SELECT DISTINCT TipoReadyAuxiliar_Id AS id, [Description] AS description, ''auxiliarId'' AS dbcolumn
        FROM TipoReadyAuxiliar
        ORDER BY [description]
    END
    IF @type = 35   
    BEGIN
        select SegmentId as Id,Name as description, ''SegmentId'' as dbColumn from ccSmsSegments
    END
    if @type = 36 begin
        if @userId <> 0 begin

                insert into @tempwork
                        select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

                select distinct us.User_id as id, us.Login as description,  ''adminId'' as dbcolumn from ccUserView us
                inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

                inner join @tempwork awg on wgu.IDWG = awg.idwg
                where us.TipoUser_id = 2 and [status] = 1

                return
            end

            else begin

                SELECT [user_id] as id, [login] AS description, ''adminId'' as dbColumn
                FROM ccUserView B WHERE [status] = 1 and TipoUser_id = 2
                ORDER BY description
            end
    end
    end --Action 0

    IF OBJECT_ID(''TEMPDB..#filters'') IS NOT NULL
    BEGIN
        DROP TABLE #filters;
    END

    -----------------------------------------------------------
    if @action = 1 begin
        -- TRUNKS
        if @type = 13
        begin
            SELECT MIN(trunk) as [min],MAX(trunk) as [max],''trunk'' as dbColumn  from RepTrunkBusy
        end

        -- AVRS DISPOSITION
        if @type = 18
        begin
            SELECT 0 as [min], 100 as [max],''Disposition'' as dbColumn
        end

        -- AVG DISPOSITION
        if @type = 19
        begin
            SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
        end

        -- SCORE
        if @type = 20
        begin
            SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
        end
    end'
    EXEC(@sql)
    -----------------------------------------End Gaby ------------------------------------------------------------

    --------------------------------------------------------BEGIN 127.20250130.0.7 Jesus Gallardo----------------------------------------------------------------------


    SET @process = 'Alter FN TimeInterval correcion visita muñoz'
    SET @sql = 'ALTER FUNCTION [dbo].[TimeInterval] (
    @start DATETIME,
    @stop DATETIME,
    @state1 DATETIME,
    @state2 DATETIME
)  
RETURNS INT
AS  
BEGIN 
    DECLARE @overlapStart DATETIME
    DECLARE @overlapEnd DATETIME
    DECLARE @time INT

    -- Calcular el máximo entre @start y @state1
    IF @start > @state1
        SET @overlapStart = @start
    ELSE
        SET @overlapStart = @state1

    -- Calcular el mínimo entre @stop y @state2
    IF @stop < @state2
        SET @overlapEnd = @stop
    ELSE
        SET @overlapEnd = @state2

    -- Calcular el tiempo
    IF @overlapEnd > @overlapStart
        SET @time = DATEDIFF(SECOND, @overlapStart, @overlapEnd)
    ELSE
        SET @time = 0

    RETURN @time
END'
    EXEC(@sql)

    SET @process = 'Alter Sp ReportsMasterProcessWIthOnlyGenerate Correcion para indices y filtro para tomar 02:59:30'
    SET @sql = 'ALTER procedure [dbo].[ReportsMasterProcessWIthOnlyGenerate] 
@from as datetime = null,@to as datetime=null,@scheduleTime int=10,@dateStart datetime =null
as

SET ANSI_WARNINGS off
SET NOCOUNT ON

declare @i int,@count int
declare @SQL varchar(max)
declare @name sysname
declare @descError nvarchar(max)
declare @dateSP datetime

set @dateSP = getdate()

-- Asumimos que @from y @to pueden venir con valores, o nulos

SET @from = ISNULL(@from, GETDATE());
SET @to = ISNULL(@to, GETDATE());

if @dateStart is null 
    set @dateStart=getdate()


-- Si @from es antes de las 03:00:00 → ajustarlo a 02:59:00 del día anterior
IF CAST(@from AS TIME) < ''03:59:30''
BEGIN
    SET @from = CAST( DATEADD(DAY, -1, CAST(@from AS DATE)) AS DATETIME);   -- 02:59:30 del día anterior
END
else begin
    SET @from = CAST(@from AS DATE);    -- 02:59:30 del día actual
end

set @from=dateadd(ss,(179*60)+30, @from)  -- 02:59:30

IF CAST(@to AS TIME) = ''00:00:00''
BEGIN
    set @to=dateadd(ss,(179*60)+30, @to) -- 02:59:00 del día siguiente
END


insert into logsReportsMaster(name,status,dateStart,dateEnd,error,maxTime)
values (''ReportsMasterProcessWIthOnlyGenerate'',2,@from,@to,'''',@scheduleTime)


exec ccspTmpTimesInterval @from= @from,@to=@to,@interval=15


declare @tableSpTmp table (id int identity primary key, nameSp varchar(300),status int)

insert into @tableSpTmp (nameSp,status) values (''ccspTmpSessionGeneral'',0)
insert into @tableSpTmp (nameSp,status) values (''ccspTmpSessionTimeGroup'',0)

insert into @tableSpTmp (nameSp,status) values (''ccspTimesccLogAgentesDia'',0) --Tabla tmpccLogAgentesDia tener los movimientos de los agentes
insert into @tableSpTmp (nameSp,status) values (''ccspTimesOutboundData'',0)        --Tabla tmpTimesOutboundData para los tiempos de las llamadas de salida
insert into @tableSpTmp (nameSp,status) values (''ccspTimesInboundData'',0)     --Tabla tmpTimesInboundData para los tiempos de las llamadas de entrada


insert into [logsReportsMaster] (name,status,dateStart,dateEnd,error,maxTime)
select nameSp,0,''19000101'',''19000101'','''',@scheduleTime from @tableSpTmp

select @i=1,@count =count(*) from @tableSpTmp


while @i<=@count
begin
    select @name = nameSp from @tableSpTmp where id=@i  

    set @sql =''EXEC ''+ @name +'' @from=''''''+convert(varchar(max),@from,121)+'''''', @to=''''''+convert(varchar(max),@to,121)+''''''''
    set @dateSP = getdate()
    
    
    begin try
        --print (@sql)
        exec (@sql)     
        update [logsReportsMaster] set status=1,dateStart=@dateSP,dateEnd=getdate() where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
    end try
    begin catch
        
        select @descError = ''Line: '' + cast(error_line() as nvarchar) + '' Number: '' + cast(@@error as nvarchar) + '' Message: '' + error_message()
        select @descError,@name
        update [logsReportsMaster] set status=3,dateStart=@dateSP,dateEnd=getdate(),error=@descError where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''     
        
    end catch

    set @i = @i+1
end

exec ccspTmpSessionGeneral @from= @from,@to=@to
exec ccspTmpSessionTimeGroup @from= @from,@to=@to

EXEC ccspTimesccLogAgentesDia @from = @from ,@to = @to              --Tabla tmpccLogAgentesDia tener los movimientos de los agentes
EXEC ccspTimesOutboundData @from = @from    ,@to = @to              --Tabla tmpTimesOutboundData para los tiempos de las llamadas de salida
EXEC ccspTimesInboundData @from = @from ,@to = @to                  --Tabla tmpTimesInboundData para los tiempos de las llamadas de entrada



create table #tmpProcedureReports( id int, name sysname)

insert into #tmpProcedureReports
select ROW_NUMBER() OVER(ORDER BY [name] ) AS id,[name] from  sys.procedures where [name] like ''ccspRep%'' and [name] not in(''ccspRepCatalogos'',''ccsprepLogAgentriaseparate'')
and name not in(select name from logsReportsMaster where status=0 and dateStart>=@dateStart) 

insert into [logsReportsMaster] (name,status,dateStart,dateEnd,error,maxTime)
select name,0,''19000101'',''19000101'','''',@scheduleTime from #tmpProcedureReports

select @i=1,@count =count(*) from #tmpProcedureReports



while @i<=@count
begin
    select @name = name from #tmpProcedureReports where id=@i   

    set @sql =''EXEC ''+ @name +'' @action=1,@from=''''''+convert(varchar(max),@from,121)+'''''', @to=''''''+convert(varchar(max),@to,121)+''''''''
    set @dateSP = getdate()
    
    
    begin try
        --print (@sql)
        exec (@sql)     
        update [logsReportsMaster] set status=1,dateStart=@dateSP,dateEnd=getdate() where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
    end try
    begin catch
        
        select @descError = ''Line: '' + cast(error_line() as nvarchar) + '' Number: '' + cast(@@error as nvarchar) + '' Message: '' + error_message()
        select @descError,@name
        update [logsReportsMaster] set status=3,dateStart=@dateSP,dateEnd=getdate(),error=@descError where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''     
        
    end catch

    set @i = @i+1
end

drop table #tmpProcedureReports'
    EXEC(@sql)


    SET @process = 'Alter SP ccSpCreateIndexReport se deja los inidices de los casos para reportes'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccSpCreateIndexReport]  
AS
BEGIN
    SET NOCOUNT ON;

declare @tIndexMerge table(id int identity,tableName varchar(255),status bit)
declare @sql nvarchar(max),@tableName varchar(255),@id int
declare @column varchar(255),@indexName varchar(255)



/****************************INDICES PARA REPORTES *******************************/
if not exists (select * from sys.indexes where name = N''IX_ccoCallsOut13'' and object_id = OBJECT_ID(N''ccoCallsOut''))
begin
   CREATE NONCLUSTERED INDEX IX_ccoCallsOut13
ON [dbo].[ccoCallsOut] ([cal_Inicio])
INCLUDE ([cal_id],[cal_telefono],[cal_puerto],[cam_id],[User_id],[statusCall_id],[calif_id],[cal_tDialog],[cal_tNotas],[cal_tXfer],[cal_tRing],[cal_manual],[cal_tMoh],[cal_whoHung],[cal_twait])
end

if not exists (select * from sys.indexes where name = N''IX_RIA_GRABACION_11'' and object_id = OBJECT_ID(N''RIA_GRABACION''))
begin
CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_11
ON [dbo].[RIA_GRABACION] ([tipo_llamada],[cal_id])
INCLUDE ([grab_id])
end

if not exists (select * from sys.indexes where name = N''IX_ccLogTransfers_3'' and object_id = OBJECT_ID(N''ccLogtransfers''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogTransfers_3
ON [dbo].[ccLogtransfers] ([fechaFin])
INCLUDE ([cal_id],[tipo],[modo],[destino],[tAntesXfer],[tDespuesXfer])
end


if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesDia_6'' and object_id = OBJECT_ID(N''ccLogAgentesDia''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_6
ON [dbo].[ccLogAgentesDia] ([fecha])
INCLUDE ([User_id],[TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesNotReady_5'' and object_id = OBJECT_ID(N''cclogagentesnotready''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesNotReady_5
ON [dbo].[cclogagentesnotready] ([fecha])
INCLUDE ([User_id],[TipoNotReady_id],[tStatus])
end

    
if not exists (select * from sys.indexes where name = N''IX_ccLogLogin_6'' and object_id = OBJECT_ID(N''ccloglogin''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogLogin_6
ON [dbo].[ccloglogin] ([fecha])
INCLUDE ([User_id],[Extension],[TipoMov])
end

if not exists (select * from sys.indexes where name = N''IX_ccoLogDials_8'' and object_id = OBJECT_ID(N''ccoLogDials''))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_8
ON [dbo].[ccoLogDials] ([fecha],[cal_id])
INCLUDE ([tipoResDial_id])
end



if not exists (select * from sys.indexes where name = N''IX_ccCallsIn_8'' and object_id = OBJECT_ID(N''ccCallsIn''))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_8
ON [dbo].[ccCallsIn] ([IVR_id])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N''IX_ccCallsIn_9'' and object_id = OBJECT_ID(N''ccCallsIn''))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_9
ON [dbo].[ccCallsIn] ([cal_Inicio])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N''IX_tmpSessionTimeGroup_1'' and object_id = OBJECT_ID(N''tmpSessionTimeGroup''))
begin
CREATE NONCLUSTERED INDEX IX_tmpSessionTimeGroup_1
ON [dbo].[tmpSessionTimeGroup] ([user_id])
INCLUDE ([timegroup],[tlog])
end

   
if not exists (select * from sys.indexes where name = N''IX_tmpccLogAgentesDia_2'' and object_id = OBJECT_ID(N''tmpccLogAgentesDia''))
begin
CREATE NONCLUSTERED INDEX IX_tmpccLogAgentesDia_2
ON [dbo].[tmpccLogAgentesDia] ([userId],[timeGroup])
INCLUDE ([TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N''IX_tmpTimesInboundData_1'' and object_id = OBJECT_ID(N''tmpTimesInboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_1
ON [dbo].[tmpTimesInboundData] ([statusCall_id])
INCLUDE ([timegroup],[Inbound_id],[nabnd],[tque],[txfer],[tring])
end

    
if not exists (select * from sys.indexes where name = N''IX_tmpTimesInboundData_2'' and object_id = OBJECT_ID(N''tmpTimesInboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_2
ON [dbo].[tmpTimesInboundData] ([cal_id])
INCLUDE ([Inbound_id],[User_id])
end


if not exists (select * from sys.indexes where name = N''IX_tmpTimesOutboundData_1'' and object_id = OBJECT_ID(N''tmpTimesOutboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_1
ON [dbo].[tmpTimesOutboundData] ([timegroup],[cal_id])
INCLUDE ([User_id])
end
    
if not exists (select * from sys.indexes where name = N''IX_tmpTimesOutboundData_2'' and object_id = OBJECT_ID(N''tmpTimesOutboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_2
ON [dbo].[tmpTimesOutboundData] ([cal_manual])
INCLUDE ([timegroup],[User_id],[nabnd_xfer],[nabnd_ring],[tdialog],[tnotes],[cal_id])
end



/**************************** INDICES Reportes *******************************/



set @column=''date''
delete from @tIndexMerge

insert into @tIndexMerge(tableName,status)
SELECT     
    t.TABLE_NAME,0
FROM 
    INFORMATION_SCHEMA.COLUMNS c
INNER JOIN 
    INFORMATION_SCHEMA.TABLES t 
    ON c.TABLE_NAME = t.TABLE_NAME AND c.TABLE_SCHEMA = t.TABLE_SCHEMA
WHERE 
    t.TABLE_NAME LIKE ''Rep%''   -- Las tablas que comienzan con ''Rep''
    AND c.COLUMN_NAME = ''date'' -- Que contienen una columna llamada ''date''
    AND t.TABLE_TYPE = ''BASE TABLE'' -- Solo tablas (no vistas)
ORDER BY 
    t.TABLE_SCHEMA, t.TABLE_NAME;


while exists(select 1 from @tIndexMerge where status=0) begin
    select top 1 @tableName=tableName,@id=id from @tIndexMerge where status=0 
    set @indexName=N''IX_''+ @tableName+''_date'' 
    set @sql=''if not exists(SELECT 1 FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.is_hypothetical = 0 -- Excluir índices hipotéticos
    and i.name = @tableName
    and c.name=@column
)
and not exists (select * from sys.indexes where name = @indexName and object_id = OBJECT_ID(@tableName)) 
and exists (select * from sys.columns where name = @column and Object_ID = Object_ID(@tableName))
begin
CREATE NONCLUSTERED INDEX ''+@indexName+''
ON [dbo].[''+@tableName+''] ([date])
end
    ''
    EXEC sp_executesql @sql, 
    N''@tableName varchar(255),@column varchar(255),@indexName varchar(255)'', 
    @tableName = @tableName, 
    @indexName = @indexName,
    @column = @column;
    --print (@sql)
    update @tIndexMerge set status=1 where @id=id
end
    
if not exists (select * from sys.indexes where name = N''IX_RepAgentNotReadyDet_2'' and object_id = OBJECT_ID(N''RepAgentNotReadyDet''))
begin
CREATE NONCLUSTERED INDEX IX_RepAgentNotReadyDet_2
ON [dbo].[RepAgentNotReadyDet] ([tiponotreadyId],[startDate])
INCLUDE ([userId],[status],[statusTime])
end

 

end'
    EXEC(@sql)

 SET @process = 'DROP VIEW [dbo].[ccInboundView] '
   SET @sql = 'IF EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N''ccInboundView''))
BEGIN
    DROP VIEW [dbo].[ccInboundView];
END;'
   EXEC(@sql)

   SET @process = 'CREATE VIEW [dbo].[ccCampsView]'
   SET @sql = 'CREATE VIEW [dbo].[ccInboundView] AS
SELECT 
    Inbound_id, descripcion, IDArea
FROM ccInbound
UNION
SELECT 
    Inbound_id, descripcion, IDArea
FROM ccInbound_consulta;'
   EXEC(@sql)


    SET @process = 'Alter Sp ccspRepAgentKPI se pone el from date'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentKPI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS


SET NOCOUNT ON

if @from is null
    select @from =convert(date,getdate())

if @to is null
    select @to = getdate()

set @from=convert(date,@from)


if @action = 1
begin
   delete RepAgentKPI with(rowlock) where date >= @from AND date < @to
    
    ;with callTemp as(  
    select  User_id, statusCall_id, cal_tDialog, convert(date, cal_Inicio, 121) as cal_Inicio, cal_whoHung, 0  as callType
    from ccoCallsOut with(nolock)
    where cal_inicio between @from and @to and cal_manual < 3
    union all
    select  User_id, statusCall_id, cal_tDialog, convert(date, cal_Inicio, 121) as cal_Inicio, cal_whoHung, 1 as callType
    from ccCallsIn with(nolock)
    where cal_inicio between @from and @to 
    ) 
    , Conteos as(
    select user_id, cal_Inicio, 1 Total, case callType when 1 then 1 else 0 end Cin, case callType when 0 then 1 else 0 end Cout,
    case when statusCall_id in (11,13,15,16,17) and cal_tDialog<10 then 1 else 0 end C10,
    case when statusCall_id in (11,13,15,16,17) and cal_tDialog<20 then 1 else 0 end C20,
    case when statusCall_id in (11,13,15,16,17) and cal_tDialog<30 then 1 else 0 end C30,
    cal_whoHung from callTemp
    ), logAgentDialogDistinct as(
    
    select distinct User_id,fecha_Calc_ms/1000.0 as fecha_Calc_ms,fecha_Dispo,fecha_Dialog
    from ccLogAgentesDia_Dialog 
    where fecha_Dialog between @from and @to     
    )
    , Trd as(   
    select  User_id, cast(AVG(fecha_Calc_ms) as decimal(10,0)) avg_fCalc
    , CONVERT(date,fecha_Dialog,121) as fecha_Dispo
    ,sum(fecha_Calc_ms) sum_fCalc
    from logAgentDialogDistinct with(nolock)
    where fecha_Dialog between @from and @to 
    group by User_id,CONVERT(date,fecha_Dialog,121)
    )
    , Snd as(
    select user_id, cal_Inicio, sum(Total) Total, sum(Cin) Cin, sum(Cout) Cout,
    sum(C10) C10, sum(C20) C20, sum(C30) C30, sum(cal_whoHung) cal_whoHung
    from Conteos group by user_id, cal_Inicio
    ), timeAgtDontDialog as(
    select A.User_id,convert(date,fecha) date
    ,sum(case when A.TipoStatusAge_id not in(0,4,5,6,9,37) then tStatus else 0 end) tDontDialog 
    ,sum(case when A.TipoStatusAge_id in(3,31) then tStatus else 0 end) tready
    from ccLogAgentesDia A with(nolock)
    where fecha between @from and @to
    group by A.User_id,convert(date,fecha)
    
    )


    insert into RepAgentKPI
    select Snd.cal_Inicio,Fst.Login as login , Fst.user_id as [userId]
    ,Nombres + isnull('' ''+ApellidoPaterno, '''') + isnull('' ''+ApellidoMaterno, '''') as [user]
    ,Total as totalCalls, Cin as callsIn
    ,Cout as callsOut, C10 as [finishedCalls10], C20 as [finishedCalls20], C30 as [finishedCalls30], cal_whoHung as whoHung
    ,isnull(avg_fCalc, 0) as callsAvgTime
    ,datepart(yyyy,Snd.cal_Inicio) [year]
    ,datepart(mm,Snd.cal_Inicio) [mounth]
    ,datepart(dd,Snd.cal_Inicio) [day]
    ,0 as [hour]
    ,0 as [minute]
    ,convert(decimal(10,0),agtTime.tDontDialog/Total) as [callsAvgTimeCustom]   
    from Snd
    inner join ccUserView Fst on Fst.User_id = Snd.User_id
    left join Trd on Trd.User_id=Snd.User_id and Trd.fecha_Dispo=Snd.cal_Inicio
    left join timeAgtDontDialog agtTime on agtTime.User_id=Snd.User_id and agtTime.date=Snd.cal_Inicio
    order by cal_Inicio

    

end'
    EXEC(@sql)


    SET @process = 'Alter SP ccspRepAgentSummary set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentSummary] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS

IF @from IS NULL
    SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()))

IF @to IS NULL
    SELECT @to = GETDATE()

set @from=convert(date,@from)

IF @action = 1
BEGIN

    IF OBJECT_ID(''tempdb..#AuxiliarReadyDetail'') IS NOT NULL
    DROP TABLE #AuxiliarReadyDetail

    CREATE TABLE #AuxiliarReadyDetail
    (
        timegroup DATE,
        userId INT,
        [user] VARCHAR(50),
        [sessionTime] INT,
        TipoReadyAuxiliarId INT,
        descripcion VARCHAR(50),
        descripcion_time VARCHAR(50),
        [time] DECIMAL(18, 3),
        timeSeconds DECIMAL(18, 3)
    )

    INSERT INTO #AuxiliarReadyDetail
    EXEC ccspGetAuxiliarReadyDetail @from = @from, @to = @to
        
    DELETE RepAgentSummary WHERE DATE BETWEEN @from AND @to;
    DELETE RepAgentSummary_VersionAmatech WHERE DATE BETWEEN @from  AND @to;
    ;
    WITH AgentSession
    AS (
        SELECT dbo.getdaygroup(loginTime) AS [date], userId, min([login]) AS [login], [user] AS [user], MIN(loginTime) AS dateLogin, MAX(logoutTime) AS logout, SUM(sessionTimeSeconds) AS sessionTime
        FROM RepAgentSession
        WHERE dbo.getdaygroup(loginTime) BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(logintime), userId, [user]
        ),
        -------------OUT -------------------
    dataCallsOut
    AS (
        SELECT DISTINCT cal_id, max(calif_id) calif_id, statusCall_id
        FROM tmpTimesOutboundData
        where cal_manual in (0,2,3)
        GROUP BY cal_id, statusCall_id
        ), dataCallsOutByDay
    AS (
        SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogOut, SUM(tnotes) tNotesOut, sum(nabnd_xfer) nabnd_xfer
        , sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
        , SUM(txfer)  txferOut, SUM(tring)  tringOut
        FROM tmpTimesOutboundData
        where cal_manual in (0,2,3)
        GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
        ), tmpCallout
    AS (
        SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifOut
        , isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallOut
        , isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallOut
        , sum(tDialogOut) AS tDialogOut, sum(tNotesOut) AS tNotesOut, sum(nabnd_xfer) abnd_xfer, sum(nabnd_ring) abnd_ring
        , sum(nabnd_dialog) abnd_dialog, [date]
        , SUM(txferOut)  txferOut, SUM(tringOut)  tringOut
        FROM dataCallsOutByDay A
        INNER JOIN dataCallsOut B
            ON A.cal_id = B.cal_id
        GROUP BY [date], User_id
        ),
        ------------- IN -------------------
    dataCallsIn
    AS (
        SELECT DISTINCT cal_id, max(calif_id) calif_id, statusCall_id
        FROM tmpTimesInboundData
        GROUP BY cal_id, statusCall_id
        ), dataCallsInByDay
    AS (
        SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogIn, SUM(tnotes) tNotesIn
        , sum(nabnd_xfer) nabnd_xfer, sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
        , SUM(txfer)  txferIn, SUM(tring)  tringIn
        FROM tmpTimesInboundData
        GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
        ), tmpCallIn
    AS (
        SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifIn
        , isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallIn
        , isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallIn
        , sum(tDialogIn) AS tDialogIn, sum(tNotesIn) AS tNotesIn, sum(nabnd_xfer) abnd_xfer
        , sum(nabnd_ring) abnd_ring, sum(nabnd_dialog) abnd_dialog, [date]
        , SUM(txferIn)  txferIn, SUM(tringIn)  tringIn
        FROM dataCallsInByDay A
        INNER JOIN dataCallsIn B
            ON A.cal_id = B.cal_id
        GROUP BY [date], User_id
        ), RepDetail
    AS (
        SELECT r.userId, SUM(r.timeSeconds) AS notReady, dbo.getdaygroup(r.DATE) AS daygroup
        FROM RepAgentNotReady r with(nolock)
        WHERE r.DATE BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(r.DATE), r.userId
        )
    ,notReadyDay as(
    SELECT r.userId, SUM(r.timeSeconds) AS timeSeconds, dbo.getdaygroup(r.DATE) AS daygroup
        ,descripcion_time,descripcion,tiponotreadyId
        FROM RepAgentNotReady r with(nolock)
        WHERE r.DATE BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(r.DATE), r.userId,descripcion,descripcion_time,tiponotreadyId
    ),auxiliarReadyDay as(
        SELECT r.userId, SUM(r.timeSeconds) AS timeSeconds, dbo.getdaygroup(timegroup) AS daygroup
        ,descripcion_time,descripcion,TipoReadyAuxiliarId
        FROM #AuxiliarReadyDetail r with(nolock)
        GROUP BY dbo.getdaygroup(timegroup), r.userId,descripcion,descripcion_time,TipoReadyAuxiliarId
    ), RepAgentGIGroup as(
        SELECT dbo.getdaygroup([date]) AS [date], userId, SUM(tav) AS tav
        , SUM(tunknown) AS tunknown
        , SUM(tother) AS tother
        , SUM(tprob) AS tprob
        , SUM(tChatting) AS tChatting       
        , SUM(tundefined) AS tundefined
        , SUM([tManual]) AS [tManual]
        FROM RepAgentGI
        WHERE [date] BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup([date]), userId
    )
    --select * from AgentSession
    
    INSERT INTO RepAgentSummary (date,login,[user],sessionTime,loginMktTime,logoutMktTime,callTengaged,ndTime,NCallsOut,NCallsIn,NCallsCorta,NAtend,NNoCalif
    ,Available,avgCallTengaged,twrapup,userId,TypeNotReady,descripcion,descripcion_time,time,transferStatus,ringingTime,unknownStatus,otherStatus,failureStatus
    ,chatTengaged,undefinedTime,dialingStatus,TipoReadyAuxiliarId,auxiliarRedy_descripcion,descripcion_auxiliarRedyTime_time,auxiliarRedyTime)
    SELECT A.[date], A.[login], A.[user], A.sessionTime, A.dateLogin AS loginMktTime
    , A.logout AS logoutMktTime
    , isnull(co.tDialogOut, 0) + isnull(ci.tDialogIn, 0) callTengaged
    , ISNULL(r.notready, 0) AS ndTime, isnull(co.AttendedCallOut, 0) AS NCallsOut, isnull(ci.AttendedCallIn, 0) AS NCallsIn
    , ISNULL(co.abnd_xfer, 0) + isnull(co.abnd_ring, 0) + isnull(co.abnd_ring, 0) + isnull(ci.abnd_xfer, 0) + isnull(ci.abnd_ring, 0) + isnull(ci.abnd_ring, 0) AS NCallsCorta
    , ISNULL(co.NotAttendedCallOut, 0) + ISNULL(ci.NotAttendedCallIn, 0) AS NAtend
    , ISNULL(ci.NoCalifIn, 0) + ISNULL(co.NoCalifOut, 0) AS NNoCalif    
    , ISNULL(AgtGI.tav, 0) AS Available
        ,ISNULL(    
        (   ISNULL(co.tDialogOut, 0) + ISNULL(co.tNotesOut, 0) + ISNULL(ci.tDialogIn, 0) + ISNULL(ci.tNotesIn, 0) )
            /
         nullif(isnull(co.AttendedCallOut,0) + isnull(ci.AttendedCallIn,0),0)
        , 0) AS avgCallTengaged
        
        ,ISNULL(co.tNotesOut, 0) + ISNULL(ci.tNotesIn, 0) AS twrapup, A.userId AS userId
        , notReady.TipoNotReadyId
        , notReady.descripcion
        , notReady.descripcion_time
        , notReady.timeSeconds
        , ISNULL(co.txferOut, 0) + ISNULL(ci.txferIn, 0) AS transferStatus
        , ISNULL(co.tringOut, 0) + ISNULL(ci.tringIn, 0) AS ringingTime
        , ISNULL(AgtGI.tunknown, 0) unknownStatus
        , ISNULL(AgtGI.tother, 0) otherStatus
        , ISNULL(AgtGI.tprob, 0) failureStatus
        , ISNULL(AgtGI.tChatting, 0) chatTengaged
        , ISNULL(AgtGI.tundefined, 0) undefinedTime
        , ISNULL(AgtGI.tManual, 0) dialingStatus
        , auxiliarReady.TipoReadyAuxiliarId
        , auxiliarReady.descripcion as auxiliarRedy_descripcion
        , auxiliarReady.descripcion_time as descripcion_auxiliarRedyTime_time
        , convert(int,auxiliarReady.timeSeconds) as auxiliarRedyTime
    FROM AgentSession A
    LEFT JOIN tmpCallout co ON A.DATE = co.DATE AND A.userId = co.userId
    LEFT JOIN tmpCallIn ci  ON A.DATE = ci.DATE AND A.userId = ci.userId
    LEFT JOIN RepDetail r   ON r.daygroup = A.DATE AND A.userId = r.userId
    inner join notReadyDay notReady on notReady.userId=A.userId and notReady.daygroup=A.date
    LEFT join #AuxiliarReadyDetail auxiliarReady on auxiliarReady.userId=A.userId and auxiliarReady.timegroup=A.date
    left join RepAgentGIGroup AgtGI on AgtGI.date=A.date and AgtGI.userId=A.userId
    order by A.[date],A.userId

END'
    EXEC(@sql)


    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepCallXfer] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepCallXfer]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

SET NOCOUNT ON

if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null  
        select @to = getdate()

    set @from=convert(date,@from)

    delete RepCallXfer with(rowlock)    where [date] between @from and @to
    insert RepCallXfer 
    select convert(varchar(10),fechafin,121) [date], 
    clt.cal_id callid, 
    case when tipo = 1 then ''systemTranslated_inbound'' else ''systemTranslated_outbound'' end CallTypes, 
    isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno 
            from ccUserView nolock 
            where user_id = (case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') Agent, 
    case when modo = 0 then ''systemTranslated_blindXfer'' 
        when modo = 1 then ''systemTranslated_Agent'' 
        when modo = 2 then 
            case when cast(dbo.Limpia(clt.destino) as int) >= 0 then ''systemTranslated_acd'' 
                else ''systemTranslated_Survey'' end 
        when modo = 3 then ''systemTranslated_conference'' 
        when modo = 4 then ''systemTranslated_supXfer'' 
        when modo in(5,6) then ''systemTranslated_overflow'' 
        when modo in(7) then ''systemTranslated_press8'' 
        else ''systemTranslated_Default'' 
    end as xfertype, 
    ISNULL((case when modo = 0 then isnull((select top 1 nombre 
                                    from telefonosTransferencia 
                                    where tel = clt.destino),clt.destino) 
        when modo = 1 then isnull((select Computer 
                                    from ccposicion 
                                    where pos_id = abs(clt.destino)),''systemTranslated_Indefinite'') 
        when modo = 2 then 
            case when cast(dbo.Limpia(clt.destino) as bigint) >= 0 then
                    isnull((select descripcion from ccinbound 
                            where inbound_id = clt.destino),''systemTranslated_Indefinite'') 
                else
                    isnull((select top 1 description 
                            from survey 
                            where active=1 
                            and scriptId = abs(cast(clt.destino as int))),''systemTranslated_Indefinite'') 
            end 
        when modo = 3 then isnull((select nombre 
                                    from telefonosConferencia 
                                    where tel = clt.destino),clt.destino) 
        when modo = 4 then isnull((select top 1 nombre 
                                    from telefonosTransferencia 
                                    where tel = clt.destino),clt.destino) 
        when modo in(5,6) then isnull((select Computer 
                                        from ccposicion 
                                        where pos_id = abs(clt.destino)),clt.destino) 
    end), ''systemTranslated_Indefinite'') destination, 
    tantesxfer timebeforexfer, 
    tdespuesxfer timeafterxfer, 
    dateadd(ss,-(tantesxfer + tdespuesxfer),fechafin) startDate, 
    fechafin as endDate, 
    case when camp.cam_descripcion is not null then camp.cam_descripcion 
        when inbound.descripcion is not null then inbound.descripcion 
        else ''systemTranslated_Indefinite'' 
    end as Origin, 
    tantesxfer+tdespuesxfer as TotalTimeDuration, 
    isnull((select case clt.tipoLlamada_id 
                when 1 then ''systemTranslated_fijo'' 
                when 3 then ''systemTranslated_cellPhone'' 
                else ''systemTranslated_interno'' 
            end),''systemTranslated_Indefinite'') as TipoTel, 
    (case tipo when 1 then ci.User_id else co.User_id end) User_ID, 
    isnull(callerAni, '''')  as callerni
    from cclogtransfers clt 
    left join ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
    left join cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1 
    left join cccamps camp on camp.cam_id =co.cam_id 
    left join ccinbound inbound on inbound.Inbound_id =ci.Inbound_id 
    WHERE fechafin >= @from and fechafin < @to
end
    '
    EXEC(@sql)


    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepIVRGeneral] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepIVRGeneral]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
    select @from = convert(date,getdate())

if @to is null
    select @to = getdate()

set @from=convert(date,@from)

if @action = 1
    begin
        delete RepIVRGeneral with(rowlock)
        where date >= @from and date < @to

        insert into RepIVRGeneral
        select convert(date,[date],121) as [date], 
        sum(case when calId = 0 then 1 else 0 end) as [noTransferred], 
        sum(case when calId > 0 then 1 else 0 end) as [transferred], 
        count(*) as [total]
        , datepart(yyyy,date)
        , datepart(mm,date)
        , datepart(dd,date)
        , 0
        , 0
        from (
        select A.Ivr_id, A.cal_ani, isnull(B.cal_id,0) as calId ,convert(date,A.[date],121) as [date] 
                from IVRCallsIn as a with(nolock)
                left join ccCallsIn as b with(nolock) on  A.IVR_id = B.IVR_id 
                where date >= @from and date < @to
            ) as c
        where date >= @from and date < @to
        group by [date]
        
    end'
    EXEC(@sql)



    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepMKTDiarioTiemposTotales] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepMKTDiarioTiemposTotales]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

SET NOCOUNT ON
if @from is null
    select @from = convert(date,getdate())

if @to is null
    select @to = getdate()

set @from=convert(date,@from)

declare @dateNow datetime,@maxLogout datetime

if @action = 1
begin

select 
    convert(datetime,convert(date,login)) fecha,
    SUM(DATEDIFF(ss, login, logout)) t_ses,
    count(distinct user_id) user_id
into #infoSession
from TmpSessionGeneral
GROUP BY convert(datetime,convert(date,login))

SELECT 
        i.cal_Inicio as [date],
        i.user_id as acduser,
        i.Inbound_id as inboundId,
        case when i.statuscall_id=13 then i.cal_tmoh else 0 end thold,
        case when i.statusCall_id=13 then i.cal_tring else 0 end tring,
        case when i.statusCall_id=13 and i.cal_tdialog>=0 then i.cal_tdialog else 0 end tacd,
        case when i.statusCall_id=13 then i.cal_tnotas else 0 end tacw,
        case when i.statusCall_id=13 then 1 else null end nacd,
        case when i.statusCall_id=13 and i.cal_tnotas>0 then 1 else null end nacw,
        case when i.statusCall_id=13 and i.cal_tmoh>0 then 1 else null end nhold,
        case when i.statusCall_id=13 and i.cal_tring>0 then 1 else null end nring   
    into #inboundData2          
    FROM    cccallsin i (NOLOCK)    
    WHERE   i.cal_inicio between @from and @to

SELECT user_id AS agtuser_id,
    login AS agtlogin,
    ISNULL(apellidopaterno,'''')+'' ''+ISNULL(apellidomaterno,'''')+'' ''+ISNULL(nombres,'''') agt_name
    into #users
    FROM ccUserView (NOLOCK)

    delete from [RepMKTDiarioTiemposTotales] with(rowlock)  where date >= @from AND date <= @to 

    insert RepMKTDiarioTiemposTotales 
    select c.[date] --
        ,isnull(l.agtlogin,''N/A'') as [OpaId]
        ,isnull(l.agt_name,'''') [NombreDeOperadora]
        ,[InboundID]--
        ,[TiempoPromACD]--
        ,[TiempoPromACW]--
        ,[TiempoPromReten]
        ,[TiempoPromRing]
        ,[AHT]
        ,[LlamadasAtendidas]
        ,DATEPART(YYYY, c.[date]) as [year] 
        ,DATEPART(mm, c.[date]) as [month]
        ,DATEPART(dd, c.[date]) as [day]
        ,DATEPART(hh, c.[date]) as [hour]
        ,DATEPART(mi, c.[date]) as [minutes]
     from (
        select convert(datetime,convert(date,[date])) as [date],
            acduser as [user],
            inboundId as [InboundId]
            ,case when sum(c.nacd)>0 then sum(c.tacd)/sum(c.nacd) else 0 end as [TiempoPromACD]
            ,case when sum(c.nacw)>0 then sum(c.tacw)/sum(c.nacw) else 0 end as [TiempoPromACW]
            ,case when sum(c.nhold)>0 then sum(c.thold)/sum(c.nhold) else 0 end as [TiempoPromReten]
            ,case when sum(c.nring)>0 then sum(c.tring)/sum(c.nring) else 0 end as [TiempoPromRing]
            ,sum(((case when c.nacd>0 then c.tacd/c.nacd else 0 end)+(case when c.nacw>0 then c.tacw/c.nacw else 0 end)+(case when c.nring>0 then c.tring/c.nring else 0 end)+(case when c.nhold>0 then c.thold/c.nhold else 0 end))) [AHT]
            ,isnull(sum(c.nacd),0) as [LlamadasAtendidas]
        from #inboundData2 as c 
        group by convert(datetime,convert(date,[date])),inboundId,acduser
    ) c
    LEFT JOIN #infoSession G on G.fecha = c.date
    left join #users l on [user]=l.agtuser_id   
    WHERE @from <= C.[date] AND @to >= c.[date] and [LlamadasAtendidas]>0
    order by [date]

drop table #inboundData2
drop table #infoSession 
drop table #users

end
'
    EXEC(@sql)


    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepOutAnswCalls] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutAnswCalls]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

SET NOCOUNT ON

if @action = 1
begin
    if @from is null
        select @from = convert(date,getdate())

    if @to is null
        select @to = getdate()

    set @from=convert(date,@from)
                            
    delete RepOutAnswCalls with(rowlock)
    where [date] between @from and @to

    ;with   
    co as(
    select
    convert(date,cal_inicio,121) [date],
    co.cam_id campaignId, count(*) total, 
    COUNT(CASE WHEN(statusCall_id = 16)THEN co.cal_id ELSE NULL END) nasig_tl,
    COUNT(CASE WHEN(statuscall_id = 15)THEN co.cal_id ELSE NULL END) nasig_nc,
    COUNT(CASE WHEN(statuscall_id = 13)THEN co.cal_id ELSE NULL END) nAnswered,
    COUNT(CASE WHEN(statuscall_id = 11)THEN co.cal_id ELSE NULL END) nassigned,
    COUNT(CASE WHEN(statuscall_id in (6,4))THEN co.cal_id ELSE NULL END) nabdn_sis
    from ccocallsout co with(nolock,index(IX_ccoCallsOut13))    
    where cal_inicio between @from and @to 
    group by convert(date,cal_inicio,121),co.cam_id
    ) 
    ,wgCalId as(
    
        select campaignId,isnull(min(wg.IDWG),1) IDWG
        from co o 
        left join ccRIACampEspWG wg on o.campaignId =wg.IdCampEsp and wg.Tipo=1
        group by campaignId
    )
    

    insert RepOutAnswCalls
    select 
    [date], abnd.campaignId, ca.cam_descripcion campaign, 
    wg.IDWG workgroupId, e.WGName workgroup, isnull(f.IDArea,0) areaId, g.AreaName area, total,
    cast(((nasig_tl*100.0)/total) as decimal(5,2)) asig_tl,
    cast(((nasig_nc*100.0)/total) as decimal(5,2)) asig_nc,
    cast(((nAnswered*100.0)/total) as decimal(5,2)) Answered,
    cast(((nassigned*100.0)/total) as decimal(5,2)) assigned,
    cast(((nabdn_sis*100.0)/total) as decimal(5,2)) abdn_sis
    from co abnd    
    left join cccamps ca on ca.cam_id=abnd.campaignId 
    left join wgCalId wg on abnd.campaignId=wg.campaignId
    left join ccRIACat_WorkGroup as e on e.idwg = wg.idwg
    left join ccRIAAreaWorkGroup as f on f.idwg = e.idwg
    left join ccRIACat_Areas as g on g.idarea = f.idarea
                            
end'
    EXEC(@sql)



    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsByTelephone] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsByTelephone]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
    select @from = convert(date,getdate())

if @to is null
    select @to = getdate()

set @from=convert(date,@from)


if @action = 1
    begin
        delete RepOutCallsByTelephone with(rowlock)
        where date >= @from and date < @to

        insert into RepOutCallsByTelephone
        select timegroup as [date], cal_telefono as [telephone], cal_key as [callKey], cam_id as [campaignId], cam_descripcion as [campaign], 
        count(cal_telefono) as quantity
        , datepart(yyyy,timegroup) as [year]
        , datepart(mm,timegroup) as [month]
        , datepart(dd,timegroup) as [day]
        , datepart(hh,timegroup) as [hour]
        , datepart(mi,timegroup) as [minutes]
        from(select cal_telefono, convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) as timegroup, cal_key, a.cam_id, b.cam_descripcion
             from ccocallsout a
             left join cccamps b on (a.cam_id = b.cam_id) 
             where cal_inicio >= @from 
             and cal_inicio < @to) c
        group by cal_telefono, timegroup, cal_key, cam_id, cam_descripcion
        order by cal_telefono, count(cal_telefono)
    end'
    EXEC(@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbnd] se cambia ccCampsView y ccInboundView'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbnd]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

declare @setting smallint
select @setting= valor from ccSettings where setting_id=43
if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null  
        select @to = getdate()

    delete RepSpececialAbnd with(rowlock)
    where [date] between @from and @to
    
    insert RepSpececialAbnd select [date], campaignId, inboundId, [Espec/Camp], total, abandonedCalls, 
    cast(((abandonedCalls*100.0)/total) as decimal(5,2)) abandonedCallsPctg from (
        select convert(varchar(10),cal_inicio,121) [date], 0 campaignId, ci.inbound_id inboundId, 
        ''ACD - '' + descripcion [Espec/Camp], count(*) total, 
        COUNT(
        CASE WHEN @setting = 0 and (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,''1900-01-01 00:00:00'') = ''1900-01-01 00:00:00''))  THEN 1
             WHEN @setting = 1 and (statuscall_id IN (6) AND (cal_que > 0) AND (isnull(cal_xfer,''1900-01-01 00:00:00'') = ''1900-01-01 00:00:00'')) THEN 1
         ELSE NULL END) abandonedCalls
        from cccallsin ci with(nolock) 
        left join ccInboundView ib on ib.inbound_id=ci.inbound_id 
        where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, ''ACD - '' + descripcion
        union all
        select convert(varchar(10),cal_inicio,121) [date], co.cam_id campaignId, 0 inboundId, 
        ''Camp - '' + cam_descripcion [Espec/Camp], count(*) total, 
        COUNT(
            CASE WHEN @setting = 0 and (statuscall_id in(11,15,16))THEN cal_id 
                 WHEN @setting = 1 and (statuscall_id in(6))THEN cal_id ELSE NULL END) abandonedCalls
        from ccocallsout co with(nolock) 
        left join ccCampsView ca on ca.cam_id=co.cam_id 
        where cal_inicio between @from and @to and cal_manual in (0,2) group by convert(varchar(10),cal_inicio,121), co.cam_id, ''Camp - '' + cam_descripcion
    ) abnd
end'
    EXEC(@sql)


    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbndPercentage] se agrega ccInboundView'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbndPercentage]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS
declare @setting smallint
set @setting=1
select @setting= valor from ccSettings where setting_id=43 

begin
    if @from is null
    select @from = convert(date,getdate())

    if @to is null
        select @to = getdate()

    set @from=convert(date,@from)

    delete RepSpececialAbndPercentage with(rowlock)
    where [date] between @from and @to

    insert RepSpececialAbndPercentage select [date], inboundId, [inbound]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [5]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [10]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [15]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [20]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [25]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [30]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [40]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [50]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [60]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [>60]
            from (
                select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
                ,cal_id
                ,SUM(CASE WHEN  @setting = 0 and (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) 
                          WHEN  @setting = 1 and (statuscall_id = 6) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
                ,COUNT(
                    CASE WHEN @setting = 0 and (statuscall_id <> 13) THEN 1 
                         WHEN @setting = 1 and (statuscall_id = 6) THEN 1 ELSE NULL END) AS nAbnd
                from cccallsin ci with(nolock) 
                left join ccInboundView ib on ib.inbound_id=ci.inbound_id
                where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
            ) xCalls
        GROUP BY [date], inboundId, [inbound]
end
'
    EXEC(@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbndProfiles] set @from=convert(date,@from) y ccInboundView'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbndProfiles]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS
declare @setting smallint
select @setting= valor from ccSettings where setting_id=43
if @action = 1
begin
    if @from is null
        select @from = convert(date,getdate())

    if @to is null
        select @to = getdate()

    set @from=convert(date,@from)

    delete RepSpececialAbndProfiles with(rowlock)
    where [date] between @from and @to

    insert RepSpececialAbndProfiles select [date], inboundId, [inbound]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))) AS [5]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))) AS [10]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))) AS [15]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))) AS [20]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))) AS [25]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))) AS [30]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))) AS [40]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))) AS [50]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))) AS [60]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 THEN 1 ELSE NULL END),0))) AS [>60]
        , COUNT(*) total
            from (
                select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
                ,cal_id
                ,SUM(CASE WHEN  @setting = 0 and (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) 
                          WHEN  @setting = 1 and (statuscall_id = 6) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
                ,COUNT(
                    CASE WHEN @setting = 0 and (statuscall_id <> 13) THEN 1 
                         WHEN @setting = 1 and (statuscall_id = 6) THEN 1 ELSE NULL END) AS nAbnd
                from cccallsin ci with(nolock) 
                left join ccInboundView ib on ib.inbound_id=ci.inbound_id
                where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
            ) xCalls
        GROUP BY [date], inboundId, [inbound]
end
'
    EXEC(@sql)


    
    SET @process = ' ALTER PROCEDURE [dbo].[ccspRepSpececialAbndTimes] set @from=convert(date,@from) y ccInboundView'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbndTimes]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS

declare @setting smallint
select @setting= valor from ccSettings where setting_id=43

if @action = 1
begin
    if @from is null
        select @from = convert(date,getdate())

    if @to is null
        select @to = getdate()

    set @from=convert(date,@from)

    delete RepSpececialAbndTimes with(rowlock)
    where [date] between @from and @to

    insert RepSpececialAbndTimes select [date], inboundId, [inbound]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [5]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [10]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [15]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [20]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [25]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [30]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [40]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [50]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [60]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [>60]
            from (
                select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
                ,cal_id
                ,SUM(CASE WHEN  @setting = 0 and (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) 
                          WHEN  @setting = 1 and (statuscall_id = 6) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
                ,COUNT(
                    CASE WHEN @setting = 0 and (statuscall_id <> 13) THEN 1 
                         WHEN @setting = 1 and (statuscall_id = 6) THEN 1 ELSE NULL END) AS nAbnd
                from cccallsin ci with(nolock) 
                left join ccInboundView ib on ib.inbound_id=ci.inbound_id
                where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
            ) xCalls
        GROUP BY [date], inboundId, [inbound]
end
'
    EXEC(@sql)


    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAgtPerformance] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAgtPerformance]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null  
        select @to = getdate()

    set @from=convert(date,@from)
                            
    DECLARE @data varchar(10), @promesa INT, @promesainb INT, @tresDialog AS smallint
    EXEC @tresDialog=ccspConfigTresDialog
    select @data = isnull(valor,''1|1'') from ccSettings where setting_id = 30
    SELECT @promesainb = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 1
    SELECT @promesa = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 2
                        
    delete RepSpececialAgtPerformance with(rowlock)
    where [date] between @from and @to

    insert RepSpececialAgtPerformance select [date],rcalls.USER_ID [userId]
    ,us.apellidopaterno + '' '' + us.apellidomaterno + '' '' + nombres [user],login [Agent]
    ,answer Answered, promises, promisesPctg, dialog avgCallTime, wrapup avgWrapupTime
    from (
    select [date], user_id, SUM(answer) answer, SUM(promises) promises
    ,isnull(cast(SUM(promises)*100.0/nullif(SUM(answer),0) as decimal(5,2)),0) promisesPctg
    ,isnull(sum(dialog)/nullif(SUM(answer),0),0) dialog, isnull(sum(wrapup)/nullif(SUM(answer),0),0) wrapup
    from (
    select 
    CONVERT(varchar(10),cal_inicio,121) [date], user_id
    ,isnull(sum(cal_tdialog),0) dialog, isnull(sum(cal_tnotas),0) wrapup
    ,isnull(count(case calif_id when @promesa then 1 else null end),0) promises
    ,isnull(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END),0) answer
    from ccoCallsOut with(nolock) where cal_inicio between @from and @to and cal_manual in(0,2) and USER_ID>0
    group by CONVERT(varchar(10),cal_inicio,121),user_id
    union all
    select
    CONVERT(varchar(10),cal_inicio,121) [date], user_id
    ,isnull(sum(cal_tdialog),0) dialog, isnull(sum(cal_tnotas),0) wrapup
    ,isnull(count(case calif_id when @promesainb then 1 else null end),0) promises
    ,isnull(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) answer
    from ccCallsIn with(nolock) where cal_inicio between @from and @to  and USER_ID>0
    group by CONVERT(varchar(10),cal_inicio,121),user_id) calls group by [date],user_id) rcalls 
    left join ccUserView us on us.user_id=rcalls.user_id
end'
    EXEC(@sql)



    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepSpececialPromises] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepSpececialPromises]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
    if @from is null
    select @from = convert(date,getdate())

    if @to is null
        select @to = getdate()

    set @from=convert(date,@from)

    DECLARE @data varchar(10), @promesa INT, @promesainb INT
    select @data = isnull(valor,''1|1'') from ccSettings where setting_id = 30
    SELECT @promesainb = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 1
    SELECT @promesa = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 2

    delete RepSpececialPromises with(rowlock)
    where [date] between @from and @to
    
    insert RepSpececialPromises SELECT convert(varchar(10),[date],121) [date], ''systemTranslated_outbound'' [type],
    cout.campaignId campaignId, 0 inboundId,
    camp.cam_descripcion [campACDDescription],
    ISNULL(SUM(CASE cout.dispositionId WHEN @promesa THEN cout.count ELSE 0 END),0) AS promises,
    ISNULL(SUM(cout.count),0) AS total,
    CASE ISNULL(SUM(cout.count),0) WHEN 0 THEN 0 ELSE  
    CONVERT(decimal,ISNULL(SUM(CASE cout.dispositionId WHEN @promesa THEN cout.count ELSE 0 END),0))/ 
    CONVERT(decimal,ISNULL(SUM(cout.count),0)) END AS percentage 
    FROM RepOutDispositions as cout JOIN ccCamps as camp ON camp.cam_id = cout.campaignId 
    WHERE cout.date BETWEEN @from AND @to GROUP BY convert(varchar(10),[date],121), cout.campaignId, camp.cam_descripcion
    union all
    SELECT convert(varchar(10),[date],121) [date], ''systemTranslated_inbound'' [type],
    0 campaignId, cin.inboundId inboundId,
    espe.descripcion [campACDDescription],
    ISNULL(SUM(CASE cin.dispositionId WHEN @promesainb THEN cin.count ELSE 0 END),0) AS promises,
    ISNULL(SUM(cin.count),0) AS TOTAL,
    CASE ISNULL(SUM(cin.count),0) WHEN 0 THEN 0 ELSE
    CONVERT(decimal,ISNULL(SUM(CASE cin.dispositionId WHEN @promesainb THEN cin.count ELSE 0 END),0))/ 
    CONVERT(decimal,ISNULL(SUM(cin.count),0)) END AS percentage
    FROM RepInDispositions as cin JOIN ccInbound as espe ON espe.inbound_id = cin.inboundId
    WHERE cin.date BETWEEN @from AND @to GROUP BY convert(varchar(10),[date],121), cin.inboundId, espe.descripcion
end'
    EXEC(@sql)





    



    SET @process = 'ALTER   PROCEDURE [dbo].[ccspRepMKTTiemposTotales] se cambia  ccInboundView'
    SET @sql = 'ALTER   PROCEDURE [dbo].[ccspRepMKTTiemposTotales]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

SET NOCOUNT ON

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
    select @to = getdate()

if @action = 1
begin

    IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup;           
        
    IF OBJECT_ID(''tempdb..#IntervalosInbound'') IS NOT NULL DROP TABLE #IntervalosInbound
    
    IF OBJECT_ID(''tempdb..#HoldDisp'') IS NOT NULL drop table #HoldDisp
    IF OBJECT_ID(''tempdb..#groupLog'') IS NOT NULL drop table #groupLog    

    IF OBJECT_ID(''tempdb..#transferData'') IS NOT NULL drop table #transferData        
    

    CREATE TABLE #sessionTimeGroup( [user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,
    [timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)
            
    
    ;with 
     relationCallIdCamId as(
        select distinct cal_id as callId,Inbound_id InboundId,User_id as userId from tmpTimesInboundData
    ),
    transferData as(
        select B.userId,B.InboundId
        ,CASE WHEN t.modo in (0,3,4) then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as SalExt
        ,CASE WHEN t.modo in (0,3,4)  then (t.tAntesXfer + t.tDespuesXfer) else 0 end as tprosalext         
        ,timegroup      
        from TmpTimesccLogtransfers T
        inner join relationCallIdCamId B on t.callId=B.callId   
        where tipo=1
    ), transferDataGroup as(

    select userId, timegroup, InboundId 
    ,sum(SalExt) SalExt,sum(tprosalext) tprosalext
    from transferData
    group by timegroup, InboundId,userId
    )
    

    select * into #transferData from transferDataGroup

    ;with relationWg as(
        select distinct wgu.User_id,wg.IdCampEsp from ccriaworkgroupusers wgu
        Inner Join ccRIACampEspWG wg ON wg.IDWG = WGU.IDWG
        where wg.Tipo = 0
    )

    INSERT INTO #sessionTimeGroup
    select st.[user_id],[login],logout,timegroup,timegroup_next timeGroupNext,tlog, wgu.IdCampEsp from TmpSessionTimeGroup st
        Inner Join relationWg wgu ON st.User_id = wgu.User_id

    
    select userId as user_id,camId as IdCampEsp,TipoStatusAge_id,
    sum(tstatus) as tstatus,
    sum(CASE WHEN timeGroup > dateIni AND timeGroupNext > dateEnd THEN 1 ELSE 0 END) AS nstatusfra,
    timeGroup
    INTO #groupLog
    from tmpccLogAgentesDia
    where TipoStatusAge_id IN (3,37) 
    GROUP BY userId,camId,TipoStatusAge_id,timegroup
    order by userId,timegroup,camId
                
    
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ;with inCount as(
        select i.timegroup,Inbound_id as inboundId,User_id userId 
        ,sum(CASE WHEN i.timeGroup > dateStartDetail AND i.timegroup_next > dateEndDetail and  statusCall_id = 13  THEN 1 ELSE 0 END ) as nacd          
                ,sum(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13  THEN 1 ELSE 0 END ) as nabnd
                ,sum(tdialog) as tacd
                ,sum(tnotes) as tacw
                ,sum(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13  and tnotes>0 THEN 1 ELSE 0 END) as nacw            
                ,sum(SalExt) as SalExt
                ,sum(tprosalext) as tprosalext
                ,sum(ntotal) as ncalls  
                ,SUM(tring) as tring
                ,SUM(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13  and tring>0 THEN 1 ELSE 0 END) as nring
                ,SUM(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13   THEN nMoh ELSE 0 END) as nhold
        from tmpTimesInboundData i
        left join #transferData  t on i.timegroup=t.timegroup and i.Inbound_id=t.InboundId
                    group by i.timegroup,Inbound_id,User_id 
    )

    select case when c.timegroup is not null then c.timegroup else G.timegroup end  as [date]
        ,isnull(c.inboundId,inb_id) as inboundId
        ,isnull(c.nacd,0) as nacd
        ,isnull(c.nabnd,0)  as nabnd    
        ,isnull(c.tacd,0)tacd, isnull(c.tacw,0) tacw,isnull(c.nacw,0) nacw      
        ,isnull(c.SalExt,0)  SalExt,isnull(c.tprosalext,0)  tprosalext
        ,G.userId 
        ,isnull(G.[tlog seg],0) as tlog
        ,isnull(c.ncalls, 0) AS ncalls      
        ,isnull(c.tring, 0) AS tring
        ,isnull(c.nring, 0) AS nring
        ,isnull(c.nhold, 0) AS nhold
     INTO #IntervalosInbound
     from (
            select * from  inCount where inboundId > 0      
        ) c     
    full join 
    (select [user_id] as userId, timegroup, inb_id,sum([tlog seg] ) as [tlog seg] from  #sessionTimeGroup group by [user_id] ,timegroup,inb_id ) G
    on G.timegroup=c.[timegroup] and c.inboundId = G.inb_id and G.userId=c.userId

    
    select i.*
    ,isnull(case when lo.TipoStatusAge_id=3 then isnull(lo.tStatus,0) end,0) tdispo
    ,isnull(case when lo.TipoStatusAge_id=3 then lo.nstatusfra end,0) ndispo
    ,isnull(case when lo.TipoStatusAge_id=37 then isnull(lo.tStatus,0) end,0) tauxiliar
    ,isnull(case when lo.TipoStatusAge_id=37 then 1 end,0) nauxiliar
    ,isnull(h.tiempohold, 0) AS thold
    INTO #HoldDisp
    from #IntervalosInbound i
    left JOIN #groupLog lo on i.date = lo.timegroup and i.inboundId = lo.IdCampEsp and i.userId = lo.user_id
    left JOIN tmpTimesHoldIn h on h.inbound_id = i.inboundId and i.date = h.timegroup and i.userId = h.userId   

    delete from [RepMKTTiemposTotales]  where date >= @from AND date <= @to

    INSERT INTO [RepMKTTiemposTotales]
    select 
        [date] as [date]
        ,inboundId
        ,inb.descripcion as Acds
        ,round(case when count(distinct userId)>1 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct userId)*1800))*count(distinct userId))/100 else 0 end,1) as [Llamadas por Posic.]
        ,sum(ncalls) [Recibidas]
        ,sum(nacd) [Atendidas]
        ,sum(nabnd) [Abandonadas]
        ,case when sum(nacd)>0 then sum(tacd)/sum(nacd) else 0 end as [tPromACD]
        ,case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end as [tPromACW]
        ,case when sum(nhold)>0 then sum(thold)/sum(nhold) else 0 end as [tPromRetention]
        ,sum(SalExt) as [callsOutExt]   
        ,isnull(case when sum(SalExt)>0 then sum(tprosalext)/sum(SalExt) else 0 end,0) as [TPromSalidaExt]
        ,case when sum(ndispo)>0 then sum(tdispo)/sum(ndispo) else 0 end as [TPromDispon]
        ,case when sum(nring)>0 then sum(tring)/sum(nring) else 0 end [TPromRing]
        ,sum(((case when nacd>0 then tacd/nacd else 0 end)+(case when nacw>0 then tacw/nacw else 0 end)+(case when nring>0 then tring/nring else 0 end)+(case when nhold>0 then thold/nhold else 0 end))) [AHT1]
        ,sum(tacd) as tacd
        ,sum(tacw) as tacw
        ,sum(nacw) as nacw              
        ,sum(tprosalext) as tprosalext
        ,sum(tlog) as tlog
        ,sum(nhold) as nhold
        ,sum(thold) as thold
        ,sum(tdispo) as tdispo
        ,sum(ndispo) as ndispo
        ,sum(tring) as tring
        ,sum(nring) as nring
        ,userId as accountUserId            
        ,DATEPART(YYYY, [date]) as [year] 
        ,DATEPART(mm, [date]) as [month]
        ,DATEPART(dd, [date]) as [day]
        ,DATEPART(hh, [date]) as [hour]
        ,DATEPART(mi, [date]) as [minutes]
        ,case when sum(nauxiliar)>0 then sum(tauxiliar)/sum(nauxiliar) else 0 end [TPromAuxiliar]
        ,sum(tauxiliar) as tauxiliarRdy
        ,sum(nauxiliar) as nauxiliar
        from #HoldDisp
        Left join ccInboundView inb ON inb.Inbound_id = inboundId
        group by[date],inboundId, userId, inb.descripcion
        order by date       

    IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup;                   
    IF OBJECT_ID(''tempdb..#IntervalosInbound'') IS NOT NULL DROP TABLE #IntervalosInbound
    
    IF OBJECT_ID(''tempdb..#HoldDisp'') IS NOT NULL drop table #HoldDisp
    IF OBJECT_ID(''tempdb..#groupLog'') IS NOT NULL drop table #groupLog    

    IF OBJECT_ID(''tempdb..#transferData'') IS NOT NULL drop table #transferData        

END'
    EXEC(@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepMKTIntervalos] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepMKTIntervalos]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
    
set nocount on
set ansi_nulls off
set ANSI_WARNINGS off


if @from is null
    select @from = convert(date,getdate())

if @to is null
    select @to = getdate()

if @action = 1
begin
    
    IF OBJECT_ID(''tempdb..#sessionTimeGroup'')  IS NOT NULL  drop table #sessionTimeGroup
    CREATE TABLE #sessionTimeGroup( [user_id] [smallint] NOT NULL,[timegroup] [datetime]  NOT NULL, [tlog] [INT] NULL, [inb_id] [int] NOT NULL) 
    
    ;with relationWg as(
        select distinct wgu.User_id,wg.IdCampEsp from ccriaworkgroupusers wgu
        Inner Join ccRIACampEspWG wg ON wg.IDWG = WGU.IDWG
        where wg.Tipo = 0
    )

    INSERT INTO #sessionTimeGroup
    select st.[user_id],timegroup,tlog, wgu.IdCampEsp 
    from TmpSessionTimeGroup st
    Inner Join relationWg wgu ON st.User_id = wgu.User_id


    delete from [RepMKTIntervalos]  where date >= @from AND date <= @to
        
    
    
    ;with 
     relationCallIdCamId as(
        select distinct cal_id as callId,Inbound_id InboundId,User_id as userId from tmpTimesInboundData
    ),
    transferData as(
        select B.userId,B.InboundId
        ,CASE WHEN t.modo = 2 then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as fent
        ,CASE WHEN t.modo = 2 and t.tipo=1 then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as fsal
        ,CASE WHEN t.modo in (0,3,4) then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as SalExt
        ,CASE WHEN t.modo in (0,3,4) then [dbo].TimeInterval( timegroup,timegroup_next,dateIni,dateEnd) else 0 end as tprosalext    
        ,dateIni as dateStart   
        ,dateEnd
        ,timegroup
        ,timegroup_next
        from TmpTimesccLogtransfers T
        inner join relationCallIdCamId B on t.callId=B.callId   
        where tipo=1
    ), transferDataGroup as(

    select userId, timegroup, InboundId 
    ,sum(fent) fent,sum(fsal) fsal, sum(salExt) salExt,sum(tprosalext) as tprosalext
    ,min(dateStart) as [dateTTransferStart]
    ,max(dateEnd) as [dateTTransferEnd]
    from transferData
    group by timegroup, InboundId,userId
    ), mktInterval as(

    select 
    i.timegroup
    ,i.inbound_Id as inboundId  
    ,i.User_id as userId
    ,sum(tresp) as tresp
    ,sum(case when statusCall_id =13 and ntotal>0 then 1 else 0 end) as nacd
    ,sum(case when statuscall_id <> 13 then tque+txfer+tring else 0 end) AS tAbnd
    ,sum(case when statusCall_id <>13 and ntotal>0 then 1 else 0 end) as nabnd  
    ,sum(case when statusCall_id=13 then tdialog else 0 end) as tacd
    ,sum(tnotes) as tacw
    ,sum(case when statusCall_id=13 and ntotal>0 and tnotes>0 then 1 else 0 end) as nacw 
    ,sum(case when statuscall_id = 13 then tque + txfer + tring else 0 end) as maxdem
    ,sum(case when statuscall_id in (7,8) AND nque > 0 AND txfer=0 then 1 else 0 end) as ncalque
    ,sum(case when statusCall_id in (7,8) AND nque > 0 AND txfer=0 then tque else 0 end) as tcalque
    ,isnull(sum(t.fent),0) as fent
    ,isnull(sum(t.fsal),0) as fsal
    ,isnull(sum(t.SalExt),0) as SalExt
    ,isnull(sum(t.tprosalext),0) as tprosalext  
    ,isnull(sum(ntotal),0) as ntotal
    ,1 as countUserDistinct
    ,count(distinct case when statusCall_id =13 and ntotal>0 then  userId end ) countUserDistinctNacd
    from tmpTimesInboundData i
    left join transferDataGroup t on i.timegroup=t.timegroup and i.Inbound_id=t.InboundId and i.User_id=t.userId    
    group by i.timegroup,i.inbound_Id,i.User_id 
    )

    INSERT INTO [RepMKTIntervalos]
    select 
    isnull(A.timegroup,g.timegroup) as [date]
    ,isnull(A.inboundId,g.[inb_id]) as inboundId
    ,inb.descripcion as Acds
    ,case when A.nacd>0 then A.tresp/isnull(nullif(A.nacd,0), 1) else 0 end as [avrAnswer]
    ,case when A.nabnd>0 then A.tabnd/A.nabnd else 0 end as [AvgAbandonTime]
    ,isnull(A.nacd,0) [acdCalls]
    ,case when A.nacd>0 then A.tacd/A.nacd else 0 end as [tPromACD]
    ,case when A.nacw>0 then A.tacw/A.nacw else 0 end as [tPromACW]
    ,isnull(A.nabnd,0) as [abondeonedCalls]
    ,isnull(A.maxdem,0) as [maxDelay]
    ,isnull(A.fent,0) as  [entryFlow]   
    ,isnull(A.fsal,0) as  [outFLow]
    ,isnull(A.SalExt,0) as [calloutExt] 
    ,isnull(case when A.SalExt>0 then A.tprosalext/A.SalExt else 0 end,0) as [TPromSalidaExt]
    ,isnull(A.ncalque,0) as [callDeleteQue] 
    ,case when A.ncalque>0 then A.tcalque/A.ncalque else 0 end as [TpromElimCola]       
    ,case when round(case when countUserDistinct>0 then ((convert(float,((tlog)*100))/isnull(nullif(convert(float,countUserDistinct*1800),0), 1))*countUserDistinct)/100 else 0 end,1)>0 
        then (case when convert(decimal(15,2),(((nacd) * case when (nacd)>0 then (tacd)/isnull(nullif((nacd),0), 1) else 0 end) / convert(float,((round(case when (countUserDistinct)>0 then ((convert(float,((tlog)*100))/isnull(nullif(convert(float,countUserDistinct*1800),0), 1))*countUserDistinct)/100 else 0 end,1))*1800)))*100)>100 then 100 
               else convert(decimal(15,2),(((nacd) * case when (nacd)>0 then (tacd)/isnull(nullif((nacd),0), 1) else 0 end) / convert(float,((round(case when countUserDistinct>0 then ((convert(float,((tlog)*100))/isnull(nullif(convert(float,countUserDistinct*1800),0), 1))*countUserDistinct)/100 else 0 end,1))*1800)))*100) end)
        else 0 end avrTimeACD       
    ,isnull(convert(decimal(10,2), case when nacd+nabnd>0 then convert(decimal(10,2), nacd*100.0/(nacd+nabnd)) else 0.00 end),0.00) avrCallsAnswer  
    ,isnull(convert(decimal(10,2), round( case when countUserDistinct is not null then (tlog*100.0/1800)/100 else 0 end,1)),0.00) as PromPosicionPersonal   
    ,case when (nacd) >0 then (case when (nacd)/isnull(nullif(countUserDistinctNacd,0), 1) >0 then convert(int, (nacd)/isnull(nullif(countUserDistinctNacd,0), 1)) else 1 end) else 0 end as [LlamadasporPosicion]
    ,isnull(A.tresp,0) as tresp
    ,isnull(A.tabnd,0) as tabnd
    ,isnull(A.tacd,0) as tacd
    ,isnull(A.tacw,0) as tacw
    ,isnull(A.nacw,0) as nacw       
    ,isnull(A.tcalque,0) as tcalque         
    ,isnull(A.tprosalext,0) as tprosalext
    ,isnull(g.tlog,0) as tlog
    ,isnull(A.userId,g.user_id) accountUserId   
    ,DATEPART(YYYY, isnull(A.timegroup,g.timegroup)) as [year] 
    ,DATEPART(mm, isnull(A.timegroup,g.timegroup)) as [month]
    ,DATEPART(dd, isnull(A.timegroup,g.timegroup)) as [day]
    ,DATEPART(hh, isnull(A.timegroup,g.timegroup)) as [hour]
    ,DATEPART(mi, isnull(A.timegroup,g.timegroup)) as [minutes]
    from mktInterval A
    full join #sessionTimeGroup g on A.timegroup=g.timegroup and A.inboundId=g.[inb_id] and A.userId=g.[user_id]
    Left join ccInboundView inb ON inb.Inbound_id = A.inboundId or inb.Inbound_id=g.inb_id
    where ntotal>0
    order by [date],inboundId,A.userId

    IF OBJECT_ID(''tempdb..#sessionTimeGroup'')  IS NOT NULL  drop table #sessionTimeGroup  
    
end
'
    EXEC(@sql)


    SET @process = ''
    SET @sql = ''
    EXEC(@sql)



    --------------------------------------------------------END 127.20250130.0.7 Jesus Gallardo----------------------------------------------------------------------


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
