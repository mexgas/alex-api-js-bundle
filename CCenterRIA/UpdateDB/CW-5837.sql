/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
Description:

Database: CCenterRia
Required version: 123.14

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
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 24
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

    set @process = 'CW-5837 Se quita el SP ccspGalatea_Finder si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccspGalatea_Finder'')
            begin
          DROP PROCEDURE ccspGalatea_Finder;
            end'
    EXEC(@sql)

    set @process = 'CW-5837 se crea SP ccspGalatea_Finder'
    set @sql = '
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
                      , ISNULL(B.descripcion, ''N/A'') AS AcdName
                      , ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition
                      , ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition
                      , ISNULL(conversationDate, requestDate) DateStart 
					  , ISNULL(A.agentId,0) AgentID
					  FROM ccWhatsAppConversations A
                                                                             LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
                                                                             LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
                                                                             LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
																			 left join ccRIAInboundGraph graph on graph.Inbound_id=A.inboundId
                 WHERE A.conversationId = @conversationId;

             END;'
    EXEC(@sql)


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