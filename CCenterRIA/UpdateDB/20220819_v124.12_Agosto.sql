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
SET @versionfix = 12
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

	    ----------------------------------GMZ | Reincio MCS --------------------------------------------------

        set @process = 'Reincio MCS se crea tabla ccDesconnectionMCS'
        set @sql = 'if not exists (select * from sys.tables where name = N''ccDesconnectionMCS'')
		begin
		    CREATE TABLE [dbo].[ccDesconnectionMCS](
			[desconnectionId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
			[timeStampDesconnection] [DATETIME] NOT NULL,
			[timeStampConnection] [DATETIME]
			
			CONSTRAINT [pk_ccRIADesconnectionMCS_1] PRIMARY KEY CLUSTERED
			(
				[desconnectionId] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			)ON [PRIMARY]
		end'
        EXEC(@sql)

        set @process = 'Reincio MCS se altera sp ccsp_ConversationWASave'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
                                              , @conversationId     INT         = 0
                                              , @inboundId          SMALLINT    = NULL
                                              , @phoneACD           VARCHAR(50) = NULL
                                              , @clientId           VARCHAR(25) = NULL
                                              , @conversationStatus SMALLINT    = 0
                                              , @tChatting          FLOAT    = 0
                                              , @tWrapUp            SMALLINT    = 0
                                              , @finishedBy         TINYINT     = 0
                                              , @onQueue            BIT         = NULL
                                              , @tQueue             SMALLINT    = 0
                                              , @tTimeout           INT         = 0
                                              , @disposition        SMALLINT    = 0
                                              , @subDisposition     SMALLINT    = 0
                                              , @agentId            INT         = 0
											  --VAR MESSAGES
											  , @messageId          VARCHAR(50) = NULL
											  , @messageIdUi        INT			= NULL
											  , @clientNum			VARCHAR(15) = NULL
											  , @vonageNum			VARCHAR(15) = NULL
											  , @typeMessage		VARCHAR(25) = ''''
											  , @content			NVARCHAR(MAX)= NULL
											  , @timeStampMessage   DATETIME	= NULL
											  , @timeStampMessageUTC DATETIME	= NULL
											  , @originType         VARCHAR(15) = NULL
											  , @currency			VARCHAR(10) = ''-''
											  ,	@price				VARCHAR(10) = ''0.00''
											  , @messageStatus		VARCHAR(15) = ''N/A''
											  , @listConversationsIds	VARCHAR(MAX) = NULL
		AS
		BEGIN
		    DECLARE @isEndConversation BIT;
		    DECLARE @meanContactTypeId SMALLINT;
			DECLARE @conversationIdNew INT;
		    SET @meanContactTypeId = 1;
		    SET NOCOUNT ON;

		    IF @action = 1
		    BEGIN --new Conversation
		        IF NOT EXISTS
		                      (SELECT A.conversationId conversationId FROM ccWhatsAppConversations A
		                       WHERE A.conversationId = @conversationId
		                      )
		        BEGIN
		            INSERT INTO [ccWhatsAppConversations]
		            (inboundId
		           , phoneACD
		           , clientId
		           , conversationStatus
		           , tChatting
		           , tWrapUp
		           , finishedBy
		           , onQueue
		           , tQueue
		           , tTimeout
		           , disposition
		           , subDisposition
		           , agentId
		            )
		            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);

					IF NOT EXISTS (SELECT WhatsAppSpamId FROM ccWhatsAppSpam WHERE NumberClient = @clientId and InboundId = @inboundId) BEGIN
						SELECT @conversationId = SCOPE_IDENTITY();
						SELECT @conversationId AS ConversationId;
					END
					ELSE BEGIN

						declare @conversationIdTemporal     INT;
						SELECT @conversationIdTemporal = SCOPE_IDENTITY();
						EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationIdTemporal, @conversationStatus = 13
						SELECT 0 AS ConversationId;
					END;

					--Save new request
					IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @inboundId)
						BEGIN
							INSERT INTO ccWAOperatingSummary (InboundId, Request) VALUES (@inboundId, 1);
						END
					ELSE
						BEGIN
							UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId
						END



		            RETURN(0);
		        END
		        ELSE
		        BEGIN
					DECLARE @conversationStatusTemp INT = @conversationStatus;
					IF @conversationStatus in(17,18) BEGIN
						SET @conversationStatusTemp = 1
					END
					 INSERT INTO [ccWhatsAppConversations]
		            (inboundId
		           , phoneACD
		           , clientId
		           , conversationStatus
		           , tChatting
		           , tWrapUp
		           , finishedBy
		           , onQueue
		           , tQueue
		           , tTimeout
		           , disposition
		           , subDisposition
		           , agentId
		            )
		            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
		            SELECT @conversationIdNew = SCOPE_IDENTITY();

					INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore
																	 , conversationIdAfter)
						VALUES (@conversationId, @conversationIdNew);
					--Save new request by reassign
					UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId

	            EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

	            SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship where conversationIdBefore = @conversationId;
	            RETURN(0);
	        END;
	    END;

	    IF @action = 2
	    BEGIN --save conversation Times
			DECLARE @conversationIdTemp INT;
			DECLARE @TablaTemp TABLE (conversationId INT, status bit);

			IF @listConversationsIds IS NOT NULL begin
				INSERT INTO @TablaTemp
				SELECT value,0
				FROM fn_RIASplitDelimited(@listConversationsIds, '','')
				where value is not null and value<>''''
			end
			else begin
				INSERT INTO @TablaTemp values(@conversationId,0)
			end

			UPDATE ccWhatsAppConversations
			SET
			conversationStatus = @conversationStatus
			, finishedBy = case when @conversationStatus = 10 then 2
				when @conversationStatus = 17 then 2
				when @conversationStatus = 18 then 2
				else 1 end
			, tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
			,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
			,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
			WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

			 WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
			BEGIN
				select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
				exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5

	            IF @conversationStatus in(13,10,17,18,11) BEGIN
					DECLARE @conversationDateTemp INT;
	                select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end from ccWhatsAppConversations where conversationId = @conversationId;

	    			IF @conversationStatus = 13 BEGIN
	    				IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
	    					INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
	    				END
	    			END
	                ELSE IF @conversationStatus in(10,17,18) BEGIN --Save conversation Ended by system
						IF @conversationDateTemp > 0 BEGIN
							UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
						END
						ELSE BEGIN
							 UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1) WHERE InboundId = @inboundId
						END
	                END
	                ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
	                    UPDATE ccWAOperatingSummary SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
	                END
	            END
				update @TablaTemp set status=1 where conversationId=@conversationIdTemp
			END

	    END;

	    IF @action = 3
	    BEGIN --save conversation Status
	        UPDATE ccWhatsAppConversations
	               SET
	                   --conversationDate = GETDATE(),
	                   conversationStatus = @conversationStatus
	        WHERE conversationId = @conversationId;
	    END;

	    IF @action = 4 BEGIN --save messages from conversation
	        IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId)
	            AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversations A WHERE A.messageId=@messageId)
	        BEGIN
	            IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
	                (SELECT messageIdUi
	                  FROM ccWAMessagesConversations
	                 WHERE originType IN (''Agent'', ''Admin'')
	                   AND conversationId = @conversationId)
	                BEGIN
	                    UPDATE ccWhatsAppConversations
	                       SET FirstMessageAgent = @timeStampMessage
	                     WHERE conversationId = @conversationId;
	                END

	            INSERT INTO [ccWAMessagesConversations](
	                                                messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
	                                               (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
	            SELECT @messageId=SCOPE_IDENTITY()
	            SELECT @messageId as MessageId
	            RETURN (0)
	        END
	        ELSE BEGIN
	            SELECT 0 AS MessageId
	            RETURN (0)
	        END
	    END;

			IF @action = 5
		    BEGIN --save onQueue
		        UPDATE ccWhatsAppConversations
		               SET onQueue = 1,
					   conversationStatus = @conversationStatus
		        WHERE conversationId = @conversationId;
				SELECT @inboundId = inboundId FROM ccWhatsAppConversations where conversationId=@conversationId;
				UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue + 1) WHERE InboundId = @inboundId
		    END;

	    IF @action = 6
	    BEGIN --save agent, assigdate and tqueue
			declare @agentIdTmp int
			SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversations A where A.conversationId = @conversationId

	        IF (@agentIdTmp is null or @agentIdTmp=0)
	        BEGIN
	            UPDATE ccWhatsAppConversations
	                   SET agentId = @agentId,
	                   assignDate = getdate(),
	                   conversationStatus = @conversationStatus
					   ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
	            WHERE conversationId = @conversationId;

	            SELECT @conversationId as conversationId
		    SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations where conversationId=@conversationId;

		    IF @onQueue = 1 BEGIN
			UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1) WHERE InboundId = @inboundId
		    END
	        END
	    END;

			IF @action = 7
		    BEGIN --update price message
		        UPDATE ccWAMessagesConversations
		               SET price = @price,
						   currency = @currency
		        WHERE messageId = @messageId;
		    END;

			IF @action = 8
		    BEGIN --update status message
				IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
					UPDATE ccWAMessagesConversations
						   SET messageStatus = @messageStatus
					WHERE messageId = @messageId;
				END;
		    END;

			IF @action = 9
		    BEGIN --Save last message time by conversationID
				IF (SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversation A WHERE A.conversationId=@conversationId) IS NULL BEGIN
					INSERT INTO ccLastMessageAgentByConversation (conversationId) VALUES (@conversationId)
				END;
				ELSE
					BEGIN
						UPDATE ccLastMessageAgentByConversation
						   SET timeStampLastMessageAgent = getDate()
						WHERE conversationId = @conversationId;
					END;
		    END;

			IF @action = 10
		    BEGIN --drop and insert register by conversationID
				DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
		    END;

			IF @action = 11
		    BEGIN --register desconnection agent by conversationID
				UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
		    END;

			IF @action = 12
		    BEGIN --Obtain conversationsWA post MCS reset

				declare @disconnectionIdTemp int = (select top 1 disconnectionId from ccDisconnectionMCS where timeStampConnection is null order by timeStampDisconnection desc);
				UPDATE ccDisconnectionMCS SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

				declare @from as datetime;-- = ''01-07-2022'';
				select @from = convert(datetime,convert(varchar(11),getdate()))
				set @from=DATEADD(dd,-1,@from);
					select A.conversationId, A.inboundId, A.phoneACD, A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, A.onQueue, A.agentId, isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
					,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
					from ccWhatsAppConversations A
					left join ccWAMessagesConversations B on A.conversationId = B.conversationId
					left join ccDisconnectionMCS C on C.disconnectionId = @disconnectionIdTemp
					--where B.conversationId is null
					where A.requestDate >= @from 
						and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
					order by agentId desc, requestDate,timeStampMessage, inboundId, clientId 
		    END;
			IF @action = 13
			BEGIN ---Obtain agents ON STATUS READY
				WITH agents
				AS(
					SELECT c.User_id, c.fecha, c.currentStatus
					FROM ccLogAgentesDia c
					INNER JOIN 
					(
					  SELECT User_id, MAX(fecha) max_time
					  FROM ccLogAgentesDia
					  GROUP BY User_id
					) AS t
					ON c.fecha = t.max_time
					AND c.User_id=t.User_id AND currentStatus in (3, 34,31)
				), usersByCampigns
				AS (
					select IdCampEsp, User_id from ccRIACampEspWG A
					Inner join ccRIAWorkGroupUsers B
					on A.IDWG = B.IDWG
					Inner join contactMeanIn C
					ON A.idCampEsp = C.inboundId
					where A.IDWG = 1 and A.Tipo = 0
					AND C.meanContactTypeId = 5
				)

				select DISTINCT A.User_Id from agents A
				left join usersByCampigns B on A.User_Id = B.User_Id
			END;

			IF @action = 14
		    BEGIN --register desconnection MCS
				INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
		    END;
		END;'
        EXEC(@sql)

        set @process = 'Reinicio MCS se altera sp ccsp_ConversationWASave'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformation]
		    @Option SMALLINT,
		    @InboundId SMALLINT = 0,
		    @ConversationId INT = 0,
			@AgentsAvailables INT = 0,
			@IncreaseDecreaseAgent BIT = NULL

		    AS
		    SET NOCOUNT ON

		    IF @InboundId IS NOT NULL BEGIN
		        IF EXISTS (SELECT * FROM ccInbound WHERE Inbound_id = @InboundId AND chat = 5) BEGIN
		            DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
		            --DECLARE @Today SMALLDATETIME = ''2022-03-24''
		            IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
		                BEGIN
		                    IF EXISTS (SELECT * FROM ccWAAverageConversations
		                               WHERE InboundId = @InboundId
		                               AND (LastUpdate IS NULL
		                               OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
		                               OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
		                    BEGIN
		                        -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

		                        DECLARE @AverageConversationTime INT = 0;
		                        DECLARE @AverageDialogTime INT = 0;
		                        DECLARE @AverageWaitingTime INT = 0;
		                        DECLARE @MaximumWaitingTime INT = 0;
		                        DECLARE @DefaultValue INT = (SELECT ISNULL(defaultServiceLevelParameter, 2) FROM contactMeanIn WHERE inboundId = @InboundId);
		                        SET @DefaultValue = @DefaultValue * 60;
		                        DECLARE @LessThanDefault INT = 0;
		                        DECLARE @ReceivedConversations INT = 0;
		                        DECLARE @ServiceLevel SMALLINT = 0;

		                        --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

		                        SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
		                               @AverageDialogTime = ROUND(AVG(tChatting), 4),
		                               @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
		                               @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
		                               @ReceivedConversations = COUNT(conversationDate),
		                               @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
		                        FROM ccWhatsAppConversations WHERE inboundId = @InboundId
		                        AND requestDate >= @Today

		                        SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

		                        ----------------------------------------------------- Update table --------------------------------------------------------

		                        IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
		                        BEGIN
		                            UPDATE ccWAAverageConversations
		                            SET AverageConversationTime = @AverageConversationTime,
		                                AverageDialogTime = @AverageDialogTime,
		                                AverageWaitingTime = @AverageWaitingTime,
		                                MaximumWaitingTime = @MaximumWaitingTime,
		                                ServiceLevel = @ServiceLevel,
		                                StatusUpdate = 0,
		                                LastUpdate = GETDATE()
		                            WHERE InboundId = @InboundId
		                        END
		                        ELSE
		                        BEGIN
		                            INSERT INTO ccWAAverageConversations (InboundId, AverageConversationTime, AverageDialogTime,
		                                                                  AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
		                            VALUES(@InboundId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
		                                   @ServiceLevel, 0 , GETDATE())
		                        END
		                    END
		                    --------------------------------- Results -----------------------------------

		                    SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
		                           ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
		                           ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
		                           ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
		                           ISNULL(ServiceLevel, 0) AS ServiceLevel,
								   ISNULL(Attended, 0) AS Attended,
								   ISNULL(Assigned, 0) AS Assigned,
								   ISNULL(OnQueue, 0) AS OnQueue,
								   ISNULL(EndedBySystem, 0) AS EndedBySystem,
								   ISNULL(Available, 0) AS Available,
								   ISNULL(Request, 0) AS Request
		                    FROM ccWAAverageConversations conv
							RIGHT JOIN ccWAOperatingSummary summary ON conv.InboundId = summary.InboundId
		                    WHERE conv.inboundId = @InboundId OR summary.InboundId = @InboundId
		                END
		            IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
		                           -- Average Queue/Waiting Time, and Service Level)
		            BEGIN
		                IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
		                    BEGIN
		                        UPDATE ccWAAverageConversations SET StatusUpdate = 1
		                        WHERE InboundId = @InboundId
		                    END
		                    ELSE
		                    BEGIN
		                        INSERT INTO ccWAAverageConversations (InboundId, StatusUpdate)
		                        VALUES(@InboundId, 1)
		                    END
		            END
		            IF @Option = 3 -- Save time from accepted conversation by agent
		            BEGIN
		                IF @ConversationId IS NOT NULL
		                BEGIN
		                    UPDATE ccWhatsAppConversations SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
							--Save Conversation Assigned
							SELECT @inboundId = inboundId FROM ccWhatsAppConversations where conversationId=@conversationId;
							UPDATE ccWAOperatingSummary SET Assigned = (Assigned + 1) WHERE InboundId = @inboundId
							--EXEC ccsp_WhatsAppOperatingSummary @Option = 2, @InboundId = @CampIdTemp;
		                END
		            END
		            IF @Option = 4 -- Get Disposition Information
		            BEGIN
		                SELECT disposition.Description AS DispositionName,
		                       disposition.calif_id AS DispositionId,
		                       COUNT(whatsConv.disposition) AS Total,
		                       disposition.GraphColor,
		                       COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
		                FROM ccWhatsAppConversations whatsConv
		                INNER JOIN cctipocalif disposition ON disposition.calif_id = whatsConv.disposition
		                WHERE inboundId = @InboundId AND assignDate >= @Today
		                GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
		            END
		            IF @Option = 5 -- Get Subdisposition Information
		            BEGIN
		                SELECT relation.calif_id AS DispositionId,
		                       subDispositions.califSubDesc AS SubDispositionsName,
		                       COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
		                FROM cctipoSubCalifRel relation
		                INNER JOIN ccTipoCalifSub subDispositions ON subDispositions.califSub_id = relation.califSub_id
		                INNER JOIN ccWhatsAppConversations whatsConv ON whatsConv.subDisposition = subDispositions.califSub_id
		                WHERE whatsConv.inboundId = @InboundId AND
		                      whatsConv.assignDate >= @Today AND
		                      relation.tipoSubRel = 1
		                GROUP BY subDispositions.califSubDesc, relation.calif_id
		            END
					IF @Option = 6 -- Agents Availables
					BEGIN
						IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @InboundId)
							BEGIN
								INSERT INTO ccWAOperatingSummary (InboundId, Available) VALUES (@InboundId, @AgentsAvailables);
							END
						ELSE
							BEGIN
								UPDATE ccWAOperatingSummary SET Available = @AgentsAvailables WHERE InboundId = @InboundId
							END
					END

		        END
		    END
			IF @Option = 0 BEGIN-- Reset TABLES
				TRUNCATE TABLE ccWAOperatingSummary;
				TRUNCATE TABLE ccWAAverageConversations;
				TRUNCATE TABLE ccLastMessageAgentByConversation;
			END
		    RETURN(0)
		    SET NOCOUNT OFF
        '
        EXEC(@sql)

		------------------------------------------------------------  END  ----------------------------------------------------------------------------------------------------------------------------------

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
