/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: David Medina Medina
Date: 2024/09/30
Description: Release 126.20240930.0.0
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
SET @versionfix = 22
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
    	
		------------------------------------------------- BEGIN MARCO GARCÍA----------------------------------------------------------------------------------
		------------------------------------------------------- Tablas ------------------------------------------------------------------------------------------
		SET @process = 'K002091 - Descargar conversaciones entrada Whatsapp con adjuntos - Se crea la tabla ccFinderWhatsAppDownloadedMessage'
		SET @sql = '
			IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = ''ccFinderWhatsAppDownloadedMessage'')
			BEGIN
				CREATE TABLE [dbo].ccFinderWhatsAppDownloadedMessage(
					[FinderWhatsAppMessageId] [INT] PRIMARY KEY NOT NULL,
					[Description] VARCHAR(400) NOT NULL,
					[OpTagEs] [VARCHAR](250) NOT NULL,
					[OpTagEn] [VARCHAR](250) NOT NULL,
					[OpTagPt] [VARCHAR](250) NOT NULL
				)
			END '
		EXEC(@sql)


		SET @process = 'K002091 - Descargar conversaciones entrada Whatsapp con adjuntos - Se agregan registros a la tabla ccFinderWhatsAppDownloadedMessage '
		SET @sql = '
			IF NOT EXISTS (SELECT 1 FROM ccFinderWhatsAppDownloadedMessage WHERE FinderWhatsAppMessageId = 1)
			BEGIN
				INSERT INTO dbo.ccFinderWhatsAppDownloadedMessage
				(
					FinderWhatsAppMessageId,
					Description,
					OpTagEs,
					OpTagEn,
					OpTagPt
				)
				VALUES
				(   1,  -- FinderWhatsAppMessageId - int
					''Nombre de la carpeta que contendrá los adjuntos de la conversación'', -- Description - varchar(400)
					''Adjuntos'', -- OpTagEs - varchar(250)
					''Attachments'', -- OpTagEn - varchar(250)
					''Anexos''  -- OpTagPt - varchar(250)
					),
					(   2,  -- FinderWhatsAppMessageId - int
					''Nombre del archivo que contendrá los archivos que no se pudieron descargar y el por qué'', -- Description - varchar(400)
					''Adjuntos no descargados'', -- OpTagEs - varchar(250)
					''Attachments not downloaded'', -- OpTagEn - varchar(250)
					''Anexos não baixados''  -- OpTagPt - varchar(250)
					),
					(   3,  -- FinderWhatsAppMessageId - int
					''Titulo que lleva el archivo txt que contiene los archivos no descargados'', -- Description - varchar(400)
					''Adjuntos no descargados'', -- OpTagEs - varchar(250)
					''Attachments not downloaded'', -- OpTagEn - varchar(250)
					''Anexos não baixados''  -- OpTagPt - varchar(250)
					),
					(   4,  -- FinderWhatsAppMessageId - int
					''Mensaje de conexión que se incluira al archivo que contiene los no descargados'', -- Description - varchar(400)
					''Error: No se puede establecer comunicación con el servidor.'', -- OpTagEs - varchar(250)
					''Error: Unable to connect to the server.'', -- OpTagEn - varchar(250)
					''Erro: Não é possível se conectar ao servidor.''  -- OpTagPt - varchar(250)
					),
					(   5,  -- FinderWhatsAppMessageId - int
					''Mensaje de cleanup que se incluira al archivo que contiene los no descargados'', -- Description - varchar(400)
					''Error: No se puede encontrar el archivo. El servidor fue depurado'', -- OpTagEs - varchar(250)
					''Error: Unable to find file. The server was cleaned up.'', -- OpTagEn - varchar(250)
					''Erro: Não é possível localizar o arquivo. O servidor foi limpo.''  -- OpTagPt - varchar(250)
					),
					(   6,  -- FinderWhatsAppMessageId - int
					''Mensaje de que cambio la ruta de almacenamiento que se incluira al archivo que contiene los no descargados'', -- Description - varchar(400)
					''Error. No se puede encontrar el archivo. La ruta de almacenamiento fue cambiada.'', -- OpTagEs - varchar(250)
					''Error: Unable to find file. The storage path was changed.'', -- OpTagEn - varchar(250)
					''Erro: Não é possível localizar o arquivo. O caminho de armazenamento foi alterado.''  -- OpTagPt - varchar(250)
					),
					(   7,  -- FinderWhatsAppMessageId - int
					''Mensaje de que se excedio el tiempo limite de almacenamiento  que se incluira al archivo que contiene los no descargados'', -- Description - varchar(400)
					''Error: No se puede encontrar el archivo. El tiempo límite de almacenamiento fue excedido.'', -- OpTagEs - varchar(250)
					''Error: Unable to find file. The storage time limit was exceeded.'', -- OpTagEn - varchar(250)
					''Erro: Não é possível localizar o arquivo. O limite de tempo de armazenamento foi excedido.''  -- OpTagPt - varchar(250)
					)
			END'
		EXEC(@sql)
		--------------------------------------------------------- SPs -------------------------------------------------------------------------------------------
		SET @process = 'K002091 - Descargar conversaciones entrada Whatsapp con adjuntos -  Se elimina SP ccsp_AgentHistoricalChat'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_AgentHistoricalChat'')
					begin
						DROP PROCEDURE ccsp_AgentHistoricalChat;
					end'
		EXEC(@sql)

		SET @process = 'K002091 - Descargar conversaciones entrada Whatsapp con adjuntos - se modifica el @option 4, 
		línea 261, 396, 230 - 241 y 365 - 376'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_AgentHistoricalChat] 
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
                    SELECT conversationId AS ConversationId,
                        @campType AS CampType,
                        assignDate AS Date
                    FROM ccWhatsAppConversations with(nolock)
                    WHERE clientId = @clientNum AND assignDate IS NOT NULL
                    GROUP BY conversationId, assignDate
                END
                ELSE
                BEGIN  -- OUTBOUND
                    SELECT conversationId AS ConversationId,
                        @campType AS CampType,
                        assignDate AS Date
                    FROM ccWhatsAppConversationsOut with(nolock)
                    WHERE clientId = @clientNum AND assignDate IS NOT NULL
                    GROUP BY conversationId, assignDate
                END
            END

            IF @option = 2 --whatsapp, get acdId by conversation id
            BEGIN
                IF @campType = 0
                BEGIN
                    SELECT CAST(inboundId AS INT)
                    FROM [ccWhatsAppConversations] with(nolock)
                    WHERE conversationId = @conversationId
                END
                ELSE
                BEGIN
                    SELECT CAST(camId AS INT)
                    FROM [ccWhatsAppConversationsOut] with(nolock)
                    WHERE conversationId = @conversationId
                END
            END

            IF @option = 3 --get data conversation
            BEGIN
                DECLARE @OldAgentId INT = 0
                DECLARE @OldConversationId INT = 0

                SELECT @OldAgentId = conv.agentId, @OldConversationId = rel.conversationIdBefore
                FROM ccWhatsAppConversationsRelationship rel with(nolock)
                RIGHT JOIN ccWhatsAppConversations conv with(nolock) ON conv.conversationId = rel.conversationIdBefore
                WHERE rel.conversationIdAfter = @conversationId

                SELECT cast(i.chat AS INT) AS ServiceType, cast(c.conversationId AS INT) AS ConversationID, c.clientId AS ClientId, cm.conexionInfo AS [To], cast(i.Inbound_id AS INT) AS ACDId, i.descripcion AS ACDName, cast(g.
                        graphic_id AS INT) AS ACDGraphicId, cast(cm.closeConversationTime AS INT) AS [TimeOut], cast(cm.answerTimeOut AS INT) AS [TimeOutWarning], i.ExitWrapUpDisposition AS [ExitWrapUpDisposition], i.tNotas AS 
                    [WrapUpTime], i.ShowCalifWnd, cast(ISNULL(answerTimeoutClient, 30) AS INT) AS [AnswerTimeoutClient], ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS 
                    [SecTimeOutLastMessageAgent], isnull(permission.AllowUnassign, 0) AS AllowUnassign, isnull(permission.AllowSpam, 0) AS AllowSpam, ISNULL(@OldAgentId, 0) AS OldAgentId, ISNULL(@OldConversationId, 0) AS 
                    OldConversationId, c.agentId AS AgentId
                FROM ccInbound i
                INNER JOIN contactMeanIn cm ON i.Inbound_id = cm.inboundId
                INNER JOIN ccWhatsAppConversations c with(nolock) ON (
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
                DECLARE @camp_acd_id INT = 0;

                IF @campType = 0
                BEGIN
                    SET @camp_acd_id = (SELECT inboundId FROM ccWhatsAppConversations with(nolock) WHERE conversationId = @conversationId)

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
                    WHEN typeMessage IN (''image'', ''file'', ''video'', ''audio'')
                        THEN 
                            CASE 
                                WHEN content LIKE ''%Caption:%''
                                    THEN 
                                    (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 1), '':'') WHERE id = 2)
                                 WHEN content IS NOT NULL AND LEN(content) > 0 
                                    THEN
                                        RIGHT(content, CHARINDEX(''/'', REVERSE(content)) - 1)
                                ELSE
                                ''''
                            END
                    WHEN typeMessage NOT IN (''text'', ''location'')
                        THEN content
                    ELSE ''''
                    END AS Caption, CASE 
                    WHEN originType = ''Client''
                        THEN CASE 
                                WHEN typeMessage = ''text''
                                    OR typeMessage = ''location''
                                    THEN ''''
                                ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + ''INBOUND'' + CHAR(92)+ CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
                                    typeMessage + CHAR(92) + CHAR(92) + messageId + ''.'' + CASE 
                                        WHEN typeMessage = ''video''
                                            THEN ''mp4''
                                        WHEN typeMessage = ''image''
                                            THEN ''jpg''
                                        WHEN typeMessage = ''audio''
                                            THEN ''mp3''
                                        WHEN typeMessage = ''file''
                                            THEN (
                                                    SELECT SUBSTRING(content, LEN(content) - CHARINDEX(''.'', REVERSE(content)) + 2, LEN(content))
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
                    END AS [LocationURL],
                    graphics.graphic_id AS GraphicId,
                    conversationId AS ConversationId
                    FROM ccWAMessagesConversations
                    LEFT JOIN ccRIAInboundGraph graphics ON Inbound_id = @camp_acd_id
                    WHERE conversationId = @conversationId
                    ORDER BY TIMESTAMP ASC
                END
                ELSE
                BEGIN
                    SET @camp_acd_id = (SELECT camId FROM ccWhatsAppConversationsOut with(nolock) WHERE conversationId = @conversationId)

                    SELECT messageId AS MessageId, messageStatus AS STATUS, originType AS Origin, CASE 
                    WHEN originType = ''Client''
                        THEN 3
                    WHEN originType = ''Agent''
                        THEN 2
                    WHEN originType = ''Admin''
                        THEN 1
                    ELSE 0
                    END AS OriginType, timeStampMessage AS [Timestamp], CASE 
                    WHEN typeMessage IN (''text'', ''template'')
                        THEN content 
                    ELSE ''''
                    END AS Content, typeMessage AS Type, CASE 
                    WHEN typeMessage IN (''image'', ''file'', ''video'', ''audio'')
                        THEN 
                            CASE 
                                WHEN content LIKE ''%Caption:%''
                                    THEN 
                                    (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 1), '':'') WHERE id = 2)
                                 WHEN content IS NOT NULL AND LEN(content) > 0 
                                    THEN
                                        RIGHT(content, CHARINDEX(''/'', REVERSE(content)) - 1)
                            ELSE
                            ''''
                            END
                    WHEN typeMessage NOT IN (''text'', ''location'', ''template'')
                        THEN content
                    ELSE ''''
                    END AS Caption, CASE 
                    WHEN originType = ''Client''
                        THEN CASE 
                                WHEN typeMessage = ''text''
                                    OR typeMessage = ''location''
                                    THEN ''''
                                ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + ''OUTBOUND'' + CHAR(92)+ CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
                                    typeMessage + CHAR(92) + CHAR(92) + messageId + ''.'' + CASE 
                                        WHEN typeMessage = ''video''
                                            THEN ''mp4''
                                        WHEN typeMessage = ''image''
                                            THEN ''jpg''
                                        WHEN typeMessage = ''audio''
                                            THEN ''mp3''
                                        WHEN typeMessage = ''file''
                                            THEN (
                                                    SELECT SUBSTRING(content, LEN(content) - CHARINDEX(''.'', REVERSE(content)) + 2, LEN(content))
                                                    )
                                        ELSE ''''
                                        END
                                END
                    ELSE CASE 
                            WHEN typeMessage = ''text''
                                OR typeMessage = ''location''
                                OR typeMessage = ''template''
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
                    END AS [LocationURL],
                    graphics.graphic_id AS GraphicId,
                    conversationId AS ConversationId
                    FROM ccWAMessagesConversationsOut
                    LEFT JOIN ccRIACampsGraph graphics ON cam_id = @camp_acd_id
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
                                FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationship] with(nolock)
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
                                FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationshipOut] with(nolock)
                                WHERE conversationIdAfter = @conversationId
                                )
                            THEN CAST(1 AS BIT)
                        ELSE CAST(0 AS BIT)
                        END
                END
            END
        END
		'
		EXEC (@sql)

		SET @process = 'K002091 - Descargar conversaciones entrada Whatsapp con adjuntos -  Se elimina SP ccspGalatea_Finder'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccspGalatea_Finder'')
					begin
						DROP PROCEDURE ccspGalatea_Finder;
					end'
		EXEC(@sql)

		SET @process = 'K002091 - Descargar conversaciones entrada Whatsapp con adjuntos - se agrega el @action 6 lineas 630 - 638 '
		SET @sql = 'CREATE PROCEDURE [dbo].[ccspGalatea_Finder] 
				@action INT, 
				@userId INT = 0, 
				@conversationId BIGINT = 0,
				@isSuperUser bit=0
				AS
				IF @action = 1
				    BEGIN--trae el nombre de la base de datos en BX
				    if @isSuperUser =0 begin

				            SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, c.cam_descripcion AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
				                INNER JOIN ccCamps c ON WGCam.IdCampEsp = c.cam_id
				                                        AND WGCam.Tipo = 1
				            WHERE Wguser.User_id = @userId
				            UNION
				            SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, inb.descripcion AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
				                INNER JOIN ccInbound inb ON WGCam.IdCampEsp = inb.Inbound_id
				                                            AND WGCam.Tipo = 0
				            WHERE Wguser.User_id = @userId;
				        end
				        else begin
				        SELECT CAST(c.cam_id AS INT) AS [Value], CAST(2 AS INT) AS callType, c.cam_descripcion AS label FROM ccCamps c
				        UNION
				        SELECT CAST(inb.Inbound_id AS INT) AS [Value], CAST(1 AS INT) AS callType, inb.descripcion AS label FROM ccInbound inb;
				        end
				        RETURN 0;
				END;
				IF @action = 2
				    BEGIN
				    if @isSuperUser =0 begin
				        WITH WgId
				            AS (SELECT IDWG
				                FROM ccRIAWorkGroupUsers Wguser
				                WHERE Wguser.User_id = @userId)
				            SELECT DISTINCT 
				                    CAST(Wguser.User_id AS INT) AS [Value], CONCAT(ccUsers.Nombres, '' '', ccUsers.ApellidoPaterno, '' '', ccUsers.ApellidoMaterno)  AS label
				            FROM ccRIAWorkGroupUsers Wguser
				                INNER JOIN WgId ON Wguser.IDWG = WgId.IDWG
				                INNER JOIN ccUsers ON ccUsers.User_id = Wguser.User_id
				                                        AND TipoUser_id = 1;
				end
				else begin
				        select CAST(ccUsers.User_id AS INT) AS [Value], CONCAT(ccUsers.Nombres, '' '', ccUsers.ApellidoPaterno, '' '', ccUsers.ApellidoMaterno)  AS label
				        from ccUsers where TipoUser_id = 1;
				end
				        RETURN 0;
				END;
				IF @action = 3
				         BEGIN--Informacion de la conversacion de whatsApp
				               SELECT A.ConversationID, A.inboundId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneACD AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID, C.Login AS UserName
				                        ,(cast(sum(A.tConversation) / 3600 as varchar(10)) + '':'' + 
				                        right(''0'' + cast((sum(A.tConversation) % 3600) / 60 as varchar(10)), 2) + '':'' + 
				                        right(''0'' + cast(sum(A.tConversation) % 60 as varchar(10)), 2)) as Duration
				             FROM ccWhatsAppConversations A
				                  LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
				                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
				                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
				                  LEFT JOIN ccRIAInboundGraph graph ON graph.Inbound_id = A.inboundId
				                  LEFT JOIN ccUsers C ON A.agentId = C.User_id
				             WHERE A.conversationId = @conversationId
				             group by A.conversationId, A.inboundId, graph.graphic_id, A.phoneACD, A.clientId, B.descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc, conversationDate, requestDate, A.agentId, C.Login;

				             RETURN 0;
				     END;
				IF @action = 4
				         BEGIN--Informacion de la conversacion de whatsApp out
				               SELECT A.ConversationID, A.camId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneCamp AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.cam_descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID, C.Login AS UserName
				                        ,(cast(sum(A.tConversation) / 3600 as varchar(10)) + '':'' + 
				                        right(''0'' + cast((sum(A.tConversation) % 3600) / 60 as varchar(10)), 2) + '':'' + 
				                        right(''0'' + cast(sum(A.tConversation) % 60 as varchar(10)), 2)) as Duration
				             FROM ccWhatsAppConversationsOut A
				                  LEFT JOIN ccCamps B ON A.camId = B.cam_id
				                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
				                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
				                  LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = A.camId
				                  LEFT JOIN ccUsers C ON A.agentId = C.User_id
				             WHERE A.conversationId = @conversationId
				             group by A.conversationId, A.camid, graph.graphic_id, A.phoneCamp, A.clientId, B.cam_descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc, conversationDate, requestDate, A.agentId, C.Login;

				             RETURN 0;
				     END;
				IF @action = 5
				         BEGIN--Informacion de la conversacion de Chat
				                SELECT A.ChatId AS ConversationID, A.inboundId AS CampaignId, A.userId AS AgentID, ISNULL(B.descripcion, ''N/A'') AS CampaignName,
							   ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, 
							   C.Login AS UserName, A.clientName as Client, ISNULL(A.chatDate, A.requestDate) as DateStart,
							   (cast(sum(A.tChatting) / 3600 as varchar(10)) + '':'' + 
				                right(''0'' + cast((sum(A.tChatting) % 3600) / 60 as varchar(10)), 2) + '':'' + 
				                right(''0'' + cast(sum(A.tChatting) % 60 as varchar(10)), 2)) as Duration
				             FROM ccRIAChats A
				                  LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
				                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
				                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
				                  LEFT JOIN ccUsers C ON A.userId = C.User_id
				             WHERE A.chatId = @conversationId
				             group by A.chatId, A.inboundId, A.userId, A.userId, B.descripcion, cctipocalif.[Description], cctipocalifsub.califSubdesc,
							 chatDate, requestDate, A.userId, C.Login, tChatting, clientName;

				             RETURN 0;
				     END;
				IF @action = 6
				BEGIN
					SELECT cfwadm.FinderWhatsAppMessageId,
                           cfwadm.Description,
                           cfwadm.OpTagEs,
                           cfwadm.OpTagEn,
                           cfwadm.OpTagPt FROM dbo.ccFinderWhatsAppDownloadedMessage AS cfwadm
					RETURN 0
				END
		'
		EXEC (@sql)

	
		
------------------------------------------- END MARCO GARCÍA ----------------------------------------------------------

------------------------------------------- Begin Rod Salazar ----------------------------------------------------------

		SET @process = 'KR146000 - Se crea tabla ttsMessages'
		SET @sql = '
					IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''ttsMessages''))
					BEGIN
						create table ttsMessages(
							messageId int not null identity(1,1) primary key,
							name varchar(40) not null,
							description varchar(40) null,
							message varchar(3072) not null,
							areaId int null
						)

						CREATE INDEX IDX_TTSMessage ON ttsMessages (messageId);
					END
					'
		EXEC(@sql)

		set @process = 'KR146000 Validar vista ViewTTSMessagesData'
		set @sql = 'IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''ViewTTSMessagesData''))
					BEGIN
						DROP VIEW ViewTTSMessagesData;
					END;'
		EXEC(@sql)

		SET @process = 'KR146000 - Se crea vista para leer los datos'
		SET @sql = 'CREATE VIEW ViewTTSMessagesData as 
					--select * from DatosClienteTTS
					select cam_id, cal_key, cal_telefono, Dato1, Dato2, Dato3, Dato4, Dato5 from ccoCallsOutSource'
		EXEC(@sql)

		SET @process = 'KR146000 - Se agrega tipoMsg_id = 20 e identificadores para historial de actividad'
		SET @sql = 'IF NOT EXISTS (SELECT 1 FROM ccTipoMsgs WHERE TipoMsg_Id = 20)
					BEGIN
						INSERT INTO ccTipoMsgs VALUES (20, ''TTS'', ''TTS'');
					END;

					IF NOT EXISTS (SELECT 1 FROM ccGalateaModules WHERE ModuleId = 23)
					BEGIN
						INSERT INTO ccGalateaModules (ModuleId, MTagEs, MTagEn, MTagPt) VALUES (23, ''Mensajes automáticos'', ''Automatic messages'', ''Mensagens automáticas'');
					END;

					IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 124)
					BEGIN
						INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (124, ''Crear audio desde texto'', ''Create audio from text'', ''Criar áudio a partir de texto'');
					END;

					IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 125)
					BEGIN
						INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (125, ''Editar audio desde texto'', ''Edit audio from text'', ''Editar áudio a partir de texto'');
					END;

					IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 126)
					BEGIN
						INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (126, ''Eliminar audio desde texto'', ''Delete audio from text'', ''Excluir áudio a partir de texto'');
					END;

					IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''AUTOMATIC_MESSAGES_DESCRIPTION'')
					BEGIN
						INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''AUTOMATIC_MESSAGES_DESCRIPTION'', ''Descripción'', ''Description'', ''Descrição'');
					END;

					IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''AUTOMATIC_MESSAGES_GLOBAL'')
					BEGIN
						INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''AUTOMATIC_MESSAGES_GLOBAL'', ''Global'', ''Global'', ''Global'');
					END;

					IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''AUTOMATIC_MESSAGES_MESSAGE'')
					BEGIN
						INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''AUTOMATIC_MESSAGES_MESSAGE'', ''Texto'', ''Text'', ''Texto'');
					END;

					IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''AUTOMATIC_MESSAGES_NAME'')
					BEGIN
						INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''AUTOMATIC_MESSAGES_NAME'', ''Nombre'', ''Name'', ''Nome'');
					END;

					IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''AUTOMATIC_MESSAGES_ANSWER_MACHINE'')
					BEGIN
						INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''AUTOMATIC_MESSAGES_ANSWER_MACHINE'', ''Máquina contestadora'', ''Answering machine'', ''Secretária eletrônica'');
					END;

					IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = ''FK_ccCampsMsgs_ccMsgFiles'' AND parent_object_id = OBJECT_ID(''ccCampsMsgs''))
					BEGIN
						ALTER TABLE ccCampsMsgs DROP CONSTRAINT FK_ccCampsMsgs_ccMsgFiles;
					END;'
		EXEC(@sql)
		
		SET @process = 'KR146000 - Se valida funcion fnGetTTSTraduction'
		SET @sql = 'IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''fnGetTTSTraduction'') AND type IN (N''FN'', N''IF'', N''TF''))
					BEGIN
						DROP FUNCTION fnGetTTSTraduction;
					END;'
		EXEC(@sql)


		SET @process = 'KR146000 - Se crea función fnGetTTSTraduction'
		SET @sql = '
			CREATE function [dbo].[fnGetTTSTraduction](@phrase varchar(3072), @type int)
					RETURNS varchar(3072)
					AS
					BEGIN
						
						declare @typeText varchar(30) = ''''
						DECLARE @pos INT;
						DECLARE @result varchar(3072) = ''''
						declare @isNum int;

						select @typeText = case when @type = 1 then ''<SpellingText>'' else ''<TelephoneText>'' end;

						SET @pos = CHARINDEX(@typeText, @phrase);

						IF(@pos > 0) 
						BEGIN
							declare @word varchar(3072) = ''''

							SELECT @word = SUBSTRING(@phrase, @pos + LEN(@typeText), LEN(@phrase))

							DECLARE @wordWithDelimitador NVARCHAR(MAX) = '''';

							set @isNum = CASE WHEN @word LIKE ''%[^0-9]%'' THEN 0 ELSE 1 END 

							if(@isNum = 1 or @type = 1)
							BEGIN
								DECLARE @i INT = 1;
								DECLARE @len INT = LEN(@word);

								WHILE @i <= @len
								BEGIN
									SET @wordWithDelimitador = @wordWithDelimitador + SUBSTRING(@word, @i, @type) + '';'';
									SET @i = @i + @type;
								END
							END
							ELSE
							BEGIN
								SET @wordWithDelimitador = @word
							END
						
							SET @result = SUBSTRING(@phrase, 0, @pos) + @WordWithDelimitador + '' ''
						END
						ELSE
						BEGIN
							SET @result = @phrase
						END

						RETURN @result
					END'
		EXEC(@sql)

		SET @process = 'KR146000 - se valida sp ccsp_TTSMessageData'
		SET @sql = 'IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''ccsp_TTSMessageData''))              
					BEGIN
						DROP PROCEDURE ccsp_TTSMessageData;
					END;'
		EXEC(@sql)

		SET @process = 'KR146000 - se crea sp ccsp_TTSMessageData'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_TTSMessageData]
						@cam_id INT,
						@callout_id INT,
						@message NVARCHAR(MAX) OUTPUT
					AS
					BEGIN
						SET NOCOUNT ON;

						DECLARE @sql NVARCHAR(MAX) = '''';
						DECLARE @columnName NVARCHAR(128);
						DECLARE @index INT = 1;
						DECLARE @totalColumns INT;
						DECLARE @cal_key varchar(40) = ''''
						DECLARE @cal_telefono varchar(30) = ''''

						DECLARE @TempColumns AS TABLE (
							ColumnID INT IDENTITY(1,1),
							ColumnName NVARCHAR(128) 
						);

	
						select @cal_key = cal_Key, @cal_telefono = cal_telefono from ccoCallsOutSource where callout_id = @callout_id
    
						SELECT @message = b.message 
						FROM ccCampsMsgs a
						LEFT JOIN ttsMessages b ON b.messageId = a.Msg_id
						WHERE cam_id = @cam_id AND Type = 20;

						INSERT INTO @TempColumns (ColumnName)
						SELECT COLUMN_NAME 
						FROM INFORMATION_SCHEMA.COLUMNS
						WHERE TABLE_NAME = ''ViewTTSMessagesData'' and COLUMN_NAME not in (''identificador'', ''cam_id'', ''cal_key'', ''cal_telefono'');
  
						SELECT @totalColumns = COUNT(*) FROM @TempColumns;

						IF EXISTS (SELECT 1 FROM ViewTTSMessagesData WHERE cam_id = @cam_id and cal_key = @cal_key and cal_telefono = @cal_telefono)
						BEGIN
							WHILE @index <= @totalColumns
							BEGIN
    
								SELECT @columnName = ColumnName 
								FROM @TempColumns
								WHERE ColumnID = @index;
    
								IF CHARINDEX(@columnName, @message) > 0
								BEGIN
									SET @sql = ''SELECT @message = REPLACE(@message, ''''{{'' + @columnName + ''}}'''', ''''{{'''' + ISNULL(CONVERT(NVARCHAR(MAX), '' + @columnName + ''), '''''''') + ''''}}'''') FROM ViewTTSMessagesData WHERE cam_id = @cam_id and cal_key = @cal_key and cal_telefono = @cal_telefono;'';

									EXEC sp_executesql @sql, N''@message NVARCHAR(MAX) OUTPUT, @cam_id INT, @cal_key varchar(40), @cal_telefono varchar(30)'', @message OUTPUT, @cam_id, @cal_key, @cal_telefono;
								END
			
								SET @index = @index + 1;
							END;
						END
						ELSE
						BEGIN
							WHILE @index <= @totalColumns
							BEGIN
    
								SELECT @columnName = ColumnName 
								FROM @TempColumns
								WHERE ColumnID = @index;
    
								IF CHARINDEX(@columnName, @message) > 0
								BEGIN
									SET @sql = ''SELECT @message = REPLACE(@message, ''''{{'' + @columnName + ''}}'''', ''''{{}}'''') ;'';

									EXEC sp_executesql @sql, N''@message NVARCHAR(MAX) OUTPUT'', @message OUTPUT;
								END
			
								SET @index = @index + 1;
							END;
						END
    
						SELECT @message = REPLACE(@message, ''.00'', '''')
					END;'
		EXEC(@sql)

		SET @process = 'KR146000 - se valida sp ccsp_TTSMessages'
		SET @sql = 'IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''ccsp_TTSMessages''))              
					BEGIN
						DROP PROCEDURE ccsp_TTSMessages;
					END;'
		EXEC(@sql)

		SET @process = 'KR146000 - se crea sp ccsp_TTSMessages'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_TTSMessages]
					@cam_id int,
					@callout_id int
				
					AS
				
					declare @message varchar(3072) = ''''
			
					IF EXISTS (SELECT 1, * FROM ccCampsMsgs WHERe cam_id = @cam_id and Type = 20)
					BEGIN
	
						exec ccsp_TTSMessageData @cam_id, @callout_id, @message = @message output

						SELECT @message = REPLACE(REPLACE(@message, ''{{'', ''''), ''}}'', '''')

						declare @temp table(part varchar(3072))

						IF CHARINDEX(''<CurrencyText>'', @message) > 0
						BEGIN
							WHILE CHARINDEX(''<CurrencyText>'', @message) > 0
							BEGIN
								DECLARE @start INT, @end INT, @currencyValue NVARCHAR(3072)

								SET	@start = CHARINDEX(''<CurrencyText>'', @message) + LEN(''<CurrencyText>'')
								SET @end = CHARINDEX(''</CurrencyText>'', @message)
     
								SET @currencyValue = SUBSTRING(@message, @start, @end - @start)
      
								IF ISNUMERIC(@currencyValue) = 1
								BEGIN	
									SET @message = STUFF(@message, CHARINDEX(''<CurrencyText>'', @message), @end - CHARINDEX(''<CurrencyText>'', @message) + LEN(''</CurrencyText>''), @currencyValue + '' pesos'')
								END
								ELSE
								BEGIN	
									SET @message = STUFF(@message, CHARINDEX(''<CurrencyText>'', @message), @end - CHARINDEX(''<CurrencyText>'', @message) + LEN(''</CurrencyText>''), @currencyValue)
								END
							END	
						END

						IF CHARINDEX(''<SpellingText>'', @message) > 0
						BEGIN

							insert into @temp
							select dbo.fnGetTTSTraduction(value, 1) from dbo.fn_RIASplitDelimited(@message, ''</SpellingText>'');
		
							set @message=''''
							select @message = @message + part from  @temp

							delete from @temp
				
						END

						IF CHARINDEX(''<TelephoneText>'', @message) > 0
						BEGIN
								
							insert into @temp
							select dbo.fnGetTTSTraduction(value, 2) from dbo.fn_RIASplitDelimited(@message, ''</TelephoneText>'');				
		
							set @message=''''
							select @message = @message + part from  @temp
			
						END
					END

					select @message'
		EXEC(@sql)

		

		SET @process = 'KR146000 - Se valida función fn_RIASplitDelimited'
		SET @sql = 'IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''fn_RIASplitDelimited'') AND type IN (N''FN'', N''IF'', N''TF''))
					BEGIN
						DROP FUNCTION fn_RIASplitDelimited;
					END;'
		EXEC(@sql)

		SET @process = 'KR146000 - se modifica función fn_RIASplitDelimited'
		SET @sql = 'CREATE FUNCTION [dbo].[fn_RIASplitDelimited]
					( 
					  @List nvarchar(MAX),
					  @SplitOn varchar(20)
					)
					RETURNS @RtnValue table (
					  Id int identity(1,1),
					  Value nvarchar(255)
					)
					AS
					BEGIN
					  While (Charindex(@SplitOn,@List)>0)
					  Begin 
						Insert Into @RtnValue (value)
						Select 
						  Value = ltrim(rtrim(Substring(@List,1,Charindex(@SplitOn,@List)-1))) 
						Set @List = Substring(@List,Charindex(@SplitOn,@List)+len(@SplitOn),len(@List))
					  End 
  
					  Insert Into @RtnValue (Value)
						Select Value = ltrim(rtrim(@List))

						Return
					END'
		EXEC(@sql)

		SET @process = 'KR146000 - se valida funcion fn_ccCamps_SelMessage'
		SET @sql = 'IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''fn_ccCamps_SelMessage'') AND type IN (N''FN'', N''IF'', N''TF''))
					BEGIN
						DROP FUNCTION fn_ccCamps_SelMessage;
					END;'
		EXEC(@sql)

		SET @process = 'KR146000 - se modifica funcion fn_ccCamps_SelMessage'
		SET @sql = 'CREATE function [dbo].[fn_ccCamps_SelMessage](@cam_id smallint)
					returns @SelMessage table (msg_mostrar varchar(max), msg_mostrar_dnc varchar(max), msg_mostrar_dnc_confirm varchar(max) )
					as
					begin
					declare @msg_mostrar varchar(max), @msg_mostrar_dnc varchar(max), @msg_mostrar_dnc_confirm varchar(max)
					select @msg_mostrar='''', @msg_mostrar_dnc='''', @msg_mostrar_dnc_confirm = ''''

					select @msg_mostrar=@msg_mostrar+coalesce(msgFile+'','','''')
					from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id
					where M.cam_id = @cam_id and type = 8 order by orden

					IF EXISTS (select 1 from ccCampsMsgs where Type = 20 and cam_id = @cam_id)
					BEGIN
						select @msg_mostrar = @msg_mostrar + ''TTS/message.wav,''
					END

					select @msg_mostrar_dnc=@msg_mostrar_dnc+coalesce(msgFile+'','','''')
					from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id
					where M.cam_id = @cam_id and type = 11 order by orden

					select @msg_mostrar_dnc_confirm=@msg_mostrar_dnc_confirm+coalesce(msgFile+'','','''')
					from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id
					where M.cam_id = @cam_id and type = 14 order by orden

					insert into @SelMessage select 
					case when len(isnull(@msg_mostrar,''''))>0 then left(@msg_mostrar, len(@msg_mostrar)-1) else '''' end,
					case when len(isnull(@msg_mostrar_dnc,''''))>0 then left(@msg_mostrar_dnc, len(@msg_mostrar_dnc)-1) else '''' end,
					case when len(isnull(@msg_mostrar_dnc_confirm,''''))>0 then left(@msg_mostrar_dnc_confirm, len(@msg_mostrar_dnc_confirm)-1) else '''' end

					return
					end'
		EXEC(@sql)

		SET @process = 'KR146000 - se valida sp ccsp_LoadGraphics'
		SET @sql = 'IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''ccsp_LoadGraphics''))              
					BEGIN
						DROP PROCEDURE ccsp_LoadGraphics;
					END;'
		EXEC(@sql)

		SET @process = 'KR146000 - Se crea sp ccsp_LoadGraphics'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_LoadGraphics]
					@Id as smallint,
					@callType as smallint,
					@UserId as smallint,
					@phone varchar(50)=null
					AS
					BEGIN
					        
					    SET NOCOUNT ON  
					    DECLARE @realValue int      
					    exec @realValue= ccsp_AgentGetStartStopPermission @age_id=@UserId, @cam_id=@Id, @call_type=@callType,@phone=@phone
					    set @realValue=isnull(@realValue,0);

					    if (@callType=1)
					    begin
					        DECLARE @canReprogram bit  
					        create table #canReprogram (canReprogram bit)
					        insert into #canReprogram
					        exec ccsp_AgentGetCampReprogramData @Id, @callType
					        select @canReprogram = canReprogram from #canReprogram
					        drop table #canReprogram

					        select a1.Inbound_id id, a2.descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey, 0 as leaveRecMessage , a2.EditableContactData,
					        case when isnull(a4.callsBySurvey,0) > 0 or extended.SurveyCamId>0 then 1 else 0 end isRelationSurvey ,
					        isnull(a2.callBackSurveyAgent,1) callBackSurveyAgent,isnull(a2.callBackSurveyClient,1) callBackSurveyClient,
					        a2.ShowCalifWnd as ShowDisposition,
					        isnull(a2.startStopRecording,0) as StartStopRecording,
					        @realValue as IsStartStopRecording,
					        isnull(a2.editableDtmf, 0) as isEditDtmf,
					        @canReprogram  CanReprogram
					        from ccRIAInboundGraph a1 
					        inner join ccInbound a2 on (a1.inbound_id=a2.inbound_id)
					        inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id) 
					        left join ccCamps a4 on a4.cam_id=a2.cam_id 
							left join ccInboundExtend extended on extended.Inbound_id = a1.Inbound_id
							where a1.inbound_id=@Id and type_id in(1,2,3) order by type_id        
					     end    
					     else
					     begin
					        select a1.cam_id Id, a2.cam_descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey,
					        case when msgFile <> '''' and leaveRecMessage = 1 then 1 else 0 end as leaveRecMessage, 
					        case when isnull(a2.surveyCamId,0) >0 then 1 else 0 end isRelationSurvey ,
					        a2.cam_ShowCalifWnd as ShowDisposition,
					        a2.callBackSurveyAgent,a2.callBackSurveyClient,
					        isnull(a2.startStopRecording,0) as StartStopRecording,
					        @realValue as IsStartStopRecording,
					        isnull(a4.EditableContactData,0) as EditableContactData
					        from ccRIACampsGraph a1 
					        inner join ccCamps a2 on (a1.cam_id=a2.cam_id)
					        inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id)
					        left join ccCampsExtend a4 on (a1.cam_id = a4.cam_id)
					        left outer join (SELECT TOP 1 M.cam_id, CASE WHEN M.type = 8 THEN T.msgFile WHEN M.type = 20 THEN TT.name END AS msgFile
								FROM ccCampsMsgs M
								LEFT JOIN ccMsgFiles T ON M.Msg_id = T.msg_id AND M.type = 8
								LEFT JOIN ttsmessages TT ON M.Msg_id = TT.messageId AND M.type = 20
								WHERE M.cam_id = @Id AND (M.type = 8 OR M.type = 20)) b on a2.cam_id = b.cam_id 
					        where a1.cam_id=@Id and type_id in(1,2,3) order by type_id
					     end    
					END'
		EXEC(@sql)

		SET @process = 'KR146000 - se valida sp ccsp_RIAADMCampMsgs'
		SET @sql = 'IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''ccsp_RIAADMCampMsgs''))            
					BEGIN
						DROP PROCEDURE ccsp_RIAADMCampMsgs;
					END;'
		EXEC(@sql)

		SET @process = 'KR146000 - se crea sp ccsp_RIAADMCampMsgs'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAADMCampMsgs]
					@Command tinyint, -- 1=Query, 2=Insert
					@msg_id int = null,
					@cam_id smallint = null,
					@order tinyint = null,
					@Type tinyint = null,
					@queue bit = null,
					@msgFile varchar(40) = '''',
					@description varchar(40) = ''''
					as
					set nocount on
					if @Command=1
					 begin
						select A.type, A.orden, case when type = 20 then name else msgFile end as msgFile, case when A.Type = 20 then 1000 + A.Msg_id else A.Msg_id end as Msg_id, D.msg_mostrar
						from ccCampsMsgs A 
						join ccCamps B on A.cam_id = B.cam_id
						left join ccMsgFiles C on A.Msg_id = C.Msg_id 
						left join ccTipoMsgs D on A.type = D.tipomsg_id
						left join ttsMessages E on E.messageId = A.Msg_id
						where A.cam_id = @cam_id
						order by A.type, A.orden
						return(0) 
					 end

					If @Command=2
					 begin
						if not exists (select msg_id from ccCampsMsgs where msg_id=@msg_id and cam_id=@cam_id and type=@type)
							insert into ccCampsMsgs (msg_id, cam_id, orden, type) values (@msg_id, @cam_id, @order, @Type)
						return(0)
					 end
 
					If @Command=3
						begin
							exec @msg_id = ccsp_RIACATMessages 5, 0, @msgFile, @description
							if @msg_id <> 0
								insert into ccCampsMsgs (msg_id, cam_id, orden, type) values (@msg_id, @cam_id, @order, @Type)
							return(0)
						end

					set nocount off'
		EXEC(@sql)
		
		SET @process = 'KR146000 - se valida sp ccsp_DLRgetDialPrefix'
		SET @sql = 'IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''ccsp_DLRgetDialPrefix''))           
					BEGIN
						DROP PROCEDURE ccsp_DLRgetDialPrefix;
					END;'
		EXEC(@sql)

		SET @process = 'KR146000 - se crea sp ccsp_DLRgetDialPrefix'
		SET @sql = 'CREATE procedure [dbo].[ccsp_DLRgetDialPrefix]
					@cam_id smallint=0,
					@iPortNumber smallint = 0,
					@phone varchar(30) = '''',
					@callout_id int = 0
					as
					declare @prefix as varchar(15), @sipheader varchar(500)
					declare @ani as varchar(32)
					declare @pais as tinyint 
					declare @aniglobal varchar(32), @sipHdrFormat varchar(255)
					declare @ivr_script smallint, @surveycamid int
					declare @call_record tinyint, @tNoContesta tinyint, @detectAnswerMachine smallint, @detectVoiceMail tinyint
					declare @PrefixRec varchar(40)
					declare @carrier varchar(255)
					declare @recordHold bit, @recordIvr bit

					select @pais = valor from ccsettings with(nolock) where setting_id = 104
					select @aniglobal = valor from ccsettings with(nolock) where setting_id = 177

					set @prefix =''''
					-- Prefijo por puerto
					select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )

					-- Prefijo por campa?a,
					if @prefix =''''
						select @prefix = dialPrefixMan from ccCamps where cam_id = @cam_id

					-- Prefijo general
					if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 2 = 2)
						select @prefix = valor from ccsettings with(nolock) where setting_id =101

					-- Ani
					set @ani = dbo.TelAni(@phone, (select id_anilist from ccCamps where cam_id =@cam_id) )

					--AnswerMachine Message Files
					DECLARE @MsgFiles VARCHAR(8000) 
					SELECT @MsgFiles = COALESCE(@MsgFiles + '','', '''') + V.msgfile 
					FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 8 ORDER BY orden

					IF EXISTS (select 1 from ccCampsMsgs where Type = 20 and cam_id = @cam_id)
					BEGIN
						select @MsgFiles = @MsgFiles + '',TTS/message.wav''
					END

					--Custom MOH Files
					DECLARE @MohFiles VARCHAR(8000) 
					SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
					FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

					select @surveycamid = 0, @ivr_script = 0

					select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta = cam_tNoContesta, @ani = case when @ani = '''' then ani else @ani end
					,@detectAnswerMachine = detectAnswerMachine, @detectVoiceMail = detectVoiceMail
					,@call_record = dbo.EnableCallRecord(call_record, @pais, @phone), @surveycamid = isnull(surveycamid,0), @recordHold=ISNULL(recordHold,0)
					,@recordIvr=ISNULL(recordIvr,0), @PrefixRec = ISNULL(prefijo,'''')
					from ccCamps NOLOCK where cam_id = @cam_id

					SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)

					if @surveycamid > 0
						select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid


					if @ani = '''' begin 
					set @ani = @aniglobal 
					end 

					 set @carrier = ''''
					 select @carrier = dbo.GetCarrierByTel(@phone)

					select @prefix as sDialPrefix, @tNoContesta as tNoContesta,@ani as ani, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail,
					@call_record as call_record, isnull(@MsgFiles,'''') as messageFiles, isnull(@MohFiles,'''') as mohFiles, @ivr_script ivrScript, @sipheader data
					,@PrefixRec PrefijoRec, @carrier Carrier, @recordHold recordHold, @recordIvr recordIvr'
		EXEC(@sql)

		SET @process = 'KR146000 - se valida sp ccsp_AutomaticMessages'
		SET @sql = 'IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''ccsp_AutomaticMessages''))
					BEGIN
						DROP PROCEDURE ccsp_AutomaticMessages;
					END;'
		EXEC(@sql)

		SET @process = 'KR146000 - se crea sp ccsp_AutomaticMessages'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_AutomaticMessages]
					@command smallint, -- 1=Insert, 2=Delete
					@msg_id varchar(255)=null,
					@campIO_id int=null,
					@type tinyint=null,
					@campType int=null
					as
					set nocount on

					declare @maxOrden int, @campName varchar(max), @num int
					declare @T_all as table (id int, msg_id int)
					declare @T_TTS as table (id int, msg_id int)

					if @campType=0
						set @campName = (select descripcion from ccInbound where Inbound_id=@campIO_id)
					else
						set @campName = (select cam_descripcion from ccCamps where cam_id=@campIO_id)

						If @command=1
						 begin
							if @campType=0 
							 begin
								select @maxOrden = max(orden) from ccInboundMsgs where Inbound_id=@campIO_id and type=@type

								select @num = case when @maxOrden is null then 1 else 0 end
								set @maxOrden =ISNULL(@maxOrden,0)

								insert @T_all 
								select ROW_NUMBER() OVER(ORDER BY A.id ASC)-@num AS Row#,
								A.value from dbo.fn_RIASplitDelimited(@msg_id, '','') A
								left join ccInboundMsgs B on A.Value=B.Msg_id and B.Inbound_id=@campIO_id and B.Type=@type
								where B.Inbound_id  is null

								insert into ccInboundMsgs (msg_id, inbound_id, orden, type)
								select B.msg_id, @campIO_id as inbound_id, @maxOrden+B.id as orden,@type as type 
								from  @T_all B
								where msg_id not in(select Msg_id from ccInboundMsgs where Inbound_id=@campIO_id and Type=@type)

								select @campName
							 end

							if @campType=1 
							 begin
            
								IF @type = 8 or @type = 20
								BEGIN
									select @maxOrden = max(orden) from ccCampsMsgs where cam_id=@campIO_id and Type in (8, 20)
								END
								ELSE
								BEGIN
									select @maxOrden = max(orden) from ccCampsMsgs where cam_id=@campIO_id and type=@type
								END

								select @num = case when @maxOrden is null then 1 else 0 end
								set @maxOrden =ISNULL(@maxOrden,0)

								insert @T_all 
								select ROW_NUMBER() OVER(ORDER BY A.id ASC)-@num AS Row#,
								A.value from dbo.fn_RIASplitDelimited(@msg_id, '','') A
								left join ccCampsMsgs B on A.Value=B.Msg_id and B.cam_id=@campIO_id and B.Type=@type
								where B.cam_id  is null

								IF @type = 8
								BEGIN

									insert into @T_TTS
									select id, msg_id from @T_all where msg_id > 1000

									update @T_TTS set msg_id = msg_id - 1000

									insert into ccCampsMsgs(msg_id, cam_id, orden, type)
									select B.msg_id, @campIO_id as cam_id, @maxOrden+B.id as orden, 20 as type 
									from  @T_TTS B
									where msg_id not in(select Msg_id from ccCampsMsgs where cam_id=@campIO_id and Type = 20)

									delete from @T_all where msg_id > 1000				
								END

								insert into ccCampsMsgs(msg_id, cam_id, orden, type)
								select B.msg_id, @campIO_id as cam_id, @maxOrden+B.id as orden,@type as type 
								from  @T_all B
								where msg_id not in(select Msg_id from ccCampsMsgs where cam_id=@campIO_id and Type=@type)

								select @campName
							 end
						 end

						if @command=2
						 begin
							if @campType=0
							begin
								delete im from ccInboundMsgs im
								where Msg_id IN(select Value from dbo.fn_RIASplitDelimited(@msg_id, '','')) and Inbound_id=@campIO_id and Type=@type

								insert @T_all
								select ROW_NUMBER() OVER(ORDER BY B.orden ASC)-1 AS Row#,
								b.Msg_id from ccInboundMsgs B
								where B.Inbound_id=@campIO_id and B.Type=@type
								order by orden

								UPDATE ccInboundMsgs SET orden = a.id
								FROM ccInboundMsgs IM
								INNER JOIN @T_all A ON IM.Msg_id = A.msg_id
								WHERE IM.Inbound_id=@campIO_id and IM.Type=@type

								select @campName
							end

							if @campType=1
							begin
								delete cm from ccCampsMsgs cm
								where Msg_id IN(select Value from dbo.fn_RIASplitDelimited(@msg_id, '','')) and cam_id=@campIO_id and Type=@type

								IF @type = 8
								BEGIN
									delete cm from ccCampsMsgs cm
									where Msg_id IN(select (Value - 1000) from dbo.fn_RIASplitDelimited(@msg_id, '','')) and cam_id=@campIO_id and type = 20
								END

								insert @T_all
								select ROW_NUMBER() OVER(ORDER BY B.orden ASC)-1 AS Row#,
								b.Msg_id from ccCampsMsgs B 
								where B.cam_id=@campIO_id and (
								(@type = 8 AND B.Type IN (8, 20)) 
								OR (@type <> 8 AND B.Type = @type))
								order by orden

								UPDATE ccCampsMsgs SET orden = a.id
								FROM ccCampsMsgs CM
								INNER JOIN @T_all A ON CM.Msg_id = A.msg_id
								WHERE CM.cam_id=@campIO_id AND (
								(@type = 8 AND cm.Type IN (8, 20)) 
								OR (@type <> 8 AND cm.Type = @type))

								select @campName
							end
						 end
					set nocount off'
		EXEC(@sql)

		SET @process = 'KR146000 - se valida sp ccsp_GalateaAutomaticMessages'
		SET @sql = 'IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''ccsp_GalateaAutomaticMessages''))
					BEGIN
						DROP PROCEDURE ccsp_GalateaAutomaticMessages;
					END;'
		EXEC(@sql)

		SET @process = 'KR146000 - se crea sp ccsp_GalateaAutomaticMessages'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAutomaticMessages]
						@action as tinyint,
						@type as int = null,
						@msgFile as varchar(40) = '''',
						@Description as varchar(40) = '''',
						@length as int = null,
						@CampId INT = 0,
						@CampType SMALLINT = 0,
						@MessageType TINYINT = 0,
						@msgIdLst varchar(8000) = null,
						@msgName as varchar(40) = '''',
						@msg_id int = 0,
						@VariableData TINYINT = 0,
						@TtsType TINYINT = 0,
						@VariableOrder TINYINT = 0,
						@MsgRelation varchar(8000) = NULL,
						@idArea SMALLINT = NULL,
						@message as varchar(3042) = '''',
						@adminId as int = 0,
						@calloutId as int = 0,
						@phone as varchar(10) = ''''

						AS

						SET NOCOUNT ON

						declare @area as varchar(20) = ''''
						declare @login as varchar(50) = ''''

						select @area = AreaName, @login = Login
						from ccUsers a
						left join ccRIACat_Areas b on a.IDArea = b.IDArea
						where User_id = @adminId

						if @action = 1  -- Get audio catalog
						begin
							(select ISNULL(msgName, msgFile) [MsgName], Descripcion [MsgDescription], msgFile [MsgFile], msg_id [MsgId], DefaultMessage, ISNULL(idArea, -1) [IdArea], '''' as [Message] from ccMsgFiles
							where msgFile not like ''TTS|%'' AND (idArea IN (@idArea,-1) OR idArea IS NULL))
							union 
							(select name [MsgName], 
									Description [MsgDescription], 
									'''' [MsgFile], 
									messageId [MsgId], 
									cast(0 as bit), 
									cast(ISNULL(areaId, -1) as smallint) [IdArea],
									message as [Message]
							from ttsMessages
							where (areaId IN (1,-1) OR areaId IS NULL))
							return (0)
						end

						if @action = 2
						begin
							if EXISTS(select msgName from ccMsgFiles where msgName=@msgName)
							begin
								select 1 as result
							end
							else
							begin 
								insert into ccMsgFiles (msgFile, descripcion, length, msgName, idArea) values (@msgFile, @Description, @length, @msgName, @idArea)
								select 0 as result
							end 
            
						end 

						if @action = 3
						begin
							select msg_id from ccMsgFiles where msgName=@msgName
						end

						IF @action = 4 -- Get Assigned Messages by Campaign Id and Campaign Type
						BEGIN
							DECLARE @CampaignMessagesRelation TABLE (MessageType TINYINT, MessageOrder TINYINT, MessageFile VARCHAR(MAX), 
																		MessageId INT, MessageDescription VARCHAR(MAX), Queue BIT)
							IF @CampType = 0  -- Inbound Campaigns
								BEGIN
									INSERT INTO @CampaignMessagesRelation (MessageType, MessageOrder, MessageFile, MessageId, MessageDescription, Queue) 
									EXEC ccsp_RIAADMInboundMsgs @Command = 1,@Inbound_id = @CampId
								END
							ELSE              -- Outbound Campaigns
								BEGIN 
									INSERT INTO @CampaignMessagesRelation (MessageType, MessageOrder, MessageFile, MessageId, MessageDescription)
									EXEC ccsp_RIAADMCampMsgs @Command = 1, @cam_id = @CampId
									UPDATE @CampaignMessagesRelation SET Queue = 0
								END

							IF @messageType = 8 and @CampType = 1
							BEGIN
								SELECT * FROM @CampaignMessagesRelation WHERE MessageType IN (8, 20)
							END
							ELSE
							BEGIN
								SELECT * FROM @CampaignMessagesRelation WHERE MessageType = @MessageType
							END
            
						END 

						IF @action = 5 -- Delete audio message
						begin
							if exists(select Msg_id from ccInboundMsgs where Msg_id in (select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')))
							begin
								select 0 as result
								return(0)
							end
							if exists(select Msg_id from ccCampsMsgs where Msg_id in (
						select B.msg_id from dbo.fn_RIASplitDelimited(@msgIdLst, '','') A
						inner join ccMsgFiles B on A.Value=B.msg_id 
						where msgFile not like ''TTS|%''
						)
						)
							begin
								select 0 as result
								return(0)
							end
            
							delete A from ccCampsMsgs A where Msg_id in (
							select B.msg_id from dbo.fn_RIASplitDelimited(@msgIdLst, '','') A
							inner join ccMsgFiles B on A.Value=B.msg_id 
							where msgFile like ''TTS|%'')

							delete ccMsgFiles Where msg_id in (select value from dbo.fn_RIASplitDelimited(@msgIdLst, '',''))
							select 1 as result
							return(0)
						end 

						if @action = 6
						BEGIN
							if @type = 0
								BEGIN
									update ccMsgFiles set Descripcion = @Description, msgName = @msgName, idArea = @idArea where msg_id = @msg_id
								END
							else
								BEGIN
									update ccMsgFiles set Descripcion = @Description, msgName = @msgName, msgFile = @msgFile, length = @length, idArea = @idArea where msg_id = @msg_id
								END
						END 

						if @action = 7
						BEGIN
							select msg_id as msgId, msgName as MsgName, Descripcion as MsgDescription, ISNULL(idArea,-1) AS IdArea from ccMsgFiles where msg_id = @msg_id
						END

						IF @action = 8
						BEGIN
							DECLARE @Language TINYINT = (SELECT valor from ccSettings where setting_id = 27)
							DECLARE @TempMsgFile VARCHAR(10) = (''TTS'' + ''|'' + CONVERT(VARCHAR(2), @TtsType) + ''|'' + CONVERT(VARCHAR(2), @VariableData))
							SET @Description = (SELECT CASE WHEN @Language = 0 THEN TtsTypesTagsSpanish 
															WHEN @Language = 1 THEN TtsTypesTagsEnglish 
															ELSE TtsTypesTagsPortuguese END 
												FROM ccRIA_AutamaticMessages_TtsTypesTags 
												WHERE Id = @VariableData) 
												+ ''|'' + 
												(SELECT VariableDataTag FROM ccRIA_AutamaticMessages_VariableDataTags 
												WHERE LanguageId = @Language)
												+ CONVERT(VARCHAR(2), @VariableData) 
												+ ''|'' + CONVERT(VARCHAR(2), @CampId) 

							IF @msg_id = 0
							BEGIN
							EXEC ccsp_RIAADMCampMsgs @Command = 3, @cam_id = @CampId, @order = @VariableOrder,@type=8,@msgFile=@TempMsgFile,@description=@Description   
							END
							ELSE
							BEGIN
								UPDATE ccMsgFiles SET msgFile = @TempMsgFile, Descripcion = @Description where msg_id = @msg_id
							END
            
						END

						IF @action = 9
						BEGIN
							select msgFile [MsgFile] from ccMsgFiles where msg_id in (select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')) and msgFile not like ''TTS|%''
						END

						IF @action = 10
						BEGIN
							IF @CampType = 0  -- Inbound Campaigns
								BEGIN
									UPDATE b SET b.orden = a.Id - 1 FROM dbo.fn_RIASplitDelimited(@MsgRelation, '','') a INNER JOIN ccInboundMsgs b ON b.Inbound_id = @CampId AND b.Type = @MessageType AND b.Msg_id = a.Value 
								END
							ELSE              -- Outbound Campaigns
								BEGIN
									IF @MessageType = 8
									BEGIN
										declare @currentTable as table (id int, value int, type int)

										insert into @currentTable
										select a.Id - 1, case when a.Value > 1000 then a.Value - 1000 else a.Value end, case when a.Value > 1000 then 20 else 8 end as type
										from dbo.fn_RIASplitDelimited(@MsgRelation, '','') a

										update a set a.orden = b.id from ccCampsMsgs a join @currentTable b on a.Msg_id = b.value and a.Type = b.type and a.cam_id = @CampId
									END
									ELSE
									BEGIN
										UPDATE b SET b.orden = a.Id - 1 FROM dbo.fn_RIASplitDelimited(@MsgRelation, '','') a INNER JOIN ccCampsMsgs b ON b.cam_id = @CampId AND b.Type = @MessageType AND b.Msg_id = a.Value 
									END                    
								END
						END

						IF @action = 11
						BEGIN
							IF @msg_id < 1000
							BEGIN
								(select OC.cam_id as Camp_Id, Camp_Type = 1, ISNULL(cam_descripcion,'''''''') as [Name], Graphics.frame as Frame, CM.Type, ISNULL(OC.IDArea,0) as IdArea, ISNULL(AREas.AreaName,'''') as AreaName
								from ccCamps as OC with(nolock) 
								left join ccRIACat_Areas as AREas with(nolock) on OC.IDArea = AREas.IDArea
								inner join ccRIACampsGraph as CampsGraph on OC.cam_id = CampsGraph.cam_id
								inner join ccRIAGraphics as Graphics on Graphics.graphic_id = CampsGraph.graphic_id
								inner join ccCampsMsgs CM on CM.cam_id = OC.cam_id
								Where CM.msg_id = @msg_id)
								UNION ALL
								(select IC.Inbound_id as Camp_Id, Camp_Type = 0,ISNULL(descripcion,'''''''') as [Name], Graphics.frame as Frame, IM.Type, ISNULL(IC.IDArea,0) as IdArea, ISNULL(AREas.AreaName,'''') as AreaName
								from ccInbound as IC with(nolock) 
								left join ccRIACat_Areas as AREas with(nolock) on IC.IDArea = AREas.IDArea
								inner join ccRIAInboundGraph as CampsGraph on IC.Inbound_id = CampsGraph.Inbound_id
								inner join ccRIAGraphics as Graphics on Graphics.graphic_id = CampsGraph.graphic_id
								inner join ccInboundMsgs IM on IM.Inbound_id = IC.Inbound_id
								Where IM.msg_id = @msg_id)
								END
							ELSE
							BEGIN 
								select OC.cam_id as Camp_Id, Camp_Type = 1, ISNULL(cam_descripcion,'''''''') as [Name], Graphics.frame as Frame, CM.Type, ISNULL(OC.IDArea,0) as IdArea, ISNULL(AREas.AreaName,'''') as AreaName
								from ccCamps as OC with(nolock) 
								left join ccRIACat_Areas as AREas with(nolock) on OC.IDArea = AREas.IDArea
								inner join ccRIACampsGraph as CampsGraph on OC.cam_id = CampsGraph.cam_id
								inner join ccRIAGraphics as Graphics on Graphics.graphic_id = CampsGraph.graphic_id
								inner join ccCampsMsgs CM on CM.cam_id = OC.cam_id
								Where CM.msg_id = @msg_id-1000
								and CM.Type = 20
							END
						END

						IF @action = 12
						BEGIN			
							IF NOT EXISTS (select 1 from ttsMessages where name = @msgName)
							BEGIN
								INSERT INTO ttsMessages values (@msgName, @Description, @message, -1)
							END

							select @@rowcount
						END

						IF @action = 13 --update
						BEGIN			

							declare @result int = 0;
							declare @currentMessage as table(name varchar(40), description varchar(40), message varchar(3042), areaId int);
							declare @currentName varchar(40) = '''';

							insert into @currentMessage
							select name, description, message, areaId from ttsMessages where messageId = @msg_id

							select @currentName = name from ttsMessages where messageId = @msg_id

							IF EXISTS (select 1 from ccCampsMsgs where Msg_id = @msg_id and Type = 20)
							BEGIN
								declare @camId int = 0;

								select @camId = cam_id from ccCampsMsgs where Msg_id = @msg_id and Type = 20

								IF EXISTS (select 1 from ccCamps where cam_id = @camId and cam_procesando = 1)
								BEGIN
									set @result = 2			
								END
							END

							IF @result <> 2
							BEGIN
								IF EXISTS (select 1 from ttsMessages where messageId = @msg_id)
								BEGIN
									update ttsMessages set name = @msgName, description = @Description, areaId = @idArea, message = @message where messageId = @msg_id
									set @result = @@rowcount;
								END
								ELSE
								BEGIN
									set @result = 3;
								END
							END

							IF @result = 1
							BEGIN
								DECLARE @logEntries TABLE (
									Identifier VARCHAR(50),
									Value VARCHAR(255)
								);

								INSERT INTO @logEntries (Identifier, Value)
								SELECT ''AUTOMATIC_MESSAGES_NAME'', @msgName
								WHERE EXISTS (SELECT 1 FROM @currentMessage WHERE name <> @msgName)

								UNION ALL

								SELECT ''AUTOMATIC_MESSAGES_DESCRIPTION'', @Description
								WHERE EXISTS (SELECT 1 FROM @currentMessage WHERE description <> @Description)

								UNION ALL

								SELECT ''AUTOMATIC_MESSAGES_MESSAGE'', @message
								WHERE EXISTS (SELECT 1 FROM @currentMessage WHERE message <> @message)

								UNION ALL

								SELECT ''AUTOMATIC_MESSAGES_GLOBAL'', CASE WHEN @idArea = -1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
								WHERE EXISTS (SELECT 1 FROM @currentMessage WHERE areaId <> @idArea);

								INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
								SELECT @area, GETDATE(), @login, 125, 23, Identifier, Value, @currentName
								FROM @logEntries;
							END

			
							select @result
						END

						IF @action = 14 --delete
						BEGIN
							declare @res as int = 1
							declare @response as int = 0
							declare @deleted as int = 0			
							declare @messages as table(id int, name varchar(40))	
							declare @messagesList as varchar(3072) = ''''			

							insert into @messages
							select messageId, name
							from ttsMessages a
							where a.messageId in (select value from dbo.fn_RIASplitDelimited(@msgIdLst, '',''))

							IF EXISTS (select 1 from ccCampsMsgs where msg_id in (select id from @messages) and Type = 20)
							BEGIN
								set @res = 2
								delete from @messages where id in (select msg_id from ccCampsMsgs where type = 20)
							END

							delete from ttsMessages where messageId in (select id from @messages)

							select @deleted = @@ROWCOUNT

							set @response = case 
												when @deleted > 0 and @res = 1 then 1 -- elimino todo
												when @res = 2 and not exists (select 1 from @messages) then 2 -- todo está asignado
												when @deleted > 0 and @res = 2 then 3 -- si elimino, pero otros están asignados 
												when @deleted = 0 and @res in (1, 2) then 4 -- no se elimino nada, no existen en bd							
											end

							IF @response in (1, 3)
							BEGIN
								INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
								SELECT @area, getDate(), @login, 126, 23, '''', '''', name
								from @messages
							END
			 
							SELECT @messagesList = @messagesList + CAST(1000 + id AS VARCHAR) + '','' 
							FROM @messages;

							IF LEN(@messagesList) > 0
							BEGIN
    							SET @messagesList = LEFT(@messagesList, LEN(@messagesList) - 1);
							END

							select @response as response, case when @response = 2 then '''' else @messagesList end as msgIdList
						END

						IF @action = 15
						BEGIN
							select messageId from ttsMessages where name = @msgName
						END	

						IF @action = 16
						BEGIN
							select name from ttsMessages where messageId = (@msg_id - 1000)
						END

						IF @action = 17
						BEGIN
							declare @temp as table(Dato1 varchar(3072), Dato2 varchar(3072), Dato3 varchar(3072), Dato4 varchar(3072), Dato5 varchar(3072), callout_id int)

							if exists (select 1 from ccoCallsOutSource where cam_id = @CampId)
							BEGIN				
								declare @callout_id int = -1
				
								select top 1 @callout_id = callout_id from ccoCallsOutSource where cam_id = @campId


								exec ccsp_TTSMessageData @campId, @callout_id, @message = @message output

								SELECT @message = REPLACE(REPLACE(@message, '' {{'', '' <NormalVar>Var:''), ''}} '', ''</NormalVar> '')

								IF RIGHT(@message, 2) = ''}}''
								BEGIN					
									SET @message = LEFT(@message, LEN(@message) - 2) + ''</NormalVar>'';
								END
				
								SELECT @message = REPLACE(REPLACE(@message, ''}}'', ''''), ''{{'', '''')				

								select @message + ''|'' + cast(@callout_id as varchar)
							END
							ELSE
							BEGIN
								select ''''
							END
						END

						IF @action = 18
						BEGIN
							declare @temp2 as table(Dato1 varchar(3072), Dato2 varchar(3072), Dato3 varchar(3072), Dato4 varchar(3072), Dato5 varchar(3072))

							insert into @temp2
								select case when MAX(LEN(dato1)) = 0 then 10 else MAX(LEN(dato1)) end AS Dato1,
									case when MAX(LEN(dato2)) = 0 then 10 else MAX(LEN(dato2)) end AS Dato2,
									case when MAX(LEN(dato3)) = 0 then 10 else MAX(LEN(dato3)) end AS Dato3,
									case when MAX(LEN(dato4)) = 0 then 10 else MAX(LEN(dato4)) end AS Dato4,
									case when MAX(LEN(dato5)) = 0 then 10 else MAX(LEN(dato5)) end AS Dato5
								from ccoCallsOutSource where cam_id = @CampId

							SELECT CAST(Dato1 as varchar) + '','' + CAST(Dato2 as varchar) + '','' + CAST(Dato3 as varchar) + '','' + CAST(Dato4 as varchar) + '',''+ CAST(Dato5 as varchar)
							FROM @temp2
						END

						IF @action = 19
						BEGIN
			
							DECLARE @resultCalId as int = 0
			
							insert into ccoCallsOut(User_id, cam_id, callout_id, cal_telefono, statusCall_id) values (@adminId, @CampId, @calloutId, @phone, 11)

							SELECT cast(@@IDENTITY as int) as messageId

						END

						IF @action = 20
						BEGIN
							declare @names varchar(250) = ''''
			
							SELECT @names = @names + COLUMN_NAME + '',''
							FROM INFORMATION_SCHEMA.COLUMNS
							WHERE TABLE_NAME = ''ViewTTSMessagesData'' and COLUMN_NAME not in (''identificador'', ''cam_id'', ''cal_key'', ''cal_telefono'')

							SELECT @names = LEFT(@names, LEN(@names) - 1);

							select @names
						END

						SET NOCOUNT OFF'
		EXEC(@sql)

		------------------------------------------- Begin Rod Salazar ----------------------------------------------------------

    SET @process = 'ALter funcion fnGetTipoLlamada'
    SET @sql = 'Alter FUNCTION [dbo].[fnGetTipoLlamada](@tel VARCHAR(32))
RETURNS TINYINT
AS
BEGIN
    DECLARE @ladatemp varchar(5), @ldlocal VARCHAR(10), @serie varchar(10), @numeracion SMALLINT, @lenght TINYINT
    DECLARE @mod VARCHAR(10), @country TINYINT,@s@lenght varchar(10)

    -- Retrieve country and local area code from settings
    SELECT @country = valor 
    FROM ccsettings WITH (NOLOCK) 
    WHERE setting_id = 104

    SELECT @lenght = LEN(@tel),
           @ldlocal = valor 
    FROM ccSettings WITH (NOLOCK) 
    WHERE setting_id = 17

    -- Temporary tables for prefijo and tipoLlamada data
    DECLARE @table TABLE (
        id INT NOT NULL,
        prefijo NVARCHAR(100) NOT NULL
    )

    DECLARE @t_tipos TABLE (
        tipollamada_id INT NOT NULL,
        prefijo NVARCHAR(100) NOT NULL,
        rowid INT NOT NULL
    )

    DECLARE @tipoLlamada_id SMALLINT, @prefijo VARCHAR(15), @tipo TINYINT, @cantidadLL TINYINT
    SET @tipoLlamada_id = 0

    set @s@lenght=CONVERT(varchar(10),@lenght)

    if @country= 1 begin
        INSERT INTO @t_tipos
        SELECT tipoLlamada_id, prefijo, ROW_NUMBER() OVER (ORDER BY LEN(prefijo) DESC) AS rowid
        FROM cstoTipoLlamada WITH (INDEX(IX_cstoTipoLlamada), NOLOCK)
        WHERE country_id = 1 AND tipoLlamada_id NOT IN (8, 9, 10, 11, 12)
        and longitud like ''%''+@s@lenght+''%''
    end
    else begin
        INSERT INTO @t_tipos
        SELECT tipoLlamada_id, prefijo, ROW_NUMBER() OVER (ORDER BY LEN(prefijo) DESC) AS rowid
        FROM cstoTipoLlamada WITH (INDEX(IX_cstoTipoLlamada), NOLOCK)
        WHERE country_id = @country
        and longitud like ''%''+@s@lenght+''%''
    end
        

    -- Count the number of matching records
    SELECT @cantidadLL = COUNT(*) 
    FROM @t_tipos

    -- If there are matching options, evaluate them
    IF @cantidadLL <> 0
    BEGIN
        SELECT TOP 1 @tipo = tipollamada_id
        FROM @t_tipos t
        CROSS APPLY dbo.fn_RIASplitDelimited(t.prefijo, ''|'') AS splitPrefijo
        WHERE @tel LIKE splitPrefijo.value + ''%''
        ORDER BY LEN(splitPrefijo.value) DESC;
    END
    ELSE
    BEGIN
        
        SELECT TOP 1 @tipoLlamada_id = tipoLlamada_id, @prefijo = prefijo
        FROM cstoTipoLlamada WITH (INDEX(IX_cstoTipoLlamada), NOLOCK)
        CROSS APPLY dbo.fn_RIASplitDelimited(cstoTipoLlamada.prefijo, ''|'') AS split
        WHERE country_id = @country
          AND longitud = ''0''
          AND @tel LIKE split.value + ''%''
          AND (country_id <> 1 OR (country_id = 1 AND tipoLlamada_id NOT IN (8, 9, 10, 11, 12)))
        ORDER BY LEN(split.value) DESC;     

        -- If a match was found, assign it to @tipo
        IF @tipoLlamada_id <> 0
        BEGIN
            SET @tipo = @tipoLlamada_id
        END
        ELSE
        BEGIN
            if @country!=1 begin
                 RETURN @tipo
            end
            -- Additional series checks for certain phone lengths
            IF @lenght = 10 - LEN(@ldlocal)
            BEGIN
                SELECT @tel = CONVERT(VARCHAR(3), @ldlocal) + @tel
            END

            SELECT @tel = RIGHT(@tel, 10)
            SELECT @ladatemp = LEFT(@tel, 2)

            -- Check for two-digit area codes
            IF @ladatemp IN (''55'', ''56'', ''33'', ''81'')
            BEGIN
                SELECT @serie = SUBSTRING(@tel, 3, 4), 
                       @numeracion = RIGHT(@tel, 4)                
            END
            ELSE
            BEGIN
                -- Check for three-digit area codes                
                SELECT @ladatemp = LEFT(@tel, 3), 
                       @serie = SUBSTRING(@tel, 4, 3), 
                       @numeracion = RIGHT(@tel, 4)                
            END

            -- Fetch modalidad based on series and numeracion
            SELECT top 1 @mod = MODALIDAD 
            FROM Series WITH (NOLOCK) 
            WHERE CLD = @ladatemp 
            AND SERIE = @serie 
            AND @numeracion BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

            -- Check if the number is local
            DECLARE @isLocal BIT = 0

           IF EXISTS (SELECT 1 FROM ccRiaArecode WITH (NOLOCK) WHERE area = @ladatemp)
           OR @ldlocal = @ladatemp
            BEGIN
                SET @isLocal = 1;
            END

            -- Determinar el tipo de llamada según la modalidad y si es local
            IF @mod IN (''FIJO'', ''MPP'')
            BEGIN
                -- Llamada fija o móvil postpago
                SET @tipo = CASE 
                            WHEN @isLocal = 1 THEN 1  -- Llamada local
                            ELSE 2                     -- Llamada de larga distancia
                        END;
            END
            ELSE IF @mod = ''CPP''
            BEGIN
                -- Llamada celular prepago
                SET @tipo = CASE 
                            WHEN @isLocal = 1 THEN 3  -- Llamada celular local
                            ELSE 4                    -- Llamada celular de larga distancia
                        END;
            END
        END
    END

    RETURN @tipo
END
'
    EXEC(@sql)		
		

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
