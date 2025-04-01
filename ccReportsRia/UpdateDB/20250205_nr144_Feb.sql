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
SET NOCOUNT ON --

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
