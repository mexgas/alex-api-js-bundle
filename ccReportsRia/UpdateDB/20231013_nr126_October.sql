SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 126

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	-----------------------------------------------------BEGIN Ivan Martin  K002083, K002084, K002085, K002086, K002087 -----------------------------------------------------------------

	-- BEGIN K002084 Modificar monto facturado en reporte Detalle de conversaciones -----------------------------------------------------------------

	set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
		    begin
		    DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
		    end'
	EXEC(@sql)

	SET @process = 'K002084 Se agrega la nueva columna globalid en la tabla RepWhatsAppDetailConversationIn'
	SET @sql = 'IF NOT EXISTS(SELECT * FROM sys.columns WHERE  name = N''globalid'' AND Object_ID = Object_ID(N''RepWhatsAppDetailConversationIn''))
				BEGIN
					ALTER TABLE RepWhatsAppDetailConversationIn ADD globalid INT DEFAULT 0;
				END'
	EXEC(@sql)

	SET @process = 'K002084 Se cambia nombre y tipo de dato del columa billedAmountWhatsApp a billedWhatsApp en tabla RepWhatsAppDetailConversationIn para que la UI tome la nueva traduccion'
	SET @sql = 'IF EXISTS(SELECT * FROM sys.columns WHERE  name = N''billedAmountWhatsApp'' AND Object_ID = Object_ID(N''RepWhatsAppDetailConversationIn''))
				BEGIN
					EXEC sp_rename ''RepWhatsAppDetailConversationIn.billedAmountWhatsApp'', ''billedWhatsApp'', ''COLUMN'';
					ALTER TABLE RepWhatsAppDetailConversationIn ALTER COLUMN billedWhatsApp VARCHAR(40);
				END'
	EXEC(@sql)

	SET @process = 'K002084 Se agrega columna billedWhatsApp a TranslatedReports para el reporte 12010'
	SET @sql = 'IF EXISTS(SELECT * FROM TranslatedReports WHERE id = 12010)
				BEGIN
					DELETE FROM TranslatedReports WHERE id = 12010
					INSERT INTO TranslatedReports VALUES (12010, ''contactCountry|billedWhatsApp'')
				END'
	EXEC(@sql)

	SET @process = 'K002084 Se elimina view RepViewWhatsAppDetailConversationIn'
	SET @sql = 'IF EXISTS(SELECT * FROM sys.views where name = N''RepViewWhatsAppDetailConversationIn'')
				BEGIN
					DROP VIEW RepViewWhatsAppDetailConversationIn
				END'
	EXEC(@sql)

	SET @process = 'K002084 Se crea nueva vista RepViewWhatsAppDetailConversationIn para el nuevo orden de columnas de la tabla RepWhatsAppDetailConversationIn'
	SET @sql = 'CREATE VIEW RepViewWhatsAppDetailConversationIn AS
				SELECT
					[date],
					[inboundid],
					[campaign],
					[conversationid],
					[globalid],
					[dispositionId],
					[disposition],
					[subDispositionId],
					[subDisposition],
					[associatedPhoneNumberWhatsApp],
					[userId],
					[agentName],
					[contactPhoneNumberWhatsApp],
					[contactCountry],
					[waitTimeWhatsApp],
					[conversationTimeWhatsApp],
					[billedWhatsApp],
					[year],
					[month],
					[day],
					[hour],
					[minutes]
				FROM [dbo].[RepWhatsAppDetailConversationIn]'
	EXEC(@sql)

	SET @process = 'K002084 Verifica si existe el procedure ccspRepWhatsAppDetailConversationIn'
	SET @sql = 'IF EXISTS(SELECT * FROM sys.procedures WHERE name = N''ccspRepWhatsAppDetailConversationIn'')
				BEGIN
				    DROP PROCEDURE ccspRepWhatsAppDetailConversationIn;
				END'
	EXEC(@sql)

	SET @process = 'K002084 Se modifica el procedure ccspRepWhatsAppDetailConversationIn para que contenga la nueva columna globalids y se cambia la manera de sacar el cobro con los ids globales (lineas 96 a 100, 103, 109, 110)'
	SET @sql = 'CREATE procedure [dbo].[ccspRepWhatsAppDetailConversationIn]
				@action as tinyint,
				@from as datetime = null,
				@to as datetime = null

				AS
				IF @FROM IS NULL
					SELECT @FROM = GETDATE()
					SET @FROM = DATEADD(dd, -1, @FROM)
				IF @to IS NULL
					SELECT @to = GETDATE()

				if @action = 1	begin

				    delete from RepWhatsAppDetailConversationIn where date >= @from AND date < @to

					INSERT INTO RepWhatsAppDetailConversationIn
					select A.requestDate as [date] ---A.conversationDate
				     ,A.inboundId as inboundid
					 ,B.descripcion as campaign	
					 ,A.conversationId as conversationid
					 ,A.disposition as dispositionId
					 ,isnull(disposition.Description,'''') as disposition
					 ,A.subDisposition as subDispositionId
					 ,isnull(subDisposition.califSubDesc,'''') as subDisposition
					 ,A.phoneACD as associatedPhoneNumberWhatsApp
					 ,A.agentId as userId
					 ,isnull([user].Nombres+'' ''+ [user].ApellidoPaterno+'' ''+[user].ApellidoMaterno,'''') as agentName
					 ,A.clientId as contactPhoneNumberWhatsApp
					 ,dbo.GetCountryWhatsApp(A.clientId) contactCountry
					 ,A.tQueue as waitTimeWhatsApp
					 ,isnull(A.tConversation,A.tChatting) as conversationTimeWhatsApp	
					 ,CASE WHEN globalIds.IsBilled = 1 THEN ''systemTranslated_isBilled'' ELSE ''systemTranslated_isNotBilled'' END AS billedWhatsApp
					 ,DATEPART(yyyy,A.requestDate) [year]
					 ,datepart(mm,A.requestDate) [month]
					 ,datepart(dd,A.requestDate) [day]
					 ,datepart(hh,A.requestDate) [hour]
					 ,datepart(mi,A.requestDate) [minutes]
					 ,ISNULL(globalRelation.GlobalId, 0) as globalid
					 from ccWhatsAppConversations A
					inner join ccinbound B on A.inboundId=B.Inbound_id
					left join cctipocalif disposition on disposition.calif_id=A.disposition
					left join cctipocalifsub subDisposition on subDisposition.califSub_id=A.subDisposition
					left join ccUserView [user] on [user].User_id=A.agentId
					LEFT JOIN ccWhatsAppGlobalIdsRelationship globalRelation ON globalRelation.ConversationId = A.conversationId AND ConversationType = 0
					LEFT JOIN ccWhatsAppGlobalIds globalIds ON globalRelation.GlobalId = globalIds.GlobalId AND 
															   globalIds.FirstMessageConversationIdFromAgent = A.conversationId AND
															   globalIds.FirstMessageConversationTypeFromAgent = 0
					where A.requestDate between @from AND @to
				end'
	EXEC(@sql)

	SET @process = 'K002084 Verifica si existe el procedure ccspRepWhatsAppByCampaignIn'
	SET @sql = 'IF EXISTS(SELECT * FROM sys.procedures WHERE name = N''ccspRepWhatsAppByCampaignIn'')
				BEGIN
				    DROP PROCEDURE ccspRepWhatsAppByCampaignIn;
				END'
	EXEC(@sql)

	SET @process = 'K002084 Se modifica ccspRepWhatsAppByCampaignIn para cambiar la manera de sacar la fecha'
	SET @sql = 'CREATE procedure [dbo].[ccspRepWhatsAppByCampaignIn]
				@action as tinyint,
				@from as datetime = null,
				@to as datetime = null

				AS
				IF @FROM IS NULL
					SELECT @FROM = GETDATE()
					SET @FROM = DATEADD(dd, -1, @FROM)
				IF @to IS NULL
					SELECT @to = GETDATE()

				if @action = 1	begin

					delete from RepWhatsAppByCampaignIn with(rowlock)	where date >= @from AND date < @to ;
	
					WITH conv
					AS (
						SELECT convert(date, A.requestDate) AS [date]
						,A.inboundId AS inboundid
						,B.descripcion as campaign		 
						,A.phoneACD AS associatedPhoneNumberWhatsApp
						,dbo.GetCountryWhatsApp(A.clientId) contactCountry
						,count(DISTINCT clientId) totalContactsWhatsApp------
						,count(A.requestDate) AS totalConversationsWhatsApp
						,count(CASE 
									WHEN agentId > 0
										THEN 1
									ELSE NULL
									END) numberAssignedMessagesWhatsApp
						,ISNULL(MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),0) as maxWaitTimeWhatsApp
						,ISNULL(ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),0) as avgWaitTimeWhatsApp
						,count(CASE 
									WHEN conversationStatus = 13
										THEN 1
									ELSE NULL
									END) spamWhatsApp
						,0 as serviceLevelWhats
						,count(CASE 
									WHEN conversationStatus = 17
										THEN 1
									ELSE NULL
									END) contactFinishedConversationsWhatApp
						,count(CASE 
									WHEN conversationStatus = 11
										THEN 1
									ELSE NULL
									END) agentFinishedConversationsWhatApp
						,count(CASE 
									WHEN conversationStatus = 17
										THEN 1
									ELSE NULL
									END) systemFinishedConversationsWhatsApp
						,COUNT(conversationDate) receivedConversations
						,COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= (ISNULL(C.defaultServiceLevelParameter, 2) * 60) THEN 1 ELSE NULL END) lessThanDefault
						FROM ccWhatsAppConversations A
						inner join ccinbound B on A.inboundId=B.Inbound_id
						LEFT JOIN contactMeanIn C on A.inboundId = c.inboundId 
						WHERE A.requestDate 
							BETWEEN @from
								AND @to
						GROUP BY convert(DATE, A.requestDate), A.inboundId, B.descripcion, A.phoneACD, dbo.GetCountryWhatsApp(A.clientId)
						), numSentMsg
					AS (
						SELECT convert(DATE, conv.requestDate) date, conv.inboundId, conv.phoneACD associatedPhoneNumberWhatsApp, count(CASE 
									WHEN Msg.originType IN (''Agent'', ''Admin'')
										THEN 1
									ELSE NULL
									END) numberMsgClientConversation, count(CASE 
									WHEN Msg.originType IN (''Client'')
										THEN 1
									ELSE NULL
									END) numberMsgReceivedWhats
						FROM ccWAMessagesConversations Msg
						INNER JOIN ccWhatsAppConversations conv ON Msg.conversationId = conv.conversationId	
						WHERE conv.conversationDate BETWEEN @from
								AND @to
						GROUP BY convert(DATE, conv.requestDate), conv.inboundId, conv.phoneACD
						)

					INSERT INTO RepWhatsAppByCampaignIn
						SELECT A.date, A.inboundid, A.campaign, A.associatedPhoneNumberWhatsApp, ISNULL(B.numberMsgClientConversation,0) numberSentMessagesWhatsApp, A.totalContactsWhatsApp, ISNULL(B.numberMsgReceivedWhats,0), A.contactCountry, A.totalConversationsWhatsApp, A.numberAssignedMessagesWhatsApp, A.maxWaitTimeWhatsApp, A.avgWaitTimeWhatsApp,
							   A.spamWhatsApp, CASE WHEN A.receivedConversations = 0 THEN 0 ELSE ROUND(((A.lessThanDefault*1.0) / A.receivedConversations) * 100, 2) END serviceLevelWhats, A.contactFinishedConversationsWhatApp, A.agentFinishedConversationsWhatApp, A.systemFinishedConversationsWhatsApp ,DATEPART(yyyy,A.[DATE]) [year]
							,datepart(mm,A.[DATE]) [month]
							,datepart(dd,A.[DATE]) [day]
							,0 [hour]
							,0 [minutes]
						FROM conv A
						LEFT JOIN numSentMsg B ON A.DATE = B.DATE
							AND A.inboundId = B.inboundId
							AND A.associatedPhoneNumberWhatsApp = B.associatedPhoneNumberWhatsApp
				end'
	EXEC(@sql)

	-- END K002084 Modificar monto facturado en reporte Detalle de conversaciones -----------------------------------------------------------------

	-- BEGIN K002085 - Detalle de conversaciones de salida y K002086-Conversaciones de salida por campaña WhatsApp -----------------------------------------------------------------

	SET @process = 'K002085 y K002086 Se crea nueva tabla RepWhatsAppByCampaignOut'
	SET @sql = 'IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = N''RepWhatsAppByCampaignOut'')
				BEGIN
				    CREATE TABLE [dbo].[RepWhatsAppByCampaignOut](
					[date] [DATE] NOT NULL,
					[campaignId] [INT] NOT NULL,
					[campaign] [VARCHAR](50) NOT NULL,
					[associatedPhoneNumberWhatsApp] [VARCHAR](40) NOT NULL,	
					[numberSentMessagesWhatsApp] [VARCHAR](40) NOT NULL,
					[totalContactsWhatsApp] [INT] NOT NULL,
					[numberMsgReceivedWhats] [INT] NOT NULL,
					[contactCountry] [VARCHAR](50) NOT NULL,
					[totalConversationsWhatsApp] [INT] NOT NULL,
					[numberAssignedMessagesWhatsApp] [INT] NOT NULL,
					[maxWaitTimeWhatsApp] [INT] NULL,
					[avgWaitTimeWhatsApp] [INT] NOT NULL,
					[spamWhatsApp] [INT] NOT NULL,
					[serviceLevelWhats] [INT] NOT NULL,
					[contactFinishedConversationsWhatApp] [INT] NOT NULL,
					[agentFinishedConversationsWhatApp] [INT] NOT NULL,
					[systemFinishedConversationsWhatsApp] [INT] NOT NULL,
					[year] [SMALLINT] NOT NULL,
					[month] [SMALLINT] NOT NULL,
					[day] [SMALLINT] NOT NULL,
					[hour] [SMALLINT] NOT NULL,
					[minutes] [SMALLINT] NOT NULL)
				END'
	EXEC(@sql)

	SET @process = 'K002085 y K002086 Se crea índice de RepWhatsAppByCampaignOut'
	SET @sql = 'IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = N''IX_RepWhatsAppByCampaignOut'' AND object_id = OBJECT_ID(N''RepWhatsAppByCampaignOut''))
				BEGIN
					CREATE INDEX IX_RepWhatsAppByCampaignOut ON RepWhatsAppByCampaignOut(date, campaignId);
				END'
	EXEC(@sql)

	SET @process = 'K002085 y K002086 Se crea nueva tabla RepWhatsAppDetailConversationOut'
	SET @sql = 'IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = N''RepWhatsAppDetailConversationOut'')
				BEGIN
				    CREATE TABLE [dbo].[RepWhatsAppDetailConversationOut](
					[date] [DATETIME] NOT NULL,
					[campaignId] [INT] NOT NULL,
					[campaign] [VARCHAR](50) NOT NULL,
					[conversationid] [INT] NOT NULL,	
					[globalid] [INT] NOT NULL,	
					[dispositionId] [SMALLINT] NOT NULL,
					[disposition] [VARCHAR](60) NOT NULL,
					[subDispositionId] [SMALLINT] NOT NULL,
				    [subDisposition] [VARCHAR](60) NOT NULL,
					[associatedPhoneNumberWhatsApp] [VARCHAR](40) NOT NULL,
					[userId] [INT] NOT NULL,
					[agentName] [VARCHAR](100) NOT NULL,
					[contactPhoneNumberWhatsApp] [VARCHAR](40) NULL,
					[contactCountry] [VARCHAR](50) NOT NULL,
					[waitTimeWhatsApp] [INT] NOT NULL,
					[conversationTimeWhatsApp] [INT] NOT NULL,
					[billedWhatsApp] [VARCHAR](40) NOT NULL,
					[year] [SMALLINT] NOT NULL,
					[month] [SMALLINT] NOT NULL,
					[day] [SMALLINT] NOT NULL,
					[hour] [SMALLINT] NOT NULL,
					[minutes] [SMALLINT] NOT NULL)
				END'
	EXEC(@sql)

	SET @process = 'K002085 y K002086 Se crea índice de RepWhatsAppDetailConversationOut'
	SET @sql = 'IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = N''IX_RepWhatsAppDetailConversationOut'' AND object_id = OBJECT_ID(N''RepWhatsAppDetailConversationOut''))
				BEGIN
					CREATE INDEX IX_RepWhatsAppDetailConversationOut ON RepWhatsAppDetailConversationOut(date, campaignId, userId);
				END'
	EXEC(@sql)

	SET @process = 'K002085 y K002086 Se agregan los filtros y traducciones'
	SET @sql = '-- Outbound WhatsApp Filters

				-- Conversations Detail
				IF NOT EXISTS(SELECT * FROM ReportsFiltersMenus WHERE IdReport = 14010)
				BEGIN
					INSERT INTO ReportsFiltersMenus(idReport, filterMenuName) VALUES(14010, N''date'')
					INSERT INTO ReportsFiltersMenus(idReport, filterMenuName) VALUES(14010, N''filterby'')
				END

				-- Conversations by Campaign
				IF NOT EXISTS(SELECT * FROM ReportsFiltersMenus WHERE IdReport = 14020)
				BEGIN
					INSERT INTO ReportsFiltersMenus(idReport, filterMenuName) VALUES(14020, N''date'')
					INSERT INTO ReportsFiltersMenus(idReport, filterMenuName) VALUES(14020, N''filterby'')
				END

				-- Conversations Detail
				IF NOT EXISTS(SELECT * FROM ReportsFilters WHERE id = 14010)
				BEGIN
					INSERT INTO ReportsFilters VALUES(''Answered Calls Detail'', ''campaigns'', 14010)
					INSERT INTO ReportsFilters VALUES(''Answered Calls Detail'', ''users'', 14010)
				END

				-- Conversations by Campaign
				IF NOT EXISTS(SELECT * FROM ReportsFilters WHERE id = 14020)
				BEGIN
					INSERT INTO ReportsFilters VALUES(''Answered Calls Detail'', ''campaigns'', 14020)
				END

				-- Both
				IF NOT EXISTS(SELECT * FROM TranslatedReports WHERE id IN(14010, 14020))
				BEGIN
					INSERT INTO TranslatedReports VALUES(14010, ''contactCountry|billedWhatsApp|isBilled|isNotBilled'')
					INSERT INTO TranslatedReports VALUES(14020, ''contactCountry'')
				END'
	EXEC(@sql)

	SET @process = 'K002085 y K002086 Se agregan filtros para totales'
	SET @sql = '-- Conversations Detail
				IF NOT EXISTS(SELECT * FROM ReportsTotals WHERE id = ''14010'')
				BEGIN 
					INSERT INTO ReportsTotals VALUES (14010, ''sum:tQueue|sum:tConversation'')
				END

				-- Conversations by Campaign
				IF NOT EXISTS(SELECT * FROM ReportsTotals WHERE id = ''14020'')
				BEGIN 
					INSERT INTO ReportsTotals VALUES (14020, ''sum:numberSentMessagesWhatsApp|sum:totalContactsWhatsApp|sum:numberMsgReceivedWhats|sum:totalConversationsWhatsApp|sum:numberAssignedMessagesWhatsApp|sum:maxWaitTimeWhatsApp|sum:avgWaitTimeWhatsApp|sum:spamWhatsApp|sum:contactFinishedConversationsWhatApp|sum:agentFinishedConversationsWhatApp|sum:systemFinishedConversationsWhatsApp'')
				END'
	EXEC(@sql)

	SET @process = 'K002085 y K002086 Verifica si existe el procedure ccspRepWhatsAppDetailConversationOut'
	SET @sql = 'IF EXISTS(SELECT * FROM sys.procedures WHERE name = N''ccspRepWhatsAppDetailConversationOut'')
				BEGIN
				    DROP PROCEDURE ccspRepWhatsAppDetailConversationOut;
				END'
	EXEC(@sql)

	SET @process = 'K002085 y K002086 Verifica si existe el procedure ccspRepWhatsAppByCampaignOut'
	SET @sql = 'IF EXISTS(SELECT * FROM sys.procedures WHERE name = N''ccspRepWhatsAppByCampaignOut'')
				BEGIN
				    DROP PROCEDURE ccspRepWhatsAppByCampaignOut;
				END'
	EXEC(@sql)

	SET @process = 'K002085 y K002086 Se crea nuevo SP ccspRepWhatsAppDetailConversationOut'
	SET @sql = 'CREATE procedure [dbo].[ccspRepWhatsAppDetailConversationOut]
				@actiON AS TINYINT,
				@FROM AS DATETIME = NULL,
				@to AS DATETIME = NULL

				AS
				IF @FROM IS NULL
					SELECT @FROM = GETDATE()
					SET @FROM = DATEADD(dd, -1, @FROM)
				IF @to IS NULL
					SELECT @to = GETDATE()

				IF @actiON = 1	begin
				    DELETE FROM RepWhatsAppDetailConversationOut WHERE date >= @FROM AND date < @to

					INSERT INTO RepWhatsAppDetailConversationOut
					SELECT A.requestDate AS [date] 
				     	  ,A.camId AS campaignId
						  ,B.cam_descripcion AS campaign	
						  ,A.conversationId AS conversationid
						  ,ISNULL(globalRelation.GlobalId, 0) as globalid
						  ,A.disposition AS dispositionId
						  ,ISNULL(disposition.Description,'''') AS disposition
						  ,A.subDisposition AS subdispositionId
						  ,ISNULL(subDisposition.califSubDesc,'''') AS subDisposition
						  ,A.phoneCamp AS associatedPhoneNumberWhatsApp
						  ,A.agentId AS userId
						  ,ISNULL([user].Nombres+'' ''+ [user].ApellidoPaterno+'' ''+[user].ApellidoMaterno,'''') AS agentName
						  ,A.clientId AS contactPhoneNumberWhatsApp
						  ,dbo.GetCountryWhatsApp(A.clientId) contactCountry
						  ,A.tQueue AS waitTimeWhatsApp
						  ,ISNULL(A.tCONversatiON,A.tChatting) AS conversationTimeWhatsApp	
						  ,CASE WHEN globalIds.IsBilled = 1 THEN ''systemTranslated_isBilled'' ELSE ''systemTranslated_isNotBilled'' END AS billedWhatsApp
						  ,DATEPART(yyyy,A.requestDate) [year]
						  ,DATEPART(mm,A.requestDate) [mONth]
						  ,DATEPART(dd,A.requestDate) [day]
						  ,DATEPART(hh,A.requestDate) [hour]
						  ,DATEPART(mi,A.requestDate) [minutes]
					FROM ccWhatsAppConversationsOut A
					INNER JOIN ccCamps B ON A.camId=B.cam_id
					LEFT JOIN cctipocalifout disposition ON disposition.calif_id = A.disposition
					LEFT JOIN cctipocalifsubout subDISpositiON ON subDISpositiON.califSub_id=A.subDISpositiON
					LEFT JOIN ccUserView [user] ON [user].User_id=A.agentId
					LEFT JOIN ccWhatsAppGlobalIdsRelationship globalRelation ON globalRelation.ConversationId = A.conversationId AND ConversationType = 1
					LEFT JOIN ccWhatsAppGlobalIds globalIds ON globalRelation.GlobalId = globalIds.GlobalId AND 
															   globalIds.FirstMessageConversationIdFromAgent = A.conversationId AND
															   globalIds.FirstMessageConversationTypeFromAgent = 1
					WHERE A.requestDate between @FROM AND @to
				END'
	EXEC(@sql)

	SET @process = 'K002085 y K002086 Se crea nuevo SP ccspRepWhatsAppByCampaignOut'
	SET @sql = 'CREATE procedure [dbo].[ccspRepWhatsAppByCampaignOut]
					 @action AS TINYINT,
					 @FROM AS DATETIME = NULL,
					 @to AS DATETIME = NULL

				AS
				IF @FROM IS NULL
					SELECT @FROM = GETDATE()
					SET @FROM = DATEADD(dd, -1, @FROM)
				IF @to IS NULL
					SELECT @to = GETDATE()

				IF @action = 1	BEGIN

					DELETE FROM RepWhatsAppByCampaignOut with(rowlock)	WHERE date >= @FROM AND date < @to ;
					
					WITH conv
					AS (
						SELECT A.requestDate AS [date]
						,A.camId AS cam_id
						,B.cam_descripcion AS campaign		 
						,A.phoneCamp AS AssociatedPhoneNumberWhatsApp
						,dbo.GetCountryWhatsApp(A.clientId) contactCountry
						,COUNT(DISTINCT clientId) totalContactsWhatsApp------
						,COUNT(A.requestDate) AS totalConversationsWhatsApp
						,COUNT(CASE 
									WHEN agentId > 0
										THEN 1
									ELSE NULL
									END) numberASsignedMessagesWhatsApp
						,ISNULL(MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),0) AS maxWaitTimeWhatsApp
						,ISNULL(ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),0) AS avgWaitTimeWhatsApp
						,COUNT(CASE 
									WHEN conversationStatus = 13
										THEN 1
									ELSE NULL
									END) spamWhatsApp
						,0 AS serviceLevelWhats  -- Cambiar cuando se tenga nivel de servicio
						,COUNT(CASE 
									WHEN conversationStatus = 17
										THEN 1
									ELSE NULL
									END) contactFinIShedConversationsWhatApp
						,COUNT(CASE 
									WHEN conversationStatus = 11
										THEN 1
									ELSE NULL
									END) agentFinIShedConversationsWhatApp
						,COUNT(CASE 
									WHEN conversationStatus = 17
										THEN 1
									ELSE NULL
									END) systemFinIShedConversationsWhatsApp
						,COUNT(conversationDate) receivedConversations
				        --,COUNT(CASE WHEN DATEDIFF(SECOND, AssignDate , FirstMessageAgent) <= (ISNULL(C.defaultServiceLevelParameter, 2) * 60) THEN 1 ELSE NULL END) lessThanDefault
						FROM ccWhatsAppConversationsOut A
						INNER join ccCamps B on A.camId=B.cam_id
						LEFT JOIN contactMeanOut C on A.camId = c.camp_id 
						WHERE A.requestDate 
							BETWEEN @FROM
								AND @to
						GROUP BY  A.requestDate, A.camId, B.cam_descripcion, A.phoneCamp, dbo.GetCountryWhatsApp(A.clientId)
						), numSentMsg
					AS (
						SELECT  conv.requestDate date, conv.camId, conv.phoneCamp ASsociatedPhoneNumberWhatsApp, COUNT(CASE 
									WHEN Msg.originType IN (''Agent'', ''Admin'')
										THEN 1
									ELSE NULL
									END) numberMsgClientConversation, COUNT(CASE 
									WHEN Msg.originType IN (''Client'')
										THEN 1
									ELSE NULL
									END) numberMsgReceivedWhats
						FROM ccWAMessagesConversationsOut Msg
						INNER JOIN ccWhatsAppConversationsOut conv ON Msg.conversationId = conv.conversationId	
						WHERE conv.conversationDate BETWEEN @FROM
								AND @to
						GROUP BY  conv.requestDate, conv.camId, conv.phoneCamp
						)

					INSERT INTO RepWhatsAppByCampaignOut
					SELECT CONVERT(DATE,A.date), A.cam_id, A.campaign, A.ASsociatedPhoneNumberWhatsApp, ISNULL(B.numberMsgClientConversation,0) numberSentMessagesWhatsApp, A.totalContactsWhatsApp, ISNULL(B.numberMsgReceivedWhats,0), A.contactCountry, A.totalConversationsWhatsApp, A.numberASsignedMessagesWhatsApp, A.maxWaitTimeWhatsApp, A.avgWaitTimeWhatsApp,
						   A.spamWhatsApp, 0 serviceLevelWhats, A.contactFinIShedConversationsWhatApp, A.agentFinIShedConversationsWhatApp, A.systemFinIShedConversationsWhatsApp ,DATEPART(yyyy,A.[DATE]) [year]
						   ,DATEPART(mm,A.[DATE]) [month]
						   ,DATEPART(dd,A.[DATE]) [day]
						   ,0
						   ,0
					FROM conv A
					LEFT JOIN numSentMsg B ON A.DATE = B.DATE
					AND A.cam_id = B.camId
					AND A.AssociatedPhoneNumberWhatsApp = B.AssociatedPhoneNumberWhatsApp
				END'
	EXEC(@sql)


	set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
	        begin
	        ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
	        end'
	EXEC(@sql)
	
	-- BEGIN K002085 - Detalle de conversaciones de salida y K002086-Conversaciones de salida por campaña WhatsApp -----------------------------------------------------------------

	-----------------------------------------------------END Ivan Martin  K002083, K002084, K002085, K002086, K002087 -----------------------------------------------------------------
	
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
