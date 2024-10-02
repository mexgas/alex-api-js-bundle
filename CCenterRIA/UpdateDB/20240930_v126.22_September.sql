/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: David Medina Medina
Date: 2024/09/19
Description: Release 126.20240919.0.0
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
