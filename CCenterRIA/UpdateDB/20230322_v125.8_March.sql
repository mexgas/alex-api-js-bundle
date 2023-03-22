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
		-------------------------------------------- BEGIN IVAN OUTBOUND HISTORICAL CHAT ------------------------------
		SET @process = 'DEV1-19 Alter ccsp_AgentHistoricalChat se agrega camp type en option 1, 2, 4, y 5 para traer también conversaciones de salida'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentHistoricalChat] 
					@option SMALLINT, 
					@clientNum VARCHAR(15) = '''', 
					@conversationId AS INT = 0, 
					@inboundId AS SMALLINT = 0, 
					@serviceType AS SMALLINT = 0,
					@campType AS INT = 0
		            AS
		            BEGIN
		                IF @option = 1 --whatsapp, get conversation ids
		                BEGIN
							DECLARE @tempId INT = 0
							IF @campType = 0 -- INBOUND
							BEGIN
								SELECT conversationId
								FROM ccWhatsAppConversations
								WHERE clientId = @clientNum 
								GROUP BY conversationId
							END
							ELSE
							BEGIN  -- OUTBOUND
								SELECT conversationId
								FROM ccWhatsAppConversationsOut
								WHERE clientId = @clientNum 
								GROUP BY conversationId
							END
		                END

		                IF @option = 2 --whatsapp, get acdId by conversation id
		                BEGIN
							IF @campType = 0
							BEGIN
								SELECT CAST(inboundId AS INT)
								FROM [CCenterRIA].[dbo].[ccWhatsAppConversations]
								WHERE conversationId = @conversationId
							END
							ELSE
							BEGIN
								SELECT CAST(camId AS INT)
								FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsOut]
								WHERE conversationId = @conversationId
							END
		                END

		                IF @option = 3 --get data conversation
		                BEGIN
		                    DECLARE @OldAgentId INT = 0
		                    DECLARE @OldConversationId INT = 0

		                    SELECT @OldAgentId = conv.agentId, @OldConversationId = rel.conversationIdBefore
		                    FROM ccWhatsAppConversationsRelationship rel
		                    RIGHT JOIN ccWhatsAppConversations conv ON conv.conversationId = rel.conversationIdBefore
		                    WHERE rel.conversationIdAfter = @conversationId

		                    SELECT cast(i.chat AS INT) AS ServiceType, cast(c.conversationId AS INT) AS ConversationID, c.clientId AS ClientId, cm.conexionInfo AS [To], cast(i.Inbound_id AS INT) AS ACDId, i.descripcion AS ACDName, cast(g.
		                            graphic_id AS INT) AS ACDGraphicId, cast(cm.closeConversationTime AS INT) AS [TimeOut], cast(cm.answerTimeOut AS INT) AS [TimeOutWarning], i.ExitWrapUpDisposition AS [ExitWrapUpDisposition], i.tNotas AS 
		                        [WrapUpTime], i.ShowCalifWnd, cast(ISNULL(answerTimeoutClient, 30) AS INT) AS [AnswerTimeoutClient], ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS 
		                        [SecTimeOutLastMessageAgent], isnull(permission.AllowUnassign, 0) AS AllowUnassign, isnull(permission.AllowSpam, 0) AS AllowSpam, ISNULL(@OldAgentId, 0) AS OldAgentId, ISNULL(@OldConversationId, 0) AS 
		                        OldConversationId, c.agentId AS AgentId
		                    FROM ccInbound i
		                    INNER JOIN contactMeanIn cm ON i.Inbound_id = cm.inboundId
		                    INNER JOIN ccWhatsAppConversations c ON (
		                            c.inboundId = i.Inbound_id
		                            AND c.conversationId = @conversationId
		                            )
		                    INNER JOIN ccRIAInboundGraph g ON g.Inbound_id = i.Inbound_id
		                    LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
		                    LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
		                    WHERE i.chat = @serviceType
		                        AND i.Inbound_id = @inboundId

		                END

		                IF @option = 4 --get messages from conversation id
		                BEGIN
							DECLARE @filetype AS VARCHAR(5)

							IF @campType = 0
							BEGIN

								SELECT messageId AS MessageId, messageStatus AS STATUS, originType AS Origin, CASE 
		                        WHEN originType = ''Client''
		                            THEN 3
		                        WHEN originType = ''Agent''
		                            THEN 2
		                        WHEN originType = ''Admin''
		                            THEN 1
		                        ELSE 0
		                        END AS OriginType, timeStampMessage AS [Timestamp], CASE 
		                        WHEN typeMessage <> ''text''
		                            THEN ''''
		                        ELSE content
		                        END AS Content, typeMessage AS Type, CASE 
		                        WHEN typeMessage NOT IN (''text'', ''location'')
		                            THEN content
		                        ELSE ''''
		                        END AS Caption, CASE 
		                        WHEN originType = ''Client''
		                            THEN CASE 
		                                    WHEN typeMessage = ''text''
		                                        OR typeMessage = ''location''
		                                        THEN ''''
		                                    ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
		                                        typeMessage + CHAR(92) + CHAR(92) + messageId + ''.'' + CASE 
		                                            WHEN typeMessage = ''video''
		                                                THEN ''mp4''
		                                            WHEN typeMessage = ''image''
		                                                THEN ''jpg''
		                                            WHEN typeMessage = ''audio''
		                                                THEN ''mp3''
		                                            WHEN typeMessage = ''file''
		                                                THEN (
		                                                        SELECT substring(content, CHARINDEX(''.'', content) + 1, len(content))
		                                                        )
		                                            ELSE ''''
		                                            END
		                                    END
		                        ELSE CASE 
		                                WHEN typeMessage = ''text''
		                                    OR typeMessage = ''location''
		                                    THEN ''''
		                                ELSE content
		                                END
		                        END AS [Url], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 1
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Address], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 2
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Lat], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 3
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Long], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 4
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Name], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN ''https://www.google.com/maps/search/'' + (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 2
		                                                ), '':'')
		                                    WHERE id = 2
		                                    ) + '','' + (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 3
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [LocationURL]
								FROM ccWAMessagesConversations
								WHERE conversationId = @conversationId
								ORDER BY TIMESTAMP ASC
							END
							ELSE
							BEGIN
								SELECT messageId AS MessageId, messageStatus AS STATUS, originType AS Origin, CASE 
		                        WHEN originType = ''Client''
		                            THEN 3
		                        WHEN originType = ''Agent''
		                            THEN 2
		                        WHEN originType = ''Admin''
		                            THEN 1
		                        ELSE 0
		                        END AS OriginType, timeStampMessage AS [Timestamp], CASE 
		                        WHEN typeMessage <> ''text''
		                            THEN ''''
		                        ELSE content
		                        END AS Content, typeMessage AS Type, CASE 
		                        WHEN typeMessage NOT IN (''text'', ''location'')
		                            THEN content
		                        ELSE ''''
		                        END AS Caption, CASE 
		                        WHEN originType = ''Client''
		                            THEN CASE 
		                                    WHEN typeMessage = ''text''
		                                        OR typeMessage = ''location''
		                                        THEN ''''
		                                    ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
		                                        typeMessage + CHAR(92) + CHAR(92) + messageId + ''.'' + CASE 
		                                            WHEN typeMessage = ''video''
		                                                THEN ''mp4''
		                                            WHEN typeMessage = ''image''
		                                                THEN ''jpg''
		                                            WHEN typeMessage = ''audio''
		                                                THEN ''mp3''
		                                            WHEN typeMessage = ''file''
		                                                THEN (
		                                                        SELECT substring(content, CHARINDEX(''.'', content) + 1, len(content))
		                                                        )
		                                            ELSE ''''
		                                            END
		                                    END
		                        ELSE CASE 
		                                WHEN typeMessage = ''text''
		                                    OR typeMessage = ''location''
		                                    THEN ''''
		                                ELSE content
		                                END
		                        END AS [Url], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 1
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Address], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 2
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Lat], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 3
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Long], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 4
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Name], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN ''https://www.google.com/maps/search/'' + (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 2
		                                                ), '':'')
		                                    WHERE id = 2
		                                    ) + '','' + (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 3
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [LocationURL]
								FROM ccWAMessagesConversationsOut
								WHERE conversationId = @conversationId
								ORDER BY TIMESTAMP ASC
							END
		                    
		                END

		                IF @option = 5 --get if conversation is reassigned
		                BEGIN
							IF @campType = 0
							BEGIN
								SELECT CASE 
		                            WHEN EXISTS (
		                                    SELECT *
		                                    FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationship]
		                                    WHERE conversationIdAfter = @conversationId
		                                    )
		                                THEN CAST(1 AS BIT)
		                            ELSE CAST(0 AS BIT)
		                            END
							END
							ELSE
							BEGIN
								SELECT CASE 
		                            WHEN EXISTS (
		                                    SELECT *
		                                    FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationshipOut]
		                                    WHERE conversationIdAfter = @conversationId
		                                    )
		                                THEN CAST(1 AS BIT)
		                            ELSE CAST(0 AS BIT)
		                            END
							END
		                END
		            END'
		            exec (@sql)
		            
		-------------------------------------------- END IVAN OUTBOUND HISTORICAL CHAT ------------------------------
		SET @process = 'DEV1-19 Alter ccsp_SaveDispositionsMultimedia Se modifica para que tengamos option @mediaType 7 cuando es WhatsApp ccWhatsAppConversationsOut'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_SaveDispositionsMultimedia] @action         INT
                                                      , @conversationId bigint      = 0
                                                      , @disposition    SMALLINT = 0
                                                      , @subDisposition SMALLINT = 0
                                                      , @tWrapUp        SMALLINT = 0
                                                      , @mediaType      SMALLINT = 0
													  , @campType bit =0
AS
BEGIN

    SET NOCOUNT ON;

    IF @action = 1
    BEGIN --Califica la conversación y pone el tiempo Notas
        DECLARE @Temp NVARCHAR(1000),@tableName NVARCHAR(255),@type int
		
		set @mediaType= CASE when @mediaType=5 and @campType=1 then 7 else @mediaType end
		set @type=CASE @mediaType WHEN 6 then 1 else @mediaType end ---revisar tabla ccfinderServices

		set @tableName= CASE @mediaType 
					WHEN 5 THEN ''ccWhatsAppConversations'' 
					WHEN 6 THEN ''chat'' 
					WHEN 7 THEN ''ccWhatsAppConversationsOut'' 
					ELSE '''' END

		set @Temp= N''UPDATE '' +
                @tableName + '' SET disposition= @disposition ,subDisposition= @subDisposition ,tWrapUp= @tWrapUp WHERE conversationId= @conversationId;'';
        EXEC sp_executesql
             @temp
           , N''@disposition SMALLINT, @subDisposition SMALLINT, @tWrapUp SMALLINT, @conversationId INT''
           , @disposition
           , @subDisposition
           , @tWrapUp
           , @conversationId;


		exec ccsp_CreateNodeMultimedia @conversationId=@conversationId, @type=@type

    END;
END; '
	
		exec (@sql)
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