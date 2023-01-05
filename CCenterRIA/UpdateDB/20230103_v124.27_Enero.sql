/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.25

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
SET @versionfix = 27
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

		--- K036001-LN-Modificar longitud cal_key --
		SET @process = 'K036001-LN-Modificar longitud cal_key delete procedure ccsp_GalateaAdminUploadBLst'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaAdminUploadBLst'')
			BEGIN
				DROP PROCEDURE ccsp_GalateaAdminUploadBLst;
			END';
		EXEC(@sql);

		SET @process = 'K036001-LN-Modificar longitud cal_key  create procedure ccsp_GalateaAdminUploadBLst'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminUploadBLst]  @command TINYINT, @telephone VARCHAR(20) = 0, @idtipolista INT, @calKey AS VARCHAR(20) = NULL
		AS
		DECLARE @hashCalKey BIGINT, @hashPhone BIGINT

		SELECT @hashPhone = dbo.hashPhone(@telephone)

		IF @calKey IS NOT NULL
		BEGIN
		  SELECT @hashCalKey = dbo.hashList(@calKey)
		END

		IF @hashCalKey IS NULL
		BEGIN
		  IF @command IN (1, 4) --LookForNumber 
			AND EXISTS (
			  SELECT idtipolista
			  FROM cclistanegra
			  WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idtipolista
			  )
		  BEGIN
			SELECT 1

			RETURN (0)
		  END
		END
		ELSE
		BEGIN
		  IF @command IN (1, 4) --LookForNumber 
			AND EXISTS (
			  SELECT idtipolista
			  FROM cclistanegra
			  WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
			  )
		  BEGIN
			SELECT 1

			RETURN (0)
		  END
		END

		IF @command = 1 --Insert Number
		BEGIN
		  EXEC ccsp_InsertDNCList @telephone, @idtipolista, @hashCalKey

		  INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
		  VALUES (@telephone, 1, @idtipolista)

		  SELECT 200
		END

		IF @command = 2 --Delete Number
		BEGIN
		  INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
		  VALUES (@telephone, 5, @idtipolista)

		  IF @hashCalKey IS NULL
		  BEGIN
			DELETE
			FROM cclistanegra
			WHERE Hashtel = @hashPhone AND HashKey IS NULL
		  END
		  ELSE
		  BEGIN
			DELETE
			FROM cclistanegra
			WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey
		  END

		  RETURN (0)
		END

		IF @command = 3 --Reemplaza
		BEGIN
		  INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
		  SELECT telefono, 4, @idtipolista
		  FROM cclistanegra
		  WHERE idtipolista = @idtipolista

		  DELETE
		  FROM cclistanegra
		  WHERE idtipolista = @idtipolista

		  RETURN (0)
		END

		IF @command = 5 --Delete by idtipolista
		BEGIN
		  UPDATE ccTiposListaNegra
		  SET STATUS = 0
		  WHERE idtipolista = @idtipolista

		  DELETE ccAgendaListaNegra
		  WHERE idagenda IN (
			  SELECT idagenda
			  FROM ccAgenda_TipolistaNegra
			  WHERE idtipolista = @idtipolista
			  )

		  DELETE ccAgenda_TipolistaNegra
		  WHERE idtipolista = @idtipolista

		  DELETE cccalifblacklist
		  WHERE idtipolista = @idtipolista

		  DELETE Camplistanegra
		  WHERE idtipolista = @idtipolista

		  DECLARE @telefono VARCHAR(10)

		  WHILE EXISTS (
			  SELECT telefono
			  FROM ccListaNegra
			  WHERE idtipolista = @idtipolista
			  )
		  BEGIN
			SELECT TOP 1 @hashPhone = Hashtel, @telefono = telefono
			FROM ccListaNegra
			WHERE idtipolista = @idtipolista

			INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
			VALUES (@telefono, 5, @idtipolista)

			DELETE
			FROM cclistanegra
			WHERE Hashtel = @hashPhone AND idtipolista = @idtipolista
		  END

		  RETURN (0)
		END

		SET NOCOUNT OFF'

		EXEC(@sql);
		-------------------------------------------- Ivan Martin (Gerardo Zumaya) K002082-DescargaConv_WA --------------------
		SET @process = 'K002082-DescargaConv_WA Drop procedure ccspGalatea_Finder'
		SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccspGalatea_Finder'')
					BEGIN
						DROP PROCEDURE ccspGalatea_Finder;
					END';
		EXEC(@sql);

		SET @process = 'K002082-DescargaConv_WA Se actualiza el @action 3'
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
					     END;';
		EXEC(@sql);
		----------------------------------------------------------------------------------------------------------------------
	

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
