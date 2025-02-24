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
   -------------------------------------------  BEGIN Carlos Chavez    -------------------------------------------

   SET @process = 'Se comenta sp ccSpCreateIndexReport al modificar schema_option en replicacion'
    SET @sql = 'ALTER PROCEDURE [dbo].[ReportsMasterProcessWIthOnlyGenerate] @from AS DATETIME = NULL
,@to AS DATETIME = NULL
,@scheduleTime INT = 10
,@dateStart DATETIME = NULL
,@isAllReport tinyint =0 --0 Only table ReportHighUse,1  not in table ReportHighUse, 2 all 
AS
SET ANSI_WARNINGS OFF
SET NOCOUNT ON

DECLARE @i INT,@count INT
DECLARE @SQL nVARCHAR(4000)
DECLARE @name SYSNAME
DECLARE @descError NVARCHAR(max)
DECLARE @dateSP DATETIME

IF @from IS NULL
BEGIN
    SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))
END

IF @to IS NULL
BEGIN
    SET @to = getdate()
END

IF @dateStart IS NULL
BEGIN
    SET @dateStart = getdate()
END

--exec ccSpCreateIndexReport

EXEC ccspTmpTimesInterval @from = @from ,@to = @to  ,@interval = 15 --Tabla TmpTimesInterval Temporal para tener Intervalos de 15 Minutos
EXEC ccspTmpSessionGeneral @from = @from    ,@to = @to              --Tabla tmpSessionGeneral para tener la sesiones de agentes
EXEC ccspTmpSessionTimeGroup @from = @from  ,@to = @to              --Tabla tmpSessionTimeGroup para dividir la sesion en intervalos de 15 Minutos
EXEC ccspTimesccLogAgentesDia @from = @from ,@to = @to              --Tabla tmpccLogAgentesDia tener los movimientos de los agentes
EXEC ccspTimesOutboundData @from = @from    ,@to = @to              --Tabla tmpTimesOutboundData para los tiempos de las llamadas de salida
EXEC ccspTimesInboundData @from = @from ,@to = @to                  --Tabla tmpTimesInboundData para los tiempos de las llamadas de entrada
exec ccspTmpTimesccLogtransfers @from = @from, @to = @to            --Tabla TmpTimesccLogtransfers para los tiempos de las llamadas que son trasferidas
exec ccsptmpTimesHoldIn @from = @from, @to = @to                    --Tabla tmpTimesHoldIn para los tiempos cuando se pone en hold en llamadas de entrada

CREATE TABLE #tmpProcedureReports (
    id INT
    ,name SYSNAME
    )

declare @tableSpDontProcess table(nameSp varchar(300) primary key not null)

insert into @tableSpDontProcess values(''ccspRepCatalogos'') -- ccspRepCatalogos es para catalogos por eso no se debe correr
insert into @tableSpDontProcess values(''ccspRepAgentSession'') -- ccspRepAgentSession Genera el reporte de sesiones para alimentar  
insert into @tableSpDontProcess values(''ccspRepAgentNotReadyDet'') -- ccspRepAgentNotReadyDet sabemos cuando inicia y cuando termina los no disponibles 
insert into @tableSpDontProcess values(''ccspRepAgentNotReady'') -- ccspRepAgentNotReady Agrupa por hora
insert into @tableSpDontProcess values(''ccspRepAgentGI'')      -- ccspRepAgentGI Agrupa por hora


if @isAllReport =0 begin

    INSERT INTO #tmpProcedureReports
    SELECT ROW_NUMBER() OVER (
            ORDER BY [name]
            ) AS id
        ,[name]
    FROM sys.procedures
    WHERE [name] LIKE ''ccspRep%''  
        AND [name] NOT IN (select nameSp from @tableSpDontProcess)
        AND [name] IN (select nameSp from ReportHighUse)        
end
else if @isAllReport =1 begin
    INSERT INTO #tmpProcedureReports
    SELECT ROW_NUMBER() OVER (
            ORDER BY [name]
            ) AS id
        ,[name]
    FROM sys.procedures
    WHERE [name] LIKE ''ccspRep%''
        AND [name] NOT IN (select nameSp from @tableSpDontProcess)
        AND [name] Not IN (select nameSp from ReportHighUse)        
end
else begin
    INSERT INTO #tmpProcedureReports
    SELECT ROW_NUMBER() OVER (
            ORDER BY [name]
            ) AS id
        ,[name]
    FROM sys.procedures
    WHERE [name] LIKE ''ccspRep%''
        AND [name] NOT IN (select nameSp from @tableSpDontProcess)        
end


exec ccspRepAgentSession @action=1,@from=@from,@to=@to --Saca el detalle de las sesiones
exec ccspRepAgentNotReadyDet @action=1,@from=@from,@to=@to --Saca el detalle de los no disponibles
exec ccspRepAgentNotReady @action=1,@from=@from,@to=@to --Agrupa a los no disponibles por hora
exec ccspRepAgentGI @action=1,@from=@from,@to=@to   --Agrupa por 15 minutos

INSERT INTO [logsReportsMaster] (name,STATUS,dateStart,dateEnd,error,maxTime)
SELECT name,0 [status]  ,''19000101'' as dateStart,''19000101'' dateEnd,'''' error,@scheduleTime
FROM #tmpProcedureReports

SELECT @i = 1, @count = count(*) FROM #tmpProcedureReports

WHILE @i <= @count  
BEGIN
    SELECT @name = name
    FROM #tmpProcedureReports
    WHERE id = @i

    SET @sql = ''EXEC '' + @name + '' @action=1, @from=@from, @to=@to''
    
    SET @dateSP = getdate()

    BEGIN TRY
        --print @sql
        
        exec sp_executesql @sql, N''@from DATETIME, @to DATETIME'',@from, @to

        UPDATE [logsReportsMaster]
        SET STATUS = 1
            ,dateStart = @dateSP
            ,dateEnd = getdate()
        WHERE name = @name
            AND STATUS = 0
            AND dateStart = ''19000101''
            AND dateEnd = ''19000101''
            
    END TRY

    BEGIN CATCH
        SELECT @descError = ''Line: '' + cast(error_line() AS NVARCHAR) + '' Number: '' + cast(@@error AS NVARCHAR) + '' Message: '' + error_message()

        SELECT @descError,@name

        UPDATE [logsReportsMaster]
        SET STATUS = 3
            ,dateStart = @dateSP
            ,dateEnd = getdate()
            ,error = @descError
        WHERE name = @name
            AND STATUS = 0
            AND dateStart = ''19000101''
            AND dateEnd = ''19000101''
    END CATCH

    SET @i = @i + 1
END

DROP TABLE #tmpProcedureReports';
    EXEC(@sql);
   -------------------------------------------  END Carlos Chavez    -------------------------------------------
	
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
