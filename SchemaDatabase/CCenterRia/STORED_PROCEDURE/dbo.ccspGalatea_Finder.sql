CREATE PROCEDURE [dbo].[ccspGalatea_Finder] @action       INT
                                         , @userId       INT    = 0
                                         , @conversationId BIGINT = 0
AS
     IF @action = 1
     BEGIN--trae el nombre de la base de datos en BX
         SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value]
              , CAST(WGCam.Tipo AS INT) + 1 AS callType
              , c.cam_descripcion AS label FROM ccRIAWorkGroupUsers Wguser
                                                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                                                INNER JOIN ccCamps c ON WGCam.IdCampEsp = c.cam_id
                                                                        AND WGCam.Tipo = 1
         WHERE Wguser.User_id = @userId
         UNION
         SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value]
              , CAST(WGCam.Tipo AS INT) + 1 AS callType
              , inb.descripcion AS label FROM ccRIAWorkGroupUsers Wguser
                                              INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                                              INNER JOIN ccInbound inb ON WGCam.IdCampEsp = inb.Inbound_id
                                                                          AND WGCam.Tipo = 0
         WHERE Wguser.User_id = @userId;
     END;
     ELSE
         IF @action = 2
         BEGIN
             WITH WgId
                  AS (SELECT IDWG FROM ccRIAWorkGroupUsers Wguser WHERE Wguser.User_id = @userId)
                  SELECT DISTINCT
                         CAST(Wguser.User_id AS INT) AS [Value]
                       , ccUsers.Login AS label FROM ccRIAWorkGroupUsers Wguser
                                                     INNER JOIN WgId ON Wguser.IDWG = WgId.IDWG
                                                     INNER JOIN ccUsers ON ccUsers.User_id = Wguser.User_id
                                                                           AND TipoUser_id = 1;
         END;
         ELSE
             IF @action = 3
             BEGIN--Informacion de la conversacion de whatsApp
                 SELECT A.ConversationID
                      , A.inboundId AS AcdId
					  , isnull(graph.graphic_id,1) as GraphicId
                      , A.phoneACD AS PhoneAcd
                      , A.clientId AS PhoneClient
                      , ISNULL(B.descripcion, 'N/A') AS AcdName
                      , ISNULL(cctipocalif.[Description], 'N/A') AS Disposition
                      , ISNULL(cctipocalifsub.califSubdesc, 'N/A') AS SubDisposition
                      , ISNULL(conversationDate, requestDate) DateStart
					  , ISNULL(A.agentId,0) AgentID
					  FROM ccWhatsAppConversations A
                                                                             LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
                                                                             LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
                                                                             LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
																			 left join ccRIAInboundGraph graph on graph.Inbound_id=A.inboundId
                 WHERE A.conversationId = @conversationId;

             END;